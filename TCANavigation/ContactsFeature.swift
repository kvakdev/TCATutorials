//
//  ContactsFeature.swift
//  TCANavigation
//
//  Created by Andrii Kvashuk on 21/02/2024.
//

import SwiftUI
import ComposableArchitecture

struct Contact: Identifiable, Equatable {
    let id: UUID
    var name: String
}

@Reducer
struct ContactsFeature {
    @Dependency(\.uuid) var uuid
    
    @ObservableState
    struct State {
        @Presents var destination: Destination.State?
        var contacts: IdentifiedArrayOf<Contact> = []
    }
    
    enum Action {
        case addButtonTapped
        case deleteButtonTapped(id: Contact.ID)
        case destination(PresentationAction<Destination.Action>)
        
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID)
        }
    }
    
    @Reducer
    enum Destination {
        case addContact(AddContactsFeature)
        case alert(AlertState<ContactsFeature.Action.Alert>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.destination = .addContact(
                    AddContactsFeature.State(
                        contact: Contact(id: self.uuid(), name: "")
                    )
                )
                return .none
       
            case .destination(.presented(.addContact(.delegate(.saveContact(let contact))))):
                state.contacts.append(contact)
                
                return .none
            
            case let .deleteButtonTapped(id: id):
                state.destination = .alert(
                      AlertState {
                        TextState("Are you sure?")
                      } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                          TextState("Delete")
                        }
                      }
                    )
                return .none
                
            case let .destination(.presented(.alert(.confirmDeletion(id: id)))):
                state.contacts.remove(id: id)
                
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>
  
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        Text(contact.name)
                        Spacer()
                        Button {
                            store.send(.deleteButtonTapped(id: contact.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(item: $store.scope(state: \.destination?.addContact,
                                  action: \.destination.addContact)) { store in
            NavigationStack {
                AddContactsView(store: store)
            }
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))

  }
}

#Preview {
  ContactsView(
    store: Store(
      initialState: ContactsFeature.State(
        contacts: [
          Contact(id: UUID(), name: "Blob"),
          Contact(id: UUID(), name: "Blob Jr"),
          Contact(id: UUID(), name: "Blob Sr"),
        ]
      )
    ) {
      ContactsFeature()
    }
  )
}

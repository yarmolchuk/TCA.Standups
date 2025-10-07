//
//  StandupDetailFeature.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 30.09.2025.
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct StandupDetailFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        var standup: Standup
    }
    
    @Reducer
    struct Destination {
        enum State: Equatable {
            case alert(AlertState<Action.Alert>)
            case editStandup(StandupFormFeature.State)
        }
        
        enum Action: Equatable {
            case alert(Alert)
            case editStandup(StandupFormFeature.Action)
            
            enum Alert {
                case confirmDeletion
            }
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: \.editStandup, action: \.editStandup) {
                StandupFormFeature()
            }
        }
    }
    
    enum Action: Equatable {
        case cancelEditStandupButtonTapped
        case delegate(Delegate)
        case saveStandupButtonTapped
        case deleteButtonTapped
        case deleteMeetings(atOffsets: IndexSet)
        case editButtonTapped
        case destination(PresentationAction<Destination.Action>)
        
        enum Delegate: Equatable {
            case deleteStandup(id: Standup.ID)
            case standupUpdated(Standup)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelEditStandupButtonTapped:
                state.destination = nil
                return .none
                
            case .delegate:
                return .none
                
            case .deleteButtonTapped:
                state.destination = .alert(
                    AlertState {
                        TextState("Are you sure you want to delete?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion) {
                            TextState("Delete")
                        }
                    }
                )
                return .none
                
            case .deleteMeetings(atOffsets: let indices):
                state.standup.meetings.remove(atOffsets: indices)
                return .none
                
            case .destination(.presented(.alert(.confirmDeletion))):
                return .run { [id = state.standup.id] send in
                    await send(.delegate(.deleteStandup(id: id)))
                    await self.dismiss()
                }
                               
            case .destination:
                return .none
                
            case .editButtonTapped:
                state.destination = .editStandup(StandupFormFeature.State(standup: state.standup))
                return .none
                
            case .saveStandupButtonTapped:
                guard case let .editStandup(standupForm) = state.destination else { return .none }
                
                state.standup = standupForm.standup
                state.destination = nil
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        .onChange(of: \.standup) { oldValue, newValue in
            Reduce { state, action in
                .send(.delegate(.standupUpdated(newValue)))
            }
        }
    }
}

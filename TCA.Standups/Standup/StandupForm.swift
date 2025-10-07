//
//  StandupForm.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 22.09.2025.
//

import SwiftUI
import ComposableArchitecture
import Tagged

@Reducer
struct StandupFormFeature {
    @Dependency(\.uuid) var uuid

    @ObservableState
    struct State: Equatable, Sendable {
        var focus: Field? = .title
        var standup: Standup
        
        init(focus: Field? = .title, standup: Standup) {
            self.focus = focus
            self.standup = standup
            
            if self.standup.attendees.isEmpty {
                @Dependency(\.uuid) var uuid
                
                self.standup.attendees.append(Attendee(id: uuid()))
            }
        }
        
        enum Field: Hashable {
            case attendee(Attendee.ID)
            case title
        }
    }
    
    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case addAttendeeButtonTapped
        case deleteAttendees(atOffsets: IndexSet)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .addAttendeeButtonTapped:
                let attendee = Attendee(id: uuid())
                state.standup.attendees.append(attendee)
                state.focus = .attendee(attendee.id)
                
                return .none
                
            case let .deleteAttendees(atOffsets: indices):
                state.standup.attendees.remove(atOffsets: indices)
                
                if state.standup.attendees.isEmpty {
                    state.standup.attendees.append(Attendee(id: uuid()))
                }
                
                guard let firstIndex = indices.first else { return .none }
                
                let index = min(firstIndex, state.standup.attendees.count - 1)
                state.focus = .attendee(state.standup.attendees[index].id)
                
                return .none
            }
        }
    }
}

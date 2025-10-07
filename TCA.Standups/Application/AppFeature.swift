//
//  AppFeature.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 01.10.2025.
//

import ComposableArchitecture
import CasePaths
import Foundation

@Reducer
struct AppFeature {
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid
    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager.save) var saveData
    
    @Reducer
    struct Path {
        enum State: Equatable {
            case detail(StandupDetailFeature.State)
            case meeting(Meeting, standup: Standup)
            case recordMeeting(RecordMeetingFeature.State)
        }
        
        enum Action: Equatable {
            case detail(StandupDetailFeature.Action)
            case meeting(Never)
            case recordMeeting(RecordMeetingFeature.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: \.detail, action: \.detail) {
                StandupDetailFeature()
            }
            Scope(state: \.recordMeeting, action: \.recordMeeting) {
                RecordMeetingFeature()
            }
        }
    }
    
    @ObservableState
    struct State: Equatable {
        var standupsList = StandupsListFeature.State()
        var path = StackState<Path.State>()
    }

    enum Action {
        case standupsList(StandupsListFeature.Action)
        case path(StackAction<Path.State, Path.Action>)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.standupsList, action: \.standupsList) {
            StandupsListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .path(.element(id: _, action: .detail(.delegate(action)))):
                switch action {
                case let .deleteStandup(id: id):
                    state.standupsList.standups.remove(id: id)
                    return .none
                    
                case let .standupUpdated(standup):
                    state.standupsList.standups[id: standup.id] = standup
                    return .none
                }
                
            case let .path(.element(id: id, action: .recordMeeting(.delegate(action)))):
                switch action {
                case let .saveMeeting(transcript: transcript):
                    guard let detailID = state.path.ids.dropLast().last
                    else {
                        XCTFail("Record meeting is the last element in the stack. A detail feature should proceed it.")
                        return .none
                    }
                    state.path[id: detailID, case: \.detail]?.standup.meetings.insert(
                        Meeting(
                            id: self.uuid(),
                            date: self.now,
                            transcript: transcript
                        ),
                        at: 0
                    )
                    guard let standup = state.path[id: detailID, case: \.detail]?.standup
                    else { return .none }
                    state.standupsList.standups[id: standup.id] = standup
                    return .none
                }
                
            case .path:
                return .none
                
            case .standupsList:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            Path()
        }
        
        Reduce { state, _ in
            .run { [standups = state.standupsList.standups] _ in
                enum CancelID { case saveDebounce }
                
                try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
                    try await self.clock.sleep(for: .seconds(1))
                    try saveData(
                        JSONEncoder().encode(standups), .standups
                    )
                }
            }
        }
    }
}

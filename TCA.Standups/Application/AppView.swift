//
//  AppView.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 01.10.2025.
//

import ComposableArchitecture
import SwiftUI
import CasePaths

struct AppView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: \.path)) {
            StandupsListView(
                store: store.scope(state: \.standupsList, action: \.standupsList)
            )
        } destination: { state in
            switch state {
            case .detail:
                CaseLet(
                    /AppFeature.Path.State.detail,
                     action: AppFeature.Path.Action.detail,
                     then: StandupDetailView.init(store:)
                )
                
            case let .meeting(meeting, standup: standup):
                MeetingView(meeting: meeting, standup: standup)
                
            case .recordMeeting:
                CaseLet(
                    /AppFeature.Path.State.recordMeeting,
                     action: AppFeature.Path.Action.recordMeeting,
                     then: RecordMeetingView.init(store:)
                )
            }
        }
    }
}

extension URL {
    static let standups = Self.documentsDirectory.appending(component: "standups.json")
}

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State()
            )
        ) {
            AppFeature()
                ._printChanges()
        }
    )
}

#Preview("Quick finish meeting") {
    var standup = Standup.mock
    let _ = standup.duration = .seconds(6)
    AppView(
        store: Store(
            initialState: AppFeature.State(
                path: StackState([
                    .detail(
                        StandupDetailFeature.State(standup: standup)
                    ),
                    .recordMeeting(
                        RecordMeetingFeature.State(standup: standup)
                    )
                ])
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.dataManager = .mock(
                initialData: try? JSONEncoder().encode([standup])
            )
        }
    )
}

//
//  StandupsListView.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 20.09.2025.
//

import SwiftUI
import ComposableArchitecture

struct StandupsListView: View {
    @Bindable var store: StoreOf<StandupsListFeature>
    
    var body: some View {
        List {
            ForEach(store.state.standups) { standup in
                NavigationLink(
                    state: AppFeature.Path.State.detail(StandupDetailFeature.State(standup: standup))
                ) {
                    CardView(standup: standup)
                }
                .listRowBackground(standup.theme.mainColor)
            }
        }
        .navigationTitle("Daily Standups")
        .toolbar {
            ToolbarItem {
                Button("Add") {
                    store.send(.addButtonTapped)
                }
            }
        }
        .sheet(store: store.scope(state: \.$addStandup, action: \.addStandup)) { standupFormStore in
            NavigationStack {
                StandupFormView(store: standupFormStore)
                    .navigationTitle("New standup")
                    .toolbar {
                        ToolbarItem {
                            Button("Save") {
                                store.send(.saveStandupButtonTapped)
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                store.send(.cancelStandupButtonTapped)
                            }
                        }
                    }
            }
        }
    }
}

#Preview("List") {
    NavigationStack {
        StandupsListView(
            store: Store(initialState: StandupsListFeature.State()) {
                StandupsListFeature()
                    ._printChanges()
            }
        )
    }
}

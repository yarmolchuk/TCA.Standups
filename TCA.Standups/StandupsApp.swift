//
//  StandupsApp.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 20.09.2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppFeature.State(
                        standupsList: StandupsListFeature.State(),
                        path: StackState([])
                    )
                ) {
                    AppFeature()
                        ._printChanges()
                }
            )
        }
    }
}

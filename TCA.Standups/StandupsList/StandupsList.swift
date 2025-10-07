//
//  StandupsList.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 20.09.2025.
//

import SwiftUI
import ComposableArchitecture
import Tagged

@Reducer
struct StandupsListFeature {
    @Dependency(\.uuid) var uuid
   
    @ObservableState
    struct State: Equatable {
        @Presents
        var addStandup: StandupFormFeature.State?
        var standups: IdentifiedArrayOf<Standup> = []
        
        init(addStandup: StandupFormFeature.State? = nil) {
            self.addStandup = addStandup

            do {
                @Dependency(\.dataManager.load) var loadData
                self.standups = try JSONDecoder().decode(IdentifiedArrayOf<Standup>.self, from: loadData(.standups))
            } catch {
                self.standups = []
            }
        }
    }
    
    enum Action {
        case addButtonTapped
        case addStandup(PresentationAction<StandupFormFeature.Action>)
        case cancelStandupButtonTapped
        case saveStandupButtonTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                state.addStandup = StandupFormFeature.State(
                    standup: Standup(id: uuid())
                )
                return .none
                
            case .addStandup:
                return .none
                
            case .cancelStandupButtonTapped:
                state.addStandup = nil
                
                return .none
                
            case .saveStandupButtonTapped:
                guard let standup = state.addStandup?.standup else { return .none }
                state.standups.append(standup)
                state.addStandup = nil
                
                return .none
            }
        }
        .ifLet(\.$addStandup, action: \.addStandup) {
            StandupFormFeature()
        }
    }
}

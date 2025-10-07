//
//  StandupsListTests.swift
//  TCA.StandupsTests
//
//  Created by Yarmolchuk on 29.09.2025.
//

@preconcurrency import ComposableArchitecture
import XCTest

@testable import TCA_Standups
internal import Tagged

@MainActor
final class StandupsListTests: XCTestCase {
    func testAddStandup() async {
        let store = TestStore(initialState: StandupsListFeature.State()) {
            StandupsListFeature()
        } withDependencies: {
            $0.dataManager = .mock()
            $0.uuid = .incrementing
        }
        
        var standup = Standup(
            id: UUID(0),
            attendees: [Attendee(id: UUID(1))]
        )
        await store.send(.addButtonTapped) {
            $0.addStandup = StandupFormFeature.State(
                standup: standup
            )
        }
        standup.title = "Point-Free Morning Sync"
        await store.send(.addStandup(
            PresentationAction.presented(
                StandupFormFeature.Action.binding(.set(\.standup, standup))
            ))
        ) {
            $0.addStandup?.standup.title = "Point-Free Morning Sync"
        }
        await store.send(.saveStandupButtonTapped) {
            $0.addStandup = nil
            $0.standups = [
                Standup(
                    id: UUID(0),
                    attendees: [Attendee(id: UUID(1))],
                    title: "Point-Free Morning Sync"
                )
            ]
        }
    }
    
    func testAddStandup_NonExhaustive() async {
        let store = TestStore(initialState: StandupsListFeature.State()) {
            StandupsListFeature()
        } withDependencies: {
            $0.dataManager = .mock()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off(showSkippedAssertions: true)
        
        var standup = Standup(
            id: UUID(0),
            attendees: [Attendee(id: UUID(1))]
        )
        
        await store.send(.addButtonTapped)
        standup.title = "Point-Free Morning Sync"
        
        await store.send(
            .addStandup(
                PresentationAction.presented(
                    StandupFormFeature.Action.binding(.set(\.standup, standup))
                )
            )
        )
        await store.send(.saveStandupButtonTapped) {
            $0.standups = [
                Standup(
                    id: UUID(0),
                    attendees: [Attendee(id: UUID(1))],
                    title: "Point-Free Morning Sync"
                )
            ]
        }
    }
}

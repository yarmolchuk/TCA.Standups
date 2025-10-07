//
//  StandupFormTests.swift
//  TCA.StandupsTests
//
//  Created by Yarmolchuk on 27.09.2025.
//

import XCTest
import ComposableArchitecture
internal import Tagged

@testable import TCA_Standups

final class StandupFormTests: XCTestCase {
    func testAddDeleteAttendee() async {
        let store = await TestStore(
            initialState: StandupFormFeature.State(
                standup: Standup(
                    id: UUID(),
                    attendees: [
                        Attendee(id: UUID())
                    ]
                )
            )
        ) {
            StandupFormFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        
        await store.send(.addAttendeeButtonTapped) {
            $0.focus = .attendee(UUID(0))
            $0.standup.attendees.append(
                Attendee(id: UUID(0))
            )
        }
        await store.send(.deleteAttendees(atOffsets: [1])) {
            $0.focus = .attendee($0.standup.attendees[0].id)
            $0.standup.attendees.remove(at: 1)
        }
    }
}

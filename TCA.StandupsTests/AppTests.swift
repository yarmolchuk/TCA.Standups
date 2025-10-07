//
//  AppTests.swift
//  TCA.StandupsTests
//
//  Created by Yarmolchuk on 02.10.2025.
//

@preconcurrency import ComposableArchitecture
import XCTest

@testable import TCA_Standups
internal import Speech

@MainActor
final class AppTests: XCTestCase {
    func testEdit() async {
        let standup = Standup.mock
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State()
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
        }
        
        await store.send(.path(.push(id: 0, state: .detail(StandupDetailFeature.State(standup: standup))))) {
            $0.path[id: 0] = .detail(StandupDetailFeature.State(standup: standup))
        }
        await store.send(.path(.element(id: 0, action: .detail(.editButtonTapped)))) {
            $0.path[id: 0, case: \.detail]?.destination = .editStandup(StandupFormFeature.State(standup: standup))
        }
        var editedStandup = standup
        editedStandup.title = "Point-Free Morning Sync"
        
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .detail(
                        .destination(
                            PresentationAction.presented(
                                .editStandup(
                                    StandupFormFeature.Action.binding(.set(\.standup, editedStandup))
                                )
                            )
                        )
                    )
                )
            )
        ) {
            $0.path[id: 0, case: \.detail]?
                .$destination[case: \.editStandup]?
                .standup.title = "Point-Free Morning Sync"
        }
        await store.send(.path(.element(id: 0, action: .detail(.saveStandupButtonTapped)))) {
            $0.path[id: 0, case: \.detail]?.destination = nil
            $0.path[id: 0, case: \.detail]?.standup.title = "Point-Free Morning Sync"
        }
        await store.receive(\.path) {
            $0.standupsList.standups[0].title = "Point-Free Morning Sync"
        }
    }
    
    func testEdit_NonExhaustive() async {
        let standup = Standup.mock
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State()
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
        }
        store.exhaustivity = .off
        
        await store.send(.path(.push(id: 0, state: .detail(StandupDetailFeature.State(standup: standup)))))
        await store.send(.path(.element(id: 0, action: .detail(.editButtonTapped))))
        
        var editedStandup = standup
        editedStandup.title = "Point-Free Morning Sync"
        
        await store.send(.path(.element(id: 0, action: .detail(.destination(.presented(.editStandup(
            .binding(.set(\.standup, editedStandup))
        )))))))
        
        await store.send(.path(.element(id: 0, action: .detail(.saveStandupButtonTapped))))
        await store.skipReceivedActions()
        
        store.assert {
            $0.standupsList.standups[0].title = "Point-Free Morning Sync"
        }
    }
    
//    func testDeletion_NonExhaustive() async {
//        let standup = Standup.mock
//        let store = TestStore(
//            initialState: AppFeature.State(
//                standupsList: StandupsListFeature.State(),
//                path: StackState([ .detail(StandupDetailFeature.State(standup: standup)) ])
//            )
//        ) {
//            AppFeature()
//        } withDependencies: {
//            $0.continuousClock = ImmediateClock()
//            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
//        }
//        store.exhaustivity = .off
//
//        await store.send(
//            .path(.element(id: 0, action: .detail(.deleteButtonTapped)))
//        )
//        await store.send(
//            .path(.element(id: 0, action: .detail(.alert(.presented(.confirmDeletion)))))
//        )
//        await store.skipReceivedActions()
//
//        store.assert {
//            $0.path = StackState([])
//            $0.standupsList.standups = []
//        }
//    }
    
//    func _testTimerRunOutEndMeeting() async {
//        let standup = Standup(
//            id: UUID(),
//            attendees: [Attendee(id: UUID())],
//            duration: .seconds(1),
//            meetings: [],
//            theme: .bubblegum,
//            title: "Point-Free"
//        )
//        let store: TestStoreOf<AppFeature> = TestStore(
//            initialState: AppFeature.State(
//                standupsList: StandupsListFeature.State(),
//                path: StackState([
//                    .detail(StandupDetailFeature.State(standup: standup)),
//                    .recordMeeting(RecordMeetingFeature.State(standup: standup)),
//                ])
//            )
//        ) {
//            AppFeature()
//        } withDependencies: {
//            $0.continuousClock = ImmediateClock()
//            $0.date.now = Date(timeIntervalSince1970: 1234567890)
//            $0.speechClient.requestAuthorization = { .denied }
//            $0.uuid = .incrementing
//            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
//        }
//        store.exhaustivity = .off
//        
//        await store.send(.path(.element(id: 1, action: .recordMeeting(.onTask))))
//        // await store.receive(\.path[id: 1].recordMeeting.delegate.saveMeeting) // TODO: Fix me
//        await store.receive(\.path.popFrom)
//        
//        await store.skipReceivedActions()
//        
//        store.assert {
//            $0.path[id: 0, case: \.detail]?.standup.meetings = [
//                Meeting(
//                    id: UUID(0),
//                    date: Date(timeIntervalSince1970: 1234567890),
//                    transcript: ""
//                )
//            ]
//            XCTAssertEqual($0.path.count, 1)
//        }
//    }
    
    func testEndMeetingEarlyDiscard() async {
        let standup = Standup(
            id: UUID(),
            attendees: [Attendee(id: UUID())],
            duration: .seconds(1),
            meetings: [],
            theme: .bubblegum,
            title: "Point-Free"
        )
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State(),
                path: StackState([
                    .detail(StandupDetailFeature.State(standup: standup)),
                    .recordMeeting(RecordMeetingFeature.State(standup: standup)),
                ])
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.speechClient.requestAuthorization = { .denied }
            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
        }
        store.exhaustivity = .off
        
        await store.send(.path(.element(id: 1, action: .recordMeeting(.onTask))))
        await store.send(.path(.element(id: 1, action: .recordMeeting(.endMeetingButtonTapped))))
        await store.send(.path(.element(id: 1, action: .recordMeeting(.alert(.presented(.confirmDiscard))))))
        await store.skipReceivedActions()

        store.assert {
            $0.path[id: 0, case: \.detail]?.standup.meetings = []
            XCTAssertEqual($0.path.count, 1)
        }
    }
    
//    func testTimerRunOutEndMeeting_WithSpeechRecognizer() async {
//        let standup = Standup(
//            id: UUID(),
//            attendees: [Attendee(id: UUID())],
//            duration: .seconds(1),
//            meetings: [],
//            theme: .bubblegum,
//            title: "Point-Free"
//        )
//
//        let store = TestStore(
//            initialState: AppFeature.State(
//                standupsList: StandupsListFeature.State(),
//                path: StackState([
//                    .detail(
//                        StandupDetailFeature.State(standup: standup)
//                    ),
//                    .recordMeeting(
//                        RecordMeetingFeature.State(standup: standup)
//                    ),
//                ])
//            )
//        ) {
//            AppFeature()
//        } withDependencies: {
//            $0.continuousClock = ImmediateClock()
//            $0.date.now = Date(timeIntervalSince1970: 1234567890)
//            $0.uuid = .incrementing
//            $0.speechClient.requestAuthorization = { .authorized }
//            $0.speechClient.start = {
//                AsyncThrowingStream {
//                    $0.yield("This was a good meeting!")
//                }
//            }
//            $0.dataManager = .mock(initialData: try? JSONEncoder().encode([standup]))
//            $0.uuid = .incrementing
//        }
//        store.exhaustivity = .off
//
//        await store.send(
//            .path(.element(id: 1, action: .recordMeeting(.onTask)))
//        )
//        await store.skipReceivedActions()
//        store.assert {
//            $0.path[id: 0, case: \.detail]?
//                .standup.meetings = [
//                    Meeting(
//                        id: UUID(0),
//                        date: Date(timeIntervalSince1970: 1234567890),
//                        transcript: "This was a good meeting!"
//                    )
//                ]
//            XCTAssertEqual($0.path.count, 1)
//        }
//    }
    
    func testAdd() async {
        let store = TestStore(
            initialState: AppFeature.State(
                standupsList: StandupsListFeature.State()
            )
        ) {
            AppFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off
        
        await store.send(.standupsList(.addButtonTapped))
        await store.send(.standupsList(.saveStandupButtonTapped))
        
        store.assert {
            $0.standupsList.standups = [
                Standup(
                    id: UUID(0),
                    attendees: [Attendee(id: UUID(1))]
                )
            ]
        }
    }
}

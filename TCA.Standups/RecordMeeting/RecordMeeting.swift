//
//  RecordMeeting.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 03.10.2025.
//

import Foundation
import ComposableArchitecture
import Speech
import SwiftUI

@Reducer
struct RecordMeetingFeature {
    @Dependency(\.continuousClock) var clock
    @Dependency(\.speechClient) var speechClient
    @Dependency(\.dismiss) var dismiss
    
    @ObservableState
    struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        
        var secondsElapsed = 0
        var speakerIndex = 0
        let standup: Standup
        var transcript = ""
        
        var durationRemaining: Duration {
            self.standup.duration - .seconds(self.secondsElapsed)
        }
    }
    
    enum Action: Equatable {
        case speechResult(String)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case timerTicked
        case endMeetingButtonTapped
        case nextButtonTapped
        case onTask
       
        enum Alert {
            case confirmDiscard
            case confirmSave
        }
        
        enum Delegate: Equatable {
            case saveMeeting(transcript: String)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .speechResult(transcript):
                state.transcript = transcript
                
                return .none
                
            case .alert(.presented(.confirmDiscard)):
                return .run { _ in await self.dismiss() }
                
            case .alert(.presented(.confirmSave)):
                return .run { [transcript = state.transcript] send in
                    await send(
                        .delegate(.saveMeeting(transcript: transcript))
                    )
                    await self.dismiss()
                }
                
            case .alert(.dismiss):
                return .none
                
            case .delegate:
                return .none
                
            case .endMeetingButtonTapped:
                state.alert = .endMeeting(isDiscardable: false)
                
                return .none
                
            case .nextButtonTapped:
                guard
                    state.speakerIndex < state.standup.attendees.count - 1
                else {
                    state.alert = .endMeeting(isDiscardable: false)
                    return .none
                }
    
                state.speakerIndex += 1
                state.secondsElapsed = state.speakerIndex * Int(
                    state.standup.durationPerAttendee.components.seconds
                )
                return .none
                
            case .onTask:
                return .run(operation: onTask)
                
            case .timerTicked:
                guard state.alert == nil else { return .none }
                state.secondsElapsed += 1
                
                let secondsPerAttendee = Int(state.standup.durationPerAttendee.components.seconds)
                
                if state.secondsElapsed.isMultiple(of: secondsPerAttendee) {
                    if state.speakerIndex == state.standup.attendees.count - 1 {
                        return .run { [transcript = state.transcript] send in
                            await send(
                                .delegate(.saveMeeting(transcript: transcript))
                            )
                            await dismiss()
                        }
                    }
                    state.speakerIndex += 1
                }
                
                return .none
                
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

private extension RecordMeetingFeature {
    func onTask(send: Send<Action>) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                guard await self.speechClient.requestAuthorization() == .authorized else { return }
                
                do {
                    for try await transcript in self.speechClient.start() {
                        await send(.speechResult(transcript))
                    }
                } catch {}
            }
            
            group.addTask {
                for await _ in self.clock.timer(interval: .seconds(1)) {
                    await send(.timerTicked)
                }
            }
        }
    }
}

extension AlertState where Action == RecordMeetingFeature.Action.Alert {
    static func endMeeting(isDiscardable: Bool) -> Self {
        Self {
            TextState("End meeting?")
        } actions: {
            ButtonState(action: .confirmSave) {
                TextState("Save and end")
            }
            if isDiscardable {
                ButtonState(
                    role: .destructive, action: .confirmDiscard
                ) {
                    TextState("Discard")
                }
            }
            ButtonState(role: .cancel) {
                TextState("Resume")
            }
        } message: {
            TextState(
                """
                You are ending the meeting early. \
                What would you like to do?
                """
            )
        }
    }
}

//
//  RecordMeetingView.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 03.10.2025.
//

import ComposableArchitecture
import SwiftUI

struct RecordMeetingView: View {
    let store: StoreOf<RecordMeetingFeature>
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(store.standup.theme.mainColor)
            
            VStack {
                MeetingHeaderView(
                    secondsElapsed: store.secondsElapsed,
                    durationRemaining: store.durationRemaining,
                    theme: store.standup.theme
                )
                MeetingTimerView(
                    standup: store.standup,
                    speakerIndex: store.speakerIndex
                )
                MeetingFooterView(
                    standup: store.standup,
                    nextButtonTapped: {
                        store.send(.nextButtonTapped)
                    },
                    speakerIndex: store.speakerIndex
                )
            }
        }
        .padding()
        .foregroundColor(store.standup.theme.accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("End meeting") {
                    store.send(.endMeetingButtonTapped)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await store.send(.onTask).finish()
        }
        .alert(store: store.scope(state: \.$alert, action: \.alert))
    }
}

struct MeetingHeaderView: View {
    let secondsElapsed: Int
    let durationRemaining: Duration
    let theme: Theme
    
    var body: some View {
        VStack {
            ProgressView(value: self.progress)
                .progressViewStyle(
                    MeetingProgressViewStyle(theme: self.theme)
                )
            HStack {
                VStack(alignment: .leading) {
                    Text("Time Elapsed")
                        .font(.caption)
                    Label(
                        Duration.seconds(self.secondsElapsed)
                            .formatted(.units()),
                        systemImage: "hourglass.bottomhalf.fill"
                    )
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Time Remaining")
                        .font(.caption)
                    Label(
                        self.durationRemaining.formatted(.units()),
                        systemImage: "hourglass.tophalf.fill"
                    )
                    .font(.body.monospacedDigit())
                    .labelStyle(.trailingIcon)
                }
            }
        }
        .padding([.top, .horizontal])
    }
    
    private var totalDuration: Duration {
        .seconds(self.secondsElapsed) + self.durationRemaining
    }
    
    private var progress: Double {
        guard self.totalDuration > .seconds(0)
        else { return 0 }
        return Double(self.secondsElapsed)
        / Double(self.totalDuration.components.seconds)
    }
}

struct MeetingProgressViewStyle: ProgressViewStyle {
    var theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(self.theme.accentColor)
                .frame(height: 20)
            
            ProgressView(configuration)
                .tint(self.theme.mainColor)
                .frame(height: 12)
                .padding(.horizontal)
        }
    }
}

struct MeetingTimerView: View {
    let standup: Standup
    let speakerIndex: Int
    
    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 24)
            .overlay {
                VStack {
                    Group {
                        if self.speakerIndex < self.standup.attendees.count {
                            Text(
                                self.standup.attendees[self.speakerIndex]
                                    .name
                            )
                        } else {
                            Text("Someone")
                        }
                    }
                    .font(.title)
                    Text("is speaking")
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .padding(.top)
                }
                .foregroundStyle(self.standup.theme.accentColor)
            }
            .overlay {
                ForEach(
                    Array(self.standup.attendees.enumerated()),
                    id: \.element.id
                ) { index, attendee in
                    if index < self.speakerIndex + 1 {
                        SpeakerArc(
                            totalSpeakers: self.standup.attendees.count,
                            speakerIndex: index
                        )
                        .rotation(Angle(degrees: -90))
                        .stroke(
                            self.standup.theme.mainColor, lineWidth: 12
                        )
                    }
                }
            }
            .padding(.horizontal)
    }
}

struct SpeakerArc: Shape {
    let totalSpeakers: Int
    let speakerIndex: Int
    
    func path(in rect: CGRect) -> Path {
        let diameter = min(rect.size.width, rect.size.height) - 24
        let radius = diameter / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: self.startAngle,
                endAngle: self.endAngle,
                clockwise: false
            )
        }
    }
    
    private var degreesPerSpeaker: Double {
        360 / Double(self.totalSpeakers)
    }
    private var startAngle: Angle {
        Angle(
            degrees: self.degreesPerSpeaker
            * Double(self.speakerIndex)
            + 1
        )
    }
    private var endAngle: Angle {
        Angle(
            degrees: self.startAngle.degrees
            + self.degreesPerSpeaker
            - 1
        )
    }
}

struct MeetingFooterView: View {
    let standup: Standup
    var nextButtonTapped: () -> Void
    let speakerIndex: Int
    
    var body: some View {
        VStack {
            HStack {
                if self.speakerIndex
                    < self.standup.attendees.count - 1 {
                    Text(
                        """
                        Speaker \(self.speakerIndex + 1) \
                        of \(self.standup.attendees.count)
                        """
                    )
                } else {
                    Text("No more speakers.")
                }
                Spacer()
                Button(action: self.nextButtonTapped) {
                    Image(systemName: "forward.fill")
                }
            }
        }
        .padding([.bottom, .horizontal])
    }
}

#Preview {
    NavigationStack {
        RecordMeetingView(
            store: Store(initialState: RecordMeetingFeature.State(standup: .mock)) {
                RecordMeetingFeature()
            }
        )
    }
}

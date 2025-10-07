//
//  MeetingView.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 06.10.2025.
//

import SwiftUI

struct MeetingView: View {
    let meeting: Meeting
    let standup: Standup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                    .padding(.bottom)
                Text("Attendees")
                    .font(.headline)
                ForEach(self.standup.attendees) { attendee in
                    Text(attendee.name)
                }
                Text("Transcript")
                    .font(.headline)
                    .padding(.top)
                Text(self.meeting.transcript)
            }
        }
        .navigationTitle(Text(self.meeting.date, style: .date))
        .padding()
    }
}

#Preview {
    MeetingView(
        meeting: .init(id: UUID(), date: Date(), transcript: ""),
        standup: .mock
    )
}

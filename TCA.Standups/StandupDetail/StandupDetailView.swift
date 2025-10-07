//
//  StandupDetail.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 30.09.2025.
//

import ComposableArchitecture
import SwiftUI

struct StandupDetailView: View {
    let store: StoreOf<StandupDetailFeature>
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    // Do something
                } label: {
                    Label("Start Meeting", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Length", systemImage: "clock")
                    Spacer()
                    Text(store.standup.duration.formatted(.units()))
                }
                
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text("Bubblegum")
                        .padding(4)
                        .foregroundColor(store.standup.theme.accentColor)
                        .background(store.standup.theme.mainColor)
                        .cornerRadius(4)
                }
            } header: {
                Text("Standup Info")
            }
            
            if !store.standup.meetings.isEmpty {
                Section {
                    ForEach(store.standup.meetings) { meeting in
                        NavigationLink(
                            state: AppFeature.Path.State.meeting(meeting, standup: store.standup)
                        ) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                        store.send(.deleteMeetings(atOffsets: indices))
                    }
                } header: {
                    Text("Past meetings")
                }
            }
            
            Section {
                ForEach(store.standup.attendees) { attendee in
                    Label(attendee.name, systemImage: "person")
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Button("Delete") {
                    store.send(.deleteButtonTapped)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(store.standup.title)
        .toolbar {
            Button("Edit") {
                store.send(.editButtonTapped)
            }
        }
        .alert(
            store: store.scope(state: \.$destination, action: \.destination),
            state: \.alert,
            action: StandupDetailFeature.Destination.Action.alert
        )
        .sheet(
            store: store.scope(state: \.$destination, action: \.destination),
            state: \.editStandup,
            action: StandupDetailFeature.Destination.Action.editStandup
        ) { sheetStore in
            NavigationStack {
                StandupFormView(store: sheetStore)
                    .navigationTitle("Edit standup")
                    .toolbar {
                        ToolbarItem {
                            Button("Save") {
                                store.send(.saveStandupButtonTapped)
                                
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                store.send(.cancelEditStandupButtonTapped)
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StandupDetailView(
            store: Store(initialState: StandupDetailFeature.State(standup: .mock)) {
                StandupDetailFeature()
            }
        )
    }
}

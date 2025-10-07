//
//  StandupFormView.swift
//  TCA.Standups
//
//  Created by Yarmolchuk on 22.09.2025.
//

import SwiftUI
import ComposableArchitecture

struct StandupFormView: View {
    @Bindable var store: StoreOf<StandupFormFeature>
    @FocusState var focus: StandupFormFeature.State.Field?
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $store.standup.title)
                    .focused($focus, equals: .title)
                HStack {
                    Slider(
                        value: $store.standup.duration.minutes,
                        in: 5...30,
                        step: 1
                    ) {
                        Text("Length")
                    }
                    Spacer()
                    Text(
                        store.standup.duration.formatted(.units())
                    )
                }
                ThemePicker(selection: $store.standup.theme)
            } header: {
                Text("Standup Info")
            }
            Section {
                ForEach(
                    $store.standup.attendees
                ) { $attendee in
                    TextField("Name", text: $attendee.name)
                        .focused(
                            $focus, equals: .attendee(attendee.id)
                        )
                }
                .onDelete { indices in
                    store.send(
                        .deleteAttendees(atOffsets: indices)
                    )
                }
                
                Button("Add attendee") {
                    store.send(.addAttendeeButtonTapped)
                }
            } header: {
                Text("Attendees")
            }
        }
        .bind($store.focus, to: $focus)
    }
}

struct ThemePicker: View {
    @Binding var selection: Theme
    
    var body: some View {
        Picker("Theme", selection: $selection) {
            ForEach(Theme.allCases) { theme in
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.mainColor)
                    
                    Label(theme.name, systemImage: "paintpalette")
                        .padding(4)
                }
                .foregroundColor(theme.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .tag(theme)
            }
        }
    }
}

extension Duration {
    fileprivate var minutes: Double {
        get { Double(self.components.seconds / 60) }
        set { self = .seconds(newValue * 60) }
    }
}

#Preview {
    NavigationStack {
        StandupFormView(
            store: Store(initialState: StandupFormFeature.State(standup: .mock)) {
                StandupFormFeature()
                    ._printChanges()
            }
        )
    }
}

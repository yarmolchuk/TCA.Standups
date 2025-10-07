# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift iOS application built with SwiftUI and The Composable Architecture (TCA) for managing standups. The project follows TCA patterns with reducers, state management, and effects.

## Architecture

- **TCA (The Composable Architecture)**: Uses @Reducer structs with @ObservableState and typed Actions
- **State Management**: Each feature has its own State struct with Equatable and Sendable conformance
- **Dependencies**: Uses @Dependency property wrapper for dependency injection (e.g., UUID generation)
- **Models**: Core data models use Tagged<Self, UUID> for type-safe IDs
- **UI**: SwiftUI views with TCA integration

### Key Components

- `StandupsApp.swift`: Main app entry point
- `Models/Standup.swift`: Core data models (Standup, Attendee, Meeting, Theme) with Tagged IDs
- `StandupsList/`: List feature with reducer and view
- `Standup/StandupForm.swift`: Form feature for creating/editing standups with focus management
- `ContentView.swift`: Currently a placeholder view

### Dependencies

- **ComposableArchitecture**: Main architecture framework
- **Tagged**: Type-safe wrapper for primitive types (used for IDs)
- **SwiftUI**: UI framework

## Development Commands

This is an Xcode project. Common development tasks:

### Building and Running
```bash
# Build the project
xcodebuild -project TCA.Standups.xcodeproj -scheme "TCA.Standups" -configuration Debug

# Run tests
xcodebuild test -project TCA.Standups.xcodeproj -scheme "TCA.Standups"
```

### Xcode Integration
- Open `TCA.Standups.xcodeproj` in Xcode
- Use Xcode's built-in build (⌘+B) and run (⌘+R) commands
- Tests can be run with ⌘+U

## Key Patterns

- **Reducers**: Use @Reducer macro with reduce(into:action:) -> Effect<Action> method
- **State**: @ObservableState structs that are Equatable and Sendable
- **Actions**: Enums conforming to Equatable and Sendable, often with BindableAction
- **Focus Management**: StandupForm uses Field enum for managing text field focus
- **Mock Data**: Models include static mock data for testing and previews
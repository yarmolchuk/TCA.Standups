//
//  Theme.swift
//  TCA.Standups
//
//  Created by Assistant on 23.09.2025.
//

import SwiftUI

enum Theme: String, CaseIterable, Equatable, Identifiable, Codable, Sendable {
    case bubblegum
    case buttercup
    case indigo
    case lavender
    case magenta
    case navy
    case orange
    case oxblood
    case periwinkle
    case poppy
    case purple
    case seafoam
    case sky
    case tan
    case teal
    case yellow
    
    var id: Self { self }
    
    var accentColor: Color {
        switch self {
        case .bubblegum, .buttercup, .lavender, .orange, .periwinkle, .poppy, .seafoam, .sky, .tan, .teal, .yellow:
            return .black
        case .indigo, .magenta, .navy, .oxblood, .purple:
            return .white
        }
    }
    
    var mainColor: Color { Color(rawValue) }
    var name: String { rawValue.capitalized }
}

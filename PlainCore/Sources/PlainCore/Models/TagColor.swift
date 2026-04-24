import SwiftUI

public enum TagColor: Int, CaseIterable, Sendable {
    case red = 0       // #FF3B30
    case orange = 1    // #FF9500
    case yellow = 2    // #FFCC00
    case green = 3     // #34C759
    case teal = 4      // #5AC8FA
    case blue = 5      // #007AFF
    case indigo = 6    // #5856D6
    case purple = 7    // #AF52DE
    case pink = 8      // #FF2D55
    case brown = 9     // #A2845E
    case lime = 10     // #A8D600
    case gray = 11     // #8E8E93

    public var foregroundColor: Color {
        switch self {
        case .red:    Color(red: 1.00, green: 0.23, blue: 0.19)
        case .orange: Color(red: 1.00, green: 0.58, blue: 0.00)
        case .yellow: Color(red: 1.00, green: 0.80, blue: 0.00)
        case .green:  Color(red: 0.20, green: 0.78, blue: 0.35)
        case .teal:   Color(red: 0.35, green: 0.78, blue: 0.98)
        case .blue:   Color(red: 0.00, green: 0.48, blue: 1.00)
        case .indigo: Color(red: 0.35, green: 0.34, blue: 0.84)
        case .purple: Color(red: 0.69, green: 0.32, blue: 0.87)
        case .pink:   Color(red: 1.00, green: 0.18, blue: 0.33)
        case .brown:  Color(red: 0.64, green: 0.52, blue: 0.37)
        case .lime:   Color(red: 0.66, green: 0.84, blue: 0.00)
        case .gray:   Color(red: 0.56, green: 0.56, blue: 0.58)
        }
    }

    public var backgroundColor: Color {
        foregroundColor.opacity(0.15)
    }

    public static func from(index: Int) -> TagColor {
        TagColor(rawValue: index) ?? .blue
    }
}

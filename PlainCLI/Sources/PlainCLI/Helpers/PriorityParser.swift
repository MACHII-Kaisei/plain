import PlainCore

enum PriorityParser {
    static func parse(_ string: String) -> Priority? {
        switch string.lowercased() {
        case "high", "h", "高": return .high
        case "medium", "m", "中": return .medium
        case "low", "l", "低": return .low
        default: return nil
        }
    }

    static func label(_ priority: Priority) -> String {
        switch priority {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
}

import Foundation
import PlainCore

enum OutputFormatter {
    static func shortID(_ uuid: UUID) -> String {
        String(uuid.uuidString.prefix(6)).lowercased()
    }

    static func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "MM/dd HH:mm"
        return f.string(from: date)
    }

    static func sectionLabel(_ section: TaskSection) -> String {
        switch section {
        case .today: return "今日"
        case .tomorrow: return "明日"
        case .upcoming: return "これから"
        case .overdue: return "期限切れ"
        case .someday: return "いつか"
        case .completed: return "完了済み"
        }
    }
}

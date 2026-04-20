import Foundation

enum DateParser {
    /// 日付文字列をパースする
    /// - "today" → 今日
    /// - "tomorrow" → 明日
    /// - "YYYY-MM-DD" → 指定日
    /// - "MM-DD" → 今年の指定月日（過去なら来年）
    /// - "+Nd" → N日後
    static func parseDate(_ string: String) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        switch string.lowercased() {
        case "today":
            return today
        case "tomorrow":
            return cal.date(byAdding: .day, value: 1, to: today)
        default:
            break
        }

        // +Nd パターン
        if string.hasPrefix("+"), string.hasSuffix("d"),
           let n = Int(string.dropFirst().dropLast()) {
            return cal.date(byAdding: .day, value: n, to: today)
        }

        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")

        // YYYY-MM-DD
        isoFormatter.dateFormat = "yyyy-MM-dd"
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // MM-DD（今年、過去なら来年）
        isoFormatter.dateFormat = "MM-dd"
        if let date = isoFormatter.date(from: string) {
            var comps = cal.dateComponents([.month, .day], from: date)
            comps.year = cal.component(.year, from: today)
            if let candidate = cal.date(from: comps) {
                if candidate < today {
                    comps.year = cal.component(.year, from: today) + 1
                    return cal.date(from: comps)
                }
                return candidate
            }
        }

        return nil
    }

    /// 時刻文字列（HH:mm）をパースし、日付に適用する
    static func applyTime(_ timeString: String, to date: Date) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]), hour >= 0, hour <= 23,
              let minute = Int(parts[1]), minute >= 0, minute <= 59 else {
            return nil
        }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        return cal.date(from: comps)
    }

    /// 日付 + 時刻を組み合わせてパース。時刻省略時は 09:00
    static func parse(due: String?, at time: String?) -> Date? {
        guard let due else { return nil }
        guard var date = parseDate(due) else { return nil }
        let timeStr = time ?? "09:00"
        if let withTime = applyTime(timeStr, to: date) {
            date = withTime
        }
        return date
    }
}

import SwiftUI
import WidgetKit
import PlainCore

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Plain - 今日")
        .description("今日と明日のタスクを表示します。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

import SwiftUI
import WidgetKit
import PlainCore

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Plain - TODO")
        .description("未完了タスクを期限が近い順に表示します。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

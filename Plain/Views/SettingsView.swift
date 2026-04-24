import SwiftUI

struct SettingsView: View {
    @AppStorage("completedRetentionDays") private var retentionDays: Int = 7

    private let retentionPresets: [(days: Int, label: String)] = [
        (3,   "3日間"),
        (7,   "1週間"),
        (14,  "2週間"),
        (30,  "1ヶ月"),
        (90,  "3ヶ月"),
    ]

    var body: some View {
        Form {
            Section("表示") {
                Picker("完了タスクの保持期間", selection: $retentionDays) {
                    ForEach(retentionPresets, id: \.days) { preset in
                        Text(preset.label).tag(preset.days)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 200)
    }
}

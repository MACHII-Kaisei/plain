import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationLeadMinutes") private var leadMinutes: Int = 0

    private let presets: [(minutes: Int, label: String)] = [
        (0,    "ちょうど"),
        (5,    "5分前"),
        (10,   "10分前"),
        (15,   "15分前"),
        (30,   "30分前"),
        (60,   "1時間前"),
        (120,  "2時間前"),
        (180,  "3時間前"),
        (360,  "6時間前"),
        (1440, "1日前"),
    ]

    var body: some View {
        Form {
            Section("通知") {
                Toggle("期日通知を有効にする", isOn: $notificationsEnabled)
                Picker("通知タイミング", selection: $leadMinutes) {
                    ForEach(presets, id: \.minutes) { preset in
                        Text(preset.label).tag(preset.minutes)
                    }
                }
                .disabled(!notificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 200)
    }
}

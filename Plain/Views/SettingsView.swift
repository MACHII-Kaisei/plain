import AppKit
import EventKit
import SwiftUI

struct SettingsView: View {
    @AppStorage("completedRetentionDays") private var retentionDays: Int = 0
    @AppStorage(ReminderSyncSettings.enabledKey) private var reminderSyncEnabled = false
    @State private var authStatus = EKEventStore.authorizationStatus(for: .reminder)
    @State private var lastSuccessAt: Date?
    @State private var lastError: String?
    @State private var isRefreshing = false

    private let retentionPresets: [(days: Int, label: String)] = [
        (0,   "すべて"),
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

            Section("同期") {
                Toggle("Apple リマインダーと同期", isOn: $reminderSyncEnabled)

                Text("純正リマインダーの「\(ReminderSyncSettings.listName)」リストと双方向で同期します。iPhone では標準のリマインダーアプリから閲覧・追加・完了・削除できます。タグは同期されません。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LabeledContent("権限", value: authorizationLabel)
                LabeledContent("リスト", value: ReminderSyncSettings.listName)
                LabeledContent("最終同期", value: formattedLastSuccess)

                if let lastError, !lastError.isEmpty {
                    Label(lastError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                HStack {
                    Button("今すぐ同期") {
                        isRefreshing = true
                        NotificationCenter.default.post(name: .plainReminderSyncNow, object: nil)
                        refreshState(after: 1.5)
                    }
                    .disabled(!reminderSyncEnabled || isRefreshing)

                    if isDenied {
                        Button("システム設定を開く") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }

                    Button("同期リストを再作成") {
                        ReminderSyncSettings.resetCalendarConnection()
                        isRefreshing = true
                        NotificationCenter.default.post(name: .plainReminderSyncNow, object: nil)
                        refreshState(after: 1.5)
                    }
                    .disabled(!reminderSyncEnabled || isRefreshing)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
        .onAppear { refreshState() }
        .onChange(of: reminderSyncEnabled) {
            refreshState(after: 1.0)
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            refreshState()
        }
    }

    private var isDenied: Bool {
        authStatus == .denied || authStatus == .restricted || authStatus == .writeOnly
    }

    private var authorizationLabel: String {
        switch authStatus {
        case .notDetermined:
            return "未確認"
        case .restricted:
            return "制限中"
        case .denied:
            return "拒否"
        case .fullAccess:
            return "許可済み"
        case .writeOnly:
            return "書き込みのみ"
        @unknown default:
            return "不明"
        }
    }

    private var formattedLastSuccess: String {
        guard let lastSuccessAt else { return "未同期" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastSuccessAt)
    }

    private func refreshState(after delay: TimeInterval = 0) {
        Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            authStatus = EKEventStore.authorizationStatus(for: .reminder)
            lastSuccessAt = UserDefaults.standard.object(forKey: ReminderSyncSettings.lastSuccessAtKey) as? Date
            lastError = UserDefaults.standard.string(forKey: ReminderSyncSettings.lastErrorKey)
            isRefreshing = false
        }
    }
}

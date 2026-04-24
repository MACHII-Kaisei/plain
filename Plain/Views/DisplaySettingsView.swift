import SwiftUI

struct DisplaySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("completedRetentionDays") private var retentionDays: Int = 7
    @AppStorage("showNotesInRow") private var showNotesInRow: Bool = true
    @AppStorage("showTagsInRow") private var showTagsInRow: Bool = true

    private let retentionOptions: [(days: Int, label: String)] = [
        (3,  "3日"),
        (7,  "7日"),
        (14, "14日"),
        (30, "30日"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("表示設定")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            Form {
                Section("完了済みタスク") {
                    Picker("表示期間", selection: $retentionDays) {
                        ForEach(retentionOptions, id: \.days) { option in
                            Text(option.label).tag(option.days)
                        }
                    }
                }

                Section("タスク行") {
                    Toggle("メモを表示", isOn: $showNotesInRow)
                    Toggle("タグを表示", isOn: $showTagsInRow)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 280)
        .background(Color(red: 249/255, green: 249/255, blue: 255/255))
    }
}

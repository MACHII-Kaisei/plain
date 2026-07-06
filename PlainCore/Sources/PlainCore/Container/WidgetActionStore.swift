import Foundation
import SwiftData
import Darwin

/// ウィジェット拡張が本体 DB を直接更新できない環境（adhoc 署名などで
/// Group Container へのアクセスがサンドボックスに拒否される場合）に、
/// 完了トグル操作をファイルとして書き残すためのアクション。
public struct WidgetToggleAction: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let taskID: UUID
    public let desiredCompleted: Bool
    public let createdAt: Date

    public init(id: UUID, taskID: UUID, desiredCompleted: Bool, createdAt: Date) {
        self.id = id
        self.taskID = taskID
        self.desiredCompleted = desiredCompleted
        self.createdAt = createdAt
    }
}

/// ペンディング操作のメールボックス。
/// ウィジェット拡張自身のコンテナ内ディレクトリを既定の置き場とする。
/// ウィジェットは自分のコンテナに自由に書け、本体アプリは
/// temporary-exception entitlement で同じパスを読み書きできる。
public struct WidgetActionStore {
    public let directoryURL: URL

    public init(directoryURL: URL = WidgetActionStore.defaultDirectoryURL()) {
        self.directoryURL = directoryURL
    }

    /// 本体アプリ・ウィジェットのどちらのプロセスから見ても同じ実パスになるよう、
    /// getpwuid で実ホームを解決する（サンドボックス内でも実ホームが返る）。
    public static func defaultDirectoryURL() -> URL {
        realHomeDirectory()
            .appendingPathComponent("Library/Containers/app.plain.Plain.PlainWidget/Data/Library/Application Support")
            .appendingPathComponent("PendingWidgetActions", isDirectory: true)
    }

    private static func realHomeDirectory() -> URL {
        if let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home))
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    public func enqueue(_ action: WidgetToggleAction) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.plainWidgetAction.encode(action)
        try data.write(to: fileURL(for: action), options: [.atomic])
    }

    /// createdAt 昇順（同時刻は id で安定ソート）で返す。壊れたファイルは削除して読み飛ばす。
    public func pendingActions() -> [WidgetToggleAction] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }
        var actions: [WidgetToggleAction] = []
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let action = try? JSONDecoder.plainWidgetAction.decode(WidgetToggleAction.self, from: data) else {
                try? fm.removeItem(at: file)
                continue
            }
            actions.append(action)
        }
        return actions.sorted {
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    public func remove(_ action: WidgetToggleAction) {
        try? FileManager.default.removeItem(at: fileURL(for: action))
    }

    /// ペンディング操作を DB に反映する。戻り値は消費（削除）したアクション数。
    /// 保存に失敗した場合はファイルを残して 0 を返し、次回の呼び出しで再試行する。
    @discardableResult
    public func applyPendingActions(context: ModelContext) -> Int {
        let actions = pendingActions()
        guard !actions.isEmpty else { return 0 }

        var needsSave = false
        for action in actions {
            let taskID = action.taskID
            let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == taskID })
            guard let item = try? context.fetch(descriptor).first else { continue }
            guard item.isCompleted != action.desiredCompleted else { continue }
            item.isCompleted = action.desiredCompleted
            item.completedAt = action.desiredCompleted ? action.createdAt : nil
            item.updatedAt = Date()
            needsSave = true
        }

        if needsSave {
            do {
                try context.save()
            } catch {
                return 0
            }
        }

        for action in actions {
            remove(action)
        }
        return actions.count
    }

    private func fileURL(for action: WidgetToggleAction) -> URL {
        directoryURL.appendingPathComponent("\(action.id.uuidString).json")
    }
}

private extension JSONEncoder {
    static var plainWidgetAction: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var plainWidgetAction: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}

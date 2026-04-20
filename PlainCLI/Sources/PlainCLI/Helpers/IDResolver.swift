import Foundation
import SwiftData
import PlainCore

enum IDResolverError: Error, CustomStringConvertible {
    case notFound(String)
    case ambiguous(String, Int)

    var description: String {
        switch self {
        case .notFound(let id):
            return "タスクが見つかりません: \(id)"
        case .ambiguous(let id, let count):
            return "複数のタスク(\(count)件)が一致します。もう少し長いIDを指定してください: \(id)"
        }
    }
}

enum IDResolver {
    /// 短縮ID（6文字以上）またはフルUUIDからTodoItemを解決する
    static func resolve(_ shortID: String, in context: ModelContext) throws -> TodoItem {
        let descriptor = FetchDescriptor<TodoItem>()
        let all = try context.fetch(descriptor)

        let matches = all.filter {
            $0.id.uuidString.lowercased().hasPrefix(shortID.lowercased())
        }

        switch matches.count {
        case 0:
            throw IDResolverError.notFound(shortID)
        case 1:
            return matches[0]
        default:
            throw IDResolverError.ambiguous(shortID, matches.count)
        }
    }
}

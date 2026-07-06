import Foundation
import SwiftData
import Darwin

public struct WidgetTagSnapshot: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let colorIndex: Int

    public init(id: UUID, name: String, colorIndex: Int) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
    }
}

public struct WidgetTodoItemSnapshot: Codable, Hashable, Identifiable {
    public let id: UUID
    public let title: String
    public let notes: String?
    public let dueDate: Date?
    public let isCompleted: Bool
    public let hasDueTime: Bool
    public let tags: [WidgetTagSnapshot]

    public init(
        id: UUID,
        title: String,
        notes: String?,
        dueDate: Date?,
        isCompleted: Bool,
        hasDueTime: Bool,
        tags: [WidgetTagSnapshot]
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.hasDueTime = hasDueTime
        self.tags = tags
    }
}

public struct WidgetSnapshotCache: Codable, Hashable {
    public let generatedAt: Date
    public let todoItems: [WidgetTodoItemSnapshot]

    public init(generatedAt: Date, todoItems: [WidgetTodoItemSnapshot]) {
        self.generatedAt = generatedAt
        self.todoItems = todoItems
    }
}

public enum SharedWidgetSnapshotStore {
    private static let fileName = "WidgetSnapshot.json"
    private static let defaultsKey = "WidgetSnapshotData"

    public static var cacheURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedContainer.appGroupIdentifier)?
            .appendingPathComponent(fileName)
    }

    public static func load() throws -> WidgetSnapshotCache {
        try load(
            readableURLs: readableCacheURLs(),
            defaults: UserDefaults(suiteName: SharedContainer.appGroupIdentifier)
        )
    }

    static func load(readableURLs: [URL], defaults: UserDefaults?) throws -> WidgetSnapshotCache {
        var lastError: Error?
        for url in readableURLs {
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder.plainWidgetSnapshot.decode(WidgetSnapshotCache.self, from: data)
            } catch {
                lastError = error
            }
        }

        if let data = defaults?.data(forKey: defaultsKey) {
            return try JSONDecoder.plainWidgetSnapshot.decode(WidgetSnapshotCache.self, from: data)
        }

        throw lastError ?? CocoaError(.fileNoSuchFile)
    }

    public static func write(from container: ModelContainer, now: Date = Date()) throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { !$0.isCompleted })
        let items = try context.fetch(descriptor)
            .sorted(by: TodoItemSort.compareActive)
            .map(\.widgetSnapshot)
        try write(WidgetSnapshotCache(generatedAt: now, todoItems: items))
    }

    public static func write(_ cache: WidgetSnapshotCache) throws {
        let data = try JSONEncoder.plainWidgetSnapshot.encode(cache)
        UserDefaults(suiteName: SharedContainer.appGroupIdentifier)?.set(data, forKey: defaultsKey)

        var lastError: Error?
        var didWrite = false
        for url in writableCacheURLs() {
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: url, options: [.atomic])
                didWrite = true
            } catch {
                lastError = error
            }
        }

        if didWrite { return }
        throw lastError ?? CocoaError(.fileNoSuchFile)
    }

    private static func readableCacheURLs() -> [URL] {
        uniqueURLs([
            widgetExtensionApplicationSupportURL(),
            directWidgetContainerURL(),
            cacheURL,
            directGroupContainerURL(for: SharedContainer.appGroupIdentifier),
        ])
    }

    private static func writableCacheURLs() -> [URL] {
        uniqueURLs([
            cacheURL,
            directGroupContainerURL(for: SharedContainer.appGroupIdentifier),
            directWidgetContainerURL(),
        ])
    }

    private static func directGroupContainerURL(for identifier: String) -> URL? {
        guard let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir else { return nil }
        return URL(fileURLWithPath: String(cString: home))
            .appendingPathComponent("Library/Group Containers")
            .appendingPathComponent(identifier)
            .appendingPathComponent(fileName)
    }

    private static func widgetExtensionApplicationSupportURL() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    private static func directWidgetContainerURL() -> URL? {
        guard let pw = getpwuid(getuid()), let home = pw.pointee.pw_dir else { return nil }
        return URL(fileURLWithPath: String(cString: home))
            .appendingPathComponent("Library/Containers/app.plain.Plain.PlainWidget/Data/Library/Application Support")
            .appendingPathComponent(fileName)
    }

    private static func uniqueURLs(_ urls: [URL?]) -> [URL] {
        var seen = Set<String>()
        return urls.compactMap { url in
            guard let url else { return nil }
            let path = url.standardizedFileURL.path
            guard seen.insert(path).inserted else { return nil }
            return url
        }
    }
}

private extension TodoItem {
    var widgetSnapshot: WidgetTodoItemSnapshot {
        WidgetTodoItemSnapshot(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: isCompleted,
            hasDueTime: hasDueTime,
            tags: tags
                .sorted { $0.createdAt < $1.createdAt }
                .map { WidgetTagSnapshot(id: $0.id, name: $0.name, colorIndex: $0.colorIndex) }
        )
    }
}

private extension JSONEncoder {
    static var plainWidgetSnapshot: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var plainWidgetSnapshot: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

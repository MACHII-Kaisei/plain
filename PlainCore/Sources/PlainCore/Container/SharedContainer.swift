import Foundation
import SwiftData

public enum SharedContainer {
    public static let appGroupIdentifier = "group.com.KaiseiMachii.Plain"

    public static func makeSharedContainer() throws -> ModelContainer {
        let schema = Schema([TodoItem.self])
        let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
            .appendingPathComponent("Plain.sqlite")
        let config = ModelConfiguration(schema: schema, url: url)
        return try ModelContainer(for: schema, configurations: [config])
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([TodoItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}

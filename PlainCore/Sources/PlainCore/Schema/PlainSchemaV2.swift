import Foundation
import SwiftData

public enum PlainSchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    public static let models: [any PersistentModel.Type] = [TodoItem.self, Tag.self]
}

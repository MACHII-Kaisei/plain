import Foundation
import SwiftData

public enum PlainMigrationPlan: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [
        PlainSchemaV1.self,
        PlainSchemaV2.self,
    ]

    public static let stages: [MigrationStage] = [
        migrateV1toV2,
    ]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: PlainSchemaV1.self,
        toVersion: PlainSchemaV2.self
    )
}

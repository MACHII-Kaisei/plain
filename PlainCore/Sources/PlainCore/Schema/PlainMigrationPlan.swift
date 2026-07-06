import Foundation
import SwiftData

public enum PlainMigrationPlan: SchemaMigrationPlan {
    public static let schemas: [any VersionedSchema.Type] = [
        PlainSchemaV1.self,
        PlainSchemaV2.self,
        PlainSchemaV3.self,
    ]

    public static let stages: [MigrationStage] = [
        migrateV1toV2,
        migrateV2toV3,
    ]

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: PlainSchemaV1.self,
        toVersion: PlainSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: PlainSchemaV2.self,
        toVersion: PlainSchemaV3.self
    )
}

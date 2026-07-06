import Testing
import SwiftData
import PlainCore

@Test
func schemaVersionIsThreeZeroZero() {
    #expect(PlainSchemaV3.versionIdentifier == Schema.Version(3, 0, 0))
}

@Test
func schemaV3ContainsTodoItemAndTag() {
    #expect(PlainSchemaV3.models.count == 2)
    #expect(ObjectIdentifier(PlainSchemaV3.models[0]) == ObjectIdentifier(PlainSchemaV3.TodoItem.self))
    #expect(ObjectIdentifier(PlainSchemaV3.models[1]) == ObjectIdentifier(PlainSchemaV3.Tag.self))
}

@Test
func reminderExternalIDDefaultsToNil() {
    let item = TodoItem(title: "A")
    #expect(item.reminderExternalID == nil)
}

@Test
func migrationPlanIncludesV3() {
    #expect(PlainMigrationPlan.schemas.count == 3)
    #expect(PlainMigrationPlan.stages.count == 2)
}

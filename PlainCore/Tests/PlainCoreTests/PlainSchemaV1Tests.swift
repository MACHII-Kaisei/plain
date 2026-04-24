import Testing
import SwiftData
import PlainCore

@Test
func schemaVersionIsOne_zero_zero() {
    #expect(PlainSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
}

@Test
func schemaContainsTodoItem() {
    #expect(PlainSchemaV1.models.count == 1)
    #expect(ObjectIdentifier(PlainSchemaV1.models[0]) == ObjectIdentifier(PlainSchemaV1.TodoItem.self))
}

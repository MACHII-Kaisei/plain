import Foundation
import SwiftData

@Model
public final class Tag {
    public var id: UUID
    public var name: String
    public var colorIndex: Int
    public var createdAt: Date

    @Relationship(inverse: \TodoItem.tags)
    public var items: [TodoItem]

    public init(name: String, colorIndex: Int) {
        self.id = UUID()
        self.name = name
        self.colorIndex = colorIndex
        self.createdAt = Date()
        self.items = []
    }
}

import SwiftData
import PlainCore

enum ContainerProvider {
    static func shared() throws -> ModelContainer {
        try SharedContainer.makeSharedContainer()
    }
}

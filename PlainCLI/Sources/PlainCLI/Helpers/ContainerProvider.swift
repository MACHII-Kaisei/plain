import SwiftData
import PlainCore

enum ContainerProvider {
    static func shared() throws -> ModelContainer {
        let container = try SharedContainer.makeSharedContainer()
        // ウィジェットが書き残したペンディング操作を反映してから返す
        // （アプリ本体が起動していない間の完了操作を CLI でも見えるようにする）
        WidgetActionStore().applyPendingActions(context: ModelContext(container))
        return container
    }
}

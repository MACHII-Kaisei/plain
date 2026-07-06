import Foundation
import PlainCore

enum WidgetReloader {
    /// plain://reload を開いてウィジェットをリロードする
    static func reload() {
        if let container = try? ContainerProvider.shared() {
            try? SharedWidgetSnapshotStore.write(from: container)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["plain://reload"]
        try? process.run()
        process.waitUntilExit()
    }
}

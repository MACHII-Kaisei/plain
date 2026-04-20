import Foundation

enum WidgetReloader {
    /// plain://reload を開いてウィジェットをリロードする
    static func reload() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["plain://reload"]
        try? process.run()
        process.waitUntilExit()
    }
}

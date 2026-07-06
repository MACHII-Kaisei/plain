import Foundation

enum PlainURLAction: Equatable {
    case open
    case newTask
    case openTask(UUID)
    case reload
    case sync
}

enum URLRouter {
    static func parse(_ url: URL) -> PlainURLAction? {
        guard url.scheme == "plain" else { return nil }
        switch url.host {
        case "open":
            return .open
        case "new":
            return .newTask
        case "reload":
            return .reload
        case "sync":
            return .sync
        case "task":
            let idString = url.pathComponents.last ?? ""
            guard let uuid = UUID(uuidString: idString) else { return nil }
            return .openTask(uuid)
        default:
            return nil
        }
    }
}

import Foundation

enum PlainURLAction: Equatable {
    case newTask
    case openTask(UUID)
    case reload
}

enum URLRouter {
    static func parse(_ url: URL) -> PlainURLAction? {
        guard url.scheme == "plain" else { return nil }
        switch url.host {
        case "new":
            return .newTask
        case "reload":
            return .reload
        case "task":
            let idString = url.pathComponents.last ?? ""
            guard let uuid = UUID(uuidString: idString) else { return nil }
            return .openTask(uuid)
        default:
            return nil
        }
    }
}

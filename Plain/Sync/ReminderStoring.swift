import Foundation

@MainActor
protocol ReminderStoring {
    func requestAccess() async throws -> Bool
    func ensurePlainList() throws
    func fetchAll() async throws -> [ReminderData]

    @discardableResult
    func create(_ data: ReminderData) throws -> String
    func update(_ data: ReminderData, externalID: String) throws
    func delete(externalID: String) throws
}

enum ReminderStoreError: LocalizedError, Equatable {
    case accessDenied
    case listUnavailable
    case reminderNotFound(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            "リマインダーへのアクセスが許可されていません。"
        case .listUnavailable:
            "同期対象のリマインダーリストが見つかりません。"
        case .reminderNotFound(let externalID):
            "リマインダーが見つかりません: \(externalID)"
        }
    }
}

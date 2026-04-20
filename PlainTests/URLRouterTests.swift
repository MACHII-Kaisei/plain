import Foundation
import Testing
@testable import Plain

@Test func parseNewTaskURL() {
    let url = URL(string: "plain://new")!
    #expect(URLRouter.parse(url) == .newTask)
}

@Test func parseOpenTaskURL() throws {
    let uuid = UUID()
    let url = URL(string: "plain://task/\(uuid.uuidString)")!
    #expect(URLRouter.parse(url) == .openTask(uuid))
}

@Test func parseUnknownSchemeReturnsNil() {
    let url = URL(string: "https://example.com")!
    #expect(URLRouter.parse(url) == nil)
}

@Test func parseInvalidUUIDReturnsNil() {
    let url = URL(string: "plain://task/not-a-uuid")!
    #expect(URLRouter.parse(url) == nil)
}

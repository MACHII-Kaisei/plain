import Foundation
import Testing
import PlainCore

@Test
func priorityLowRawValueIsZero() {
    #expect(Priority.low.rawValue == 0)
}

@Test
func priorityMediumRawValueIsOne() {
    #expect(Priority.medium.rawValue == 1)
}

@Test
func priorityHighRawValueIsTwo() {
    #expect(Priority.high.rawValue == 2)
}

@Test
func priorityAllCasesCountIsThree() {
    #expect(Priority.allCases.count == 3)
}

@Test
func priorityCodableRoundTripHigh() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let encoded = try encoder.encode(Priority.high)
    let json = try #require(String(data: encoded, encoding: .utf8))
    #expect(json == "2")

    let decoded = try decoder.decode(Priority.self, from: encoded)
    #expect(decoded == .high)
}

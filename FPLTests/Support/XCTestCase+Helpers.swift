import XCTest
@testable import FPL

extension XCTestCase {
    func assertThrows<T>(
        _ expected: FPLError,
        _ expression: @autoclosure () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? FPLError, expected, file: file, line: line)
        }
    }
}

extension XCTestCase {
    /// A cache in a fresh temporary directory that is deleted when the test finishes.
    func makeTemporaryCache() -> FileBootstrapCache {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return FileBootstrapCache(fileURL: directory.appendingPathComponent("bootstrap-static.json"))
    }
}

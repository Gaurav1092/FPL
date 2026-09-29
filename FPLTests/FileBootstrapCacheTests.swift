import XCTest
@testable import FPL

final class FileBootstrapCacheTests: XCTestCase {
    private let savedAt = Date(timeIntervalSince1970: 1_700_000_000)

    func testLoadReturnsNilWhenNothingSaved() throws {
        let cache = makeTemporaryCache()

        XCTAssertNil(try cache.load())
    }

    func testSaveThenLoadRoundTrips() throws {
        let cache = makeTemporaryCache()

        try cache.save(Fixtures.bootstrapData, savedAt: savedAt)

        XCTAssertEqual(try cache.load(), .init(data: Fixtures.bootstrapData, savedAt: savedAt))
    }

    func testSaveReplacesPreviousEntry() throws {
        let cache = makeTemporaryCache()
        let later = savedAt.addingTimeInterval(60)

        try cache.save(Data("old".utf8), savedAt: savedAt)
        try cache.save(Data("new".utf8), savedAt: later)

        XCTAssertEqual(try cache.load(), .init(data: Data("new".utf8), savedAt: later))
    }
}

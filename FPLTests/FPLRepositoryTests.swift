import XCTest
@testable import FPL

final class FPLRepositoryTests: XCTestCase {
    private let fetchDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let cacheDate = Date(timeIntervalSince1970: 1_600_000_000)

    private func makeRepository(httpClient: MockHTTPClient, cache: FileBootstrapCache) -> FPLRepository {
        let fetchDate = fetchDate
        return FPLRepository(apiClient: FPLAPIClient(httpClient: httpClient), cache: cache, now: { fetchDate })
    }

    func testFetchReturnsLeagueAndCachesResponse() async throws {
        let cache = makeTemporaryCache()
        let repository = makeRepository(httpClient: .responding(statusCode: 200, data: Fixtures.bootstrapData), cache: cache)

        let league = try await repository.fetchLeague()

        XCTAssertEqual(league.teams.count, 3)
        XCTAssertEqual(league.updatedAt, fetchDate)
        XCTAssertEqual(try cache.load(), .init(data: Fixtures.bootstrapData, savedAt: fetchDate))
    }

    func testFailedFetchLeavesCacheUntouched() async throws {
        let cache = makeTemporaryCache()
        try cache.save(Fixtures.bootstrapData, savedAt: cacheDate)
        let repository = makeRepository(httpClient: .failing(with: URLError(.notConnectedToInternet)), cache: cache)

        await assertThrows(.offline, try await repository.fetchLeague())

        let cached = await repository.cachedLeague()
        XCTAssertEqual(cached?.updatedAt, cacheDate)
    }

    func testMalformedResponseDoesNotOverwriteCache() async throws {
        let cache = makeTemporaryCache()
        try cache.save(Fixtures.bootstrapData, savedAt: cacheDate)
        let repository = makeRepository(httpClient: .responding(statusCode: 200, data: Data("<html>".utf8)), cache: cache)

        await assertThrows(.decoding, try await repository.fetchLeague())

        XCTAssertEqual(try cache.load()?.data, Fixtures.bootstrapData)
    }

    func testCachedLeagueIsNilWhenNothingCached() async {
        let repository = makeRepository(httpClient: .responding(statusCode: 500), cache: makeTemporaryCache())

        let cached = await repository.cachedLeague()

        XCTAssertNil(cached)
    }

    func testCachedLeagueUsesCacheDate() async throws {
        let cache = makeTemporaryCache()
        try cache.save(Fixtures.bootstrapData, savedAt: cacheDate)
        let repository = makeRepository(httpClient: .responding(statusCode: 500), cache: cache)

        let cached = await repository.cachedLeague()

        XCTAssertEqual(cached?.teams.map(\.name), ["Arsenal", "Aston Villa", "Bournemouth"])
        XCTAssertEqual(cached?.updatedAt, cacheDate)
    }

    func testCorruptCacheIsTreatedAsEmpty() async throws {
        let cache = makeTemporaryCache()
        try cache.save(Data("not json".utf8), savedAt: cacheDate)
        let repository = makeRepository(httpClient: .responding(statusCode: 500), cache: cache)

        let cached = await repository.cachedLeague()

        XCTAssertNil(cached)
    }
}

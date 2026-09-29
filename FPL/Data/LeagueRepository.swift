import Foundation

protocol LeagueRepository: Sendable {
    /// The last successfully fetched data, or `nil` if nothing usable is cached.
    func cachedLeague() async -> LeagueSnapshot?

    /// Fetches fresh data from the API and caches it on success.
    func fetchLeague() async throws -> LeagueSnapshot
}

/// Combines the API client and the on-disk cache.
///
/// Both methods are `async` and nonisolated, so JSON decoding (the payload is over 1 MB)
/// runs off the main actor.
struct FPLRepository: LeagueRepository {
    private let apiClient: FPLAPIClient
    private let cache: FileBootstrapCache
    private let now: @Sendable () -> Date

    init(apiClient: FPLAPIClient, cache: FileBootstrapCache, now: @escaping @Sendable () -> Date = { Date() }) {
        self.apiClient = apiClient
        self.cache = cache
        self.now = now
    }

    func cachedLeague() async -> LeagueSnapshot? {
        // A missing or unreadable cache just means there's nothing to show yet.
        guard let entry = try? cache.load(),
              let response = try? BootstrapResponse.decode(from: entry.data)
        else { return nil }
        return LeagueSnapshot(response: response, updatedAt: entry.savedAt)
    }

    func fetchLeague() async throws -> LeagueSnapshot {
        let data = try await apiClient.fetchBootstrap()
        // Decode before caching so a malformed response never replaces a good cached copy.
        let response = try BootstrapResponse.decode(from: data)
        let fetchedAt = now()
        // A failed write shouldn't fail the refresh; the user still gets fresh data.
        try? cache.save(data, savedAt: fetchedAt)
        return LeagueSnapshot(response: response, updatedAt: fetchedAt)
    }
}

import Foundation

@MainActor
final class TeamsViewModel {
    enum State: Equatable {
        /// First load with nothing cached.
        case loading
        /// First load failed and there's nothing to show. The user can retry.
        case failed(FPLError)
        case loaded(Content)
    }

    struct Content: Equatable {
        var league: LeagueSnapshot
        /// A fetch is in flight while the current data stays on screen.
        var isRefreshing = false
        /// Set when the latest refresh failed. The data shown is still from `league.updatedAt`.
        var refreshError: FPLError?
    }

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    private let repository: any LeagueRepository
    private var isFetching = false

    init(repository: any LeagueRepository) {
        self.repository = repository
    }

    /// Shows cached data straight away if there is any, then fetches the latest.
    func load() async {
        if let cached = await repository.cachedLeague() {
            state = .loaded(Content(league: cached, isRefreshing: true))
        } else {
            state = .loading
        }
        await fetch()
    }

    /// Pull-to-refresh. Any data already on screen stays visible.
    func refresh() async {
        if case .loaded(var content) = state {
            content.isRefreshing = true
            state = .loaded(content)
        }
        await fetch()
    }

    /// Retry after the initial load failed.
    func retry() async {
        state = .loading
        await fetch()
    }

    private func fetch() async {
        // A refresh while a fetch is in flight would only repeat the same request.
        guard !isFetching else { return }
        isFetching = true
        defer { isFetching = false }

        do {
            let league = try await repository.fetchLeague()
            state = .loaded(Content(league: league))
        } catch {
            let fplError = error as? FPLError ?? .network
            if case .loaded(var content) = state {
                content.isRefreshing = false
                content.refreshError = fplError
                state = .loaded(content)
            } else {
                state = .failed(fplError)
            }
        }
    }
}

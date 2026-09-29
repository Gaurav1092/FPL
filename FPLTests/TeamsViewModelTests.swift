import XCTest
@testable import FPL

final class TeamsViewModelTests: XCTestCase {
    private let cached = LeagueSnapshot.stub(teamNames: ["Arsenal"], updatedAt: Date(timeIntervalSince1970: 1))
    private let fresh = LeagueSnapshot.stub(teamNames: ["Arsenal", "Chelsea"], updatedAt: Date(timeIntervalSince1970: 2))

    @MainActor
    private func makeViewModel(
        cached: LeagueSnapshot? = nil,
        fetchResults: [Result<LeagueSnapshot, FPLError>]
    ) -> (TeamsViewModel, recordedStates: () -> [TeamsViewModel.State]) {
        let viewModel = TeamsViewModel(repository: StubLeagueRepository(cached: cached, fetchResults: fetchResults))
        var states: [TeamsViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }
        return (viewModel, { states })
    }

    @MainActor
    func testInitialLoadWithoutCacheShowsLoadingThenData() async {
        let (viewModel, states) = makeViewModel(fetchResults: [.success(fresh)])

        await viewModel.load()

        XCTAssertEqual(states(), [.loading, .loaded(.init(league: fresh))])
    }

    @MainActor
    func testInitialFailureWithoutCacheShowsErrorAndRetrySucceeds() async {
        let (viewModel, states) = makeViewModel(fetchResults: [.failure(.offline), .success(fresh)])

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .failed(.offline))

        await viewModel.retry()
        XCTAssertEqual(states(), [.loading, .failed(.offline), .loading, .loaded(.init(league: fresh))])
    }

    @MainActor
    func testCachedDataIsShownWhileFetchingThenReplaced() async {
        let (viewModel, states) = makeViewModel(cached: cached, fetchResults: [.success(fresh)])

        await viewModel.load()

        XCTAssertEqual(states(), [
            .loaded(.init(league: cached, isRefreshing: true)),
            .loaded(.init(league: fresh)),
        ])
    }

    @MainActor
    func testOfflineLaunchKeepsCachedDataAndReportsError() async {
        let (viewModel, _) = makeViewModel(cached: cached, fetchResults: [.failure(.offline)])

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(.init(league: cached, refreshError: .offline)))
    }

    @MainActor
    func testRefreshFailureKeepsExistingData() async {
        let (viewModel, states) = makeViewModel(fetchResults: [.success(fresh), .failure(.server(statusCode: 500))])
        await viewModel.load()

        await viewModel.refresh()

        XCTAssertEqual(Array(states().suffix(2)), [
            .loaded(.init(league: fresh, isRefreshing: true)),
            .loaded(.init(league: fresh, refreshError: .server(statusCode: 500))),
        ])
    }

    @MainActor
    func testSuccessfulRefreshClearsPreviousRefreshError() async {
        let (viewModel, _) = makeViewModel(cached: cached, fetchResults: [.failure(.offline), .success(fresh)])
        await viewModel.load()

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded(.init(league: fresh)))
    }

    @MainActor
    func testEmptyLeagueLoadsWithNoTeams() async {
        let empty = LeagueSnapshot.stub(teamNames: [])
        let (viewModel, _) = makeViewModel(fetchResults: [.success(empty)])

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded(.init(league: empty)))
    }
}

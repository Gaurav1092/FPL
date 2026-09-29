# FPL Team Viewer

A small native iOS app for browsing Premier League teams and their squads, using the Fantasy Premier League `bootstrap-static` API.

## Build and run

- Xcode 27, iOS 15.0+ deployment target, Swift 6 language mode. No third-party dependencies.
- Open `FPL.xcodeproj`, select the **FPL** scheme and an iOS Simulator, then Run (⌘R).
- Tests: ⌘U. They use fixtures and stubs and never call the live API.
- To run on a device, set your team under *Signing & Capabilities* (the bundle ID is `com.example.FPL`).

## What it does

- **Teams:** every team with its name, short name and player count. Tap a team to see its squad.
- **Squad:** players grouped Goalkeepers → Defenders → Midfielders → Forwards, ordered by total points (ties broken by name). Each player shows name, position, price and points.
- **Search:** filters the squad as you type. Matching is case- and accent-insensitive ("martinez" finds "Martínez") and checks both the short name and the full name.
- **States:** initial loading, failure with Retry, pull-to-refresh, refresh failure (existing data stays visible, with a "Showing data from …" banner), and empty results.
- **Offline:** the last good response is cached on disk. At launch cached data appears straight away, then the app refreshes from the network. With no connection the cached data stays on screen and the banner explains why.

## Architecture

MVVM with a thin data layer. I kept it deliberately small for an app of this size: no coordinators, no DI container, no generic "use case" layer.

```
FPL/
  App/        AppDelegate, SceneDelegate: programmatic window and dependency wiring
  Networking/ HTTPClient (protocol that URLSession conforms to), FPLAPIClient, FPLError
  Models/     Codable DTOs (only the fields used), Team / Player / Position, LeagueSnapshot mapping
  Data/       FileBootstrapCache, LeagueRepository (API + cache)
  Features/   Teams/ and Squad/: view model + view controller each; SquadBuilder (grouping/sort/search)
  Shared/     StateView (loading/error/empty), BannerView
```

Key decisions:

- **One request.** `bootstrap-static` contains every team and player, so the app fetches it once and derives both screens from it in memory. The Squad screen needs no network call, and search is a synchronous filter with no debounce and no cancellation.
- **State as an enum, not flags.** `TeamsViewModel.State` is `loading | failed(error) | loaded(content)`, and `content` carries `isRefreshing` and `refreshError`. "Refresh failed but keep the data" is simply `loaded` with an error attached, and impossible combinations (such as an error screen alongside data) can't be represented.
- **Swift Concurrency end to end.** View models are `@MainActor`. The repository and API client are `Sendable` value types whose async work, including decoding a payload of over 1 MB, runs off the main actor. Overlapping refreshes are coalesced with an `isFetching` guard.
- **Closures for view-model → view updates** (`onStateChange`), not Combine. Combine is a first-party framework and would be allowed, but there's a single subscriber per view model and one-directional state, so a closure is the simplest thing that works. It also avoids mixing two concurrency models when the brief asks for async/await. Observation's automatic UIKit tracking isn't available on iOS 15.
- **Cache the raw response bytes.** The cache stores exactly what the server sent, and the cache and the network share one decoding path. A response is only cached after it decodes successfully, so a bad response can't overwrite a good cached copy. The file is written atomically to Application Support (the system can purge Caches, which would break offline launch) and is excluded from backup.
- **Injectable seams only where tests need them:** `HTTPClient` for the API client, `LeagueRepository` for the view models, and a file URL for the cache (tests use a temporary directory).
- **UIKit:** compositional list layout, diffable data sources keyed by ID, `UISearchController`, `UIRefreshControl`, and state views set as the collection view's `backgroundView` so pull-to-refresh still works over the empty and error states.

## Assumptions

- Positions come from a local `Position` enum (element types 1–4) rather than the API's `element_types`. Other types are excluded. FPL added element type 5 ("Manager") in 2024/25, and managers aren't squad players.
- Price is `now_cost / 10`, shown as £X.Xm. The player count is the number of FPL players listed for the team.
- Pull-to-refresh is on the Teams screen only. A Squad screen shows the data it was opened with.

## Tests

Tests cover decoding and mapping (`DecodingTests`), HTTP and transport error mapping (`FPLAPIClientTests`), the cache (`FileBootstrapCacheTests`), repository caching rules (`FPLRepositoryTests`), grouping, ordering and search (`SquadBuilderTests`, `SquadViewModelTests`), and the full Teams state machine: first load, failure then retry, cached launch, offline launch, refresh failure and empty results (`TeamsViewModelTests`).

## With more time

1. **Squad screen refresh:** share a store between screens so an open squad updates after a refresh, and add pull-to-refresh there too.
2. **Team badges and player photos** from the Premier League CDN, using a small `URLCache`-backed image loader with cell-reuse cancellation.
3. **Player detail and sorting options** (price, form, ownership), and showing injury status (`status`, `news`).
4. **UI tests** for the main flows, with a stubbed `HTTPClient` injected via a launch argument, plus snapshot tests of the state views.
5. **Better error details:** log the underlying decoding error, and add reachability-aware messaging using `NWPathMonitor`.
6. **Accessibility pass:** VoiceOver labels combining name, position, price and points into one sentence, and a check of the largest Dynamic Type sizes.

I prioritised correctness of the data layer and the asynchronous state handling (requirements 4 and 5), and put tests around both. They're the parts most likely to break in subtle ways; visual polish is easy to add later.

## Known limitations

- The whole `bootstrap-static` payload is re-downloaded on each refresh. It's the only endpoint that has everything, and the app doesn't use `ETag` / `If-None-Match`.
- The time shown in the stale-data banner is when the data was saved on the device, not when FPL last updated it.
- Accent-insensitive search folds accented letters such as "é" and "ö", but not separate letters such as "Ø" (so "odegaard" won't match "Ødegaard").
- No launch screen artwork or app icon.

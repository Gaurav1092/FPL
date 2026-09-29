import UIKit

final class TeamsViewController: UIViewController {
    private enum Section { case main }

    private let viewModel: TeamsViewModel
    private let bannerView = BannerView()
    private let stateView = StateView()
    private let refreshControl = UIRefreshControl()
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .insetGrouped))
    )
    private lazy var dataSource = makeDataSource()
    private lazy var activityItem: UIBarButtonItem = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        return UIBarButtonItem(customView: indicator)
    }()

    /// The diffable data source holds team IDs; this holds the teams they refer to.
    private var teamsByID: [Team.ID: Team] = [:]

    init(viewModel: TeamsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Teams"
        view.backgroundColor = .systemGroupedBackground
        configureHierarchy()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)

        Task { [viewModel] in
            await viewModel.load()
        }
    }

    private func configureHierarchy() {
        collectionView.delegate = self
        collectionView.backgroundView = stateView
        collectionView.refreshControl = refreshControl
        refreshControl.addAction(UIAction { [weak self] _ in self?.refresh() }, for: .valueChanged)
        stateView.onRetry = { [weak self] in self?.retry() }

        let stack = UIStackView(arrangedSubviews: [bannerView, collectionView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // The collection view isn't the root view's first subview, so tell the navigation bar
        // which scroll view drives its scroll-edge appearance.
        setContentScrollView(collectionView)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Team.ID> {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Team> { cell, _, team in
            var content = cell.defaultContentConfiguration()
            content.text = team.name
            content.secondaryText = team.shortName
            content.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = content
            cell.accessories = [.label(text: "\(team.playerCount) players"), .disclosureIndicator()]
        }

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, teamID in
            guard let team = self?.teamsByID[teamID] else { return nil }
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: team)
        }
    }

    // MARK: - Rendering

    private func render(_ state: TeamsViewModel.State) {
        switch state {
        case .loading:
            apply(teams: [])
            stateView.show(.loading)
            bannerView.message = nil
            setRefreshing(false)

        case .failed(let error):
            apply(teams: [])
            stateView.show(.message(title: "Couldn't load teams", detail: error.message, showsRetry: true))
            bannerView.message = nil
            setRefreshing(false)

        case .loaded(let content):
            apply(teams: content.league.teams)
            stateView.show(content.league.teams.isEmpty
                ? .message(title: "No teams available", detail: "Pull down to refresh.")
                : .hidden)
            bannerView.message = content.refreshError.map {
                "\($0.message) Showing data from \(Self.format(content.league.updatedAt))."
            }
            setRefreshing(content.isRefreshing)
        }
    }

    private func apply(teams: [Team]) {
        let existingIDs = Set(dataSource.snapshot().itemIdentifiers)
        teamsByID = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, Team.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(teams.map(\.id))
        // Same IDs don't mean same content (player counts can change on refresh), so
        // reconfigure the cells that stay on screen.
        snapshot.reconfigureItems(teams.map(\.id).filter(existingIDs.contains))
        dataSource.apply(snapshot, animatingDifferences: !existingIDs.isEmpty)
    }

    /// Shows a spinner in the navigation bar for fetches the user didn't start by pulling
    /// (e.g. the refresh at launch after showing cached data).
    private func setRefreshing(_ isRefreshing: Bool) {
        if !isRefreshing {
            refreshControl.endRefreshing()
        }
        navigationItem.rightBarButtonItem = isRefreshing && !refreshControl.isRefreshing ? activityItem : nil
    }

    private static func format(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    // MARK: - Actions

    private func refresh() {
        Task { [viewModel] in
            await viewModel.refresh()
        }
    }

    private func retry() {
        Task { [viewModel] in
            await viewModel.retry()
        }
    }
}

extension TeamsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

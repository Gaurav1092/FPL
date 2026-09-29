import UIKit

final class SquadViewController: UIViewController {
    private let viewModel: SquadViewModel
    private let playersByID: [Player.ID: Player]
    private let stateView = StateView()
    private lazy var collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private lazy var dataSource = makeDataSource()

    init(team: Team) {
        viewModel = SquadViewModel(team: team)
        playersByID = Dictionary(uniqueKeysWithValues: team.players.map { ($0.id, $0) })
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.team.name
        view.backgroundColor = .systemGroupedBackground
        configureSearch()
        configureCollectionView()

        viewModel.onChange = { [weak self] in
            self?.applySnapshot(animated: true)
        }
        applySnapshot(animated: false)
    }

    private func configureSearch() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search players"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureCollectionView() {
        collectionView.allowsSelection = false
        collectionView.keyboardDismissMode = .onDrag
        collectionView.backgroundView = stateView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Position, Player.ID> {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Player> { cell, _, player in
            var content = cell.defaultContentConfiguration()
            content.text = player.webName
            content.secondaryText = "\(player.position.shortName) · \(player.formattedPrice)"
            content.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = content
            cell.accessories = [.label(text: "\(player.totalPoints) pts")]
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            var content = header.defaultContentConfiguration()
            content.text = self?.dataSource.sectionIdentifier(for: indexPath.section)?.pluralName
            header.contentConfiguration = content
        }

        let dataSource = UICollectionViewDiffableDataSource<Position, Player.ID>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, playerID in
            guard let player = self?.playersByID[playerID] else { return nil }
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: player)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Position, Player.ID>()
        for section in viewModel.sections {
            snapshot.appendSections([section.position])
            snapshot.appendItems(section.players.map(\.id), toSection: section.position)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
        stateView.show(viewModel.emptyMessage.map { StateView.Content.message(title: $0) } ?? .hidden)
    }
}

extension SquadViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(searchController.searchBar.text ?? "")
    }
}

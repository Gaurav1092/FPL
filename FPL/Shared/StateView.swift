import UIKit

/// Loading, error and empty states. Used as a collection view's `backgroundView`, so it sits
/// behind any cells and pull-to-refresh keeps working over it.
final class StateView: UIView {
    enum Content: Equatable {
        case hidden
        case loading
        case message(title: String, detail: String? = nil, showsRetry: Bool = false)
    }

    var onRetry: (() -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private lazy var retryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Retry"
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .primaryActionTriggered)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailLabel.textColor = .secondaryLabel
        for label in [titleLabel, detailLabel] {
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textAlignment = .center
        }

        let stack = UIStackView(arrangedSubviews: [activityIndicator, titleLabel, detailLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
        ])

        show(.hidden)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ content: Content) {
        switch content {
        case .hidden:
            activityIndicator.stopAnimating()
            setLabels(title: nil, detail: nil)
            retryButton.isHidden = true
        case .loading:
            activityIndicator.startAnimating()
            setLabels(title: nil, detail: nil)
            retryButton.isHidden = true
        case .message(let title, let detail, let showsRetry):
            activityIndicator.stopAnimating()
            setLabels(title: title, detail: detail)
            retryButton.isHidden = !showsRetry
        }
    }

    private func setLabels(title: String?, detail: String?) {
        titleLabel.text = title
        titleLabel.isHidden = title == nil
        detailLabel.text = detail
        detailLabel.isHidden = detail == nil
    }
}

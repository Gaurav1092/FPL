import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let repository = FPLRepository(
            apiClient: FPLAPIClient(httpClient: URLSession.shared),
            cache: .makeDefault()
        )
        let teamsViewController = TeamsViewController(viewModel: TeamsViewModel(repository: repository))

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: teamsViewController)
        window.makeKeyAndVisible()
        self.window = window
    }
}

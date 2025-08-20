import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🚀 SceneDelegate: scene willConnectTo çağrıldı")
        
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ WindowScene oluşturulamadı")
            return
        }
        
        print("✅ WindowScene oluşturuldu")
        
        // Window oluştur
        window = UIWindow(windowScene: windowScene)
        
        print("✅ Window oluşturuldu")
        
        // Eski ViewController'a geri dön (SimpleWearOS eklenene kadar)
        let viewController = ViewController()
        
        print("✅ ViewController oluşturuldu")
        
        // Navigation Controller'a embed et
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.backgroundColor = UIColor.white
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColor.systemBlue
        
        print("✅ NavigationController oluşturuldu")
        
        // Window'u ayarla
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("✅ Window görünür yapıldı")
        print("📱 Root VC: \(String(describing: window?.rootViewController))")
        
        print("✅ SceneDelegate setup complete")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("🔌 Scene disconnected")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("✅ Scene became active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("⏸ Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("➡️ Scene will enter foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("⬅️ Scene did enter background")
    }
}

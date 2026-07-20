import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Antifraud.shared.initialize(
            projectId: "your-project-uuid-here",
            publicKey: """
            -----BEGIN PUBLIC KEY-----
            MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv62K/N9g5P8i...
            -----END PUBLIC KEY-----
            """
        )

        return true
    }
}

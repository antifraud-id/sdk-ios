import UIKit
import AntifraudSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func handleCheckout(_ sender: Any) {
        Task {
            var sessionId: String? = nil

            do {
                sessionId = try await Antifraud.shared.createSession()
            } catch {
                print("Antifraud session generation failed: \(error)")
            }

            // Forward sessionId (may be nil) to your backend
            // await myBackendApi.processOrder(amount: 100.0, antifraudSessionId: sessionId)
        }
    }
}

# Antifraud iOS SDK

Native iOS SDK for [Antifraud.id](https://antifraud.id) device fingerprinting and fraud detection. The SDK collects hardware specifications, OS attributes, carrier metadata, location signals, and deep security diagnostics (jailbreak, emulator, debugger, mock location, and tampering hooks), encrypts the payload using hybrid RSA-OAEP + AES-GCM cryptography, and exchanges it for a stable `session_id` via the Antifraud API.

## Requirements

- iOS 13.0+
- Swift 5.0+
- CocoaPods 1.10+

## Installation

Add the following to your `Podfile`:

```ruby
pod 'AntifraudSDK', '~> 1.0.0'
```

Then run:

```bash
pod install
```

## Usage

### 1. Initialize the SDK

Initialize once at app launch in your `AppDelegate`:

```swift
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
            """,
            apiUrl: "https://api.antifraud.id",  // Optional, defaults to https://api.antifraud.id
            timeoutMs: 5000                       // Optional, defaults to 5000ms
        )

        return true
    }
}
```

### 2. Generate a Session ID

Call `createSession()` before sensitive events (registrations, logins, checkouts). Always implement a **fail-open strategy**:

```swift
func handleCheckout(amount: Double) async {
    var sessionId: String? = nil

    do {
        sessionId = try await Antifraud.shared.createSession()
    } catch {
        // Fail-open: log error but allow transaction to proceed
        print("Antifraud session generation failed: \(error)")
    }

    // Forward sessionId (may be nil) to your backend
    await myBackendApi.processOrder(amount: amount, antifraudSessionId: sessionId)
}
```

## Info.plist Configuration

Add the following to your app's `Info.plist` if you want location signal profiling:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We collect location signals to analyze and prevent fraudulent transaction rings.</string>
```

## Signals Collected

| Category | Signals |
|----------|---------|
| **Device Identity** | Stable UUID stored in Keychain (survives app reinstalls) |
| **Network** | Carrier name, VPN detection, connection type (WiFi/4G/5G/etc) |
| **Hardware** | CPU architecture, total memory, free storage, screen resolution, battery level/charging, uptime |
| **Security** | Jailbreak detection, emulator detection, debugger attachment, Frida/Xposed/Substrate hooks, app binary signature hash |
| **Location** | Latitude, longitude, horizontal accuracy (graceful `0.0` when permissions absent) |

## License

MIT License. See [LICENSE](LICENSE) for details.

import Foundation
import CoreLocation

public class Antifraud: NSObject {
    public static let shared = Antifraud()
    public static let sdkVersion = "ios-1.0.1"

    private var projectId: String?
    private var publicKey: String?
    private var apiUrl: String = "https://api.antifraud.id"
    private var timeoutMs: Int = 5000

    private override init() {
        super.init()
    }

    public func initialize(
        projectId: String,
        publicKey: String,
        apiUrl: String? = nil,
        timeoutMs: Int = 5000
    ) {
        self.projectId = projectId
        self.publicKey = publicKey
        if let api = apiUrl, !api.isEmpty {
            self.apiUrl = api
        }
        if timeoutMs > 0 {
            self.timeoutMs = timeoutMs
        }
    }

    public func createSession() async throws -> String {
        guard let currentProjectId = projectId, let currentPublicKey = publicKey else {
            throw NSError(domain: "AntifraudSDK", code: 1, userInfo: [NSLocalizedDescriptionKey: "Antifraud SDK is not initialized."])
        }

        let deviceId = DeviceIdManager.getDeviceId()
        let platform = DeviceCollector.getPlatform()
        let osVersion = DeviceCollector.getOsVersion()
        let model = DeviceCollector.getModel()
        let manufacturer = DeviceCollector.getManufacturer()

        let networkInfo = NetworkCollector.getNetworkInfo()
        let screenInfo = DeviceCollector.getScreenInfo()
        let batteryInfo = DeviceCollector.getBatteryInfo()
        let gpsInfo = LocationCollector.shared.getLocationInfo()
        let appInfo = AppInfoCollector.getAppInfo()
        let uptime = DeviceCollector.getUptime()

        var isMock = false
        if #available(iOS 15.0, macOS 12.0, *) {
            if let loc = CLLocationManager().location {
                isMock = loc.sourceInformation?.isSimulatedBySoftware ?? false
            }
        }

        let securityInfo = SecurityCollector.getSecurityInfo(mockLocationDetected: isMock)

        // Stable device hash — FNV-1a over hardware signals identical across
        // app reinstalls on the same physical device. The engine uses it to
        // unify identity across SDKs/browsers.
        let stableDeviceHash = fnv1a([
            manufacturer,
            model,
            osVersion,
            String(screenInfo.width),
            String(screenInfo.height),
            String(Int(screenInfo.dpi)),
            DeviceCollector.getCpuArchitecture(),
            String(DeviceCollector.getTotalMemoryMB())
        ].joined(separator: "|"))

        let deviceInfo = DeviceInfo(
            deviceId: deviceId,
            platform: platform,
            osVersion: osVersion,
            manufacturer: manufacturer,
            model: model,
            appVersion: appInfo.appVersion,
            buildNumber: appInfo.buildNumber,
            stableDeviceHash: stableDeviceHash,
            uptime: uptime,
            security: securityInfo,
            battery: batteryInfo,
            network: networkInfo,
            gps: gpsInfo,
            screen: screenInfo
        )

        let payload = MobileSDKPayload(deviceInfo: deviceInfo)

        let encoder = JSONEncoder()
        let plaintextData = try encoder.encode(payload)
        guard let plaintextJSON = String(data: plaintextData, encoding: .utf8) else {
            throw NSError(domain: "AntifraudSDK", code: 2, userInfo: [NSLocalizedDescriptionKey: "Serialization error."])
        }

        let encryptedData = try HybridEncryptor.encryptPayload(publicKeyPEM: currentPublicKey, plaintextJSON: plaintextJSON)

        let sessionId = try await AntifraudSessionClient.createSession(
            apiUrl: apiUrl,
            projectId: currentProjectId,
            timeoutMs: timeoutMs,
            encryptedPayload: encryptedData
        )

        return sessionId
    }

    private func fnv1a(_ input: String) -> String {
        var hash: UInt32 = 0x811c9dc5
        for byte in input.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return String(format: "%08x", hash)
    }
}

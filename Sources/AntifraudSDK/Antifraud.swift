import Foundation
import CoreLocation

public class Antifraud: NSObject {
    public static let shared = Antifraud()

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
        let hardwareInfo = DeviceCollector.getHardwareInfo()
        let locationInfo = LocationCollector.shared.getLocationInfo()
        let appInfo = AppInfoCollector.getAppInfo()

        var isMock = false
        if #available(iOS 15.0, *) {
            if let loc = CLLocationManager().location {
                isMock = loc.sourceInformation?.isSimulatedBySoftware ?? false
            }
        }

        let securityInfo = SecurityCollector.getSecurityInfo(mockLocationDetected: isMock)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let collectedAt = formatter.string(from: Date())

        let deviceInfo = DeviceInfo(
            deviceId: deviceId,
            platform: platform,
            osVersion: osVersion,
            model: model,
            manufacturer: manufacturer,
            network: networkInfo,
            hardware: hardwareInfo,
            security: securityInfo,
            location: locationInfo,
            app: appInfo,
            collectedAt: collectedAt
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
}

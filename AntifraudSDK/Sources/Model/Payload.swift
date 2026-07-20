import Foundation

struct NetworkInfo: Codable {
    let ip: String
    let connectionType: String
    let carrier: String
    let isVpnActive: Bool
}

struct HardwareInfo: Codable {
    let cpuArchitecture: String
    let totalMemory: Int
    let freeStorage: Int
    let screenResolution: String
    let batteryLevel: Int
    let isCharging: Bool
    let uptime: Int64
}

struct SecurityInfo: Codable {
    let isRootedOrJailbroken: Bool
    let isEmulator: Bool
    let isMockLocation: Bool
    let isDebuggerAttached: Bool
    let isAppTampered: Bool
    let appSignatureHash: String
}

struct LocationInfo: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
}

struct AppInfo: Codable {
    let appVersion: String
    let buildNumber: String
}

struct DeviceInfo: Codable {
    let deviceId: String
    let platform: String
    let osVersion: String
    let model: String
    let manufacturer: String
    let network: NetworkInfo
    let hardware: HardwareInfo
    let security: SecurityInfo
    let location: LocationInfo
    let app: AppInfo
    let collectedAt: String
}

struct MobileSDKPayload: Codable {
    let deviceInfo: DeviceInfo
}

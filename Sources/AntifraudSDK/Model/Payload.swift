import Foundation

struct NetworkInfo: Codable {
    let ip: String
    let isp: String
    let carrier: String
    let connectionType: String
}

struct SecurityInfo: Codable {
    let isRooted: Bool
    let isEmulator: Bool
    let isDebuggerAttached: Bool
    let isAppTampered: Bool
    let isMockLocation: Bool
}

struct BatteryInfo: Codable {
    let level: Int
    let isCharging: Bool
}

struct GpsInfo: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
}

struct ScreenInfo: Codable {
    let width: Int
    let height: Int
    let dpi: Double
}

struct AppInfo: Codable {
    let appVersion: String
    let buildNumber: String
}

struct DeviceInfo: Codable {
    let deviceId: String
    let platform: String
    let osVersion: String
    let manufacturer: String
    let model: String
    let appVersion: String
    let buildNumber: String
    let stableDeviceHash: String
    let uptime: Int64
    let security: SecurityInfo
    let battery: BatteryInfo
    let network: NetworkInfo
    let gps: GpsInfo
    let screen: ScreenInfo
}

struct MobileSDKPayload: Codable {
    let deviceInfo: DeviceInfo
}

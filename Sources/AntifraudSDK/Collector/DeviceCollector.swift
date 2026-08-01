#if canImport(UIKit)
import UIKit
#endif
import Foundation

enum DeviceCollector {

    static func getPlatform() -> String {
        return "iOS"
    }

    static func getOsVersion() -> String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }

    static func getModel() -> String {
        return getDeviceMachineName()
    }

    static func getManufacturer() -> String {
        return "Apple"
    }

    static func getCpuArchitecture() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        let machineName = String(cString: machine)
        if machineName.hasPrefix("iPhone") || machineName.hasPrefix("iPad") {
            return "arm64"
        }
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return machineName
        #endif
    }

    static func getTotalMemoryMB() -> Int {
        let totalMemBytes = ProcessInfo.processInfo.physicalMemory
        return Int(totalMemBytes / (1024 * 1024))
    }

    static func getScreenInfo() -> ScreenInfo {
        #if canImport(UIKit)
        let screen = UIScreen.main
        let scale = screen.scale
        let width = Int(screen.bounds.width * scale)
        let height = Int(screen.bounds.height * scale)
        return ScreenInfo(width: width, height: height, dpi: Double(scale) * 160.0)
        #else
        return ScreenInfo(width: 0, height: 0, dpi: 0.0)
        #endif
    }

    static func getBatteryInfo() -> BatteryInfo {
        var batteryLevel = -1
        var isCharging = false

        #if canImport(UIKit)
        let wasEnabled = UIDevice.current.isBatteryMonitoringEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            batteryLevel = Int(level * 100.0)
        }
        let state = UIDevice.current.batteryState
        isCharging = (state == .charging || state == .full)
        UIDevice.current.isBatteryMonitoringEnabled = wasEnabled
        #endif

        return BatteryInfo(level: batteryLevel, isCharging: isCharging)
    }

    static func getUptime() -> Int64 {
        return Int64(ProcessInfo.processInfo.systemUptime)
    }

    private static func getDeviceMachineName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

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

    static func getHardwareInfo() -> HardwareInfo {
        let cpuArch = getCpuArchitecture()

        let totalMemBytes = ProcessInfo.processInfo.physicalMemory
        let totalMemMB = Int(totalMemBytes / (1024 * 1024))

        var freeStorageMB = 0
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attrs[.systemFreeSize] as? Int64 {
            freeStorageMB = Int(freeSize / (1024 * 1024))
        }

        var screenRes = "unknown"
        #if canImport(UIKit)
        let screen = UIScreen.main
        let scale = screen.scale
        let width = Int(screen.bounds.width * scale)
        let height = Int(screen.bounds.height * scale)
        screenRes = "\(width)x\(height)"
        #endif

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

        let uptimeSec = Int64(ProcessInfo.processInfo.systemUptime)

        return HardwareInfo(
            cpuArchitecture: cpuArch,
            totalMemory: totalMemMB,
            freeStorage: freeStorageMB,
            screenResolution: screenRes,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            uptime: uptimeSec
        )
    }

    private static func getCpuArchitecture() -> String {
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

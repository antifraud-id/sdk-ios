#if canImport(UIKit)
import UIKit
#endif
import Foundation
import MachO
import CoreLocation

enum SecurityCollector {

    static func getSecurityInfo(mockLocationDetected: Bool) -> SecurityInfo {
        let jailbroken = isJailbroken()
        let emulator = isEmulator()
        let debugger = isDebuggerAttached()
        let tampered = isAppTampered()

        return SecurityInfo(
            isRooted: jailbroken,
            isEmulator: emulator,
            isDebuggerAttached: debugger,
            isAppTampered: tampered,
            isMockLocation: mockLocationDetected
        )
    }

    private static func isJailbroken() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia/",
            "/private/var/tmp/cydia.log"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        let testStr = "Jailbreak Test"
        do {
            try testStr.write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
            return true
        } catch {
            // normal sandbox restriction
        }

        #if canImport(UIKit)
        var canOpen = false
        if Thread.isMainThread {
            if let url = URL(string: "cydia://"), UIApplication.shared.canOpenURL(url) {
                canOpen = true
            }
        } else {
            DispatchQueue.main.sync {
                if let url = URL(string: "cydia://"), UIApplication.shared.canOpenURL(url) {
                    canOpen = true
                }
            }
        }
        if canOpen { return true }
        #endif

        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            if let rawName = _dyld_get_image_name(i) {
                let name = String(cString: rawName)
                let lowerName = name.lowercased()
                if lowerName.contains("libsubstitute") ||
                    lowerName.contains("mobilesubstrate") ||
                    lowerName.contains("substrate") ||
                    lowerName.contains("sslkillswitch") ||
                    lowerName.contains("frida") {
                    return true
                }
            }
        }

        return false
    }

    private static func isEmulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
        #endif
    }

    private static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.size
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)

        if junk == 0 {
            if (info.kp_proc.p_flag & P_TRACED) != 0 {
                return true
            }
        }

        #if !targetEnvironment(simulator)
        if getppid() != 1 {
            return true
        }
        #endif

        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            if let rawName = _dyld_get_image_name(i) {
                let name = String(cString: rawName)
                if name.lowercased().contains("frida") {
                    return true
                }
            }
        }

        return false
    }

    private static func isAppTampered() -> Bool {
        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            if let rawName = _dyld_get_image_name(i) {
                let name = String(cString: rawName)
                if name.lowercased().contains("frida") || name.lowercased().contains("sslkillswitch") {
                    return true
                }
            }
        }
        return false
    }
}

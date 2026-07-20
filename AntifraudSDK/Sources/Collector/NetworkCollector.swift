import Foundation
import CoreTelephony
import Network

enum NetworkCollector {

    static func getNetworkInfo() -> NetworkInfo {
        let isVpn = isVpnConnected()
        let carrierName = getCarrierName()
        let connType = getConnectionType()

        return NetworkInfo(
            ip: "",
            connectionType: connType,
            carrier: carrierName,
            isVpnActive: isVpn
        )
    }

    private static func isVpnConnected() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings() else { return false }
        let nsDict = cfDict.takeRetainedValue() as NSDictionary
        guard let keys = nsDict["__SCOPED__"] as? NSDictionary else { return false }
        for key in keys.allKeys {
            if let name = key as? String {
                let lowerName = name.lowercased()
                if lowerName.contains("tap") || lowerName.contains("tun") || lowerName.contains("ppp") || lowerName.contains("ipsec") || lowerName.contains("vpn") {
                    return true
                }
            }
        }
        return false
    }

    private static func getCarrierName() -> String {
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            if let providers = info.serviceSubscriberCellularProviders {
                for (_, provider) in providers {
                    if let name = provider.carrierName, !name.isEmpty {
                        return name
                    }
                }
            }
        } else {
            if let provider = info.subscriberCellularProvider, let name = provider.carrierName, !name.isEmpty {
                return name
            }
        }
        return ""
    }

    private static func getConnectionType() -> String {
        let monitor = NWPathMonitor()
        var pathType = "UNKNOWN"
        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                pathType = "WIFI"
            } else if path.usesInterfaceType(.cellular) {
                pathType = getCellularGeneration()
            } else if path.usesInterfaceType(.wiredEthernet) {
                pathType = "ETHERNET"
            } else {
                pathType = "UNKNOWN"
            }
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "NWPathMonitorQueue")
        monitor.start(queue: queue)

        _ = semaphore.wait(timeout: .now() + 0.1)
        monitor.cancel()

        return pathType
    }

    private static func getCellularGeneration() -> String {
        let info = CTTelephonyNetworkInfo()
        var radioTech: String? = nil
        if #available(iOS 12.0, *) {
            radioTech = info.serviceCurrentRadioAccessTechnology?.values.first
        } else {
            radioTech = info.currentRadioAccessTechnology
        }

        guard let tech = radioTech else { return "CELLULAR" }

        switch tech {
        case CTRadioAccessTechnologyLTE:
            return "4G"
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyeHRPD:
            return "3G"
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return "2G"
        default:
            if #available(iOS 14.1, *) {
                if tech == CTRadioAccessTechnologyNR || tech == CTRadioAccessTechnologyNRNSA {
                    return "5G"
                }
            }
            return "4G"
        }
    }
}

import Foundation
import CoreTelephony
import Network

enum NetworkCollector {

    static func getNetworkInfo() -> NetworkInfo {
        let carrierName = getCarrierName()
        let connType = getConnectionType()

        return NetworkInfo(
            ip: "", // Left empty, server-observed
            isp: "",
            carrier: carrierName,
            connectionType: connType
        )
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

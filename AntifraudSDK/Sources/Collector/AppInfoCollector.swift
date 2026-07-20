import Foundation

enum AppInfoCollector {

    static func getAppInfo() -> AppInfo {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return AppInfo(appVersion: version, buildNumber: build)
    }
}

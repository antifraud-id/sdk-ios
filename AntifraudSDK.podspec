Pod::Spec.new do |s|
  s.name             = 'AntifraudSDK'
  s.version          = '1.0.0'
  s.summary          = 'Native iOS SDK for Antifraud.id device fingerprinting and fraud detection.'
  s.description      = <<-DESC
AntifraudSDK collects hardware specifications, OS attributes, carrier metadata,
location signals, and deep security diagnostics (jailbreak, emulator, debugger,
mock location, and tampering hooks), encrypts the payload using hybrid
RSA-OAEP + AES-GCM cryptography, and exchanges it for a stable session_id
via the Antifraud API.
                       DESC
  s.homepage         = 'https://antifraud.id'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'antifraud.id' => 'info@antifraud.id' }
  s.source           = { :git => 'https://github.com/antifraud-id/sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'AntifraudSDK/Sources/**/*.swift'
  s.resource_bundles = {
    'AntifraudSDK_Privacy' => ['AntifraudSDK/Sources/PrivacyInfo.xcprivacy']
  }

  s.frameworks = 'Foundation', 'UIKit', 'CoreLocation', 'CoreTelephony', 'Network', 'Security', 'CryptoKit'
end

import Foundation
import CryptoKit
import Security

enum HybridEncryptor {

    enum EncryptError: Error {
        case invalidKeyPEM
        case keyCreationCheckFailed
        case rsaEncryptionFailed
        case aesEncryptionFailed
    }

    static func encryptPayload(publicKeyPEM: String, plaintextJSON: String) throws -> String {
        let cleanPEM = publicKeyPEM
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: cleanPEM) else {
            throw EncryptError.invalidKeyPEM
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw EncryptError.keyCreationCheckFailed
        }

        let symmetricKey = SymmetricKey(size: .bits256)
        let aesKeyBytes = symmetricKey.withUnsafeBytes { Data($0) }

        guard let rsaCiphertext = SecKeyCreateEncryptedData(
            publicKey,
            .rsaEncryptionOAEPSHA256,
            aesKeyBytes as CFData,
            &error
        ) else {
            throw EncryptError.rsaEncryptionFailed
        }
        let rsaCipherData = rsaCiphertext as Data

        guard let plaintextData = plaintextJSON.data(using: .utf8) else {
            throw EncryptError.aesEncryptionFailed
        }

        var nonceBytes = [UInt8](repeating: 0, count: 12)
        let secStatus = SecRandomCopyBytes(kSecRandomDefault, nonceBytes.count, &nonceBytes)
        guard secStatus == errSecSuccess else {
            throw EncryptError.aesEncryptionFailed
        }
        let nonce = try AES.GCM.Nonce(data: nonceBytes)

        let sealedBox = try AES.GCM.seal(plaintextData, using: symmetricKey, nonce: nonce)
        guard let aesCiphertext = sealedBox.combined else {
            throw EncryptError.aesEncryptionFailed
        }

        var buffer = Data()
        var rsaLen = UInt32(rsaCipherData.count).bigEndian
        buffer.append(Data(bytes: &rsaLen, count: 4))
        buffer.append(rsaCipherData)
        buffer.append(aesCiphertext)

        return buffer.base64EncodedString()
    }
}

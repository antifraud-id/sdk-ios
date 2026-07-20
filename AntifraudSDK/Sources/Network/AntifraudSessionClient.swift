import Foundation

enum AntifraudSessionClient {

    enum NetworkError: Error {
        case invalidURL
        case noData
        case serverError(String)
        case decodingError
    }

    static func createSession(
        apiUrl: String,
        projectId: String,
        timeoutMs: Int,
        encryptedPayload: String
    ) async throws -> String {
        var cleanUrl = apiUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanUrl.hasSuffix("/") {
            cleanUrl = String(cleanUrl.dropLast())
        }
        if !cleanUrl.lowercased().hasPrefix("http://") && !cleanUrl.lowercased().hasPrefix("https://") {
            cleanUrl = "https://" + cleanUrl
        }
        guard let url = URL(string: "\(cleanUrl)/v1/session") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Double(timeoutMs) / 1000.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(projectId, forHTTPHeaderField: "X-Antifraud-Project-ID")

        let jsonDict = ["payload": encryptedPayload]
        let requestBody = try JSONSerialization.data(withJSONObject: jsonDict)
        request.httpBody = requestBody

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: NetworkError.serverError("Invalid HTTP Response"))
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NetworkError.noData)
                    return
                }

                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMsg = try? (JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                    continuation.resume(throwing: NetworkError.serverError(errorMsg ?? "HTTP \(httpResponse.statusCode)"))
                    return
                }

                do {
                    if let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let sessionId = jsonResult["session_id"] as? String {
                        continuation.resume(returning: sessionId)
                    } else {
                        continuation.resume(throwing: NetworkError.decodingError)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }
}

extension AntifraudSessionClient.NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL constructed for the session API."
        case .noData:
            return "No data received from the server."
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError:
            return "Failed to decode session response from the server."
        }
    }
}

extension AntifraudSessionClient.NetworkError: CustomNSError {
    public static var errorDomain: String {
        return "AntifraudNetworkError"
    }

    public var errorCode: Int {
        switch self {
        case .invalidURL:
            return 1001
        case .noData:
            return 1002
        case .serverError:
            return 1003
        case .decodingError:
            return 1004
        }
    }

    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: errorDescription ?? "Unknown network error"]
    }
}

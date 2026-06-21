import Foundation
import CryptoKit

/// PDF取得結果。Android版の ScrapeResult に対応。
struct ScrapeResult {
    let success: Bool
    var pdfData: Data? = nil
    var title: String = ""
    var hash: String = ""
    var errorMessage: String = ""
}

/// www.taisei-exp.com はHTTP Basic認証で保護されている。
/// ユーザー名・パスワードをAuthorizationヘッダーに付けてPDFを直接取得する。
/// Android版の WebScraper.kt(OkHttp実装)に対応する処理をURLSessionで再現。
enum WebScraper {

    static func loginAndFetchPdf(pdfUrl: String, username: String, password: String) async -> ScrapeResult {
        guard let url = URL(string: pdfUrl) else {
            return ScrapeResult(success: false, errorMessage: "URLが不正です")
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        let credentialString = "\(username):\(password)"
        let base64Credential = Data(credentialString.utf8).base64EncodedString()
        request.setValue("Basic \(base64Credential)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/pdf,*/*", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return ScrapeResult(success: false, errorMessage: "通信エラー: 不正なレスポンス")
            }

            if (200...299).contains(httpResponse.statusCode) {
                if data.isEmpty {
                    return ScrapeResult(success: false, errorMessage: "PDFデータが空です")
                }
                return ScrapeResult(
                    success: true,
                    pdfData: data,
                    title: extractFilename(from: pdfUrl),
                    hash: sha256(data)
                )
            } else {
                let message: String
                switch httpResponse.statusCode {
                case 401: message = "認証エラー(401): ユーザー名またはパスワードが違います"
                case 403: message = "アクセス拒否(403)"
                case 404: message = "PDFが見つかりません(404)"
                default:  message = "取得失敗 (status=\(httpResponse.statusCode))"
                }
                return ScrapeResult(success: false, errorMessage: message)
            }
        } catch {
            return ScrapeResult(success: false, errorMessage: "通信エラー: \(error.localizedDescription)")
        }
    }

    private static func extractFilename(from urlString: String) -> String {
        guard let url = URL(string: urlString) else { return "配車表" }
        let name = url.lastPathComponent
        return name.isEmpty ? "配車表" : name
    }

    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

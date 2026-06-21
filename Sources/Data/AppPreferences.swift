import Foundation
import Combine

/// アプリ設定の保存・読み込みを担当する。Android版の AppPreferences (DataStore) に対応。
/// 機密性の高いユーザー名・パスワードは Keychain に、それ以外は UserDefaults に保存する。
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    static let defaultURL4ton = "https://www.taisei-exp.com/t_document/schedule01/haisyalist.pdf"
    static let defaultURLLarge = "https://www.taisei-exp.com/t_document/schedule/haisyalist.pdf"

    private let defaults = UserDefaults.standard

    @Published var username: String {
        didSet { KeychainHelper.save(username, forKey: "username") }
    }
    @Published var password: String {
        didSet { KeychainHelper.save(password, forKey: "password") }
    }
    @Published var checkIntervalMinutes: Int {
        didSet { defaults.set(checkIntervalMinutes, forKey: "check_interval_minutes") }
    }
    @Published var notificationEnabled: Bool {
        didSet { defaults.set(notificationEnabled, forKey: "notification_enabled") }
    }
    @Published var isLoggedIn: Bool {
        didSet { defaults.set(isLoggedIn, forKey: "logged_in") }
    }
    @Published var url4ton: String {
        didSet { defaults.set(url4ton, forKey: "url_4ton") }
    }
    @Published var urlLarge: String {
        didSet { defaults.set(urlLarge, forKey: "url_large") }
    }
    @Published var lastHash4ton: String {
        didSet { defaults.set(lastHash4ton, forKey: "last_hash_4ton") }
    }
    @Published var lastHashLarge: String {
        didSet { defaults.set(lastHashLarge, forKey: "last_hash_large") }
    }

    private init() {
        username = KeychainHelper.load(forKey: "username")
        password = KeychainHelper.load(forKey: "password")
        checkIntervalMinutes = defaults.object(forKey: "check_interval_minutes") as? Int ?? 30
        notificationEnabled = defaults.object(forKey: "notification_enabled") as? Bool ?? true
        isLoggedIn = defaults.object(forKey: "logged_in") as? Bool ?? false
        url4ton = defaults.string(forKey: "url_4ton") ?? AppPreferences.defaultURL4ton
        urlLarge = defaults.string(forKey: "url_large") ?? AppPreferences.defaultURLLarge
        lastHash4ton = defaults.string(forKey: "last_hash_4ton") ?? ""
        lastHashLarge = defaults.string(forKey: "last_hash_large") ?? ""
    }

    func url(for type: VehicleType) -> String {
        type == .fourTon ? url4ton : urlLarge
    }

    func hash(for type: VehicleType) -> String {
        type == .fourTon ? lastHash4ton : lastHashLarge
    }

    func setHash(_ hash: String, for type: VehicleType) {
        if type == .fourTon {
            lastHash4ton = hash
        } else {
            lastHashLarge = hash
        }
    }
}

import Foundation
import UserNotifications

/// ローカル通知の表示を担当する。Android版の NotificationHelper.kt に対応。
/// サーバーからのプッシュ送信ではなく、端末内で定期チェックした結果を通知する方式のため、
/// Apple Developer Program(有料)への登録なしで動作する。
enum NotificationHelper {

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if !granted {
                print("通知の許可が得られませんでした")
            }
        }
    }

    static func showUpdateNotification(title: String, scheduleId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "📋 配車表が更新されました"
        content.body = title
        content.sound = .default
        content.userInfo = ["schedule_id": scheduleId.uuidString]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 即時表示
        )
        UNUserNotificationCenter.current().add(request)
    }
}

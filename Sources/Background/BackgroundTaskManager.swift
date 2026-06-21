import Foundation
import BackgroundTasks

/// バックグラウンドでの定期チェックを担当する。Android版の ScheduleCheckWorker (WorkManager) に対応。
///
/// 【iOSとAndroidの違いについて】
/// AndroidのWorkManagerは指定した間隔で比較的確実にバックグラウンド処理を実行できるが、
/// iOSのBGTaskScheduler(BGAppRefreshTask)は「このタイミング以降のなるべく早い時間に」
/// 実行してほしいとOSにリクエストする仕組みであり、正確な間隔を保証しない
/// (バッテリー残量・利用習慣などをもとにOSが実行タイミングを決定する)。
/// そのため、手動更新(プルダウン)と組み合わせて使うことを推奨する。
enum BackgroundTaskManager {

    static let taskIdentifier = "com.dispatch.app.refresh"

    /// アプリ起動時に1度だけ呼ぶ(タスクの登録)
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleAppRefresh(task: refreshTask)
        }
    }

    /// 次回のバックグラウンドチェックを予約する
    static func schedule() {
        let prefs = AppPreferences.shared
        let intervalMinutes = min(max(prefs.checkIntervalMinutes, 15), 1440)

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(intervalMinutes * 60))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("バックグラウンドタスクの予約に失敗しました: \(error)")
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
    }

    private static func handleAppRefresh(task: BGAppRefreshTask) {
        // 次回分を先に予約しておく(iOSの作法)
        schedule()

        let work = Task {
            await checkAllSchedules()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
        }
    }

    /// 手動更新(プルダウン)・バックグラウンド更新の両方から呼ばれる共通チェック処理
    @MainActor
    static func checkAllSchedules() async {
        let prefs = AppPreferences.shared
        guard !prefs.username.isEmpty else { return }

        for type in VehicleType.allCases {
            await checkSchedule(type: type, prefs: prefs)
        }
    }

    /// 1車種分のチェックを行い、更新があれば保存・通知する
    @MainActor
    @discardableResult
    static func checkSchedule(type: VehicleType, prefs: AppPreferences) async -> (success: Bool, message: String) {
        let url = prefs.url(for: type)
        guard !url.isEmpty else { return (false, "URLが設定されていません") }
        guard !prefs.username.isEmpty else { return (false, "ログイン情報が設定されていません") }

        let result = await WebScraper.loginAndFetchPdf(
            pdfUrl: url,
            username: prefs.username,
            password: prefs.password
        )

        guard result.success, let pdfData = result.pdfData else {
            return (false, result.errorMessage)
        }

        let lastHash = prefs.hash(for: type)
        if result.hash != lastHash {
            let schedule = ScheduleStore.shared.addSchedule(
                type: type, sourceUrl: url, pdfData: pdfData, hash: result.hash
            )
            prefs.setHash(result.hash, for: type)

            if prefs.notificationEnabled {
                NotificationHelper.showUpdateNotification(
                    title: "\(type.label)が更新されました",
                    scheduleId: schedule.id
                )
            }
            return (true, "新しい\(type.label)を取得しました")
        } else {
            return (true, "変更はありません")
        }
    }
}

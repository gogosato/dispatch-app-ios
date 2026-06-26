import Foundation
import BackgroundTasks

/// バックグラウンドでの定期チェックを担当する。Android版の ScheduleCheckWorker (WorkManager) に対応。
///
/// 【iOSとAndroidの違いについて】
/// AndroidのWorkManagerは指定した間隔で比較的確実にバックグラウンド処理を実行できるが、
/// iOSのBGTaskScheduler(BGAppRefreshTask)は「このタイミング以降のなるべく早い時間に」
/// 実行してほしいとOSにリクエストする仕組みであり、正確な間隔を保証しない
/// (バッテリー残量・利用習慣などをもとにOSが実行タイミングを決定する)。
///
/// 【対策】
/// - BGAppRefreshTask: 従来通り。OSが許可したタイミングで軽量チェックを行う。
/// - BGProcessingTask: 充電中かつWi-Fi接続時に実行される、より確実なタスク。
///   BGAppRefreshTask が遅延してもこちらが補完する。
/// - scenePhase (.active): アプリをフォアグラウンドに持ってきた瞬間にチェック。
///   これにより「開いたら必ず最新情報」が保証される。
enum BackgroundTaskManager {

    static let refreshTaskIdentifier    = "com.dispatch.app.refresh"
    static let processingTaskIdentifier = "com.dispatch.app.processing"

    // MARK: - 登録

    /// アプリ起動時に1度だけ呼ぶ(タスクの登録)
    static func register() {
        // BGAppRefreshTask
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleAppRefresh(task: refreshTask)
        }

        // BGProcessingTask
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            handleProcessing(task: processingTask)
        }
    }

    // MARK: - スケジュール

    /// 次回のバックグラウンドチェックを予約する(両タスクをまとめて登録)
    static func schedule() {
        scheduleAppRefresh()
        scheduleProcessing()
    }

    /// BGAppRefreshTask を予約する
    private static func scheduleAppRefresh() {
        let prefs = AppPreferences.shared
        let intervalMinutes = min(max(prefs.checkIntervalMinutes, 15), 1440)

        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(intervalMinutes * 60))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BGAppRefreshTask の予約に失敗しました: \(error)")
        }
    }

    /// BGProcessingTask を予約する(充電中かつWi-Fi時に実行される補完タスク)
    private static func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        // 充電中かつWi-Fi接続時に実行してもらう
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false  // 充電必須にしすぎると動かないため外す
        // 最短でも設定間隔が経過してから実行する
        let prefs = AppPreferences.shared
        let intervalMinutes = min(max(prefs.checkIntervalMinutes, 15), 1440)
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(intervalMinutes * 60))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // 既に登録済みの場合などエラーになることがあるが無視してよい
            print("BGProcessingTask の予約に失敗しました: \(error)")
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: processingTaskIdentifier)
    }

    // MARK: - ハンドラ

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

    private static func handleProcessing(task: BGProcessingTask) {
        // 次回分を先に予約しておく
        schedule()

        let work = Task {
            await checkAllSchedules()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
        }
    }

    // MARK: - チェック処理

    /// 手動更新(プルダウン)・バックグラウンド更新・フォアグラウンド復帰の全ケースから呼ばれる共通チェック処理
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

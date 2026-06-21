import SwiftUI

@main
struct DispatchAppApp: App {
    @StateObject private var prefs = AppPreferences.shared
    @StateObject private var store = ScheduleStore.shared

    init() {
        // バックグラウンドタスクの登録は、アプリ起動のなるべく早い段階で行う必要がある
        BackgroundTaskManager.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(prefs)
                .environmentObject(store)
                .onAppear {
                    if prefs.isLoggedIn {
                        BackgroundTaskManager.schedule()
                    }
                }
        }
    }
}

/// ログイン状態に応じて表示する画面を切り替える(Android版のcheckAndNavigateToLoginに対応)
struct RootView: View {
    @EnvironmentObject var prefs: AppPreferences

    var body: some View {
        if prefs.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

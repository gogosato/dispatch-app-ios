import SwiftUI

/// 設定画面。Android版の SettingsActivity.kt に対応。
struct SettingsView: View {
    @EnvironmentObject var prefs: AppPreferences
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var password = ""
    @State private var url4ton = ""
    @State private var urlLarge = ""
    @State private var intervalText = ""
    @State private var notificationEnabled = true
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("ログイン情報") {
                    TextField("ユーザー名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("パスワード", text: $password)
                }

                Section("取得先URL") {
                    TextField("4トンPDF URL", text: $url4ton)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("大型PDF URL", text: $urlLarge)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("更新設定") {
                    HStack {
                        Text("チェック間隔(分)")
                        Spacer()
                        TextField("30", text: $intervalText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    Text("15〜1440分の範囲で設定できます。OSの判断により実際の間隔は前後します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Toggle("通知を有効にする", isOn: $notificationEnabled)
                }

                Section {
                    Button("ログアウト", role: .destructive) {
                        showLogoutConfirm = true
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .disabled(username.isEmpty || password.isEmpty)
                }
            }
            .onAppear(perform: loadCurrent)
            .confirmationDialog("ログアウトしますか?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("ログアウト", role: .destructive) { logout() }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }

    private func loadCurrent() {
        username = prefs.username
        password = prefs.password
        url4ton = prefs.url4ton
        urlLarge = prefs.urlLarge
        intervalText = String(prefs.checkIntervalMinutes)
        notificationEnabled = prefs.notificationEnabled
    }

    private func save() {
        let interval = min(max(Int(intervalText) ?? 30, 15), 1440)

        prefs.username = username
        prefs.password = password
        prefs.url4ton = url4ton.isEmpty ? AppPreferences.defaultURL4ton : url4ton
        prefs.urlLarge = urlLarge.isEmpty ? AppPreferences.defaultURLLarge : urlLarge
        prefs.checkIntervalMinutes = interval
        prefs.notificationEnabled = notificationEnabled
        prefs.isLoggedIn = true

        BackgroundTaskManager.schedule()
        dismiss()
    }

    private func logout() {
        BackgroundTaskManager.cancel()
        prefs.isLoggedIn = false
        dismiss()
    }
}

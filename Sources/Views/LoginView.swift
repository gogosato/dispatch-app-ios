import SwiftUI

/// ログイン画面。Android版の LoginActivity.kt に対応。
struct LoginView: View {
    @EnvironmentObject var prefs: AppPreferences
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("大成運送配車")
                        .font(.title2)
                        .bold()
                }

                VStack(spacing: 12) {
                    TextField("ユーザー名", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("パスワード", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 32)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    Task { await attemptLogin() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("ログイン")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(username.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
            .onAppear { username = prefs.username }
        }
    }

    private func attemptLogin() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        // 4トンPDFのURLでログイン可否を確認(Android版と同じロジック)
        let result = await WebScraper.loginAndFetchPdf(
            pdfUrl: prefs.url4ton,
            username: username,
            password: password
        )

        if result.success {
            prefs.username = username
            prefs.password = password
            prefs.isLoggedIn = true
            NotificationHelper.requestAuthorizationIfNeeded()
            BackgroundTaskManager.schedule()
        } else {
            errorMessage = "ログイン失敗: \(result.errorMessage)"
        }
    }
}

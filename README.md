# 大成運送配車 - iOSアプリ

Android版「大成運送配車」のiOS移植版(Swift/SwiftUI)。

## できること(Android版と同等)
- ユーザー名・パスワードでログイン(www.taisei-exp.com、Basic認証)
- 4トン配車・大型配車のPDFを定期的に自動チェック
- 更新があればローカル通知
- 一覧・詳細(PDFKitによるピンチズーム対応PDF表示)
- 未読バッジ表示・スワイプ削除・プルダウン手動更新

## 技術構成
- SwiftUI + Swift Concurrency(async/await)
- 認証情報: Keychain
- その他設定: UserDefaults
- 配車表データ: Documents配下にJSON+PDFファイルで保存(サーバー不要)
- バックグラウンド更新: BGTaskScheduler(BGAppRefreshTask)
- 通知: UNUserNotificationCenter(ローカル通知。サーバープッシュではない)
- 外部ライブラリ: なし(標準フレームワークのみ)

## ビルド方法

### GitHub Actions(推奨・このリポジトリの想定フロー)
`main` ブランチにpushすると `.github/workflows/build.yml` が自動実行され、
GitHub上のmacOSランナーで未署名の `.ipa` がビルドされます。
「Actions」タブ → 該当の実行 → 「Artifacts」から `DispatchApp-ipa` をダウンロードしてください。

その `.ipa` をSideloadlyでご自身のiPhoneにインストールします。

### ローカル(Macをお持ちの場合)
```
brew install xcodegen
xcodegen generate
open DispatchApp.xcodeproj
```

## 設定が必要な項目
- `Sources/Data/AppPreferences.swift` 内のデフォルトURL(`defaultURL4ton` / `defaultURLLarge`)
  は初回ログイン前のデフォルト値です。実際の認証情報はアプリ内の設定画面から入力します。

## Android版との違い
- PDF表示: 自作ズームView → PDFKitの標準ズーム(より滑らか)
- バックグラウンド更新: 指定間隔での確実な実行 → iOSの判断による「なるべく早いタイミング」
  (正確性が必要な場合はプルダウンでの手動更新を併用してください)
- 通知: ローカル通知方式のため、Apple Developer Program未加入でも動作します

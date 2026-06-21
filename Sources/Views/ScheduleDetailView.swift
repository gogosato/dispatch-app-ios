import SwiftUI
import PDFKit

/// PDF詳細表示画面。Android版の ScheduleDetailActivity.kt + ZoomableImageView.kt に対応。
///
/// Android版では PdfRenderer でページをBitmap化し、自作の ZoomableImageView で
/// ピンチズーム・パン・ダブルタップ拡大を実装していたが、
/// iOSでは PDFKit の PDFView がピンチズーム・ページめくり・ダブルタップ拡大を標準で備えているため、
/// 自作ズームコードは不要になる。
struct ScheduleDetailView: View {
    let schedule: DispatchSchedule
    @EnvironmentObject var store: ScheduleStore
    @State private var document: PDFDocument?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let document {
                PDFKitView(document: document)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(schedule.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("取得日時: \(dateText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear(perform: load)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: schedule.fetchedAt)
    }

    private func load() {
        guard document == nil else { return }
        let url = store.pdfURL(for: schedule)
        guard FileManager.default.fileExists(atPath: url.path),
              let doc = PDFDocument(url: url) else {
            errorMessage = "PDFファイルが見つかりません"
            return
        }
        document = doc
    }
}

/// PDFKitのPDFViewをSwiftUIで使うためのラッパー。
/// ピンチズーム・ダブルタップ拡大・ページ送りはPDFView標準機能でそのまま動作する。
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemBackground
        view.maxScaleFactor = 6.0
        view.minScaleFactor = view.scaleFactorForSizeToFit
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }
    }
}

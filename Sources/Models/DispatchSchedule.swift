import Foundation

/// 取得した配車表(PDF)1件分のメタデータ。
/// Android版の Room Entity「DispatchSchedule」に対応。
/// PDF本体は端末内ファイルとして保存し、ここではファイル名のみ保持する。
struct DispatchSchedule: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var pdfFileName: String
    var contentHash: String
    var fetchedAt: Date
    var sourceUrl: String
    var vehicleType: VehicleType
    var isRead: Bool = false
}

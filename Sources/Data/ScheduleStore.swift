import Foundation

/// 取得済み配車表の一覧管理・永続化を担当する。
/// Android版の Room (AppDatabase + DispatchDao) に対応するが、
/// データ量が小さいアプリのためシンプルにJSONファイル+PDFファイル保存で実装する。
@MainActor
final class ScheduleStore: ObservableObject {
    static let shared = ScheduleStore()

    @Published private(set) var schedules: [DispatchSchedule] = []

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var pdfsDirectory: URL {
        let dir = documentsURL.appendingPathComponent("pdfs", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var indexFileURL: URL {
        documentsURL.appendingPathComponent("schedules.json")
    }

    private init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexFileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let decoded = try? decoder.decode([DispatchSchedule].self, from: data) {
            schedules = decoded.sorted { $0.fetchedAt > $1.fetchedAt }
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(schedules) {
            try? data.write(to: indexFileURL, options: .atomic)
        }
    }

    func schedules(for type: VehicleType) -> [DispatchSchedule] {
        schedules.filter { $0.vehicleType == type }
    }

    func unreadCount(for type: VehicleType? = nil) -> Int {
        if let type {
            return schedules.filter { $0.vehicleType == type && !$0.isRead }.count
        }
        return schedules.filter { !$0.isRead }.count
    }

    func pdfURL(for schedule: DispatchSchedule) -> URL {
        pdfsDirectory.appendingPathComponent(schedule.pdfFileName)
    }

    @discardableResult
    func addSchedule(type: VehicleType, sourceUrl: String, pdfData: Data, hash: String) -> DispatchSchedule {
        let fileName = "\(type.rawValue)_\(Int(Date().timeIntervalSince1970 * 1000)).pdf"
        let fileURL = pdfsDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: fileURL)

        let schedule = DispatchSchedule(
            title: type.label,
            pdfFileName: fileName,
            contentHash: hash,
            fetchedAt: Date(),
            sourceUrl: sourceUrl,
            vehicleType: type
        )
        schedules.insert(schedule, at: 0)
        persist()
        return schedule
    }

    func markAsRead(_ id: UUID) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }
        guard !schedules[index].isRead else { return }
        schedules[index].isRead = true
        persist()
    }

    func delete(_ schedule: DispatchSchedule) {
        try? fileManager.removeItem(at: pdfURL(for: schedule))
        schedules.removeAll { $0.id == schedule.id }
        persist()
    }
}

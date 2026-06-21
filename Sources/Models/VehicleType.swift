import Foundation

/// 車種別の配車表タイプ。Android版の VehicleType enum に対応。
enum VehicleType: String, CaseIterable, Codable, Hashable {
    case fourTon = "FOUR_TON"
    case large = "LARGE"

    var label: String {
        switch self {
        case .fourTon: return "4トン配車"
        case .large: return "大型配車"
        }
    }

    var iconName: String {
        switch self {
        case .fourTon: return "truck.box"
        case .large: return "truck.box.fill"
        }
    }
}

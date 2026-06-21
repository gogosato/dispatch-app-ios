import SwiftUI

/// 一覧の1行分の表示。Android版の item_schedule.xml + ScheduleAdapter.kt に対応。
struct ScheduleRowView: View {
    let schedule: DispatchSchedule

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: schedule.fetchedAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(schedule.isRead ? Color.clear : Color.red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.title)
                    .font(.headline)
                Text(dateText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .opacity(schedule.isRead ? 0.7 : 1.0)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

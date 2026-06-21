import SwiftUI

/// 1車種分の配車表一覧。Android版の ScheduleListFragment.kt に対応。
struct ScheduleListView: View {
    let vehicleType: VehicleType
    @EnvironmentObject var store: ScheduleStore
    @EnvironmentObject var prefs: AppPreferences
    @State private var toastMessage: String?

    private var schedules: [DispatchSchedule] {
        store.schedules(for: vehicleType)
    }

    var body: some View {
        Group {
            if schedules.isEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        emptyView
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            } else {
                List {
                    ForEach(schedules) { schedule in
                        NavigationLink(value: schedule) {
                            ScheduleRowView(schedule: schedule)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(schedule)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationDestination(for: DispatchSchedule.self) { schedule in
            ScheduleDetailView(schedule: schedule)
                .onAppear { store.markAsRead(schedule.id) }
        }
        .refreshable {
            await refresh()
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.footnote)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("配車表がありません")
                .font(.headline)
            Text("下に引っ張って更新してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func refresh() async {
        let result = await BackgroundTaskManager.checkSchedule(type: vehicleType, prefs: prefs)
        withAnimation { toastMessage = result.message }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        withAnimation { toastMessage = nil }
    }
}

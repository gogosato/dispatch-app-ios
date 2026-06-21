import SwiftUI

/// 4トン配車/大型配車のタブ画面。Android版の MainActivity.kt (ViewPager2 + TabLayout) に対応。
struct MainTabView: View {
    @EnvironmentObject var store: ScheduleStore
    @EnvironmentObject var prefs: AppPreferences
    @State private var selectedTab: VehicleType = .fourTon
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(VehicleType.allCases, id: \.self) { type in
                NavigationStack {
                    ScheduleListView(vehicleType: type)
                        .navigationTitle(navTitle)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape")
                                }
                            }
                        }
                }
                .tabItem {
                    Label(tabTitle(for: type), systemImage: type.iconName)
                }
                .tag(type)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func tabTitle(for type: VehicleType) -> String {
        let count = store.unreadCount(for: type)
        return count > 0 ? "\(type.label)(\(count))" : type.label
    }

    private var navTitle: String {
        let count = store.unreadCount()
        return count > 0 ? "配車表(\(count)件未読)" : "配車表"
    }
}

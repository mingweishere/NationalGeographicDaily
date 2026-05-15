import SwiftUI
import SwiftData

@main
struct NationalGeographicDailyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        BackgroundRefreshService.registerHandler()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: FavoritePhoto.self)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefreshService.scheduleRefresh()
            }
        }
    }
}

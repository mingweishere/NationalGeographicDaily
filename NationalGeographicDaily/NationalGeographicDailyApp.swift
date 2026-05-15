import SwiftUI
import SwiftData

@main
struct NationalGeographicDailyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: FavoritePhoto.self)
    }
}

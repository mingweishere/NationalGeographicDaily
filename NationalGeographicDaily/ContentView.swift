import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("Today's Photo")
                    .navigationTitle("NatGeo Daily")
            }
            .tabItem {
                Label("Today", systemImage: "photo")
            }

            NavigationStack {
                Text("Favorites")
                    .navigationTitle("Favorites")
            }
            .tabItem {
                Label("Favorites", systemImage: "heart.fill")
            }

            NavigationStack {
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .tint(.yellow)
    }
}

#Preview {
    ContentView()
}

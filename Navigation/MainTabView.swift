import SwiftUI

enum AppTab: Hashable {
    case home, scan, collection, profile
}

struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onScan: { selection = .scan })
                .tabItem { Label("Hem", systemImage: "house") }
                .tag(AppTab.home)

            ScannerView()
                .tabItem { Label("Skanna", systemImage: "camera.viewfinder") }
                .tag(AppTab.scan)

            CollectionView()
                .tabItem { Label("Samling", systemImage: "books.vertical") }
                .tag(AppTab.collection)

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(AntiqueTheme.brass)
    }
}
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TravelListView()
            }
            .tabItem {
                Label("旅行", systemImage: "airplane.departure")
            }

            NavigationStack {
                RandomReviewView()
            }
            .tabItem {
                Label("回忆", systemImage: "shuffle")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Travel.self, TravelRecord.self, PhotoItem.self], inMemory: true)
}

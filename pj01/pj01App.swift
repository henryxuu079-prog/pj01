import SwiftUI
import SwiftData

@main
struct pj01App: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([Travel.self, TravelRecord.self, PhotoItem.self])
            let config = ModelConfiguration(
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        #if os(macOS)
        .commands {
            AppCommands()
        }
        #endif
    }
}

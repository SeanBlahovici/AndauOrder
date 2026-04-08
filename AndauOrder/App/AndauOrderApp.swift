import SwiftUI
import SwiftData

@main
struct AndauOrderApp: App {
    @State private var syncCoordinator = SyncCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncCoordinator)
        }
        .modelContainer(for: [
            OrderRecord.self,
            SyncQueueEntry.self,
            CachedZohoItem.self,
            PriceCatalogEntry.self,
        ])
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

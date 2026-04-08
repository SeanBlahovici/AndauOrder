import SwiftUI
import SwiftData

@main
struct AndauOrderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            OrderRecord.self,
            SyncQueueEntry.self,
            CachedZohoItem.self,
        ])
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

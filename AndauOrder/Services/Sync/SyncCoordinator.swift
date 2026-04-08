import Foundation
import SwiftData
import Observation

@Observable
final class SyncCoordinator: @unchecked Sendable {
    let syncEngine: SyncEngine
    private let networkMonitor: NetworkMonitor
    private var isProcessing = false

    init() {
        self.syncEngine = SyncEngine()
        self.networkMonitor = NetworkMonitor()
    }

    var isConnected: Bool { networkMonitor.isConnected }

    @MainActor
    func syncNow(modelContext: ModelContext) async {
        guard !isProcessing, networkMonitor.isConnected else { return }
        isProcessing = true
        defer { isProcessing = false }
        await syncEngine.processQueue(modelContext: modelContext)
    }
}

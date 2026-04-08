import SwiftUI

struct SyncStatusBadge: View {
    let status: SyncStatus

    var body: some View {
        Label(status.displayLabel, systemImage: status.iconName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundStyle(backgroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .draft: .secondary
        case .pendingSync: .orange
        case .syncing: .blue
        case .partiallySynced: .yellow
        case .synced: .green
        case .failed: .red
        }
    }
}

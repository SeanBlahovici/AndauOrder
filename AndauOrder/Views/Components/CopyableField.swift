import SwiftUI

struct CopyableField: View {
    let label: String
    let value: String
    @State private var showCopied = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value.isEmpty ? "—" : value)
                .textSelection(.enabled)

            Spacer()

            if !value.isEmpty {
                Button {
                    ClipboardHelper.copy(value)
                    showCopied = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        showCopied = false
                    }
                } label: {
                    if showCopied {
                        Label("Copied", systemImage: "checkmark")
                            .foregroundStyle(.green)
                    } else {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .animation(.default, value: showCopied)
            }
        }
    }
}

struct CopyButton: View {
    let title: String
    let textToCopy: String
    @State private var showCopied = false

    var body: some View {
        Button {
            ClipboardHelper.copy(textToCopy)
            showCopied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                showCopied = false
            }
        } label: {
            if showCopied {
                Label("Copied!", systemImage: "checkmark")
                    .foregroundStyle(.green)
            } else {
                Label(title, systemImage: "doc.on.doc")
            }
        }
        .buttonStyle(.bordered)
        .animation(.default, value: showCopied)
    }
}

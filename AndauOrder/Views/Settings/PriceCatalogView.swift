import SwiftUI
import SwiftData

struct PriceCatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PriceCatalogEntry.category) private var entries: [PriceCatalogEntry]
    @State private var hasSeeded = false

    private var groupedEntries: [(category: String, entries: [PriceCatalogEntry])] {
        let grouped = Dictionary(grouping: entries, by: \.category)
        let order = ["Loupes", "Headlights", "Accessories", "Adapters", "Corrections", "Other"]
        return order.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        Form {
            if entries.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Prices Set", systemImage: "dollarsign.circle")
                    } description: {
                        Text("Tap 'Initialize Catalog' to set up default product prices.")
                    } actions: {
                        Button("Initialize Catalog") {
                            seedCatalog()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ForEach(groupedEntries, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.entries) { entry in
                            PriceCatalogRowView(entry: entry)
                        }
                    }
                }

                Section {
                    Button("Reset All Prices to $0", role: .destructive) {
                        for entry in entries {
                            entry.price = 0
                            entry.updatedAt = Date()
                        }
                        try? modelContext.save()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Price Catalog")
        .onAppear {
            if entries.isEmpty && !hasSeeded {
                seedCatalog()
            }
        }
    }

    private func seedCatalog() {
        guard entries.isEmpty else { return }
        for entry in PriceCatalogLookup.defaultEntries {
            modelContext.insert(entry)
        }
        try? modelContext.save()
        hasSeeded = true
    }
}

struct PriceCatalogRowView: View {
    @Bindable var entry: PriceCatalogEntry

    var body: some View {
        HStack {
            Text(entry.label)
            Spacer()
            HStack(spacing: 2) {
                Text("$").foregroundStyle(.secondary)
                TextField("0", value: $entry.price, format: .number.precision(.fractionLength(2)))
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            .frame(width: 120)
        }
    }
}

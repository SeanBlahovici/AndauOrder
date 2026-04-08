import SwiftUI

struct ProductSelectionView: View {
    @Binding var formData: OrderFormData

    var body: some View {
        Form {
            // Loupes
            Section("Loupes") {
                loupeStylePicker
                if formData.loupeSelection.style != nil {
                    loupeFramePicker
                    if let frame = formData.loupeSelection.frame {
                        if frame.requiresSize {
                            loupeFrameSizePicker(frame: frame)
                        }
                        loupeColorPicker(frame: frame)
                    }
                }
            }

            // Headlights
            Section("Headlights") {
                headlightTypePicker
                if formData.headlightSelection.type != nil {
                    headlightAccessories
                }
            }

            // PPE
            Section("PPE") {
                Toggle("Side Shield", isOn: $formData.ppeSelection.sideShield)
                Toggle("Laser Protection", isOn: $formData.ppeSelection.laserProtection)
            }

            // Adapters
            Section("Adapters") {
                adapterPicker
            }

            // Other
            Section("Other Notes") {
                TextField("Additional notes...", text: $formData.otherNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Loupes

    @ViewBuilder
    private var loupeStylePicker: some View {
        let grouped = Dictionary(grouping: LoupeStyle.allCases, by: \.category)
        let categories = ["Ergo V", "Ergo", "Galilean", "Prismatic"]

        Picker("Style", selection: $formData.loupeSelection.style) {
            Text("None").tag(LoupeStyle?.none)
            ForEach(categories, id: \.self) { category in
                if let styles = grouped[category] {
                    Section(category) {
                        ForEach(styles) { style in
                            Text(style.rawValue).tag(LoupeStyle?.some(style))
                        }
                    }
                }
            }
        }
        .onChange(of: formData.loupeSelection.style) { _, _ in
            // Reset dependent fields when style changes
            formData.loupeSelection.frame = nil
            formData.loupeSelection.size = nil
            formData.loupeSelection.color = nil
        }
    }

    @ViewBuilder
    private var loupeFramePicker: some View {
        Picker("Frame", selection: $formData.loupeSelection.frame) {
            Text("None").tag(FrameModel?.none)
            ForEach(FrameModel.allCases) { frame in
                Text(frame.rawValue).tag(FrameModel?.some(frame))
            }
        }
        .onChange(of: formData.loupeSelection.frame) { _, _ in
            formData.loupeSelection.size = nil
            formData.loupeSelection.color = nil
        }
    }

    @ViewBuilder
    private func loupeFrameSizePicker(frame: FrameModel) -> some View {
        Picker("Size", selection: $formData.loupeSelection.size) {
            Text("None").tag(FrameSize?.none)
            ForEach(frame.availableSizes) { size in
                Text(size.displayName).tag(FrameSize?.some(size))
            }
        }
    }

    @ViewBuilder
    private func loupeColorPicker(frame: FrameModel) -> some View {
        Picker("Color", selection: $formData.loupeSelection.color) {
            Text("None").tag(String?.none)
            ForEach(frame.availableColors, id: \.self) { color in
                Text(color).tag(String?.some(color))
            }
        }
    }

    // MARK: - Headlights

    @ViewBuilder
    private var headlightTypePicker: some View {
        let grouped = Dictionary(grouping: HeadlightType.allCases, by: \.category)
        let categories = ["Orchid", "External", "Student", "Butterfly"]

        Picker("Type", selection: $formData.headlightSelection.type) {
            Text("None").tag(HeadlightType?.none)
            ForEach(categories, id: \.self) { category in
                if let types = grouped[category] {
                    Section(category) {
                        ForEach(types) { type in
                            Text(type.rawValue).tag(HeadlightType?.some(type))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var headlightAccessories: some View {
        Toggle("Extra Battery", isOn: $formData.headlightSelection.extraBattery)
        Toggle("3.5 ft Orchid Cord", isOn: $formData.headlightSelection.orchidCord3_5ft)
        Toggle("5 ft Orchid Cord", isOn: $formData.headlightSelection.orchidCord5ft)
    }

    // MARK: - Adapters

    @ViewBuilder
    private var adapterPicker: some View {
        Picker("Adapter Type", selection: $formData.adapterSelection.type) {
            Text("None").tag(AdapterType?.none)
            ForEach(AdapterType.allCases) { adapter in
                Text(adapter.rawValue).tag(AdapterType?.some(adapter))
            }
        }

        if formData.adapterSelection.type == .competitorAdapter {
            TextField("Competitor Adapter Detail", text: $formData.adapterSelection.competitorAdapterDetail)
        }
    }
}

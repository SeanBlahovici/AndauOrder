import SwiftUI

struct CustomizationView: View {
    @Binding var formData: OrderFormData

    var body: some View {
        Form {
            // Customization
            Section("Customization") {
                TextField("Custom Engraving", text: $formData.customization.customEngraving)

                HStack {
                    Text("Working Distance")
                    Spacer()
                    TextField(
                        "0",
                        value: $formData.customization.workingDistanceInches,
                        format: .number
                    )
                    .multilineTextAlignment(.trailing)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(width: 80)
                    Text("in")
                        .foregroundStyle(.secondary)
                }

                TextField("Case #", text: $formData.customization.caseNumber)

                TextField("Pics Taken By", text: $formData.customization.picsTakenBy)
            }

            // Prescription
            Section("Prescription") {
                prescriptionSection
            }

            // External Lens Distance
            Section("External Lens Distance") {
                Toggle("Near (Reading)", isOn: $formData.prescription.externalLensNear)
                Toggle("Middle (Computer)", isOn: $formData.prescription.externalLensMiddle)
                Toggle("Far (Distance)", isOn: $formData.prescription.externalLensFar)
            }

            // Eye Exam & Records
            Section("Eye Exam & Records") {
                optionalBoolPicker("Current Eye Exam?", selection: $formData.prescription.currentEyeExam)
                optionalBoolPicker("Do We Have a Copy?", selection: $formData.prescription.doWeHaveCopy)
                optionalBoolPicker("Contacts?", selection: $formData.prescription.contacts)
                optionalBoolPicker("Readers?", selection: $formData.prescription.readers)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private var prescriptionSection: some View {
        // Internal correction
        Picker("Internal", selection: $formData.prescription.internalType) {
            Text("None").tag(CorrectionType?.none)
            ForEach([CorrectionType.regular, .special], id: \.self) { type in
                Text(type.rawValue).tag(CorrectionType?.some(type))
            }
        }

        // External correction
        Picker("External", selection: $formData.prescription.externalType) {
            Text("None").tag(ExternalCorrectionType?.none)
            ForEach([ExternalCorrectionType.regular, .special, .multiFocal], id: \.self) { type in
                Text(type.rawValue).tag(ExternalCorrectionType?.some(type))
            }
        }
    }

    @ViewBuilder
    private func optionalBoolPicker(_ label: String, selection: Binding<Bool?>) -> some View {
        Picker(label, selection: selection) {
            Text("—").tag(Bool?.none)
            Text("Yes").tag(Bool?.some(true))
            Text("No").tag(Bool?.some(false))
        }
    }
}

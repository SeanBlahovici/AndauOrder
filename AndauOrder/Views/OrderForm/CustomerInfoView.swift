import SwiftUI
import PhotosUI

struct CustomerInfoView: View {
    @Binding var formData: OrderFormData
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Form {
            // Order Info
            Section("Order Information") {
                DatePicker("Date", selection: $formData.date, displayedComponents: .date)

                TextField("Territory Manager", text: $formData.territoryManager)

                TextField("Specialty", text: $formData.customer.specialty)
                    .textContentType(.jobTitle)

                TextField("Currently Using", text: $formData.customer.currentlyUsing)

                Toggle("Student", isOn: $formData.customer.isStudent)
            }

            // Customer Details
            Section("Customer Details") {
                TextField("First Name", text: $formData.customer.firstName)
                    .textContentType(.givenName)

                TextField("Last Name", text: $formData.customer.lastName)
                    .textContentType(.familyName)

                TextField("Email", text: $formData.customer.email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif

                TextField("Phone", text: $formData.customer.phone)
                    .textContentType(.telephoneNumber)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif

                TextField("Clinic Name", text: $formData.customer.clinicName)
                    .textContentType(.organizationName)
            }

            // Billing Address
            Section("Billing Address") {
                addressFields(address: $formData.customer.billingAddress)
            }

            // Shipping Address
            Section("Shipping Address") {
                Toggle("Same as Billing", isOn: $formData.customer.shippingSameAsBilling)

                if !formData.customer.shippingSameAsBilling {
                    addressFields(address: $formData.customer.shippingAddress)
                }
            }

            // Student Info (conditional)
            if formData.customer.isStudent {
                Section("Student Information") {
                    TextField("School Name", text: studentInfoBinding.schoolName)

                    DatePicker(
                        "Graduation Date",
                        selection: Binding(
                            get: { formData.customer.studentInfo?.graduationDate ?? Date() },
                            set: { formData.customer.studentInfo?.graduationDate = $0 }
                        ),
                        displayedComponents: .date
                    )

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let photoData = formData.customer.studentInfo?.schoolIDPhotoData,
                           let image = imageFromData(photoData) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Label("Select School ID Photo", systemImage: "photo.badge.plus")
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                formData.customer.studentInfo?.schoolIDPhotoData = data
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: formData.customer.isStudent) { _, isStudent in
            if isStudent && formData.customer.studentInfo == nil {
                formData.customer.studentInfo = StudentInfo()
            }
        }
    }

    @ViewBuilder
    private func addressFields(address: Binding<Address>) -> some View {
        TextField("Street", text: address.street)
            .textContentType(.streetAddressLine1)

        TextField("Street 2 (Optional)", text: address.street2)
            .textContentType(.streetAddressLine2)

        TextField("City", text: address.city)
            .textContentType(.addressCity)

        TextField("Province / State", text: address.stateProvince)
            .textContentType(.addressState)

        TextField("Postal / ZIP Code", text: address.postalZipCode)
            .textContentType(.postalCode)

        TextField("Country", text: address.country)
            .textContentType(.countryName)
    }

    #if os(macOS)
    private func imageFromData(_ data: Data) -> Image? {
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
    }
    #else
    private func imageFromData(_ data: Data) -> Image? {
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
    #endif

    private var studentInfoBinding: Binding<StudentInfo> {
        Binding(
            get: { formData.customer.studentInfo ?? StudentInfo() },
            set: { formData.customer.studentInfo = $0 }
        )
    }
}

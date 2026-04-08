# Export & Copy Station — Design Spec

## Context

Michelle uses AndauOrder on her Mac to capture dental loupes orders at conferences. She then manually enters this data into Zoho CRM and Zoho Books on her laptop. Without Zoho API access, the app currently saves orders locally but provides no way to get the data out efficiently. The biggest pain point is entering estimate line items into Zoho Books, followed by the repetitive lead creation fields in CRM and re-entering her own contact info on every estimate.

This feature makes the app useful without API access by providing a Copy Station (field-by-field copy-to-clipboard) and PDF export (printable summary for records and side-by-side reference).

## Design

### 1. Export Tab (7th tab in OrderFormContainerView)

A new tab added after "Review & Submit" in the horizontal tab bar. Only enabled when the order has been saved. Organized to match Michelle's Zoho entry workflow sequence.

#### 1a. Lead Info Section

Mirrors the Zoho CRM "Create Lead" form. Each row displays:

| Field Label | Value (from OrderFormData) | Copy Button |

Fields (using FieldMappings.leadFields naming):
- First Name (`customer.firstName`)
- Last Name (`customer.lastName`)
- Email (`customer.email`)
- Phone (`customer.phone`)
- Company (`customer.clinicName`)
- Street (`customer.billingAddress.street`)
- City (`customer.billingAddress.city`)
- Province (`customer.billingAddress.stateProvince`)
- Postal Code (`customer.billingAddress.postalZipCode`)
- Country (`customer.billingAddress.country`)

A "Copy All Lead Fields" button at the section top copies all fields as a formatted text block for reference.

#### 1b. Deal Info Section

For the Opportunities step in Zoho CRM:
- Deal Name — auto-generated via `FieldMappings.dealName(from:)` (e.g., "Jane Doe - Ergo 3.0x Indie M")
- Estimated Amount — `pricing.total` formatted as CAD currency
- Closing Date — order date formatted as yyyy-MM-dd (Michelle can adjust in Zoho)

Each with individual Copy buttons.

#### 1c. Estimate Line Items Section

The primary pain point. Uses `FieldMappings.estimateLineItems(from:)` to generate the same line items that would be sent to Zoho Books API.

Each line item displayed as a card:
- Product Name | Description (if any) | Rate (CAD)
- Copy buttons for name and rate individually
- "Copy All Line Items" button copies a formatted reference table

Conditional items (only shown when applicable):
- Loupes (style + frame + size + color)
- Internal Correction
- External Correction
- Headlight (with accessories note)
- Flamingo
- Laser Inserts
- Adapters
- Shipping
- Promotion Discount

#### 1d. Michelle's Info Block

Pre-filled from Settings (UserDefaults: michelleEmail, michellePhone). Formatted exactly as needed for Zoho Books estimate notes:

```
Contact: Michelle Fontaine
Email: michelle@example.com
Phone: 555-1234
```

Single "Copy Notes Block" button. Reuses `FieldMappings.estimateNotes(from:defaults:)`.

#### 1e. Workflow Checklist

Non-copyable step-by-step reminder of the Zoho entry workflow:
1. Create Lead in CRM (use Lead Info section above)
2. Transition Lead: New → TM Reached Out → Customer Engaged
3. In Opportunities: Transition to Qualified, set closing date & amount
4. Demo Booked / Meeting Scheduled — set demo date & follow-up
5. Sync Account with Books
6. Create Estimate in Books (use Line Items section above)
7. Add Michelle's info to estimate notes (use Info Block above)
8. Verify customer info in Customers
9. Add credit card if available

### 2. PDF Export

A "Generate PDF" button at the bottom of the Export tab. Also accessible from the order list context menu.

#### PDF Layout

- **Header**: "Andau Medical — Order Summary" + order date + order number
- **Customer Block**: Full name, email, phone, clinic, specialty, student status, billing & shipping addresses
- **Products Block**: Table of selected products with descriptions
- **Customization Block**: Engraving text, working distance, Rx type details
- **Pricing Table**: All line items, subtotal, tax (14.975% QC), total in CAD
- **Signature**: Embedded signature image (if captured)
- **Footer**: "Territory Manager: Michelle Fontaine" + email + phone

#### Implementation

- Dedicated `OrderPDFView` — a SwiftUI view designed specifically for PDF rendering (not the same as the on-screen Export tab)
- Rendered via `ImageRenderer` to generate PDF data
- macOS: NSSavePanel for save location, or NSPrintOperation for direct printing
- iOS: Share Sheet (UIActivityViewController)
- Accessible from:
  - "Generate PDF" button on Export tab
  - Right-click context menu on orders in the order list ("Export to PDF")

### 3. Copy Feedback UX

- Each Copy button: tapping copies the value to system clipboard
- Button shows "Copied" state with checkmark for ~1.5 seconds
- Uses `NSPasteboard.general` (macOS) / `UIPasteboard.general` (iOS)
- Platform-adaptive via `#if os(macOS)` / `#else`

### 4. Integration Points

**New files:**
- `AndauOrder/Views/OrderForm/ExportView.swift` — The Export tab view with all copy sections
- `AndauOrder/Views/Components/CopyableField.swift` — Reusable row component (label + value + copy button)
- `AndauOrder/Views/Components/OrderPDFView.swift` — SwiftUI view for PDF rendering
- `AndauOrder/Utilities/PDFGenerator.swift` — PDF generation helper (ImageRenderer → Data)
- `AndauOrder/Utilities/ClipboardHelper.swift` — Cross-platform clipboard abstraction

**Modified files:**
- `AndauOrder/Views/OrderForm/OrderFormContainerView.swift` — Add 7th "Export" tab
- `AndauOrder/Views/OrderList/OrderListView.swift` — Add context menu items ("Export to PDF", "Open Export View")
- `project.yml` — Add new .swift files to xcodegen config (handled by xcodegen generate)

**No changes to:**
- Existing form views, ViewModels, Models, Services, or Sync pipeline
- The Export tab is purely additive

### 5. Reuse of Existing Code

- `FieldMappings.leadFields(from:)` — generates the exact CRM field names/values for lead copy
- `FieldMappings.dealName(from:)` — generates deal name string
- `FieldMappings.estimateLineItems(from:)` — generates line items for estimate copy
- `FieldMappings.estimateNotes(from:defaults:)` — generates Michelle's info block
- `OrderFormData` and all nested structs — data source for all copy/export fields
- `ImageRenderer` pattern from `SignatureCaptureView` — adapted for PDF generation

## Verification

1. Build macOS target: `xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrder_macOS -destination 'platform=macOS' build`
2. Open an existing order → navigate to Export tab → verify all fields populated correctly
3. Click individual Copy buttons → paste into TextEdit → verify correct values
4. Click "Copy All Lead Fields" → verify formatted block
5. Click "Copy All Line Items" → verify formatted table
6. Click "Copy Notes Block" → verify Michelle's info
7. Click "Generate PDF" → verify save dialog → open PDF → verify all sections
8. Right-click order in list → "Export to PDF" → verify PDF generated
9. Test with an order that has minimal data (only required fields) → verify graceful handling of nil/empty optionals

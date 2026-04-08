# CLAUDE.md

## Project Overview

AndauOrder is a SwiftUI multiplatform app (iOS 26 + macOS 26) that digitizes the Andau Medical dental loupes order form and automates data entry into Zoho CRM + Zoho Books. Built for Michelle Fontaine, a territory manager based in Quebec, Canada. Single-user app designed for iPad use at dental conferences and macOS for office work.

## Build Commands

```bash
# Generate project (REQUIRED after adding/removing .swift files)
xcodegen generate

# Build macOS
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrder_macOS -destination 'platform=macOS' build

# Build iOS
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrder_iOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrderTests_macOS -destination 'platform=macOS' test
```

## Tech Stack

- Swift 6.0 with strict concurrency
- SwiftUI (iOS 26 / macOS 26)
- SwiftData for persistence
- xcodegen (project.yml -> .xcodeproj)
- Zoho CRM v8 API + Zoho Books v3 API
- Canada region: accounts.zohocloud.ca, www.zohoapis.ca (production), sandbox.zohoapis.ca (sandbox)

## Key Architecture Patterns

**Observation framework:** All ViewModels use `@Observable` (not ObservableObject). Views use `@State` for ownership and `@Bindable` for bindings from observed objects.

**SwiftData models:** OrderRecord, SyncQueueEntry, CachedZohoItem, PriceCatalogEntry. Enums are stored as raw strings (e.g., `syncStatusRaw`), with computed properties for type-safe access (`syncStatus`). SwiftData `#Predicate` closures can ONLY reference stored properties -- never computed ones.

**Protocol-based services:** ZohoAuthServiceProtocol, HTTPClientProtocol, ZohoCRMServiceProtocol, ZohoBooksServiceProtocol. Enables mock testing. Implementations use `@unchecked Sendable` with internal synchronization.

**Sync pipeline:** 8-step queue in SyncEngine, each step is a SyncQueueEntry. Steps execute sequentially. Failure stops the pipeline (no skipping). Idempotency guards on createLead and createBooksCustomer. Max 5 auto-retries per step.

**Offline-first:** Orders save to SwiftData immediately. Sync queue processes when online. SyncCoordinator monitors connectivity via NetworkMonitor (NWPathMonitor).

**Auto-save:** 500ms debounced via Task.sleep in OrderFormContainerView.

## File Map

```
project.yml                        # xcodegen config -- regenerate .xcodeproj from this

AndauOrder/App/
  AndauOrderApp.swift              # @main entry, SwiftData container, SyncCoordinator environment
  Constants.swift                  # AppConstants (tax rate, auto-save interval)

AndauOrder/Models/Domain/
  OrderFormData.swift              # Main form struct (Codable, Sendable) -- all order fields
  Customer.swift                   # Customer + Address structs
  StudentInfo.swift                # Student verification data
  LoupeSelection.swift             # LoupeStyle, FrameModel, FrameSize enums + selection
  HeadlightSelection.swift         # HeadlightType enum + selection with accessories
  PPESelection.swift               # Side shield + laser protection toggles
  AdapterSelection.swift           # AdapterType enum + selection
  Customization.swift              # Engraving, working distance, case number
  Prescription.swift               # Internal/external correction types, eye exam booleans
  OrderPricing.swift               # 9 line items (Decimal), tax, subtotal, total
  ReviewChecklist.swift            # 14 toggle items with KeyPath-based binding

AndauOrder/Models/Persistence/
  OrderRecord.swift                # @Model -- stores OrderFormData as JSON, Zoho IDs, SyncStatus
  SyncQueueEntry.swift             # @Model -- individual sync step (SyncStepType, SyncStepStatus)
  PriceCatalog.swift               # @Model -- product prices + PriceCatalogKey/Lookup helpers
  CachedZohoItem.swift             # @Model -- cached Zoho product items

AndauOrder/Models/API/CRM/
  CRMResponseDTO.swift             # Generic CRMResponse<T>, CRMRecord<T>, CRMRecordID
  BlueprintDTO.swift               # BlueprintResponse, BlueprintTransition
  ConvertLeadDTO.swift             # ConvertLeadRequest/Response for lead conversion

AndauOrder/Models/API/Books/
  BooksCustomerDTO.swift           # BooksContactRequest, BooksAddress, BooksContactResponse
  EstimateDTO.swift                # BooksEstimateRequest, BooksLineItem, BooksEstimateResponse

AndauOrder/ViewModels/
  OrderFormViewModel.swift         # @Observable -- form state, save, markForSync, tab navigation, validation
  OrderListViewModel.swift         # @Observable -- search, selection, create/delete orders

AndauOrder/Views/Root/
  ContentView.swift                # NavigationSplitView -- sidebar + detail, settings sheet, debug sample order

AndauOrder/Views/OrderForm/
  OrderFormContainerView.swift     # Tab bar + tab content switching, auto-save, network indicator
  CustomerInfoView.swift           # Customer details form, address, student info, photo picker
  ProductSelectionView.swift       # Loupe/headlight/PPE/adapter pickers
  CustomizationView.swift          # Engraving, Rx, working distance
  PricingView.swift                # Line item pricing with CurrencyField
  ReviewChecklistView.swift        # 14-item checklist, referrals, payment
  ReviewSubmitView.swift           # Summary, signature capture, submit button

AndauOrder/Views/OrderList/
  OrderListView.swift              # Searchable order list with context menus
  OrderRowView.swift               # Order row with name, products, sync status

AndauOrder/Views/Settings/
  SettingsView.swift               # Zoho credentials, environment picker, test connection, Michelle info
  PriceCatalogView.swift           # Price catalog editor grouped by category
  SyncStatusView.swift             # Sync queue visualization with per-step status

AndauOrder/Views/Components/
  SyncStatusBadge.swift            # Colored capsule badge for SyncStatus
  CurrencyField.swift              # Decimal + Double currency input fields
  SignatureCaptureView.swift       # Canvas drawing -> PNG export

AndauOrder/Services/Auth/
  ZohoEnvironment.swift            # sandbox/production URL resolution (.zohocloud.ca)
  TokenStore.swift                 # Keychain wrapper (Security framework)
  ZohoAuthService.swift            # Token refresh with 5-min expiry buffer

AndauOrder/Services/Networking/
  APIError.swift                   # Typed error enum (unauthorized, rateLimited, zohoError, etc.)
  HTTPClient.swift                 # Authenticated HTTP client, auto-retry on 401

AndauOrder/Services/CRM/
  ZohoCRMService.swift             # Lead CRUD, blueprint transitions, lead conversion, deal updates

AndauOrder/Services/Books/
  ZohoBooksService.swift           # Customer search/create, estimate creation

AndauOrder/Services/Sync/
  SyncEngine.swift                 # 8-step sync queue processor (@Observable, @MainActor methods)
  SyncCoordinator.swift            # Network monitor + sync trigger
  FieldMappings.swift              # OrderFormData -> Zoho CRM/Books field mapping

AndauOrder/Utilities/
  NetworkMonitor.swift             # NWPathMonitor wrapper (@Observable, @unchecked Sendable)
  PricingCalculator.swift          # Static pricing math helpers
  SampleOrderFactory.swift         # DEBUG-only fully-populated test order

AndauOrderTests/Utilities/
  PricingCalculatorTests.swift     # 5 tests using Swift Testing (@Suite/@Test)
```

## Zoho API Details

**Region:** Canada -- `accounts.zohocloud.ca`, `www.zohoapis.ca` (production), `sandbox.zohoapis.ca` (sandbox)

**Auth:** Self Client refresh token flow. No OAuth UI. Token stored in Keychain, credentials in UserDefaults (@AppStorage keys: zohoClientID, zohoClientSecret, zohoRefreshToken, zohoOrgID, zohoEnvironment).

**CRM (v8):** Create leads, get/execute blueprint transitions, convert leads to contact+account+deal, update deals. Response pattern: `{ "data": [{ "code": "SUCCESS", "details": { "id": "..." } }] }`.

**Books (v3):** Search/create customers, create estimates with line items. All calls need `?organization_id={orgID}`. Response pattern: `{ "code": 0, "message": "...", "contact": {...} }`.

**Required scopes:**
```
ZohoCRM.modules.ALL,ZohoBooks.estimates.CREATE,ZohoBooks.contacts.CREATE,ZohoBooks.contacts.READ,ZohoBooks.settings.READ,ZohoBooks.items.READ
```

## Sync Pipeline Steps (SyncStepType enum)

1. `createLead` -- POST /Leads
2. `transitionLeadToTMReachedOut` -- PUT blueprint on lead
3. `transitionLeadToCustomerEngaged` -- PUT blueprint on lead
4. `fetchCreatedRecords` -- POST /Leads/{id}/actions/convert -> gets contactID, accountID, dealID
5. `transitionDealToQualified` -- PUT blueprint on deal
6. `updateDealDetails` -- PUT /Deals with stage, date, amount
7. `createBooksCustomer` -- POST /contacts (checks for existing by email first)
8. `createEstimate` -- POST /estimates with line items from FieldMappings

## Important Conventions

- Run `xcodegen generate` after adding or removing any .swift files
- All currency values use `Decimal` (not Double) for precision
- Quebec tax rate: 14.975% (GST 5% + QST 9.975%)
- Territory manager is always "Michelle Fontaine"
- Default country is "Canada"
- SwiftData enum storage: use `fooRaw: String` stored property + `foo: FooEnum` computed property
- SwiftData predicates: MUST use stored properties (e.g., `syncStatusRaw`), never computed properties
- Services read from `UserDefaults.standard` (not @AppStorage, which is view-only)
- `@unchecked Sendable` on classes with internal lock-based synchronization
- Form views use `@Binding var formData: OrderFormData`; ReviewSubmitView uses `@Bindable var viewModel`
- DEBUG code wrapped in `#if DEBUG` / `#endif`

## Known Limitations / Future Work

- Blueprint transition names are searched by substring ("TM Reached Out", "Customer Engaged", "Qualified") -- may need adjustment if CRM blueprint names differ
- CRM custom fields (Specialty, Currently_Using) not yet mapped -- need to inspect actual CRM field names via GET /settings/fields?module=Leads
- No unit tests yet for services (auth, CRM, Books, sync engine) -- would need URLProtocol mocking
- No TestFlight deployment yet -- needs Development Team set in Xcode signing
- Liquid Glass styling (iOS 26) not yet applied beyond system defaults
- CachedZohoItem model exists but is not used yet (placeholder for item catalog sync)

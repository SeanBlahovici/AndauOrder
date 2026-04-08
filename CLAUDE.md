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
- Canada region: accounts.zoho.com, www.zohoapis.com (production), sandbox.zohoapis.com (sandbox)

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
  ZohoEnvironment.swift            # sandbox/production URL resolution (.zoho.com)
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

## Domain Model Details

**OrderFormData** is the central form struct (Codable, Sendable, Equatable). It contains:
- `customer: Customer` -- firstName, lastName, email, phone, clinicName, billingAddress, shippingAddress, shippingSameAsBilling, specialty, currentlyUsing, isStudent, studentInfo
- `loupeSelection: LoupeSelection` -- style (LoupeStyle?), frame (FrameModel?), size (FrameSize?), color (String?). 14 loupe styles across 4 categories: ErgoV, Ergo (3.0x-10x), Galilean (2.5x-3.2x), Prismatic (4.0x-5.5x). 7 frame models (Indie, Blues, Soul, Jazz, Sport, Progear, Bolle) with dynamic colors/sizes.
- `headlightSelection: HeadlightSelection` -- type (HeadlightType?), extraBattery, orchidCord3_5ft, orchidCord5ft. 9 headlight types across 4 categories.
- `ppeSelection: PPESelection` -- sideShield, laserProtection booleans
- `adapterSelection: AdapterSelection` -- type (AdapterType?), competitorAdapterDetail. 4 adapter types.
- `prescription: Prescription` -- internalType (CorrectionType?), externalType (ExternalCorrectionType?), externalLensNear/Middle/Far booleans, currentEyeExam, doWeHaveCopy, contacts, readers
- `pricing: OrderPricing` -- 9 Decimal line items (loupes, internalCorrection, externalCorrection, light, flamingo, laserInserts, adapters, shipping, lessPromotion) + taxRate, computed subtotal/tax/total
- `reviewChecklist: ReviewChecklist` -- 14 boolean toggles with KeyPath-based allItems array
- Payment: nameOnCard, referralSources (Set<ReferralSource>), isPaid, paymentType, signatureImageData

**Address** struct: street, street2, city, stateProvince, postalZipCode, country (default "Canada")

**OrderRecord** (@Model): stores OrderFormData as JSON in orderDataJSON, Zoho IDs (zohoLeadID, zohoContactID, zohoAccountID, zohoDealID, zohoEstimateID, zohoBooksCustID), SyncStatus via syncStatusRaw.

**SyncQueueEntry** (@Model): orderID (UUID), stepType/status via raw strings, stepOrder, zohoRecordID, attemptCount, lastError.

## Authentication Layer

**ZohoEnvironment** (enum): Resolves base URLs. Both sandbox and production use `accounts.zoho.com` for auth. CRM base differs: `sandbox.zohoapis.com/crm/v8` vs `www.zohoapis.com/crm/v8`. Same pattern for Books (`/books/v3`).

**TokenStore** (struct, Sendable): Keychain wrapper using Security framework (SecItemAdd/CopyMatching/Update/Delete). Service name `com.andaumedical.order.zoho`. Stores accessToken, accessTokenExpiry (as epoch TimeInterval), refreshToken. Uses `nonmutating set` with static methods so the struct itself is Sendable.

**ZohoAuthService** (class, @unchecked Sendable): Implements ZohoAuthServiceProtocol. Uses NSLock for thread safety. `validAccessToken()` checks cached token with 5-minute expiry buffer, then calls refresh endpoint if needed. Refresh is a POST to `{accountsURL}/oauth/v2/token` with form-urlencoded body (refresh_token, client_id, client_secret, grant_type). Reads credentials from UserDefaults.standard. The `storeToken()` helper is a synchronous method (not async) to avoid NSLock-in-async-context issues in Swift 6.

## HTTP Client

**HTTPClient** (class, Sendable): Implements HTTPClientProtocol. Takes ZohoAuthServiceProtocol dependency. Sets `Authorization: Zoho-oauthtoken {token}` header on all requests. `Content-Type: application/json` for POST/PUT. Auto-retries once on 401 (token may have expired mid-request). Maps HTTP status codes to APIError: 401->unauthorized, 404->notFound, 429->rateLimited, 5xx->serverError. Catches URLError.notConnectedToInternet as networkUnavailable.

**Key design:** Protocol extension provides default parameter values (body=nil, queryParams=[:]) so callers can omit them.

## CRM Service

**ZohoCRMService** (class, @unchecked Sendable): Takes HTTPClientProtocol + UserDefaults. Resolves CRM base URL from `zohoEnvironment` UserDefaults key.

Methods:
- `createLead(from:)` -- POST /Leads with field mappings from FieldMappings.leadFields(). Returns leadID from response.
- `getBlueprint(module:recordID:)` -- GET /{module}/{id}/actions/blueprint. Returns [BlueprintTransition].
- `executeTransition(module:recordID:transitionID:data:)` -- PUT /{module}/{id}/actions/blueprint. Uses RawJSON wrapper to bridge [String: Any] -> Encodable via JSONSerialization + recursive JSONValue enum.
- `convertLead(leadID:order:)` -- POST /Leads/{id}/actions/convert with ConvertLeadRequest body. Returns (contactID, accountID, dealID) tuple.
- `updateDeal(dealID:stage:closingDate:amount:)` -- PUT /Deals with DealUpdateRecord body.

**RawJSON bridging pattern:** Since `[String: Any]` is not Encodable, the CRM service serializes it to Data via JSONSerialization, then wraps it in a RawJSON struct whose `encode(to:)` reconstructs the JSON through a recursive JSONValue enum (string/number/bool/null/array/object) with DynamicCodingKey. This avoids double-encoding when HTTPClient calls JSONEncoder.encode(body).

## Books Service

**ZohoBooksService** (class, @unchecked Sendable): Takes HTTPClientProtocol + UserDefaults. All calls include `organization_id` query param from `zohoOrgID` UserDefaults key.

Methods:
- `searchCustomer(email:)` -- GET /contacts?email={email}. Returns first BooksContact or nil. Uses local BooksContactListResponse struct.
- `createCustomer(from:)` -- POST /contacts with BooksContactRequest. Maps Address -> BooksAddress via helper.
- `createEstimate(customerID:order:)` -- POST /estimates with BooksEstimateRequest. Line items and notes built by FieldMappings.

## Field Mappings

**FieldMappings** (enum, namespace):
- `leadFields(from:)` -- Maps customer data to CRM Lead fields: Last_Name, First_Name, Email, Phone, Company, Street, City, State, Zip_Code, Country.
- `dealName(from:)` -- "{fullName} - {loupeDisplayDescription}"
- `estimateLineItems(from:)` -- Builds [BooksLineItem] from: loupes (style+frame+size+color), internal/external corrections, headlight (+accessories in description), flamingo, laser inserts, adapters, shipping, promotion discount.
- `estimateNotes(from:defaults:)` -- "Contact: Michelle Fontaine\nEmail: ...\nPhone: ..." from UserDefaults + order notes.

## Sync Engine

**SyncEngine** (@Observable, @unchecked Sendable): Creates its own ZohoAuthService -> HTTPClient -> CRMService/BooksService chain in init().

**enqueueSync(for:modelContext:)**: Deletes any existing SyncQueueEntry items for the order, creates 8 new entries (stepOrder 0-7), sets order status to .syncing.

**processQueue(modelContext:)** (@MainActor): Fetches all orders with syncStatusRaw in [pendingSync, partiallySynced, failed, syncing]. For each, calls processOrder().

**processOrder()** (@MainActor): Fetches SyncQueueEntry items sorted by stepOrder. Skips .completed/.skipped. For first .pending/.failed entry: sets .inProgress, executes step, on success sets .completed + stores zohoRecordID + updates OrderRecord Zoho IDs, on failure sets .failed + increments attemptCount + stores lastError. Stops on first failure. After processing, updates order sync status (all completed -> .synced, any failed -> .failed, some completed -> .partiallySynced).

**executeStep()** (@MainActor): Switch on stepType, calls appropriate service. Idempotency: skips createLead if order.zohoLeadID already set, skips createBooksCustomer if order.zohoBooksCustID already set. Blueprint transitions are looked up by name substring ("TM Reached Out", "Customer Engaged", "Qualified").

**retryFailed(orderID:modelContext:)**: Resets all failed entries for the order to .pending with attemptCount=0, then calls processQueue.

**Max retries:** If attemptCount >= 5, stops auto-retrying (requires manual retry from SyncStatusView).

## SyncCoordinator

**SyncCoordinator** (@Observable, @unchecked Sendable): Owns SyncEngine and NetworkMonitor. Provides `isConnected` computed property. `syncNow(modelContext:)` guards against duplicate processing and offline state, then delegates to syncEngine.processQueue().

Injected into SwiftUI environment from AndauOrderApp via `.environment(syncCoordinator)`.

## View Layer Details

**ContentView**: NavigationSplitView with OrderListView sidebar + OrderFormContainerView detail. Settings sheet. DEBUG-only "Sample Order" flask button.

**OrderFormContainerView**: Scrollable horizontal tab bar (6 capsule buttons). Switches tab content. Auto-save onChange of formData with 500ms debounce. Network indicator (wifi/wifi.slash) in toolbar. Optional `@Environment(SyncCoordinator.self)` for network status.

**ReviewSubmitView**: Uses `@Bindable var viewModel` (not `let`) to support SignatureCaptureView binding. Submit button calls `viewModel.markForSync(syncCoordinator:)` then `syncCoordinator.syncNow()`.

**OrderFormViewModel**: `markForSync(syncCoordinator:)` saves, sets pendingSync, calls syncCoordinator.syncEngine.enqueueSync(), saves context.

**SettingsView**: AppStorage fields for zohoEnvironment, zohoClientID, zohoClientSecret, zohoRefreshToken, zohoOrgID, michelleEmail, michellePhone. Test Connection button calls ZohoAuthService().validAccessToken(). Link to SyncStatusView and PriceCatalogView.

**SyncStatusView**: Lists non-draft orders with SyncStatusBadge, expandable sync step entries, retry buttons. "Sync All Now" button.

**SignatureCaptureView**: Canvas + DragGesture for drawing. Renders to PNG via ImageRenderer. Platform-specific: NSImage on macOS, UIImage on iOS.

**CustomerInfoView**: PhotosPicker for student ID photo. Platform-specific imageFromData helper.

## Zoho API Details

**Region:** Canada -- `accounts.zoho.com`, `www.zohoapis.com` (production), `sandbox.zohoapis.com` (sandbox)

**Auth:** Self Client refresh token flow. No OAuth UI. Token stored in Keychain, credentials in UserDefaults (@AppStorage keys: zohoClientID, zohoClientSecret, zohoRefreshToken, zohoOrgID, zohoEnvironment).

**CRM (v8):** Create leads, get/execute blueprint transitions, convert leads to contact+account+deal, update deals. Response pattern: `{ "data": [{ "code": "SUCCESS", "details": { "id": "..." } }] }`.

**Books (v3):** Search/create customers, create estimates with line items. All calls need `?organization_id={orgID}`. Response pattern: `{ "code": 0, "message": "...", "contact": {...} }`.

**Required scopes:**
```
ZohoCRM.modules.ALL,ZohoBooks.estimates.CREATE,ZohoBooks.contacts.CREATE,ZohoBooks.contacts.READ,ZohoBooks.settings.READ,ZohoBooks.items.READ
```

### CRM Endpoints (base: https://www.zohoapis.com/crm/v8)
```
POST   /Leads                                    -- Create lead
GET    /Leads/{id}/actions/blueprint              -- Get available transitions
PUT    /Leads/{id}/actions/blueprint              -- Execute transition
POST   /Leads/{id}/actions/convert                -- Convert to contact+account+deal
PUT    /Deals                                     -- Update deal fields
GET    /settings/fields?module=Leads              -- Discover custom field names
```

### Books Endpoints (base: https://www.zohoapis.com/books/v3, always add ?organization_id={orgID})
```
GET    /contacts?email={email}                    -- Search customer
POST   /contacts                                  -- Create customer
POST   /estimates                                 -- Create estimate with line items
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
- Dates formatted as "yyyy-MM-dd" with POSIX locale and UTC timezone for Zoho APIs
- CRM requests use `{ "data": [...] }` wrapper pattern (CRMDataWrapper<T>)
- Books requests use direct body (no wrapper)
- [String: Any] -> Encodable bridging uses RawJSON/JSONValue/DynamicCodingKey pattern in ZohoCRMService
- SyncEngine methods that touch ModelContext are @MainActor annotated
- ImageRenderer for PNG export uses platform-specific code (#if os(macOS) for NSImage, #else for UIImage)

## Known Limitations / Future Work

- Blueprint transition names are searched by substring ("TM Reached Out", "Customer Engaged", "Qualified") -- may need adjustment if CRM blueprint names differ
- CRM custom fields (Specialty, Currently_Using) not yet mapped -- need to inspect actual CRM field names via GET /settings/fields?module=Leads
- No unit tests yet for services (auth, CRM, Books, sync engine) -- would need URLProtocol mocking
- No TestFlight deployment yet -- needs Development Team set in Xcode signing
- Liquid Glass styling (iOS 26) not yet applied beyond system defaults
- CachedZohoItem model exists but is not used yet (placeholder for item catalog sync)
- Books contact search response may vary -- BooksContactListResponse assumes `{ code, contacts }` wrapper
- No UI alerts/toasts for sync success/failure yet -- only visible via SyncStatusView
- Auto-sync on connectivity restore is not automatic -- requires manual "Sync All Now" or submitting an order

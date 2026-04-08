# AndauOrder

A SwiftUI multiplatform app (iOS 26 + macOS 26) that digitizes the Andau Medical dental loupes order form and automates data entry into Zoho CRM and Zoho Books. Built for Michelle Fontaine, territory manager for Quebec, Canada.

## Overview

AndauOrder replaces the 2-page Andau Medical paper order form with a native SwiftUI app. Sales data entered during dental conferences and client visits flows directly into Zoho CRM (leads, deals, contacts) and Zoho Books (customers, estimates), eliminating manual re-entry.

The app is built for a single user -- Michelle -- primarily for use on her iPad in the field, with a macOS version available for office use.

## Features

- **6-tab order form** -- Customer, Products, Customization, Pricing, Review, Submit
- **14 product configurations** -- loupes, headlights, PPE, adapters
- **Auto-pricing** from a configurable price catalog
- **Quebec tax calculation** -- GST 5% + QST 9.975% = 14.975%
- **Signature capture** -- Canvas-based drawing surface, works with Apple Pencil
- **Student ID photo capture** via PhotosPicker
- **Offline-capable** with sync queue (8-step pipeline)
- **Auto-save** with 500ms debounce
- **Network status indicator**

## Requirements

- Xcode 26.0+ (beta)
- iOS 26.0+ / macOS 26.0+
- Swift 6.0
- xcodegen (`brew install xcodegen`)

## Build & Run

```bash
# Generate Xcode project
xcodegen generate

# Build macOS
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrder_macOS -destination 'platform=macOS' build

# Build iOS (simulator)
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrder_iOS -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrderTests_macOS -destination 'platform=macOS' test
```

## Zoho Setup

### Prerequisites

- A Zoho account (zoho.com) with CRM and Books modules
- A Self Client registered at api-console.zoho.com
- Andau Medical uses the **Canada region** -- all API URLs use `.zohocloud.ca` / `.zohoapis.ca`

### Step 1: Create Self Client

1. Go to api-console.zoho.com
2. Click "Add Client" then "Self Client"
3. Note the Client ID and Client Secret

### Step 2: Generate Grant Code

1. In the Self Client page, enter these scopes:
   ```
   ZohoCRM.modules.ALL,ZohoBooks.estimates.CREATE,ZohoBooks.contacts.CREATE,ZohoBooks.contacts.READ,ZohoBooks.settings.READ,ZohoBooks.items.READ
   ```
2. Set scope duration (prefer long-lived)
3. Click "Create" and copy the grant code

### Step 3: Exchange for Refresh Token

```bash
curl -X POST "https://accounts.zohocloud.ca/oauth/v2/token" \
  -d "grant_type=authorization_code" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code=YOUR_GRANT_CODE"
```

Save the `refresh_token` from the response. This is long-lived and will not expire unless revoked.

### Step 4: Configure the App

1. Open AndauOrder and navigate to Settings
2. Set Environment to **Sandbox** (for testing)
3. Enter Client ID, Client Secret, Refresh Token, and Organization ID (found in Books under Settings > Organization)
4. Enter Michelle's email and phone (auto-filled into estimates)
5. Click **Test Connection** to verify

### Step 5: Sandbox Testing

1. Use the "flask" button (DEBUG builds only) to create a sample order
2. Open the sample order, go to the Submit tab, and click "Submit to Zoho"
3. Check Settings > Sync Status to monitor the 8-step pipeline
4. Verify in Zoho CRM Sandbox: lead created, transitions executed, contact/account/deal created
5. Verify in Zoho Books Sandbox: customer and estimate created

### Step 6: Switch to Production

1. Generate a new grant code with production scopes
2. Exchange for a production refresh token
3. In Settings, switch Environment to **Production**
4. Enter production credentials
5. Test with a real order, then delete the test data from Zoho

## Testing

### Debug Sample Order

In DEBUG builds, the toolbar includes a flask icon that creates a fully-populated test order. The sample order uses a Quebec dentist ("Jean-Pierre Tremblay") with Ergo 4.0x loupes, Orchid headlight, and all fields filled. This allows immediate testing of the full sync pipeline without manual data entry.

### Sync Pipeline Steps

The sync engine processes 8 steps in order:

1. **Create Lead** -- POST to CRM /Leads
2. **TM Reached Out** -- Blueprint transition on lead
3. **Customer Engaged** -- Blueprint transition on lead
4. **Convert Lead** -- Creates Contact, Account, and Deal
5. **Qualify Deal** -- Blueprint transition on deal
6. **Update Deal** -- Sets closing date and amount
7. **Create Books Customer** -- POST to Books /contacts (checks for duplicates first)
8. **Create Estimate** -- POST to Books /estimates with line items

If a step fails, the pipeline stops and can be retried from Settings > Sync Status.

### Unit Tests

```bash
xcodebuild -project AndauOrder.xcodeproj -scheme AndauOrderTests_macOS -destination 'platform=macOS' test
```

Tests cover: PricingCalculator (subtotal, tax, total, negative subtotal, promotions).

## Project Structure

```
AndauOrder/
├── App/                          # App entry point, constants
├── Models/
│   ├── Domain/                   # OrderFormData, Customer, products, pricing
│   ├── Persistence/              # SwiftData models (OrderRecord, SyncQueueEntry, etc.)
│   └── API/                      # Zoho API DTOs
│       ├── CRM/                  # CRM response/request types
│       └── Books/                # Books response/request types
├── ViewModels/                   # OrderFormViewModel, OrderListViewModel
├── Views/
│   ├── Root/                     # ContentView (NavigationSplitView)
│   ├── OrderForm/                # 6 tab views + container
│   ├── OrderList/                # Sidebar list + row
│   ├── Settings/                 # Settings, PriceCatalog, SyncStatus
│   └── Components/               # Reusable views (SyncStatusBadge, CurrencyField, SignatureCapture)
├── Services/
│   ├── Auth/                     # ZohoEnvironment, TokenStore (Keychain), ZohoAuthService
│   ├── Networking/               # HTTPClient, APIError
│   ├── CRM/                      # ZohoCRMService
│   ├── Books/                    # ZohoBooksService
│   └── Sync/                     # SyncEngine, SyncCoordinator, FieldMappings
├── Utilities/                    # NetworkMonitor, PricingCalculator, SampleOrderFactory
└── Resources/                    # Assets.xcassets
```

## Architecture Notes

- **SwiftData** for persistence (OrderRecord, SyncQueueEntry, CachedZohoItem, PriceCatalogEntry)
- **@Observable** pattern for ViewModels (not ObservableObject)
- **Swift 6.0 strict concurrency** -- services use `@unchecked Sendable` where internal synchronization is guaranteed
- **Protocol-based services** (ZohoAuthServiceProtocol, HTTPClientProtocol, etc.) for testability
- **Offline-first** -- orders save locally, sync queue processes when online
- **xcodegen** manages the Xcode project from `project.yml` -- run `xcodegen generate` after adding or removing files

## License

Private -- Andau Medical internal use only.

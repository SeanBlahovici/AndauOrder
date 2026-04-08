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

- A Zoho account at zoho.com with CRM and Books modules active
- Andau Medical uses the **Canada region** -- all API URLs use `.zoho.com` / `.zohoapis.com`

### Step 1: Enable CRM Sandbox (for safe testing)

1. Log into Zoho CRM at crm.zoho.com
2. Go to **Setup** (gear icon, top right) > **Data Administration** > **Sandbox**
3. Click **Create Sandbox** -- give it a name like "AndauOrder Testing"
4. Wait for it to provision (takes a minute)
5. This creates a copy of your CRM where you can test without affecting real data

### Step 2: Find Your Organization ID (for Zoho Books)

1. Log into Zoho Books at books.zoho.com
2. Go to **Settings** (gear icon) > **Organization Profile**
3. Your **Organization ID** is displayed at the top -- it's a numeric string like `12345678`
4. Copy this -- you'll need it for the app

### Step 3: Create a Self Client (API credentials)

1. Go to [api-console.zoho.com](https://api-console.zoho.com)
2. Sign in with the same Zoho account
3. Click **Add Client** > **Self Client**
4. Give it a name like "AndauOrder"
5. You'll see your **Client ID** and **Client Secret** -- copy both

### Step 4: Generate a Grant Code

1. Still in the Self Client page at api-console.zoho.com, click **Generate Code**
2. Paste these scopes:
   ```
   ZohoCRM.modules.ALL,ZohoBooks.estimates.CREATE,ZohoBooks.contacts.CREATE,ZohoBooks.contacts.READ,ZohoBooks.settings.READ,ZohoBooks.items.READ
   ```
3. For **Time Duration**, select the longest option available (10 minutes is typical -- this is just how long you have to exchange it, not how long access lasts)
4. For **Scope Description**, enter anything (e.g. "AndauOrder app")
5. Click **Create**
6. Copy the **grant code** that appears -- you have ~10 minutes to use it

### Step 5: Exchange Grant Code for a Refresh Token

Run this in Terminal, replacing the placeholders:

```bash
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "grant_type=authorization_code" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code=YOUR_GRANT_CODE"
```

You'll get a JSON response like:
```json
{
  "access_token": "1000.xxxx...",
  "refresh_token": "1000.yyyy...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

**Save the `refresh_token`**. This is long-lived and won't expire unless you revoke it. The app uses it to automatically get fresh access tokens.

If you get an error like `"invalid_code"`, the grant code expired -- go back to Step 4 and generate a new one.

### Step 6: Configure the App

1. Open AndauOrder and go to **Settings** (gear icon in sidebar)
2. Set Environment to **Sandbox**
3. Enter:
   - **Client ID** -- from Step 3
   - **Client Secret** -- from Step 3
   - **Refresh Token** -- from Step 5
   - **Organization ID** -- from Step 2
4. Enter Michelle's email and phone (auto-filled into Zoho Books estimates)
5. Click **Test Connection** -- you should see a green checkmark

If Test Connection fails:
- Double-check all 4 credentials are pasted correctly (no extra spaces)
- Make sure you're using the Canada region account (zoho.com)
- The grant code may have expired -- regenerate it (Step 4) and re-exchange (Step 5)

### Step 7: Sandbox Testing

1. Use the **flask button** (DEBUG builds) to create a sample order
2. Open the sample order > go to **Submit** tab > click **Submit to Zoho**
3. Go to **Settings** > **Sync Status** to watch the 8 steps process
4. Verify in Zoho CRM Sandbox: lead appears, transitions complete, contact/account/deal created
5. Verify in Zoho Books: customer and estimate appear with correct line items

### Step 8: Switch to Production

When sandbox testing passes:

1. Generate a **new grant code** (Step 4 -- same scopes)
2. Exchange for a **new refresh token** (Step 5)
3. In the app, switch Environment to **Production**
4. Enter the new Refresh Token (Client ID, Secret, and Org ID stay the same)
5. Click **Test Connection** to verify
6. Create a real test order and submit -- verify it appears in production CRM/Books
7. Delete the test data from Zoho manually if needed

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

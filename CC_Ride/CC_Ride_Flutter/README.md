# CC Ride — Flutter App

CC Ride is a corporate ride-hailing platform that connects employees with reliable transportation. The Flutter app serves the passenger/employee side: booking rides, posting trip schedules, managing wallets, and accessing corporate features such as department-based travel approvals and budget controls.

## Project Structure

```
lib/
├── app/
│   ├── data/               # API config, local storage, models
│   ├── modules/
│   │   ├── controllers/    # GetX controllers (business logic & UI state)
│   │   └── view/           # Screen widgets
│   └── routes/             # App navigation (GetX routing)
├── language/               # i18n locale strings
├── theme/                  # Dark/light mode toggle (ThemeColores)
├── utils/
│   ├── cc_ds.dart          # Corporate Transit Excellence design system tokens
│   └── color.dart          # Legacy alias shim (re-exports cc_ds tokens)
└── widgets/                # Shared widgets (CCButton, custom fields, etc.)
```

## Design System

All UI tokens live in `lib/utils/cc_ds.dart` (Corporate Transit Excellence):

| Token | Value | Usage |
|---|---|---|
| `ccPrimary` | `#1565C0` | Buttons, active states, links |
| `ccNavyText` | `#0D2137` | Primary text |
| `ccBackground` | `#F6F9FE` | Scaffold backgrounds |
| `ccSurface` | `#FFFFFF` | Cards, bottom sheets, inputs |
| `ccIceBlue` | `#E8F1FF` | Chips, avatar fills, highlights |
| `ccInputBorder` | `#DCE8F5` | Input and divider borders |
| `ccSecondaryText` | `#5C7080` | Subtitles, hints, placeholders |
| `ccError` | `#BA1A1A` | Error states |
| `ccSuccess` | `#2A9C64` | Success states |

Font: **Inter** throughout. Weights: w700 (bold), w500 (medium), w400 (regular).

The `CCButton` widget (`lib/widgets/custom_widgets.dart`) is the standard primary action button — height 52, `ccPrimary` fill, `CCRadius.btn` (12px) corners.

## State Management

GetX (`get` package) — controllers extend `GetxController`, screens extend `GetView<Controller>` or use `GetBuilder`/`Obx` for reactive rebuilds.

## Key Features

- **Ride booking** — search, filter, and book posted trips
- **Trip posting** — schedule one-time or recurring trips with seat management
- **Corporate module** — employee management, department budgets, ride policies, approval queues
- **Wallet** — top-up via Stripe, Razorpay, Paystack, Flutterwave, or Paytm web-view flows
- **Real-time tracking** — Google Maps with polyline routes
- **Push notifications** — OneSignal
- **Dark mode** — system-aware toggle stored in GetStorage

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart 3.x
- Android Studio or VS Code with Flutter extension
- A Google Maps API key
- Firebase project (for Auth, Firestore, Cloud Messaging)

### Setup

1. Clone the repo and install dependencies:
   ```bash
   flutter pub get
   ```

2. Add your `google-services.json` (Android) to `android/app/` and `GoogleService-Info.plist` (iOS) to `ios/Runner/`.

3. Set the backend base URL in `lib/app/data/confing.dart`:
   ```dart
   static const String baseurl = 'https://api.ccride.ng/';
   ```

4. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

### Building a Release APK

```bash
flutter build apk --release
```

Requires a keystore configured in `android/key.properties`. See the [Flutter deployment guide](https://docs.flutter.dev/deployment/android) for signing setup.

## Backend

The Node.js/Express backend lives in `CC_Ride/backend/`. It exposes the REST API consumed by this app and the admin panel. See the backend `README` for setup instructions.

## Admin Panel

The React admin dashboard lives in `CC_Ride/admin/`. It connects to the same backend API.

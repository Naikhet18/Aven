# Deployment Guide

## Backend Setup (Supabase)
Migrations live in `supabase/migrations/`. Apply them to the linked project with the Supabase CLI:
```bash
supabase db push
```
This creates the schema and, critically, the `business_members`-scoped RLS policies -- do not skip
this on a fresh project, or every table is only protected by `using (true)` from the earlier
migrations (any authenticated user could read/write any business's data).

**Also required, and can't be scripted from a migration**: enable
*Authentication → Sign In / Providers → Anonymous Sign-Ins* in the Supabase dashboard. Staff devices
join a restaurant password-less via anonymous auth (see ARCHITECTURE.md); the "Join with a Code"
screen fails with an auth error until this is switched on.

## Environment Setup
Create a `.env` file in the root of the project (already gitignored):
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```
The app reads these via `--dart-define-from-file`, not a bundled runtime `.env` reader, and refuses
to start if they're missing -- there is no baked-in fallback project.

## Running locally
```bash
flutter run --dart-define-from-file=.env
```

## Android Deployment

### Prerequisites
- Flutter SDK installed
- Android Studio / Android SDK installed
- Keystore (for release signing, optional for internal testing)

### Build APK
```bash
flutter build apk --release --dart-define-from-file=.env
```
Output: `build/app/outputs/flutter-apk/app-release.apk`. Copy it to an Android device and install
("Install from unknown sources" must be enabled).

### Build App Bundle (AAB)
```bash
flutter build appbundle --release --dart-define-from-file=.env
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Permissions
The manifest declares Bluetooth (thermal printer) and Camera (QR table scanning) permissions. On
Android 12+, Bluetooth scanning/connecting is gated behind a runtime permission prompt (handled in
Settings > Printer via `permission_handler`); on older Android it also needs location permission,
which is already declared.

## iOS Deployment

### Prerequisites
- Mac with macOS, Xcode, an Apple Developer Account (Free or Paid), CocoaPods.

### Build for Physical iOS Device
1. `open ios/Runner.xcworkspace`
2. Runner project > **Signing & Capabilities** > enable "Automatically manage signing" > select your
   team.
3. Connect your iPhone, select it as the build target, press Play (or run
   `flutter run --dart-define-from-file=.env -d <device-id>` from the terminal).

*(First run from a free developer account: trust the developer certificate under Settings > General
> VPN & Device Management on the iPhone.)*

Info.plist already declares `NSBluetoothAlwaysUsageDescription`,
`NSBluetoothPeripheralUsageDescription`, and `NSCameraUsageDescription` for the printer/QR features.

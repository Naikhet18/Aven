# Deployment Guide

## Android Deployment

### Prerequisites
- Flutter SDK installed
- Android Studio / Android SDK installed
- Keystore (for release signing, optional for internal testing)

### Build APK
To build an APK that can be directly installed on an Android device:
```bash
flutter build apk --release
```
The output file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

Copy this file to your Android phone and install it. Ensure "Install from unknown sources" is enabled on the device.

### Build App Bundle (AAB)
To build an Android App Bundle (for Google Play):
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## iOS Deployment

### Prerequisites
- Mac with macOS
- Xcode installed
- Apple Developer Account (Free or Paid)
- CocoaPods installed (`sudo gem install cocoapods`)

### Build for Physical iOS Device
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In Xcode, select the `Runner` project in the left navigator.
3. Go to the **Signing & Capabilities** tab.
4. Check "Automatically manage signing".
5. Select your Apple Developer Team.
6. Connect your iPhone via USB.
7. Select your iPhone as the build target in the top bar.
8. Press `Cmd + R` or click the Play button to build and run.

*(Note: The first time you run an app from a free developer account on your iPhone, you must go to Settings > General > VPN & Device Management and trust the developer certificate.)*

## Environment Setup
Create a `.env` file in the root of the project:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

<div align="center">
  <img src="assets/images/logo_new.png" width="120" alt="Aven Logo" />
  <h1>Aven POS</h1>
  <p><strong>A restaurant POS that doesn't look like it was built in 2004.</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-A2A9B6?style=for-the-badge&logo=flutter" alt="Platforms" />
    <img src="https://img.shields.io/badge/Built_With-Flutter%20%7C%20Supabase-040404?style=for-the-badge" alt="Stack" />
    <img src="https://img.shields.io/github/stars/Naikhet18/Aven?style=for-the-badge&color=FFD700" alt="Stars" />
    <img src="https://img.shields.io/github/license/Naikhet18/Aven?style=for-the-badge&color=414141" alt="License" />
  </p>
</div>

---

<p align="center">
  <i>We made managing a restaurant less painful. Built with questionable amounts of caffeine, true OLED blacks, and an obsession with speed. Yes, it actually works.</i>
</p>

---

# 📲 Download the App

<p align="center">

### 🤖 Android

<a href="https://github.com/Naikhet18/Aven/releases/latest/download/Aven-v1.0.0-android.apk">
  <img src="https://img.shields.io/badge/Download%20APK-Android-brightgreen?style=for-the-badge&logo=android">
</a>

> **Android:** Download the APK and install it. *(If prompted, allow installation from unknown sources in your settings).*

### 🍎 iOS

<a href="#">
  <img src="https://img.shields.io/badge/Download%20on%20the-App%20Store-black?style=for-the-badge&logo=apple">
</a>

> **iOS:** `YOUR_APP_STORE_LINK` | `YOUR_TESTFLIGHT_LINK`
> *(iOS distribution coming soon. App Store/TestFlight placeholders to be updated upon release).*

</p>

---

## 🎥 See It In Action

<p align="center">
  <img src="assets/videos/aven_logo_reveal_final_20260909234039.gif" width="300" alt="Aven Startup Demo">
</p>

### 📱 The UI

| Dashboard | Billing | Kitchen (KDS) |
| :---: | :---: | :---: |
| <img src="assets/screenshots/dashboard.png" width="250" alt="Dashboard"> | <img src="assets/screenshots/billing.png" width="250" alt="Billing"> | <img src="assets/screenshots/kitchen.png" width="250" alt="Kitchen"> |
> *(Replace screenshot placeholders with actual images once uploaded to `assets/screenshots/`)*

---

## ✨ Why you'll probably love this

* ⚡ **Offline-First:** Because restaurant Wi-Fi is universally terrible. Driven by local `Drift` SQLite caching.
* 🌙 **True OLED Dark Mode:** Pitch-black `#040404` backgrounds and neon accents. Saves battery, saves your eyes, looks insanely premium.
* 📱 **QR Onboarding:** Staff can join your business by literally just scanning a QR code. No setup hell.
* 🖨️ **Bluetooth Thermal Printing:** It actually prints physical receipts to generic Bluetooth printers. Yes, it was painful to build. You're welcome.
* 🔥 **Real-time Sync:** Kitchen gets orders instantly. Waiters see status updates instantly. No more screaming across the room.

---

## 🛠️ Tech Stack

### 📱 Mobile Front-End
* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** Riverpod
* **Routing:** GoRouter
* **Local DB:** Drift (SQLite)

### ☁️ Backend & Cloud
* **BaaS:** [Supabase](https://supabase.com/)
* **Database:** PostgreSQL
* **Auth:** Supabase Auth (Multi-tenant business architecture)

### 🔌 Hardware Integrations
* **Printing:** `print_bluetooth_thermal`
* **Scanning:** `mobile_scanner` (Google MLKit)

---

## 🏗️ Architecture

```mermaid
graph TD
    A[Flutter Mobile App] --> B(Drift Local SQLite)
    A --> C{Supabase Realtime}
    C --> D[(PostgreSQL)]
    A -.-> E[Bluetooth Thermal Printer]
    A -.-> F[Camera Barcode Scanner]
    
    style A fill:#040404,stroke:#AvenGreen,stroke-width:2px,color:#fff
    style B fill:#1C1C1E,stroke:#414141,color:#fff
    style C fill:#3ECF8E,stroke:#fff,color:#000
    style D fill:#3ECF8E,stroke:#fff,color:#000
```

---

## 🚀 Getting Started

Getting this running locally is ridiculously easy.

### Requirements
* Flutter SDK (`>=3.13.2`)
* Dart SDK
* Supabase project (Free tier is perfectly fine)

### 1. Clone the repo
```bash
git clone https://github.com/Naikhet18/Aven.git
cd Aven
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Environment Variables
Create a `.env` file in the root directory. Do **not** commit this file.

```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

### 4. Run the app
```bash
# To run on a connected Android/iOS device
flutter run --dart-define-from-file=.env

# To build the production universal APK
flutter build apk --release --dart-define-from-file=.env
```

---

## ✅ First Release Checklist

### 🤖 Android
- [x] Production/release APK builds successfully
- [x] APK installs successfully on a real Android device
- [x] App name is correct
- [x] App icon is correct
- [x] Version name is correct
- [x] Version code is correct
- [ ] Release APK is attached to GitHub Release
- [ ] APK download button works from README
- [ ] GitHub Actions release workflow tested
- [ ] Signing configuration verified
- [ ] Google Play Store listing created
- [ ] Google Play Store screenshots uploaded
- [ ] Google Play Store description added
- [ ] Privacy policy URL added if required
- [ ] Content rating completed
- [ ] App published to Google Play

### 🍎 iOS
- [x] iOS build succeeds
- [x] Bundle identifier is correct
- [x] App name is correct
- [x] App icon is correct
- [x] Version/build number is correct
- [ ] Signing configuration verified
- [ ] App tested on a real iPhone
- [ ] TestFlight configured
- [ ] TestFlight invitation link added to README
- [ ] App Store listing created
- [ ] App Store screenshots uploaded
- [ ] App Store description added
- [ ] Privacy information completed
- [ ] App submitted for review
- [ ] App approved
- [ ] App Store download link added to README

### 🐙 GitHub
- [x] Repository description is polished
- [x] README is complete
- [ ] Screenshots added
- [x] Demo/GIF added if available
- [ ] GitHub topics/tags added
- [ ] LICENSE added
- [x] `.gitignore` verified
- [x] No API keys/secrets committed
- [x] GitHub Actions verified
- [ ] First GitHub Release created
- [ ] Release notes written
- [ ] APK attached to release
- [ ] README download buttons tested

### 🔐 Security
- [x] No secrets committed to Git
- [x] `.env` files excluded from Git
- [x] Production API configuration verified
- [x] Debug logging disabled where appropriate
- [x] Release build verified
- [x] Required security/privacy documentation added

### 📸 Store Assets
- [x] App icon
- [ ] Android screenshots
- [ ] iPhone screenshots
- [ ] Feature graphic if required
- [ ] App Store promotional assets if required
- [ ] App description
- [ ] Short description
- [ ] Keywords/categories

---

## 🤝 Contributing

Found a bug? Congrats, you're now part of the development team. 🫡

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🔐 Privacy & Security

* **Authentication:** Handled entirely by Supabase Auth.
* **Multi-Tenancy:** Row Level Security (RLS) policies strictly enforce that users can only read/write data for the `business_id` they belong to.
* **Local Data:** Offline cached data is stored securely in SQLite via Drift.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🧑‍💻 Author

Built with questionable amounts of caffeine by **Naikhet18**.

* GitHub: [@Naikhet18](https://github.com/Naikhet18)

---

## 💬 Support

If this app somehow breaks your thermal printer, open an Issue.
For general chats or feature requests, hit up the Discussions tab.

---

## 🎯 Final "Publish This Thing" Checklist

```text
☐ Build release
☐ Test Android APK
☐ Test iOS build
☐ Create GitHub Release
☐ Upload APK
☐ Publish Android app
☐ Publish iOS app / TestFlight
☐ Add store links to README
☐ Verify every download button
☐ Ship it 🚀
```

---

> ⭐ If this project saved you from writing 10,000 lines of boilerplate POS code, drop a star.
> 
> It feeds the developer's ego.

<br>

<p align="center">
  Made with ❤️, caffeine ☕, and an unreasonable number of tabs.
</p>

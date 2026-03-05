# Persona — Secure Personal Control Center

A modern, local-first personal security and productivity application built with Flutter. Persona combines a secure password vault, 2FA authenticator, encrypted task manager, and secure notes into a single, elegant interface.

---

## 🛡️ Key Features

- **🔒 Secure Vault**: Store credentials, recovery codes, and sensitive notes with industry-standard AES-256 encryption.
- **🕒 Authenticator (TOTP)**: Generate 2FA codes fully offline. Supports QR code scanning and manual setup with brand-aware icons.
- **📅 Planner**: A personal task manager with a calendar view, recurring tasks, and local notifications.
- **📝 Secure Notes**: Encrypted text notes with full Markdown support for private journaling or sensitive snippets.
- **📦 Encrypted Backups**: Export and restore your entire app data as password-protected, encrypted files.
- **📱 Biometric Lock**: Integration with device-level security (Fingerprint, Face ID, or PIN).
- **🙈 Privacy First**: 
  - Offline-first architecture (data never leaves your device).
  - Screen protection (blocks screenshots and hides app content in the task switcher).
  - Clipboard auto-clear logic.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) or VS Code
- Git

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Fierrez/persona_app.git
   cd persona_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 🛠️ Requirements & Security

- **Android**: Min SDK 21 (Android 5.0). Requires `USE_BIOMETRIC` permissions.
- **iOS**: iOS 12.0 or higher.
- **Data Safety**: All data is stored in `EncryptedSharedPreferences` (Android) and the Secure Keychain (iOS).

---

## 📜 License

Copyright © 2026 MK Hiro.

This project is licensed under the **Apache License, Version 2.0** (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

---

## 🤝 Contributions

This is a personal project, but contributions are welcome. Please open an issue first to discuss any major changes.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

**Maintainer**: [MK Hiro](https://github.com/Fierrez)

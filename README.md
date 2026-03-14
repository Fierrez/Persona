# Persona — Secure Personal Control Center

A modern, local-first personal security and productivity application built with Flutter. Persona combines a secure password vault, 2FA authenticator, encrypted task manager, and secure notes into a single, elegant interface.

---

## 🛡️ Key Features

- **🔒 Secure Vault**: Store credentials, recovery codes, and sensitive notes with industry-standard AES-256 encryption.
- **🕒 Authenticator (TOTP)**: Generate 2FA codes fully offline. Supports QR code scanning and manual setup with brand-aware icons and a dynamic countdown timer.
- **📅 Smart Planner**: A detailed task manager with priority color-coding, specific time reminders, and a calendar view.
- **📝 Markdown Notes**: Secure, encrypted text notes with full Markdown support for rich-text journaling.
- **📦 Multi-Format Backups**: 
  - **Encrypted (.enc)**: Full secure backup protected by your own password.
  - **JSON Export**: Portable, human-readable data format.
  - **Auto-Backup**: Weekly internal safety points saved automatically to your device.
- **📱 Biometric Lock**: Instant app-level security using Fingerprint, Face ID, or PIN with a 30-second switch grace period.
- **🙈 Pro Privacy**: 
  - **Offline-Only**: Zero network permissions. Your data never leaves your device.
  - **Screen Protection**: Dynamic toggle to block screenshots and hide content in the task switcher.
  - **Floating Island Toasts**: Premium, non-intrusive notifications.

---

## 🚀 Getting Started

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Fierrez/persona_app.git
   cd persona_app
   ```
3. Run the app:
   ```bash
   flutter run
   ```

---

## 🛠️ Security Reference

- **Android**: Min SDK 21 (Android 5.0). Requires `USE_BIOMETRIC` permissions.
- **iOS**: iOS 12.0 or higher.
- **Data Safety**: All data is stored in `EncryptedSharedPreferences` (Android) and the Secure Keychain (iOS).

---

## 📜 License

Copyright © 2026 MK Hiro. Licensed under the **Apache License, Version 2.0**.

---

**Maintainer**: [MK Hiro](https://github.com/Fierrez)

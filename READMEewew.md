# Persona — Personal Project

Personal security and productivity app built with Flutter.

This is my personal project; it's maintained by me and intended primarily for personal use. If you'd like to try it, fork or clone and adapt it. Contributions are welcome but may not receive immediate attention.

---

## Quick Summary

- Local-first, privacy-focused vault for credentials, recovery codes, TOTP, and secure tasks.
- Cross-platform: Windows, Android, and Web-ready.

---

## Features (summary)

- Vault (recovery codes): store, mark used, backup/restore
- Credentials manager: store service, username, password; import/export CSV
- Authenticator: offline TOTP generation, QR import
- Tasks: encrypted personal task list and planner
- Encrypted full-app backup and restore

---

## Developer / Owner

Maintainer: MK Hiro

Contact: https://github.com/Fierrez

This repository reflects my personal setup and preferences.

---

## Requirements

- Flutter SDK
- Git
- Visual Studio (Desktop Development with C++ for Windows)  
- Android Studio (for Android builds)

Verify platform setup:

```bash
flutter doctor
```

## Setup (local development)

Clone the repository (replace with your repo URL):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO.git
cd YOUR_REPO
flutter pub get
```

Run on Windows:

```bash
flutter run -d windows
```

Run on Android:

```bash
flutter run
```

Run on Web (Chrome):

```bash
flutter run -d chrome
```

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for full text.

---

## Contributions

This is primarily a personal project. If you want to contribute:

- Open a pull request or submit an issue. I may take time to review.
- For significant changes, open an issue first to discuss design.

Local quick commands:

```bash
git checkout -b feature/your-feature
dart format .
flutter analyze
flutter test
git add .
git commit -m "Add feature X"
git push origin feature/your-feature
```

---

## Security & Data

All data is stored locally and encrypted. There is no automatic cloud sync by default.

If you discover a security issue, please contact me privately via my GitHub profile.

---




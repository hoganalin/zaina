# mobile/ — Flutter app

Scaffolded with `flutter create . --org com --project-name zaina --platforms=ios,android`, giving bundle / package id `com.zaina` to match the Firebase project (`zaina-95124`).

## Firebase config (gitignored)

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

A fresh checkout needs to download these from the Firebase console and drop them into the paths above. They contain client-side API keys, not secrets, but are gitignored to keep config refresh manual.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs    # generate freezed/json files
```

Run with the API base URL pointing at your local backend:

```bash
# Android emulator (uses 10.0.2.2 by default — no flag needed)
flutter run

# iOS simulator (uses localhost by default)
flutter run -d ios

# Real device
flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000
```

## Sign-in flow (Sprint 1)

1. Sign-in screen offers Google (all platforms) + Apple (iOS only).
2. Firebase SDK returns an ID token.
3. App calls `POST /api/auth/session` with the token in `Authorization: Bearer …`.
4. Backend verifies, find-or-creates a User row, returns the self-view.
5. Self-view is held in a Riverpod `AsyncNotifier`; router redirects to `/home`.

### Platform-specific extras

- **Android** — Google Sign-In needs the debug keystore SHA-1 in the Firebase console (`./gradlew signingReport` from `android/`).
- **iOS** — `Info.plist` needs `CFBundleURLTypes` with the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`. Apple Sign In needs the capability enabled in Xcode (paid Apple dev account).

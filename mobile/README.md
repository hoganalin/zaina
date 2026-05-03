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
# Android emulator (default 10.0.2.2 works on most setups)
flutter run

# WSL2 + Windows-side emulator → 10.0.2.2 doesn't reach WSL2;
# use the WSL host IP from `hostname -I` instead
flutter run --dart-define=API_BASE_URL=http://<wsl-ip>:3000

# iOS simulator (uses localhost by default)
flutter run -d ios

# Real device
flutter run --dart-define=API_BASE_URL=http://<your-LAN-ip>:3000
```

## Sign-in flow

1. Splash screen with the 在哪 logo, gold sun-ray, and the 3-cup illustration cropped from the team's Figma (`assets/illustrations/three-cups.png`). Three provider buttons — Facebook (decorative; needs Firebase Console set-up per ADR-0010), Google (functional), Apple (iOS only).
2. Firebase SDK returns an ID token.
3. App calls `POST /api/auth/session` with the token in `Authorization: Bearer …`.
4. Backend verifies, find-or-creates a User row, returns the self-view.
5. Self-view is held in a Riverpod `AsyncNotifier`; router redirects to `/onboarding` (if `onboardingCompleted=false`) or `/feed`.

## Routes

```
/sign-in
/onboarding              4-step (nickname / @username / interests / channels)

/feed         動態  ─┐
/companions   夥伴   │
/notifications 通知  ├─ StatefulShellRoute (5-tab bottom nav)
/messages     訊息   │
/me           我    ─┘

/channels                Channel list, opened from 動態 AppBar
/compose                 Post composer (FAB on 動態)
/post/:id                Post detail with comments + like
/profile/:id             Public profile (own when :id matches authed user.id)
/edit-profile
/chat/:id                DM thread with socket.io subscription
/verify                  Identity verification (simulated)
```

## Visual language

Theme tokens in `lib/theme/zaina_theme.dart` mirror the team's Figma file (`docs/design/figma-tokens.md`). Reusable widgets:

- `widgets/zaina_logo.dart` — 在哪 dual-circle logo + 「歡迎光臨」 signboard
- `widgets/paper_background.dart` — programmatic paper-noise texture
- `widgets/sun_ray_background.dart` — gold radial fan + bubble-tea-stamp circles
- `widgets/signboard_card.dart` — six post-card templates cycling by post id hash:
  1. multi-stack stamps on image (only short CJK titles, ≤5 chars)
  2. sticker + cream caption box on image
  3. red sunburst with hand-painted yellow text
  4. yellow signboard with red border + 「特別話題」 label
  5. paper speech bubble with corner sticker
  6. green panel + sticker + cream caption

## Platform-specific extras

- **Android** — Google Sign-In needs the debug keystore SHA-1 in the Firebase console (`./gradlew signingReport` from `android/`).
- **iOS** — `Info.plist` needs `CFBundleURLTypes` with the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`. Apple Sign In needs the capability enabled in Xcode (paid Apple dev account).

## Known constraints

- `Image.network` on feed cards must use `cacheWidth: 360, cacheHeight: 360` — without it, 36 simultaneously-loading raw bitmaps blow memory and trigger an Android ANR on first paint.
- Rendering layer: Flutter defaults to **Impeller** on Android. `screencap -p` over adb captures a black frame because Impeller draws via OpenGLES that screencap can't read — use the emulator window directly to verify visuals.

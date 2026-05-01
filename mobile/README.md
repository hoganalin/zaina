# mobile/ — Flutter app

Scaffolded with `flutter create . --org com --project-name zaina --platforms=ios,android`, giving bundle / package id `com.zaina` to match the Firebase project (`zaina-95124`).

## Firebase config (gitignored)

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

A fresh checkout needs to download these from the Firebase console and drop them into the paths above. They contain client-side API keys, not secrets, but are gitignored to keep config refresh manual.

## Dependencies to add (Sprint 1+)

`pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  dio: ^5.7.0
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.4
  go_router: ^14.6.2
  socket_io_client: ^3.0.2

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  riverpod_generator: ^2.6.3
```

Then `flutter pub get` and `dart run build_runner watch` to keep generated files in sync.

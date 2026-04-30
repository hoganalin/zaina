# mobile/ — Flutter app

> Sprint 0 leaves this directory as a placeholder. Sprint 1 will run `flutter create` to scaffold the actual project, then commit the result.

## Why this directory is empty right now

The host system has Flutter installed at `/mnt/c/flutter/` (Windows side, accessed through WSL). Calling `flutter create` from inside WSL fails with a `\r` line-ending error because the Windows scripts aren't WSL-friendly. Rather than create a half-broken scaffold, Sprint 0 stops here and leaves the actual `flutter create` to be run **on the Windows side**.

## What Sprint 1 will do

From a Windows terminal (PowerShell or Command Prompt), at the repo root:

```powershell
cd C:\Users\Rogan\projects\zaina\mobile  # or wherever the repo is on the Windows side
flutter create . --org com.zaina --project-name zaina --platforms=ios,android
```

Alternatively, install Flutter natively in WSL:

```bash
sudo snap install flutter --classic
flutter doctor
cd /home/rogan/projects/zaina/mobile
flutter create . --org com.zaina --project-name zaina --platforms=ios,android
```

## Planned dependencies (Sprint 1+)

To be added to `pubspec.yaml` once the project is scaffolded:

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

Run `flutter pub get` after adding these. Then `dart run build_runner watch` keeps generated files in sync.

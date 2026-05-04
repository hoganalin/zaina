# sign_in/

登入畫面（Google / Apple）+ 全 app 共用的 `authStateProvider`。Router 預設導向這裡，登入完成後再 redirect 到 `/onboarding` 或 `/feed`。

## Screens & providers

| 檔案 | 用途 |
|---|---|
| `sign_in_screen.dart` | 三個 provider button（Google ✅、Apple ✅、Facebook 為 placeholder snackbar） |
| `auth_providers.dart` | `AuthNotifier` (`AsyncNotifier<SelfView?>`) + `submitOnboarding` + `signOut` 全 app 唯一身分來源 |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `POST` | `/api/auth/session` | 把 Firebase ID token 換成自家 SelfView（server 端 verify token + upsert User row，ADR-0008） |
| `PATCH` | `/api/me/onboarding` | onboarding 用，定義在這裡的 `submitOnboarding` |
| `GET` | `/api/me/check-username` | onboarding 用，username 唯一性檢查 |

## 資料流

```
SignInScreen
  → User 按 Google → signInWithGoogle()
    → GoogleSignIn().signIn() → Firebase signInWithCredential()
    → POST /api/auth/session （Authorization: Bearer <Firebase ID token>）
    → server verify + upsert + 回 SelfView
    → state = AsyncData(SelfView)
    → unawaited(fcmServiceProvider.register())
  → router refreshListenable 觸發 → redirect /onboarding 或 /feed

冷啟（app 重開）
  → AuthNotifier.build() 看 FirebaseAuth.currentUser
  → 有 → POST /api/auth/session 取 SelfView
  → 失敗（API 不認）→ FirebaseAuth.signOut()，當作未登入

登出
  → fcmService.unregister() → FirebaseAuth.signOut() → GoogleSignIn().signOut()
  → state = AsyncData(null)
```

## 已知陷阱

- **加新 provider 走 RULE-01 清單**（CLAUDE.md）：Console → SDK → token → 驗收測試。少一步 Claude 會擋下不收。
- **`_fetchSelfView` 失敗要 signOut**：`build()` 裡 catch 之後立刻 `FirebaseAuth.signOut()`，避免「Firebase 已登入但 API 不認」的卡死狀態。新人接手常會把這個 catch 改成「重試」，那會卡死在登入頁。
- **Apple sign-in 只在 iOS 顯示按鈕**：[sign_in_screen.dart:19](sign_in_screen.dart#L19) 用 `Platform.isIOS` 判斷。不要拿掉這個條件——Android 上沒有 Apple sign-in 機制。
- **Apple iOS device 驗收待 Mac 環境**：RULE-01 第 1–3 步（Console、SDK、`/api/auth/session`）已就位，第 4 步測試也在 [api/test/auth.session.test.ts](../../../../api/test/auth.session.test.ts) 模擬 `firebase.sign_in_provider: 'apple.com'` + 無 `name` 的 shape。但 Apple Developer Service ID + iOS 真機 / Simulator 走一次的驗收還沒做（Windows/WSL 開發機無 Xcode）。等 Mac 環境再跑 `flutter run -d iphone`。
- **Email 沒做**：deck 有列「Email / Google / Apple」三選項，但 v1 範圍只實作 Google + Apple。要做的話走 RULE-01。
- **Token 換 SelfView 之後**：`unawaited(fcmServiceProvider.register())` 是 best-effort——FCM 註冊失敗**不能**阻擋使用者進 app。

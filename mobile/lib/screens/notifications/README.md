# notifications/

通知列表——bottom-nav 第三格。FCM 推播觸發、進 app 後在這裡讀取歷史。

## Screens

| 檔案 | 用途 |
|---|---|
| `notifications_screen.dart` | 通知時間軸（like / comment / follow / message） |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/notifications` | 取當前 user 的通知列表 |

對應 dart client：[`lib/api/notifications_api.dart`](../../api/notifications_api.dart)。FCM token 註冊在 [`lib/api/fcm_service.dart`](../../api/fcm_service.dart) 走 `PATCH /api/me/push-token`。

## 資料流

```
登入成功（auth_providers._fetchSelfView）
  → unawaited(fcmServiceProvider.register())
  → PATCH /api/me/push-token { fcmToken }
  → server 把 token 存到 User.fcmTokens

事件發生（例：對方留言）
  → server emitToUser + sendFCM
  → 對方 app 在前景 → in-app banner；背景 → 系統通知

notifications_screen build
  → ref.watch(notificationsProvider)
  → GET /api/notifications → 顯示時間軸
```

## 已知陷阱

- **FCM register 是 best-effort**：`unawaited()` 包住，**永遠**不阻擋登入。即使 token 拿不到，user 還是要能進 app。
- **登出時要 unregister**：`auth_providers.signOut()` 已呼叫 `fcmService.unregister()` → `PATCH /api/me/push-token { fcmToken: null }`。**不要**忘記，否則該裝置會繼續收前任 user 的推播。
- **通知本身只是事件記錄**：點進去要自己 navigate（例如點 like 通知 → 開 post detail）。沒有「已讀」狀態（v1 portfolio 範圍未做）。

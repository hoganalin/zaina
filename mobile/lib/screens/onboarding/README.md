# onboarding/

新帳號的 4 步驟設定流程。Sign-in 成功後 router 會強制導向這裡，直到 `user.onboardingCompleted == true`（[router.dart:46](../../router.dart#L46)）。

## Screens

| 檔案 | 用途 |
|---|---|
| `onboarding_screen.dart` | 4 step：暱稱 + 性別 → 城市 + 國家 → 興趣 → 喜歡的看板，以及最後的 `WelcomeSignboard` 「歡迎光臨」歡迎畫面 |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/interests` | 興趣標籤清單（12 個） |
| `GET` | `/api/channels` | 看板清單（共用，channels 螢幕也讀） |
| `PATCH` | `/api/me/onboarding` | 一次提交所有欄位（透過 `authStateProvider.submitOnboarding`） |

對應 dart client：[`lib/api/onboarding_api.dart`](../../api/onboarding_api.dart)、提交走 [`lib/screens/sign_in/auth_providers.dart`](../sign_in/auth_providers.dart)。

## 資料流

```
sign-in 成功 → user 在 DB 但 onboardingCompleted=false
  → router redirect 到 /onboarding
  → 顯示 step 1 (nickname + gender)

User 走完 4 步驟 → 按完成
  → authStateProvider.submitOnboarding({...})
    → PATCH /api/me/onboarding 一次帶所有欄位
    → server 在 transaction 裡寫 user + UserInterest + ChannelFollow
  → state 更新成 onboardingCompleted=true 的 SelfView
  → router refresh listenable 觸發 → redirect 到 /feed
```

## 已知陷阱

- **後端 user row 在 sign-in 那一刻就建好**（ADR-0008，eager create）。Onboarding 是**更新**（`PATCH`），不是 create。**不要**改成 POST。
- **interest / channel 是 set，不是 list**：選了 N 個就提交 N 個 id 陣列，**不分順序**。後端用 transaction 包 `deleteMany + createMany` 全量替換。
- **檢查 username 唯一**：`auth_providers.checkUsernameAvailable` 在使用者打字時 debounce 呼叫 `GET /api/me/check-username?u=xxx`。錯誤要靜默吞掉（回 false 表示不可用）。
- **Step 切換不會自動驗證**：每個 step 的 `_canProceed` 由欄位完整性決定，不要在 onChange 時硬性 setState 觸發 rebuild 壓垮 UI。

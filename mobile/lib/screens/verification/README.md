# verification/

身分驗證——送出學生 / 上班族證件，通過後 profile 顯示 Verified Badge。**v1 是模擬審核**（ADR-0004），server 端不做 OCR、不接外部驗證 API，收到請求就在 transaction 裡直接 mark `status=approved` 與 `User.isVerified=true`。

## Screens

| 檔案 | 用途 |
|---|---|
| [`verification_screen.dart`](verification_screen.dart) | 選身分類型（學生 / 在職）→ 貼圖片 URL → 送出。已驗證者看到「已驗證」提示卡。 |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `POST` | `/api/verifications` | 送一份 verification 申請（`{identityType, imageUrl}`），server 端即時 approve |
| `GET` | `/api/me` | submit 成功後 client 自動 refresh，拿新的 `SelfView`（`isVerified=true`） |

對應 dart client：[`lib/api/verifications_api.dart`](../../api/verifications_api.dart)。

## 資料流

```
User 進 verification_screen
  → 選 identityType (student / employee)
  → 在 TextField 貼一個圖片 URL（v1 暫不支援直接上傳）
  → 按「送出驗證」
  → VerificationsApi.submit():
      POST /api/verifications { identityType, imageUrl }
      server 在 transaction 裡：
        create Verification(status=approved, reviewedAt=now)
        update User isVerified=true
      接著 client 自動 GET /api/me
      → authStateProvider.updateSelfView(newSelfView)
  → context.pop() 回上一頁
  → profile 顯示 Verified Badge
```

## 已知陷阱

- **v1 沒有真上傳**：UI 只是一個 `TextField` 收 URL（`verification_screen.dart:92-99`）。沒有 `image_picker`、沒有 GCS 上傳、沒有 signed URL。要做真上傳前先讀 ADR-0004。
- **審核是模擬**（ADR-0004）：`Verification.status` 在 v1 永遠 `approved`。**沒**有 OCR、**沒**有人工審核、**沒**有 `pending` / `rejected` 流程（schema 保留但未實作）。
- **`isVerified` 是 cosmetic**：通過 verification 不解鎖任何功能、不解鎖 DM、不解鎖 post（ADR-0005）。**不要**寫 `if (user.isVerified) { ... }` 來 gate 功能。
- **送出成功後 state 由 API client 推進**：`VerificationsApi.submit()` 自己 call `/api/me` 並 `updateSelfView`（`verifications_api.dart:28-31`）。**不要**在 screen 裡自己再 call 一次 `/api/me`，會多打一次 API。
- **`imageUrl` zod 只驗 url shape**，不驗該圖真的存在或是合法證件（[FEATURES.md](../../../../docs/FEATURES.md)）。v1 portfolio 範圍。

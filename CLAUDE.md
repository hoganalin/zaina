# CLAUDE.md

Instructions for Claude Code working in this repository.

## 專案概述

**在哪 ZAINA** — 旅居海外台灣人的「主題優先」社交 App。Portfolio 級別，展示完整全端：**Flutter + Riverpod + freezed + dio**（mobile）／**TypeScript + Hono + Prisma + Postgres + Socket.io**（API）／**Firebase Auth + FCM**／**GCP Cloud Run + Neon**（部署）。產品真實可跑，但所有 scope 取捨偏向「demonstrable in an interview」而非「production-ready at scale」。

## 常用指令

| 指令 | 用途 |
|---|---|
| `cd api && npm run dev` | API dev server（tsx watch → http://localhost:3000） |
| `cd api && npm run typecheck` | `tsc --noEmit` |
| `cd api && npm test` | vitest 全套（48 cases，串真實 Neon DB） |
| `cd api && npm run prisma:migrate` | `prisma migrate dev`（產生 + 套用 migration） |
| `cd api && npm run prisma:seed` | 12 channels + 12 interests + 5 authors + 36 posts |
| `cd mobile && flutter pub get` | 安裝 mobile 依賴 |
| `cd mobile && dart run build_runner build --delete-conflicting-outputs` | 產生 freezed/json |
| `cd mobile && flutter run` | 啟動（Android emulator 預設打 10.0.2.2:3000） |
| `cd mobile && flutter run --dart-define=API_BASE_URL=http://<ip>:3000` | 真機 / WSL2 指向自訂 host |
| `cd infra && docker compose up -d` | 本機 Postgres（zaina/zaina/zaina:5432） |

## 關鍵規則

- **全棧領域語言一致** — 用 `CONTEXT.md` 定義的詞（**Channel 看板**，不要 topic / subreddit；**Followed Person**；**Conversation Eligibility**；**Post City**；**Verified Badge**）。「夥伴」是 UI label，後端永遠是單向 UserFollow（ADR-0002 + ADR-0010）。
- **凡有不直觀的設計就有 ADR** — 動 schema 前讀 ADR-0006（denormalised counts）/ ADR-0007（channel as table）/ ADR-0008（user row eager create）；動 DM 前讀 ADR-0003；動驗證前讀 ADR-0004；要砍／加 feature 前讀 ADR-0005 與 ADR-0010。
- **顏色與字級一律從 token 取**：`mobile/lib/theme/zaina_theme.dart` ↔ `docs/design/figma-tokens.md`。**禁止 eyeball 任何 hex**。Feed grid 的 `Image.network` **必須帶 `cacheWidth/cacheHeight`**（沒帶會 ANR）。
- **API：strict TypeScript / `@hono/zod-validator` 驗每個 body+query / Prisma 跨表寫入包 `$transaction` / 套 `requireAuth` 取 `c.var.userId` 與 `c.var.user`**。Mobile：**Riverpod、freezed、dio 單例**，1 screen = 1 directory（`lib/screens/<name>/`），不要用 `FutureBuilder`。
- **功能開發使用 `docs/plans/` 記錄計畫**（命名 `YYYY-MM-DD-<feature>.md`，內容 User Story → Spec → Tasks）；**完成後 `git mv` 至 `docs/plans/archive/`** 並同步更新 `docs/FEATURES.md` 與 `docs/CHANGELOG.md`。流程細節：`docs/DEVELOPMENT.md §11`。

> 補充：commit 用 conventional prefix (`feat`/`fix`/`chore`/`docs`/`refactor`/`test`/`perf`)；**絕不 `--amend` 已 push 的 commit**；pre-commit hook 失敗 → 修問題 → 寫新 commit。
> 推薦 skills：新功能用 `/grill-with-docs` 過詞與 spec、`/tdd` 寫紅綠重構、`/to-issues` 拆 sprint。

## Mobile 工程紀律（4 條家規）

這 4 條是 mobile 端「自動出閘」的紀律。違反任何一條，code review 直接退件。

### RULE-01 「新增登入方式」必須走完清單

加 Apple / 第三方登入時，這 4 步缺一不可：

1. **Console 設定**：Firebase Console 啟用 provider（Apple 還要在 Apple Developer 設 Service ID + key）
2. **手機 SDK 接起來**：mobile 裝對應 plugin、寫 `signInWith<X>()` notifier method
3. **Token 送進後端**：`POST /api/auth/session` 走通（Firebase Admin SDK verify ID token）
4. **驗收測試**：`api/test/auth.session.test.ts` 加一個 case 模擬該 provider 的 token shape

少做任何一步 → 不算完成。範例：`signInWithGoogle` (`mobile/lib/screens/sign_in/auth_providers.dart:36`)。

### RULE-02 斷線重連策略寫一份、不許重複

「網路斷了怎麼辦」**只在 `mobile/lib/api/chat_socket.dart` 寫一次**：

- Backoff：1s → 2s → 5s → 10s → 30s（最大 30s）
- 每次 reconnect 前重新取 Firebase ID token（token 1 小時會過期）
- Server 端 `io.on('connection')` 會重跑 auth 並重新 join `user:{id}` room，所以 client 端**不需要**重新訂閱

未來任何即時功能（typing、presence、notifications stream）都走同一個 socket、共用這份策略——**不准複製一份新的**。

### RULE-03 每個 screen / feature 都要附 README

`mobile/lib/screens/<name>/README.md` 必填：

1. **這個 screen 是什麼**（一句話 + 主要 user story）
2. **跟哪些 API 說話**（端點清單 + 對應的 `lib/api/*.dart`）
3. **資料怎麼流**（Riverpod provider → screen → user action → API → state）
4. **已知陷阱**（例如 feed 的 `Image.network` 必須帶 `cacheWidth/cacheHeight` 否則 ANR）

新人接手 3 分鐘看懂，不用叫作者來解釋。範例：`mobile/lib/screens/conversations/README.md`、`mobile/lib/screens/feed/README.md`。

### RULE-04 測試要跟功能一起交件

新增 API endpoint 或 mobile 互動邏輯 → 同一次 PR 必須附測試：

- API 改動 → `api/test/<feature>.test.ts` 加 case（串真實 Neon DB，不 mock）
- Mobile 互動邏輯 → `mobile/test/<area>_test.dart` 加 widget test（不需要跑 emulator）

說「之後補」？退件。這條規矩是讓 `api/` 端 48 個 vitest cases 自然長出來的原因，mobile 端也走同樣標準。

## 詳細文件

- [`./docs/README.md`](./docs/README.md) — 項目介紹、技術棧、快速開始、文件索引
- [`./docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) — 目錄結構、啟動流程、API 路由總覽、認證與授權、DB schema、Socket.io / FCM 整合
- [`./docs/DEVELOPMENT.md`](./docs/DEVELOPMENT.md) — 命名規則、模組系統、新增 API/middleware/migration 步驟、環境變數表、JSDoc 風格、計畫歸檔流程
- [`./docs/FEATURES.md`](./docs/FEATURES.md) — 14 個功能的端點規格 + 行為描述 + 業務邏輯 + 錯誤情境
- [`./docs/TESTING.md`](./docs/TESTING.md) — 測試檔表、執行順序與依賴、輔助函式、寫新測試的步驟、常見陷阱
- [`./docs/CHANGELOG.md`](./docs/CHANGELOG.md) — Sprint 0–9 變動紀錄
- [`./docs/adr/`](./docs/adr/) — 10 個架構決策（ADR-0001…0010），新增**永遠 +1**
- [`./docs/design/`](./docs/design/) — Figma token、視覺規格、cached PNG 匯出
- [`./docs/plans/`](./docs/plans/) — 進行中計畫（完成移到 `archive/`）
- [`./CONTEXT.md`](./CONTEXT.md) — 領域語言（讀完這份再讀程式碼）
- [`./DEPLOY.md`](./DEPLOY.md) — GCP Cloud Run + Neon 部署步驟

## Figma 存取注意

Figma 檔 `JGUawgfQV6xjWlirhpk73y`。token 在 `~/.claude.json`（`figma-developer-mcp`）。**Starter plan 配額很低，重複拉 `mcp__figma__get_figma_data` 會把 API 鎖好幾天**。動圖前先確認 `docs/design/reference/` 的 cached PNG 是否已能回答問題。

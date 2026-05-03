# 在哪 ZAINA — 文件索引

> 旅居海外台灣人的「主題優先」社交 App。Flutter 前端 + Hono/Prisma 後端 + GCP Cloud Run + Neon Postgres。

這份 `docs/` 目錄是專案的真實知識庫。`README.md`（根目錄）面向對外讀者；本目錄內的文件面向開發者與 AI 助手。

---

## 1. 專案是什麼

ZAINA 是一個 portfolio 級別的社交應用，目標是展示完整的全端能力（Flutter / Node.js / GCP / TypeScript）。產品定位：

- **Topic-first**：主畫面是「看板」與貼文，**沒有 swipe、沒有 match**（ADR-0002）。
- **使用者**：旅居海外的台灣人。看板分類涵蓋租屋、二手、票券、旅遊、旅伴、美食、心情等。
- **私訊**：必須先有公開互動（評論）才能 DM，第一封落入 Message Request 佇列（ADR-0003）。
- **驗證**：學生／員工證上傳是真實流程，但審核流程在 v1 是模擬通過（ADR-0004）。

完整的領域語言定義見 [`../CONTEXT.md`](../CONTEXT.md)。

## 2. 技術棧

| 層 | 技術 | 版本 / 備註 |
|---|---|---|
| Mobile UI | Flutter | SDK `^3.11.5`（pubspec.yaml） |
| 狀態管理 | flutter_riverpod | `^2.5.1` — `AsyncNotifier` 為主 |
| 路由 | go_router | `^14.6.0` — `StatefulShellRoute.indexedStack` |
| Models | freezed + json_serializable | 編譯時序列化，禁手寫 fromJson |
| HTTP | dio | `^5.7.0` — 單例 + 認證 interceptor |
| Realtime | socket_io_client | `^3.0.2` |
| Auth (Mobile) | firebase_auth + google_sign_in + sign_in_with_apple | — |
| Push | firebase_messaging | `^15.1.4` |
| API runtime | Node.js | 22+（Dockerfile alpine） |
| API 框架 | Hono | `^4.6.13`，搭配 `@hono/node-server` |
| 驗證 | `@hono/zod-validator` + zod | 全部請求 body / query 經 zod schema |
| ORM | Prisma Client | `^6.0.0` |
| 資料庫 | PostgreSQL | 16-alpine（local docker-compose）／Neon（prod） |
| Auth (Server) | firebase-admin | `^13.0.1`，verifyIdToken |
| Realtime (Server) | socket.io | `^4.8.1` |
| 測試 | vitest | `^4.1.5`，串接真實 Neon DB |
| 部署 | GCP Cloud Run + Artifact Registry | 詳見 `../DEPLOY.md` |

## 3. 快速開始

### 啟動 API（本機）

```bash
# 1. Postgres：本機 docker 或填 Neon 連線字串
cd infra && docker compose up -d                    # docker-compose.yml 的 zaina/zaina/zaina

# 2. 安裝 + migrate + seed
cd ../api
cp .env.example .env                                # 填 DATABASE_URL、FIREBASE_*
npm install
npx prisma migrate dev                              # 套用所有 migration
npm run prisma:seed                                 # 12 channels + 12 interests + 5 authors + 36 posts

# 3. 啟動 dev server
npm run dev                                         # tsx watch src/index.ts → http://localhost:3000
curl http://localhost:3000/health                   # {"status":"ok",...}
```

### 啟動 Flutter

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 產生 *.freezed.dart / *.g.dart
flutter run                                                # Android 預設 10.0.2.2:3000；iOS 預設 localhost:3000
# 真機 / WSL2：
flutter run --dart-define=API_BASE_URL=http://<lan-or-wsl-ip>:3000
```

### 跑測試

```bash
cd api
npm test                                            # vitest run，48 cases、串接真實 DB（fileParallelism: false）
```

## 4. 常用指令

| 指令 | 用途 | 出處 |
|---|---|---|
| `npm run dev` | API dev server（tsx watch） | `api/package.json` |
| `npm run build` | 編譯到 `dist/` | `api/package.json` |
| `npm start` | 跑編譯後的 `dist/index.js` | `api/package.json` |
| `npm run typecheck` | `tsc --noEmit` | `api/package.json` |
| `npm test` | vitest 全套 | `api/package.json` |
| `npm run test:watch` | vitest watch mode | `api/package.json` |
| `npm run prisma:generate` | 重新產 Prisma client | `api/package.json` |
| `npm run prisma:migrate` | `prisma migrate dev` | `api/package.json` |
| `npm run prisma:studio` | 本地 GUI 看 DB | `api/package.json` |
| `npm run prisma:seed` | 套用 `prisma/seed.ts` | `api/package.json` |
| `flutter pub get` | 安裝 mobile 依賴 | mobile |
| `dart run build_runner build --delete-conflicting-outputs` | 產生 freezed/json 檔 | mobile |
| `flutter run` | 啟動 mobile（auto-pick device） | mobile |
| `flutter analyze` | 跑 lint（`analysis_options.yaml`） | mobile |

## 5. 文件索引

| 檔案 | 內容 |
|---|---|
| [`README.md`](./README.md) | （本檔）入口、技術棧、快速開始 |
| [`ARCHITECTURE.md`](./ARCHITECTURE.md) | 目錄結構、啟動流程、API 路由、認證、DB schema、第三方整合 |
| [`DEVELOPMENT.md`](./DEVELOPMENT.md) | 命名規則、模組系統、環境變數、計畫歸檔流程 |
| [`FEATURES.md`](./FEATURES.md) | 功能行為說明（每個端點的 query / body / 業務邏輯 / 錯誤碼） |
| [`TESTING.md`](./TESTING.md) | 測試檔表、執行順序、輔助函式、寫新測試的步驟與陷阱 |
| [`CHANGELOG.md`](./CHANGELOG.md) | Sprint 0–9 變動紀錄 |
| [`adr/`](./adr/) | 10 個架構決策（ADR-0001…0010），是「為什麼這樣寫」的權威來源 |
| [`design/figma-tokens.md`](./design/figma-tokens.md) | Figma 顏色／字級 token 對照（5 scale × 11 stop） |
| [`design/visual-spec.md`](./design/visual-spec.md) | 視覺規格、信件招牌看板卡片系統 |
| [`design/reference/`](./design/reference/) | Figma 匯出的 PNG（splash / signin / feed / first_login / logo） |
| [`plans/`](./plans/) | 進行中的開發計畫（YYYY-MM-DD-feature.md） |
| [`plans/archive/`](./plans/archive/) | 已完成計畫歸檔 |
| [`demo-60s-script.md`](./demo-60s-script.md) | Demo 錄製 60 秒口稿 |
| [`../CONTEXT.md`](../CONTEXT.md) | 領域語言：User / Channel / Post / Conversation / Block / Verification 等定義 |
| [`../CLAUDE.md`](../CLAUDE.md) | AI 助手的工作守則（讀這個目錄前先讀它） |
| [`../DEPLOY.md`](../DEPLOY.md) | GCP Cloud Run + Neon 部署步驟 |

## 6. 進入專案的閱讀順序

第一次接觸的開發者建議：

1. `../README.md`（根） — 30 秒抓到產品輪廓
2. `../CONTEXT.md` — 名詞定義，不讀會用錯詞
3. `ARCHITECTURE.md` — 系統怎麼長的
4. `FEATURES.md` — 找你要動的功能
5. `adr/` 對應的決策 — 動之前先看為什麼這樣
6. `DEVELOPMENT.md` — 寫程式前讀命名／環境變數規則
7. `TESTING.md` — 寫程式時對照

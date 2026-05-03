# DEVELOPMENT.md

開發守則。涵蓋命名規則、模組系統、新增 API / middleware / DB 的步驟、環境變數、JSDoc 與 plan 歸檔流程。

---

## 1. 命名規則對照表

### 1.1 API 端 (TypeScript)

| 種類 | 風格 | 範例 | 出處 |
|---|---|---|---|
| 檔名 | kebab-case 不行；用 lowercase | `eligibility.ts`, `requireAuth.ts` | `src/` |
| Hono 路由模組變數 | `<resource>Routes` | `authRoutes`, `meRoutes`, `companionsRoutes` | `routes/auth.ts` 等 |
| middleware 檔名 | camelCase 函式名 | `requireAuth.ts` 內 export `requireAuth` | `middleware/requireAuth.ts` |
| Zod schema | suffix `Schema` | `createPostSchema`, `paginationSchema` | `routes/posts.ts` |
| 函式 | camelCase | `canDM`, `orderUserPair`, `getBlockedCounterparts` | — |
| Prisma model | PascalCase | `User`, `Post`, `UserFollow` | `schema.prisma` |
| Prisma enum | PascalCase | `Gender`, `ConversationStatus` | `schema.prisma` |
| Enum 值 | snake_case | `non_binary`, `message_request` | `schema.prisma` |
| API key (JSON) | camelCase | `likeCount`, `commentCount`, `firebaseUid` | 全棧一致 |
| Resource envelope | 名詞單數／複數 | `{user: ...}`, `{posts: [...]}` | route handlers |
| URL path | kebab-case + 複數 | `/api/posts/:id/comments`, `/api/me/check-username` | `app.ts` |
| 錯誤 code | snake_case | `username_taken`, `not_eligible`, `cannot_dm_self` | route handlers |

### 1.2 Mobile 端 (Dart / Flutter)

| 種類 | 風格 | 範例 | 出處 |
|---|---|---|---|
| 檔名 | snake_case | `feed_screen.dart`, `auth_providers.dart`, `chat_socket.dart` | `lib/` |
| Class | PascalCase | `FeedScreen`, `AuthNotifier`, `ChatSocket` | — |
| 變數 / 函式 | camelCase | `signInWithGoogle`, `authStateProvider` | — |
| 常數 | lowerCamelCase（前置 `k`） | `_kApiBaseUrlOverride` | `dio_client.dart` |
| Riverpod provider | suffix `Provider` | `authStateProvider`, `routerProvider`, `fcmServiceProvider` | — |
| freezed model | PascalCase；檔名 snake_case | `FeedPost` in `feed_post.dart` | `models/` |
| 生成檔 | `.freezed.dart`, `.g.dart` | `feed_post.freezed.dart` | build_runner |
| 資料夾結構 | 一個 screen 一個 dir | `lib/screens/feed/`、`/sign_in/`、`/profile/` | CLAUDE.md 規定 |
| Theme tokens | `ZainaPalette.<role>` | `ZainaPalette.brickRed` | `theme/zaina_theme.dart` |

### 1.3 命名陷阱（請避開）

- **不要用 `topic`／`話題`**：模型上沒有 Topic entity；UI copy 才保留「特別話題」/「所有話題」。資料層用 **Channel** 或 **Post**。
- **不要把 `Followed Person` 寫成 match / 配對**。
- **「夥伴」是 UI 標籤**，後端永遠是 UserFollow。Sprint 9 之後仍是單向，沒有 mutual。
- **資料庫欄位用 camelCase**（Prisma 預設），不要 snake_case。但**枚舉值是 snake_case**（`message_request`）— 這是 Prisma enum 慣例。

---

## 2. 模組系統

### 2.1 API（ESM + verbatimModuleSyntax）

`api/tsconfig.json` 設 `"module": "ESNext"` + `"moduleResolution": "Bundler"` + `"verbatimModuleSyntax": true`。意義：

- **import 路徑必須帶 `.js`**（即使是 `.ts` 檔）：
  ```ts
  import { app } from './app.js';                    // ✅
  import { app } from './app';                        // ❌ tsx 跑不起來
  import { requireAuth } from '../middleware/requireAuth.js';  // ✅
  ```
- type-only import 必須明示 `type`：
  ```ts
  import type { Server as HttpServer } from 'node:http';
  import { type AuthVariables, requireAuth } from '../middleware/requireAuth.js';
  ```
- **package.json 是 `"type": "module"`** — 整個 api package 是 ESM。
- 執行：dev 用 `tsx watch`（直接吃 .ts），prod 用 `tsc → node dist/index.js`。

### 2.2 Mobile

- Dart 沒有複雜的 module system。`package:zaina/...` 引用走 pubspec name `zaina`；專案內用相對路徑。
- **freezed / json_serializable 需要 `part`**：
  ```dart
  part 'feed_post.freezed.dart';
  part 'feed_post.g.dart';
  ```
- 改完 model 必跑 `dart run build_runner build --delete-conflicting-outputs`。

---

## 3. 環境變數

### 3.1 API（驗證在 `src/env.ts`）

| 變數 | 用途 | 必要性 | 預設 |
|---|---|---|---|
| `DATABASE_URL` | Postgres 連線字串（含 `?schema=public`） | 必填 | — |
| `PORT` | API 監聽 port | 選填 | `3000` |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | service account JSON 路徑（local dev） | 本機必填；Cloud Run 留空走 ADC | — |
| `FIREBASE_PROJECT_ID` | Firebase 專案 id | 選填（admin SDK 通常從 service account 推得） | — |
| `NODE_ENV` | `development`\|`production`\|`test` | 選填 | `development` |
| `GCS_BUCKET_ID_IMAGES` | 私有 bucket（驗證上傳用） | **未實作**，目前 `.env.example` 預留 | — |
| `FIREBASE_WEB_API_KEY` | `scripts/demo-token.ts` 換 ID token 用 | 跑 demo-token script 才需要 | — |

驗證：`safeParse(process.env)`，缺/錯印錯誤路徑後 `process.exit(1)`。

> ⚠️ **DATABASE_URL 必須是合法 URL**（zod `.url()`）— 如「postgres://」起頭都行，但 `localhost:5432` 沒有 scheme 會 fail。

### 3.2 Mobile（compile-time `--dart-define`）

| 變數 | 用途 | 必要性 | 預設 |
|---|---|---|---|
| `API_BASE_URL` | 覆寫 API 起點 | 真機 / WSL2 必填 | Android emulator: `http://10.0.2.2:3000`；其他: `http://localhost:3000` |

讀取：`dio_client.dart` 用 `String.fromEnvironment('API_BASE_URL')`。

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.7:3000
flutter build apk --dart-define=API_BASE_URL=https://zaina-api-xxx.a.run.app
```

### 3.3 Firebase config（mobile，gitignored）

| 檔案 | 平台 | 來源 |
|---|---|---|
| `mobile/android/app/google-services.json` | Android | Firebase Console → Project settings → Your apps |
| `mobile/ios/Runner/GoogleService-Info.plist` | iOS | 同上 |

**這些是 client-side API key，不是 secret，但被 gitignore 是為了讓重新下載成為手動步驟。**

---

## 4. 新增 API endpoint 步驟

下面以「新增 `POST /api/posts/:id/share`」為例。

### 4.1 建立或選擇 route 檔

這個 endpoint 屬於 posts，所以加在 `api/src/routes/posts.ts`。如果是新資源，建立 `routes/<resource>.ts` 並在 `app.ts` 掛 `app.route('/api/<resource>', <resource>Routes)`。

### 4.2 寫 zod schema

在檔案頂部聲明：

```ts
const sharePayloadSchema = z.object({
  channel: z.enum(['line', 'twitter', 'copy_link']),
  note: z.string().max(300).optional(),
});
```

### 4.3 寫 handler

```ts
postsRoutes.post(
  '/:id/share',
  zValidator('json', sharePayloadSchema),
  async (c) => {
    const userId = c.var.userId;
    const postId = c.req.param('id');
    const data = c.req.valid('json');

    // 確認資源存在
    const post = await prisma.post.findUnique({ where: { id: postId }, select: { id: true } });
    if (!post) return c.json({ error: 'not_found' }, 404);

    // 業務邏輯（如有 denormalised count 必須包 transaction）
    // ...

    return c.json({ ok: true }, 200);
  },
);
```

要點：

- **必先驗證 `c.req.param` 對應到的資源存在**，回 404 前先 `select: {id: true}` 避免一次撈整 row。
- **跨表寫入用 `prisma.$transaction`**。
- 使用 `c.var.userId`（middleware 已設）— 不要再 verifyIdToken 一次。

### 4.4 寫測試

對應到 `api/test/posts.test.ts`，仿既有 case 寫 mock + 斷言。詳見 [`TESTING.md`](./TESTING.md)。

### 4.5 mobile 端

1. 在 `mobile/lib/api/posts_api.dart` 新增方法：
   ```dart
   Future<void> share(String postId, {required String channel, String? note}) async {
     await _dio.post('/api/posts/$postId/share', data: {'channel': channel, if (note != null) 'note': note});
   }
   ```
2. 如果有 freezed model 變動，先改 model → 跑 build_runner。
3. 在對應 screen / Riverpod provider 呼叫。

### 4.6 更新文件

- `docs/FEATURES.md` — 加端點規格與行為描述
- `docs/ARCHITECTURE.md` 路由表 — 加一列
- 若引入新概念 → 更新 `CONTEXT.md`
- 若做了不一樣的設計選擇 → 寫 ADR（見 §7）

---

## 5. 新增 middleware

ZAINA 目前只有 `requireAuth` 一個 middleware，全部 `/api/...`（除 auth/session）都套用。新增 middleware 模式：

### 5.1 建檔 `api/src/middleware/<name>.ts`

```ts
import { createMiddleware } from 'hono/factory';
import type { AuthVariables } from './requireAuth.js';

export type RateLimitVariables = AuthVariables & {
  remainingQuota: number;
};

export const rateLimit = createMiddleware<{ Variables: RateLimitVariables }>(
  async (c, next) => {
    // 你的邏輯
    c.set('remainingQuota', 60);
    await next();
  },
);
```

### 5.2 套用

- 全 route 套：`postsRoutes.use('*', rateLimit);`
- 單 endpoint 套：`postsRoutes.post('/', rateLimit, zValidator(...), async (c) => {...});`

### 5.3 注意

- middleware 改 `c.set('xxx', ...)` 後需要在 `<Variables>` 型別宣告，否則 `c.var.xxx` TypeScript 抱怨。
- 中介必須 `await next()`，否則 handler 不會跑。
- 在 `requireAuth` 之後執行的 middleware 可以信任 `c.var.userId` / `c.var.user` 存在。

---

## 6. 新增 DB schema 變更

### 6.1 編輯 `api/prisma/schema.prisma`

新增 model 或欄位：

```prisma
model Notification {
  id        String   @id @default(uuid())
  userId    String
  type      String
  payload   Json
  readAt    DateTime?
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, createdAt])
}
```

### 6.2 產 migration

```bash
cd api
npm run prisma:migrate         # 等同 prisma migrate dev
# 系統會 prompt 取 migration 名稱，例：add_notification_table
```

→ 自動生成 `prisma/migrations/<timestamp>_add_notification_table/migration.sql`、套到本地 DB、產生 Prisma client。

### 6.3 commit

`prisma/migrations/` **必須提交到 git**。檔案命名格式 `YYYYMMDDHHMMSS_<snake_case>`，這是 Prisma 自動產的，不要手動改。

### 6.4 prod 套用

部署到 Cloud Run 之前在工作站跑：

```bash
DATABASE_URL="<neon-url>" npx prisma migrate deploy
```

`migrate deploy` 與 `migrate dev` 不同：deploy 不會 prompt、不會 reset、只跑未套用的 migration。

### 6.5 更新 seed（如需要）

`api/prisma/seed.ts` — 若新增固定資料（如新 channel），加進對應 array 後跑 `npm run prisma:seed`。注意 seed 中 `prisma.<table>.upsert` 是 idempotent，但**`prisma.post.deleteMany` + 重建 author 是「每次重跑會清光」**——測試環境跑 seed 前要警覺。

### 6.6 更新文件

- `docs/ARCHITECTURE.md` §7 schema 章節
- `docs/CHANGELOG.md` 加一列（migration name + 修改原因）
- 若新增是因為某個產品決策 → 寫 ADR

---

## 7. 寫 ADR（Architecture Decision Record）

ZAINA 已有 10 份 ADR 在 `docs/adr/`。新增規則：

- 編號**永遠 +1**（目前最新 0010，下個是 0011）。
- 檔名 `NNNN-kebab-case-title.md`。
- 結構（最薄版本）：
  ```markdown
  # 標題

  決定的事 — 一段話講完。

  ## Considered alternatives
  - 選項 A — 拒絕原因
  - 選項 B — 拒絕原因

  ## Trade-off accepted (optional)
  接受了什麼風險、為什麼可接受
  ```
- ADR 是**不可改寫**的決策快照。要修決策 → 寫一個新 ADR superseded 舊的。
- 任何看似違反直覺的程式（denormalised count、simulated verification、message_request 升級）都該有對應 ADR。

---

## 8. JSDoc / Dart doc 風格

ZAINA 預設 **不寫註解**。只在以下情況寫：

- WHY 不明顯：背後有不可見的不變式 / 過去的 bug 修復 / 業務規則限制
- 連結 ADR 或 CONTEXT
- 警告未來讀者「不要修這個地方」

範例（從現有程式擷取）：

#### TypeScript（block 註解，連結 ADR）

```ts
/**
 * Per ADR-0003: A may DM B if any of the following holds:
 *  - A commented on a Post authored by B
 *  - B commented on a Post authored by A
 *  - A and B both commented on the same Post
 *
 * The check runs against the `Comment` table; no eligibility table exists.
 * Block (either direction) severs eligibility unconditionally.
 */
export async function canDM(aId: string, bId: string): Promise<boolean> { ... }
```

#### TypeScript（行內註解，標未來修改）

```ts
// Per ADR-0004: review is simulated. The submission lands in the table
// with status 'approved' immediately, and the user is marked verified.
const result = await prisma.$transaction(async (tx) => { ... });
```

#### Dart（`///` doc comment）

```dart
/// Best-effort registration — silently no-ops on web / unsupported platforms.
Future<void> register() async { ... }
```

不要寫的：

- ❌ 重述 code 在做什麼（`// loop through users`）
- ❌ 寫「為了這次需求加的」（會 rot）
- ❌ 翻譯型別
- ❌ TODO / FIXME 散在程式碼 — 開 issue 或寫 plan

---

## 9. Lint / Format

### 9.1 API

- TypeScript `strict: true`、`noUncheckedIndexedAccess`、`noImplicitOverride`、`noFallthroughCasesInSwitch`。
- 沒裝 ESLint / Prettier — `tsc --noEmit` (`npm run typecheck`) 是唯一閘門。
- 風格：2-space indent，single quotes，trailing commas。仿現有檔案。

### 9.2 Mobile

- `analysis_options.yaml` 引 `flutter_lints` 預設規則。
- 跑 `flutter analyze` 檢查。
- 風格：dart 預設 2-space + dartfmt（IDE 自動格式化）。

---

## 10. Git workflow

### 10.1 Commit 訊息

Conventional commits：

| 前綴 | 用途 | 範例 |
|---|---|---|
| `feat:` | 新功能 | `feat: sprint 6 — DM with Socket.io` |
| `fix:` | bug 修復 | `fix(mobile): bigger text on hashtag chips` |
| `chore:` | 維護 / 不影響行為 | `chore(mobile): remove cup leading icon` |
| `docs:` | 文件 | `docs: refresh README / CLAUDE` |
| `refactor:` | 結構重整 | — |
| `test:` | 測試 | — |
| `perf:` | 效能 | `perf(mobile): smaller picsum so feed doesn't ANR` |

Scope 用 `(api)` / `(mobile)` / `(seed)` 等。

### 10.2 規矩

- **絕不 `--amend` 已 push 的 commit**。
- pre-commit hook 失敗 → 修問題 → 寫**新** commit（不要 amend）。
- Sprint 大功能：一個 PR；內部小 commit 自由。

---

## 11. 計畫歸檔流程（plans/ 目錄）

開發新功能或大型重構時，建立計畫文件來追蹤 user story → spec → tasks。完成後**移到 archive**。

### 11.1 建立計畫

```bash
# 命名：YYYY-MM-DD-feature-name.md
$EDITOR docs/plans/2026-05-10-group-chat.md
```

### 11.2 計畫文件結構

```markdown
# 群組聊天 (Group Chat)

## User Story
作為一個多人朋友群，我希望能在 ZAINA 內開群組聊天而不必跳到 LINE，
這樣討論旅伴 / 揪團可以連結到原本的貼文與留言上下文。

## Spec
- 對應 ADR：（若有 → 0011-group-chat.md）
- 影響領域：CONTEXT.md 加 `Group Conversation` 詞條
- DB：新表 `GroupConversation`、`GroupMember`、`Message.groupConversationId?`
- API：
  - POST /api/groups
  - POST /api/groups/:id/members
  - GET /api/groups/:id/messages
  - POST /api/groups/:id/messages
- Realtime：socket emit room: `group:<groupId>`
- UI：聊天列表新增分頁、群組設定畫面

## Tasks
- [ ] migration: add Group* tables
- [ ] API: POST /api/groups
- [ ] API: members add/remove
- [ ] API: messages send/receive
- [ ] socket: group:<id> room join
- [ ] mobile: 群組列表 UI
- [ ] mobile: 群組對話畫面
- [ ] tests: groups.test.ts
- [ ] docs/FEATURES.md / ARCHITECTURE.md / CHANGELOG.md
```

### 11.3 完成後歸檔

```bash
git mv docs/plans/2026-05-10-group-chat.md docs/plans/archive/2026-05-10-group-chat.md
```

並：

1. 更新 `docs/FEATURES.md`，加進功能總覽表 + 完整段落（端點 / 行為 / 業務邏輯）
2. 更新 `docs/CHANGELOG.md`，列出新增 endpoint / migration / UI changes
3. 對應 ADR（若有產生新決策）放 `docs/adr/`
4. 在 commit message 引用計畫檔名：`feat: ship group chat (plan: 2026-05-10-group-chat)`

### 11.4 取消的計畫

未實作就放棄的計畫：在檔案頂部加：

```markdown
> Status: ABANDONED 2026-XX-XX — 原因：xxx
```

並 git mv 到 `docs/plans/archive/`。保留紀錄能讓未來重啟時不需重新發明過已被否決的方案。

---

## 12. 對 AI 助手 / Claude Code 的建議

ZAINA 強烈仰賴 Claude Code 作 pair-programmer。守則：

1. 進專案先讀 [`../CLAUDE.md`](../CLAUDE.md) → `CONTEXT.md` → 對應 ADR。
2. 動 schema 之前先看 ADR-0006（denorm count）、ADR-0007（channel as table）、ADR-0008（user row eager create）。
3. 動 DM 之前先看 ADR-0003。
4. 動視覺之前**禁止 eyeball 顏色**，所有 hex 從 `lib/theme/zaina_theme.dart` / `docs/design/figma-tokens.md` 拿。
5. 寫新功能用 `/grill-with-docs` 預先過詞與 spec；用 `/tdd` 跑紅綠重構；用 `/to-issues` 拆 sprint。
6. 跨 sprint 大功能：先在 `docs/plans/` 寫計畫，跟著上面流程歸檔。

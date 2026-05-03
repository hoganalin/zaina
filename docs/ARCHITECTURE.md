# ARCHITECTURE.md

ZAINA 的系統結構。本文件聚焦於**新加入者「不知道就會踩坑」**的事實：跨模組的整合點、啟動流程、認證鏈路、資料庫 schema、第三方整合。**如果只看一份文件就要動程式，看這份。**

---

## 1. 系統整體圖

```
┌──────────────────────────┐    Bearer Firebase ID token     ┌──────────────────────────┐
│   Mobile (Flutter)       │  ─────────────────────────────► │   API (Cloud Run)        │
│                          │      HTTPS / REST               │                          │
│   Riverpod ─ dio         │                                 │   Hono + zod-validator   │
│   freezed models         │  ◄────── JSON envelopes ──────  │   Prisma (Postgres)      │
│   socket_io_client       │  ─────────────────────────────► │   Socket.io              │
│   firebase_messaging     │      auth: { token }            │   firebase-admin         │
└────────┬─────────────────┘                                 └──────────┬───────────────┘
         │                                                              │
         │  Google / Apple sign-in                                      │ verifyIdToken
         ▼                                                              ▼
┌──────────────────────────┐                                 ┌──────────────────────────┐
│   Firebase Auth          │                                 │   Neon Postgres          │
│   Cloud Messaging (FCM)  │  ◄── push send (best-effort) ── │   (managed, ap-east-1)   │
└──────────────────────────┘                                 └──────────────────────────┘
```

兩個雲端供應商：**GCP**（Cloud Run + Artifact Registry + Firebase）+ **Neon**（managed Postgres）。決策見 [ADR-0009](./adr/0009-cloud-run-and-neon.md)。

---

## 2. 目錄結構

```
zaina/
├── README.md                    對外入口（產品 / stack / Sprint roadmap）
├── CLAUDE.md                    AI 助手工作守則
├── CONTEXT.md                   領域語言（看這個再讀程式碼）
├── DEPLOY.md                    GCP Cloud Run 部署步驟
├── api.log / build.log          gcloud 部署留下的記錄（gitignored 不到位時會殘留）
│
├── api/                         Node.js + Hono + Prisma 後端
│   ├── package.json             scripts、依賴
│   ├── tsconfig.json            "strict": true、noUncheckedIndexedAccess、ES2022 + ESNext
│   ├── vitest.config.ts         fileParallelism: false（共用 Neon DB，不能平行）
│   ├── Dockerfile               3-stage：deps → build (prisma generate + tsc + prune) → runtime
│   ├── .env / .env.example      DATABASE_URL / FIREBASE_* / PORT
│   ├── .dockerignore
│   ├── prisma/
│   │   ├── schema.prisma        所有 models + enums + indexes
│   │   ├── seed.ts              12 channels / 12 interests / 5 seed authors / 36 posts
│   │   └── migrations/          3 個：init、add_fcm_token、add_username
│   ├── src/
│   │   ├── index.ts             啟動入口：serve(app.fetch) + attachSocketServer(http)
│   │   ├── app.ts               Hono 實例 + 11 個 route 掛載
│   │   ├── env.ts               zod 驗證 process.env（缺漏 process.exit(1)）
│   │   ├── db.ts                singleton PrismaClient
│   │   ├── firebase.ts          firebase-admin 初始化（service account 或 ADC）
│   │   ├── eligibility.ts       canDM(a, b) — ADR-0003 條件查詢
│   │   ├── blocks.ts            getBlockedCounterparts(userId) — symmetric block 集合
│   │   ├── push.ts              sendPush(userId, payload) — FCM、best-effort
│   │   ├── realtime.ts          Socket.io server + per-user room 加入
│   │   ├── middleware/
│   │   │   └── requireAuth.ts   解 Bearer + 比對 firebaseUid → User row
│   │   └── routes/
│   │       ├── auth.ts          POST /api/auth/session（唯一會 upsert User 的端點）
│   │       ├── me.ts            GET / PATCH /me、check-username、push-token、onboarding
│   │       ├── interests.ts     GET /interests
│   │       ├── channels.ts      GET / POST/DELETE /:id/follow
│   │       ├── feed.ts          GET /following（追蹤的看板）／GET /city
│   │       ├── posts.ts         GET/POST + like/unlike + comments
│   │       ├── users.ts         公開 profile + posts + block/unblock + follow/unfollow
│   │       ├── conversations.ts 列表 / 建立 / 取訊息 / 發訊息（含 message_request 升級）
│   │       ├── verifications.ts 上傳模擬通過（ADR-0004）
│   │       ├── notifications.ts 即時 ad-hoc 聚合四種來源
│   │       └── companions.ts    GET /daily — 同城／共同興趣推薦
│   ├── test/
│   │   ├── auth.session.test.ts
│   │   ├── channels.test.ts
│   │   ├── conversations.test.ts
│   │   ├── feed.test.ts
│   │   ├── interests.test.ts
│   │   ├── me.test.ts
│   │   ├── posts.test.ts
│   │   └── users.test.ts        共 48 cases，全部串真實 Neon DB
│   ├── scripts/
│   │   └── demo-token.ts        用 Firebase Admin 換 ID token 給 curl 測試
│   └── secrets/                 service account JSON（gitignored）
│
├── mobile/                      Flutter app
│   ├── pubspec.yaml             依賴 + assets
│   ├── analysis_options.yaml    flutter_lints
│   ├── README.md                Sign-in flow、平台特殊設定、route 表
│   ├── android/ ios/ web/       平台專案
│   ├── assets/illustrations/    splash 三杯插畫等 PNG
│   └── lib/
│       ├── main.dart            Firebase.initializeApp() → ProviderScope → MaterialApp.router
│       ├── router.dart          go_router + StatefulShellRoute（5 tabs + 8 top-level routes）
│       ├── theme/
│       │   └── zaina_theme.dart ZainaPalette（hex 直接從 Figma） + buildZainaTheme()
│       ├── api/                 dio 客戶端 + 各 endpoint API class
│       │   ├── dio_client.dart  singleton dio + _AuthInterceptor（Firebase ID token）
│       │   ├── chat_socket.dart Socket.io client + Stream<IncomingMessage>
│       │   ├── fcm_service.dart 註冊 / 解註冊 FCM token + foreground 訊息處理
│       │   ├── feed_api.dart    /api/feed/following + /city
│       │   ├── posts_api.dart   /api/posts/* + comments
│       │   ├── channels_api.dart /api/channels + follow toggle
│       │   ├── users_api.dart   /api/users/:id + block / follow
│       │   ├── conversations_api.dart /api/conversations
│       │   ├── notifications_api.dart /api/notifications
│       │   ├── companions_api.dart /api/companions/daily
│       │   ├── verifications_api.dart /api/verifications
│       │   └── onboarding_api.dart /api/me/onboarding（命名歷史殘餘；實際打 me）
│       ├── models/              freezed + json — 每個檔有對應的 .freezed.dart / .g.dart
│       │   ├── self_view.dart        登入後拿到的 user（無 firebaseUid）
│       │   ├── feed_post.dart        貼文 + author + channel + likedByMe
│       │   ├── comment.dart
│       │   ├── channel.dart          + isFollowing
│       │   ├── interest.dart
│       │   ├── companion.dart        夥伴推薦卡資料
│       │   ├── conversation.dart     列表 + 對方使用者 lite + lastMessage
│       │   ├── chat_message.dart
│       │   └── app_notification.dart 通知（4 種 type 的 union shape）
│       ├── widgets/
│       │   ├── zaina_logo.dart        在哪 logo + 「歡迎光臨」 signboard
│       │   ├── paper_background.dart  程式畫的紙紋
│       │   ├── sun_ray_background.dart 金色放射 + 珍奶杯印
│       │   └── signboard_card.dart    6 種貼文卡 template，依 post.id hash 輪
│       └── screens/             一個畫面一個資料夾，內含 widget + provider + state
│           ├── sign_in/         SignInScreen + AuthNotifier（authStateProvider）
│           ├── onboarding/
│           ├── shell/           shell_scaffold（5 cup-tab bottom nav）
│           ├── feed/            FeedScreen — 2 tab（所有話題 / 同城）+ 看板按鈕 + FAB
│           ├── compose/
│           ├── post_detail/     貼文詳情 + 評論 + like
│           ├── channels/
│           ├── companions/
│           ├── notifications/
│           ├── conversations/   list + chat 二畫面
│           ├── profile/         自己 / 別人 + edit profile
│           └── verification/
│
├── infra/
│   └── docker-compose.yml       Postgres 16-alpine（zaina/zaina/zaina:5432）
│
└── docs/
    ├── README.md                文件索引
    ├── ARCHITECTURE.md          （本檔）
    ├── DEVELOPMENT.md
    ├── FEATURES.md
    ├── TESTING.md
    ├── CHANGELOG.md
    ├── plans/                   進行中計畫
    │   └── archive/             完成歸檔
    ├── adr/                     10 個架構決策（0001–0010）
    ├── design/
    │   ├── figma-tokens.md
    │   ├── visual-spec.md
    │   └── reference/           PNG 匯出
    └── demo-60s-script.md
```

> ⚠️ **API 目錄夾雜檔案**：`api/` 底下有一批 `classes*.dex`、`AndroidManifest.xml`、`*.proto`、`META-INF/`、`kotlin/`、`lib/` — 這些是**過去某次 APK 解包誤倒在這裡的殘留**，不是後端原始碼。實際後端只看 `src/`、`prisma/`、`test/`、`scripts/`、`package.json`、`Dockerfile`、`tsconfig.json`、`vitest.config.ts`、`.env*`、`.dockerignore`。Build / Docker 都只跑 `src/` 與 `prisma/`，所以雜檔不會進到 image。

---

## 3. 啟動流程

### 3.1 API 啟動（`src/index.ts`）

順序非常重要，理解一次永遠不踩雷：

```ts
import './firebase.js';                  // 1. firebase-admin initializeApp() — 在任何 getAuth()/getMessaging() 之前
import { serve } from '@hono/node-server';
import { app } from './app.js';          // 2. 11 個 route 都在這裡掛上去
import { loadEnv } from './env.js';      // 3. zod 驗 env，缺東西直接 process.exit(1)
import { attachSocketServer } from './realtime.js';

const env = loadEnv();                   // 缺 DATABASE_URL 時 server 不會起
const server = serve({ fetch: app.fetch, port: env.PORT });
attachSocketServer(server as unknown as HttpServer);   // 4. Socket.io 共用同一個 HTTP server
```

### 3.2 firebase.ts 初始化邏輯

```ts
if (getApps().length === 0) {
  if (FIREBASE_SERVICE_ACCOUNT_PATH) {
    initializeApp({ credential: cert(JSON.parse(readFileSync(path))) });
  } else {
    initializeApp();   // Cloud Run / Cloud Functions 走 ADC（ambient credentials）
  }
}
```

→ 本機開發**必須**設 `FIREBASE_SERVICE_ACCOUNT_PATH`，指向下載的 service account JSON。Cloud Run 上不需要設，因為平台會注入 ADC。

### 3.3 env.ts 的 zod schema

```ts
DATABASE_URL: z.string().url(),                 // 必填
PORT: z.coerce.number().int().positive().default(3000),
FIREBASE_SERVICE_ACCOUNT_PATH: z.string().optional(),
FIREBASE_PROJECT_ID: z.string().optional(),
NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
```

`safeParse` 失敗時印出**每個欄位的錯誤路徑**並 exit 1。這是 server 起不來最常見的原因。

### 3.4 Mobile 啟動（`mobile/lib/main.dart`）

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();           // 必須在 runApp 之前
runApp(const ProviderScope(child: ZainaApp()));   // Riverpod 容器
```

`ZainaApp` 是 `ConsumerWidget`，`build()` 讀 `routerProvider`，回傳 `MaterialApp.router(...)`。Theme 透過 `buildZainaTheme()`（`lib/theme/zaina_theme.dart`）注入。

### 3.5 Mobile 路由與重定向（`mobile/lib/router.dart`）

```dart
redirect: (context, state) {
  final user = ref.read(authStateProvider).valueOrNull;
  final loc = state.matchedLocation;

  if (user == null)                                  return loc == '/sign-in' ? null : '/sign-in';
  if (!user.onboardingCompleted)                     return loc == '/onboarding' ? null : '/onboarding';
  if (loc == '/sign-in' || loc == '/onboarding')     return '/feed';
  return null;
}
```

→ **三層 gate**：未登入 → /sign-in；登入但 onboarding 未完成 → /onboarding；其他都 OK。`refreshListenable` 監聽 `authStateProvider`，登入／登出立即重新評估。

---

## 4. API 路由總覽

App 入口統一在 `src/app.ts`：

```ts
app.get('/', ...)          // {name: 'zaina-api', status: 'ok'} — 首頁不認證
app.get('/health', ...)    // {status: 'ok', timestamp} — Cloud Run health check
app.route('/api/auth', authRoutes);
app.route('/api/me', meRoutes);
app.route('/api/interests', interestsRoutes);
app.route('/api/channels', channelsRoutes);
app.route('/api/feed', feedRoutes);
app.route('/api/posts', postsRoutes);
app.route('/api/users', usersRoutes);
app.route('/api/conversations', conversationsRoutes);
app.route('/api/verifications', verificationsRoutes);
app.route('/api/notifications', notificationsRoutes);
app.route('/api/companions', companionsRoutes);
```

| Method | Path | 檔案 | 認證 | 說明 |
|---|---|---|---|---|
| GET | `/` | `app.ts` | ❌ | `{name:"zaina-api",status:"ok"}` |
| GET | `/health` | `app.ts` | ❌ | health check（Cloud Run 預設） |
| POST | `/api/auth/session` | `routes/auth.ts` | Bearer **without** middleware | 自己驗 token；upsert User row；回 self-view |
| GET | `/api/me` | `routes/me.ts` | ✅ | 回前 `c.var.user` 的 self-view |
| PATCH | `/api/me` | `routes/me.ts` | ✅ | 部分編輯（zod strict）；改 username 撞號回 409 |
| GET | `/api/me/check-username` | `routes/me.ts` | ✅ | `?u=...`；回 `{available, reason?}` |
| PATCH | `/api/me/onboarding` | `routes/me.ts` | ✅ | nickname/...必填；transaction 重寫 UserInterest+ChannelFollow |
| PATCH | `/api/me/push-token` | `routes/me.ts` | ✅ | 寫入或清空 `User.fcmToken` |
| GET | `/api/interests` | `routes/interests.ts` | ✅ | 全部 interests，按 category+name |
| GET | `/api/channels` | `routes/channels.ts` | ✅ | 全部 channels + `isFollowing` |
| POST | `/api/channels/:id/follow` | `routes/channels.ts` | ✅ | upsert ChannelFollow（idempotent） |
| DELETE | `/api/channels/:id/follow` | `routes/channels.ts` | ✅ | deleteMany（idempotent） |
| GET | `/api/feed/following` | `routes/feed.ts` | ✅ | 追蹤的看板的貼文，limit/offset、排除 blocked |
| GET | `/api/feed/city` | `routes/feed.ts` | ✅ | `post.city == user.city` 的貼文，無 city 回空 |
| POST | `/api/posts` | `routes/posts.ts` | ✅ | zod 驗 channelId/title/body/city/country/imageUrl? |
| GET | `/api/posts/:id` | `routes/posts.ts` | ✅ | 含 channel/author/likedByMe |
| POST | `/api/posts/:id/like` | `routes/posts.ts` | ✅ | transaction：PostLike + likeCount++（idempotent） |
| DELETE | `/api/posts/:id/like` | `routes/posts.ts` | ✅ | transaction：PostLike 刪除 + likeCount-- |
| GET | `/api/posts/:id/comments` | `routes/posts.ts` | ✅ | asc 順序，含 author lite |
| POST | `/api/posts/:id/comments` | `routes/posts.ts` | ✅ | transaction：寫評論 + commentCount++ |
| GET | `/api/users/:id` | `routes/users.ts` | ✅ | 公開資料（無 firebaseUid）+ postCount/followerCount/followingCount/isFollowing |
| GET | `/api/users/:id/posts` | `routes/users.ts` | ✅ | 該作者貼文 + likedByMe |
| POST | `/api/users/:id/block` | `routes/users.ts` | ✅ | 拒自己；upsert Block |
| DELETE | `/api/users/:id/block` | `routes/users.ts` | ✅ | deleteMany |
| POST | `/api/users/:id/follow` | `routes/users.ts` | ✅ | upsert UserFollow |
| DELETE | `/api/users/:id/follow` | `routes/users.ts` | ✅ | deleteMany |
| GET | `/api/conversations` | `routes/conversations.ts` | ✅ | 列出我參與的對話 + lastMessage |
| POST | `/api/conversations` | `routes/conversations.ts` | ✅ | userId；既存則回；不符 ADR-0003 → 403 |
| GET | `/api/conversations/:id/messages` | `routes/conversations.ts` | ✅ | asc 順序，非參與者 → 403 |
| POST | `/api/conversations/:id/messages` | `routes/conversations.ts` | ✅ | 寫訊息 + 升級 message_request→active + emit + push |
| POST | `/api/verifications` | `routes/verifications.ts` | ✅ | identityType+imageUrl；transaction 寫入 + isVerified=true |
| GET | `/api/verifications/me` | `routes/verifications.ts` | ✅ | 我的所有 verification 紀錄 |
| GET | `/api/notifications` | `routes/notifications.ts` | ✅ | 4 來源混排，30 天內、cap 50 |
| GET | `/api/companions/daily` | `routes/companions.ts` | ✅ | 同城／共同興趣推薦，limit≤20，預設 10 |

### 4.1 認證機制（`src/middleware/requireAuth.ts`）

```ts
export const requireAuth = createMiddleware<{ Variables: AuthVariables }>(async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader) return c.json({ error: 'unauthorized' }, 401);
  const token = authHeader.replace(/^Bearer\s+/, '');

  let decoded;
  try {
    decoded = await getAuth().verifyIdToken(token);   // firebase-admin
  } catch {
    return c.json({ error: 'unauthorized' }, 401);
  }

  const user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });
  if (!user) return c.json({ error: 'unauthorized' }, 401);   // ADR-0008：必須先打 /api/auth/session

  c.set('userId', user.id);
  c.set('user', user);
  await next();
});
```

關鍵事實：

- **唯一會建立 User row 的端點是 `POST /api/auth/session`**。任何被 `requireAuth` 保護的端點，如果 firebaseUid 對應不到 User，回 401（不會自動建立）。對應 ADR-0008。
- 所有 `/api/...` route（除 `/api/auth/session`）都套了 `routes.use('*', requireAuth)`。
- Hono `c.var.user` 是完整 Prisma `User` 物件（包含 firebaseUid）；`c.var.userId` 是字串。`stripFirebaseUid()` helper 在 `me.ts` 用來輸出時剔除 firebaseUid。
- **JWT 是 Firebase 簽的 ID token**，由 client 每次 request 取得。沒有 server 自簽 JWT。Token 過期由 Firebase SDK 處理（mobile 端 `user.getIdToken()` 自動 refresh）。
- **Token 有效期：1 小時**（Firebase 預設）。Mobile dio 的 interceptor 每次發送都呼叫 `getIdToken()`，所以總是新鮮。

### 4.2 統一回應格式

API 沒有統一的 envelope，**但每個資源型 endpoint 都把資料包在「資源名稱」key 下**，方便日後加 metadata：

```jsonc
// GET /api/me
{ "user": { "id": "...", "nickname": "...", ... } }

// GET /api/feed/following
{ "posts": [...], "nextOffset": 20 }   // 沒下一頁時 nextOffset: null

// GET /api/posts/:id
{ "post": { ... } }

// GET /api/posts/:id/comments
{ "comments": [...], "nextOffset": null }

// POST /api/posts/:id/like
{ "likeCount": 1, "likedByMe": true }   // 寫操作的薄回應

// 錯誤
{ "error": "unauthorized" }              // 401
{ "error": "not_found" }                  // 404
{ "error": "forbidden" }                  // 403
{ "error": "not_eligible" }               // 403（ADR-0003 阻擋）
{ "error": "username_taken" }             // 409
{ "error": "invalid_channel_id" }         // 400
{ "error": "cannot_block_self" }          // 400
{ "error": "cannot_dm_self" }             // 400
{ "error": "cannot_follow_self" }         // 400
{ "error": "invalid_interest_id" }        // 400
```

→ Mobile 端 freezed model 對應「資源名稱 key」逐一解；錯誤回應由 dio 拋例外（`DioException`），上層 try/catch 後決定 UI。

### 4.3 分頁規則

所有 list endpoint：

```ts
const paginationSchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
```

- `feed.ts`：limit max 50, default 20。
- `posts.ts` 評論：limit max 100, default 50。
- `companions.ts`：limit max 20, default 10。
- 取 `limit + 1` 件來判斷是否有下一頁，回 `nextOffset` 或 `null`。

---

## 5. Socket.io 即時層（`src/realtime.ts`）

```ts
io.use(async (socket, next) => {
  const token = socket.handshake.auth?.token;             // mobile 端 setAuth({token})
  const decoded = await getAuth().verifyIdToken(token);
  const user = await prisma.user.findUnique({ where: { firebaseUid: decoded.uid } });
  socket.data.userId = user.id;
  next();
});

io.on('connection', (socket) => {
  socket.join(`user:${socket.data.userId}`);              // 一個 user 一個 room
});

export function emitToUser(userId, event, payload) {
  io?.to(`user:${userId}`).emit(event, payload);
}
```

- 訊息送出時，`conversations.ts` 呼叫 `emitToUser(otherUserId, 'message:new', {conversationId, message})`。
- Mobile `chat_socket.dart` 訂閱 `message:new`，把 payload 解成 `IncomingMessage` 推到 broadcast `Stream`，再由聊天畫面 / 通知畫面消費。
- Socket.io transport 預設 polling+websocket；mobile 端強制 `setTransports(['websocket'])`。

---

## 6. 推播（`src/push.ts`）

```ts
export async function sendPush(userId, payload) {
  const user = await prisma.user.findUnique({ where: {id: userId}, select: {fcmToken: true} });
  if (!user?.fcmToken) return;                            // best-effort：沒 token silently no-op
  await getMessaging().send({
    token: user.fcmToken,
    notification: { title, body },
    data,                                                  // string-only key/value
  });
  // catch 都吞掉並 console.warn — 不能阻塞主流程
}
```

呼叫點：DM 寫入後（`conversations.ts:186`），新評論 / 新追蹤者目前不觸發 push（依 README「Future」清單，這些只在 `/api/notifications` 端輪詢）。

---

## 7. 資料庫 Schema

來自 `api/prisma/schema.prisma`。每個欄位的型別、約束、index 都列出來。

### 7.1 Enums

| Enum | 值 |
|---|---|
| `Gender` | `male`, `female`, `non_binary` |
| `VerificationStatus` | `pending`, `approved`, `rejected` |
| `IdentityType` | `student`, `employee` |
| `InterestCategory` | `active`, `static` |
| `ConversationStatus` | `message_request`, `active` |

### 7.2 Models

#### User

| 欄位 | 型別 | 約束 |
|---|---|---|
| `id` | String | PK，UUID |
| `firebaseUid` | String | **UNIQUE** — 對應 Firebase 身份 |
| `nickname` | String | 必填，登入時 `displayName ?? '新朋友'` |
| `username` | String? | UNIQUE（add_username migration） — 3–20 chars `[a-zA-Z0-9_]` |
| `gender` | Gender? | onboarding 填 |
| `country` | String? | onboarding 填 |
| `city` | String? | onboarding 填，drives 同城 feed |
| `avatarUrl` | String? | — |
| `bio` | String? | max 500 chars（zod） |
| `isVerified` | Boolean | default false；驗證通過後 true |
| `onboardingCompleted` | Boolean | default false；onboarding 結束後 true |
| `fcmToken` | String? | add_fcm_token migration；FCM 推播用 |
| `createdAt` | DateTime | default now |

關係：`posts`、`comments`、`postLikes`、`interests`（UserInterest）、`followedChannels`（ChannelFollow）、`followers`/`following`（UserFollow，雙向 relation name）、`conversationsAsA`/`asB`、`messagesSent`、`blocksMade`/`blocksReceived`、`verifications`。

#### Verification

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `userId` | String FK→User，onDelete: Cascade |
| `identityType` | `student` \| `employee` |
| `imageUrl` | String — 預期 GCS signed URL（私有 bucket） |
| `status` | default `pending` — **ADR-0004：實際路由直接寫 `approved`** |
| `reviewedAt` | DateTime? |
| `createdAt` | DateTime |

#### Channel

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `slug` | String UNIQUE — `rent`, `secondhand`, `food`, ... |
| `name` | String — 顯示用中文「租屋」 |
| `description` | String? |
| `icon` | String? — emoji，例 `🏠` |
| `sortOrder` | Int default 0 |
| `createdAt` | DateTime |

種子在 `prisma/seed.ts`，12 個 channel（ADR-0007 解釋為何用 table 而非 enum）。

#### Post

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `authorId` | String FK→User，Cascade |
| `channelId` | String FK→Channel |
| `title` | String — 1–120 chars（zod） |
| `body` | String — 1–2000 chars |
| `city` | String — 1–80 chars，預設使用者 city，可覆蓋 |
| `country` | String — 1–80 chars |
| `imageUrl` | String? |
| `viewCount` | Int default 0（**目前未在程式裡 increment**，預留欄位） |
| `likeCount` | Int default 0 — denormalized（ADR-0006） |
| `commentCount` | Int default 0 — denormalized |
| `createdAt` | DateTime |

Indexes：`@@index([channelId, createdAt])`、`@@index([city, createdAt])` — 兩個 feed 的查詢路徑都打到。

#### Comment

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `postId` | String FK→Post Cascade |
| `authorId` | String FK→User Cascade |
| `body` | String — max 1000 chars（zod） |
| `createdAt` | DateTime |

Indexes：`@@index([postId, createdAt])`、`@@index([authorId])`。

#### Interest

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `slug` | String UNIQUE |
| `name` | String |
| `category` | `active` \| `static` |

12 個種子。

#### UserInterest（多對多）

```
@@id([userId, interestId])
```

#### ChannelFollow（多對多）

```
@@id([userId, channelId]) + createdAt
```

#### PostLike（多對多 + denormalized 計數來源）

```
@@id([userId, postId]) + createdAt
```

#### UserFollow（單向）

```
followerId, followingId, createdAt
@@id([followerId, followingId])
```

雙 relation name：`UserFollowFollower`（誰在追蹤）、`UserFollowFollowing`（被追蹤的人）。

#### Conversation

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `userAId` | String FK — **always the smaller UUID**（程式碼強制） |
| `userBId` | String FK — always the larger |
| `status` | default `message_request`，B 首次回覆後升 `active` |
| `lastMessageAt` | DateTime — 排序用 |
| `createdAt` | DateTime |

Unique：`@@unique([userAId, userBId])` — 一對 user 至多一條對話。`orderUserPair(a, b)` 在 `eligibility.ts` 強制排序。

#### Message

| 欄位 | 型別 |
|---|---|
| `id` | String PK |
| `conversationId` | String FK Cascade |
| `senderId` | String FK→User Cascade |
| `body` | String — 1–2000 chars |
| `readAt` | DateTime? — **目前未實作讀取狀態 update** |
| `createdAt` | DateTime |

Index：`@@index([conversationId, createdAt])`。

#### Block

```
blockerId, blockedId, createdAt
@@id([blockerId, blockedId])
```

對稱：`getBlockedCounterparts(userId)` 回 union（不分方向）。

### 7.3 Migrations

- `20260501011145_init` — 全部表的初始建立。
- `20260502035709_add_fcm_token` — `User.fcmToken TEXT NULL`。
- `20260503010000_add_username` — `User.username TEXT NULL` + UNIQUE INDEX。

新增 migration 用 `npm run prisma:migrate`（內部 `prisma migrate dev`）。

---

## 8. 第三方整合

### 8.1 Firebase Auth（client + server）

- **Client 流程**（`mobile/lib/screens/sign_in/auth_providers.dart`）：
  1. `GoogleSignIn().signIn()` 或 `SignInWithApple.getAppleIDCredential(...)`
  2. `FirebaseAuth.signInWithCredential(...)` 把第三方 credential 換成 Firebase 身份
  3. `dio.post('/api/auth/session')` — interceptor 自動帶 `Authorization: Bearer <id_token>`
  4. 後端 `getAuth().verifyIdToken(token)`，upsert User row，回 self-view
  5. Riverpod state 變更觸發 router 重定向
- **Token refresh**：`FirebaseAuth.instance.currentUser?.getIdToken()` 每次都拿最新（內部會 refresh），dio interceptor 在每個 request 之前呼叫一次。
- **Apple sign-in 限 iOS**，需 Apple Developer 帳號 + Service ID。
- **Facebook 按鈕僅佔位**（ADR-0010 — 需要 Facebook Developer App + key-hash + Firebase Console provider，全部 user-side）。

### 8.2 Firebase Cloud Messaging（FCM）

- 註冊（`mobile/lib/api/fcm_service.dart`）：登入後 `register()`，取 token → `PATCH /api/me/push-token` 寫進 `User.fcmToken`。也訂 `onTokenRefresh` 與 `onMessage`。
- 解註冊：登出時 `PATCH /api/me/push-token` 設成 null。
- 發送（`api/src/push.ts`）：`getMessaging().send({token, notification, data})`，所有錯誤吞掉只 `console.warn`。
- 觸發點：目前只有 DM 收到時（`conversations.ts:186`）。新評論／新追蹤者僅靠 `/api/notifications` 輪詢。

### 8.3 Google Cloud Storage（私有 bucket）

ADR-0004 規定：學生／員工證上傳的圖片放**私有 GCS bucket**，API 簽 short-lived URL。`api/.env.example` 預留 `GCS_BUCKET_ID_IMAGES=""`，**v1 程式並未實作上傳路徑**（`/api/verifications` body 直接收 `imageUrl: z.string().url()`，只做型別檢查）。Mobile 端目前沿用 picker 拿到的本地 URI 替代示意。實裝為 future work。

### 8.4 Neon Postgres

- 連線字串放 `DATABASE_URL`。
- Cloud Run deploy 時透過 Secret Manager 注入：`--set-secrets="DATABASE_URL=database-url:latest"`（見 `DEPLOY.md`）。
- 跨雲延遲 30–80ms / query；feed 在 denormalized count 下單查仍 < 300ms RTT。
- 連線池：Prisma 預設池大小 = `2 * num_physical_cpus`，Cloud Run 0.5 vCPU 只有 1 連線。Neon 提供 pooler endpoint，建議 prod 用 pooler URL。

### 8.5 GCP Cloud Run

- 部署：`docker build` 推 Artifact Registry → `gcloud run deploy --image=...`。
- 重點：`--allow-unauthenticated`（auth 在 app 層處理）+ `--min-instances=0`（scale-to-zero，cold start 1–2s）。
- 詳細指令見 `../DEPLOY.md`。

---

## 9. 資料流（讀／寫場景）

### 9.1 載入動態（讀路徑）

```
Flutter FeedScreen
  → ref.watch(feedFollowingProvider)
  → FeedApi.fetchFollowing(limit, offset)
  → dio.get('/api/feed/following', queryParameters)
    [ interceptor 加上 Authorization: Bearer <Firebase ID token> ]
  → Hono GET /api/feed/following
    requireAuth middleware:
      verifyIdToken → user lookup → c.set
    handler:
      ChannelFollow find → channelIds
      blocks.getBlockedCounterparts(userId)
      Post.findMany({ channelId IN, authorId NOT IN blocked }, take: limit+1, skip: offset)
      annotateLikedByMe(posts, userId)   // PostLike batch lookup
    → 200 { posts: [...], nextOffset }
  ← FeedPost.fromJson list（freezed）
  ← FutureProvider 回應，Riverpod 觸發 rebuild
```

### 9.2 發送 DM（寫路徑 + 升級狀態 + emit + push）

```
Flutter ChatScreen
  → ConversationsApi.sendMessage(conversationId, body)
  → dio.post('/api/conversations/:id/messages', {body})
  → Hono POST /api/conversations/:id/messages
    requireAuth
    handler:
      conv = findUnique({id})；checks userAId/userBId 含 me
      狀態判斷：
        if conv.status === 'message_request'
          且 sender 之前沒在這對話發過訊息
          且 conversation 內已有訊息（對方先發過）
          → willPromote = true
      prisma.$transaction:
        Message.create
        Conversation.update({lastMessageAt, [status: active 若 willPromote]})
      emitToUser(otherUserId, 'message:new', {conversationId, message})
      sendPush(otherUserId, {title: sender.nickname, body: body.slice(80)})  // 不 await
    → 201 { message }
  Mobile 收到回應後 optimistic 已上 UI；對方端：
  Socket connection 觸發 'message:new' → IncomingMessage 進 broadcast Stream
    → ConversationsScreen / ChatScreen 各自監聽，對應更新
  對方背景時 FCM 顯示通知；點擊跳到 /chat/:conversationId
```

### 9.3 留言觸發 DM 解鎖（ADR-0003 流程）

```
A 在 B 的貼文留言（POST /api/posts/:id/comments）
  Comment.create + Post.update commentCount++（同 transaction）
A 在 ChatScreen 嘗試開 DM（POST /api/conversations {userId: B.id}）
  canDM(A, B)：
    block? → false
    A→B post comment exists? → 是 → true
  Conversation.create(status='message_request')
A 發送第一封訊息 → status 維持 message_request
B 在 訊息 tab 看到「訊息邀請」徽章
B 點開回覆 → handler 偵測 willPromote=true → status='active'
往後 A 與 B 的對話正常呈現於主訊息列表
```

---

## 10. 關鍵不變式 / 容易踩雷處

1. **一個 firebaseUid 對到一個 User row**（ADR-0008）。任何「找不到 User」時不要 silent create — `requireAuth` 直接 401。
2. **denormalised count 必須在同一個 `prisma.$transaction` 內更新**（ADR-0006）。看似多餘的 transaction 不能拆。
3. **Conversation 的 (userAId, userBId) 永遠 a < b**（`orderUserPair` 強制）。直接 `findFirst({OR: ...})` 也能找到，但建立／upsert 必須先排序，否則撞 unique。
4. **`requireAuth` 之外只有 `/api/auth/session` 可以建立 User**。把建立邏輯放別地會破壞 ADR-0008 的承諾。
5. **Block 對稱**：`getBlockedCounterparts(userId)` 回的集合在 feed / DM eligibility 都要排除。
6. **Mobile feed 的 `Image.network` 必須帶 `cacheWidth/cacheHeight`**（見 mobile/README.md），否則 36 張原圖會 ANR。
7. **vitest fileParallelism = false**（vitest.config.ts）—— 測試共用一個 Neon DB，平行會 race。
8. **`api/` 目錄裡的 dex / proto / META-INF 是雜檔**，不要當原始碼讀。`Dockerfile` 只 `COPY . .` 後 `npm run build`，雜檔會進 image 但不影響執行（dist/ 才是 entrypoint）。如果未來要清理可以加進 `.dockerignore` 並從 git 移除。

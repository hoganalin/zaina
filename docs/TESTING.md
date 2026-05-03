# TESTING.md

ZAINA 的測試規範與實作手冊。

---

## 1. 測試現況

- **API**：vitest 8 個檔案、48 個測試 case，全部串**真實 Neon DB**（fileParallelism=false）。
- **Mobile**：尚未撰寫 widget / unit tests（v1 portfolio 範圍內捨棄；ADR-0005）。

```bash
cd api
npm test                       # 一次跑完
npm run test:watch             # vitest watch
```

CI 上不要忘了設 `DATABASE_URL`（Neon test branch 為佳）。

---

## 2. 測試檔案表

| 檔案 | 測試對象 | Case 數（粗估） |
|---|---|---|
| `test/auth.session.test.ts` | `POST /api/auth/session`：401 / 找不到 token / 第一次登入 / 重複登入 idempotent | 4 |
| `test/me.test.ts` | `GET/PATCH /api/me` + `PATCH /api/me/onboarding`：401 / strict 拒未知欄位 / 部分更新 / onboarding transaction / 重送 idempotent / 不存在的 interest 回 400 | 7+ |
| `test/feed.test.ts` | `GET /api/feed/following` + `/city`：401 / 空集合 / 過濾 channel 與 city / 排序 desc / 分頁 | 5+ |
| `test/posts.test.ts` | `POST /api/posts` + `GET/POST/DELETE like` + comments：建立 / 不存在 channel 400 / 404 / likedByMe 反映狀態 / like idempotent / commentCount 增量 / asc 排序 | 9+ |
| `test/channels.test.ts` | `GET /api/channels` + `POST/DELETE /:id/follow`：401 / isFollowing 標籤 / follow idempotent / unfollow idempotent / 404 | 5 |
| `test/interests.test.ts` | `GET /api/interests`：401 / 回 seeded 資料 | 2 |
| `test/users.test.ts` | `GET /api/users/:id` + `/:id/posts`：404 / 公開 profile（無 firebaseUid）+ postCount / 該作者 posts + likedByMe | 3 |
| `test/conversations.test.ts` | DM 全流程：cannot_dm_self / not_eligible / 建立 / idempotent / 非參與者擋下 403 / message_request → active 升級 / 排序 / list | 8+ |

對應檔案的程式碼見 `api/src/routes/<resource>.ts`。

---

## 3. 為什麼共用一個 DB？

`vitest.config.ts`：

```ts
fileParallelism: false,           // 檔案間序列跑
testTimeout: 15000,                // Neon cold start + 多步 prisma transaction
env: loadEnv(mode, process.cwd(), ''),
```

- 每個檔案在 `beforeEach` / `afterAll` 用獨特 firebaseUid prefix 清理（例：`firebase-uid-posts-test`），避免互相污染。
- **不能改成平行** — 多個檔案同時對 `prisma.user.create({firebaseUid: TEST_UID})` 寫入會撞 unique。

---

## 4. 測試的兩個結構性決定

### 4.1 串真實 DB 而非 mock Prisma

> 「mock 過的測試常常通過、但真上 prod 一跑 schema 不一致就炸。我們吃過這虧。」（DEVELOPMENT.md 風格 feedback memory 的精神）

- 測試直接打 Neon，所有 schema 變更會自動被 migration 涵蓋。
- 速度成本：48 cases ~30s（含 Neon cold start）。可接受。
- 替代：用 SQLite + schema 同步 — 拒絕，因為 Postgres-specific（`@@unique` 行為、`citext` 等）跑不出真行為。

### 4.2 mock `firebase-admin/auth`

唯一被 mock 的是 Firebase token 驗證。原因：跑測試不可能真的拿一個有效 ID token。模式：

```ts
const { verifyIdTokenMock } = vi.hoisted(() => ({ verifyIdTokenMock: vi.fn() }));

vi.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken: verifyIdTokenMock }),
}));

// 注意：vi.mock 必須在 import app 之前定義
const { app } = await import('../src/app.js');
const { prisma } = await import('../src/db.js');
```

**為什麼用 `vi.hoisted`**：因為 `vi.mock` 會被提升到頂部執行，但被 mock 的函式引用必須先存在。`hoisted()` 確保 `verifyIdTokenMock` 在 hoist 階段已建立。

每個測試開頭：

```ts
verifyIdTokenMock.mockReset();
verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });   // 單次
// 或
verifyIdTokenMock.mockResolvedValue({ uid: TEST_UID });       // 整段
```

接著用 dummy `Authorization: Bearer t`（後端會 replace `Bearer ` 並把剩字串丟進 mock）。

---

## 5. Hono `app.request()` 

vitest 不啟動 HTTP server — 改用 Hono 內建的 `app.request()` 在 process 內模擬 Web Fetch API request：

```ts
const res = await app.request('/api/posts', {
  method: 'POST',
  headers: { Authorization: 'Bearer t', 'Content-Type': 'application/json' },
  body: JSON.stringify({ ... }),
});
expect(res.status).toBe(201);
const body = (await res.json()) as { post: Record<string, unknown> };
```

優點：

- 沒有 port 衝突
- middleware 與 zod validator 都會被執行
- response 是 standard `Response` 物件

缺點：

- 不會驗 Socket.io 行為（realtime 的測試需要起真實 server，目前沒做）

---

## 6. 測試輔助函式

### 6.1 共用模式

每個檔案頂部：

```ts
const TEST_UID = 'firebase-uid-<resource>-test';

async function authedUser() {
  return prisma.user.create({
    data: { firebaseUid: TEST_UID, nickname: 'Test', onboardingCompleted: true },
  });
}

beforeEach(async () => {
  verifyIdTokenMock.mockReset();
  await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
});

afterAll(async () => {
  await prisma.user.deleteMany({ where: { firebaseUid: TEST_UID } });
  await prisma.$disconnect();
});
```

> ⚠️ `prisma.user.deleteMany` 透過 cascade 連帶清掉該 user 的 posts / comments / likes / channelfollows / userinterests。其他資源（channel / interest）為共用 seed，不要刪。

### 6.2 conversations.test.ts 特殊輔助

```ts
async function makeAEligibleByCommentingOnBPost(aId: string, bId: string) {
  const channel = await prisma.channel.findFirst();
  const post = await prisma.post.create({
    data: { authorId: bId, channelId: channel!.id, title: 'B post', body: 'b', city: 'Tokyo', country: 'Japan' },
  });
  await prisma.comment.create({ data: { postId: post.id, authorId: aId, body: 'A comment' } });
}
```

→ 模擬 ADR-0003 條件之一：A 在 B 的 post 留言。後續 `canDM(A, B)` 才會 true。

---

## 7. 寫一個新測試的步驟

### 7.1 範例：新增 share endpoint 的測試

假設已實作 `POST /api/posts/:id/share`（見 DEVELOPMENT.md §4）。

#### 步驟 1：在 `posts.test.ts` 新增 describe block

```ts
describe('share', () => {
  async function setupPost() {
    const user = await authedUser();
    const channel = await prisma.channel.findFirst();
    const post = await prisma.post.create({
      data: {
        authorId: user.id,
        channelId: channel!.id,
        title: 'share-test',
        body: 'b',
        city: 'Tokyo',
        country: 'Japan',
      },
    });
    return { user, post };
  }

  it('returns 200 on valid share request', async () => {
    const { post } = await setupPost();
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(`/api/posts/${post.id}/share`, {
      method: 'POST',
      headers: { Authorization: 'Bearer t', 'Content-Type': 'application/json' },
      body: JSON.stringify({ channel: 'line' }),
    });
    expect(res.status).toBe(200);
  });

  it('returns 404 for unknown post', async () => {
    await authedUser();
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(
      '/api/posts/00000000-0000-0000-0000-000000000000/share',
      {
        method: 'POST',
        headers: { Authorization: 'Bearer t', 'Content-Type': 'application/json' },
        body: JSON.stringify({ channel: 'line' }),
      },
    );
    expect(res.status).toBe(404);
  });

  it('rejects unknown channel value with 400', async () => {
    const { post } = await setupPost();
    verifyIdTokenMock.mockResolvedValueOnce({ uid: TEST_UID });

    const res = await app.request(`/api/posts/${post.id}/share`, {
      method: 'POST',
      headers: { Authorization: 'Bearer t', 'Content-Type': 'application/json' },
      body: JSON.stringify({ channel: 'wechat' }),
    });
    expect(res.status).toBe(400);
  });
});
```

#### 步驟 2：跑

```bash
npm test -- posts.test.ts
```

#### 步驟 3：紅綠重構

走 `/tdd` skill 的紅綠循環：寫紅 case → 寫實作 → 綠 → 整理。

### 7.2 對全新資源（新檔案）

複製任一現有 `*.test.ts` 的開頭模板：

1. `vi.hoisted` 宣告 mock
2. `vi.mock('firebase-admin/auth', ...)`
3. `await import('../src/app.js')` + `db.js`
4. 自訂 `TEST_UID`
5. `beforeEach` / `afterAll` 清理

---

## 8. 常見陷阱

### 8.1 unique constraint 撞撞撞

**症狀**：`Unique constraint failed on the fields: (firebaseUid)`

**原因**：上一輪測試的 `afterAll` 沒跑（test crashed），殘留 row。

**解法**：手動清，或先跑

```bash
npx prisma studio
```

刪除 `firebase-uid-*-test` 的 user。或用 SQL：

```sql
DELETE FROM "User" WHERE "firebaseUid" LIKE 'firebase-uid-%-test%';
```

### 8.2 Neon cold start timeout

**症狀**：第一個測試 timeout 5s。

**解法**：`testTimeout: 15000` 已設定。如果還是 timeout，到 Neon dashboard 把 endpoint 預熱（送一個 `SELECT 1`）。

### 8.3 mock 沒 reset 影響下一個 case

**症狀**：用 `mockResolvedValue`（無 `Once`）後，下一個 it 應該回 401 卻回 200。

**解法**：每個 it 開頭重設 mock。`beforeEach` 已經 `verifyIdTokenMock.mockReset()`，但若需多次同 mock，用 `mockResolvedValueOnce` 或 `mockResolvedValue` 加最後 `.mockReset()`。

### 8.4 平行跑

**症狀**：CI 改用 `vitest --concurrent` 後測試亂死。

**解法**：別碰 `fileParallelism: false`。所有檔案共用 DB 是設計選擇。

### 8.5 Prisma 模型欄位變更後沒 generate

**症狀**：`Property 'username' does not exist on type ...`

**解法**：

```bash
npm run prisma:generate
```

migration 跑完通常會自動 generate，但若 schema 改了沒 migrate（例如僅修改 `@map` 名稱）就要手動。

### 8.6 測試清理 cascade 沒涵蓋的表

`Block`、`UserFollow`、`Conversation` 都有 `onDelete: Cascade` 連到 User，所以刪 user 會連帶清掉。**但** seed 的 channel / interest 不要碰 — 全部測試共享。

### 8.7 firebase-admin SDK 在測試環境想初始化

`src/firebase.ts` 的 `initializeApp()` 在沒 service account path 時會走 ADC，測試環境 ADC 不存在會噴 warning。**不要刪 import** — 它會被 mock 替換掉。

實際上 `firebase.ts` 的 initialize 是 in-module，不在 mock 範圍 — 但因為我們 mock 的是 `firebase-admin/auth`、`firebase-admin/messaging`，initializeApp() 仍會嘗試。在測試環境只會留一條 warn log，不會 crash。

如果你看到測試噴 `[firebase] credentials not found`，可以 mock `firebase-admin/app`：

```ts
vi.mock('firebase-admin/app', () => ({
  initializeApp: vi.fn(),
  cert: vi.fn(),
  getApps: () => [],
}));
```

但目前沒做，因為 noisy 但不影響結果。

---

## 9. demo-token 工具（手動測試）

`api/scripts/demo-token.ts` 用 Firebase Admin 簽 custom token、再用 Web API key 換 ID token，給 curl 測試用：

```bash
FIREBASE_WEB_API_KEY=AIzaSy... \
FIREBASE_SERVICE_ACCOUNT_PATH=./secrets/zaina-xxx.json \
tsx api/scripts/demo-token.ts seed-author-hana

# 印出 ID token，可丟進 curl：
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/me
```

只能用在 seed authors（demo only），不要對真實使用者用。

---

## 10. 推薦的進一步測試（未實作）

如果未來要把測試擴到滿：

- **Mobile widget tests** — 至少測 `auth_providers.dart` 的 router redirect、`signboard_card.dart` 的 6 template 切換。
- **Mobile golden tests** — 對六種 post card 截圖比對，避免視覺 regression。
- **API e2e socket test** — 起真實 socket.io，驗證 message:new emit。
- **Load test** — feed endpoint 在 Cloud Run cold start 後的 P95 RTT。

這些都不在 v1 portfolio 範圍（ADR-0005）。

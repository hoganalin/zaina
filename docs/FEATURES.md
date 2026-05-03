# FEATURES.md

每個 v1 功能的**行為描述 + 端點規格 + 業務邏輯 + 錯誤情境**。表格只是入口；要動到任何端點前必讀對應段落。

完成度均對應 README 的 Sprint 表（Sprint 0–9 全部 ✅）。

---

## 功能總覽

| 功能 | Sprint | 狀態 | 主要檔案 |
|---|---|---|---|
| 1. Google / Apple 登入 + Session 建檔 | 1 | ✅ | `routes/auth.ts`, `screens/sign_in/` |
| 2. Onboarding（暱稱 / @username / 性別 / 城市 / 興趣 / 看板） | 2 + 9 | ✅ | `routes/me.ts`, `screens/onboarding/` |
| 3. Feed（追蹤的看板 / 同城 二 tab） | 3 | ✅ | `routes/feed.ts`, `screens/feed/` |
| 4. 發貼文 + 留言 + Like（denormalised 計數） | 4 | ✅ | `routes/posts.ts`, `screens/compose/`, `screens/post_detail/` |
| 5. 看板追蹤 / 取消追蹤 | 5 | ✅ | `routes/channels.ts`, `screens/channels/` |
| 6. 公開 Profile + 編輯 Profile | 5 | ✅ | `routes/users.ts`, `routes/me.ts`, `screens/profile/` |
| 7. 使用者追蹤 / 取消追蹤 | 5 + 9 | ✅ | `routes/users.ts` |
| 8. DM（Conversation Eligibility + Message Request + Socket.io） | 6 | ✅ | `routes/conversations.ts`, `eligibility.ts`, `realtime.ts`, `screens/conversations/` |
| 9. Block | 7 | ✅ | `routes/users.ts`, `blocks.ts` |
| 10. Verification（模擬通過 + Verified Badge） | 7 | ✅ | `routes/verifications.ts`, `screens/verification/` |
| 11. FCM 推播（DM 觸發） | 7 | ✅ | `push.ts`, `routes/me.ts` push-token, `api/fcm_service.dart` |
| 12. 通知（comment / DM / new post / new follower 聚合） | 9 | ✅ | `routes/notifications.ts`, `screens/notifications/` |
| 13. 夥伴推薦（同城 / 共同興趣） | 9 | ✅ | `routes/companions.ts`, `screens/companions/` |
| 14. @username（live 可用性檢查 + 寫入 onboarding/edit profile） | 9 | ✅ | `routes/me.ts`, onboarding step 2 |

刻意**未做**的（ADR-0005 / ADR-0010）：swipe / match、真實 ID 審核、群聊、活動板、區域看板、報告、軟刪、多語、MBTI / 星座 / 抽菸 / 飲酒 / 睡眠等檔案欄位、專屬話題編輯、ISIC OCR、Facebook 真登入、未登入瀏覽。

---

## 1. Google / Apple 登入 + Session 建檔

**目標**：使用者按下登入後在後端有一筆對應的 `User` row。

### 行為

1. `SignInScreen`（`mobile/lib/screens/sign_in/sign_in_screen.dart`）顯示三個 provider 按鈕：Facebook（佔位／snackbar 解釋未啟用）、Google、Apple（iOS only）。背景是 paper texture + 三杯插畫。
2. 點擊後 `auth_providers.dart` 中 `AuthNotifier.signInWithGoogle()` / `signInWithApple()` 把第三方 credential 傳給 `FirebaseAuth.signInWithCredential`。
3. `_fetchSelfView()` 呼叫 `POST /api/auth/session`（dio interceptor 自動帶 token）。
4. 後端 `verifyIdToken(token)` 解出 `decoded.uid`，`prisma.user.upsert({where:{firebaseUid: decoded.uid}, update:{}, create:{firebaseUid, nickname: decoded.name ?? '新朋友'}})`。
5. 回 `{user: SelfView}`（剝掉 `firebaseUid`）。
6. Riverpod state 變更 → router redirect 評估：onboarding 未完成 → `/onboarding`；完成 → `/feed`。
7. FCM 註冊在背景平行進行（`fcmServiceProvider.register()`，不 await）。

### 端點

`POST /api/auth/session` — **唯一不套 `requireAuth` middleware 的 `/api/...` 端點**（它就是要建 User row）。

- **Header**：`Authorization: Bearer <Firebase ID token>`（必填）
- **Body**：（無）
- **回應 200**：`{user: {id, nickname, gender, country, city, avatarUrl, bio, isVerified, onboardingCompleted, createdAt, fcmToken, username}}`
- **回應 401**：缺 header 或 verify 失敗

### 業務邏輯（ADR-0008）

- `upsert` 是核心：第一次登入 create；之後 update 空物件等同無操作，回原本 row。
- 沒有「先驗證 token、後在另一個畫面建 row」的選項 — 這個 endpoint 是 single source of truth。

### 錯誤情境

- Token 過期 / 偽造 → 401
- `displayName` 缺值（如 Apple 不回 name）→ nickname 寫 `'新朋友'`
- DB 連線錯 → 500（未顯式處理）

---

## 2. Onboarding（暱稱 / @username / 性別 / 城市 / 興趣 / 看板）

**目標**：讓首次登入使用者填完必要 profile，把 `onboardingCompleted` 翻成 true。

### 行為

OnboardingScreen 走 4 步（Sprint 9 加入 @username step）：

1. 暱稱（required, max 40）
2. @username（optional；live 可用性檢查；3–20 chars `[a-zA-Z0-9_]`）
3. 興趣多選（雙 category：active / static）
4. 看板多選

最後送出時呼叫 `PATCH /api/me/onboarding`，後端在一個 transaction 內：

- update User（nickname, username?, gender?, country?, city?, onboardingCompleted=true）
- deleteMany UserInterest where userId
- createMany UserInterest（如果有）
- deleteMany ChannelFollow where userId
- createMany ChannelFollow（如果有）

### 端點

#### `PATCH /api/me/onboarding`

- **Body**（zod）：
  - `nickname: string(1..40)` — 必填
  - `username?: string` — 必須 match `/^[a-zA-Z0-9_]{3,20}$/`
  - `gender?: 'male'|'female'|'non_binary'`
  - `country?: string(1..80)`
  - `city?: string(1..80)`
  - `interestIds: string[]` — UUID array，default `[]`
  - `channelIds: string[]` — UUID array，default `[]`
- **驗證**：
  - 任一 `interestId` / `channelId` 不存在 → `400 invalid_interest_id` / `400 invalid_channel_id`
  - username 已被別人佔 → `409 username_taken`（先 select、再 catch P2002）
- **回應 200**：`{user: SelfView}`

#### `GET /api/me/check-username?u=<value>`

- **Query**：`u` — 任意字串
- **回應**：`{available: bool, reason?: 'invalid_format'}`
- **規則**：
  - 不 match regex → `{available: false, reason: 'invalid_format'}`
  - 該 username 已存在但是「我自己」→ `{available: true}`（自己佔用視為仍可用）
  - 別人佔用 → `{available: false}`

### 業務邏輯（重點）

- Onboarding 是「**重寫式**」：deleteMany + createMany 取代既有 UserInterest / ChannelFollow，所以**重複送會把先前的興趣全部清掉**——這正是 `me.test.ts` 「replaces relations on re-submit」測試所驗證的 idempotent semantics。
- onboarding 不允許跳過：router redirect 強制 onboardingCompleted=false 的使用者只能在 `/onboarding`。但 username 可以跳過，事後從 edit profile 補。
- transaction 包整段，避免 update 成功 / interest 失敗時資料不一致。

---

## 3. Feed（追蹤的看板 / 同城）

**目標**：兩個無限捲動的清單，呈現使用者關注的內容。

### 行為

`FeedScreen` 上方 pill 切換：

- 「所有話題」/「我關注」 → `GET /api/feed/following`
- 「同城」 → `GET /api/feed/city`

兩個列表都是 2-column masonry grid（`flutter_staggered_grid_view`），每張卡使用 `signboard_card.dart` 的 6 種 template（依 `post.id.hashCode % 6` 輪）：

1. 圖片 + 多疊章戳（短 CJK 標題 ≤5 字才用）
2. 圖片 + sticker + 米色標題框
3. 紅色光芒 + 黃色手繪字（無圖時）
4. 黃色看板 + 紅邊 + 「特別話題」標籤
5. 紙本對話泡 + 角落貼紙
6. 綠色面板 + sticker + 米色框

下拉刷新；滾到底自動載下一頁（`nextOffset != null`）。

### 端點

#### `GET /api/feed/following?limit=20&offset=0`

- **Query**：`limit` 1–50, default 20；`offset` ≥0, default 0
- **行為**：
  1. 找 `ChannelFollow where userId` → channelIds 集合
  2. 集合空 → 回 `{posts: [], nextOffset: null}`
  3. `getBlockedCounterparts(userId)` → 排除作者
  4. `Post.findMany({channelId IN, authorId NOT IN blocked}, orderBy desc, take limit+1)`
  5. `annotateLikedByMe` — 一次撈我對這批 posts 的 PostLike，標 boolean
  6. 回 `{posts, nextOffset: hasMore ? offset+limit : null}`
- **每筆 post**：完整 Post 欄位 + `channel: {id, slug, name, icon}` + `author: {id, nickname, avatarUrl}` + `likedByMe: bool`

#### `GET /api/feed/city?limit=20&offset=0`

- 同上，但 `where: {city: c.var.user.city}`。
- **若使用者沒設 city**：直接回 `{posts: [], nextOffset: null}`（不噴錯）。

### 業務邏輯

- **不過濾自己的貼文**（自己看自己的可以）。
- Block 是雙向過濾：你 block 他 / 他 block 你 → 都看不到他的。
- 排序純粹 `createdAt desc`，沒有 ranking。

### 錯誤情境

- 無 token → 401
- limit > 50 / offset < 0 → 400（zod）

---

## 4. 發貼文 + 留言 + Like

### 行為

#### 發貼

`ComposePostScreen`（FAB 從動態 tab 進入）。表單：channel picker、title、body、city（預填 user.city，可改）、country。送出 → `POST /api/posts`，成功 navigate back。

#### 留言

`PostDetailScreen` 進來後 fetch 貼文 + 第一頁留言。底部 `TextField` 送出 → `POST /api/posts/:id/comments`，optimistic insert + commentCount++ 顯示。

#### Like

PostDetailScreen 與 FeedCard 都有愛心 icon。tap 按下：

- 未 like → `POST /:id/like`，`likedByMe=true`、`likeCount++`
- 已 like → `DELETE /:id/like`，`likedByMe=false`、`likeCount--`

### 端點

#### `POST /api/posts`

- **Body**：
  - `channelId: uuid`
  - `title: string(1..120)`
  - `body: string(1..2000)`
  - `city: string(1..80)`
  - `country: string(1..80)`
  - `imageUrl?: url`
- **驗證**：channelId 必須存在 → 不存在 `400 invalid_channel_id`
- **回應 201**：`{post: <Post + channel + author + likedByMe: false>}`

#### `GET /api/posts/:id`

- **回應 200**：`{post: <Post + channel + author + likedByMe>}`
- **回應 404**：`not_found`

#### `POST /api/posts/:id/like`

- **行為**：先檢查 post 存在（404 否則）；查 PostLike 是否已存在 → 若存在直接回現值（idempotent）；否則 transaction：create PostLike + post.update likeCount++。
- **回應 200**：`{likeCount, likedByMe: true}`

#### `DELETE /api/posts/:id/like`

- **行為**：transaction 內檢查 post 存在 → 不存在回 null（外層 404）；deleteMany；若 count 0（idempotent）只回現值；否則 likeCount--。
- **回應 200**：`{likeCount, likedByMe: false}`

#### `GET /api/posts/:id/comments?limit=50&offset=0`

- **Query**：limit 1–100, default 50；offset 0+。
- **回應 200**：`{comments: [{id, body, createdAt, author:{id,nickname,avatarUrl}}], nextOffset}`，**asc by createdAt**（早期留言在上）。
- **回應 404**：`not_found` if post 不存在。

#### `POST /api/posts/:id/comments`

- **Body**：`body: string(1..1000)`
- **行為**：transaction 內 — 確認 post 存在；create Comment（含 author lite include）；post.update commentCount++。
- **回應 201**：`{comment}`
- **回應 404**：`not_found`

### 業務邏輯（ADR-0006 denormalised counts）

- `likeCount` / `commentCount` **不是 SQL COUNT**，是 cached column。
- 任何 like / comment 寫入都**必須**包進 `prisma.$transaction`，否則計數會漂移。
- catastrophic failure（如 transaction 中段死機）會出 drift；ADR-0006 接受這個風險，承諾 v2 加 nightly cron reconcile。
- 寫測試時請斷言 `Post.likeCount` / `Post.commentCount` 真的有變動（`posts.test.ts` 的 reload 步驟）。

### 錯誤情境

- channelId 隨便填 → 400
- title 超過 120 字 → 400（zod）
- body 為空 → 400
- post 不存在 → 404
- 連 like 兩次 → 第二次仍 200，計數不會多加（idempotent）

---

## 5. 看板追蹤 / 取消追蹤

### 行為

從動態 AppBar 的看板按鈕進 `ChannelsScreen`，列出全部 12 個 channel + emoji icon + isFollowing 狀態。toggle 即發 POST/DELETE。返回後動態的「我關注」tab 內容跟著變。

### 端點

#### `GET /api/channels`

- **回應 200**：`{channels: [{id, slug, name, description, icon, sortOrder, createdAt, isFollowing}]}`，先 sortOrder asc 後 name asc。
- isFollowing 反映目前使用者的 ChannelFollow。

#### `POST /api/channels/:id/follow`

- 先確認 channel 存在 → 不存在 404。
- `upsert` ChannelFollow（`@@id([userId, channelId])` 作 key），idempotent。
- 回 `{isFollowing: true}`。

#### `DELETE /api/channels/:id/follow`

- `deleteMany`，不存在當作已取消，仍回 `{isFollowing: false}`。

---

## 6. 公開 Profile + 編輯 Profile

### 行為

#### 公開 profile（`/profile/:id`）

`ProfileScreen` 顯示對方的：暱稱、@username、頭像、bio、城市、Verified Badge、postCount、followerCount、followingCount、`isFollowing`、是否 blocked。底下顯示對方貼文（無限捲動）。Overflow menu 提供 Block / Unblock、發訊息（會跳到 `/chat/:conversationId` 或顯示「不能私訊」snackbar）。

#### 自己 profile（在「我」tab）

走同一個 `ProfileScreen` 但 `userId == authedUser.id`，hides Block/Follow 按鈕，顯示「編輯資料」/ 「驗證身分」/「登出」入口。

#### 編輯 profile（`/edit-profile`）

Form 修改 nickname、username（live check）、gender、country、city、bio、avatarUrl。送 `PATCH /api/me`，成功更新 Riverpod self-view（`AuthNotifier.updateSelfView`）。

### 端點

#### `GET /api/users/:id`

- **回應 200**：
  ```json
  {
    "user": {
      "id", "nickname", "username", "gender", "country", "city",
      "avatarUrl", "bio", "isVerified", "createdAt",
      "postCount", "followerCount", "followingCount", "isFollowing"
    }
  }
  ```
- **不含 firebaseUid / fcmToken / onboardingCompleted**（保護隱私）。
- 自己看自己時 `isFollowing: false`（hardcoded — 自己不能追蹤自己）。

#### `GET /api/users/:id/posts?limit=20&offset=0`

- 該作者所有貼文，desc by createdAt，含 channel/author/likedByMe。

#### `PATCH /api/me`（profile edit）

- **Body**（zod **strict** — 多帶欄位會 400）：
  - `nickname?: string(1..40)`
  - `username?: string|null`（regex match 或 null 清空）
  - `gender?: 'male'|'female'|'non_binary'|null`
  - `country?: string(1..80)|null`
  - `city?: string(1..80)|null`
  - `bio?: string(0..500)|null`
  - `avatarUrl?: url|null`
- **回應**：200 `{user: SelfView}`、409 username_taken、400 unknown field
- 不接受 `onboardingCompleted` / `isVerified` 等敏感欄位（zod strict 攔截）。

### 業務邏輯

- 自己看自己用 `me === id` 短路，省掉 isFollowing 那次 DB 查詢。
- followerCount = `UserFollow.count where followingId = me`；followingCount = `UserFollow.count where followerId = me`。

---

## 7. 使用者追蹤 / 取消追蹤

從公開 profile 或夥伴卡上的「追蹤」按鈕觸發。

### 端點

#### `POST /api/users/:id/follow`

- 拒自追蹤 → `400 cannot_follow_self`
- target 不存在 → 404
- upsert UserFollow（`{followerId: me, followingId: id}`）
- 回 `{isFollowing: true}`

#### `DELETE /api/users/:id/follow`

- deleteMany；回 `{isFollowing: false}`

### 業務邏輯（ADR-0010 / ADR-0002）

- **單向 follow**，不需互追。
- 夥伴 tab 的「追蹤」按鈕走的就是這個端點 — 「夥伴」只是 UI label，後端與一般 follow 完全一致。

---

## 8. DM（Conversation Eligibility + Message Request + Socket.io）

### 行為

#### 發起對話

A 點對方 profile 的「發訊息」→ mobile 呼叫 `POST /api/conversations {userId: B}`：

- 後端 `canDM(A, B)` 判斷（見下方）。
- 不可 → 回 403，UI 顯示「需先在貼文下留言才能私訊」。
- 可 → create Conversation(status='message_request')。

#### 進入聊天

`ChatScreen`（`/chat/:conversationId`）：

1. 啟動時 `connect()` socket（`auth: {token}`）並 join `user:<myId>` room
2. `GET /api/conversations/:id/messages` 一次撈完歷史
3. 訂閱 `chatSocket.events`，filter 條件 `conversationId == 本畫面 id`，append 到清單
4. 送出時 `POST /:id/messages`；對方端：socket emit + FCM 推播

#### 升級訊息邀請

新建立的 Conversation status='message_request'。**B 第一次回覆**時自動升級為 'active'：

```ts
if (conv.status === 'message_request' && sender 沒在這對話發過 && conversation 已有訊息) {
  willPromote = true   // → status: 'active' in transaction
}
```

→ A 自己重複發訊息不會升級；只有 B 回覆才升。「對話列表」會分別顯示「訊息邀請」與一般對話的徽章。

### 端點

#### `GET /api/conversations`

- 列出 `userAId == me OR userBId == me` 的對話，desc by lastMessageAt。
- 每筆：`{id, status, lastMessageAt, other: {id, nickname, avatarUrl}, lastMessage: {id, body, createdAt, ...}|null}`。

#### `POST /api/conversations`

- **Body**：`{userId: uuid}` — 對方 id
- 自己 → `400 cannot_dm_self`
- target 不存在 → 404
- 已存在 conversation → 直接回（不檢查 eligibility，因為已建立過）
- 不存在 → `canDM(me, other)` → 不可 `403 not_eligible`
- 可 → 建立 status='message_request'，回 201
- 用 `orderUserPair(me, other)` 強制 a<b

#### `GET /api/conversations/:id/messages`

- 非參與者 → 403 forbidden
- 不存在 → 404
- 回 asc by createdAt：`{messages: [{id, conversationId, senderId, body, readAt, createdAt}]}`

#### `POST /api/conversations/:id/messages`

- **Body**：`{body: string(1..2000)}`
- 行為：見上方升級邏輯 + transaction：create Message + Conversation.update(lastMessageAt[, status])
- 完成後：
  - `emitToUser(other, 'message:new', {conversationId, message})`
  - `sendPush(other, {title: sender.nickname, body: body.slice(0, 80)+'…', data:{conversationId, type:'dm'}})`（fire-and-forget，不 await）
- 回 201 `{message}`

### 業務邏輯（ADR-0003）— `canDM(a, b)`

```ts
if (a === b) return false;
if (任一方向 Block 存在) return false;

if (A 在 B 的 post 留過言) return true;
if (B 在 A 的 post 留過言) return true;

A 留言過的 postIds 集合 = ...
if (B 也在這些 post 留過言) return true;

return false;
```

→ 公開留言是進入私訊的唯一通道。沒有 follow gate / mutual gate。

### Socket 通道（`realtime.ts`）

- `auth: {token}` 必填，verifyIdToken + 找 User row → 設 `socket.data.userId`
- 連線後加入 `user:<id>` room
- 後端 `emitToUser(userId, event, payload)` 對該 room broadcast
- mobile 訂閱 `'message:new'`，payload `{conversationId, message: ChatMessage}`

### 錯誤情境

- A 還沒有任何 comment → DM 嘗試 403
- 第三人試圖塞訊息 → 403 forbidden
- conversation 不存在 → 404
- token 過期（後端 verify 失敗）→ 401（要重新登入）

---

## 9. Block

### 行為

公開 profile overflow → 「封鎖」/「解除封鎖」。封鎖後：

- 對方貼文不出現在你的 feed（任 tab）
- 你 / 對方都不能對對方 DM
- 已存在的 conversation 仍可看，但發新訊息會擋（**目前未實作 send 時 block 檢查 — 只擋 conversation create**）

### 端點

#### `POST /api/users/:id/block`

- 自己 → `400 cannot_block_self`
- target 不存在 → 404
- upsert Block（`@@id([blockerId, blockedId])`），idempotent
- 回 `{blocked: true}`

#### `DELETE /api/users/:id/block`

- deleteMany；回 `{blocked: false}`

### 業務邏輯

- `blocks.getBlockedCounterparts(userId)` 回**對稱集合**：所有「我封鎖的」+「封鎖我的」併起來。
- 兩個 feed 都用這個集合 `notIn` 過濾 authorId。
- DM 端 `canDM` 也檢查雙向 Block。

---

## 10. Verification（模擬通過 + Verified Badge）

### 行為

「我」tab → 「驗證身分」→ `VerificationScreen`：

1. 選 identityType（學生 / 員工）
2. 從相簿選圖（沒有 camera 路徑 — README 寫 future）
3. 送出 → `POST /api/verifications`
4. 立即 `isVerified=true`，profile 與貼文上開始顯示 ✓ 已認證

### 端點

#### `POST /api/verifications`

- **Body**：`{identityType: 'student'|'employee', imageUrl: url}`
- **行為**（ADR-0004）：transaction 內
  - create Verification(status='approved', reviewedAt=now)
  - update User isVerified=true
- **回應 201**：`{verification: {...}}`

#### `GET /api/verifications/me`

- 回我所有 verification 紀錄，desc by createdAt。

### 業務邏輯（ADR-0004）

- **路由直接寫 `status: 'approved'`**，跳過真實 `pending` 狀態。
- schema 仍保留 `pending`/`rejected` 給未來實作。
- imageUrl 接 zod url 驗證 — 未檢查 URL 是否真的指向有效 GCS object（v1 portfolio 範圍）。
- isVerified 是 cosmetic — 不阻擋任何功能。

---

## 11. FCM 推播

### 行為

- 登入 → mobile FCM token → `PATCH /api/me/push-token` 寫入。
- onTokenRefresh / onMessage 訂閱也在這時上。
- 登出 / 切換帳號 → `PATCH push-token` 寫 null。
- 觸發來源：目前**僅 DM 訊息**（`POST /api/conversations/:id/messages`）。

### 端點

#### `PATCH /api/me/push-token`

- **Body**：`{fcmToken: string(>=1)|null}`
- 寫入 / 清空 `User.fcmToken`，回 `{ok: true}`。

### 業務邏輯（`api/src/push.ts`）

- 沒 fcmToken silently no-op（best-effort）。
- `getMessaging().send({token, notification:{title,body}, data})`，所有錯誤吞掉只 console.warn — **絕不阻擋呼叫端流程**。
- payload 結構：
  ```
  notification: { title: sender.nickname, body: body[0..80]+'…' }
  data: { conversationId, type: 'dm' }
  ```
- mobile 端 onMessage 目前只 `debugPrint`（前景時不顯示 system notification — 可未來補 flutter_local_notifications）。

---

## 12. 通知（4 來源 ad-hoc 聚合）

### 行為

通知 tab 顯示混排清單：

- `comment_on_my_post` — 別人在我的貼文留言
- `new_dm` — 我收到新私訊
- `new_post_in_channel` — 我關注的看板有新貼文（非自己）
- `new_follower` — 有人追蹤我

每筆顯示 actor avatar + 中文化文案 + tap 跳轉（貼文 / 對話 / profile）。

### 端點

#### `GET /api/notifications`

- 無 query 參數；服務內 limit hard-coded 50、since=過去 30 天。
- **行為**（ADR-0010）：分別查四個 source，全部塞進統一 shape 後 sort by createdAt desc，slice 50。
- 沒有 Notification table — read load 在這個量級夠便宜，避免 schema 膨脹。
- **回應 200**：
  ```json
  {
    "notifications": [
      {
        "id": "comment:<uuid>",
        "type": "comment_on_my_post",
        "createdAt": "...",
        "actor": {"id", "nickname", "avatarUrl"},
        "target": {"postId": "...", "postTitle": "..."}
      },
      {"id": "dm:<uuid>", "type": "new_dm", "actor", "target": {"conversationId", "body"}},
      {"id": "post:<uuid>", "type": "new_post_in_channel", "actor", "target": {"postId", "postTitle", "channelName", "channelIcon"}},
      {"id": "follow:<followerId>-<followingId>", "type": "new_follower", "actor"}
    ]
  }
  ```

### 業務邏輯

- comment 與 dm 條件都加 `senderId/authorId != userId` 排除自己的動作。
- new_post 限「我關注的 channel」+「非自己作者」；額外 take 20（不到全部 limit 50，但混排後仍會被 sort + slice）。
- new_follower 用 UserFollow 直接撈。
- **這是純讀路徑** — 不寫任何資料，所以「讀過」狀態無法持久化。如果未來要做 unread badge 必須加 schema。

### 錯誤情境

- 401 未登入

---

## 13. 夥伴推薦（同城 / 共同興趣）

### 行為

「夥伴」tab：每天的推薦卡片（堆疊式）。卡片顯示對方暱稱、@username、城市、bio、共同興趣。下方兩個按鈕：

- 「追蹤」 → `POST /api/users/:id/follow`，卡片離開 stack
- 「略過」 → 純 UI 移除，不寫 DB（**非持久化**）

### 端點

#### `GET /api/companions/daily?limit=10`

- **Query**：`limit` 1–20, default 10
- **行為**：
  1. 取我的 interestIds 與 blocked 集合
  2. 取我已追蹤的 followingIds
  3. excludeIds = {self, blocked, followed}
  4. `User.findMany`：`onboardingCompleted=true`、`id NOT IN excludeIds`、`OR: [{city: me.city}, {interests: {some: {interestId IN myInterestIds}}}]`，`take: limit*4`
  5. TypeScript 端 rank：先 sharedCity desc（同城優先），再 sharedInterestCount desc
  6. slice limit
- **回應 200**：
  ```json
  {
    "companions": [
      {
        "id", "nickname", "username", "city", "country", "avatarUrl", "bio", "isVerified",
        "sharedCity": true,
        "sharedInterestCount": 2
      }
    ]
  }
  ```

### 業務邏輯（ADR-0010 / ADR-0002）

- **不是 swipe**，沒有 match — 「追蹤」走標準 UserFollow，「略過」是 UI-only。
- candidates 只取 `onboardingCompleted` 的 user — 避免推薦頁出現只剩 firebase placeholder 的空殼帳號。
- 排名在 TS 算（`take: limit*4` 的 candidate pool），原因是 SQL JOIN + COUNT shared interests 寫起來較繁、portfolio 範圍可接受 in-memory 排序。

### 錯誤情境

- 401 未登入

---

## 14. @username

### 行為

- Onboarding step 2 / 編輯 profile 都有 username 欄位
- 輸入時 debounced 觸發 `GET /api/me/check-username?u=...`，UI 顯示「✓ 可用」/「✗ 已被使用」/「✗ 格式錯誤」
- 送出 onboarding 或 PATCH me 時若被別人佔走（race）→ 409，UI 提示重選

### 端點規格

見上方 §2 與 §6 說明。

### 業務邏輯

- regex `^[a-zA-Z0-9_]{3,20}$`（前後端共用）
- DB UNIQUE constraint 是最後防線（race condition 才會觸發 P2002 → 409）
- check-username 會把「自己佔用」視為 available，避免使用者編輯自己時看到誤判

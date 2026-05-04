# CHANGELOG

ZAINA 的版本變動紀錄。Sprint 為單位（對應 README 的 roadmap），日期取主要 commit 時間。專案自 2026-04-30 起步、2026-05-03 達到 v1 feature complete。

注意 Sprint 0~9 是「portfolio 階段」的開發 sprint，每個 Sprint = 一個 PR/commit chunk，但**未發布版本標籤**。本檔案以 Sprint 號碼作 anchor。

## [Unreleased]

待加入：實裝計畫請放 `docs/plans/`，完成後挪到 `docs/plans/archive/` 並更新本檔。

候選清單（`README.md` Future 區）：

- 真實 ISIC / 員工驗證 backend（取代 ADR-0004 的模擬）
- 群組聊天 + 活動板
- 區域看板（東京板 / 倫敦板）
- 春節 / 端午節 sticker pack
- 「我的情感地圖」個人連結圖
- 計數 reconciliation cron job（ADR-0006 v2）
- ID 圖片相機路徑（補上目前只有相簿選圖）

---

## Sprint 10 — Mobile 工程紀律 codify + 12 screen READMEs + mobile test 地板（2026-05-04）

對應 ADR：[`adr/0011-mobile-discipline-as-rules.md`](./adr/0011-mobile-discipline-as-rules.md)

### Added

- **`CLAUDE.md` 「Mobile 工程紀律（4 條家規）」段**（+45 lines）：RULE-01 新增登入方式必須走完 4 步清單 / RULE-02 斷線重連策略寫一份不許重複 / RULE-03 每個 screen 附 README / RULE-04 測試跟功能一起交件。違反任何一條 → code review 退件。
- **12 份 screen README**（`mobile/lib/screens/*/README.md`）：每份用 RULE-03 固定 schema（用途 / API / 資料流 / 已知陷阱）。channels / companions / compose / conversations / feed / notifications / onboarding / post_detail / profile / shell / sign_in / verification 全到位。
- **`mobile/test/`**：9 個 widget / unit cases 作為 RULE-04 的 floor。`widgets/zaina_logo_test.dart` × 3（ZainaLogo + WelcomeSignboard）、`theme/zaina_theme_test.dart` × 4（M3 + token 驗證）、`api/chat_socket_test.dart` × 2（enum + 初始 status）。

### Changed

- **`mobile/lib/api/chat_socket.dart`**：把 RULE-02 的 reconnect 策略寫進 code——backoff 1s→30s（infinite attempts、cap 30s）、`reconnect_attempt` 自動 refresh Firebase ID token（避免 1 小時過期失效）、新增 `ChatConnectionStatus` enum 4 狀態 + `socket.status` stream 給 UI 顯示「重連中…」。caller (`chat_screen.dart`) 不需改動。

### Hardened

- `flutter test` 9/9 全綠、`flutter analyze` no issues。
- **`api/test/auth.session.test.ts`** 補 Apple-shaped token case（`firebase.sign_in_provider: 'apple.com'` + 無 `name`，驗 `decoded.name ?? '新朋友'` fallback）——RULE-01 第 4 步收尾，`auth.session` 5/5 全綠。iOS 端 device 驗收待 Mac 環境。

### Deferred / Cut

- **`lib/` 結構重構**（投影片原本寫的 `app/ core/ features/ shared/`）：保留現有 `screens/` 扁平結構（CLAUDE.md `1 screen = 1 directory` 規約），重構成本（改 12 個 screen 的 import 與 router）超過 portfolio 範圍效益。投影片文案改成與 repo 一致的 `screens/` 結構即可。
- **README staleness audit job**（ADR-0011 v2）：12 份 README 的自動化 lint（比對 screen 實際的 API client + provider 列表）留給未來實作。

---

## Sprint 9 — 視覺 re-skin + 夥伴 / 通知 / @username（2026-05-02 ~ 2026-05-03）

對應 ADR：[`adr/0010-deck-partial-alignment.md`](./adr/0010-deck-partial-alignment.md)

### Added

- **5-tab bottom nav**：動態 / 夥伴 / 通知 / 訊息 / 我（cup-emoji icon），看板從 tab 移到動態 AppBar 的按鈕。`shell_scaffold.dart`。
- **夥伴 tab + `GET /api/companions/daily`**：同城／共同興趣推薦，Limit 10，TS-side rank。`routes/companions.ts`、`screens/companions/`。
- **通知 tab + `GET /api/notifications`**：四種來源（comment / DM / new post / new follower）ad-hoc 聚合，30 天內 cap 50。`routes/notifications.ts`、`screens/notifications/`。
- **`@username`**：onboarding 加第二步、edit profile 加欄位、`GET /api/me/check-username`。`migration: 20260503010000_add_username` + `User.username String? @unique`。
- **視覺 re-skin**：完整 Figma token 套用、paper-textured 背景、紅 / 綠 / 棕 / 金 配色、bubble-tea 杯印、招牌看板 6 種 template 卡片。`theme/zaina_theme.dart`、`widgets/signboard_card.dart`、`widgets/sun_ray_background.dart`。
- **登入 / splash / first-login 全部 re-skin**，加在 `assets/illustrations/` 的三杯插畫與 logo PNG。

### Changed

- **看板按鈕從 tab 改成 AppBar icon**（5 tab 改造）。
- 文字尺寸與 nav 高度多次微調（commits 35ae6d4, 17252eb, 7dc7fc0）以符合 deck。
- 多疊章戳僅短 CJK 標題啟用（commit ea396d7）。
- `Image.network` 強制 `cacheWidth/cacheHeight` 防 ANR（commit 515b03c）。
- 所有 hex 從 eyeball palette 改成 Figma 直拉（commit 406219a）。

### Deferred / Cut

- Swipe / match — ADR-0002 stands。
- MBTI / 星座 / 抽菸 / 飲酒 / 睡眠 / 已去國家 — ADR-0005。
- 專屬話題 + 招牌看板 / 圖片看板編輯器 — ADR-0005。
- ISIC OCR + crop — ADR-0004。
- Facebook 登入（按鈕為 placeholder + snackbar）。
- 未登入瀏覽。

---

## Sprint 8 — GCP 部署 + 文件 + Demo（2026-05-02）

### Added

- **Dockerfile**（3-stage：deps → build (prisma generate + tsc + prune) → runtime；non-root user）。
- **`DEPLOY.md`**：Cloud Run + Artifact Registry + Secret Manager + Neon migrate deploy 步驟。
- **README polish**：stack table、demo flow 13 步、ADR 連結列表。
- **`scripts/demo-token.ts`**：用 Firebase Admin 換 ID token 給 curl 測試。

### Changed

- README 加 mermaid 架構圖、Sprint 表狀態全 ✅。

---

## Sprint 7 — Verification + Block + FCM 推播（2026-05-01）

對應 ADR：[`adr/0004-simulated-verification.md`](./adr/0004-simulated-verification.md)

### Added

- **`POST /api/verifications`** — 上傳模擬通過：transaction 寫 Verification(status=approved) + isVerified=true。
- **`GET /api/verifications/me`** — 我的驗證紀錄。
- **`POST/DELETE /api/users/:id/block`** — Block CRUD + 雙向過濾（`blocks.ts` getBlockedCounterparts）。
- **`PATCH /api/me/push-token`** — FCM token 寫入 / 清空。
- **`migration: 20260502035709_add_fcm_token`** — `User.fcmToken TEXT NULL`。
- **FCM 推播觸發 DM**：`conversations.ts` 訊息送出後 `sendPush(otherUserId, ...)`，best-effort。
- Mobile：`VerificationScreen`、Profile overflow 的 Block / Unblock、`fcm_service.dart`。

### Changed

- Feed 與 conversations 的 query 全加 `getBlockedCounterparts` 過濾。

---

## Sprint 6 — DM with Socket.io + Conversation Eligibility + Message Request（2026-04-30 ~ 2026-05-01）

對應 ADR：[`adr/0003-conversation-eligibility.md`](./adr/0003-conversation-eligibility.md)

### Added

- **Conversation / Message tables** — `userAId < userBId` 強制（`orderUserPair`）；status `message_request` / `active`。
- **`canDM(a, b)`**（`eligibility.ts`）：A 在 B post 留言 / B 在 A post 留言 / 同一 post 都留言 三條件之一。
- **`POST /api/conversations`** — 新建（403 not_eligible）、回既存。
- **`GET /api/conversations`** — 列表 + 對方 lite + lastMessage。
- **`GET /api/conversations/:id/messages`** — asc by createdAt，非參與者 403。
- **`POST /api/conversations/:id/messages`** — transaction 寫訊息 + lastMessageAt + 自動升 active（B 第一次回時）+ socket emit + push。
- **Socket.io 即時層**（`realtime.ts`）：auth verify → `user:<id>` room → emit。
- Mobile：`ConversationsScreen`、`ChatScreen`、`chat_socket.dart`。

---

## Sprint 5 — 看板 follow / 公開 profile / 5 tab nav（2026-04-30）

### Added

- **`GET/POST/DELETE /api/channels/:id/follow`** — channel follow 切換。
- **`GET /api/users/:id`** + `/posts` — 公開 profile + 該作者貼文。
- **`POST/DELETE /api/users/:id/follow`** — 單向 user follow。
- **Mobile bottom nav**（5 tab，當時還是 動態 / 看板 / 訊息 / 我，Sprint 9 改成 deck 版）。
- Mobile：`ChannelsScreen`、`ProfileScreen`、`EditProfileScreen`。

---

## Sprint 4 — 發貼文 + 留言 + Like（2026-04-30）

對應 ADR：[`adr/0006-denormalized-post-counts.md`](./adr/0006-denormalized-post-counts.md)

### Added

- **`POST /api/posts`** + `GET /api/posts/:id`。
- **`POST/DELETE /api/posts/:id/like`** — transaction 內 PostLike CUD + likeCount inc/dec，idempotent。
- **`GET/POST /api/posts/:id/comments`** — 評論 + commentCount transaction 維護。
- **denormalised counts**：`Post.likeCount` / `commentCount` 同 transaction 更新。
- Mobile：`ComposePostScreen`、`PostDetailScreen` + 評論 + Like。

---

## Sprint 3 — 唯讀 Feed（2026-04-30）

### Added

- **`GET /api/feed/following`** — 追蹤的看板的貼文（block 過濾、分頁、likedByMe）。
- **`GET /api/feed/city`** — 同城貼文（`post.city == user.city`）。
- **`prisma/seed.ts`**：12 channels、12 interests、5 seed authors、36 posts（每 channel 3 篇）。
- **`Post.imageUrl`** + 對應 picsum seed image。
- Mobile：`FeedScreen`（2 tab）、freezed `FeedPost` model、masonry grid。

---

## Sprint 2 — Onboarding（2026-04-30）

### Added

- **`PATCH /api/me/onboarding`** — transaction 內：update User + deleteMany/createMany UserInterest + ChannelFollow（替換式 idempotent）。
- **`GET /api/interests`** + `/api/channels`（read 部分）。
- Mobile：`OnboardingScreen` 4 步（Sprint 9 才加 username step），`InterestPickerWidget`、`ChannelPickerWidget`。

---

## Sprint 1 — Sign-in + Session（2026-04-30）

對應 ADR：[`adr/0008-user-row-on-firebase-verify.md`](./adr/0008-user-row-on-firebase-verify.md)

### Added

- **`POST /api/auth/session`** — 唯一會建立 User row 的端點。
- **`requireAuth` middleware**（`middleware/requireAuth.ts`）：parse Bearer → verifyIdToken → 找 User row → set context vars。
- **firebase-admin 初始化**（`firebase.ts`）：service account path 或 ADC。
- **prisma init migration**（`20260501011145_init`）— 全 schema。
- Mobile：`SignInScreen`、Google sign-in、Apple sign-in、`auth_providers.dart` AsyncNotifier、`dio_client.dart` 含 `_AuthInterceptor`。

---

## Sprint 0 — 專案 init（2026-04-30）

### Added

- 倉庫初始化、`api/` + `mobile/` + `infra/` 目錄。
- `package.json` / `pubspec.yaml` / `tsconfig.json` / `analysis_options.yaml`。
- `infra/docker-compose.yml`（postgres:16-alpine）。
- ADRs `0001`–`0009`：portfolio tech stack、topic-first（無 swipe / match）、Conversation Eligibility、simulated verification、v1 portfolio scope、denormalised counts、channels as table、user row eager create、cloud run + neon。
- `CONTEXT.md`、`README.md`、`CLAUDE.md` 初版。
- API hello world（`/`、`/health`）。

---

## ADR 索引（時間順）

| 編號 | 名稱 | Sprint |
|---|---|---|
| 0001 | Portfolio tech stack | 0 |
| 0002 | Topic-first product, no swipe / no match | 0 |
| 0003 | Conversation Eligibility — DM gated by prior public comment | 6 |
| 0004 | Verification is simulated in v1 | 7 |
| 0005 | V1 portfolio scope | 0 |
| 0006 | Denormalized counts on Post | 4 |
| 0007 | Channels as a table, seeded from file | 0 |
| 0008 | User row is created on first Firebase verify | 1 |
| 0009 | Deploy on Cloud Run + Neon | 8 |
| 0010 | Partially align v1 with the team's pitch deck | 9 |

未來新 ADR：編號 0011 起，**永遠 +1**（DEVELOPMENT.md §7）。

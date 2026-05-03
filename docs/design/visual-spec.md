# 在哪 ZAINA — Visual Spec (distilled from pitch deck)

Source: `簡報.pdf` from team 第33組 笑鼠班 (組員：書、77、Peitsen、hsinghua、Luna、Joyce). PDF stays on user's machine; this file captures the design tokens and decisions the implementation needs.

## Palette

| Token | Hex | Use |
|---|---|---|
| `paperCream` | `#F4ECD8` | App background, scaffolds, sheets |
| `paperCreamSoft` | `#FAF3E2` | Card surfaces, input fields |
| `brickRed` | `#A23A2D` | Primary buttons, the 在/哪 logo circles, FAB, primary highlights |
| `brickRedDeep` | `#7E2B22` | Pressed states, button text on cream |
| `postboxGreen` | `#3A6B43` | Secondary accents (signboards, tags, signed-in chips) |
| `postboxGreenDeep` | `#2A4F32` | Hover/pressed for green elements |
| `bobaBrown` | `#8E6849` | Tertiary, body text emphasis, vintage frame outlines |
| `bobaBrownDeep` | `#5C4530` | Muted text |
| `goldSparkle` | `#D6B05A` | Sparkles around logo, success accents |
| `inkBlack` | `#2D2118` | Body text |

## Typography

Use the platform default Chinese system font (PingFang TC on iOS, Noto Sans TC on Android). The deck uses bold headings + medium body; mirror with:
- `headingLarge`: 24sp, weight 700
- `headingMedium`: 20sp, weight 700
- `body`: 15sp, weight 400
- `caption`: 12sp, weight 400, color `bobaBrownDeep`

Logo uses heavier serif-feeling display (we'll use `FontWeight.w900` on the system font with letter-spacing tightened — close enough for portfolio without shipping a custom font).

## Logo mark

The iconic device: two red circles stacked left-right (white border, brick red fill), white character `在` in left circle, `哪` in right circle. Underneath: `ZAINA` in red serif-weight letters with a vertical bar between `ZAI` and `NA`. Sparkles flanking optional.

## Bottom navigation (5 tabs per deck IA)

| Order | Label | Route | Notes |
|---|---|---|---|
| 1 | 動態 | `/feed` | Two top tabs (我關注 / 同城) + channel filter chip strip + ✏️ FAB |
| 2 | 夥伴 | `/companions` | Daily recommendations card list. No swipe. 追蹤 + 略過 actions |
| 3 | 通知 | `/notifications` | Comments on my posts, new DMs, new posts in followed channels |
| 4 | 訊息 | `/messages` | Conversation list — message_request items badged |
| 5 | 我 | `/me` | Profile + ✓驗證 + ✏️編輯 + ↪登出 |

Channel management (follow/unfollow per channel, full list) moves from a top-level tab to a button on the 動態 AppBar that opens a sheet — the deck does not give 看板 its own tab.

## Sign-in screen

- Paper background
- Centered logo, ~30% from top
- 3 cup-clinking illustration row below title (use emoji `🧋🧋🧋` arranged in a row as v1 stand-in for the deck's hand-drawn art)
- Three full-width buttons stacked, `12px` between:
  - Facebook 登入 — `#1877F2` background, white text + `f` icon (decorative; show snackbar on tap explaining deferred config)
  - Google 登入 — white background, `bobaBrownDeep` border, Google G icon (functional)
  - Apple 登入 — black background, white text (functional, iOS only — hidden on Android per ADR-0001)
- Footer: "註冊即表示您同意我們的條款" disclaimer text in 12sp `bobaBrownDeep`

## Post card (招牌看板 style)

Two visual flavours used in deck:
1. **Image background card** — full-bleed image, scrim at bottom with title in white. Channel name + city in small chip top-left
2. **Signboard card** — solid color background (red or green), centered Chinese characters in vertical bubble-tea-circle style (e.g. `讚 / 早 / 上 / 好`). Looks like a mini hand-painted shop sign

For v1, all cards default to **signboard style** unless the post has `imageUrl` set. Each card shows: channel chip + city + title + body excerpt + author + like/comment counts.

## Onboarding stepper

Top of every onboarding screen: 3 step indicator pills (帳號驗證 / 身份驗證 / 個人資料) with checkmark when complete. Active step `brickRed`, completed step `postboxGreen`, future step `bobaBrown` outlined.

Steps:
1. 帳號驗證 — nickname + username availability + city
2. 身份驗證 — student/employee toggle + ISIC photo placeholder upload (verification.simulated stays per ADR-0004)
3. 個人資料 — gender + interests + channel follow

Final screen: full-bleed `歡迎光臨` red+green signboard art (two bubble tea cups + 歡迎光臨 vertical chars), `恭喜您完成設定` heading, `開啟探索` primary button → `/feed`.

## Voice / copy

Substitute Material-flavoured strings throughout:
- `登入` instead of `Sign in`
- `送出中…` instead of `Loading…`
- `哈囉，<name>` (already in use) — keep
- Onboarding success: `歡迎光臨` (deck wording)
- Empty states: `還沒有人在這裡留言。哩厚！第一個來吧` (sample template)
- DM eligibility refusal: `先在公開區互動，珍奶喝完再來敲門` (replaces the current technical wording)

## What the deck has but we are NOT implementing

See ADR-0010. Short list: swipe/match, MBTI/zodiac/lifestyle profile fields, 專屬話題 editor, full 招牌看板 编輯器, ISIC OCR, Facebook live auth, 未登入瀏覽.

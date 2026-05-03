# Partially align v1 with the team's pitch deck

The team's pitch deck (第33組 笑鼠班) defines a Taiwan-themed retro visual identity and an information architecture (5 bottom-nav tabs, 話題-centric content unit, 夥伴 daily recommendation, 招牌看板 vintage signage post cards, 專屬話題 conversation starters, ISIC OCR-driven verification, MBTI / 星座 / 抽菸 / 飲酒 / 睡眠 profile fields, Facebook + Google + Apple sign-in, 未登入瀏覽) that v1 deliberately did not implement. ADR-0001 / 0002 / 0004 / 0005 / 0007 documented those cuts in service of "8 Sprints of demonstrable progress" instead of "half-finished feature catalog."

After Sprint 8 shipped, we revisited the deck and chose to partially re-align: every previously cut decision still stands, but we now port over the visual identity and the cheapest of the missing features so the demo no longer reads as a generic Material 3 app. This is **option B** of three considered (A = re-skin only; C = full IA rebuild — would have invalidated Sprints 5-7).

## What we add now

- **Visual identity layer** — paper-textured cream surface, 石磚紅 / 郵筒綠 / 珍奶咖 palette, custom 在哪 logo, bubble-tea iconography, 招牌看板 post cards, Taiwan colloquial copy ("哩厚", "歡迎光臨")
- **5-tab bottom nav** matching the deck (動態 / 夥伴 / 通知 / 訊息 / 我) — 看板 management moves from a tab to a button on the 動態 AppBar, since the deck's home page also surfaces channel filter chips at the top of 話題 rather than as a tab
- **夥伴 daily recommendation** — same-city or shared-interest cards. *Compatible with ADR-0002* because there is no swipe and no symmetric match: the 「追蹤」 button creates a unilateral UserFollow row; 「略過」 is non-persistent
- **通知 tab** — derived ad-hoc from existing tables (comments on my posts, new DMs, new posts in channels I follow). No new schema
- **帳號名稱 (`@username`)** — add `User.username` (nullable, unique). Displayed on profile. Optional onboarding step with availability check. Differs from ADR-0005's cut of MBTI/zodiac/etc. because username is *infrastructure* (stable identifier in URLs and mentions), not a profile attribute

## Still cut, still cut for the same reason

- **Swipe / match** — ADR-0002 stands. 夥伴 cards are recommendations, not Tinder.
- **MBTI / 星座 / 抽菸 / 飲酒 / 睡眠 / 生活作息 / 去過的國家** — ADR-0005. Visible in deck mockups but adds 7 enums + 7 profile screens for negligible portfolio uplift.
- **專屬話題 + 招牌看板 / 圖片看板 editor** — ADR-0005. The signage *visual* lands as a card style in feed, but the per-post signage editor is out of scope.
- **ISIC OCR + crop** — ADR-0004. Verification stays simulated; the upload UI shows the ISIC card placeholder per deck.
- **Facebook 登入** — adding the button is a button, but the actual flow needs a Facebook Developer App + key-hash registration + Firebase Console provider setup, all user-side. Deferred to a Sprint 9.x once the user has those credentials. The button appears in the redesigned sign-in screen as visual placeholder with a snackbar disclosing the deferred state.
- **未登入瀏覽** — the deck supports a "未登入模式" browse path. Out of scope: every read endpoint already requires `requireAuth` per Sprint 1, and changing that would touch all of feed.ts / users.ts / channels.ts. The eager User row creation (ADR-0008) makes anonymous browse a separate IA branch we don't need for portfolio.

## Trade-off

Visual re-skin without IA rewrite means the rendered app reads as the team's product, but the Sprint 5-7 endpoints/data model remain (channels, denormalised counts, message_request promotion). The recruiter sees Taiwan branding + reasonable IA + working backend; reviewers reading ADRs see clear rationale for what's kept, cut, and added now.

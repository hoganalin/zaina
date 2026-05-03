# 在哪 ZAINA

A topic-first social app for overseas Taiwanese (旅居海外的台灣人) to find conversation, connection, and a sense of home. Built as a portfolio project to demonstrate Flutter + Node.js + cloud-deployed full-stack development.

## Language

**Topic-first**:
The app's core loop is "browse 看板 → read/post → engage → DM". There is no swipe, no match.
_Avoid_: matching, swipe, 配對

**User**:
A person whose identity has been verified by Firebase Auth (Google or Apple sign-in). One Firebase identity corresponds to exactly one User row. The row is created at first verified sign-in with `onboardingCompleted=false` and a placeholder nickname; Onboarding (Sprint 2) fills in nickname, gender, city, and interests. A User without onboarding has signed in but is not yet usable as an Author or Followed Person.
_Avoid_: account, member, profile (these refer to different concerns)

**Followed Person (追蹤的人)**:
A user another user has chosen to follow or has DM'd. The underlying relationship is a unilateral **UserFollow** row (no mutual-confirmation step).
_Avoid_: match, mutual follow

**夥伴 / Companion**:
The UI label for the daily-recommendation tab introduced in Sprint 9 (ADR-0010). Cards show same-city or shared-interest users with a 「追蹤」 / 「略過」 action. **「追蹤」 creates a UserFollow row — same backend as Followed Person**; the term differs only in surface copy because the deck mockups use 夥伴 there. There is still **no swipe and no symmetric match** — ADR-0002 stands.
_Avoid_: buddy, match (the swipe kind)

**Username (@handle)**:
A unique stable identifier (3-20 chars, letters/digits/underscore) on the User row, displayed as `@username`. Optional — onboarding can be skipped and added later in `/edit-profile`. `GET /api/me/check-username` does the live availability probe; `PATCH /api/me` and `PATCH /api/me/onboarding` both accept it and return 409 on conflict.
_Avoid_: handle, login (those mean other things)

**Notification (通知)**:
Items shown in the 通知 tab. Derived ad-hoc from existing tables (no Notification table) — the four sources are: comments on the requester's posts, new DMs received, new posts in followed channels, and new followers. Cap 50, last 30 days.
_Avoid_: alert, push (push is the OS-level FCM delivery, separate concept)

**Interest (興趣)**:
A fixed lifestyle attribute on a user's profile (e.g. 跑步, 動漫). Selected during onboarding. Used for profile display and recommendation seeding. A User does NOT follow Interests.
_Avoid_: tag, hobby

**Channel (看板)**:
A pre-defined topical category that groups related Posts (e.g. 租屋, 旅遊, 升學, 心情). Drawn from a fixed admin-curated list — users cannot create their own. A User can follow / unfollow Channels.
_Avoid_: topic, 話題, board, 主題, 頻道, subreddit

**Post (貼文)**:
A single thread authored by a User inside one Channel (e.g. "今天是我生日", "找紐約合租夥伴"). Has author, channel, body, **city**, comments, likes, view count. Any User can author a Post.
_Avoid_: topic, 話題, thread

**Post City (貼文所在城市)**:
A required attribute on every Post indicating where the post is geographically anchored. Defaults to the User's profile city but can be overridden per Post (e.g. someone in NYC posting about Taipei). Drives feed sorting.
_Avoid_: location, region

**Feed (動態)**:
The Post listing on the home screen. Has two tabs: **所有話題 / 我關注** (followed Channels) and **同城** (Posts where `post.city == user.city`). Each tab is paginated by `createdAt desc`. Bottom navigation has 5 sibling tabs total: 動態 / 夥伴 / 通知 / 訊息 / 我.
_Avoid_: timeline, stream

**Conversation Eligibility (對話資格)**:
The rule that gates who may initiate a DM with whom. A can DM B iff at least one of: A commented on a Post by B; B commented on a Post by A; A and B both commented on the same Post. The product has no swipe / no match — public commenting is the only path into private chat.
_Avoid_: match, mutual follow

**Message Request (訊息請求)**:
The first DM sent under a newly-formed Conversation Eligibility lands here, not in B's main inbox. B promotes it to a full conversation by accepting or replying. Mirrors IG / FB Messenger UX.
_Avoid_: pending message, intro

**Block (封鎖)**:
A unilateral action where User A hides User B's Posts and severs DM eligibility regardless of comment history. The v1 safety mechanism. Reporting (檢舉) is explicitly out of scope for v1.
_Avoid_: mute, report, hide

**Verification (身份驗證)**:
The optional onboarding step where a User uploads a student or work ID. In v1 the review pipeline is **simulated**: uploads are stored, a Verification record is written with status=pending, and a scheduled job (or admin endpoint) auto-approves after a delay. The product roadmap will replace this with a real ISIC / employer verification API. A User without verification has full functionality — only the **Verified Badge** (✓ 已認證) is missing.
_Avoid_: KYC, identity check

**Verified Badge (認證徽章)**:
A visual marker (✓ 已認證) shown on a User's profile and posts after Verification is approved. Cosmetic only in v1 — does not gate any feature. Onboarding allows users to skip verification and earn the badge later from their profile.
_Avoid_: trusted, premium

## Relationships

- A **User** picks many **Interests** during onboarding (profile attribute, no follow relation)
- A **User** follows zero or more **Channels**
- A **User** authors zero or more **Posts**; each **Post** belongs to exactly one **Channel** and has exactly one **Post City**
- A **User** can mark another **User** as a **Followed Person** (UserFollow row)
- A **User** can claim a unique **Username** for stable identification
- A viewer's **Feed** has 「所有話題 / 同城」 tabs; sorted by recency within each
- The 夥伴 tab shows **Companion** recommendations (same-city or shared-interest, excluding blocks and existing follows)
- The 通知 tab aggregates **Notifications** ad-hoc from comments / DMs / new posts in followed channels / new followers
- A **User** has **Conversation Eligibility** with another User only via prior public comment interaction; the first DM lands as a **Message Request**
- A **User** can **Block** another User unilaterally, overriding all eligibility

## Flagged ambiguities

- "話題" in the original mockups was overloaded across three concepts (Interest / Channel / Post) — resolved: split into three terms. **The word 話題 is retired in the data model** (no Topic entity exists) but **resurfaces as UI copy** in two places: the feed's pill segmented control labels「所有話題」/「追蹤話題」, and the 「特別話題」 sticker on yellow-signboard cards. Those are deck-driven surface strings; underneath, the entities are Channels and Posts.
- "夥伴" was retired from the data model in favour of unilateral UserFollow, but **resurfaces as UI copy for the Sprint 9 dailies tab** (deck-driven; ADR-0010). The term still does NOT mean "matched" — it's a unilateral follow recommendation.
- "配對" appears in the original mockups but is explicitly out of scope — the product replaces matching with topic-centered conversation. ADR-0002 stands.

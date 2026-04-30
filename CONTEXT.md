# 在哪 ZAINA

A topic-first social app for overseas Taiwanese (旅居海外的台灣人) to find conversation, connection, and a sense of home. Built as a portfolio project to demonstrate Flutter + Node.js + cloud-deployed full-stack development.

## Language

**Topic-first**:
The app's core loop is "browse 看板 → read/post → engage → DM". There is no swipe, no match.
_Avoid_: matching, swipe, 配對

**Followed Person (追蹤的人)**:
A user another user has chosen to follow or has DM'd. Replaces the earlier term 夥伴.
_Avoid_: 夥伴, buddy, companion, match

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

**Feed**:
The Post listing on the home screen. Has two tabs: **所有看板** (all Channels, default) and **追蹤看板** (followed Channels only). Within each tab, Posts are sorted by geographic proximity to the viewer's profile city: same city > same country > same continent > global, then by recency.
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
- A **User** can mark another **User** as a **Followed Person**
- A viewer's **Feed** ranks Posts by proximity of **Post City** to the viewer's profile city, then by recency
- A **User** has **Conversation Eligibility** with another User only via prior public comment interaction; the first DM lands as a **Message Request**
- A **User** can **Block** another User unilaterally, overriding all eligibility

## Flagged ambiguities

- "話題" in the original mockups was overloaded across three concepts (Interest / Channel / Post) — resolved: split into three terms. The word "話題" is retired entirely in favour of the more precise terms.
- "夥伴" was used in the original mockups to mean both "matched user" and "person I follow" — resolved: this product has no match concept, so the term is retired in favor of **Followed Person (追蹤的人)**.
- "配對" appears in the original mockups but is explicitly out of scope — the product replaces matching with topic-centered conversation.

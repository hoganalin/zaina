# V1 portfolio scope

V1 ships nine functional features — auth, onboarding, feed, channels, posting, comments + likes, DM (Socket.io + Conversation Eligibility), profile, block — plus simulated verification (ADR-0004) and basic push notifications. Explicitly excluded: swipe / match, real verification review, group chat, activities, listings, MBTI / zodiac / smoking / drinking profile fields, hashtags, reporting, soft delete, multi-language.

The cut is driven by portfolio value — eight Sprints of demonstrable progress is preferable to a half-finished feature catalog. Roadmap items (camera capture, group chat, AI matching, regional Channels, festive sticker packs) are documented in the README's "Future" section as deliberate signals of product thinking.

## Sprint breakdown

| Sprint | Scope |
|---|---|
| 0 | Repo init, skeleton, local hello-world |
| 1 | Google + Apple sign-in → Firebase verify → DB User row |
| 2 | Onboarding (nickname / gender / city / interests / channels) |
| 3 | Read-only Feed with seed Posts, two tabs |
| 4 | Posting + Comment + Like (denormalised counts per ADR-0006) |
| 5 | Channel follow/unfollow, profile pages |
| 6 | DM with Socket.io + Conversation Eligibility + Message Request |
| 7 | Verification UI + Block + push notifications |
| 8 | GCP deploy + README polish + screenshots + demo recording |

# 在哪 ZAINA

> A topic-first social app for overseas Taiwanese (旅居海外的台灣人) — find conversation, connection, and a sense of home.

[![status](https://img.shields.io/badge/status-v1%20feature%20complete-success)]()
[![stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Hono%20%2B%20GCP-blue)]()
[![tests](https://img.shields.io/badge/api%20tests-48%20passing-success)]()
[![design](https://img.shields.io/badge/design-deck%20aligned-d6a85a)]()

## Why this project exists

This is a portfolio project. It demonstrates a complete vertical slice of modern social-app development — Flutter mobile, Node.js (Hono) API, Postgres + Prisma, Firebase Auth, Socket.io realtime DM, and GCP deployment — built in eight Sprints with deliberate, documented architectural decisions.

The product itself is real: a topic-first (no swipe, no match) social space where overseas Taiwanese discover each other through public conversation about renting, food, travel, and life abroad. See [`CONTEXT.md`](./CONTEXT.md) for the domain model.

## Stack

| Layer | Technology | Why |
|---|---|---|
| Mobile | Flutter + Riverpod + freezed + dio | Cross-platform, modern state mgmt, type-safe HTTP |
| API | TypeScript + Hono + REST | TS-native framework with built-in Zod validation |
| Database | PostgreSQL + Prisma ORM | Industry standard, auto-generated TS types |
| Auth | Firebase Auth (Google + Apple) | 5-line OAuth integration, free tier covers portfolio |
| Realtime | Socket.io | Auto-reconnect for mobile networks |
| Storage | Google Cloud Storage | Private buckets + signed URLs for ID images |
| Database hosting | Neon (managed Postgres) | Permanent free tier, branching for dev/staging |
| API hosting | GCP Cloud Run | Scale-to-zero, Docker-based deploys |

See [`docs/adr/0001-portfolio-tech-stack.md`](./docs/adr/0001-portfolio-tech-stack.md) for the reasoning.

## Architecture

```mermaid
flowchart LR
  subgraph Client[Mobile · Flutter]
    UI[Screens<br/>Riverpod]
    Dio[dio + auth interceptor]
    Sock[socket_io_client]
    FCM[firebase_messaging]
  end

  subgraph API[Cloud Run · Hono]
    REST[REST routes<br/>+ zod validators]
    Mw[requireAuth middleware]
    SocketSvr[Socket.io server]
    Eligibility[canDM]
    Push[FCM sendPush]
  end

  subgraph Data
    Neon[(Neon Postgres<br/>via Prisma)]
  end

  subgraph Firebase
    Auth[Auth<br/>verifyIdToken]
    FBMsg[Cloud Messaging]
  end

  UI --> Dio
  UI --> Sock
  UI --> FCM
  Dio -- "Bearer ID token" --> REST
  Sock -- "auth: ID token" --> SocketSvr
  REST --> Mw --> Eligibility
  Mw -- verify --> Auth
  REST --> Neon
  SocketSvr --> Neon
  REST --> Push --> FBMsg --> FCM
  SocketSvr -. "message:new emit" .-> Sock
```

## Repository layout

```
zaina/
├── mobile/                 Flutter app (iOS + Android)
├── api/                    Node.js + Hono backend
├── infra/                  docker-compose for local Postgres
├── docs/adr/               Architecture Decision Records (10 records)
├── docs/design/            Visual spec, Figma tokens, reference renders
├── docs/design/reference/  signin / splash / feed / first_login / logo PNGs
├── CONTEXT.md              Domain language and relationships
├── CLAUDE.md               Instructions for Claude Code (AI pair)
├── DEPLOY.md               GCP Cloud Run deploy guide
└── README.md               This file
```

## Getting started

### Prerequisites

- Node.js 22+
- Flutter 3.41+
- Docker (for local Postgres) **or** a Neon connection string
- A Firebase project with Google + Apple sign-in enabled
- The Firebase Admin service account JSON dropped at `api/secrets/`

### API (Hono + Prisma)

```bash
cd api
npm install
cp .env.example .env       # fill in DATABASE_URL and FIREBASE_*
npx prisma migrate dev
npm run prisma:seed        # 12 channels + 12 interests + 5 demo authors + 36 posts
npm run dev                # http://localhost:3000
npm test                   # 48 vitest cases against a live (Neon) DB
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs    # freezed + json_serializable
flutter run                # picks up Android emulator / iOS simulator
```

Override the API host (e.g. for a real device hitting your LAN):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000
```

### Local Postgres (optional, instead of Neon)

```bash
cd infra
docker compose up -d
# DATABASE_URL=postgresql://zaina:zaina@localhost:5432/zaina
```

### Deploying to GCP

Step-by-step Cloud Run deploy in [`DEPLOY.md`](./DEPLOY.md).

## Demo flow

A reviewer can walk every Sprint in 4–5 minutes. Bottom nav has five tabs — **動態 / 夥伴 / 通知 / 訊息 / 我** — themed as bubble-tea cup variants per the deck.

1. **Sign in** with Google. Splash shows the 在哪 logo + sun-ray + 3-cup illustration cropped from the team's Figma. Backend find-or-creates the User row (Sprint 1).
2. **Onboarding** — 4 steps: nickname / @username (live availability check) / interests / channels. Finish lands on a 「歡迎光臨」 signboard modal (Sprint 2 + Sprint 9 username step).
3. **Feed** (動態 tab) — 2-column masonry of post cards. Six visual templates cycle by post id hash: image+multi-stack-stamps, image+sticker+caption, red sunburst, yellow signboard with red border, paper speech bubble, green panel (Sprint 3 + ADR-0010).
4. **Compose a post** via the FAB; tap it from the feed (Sprint 4 read).
5. **Tap the heart**, leave a comment, then watch likeCount + commentCount update (Sprint 4 write + ADR-0006).
6. **看板** sub-screen (動態 AppBar icon) — toggle channel follow on/off, watch the 動態 feed change (Sprint 5).
7. **夥伴** tab — daily recommendation cards (same-city or shared-interest), 追蹤 / 略過 actions. No swipe — ADR-0002 stands.
8. **通知** tab — derived feed of comments on your posts, new DMs, new posts in followed channels, new followers (Sprint 9, no Notification table; queried ad-hoc).
9. **我** tab → edit profile (city, bio) and visit a seed author's profile from a post (Sprint 5).
10. **Tap 「私訊」** on someone you've never interacted with → eligibility error per ADR-0003.
11. **Comment on their post** first, retry 「私訊」 → conversation lands in 訊息 tab badged "訊息邀請" (Sprint 6 + ADR-0003).
12. **Verify** your account from 我 → ✓ (Sprint 7 + ADR-0004 simulated review).
13. **Block** a user from their profile overflow menu — their posts vanish from your feeds (Sprint 7).

## Sprint roadmap

| Sprint | Status | Scope |
|---|---|---|
| 0 | ✅ done | Repo init, skeleton, decisions documented |
| 1 | ✅ done | Google + Apple sign-in → Firebase verify → DB User |
| 2 | ✅ done | Onboarding (nickname / gender / city / interests / channels) |
| 3 | ✅ done | Read-only Feed with seed posts, two tabs |
| 4 | ✅ done | Posting + Comment + Like |
| 5 | ✅ done | Channel follow/unfollow, profile pages |
| 6 | ✅ done | DM with Socket.io + Conversation Eligibility + Message Request |
| 7 | ✅ done | Verification UI + Block + push notifications |
| 8 | ✅ done | GCP deploy + screenshots + demo recording |
| 9 | ✅ done | Visual re-skin to deck + 夥伴 / 通知 / @username (ADR-0010) |

Detailed scope: [`docs/adr/0005-v1-portfolio-scope.md`](./docs/adr/0005-v1-portfolio-scope.md).

## Key product decisions

- **Topic-first, no swipe / no match.** [ADR-0002](./docs/adr/0002-topic-first-no-match.md)
- **DM gated by prior public comment** (Conversation Eligibility). [ADR-0003](./docs/adr/0003-conversation-eligibility.md)
- **Verification flow is simulated in v1** (real flow surface, fake review backend). [ADR-0004](./docs/adr/0004-simulated-verification.md)
- **Denormalised Post counts** (likeCount / commentCount cached on Post). [ADR-0006](./docs/adr/0006-denormalized-post-counts.md)
- **Channels as a table, seeded from file.** [ADR-0007](./docs/adr/0007-channels-as-table.md)
- **User row created at first verified sign-in** (eager, not lazy). [ADR-0008](./docs/adr/0008-user-row-on-firebase-verify.md)
- **Cloud Run + Neon** over Cloud SQL — scale-to-zero portfolio economics. [ADR-0009](./docs/adr/0009-cloud-run-and-neon.md)
- **Partial alignment with team's Figma deck** after Sprint 8 — re-skin + selected features (夥伴 / 通知 / @username), explicit list of what stays cut. [ADR-0010](./docs/adr/0010-deck-partial-alignment.md)

## Visual layer

The Sprint 9 re-skin is driven by the team's pitch deck and Figma file (`JGUawgfQV6xjWlirhpk73y`). Source-of-truth tokens live in [`docs/design/figma-tokens.md`](./docs/design/figma-tokens.md) (5 colour scales × 11 stops, pulled directly via the Figma REST API). Component / IA notes in [`docs/design/visual-spec.md`](./docs/design/visual-spec.md). Reference renders saved in [`docs/design/reference/`](./docs/design/reference/).

Brand palette implemented in [`mobile/lib/theme/zaina_theme.dart`](./mobile/lib/theme/zaina_theme.dart):

| Role | Hex | Notes |
|---|---|---|
| App background | `#FAF5EC` | base-50, paper cream |
| Primary (brick red) | `#AF3737` | primary-700, buttons + FAB |
| Secondary (postbox green) | `#2A522A` | secondary-700, chat bubbles + signboard frames |
| Boba brown | `#846549` | neutral-600, body emphasis |
| Gold accent | `#E9A936` | accent-400, sun-rays + verified |
| Ink | `#2C1F1A` | neutral-950 |

Re-usable design widgets:

- `lib/widgets/zaina_logo.dart` — 在哪 dual-circle logo + welcome signboard
- `lib/widgets/paper_background.dart` — programmatic paper-noise texture
- `lib/widgets/sun_ray_background.dart` — gold radial fan, used on splash + welcome
- `lib/widgets/signboard_card.dart` — 6-template post card cycling by post id hash

## Future (post-v1)

- Real ISIC / employer verification backend
- Group chats + activity boards
- Regional Channels (東京板, 倫敦板)
- Festive sticker packs (春節紅包, 端午節)
- "我的情感地圖" — personal connection map
- Cron-based count reconciliation
- Camera-capture path for ID upload (in addition to gallery selection)

## Credits

Original product design and pitch deck: 第33組 笑鼠班 — 書, 77, Peitsen, hsinghua, Luna, Joyce.
Engineering, scoping, and ADRs: this repo.

---

🤖 This project is built with heavy use of Claude Code as a pair-programmer, demonstrating AI-augmented full-stack development.

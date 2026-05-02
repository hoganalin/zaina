# 在哪 ZAINA

> A topic-first social app for overseas Taiwanese (旅居海外的台灣人) — find conversation, connection, and a sense of home.

[![status](https://img.shields.io/badge/status-v1%20feature%20complete-success)]()
[![stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Hono%20%2B%20GCP-blue)]()
[![tests](https://img.shields.io/badge/api%20tests-48%20passing-success)]()

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
├── mobile/         Flutter app (iOS + Android)
├── api/            Node.js + Hono backend
├── infra/          docker-compose for local Postgres
├── docs/adr/       Architecture Decision Records
├── CONTEXT.md      Domain language and relationships
├── CLAUDE.md       Instructions for Claude Code (AI pair)
└── README.md       This file
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

A reviewer can walk every Sprint in 4–5 minutes:

1. **Sign in** with a Google account → backend find-or-creates the User row (Sprint 1).
2. **Onboarding** — pick nickname, city, interests, follow channels (Sprint 2).
3. **Feed** — switch between **我關注** and **同城** tabs (Sprint 3).
4. **Compose a post** via the FAB; tap it from the feed (Sprint 4 read).
5. **Tap the heart**, leave a comment, then watch likeCount + commentCount update (Sprint 4 write + ADR-0006).
6. **Channels tab** — toggle following on/off, watch the **我關注** feed change (Sprint 5).
7. **Profile tab** — edit your bio, then visit a seed author's profile from a post (Sprint 5).
8. **Tap 「私訊」** on someone you've never interacted with → eligibility error.
9. **Comment on their post** first, retry 「私訊」 → conversation lands in Message Request (Sprint 6 + ADR-0003).
10. **Verify** your account from Profile → 驗證 (Sprint 7 + ADR-0004 simulated review).
11. **Block** a user from their profile overflow menu — their posts vanish from your feeds (Sprint 7).

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

Detailed scope: [`docs/adr/0005-v1-portfolio-scope.md`](./docs/adr/0005-v1-portfolio-scope.md).

## Key product decisions

- **Topic-first, no swipe / no match.** [ADR-0002](./docs/adr/0002-topic-first-no-match.md)
- **DM gated by prior public comment** (Conversation Eligibility). [ADR-0003](./docs/adr/0003-conversation-eligibility.md)
- **Verification flow is simulated in v1** (real flow surface, fake review backend). [ADR-0004](./docs/adr/0004-simulated-verification.md)
- **Denormalised Post counts** (likeCount / commentCount cached on Post). [ADR-0006](./docs/adr/0006-denormalized-post-counts.md)
- **Channels as a table, seeded from file.** [ADR-0007](./docs/adr/0007-channels-as-table.md)
- **User row created at first verified sign-in** (eager, not lazy). [ADR-0008](./docs/adr/0008-user-row-on-firebase-verify.md)
- **Cloud Run + Neon** over Cloud SQL — scale-to-zero portfolio economics. [ADR-0009](./docs/adr/0009-cloud-run-and-neon.md)

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

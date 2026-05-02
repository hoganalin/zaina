# 在哪 ZAINA

> A topic-first social app for overseas Taiwanese (旅居海外的台灣人) — find conversation, connection, and a sense of home.

[![status](https://img.shields.io/badge/status-in%20development-yellow)]()
[![stack](https://img.shields.io/badge/stack-Flutter%20%2B%20Hono%20%2B%20GCP-blue)]()

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

> Sprint 0 sets up the skeleton; Sprint 1 (auth) is the first running feature. Setup commands below assume you've completed Sprint 0.

### Prerequisites

- Node.js 20+
- Flutter 3.19+
- Docker (for local Postgres) **or** a Neon connection string
- A Firebase project with Google + Apple sign-in enabled

### API (Hono + Prisma)

```bash
cd api
npm install
cp .env.example .env       # fill in DATABASE_URL and FIREBASE_*
npx prisma migrate dev
npx prisma db seed         # creates the 12 Channels and Interests
npm run dev                # http://localhost:3000
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run                # picks up running iOS simulator / Android emulator
```

### Local Postgres (optional, instead of Neon)

```bash
cd infra
docker compose up -d
# DATABASE_URL=postgresql://zaina:zaina@localhost:5432/zaina
```

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
| 8 | ⏳ | GCP deploy + screenshots + demo recording |

Detailed scope: [`docs/adr/0005-v1-portfolio-scope.md`](./docs/adr/0005-v1-portfolio-scope.md).

## Key product decisions

- **Topic-first, no swipe / no match.** [ADR-0002](./docs/adr/0002-topic-first-no-match.md)
- **DM gated by prior public comment** (Conversation Eligibility). [ADR-0003](./docs/adr/0003-conversation-eligibility.md)
- **Verification flow is simulated in v1** (real flow surface, fake review backend). [ADR-0004](./docs/adr/0004-simulated-verification.md)
- **Denormalised Post counts** (likeCount / commentCount cached on Post). [ADR-0006](./docs/adr/0006-denormalized-post-counts.md)
- **Channels as a table, seeded from file.** [ADR-0007](./docs/adr/0007-channels-as-table.md)

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

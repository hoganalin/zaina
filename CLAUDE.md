# CLAUDE.md

Instructions for Claude Code working in this repository.

## What this repo is

A portfolio social app called **在哪 ZAINA**, built to demonstrate full-stack ability for a specific job posting (Flutter / Node.js / Vibe Coding / GCP). The product is real and the code is intended to be runnable, but **scope decisions consistently favor "demonstrable in an interview" over "production-ready at scale"**.

## Read these first

- [`CONTEXT.md`](./CONTEXT.md) — domain language. Use these terms, avoid the "Avoid" terms. Example: it's a **Channel (看板)**, not a "topic" or "subreddit"; it's a **Followed Person (追蹤的人)**, never a "match" or "夥伴".
- [`docs/adr/`](./docs/adr/) — every architectural decision and why. If a code pattern looks unusual (e.g. denormalised counts, simulated verification), check the ADRs before "fixing" it.

## Repository layout

```
mobile/         Flutter app
api/            Node.js + Hono + Prisma backend
infra/          docker-compose for local Postgres
docs/adr/       Architecture Decision Records (always increment by 1)
```

The `mobile/` and `api/` directories are independent — no shared package manager. Don't try to introduce a monorepo tool (turborepo, nx, pnpm workspace) unless the user explicitly asks.

## Coding conventions

### API (TypeScript + Hono)

- Strict TypeScript (`"strict": true`). Never use `any`; prefer `unknown` then narrow.
- Validate every request body and query string with `@hono/zod-validator`. Don't read raw `req.body`.
- Use Prisma for all DB access. Wrap multi-step writes in `prisma.$transaction(...)`.
- Endpoints follow REST: `GET /api/posts`, `POST /api/posts/:id/comments`, etc.
- Auth middleware sets `c.set('userId', ...)` after verifying Firebase token. Routes that need auth start with `requireAuth` middleware.
- Update denormalised counters (`likeCount`, `commentCount`) in the same transaction as the underlying write — see [ADR-0006](./docs/adr/0006-denormalized-post-counts.md).

### Mobile (Flutter + Riverpod)

- State management: **Riverpod**, not Provider, not Bloc, not GetX.
- Models: **freezed + json_serializable**. Never write `fromJson` / `toJson` by hand.
- HTTP: **dio** with a singleton client. Auth interceptor injects the Firebase ID token on every request.
- Async data: `FutureProvider` / `StreamProvider`. Don't use `FutureBuilder` directly in widgets.
- File: 1 screen = 1 directory under `lib/screens/<screen>/`. Each holds the screen widget, its providers, and its state types.

### Commits

- Conventional commit prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`.
- One Sprint feature ≈ one PR; commits within can be smaller.
- Never `--amend` published commits. Pre-commit hook failure → fix and write a new commit.

## Sprint state

Sprint progress lives in the README's roadmap table. When starting a Sprint, update its status to 🚧; when shipping it, mark ✅ and commit.

## Tools the user wants you to use

- **`/grill-with-docs`** when starting a non-trivial new feature — sharpen the design against the domain model first.
- **`/tdd`** when implementing a feature — red / green / refactor, one vertical slice at a time.
- **`/to-issues`** when breaking a Sprint into tracked work items.

These live user-globally at `~/.claude/skills/` (not committed in this repo). Don't substitute other skills without asking.

## Scope rule

If something feels like it should be added "for completeness" or "for production" — check [ADR-0005](./docs/adr/0005-v1-portfolio-scope.md) first. The v1 cut is deliberate. Out-of-scope features go in the README's "Future" section, not into the code.

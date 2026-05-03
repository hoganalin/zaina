# CLAUDE.md

Instructions for Claude Code working in this repository.

## What this repo is

A portfolio social app called **在哪 ZAINA**, built to demonstrate full-stack ability for a specific job posting (Flutter / Node.js / Vibe Coding / GCP). The product is real and the code is intended to be runnable, but **scope decisions consistently favor "demonstrable in an interview" over "production-ready at scale"**.

## Read these first

- [`CONTEXT.md`](./CONTEXT.md) — domain language. Use these terms, avoid the "Avoid" terms. Example: it's a **Channel (看板)**, not a "topic" or "subreddit". (Note: post-Sprint-9, **「夥伴」(companion) is now in active use** as a unilateral-follow recommendation tab — see ADR-0010. Older copy that called it "Followed Person" only is stale.)
- [`docs/adr/`](./docs/adr/) — every architectural decision and why. If a code pattern looks unusual (e.g. denormalised counts, simulated verification, multi-template signboard cards), check the ADRs before "fixing" it.
- [`docs/design/visual-spec.md`](./docs/design/visual-spec.md) + [`docs/design/figma-tokens.md`](./docs/design/figma-tokens.md) — the deck visual layer. Brand palette, typography, component cycle. Do NOT eyeball colours — pull from the token catalogue.

## Repository layout

```
mobile/                 Flutter app
api/                    Node.js + Hono + Prisma backend
infra/                  docker-compose for local Postgres
docs/adr/               Architecture Decision Records (always increment by 1)
docs/design/            Visual spec + Figma token catalogue
docs/design/reference/  Cached PNG renders pulled from Figma (signin/splash/feed/etc)
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
- **Theme tokens come from `lib/theme/zaina_theme.dart`**. Do not hard-code colours. Brand palette mirrors the Figma file's `顏色（Color）` frame; refresh procedure documented at the bottom of `docs/design/figma-tokens.md`.
- **Don't render `Image.network` without `cacheWidth/cacheHeight`** on the feed grid — 36 raw bitmaps blew up memory and ANR'd the app on first paint. See commit history for the regression.
- Bottom nav has **5 tabs** (動態 / 夥伴 / 通知 / 訊息 / 我) per ADR-0010. Sub-screens (channels list, edit profile, post detail, chat, verify) are top-level routes outside the shell, not branches.

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

**For deck-driven additions** (anything traceable to `簡報.pdf` or the Figma file), check [ADR-0010](./docs/adr/0010-deck-partial-alignment.md) before implementing. The "Still cut" list there is current — items like swipe/match, MBTI/zodiac/lifestyle profile fields, 專屬話題 editor, ISIC OCR, real Facebook auth, and 未登入瀏覽 stay out unless the user reverses that ADR.

## Figma access

The team's Figma file is `JGUawgfQV6xjWlirhpk73y`. A personal access token is stored in `~/.claude.json` via `claude mcp add user` (see `figma-developer-mcp`). The seat is on a Starter plan with low API quota — burning through `mcp__figma__get_figma_data` heavily can lock the API for *days*. Before doing iterative pulls, check whether the cached renders in `docs/design/reference/` already answer the question.

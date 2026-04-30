# Portfolio tech stack

We chose **Flutter** (mobile), **TypeScript + Hono + Prisma + Postgres** (API), **Firebase Auth** (identity), **GCP Cloud Run + Neon + GCS** (deployment + storage), **Socket.io** (realtime DM), and **Riverpod + freezed + dio** (Flutter state and HTTP).

This is a portfolio project targeting a specific job posting (Flutter / Node.js / AWS-or-GCP / Vibe Coding). Technical fit is secondary to **interview signal** — every component is chosen to map to a bullet point in the JD or to differentiate the project (Hono over Express for TS-native ergonomics, Neon's branching feature, Cloud Run's scale-to-zero economics).

## Considered alternatives

- **Expo + Supabase** — better DX, but no Flutter and no clear Node.js / cloud demonstration. The job calls for both.
- **Express** — safer and more searchable, but Hono's first-class TypeScript + Zod validator gives more interview talking points.
- **Cloud SQL** — managed and integrated, but no free tier; Neon's permanent free tier and DB branching are demonstrably modern.
- **Bloc state management** — common in enterprise Flutter, but Riverpod's API is closer to the user's React + Zustand mental model and produces fewer files per feature.

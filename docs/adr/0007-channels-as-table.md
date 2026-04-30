# Channels as a table, seeded from file

Channels (12 in v1: 租屋 / 二手拍 / 票券 / 旅遊 / 旅伴 / 美食 / 亞洲 / 西班牙 / 歐洲 / 獨旅 / 升學 / 心情) are stored in a dedicated `Channel` table with `slug`, `name`, `icon`, `description`. Initial channels are written via Prisma seed file, which is committed to git.

The alternative — a Prisma `enum` — would couple every channel addition to an API redeploy and a migration. Putting Channels in a table makes future additions (regional boards, partner channels) trivial, allows per-channel attributes (icon, description), and lets analytics queries `GROUP BY channel` naturally.

## Why seed from file

The canonical v1 channel list is small and meaningful — it should be version-controlled and reviewed. Seeding from a TS file in `prisma/seed.ts` keeps the list in git while still treating Channels as data, not schema.

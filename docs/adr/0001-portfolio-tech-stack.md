# Portfolio 技術選型

選用 **Flutter**（mobile）、**TypeScript + Hono + Prisma + Postgres**（API）、**Firebase Auth**（身分）、**GCP Cloud Run + Neon + GCS**（部署 + 儲存）、**Socket.io**（即時 DM）、**Riverpod + freezed + dio**（Flutter state 與 HTTP）。

這是針對特定 JD（Flutter / Node.js / AWS-or-GCP / Vibe Coding）的 portfolio 專案。技術合適度次要，**面試 signal 優先**——每個元件都對應 JD 上的一個關鍵字，或當作差異化點（Hono over Express 是 TypeScript 原生的工程性、Neon 的 branching 功能、Cloud Run 的 scale-to-zero 經濟模型）。

## 評估過的替代方案

- **Expo + Supabase**——DX 較佳，但沒有 Flutter、也無法清楚 demo Node.js / 雲端能力。JD 兩邊都要。
- **Express**——保險、查資料容易，但 Hono 一級 TypeScript + Zod validator 提供更多面試話題。
- **Cloud SQL**——managed 整合度高，但無永久免費額度；Neon 的永久免費 + DB branching 是 demonstrably modern。
- **Bloc state management**——Flutter 企業端常見，但 Riverpod API 更貼近 user 既有的 React + Zustand 心智模型，每個 feature 產出更少檔案。

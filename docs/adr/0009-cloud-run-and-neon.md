# 部署在 Cloud Run + Neon

API 以單一 container 部在 **Google Cloud Run**，DB 用 **Neon**（managed Postgres）。兩者都 scale-to-zero、都不需要 VPC peering，加總 idle 成本接近 0。

這個組合勝過更直覺的 GCP 原生組（Cloud Run + **Cloud SQL Postgres**），因為 Cloud SQL 有 minimum-instance 費用——portfolio app 不該在沒人 demo 的時候漏錢。Neon 的 connection pooler 也讓 cold start 路徑更乾淨——Cloud SQL 在 serverless 場景的官方建議是 auth proxy sidecar，活動零件比這個 scope 該有的多。

## 接受的 trade-off

- **跨雲延遲**——Cloud Run（任意 region）↔ Neon（`ap-southeast-1`）每個 query 多 30–80ms（相對於同 region Cloud SQL）。Feed query 是最熱的讀路徑，靠單一 denormalised select（ADR-0006）撐住，端到端 RTT 實測仍在 300ms 內。
- **Cloud Run cold start（~1–2s）**——idle 後第一個 request 會慢。portfolio demo 場景，reviewer 會容忍；scale-to-zero 的省錢效益值得。
- **兩家供應商而非一家**——Google 認證 Cloud Run、Neon 認證 Postgres、Firebase 認證 auth/messaging。我們接受 ops 分散，換取每個服務搭配最適合的 provider。

## 哪個元件在哪

| 用途 | Provider | 備註 |
|---|---|---|
| API container | Cloud Run | scale-to-zero；每次 `gcloud run deploy` 出一個 revision |
| Postgres | Neon | 免費額度；SQL 走 Prisma |
| Auth | Firebase Auth | Google + Apple sign-in |
| 推播 | Firebase Cloud Messaging | 新 DM 觸發 best-effort 送達 |
| 靜態資產 | （延後） | 圖片上傳 + CDN 不在 v1 |

## v1 不做

- Cloud SQL 遷移（要等讀流量大到值得 same-region pooling 才做）。
- 多 region。Portfolio demo 單 region 足夠。
- Cloud Run ↔ Neon 的 VPC + private IP。這個量級走公網 TLS 沒問題。

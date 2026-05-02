# Deploy on Cloud Run + Neon

The API ships as a single container on **Google Cloud Run** with the database hosted on **Neon** (managed Postgres). Both scale to zero, neither requires a VPC peering setup, and the combined idle cost is effectively free.

This pairing was picked over the more obvious GCP-native combo (Cloud Run + **Cloud SQL Postgres**) because Cloud SQL imposes a minimum-instance fee even when idle, and a portfolio app should not bleed money between demos. Neon's connection pooler also makes the cold-start path cleaner — Cloud SQL's recommended pattern for serverless is the auth proxy sidecar, which is more moving parts than this scope warrants.

## Trade-offs accepted

- **Cross-cloud latency** between Cloud Run (any region) and Neon (`ap-southeast-1`) adds 30–80ms per query relative to a same-region Cloud SQL setup. The feed query is the hottest read path and lives behind a single denormalised select (ADR-0006), so end-to-end RTT is still under 300ms in practice.
- **Cold start on Cloud Run** (~1–2s) means the first request after idle is slow. For a portfolio demo, the reviewer will tolerate this; the scaling-to-zero saving outweighs it.
- **Two vendors instead of one** — you authenticate at Google for Cloud Run, at Neon for Postgres, at Firebase for auth/messaging. We accept the operational fragmentation in exchange for matching each service to the best provider.

## What lives where

| Concern              | Provider | Notes |
|----------------------|----------|-------|
| API container        | Cloud Run | scale-to-zero; one revision per `gcloud run deploy` |
| Postgres             | Neon | Free tier; SQL via Prisma |
| Auth                 | Firebase Auth | Google + Apple sign-in providers |
| Push                 | Firebase Cloud Messaging | best-effort delivery on new DM |
| Static assets        | (deferred) | image upload + CDN out of v1 scope |

## Out of scope for v1

- Cloud SQL migration (only worth doing once read traffic justifies same-region pooling).
- Multi-region. Single region is sufficient for portfolio demo.
- VPC + private IP between Cloud Run and Neon. Public-IP TLS is fine at this scale.

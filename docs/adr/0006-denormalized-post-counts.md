# Denormalized counts on Post

`Post.likeCount` and `Post.commentCount` are stored as columns and updated in the same Prisma transaction that writes / deletes a `PostLike` or `Comment`. The naive alternative — computing via SQL `COUNT` per request — would add an O(N) aggregation to every Feed query, which is the app's hottest read path.

Read frequency dominates write frequency by >100×. Pay one extra `UPDATE` per write to make every Feed read O(1) per row.

## Trade-off accepted

Counts can drift in catastrophic failure modes (transaction commit half-applied, manual DB edits). We accept the drift risk in v1. A nightly cron-based reconciliation job is planned for v2 — it will recompute counts from `PostLike` and `Comment` and overwrite the cached column.

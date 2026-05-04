# Post 上的 denormalised 計數欄位

`Post.likeCount` 與 `Post.commentCount` 是欄位，由寫入 / 刪除 `PostLike` 或 `Comment` 的同一個 Prisma transaction 一起更新。直覺的替代方案——每個 request 跑一次 SQL `COUNT`——會在 app 最熱的讀路徑（Feed query）多一個 O(N) aggregation。

讀寫比 >100×。每個寫入多付一個 `UPDATE`，換每個 Feed read 每筆 O(1)。

## 接受的 trade-off

計數在災難情境下會 drift（transaction commit 半套用、手動改 DB 等）。v1 接受 drift 風險。一個用 cron 定期 reconcile 的 job 排在 v2——它會從 `PostLike` 與 `Comment` 重算 count 並覆蓋 cache 欄位。

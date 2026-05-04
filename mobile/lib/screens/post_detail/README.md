# post_detail/

單一貼文的詳細頁——主文 + 留言串 + Like。從 feed card 點進來。

## Screens

| 檔案 | 用途 |
|---|---|
| `post_detail_screen.dart` | 主文 + 留言列表 + Like 按鈕 + 留言輸入 |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/posts/:postId` | 取貼文（含 author、channel、likedByMe） |
| `GET` | `/api/posts/:postId/comments` | 留言列表 |
| `POST` | `/api/posts/:postId/like` | Like |
| `DELETE` | `/api/posts/:postId/like` | Unlike |
| `POST` | `/api/posts/:postId/comments` | 新增留言 |

對應 dart client：[`lib/api/posts_api.dart`](../../api/posts_api.dart)。

## 資料流

```
進入 post_detail
  → 同時 fetch post + comments
  → 顯示

User 按 Like：
  → 樂觀 +1 + likedByMe=true
  → POST /api/posts/:id/like
  → server 在 transaction 裡同時寫 PostLike + Post.likeCount++
    （ADR-0006 denormalised counts）
  → 失敗 rollback

User 留言：
  → POST /api/posts/:id/comments → 取回完整 comment（含 author）
  → append 到 _comments
  → server 同時 Post.commentCount++
  → 對方收到 FCM + in-app 通知（emitToUser + sendFCM）
```

## 已知陷阱

- **likeCount / commentCount 是 denormalised 欄位**（ADR-0006）：寫入時必須在同一個 prisma `$transaction` 裡更新，**不要**靠 SQL `COUNT(*)` aggregation——feed 是 hot read path。
- **留言觸發 Conversation Eligibility**（ADR-0003）：在這個 post 留言後，A↔post.author 之間就有 eligibility。用戶可能會困惑「為什麼留個言突然能 DM 了」——這是設計，不是 bug。
- **Like 樂觀更新失敗要 rollback**：`_toggleLike` 已實作，rollback 後要還原 `likedByMe` 跟 `likeCount` 兩個欄位，**不要漏一個**。

# companions/

「夥伴」每日推薦——bottom-nav 第二格。**「夥伴」只是 UI label**，後端永遠是單向 `UserFollow`（ADR-0002 + ADR-0010）。

## Screens

| 檔案 | 用途 |
|---|---|
| `companions_screen.dart` | 每日 10 個推薦使用者卡片，可一鍵 follow |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/companions/daily?limit=10` | 每日推薦清單（同 city + 共同看板的 user） |
| `POST` | `/api/users/:userId/follow` | follow（單向） |

對應 dart client：[`lib/api/companions_api.dart`](../../api/companions_api.dart)。

## 資料流

```
companions_screen build
  → ref.watch(dailyCompanionsProvider)
  → GET /api/companions/daily → 10 筆

User 按 follow：
  → companionsApi.follow(userId) → POST → 樂觀標 followedByMe=true
```

## 已知陷阱

- **不是 swipe / match**（ADR-0002）：這是純展示「今天的推薦」，**沒有**接受 / 拒絕的概念。產品上故意不做 match 機制。
- **「夥伴」永遠是單向 follow**：UI 講「夥伴」，但 schema 是 `UserFollow(followerId, followeeId)`。改名前讀 ADR-0002 + ADR-0010。
- **每日 limit 由 server 決定**：client 傳 `?limit=10` 是 hint，server 會自己排序與去重，不要假設順序穩定。

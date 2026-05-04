# feed/

兩個 tab 的貼文牆：「所有話題」（追蹤的看板）與「同城」（依 user.city 過濾）。Bottom-nav 第一格、app 的主入口。

## Screens

| 檔案 | 用途 |
|---|---|
| `feed_screen.dart` | 雙 tab masonry grid + 篩選 chip strip + 招牌看板 stamp |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/feed/following` | 「所有話題」tab——當前 user 追蹤的看板的最新貼文 |
| `GET` | `/api/feed/city` | 「同城」tab——同 `user.city` 的最新貼文 |

對應 dart client：[`lib/api/feed_api.dart`](../../api/feed_api.dart)（兩個 `FutureProvider`：`followingFeedProvider`、`cityFeedProvider`）。

## 資料流

```
feed_screen build
  → ref.watch(followingFeedProvider)  / ref.watch(cityFeedProvider)
  → _fetchFeed(path) → dio.get(...)
  → List<FeedPost>（freezed）→ 渲染 masonry grid

User 切 tab：
  → DefaultTabController index 切換，兩個 provider 各自 cache 結果
```

## 已知陷阱

- **`Image.network` 必須帶 `cacheWidth` / `cacheHeight`**——沒帶的話 feed 滾動會直接 ANR。CLAUDE.md「關鍵規則」第 3 條已定。實測值：`cacheWidth: 360` / `cacheHeight: 360` 配 picsum 360x360 圖片。
- **顏色一律從 token 取**：feed card 的色票全部從 [`lib/theme/zaina_theme.dart`](../../theme/zaina_theme.dart) 的 `ZainaPalette.*` 取。**禁止 eyeball hex**（CLAUDE.md「關鍵規則」第 3 條）。
- **多堆疊 stamp 規則**：`signboard_card.dart` 只在 CJK 短標題時用多 stamp（避免英文標題堆疊起來看不懂）。歷史教訓見 commit `ea396d7`。
- **Picsum 圖片只有 seed 用**：所有 feed 圖目前都是 `picsum.photos/seed/...`，因為 mobile 端**還沒實作圖片上傳 UI**（只有 API + DB 接好）。

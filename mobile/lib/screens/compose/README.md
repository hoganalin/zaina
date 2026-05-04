# compose/

發新貼文。從 feed 的 FAB（紅色筆 icon）進入。

## Screens

| 檔案 | 用途 |
|---|---|
| `compose_post_screen.dart` | 看板選擇 + 標題 + 內容 + 城市 / 國家 |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `POST` | `/api/posts` | 建立新貼文 |

Body：`{ channelId, title, body, city, country, imageUrl? }`。對應 dart client：[`lib/api/posts_api.dart`](../../api/posts_api.dart)。

## 資料流

```
compose_post_screen.initState
  → 預填 city / country = 當前 user.city / user.country

User 送出：
  → postsApi.create({ channelId, title, body, city, country })
  → 成功：context.pop() 回 feed（feed provider 不會自動重新拉，
    User 看新文章要切 tab 或下拉刷新）
  → 失敗：在頁面顯示錯誤
```

## 已知陷阱

- **圖片上傳 UI 還沒做**：API + DB 已支援 `imageUrl?`（[posts.ts:26](../../../../api/src/routes/posts.ts)、[seed.ts:163](../../../../api/prisma/seed.ts)），feed 上的圖目前都是 picsum seed 圖。要做圖片上傳的話需要：(1) `image_picker` plugin；(2) 新 API endpoint 上傳到 GCS post bucket；(3) 拿回 imageUrl 帶進 create body。
- **送出後 feed 不會自動刷新**：因為 `followingFeedProvider` / `cityFeedProvider` 沒 invalidate。如果要做「送出後立即看到自己的文章」，要在 `_submit` 成功時 `ref.invalidate(followingFeedProvider)`。
- **`channelId` 必填**：server 端 zod 會擋下沒選看板的 submit。`_canSubmit` 已強制這個 invariant，不要拿掉。

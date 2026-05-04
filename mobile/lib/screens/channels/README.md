# channels/

12 個看板總覽 + 追蹤 / 取消追蹤。Bottom-nav 沒有，從 feed 的話題開關進入（grid 右上角的方塊 icon）。

## Screens

| 檔案 | 用途 |
|---|---|
| `channels_screen.dart` | 看板列表（icon + 名稱 + 簡介），每筆有「追蹤 / 已追蹤」toggle |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/channels` | 取所有看板（含當前 user 的 `followedByMe` flag） |
| `POST` | `/api/channels/:channelId/follow` | 追蹤該看板 |
| `DELETE` | `/api/channels/:channelId/follow` | 取消追蹤 |

對應 dart client：[`lib/api/channels_api.dart`](../../api/channels_api.dart)。

## 資料流

```
channels_screen build
  → ref.watch(channelsProvider)  // 共用，onboarding 也用
  → 顯示 12 筆 + followedByMe flag

User 按追蹤：
  → channelsApi.follow(id) → POST → 樂觀更新 provider
  → 失敗 rollback + SnackBar
```

## 已知陷阱

- **看板是表，不是 enum**（ADR-0007）：新增看板要寫 prisma seed + migrate，**不要**在 dart enum 加。
- **`channelsProvider` 是共用的**：onboarding step 4「選喜歡的看板」也讀同一個 provider。改它的 cache 行為要兩邊都驗。

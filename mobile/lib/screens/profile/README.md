# profile/

公開 profile + 自家 profile 編輯。Bottom-nav 第五格「我」走 `_MyProfileTab` → `ProfileScreen(userId: 自己)`；點別人頭像走 `/profile/:id`。

## Screens

| 檔案 | 用途 |
|---|---|
| `profile_screen.dart` | 公開 profile（自己 / 別人共用同一個）：暱稱 / city / 興趣 / Verified Badge / 該 user 的貼文列表 / follow / block |
| `edit_profile_screen.dart` | 自家 profile 編輯（暱稱 / 性別 / city / country / 興趣） |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/users/:userId` | 公開 profile 欄位 + isFollowedByMe / isBlockedByMe |
| `GET` | `/api/users/:userId/posts` | 該 user 的貼文 |
| `PATCH` | `/api/me` | 編輯自家欄位（edit_profile_screen） |
| `POST` | `/api/users/:userId/follow` | follow |
| `DELETE` | `/api/users/:userId/follow` | unfollow |
| `POST` | `/api/users/:userId/block` | block |
| `DELETE` | `/api/users/:userId/block` | unblock |

對應 dart client：[`lib/api/users_api.dart`](../../api/users_api.dart)。

## 資料流

```
profile_screen build
  → fetch user + posts 並行
  → 顯示

「我」tab：
  → _MyProfileTab 從 authStateProvider 取自己的 id
  → 用同一個 ProfileScreen 渲染，server 端會根據 token 認出是同一人
    → 不顯示 follow / block 按鈕，改顯示「編輯 profile」

User 按 follow：
  → users_api.follow(userId) → POST
  → 樂觀標記 followedByMe=true
  → 失敗 rollback

User 編輯（edit_profile）：
  → PATCH /api/me → 取回新 SelfView
  → ref.read(authStateProvider.notifier).updateSelfView(new)
  → 所有 watch authStateProvider 的螢幕跟著更新
```

## 已知陷阱

- **「我」tab 要等 user.id**：`_MyProfileTab` 在 [router.dart:21](../../router.dart#L21)，未登入 / loading 時顯示 spinner 而不是空白頁。
- **block 是單向**：A block B 之後，B 的 feed 還是會看到 A 的 post（v1 簡化）。完整 block 行為見 ADR-0005「故意不做」段。
- **edit profile 完成要更新 authStateProvider**：用 `updateSelfView(view)` 把回傳的新 SelfView 寫回 state，**不要**只 setState 自己 screen 的局部變數——其他螢幕（feed / DM）會看到舊資料。
- **Verified Badge 是 cosmetic**：`isVerified` 不擋任何功能（ADR-0004）。改它的顯示邏輯前先讀 ADR。

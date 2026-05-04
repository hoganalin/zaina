# conversations/

DM 列表 + 單一對話視窗。**Conversation Eligibility** 由後端強制（ADR-0003）；前端只負責顯示。

## Screens

| 檔案 | 用途 |
|---|---|
| `conversations_screen.dart` | 對話列表，bottom-nav「訊息」分頁 |
| `chat_screen.dart` | 單一對話的訊息流 + composer |

## API endpoints

| Method | Path | 用途 |
|---|---|---|
| `GET` | `/api/conversations` | 取對話列表（含對方 user 概要 + 最後一則訊息） |
| `POST` | `/api/conversations` | 開新對話（若已存在會 idempotent 回現有 id） |
| `GET` | `/api/conversations/:id/messages` | 取單一對話的歷史訊息 |
| `POST` | `/api/conversations/:id/messages` | 送出新訊息（API 同時 emit `message:new` 給對方） |

對應 dart client：[`lib/api/conversations_api.dart`](../../api/conversations_api.dart)。

## Realtime

即時訊息走 [`lib/api/chat_socket.dart`](../../api/chat_socket.dart) 的單一 `ChatSocket`：

- `socket.events` — 訊息流（`IncomingMessage`），`chat_screen` 過濾自己這個 conversation 的事件
- `socket.status` — 連線狀態流（`ChatConnectionStatus`），UI 可以顯示「重新連線中…」
- `socket.connect()` — `chat_screen.initState` 呼叫；如已連線會 no-op
- `socket.disconnect()` — Provider dispose 時自動執行

斷線重連策略全部封裝在 `ChatSocket` 裡（CLAUDE.md RULE-02）：1s → 30s backoff、每次 reconnect 自動 refresh Firebase ID token、server 端自動 re-join `user:{id}` room。

## 資料流

```
chat_screen.initState
  → conversationsApi.fetchMessages(id)            ← REST 拉歷史
  → chatSocket.connect()                          ← WebSocket 接即時
  → chatSocket.events.listen(...)                 ← 收新訊息更新 state

User 送訊息：
  → conversationsApi.sendMessage(id, body)        ← REST POST
  → API 同步 broadcast `message:new` 給對方        ← server emitToUser
  → 對方的 chat_screen 透過 socket.events 收到
```

## 已知陷阱

- **去重**：自己送出的訊息會從 REST 回傳一次，再從 socket 回來一次（同 id）。`chat_screen` 用 `_messages.any((m) => m.id == evt.message.id)` 過濾。
- **DM Eligibility 會回 403**：A 想 DM B，但 A/B 之前沒在同一 Post 留言過，`POST /api/conversations` 會回 `403 conversation_not_eligible`。錯誤訊息要對使用者翻譯成「先到對方貼文留言才能私訊」。
- **Token 過期**：`chat_socket.dart` 已處理（每次 reconnect 拿新 token）。**不要**在這裡額外做 token 邏輯——CLAUDE.md RULE-02。

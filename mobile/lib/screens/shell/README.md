# shell/

5-tab bottom-nav 主框架。go_router 的 `StatefulShellRoute.indexedStack` 包住 5 個 branch：feed / companions / notifications / messages / me。每個 branch 有獨立的 navigation stack（換 tab 不會 reset 對方的 scroll / push state）。

## Screens

| 檔案 | 用途 |
|---|---|
| `shell_scaffold.dart` | `Scaffold` + `NavigationBar` + 第一格 tab 顯示 FAB（發文按鈕） |

## API endpoints

無——shell 只是 nav 容器，沒有自己的資料層。

## 資料流

```
go_router (router.dart)
  → StatefulShellRoute.indexedStack(
      branches: [feed, companions, notifications, messages, me])
  → ShellScaffold(navigationShell: ...)

User 按 NavigationBar destination：
  → navigationShell.goBranch(index, initialLocation: ...)
  → 切換 IndexedStack，保留每個 branch 的 stack

第一格（feed）顯示 FAB：
  → context.push('/compose')
  → compose 完成 pop 回 feed
```

## 已知陷阱

- **5 個 branch 都要在 router.dart 註冊**：少一個 branch，`navigationShell.goBranch(4)` 會 throw range error。新增 tab 一定同時改 router.dart 的 branches list 跟這裡的 destinations list。
- **`initialLocation: index == currentIndex` 是「再按一次回首頁」**：使用者在 feed 內 push 了 detail，再按 feed tab → 應該 pop 回 feed root。不要拿掉這個條件。
- **FAB 只在第一格顯示**：`navigationShell.currentIndex == 0` 才 render FAB。如果未來其他 tab 也要 FAB，**不要**在這裡硬塞 if-else，新增一個 per-tab FAB 機制。
- **`NavigationBar` label 字體大小是 17pt**：之前實測 13/15pt 在 6 字 label（"動態"+"夥伴"+"通知"+"訊息"+"我"）下太小。改字級前讀 commit `17252eb`。

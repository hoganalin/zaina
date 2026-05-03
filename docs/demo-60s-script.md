# 在哪 ZAINA — 60 秒 Demo 錄影腳本

> 用途：面試前在 Android emulator 錄製的 1 分鐘 demo 影片。每秒對應的動作清楚標出來，照表操課即可，不要即興。
>
> 錄之前先確認：後端 `:3000` 起來、emulator 內 app 已跳到登入畫面、用 seed 帳號（建議用 `npm run prisma:seed` 產出的 demo 帳號之一）登入完成、停在 **動態 Feed**。

## 錄影前置（不算進 60 秒）

1. emulator 側邊面板點「Camera」/「⋯」→ Record screen → 確認 mp4 輸出位置
2. 螢幕暗一下、確認手機系統時間整點對齊（或忽略）
3. **錄影起點：app 已停在動態 feed，feed 已 scroll 到最上方**

## 主腳本（60 秒）

| 時間 | 螢幕內容 | 操作 | 重點 |
|---|---|---|---|
| 0:00–0:03 | 動態 feed 最上方 | 停住，讓畫面定格一下 | 第一印象：磚紅 / 看板綠 / 紙黃配色，雙欄 masonry |
| 0:03–0:10 | Feed 緩慢往下滾 | 食指拖動，每秒 ~150px | 露出 6 種 signboard 模板：圖+多戳章、圖+貼紙、紅日光、黃看板紅邊、紙泡泡、綠面板 |
| 0:10–0:13 | Feed 滾到一張黃看板紅邊貼文 | 停住 | 「特別話題」貼紙特寫 |
| 0:13–0:15 | 點進該貼文 | 單擊 | 進入貼文詳情 |
| 0:15–0:20 | 貼文詳情 | 點 ❤️ → 數字 +1（denormalised count，ADR-0006） | likeCount 即時更新 |
| 0:20–0:25 | 仍在貼文詳情 | 點留言欄輸入「你好啊」→ 送出 → commentCount +1 | 同一個 transaction 跑完 |
| 0:25–0:27 | 返回鍵 | 點左上箭頭 | 回到 feed |
| 0:27–0:32 | 動態 AppBar | 點看板 icon | 進看板列表（Channels） |
| 0:32–0:36 | 看板列表 | 點 1 個未追蹤看板的「追蹤」 → 切換 | 看板切換 / Sprint 5 |
| 0:36–0:38 | 返回 feed | 左上箭頭 | feed 重新整理 |
| 0:38–0:40 | bottom nav 從 動態 切到 夥伴 | 點底部第 2 個 tab | 切到 Companion |
| 0:40–0:46 | 夥伴推薦卡 | 滑卡 1 次（讓畫面看到第二張）→ 在某張按「追蹤」 | unilateral follow，no swipe match（ADR-0002 / 0010）|
| 0:46–0:48 | bottom nav 切到 通知 | 點底部第 3 個 tab | 通知 tab（Sprint 9，ad-hoc derived）|
| 0:48–0:50 | 通知 tab 內容 | 不操作，停 | 露出 4 種來源（comment / DM / channel post / follow）|
| 0:50–0:52 | bottom nav 切到 訊息 | 點底部第 4 個 tab | DM 列表 |
| 0:52–0:55 | 訊息 tab | 不操作，停（或快點一個 conversation 進去再退）| 顯示 conversation eligibility 的訊息邀請 badge |
| 0:55–0:58 | bottom nav 切到 我 | 點底部第 5 個 tab | 個人頁 |
| 0:58–1:00 | 我 tab | 停在 profile 上方，露出 @username + ✓ 已認證 徽章 | 收尾畫面 |

## 拍攝注意

- **不要用真實 Google 帳號的個資**畫面入鏡。錄之前先把通知欄清乾淨、把 emulator 系統時間 / 電量都關小。
- **Feed scroll 不要太快**——如果一秒過 1.5 屏，6 種模板沒人看得到。寧可漏掉幾張。
- **不要 demo onboarding**。onboarding 4 步太花時間，跳掉。錄影起點就是已登入完成的 feed。
- **不要 demo verify / block / DM eligibility 失敗→補救**——這些 flow 需要 setup（兩個帳號互留言）才能真的演完，剪不進 60 秒。
- 如果某一段不順（例如點進貼文時轉圈圈太久），按 home 鍵中斷 → 重來，不要在影片裡留 loading。
- 推薦錄 2~3 take 取最順那次。

## 後製 / 上傳

YouTube 標題：

```
在哪 ZAINA — Flutter × Node.js 全端 Demo（60 秒）
```

YouTube 描述（含章節時間戳，YouTube 會自動轉成可點章節）：

```
旅居海外的台灣人 topic-first 社群 app，作品集示範。
Flutter + Riverpod / Hono + Prisma / Firebase Auth / Cloud Run + Neon Postgres / Socket.io DM。

00:00 動態 Feed（雙欄 6 模板）
00:13 點讚 + 留言（denormalised counts）
00:27 看板（Channel follow）
00:38 夥伴 推薦（unilateral follow，no swipe match）
00:46 通知 + 訊息
00:55 個人頁（已認證 badge）

GitHub: <repo url>
ADR + 設計文件: <repo>/docs/
```

設定：**Visibility = Unlisted**，**Made for Kids = No**。
縮圖（可選）：feed 主畫面截圖 + 大標 `60 秒` + 在哪 logo。

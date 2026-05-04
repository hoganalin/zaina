# v1 跟團隊 deck 部分對齊

團隊 deck（第33組 笑鼠班）定義了一套台味復古視覺與一份 information architecture（5-tab bottom nav、話題-centric 內容單元、夥伴每日推薦、招牌看板復古牌貼文卡、專屬話題對話起點、ISIC OCR 驗證、MBTI / 星座 / 抽菸 / 飲酒 / 睡眠 profile 欄位、Facebook + Google + Apple sign-in、未登入瀏覽），這些 v1 都**故意沒做**。ADR-0001 / 0002 / 0004 / 0005 / 0007 把這些 cut 寫成「8 Sprint 的 demonstrable 進度」勝過「半完成的功能型錄」的取捨。

Sprint 8 出貨後，我們重看 deck 並選擇**部分 re-align**：之前 cut 的決定**全部仍然有效**，但現在把視覺風格與最便宜的幾個缺項 port 過來，避免 demo 看起來像通用 Material 3 app。這是評估過的三個方案中的 **option B**（A = 只 re-skin；C = IA 整套打掉重練——會 invalidate Sprint 5-7）。

## 現在新增的部分

- **視覺層**——paper-textured cream 背景、石磚紅 / 郵筒綠 / 珍奶咖 配色、自製在哪 logo、珍奶杯印、招牌看板貼文卡、台味文案（「哩厚」、「歡迎光臨」）
- **5-tab bottom nav** 對齊 deck（動態 / 夥伴 / 通知 / 訊息 / 我）——看板管理從一個 tab 改成動態 AppBar 上的按鈕，因為 deck 的 home 頁也是把看板篩選 chip 放在話題上方而非獨立 tab
- **夥伴每日推薦**——同城 / 共同興趣的卡片。**不違反 ADR-0002** 因為沒有 swipe、沒有對稱 match：「追蹤」按鈕建立單向 UserFollow row、「略過」不持久化
- **通知 tab**——從既有表 ad-hoc 推導（我貼文上的留言、新 DM、追蹤的看板的新貼文）。沒新 schema
- **帳號名稱（`@username`）**——加 `User.username`（nullable、unique）。Profile 顯示。Onboarding 多一個可選步驟附 availability check。跟 ADR-0005 cut MBTI/星座/etc 的不同在於：username 是 **infrastructure**（URL 與 mention 的穩定識別碼），不是 profile 屬性

## 仍然 cut，理由不變

- **Swipe / match**——ADR-0002 stands。夥伴卡片是推薦，不是 Tinder。
- **MBTI / 星座 / 抽菸 / 飲酒 / 睡眠 / 生活作息 / 去過的國家**——ADR-0005。Deck mockup 有，但加 7 個 enum + 7 個 profile 螢幕對 portfolio 加分微乎其微。
- **專屬話題 + 招牌看板 / 圖片看板編輯器**——ADR-0005。招牌**視覺**以卡片風格落地進 feed，但 per-post 招牌編輯器不在 scope。
- **ISIC OCR + 裁切**——ADR-0004。驗證仍然模擬；上傳 UI 顯示 ISIC 卡 placeholder 對齊 deck。
- **Facebook 登入**——加按鈕容易，但實際流程要 Facebook Developer App + key-hash 註冊 + Firebase Console provider 設定，全是 user 端要做的。延後到 Sprint 9.x，等使用者拿到憑證再做。按鈕在新版登入頁以 placeholder 出現，按下顯示 snackbar 說明延後狀態。
- **未登入瀏覽**——deck 支援「未登入模式」瀏覽。不做：每個 read endpoint 自 Sprint 1 起就靠 `requireAuth`，要改會動 feed.ts / users.ts / channels.ts 全部。eager User row 建立（ADR-0008）讓「匿名瀏覽」成為一個我們不需要的另一條 IA 分支。

## Trade-off

只 re-skin 不重寫 IA 意味著 demo 看起來是團隊的產品，但 Sprint 5-7 的 endpoint / data model 仍維持（看板、denormalised counts、message_request 升級）。Reviewer 看到台灣品牌 + 合理 IA + 能跑的後端；讀 ADR 的人看到「保留什麼、cut 什麼、新加什麼」的清楚理由。

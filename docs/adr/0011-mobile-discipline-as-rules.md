# Mobile 出貨紀律編成 enforceable RULES

Mobile 端工作現在走 `CLAUDE.md` 「Mobile 工程紀律」段定義的 4 條 numbered rules，每條都有 repo 內具體 artifact 撐住。RULE-01 強制每個新登入 provider 走 4 步清單（Console → SDK → 後端 `POST /api/auth/session` → `api/test/auth.session.test.ts` 加一個 vitest case）。RULE-02 把斷線重連策略釘在單一檔案（`mobile/lib/api/chat_socket.dart`：backoff 1s→30s、每次 reconnect 自動 refresh Firebase token、server 端自動 re-join `user:{id}` room）。RULE-03 要求每個 screen 一份 `README.md`，固定 schema（用途 / API endpoints / 資料流 / 已知陷阱）；12 個 screen、12 份 README，同一次改動全部 land。RULE-04 禁止「測試之後再補」——`mobile/test/` 在這次同步開出 9 個 starter case 當地板，之後每個新 endpoint 或互動邏輯必須跟測試一起 PR。

替代方案是**先前的狀態**——`CLAUDE.md` 裡只有 aspirational prose（「Riverpod、freezed、dio 單例」）、沒 enforcement、沒 per-screen artifact。寫規矩是有成本的：setup 時間、12 份 README 隨 screen 演進的 maintenance overhead、過度僵化的風險。**不寫**的成本在 AI 加速開發下更大：未來每個 Claude session 都會重新賭一次 socket reconnect 策略、README 格式、測試覆蓋是否被 gate，codebase 會緩慢退化到「看起來沒事，到處在 drift」。Anchor constraint：這是 portfolio 專案，**出貨流程本身就是 artifact**。Implicit 紀律無法在面試中被指認；numbered rule + 具體檔案可以。

## 接受的 trade-off

12 份 README 會比它們描述的 screen 退化更快——這是預期的失敗模式。v1 接受 staleness，靠 RULE-03 schema 夠短（只有 4 個 section）讓 PR review 時 drift 容易被肉眼抓到。未來用 AI-driven audit job（用 screen 實際的 API client + provider list 去 lint 對應的 README）做自動偵測，這條留給 v2，不在本 ADR scope。

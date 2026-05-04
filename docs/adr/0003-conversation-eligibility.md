# Conversation Eligibility——DM 必須先有公開留言

User A 想 DM User B，必須符合三條件之一：A 在 B 的 Post 留過言；B 在 A 的 Post 留過言；A 與 B 都在同一篇 Post 留過言。檢查邏輯動態從 `Comment` 表算出——**沒有**獨立的 eligibility 表。eligibility 剛成立後的第一封 DM 進 B 的 **Message Request** 佇列，不直接進主收件夾。

這是 v1 的反垃圾機制，取代其他社交 app 的「match」門檻。它強制了產品的前提——**公開對話先於私訊**——同時又簡單到一句 SQL `EXISTS` 就能表達、可以搭既有的 `Comment` index 順帶完成。

## Trade-off

更嚴格的版本（mutual follow、follow-back）會造成冷啟死結。「都在同一篇 Post 留言」這條較鬆的分支讓兩個陌生人不必有任何貼文也能達到 DM，保留產品所仰賴的「透過對話互相發現」的路徑。

## v1 不做

- 檢舉（reporting）未實作。封鎖（block）是唯一安全控制——它單方面切斷 eligibility，並把被封鎖者的 Posts 從封鎖者的 Feed 隱藏。

## 決策來源 · 這份決定是怎麼做出來的

這份決定來自一次 Human × AI 的 iterative design 對話。分工如下：

| 來源 | 貢獻 |
|:---|:---|
| AI（Claude Opus 4.7） | 攤開 4 種反垃圾門檻方案（不設門檻 / mutual-follow / match-gate / public-comment-gate）並列出每一種的工程與產品意涵；指出 cold-start 死結風險、提出「都在同一篇 Post 留言」這條放寬條款 |
| Human · 決定 | 否決 mutual-follow（cold-start）與 match-gate（違反 ADR-0002 不做 swipe）；選 public-comment-gate——這是唯一跟產品「公開對話優先」DNA 一致的選項 |
| Human · 實作選擇 | 選 dynamic `EXISTS` query 而不是 denormalized 的 `ConversationEligibility` 表——順著既有的 `Comment` index、沒新狀態要維護（跟 ADR-0005 ship-then-refine 一致） |
| Human · 驗收 | 把 eligibility 三條路徑寫進 integration test，跑真 Neon DB |

AI 加速了選項生成與 trade-off 拉開的速度；架構決策——什麼出貨、什麼測試、什麼寫進產品守則——留在人這邊。
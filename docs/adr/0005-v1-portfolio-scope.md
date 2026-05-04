# v1 portfolio 範圍

V1 出 9 個功能性 feature——auth、onboarding、feed、channels、發文、留言 + Like、DM（Socket.io + Conversation Eligibility）、profile、block——加上模擬驗證（ADR-0004）與基本推播。明確排除：swipe / match、真審核、群組聊天、活動、二手物、MBTI / 星座 / 抽菸 / 飲酒 profile 欄位、hashtag、檢舉、soft delete、多語。

取捨由 portfolio 價值驅動——**8 Sprint 的 demonstrable 進度**勝過半成品功能型錄。Roadmap 項目（相機拍照、群組聊天、AI 配對、區域看板、節慶 sticker pack）寫在 README 的「Future」區，當作產品思考的明確訊號。

## Sprint 拆解

| Sprint | 範圍 |
|---|---|
| 0 | Repo init、skeleton、本機 hello-world |
| 1 | Google + Apple sign-in → Firebase verify → DB User row |
| 2 | Onboarding（暱稱 / 性別 / 城市 / 興趣 / 看板） |
| 3 | 唯讀 Feed + seed posts、2 個 tab |
| 4 | 發文 + 留言 + Like（denormalised counts，見 ADR-0006） |
| 5 | 看板 follow / unfollow、profile 頁面 |
| 6 | DM：Socket.io + Conversation Eligibility + Message Request |
| 7 | Verification UI + Block + 推播 |
| 8 | GCP 部署 + README polish + 截圖 + demo 錄影 |

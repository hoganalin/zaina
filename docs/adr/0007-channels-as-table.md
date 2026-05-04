# Channels 用 table，從檔案 seed

看板（v1 有 12 個:租屋 / 二手拍 / 票券 / 旅遊 / 旅伴 / 美食 / 亞洲 / 西班牙 / 歐洲 / 獨旅 / 升學 / 心情）存在獨立的 `Channel` 表，欄位有 `slug`、`name`、`icon`、`description`。初始看板資料從 Prisma seed 檔寫入，seed 檔本身 commit 進 git。

替代方案——Prisma `enum`——會把每次新增看板綁進 API 重新部署 + migration。把 Channels 放表裡讓未來新增（區域看板、合作看板）成本極低，允許每看板自己的屬性（icon、description），分析查詢也能很自然地 `GROUP BY channel`。

## 為什麼從檔案 seed

v1 的 canonical 看板 list 又小又有意義——應該被 version-controlled、被 review。從 `prisma/seed.ts` 的 TS 檔 seed 把 list 留在 git，同時把 Channel 當資料而非 schema 處理。

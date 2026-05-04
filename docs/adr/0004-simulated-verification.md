# v1 的身分驗證是模擬的

學生證上傳流程從前端到後端完整實作（Flutter UI → 圖片裁切 → GCS 上傳 → `Verification` 紀錄 → Verified Badge），但**審核 pipeline 是模擬的**：一個排程 job（或隱藏的 admin endpoint）在延遲後自動 approve 所有 pending verification。**沒有** OCR、**沒有**人工審核。

這個決定讓 v1 可以完整 demo 整個流程——圖片上傳、狀態流轉、徽章顯示——portfolio 用途，不需要建一個真審核後端（要 OCR、admin dashboard、人工 ops）。README 明確標示這是模擬版；正式生產環境會接 ISIC 驗證或人工審核。

## 此決定衍生的限制

- 上傳的證件圖進**私有 GCS bucket**。API 發短期 signed URL；圖**永遠**不會公開可讀。
- 「未驗證」使用者擁有完整功能。Verified Badge（✓ 已認證）在 v1 純粹 cosmetic——**不**擋發文、留言、DM。

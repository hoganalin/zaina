# 第一次 Firebase verify 就建 User row

`User` row 在第一次成功的 Firebase 登入（Google 或 Apple）當下寫入，欄位 `onboardingCompleted=false` + 預設暱稱（`firebaseUser.displayName ?? "新朋友"`）。`POST /api/auth/session` 是**唯一**會建 User 的地方；其他每個 route 上的 `requireAuth` middleware 只用 `firebaseUid` 查既有 User，**永不**建立新 row。Onboarding（Sprint 2）就地覆蓋暱稱 / 性別 / 城市 / 興趣。

替代方案——等 onboarding 完成才寫 row——可以得到「by construction 完整的」 `User`（沒有 placeholder 欄位），但代價是後端要追蹤第二種身分狀態（「Firebase token 驗過、DB 沒 row」）——要嘛靠 session table、要嘛把 user 屬性塞進 JWT。Eager create 讓後端保持 stateless，每個 authenticated request 都有單一 invariant：一個 Firebase identity ↔ 剛好一個 User row。

## 為什麼這份 ADR 要存在

未來看 DB 的人會看到 `nickname='新朋友'`（或 Firebase displayName 像 `Hogan Lin`）+ `onboardingCompleted=false` 的 User row。這些 row 是**故意**的、**必要**的——**不要**「修」掉它們：不要把 `nickname` 改成 nullable、不要刪 row、不要把 row 建立挪到後面。把 User 當作者 / 追蹤對象 / DM 對方時，要靠 `onboardingCompleted` 過濾，不是靠 row 本身存在與否。

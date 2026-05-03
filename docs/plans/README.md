# docs/plans/

開發中的功能計畫（user story → spec → tasks）。

## 命名

`YYYY-MM-DD-<feature-name>.md`

例：`2026-05-15-group-chat.md`、`2026-06-01-real-isic-verification.md`

## 結構

每份計畫至少：

```markdown
# <功能名稱>

## User Story
作為 <角色>，我希望 <能做的事>，這樣 <達成的目的>。

## Spec
- 對應 ADR：（若有，列檔名）
- 影響的領域語言：是否需更新 CONTEXT.md
- DB：新表 / 新欄位 / migration
- API：列出新增端點
- Realtime：socket emit 變動
- UI：影響的 screen / widget

## Tasks
- [ ] migration: ...
- [ ] API: ...
- [ ] mobile: ...
- [ ] tests: ...
- [ ] docs: 更新 FEATURES / ARCHITECTURE / CHANGELOG
```

## 完成後流程（DEVELOPMENT.md §11）

1. `git mv docs/plans/<file>.md docs/plans/archive/<file>.md`
2. 更新 `docs/FEATURES.md`（功能總覽 + 完整段落）
3. 更新 `docs/CHANGELOG.md`
4. 若有架構決策 → `docs/adr/NNNN-<title>.md`（編號 +1）
5. Commit：`feat: ship <feature> (plan: <date>-<name>)`

## 取消的計畫

頂部加 `> Status: ABANDONED YYYY-MM-DD — 原因：...`，git mv 到 `archive/`。保留歷史避免重新發明被否決的方案。

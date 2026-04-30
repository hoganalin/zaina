# Conversation Eligibility — DM gated by prior public comment

User A may DM User B only if at least one of: A commented on a Post by B; B commented on a Post by A; A and B both commented on the same Post. The check is computed dynamically from the `Comment` table — no eligibility table exists. The first DM under newly-formed eligibility lands in B's **Message Request** queue, not the main inbox.

This is the v1 anti-spam mechanism replacing the "match" gate that other social apps use. It enforces the product's premise that **public conversation precedes private chat**, while staying simple enough to express in one SQL `EXISTS` query and ride along with the existing `Comment` index.

## Trade-off

Strict variants (mutual follow, follow-back) cause cold-start deadlock. The looser "both commented on same Post" branch lets two strangers reach DM without either having posted, which preserves the discovery-through-conversation path the product depends on.

## Out of scope for v1

Reporting (檢舉) is not implemented. Block (封鎖) is the only safety control — it severs eligibility unilaterally and hides the blocked user's Posts from the blocker's Feed.

# Verification is simulated in v1

The student-ID upload flow is fully implemented end-to-end (Flutter UI → image crop → GCS upload → `Verification` record → Verified Badge), but the review pipeline is **simulated**: a scheduled job (or hidden admin endpoint) auto-approves pending verifications after a delay. No OCR, no human review.

This decision lets v1 showcase the full flow — image upload, status workflow, badge display — for portfolio purposes, without building a real review backend (which would require OCR, an admin dashboard, and human operations). The README explicitly notes the simulation; production would integrate ISIC verification or human review.

## Constraints from this decision

- Uploaded ID images go to a **private GCS bucket**. The API issues short-lived signed URLs; images are never publicly readable.
- "Unverified" users have full functionality. The Verified Badge (✓ 已認證) is cosmetic only in v1 — it does not gate posting, commenting, or DM.

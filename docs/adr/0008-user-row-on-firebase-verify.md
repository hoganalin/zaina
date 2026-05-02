# User row is created on first Firebase verify

A `User` row is written at the first verified Firebase sign-in (Google or Apple), with `onboardingCompleted=false` and a placeholder nickname (`firebaseUser.displayName ?? "新朋友"`). The dedicated `POST /api/auth/session` endpoint is the single place this happens; the `requireAuth` middleware on every other route only looks up an existing User by `firebaseUid` and never creates one. Onboarding (Sprint 2) overwrites nickname/gender/city/interests in place.

The alternative — wait until onboarding completes before persisting any row — would have given a "complete by construction" `User` (no placeholder fields), but at the cost of a second identity state ("verified Firebase token, no DB row") that the backend would have to track in a session table or by stuffing user attributes into a JWT. Eager creation keeps the backend stateless and gives every authenticated request a single invariant: one Firebase identity ↔ exactly one User row.

## Why this is documented

A future reader looking at the DB will see `User` rows with `nickname='新朋友'` (or a Firebase displayName like `Hogan Lin`) and `onboardingCompleted=false`. Those rows are intentional and required — do not "fix" them by making `nickname` nullable, deleting them, or moving row creation later. Reads that surface Users as authors / followed people / DM partners must respect `onboardingCompleted` instead.

# Atomic Notes — Testing, Security Audit & Performance Review

*Canonical testing document. This audit was performed by static inspection, grep-based security/privacy scanning, SQL/RLS review, and local structural checks. There is **no local Flutter SDK** in this environment, so `flutter analyze` / `flutter test` were **not** run locally — GitHub Actions is the authoritative compiler/test runner. Tests that require a device, a second device, or the live Supabase project are documented as **MANUAL** procedures, not claimed as executed.*

*Version under test: `1.14.0+5`. Date: 2026-08-23.*

## Summary

| Severity | Found | Fixed | Remaining |
|---|---:|---:|---:|
| Critical | 0 | 0 | 0 |
| High | 0 | 0 | 0 |
| Medium | 1 | 1 | 0 |
| Low | 2 | 0 | 2 (documented) |
| Informational | 4 | 0 | 4 (documented) |

**Overall:** the codebase is, for its stage, well designed on security and privacy. Balances and notifications are server-authoritative and RPC-gated, user isolation is enforced on multiple layers, there are no trackers/ads/analytics, secrets are absent from code, and Android permissions are minimal. One real correctness bug (energy charged for a sync that then failed to upload) was found and fixed. The remaining items are low-risk hardening/cleanup and pre-existing potential risks with existing backstops.

**Release decision: READY WITH KNOWN LOW-RISK ISSUES** — contingent on (a) CI green (analyze + test) on the next push, (b) migrations `006`→`009` applied to the Supabase project, and (c) the MANUAL device / multi-device flows in this doc executed once. Real-user email still needs a verified sending domain (spam until then). No blocker in the app code.

---

## Current architecture under test

- **Client:** Flutter, local-first. Hive for local notes. Singleton `ChangeNotifier` services: `NotesRepository` (notes + sync engine), `Vault` (E2E), `EnergyService` (energy/coins), `NotificationService` (feed), `SyncStatusHelper`, `NoteQuota`. Navigation via a static named-route table with a global `navigatorKey`. `SessionGuard` centralizes auth-state teardown.
- **Backend:** Supabase (Postgres + Auth + RLS + Realtime). Migrations `001`–`009`. Balances/notifications mutated only by `SECURITY DEFINER` RPCs; client writes to protected columns/tables are revoked or policy-denied.
- **Two repos:** public (`cred.dart` placeholders) and private build repo (real anon key). CI builds from private.

## Testing environment

- Static/local (executed here): file inspection, brace/paren balance checker, import/reference greps, secret scan, RLS/RPC review, dependency & permission inspection.
- Not available locally: `flutter analyze`, `flutter test`, device emulation, live DB. These run in **GitHub Actions** (`.github/workflows/build.yml`: `flutter analyze --no-fatal-infos --no-fatal-warnings` + `flutter test`) — authoritative.

---

## Baseline established

- Version `1.14.0+5`; 62 Dart files under `lib/`; migrations `001`–`009`; tests `vault_test.dart`, `widget_test.dart`, `energy_test.dart` (added by this audit).
- Dependencies: `supabase_flutter`, `hive_ce`(+flutter), `flutter_svg`, `google_nav_bar`, `flutter_staggered_grid_view`, `connectivity_plus`, `smooth_page_indicator`, `local_auth`, `cryptography`, `flutter_secure_storage`, `cupertino_icons`, `provider` (declared, unused). No analytics/ads/crash/telemetry packages.
- Android permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `USE_BIOMETRIC` only.
- Only network client is the Supabase SDK. No `http`/`dio`/custom `HttpClient`. No committed `.env`.

---

## Issues found & fixes applied

### M-1 (Medium, FIXED) — Energy charged for a sync that failed to upload
- **Area:** Atomic Energy / Sync. **Type:** correctness (prompt §11 "deduction occurring despite failed operation").
- **Root cause:** `syncNow` spent energy *before* `_push`, and a `_push`/`_pull` timeout or error returned without returning the charge. A network drop after the connectivity check cost the user energy (10 for instant; 5 for a charged standard sync) with nothing uploaded.
- **Fix:** added `energy_refund` RPC (migration `009`, capped, ledgered) and made `energy_spend_standard` return the amount actually charged (0 within the free hour, else 5). `syncNow` now records the exact amount charged and refunds it on `TimeoutException`/error. The zero-balance gate is preserved (charge still happens before push, so a broke wallet still can't sync). Files: `009_energy_refund.sql`, `energy_service.dart` (`spendStandard`→`int?`, new `refund`), `notes_repository.dart` (`syncNow`).
- **Retest:** MANUAL (T-SYNC-FAIL below) once CI builds; unit-covered indirectly by the energy client tests.

### L-1 (Low, documented) — Incremental pull cursor uses the client clock
- `_pull` uses `lastSyncedAt = DateTime.now()` (client) as the `updated_at >` cursor against server timestamps. A device clock running ahead of the server could skip remote rows updated in that window. **Backstop:** the realtime `.stream()` subscription delivers those rows anyway, so in practice updates still arrive. **Recommended hardening (not applied — needs multi-device testing):** advance the cursor from the max server `updated_at` seen in the pulled/merged rows rather than the client clock.

### L-2 (Low, documented) — `provider` is an unused dependency
- Declared in `pubspec.yaml` but never imported (app uses singletons + `setState`). Safe to remove to trim the dependency graph/attack surface. Left in place to avoid churn; remove when convenient.

### Informational
- **I-1:** `vault.dart` `debugPrint('Vault: unlock rejected, phrase did not verify')` logs a message only — **no** phrase/key is logged. Verified across the repo: no recovery phrase, key, password, token, or decrypted note content is ever logged.
- **I-2:** One `as` cast in `lib/` (`rows as List` in sync) — bounded, on a known Supabase response shape.
- **I-3:** The 5-coin welcome gift applies only to newly created wallet rows; existing test accounts must be seeded manually. By design.
- **I-4:** "Standard/hourly" sync is charged hourly *when a sync happens* (on save/reconnect/realtime), not by a true periodic background job. A real scheduled background sync is a future feature.

---

## Security audit (result: strong)

- **RLS / server authority (reviewed `003`,`006`,`007`,`008`,`009`):**
  - `atomicuser`: owner-scoped RLS; `note_limit`, `coins`, `energy`, `energy_cap`, `last_daily_grant_at`, `last_standard_sync_at` have client `insert`/`update` **revoked** → only `SECURITY DEFINER` RPCs (`energy_ensure/grant_daily/convert/spend/spend_standard/refund`) change them, all scoped to `auth.uid()`. A user **cannot** self-credit coins or energy, bypass the cap (`energy_convert` rejects overflow, never clips), or replay the daily grant (rolling 24h on `now()`).
  - `energy_ledger`: select-own only; **no** client write policy → history is append-only via RPCs. Cannot be forged.
  - `note`: owner-scoped RLS on all four verbs (migration `002`).
  - `notifications`: read-all authenticated, **no** write policy → announcements are service-role only. Normal users **cannot** create/modify global notifications. `user_notifications`: select-own only; read/dismiss go through `auth.uid()`-scoped RPCs → a user cannot forge another user's state.
- **Secrets:** repo-wide scan for `re_…`, `sk_live`, `whsec_`, `service_role`, and Supabase JWTs — **none in code**. Public `cred.dart` = placeholders; the real anon key exists only in the private build repo (publishable by design). Resend key + `service_role` live only in the Supabase dashboard. (Owner action: rotate the Resend and `service_role` keys, shared during setup.)
- **Auth:** OTP verification and password reset are server-generated codes verified via `verifyOTP`; logout routes through `SessionGuard` which resets the stack and tears down all per-user state; session expiry funnels to the same path. Rate limiting for OTP/email is a Supabase dashboard setting (owner-configured).

## Privacy & data-leak audit (result: strong)

- **No** analytics, telemetry, crash reporting, ad SDK, or third-party tracker packages. No `firebase`, `sentry`, `admob`, `mixpanel`, etc.
- **Only** network destination is the app's own Supabase backend (notes/auth/energy/notifications) + Supabase-SMTP→Resend for auth email. No other HTTP client exists in the code.
- E2E notes upload ciphertext only (`_seal` empties title/body/items into `payload`, sets `enc_v=1`); a locked device pulls `enc_v=0` rows only and never fetches ciphertext it can't read. No plaintext or key is logged.

## Encryption audit (result: sound, unchanged)

- AES-256-GCM + Argon2id (64MB/3/1), per-user salt = SHA-256(domain|uid), server stores only a verifier. Key cached in `flutter_secure_storage`, dropped from RAM on logout (`Vault.lockMemory`) and deleted on explicit logout (`clearLocal`), rebinds per account (`init`). No cryptographic change made (per the "don't casually change crypto" rule). Covered by `vault_test.dart` (17 tests, run in CI).

## User-isolation audit (result: strong)

- Hive notes box is owner-tagged (`__cache_owner__`); a different account's cache is cleared on load and on `start()`. In-memory notes cleared on logout (`clearMemory`). `Vault`, `EnergyService`, `NotificationService` all rebind per `uid` and are `clear()`-ed by `SessionGuard` on sign-out. `_mergeAll` drops results whose `forUid` no longer matches the current session (stale-fetch-after-logout guard). Manual test T-ISO-1 must confirm end-to-end.

## Performance notes

- Startup does not block on network: `Vault.init`, `NotesRepository.start`, `EnergyService.init`, `NotificationService.init` are `unawaited` after the session check; local notes load from Hive first. Sync is batched (one upsert for all dirty). No N+1 in the reviewed paths. Argon2id runs on the main isolate (~1s on unlock/setup) — known, documented earlier; off-isolate is a future optimization. No measurements were collected in this environment; none are invented here.

---

## Test matrix

Legend: **PASS(insp)** = verified by code/SQL inspection or local static check; **MANUAL** = requires device/multi-device/live-DB, documented for the owner to run; **FIXED** = bug fixed this pass, needs retest in CI/device.

| ID | Area | Type | Expected | Status |
|---|---|---|---|---|
| T-SEC-RLS | RLS / server authority | White/Security | Client cannot write balances/ledger/notifications; RPCs scoped to `auth.uid()` | PASS(insp) |
| T-SEC-SECRETS | Secrets | Security | No secrets in code/public repo | PASS(insp) |
| T-PRIV-NET | Privacy | Security | Only Supabase network dest; no trackers | PASS(insp) |
| T-ENC-BOUNDARY | Encryption | White | E2E uploads ciphertext only; locked device pulls `enc_v=0` | PASS(insp) |
| T-ISO-CACHE | User isolation | White | Owner-tag clears prior user's cache | PASS(insp) |
| T-ISO-1 | User isolation | Black | User A logout → User B login shows no A data | MANUAL |
| T-SYNC-RACE | Sync | White | Stale post-logout fetch dropped (`forUid` guard) | PASS(insp) |
| T-SYNC-FAIL | Energy/Sync | Black | Failed upload refunds the energy charged | FIXED → MANUAL retest |
| T-ENERGY-GATE | Energy | Black | Zero energy → no cloud upload; local save works | PASS(insp) + MANUAL |
| T-ENERGY-CAP | Energy | Black | Convert rejects cap overflow; no clip | PASS(insp) |
| T-ENERGY-GRANT | Energy | Black | +20 once per 24h server clock | PASS(insp) + MANUAL |
| T-COINS-CONV | Coins | Black | 1 coin → 40 energy; insufficient rejected | PASS(insp) + MANUAL |
| T-NOTIF-OWN | Notifications | Security | User cannot author global notifications; own state only | PASS(insp) |
| T-NOTIF-CTA | Notifications | Black | Empty/missing CTA not actionable | PASS(insp) via `energy_test`/model |
| T-AUTH-OTP | Auth | Black | Signup/reset OTP verify + new password | MANUAL (device) |
| T-OFFLINE | Offline | Black | Local create/edit works with no network | MANUAL (device) |
| T-CI | Build | Static | `flutter analyze` errors=0; `flutter test` green | RUN IN CI (pending push) |

---

## Automated tests

- `test/vault_test.dart` — 17 crypto/phrase tests (pre-existing).
- `test/widget_test.dart` — leaf widgets + Note model (pre-existing).
- `test/energy_test.dart` — **added this audit:** `EnergyBar.colorFor` thresholds (`<10`/`10–79`/`≥80`), `Wallet` parsing + `energyFraction` clamp + 120 cap default, `EnergyTxKind` mapping/labels, `AppNotification.fromMap` + `hasAction`/`isCritical` (malformed-CTA guard).
- These run in CI. They were **not** run locally (no SDK).

## Manual tests to run once (owner)

1. **T-ISO-1** user isolation: sign in A, create/sync notes, enable vault; logout; sign in B on same device → confirm zero A notes/energy/coins/notifications/vault state.
2. **T-SYNC-FAIL** refund: with sync ON and pending edits, trigger instant sync while forcing the upload to fail (airplane mode right after tap / kill network mid-upload) → energy is returned (a "Sync refund" ledger row appears; balance restored).
3. **T-ENERGY-GATE**: spend energy to 0, edit a note → note saves locally, does not appear in cloud; top up → next sync uploads it.
4. **T-AUTH-OTP**: signup + reset flows deliver a code and complete in-app.
5. **T-OFFLINE**: airplane mode → create/edit/delete notes and checklists work.

## Remaining risks / known limitations

- Incremental pull cursor clock-skew (L-1) — backstopped by realtime; harden later.
- `provider` unused dep (L-2).
- Argon2id on main isolate (~1s) — known.
- Real-user email needs a verified domain (spam until then).
- Coin **purchases** and the admin **Atomic-Controller** are not built yet (next phases).

## CI verification

Push the private repo; the Actions run must show `flutter analyze` with 0 errors and `flutter test` (vault + widget + energy) green. That run — not this document — is the proof of compilation and unit-test success.

## Migrations to apply (owner, in order)

`006_energy.sql` → `007_hourly_standard_sync.sql` → `008_notifications.sql` → `009_energy_refund.sql`, in the Supabase SQL editor. Each ends with a verification `select`.

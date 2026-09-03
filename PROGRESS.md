# Project Status

_Last updated: 2026-09-03 · Version 1.18.2 (build 6) · Status: reviving → open source soon_

A running snapshot of where **Atomic Notes** stands. For the full feature story
and the roadmap, see the [README](README.md). For exactly how data is handled,
see [TRANSPARENCY.md](TRANSPARENCY.md).

Atomic Notes was first built roughly three years ago, shelved when the tooling
wasn't ready, and is now revived: a new UI/UX system, a re-architected sync
engine, a full performance pass, and a security-and-privacy-first foundation.

---

## Shipped

* **Local-first storage.** Every note settles into on-device Hive storage the
  instant you stop typing. The local copy is the source of truth, so there is no
  "saving…" spinner and no way to lose work by closing the app or losing signal.
* **Fully usable offline.** Launch speed is identical online or off. Startup
  never blocks on the network, and a failed backend init shows a real error
  screen instead of hanging or vanishing.
* **Per-note realtime cloud sync (opt-in).** Sign in once and changes propagate
  per note across devices. One row per note, a server-authoritative
  `updated_at`, tombstones for deletes, and merge logic that never clobbers an
  unsynced local edit.
* **Notes and checklists, one object.** Same data model, same editor, same quota.
* **Pin, filter, and multi-select.** Pin to the top; filter by Newest, Oldest,
  To-dos, or Notes; enter selection mode to bulk-delete.
* **Note search.** Find notes by content from the notes screen.
* **Biometric app lock.** Optional fingerprint or face unlock (`local_auth`),
  layered on top of account sign-in and given priority at launch.
* **Server-enforced quota.** The 50-note free tier is a rule in Postgres, not
  just a hint in the UI.
* **Technical Editorial design system.** Bundled fonts and a disciplined
  ink / paper / signal palette, so the app renders deterministically with no
  network.
* **Onboarding once; session persists.** A brief one-time walkthrough, then a
  single sign-in that survives across launches.

## In active development

* **Client-side end-to-end encryption.** Encrypting note content on-device with
  a credential-derived key (AES-256-GCM) so the server only ever stores
  ciphertext. This is the top priority and the prerequisite for opening the full
  source. See the README's [Privacy &amp; Security](README.md#privacy--security)
  and [Encryption](README.md#encryption-in-active-development) sections.

## Planned

See the [Roadmap](README.md#roadmap): publish the full source, Amazon Appstore
listing and developer verification, the opt-in Atomic Coin funding concept,
alternative funding channels (Sponsors / Ko-fi / Open Collective), and
task / reminder notifications.

> Explicitly **not** planned: AI features and paid subscriptions. Both were
> evaluated and rejected for pushing the app toward the data-hungry model Atomic
> Notes exists to avoid.

---

## Get the app

* **Android:** prebuilt releases on the [Releases](../../releases) page.
* **iOS:** planned; an unsigned iOS build already compiles in CI.

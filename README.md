<div align="center">
  <img src="assets/readme/hero-banner.svg" alt="Atomic Notes — local-first notes app with cloud sync" width="100%" />

  [![Platform](https://img.shields.io/badge/platform-Android%20%C2%B7%20iOS-3A2FF0.svg)](#get-the-app)
  [![License: MIT](https://img.shields.io/badge/License-MIT%20(source%20coming%20soon)-3A2FF0.svg)](#license)

  Local-first notes. Optional cloud sync. No trackers, no analytics, no ad SDKs today.
</div>

## Contents
* [What this is](#what-this-is)
* [Features](#features)
* [Privacy & Security](#privacy--security)
* [Usability](#usability)
* [Design System](#design)
* [Get the App](#get-the-app)
* [Roadmap](#roadmap)
* [License](#license)
* [Author](#author)

---

## What this is
Atomic Notes is a note-taking app built on a simple premise: your notes should work with zero friction, whether you are online or offline, and you should never have to guess what happens to your data[cite: 1]. 

*   **Stack:** Built with a Flutter client and a Supabase backend (Postgres, Auth, Row-Level Security, and Realtime)[cite: 3].
*   **Storage:** Local-first architecture utilizing Hive CE (`hive_ce`) for on-device storage[cite: 3].
*   **The Promise:** There are no subscriptions, no AI integrations, no analytics SDKs, and no ad SDKs in the app today[cite: 1, 3]. 

*Note: The source code is currently not public. This is a deliberate, temporary choice while security-sensitive parts of the app are hardened[cite: 1, 3]. Publishing the source is planned; until then, this README is written to be exact about what is and isn't protected[cite: 1].*

---

## Features
*   **Notes and checklists, side by side:** Text notes and to-do checklists are first-class objects of the same type[cite: 1, 3]. Both count toward the same 50-note free limit and behave identically[cite: 1, 3].
*   **Instant local save:** Every note writes to on-device storage the moment you stop typing[cite: 1].
*   **Fully usable offline:** Local storage is the primary copy of your notes[cite: 1]. The app launches at the same speed whether you are online or offline, and launch never blocks on the network[cite: 1, 3].
*   **Optional cloud sync:** Sign in once and your notes sync to your other devices via Supabase[cite: 1, 3]. Sync operates on a per-note realtime basis rather than re-uploading an entire notebook blob[cite: 1, 3].
*   **Biometric app lock:** Fingerprint or face unlock (via `local_auth`) can gate the app, layered securely on top of your account sign-in[cite: 1, 3].
*   **Dedicated Stats Screen:** A plain-numbers "Database" screen displays your note count, sync status, and account info[cite: 1, 3].
*   **Strict free tier:** The 50-note limit is enforced server-side via Postgres, not just hidden client-side[cite: 1, 3].

---

## Privacy & Security
Precision matters more here than sounding impressive. Here is exactly where things stand today[cite: 1]:

**What is actually protected right now:**
*   Data in transit is protected by standard HTTPS[cite: 1, 3].
*   Data at rest in the cloud is scoped by Supabase Row-Level Security (RLS) access control, ensuring only your signed-in account can read or write your notes[cite: 1, 3].
*   The app collects zero telemetry. There are no crash-reporters, no third-party trackers, and no analytics[cite: 1, 3].

**What is NOT protected today (Stated Plainly):**
*   **Notes are NOT end-to-end encrypted**[cite: 1, 3]. Content is currently base64-encoded for storage[cite: 1, 3]. This is an important technical distinction: encoding is easily reversible by anyone with direct access to the data, whereas encryption is not[cite: 1, 3].
*   Local, on-device Hive storage is also unencrypted at rest today[cite: 1, 3]. 
*   *Closing this gap with genuine client-side encryption is the top roadmap priority, not a someday-maybe[cite: 1, 3].*

---

## Usability
*   **One sign-in, then it's yours:** An active session is currently required to bypass the splash screen, but it is a one-time step[cite: 1, 3]. Your session persists across launches[cite: 1, 3].
*   **A short walkthrough, once:** New users get a brief onboarding tutorial that disappears for good once completed[cite: 1, 3].
*   **Lock screen priority:** If biometric lock is enabled, it takes priority over everything else at launch so it cannot be accidentally bypassed[cite: 1].

---

## Design System
The UI follows a strict, disciplined system called **Technical Editorial**[cite: 1, 3]. It relies on condensed uppercase headings, hairline rules instead of shadows, and deliberate restraint on color[cite: 1, 3].

| Token | Hex | Role |
| :--- | :--- | :--- |
| **Ink** | `#15171B` | Typography, borders, inverted blocks[cite: 1, 3]. |
| **Paper** | `#F4F5F1` | The background canvas[cite: 1, 3]. |
| **Signal** | `#3A2FF0` | Sync, active states, focus—the only accent color[cite: 1, 3]. |

**Typography:** Bebas Neue for headings, Hanken Grotesk for body copy, and JetBrains Mono for metadata and status readouts[cite: 3].

---

## Get the App
*   **Android:** Prebuilt Android releases are currently distributed via the [GitHub Releases](../../releases) page[cite: 1, 3]. 
*   **Google Play:** There is no Google Play Store listing planned[cite: 1, 3]. 
*   **Future Distribution:** An Amazon Appstore listing is planned strictly to satisfy future AdMob eligibility requirements[cite: 1, 3]. F-Droid may be explored in the future as a separate ad-free build flavor[cite: 3].

---

## Roadmap
*Nothing below is finished. This section exists to outline the intended direction, not current behavior[cite: 1, 3].*

1.  **Client-Side Encryption:** Upgrading the current base64-encoding to genuine encryption so notes are unreadable to anyone but the account holder[cite: 1, 3].
2.  **Publish Source Code:** Opening the repository to public read access once security hardening is complete[cite: 1, 3].
3.  **The Atomic Coin System (CONCEPT — NOT LIVE):**
    <div align="center">
      <img src="assets/readme/atomic-coin-flow.svg" alt="Roadmap concept, not live: planned design for the Atomic Coin system" width="100%" />
    </div>
    Atomic Notes will stay free, but cloud infrastructure is not[cite: 1, 3]. Instead of subscriptions, an opt-in, gamified ad economy is planned[cite: 1, 3]:
    *   Watch 1 rewarded ad to earn 3 particles (1 electron + 1 proton + 1 neutron)[cite: 1, 3].
    *   3 particles automatically form 1 **Atom**[cite: 1, 3].
    *   Collect 3 Atoms to mint 1 **Atomic Coin**[cite: 1, 3].
    *   Spend 1 Atomic Coin to unlock 1 **instant/on-demand cloud sync**[cite: 1, 3].
    
    *Crucial Guarantee:* A free, periodic background sync will **always** remain free for everyone[cite: 1, 3]. Coins will only ever buy speed/convenience, never the basic guarantee that a note is saved and synced[cite: 1, 3].

*   **No AI features and no subscriptions are planned.**[cite: 1, 3].
*   **Task/reminder notifications** will be added once the core foundation is stable[cite: 1].

---

## License
MIT — See the [`LICENSE`](LICENSE) file[cite: 1, 3]. (Takes effect in practice once the source is published[cite: 1]).

## Author
Built by **Ashutosh Sharma** ([DevBehindYou](https://devbehindyou.vercel.app)) — web development, SEO, and applied AI[cite: 1, 3].
*   [Portfolio](https://devbehindyou.vercel.app)[cite: 1]
*   [GitHub](https://github.com/DevBehindYou)[cite: 1]
*   [Medium](https://medium.com/@devbehindyou)[cite: 1]
*   [X (Twitter)](https://x.com/devbehindyou)[cite: 1]
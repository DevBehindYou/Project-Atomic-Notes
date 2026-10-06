<div align="center">

<a href="https://github.com/DevBehindYou/Atomic-Notes-App-V0.2">
  <img src="https://raw.githubusercontent.com/DevBehindYou/Atomic-Notes-App-V0.2/main/Project-Images/README/hero.png" width="100%" alt="Atomic Notes, a local-first notes app for Android that syncs to your own Google Drive" />
</a>

<h1>Atomic Notes has moved</h1>

<p><b>Your Notes, Your Drive, Always Yours.</b></p>

<p>This repository was the first home of Atomic Notes. The app has been rebuilt from the ground up,<br />
and it now lives in two new places.</p>

<p>
  <a href="https://github.com/DevBehindYou/Atomic-Notes-App-V0.2"><b>App repository</b></a>
  &nbsp;·&nbsp;
  <a href="https://atomic-notes.devbehindyou.com"><b>Website</b></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/DevBehindYou/Atomic-Notes-App-V0.2/releases/latest"><b>Download the latest APK</b></a>
</p>

</div>

---

## Where to go now

| You want to | Go to |
| :--- | :--- |
| Download the app (Android 9 or newer) | [Latest release](https://github.com/DevBehindYou/Atomic-Notes-App-V0.2/releases/latest) |
| Read the app's code, docs, and changelog | [DevBehindYou/Atomic-Notes-App-V0.2](https://github.com/DevBehindYou/Atomic-Notes-App-V0.2) |
| See features, the FAQ, live updates, and the blog | [Atomic Notes website](https://atomic-notes.devbehindyou.com) |
| Check what the app collects and what it protects | [TRANSPARENCY.md](https://github.com/DevBehindYou/Atomic-Notes-App-V0.2/blob/main/TRANSPARENCY.md) |

## What is Atomic Notes?

**Atomic Notes is a free notes app for Android that keeps your notes on your phone first and syncs them to a private folder in your own Google Drive.** It has no AI features, no ads, and no analytics. An optional vault encrypts every note on the device with AES-256-GCM, so the sync server and Google only ever store ciphertext. Version 2.03.5 shipped on September 28, 2026.

## What changed since this repository

- **Your Drive, not ours.** Sync writes one file per note to a `My-Atomic-Notes` folder in your Google Drive. The server keeps only metadata, never your note text.
- **End-to-end vault, shipped.** Six words you write down become a key on your phone (Argon2id), and AES-256-GCM seals each note before it leaves the device.
- **Atomic Energy.** Writing notes is free. Cloud sync runs on energy that refills by 20 every 24 hours.
- **A new design and more locks.** A notification center, biometric lock, two-step verification, and blocked screenshots.

## Why the old code is gone

The code that lived here was the first version of Atomic Notes, built on an older backend that no longer runs. It was removed so that no one builds or installs an outdated, unsupported app by mistake.

The builds on this repository's Releases page (v1.12.1 and v1.18.2-DEMO) are no longer supported. Download the current version from the [new repository](https://github.com/DevBehindYou/Atomic-Notes-App-V0.2/releases/latest).

## Is Atomic Notes still open source?

No. Since September 28, 2026, Atomic Notes has been **source-available**. The code is public in the new repository so anyone can read it and check how the app treats their data, but it is proprietary. Copying, modifying, redistributing, or reusing it is not allowed. The terms are in the [Atomic Notes Source-Available License](https://github.com/DevBehindYou/Atomic-Notes-App-V0.2/blob/main/LICENSE).

## License

Everything in this repository is covered by the [Atomic Notes Source-Available License](LICENSE). All rights reserved. Versions of this repository published before September 28, 2026, were released under the MIT License, and copies taken from those versions keep that grant.

---

<div align="center">
  <sub>Built by <a href="https://github.com/DevBehindYou">DevBehindYou</a> (Ashutosh Sharma) · <b>Your Notes, Your Drive, Local First.</b></sub>
</div>

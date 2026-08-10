# Transparency

Atomic Notes exists because a data breach taught its developer a hard lesson: most apps will not tell you plainly what happens to your data. This page does. It describes, in plain language, how Atomic Notes handles your notes today, what is protected, what is not protected yet, and where the project is headed. If any of this ever stops being accurate, treat it as a bug and tell us.

## What we collect

Almost nothing. Atomic Notes ships no analytics, no crash reporters, no advertising SDKs, and no third-party trackers. It does not build a profile of you, and it does not measure how you use the app. The only data it handles is the data you create (your notes and checklists) and the minimum needed to run an account: an email address, and a display name if you choose to sign in for cloud sync.

## Where your notes live

Your notes live on your device first. Atomic Notes is local-first: every note is written to on-device storage the moment you stop typing, and the app opens and works whether or not you have a connection. Cloud sync is optional. When you turn it on, your notes are copied to your own private rows so they can reach your other devices. When you turn it off, your notes stay on the device only. You can see the split any time on the in-app Database screen, which shows how many notes are on the device versus in the cloud.

## What is protected today

* Traffic between the app and the backend uses HTTPS/TLS.
* Cloud data is scoped by row-level access control. Every rule ties a row to its owner, so your signed-in account is the only one that can read or write your notes.
* There is no telemetry, no ad SDK, and no AI feature, so your notes are never profiled, targeted, or used to train a model.
* You can turn on an optional biometric lock that gates the app on your device.

## What is not protected yet

We would rather be exact than impressive. Today your note contents are stored as ordinary text in your own database rows. They are protected by the transport encryption and access control above, and by the hosting platform's at-rest disk encryption, but they are not yet end-to-end encrypted. In principle, the service operator could read note contents.

Closing that gap is the project's top priority. Client-side end-to-end encryption, where your notes are sealed on your device with a key derived from your credentials so the server only ever stores unreadable ciphertext, is in active development and is planned for the next release. Until it ships, please do not store passwords or other high-risk secrets in any notes app, including this one.

## No AI, no ads, no data sale

Atomic Notes has no AI features. Your notes are never sent to a model and never used as training data. There are no ads in the app today. The planned way to cover cloud costs is an optional, rewarded-ad system a user can choose to use for faster sync. It only ever buys speed, never access to your notes, and a free background sync will always stay free. The project will never sell your data. That is not a promise about intentions. It is a consequence of building the app so that there is nothing to sell.

## Open source

The application source is private for now, held back until the security-sensitive parts are hardened, encryption first. The plan is to open it to public read access once that work is done, so anyone can verify these claims rather than take them on faith. This showcase repository, its README, and its website already describe the architecture and the exact security posture in the same honest terms as this page.

## How to hold us to this

Verify, do not trust. Once the source is public, you will be able to read exactly what the app does. In the meantime, the app makes no hidden network calls beyond its own backend, ships no third-party SDKs that phone home, and requests no permissions it does not use. If you find anything that contradicts this page, that is a defect we want to fix.

Questions or concerns: reach the developer through the links in the project [README](README.md).

---

*Last reviewed: 2026-08-10. This page tracks the app's real behavior, not its aspirations. The one forward-looking item, end-to-end encryption, is labeled as in development on purpose.*

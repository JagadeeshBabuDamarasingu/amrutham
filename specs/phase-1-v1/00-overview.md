# Phase 1 (v1) — Overview

## Scope

F1 (profiles/family history), F2 (medications/schedules/reminders — the core loop), F3 (dose journal), F4 tier 1 only (photo filing, no OCR yet), F5 (plain-files vault), F9 (bare encounter log).

This is the hard cut. Counted honestly, the full feature wishlist explored during planning was roughly six apps' worth of surface for one solo developer — encounter tracking, expense/insurance tracking, family analytics, a doctor access system, diet/weight/period tracking, a generalized notification system, a content/dashboard layer. Every feature above survived the question "does this change whether v1 ships at all?" Everything else didn't — see [out-of-scope.md](../out-of-scope.md).

## Goals

- Activation: a user schedules their first medication and captures their first document in one session, no manual required.
- The only retention metric that matters: the reminder loop is still alive at week 8 in real households (start with the founder's own family).
- Durability: the "abandonment test" (vault fully readable in a text editor with the app uninstalled) passes on every release, from day one.
- Zero infrastructure cost — no server exists to pay for.

## Personas (design against these, not abstractions)

- **Lakshmi** (primary user, the wedge) — 28–45, manages parents'/in-laws' medications and doctor visits alongside her own family. Phone-first, comfortable with WhatsApp/Drive, not technical beyond that. Success looks like: "Appa's meds fire on my phone and his. At the cardiologist I handed over one page instead of a plastic bag."
- **Amma** (secondary user, dependent profile) — 60+, takes 3–7 chronic medications, low digital literacy, needs large-text/elder-mode UI. Success looks like: "The reminder shows the strip photo. I tap once. Nobody nags me."
- **Ravi** (self-tracker) — 25–40, privacy-conscious, wants his records out of commercial clouds. Success looks like: "My vault is Markdown in my own synced folder. The app is just a nice editor over it."

## Build milestones — in order, each a mergeable, demoable slice

- **M0 — Scaffold.** *(Already done — `apps/mobile` is a fresh Flutter project.)* Next: pin dependency versions in `pubspec.yaml` per [02-architecture.md](02-architecture.md) §2 before adding any real code.
- **M1 — Profiles (F1).** `PersonProfile` + `FamilyHistoryEntry` + `AllergyRecord` domain/DB/vault-write round trip. UI: create a profile, add 3 family-history entries, in under 5 minutes. No reminders yet.
- **M2 — Medications & reminders (F2) — the core loop.** `MedicationCourse`/`SchedulePhase` CRUD, `flutter_local_notifications`-based reminder scheduling. This milestone is not done until it's been tested on a real device, across a taper, **and on at least one aggressive-battery-optimization OEM device** (Xiaomi/Oppo/Vivo are common in India and are documented to kill background work aggressively) — not just an emulator or a Pixel.
- **M3 — Dose journal (F3).** One-tap log from the reminder notification; append-only entries; a coverage-stat view with no judgment language ("30 of 31 days logged," never a score).
- **M4 — Document capture, tier 1 only (F4 partial).** Photo filing — `FiledDocument`, camera/gallery capture, attach to person + date + type. OCR (tier 2) is a phase 2 milestone, deliberately deferred — tier 1 alone is already independently valuable and "can't fail."
- **M5 — Plain-files vault (F5).** Retrofit M1–M4's database writes to also write through the vault engine; implement the rebuild-from-files procedure; ship the abandonment test green. This is why M1–M4 must go through the repository layer consistently rather than writing to the database directly from UI code.
- **M6 — Encounter log (F9).** `Visit`/`Hospitalization`/`TelehealthDetail`/`EpisodeOfCare`, reusing M4's document attachment model. Completes v1.
- **v1 complete** when the abandonment test is green and the release checklist (dependency deny-list review, no unnecessary network permissions, no analytics SDK) has been run.

See [01-features.md](01-features.md) for detailed feature specs and acceptance criteria, and [02-architecture.md](02-architecture.md) for the engineering design (domain model, database schema, the reminder engine, encryption, testing strategy).

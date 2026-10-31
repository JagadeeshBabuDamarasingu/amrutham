# Tasks

Engineering work on Amrutham. Things that need the owner's decision or action are in [TODO.md](TODO.md).
Design decisions and the review findings behind them are in [concepts_brief.md](concepts_brief.md).

Last updated overnight, 2026-11-01. The phone was disconnected, so **nothing below marked "not run on a phone" has been seen working on a device.**

## Built and tested (unit and widget tests; 218 pass)

- Edit and delete for profiles, medicines and schedule phases, readings, history, expenses (and receipt), records, allergies and family history.
- Public backup format with a semantic `schemaVersion`, one reader per major version, and a test that fails if the document's shape changes without a bump (`docs/backup-format.md`, `docs/backup-schema.json`).
- Home screen widgets: Emergency card (5x2), Dial (5x1), Blood group and allergies (2x2), with per-person settings, backup exclusion for the widget copy, and the four app-icon shortcuts.
- App lock using the phone's own lock (no PIN): locks at start and after 1/5/15 minutes or right away, emergency card open while locked, widgets and shortcuts lock-aware, Settings screen, one-time question after onboarding. **Not run on a phone.**
- Learn: Our healing heritage (hub and five guides, all Draft).
- Expenses: year view now has Export PDF as well as CSV (a real `.csv` file).
- Care team: doctor and hospital detail pages (call, message, directions, workplace link, visits and spending matched by name).
- Today greeting keeps "Good afternoon," on one line with the name below.
- A 130%-text sweep over 25 screens (found and fixed three overflows, including the lock screen).

## Not built yet

### Needs a decision before it can be built (see TODO.md)
- [ ] **Family devices: pair and sync** (Doop 3b, 3c). Large, and a security design.
- [ ] **Next-dose widget** (Doop 13b). Read-only is easy; Taken / Not taken from the widget needs a write path that has not been proven.
- [ ] **More languages** (Doop 9a-9m). Only English, Hindi and Telugu exist, and the Hindi and Telugu strings are unreviewed. The lock, widgets, shortcuts and new screens are English only.
- [ ] **Add-member wizard** (Doop 2a-2d): the design is three steps (basics, allergies and surgeries, medicines); the app has one screen and separate add screens.
- [ ] **Recovery-code changes** from the brief: manual backups reusing the stored key, a monthly "do you still have it?" card on Today, "where I kept it" choices, and a replace-the-code flow. Needs the three open decisions in TODO.md. Includes fixing the stale key after a restore.

### Small follow-ups
- [ ] Doctor page: clinic days and notes (needs a schema change, `schemaVersion` 1.1.0 and a Realm migration). "Linked to" picker so visits and spending match a saved doctor, not just by name.
- [ ] Update Doop 13b and 13e to say "Not taken", not "Skip", once the status wording is settled.
- [ ] Vault-ready screen (Doop 0e) and a progress screen while restoring (0g) were not checked against the app.
- [ ] "Right away" lock timeout will lock when you return from the camera or a file picker. Consider ignoring those.
- [ ] A "visit summary for a doctor" export from History (suggested in the audit, never designed).
- [ ] Opt-in measurement reminders (suggested in the audit, never designed).
- [ ] One back-button pattern across screens (audit).

## Needs checking on a real phone (morning checklist is in TODO.md)
- App lock (biometric prompt, Android 8 and below theme, hide-in-recents, relock timing, widget and shortcut taps while locked).
- Widgets and shortcuts after the latest changes, especially a freshly added card's default size.
- Release build signed with the upload key.
- Background and folder backups (from earlier work).

## Quality and housekeeping
- [ ] Check every dependency's licence is compatible with GPL-3.0.
- [ ] Review every Learn guide against its sources; all are Draft (the heritage ones especially).
- [ ] Add CI (`flutter analyze` and `flutter test`) on push.
- [ ] Untracked files to decide on: `.ignore`, `DESIGN.md` (empty), `README.md` (waits for images), `assets/`, `apps/mobile/android/build/` (should be git-ignored), the generated Linux, macOS and Windows plugin registrants.
- [ ] Play Store listing: privacy policy page, data-safety answers, screenshots, descriptions. The privacy page now mentions the widget copy; it should also mention the biometric prompt and `hide in recents`.
- [ ] Riverpod 3 upgrade is blocked by Realm; revisit later.

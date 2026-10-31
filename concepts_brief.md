# Less recovery-code typing, and a reminder to keep the code

* **Author:** Jagadeesh Babu Damarasingu
* **Date:** 2026-10-31

## Overview

Today the recovery code is typed for every manual backup, every restore, the "Check my code" row, and when automatic backups are turned on. It works like a password, but it is called a recovery code, and it was meant for recovery. The goal is to stop asking for it on routine backup actions, and to make sure people still know where their copy is on the day they need it.

The agreed hypothesis:

- The recovery code is used for recovery. A Signal-style reminder card on the Home screen asks people to re-enter it: daily for the first 7 days until entered correctly once, then at 1 week, 1 month, 6 months and yearly. It can be dismissed. A wrong entry says "incorrect". An optional note records where the copy is kept.
- Backup screens are a restricted area. Fingerprint is turned on at onboarding when the phone supports it, and is the default unlock. "Use recovery code instead" is always offered, and an unlock lasts about five minutes across backup screens.
- Manual backups use the stored key that automatic backups already keep, so they stop asking for the code.
- Restore and showing or replacing the code always need the code. Fingerprint never replaces the code for these.
- The fingerprint only opens a screen. The backup key never depends on it, so changing fingerprints cannot lock anyone out.
- One person is assumed to own the phone. Shared-phone use was not discussed.

## Analysis

Six reviewers read the code. They did not run anything. The main finding: **one change removes the friction, and most of the rest adds cost without a matching benefit.**

**What the review says to keep**

- Let manual backups reuse the stored key. This is about ten lines in `backup_flow.dart`. It needs no change to the backup file, so `schemaVersion` stays 1.0.0 and the shape test passes unchanged.
- A reminder to keep the code is worthwhile, in a simpler form than the five-step schedule.

**What does not match the code**

1. **"Show the code" cannot be built.** The phone stores only a salt and a check value, never the code. Showing it would mean storing it, which breaks the privacy promise and the app's own "we can't show it again" notice. "Replace the code" has no flow today and is costly: a new check value, a new key, and an immediate re-backup, because Drive and folder files would stay locked to the old code until overwritten.
2. **The stored key is tied to the automatic-backup switch.** Turning automatic backups off deletes the key, so manual backups would start asking for the code again. The key needs to be its own item, independent of those switches. The stored name `auto_secret` should stay so existing installs keep working.
3. **The stored key goes stale after a restore, and this bug exists today.** Restore replaces the check value but not the stored key, so later scheduled backups use the old key and the new code cannot open them. Reusing the key for manual backups would spread this to every backup.

**What the review challenges**

- **The fingerprint gate guards little.** The app has no app lock, so anyone holding the unlocked phone can already read every record. Gating the backup screens only protects one extra action: sending an encrypted file somewhere, which is useless without the code. The real exposure is someone pointing automatic backups at their own destination. Requiring the code to connect a new destination covers that. The gate also costs real work: a new dependency, a change to the main Android activity that has to be checked against the existing background-backup and folder plugins, fallback screens, and a test seam. The likely threat in practice is a family member who knows the screen lock, and the gate does nothing against that. The reviewers' recommendation is to defer it, and to build an app-wide lock as a separate feature if one is wanted.
- **Daily reminders for 7 days mostly annoy.** The person has just written the code down and passed the setup check. Each check also runs a slow key derivation for several seconds. A dismissible card trains dismissal. A smaller schedule works better: a first card at about 7 days, then every 6 months.
- **The "where I kept it" note is a small leak.** Anyone with the unlocked phone can read "Gmail draft" or "locker, bank X". It is lost with the phone, which is when it would help. Users may also type the code itself into it. A static line on the card works almost as well.
- **More phones will hold a long-lived key.** Today only automatic-backup users do. The reviewers found no Android Auto Backup settings in the manifest, so this needs checking before a second long-lived key goes into secure storage.

**Smallest alternatives**

| Option | Removes the friction | Cost |
| --- | --- | --- |
| A. Manual backup reuses the stored key; no fingerprint | Yes | About 10 lines plus text, after the key is decoupled |
| B. A plus a one-interval reminder card | Yes, and adds the "where is your code" nudge | A plus about 40 lines |
| C. Fingerprint only | No, the code is still needed | New dependency |
| D. Automatic backups on by default | Mostly | Large, and it fights "no account" |
| E. The full plan above | Yes | Largest |

**Things that must be fixed whichever option is chosen**

- First keyless manual backup: three groups have no stored key (installs that never used automatic backups, installs that turned it off, and every phone after a restore). They type the code once, and the key is derived and stored.
- "Entered correctly" must be one definition. Setup checks only 2 of 6 groups; Settings requires all 24 characters. Any full correct entry anywhere should count, stamped in one place.
- Existing installs have no creation date for the code. Use the first launch after the update.
- Several in-app texts become false, including "Backing up by hand always asks for your recovery code". Docs and the privacy page also say the code is never stored and need re-reading.
- Wording is muddled: the same thing is called "recovery code", "key" and "vault". Use "recovery code" and "your records". Avoid "password" and "PIN" loanwords in Hindi and Telugu, because they suggest a reset exists.
- The backup, restore and recovery screens are hard-coded English today. New text is English only unless translated, and health text must not be machine-translated.

## Goals vs. Non-Goals

* **In-Scope Goals:**
  - A whole-app lock using the phone's own screen lock, and a replace-the-code flow, staged after the key fixes.
  - Manual backups stop asking for the recovery code.
  - A Home-screen reminder to confirm the code, with a defined schedule and a defined meaning for "entered correctly" and "dismiss".
  - The stored key is independent of the automatic-backup switches, and is refreshed on restore.
  - Fix the stale-key-after-restore bug, with a test.
  - Update the text, docs and privacy wording that this makes false.
* **Out-of-Scope Non-Goals (proposed by the review, awaiting the user's decision):**
  - Showing the recovery code in the app (cannot be built without storing it).
  - A free-text "where I kept it" note (replaced by a fixed list).
  - Translating the new text into Hindi and Telugu in this change (done before the first release instead).

## Key Decisions & Staging for Next Steps

**Decisions already made by the user**

- The code is used for recovery, plus a Signal-style reminder card on Home.
- Restore and showing or replacing the code always need the code.
- A wrong entry says "incorrect".
- Fingerprint, if built, is a gate only and is the default with the code as fallback.

- Connecting or changing a Drive account or folder requires the recovery code (confirmed 2026-10-31). Disconnecting or turning a destination off does not (assistant's call, since removing one sends no data anywhere).
- The reminder repeats at least monthly (confirmed 2026-10-31). Working definition, not yet confirmed: first card at about day 7; after that it appears 30 days after the last full correct entry made anywhere (card, Settings, backup, restore); dismiss means "ask again in 7 days"; no fixed end.

- A whole-app lock replaces the backup-only fingerprint gate (confirmed 2026-10-31). Working rules, not yet confirmed: it uses the phone's own fingerprint or screen lock and no separate app PIN; it is a screen gate only and never protects the key; the emergency card is reachable while locked; reminders keep firing; the re-lock timeout is a setting; recent-apps screenshots are hidden.
- "Show the code" is dropped. "Replace the code" is in scope, built after the key fixes (confirmed 2026-10-31).
- The "where I kept it" note is a fixed list with no typing (confirmed 2026-10-31); the exact options are still open.
- New text is English only now. Hindi and Telugu are added, with native-speaker review, before the first release (confirmed 2026-10-31).

- The "where I kept it" list is multiple choice, and the app recommends choosing more than one place for safety (confirmed 2026-10-31). Options: paper at home, locker, password manager, with a family member, on this phone only (with a warning), I haven't saved it yet, other.
- While the app is locked, only the emergency card is open, plus an unlock screen that explains itself. Default re-lock timeout is 1 minute away from the app, with 5 minutes, 15 minutes and "only when the phone locks" as choices (confirmed 2026-10-31).
- At the end of onboarding the app asks "Protect Amrutham with your phone's lock?", defaulting to on. If the phone has no screen lock set, the question is skipped and Settings explains it (confirmed 2026-10-31).

- A quick-access bubble on the Android home screen is wanted, modelled on the Hermes Companion frames 05-07 (https://doop.design/c/Tw-3559pWr): a floating bubble with a count badge, a peek card, and a tap-to-open quick panel with a drag-to-dismiss target (confirmed 2026-10-31 as a wish; scope not decided). Reviewers have not seen it yet. Assistant's objections, from memory and not verified against current Android rules: it needs the "Display over other apps" permission, a foreground service with a permanent notification, and survives badly on phone makers that kill background services; health information floating over other apps is a privacy risk, so the bubble should show a count only and the panel must sit behind the app lock with only the emergency card open. Cheaper alternatives that give most of the value: a home-screen widget (next dose and a Taken button), long-press app shortcuts (emergency card, log a reading) and a Quick Settings tile. Recommendation: widget and shortcuts first, overlay bubble later as an opt-in.

- Widgets and shortcuts come first; the overlay bubble stays a later opt-in (confirmed 2026-10-31). Designed in Doop canvas 6jousPASWH, page "12 · Quick access: widgets & shortcuts", frames 13a to 13e: home screen with both widgets, next-dose widget sizes and states, an emergency-card widget for a senior's phone (large type, 72 px Call button, a separate Call-only widget), the Settings screen for what widgets show, and the touch-and-hold shortcut menu. An emergency-card widget so the app suits seniors' phones was requested by the user.
- Design rules I applied (assistant's choices, not yet confirmed): medicine names on the next-dose widget are off by default, and Taken and Skip appear only when names are shown; Taken has a 5-minute undo; the emergency widget shows only what the person turns on (blood group and allergies on, medicines off by default); Call opens the dialer with the number filled in rather than placing the call, to avoid the call-phone permission; the emergency card shortcut opens while the app is locked and the others need the phone's lock.

**Open decisions for the user**

1. Are the privacy defaults right: names off, emergency widget showing blood group and allergies?
2. Should the senior widget call directly (needs the call-phone permission) or open the dialer (one more tap)?

**Recommended order**

1. Fix the stale key on restore, with a test.
2. Make the stored key its own item, independent of the automatic-backup switches, keeping `auto_secret`. No visible change.
3. Manual backup uses the key, deriving it once on first use. Fix the false text. Optionally offer "Turn on automatic backups?" after that first backup.
4. Reminder logic as a pure function of now, creation date, last verified date and dismissed date. No UI yet.
5. Home card with dismiss and "Check my code".
6. Docs and privacy wording, in the same commits as the behaviour they describe.
7. Whole-app lock (replaces the backup-only fingerprint gate), then the replace-code flow.
8. Quick access: widget and shortcuts, then the optional overlay bubble (separate feature; must respect the app lock).

## Widgets and shortcuts: six-lens review (2026-10-31)

The reviewers read the code but ran nothing; Android behaviour marked "unverified" comes from memory. They could not see the Doop frames, so visual polish was not reviewed.

**Verdict.** The idea is right, but the design is not buildable as drawn. It bundles five features, and its lock rules depend on an app lock that does not exist yet. Three reviewers independently recommend the same first slice: the Emergency card shortcut plus a static emergency widget with no dose-writing. The next-dose widget comes second; Taken, Skip and Undo come last.

**Blockers**

1. **A widget needs a second, unencrypted copy of health data.** Realm is encrypted and its key sits in secure storage, and native widget code cannot open it. The widget must read a plain file or preferences, which contradicts the privacy page's encryption claim. Write only the fields the person turned on, redact in Dart, delete the data on toggle-off, widget removal, deletion or death, and update the privacy page in the same change. An encrypted snapshot (recommended by one reviewer for the emergency widget) needs native crypto.
2. **Android Auto Backup is unrestricted.** Confirmed: the manifest has no `allowBackup`, `dataExtractionRules` or `fullBackupContent`. A plain widget file could be copied to the user's Google account. Keep it in `noBackupFilesDir` and add exclusion rules before any widget ships.
3. **Taken, Skip and Undo have no safe write path.** Native code cannot write to Realm, and the only precedent is the WorkManager isolate (whether a widget tap can start a Dart task is unverified, as is running two isolates on one encrypted Realm). `DoseStatus` is only `{taken, missed}` (confirmed), so "Skip" has no state: mapping it to `missed` is cheap, a new status needs a `schemaVersion` bump and would crash old builds on `byName` (confirmed at `dose_log_repository.dart:50`). There is no delete or undo method, and the dose key includes the scheduled millisecond, so the widget must carry the exact value and never recompute it across a time-zone change. A tap must re-check that the dose is still pending, and the 5-minute undo must survive process death.
4. **The app lock does not exist.** There is no `local_auth`, no lock flag and no lock screen. "Emergency card opens when locked" cannot be enforced yet. Widget Taken and Skip would change records without any unlock, so they must be declared exempt by design or routed through unlock.
5. **There is no launch routing.** `main.dart` has no named routes or intent handling, and the manifest uses `singleTop`, so a shortcut arrives as a cold start or a new intent. It needs an initial-action call plus a stream, cleared after use, and must handle the three gate states (welcome unseen, no recovery code, no profiles).
6. **"Call" wording is unsafe for seniors.** The button opens a dialer and needs a second tap, so a panicking person may think the call is under way. Either label it honestly ("Dial Anita" with a note to press the call button) or place the call directly. Dialer-only remains the right permission choice and matches the privacy page.

**Major issues**

- **Identity and empty states are safety issues.** Always show the person's name on the widget. Empty allergies must read "none added to Amrutham", not blank or "none", and the same for blood group. A missing phone number disables the button and says so; the number is free text and must be sanitised before building a `tel:` link. "All set" is ambiguous for someone with no medicines, so use "All 4 taken today", "No doses left today" and "No medicines added yet".
- **Staleness is a safety problem.** Update floors (about 30 minutes for widgets, 15 for WorkManager; unverified) cannot roll the widget at each dose time. Push a 7-day list of dose instants and use alarms at dose boundaries, midnight and undo expiry; re-render on boot, time-zone and clock changes; show an "updated" stamp and "Open Amrutham to refresh" after about 36 hours. Use one listener on Realm changes instead of editing seven call sites, and refresh after a restore. Xiaomi, Oppo, Vivo and Realme may block alarms (unverified); only a device matrix tests this.
- **"Next dose" logic lives only inside a Riverpod provider** (today-only, with the pending filter duplicated and a third copy in the reminder code). Extract one pure function and use it from the screen, the widget and later the reminders. PRN never counts toward "2 of 4".
- **Deceased people are an existing bug the widget would expose.** Confirmed: the reminder code has no deceased check, so reminders for a deceased person may still fire (the Today screen already skips them). Share one "is this person live" rule between reminders and the widget; a deleted or deceased person's widget says "no longer tracked".
- **Widget-to-person mapping is unspecified.** The in-app selection is an in-memory provider. A widget needs its own saved person; for a first version make the person one global Settings choice and skip a config activity.
- **Plugin boundary.** A channel in `MainActivity` does not exist in the WorkManager background engine, so put it in a registered plugin like `plugins/amrutham_folder` (a new `plugins/amrutham_widgets`; that plugin is Java, so add Kotlin or write the widget in Java). Three reviewers recommend against the `home_widget` package (unverified): it adds a dependency, still writes plain preferences, and the widget code is a few hundred lines.
- **Widget settings** go in the local settings store as one JSON value, not in Realm, which would force a `schemaVersion` 9, a backup-format bump and a failing shape test. Not backing it up is a benefit: a restore resets to the private defaults.
- **Language.** Widgets follow the system locale, not the in-app language, so a Hindi in-app user could get an English emergency widget. Options: Dart pushes labels, Android resources, or English only first. Health wording must not be machine-translated.
- **Wording.** Use the app's own "Missed" (or "Not taken"), not "Skip"; explain greyed switches ("Buttons to mark a dose are off. Turn on medicine names to mark doses from the home screen."); avoid "Private" because the privacy page uses it for something else (say "Hide medicine names"); a bare "Undo" can read as "cancel" in Hindi and Telugu; call "Add to home screen" "How to add a widget" if it only shows steps.
- **Lock-screen and card-toggle conflict.** Frame 2i's "show on lock screen" is off by default; a home-screen widget is a separate surface that ignores it. Gate the widget on the same setting, or say on both toggles that they differ. Also, reminder titles already contain the medicine name, so "names off" on the widget is stricter than the existing notifications; align them or the privacy story contradicts itself.
- **Crash path.** Crash capture is installed only in `main()`, so widget failures are invisible and missing from "Send a problem report". Install capture in the widget entry point, keep stack-only recording, and show "couldn't save, open the app" on the widget.

**Minor issues:** the `.debug` application id breaks static shortcut targets (use a per-build id); PendingIntent flags and non-exported receivers; widget provider XML sizing and preview images; no bundled fonts in widgets; TalkBack descriptions and 48 dp targets; three card variants that do not share state (consider one resizable widget); say which emergency contact is called; notification action buttons are a cheaper way to answer a dose than widget buttons and could come first; `DESIGN.md` is empty, so either fill it or delete it.

**Recommended build order**

1. **Slice 1 (no writes, no lock dependency):** backup exclusions and a `noBackupFilesDir` file; `plugins/amrutham_widgets` with `setSnapshot` and an initial-action stream; a pure snapshot builder with all redaction in one place; one 2x2 emergency widget with name, blood group, allergy line and an honest Dial button and the empty states above; the Emergency card shortcut; a minimal Settings section; privacy page and `docs/backup-format.md` updated in the same commit; a device test on Android 12+ and one Xiaomi or Oppo phone.
2. **Slice 2:** a read-only next-dose widget (count and "Open Amrutham", with the person's name), using the extracted pure function, alarm-driven rollover and a stale stamp.
3. **Slice 3, after the app lock:** spike the Dart write from a widget tap; add `deleteDose` and a `loggedAt` parameter; names-on with Taken, Not taken and Undo; the other three shortcuts behind the lock; the senior 4x3 card only if a senior tester asks.
4. **Defer:** the overlay bubble, a separate Call-only widget, per-widget configuration, `CALL_PHONE`, and `home_widget`.

**Open decisions for the user (from this review)**

1. Where widget data lives: a plain file excluded from backup, or a Keystore-encrypted snapshot.
2. Does "Skip" mean the existing `missed` ("Not taken"), or a new status needing a schema bump?
3. Are widget Taken and Not-taken exempt from the app lock, or must they unlock?
4. Do home-screen widgets honour frame 2i's "show on lock screen" toggle, or are they a separate surface?
5. Call: dialer-only with honest wording, or a senior-only direct-call option?
6. Person: one global setting or per widget? Which emergency contact does the widget call?
7. Do shortcuts ship before the app lock with a stub, or wait for it?
8. Is an English-only widget acceptable for the first release?
9. Should Taken dismiss the reminder notification already shown?
10. Is the "deceased person still gets reminders" bug in scope? It should be fixed before any widget relies on the same rule.

**Decision after the review (2026-10-31): as many emergency cards as the user wants.**
- The user can place any number of emergency cards on the home screen, for different people or the same person more than once. This replaces the single global "person" setting the reviewers suggested for a first version.
- Each card belongs to one person, chosen when it is added (Android's own widget-configuration screen), and each card has its own saved details, removed when the card is removed. The Settings screen lists one row per person with that person's card settings behind it. The app may offer an "Add" button that asks the launcher to place a card (unverified, launcher-dependent); removing a card stays a touch-and-hold action on the home screen.
- Designed in Doop: 13d (card list) and the new 13f (who is it for, what it shows). The call button is now labelled "Dial", as the review advised, in 13a, 13c and 13f.
- New risks: every card is another copy of someone's health details on the home screen, so each card is opt-in and shows only what the person switched on; the name stays large on every card because of the wrong-person risk on a shared phone; per-card data needs its own purge when a card is removed.
- Still open from the review: where widget data lives (plain file excluded from backup, or encrypted), whether "Skip" is the existing "missed" ("Not taken"), the lock-screen question, and the others listed above. The frames 13a, 13b and 13e still say "Skip" and need the final wording once that is decided.

**Built and checked on the phone (2026-11-01).** Three separate home screen widgets share one person's data: the emergency card at 5×2 (details left; blood group tile and Dial button stacked right), a Dial widget at 5×1 (phone icon, "Dial Anita", "for Appa"), and a blood group and allergies widget at 2×2. Widgets use the system font. The card's layout is chosen by its width, not its height, because the test phone's launcher has tall rows (about 120 dp) and rounds a declared 110 dp minimum height up to three rows; a 70 dp minimum is declared so a newly added card should default to two rows (not yet confirmed on a freshly added card). A placed widget keeps its size, so an existing card must be resized by hand or re-added. Doop frames 13a, 13c and 13f now show these sizes; 13b and 13e are unchanged, and the next-dose widget they show is not built yet.

**App lock: designed in Doop (2026-11-01), page "13 · App lock", frames 14a-14f. Not built.**
- 14a Locked: "Amrutham is locked", one Unlock button (phone fingerprint, face or screen lock; no app PIN), and an always-open "Emergency card" below it, with a note that the records stay encrypted either way.
- 14b Emergency card while locked: a banner "Amrutham is locked. Only this card is open." with an Unlock button, the person chips, the card; Print, Save PDF and Share copy are greyed until unlocked.
- 14c Ask at the end of onboarding: a sheet "Protect Amrutham with your phone's lock?", four plain points, "Turn on" and "Not now".
- 14d Settings, App lock on: switch; "Lock after you leave the app": Right away, 1 minute (default), 5 minutes, 15 minutes; "Hide Amrutham in recent apps" (on).
- 14e Settings when the phone has no screen lock: an amber notice and an "Open phone settings" button; the switch is disabled. If the screen lock is removed later, the app opens without asking and says so here, rather than locking the person out.
- 14f Not unlocked: "Try again", the emergency card still open, and a note that waiting after wrong tries is the phone's doing.
- Choices made while designing, not yet confirmed: "only when the phone locks" is dropped as a timeout (it needs a system broadcast); hiding the app in recent apps also blocks screenshots, which means it blocks adb screenshots of a debug build, so it should be off in debug builds; the person chips on the locked emergency card show names; backups, restore and the recovery-code prompts are unchanged by the lock.

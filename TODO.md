# TODO: needs your attention

Only you can do or decide these. Engineering work is in [TASKS.md](TASKS.md).

## Morning: test on the phone (nothing below has been run on a device)

Before you start: connect the phone, check it has **at least 1 GB free** (a full phone makes the install fail and `flutter run` then uninstalls the app, which wipes its data). Then ask me to deploy, or run the usual `flutter run` session.

1. **App lock.** Settings, App lock, turn it on (the phone should ask for fingerprint or screen lock).
   - Leave the app for over a minute and return: it should ask again. Check "Right away" and 5 minutes too.
   - On the lock screen, open the Emergency card: no Print, Share or Add contact, and Back returns to the lock.
   - Press Back on the lock screen: it must never reach the app.
   - Tap an Emergency card widget and an app-icon shortcut while locked: the card opens; "Log a reading" should ask you to unlock first.
   - On a phone with no screen lock the switch should be off with an explanation.
2. **Startup.** Check there is no crash on launch, now that the main activity is a FragmentActivity and the launch theme is AppCompat. If it crashes on an older Android, tell me the Android version.
3. **Widgets.** Add a fresh Emergency card and check its default size is 5x2 and no resize is needed. Check Dial and Blood group.
4. **Learn.** Open "Our healing heritage". Read the five guides for wording you would not put your name to.
5. **Care team.** Tap a doctor: the new page opens; "Works at" links to the hospital; the more button (three dots) and long-press still open the Edit / Move / Remove sheet.
6. **Expenses.** Year view: Export CSV opens a share sheet with a `.csv` file; Export PDF opens the print preview.
7. **Today.** The greeting stays on one line and the name sits below it.

## Decisions I am waiting on

**Recovery code (from the brief):**
- Which "where I kept it" choices to offer (my list: paper at home, locker, password manager, with a family member, on this phone only with a warning, haven't saved it yet, other).
- Should connecting a new Drive account or folder need the code? (You said yes; confirm it still holds now that the lock exists.)
- Should I start on the reminder card and the manual-backup-uses-stored-key change? I held off because the lock was higher priority.

**Next-dose widget:**
- Is "Skip" the app's existing "Missed" ("Not taken"), with no new status?
- Should Taken / Not taken on the widget be allowed while the app lock is on?
- Where should its data live: the same plain preferences file as the emergency card?
- It would need a way for a widget tap to write to the encrypted database, which I have not proven works. Do you want a read-only widget first ("2 medicines due", tap to open)?

**Positioning: for everyone in the world, not only India (you said so; about 3 hours ago):** the new About screen already says it. These still say India, and need your go-ahead because the first two are public:
- Website headline "Family health records for India" (`apps/web/app/page.tsx:116`) and its FAQ line about "more Indian languages". README line 7. Play listing wording.
- Emergency number: the lock screen button says 112, which GSM phones recognise in most countries, but it is the local number (911, 999, 000…) people expect. Should it follow the phone's region?
- In-app content that is India-specific: government schemes and helplines in Learn, Rupee formatting and "Ayushman"-style wording in Expenses, the language list (English, Hindi, Telugu), doctor and hospital fields, and the Doop frames for languages (9a-9m). Which of these should become region-aware, and which stay as an "India" section of Learn?

**SOS button (asked for on the lock screen notification; not built):**
- "Ring the other family phones over Tailscale or a private mesh" needs the family-devices pairing below. Without pairing, Amrutham has no way to find the other phones. Is SOS reason enough to build pairing first, and should it be Tailscale only, or also same Wi-Fi?
- "Inform an ambulance service or call centre": an app cannot silently alert 112 or 108. What it can do is open the dialer with the number filled in (the notification now has an "Emergency 112" button). Do you want 108 as well, and is 112 right for every state? Please check against a source.
- Automatic SMS to family needs the SEND_SMS permission, which Google Play restricts. Prefilled SMS (one tap to send) is the Play-safe version. Which do you want?

**Family devices (sync):** this is a large feature and I did not want to guess.
- How should phones find each other: same Wi-Fi, Tailscale, or a relay you run? ("No server of ours" rules out a relay we host.)
- What syncs: everything, or only what a person chooses to share?
- Who wins when two phones edit the same entry?
- Do you want it before the first release, or after?

**Languages:**
- Which languages ship first? Only English, Hindi and Telugu exist.
- Who reviews the translations? Health wording must not be machine-translated.

**Add-member wizard:** the design has three steps; the app has one screen plus separate add screens. Build the wizard, or keep the current flow and update the design?

**Doctor page:** clinic days and notes need a database change. Worth it? Also, should history entries and expenses get a "Doctor or hospital" picker, so visits and spending match a saved doctor exactly instead of by name?

**Lock details:**
- "Right away" will lock when you come back from the camera or a file picker. Acceptable, or should I ignore those returns?
- Hide-in-recents also blocks screenshots (off in debug builds). Keep it on by default?

## Your side (carried over)
- [ ] Google Cloud: change the debug OAuth client's package to `app.amrutham.debug`; add the upload-key SHA-1 and later the Play App Signing SHA-1; add yourself as a consent-screen test user.
- [ ] Uninstall the old `com.example.amrutham` and the earlier `app.amrutham` debug build from the phone.
- [ ] Dhanvantari artwork: confirm you may use it (licence or source) before it is on posters or the site.
- [ ] Hindi and Telugu strings: a native speaker should read them.
- [ ] Learn guides: a doctor or other qualified reviewer should read them before the Draft label is removed. For the heritage guides especially: the dates for Sushruta, the "eight kinds of surgical work" wording, and the yoga claims (back and neck pain, sleep, weight) against the NCCIH page.
- [ ] Check the helpline numbers in the app against a source.
- [ ] Doop: approve the Promotions page and the README images so I can generate them; check the lock and widget frames (pages 12 and 13).
- [ ] Send a test email to hello@amrutham.app to confirm the mailbox works.
- [ ] Play Console account, listing, privacy policy URL and data-safety answers; final wording check ("free forever", "open source GPL-3.0", "not medical advice").
- [ ] Decide when to post the "I'm working on Amrutham" announcements.

## Design review (1 Nov 2026): to build in Flutter later

New Doop frames 16a-16c, 17a-17b and "Map · Navigation, simplified". Decisions needed are marked **?**.

**Drift found and fixed in Doop:** 13f (empty allergies line is now omitted, not "none added"), 3d and 0f (Tailscale marked "Coming later"), frame 3 (old Settings, marked OLD).
**Still drifting, not yet fixed:** the 9a-9m language frames (still "All Indian languages"; need a region-neutral set), Learn India-only content (7e-7h), "vault" wording (0e, 0f: keep or "your records"? **?**), frame 15d is a partial Settings.

**Build from the designs:**
1. Settings regrouped into four groups (16a). Backup and recovery becomes a hub with a status card (16b).
2. Recovery guide, every case (16c). New things it assumes, none built yet:
   - "Check my backup" (decrypts the latest backup with the typed code, restores nothing).
   - "Make a new recovery code" when the phone still has the data, then back up again.
   - "Where I kept it" and the printable recovery sheet (no health data).
   - Reminder when the folder backup is over a week old.
3. App guides live in Settings > Help > Using Amrutham (17a), not in the Learn tab, and are also linked from the feature they explain. A "Finish setting up" checklist card on Today (5 steps: add a person, add a contact, back up, save the recovery code, set up an emergency card). First guide: emergency card (17b).
4. Readable copy (16e, decided): unprotected PDF/CSV/documents export, with a warning and a tick-box that the user takes responsibility, opened through the share sheet, with a reminder after a week to delete it.
**?** Should the setup card on Today be dismissible?

**Settings search (frames 16a, 16d):** a search field at the top of Settings. It searches a fixed list of settings and guide titles, including ones inside other pages, and shows each with its path ("Settings › Emergency cards"). It never searches health records and stores nothing. Build it from one list of entries (title, keywords, path, route) so new settings are added in one place. **?** Worth it with only ~10 top-level rows? It earns its place once the deep items are indexed.

**Setup card (decided: nice to have):** shown on Today in the slot above the tab bar (where the daily tip sits) until the 5 steps are done, with a close button; the daily tip returns after. Tapping opens Settings > Help > Using Amrutham. Designed in frame 1 (Today). The Today gear now opens the new Settings (16a).

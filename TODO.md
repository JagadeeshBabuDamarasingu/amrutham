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

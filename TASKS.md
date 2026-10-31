# Tasks

Work still to do on Amrutham. Items that need the owner's decision or action are in [TODO.md](TODO.md).

## Designed in Doop, not built in the app
- [ ] **Learn: "Our healing heritage"** hub plus five guides (Sushruta, what survives in modern surgery, Yoga, old names/new names, what research says). Designs are on Doop page "09" (frames 12a-12f). Build after the designs are approved:
  - add a `LearnHub` and the five guides (marked Draft) to `lib/learn/learn_content.dart`
  - add the hub to `learn_screen.dart` and the "Our healing heritage" chip on the library
  - tests in `test/learn_test.dart`
- [ ] Doop "Promotions" posters and README images: render final PNGs locally with Edge (`assets/announcements/src/shot.bat`) into `docs/images/` (`banner.png`, `screens.png`, `privacy.png`), then commit `README.md` with them.

## Features not built yet
- [ ] **Edit screens** for profile, expenses, medical history, medicines and allergies (only the care team has "edit all fields" so far).
- [ ] **"Linked to" picker on expenses** (link an expense to a care provider or record).
- [ ] **Family devices**: pairing, Tailscale and live sync between phones.
- [ ] **More languages**: Hindi and Telugu cover the main screens only; the rest of the app and other languages are open.
- [ ] Hindi and Telugu strings of the new screens (Add sheet, care team, backups, automatic backups).

## Needs checking on a real phone
- [ ] Automatic background backups (WorkManager). Drive in the background may fail and fall back to catching up when the app opens.
- [ ] Backing up to a folder through the Android document tree.
- [ ] `.debug` build running beside the release app, plus the new adaptive and white-background icons.
- [ ] Release build signed with the upload key (needs `android/key.properties`).

## Quality and housekeeping
- [ ] Audit that every dependency's licence is compatible with GPL-3.0.
- [ ] Review every Learn guide against sources; they are all Draft.
- [ ] Check the Android 13+ notification permission flow and exact-alarm behaviour for reminders on different phones.
- [ ] Add CI (`flutter analyze` and `flutter test`) on push.
- [ ] Decide what to do with untracked or modified files: generated linux/windows/macos plugin registrants, `.ignore`, `DESIGN.md`, `assets/`, `apps/mobile/android/build/` (the last should probably be git-ignored).
- [ ] Riverpod 3.x upgrade is blocked by the Realm dependency; revisit later.
- [ ] Play Store listing pieces: privacy policy page on the website, data-safety form answers, screenshots, short and long descriptions.

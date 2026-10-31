# TODO: needs your attention

Things only you can do or decide. Engineering work is in [TASKS.md](TASKS.md).

## Do these first
- [x] **Back up the upload keystore and its password** (done: keystore and `key.properties` backed up) somewhere other than this machine. Losing it blocks Play updates.
- [ ] **Google Cloud (Drive backup)**
  - change the debug OAuth client's package to `app.amrutham.debug`
  - add the upload-key SHA-1 (`CF:51:...:F8`) and, later, the Play App Signing SHA-1
  - add yourself as a test user on the consent screen
- [ ] **Uninstall the old apps** from the phone (`com.example.amrutham` and the earlier `app.amrutham` debug build), then install the new `.debug` build.

## Review and decide
- [ ] **Doop page "09 · Learn: our healing heritage"** (frames 12a-12f): approve or send changes. Hub 12a was not render-checked; please look at it. Say if you want two hubs (surgery, yoga) instead of one.
- [ ] **Doop page "11 · Promotions"**: review the posters, README banner, strip and diagram. When you approve, I render the PNGs and commit the README.
- [ ] **Dhanvantari artwork**: confirm you can use the image (licence or source) before it goes on posters or the site.
- [ ] **Hindi and Telugu strings**: get a native speaker to read them.
- [ ] **Learn content**: have a doctor or other qualified reviewer read the guides, especially Sushruta's dating and the "eight procedures" wording, before removing the Draft label.
- [ ] Decide whether to extend "edit all fields" beyond the care team (profile, expenses, history, medicines, allergies).
- [ ] Decide on the helpline numbers shown in the app: they are unverified and need a source check.

## Test on your phone
- [ ] Turn on **Automatic backups** to a folder and to Google Drive, leave the app closed for a day, and see if a backup appears.
- [ ] Make a manual folder backup and check the file is in the folder.
- [ ] Send a problem report and a test email to hello@amrutham.app to confirm the mailbox works.

## Launch
- [ ] Play Console developer account, app listing, privacy policy URL and data-safety answers.
- [ ] Final check of wording: "free forever", "open source (GPL-3.0)", "not medical advice".
- [ ] Decide when to post the "I'm working on Amrutham" announcements.

/// Privacy policy and terms, kept in the app so they can be read offline.
/// The same text is published at amrutham.app/privacy and /terms; change both
/// together.
library;

const legalUpdated = '5 November 2026';

class LegalSection {
  const LegalSection(this.heading, this.paragraphs, {this.bullets = const []});
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
}

class LegalDoc {
  const LegalDoc(this.title, this.intro, this.sections);
  final String title;
  final String intro;
  final List<LegalSection> sections;
}

const privacyDoc = LegalDoc(
  'Privacy policy',
  'Amrutham keeps your family\'s health information on your phone. This page says plainly what that means.',
  [
    LegalSection('What we collect', [
      'Nothing. Amrutham has no account, no analytics, no advertising and no server of ours that receives your data. We cannot see your records, and we cannot recover them for you.',
    ]),
    LegalSection('Where your information lives', [], bullets: [
      'Names, medicines, measurements, history, expenses and care-team details are stored in a database on your phone, encrypted with a key kept in the phone\'s secure storage.',
      'Documents you add are saved as ordinary files in a folder on your phone.',
      'Your recovery code is never stored. The phone keeps only a salted hash used to check a code you type.',
      'If you turn on a phone lock, Amrutham asks your phone to check your fingerprint, face or screen lock. It never sees or stores them.',
    ]),
    LegalSection('Home screen cards and the lock-screen notice', [
      'Both are off until you turn them on. When on, the app keeps a small copy of only the details you chose to show (for example a name, blood group, allergies and phone numbers to dial) in a file on your phone, so the home screen or notification can display it.',
      'That copy is not encrypted like the database. Anyone who can see your home screen or lock screen can read what is shown. The copy is left out of Android\'s cloud backup and device transfer, and it is deleted when you turn the feature off.',
    ]),
    LegalSection('Medicine alarms and photos', [
      'Alarms are set on your phone by the phone\'s own alarm system. They work with no internet. When one rings it can open a full-screen alarm over the lock screen, so an elder can answer it without unlocking the phone. That screen shows only the medicine name, dose and the photo you chose.',
      'A photo of a medicine (so that someone can recognise the tablet) is saved on your phone with your other records, and is included in your encrypted backup. It is never uploaded anywhere by the app.',
    ]),
    LegalSection('Backups', [
      'A backup is a single file, encrypted with a key made from your recovery code before it leaves the database. You choose where it goes:',
    ], bullets: [
      'A folder on your phone or a storage service you pick.',
      'Your own Google Drive, in the app\'s private area (the "app data" space). Amrutham can only see files it created there, and nothing else in your Drive. Signing in uses Google\'s own sign-in; Amrutham does not receive your password.',
      'Google can see that an encrypted file exists and its size, as with any file you store with them. They cannot read its contents without your recovery code. Google\'s own terms and privacy policy apply to what you store with them.',
    ]),
    LegalSection('What the app can ask your phone for', [], bullets: [
      'Notifications, exact alarms and full-screen alerts, to ring medicine reminders on time and show them over the lock screen. Reminders work without the internet.',
      'Camera, photos and files, only when you choose to add a record or a medicine photo.',
      'The phone dialer, only when you tap a call button. The call is made by your phone, not by the app.',
      'The share sheet, only when you choose to share or export something. What you share is sent by the app you pick, not by Amrutham.',
      'Fingerprint, face or screen lock, only to unlock the app if you turn the app lock on. With the app lock on, Amrutham also hides its preview in the recent-apps list. Alarms are never blocked by the lock.',
    ]),
    LegalSection('The internet', [
      'The app does not send your information anywhere on its own. It uses the internet only when you back up to Google Drive, or open a link to an official website such as a government health site.',
    ]),
    LegalSection('Health guides', [
      'The guides in the app are general information, not medical advice. Reading them leaves no history, and nothing you read is recorded or shared.',
    ]),
    LegalSection('Children', [
      'A parent or guardian can add a child as a profile. The information stays on the parent\'s phone like everything else.',
    ]),
    LegalSection('Your choices', [
      'Everything is yours to export or delete. Removing the app removes the database and documents from the phone; backups you made stay where you put them until you delete them.',
    ]),
    LegalSection('Changes', [
      'If this changes, the new version will be published at amrutham.app/privacy with its date before an app update relies on it.',
    ]),
  ],
);

const termsDoc = LegalDoc(
  'Terms of use',
  'These terms cover using Amrutham. By using the app you agree to them. They are short on purpose.',
  [
    LegalSection('What Amrutham is', [
      'Amrutham is a free, open-source app (GPL-3.0) for keeping your family\'s health records, medicines and reminders on your phone. It is a record-keeping tool.',
    ]),
    LegalSection('Not medical advice, not an emergency service', [], bullets: [
      'Amrutham does not diagnose, treat or advise. The guides are general information; talk to a qualified professional about your own situation.',
      'The app does not contact emergency services or anyone else for you. In an emergency, call your local emergency number.',
      'Reminders depend on your phone: its battery settings, silent mode, updates and notifications permission can stop them. Do not rely on Amrutham as your only way of remembering a critical dose.',
      'You are responsible for checking that what you enter is correct. Entries marked "as reported" are not verified.',
    ]),
    LegalSection('Your data and your recovery code', [
      'Your data lives on your phone. We hold no copy and cannot recover it. If you lose your phone and have no backup, or lose your recovery code, your records cannot be restored by anyone. Keep a backup and keep your recovery code somewhere safe.',
    ]),
    LegalSection('What you choose to show', [
      'Home screen cards, the lock-screen notice and the emergency card can be read by anyone who can see or pick up your phone. You decide what they show, and you are responsible for the choice.',
    ]),
    LegalSection('Using it for others', [
      'If you keep records for someone else, such as a child or a parent, you confirm you are entitled to do so and will treat their information with care.',
    ]),
    LegalSection('Licence', [
      'Amrutham is free software under the GNU General Public License v3.0. You may use, study, share and change it under that licence. The source is at github.com/JagadeeshBabuDamarasingu/amrutham. Third-party software and fonts keep their own licences, listed under Credits.',
    ]),
    LegalSection('No warranty, limited liability', [
      'The app is provided "as is", without warranty of any kind, as the GPL describes. To the extent the law allows, the authors are not liable for loss or harm arising from using the app, including lost data, missed reminders or mistakes in entries. Nothing here limits rights you have under law that cannot be waived.',
    ]),
    LegalSection('Changes', [
      'These terms may change. The current version is always at amrutham.app/terms, with its date.',
    ]),
  ],
);

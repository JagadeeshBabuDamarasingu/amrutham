/// What the About screen says about the app. The version must match
/// pubspec.yaml: test/about_test.dart fails if they drift apart.
const appVersion = '0.9.0';
const appBuild = '1';

const sourceUrl = 'https://github.com/JagadeeshBabuDamarasingu/amrutham';
const issuesUrl = '$sourceUrl/issues';
const privacyUrl = 'https://amrutham.app/privacy';

const aboutVision =
    'Every family, anywhere in the world, can keep its health history in one place '
    'that it owns, and find it when it matters.';

const aboutMission =
    'To build a family health record that costs nothing, shows no ads and needs no '
    'account, and keeps what you enter on your own phone. Amrutham writes down what '
    'you tell it and explains how things work. It never diagnoses you or tells you '
    'what to do.';

/// One group of software on the Credits screen.
class CreditGroup {
  const CreditGroup(this.title, this.items);

  final String title;
  final List<Credit> items;
}

class Credit {
  const Credit(this.name, this.what, [this.licence]);

  final String name;
  final String what;

  /// Null where the licence is not one fixed text (a tool, or a service).
  final String? licence;
}

/// Every package the app depends on, and the tools it was made with. Full
/// licence texts are shown by Flutter's own licence page, which reads them from
/// the packages themselves, so the short names here are only a guide.
const credits = [
  CreditGroup('The app', [
    Credit('Flutter and Dart', 'The toolkit and language the whole app is written in', 'BSD-3'),
    Credit('flutter_riverpod', 'Keeps screens in step with your data', 'MIT'),
  ]),
  CreditGroup('Your data, kept safe', [
    Credit('Realm', 'The database on your phone', 'Apache-2.0'),
    Credit('flutter_secure_storage', "Holds the database key in the phone's secure storage", 'BSD-3'),
    Credit('cryptography', 'Argon2id and AES-256-GCM, for encrypted backups', 'Apache-2.0'),
    Credit('local_auth', 'Fingerprint, face or screen lock for the app lock', 'BSD-3'),
    Credit('ulid', 'Unique ids for your records', 'MIT'),
  ]),
  CreditGroup('Backups, sharing and files', [
    Credit('google_sign_in and http', 'Optional backup to your own Google Drive', 'BSD-3'),
    Credit('workmanager', 'Runs automatic backups in the background', 'MIT'),
    Credit('share_plus', 'Sends a file or card to another app', 'BSD-3'),
    Credit('file_picker and image_picker', 'Choosing documents, folders and photos', 'MIT · BSD-3'),
    Credit('path_provider', 'Finds where files live on the phone', 'BSD-3'),
    Credit('printing', 'Print or save the emergency card and reports as PDF', 'Apache-2.0'),
  ]),
  CreditGroup('Reminders and links', [
    Credit('flutter_local_notifications', 'Medicine and visit reminders', 'BSD-3'),
    Credit('timezone and flutter_timezone', 'So a 9 am reminder is 9 am where you are', 'BSD-2 · MIT'),
    Credit('url_launcher', 'Opens the dialer, maps and web pages', 'BSD-3'),
  ]),
  CreditGroup('Typefaces', [
    Credit('Figtree', 'Body text. By Erik Kennedy', 'OFL'),
    Credit('Bricolage Grotesque', 'Headings. By Mathieu Triay', 'OFL'),
  ]),
  CreditGroup('Used to build it', [
    Credit('Android and Gradle', 'The platform and the build tool', 'Apache-2.0'),
    Credit('Next.js and Vercel', 'The amrutham.app website', 'MIT'),
    Credit('Doop', 'Where every screen was designed first'),
    Credit('Claude Code', 'An AI assistant that helped write and test the code. A person reviews and ships every change.'),
  ]),
];

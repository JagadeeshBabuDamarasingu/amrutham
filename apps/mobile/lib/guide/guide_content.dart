/// Step-by-step help for using the app. Written for anyone, anywhere: no
/// country-specific rules, only what the app does.
library;

/// Where a step's button takes the person.
enum GuideAction { family, cards, medicalInfo, backup, lock }

class GuideStep {
  const GuideStep(this.title, this.body, {this.button, this.action});
  final String title;
  final String body;
  final String? button;
  final GuideAction? action;
}

class Guide {
  const Guide({
    required this.id,
    required this.title,
    required this.blurb,
    required this.intro,
    required this.steps,
    this.note,
  });
  final String id;
  final String title;
  final String blurb;
  final String intro;
  final List<GuideStep> steps;
  final String? note;
}

const emergencyGuide = Guide(
  id: 'emergency',
  title: 'Set up an emergency card',
  blurb: 'So a stranger can help in under a minute',
  intro:
      'About 5 minutes. When someone is hurt or unwell, a stranger can see who they are, '
      'what to avoid, and who to call.',
  steps: [
    GuideStep(
      'Fill in the details that matter',
      'Blood group, allergies, the medicines taken every day, and at least one person to call. '
          'Open the person in Family and add what you know. An entry marked "as reported" is shown as unverified.',
      button: 'Open Family',
      action: GuideAction.family,
    ),
    GuideStep(
      'Add emergency contacts',
      'Add two if you can: someone nearby, and someone who answers late at night. '
          'Write the number the way you would dial it, with the country code if they live abroad.',
      button: 'Open Family',
      action: GuideAction.family,
    ),
    GuideStep(
      'Put a card on the home screen',
      'Touch and hold an empty spot on the home screen, choose Widgets, then Amrutham. '
          'Pick the Emergency card. Your phone asks who it is for and what it shows.',
      button: 'Choose what cards show',
      action: GuideAction.cards,
    ),
    GuideStep(
      'Show it on the lock screen',
      'Turn on the lock-screen notice. A stranger can read the blood group and numbers without unlocking. '
          'The numbers are written out so they can be dialled from the phone\'s emergency screen. '
          'A tap to call needs the phone unlocked.',
      button: 'Open emergency card settings',
      action: GuideAction.cards,
    ),
    GuideStep(
      'Add your phone\'s own Medical info',
      'Paramedics and strangers know to look here. It works even when the phone is locked, and the numbers can '
          'be tapped to call. Open it, then add blood group, allergies and contacts.',
      button: 'Open Medical info',
      action: GuideAction.medicalInfo,
    ),
    GuideStep(
      'Keep a paper copy',
      'Open the person\'s Emergency card in Family, then choose Print or save as PDF. Keep it in a wallet or bag, '
          'or give it to a neighbour. It works when the phone is dead or lost.',
      button: 'Open Family',
      action: GuideAction.family,
    ),
  ],
  note:
      'Anything on the home screen or lock screen can be read by anyone who picks up the phone. '
      'Choose only what you are comfortable with. You can change it any time in Settings, Emergency cards.',
);

const familyGuide = Guide(
  id: 'family',
  title: 'Add your family',
  blurb: 'Children, parents, or someone you care for',
  intro: 'Everyone gets their own profile, with their own medicines, records and emergency card. All of it stays on this phone.',
  steps: [
    GuideStep(
      'Add a person',
      'Open Family and tap Add. Enter a name and how they are related to you. Birth date and blood group are optional, and you can add them later.',
      button: 'Open Family',
      action: GuideAction.family,
    ),
    GuideStep(
      'Fill in their profile',
      'Open the person to add allergies, medicines, past surgeries, doctors and emergency contacts. Add only what you know. You can come back any time.',
    ),
    GuideStep(
      'Someone who has passed away',
      'Choose "Remembered" when you add them. Their reminders stop and their records stay, so family history is not lost.',
    ),
  ],
);

const medicinesGuide = Guide(
  id: 'medicines',
  title: 'Medicines and reminders',
  blurb: 'Add a course, and make sure reminders ring',
  intro: 'Add a medicine once, with the times, and Amrutham reminds you each day until the course ends.',
  steps: [
    GuideStep(
      'Add a medicine',
      'Open the person in Family and tap Add medicine. Enter the name, the dose, the times each day, and how long it lasts.',
      button: 'Open Family',
      action: GuideAction.family,
    ),
    GuideStep(
      'Allow notifications',
      'When your phone asks, choose Allow. Without this, reminders cannot appear.',
    ),
    GuideStep(
      'Mark each dose',
      'On Today, tap Taken when you have taken it, or Missed if you skipped it. The history keeps both, so you can show a doctor.',
    ),
    GuideStep(
      'If reminders are late or missing',
      'See "Reminders are late or missing" in this list. Some phones stop reminders to save battery.',
    ),
  ],
);

const backupGuide = Guide(
  id: 'backup',
  title: 'Back up, and get it back',
  blurb: 'Every way to recover, in plain steps',
  intro:
      'Your records live only on this phone, so a backup is the only way to get them back if it is lost, broken or reset.',
  steps: [
    GuideStep(
      'Write down your recovery code',
      'Amrutham makes a code when you add your first person. Write it on paper and keep it somewhere safe. '
          'Without it, nobody can open your backup, including us.',
    ),
    GuideStep(
      'Choose where backups go',
      'Settings, Backup and recovery. Pick your own Google Drive, a folder on the phone, or both. Two places is safer than one.',
      button: 'Open Backup and recovery',
      action: GuideAction.backup,
    ),
    GuideStep(
      'Turn on automatic backups',
      'In Backup and recovery, open Automatic backups. Then you never have to remember.',
      button: 'Open Backup and recovery',
      action: GuideAction.backup,
    ),
    GuideStep(
      'On a new phone',
      'Install Amrutham, tap "I already have a vault" on the first screen, choose your backup, and type your recovery code.',
    ),
    GuideStep(
      'If you lose the code',
      'While you still have the old phone, your records are not lost yet: make a new backup right away. '
          'If you have lost both the phone and the code, the backup cannot be opened by anyone.',
    ),
  ],
);

const lockGuide = Guide(
  id: 'lock',
  title: 'Lock the app',
  blurb: 'What it protects, and what stays visible',
  intro: 'The app lock asks for your fingerprint, face or phone lock before showing anything private.',
  steps: [
    GuideStep(
      'Turn it on',
      'Settings, App lock. Your phone needs a screen lock set up first.',
      button: 'Open App lock',
      action: GuideAction.lock,
    ),
    GuideStep(
      'Choose when it locks',
      'Pick how long the app can be out of sight before it locks again, from right away to several minutes.',
    ),
    GuideStep(
      'What stays visible',
      'On the lock screen, anyone can open the Emergency card, so a stranger can still help. They cannot print, share or edit it, and they cannot see anything else.',
    ),
  ],
);

const remindersGuide = Guide(
  id: 'reminders',
  title: 'Reminders are late or missing',
  blurb: 'Battery and notification settings',
  intro: 'Phones sometimes stop apps in the background to save battery. These settings fix most late or missing reminders.',
  steps: [
    GuideStep(
      'Allow notifications',
      'Phone settings, Apps, Amrutham, Notifications. Make sure they are on.',
    ),
    GuideStep(
      'Allow alarms and reminders',
      'In the same app settings, look for "Alarms & reminders" and turn it on, so reminders arrive at the exact minute.',
    ),
    GuideStep(
      'Stop battery saving for Amrutham',
      'Phone settings, Apps, Amrutham, Battery. Choose "Unrestricted" or "Don\'t optimise". Some phones also have an auto-start or "protected apps" list: add Amrutham to it.',
    ),
    GuideStep(
      'Check Do Not Disturb',
      'Silent or Do Not Disturb modes can hide reminders. Allow Amrutham as an exception, or turn the mode off.',
    ),
  ],
);

const startGuides = [emergencyGuide, familyGuide, medicinesGuide];
const safeGuides = [backupGuide, lockGuide];
const troubleGuides = [remindersGuide];
const allGuideList = [...startGuides, ...safeGuides, ...troubleGuides];

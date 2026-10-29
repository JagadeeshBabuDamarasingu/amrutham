import 'package:flutter/widgets.dart';

/// App chrome in other languages. Anything not listed here shows in English.
///
/// These are NOT reviewed translations (see [languages]): health guides are
/// never translated by machine, and these few words still want a native
/// speaker's check before release.
const _translations = <String, Map<String, String>>{
  'hi': {
    'Today': 'आज',
    'Family': 'परिवार',
    'Records': 'रिकॉर्ड',
    'Learn': 'सीखें',
    'Later today': 'आज आगे',
    'Taken': 'ले ली',
    'Missed': 'छूट गई',
    'Settings': 'सेटिंग्स',
    'Language': 'भाषा',
    'Good morning': 'सुप्रभात',
    'Good afternoon': 'नमस्कार',
    'Good evening': 'शुभ संध्या',
  },
  'te': {
    'Today': 'ఈ రోజు',
    'Family': 'కుటుంబం',
    'Records': 'రికార్డులు',
    'Learn': 'నేర్చుకోండి',
    'Later today': 'ఈ రోజు తర్వాత',
    'Taken': 'వేసుకున్నాను',
    'Missed': 'తప్పింది',
    'Settings': 'సెట్టింగ్‌లు',
    'Language': 'భాష',
    'Good morning': 'శుభోదయం',
    'Good afternoon': 'శుభ మధ్యాహ్నం',
    'Good evening': 'శుభ సాయంత్రం',
  },
};

/// The English text, in the app language if we have it.
String tr(BuildContext context, String english) =>
    _translations[Localizations.localeOf(context).languageCode]?[english] ??
    english;

/// Languages with translated app chrome; the rest are listed as coming.
const available = {'en', 'hi', 'te'};

/// (code, name in its own script, English name)
const languages = [
  ('hi', 'हिन्दी', 'Hindi'),
  ('te', 'తెలుగు', 'Telugu'),
  ('ta', 'தமிழ்', 'Tamil'),
  ('bn', 'বাংলা', 'Bengali'),
  ('mr', 'मराठी', 'Marathi'),
  ('ur', 'اردو', 'Urdu'),
  ('en', 'English', 'English'),
  ('es', 'Español', 'Spanish'),
  ('fr', 'Français', 'French'),
  ('ar', 'العربية', 'Arabic'),
];

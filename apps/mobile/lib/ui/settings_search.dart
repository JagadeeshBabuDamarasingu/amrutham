import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../about/legal_text.dart';
import '../guide/guide_content.dart';
import 'about_screen.dart';
import 'app_lock_screen.dart';
import 'app_style.dart';
import 'auto_backup_screen.dart';
import 'backup_recovery_screen.dart';
import 'guide_screens.dart';
import 'language_screen.dart';
import 'medicine_alarms_screen.dart';
import 'legal_screen.dart';
import 'problem_report.dart';
import 'recovery_cases_screen.dart';
import 'restore_screen.dart';
import 'storage_screens.dart';
import 'widgets_settings_screen.dart';

/// One thing the search can open. Only settings and help are listed here:
/// health records are never searched.
class SettingsEntry {
  const SettingsEntry(this.title, this.path, this.keywords, this.open);
  final String title;
  final String path;
  final String keywords;
  final void Function(BuildContext context) open;
}

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

const _safe = 'Settings › Keep your records safe';
const _hub = 'Settings › Backup and recovery';
const _help = 'Settings › Help';

final List<SettingsEntry> settingsEntries = [
  SettingsEntry(
    'Backup and recovery',
    _safe,
    'backup back up copy save drive google folder restore',
    (c) => _push(c, const BackupRecoveryScreen()),
  ),
  SettingsEntry(
    'Automatic backups',
    _hub,
    'backup automatic daily weekly schedule',
    (c) => _push(c, const AutoBackupScreen()),
  ),
  SettingsEntry(
    'Where backups go',
    _hub,
    'backup google drive folder storage place',
    (c) => _push(c, const StorageChoiceScreen()),
  ),
  SettingsEntry(
    'Restore from a backup',
    _hub,
    'restore new phone replace reinstall get back',
    (c) => _push(c, const RestoreVaultScreen(replacing: true)),
  ),
  SettingsEntry(
    'Check that I still have my recovery code',
    _hub,
    'recovery code check verify',
    (c) => _push(c, const BackupRecoveryScreen()),
  ),
  SettingsEntry(
    'Where did you keep your code?',
    _hub,
    'recovery code kept paper locker note',
    (c) => _push(c, const BackupRecoveryScreen()),
  ),
  SettingsEntry(
    'Make a new recovery code',
    _hub,
    'recovery code new forgot lost replace',
    (c) => _push(c, const BackupRecoveryScreen()),
  ),
  SettingsEntry(
    'I lost my phone, my code, or both',
    _hub,
    'lost phone code recover worst case stolen broken',
    (c) => _push(c, const RecoveryCasesScreen()),
  ),
  SettingsEntry(
    'App lock',
    _safe,
    'lock fingerprint face biometric pin screen lock recents private',
    (c) => _push(c, const AppLockScreen()),
  ),
  SettingsEntry(
    'Emergency cards',
    'Settings › Emergency cards',
    'emergency card widget home screen lock screen notice medical info dial blood group allergies',
    (c) => _push(c, const WidgetsSettingsScreen()),
  ),
  SettingsEntry(
    'Emergency card on the lock screen',
    'Settings › Emergency cards',
    'lock screen notification stranger medical info',
    (c) => _push(c, const WidgetsSettingsScreen()),
  ),
  SettingsEntry(
    'Medicine alarms',
    'Settings › On this phone',
    'alarm reminder medicine tablet dose ring snooze time schedule notification',
    (c) => _push(c, const MedicineAlarmsScreen()),
  ),
  SettingsEntry(
    'Language',
    'Settings › On this phone',
    'language hindi telugu english translate',
    (c) => _push(c, const LanguageScreen()),
  ),
  SettingsEntry(
    'Using Amrutham',
    _help,
    'help guide how to start learn',
    (c) => _push(c, const UsingAmruthamScreen()),
  ),
  for (final g in allGuideList)
    SettingsEntry(
      g.title,
      '$_help › Using Amrutham',
      '${g.blurb} guide how',
      (c) => _push(c, GuideScreen(g)),
    ),
  SettingsEntry(
    'About Amrutham',
    '$_help › About',
    'about vision mission version',
    (c) => _push(c, const AboutScreen()),
  ),
  SettingsEntry(
    'Credits and licences',
    '$_help › About',
    'credits licence license open source software fonts',
    (c) => _push(c, const CreditsScreen()),
  ),
  SettingsEntry(
    'Contact us',
    '$_help › About',
    'contact email write question idea',
    (c) => _push(c, const ContactScreen()),
  ),
  SettingsEntry(
    'Privacy policy',
    '$_help › About',
    'privacy policy data',
    (c) => _push(c, const LegalScreen(privacyDoc)),
  ),
  SettingsEntry(
    'Terms of use',
    '$_help › About',
    'terms conditions rules',
    (c) => _push(c, const LegalScreen(termsDoc)),
  ),
  SettingsEntry(
    'Send a problem report',
    _help,
    'problem report crash bug error feedback',
    (c) => showProblemReport(c),
  ),
];

/// Entries whose title or keywords contain every word typed, title matches first.
List<SettingsEntry> searchSettings(
  String query, [
  List<SettingsEntry>? entries,
]) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];
  final hits = <(int, SettingsEntry)>[];
  for (final e in entries ?? settingsEntries) {
    final title = e.title.toLowerCase();
    final all = '$title ${e.keywords}';
    if (!words.every(all.contains)) continue;
    hits.add((words.every(title.contains) ? 0 : 1, e));
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final h in hits) h.$2];
}

const _suggestions = [
  'backup',
  'recovery code',
  'language',
  'widget',
  'privacy',
];

/// The field at the top of Settings; shows results in place of [child] while
/// something is typed.
class SettingsSearch extends ConsumerStatefulWidget {
  const SettingsSearch({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SettingsSearch> createState() => _SettingsSearchState();
}

class _SettingsSearchState extends ConsumerState<SettingsSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Widget _highlight(String text, String query) {
    final i = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    const base = TextStyle(
      fontWeight: FontWeight.w800,
      color: onboardInk,
      fontSize: 15,
    );
    if (i < 0) return Text(text, style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: const TextStyle(backgroundColor: Color(0xFFF9E2A8)),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final results = searchSettings(query);
    final searching = query.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search settings',
            suffixIcon: searching
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_controller.clear),
                  )
                : null,
          ),
        ),
        if (!searching && _focus.hasFocus) ...[
          const SectionLabel('Try'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _controller.text = s),
                ),
            ],
          ),
        ],
        if (searching) ...[
          SectionLabel(
            results.isEmpty
                ? 'No results'
                : '${results.length} ${results.length == 1 ? 'result' : 'results'}',
          ),
          if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Nothing matches. Try one word, like "backup" or "lock".',
                style: TextStyle(color: onboardMuted, height: 1.4),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      title: _highlight(results[i].title, query),
                      subtitle: Text(results[i].path),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => results[i].open(context),
                    ),
                  ],
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 0),
            child: Text(
              'Search looks inside settings pages too. It never searches your health records, and nothing you type is stored.',
              style: TextStyle(
                color: onboardMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ] else
          widget.child,
      ],
    );
  }
}

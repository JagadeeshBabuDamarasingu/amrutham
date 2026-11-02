import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lock/lock_controller.dart';
import '../lock/lock_settings.dart';
import '../providers/app_providers.dart';
import 'about_screen.dart';
import 'app_lock_screen.dart';
import 'app_style.dart';
import 'backup_recovery_screen.dart';
import 'guide_screens.dart';
import 'language_screen.dart';
import 'medicine_alarms_screen.dart';
import 'problem_report.dart';
import 'settings_search.dart';
import 'strings.dart';
import 'widgets_settings_screen.dart';

/// Frame 16a: four groups, each with one job.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsHidden = ref.watch(tipsHiddenProvider).valueOrNull ?? false;
    final (places, last) = backupState(ref);
    final lockOn =
        (ref.watch(lockSettingsProvider).valueOrNull ?? const LockSettings())
            .enabled;
    final cardsOn =
        ref.watch(widgetSettingsProvider).valueOrNull?.enabled ?? false;
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    Widget tile(
      String label,
      String sub, {
      VoidCallback? onTap,
      Widget? trailing,
    }) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            tr(context, 'Settings'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          SettingsSearch(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Keep your records safe'),
                Card(
                  child: Column(
                    children: [
                      tile(
                        'Backup and recovery',
                        places == 0
                            ? 'Not backed up yet'
                            : 'Backed up ${ago(last)} · ${places == 1 ? '1 place' : '$places places'}',
                        onTap: () => open(const BackupRecoveryScreen()),
                      ),
                      const Divider(height: 1),
                      tile(
                        'App lock',
                        lockOn
                            ? "On. Opens with your phone's lock."
                            : "Off. Keep other people out with your phone's lock.",
                        onTap: () => open(const AppLockScreen()),
                      ),
                    ],
                  ),
                ),
                const SectionLabel('For emergencies'),
                Card(
                  child: tile(
                    'Emergency cards',
                    cardsOn
                        ? 'On. Home screen and lock screen.'
                        : 'Off. Put an emergency card on your home screen.',
                    onTap: () => open(const WidgetsSettingsScreen()),
                  ),
                ),
                const SectionLabel('On this phone'),
                Card(
                  child: Column(
                    children: [
                      tile(
                        'Medicine alarms',
                        'See every alarm, check it can ring, try one.',
                        onTap: () => open(const MedicineAlarmsScreen()),
                      ),
                      const Divider(height: 1),
                      tile(
                        tr(context, 'Language'),
                        'Set on this phone only.',
                        onTap: () => open(const LanguageScreen()),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        title: const Text(
                          'Daily tip',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'One short line above the tab bar. Same for everyone, never a notification.',
                        ),
                        value: !tipsHidden,
                        onChanged: (show) async {
                          await ref
                              .read(onboardingStoreProvider)
                              .setTipsHidden(!show);
                          ref.invalidate(tipsHiddenProvider);
                        },
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Help'),
                Card(
                  child: Column(
                    children: [
                      tile(
                        'Using Amrutham',
                        'Step-by-step guides, and what to do if something goes wrong',
                        onTap: () => open(const UsingAmruthamScreen()),
                      ),
                      const Divider(height: 1),
                      tile(
                        'About, privacy and terms',
                        'Our vision, credits and how to reach us',
                        onTap: () => open(const AboutScreen()),
                      ),
                      const Divider(height: 1),
                      tile(
                        'Send a problem report',
                        'See what crashed, then choose whether to send it.',
                        onTap: () => showProblemReport(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

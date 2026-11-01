import 'package:amrutham_widgets/amrutham_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guide/guide_content.dart';
import '../guide/setup_progress.dart';
import 'app_lock_screen.dart';
import 'app_shell.dart';
import 'app_style.dart';
import 'backup_recovery_screen.dart';
import 'widgets_settings_screen.dart';

/// Frame 17a: every guide in one list, with setup progress on top.
class UsingAmruthamScreen extends ConsumerWidget {
  const UsingAmruthamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(setupStepsProvider);
    final done = steps.where((s) => s.done).length;
    final next = steps.where((s) => !s.done).firstOrNull;

    Widget group(String label, List<Guide> guides) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < guides.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  title: Text(guides[i].title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(guides[i].blurb),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GuideScreen(guides[i])),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Using Amrutham',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null ? 'ALL SET' : '$done OF ${steps.length} DONE',
                  style: const TextStyle(color: Color(0xFFB8D0C5), fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  next == null ? 'You are all set up' : 'Finish setting up',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                for (final s in steps)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InkWell(
                      onTap: s.done
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GuideScreen(s.guide))),
                      child: Row(
                        children: [
                          Icon(
                            s.done ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 20,
                            color: s.done ? onboardAmber : const Color(0xFFB8D0C5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.label,
                              style: TextStyle(
                                color: s.done ? const Color(0xFFB8D0C5) : Colors.white,
                                decoration: s.done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (!s.done) const Icon(Icons.chevron_right, color: onboardAmber),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          group('Start here', startGuides),
          group('Keep it safe', safeGuides),
          group('Something not working?', troubleGuides),
        ],
      ),
    );
  }
}

/// Frame 17b: numbered steps, each with a button that goes to the right place.
class GuideScreen extends ConsumerWidget {
  const GuideScreen(this.guide, {super.key});

  final Guide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            guide.title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(guide.intro, style: const TextStyle(fontSize: 15.5, height: 1.45, color: onboardMuted)),
          const SizedBox(height: 12),
          for (var i = 0; i < guide.steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: onboardInk,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guide.steps[i].title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(guide.steps[i].body, style: const TextStyle(height: 1.45)),
                        if (guide.steps[i].action != null) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => runGuideAction(context, ref, guide.steps[i].action!),
                            child: Text(guide.steps[i].button ?? 'Open'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (guide.note != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFBEFD2), borderRadius: BorderRadius.circular(16)),
              child: Text(guide.note!, style: const TextStyle(color: Color(0xFF4A3300), height: 1.45)),
            ),
        ],
      ),
    );
  }
}

Future<void> runGuideAction(BuildContext context, WidgetRef ref, GuideAction action) async {
  final nav = Navigator.of(context);
  switch (action) {
    case GuideAction.family:
      nav.popUntil((r) => r.isFirst);
      ref.read(shellTabProvider.notifier).state = 1;
    case GuideAction.cards:
      nav.push(MaterialPageRoute(builder: (_) => const WidgetsSettingsScreen()));
    case GuideAction.backup:
      nav.push(MaterialPageRoute(builder: (_) => const BackupRecoveryScreen()));
    case GuideAction.lock:
      nav.push(MaterialPageRoute(builder: (_) => const AppLockScreen()));
    case GuideAction.medicalInfo:
      final opened = await AmruthamWidgets.openMedicalInfo();
      if (!context.mounted || opened) return;
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Open it from Settings'),
          content: const Text('This phone would not open it from here. Look in Settings for "Safety & emergency", then "Medical information".'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('OK'))],
        ),
      );
  }
}

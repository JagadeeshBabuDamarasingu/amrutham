import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'app_style.dart';
import 'backup_recovery_screen.dart';
import 'recovery_flow_screen.dart';
import 'restore_screen.dart';

/// Where the person says they keep the recovery code. Only the choice is
/// kept, never the code.
const codeKeptKey = 'code_kept';
const codeKeptChoices = [
  'On paper at home',
  'In a locker or safe',
  'In a password manager',
  'With a family member',
  'Only on this phone (risky)',
  "I haven't saved it yet",
  'Somewhere else',
];

final codeKeptProvider = FutureProvider<String?>(
  (ref) => ref.watch(onboardingStoreProvider).setting(codeKeptKey),
);

Future<void> askWhereCodeKept(BuildContext context, WidgetRef ref) async {
  final store = ref.read(onboardingStoreProvider);
  final current = await store.setting(codeKeptKey);
  if (!context.mounted) return;
  final choice = await showDialog<String>(
    context: context,
    builder: (dialog) => SimpleDialog(
      title: const Text('Where did you keep your code?'),
      children: [
        for (final c in codeKeptChoices)
          ListTile(
            title: Text(c),
            trailing: c == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(dialog, c),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            'Only this note is saved on the phone, never the code itself.',
            style: TextStyle(color: onboardMuted, fontSize: 12.5),
          ),
        ),
      ],
    ),
  );
  if (choice == null) return;
  await store.putSetting(codeKeptKey, choice);
  ref.invalidate(codeKeptProvider);
}

/// Replaces the recovery code, after saying what that means.
Future<void> makeNewRecoveryCode(BuildContext context, WidgetRef ref) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Make a new recovery code?'),
      content: const Text(
        'The new code opens every backup you make from now on. Backups you made before still need the old code. '
        'After this, back up again so your newest records can be opened with the new code.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Make a new code')),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const RecoveryFlowScreen()),
  );
  if (done == true) {
    final store = ref.read(onboardingStoreProvider);
    await store.putSetting(codeKeptKey, null);
    ref.invalidate(codeKeptProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New code saved. Back up now so it covers your newest records.')),
      );
    }
  }
}

class _Case {
  const _Case(this.title, this.body, this.outcome, this.tone, {this.steps = const [], this.extra, this.extraTone, this.button});
  final String title;
  final String body;
  final String outcome;
  final _Tone tone;
  final List<String> steps;
  final String? extra;
  final _Tone? extraTone;
  final _Button? button;
}

enum _Tone { good, partial, bad }

enum _Button { newCode, restore }

const _groups = <(String, List<_Case>)>[
  (
    'I still have my phone',
    [
      _Case(
        'I forgot my recovery code',
        'The phone still holds your records, so nothing is lost yet. Make a new code now, then back up again, before anything else goes wrong.',
        'Everything stays',
        _Tone.good,
        steps: ['Make a new code below and write it on paper.', 'Back up now.'],
        button: _Button.newCode,
      ),
      _Case(
        'The app was deleted or reset',
        'Install Amrutham again, tap "I already have a vault" on the first screen, pick where your backup is, and type your recovery code.',
        'Everything comes back from your last backup',
        _Tone.good,
        button: _Button.restore,
      ),
    ],
  ),
  (
    'I have a new phone',
    [
      _Case(
        'I have my recovery code and my backup',
        '',
        'Everything comes back',
        _Tone.good,
        steps: [
          'Install Amrutham and tap "I already have a vault".',
          'Sign in to the same Google account, or choose the folder.',
          'Type your recovery code.',
        ],
      ),
      _Case(
        'I have my backup but lost my code',
        'The backup is locked, and nobody can open it without the code, including us. Try these first:',
        'Cannot be opened without the code',
        _Tone.bad,
        steps: [
          'Look where you wrote it. "Where did you keep your code?" in Backup and recovery may remind you, if the old phone still turns on.',
          'Ask the family member who may hold a copy.',
          'Look for an old printout or a note in your password manager.',
        ],
        extra:
            'Your documents may still be readable. Photos and PDFs saved to a folder backup are ordinary files. Open the Amrutham folder in your files app.',
        extraTone: _Tone.partial,
      ),
    ],
  ),
  (
    'The worst cases',
    [
      _Case(
        'I lost the phone, and I never backed up',
        'There is no copy anywhere, because we never hold your data. What can still help: printed emergency cards, a doctor\'s or hospital\'s own records, and old shared exports in your messages or email.',
        'Cannot be restored',
        _Tone.bad,
      ),
      _Case(
        'I lost the phone and the code',
        'Your Drive or folder backup is still there, but locked. Follow "I have my backup but lost my code" above. If the code is truly gone, start fresh and ask clinics for copies of key records.',
        'Backup stays locked',
        _Tone.bad,
      ),
    ],
  ),
];

/// Frame 16c: pick what happened; each case says plainly what comes back and
/// what does not.
class RecoveryCasesScreen extends ConsumerWidget {
  const RecoveryCasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color bg(_Tone t) => switch (t) {
      _Tone.good => const Color(0xFFDDF0E5),
      _Tone.partial => const Color(0xFFFBEFD2),
      _Tone.bad => const Color(0xFFF7DDDA),
    };
    Color fg(_Tone t) => switch (t) {
      _Tone.good => const Color(0xFF1C6A47),
      _Tone.partial => const Color(0xFF6B4A00),
      _Tone.bad => const Color(0xFF8A2A22),
    };
    Widget tag(String text, _Tone t) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bg(t), borderRadius: BorderRadius.circular(10)),
          child: Text(text, style: TextStyle(color: fg(t), fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Getting your records back',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick what happened. Each case says plainly what you can get back, and what you cannot.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          for (final (label, cases) in _groups) ...[
            SectionLabel(label),
            for (final c in cases)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      if (c.body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(c.body, style: const TextStyle(height: 1.45)),
                      ],
                      for (var i = 0; i < c.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('${i + 1}. ${c.steps[i]}', style: const TextStyle(height: 1.45)),
                        ),
                      tag(c.outcome, c.tone),
                      if (c.extra != null) ...[
                        const SizedBox(height: 10),
                        Text(c.extra!, style: const TextStyle(height: 1.45)),
                        tag('Documents only, no medicines or history', c.extraTone!),
                      ],
                      if (c.button != null) ...[
                        const SizedBox(height: 12),
                        switch (c.button!) {
                          _Button.newCode => FilledButton(
                            onPressed: () => makeNewRecoveryCode(context, ref),
                            child: const Text('Make a new code'),
                          ),
                          _Button.restore => OutlinedButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RestoreVaultScreen(replacing: true)),
                            ),
                            child: const Text('Restore from a backup'),
                          ),
                        },
                      ],
                    ],
                  ),
                ),
              ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFBEFD2), borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'Prevent the worst case: use two backup places, write the code on paper, and keep the phone backed up.',
              style: TextStyle(color: Color(0xFF4A3300), height: 1.45, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

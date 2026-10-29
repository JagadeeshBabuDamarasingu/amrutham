import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../crypto/recovery_code.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

/// Makes sure a recovery code exists before the first record is saved
/// (specs/phase-1-v1/01-features.md F5). Returns true when it is set up —
/// already, or just now — and false if the user backed out.
Future<bool> ensureRecoverySetUp(BuildContext context, WidgetRef ref) async {
  if (await ref.read(recoverySetProvider.future)) return true;
  if (!context.mounted) return false;
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const RecoveryFlowScreen()),
  );
  return done ?? false;
}

/// Three steps in one screen: notice → code → confirm you wrote it down.
class RecoveryFlowScreen extends ConsumerStatefulWidget {
  /// [code] is only for tests; the app always generates a fresh one.
  const RecoveryFlowScreen({super.key, this.code});

  final RecoveryCode? code;

  @override
  ConsumerState<RecoveryFlowScreen> createState() => _RecoveryFlowScreenState();
}

class _RecoveryFlowScreenState extends ConsumerState<RecoveryFlowScreen> {
  late final RecoveryCode _code = widget.code ?? RecoveryCode.generate();
  // Two distinct groups to re-type, chosen once per flow.
  late final List<int> _checkParts = (List.generate(
    RecoveryCode.groupCount,
    (i) => i,
  )..shuffle(Random.secure())).take(2).toList()..sort();
  final _inputs = [TextEditingController(), TextEditingController()];
  int _step = 0;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _inputs) {
      c.dispose();
    }
    super.dispose();
  }

  bool _matches(int i) =>
      _inputs[i].text.trim().toUpperCase() == _code.groups[_checkParts[i]];

  Future<void> _finish() async {
    setState(() => _saving = true);
    final record = await RecoveryRecord.create(_code);
    await ref.read(onboardingStoreProvider).saveRecovery(record);
    ref.invalidate(recoverySetProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: onboardBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Progress(step: _step),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (_step) {
                      0 => const _NoticeStep(),
                      1 => _CodeStep(code: _code),
                      _ => _ConfirmStep(
                        parts: _checkParts,
                        inputs: _inputs,
                        onChanged: () => setState(() {}),
                        onShowAgain: () => setState(() => _step = 1),
                      ),
                    },
                  ),
                ),
                if (_saving)
                  const Center(child: CircularProgressIndicator())
                else
                  OnboardButton(
                    label: switch (_step) {
                      0 => 'I understand',
                      1 => "I've saved it",
                      _ => 'Continue',
                    },
                    onPressed: _step == 2 && !(_matches(0) && _matches(1))
                        ? null
                        : () => _step == 2
                              ? _finish()
                              : setState(() => _step++),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? onboardInk : const Color(0xFFD9E2DD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

const _titleStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.8,
  height: 1.1,
  color: Color(0xFF16211C),
);
const _bodyStyle = TextStyle(fontSize: 16, height: 1.4, color: onboardMuted);

class _NoticeStep extends StatelessWidget {
  const _NoticeStep();

  @override
  Widget build(BuildContext context) {
    const points = [
      ('It stays on your phone', 'No account, no analytics, no server of ours.'),
      (
        'Your records are plain files',
        'You can open them without this app, any time.',
      ),
      (
        'No tracking, ever',
        'Nothing about you or your family is sent to us.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Before we start', style: _titleStyle),
        const SizedBox(height: 6),
        const Text('Three things, plainly.', style: _bodyStyle),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final (title, body) in points)
                  ListTile(
                    leading: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFD5E4DC),
                      child: Icon(Icons.check, size: 16, color: onboardInk),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(body),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEFD0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: onboardAmber,
                child: Text('!', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'There is no "forgot password"\n',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D2E00),
                        ),
                      ),
                      TextSpan(
                        text:
                            'If you lose this phone and your recovery code, '
                            'nobody can open your records. Not even us. '
                            'Next, we make that code.',
                        style: TextStyle(color: Color(0xFF5A4300)),
                      ),
                    ],
                  ),
                  style: TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({required this.code});

  final RecoveryCode code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your recovery code', style: _titleStyle),
        const SizedBox(height: 8),
        const Text(
          'Made on this phone just now. It opens your vault on a new phone. '
          "We can't show it again.",
          style: _bodyStyle,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              for (var i = 0; i < code.groups.length; i++)
                Container(
                  decoration: BoxDecoration(
                    color: onboardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 11, color: onboardMuted),
                      ),
                      Text(
                        code.groups[i],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                // Opens the OS share sheet: save to Files, print, or send to a
                // password manager — without this app needing storage rights.
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    subject: 'Amrutham recovery code',
                    text:
                        'Amrutham recovery code: ${code.formatted}\n\n'
                        'Keep this somewhere that is not this phone.',
                  ),
                ),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Save or print'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code.formatted));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Keep it somewhere that is not this phone. Anyone with this code '
          "and your vault files can read your records, so don't post or "
          'message it.',
          style: TextStyle(fontSize: 13, height: 1.4, color: onboardMuted),
        ),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({
    required this.parts,
    required this.inputs,
    required this.onChanged,
    required this.onShowAgain,
  });

  final List<int> parts;
  final List<TextEditingController> inputs;
  final VoidCallback onChanged;
  final VoidCallback onShowAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Check you wrote it down', style: _titleStyle),
        const SizedBox(height: 8),
        const Text(
          "Type two parts of the code from your copy, not from this phone's "
          'screen.',
          style: _bodyStyle,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 2; i++) ...[
          Text(
            'PART ${parts[i] + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: onboardMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: inputs[i],
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.characters,
            maxLength: RecoveryCode.groupLength,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextButton(
          onPressed: onShowAgain,
          child: const Text('‹ Show the code again'),
        ),
        const Text(
          'This only checks what you typed against the code on this phone. '
          'Nothing is sent anywhere.',
          style: TextStyle(fontSize: 13, height: 1.4, color: onboardMuted),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guide/setup_progress.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'guide_screens.dart';

/// Frame 1: "Finish setting up" above the tab bar until the five steps are
/// done or it is closed. The daily tip takes its place after.
bool showSetupCard(WidgetRef ref) {
  final steps = ref.watch(setupStepsProvider);
  final hidden = ref.watch(setupHiddenProvider).valueOrNull ?? true;
  return !hidden && steps.any((s) => !s.done);
}

class SetupCard extends ConsumerWidget {
  const SetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(setupStepsProvider);
    final done = steps.where((s) => s.done).length;
    final next = steps.firstWhere((s) => !s.done, orElse: () => steps.last);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UsingAmruthamScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'FINISH SETTING UP · $done OF ${steps.length}',
                    style: const TextStyle(color: Color(0xFF9FC0B2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ),
                IconButton(
                  tooltip: 'Hide',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF9FC0B2)),
                  onPressed: () async {
                    await ref.read(onboardingStoreProvider).putSetting(setupHiddenKey, '1');
                    ref.invalidate(setupHiddenProvider);
                  },
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: done / steps.length,
                minHeight: 5,
                backgroundColor: const Color(0xFF2C5245),
                color: onboardAmber,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(next.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, color: onboardAmber),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

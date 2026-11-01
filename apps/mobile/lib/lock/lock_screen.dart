import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import '../quick_access/emergency_snapshot.dart' show shortBlood;
import '../ui/app_style.dart';
import '../ui/emergency_card_screen.dart';
import 'lock_controller.dart';

const _pine = Color(0xFF17302A);

/// Everything shown while the app is locked: the lock screen, and the emergency
/// card, which anyone may open. It is one route over the whole app with a small
/// navigator of its own, so Back works inside it and never reaches the screens
/// underneath.
class LockHost extends ConsumerStatefulWidget {
  const LockHost({super.key});

  @override
  ConsumerState<LockHost> createState() => _LockHostState();
}

/// The lock's own navigator (the emergency card opens inside it).
final lockNavigator = GlobalKey<NavigatorState>();

class _LockHostState extends ConsumerState<LockHost> {
  final _nested = lockNavigator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequestedCard(ref.read(lockProvider)));
  }

  /// A widget or shortcut asked for a card while locked: show it straight away.
  void _openRequestedCard(AppLockState state) {
    final id = state.cardFor;
    if (id == null || !mounted) return;
    ref.read(lockProvider.notifier).cardShown();
    _nested.currentState?.push(MaterialPageRoute(builder: (_) => LockedEmergencyCard(personId: id)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lockProvider, (_, next) => _openRequestedCard(next));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _nested.currentState?.maybePop();
      },
      // Beside the app's navigator now, so it must not share its hero controller.
      child: HeroControllerScope.none(
        child: Navigator(
          key: _nested,
          onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const LockScreen()),
        ),
      ),
    );
  }
}

/// Frames 14a and 14f.
class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(lockProvider);
    final living = [
      for (final p in ref.watch(profilesProvider).valueOrNull ?? const <PersonProfile>[])
        if (!p.isDeceased) p,
    ];
    final failed = lock.failed;
    return Scaffold(
      backgroundColor: _pine,
      body: SafeArea(
        // Scrollable, and as tall as the screen when there is room: the lock
        // screen must never be cut off at large text on a small phone.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Icon(failed ? Icons.lock_outline : Icons.favorite_border, size: 28, color: onboardAmber),
              ),
              const SizedBox(height: 12),
              const Text(
                'AMRUTHAM',
                style: TextStyle(color: Color(0xFF9FC0B2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                failed ? 'Not unlocked' : 'Amrutham is locked',
                style: const TextStyle(
                  fontFamily: headingFont,
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                failed
                    ? "That didn't work, or you cancelled. Nothing was opened."
                    : "Open it with your phone's fingerprint, face or screen lock.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCFE0D8), fontSize: 16, height: 1.5),
              ),
              const Spacer(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: onboardAmber,
                    foregroundColor: const Color(0xFF2A1D00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => ref.read(lockProvider.notifier).unlock(),
                  icon: const Icon(Icons.fingerprint, size: 26),
                  label: Text(failed ? 'Try again' : 'Unlock'),
                ),
              ),
              if (living.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'IN AN EMERGENCY',
                        style: TextStyle(color: Color(0xFF9FC0B2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                  ],
                ),
                const SizedBox(height: 12),
                _EmergencySummary(people: [for (final p in living) p], failed: failed),
              ],
              const SizedBox(height: 22),
              Text(
                failed
                    ? 'Too many wrong tries? Your phone will make you wait before it asks again. That is your phone, not Amrutham.'
                    : 'Your records stay on this phone, encrypted, whether the lock is on or not. The lock keeps other people out of the app.',
                style: const TextStyle(color: Color(0xFF9FC0B2), fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 16),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frame 14b: the emergency card with a banner and the family's chips, and none
/// of Print, Save PDF or Share until the app is unlocked.
class LockedEmergencyCard extends ConsumerStatefulWidget {
  const LockedEmergencyCard({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<LockedEmergencyCard> createState() => _LockedEmergencyCardState();
}

class _LockedEmergencyCardState extends ConsumerState<LockedEmergencyCard> {
  late PersonId _id = widget.personId;

  @override
  Widget build(BuildContext context) {
    final living = [
      for (final p in ref.watch(profilesProvider).valueOrNull ?? const <PersonProfile>[])
        if (!p.isDeceased) p,
    ];
    return Scaffold(
      backgroundColor: onboardBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
              decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Amrutham is locked. ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: 'Only this card is open.'),
                        ],
                      ),
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: onboardAmber,
                      foregroundColor: const Color(0xFF2A1D00),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => ref.read(lockProvider.notifier).unlock(),
                    child: const Text('Unlock'),
                  ),
                ],
              ),
            ),
            if (living.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final p in living)
                        ChoiceChip(
                          label: Text(p.displayName),
                          selected: p.id == _id,
                          onSelected: (_) => setState(() => _id = p.id),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(child: EmergencyCardScreen(key: ValueKey(_id), personId: _id, locked: true)),
          ],
        ),
      ),
    );
  }
}

/// The emergency details right on the lock screen: blood group, allergies,
/// medicines and who to call, for whoever needs them without unlocking. Tap
/// for the full card. With several people, pick whose.
class _EmergencySummary extends ConsumerStatefulWidget {
  const _EmergencySummary({required this.people, required this.failed});

  final List<PersonProfile> people;
  final bool failed;

  @override
  ConsumerState<_EmergencySummary> createState() => _EmergencySummaryState();
}

class _EmergencySummaryState extends ConsumerState<_EmergencySummary> {
  PersonId? _picked;

  @override
  Widget build(BuildContext context) {
    final person = widget.people.where((p) => p.id == _picked).firstOrNull ?? widget.people.first;
    final allergies = ref.watch(allergiesProvider(person.id)).valueOrNull ?? [];
    final medicines = EmergencyCardScreen.distinctMedicines(
      ref.watch(activeCoursesProvider(person.id)).valueOrNull ?? [],
    );
    const muted = TextStyle(color: Color(0xFF9FC0B2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1);
    const body = TextStyle(color: Colors.white, fontSize: 15, height: 1.4);
    Widget block(String label, List<String> lines) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: muted),
          const SizedBox(height: 3),
          for (final l in lines) Text(l, style: body),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.people.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              children: [
                for (final p in widget.people)
                  ChoiceChip(
                    label: Text(p.displayName),
                    selected: p.id == person.id,
                    onSelected: (_) => setState(() => _picked = p.id),
                  ),
              ],
            ),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LockedEmergencyCard(personId: person.id)),
          ),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: onboardAmber, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Blood ${shortBlood(person.bloodGroup)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2A1D00)),
                      ),
                    ),
                  ],
                ),
                block('ALLERGIES', allergies.isEmpty ? ['None recorded'] : [for (final a in allergies) EmergencyCardScreen.allergyLine(a)]),
                block('CALL', person.emergencyContacts.isEmpty
                    ? ['No contacts added']
                    : [for (final c in person.emergencyContacts) '${c.name}${c.relationship == null ? '' : ' (${c.relationship})'}  ${c.phone}']),
                block('TAKING NOW', medicines.isEmpty ? ['No active medicines'] : [for (final m in medicines) m.medicationName]),
                const SizedBox(height: 10),
                Text(
                  widget.failed ? 'Open for anyone who needs it. Tap for the full card.' : 'Anyone can see this. Tap for the full card.',
                  style: const TextStyle(color: Color(0xFFBBD3C8), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

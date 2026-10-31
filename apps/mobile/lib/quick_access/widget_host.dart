import 'dart:async';

import 'package:amrutham_widgets/amrutham_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/medication.dart';
import '../providers/app_providers.dart';
import '../ui/emergency_card_screen.dart';
import 'emergency_snapshot.dart';

/// Keeps the home screen cards in step with the app, and opens the emergency
/// card when one is tapped. It copies to the widgets only while the person has
/// switched them on, and wipes the copy the moment they switch them off.
class WidgetSyncHost extends ConsumerStatefulWidget {
  const WidgetSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetSyncHost> createState() => _State();
}

class _State extends ConsumerState<WidgetSyncHost> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    AmruthamWidgets.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _sync();
      final action = await AmruthamWidgets.initialAction();
      if (action != null) _open(action);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _open(Map<String, String> action) {
    final person = action['personId'];
    if (!mounted || action['action'] != 'emergency' || person == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmergencyCardScreen(personId: PersonId(person))),
    );
  }

  /// Several changes arrive together (a restore, a profile save): copy once.
  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _sync);
  }

  Future<void> _sync() async {
    final settings = await ref.read(widgetSettingsProvider.future);
    if (!settings.enabled) {
      await AmruthamWidgets.sync(enabled: false, people: const [], snapshots: const {});
      return;
    }
    final people = (await ref.read(profilesProvider.future)).where((p) => !p.isDeceased).toList();
    final snapshots = <String, String>{};
    for (final p in people) {
      final allergies = await ref.read(allergiesProvider(p.id).future);
      final courses = await ref.read(medicationCoursesProvider(p.id).future);
      snapshots[p.id.value] = EmergencySnapshot.build(
        person: p,
        allergies: allergies,
        medicines: [for (final c in courses) if (c.status == CourseStatus.active) c],
        options: settings.optionsFor(p.id.value),
      );
    }
    await AmruthamWidgets.sync(
      enabled: true,
      people: [for (final p in people) (id: p.id.value, name: p.displayName)],
      snapshots: snapshots,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(widgetSettingsProvider, (_, _) => _schedule());
    ref.listen(profilesProvider, (_, _) => _schedule());
    for (final p in ref.watch(profilesProvider).valueOrNull ?? const []) {
      ref.listen(allergiesProvider(p.id), (_, _) => _schedule());
      ref.listen(medicationCoursesProvider(p.id), (_, _) => _schedule());
    }
    return widget.child;
  }
}

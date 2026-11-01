import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'guide_content.dart';

class SetupStep {
  const SetupStep(this.label, this.done, this.guide);
  final String label;
  final bool done;
  final Guide guide;
}

/// The five things that make the app useful and safe, and which are done.
final setupStepsProvider = Provider<List<SetupStep>>((ref) {
  final people = ref.watch(profilesProvider).valueOrNull ?? [];
  final recovery = ref.watch(recoverySetProvider).valueOrNull ?? false;
  final drive = ref.watch(driveStatusProvider).valueOrNull;
  final folder = ref.watch(backupFolderProvider).valueOrNull;
  final cards = ref.watch(widgetSettingsProvider).valueOrNull?.enabled ?? false;
  return [
    SetupStep('Add a person', people.isNotEmpty, familyGuide),
    SetupStep('Add an emergency contact', people.any((p) => p.emergencyContacts.isNotEmpty), emergencyGuide),
    SetupStep('Save your recovery code', recovery, backupGuide),
    SetupStep('Back up your records', drive?.$2 != null || folder != null, backupGuide),
    SetupStep('Set up an emergency card', cards, emergencyGuide),
  ];
});

const setupHiddenKey = 'setup_card_hidden';

final setupHiddenProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(onboardingStoreProvider).setting(setupHiddenKey) == '1',
);

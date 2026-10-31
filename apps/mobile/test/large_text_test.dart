// The audit asked for a check at 130% system text on a narrow phone. This opens
// the main screens like that and fails on any overflow (a Flutter test reports a
// RenderFlex overflow as an exception).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/learn/learn_content.dart';
import 'package:amrutham/lock/device_auth.dart';
import 'package:amrutham/lock/lock_controller.dart';
import 'package:amrutham/lock/lock_screen.dart';
import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/model/health_record.dart';
import 'package:amrutham/model/measurement.dart';
import 'package:amrutham/ui/add_allergy_screen.dart';
import 'package:amrutham/ui/add_care_provider_screen.dart';
import 'package:amrutham/ui/add_expense_screen.dart';
import 'package:amrutham/ui/add_family_history_screen.dart';
import 'package:amrutham/ui/add_history_event_screen.dart';
import 'package:amrutham/ui/add_medication_course_screen.dart';
import 'package:amrutham/ui/app_lock_screen.dart';
import 'package:amrutham/ui/care_team_screen.dart';
import 'package:amrutham/ui/create_profile_screen.dart';
import 'package:amrutham/ui/family_screen.dart';
import 'package:amrutham/ui/history_screen.dart';
import 'package:amrutham/ui/log_measurement_screen.dart';
import 'package:amrutham/ui/metrics_screen.dart';
import 'package:amrutham/ui/care_provider_detail_screen.dart';
import 'package:amrutham/ui/emergency_card_screen.dart';
import 'package:amrutham/ui/expenses_screen.dart';
import 'package:amrutham/ui/learn_screen.dart';
import 'package:amrutham/ui/today_screen.dart';
import 'package:amrutham/ui/widgets_settings_screen.dart';

import 'lock_fakes.dart';
import 'memory_onboarding_store.dart';

final _person = PersonProfile(
  id: const PersonId('appa'),
  displayName: 'Venkata Subrahmanyam Reddy',
  givenName: 'Venkata Subrahmanyam',
  surname: 'Reddy',
  relationship: RelationshipType.self,
  bloodGroup: 'O positive',
  emergencyContacts: const [EmergencyContact(name: 'Anita Reddy', phone: '+91 98765 43210', relationship: 'daughter')],
  createdAt: DateTime(2025),
);

final _doctor = CareProvider(
  id: const CareProviderId('rao'),
  kind: CareKind.doctor,
  name: 'Dr. Subrahmanyam Rao',
  specialty: 'Orthopaedic and joint replacement surgeon',
  worksAt: 'Apollo Hospitals, Jubilee Hills',
  phone: '+91 98765 43210',
  location: 'Road No. 72, Jubilee Hills, Hyderabad 500033',
  personIds: const [PersonId('appa')],
  isCurrent: true,
);

Future<void> _open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(320 * 3, 640 * 3); // a small phone
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore()),
        deviceAuthProvider.overrideWithValue(FakeDeviceAuth()),
        profilesProvider.overrideWith((ref) => Stream.value([_person])),
        allergiesProvider.overrideWith((ref, id) => Stream.value(const [])),
        medicationCoursesProvider.overrideWith((ref, id) => Stream.value(const <MedicationCourse>[])),
        historyEventsProvider.overrideWith((ref, id) => Stream.value(const [])),
        expensesProvider.overrideWith((ref) => Stream.value(const <Expense>[])),
        careProvidersAllProvider.overrideWith((ref) => Stream.value([_doctor])),
        careTeamProvider.overrideWith((ref, id) => Stream.value([_doctor])),
        measurementsProvider.overrideWith((ref, id) => Stream.value(const <Measurement>[])),
        familyHistoryProvider.overrideWith((ref, id) => Stream.value(const [])),
        recordsProvider.overrideWith((ref) => Stream.value(const <HealthRecord>[])),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final screens = <String, Widget Function()>{
    'Today': () => const Scaffold(body: TodayScreen()),
    'Learn': () => const Scaffold(body: LearnScreen()),
    'Heritage hub': () => const HubScreen(hub: LearnHub.heritage),
    'Mental wellbeing hub': () => const HubScreen(hub: LearnHub.mentalWellbeing),
    'A heritage guide': () => GuideScreen(guide: allGuides.firstWhere((g) => g.id == 'research-says')),
    'The longest tabbed guide': () => GuideScreen(guide: allGuides.firstWhere((g) => g.id == 'thoughts-of-ending-life')),
    'Emergency card': () => const EmergencyCardScreen(personId: PersonId('appa')),
    'Locked emergency card': () => const LockedEmergencyCard(personId: PersonId('appa')),
    'Lock screen': () => const LockScreen(),
    'App lock settings': () => const AppLockScreen(),
    'Widget settings': () => const WidgetsSettingsScreen(),
    'Doctor page': () => const CareProviderDetailScreen(providerId: CareProviderId('rao'), personId: PersonId('appa')),
    'Year of expenses': () => const YearViewScreen(),
    'Family': () => const Scaffold(body: FamilyScreen()),
    'Care team': () => const CareTeamScreen(personId: PersonId('appa')),
    'Metrics': () => const MetricsScreen(personId: PersonId('appa')),
    'History': () => const HistoryScreen(personId: PersonId('appa')),
    'Add a person': () => const CreateProfileScreen(),
    'Add an expense': () => const AddExpenseScreen(personId: PersonId('appa')),
    'Log a reading': () => const LogMeasurementScreen(personId: PersonId('appa')),
    'Add an allergy': () => const AddAllergyScreen(personId: PersonId('appa')),
    'Add family history': () => const AddFamilyHistoryScreen(personId: PersonId('appa')),
    'Add a history entry': () => const AddHistoryEventScreen(personId: PersonId('appa')),
    'Add a medicine': () => const AddMedicationCourseScreen(personId: PersonId('appa')),
    'Add a doctor': () => const AddCareProviderScreen(personId: PersonId('appa')),
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits at 130% text on a small phone', (tester) async {
      await _open(tester, entry.value());
      expect(tester.takeException(), isNull);
    });
  }
}

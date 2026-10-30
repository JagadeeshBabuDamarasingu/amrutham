import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/db/realm_schemas.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/repository/care_team_repository.dart';
import 'package:amrutham/ui/add_care_provider_screen.dart';
import 'package:amrutham/ui/care_provider_picker_screen.dart';
import 'package:amrutham/ui/care_team_screen.dart';

import 'package:realm/realm.dart';

import 'realm_test_helper.dart';

const _appa = PersonId('appa');
const _amma = PersonId('amma');

PersonProfile _person(PersonId id, String given) => PersonProfile(
  id: id,
  displayName: '$given Reddy',
  givenName: given,
  relationship: RelationshipType.parent,
  createdAt: DateTime(2026),
);

/// Assertions read the Realm directly: its change streams only deliver on
/// real time, which the test's fake clock never gives.
class _Db {
  _Db(this.realm);
  final Realm realm;

  List<CareProviderRow> get rows => realm.all<CareProviderRow>().toList();
  CareProviderRow row(String name) => rows.firstWhere((r) => r.name == name);
  List<String> teamOf(PersonId id) =>
      (rows.where((r) => r.personIds.contains(id.value)).map((r) => r.name).toList()..sort());
}

/// The screens read through providers; the repository is real, the lists the
/// screens watch are handed over directly.
Future<_Db> _pump(WidgetTester tester, Widget Function(List<CareProvider> all) home) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final realm = openInMemoryRealm();
  addTearDown(realm.close);
  final repo = CareTeamRepository(realm);
  final apollo = await repo.add(kind: CareKind.facility, name: 'Apollo Hospitals', personIds: [_appa, _amma]);
  final rao = await repo.add(
    kind: CareKind.doctor,
    name: 'Dr. S. Rao',
    specialty: 'Cardiologist',
    phone: '98480 55012',
    personIds: [_appa],
  );
  final all = [apollo, rao];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        careTeamRepositoryProvider.overrideWith((ref) async => repo),
        careProvidersAllProvider.overrideWith((ref) => Stream.value(all)),
        careTeamProvider.overrideWith(
          (ref, id) => Stream.value([for (final p in all) if (p.personIds.contains(id)) p]),
        ),
        profilesProvider.overrideWith(
          (ref) => Stream.value([_person(_appa, 'Appa'), _person(_amma, 'Amma')]),
        ),
      ],
      child: MaterialApp(home: home(all)),
    ),
  );
  await tester.pumpAndSettle();
  return _Db(realm);
}

void main() {
  testWidgets('the picker offers only doctors not already on this care team', (tester) async {
    final db = await _pump(tester, (_) => const CareProviderPickerScreen(personId: _amma));

    expect(find.text('Dr. S. Rao'), findsOneWidget);
    expect(find.text('Apollo Hospitals'), findsNothing); // Amma already has it
    expect(find.textContaining('Sees Appa'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(db.teamOf(_amma), ['Apollo Hospitals', 'Dr. S. Rao']);
    expect(db.rows, hasLength(2)); // linked, not copied
  });

  testWidgets('typing a saved doctor offers to use them, and Use saved links', (tester) async {
    final db = await _pump(tester, (_) => const AddCareProviderScreen(personId: _amma));

    await tester.enterText(find.byType(TextField).first, 'dr s rao');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. S. Rao is already saved'), findsOneWidget);
    await tester.tap(find.text('Use saved'));
    await tester.pumpAndSettle();

    expect(db.rows, hasLength(2)); // no second copy
    expect(db.teamOf(_amma), contains('Dr. S. Rao'));
  });

  testWidgets('Add anyway still creates a second entry', (tester) async {
    final db = await _pump(tester, (_) => const AddCareProviderScreen(personId: _amma));

    await tester.enterText(find.byType(TextField).first, 'Dr S Rao');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add anyway'));
    await tester.pumpAndSettle();

    expect(db.rows, hasLength(3));
  });

  testWidgets('Cancel on the warning saves nothing', (tester) async {
    final db = await _pump(tester, (_) => const AddCareProviderScreen(personId: _amma));

    await tester.enterText(find.byType(TextField).first, 'Dr S Rao');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(db.rows, hasLength(2));
  });

  testWidgets('a new name saves without any warning', (tester) async {
    final db = await _pump(tester, (_) => const AddCareProviderScreen(personId: _amma));

    await tester.enterText(find.byType(TextField).first, 'Dr. Meena Kumar');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already saved'), findsNothing);
    expect(db.rows, hasLength(3));
  });

  testWidgets('editing is prefilled, and saves the changed fields', (tester) async {
    final db = await _pump(
      tester,
      (all) => AddCareProviderScreen(
        personId: _appa,
        editing: all.firstWhere((p) => p.name == 'Dr. S. Rao'),
      ),
    );

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Dr. S. Rao'), findsOneWidget); // prefilled name
    expect(find.text('Cardiologist'), findsOneWidget);
    expect(find.text('98480 55012'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Cardiologist'), 'Heart specialist');
    await tester.enterText(find.widgetWithText(TextField, '98480 55012'), '');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already saved'), findsNothing); // never matches itself
    final saved = db.row('Dr. S. Rao');
    expect(saved.specialty, 'Heart specialist');
    expect(saved.phone, isNull);
  });

  testWidgets('a shared doctor shows who else they see, and Remove only unlinks', (tester) async {
    final db = await _pump(tester, (_) => const CareTeamScreen(personId: _amma));

    expect(find.text('Also sees Appa'), findsOneWidget);
    await tester.tap(find.text('Apollo Hospitals'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsOneWidget);

    await tester.tap(find.text('Remove from this care team'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(db.teamOf(_amma), isEmpty);
    expect(db.teamOf(_appa), contains('Apollo Hospitals'));
  });

  testWidgets('an unshared doctor offers Delete, not Delete for everyone', (tester) async {
    await _pump(tester, (_) => const CareTeamScreen(personId: _appa));

    await tester.tap(find.text('Dr. S. Rao'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Delete for everyone'), findsNothing);
  });
}

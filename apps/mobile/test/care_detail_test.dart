// A doctor's or hospital's page: contact buttons only when there is something
// to contact, links between a doctor and where they work, and visits and
// spending matched by name from the history and the expenses.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/care_provider_detail_screen.dart';

const _appa = PersonId('appa');
const _amma = PersonId('amma');

CareProvider _doctor({String? phone = '+91 98765 43210', List<PersonId> people = const [_appa]}) => CareProvider(
  id: const CareProviderId('rao'),
  kind: CareKind.doctor,
  name: 'Dr. S. Rao',
  specialty: 'Orthopaedic surgeon',
  worksAt: 'Apollo Hospitals',
  phone: phone,
  location: 'Jubilee Hills, Hyderabad',
  personIds: people,
  isCurrent: true,
);

final _hospital = CareProvider(
  id: const CareProviderId('apollo'),
  kind: CareKind.facility,
  name: 'Apollo Hospitals',
  personIds: const [_appa],
  isCurrent: true,
);

HistoryEvent _visit(String id, PersonId who, DateTime on, {String? provider = 'S Rao', String title = 'Review'}) => HistoryEvent(
  id: HistoryEventId(id),
  personId: who,
  kind: HistoryKind.visit,
  title: title,
  eventDate: on,
  provider: provider,
);

Expense _spend(String id, PersonId who, int paise, DateTime on, {String? payee = 'dr s. rao'}) => Expense(
  id: ExpenseId(id),
  personId: who,
  title: 'Consultation',
  payee: payee,
  amountPaise: paise,
  category: ExpenseCategory.consultation,
  spentOn: on,
  addedAt: on,
);

void main() {
  final now = DateTime(2026, 11, 1);

  group('summarizeCare', () {
    test('finds the last and next visit and this year\'s spending, matching the name loosely', () {
      final s = summarizeCare(
        _doctor(),
        [
          _visit('1', _appa, DateTime(2026, 3, 1)),
          _visit('2', _appa, DateTime(2026, 10, 28)),
          _visit('3', _appa, DateTime(2026, 12, 5), title: 'Knee review'),
          _visit('4', _appa, DateTime(2026, 12, 20)),
          _visit('5', _appa, DateTime(2026, 9, 1), provider: 'Dr. Someone Else'),
          _visit('6', _appa, DateTime(2026, 9, 2), provider: null),
        ],
        [
          _spend('a', _appa, 620000, DateTime(2026, 4, 2)),
          _spend('b', _appa, 100000, DateTime(2025, 12, 31)), // last year
          _spend('c', _appa, 50000, DateTime(2026, 6, 1), payee: 'Pharmacy'),
        ],
        now,
      );
      expect(s.lastVisit!.eventDate, DateTime(2026, 10, 28));
      expect(s.nextVisit!.title, 'Knee review');
      expect(s.visits, 2);
      expect(s.spentThisYear, 620000);
    });

    test('only counts the people the doctor is shared with', () {
      final s = summarizeCare(
        _doctor(),
        [_visit('1', _amma, DateTime(2026, 10, 1))],
        [_spend('a', _amma, 99900, DateTime(2026, 4, 2))],
        now,
      );
      expect((s.lastVisit, s.nextVisit, s.visits, s.spentThisYear), (null, null, 0, 0));
      final shared = summarizeCare(_doctor(people: const [_appa, _amma]), [_visit('1', _amma, DateTime(2026, 10, 1))], const [], now);
      expect(shared.visits, 1);
    });

    test('nothing recorded is zero, not an error', () {
      final s = summarizeCare(_doctor(), const [], const [], now);
      expect((s.lastVisit, s.nextVisit, s.visits, s.spentThisYear), (null, null, 0, 0));
    });
  });

  test('the badge shows two initials, ignoring Dr.', () {
    expect(careInitials('Dr. S. Rao'), 'SR');
    expect(careInitials('Anita Iyer Rao'), 'AI');
    expect(careInitials('dr Lakshmi'), 'L');
  });

  group('the page', () {
    Future<void> pump(WidgetTester tester, CareProvider open, List<CareProvider> all) async {
      tester.view.physicalSize = const Size(400 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            careProvidersAllProvider.overrideWith((ref) => Stream.value(all)),
            profilesProvider.overrideWith(
              (ref) => Stream.value([
                PersonProfile(id: _appa, displayName: 'Appa', relationship: RelationshipType.parent, createdAt: DateTime(2025)),
              ]),
            ),
            historyEventsProvider.overrideWith(
              (ref, id) => Stream.value([_visit('1', id, DateTime.now().subtract(const Duration(days: 3)))]),
            ),
            expensesProvider.overrideWith(
              (ref) => Stream.value([_spend('a', _appa, 620000, DateTime.now())]),
            ),
          ],
          child: MaterialApp(home: CareProviderDetailScreen(providerId: open.id, personId: _appa)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a doctor shows who they are, their details, and what the app knows', (tester) async {
      await pump(tester, _doctor(), [_doctor(), _hospital]);
      expect(find.text('Dr. S. Rao'), findsOneWidget);
      expect(find.textContaining('Orthopaedic surgeon · for Appa'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Apollo Hospitals ›'), findsOneWidget);
      expect(find.text('Jubilee Hills, Hyderabad'), findsOneWidget);
      expect(find.text('Recorded visits'), findsOneWidget);
      expect(find.text('₹6,200'), findsOneWidget);
    });

    testWidgets('the workplace opens the hospital, which lists its doctors', (tester) async {
      await pump(tester, _doctor(), [_doctor(), _hospital]);
      await tester.tap(find.text('Apollo Hospitals ›'));
      await tester.pumpAndSettle();
      expect(find.text('Hospital or clinic · for Appa'), findsOneWidget);
      expect(find.text('DOCTORS HERE'), findsOneWidget);
      expect(find.text('Dr. S. Rao'), findsOneWidget);
    });

    testWidgets('without a phone number, Call and Message cannot be pressed', (tester) async {
      final d = _doctor(phone: null);
      await pump(tester, d, [d, _hospital]);
      final call = find.ancestor(of: find.text('Call'), matching: find.byType(InkWell)).first;
      expect(tester.widget<InkWell>(call).onTap, isNull);
      final directions = find.ancestor(of: find.text('Directions'), matching: find.byType(InkWell)).first;
      expect(tester.widget<InkWell>(directions).onTap, isNotNull);
    });

    testWidgets('a hospital with nothing added says so', (tester) async {
      await pump(tester, _hospital, [_hospital]);
      expect(find.textContaining('No details added yet'), findsOneWidget);
    });
  });
}

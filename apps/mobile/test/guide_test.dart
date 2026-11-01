import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/guide/guide_content.dart';
import 'package:amrutham/guide/setup_progress.dart';
import 'package:amrutham/ui/guide_screens.dart';
import 'package:amrutham/ui/setup_card.dart';

List<SetupStep> _steps(int done) => [
  for (var i = 0; i < 5; i++) SetupStep('Step ${i + 1}', i < done, emergencyGuide),
];

Future<void> _show(WidgetTester tester, Widget screen, {int done = 3, bool hidden = false}) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        setupStepsProvider.overrideWithValue(_steps(done)),
        setupHiddenProvider.overrideWith((ref) async => hidden),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Using Amrutham lists every guide and the setup progress', (tester) async {
    await _show(tester, const UsingAmruthamScreen());
    expect(find.text('3 OF 5 DONE'), findsOneWidget);
    for (final g in allGuideList) {
      expect(find.text(g.title), findsOneWidget, reason: g.title);
    }
  });

  testWidgets('a guide shows numbered steps with buttons that go somewhere', (tester) async {
    await _show(tester, GuideScreen(emergencyGuide));
    expect(find.text('Fill in the details that matter'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Open Medical info'), 200);
    expect(find.text('Open Medical info'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('6'), 200);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('the setup card shows the next step, and goes away when done or closed', (tester) async {
    await _show(
      tester,
      Consumer(builder: (context, ref, _) => Scaffold(body: showSetupCard(ref) ? const SetupCard() : const Text('tip'))),
    );
    expect(find.text('FINISH SETTING UP · 3 OF 5'), findsOneWidget);
    expect(find.text('Step 4'), findsOneWidget);
    await _show(tester, Consumer(builder: (context, ref, _) => Scaffold(body: showSetupCard(ref) ? const SetupCard() : const Text('tip'))), done: 5);
    expect(find.text('tip'), findsOneWidget);
  });

  test('every guide step with a button has an action, and no copy is country-specific', () {
    for (final g in allGuideList) {
      for (final s in g.steps) {
        expect(s.button == null, s.action == null, reason: '${g.title}: ${s.title}');
        expect('${g.intro}${s.body}', isNot(contains('India')));
      }
    }
  });
}

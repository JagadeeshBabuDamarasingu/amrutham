import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/ui/recovery_code_dialog.dart';

const _typed = 'ABCD-EFGH-JKMN-PQRS-TUVW-XYZ2';

/// Shows a page with the dialog already open.
Future<void> _open(
  WidgetTester tester,
  Future<bool> Function(RecoveryCode) verify, {
  bool closeOnMatch = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<RecoveryCode>(
              context: context,
              builder: (_) => RecoveryCodeDialog(
                verify: verify,
                title: 'Back up your vault',
                intro: 'Type your recovery code.',
                actionLabel: 'Back up',
                closeOnMatch: closeOnMatch,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a matching code closes the dialog and returns the code, with no errors', (tester) async {
    RecoveryCode? returnedCode;
    await _open(tester, (code) async {
      returnedCode = code;
      return true;
    });

    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Back up'));
    // The close animation runs here. Disposing the text field's controller
    // while it plays used to throw "used after being disposed".
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(returnedCode?.value, RecoveryCode.parse(_typed)!.value);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a code in the wrong shape is refused without checking', (tester) async {
    var checked = false;
    await _open(tester, (_) async => checked = true);

    await tester.enterText(find.byType(TextField), 'ABCD-EFGH');
    await tester.tap(find.text('Back up'));
    await tester.pumpAndSettle();

    expect(find.text('That is not 24 characters of a code.'), findsOneWidget);
    expect(checked, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('a wrong code says so and the dialog stays open', (tester) async {
    await _open(tester, (_) async => false);

    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Back up'));
    await tester.pumpAndSettle();

    expect(find.text('That does not match your recovery code.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Back up'), findsWidgets); // the button is usable again
  });

  testWidgets('cancelling while the check runs does not throw', (tester) async {
    final slow = Future<bool>.delayed(const Duration(seconds: 2), () => true);
    await _open(tester, (_) => slow);

    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Back up'));
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle(const Duration(seconds: 3)); // check finishes after close

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('check mode reports a match and stays open', (tester) async {
    await _open(tester, (_) async => true, closeOnMatch: false);

    await tester.enterText(find.byType(TextField), _typed);
    await tester.tap(find.text('Back up'));
    await tester.pumpAndSettle();

    expect(find.text('That matches your recovery code.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

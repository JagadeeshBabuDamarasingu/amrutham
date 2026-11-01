import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/about/app_info.dart';
import 'package:amrutham/ui/about_screen.dart';

Future<void> _show(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 7000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
}

void main() {
  test('the version shown is the version in pubspec.yaml', () {
    final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    expect(line.replaceFirst('version:', '').trim(), '$appVersion+$appBuild');
  });

  testWidgets('About shows the vision, the mission and the promises', (tester) async {
    await _show(tester, const AboutScreen());
    expect(find.text(aboutVision), findsOneWidget);
    expect(find.text(aboutMission), findsOneWidget);
    expect(find.text('Free, forever'), findsOneWidget);
    expect(find.text('Version $appVersion · build $appBuild'), findsOneWidget);
    expect(find.textContaining('India'), findsNothing, reason: 'for everyone, not one country');
  });

  testWidgets('About opens Credits and Contact', (tester) async {
    await _show(tester, const AboutScreen());
    await tester.tap(find.text('Credits and licences'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter and Dart'), findsOneWidget);
    expect(find.text('Full licence texts'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact us'));
    await tester.pumpAndSettle();
    expect(find.text('hello@amrutham.app'), findsOneWidget);
  });

  test('every package the app depends on is credited', () {
    final text = File('pubspec.yaml').readAsStringSync();
    final deps = text.split('dev_dependencies:').first.split('dependencies:').last;
    final credited = credits.expand((g) => g.items).map((c) => c.name).join(' ');
    for (final line in deps.split('\n')) {
      final m = RegExp(r'^  ([a-z_]+):').firstMatch(line);
      if (m == null) continue;
      final name = m[1]!;
      if (const {'flutter', 'flutter_localizations', 'cupertino_icons', 'amrutham_folder', 'amrutham_widgets', 'realm'}.contains(name)) continue;
      expect(credited, contains(name), reason: '$name is used but not on the Credits screen');
    }
  });
}

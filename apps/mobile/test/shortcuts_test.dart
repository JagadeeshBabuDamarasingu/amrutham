// App-icon shortcuts are plain Android XML that no Dart test exercises, and a
// wrong package or action fails silently on the phone (the shortcut does
// nothing). This reads the files and checks they agree with each other and
// with the app.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/quick_access/launch_action.dart';

String _read(String path) => File('android/app/src/$path').readAsStringSync();

void main() {
  final actionNames = RegExp(r'name="amrutham_action" android:value="([^"]+)"');

  test('every shortcut asks for an action the app understands', () {
    for (final file in ['main/res/xml/shortcuts.xml', 'debug/res/xml/shortcuts.xml']) {
      final actions = actionNames.allMatches(_read(file)).map((m) => m[1]!).toList();
      expect(actions, ['emergency', 'log-reading', 'next-dose', 'add-record'], reason: file);
      for (final a in actions) {
        expect(resolveLaunch({'action': a}, living: const [PersonId('p')]), isNotNull, reason: a);
      }
    }
  });

  test('the debug copy targets the .debug id, the main copy the real one', () {
    expect(_read('main/res/xml/shortcuts.xml'), contains('android:targetPackage="app.amrutham"'));
    expect(_read('main/res/xml/shortcuts.xml'), isNot(contains('app.amrutham.debug')));
    expect(_read('debug/res/xml/shortcuts.xml'), contains('android:targetPackage="app.amrutham.debug"'));
  });

  test('the manifest points at the shortcuts and every label and icon exists', () {
    expect(_read('main/AndroidManifest.xml'), contains('android:name="android.app.shortcuts"'));
    final xml = _read('main/res/xml/shortcuts.xml');
    final strings = _read('main/res/values/shortcut_strings.xml');
    for (final m in RegExp(r'@string/(\w+)').allMatches(xml)) {
      expect(strings, contains('name="${m[1]}"'));
    }
    for (final m in RegExp(r'@drawable/(\w+)').allMatches(xml)) {
      expect(File('android/app/src/main/res/drawable/${m[1]}.xml').existsSync(), isTrue, reason: m[1]);
    }
  });

  test('there are at most four, the number launchers reliably show', () {
    expect('<shortcut\n'.allMatches(_read('main/res/xml/shortcuts.xml')).length, lessThanOrEqualTo(4));
  });
}

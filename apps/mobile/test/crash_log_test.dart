import 'dart:io';

import 'package:amrutham/crash/crash_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late CrashLog log;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('crash');
    log = CrashLog(File('${dir.path}/crash_log.txt'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('keeps the type and stack but never the message', () {
    log.record(StateError('Meera has diabetes'), StackTrace.fromString('#0 main'));
    final text = log.read();
    expect(text, contains('StateError'));
    expect(text, contains('#0 main'));
    expect(text, isNot(contains('Meera')));
  });

  test('stays under the cap, newest entries kept', () {
    for (var i = 0; i < 400; i++) {
      log.record(StateError('x'), StackTrace.fromString('${'frame ' * 40}#$i'));
    }
    expect(log.file.lengthSync(), lessThanOrEqualTo(64 * 1024));
    expect(log.read(), contains('#399'));
  });

  test('clear removes the log', () {
    log.record(StateError('x'), null);
    log.clear();
    expect(log.hasEntries, isFalse);
  });
}

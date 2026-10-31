import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/backup_folder.dart';

const _tree = 'content://com.android.externalstorage.documents/tree/primary%3ADocuments%2FAmrutham';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.amrutham/folder');

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  test('a content folder is written through the native channel', () async {
    MethodCall? seen;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      seen = call;
      return true;
    });

    await writeToBackupFolder(_tree, backupFileName, [1, 2, 3]);

    expect(seen!.method, 'write');
    expect(seen!.arguments['tree'], _tree);
    expect(seen!.arguments['name'], 'amrutham-backup.amrutham');
    expect(seen!.arguments['bytes'], [1, 2, 3]);
  });

  test('a native write failure reaches the caller', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'write_failed', message: 'denied'),
    );
    await expectLater(writeToBackupFolder(_tree, backupFileName, [1]), throwsA(isA<PlatformException>()));
  });

  test('a plain path is written as a file and replaced next time', () async {
    final dir = await Directory.systemTemp.createTemp('folder');
    addTearDown(() => dir.delete(recursive: true));

    await writeToBackupFolder(dir.path, backupFileName, [1, 2, 3]);
    await writeToBackupFolder(dir.path, backupFileName, [9]);

    expect(File('${dir.path}/$backupFileName').readAsBytesSync(), [9]);
    expect(dir.listSync(), hasLength(1));
  });

  test('a missing plain folder throws FileSystemException', () async {
    await expectLater(
      writeToBackupFolder('/no/such/folder', backupFileName, [1]),
      throwsA(isA<FileSystemException>()),
    );
  });

  group('backupFolderLabel', () {
    test('phone storage tree', () => expect(backupFolderLabel(_tree), 'Phone storage › Documents › Amrutham'));
    test('tree root', () {
      expect(
        backupFolderLabel('content://com.android.externalstorage.documents/tree/primary%3A'),
        'Phone storage',
      );
    });
    test('an SD card keeps its volume id', () {
      expect(
        backupFolderLabel('content://com.android.externalstorage.documents/tree/1A2B-3C4D%3ABackups'),
        '1A2B-3C4D › Backups',
      );
    });
    test('a plain path is shown as is', () => expect(backupFolderLabel('/storage/emulated/0/Backups'), '/storage/emulated/0/Backups'));
  });
}

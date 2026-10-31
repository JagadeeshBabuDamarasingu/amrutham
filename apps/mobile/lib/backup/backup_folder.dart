import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('app.amrutham/folder');

/// The backup file's fixed name: overwritten each time, so a sync app sees one
/// file.
const backupFileName = 'amrutham-backup.amrutham';

/// Lets the person pick a folder. On Android this keeps write access across
/// restarts and returns a `content://` tree URI (plain paths in shared storage
/// are not writable since Android 11); elsewhere it returns a path. Null if
/// they back out.
Future<String?> pickBackupFolder() =>
    Platform.isAndroid ? _channel.invokeMethod<String>('pick') : FilePicker.getDirectoryPath();

/// Writes [bytes] as [name] into [folder], replacing a file of that name.
/// Throws [FileSystemException] or [PlatformException] if it can't.
Future<void> writeToBackupFolder(String folder, String name, List<int> bytes) async {
  if (folder.startsWith('content://')) {
    await _channel.invokeMethod<bool>('write', {
      'tree': folder,
      'name': name,
      'bytes': Uint8List.fromList(bytes),
    });
  } else {
    await File('$folder/$name').writeAsBytes(bytes, flush: true);
  }
}

/// A readable name for the stored folder: "Phone storage › Documents › Backups"
/// for a tree URI, the path itself otherwise.
String backupFolderLabel(String folder) {
  if (!folder.startsWith('content://')) return folder;
  final id = Uri.parse(folder).pathSegments.last;
  final colon = id.indexOf(':');
  final volume = colon < 0 ? id : id.substring(0, colon);
  final rest = colon < 0 ? '' : id.substring(colon + 1);
  final root = volume == 'primary' ? 'Phone storage' : volume;
  return rest.isEmpty ? root : '$root › ${rest.replaceAll('/', ' › ')}';
}

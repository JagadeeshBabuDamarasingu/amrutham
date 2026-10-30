import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A crash log that never leaves the phone by itself. Errors are written to
/// one file; the person decides whether to send it (Settings > Send a problem
/// report). Only the error type and stack trace are kept, never the message,
/// because messages can quote what the person typed or stored.
class CrashLog {
  CrashLog(this.file);

  final File file;

  static const _maxBytes = 64 * 1024;
  static const _sep = '\n---\n';

  static Future<CrashLog> open() async {
    final dir = await getApplicationSupportDirectory();
    return CrashLog(File(p.join(dir.path, 'crash_log.txt')));
  }

  /// Route Flutter and platform errors here. Call once, from main().
  Future<void> install() async {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      return false; // keep the default behaviour (report to console, crash)
    };
  }

  void record(Object error, StackTrace? stack) {
    try {
      final entry = '${DateTime.now().toUtc().toIso8601String()}\n'
          '${error.runtimeType}\n${stack ?? '(no stack trace)'}';
      var text = file.existsSync() ? file.readAsStringSync() : '';
      text = text.isEmpty ? entry : '$text$_sep$entry';
      if (text.length > _maxBytes) {
        // Keep the newest entries; cut at an entry boundary.
        final cut = text.indexOf(_sep, text.length - _maxBytes);
        text = cut < 0 ? text.substring(text.length - _maxBytes) : text.substring(cut + _sep.length);
      }
      file.writeAsStringSync(text);
    } catch (_) {
      // Logging must never be the thing that crashes the app.
    }
  }

  bool get hasEntries => file.existsSync() && file.lengthSync() > 0;

  String read() => hasEntries ? file.readAsStringSync() : '';

  void clear() {
    if (file.existsSync()) file.deleteSync();
  }
}

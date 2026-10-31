import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

const driveEmailKey = 'drive_email';
const driveLastBackupKey = 'drive_last_backup';

const _scope = 'https://www.googleapis.com/auth/drive.appdata';
const _fileName = 'amrutham-backup.amrutham';

/// Talks to Google Drive's hidden app folder (`appDataFolder`): only this app
/// can see it, never the rest of the user's Drive. Holds one encrypted file.
class DriveApi {
  DriveApi(this._client, this._token);

  final http.Client _client;
  final String _token;

  Map<String, String> get _auth => {'Authorization': 'Bearer $_token'};

  Future<String?> _findId() async {
    final res = await _client.get(
      Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q': "name = '$_fileName'",
        'fields': 'files(id)',
      }),
      headers: _auth,
    );
    _check(res);
    final files = (jsonDecode(res.body)['files'] as List);
    return files.isEmpty ? null : files.first['id'] as String;
  }

  /// Replaces the backup file, or creates it the first time.
  Future<void> upload(List<int> bytes) async {
    final id = await _findId();
    const boundary = 'amrutham-boundary';
    final meta = jsonEncode({
      'name': _fileName,
      if (id == null) 'parents': ['appDataFolder'],
    });
    final body = <int>[
      ...utf8.encode('--$boundary\r\nContent-Type: application/json\r\n\r\n$meta\r\n'
          '--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'),
      ...bytes,
      ...utf8.encode('\r\n--$boundary--'),
    ];
    final uri = Uri.https(
      'www.googleapis.com',
      id == null ? '/upload/drive/v3/files' : '/upload/drive/v3/files/$id',
      {'uploadType': 'multipart'},
    );
    final request = http.Request(id == null ? 'POST' : 'PATCH', uri)
      ..headers.addAll({..._auth, 'Content-Type': 'multipart/related; boundary=$boundary'})
      ..bodyBytes = body;
    _check(await http.Response.fromStream(await _client.send(request)));
  }

  /// The backup bytes, or null if nothing has been uploaded yet.
  Future<List<int>?> download() async {
    final id = await _findId();
    if (id == null) return null;
    final res = await _client.get(
      Uri.https('www.googleapis.com', '/drive/v3/files/$id', {'alt': 'media'}),
      headers: _auth,
    );
    _check(res);
    return res.bodyBytes;
  }

  /// Size of the stored backup in bytes, or null if there is none.
  Future<int?> size() async {
    final res = await _client.get(
      Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q': "name = '$_fileName'",
        'fields': 'files(size)',
      }),
      headers: _auth,
    );
    _check(res);
    final files = (jsonDecode(res.body)['files'] as List);
    return files.isEmpty ? null : int.tryParse('${files.first['size']}');
  }

  void _check(http.Response res) {
    if (res.statusCode >= 300) {
      throw http.ClientException('Drive answered ${res.statusCode}', res.request?.url);
    }
  }
}

/// The Web application OAuth client of the Amrutham Google Cloud project. Not
/// a secret. The Android clients (debug, upload, Play signing keys) are matched
/// by package name and SHA-1 and need nothing here.
const _webClientId =
    '741908044343-fhjhvs3o76vd2c9lc3nasc29pb1oq38r.apps.googleusercontent.com';

/// Google sign-in plus an authorised [DriveApi]. Needs an OAuth client for the
/// app's package name and signing key in Google Cloud (see the README).
class DriveSession {
  DriveSession._();
  static final instance = DriveSession._();

  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _ready = true;
  }

  /// Asks the user to sign in and allow the app folder. Returns their email.
  Future<String> connect() async {
    await _init();
    final account = await GoogleSignIn.instance.authenticate(scopeHint: [_scope]);
    await account.authorizationClient.authorizeScopes([_scope]);
    return account.email;
  }

  Future<DriveApi> _api() async {
    await _init();
    final auth = await GoogleSignIn.instance.authorizationClient.authorizationForScopes([_scope]) ??
        await GoogleSignIn.instance.authorizationClient.authorizeScopes([_scope]);
    return DriveApi(http.Client(), auth.accessToken);
  }

  Future<void> upload(List<int> bytes) async => (await _api()).upload(bytes);
  Future<List<int>?> download() async => (await _api()).download();
  Future<int?> size() async => (await _api()).size();

  Future<void> disconnect() async {
    await _init();
    await GoogleSignIn.instance.signOut();
  }
}

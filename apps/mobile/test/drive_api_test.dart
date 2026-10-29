import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amrutham/backup/drive_backup.dart';

void main() {
  test('first upload creates the file in the hidden app folder', () async {
    final calls = <http.BaseRequest>[];
    final bodies = <String>[];
    final api = DriveApi(
      MockClient.streaming((req, body) async {
        calls.add(req);
        bodies.add(utf8.decode(await body.toBytes(), allowMalformed: true));
        final json = req.method == 'GET' ? '{"files":[]}' : '{}';
        return http.StreamedResponse(Stream.value(utf8.encode(json)), 200, request: req);
      }),
      'tok',
    );
    await api.upload([1, 2, 3]);

    expect(calls.map((c) => c.method), ['GET', 'POST']);
    expect(calls.first.url.queryParameters['spaces'], 'appDataFolder');
    expect(calls.last.headers['Authorization'], 'Bearer tok');
    expect(bodies.last, contains('"parents":["appDataFolder"]'));
  });

  test('later uploads update the same file, and download finds it', () async {
    final calls = <String>[];
    final api = DriveApi(
      MockClient.streaming((req, body) async {
        calls.add('${req.method} ${req.url.path}');
        await body.toBytes();
        final data = req.url.queryParameters['alt'] == 'media'
            ? [7, 7]
            : utf8.encode(req.method == 'GET' ? '{"files":[{"id":"abc","size":"2"}]}' : '{}');
        return http.StreamedResponse(Stream.value(data), 200, request: req);
      }),
      'tok',
    );
    await api.upload([1]);
    expect(await api.download(), [7, 7]);
    expect(await api.size(), 2);
    expect(calls, contains('PATCH /upload/drive/v3/files/abc'));
  });

  test('a Drive error surfaces instead of looking like success', () async {
    final api = DriveApi(MockClient((_) async => http.Response('no', 403)), 'tok');
    await expectLater(api.upload([1]), throwsA(isA<http.ClientException>()));
  });
}

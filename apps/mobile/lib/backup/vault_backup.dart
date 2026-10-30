import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:realm/realm.dart';

import '../crypto/recovery_code.dart';
import '../db/realm_schemas.dart';

/// Thrown when a backup can't be read: wrong code, damaged file, or not an
/// Amrutham backup. The wording is safe to show.
class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// An encrypted copy of everything on the phone: every table, plus the filed
/// documents. The key comes from the recovery code (Argon2id), so only the
/// code opens it; nothing is stored or sent anywhere.
///
/// File layout: magic "AMRBK1" | salt (16) | nonce (12) | ciphertext | mac (16).
// ponytail: the whole vault is read into memory and documents are base64 inside
// one JSON document. Fine for a family's records; a vault with hundreds of
// large scans needs a streamed/zip format.
class VaultBackup {
  static const _magic = 'AMRBK1';
  static const _version = 1;

  // ---- snapshot / restore (plain JSON, no crypto) ----

  static Future<Map<String, dynamic>> snapshot(Realm realm, Directory vault) async {
    String? d(DateTime? v) => v?.toUtc().toIso8601String();
    final records = <Map<String, dynamic>>[];
    for (final r in realm.all<RecordRow>()) {
      final files = <Map<String, String>>[];
      for (final rel in r.files) {
        final f = File(p.join(vault.path, rel));
        if (await f.exists()) {
          files.add({'path': rel, 'data': base64Encode(await f.readAsBytes())});
        }
      }
      records.add({
        'id': r.id, 'personId': r.personId, 'type': r.type, 'title': r.title,
        'recordDate': d(r.recordDate), 'addedAt': d(r.addedAt), 'source': r.source,
        'files': files,
      });
    }
    final receipts = <Map<String, String>>[];
    final receiptDir = Directory(p.join(vault.path, 'receipts'));
    if (await receiptDir.exists()) {
      await for (final f in receiptDir.list()) {
        if (f is File) {
          receipts.add({
            'path': p.join('receipts', p.basename(f.path)),
            'data': base64Encode(await f.readAsBytes()),
          });
        }
      }
    }
    return {
      'version': _version,
      'createdAt': d(DateTime.now()),
      'people': [
        for (final x in realm.all<PersonRow>())
          {
            'id': x.id, 'displayName': x.displayName,
            'givenName': x.givenName, 'surname': x.surname, 'relationship': x.relationship,
            'dateOfBirth': d(x.dateOfBirth), 'sex': x.sex, 'bloodGroup': x.bloodGroup,
            'createdAt': d(x.createdAt), 'isDeceased': x.isDeceased,
            'dateOfDeath': d(x.dateOfDeath), 'causeOfDeath': x.causeOfDeath,
            'emergencyContacts': [
              for (final c in x.emergencyContacts)
                {'name': c.name, 'phone': c.phone, 'relationship': c.relationship},
            ],
          },
      ],
      'familyHistory': [
        for (final x in realm.all<FamilyHistoryEntryRow>())
          {
            'id': x.id, 'personId': x.personId, 'relationship': x.relationship,
            'conditionText': x.conditionText, 'conditionCode': x.conditionCode,
            'onsetAgeApprox': x.onsetAgeApprox, 'outcome': x.outcome,
            'certainty': x.certainty, 'notes': x.notes,
          },
      ],
      'allergies': [
        for (final x in realm.all<AllergyRecordRow>())
          {
            'id': x.id, 'personId': x.personId, 'substance': x.substance,
            'reaction': x.reaction, 'severity': x.severity,
            'certainty': x.certainty, 'notes': x.notes,
          },
      ],
      'courses': [
        for (final x in realm.all<MedicationCourseRow>())
          {
            'id': x.id, 'personId': x.personId, 'medicationName': x.medicationName,
            'status': x.status, 'startDate': d(x.startDate), 'endDate': d(x.endDate),
            'prescriberName': x.prescriberName, 'reason': x.reason,
          },
      ],
      'phases': [
        for (final x in realm.all<SchedulePhaseRow>())
          {
            'id': x.id, 'courseId': x.courseId, 'doseAmount': x.doseAmount,
            'frequency': x.frequency, 'period': x.period, 'periodUnit': x.periodUnit,
            'daysOfWeek': x.daysOfWeek.toList(), 'timesOfDay': x.timesOfDay.toList(),
            'isPrn': x.isPrn, 'prnReason': x.prnReason,
            'prnMaxFrequency': x.prnMaxFrequency, 'phaseStart': d(x.phaseStart),
            'phaseEnd': d(x.phaseEnd), 'conflictGroupId': x.conflictGroupId,
          },
      ],
      'measurements': [
        for (final x in realm.all<MeasurementRow>())
          {
            'id': x.id, 'personId': x.personId, 'kind': x.kind, 'value': x.value,
            'value2': x.value2, 'measuredAt': d(x.measuredAt), 'note': x.note,
          },
      ],
      'history': [
        for (final x in realm.all<HistoryEventRow>())
          {
            'id': x.id, 'personId': x.personId, 'kind': x.kind, 'title': x.title,
            'eventDate': d(x.eventDate), 'provider': x.provider, 'notes': x.notes,
          },
      ],
      'doseLogs': [
        for (final x in realm.all<DoseLogRow>())
          {
            'id': x.id, 'personId': x.personId, 'courseId': x.courseId,
            'scheduledAt': d(x.scheduledAt), 'status': x.status, 'loggedAt': d(x.loggedAt),
          },
      ],
      'careTeam': [
        for (final x in realm.all<CareProviderRow>())
          {
            'id': x.id, 'kind': x.kind, 'name': x.name, 'isCurrent': x.isCurrent,
            'specialty': x.specialty, 'worksAt': x.worksAt, 'phone': x.phone,
            'location': x.location, 'personIds': x.personIds.toList(),
          },
      ],
      'expenses': [
        for (final x in realm.all<ExpenseRow>())
          {
            'id': x.id, 'personId': x.personId, 'title': x.title,
            'amountPaise': x.amountPaise, 'category': x.category,
            'spentOn': d(x.spentOn), 'addedAt': d(x.addedAt),
            'payee': x.payee, 'paidBy': x.paidBy,
          },
      ],
      'records': records,
      'receipts': receipts,
    };
  }

  /// Replaces everything on this phone with [data]. Returns the person ids so
  /// the caller can re-arm their reminders.
  static Future<List<String>> restore(
    Realm realm,
    Directory vault,
    Map<String, dynamic> data,
  ) async {
    if (data['version'] != _version) {
      throw BackupException('This backup was made by a newer version of Amrutham.');
    }
    DateTime t(Object? v) => DateTime.parse(v as String).toLocal();
    DateTime? to(Object? v) => v == null ? null : t(v);
    List<Map<String, dynamic>> list(String k) =>
        ((data[k] as List?) ?? const []).cast<Map<String, dynamic>>();

    // Files first (outside the write transaction), after clearing old ones.
    if (await vault.exists()) await vault.delete(recursive: true);
    await vault.create(recursive: true);
    for (final r in list('records')) {
      for (final f in (r['files'] as List).cast<Map<String, dynamic>>()) {
        final file = File(p.join(vault.path, f['path'] as String));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(base64Decode(f['data'] as String));
      }
    }

    for (final f in list('receipts')) {
      final file = File(p.join(vault.path, f['path'] as String));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(base64Decode(f['data'] as String));
    }

    realm.write(() {
      realm
        ..deleteAll<PersonRow>()
        ..deleteAll<FamilyHistoryEntryRow>()
        ..deleteAll<AllergyRecordRow>()
        ..deleteAll<MedicationCourseRow>()
        ..deleteAll<SchedulePhaseRow>()
        ..deleteAll<MeasurementRow>()
        ..deleteAll<HistoryEventRow>()
        ..deleteAll<DoseLogRow>()
        ..deleteAll<CareProviderRow>()
        ..deleteAll<ExpenseRow>()
        ..deleteAll<RecordRow>();

      for (final x in list('people')) {
        realm.add(PersonRow(
          x['id'] as String, x['displayName'] as String, x['relationship'] as String,
          t(x['createdAt']),
          givenName: x['givenName'] as String?, surname: x['surname'] as String?,
          dateOfBirth: to(x['dateOfBirth']), sex: x['sex'] as String?,
          bloodGroup: x['bloodGroup'] as String?,
          isDeceased: x['isDeceased'] as bool? ?? false,
          dateOfDeath: to(x['dateOfDeath']), causeOfDeath: x['causeOfDeath'] as String?,
          emergencyContacts: [
            for (final c in (x['emergencyContacts'] as List).cast<Map<String, dynamic>>())
              EmergencyContactRow(c['name'] as String, c['phone'] as String,
                  relationship: c['relationship'] as String?),
          ],
        ));
      }
      for (final x in list('familyHistory')) {
        realm.add(FamilyHistoryEntryRow(
          x['id'] as String, x['personId'] as String, x['relationship'] as String,
          x['conditionText'] as String, x['certainty'] as String,
          conditionCode: x['conditionCode'] as String?,
          onsetAgeApprox: x['onsetAgeApprox'] as int?, outcome: x['outcome'] as String?,
          notes: x['notes'] as String?,
        ));
      }
      for (final x in list('allergies')) {
        realm.add(AllergyRecordRow(
          x['id'] as String, x['personId'] as String, x['substance'] as String,
          x['reaction'] as String, x['certainty'] as String,
          severity: x['severity'] as String?, notes: x['notes'] as String?,
        ));
      }
      for (final x in list('courses')) {
        realm.add(MedicationCourseRow(
          x['id'] as String, x['personId'] as String, x['medicationName'] as String,
          x['status'] as String, t(x['startDate']),
          endDate: to(x['endDate']), prescriberName: x['prescriberName'] as String?,
          reason: x['reason'] as String?,
        ));
      }
      for (final x in list('phases')) {
        realm.add(SchedulePhaseRow(
          x['id'] as String, x['courseId'] as String, x['doseAmount'] as String,
          x['frequency'] as int, x['period'] as int, x['periodUnit'] as String,
          t(x['phaseStart']),
          daysOfWeek: (x['daysOfWeek'] as List).cast<int>(),
          timesOfDay: (x['timesOfDay'] as List).cast<String>(),
          isPrn: x['isPrn'] as bool, prnReason: x['prnReason'] as String?,
          prnMaxFrequency: x['prnMaxFrequency'] as String?, phaseEnd: to(x['phaseEnd']),
          conflictGroupId: x['conflictGroupId'] as String?,
        ));
      }
      for (final x in list('measurements')) {
        realm.add(MeasurementRow(
          x['id'] as String, x['personId'] as String, x['kind'] as String,
          (x['value'] as num).toDouble(), t(x['measuredAt']),
          value2: (x['value2'] as num?)?.toDouble(), note: x['note'] as String?,
        ));
      }
      for (final x in list('history')) {
        realm.add(HistoryEventRow(
          x['id'] as String, x['personId'] as String, x['kind'] as String,
          x['title'] as String, t(x['eventDate']),
          provider: x['provider'] as String?, notes: x['notes'] as String?,
        ));
      }
      for (final x in list('doseLogs')) {
        realm.add(DoseLogRow(
          x['id'] as String, x['personId'] as String, x['courseId'] as String,
          t(x['scheduledAt']), x['status'] as String, t(x['loggedAt']),
        ));
      }
      for (final x in list('careTeam')) {
        realm.add(CareProviderRow(
          x['id'] as String, x['kind'] as String, x['name'] as String,
          x['isCurrent'] as bool,
          specialty: x['specialty'] as String?, worksAt: x['worksAt'] as String?,
          phone: x['phone'] as String?, location: x['location'] as String?,
          personIds: (x['personIds'] as List).cast<String>(),
        ));
      }
      for (final x in list('expenses')) {
        realm.add(ExpenseRow(
          x['id'] as String, x['personId'] as String, x['title'] as String,
          x['amountPaise'] as int, x['category'] as String, t(x['spentOn']),
          t(x['addedAt']),
          payee: x['payee'] as String?, paidBy: x['paidBy'] as String?,
        ));
      }
      for (final x in list('records')) {
        realm.add(RecordRow(
          x['id'] as String, x['personId'] as String, x['type'] as String,
          x['title'] as String, t(x['recordDate']), t(x['addedAt']),
          source: x['source'] as String?,
          files: [for (final f in (x['files'] as List).cast<Map<String, dynamic>>()) f['path'] as String],
        ));
      }
    });
    return [for (final x in list('people')) x['id'] as String];
  }

  // ---- encryption ----

  /// Encrypts on a background isolate: Argon2id and AES in pure Dart are slow.
  static Future<List<int>> encrypt(Map<String, dynamic> data, RecoveryCode code) {
    final json = jsonEncode(data);
    final rng = Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final nonce = List<int>.generate(12, (_) => rng.nextInt(256));
    return Isolate.run(() async {
      final key = await _key(code.value, salt);
      final box = await AesGcm.with256bits().encrypt(
        utf8.encode(json),
        secretKey: key,
        nonce: nonce,
      );
      return <int>[...utf8.encode(_magic), ...salt, ...box.nonce, ...box.cipherText, ...box.mac.bytes];
    });
  }

  static Future<Map<String, dynamic>> decrypt(List<int> bytes, RecoveryCode code) async {
    final head = utf8.encode(_magic).length;
    if (bytes.length < head + 16 + 12 + 16 ||
        utf8.decode(bytes.sublist(0, head), allowMalformed: true) != _magic) {
      throw BackupException("That file isn't an Amrutham backup.");
    }
    final salt = bytes.sublist(head, head + 16);
    final rest = bytes.sublist(head + 16);
    try {
      final plain = await Isolate.run(() async {
        final key = await _key(code.value, salt);
        return AesGcm.with256bits().decrypt(
          SecretBox.fromConcatenation(rest, nonceLength: 12, macLength: 16),
          secretKey: key,
        );
      });
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      throw BackupException("That recovery code doesn't open this backup.");
    }
  }

  static Future<SecretKey> _key(String code, List<int> salt) {
    // ponytail: same Argon2id cost as the verifier in recovery_code.dart; tune
    // both together once benchmarked on a low-end phone (spec §8).
    return Argon2id(memory: 19456, parallelism: 1, iterations: 2, hashLength: 32)
        .deriveKeyFromPassword(password: code, nonce: salt);
  }
}

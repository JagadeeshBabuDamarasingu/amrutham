// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_schemas.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class EmergencyContactRow extends _EmergencyContactRow
    with RealmEntity, RealmObjectBase, EmbeddedObject {
  EmergencyContactRow(String name, String phone, {String? relationship}) {
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'phone', phone);
    RealmObjectBase.set(this, 'relationship', relationship);
  }

  EmergencyContactRow._();

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get phone => RealmObjectBase.get<String>(this, 'phone') as String;
  @override
  set phone(String value) => RealmObjectBase.set(this, 'phone', value);

  @override
  String? get relationship =>
      RealmObjectBase.get<String>(this, 'relationship') as String?;
  @override
  set relationship(String? value) =>
      RealmObjectBase.set(this, 'relationship', value);

  @override
  Stream<RealmObjectChanges<EmergencyContactRow>> get changes =>
      RealmObjectBase.getChanges<EmergencyContactRow>(this);

  @override
  Stream<RealmObjectChanges<EmergencyContactRow>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<EmergencyContactRow>(this, keyPaths);

  @override
  EmergencyContactRow freeze() =>
      RealmObjectBase.freezeObject<EmergencyContactRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'name': name.toEJson(),
      'phone': phone.toEJson(),
      'relationship': relationship.toEJson(),
    };
  }

  static EJsonValue _toEJson(EmergencyContactRow value) => value.toEJson();
  static EmergencyContactRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'name': EJsonValue name, 'phone': EJsonValue phone} =>
        EmergencyContactRow(
          fromEJson(name),
          fromEJson(phone),
          relationship: fromEJson(ejson['relationship']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(EmergencyContactRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.embeddedObject,
      EmergencyContactRow,
      'EmergencyContactRow',
      [
        SchemaProperty('name', RealmPropertyType.string),
        SchemaProperty('phone', RealmPropertyType.string),
        SchemaProperty(
          'relationship',
          RealmPropertyType.string,
          optional: true,
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class PersonRow extends _PersonRow
    with RealmEntity, RealmObjectBase, RealmObject {
  PersonRow(
    String id,
    String displayName,
    String relationship,
    DateTime createdAt, {
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
    Iterable<EmergencyContactRow> emergencyContacts = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'displayName', displayName);
    RealmObjectBase.set(this, 'relationship', relationship);
    RealmObjectBase.set(this, 'dateOfBirth', dateOfBirth);
    RealmObjectBase.set(this, 'sex', sex);
    RealmObjectBase.set(this, 'bloodGroup', bloodGroup);
    RealmObjectBase.set<RealmList<EmergencyContactRow>>(
      this,
      'emergencyContacts',
      RealmList<EmergencyContactRow>(emergencyContacts),
    );
    RealmObjectBase.set(this, 'createdAt', createdAt);
  }

  PersonRow._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get displayName =>
      RealmObjectBase.get<String>(this, 'displayName') as String;
  @override
  set displayName(String value) =>
      RealmObjectBase.set(this, 'displayName', value);

  @override
  String get relationship =>
      RealmObjectBase.get<String>(this, 'relationship') as String;
  @override
  set relationship(String value) =>
      RealmObjectBase.set(this, 'relationship', value);

  @override
  DateTime? get dateOfBirth =>
      RealmObjectBase.get<DateTime>(this, 'dateOfBirth') as DateTime?;
  @override
  set dateOfBirth(DateTime? value) =>
      RealmObjectBase.set(this, 'dateOfBirth', value);

  @override
  String? get sex => RealmObjectBase.get<String>(this, 'sex') as String?;
  @override
  set sex(String? value) => RealmObjectBase.set(this, 'sex', value);

  @override
  String? get bloodGroup =>
      RealmObjectBase.get<String>(this, 'bloodGroup') as String?;
  @override
  set bloodGroup(String? value) =>
      RealmObjectBase.set(this, 'bloodGroup', value);

  @override
  RealmList<EmergencyContactRow> get emergencyContacts =>
      RealmObjectBase.get<EmergencyContactRow>(this, 'emergencyContacts')
          as RealmList<EmergencyContactRow>;
  @override
  set emergencyContacts(covariant RealmList<EmergencyContactRow> value) =>
      throw RealmUnsupportedSetError();

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  Stream<RealmObjectChanges<PersonRow>> get changes =>
      RealmObjectBase.getChanges<PersonRow>(this);

  @override
  Stream<RealmObjectChanges<PersonRow>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<PersonRow>(this, keyPaths);

  @override
  PersonRow freeze() => RealmObjectBase.freezeObject<PersonRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'displayName': displayName.toEJson(),
      'relationship': relationship.toEJson(),
      'dateOfBirth': dateOfBirth.toEJson(),
      'sex': sex.toEJson(),
      'bloodGroup': bloodGroup.toEJson(),
      'emergencyContacts': emergencyContacts.toEJson(),
      'createdAt': createdAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(PersonRow value) => value.toEJson();
  static PersonRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'displayName': EJsonValue displayName,
        'relationship': EJsonValue relationship,
        'createdAt': EJsonValue createdAt,
      } =>
        PersonRow(
          fromEJson(id),
          fromEJson(displayName),
          fromEJson(relationship),
          fromEJson(createdAt),
          dateOfBirth: fromEJson(ejson['dateOfBirth']),
          sex: fromEJson(ejson['sex']),
          bloodGroup: fromEJson(ejson['bloodGroup']),
          emergencyContacts: fromEJson(ejson['emergencyContacts']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(PersonRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, PersonRow, 'PersonRow', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('displayName', RealmPropertyType.string),
      SchemaProperty('relationship', RealmPropertyType.string),
      SchemaProperty(
        'dateOfBirth',
        RealmPropertyType.timestamp,
        optional: true,
      ),
      SchemaProperty('sex', RealmPropertyType.string, optional: true),
      SchemaProperty('bloodGroup', RealmPropertyType.string, optional: true),
      SchemaProperty(
        'emergencyContacts',
        RealmPropertyType.object,
        linkTarget: 'EmergencyContactRow',
        collectionType: RealmCollectionType.list,
      ),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class FamilyHistoryEntryRow extends _FamilyHistoryEntryRow
    with RealmEntity, RealmObjectBase, RealmObject {
  FamilyHistoryEntryRow(
    String id,
    String personId,
    String relationship,
    String conditionText,
    String certainty, {
    String? conditionCode,
    int? onsetAgeApprox,
    String? outcome,
    String? notes,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'personId', personId);
    RealmObjectBase.set(this, 'relationship', relationship);
    RealmObjectBase.set(this, 'conditionText', conditionText);
    RealmObjectBase.set(this, 'conditionCode', conditionCode);
    RealmObjectBase.set(this, 'onsetAgeApprox', onsetAgeApprox);
    RealmObjectBase.set(this, 'outcome', outcome);
    RealmObjectBase.set(this, 'certainty', certainty);
    RealmObjectBase.set(this, 'notes', notes);
  }

  FamilyHistoryEntryRow._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get personId =>
      RealmObjectBase.get<String>(this, 'personId') as String;
  @override
  set personId(String value) => RealmObjectBase.set(this, 'personId', value);

  @override
  String get relationship =>
      RealmObjectBase.get<String>(this, 'relationship') as String;
  @override
  set relationship(String value) =>
      RealmObjectBase.set(this, 'relationship', value);

  @override
  String get conditionText =>
      RealmObjectBase.get<String>(this, 'conditionText') as String;
  @override
  set conditionText(String value) =>
      RealmObjectBase.set(this, 'conditionText', value);

  @override
  String? get conditionCode =>
      RealmObjectBase.get<String>(this, 'conditionCode') as String?;
  @override
  set conditionCode(String? value) =>
      RealmObjectBase.set(this, 'conditionCode', value);

  @override
  int? get onsetAgeApprox =>
      RealmObjectBase.get<int>(this, 'onsetAgeApprox') as int?;
  @override
  set onsetAgeApprox(int? value) =>
      RealmObjectBase.set(this, 'onsetAgeApprox', value);

  @override
  String? get outcome =>
      RealmObjectBase.get<String>(this, 'outcome') as String?;
  @override
  set outcome(String? value) => RealmObjectBase.set(this, 'outcome', value);

  @override
  String get certainty =>
      RealmObjectBase.get<String>(this, 'certainty') as String;
  @override
  set certainty(String value) => RealmObjectBase.set(this, 'certainty', value);

  @override
  String? get notes => RealmObjectBase.get<String>(this, 'notes') as String?;
  @override
  set notes(String? value) => RealmObjectBase.set(this, 'notes', value);

  @override
  Stream<RealmObjectChanges<FamilyHistoryEntryRow>> get changes =>
      RealmObjectBase.getChanges<FamilyHistoryEntryRow>(this);

  @override
  Stream<RealmObjectChanges<FamilyHistoryEntryRow>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<FamilyHistoryEntryRow>(this, keyPaths);

  @override
  FamilyHistoryEntryRow freeze() =>
      RealmObjectBase.freezeObject<FamilyHistoryEntryRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'personId': personId.toEJson(),
      'relationship': relationship.toEJson(),
      'conditionText': conditionText.toEJson(),
      'conditionCode': conditionCode.toEJson(),
      'onsetAgeApprox': onsetAgeApprox.toEJson(),
      'outcome': outcome.toEJson(),
      'certainty': certainty.toEJson(),
      'notes': notes.toEJson(),
    };
  }

  static EJsonValue _toEJson(FamilyHistoryEntryRow value) => value.toEJson();
  static FamilyHistoryEntryRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'personId': EJsonValue personId,
        'relationship': EJsonValue relationship,
        'conditionText': EJsonValue conditionText,
        'certainty': EJsonValue certainty,
      } =>
        FamilyHistoryEntryRow(
          fromEJson(id),
          fromEJson(personId),
          fromEJson(relationship),
          fromEJson(conditionText),
          fromEJson(certainty),
          conditionCode: fromEJson(ejson['conditionCode']),
          onsetAgeApprox: fromEJson(ejson['onsetAgeApprox']),
          outcome: fromEJson(ejson['outcome']),
          notes: fromEJson(ejson['notes']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(FamilyHistoryEntryRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      FamilyHistoryEntryRow,
      'FamilyHistoryEntryRow',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty(
          'personId',
          RealmPropertyType.string,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('relationship', RealmPropertyType.string),
        SchemaProperty('conditionText', RealmPropertyType.string),
        SchemaProperty(
          'conditionCode',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty('onsetAgeApprox', RealmPropertyType.int, optional: true),
        SchemaProperty('outcome', RealmPropertyType.string, optional: true),
        SchemaProperty('certainty', RealmPropertyType.string),
        SchemaProperty('notes', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class AllergyRecordRow extends _AllergyRecordRow
    with RealmEntity, RealmObjectBase, RealmObject {
  AllergyRecordRow(
    String id,
    String personId,
    String substance,
    String reaction,
    String certainty, {
    String? severity,
    String? notes,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'personId', personId);
    RealmObjectBase.set(this, 'substance', substance);
    RealmObjectBase.set(this, 'reaction', reaction);
    RealmObjectBase.set(this, 'severity', severity);
    RealmObjectBase.set(this, 'certainty', certainty);
    RealmObjectBase.set(this, 'notes', notes);
  }

  AllergyRecordRow._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get personId =>
      RealmObjectBase.get<String>(this, 'personId') as String;
  @override
  set personId(String value) => RealmObjectBase.set(this, 'personId', value);

  @override
  String get substance =>
      RealmObjectBase.get<String>(this, 'substance') as String;
  @override
  set substance(String value) => RealmObjectBase.set(this, 'substance', value);

  @override
  String get reaction =>
      RealmObjectBase.get<String>(this, 'reaction') as String;
  @override
  set reaction(String value) => RealmObjectBase.set(this, 'reaction', value);

  @override
  String? get severity =>
      RealmObjectBase.get<String>(this, 'severity') as String?;
  @override
  set severity(String? value) => RealmObjectBase.set(this, 'severity', value);

  @override
  String get certainty =>
      RealmObjectBase.get<String>(this, 'certainty') as String;
  @override
  set certainty(String value) => RealmObjectBase.set(this, 'certainty', value);

  @override
  String? get notes => RealmObjectBase.get<String>(this, 'notes') as String?;
  @override
  set notes(String? value) => RealmObjectBase.set(this, 'notes', value);

  @override
  Stream<RealmObjectChanges<AllergyRecordRow>> get changes =>
      RealmObjectBase.getChanges<AllergyRecordRow>(this);

  @override
  Stream<RealmObjectChanges<AllergyRecordRow>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<AllergyRecordRow>(this, keyPaths);

  @override
  AllergyRecordRow freeze() =>
      RealmObjectBase.freezeObject<AllergyRecordRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'personId': personId.toEJson(),
      'substance': substance.toEJson(),
      'reaction': reaction.toEJson(),
      'severity': severity.toEJson(),
      'certainty': certainty.toEJson(),
      'notes': notes.toEJson(),
    };
  }

  static EJsonValue _toEJson(AllergyRecordRow value) => value.toEJson();
  static AllergyRecordRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'personId': EJsonValue personId,
        'substance': EJsonValue substance,
        'reaction': EJsonValue reaction,
        'certainty': EJsonValue certainty,
      } =>
        AllergyRecordRow(
          fromEJson(id),
          fromEJson(personId),
          fromEJson(substance),
          fromEJson(reaction),
          fromEJson(certainty),
          severity: fromEJson(ejson['severity']),
          notes: fromEJson(ejson['notes']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(AllergyRecordRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      AllergyRecordRow,
      'AllergyRecordRow',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty(
          'personId',
          RealmPropertyType.string,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('substance', RealmPropertyType.string),
        SchemaProperty('reaction', RealmPropertyType.string),
        SchemaProperty('severity', RealmPropertyType.string, optional: true),
        SchemaProperty('certainty', RealmPropertyType.string),
        SchemaProperty('notes', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class MedicationCourseRow extends _MedicationCourseRow
    with RealmEntity, RealmObjectBase, RealmObject {
  MedicationCourseRow(
    String id,
    String personId,
    String medicationName,
    String status,
    DateTime startDate, {
    DateTime? endDate,
    String? prescriberName,
    String? reason,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'personId', personId);
    RealmObjectBase.set(this, 'medicationName', medicationName);
    RealmObjectBase.set(this, 'status', status);
    RealmObjectBase.set(this, 'startDate', startDate);
    RealmObjectBase.set(this, 'endDate', endDate);
    RealmObjectBase.set(this, 'prescriberName', prescriberName);
    RealmObjectBase.set(this, 'reason', reason);
  }

  MedicationCourseRow._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get personId =>
      RealmObjectBase.get<String>(this, 'personId') as String;
  @override
  set personId(String value) => RealmObjectBase.set(this, 'personId', value);

  @override
  String get medicationName =>
      RealmObjectBase.get<String>(this, 'medicationName') as String;
  @override
  set medicationName(String value) =>
      RealmObjectBase.set(this, 'medicationName', value);

  @override
  String get status => RealmObjectBase.get<String>(this, 'status') as String;
  @override
  set status(String value) => RealmObjectBase.set(this, 'status', value);

  @override
  DateTime get startDate =>
      RealmObjectBase.get<DateTime>(this, 'startDate') as DateTime;
  @override
  set startDate(DateTime value) =>
      RealmObjectBase.set(this, 'startDate', value);

  @override
  DateTime? get endDate =>
      RealmObjectBase.get<DateTime>(this, 'endDate') as DateTime?;
  @override
  set endDate(DateTime? value) => RealmObjectBase.set(this, 'endDate', value);

  @override
  String? get prescriberName =>
      RealmObjectBase.get<String>(this, 'prescriberName') as String?;
  @override
  set prescriberName(String? value) =>
      RealmObjectBase.set(this, 'prescriberName', value);

  @override
  String? get reason => RealmObjectBase.get<String>(this, 'reason') as String?;
  @override
  set reason(String? value) => RealmObjectBase.set(this, 'reason', value);

  @override
  Stream<RealmObjectChanges<MedicationCourseRow>> get changes =>
      RealmObjectBase.getChanges<MedicationCourseRow>(this);

  @override
  Stream<RealmObjectChanges<MedicationCourseRow>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<MedicationCourseRow>(this, keyPaths);

  @override
  MedicationCourseRow freeze() =>
      RealmObjectBase.freezeObject<MedicationCourseRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'personId': personId.toEJson(),
      'medicationName': medicationName.toEJson(),
      'status': status.toEJson(),
      'startDate': startDate.toEJson(),
      'endDate': endDate.toEJson(),
      'prescriberName': prescriberName.toEJson(),
      'reason': reason.toEJson(),
    };
  }

  static EJsonValue _toEJson(MedicationCourseRow value) => value.toEJson();
  static MedicationCourseRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'personId': EJsonValue personId,
        'medicationName': EJsonValue medicationName,
        'status': EJsonValue status,
        'startDate': EJsonValue startDate,
      } =>
        MedicationCourseRow(
          fromEJson(id),
          fromEJson(personId),
          fromEJson(medicationName),
          fromEJson(status),
          fromEJson(startDate),
          endDate: fromEJson(ejson['endDate']),
          prescriberName: fromEJson(ejson['prescriberName']),
          reason: fromEJson(ejson['reason']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(MedicationCourseRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      MedicationCourseRow,
      'MedicationCourseRow',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty(
          'personId',
          RealmPropertyType.string,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('medicationName', RealmPropertyType.string),
        SchemaProperty('status', RealmPropertyType.string),
        SchemaProperty('startDate', RealmPropertyType.timestamp),
        SchemaProperty('endDate', RealmPropertyType.timestamp, optional: true),
        SchemaProperty(
          'prescriberName',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty('reason', RealmPropertyType.string, optional: true),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class SchedulePhaseRow extends _SchedulePhaseRow
    with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  SchedulePhaseRow(
    String id,
    String courseId,
    String doseAmount,
    int frequency,
    int period,
    String periodUnit,
    DateTime phaseStart, {
    Iterable<int> daysOfWeek = const [],
    Iterable<String> timesOfDay = const [],
    bool isPrn = false,
    String? prnReason,
    String? prnMaxFrequency,
    DateTime? phaseEnd,
    String? conflictGroupId,
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<SchedulePhaseRow>({
        'isPrn': false,
      });
    }
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'courseId', courseId);
    RealmObjectBase.set(this, 'doseAmount', doseAmount);
    RealmObjectBase.set(this, 'frequency', frequency);
    RealmObjectBase.set(this, 'period', period);
    RealmObjectBase.set(this, 'periodUnit', periodUnit);
    RealmObjectBase.set<RealmList<int>>(
      this,
      'daysOfWeek',
      RealmList<int>(daysOfWeek),
    );
    RealmObjectBase.set<RealmList<String>>(
      this,
      'timesOfDay',
      RealmList<String>(timesOfDay),
    );
    RealmObjectBase.set(this, 'isPrn', isPrn);
    RealmObjectBase.set(this, 'prnReason', prnReason);
    RealmObjectBase.set(this, 'prnMaxFrequency', prnMaxFrequency);
    RealmObjectBase.set(this, 'phaseStart', phaseStart);
    RealmObjectBase.set(this, 'phaseEnd', phaseEnd);
    RealmObjectBase.set(this, 'conflictGroupId', conflictGroupId);
  }

  SchedulePhaseRow._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get courseId =>
      RealmObjectBase.get<String>(this, 'courseId') as String;
  @override
  set courseId(String value) => RealmObjectBase.set(this, 'courseId', value);

  @override
  String get doseAmount =>
      RealmObjectBase.get<String>(this, 'doseAmount') as String;
  @override
  set doseAmount(String value) =>
      RealmObjectBase.set(this, 'doseAmount', value);

  @override
  int get frequency => RealmObjectBase.get<int>(this, 'frequency') as int;
  @override
  set frequency(int value) => RealmObjectBase.set(this, 'frequency', value);

  @override
  int get period => RealmObjectBase.get<int>(this, 'period') as int;
  @override
  set period(int value) => RealmObjectBase.set(this, 'period', value);

  @override
  String get periodUnit =>
      RealmObjectBase.get<String>(this, 'periodUnit') as String;
  @override
  set periodUnit(String value) =>
      RealmObjectBase.set(this, 'periodUnit', value);

  @override
  RealmList<int> get daysOfWeek =>
      RealmObjectBase.get<int>(this, 'daysOfWeek') as RealmList<int>;
  @override
  set daysOfWeek(covariant RealmList<int> value) =>
      throw RealmUnsupportedSetError();

  @override
  RealmList<String> get timesOfDay =>
      RealmObjectBase.get<String>(this, 'timesOfDay') as RealmList<String>;
  @override
  set timesOfDay(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  bool get isPrn => RealmObjectBase.get<bool>(this, 'isPrn') as bool;
  @override
  set isPrn(bool value) => RealmObjectBase.set(this, 'isPrn', value);

  @override
  String? get prnReason =>
      RealmObjectBase.get<String>(this, 'prnReason') as String?;
  @override
  set prnReason(String? value) => RealmObjectBase.set(this, 'prnReason', value);

  @override
  String? get prnMaxFrequency =>
      RealmObjectBase.get<String>(this, 'prnMaxFrequency') as String?;
  @override
  set prnMaxFrequency(String? value) =>
      RealmObjectBase.set(this, 'prnMaxFrequency', value);

  @override
  DateTime get phaseStart =>
      RealmObjectBase.get<DateTime>(this, 'phaseStart') as DateTime;
  @override
  set phaseStart(DateTime value) =>
      RealmObjectBase.set(this, 'phaseStart', value);

  @override
  DateTime? get phaseEnd =>
      RealmObjectBase.get<DateTime>(this, 'phaseEnd') as DateTime?;
  @override
  set phaseEnd(DateTime? value) => RealmObjectBase.set(this, 'phaseEnd', value);

  @override
  String? get conflictGroupId =>
      RealmObjectBase.get<String>(this, 'conflictGroupId') as String?;
  @override
  set conflictGroupId(String? value) =>
      RealmObjectBase.set(this, 'conflictGroupId', value);

  @override
  Stream<RealmObjectChanges<SchedulePhaseRow>> get changes =>
      RealmObjectBase.getChanges<SchedulePhaseRow>(this);

  @override
  Stream<RealmObjectChanges<SchedulePhaseRow>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<SchedulePhaseRow>(this, keyPaths);

  @override
  SchedulePhaseRow freeze() =>
      RealmObjectBase.freezeObject<SchedulePhaseRow>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'courseId': courseId.toEJson(),
      'doseAmount': doseAmount.toEJson(),
      'frequency': frequency.toEJson(),
      'period': period.toEJson(),
      'periodUnit': periodUnit.toEJson(),
      'daysOfWeek': daysOfWeek.toEJson(),
      'timesOfDay': timesOfDay.toEJson(),
      'isPrn': isPrn.toEJson(),
      'prnReason': prnReason.toEJson(),
      'prnMaxFrequency': prnMaxFrequency.toEJson(),
      'phaseStart': phaseStart.toEJson(),
      'phaseEnd': phaseEnd.toEJson(),
      'conflictGroupId': conflictGroupId.toEJson(),
    };
  }

  static EJsonValue _toEJson(SchedulePhaseRow value) => value.toEJson();
  static SchedulePhaseRow _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'courseId': EJsonValue courseId,
        'doseAmount': EJsonValue doseAmount,
        'frequency': EJsonValue frequency,
        'period': EJsonValue period,
        'periodUnit': EJsonValue periodUnit,
        'phaseStart': EJsonValue phaseStart,
      } =>
        SchedulePhaseRow(
          fromEJson(id),
          fromEJson(courseId),
          fromEJson(doseAmount),
          fromEJson(frequency),
          fromEJson(period),
          fromEJson(periodUnit),
          fromEJson(phaseStart),
          daysOfWeek: fromEJson(ejson['daysOfWeek']),
          timesOfDay: fromEJson(ejson['timesOfDay']),
          isPrn: fromEJson(ejson['isPrn'], defaultValue: false),
          prnReason: fromEJson(ejson['prnReason']),
          prnMaxFrequency: fromEJson(ejson['prnMaxFrequency']),
          phaseEnd: fromEJson(ejson['phaseEnd']),
          conflictGroupId: fromEJson(ejson['conflictGroupId']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(SchedulePhaseRow._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      SchedulePhaseRow,
      'SchedulePhaseRow',
      [
        SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
        SchemaProperty(
          'courseId',
          RealmPropertyType.string,
          indexType: RealmIndexType.regular,
        ),
        SchemaProperty('doseAmount', RealmPropertyType.string),
        SchemaProperty('frequency', RealmPropertyType.int),
        SchemaProperty('period', RealmPropertyType.int),
        SchemaProperty('periodUnit', RealmPropertyType.string),
        SchemaProperty(
          'daysOfWeek',
          RealmPropertyType.int,
          collectionType: RealmCollectionType.list,
        ),
        SchemaProperty(
          'timesOfDay',
          RealmPropertyType.string,
          collectionType: RealmCollectionType.list,
        ),
        SchemaProperty('isPrn', RealmPropertyType.bool),
        SchemaProperty('prnReason', RealmPropertyType.string, optional: true),
        SchemaProperty(
          'prnMaxFrequency',
          RealmPropertyType.string,
          optional: true,
        ),
        SchemaProperty('phaseStart', RealmPropertyType.timestamp),
        SchemaProperty('phaseEnd', RealmPropertyType.timestamp, optional: true),
        SchemaProperty(
          'conflictGroupId',
          RealmPropertyType.string,
          optional: true,
        ),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

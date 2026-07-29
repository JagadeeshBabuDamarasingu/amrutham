// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class MedicationCourse extends Table
    with TableInfo<MedicationCourse, MedicationCourseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MedicationCourse(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES person(id)',
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _prescriberNameMeta = const VerificationMeta(
    'prescriberName',
  );
  late final GeneratedColumn<String> prescriberName = GeneratedColumn<String>(
    'prescriber_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    medicationName,
    status,
    startDate,
    endDate,
    prescriberName,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_course';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationCourseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('prescriber_name')) {
      context.handle(
        _prescriberNameMeta,
        prescriberName.isAcceptableOrUnknown(
          data['prescriber_name']!,
          _prescriberNameMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationCourseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationCourseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      prescriberName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescriber_name'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
    );
  }

  @override
  MedicationCourse createAlias(String alias) {
    return MedicationCourse(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MedicationCourseRow extends DataClass
    implements Insertable<MedicationCourseRow> {
  final String id;
  final String personId;
  final String medicationName;
  final String status;
  final String startDate;
  final String? endDate;
  final String? prescriberName;
  final String? reason;
  const MedicationCourseRow({
    required this.id,
    required this.personId,
    required this.medicationName,
    required this.status,
    required this.startDate,
    this.endDate,
    this.prescriberName,
    this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['medication_name'] = Variable<String>(medicationName);
    map['status'] = Variable<String>(status);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || prescriberName != null) {
      map['prescriber_name'] = Variable<String>(prescriberName);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  MedicationCourseCompanion toCompanion(bool nullToAbsent) {
    return MedicationCourseCompanion(
      id: Value(id),
      personId: Value(personId),
      medicationName: Value(medicationName),
      status: Value(status),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      prescriberName: prescriberName == null && nullToAbsent
          ? const Value.absent()
          : Value(prescriberName),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
    );
  }

  factory MedicationCourseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationCourseRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['person_id']),
      medicationName: serializer.fromJson<String>(json['medication_name']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<String>(json['start_date']),
      endDate: serializer.fromJson<String?>(json['end_date']),
      prescriberName: serializer.fromJson<String?>(json['prescriber_name']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'person_id': serializer.toJson<String>(personId),
      'medication_name': serializer.toJson<String>(medicationName),
      'status': serializer.toJson<String>(status),
      'start_date': serializer.toJson<String>(startDate),
      'end_date': serializer.toJson<String?>(endDate),
      'prescriber_name': serializer.toJson<String?>(prescriberName),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  MedicationCourseRow copyWith({
    String? id,
    String? personId,
    String? medicationName,
    String? status,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    Value<String?> prescriberName = const Value.absent(),
    Value<String?> reason = const Value.absent(),
  }) => MedicationCourseRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    medicationName: medicationName ?? this.medicationName,
    status: status ?? this.status,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    prescriberName: prescriberName.present
        ? prescriberName.value
        : this.prescriberName,
    reason: reason.present ? reason.value : this.reason,
  );
  MedicationCourseRow copyWithCompanion(MedicationCourseCompanion data) {
    return MedicationCourseRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      prescriberName: data.prescriberName.present
          ? data.prescriberName.value
          : this.prescriberName,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCourseRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('medicationName: $medicationName, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('prescriberName: $prescriberName, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    medicationName,
    status,
    startDate,
    endDate,
    prescriberName,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationCourseRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.medicationName == this.medicationName &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.prescriberName == this.prescriberName &&
          other.reason == this.reason);
}

class MedicationCourseCompanion extends UpdateCompanion<MedicationCourseRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> medicationName;
  final Value<String> status;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String?> prescriberName;
  final Value<String?> reason;
  final Value<int> rowid;
  const MedicationCourseCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.prescriberName = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationCourseCompanion.insert({
    required String id,
    required String personId,
    required String medicationName,
    required String status,
    required String startDate,
    this.endDate = const Value.absent(),
    this.prescriberName = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       medicationName = Value(medicationName),
       status = Value(status),
       startDate = Value(startDate);
  static Insertable<MedicationCourseRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? medicationName,
    Expression<String>? status,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? prescriberName,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (medicationName != null) 'medication_name': medicationName,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (prescriberName != null) 'prescriber_name': prescriberName,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationCourseCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? medicationName,
    Value<String>? status,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String?>? prescriberName,
    Value<String?>? reason,
    Value<int>? rowid,
  }) {
    return MedicationCourseCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      medicationName: medicationName ?? this.medicationName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      prescriberName: prescriberName ?? this.prescriberName,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (prescriberName.present) {
      map['prescriber_name'] = Variable<String>(prescriberName.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationCourseCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('medicationName: $medicationName, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('prescriberName: $prescriberName, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SchedulePhase extends Table
    with TableInfo<SchedulePhase, SchedulePhaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SchedulePhase(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES medication_course(id)',
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  late final GeneratedColumn<String> doseAmount = GeneratedColumn<String>(
    'dose_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  late final GeneratedColumn<int> period = GeneratedColumn<int>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _periodUnitMeta = const VerificationMeta(
    'periodUnit',
  );
  late final GeneratedColumn<String> periodUnit = GeneratedColumn<String>(
    'period_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _timesOfDayMeta = const VerificationMeta(
    'timesOfDay',
  );
  late final GeneratedColumn<String> timesOfDay = GeneratedColumn<String>(
    'times_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isPrnMeta = const VerificationMeta('isPrn');
  late final GeneratedColumn<int> isPrn = GeneratedColumn<int>(
    'is_prn',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _prnReasonMeta = const VerificationMeta(
    'prnReason',
  );
  late final GeneratedColumn<String> prnReason = GeneratedColumn<String>(
    'prn_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _prnMaxFrequencyMeta = const VerificationMeta(
    'prnMaxFrequency',
  );
  late final GeneratedColumn<String> prnMaxFrequency = GeneratedColumn<String>(
    'prn_max_frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _phaseStartMeta = const VerificationMeta(
    'phaseStart',
  );
  late final GeneratedColumn<String> phaseStart = GeneratedColumn<String>(
    'phase_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _phaseEndMeta = const VerificationMeta(
    'phaseEnd',
  );
  late final GeneratedColumn<String> phaseEnd = GeneratedColumn<String>(
    'phase_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _conflictGroupIdMeta = const VerificationMeta(
    'conflictGroupId',
  );
  late final GeneratedColumn<String> conflictGroupId = GeneratedColumn<String>(
    'conflict_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    courseId,
    doseAmount,
    frequency,
    period,
    periodUnit,
    daysOfWeek,
    timesOfDay,
    isPrn,
    prnReason,
    prnMaxFrequency,
    phaseStart,
    phaseEnd,
    conflictGroupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_phase';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchedulePhaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    } else if (isInserting) {
      context.missing(_doseAmountMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('period_unit')) {
      context.handle(
        _periodUnitMeta,
        periodUnit.isAcceptableOrUnknown(data['period_unit']!, _periodUnitMeta),
      );
    } else if (isInserting) {
      context.missing(_periodUnitMeta);
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('times_of_day')) {
      context.handle(
        _timesOfDayMeta,
        timesOfDay.isAcceptableOrUnknown(
          data['times_of_day']!,
          _timesOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timesOfDayMeta);
    }
    if (data.containsKey('is_prn')) {
      context.handle(
        _isPrnMeta,
        isPrn.isAcceptableOrUnknown(data['is_prn']!, _isPrnMeta),
      );
    }
    if (data.containsKey('prn_reason')) {
      context.handle(
        _prnReasonMeta,
        prnReason.isAcceptableOrUnknown(data['prn_reason']!, _prnReasonMeta),
      );
    }
    if (data.containsKey('prn_max_frequency')) {
      context.handle(
        _prnMaxFrequencyMeta,
        prnMaxFrequency.isAcceptableOrUnknown(
          data['prn_max_frequency']!,
          _prnMaxFrequencyMeta,
        ),
      );
    }
    if (data.containsKey('phase_start')) {
      context.handle(
        _phaseStartMeta,
        phaseStart.isAcceptableOrUnknown(data['phase_start']!, _phaseStartMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseStartMeta);
    }
    if (data.containsKey('phase_end')) {
      context.handle(
        _phaseEndMeta,
        phaseEnd.isAcceptableOrUnknown(data['phase_end']!, _phaseEndMeta),
      );
    }
    if (data.containsKey('conflict_group_id')) {
      context.handle(
        _conflictGroupIdMeta,
        conflictGroupId.isAcceptableOrUnknown(
          data['conflict_group_id']!,
          _conflictGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchedulePhaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchedulePhaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_amount'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period'],
      )!,
      periodUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_unit'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      ),
      timesOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_of_day'],
      )!,
      isPrn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_prn'],
      )!,
      prnReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prn_reason'],
      ),
      prnMaxFrequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prn_max_frequency'],
      ),
      phaseStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase_start'],
      )!,
      phaseEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase_end'],
      ),
      conflictGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_group_id'],
      ),
    );
  }

  @override
  SchedulePhase createAlias(String alias) {
    return SchedulePhase(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SchedulePhaseRow extends DataClass
    implements Insertable<SchedulePhaseRow> {
  final String id;
  final String courseId;
  final String doseAmount;
  final int frequency;
  final int period;
  final String periodUnit;
  final String? daysOfWeek;
  final String timesOfDay;
  final int isPrn;
  final String? prnReason;
  final String? prnMaxFrequency;
  final String phaseStart;
  final String? phaseEnd;

  /// Reserved for phase 2's sync conflict rule; always NULL in phase 1
  /// since single-device usage has no conflicts to represent yet. See
  /// specs/phase-1-v1/02-architecture.md §6's conflict rule —
  /// activeNonConflictedPhasesForPerson() must already respect this column.
  final String? conflictGroupId;
  const SchedulePhaseRow({
    required this.id,
    required this.courseId,
    required this.doseAmount,
    required this.frequency,
    required this.period,
    required this.periodUnit,
    this.daysOfWeek,
    required this.timesOfDay,
    required this.isPrn,
    this.prnReason,
    this.prnMaxFrequency,
    required this.phaseStart,
    this.phaseEnd,
    this.conflictGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['course_id'] = Variable<String>(courseId);
    map['dose_amount'] = Variable<String>(doseAmount);
    map['frequency'] = Variable<int>(frequency);
    map['period'] = Variable<int>(period);
    map['period_unit'] = Variable<String>(periodUnit);
    if (!nullToAbsent || daysOfWeek != null) {
      map['days_of_week'] = Variable<String>(daysOfWeek);
    }
    map['times_of_day'] = Variable<String>(timesOfDay);
    map['is_prn'] = Variable<int>(isPrn);
    if (!nullToAbsent || prnReason != null) {
      map['prn_reason'] = Variable<String>(prnReason);
    }
    if (!nullToAbsent || prnMaxFrequency != null) {
      map['prn_max_frequency'] = Variable<String>(prnMaxFrequency);
    }
    map['phase_start'] = Variable<String>(phaseStart);
    if (!nullToAbsent || phaseEnd != null) {
      map['phase_end'] = Variable<String>(phaseEnd);
    }
    if (!nullToAbsent || conflictGroupId != null) {
      map['conflict_group_id'] = Variable<String>(conflictGroupId);
    }
    return map;
  }

  SchedulePhaseCompanion toCompanion(bool nullToAbsent) {
    return SchedulePhaseCompanion(
      id: Value(id),
      courseId: Value(courseId),
      doseAmount: Value(doseAmount),
      frequency: Value(frequency),
      period: Value(period),
      periodUnit: Value(periodUnit),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      timesOfDay: Value(timesOfDay),
      isPrn: Value(isPrn),
      prnReason: prnReason == null && nullToAbsent
          ? const Value.absent()
          : Value(prnReason),
      prnMaxFrequency: prnMaxFrequency == null && nullToAbsent
          ? const Value.absent()
          : Value(prnMaxFrequency),
      phaseStart: Value(phaseStart),
      phaseEnd: phaseEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseEnd),
      conflictGroupId: conflictGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictGroupId),
    );
  }

  factory SchedulePhaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchedulePhaseRow(
      id: serializer.fromJson<String>(json['id']),
      courseId: serializer.fromJson<String>(json['course_id']),
      doseAmount: serializer.fromJson<String>(json['dose_amount']),
      frequency: serializer.fromJson<int>(json['frequency']),
      period: serializer.fromJson<int>(json['period']),
      periodUnit: serializer.fromJson<String>(json['period_unit']),
      daysOfWeek: serializer.fromJson<String?>(json['days_of_week']),
      timesOfDay: serializer.fromJson<String>(json['times_of_day']),
      isPrn: serializer.fromJson<int>(json['is_prn']),
      prnReason: serializer.fromJson<String?>(json['prn_reason']),
      prnMaxFrequency: serializer.fromJson<String?>(json['prn_max_frequency']),
      phaseStart: serializer.fromJson<String>(json['phase_start']),
      phaseEnd: serializer.fromJson<String?>(json['phase_end']),
      conflictGroupId: serializer.fromJson<String?>(json['conflict_group_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'course_id': serializer.toJson<String>(courseId),
      'dose_amount': serializer.toJson<String>(doseAmount),
      'frequency': serializer.toJson<int>(frequency),
      'period': serializer.toJson<int>(period),
      'period_unit': serializer.toJson<String>(periodUnit),
      'days_of_week': serializer.toJson<String?>(daysOfWeek),
      'times_of_day': serializer.toJson<String>(timesOfDay),
      'is_prn': serializer.toJson<int>(isPrn),
      'prn_reason': serializer.toJson<String?>(prnReason),
      'prn_max_frequency': serializer.toJson<String?>(prnMaxFrequency),
      'phase_start': serializer.toJson<String>(phaseStart),
      'phase_end': serializer.toJson<String?>(phaseEnd),
      'conflict_group_id': serializer.toJson<String?>(conflictGroupId),
    };
  }

  SchedulePhaseRow copyWith({
    String? id,
    String? courseId,
    String? doseAmount,
    int? frequency,
    int? period,
    String? periodUnit,
    Value<String?> daysOfWeek = const Value.absent(),
    String? timesOfDay,
    int? isPrn,
    Value<String?> prnReason = const Value.absent(),
    Value<String?> prnMaxFrequency = const Value.absent(),
    String? phaseStart,
    Value<String?> phaseEnd = const Value.absent(),
    Value<String?> conflictGroupId = const Value.absent(),
  }) => SchedulePhaseRow(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    doseAmount: doseAmount ?? this.doseAmount,
    frequency: frequency ?? this.frequency,
    period: period ?? this.period,
    periodUnit: periodUnit ?? this.periodUnit,
    daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
    timesOfDay: timesOfDay ?? this.timesOfDay,
    isPrn: isPrn ?? this.isPrn,
    prnReason: prnReason.present ? prnReason.value : this.prnReason,
    prnMaxFrequency: prnMaxFrequency.present
        ? prnMaxFrequency.value
        : this.prnMaxFrequency,
    phaseStart: phaseStart ?? this.phaseStart,
    phaseEnd: phaseEnd.present ? phaseEnd.value : this.phaseEnd,
    conflictGroupId: conflictGroupId.present
        ? conflictGroupId.value
        : this.conflictGroupId,
  );
  SchedulePhaseRow copyWithCompanion(SchedulePhaseCompanion data) {
    return SchedulePhaseRow(
      id: data.id.present ? data.id.value : this.id,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      period: data.period.present ? data.period.value : this.period,
      periodUnit: data.periodUnit.present
          ? data.periodUnit.value
          : this.periodUnit,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      timesOfDay: data.timesOfDay.present
          ? data.timesOfDay.value
          : this.timesOfDay,
      isPrn: data.isPrn.present ? data.isPrn.value : this.isPrn,
      prnReason: data.prnReason.present ? data.prnReason.value : this.prnReason,
      prnMaxFrequency: data.prnMaxFrequency.present
          ? data.prnMaxFrequency.value
          : this.prnMaxFrequency,
      phaseStart: data.phaseStart.present
          ? data.phaseStart.value
          : this.phaseStart,
      phaseEnd: data.phaseEnd.present ? data.phaseEnd.value : this.phaseEnd,
      conflictGroupId: data.conflictGroupId.present
          ? data.conflictGroupId.value
          : this.conflictGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchedulePhaseRow(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('frequency: $frequency, ')
          ..write('period: $period, ')
          ..write('periodUnit: $periodUnit, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('isPrn: $isPrn, ')
          ..write('prnReason: $prnReason, ')
          ..write('prnMaxFrequency: $prnMaxFrequency, ')
          ..write('phaseStart: $phaseStart, ')
          ..write('phaseEnd: $phaseEnd, ')
          ..write('conflictGroupId: $conflictGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    courseId,
    doseAmount,
    frequency,
    period,
    periodUnit,
    daysOfWeek,
    timesOfDay,
    isPrn,
    prnReason,
    prnMaxFrequency,
    phaseStart,
    phaseEnd,
    conflictGroupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchedulePhaseRow &&
          other.id == this.id &&
          other.courseId == this.courseId &&
          other.doseAmount == this.doseAmount &&
          other.frequency == this.frequency &&
          other.period == this.period &&
          other.periodUnit == this.periodUnit &&
          other.daysOfWeek == this.daysOfWeek &&
          other.timesOfDay == this.timesOfDay &&
          other.isPrn == this.isPrn &&
          other.prnReason == this.prnReason &&
          other.prnMaxFrequency == this.prnMaxFrequency &&
          other.phaseStart == this.phaseStart &&
          other.phaseEnd == this.phaseEnd &&
          other.conflictGroupId == this.conflictGroupId);
}

class SchedulePhaseCompanion extends UpdateCompanion<SchedulePhaseRow> {
  final Value<String> id;
  final Value<String> courseId;
  final Value<String> doseAmount;
  final Value<int> frequency;
  final Value<int> period;
  final Value<String> periodUnit;
  final Value<String?> daysOfWeek;
  final Value<String> timesOfDay;
  final Value<int> isPrn;
  final Value<String?> prnReason;
  final Value<String?> prnMaxFrequency;
  final Value<String> phaseStart;
  final Value<String?> phaseEnd;
  final Value<String?> conflictGroupId;
  final Value<int> rowid;
  const SchedulePhaseCompanion({
    this.id = const Value.absent(),
    this.courseId = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.frequency = const Value.absent(),
    this.period = const Value.absent(),
    this.periodUnit = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.timesOfDay = const Value.absent(),
    this.isPrn = const Value.absent(),
    this.prnReason = const Value.absent(),
    this.prnMaxFrequency = const Value.absent(),
    this.phaseStart = const Value.absent(),
    this.phaseEnd = const Value.absent(),
    this.conflictGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulePhaseCompanion.insert({
    required String id,
    required String courseId,
    required String doseAmount,
    required int frequency,
    required int period,
    required String periodUnit,
    this.daysOfWeek = const Value.absent(),
    required String timesOfDay,
    this.isPrn = const Value.absent(),
    this.prnReason = const Value.absent(),
    this.prnMaxFrequency = const Value.absent(),
    required String phaseStart,
    this.phaseEnd = const Value.absent(),
    this.conflictGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       courseId = Value(courseId),
       doseAmount = Value(doseAmount),
       frequency = Value(frequency),
       period = Value(period),
       periodUnit = Value(periodUnit),
       timesOfDay = Value(timesOfDay),
       phaseStart = Value(phaseStart);
  static Insertable<SchedulePhaseRow> custom({
    Expression<String>? id,
    Expression<String>? courseId,
    Expression<String>? doseAmount,
    Expression<int>? frequency,
    Expression<int>? period,
    Expression<String>? periodUnit,
    Expression<String>? daysOfWeek,
    Expression<String>? timesOfDay,
    Expression<int>? isPrn,
    Expression<String>? prnReason,
    Expression<String>? prnMaxFrequency,
    Expression<String>? phaseStart,
    Expression<String>? phaseEnd,
    Expression<String>? conflictGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (courseId != null) 'course_id': courseId,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (frequency != null) 'frequency': frequency,
      if (period != null) 'period': period,
      if (periodUnit != null) 'period_unit': periodUnit,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (timesOfDay != null) 'times_of_day': timesOfDay,
      if (isPrn != null) 'is_prn': isPrn,
      if (prnReason != null) 'prn_reason': prnReason,
      if (prnMaxFrequency != null) 'prn_max_frequency': prnMaxFrequency,
      if (phaseStart != null) 'phase_start': phaseStart,
      if (phaseEnd != null) 'phase_end': phaseEnd,
      if (conflictGroupId != null) 'conflict_group_id': conflictGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulePhaseCompanion copyWith({
    Value<String>? id,
    Value<String>? courseId,
    Value<String>? doseAmount,
    Value<int>? frequency,
    Value<int>? period,
    Value<String>? periodUnit,
    Value<String?>? daysOfWeek,
    Value<String>? timesOfDay,
    Value<int>? isPrn,
    Value<String?>? prnReason,
    Value<String?>? prnMaxFrequency,
    Value<String>? phaseStart,
    Value<String?>? phaseEnd,
    Value<String?>? conflictGroupId,
    Value<int>? rowid,
  }) {
    return SchedulePhaseCompanion(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      doseAmount: doseAmount ?? this.doseAmount,
      frequency: frequency ?? this.frequency,
      period: period ?? this.period,
      periodUnit: periodUnit ?? this.periodUnit,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      isPrn: isPrn ?? this.isPrn,
      prnReason: prnReason ?? this.prnReason,
      prnMaxFrequency: prnMaxFrequency ?? this.prnMaxFrequency,
      phaseStart: phaseStart ?? this.phaseStart,
      phaseEnd: phaseEnd ?? this.phaseEnd,
      conflictGroupId: conflictGroupId ?? this.conflictGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<String>(doseAmount.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (period.present) {
      map['period'] = Variable<int>(period.value);
    }
    if (periodUnit.present) {
      map['period_unit'] = Variable<String>(periodUnit.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (timesOfDay.present) {
      map['times_of_day'] = Variable<String>(timesOfDay.value);
    }
    if (isPrn.present) {
      map['is_prn'] = Variable<int>(isPrn.value);
    }
    if (prnReason.present) {
      map['prn_reason'] = Variable<String>(prnReason.value);
    }
    if (prnMaxFrequency.present) {
      map['prn_max_frequency'] = Variable<String>(prnMaxFrequency.value);
    }
    if (phaseStart.present) {
      map['phase_start'] = Variable<String>(phaseStart.value);
    }
    if (phaseEnd.present) {
      map['phase_end'] = Variable<String>(phaseEnd.value);
    }
    if (conflictGroupId.present) {
      map['conflict_group_id'] = Variable<String>(conflictGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulePhaseCompanion(')
          ..write('id: $id, ')
          ..write('courseId: $courseId, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('frequency: $frequency, ')
          ..write('period: $period, ')
          ..write('periodUnit: $periodUnit, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('isPrn: $isPrn, ')
          ..write('prnReason: $prnReason, ')
          ..write('prnMaxFrequency: $prnMaxFrequency, ')
          ..write('phaseStart: $phaseStart, ')
          ..write('phaseEnd: $phaseEnd, ')
          ..write('conflictGroupId: $conflictGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AllergyRecord extends Table
    with TableInfo<AllergyRecord, AllergyRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AllergyRecord(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES person(id)',
  );
  static const VerificationMeta _substanceMeta = const VerificationMeta(
    'substance',
  );
  late final GeneratedColumn<String> substance = GeneratedColumn<String>(
    'substance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _reactionMeta = const VerificationMeta(
    'reaction',
  );
  late final GeneratedColumn<String> reaction = GeneratedColumn<String>(
    'reaction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _certaintyMeta = const VerificationMeta(
    'certainty',
  );
  late final GeneratedColumn<String> certainty = GeneratedColumn<String>(
    'certainty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    substance,
    reaction,
    severity,
    certainty,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'allergy_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<AllergyRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('substance')) {
      context.handle(
        _substanceMeta,
        substance.isAcceptableOrUnknown(data['substance']!, _substanceMeta),
      );
    } else if (isInserting) {
      context.missing(_substanceMeta);
    }
    if (data.containsKey('reaction')) {
      context.handle(
        _reactionMeta,
        reaction.isAcceptableOrUnknown(data['reaction']!, _reactionMeta),
      );
    } else if (isInserting) {
      context.missing(_reactionMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('certainty')) {
      context.handle(
        _certaintyMeta,
        certainty.isAcceptableOrUnknown(data['certainty']!, _certaintyMeta),
      );
    } else if (isInserting) {
      context.missing(_certaintyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AllergyRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AllergyRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      substance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}substance'],
      )!,
      reaction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reaction'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      ),
      certainty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certainty'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  AllergyRecord createAlias(String alias) {
    return AllergyRecord(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AllergyRecordRow extends DataClass
    implements Insertable<AllergyRecordRow> {
  final String id;
  final String personId;
  final String substance;
  final String reaction;
  final String? severity;
  final String certainty;
  final String? notes;
  const AllergyRecordRow({
    required this.id,
    required this.personId,
    required this.substance,
    required this.reaction,
    this.severity,
    required this.certainty,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['substance'] = Variable<String>(substance);
    map['reaction'] = Variable<String>(reaction);
    if (!nullToAbsent || severity != null) {
      map['severity'] = Variable<String>(severity);
    }
    map['certainty'] = Variable<String>(certainty);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AllergyRecordCompanion toCompanion(bool nullToAbsent) {
    return AllergyRecordCompanion(
      id: Value(id),
      personId: Value(personId),
      substance: Value(substance),
      reaction: Value(reaction),
      severity: severity == null && nullToAbsent
          ? const Value.absent()
          : Value(severity),
      certainty: Value(certainty),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory AllergyRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AllergyRecordRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['person_id']),
      substance: serializer.fromJson<String>(json['substance']),
      reaction: serializer.fromJson<String>(json['reaction']),
      severity: serializer.fromJson<String?>(json['severity']),
      certainty: serializer.fromJson<String>(json['certainty']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'person_id': serializer.toJson<String>(personId),
      'substance': serializer.toJson<String>(substance),
      'reaction': serializer.toJson<String>(reaction),
      'severity': serializer.toJson<String?>(severity),
      'certainty': serializer.toJson<String>(certainty),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AllergyRecordRow copyWith({
    String? id,
    String? personId,
    String? substance,
    String? reaction,
    Value<String?> severity = const Value.absent(),
    String? certainty,
    Value<String?> notes = const Value.absent(),
  }) => AllergyRecordRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    substance: substance ?? this.substance,
    reaction: reaction ?? this.reaction,
    severity: severity.present ? severity.value : this.severity,
    certainty: certainty ?? this.certainty,
    notes: notes.present ? notes.value : this.notes,
  );
  AllergyRecordRow copyWithCompanion(AllergyRecordCompanion data) {
    return AllergyRecordRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      substance: data.substance.present ? data.substance.value : this.substance,
      reaction: data.reaction.present ? data.reaction.value : this.reaction,
      severity: data.severity.present ? data.severity.value : this.severity,
      certainty: data.certainty.present ? data.certainty.value : this.certainty,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AllergyRecordRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('substance: $substance, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('certainty: $certainty, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    substance,
    reaction,
    severity,
    certainty,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllergyRecordRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.substance == this.substance &&
          other.reaction == this.reaction &&
          other.severity == this.severity &&
          other.certainty == this.certainty &&
          other.notes == this.notes);
}

class AllergyRecordCompanion extends UpdateCompanion<AllergyRecordRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> substance;
  final Value<String> reaction;
  final Value<String?> severity;
  final Value<String> certainty;
  final Value<String?> notes;
  final Value<int> rowid;
  const AllergyRecordCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.substance = const Value.absent(),
    this.reaction = const Value.absent(),
    this.severity = const Value.absent(),
    this.certainty = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AllergyRecordCompanion.insert({
    required String id,
    required String personId,
    required String substance,
    required String reaction,
    this.severity = const Value.absent(),
    required String certainty,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       substance = Value(substance),
       reaction = Value(reaction),
       certainty = Value(certainty);
  static Insertable<AllergyRecordRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? substance,
    Expression<String>? reaction,
    Expression<String>? severity,
    Expression<String>? certainty,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (substance != null) 'substance': substance,
      if (reaction != null) 'reaction': reaction,
      if (severity != null) 'severity': severity,
      if (certainty != null) 'certainty': certainty,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AllergyRecordCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? substance,
    Value<String>? reaction,
    Value<String?>? severity,
    Value<String>? certainty,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return AllergyRecordCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      substance: substance ?? this.substance,
      reaction: reaction ?? this.reaction,
      severity: severity ?? this.severity,
      certainty: certainty ?? this.certainty,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (substance.present) {
      map['substance'] = Variable<String>(substance.value);
    }
    if (reaction.present) {
      map['reaction'] = Variable<String>(reaction.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (certainty.present) {
      map['certainty'] = Variable<String>(certainty.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AllergyRecordCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('substance: $substance, ')
          ..write('reaction: $reaction, ')
          ..write('severity: $severity, ')
          ..write('certainty: $certainty, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FamilyHistoryEntry extends Table
    with TableInfo<FamilyHistoryEntry, FamilyHistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FamilyHistoryEntry(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES person(id)',
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _conditionTextMeta = const VerificationMeta(
    'conditionText',
  );
  late final GeneratedColumn<String> conditionText = GeneratedColumn<String>(
    'condition_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _conditionCodeMeta = const VerificationMeta(
    'conditionCode',
  );
  late final GeneratedColumn<String> conditionCode = GeneratedColumn<String>(
    'condition_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _onsetAgeApproxMeta = const VerificationMeta(
    'onsetAgeApprox',
  );
  late final GeneratedColumn<int> onsetAgeApprox = GeneratedColumn<int>(
    'onset_age_approx',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _certaintyMeta = const VerificationMeta(
    'certainty',
  );
  late final GeneratedColumn<String> certainty = GeneratedColumn<String>(
    'certainty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    relationship,
    conditionText,
    conditionCode,
    onsetAgeApprox,
    outcome,
    certainty,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_history_entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyHistoryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('condition_text')) {
      context.handle(
        _conditionTextMeta,
        conditionText.isAcceptableOrUnknown(
          data['condition_text']!,
          _conditionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conditionTextMeta);
    }
    if (data.containsKey('condition_code')) {
      context.handle(
        _conditionCodeMeta,
        conditionCode.isAcceptableOrUnknown(
          data['condition_code']!,
          _conditionCodeMeta,
        ),
      );
    }
    if (data.containsKey('onset_age_approx')) {
      context.handle(
        _onsetAgeApproxMeta,
        onsetAgeApprox.isAcceptableOrUnknown(
          data['onset_age_approx']!,
          _onsetAgeApproxMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('certainty')) {
      context.handle(
        _certaintyMeta,
        certainty.isAcceptableOrUnknown(data['certainty']!, _certaintyMeta),
      );
    } else if (isInserting) {
      context.missing(_certaintyMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyHistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyHistoryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      conditionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_text'],
      )!,
      conditionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_code'],
      ),
      onsetAgeApprox: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onset_age_approx'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      certainty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certainty'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  FamilyHistoryEntry createAlias(String alias) {
    return FamilyHistoryEntry(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FamilyHistoryEntryRow extends DataClass
    implements Insertable<FamilyHistoryEntryRow> {
  final String id;
  final String personId;
  final String relationship;
  final String conditionText;
  final String? conditionCode;
  final int? onsetAgeApprox;
  final String? outcome;
  final String certainty;
  final String? notes;
  const FamilyHistoryEntryRow({
    required this.id,
    required this.personId,
    required this.relationship,
    required this.conditionText,
    this.conditionCode,
    this.onsetAgeApprox,
    this.outcome,
    required this.certainty,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['relationship'] = Variable<String>(relationship);
    map['condition_text'] = Variable<String>(conditionText);
    if (!nullToAbsent || conditionCode != null) {
      map['condition_code'] = Variable<String>(conditionCode);
    }
    if (!nullToAbsent || onsetAgeApprox != null) {
      map['onset_age_approx'] = Variable<int>(onsetAgeApprox);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    map['certainty'] = Variable<String>(certainty);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  FamilyHistoryEntryCompanion toCompanion(bool nullToAbsent) {
    return FamilyHistoryEntryCompanion(
      id: Value(id),
      personId: Value(personId),
      relationship: Value(relationship),
      conditionText: Value(conditionText),
      conditionCode: conditionCode == null && nullToAbsent
          ? const Value.absent()
          : Value(conditionCode),
      onsetAgeApprox: onsetAgeApprox == null && nullToAbsent
          ? const Value.absent()
          : Value(onsetAgeApprox),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      certainty: Value(certainty),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory FamilyHistoryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyHistoryEntryRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['person_id']),
      relationship: serializer.fromJson<String>(json['relationship']),
      conditionText: serializer.fromJson<String>(json['condition_text']),
      conditionCode: serializer.fromJson<String?>(json['condition_code']),
      onsetAgeApprox: serializer.fromJson<int?>(json['onset_age_approx']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      certainty: serializer.fromJson<String>(json['certainty']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'person_id': serializer.toJson<String>(personId),
      'relationship': serializer.toJson<String>(relationship),
      'condition_text': serializer.toJson<String>(conditionText),
      'condition_code': serializer.toJson<String?>(conditionCode),
      'onset_age_approx': serializer.toJson<int?>(onsetAgeApprox),
      'outcome': serializer.toJson<String?>(outcome),
      'certainty': serializer.toJson<String>(certainty),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  FamilyHistoryEntryRow copyWith({
    String? id,
    String? personId,
    String? relationship,
    String? conditionText,
    Value<String?> conditionCode = const Value.absent(),
    Value<int?> onsetAgeApprox = const Value.absent(),
    Value<String?> outcome = const Value.absent(),
    String? certainty,
    Value<String?> notes = const Value.absent(),
  }) => FamilyHistoryEntryRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    relationship: relationship ?? this.relationship,
    conditionText: conditionText ?? this.conditionText,
    conditionCode: conditionCode.present
        ? conditionCode.value
        : this.conditionCode,
    onsetAgeApprox: onsetAgeApprox.present
        ? onsetAgeApprox.value
        : this.onsetAgeApprox,
    outcome: outcome.present ? outcome.value : this.outcome,
    certainty: certainty ?? this.certainty,
    notes: notes.present ? notes.value : this.notes,
  );
  FamilyHistoryEntryRow copyWithCompanion(FamilyHistoryEntryCompanion data) {
    return FamilyHistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      conditionText: data.conditionText.present
          ? data.conditionText.value
          : this.conditionText,
      conditionCode: data.conditionCode.present
          ? data.conditionCode.value
          : this.conditionCode,
      onsetAgeApprox: data.onsetAgeApprox.present
          ? data.onsetAgeApprox.value
          : this.onsetAgeApprox,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      certainty: data.certainty.present ? data.certainty.value : this.certainty,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyHistoryEntryRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relationship: $relationship, ')
          ..write('conditionText: $conditionText, ')
          ..write('conditionCode: $conditionCode, ')
          ..write('onsetAgeApprox: $onsetAgeApprox, ')
          ..write('outcome: $outcome, ')
          ..write('certainty: $certainty, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    personId,
    relationship,
    conditionText,
    conditionCode,
    onsetAgeApprox,
    outcome,
    certainty,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyHistoryEntryRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.relationship == this.relationship &&
          other.conditionText == this.conditionText &&
          other.conditionCode == this.conditionCode &&
          other.onsetAgeApprox == this.onsetAgeApprox &&
          other.outcome == this.outcome &&
          other.certainty == this.certainty &&
          other.notes == this.notes);
}

class FamilyHistoryEntryCompanion
    extends UpdateCompanion<FamilyHistoryEntryRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> relationship;
  final Value<String> conditionText;
  final Value<String?> conditionCode;
  final Value<int?> onsetAgeApprox;
  final Value<String?> outcome;
  final Value<String> certainty;
  final Value<String?> notes;
  final Value<int> rowid;
  const FamilyHistoryEntryCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.relationship = const Value.absent(),
    this.conditionText = const Value.absent(),
    this.conditionCode = const Value.absent(),
    this.onsetAgeApprox = const Value.absent(),
    this.outcome = const Value.absent(),
    this.certainty = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyHistoryEntryCompanion.insert({
    required String id,
    required String personId,
    required String relationship,
    required String conditionText,
    this.conditionCode = const Value.absent(),
    this.onsetAgeApprox = const Value.absent(),
    this.outcome = const Value.absent(),
    required String certainty,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       relationship = Value(relationship),
       conditionText = Value(conditionText),
       certainty = Value(certainty);
  static Insertable<FamilyHistoryEntryRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? relationship,
    Expression<String>? conditionText,
    Expression<String>? conditionCode,
    Expression<int>? onsetAgeApprox,
    Expression<String>? outcome,
    Expression<String>? certainty,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (relationship != null) 'relationship': relationship,
      if (conditionText != null) 'condition_text': conditionText,
      if (conditionCode != null) 'condition_code': conditionCode,
      if (onsetAgeApprox != null) 'onset_age_approx': onsetAgeApprox,
      if (outcome != null) 'outcome': outcome,
      if (certainty != null) 'certainty': certainty,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyHistoryEntryCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? relationship,
    Value<String>? conditionText,
    Value<String?>? conditionCode,
    Value<int?>? onsetAgeApprox,
    Value<String?>? outcome,
    Value<String>? certainty,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return FamilyHistoryEntryCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      relationship: relationship ?? this.relationship,
      conditionText: conditionText ?? this.conditionText,
      conditionCode: conditionCode ?? this.conditionCode,
      onsetAgeApprox: onsetAgeApprox ?? this.onsetAgeApprox,
      outcome: outcome ?? this.outcome,
      certainty: certainty ?? this.certainty,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (conditionText.present) {
      map['condition_text'] = Variable<String>(conditionText.value);
    }
    if (conditionCode.present) {
      map['condition_code'] = Variable<String>(conditionCode.value);
    }
    if (onsetAgeApprox.present) {
      map['onset_age_approx'] = Variable<int>(onsetAgeApprox.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (certainty.present) {
      map['certainty'] = Variable<String>(certainty.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyHistoryEntryCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('relationship: $relationship, ')
          ..write('conditionText: $conditionText, ')
          ..write('conditionCode: $conditionCode, ')
          ..write('onsetAgeApprox: $onsetAgeApprox, ')
          ..write('outcome: $outcome, ')
          ..write('certainty: $certainty, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Person extends Table with TableInfo<Person, PersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Person(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bloodGroupMeta = const VerificationMeta(
    'bloodGroup',
  );
  late final GeneratedColumn<String> bloodGroup = GeneratedColumn<String>(
    'blood_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    relationship,
    dateOfBirth,
    sex,
    bloodGroup,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('blood_group')) {
      context.handle(
        _bloodGroupMeta,
        bloodGroup.isAcceptableOrUnknown(data['blood_group']!, _bloodGroupMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      bloodGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_group'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Person createAlias(String alias) {
    return Person(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PersonRow extends DataClass implements Insertable<PersonRow> {
  final String id;
  final String displayName;
  final String relationship;
  final String? dateOfBirth;
  final String? sex;
  final String? bloodGroup;
  final int createdAt;
  const PersonRow({
    required this.id,
    required this.displayName,
    required this.relationship,
    this.dateOfBirth,
    this.sex,
    this.bloodGroup,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['relationship'] = Variable<String>(relationship);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || bloodGroup != null) {
      map['blood_group'] = Variable<String>(bloodGroup);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PersonCompanion toCompanion(bool nullToAbsent) {
    return PersonCompanion(
      id: Value(id),
      displayName: Value(displayName),
      relationship: Value(relationship),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      bloodGroup: bloodGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodGroup),
      createdAt: Value(createdAt),
    );
  }

  factory PersonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      relationship: serializer.fromJson<String>(json['relationship']),
      dateOfBirth: serializer.fromJson<String?>(json['date_of_birth']),
      sex: serializer.fromJson<String?>(json['sex']),
      bloodGroup: serializer.fromJson<String?>(json['blood_group']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'display_name': serializer.toJson<String>(displayName),
      'relationship': serializer.toJson<String>(relationship),
      'date_of_birth': serializer.toJson<String?>(dateOfBirth),
      'sex': serializer.toJson<String?>(sex),
      'blood_group': serializer.toJson<String?>(bloodGroup),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  PersonRow copyWith({
    String? id,
    String? displayName,
    String? relationship,
    Value<String?> dateOfBirth = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<String?> bloodGroup = const Value.absent(),
    int? createdAt,
  }) => PersonRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    relationship: relationship ?? this.relationship,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    sex: sex.present ? sex.value : this.sex,
    bloodGroup: bloodGroup.present ? bloodGroup.value : this.bloodGroup,
    createdAt: createdAt ?? this.createdAt,
  );
  PersonRow copyWithCompanion(PersonCompanion data) {
    return PersonRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      sex: data.sex.present ? data.sex.value : this.sex,
      bloodGroup: data.bloodGroup.present
          ? data.bloodGroup.value
          : this.bloodGroup,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('relationship: $relationship, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    relationship,
    dateOfBirth,
    sex,
    bloodGroup,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.relationship == this.relationship &&
          other.dateOfBirth == this.dateOfBirth &&
          other.sex == this.sex &&
          other.bloodGroup == this.bloodGroup &&
          other.createdAt == this.createdAt);
}

class PersonCompanion extends UpdateCompanion<PersonRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> relationship;
  final Value<String?> dateOfBirth;
  final Value<String?> sex;
  final Value<String?> bloodGroup;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PersonCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.relationship = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.sex = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonCompanion.insert({
    required String id,
    required String displayName,
    required String relationship,
    this.dateOfBirth = const Value.absent(),
    this.sex = const Value.absent(),
    this.bloodGroup = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       relationship = Value(relationship),
       createdAt = Value(createdAt);
  static Insertable<PersonRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? relationship,
    Expression<String>? dateOfBirth,
    Expression<String>? sex,
    Expression<String>? bloodGroup,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (relationship != null) 'relationship': relationship,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (sex != null) 'sex': sex,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? relationship,
    Value<String?>? dateOfBirth,
    Value<String?>? sex,
    Value<String?>? bloodGroup,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PersonCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (bloodGroup.present) {
      map['blood_group'] = Variable<String>(bloodGroup.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('relationship: $relationship, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('sex: $sex, ')
          ..write('bloodGroup: $bloodGroup, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EmergencyContact extends Table
    with TableInfo<EmergencyContact, EmergencyContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EmergencyContact(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES person(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    personId,
    name,
    phone,
    relationship,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_contact';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmergencyContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyContactRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      ),
    );
  }

  @override
  EmergencyContact createAlias(String alias) {
    return EmergencyContact(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EmergencyContactRow extends DataClass
    implements Insertable<EmergencyContactRow> {
  final String id;
  final String personId;
  final String name;
  final String phone;
  final String? relationship;
  const EmergencyContactRow({
    required this.id,
    required this.personId,
    required this.name,
    required this.phone,
    this.relationship,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person_id'] = Variable<String>(personId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || relationship != null) {
      map['relationship'] = Variable<String>(relationship);
    }
    return map;
  }

  EmergencyContactCompanion toCompanion(bool nullToAbsent) {
    return EmergencyContactCompanion(
      id: Value(id),
      personId: Value(personId),
      name: Value(name),
      phone: Value(phone),
      relationship: relationship == null && nullToAbsent
          ? const Value.absent()
          : Value(relationship),
    );
  }

  factory EmergencyContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyContactRow(
      id: serializer.fromJson<String>(json['id']),
      personId: serializer.fromJson<String>(json['person_id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      relationship: serializer.fromJson<String?>(json['relationship']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'person_id': serializer.toJson<String>(personId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'relationship': serializer.toJson<String?>(relationship),
    };
  }

  EmergencyContactRow copyWith({
    String? id,
    String? personId,
    String? name,
    String? phone,
    Value<String?> relationship = const Value.absent(),
  }) => EmergencyContactRow(
    id: id ?? this.id,
    personId: personId ?? this.personId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    relationship: relationship.present ? relationship.value : this.relationship,
  );
  EmergencyContactRow copyWithCompanion(EmergencyContactCompanion data) {
    return EmergencyContactRow(
      id: data.id.present ? data.id.value : this.id,
      personId: data.personId.present ? data.personId.value : this.personId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactRow(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relationship: $relationship')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, personId, name, phone, relationship);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyContactRow &&
          other.id == this.id &&
          other.personId == this.personId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.relationship == this.relationship);
}

class EmergencyContactCompanion extends UpdateCompanion<EmergencyContactRow> {
  final Value<String> id;
  final Value<String> personId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> relationship;
  final Value<int> rowid;
  const EmergencyContactCompanion({
    this.id = const Value.absent(),
    this.personId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.relationship = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmergencyContactCompanion.insert({
    required String id,
    required String personId,
    required String name,
    required String phone,
    this.relationship = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       personId = Value(personId),
       name = Value(name),
       phone = Value(phone);
  static Insertable<EmergencyContactRow> custom({
    Expression<String>? id,
    Expression<String>? personId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? relationship,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (personId != null) 'person_id': personId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (relationship != null) 'relationship': relationship,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmergencyContactCompanion copyWith({
    Value<String>? id,
    Value<String>? personId,
    Value<String>? name,
    Value<String>? phone,
    Value<String?>? relationship,
    Value<int>? rowid,
  }) {
    return EmergencyContactCompanion(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyContactCompanion(')
          ..write('id: $id, ')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('relationship: $relationship, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final MedicationCourse medicationCourse = MedicationCourse(this);
  late final SchedulePhase schedulePhase = SchedulePhase(this);
  late final AllergyRecord allergyRecord = AllergyRecord(this);
  late final FamilyHistoryEntry familyHistoryEntry = FamilyHistoryEntry(this);
  late final Person person = Person(this);
  late final EmergencyContact emergencyContact = EmergencyContact(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    medicationCourse,
    schedulePhase,
    allergyRecord,
    familyHistoryEntry,
    person,
    emergencyContact,
  ];
}

typedef $MedicationCourseCreateCompanionBuilder =
    MedicationCourseCompanion Function({
      required String id,
      required String personId,
      required String medicationName,
      required String status,
      required String startDate,
      Value<String?> endDate,
      Value<String?> prescriberName,
      Value<String?> reason,
      Value<int> rowid,
    });
typedef $MedicationCourseUpdateCompanionBuilder =
    MedicationCourseCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> medicationName,
      Value<String> status,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String?> prescriberName,
      Value<String?> reason,
      Value<int> rowid,
    });

final class $MedicationCourseReferences
    extends
        BaseReferences<_$AppDatabase, MedicationCourse, MedicationCourseRow> {
  $MedicationCourseReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<SchedulePhase, List<SchedulePhaseRow>>
  _schedulePhaseRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.schedulePhase,
    aliasName: 'medication_course__id__schedule_phase__course_id',
  );

  $SchedulePhaseProcessedTableManager get schedulePhaseRefs {
    final manager = $SchedulePhaseTableManager(
      $_db,
      $_db.schedulePhase,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_schedulePhaseRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $MedicationCourseFilterComposer
    extends Composer<_$AppDatabase, MedicationCourse> {
  $MedicationCourseFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prescriberName => $composableBuilder(
    column: $table.prescriberName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> schedulePhaseRefs(
    Expression<bool> Function($SchedulePhaseFilterComposer f) f,
  ) {
    final $SchedulePhaseFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedulePhase,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SchedulePhaseFilterComposer(
            $db: $db,
            $table: $db.schedulePhase,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationCourseOrderingComposer
    extends Composer<_$AppDatabase, MedicationCourse> {
  $MedicationCourseOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prescriberName => $composableBuilder(
    column: $table.prescriberName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MedicationCourseAnnotationComposer
    extends Composer<_$AppDatabase, MedicationCourse> {
  $MedicationCourseAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get prescriberName => $composableBuilder(
    column: $table.prescriberName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  Expression<T> schedulePhaseRefs<T extends Object>(
    Expression<T> Function($SchedulePhaseAnnotationComposer a) f,
  ) {
    final $SchedulePhaseAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedulePhase,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SchedulePhaseAnnotationComposer(
            $db: $db,
            $table: $db.schedulePhase,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $MedicationCourseTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          MedicationCourse,
          MedicationCourseRow,
          $MedicationCourseFilterComposer,
          $MedicationCourseOrderingComposer,
          $MedicationCourseAnnotationComposer,
          $MedicationCourseCreateCompanionBuilder,
          $MedicationCourseUpdateCompanionBuilder,
          (MedicationCourseRow, $MedicationCourseReferences),
          MedicationCourseRow,
          PrefetchHooks Function({bool schedulePhaseRefs})
        > {
  $MedicationCourseTableManager(_$AppDatabase db, MedicationCourse table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MedicationCourseFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MedicationCourseOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MedicationCourseAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> medicationName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> prescriberName = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationCourseCompanion(
                id: id,
                personId: personId,
                medicationName: medicationName,
                status: status,
                startDate: startDate,
                endDate: endDate,
                prescriberName: prescriberName,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String medicationName,
                required String status,
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                Value<String?> prescriberName = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationCourseCompanion.insert(
                id: id,
                personId: personId,
                medicationName: medicationName,
                status: status,
                startDate: startDate,
                endDate: endDate,
                prescriberName: prescriberName,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $MedicationCourseReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({schedulePhaseRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (schedulePhaseRefs) db.schedulePhase,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (schedulePhaseRefs)
                    await $_getPrefetchedData<
                      MedicationCourseRow,
                      MedicationCourse,
                      SchedulePhaseRow
                    >(
                      currentTable: table,
                      referencedTable: $MedicationCourseReferences
                          ._schedulePhaseRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $MedicationCourseReferences(
                            db,
                            table,
                            p0,
                          ).schedulePhaseRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.courseId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $MedicationCourseProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      MedicationCourse,
      MedicationCourseRow,
      $MedicationCourseFilterComposer,
      $MedicationCourseOrderingComposer,
      $MedicationCourseAnnotationComposer,
      $MedicationCourseCreateCompanionBuilder,
      $MedicationCourseUpdateCompanionBuilder,
      (MedicationCourseRow, $MedicationCourseReferences),
      MedicationCourseRow,
      PrefetchHooks Function({bool schedulePhaseRefs})
    >;
typedef $SchedulePhaseCreateCompanionBuilder =
    SchedulePhaseCompanion Function({
      required String id,
      required String courseId,
      required String doseAmount,
      required int frequency,
      required int period,
      required String periodUnit,
      Value<String?> daysOfWeek,
      required String timesOfDay,
      Value<int> isPrn,
      Value<String?> prnReason,
      Value<String?> prnMaxFrequency,
      required String phaseStart,
      Value<String?> phaseEnd,
      Value<String?> conflictGroupId,
      Value<int> rowid,
    });
typedef $SchedulePhaseUpdateCompanionBuilder =
    SchedulePhaseCompanion Function({
      Value<String> id,
      Value<String> courseId,
      Value<String> doseAmount,
      Value<int> frequency,
      Value<int> period,
      Value<String> periodUnit,
      Value<String?> daysOfWeek,
      Value<String> timesOfDay,
      Value<int> isPrn,
      Value<String?> prnReason,
      Value<String?> prnMaxFrequency,
      Value<String> phaseStart,
      Value<String?> phaseEnd,
      Value<String?> conflictGroupId,
      Value<int> rowid,
    });

final class $SchedulePhaseReferences
    extends BaseReferences<_$AppDatabase, SchedulePhase, SchedulePhaseRow> {
  $SchedulePhaseReferences(super.$_db, super.$_table, super.$_typedResult);

  static MedicationCourse _courseIdTable(_$AppDatabase db) => db
      .medicationCourse
      .createAlias('schedule_phase__course_id__medication_course__id');

  $MedicationCourseProcessedTableManager get courseId {
    final $_column = $_itemColumn<String>('course_id')!;

    final manager = $MedicationCourseTableManager(
      $_db,
      $_db.medicationCourse,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SchedulePhaseFilterComposer
    extends Composer<_$AppDatabase, SchedulePhase> {
  $SchedulePhaseFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodUnit => $composableBuilder(
    column: $table.periodUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPrn => $composableBuilder(
    column: $table.isPrn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prnReason => $composableBuilder(
    column: $table.prnReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prnMaxFrequency => $composableBuilder(
    column: $table.prnMaxFrequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phaseStart => $composableBuilder(
    column: $table.phaseStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phaseEnd => $composableBuilder(
    column: $table.phaseEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictGroupId => $composableBuilder(
    column: $table.conflictGroupId,
    builder: (column) => ColumnFilters(column),
  );

  $MedicationCourseFilterComposer get courseId {
    final $MedicationCourseFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.medicationCourse,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationCourseFilterComposer(
            $db: $db,
            $table: $db.medicationCourse,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SchedulePhaseOrderingComposer
    extends Composer<_$AppDatabase, SchedulePhase> {
  $SchedulePhaseOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodUnit => $composableBuilder(
    column: $table.periodUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPrn => $composableBuilder(
    column: $table.isPrn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prnReason => $composableBuilder(
    column: $table.prnReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prnMaxFrequency => $composableBuilder(
    column: $table.prnMaxFrequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phaseStart => $composableBuilder(
    column: $table.phaseStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phaseEnd => $composableBuilder(
    column: $table.phaseEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictGroupId => $composableBuilder(
    column: $table.conflictGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  $MedicationCourseOrderingComposer get courseId {
    final $MedicationCourseOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.medicationCourse,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationCourseOrderingComposer(
            $db: $db,
            $table: $db.medicationCourse,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SchedulePhaseAnnotationComposer
    extends Composer<_$AppDatabase, SchedulePhase> {
  $SchedulePhaseAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get periodUnit => $composableBuilder(
    column: $table.periodUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isPrn =>
      $composableBuilder(column: $table.isPrn, builder: (column) => column);

  GeneratedColumn<String> get prnReason =>
      $composableBuilder(column: $table.prnReason, builder: (column) => column);

  GeneratedColumn<String> get prnMaxFrequency => $composableBuilder(
    column: $table.prnMaxFrequency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phaseStart => $composableBuilder(
    column: $table.phaseStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phaseEnd =>
      $composableBuilder(column: $table.phaseEnd, builder: (column) => column);

  GeneratedColumn<String> get conflictGroupId => $composableBuilder(
    column: $table.conflictGroupId,
    builder: (column) => column,
  );

  $MedicationCourseAnnotationComposer get courseId {
    final $MedicationCourseAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.medicationCourse,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $MedicationCourseAnnotationComposer(
            $db: $db,
            $table: $db.medicationCourse,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SchedulePhaseTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SchedulePhase,
          SchedulePhaseRow,
          $SchedulePhaseFilterComposer,
          $SchedulePhaseOrderingComposer,
          $SchedulePhaseAnnotationComposer,
          $SchedulePhaseCreateCompanionBuilder,
          $SchedulePhaseUpdateCompanionBuilder,
          (SchedulePhaseRow, $SchedulePhaseReferences),
          SchedulePhaseRow,
          PrefetchHooks Function({bool courseId})
        > {
  $SchedulePhaseTableManager(_$AppDatabase db, SchedulePhase table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SchedulePhaseFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SchedulePhaseOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SchedulePhaseAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> doseAmount = const Value.absent(),
                Value<int> frequency = const Value.absent(),
                Value<int> period = const Value.absent(),
                Value<String> periodUnit = const Value.absent(),
                Value<String?> daysOfWeek = const Value.absent(),
                Value<String> timesOfDay = const Value.absent(),
                Value<int> isPrn = const Value.absent(),
                Value<String?> prnReason = const Value.absent(),
                Value<String?> prnMaxFrequency = const Value.absent(),
                Value<String> phaseStart = const Value.absent(),
                Value<String?> phaseEnd = const Value.absent(),
                Value<String?> conflictGroupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulePhaseCompanion(
                id: id,
                courseId: courseId,
                doseAmount: doseAmount,
                frequency: frequency,
                period: period,
                periodUnit: periodUnit,
                daysOfWeek: daysOfWeek,
                timesOfDay: timesOfDay,
                isPrn: isPrn,
                prnReason: prnReason,
                prnMaxFrequency: prnMaxFrequency,
                phaseStart: phaseStart,
                phaseEnd: phaseEnd,
                conflictGroupId: conflictGroupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String courseId,
                required String doseAmount,
                required int frequency,
                required int period,
                required String periodUnit,
                Value<String?> daysOfWeek = const Value.absent(),
                required String timesOfDay,
                Value<int> isPrn = const Value.absent(),
                Value<String?> prnReason = const Value.absent(),
                Value<String?> prnMaxFrequency = const Value.absent(),
                required String phaseStart,
                Value<String?> phaseEnd = const Value.absent(),
                Value<String?> conflictGroupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulePhaseCompanion.insert(
                id: id,
                courseId: courseId,
                doseAmount: doseAmount,
                frequency: frequency,
                period: period,
                periodUnit: periodUnit,
                daysOfWeek: daysOfWeek,
                timesOfDay: timesOfDay,
                isPrn: isPrn,
                prnReason: prnReason,
                prnMaxFrequency: prnMaxFrequency,
                phaseStart: phaseStart,
                phaseEnd: phaseEnd,
                conflictGroupId: conflictGroupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $SchedulePhaseReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $SchedulePhaseReferences
                                    ._courseIdTable(db),
                                referencedColumn: $SchedulePhaseReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SchedulePhaseProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SchedulePhase,
      SchedulePhaseRow,
      $SchedulePhaseFilterComposer,
      $SchedulePhaseOrderingComposer,
      $SchedulePhaseAnnotationComposer,
      $SchedulePhaseCreateCompanionBuilder,
      $SchedulePhaseUpdateCompanionBuilder,
      (SchedulePhaseRow, $SchedulePhaseReferences),
      SchedulePhaseRow,
      PrefetchHooks Function({bool courseId})
    >;
typedef $AllergyRecordCreateCompanionBuilder =
    AllergyRecordCompanion Function({
      required String id,
      required String personId,
      required String substance,
      required String reaction,
      Value<String?> severity,
      required String certainty,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $AllergyRecordUpdateCompanionBuilder =
    AllergyRecordCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> substance,
      Value<String> reaction,
      Value<String?> severity,
      Value<String> certainty,
      Value<String?> notes,
      Value<int> rowid,
    });

class $AllergyRecordFilterComposer
    extends Composer<_$AppDatabase, AllergyRecord> {
  $AllergyRecordFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get substance => $composableBuilder(
    column: $table.substance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certainty => $composableBuilder(
    column: $table.certainty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $AllergyRecordOrderingComposer
    extends Composer<_$AppDatabase, AllergyRecord> {
  $AllergyRecordOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get substance => $composableBuilder(
    column: $table.substance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reaction => $composableBuilder(
    column: $table.reaction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certainty => $composableBuilder(
    column: $table.certainty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AllergyRecordAnnotationComposer
    extends Composer<_$AppDatabase, AllergyRecord> {
  $AllergyRecordAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get substance =>
      $composableBuilder(column: $table.substance, builder: (column) => column);

  GeneratedColumn<String> get reaction =>
      $composableBuilder(column: $table.reaction, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get certainty =>
      $composableBuilder(column: $table.certainty, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $AllergyRecordTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AllergyRecord,
          AllergyRecordRow,
          $AllergyRecordFilterComposer,
          $AllergyRecordOrderingComposer,
          $AllergyRecordAnnotationComposer,
          $AllergyRecordCreateCompanionBuilder,
          $AllergyRecordUpdateCompanionBuilder,
          (
            AllergyRecordRow,
            BaseReferences<_$AppDatabase, AllergyRecord, AllergyRecordRow>,
          ),
          AllergyRecordRow,
          PrefetchHooks Function()
        > {
  $AllergyRecordTableManager(_$AppDatabase db, AllergyRecord table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AllergyRecordFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AllergyRecordOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AllergyRecordAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> substance = const Value.absent(),
                Value<String> reaction = const Value.absent(),
                Value<String?> severity = const Value.absent(),
                Value<String> certainty = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllergyRecordCompanion(
                id: id,
                personId: personId,
                substance: substance,
                reaction: reaction,
                severity: severity,
                certainty: certainty,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String substance,
                required String reaction,
                Value<String?> severity = const Value.absent(),
                required String certainty,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AllergyRecordCompanion.insert(
                id: id,
                personId: personId,
                substance: substance,
                reaction: reaction,
                severity: severity,
                certainty: certainty,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AllergyRecordProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AllergyRecord,
      AllergyRecordRow,
      $AllergyRecordFilterComposer,
      $AllergyRecordOrderingComposer,
      $AllergyRecordAnnotationComposer,
      $AllergyRecordCreateCompanionBuilder,
      $AllergyRecordUpdateCompanionBuilder,
      (
        AllergyRecordRow,
        BaseReferences<_$AppDatabase, AllergyRecord, AllergyRecordRow>,
      ),
      AllergyRecordRow,
      PrefetchHooks Function()
    >;
typedef $FamilyHistoryEntryCreateCompanionBuilder =
    FamilyHistoryEntryCompanion Function({
      required String id,
      required String personId,
      required String relationship,
      required String conditionText,
      Value<String?> conditionCode,
      Value<int?> onsetAgeApprox,
      Value<String?> outcome,
      required String certainty,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $FamilyHistoryEntryUpdateCompanionBuilder =
    FamilyHistoryEntryCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> relationship,
      Value<String> conditionText,
      Value<String?> conditionCode,
      Value<int?> onsetAgeApprox,
      Value<String?> outcome,
      Value<String> certainty,
      Value<String?> notes,
      Value<int> rowid,
    });

class $FamilyHistoryEntryFilterComposer
    extends Composer<_$AppDatabase, FamilyHistoryEntry> {
  $FamilyHistoryEntryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionText => $composableBuilder(
    column: $table.conditionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionCode => $composableBuilder(
    column: $table.conditionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onsetAgeApprox => $composableBuilder(
    column: $table.onsetAgeApprox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certainty => $composableBuilder(
    column: $table.certainty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $FamilyHistoryEntryOrderingComposer
    extends Composer<_$AppDatabase, FamilyHistoryEntry> {
  $FamilyHistoryEntryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionText => $composableBuilder(
    column: $table.conditionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionCode => $composableBuilder(
    column: $table.conditionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onsetAgeApprox => $composableBuilder(
    column: $table.onsetAgeApprox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certainty => $composableBuilder(
    column: $table.certainty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FamilyHistoryEntryAnnotationComposer
    extends Composer<_$AppDatabase, FamilyHistoryEntry> {
  $FamilyHistoryEntryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conditionText => $composableBuilder(
    column: $table.conditionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conditionCode => $composableBuilder(
    column: $table.conditionCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get onsetAgeApprox => $composableBuilder(
    column: $table.onsetAgeApprox,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get certainty =>
      $composableBuilder(column: $table.certainty, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $FamilyHistoryEntryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          FamilyHistoryEntry,
          FamilyHistoryEntryRow,
          $FamilyHistoryEntryFilterComposer,
          $FamilyHistoryEntryOrderingComposer,
          $FamilyHistoryEntryAnnotationComposer,
          $FamilyHistoryEntryCreateCompanionBuilder,
          $FamilyHistoryEntryUpdateCompanionBuilder,
          (
            FamilyHistoryEntryRow,
            BaseReferences<
              _$AppDatabase,
              FamilyHistoryEntry,
              FamilyHistoryEntryRow
            >,
          ),
          FamilyHistoryEntryRow,
          PrefetchHooks Function()
        > {
  $FamilyHistoryEntryTableManager(_$AppDatabase db, FamilyHistoryEntry table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FamilyHistoryEntryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FamilyHistoryEntryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FamilyHistoryEntryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String> conditionText = const Value.absent(),
                Value<String?> conditionCode = const Value.absent(),
                Value<int?> onsetAgeApprox = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String> certainty = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyHistoryEntryCompanion(
                id: id,
                personId: personId,
                relationship: relationship,
                conditionText: conditionText,
                conditionCode: conditionCode,
                onsetAgeApprox: onsetAgeApprox,
                outcome: outcome,
                certainty: certainty,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String relationship,
                required String conditionText,
                Value<String?> conditionCode = const Value.absent(),
                Value<int?> onsetAgeApprox = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                required String certainty,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyHistoryEntryCompanion.insert(
                id: id,
                personId: personId,
                relationship: relationship,
                conditionText: conditionText,
                conditionCode: conditionCode,
                onsetAgeApprox: onsetAgeApprox,
                outcome: outcome,
                certainty: certainty,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FamilyHistoryEntryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      FamilyHistoryEntry,
      FamilyHistoryEntryRow,
      $FamilyHistoryEntryFilterComposer,
      $FamilyHistoryEntryOrderingComposer,
      $FamilyHistoryEntryAnnotationComposer,
      $FamilyHistoryEntryCreateCompanionBuilder,
      $FamilyHistoryEntryUpdateCompanionBuilder,
      (
        FamilyHistoryEntryRow,
        BaseReferences<
          _$AppDatabase,
          FamilyHistoryEntry,
          FamilyHistoryEntryRow
        >,
      ),
      FamilyHistoryEntryRow,
      PrefetchHooks Function()
    >;
typedef $PersonCreateCompanionBuilder =
    PersonCompanion Function({
      required String id,
      required String displayName,
      required String relationship,
      Value<String?> dateOfBirth,
      Value<String?> sex,
      Value<String?> bloodGroup,
      required int createdAt,
      Value<int> rowid,
    });
typedef $PersonUpdateCompanionBuilder =
    PersonCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> relationship,
      Value<String?> dateOfBirth,
      Value<String?> sex,
      Value<String?> bloodGroup,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $PersonReferences
    extends BaseReferences<_$AppDatabase, Person, PersonRow> {
  $PersonReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<EmergencyContact, List<EmergencyContactRow>>
  _emergencyContactRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.emergencyContact,
    aliasName: 'person__id__emergency_contact__person_id',
  );

  $EmergencyContactProcessedTableManager get emergencyContactRefs {
    final manager = $EmergencyContactTableManager(
      $_db,
      $_db.emergencyContact,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _emergencyContactRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $PersonFilterComposer extends Composer<_$AppDatabase, Person> {
  $PersonFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> emergencyContactRefs(
    Expression<bool> Function($EmergencyContactFilterComposer f) f,
  ) {
    final $EmergencyContactFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.emergencyContact,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EmergencyContactFilterComposer(
            $db: $db,
            $table: $db.emergencyContact,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PersonOrderingComposer extends Composer<_$AppDatabase, Person> {
  $PersonOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PersonAnnotationComposer extends Composer<_$AppDatabase, Person> {
  $PersonAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get bloodGroup => $composableBuilder(
    column: $table.bloodGroup,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> emergencyContactRefs<T extends Object>(
    Expression<T> Function($EmergencyContactAnnotationComposer a) f,
  ) {
    final $EmergencyContactAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.emergencyContact,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EmergencyContactAnnotationComposer(
            $db: $db,
            $table: $db.emergencyContact,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PersonTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Person,
          PersonRow,
          $PersonFilterComposer,
          $PersonOrderingComposer,
          $PersonAnnotationComposer,
          $PersonCreateCompanionBuilder,
          $PersonUpdateCompanionBuilder,
          (PersonRow, $PersonReferences),
          PersonRow,
          PrefetchHooks Function({bool emergencyContactRefs})
        > {
  $PersonTableManager(_$AppDatabase db, Person table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PersonFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PersonOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PersonAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonCompanion(
                id: id,
                displayName: displayName,
                relationship: relationship,
                dateOfBirth: dateOfBirth,
                sex: sex,
                bloodGroup: bloodGroup,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String relationship,
                Value<String?> dateOfBirth = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<String?> bloodGroup = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonCompanion.insert(
                id: id,
                displayName: displayName,
                relationship: relationship,
                dateOfBirth: dateOfBirth,
                sex: sex,
                bloodGroup: bloodGroup,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $PersonReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({emergencyContactRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (emergencyContactRefs) db.emergencyContact,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (emergencyContactRefs)
                    await $_getPrefetchedData<
                      PersonRow,
                      Person,
                      EmergencyContactRow
                    >(
                      currentTable: table,
                      referencedTable: $PersonReferences
                          ._emergencyContactRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $PersonReferences(db, table, p0).emergencyContactRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $PersonProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Person,
      PersonRow,
      $PersonFilterComposer,
      $PersonOrderingComposer,
      $PersonAnnotationComposer,
      $PersonCreateCompanionBuilder,
      $PersonUpdateCompanionBuilder,
      (PersonRow, $PersonReferences),
      PersonRow,
      PrefetchHooks Function({bool emergencyContactRefs})
    >;
typedef $EmergencyContactCreateCompanionBuilder =
    EmergencyContactCompanion Function({
      required String id,
      required String personId,
      required String name,
      required String phone,
      Value<String?> relationship,
      Value<int> rowid,
    });
typedef $EmergencyContactUpdateCompanionBuilder =
    EmergencyContactCompanion Function({
      Value<String> id,
      Value<String> personId,
      Value<String> name,
      Value<String> phone,
      Value<String?> relationship,
      Value<int> rowid,
    });

final class $EmergencyContactReferences
    extends
        BaseReferences<_$AppDatabase, EmergencyContact, EmergencyContactRow> {
  $EmergencyContactReferences(super.$_db, super.$_table, super.$_typedResult);

  static Person _personIdTable(_$AppDatabase db) =>
      db.person.createAlias('emergency_contact__person_id__person__id');

  $PersonProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $PersonTableManager(
      $_db,
      $_db.person,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EmergencyContactFilterComposer
    extends Composer<_$AppDatabase, EmergencyContact> {
  $EmergencyContactFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  $PersonFilterComposer get personId {
    final $PersonFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.person,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PersonFilterComposer(
            $db: $db,
            $table: $db.person,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EmergencyContactOrderingComposer
    extends Composer<_$AppDatabase, EmergencyContact> {
  $EmergencyContactOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  $PersonOrderingComposer get personId {
    final $PersonOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.person,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PersonOrderingComposer(
            $db: $db,
            $table: $db.person,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EmergencyContactAnnotationComposer
    extends Composer<_$AppDatabase, EmergencyContact> {
  $EmergencyContactAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  $PersonAnnotationComposer get personId {
    final $PersonAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.person,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PersonAnnotationComposer(
            $db: $db,
            $table: $db.person,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EmergencyContactTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          EmergencyContact,
          EmergencyContactRow,
          $EmergencyContactFilterComposer,
          $EmergencyContactOrderingComposer,
          $EmergencyContactAnnotationComposer,
          $EmergencyContactCreateCompanionBuilder,
          $EmergencyContactUpdateCompanionBuilder,
          (EmergencyContactRow, $EmergencyContactReferences),
          EmergencyContactRow,
          PrefetchHooks Function({bool personId})
        > {
  $EmergencyContactTableManager(_$AppDatabase db, EmergencyContact table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EmergencyContactFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EmergencyContactOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EmergencyContactAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> relationship = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmergencyContactCompanion(
                id: id,
                personId: personId,
                name: name,
                phone: phone,
                relationship: relationship,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String personId,
                required String name,
                required String phone,
                Value<String?> relationship = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmergencyContactCompanion.insert(
                id: id,
                personId: personId,
                name: name,
                phone: phone,
                relationship: relationship,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $EmergencyContactReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $EmergencyContactReferences
                                    ._personIdTable(db),
                                referencedColumn: $EmergencyContactReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EmergencyContactProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      EmergencyContact,
      EmergencyContactRow,
      $EmergencyContactFilterComposer,
      $EmergencyContactOrderingComposer,
      $EmergencyContactAnnotationComposer,
      $EmergencyContactCreateCompanionBuilder,
      $EmergencyContactUpdateCompanionBuilder,
      (EmergencyContactRow, $EmergencyContactReferences),
      EmergencyContactRow,
      PrefetchHooks Function({bool personId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $MedicationCourseTableManager get medicationCourse =>
      $MedicationCourseTableManager(_db, _db.medicationCourse);
  $SchedulePhaseTableManager get schedulePhase =>
      $SchedulePhaseTableManager(_db, _db.schedulePhase);
  $AllergyRecordTableManager get allergyRecord =>
      $AllergyRecordTableManager(_db, _db.allergyRecord);
  $FamilyHistoryEntryTableManager get familyHistoryEntry =>
      $FamilyHistoryEntryTableManager(_db, _db.familyHistoryEntry);
  $PersonTableManager get person => $PersonTableManager(_db, _db.person);
  $EmergencyContactTableManager get emergencyContact =>
      $EmergencyContactTableManager(_db, _db.emergencyContact);
}

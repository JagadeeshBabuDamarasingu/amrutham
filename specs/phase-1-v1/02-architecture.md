# Phase 1 (v1) — Architecture

This is the engineering design for phase 1. It assumes the reasoning behind every choice below (Flutter over Kotlin Multiplatform and fully-native; `drift`+`sqlite3` over Isar; `flutter_local_notifications` over `workmanager`) — the full framework decision record lives in the Obsidian vault (`amrutham-technical-spec.md` §14 and the research note's framework-investigation wave). This document is the "how," not the "why we chose this over the alternatives."

## 1. Repository structure (this repo)

```
amrutham/
├── apps/
│   └── mobile/                      # the Flutter app (already scaffolded)
│       ├── pubspec.yaml             # pin every dependency version explicitly
│       ├── lib/
│       │   ├── main.dart
│       │   ├── model/               # pure Dart data classes / sealed classes (§3)
│       │   ├── db/                  # drift schema + generated code (§4)
│       │   ├── vault/               # plain-file read/write engine (§5)
│       │   ├── reminder/            # flutter_local_notifications-based scheduling (§6)
│       │   ├── capture/             # document capture pipeline, tier 1 only this phase (§7)
│       │   ├── crypto/              # key management (§8)
│       │   ├── repository/          # use-case layer gluing the above — UI must go through this,
│       │   │                        #   never write to `db/` directly (see §5's vault-retrofit note)
│       │   └── ui/                  # Flutter widgets — kept thin, no business logic
│       ├── android/, ios/, ...      # platform folders (already scaffolded)
│       └── test/
│           ├── safety_invariant_test.dart
│           └── vault_roundtrip_test.dart
└── specs/                           # this folder
```

`sync/` and `fhir/` modules are **not** part of phase 1 — they're introduced in phase 2. Don't add networking dependencies to `pubspec.yaml` in this phase at all (see the non-negotiables in the specs README).

## 2. Tech stack & versions (phase 1 subset)

Pin exact versions; never an unpinned `^` on anything touching native code, encryption, or scheduling.

| Concern | Choice | Note |
|---|---|---|
| Framework | Flutter (Dart 3.x) | — |
| Local DB | `drift` + `sqlite3` (v3.10+), using the build-hook `source: sqlcipher` mode | **Not** `source: sqlite3mc` — a real benchmark found the generic SQLite3MultipleCiphers path is 3.81× slower than true SQLCipher on iOS (no hardware crypto acceleration). Not `sqlcipher_flutter_libs` — formally end-of-life. |
| Reminder scheduling | `flutter_local_notifications` | **Not** `workmanager`. Neither `WorkManager` nor `BGTaskScheduler` actually guarantees firing at an exact time — both are best-effort background-*work* APIs. The correct primitive on both platforms is an OS-level scheduled notification (`AlarmManager`+`NotificationCompat` on Android, `UNUserNotificationCenter` on iOS), which this package wraps correctly. No custom native code is needed for this. |
| Secure key storage | `flutter_secure_storage` | **Strict version-pinning + mandatory migration-test discipline**: this package has a documented, recurring history of migration-triggered data-loss/lockout bugs (not steady-state bugs). Never bump its major version without first running a full backup-then-restore test against production-shaped data. |
| Recovery/export key derivation | `package:cryptography` (or its fork `cryptography_plus`) — `Argon2id` class | Pure-Dart implementation, not natively accelerated for Argon2id specifically. Benchmark actual derivation time on a real low-end Android device before fixing memory/time cost parameters — do this before M1's onboarding flow locks them in. |
| YAML (read) | `yaml` (dart-lang) | Vault frontmatter format. |
| YAML (round-trip write, preserves formatting) | `yaml_edit` (dart-lang) | Combine with a manual split on the `---` delimiters so the Markdown body passes through untouched — no ready-made "frontmatter" package exists that does this for you. |
| ULID generation | `package:ulid` | Dependency-free, most-adopted. Its ~22-month-old last release matters less than usual since the ULID spec itself is frozen. |
| File I/O | `dart:io` | — |
| Serialization | `dart:convert` + hand-written `toJson`/`fromJson` (or `json_serializable` if codegen preferred) | — |

**Explicitly not included in phase 1**: `google_mlkit_text_recognition` (phase 2, with OCR), any SAF/iCloud sync package (phase 2), any FHIR export library (phase 2).

## 3. Core domain model (phase 1 entities)

IDs are ULIDs everywhere (lexicographically sortable, embeds a timestamp — avoids the "which field is created-at" ambiguity plain UUIDs have).

```dart
// model/person.dart
enum RelationshipType { self, child, parent, otherDependent }

class PersonProfile {
  final String id;
  final String displayName;
  final RelationshipType relationship;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? bloodGroup;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;
  const PersonProfile({ required this.id, required this.displayName, required this.relationship,
    this.dateOfBirth, this.sex, this.bloodGroup, this.emergencyContacts = const [], required this.createdAt });
}

// model/family_history.dart — "unverified recorded facts," never risk-scored
enum Certainty { confirmed, reported, suspected }

class FamilyHistoryEntry {
  final String id;
  final String personId;
  final String relationship;       // free text, KIN-ontology-informed but not enum-locked
  final String conditionText;      // free text always present
  final String? conditionCode;     // optional SNOMED code, enrichment only
  final int? onsetAgeApprox;
  final String? outcome;
  final Certainty certainty;
  final String? notes;
  const FamilyHistoryEntry({ required this.id, required this.personId, required this.relationship,
    required this.conditionText, this.conditionCode, this.onsetAgeApprox, this.outcome,
    required this.certainty, this.notes });
}

// model/medication.dart — the core loop
enum CourseStatus { active, completed, stopped, paused }
enum PeriodUnit { day, week, month }

class MedicationCourse {
  final String id;
  final String personId;
  final String medicationName;         // free text always the ground truth (India: no universal drug code)
  final List<DrugCode> medicationCoding; // optional enrichment, never required
  final CourseStatus status;
  final DateTime startDate;
  final DateTime? endDate;             // null = chronic/ongoing
  final String? prescriberName;
  final String? reason;
  const MedicationCourse({ required this.id, required this.personId, required this.medicationName,
    this.medicationCoding = const [], required this.status, required this.startDate,
    this.endDate, this.prescriberName, this.reason });
}
class DrugCode { final String system; final String code; final String display;
  const DrugCode({required this.system, required this.code, required this.display}); }

class SchedulePhase {
  final String id;
  final String courseId;
  final String doseAmount;
  final int frequency;
  final int period;
  final PeriodUnit periodUnit;
  final Set<int>? daysOfWeek;          // 1=Mon..7=Sun, for alternate-day dosing
  final List<String> timesOfDay;       // "HH:mm" strings
  final bool isPrn;
  final String? prnReason;
  final String? prnMaxFrequency;
  final DateTime phaseStart;
  final DateTime? phaseEnd;            // ordered phases with distinct ranges = taper support
  const SchedulePhase({ required this.id, required this.courseId, required this.doseAmount,
    required this.frequency, required this.period, required this.periodUnit,
    this.daysOfWeek, required this.timesOfDay, this.isPrn = false, this.prnReason,
    this.prnMaxFrequency, required this.phaseStart, this.phaseEnd });
}

// model/dose_log.dart — append-only
enum DoseStatus { taken, missed, late, prnTaken }

class DoseLogEntry {
  final String id;
  final String phaseId;
  final String deviceId;               // which device logged this (matters again once phase-2 sync exists)
  final DateTime? scheduledAt;         // null for PRN
  final DateTime loggedAt;             // audit timestamp — when the entry was actually written
  final DoseStatus status;
  const DoseLogEntry({ required this.id, required this.phaseId, required this.deviceId,
    this.scheduledAt, required this.loggedAt, required this.status });
  // Binding: no field here ever carries a streak count, a score, or a reward flag.
}

// model/document.dart — F4 tier 1 only this phase. The sealed hierarchy below is built
// now so tier 2 (phase 2) slots in without a rewrite — but DraftExtraction/ConfirmedExtraction
// are NOT used in phase 1; only FiledDocument is.
enum DocumentType { prescription, labReport, dischargeSummary, stripPhoto, other }

sealed class DocumentRecord {
  final String id;
  final String personId;
  final String filePath;   // pointer into the plain-files vault, never inline bytes in the DB
  final DateTime capturedAt;
  final DocumentType documentType;
  const DocumentRecord({ required this.id, required this.personId, required this.filePath,
    required this.capturedAt, required this.documentType });
}

/// The only variant used in phase 1. Can't fail — a filed photo with metadata, nothing extracted.
class FiledDocument extends DocumentRecord {
  final String? note;
  const FiledDocument({ required super.id, required super.personId, required super.filePath,
    required super.capturedAt, required super.documentType, this.note });
}

// DraftExtraction / ConfirmedExtraction are defined in phase 2's spec (F4 tier 2) — the sealed
// hierarchy here already reserves the shape so the reminder engine's type-safety guarantee
// (§6 below) holds from day one, even before OCR exists to produce a Draft.

// model/encounter.dart
enum VisitKind { opd, telehealth, inpatient }
enum TelehealthMode { video, audio, chat }

class Visit {
  final String id;
  final String personId;
  final VisitKind kind;
  final DateTime date;
  final DateTime? endTime;
  final String? facilityOrDoctorName;
  final String? specialty;
  final String? reasonForVisit;
  final String? diagnosesText;
  final List<String> attachmentIds;
  final String? episodeOfCareId;
  final HospitalizationDetail? hospitalization; // present only if kind == inpatient
  final TelehealthDetail? telehealth;           // present only if kind == telehealth
  const Visit({ required this.id, required this.personId, required this.kind, required this.date,
    this.endTime, this.facilityOrDoctorName, this.specialty, this.reasonForVisit,
    this.diagnosesText, this.attachmentIds = const [], this.episodeOfCareId,
    this.hospitalization, this.telehealth });
}
class HospitalizationDetail {
  final DateTime admitDate; final DateTime? dischargeDate;
  final String? facility; final String? ward; final String? attendingPhysician;
  final String? admitReason; final String? dischargeDisposition;
  final String? dischargeSummaryDocId;
  const HospitalizationDetail({ required this.admitDate, this.dischargeDate, this.facility,
    this.ward, this.attendingPhysician, this.admitReason, this.dischargeDisposition,
    this.dischargeSummaryDocId });
}
class TelehealthDetail {
  final String? platform; final TelehealthMode mode;
  final String? recordingDocId; // strictly opt-in, off by default
  const TelehealthDetail({ this.platform, required this.mode, this.recordingDocId });
}

class EpisodeOfCare {
  final String id; final String personId; final String label; // "Chemo course 2026", free text
  final String? type; final DateTime startDate; final DateTime? endDate;
  final String? primaryDiagnosisText;
  const EpisodeOfCare({ required this.id, required this.personId, required this.label,
    this.type, required this.startDate, this.endDate, this.primaryDiagnosisText });
}
```

Wrap IDs in `@JvmInline`-equivalent Dart extension types or simple value classes where practical (`PersonId`, `CourseId`, etc.) — prevents passing a `DocumentId` where a `PersonId` is expected, a real bug class in a schema this cross-referenced.

## 4. Database schema (drift)

The DB is a **rebuildable cache**, not the source of truth. Every table below must be derivable purely by re-reading the vault directory (§5) — if a rebuild-from-files procedure can't reconstruct a table, that table is modeling something that shouldn't exist yet, or the vault format is missing a field.

```sql
-- db/person.drift
CREATE TABLE person (
    id TEXT NOT NULL PRIMARY KEY,
    display_name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    date_of_birth TEXT,
    sex TEXT,
    blood_group TEXT,
    created_at INTEGER NOT NULL
);

-- db/family_history.drift
CREATE TABLE family_history_entry (
    id TEXT NOT NULL PRIMARY KEY,
    person_id TEXT NOT NULL REFERENCES person(id),
    relationship TEXT NOT NULL,
    condition_text TEXT NOT NULL,
    condition_code TEXT,
    onset_age_approx INTEGER,
    outcome TEXT,
    certainty TEXT NOT NULL,
    notes TEXT
);

-- db/medication.drift
CREATE TABLE medication_course (
    id TEXT NOT NULL PRIMARY KEY,
    person_id TEXT NOT NULL REFERENCES person(id),
    medication_name TEXT NOT NULL,
    status TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    prescriber_name TEXT,
    reason TEXT
);

CREATE TABLE schedule_phase (
    id TEXT NOT NULL PRIMARY KEY,
    course_id TEXT NOT NULL REFERENCES medication_course(id),
    dose_amount TEXT NOT NULL,
    frequency INTEGER NOT NULL,
    period INTEGER NOT NULL,
    period_unit TEXT NOT NULL,
    days_of_week TEXT,
    times_of_day TEXT NOT NULL,
    is_prn INTEGER NOT NULL DEFAULT 0,
    prn_reason TEXT,
    prn_max_frequency TEXT,
    phase_start TEXT NOT NULL,
    phase_end TEXT,
    conflict_group_id TEXT  -- reserved for phase 2's sync conflict rule; always NULL in phase 1
                            -- since single-device usage has no conflicts to represent yet
    -- NOTE: no "confirmed" column. Rows only exist here once confirmed — draft extractions
    -- (phase 2) never reach this table at all.
);

-- db/dose_log.drift — append-only
CREATE TABLE dose_log_entry (
    id TEXT NOT NULL PRIMARY KEY,
    phase_id TEXT NOT NULL REFERENCES schedule_phase(id),
    device_id TEXT NOT NULL,
    scheduled_at INTEGER,
    logged_at INTEGER NOT NULL,
    status TEXT NOT NULL
);

-- db/document.drift — phase 1 only ever writes record_kind = 'filed'
CREATE TABLE document_record (
    id TEXT NOT NULL PRIMARY KEY,
    person_id TEXT NOT NULL REFERENCES person(id),
    file_path TEXT NOT NULL,
    captured_at INTEGER NOT NULL,
    document_type TEXT NOT NULL,
    record_kind TEXT NOT NULL,  -- 'filed' this phase; 'draft_extraction' | 'confirmed_extraction' from phase 2
    note TEXT,
    resulting_course_id TEXT    -- set only when record_kind = 'confirmed_extraction' (phase 2)
);

-- db/encounter.drift
CREATE TABLE visit (
    id TEXT NOT NULL PRIMARY KEY,
    person_id TEXT NOT NULL REFERENCES person(id),
    kind TEXT NOT NULL,
    date TEXT NOT NULL,
    end_time INTEGER,
    facility_or_doctor_name TEXT,
    specialty TEXT,
    reason_for_visit TEXT,
    diagnoses_text TEXT,
    episode_of_care_id TEXT
);

CREATE TABLE hospitalization_detail (
    visit_id TEXT NOT NULL PRIMARY KEY REFERENCES visit(id),
    admit_date TEXT NOT NULL,
    discharge_date TEXT,
    facility TEXT, ward TEXT, attending_physician TEXT,
    admit_reason TEXT, discharge_disposition TEXT,
    discharge_summary_doc_id TEXT
);

CREATE TABLE telehealth_detail (
    visit_id TEXT NOT NULL PRIMARY KEY REFERENCES visit(id),
    platform TEXT, mode TEXT NOT NULL,
    recording_doc_id TEXT
);

CREATE TABLE episode_of_care (
    id TEXT NOT NULL PRIMARY KEY,
    person_id TEXT NOT NULL REFERENCES person(id),
    label TEXT NOT NULL,
    type TEXT,
    start_date TEXT NOT NULL,
    end_date TEXT,
    primary_diagnosis_text TEXT
);
```

### Encryption setup (concrete, verified recipe)

In `pubspec.yaml`:
```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher   # NOT sqlite3mc — see §2 above
```
This is a Dart build hook (stable since Dart 3.10, no experiment flag needed) — the correct precompiled native library is fetched/built automatically per platform, no manual `.so`/`.framework` bundling required. Set the key in drift's `setup` callback, which runs before drift touches the DB:
```dart
NativeDatabase.createInBackground(
  myDatabaseFile,
  setup: (rawDb) {
    rawDb.execute("PRAGMA key = '$passphrase';");
    assert(rawDb.select('PRAGMA cipher;').isNotEmpty); // NOT 'PRAGMA cipher_version' — that's
                                                        // SQLCipher-specific and silently returns
                                                        // empty even when encryption IS active.
  },
);
```
Remove any dependency on `sqlcipher_flutter_libs` — formally superseded as of drift 2.32.0+. iOS needs extra release-validation care: a documented Flutter-tooling-level (not sqlite3.dart) App Store Connect packaging gotcha requires a `flutter clean` before `Product > Archive` in Xcode.

`drift`'s code generator produces typed Dart query classes from the `.drift` files above — add named queries (`selectActiveNonConflictedPhasesForPerson`, `selectDoseLogByPerson`, etc.) incrementally as the repository layer needs them.

## 5. Plain-files vault format

```
<vault-root>/
├── amrutham.json                       # vault-level metadata: schema version, created-at
├── people/
│   └── <person-ulid>/
│       ├── profile.md
│       ├── family-history/<entry-ulid>.md
│       ├── allergies/<entry-ulid>.md
│       ├── medications/<course-ulid>/
│       │   ├── course.md               # frontmatter = MedicationCourse fields + embedded phase list
│       │   └── dose-log/<device-id>/shard-<counter>.jsonl   # append-only; phase-2 sync detail,
│       │                                                    #   but the file shape is fixed now
│       ├── documents/<document-ulid>/
│       │   ├── meta.md                 # frontmatter = DocumentRecord fields
│       │   └── original.<ext>          # the actual photo/file, opaque binary
│       └── visits/<visit-ulid>.md
└── exports/
    └── emergency-card-<person>.pdf
```

**Example — `profile.md`:**
```markdown
---
id: 01J8X3K9QZ7R2M4N5P6Q7R8S9T
displayName: Lakshmi
relationship: self
dateOfBirth: 1988-04-12
sex: female
bloodGroup: O+
createdAt: 2026-07-28T09:14:00Z
---
```

**Rebuild-from-files procedure**: on app start (or vault re-open), walk `people/**/*.md`, parse frontmatter via the `yaml` package into the domain model (§3), upsert into the drift database. This is the procedure exercised by the abandonment test (§11) in reverse.

**Why Markdown+YAML and not pure JSON**: matches F5's Obsidian-vault-friendly requirement directly — these files open sensibly in Obsidian or any text editor, not just this app.

## 6. The reminder engine — the single most important design decision in this phase

**Does not use the `workmanager` package.** Neither `WorkManager` (Android) nor `BGTaskScheduler` (iOS) actually guarantees firing at a specific time — Apple's own documentation states `BGTaskRequest.earliestBeginDate` means the system "doesn't guarantee launching the task at the specified date, only that it won't begin sooner"; `WorkManager`'s delay is a minimum, not exact, and periodic work has a 15-minute-minimum interval with a flex window. The correct primitive on both platforms is an **OS-level scheduled notification** — `AlarmManager`+`NotificationCompat` on Android, `UNUserNotificationCenter` on iOS — handled by the OS's own notification daemon (not the app process), which is why it survives app kill and isn't subject to iOS's background-execution throttling at all. `flutter_local_notifications` wraps exactly these two primitives correctly.

```dart
// reminder/reminder_repository.dart
class ReminderRepository {
  final FlutterLocalNotificationsPlugin _notifications;
  final ScheduleDao _scheduleDao; // drift-generated

  /// The ONLY entry point the app uses to arm reminders for a person.
  /// Reads only CONFIRMED, non-conflicted schedule phases — there is no code
  /// path here that can reach a DraftExtraction (phase 2) or an
  /// unresolved-conflict phase (conflict_group_id IS NOT NULL, phase 2 sync).
  Future<void> armRemindersForPerson(String personId) async {
    final phases = await _scheduleDao.activeNonConflictedPhasesForPerson(personId);
    for (final phase in phases) {
      await _notifications.zonedSchedule(
        phase.id.hashCode,
        'Take ${phase.medicationName}',
        phase.doseAmount,
        _nextInstanceOf(phase.timesOfDay.first),
        NotificationDetails(
          android: AndroidNotificationDetails('meds_channel', 'Medication Reminders'),
          // include the strip/prescription photo reference (FiledDocument.filePath for this
          // course, if one exists) per the elder persona's need
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily at this time —
                                                           // NOT one notification per future date
      );
    }
  }
}
```

**Concrete gotchas to build against from day one:**
- **Android 14+ exact-alarm permission**: `SCHEDULE_EXACT_ALARM` is denied by default for freshly-installed apps targeting API 33+. Check `AlarmManager.canScheduleExactAlarms()`; if false, prompt via `Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM`. **If this permission is revoked, `flutter_local_notifications` will not schedule the recurring exact-mode notification at all** — build an explicit fallback path (degrade to `AndroidScheduleMode.inexactAllowWhileIdle` with a visible in-app warning; silent degradation of a medication reminder is unacceptable).
- **Required Android manifest entries**: `RECEIVE_BOOT_COMPLETED` + `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, plus the plugin's own boot-rebroadcast receivers.
- **Notification count caps**: iOS caps pending notifications at 64; Samsung devices have a reported ~500-alarm `AlarmManager` cap. Both are avoided by using `matchDateTimeComponents: DateTimeComponents.time` (one standing recurring request per medication/time-slot) rather than enumerating individual future dates — do this from the start.
- **Toolchain requirement**: current `flutter_local_notifications` needs Gradle core library desugaring + `compileSdk 35+`/AGP 8.11.1+.
- **OEM battery optimization** (Xiaomi/Oppo/Vivo/Huawei/Samsung): no scheduling API on Android fully escapes this. Mitigation is user education (prompt to allowlist the app via `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`), not a code fix — which is why M2's acceptance criteria (see the phase overview) require real-device testing on an aggressive-OEM device before that milestone is considered done.

**Conflict rule (reserved now, activated in phase 2)**: when sync eventually detects two divergent `schedule_phase` rows for the same course from different devices, the merge must write **both** as separate rows tagged with a shared `conflict_group_id`, never pick one — and `activeNonConflictedPhasesForPerson` must exclude any phase with a non-null `conflict_group_id` from scheduling entirely until a human resolves it. Build the query to already respect this column even though phase 1 never populates it.

## 7. Document capture pipeline (F4 tier 1 only)

```dart
// capture/capture_repository.dart
class CaptureRepository {
  // The only method used in phase 1 — always available, cannot fail into a bad state.
  FiledDocument fileDocument(String imagePath, String personId, DocumentType type) { /* ... */ }

  // extractDraft() / confirmExtraction() belong to phase 2 (F4 tier 2) — do not implement
  // them yet, but the DocumentRecord sealed hierarchy (§3) already reserves the shape.
}
```

## 8. Encryption & key management

Two independent keys, never conflated:

1. **Device DB key** — generated on first run, `flutter_secure_storage`-backed (Android Keystore / iOS Keychain under the hood). See §2's pinning discipline.
2. **Export/recovery passphrase** — user-set (or app-generated + shown once) at vault creation. Derives an export-encryption key via `package:cryptography`'s `Argon2id` class. This is the key a "recovery code" printout represents.

```dart
// crypto/key_manager.dart
abstract class DbKeyProvider {
  Future<Uint8List> getOrCreateDbKey(); // flutter_secure_storage-backed
}

class RecoveryKeyDeriver {
  final _argon2id = Argon2id(memory: /* benchmark-tuned */ 19456, parallelism: 1, iterations: 2, hashLength: 32);
  Future<Uint8List> deriveExportKey(String passphrase, Uint8List salt) async {
    final secretKey = await _argon2id.deriveKeyFromPassword(password: passphrase, nonce: salt);
    return Uint8List.fromList(await secretKey.extractBytes());
  }
}
```

Onboarding must generate and force display/printing of the recovery code before the vault accepts its first real record.

**Open item, no fixed criterion yet**: when "pin + migration-test discipline" on `flutter_secure_storage` is judged insufficient and a custom native Keystore/Keychain escalation should happen instead. Revisit after M1's onboarding/recovery-code flow has real usage — don't build the escalation preemptively.

## 9–10. Sync & FHIR export

Not phase 1 scope at all. See [phase 2 features](../phase-2-v1.5/01-features.md) for BYO sync (including multi-provider redundancy) and FHIR export. The domain model above (§3) is deliberately shaped close to FHIR's own field names where cheap, so that mapping layer stays thin when it's eventually built.

## 11. Testing strategy

**`vault_roundtrip_test.dart` — the abandonment test.** This must exist and be green before v1 is considered done, not as a nice-to-have:
```dart
test('vault survives without the app', () async {
  // 1. Use the app's repositories to create a person, a medication course
  //    with a 2-phase taper, a dose log entry, a filed document.
  // 2. Point a bare YAML/Markdown parser (NOT the app's vault engine) at the
  //    resulting directory and assert every field is recoverable as plain text.
  // 3. Assert the directory needs no proprietary binary format anywhere
  //    except the original document files themselves (opaque by nature).
});
```

**`safety_invariant_test.dart` — draft cannot feed a reminder** (write this now even though phase 1 has no drafts yet, so the guarantee is locked in before phase 2 introduces `DraftExtraction`):
```dart
test('unconfirmed data never produces a reminder', () async {
  // Phase 1: there is no code path that can create a schedule_phase row
  // without going through the confirmed MedicationCourse/SchedulePhase
  // repository methods. Assert armRemindersForPerson() only ever reads
  // from schedule_phase, never from any draft/staging table.
});

test('conflicted schedule phase is excluded from reminders', () async {
  // simulate a row with a non-null conflict_group_id (even though phase 1's
  // sync doesn't populate this yet), assert activeNonConflictedPhasesForPerson()
  // excludes it.
});
```

**Manual/release checklist** (until CI exists): grep the dependency list for any analytics/crash/telemetry SDK name before every release; confirm no unnecessary network permissions are declared; confirm the Android build complies with Google Play's 16KB memory page-size requirement (native `.so` bundling — relevant to the SQLCipher native library, in force since November 2025).

## 12. Open engineering questions (resolve before M2)

- `cryptography` package's Argon2id benchmark on a real low-end device — do this before M1's onboarding flow locks in cost parameters.
- Exact `minSdk` — balance elder-mode device reach against future OCR-plugin floors (phase 2); revisit before phase 2 starts, not now.
- The Keystore/Keychain escalation trigger (§8) — no fixed criterion yet.

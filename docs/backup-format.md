# Amrutham backup file format

Your backup is yours, so the format is public. Anyone can write a tool that reads one, as long as they hold the recovery code. This page is the specification; the reference implementation is [`apps/mobile/lib/backup/vault_backup.dart`](../apps/mobile/lib/backup/vault_backup.dart), and the JSON layout is also given as a [JSON Schema](backup-schema.json).

Schema version: **1.0.0** (see [section 6](#6-versioning)). Licence: GPL-3.0, like the rest of the repository.

## 1. Envelope

One file, normally named `amrutham-backup.amrutham`. All parts are bytes, in this order:

| Offset | Length | Content |
| --- | --- | --- |
| 0 | 6 | Magic, the ASCII text `AMRBK1` |
| 6 | 16 | Salt for the key derivation |
| 22 | 12 | AES-GCM nonce |
| 34 | n | Ciphertext (same length as the plaintext) |
| 34 + n | 16 | AES-GCM authentication tag |

A file shorter than 6 + 16 + 12 + 16 = 50 bytes, or one that doesn't start with `AMRBK1`, is not a backup. There are no associated data. The magic is not part of the authenticated data.

## 2. Key

The password is the **recovery code** the app showed you: 24 characters from the alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, shown as six groups of four joined by `-`.

Normalise what a person types before use: upper-case it and remove spaces and dashes, leaving 24 characters. The password bytes are those 24 characters as ASCII.

Derive a 32-byte key with **Argon2id** (version 1.3):

| Parameter | Value |
| --- | --- |
| Memory | 19456 KiB (19 MiB) |
| Iterations | 2 |
| Parallelism | 1 |
| Output length | 32 bytes |
| Salt | the 16 bytes from the file |

These are the OWASP-recommended minimum settings for Argon2id.

## 3. Encryption

**AES-256-GCM** with the derived key, the 12-byte nonce from the file, and a 16-byte tag. Decrypting gives UTF-8 text, which is one JSON document (section 4). A wrong code or a damaged file fails the tag check. Nothing is leaked by the failure beyond "wrong code or damaged".

Every backup gets a fresh random nonce. Automatic backups (a feature that runs without asking for the code) reuse one salt and so one derived key kept in the phone's secure storage; the file is otherwise identical and opens with the same recovery code.

## 4. The JSON document

The top level is an object. Dates are ISO 8601 strings in UTC (for example `2026-04-02T09:30:00.000Z`). Optional values are `null`. Ids are opaque strings (ULIDs today). Money is a whole number of **paise** (1 rupee = 100 paise), never a float.

| Key | Content |
| --- | --- |
| `schemaVersion` | Semantic version of this document, for example `"1.0.0"`. See section 6. |
| `version` | The major number of `schemaVersion` as an integer (`1`). Kept so older app builds, which only know this key, still open the file. Files made before `schemaVersion` existed have only this key; read that as `<version>.0.0`. |
| `createdAt` | When the backup was made. |
| `people` | Family members: name parts, relationship, date of birth, sex, blood group, deceased flag and details, emergency contacts. |
| `familyHistory` | Conditions in relatives, per person. |
| `allergies` | Allergies, per person. |
| `courses` | Medicine courses, per person. |
| `phases` | Schedule phases of a course (dose, times, days, as-needed). |
| `measurements` | Readings: weight, blood pressure, sugar and so on. |
| `history` | Dated visits, procedures and scans. |
| `doseLogs` | Taken / skipped answers for scheduled doses. |
| `careTeam` | Doctors and facilities, shared by the people in `personIds`. |
| `expenses` | Medical spending, in paise. |
| `records` | Filed documents, each with its files. |
| `receipts` | Receipt photos. |

Files are embedded: each entry has a vault-relative `path` and base64 `data`. Records keep their path (`<personId>/<date>-<title>-<id>.<ext>`); receipts live under `receipts/<expenseId>.<ext>`. A reader must reject any `path` that is absolute or contains `..` before writing it to disk.

Unknown keys must be ignored, so a later version can add fields.

## 5. Reading one by hand

1. Check the magic, split off the salt, nonce, tag and ciphertext.
2. Normalise the code, then Argon2id it with the salt into 32 bytes.
3. AES-256-GCM decrypt, passing the tag.
4. Parse the UTF-8 result as JSON.

Any language with Argon2 and AES-GCM can do this; no Amrutham code is needed.

## 6. Versioning

`schemaVersion` is a [semantic version](https://semver.org) of the JSON document. The envelope (section 1) is versioned separately, by its magic.

| Change | Bump | A reader of the same major... |
| --- | --- | --- |
| A new optional field or table | **minor** (1.0.0 to 1.1.0) | still opens it and ignores what it doesn't know |
| Wording or clarification, data unchanged | **patch** | opens it as before |
| Anything an older reader couldn't understand: a field removed, renamed or retyped, new meaning for a value | **major** (1.x to 2.0.0) | must refuse it |

Rules for readers:

1. Parse `schemaVersion`. If it is missing, use `version` as the major and read it as `<version>.0.0`.
2. Pick the reader for that **major**. If your app has none, stop **before changing anything** and say whether the backup is newer (update the app) or too old.
3. A reader for major N reads every N.x.y. Missing optional keys mean "none".

Rules for Amrutham:

- Every major ever written keeps its own reader in the app (`_readers` in `vault_backup.dart`) and is never deleted, so a backup from any past release opens in the newest app.
- A major bump ships with a reader for the old major, the new one, and a test that opens a frozen sample of the old one.
- Changing the document means bumping `schemaVersion` and this page together.

History:

| Schema | Changes |
| --- | --- |
| 1.0.0 | Everything described above, including the given name and surname, care team, expenses with receipts and dose logs (all optional when reading, so the earliest files, which lack them, are still 1.x). |

## 7. Known limits

The whole vault is one JSON document held in memory, with files in base64, which is about a third larger than the files themselves. That suits a family's records; a vault with hundreds of large scans would need a streamed format, which would be a new major version.

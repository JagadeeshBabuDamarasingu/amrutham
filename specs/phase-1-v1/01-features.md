# Phase 1 (v1) — Feature Specs

## F1 — Person profiles & family history

- Profiles: self + genuine dependents (children, elderly parents). **No adult-peer accounts, no admin role** — per-person data ownership is the model; "admin" concepts are plumbing only, never implied data access.
- Family history is recorded as **unverified facts**, never computed or displayed as risk. Fields: relationship (free text, KIN-ontology-informed naming, not enum-locked), condition (free text always present, optional SNOMED code as enrichment only), onset age (approximate), outcome, `certainty` (confirmed / reported / suspected).
- Output register anywhere this data surfaces is strictly "3 first-degree relatives with type-2 diabetes — worth discussing with a doctor." Never a risk score, a percentage, or a red/yellow/green indicator. This is a hard line — see [out-of-scope.md](../out-of-scope.md) for why.
- **Acceptance:** a full profile plus 3 family-history entries can be created in under 5 minutes on a phone. No field is mandatory except a display name.

## F2 — Medication courses, schedules & reminders — *the core loop*

- Course = a prescribing episode: status (active/completed/stopped/paused), start/end date (null end = chronic), prescriber/reason optional.
- Multi-phase schedules: ordered phase rows support tapers (e.g., a 3-phase prednisolone course), PRN with a reason and a max-frequency ceiling (never a fixed reminder cadence — the ceiling is a ceiling, not a schedule), alternate-day dosing, specific times of day.
- Reminders per phase; a large-text/high-contrast elder-mode theme is first-class, not a buried setting; the reminder notification shows the medicine-strip or prescription photo if one exists for that course.
- **Schedules are single-writer by default** — one designated editor device per person's record (e.g., "Amma's care is managed from Lakshmi's phone"). See phase 2's sync spec for the conflict rule when this is violated.
- **Acceptance:** add a 3-phase taper in under 2 minutes; reminders fire correctly offline; changing a schedule always requires explicit local confirmation, never a silent background update.

## F3 — Dose journal

- Append-only event log: taken / missed / late / PRN-taken, tagged per device, per person.
- **"Missed" is exactly as frictionless and un-punished as "Taken."** One tap, no follow-up dialog, no streak-loss framing. Late edits are allowed, with an honest audit timestamp that appears in any future export ("logged 2 days later" — never hidden).
- **No streaks, points, rewards, or notifications attached to adherence, ever.** This is binding, not a style preference — rewarding a self-reported clinical fact corrupts the record by construction (a reward on "dose taken" incentivizes false logs to preserve the reward). If a progress-indication feature is ever built (phase 2, F6), it never touches this data.
- Coverage stat only ("30 of 31 days logged"), never a judgment, never a percentage framed as a grade.
- **Acceptance:** log a dose in one tap from the reminder notification; the journal survives device clock changes (store both scheduled time and logged time, don't infer one from the other); any export shows the honest audit timestamps.

## F4 — Document capture, tier 1 only (photo filing)

- **Can't fail.** Photograph and file any medical document — attached to a person, a date, and a type (prescription / lab report / discharge summary / strip photo / other). This alone beats a plastic bag of paper, and it's the entire scope of this phase's F4 work.
- **No OCR, no extraction, no drug-name parsing in phase 1.** That's tier 2, deliberately deferred to phase 2 (see [phase 2 features](../phase-2-v1.5/01-features.md)) — printed-text extraction only, never handwriting, and only once the draft/confirmed type-safety pattern and formulary-constrained pickers are built. Building tier 1 alone first means shipping something genuinely useful and completely safe before touching anything that requires a safety review.
- **Acceptance:** file a photo in under 15 seconds; a filed document is always attached to exactly one person, one date, one type; nothing here can ever influence a reminder (there's no extracted data yet to influence anything with).

## F5 — Plain-files vault & export — *the product's soul*

- Canonical storage is human-readable **Markdown with YAML frontmatter** (structured fields) plus a narrative body, in a user-visible folder — not a database export, the actual source of truth. The local encrypted database is a working index/cache, rebuildable from these files at any time.
- Exports (phase 1 scope: internal round-trip only; FHIR/PDF export mappers are phase 2): the vault format itself must already be Obsidian-vault-friendly — these files should open sensibly in Obsidian or any plain text editor, not just this app.
- A **printable one-page emergency card per person** (meds, allergies, blood group, contacts) is real phase-1 value that survives the app's death even before any other export exists.
- Recovery: a recovery code is generated and the user is forced through a "print or save this now" step **before the vault accepts its first real record** — this is mandatory, not optional, given that losing the passphrase means permanent data loss with no recovery path.
- **Acceptance (the "abandonment test"):** the vault directory remains fully readable and parseable by a bare YAML/Markdown parser — not the app's own code — with the app uninstalled. This must be a real, running test, not an aspiration. See [02-architecture.md](02-architecture.md) §11 for the concrete test design.

## F9 — Bare encounter log

- `Visit` as the atomic unit: kind (OPD / telehealth / inpatient), date, facility/doctor name (free text — not a practitioner registry), specialty, reason for visit, diagnoses (free text/coded), attachment references (reuses F4's document model, never a separate document type).
- An optional `hospitalization` sub-block (admit/discharge dates, ward, disposition) appears **only** when kind is inpatient. An optional `telehealth` sub-block (platform, mode, opt-in-only recording reference) appears **only** when kind is telehealth.
- An optional thin `EpisodeOfCare` wrapper groups multiple visits under one label ("Chemo course 2026") for multi-visit courses — this same primitive is what phase 3/4's "rare or complex condition" guidance leans on; don't build anything disease-specific on top of it.
- **Explicitly out of scope, permanently:** a FHIR `Appointment`-style booking/slot model (no personal-app value), structured bed/ward tracking, any institutional billing/claims linkage (that's a killed feature — see [out-of-scope.md](../out-of-scope.md)).
- **Acceptance:** log an OPD visit in under 30 seconds; an inpatient stay with a discharge summary attached in under 2 minutes.

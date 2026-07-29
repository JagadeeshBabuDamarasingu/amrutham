# Phase 2 (v1.5) — Feature Specs

Start this phase only once phase 1's abandonment test is green and v1 has real usage in at least the founder's own family.

## F4 tier 2 — Printed-text OCR extraction

Extends phase 1's document capture (F4 tier 1, already shipped) with the safety-critical draft/confirm pattern.

- **Printed text only.** Medicine **strip scanning** (name/strength/expiry — the household's actual ground-truth artifact) and lab-report parsing (PDF text-layer first — most Indian lab PDFs have one; OCR fallback via `google_mlkit_text_recognition` — the healthiest dependency found across the entire framework investigation; per-lab regex templates similar to the open-source Koshika project; fuzzy biomarker dictionary matching).
- **Handwritten prescriptions are filed as images via F4 tier 1 and manually entered — never OCR'd, never marketed as scannable.** The best published extraction result on Indian handwritten prescriptions is 82% F1, and its own authors state it "should not be deployed." This is not a temporary limitation to lift later; it's a permanent bright line.
- **Binding safety pattern**: extraction produces a `DraftExtraction` (the sealed-class type already reserved in phase 1's domain model) — **architecturally, not just by convention, incapable of feeding a reminder.** Drug/dose/frequency are committed only via **formulary-constrained pickers** (dose options limited to strengths that actually exist for that drug — there is no 100mg amlodipine, so the picker makes a misread unrepresentable) with the source-image crop shown per field. **No "Accept All" button exists anywhere in this flow.** Flag any chosen dose that's an exact 10× or 1/10× of another plausible reading (10mg ↔ 100mg) and force a magnified-crop re-check before allowing confirmation — this is the single most cited real-world OCR-in-medicine failure pattern.
- Confirmation produces a `ConfirmedExtraction`, which is the only thing the reminder engine's repository layer can read (see phase 1 architecture §6).
- **Bright line, permanent**: the OCR module has zero network capability. No consent flow ever unlocks a cloud OCR fallback — this is the thing that keeps the app's entire zero-data-flow legal posture intact.
- Drug-name matching: a bundled dictionary (1mg-derived open dataset + Jan Aushadhi government list — verify licensing before bundling), fuzzy-matched, presented as ranked candidates. **Never silently auto-corrected** — a fuzzy match returning "Amlopres" when the strip says "Amlodipine" and silently accepting it is exactly the failure mode this whole pattern exists to prevent.
- **Acceptance:** strip scan to a confirmed medication in under 60 seconds; a draft record can never produce a reminder (enforced in the data model and covered by a test, not just documentation).

## F6 — Progress indication (not gamification)

- Static setup checklists ("Amma's profile: 4 of 6 complete" — start non-zero, the endowed-progress pattern), one-time self-verifying milestones ("first year of records digitized"), a quiet stats page ("214 records kept for 3 family members").
- Duty/care framing ("keeping Amma's records complete"), not points framing — this is the demographic-appropriate register for the target users, not a stylistic preference. Age-adaptive tone; the entire layer is toggleable off.
- **No economy, no levels, no events, no engagement notifications, ever.** Rewards only "document filed" as a milestone, never extraction throughput or verification speed (rewarding verification speed directly undermines F4 tier 2's safety pattern — it pays for rubber-stamping).
- **Acceptance:** zero recurring-content maintenance burden; nothing here references adherence data (F3) at all — this feature and the dose journal must never touch each other.

## F7 — BYO sync, including multi-provider redundancy

- **Android:** SAF "pick any synced folder" (reaches Drive, Nextcloud, Syncthing, local — zero OAuth, abandonment-proof by construction). **iOS:** iCloud Documents as the default, zero-OAuth path.
- **Multi-provider redundancy**: the user can configure **more than one simultaneous sync destination** (e.g., mirror the vault to both a Drive-synced folder and a Dropbox-synced folder) so no single cloud vendor is a single point of failure. This is cheap once the shard-sync mechanism below exists — each additional destination is just "another folder to write the same encrypted shards to," not bespoke per-provider SDK code. Don't confuse this with phase 3's F13 sharing feature, which does need provider-native APIs for a different reason (access-control/expiry semantics that generic file-sync doesn't provide) — keep that provider list short (Drive + OneDrive) while this one can genuinely be "as many as the user wants."
- Sync unit design: **per-device append-only journal shards** (`deviceId+counter` filenames — races structurally impossible; union-merge on read). Fixed-size encrypted chunks so unchanged chunks skip re-upload.
- **Conflict rule (binding, activates the reserved `conflict_group_id` column from phase 1): silent last-write-wins on a medication schedule is forbidden.** Concurrent schedule edits produce both versions as explicit conflict copies; reminders for the contested medication are **blocked** until a human resolves the conflict in a loud UI — never guessed, never auto-merged.
- Metadata hygiene: opaque filenames, batched/jittered writes (no per-event heartbeat — a per-event sync pattern turns file-modification timestamps into an adherence-tracking side channel for anyone with access to the sync folder), a per-record **"this device only"** exclusion flag, an explicit staleness indicator ("last change from Appa's phone seen 3 days ago").
- **Acceptance:** two-device offline edit of the same schedule produces a blocking conflict UI, never a silent merge; the sync folder leaks no plaintext names or predictable size/timing patterns.

## F8 — Visit-summary share

- "Share a snapshot": a scope picker (meds + allergies + selected labs/time-range) generates a clean one-page bilingual PDF, delivered via the OS share sheet (WhatsApp/print/show-screen). Optional **offline signed QR** (payload-in-QR, SMART-Health-Card-style, size-capped — no server, no expiry theater).
- **Binding language: the verb is "send a copy." No "revoke" button exists anywhere.** Pre-share notice, non-dismissable: "You cannot take a copy back."
- **Acceptance:** scope selection to a shared PDF in under 30 seconds; the PDF is legible to a doctor in under 10 seconds (medications table first, not buried).

## F10 — Doctor sharing: local "saved recipient," never live access

- A purely on-device, unencrypted shortcut list (e.g., "Dr. Sharma — Cardiologist") that pre-fills F8's scope picker and recipient label for repeat sharing. Nothing is generated or transmitted until the user actively triggers a share in the moment.
- Presets may distinguish an "ongoing care" scope (wider default date range/record types) from a "one-time visit" scope — this is stored data shaping F8's picker defaults, not a live grant.
- **Binding, permanent: no live/standing/on-demand-pull access of any kind.** No server, no discoverable endpoint, no hosted viewer, no credential that persists on the recipient's device between visits. (This was tested against a full adversarial review — a "doctor guest role" with live access is the same unsolved group-key-management primitive as the family peer network that was killed elsewhere, just at group size 2, and the asymmetries — one clinic device aggregating standing keys across many unrelated patients, no natural revocation trigger on doctor-churn — make it worse, not better.)
- **Acceptance:** save a recipient once; every subsequent share to them is scope-prefilled in one tap; deleting a saved recipient has zero effect on shares already sent (this is honest — it was never access in the first place).

## F11 — Weight tracking, dependent-profile-first

- `WeightObservation { profileId, valueKg, effectiveDateTime, note?, source: manual | health-connect | healthkit }`.
- Manual entry only in this phase; optional Health Connect (Android) / HealthKit (iOS) read-import as a later minor version. **No custom Bluetooth stack** — defer entirely to the Health Connect/HealthKit ecosystem if scale support is ever demanded.
- **Binding, profile-type-aware defaults**:
  - Elderly/dependent profiles: full trend display + an **unintentional weight-loss alert** (a real geriatric red flag — this is the actual clinical value of this feature). Frequent weighing is protective here.
  - Adolescent/young-adult profiles: **trend-only display, raw number hidden by default**, no direction-based alerts, no goals, no BMI display, no streaks. (Daily self-weighing is a documented risk factor for disordered eating in this population specifically — this default split isn't a style choice, it's the safety line.)
  - **No daily notification for either profile type.** If any prompt exists at all, it's low-frequency (weekly at most), user-configured, never nonprofit-initiated by default.
- **Explicitly out of scope**: calorie/macro/diet logging (the only diet-adjacent survivor from the full feature review is a qualitative "appetite/intake note" for elderly caregiving — no nutrient tracking, ever), goal-setting, BMI as a primary metric.
- **Acceptance:** log a weight entry in under 10 seconds; an elderly profile's unexpected 3+ month decline surfaces a caregiver-facing flag; a teen profile never displays a bare numeric trend line by default.

## F12 — Curated health, scheme & insurance information

- **No original doctor-authored content, no contributor submission channel, no individual-credential claims of any kind, ever.** The app never says "shared by proper doctors" or badges any individual author — credibility is explicitly the *institution's* (WHO/ICMR/MoHFW/NHP.gov.in/NHS/Mayo Clinic), never the app's or an individual's. (Credential verification has no free, reliable path in India — the NMC register has broken TLS and no public API — and even paid third-party KYC verification doesn't solve staleness, unbounded editorial burden, or policing volunteer contributors against the no-brand-promotion rule. A fabricated "doctor-reviewed" badge would launder off the app's own trustworthy reputation, which is worse than hosting no content at all.)
- **Two content types, different rules:**
  - **Concept layer** (stable, cache-offline, bundled at build time): how a scheme *type* generally works, generic eligibility patterns, what a waiting period/co-pay/claim process means, a pre-purchase insurance checklist. Safe to author once because it describes how the category works, not what a specific scheme currently offers. No specific insurer or product ever named, ranked, or recommended — this is both the ethical "no brand promotion" line and the actual legal safe-harbor line under the Insurance Act (generic education isn't regulated "solicitation").
  - **Fact layer** (volatile — current coverage amounts, eligibility thresholds, exact scheme names, enrollment portals): **never asserted in-app.** Always a dated, labeled outbound link to the official source (e.g., "Check current PM-JAY eligibility → pmjay.gov.in, last verified by us: [date]"). No open government API/dataset exists for this — PM-JAY eligibility is not an open API, state schemes are fragmented with no federated data layer — so hand-curated links are the honest option, not a shortcut.
- **Binding staleness UI**: every content item shows a visible **"Last reviewed: [date] / Next review due: [date]"** badge (a 3-year cycle, matching NHS.uk's own practice, not Mayo Clinic's 2-year one which assumes 100+ staff a solo nonprofit doesn't have). Overdue content is visually flagged, never silently displayed as equally trustworthy as fresh content.
- **Binding privacy rule**: content-viewing history is never logged or exposed across profiles — the same "this device only" exclusion applied to reproductive-tracking data, extended to what a profile has *read*, not just what it recorded. (Exposure of *having viewed something* is itself a real proxy-signal risk — e.g., a parent seeing "she read an article about pregnancy" — even though the content itself, per the evidence, is generally protective rather than risk-increasing.)
- **Reproductive/fertility content**: basic puberty/menstrual-health literacy available broadly across age tiers; more specific adult-relevant topics (fertility treatment, infertility as a diagnosed condition) tiered toward older-teen/adult profiles — **no hard block at exactly 18.**
- **Explicitly out of scope, permanently**: any doctor-contributor submission channel, any live community/forum/consultation feature (a distinct, much larger, separately-deferred future project — not part of this app), any computed/personalized recommendation ("based on your situation, scheme X fits you" crosses from education into advice-adjacent territory the same way hereditary-risk-scoring did).
- **Acceptance:** every content item has a visible last-reviewed/next-review-due date; zero specific insurers/schemes are asserted with current numbers anywhere in bundled content; a link-rot check passes at each release.

## F5 (extension) — FHIR export

Not detailed as its own feature file since it's an extension of phase 1's F5 — build the mapper layer now that the domain model has stabilized: `MedicationCourse`+`SchedulePhase[]` → FHIR `MedicationRequest` (`dosageInstruction[]` per phase), `FamilyHistoryEntry` → `FamilyMemberHistory`, `Visit` → `Encounter` (+ hospitalization → the `Encounter.hospitalization` backbone element), `DocumentRecord` → `DocumentReference`. Bundle format: HL7's draft Personal Health Records Format IG's `.phr` (NDJSON) container. The domain model was deliberately shaped close to FHIR's own field names for exactly this reason — this mapping layer should stay thin.

## Documentation deliverable — "using Amrutham for a rare or complex condition" (zero code)

Ship a documentation page, not a feature, showing how F1 (diagnosis/family history) + F2 (schedules — already handles recurring intrathecal-injection-style regimens like Spinraza and one-time-treatment-plus-follow-up courses like Zolgensma) + F4 (documents + observation log, if built — see below) + F9 (`EpisodeOfCare`, already scoped for multi-visit courses like "a chemo course") compose to serve a family managing a rare or chronic condition, **without any disease-specific build.** This was the outcome of a dedicated review of a request to add rare-disease (e.g., SMA) symptom tracking — self-scoring a clinical instrument like CHOP-INTEND without trained-assessor administration produces clinically meaningless-or-misleading data that could feed real, expensive, irreversible treatment decisions, and disease-named/scored outputs cross FDA's own general-wellness safe-harbor line. No new feature was needed; existing primitives already compose to serve this need.

### F4 generalization — caregiver-authored observation entries (small, disease-agnostic)

If built (evaluate against the phase-2 timebox before committing): caregiver-authored free-text journal entries, caregiver-defined binary/event tags (e.g., "used BiPAP last night," "choked while eating" — **the caregiver types the tag; the app never ships or maintains a disease-specific symptom vocabulary**), and photo/video attachments explicitly framed as "for your clinician to review." The app captures and transports; it never scores or interprets.
- **Permanent invariant, not just a rule for this feature**: the app never names a specific disease or characterizes any entry/trend as abnormal, pathological, improving, or declining, anywhere in the UI or export. This generalizes the SaMD discipline already applied to F1's family-history register to cover free-text/media logging too — any future feature proposal that requires naming a disease or grading severity to be useful has already failed this test.

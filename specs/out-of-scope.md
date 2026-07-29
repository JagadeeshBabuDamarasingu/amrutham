# Out of scope — permanently

These aren't "not yet." Each was proposed and killed after adversarial review, for a specific reason. If a future contributor (including future-us) wants to revisit one, the reason needs to be argued down first, not just rediscovered as a good idea.

## Risk scoring / hereditary disease risk percentages

Family history is recorded as unverified facts only (see [phase-1 F1](phase-1-v1/01-features.md)) and surfaced only as a plain factual summary ("3 first-degree relatives with type-2 diabetes — worth discussing with a doctor"). Never a computed risk score, a percentage, or a red/yellow/green indicator.

**Why:** actuarially meaningless without clinical-grade family history intake and genetic counseling this project cannot provide; a false sense of precision here is actively harmful, not neutral. Also a fast path into regulated medical-device (SaMD) territory this project deliberately stays out of.

## Gamification / streaks / rewards on adherence data

No streaks, points, badges, or "you're on a 30-day streak!" framing attached to dose-taken logging, ever.

**Why:** rewarding a self-reported clinical fact corrupts the record by construction — a reward on "dose taken" incentivizes false logs to preserve the reward or streak. The dose journal's entire value is being an honest record; gamifying it destroys the thing it exists for. (Progress *indication*, F6 in phase 2, is a different, permitted thing — see that spec for the distinction.)

## Punishing or shaming "missed dose" logging

"Missed" must be exactly as frictionless and un-punished as "Taken" — one tap, no follow-up dialog, no streak-loss framing, ever.

**Why:** the moment logging a miss costs more friction or feels worse than not logging at all, users stop logging misses, and the record silently becomes fiction.

## Live/standing AI or third-party access to health data

No live, standing, or "always-on" access grant to anyone — not a doctor, not a family member, not an AI system — over a person's records.

**Why:** every version of "live access" investigated collapses into the same unsolved problem: durable group-key management with real revocation, which is a genuinely hard cryptographic and UX problem this project cannot solve credibly at nonprofit-solo-maintainer scale. Every access grant that ships is time-boxed and copy-based instead (see [F8](phase-1-v1/01-features.md), [F10](phase-2-v1.5/01-features.md), [F13](phase-3-v2/01-features.md)).

## Cloud LLM access to health records

Any AI feature (see [phase-4 MCP gateway](phase-4-v3/01-features.md)) is local-model-only. No cloud LLM ever sees a user's health data, under any consent model.

**Why:** sending health data to a cloud LLM API collapses this project's zero-data-flow legal posture (the thing that keeps it out of DPDP fiduciary status, GDPR controller status, and HIPAA scope) for the sake of one feature. There is no consent flow that legitimately reopens that door once it's shut, and medication lists alone can reveal a diagnosis (e.g., a specific antiretroviral regimen implies HIV status) even with no diagnosis field involved — so scoping *categories* of data doesn't bound what a model can infer from what it's given.

## AI-generated dosing or triage output

Even the local, read-only AI gateway (phase 4) never emits a dosing instruction ("take 2 instead of 1") or a triage disposition ("you don't need the ER"). These are hard refusal categories enforced by a post-generation output filter, not a prompt-level instruction.

**Why:** this is unlicensed medical practice by an algorithm, full stop, regardless of how good the underlying model is. The gateway's only sanctioned clinical-adjacent job is deterministic drug-interaction lookups, with the LLM narrating a pre-computed real answer — never computing or advising anything itself.

## Live health community / social features

A community layer (forums, comment threads, peer support groups) was explicitly raised and explicitly deferred as a separate, future, distinct project — not part of Amrutham.

**Why:** moderation at any real scale is a full-time job with real legal exposure (health misinformation, medical-advice liability from peer users, harassment) that has nothing to do with this project's actual mission of encouraging personal record-keeping. Bundling it in risks sinking the core product under a much harder problem.

## Institutional billing / claims linkage

No structured claims-submission integration, no insurer billing-code linkage, no institutional payer-side data model.

**Why:** this project tracks a family's *own* expense records for their own budgeting and government-scheme literacy (see phase-2 F12's financing-the-health-crisis content), not the institutional billing side of healthcare. That's a different regulatory world (payer/provider claims infrastructure) this project has no reason to enter.

## FHIR `Appointment`-style booking/slot model

No appointment scheduling, slot booking, or provider-availability modeling in the encounter log (F9).

**Why:** zero value for a personal record-keeping app — booking a slot with a real clinic is a completely different problem (and product) from recording that a visit happened. Would import a large chunk of FHIR's institutional-scheduling complexity for no user benefit.

## Structured bed/ward tracking

The `hospitalization` sub-block (F9) records admit/discharge dates, ward, and disposition as simple fields — never a structured bed-management or ward-inventory model.

**Why:** that's hospital operations software, not a personal family record. Out of both scope and mission.

## Naming diseases or grading severity in caregiver observation entries

Phase-2's generalized caregiver observation entries (extended from the rare-disease documentation work) never auto-name a suspected condition or auto-grade severity from logged observations.

**Why:** a permanent invariant, not a phase limitation — this is unlicensed diagnostic inference dressed up as a logging feature. The app records what a caregiver directly observed, in the caregiver's own words; it never synthesizes a diagnosis or a severity grade from that record.

## Admin role / account-level data access

"Admin" (e.g., the family member managing a shared device or a dependent's profile) is plumbing only — device/app administration — never a role that implies broader data access than the per-person ownership model already grants.

**Why:** collapsing "manages the app" into "can see everyone's data" is exactly the failure mode that makes shared-device family apps feel surveillance-like. Per-person ownership is the whole model; there's no backdoor role that overrides it.

## Proximity-bound (Bluetooth/WiFi Direct) sharing as the actual transport for time-boxed sharing

Considered and rejected as the mechanism for [F13](phase-3-v2/01-features.md) specifically — see that spec's "why this shape" section for the full reasoning.

**Why:** doesn't fit the motivating scenario (devices aren't co-located for the sharing window), so it was replaced with the periodic auto-refreshing copy-based design.

## Live WebRTC / hosted signaling-and-TURN relay for family sharing

Considered and rejected for the same feature — see F13.

**Why:** reintroduces the exact always-on hosted-infrastructure liability (and its cost/maintenance burden on a nonprofit solo maintainer) that a peer-to-peer family-circle feature was killed for earlier in planning, just relocated from "web viewer" to "signaling/TURN relay" — not actually eliminated.

## Dropbox for pairwise time-boxed sharing

Dropbox is excluded specifically from [F13](phase-3-v2/01-features.md) (though it remains fine as one of many BYO-sync destinations in [F7](phase-2-v1.5/01-features.md)).

**Why:** structurally cannot do per-recipient sharing with expiry on any personal tier — its expiration feature is a link property, Business-tier only, never a property of the actual per-recipient sharing primitive itself.

## ABDM (Ayushman Bharat Digital Mission) integration, for now

Not ruled out permanently — deliberately deferred, see [phase-4](phase-4-v3/01-features.md). Listed here because it's easy to assume it's further along than it is.

**Why:** real ABDM HIU/Gateway registration is a large compliance lift (NHA sandbox onboarding, a genuine security/consent-artifact integration) with no demonstrated user demand yet. The domain model stays profile-compatible so this is an adapter later, not a rewrite — but building it now would be solving a problem no user has asked for yet, at the cost of everything else on the roadmap.

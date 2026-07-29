# Amrutham — Specs

**Working title.** A nonprofit, open-source, offline-first, privacy-first family health records app. India-first, Flutter/Dart, no developer-run server, plain files as the source of truth.

These specs are the working build reference for this repo. The full research and reasoning behind every decision here — five waves of feature research/adversarial review, plus two more on the mobile framework choice and the peer-to-peer sharing design — lives in the Obsidian vault (`Projects/health-binder/` — PRD, technical spec, and the research note), not duplicated here. If a decision below seems to come out of nowhere, it didn't; check the vault's research note for the "why."

## What this app is

Your family's medical history, in files you own, in an app that can die without taking your data with it. Medication schedules and reminders are the daily loop; the health record accretes as a byproduct of photo-first capture. No developer server, no telemetry, no accounts.

## Phases

| Phase | Contents | Status |
|---|---|---|
| [Phase 1 — v1](phase-1-v1/) | Profiles, family history, medications/schedules/reminders (the core loop), dose journal, document photo-filing, the plain-files vault, a bare encounter log | Current — start here |
| [Phase 2 — v1.5](phase-2-v1.5/) | OCR extraction (tier 2), progress indication, BYO sync + multi-provider redundancy, visit-summary sharing, saved-recipient doctor sharing, dependent-profile weight tracking, curated health/scheme/insurance content | Next |
| [Phase 3 — v2](phase-3-v2/) | Pairwise time-boxed sharing between family members | Later |
| [Phase 4 — v3](phase-4-v3/) | Local-LLM MCP gateway for scoped AI access to records; SMART Health Links; ABDM import adapter | Only if the project is alive and has had a security review |
| [Out of scope](out-of-scope.md) | Everything deliberately killed, and why — read this before re-proposing a feature | Permanent reference |

## Non-negotiables (apply to every phase)

1. **Zero developer-side data flow.** No server, no telemetry, no analytics/crash-reporting SDK — not even an "anonymous" one. No unnecessary network permissions.
2. **Draft/confirmed is a type distinction, not a boolean flag.** Anything OCR- or import-derived is a different Dart type than a user-confirmed record. The reminder engine must be structurally incapable of reading a draft.
3. **Plain files are the source of truth.** The local database is a rebuildable cache. The vault directory must stay byte-legible without the app.
4. **Silent last-write-wins on a medication schedule is forbidden.** Any sync merge touching a schedule must produce a blocking conflict UI on divergence, never an automatic pick.
5. **No output names a specific disease or characterizes a trend as abnormal/improving/declining.** Applies to UI copy, notifications, and exports.
6. **The reminder-firing path never depends on the `workmanager` package.** Use `flutter_local_notifications` (see phase 1 architecture) — no custom native code is needed for this once the right package is used.
7. **No proactive daily push notification exists for anything except medication dose reminders.** Any other domain's reminder is opt-in, low-frequency, user-configured — never nonprofit-initiated by default.
8. **Every dependency is chosen for boringness — pin versions, review before every release.** Check the dependency list against the deny-list in [out-of-scope.md](out-of-scope.md) and the phase-1 architecture doc before adding anything new.

## Naming

"Amrutham" is a working title, not final. Trademark/phonetic collision risk with Amrutanjan Health Care is on record; "nectar of immortality" is also flagged as a significant overclaim tension with this project's own non-diagnostic discipline. Final name decision is deferred — do not build brand assets (app store listing copy, logo, domain) around this name as permanent yet.

## Open source

Staged, not day-one. Build to a stable, threat-modeled core first, seek a free security review (OTF Security Lab / OSTIF), then publish. License: GPLv3 for the client code now; reserve AGPLv3 for if/when any server component ever exists (none currently planned). Register the trademark on the final name early, independent of publish timing.

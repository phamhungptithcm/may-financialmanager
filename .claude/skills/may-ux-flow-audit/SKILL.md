---
name: may-ux-flow-audit
description: Inspect, transcribe and verify Mây Family Finance navigation graph from the authentic FigJam UX Flow .jam source or an owner-reviewed provenance-locked export. Map every node and edge to Flutter routes and automated tests.
---

# Audit the approved FigJam UX Flow

**Request:** $ARGUMENTS

1. Read `CLAUDE.md`, `AGENTS.md`, `docs/qa/APPROVED_REFERENCES.md` and `docs/specs/02_UI_UX.md`. The owner approved `FamilyClanMockupFullFlow.html` as Mây.
2. Run `python3 scripts/reference_preflight.py --strict`. Inspect the authentic `docs/Family Finance — End-to-end UX Flow.jam` via connected Figma/FigJam tools or a readable export with checked SHA provenance. `.jam` is NOT PNG. If neither a readable board nor a verified export exists: BLOCK flow implementation and list precise missing evidence.
3. For reproducible baseline, run `python3 scripts/reference_preflight.py --strict --require-flow-export`. Do not fabricate or generate a diagram to satisfy missing input; request export from actual `.jam`.
4. Enumerate all visible graph nodes, labels, outgoing/incoming edges, conditional branches, failure/cancel/retry paths, overlays, deep links and start/end states. Compare with real browser behavior of HTML mockup, not generic product assumptions.
5. Create/maintain `docs/qa/UI_FLOW_MATRIX.csv` rows with exact `flow_jam_node`, `flow_jam_edge` and corresponding Flutter route/state, user gesture, backend Function and test IDs.
6. For ambiguous edges, mark BLOCKED and write `docs/qa/REFERENCE_CONFLICTS.md` entry, never silently fill gaps. Every route/transition marked PASS must have verified source and runnable app interaction evidence.
7. Report uncovered source edges, invented/extra app navigation, conflicting specs, missing tests and owner review decisions.

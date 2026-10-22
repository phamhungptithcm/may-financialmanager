# Mây Claude Code v3 — Repo-aligned instructions + skills

Copy/merge this **flat overlay** at the root of existing `May/` (no nested `May/May/`). Existing specs and the two original reference files are NOT included or changed.

**Owner-confirmed:** `docs/FamilyClanMockupFullFlow.html` is the genuine Mây Finance mockup despite the filename. `docs/Family Finance — End-to-end UX Flow.jam` is the authoritative FigJam diagram, not a PNG. If FigJam can't be opened in Claude's execution environment, export it (PNG/SVG) and register source/export SHA256 in the review manifest before implementing UI flows.

## Install safely

From the extracted kit folder:

```bash
python3 install.py --project-root /absolute/path/to/May --dry-run
python3 install.py --project-root /absolute/path/to/May
python3 verify_skills.py --project-root /absolute/path/to/May --check-references
cd /absolute/path/to/May
python3 scripts/reference_preflight.py --strict
# For flows, a reviewed export is required:
python3 scripts/reference_preflight.py --strict --require-flow-export
# Once references are owner-reviewed, create and commit lock (do not auto-reset):
python3 scripts/reference_preflight.py --strict --require-flow-export --write-lock
```

If existing `CLAUDE.md` or `.claude/settings.json` differs, the installer reports CONFLICT and does not overwrite; manually merge. Project roots must contain `docs/`.

### FigJam flow export (when Claude cannot inspect `.jam` directly)

1. Open actual `.jam` in FigJam/Figma; export full diagram as a readable `PNG` or `SVG` into `docs/qa/design-references/ux-flow.png` (or `ux-flow.svg`). **Do not rename .jam to .png.**
2. From project root execute `python3 scripts/register_flow_export.py --export docs/qa/design-references/ux-flow.png` (or `.svg`). Script binds export hash to current `.jam` hash but does NOT prove the export matches its source. Human reviewer visually checks all nodes, branches, labels then commits reference manifest and export.
3. Run `python3 scripts/reference_preflight.py --strict --require-flow-export` and review generated `docs/qa/design-references/flow-export-manifest.json`.
4. Re-export and re-register after any approved FigJam change. Old manifests fail preflight when source hash changes.
5. `docs/qa/UI_FLOW_MATRIX.csv` must include real diagram nodes/edges with evidence. A screenshot alone does not prove every branch was implemented.

If you have a reliable FigJam connector, inspect the board directly first. A reviewer-approved export still supports reproducible source review and CI even when the connector is unavailable.

### Claude Code invocation

```bash
cd /absolute/path/to/May
claude
# /may-implement-feature Phase 0 — audit only
# /may-ui-fidelity Home and widget flows
# /may-ux-flow-audit map all FigJam nodes and transitions
# /may-firebase-contracts ledger+budgets
# /may-financial-integrity ledger and projections
# /may-release-gate staging readiness
```

Project skills are in `.claude/skills/<name>/SKILL.md`, subagents in `.claude/agents/*.md`, policy hook `.claude/hooks/pre_tool_guard.py` referenced by `.claude/settings.json`.

**CI**: `.github/workflows/may-reference-contract.yml` requires a committed approved lock/export. Enable it as a required status check only after reviewer approves references and baseline. Hooks help avoid accidental mistakes but aren't an execution sandbox or reliable defense against arbitrary shell scripts.

**Status**: documents, automation and test fixtures produced; does not mean the real app, original mockup or FigJam source has been audited or deployed.

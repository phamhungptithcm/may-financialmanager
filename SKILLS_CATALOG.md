# Claude Code project skills — Mây

Claude Code discovers project skills at `.claude/skills/<skill-name>/SKILL.md` when invoked from the actual repository root. Type `/skills` or `/` in Claude Code to inspect skills; hidden `.claude` folders are visible using `ls -la`.

| Skill | Purpose |
| --- | --- |
| `/may-implement-feature` | Complete Flutter + Firebase vertical slice using authoritative specs |
| `/may-ui-fidelity` | Validate original HTML UI, copy, gestures, motion and screenshot parity |
| `/may-ux-flow-audit` | Examine verified FigJam flow graph and map node/edge to routes/tests |
| `/may-firebase-contracts` | Functions/DTO/RTDB Security Rules/integrations |
| `/may-financial-integrity` | Ledger, idempotency, projection reconciliation and money correctness |
| `/may-release-gate` | Manual-only readiness gate, no deploy |

Subagents are discoverable in `.claude/agents/`: `may-design-auditor`, `may-backend-contract-auditor`, `may-finance-security-auditor`.

## How to use

1. Merge kit into `May/` root, not `May/May/`.
2. Run `python3 verify_skills.py --project-root /path/to/May --check-references`.
3. Run `python3 scripts/reference_preflight.py --strict --require-flow-export` before UI implementation.
4. Start Claude from `May/` and call `/may-implement-feature Phase 0`.

`docs/FamilyClanMockupFullFlow.html` is OWNER-APPROVED as Mây despite historical name. The second reference is `.jam` FigJam source. An original `.jam` file alone may not be renderable by CLI; use connected Figma tools or a reviewed export, **never guess flow topology**. Read `README_AGENT_KIT.md` for export/manifest instructions.

# Mây Claude Agent Kit v3 — Verification

**Scope tested:** Claude configuration file layout, Python preflight scripts, flow export review guard, original-reference lock check and hook policy fixtures. **Not tested:** actual owner `.jam`, real owner HTML interactions, Firebase production, Flutter app builds, Claude Code runtime invocation.

- Claude Code discovery layout: `.claude/skills/<name>/SKILL.md`, `.claude/agents/*.md`, `.claude/settings.json`.
- Original prototype: `docs/FamilyClanMockupFullFlow.html` (owner confirmed this is Mây Finance).
- Original flow diagram: `docs/Family Finance — End-to-end UX Flow.jam` (must be inspected with Figma or verified readable export).
- `python3 -m unittest discover -s tests -v`: 5 fixture tests PASS; tests do not pretend to verify the real design assets.
- `verify_skills.py`: 6 discovered/verified skill layouts. Reference originals absent from kit by design.
- Installer: must preserve any existing `CLAUDE.md`, `.claude/settings.json`, `docs/` references and report differing targets as CONFLICT.
- Hooks: inadvertent edits to approved originals denied for supported editor tools; not a sandbox and not resistant to arbitrary shell commands.
- CI: reference manifest/lock and trace matrix gate provided; requires owner-approved lock + export to pass.

## Human actions still required

1. Confirm original HTML and `.jam` physically exist in real `May/docs/`.
2. Export/open the real `.jam`, review its exact nodes/edges, approve and commit provenance manifest.
3. Review lock, git changes and hook configuration before enabling it in a production repository.
4. Run Claude Code `/skills` and test one read-only feature audit on your own machine.

Never call unrun emulators, original motion tests or Flutter implementations PASS.

# Mây Agent Entry Point

Canonical instructions: `CLAUDE.md` + `AGENTS.md`.

Project skills: `.claude/skills/<skill>/SKILL.md`. This file is for tools that explicitly look for `AGENT.md`; Claude Code discovers `CLAUDE.md` and `.claude/skills` automatically.

Owner-approved references:
- `docs/FamilyClanMockupFullFlow.html` — UI/UX/motion/interaction (approved as Mây).
- `docs/Family Finance — End-to-end UX Flow.jam` — FigJam flow; view through FigJam or approved, provenance-locked export.
- `docs/specs/*` — Firebase, database, APIs, business rules and security.

## Foundation-First and Reuse-First Policy

All implementation must follow:

Foundation → Shared Components → Domain Components → Features.

Before introducing a new component or service:

1. Search for an existing implementation.
2. Review the shared component inventory.
3. Prefer reuse or composition.
4. Avoid duplicate responsibilities.
5. Keep domain-specific behavior inside its domain.
6. Follow established design tokens and API contracts.
7. Add tests for shared behavior.
8. Update component documentation when public APIs change.

The approved HTML prototype is the visual source of truth.

Never introduce inconsistent colors, spacing, typography,
animations, transitions, buttons, forms, or navigation.

All features must use the shared design system.

All Firebase Functions must reuse common authentication,
authorization, validation, logging, and error-handling
infrastructure.

Do not create abstractions solely for hypothetical reuse.

Shared components must remain independent of individual
feature implementations.

Any exception requires a documented architectural reason.

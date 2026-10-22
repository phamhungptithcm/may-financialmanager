# Mây Family Finance — Release Notes Standard

## Overview

Release notes are generated automatically from git history by `scripts/ci/generate-release-notes.sh`. This document specifies the structure, tone, and content rules.

## Structure

Every release note MUST follow this structure (empty sections omitted):

```markdown
# Mây Family Finance vX.Y.Z

Release Date: YYYY-MM-DD

## New Features

- Feature description with context

## Improvements

- Performance, UX, accessibility improvements

## Bug Fixes

- Defect resolution description

## Security

- Relevant security improvements (no vulnerability disclosure)

## Technical Changes

- Architecture, dependency, or infrastructure changes

## Breaking Changes

- Migration guidance for incompatible changes

## Merged Pull Requests

- #123 -- PR title
- #124 -- PR title

[Full Changelog: vX.Y.Z...HEAD](...)
```

## Content Rules

### Tone

- Clear, professional English.
- Concise and natural language.
- No marketing exaggeration ("revolutionary", "amazing").
- Focus on **user impact**, not implementation details.

### Grouping

Changes are grouped by **user-visible impact**:

| Category | Commit prefix match |
|----------|---------------------|
| New Features | `feat:`, `feat(scope):` |
| Improvements | `perf:`, general descriptive commits |
| Bug Fixes | `fix:`, `fix(scope):` |
| Security | Commits mentioning security, auth, permissions |
| Technical Changes | `refactor:`, dependency updates |
| Breaking Changes | `!:` suffix or `BREAKING CHANGE:` in body |

### PR References

PR numbers are extracted from merge commit subjects (`#\d+`) and listed at the end. Up to 30 unique PRs are included per release.

## Do Not Include

- **Fabricated features** -- only list what actually exists in git history.
- **Internal tooling changes** that don't affect users (e.g., CI config tweaks) unless they have user impact.
- **Vulnerability details** -- describe the improvement without revealing attack surface.
- **Secrets or credentials** -- never include token values, keys, or configuration.
- **Duplicated entries** -- each change listed once, at most.

## First Release Notes Example

For the initial `v0.1.0` release (from a clean repo with scaffolding):

```markdown
# Mây Family Finance v0.1.0

Release Date: 2026-10-22

## Overview

Initial release of Mây Family Finance -- an iOS/Android household budgeting app built on Firebase with immutable double-entry ledger semantics.

## Infrastructure

- Flutter 3.24+ project scaffold (iOS + Android)
- Firebase Cloud Functions v2 TypeScript architecture
- CI/CD pipeline with Branch CI and Main Release workflows
- GitHub Actions: format, analysis, tests, emulator, security scanning
- Semantic versioning with conventional commit support

[First Release -- Full Commit History](...)
```

---

*Last updated: 2026-10-22*

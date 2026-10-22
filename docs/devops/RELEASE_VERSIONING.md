# Mây Family Finance — Release Versioning

## Semantic Versioning Policy

Mây follows [semver 2.0.0](https://semver.org/) with the prefix `v`:

```
vMAJOR.MINOR.PATCH
```

### Bump Rules

| Condition | Bump | Example Transition |
|-----------|------|--------------------|
| Any commit contains `BREAKING CHANGE:` or `!` suffix | **MAJOR** | v0.2.3 -> v1.0.0 |
| At least one `feat:` commit (no breaking) | **MINOR** | v0.2.3 -> v0.3.0 |
| Only `fix:` commits (no feat or breaking) | **PATCH** | v0.2.3 -> v0.2.4 |
| Only `docs:`, `test:`, `chore:`, `refactor:` | **No release** (exit 2) | -- |

### Pre-1.0 Policy (MAJOR.MINOR.PATCH where MAJOR = 0)

In the `v0.x.y` range, MINOR bumps indicate feature additions that may still introduce breaking changes. MAJOR bumps are reserved for significant architectural shifts (e.g., Firebase SDK major upgrade, database schema change requiring migration).

**First release is `v0.1.0`**, representing the initial scaffolding and core infrastructure.

### Version Calculation Logic

Located in: `scripts/ci/calculate-version.sh`

1. Determine diff range: last tag -> HEAD (or first commit -> HEAD for clean repos).
2. Parse each commit message for conventional commit prefixes.
3. Check for breaking change markers first.
4. Then check for `feat:` -> MINOR bump.
5. Then check for `fix:` -> PATCH bump.
6. Exit 2 if no release-worthy changes found.

### Idempotency and Deduplication

- The pipeline checks if a calculated version tag already exists before creating it.
- If the tag exists, the pipeline completes successfully (exit 0) with a notice -- **no duplicate releases**.
- Concurrency group `main-release-${{ github.ref }}` prevents parallel release runs from the same ref.
- Concurrent pushes to main are serialized; the first runner creates the tag, subsequent runners detect it and skip.

### Version Override

For manual version control (rare):

```bash
# Force a specific version on a release run.
VERSION=v1.2.3 git push origin main
```

When `VERSION` is set in the environment, it bypasses automatic calculation but still passes through format validation (`grep -P '^v\d+\.\d+\.\d+$'`).

### Tag Safety Rules

| Rule | Enforcement |
|------|-------------|
| No force-push to release tags | Branch protection: no tag deletion/force push on main |
| No overwrite existing tags | `git tag -a` fails if tag exists; pipeline checks first |
| Immutable tags | Tags are lightweight-annotated; never deleted by automation |
| Deterministic output | Same commit history -> same version (purely git-history-driven) |

### Version Number Reference

| Release | Meaning | Example Use Case |
|---------|---------|-----------------|
| v0.1.0 | Initial scaffolding + CI/CD baseline | First push after repo init |
| v0.2.0 | First feature release | Auth + onboarding complete |
| v0.2.1 | Bug fix patch | Fix money formatting edge case |
| v0.3.0 | New feature (minor) | Ledger + transaction flow |
| v1.0.0 | Stable API / production-ready | Breaking changes absorbed; stable contracts |

---

*Last updated: 2026-10-22*

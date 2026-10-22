# Mây Family Finance — Branch Strategy

## Overview

Branch protection and CI triggers are configured to enforce a structured development workflow.

## Branch Convention

| Pattern | Purpose | Pipeline Trigger |
|---------|---------|-----------------|
| `main` | Production-ready code | Main Release pipeline |
| `develop` | Integration branch (future) | Branch CI only |
| `feature/<name>` | New feature work | Branch CI only |
| `bugfix/<name>` | Bug fixes | Branch CI only |
| `release/<version>` | Pre-release stabilization | Branch CI only |
| `hotfix/<name>` | Urgent production fixes | Branch CI -> Main Release (when merged) |

## Branch Protection for main

The following must be configured in **Repository Settings -> Branch Rules**:

```yaml
branch: main
protection:
  require_pull_request: true
  required_approving_review_count: 1
  dismiss_stale_reviews: true
  require_conversation_resolution: true
  enforce_admins: true
  allow_force_pushes: false
  allow_deletions: false
  required_status_checks:
    strict: true
    checks:
      - Branch CI / Quality Gates
      - Branch CI / Build Android (APK + AAB)
```

## Merge Strategy

- **Squash merge** preferred for feature branches (clean linear history).
- **Rebase merge** acceptable for bugfixes.
- **Merge commits** acceptable when PR description adds valuable context.
- All merges must pass Branch CI before merging.

## Release Flow

```
feature/*  ->  PR -> main  ->  Branch CI passes  ->  squash merge  ->  Main Release triggered
```

After a merge to `main`:

1. Main Release pipeline executes automatically.
2. If quality gates pass, version is calculated from conventional commit prefixes.
3. Tag and GitHub Release are created.
4. Release artifacts (APK + AAB) are uploaded.

## Hotfix Procedure

1. Create `hotfix/<issue>` from the current release tag (not main).
2. Implement fix on the hotfix branch.
3. Open PR targeting `main`.
4. After CI passes and review approved, merge to `main`.
5. Main Release pipeline creates the versioned release automatically.

---

*Last updated: 2026-10-22*

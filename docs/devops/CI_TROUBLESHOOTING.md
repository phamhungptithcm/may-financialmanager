# Mây Family Finance — CI/CD Troubleshooting

## Common Failures and Remediation

### Flutter: `flutter pub get` fails

| Cause | Remedy |
|-------|--------|
| Network/dart pub blocked | Check runner network access; add proxy env vars if needed |
| SDK version constraint mismatch | Ensure `subosito/flutter-action` uses flutter >= 3.24.0 |
| Missing platform support | Android SDK/API levels must be installed on the runner (default in `ubuntu-latest`) |

### Flutter: `dart format --set-exit-code` fails

Run locally to fix:

```bash
cd apps/mobile && dart format lib/ --line-length 120
```

Commit the reformatted files and re-push.

### Flutter: `flutter analyze --no-fatal-infos` reports errors

```bash
cd apps/mobile && flutter analyze --write analysis_errors.json
cat analysis_errors.json | jq '.[] | select(.severity == "ERROR")'
```

Fix reported ERROR-level issues. INFO-level warnings are ignored (`--no-fatal-infos`).

### Functions: `npm ci` fails

| Cause | Remedy |
|-------|--------|
| No `package-lock.json` | Run `npm install` locally to generate lockfile, commit it |
| Node engine mismatch | Verify `package.json.engines.node` matches the runner's Node version (20) |

### Functions: TypeScript `tsc --noEmit` fails

```bash
cd functions && npx tsc --noEmit --pretty
```

Check for type errors, unused variables (`noUnusedLocals`), or path mapping issues. Verify `@may/contracts/*` paths resolve correctly.

### Functions: ESLint fails

```bash
cd functions && npx eslint src/ --ext .ts --fix   # auto-fix where possible
```

Review remaining manual fixes. Commit and re-push.

### Firebase Emulator: runs indefinitely or hangs

| Cause | Remedy |
|-------|--------|
| No test files match emulator hooks | This is informational -- add test files when Functions are implemented |
| Java not found on runner | The `setup-java@v4` action should provide Java; verify runner image |
| Rules file too small | RTDB rules must be substantive (>20 B) for the preflight check to pass |

### Security scan: gitleaks reports findings

```bash
# Run locally to inspect false positives
gitleaks detect --report-format json --report-path /tmp/gitleaks.json
cat /tmp/gitleaks.json | jq '.[] | {RuleID, Description, File, StartLine}'
```

If false positive: add to `.gitleaks.toml` ignore list.
If true positive: **do not commit secrets** -- use GitHub Secrets instead.

### Security scan: trivy blocks on CRITICAL/HIGH

Review findings in the job log. Filter by package type:

```bash
trivy fs --severity CRITICAL,HIGH . --format table
```

Fix vulnerabilities or document acceptable risk for third-party dependencies.

### Android build fails

| Cause | Remedy |
|-------|--------|
| Missing Android SDK components | `flutter doctor` -- install recommended packages |
| Gradle wrapper corrupted | Delete `.gradle/` and re-run `flutter pub get` |
| Java version mismatch | Ensure `java-version: '17'` matches Flutter's requirements |

### iOS build fails on macOS runner

| Cause | Remedy |
|-------|--------|
| Xcode version incompatibility | Update to latest stable Xcode via `xcode-select --switch` |
| CocoaPods issues | `cd ios && pod install` manually on the runner (add as step) |
| Missing signing credentials | Add `FLUTTER_IOS_PROVISIONING_PROFILE` and `FLUTTER_IOS_CERTIFICATE` secrets |

### Release: duplicate tag detected

The pipeline handles this automatically -- it checks `git rev-parse refs/tags/<VERSION>` before creating. No action needed; the run completes with a notice.

### Release: concurrent main push conflict

Concurrency group `main-release-${{ github.ref }}` serializes runs on the same ref. Only one release job creates tags at a time. The non-winning runner detects the existing tag and skips gracefully.

## Manual Recovery Procedures

### Re-run a failed pipeline

1. Go to **Actions** in the repository.
2. Find the failed run.
3. Click **Re-run all jobs**.

### Delete an accidental tag

```bash
git push origin --delete refs/tags/v0.x.y   # requires admin
# Then re-push to main (will produce correct version)
```

### Force a version number

```bash
VERSION=v1.0.0 git push origin main
```

### Bypass branch protection temporarily

Requires repository administrator access. Use only for emergency fixes:

```
Settings -> Branches -> Edit rule -> disable required checks (temporary)
```

Re-enable immediately after the fix lands.

## Pipeline Status Quick Reference

| Symbol | Meaning |
|--------|---------|
| OK | Passed -- all checks green |
| X  | Failed -- action required |
| W  | Warning -- non-blocking issue |
| O  | Skipped -- prerequisite not met (documented) |

---

*Last updated: 2026-10-22*

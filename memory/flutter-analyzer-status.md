---
name: flutter-analyzer-zero-errors
description: Flutter analyze results — zero errors after Phase 0 remediation
metadata:
  type: project
---

# Flutter Analysis Status (2026-10-23)

## Result: 0 ERRORS, 21 WARNINGS/INFO

### Errors resolved (~111 → 0):
- Analyzer crash fixed (may_app.dart broken MaterialApp.router syntax)
- All type mismatches fixed (router redirect, onTapOutside, snackbar return)
- All const/non-const issues fixed (MayElevation, may_theme light/dark)
- All invalid Dart syntax fixed (String! → String?, empty ternaries)
- All undefined method/class references fixed (DateFormat, HeadingData)
- money_test.dart getter invocation fixed (a.abs() → a.abs)

### Warnings remaining (non-blocking):
- 9 info-level: deprecated withOpacity APIs (Flutter 3.24+)
- 8 warnings: unused private elements/variables (Phase 0 scope, will be used in Phase 1)
- 4 warnings: unused imports on files that will gain usage in Phase 1

### Backend status:
- TypeScript: clean (npx tsc --noEmit passes)
- Tests: 66/66 passing (54 unit + 12 emulator stubs)

### Flutter SDK:
- Installed at ~/Desktop/FlutterSDK/flutter (ARM64 Linux, no prebuilt available)
- `flutter analyze` runs successfully with zero errors

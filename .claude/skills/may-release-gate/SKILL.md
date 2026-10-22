---
name: may-release-gate
description: Manually invoked pre-release Mây readiness audit covering exact HTML and approved FigJam .jam flow parity, Firebase rules/ledger, native widgets, OCR, push, App Store/Play billing and privacy; never deploys.
disable-model-invocation: true
---

# Release GO / NO-GO — Never executes release

**Target:** $ARGUMENTS

1. Check git status, original reference lock and current `.jam`/readable export hashes with `python3 scripts/reference_preflight.py --strict --require-flow-export --lock-check`. Any missing reference = NO-GO.
2. Review all implemented UI states and actual FigJam graph paths against browser reference, simulator/device screenshots, interaction and animation recordings; obtain human visual sign-off.
3. Run `scripts/verify_repository.sh`, Flutter tests, Firebase Emulator functions/rules/storage tests, security negative tests, financial concurrency/reconciliation checks and CI. No unsupported PASS claims.
4. Validate store sandbox purchase renew/revoke/refund, live localized storefront price, backend entitlements, consent/AdMob, private OCR, FCM quiet hours, widget redaction and crash reporting sanitization.
5. Verify backup/restore, exports/deletion compliance, infrastructure quotas, secrets, staging environment, documented rollback and peer review.
6. Audit `docs/qa/UI_FLOW_MATRIX.csv` and `docs/qa/BACKEND_TRACE_MATRIX.csv`, conflicts and screenshots. Produce GO/NO-GO with owners, links, missing evidence.
7. Do NOT run production deploy/publish, real purchases, migrations or irreversible operations. Owner must authorize a separate action.

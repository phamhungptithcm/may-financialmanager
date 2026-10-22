---
paths:
  - "apps/mobile/**"
  - "docs/qa/UI_FLOW_MATRIX.csv"
---
# UI/UX reference rule
Before changing Flutter UI, inspect approved `docs/FamilyClanMockupFullFlow.html` in source and browser. It is the correct Mây Finance mockup. Read `docs/Family Finance — End-to-end UX Flow.jam` through Figma or a reviewed hash-linked export (see `scripts/reference_preflight.py --strict --require-flow-export`), not by pretending `.jam` is a PNG. Reproduce all actual copy, UI states and animation transitions supported by evidence. No unverified 100% match claims. Never use a WebView to substitute for Flutter UI.

# Mây — Approved design inputs

**Owner confirmation (conversation, 2026-10-21):** `docs/FamilyClanMockupFullFlow.html` represents the **Mây Family Finance** UI/UX prototype. The filename is historical and must remain unchanged unless explicitly approved. Do not classify it as genealogy design solely from filename.

- `docs/FamilyClanMockupFullFlow.html`: authoritative visual styles, screens, labels, HTML/CSS/JS transitions and observed UI flow.
- `docs/Family Finance — End-to-end UX Flow.jam`: authoritative journey graph, node/edge labels and navigation behavior. Treat this as an opaque FigJam source until verified with Figma access or a reviewed export.
- `docs/specs/*`: authoritative domain logic, Firebase architecture, RTDB schema, backend Functions, policies and tests.

### Evidence requirement

A FigJam export is valid only when `docs/qa/design-references/flow-export-manifest.json` records current `.jam` SHA-256 and export SHA-256, export content is readable, and a reviewer has verified equivalence. Hashes establish change detection, NOT semantic fidelity.

DO NOT mutate the originals to make tooling work. Do not mark any UI flow completed from an unknown/unreviewed diagram.

# Screen-level UI fidelity checklist

Sources: HTML `docs/FamilyClanMockupFullFlow.html` (approved Mây prototype), FigJam `docs/Family Finance — End-to-end UX Flow.jam`, reviewed readable export with SHA manifest and `docs/specs/02_UI_UX.md`.

- [ ] Reference preflight passes with `--require-flow-export` and lock check if present.
- [ ] HTML DOM/CSS/JS states and responsive behavior inventoried, **opened in browser**; every interactive path exercised.
- [ ] Actual FigJam nodes and edges transcribed from readable source/export; every branch mapped to Flutter and expected backend command.
- [ ] Typography, baseline, line height, Vietnamese text, colors, corner radius, shadows, grids, safe areas, nav bars, modal and sheet geometry match reference in same-size screenshots.
- [ ] Gesture/keyboard/back navigation, scan receipt manual fallback, widgets reorder/persist, Plus no-ads, native push privacy and locks tested.
- [ ] Animation and transitions tested with actual duration/easing/trigger/effect based on CSS/JS or explicit spec; Reduce Motion honored.
- [ ] Empty/loading/offline/error/permission denied/validation states available.
- [ ] Screenshots and motion clips from reference and emulator/physical devices are stored with test IDs and reviewed; unsupported comparisons flagged BLOCKED, never PASS.
- [ ] Backend authorizations and data outcomes preserve actual specs. No WebView shortcuts or mock-based fake production.

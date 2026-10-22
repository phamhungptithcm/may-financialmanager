---
name: may-ui-fidelity
description: Reproduce and verify Flutter screens, Vietnamese copy, components, widget UX, gestures, animation and transitions using the owner-approved Mây HTML prototype and genuine FigJam .jam flow evidence.
---

# UI fidelity workflow

**Task:** $ARGUMENTS

1. Run `python3 scripts/reference_preflight.py --strict --require-flow-export` (add `--lock-check` if reviewed lock exists). The owner confirmed `docs/FamilyClanMockupFullFlow.html` is the Mây prototype despite its filename. `.jam` is the flow source, not a PNG.
2. Read HTML DOM/CSS/JS and all states, transitions, keyframes and responsive rules. Render and interact with the HTML in browser; do not infer motion purely from screenshots.
3. Inspect full genuine `docs/Family Finance — End-to-end UX Flow.jam` via Figma tools or approved export; transcribe literal graph nodes/edges. Invoke `/may-ux-flow-audit` where needed.
4. Map reference DOM selector / screen → literal FigJam node and edge → Flutter route/state/component → backend command → screenshot and test.
5. Create Flutter-native reusable tokens/components; not WebViews or generic UI. Match text, spacing, scale, safe area, shadows, colors, outlines, keyboard, sheets, charts, drag/reorder state, dark mode if shown and accessibility.
6. Record motion precisely: trigger, duration, easing, delay, direction, layering, gesture interruption and Reduce Motion variant from source. If not defined label UNSPECIFIED; don't invent visually significant transitions.
7. Capture screenshots at matching viewport/locale/text scale and interaction recordings on iOS/Android as supported; use `scripts/visual_compare.py` as advisory only. Diff threshold alone never proves 100%.
8. Update `docs/qa/UI_FLOW_MATRIX.csv` with genuine proof and PASS/FAIL/BLOCKED status, owner reviewer and deviations/ADR. Backend contracts always override UI fiction about finance authorization or payment success.

Blocked references = report BLOCKED and refrain from UI implementation of unsupported flows.

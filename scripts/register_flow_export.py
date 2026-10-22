#!/usr/bin/env python3
"""Bind manually exported FigJam flow PNG/SVG to the current .jam source by SHA256.

Does NOT approve source-export visual/semantic fidelity. Reviewer must verify and
manually change review_status to APPROVED with reviewer and reviewed_at timestamp.
"""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'docs/Family Finance — End-to-end UX Flow.jam'
EVIDENCE_DIR = ROOT / 'docs/qa/design-references'
MANIFEST = EVIDENCE_DIR / 'flow-export-manifest.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--export', required=True, help='Owner-exported relative or absolute PNG/SVG inside docs/qa/design-references')
    args = p.parse_args()
    if not SOURCE.is_file() or SOURCE.stat().st_size == 0:
        p.error('Original .jam source missing')
    target = Path(args.export)
    if not target.is_absolute(): target = ROOT / target
    target = target.resolve()
    if not target.is_relative_to(EVIDENCE_DIR.resolve()) or target.suffix.lower() not in ('.png', '.svg'):
        p.error('Export must be PNG/SVG inside docs/qa/design-references')
    if not target.is_file() or not target.stat().st_size:
        p.error('Export missing or empty')
    b = target.read_bytes()[:4096]
    if target.suffix.lower() == '.png' and not b.startswith(b'\x89PNG\r\n\x1a\n'):
        p.error('Not a PNG')
    if target.suffix.lower() == '.svg' and b'<svg' not in b:
        p.error('Not an SVG')
    # Explicitly reset approval on re-registration to avoid trusting stale reviewer signoff.
    data = {'schema_version': 1,
            'source_path': SOURCE.relative_to(ROOT).as_posix(),
            'source_sha256': digest(SOURCE),
            'export_path': target.relative_to(ROOT).as_posix(),
            'export_sha256': digest(target),
            'review_status': 'PENDING_REVIEW',
            'reviewer': '',
            'reviewed_at': '',
            'review_note': 'Reviewer must verify EVERY actual node, edge, conditional label and crop against FigJam source before APPROVED.'}
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', 'utf-8')
    print('Registered source/export SHA256. Approval deliberately PENDING_REVIEW. Review and commit:', MANIFEST.relative_to(ROOT))


if __name__ == '__main__': main()

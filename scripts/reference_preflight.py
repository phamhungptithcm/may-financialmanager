#!/usr/bin/env python3
"""Validate original HTML + opaque FigJam .jam; optionally require a reviewed export.

Never edits original references. --write-lock creates a reviewed-commit candidate,
not proof of reference authenticity; the owner must inspect and commit it.
"""
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
HTML = DOCS / "FamilyClanMockupFullFlow.html"
JAM = DOCS / "Family Finance — End-to-end UX Flow.jam"
EXPORT_DIR = DOCS / "qa" / "design-references"
MANIFEST = EXPORT_DIR / "flow-export-manifest.json"
LOCK = DOCS / "qa" / "reference-lock.json"
REQUIRED = [
    "README.md", "MANIFEST.json", "specs/00_DECISIONS_SCOPE.md",
    "specs/01_PRD.md", "specs/02_UI_UX.md", "specs/03_ARCHITECTURE.md",
    "specs/04_RTDB_SCHEMA.md", "specs/05_FUNCTIONS_CATALOG.md",
    "specs/06_API_CONTRACTS.md", "specs/07_INTEGRATIONS.md",
    "specs/08_SECURITY_PRIVACY.md", "specs/09_COMPONENT_LIBRARY.md",
    "specs/10_TESTING_ACCEPTANCE.md", "specs/11_DELIVERY_PLAN.md",
    "specs/13_CONFIGURATION_RUNBOOK.md", "contracts/domain-contracts.ts",
    "firebase/database.rules.json", "firebase/storage.rules",
    "qa/TRACEABILITY.md", "qa/VERIFICATION.md",
]


def sha256(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for piece in iter(lambda: f.read(1024 * 1024), b""):
            h.update(piece)
    return h.hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def inspect_export(errors, warnings, refs, required):
    if not MANIFEST.is_file():
        message = "No FigJam export manifest: docs/qa/design-references/flow-export-manifest.json"
        (errors if required else warnings).append(message)
        return
    try:
        manifest = json.loads(MANIFEST.read_text('utf-8'))
        target_rel = manifest['export_path']
        # Never use untrusted manifest path outside approved evidence directory.
        target = (ROOT / target_rel).resolve(strict=False)
        if not target.is_relative_to(EXPORT_DIR.resolve()) or target.suffix.lower() not in ('.png', '.svg'):
            raise ValueError('export_path must point to an approved .png/.svg under docs/qa/design-references')
        if not target.is_file() or target.stat().st_size == 0:
            raise ValueError('Referenced export file is missing or empty')
        sig = target.read_bytes()[:300]
        if target.suffix.lower() == '.png' and not sig.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError('Referenced PNG does not have PNG magic header')
        if target.suffix.lower() == '.svg' and b'<svg' not in sig and b'<svg' not in target.read_bytes()[:4096]:
            raise ValueError('Referenced SVG does not contain an SVG element')
        if manifest.get('source_path') != relative(JAM):
            raise ValueError('Manifest points to the wrong FigJam source')
        if sha256(JAM) != manifest.get('source_sha256'):
            raise ValueError('FigJam .jam source differs from registered export source hash; re-export/re-review')
        if sha256(target) != manifest.get('export_sha256'):
            raise ValueError('Export changed after registration; re-review')
        if manifest.get('review_status') != 'APPROVED' or not manifest.get('reviewer') or not manifest.get('reviewed_at'):
            raise ValueError('Export must be reviewed and explicitly APPROVED; hash consistency alone is not enough')
        refs['flow_export'] = {'path': relative(target), 'size_bytes': target.stat().st_size,
                               'sha256': sha256(target), 'reviewer': manifest['reviewer'],
                               'reviewed_at': manifest['reviewed_at']}
    except (OSError, ValueError, KeyError, TypeError) as ex:
        (errors if required else warnings).append('FigJam export not approved/readable: ' + str(ex))


def analyze(require_flow_export=False):
    errors, warnings, files = [], [], {}
    for label, path in (('html', HTML), ('figjam', JAM)):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append('Missing original reference: ' + relative(path))
            continue
        files[label] = {'path': relative(path), 'size_bytes': path.stat().st_size,
                        'sha256': sha256(path)}
    if HTML.is_file() and HTML.stat().st_size:
        txt = HTML.read_text('utf-8', errors='replace')
        if not re.search(r'<(?:html|body|main|div|section)(?:\s|>)', txt, re.I):
            errors.append('HTML prototype does not appear to contain valid app markup')
        title = re.search(r'<title[^>]*>(.*?)</title\s*>', txt, re.I | re.S)
        files['html']['title'] = re.sub(r'\s+', ' ', title.group(1)).strip()[:120] if title else '(none)'
        files['html']['css_keyframes'] = sorted(set(re.findall(r'@keyframes\s+([\w-]+)', txt)))[:40]
        # File name FamilyClan is owner-approved and is NOT a mismatch by itself.
        finance_words = ('chi tiêu', 'thu nhập', 'ngân sách', 'income', 'expense', 'finance', 'budget', 'transaction', 'tiết kiệm', 'tài sản')
        if not any(x in txt.lower() for x in finance_words):
            warnings.append('No obvious finance keywords detected in HTML content; owner has confirmed this is Mây prototype, inspect live behavior before UI work')
    if JAM.is_file() and JAM.stat().st_size:
        if JAM.read_bytes()[:8].startswith(b'\x89PNG\r\n\x1a\n'):
            errors.append('Original flow is PNG bytes renamed to .jam; verify the genuine FigJam source')
        warnings.append('Original .jam is treated as opaque: an actual Figma read or approved export is needed to inspect nodes/edges')
        inspect_export(errors, warnings, files, require_flow_export)
    missing = [str(Path('docs') / p) for p in REQUIRED if not (DOCS / p).is_file()]
    if missing: errors.extend('Missing required specification: ' + p for p in missing)
    if not list((DOCS / 'schemas').glob('*.json')):
        errors.append('Missing JSON schemas in docs/schemas')
    return {'ok': not errors, 'project_root': str(ROOT), 'references': files,
            'required_flow_export': require_flow_export, 'missing_specs': missing,
            'errors': errors, 'warnings': warnings, 'lock_exists': LOCK.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--strict', action='store_true', help='exit with status 2 if preflight fails')
    parser.add_argument('--require-flow-export', action='store_true', help='require SHA linked, human APPROVED full FigJam flow export')
    parser.add_argument('--lock-check', action='store_true', help='require current hashes to match owner-reviewed lock')
    parser.add_argument('--write-lock', action='store_true', help='write lock candidate after successful preflight; review before commit')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    result = analyze(args.require_flow_export)
    if args.write_lock:
        if result['errors']:
            result['errors'].append('Cannot write reference lock while preflight is blocked')
        else:
            LOCK.parent.mkdir(parents=True, exist_ok=True)
            content = {v['path']: v['sha256'] for v in result['references'].values()}
            LOCK.write_text(json.dumps({'schema_version': 2, 'references_sha256': content}, indent=2, ensure_ascii=False) + '\n', 'utf-8')
            result['lock_created'] = relative(LOCK)
    if args.lock_check:
        if not LOCK.is_file():
            result['errors'].append('Reviewed docs/qa/reference-lock.json missing')
        else:
            try:
                data = json.loads(LOCK.read_text('utf-8'))['references_sha256']
                for item in result['references'].values():
                    if data.get(item['path']) != item['sha256']:
                        result['errors'].append('Approved reference differs from lock: ' + item['path'])
            except (OSError, KeyError, ValueError) as ex:
                result['errors'].append('Invalid reference lock: ' + str(ex))
    result['ok'] = not result['errors']
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print('Mây reference preflight: ' + ('PASS' if result['ok'] else 'BLOCKED'))
        for label, item in result['references'].items():
            print(f"  {label}: {item['path']} (SHA256 {item['sha256'][:12]}...)")
        for warning in result['warnings']: print('  WARN:', warning)
        for error in result['errors']: print('  BLOCK:', error)
    return 0 if result['ok'] or not args.strict else 2


if __name__ == '__main__':
    sys.exit(main())

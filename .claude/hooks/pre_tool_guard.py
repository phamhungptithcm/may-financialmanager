#!/usr/bin/env python3
"""Mây Claude PreToolUse guard: mitigates accidental unsafe edits, NOT a sandbox."""
import hashlib
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get('CLAUDE_PROJECT_DIR', Path(__file__).resolve().parents[2])).resolve()
HTML = 'docs/FamilyClanMockupFullFlow.html'
JAM = 'docs/Family Finance — End-to-end UX Flow.jam'
LOCK = 'docs/qa/reference-lock.json'
EXPORT_MANIFEST = 'docs/qa/design-references/flow-export-manifest.json'


def respond(kind, why):
    print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse',
                'permissionDecision': kind, 'permissionDecisionReason': why}}, ensure_ascii=False))


def normal_path(value):
    try:
        p = Path(value)
        full = (p if p.is_absolute() else ROOT / p).resolve()
        return full.relative_to(ROOT).as_posix()
    except (OSError, ValueError, TypeError):
        return None


def sha256(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def inputs_ready(ui=False):
    paths = [ROOT / HTML, ROOT / JAM]
    if not all(p.is_file() and p.stat().st_size > 0 for p in paths): return False
    lock_path = ROOT / LOCK
    if lock_path.is_file():
        try:
            hashes = json.loads(lock_path.read_text('utf-8'))['references_sha256']
            if any(hashes.get(p.relative_to(ROOT).as_posix()) != sha256(p) for p in paths): return False
        except (OSError, ValueError, KeyError): return False
    if ui:
        mf = ROOT / EXPORT_MANIFEST
        if not mf.is_file(): return False
        try:
            meta = json.loads(mf.read_text('utf-8'))
            exp = (ROOT / meta['export_path']).resolve()
            if not exp.is_relative_to((ROOT / 'docs/qa/design-references').resolve()): return False
            if not exp.is_file() or exp.suffix.lower() not in ('.png', '.svg'): return False
            if meta.get('review_status') != 'APPROVED' or not meta.get('reviewer') or not meta.get('reviewed_at'): return False
            if meta.get('source_path') != JAM or sha256(ROOT / JAM) != meta['source_sha256']: return False
            if sha256(exp) != meta['export_sha256']: return False
        except (OSError, ValueError, KeyError): return False
    return True


def main():
    try: body = json.load(sys.stdin)
    except (OSError, ValueError): return 0
    tool = body.get('tool_name') or ''
    payload = body.get('tool_input') or {}
    if tool in ('Write', 'Edit', 'MultiEdit', 'NotebookEdit'):
        raw = payload.get('file_path') or payload.get('notebook_path')
        if not raw: return 0
        path = normal_path(raw)
        if path is None:
            respond('ask', 'Write target outside repository requires explicit approval')
        elif path in (HTML, JAM, LOCK, EXPORT_MANIFEST) or (path.startswith('docs/') and not path.startswith('docs/qa/')):
            respond('deny', 'Approved design/source contracts are protected. Propose ADR and obtain explicit owner approval; do not edit original reference.')
        elif path.startswith('apps/mobile/') and not inputs_ready(ui=True):
            respond('deny', 'UI implementation requires genuine .jam source AND reviewer-approved FigJam export provenance. Run preflight --require-flow-export.')
        elif path.startswith('functions/') and not inputs_ready():
            respond('deny', 'Missing or changed original Mây reference HTML / FigJam .jam. Run preflight before backend implementation.')
        elif not path.startswith(('.claude/', 'scripts/', '.github/', 'docs/qa/', 'apps/', 'functions/', 'packages/')) and not inputs_ready():
            respond('deny', 'Missing original references or inconsistent lock. Resolve before implementation edits.')
    elif tool == 'Bash':
        cmd = payload.get('command') or ''
        hard_deny = (r'\bgit\s+(?:reset\s+--hard|clean\s+-f|push\b[^\n]*--force)',
                     r'\bfirebase\s+(?:database:remove|projects:delete)',
                     r'\b(?:rm|mv|cp|truncate)\b[^\n]*(?:FamilyClanMockupFullFlow|End-to-end UX Flow\.jam|reference-lock\.json)')
        require_permission = (r'\bfirebase\s+deploy\b',r'\bfastlane\b[^\n]*(?:release|deliver|supply|pilot)',
                              r'\brm\s+-[A-Za-z]*r[A-Za-z]*f\b',r'\bflutter\s+build\s+(?:ipa|appbundle)\b',
                              r'\b(?:gcloud|gsutil)\b[^\n]*(?:delete|rm|deploy)')
        if any(re.search(p, cmd, re.I) for p in hard_deny):
            respond('deny', 'Potential destructive action or approved reference mutation is prohibited')
        elif any(re.search(p, cmd, re.I) for p in require_permission):
            respond('ask', 'Production, publishing or irreversible command requires explicit owner approval')
    return 0


if __name__ == '__main__': sys.exit(main())

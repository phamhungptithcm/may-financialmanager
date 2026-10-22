#!/usr/bin/env python3
"""Validate Claude Code-discoverable skills, subagents, settings and Mây references."""
import argparse
import json
import re
from pathlib import Path

SKILLS = ('may-implement-feature', 'may-ui-fidelity', 'may-ux-flow-audit',
          'may-firebase-contracts', 'may-financial-integrity', 'may-release-gate')
AGENTS = ('may-design-auditor.md', 'may-backend-contract-auditor.md', 'may-finance-security-auditor.md')
REFERENCES = ('FamilyClanMockupFullFlow.html', 'Family Finance — End-to-end UX Flow.jam')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--project-root', default='.')
    p.add_argument('--check-references', action='store_true')
    args = p.parse_args()
    root = Path(args.project_root).expanduser().resolve()
    errs = []
    for filename in ('CLAUDE.md', 'AGENTS.md'):
        if not (root / filename).is_file(): errs.append(f'Missing {filename}')
    settings = root / '.claude/settings.json'
    try:
        cfg = json.loads(settings.read_text('utf-8'))
        if not cfg.get('hooks',{}).get('PreToolUse'):
            errs.append('Missing PreToolUse policy hook (may be intentional if existing settings require manual merge)')
    except (OSError, ValueError) as e: errs.append(f'Bad Claude settings: {e}')
    for name in SKILLS:
        fn = root / '.claude/skills' / name / 'SKILL.md'
        if not fn.is_file(): errs.append('Missing skill: ' + name); continue
        txt = fn.read_text('utf-8')
        if not txt.startswith('---\n') or '\n---\n' not in txt[4:]:
            errs.append('Invalid skill YAML fence: '+name); continue
        front = txt.split('---', 2)[1]
        if not re.search(r'^name:\s*'+re.escape(name)+r'\s*$', front, re.M): errs.append('Wrong frontmatter name: '+name)
        if not re.search(r'^description:\s*\S+', front, re.M): errs.append('Missing description: '+name)
        print('Skill:', name)
    for fn in AGENTS:
        if not (root / '.claude/agents' / fn).is_file(): errs.append('Missing subagent: ' + fn)
    if (root / 'May/.claude/skills').exists(): errs.append('Wrong nested May/May/.claude folder found')
    for filename in REFERENCES:
        ref = root / 'docs' / filename
        if not ref.is_file() or ref.stat().st_size == 0:
            print('Missing design original: docs/' + filename)
            if args.check_references: errs.append('Missing design original: '+filename)
        else: print('Reference:', filename)
    for e in errs: print('ERROR:', e)
    print('SKILLS:', 'PASS' if not errs else 'FAIL', f'({len(SKILLS)} registered)')
    return 0 if not errs else 1


if __name__ == '__main__': raise SystemExit(main())

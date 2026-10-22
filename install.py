#!/usr/bin/env python3
"""Install Mây's Claude Code overlay safely into an existing May project.

No files are overwritten, no commands are executed in the target repository.
"""
from __future__ import annotations
import argparse
import filecmp
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EXCLUDE = {'install.py', 'verify_skills.py', 'PACKAGING_MANIFEST.json'}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-root', required=True, help='Existing May repository root (the folder with docs/)')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes only')
    args = parser.parse_args()
    project = Path(args.project_root).expanduser().resolve()
    if project == ROOT:
        print('ERROR: Source and destination are the same directory.', file=sys.stderr)
        return 2
    if not project.is_dir() or not (project/'docs').is_dir():
        print('ERROR: Destination must be an existing May project containing docs/.', file=sys.stderr)
        return 2
    statuses={'ADD':0,'EXISTS':0,'CONFLICT':0}
    for source in sorted(ROOT.rglob('*')):
        if not source.is_file() or source.name in EXCLUDE or '__pycache__' in source.parts or source.suffix == '.pyc':
            continue
        rel = source.relative_to(ROOT)
        target = project / rel
        if target.exists():
            status = 'EXISTS' if target.is_file() and filecmp.cmp(source,target,shallow=False) else 'CONFLICT'
        else:
            status = 'ADD'
            if not args.dry_run:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source,target)
        print(f'{status:8} {rel.as_posix()}')
        statuses[status] += 1
    print('Summary:',statuses,'DRY RUN' if args.dry_run else 'INSTALLED')
    if statuses['CONFLICT']:
        print('Existing different files have NOT been overwritten. Manually merge relevant changes (especially CLAUDE.md, AGENTS.md, .claude/settings.json).')
    print('Then: python3 verify_skills.py --project-root '+str(project))
    return 0

if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Validate Mây implementation traceability reports; never invent missing test evidence."""
import argparse
import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TABLES = {
    "UI_FLOW_MATRIX.csv": ("req_id", "html_screen_selector", "flow_jam_node", "flow_jam_edge",
                           "flutter_route", "ui_state", "motion_contract", "evidence_ref",
                           "evidence_actual", "diff_image", "test_id", "status"),
    "BACKEND_TRACE_MATRIX.csv": ("req_id", "function_name", "contract_ref", "auth_role", "db_paths",
                               "rules", "emulator_test", "status", "evidence"),
}
VALID = {"NOT_STARTED", "IN_PROGRESS", "PASS", "FAIL", "BLOCKED", "APPROVED_EXCEPTION"}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--release", action="store_true", help="require nonempty matrices and no incomplete/failing rows")
    args = p.parse_args()
    problems = []; counts = {}
    for filename, required in TABLES.items():
        path = ROOT / "docs/qa" / filename
        if not path.is_file():
            problems.append(f"Missing traceability: {path.relative_to(ROOT)}")
            continue
        with path.open(encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            absent = [k for k in required if k not in (reader.fieldnames or [])]
            if absent:
                problems.append(f"{filename} missing columns: {', '.join(absent)}")
                continue
            rows = list(reader)
        counts[filename] = len(rows)
        if args.release and not rows:
            problems.append(f"{filename}: no traced implementations; cannot certify release")
        for n, row in enumerate(rows, start=2):
            status = row.get("status", "")
            if status not in VALID:
                problems.append(f"{filename}:{n}: invalid status {status!r}")
            if status == "PASS":
                for k in required:
                    if not (row.get(k) or "").strip():
                        problems.append(f"{filename}:{n}: PASS without {k} evidence")
            if args.release and status != "PASS":
                # APPROVED_EXCEPTION is allowed only with explicit signed-off review outside this file
                problems.append(f"{filename}:{n}: release not ready: {status}")
    for name, count in counts.items(): print(f"{name}: {count} rows")
    for problem in problems: print("BLOCKED:", problem, file=sys.stderr)
    print(f"Audit: {'PASS' if not problems else 'BLOCKED'}")
    return 0 if not problems else 2

if __name__ == "__main__": sys.exit(main())

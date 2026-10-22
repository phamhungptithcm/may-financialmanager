#!/usr/bin/env python3
"""Advisory pixel screenshot comparison; NOT a substitute for flow/motion/manual review.

Dependencies: Pillow (pip install Pillow in a project-local venv).
"""
import argparse
import json
import sys
from pathlib import Path
try:
    from PIL import Image, ImageChops, ImageEnhance, ImageStat
except ImportError:
    print("BLOCKED: Pillow is required for visual diff; install into project-local venv", file=sys.stderr)
    raise SystemExit(3)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("reference")
    p.add_argument("actual")
    p.add_argument("--output", default="docs/qa/evidence/visual-diff.png")
    p.add_argument("--max-mae", type=float, default=None,
                   help="Optional mean absolute RGB error limit [0,1]; only use with approved same-renderer baselines")
    args = p.parse_args()
    with Image.open(args.reference) as src, Image.open(args.actual) as candidate:
        a, b = src.convert("RGB"), candidate.convert("RGB")
        if a.size != b.size:
            print(f"BLOCKED: same viewport required; reference={a.size}, actual={b.size}", file=sys.stderr)
            return 2
        d = ImageChops.difference(a, b)
        stat = ImageStat.Stat(d)
        mae = sum(stat.mean) / (3.0 * 255.0)
        bbox = d.getbbox()
        out = Path(args.output); out.parent.mkdir(parents=True, exist_ok=True)
        ImageEnhance.Contrast(d).enhance(2.8).save(out)
        result = {"reference": args.reference, "actual": args.actual, "image_size": list(a.size),
                  "normalized_mae": round(mae, 6), "diff_bbox": bbox, "diff_file": str(out),
                  "caveat": "Raster metrics do not test motion, flows or perceptual match. Different HTML/Flutter text rasterizers need manual review."}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 1 if args.max_mae is not None and mae > args.max_mae else 0

if __name__ == "__main__":
    sys.exit(main())

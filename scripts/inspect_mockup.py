#!/usr/bin/env python3
"""Extract audit hints from approved HTML; browser walkthrough remains mandatory."""
import argparse
import json
import re
import sys
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/FamilyClanMockupFullFlow.html"

class Inspector(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.views, self.handlers, self.links, self.buttons, self.elements = [], [], [], [], [], Counter()

    def handle_starttag(self, tag, attrs):
        a = dict(attrs); self.elements[tag] += 1
        if a.get("id"): self.ids.append(a["id"])
        if tag in {"section", "main", "article", "nav"} or any(k in a for k in ("data-screen", "data-page", "data-view", "data-route")):
            self.views.append({"tag": tag, "id": a.get("id"), "class": a.get("class"),
                               "screen": {k: a[k] for k in ("data-screen", "data-page", "data-view", "data-route") if k in a}})
        if a.get("onclick"): self.handlers.append({"tag": tag, "id": a.get("id"), "onclick": a["onclick"][:250]})
        if tag == "a" and a.get("href"): self.links.append(a["href"])
        if tag in ("button", "input", "select", "textarea"):
            self.buttons.append({"tag": tag, "id": a.get("id"), "class": a.get("class"),
                                 "type": a.get("type"), "aria-label": a.get("aria-label")})


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--out", help="Write inventory as JSON to this relative path (default stdout only)")
    args = p.parse_args()
    if not SRC.exists():
        print(f"BLOCKED: required mockup unavailable: {SRC}", file=sys.stderr); return 2
    txt = SRC.read_text(encoding="utf-8", errors="replace")
    parser = Inspector(); parser.feed(txt)
    styles = dict(re.findall(r"(--[a-zA-Z][\w-]*)\s*:\s*([^;}]+)", txt))
    data = {"source": str(SRC.relative_to(ROOT)), "caveat": "Heuristic source inventory. JS-created views and event delegation MUST be checked in browser.",
            "counts": dict(parser.elements), "screen_or_structural_elements": parser.views,
            "ids": parser.ids, "inline_handlers": parser.handlers, "links": sorted(set(parser.links)),
            "form_controls": parser.buttons, "css_custom_properties": styles,
            "keyframes": sorted(set(re.findall(r"@keyframes\s+([\w-]+)", txt))),
            "transition_declarations": re.findall(r"\btransition\s*:\s*([^;}]+)", txt)[:100],
            "animation_declarations": re.findall(r"\banimation\s*:\s*([^;}]+)", txt)[:100]}
    out = json.dumps(data, indent=2, ensure_ascii=False)
    if args.out:
        dest = ROOT / args.out
        if not dest.resolve().is_relative_to((ROOT / "docs/qa").resolve()):
            print("BLOCKED: inventory output must be under docs/qa/", file=sys.stderr); return 2
        dest.parent.mkdir(parents=True, exist_ok=True); dest.write_text(out + "\n", encoding="utf-8")
        print(f"Wrote {dest.relative_to(ROOT)}")
    else:
        print(out)
    return 0

if __name__ == "__main__": sys.exit(main())

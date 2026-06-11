#!/usr/bin/env python3
"""Classify PDF as TEXT, SCANNED, or MIXED before extraction.

Heuristic: sample pages, check ratio of extractable text vs page count.
- TEXT:    >80% pages have meaningful text
- SCANNED: <20% pages have meaningful text
- MIXED:   in between

Exits 0 always. Prints classification + per-page char counts.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

MIN_CHARS_PER_PAGE = 50


def classify(path: Path, sample: int) -> int:
    try:
        import pypdf
    except ImportError:
        print("ERROR: pypdf not installed. Run: pip install pypdf", file=sys.stderr)
        return 2

    reader = pypdf.PdfReader(str(path))
    total = len(reader.pages)
    sample_n = min(sample, total) if sample else total

    counts: list[int] = []
    for i in range(sample_n):
        try:
            text = reader.pages[i].extract_text() or ""
        except Exception:
            text = ""
        counts.append(len(text.strip()))

    text_pages = sum(1 for c in counts if c >= MIN_CHARS_PER_PAGE)
    ratio = text_pages / sample_n if sample_n else 0

    if ratio >= 0.8:
        verdict = "TEXT"
    elif ratio <= 0.2:
        verdict = "SCANNED"
    else:
        verdict = "MIXED"

    print(f"file: {path}")
    print(f"pages: {total} (sampled {sample_n})")
    print(f"text_pages: {text_pages}/{sample_n} ({ratio:.0%})")
    print(f"verdict: {verdict}")
    print()
    print("per-page chars:")
    for i, c in enumerate(counts):
        marker = "T" if c >= MIN_CHARS_PER_PAGE else "."
        print(f"  p{i + 1:>4}: {c:>6} {marker}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file", type=Path)
    ap.add_argument("--sample", type=int, default=0, help="sample first N pages (0=all)")
    args = ap.parse_args()
    if not args.file.exists():
        print(f"ERROR: {args.file} not found", file=sys.stderr)
        return 1
    return classify(args.file, args.sample)


if __name__ == "__main__":
    raise SystemExit(main())

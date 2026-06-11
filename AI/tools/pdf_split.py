#!/usr/bin/env python3
"""Slice PDF page range into smaller file.

Usage: pdf_split.py input.pdf --pages 5-20 [--out output.pdf]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def parse_range(spec: str, total: int) -> list[int]:
    pages: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-", 1)
            pages.update(range(int(a), int(b) + 1))
        else:
            pages.add(int(part))
    return sorted(p for p in pages if 1 <= p <= total)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file", type=Path)
    ap.add_argument("--pages", required=True, help="e.g. 5-20 or 1,3,5-10")
    ap.add_argument("--out", type=Path, help="output path (default: <stem>_p<spec>.pdf)")
    args = ap.parse_args()

    if not args.file.exists():
        print(f"ERROR: {args.file} not found", file=sys.stderr)
        return 1

    try:
        import pypdf
    except ImportError:
        print("ERROR: pip install pypdf", file=sys.stderr)
        return 2

    reader = pypdf.PdfReader(str(args.file))
    total = len(reader.pages)
    pages = parse_range(args.pages, total)
    if not pages:
        print("ERROR: no valid pages in range", file=sys.stderr)
        return 1

    writer = pypdf.PdfWriter()
    for p in pages:
        writer.add_page(reader.pages[p - 1])

    out = args.out or args.file.with_name(
        f"{args.file.stem}_p{args.pages.replace(',', '_')}.pdf"
    )
    with open(out, "wb") as f:
        writer.write(f)
    print(f"wrote {len(pages)} pages -> {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

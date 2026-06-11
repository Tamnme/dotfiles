#!/usr/bin/env python3
"""Extract tables from PDF. Try camelot first, fall back to pdfplumber.

Output: CSV files (one per table) into --out dir, or stdout if --out omitted.

Deps:
- camelot-py[cv] (ghostscript required) OR
- pdfplumber (pure python)
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def try_camelot(path: Path, pages: str, out: Path | None) -> int:
    try:
        import camelot
    except ImportError:
        return -1
    tables = camelot.read_pdf(str(path), pages=pages or "all")
    if not tables or tables.n == 0:
        return 0
    if out:
        out.mkdir(parents=True, exist_ok=True)
        for i, t in enumerate(tables):
            t.to_csv(str(out / f"table_{i + 1:03d}_p{t.page}.csv"))
        print(f"# wrote {tables.n} tables to {out}", file=sys.stderr)
    else:
        for i, t in enumerate(tables):
            print(f"===== table {i + 1} (page {t.page}) =====")
            print(t.df.to_csv(index=False))
    return tables.n


def try_pdfplumber(path: Path, pages_spec: str | None, out: Path | None) -> int:
    try:
        import pdfplumber
    except ImportError:
        return -1
    pages_filter: set[int] | None = None
    if pages_spec:
        pages_filter = set()
        for part in pages_spec.split(","):
            if "-" in part:
                a, b = part.split("-", 1)
                pages_filter.update(range(int(a), int(b) + 1))
            else:
                pages_filter.add(int(part))

    count = 0
    if out:
        out.mkdir(parents=True, exist_ok=True)
    with pdfplumber.open(str(path)) as pdf:
        for pno, page in enumerate(pdf.pages, start=1):
            if pages_filter and pno not in pages_filter:
                continue
            for ti, tbl in enumerate(page.extract_tables() or []):
                count += 1
                rows = ["\t".join(c or "" for c in row) for row in tbl]
                content = "\n".join(rows)
                if out:
                    (out / f"table_{count:03d}_p{pno}.tsv").write_text(content)
                else:
                    print(f"===== table {count} (page {pno}) =====")
                    print(content)
    if out:
        print(f"# wrote {count} tables to {out}", file=sys.stderr)
    return count


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file", type=Path)
    ap.add_argument("--pages", default="", help="e.g. 1-5,7 (camelot uses 'all' default)")
    ap.add_argument("--out", type=Path, help="output dir for CSV/TSV files")
    args = ap.parse_args()

    if not args.file.exists():
        print(f"ERROR: {args.file} not found", file=sys.stderr)
        return 1

    n = try_camelot(args.file, args.pages, args.out)
    if n >= 0:
        return 0
    print("# camelot unavailable, trying pdfplumber", file=sys.stderr)
    n = try_pdfplumber(args.file, args.pages or None, args.out)
    if n < 0:
        print("ERROR: install camelot-py[cv] or pdfplumber", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

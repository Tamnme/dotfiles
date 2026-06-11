#!/usr/bin/env python3
"""Extract text from PDF. Auto-select pdftotext (text PDFs) vs OCR (scanned).

Logic:
1. Try pdftotext (poppler). If ratio of text pages high, use that.
2. Else fall back to OCR via pytesseract on rasterized pages.

Deps:
- poppler (`brew install poppler`) for pdftotext
- pypdf for triage
- pdf2image + pytesseract + tesseract (`brew install tesseract poppler`) for OCR fallback
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

MIN_CHARS_PER_PAGE = 50


def parse_pages(spec: str | None, total: int) -> list[int]:
    if not spec:
        return list(range(1, total + 1))
    pages: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-", 1)
            pages.update(range(int(a), int(b) + 1))
        else:
            pages.add(int(part))
    return sorted(p for p in pages if 1 <= p <= total)


def pdftotext_pages(path: Path, pages: list[int]) -> tuple[str, list[int]]:
    if not shutil.which("pdftotext"):
        return "", []
    chunks: list[str] = []
    weak: list[int] = []
    for p in pages:
        out = subprocess.run(
            ["pdftotext", "-layout", "-f", str(p), "-l", str(p), str(path), "-"],
            capture_output=True, text=True, check=False,
        )
        text = out.stdout
        if len(text.strip()) < MIN_CHARS_PER_PAGE:
            weak.append(p)
        chunks.append(f"\n===== page {p} =====\n{text}")
    return "".join(chunks), weak


def ocr_pages(path: Path, pages: list[int]) -> str:
    try:
        from pdf2image import convert_from_path
        import pytesseract
    except ImportError:
        print("ERROR: OCR fallback needs pdf2image + pytesseract. Install: pip install pdf2image pytesseract", file=sys.stderr)
        return ""
    chunks: list[str] = []
    for p in pages:
        images = convert_from_path(str(path), first_page=p, last_page=p, dpi=300)
        for img in images:
            text = pytesseract.image_to_string(img)
            chunks.append(f"\n===== page {p} (OCR) =====\n{text}")
    return "".join(chunks)


def page_count(path: Path) -> int:
    import pypdf
    return len(pypdf.PdfReader(str(path)).pages)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("file", type=Path)
    ap.add_argument("--pages", help="page spec e.g. 1-5,7,10-12")
    ap.add_argument("--force-ocr", action="store_true")
    ap.add_argument("--no-ocr", action="store_true", help="skip OCR fallback")
    args = ap.parse_args()

    if not args.file.exists():
        print(f"ERROR: {args.file} not found", file=sys.stderr)
        return 1

    total = page_count(args.file)
    pages = parse_pages(args.pages, total)

    if args.force_ocr:
        sys.stdout.write(ocr_pages(args.file, pages))
        return 0

    text, weak = pdftotext_pages(args.file, pages)
    if weak and not args.no_ocr:
        print(f"# pdftotext weak on pages {weak}, running OCR fallback", file=sys.stderr)
        ocr_text = ocr_pages(args.file, weak)
        text += "\n" + ocr_text

    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

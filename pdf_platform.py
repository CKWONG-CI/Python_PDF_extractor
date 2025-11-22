#!/usr/bin/env python3
"""
pdf_platform.py

Offline PDF keyword search tool (CLI).

Features:
- Search PDFs in a directory (or a single PDF) for a preset list of keywords
- Produce JSON and CSV reports listing pages where each keyword appears

Usage examples:
  python pdf_platform.py --pdf-dir ./pdfs --keywords-file keywords.txt --output results.json
  python pdf_platform.py --pdf-file report.pdf --keywords-file keywords.txt --output-dir out

Requirements: see requirements.txt (uses PyPDF2)
"""

import argparse
import json
import csv
import re
from pathlib import Path
from typing import List, Dict

try:
	from PyPDF2 import PdfReader
except Exception as e:
	raise ImportError("PyPDF2 is required. Install with `pip install -r requirements.txt`.") from e


def load_keywords(path: Path) -> List[str]:
	text = path.read_text(encoding="utf-8")
	# Split on newlines and commas, strip, drop empties
	raw = re.split(r"[\n,]+", text)
	keywords = [k.strip() for k in raw if k.strip()]
	return keywords


def search_pdf(file_path: Path, keywords: List[str]) -> Dict[str, List[int]]:
	"""Search a single PDF file. Returns mapping keyword -> sorted list of 1-based page numbers."""
	results: Dict[str, set] = {k: set() for k in keywords}

	reader = PdfReader(str(file_path))
	num_pages = len(reader.pages)

	# Precompile regex patterns for whole-word, case-insensitive search
	patterns = {k: re.compile(re.escape(k), re.IGNORECASE) for k in keywords}

	for i in range(num_pages):
		try:
			page = reader.pages[i]
			text = page.extract_text() or ""
		except Exception:
			text = ""

		if not text:
			continue

		for k, pat in patterns.items():
			if pat.search(text):
				results[k].add(i + 1)  # 1-based pages

	# Convert sets to sorted lists
	return {k: sorted(list(pages)) for k, pages in results.items()}


def run_search(pdf_paths: List[Path], keywords: List[str]):
	aggregated = {}
	for p in pdf_paths:
		aggregated[str(p.name)] = search_pdf(p, keywords)
	return aggregated


def write_json(data, out_path: Path):
	out_path.parent.mkdir(parents=True, exist_ok=True)
	out_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def write_csv(data, out_path: Path):
	out_path.parent.mkdir(parents=True, exist_ok=True)
	# Rows: filename, keyword, pages(comma-separated)
	with out_path.open("w", encoding="utf-8", newline="") as f:
		writer = csv.writer(f)
		writer.writerow(["filename", "keyword", "pages"])
		for fname, mapping in data.items():
			for kw, pages in mapping.items():
				pages_csv = ", ".join(str(p) for p in pages)
				writer.writerow([fname, kw, pages_csv])


def gather_pdf_paths(pdf_dir: Path = None, pdf_file: Path = None) -> List[Path]:
	if pdf_file:
		if not pdf_file.exists():
			raise FileNotFoundError(f"PDF file not found: {pdf_file}")
		return [pdf_file]
	if pdf_dir:
		if not pdf_dir.exists():
			raise FileNotFoundError(f"PDF directory not found: {pdf_dir}")
		# Accept .pdf files (case insensitive)
		return sorted([p for p in pdf_dir.iterdir() if p.suffix.lower() == ".pdf"])
	raise ValueError("Either pdf_dir or pdf_file must be provided")


def parse_args():
	ap = argparse.ArgumentParser(description="Offline PDF keyword search tool")
	group = ap.add_mutually_exclusive_group(required=True)
	group.add_argument("--pdf-dir", type=Path, help="Directory containing PDF files to search")
	group.add_argument("--pdf-file", type=Path, help="Single PDF file to search")

	ap.add_argument("--keywords-file", type=Path, required=True, help="File with preset keywords (one per line or comma-separated)")
	ap.add_argument("--output", type=Path, help="Output JSON path (defaults to ./search_results.json)")
	ap.add_argument("--output-csv", type=Path, help="Also write CSV summary to this path")
	ap.add_argument("--output-dir", type=Path, help="Directory to place outputs (alternative to --output / --output-csv)")
	return ap.parse_args()


def main():
	args = parse_args()
	keywords = load_keywords(args.keywords_file)
	if not keywords:
		print("No keywords found in the keywords file.")
		return

	pdf_paths = gather_pdf_paths(args.pdf_dir, args.pdf_file)
	if not pdf_paths:
		print("No PDF files found to search.")
		return

	print(f"Searching {len(pdf_paths)} PDF(s) for {len(keywords)} keyword(s)...")
	results = run_search(pdf_paths, keywords)

	out_json = args.output or (args.output_dir / "search_results.json" if args.output_dir else Path("search_results.json"))
	write_json(results, out_json)
	print(f"JSON results written to: {out_json}")

	out_csv = args.output_csv or (args.output_dir / "search_results.csv" if args.output_dir else None)
	if out_csv:
		write_csv(results, out_csv)
		print(f"CSV summary written to: {out_csv}")


if __name__ == "__main__":
	main()

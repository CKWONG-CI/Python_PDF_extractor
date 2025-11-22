# PDF Search Tool — Quick Reference

This repository contains four files used to search PDF files for preset keywords:

- `pdf_platform.py` — Command-line script that searches one PDF or a directory of PDFs using the keywords in `keywords.txt` and writes JSON and optional CSV results.
- `run_pdf_tool.sh` — Portable bash helper that creates/activates a virtual environment, installs `requirements.txt`, and runs `pdf_platform.py` (suitable for Git Bash / WSL / Linux / macOS).
- `requirements.txt` — Python dependencies (install with `pip install -r requirements.txt`).
- `keywords.txt` — Preset keywords (one per line or comma-separated) used by `pdf_platform.py`.

Example (run manually):
```
python pdf_platform.py --pdf-file /path/to/file.pdf --keywords-file keywords.txt --output results.json --output-csv results.csv
```

Or use the helper script:
```
bash run_pdf_tool.sh --pdf-file /path/to/file.pdf --keywords-file keywords.txt --output-dir ./out
```

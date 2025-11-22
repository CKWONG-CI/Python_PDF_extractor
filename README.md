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

Setup — create a virtual environment and install dependencies

Linux / macOS (or WSL):
```
cd /path/to/project
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Git Bash (Windows) — use the same commands as Linux/WSL, or call the helper script with `bash`:
```
bash run_pdf_tool.sh --pdf-file "path/to/file.pdf" --keywords-file keywords.txt --output-dir ./out
```

Windows PowerShell:
```
cd C:\path\to\project
python -m venv .venv
.\.venv\Scripts\Activate.ps1    # may require Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
pip install -r requirements.txt
python pdf_platform.py --pdf-file ".\BLE Indoor Localization based on Improved RSSI and Trilateration.pdf" --keywords-file .\keywords.txt --output-dir .\out
```

Run the PowerShell helper script (`run_pdf_tool.ps1`)

If you have `run_pdf_tool.ps1` in the project root you can run it instead of the manual steps. Example:
```
# (may need to allow running local scripts once)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

# run the wrapper (from project folder)
.\run_pdf_tool.ps1 -PdfFile ".\BLE Indoor Localization based on Improved RSSI and Trilateration.pdf" -KeywordsFile ".\keywords.txt" -OutputDir ".\out"
```

If you prefer not to change ExecutionPolicy permanently you can run the script with a one-off bypass:
```
powershell -ExecutionPolicy Bypass -File .\run_pdf_tool.ps1 -PdfFile ".\BLE Indoor Localization based on Improved RSSI and Trilateration.pdf" -KeywordsFile ".\keywords.txt" -OutputDir ".\out"
```


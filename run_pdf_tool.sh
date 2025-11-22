#!/usr/bin/env bash
set -euo pipefail

# Portable bash runner for Windows (Git Bash/MSYS/WSL) or Linux/macOS.
# Usage examples:
#   bash run_pdf_tool.sh --pdf-file "/c/Users/you/Docs/report.pdf"
#   bash run_pdf_tool.sh --pdf-dir ./pdfs --keywords-file keywords.txt --output-dir ./out

PDF_FILE=""
PDF_DIR=""
KEYWORDS_FILE="keywords.txt"
OUTPUT=""
OUTPUT_CSV=""
VERBOSE=1

print_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  --pdf-file PATH        Single PDF file to search
  --pdf-dir PATH         Directory containing PDFs to search
  --keywords-file PATH   Keywords file (default: keywords.txt)
  --output PATH          JSON output path (default: ./search_results.json)
  --output-csv PATH      CSV output path (optional)
  --output-dir PATH      Output directory to place both outputs (alternative)
  --help                 Show this help
EOF
}

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pdf-file) PDF_FILE="$2"; shift 2 ;;
    --pdf-dir) PDF_DIR="$2"; shift 2 ;;
    --keywords-file) KEYWORDS_FILE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --output-csv) OUTPUT_CSV="$2"; shift 2 ;;
    --output-dir) OUTDIR="$2"; OUTPUT="" ; OUTPUT_CSV="" ; OUTPUT_DIR_SET="$OUTDIR"; shift 2 ;;
    --help) print_help; exit 0 ;;
    *) echo "Unknown arg: $1"; print_help; exit 2 ;;
  esac
done

# Validate at least one of pdf-file or pdf-dir
if [[ -z "${PDF_FILE}" && -z "${PDF_DIR:-}" ]]; then
  echo "Error: either --pdf-file or --pdf-dir must be provided."
  print_help
  exit 2
fi

# Resolve python
PYTHON_CMD=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD=python
else
  echo "Python not found. Please install Python 3.8+ and retry."
  exit 3
fi

# Create venv if missing
VENV_DIR=".venv"
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating virtual environment in $VENV_DIR..."
  $PYTHON_CMD -m venv "$VENV_DIR"
fi

# Activate venv (try unix-style, then Windows-style Scripts)
if [[ -f "$VENV_DIR/bin/activate" ]]; then
  # Linux / WSL / macOS
  # shellcheck disable=SC1091
  source "$VENV_DIR/bin/activate"
elif [[ -f "$VENV_DIR/Scripts/activate" ]]; then
  # Git Bash / MSYS / Cygwin / Windows created venv
  # shellcheck disable=SC1091
  source "$VENV_DIR/Scripts/activate"
else
  echo "Could not find venv activation script in $VENV_DIR. Activate manually and rerun."
  exit 4
fi

# Ensure pip and requirements installed
pip install --upgrade pip >/dev/null
if [[ -f "requirements.txt" ]]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r requirements.txt
else
  echo "Warning: requirements.txt not found; attempting to proceed (PyPDF2 required)."
fi

# Build the command to run pdf_platform.py
CMD=(python pdf_platform.py)
if [[ -n "${PDF_FILE}" ]]; then
  CMD+=(--pdf-file "$PDF_FILE")
else
  CMD+=(--pdf-dir "$PDF_DIR")
fi

CMD+=(--keywords-file "${KEYWORDS_FILE}")

# handle outputs
if [[ -n "${OUTPUT_DIR_SET:-}" ]]; then
  mkdir -p "$OUTPUT_DIR_SET"
  CMD+=(--output-dir "$OUTPUT_DIR_SET")
else
  if [[ -n "${OUTPUT}" ]]; then
    CMD+=(--output "$OUTPUT")
  fi
  if [[ -n "${OUTPUT_CSV}" ]]; then
    CMD+=(--output-csv "$OUTPUT_CSV")
  fi
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"

echo "Done."

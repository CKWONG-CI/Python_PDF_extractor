<#
Simple PowerShell runner for the PDF search tool.
Usage examples:
  .\run_pdf_tool.ps1 -PdfFile ".\BLE Indoor Localization based on Improved RSSI and Trilateration.pdf" -KeywordsFile ".\keywords.txt" -OutputDir ".\out"
  .\run_pdf_tool.ps1 -PdfDir ".\pdfs" -KeywordsFile ".\keywords.txt" -Output ".\results.json" -OutputCsv ".\results.csv"
#>

param(
  [string]$PdfFile = "",
  [string]$PdfDir  = "",
  [string]$KeywordsFile = "keywords.txt",
  [string]$Output = "",
  [string]$OutputCsv = "",
  [string]$OutputDir = ""
)

function Fail($msg) {
  Write-Error $msg
  exit 2
}

if (-not ($PdfFile -or $PdfDir)) {
  Fail "Either -PdfFile or -PdfDir must be provided. See script header for examples."
}

# Resolve python
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
  Fail "Python not found on PATH. Please install Python 3.8+ and re-run."
}

# Create venv if missing
$venv = Join-Path (Get-Location) ".venv"
if (-not (Test-Path $venv)) {
  & $python -m venv $venv
  if ($LASTEXITCODE -ne 0) { Fail "Failed to create venv" }
}

# Activate venv in this session
$activate = Join-Path $venv "Scripts\Activate.ps1"
if (-not (Test-Path $activate)) {
  Fail "Cannot find Activate.ps1 in venv. Activate manually and rerun."
}
# Dot-source the activation script to modify current session
. $activate

# Upgrade pip and install requirements if present
pip install --upgrade pip
if (Test-Path "requirements.txt") {
  pip install -r "requirements.txt"
} else {
  Write-Warning "requirements.txt not found; ensure PyPDF2 is installed."
}

# Build python command
$cmd = @("pdf_platform.py")
if ($PdfFile) { $cmd += "--pdf-file"; $cmd += $PdfFile } else { $cmd += "--pdf-dir"; $cmd += $PdfDir }
$cmd += "--keywords-file"; $cmd += $KeywordsFile

if ($OutputDir) {
  if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
  $cmd += "--output-dir"; $cmd += $OutputDir
} else {
  if ($Output) { $cmd += "--output"; $cmd += $Output }
  if ($OutputCsv) { $cmd += "--output-csv"; $cmd += $OutputCsv }
}

Write-Host "Running: python $($cmd -join ' ')"
& python $cmd
if ($LASTEXITCODE -ne 0) { Fail "pdf_platform.py exited with code $LASTEXITCODE" }

Write-Host "Done."

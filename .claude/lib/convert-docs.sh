#!/usr/bin/env bash
#
# convert-docs.sh - Document conversion utility
#
# Converts between Markdown, DOCX, and PDF formats using optimal tools with
# automatic fallback. Designed for speed and reliability in common conversion
# scenarios.
#
# Usage:
#   convert-docs.sh [INPUT_DIR] [OUTPUT_DIR]
#   convert-docs.sh --detect-tools
#   convert-docs.sh [INPUT_DIR] --dry-run
#
# Arguments:
#   INPUT_DIR   - Directory containing files to convert (default: current directory)
#   OUTPUT_DIR  - Output directory for converted files (default: ./converted_output)
#
# Options:
#   --detect-tools  - Display detected conversion tools and exit
#   --dry-run       - Show files that would be converted without converting
#
# Tool Priority Matrix:
#   DOCX → MD: MarkItDown (75-80% fidelity) → Pandoc (68% fidelity)
#   PDF → MD:  marker-pdf (95% fidelity) → PyMuPDF4LLM (55% fidelity, fast)
#   MD → DOCX: Pandoc (95%+ quality)
#   MD → PDF:  Pandoc with Typst → XeLaTeX fallback
#
# Environment Variables:
#   MARKER_PDF_VENV - Path to marker-pdf virtual environment
#                     (default: $HOME/venvs/pdf-tools)
#
# Exit Codes:
#   0 - Success (all conversions completed)
#   1 - Error (invalid arguments, missing tools, or conversion failures)
#

set -euo pipefail

# Configuration
MARKER_PDF_VENV="${MARKER_PDF_VENV:-$HOME/venvs/pdf-tools}"

# Tool availability flags
MARKITDOWN_AVAILABLE=false
PANDOC_AVAILABLE=false
MARKER_PDF_AVAILABLE=false
MARKER_PDF_PATH=""
PYMUPDF_AVAILABLE=false
TYPST_AVAILABLE=false
XELATEX_AVAILABLE=false

# Conversion counters
docx_success=0
docx_failed=0
pdf_success=0
pdf_failed=0
md_to_docx_success=0
md_to_docx_failed=0
md_to_pdf_success=0
md_to_pdf_failed=0

# Conversion direction
CONVERSION_DIRECTION=""  # TO_MARKDOWN or FROM_MARKDOWN

# Log file
LOG_FILE=""

#
# detect_tools - Check for available conversion tools
#
# Sets global flags for tool availability:
#   MARKITDOWN_AVAILABLE, PANDOC_AVAILABLE, MARKER_PDF_AVAILABLE,
#   PYMUPDF_AVAILABLE, TYPST_AVAILABLE, XELATEX_AVAILABLE
#
detect_tools() {
  # MarkItDown
  if command -v markitdown &>/dev/null; then
    MARKITDOWN_AVAILABLE=true
  fi

  # Pandoc
  if command -v pandoc &>/dev/null; then
    PANDOC_AVAILABLE=true
  fi

  # marker-pdf (check PATH first, then venv)
  if command -v marker_single &>/dev/null; then
    MARKER_PDF_AVAILABLE=true
    MARKER_PDF_PATH="marker_single"
  elif [[ -f "$MARKER_PDF_VENV/bin/marker_single" ]]; then
    MARKER_PDF_AVAILABLE=true
    MARKER_PDF_PATH="$MARKER_PDF_VENV/bin/marker_single"
  fi

  # PyMuPDF4LLM
  if python3 -c "import pymupdf4llm" 2>/dev/null; then
    PYMUPDF_AVAILABLE=true
  fi

  # Typst (for MD→PDF)
  if command -v typst &>/dev/null; then
    TYPST_AVAILABLE=true
  fi

  # XeLaTeX (for MD→PDF fallback)
  if command -v xelatex &>/dev/null; then
    XELATEX_AVAILABLE=true
  fi
}

#
# select_docx_tool - Select best available DOCX converter
#
# Returns: Tool name ("markitdown", "pandoc", or "none")
#
select_docx_tool() {
  if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
    echo "markitdown"
  elif [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "pandoc"
  else
    echo "none"
  fi
}

#
# select_pdf_tool - Select best available PDF converter
#
# Returns: Tool name ("marker-pdf", "pymupdf", or "none")
#
select_pdf_tool() {
  if [[ "$MARKER_PDF_AVAILABLE" == "true" ]]; then
    echo "marker-pdf"
  elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
    echo "pymupdf"
  else
    echo "none"
  fi
}

#
# discover_files - Find convertible files in input directory
#
# Arguments:
#   $1 - Input directory path
#
# Populates global arrays: docx_files, pdf_files, md_files
#
discover_files() {
  local input_dir="$1"

  # Find DOCX files
  while IFS= read -r -d '' file; do
    docx_files+=("$file")
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.docx" -print0 2>/dev/null)

  # Find PDF files
  while IFS= read -r -d '' file; do
    pdf_files+=("$file")
  done < <(find "$input_dir" -maxdepth 1 -type f -iname "*.pdf" -print0 2>/dev/null)

  # Find Markdown files
  while IFS= read -r -d '' file; do
    md_files+=("$file")
  done < <(find "$input_dir" -maxdepth 1 -type f \( -iname "*.md" -o -iname "*.markdown" \) -print0 2>/dev/null)
}

#
# detect_conversion_direction - Determine conversion direction
#
# Sets global variable: CONVERSION_DIRECTION
#   "TO_MARKDOWN" if DOCX/PDF files present
#   "FROM_MARKDOWN" if only MD files present
#   "MIXED" if both present (defaults to TO_MARKDOWN for mixed batches)
#
detect_conversion_direction() {
  local has_source_docs=false
  local has_markdown=false

  if [[ ${#docx_files[@]} -gt 0 ]] || [[ ${#pdf_files[@]} -gt 0 ]]; then
    has_source_docs=true
  fi

  if [[ ${#md_files[@]} -gt 0 ]]; then
    has_markdown=true
  fi

  if [[ "$has_source_docs" == "true" ]]; then
    CONVERSION_DIRECTION="TO_MARKDOWN"
  elif [[ "$has_markdown" == "true" ]]; then
    CONVERSION_DIRECTION="FROM_MARKDOWN"
  else
    CONVERSION_DIRECTION="NONE"
  fi
}

#
# show_tool_detection - Display detected tools
#
show_tool_detection() {
  echo "Document Conversion Tools Detection"
  echo "===================================="
  echo ""
  echo "DOCX Conversion:"
  if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
    echo "  ✓ MarkItDown (primary, 75-80% fidelity)"
  else
    echo "  ✗ MarkItDown not found"
  fi
  if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "  ✓ Pandoc (fallback, 68% fidelity)"
  else
    echo "  ✗ Pandoc not found"
  fi
  echo ""
  echo "PDF Conversion:"
  if [[ "$MARKER_PDF_AVAILABLE" == "true" ]]; then
    echo "  ✓ marker-pdf (primary, 95% fidelity) at: $MARKER_PDF_PATH"
  else
    echo "  ✗ marker-pdf not found"
  fi
  if [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
    echo "  ✓ PyMuPDF4LLM (fallback, 55% fidelity, fast)"
  else
    echo "  ✗ PyMuPDF4LLM not found"
  fi
  echo ""
  echo "Markdown Export:"
  if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
    echo "  ✓ Pandoc (MD→DOCX/PDF, 95%+ quality)"
  else
    echo "  ✗ Pandoc not found"
  fi
  if [[ "$TYPST_AVAILABLE" == "true" ]]; then
    echo "  ✓ Typst (PDF engine, primary)"
  else
    echo "  ✗ Typst not found"
  fi
  if [[ "$XELATEX_AVAILABLE" == "true" ]]; then
    echo "  ✓ XeLaTeX (PDF engine, fallback)"
  else
    echo "  ✗ XeLaTeX not found"
  fi
  echo ""
  echo "Selected Tools:"
  echo "  DOCX→MD: $(select_docx_tool)"
  echo "  PDF→MD:  $(select_pdf_tool)"
  echo "  MD→DOCX: $(if [[ "$PANDOC_AVAILABLE" == "true" ]]; then echo "pandoc"; else echo "none"; fi)"
  echo "  MD→PDF:  $(if [[ "$TYPST_AVAILABLE" == "true" ]] || [[ "$XELATEX_AVAILABLE" == "true" ]]; then echo "pandoc"; else echo "none"; fi)"
}

#
# show_dry_run - Display files that would be converted
#
# Arguments:
#   $1 - Input directory
#
show_dry_run() {
  local input_dir="$1"

  echo "Dry Run: Conversion Analysis"
  echo "============================="
  echo ""
  echo "Input Directory: $input_dir"
  echo ""

  if [[ ${#docx_files[@]} -gt 0 ]]; then
    echo "DOCX Files (${#docx_files[@]}):"
    for file in "${docx_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#pdf_files[@]} -gt 0 ]]; then
    echo "PDF Files (${#pdf_files[@]}):"
    for file in "${pdf_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#md_files[@]} -gt 0 ]]; then
    echo "Markdown Files (${#md_files[@]}):"
    for file in "${md_files[@]}"; do
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  echo "Conversion Direction: $CONVERSION_DIRECTION"
  echo ""

  if [[ "$CONVERSION_DIRECTION" == "TO_MARKDOWN" ]]; then
    echo "Would convert ${#docx_files[@]} DOCX and ${#pdf_files[@]} PDF files to Markdown"
  elif [[ "$CONVERSION_DIRECTION" == "FROM_MARKDOWN" ]]; then
    echo "Would convert ${#md_files[@]} Markdown files to DOCX/PDF"
  else
    echo "No convertible files found"
  fi
}

#
# Main execution
#

# Parse arguments
INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./converted_output}"

# Handle special flags
if [[ "$INPUT_DIR" == "--detect-tools" ]]; then
  detect_tools
  show_tool_detection
  exit 0
fi

DRY_RUN=false
if [[ "$OUTPUT_DIR" == "--dry-run" ]] || [[ "$2" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# Validate input directory (skip for --detect-tools)
if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Error: Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

# Initialize file arrays (required for bash -u mode)
docx_files=()
pdf_files=()
md_files=()

# Detect tools
detect_tools

# Discover files
discover_files "$INPUT_DIR"

# Detect conversion direction
detect_conversion_direction

# Handle dry run
if [[ "$DRY_RUN" == "true" ]]; then
  show_dry_run "$INPUT_DIR"
  exit 0
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize log file
LOG_FILE="$OUTPUT_DIR/conversion.log"
echo "Document Conversion Log - $(date)" > "$LOG_FILE"
echo "Input Directory: $INPUT_DIR" >> "$LOG_FILE"
echo "Output Directory: $OUTPUT_DIR" >> "$LOG_FILE"
echo "Conversion Direction: $CONVERSION_DIRECTION" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# TODO: Phase 2 will implement conversion functions
# TODO: Phase 3 will implement validation and summary

echo "Conversion script initialized successfully"
echo "Input: $INPUT_DIR"
echo "Output: $OUTPUT_DIR"
echo "Direction: $CONVERSION_DIRECTION"
echo "Found: ${#docx_files[@]} DOCX, ${#pdf_files[@]} PDF, ${#md_files[@]} MD files"
echo ""
echo "Phase 1 complete - conversion functions coming in Phase 2"

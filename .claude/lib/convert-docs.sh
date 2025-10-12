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
#   PDF → MD:  marker_pdf (95% fidelity) → PyMuPDF4LLM (55% fidelity, fast)
#   MD → DOCX: Pandoc (95%+ quality)
#   MD → PDF:  Pandoc with Typst → XeLaTeX fallback
#
# Environment Variables:
#   MARKER_PDF_VENV - Path to marker_pdf virtual environment
#                     (default: $HOME/venvs/pdf-tools)
#
# Exit Codes:
#   0 - Success (all conversions completed)
#   1 - Error (invalid arguments, missing tools, or conversion failures)
#

set -eu

# Configuration
MARKER_PDF_VENV="${MARKER_PDF_VENV:-$HOME/venvs/pdf-tools}"

# Timeout configuration (seconds)
TIMEOUT_DOCX_TO_MD=60
TIMEOUT_PDF_TO_MD=300
TIMEOUT_MD_TO_DOCX=60
TIMEOUT_MD_TO_PDF=120

# Timeout multiplier (can be overridden by environment variable)
TIMEOUT_MULTIPLIER="${TIMEOUT_MULTIPLIER:-1.0}"

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
collisions_resolved=0
timeouts_occurred=0

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

  # marker_pdf (check PATH first, then venv)
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
# with_timeout - Execute command with timeout protection
#
# Arguments:
#   $1 - Timeout duration in seconds
#   $2+ - Command and arguments to execute
#
# Returns:
#   0 - Command succeeded within timeout
#   1 - Command failed
#   124 - Command timed out
#
# The timeout duration is multiplied by TIMEOUT_MULTIPLIER for flexibility.
#
with_timeout() {
  local timeout_secs="$1"
  shift

  # Apply timeout multiplier
  timeout_secs=$(awk "BEGIN {printf \"%.0f\", $timeout_secs * $TIMEOUT_MULTIPLIER}")

  # Check if timeout command is available
  if command -v timeout &>/dev/null; then
    timeout "$timeout_secs" "$@"
    local exit_code=$?

    # Check if timeout occurred (exit code 124)
    if [[ $exit_code -eq 124 ]]; then
      timeouts_occurred=$((timeouts_occurred + 1))
      return 124
    fi

    return $exit_code
  else
    # Fallback: run without timeout if timeout command not available
    "$@"
    return $?
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
# Returns: Tool name ("marker_pdf", "pymupdf", or "none")
#
select_pdf_tool() {
  if [[ "$MARKER_PDF_AVAILABLE" == "true" ]]; then
    echo "marker_pdf"
  elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
    echo "pymupdf"
  else
    echo "none"
  fi
}

#
# check_output_collision - Ensure output filename is unique
#
# Arguments:
#   $1 - Proposed output file path
#
# Returns: Unique output file path (original or with _N suffix)
#
# If the proposed output file already exists, appends _1, _2, etc. until
# finding an unused filename. Updates global collisions_resolved counter.
#
check_output_collision() {
  local proposed_output="$1"
  local output_dir
  local output_base
  local output_ext
  local counter=1
  local candidate

  # If file doesn't exist, use it as-is
  if [[ ! -f "$proposed_output" ]]; then
    echo "$proposed_output"
    return 0
  fi

  # Extract directory, base name, and extension
  output_dir="$(dirname "$proposed_output")"
  output_base="$(basename "$proposed_output")"

  # Split into name and extension
  if [[ "$output_base" == *.* ]]; then
    output_ext=".${output_base##*.}"
    output_base="${output_base%.*}"
  else
    output_ext=""
  fi

  # Find unique filename
  while true; do
    candidate="$output_dir/${output_base}_${counter}${output_ext}"
    if [[ ! -f "$candidate" ]]; then
      collisions_resolved=$((collisions_resolved + 1))
      echo "$candidate"
      return 0
    fi
    counter=$((counter + 1))

    # Safety limit to prevent infinite loops
    if [[ $counter -gt 1000 ]]; then
      echo "$proposed_output.$$" # Use PID as last resort
      return 1
    fi
  done
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
    echo "  ✓ marker_pdf (primary, 95% fidelity) at: $MARKER_PDF_PATH"
  else
    echo "  ✗ marker_pdf not found"
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
      # Safe basename extraction for files with special characters
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#pdf_files[@]} -gt 0 ]]; then
    echo "PDF Files (${#pdf_files[@]}):"
    for file in "${pdf_files[@]}"; do
      # Safe basename extraction for files with special characters
      echo "  - $(basename "$file")"
    done
    echo ""
  fi

  if [[ ${#md_files[@]} -gt 0 ]]; then
    echo "Markdown Files (${#md_files[@]}):"
    for file in "${md_files[@]}"; do
      # Safe basename extraction for files with special characters
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

#
# convert_docx - Convert DOCX to Markdown using MarkItDown
#
# Arguments:
#   $1 - Input DOCX file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
convert_docx() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_DOCX_TO_MD" bash -c "markitdown '$input_file' > '$output_file' 2>/dev/null"
  return $?
}

#
# convert_docx_pandoc - Convert DOCX to Markdown using Pandoc
#
# Arguments:
#   $1 - Input DOCX file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
convert_docx_pandoc() {
  local input_file="$1"
  local output_file="$2"
  local media_dir
  media_dir="$(dirname "$output_file")/images"

  mkdir -p "$media_dir"
  with_timeout "$TIMEOUT_DOCX_TO_MD" pandoc "$input_file" -t gfm --extract-media="$media_dir" --wrap=preserve -o "$output_file" 2>/dev/null
  return $?
}

#
# convert_pdf_marker - Convert PDF to Markdown using marker_pdf
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
convert_pdf_marker() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_PDF_TO_MD" "$MARKER_PDF_PATH" "$input_file" "$output_file" --output_format markdown 2>/dev/null
  return $?
}

#
# convert_pdf_pymupdf - Convert PDF to Markdown using PyMuPDF4LLM
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
convert_pdf_pymupdf() {
  local input_file="$1"
  local output_file="$2"

  with_timeout 60 python3 -c "
import pymupdf4llm
import sys

try:
    md_text = pymupdf4llm.to_markdown('$input_file')
    with open('$output_file', 'w') as f:
        f.write(md_text)
    sys.exit(0)
except Exception as e:
    sys.exit(1)
" 2>/dev/null
  return $?
}

#
# convert_md_to_docx - Convert Markdown to DOCX using Pandoc
#
# Arguments:
#   $1 - Input Markdown file path
#   $2 - Output DOCX file path
#
# Returns: 0 on success, 1 on failure
#
convert_md_to_docx() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_MD_TO_DOCX" pandoc "$input_file" -o "$output_file" 2>/dev/null
  return $?
}

#
# convert_md_to_pdf - Convert Markdown to PDF using Pandoc with Typst or XeLaTeX
#
# Arguments:
#   $1 - Input Markdown file path
#   $2 - Output PDF file path
#
# Returns: 0 on success, 1 on failure
#
convert_md_to_pdf() {
  local input_file="$1"
  local output_file="$2"

  if [[ "$TYPST_AVAILABLE" == "true" ]]; then
    with_timeout "$TIMEOUT_MD_TO_PDF" pandoc "$input_file" --pdf-engine=typst -o "$output_file" 2>/dev/null
    return $?
  elif [[ "$XELATEX_AVAILABLE" == "true" ]]; then
    with_timeout "$TIMEOUT_MD_TO_PDF" pandoc "$input_file" --pdf-engine=xelatex -o "$output_file" 2>/dev/null
    return $?
  else
    return 1
  fi
}

#
# convert_file - Main conversion dispatcher with automatic fallback
#
# Arguments:
#   $1 - Input file path
#   $2 - Output directory
#
# Updates global counters based on success/failure
#
convert_file() {
  local input_file="$1"
  local output_dir="$2"
  local basename
  local extension
  local output_file
  local tool_used=""
  local conversion_success=false

  # Extract basename and extension safely
  basename="$(basename "$input_file")"
  extension="${basename##*.}"

  case "${extension,,}" in
    docx)
      # DOCX → MD conversion (safe quoting for special characters)
      output_file="$output_dir/${basename%.docx}.md"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      # Try MarkItDown first
      if [[ "$MARKITDOWN_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (MarkItDown)"
        convert_docx "$input_file" "$output_file"
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
          tool_used="markitdown"
          conversion_success=true
          docx_success=$((docx_success + 1))
        elif [[ $exit_code -eq 124 ]]; then
          echo "    MarkItDown timed out (${TIMEOUT_DOCX_TO_MD}s), trying Pandoc fallback..."
          # Fall back to Pandoc
          if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
            if convert_docx_pandoc "$input_file" "$output_file"; then
              tool_used="pandoc"
              conversion_success=true
              docx_success=$((docx_success + 1))
            fi
          fi
        else
          echo "    MarkItDown failed, trying Pandoc fallback..."
          # Fall back to Pandoc
          if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
            if convert_docx_pandoc "$input_file" "$output_file"; then
              tool_used="pandoc"
              conversion_success=true
              docx_success=$((docx_success + 1))
            fi
          fi
        fi
      # Try Pandoc if MarkItDown unavailable
      elif [[ "$PANDOC_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (Pandoc)"
        if convert_docx_pandoc "$input_file" "$output_file"; then
          tool_used="pandoc"
          conversion_success=true
          docx_success=$((docx_success + 1))
        fi
      fi

      if [[ "$conversion_success" == "false" ]]; then
        echo "    ✗ Failed to convert $basename"
        docx_failed=$((docx_failed + 1))
      else
        echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
        # Validate output
        if ! validate_output "$output_file"; then
          report_validation_warnings "$output_file" "md"
        fi
      fi
      ;;

    pdf)
      # PDF → MD conversion
      output_file="$output_dir/${basename%.pdf}.md"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      # Try marker_pdf first
      if [[ "$MARKER_PDF_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (marker_pdf)"
        if convert_pdf_marker "$input_file" "$output_file"; then
          tool_used="marker_pdf"
          conversion_success=true
          pdf_success=$((pdf_success + 1))
        else
          echo "    marker_pdf failed, trying PyMuPDF4LLM fallback..."
          # Fall back to PyMuPDF4LLM
          if [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
            if convert_pdf_pymupdf "$input_file" "$output_file"; then
              tool_used="pymupdf4llm"
              conversion_success=true
              pdf_success=$((pdf_success + 1))
            fi
          fi
        fi
      # Try PyMuPDF4LLM if marker_pdf unavailable
      elif [[ "$PYMUPDF_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename (PyMuPDF4LLM)"
        if convert_pdf_pymupdf "$input_file" "$output_file"; then
          tool_used="pymupdf4llm"
          conversion_success=true
          pdf_success=$((pdf_success + 1))
        fi
      fi

      if [[ "$conversion_success" == "false" ]]; then
        echo "    ✗ Failed to convert $basename"
        pdf_failed=$((pdf_failed + 1))
      else
        echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
        # Validate output
        if ! validate_output "$output_file"; then
          report_validation_warnings "$output_file" "md"
        fi
      fi
      ;;

    md|markdown)
      # MD → DOCX/PDF conversion (default to DOCX)
      # TODO: Phase 4 will add user control for output format selection
      output_file="$output_dir/${basename%.*}.docx"

      # Check for output filename collision and resolve if necessary
      output_file="$(check_output_collision "$output_file")"

      if [[ "$PANDOC_AVAILABLE" == "true" ]]; then
        echo "  Converting: $basename → DOCX (Pandoc)"
        if convert_md_to_docx "$input_file" "$output_file"; then
          tool_used="pandoc"
          conversion_success=true
          md_to_docx_success=$((md_to_docx_success + 1))
          echo "    ✓ Converted to $(basename "$output_file") (using $tool_used)"
          # Validate output
          if ! validate_output "$output_file"; then
            report_validation_warnings "$output_file" "docx"
          fi
        else
          echo "    ✗ Failed to convert $basename"
          md_to_docx_failed=$((md_to_docx_failed + 1))
        fi
      else
        echo "    ✗ Pandoc not available for MD→DOCX conversion"
        md_to_docx_failed=$((md_to_docx_failed + 1))
      fi
      ;;

    *)
      echo "  Skipping: $basename (unsupported format)"
      ;;
  esac

  # Log conversion result
  if [[ "$conversion_success" == "true" ]]; then
    echo "[SUCCESS] $basename → $(basename "$output_file") (tool: $tool_used)" >> "$LOG_FILE"
  else
    echo "[FAILED] $basename (no suitable tool or conversion error)" >> "$LOG_FILE"
  fi
}

#
# process_conversions - Process all discovered files
#
process_conversions() {
  local total_files=0
  local current_file=0

  # Calculate total files
  total_files=$((${#docx_files[@]} + ${#pdf_files[@]} + ${#md_files[@]}))

  if [[ $total_files -eq 0 ]]; then
    echo "No convertible files found in $INPUT_DIR"
    return 0
  fi

  echo "Processing $total_files files..."
  echo ""

  # Process DOCX files
  if [[ ${#docx_files[@]} -gt 0 ]]; then
    for file in "${docx_files[@]}"; do
      current_file=$((current_file + 1))
      echo "[$current_file/$total_files] Processing DOCX file"
      convert_file "$file" "$OUTPUT_DIR"
      echo ""
    done
  fi

  # Process PDF files
  if [[ ${#pdf_files[@]} -gt 0 ]]; then
    for file in "${pdf_files[@]}"; do
      current_file=$((current_file + 1))
      echo "[$current_file/$total_files] Processing PDF file"
      convert_file "$file" "$OUTPUT_DIR"
      echo ""
    done
  fi

  # Process MD files
  if [[ ${#md_files[@]} -gt 0 ]]; then
    for file in "${md_files[@]}"; do
      current_file=$((current_file + 1))
      echo "[$current_file/$total_files] Processing Markdown file"
      convert_file "$file" "$OUTPUT_DIR"
      echo ""
    done
  fi
}

#
# validate_output - Check if converted file exists and meets size requirements
#
# Arguments:
#   $1 - Output file path
#
# Returns: 0 if valid, 1 if invalid
#
validate_output() {
  local output_file="$1"

  if [[ ! -f "$output_file" ]]; then
    return 1
  fi

  local file_size
  file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")

  if [[ $file_size -lt 100 ]]; then
    return 1
  fi

  return 0
}

#
# check_structure - Analyze converted Markdown file structure
#
# Arguments:
#   $1 - Markdown file path
#
# Returns: String with structure statistics
#
check_structure() {
  local md_file="$1"

  if [[ ! -f "$md_file" ]]; then
    echo "0 headings, 0 tables"
    return
  fi

  local heading_count
  local table_count

  heading_count=$(grep -c '^#' "$md_file" 2>/dev/null || echo "0")
  table_count=$(grep -c '^\|' "$md_file" 2>/dev/null || echo "0")

  echo "$heading_count headings, $table_count tables"
}

#
# report_validation_warnings - Report warnings for suspicious output
#
# Arguments:
#   $1 - Output file path
#   $2 - File type (md, docx, pdf)
#
report_validation_warnings() {
  local output_file="$1"
  local file_type="$2"

  if [[ ! -f "$output_file" ]]; then
    echo "    ⚠ Warning: Output file not created"
    return
  fi

  local file_size
  file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")

  if [[ $file_size -lt 100 ]]; then
    echo "    ⚠ Warning: Output file very small ($file_size bytes)"
  fi

  # Check Markdown structure if applicable
  if [[ "$file_type" == "md" ]]; then
    local structure
    structure=$(check_structure "$output_file")
    local heading_count
    heading_count=$(echo "$structure" | cut -d' ' -f1)

    if [[ $heading_count -eq 0 ]]; then
      echo "    ⚠ Warning: No headings found in Markdown output"
    fi
  fi
}

#
# show_missing_tools - Report unavailable tools with installation guidance
#
show_missing_tools() {
  local has_missing=false

  echo ""
  echo "Missing Tools Report"
  echo "===================="
  echo ""

  # Check DOCX converters
  if [[ "$MARKITDOWN_AVAILABLE" == "false" ]] && [[ "$PANDOC_AVAILABLE" == "false" ]]; then
    echo "⚠ DOCX→MD Conversion: No tools available"
    echo "  Install MarkItDown: pip install --user 'markitdown[all]'"
    echo "  Or install Pandoc: Use your system package manager"
    echo ""
    has_missing=true
  fi

  # Check PDF converters
  if [[ "$MARKER_PDF_AVAILABLE" == "false" ]] && [[ "$PYMUPDF_AVAILABLE" == "false" ]]; then
    echo "⚠ PDF→MD Conversion: No tools available"
    echo "  Install marker_pdf: Complex setup (venv recommended)"
    echo "  Or install PyMuPDF4LLM: pip install --user pymupdf4llm"
    echo ""
    has_missing=true
  fi

  # Check MD exporters
  if [[ "$PANDOC_AVAILABLE" == "false" ]]; then
    echo "⚠ MD→DOCX/PDF Conversion: Pandoc not available"
    echo "  Install Pandoc: Use your system package manager"
    echo ""
    has_missing=true
  elif [[ "$TYPST_AVAILABLE" == "false" ]] && [[ "$XELATEX_AVAILABLE" == "false" ]]; then
    echo "⚠ MD→PDF Conversion: No PDF engine available"
    echo "  Install Typst: Use your system package manager"
    echo "  Or install XeLaTeX: Install texlive package"
    echo ""
    has_missing=true
  fi

  if [[ "$has_missing" == "false" ]]; then
    echo "✓ All recommended tools are available"
    echo ""
  fi
}

#
# generate_summary - Print conversion summary
#
generate_summary() {
  echo "======================================"
  echo "Conversion Summary"
  echo "======================================"
  echo ""
  echo "DOCX → MD:"
  echo "  Success: $docx_success"
  echo "  Failed:  $docx_failed"
  echo ""
  echo "PDF → MD:"
  echo "  Success: $pdf_success"
  echo "  Failed:  $pdf_failed"
  echo ""
  echo "MD → DOCX:"
  echo "  Success: $md_to_docx_success"
  echo "  Failed:  $md_to_docx_failed"
  echo ""
  echo "MD → PDF:"
  echo "  Success: $md_to_pdf_success"
  echo "  Failed:  $md_to_pdf_failed"
  echo ""
  if [[ $collisions_resolved -gt 0 ]]; then
    echo "Filename collisions resolved: $collisions_resolved"
    echo ""
  fi
  if [[ $timeouts_occurred -gt 0 ]]; then
    echo "Timeouts occurred: $timeouts_occurred"
    echo ""
  fi
  echo "Output directory: $OUTPUT_DIR"
  echo "Conversion log: $LOG_FILE"
  echo ""

  # Write summary to log
  echo "" >> "$LOG_FILE"
  echo "======================================">> "$LOG_FILE"
  echo "Conversion Summary" >> "$LOG_FILE"
  echo "======================================" >> "$LOG_FILE"
  echo "DOCX → MD: $docx_success success, $docx_failed failed" >> "$LOG_FILE"
  echo "PDF → MD: $pdf_success success, $pdf_failed failed" >> "$LOG_FILE"
  echo "MD → DOCX: $md_to_docx_success success, $md_to_docx_failed failed" >> "$LOG_FILE"
  echo "MD → PDF: $md_to_pdf_success success, $md_to_pdf_failed failed" >> "$LOG_FILE"
  if [[ $collisions_resolved -gt 0 ]]; then
    echo "Filename collisions resolved: $collisions_resolved" >> "$LOG_FILE"
  fi
  if [[ $timeouts_occurred -gt 0 ]]; then
    echo "Timeouts occurred: $timeouts_occurred" >> "$LOG_FILE"
  fi
}

# Check if there are files to convert or if we should show missing tools
total_convertible=$((${#docx_files[@]} + ${#pdf_files[@]} + ${#md_files[@]}))

if [[ $total_convertible -eq 0 ]]; then
  echo "No convertible files found in $INPUT_DIR"
  echo ""
  show_missing_tools
  exit 0
fi

# Process conversions
process_conversions

# Generate summary
generate_summary

# Show missing tools if any conversions failed
if [[ $((docx_failed + pdf_failed + md_to_docx_failed + md_to_pdf_failed)) -gt 0 ]]; then
  show_missing_tools
fi

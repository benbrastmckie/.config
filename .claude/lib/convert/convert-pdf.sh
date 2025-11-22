#!/usr/bin/env bash
#
# convert-pdf.sh - PDF conversion utilities
#
# Provides PDF ↔ Markdown and PDF → DOCX conversion functions.
#
# Public API:
#   convert_pdf_markitdown(input_file, output_file) - PDF→MD using MarkItDown
#   convert_pdf_pymupdf(input_file, output_file) - PDF→MD using PyMuPDF4LLM
#   convert_pdf_gemini(input_file, output_file) - PDF→MD using Gemini API
#   convert_pdf_to_md(input_file, output_file) - PDF→MD with auto tool selection
#   convert_pdf_to_docx(input_file, output_file) - PDF→DOCX using pdf2docx
#   convert_md_to_pdf(input_file, output_file) - MD→PDF using Pandoc with Typst/XeLaTeX
#
# Dependencies:
#   - MarkItDown (optional, for PDF→MD)
#   - PyMuPDF4LLM (optional, for PDF→MD)
#   - google-genai (optional, for Gemini API PDF→MD)
#   - pdf2docx (optional, for PDF→DOCX)
#   - Pandoc + Typst or XeLaTeX (optional, for MD→PDF)
#   - with_timeout() function (from convert-core.sh)
#   - TIMEOUT_PDF_TO_MD, TIMEOUT_MD_TO_PDF (from convert-core.sh)
#   - TYPST_AVAILABLE, XELATEX_AVAILABLE, PDF2DOCX_AVAILABLE (from convert-core.sh)
#   - CONVERSION_MODE (from convert-core.sh)
#

# Source Gemini wrapper if available
SCRIPT_DIR_PDF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR_PDF/convert-gemini.sh" ]]; then
  source "$SCRIPT_DIR_PDF/convert-gemini.sh"
fi

#
# convert_pdf_markitdown - Convert PDF to Markdown using MarkItDown
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
# Note: Requires with_timeout() and TIMEOUT_PDF_TO_MD from convert-core.sh
#
convert_pdf_markitdown() {
  local input_file="$1"
  local output_file="$2"

  with_timeout "$TIMEOUT_PDF_TO_MD" bash -c "markitdown '$input_file' > '$output_file' 2>/dev/null"
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
# Uses Python's pymupdf4llm library for fast PDF→MD conversion
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
# convert_md_to_pdf - Convert Markdown to PDF using Pandoc with Typst or XeLaTeX
#
# Arguments:
#   $1 - Input Markdown file path
#   $2 - Output PDF file path
#
# Returns: 0 on success, 1 on failure
#
# Tries Typst first (if available), falls back to XeLaTeX
# Note: Requires with_timeout(), TIMEOUT_MD_TO_PDF, TYPST_AVAILABLE, XELATEX_AVAILABLE from convert-core.sh
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
# convert_pdf_to_md - Convert PDF to Markdown with auto tool selection
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output Markdown file path
#
# Returns: 0 on success, 1 on failure
#
# Uses CONVERSION_MODE to select tool:
#   - gemini: Try Gemini API first, fall back to local tools
#   - offline: Use local tools only (PyMuPDF4LLM preferred, then MarkItDown)
#
convert_pdf_to_md() {
  local input_file="$1"
  local output_file="$2"

  # If Gemini mode, try API first
  if [[ "${CONVERSION_MODE:-offline}" == "gemini" ]]; then
    if type convert_pdf_gemini &>/dev/null; then
      if convert_pdf_gemini "$input_file" "$output_file"; then
        return 0
      fi
      # Fallback to local tools on API failure
      echo "    Note: Gemini API failed, using offline fallback" >&2
    fi
  fi

  # Offline conversion (PyMuPDF4LLM preferred for better structure preservation)
  if [[ "${PYMUPDF_AVAILABLE:-false}" == "true" ]]; then
    if convert_pdf_pymupdf "$input_file" "$output_file"; then
      return 0
    fi
  fi

  # Fallback to MarkItDown
  if [[ "${MARKITDOWN_AVAILABLE:-false}" == "true" ]]; then
    if convert_pdf_markitdown "$input_file" "$output_file"; then
      return 0
    fi
  fi

  return 1
}

#
# convert_pdf_to_docx - Convert PDF to DOCX using pdf2docx
#
# Arguments:
#   $1 - Input PDF file path
#   $2 - Output DOCX file path
#
# Returns: 0 on success, 1 on failure
#
# Uses pdf2docx Python library for direct PDF→DOCX conversion.
# This preserves images and layout better than Gemini→Markdown→Pandoc pipeline.
#
convert_pdf_to_docx() {
  local input_file="$1"
  local output_file="$2"

  # Check if pdf2docx is available
  if [[ "${PDF2DOCX_AVAILABLE:-false}" != "true" ]]; then
    echo "Error: pdf2docx not installed. Run: pip install pdf2docx" >&2
    return 1
  fi

  # Use timeout for large PDFs
  with_timeout 300 python3 -c "
from pdf2docx import Converter
import sys

try:
    cv = Converter('$input_file')
    cv.convert('$output_file')
    cv.close()
    sys.exit(0)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null

  return $?
}

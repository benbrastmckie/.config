#!/usr/bin/env bash
#
# convert-pdf.sh - PDF conversion utilities
#
# Provides PDF ↔ Markdown conversion functions using MarkItDown, PyMuPDF4LLM, and Pandoc.
#
# Public API:
#   convert_pdf_markitdown(input_file, output_file) - PDF→MD using MarkItDown
#   convert_pdf_pymupdf(input_file, output_file) - PDF→MD using PyMuPDF4LLM
#   convert_md_to_pdf(input_file, output_file) - MD→PDF using Pandoc with Typst/XeLaTeX
#
# Dependencies:
#   - MarkItDown (optional, for PDF→MD)
#   - PyMuPDF4LLM (optional, for PDF→MD)
#   - Pandoc + Typst or XeLaTeX (optional, for MD→PDF)
#   - with_timeout() function (from convert-core.sh)
#   - TIMEOUT_PDF_TO_MD, TIMEOUT_MD_TO_PDF (from convert-core.sh)
#   - TYPST_AVAILABLE, XELATEX_AVAILABLE (from convert-core.sh)
#

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

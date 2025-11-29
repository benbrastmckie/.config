# Convert Libraries

## Purpose

Document conversion libraries for DOCX, PDF, and Markdown transformations. This directory provides the core conversion orchestration, format-specific converters for DOCX and PDF, and Markdown validation utilities. Used by the `/convert-docs` command for bidirectional document format conversion.

## Libraries

### convert-core.sh
Main document conversion orchestration with tool detection, file discovery, and batch processing.

**Key Functions:**
- `detect_tools()` - Detect available conversion tools
- `convert_file()` - Main conversion dispatcher
- `process_conversions()` - Process files sequentially or in parallel
- `main_conversion()` - Main entry point for conversion workflow

**Usage:**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh"
main_conversion "/path/to/input" "/path/to/output"
main_conversion "/input" "/output" --parallel 4
```

**Supported Conversions:**
- DOCX -> Markdown (MarkItDown primary, Pandoc fallback)
- PDF -> Markdown (MarkItDown primary, PyMuPDF4LLM fallback)
- Markdown -> DOCX (Pandoc)
- Markdown -> PDF (Pandoc with Typst or XeLaTeX)

### convert-docx.sh
DOCX conversion utilities.

**Key Functions:**
- `convert_docx()` - DOCX->MD using MarkItDown
- `convert_docx_pandoc()` - DOCX->MD using Pandoc
- `convert_md_to_docx()` - MD->DOCX using Pandoc

**Dependencies:** MarkItDown (optional), Pandoc (optional)

### convert-markdown.sh
Markdown validation and structure analysis.

**Key Functions:**
- `check_structure()` - Analyze Markdown structure
- `report_validation_warnings()` - Report conversion quality warnings

**Validation Checks:**
- File existence and size (minimum 100 bytes)
- Heading presence in Markdown
- Structure analysis (heading count, table count)

### convert-pdf.sh
PDF conversion utilities.

**Key Functions:**
- `convert_pdf_markitdown()` - PDF->MD using MarkItDown
- `convert_pdf_pymupdf()` - PDF->MD using PyMuPDF4LLM
- `convert_md_to_pdf()` - MD->PDF using Pandoc

**Dependencies:** MarkItDown (optional), PyMuPDF4LLM (optional), Pandoc (required for MD->PDF)

## Internal Dependencies

`convert-core.sh` automatically sources the other convert libraries:
- `convert-docx.sh`
- `convert-pdf.sh`
- `convert-markdown.sh`

When using document conversion, only source `convert-core.sh`.

## Used By

- `/convert-docs` command

## Navigation

- [← Parent Directory](../README.md)

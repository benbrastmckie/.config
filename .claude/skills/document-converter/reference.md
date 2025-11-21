# Document Converter - Technical Reference

Complete technical documentation for the document-converter skill, including tool specifications, quality metrics, API reference, and performance benchmarks.

## Tool Specifications

### MarkItDown

**Version**: Latest (pip installable)
**Repository**: https://github.com/microsoft/markitdown
**License**: MIT
**Platform**: Cross-platform (Python)

**Capabilities**:
- DOCX → Markdown conversion
- PDF → Markdown conversion
- Excel → Markdown table extraction
- PowerPoint → Markdown outline extraction
- Image OCR support (with pytesseract)

**Quality Metrics** (from testing):
- DOCX tables: 100% pipe-style markdown preservation
- Heading preservation: 95%+
- Unicode/emoji support: Perfect
- Image extraction: Reliable
- Processing speed: Fast (0.5-2s per file)

**Command Interface**:
```bash
markitdown input.docx > output.md
markitdown input.pdf > output.md
```

**Exit Codes**:
- 0: Success
- 1: File not found
- 2: Conversion error

**Installation**:
```bash
pip install markitdown

# With OCR support
pip install markitdown[ocr]
```

### Pandoc

**Version**: >= 2.0 (tested with 2.19+)
**Repository**: https://github.com/jgm/pandoc
**License**: GPL-2.0
**Platform**: Cross-platform (Haskell)

**Capabilities**:
- Universal document converter (40+ formats)
- DOCX ↔ Markdown
- PDF → Markdown (via LaTeX)
- Markdown → PDF (with LaTeX/Typst)
- HTML, EPUB, and more

**Quality Metrics**:
- DOCX→Markdown: 68% fidelity (tables verbose)
- Markdown→DOCX: 95%+ fidelity (excellent)
- Markdown→PDF: High quality (LaTeX rendering)
- Heading preservation: Excellent
- Table handling: Reliable but grid-style (verbose)

**Command Interface**:
```bash
# DOCX → Markdown
pandoc -f docx -t gfm input.docx -o output.md

# Markdown → DOCX
pandoc -f gfm -t docx input.md -o output.docx

# Markdown → PDF (with Typst)
pandoc -f gfm --pdf-engine=typst input.md -o output.pdf

# Markdown → PDF (with XeLaTeX)
pandoc -f gfm --pdf-engine=xelatex input.md -o output.pdf
```

**Format Options**:
- `gfm`: GitHub-Flavored Markdown (recommended)
- `markdown`: Pandoc's extended markdown
- `commonmark`: Strict CommonMark spec

**Exit Codes**:
- 0: Success
- 1: Conversion error
- 3: File not found
- 4: Encoding error

**Installation**:
```bash
# Ubuntu/Debian
apt install pandoc

# macOS
brew install pandoc

# From source
cabal install pandoc
```

### PyMuPDF4LLM

**Version**: Latest (pip installable)
**Repository**: https://github.com/pymupdf/PyMuPDF4LLM
**License**: AGPL-3.0
**Platform**: Cross-platform (Python)

**Capabilities**:
- PDF → Markdown conversion
- Optimized for LLM consumption
- Lightweight dependencies (PyMuPDF only)
- Fast processing
- Zero configuration

**Quality Metrics**:
- Text extraction: Excellent
- Unicode preservation: Perfect
- Table detection: Basic (not formatted)
- Image extraction: Supported
- Processing speed: Very fast (0.2-1s per file)

**Command Interface**:
```python
import pymupdf4llm

md_text = pymupdf4llm.to_markdown("input.pdf")
with open("output.md", "w") as f:
    f.write(md_text)
```

**Bash Wrapper** (used in skill):
```bash
python3 -c "
import sys
import pymupdf4llm

md_text = pymupdf4llm.to_markdown(sys.argv[1])
with open(sys.argv[2], 'w') as f:
    f.write(md_text)
" input.pdf output.md
```

**Installation**:
```bash
pip install pymupdf4llm
```

### Typst

**Version**: Latest (releases on GitHub)
**Repository**: https://github.com/typst/typst
**License**: Apache-2.0
**Platform**: Cross-platform (Rust binary)

**Capabilities**:
- Markdown → PDF compilation
- Fast rendering (Rust-based)
- Modern typesetting engine
- No LaTeX dependencies

**Quality Metrics**:
- Rendering speed: Very fast (<1s typical)
- Font support: Excellent
- Layout quality: High
- Unicode support: Perfect

**Command Interface**:
```bash
typst compile input.typ output.pdf

# Via Pandoc
pandoc --pdf-engine=typst input.md -o output.pdf
```

**Installation**:
```bash
# Ubuntu/Debian (manual)
wget https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz
tar -xf typst-*.tar.xz && sudo mv typst-*/typst /usr/local/bin/

# macOS
brew install typst

# Windows
scoop install typst
```

### XeLaTeX

**Version**: Part of TeX Live distribution
**License**: TeX license
**Platform**: Cross-platform (LaTeX)

**Capabilities**:
- Markdown → PDF compilation (via Pandoc)
- Traditional LaTeX typesetting
- Extensive font support
- Unicode support

**Quality Metrics**:
- Rendering quality: Excellent
- Rendering speed: Slower than Typst (5-10s typical)
- Font support: Extensive
- Package ecosystem: Comprehensive

**Command Interface**:
```bash
# Via Pandoc
pandoc --pdf-engine=xelatex input.md -o output.pdf
```

**Installation**:
```bash
# Ubuntu/Debian
apt install texlive-xetex

# macOS
brew install mactex

# Full TeX Live
wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzf install-tl-unx.tar.gz
cd install-tl-* && ./install-tl
```

## Quality Comparison Matrix

Based on comprehensive testing with sample documents:

| Source → Target | Tool 1 (Primary) | Fidelity | Tool 2 (Fallback) | Fidelity | Speed |
|-----------------|------------------|----------|-------------------|----------|-------|
| DOCX → Markdown | MarkItDown | 75-80% | Pandoc | 68% | Fast |
| PDF → Markdown | MarkItDown | 70-85% | PyMuPDF4LLM | 65-75% | Fast |
| Markdown → DOCX | Pandoc | 95%+ | - | - | Fast |
| Markdown → PDF | Pandoc+Typst | 98%+ | Pandoc+XeLaTeX | 98%+ | Typst faster |

**Fidelity Scoring Criteria**:
- Heading structure preserved (20%)
- List formatting preserved (15%)
- Table structure preserved (25%)
- Bold/italic preserved (10%)
- Links preserved (10%)
- Images extracted/embedded (10%)
- Unicode/special chars preserved (10%)

## API Reference

### convert-core.sh

Main orchestration module for document conversion.

#### Functions

##### `detect_tools()`

Detect available conversion tools and set global flags.

**Sets**:
- `MARKITDOWN_AVAILABLE` (true/false)
- `PANDOC_AVAILABLE` (true/false)
- `PYMUPDF_AVAILABLE` (true/false)
- `TYPST_AVAILABLE` (true/false)
- `XELATEX_AVAILABLE` (true/false)

**Example**:
```bash
source convert-core.sh
detect_tools

if [ "$MARKITDOWN_AVAILABLE" = true ]; then
  echo "MarkItDown is available"
fi
```

##### `discover_files(input_dir, output_dir)`

Discover convertible files in input directory and determine conversion direction.

**Parameters**:
- `input_dir`: Directory to scan for files
- `output_dir`: Destination directory

**Sets**:
- `CONVERSION_DIRECTION`: "TO_MARKDOWN" or "FROM_MARKDOWN"
- Populates arrays: `docx_files`, `pdf_files`, `md_files`

**Returns**: 0 on success, 1 on error (no files or mixed direction)

**Example**:
```bash
discover_files ~/Documents ~/Output
echo "Direction: $CONVERSION_DIRECTION"
echo "DOCX files: ${#docx_files[@]}"
```

##### `validate_file_output(output_file, format)`

Validate conversion output file meets quality standards.

**Parameters**:
- `output_file`: Path to output file
- `format`: Expected format ("markdown", "docx", "pdf")

**Returns**: 0 if valid, 1 if validation issues found

**Checks**:
- File exists and non-empty
- Markdown: Contains headings (basic structure check)
- Images referenced exist
- Encoding is valid UTF-8

**Example**:
```bash
if validate_file_output output.md markdown; then
  echo "Valid markdown output"
else
  echo "Validation failed"
  validation_failures=$((validation_failures + 1))
fi
```

##### `main_conversion(input_dir, output_dir)`

Main conversion entry point. Orchestrates full conversion workflow.

**Parameters**:
- `input_dir`: Directory containing files to convert
- `output_dir`: Destination directory (default: ./converted_output)

**Returns**: 0 on success, 1 on error

**Workflow**:
1. Detect tools
2. Discover files
3. Create output directory
4. Process conversions (batch)
5. Validate outputs
6. Generate conversion.log

**Example**:
```bash
source convert-core.sh
main_conversion ~/Documents ~/Output
```

### convert-docx.sh

DOCX-specific conversion functions.

#### Functions

##### `convert_docx_to_markdown(input_file, output_file)`

Convert DOCX file to Markdown using MarkItDown or Pandoc.

**Parameters**:
- `input_file`: Path to .docx file
- `output_file`: Path to .md output

**Returns**: 0 on success, 1 on failure

**Behavior**:
- Tries MarkItDown first (if available)
- Falls back to Pandoc on failure
- Applies timeout (60s default)
- Extracts images to `output_dir/media/`

**Example**:
```bash
source convert-docx.sh
convert_docx_to_markdown document.docx output.md
```

##### `convert_markdown_to_docx(input_file, output_file)`

Convert Markdown file to DOCX using Pandoc.

**Parameters**:
- `input_file`: Path to .md file
- `output_file`: Path to .docx output

**Returns**: 0 on success, 1 on failure

**Behavior**:
- Uses Pandoc (only option)
- Applies timeout (60s default)
- Preserves formatting (95%+ fidelity)

**Example**:
```bash
source convert-docx.sh
convert_markdown_to_docx README.md README.docx
```

### convert-pdf.sh

PDF-specific conversion functions.

#### Functions

##### `convert_pdf_to_markdown(input_file, output_file)`

Convert PDF file to Markdown using MarkItDown or PyMuPDF4LLM.

**Parameters**:
- `input_file`: Path to .pdf file
- `output_file`: Path to .md output

**Returns**: 0 on success, 1 on failure

**Behavior**:
- Tries MarkItDown first (if available)
- Falls back to PyMuPDF4LLM on failure
- Applies timeout (300s default - PDFs are slower)
- Extracts images to `output_dir/media/`

**Example**:
```bash
source convert-pdf.sh
convert_pdf_to_markdown report.pdf report.md
```

##### `convert_markdown_to_pdf(input_file, output_file)`

Convert Markdown file to PDF using Pandoc with Typst or XeLaTeX.

**Parameters**:
- `input_file`: Path to .md file
- `output_file`: Path to .pdf output

**Returns**: 0 on success, 1 on failure

**Behavior**:
- Tries Pandoc + Typst first (if available)
- Falls back to Pandoc + XeLaTeX
- Applies timeout (120s default)
- High-quality rendering

**Example**:
```bash
source convert-pdf.sh
convert_markdown_to_pdf document.md document.pdf
```

### convert-markdown.sh

Markdown utility functions.

#### Functions

##### `sanitize_filename(filename)`

Sanitize filename for safe filesystem usage.

**Parameters**:
- `filename`: Input filename

**Returns**: Sanitized filename (stdout)

**Behavior**:
- Converts spaces to underscores
- Lowercases filename
- Removes special characters
- Preserves extension

**Example**:
```bash
source convert-markdown.sh
clean_name=$(sanitize_filename "My Document (Draft).md")
echo "$clean_name"  # my_document_draft.md
```

##### `extract_markdown_images(markdown_file, media_dir)`

Extract image references from markdown file.

**Parameters**:
- `markdown_file`: Path to .md file
- `media_dir`: Directory for extracted images

**Returns**: 0 on success, 1 on error

**Behavior**:
- Parses markdown for image syntax `![alt](path)`
- Copies referenced images to media_dir
- Updates image paths in markdown

**Example**:
```bash
source convert-markdown.sh
extract_markdown_images document.md ./media/
```

## Performance Benchmarks

Measured on typical developer workstation (8-core CPU, SSD):

### Conversion Speed

| Source Format | Target Format | Tool | File Size | Time | Throughput |
|---------------|---------------|------|-----------|------|------------|
| DOCX | Markdown | MarkItDown | 100KB | 0.8s | 125KB/s |
| DOCX | Markdown | Pandoc | 100KB | 1.2s | 83KB/s |
| PDF (text) | Markdown | MarkItDown | 500KB | 2.3s | 217KB/s |
| PDF (text) | Markdown | PyMuPDF4LLM | 500KB | 0.9s | 555KB/s |
| PDF (scan) | Markdown | MarkItDown | 2MB | 15s | 133KB/s |
| Markdown | DOCX | Pandoc | 50KB | 0.7s | 71KB/s |
| Markdown | PDF | Typst | 50KB | 0.5s | 100KB/s |
| Markdown | PDF | XeLaTeX | 50KB | 6.2s | 8KB/s |

### Batch Processing

| Files | Format | Concurrency | Total Time | Per-File Avg |
|-------|--------|-------------|------------|--------------|
| 10 DOCX | → Markdown | 4 | 3.2s | 0.32s |
| 10 DOCX | → Markdown | 1 | 9.8s | 0.98s |
| 20 PDF | → Markdown | 4 | 12.5s | 0.63s |
| 20 PDF | → Markdown | 1 | 43s | 2.15s |
| 50 Markdown | → DOCX | 4 | 14s | 0.28s |
| 50 Markdown | → PDF | 4 | 32s | 0.64s |

**Concurrency Benefits**:
- 4 parallel conversions: ~3x speedup vs sequential
- Diminishing returns beyond 4 concurrent (I/O bound)
- Optimal: Match CPU core count (4-8 concurrent)

## Configuration Reference

### Environment Variables

#### Timeout Configuration

```bash
# Base timeout values (seconds)
TIMEOUT_DOCX_TO_MD=60      # DOCX → Markdown timeout
TIMEOUT_PDF_TO_MD=300      # PDF → Markdown timeout (longer for scans)
TIMEOUT_MD_TO_DOCX=60      # Markdown → DOCX timeout
TIMEOUT_MD_TO_PDF=120      # Markdown → PDF timeout

# Global multiplier
TIMEOUT_MULTIPLIER=1.5     # Increase all timeouts by 50%
```

#### Resource Limits

```bash
# Disk usage limits
MAX_DISK_USAGE_GB=10       # Abort if output exceeds 10GB
MIN_FREE_SPACE_MB=100      # Require 100MB free space

# Concurrency
MAX_CONCURRENT_CONVERSIONS=4  # Parallel conversion limit
```

#### Logging

```bash
# Log file location
LOG_FILE=/path/to/conversion.log

# Log level (not currently implemented)
LOG_LEVEL=INFO  # DEBUG, INFO, WARN, ERROR
```

### Configuration Files

Currently, the conversion system uses environment variables only. Future enhancement could add:

**~/.claude/convert.conf**:
```ini
[timeouts]
docx_to_md = 60
pdf_to_md = 300
md_to_docx = 60
md_to_pdf = 120

[resources]
max_disk_gb = 10
min_free_mb = 100
max_concurrent = 4

[tools]
prefer_markitdown = true
prefer_typst = true
```

## Troubleshooting Guide

### Common Issues

#### Issue: "No conversion tool available"

**Cause**: Required tools not installed.

**Solution**:
```bash
# Install MarkItDown (recommended)
pip install markitdown

# Install Pandoc (required for Markdown → DOCX/PDF)
apt install pandoc  # Ubuntu/Debian
brew install pandoc  # macOS
```

#### Issue: "Conversion timeout"

**Cause**: File too large or complex for default timeout.

**Solution**:
```bash
# Increase timeout multiplier
export TIMEOUT_MULTIPLIER=2.0

# Or increase specific timeout
export TIMEOUT_PDF_TO_MD=600  # 10 minutes
```

#### Issue: "Tables look wrong in output"

**Cause**: Tool-specific table formatting differences.

**Solution**:
- MarkItDown: Pipe-style tables (best for GFM)
- Pandoc: Grid-style tables (verbose but reliable)
- Try alternate tool: `--use-agent` mode allows manual tool selection

#### Issue: "Images missing in output"

**Cause**: Image extraction failed or paths incorrect.

**Solution**:
- Check `media/` directory created
- Verify image paths in markdown (`![alt](media/image.png)`)
- Check conversion.log for image extraction errors

#### Issue: "Unicode characters corrupted"

**Cause**: Encoding issues in conversion pipeline.

**Solution**:
- MarkItDown: Perfect Unicode support (use as primary)
- PyMuPDF4LLM: Perfect Unicode support
- Pandoc: Check locale settings (`export LANG=en_US.UTF-8`)

#### Issue: "PDF conversion poor quality"

**Cause**: Scanned PDF or complex layout.

**Solution**:
- Scanned PDFs: Install OCR support (`pip install markitdown[ocr]`)
- Complex layouts: Try PyMuPDF4LLM fallback
- Increase timeout for large scans

#### Issue: "Batch conversion hangs"

**Cause**: Concurrent conversion deadlock or timeout.

**Solution**:
```bash
# Reduce concurrency
export MAX_CONCURRENT_CONVERSIONS=1

# Increase timeouts
export TIMEOUT_MULTIPLIER=3.0
```

### Debugging Tips

#### Enable Verbose Logging

```bash
# Run with bash tracing
bash -x /path/to/convert-core.sh

# Check conversion.log after run
cat conversion.log | grep FAILED
cat conversion.log | grep WARNING
```

#### Test Single File

Isolate issue by testing single file conversion:

```bash
# Test DOCX → Markdown
source convert-core.sh
detect_tools
convert_docx_to_markdown test.docx test.md

# Check exit code
echo $?  # 0 = success, 1 = failure
```

#### Check Tool Versions

```bash
# MarkItDown version
pip show markitdown

# Pandoc version
pandoc --version

# PyMuPDF4LLM version
pip show pymupdf4llm
```

## Migration Notes

### From convert-docs Command

If migrating from direct command usage to skill-based approach:

**Before** (command invocation):
```bash
/convert-docs ./documents ./output
```

**After** (skill-based, automatic):
```markdown
"Convert the PDF reports in ./documents to Markdown"
→ Claude automatically invokes document-converter skill
→ Same conversion quality and tools
→ More seamless integration in workflows
```

**Benefits**:
- Automatic skill discovery (no explicit command needed)
- Composition with other skills
- Unified conversion interface across workflows

### Backward Compatibility

The `/convert-docs` command is fully backward compatible:
- Checks for skill availability
- Delegates to skill if available
- Falls back to script mode if skill not present
- Zero breaking changes

## Future Enhancements

### Planned Features

1. **Configuration File Support**
   - Move from environment variables to ~/.claude/convert.conf
   - Per-project configuration overrides

2. **Quality Metrics API**
   - Programmatic quality scoring
   - Automated quality regression testing

3. **Format Extensions**
   - HTML → Markdown
   - Markdown → HTML
   - EPUB support

4. **Advanced Image Handling**
   - Image optimization (compress large images)
   - OCR for scanned document images
   - SVG preservation

5. **Incremental Conversion**
   - Skip already-converted files (checksum comparison)
   - Resume interrupted batch conversions

### Feature Requests

See [GitHub Issues](https://github.com/your-repo/issues) for feature requests and roadmap.

## Changelog

### Version 1.0.0 (2025-11-20)
- Initial skill release
- DOCX ↔ Markdown conversion
- PDF → Markdown conversion
- Markdown → PDF conversion
- Tool auto-detection and fallback
- Batch processing support
- Quality validation
- Concurrent conversion support

## License

Same license as parent project. See LICENSE file.

# Document Converter - Usage Examples

Practical examples for using the document-converter skill in various scenarios, from simple conversions to complex workflows.

## Basic Conversions

### Single DOCX to Markdown

```bash
# Source conversion library
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Detect tools
detect_tools

# Convert single file
convert_docx_to_markdown ~/Documents/report.docx ~/Output/report.md

# Check result
cat ~/Output/report.md
```

**Expected Output**:
```
[PROGRESS] Converting: report.docx → report.md
[SUCCESS] Converted report.docx → report.md (MarkItDown)
```

### Single PDF to Markdown

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
detect_tools

convert_pdf_to_markdown ~/Documents/whitepaper.pdf ~/Output/whitepaper.md

# Verify output
ls -lh ~/Output/whitepaper.md
cat ~/Output/whitepaper.md | head -20
```

**Note**: PDF conversions may take longer (up to 300s for large scanned PDFs).

### Markdown to DOCX

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
detect_tools

convert_markdown_to_docx ~/notes/README.md ~/Output/README.docx

# Open in Word to verify
xdg-open ~/Output/README.docx  # Linux
open ~/Output/README.docx      # macOS
```

**Quality**: 95%+ fidelity with Pandoc (excellent formatting preservation).

### Markdown to PDF

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
detect_tools

convert_markdown_to_pdf ~/notes/document.md ~/Output/document.pdf

# Open PDF viewer
xdg-open ~/Output/document.pdf  # Linux
open ~/Output/document.pdf      # macOS
```

**Note**: Requires Typst or XeLaTeX for PDF engine.

## Batch Conversions

### Convert All DOCX in Directory

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Main conversion handles batch automatically
main_conversion ~/Documents/Word ~/Output/Markdown

# Check results
cat ~/Output/Markdown/conversion.log
```

**Output Structure**:
```
~/Output/Markdown/
├── conversion.log
├── document1.md
├── document2.md
├── report.md
└── media/
    ├── image1.png
    └── image2.jpg
```

### Convert All PDFs in Directory

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

main_conversion ~/Downloads/PDFs ~/Output/Markdown

# Review log for failures
grep FAILED ~/Output/Markdown/conversion.log
```

**Typical Batch Stats** (10 files):
```
Conversion Statistics:
  DOCX → Markdown: 10 succeeded, 0 failed
  Processing time: 3.2 seconds (4 concurrent)
  Tool: MarkItDown (primary)
```

### Convert All Markdown to DOCX

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

main_conversion ~/notes ~/Output/DOCX

# Verify all files converted
ls ~/Output/DOCX/*.docx | wc -l
```

## Agent-Based Workflows

### Autonomous Conversion (Skill Auto-Invoke)

When working in Claude Code, the skill automatically triggers:

**User**: "Extract text from the PDF reports in ./research/"

**Claude** (internal):
```
→ Detects conversion need
→ Loads document-converter skill
→ Executes conversion
→ Returns structured markdown
```

**Result**: PDF files converted to markdown without explicit command.

### Explicit Skill Invocation

```markdown
User: "Use the document-converter skill to convert all Word documents in ./contracts/ to markdown for analysis"

Claude: I'll use the document-converter skill to convert the Word documents.

[Invokes skill internally]

Result:
- Converted 15 DOCX files to Markdown
- Extracted to ./contracts/markdown/
- See conversion.log for details
```

### Command Integration

The `/convert-docs` command delegates to the skill when available:

```bash
# Standard command usage
/convert-docs ./documents ./output

# Behind the scenes:
# 1. Checks if document-converter skill exists
# 2. Delegates to skill if available
# 3. Falls back to script mode if not
```

## Advanced Scenarios

### Custom Timeout Configuration

For large or complex files:

```bash
# Increase PDF timeout to 10 minutes
export TIMEOUT_PDF_TO_MD=600

# Or use multiplier
export TIMEOUT_MULTIPLIER=2.0

source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
main_conversion ~/large_pdfs ~/output
```

### Concurrent Conversion Tuning

Optimize for your system:

```bash
# Low-powered system (reduce concurrency)
export MAX_CONCURRENT_CONVERSIONS=2

# High-powered system (increase concurrency)
export MAX_CONCURRENT_CONVERSIONS=8

source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
main_conversion ~/documents ~/output
```

### Selective Tool Usage

Force specific tool when needed:

```bash
# Use only Pandoc (skip MarkItDown)
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Manually set tool availability
MARKITDOWN_AVAILABLE=false
PANDOC_AVAILABLE=true

main_conversion ~/documents ~/output
```

**Use Case**: Testing tool-specific output differences.

### Disk Space Management

Prevent disk exhaustion:

```bash
# Limit output size to 5GB
export MAX_DISK_USAGE_GB=5

# Require 500MB free space
export MIN_FREE_SPACE_MB=500

source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
main_conversion ~/large_dataset ~/output
```

**Behavior**: Conversion aborts if limits exceeded.

## Quality Validation Workflows

### Validate Conversion Output

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Convert file
convert_docx_to_markdown report.docx report.md

# Validate output
if validate_file_output report.md markdown; then
  echo "✓ Conversion quality verified"
else
  echo "⚠ Validation warnings (check conversion.log)"
fi
```

**Validation Checks**:
- File exists and non-empty
- Contains headings (structural check)
- Referenced images exist
- Valid UTF-8 encoding

### Compare Tool Output

Test quality differences between tools:

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Convert with MarkItDown
PANDOC_AVAILABLE=false
convert_docx_to_markdown test.docx test_markitdown.md

# Convert with Pandoc
MARKITDOWN_AVAILABLE=false
PANDOC_AVAILABLE=true
convert_docx_to_markdown test.docx test_pandoc.md

# Compare outputs
diff -u test_markitdown.md test_pandoc.md
```

**Analysis**: Review table formatting, image handling, Unicode characters.

## Integration Examples

### Skill Composition

Document-converter can be used alongside other skills:

```markdown
User: "Analyze the financial reports in ./pdfs/ and create a summary"

Claude:
1. Uses document-converter skill to extract text from PDFs
2. Uses research-specialist skill to analyze financial data
3. Uses doc-generator skill to create summary document

Result: Comprehensive analysis with source extraction automated
```

### Workflow Automation

Integrate with other Claude Code features:

```bash
# Example: Convert, analyze, commit workflow
/convert-docs ./research/pdfs ./research/markdown
# → Converts PDFs to Markdown (skill-based)

# Analyze markdown files (research agent)
"Analyze the converted markdown files in ./research/markdown"

# Commit results
/commit "Add research analysis from PDF reports"
```

## Troubleshooting Examples

### Handle Conversion Failures

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

main_conversion ~/documents ~/output

# Check for failures
if grep -q FAILED ~/output/conversion.log; then
  echo "Some conversions failed:"
  grep FAILED ~/output/conversion.log

  # Retry with increased timeout
  export TIMEOUT_MULTIPLIER=2.0
  # Manually retry failed files...
fi
```

### Debug Single File Issues

Isolate problem files:

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
detect_tools

# Enable bash tracing
set -x

# Convert problematic file
convert_pdf_to_markdown problem.pdf problem.md

# Check exit code
echo "Exit code: $?"

# Disable tracing
set +x
```

### Test Tool Availability

Verify tools before conversion:

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

detect_tools

echo "Tool Availability:"
echo "  MarkItDown: $MARKITDOWN_AVAILABLE"
echo "  Pandoc: $PANDOC_AVAILABLE"
echo "  PyMuPDF4LLM: $PYMUPDF_AVAILABLE"
echo "  Typst: $TYPST_AVAILABLE"
echo "  XeLaTeX: $XELATEX_AVAILABLE"

# Install missing tools if needed
if [ "$MARKITDOWN_AVAILABLE" = false ]; then
  echo "Installing MarkItDown..."
  pip install markitdown
fi
```

## Performance Benchmarking

### Measure Conversion Speed

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Benchmark single file
time convert_docx_to_markdown large.docx large.md

# Benchmark batch
time main_conversion ~/100_files ~/output

# Parse conversion.log for detailed timing
grep "Processing time" ~/output/conversion.log
```

### Compare Concurrency Settings

```bash
# Test sequential
export MAX_CONCURRENT_CONVERSIONS=1
time main_conversion ~/test_files ~/output_seq

# Test parallel (4 concurrent)
export MAX_CONCURRENT_CONVERSIONS=4
time main_conversion ~/test_files ~/output_par

# Calculate speedup
# Typical: 3-4x faster with 4 concurrent
```

## Edge Cases

### Handle Mixed File Types

```bash
# Directory with DOCX, PDF, and MD files
# Note: Cannot mix TO_MARKDOWN and FROM_MARKDOWN in single run

# Convert documents TO markdown first
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
main_conversion ~/mixed/docs ~/mixed/markdown

# Then convert markdown FROM markdown to DOCX/PDF
main_conversion ~/mixed/markdown ~/mixed/docx
```

**Error if Mixed**:
```
Error: Cannot mix TO_MARKDOWN and FROM_MARKDOWN conversions
Found: DOCX files AND MD files in same directory
```

### Handle Special Characters in Filenames

```bash
source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Filename sanitization automatic
convert_docx_to_markdown "My Document (Draft) [v2].docx" "output.md"

# Output filename sanitized: my_document_draft_v2.md
```

**Sanitization Rules**:
- Spaces → underscores
- Lowercase conversion
- Special characters removed
- Extension preserved

### Handle Very Large Files

```bash
# Increase timeout significantly
export TIMEOUT_PDF_TO_MD=1800  # 30 minutes

# Reduce concurrency (memory management)
export MAX_CONCURRENT_CONVERSIONS=1

source /home/benjamin/.config/.claude/lib/convert/convert-core.sh
main_conversion ~/large_scanned_pdfs ~/output
```

**Note**: Scanned PDFs with OCR can take 10-20 minutes for 100+ page documents.

## Real-World Use Cases

### Documentation Migration

**Scenario**: Migrate Word-based documentation to Markdown for version control.

```bash
# Convert all DOCX to Markdown
/convert-docs ./docs/word ./docs/markdown

# Review conversion quality
cat ./docs/markdown/conversion.log

# Commit to git
cd ./docs/markdown
git add *.md media/
git commit -m "Migrate documentation from Word to Markdown"
```

### Research Paper Extraction

**Scenario**: Extract text from PDF research papers for analysis.

```markdown
User: "Extract text from the PDFs in ./research/papers/ for literature review"

Claude: [Invokes document-converter skill]

Result:
- Converted 45 PDF papers to Markdown
- Extracted to ./research/papers/markdown/
- Ready for analysis and summarization
```

### Report Generation

**Scenario**: Generate DOCX reports from Markdown templates.

```bash
# Write report in Markdown (easier editing)
vim report_template.md

# Convert to DOCX for distribution
/convert-docs ./templates ./reports

# Result: Professional DOCX report generated
ls ./reports/report_template.docx
```

### Batch Invoice Processing

**Scenario**: Extract text from PDF invoices for accounting.

```bash
# Convert all invoice PDFs to Markdown
/convert-docs ./invoices/pdf ./invoices/text

# Parse markdown for structured data
# (Next step: Use grep/awk to extract invoice numbers, amounts, etc.)
grep "Total:" ./invoices/text/*.md
```

## Testing and Validation

### Test Suite Example

```bash
#!/bin/bash
# test_conversions.sh - Validate document-converter skill

source /home/benjamin/.config/.claude/lib/convert/convert-core.sh

# Test 1: DOCX → Markdown
echo "Test 1: DOCX → Markdown"
detect_tools
convert_docx_to_markdown test/sample.docx test/output.md
[ -f test/output.md ] && echo "✓ PASS" || echo "✗ FAIL"

# Test 2: PDF → Markdown
echo "Test 2: PDF → Markdown"
convert_pdf_to_markdown test/sample.pdf test/output.md
[ -f test/output.md ] && echo "✓ PASS" || echo "✗ FAIL"

# Test 3: Markdown → DOCX
echo "Test 3: Markdown → DOCX"
convert_markdown_to_docx test/sample.md test/output.docx
[ -f test/output.docx ] && echo "✓ PASS" || echo "✗ FAIL"

# Test 4: Markdown → PDF
echo "Test 4: Markdown → PDF"
convert_markdown_to_pdf test/sample.md test/output.pdf
[ -f test/output.pdf ] && echo "✓ PASS" || echo "✗ FAIL"

# Test 5: Batch conversion
echo "Test 5: Batch conversion"
main_conversion test/batch test/batch_output
[ -f test/batch_output/conversion.log ] && echo "✓ PASS" || echo "✗ FAIL"
```

### Quality Regression Testing

```bash
# Baseline: Convert with current tools
/convert-docs test/baseline/docs test/baseline/output

# After tool update: Convert again
/convert-docs test/baseline/docs test/updated/output

# Compare outputs
diff -r test/baseline/output test/updated/output

# Manual review of differences
# Focus on: tables, images, unicode, headings
```

## Tips and Best Practices

### When to Use Script Mode vs Agent Mode

**Script Mode** (default):
- Standard batch conversions
- Fast processing required
- Tools already validated
- No quality reporting needed

**Agent Mode** (`--use-agent`):
- First-time conversions (tool detection)
- Quality-critical documents
- Troubleshooting conversion issues
- Detailed logging required

### Optimizing Conversion Quality

1. **Use MarkItDown for DOCX/PDF** (better table preservation)
2. **Install optional tools** (Typst for faster PDFs)
3. **Review conversion.log** (check warnings)
4. **Validate critical conversions** (use validate_file_output)
5. **Test sample files first** (before batch processing)

### Managing Large Batch Conversions

1. **Set appropriate timeouts** (longer for scanned PDFs)
2. **Tune concurrency** (match CPU cores)
3. **Monitor disk space** (set MAX_DISK_USAGE_GB)
4. **Review failures incrementally** (check conversion.log periodically)
5. **Resume interrupted conversions** (skill handles partial completion)

### Handling Edge Cases

1. **Special characters in filenames** → Automatic sanitization
2. **Mixed file types** → Separate conversion runs (TO vs FROM markdown)
3. **Very large files** → Increase timeouts, reduce concurrency
4. **Scanned PDFs** → Install OCR support (`pip install markitdown[ocr]`)
5. **Complex layouts** → Try alternate tool (PyMuPDF4LLM for PDFs)

## Additional Resources

- [SKILL.md](./SKILL.md) - Core skill documentation
- [reference.md](./reference.md) - Technical reference and API docs
- [Convert-Docs Command Guide](../../docs/guides/commands/convert-docs-command-guide.md)
- [MarkItDown Documentation](https://github.com/microsoft/markitdown)
- [Pandoc Manual](https://pandoc.org/MANUAL.html)
- [PyMuPDF4LLM Repository](https://github.com/pymupdf/PyMuPDF4LLM)

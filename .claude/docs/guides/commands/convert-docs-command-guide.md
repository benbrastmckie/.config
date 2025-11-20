# /convert-docs Command - Complete Guide

**Executable**: `.claude/commands/convert-docs.md`

**Quick Start**: Run `/convert-docs <input-directory>` to convert documents bidirectionally.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

The `/convert-docs` command converts documents bidirectionally between Markdown, Word (DOCX), and PDF formats. It automatically detects file types and applies appropriate conversion tools.

### Supported Conversions

- **To Markdown**: `.docx`, `.pdf` files
- **From Markdown**: `.md` files to DOCX (PDF via Pandoc)

### When to Use

- Converting Word documents to Markdown for version control
- Converting research PDFs to editable Markdown
- Generating Word/PDF reports from Markdown documentation
- Batch processing multiple documents

### When NOT to Use

- Single file that can be manually converted
- Complex documents with special formatting that may not convert cleanly
- Protected/encrypted documents

---

## Architecture

### Design Principles

- **Dual Mode**: Script mode (fast) or Agent mode (comprehensive)
- **Automatic Detection**: Identifies conversion direction from file types
- **Fallback Mechanisms**: Multiple tools with automatic retry

### Patterns Used

- Conditional mode selection pattern
- Tool fallback chain
- Conversion coordinator pattern

### Integration Points

- **convert-core.sh**: Core conversion library
- **doc-converter agent**: Comprehensive 5-phase workflow
- **Pandoc**: Primary conversion tool
- **Mammoth**: DOCX-specific tool (fallback)
- **pdf-to-text/pdftotext**: PDF extraction tools

### Data Flow

```
Input Directory → Mode Detection → Tool Selection
                                        ↓
Output Directory ← Logging ← Conversion ← Validation
```

---

## Usage Examples

### Example 1: Basic Conversion (Script Mode)

```bash
/convert-docs ~/Documents/Reports
```

**Expected Output**:
```
PROGRESS: Detecting file types...
PROGRESS: Found 3 DOCX files, 2 PDF files
PROGRESS: Converting to Markdown...
PROGRESS: report1.docx -> report1.md (success)
PROGRESS: report2.docx -> report2.md (success)
PROGRESS: research.pdf -> research.md (success)
CONVERSION_COMPLETE: 5/5 files converted
Output: ./converted_output/
Log: ./converted_output/conversion.log
```

**Explanation**:
Script mode provides fast conversion with automatic tool selection and fallback handling.

### Example 2: Specify Output Directory

```bash
/convert-docs ~/Documents/Reports ~/Projects/docs
```

**Expected Output**:
```
PROGRESS: Output directory: ~/Projects/docs
PROGRESS: Converting 5 files...
CONVERSION_COMPLETE: 5/5 files converted
```

**Explanation**:
Converted files are placed in the specified output directory instead of `./converted_output/`.

### Example 3: Agent Mode (Comprehensive)

```bash
/convert-docs ~/Documents/Reports --use-agent
```

**Expected Output**:
```
PROGRESS: Initializing doc-converter agent...
PROGRESS: Phase 1: Tool verification...
PROGRESS: Phase 2: File analysis...
PROGRESS: Phase 3: Conversion execution...
PROGRESS: Phase 4: Quality validation...
PROGRESS: Phase 5: Summary reporting...
CONVERSION_COMPLETE: All files converted with quality report
```

**Explanation**:
Agent mode provides comprehensive workflow with quality checks, detailed logging, and validation phases.

### Example 4: Markdown to DOCX

```bash
/convert-docs ~/Projects/docs/markdown
```

**Expected Output**:
```
PROGRESS: Found 4 MD files
PROGRESS: Converting to DOCX...
PROGRESS: readme.md -> readme.docx (success)
CONVERSION_COMPLETE: 4/4 files converted
```

**Explanation**:
When input contains Markdown files, they are converted to DOCX format.

---

## Advanced Topics

### Performance Considerations

- Script mode: <0.5s overhead, instant conversion start
- Agent mode: ~2-3s initialization overhead
- Large PDFs may take longer due to text extraction
- Consider batch sizes for many files

### Execution Modes

#### Script Mode (Default)
- **Speed**: Fastest, minimal overhead
- **Use for**: Standard conversions, quick batch processing
- **Tools**: Same quality as agent mode
- **Logging**: Basic conversion log

#### Agent Mode
- **Speed**: 2-3s additional overhead
- **Use for**: Quality-critical conversions, audits
- **Trigger**: `--use-agent` flag or keywords
- **Keywords**: "detailed logging", "quality reporting", "verify tools"

### Tool Priority

**For DOCX conversion**:
1. Pandoc (primary)
2. Mammoth (fallback)

**For PDF conversion**:
1. pdftotext (primary)
2. pdf-to-text (fallback)

**For Markdown to DOCX**:
1. Pandoc (primary)

### Quality Considerations

- Complex tables may require manual adjustment
- Images are referenced but may need path updates
- Headers/footers converted to Markdown sections
- Footnotes converted to inline or endnotes

---

## Troubleshooting

### Common Issues

#### Issue 1: Pandoc Not Found

**Symptoms**:
- "pandoc: command not found" error
- Conversion fails immediately

**Cause**:
Pandoc not installed on system

**Solution**:
```bash
# Ubuntu/Debian
sudo apt install pandoc

# macOS
brew install pandoc

# Verify installation
pandoc --version
```

#### Issue 2: PDF Text Extraction Failed

**Symptoms**:
- Empty or garbled Markdown output
- "Unable to extract text" error

**Cause**:
PDF may be image-based (scanned) or protected

**Solution**:
```bash
# Check if PDF contains text
pdftotext input.pdf - | head -20

# For image-based PDFs, use OCR:
# Install tesseract and use ocrmypdf first
ocrmypdf input.pdf input_ocr.pdf
/convert-docs <directory-with-ocr-pdf>
```

#### Issue 3: Encoding Issues

**Symptoms**:
- Strange characters in output
- Conversion succeeds but content garbled

**Cause**:
Source document has non-UTF-8 encoding

**Solution**:
```bash
# Check file encoding
file -i input.docx

# For agent mode with explicit encoding
/convert-docs <input-dir> --use-agent
# Agent handles encoding detection
```

### Debug Mode

Enable verbose output with agent mode:
```bash
/convert-docs <input-dir> --use-agent

# Check detailed log
cat ./converted_output/conversion.log
```

### Getting Help

- Check [Command Reference](.claude/docs/reference/standards/command-reference.md) for quick syntax
- Review conversion tools documentation (Pandoc, Mammoth)
- See related commands: `/research`, `/document`

---

## See Also

- [Command Reference](.claude/docs/reference/standards/command-reference.md)
- [Pandoc Documentation](https://pandoc.org/MANUAL.html)
- [Library API - convert-core.sh](.claude/docs/reference/library-api/overview.md)

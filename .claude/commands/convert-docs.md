---
command-type: primary
description: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally
argument-hint: <input-directory> [output-directory]
allowed-tools: Task, Read, Bash
agent-dependencies: doc-converter
---

# Convert Documents - Bidirectional Conversion

Convert between Markdown, Word (DOCX), and PDF formats using the doc-converter agent. Direction is automatically detected from file extensions.

## Usage

```bash
/convert-docs <input-directory> [output-directory]
```

## Parameters

- `input-directory` (required): Directory containing files to convert
  - `.docx` or `.pdf` files → Converts TO Markdown
  - `.md` files → Converts TO PDF and DOCX
- `output-directory` (optional): Where to save converted files (default: `./converted_output`)

## Examples

### Converting TO Markdown

```bash
# Convert DOCX/PDF to Markdown in current directory
/convert-docs .

# Convert documents from specific directory
/convert-docs ~/Documents/Reports

# Specify custom output directory
/convert-docs ~/Documents/Reports ~/Documents/Markdown
```

### Converting FROM Markdown

```bash
# Convert Markdown files to PDF and DOCX
/convert-docs ~/Documents/Markdown ~/Documents/PDFs

# Convert project documentation to distributable formats
/convert-docs ./docs ./docs-output

# Convert notes to Word/PDF
/convert-docs ~/notes/md ~/notes/formatted
```

## Tool Selection

The doc-converter agent uses intelligent tool selection based on comprehensive quality testing (see Report 003):

### DOCX to Markdown
1. **MarkItDown** (primary) - 75-80% fidelity, perfect table preservation
2. **Pandoc** (fallback) - 68% fidelity

### PDF to Markdown
1. **marker-pdf** (primary) - 95% fidelity, best quality
2. **PyMuPDF4LLM** (fallback) - 55% fidelity, extremely fast (0.14s)

The agent automatically detects available tools and selects the best option.
Conversion logs show which tool was used for each file.

## Orchestration Mode

For quality-critical conversions, batch processing, or audit requirements, enable **orchestration mode** by including keywords in your request:

**Trigger Keywords**:
- "detailed logging"
- "quality reporting"
- "verify tools"
- "orchestrated workflow"
- "comprehensive logging"

**Example Requests**:
```bash
# Enable orchestration mode with detailed logging
/convert-docs ./documents ./output with detailed logging

# Request quality reporting
/convert-docs ./pdfs ./markdown with quality reporting and tool verification
```

**Orchestration Mode Provides**:
1. **Comprehensive Tool Detection** - Reports all available tools with version numbers
2. **Explicit Tool Selection** - Shows which tools will be used BEFORE conversion starts with quality indicators (HIGH/MEDIUM/FAST)
3. **Detailed Logging** - Structured log file with timestamped entries and section separators
4. **Automatic Fallback Retry** - If MarkItDown fails, automatically retries with Pandoc (same for marker-pdf→PyMuPDF4LLM)
5. **Verification Phase** - File size checks, structure validation (heading/table counts), quality warnings
6. **Summary Reporting** - Stage-by-stage success/failure counts, verification warnings, overall statistics

**Use Orchestration Mode When**:
- Converting critical business documents
- Batch processing large document collections
- Quality auditing is required
- Troubleshooting conversion issues
- Generating reports on tool availability

**Log File Structure**:
```
========================================
TOOL DETECTION PHASE
========================================
✓ Pandoc: AVAILABLE - pandoc 3.1.2
✓ MarkItDown: AVAILABLE - version 0.1.5
✗ marker-pdf: NOT AVAILABLE

========================================
TOOL SELECTION PHASE
========================================
DOCX Converter: MarkItDown (HIGH quality, 75-80% fidelity)
  Q: Why MarkItDown?
  A: Best table preservation, clean output, fast processing

========================================
CONVERSION PHASE
========================================
Converting DOCX files...
  [1/5] Processing: report.docx
    ✓ SUCCESS: MarkItDown (HIGH quality)
  [2/5] Processing: notes.docx
    ✗ FAILED: MarkItDown conversion failed
    → Attempting Pandoc fallback...
    ✓ SUCCESS: Pandoc (fallback, MEDIUM quality)

========================================
VERIFICATION PHASE
========================================
✓ report.md: 15 headings, 3 table lines, 8432 bytes
✓ notes.md: 8 headings, 0 table lines, 2156 bytes

========================================
CONVERSION SUMMARY
========================================
DOCX: 5 succeeded, 0 failed (total: 5)
Overall: 5 succeeded, 0 failed (total: 5)
Verification warnings: 0
```

## What It Does

The doc-converter agent provides bidirectional conversion with optional orchestration mode for quality-critical workflows.

### Converting TO Markdown

**Standard Mode** (default):
1. **Detect Tools** - Identify best available converters for each format
2. **Discover** all DOCX and PDF files in the input directory
3. **Convert** using intelligent tool selection:
   - DOCX files → MarkItDown (primary, 75-80% fidelity) or Pandoc (fallback, 68% fidelity)
   - PDF files → marker-pdf (primary, 95% fidelity) or PyMuPDF4LLM (fallback, fast)
4. **Extract** images to organized directories (when using Pandoc/marker-pdf)
5. **Validate** conversion results and check quality
6. **Report** detailed statistics including which tools were used and any failures

**Orchestration Mode** (enabled with keywords like "detailed logging", "quality reporting", "verify tools"):
1. **Tool Detection Phase** - Report all available tools with versions
2. **Tool Selection Phase** - Show which tools will be used BEFORE conversion with quality indicators
3. **Conversion Phase** - Process files with detailed logging, automatic fallback retry (MarkItDown→Pandoc)
4. **Verification Phase** - File size checks, structure validation, quality warnings
5. **Summary Reporting Phase** - Stage-by-stage results with success/failure counts, verification warnings

### Converting FROM Markdown
1. **Discover** all Markdown (.md) files in the input directory
2. **Check PDF Engine** (Typst or XeLaTeX for PDF generation)
3. **Convert** to both formats using Pandoc:
   - Markdown → DOCX (excellent quality, 95%+ preservation)
   - Markdown → PDF (with Typst or XeLaTeX engine)
4. **Embed images** automatically from relative paths
5. **Validate** and report conversion results

## Output Structure

```
output_directory/
├── file1.md
├── file2.md
├── ...
├── images/
│   ├── file1/
│   │   ├── image1.png
│   │   └── image2.jpg
│   └── file2/
│       └── diagram.png
└── conversion.log
```

### Conversion Log Details

**Standard Mode**: Basic conversion log with tool usage and results

**Orchestration Mode**: Comprehensive log with:
- Tool detection phase with version reporting
- Tool selection phase with quality indicators (HIGH/MEDIUM/FAST)
- Per-file conversion status with automatic fallback attempts
- Verification phase with file size/structure checks
- Summary reporting with stage-by-stage success/failure counts
- Timestamped entries for long-running conversions

## Task

I need you to invoke the doc-converter agent to batch convert Word and PDF files to Markdown.

### Input Parameters

- **Input Directory**: `{arg1}` (or current directory if not specified)
- **Output Directory**: `{arg2}` (or `./markdown_output` if not specified)

### Agent Invocation

Use the Task tool to invoke a general-purpose agent with doc-converter behavioral guidelines:

```
Task {
  subagent_type: "general-purpose"
  description: "Convert documents to Markdown"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-converter.md

    You are acting as a Document Conversion Agent with the tools and
    constraints defined in that file.

    Convert documents with automatic direction detection and intelligent tool selection:
    - Input directory: {input_directory}
    - Output directory: {output_directory}
    - Direction: Auto-detect from file extensions
      - .docx/.pdf files → Convert TO Markdown
      - .md files → Convert TO PDF and DOCX
    - Tool Selection: Use best available converters (see agent guidelines)
      - DOCX: MarkItDown (primary) → Pandoc (fallback)
      - PDF: marker-pdf (primary) → PyMuPDF4LLM (fallback)
    - Extract/embed images: Yes (when applicable)
    - Validate conversions: Yes
    - Generate conversion log with tool usage: Yes
    - Orchestration mode: {orchestration_mode}
      - If user requests "detailed logging", "quality reporting", "verify tools",
        "orchestrated workflow", or similar quality-critical keywords, enable
        orchestration mode with 5-phase workflow (see agent guidelines)
      - Otherwise use standard conversion workflow

    Follow the conversion workflow defined in the agent guidelines:
    1. Tool Detection phase - Identify available converters with version reporting
    2. Discovery phase - Detect file types and conversion direction
    3. Tool Selection phase - Report selected tools with quality indicators (if orchestration mode)
    4. Conversion phase - Process with best available tools, automatic fallback retry
    5. Validation phase - Check output quality, file sizes, structure (if orchestration mode)
    6. Reporting phase - Provide detailed statistics with tool usage and verification results

    Use PROGRESS markers to provide real-time updates during batch conversion.

    After conversion completes, provide:
    - Conversion statistics (succeeded/failed by type)
    - List of any failed conversions with reasons
    - Location of output files and images
    - Quality warnings or recommendations
}
```

### Expected Output

The agent will provide:
- Real-time progress updates during conversion
- Detailed conversion statistics
- List of any failures with diagnostic information
- Paths to output files
- Quality validation results
- Next steps recommendations

### Error Handling

If tools are missing, the agent will:
- Detect available tools and select best option
- If primary tool unavailable, use fallback tool
- If no tools available for a format:
  - Report which tools are unavailable
  - Skip conversions for that format
  - Provide installation instructions:
    - MarkItDown: `pip install --user 'markitdown[all]'`
    - marker-pdf: Complex setup (see documentation)
    - PyMuPDF4LLM: `pip install --user pymupdf4llm`
    - Pandoc: System package manager
- Continue processing files that can be converted

### Quality Assurance

The agent performs automatic validation:
- Check for suspiciously small output files
- Count headings and tables
- Verify image references
- Report any quality concerns

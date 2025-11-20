# Document Conversion Guide

Complete guide for bidirectional document conversion using the `/convert-docs` command. Convert between DOCX, PDF, and Markdown formats with intelligent tool selection and automatic fallback.

## Quick Start

The simplest way to use `/convert-docs` is with natural language:

```bash
# Convert a single Markdown file to PDF
/convert-docs ./my-document.md to pdf

# Convert a Markdown file to Word format
/convert-docs ./notes.md to docx

# Convert all Word and PDF files in a directory to Markdown
/convert-docs ./reports

# Convert all Markdown files to both PDF and DOCX
/convert-docs ./markdown-docs to pdf and docx

# Convert with custom output location
/convert-docs ./source-files ./output-folder
```

That's it! The command automatically:
- Detects file types
- Selects the best conversion tools
- Handles fallback if tools fail
- Preserves formatting and structure
- Extracts/embeds images

## Tool Architecture

Understanding which tools are used helps you get the best results:

### DOCX → Markdown

**Primary Tool: MarkItDown** (75-80% fidelity)
- Excellent table preservation (pipe-style)
- Perfect Unicode/emoji support
- Fast processing
- Zero configuration

**Fallback Tool: Pandoc** (68% fidelity)
- Reliable baseline conversion
- Good heading/list preservation
- Grid-style tables (more verbose)
- Wide compatibility

### PDF → Markdown

**Primary Tool: MarkItDown**
- Handles most PDF formats well
- Consistent quality
- Easy installation
- Integrated with DOCX conversion

**Backup Tool: PyMuPDF4LLM** (fast, lightweight)
- Zero configuration required
- Perfect Unicode preservation
- Extremely fast (<5s for large files)
- Good for simple text-based PDFs

### Markdown → DOCX

**Tool: Pandoc** (95%+ quality)
- Excellent preservation of structure
- Automatic image embedding
- Professional formatting
- Industry-standard output

### Markdown → PDF

**Primary: Pandoc with Typst engine**
- Modern, fast PDF generation
- Excellent Unicode support
- Clean, professional output

**Fallback: Pandoc with XeLaTeX engine**
- Traditional LaTeX engine
- Good Unicode support
- Widely available

### How Tool Selection Works

The command automatically:
1. **Tries primary tool** for the file type
2. **Falls back** to backup tool if primary fails or times out
3. **Logs which tool** succeeded for each file
4. **Reports statistics** showing tool usage

You don't need to specify tools - it handles everything automatically!

### Installation

Install the tools you need:

```bash
# Minimum setup (handles all conversions)
pip install --user 'markitdown[all]'
sudo apt install pandoc  # or your package manager

# Recommended additions
pip install --user pymupdf4llm  # PDF backup
nix-env -iA nixpkgs.typst       # Modern PDF engine
```

**Check what's installed**:
```bash
/convert-docs --detect-tools
```

## Command Syntax

### Basic Form

```bash
/convert-docs <input> [output] [options]
```

**Parameters**:
- `input` (required): File or directory to convert
- `output` (optional): Where to save converted files (default: `./converted_output`)
- `options` (optional): Flags like `--parallel`, `--use-agent`, `--dry-run`

### Natural Language Support

The command understands natural language:

```bash
# Convert single file to specific format
/convert-docs ./document.md to pdf
/convert-docs ./notes.md to word

# Convert directory
/convert-docs ./my-documents
/convert-docs ./pdfs to markdown

# Specify output location
/convert-docs ./source ./output
```

### Options

**`--use-agent`** - Enable comprehensive 5-phase workflow:
```bash
/convert-docs ./docs ./output --use-agent
```
Provides detailed logging, validation, and quality reporting.

**`--parallel [N]`** - Process files in parallel:
```bash
/convert-docs ./archive ./output --parallel 8
```
Processes N files simultaneously (default: auto-detect CPU cores).

**`--detect-tools`** - Show available tools:
```bash
/convert-docs --detect-tools
```
Displays which conversion tools are installed.

**`--dry-run`** - Preview without converting:
```bash
/convert-docs ./documents --dry-run
```
Shows what would be converted without doing conversions.

## Conversion Modes

The `/convert-docs` command supports two execution modes:

### Script Mode (Default)

Fast, direct conversion with minimal overhead:

```bash
/convert-docs ./documents ./output
```

**Features**:
- Speed: <0.5s overhead, instant start
- Automatic tool selection and fallback
- Progress indicators `[N/Total]`
- Conversion log with statistics
- Parallel processing support

**Use for**:
- Quick batch conversions
- Large file collections
- Standard conversion workflows

### Agent Mode (--use-agent)

Comprehensive 5-phase orchestration with detailed logging:

```bash
/convert-docs ./documents ./output --use-agent
```

**Features**:
- Speed: ~2-3s agent initialization overhead
- Structured logging with phase-by-phase reporting
- Quality validation and verification
- Tool selection explanations
- Structure analysis (heading/table counts)

**Use for**:
- Quality-critical conversions
- Auditing and compliance
- Troubleshooting conversion issues
- Learning which tools work best

**Automatic Agent Triggers**:
Agent mode activates automatically if you include these keywords:
- "detailed logging"
- "quality reporting"
- "verify tools"
- "orchestrated workflow"
- "comprehensive logging"

## Usage Examples

### Basic Conversions

#### Convert Single File to PDF

```bash
/convert-docs ./my-notes.md to pdf
```

Output: `./converted_output/my-notes.pdf`

#### Convert Single File to Word

```bash
/convert-docs ./documentation.md to docx
```

Output: `./converted_output/documentation.docx`

#### Convert All Documents in Directory

```bash
/convert-docs ./my-documents
```

Automatically converts:
- All `.docx` files → `.md` files
- All `.pdf` files → `.md` files
- All `.md` files → `.pdf` and `.docx` files

#### Convert with Custom Output Location

```bash
/convert-docs ./source-docs ./markdown-output
```

Keeps source and output separate.

### Advanced Conversions

#### Quality-Critical with Agent Mode

Use comprehensive logging and validation:

```bash
/convert-docs ./important-docs ./output with detailed logging
```

Agent mode activates, provides:
- Tool detection and version reporting
- Tool selection reasoning
- Per-file validation
- Quality warnings

#### Parallel Processing

Convert large collections quickly:

```bash
/convert-docs ./archive ./output --parallel 8
```

Processes 8 files simultaneously using worker pool.

#### Dry Run Preview

See what would be converted:

```bash
/convert-docs ./documents --dry-run
```

Shows file counts and conversion direction without converting.

#### Check Available Tools

Verify conversion tools installed:

```bash
/convert-docs --detect-tools
```

Displays tool availability and selected converters.

### Real-World Scenarios

#### Scenario 1: Legacy Documentation Migration

Convert old Word docs to Markdown for version control:

```bash
/convert-docs ~/legacy-docs ~/docs-markdown
```

Result:
- All `.docx` files → `.md` files
- Images extracted to `images/` subdirectory
- Preserves heading structure and formatting

#### Scenario 2: Research Paper Collection

Convert PDF papers to Markdown for indexing:

```bash
/convert-docs ~/research/pdfs ~/research/markdown --parallel 4
```

Result:
- Fast parallel processing
- Text extracted from PDFs
- Tables and structure preserved
- Ready for full-text search

#### Scenario 3: Documentation Distribution

Convert Markdown docs to distributable formats:

```bash
/convert-docs ./project-docs ./release-docs
```

Result:
- Each `.md` → `.docx` and `.pdf`
- Professional formatting
- Images embedded automatically
- Ready for stakeholder distribution

#### Scenario 4: Meeting Notes Archive

Convert scattered DOCX meeting notes:

```bash
/convert-docs ~/meetings/2024 ~/meetings/markdown
```

Result:
- Unified Markdown format
- Searchable archive
- Version control ready
- Preserves all text and structure

#### Scenario 5: Blog Post Distribution

Convert Markdown blog posts to PDF:

```bash
/convert-docs ~/blog/posts ~/blog/pdfs to pdf
```

Result:
- Professional PDF versions of blog posts
- Ready for download/distribution
- Embedded images and formatting

## Quality Expectations

### DOCX → Markdown Quality

**MarkItDown (Primary)**:
- Fidelity: 75-80%
- Excellent: Tables (pipe-style), headings, lists
- Good: Text formatting (bold, italic, code)
- Preserved: Unicode, emoji, links
- Limitations: Custom Word styles may not translate

**Pandoc (Fallback)**:
- Fidelity: 68%
- Excellent: Headings, lists, basic formatting
- Good: Tables (grid format), text styling
- Preserved: Links, basic structure
- Limitations: Tables more verbose than pipe-style

### PDF → Markdown Quality

**MarkItDown (Primary)**:
- Quality: Good to excellent for most PDFs
- Best for: Text-based PDFs, standard layouts
- Handles: Tables, headings, basic structure
- Limitations: Complex multi-column layouts

**PyMuPDF4LLM (Backup)**:
- Quality: Fast, moderate fidelity
- Speed: Extremely fast (<5s large files)
- Best for: Simple text-based PDFs
- Limitations: Tables become plain text

### Markdown → DOCX Quality

**Pandoc**:
- Quality: 95%+ preservation
- Excellent: All standard Markdown elements
- Perfect: Headings, lists, tables, links
- Automatic: Image embedding from relative paths
- Limitations: Custom HTML may not convert

### Markdown → PDF Quality

**Typst Engine (Recommended)**:
- Quality: Excellent, modern output
- Excellent: Unicode, emoji, special characters
- Professional: Clean formatting, good typography
- Fast: Quick generation

**XeLaTeX Engine (Fallback)**:
- Quality: Good, traditional LaTeX output
- Good: Unicode support
- Reliable: Established, predictable
- Slower: Traditional LaTeX compilation

### Elements Preserved Across Conversions

**Well-Preserved**:
- Headings (H1-H6 hierarchy)
- Ordered and unordered lists
- Basic text formatting (bold, italic)
- Links and hyperlinks
- Simple tables
- Images (extracted or embedded)
- Code blocks

**May Require Review**:
- Complex multi-level tables
- Custom formatting and styles
- Embedded objects (charts, diagrams)
- Advanced typography
- Custom HTML or LaTeX

**Not Preserved**:
- Document metadata (except basic)
- Comments and track changes
- Macros and scripts
- Custom fonts (simplified)
- Complex page layouts

## Advanced Features

### Parallel Processing

Speed up large batch conversions:

```bash
/convert-docs ./archive ./output --parallel 8
```

**How it works**:
- Creates worker pool with N workers
- Processes N files simultaneously
- Thread-safe progress tracking
- Atomic logging with locks
- Automatic worker cleanup

**When to use**:
- Large file collections (>50 files)
- Fast storage (SSD)
- Multi-core CPU available

**Performance**:
- 2-4x faster for I/O-bound conversions
- Scales with CPU cores (up to 32 workers)
- Automatic CPU core detection if N not specified

### Timeout Protection

All conversions have configurable timeouts:

**Default Timeouts**:
- DOCX → MD: 60 seconds
- PDF → MD: 300 seconds (5 minutes)
- MD → DOCX: 60 seconds
- MD → PDF: 120 seconds (2 minutes)

**Timeout Multiplier**:
Adjust globally via environment variable:

```bash
TIMEOUT_MULTIPLIER=2.0 /convert-docs ./docs ./output
```

Doubles all timeouts (useful for very large files).

**Behavior**:
- On timeout: Automatically try fallback tool
- Logged: Timeout events tracked in statistics
- Continued: Processing continues to next file

### Resource Management

#### Disk Space Checking

Automatic disk space verification:

```bash
MAX_DISK_USAGE_GB=10 /convert-docs ./docs ./output
```

Warns if estimated output exceeds limit.

**Checks**:
- Available disk space
- Estimated output size (input × 1.5)
- Minimum free space buffer (100MB)

#### Concurrency Protection

Prevents multiple conversions to same directory:

**Mechanism**:
- Creates `.convert-docs.lock` file with PID
- Checks if process still running
- Removes stale locks automatically
- Prevents race conditions

**Behavior**:
- Error if another conversion active
- Automatic cleanup on exit
- Manual removal instructions if needed

### Logging and Validation

#### Conversion Log

Every conversion generates `conversion.log`:

**Location**: `<output-directory>/conversion.log`

**Contents**:
- Timestamp and metadata
- Tool detection results
- Per-file conversion attempts
- Success/failure status
- Tool used for each file
- Error messages
- Summary statistics

**Example Log Entry**:
```
[2025-10-12 14:32:15] START: research_paper.pdf -> markdown
[2025-10-12 14:32:18] SUCCESS: research_paper.pdf
  Tool: markitdown
  Output: research_paper.md
  Size: 45123 bytes
  Duration: 2847ms
```

#### File Validation

Automatic validation of input and output files:

**Input Validation**:
- Magic number verification (file type check)
- File size validation (not empty, not too large)
- Read permission check
- DOCX: ZIP format verification
- PDF: PDF header verification
- Markdown: Text file validation

**Output Validation**:
- File existence check
- Size validation (>100 bytes)
- Structure check (heading count, table count)
- Image reference validation
- Warnings for suspicious outputs

#### Progress Tracking

Real-time progress indicators:

**Script Mode**:
```
[3/15] Processing DOCX file
  Converting: meeting_notes.docx (MarkItDown)
    ✓ Converted to meeting_notes.md (using markitdown)
```

**Agent Mode**:
```
PROGRESS: Converting DOCX (3 of 15): meeting_notes.docx...
PROGRESS: Validating conversions...
PROGRESS: Conversion complete: 14 succeeded, 1 failed
```

## Implementation Details

The command delegates to two implementation layers:

### Layer 1: convert-core.sh Script

Core conversion engine (`/home/benjamin/.config/.claude/lib/convert/convert-core.sh`)

**Responsibilities**:
- Tool detection and validation
- File discovery and validation
- Conversion execution with timeout protection
- Automatic fallback handling
- Progress tracking
- Logging and statistics
- Resource management (disk space, locking)

**Key Features**:
- Thread-safe logging with atomic locks
- Parallel processing with worker pools
- Timeout protection (configurable)
- Output filename collision resolution
- Magic number validation (file type verification)
- Graceful degradation when tools missing

**Usage** (direct script invocation):
```bash
bash .claude/lib/convert/convert-core.sh ~/docs ~/output
bash .claude/lib/convert/convert-core.sh ~/docs ~/output --parallel 4
bash .claude/lib/convert/convert-core.sh --detect-tools
```

### Layer 2: doc-converter Agent

AI-powered conversion orchestrator when agent mode enabled

**Responsibilities** (5-Phase Workflow):
1. **Tool Detection Phase**: Report tool versions and availability
2. **Tool Selection Phase**: Explain tool choice with quality indicators
3. **Conversion Phase**: Execute conversions with detailed logging
4. **Verification Phase**: Validate output and structure
5. **Summary Phase**: Generate comprehensive statistics

**Agent Definition**: `/home/benjamin/.config/.claude/agents/doc-converter.md`

**Allowed Tools**: Read, Grep, Glob, Bash, Write

**When Invoked**:
- User includes `--use-agent` flag
- User includes orchestration keywords in request
- Quality-critical conversions requiring audit trails

## Troubleshooting

### Common Issues

#### No Tools Available

**Symptom**: "No converter available" error

**Solution**: Install conversion tools:
```bash
# Minimum setup (handles everything)
pip install --user 'markitdown[all]'

# Add fallback tools
pip install --user pymupdf4llm
sudo apt install pandoc  # or system package manager
```

#### Conversion Fails

**Symptom**: Individual files fail to convert

**Possible Causes**:
1. Corrupted source file
2. Password-protected PDF
3. Unsupported file format
4. Permission denied

**Debugging**:
```bash
# Check file validity
file document.pdf
file document.docx

# Try with agent mode for detailed logging
/convert-docs ./problem-file ./output --use-agent
```

Check `conversion.log` for specific error messages.

#### Poor Quality Output

**Symptom**: Converted Markdown has issues

**For DOCX**:
- Check: Does source use custom styles?
- Try: Use standard Word heading styles
- Fallback: Pandoc may handle differently

**For PDF**:
- Check: Is PDF text-based or scanned?
- Try: PyMuPDF4LLM backup for simple PDFs
- Limitation: Complex layouts need manual review

**For Markdown → DOCX/PDF**:
- Check: Does Markdown use standard syntax?
- Avoid: Custom HTML blocks
- Use: CommonMark or GitHub Flavored Markdown

#### Missing Images

**Symptom**: Images don't appear in converted Markdown

**Check**:
1. Look in `images/` subdirectory of output directory
2. Verify image links in Markdown point to correct paths
3. Ensure source file actually has embedded images

**For Markdown → DOCX/PDF**:
- Use relative image paths: `./images/diagram.png`
- Ensure images exist at those paths
- Pandoc automatically embeds relative images

#### Timeout Errors

**Symptom**: Conversion times out on large files

**Solutions**:
```bash
# Increase timeout multiplier
TIMEOUT_MULTIPLIER=3.0 /convert-docs ./docs ./output

# Use parallel processing (may help with batch)
/convert-docs ./docs ./output --parallel 4

# Process individually
/convert-docs ./single-large-file ./output
```

#### Lock File Error

**Symptom**: "Another conversion is already running"

**Check**:
```bash
# See if conversion actually running
ps aux | grep convert-docs

# If no process, remove stale lock
rm <output-directory>/.convert-docs.lock
```

### Getting Help

#### Verbose Output

Use agent mode for detailed diagnostics:

```bash
/convert-docs ./problem-files ./output with detailed logging
```

Reviews:
- Exact tool versions
- Tool selection reasoning
- Per-file conversion attempts
- Validation results
- Quality warnings

#### Check Tool Availability

Verify all tools installed:

```bash
/convert-docs --detect-tools
```

Shows which tools are available and which are missing.

#### Dry Run Analysis

Preview conversion without executing:

```bash
/convert-docs ./documents --dry-run
```

Shows:
- Files that would be converted
- File counts by type
- Conversion direction
- No actual conversion

## Best Practices

### For Best Results

**1. Use Standard Formatting**:
- DOCX: Use built-in heading styles
- PDF: Prefer text-based over scanned
- Markdown: Stick to CommonMark syntax

**2. Test First**:
- Convert a few sample files
- Verify quality meets needs
- Adjust workflow as needed

**3. Keep Originals**:
- Source files never deleted
- Can re-convert with different settings
- Safe to experiment

**4. Review Output**:
- Spot-check converted files
- Verify critical elements preserved
- Manual cleanup if needed for complex documents

**5. Use Appropriate Mode**:
- Script mode: Fast batch conversions
- Agent mode: Quality-critical, auditing, troubleshooting

### Workflow Recommendations

**Documentation Migration**:
```bash
# 1. Test sample
/convert-docs ./sample-docs ./test-output

# 2. Review quality
ls -lh ./test-output
cat ./test-output/sample.md

# 3. Batch convert
/convert-docs ./all-docs ./markdown-output --parallel 8

# 4. Version control
cd ./markdown-output
git init
git add .
git commit -m "Initial markdown migration"
```

**Distribution Workflow**:
```bash
# 1. Create Markdown source
nvim ./docs/user-guide.md

# 2. Generate distributable formats
/convert-docs ./docs/user-guide.md to pdf and docx

# 3. Verify PDF quality
xdg-open ./converted_output/user-guide.pdf

# 4. Distribute
cp ./converted_output/user-guide.* ~/shared/
```

## Navigation

### Related Documentation
- [Command Reference](../../commands/convert-docs.md) - `/convert-docs` command specification
- [Agent Definition](../../agents/doc-converter.md) - `doc-converter` agent details
- [Script Implementation](../../lib/convert/convert-core.sh) - Core conversion engine

### Tool Documentation
- [MarkItDown](https://github.com/microsoft/markitdown) - Primary conversion tool
- [Pandoc Manual](https://pandoc.org/MANUAL.html) - Universal document converter
- [PyMuPDF4LLM](https://github.com/pymupdf/PyMuPDF) - Fast PDF library
- [Typst](https://typst.app/) - Modern PDF generation

### Parent Directory
- [← Documentation Index](./README.md)

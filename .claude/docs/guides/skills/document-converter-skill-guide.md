# Document Converter Skill Guide

Complete guide for using the document-converter skill in Claude Code workflows.

## Overview

The `document-converter` skill enables seamless document conversion between Markdown, DOCX, and PDF formats. It's designed to be automatically invoked by Claude when document conversion needs are detected, or explicitly called via the `/convert-docs` command.

**Key Features**:
- Autonomous invocation (Claude detects when needed)
- Bidirectional conversion (Markdown ↔ DOCX/PDF)
- Intelligent tool selection with fallback mechanisms
- Batch processing with concurrent conversion support
- Quality validation and comprehensive reporting

## Architecture

### Skills-Based Pattern

The document-converter follows Claude Code's skills architecture pattern:

**Skills vs Commands**:
- **Skills**: Autonomous, model-invoked capabilities (Claude decides when to use)
- **Commands**: User-invoked shortcuts (explicit `/convert-docs` call)

**Integration Points**:
1. **Autonomous**: Claude auto-invokes skill when analyzing PDFs or generating documents
2. **Command**: `/convert-docs` delegates to skill when available
3. **Agent**: `doc-converter` agent auto-loads skill via `skills:` field

### Directory Structure

```
.claude/skills/document-converter/
├── SKILL.md                    # Core skill definition (metadata + instructions)
├── reference.md                # Technical reference and API docs
├── examples.md                 # Usage examples and patterns
├── scripts/                    # Conversion scripts (symlinks to lib/convert/)
│   ├── convert-core.sh        # Main orchestration
│   ├── convert-docx.sh        # DOCX conversion functions
│   ├── convert-pdf.sh         # PDF conversion functions
│   └── convert-markdown.sh    # Markdown utilities
└── templates/
    └── batch-conversion.sh    # Batch processing template
```

## Usage

### Automatic Invocation

The skill automatically triggers when Claude detects conversion needs:

**Example 1 - PDF Analysis**:
```
User: "Analyze the research papers in ./pdfs/"

Claude: [Detects PDFs need text extraction]
        [Invokes document-converter skill automatically]
        [Converts PDFs to Markdown]
        [Analyzes extracted text]
```

**Example 2 - Documentation Generation**:
```
User: "Create a Word document from README.md"

Claude: [Detects Markdown → DOCX conversion need]
        [Invokes document-converter skill]
        [Generates README.docx]
```

### Explicit Command Usage

Use `/convert-docs` for explicit conversion:

```bash
# Standard conversion (delegates to skill if available)
/convert-docs ./documents ./output

# Agent mode (comprehensive workflow)
/convert-docs ./documents ./output --use-agent

# With detailed logging
/convert-docs ./documents ./output with detailed logging
```

**Mode Selection**:
- **Skill Mode** (new): When skill available and script mode detected
- **Script Mode** (legacy): Direct script invocation when skill unavailable
- **Agent Mode**: Comprehensive 5-phase workflow with validation

### Programmatic Usage

Source the skill's conversion scripts directly:

```bash
# Source conversion core
source ~/.config/.claude/skills/document-converter/scripts/convert-core.sh

# Detect tools
detect_tools

# Convert files
main_conversion ./input ./output
```

## Tool Selection

The skill uses intelligent tool selection based on format and availability:

### DOCX → Markdown

1. **MarkItDown** (primary) - 75-80% fidelity
   - Perfect table preservation (pipe-style)
   - Excellent Unicode support
   - Fast processing
2. **Pandoc** (fallback) - 68% fidelity
   - Reliable baseline
   - Grid-style tables (verbose)

### PDF → Markdown

1. **MarkItDown** (primary) - Best for most PDFs
   - Consistent quality
   - Easy configuration
2. **PyMuPDF4LLM** (fallback) - Fast alternative
   - Zero configuration
   - Lightweight

### Markdown → DOCX

1. **Pandoc** (only option) - 95%+ quality
   - Excellent formatting preservation

### Markdown → PDF

1. **Pandoc + Typst** (primary) - Fast, modern
2. **Pandoc + XeLaTeX** (fallback) - Traditional LaTeX

### Tool Detection

The skill automatically detects available tools:

```bash
detect_tools  # Sets flags: MARKITDOWN_AVAILABLE, PANDOC_AVAILABLE, etc.
```

**Installation**:
```bash
# MarkItDown (recommended)
pip install markitdown

# PyMuPDF4LLM (optional)
pip install pymupdf4llm

# Pandoc (required for Markdown → DOCX/PDF)
apt install pandoc  # Ubuntu/Debian
brew install pandoc  # macOS

# Typst (optional, for faster PDF generation)
brew install typst  # macOS
```

## Conversion Workflow

### 5-Phase Process

1. **Tool Detection**
   - Check for MarkItDown, Pandoc, PyMuPDF4LLM, Typst, XeLaTeX
   - Set availability flags for tool selection

2. **File Discovery**
   - Scan input directory for convertible files
   - Detect conversion direction (TO_MARKDOWN or FROM_MARKDOWN)
   - Validate no mixed-mode errors

3. **Conversion Execution**
   - Process files using optimal tool based on priority matrix
   - Apply timeout limits (60s DOCX, 300s PDF, 120s MD→PDF)
   - Handle collisions (overwrite or skip existing files)
   - Retry with fallback tools on failure

4. **Validation**
   - Verify output file exists
   - Check for broken image links
   - Validate document structure (headings present)
   - Report quality issues

5. **Reporting**
   - Generate conversion.log with statistics
   - Report success/failure counts by format
   - List timeout occurrences
   - Summarize validation issues

## Configuration

### Environment Variables

Customize conversion behavior:

```bash
# Timeout multiplier
export TIMEOUT_MULTIPLIER=1.5  # Increase all timeouts by 50%

# Disk usage limits
export MAX_DISK_USAGE_GB=10    # Abort if output exceeds 10GB
export MIN_FREE_SPACE_MB=100   # Require 100MB free space

# Concurrency
export MAX_CONCURRENT_CONVERSIONS=4  # Parallel conversion limit
```

### Batch Processing Template

Use the provided template for custom workflows:

```bash
# Basic usage
./templates/batch-conversion.sh ./input ./output

# With custom options
./templates/batch-conversion.sh ./input ./output \
  --timeout-multiplier 2.0 \
  --concurrent 8 \
  --max-disk-gb 10
```

## Quality Expectations

### Fidelity Metrics

Based on comprehensive testing:

| Source → Target | Tool | Fidelity | Speed |
|-----------------|------|----------|-------|
| DOCX → Markdown | MarkItDown | 75-80% | Fast |
| DOCX → Markdown | Pandoc | 68% | Fast |
| PDF → Markdown | MarkItDown | 70-85% | Fast |
| PDF → Markdown | PyMuPDF4LLM | 65-75% | Very Fast |
| Markdown → DOCX | Pandoc | 95%+ | Fast |
| Markdown → PDF | Pandoc+Typst | 98%+ | Very Fast |
| Markdown → PDF | Pandoc+XeLaTeX | 98%+ | Slower |

**Fidelity Scoring**:
- Heading structure (20%)
- List formatting (15%)
- Table structure (25%)
- Bold/italic (10%)
- Links (10%)
- Images (10%)
- Unicode (10%)

### Known Limitations

- **Scanned PDFs**: OCR quality depends on scan resolution
- **Complex layouts**: Multi-column or nested tables may degrade
- **Embedded fonts**: PDF fonts may affect text extraction
- **Large images**: May cause timeout issues

## Integration Examples

### With Other Skills

Skills can compose automatically:

```yaml
# research-specialist skill
dependencies:
  - document-converter  # Auto-loads for PDF analysis
```

**Workflow**:
```
User: "Research machine learning papers in ./pdfs/"

Claude: [Loads research-specialist skill]
        [Detects dependency on document-converter]
        [Auto-loads document-converter skill]
        [Converts PDFs to Markdown]
        [Analyzes extracted content]
        [Generates research report]
```

### With Agents

The `doc-converter` agent auto-loads the skill:

```yaml
# .claude/agents/doc-converter.md
---
skills: document-converter
---
```

**Invocation**:
```bash
/convert-docs ./documents ./output --use-agent
→ Invokes doc-converter agent
→ Agent loads document-converter skill
→ Delegates conversion to skill
→ Provides orchestration and validation
```

### In Research Workflows

Seamless integration with research tasks:

```
User: "Create a summary of the financial reports in ./pdfs/"

Claude: [Analyzes request]
        [Detects PDF analysis need]
        [Invokes document-converter skill to extract text]
        [Analyzes extracted financial data]
        [Generates summary document]
        [Optionally converts summary to DOCX via skill]
```

## Troubleshooting

### Skill Not Triggering

**Symptom**: Skill doesn't auto-invoke when expected.

**Diagnosis**:
1. Check skill is in `.claude/skills/document-converter/`
2. Verify SKILL.md exists with valid YAML frontmatter
3. Check description includes trigger keywords

**Solution**:
```bash
# Verify skill exists
ls ~/.config/.claude/skills/document-converter/SKILL.md

# Validate YAML
python3 -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"

# Test explicit invocation
"Use document-converter skill to convert ./test.docx"
```

### Tool Installation Issues

**Symptom**: "No conversion tool available" error.

**Diagnosis**:
```bash
# Check tool availability
command -v markitdown
command -v pandoc
python3 -c "import pymupdf4llm"
```

**Solution**:
```bash
# Install MarkItDown
pip install --user markitdown

# Install Pandoc
apt install pandoc  # Ubuntu/Debian
brew install pandoc  # macOS

# Install PyMuPDF4LLM (optional)
pip install --user pymupdf4llm
```

### Conversion Timeout

**Symptom**: "Conversion timeout after Ns" error.

**Diagnosis**: File too large or complex for default timeout.

**Solution**:
```bash
# Increase timeout multiplier
export TIMEOUT_MULTIPLIER=2.0

# Or increase specific timeout
export TIMEOUT_PDF_TO_MD=600  # 10 minutes for large PDFs
```

### Poor Conversion Quality

**Symptom**: Tables or formatting incorrect in output.

**Diagnosis**: Tool-specific formatting differences or PDF complexity.

**Solution**:
- **Tables**: Use MarkItDown for pipe-style (better for GFM)
- **Scanned PDFs**: Install OCR support (`pip install markitdown[ocr]`)
- **Complex layouts**: Try alternate tool (PyMuPDF4LLM for PDFs)
- **Manual review**: Check conversion.log for warnings

### Batch Conversion Hangs

**Symptom**: Conversion process stalls during batch processing.

**Diagnosis**: Concurrent conversion deadlock or timeout.

**Solution**:
```bash
# Reduce concurrency
export MAX_CONCURRENT_CONVERSIONS=1

# Increase timeouts
export TIMEOUT_MULTIPLIER=3.0

# Re-run conversion
/convert-docs ./documents ./output
```

## Performance Optimization

### Concurrency Tuning

Match CPU core count for optimal throughput:

```bash
# Low-powered system
export MAX_CONCURRENT_CONVERSIONS=2

# High-powered system (8+ cores)
export MAX_CONCURRENT_CONVERSIONS=8
```

**Benchmarks** (typical):
- 1 concurrent: Sequential processing (baseline)
- 4 concurrent: ~3x speedup for I/O-bound conversions
- 8 concurrent: Diminishing returns beyond 4-8 (disk I/O bottleneck)

### Timeout Optimization

Adjust timeouts based on file characteristics:

```bash
# Small documents (< 1MB)
export TIMEOUT_MULTIPLIER=0.5  # Faster failures

# Large scanned PDFs (> 10MB)
export TIMEOUT_MULTIPLIER=3.0  # Allow more time for OCR
```

### Tool Selection

Choose tools based on use case:

- **Speed**: PyMuPDF4LLM for PDFs (fastest)
- **Quality**: MarkItDown for DOCX/PDF (best tables)
- **Reliability**: Pandoc (universal fallback)

## Migration Guide

### From Legacy Command

**Before** (direct command):
```bash
/convert-docs ./documents ./output
→ Invokes script mode directly
```

**After** (skill-based):
```bash
/convert-docs ./documents ./output
→ Checks for skill availability
→ Delegates to document-converter skill
→ Falls back to script mode if skill unavailable
```

**Benefits**:
- Automatic skill discovery
- Composition with other skills
- Unified conversion interface

### Backward Compatibility

The `/convert-docs` command uses agent-first architecture:

```
STEP 1: Environment initialization and error logging
↓
STEP 2: Parse arguments (--no-api, --sequential)
↓
STEP 3: Verify input path
↓
STEP 4: Invoke converter agent (agent has skills: document-converter)
↓
STEP 5: Script fallback (if agent fails)
↓
STEP 6: Verification and return
```

**Architecture Benefits**:
- Agent auto-loads skill via `skills:` frontmatter field
- Parallel processing enabled by default
- Script fallback ensures reliability
- No breaking changes to existing workflows

## Best Practices

### When to Use Skill vs Command

**Use Skill (Autonomous)**:
- In agent workflows (research, documentation)
- When Claude detects conversion need
- For seamless integration with other skills

**Use Command (Explicit)**:
```bash
/convert-docs ./documents ./output
```
- Batch processing standalone files
- Explicit user-requested conversions
- Testing and validation

### Optimizing Conversion Quality

1. **Install MarkItDown** (best DOCX/PDF quality)
2. **Use Typst for PDFs** (faster than XeLaTeX)
3. **Review conversion.log** (check warnings)
4. **Validate critical files** (manual spot-check)
5. **Test with samples** (before large batches)

### Managing Large Batch Conversions

1. **Set appropriate timeouts** (longer for scanned PDFs)
2. **Tune concurrency** (match CPU cores, typically 4-8)
3. **Monitor disk space** (set MAX_DISK_USAGE_GB)
4. **Review failures incrementally** (check log periodically)
5. **Resume interrupted conversions** (skill handles partial completion)

## Advanced Usage

### Custom Conversion Pipelines

Extend the skill for custom workflows:

```bash
#!/bin/bash
# custom-workflow.sh - Extract text from PDFs and analyze

source ~/.config/.claude/skills/document-converter/scripts/convert-core.sh

# Convert PDFs to Markdown
main_conversion ./research/pdfs ./research/markdown

# Custom post-processing
for md in ./research/markdown/*.md; do
  # Extract keywords
  grep -E "machine learning|neural network" "$md" > keywords.txt

  # Generate summary
  head -50 "$md" > summary.txt
done
```

### Tool-Specific Optimization

Force specific tools when needed:

```bash
# Use only Pandoc (skip MarkItDown)
source ~/.config/.claude/skills/document-converter/scripts/convert-core.sh

MARKITDOWN_AVAILABLE=false
PANDOC_AVAILABLE=true

main_conversion ./documents ./output
```

**Use Cases**:
- Testing tool-specific output differences
- Working around tool-specific bugs
- Optimizing for specific document types

## Standards Compliance

The document-converter skill follows all project standards:

- **Code Standards**: Output suppression, lazy directory creation, WHAT comments
- **Output Formatting**: Single summary line per bash block, console summaries
- **Command Authoring**: Execution directives, verification checkpoints
- **Documentation Standards**: Clear structure, navigation links, no emojis

## References

### Skill Documentation

- [SKILL.md](../../../skills/document-converter/SKILL.md) - Core skill definition
- [reference.md](../../../skills/document-converter/reference.md) - Technical reference
- [examples.md](../../../skills/document-converter/examples.md) - Usage examples

### Project Documentation

- [Convert-Docs Command Guide](../commands/convert-docs-command-guide.md)
- [Command Authoring Standards](../../reference/standards/command-authoring.md)
- [Code Standards](../../reference/standards/code-standards.md)
- [Directory Organization](../../concepts/directory-organization.md)

### External Documentation

- [Claude Code Skills Guide](https://code.claude.com/docs/en/skills.md)
- [MarkItDown Documentation](https://github.com/microsoft/markitdown)
- [Pandoc Manual](https://pandoc.org/MANUAL.html)
- [PyMuPDF4LLM Repository](https://github.com/pymupdf/PyMuPDF4LLM)

## Changelog

### Version 1.0.0 (2025-11-20)

**New Features**:
- Initial skill release
- Autonomous invocation capability
- Intelligent tool selection with fallback
- Batch processing with concurrent conversions
- Quality validation and comprehensive reporting
- Integration with `/convert-docs` command
- Integration with `doc-converter` agent

**Architecture**:
- Skills-based pattern implementation
- Progressive disclosure (metadata + core instructions < 500 lines)
- Symlink-based script integration (zero duplication)
- Full backward compatibility with existing workflows

**Testing**:
- All existing tests passing
- YAML frontmatter validated
- Symlinks verified
- Tool detection confirmed
- Batch template functional

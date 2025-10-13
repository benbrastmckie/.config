---
command-type: primary
description: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally
argument-hint: <input-directory> [output-directory] [--use-agent]
allowed-tools: Bash, Task, Read
agent-dependencies: doc-converter
---

# Convert Documents - Bidirectional Conversion

Convert between Markdown, Word (DOCX), and PDF formats with automatic direction detection. Uses a fast script for standard conversions or an intelligent agent for complex orchestration workflows.

## Usage

```bash
/convert-docs <input-directory> [output-directory]
/convert-docs <input-directory> [output-directory] --use-agent
/convert-docs <input-directory> [output-directory] with detailed logging
```

## Parameters

- `input-directory` (required): Directory containing files to convert
  - `.docx` or `.pdf` files → Converts TO Markdown
  - `.md` files → Converts TO DOCX (PDF via Pandoc)
- `output-directory` (optional): Where to save converted files (default: `./converted_output`)
- `--use-agent` (optional): Force agent mode for complex orchestration

## Conversion Modes

### Script Mode (Default)

Fast, direct tool invocation for standard conversions:
- **Speed**: <0.5s overhead, instant conversion start
- **Tools**: Same quality tools as agent mode
- **Fallback**: Automatic retry with fallback tools
- **Logging**: Conversion log with statistics
- **Use for**: Most conversions, quick batch processing

### Agent Mode (--use-agent or orchestration keywords)

Comprehensive 5-phase workflow with detailed logging:
- **Speed**: ~2-3s agent initialization overhead
- **Tools**: Same as script mode with adaptive selection
- **Logging**: Structured log with phase-by-phase reporting
- **Validation**: Quality checks, structure analysis, warnings
- **Use for**: Quality-critical conversions, audits, troubleshooting

**Trigger Agent Mode**:
- Add `--use-agent` flag, OR
- Include keywords: "detailed logging", "quality reporting", "verify tools", "orchestrated workflow"

## Examples

### Standard Conversions (Script Mode)

```bash
# Convert DOCX/PDF to Markdown
/convert-docs ~/Documents/Reports

# Convert Markdown to DOCX
/convert-docs ~/notes/md ~/notes/docx

# Specify output directory
/convert-docs ./docs ./converted
```

### Quality-Critical Conversions (Agent Mode)

```bash
# Force agent mode with detailed logging
/convert-docs ./documents ./output with detailed logging

# Batch processing with audit trail
/convert-docs ./pdfs ./markdown with quality reporting and tool verification

# Explicit agent mode flag
/convert-docs ./files ./output --use-agent
```

## Tool Selection

Both modes use the same intelligent tool priority:

### DOCX to Markdown
1. **MarkItDown** (primary) - 75-80% fidelity, perfect table preservation
2. **Pandoc** (fallback) - 68% fidelity

### PDF to Markdown
1. **MarkItDown** (primary) - Handles most PDF formats well
2. **PyMuPDF4LLM** (backup) - Fast, lightweight alternative

### Markdown to DOCX/PDF
- **Pandoc** - 95%+ quality with Typst or XeLaTeX engines

Tools are auto-detected. If primary tool unavailable, fallback is used automatically.

## Output Structure

```
output_directory/
├── file1.md (or .docx)
├── file2.md (or .docx)
├── images/          # When extracting images from DOCX/PDF
│   ├── image1.png
│   └── image2.jpg
└── conversion.log   # Detailed conversion log
```

## What It Does

### Script Mode Workflow

1. **Detect Tools** - Find available converters (MarkItDown, Pandoc, PyMuPDF4LLM)
2. **Discover Files** - Find DOCX, PDF, or MD files; auto-detect conversion direction
3. **Convert Files** - Process each file with progress indicators [N/Total]
   - Use primary tool (MarkItDown for DOCX and PDF)
   - On failure: automatically retry with fallback tool (Pandoc for DOCX, PyMuPDF4LLM for PDF)
   - Log success/failure for each file
4. **Validate** - Check output file sizes and structure
5. **Report** - Display conversion statistics and any failures

### Agent Mode Workflow

All script mode features PLUS:
1. **Tool Detection Phase** - Report versions and availability with quality indicators
2. **Tool Selection Phase** - Explain why each tool was chosen before conversion starts
3. **Conversion Phase** - Detailed per-file logging with automatic fallback attempts
4. **Verification Phase** - Structure validation (heading/table counts), quality warnings
5. **Summary Phase** - Stage-by-stage success/failure breakdown

## Task

Determine conversion mode based on user request, then execute conversion.

### Parse Arguments

```
input_dir = {arg1} or "."
output_dir = {arg2} or "./converted_output"
user_request = full command text
```

### Detect Conversion Mode

Check for agent mode triggers:
- `--use-agent` flag present in arguments
- Orchestration keywords in request: "detailed logging", "quality reporting", "verify tools", "orchestrated workflow", "comprehensive logging"

If agent mode triggered: Use Agent Mode (Task tool)
Otherwise: Use Script Mode (Bash tool)

### Script Mode Execution

Execute the conversion script directly:

```bash
bash /home/benjamin/.config/.claude/lib/convert-docs.sh "{input_dir}" "{output_dir}"
```

The script handles:
- Tool detection and fallback
- File discovery and conversion
- Progress indicators
- Validation and reporting
- Conversion log generation

### Agent Mode Execution

Invoke doc-converter agent via Task tool (see agent guidelines at `/home/benjamin/.config/.claude/agents/doc-converter.md`):

```
Task {
  subagent_type: "general-purpose"
  description: "Convert documents with orchestration"
  prompt: |
    Read and follow behavioral guidelines: /home/benjamin/.config/.claude/agents/doc-converter.md

    Convert documents with 5-phase orchestration workflow:
    - Input: {input_dir}
    - Output: {output_dir}
    - Direction: Auto-detect from file extensions
    - Orchestration mode: ENABLED

    Provide comprehensive logging, validation, and quality reporting.
}
```

### Error Handling

**Script Mode**:
- Missing tools reported with installation guidance
- Failed conversions logged with error details
- Continues processing remaining files
- Shows missing tools report if any failures

**Agent Mode**:
- Detailed tool detection with version reporting
- Explains tool selection decisions
- Per-file failure diagnostics
- Quality warnings and recommendations

## Installation Guidance

If tools are missing:
- **MarkItDown**: `pip install --user 'markitdown[all]'` (recommended, handles both DOCX and PDF)
- **Pandoc**: Use system package manager (apt, brew, pacman, etc.)
- **PyMuPDF4LLM**: `pip install --user pymupdf4llm` (lightweight PDF backup)
- **Typst**: System package manager
- **XeLaTeX**: Install texlive package

Run `/convert-docs --detect-tools` to see current tool availability (script mode only).

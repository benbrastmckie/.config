---
command-type: primary
description: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally
argument-hint: <input-directory> [output-directory] [--no-api] [--sequential]
allowed-tools: Bash, Task, Read
agent-dependencies: doc-converter
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - summary-formatting.sh: ">=1.0.0"
---

# Convert Documents - Bidirectional Conversion

**YOU MUST execute document conversion using agent-first architecture with script fallback.**

**YOUR ROLE**: You are the CONVERSION COORDINATOR.
- **Primary Path**: Invoke doc-converter agent via Task tool
- **Fallback Path**: Only invoke convert-core.sh script if agent fails
- **DO NOT** execute conversion yourself using Read/Write/Bash tools

**EXECUTION ARCHITECTURE**:
- **Default**: Agent invocation with parallel processing enabled
- **Fallback**: Script mode when agent invocation fails
- **Parallel Processing**: Enabled by default (use --sequential to disable)

**CRITICAL INSTRUCTIONS**:
- DO NOT execute conversion logic yourself
- DO NOT skip agent invocation - it is the primary path
- Fallback to script mode ONLY if agent fails to return CONVERSION_COMPLETE signal
- Both modes produce conversion.log and converted files

## Usage

```bash
/convert-docs <input-directory> [output-directory]
/convert-docs <input-directory> [output-directory] --no-api
/convert-docs <input-directory> [output-directory] --sequential
```

## Parameters

- `input-directory` (required): Directory containing files to convert
  - `.docx` or `.pdf` files -> Converts TO Markdown
  - `.md` files -> Converts TO DOCX (PDF via Pandoc)
- `output-directory` (optional): Where to save converted files (default: `./converted_output`)
- `--no-api` (optional): Disable API calls, use local tools only
- `--sequential` (optional): Disable parallel processing (default: parallel enabled)

## Conversion Architecture

The command uses an **agent-first architecture**:

1. **Agent Mode** (default): Invokes doc-converter agent which auto-loads the document-converter skill
2. **Script Fallback**: Falls back to convert-core.sh if agent invocation fails

### Agent Mode (Default)

The doc-converter agent has `skills: document-converter` in its frontmatter:
- Agent automatically receives skill context
- Comprehensive 5-phase workflow with detailed logging
- Quality checks, structure analysis, warnings
- Parallel processing enabled by default

### Script Fallback

If agent invocation fails:
- Direct script invocation via convert-core.sh
- Same quality tools as agent mode
- Automatic retry with fallback tools
- Logging: Conversion log with statistics

## Tool Selection

Both modes use the same intelligent tool priority:

### DOCX to Markdown
1. **MarkItDown** (primary) - 75-80% fidelity, perfect table preservation
2. **Pandoc** (fallback) - 68% fidelity

### PDF to Markdown
1. **Gemini API** (default with API key) - 95%+ fidelity
2. **PyMuPDF4LLM** (backup/offline) - 70-75% fidelity
3. **MarkItDown** (fallback) - 65-70% fidelity

### Markdown to DOCX/PDF
- **Pandoc** - 95%+ quality with Typst or XeLaTeX engines

## Output Structure

```
output_directory/
  file1.md (or .docx)
  file2.md (or .docx)
  images/          # When extracting images from DOCX/PDF
    image1.png
    image2.jpg
  conversion.log   # Detailed conversion log
```

## Task

**EXECUTE NOW**: Follow these steps in EXACT sequential order.

### Block 1 (REQUIRED) - Environment Initialization and Error Logging

**EXECUTE FIRST - Initialize Environment and Error Logging**:

```bash
set +H  # CRITICAL: Disable history expansion

# Defensive initialization of CLAUDE_PROJECT_DIR with fallback detection
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  # Attempt to source unified-location-detection.sh and use detect_project_root
  if [[ -f ".claude/lib/core/unified-location-detection.sh" ]]; then
    source .claude/lib/core/unified-location-detection.sh 2>/dev/null && {
      CLAUDE_PROJECT_DIR="$(detect_project_root)"
    } || {
      # Fallback: Use git root or pwd
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    }
  else
    # Direct fallback if library not found: use git root or pwd
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi

  export CLAUDE_PROJECT_DIR
fi

# Validate CLAUDE_PROJECT_DIR is set and valid
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  echo "CRITICAL ERROR: CLAUDE_PROJECT_DIR not set after initialization"
  exit 1
fi

if [[ ! -d "$CLAUDE_PROJECT_DIR" ]]; then
  echo "CRITICAL ERROR: CLAUDE_PROJECT_DIR points to non-existent directory: $CLAUDE_PROJECT_DIR"
  exit 1
fi

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "CRITICAL ERROR: Cannot load error-handling library"
  echo "   Expected: ${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
  exit 1
}

# Initialize error log
ensure_error_log_exists || {
  echo "CRITICAL ERROR: Cannot initialize error log"
  exit 1
}

# Set workflow metadata
COMMAND_NAME="/convert-docs"
WORKFLOW_ID="convert_docs_$(date +%s)"
USER_ARGS="$*"

# Setup bash error trap for automatic error logging
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Export metadata to environment for delegated scripts
export COMMAND_NAME WORKFLOW_ID USER_ARGS

echo "VERIFIED: Environment initialized (CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR)"
echo "VERIFIED: Error logging initialized (workflow_id=$WORKFLOW_ID)"
```

### Block 2 (REQUIRED) - Parse Arguments

**YOU MUST parse arguments and set defaults**:

```bash
input_dir="${1:-.}"
output_dir="${2:-./converted_output}"
user_request="$*"  # Full command text for flag detection

# Flag defaults
offline_flag=false
parallel_flag=true

# Parse flags
if [[ "$user_request" =~ --no-api ]]; then
  offline_flag=true
fi

if [[ "$user_request" =~ --sequential ]]; then
  parallel_flag=false
fi

# Report parsed values
echo "VERIFIED: input_dir=$input_dir"
echo "VERIFIED: output_dir=$output_dir"
echo "VERIFIED: offline_flag=$offline_flag"
echo "VERIFIED: parallel_flag=$parallel_flag"
```

**MANDATORY VERIFICATION - Arguments Parsed**:
```bash
[[ -z "$input_dir" ]] && echo "ERROR: Input directory not set" && exit 1
[[ -z "$output_dir" ]] && echo "ERROR: Output directory not set" && exit 1
```

### Block 3 (REQUIRED) - Validate Input Path

**EXECUTE NOW - Path Verification**:

```bash
# Verify input directory exists
if [[ ! -d "$input_dir" ]]; then
  echo "CRITICAL ERROR: Input directory does not exist: $input_dir"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Input directory does not exist" \
    "step_3_validation" \
    "$(jq -n --arg dir "$input_dir" '{input_dir: $dir, provided_by_user: true}')"
  exit 1
fi

# Count files to convert
file_count=$(find "$input_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $file_count -eq 0 ]]; then
  echo "CRITICAL ERROR: No convertible files found in $input_dir"
  echo "   Looking for: *.md, *.docx, *.pdf"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "No convertible files found in input directory" \
    "step_3_validation" \
    "$(jq -n --arg dir "$input_dir" --argjson count $file_count --argjson exts '["md", "docx", "pdf"]' '{input_dir: $dir, file_count: $count, expected_extensions: $exts}')"
  exit 1
fi

echo "VERIFIED: Found $file_count files to convert"
```

### Block 4 (REQUIRED) - Invoke Converter Agent

**EXECUTE NOW**: Use Task tool to invoke converter agent with parsed arguments.

**AGENT INVOCATION**: The doc-converter agent has `skills: document-converter` in its frontmatter. The skill context is automatically loaded when the agent is invoked.

```
Task {
  subagent_type: "general-purpose"
  description: "Convert documents from $input_dir to $output_dir"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-converter.md

    YOU MUST convert documents with the document-converter skill workflow.

    REQUIRED PARAMETERS (ALL MANDATORY):
    - Input Directory: $input_dir (ABSOLUTE PATH REQUIRED)
    - Output Directory: $output_dir (ABSOLUTE PATH REQUIRED)
    - Direction: Auto-detect from file extensions (.md -> DOCX, .docx/.pdf -> MD)
    - Offline Mode: $offline_flag (true = use local tools only)
    - Parallel Mode: $parallel_flag (true = parallel processing, false = sequential)
    - File Count: $file_count files to convert

    MANDATORY DELIVERABLES:
    1. Converted files in output directory
    2. conversion.log with per-file results
    3. Quality validation report
    4. Tool selection explanations

    Return signal when complete:
    CONVERSION_COMPLETE: $output_dir ($success_count files converted)
}
```

**CHECKPOINT**: After agent invocation, check for CONVERSION_COMPLETE signal.

```bash
# This verification runs AFTER agent returns
# Check if output directory was created by agent
if [[ -d "$output_dir" ]]; then
  output_count=$(find "$output_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

  if [[ $output_count -gt 0 ]]; then
    echo "VERIFIED: Agent produced $output_count files"
    # Skip to STEP 6 for final summary
  fi
fi
```

### Block 5 (FALLBACK) - Script Mode

**EXECUTE ONLY IF**: Agent invocation in STEP 4 failed or did not return CONVERSION_COMPLETE signal.

**FALLBACK TRIGGER**: If STEP 4 did not produce output files, execute script-based conversion.

```bash
echo "FALLBACK: Agent mode failed or produced no output, using script mode"

# Pre-calculate output directory (absolute path)
OUTPUT_DIR_ABS="$(cd "$(dirname "$output_dir")" 2>/dev/null && pwd)/$(basename "$output_dir")"

# Create output directory if needed
mkdir -p "$OUTPUT_DIR_ABS" || {
  echo "CRITICAL ERROR: Cannot create output directory: $OUTPUT_DIR_ABS"
  exit 1
}

echo "PROGRESS: Output directory: $OUTPUT_DIR_ABS"

# Source the conversion core module and run main function
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" || {
  echo "CRITICAL ERROR: Cannot source convert-core.sh"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source convert-core.sh library" \
    "step_5_fallback" \
    "$(jq -n --arg lib "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" --arg proj "$CLAUDE_PROJECT_DIR" '{lib_path: $lib, CLAUDE_PROJECT_DIR: $proj}')"
  exit 1
}

# Execute conversion with error handling
main_conversion "$input_dir" "$OUTPUT_DIR_ABS"
CONVERSION_EXIT=$?
if [ $CONVERSION_EXIT -ne 0 ]; then
  echo "ERROR: Script mode conversion failed"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "main_conversion function returned non-zero exit code" \
    "step_5_fallback" \
    "$(jq -n --arg input "$input_dir" --arg output "$OUTPUT_DIR_ABS" --argjson exit $CONVERSION_EXIT '{exit_code: $exit, input_dir: $input, output_dir: $output, mode: "script"}')"
  exit 1
fi

# Verify output
output_count=$(find "$OUTPUT_DIR_ABS" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $output_count -eq 0 ]]; then
  echo "CRITICAL ERROR: No files generated in output directory"
  exit 1
fi

echo "VERIFIED: Script mode produced $output_count files"
```

### Block 6 (REQUIRED) - Verification and Summary

**OUTPUT FORMAT** (4-section standard):

**FILE CREATION ENFORCEMENT**: Verify that files were created BEFORE returning success.

```bash
# Final verification
final_output_dir="${OUTPUT_DIR_ABS:-$output_dir}"
final_count=$(find "$final_output_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $final_count -eq 0 ]]; then
  echo "CRITICAL ERROR: No output files found after conversion"
  exit 1
fi
```

**RETURN FORMAT** (4-section standard):

```
=== Document Conversion Complete ===

Summary: Converted $final_count of $file_count files from $input_dir to $final_output_dir using agent-based conversion with document-converter skill.

Artifacts:
  Converted: $final_output_dir/ ($final_count files)
  Log: $final_output_dir/conversion.log

Next Steps:
  Review log: cat $final_output_dir/conversion.log
  Check quality: ls -la $final_output_dir/
```

## Error Handling

**CRITICAL ERROR HANDLING**:

**Agent Mode (Primary)**:
- Agent invocation failure -> Fall back to script mode (STEP 5)
- Missing output directory -> Script fallback
- Zero output files -> Script fallback

**Script Fallback**:
- Missing tools -> Report installation guidance + exit 1
- Failed conversions -> Log error details + continue remaining files
- Zero successful conversions -> exit 1
- Missing conversion.log -> Warning (not fatal)

## Installation Guidance

If tools are missing:
- **MarkItDown**: `pip install --user 'markitdown[all]'` (recommended, handles both DOCX and PDF)
- **Pandoc**: Use system package manager (apt, brew, pacman, etc.)
- **PyMuPDF4LLM**: `pip install --user pymupdf4llm` (lightweight PDF backup)
- **Typst**: System package manager
- **XeLaTeX**: Install texlive package
- **google-genai**: `pip install --user google-genai` (for Gemini API, requires GEMINI_API_KEY)

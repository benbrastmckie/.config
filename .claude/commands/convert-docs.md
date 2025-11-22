---
command-type: primary
description: Convert between Markdown, Word (DOCX), and PDF formats bidirectionally
argument-hint: <input-directory> [output-directory] [--use-agent] [--no-api] [--parallel]
allowed-tools: Bash, Task, Read
agent-dependencies: doc-converter
library-requirements:
  - error-handling.sh: ">=1.0.0"
  - summary-formatting.sh: ">=1.0.0"
---

# Convert Documents - Bidirectional Conversion

**YOU MUST execute document conversion using conditional mode selection: script mode OR agent mode.**

**YOUR ROLE**: You are the CONVERSION COORDINATOR with two execution paths.
- **DO NOT** convert files yourself using Read/Write/Bash tools directly
- **Script Mode**: ONLY invoke the conversion script via Bash tool (source + main_conversion)
- **Agent Mode**: ONLY use Task tool to invoke doc-converter agent
- **YOUR RESPONSIBILITY**: Parse arguments, detect mode, delegate to script or agent

**EXECUTION MODES**:
- **Script Mode** (default): Invoke `.claude/lib/convert/convert-core.sh` script via Bash - fast, direct tool invocation
- **Agent Mode** (--use-agent or keywords): Invoke doc-converter agent via Task tool - comprehensive 5-phase workflow with validation

**MODE DETECTION LOGIC**:
- IF `--use-agent` flag present OR orchestration keywords detected ("detailed logging", "quality reporting", "verify tools") → Agent Mode
- ELSE → Script Mode

**CRITICAL INSTRUCTIONS**:
- Execute mode detection BEFORE any conversion attempt
- DO NOT execute conversion logic yourself
- DO NOT skip agent invocation when agent mode triggers
- DO NOT skip script invocation when script mode triggers
- Both modes produce conversion.log and converted files

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

**EXECUTE NOW**: Follow these steps in EXACT sequential order.

### STEP 0.5 (ENVIRONMENT INITIALIZATION) - Initialize CLAUDE_PROJECT_DIR

**EXECUTE FIRST - Defensive Environment Initialization**:

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
  echo "❌ CRITICAL ERROR: CLAUDE_PROJECT_DIR not set after initialization"
  exit 1
fi

if [[ ! -d "$CLAUDE_PROJECT_DIR" ]]; then
  echo "❌ CRITICAL ERROR: CLAUDE_PROJECT_DIR points to non-existent directory: $CLAUDE_PROJECT_DIR"
  exit 1
fi
```

**MANDATORY VERIFICATION - Environment Initialized**:
```bash
echo "✓ VERIFIED: CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"
```

### STEP 0 (SKILL AVAILABILITY CHECK) - Check for document-converter Skill

**EXECUTE FIRST - Skill Detection**:

```bash
# Check if document-converter skill exists
SKILL_AVAILABLE=false
SKILL_PATH="${CLAUDE_PROJECT_DIR}/.claude/skills/document-converter/SKILL.md"

if [[ -f "$SKILL_PATH" ]]; then
  SKILL_AVAILABLE=true
  echo "✓ DETECTED: document-converter skill available"
else
  echo "⚠ INFO: document-converter skill not found (using legacy mode)"
fi
```

**MANDATORY VERIFICATION - Skill Check Complete**:
```bash
echo "✓ VERIFIED: Skill availability check complete (available=$SKILL_AVAILABLE)"
```

### STEP 1 (REQUIRED BEFORE STEP 2) - Parse Arguments

**YOU MUST parse arguments and set defaults**:

```bash
input_dir="${1:-.}"
output_dir="${2:-./converted_output}"
user_request="$*"  # Full command text for mode detection
```

**MANDATORY VERIFICATION - Arguments Parsed**:
```bash
[[ -z "$input_dir" ]] && echo "❌ ERROR: Input directory not set" && exit 1
[[ -z "$output_dir" ]] && echo "❌ ERROR: Output directory not set" && exit 1
echo "✓ VERIFIED: input_dir=$input_dir, output_dir=$output_dir"
```

### STEP 1.5 (ERROR LOGGING SETUP) - Initialize Error Logging

**EXECUTE NOW - Error Logging Integration**:

```bash
# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "CRITICAL ERROR: Cannot load error-handling library"
  echo "   Expected: ${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"
  exit 1
}

# Initialize error log
ensure_error_log_exists || {
  echo "❌ CRITICAL ERROR: Cannot initialize error log"
  exit 1
}

# Set workflow metadata
COMMAND_NAME="/convert-docs"
WORKFLOW_ID="convert_docs_$(date +%s)"
USER_ARGS="$*"

# Export metadata to environment for delegated scripts
export COMMAND_NAME WORKFLOW_ID USER_ARGS
```

**MANDATORY VERIFICATION - Error Logging Initialized**:
```bash
echo "✓ VERIFIED: Error logging initialized (workflow_id=$WORKFLOW_ID)"
```

### STEP 2 (REQUIRED BEFORE STEP 3) - Verify Input Path

**EXECUTE NOW - Path Verification**:

```bash
# Verify input directory exists
if [[ ! -d "$input_dir" ]]; then
  echo "❌ CRITICAL ERROR: Input directory does not exist: $input_dir"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Input directory does not exist" \
    "step_2_validation" \
    "$(jq -n --arg dir "$input_dir" '{input_dir: $dir, provided_by_user: true}')"
  exit 1
fi

# Count files to convert
file_count=$(find "$input_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $file_count -eq 0 ]]; then
  echo "❌ CRITICAL ERROR: No convertible files found in $input_dir"
  echo "   Looking for: *.md, *.docx, *.pdf"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "No convertible files found in input directory" \
    "step_2_validation" \
    "$(jq -n --arg dir "$input_dir" --argjson count $file_count --argjson exts '["md", "docx", "pdf"]' '{input_dir: $dir, file_count: $count, expected_extensions: $exts}')"
  exit 1
fi

echo "✓ VERIFIED: Found $file_count files to convert"
```

### STEP 3 (REQUIRED BEFORE STEP 4) - Detect Conversion Mode

**YOU MUST determine execution mode** (script or agent):

```bash
agent_mode=false

# Check for --use-agent flag
if [[ "$user_request" =~ --use-agent ]]; then
  agent_mode=true
fi

# Check for orchestration keywords
if echo "$user_request" | grep -qiE "detailed logging|quality reporting|verify tools|orchestrated workflow|comprehensive logging"; then
  agent_mode=true
fi

echo "PROGRESS: Conversion mode: $([ "$agent_mode" = true ] && echo "AGENT" || echo "SCRIPT")"
```

**MANDATORY VERIFICATION - Mode Selected**:
```bash
[[ -z "$agent_mode" ]] && echo "❌ ERROR: Mode not determined" && exit 1
echo "✓ VERIFIED: Execution mode determined: $agent_mode"
```

### STEP 3.5 (CONDITIONAL) - Skill Delegation

**CRITICAL**: Execute this step ONLY if SKILL_AVAILABLE=true AND agent_mode=false

**SKILL DELEGATION PATH**: When skill is available in script mode, delegate to skill for seamless integration.

**EXECUTE NOW - Delegate to Skill**:

When skill is available, use natural language delegation to invoke it:

```
I'm delegating this conversion to the document-converter skill.

Use the document-converter skill to convert files from $input_dir to $output_dir.

Input directory: $input_dir
Output directory: $output_dir
Expected files: $file_count
```

The skill will:
1. Source conversion libraries automatically
2. Detect available tools (MarkItDown, Pandoc, PyMuPDF4LLM, etc.)
3. Process all files with optimal tool selection
4. Generate conversion.log with statistics
5. Return completion summary

**MANDATORY VERIFICATION - Skill Delegation Complete**:
```bash
# After skill completes, verify output
output_count=$(find "$output_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $output_count -eq 0 ]]; then
  echo "❌ CRITICAL ERROR: Skill delegation produced no output files"
  echo "⚠ Falling back to script mode..."
  SKILL_AVAILABLE=false  # Trigger fallback to Step 4
else
  echo "✓ VERIFIED: Skill produced $output_count files"
  # Skip to Step 6 (final verification)
  skip_to_step_6=true
fi
```

**CHECKPOINT REQUIREMENT - Skill Delegation Complete**:

Report skill results:
```
CHECKPOINT: Skill Delegation Complete
- Skill: document-converter
- Input Directory: $input_dir
- Output Directory: $output_dir
- Files Converted: $output_count
- Log File: $output_dir/conversion.log
- Status: SUCCESS
```

**NOTE**: If skill delegation fails or produces no output, automatically fall back to STEP 4 (Script Mode).

### STEP 4 (CONDITIONAL) - Script Mode Execution

**CRITICAL**: Execute this step ONLY if (agent_mode=false AND SKILL_AVAILABLE=false) OR (skill delegation failed in Step 3.5)

**FALLBACK MODE**: Direct script invocation when skill is unavailable or delegation failed.

**EXECUTE NOW - Invoke Conversion Script**:

```bash
# Pre-calculate output directory (absolute path)
OUTPUT_DIR_ABS="$(cd "$(dirname "$output_dir")" 2>/dev/null && pwd)/$(basename "$output_dir")"

# Create output directory if needed
mkdir -p "$OUTPUT_DIR_ABS" || {
  echo "❌ CRITICAL ERROR: Cannot create output directory: $OUTPUT_DIR_ABS"
  exit 1
}

echo "PROGRESS: Output directory: $OUTPUT_DIR_ABS"

# Source the conversion core module and run main function
source "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" || {
  echo "❌ CRITICAL ERROR: Cannot source convert-core.sh"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "file_error" \
    "Failed to source convert-core.sh library" \
    "step_4_script_mode" \
    "$(jq -n --arg lib "${CLAUDE_PROJECT_DIR}/.claude/lib/convert/convert-core.sh" --arg proj "$CLAUDE_PROJECT_DIR" '{lib_path: $lib, CLAUDE_PROJECT_DIR: $proj}')"
  exit 1
}

# Execute conversion with error handling
main_conversion "$input_dir" "$OUTPUT_DIR_ABS"
CONVERSION_EXIT=$?
if [ $CONVERSION_EXIT -ne 0 ]; then
  echo "❌ ERROR: Script mode conversion failed"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "main_conversion function returned non-zero exit code" \
    "step_4_script_mode" \
    "$(jq -n --arg input "$input_dir" --arg output "$OUTPUT_DIR_ABS" --argjson exit $CONVERSION_EXIT '{exit_code: $exit, input_dir: $input, output_dir: $output, mode: "script"}')"
  exit 1
fi
```

**MANDATORY VERIFICATION - Script Conversion Complete**:
```bash
# Check conversion log exists
if [[ ! -f "$OUTPUT_DIR_ABS/conversion.log" ]]; then
  echo "⚠️  WARNING: conversion.log not found (script may have failed silently)"
fi

# Count output files
output_count=$(find "$OUTPUT_DIR_ABS" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $output_count -eq 0 ]]; then
  echo "❌ CRITICAL ERROR: No files generated in output directory"
  exit 1
fi

echo "✓ VERIFIED: $output_count files generated"
echo "✓ VERIFIED: Script mode conversion complete"
```

**CHECKPOINT REQUIREMENT - Script Mode Complete**:

Report conversion results:
```
CHECKPOINT: Script Mode Conversion Complete
- Input Directory: $input_dir
- Output Directory: $OUTPUT_DIR_ABS
- Files Converted: $output_count
- Log File: $OUTPUT_DIR_ABS/conversion.log
- Status: SUCCESS
```

### STEP 5 (CONDITIONAL) - Agent Mode Execution

**CRITICAL**: Execute this step ONLY if agent_mode=true

**EXECUTE NOW - Invoke doc-converter Agent**:

YOU MUST use THIS EXACT TEMPLATE for agent invocation (No modifications):

```
Task {
  subagent_type: "general-purpose"
  description: "Convert documents with orchestration"
  prompt: |
    Read and follow behavioral guidelines: ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-converter.md

    YOU MUST convert documents with 5-phase orchestration workflow.

    REQUIRED PARAMETERS (ALL MANDATORY):
    - Input Directory: $input_dir (ABSOLUTE PATH REQUIRED)
    - Output Directory: $output_dir (ABSOLUTE PATH REQUIRED)
    - Direction: Auto-detect from file extensions (.md → DOCX, .docx/.pdf → MD)
    - Orchestration Mode: ENABLED

    MANDATORY DELIVERABLES:
    1. Converted files in output directory
    2. conversion.log with per-file results
    3. Quality validation report
    4. Tool selection explanations

    Return metadata only (paths + file count summary).
}
```

**MANDATORY VERIFICATION - Agent Conversion Complete**:
```bash
# Check if output directory was created by agent
if [[ ! -d "$output_dir" ]]; then
  echo "❌ CRITICAL ERROR: Agent did not create output directory"

  # FALLBACK: Search for output in alternative locations
  echo "⚠️  Attempting fallback search..."
  possible_output=$(find . -name "converted_output" -o -name "output" -type d 2>/dev/null | head -1)

  if [[ -n "$possible_output" ]]; then
    echo "✓ FALLBACK: Found output at $possible_output"
    output_dir="$possible_output"
  else
    echo "❌ FALLBACK FAILED: No output directory found"
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "agent_error" \
      "Agent mode failed: output directory not created" \
      "step_5_agent_mode" \
      "$(jq -n --arg expected "$output_dir" --arg input "$input_dir" '{expected_output_dir: $expected, input_dir: $input, mode: "agent", agent_name: "doc-converter"}')"
    exit 1
  fi
fi

# Verify converted files exist
output_count=$(find "$output_dir" -type f \( -name "*.md" -o -name "*.docx" -o -name "*.pdf" \) 2>/dev/null | wc -l)

if [[ $output_count -eq 0 ]]; then
  echo "❌ CRITICAL ERROR: Agent mode produced no output files"
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "Agent mode produced no output files" \
    "step_5_agent_mode" \
    "$(jq -n --arg output "$output_dir" --arg input "$input_dir" --argjson count $output_count '{output_dir: $output, input_dir: $input, file_count: $count, mode: "agent", agent_name: "doc-converter"}')"
  exit 1
fi

echo "✓ VERIFIED: Agent mode produced $output_count files"
```

**CHECKPOINT REQUIREMENT - Agent Mode Complete**:

Report agent results:
```
CHECKPOINT: Agent Mode Conversion Complete
- Input Directory: $input_dir
- Output Directory: $output_dir
- Files Converted: $output_count
- Agent: doc-converter
- Orchestration: 5-phase workflow
- Status: SUCCESS
```

### STEP 6 (FINAL STEP) - File Creation Verification and Return Format

**FILE CREATION ENFORCEMENT**: YOU MUST verify that files were created BEFORE returning success.

Create verification BEFORE proceeding:
- Script mode: Verify $output_count files exist in $OUTPUT_DIR_ABS
- Agent mode: Verify $output_count files exist in $output_dir
- If zero files: Exit with error (already enforced in Steps 4 and 5)

**RETURN FORMAT SPECIFICATION**: YOU MUST return ONLY the following format (no additional text)

```
✓ Document Conversion Complete

Mode: [SKILL|SCRIPT|AGENT]
Input: $input_dir ($file_count files)
Output: $output_dir ($output_count files converted)
Log: $output_dir/conversion.log

Next Steps:
- Review conversion.log for any warnings
- Check output files for formatting correctness
- Use converted files as needed
```

### Error Handling

**CRITICAL ERROR HANDLING - ALL MODES**:

**Script Mode**:
- Missing tools → Report installation guidance + exit 1
- Failed conversions → Log error details + continue remaining files
- Zero successful conversions → exit 1
- Missing conversion.log → Warning (not fatal)

**Agent Mode**:
- Agent invocation failure → Retry once, then exit 1
- Missing output directory → Search fallback locations, then exit 1
- Zero output files → exit 1
- Missing validation report → Warning (not fatal)

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

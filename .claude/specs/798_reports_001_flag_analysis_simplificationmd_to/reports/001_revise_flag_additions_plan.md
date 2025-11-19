# /revise Command Flag Additions Research Report

## Metadata
- **Date**: 2025-11-18
- **Agent**: research-specialist
- **Topic**: Adding --file and --dry-run flags to /revise command
- **Report Type**: codebase analysis

## Executive Summary

Analysis of the /revise command (revise.md) against /plan and /build commands reveals that /revise is missing two important flags: `--file` for long prompt handling and `--dry-run` for preview mode. The /plan command provides a proven implementation pattern for `--file` (lines 69-91) that handles path resolution, file validation, and content loading. The /build command provides the `--dry-run` pattern (lines 89-163) that enables preview-only execution. Adding these flags to /revise requires minimal changes: approximately 25-30 lines for --file parsing and 15-20 lines for --dry-run handling, with no structural changes to the existing workflow.

## Findings

### 1. Current /revise Command Structure

The /revise command (revise.md) currently supports only one flag:

**Existing Flag**: `--complexity 1-4` (lines 82-97)
- Default value: 2
- Implementation follows standard regex pattern matching
- Strips flag from revision description after extraction

**Current Argument Format** (line 101):
```bash
# Extract existing plan path from revision description
EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)
```

### 2. --file Flag Pattern Analysis (From /plan)

**Location**: `/home/benjamin/.config/.claude/commands/plan.md:69-91`

**Implementation Components**:

```bash
# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$FEATURE_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate file exists
  if [ ! -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
    echo "ERROR: Prompt file not found: $ORIGINAL_PROMPT_FILE_PATH" >&2
    exit 1
  fi
  # Read file content into FEATURE_DESCRIPTION
  FEATURE_DESCRIPTION=$(cat "$ORIGINAL_PROMPT_FILE_PATH")
  if [ -z "$FEATURE_DESCRIPTION" ]; then
    echo "WARNING: Prompt file is empty: $ORIGINAL_PROMPT_FILE_PATH" >&2
  fi
elif [[ "$FEATURE_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /plan --file /path/to/prompt.md" >&2
  exit 1
fi
```

**Key Features**:
1. Regex extraction: `--file[[:space:]]+([^[:space:]]+)`
2. Relative-to-absolute path conversion
3. File existence validation
4. Empty file warning (non-fatal)
5. Missing argument error handling

**Archiving Pattern** (plan.md:171-178):
```bash
# === ARCHIVE PROMPT FILE (if --file was used) ===
ARCHIVED_PROMPT_PATH=""
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  mkdir -p "${TOPIC_PATH}/prompts"
  ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompts/$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  mv "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi
```

### 3. --dry-run Flag Pattern Analysis (From /build)

**Location**: `/home/benjamin/.config/.claude/commands/build.md:89-163`

**Implementation Components**:

```bash
# Argument parsing (lines 89-104)
DRY_RUN="false"

for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
  esac
done

# Handle --dry-run as second argument (lines 101-104)
if [[ "$STARTING_PHASE" == "--dry-run" ]]; then
  STARTING_PHASE="1"
  DRY_RUN="true"
fi

# Execution gate (lines 156-163)
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  echo "Plan: $(basename "$PLAN_FILE")"
  echo "Starting Phase: $STARTING_PHASE"
  echo "Phases would be executed by implementer-coordinator agent"
  exit 0
fi
```

**Key Features**:
1. Boolean flag initialization: `DRY_RUN="false"`
2. Case-based argument parsing
3. Position-independent flag detection
4. Early exit with preview output
5. Informative summary of what would be done

### 4. Adaptation Requirements for /revise

**For --file Flag**:

The /revise command must extract the plan path from the revision description, which creates a unique challenge. The --file content should replace the revision details, NOT the plan path.

**Current flow** (revise.md:99-117):
1. Extract plan path: `EXISTING_PLAN_PATH=$(echo "$REVISION_DESCRIPTION" | grep -oE '[./][^ ]+\.md' | head -1)`
2. Extract revision details: Everything after the plan path

**Required modification**:
- Parse --file BEFORE extracting plan path and revision details
- --file content should be the revision details, prepended with plan path
- OR --file content should contain both plan path and revision details

**For --dry-run Flag**:

The /revise command should show:
- Existing plan to be revised
- Revision details/insights
- Research that would be conducted
- Exit before invoking agents

### 5. Insertion Points in revise.md

**--file flag**: Insert between lines 91-99 (after --complexity, before plan path extraction)

**--dry-run flag**:
- Parse after line 91 (with --complexity)
- Execute check after line 123 (after validation, before state machine init)

### 6. Argument-Hint Update

**Current** (line 3):
```yaml
argument-hint: <revision-description-with-plan-path>
```

**Should become**:
```yaml
argument-hint: <revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]
```

## Recommendations

### Recommendation 1: Add --file Flag to Part 2

**Location**: After line 91 in revise.md, before plan path extraction

**Implementation**:

```bash
# Parse optional --file flag for long prompts
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$REVISION_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert to absolute path if relative
  if [[ ! "$ORIGINAL_PROMPT_FILE_PATH" = /* ]]; then
    ORIGINAL_PROMPT_FILE_PATH="$(pwd)/$ORIGINAL_PROMPT_FILE_PATH"
  fi
  # Validate file exists
  if [ ! -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
    echo "ERROR: Prompt file not found: $ORIGINAL_PROMPT_FILE_PATH" >&2
    exit 1
  fi
  # Read file content - must contain plan path and revision details
  FILE_CONTENT=$(cat "$ORIGINAL_PROMPT_FILE_PATH")
  if [ -z "$FILE_CONTENT" ]; then
    echo "ERROR: Prompt file is empty: $ORIGINAL_PROMPT_FILE_PATH" >&2
    exit 1
  fi
  # Replace revision description with file content
  REVISION_DESCRIPTION="$FILE_CONTENT"
elif [[ "$REVISION_DESCRIPTION" =~ --file ]]; then
  echo "ERROR: --file flag requires a path argument" >&2
  echo "Usage: /revise --file /path/to/revision_prompt.md" >&2
  exit 1
fi
```

**Note**: The file content must contain both the plan path and revision details (e.g., "revise plan at /path/to/plan.md based on new security requirements").

### Recommendation 2: Add --dry-run Flag Parsing

**Location**: After --complexity parsing (line 91), before --file parsing

**Implementation**:

```bash
# Parse optional --dry-run flag for preview mode
DRY_RUN="false"
if [[ "$REVISION_DESCRIPTION" =~ --dry-run ]]; then
  DRY_RUN="true"
  # Strip flag from revision description
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--dry-run//' | xargs)
fi
```

### Recommendation 3: Add --dry-run Execution Gate

**Location**: After validation and before Part 3 (state machine initialization), around line 124

**Implementation**:

```bash
# === DRY-RUN MODE ===
if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY-RUN MODE: Preview Only ==="
  echo ""
  echo "Existing Plan: $EXISTING_PLAN_PATH"
  echo "Revision Details: $REVISION_DETAILS"
  echo "Research Complexity: $RESEARCH_COMPLEXITY"
  echo ""
  echo "Would perform:"
  echo "  1. Research phase with complexity $RESEARCH_COMPLEXITY"
  echo "  2. Create backup of existing plan"
  echo "  3. Revise plan based on research insights"
  echo ""
  echo "No changes made."
  exit 0
fi
```

### Recommendation 4: Update Argument Hint and Documentation

**YAML frontmatter change** (line 3):

```yaml
argument-hint: <revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]
```

**Add troubleshooting entry** (end of file):

```markdown
- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory
- **Empty file error**: The prompt file must contain both the plan path and revision details
```

### Recommendation 5: Archive Prompt File (Optional Enhancement)

For consistency with /plan, consider archiving the original prompt file:

```bash
# === ARCHIVE PROMPT FILE (if --file was used) ===
if [ -n "$ORIGINAL_PROMPT_FILE_PATH" ] && [ -f "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  mkdir -p "${SPECS_DIR}/prompts"
  ARCHIVED_PROMPT_PATH="${SPECS_DIR}/prompts/$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  mv "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
  echo "Prompt file archived: $ARCHIVED_PROMPT_PATH"
fi
```

This would go in Part 3 after SPECS_DIR is determined from the plan path.

## Implementation Order

1. **Update YAML frontmatter** - Update argument-hint (line 3)
2. **Add --dry-run parsing** - After line 91 (Part 2)
3. **Add --file parsing** - After --dry-run parsing (Part 2)
4. **Add --dry-run execution gate** - After validation, before Part 3
5. **Add troubleshooting entries** - End of file
6. **(Optional) Add prompt archiving** - Part 3 after SPECS_DIR

## Estimated Impact

- **Lines added**: ~50 lines
- **Files modified**: 1 (revise.md)
- **Risk**: Low - No structural changes to workflow
- **Testing required**: Flag parsing, file loading, dry-run output, path resolution

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/revise.md` (lines 1-545: full command structure)
  - Lines 3: argument-hint YAML
  - Lines 82-97: --complexity flag parsing
  - Lines 99-117: plan path and revision details extraction
  - Lines 126-207: Part 3 state machine initialization
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-420: full command structure)
  - Lines 3: argument-hint YAML showing flag syntax
  - Lines 55-67: --complexity flag parsing
  - Lines 69-91: --file flag parsing pattern
  - Lines 171-178: prompt file archiving pattern
- `/home/benjamin/.config/.claude/commands/build.md` (lines 89-163: argument parsing and dry-run)
  - Lines 93-104: --dry-run flag parsing
  - Lines 156-163: --dry-run execution gate
- `/home/benjamin/.config/.claude/specs/796_claude_commands_readmemd_and_evaluate_how/reports/001_flag_analysis_simplification.md` (lines 1-329: source analysis report)
  - Lines 33-60: --file flag analysis
  - Lines 88-115: --dry-run flag analysis
  - Lines 259-271: Priority 2 standardization recommendations

# --file Option Implementation Summary

## Work Status

**Completion**: 100% (5/5 phases complete)

**Status**: IMPLEMENTATION_COMPLETE

---

## Overview

Successfully implemented the `--file` option for `/plan`, `/research`, and `/debug` commands to support long prompts. When provided, the command reads prompt content from a file, archives it to the specs directory, and makes the path accessible to research subagents.

## Completed Phases

### Phase 1: Core Flag Parsing Implementation [COMPLETE]

Added --file flag parsing logic to all three commands:

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 69-91)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 68-90)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 53-75)

**Implementation Details**:
- Parse `--file [path]` after --complexity parsing
- Convert relative paths to absolute paths
- Validate file exists before reading
- Read file content into description variable (FEATURE_DESCRIPTION, WORKFLOW_DESCRIPTION, ISSUE_DESCRIPTION)
- Error handling for missing path argument

### Phase 2: File Archival to Specs Directory [COMPLETE]

Added file archival logic to move original prompt file to specs directory:

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 171-178)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 167-174)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 290-297)

**Implementation Details**:
- Create `${TOPIC_PATH}/prompts/` directory
- Move original file to `${TOPIC_PATH}/prompts/$(basename "$ORIGINAL_PROMPT_FILE_PATH")`
- Store ARCHIVED_PROMPT_PATH for reference
- Confirmation message on successful archival

### Phase 3: State Persistence for Subagent Access [COMPLETE]

Added workflow state persistence for file paths:

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 190-191)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 183-184)
- `/home/benjamin/.config/.claude/commands/debug.md` (lines 312-313)

**Implementation Details**:
- `append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"`
- `append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"`

### Phase 4: Update Task Tool Prompts for Research Agents [COMPLETE]

Updated subagent Task prompts to receive file paths:

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/plan.md` (research-specialist and plan-architect prompts)
- `/home/benjamin/.config/.claude/commands/research.md` (research-specialist prompt)
- `/home/benjamin/.config/.claude/commands/debug.md` (research-specialist and plan-architect prompts)

**Implementation Details**:
- Added to Workflow-Specific Context:
  - `Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}`
  - `Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}`
- Added instruction: "If an archived prompt file is provided (not 'none'), read it for complete context."

### Phase 5: Documentation and Testing [COMPLETE]

Updated documentation and verified implementation:

**Files Modified**:
- `/home/benjamin/.config/.claude/commands/plan.md` (frontmatter, troubleshooting)
- `/home/benjamin/.config/.claude/commands/research.md` (frontmatter, troubleshooting)
- `/home/benjamin/.config/.claude/commands/debug.md` (frontmatter, troubleshooting)
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md`

**Implementation Details**:
- Updated argument-hint to: `<description> [--file <path>] [--complexity 1-4]`
- Added troubleshooting entries for file errors
- Updated command-reference.md with --file flag documentation
- Verified regex pattern parsing with test script

## Usage Examples

```bash
# Plan with file-based prompt
/plan --file /path/to/long_spec.md

# Research with file and complexity
/research --file /path/to/research_topic.md --complexity 3

# Debug with file
/debug --file /path/to/issue_description.md

# Flags can be combined in either order
/plan --complexity 2 --file /path/to/spec.md
```

## Technical Notes

### Flag Parsing Order
Flags are parsed in order: --complexity first, then --file. Both can be combined in any order.

### File Path Handling
- Relative paths converted to absolute using `$(pwd)`
- Validation checks file existence before reading
- Empty file produces warning but continues execution

### Archive Location
Files are archived to `${TOPIC_PATH}/prompts/` directory, preserving original filename.

### Backward Compatibility
Existing inline prompts continue to work without modification. The --file flag is entirely optional.

## Success Criteria Verification

- [x] All three commands accept `--file /path/to/prompt.md` flag
- [x] Prompt file content is read and stored in description variable
- [x] Original prompt file path is accessible to research subagents via ORIGINAL_PROMPT_FILE_PATH
- [x] Prompt file is moved to specs topic directory as `prompts/<original-filename>`
- [x] Existing inline prompts continue to work without modification
- [x] Flags can be combined: `--file /path --complexity 3` in either order
- [x] File validation errors provide clear error messages
- [x] Documentation updated with usage examples

## Implementation Metrics

- **Total Phases**: 5
- **Successful Phases**: 5
- **Failed Phases**: 0
- **Files Modified**: 4 command files + 1 reference doc
- **Lines Added**: ~150 lines across all files
- **Context Exhausted**: No
- **Work Remaining**: 0

---

**Generated**: 2025-11-18
**Plan Path**: /home/benjamin/.config/.claude/specs/793_reports_001_long_prompt_handling_analysismd_in/plans/001_reports_001_long_prompt_handling_analysi_plan.md

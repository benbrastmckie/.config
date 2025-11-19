# Implementation Summary: /revise Command Flag Additions

## Work Status: 100% Complete

All phases completed successfully. No work remaining.

## Overview

Added `--file` and `--dry-run` flags to the `/revise` command to provide parity with other commands and improve safety.

## Phases Completed

### Phase 1: Add --dry-run Flag [COMPLETED]
- Added `DRY_RUN` variable initialization and flag parsing after `--complexity` parsing
- Added execution gate after validation that shows preview output and exits before state machine
- Preview displays plan path, revision details, complexity level, and workflow steps

### Phase 2: Add --file Flag [COMPLETED]
- Added `ORIGINAL_PROMPT_FILE_PATH` variable and `--file` flag parsing
- Implemented relative-to-absolute path conversion
- Added file existence validation with clear error messages
- Added empty file validation with diagnostic message
- Added error handling for missing path argument

### Phase 3: Documentation Updates [COMPLETED]
- Updated YAML frontmatter argument-hint to include all flags: `<revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]`
- Added three new troubleshooting entries:
  - File not found error
  - Empty file error
  - Dry-run mode explanation

## Files Modified

- `/home/benjamin/.config/.claude/commands/revise.md` - All flag implementations and documentation updates

## Implementation Details

### --dry-run Flag
Location: Lines 99-105 (parsing), Lines 168-186 (execution gate)
```bash
# Parse optional --dry-run flag
DRY_RUN="false"
if [[ "$REVISION_DESCRIPTION" =~ --dry-run ]]; then
  DRY_RUN="true"
  REVISION_DESCRIPTION=$(echo "$REVISION_DESCRIPTION" | sed 's/--dry-run//' | xargs)
fi
```

### --file Flag
Location: Lines 107-140
```bash
# Parse optional --file flag for long prompt handling
ORIGINAL_PROMPT_FILE_PATH=""
if [[ "$REVISION_DESCRIPTION" =~ --file[[:space:]]+([^[:space:]]+) ]]; then
  ORIGINAL_PROMPT_FILE_PATH="${BASH_REMATCH[1]}"
  # Convert relative to absolute, validate, read content
  ...
fi
```

## Test Commands

```bash
# Test --dry-run shows preview and exits
/revise "revise plan at .claude/specs/test/plans/001_test.md based on feedback --dry-run"

# Test --file loads content from file
echo "revise plan at .claude/specs/test/plans/001_test.md based on new requirements" > /tmp/revise_prompt.md
/revise "--file /tmp/revise_prompt.md"

# Test flag combination
/revise "--file /tmp/revise_prompt.md --dry-run"

# Test error handling - file not found
/revise "--file /nonexistent/path.md"

# Test error handling - missing path argument
/revise "--file"
```

## Success Criteria Met

- [x] --file flag parses path correctly from revision description
- [x] --file flag converts relative paths to absolute
- [x] --file flag validates file existence before reading
- [x] --file flag loads file content as revision description
- [x] --dry-run flag detected and stored as boolean
- [x] --dry-run flag shows preview output and exits before state machine
- [x] Argument hint in YAML frontmatter updated to show new flags
- [x] Troubleshooting section updated with new error scenarios
- [x] All existing /revise functionality preserved (no regressions)
- [x] Flags can be combined (e.g., --file path.md --dry-run)

## Metrics

- Total Phases: 3
- Phases Completed: 3
- Phases Failed: 0
- Execution Mode: Sequential (dependency chain)
- Time Savings: N/A (sequential dependencies)

## Notes

- Flag processing order: --complexity, --dry-run, --file, then plan path extraction
- No prompt file archiving (unlike /plan) since /revise doesn't create new topic directories
- File content replaces entire description and must contain plan path

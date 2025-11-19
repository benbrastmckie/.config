# /revise Command Flag Additions Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Add --file and --dry-run flags to /revise command
- **Scope**: Flag parsing, execution gate, documentation updates for revise.md only
- **Estimated Phases**: 3
- **Estimated Hours**: 2-3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 14
- **Research Reports**:
  - [/revise Flag Additions Research](/home/benjamin/.config/.claude/specs/798_reports_001_flag_analysis_simplificationmd_to/reports/001_revise_flag_additions_plan.md)

## Overview

This plan implements two flag additions to the /revise command:

1. **--file `<path>`**: Load revision description from a file instead of inline argument. This provides parity with /plan, /research, and /debug commands which already support this flag for handling long prompts.

2. **--dry-run**: Preview mode that shows what would be done without executing the workflow. This matches the safety pattern used in /build and /setup commands.

No other changes will be made to the /revise command or any other commands.

## Research Summary

Based on analysis from the flag analysis simplification report:

- **--file flag**: Already implemented consistently in /plan (lines 69-91), /research, and /debug commands. Uses regex pattern `--file[[:space:]]+([^[:space:]]+)` for extraction, converts relative paths to absolute, validates file existence, and reads content.

- **--dry-run flag**: Implemented in /build (lines 89-163) using boolean flag detection and early exit pattern with preview output.

- **/revise current state**: Only supports --complexity flag (lines 82-97). Missing --file (should add for parity) and --dry-run (should add for safety).

- **Implementation approach**: Copy proven patterns from /plan and /build with minimal adaptation for /revise's specific flow (plan path + revision details extraction).

## Success Criteria

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

## Technical Design

### Insertion Points

The flags will be added to Part 2 of revise.md, specifically:

1. **--dry-run parsing**: After line 91 (after --complexity parsing)
2. **--file parsing**: After --dry-run parsing (before plan path extraction at line 99)
3. **--dry-run execution gate**: After line 123 (after validation output, before Part 3)

### Flag Processing Order

```
1. Parse --complexity (existing, line 82-91)
2. Parse --dry-run (new)
3. Parse --file (new)
4. Extract plan path from description (existing, line 99-101)
5. Validate plan exists (existing, lines 103-114)
6. Extract revision details (existing, line 117)
7. Execute dry-run gate if enabled (new)
```

### Design Decisions

1. **Parse --dry-run before --file**: This allows --dry-run to work regardless of whether --file is used
2. **File content replaces entire description**: The file must contain both plan path and revision details (consistent with how other commands work)
3. **No prompt archiving**: Unlike /plan, we won't archive the prompt file since /revise doesn't create new topic directories
4. **Preview shows all extracted values**: Dry-run output displays plan path, revision details, and complexity for verification

## Implementation Phases

### Phase 1: Add --dry-run Flag [COMPLETED] [COMPLETE]
dependencies: []

**Objective**: Add --dry-run flag parsing and execution gate to /revise command

**Complexity**: Low

Tasks:
- [x] Add --dry-run flag parsing after --complexity parsing (file: /home/benjamin/.config/.claude/commands/revise.md, after line 91)
  - Initialize: `DRY_RUN="false"`
  - Pattern match: `--dry-run`
  - Strip flag from description using sed
- [x] Add --dry-run execution gate after validation (file: /home/benjamin/.config/.claude/commands/revise.md, after line 123)
  - Check `if [ "$DRY_RUN" = "true" ]`
  - Echo preview information (plan path, revision details, complexity)
  - Echo workflow steps that would be performed
  - Exit 0 without executing state machine

Testing:
```bash
# Test --dry-run shows preview and exits
/revise "revise plan at .claude/specs/test/plans/001_test.md based on feedback --dry-run"
# Should output preview and exit without executing

# Test without --dry-run still works
/revise "revise plan at .claude/specs/test/plans/001_test.md based on feedback"
# Should execute normally
```

**Expected Duration**: 0.5 hours

### Phase 2: Add --file Flag [COMPLETED] [COMPLETE]
dependencies: [1]

**Objective**: Add --file flag parsing for long prompt handling

**Complexity**: Medium

Tasks:
- [x] Add --file flag parsing after --dry-run parsing (file: /home/benjamin/.config/.claude/commands/revise.md)
  - Initialize: `ORIGINAL_PROMPT_FILE_PATH=""`
  - Pattern match: `--file[[:space:]]+([^[:space:]]+)`
  - Convert relative to absolute path
  - Validate file exists
  - Read file content into REVISION_DESCRIPTION
  - Handle error: --file without path argument
  - Handle error: file not found
  - Handle error: file is empty
- [x] Ensure --file content contains both plan path and revision details

Testing:
```bash
# Create test prompt file
echo "revise plan at .claude/specs/test/plans/001_test.md based on new requirements" > /tmp/revise_prompt.md

# Test --file loads content correctly
/revise "--file /tmp/revise_prompt.md"
# Should extract plan path and revision details from file

# Test --file with --dry-run combination
/revise "--file /tmp/revise_prompt.md --dry-run"
# Should show preview with content from file

# Test error handling - file not found
/revise "--file /nonexistent/path.md"
# Should show error message

# Test error handling - missing path argument
/revise "--file"
# Should show usage error
```

**Expected Duration**: 1 hour

### Phase 3: Documentation Updates [COMPLETED] [COMPLETE]
dependencies: [2]

**Objective**: Update YAML frontmatter and troubleshooting section

**Complexity**: Low

Tasks:
- [x] Update argument-hint in YAML frontmatter (file: /home/benjamin/.config/.claude/commands/revise.md, line 3)
  - FROM: `argument-hint: <revision-description-with-plan-path>`
  - TO: `argument-hint: <revision-description-with-plan-path> [--file <path>] [--complexity 1-4] [--dry-run]`
- [x] Add troubleshooting entries at end of file (file: /home/benjamin/.config/.claude/commands/revise.md)
  - Add: `- **File not found error**: Ensure --file path is correct and file exists; relative paths are resolved from current directory`
  - Add: `- **Empty file error**: The prompt file must contain both the plan path and revision details`
  - Add: `- **Dry-run mode**: Use --dry-run to preview what would be done without executing`

Testing:
```bash
# Verify argument-hint shows in help
# (Manual verification - check YAML frontmatter)

# Verify troubleshooting section present
grep -A2 "File not found error" .claude/commands/revise.md
grep -A2 "Empty file error" .claude/commands/revise.md
grep -A2 "Dry-run mode" .claude/commands/revise.md
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
- Test --dry-run flag parsing in isolation
- Test --file flag parsing with various path formats
- Test flag combination handling
- Test error conditions (missing file, empty file, invalid path)

### Integration Testing
- Test complete /revise workflow with --file flag
- Test --dry-run exits before state machine initialization
- Test existing functionality not broken (regression testing)

### Manual Testing
- Create test prompt file with long revision description
- Verify --dry-run output matches expected preview format
- Verify --file content correctly replaces inline description

### Test Commands
```bash
# Regression test - existing functionality
/revise "revise plan at .claude/specs/test/plans/001_test.md based on simple change"

# New functionality tests
/revise "revise plan at .claude/specs/test/plans/001_test.md based on change --dry-run"
/revise "--file /tmp/test_prompt.md"
/revise "--file /tmp/test_prompt.md --complexity 3 --dry-run"
```

## Documentation Requirements

- Update revise.md YAML frontmatter argument-hint
- Add troubleshooting entries for new error conditions
- No external documentation updates required (single file change)
- No README.md updates required (README already documents flag patterns)

## Dependencies

### Prerequisites
- Existing /revise command functioning correctly
- Patterns from /plan.md (lines 69-91) for --file implementation
- Patterns from /build.md (lines 89-163) for --dry-run implementation

### External Dependencies
None - this is a self-contained enhancement to an existing command

### Risk Assessment
- **Low risk**: Proven patterns copied from existing commands
- **Mitigation**: --dry-run flag enables safe testing before execution
- **Rollback**: Changes localized to single file (revise.md)

## Notes

- This implementation makes no other changes beyond adding --file and --dry-run flags
- Prompt file archiving is NOT included (unlike /plan) since /revise doesn't create new topic directories
- Flag processing order matters: --dry-run must be checked after all other flag parsing completes
- File content must include the plan path since /revise extracts it from the description

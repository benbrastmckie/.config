# --file Option Implementation Plan for Long Prompts

## Metadata
- **Date**: 2025-11-18
- **Feature**: --file option for commands with research phases
- **Scope**: Add --file flag to /plan, /research, /debug for long prompt handling
- **Estimated Phases**: 5
- **Estimated Hours**: 8-10
- **Structure Level**: 0
- **Complexity Score**: 56
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [File Option Implementation Analysis](../reports/001_file_option_implementation_analysis.md)

## Overview

This plan implements the `--file` option for commands with research phases (/plan, /research, /debug) to support long prompts. When provided, the command reads the prompt content from a file, copies it to the specs directory for archival, and makes the original file path accessible to research subagents while preserving existing summarization behavior for FEATURE_DESCRIPTION/WORKFLOW_DESCRIPTION/ISSUE_DESCRIPTION.

## Research Summary

Key findings from the implementation analysis report:

- **Consistent two-step pattern**: All three commands use identical argument capture and flag parsing patterns (temp file + regex matching)
- **State persistence mechanism**: `append_workflow_state()` provides the established pattern for passing data to subagents
- **Task tool prompts**: Research agents receive context through Workflow-Specific Context sections in prompts
- **Topic directory creation**: `initialize_workflow_paths()` creates topic directories where prompt files should be archived
- **Prior recommendation**: The earlier research explicitly recommended file-based input for prompts exceeding 5,000 characters

Recommended approach: Extend existing --complexity flag parsing pattern to add --file parsing, archive files to specs directory, and pass paths through workflow state to subagent prompts.

## Success Criteria

- [ ] All three commands accept `--file /path/to/prompt.md` flag
- [ ] Prompt file content is read and stored in description variable (FEATURE_DESCRIPTION, WORKFLOW_DESCRIPTION, or ISSUE_DESCRIPTION)
- [ ] Original prompt file path is accessible to research subagents via ORIGINAL_PROMPT_FILE_PATH
- [ ] Prompt file is copied to specs topic directory as `prompt_<original-filename>`
- [ ] Existing inline prompts continue to work without modification (backward compatibility)
- [ ] Flags can be combined: `--file /path --complexity 3` in either order
- [ ] File validation errors (not found, empty) provide clear error messages
- [ ] Documentation updated with usage examples

## Technical Design

### Architecture Overview

The implementation follows the existing flag parsing pattern in all three commands:

```
User Input → Temp File Capture → Flag Parsing → Description Variable
                                    ↓
                              ORIGINAL_PROMPT_FILE_PATH
                                    ↓
                         Workflow State Persistence
                                    ↓
                     Research Subagent Task Prompts
```

### Key Design Decisions

1. **Parse After --complexity**: Add --file parsing immediately after --complexity parsing to maintain consistency
2. **Archive to Topic Directory**: Copy file after `initialize_workflow_paths()` creates topic directory
3. **Keep Both Paths**: Store both `ORIGINAL_PROMPT_FILE_PATH` (source) and `ARCHIVED_PROMPT_PATH` (in specs)
4. **Preserve Summarization**: FEATURE_DESCRIPTION/WORKFLOW_DESCRIPTION continues to hold content for topic slug generation
5. **Optional Path in Prompts**: Use `${ORIGINAL_PROMPT_FILE_PATH:-none}` to gracefully handle absence

### Component Interactions

- **Commands**: /plan, /research, /debug (Block 1/Part 1 modifications)
- **Libraries**: state-persistence.sh (existing `append_workflow_state()` function)
- **Agents**: research-specialist, plan-architect (receive path via Task prompts)

## Implementation Phases

### Phase 1: Core Flag Parsing Implementation [NOT STARTED]
dependencies: []

**Objective**: Add --file flag parsing to all three commands

**Complexity**: Medium

Tasks:
- [ ] Add --file parsing logic to `/home/benjamin/.config/.claude/commands/plan.md` after line 62
  - [ ] Initialize ORIGINAL_PROMPT_FILE_PATH=""
  - [ ] Match regex pattern `--file[[:space:]]+([^[:space:]]+)`
  - [ ] Validate source file exists
  - [ ] Read file content into FEATURE_DESCRIPTION
  - [ ] Remove --file flag from remaining text
- [ ] Add --file parsing logic to `/home/benjamin/.config/.claude/commands/research.md` after line 60
  - [ ] Same pattern as plan.md but for WORKFLOW_DESCRIPTION
- [ ] Add --file parsing logic to `/home/benjamin/.config/.claude/commands/debug.md` after line 45
  - [ ] Same pattern but for ISSUE_DESCRIPTION

Testing:
```bash
# Test pattern matching (dry run without file)
echo "test --file /path/to/file.md --complexity 3" | grep -oE '\-\-file[[:space:]]+([^[:space:]]+)'

# Verify regex captures full path
[[ "test --file /path/to/file.md" =~ --file[[:space:]]+([^[:space:]]+) ]] && echo "${BASH_REMATCH[1]}"
```

**Expected Duration**: 2 hours

### Phase 2: File Archival to Specs Directory [NOT STARTED]
dependencies: [1]

**Objective**: Copy original prompt file to topic directory after creation

**Complexity**: Low

Tasks:
- [ ] Add file copy logic to `/home/benjamin/.config/.claude/commands/plan.md` after line 144 (after mkdir -p "$RESEARCH_DIR")
  - [ ] Check if ORIGINAL_PROMPT_FILE_PATH is non-empty and file exists
  - [ ] Calculate ARCHIVED_PROMPT_PATH="${TOPIC_PATH}/prompt_$(basename "$ORIGINAL_PROMPT_FILE_PATH")"
  - [ ] Copy file: `cp "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"`
  - [ ] Echo confirmation message
- [ ] Add file copy logic to `/home/benjamin/.config/.claude/commands/research.md` after line 141
- [ ] Add file copy logic to `/home/benjamin/.config/.claude/commands/debug.md` after line 264

Testing:
```bash
# Test file copy operation
ORIGINAL_PROMPT_FILE_PATH="/tmp/test_prompt.md"
echo "Test content" > "$ORIGINAL_PROMPT_FILE_PATH"
ARCHIVED_PROMPT_PATH="/tmp/specs/prompt_test_prompt.md"
mkdir -p "$(dirname "$ARCHIVED_PROMPT_PATH")"
cp "$ORIGINAL_PROMPT_FILE_PATH" "$ARCHIVED_PROMPT_PATH"
[ -f "$ARCHIVED_PROMPT_PATH" ] && echo "Archive successful"
```

**Expected Duration**: 1 hour

### Phase 3: State Persistence for Subagent Access [NOT STARTED]
dependencies: [2]

**Objective**: Persist file paths to workflow state for subagent access

**Complexity**: Low

Tasks:
- [ ] Add state persistence to `/home/benjamin/.config/.claude/commands/plan.md` after line 156
  - [ ] `append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "$ORIGINAL_PROMPT_FILE_PATH"`
  - [ ] `append_workflow_state "ARCHIVED_PROMPT_PATH" "${ARCHIVED_PROMPT_PATH:-}"`
- [ ] Add state persistence to `/home/benjamin/.config/.claude/commands/research.md` after line 149
- [ ] Add state persistence to `/home/benjamin/.config/.claude/commands/debug.md` after line 147

Testing:
```bash
# Test state persistence (requires sourcing library)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
WORKFLOW_ID="test_$(date +%s)"
init_workflow_state "$WORKFLOW_ID"
append_workflow_state "ORIGINAL_PROMPT_FILE_PATH" "/path/to/file.md"
load_workflow_state "$WORKFLOW_ID" false
echo "Retrieved: $ORIGINAL_PROMPT_FILE_PATH"
```

**Expected Duration**: 1 hour

### Phase 4: Update Task Tool Prompts for Research Agents [NOT STARTED]
dependencies: [3]

**Objective**: Pass file paths to research-specialist and plan-architect agents

**Complexity**: Medium

Tasks:
- [ ] Update research-specialist Task prompt in `/home/benjamin/.config/.claude/commands/plan.md` (lines 165-183)
  - [ ] Add to Workflow-Specific Context section:
    ```
    - Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}
    - Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}
    ```
  - [ ] Add instruction for agents to read original file when available
- [ ] Update research-specialist Task prompt in `/home/benjamin/.config/.claude/commands/research.md` (lines 157-175)
- [ ] Update research-specialist Task prompt in `/home/benjamin/.config/.claude/commands/debug.md` (lines 282-303)
- [ ] Update plan-architect Task prompts to receive the file paths for reference

Testing:
```bash
# Verify variable expansion in prompt template
ORIGINAL_PROMPT_FILE_PATH="/path/to/spec.md"
ARCHIVED_PROMPT_PATH="/specs/prompt_spec.md"
echo "Original Prompt File: ${ORIGINAL_PROMPT_FILE_PATH:-none}"
echo "Archived Prompt File: ${ARCHIVED_PROMPT_PATH:-none}"
```

**Expected Duration**: 2 hours

### Phase 5: Documentation and Testing [NOT STARTED]
dependencies: [4]

**Objective**: Update documentation and perform end-to-end testing

**Complexity**: Low

Tasks:
- [ ] Update command frontmatter argument-hint in all three commands
  - [ ] plan.md: `<feature-description> [--file <path>] [--complexity 1-4]`
  - [ ] research.md: `<workflow-description> [--file <path>] [--complexity 1-4]`
  - [ ] debug.md: `<issue-description> [--file <path>] [--complexity 1-4]`
- [ ] Add troubleshooting entries to each command's Troubleshooting section
- [ ] Update `/home/benjamin/.config/.claude/docs/reference/command-reference.md` with --file flag documentation
- [ ] Update command-specific guides if they exist:
  - [ ] plan-command-guide.md
  - [ ] research-command-guide.md
  - [ ] debug-command-guide.md
- [ ] Create test prompts and verify end-to-end:
  - [ ] Test `/plan --file /path/to/spec.md`
  - [ ] Test `/research --file /path/to/spec.md --complexity 3`
  - [ ] Test `/debug --file /path/to/issue.md`
  - [ ] Test backward compatibility with inline prompts

Testing:
```bash
# Create test prompt file
cat > /tmp/test_long_prompt.md << 'EOF'
# Test Feature Specification

This is a comprehensive test specification for validating the --file option implementation.

## Requirements
1. Feature A
2. Feature B
3. Feature C

## Technical Details
Detailed technical content that would be too long for inline prompts.
EOF

# Test each command (manual execution required)
# /plan --file /tmp/test_long_prompt.md
# /research --file /tmp/test_long_prompt.md --complexity 2
# /debug --file /tmp/test_long_prompt.md
```

**Expected Duration**: 2 hours

**Note**: Phase dependencies enable parallel execution when using `/implement`.
- Empty `[]` = no dependencies (runs in first wave)
- `[1]` = depends on Phase 1 (runs after Phase 1 completes)
- `[2]` = depends on Phase 2 (runs after Phase 2 completes)

## Testing Strategy

### Unit Testing
- Test regex pattern matching for --file flag
- Test file existence validation
- Test file content reading
- Test state persistence round-trip

### Integration Testing
- Test each command (/plan, /research, /debug) with --file flag individually
- Test flag combination (--file with --complexity in both orders)
- Test file archival to correct location
- Verify subagents receive file path in prompts

### Backward Compatibility Testing
- Verify existing inline prompts work without modification
- Verify commands work without --file flag
- Verify existing --complexity flag behavior unchanged

### Edge Case Testing
- File not found error handling
- Empty file warning
- File with spaces in path
- Relative path conversion to absolute
- Very large prompt files

## Documentation Requirements

### Updates Required
- Command reference documentation (command-reference.md)
- Individual command guides (plan/research/debug guides)
- Command frontmatter argument-hint fields
- Troubleshooting sections in each command

### Documentation Content
- Usage examples showing --file flag
- Flag combination examples (--file + --complexity)
- Error message explanations
- Subagent access pattern description

## Dependencies

### Prerequisites
- All three commands must exist and be functional
- state-persistence.sh library with `append_workflow_state()` function
- workflow-initialization.sh library with `initialize_workflow_paths()` function
- Topic directory creation working correctly

### External Dependencies
- None (all bash built-ins and existing libraries)

### Risk Factors
- **Low**: Additive feature with explicit flag, minimal risk to existing functionality
- **Medium**: Three commands to modify increases testing surface
- **Mitigation**: Test each command individually before integration testing

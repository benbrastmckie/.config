# /debug Command Refactor Plan: Specific Fixes Beyond Systematic Infrastructure

## Metadata
- **Date**: 2025-11-21
- **Revised**: 2025-11-21 (Lazy Directory Creation Strategy)
- **Feature**: /debug command-specific fixes
- **Scope**: Issues NOT covered by systematic infrastructure plan (105)
- **Estimated Phases**: 4
- **Estimated Hours**: 6.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 42.5 (fix=3 + Tasks(17)/2=8.5 + Files(7)*3=21 + Integrations(2)*5=10)
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_root_cause_analysis.md)
  - [Lazy Directory Creation Research](../reports/002_lazy_directory_creation_research.md)
  - [Lazy Directory Creation Standards](../reports/001_lazy_directory_creation_standards.md)
  - [Error Report](/home/benjamin/.config/.claude/specs/107_debug_command_error_analysis/reports/001_error_report.md)
- **Related Plans**:
  - [Systematic Infrastructure Fix](/home/benjamin/.config/.claude/specs/105_build_state_management_bash_errors_fix/plans/001_debug_strategy.md) - Covers three-tier sourcing pattern, automated linter, pre-commit enforcement (Phases 2-6)

## Overview

This plan addresses /debug command-specific issues that are **NOT covered** by the systematic infrastructure plan (105). The systematic plan handles the broad library sourcing standards enforcement across all commands. This plan focuses on:

1. **Block 2a Missing Library**: `workflow-initialization.sh` not sourced (contains `initialize_workflow_paths`)
2. **Validation Error Logging**: Input validation errors not logged to `/errors` queryable log
3. **Lazy Directory Creation Enforcement**: Ensure directories are created ONLY when files are written, eliminating empty directories without cleanup
4. **Documentation Standards Updates**: Remove conflicting guidance from documentation files and strengthen cross-references to enforce lazy directory creation uniformly

## Research Summary

### From Root Cause Analysis (001_root_cause_analysis.md)

**Key Finding 1**: Block 2a (lines 286-289) sources only 3 libraries but calls `initialize_workflow_paths()` which requires `workflow-initialization.sh` (not sourced). This is a /debug-specific gap.

**Key Finding 2**: Input validation (lines 61-66) prints error but doesn't call `log_command_error`, making validation failures invisible to `/errors` queries.

### From Lazy Directory Creation Research (002_lazy_directory_creation_research.md)

**Key Finding 3**: The lazy directory creation infrastructure **already exists**:
- `ensure_artifact_directory()` in unified-location-detection.sh (lines 400-411)
- `create_topic_structure()` creates only topic root, not subdirectories (lines 413-425)
- Code Standards documents the pattern comprehensively (lines 68-143)

**Key Finding 4**: Empty directories are caused by **inconsistent adoption** of the existing pattern, not missing infrastructure. The solution is enforcement, not new code.

**Key Insight**: By creating directories ONLY when needed (at file write time), we never produce empty directories and never need cleanup.

### From Lazy Directory Creation Standards (001_lazy_directory_creation_standards.md)

**Key Finding 5**: Comprehensive documentation already exists in `code-standards.md` (lines 68-147) and `directory-protocols.md` (lines 196-370). Adding new documentation would create redundancy.

**Key Finding 6**: Conflicting guidance exists in three files that contradicts the lazy directory creation standard:
- `spec_updater_guide.md` line 534: "Always create topic directories with full subdirectory structure"
- `orchestration-troubleshooting.md` lines 538-566: Recommends "pre-create" as valid option
- `creating-orchestrator-commands.md` line 300: "REQUIRED: Create reports directory"

**Key Recommendation**: Remove conflicting guidance and add cross-reference to `command-authoring.md` rather than creating new documentation. This is the elegant solution.

## Success Criteria

- [ ] /debug command executes without exit code 127 errors for `initialize_workflow_paths`
- [ ] Input validation failures logged to errors.jsonl and queryable via `/errors --command /debug`
- [ ] No empty directories created when /debug workflows fail or produce no artifacts
- [ ] All directory creation happens via `ensure_artifact_directory()` at write-time
- [ ] Integration test validates no empty directories after workflow execution
- [ ] Conflicting documentation removed from spec_updater_guide.md, orchestration-troubleshooting.md, and creating-orchestrator-commands.md
- [ ] Cross-reference to lazy directory creation standard added to command-authoring.md

## Technical Design

### Core Principle: Lazy Directory Creation

**Rule**: Directory creation (`mkdir`) must be **immediately followed** (within same bash block) by file write, OR delegated to `ensure_artifact_directory()` at write-time.

```
Traditional (WRONG):
  1. Command setup: mkdir -p $DEBUG_DIR
  2. Agent invoked
  3. Agent may or may not write files
  4. If no files: empty $DEBUG_DIR remains

Lazy Creation (RIGHT):
  1. Command setup: DEBUG_DIR="${TOPIC_PATH}/debug" (path only, NO mkdir)
  2. Agent invoked with DEBUG_DIR path
  3. Agent calls ensure_artifact_directory("$DEBUG_DIR/analysis.md") before writing
  4. If no files: no $DEBUG_DIR created at all
```

### Integration with Existing Infrastructure

**Existing Functions** (no changes needed):
```bash
# unified-location-detection.sh line 400
ensure_artifact_directory() {
  local file_path="$1"
  local parent_dir=$(dirname "$file_path")
  [ -d "$parent_dir" ] || mkdir -p "$parent_dir"
  return 0
}

# unified-location-detection.sh line 413
create_topic_structure() # Creates ONLY topic root
```

**Required Changes**:
1. Audit /debug command for eager mkdir calls (should find none)
2. Audit debug-analyst agent for ensure_artifact_directory() usage
3. Add integration test to detect empty directories
4. Update agent behavioral template to mandate ensure_artifact_directory()

## Implementation Phases

### Phase 1: Fix Block 2a Missing Library [COMPLETE]
dependencies: []

**Objective**: Add `workflow-initialization.sh` sourcing to Block 2a to make `initialize_workflow_paths` available
**Complexity**: Low
**Estimated Duration**: 0.5 hours

Tasks:
- [x] **Task 1.1**: Add workflow-initialization.sh sourcing to Block 2a
  - File: `.claude/commands/debug.md`
  - Location: Lines 287-290
  - Change:
  ```bash
  # Current (Block 2a, lines 286-289) - INCOMPLETE
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null

  # Fixed - Add missing library with fail-fast
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
    echo "ERROR: Failed to source state-persistence.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-state-machine.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
    echo "ERROR: Failed to source error-handling.sh" >&2
    exit 1
  }
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
    echo "ERROR: Failed to source workflow-initialization.sh" >&2
    exit 1
  }
  ```
- [x] **Task 1.2**: Add defensive check for initialize_workflow_paths availability
- [x] **Task 1.3**: Test /debug with valid input to confirm no exit code 127 errors

Testing:
```bash
# Test: Execute /debug with valid input
/debug "Test issue description" --complexity 2

# Verify no exit code 127 errors
/errors --command /debug --since 10m | grep -c "exit code 127"
# Expected: 0
```

### Phase 2: Add Structured Validation Error Logging [COMPLETE]
dependencies: [1]

**Objective**: Make input validation failures queryable via /errors command
**Complexity**: Medium
**Estimated Duration**: 1.5 hours

Tasks:
- [x] **Task 2.1**: Update input validation block to log errors
  - File: `.claude/commands/debug.md`
  - Location: Lines 61-66
  - Change:
  ```bash
  # Current (lines 61-66) - No structured logging
  if [ -z "$ISSUE_DESCRIPTION" ]; then
    echo "ERROR: Issue description required"
    echo "USAGE: /debug <issue-description>"
    exit 1
  fi

  # Fixed - Add structured error logging
  if [ -z "$ISSUE_DESCRIPTION" ]; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Issue description is required" \
      "bash_block_1" \
      "$(jq -n --arg args "$*" --argjson count $# \
         '{user_args: $args, provided_args_count: $count}')"

    cat <<'EOF' >&2
ERROR: Issue description required

USAGE: /debug <issue-description> [--file <path>] [--complexity 1-4]

EXAMPLES:
  /debug "Build command fails with exit code 127"
  /debug "Agent not returning expected output" --complexity 3
  /debug "Parser error in test suite" --file tests/parser-test.sh
EOF
    exit 1
  fi
  ```
- [x] **Task 2.2**: Update complexity validation to log structured errors
- [x] **Task 2.3**: Update file validation to log structured errors
- [x] **Task 2.4**: Verify validation errors appear in /errors output

Testing:
```bash
# Trigger validation error with empty input
/debug "" 2>/dev/null || true

# Query for validation errors
/errors --type validation_error --command /debug --since 5m
# Expected: Error entry visible
```

### Phase 3: Lazy Directory Creation Enforcement [COMPLETE]
dependencies: [1]

**Objective**: Ensure no empty directories by enforcing lazy creation pattern
**Complexity**: Medium
**Estimated Duration**: 3.0 hours

#### Rationale

Instead of documenting that empty directories are "by design", we enforce a better pattern: directories are created ONLY when files are written. This eliminates the need for:
- Documentation explaining empty directories
- Cleanup scripts or processes
- User confusion about empty directories

#### Tasks

- [x] **Task 3.1**: Audit /debug command for eager mkdir calls
  - File: `.claude/commands/debug.md`
  - Action: Search for `mkdir -p.*_DIR` patterns
  - Expected: No matches (command should only assign paths, not create directories)
  - Verification: `grep 'mkdir -p "\$.*_DIR"' .claude/commands/debug.md`

- [x] **Task 3.2**: Audit debug-analyst agent for ensure_artifact_directory() usage
  - File: `.claude/agents/debug-analyst.md`
  - Action: Verify agent calls `ensure_artifact_directory()` before writing to DEBUG_DIR
  - If Missing: Add mandatory call before file writes
  - Change:
  ```markdown
  # In debug-analyst.md behavioral guidelines

  ## File Writing Protocol

  Before writing ANY file to DEBUG_DIR, RESEARCH_DIR, or PLANS_DIR:

  1. Source the unified-location-detection library:
     ```bash
     source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
     ```

  2. Call ensure_artifact_directory() with the full file path:
     ```bash
     ensure_artifact_directory "${DEBUG_DIR}/001_analysis.md" || {
       echo "ERROR: Failed to create directory for analysis" >&2
       exit 1
     }
     ```

  3. Write file using Write tool (directory now guaranteed to exist)

  **CRITICAL**: Never call `mkdir -p` directly. Always use ensure_artifact_directory().
  ```

- [x] **Task 3.3**: Update agent behavioral template
  - File: `.claude/docs/guides/templates/_template-agent-behavioral.md` (create if missing)
  - Add: Mandatory ensure_artifact_directory() section
  - Content:
  ```markdown
  ## Directory Creation (MANDATORY)

  This agent MUST follow the lazy directory creation pattern:

  - **NEVER** call `mkdir -p` directly for artifact directories
  - **ALWAYS** call `ensure_artifact_directory("$FILE_PATH")` before writing
  - Directories are created ONLY when files are written

  ### Example
  ```bash
  # WRONG
  mkdir -p "$DEBUG_DIR"
  # Write file later...

  # RIGHT
  ensure_artifact_directory "${DEBUG_DIR}/001_analysis.md"
  # Write file immediately after
  ```
  ```

- [x] **Task 3.4**: Create integration test for empty directory detection
  - File: `.claude/tests/integration/test_no_empty_directories.sh` (new)
  - Purpose: Fail CI if empty artifact directories detected
  - Implementation:
  ```bash
  #!/usr/bin/env bash
  # Test: Verify no empty artifact directories after workflow execution

  set -e

  CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"
  SPECS_DIR="${CLAUDE_PROJECT_DIR}/.claude/specs"

  # Find empty artifact subdirectories
  EMPTY_DIRS=$(find "$SPECS_DIR" -type d -name "reports" -empty 2>/dev/null)
  EMPTY_DIRS+=$(find "$SPECS_DIR" -type d -name "plans" -empty 2>/dev/null)
  EMPTY_DIRS+=$(find "$SPECS_DIR" -type d -name "debug" -empty 2>/dev/null)
  EMPTY_DIRS+=$(find "$SPECS_DIR" -type d -name "summaries" -empty 2>/dev/null)

  if [ -n "$EMPTY_DIRS" ]; then
    echo "ERROR: Empty artifact directories detected:"
    echo "$EMPTY_DIRS"
    echo ""
    echo "This indicates a lazy directory creation violation."
    echo "Directories should be created ONLY when files are written."
    echo ""
    echo "Fix: Ensure agents call ensure_artifact_directory() before writing files."
    exit 1
  fi

  echo "PASS: No empty artifact directories found"
  exit 0
  ```

- [x] **Task 3.5**: Add test to CI validation
  - File: `.claude/scripts/validate-all.sh`
  - Add: Call to test_no_empty_directories.sh

- [x] **Task 3.6**: Audit research-specialist agent for ensure_artifact_directory() usage
  - File: `.claude/agents/research-specialist.md`
  - Same pattern as Task 3.2

- [x] **Task 3.7**: Audit plan-architect agent for ensure_artifact_directory() usage
  - File: `.claude/agents/plan-architect.md`
  - Same pattern as Task 3.2

Testing:
```bash
# Test 1: Run test suite
bash .claude/tests/integration/test_no_empty_directories.sh

# Test 2: Execute /debug workflow that produces no debug artifacts
/debug "Simple analysis that needs no debug files" --complexity 1

# Test 3: Verify no empty debug/ directory created
find .claude/specs -type d -name "debug" -empty
# Expected: No output (no empty directories)

# Test 4: Execute /debug workflow that produces debug artifacts
/debug "Complex issue requiring debug analysis" --complexity 3

# Test 5: Verify debug/ directory exists WITH files
ls -la .claude/specs/*/debug/
# Expected: Files present in debug/ directories
```

### Phase 4: Documentation Standards Alignment [COMPLETE]
dependencies: [3]

**Objective**: Remove conflicting guidance from documentation files and strengthen cross-references to enforce lazy directory creation uniformly across all future development
**Complexity**: Low
**Estimated Duration**: 1.5 hours

#### Rationale

The research (001_lazy_directory_creation_standards.md) revealed that comprehensive lazy directory creation documentation already exists in `code-standards.md` (lines 68-147) and `directory-protocols.md` (lines 196-370). However, three documentation files contain conflicting guidance that contradicts the standard. Additionally, `command-authoring.md` lacks a cross-reference to the lazy creation standard. This phase ensures documentation consistency so future development follows the correct pattern.

#### Tasks

- [x] **Task 4.1**: Fix conflicting guidance in spec_updater_guide.md
  - File: `.claude/docs/workflows/spec_updater_guide.md`
  - Location: Line 534
  - Current (WRONG): "Always create topic directories with full subdirectory structure"
  - Change: Replace with cross-reference to code-standards.md lazy directory creation section
  - New Content:
  ```markdown
  Create only the topic root directory. Subdirectories (plans/, reports/, debug/, summaries/)
  are created lazily by agents when files are written. See [Directory Creation Anti-Patterns]
  (../reference/standards/code-standards.md#directory-creation-anti-patterns) for details.
  ```

- [x] **Task 4.2**: Fix conflicting guidance in orchestration-troubleshooting.md
  - File: `.claude/docs/guides/orchestration/orchestration-troubleshooting.md`
  - Location: Lines 538-566
  - Current (WRONG): "Option 1: Pre-create directory structure before agent invocation"
  - Change: Remove pre-creation as a valid troubleshooting option, replace with ensure_artifact_directory() pattern
  - New Content:
  ```markdown
  **Directory Creation Issues**

  If agents fail to create directories:
  1. Ensure agent sources unified-location-detection.sh
  2. Use `ensure_artifact_directory("$FILE_PATH")` before writing files
  3. Never pre-create directory structures - directories are created lazily at write-time

  See [Directory Creation Anti-Patterns](../../reference/standards/code-standards.md#directory-creation-anti-patterns)
  for the correct pattern.
  ```

- [x] **Task 4.3**: Fix conflicting guidance in creating-orchestrator-commands.md
  - File: `.claude/docs/guides/orchestration/creating-orchestrator-commands.md`
  - Location: Line 300
  - Current (WRONG): "REQUIRED: Create reports directory (specs/NNN_topic/reports/)"
  - Change: Clarify that directories are created lazily by agents, not by commands
  - New Content:
  ```markdown
  **Directory Creation**: Orchestrator commands should NOT create artifact subdirectories
  (reports/, plans/, debug/). These are created lazily by agents via `ensure_artifact_directory()`
  when files are written. Commands only create the topic root directory.
  ```

- [x] **Task 4.4**: Add cross-reference in command-authoring.md
  - File: `.claude/docs/reference/standards/command-authoring.md`
  - Location: Add new section after existing content
  - Purpose: Direct command authors to the lazy directory creation standard
  - New Content:
  ```markdown
  ## Directory Creation

  Commands MUST follow the lazy directory creation pattern:

  - **DO**: Create topic root directory (`specs/NNN_topic/`)
  - **DO NOT**: Create artifact subdirectories (`reports/`, `plans/`, `debug/`, `summaries/`)
  - **DELEGATE**: Let agents create subdirectories via `ensure_artifact_directory()` at write-time

  This ensures directories exist only when they contain files. See [Directory Creation Anti-Patterns]
  (code-standards.md#directory-creation-anti-patterns) for complete guidance and examples.
  ```

- [x] **Task 4.5**: Verify no other conflicting documentation exists
  - Action: Search for "mkdir -p" and "pre-create" patterns in .claude/docs/
  - Command: `grep -rn "mkdir -p\|pre-create" .claude/docs/ | grep -v "ensure_artifact"`
  - Expected: No results showing eager directory creation as valid pattern
  - If Found: Add to task list for remediation

Testing:
```bash
# Test 1: Verify no conflicting guidance remains
grep -rn "create.*full.*subdirectory\|pre-create.*directory\|REQUIRED.*Create.*directory" .claude/docs/
# Expected: No matches (all conflicting guidance removed)

# Test 2: Verify cross-references exist
grep -l "code-standards.md#directory-creation" .claude/docs/reference/standards/command-authoring.md
# Expected: Match found (cross-reference added)

# Test 3: Verify spec_updater_guide.md updated
grep -n "created lazily\|ensure_artifact_directory" .claude/docs/workflows/spec_updater_guide.md
# Expected: Match found (new content present)

# Test 4: Documentation link validation
# Ensure all new cross-reference links resolve correctly
for file in .claude/docs/workflows/spec_updater_guide.md \
            .claude/docs/guides/orchestration/orchestration-troubleshooting.md \
            .claude/docs/guides/orchestration/creating-orchestrator-commands.md \
            .claude/docs/reference/standards/command-authoring.md; do
  echo "Checking: $file"
  grep -o '\[.*\](.*\.md[^)]*' "$file" | while read link; do
    target=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/' | sed 's/#.*//')
    dir=$(dirname "$file")
    [ -f "$dir/$target" ] || [ -f ".claude/docs/$target" ] && echo "  OK: $target" || echo "  BROKEN: $target"
  done
done
```

## Testing Strategy

### Unit Tests
```bash
# Test ensure_artifact_directory function
test_ensure_artifact_directory() {
  source .claude/lib/core/unified-location-detection.sh

  TEST_DIR=$(mktemp -d)
  TEST_PATH="${TEST_DIR}/nested/path/file.md"

  ensure_artifact_directory "$TEST_PATH"

  [ -d "$(dirname "$TEST_PATH")" ] && echo "PASS" || echo "FAIL"

  rm -rf "$TEST_DIR"
}
```

### Integration Tests
```bash
# Test full workflow with lazy creation validation
test_lazy_creation_workflow() {
  # Run /debug
  /debug "Test issue" --complexity 2

  # Find the created topic directory
  TOPIC=$(ls -td .claude/specs/*debug* 2>/dev/null | head -1)

  # Verify no empty subdirectories
  EMPTY=$(find "$TOPIC" -type d -empty)

  [ -z "$EMPTY" ] && echo "PASS: No empty directories" || {
    echo "FAIL: Empty directories found: $EMPTY"
    return 1
  }
}
```

### Regression Tests
```bash
# Test that originally empty debug/ directories are no longer created
test_no_empty_debug_dir() {
  # Run debug workflow that produces reports but no debug artifacts
  /debug "Simple issue" --complexity 1

  TOPIC=$(ls -td .claude/specs/*simple* 2>/dev/null | head -1)

  # debug/ should NOT exist if no files written
  [ ! -d "${TOPIC}/debug" ] && echo "PASS: No empty debug/ created" || {
    # If it exists, must have files
    [ -n "$(ls -A "${TOPIC}/debug" 2>/dev/null)" ] && echo "PASS: debug/ has files" || {
      echo "FAIL: Empty debug/ directory exists"
      return 1
    }
  }
}
```

## Documentation Requirements

- [ ] Update agent behavioral guidelines with ensure_artifact_directory() requirement
- [ ] Create agent template with mandatory lazy creation section
- [ ] Cross-reference systematic plan for full remediation
- [ ] Remove conflicting guidance from spec_updater_guide.md (Phase 4, Task 4.1)
- [ ] Remove conflicting guidance from orchestration-troubleshooting.md (Phase 4, Task 4.2)
- [ ] Remove conflicting guidance from creating-orchestrator-commands.md (Phase 4, Task 4.3)
- [ ] Add lazy directory creation cross-reference to command-authoring.md (Phase 4, Task 4.4)

## Dependencies

### External Dependencies
- None (all changes internal to .claude/)

### Plan Dependencies
- **Prerequisite**: None (can be executed independently)
- **Complement**: Systematic Infrastructure Fix (105) Phase 4 Task 4.2
  - This plan's Phase 1 can be superseded by 105's full three-tier remediation
  - This plan's Phases 2-3 are NOT covered by 105 and remain necessary

### Phase Dependencies (Parallel Execution)
- Phase 1: Independent (immediate fix)
- Phase 2: Depends on Phase 1 (validation logging needs working error infrastructure)
- Phase 3: Can run parallel with Phase 2 (agent audit is independent)
- Phase 4: Depends on Phase 3 (documentation updates should reflect finalized enforcement pattern)

## Risk Assessment

### Low Risk
- **Phase 1**: Adding library sourcing is straightforward
  - Mitigation: Test with single /debug invocation before proceeding
- **Task 3.1-3.2**: Auditing existing code, no runtime changes
  - Mitigation: Document findings before making changes

### Medium Risk
- **Phase 2**: Validation logging changes could affect error handling flow
  - Mitigation: Test with both valid and invalid inputs
  - Rollback: Revert to current validation if issues arise
- **Task 3.3-3.7**: Agent behavioral changes could affect artifact creation
  - Mitigation: Test each agent individually after changes
  - Rollback: Revert agent file to backup
- **Phase 4**: Documentation changes could create broken cross-references
  - Mitigation: Link validation test (Task 4.5 testing block)
  - Rollback: Git revert individual documentation files

## Timeline

- **Phase 1**: Day 1 (0.5 hours)
- **Phase 2**: Day 1-2 (1.5 hours)
- **Phase 3**: Day 2-3 (3.0 hours)
- **Phase 4**: Day 3-4 (1.5 hours)

**Total**: 6.5 hours over 4 days

**Note**: If systematic plan (105) Phase 4 Task 4.2 is executed first, Phase 1 of this plan can be skipped (will be covered by full three-tier remediation). Phases 2-4 remain necessary regardless.

## Appendix: Why Lazy Creation is Elegant

### Problem: Empty Directories
Traditional approach creates directories during setup, resulting in empty directories when:
- Workflows fail before writing files
- Agents complete without producing artifacts
- Users cancel workflows midway

### Traditional Solutions (Inelegant)
1. **Cleanup scripts**: Periodically delete empty directories (reactive, not preventive)
2. **Documentation**: Explain that empty directories are "normal" (confusing)
3. **Marker files**: Create .gitkeep files (clutters repository)

### Lazy Creation (Elegant)
- Directories created ONLY at write-time via `ensure_artifact_directory()`
- If no files written, no directory exists
- No cleanup needed
- No documentation needed
- Clear signal: directory exists = files exist

### Implementation Cost
- Zero new infrastructure (functions already exist)
- Audit and enforce existing pattern
- One-time agent updates
- Integration test prevents regression

---

**Plan Created**: 2025-11-21
**Plan Revised**: 2025-11-21 (Added Phase 4: Documentation Standards Alignment)
**Plan Type**: Debug Strategy (Targeted Fixes + Enforcement + Documentation Alignment)
**Implementation Method**: Sequential phases with parallel option for Phases 2-3
**Expected Outcome**: /debug command functional with proper error logging, no empty directories, and consistent documentation standards

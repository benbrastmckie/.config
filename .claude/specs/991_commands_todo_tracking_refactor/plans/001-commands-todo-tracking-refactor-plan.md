# Commands TODO.md Integration Refactor - Implementation Plan

## Metadata
- **Date**: 2025-12-01
- **Feature**: Command TODO.md Integration via Delegation Pattern
- **Scope**: Add TODO.md integration to /repair, /errors, /debug commands using delegation pattern
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 48.0
- **Research Reports**:
  - [Gap Analysis and Implementation Strategy](/home/benjamin/.config/.claude/specs/991_commands_todo_tracking_refactor/reports/001-gap-analysis-and-implementation-strategy.md)

## Overview

This plan implements TODO.md integration for commands that currently lack it (/repair, /errors, /debug) using the proven delegation pattern already successfully deployed in /plan, /build, /research, and /revise. Based on comprehensive gap analysis, this refactor adds minimal helper functions to todo-functions.sh and integrates TODO.md updates at appropriate command completion points.

**Key Architectural Decision**: Use delegation pattern (trigger `/todo` regeneration) rather than incremental update API. This approach:
- Respects existing classification authority (plan metadata is source of truth)
- Preserves manually curated Backlog and Saved sections automatically
- Maintains consistency with 4 existing successful implementations
- Avoids synchronization complexity and race conditions
- Requires minimal library changes (3 helper functions vs 6+ complex update functions)

**Scope**: High and medium priority integrations only. /expand and /collapse are excluded per research recommendation (structural changes don't warrant TODO.md updates).

## Research Summary

Research report [001-gap-analysis-and-implementation-strategy.md](/home/benjamin/.config/.claude/specs/991_commands_todo_tracking_refactor/reports/001-gap-analysis-and-implementation-strategy.md) provides comprehensive analysis revealing:

**Current State**:
- 4 commands already integrated: /plan, /build, /research, /revise (all use delegation pattern)
- Library (todo-functions.sh) designed for full regeneration, not incremental updates
- Specification's incremental update API doesn't exist and conflicts with current architecture

**Key Findings**:
1. **Delegation Pattern Works**: Existing implementations are simple, consistent, and respect architectural boundaries
2. **Incremental Updates Not Needed**: Full regeneration is fast (<1s) and safer than targeted section updates
3. **Library Gap**: Only need 3 query/utility functions, not 6+ complex update functions
4. **Integration Priorities**:
   - High: /repair, /errors (similar structure to /plan)
   - Medium: /debug (handles standalone case)
   - Low: /expand, /collapse (skip - structural changes only)

**Architectural Conflicts Avoided**:
- Full regeneration vs incremental updates (delegation resolves)
- Classification authority synchronization (plan metadata remains source of truth)
- Race conditions from concurrent TODO.md writes (single delegated writer)

## Success Criteria

- [ ] Library functions added: `plan_exists_in_todo()`, `get_plan_current_section()`, `trigger_todo_update()`
- [ ] /repair command triggers TODO.md update after plan creation
- [ ] /errors command triggers TODO.md update in report mode only
- [ ] /debug command triggers TODO.md update after debug report creation
- [ ] All TODO.md updates preserve Backlog and Saved sections
- [ ] Test coverage ≥85% for new library functions
- [ ] Integration tests pass for all 3 commands
- [ ] Documentation updated (library README, integration guide, standards)
- [ ] No regression in existing /plan, /build, /research, /revise TODO.md integration

## Technical Design

### Architecture

**Delegation Pattern** (used by all commands):
```bash
# Pattern: Update plan metadata → Trigger /todo regeneration
update_plan_status "$plan_path" "[NOT STARTED]"  # or other status
trigger_todo_update "repair plan created"        # delegates to /todo
```

**Delegation Flow**:
1. Command creates/modifies plan or report
2. Command updates plan metadata (Status field) if applicable
3. Command calls `trigger_todo_update(reason)`
4. Helper function invokes `/todo` command silently
5. `/todo` scans specs/, classifies plans by metadata, regenerates TODO.md
6. Backlog and Saved sections automatically preserved

**Why Delegation Over Incremental Updates**:
- Single source of truth: Plan metadata Status field determines TODO.md section
- Automatic preservation: `/todo` command already preserves manually curated sections
- No synchronization: Plan metadata changes always reflected in next regeneration
- Simpler code: 3 functions vs 6+ complex update functions
- Lower risk: No race conditions or desynchronization bugs
- Proven pattern: 4 commands already using successfully

### Component Design

**Phase 1: Library Additions** (todo-functions.sh)

Three new functions for query and delegation:

```bash
# plan_exists_in_todo(plan_path)
# Check if plan appears in TODO.md (any section)
# Returns: 0 if found, 1 if not found
# Usage: if plan_exists_in_todo "$plan_path"; then echo "Found"; fi

# get_plan_current_section(plan_path)
# Find which TODO.md section contains the plan
# Returns: section name (e.g., "Not Started", "In Progress") or empty
# Usage: SECTION=$(get_plan_current_section "$plan_path")

# trigger_todo_update(reason)
# Delegate to /todo command for full TODO.md regeneration
# Arguments: $1 - Reason for update (for console output)
# Returns: 0 on success, 1 on failure (non-blocking)
# Usage: trigger_todo_update "repair plan created"
```

**Phase 2: /repair Integration**

Integration point: After `PLAN_CREATED` signal verification (Block 3)

```bash
# After plan-architect returns PLAN_CREATED signal
if [[ "$AGENT_OUTPUT" =~ PLAN_CREATED:\ (.+) ]]; then
  PLAN_PATH="${BASH_REMATCH[1]}"

  # Existing verification code...

  # NEW: Trigger TODO.md update
  trigger_todo_update "repair plan created"
fi
```

Classification: Repair plans have `Status: [NOT STARTED]` → TODO.md Not Started section

**Phase 3: /errors Integration**

Integration point: After error analysis report creation (Block 2, report mode only)

```bash
# After errors-analyst completes in report mode
if [ "$QUERY_MODE" = "false" ]; then
  # Report created - trigger TODO.md update
  trigger_todo_update "error analysis report"
else
  # Query mode - no files created, skip TODO.md update
  echo "Query mode - no TODO.md update needed"
fi
```

Classification: Error reports with no plan → TODO.md Research section (auto-detected)

**Phase 4: /debug Integration**

Integration point: After debug report creation, handles standalone case

```bash
# After debug-analyst returns DEBUG_COMPLETE signal
if [[ "$AGENT_OUTPUT" =~ DEBUG_COMPLETE:\ \{report_path:\ (.+)\} ]]; then
  DEBUG_REPORT="${BASH_REMATCH[1]}"

  # Existing verification code...

  # NEW: Check if topic has plan
  TOPIC_PATH=$(dirname "$(dirname "$DEBUG_REPORT")")
  PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f 2>/dev/null | head -1)

  if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    echo "✓ Debug report linked to plan: $(basename "$PLAN_FILE")"
    trigger_todo_update "debug report added to plan"
  else
    echo "NOTE: Debug report is standalone (no plan in topic)"
    trigger_todo_update "standalone debug report"
  fi
fi
```

Classification:
- If plan exists: Debug report becomes artifact (TODO.md shows under plan)
- If no plan: Debug report → TODO.md Research section (standalone research)

### Error Handling

**Library Function Failures**:
- `trigger_todo_update()` is non-blocking (returns 1 on failure but doesn't exit)
- Warning message logged to stderr if /todo delegation fails
- Command continues (TODO.md update failure doesn't block command completion)

**Edge Cases**:
1. **TODO.md doesn't exist**: `/todo` creates it (standard behavior)
2. **Plan path not found**: `/todo` skips missing plans gracefully
3. **/todo command fails**: Warning logged, command continues
4. **Concurrent updates**: Delegation pattern avoids race (sequential /todo calls)

### Integration Points Summary

| Command | Integration Point | Trigger Condition | Expected TODO.md Section |
|---------|------------------|-------------------|-------------------------|
| /repair | After PLAN_CREATED signal | Always (plan creation) | Not Started |
| /errors | After error analysis | Report mode only | Research (no plan) |
| /debug | After DEBUG_COMPLETE signal | Always (report creation) | Research or under plan |
| /plan | ✅ Existing | Always | Not Started |
| /build | ✅ Existing | Start and completion | In Progress → Completed |
| /research | ✅ Existing | Always | Research |
| /revise | ✅ Existing | Always | Status unchanged |

## Implementation Phases

### Phase 1: Library Enhancements [COMPLETE]
dependencies: []

**Objective**: Add 3 helper functions to todo-functions.sh for query and delegation support

**Complexity**: Low

**Tasks**:
- [x] Add `plan_exists_in_todo()` function to todo-functions.sh (file: /home/benjamin/.config/.claude/lib/todo/todo-functions.sh)
  - Searches TODO.md for plan path in any section
  - Handles both absolute and relative path formats
  - Returns 0 if found, 1 if not found
- [x] Add `get_plan_current_section()` function to todo-functions.sh
  - Uses awk to find section header containing plan path
  - Returns section name (e.g., "Not Started") or empty string
  - Handles edge case: TODO.md doesn't exist
- [x] Add `trigger_todo_update()` function to todo-functions.sh
  - Delegates to `/todo` command via `bash -c` pattern
  - Accepts reason argument for console output
  - Non-blocking: logs warning on failure but returns success
  - Matches pattern used by /plan, /build, /research, /revise
- [x] Add unit tests for new functions (file: /home/benjamin/.config/.claude/tests/lib/test_todo_functions.sh)
  - Test `plan_exists_in_todo()` with existing/missing plans
  - Test `get_plan_current_section()` across all sections
  - Test `trigger_todo_update()` delegation and error handling

**Testing**:
```bash
# Unit tests for new library functions
bash /home/benjamin/.config/.claude/tests/lib/test_todo_functions.sh

# Verify function signatures and error handling
source /home/benjamin/.config/.claude/lib/todo/todo-functions.sh
plan_exists_in_todo "/path/to/plan.md" || echo "Expected failure for missing plan"
```

**Expected Duration**: 3 hours

### Phase 2: /repair Command Integration [COMPLETE]
dependencies: [1]

**Objective**: Add TODO.md update trigger after repair plan creation

**Complexity**: Low

**Tasks**:
- [x] Source todo-functions.sh in /repair command setup block (file: /home/benjamin/.config/.claude/commands/repair.md)
  - Add to Block 1 sourcing section with other libraries
  - Include fail-fast error handler per code standards
- [x] Add `trigger_todo_update()` call after PLAN_CREATED signal verification (Block 3)
  - Location: After plan path extraction and verification
  - Call: `trigger_todo_update "repair plan created"`
  - Add console output: "✓ Updated TODO.md"
- [x] Verify plan metadata includes `Status: [NOT STARTED]` for correct classification
  - Check plan-architect output includes status field
  - Ensure /todo command classifies as "Not Started" section
- [x] Create integration test for /repair TODO.md workflow (file: /home/benjamin/.config/.claude/tests/integration/test_repair_todo_integration.sh)
  - Create test error pattern
  - Run /repair command
  - Verify TODO.md updated with repair plan in Not Started section
  - Verify Backlog section preserved

**Testing**:
```bash
# Integration test
bash /home/benjamin/.config/.claude/tests/integration/test_repair_todo_integration.sh

# Manual verification
/repair --since 1h --complexity 2
grep "repair plan" /home/benjamin/.config/.claude/TODO.md
```

**Expected Duration**: 2 hours

### Phase 3: /errors Command Integration [COMPLETE]
dependencies: [1]

**Objective**: Add TODO.md update trigger after error analysis report creation (report mode only)

**Complexity**: Low

**Tasks**:
- [x] Source todo-functions.sh in /errors command setup block (file: /home/benjamin/.config/.claude/commands/errors.md)
  - Add to Block 1 sourcing section
  - Include fail-fast error handler
- [x] Add conditional `trigger_todo_update()` call in report mode (Block 2)
  - Location: After errors-analyst completes successfully
  - Condition: `if [ "$QUERY_MODE" = "false" ]; then`
  - Call: `trigger_todo_update "error analysis report"`
  - Skip in query mode (no files created)
- [x] Verify research-only directory detection works (topic with reports/, no plans/)
  - Confirm /todo command adds to Research section
  - Test with /errors creating standalone error analysis
- [x] Create integration test for /errors TODO.md workflow (file: /home/benjamin/.config/.claude/tests/integration/test_errors_todo_integration.sh)
  - Test report mode: verify TODO.md updated with research entry
  - Test query mode: verify TODO.md not updated (no files)
  - Verify research-only directory classification

**Testing**:
```bash
# Integration test
bash /home/benjamin/.config/.claude/tests/integration/test_errors_todo_integration.sh

# Manual verification - report mode
/errors --command /build --summary
grep -A2 "## Research" /home/benjamin/.config/.claude/TODO.md

# Manual verification - query mode (no TODO.md update)
/errors --since 1h --limit 5
# Should NOT modify TODO.md
```

**Expected Duration**: 2 hours

### Phase 4: /debug Command Integration [COMPLETE]
dependencies: [1]

**Objective**: Add TODO.md update trigger after debug report creation, handle standalone case

**Complexity**: Medium

**Tasks**:
- [x] Source todo-functions.sh in /debug command setup block (file: /home/benjamin/.config/.claude/commands/debug.md)
  - Add to Block 1 sourcing section
  - Include fail-fast error handler
- [x] Add standalone detection logic after DEBUG_COMPLETE signal
  - Extract topic path from debug report path
  - Search for plan files in topic's plans/ directory
  - Handle case: no plans/ directory (standalone debug)
  - Handle case: plans/ empty (standalone debug)
- [x] Add `trigger_todo_update()` call with context-aware message
  - If plan exists: "debug report added to plan"
  - If standalone: "standalone debug report"
  - Add informative console output for both cases
- [x] Verify artifact linking when plan exists
  - Debug report should appear under plan in TODO.md
  - Verify /todo command discovers debug reports as artifacts
- [x] Create integration test for /debug TODO.md workflow (file: /home/benjamin/.config/.claude/tests/integration/test_debug_todo_integration.sh)
  - Test with existing plan: verify debug report linked
  - Test standalone: verify research entry created
  - Verify artifact discovery by /todo command

**Testing**:
```bash
# Integration test
bash /home/benjamin/.config/.claude/tests/integration/test_debug_todo_integration.sh

# Manual verification - with plan
cd /home/benjamin/.config/.claude/specs/968_plan_standards_alignment
/debug "plan phase markers missing"
grep -A5 "968_plan_standards_alignment" /home/benjamin/.config/.claude/TODO.md

# Manual verification - standalone
/debug "general error pattern investigation"
grep -A2 "## Research" /home/benjamin/.config/.claude/TODO.md
```

**Expected Duration**: 3 hours

### Phase 5: Testing and Documentation [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Comprehensive testing and documentation for TODO.md integration pattern

**Complexity**: Low

**Tasks**:
- [x] Create command-todo integration guide (file: /home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md)
  - Document delegation pattern with examples
  - Explain when to call trigger_todo_update()
  - Provide integration checklist for command authors
  - Include troubleshooting section
- [x] Update library README (file: /home/benjamin/.config/.claude/lib/todo/README.md)
  - Document 3 new query/utility functions
  - Add delegation pattern examples
  - Update integration examples for commands
- [x] Update TODO organization standards (file: /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md)
  - Add "Automatic Updates" section listing 7 integrated commands
  - Document delegation pattern as standard integration method
  - Add troubleshooting guidance
- [x] Run regression tests for existing integrations
  - Test /plan TODO.md integration still works
  - Test /build TODO.md integration (start and completion)
  - Test /research TODO.md integration
  - Test /revise TODO.md integration
  - Verify Backlog preservation across all workflows
- [x] Run full integration test suite
  - All Phase 2-4 integration tests pass
  - Library unit tests pass
  - Regression tests pass
  - Test coverage ≥85%
- [x] Validate TODO.md structure after all commands
  - Run validation script: `bash /home/benjamin/.config/.claude/scripts/validate-todo-structure.sh`
  - Verify all 7 sections present
  - Verify checkbox conventions correct
  - Verify artifact links valid

**Testing**:
```bash
# Full test suite
bash /home/benjamin/.config/.claude/tests/lib/test_todo_functions.sh
bash /home/benjamin/.config/.claude/tests/integration/test_repair_todo_integration.sh
bash /home/benjamin/.config/.claude/tests/integration/test_errors_todo_integration.sh
bash /home/benjamin/.config/.claude/tests/integration/test_debug_todo_integration.sh

# Regression tests
bash /home/benjamin/.config/.claude/tests/integration/test_plan_todo_integration.sh
bash /home/benjamin/.config/.claude/tests/integration/test_build_todo_integration.sh

# Validation
bash /home/benjamin/.config/.claude/scripts/validate-todo-structure.sh
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing (Phase 1)

**Scope**: New library functions in todo-functions.sh

**Test Coverage**:
- `plan_exists_in_todo()`:
  - Plan exists in TODO.md → returns 0
  - Plan missing from TODO.md → returns 1
  - TODO.md doesn't exist → returns 1
  - Relative vs absolute path handling
- `get_plan_current_section()`:
  - Plan in each section (Not Started, In Progress, etc.) → correct section name
  - Plan not in TODO.md → empty string
  - Multiple plans in same section → correct section for target
- `trigger_todo_update()`:
  - Successful delegation → console output "✓ Updated TODO.md"
  - /todo command fails → warning logged, returns success (non-blocking)
  - Reason argument included in output

**Test Framework**: Bash test scripts with assertion helpers

### Integration Testing (Phases 2-4)

**Scope**: Command workflows with TODO.md updates

**Test Scenarios**:

1. **/repair Integration** (Phase 2):
   - Run /repair with test error pattern
   - Verify TODO.md updated with repair plan in Not Started section
   - Verify plan metadata has correct status
   - Verify Backlog section preserved

2. **/errors Integration** (Phase 3):
   - Report mode: Verify research entry created
   - Query mode: Verify TODO.md not modified
   - Verify research-only directory classification

3. **/debug Integration** (Phase 4):
   - With existing plan: Verify debug report linked to plan
   - Standalone: Verify research entry created
   - Verify artifact discovery

**Test Framework**: Integration test scripts that create test specs, run commands, verify TODO.md

### Regression Testing (Phase 5)

**Scope**: Ensure existing integrations still work

**Commands to Test**:
- /plan: Not Started section entry
- /build: In Progress → Completed transition
- /research: Research section entry
- /revise: Status unchanged, artifacts updated

**Critical Checks**:
- Backlog section preservation
- Saved section preservation
- Manual edits not overwritten
- Date grouping in Completed section
- Artifact links auto-discovered

### Test Coverage Targets

- Unit tests: ≥90% for new library functions
- Integration tests: 100% command integration points covered
- Regression tests: All 4 existing integrations verified
- Overall: ≥85% test coverage

## Documentation Requirements

### New Documentation

1. **Command-TODO Integration Guide** (new file)
   - Location: /home/benjamin/.config/.claude/docs/guides/development/command-todo-integration-guide.md
   - Audience: Command authors
   - Content:
     - Delegation pattern overview
     - Integration checklist
     - Code examples from /plan, /repair, /errors, /debug
     - When to call trigger_todo_update()
     - Testing integration changes
     - Troubleshooting common issues

### Updated Documentation

2. **Library README**
   - File: /home/benjamin/.config/.claude/lib/todo/README.md
   - Updates:
     - Add "Query Functions" section documenting plan_exists_in_todo(), get_plan_current_section()
     - Add "Delegation Utilities" section documenting trigger_todo_update()
     - Update integration examples to reference new functions
     - Add delegation pattern explanation

3. **TODO Organization Standards**
   - File: /home/benjamin/.config/.claude/docs/reference/standards/todo-organization-standards.md
   - Updates:
     - Expand "Usage by Commands" section to list all 7 integrated commands
     - Add /repair, /errors, /debug to automatic update table
     - Document delegation pattern as standard integration method
     - Add troubleshooting section for TODO.md update failures

### Documentation Format

- Follow CommonMark specification
- Use code blocks with bash syntax highlighting
- Include cross-references to related documentation
- Add navigation links (parent, related documents)
- Use Unicode box-drawing for diagrams if needed
- No emojis (UTF-8 encoding issues)
- No historical commentary per development philosophy

## Dependencies

### External Dependencies

None. All functionality implemented using existing:
- Bash built-ins (if, while, grep, awk)
- /todo command (already exists)
- unified-location-detection.sh (already exists)
- error-handling.sh (already exists)

### Internal Dependencies

**Phase 1 is prerequisite for Phases 2-4**:
- Phases 2, 3, 4 depend on Phase 1 (library functions must exist)
- Phase 5 depends on Phases 2, 3, 4 (testing requires implementations)

**No circular dependencies**:
- Library functions are independent (can be tested in isolation)
- Command integrations are independent (can be implemented in parallel after Phase 1)
- Documentation can be drafted during implementation

### File Modification Permissions

All target files are in user's .claude/ directory with write permissions:
- /home/benjamin/.config/.claude/lib/todo/todo-functions.sh (library)
- /home/benjamin/.config/.claude/commands/repair.md (command)
- /home/benjamin/.config/.claude/commands/errors.md (command)
- /home/benjamin/.config/.claude/commands/debug.md (command)
- Documentation files (all in docs/ subdirectories)

## Risk Assessment

### Low-Risk Changes

- Adding query functions (plan_exists_in_todo, get_plan_current_section): Read-only, no side effects
- Adding trigger_todo_update(): Wraps existing pattern, non-blocking on failure
- /repair integration: Identical pattern to /plan (proven)
- /errors integration: Conditional update only in report mode (safe)

### Medium-Risk Changes

- /debug standalone detection: Handles edge case (no plan exists)
  - Mitigation: Explicit edge case handling, informative logging
  - Fallback: Still triggers TODO.md update (research section)

### Low-Risk Impact

- Library function failures: Non-blocking (commands continue)
- /todo delegation failure: Logged warning, doesn't block command
- TODO.md structure issues: Validation script detects, user corrects

### Rollback Plan

If integration causes issues:

1. **Command-level rollback**: Comment out `trigger_todo_update()` calls
2. **Library rollback**: `git checkout HEAD -- /home/benjamin/.config/.claude/lib/todo/todo-functions.sh`
3. **TODO.md restore**: `git checkout HEAD -- /home/benjamin/.config/.claude/TODO.md` (if manually curated sections lost)

All changes are additive (no existing functionality removed), making rollback safe.

## Excluded from Scope

Based on research recommendations, the following are explicitly excluded:

1. **/expand and /collapse commands**: Structural changes don't warrant TODO.md updates (research section 4.5)
2. **Incremental update API**: Delegation pattern is simpler and safer (research section 3.1)
3. **Performance optimization**: /todo regeneration is already fast (<1s) (research section 7.4)
4. **Enhanced logging**: Basic reason argument sufficient for v1 (research section 7.4)

These exclusions reduce scope from 6 days to 4 days (research Appendix A) while maintaining all high and medium priority integrations.

## Success Metrics

- ✅ All 3 high/medium priority commands integrated (/repair, /errors, /debug)
- ✅ 7 total commands with TODO.md integration (4 existing + 3 new)
- ✅ Test coverage ≥85%
- ✅ Zero regression in existing integrations
- ✅ Backlog and Saved sections preserved in all workflows
- ✅ Documentation complete and reviewed
- ✅ Integration guide available for future command authors

## Implementation Notes

**Clean-Break Development**: This refactor adds new functionality without modifying existing integration patterns. The delegation pattern is consistent across all 7 commands.

**Error Logging**: All command integrations use error-handling.sh for error logging. TODO.md update failures are logged as `state_error` type with command context.

**Code Standards**: All bash blocks follow three-tier sourcing pattern with fail-fast handlers for Tier 1 libraries (unified-location-detection, error-handling).

**Output Formatting**: Console output uses single summary line per integration: "✓ Updated TODO.md (reason)". No verbose output unless TODO.md update fails.

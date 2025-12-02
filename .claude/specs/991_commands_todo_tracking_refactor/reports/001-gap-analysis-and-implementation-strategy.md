# Commands TODO.md Integration - Gap Analysis and Implementation Strategy

## Executive Summary

This report analyzes the current state of TODO.md integration across `.claude/commands/` and provides a comprehensive implementation strategy to achieve the requirements specified in [990_commands_todo_tracking_integration/reports/001](../../../990_commands_todo_tracking_integration/reports/001-i-want-all-commands-in-claudecommands.md).

**Current State**: Commands have basic TODO.md references in code but **no automated integration library exists**. The specification assumes `todo-functions.sh` contains helper functions like `update_todo_section()`, `mark_plan_completed()`, etc., but analysis shows the current library only provides `/todo` command utilities (project scanning, classification, file generation).

**Key Finding**: This is a **library creation task**, not just a refactor. We must build the integration API from scratch.

## 1. Current State Analysis

### 1.1 Existing todo-functions.sh Library

**Location**: `/home/benjamin/.config/.claude/lib/todo/todo-functions.sh`

**Current Capabilities**:
- Project discovery (`scan_project_directories`, `find_plans_in_topic`)
- Artifact collection (`find_related_artifacts`)
- Plan metadata extraction (`extract_plan_metadata`, `classify_status_from_metadata`)
- Section classification (`categorize_plan`)
- TODO.md file regeneration (`update_todo_file`, `extract_backlog_section`)
- Cleanup utilities (for `/todo --clean` mode)

**Functions NOT in Library** (specified but missing):
- `update_todo_section(section, plan_path, title, description, artifacts_json)`
- `move_plan_between_sections(plan_path, from_section, to_section)`
- `add_artifact_to_plan(plan_path, artifact_type, artifact_path)`
- `mark_plan_completed(plan_path, title, description)`
- `mark_plan_in_progress(plan_path, title, description)`
- `mark_plan_abandoned(plan_path, reason, superseded_by_path)`
- `plan_exists_in_todo(plan_path)`
- `get_plan_current_section(plan_path)`
- `validate_todo_structure()` - **Exists but different signature**
- `preserve_backlog_section()` - Exists as `extract_backlog_section()`

**Gap**: The specification assumes an incremental update API that doesn't exist. Current library is designed for **full regeneration**, not targeted section updates.

### 1.2 Commands with Existing TODO.md Integration

**Analysis of command code reveals**:

1. **/plan** (line 1501):
   ```bash
   bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
   echo "✓ Updated TODO.md"
   ```
   - **Pattern A**: Delegates to `/todo` command for full regeneration
   - Location: After `PLAN_CREATED` signal in Block 3

2. **/build** (lines 347, 1061):
   ```bash
   # Pattern B: START (after update_plan_status "IN PROGRESS")
   bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
   echo "✓ Updated TODO.md"

   # Pattern C: COMPLETION (after update_plan_status "COMPLETE")
   bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
   echo "✓ Updated TODO.md"
   ```
   - Runs twice: at workflow start (→ In Progress) and completion (→ Completed)
   - Uses checkbox-utils.sh to update plan metadata, then triggers `/todo` regeneration

3. **/research** (line 1235):
   ```bash
   # Pattern D: After REPORT_CREATED signal
   bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
   echo "✓ Updated TODO.md"
   ```

4. **/revise** (line 1293):
   ```bash
   # Pattern G: After PLAN_REVISED signal
   bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || true
   echo "✓ Updated TODO.md"
   ```

**Current Pattern**: All commands delegate to `/todo` command for **full TODO.md regeneration** after updating plan metadata or creating artifacts. This is inefficient but functional.

### 1.3 Commands WITHOUT TODO.md Integration

Based on file grepping and code analysis:

- **/debug** - No TODO.md updates (should add debug artifacts to existing plans)
- **/repair** - No TODO.md updates (should add repair plans to Not Started)
- **/errors** - No TODO.md updates (should add error analysis artifacts)
- **/expand** - No TODO.md updates (should add expansion notes)
- **/collapse** - No TODO.md updates (should remove expansion notes)

### 1.4 Completion Signals Analysis

Commands use these signals for TODO.md integration triggers:

| Command | Signal | Location | Current TODO.md Integration |
|---------|--------|----------|----------------------------|
| `/plan` | `PLAN_CREATED: <path>` | End of Block 3 | ✅ Yes (delegates to /todo) |
| `/build` | `IMPLEMENTATION_COMPLETE` + `summary_path: <path>` | End of Block 4 | ✅ Yes (delegates to /todo twice) |
| `/research` | `REPORT_CREATED: <path>` | End of Block 2 | ✅ Yes (delegates to /todo) |
| `/revise` | `PLAN_REVISED: <path>` | End of Block 6 | ✅ Yes (delegates to /todo) |
| `/debug` | `DEBUG_COMPLETE: {report_path}` | After debug-analyst | ❌ No TODO.md integration |
| `/repair` | Similar to /plan | After plan creation | ❌ No TODO.md integration |
| `/errors` | Various (query/report modes) | After errors-analyst | ❌ No TODO.md integration |
| `/expand` | No explicit signal | After expansion | ❌ No TODO.md integration |
| `/collapse` | No explicit signal | After collapse | ❌ No TODO.md integration |

## 2. Requirements Analysis from Specification

### 2.1 Core Requirements

The specification defines 8 command integration points with specific TODO.md update patterns:

**Category 1: Plan Creation Commands** (2 commands)
- `/plan` - Add to **Not Started** after plan creation ✅ (implemented)
- `/research` - Add to **Research** section ✅ (implemented)

**Category 2: Plan Implementation Commands** (1 command)
- `/build` - Move to **In Progress** at start, **Completed** at finish ✅ (implemented)

**Category 3: Plan Revision Commands** (1 command)
- `/revise` - Add revision artifacts, keep current section ✅ (implemented)

**Category 4: Debugging Commands** (1 command)
- `/debug` - Add debug artifacts to existing plan ❌ (missing)

**Category 5: Error Analysis Commands** (2 commands)
- `/errors` - Add error report artifacts (report mode only) ❌ (missing)
- `/repair` - Add repair plan to **Not Started** ❌ (missing)

**Category 6: Plan Structure Commands** (2 commands)
- `/expand` - Add expansion note to plan description ❌ (missing)
- `/collapse` - Remove expansion note from plan description ❌ (missing)

**Category 7: TODO Management Commands** (2 commands)
- `/todo` - IS the manager (no integration needed) ✅
- `/todo --clean` - Built-in regeneration ✅

**Category 8: Utility Commands** (2 commands)
- `/setup` - No TODO.md integration needed ✅
- `/convert-docs` - No TODO.md integration needed ✅

### 2.2 Integration Complexity Tiers

**Tier 1: Simple Delegation (Current Pattern)**
- Commands: `/plan`, `/build`, `/research`, `/revise`
- Implementation: Call `/todo` command for full regeneration
- Pros: Simple, consistent, respects manual Backlog/Saved edits
- Cons: Regenerates entire TODO.md (slow for large projects)
- Status: ✅ **Already implemented**

**Tier 2: Direct Library Integration (Specification Proposal)**
- Commands: `/debug`, `/errors`, `/repair`, `/expand`, `/collapse`
- Implementation: Use helper functions for targeted updates
- Pros: Faster, more granular control
- Cons: **Requires library functions that don't exist yet**
- Status: ❌ **Blocked on library creation**

## 3. Gap Analysis

### 3.1 Library API Gap

The specification assumes these functions exist:

```bash
# Missing functions (need to be created):
update_todo_section(section, plan_path, title, description, artifacts_json)
move_plan_between_sections(plan_path, from_section, to_section)
add_artifact_to_plan(plan_path, artifact_type, artifact_path)
mark_plan_completed(plan_path, title, description)
mark_plan_in_progress(plan_path, title, description)
mark_plan_abandoned(plan_path, reason, superseded_by_path)
plan_exists_in_todo(plan_path)
get_plan_current_section(plan_path)
```

**Critical Design Decision Required**:

The specification's incremental update approach has **architectural conflicts** with the current TODO.md design:

1. **Conflict: Full Regeneration vs Incremental Updates**
   - Current `/todo` command: Scans all specs/, classifies plans, regenerates entire TODO.md
   - Specification: Commands make targeted section updates
   - **Issue**: If `/todo` runs after targeted updates, it will overwrite them with classification results

2. **Conflict: Classification Authority**
   - Current: Plan metadata (`Status: [COMPLETE]`) is source of truth
   - Specification: Commands update TODO.md sections directly
   - **Issue**: Plan status and TODO.md section can become desynchronized

3. **Conflict: Preserved Sections**
   - Current: Backlog and Saved are preserved during regeneration
   - Specification: Incremental updates don't touch these sections
   - **Issue**: Both approaches preserve manually curated sections, but different mechanisms

### 3.2 Integration Opportunities

**Observation**: The current delegation pattern (`bash -c "cd ... && .claude/commands/todo.md"`) works well because:

1. Respects manual Backlog/Saved edits (preserved sections)
2. Ensures TODO.md reflects plan metadata (single source of truth)
3. Handles artifact discovery automatically
4. Simple to implement and maintain

**Alternative Approach**: Instead of creating incremental update functions, we could:

1. **Extend checkbox-utils.sh** to update plan metadata (`Status:` field)
2. **Keep delegation pattern** for TODO.md updates
3. **Add TODO.md delegation** to remaining commands

This approach:
- ✅ Simpler (no new library needed)
- ✅ Consistent with existing pattern
- ✅ Respects classification authority (plan metadata)
- ✅ Preserves manually curated sections
- ❌ Slightly slower (full regeneration each time)

### 3.3 Command-Specific Integration Analysis

#### 3.3.1 /debug Command

**Current State**: Creates debug reports in `debug/001-*.md` but doesn't update TODO.md

**Specification Requirement**:
```bash
# Add debug report as artifact to existing plan
add_artifact_to_plan "$PLAN_FILE" "Debug" "$DEBUG_REPORT"
```

**Issue**: Debug reports are typically **standalone** (no plan context). The spec assumes we can find a related plan:

```bash
TOPIC_PATH=$(dirname "$(dirname "$DEBUG_REPORT")")
PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f | head -1)
```

**Risk**: What if there's no plan? (debug analysis of ad-hoc issues)

**Recommendation**:
- If plan exists: Add to Research section (debug reports are analysis, not plans)
- If no plan: Log info message (no TODO.md update needed)
- Use delegation pattern: Update plan status if needed, then call `/todo`

#### 3.3.2 /errors Command

**Current State**: Two modes - query (no files) and report (creates error analysis)

**Specification Requirement**: Report mode should add error analysis to Research section

**Issue**: `/errors` report mode creates topic directories with reports but no plans (same as `/research`). Current `/todo` command already handles this via research-only directory detection.

**Recommendation**:
- Add `/todo` delegation call after report creation
- No library changes needed (research section auto-detection already works)

#### 3.3.3 /repair Command

**Current State**: Creates error analysis reports + repair plan

**Specification Requirement**: Add repair plan to **Not Started** section

**Issue**: `/repair` is identical to `/plan` workflow (research → plan creation). Should already be handled by plan classification.

**Recommendation**:
- Add `/todo` delegation call after plan creation (same as `/plan`)
- Ensure plan metadata has `Status: [NOT STARTED]` for correct classification

#### 3.3.4 /expand and /collapse Commands

**Current State**: Modify plan structure (phase expansion/collapse) but don't update TODO.md

**Specification Requirement**: Add/remove expansion notes in plan description

**Issue**: Expansion is **structural change**, not status change. Current TODO.md format shows:
```markdown
- [ ] **Plan Title** - Description [path]
  - Phase 3/8 complete
```

The "expansion note" would go in description field, which is auto-extracted from plan metadata.

**Recommendation**:
- Update plan **description** metadata when expanding/collapsing
- Use delegation pattern: Update plan → call `/todo` to regenerate
- Alternative: Skip TODO.md updates (expansion is internal detail)

## 4. Implementation Strategy

### 4.1 Recommended Approach: Delegation-First Pattern

**Rationale**: The current delegation pattern is simpler, more maintainable, and respects architectural boundaries. Creating incremental update functions introduces synchronization complexity without significant performance benefit.

### 4.2 Phase 1: Library Enhancements (1-2 days)

**Goal**: Add minimal helper functions for common operations

**New Functions to Add** (`todo-functions.sh`):

```bash
# plan_exists_in_todo(plan_path)
# Check if plan appears in any TODO.md section
# Returns: 0 if found, 1 if not found
plan_exists_in_todo() {
  local plan_path="$1"
  local todo_path="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

  [ ! -f "$todo_path" ] && return 1

  # Search for plan path in TODO.md (handle both relative and absolute)
  local rel_path=$(get_relative_path "$plan_path")
  grep -qF "[$rel_path]" "$todo_path"
}

# get_plan_current_section(plan_path)
# Find which section contains the plan
# Returns: section name or empty string
get_plan_current_section() {
  local plan_path="$1"
  local todo_path="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

  [ ! -f "$todo_path" ] && return 0

  local rel_path=$(get_relative_path "$plan_path")

  # Use awk to find which section contains this plan
  awk -v plan="$rel_path" '
    /^## / { section = substr($0, 4); next }
    $0 ~ plan { print section; exit }
  ' "$todo_path"
}

# trigger_todo_update(reason)
# Delegate to /todo command for full regeneration
# Arguments: $1 - Reason for update (for logging)
trigger_todo_update() {
  local reason="${1:-manual trigger}"

  # Silent delegation to /todo command
  bash -c "cd \"$CLAUDE_PROJECT_DIR\" && .claude/commands/todo.md" 2>/dev/null || {
    echo "WARNING: TODO.md update failed ($reason)" >&2
    return 1
  }

  echo "✓ Updated TODO.md ($reason)"
  return 0
}
```

**Note**: These are query/utility functions only. All updates go through `/todo` delegation.

### 4.3 Phase 2: High-Priority Command Integration (2-3 days)

**Commands**: `/repair`, `/errors` (already have basic structure similar to `/plan`)

#### /repair Integration

**Location**: After plan creation (same pattern as `/plan`)

```bash
# After PLAN_CREATED verification
trigger_todo_update "repair plan created"
```

**Files to Modify**: `.claude/commands/repair.md`

**Test**: Run `/repair --since 1h`, verify repair plan appears in TODO.md Not Started section

#### /errors Integration

**Location**: Block 2 (after report creation, report mode only)

```bash
# After error analysis report created
if [ "$QUERY_MODE" = "false" ]; then
  # Report mode - update TODO.md
  trigger_todo_update "error analysis report"
fi
```

**Files to Modify**: `.claude/commands/errors.md`

**Test**: Run `/errors --command /build`, verify research entry in TODO.md Research section

### 4.4 Phase 3: Medium-Priority Command Integration (2-3 days)

**Commands**: `/debug`

#### /debug Integration

**Location**: After debug report creation

```bash
# After debug report created and verified
TOPIC_PATH=$(dirname "$(dirname "$DEBUG_REPORT")")
PLAN_FILE=$(find "$TOPIC_PATH/plans" -name '*.md' -type f | head -1)

if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
  # Plan exists - update will be reflected in TODO.md
  trigger_todo_update "debug report added"
  echo "✓ Debug report linked to plan: $(basename "$PLAN_FILE")"
else
  echo "NOTE: Debug report is standalone (no plan found in $TOPIC_PATH)"
  # Still trigger update to add to Research section
  trigger_todo_update "standalone debug report"
fi
```

**Files to Modify**: `.claude/commands/debug.md`

**Test**: Run `/debug` on existing plan topic, verify debug report appears as artifact

### 4.5 Phase 4: Low-Priority Command Integration (1-2 days)

**Commands**: `/expand`, `/collapse`

**Decision Point**: These commands modify plan structure (internal detail). Do we need TODO.md updates?

**Option A - Skip Integration**:
- Expansion notes don't affect plan status/progress
- TODO.md shows phase completion, not structural details
- Minimal user value

**Option B - Add Expansion Notes**:
```bash
# After expansion
trigger_todo_update "plan structure expanded"
```

**Recommendation**: **Option A** (skip integration). Expansion is an internal structural detail that doesn't warrant TODO.md updates.

### 4.6 Testing Strategy

**Unit Tests** (for new library functions):
```bash
# test_todo_functions.sh

test_plan_exists_in_todo() {
  # Setup: Create test TODO.md with known plan
  local test_todo=$(mktemp)
  echo "## Not Started" > "$test_todo"
  echo "- [ ] Test Plan [.claude/specs/999_test/plans/001.md]" >> "$test_todo"

  # Test: Check existing plan
  export CLAUDE_PROJECT_DIR="/tmp/test"
  cp "$test_todo" "/tmp/test/.claude/TODO.md"

  if plan_exists_in_todo "/tmp/test/.claude/specs/999_test/plans/001.md"; then
    echo "PASS"
  else
    echo "FAIL: Plan should exist"
  fi

  # Cleanup
  rm "$test_todo"
}

test_get_plan_current_section() {
  # Setup: Create test TODO.md
  # Test: Verify section detection
  # Cleanup
}
```

**Integration Tests** (for command workflows):
```bash
# test_repair_todo_integration.sh

test_repair_todo_integration() {
  # Create test error pattern
  # Run /repair command
  # Verify TODO.md updated with repair plan in Not Started section
  # Verify plan metadata correct
}
```

**Regression Tests** (ensure existing workflows still work):
```bash
# test_plan_todo_integration.sh

test_plan_workflow_preserves_backlog() {
  # Add items to Backlog section manually
  # Run /plan command
  # Verify Backlog section unchanged
}
```

### 4.7 Documentation Updates

**Files to Update**:

1. `.claude/docs/guides/development/command-todo-integration-guide.md` (new)
   - Integration patterns for command authors
   - When to call `trigger_todo_update()`
   - Testing checklist

2. `.claude/lib/todo/README.md`
   - Document new query functions
   - Update integration examples

3. `.claude/docs/reference/standards/todo-organization-standards.md`
   - Add "Automatic Updates" section
   - List which commands update TODO.md
   - Explain delegation pattern

## 5. Risk Assessment

### 5.1 Low-Risk Changes

- Adding `/todo` delegation calls to commands (same pattern as existing)
- Query functions (`plan_exists_in_todo`, `get_plan_current_section`)
- Integration for `/repair` and `/errors` (similar to `/plan`)

### 5.2 Medium-Risk Changes

- `/debug` integration (handles missing plan case)
- Library function additions (must maintain backward compatibility)

### 5.3 High-Risk Changes (Avoided)

- Creating incremental update API (architectural conflicts)
- Modifying `/todo` regeneration logic (complex, many dependencies)
- Changing classification authority (would break existing workflows)

### 5.4 Rollback Plan

If integration causes issues:

1. **Command-level rollback**: Comment out `trigger_todo_update()` calls
2. **Library rollback**: Revert `todo-functions.sh` to previous version
3. **TODO.md restore**: Use git to restore previous TODO.md

All changes are additive (no existing functionality removed), making rollback safe.

## 6. Alternative: Incremental Update API (Not Recommended)

If stakeholders insist on the specification's incremental update approach, here's the implementation:

### 6.1 Incremental Update Functions

```bash
# update_todo_section(section, plan_path, title, description, artifacts_json)
update_todo_section() {
  local section="$1"
  local plan_path="$2"
  local title="$3"
  local description="$4"
  local artifacts_json="${5:-{}}"

  local todo_path="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

  # 1. Load existing TODO.md
  # 2. Parse sections
  # 3. Remove plan from any existing section
  # 4. Add plan to target section with new metadata
  # 5. Preserve Backlog/Saved sections
  # 6. Write updated TODO.md

  # ISSUE: This duplicates /todo command logic
  # ISSUE: Race conditions if /todo runs concurrently
  # ISSUE: Classification authority conflict (plan metadata vs manual placement)
}
```

### 6.2 Why This Is Not Recommended

1. **Code Duplication**: Reimplements `/todo` command logic
2. **Synchronization Complexity**: Plan metadata and TODO.md can diverge
3. **Race Conditions**: Multiple commands updating TODO.md simultaneously
4. **Maintenance Burden**: Two code paths for TODO.md updates
5. **Testing Complexity**: Must test incremental updates + regeneration interactions
6. **No Performance Benefit**: `/todo` regeneration is already fast (<1s for typical projects)

## 7. Recommendations

### 7.1 Immediate Actions (Phase 1 - Week 1)

1. **Add query functions** to `todo-functions.sh`:
   - `plan_exists_in_todo()`
   - `get_plan_current_section()`
   - `trigger_todo_update()` (delegation wrapper)

2. **Document delegation pattern** in command authoring guide

3. **Create integration tests** for `/plan`, `/build`, `/research` (verify existing integration)

### 7.2 High-Priority Integration (Phase 2 - Week 2)

1. **Integrate `/repair`**: Add `trigger_todo_update()` after plan creation
2. **Integrate `/errors`**: Add `trigger_todo_update()` in report mode
3. **Test end-to-end workflows** with TODO.md verification

### 7.3 Medium-Priority Integration (Phase 3 - Week 3)

1. **Integrate `/debug`**: Handle standalone debug reports
2. **Add comprehensive tests** for debug workflow

### 7.4 Optional Enhancements (Phase 4 - Week 4)

1. **Performance optimization**: Cache TODO.md parsing results (if needed)
2. **Enhanced logging**: Track which command triggered TODO.md update
3. **Validation hooks**: Verify TODO.md structure after updates

### 7.5 Documentation Deliverables

1. **Command TODO Integration Guide** (new) - For command authors
2. **TODO.md Organization Standards Update** - Add automatic update section
3. **Library README Update** - Document new query functions
4. **Testing Guide** - How to test TODO.md integration

## 8. Conclusion

**Key Decision**: Use **delegation pattern** instead of incremental update API.

**Rationale**:
- Simpler implementation (no new complex library)
- Respects architectural boundaries (plan metadata is source of truth)
- Preserves manually curated sections (Backlog, Saved)
- Consistent with existing successful pattern
- Lower risk, easier to test and maintain

**Implementation Timeline**: 4 weeks total

**Success Criteria**:
- ✅ All 9 command integration points implemented
- ✅ TODO.md automatically updated on plan/report creation
- ✅ Backlog and Saved sections preserved
- ✅ Comprehensive test coverage
- ✅ Documentation complete

**Next Steps**: Create implementation plan from this research → `/plan` command with gap analysis insights.

## Appendix A: Command Integration Checklist

| Command | Priority | Integration Point | Estimated Effort | Dependencies |
|---------|----------|-------------------|------------------|--------------|
| `/plan` | N/A | Already implemented | 0 days | None (complete) |
| `/build` | N/A | Already implemented | 0 days | None (complete) |
| `/research` | N/A | Already implemented | 0 days | None (complete) |
| `/revise` | N/A | Already implemented | 0 days | None (complete) |
| `/repair` | High | After plan creation | 0.5 days | Phase 1 helpers |
| `/errors` | High | Report mode only | 0.5 days | Phase 1 helpers |
| `/debug` | Medium | After report creation | 1 day | Phase 1 helpers |
| `/expand` | Low | Optional (skip?) | 0.5 days | Phase 1 helpers |
| `/collapse` | Low | Optional (skip?) | 0.5 days | Phase 1 helpers |

**Total Estimated Effort**: 3-4 days (excluding testing and documentation)

## Appendix B: Library Function Comparison

| Function (Specification) | Exists? | Current Name | Recommended Action |
|-------------------------|---------|--------------|-------------------|
| `update_todo_section()` | ❌ | N/A | Replace with `trigger_todo_update()` |
| `move_plan_between_sections()` | ❌ | N/A | Replace with `trigger_todo_update()` |
| `add_artifact_to_plan()` | ❌ | N/A | Replace with `trigger_todo_update()` |
| `mark_plan_completed()` | ❌ | N/A | Update plan metadata + `trigger_todo_update()` |
| `mark_plan_in_progress()` | ❌ | N/A | Update plan metadata + `trigger_todo_update()` |
| `mark_plan_abandoned()` | ❌ | N/A | Update plan metadata + `trigger_todo_update()` |
| `plan_exists_in_todo()` | ❌ | N/A | ✅ **Add as query function** |
| `get_plan_current_section()` | ❌ | N/A | ✅ **Add as query function** |
| `validate_todo_structure()` | ✅ | Same name | Keep existing (different use case) |
| `preserve_backlog_section()` | ✅ | `extract_backlog_section()` | Keep existing name |

**Note**: Delegation pattern eliminates need for 6 of 10 specified functions, significantly reducing implementation complexity.

## Appendix C: Research-Only Directory Detection

Current `/todo` command already handles research-only directories automatically:

```bash
# From todo-functions.sh update_todo_file() function (lines 789-814)

# Check if directory has reports/ but no plans/ (or empty plans/)
if [ -d "$reports_dir" ]; then
  local has_plans=false
  if [ -d "$plans_dir" ]; then
    if ls "$plans_dir"/*.md >/dev/null 2>&1; then
      has_plans=true
    fi
  fi

  # If no plans, this is a research-only directory
  if [ "$has_plans" = "false" ]; then
    local research_entry
    research_entry=$(format_research_entry "$topic_name" "$topic_path")
    research_entries+=("$research_entry")
  fi
fi
```

This means `/research`, `/errors`, and `/debug` (standalone mode) automatically appear in Research section **without any integration code** - they just need to trigger TODO.md regeneration.

**Implication**: Integration for research-producing commands is even simpler than specification suggests.

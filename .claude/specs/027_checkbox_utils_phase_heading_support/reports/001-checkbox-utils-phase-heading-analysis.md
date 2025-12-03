# Checkbox Utils Phase Heading Support Analysis

## Metadata
- **Date**: 2025-12-03
- **Agent**: research-specialist
- **Topic**: Make checkbox-utils.sh support both ## Phase and ### Phase heading formats
- **Report Type**: codebase analysis

## Executive Summary

The checkbox-utils.sh library currently hardcodes `### Phase` (h3) patterns in AWK scripts and grep commands, causing silent failures when processing plans that use `## Phase` (h2) format. Analysis reveals that 5 newer plans use `## Phase` format while the majority (10+) use the standard `### Phase` format. The library needs to support both formats dynamically to ensure backwards compatibility and future flexibility. Six AWK patterns and three grep commands require modification to detect heading levels or support both formats explicitly.

## Findings

### Current Implementation Analysis

**File**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` (696 lines)

The library contains hardcoded `### Phase` patterns in the following locations:

#### AWK Pattern Matches (6 instances)

1. **Line 204** - `mark_phase_complete()` function:
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

2. **Line 249** - `mark_phase_complete()` function (second awk block):
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

3. **Line 420** - `remove_status_marker()` function:
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

4. **Line 454** - `add_in_progress_marker()` function:
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

5. **Line 493** - `add_complete_marker()` function:
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

6. **Line 564** - `verify_phase_complete()` function:
   ```awk
   /^### Phase / {
     phase_field = $3
     gsub(/:/, "", phase_field)
   ```

#### Grep Pattern Matches (3 instances)

1. **Line 538** - `add_not_started_markers()` function:
   ```bash
   local count=$(grep -c "^### Phase.*\[NOT STARTED\]" "$plan_path" 2>/dev/null || echo "0")
   ```

2. **Line 665** - `check_all_phases_complete()` function:
   ```bash
   local total_phases=$(grep -c "^### Phase [0-9]" "$plan_path" 2>/dev/null || echo "0")
   ```

3. **Line 673** - `check_all_phases_complete()` function:
   ```bash
   local complete_phases=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$plan_path" 2>/dev/null || echo "0")
   ```

#### Special Case: `add_not_started_markers()` AWK Pattern

Line 523 has a different pattern that includes the colon:
```awk
/^### Phase [0-9]+:/ {
  # Check if line already has a status marker
```

### Plan Format Distribution

#### Plans Using `## Phase` (h2 format) - 5 files

1. `/home/benjamin/.config/.claude/specs/026_lean_command_orchestrator_implementation/plans/001-lean-command-orchestrator-implementation-plan.md`
2. `/home/benjamin/.config/.claude/specs/024_repair_repair_20251202_152829/plans/001-repair-repair-20251202-152829-plan.md`
3. `/home/benjamin/.config/.claude/specs/023_repair_test_20251202_150525/plans/001-repair-test-20251202-150525-plan.md`
4. `/home/benjamin/.config/.claude/specs/018_repair_repair_20251202_120554/plans/001-repair-repair-20251202-120554-plan.md`
5. `/home/benjamin/.config/.claude/specs/005_repair_research_20251201_212513/plans/001-repair-research-20251201-212513-plan.md`

**Pattern**: Newer plans and auto-generated repair plans use `## Phase` format.

#### Plans Using `### Phase` (h3 format) - 10+ files

1. `/home/benjamin/.config/.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md`
2. `/home/benjamin/.config/.claude/specs/997_todo_update_pattern_fix/plans/001-todo-update-pattern-fix-plan.md`
3. And 8 more legacy plans...

**Pattern**: Standard format established by plan-architect agent, documented in plan-progress.md.

### Documentation Standards

**File**: `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md` (Lines 36-72)

Documentation exclusively shows `### Phase` format:
```markdown
### Phase 1: Setup [NOT STARTED]
### Phase 2: Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

**File**: `/home/benjamin/.config/.claude/agents/plan-architect.md` (Lines 557-560)

Plan-architect explicitly creates `### Phase` format:
```markdown
### Phase 1: Foundation [NOT STARTED]
### Phase 2: Core Implementation [NOT STARTED]
### Phase 3: Testing [NOT STARTED]
```

### Integration Points

**Consumers of checkbox-utils.sh**:

1. **implementation-executor.md** (Lines 72, 99, 153, 191-193)
   - Calls `add_in_progress_marker()` at phase start
   - Calls `add_complete_marker()` at phase end
   - Falls back to `mark_phase_complete()` on marker failure

2. **spec-updater.md** (Lines 407, 437, 489, 542-543)
   - Calls `mark_phase_complete()` for batch updates
   - Uses as fallback when `update_checkbox()` fails

3. **Test suites** (5 files)
   - `test_plan_progress_markers.sh` - All tests use `### Phase` format (Line 55, 81)
   - `test_implement_progress_tracking.sh` - Uses `### Phase` format
   - `test_hierarchy_updates.sh` - Tests hierarchy propagation
   - `test_plan_updates.sh` - Tests checkbox updates

### Silent Failure Impact

When checkbox-utils.sh functions encounter `## Phase` headings:

1. **AWK patterns fail to match** → Phase detection returns nothing
2. **Functions complete successfully** → No error raised (return 0)
3. **Status markers not applied** → Plans remain with old status
4. **No user-visible error** → Silent failure, hard to diagnose

**Example failure scenario**:
```bash
# Plan has: ## Phase 1: Setup [NOT STARTED]
add_in_progress_marker "plan.md" "1"
# Result: Returns 0 (success), but heading unchanged
# Expected: ## Phase 1: Setup [IN PROGRESS]
# Actual: ## Phase 1: Setup [NOT STARTED]
```

### Field Extraction Logic

Current AWK logic assumes field position based on heading level:

**For `### Phase 1: Setup`**:
- `$1` = `###`
- `$2` = `Phase`
- `$3` = `1:` (phase number extracted correctly)

**For `## Phase 1: Setup`**:
- `$1` = `##`
- `$2` = `Phase`
- `$3` = `1:` (same field position!)

**Key insight**: The phase number field position is the same for both formats. The issue is pattern matching, not field extraction.

## Recommendations

### 1. Dynamic Heading Level Detection (Recommended)

**Approach**: Modify AWK patterns to match both `^##+ Phase` formats dynamically.

**Pattern change**:
```awk
# Before
/^### Phase / {

# After
/^##+ Phase / {
```

**Benefits**:
- Single pattern matches both h2 and h3
- Future-proof for h4+ if needed
- Minimal code change

**Considerations**:
- Ensure field extraction still works (it should, since field position is identical)
- Test with both formats

### 2. Explicit Dual Pattern Support

**Approach**: Check for both patterns explicitly with OR logic.

**Pattern change**:
```awk
# Before
/^### Phase / {

# After
/^## Phase / || /^### Phase / {
```

**Benefits**:
- Explicit support visible in code
- Clear intent
- Easy to extend

**Considerations**:
- More verbose
- Requires updating 9 locations

### 3. Add Heading Level Auto-Detection Function

**Approach**: Create a new function to detect the heading level used in a plan file, then use that throughout.

**Implementation**:
```bash
detect_phase_heading_level() {
  local plan_path="$1"

  if grep -q "^## Phase [0-9]" "$plan_path" 2>/dev/null; then
    echo "##"
  elif grep -q "^### Phase [0-9]" "$plan_path" 2>/dev/null; then
    echo "###"
  else
    echo "###"  # Default to standard format
  fi
}
```

**Usage pattern**:
```bash
local heading_level=$(detect_phase_heading_level "$plan_path")
awk -v phase="$phase_num" -v level="$heading_level" '
  $0 ~ "^" level " Phase " {
    # Process phase heading
  }
' "$plan_path"
```

**Benefits**:
- Handles mixed formats (file-level detection)
- Central detection point
- Easy to add logging/warnings for inconsistent formats

**Considerations**:
- Adds function call overhead
- More complex implementation
- May not handle plans with mixed heading levels within same file

### 4. Update Test Suite

**Required changes**:

1. Add test cases for `## Phase` format to all test files
2. Create mixed-format test scenarios
3. Verify backwards compatibility with `### Phase` format

**Test files requiring updates**:
- `test_plan_progress_markers.sh` - Add h2 format test cases
- `test_implement_progress_tracking.sh` - Test with h2 plans
- `test_hierarchy_updates.sh` - Verify hierarchy works with both formats

### 5. Update Documentation

**Files to update**:

1. `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md`
   - Document that both formats are supported
   - Show examples of each format
   - Clarify that heading level is flexible

2. `/home/benjamin/.config/.claude/agents/plan-architect.md`
   - Note that `### Phase` is recommended but `## Phase` is supported
   - Explain when each format might be preferred

3. `/home/benjamin/.config/.claude/lib/plan/README.md`
   - Document checkbox-utils.sh heading level flexibility
   - Add examples of both formats

### 6. Backwards Compatibility Testing

**Critical test cases**:

1. Existing `### Phase` plans continue to work
2. New `## Phase` plans work correctly
3. Mixed format plans (if encountered) handled gracefully
4. Hierarchy propagation works for both formats
5. All status markers applied correctly for both formats

## References

### Code Files
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` - Main implementation (lines 204, 249, 420, 454, 493, 523, 538, 564, 665, 673)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` - Consumer (lines 72, 99, 153, 191-193)
- `/home/benjamin/.config/.claude/agents/spec-updater.md` - Consumer (lines 407, 437, 489, 542-543)

### Plan Files (Examples)
- `/home/benjamin/.config/.claude/specs/026_lean_command_orchestrator_implementation/plans/001-lean-command-orchestrator-implementation-plan.md` - Uses `## Phase` format
- `/home/benjamin/.config/.claude/specs/999_build_implement_persistence/plans/001-build-implement-persistence-plan.md` - Uses `### Phase` format

### Documentation
- `/home/benjamin/.config/.claude/docs/reference/standards/plan-progress.md` - Progress tracking standards
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Plan creation standards (lines 533-560)

### Test Files
- `/home/benjamin/.config/.claude/tests/progressive/test_plan_progress_markers.sh` - Status marker tests
- `/home/benjamin/.config/.claude/tests/integration/test_implement_progress_tracking.sh` - Integration tests
- `/home/benjamin/.config/.claude/tests/progressive/test_hierarchy_updates.sh` - Hierarchy tests

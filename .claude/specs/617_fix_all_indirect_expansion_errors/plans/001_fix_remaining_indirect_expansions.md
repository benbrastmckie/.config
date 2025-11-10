# Fix All Remaining Indirect Variable Expansion Errors

## Metadata
- **Date**: 2025-11-09
- **Feature**: Bug Fix - Complete Indirect Variable Expansion Cleanup
- **Scope**: Fix all remaining ${!VAR} and ${!ARRAY[@]} syntax errors across .claude/lib/ preventing /coordinate execution
- **Estimated Phases**: 4 phases
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Specs**:
  - 613 (Fixed coordinate.md handle_state_error function)
  - 582 (Previous history expansion research)

## Problem Statement

While spec 613 fixed the indirect variable expansion in `coordinate.md`, **multiple instances remain in library files** causing /coordinate to fail during workflow initialization.

### Error Evidence from coordinate_output.md

```
/run/current-system/sw/bin/bash: line 236: !: command not found
/run/current-system/sw/bin/bash: line 248: !: command not found

ERROR: TOPIC_PATH not set after workflow initialization
This indicates a bug in initialize_workflow_paths()
```

### Root Cause Analysis

The `!` character triggers bash history expansion errors even inside double quotes when scripts are executed in certain contexts. This affects two distinct patterns:

**Pattern 1: Array Index Iteration** (workflow-initialization.sh:291)
```bash
for i in "${!report_paths[@]}"; do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done
```

**Pattern 2: Associative Array Key Iteration** (context-pruning.sh, 6 instances)
```bash
for key in "${!PRUNED_METADATA_CACHE[@]}"; do
  # iterate over associative array keys
done
```

Both patterns fail with "!: command not found" errors during /coordinate execution.

## Impact

**Blocking Issues:**
- /coordinate command completely non-functional (workflow initialization fails)
- All multi-agent orchestration workflows blocked
- Phase 7 state-based refactor validation cannot be completed

**Scope of Problem:**
- 7 total instances across 2 critical library files
- Affects every /coordinate invocation (not just edge cases)
- Cannot be worked around without fixing the libraries

## Success Criteria

- [ ] All ${!array[@]} patterns replaced in workflow-initialization.sh
- [ ] All ${!array[@]} patterns replaced in context-pruning.sh
- [ ] /coordinate executes successfully through complete research workflow
- [ ] TOPIC_PATH properly initialized
- [ ] Array iteration logic works correctly (exports all array elements)
- [ ] Zero regressions in library functionality
- [ ] Pattern documented to prevent future occurrences

## Technical Analysis

### Affected Files and Instances

**File 1: `.claude/lib/workflow-initialization.sh`**
- **Line 291**: `for i in "${!report_paths[@]}"; do`
- **Usage**: Iterate over indexed array to export individual elements
- **Criticality**: HIGH - Blocks TOPIC_PATH initialization

**File 2: `.claude/lib/context-pruning.sh`**
- **Line 151**: `for key in "${!PRUNED_METADATA_CACHE[@]}"; do`
- **Line 246**: `for phase_id in "${!PHASE_METADATA_CACHE[@]}"; do`
- **Line 253**: `for key in "${!PRUNED_METADATA_CACHE[@]}"; do`
- **Line 315**: `for key in "${!PRUNED_METADATA_CACHE[@]}"; do`
- **Line 321**: `for key in "${!PHASE_METADATA_CACHE[@]}"; do`
- **Line 327**: `for key in "${!WORKFLOW_METADATA_CACHE[@]}"; do`
- **Usage**: Iterate over associative array keys
- **Criticality**: MEDIUM - Used in context management, may affect performance but not initialization

### Solution Approaches

#### For Indexed Arrays (workflow-initialization.sh)
Replace `"${!array[@]}"` with C-style for loop:

```bash
# Before (line 291):
for i in "${!report_paths[@]}"; do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done

# After:
array_length=${#report_paths[@]}
for ((i=0; i<array_length; i++)); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done
```

**Rationale:**
- C-style loops don't use `!` character
- Work with set -u (unbound variable checking)
- Same iteration behavior (0-based indices)
- Clear and readable

#### For Associative Arrays (context-pruning.sh)
Replace `"${!array[@]}"` with eval-based expansion:

```bash
# Before:
for key in "${!PRUNED_METADATA_CACHE[@]}"; do
  # use $key
done

# After:
# Use eval for associative array key expansion (safe: array name is known constant)
# Alternative ${!ARRAY[@]} syntax fails with history expansion errors
for key in $(eval echo "\${!PRUNED_METADATA_CACHE[@]}"); do
  # use $key
done
```

**Rationale:**
- eval is safe when array name is a known constant (not user input)
- Works with set -u mode
- Maintains associative array iteration semantics
- Consistent with 613 fix approach

### Why This Wasn't Caught Earlier

1. **Spec 613 focused only on coordinate.md**: Didn't audit library files
2. **Libraries sourced at runtime**: Errors only appear during actual execution
3. **Recent refactor**: State-based refactor (602) may have introduced new code paths triggering these libraries
4. **History expansion context-dependent**: May not fail in all execution environments

## Implementation Phases

### Phase 1: Fix workflow-initialization.sh Array Iteration [COMPLETED]
**Objective**: Replace indexed array iteration to fix TOPIC_PATH initialization
**Complexity**: Low
**Priority**: CRITICAL (blocks all /coordinate functionality)

**Tasks:**
- [x] **Locate Array Export Code**: Find the report_paths array export loop (line ~291)
- [x] **Replace with C-style Loop**: Update iteration to avoid `${!array[@]}` syntax
  ```bash
  # Around line 287-293 in workflow-initialization.sh

  # Before:
  export REPORT_PATHS_COUNT="${#report_paths[@]}"
  for i in "${!report_paths[@]}"; do
    export "REPORT_PATH_$i=${report_paths[$i]}"
  done

  # After:
  export REPORT_PATHS_COUNT="${#report_paths[@]}"
  # Use C-style for loop to avoid history expansion with ${!array[@]}
  array_length=${#report_paths[@]}
  for ((i=0; i<array_length; i++)); do
    export "REPORT_PATH_$i=${report_paths[$i]}"
  done
  ```
- [x] **Add Explanatory Comment**: Document why C-style loop is used
  ```bash
  # Use C-style for loop to avoid history expansion errors
  # The ${!array[@]} syntax triggers "!: command not found" in some bash contexts
  ```
- [x] **Verify Export Logic**: Ensure all array elements still exported correctly
  - Test with array of multiple elements
  - Verify REPORT_PATH_0, REPORT_PATH_1, etc. are exported
  - Check REPORT_PATHS_COUNT matches array length

**Testing:**
```bash
# Unit test: Verify array export with C-style loop
test_array_export() {
  source .claude/lib/workflow-initialization.sh

  # Create test array
  test_array=("path1" "path2" "path3")

  # Export using C-style loop
  export TEST_COUNT="${#test_array[@]}"
  array_length=${#test_array[@]}
  for ((i=0; i<array_length; i++)); do
    export "TEST_PATH_$i=${test_array[$i]}"
  done

  # Verify exports
  [ "$TEST_COUNT" -eq 3 ] || { echo "✗ Count wrong: $TEST_COUNT"; return 1; }
  [ "$TEST_PATH_0" = "path1" ] || { echo "✗ Path 0 wrong"; return 1; }
  [ "$TEST_PATH_1" = "path2" ] || { echo "✗ Path 1 wrong"; return 1; }
  [ "$TEST_PATH_2" = "path3" ] || { echo "✗ Path 2 wrong"; return 1; }

  echo "✓ Array export works correctly"
}

test_array_export
```

**Files Modified:**
- `.claude/lib/workflow-initialization.sh` (line ~291)

**Expected Duration**: 30 minutes

---

### Phase 2: Fix context-pruning.sh Associative Array Iterations [COMPLETED]
**Objective**: Replace all associative array key iterations to prevent future errors
**Complexity**: Low-Medium
**Priority**: HIGH (prevents context management errors)

**Tasks:**
- [x] **Fix PRUNED_METADATA_CACHE Iteration (Line 151)**:
  ```bash
  # Around line 150-156

  # Before:
  for key in "${!PRUNED_METADATA_CACHE[@]}"; do
    if [[ "$key" == *"$phase_id"* ]]; then
      unset PRUNED_METADATA_CACHE["$key"]
    fi
  done

  # After:
  # Use eval for associative array key expansion (safe: array name is constant)
  # Alternative ${!ARRAY[@]} syntax fails with history expansion errors
  for key in $(eval echo "\${!PRUNED_METADATA_CACHE[@]}"); do
    if [[ "$key" == *"$phase_id"* ]]; then
      unset PRUNED_METADATA_CACHE["$key"]
    fi
  done
  ```

- [x] **Fix PHASE_METADATA_CACHE Iteration (Line 246)**:
  ```bash
  # Similar pattern, replace with eval-based expansion
  for phase_id in $(eval echo "\${!PHASE_METADATA_CACHE[@]}"); do
    # existing logic
  done
  ```

- [x] **Fix PRUNED_METADATA_CACHE Iteration (Line 253)**:
  ```bash
  # Same as line 151
  for key in $(eval echo "\${!PRUNED_METADATA_CACHE[@]}"); do
    # existing logic
  done
  ```

- [x] **Fix PRUNED_METADATA_CACHE Iteration (Line 315)**:
  ```bash
  for key in $(eval echo "\${!PRUNED_METADATA_CACHE[@]}"); do
    # existing logic
  done
  ```

- [x] **Fix PHASE_METADATA_CACHE Iteration (Line 321)**:
  ```bash
  for key in $(eval echo "\${!PHASE_METADATA_CACHE[@]}"); do
    # existing logic
  done
  ```

- [x] **Fix WORKFLOW_METADATA_CACHE Iteration (Line 327)**:
  ```bash
  for key in $(eval echo "\${!WORKFLOW_METADATA_CACHE[@]}"); do
    # existing logic
  done
  ```

- [x] **Add Standardized Comments**: Add explanatory comment before each loop
  ```bash
  # Use eval for associative array key expansion (safe: CACHE_NAME is known constant)
  # Alternative ${!ARRAY[@]} syntax fails with history expansion errors
  ```

- [x] **Verify Associative Array Logic**: Ensure key iteration still works correctly
  - Test with populated associative arrays
  - Verify all keys are iterated
  - Check unset operations work correctly

**Testing:**
```bash
# Unit test: Verify associative array key iteration
test_assoc_array_iteration() {
  # Create test associative array
  declare -A test_cache
  test_cache["key1"]="value1"
  test_cache["key2"]="value2"
  test_cache["key3"]="value3"

  # Iterate using eval expansion
  count=0
  for key in $(eval echo "\${!test_cache[@]}"); do
    count=$((count + 1))
    echo "Key: $key, Value: ${test_cache[$key]}"
  done

  [ "$count" -eq 3 ] || { echo "✗ Wrong count: $count"; return 1; }
  echo "✓ Associative array iteration works correctly"
}

test_assoc_array_iteration
```

**Files Modified:**
- `.claude/lib/context-pruning.sh` (6 locations)

**Expected Duration**: 45-60 minutes

---

### Phase 3: Comprehensive Pattern Search and Verification [COMPLETED]
**Objective**: Ensure no other instances exist in active code
**Complexity**: Low
**Priority**: MEDIUM (prevention of future issues)

**Tasks:**
- [x] **Search All .claude/lib/ Files**: Find any remaining ${!...} patterns
  ```bash
  # Search command libraries
  grep -r '\${!' .claude/lib/*.sh | grep -v "^#" | grep -v "\.md:"

  # Verify only documentation/comments remain
  ```

- [x] **Search All .claude/commands/ Files**: Check orchestration commands
  ```bash
  # Search for pattern in command files
  grep -r '\${!' .claude/commands/*.md | grep -v "Alternative.*syntax" | grep -v "^#"

  # Filter out documentation comments about the fix
  ```

- [x] **Document the Anti-Pattern**: Add to troubleshooting guide
  - Location: `.claude/docs/troubleshooting/bash-tool-limitations.md`
  - Section: "History Expansion Errors with ${!...} Syntax"
  - Document both indexed and associative array fixes
  - Provide copy-paste safe alternatives

- [x] **Create Bash Linting Rule** (optional): Prevent future occurrences
  - Add to `.claude/lib/validate-bash-code.sh` (if exists)
  - Or create simple grep-based check for CI/pre-commit
  ```bash
  # Check for problematic pattern
  if grep -r '\${!' .claude/lib/*.sh .claude/commands/*.md | grep -v "^#.*Alternative"; then
    echo "ERROR: Found ${!...} pattern (use eval or C-style loops instead)"
    exit 1
  fi
  ```

**Testing:**
```bash
# Verification script
#!/usr/bin/env bash
set -euo pipefail

echo "=== Verifying No Remaining ${!...} Patterns ==="

# Search library files (excluding comments)
LIB_MATCHES=$(grep -r '\${!' .claude/lib/*.sh 2>/dev/null | grep -v "^#" | grep -v "Alternative" || true)

if [ -n "$LIB_MATCHES" ]; then
  echo "✗ Found ${!...} patterns in library files:"
  echo "$LIB_MATCHES"
  exit 1
else
  echo "✓ No ${!...} patterns in library files"
fi

# Search command files (excluding documentation)
CMD_MATCHES=$(grep -r '\${!' .claude/commands/*.md 2>/dev/null | grep -v "Alternative.*syntax" | grep -v "^#" || true)

if [ -n "$CMD_MATCHES" ]; then
  echo "✗ Found ${!...} patterns in command files:"
  echo "$CMD_MATCHES"
  exit 1
else
  echo "✓ No ${!...} patterns in command files"
fi

echo ""
echo "✓ All ${!...} patterns have been replaced"
```

**Files Modified:**
- `.claude/docs/troubleshooting/bash-tool-limitations.md` (documentation)
- Possibly `.claude/lib/validate-bash-code.sh` (optional linting)

**Expected Duration**: 30 minutes

---

### Phase 4: Integration Testing with Complete /coordinate Workflow
**Objective**: Verify all fixes work in real /coordinate execution
**Complexity**: Low
**Priority**: CRITICAL (validation of complete fix)

**Tasks:**
- [ ] **Test Simple Research Workflow**: Verify initialization succeeds
  ```bash
  /coordinate "Research bash history expansion issues"
  ```
  - Expected: No "!: command not found" errors
  - Expected: TOPIC_PATH initialized successfully
  - Expected: State machine displays initialization summary
  - Expected: Research agents invoked successfully

- [ ] **Test Research-and-Plan Workflow**: Verify array export works
  ```bash
  /coordinate "Research and plan a simple test feature"
  ```
  - Expected: Multiple research reports created
  - Expected: All REPORT_PATH_N variables exported correctly
  - Expected: Planning agent receives all report paths
  - Expected: Plan created successfully

- [ ] **Test Context Pruning**: Verify associative array iteration works
  - Trigger workflow with multiple phases (research → plan → implement)
  - Verify context pruning doesn't crash
  - Check that metadata caches are properly iterated
  - Confirm no errors in pruning operations

- [ ] **Test Error Handling**: Verify retry counter still works (from 613 fix)
  - Intentionally trigger an error in /coordinate
  - Verify error handling displays state context
  - Verify retry counter increments correctly
  - Verify max retry logic works

- [ ] **Verify Regression-Free**: Run existing coordinate tests
  ```bash
  # Run coordinate test suite
  bash .claude/tests/test_coordinate_all.sh

  # Check for new failures (ignore pre-existing failures)
  ```

- [ ] **Document Test Results**: Record all test outcomes
  - Create test execution log
  - Note any unexpected behaviors
  - Confirm all success criteria met

**Testing:**
```bash
# Complete integration test script
#!/usr/bin/env bash
set -euo pipefail

echo "=== /coordinate Integration Tests - Indirect Expansion Fixes ==="
echo ""

# Test 1: Simple research (tests workflow-initialization.sh fix)
echo "Test 1: Simple research workflow"
if /coordinate "Research bash indirect expansion solutions" &> /tmp/coord_test1.log; then
  if grep -q "TOPIC_PATH" /tmp/coord_test1.log && ! grep -q "!: command not found" /tmp/coord_test1.log; then
    echo "✓ Research workflow succeeded, TOPIC_PATH initialized"
  else
    echo "✗ Research workflow had issues"
    cat /tmp/coord_test1.log
    exit 1
  fi
else
  echo "✗ Research workflow failed"
  cat /tmp/coord_test1.log
  exit 1
fi

# Test 2: Array export verification
echo ""
echo "Test 2: Multiple report array export"
# This would create multiple research reports and verify exports
echo "  (Manual verification: check REPORT_PATH_0, REPORT_PATH_1 in workflow state)"

# Test 3: Context pruning (if workflow reaches those code paths)
echo ""
echo "Test 3: Context pruning operations"
echo "  (Verify no errors in longer workflows using context management)"

echo ""
echo "=== All Integration Tests Complete ==="
```

**Files Modified**: None (testing only)

**Expected Duration**: 45-60 minutes

---

## Testing Strategy

### Unit Testing
- **Array Export**: Verify C-style loop exports all elements correctly
- **Associative Array Iteration**: Verify eval expansion iterates all keys
- **Edge Cases**: Empty arrays, single-element arrays, large arrays

### Integration Testing
- **Workflow Initialization**: Complete /coordinate workflow from start to finish
- **Multi-Report Workflows**: Verify array exports with multiple research reports
- **Context Management**: Verify pruning operations with associative arrays
- **Error Handling**: Verify retry logic still works (regression check)

### Regression Testing
- **Existing Tests**: Run test_coordinate_all.sh and compare results
- **Manual Validation**: Test known /coordinate use cases
- **Performance**: Verify no performance degradation from loop changes

## Documentation Requirements

### Code Comments
- Document why C-style loops are used (history expansion avoidance)
- Document why eval is safe for associative arrays (known constant names)
- Add references to spec 617 in modified functions

### Troubleshooting Documentation
Update `.claude/docs/troubleshooting/bash-tool-limitations.md`:

```markdown
## History Expansion Errors with ${!...} Syntax

### Problem
The `${!VAR}` and `${!ARRAY[@]}` syntax can trigger "!: command not found" errors
in certain bash execution contexts due to history expansion.

### Solution

**For Indexed Arrays:**
```bash
# Don't use:
for i in "${!array[@]}"; do

# Instead use:
array_length=${#array[@]}
for ((i=0; i<array_length; i++)); do
```

**For Associative Arrays:**
```bash
# Don't use:
for key in "${!assoc_array[@]}"; do

# Instead use:
for key in $(eval echo "\${!assoc_array[@]}"); do
# Note: eval is safe when array name is a known constant
```

### Related Specs
- Spec 613: Initial fix in coordinate.md
- Spec 617: Complete fix across all libraries
```

## Dependencies

### Prerequisites
- Spec 613 completed (coordinate.md error handling fixed)
- State-based refactor (602) complete
- Bash 4.0+ for C-style loops and associative arrays

### No External Dependencies
- Fixes use standard bash features
- No new libraries required
- No breaking changes to library APIs

## Risk Assessment

### Low Risk Changes
- **C-style loops**: Well-tested bash feature, equivalent behavior to ${!array[@]}
- **eval for constants**: Safe when array names are hardcoded (not user input)
- **Targeted changes**: Only modifying loop syntax, not business logic

### Mitigation Strategies
- Comprehensive unit tests before integration testing
- Test all affected code paths
- Keep atomic commits for easy rollback
- Document changes thoroughly

### Rollback Plan
```bash
# Revert all changes if issues arise
git revert <phase-4-commit>
git revert <phase-3-commit>
git revert <phase-2-commit>
git revert <phase-1-commit>

# Or restore original code manually:
# workflow-initialization.sh line 291:
for i in "${!report_paths[@]}"; do

# context-pruning.sh multiple lines:
for key in "${!PRUNED_METADATA_CACHE[@]}"; do
```

## Implementation Notes

### Bash Safety Considerations

**C-style Loops:**
- Standard bash feature since bash 2.x
- Compatible with set -u (no unbound variables)
- Readable and maintainable
- No special character issues

**Eval for Associative Arrays:**
- Safe when array name is a known constant (PRUNED_METADATA_CACHE, etc.)
- Array names are hardcoded in library code, never from user input
- Consistent with spec 613 approach for indirect variables
- Works correctly with set -u mode

### Why Not Other Approaches?

**Approach 1: set +H to disable history expansion** (Rejected)
- Global setting might conflict with user environment
- Doesn't address root cause
- Could have unintended side effects

**Approach 2: Use compgen** (Deferred)
- compgen -v might work but less portable
- More complex than current solution
- Can be considered if current approach has issues

**Approach 3: Convert to indexed arrays** (Rejected)
- Would break associative array semantics
- Requires significant refactoring
- Not backwards compatible

### Selected Approach
- **Indexed arrays**: C-style loops (standard, safe, readable)
- **Associative arrays**: eval expansion (consistent with 613, safe with constants)

## Next Steps After Completion

1. **Monitor Production**: Watch for edge cases in real usage
2. **Add Linting**: Prevent future ${!...} usage in new code
3. **Document Pattern**: Add to coding standards
4. **Consider Bash Best Practices**: Review other potential bash gotchas

---

## Summary

This plan completes the indirect variable expansion fix started in spec 613 by:
1. Fixing workflow-initialization.sh array export (CRITICAL - blocks /coordinate)
2. Fixing context-pruning.sh associative array iterations (prevents future errors)
3. Verifying no other instances exist
4. Testing complete /coordinate workflows

**Estimated Total Time**: 2-3 hours across 4 phases
**Risk Level**: Low (targeted syntax changes, well-tested alternatives)
**Impact**: Unblocks all /coordinate functionality and prevents future history expansion errors

Once complete, /coordinate will:
- Execute successfully through complete workflows
- Properly initialize TOPIC_PATH and all workflow variables
- Export report arrays correctly
- Handle context pruning without errors
- Be resilient to bash history expansion issues

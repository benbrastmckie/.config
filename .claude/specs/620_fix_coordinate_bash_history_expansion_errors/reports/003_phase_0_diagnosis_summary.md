# Root Cause Diagnosis Summary
## Phase 0 Testing Results - 2025-11-09

## Hypothesis Testing Results

### Hypothesis A: Hidden/Non-printable Characters
- **Status**: REJECTED
- **Evidence**:
  - Checked coordinate.md with `od -c` - all `!` characters are normal printable (hex `21`)
  - Checked all sourced libraries for non-printable characters
  - Found only legitimate Unicode characters (→, ━, ✓, ≈) in comments and strings
  - No problematic hidden characters found
- **Action**: None needed

### Hypothesis B: Bash Tool Transformation Error
- **Status**: PARTIALLY CONFIRMED (symptom, not root cause)
- **Evidence**:
  - Extracted first bash block from coordinate.md to standalone script
  - Script executed successfully when run directly: `bash /tmp/test_coordinate.sh`
  - No "!: command not found" errors in direct execution
  - Only application logic errors (WORKFLOW_DESCRIPTION parameter passing)
  - The extracted script sources all libraries successfully
- **Action**: This confirms the issue is in how the Bash tool processes commands, not the bash code itself

### Hypothesis C: Library File Issues
- **Status**: REJECTED
- **Evidence**:
  - All required libraries exist in `.claude/lib/`:
    - ✓ workflow-detection.sh
    - ✓ workflow-scope-detection.sh
    - ✓ unified-logger.sh
    - ✓ unified-location-detection.sh
    - ✓ overview-synthesis.sh
    - ✓ metadata-extraction.sh
    - ✓ checkpoint-utils.sh
    - ✓ dependency-analyzer.sh
    - ✓ context-pruning.sh
    - ✓ error-handling.sh
  - Each library sources successfully when tested individually
  - library-sourcing.sh function exists and loads correctly
  - No ${!...} indirect expansion patterns causing issues (Spec 617 fixes are in place)
- **Action**: None needed - libraries are correct

### Hypothesis D: Environment-Specific Bash Behavior
- **Status**: CONFIRMED - ROOT CAUSE IDENTIFIED
- **Evidence**:
  - Environment: NixOS bash 5.2.37 from `/nix/store/.../bash-interactive-5.2p37/bin/bash`
  - History expansion status: OFF (correct for non-interactive shells)
  - Bash configuration is standard and correct
  - **CRITICAL FINDING**: The Bash tool itself experiences `!` processing errors during diagnosis
    - Example: `grep '!' file` command fails with history expansion errors
    - Example: Commands with `!` in strings fail unpredictably
    - This occurs despite history expansion being OFF in bash
  - The issue is in **the Bash tool's command preprocessing layer**, not bash itself
- **Action**: Workarounds needed for Bash tool limitations

## Root Cause Identified

**Primary Cause**: The Bash tool (Claude Code's bash command processor) has a bug or limitation in how it processes commands containing the `!` character.

**Technical Details**:
1. The actual bash shell has history expansion properly disabled
2. When bash scripts are executed directly, they work correctly
3. When the same scripts are executed via the Bash tool, commands with `!` fail
4. The failure occurs during the tool's preprocessing/evaluation stage
5. This affects:
   - The `source_required_libraries` function in library-sourcing.sh (line 96: `if ! source ...`)
   - Diagnostic commands attempting to search for `!`
   - Any bash conditional using `!` operator

**Why Previous Plan Failed**:
- Plan 001 added source guards and re-sourcing patterns
- These fixes addressed bash block boundaries but not the Bash tool's preprocessing issue
- The first bash block still fails because the tool can't process the `!` in `if ! source ...`
- Testing was deferred and never actually run, so the tool limitation was never discovered

## Secondary Contributing Factors

1. **Library Sourcing Error Suppression**: library-sourcing.sh line 96 redirects errors with `2>/dev/null`, making diagnosis harder
2. **Cascade Effect**: When `source_required_libraries` fails, `handle_state_error` is undefined, causing cascading errors
3. **Testing Gap**: Plan 001 marked complete without runtime validation

## Recommended Fix Strategy

Since the root cause is a **Bash tool limitation** that we cannot fix directly, we must implement workarounds:

### Strategy 1: Avoid `!` Operator in Sourcing (Recommended)
Replace the problematic `if ! command` pattern with equivalent logic:

```bash
# Instead of:
if ! source "$lib_path" 2>/dev/null; then
  failed_libraries+=("$lib")
fi

# Use:
if source "$lib_path" 2>/dev/null; then
  : # Success - do nothing
else
  failed_libraries+=("$lib")
fi
```

This avoids the `!` operator entirely while maintaining identical logic.

### Strategy 2: Explicit History Expansion Disable (Belt and Suspenders)
Add `set +H` at the very start of coordinate.md first bash block, even though history expansion is already off:

```bash
#!/usr/bin/env bash
set +H  # Explicitly disable history expansion (workaround for tool issues)
set -euo pipefail
```

### Strategy 3: Remove Error Suppression (Better Diagnostics)
Temporarily remove `2>/dev/null` from library sourcing to see actual errors:

```bash
# Change library-sourcing.sh:96 from:
if ! source "$lib_path" 2>/dev/null; then

# To:
if source "$lib_path"; then
  : # Success
else
  # (Error will be visible)
```

## Validation Plan

How we'll know the fix works:

### Test Case 1: First Bash Block Initialization
```bash
bash -c 'source .claude/lib/library-sourcing.sh && source_required_libraries workflow-detection.sh error-handling.sh && echo SUCCESS'
```
Expected: SUCCESS message, no errors

### Test Case 2: handle_state_error Availability
```bash
bash -c 'source .claude/lib/library-sourcing.sh && source_required_libraries error-handling.sh && declare -F handle_state_error'
```
Expected: Function declaration shown

### Test Case 3: Full Coordinate Execution
```bash
/coordinate "Test research workflow"
```
Expected: No "!: command not found" errors, state machine initializes

## Files Requiring Changes

1. **`.claude/lib/library-sourcing.sh`**:
   - Line 96: Replace `if !` with `if...; then : else`
   - Remove `2>/dev/null` temporarily for diagnosis

2. **`.claude/commands/coordinate.md`**:
   - Line 24 (start of first bash block): Add `set +H`
   - Enhanced error handling after `source_required_libraries` call

## Confidence Level

**HIGH** - Root cause identified with strong evidence:
- ✅ All four hypotheses tested systematically
- ✅ Direct bash execution works, tool execution fails (reproducible)
- ✅ Specific problematic code patterns identified
- ✅ Fix strategy targets confirmed root cause
- ✅ Validation test cases defined

## Next Steps

1. Proceed to Phase 1: Implement fixes based on Strategy 1 + Strategy 2
2. Apply changes to library-sourcing.sh and coordinate.md
3. Run validation test cases immediately after each change
4. Only mark Phase 1 complete when all runtime tests pass

## References

- **Diagnostic Analysis**: [002_diagnostic_analysis.md](002_diagnostic_analysis.md)
- **Failed Plan**: [001_coordinate_history_expansion_fix.md](../plans/001_coordinate_history_expansion_fix.md)
- **This Plan**: [002_complete_diagnostic_and_fix.md](../plans/002_complete_diagnostic_and_fix.md)
- **Console Output**: [coordinate_output.md](../../coordinate_output.md)

---

**Diagnosis Complete**: 2025-11-09
**Phase 0 Status**: COMPLETE - Root cause confirmed, fix strategy defined
**Confidence**: HIGH (systematic testing, reproducible findings)
**Ready for Phase 1**: YES

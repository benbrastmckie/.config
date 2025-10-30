# Phase 3 Expansion: Remove unified-logger.sh Rotation Wrappers

## Metadata

- **Phase Number**: 3
- **Parent Plan**: 003_unified_compatibility_removal_plan.md
- **Complexity**: High (8/10) - Context-sensitive manual updates
- **Estimated Duration**: 45-60 minutes
- **Risk Level**: Medium-High (variable context preservation)
- **Reference Count**: 22 total references
  - `rotate_log_if_needed()`: 11 references (internal to unified-logger.sh)
  - `rotate_conversion_log_if_needed()`: 11 references (internal to unified-logger.sh)

## Objective

Update all log rotation wrapper calls to use the canonical `rotate_log_file()` function with explicit log file paths, then remove the wrapper function definitions. This phase requires careful context analysis to ensure each reference receives the correct log file variable (`$AP_LOG_FILE` or `$CONVERSION_LOG_FILE`).

### Success Criteria

- [ ] All 11 `rotate_log_if_needed()` calls updated to `rotate_log_file "$AP_LOG_FILE"`
- [ ] All 11 `rotate_conversion_log_if_needed()` calls updated to `rotate_log_file "$CONVERSION_LOG_FILE"`
- [ ] Wrapper function definitions removed from unified-logger.sh (lines 97-105)
- [ ] Export statements removed from unified-logger.sh (lines 723-724)
- [ ] Documentation updated in unified-logger.sh header and README.md
- [ ] Zero grep results for wrapper function names after updates
- [ ] All 77/77 tests pass (100% pass rate - BLOCKING requirement)
- [ ] Checkpoint created documenting phase 3 completion

## Implementation Strategy

### Context-Sensitive Replacement Pattern

Unlike the previous phases which used batch sed replacements, Phase 3 requires **manual context analysis** for each reference because:

1. **Variable Context Matters**: Each wrapper call must be replaced with the correct log file variable
2. **Internal References Only**: All 22 references are within unified-logger.sh itself
3. **Function Purpose**: Determining whether to use `$AP_LOG_FILE` or `$CONVERSION_LOG_FILE` requires understanding the calling function's purpose

### Replacement Patterns

```bash
# Pattern 1: Adaptive Planning Context
rotate_log_if_needed
# Replace with:
rotate_log_file "$AP_LOG_FILE"

# Pattern 2: Conversion Logging Context
rotate_conversion_log_if_needed
# Replace with:
rotate_log_file "$CONVERSION_LOG_FILE"
```

### Analysis Checklist (Per Reference)

For each reference found, analyze:

1. **Function Name**: Which function contains this call?
2. **Function Purpose**: Is it adaptive planning or conversion logging?
3. **Log File Variable**: Which variable is appropriate (`$AP_LOG_FILE` or `$CONVERSION_LOG_FILE`)?
4. **Surrounding Context**: Are there other clues (function name prefix, comments, variable usage)?
5. **Expected Behavior**: Will the replacement preserve the original log rotation behavior?

## Stage 1: Pre-Update Analysis

### Step 1.1: Locate All References

```bash
# Find all wrapper function references in unified-logger.sh
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected output: ~22 matches (11 per wrapper)
```

### Step 1.2: Create Reference Map

Document each reference location and context:

```bash
# Create analysis workspace
mkdir -p /tmp/phase3_analysis
cd /tmp/phase3_analysis

# Extract context for each reference (5 lines before/after)
grep -B 5 -A 5 -n "rotate_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh \
  > rotate_log_if_needed_context.txt

grep -B 5 -A 5 -n "rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh \
  > rotate_conversion_log_if_needed_context.txt
```

### Step 1.3: Analyze Function Contexts

Based on the file structure (from Read operation), expected locations:

**`rotate_log_if_needed()` References** (11 total):
1. **Line 97**: Function definition - DELETE (not replace)
2. **Line 126**: Inside `write_log_entry()` - Adaptive planning context → `rotate_log_file "$AP_LOG_FILE"`
3. **Line 723**: Export statement - DELETE (not replace)

**`rotate_conversion_log_if_needed()` References** (11 total):
1. **Line 101**: Function definition - DELETE (not replace)
2. **Line 487**: Inside `log_conversion_start()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
3. **Line 510**: Inside `log_conversion_success()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
4. **Line 545**: Inside `log_conversion_failure()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
5. **Line 571**: Inside `log_conversion_fallback()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
6. **Line 592**: Inside `log_tool_detection()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
7. **Line 610**: Inside `log_phase_start()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
8. **Line 630**: Inside `log_phase_end()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
9. **Line 655**: Inside `log_validation_check()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
10. **Line 683**: Inside `log_summary()` - Conversion context → `rotate_log_file "$CONVERSION_LOG_FILE"`
11. **Line 724**: Export statement - DELETE (not replace)

### Step 1.4: Verify Analysis Accuracy

Cross-reference line numbers with actual file content:

```bash
# Verify each line number matches expected content
sed -n '97p; 126p; 487p; 510p; 545p; 571p; 592p; 610p; 630p; 655p; 683p; 723p; 724p' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Expected Output Verification**:
- Lines 97-105: Should show function definitions
- Line 126: Should be inside `write_log_entry()` function
- Lines 487-683: Should be inside conversion logging functions
- Lines 723-724: Should show export statements

### Step 1.5: Document Replacement Strategy

Create a replacement manifest:

```
REFERENCE REPLACEMENT MANIFEST - Phase 3
========================================

Function Calls to Replace (20 total):
-------------------------------------
Line 126:  rotate_log_if_needed
→ Replace: rotate_log_file "$AP_LOG_FILE"
→ Context: write_log_entry() - Adaptive planning log

Line 487:  rotate_conversion_log_if_needed
→ Replace: rotate_log_file "$CONVERSION_LOG_FILE"
→ Context: log_conversion_start() - Conversion log

Line 510:  rotate_conversion_log_if_needed
→ Replace: rotate_log_file "$CONVERSION_LOG_FILE"
→ Context: log_conversion_success() - Conversion log

[... continue for all 20 function calls ...]

Code to Delete (4 total):
-------------------------
Lines 97-99:   rotate_log_if_needed() function definition
Lines 101-105: rotate_conversion_log_if_needed() function definition
Line 723:      export -f rotate_log_if_needed
Line 724:      export -f rotate_conversion_log_if_needed
```

## Stage 2: File-by-File Updates

### Overview

Since all references are within `/home/benjamin/.config/.claude/lib/unified-logger.sh`, this stage involves a single file with multiple precise edits.

### Step 2.1: Create Backup

```bash
# Create timestamped backup
cp /home/benjamin/.config/.claude/lib/unified-logger.sh \
   /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-$(date +%Y%m%d-%H%M%S)

# Verify backup exists
ls -lh /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-*
```

### Step 2.2: Update Function Calls (Adaptive Planning Context)

**Target**: Line 126 in `write_log_entry()` function

**Context Analysis**:
```bash
# View surrounding context
sed -n '120,135p' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Expected Context**:
```bash
write_log_entry() {
  local log_level="$1"
  local event_type="$2"
  local message="$3"
  local data="${4:-}"

  rotate_log_if_needed  # ← Line 126 (UPDATE THIS)

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  ...
}
```

**Replacement Command**:
```bash
# Update line 126: rotate_log_if_needed → rotate_log_file "$AP_LOG_FILE"
sed -i '126s/rotate_log_if_needed/rotate_log_file "$AP_LOG_FILE"/' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Verification**:
```bash
# Verify replacement succeeded
sed -n '126p' /home/benjamin/.config/.claude/lib/unified-logger.sh | grep 'rotate_log_file "$AP_LOG_FILE"'

# Expected: rotate_log_file "$AP_LOG_FILE" (with proper indentation)
```

### Step 2.3: Update Function Calls (Conversion Logging Context)

**Targets**: Lines 487, 510, 545, 571, 592, 610, 630, 655, 683 (9 total)

**Batch Replacement Strategy**:
```bash
# Replace all rotate_conversion_log_if_needed calls in one operation
sed -i 's/rotate_conversion_log_if_needed/rotate_log_file "$CONVERSION_LOG_FILE"/g' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Individual Verification** (spot-check critical functions):

1. **log_conversion_start()** (Line ~487):
```bash
sed -n '483,493p' /home/benjamin/.config/.claude/lib/unified-logger.sh
# Should show: rotate_log_file "$CONVERSION_LOG_FILE"
```

2. **log_conversion_success()** (Line ~510):
```bash
sed -n '505,515p' /home/benjamin/.config/.claude/lib/unified-logger.sh
# Should show: rotate_log_file "$CONVERSION_LOG_FILE"
```

3. **log_summary()** (Line ~683):
```bash
sed -n '678,688p' /home/benjamin/.config/.claude/lib/unified-logger.sh
# Should show: rotate_log_file "$CONVERSION_LOG_FILE"
```

### Step 2.4: Post-Update Function Call Verification

```bash
# Count remaining wrapper function calls (should be 0 after updates)
grep -c "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: 4 (only the definitions and export statements remain)

# Verify all function calls updated correctly
grep -n "rotate_log_file" /home/benjamin/.config/.claude/lib/unified-logger.sh | head -20

# Expected: Should show rotate_log_file calls with proper variables
```

## Stage 3: Wrapper Deletion

### Step 3.1: Remove Function Definitions

**Target Lines**: 97-105

**Context Verification**:
```bash
# View lines 95-107 to confirm deletion range
sed -n '95,107p' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Expected Content**:
```bash
# Line 96: Comment before wrapper functions
# Specific rotation functions for backward compatibility
rotate_log_if_needed() {
  rotate_log_file "$AP_LOG_FILE"
}

rotate_conversion_log_if_needed() {
  if [[ -n "$CONVERSION_LOG_FILE" ]]; then
    rotate_log_file "$CONVERSION_LOG_FILE" "$CONVERSION_LOG_MAX_SIZE" "$CONVERSION_LOG_MAX_FILES"
  fi
}
# Line 106: Blank line or next section marker
```

**Deletion Strategy**:

Option 1 - **Delete lines 96-105** (includes comment):
```bash
sed -i '96,105d' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

Option 2 - **Delete lines 97-105** (preserves blank line):
```bash
sed -i '97,105d' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Recommended**: Option 1 (delete compatibility comment too)

**Post-Deletion Verification**:
```bash
# Verify function definitions removed
sed -n '95,100p' /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: Should show the next section (ADAPTIVE PLANNING LOGGING header)
```

### Step 3.2: Remove Export Statements

**Target Lines**: 723-724 (line numbers will shift after previous deletion)

**Important**: After deleting lines 96-105 (10 lines), the export statements will move up by 10 lines:
- Original line 723 → New line 713
- Original line 724 → New line 714

**Context Verification**:
```bash
# Find current location of export statements
grep -n "export -f rotate_log_if_needed" /home/benjamin/.config/.claude/lib/unified-logger.sh
grep -n "export -f rotate_conversion_log_if_needed" /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Deletion Command** (use actual line numbers from grep output):
```bash
# Delete export statements (adjust line numbers based on actual file state)
sed -i '/export -f rotate_log_if_needed/d; /export -f rotate_conversion_log_if_needed/d' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Post-Deletion Verification**:
```bash
# Verify export statements removed
grep "export -f rotate_log_if_needed\|export -f rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: No output (0 matches)
```

### Step 3.3: Comprehensive Deletion Verification

```bash
# Final check: zero references to wrapper functions should remain
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: No output (0 matches)

# Verify rotate_log_file calls exist (canonical function)
grep -c "rotate_log_file" /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: ~10+ matches (definition + all replaced calls)
```

## Stage 4: Documentation Updates

### Step 4.1: Update Inline Documentation (unified-logger.sh Header)

**Target**: Lines 1-20 (file header)

**Current Header Analysis**:
```bash
# View current header
sed -n '1,25p' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

**Expected Current Content**:
```bash
#!/usr/bin/env bash
#
# Unified Logger
# Provides structured logging for all Claude Code operations
# Consolidates: adaptive-planning-logger.sh, conversion-logger.sh
#
# Log files:
#   - .claude/logs/adaptive-planning.log
#   - .claude/logs/conversion.log
#
# Features:
#   - Structured logging (timestamp, level, category, message)
#   - Log rotation (10MB max, 5 files retained)
#   - Multiple log streams
#   - Query functions
#
# Usage:
#   source .claude/lib/unified-logger.sh
#   log_complexity_check 3 9.2 8 12  # Adaptive planning
#   init_conversion_log "$OUTPUT_DIR/conversion.log"  # Conversion
```

**No Changes Required**: Header doesn't mention wrapper functions explicitly.

**Alternative Check** - Search for wrapper mentions:
```bash
# Search for any wrapper function documentation in comments
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh | grep "^[0-9]*:#"

# If matches found, remove those comment lines
```

### Step 4.2: Update Library README.md

**File**: `/home/benjamin/.config/.claude/lib/README.md`

**Search for References**:
```bash
# Find all mentions of wrapper functions
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/README.md
```

**Expected Matches** (from earlier grep):
- Line 221: `- Common logging (init_log, rotate_log_if_needed, query_log)`
- Line 767: `- rotate_conversion_log_if_needed() - Rotate log files automatically`

**Update Line 221**:
```bash
# Before:
- Common logging (init_log, rotate_log_if_needed, query_log)

# After:
- Common logging (init_log, rotate_log_file, query_log)
```

**Replacement Command**:
```bash
sed -i '221s/rotate_log_if_needed/rotate_log_file/' \
  /home/benjamin/.config/.claude/lib/README.md
```

**Update Line 767**:
```bash
# Before:
- `rotate_conversion_log_if_needed()` - Rotate log files automatically

# After:
- `rotate_log_file(log_file, [max_size], [max_files])` - Rotate log files with explicit path
```

**Replacement Command**:
```bash
sed -i '767s/rotate_conversion_log_if_needed()/rotate_log_file(log_file, [max_size], [max_files])/' \
  /home/benjamin/.config/.claude/lib/README.md

sed -i '767s/Rotate log files automatically/Rotate log files with explicit path/' \
  /home/benjamin/.config/.claude/lib/README.md
```

**Verification**:
```bash
# Verify no wrapper function references remain
grep "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/README.md

# Expected: No output (0 matches)

# Verify rotate_log_file documented
grep "rotate_log_file" /home/benjamin/.config/.claude/lib/README.md

# Expected: 1+ matches showing canonical function
```

### Step 4.3: Update Standards Documentation

**File**: `/home/benjamin/.config/.claude/docs/reference/library-api.md`

**Search for References**:
```bash
# Find wrapper function documentation
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/docs/reference/library-api.md
```

**If Matches Found**:
1. **Document rotate_log_file() only** (canonical function)
2. **Remove wrapper function entries** (delete entire sections)
3. **Update examples** to use explicit log file paths

**Example Canonical Documentation** (replace wrapper docs):
```markdown
### rotate_log_file()

Rotate log files when they exceed size threshold.

**Signature**:
```bash
rotate_log_file <log_file_path> [max_size] [max_files]
```

**Parameters**:
- `log_file_path`: Path to log file to rotate
- `max_size`: Maximum file size in bytes (default: 10MB)
- `max_files`: Number of rotated files to retain (default: 5)

**Usage**:
```bash
# Adaptive planning log rotation
rotate_log_file "$AP_LOG_FILE"

# Conversion log rotation with custom limits
rotate_log_file "$CONVERSION_LOG_FILE" "$CONVERSION_LOG_MAX_SIZE" "$CONVERSION_LOG_MAX_FILES"
```

**Behavior**:
- When log exceeds max_size, rename to .log.1
- Rotate existing backups (.log.1 → .log.2, etc.)
- Delete oldest backup exceeding max_files limit
```

### Step 4.4: Verify Documentation Completeness

```bash
# Search entire .claude/ directory for wrapper function references
grep -r "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/ \
  --include="*.md" \
  --exclude-dir=specs \
  --exclude-dir=.git

# Expected: 0 matches (all documentation updated)
```

## Stage 5: Testing and Verification

### Step 5.1: Pre-Test Verification

**Syntax Check**:
```bash
# Verify unified-logger.sh has valid bash syntax
bash -n /home/benjamin/.config/.claude/lib/unified-logger.sh

# Expected: No output (syntax valid)
```

**Source Test**:
```bash
# Verify file can be sourced without errors
(
  set -euo pipefail
  source /home/benjamin/.config/.claude/lib/unified-logger.sh
  echo "Source successful"
)

# Expected: "Source successful"
```

**Function Availability Check**:
```bash
# Verify rotate_log_file is available after sourcing
(
  source /home/benjamin/.config/.claude/lib/unified-logger.sh
  type rotate_log_file
)

# Expected: Function definition shown

# Verify wrapper functions are NOT available
(
  source /home/benjamin/.config/.claude/lib/unified-logger.sh
  type rotate_log_if_needed 2>&1 || echo "Wrapper correctly removed"
)

# Expected: "Wrapper correctly removed"
```

### Step 5.2: Run Full Test Suite

```bash
# Navigate to test directory
cd /home/benjamin/.config/.claude/tests

# Run complete test suite
./run_all_tests.sh

# Expected: 77/77 tests PASSED (100% pass rate)
```

### Step 5.3: Handle Test Failures (If Any)

**If tests fail**, follow this diagnostic procedure:

**Step 5.3.1: Identify Failing Tests**
```bash
# Review test output for specific failures
./run_all_tests.sh 2>&1 | grep -A 5 "FAILED"

# Note which test files failed
```

**Step 5.3.2: Analyze Root Cause**

Common failure patterns:

1. **"rotate_log_if_needed: command not found"**
   - Cause: Missed reference update in test file
   - Fix: Update test file to use `rotate_log_file "$AP_LOG_FILE"`

2. **"rotate_conversion_log_if_needed: command not found"**
   - Cause: Missed reference update in command/agent file
   - Fix: Search for remaining references and update

3. **Log rotation not occurring**
   - Cause: Incorrect variable passed to `rotate_log_file`
   - Fix: Verify `$AP_LOG_FILE` or `$CONVERSION_LOG_FILE` is set correctly

**Step 5.3.3: Search for Missed References**
```bash
# Comprehensive search for any remaining wrapper function calls
grep -rn "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/ \
  --include="*.sh" \
  --include="*.md" \
  --exclude-dir=.git \
  --exclude-dir=specs

# Expected: 0 matches (if any found, update those files)
```

**Step 5.3.4: Fix and Re-Test**
```bash
# After fixing issues, re-run test suite
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh

# Repeat until 77/77 tests pass
```

### Step 5.4: Functional Testing (Manual Verification)

**Test Adaptive Planning Logging**:
```bash
# Create test script
cat > /tmp/test_ap_logging.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source /home/benjamin/.config/.claude/lib/unified-logger.sh

# Write test entry (should trigger rotation check)
write_log_entry "INFO" "test_event" "Phase 3 verification test"

# Verify log file created
if [[ -f "$AP_LOG_FILE" ]]; then
  echo "✓ Adaptive planning log created"
  tail -1 "$AP_LOG_FILE"
else
  echo "✗ Adaptive planning log not found"
  exit 1
fi
EOF

chmod +x /tmp/test_ap_logging.sh
/tmp/test_ap_logging.sh

# Expected: Log entry created successfully
```

**Test Conversion Logging**:
```bash
# Create test script
cat > /tmp/test_conversion_logging.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source /home/benjamin/.config/.claude/lib/unified-logger.sh

# Initialize conversion log
init_conversion_log "/tmp/test_conversion.log"

# Log conversion start (should trigger rotation check)
log_conversion_start "/tmp/test.docx" "markdown"

# Verify log file created
if [[ -f "/tmp/test_conversion.log" ]]; then
  echo "✓ Conversion log created"
  tail -5 /tmp/test_conversion.log
else
  echo "✗ Conversion log not found"
  exit 1
fi
EOF

chmod +x /tmp/test_conversion_logging.sh
/tmp/test_conversion_logging.sh

# Expected: Conversion log entry created successfully
```

### Step 5.5: Regression Testing (Edge Cases)

**Test 1: Log Rotation Trigger**
```bash
# Create large log file to trigger rotation
cat > /tmp/test_rotation.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source /home/benjamin/.config/.claude/lib/unified-logger.sh

# Create test log file exceeding 10MB
TEST_LOG="/tmp/test_rotation.log"
dd if=/dev/zero of="$TEST_LOG" bs=1M count=11 2>/dev/null

# Trigger rotation
rotate_log_file "$TEST_LOG"

# Verify rotation occurred
if [[ -f "${TEST_LOG}.1" ]]; then
  echo "✓ Log rotation successful"
  ls -lh /tmp/test_rotation.log*
else
  echo "✗ Log rotation failed"
  exit 1
fi

# Cleanup
rm -f /tmp/test_rotation.log*
EOF

chmod +x /tmp/test_rotation.sh
/tmp/test_rotation.sh

# Expected: Rotation successful, .log.1 created
```

**Test 2: Empty/Unset Log File Variables**
```bash
# Verify graceful handling of unset variables
(
  source /home/benjamin/.config/.claude/lib/unified-logger.sh

  # Test with undefined variable (should fail fast)
  rotate_log_file "$UNDEFINED_VAR" 2>&1 || echo "✓ Fail-fast behavior correct"
)

# Expected: Error message or fail-fast exit
```

### Step 5.6: Comprehensive Verification Checklist

```bash
# Execute comprehensive verification script
cat > /tmp/phase3_verification.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Phase 3 Comprehensive Verification"
echo "===================================="

# 1. Verify wrapper functions deleted
echo -n "1. Wrapper function definitions removed... "
if ! grep -q "rotate_log_if_needed()\|rotate_conversion_log_if_needed()" \
     /home/benjamin/.config/.claude/lib/unified-logger.sh; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# 2. Verify export statements deleted
echo -n "2. Export statements removed... "
if ! grep -q "export -f rotate_log_if_needed\|export -f rotate_conversion_log_if_needed" \
     /home/benjamin/.config/.claude/lib/unified-logger.sh; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# 3. Verify rotate_log_file calls exist
echo -n "3. Canonical function calls present... "
if grep -q 'rotate_log_file "$AP_LOG_FILE"' \
     /home/benjamin/.config/.claude/lib/unified-logger.sh; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# 4. Verify documentation updated
echo -n "4. Documentation updated... "
if ! grep -q "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
     /home/benjamin/.config/.claude/lib/README.md; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# 5. Verify syntax validity
echo -n "5. Bash syntax valid... "
if bash -n /home/benjamin/.config/.claude/lib/unified-logger.sh 2>/dev/null; then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

# 6. Verify file sources correctly
echo -n "6. File sources without errors... "
if (source /home/benjamin/.config/.claude/lib/unified-logger.sh 2>/dev/null); then
  echo "✓ PASS"
else
  echo "✗ FAIL"
  exit 1
fi

echo ""
echo "All verification checks passed! ✓"
EOF

chmod +x /tmp/phase3_verification.sh
/tmp/phase3_verification.sh

# Expected: All 6 checks pass
```

## Stage 6: Checkpoint Creation

### Step 6.1: Document Phase Completion

```bash
# Create checkpoint file
cat > /home/benjamin/.config/.claude/specs/528_create_a_detailed_implementation_plan_to_remove_al/artifacts/phase_3_checkpoint.md <<'EOF'
# Phase 3 Checkpoint: unified-logger.sh Rotation Wrappers Removed

## Completion Summary

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Phase**: 3 - Remove unified-logger.sh Rotation Wrappers
**Status**: COMPLETE
**Test Results**: 77/77 PASSED (100%)

## Changes Executed

### Function Call Updates (20 references)
- Line 126: `rotate_log_if_needed` → `rotate_log_file "$AP_LOG_FILE"`
- Lines 487, 510, 545, 571, 592, 610, 630, 655, 683: `rotate_conversion_log_if_needed` → `rotate_log_file "$CONVERSION_LOG_FILE"`

### Code Deletions
- Lines 96-105: Wrapper function definitions removed
- Export statements: `export -f rotate_log_if_needed` and `export -f rotate_conversion_log_if_needed` removed

### Documentation Updates
- `/home/benjamin/.config/.claude/lib/README.md`: Updated lines 221, 767 to reference canonical function
- `/home/benjamin/.config/.claude/lib/unified-logger.sh`: Header verified (no wrapper mentions)
- `/home/benjamin/.config/.claude/docs/reference/library-api.md`: Wrapper function docs removed (if present)

## Verification Results

✓ Zero grep results for wrapper function names
✓ All rotate_log_file calls use explicit log file variables
✓ Bash syntax validation passed
✓ Source test passed
✓ Full test suite: 77/77 PASSED
✓ Functional testing passed (adaptive planning and conversion logs)
✓ Regression testing passed (rotation trigger, edge cases)

## Files Modified

1. `/home/benjamin/.config/.claude/lib/unified-logger.sh` - Primary updates
2. `/home/benjamin/.config/.claude/lib/README.md` - Documentation updates
3. `/home/benjamin/.config/.claude/docs/reference/library-api.md` - Standards documentation

## Next Phase

Proceed to **Phase 4: Remove Unused Legacy Function** (generate_legacy_location_context)

## Rollback Procedure (If Needed)

```bash
# Restore from backup
cp /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-* \
   /home/benjamin/.config/.claude/lib/unified-logger.sh

# Re-run tests to verify restoration
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```
EOF

# Display checkpoint
cat /home/benjamin/.config/.claude/specs/528_create_a_detailed_implementation_plan_to_remove_al/artifacts/phase_3_checkpoint.md
```

### Step 6.2: Update Parent Plan Checkboxes

```bash
# Mark Phase 3 tasks complete in parent plan
# (Manual update - open in editor and check off completed tasks)

# File to update:
# /home/benjamin/.config/.claude/specs/528_create_a_detailed_implementation_plan_to_remove_al/plans/003_unified_compatibility_removal_plan.md

# Tasks to mark complete (lines 167-174):
# [x] Update all `rotate_log_if_needed()` calls to `rotate_log_file("$AP_LOG_FILE")`
# [x] Update all `rotate_conversion_log_if_needed()` calls to `rotate_log_file("$CONVERSION_LOG_FILE")`
# [x] Verify grep finds 0 references to wrapper function names
# [x] Remove wrapper definitions from unified-logger.sh
# [x] Update unified-logger.sh documentation to show only canonical usage
# [x] Run test suite: `.claude/tests/run_all_tests.sh`
# [x] Verify all 77/77 tests pass
# [x] Create checkpoint: document phase 3 completion
```

## Troubleshooting

### Issue 1: Tests Fail with "command not found"

**Symptom**:
```
test_adaptive_planning.sh: line 42: rotate_log_if_needed: command not found
```

**Root Cause**: Test file still references old wrapper function

**Diagnosis**:
```bash
# Find which test file has the reference
grep -rn "rotate_log_if_needed" /home/benjamin/.config/.claude/tests/
```

**Resolution**:
```bash
# Update test file to use canonical function
sed -i 's/rotate_log_if_needed/rotate_log_file "$AP_LOG_FILE"/g' \
  /home/benjamin/.config/.claude/tests/test_adaptive_planning.sh

# Re-run tests
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

### Issue 2: Log Rotation Not Triggering

**Symptom**: Large log files not rotating after update

**Root Cause**: Incorrect variable passed to `rotate_log_file`

**Diagnosis**:
```bash
# Check if AP_LOG_FILE is set correctly
(
  source /home/benjamin/.config/.claude/lib/unified-logger.sh
  echo "AP_LOG_FILE=$AP_LOG_FILE"
)

# Expected: /home/benjamin/.config/.claude/data/logs/adaptive-planning.log
```

**Resolution**:
```bash
# If variable is empty, check unified-logger.sh lines 38-41
# Verify AP_LOG_FILE is initialized correctly:
if [[ -z "${AP_LOG_FILE:-}" ]]; then
  readonly AP_LOG_FILE="${CLAUDE_LOGS_DIR:-.claude/data/logs}/adaptive-planning.log"
fi

# If initialization is correct but still failing, check the rotate_log_file call
# Ensure proper quoting: rotate_log_file "$AP_LOG_FILE"
```

### Issue 3: Conversion Logging Fails

**Symptom**: `log_conversion_start()` or similar functions error

**Root Cause**: CONVERSION_LOG_FILE not initialized before rotation call

**Diagnosis**:
```bash
# Test conversion log initialization
(
  source /home/benjamin/.config/.claude/lib/unified-logger.sh
  init_conversion_log "/tmp/test.log"
  log_conversion_start "/tmp/test.docx" "markdown"
)

# If error occurs, check error message
```

**Resolution**:
```bash
# Verify init_conversion_log() is called before any log_conversion_*() functions
# Check lines 101-105 in original unified-logger.sh:
rotate_conversion_log_if_needed() {
  if [[ -n "$CONVERSION_LOG_FILE" ]]; then  # ← Guards against unset variable
    rotate_log_file "$CONVERSION_LOG_FILE" "$CONVERSION_LOG_MAX_SIZE" "$CONVERSION_LOG_MAX_FILES"
  fi
}

# Ensure rotate_log_file calls have same guard:
if [[ -n "$CONVERSION_LOG_FILE" ]]; then
  rotate_log_file "$CONVERSION_LOG_FILE"
fi
```

### Issue 4: Sed Replacement Affected Wrong Lines

**Symptom**: Function definitions or exports still present, but different content

**Root Cause**: Line numbers shifted during multi-step sed operations

**Diagnosis**:
```bash
# View current file state
cat -n /home/benjamin/.config/.claude/lib/unified-logger.sh | grep -A 3 -B 3 "rotate_log_if_needed"
```

**Resolution**:
```bash
# Restore from backup and re-execute carefully
cp /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-* \
   /home/benjamin/.config/.claude/lib/unified-logger.sh

# Use pattern-based deletion instead of line numbers
sed -i '/^rotate_log_if_needed()/,/^}$/d' /home/benjamin/.config/.claude/lib/unified-logger.sh
sed -i '/^rotate_conversion_log_if_needed()/,/^}$/d' /home/benjamin/.config/.claude/lib/unified-logger.sh
```

### Issue 5: Documentation Still References Wrappers

**Symptom**: Grep finds wrapper references in documentation after updates

**Root Cause**: Missed documentation files or incomplete sed patterns

**Diagnosis**:
```bash
# Find all remaining documentation references
grep -rn "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/ \
  --include="*.md" \
  --exclude-dir=specs \
  --exclude-dir=.git
```

**Resolution**:
```bash
# Update each file found
# For README.md files:
find /home/benjamin/.config/.claude/ -name "README.md" -type f \
  -exec sed -i 's/rotate_log_if_needed/rotate_log_file/g' {} +

# For documentation guides:
find /home/benjamin/.config/.claude/docs/ -name "*.md" -type f \
  -exec sed -i 's/rotate_conversion_log_if_needed/rotate_log_file "$CONVERSION_LOG_FILE"/g' {} +

# Verify cleanup
grep -r "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/ --include="*.md" --exclude-dir=specs
```

## Success Criteria Validation

### Final Checklist

Before marking Phase 3 complete, verify ALL criteria met:

- [ ] **Function Calls Updated**: All 20 wrapper calls replaced with `rotate_log_file` + explicit variable
- [ ] **Definitions Deleted**: Lines 96-105 removed from unified-logger.sh
- [ ] **Exports Deleted**: Export statements for wrapper functions removed
- [ ] **Documentation Updated**: README.md, library-api.md, and inline docs show only canonical function
- [ ] **Zero Grep Results**: No wrapper function references in codebase (excluding specs/)
- [ ] **Syntax Valid**: `bash -n unified-logger.sh` passes
- [ ] **Source Test Passes**: File sources without errors
- [ ] **Test Suite Passes**: 77/77 tests PASSED (100%)
- [ ] **Functional Tests Pass**: Manual logging tests succeed
- [ ] **Regression Tests Pass**: Edge cases handled correctly
- [ ] **Checkpoint Created**: Phase 3 checkpoint document written
- [ ] **Backup Created**: Timestamped backup of unified-logger.sh exists

### Verification Commands (All-in-One)

```bash
#!/usr/bin/env bash
# Phase 3 Final Verification Script

echo "Phase 3 Final Verification Checklist"
echo "====================================="

PASS_COUNT=0
FAIL_COUNT=0

check() {
  local description="$1"
  local command="$2"

  echo -n "Checking: $description... "
  if eval "$command" &>/dev/null; then
    echo "✓ PASS"
    ((PASS_COUNT++))
  else
    echo "✗ FAIL"
    ((FAIL_COUNT++))
  fi
}

# Run all checks
check "Wrapper definitions removed" \
  "! grep -q 'rotate_log_if_needed()\|rotate_conversion_log_if_needed()' /home/benjamin/.config/.claude/lib/unified-logger.sh"

check "Export statements removed" \
  "! grep -q 'export -f rotate_log_if_needed\|export -f rotate_conversion_log_if_needed' /home/benjamin/.config/.claude/lib/unified-logger.sh"

check "Canonical calls present" \
  "grep -q 'rotate_log_file \"\$AP_LOG_FILE\"' /home/benjamin/.config/.claude/lib/unified-logger.sh"

check "Documentation updated" \
  "! grep -q 'rotate_log_if_needed\|rotate_conversion_log_if_needed' /home/benjamin/.config/.claude/lib/README.md"

check "Syntax valid" \
  "bash -n /home/benjamin/.config/.claude/lib/unified-logger.sh"

check "File sources correctly" \
  "source /home/benjamin/.config/.claude/lib/unified-logger.sh"

check "Backup exists" \
  "ls /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-* >/dev/null 2>&1"

# Test suite check (run separately due to time)
echo -n "Checking: Test suite passes... "
if cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh 2>&1 | grep -q "77/77 PASSED"; then
  echo "✓ PASS"
  ((PASS_COUNT++))
else
  echo "✗ FAIL (run manually to debug)"
  ((FAIL_COUNT++))
fi

echo ""
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [ $FAIL_COUNT -eq 0 ]; then
  echo "✓ Phase 3 COMPLETE - All criteria met"
  exit 0
else
  echo "✗ Phase 3 INCOMPLETE - Fix failures before proceeding"
  exit 1
fi
```

## Estimated Timeline

### Detailed Task Breakdown

| Stage | Task | Estimated Time |
|-------|------|----------------|
| 1.1 | Locate all references | 5 min |
| 1.2 | Create reference map | 5 min |
| 1.3 | Analyze function contexts | 10 min |
| 1.4 | Verify analysis accuracy | 5 min |
| 1.5 | Document replacement strategy | 5 min |
| **Stage 1 Total** | | **30 min** |
| 2.1 | Create backup | 2 min |
| 2.2 | Update adaptive planning calls | 5 min |
| 2.3 | Update conversion logging calls | 10 min |
| 2.4 | Post-update verification | 5 min |
| **Stage 2 Total** | | **22 min** |
| 3.1 | Remove function definitions | 5 min |
| 3.2 | Remove export statements | 3 min |
| 3.3 | Deletion verification | 5 min |
| **Stage 3 Total** | | **13 min** |
| 4.1 | Update inline documentation | 5 min |
| 4.2 | Update library README | 5 min |
| 4.3 | Update standards documentation | 5 min |
| 4.4 | Verify documentation completeness | 5 min |
| **Stage 4 Total** | | **20 min** |
| 5.1 | Pre-test verification | 5 min |
| 5.2 | Run full test suite | 10 min |
| 5.3 | Handle test failures (if any) | 0-20 min |
| 5.4 | Functional testing | 10 min |
| 5.5 | Regression testing | 10 min |
| 5.6 | Comprehensive verification | 5 min |
| **Stage 5 Total** | | **40-60 min** |
| 6.1 | Document phase completion | 5 min |
| 6.2 | Update parent plan checkboxes | 3 min |
| **Stage 6 Total** | | **8 min** |
| **TOTAL (No Failures)** | | **133 min (2h 13m)** |
| **TOTAL (With Failures)** | | **153 min (2h 33m)** |

### Buffer Recommendations

- **Minimum**: 45 minutes (assumes no issues)
- **Realistic**: 60 minutes (assumes minor debugging)
- **Maximum**: 90 minutes (assumes test failures requiring investigation)

### Critical Path Items

1. **Context Analysis** (Stage 1.3) - 10 minutes: Cannot proceed without understanding which variable applies to each call
2. **Test Suite** (Stage 5.2) - 10 minutes: BLOCKING requirement, cannot complete phase without 77/77 pass
3. **Test Failure Resolution** (Stage 5.3) - Variable: May require 0-20 minutes depending on failure complexity

## Risk Mitigation Strategies

### Risk 1: Incorrect Variable Assignment

**Probability**: Low
**Impact**: High (log rotation fails silently)

**Mitigation**:
- Stage 1.3 includes detailed context analysis for each reference
- All references are internal to unified-logger.sh (clear function purpose)
- Functional testing (Stage 5.4) validates actual log rotation behavior

**Contingency**:
- Restore from backup (Step 2.1 creates timestamped backup)
- Re-execute Stage 2 with corrected variable assignments

### Risk 2: Test Failures Block Completion

**Probability**: Medium
**Impact**: High (phase cannot complete without 100% pass rate)

**Mitigation**:
- Pre-test verification (Stage 5.1) catches syntax errors before test suite
- Troubleshooting section includes diagnostic procedures for common failures
- All test failures have documented resolution strategies

**Contingency**:
- Comprehensive search for missed references (Issue 1 resolution)
- Restore from backup if changes too extensive
- Escalate to user if test failures unrelated to Phase 3 changes

### Risk 3: Documentation Incompleteness

**Probability**: Low
**Impact**: Medium (future developers may reference non-existent functions)

**Mitigation**:
- Stage 4.4 runs comprehensive grep across all documentation
- Final verification checklist includes documentation check
- Multiple documentation files updated systematically

**Contingency**:
- Re-run documentation grep searches to find missed references
- Update any newly discovered documentation files

### Risk 4: Line Number Shifts During Multi-Step Edits

**Probability**: Medium
**Impact**: Medium (deletions may affect wrong lines)

**Mitigation**:
- Stage 3 uses pattern-based deletion (not line numbers) for robustness
- Each deletion step includes verification command
- Backup created before any edits (Step 2.1)

**Contingency**:
- Restore from backup and use pattern-based sed instead of line numbers
- Issue 4 troubleshooting provides specific resolution steps

## Notes

### Context-Sensitive Update Rationale

Phase 3 differs from Phase 1 and Phase 2 in complexity:

- **Phase 1** (artifact-operations.sh): Simple file path replacement, batch sed worked well
- **Phase 2** (error-handling.sh): Function name replacement, batch sed worked well
- **Phase 3** (unified-logger.sh): Variable context matters, manual analysis required

The manual analysis approach ensures:
1. Correct variable assignment (`$AP_LOG_FILE` vs `$CONVERSION_LOG_FILE`)
2. Understanding of each function's purpose
3. Preservation of rotation behavior

### Internal References Advantage

All 22 references are within unified-logger.sh itself, which simplifies:
- Context analysis (all functions in one file)
- Testing (single file to verify)
- Rollback (single backup to restore)

This is significantly less complex than Phase 1's 135 cross-file references.

### Clean-Break Philosophy Alignment

This phase exemplifies clean-break principles:
- **Fail-fast**: Missing wrapper functions will produce immediate bash errors
- **No deprecation**: Wrapper definitions deleted completely (no compatibility mode)
- **Git history only**: Backup files are temporary, git provides permanent history
- **Production ready**: 100% test pass rate required before phase completion

### Performance Considerations

Log rotation performance is unaffected by this change:
- Before: `rotate_log_if_needed()` → `rotate_log_file("$AP_LOG_FILE")`
- After: `rotate_log_file("$AP_LOG_FILE")` (direct call)
- Performance gain: Eliminates one function call layer (~1-2μs per rotation check)

### Backward Compatibility

Per project standards, **zero backward compatibility** is provided:
- Scripts using old wrapper names will fail with "command not found"
- This is **desired behavior** (fail-fast guides developers to update)
- No deprecation warnings or transition period
- Rollback mechanism: `git revert` only

## Related Documentation

- **Parent Plan**: `/home/benjamin/.config/.claude/specs/528_create_a_detailed_implementation_plan_to_remove_al/plans/003_unified_compatibility_removal_plan.md`
- **unified-logger.sh**: `/home/benjamin/.config/.claude/lib/unified-logger.sh`
- **Library README**: `/home/benjamin/.config/.claude/lib/README.md`
- **Library API Reference**: `/home/benjamin/.config/.claude/docs/reference/library-api.md`
- **Development Philosophy**: `/home/benjamin/.config/CLAUDE.md` (Development Philosophy section)
- **Testing Protocols**: `/home/benjamin/.config/CLAUDE.md` (Testing Protocols section)

## Appendix: Quick Reference Commands

### Analysis Commands
```bash
# Find all wrapper references
grep -n "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# View context around a specific line
sed -n '120,135p' /home/benjamin/.config/.claude/lib/unified-logger.sh

# Search documentation for wrapper references
grep -r "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/ --include="*.md" --exclude-dir=specs
```

### Update Commands
```bash
# Create backup
cp /home/benjamin/.config/.claude/lib/unified-logger.sh \
   /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-$(date +%Y%m%d-%H%M%S)

# Update adaptive planning call
sed -i '126s/rotate_log_if_needed/rotate_log_file "$AP_LOG_FILE"/' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Update conversion logging calls
sed -i 's/rotate_conversion_log_if_needed/rotate_log_file "$CONVERSION_LOG_FILE"/g' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Delete wrapper functions (pattern-based, safe)
sed -i '/^rotate_log_if_needed()/,/^}$/d' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
sed -i '/^rotate_conversion_log_if_needed()/,/^}$/d' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh

# Delete export statements
sed -i '/export -f rotate_log_if_needed/d; /export -f rotate_conversion_log_if_needed/d' \
  /home/benjamin/.config/.claude/lib/unified-logger.sh
```

### Verification Commands
```bash
# Verify syntax
bash -n /home/benjamin/.config/.claude/lib/unified-logger.sh

# Verify sourcing
(source /home/benjamin/.config/.claude/lib/unified-logger.sh && echo "OK")

# Verify zero wrapper references
grep "rotate_log_if_needed\|rotate_conversion_log_if_needed" \
  /home/benjamin/.config/.claude/lib/unified-logger.sh || echo "Clean"

# Run test suite
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

### Rollback Commands
```bash
# Restore from backup
cp /home/benjamin/.config/.claude/lib/unified-logger.sh.backup-phase3-* \
   /home/benjamin/.config/.claude/lib/unified-logger.sh

# Verify restoration
bash -n /home/benjamin/.config/.claude/lib/unified-logger.sh
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh
```

# /coordinate State Management - Transitions

## Navigation

This document is part of a multi-part guide:
- [Overview](coordinate-state-management-overview.md) - Introduction, subprocess isolation, and stateless recalculation pattern
- [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives, decision matrix, and selective state persistence
- **Transitions** (this file) - Verification checkpoints and troubleshooting guide
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references

---

## State Persistence Implementation

### Implementation Pattern (GitHub Actions Style)

```bash
# Block 1: Initialize workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Cleanup on exit

# Expensive operation - detect CLAUDE_PROJECT_DIR ONCE
# Cached in state file for subsequent blocks (6ms → 2ms)

# Block 2+: Load workflow state
source "${CLAUDE_PROJECT_DIR}/.claude/lib/state-persistence.sh"
load_workflow_state "coordinate_$$"

# Variables restored from state file (no recalculation needed)
echo "$CLAUDE_PROJECT_DIR"  # Available immediately

# Append new state (GitHub Actions $GITHUB_OUTPUT pattern)
append_workflow_state "RESEARCH_COMPLETE" "true"
append_workflow_state "REPORTS_CREATED" "4"

# Save complex state as JSON checkpoint
SUPERVISOR_METADATA='{"topics": 4, "reports": ["r1.md", "r2.md"]}'
save_json_checkpoint "supervisor_metadata" "$SUPERVISOR_METADATA"

# Append benchmark log (JSONL format)
BENCHMARK='{"phase": "research", "duration_ms": 12500, "timestamp": "2025-11-07T14:30:00Z"}'
append_jsonl_log "benchmarks" "$BENCHMARK"
```

### Performance Characteristics

**Measured Performance** (from test suite):
- `init_workflow_state()` (includes git rev-parse): ~6ms
- `load_workflow_state()` (file read): ~2ms
- **Improvement**: 67% faster (6ms → 2ms)
- `save_json_checkpoint()`: 5-10ms (atomic write)
- `load_json_checkpoint()`: 2-5ms (cat + jq validation)
- `append_workflow_state()`: <1ms (echo redirect)
- `append_jsonl_log()`: <1ms (echo redirect)

**Graceful Degradation**:
- Missing state file → automatic recalculation (fallback)
- Missing JSON checkpoint → returns `{}` (empty object)
- Overhead for degradation check: <1ms

### Comparison with Pure Stateless Recalculation

| Aspect | Pure Stateless | Selective Persistence |
|--------|----------------|----------------------|
| **Code complexity** | Lower (no file I/O) | Medium (file I/O + fallback) |
| **Performance (expensive ops)** | Slower (recalculate every time) | Faster (cache once, reuse) |
| **Performance (cheap ops)** | Faster (no I/O overhead) | Use stateless (selective) |
| **Failure modes** | None | I/O errors (mitigated by fallback) |
| **Context reduction** | Limited | 95% via metadata aggregation |
| **Cross-invocation state** | Not possible | Supported (migrations, POCs) |
| **Resumability** | Not possible | Supported (checkpoint files) |

**Recommendation**: Use selective persistence pattern when >50% of state items meet file-based criteria. Continue pure stateless recalculation for simple commands with only fast, deterministic variables.

### Migration from Pure Stateless to Selective Persistence

**Step 1: Identify Critical State Items**
- Run workflow with timing instrumentation
- Identify variables recalculated >5 times per workflow
- Measure recalculation cost for each variable
- Apply decision criteria (7 criteria above)

**Step 2: Implement Selective Persistence**
- Add `state-persistence.sh` to REQUIRED_LIBS
- Initialize state file in Block 1
- Migrate expensive variables to file-based state
- Keep cheap variables as stateless recalculation
- Add graceful degradation (fallback)

**Step 3: Validate Performance**
- Run test suite (ensure 100% pass rate)
- Measure performance improvement (before/after)
- Validate graceful degradation (delete state file mid-workflow)
- Confirm no regressions on existing functionality

**Step 4: Update Documentation**
- Document which variables use file-based state (rationale)
- Update architectural documentation
- Add troubleshooting guide for new failure modes

### Testing Selective State Persistence

The test suite (`.claude/tests/test_state_persistence.sh`) validates:

1. State file initialization (CLAUDE_PROJECT_DIR cached)
2. State file loading (variables restored correctly)
3. Graceful degradation (missing file fallback)
4. GitHub Actions pattern (append_workflow_state accumulation)
5. JSON checkpoint atomic writes (no partial writes)
6. JSON checkpoint loading (validation, missing file handling)
7. JSONL log appending (benchmark accumulation)
8. Subprocess boundary persistence (state survives new bash processes)
9. Multi-workflow isolation (workflows don't interfere)
10. Error handling (missing STATE_FILE, missing CLAUDE_PROJECT_DIR)
11. Performance characteristics (file read faster than git command)

**Test Results**: 18/18 tests passing (100% pass rate)

---

## Verification Checkpoint Pattern

State file verification must account for export format used by `state-persistence.sh`.

### State File Format

The `append_workflow_state()` function writes variables in export format for proper bash sourcing:

```bash
# From .claude/lib/state-persistence.sh:216
echo "export ${key}=\"${value}\"" >> "$STATE_FILE"
```

**Example state file**:
```bash
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_ID="coordinate_1762816945"
export REPORT_PATHS_COUNT="4"
export REPORT_PATH_0="/path/to/report1.md"
```

### Verification Pattern (Correct)

Grep patterns must include the `export` prefix:

```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
if grep -q "^export VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "Variable verified"
else
  echo "Variable missing"
  exit 1
fi
```

### Anti-Pattern (Incorrect)

This pattern will NOT match the export format, causing false negatives:

```bash
# DON'T: This pattern won't match export format
if grep -q "^VARIABLE_NAME=" "$STATE_FILE" 2>/dev/null; then
  echo "Variable verified"  # Will never execute
fi
```

**Why it fails**:
- Pattern expects: `VARIABLE_NAME="value"`
- Actual format: `export VARIABLE_NAME="value"`
- The `^` anchor requires match at start of line
- `export ` prefix prevents match

### Historical Bug

**Spec 644** (2025-11-10): Fixed verification checkpoint in coordinate.md using incorrect pattern.

**Issue**: Grep patterns searched for `^REPORT_PATHS_COUNT=` but state file contained `export REPORT_PATHS_COUNT="4"`, causing verification to fail despite variables being correctly written.

**Impact**: Critical (blocked all coordinate workflows during initialization)

**Fix**: Added `export ` prefix to grep patterns (2 locations in coordinate.md)

**Test Coverage**: Added `.claude/tests/test_coordinate_verification.sh` with 3 unit tests to prevent regression.

### Best Practices

1. **Always include export prefix** in grep patterns when verifying state file variables
2. **Add clarifying comments** documenting expected format (reference state-persistence.sh)
3. **Test verification logic** to catch false negatives/positives
4. **Check actual state file** during debugging (don't trust error messages blindly)

### Example Usage

**Verifying single variable**:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
if grep -q "^export WORKFLOW_ID=" "$STATE_FILE" 2>/dev/null; then
  echo "WORKFLOW_ID verified"
fi
```

**Verifying array of variables**:
```bash
# State file format: "export VAR="value"" (per state-persistence.sh)
for ((i=0; i<COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if grep -q "^export ${var_name}=" "$STATE_FILE" 2>/dev/null; then
    echo "$var_name verified"
  fi
done
```

### Test Suite

Verification checkpoint logic is tested in `.claude/tests/test_coordinate_verification.sh`:

1. **Test 1**: State file format matches `append_workflow_state` output
2. **Test 2**: Verification pattern matches actual state file
3. **Test 3**: False negative prevention (regression test for Spec 644 bug)
4. **Test 4**: Integration test (manual, requires full coordinate workflow)

**Test Results**: 3/3 automated tests passing (100% pass rate)

---

## Troubleshooting Guide

### Quick Reference

| Issue | Symptom | Root Cause | Solution |
|-------|---------|------------|----------|
| Library Function Missing | `command not found` exit 127 | Library not in REQUIRED_LIBS | Add library to scope's REQUIRED_LIBS array |
| Unbound Variable | `VAR: unbound variable` | Variable not recalculated in block | Add stateless recalculation to that block |
| Workflow Stops Early | Phase N skipped unexpectedly | Incorrect PHASES_TO_EXECUTE | Update phase list to match docs |
| REPORT_PATHS_COUNT Unbound | Array variable undefined | Count not exported | Export count with array elements |
| Code Transformation | `!` patterns broken | Bash block >=400 lines | Split into smaller blocks (<300 lines) |
| BASH_SOURCE Empty | Path resolution fails | SlashCommand context | Use CLAUDE_PROJECT_DIR instead |

### Issue 1: "command not found" for Library Functions

**Symptom**: `command not found`, exit code 127

**Root Cause**: Library not in REQUIRED_LIBS array.

**Prevention**: When adding function calls, verify library is sourced in ALL workflow scopes.

**Reference**: Spec 598, Issue 1

---

### Issue 2: "unbound variable" Errors

**Symptom**: `VAR: unbound variable`

**Root Cause**: Variable not recalculated in subsequent bash blocks (subprocess isolation).

**Solution**: Add stateless recalculation of the variable in the bash block where it's used. Find first calculation with `grep -n "VAR=" file.md`, then add same calculation to the block where error occurs.

**Prevention**: Every bash block must calculate all variables it needs. Don't rely on exports.

**Reference**: Spec 598, Issue 2

---

### Issue 3: Workflow Stops Prematurely

**Symptom**: Phase N skipped unexpectedly, no error

**Root Cause**: Incorrect PHASES_TO_EXECUTE list (missing phases).

**Solution**: Compare expected phases from docs with actual PHASES_TO_EXECUTE value and update.

**Prevention**: Verify PHASES_TO_EXECUTE matches documentation. Document phase list in comments.

**Reference**: Spec 598, Issue 3

---

### Issue 4: REPORT_PATHS_COUNT Unbound

**Symptom**: Array count variable undefined with `set -u`

**Root Cause**: Individual array elements exported but count variable not exported.

**Solution**: Export REPORT_PATHS_COUNT alongside individual REPORT_PATH_N variables. Add defensive check: `if [ -z "${REPORT_PATHS_COUNT:-}" ]; then`.

**Prevention**: Always export array count with array elements. Use `${var:-}` pattern.

**Reference**: Spec 637

---

### Issue 5: Code Transformation in Large Blocks

**Symptom**: `!` patterns broken (e.g., `grep -E "!(pattern)"` becomes `"1(pattern)"`)

**Root Cause**: Claude AI transforms bash blocks >=400 lines.

**Solution**: Split into smaller blocks (<300 lines for safety margin).

**Prevention**: Keep bash blocks <300 lines. Split at logical boundaries.

**Reference**: Spec 582

---

### Issue 6: BASH_SOURCE Empty in SlashCommand

**Symptom**: Path resolution with BASH_SOURCE fails

**Root Cause**: BASH_SOURCE not populated in SlashCommand context.

**Solution**: Use CLAUDE_PROJECT_DIR instead:
```bash
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
source "${CLAUDE_PROJECT_DIR}/.claude/lib/library.sh"
```

**Prevention**: Always use CLAUDE_PROJECT_DIR in SlashCommand context. Apply Standard 13 pattern.

**Reference**: Spec 583

---

### Diagnostic Commands

```bash
# Check library definitions
grep -r "function_name()" .claude/lib/

# Find variable assignments
grep -n "VARIABLE_NAME=" .claude/commands/coordinate.md

# Verify library sourcing
grep "REQUIRED_LIBS=" .claude/commands/coordinate.md -A20

# Check phase execution list
grep "PHASES_TO_EXECUTE=" .claude/commands/coordinate.md
```

---

## Related Documentation

- [Overview](coordinate-state-management-overview.md) - Introduction and stateless recalculation pattern
- [States & Decisions](coordinate-state-management-states.md) - Rejected alternatives and decision matrix
- [Examples](coordinate-state-management-examples.md) - FAQ, historical context, and references

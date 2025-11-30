# Minimal Changes for /research Buffer Opening Proof-of-Concept

## Metadata
- **Date**: 2025-11-29
- **Target**: /research command buffer opening fix
- **Approach**: Delayed buffer read (simplest working solution)
- **Estimated Implementation**: 30 minutes
- **Testing Time**: 15 minutes

## Overview

This document specifies the EXACT minimal changes needed to fix buffer opening for the /research command as a proof-of-concept. The fix uses a simple delayed buffer read to allow Block 2 to execute before the hook reads terminal output.

## Root Cause Summary

**Problem**: Stop hook fires when Claude finishes responding, but /research outputs REPORT_CREATED signal in Block 2 which executes AFTER Claude's response completes. Hook reads terminal buffer before Block 2 runs.

**Solution**: Add 300ms delay before reading terminal buffer to allow Block 2 to execute and flush output.

## Required Changes

### Change 1: Add Terminal Output Dump (Diagnostic)

**File**: /home/benjamin/.config/.claude/hooks/post-buffer-opener.sh
**Location**: After line 105 (`debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"`)
**Action**: Insert diagnostic logging

```bash
debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"

# === DIAGNOSTIC: Dump terminal output for debugging ===
if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
  debug_log "=== TERMINAL OUTPUT DUMP START ==="
  local line_num=1
  while IFS= read -r line; do
    debug_log "Line $line_num: $line"
    ((line_num++))
  done <<< "$TERMINAL_OUTPUT"
  debug_log "=== TERMINAL OUTPUT DUMP END ==="

  # Check for block completion markers
  debug_log "Block execution check:"
  if echo "$TERMINAL_OUTPUT" | grep -q "Block 1d:"; then
    debug_log "  ✓ Block 1d executed"
  fi
  if echo "$TERMINAL_OUTPUT" | grep -q "Verifying research artifacts"; then
    debug_log "  ✓ Block 2 executed"
  else
    debug_log "  ✗ Block 2 NOT executed (timing race detected)"
  fi
  if echo "$TERMINAL_OUTPUT" | grep -q "REPORT_CREATED:"; then
    debug_log "  ✓ REPORT_CREATED signal found"
  else
    debug_log "  ✗ REPORT_CREATED signal absent"
  fi
fi
```

**Purpose**: Confirms hypothesis that Block 2 hasn't executed when hook reads buffer.

### Change 2: Add Delayed Buffer Read

**File**: /home/benjamin/.config/.claude/hooks/post-buffer-opener.sh
**Location**: Before line 98 (the `TERMINAL_OUTPUT=$(timeout 5 nvim...` line)
**Action**: Insert delay configuration and sleep

```bash
# === TIMING FIX: Delay before reading terminal buffer ===
# Stop hook fires when Claude finishes responding, but multi-block commands
# execute AFTER the response completes. Delay allows final block (which outputs
# REPORT_CREATED) to execute and flush to terminal buffer.
#
# Configuration:
#   BUFFER_OPENER_DELAY - Seconds to delay (default: 0.3)
#   Set to 0 to disable delay
#
# Rationale:
#   - /research Block 2 outputs REPORT_CREATED signal (line 696)
#   - Block 2 executes after Stop hook fires
#   - 300ms is sufficient for Block 2 execution on typical systems
#   - Configurable for slower systems if needed
BUFFER_OPENER_DELAY="${BUFFER_OPENER_DELAY:-0.3}"

if [[ "${BUFFER_OPENER_DELAY}" != "0" ]]; then
  debug_log "Applying ${BUFFER_OPENER_DELAY}s delay before reading terminal buffer"
  sleep "$BUFFER_OPENER_DELAY"
fi

# === Access terminal buffer output via Neovim RPC ===
# Get the last 100 lines of terminal output (sufficient for completion signals)
TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)
```

**Purpose**: Gives Block 2 time to execute and output signal before hook reads terminal.

## Testing Procedure

### Step 1: Enable Debug Mode

```bash
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3
```

### Step 2: Run /research Command

In Neovim terminal, execute:

```
/research "test buffer opening with delayed read"
```

### Step 3: Verify Results

Check debug log:

```bash
cat /home/benjamin/.config/.claude/tmp/buffer-opener-debug.log | tail -50
```

**Expected Output**:
```
[timestamp] Hook triggered, NVIM=...
[timestamp] Parsed: hook_event=Stop, command=/research, status=success
[timestamp] Eligible command: /research
[timestamp] Applying 0.3s delay before reading terminal buffer
[timestamp] Got terminal output (XXXX chars)
[timestamp] === TERMINAL OUTPUT DUMP START ===
[timestamp] Line 1: ✓ Setup complete, ready for topic naming
...
[timestamp] Line N: Verifying research artifacts...
[timestamp] Line M: REPORT_CREATED: /path/to/report.md
[timestamp] === TERMINAL OUTPUT DUMP END ===
[timestamp] Block execution check:
[timestamp]   ✓ Block 1d executed
[timestamp]   ✓ Block 2 executed
[timestamp]   ✓ REPORT_CREATED signal found
[timestamp] Found REPORT_CREATED: /path/to/report.md
[timestamp] Successfully sent open command for: /path/to/report.md
```

**Success Criteria**:
- [ ] Block 2 output present in dump
- [ ] REPORT_CREATED signal detected
- [ ] Buffer opened in Neovim
- [ ] Report file visible in new buffer/split

### Step 4: Measure Latency

Time from command completion message to buffer appearing:
- Target: <500ms total (300ms delay + 200ms execution/RPC)
- Acceptable: <800ms
- Too slow: >1000ms (consider reducing delay)

### Step 5: Test Edge Cases

```bash
# Test with shorter delay (fast system)
export BUFFER_OPENER_DELAY=0.1
# Run /research, verify still works

# Test with longer delay (slow system)
export BUFFER_OPENER_DELAY=0.5
# Run /research, verify still works

# Test with delay disabled (should fail - proves fix is needed)
export BUFFER_OPENER_DELAY=0
# Run /research, verify FAILS (no buffer opens)
# Re-enable: export BUFFER_OPENER_DELAY=0.3
```

## Rollback Procedure

If delayed read causes issues:

1. Disable delay:
   ```bash
   export BUFFER_OPENER_DELAY=0
   ```

2. Or revert hook changes:
   ```bash
   git checkout .claude/hooks/post-buffer-opener.sh
   ```

## Configuration Guide

### Environment Variables

- `BUFFER_OPENER_DEBUG` - Enable diagnostic logging (default: false)
- `BUFFER_OPENER_DELAY` - Delay in seconds before reading terminal (default: 0.3)
- `BUFFER_OPENER_ENABLED` - Enable/disable feature entirely (default: true)

### Tuning for Different Systems

**Fast system** (modern CPU, fast terminal):
```bash
export BUFFER_OPENER_DELAY=0.2
```

**Slow system** (older CPU, slow terminal emulator):
```bash
export BUFFER_OPENER_DELAY=0.5
```

**Remote/SSH session** (network latency):
```bash
export BUFFER_OPENER_DELAY=0.8
```

**Disable feature**:
```bash
export BUFFER_OPENER_ENABLED=false
```

## Success Metrics

### Phase 1: Diagnostic Verification
- [x] Terminal output dump implemented
- [ ] /research run with debug enabled
- [ ] Debug log confirms Block 2 absence before delay
- [ ] Debug log confirms Block 2 presence after delay

### Phase 2: Delayed Read Implementation
- [ ] Delay code implemented
- [ ] Default 300ms delay configured
- [ ] /research buffer opens successfully
- [ ] Latency measured <500ms
- [ ] Edge cases tested (0.1s, 0.5s, 0s delays)

### Phase 3: Success Rate Validation
- [ ] 10 consecutive /research runs succeed
- [ ] Success rate ≥95% (at least 19/20 attempts)
- [ ] No regressions in other hooks
- [ ] No regressions in non-eligible commands

## Next Steps After POC Success

Once /research proof-of-concept achieves ≥95% success rate:

1. **Document Configuration**: Update /home/benjamin/.config/.claude/hooks/README.md
2. **Test Other Commands**: Verify works for /plan, /debug, /repair, /revise
3. **Evaluate Robustness**: If success rate <95%, implement polling (Approach 2B)
4. **Update Plan 851**: Mark complete with lessons learned
5. **User Guide**: Create troubleshooting section for buffer opening issues

## Implementation Checklist

- [ ] Change 1: Add terminal output dump (after line 105)
- [ ] Change 2: Add delayed buffer read (before line 98)
- [ ] Test: Run /research with debug enabled
- [ ] Verify: Check debug log shows Block 2 executed
- [ ] Verify: Buffer opens automatically
- [ ] Measure: Latency <500ms
- [ ] Test: Edge cases (various delay values)
- [ ] Validate: 10+ consecutive successes

## Alternative: Polling Implementation

If delayed read achieves <95% success rate, implement polling retry instead:

**Location**: Replace single read at line 98
**Implementation**: See [Approach 2B in Diagnostic Strategy Report](002-research-command-diagnostic-strategy.md#approach-2b-multi-read-polling-robust)

**Trade-offs**:
- More complex code (30 lines vs 5 lines)
- Multiple RPC calls (though cheap)
- More robust across timing variations
- Still <500ms total delay (5 retries × 100ms)

## Code Diff Summary

```diff
--- a/.claude/hooks/post-buffer-opener.sh
+++ b/.claude/hooks/post-buffer-opener.sh
@@ -95,6 +95,44 @@
     ;;
 esac

+# === TIMING FIX: Delay before reading terminal buffer ===
+# Stop hook fires when Claude finishes responding, but multi-block commands
+# execute AFTER the response completes. Delay allows final block (which outputs
+# REPORT_CREATED) to execute and flush to terminal buffer.
+BUFFER_OPENER_DELAY="${BUFFER_OPENER_DELAY:-0.3}"
+
+if [[ "${BUFFER_OPENER_DELAY}" != "0" ]]; then
+  debug_log "Applying ${BUFFER_OPENER_DELAY}s delay before reading terminal buffer"
+  sleep "$BUFFER_OPENER_DELAY"
+fi
+
 # === Access terminal buffer output via Neovim RPC ===
 TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)

@@ -105,6 +143,29 @@
 fi

 debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"
+
+# === DIAGNOSTIC: Dump terminal output for debugging ===
+if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
+  debug_log "=== TERMINAL OUTPUT DUMP START ==="
+  local line_num=1
+  while IFS= read -r line; do
+    debug_log "Line $line_num: $line"
+    ((line_num++))
+  done <<< "$TERMINAL_OUTPUT"
+  debug_log "=== TERMINAL OUTPUT DUMP END ==="
+
+  # Check for block completion markers
+  debug_log "Block execution check:"
+  echo "$TERMINAL_OUTPUT" | grep -q "Block 1d:" && debug_log "  ✓ Block 1d executed"
+  if echo "$TERMINAL_OUTPUT" | grep -q "Verifying research artifacts"; then
+    debug_log "  ✓ Block 2 executed"
+  else
+    debug_log "  ✗ Block 2 NOT executed (timing race detected)"
+  fi
+  echo "$TERMINAL_OUTPUT" | grep -q "REPORT_CREATED:" && \
+    debug_log "  ✓ REPORT_CREATED signal found" || \
+    debug_log "  ✗ REPORT_CREATED signal absent"
+fi

 # === Extract completion signals with priority logic ===
```

**Total Changes**:
- Lines added: 44
- Lines modified: 0
- Lines deleted: 0
- Complexity: Low (simple sleep and debug logging)

## Conclusion

This minimal change set (44 lines) provides:

1. **Diagnostic capability**: Confirms timing race hypothesis
2. **Simple fix**: 300ms delay allows Block 2 to execute
3. **Configurability**: Tunable for different system speeds
4. **Low risk**: Non-invasive, easily reversible
5. **Fast implementation**: 30-minute implementation, 15-minute testing

Expected outcome: ≥95% success rate for /research buffer opening, proving the concept before expanding to other workflow commands.

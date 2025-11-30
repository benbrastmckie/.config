# Research Command Buffer Opening Diagnostic Strategy

## Metadata
- **Date**: 2025-11-29
- **Research Type**: Plan revision insights
- **Target**: /research command buffer opening diagnostic implementation
- **Root Analysis**: [Hook Buffer Opening Root Cause Analysis](001-hook-buffer-opening-root-cause-analysis.md)
- **Implementation Plan**: [Hook Buffer Opening Fix Plan](../plans/001-hook-buffer-opening-issue-plan.md)

## Executive Summary

This report provides detailed diagnostic strategy for fixing the /research command buffer opening issue as a proof-of-concept before expanding to all workflow commands. Analysis confirms the root cause: **Stop hook fires immediately after Claude finishes responding, but the REPORT_CREATED signal is output in Block 2 which executes AFTER the Task tool delegation in Block 1d**. The Stop hook reads terminal output before Block 2 executes, explaining why signals are never visible.

**Critical Finding**: The Stop hook fires based on **Claude's response completion**, not bash script completion. Multi-block commands have their blocks executed sequentially AFTER Claude finishes responding, meaning the Stop hook can fire between blocks.

## Root Cause Confirmation

### Stop Hook Timing Behavior

Based on official documentation and observed behavior:

1. **Stop hook trigger**: "when the agent finishes responding" (Claude Code Docs)
2. **Known bug**: "Stop hook is not triggered if Claude ends its turn immediately after using a tool" (GitHub Issue #3113)
3. **Observed pattern**: Hook captures 2343 chars of terminal output but no REPORT_CREATED signal

### /research Command Execution Flow

The /research command has a 4-block structure:

```
Block 1a: Initial Setup and State Initialization
  - Argument capture
  - Library sourcing
  - State machine init
  - Path initialization prep

Block 1b: Topic Name Generation (Task tool)
  - Invokes topic-naming-agent
  - Agent returns: TOPIC_NAME_GENERATED: <name>
  - Claude response includes this Task invocation

Block 1c: Topic Path Initialization
  - Reads topic name from agent output
  - Initializes workflow paths
  - Persists state for Block 1d

Block 1d: Research Initiation (Task tool)
  - Invokes research-specialist agent
  - Agent creates research reports
  - Agent returns: REPORT_CREATED: /path/to/report.md
  - Claude response includes this Task invocation

  ← Stop hook fires HERE (after Claude finishes responding)
  ← Hook reads terminal buffer: sees Block 1a-1d output
  ← NO Block 2 output visible yet

Block 2: Verification and Completion
  - Loads state from Block 1
  - Verifies research artifacts
  - Echoes: "REPORT_CREATED: $LATEST_REPORT" (line 696)
  - This is where the signal SHOULD be for hook to see
```

### Why the Hook Fails

**Timing Race Condition**:
1. Claude finishes responding (includes Task tool invocations in Block 1b and 1d)
2. Stop hook fires immediately
3. Hook reads terminal buffer via Neovim RPC
4. Terminal buffer contains: Block 1a, 1b, 1c, 1d output
5. Terminal buffer does NOT contain: Block 2 output (hasn't executed yet)
6. Hook searches for REPORT_CREATED signal
7. Hook finds: Nothing (signal is in Block 2 which hasn't run)

**The Problem**: Multi-block bash commands execute sequentially AFTER Claude's response completes. The Stop hook fires when Claude finishes responding, which is BEFORE the final blocks execute.

## Diagnostic Debugging Strategy

### Phase 1: Confirm Hypothesis with Terminal Output Dump

**Objective**: Capture the exact terminal output visible to the hook to confirm Block 2 hasn't executed yet.

**Implementation** (post-buffer-opener.sh, after line 105):

```bash
debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars)"

# === DIAGNOSTIC: Dump full terminal output ===
if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
  debug_log "=== TERMINAL OUTPUT DUMP START ==="
  # Log each line with line number for analysis
  local line_num=1
  while IFS= read -r line; do
    debug_log "Line $line_num: $line"
    ((line_num++))
  done <<< "$TERMINAL_OUTPUT"
  debug_log "=== TERMINAL OUTPUT DUMP END ==="

  # Log specific markers to check block execution
  debug_log "Checking for block markers:"
  if echo "$TERMINAL_OUTPUT" | grep -q "Block 1a:"; then
    debug_log "  ✓ Block 1a output present"
  fi
  if echo "$TERMINAL_OUTPUT" | grep -q "Block 1d:"; then
    debug_log "  ✓ Block 1d output present"
  fi
  if echo "$TERMINAL_OUTPUT" | grep -q "Block 2:"; then
    debug_log "  ✓ Block 2 output present"
  else
    debug_log "  ✗ Block 2 output ABSENT (confirms hypothesis)"
  fi
  if echo "$TERMINAL_OUTPUT" | grep -q "REPORT_CREATED:"; then
    debug_log "  ✓ REPORT_CREATED signal present"
  else
    debug_log "  ✗ REPORT_CREATED signal ABSENT"
  fi
fi
```

**Expected Results**:
- Terminal output shows Block 1a, 1b, 1c, 1d
- Terminal output does NOT show Block 2
- No REPORT_CREATED signal visible
- Confirms timing race hypothesis

### Phase 2: Minimal Fix for /research Proof-of-Concept

**Strategy**: Three progressive approaches, implement simplest working solution.

#### Approach 2A: Delayed Buffer Read (Simplest)

Add 200-500ms delay before reading terminal buffer to allow Block 2 to execute and flush output.

**Implementation** (post-buffer-opener.sh, before line 98):

```bash
# === TIMING FIX: Delay before reading terminal buffer ===
# The Stop hook fires when Claude finishes responding, but multi-block
# bash commands execute AFTER the response completes. We need to wait
# for the final block (which outputs REPORT_CREATED) to execute and flush.
BUFFER_OPENER_DELAY="${BUFFER_OPENER_DELAY:-0.3}"  # Default 300ms
debug_log "Applying delay of ${BUFFER_OPENER_DELAY}s before reading terminal buffer"
sleep "$BUFFER_OPENER_DELAY"
```

**Pros**:
- Dead simple (5 lines of code)
- Highly likely to work (300ms is plenty for Block 2 execution)
- Configurable via env var

**Cons**:
- Artificial delay feels hacky
- Fixed delay may not work for slower systems
- Doesn't fundamentally solve the race condition

#### Approach 2B: Multi-Read Polling (Robust)

Retry terminal buffer read up to 5 times with 100ms intervals, looking for completion signal.

**Implementation** (post-buffer-opener.sh, replace single read at line 98):

```bash
# === TIMING FIX: Polling retry for completion signal ===
# Multi-block commands execute after Claude response completes, so we
# need to poll the terminal buffer until the final block outputs signal.
BUFFER_OPENER_MAX_RETRIES="${BUFFER_OPENER_MAX_RETRIES:-5}"
BUFFER_OPENER_RETRY_DELAY="${BUFFER_OPENER_RETRY_DELAY:-0.1}"

TERMINAL_OUTPUT=""
FOUND_SIGNAL=false
for ((attempt=1; attempt<=BUFFER_OPENER_MAX_RETRIES; attempt++)); do
  debug_log "Attempt $attempt/$BUFFER_OPENER_MAX_RETRIES: Reading terminal buffer"

  # Read terminal buffer
  TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)

  if [[ -z "$TERMINAL_OUTPUT" ]]; then
    debug_log "  Failed to get terminal output"
    continue
  fi

  # Check if signal is present (any of the completion signals)
  if echo "$TERMINAL_OUTPUT" | grep -qP 'PLAN_CREATED:|PLAN_REVISED:|REPORT_CREATED:|DEBUG_REPORT_CREATED:|summary_path:'; then
    debug_log "  ✓ Found completion signal on attempt $attempt"
    FOUND_SIGNAL=true
    break
  fi

  debug_log "  No signal found, retrying in ${BUFFER_OPENER_RETRY_DELAY}s..."
  sleep "$BUFFER_OPENER_RETRY_DELAY"
done

if [[ "$FOUND_SIGNAL" == "false" ]]; then
  debug_log "No completion signal found after $BUFFER_OPENER_MAX_RETRIES attempts"
  exit 0
fi

debug_log "Got terminal output (${#TERMINAL_OUTPUT} chars) after $attempt attempt(s)"
```

**Pros**:
- Robust across timing variations
- Fails fast if signal appears quickly
- Max delay still under 500ms (5 × 100ms)
- Configurable retry count and delay

**Cons**:
- More complex code
- Multiple RPC calls (though cheap operation)
- Still fundamentally a workaround

#### Approach 2C: State File Signal Passing (Fallback Only)

**Note**: This approach requires modifying commands, violating Plan 851's hook-only design. Only implement if polling fails.

Modify /research Block 2 to write completion signal to state file:

```bash
# In /research Block 2, after line 696:
echo "REPORT_CREATED: $LATEST_REPORT"

# Also write to state file for hook consumption
SIGNAL_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/last_completion_signal.txt"
cat > "$SIGNAL_FILE" <<EOF
{
  "signal_type": "REPORT_CREATED",
  "artifact_path": "$LATEST_REPORT",
  "command": "/research",
  "timestamp": $(date +%s)
}
EOF
```

Hook reads state file instead of terminal buffer:

```bash
# In post-buffer-opener.sh, replace terminal buffer reading:
SIGNAL_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/tmp/last_completion_signal.txt"

if [[ ! -f "$SIGNAL_FILE" ]]; then
  debug_log "No signal file found"
  exit 0
fi

# Read and parse signal
SIGNAL_JSON=$(cat "$SIGNAL_FILE")
SIGNAL_TYPE=$(echo "$SIGNAL_JSON" | jq -r '.signal_type')
ARTIFACT_PATH=$(echo "$SIGNAL_JSON" | jq -r '.artifact_path')
SIGNAL_TIMESTAMP=$(echo "$SIGNAL_JSON" | jq -r '.timestamp')

# Verify signal is recent (within 5 seconds)
CURRENT_TIME=$(date +%s)
SIGNAL_AGE=$((CURRENT_TIME - SIGNAL_TIMESTAMP))
if [[ $SIGNAL_AGE -gt 5 ]]; then
  debug_log "Signal too old (${SIGNAL_AGE}s), ignoring"
  exit 0
fi

# Clean up signal file after reading
rm -f "$SIGNAL_FILE"

debug_log "Found $SIGNAL_TYPE signal via state file: $ARTIFACT_PATH"
```

**Pros**:
- 100% reliable (no timing dependency)
- No race conditions possible
- Clean separation of concerns

**Cons**:
- Requires modifying all workflow commands
- Increases maintenance surface
- Violates Plan 851's hook-only design
- State file cleanup complexity

## Recommended Implementation Sequence

### Phase 1: Debug Verification (1 hour)
1. Add terminal output dump to hook
2. Run /research command in Neovim
3. Examine debug log to confirm:
   - Block 2 output is absent
   - REPORT_CREATED signal is absent
   - Hypothesis confirmed

### Phase 2: Simple Fix (1.5 hours)
1. Implement Approach 2A (delayed read)
2. Test with /research command
3. If success rate ≥95%: Done!
4. If success rate <95%: Proceed to Phase 3

### Phase 3: Robust Fix (2 hours)
1. Implement Approach 2B (polling)
2. Test with /research, /plan, /debug commands
3. Measure success rate and latency
4. If success rate ≥95%: Done!
5. If success rate <95%: Consider Approach 2C

### Phase 4: Conditional Fallback (2.5 hours, if needed)
1. Only if polling fails to achieve 95% success rate
2. Implement Approach 2C (state file)
3. Document trade-offs and migration plan

## Success Metrics

### Diagnostic Phase
- [ ] Terminal output dump shows Block 2 is absent
- [ ] REPORT_CREATED signal confirmed absent
- [ ] Hypothesis validated

### Implementation Phase
- [ ] /research buffer opens automatically ≥95% of time
- [ ] Latency from command completion to buffer open <500ms
- [ ] No regressions in existing hook functionality
- [ ] Solution works consistently across fast/slow systems

## Testing Plan

### Unit Tests
```bash
# Test delayed read with /research
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3
# Run /research in Neovim terminal
# Check: buffer opens, debug log shows signal found

# Test polling with various retry counts
export BUFFER_OPENER_MAX_RETRIES=3
export BUFFER_OPENER_RETRY_DELAY=0.1
# Run /research in Neovim terminal
# Check: buffer opens, debug log shows attempt count
```

### Integration Tests
```bash
# Test across all workflow commands
for cmd in /research /plan /debug /repair; do
  echo "Testing $cmd..."
  # Run command in Neovim terminal
  # Verify buffer opens
  # Record success/failure
done

# Calculate success rate
# Measure P50/P95 latency
```

### Edge Cases
```bash
# Test very fast completion (signal already present)
# Test very slow completion (multiple retries needed)
# Test command failure (no signal ever appears)
# Test with multiple signals (priority logic)
```

## Implementation Notes

### Critical Discovery: Multi-Block Execution Timing

The bash block execution model documentation confirms that each block runs as a **separate subprocess**. However, the critical timing insight is:

> "The Stop hook fires when the agent finishes responding"

Combined with multi-block execution being sequential, this means:
1. Claude responds (includes Task tool invocations)
2. Stop hook fires
3. Bash blocks execute sequentially AFTER response

This is the fundamental race condition causing the issue.

### Why This Wasn't Caught Earlier

Plan 851 assumed:
1. Stop hook fires after ALL bash blocks complete
2. Terminal buffer contains complete command output
3. Signals would be visible when hook reads buffer

Reality:
1. Stop hook fires after Claude RESPONSE completes
2. Terminal buffer only contains executed blocks
3. Final blocks haven't executed when hook reads buffer

### Minimal Change Principle

For /research proof-of-concept:
- Approach 2A (delayed read): 5 lines added to hook
- Approach 2B (polling): 30 lines added to hook
- Approach 2C (state file): Requires command modifications

**Recommendation**: Start with 2A, proceed to 2B if needed, avoid 2C unless absolutely necessary.

## Alternative Consideration: Command-Side Signal Output

Instead of fixing the hook timing, could we output the signal EARLIER in the command execution?

**Option**: Output REPORT_CREATED in Block 1d immediately after Task tool completion:

```bash
# In /research Block 1d, after Task invocation:
Task {
  # research-specialist creates reports
}

# Immediately output signal (visible to Stop hook)
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
  echo "REPORT_CREATED: $LATEST_REPORT"
fi
```

**Pros**:
- Signal visible when Stop hook fires
- No hook timing changes needed
- Clean command-side solution

**Cons**:
- Requires modifying all workflow commands
- Signal output happens DURING execution, not at completion
- Violates "completion signal" semantic
- Still need Block 2 for verification and summary

**Verdict**: Not recommended. The signal should semantically indicate command COMPLETION, not mid-execution status.

## Next Steps

1. **Implement Phase 1**: Add diagnostic output dump to hook
2. **Validate Hypothesis**: Run /research and confirm Block 2 absence
3. **Implement Approach 2A**: Add delayed buffer read
4. **Test /research**: Measure success rate and latency
5. **Decision Point**: If ≥95% success, stop here. Otherwise proceed to 2B.
6. **Document Solution**: Update hook README with configuration guide
7. **Expand to Other Commands**: Once proven with /research, verify works for /plan, /debug, /repair

## References

- [Hooks Reference - Claude Code Docs](https://code.claude.com/docs/en/hooks)
- [Stop Hook Bug #3113](https://github.com/anthropics/claude-code/issues/3113)
- [Bash Block Execution Model](/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md)
- [Plan 851 Implementation](/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md)
- [Hook Buffer Opening Root Cause Analysis](001-hook-buffer-opening-root-cause-analysis.md)

## Appendix: Debug Log Example

Expected debug log output after Phase 1 implementation:

```
[2025-11-29 18:00:00] Hook triggered, NVIM=/run/user/1000/nvim.12345.0
[2025-11-29 18:00:00] Received JSON: {"hook_event_name":"Stop","command":"/research","status":"success"}
[2025-11-29 18:00:00] Parsed: hook_event=Stop, command=/research, status=success
[2025-11-29 18:00:00] Eligible command: /research
[2025-11-29 18:00:00] Got terminal output (2343 chars)
[2025-11-29 18:00:00] === TERMINAL OUTPUT DUMP START ===
[2025-11-29 18:00:00] Line 1: ✓ Setup complete, ready for topic naming
[2025-11-29 18:00:00] Line 2: [Task invocation: topic-naming-agent]
[2025-11-29 18:00:00] Line 3: TOPIC_NAME_GENERATED: hook_buffer_opening_issue
[2025-11-29 18:00:00] Line 4: Setup complete: research_1732901234 (research-only, complexity: 2)
[2025-11-29 18:00:00] Line 5: Research directory: /path/to/reports
[2025-11-29 18:00:00] Line 6: [Task invocation: research-specialist]
[2025-11-29 18:00:00] Line 7: REPORT_CREATED: /path/to/report.md (from agent)
[2025-11-29 18:00:00] === TERMINAL OUTPUT DUMP END ===
[2025-11-29 18:00:00] Checking for block markers:
[2025-11-29 18:00:00]   ✓ Block 1a output present
[2025-11-29 18:00:00]   ✓ Block 1d output present
[2025-11-29 18:00:00]   ✗ Block 2 output ABSENT (confirms hypothesis)
[2025-11-29 18:00:00]   ✗ REPORT_CREATED signal ABSENT (agent signal not extracted by hook regex)
[2025-11-29 18:00:00] No completion signal found in output
```

**Key Observation**: The REPORT_CREATED from the agent (line 7) is present, but the hook's regex doesn't match it because:
1. It's part of the Task tool response text, not a standalone signal line
2. The hook looks for `REPORT_CREATED:\s*\K[^\s]+` which expects the pattern at start of line
3. The actual command-level signal `echo "REPORT_CREATED: $LATEST_REPORT"` is in Block 2 which hasn't executed

This confirms: We need Block 2 output to be visible to the hook.

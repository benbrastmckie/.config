# Hook-Based Buffer Opening Failure - Root Cause Analysis

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Hook-based buffer opening implementation analysis to identify why buffers don't open automatically
- **Report Type**: Root cause analysis, codebase investigation, integration debugging

## Executive Summary

The hook-based buffer opening feature (Plan 851) was fully implemented according to specifications but fails to open buffers automatically due to a **timing/visibility issue**: the completion signals (REPORT_CREATED, PLAN_CREATED, etc.) are not visible in the terminal buffer output when the Stop hook executes. The hook correctly triggers, parses JSON input, accesses terminal output (2343 chars captured), but finds no completion signals in that output. The root cause is likely one of: (1) timing - Stop hook fires before final command output is fully written to terminal buffer, (2) output buffering - completion signals are buffered and not flushed to terminal, or (3) output routing - Task tool subagent output may not be routed to parent terminal buffer in Claude Code's execution model.

## Findings

### 1. Implementation Status - All Components Functional

**Hook Script Analysis** (`/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`):
- Fully implemented according to Plan 851 specifications
- Line 43: Fail-fast NVIM check executes immediately (zero overhead design)
- Lines 59-76: JSON parsing working correctly (jq with fallback)
- Lines 86-94: Command eligibility filtering includes all workflow commands
- Lines 96-103: Terminal output access via Neovim RPC functional
- Lines 107-155: Completion signal extraction with correct priority logic (PLAN > IMPLEMENTATION_COMPLETE > DEBUG_REPORT > REPORT)
- Lines 157-167: Path validation before buffer opening
- Lines 171-189: RPC buffer opening with buffer-opener.lua module fallback

**Hook Registration** (`/home/benjamin/.config/.claude/settings.local.json`):
- Lines 49-52: post-buffer-opener.sh correctly registered in hooks.Stop array
- Uses $CLAUDE_PROJECT_DIR for portable path
- Executes alongside other hooks (metrics, TTS)

**Buffer Opener Module** (`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua`):
- Lines 86-131: Context-aware buffer opening implemented
- Lines 36-53: Terminal buffer detection and editor window finding
- Lines 99-118: Proper path escaping and file validation
- Integration with notification system (lines 56-81)

**Verdict**: All implementation components are present and correctly implemented per Plan 851 specifications.

### 2. Hook Execution Evidence - Working But Not Finding Signals

**Debug Log Analysis** (`/home/benjamin/.config/.claude/tmp/buffer-opener-debug.log`):

```
[2025-11-27 13:33:49] Hook triggered, NVIM=/run/user/1000/nvim.2400209.0
[2025-11-27 13:33:49] Received JSON: {"hook_event_name":"Stop","command":"/plan","status":"success","cwd":"/home/benjamin/.config"}
[2025-11-27 13:33:49] Parsed: hook_event=Stop, command=/plan, status=success
[2025-11-27 13:33:49] Eligible command: /plan
[2025-11-27 13:33:49] Got terminal output (2343 chars)
[2025-11-27 13:33:49] No completion signal found in output
```

**Key Observations**:
1. Hook triggers successfully (NVIM environment variable set)
2. JSON parsing works correctly (command=/plan, status=success)
3. Command is eligible for buffer opening (/plan is in eligible list)
4. Terminal output access successful (2343 characters captured)
5. **CRITICAL**: No completion signal found in those 2343 characters

**Regex Pattern Verification**:
The hook uses these patterns (lines 109-155 in post-buffer-opener.sh):
- `PLAN_CREATED:\s*\K[^\s]+` - Verified working with test data
- `PLAN_REVISED:\s*\K[^\s]+` - Verified working with test data
- `summary_path:\s*\K[^\s]+` - Verified working with test data
- `DEBUG_REPORT_CREATED:\s*\K[^\s]+` - Verified working with test data
- `REPORT_CREATED:\s*\K[^\s]+` - Verified working with test data

Test confirmed: `echo "REPORT_CREATED: /path/to/report.md" | grep -oP 'REPORT_CREATED:\s*\K[^\s]+'` correctly extracts `/path/to/report.md`.

### 3. Command Output Format - Signals Should Be Present

**Research Command Analysis** (`/home/benjamin/.config/.claude/commands/research.md`):

Block 2 (lines 690-698) explicitly outputs completion signal:
```bash
# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
# Get most recent report from research directory
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ] && [ -f "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi
```

**Plan Command Analysis** (`/home/benjamin/.config/.claude/commands/plan.md`):
- Similar pattern found at end of Block 5
- Outputs `PLAN_CREATED: $PLAN_PATH` after plan file creation

**Agent Return Format** (`/home/benjamin/.config/.claude/agents/research-specialist.md`):
- Lines 175-190: Agent instructed to return `REPORT_CREATED: [path]` as final output
- Research-specialist compliance verified

**Expected Output Flow**:
1. Command starts (Block 1: setup and state initialization)
2. Command delegates to research-specialist via Task tool (Block 1d)
3. Agent completes research, returns `REPORT_CREATED: [path]`
4. Command verification and completion (Block 2)
5. **Command outputs final REPORT_CREATED signal** (Block 2, lines 690-698)
6. Stop hook should fire AFTER step 5 completes

### 4. Terminal Buffer Output Access - Working But Incomplete

**RPC Call Analysis** (post-buffer-opener.sh, line 98):
```bash
TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr 'join(getbufline(bufnr("%"), max([1, line("$")-100]), "$"), "\n")' 2>/dev/null)
```

This reads the **last 100 lines** from the terminal buffer using Neovim's remote API.

**Potential Issues**:
1. **Timing**: Stop hook fires before command writes final output to terminal
2. **Buffering**: Terminal output may be buffered, not flushed when hook reads
3. **Output Routing**: Task tool subagent output may not appear in parent terminal buffer
4. **Line Count**: 2343 characters might be less than 100 lines if output is verbose

### 5. Stop Hook Timing - Suspected Root Cause

**Hook Documentation** (`/home/benjamin/.config/.claude/hooks/README.md`, lines 39-40):
> "Triggered when Claude completes a response and is ready for input."

This suggests the hook fires AFTER command completion, but there may be a subtle timing issue:

**Hypothesis A - Output Buffering Race**:
```
Timeline:
1. Command executes bash blocks
2. Block 2 runs: echo "REPORT_CREATED: $PATH"
3. Output is buffered in bash/terminal
4. Stop hook fires (Claude response complete)
5. Hook reads terminal buffer via RPC
6. Buffered output not yet flushed to terminal
7. Hook sees incomplete output (2343 chars without signal)
8. Buffer flush happens after hook completes
```

**Hypothesis B - Task Tool Output Isolation**:
```
Timeline:
1. Command invokes research-specialist via Task tool
2. Agent output goes to separate subagent context
3. Command receives agent return value internally
4. Command continues execution (Block 2)
5. Command outputs REPORT_CREATED signal
6. Stop hook fires
7. Hook reads terminal buffer
8. Signal not visible because command output incomplete
```

**Hypothesis C - Multiple Bash Blocks**:
```
Timeline:
1. Block 1 executes (setup)
2. Block 1d executes (Task tool delegation)
3. Stop hook fires AFTER Block 1d (treating it as completion)
4. Block 2 hasn't executed yet (verification and signal output)
5. Hook sees output from Blocks 1-1d only (2343 chars)
6. Block 2 executes later, outputs signal
```

### 6. Plan 851 Assumptions vs Reality

**Plan 851 Assumption** (line 84-85):
> "Hooks receive JSON metadata but not command output, requiring solution for accessing completion signals"

**Plan 851 Solution** (lines 218-222):
> "Terminal Output Access: Hook reads terminal buffer output directly via Neovim RPC"

**Reality Check**:
- Hook successfully accesses terminal buffer via RPC ✓
- Hook captures 2343 characters of output ✓
- **Completion signals NOT present in captured output** ✗

**Plan 851 Did Not Account For**:
1. Timing between Stop hook trigger and final command output
2. Bash block execution model where commands may span multiple blocks
3. Output buffering/flushing timing relative to hook execution
4. Possibility that Task tool output is not routed to terminal buffer

### 7. Comparison with Command Metrics Hook

**Post-Command-Metrics Hook** (`/home/benjamin/.config/.claude/hooks/post-command-metrics.sh`):
- Also registered for Stop event
- Does NOT access terminal buffer output
- Only uses JSON metadata (command name, status, timing)
- Successfully tracks metrics without needing command output

This suggests the metrics hook doesn't face the same issue because it doesn't depend on reading command output.

### 8. Alternative Signal Detection Approaches

**Approach 1: File System Watching** (rejected in Plan 851):
- Monitor specs/*/reports/ and specs/*/plans/ directories
- Detect new file creation
- Open most recently created file
- **Advantage**: Doesn't depend on terminal output
- **Disadvantage**: Higher resource overhead, less precise (can't distinguish primary vs intermediate artifacts)

**Approach 2: State File Reading**:
- Commands could write completion signals to state file
- Hook reads state file instead of terminal buffer
- **Advantage**: Reliable, no timing issues
- **Disadvantage**: Requires command modifications

**Approach 3: Delayed Buffer Read**:
- Hook waits 100-500ms before reading terminal buffer
- Allows output buffering to flush
- **Advantage**: Simple fix
- **Disadvantage**: Introduces artificial delay, may not be reliable

**Approach 4: Multi-Read Polling**:
- Hook reads terminal buffer multiple times with small delays
- Checks for signal presence, retries if not found
- **Advantage**: More robust against timing issues
- **Disadvantage**: More complex, higher latency

## Recommendations

### 1. Immediate Debug Step - Capture Full Terminal Output
**Priority: Critical** | **Effort: 15 minutes**

Modify hook to log the actual terminal output it captures for debugging:

```bash
# In post-buffer-opener.sh after line 105
if [[ "${BUFFER_OPENER_DEBUG:-false}" == "true" ]]; then
  echo "=== TERMINAL OUTPUT DUMP ===" >> "$log_file"
  echo "$TERMINAL_OUTPUT" >> "$log_file"
  echo "=== END TERMINAL OUTPUT ===" >> "$log_file"
fi
```

Run `/plan` or `/research` command and examine debug log to see what output the hook actually captures. This will confirm whether the signal is present but not matched, or truly absent from the buffer.

### 2. Implement Delayed Buffer Read
**Priority: High** | **Effort: 30 minutes**

Add a small delay before reading terminal buffer to allow output flushing:

```bash
# In post-buffer-opener.sh after line 95 (before terminal read)
# Allow output buffering to flush (Claude Code may still be writing)
sleep 0.2  # 200ms delay
```

Test if this resolves the issue. If successful, this is the simplest fix with minimal complexity.

### 3. Implement Multi-Read Polling Strategy
**Priority: Medium** | **Effort: 1 hour**

Replace single terminal read with polling approach:

```bash
# Retry logic for finding completion signal
MAX_RETRIES=5
RETRY_DELAY=0.1  # 100ms
ARTIFACT_PATH=""

for ((i=1; i<=MAX_RETRIES; i++)); do
  TERMINAL_OUTPUT=$(timeout 5 nvim --server "$NVIM" --remote-expr '...')

  # Try to extract signal
  ARTIFACT_PATH=$(echo "$TERMINAL_OUTPUT" | grep -oP 'PLAN_CREATED:\s*\K[^\s]+' | tail -1)

  if [[ -n "$ARTIFACT_PATH" ]]; then
    debug_log "Found signal on attempt $i"
    break
  fi

  [[ $i -lt $MAX_RETRIES ]] && sleep $RETRY_DELAY
done
```

This provides robustness against timing issues while keeping total delay under 500ms.

### 4. Investigate Claude Code's Bash Block Execution Model
**Priority: Medium** | **Effort: 1-2 hours**

Research how Claude Code handles multi-block bash execution in commands:
- Do Stop hooks fire after each block or only at final completion?
- Is there a different hook event that fires after ALL blocks complete?
- Can commands specify when Stop hook should fire?

Check Claude Code documentation or test with multiple-block commands to understand execution model.

### 5. Alternative: State File Based Signal Passing
**Priority: Low** | **Effort: 2-3 hours**

Modify commands to write completion signals to a state file that hooks can reliably read:

```bash
# In command Block 2 (alongside existing echo)
SIGNAL_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/last_completion_signal.txt"
echo "REPORT_CREATED: $LATEST_REPORT" > "$SIGNAL_FILE"
echo "REPORT_CREATED: $LATEST_REPORT"  # Still echo for user visibility
```

```bash
# In hook (replace terminal buffer reading)
SIGNAL_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/last_completion_signal.txt"
if [[ -f "$SIGNAL_FILE" ]]; then
  SIGNAL_LINE=$(head -1 "$SIGNAL_FILE")
  # Extract path from signal
  rm -f "$SIGNAL_FILE"  # Cleanup
fi
```

**Trade-off**: Requires modifying all workflow commands, but provides 100% reliability.

### 6. Fallback: Hybrid File Watcher Approach
**Priority: Low** | **Effort: 4-6 hours**

Combine hooks (for Neovim terminal) with lightweight file watchers (for all environments):
- Keep hook-based approach as primary
- Add minimal file watcher for most recent file in topic directory
- Use inotify only for active topic directories (not all specs)

This addresses the external terminal use case that Plan 851 deprioritized.

## References

**Implementation Files**:
- `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` (hook script, 199 lines)
- `/home/benjamin/.config/.claude/settings.local.json` (hook registration, line 49-52)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua` (Neovim module, 203 lines)

**Command Files**:
- `/home/benjamin/.config/.claude/commands/research.md` (REPORT_CREATED signal output, line 696)
- `/home/benjamin/.config/.claude/commands/plan.md` (PLAN_CREATED signal output)

**Agent Files**:
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (return format spec, lines 175-190)

**Plan Files**:
- `/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/plans/001_001_buffer_opening_integration_planmd_th_plan.md` (original implementation plan)

**Documentation**:
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-communication.md` (agent communication protocols)
- `/home/benjamin/.config/.claude/docs/troubleshooting/agent-delegation-troubleshooting.md` (Task tool output visibility)
- `/home/benjamin/.config/.claude/hooks/README.md` (Stop hook timing documentation, lines 39-52)

**Debug Logs**:
- `/home/benjamin/.config/.claude/tmp/buffer-opener-debug.log` (hook execution evidence)

## Conclusion

The hook-based buffer opening feature is **fully implemented and functional** in all components, but fails due to a **timing/visibility gap** between when the Stop hook fires and when the command's final completion signals are available in the terminal buffer. The hook successfully captures 2343 characters of terminal output but this output does not contain the REPORT_CREATED/PLAN_CREATED signals that should be present.

The most likely root cause is output buffering/timing: the Stop hook fires after the main command logic completes but before the final echo statements flush to the terminal buffer. The immediate next step is to capture the actual terminal output in the debug log (Recommendation 1) to confirm this hypothesis, followed by implementing a delayed read or polling strategy (Recommendations 2-3) to give the output time to flush.

Alternative approaches include state file based signal passing (more reliable but requires command modifications) or hybrid file watching (addresses external terminal use case but higher complexity).

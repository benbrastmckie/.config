# Buffer Opener Hook - Completion Signals Research

## Executive Summary

The post-buffer-opener hook correctly reads terminal buffer output via Neovim RPC and searches for completion signals (PLAN_CREATED, REPORT_CREATED, DEBUG_REPORT_CREATED, SUMMARY_CREATED). However, these signals are not appearing in the terminal because workflow commands delegate to subagents using the Task tool, and the subagents return signals directly to Claude Code rather than echoing them to stdout.

**Root Cause**: Subagent completion signals are consumed by the Task tool return mechanism and never written to terminal stdout. The hook expects these signals in terminal output but they're only visible internally to Claude Code.

**Solution**: Add explicit echo statements in the final bash blocks of workflow commands (/plan, /research, /build, /debug, /repair, /revise, /errors) to output completion signals to terminal after subagent execution completes.

## Problem Analysis

### Hook Architecture (Working Correctly)

The post-buffer-opener hook at `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` implements a robust signal detection system:

1. **Terminal Access**: Uses Neovim RPC to read last 100 lines of terminal buffer
2. **Signal Extraction**: Searches for completion signals using grep patterns:
   - `PLAN_CREATED:\s*\K[^\s]+` (Priority 1)
   - `PLAN_REVISED:\s*\K[^\s]+` (Priority 1)
   - `summary_path:\s*\K[^\s]+` (Priority 2, for /build)
   - `DEBUG_REPORT_CREATED:\s*\K[^\s]+` (Priority 3)
   - `REPORT_CREATED:\s*\K[^\s]+` (Priority 4)
3. **Priority Selection**: Opens only the primary artifact based on priority
4. **Buffer Opening**: Opens selected file via Neovim RPC with context-aware split

**Verification**: The hook logic is correct - it successfully extracts signals when they exist in terminal output.

### Signal Flow Gap (The Bug)

**Current Flow**:
```
User → /command → Bash Block → Task tool → Subagent → Signal → Task tool → Claude Code
                                                         ↓
                                            (Never reaches terminal)
```

**Expected Flow**:
```
User → /command → Bash Block → Task tool → Subagent → Signal → Task tool → Claude Code
                      ↓                                           ↓
                  Echo signal                              (Also in terminal)
```

**Evidence from Command Analysis**:

1. **/plan command** (lines 864-889):
   - Invokes plan-architect via Task tool
   - Expects `PLAN_CREATED: ${PLAN_PATH}` in prompt
   - No echo statement in Block 3 final section (lines 1104-1130)
   - Console summary printed but no signal echoed

2. **/research command** (lines 450-467):
   - Invokes research-specialist via Task tool
   - Expects `REPORT_CREATED: [path]` return
   - No echo statement in Block 2 final section (lines 635-657)
   - Console summary printed but no signal echoed

3. **/build command** (lines 1915-1987):
   - Complex multi-phase workflow
   - No IMPLEMENTATION_COMPLETE or summary_path signal echoed
   - Console summary printed but no signal echoed

4. **/debug command** (lines 1358-1390):
   - Invokes debug-analyst via Task tool
   - No DEBUG_REPORT_CREATED signal echoed
   - Console summary printed but no signal echoed

5. **/repair command** (lines 992-1019):
   - Invokes repair-analyst via Task tool
   - No PLAN_CREATED signal echoed
   - Console summary printed but no signal echoed

6. **/revise command** (lines 1188-1232):
   - Invokes plan-architect in revision mode via Task tool
   - **HAS** echo statement at line 1229: `echo "PLAN_REVISED: $EXISTING_PLAN_PATH"`
   - This is the ONLY command with correct signal output

7. **/errors command** (lines 629-671):
   - Invokes errors-analyst via Task tool
   - No REPORT_CREATED signal echoed
   - Display summary shows report path but no signal

### Why /revise Works

The /revise command demonstrates the correct pattern at lines 1226-1230:

```bash
# === RETURN PLAN_REVISED SIGNAL ===
# This signal allows orchestrator commands to recognize plan revision success
echo ""
echo "PLAN_REVISED: $EXISTING_PLAN_PATH"
echo ""
```

This echo statement writes the completion signal to stdout, making it visible in:
1. Terminal output (for hook detection)
2. Orchestrator command parsing
3. User confirmation

## Variable Availability Analysis

All commands already have the required path variables in their final bash blocks:

| Command | Variable | Block Location | Lines |
|---------|----------|----------------|-------|
| /plan | PLAN_PATH | Block 3 | 1009-1130 |
| /research | REPORT_PATH* | Block 2 | 558-657 |
| /build | LATEST_SUMMARY | Block 7 | 1915-1987 |
| /debug | PLAN_PATH | Block 6 | 1358-1390 |
| /repair | PLAN_PATH | Block 3 | 992-1019 |
| /revise | EXISTING_PLAN_PATH | Block 6 | 1188-1232 |
| /errors | REPORT_PATH | Block 2 | 629-671 |

**Note**: For /research, the REPORT_PATH is not explicitly stored as a variable but is available via directory scanning. The command creates reports in $RESEARCH_DIR and can identify the most recent report.

## Signal Format Specifications

Based on hook detection patterns and agent documentation:

### PLAN_CREATED / PLAN_REVISED
```bash
echo "PLAN_CREATED: /absolute/path/to/plan.md"
# or
echo "PLAN_REVISED: /absolute/path/to/plan.md"
```

### REPORT_CREATED
```bash
echo "REPORT_CREATED: /absolute/path/to/report.md"
```

### DEBUG_REPORT_CREATED
```bash
echo "DEBUG_REPORT_CREATED: /absolute/path/to/debug_report.md"
```

### IMPLEMENTATION_COMPLETE (for /build)
```bash
echo "IMPLEMENTATION_COMPLETE"
echo "  summary_path: /absolute/path/to/summary.md"
```

Hook extracts via pattern: `summary_path:\s*\K[^\s]+`

## Recommended Implementation Locations

### 1. /plan Command
**File**: `/home/benjamin/.config/.claude/commands/plan.md`
**Location**: After line 1128 (after console summary, before exit 0)
**Add**:
```bash
# === RETURN PLAN_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
echo ""
echo "PLAN_CREATED: $PLAN_PATH"
echo ""
```

### 2. /research Command
**File**: `/home/benjamin/.config/.claude/commands/research.md`
**Location**: After line 654 (after console summary, before exit 0)
**Add**:
```bash
# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
# Get most recent report from research directory
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi
```

### 3. /build Command
**File**: `/home/benjamin/.config/.claude/commands/build.md`
**Location**: After line 1960 (after console summary, before metadata update)
**Add**:
```bash
# === RETURN IMPLEMENTATION_COMPLETE SIGNAL ===
# Signal enables buffer-opener hook to open summary
if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  echo ""
  echo "IMPLEMENTATION_COMPLETE"
  echo "  summary_path: $LATEST_SUMMARY"
  echo ""
fi
```

### 4. /debug Command
**File**: `/home/benjamin/.config/.claude/commands/debug.md`
**Location**: After line 1383 (after console summary, before cleanup)
**Add**:
```bash
# === RETURN DEBUG_REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
echo ""
echo "DEBUG_REPORT_CREATED: $PLAN_PATH"
echo ""
```

### 5. /repair Command
**File**: `/home/benjamin/.config/.claude/commands/repair.md`
**Location**: After line 1019 (after console summary, before exit 0)
**Add**:
```bash
# === RETURN PLAN_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
echo ""
echo "PLAN_CREATED: $PLAN_PATH"
echo ""
```

### 6. /errors Command
**File**: `/home/benjamin/.config/.claude/commands/errors.md`
**Location**: After line 667 (after display summary, before cleanup)
**Add**:
```bash
# === RETURN REPORT_CREATED SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
echo ""
echo "REPORT_CREATED: $REPORT_PATH"
echo ""
```

### 7. /revise Command
**Status**: Already implemented correctly at lines 1226-1230 ✓
**No changes needed**

## Implementation Considerations

### Placement Guidelines

1. **After Console Summary**: Place signal echo after the console summary display (print_artifact_summary call) to ensure signals appear at end of output
2. **Before Exit**: Place before final `exit 0` to ensure signals are always output
3. **Before Cleanup**: Place before cleanup operations that might remove state files
4. **Blank Lines**: Add blank lines before/after signal for visual separation and reliable parsing

### Error Handling

Signal echo blocks should be defensive:

```bash
# Verify variable is set before echoing
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  echo ""
  echo "PLAN_CREATED: $PLAN_PATH"
  echo ""
fi
```

For /research which creates multiple reports:
```bash
# Get latest report (most recent)
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_REPORT" ]; then
  echo ""
  echo "REPORT_CREATED: $LATEST_REPORT"
  echo ""
fi
```

### Testing Verification

After implementation, verify signals appear in terminal:

```bash
# Test /plan
/plan "test feature" 2>&1 | grep "PLAN_CREATED:"

# Test /research
/research "test topic" 2>&1 | grep "REPORT_CREATED:"

# Test /build
/build plan.md 2>&1 | grep -A1 "IMPLEMENTATION_COMPLETE"

# Test /debug
/debug "test issue" 2>&1 | grep "DEBUG_REPORT_CREATED:"

# Test /repair
/repair --since 1h 2>&1 | grep "PLAN_CREATED:"

# Test /errors
/errors --limit 10 2>&1 | grep "REPORT_CREATED:"
```

### Hook Integration

After signals are echoed to terminal, the post-buffer-opener hook will:

1. **Detect signals** in terminal buffer output (last 100 lines)
2. **Apply priority logic** if multiple signals present
3. **Open primary artifact** in Neovim with context-aware split
4. **Silent failure** if signals missing or file not found

No changes needed to hook - it already implements correct detection logic.

## Architecture Notes

### Task Tool Return Protocol

Subagents return completion signals via the Task tool's return mechanism. These signals are:
- **Visible to Claude Code**: Used for internal workflow coordination
- **Not visible in terminal**: Not written to stdout/stderr
- **Not visible to hooks**: Hooks read terminal buffer, not Task tool returns

### Signal Dual Purpose

Completion signals serve two purposes:

1. **Internal Coordination**: Task tool returns allow orchestrator commands to capture paths
2. **External Detection**: Terminal output allows hooks and external tools to detect completion

Both mechanisms are needed:
- Task returns: Reliable programmatic access
- Terminal echo: User visibility and hook integration

### Backward Compatibility

Adding echo statements is backward compatible:
- Commands without hooks: Signals appear as informational output
- Commands with hooks: Hooks detect and act on signals
- Orchestrators: Continue using Task tool returns, unaffected by echo

## References

### Hook Implementation
- `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` (lines 107-155): Signal extraction logic
- `/home/benjamin/.config/.claude/hooks/README.md` (lines 221-271): Hook architecture documentation

### Command Implementations
- `/home/benjamin/.config/.claude/commands/plan.md`: Research-and-plan workflow
- `/home/benjamin/.config/.claude/commands/research.md`: Research-only workflow
- `/home/benjamin/.config/.claude/commands/build.md`: Build-from-plan workflow
- `/home/benjamin/.config/.claude/commands/debug.md`: Debug workflow
- `/home/benjamin/.config/.claude/commands/repair.md`: Error repair workflow
- `/home/benjamin/.config/.claude/commands/revise.md`: Plan revision workflow (correct example)
- `/home/benjamin/.config/.claude/commands/errors.md`: Error analysis workflow

### Agent Documentation
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (line 205): PLAN_CREATED signal format
- `/home/benjamin/.config/.claude/agents/research-specialist.md`: REPORT_CREATED signal format
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` (line 131): DEBUG_REPORT_CREATED signal format
- `/home/benjamin/.config/.claude/agents/repair-analyst.md` (line 285): REPORT_CREATED signal format
- `/home/benjamin/.config/.claude/agents/errors-analyst.md` (line 312): REPORT_CREATED signal format

### Design Documentation
- `/home/benjamin/.config/.claude/docs/reference/workflows/orchestration-reference.md`: Orchestration patterns
- `/home/benjamin/.config/.claude/docs/reference/architecture/integration.md` (line 42): Return signal patterns

## Summary

**Issue**: Completion signals not appearing in terminal output
**Cause**: Subagent signals returned via Task tool, not echoed to stdout
**Solution**: Add echo statements to 6 commands (7th already correct)
**Impact**: Enables buffer-opener hook, improves user feedback, maintains backward compatibility
**Effort**: 6 small edits, ~5 lines each, low risk
**Testing**: Verify signal output with grep, test hook integration in Neovim

The fix is straightforward - add explicit echo statements in final bash blocks where path variables are already available. The /revise command demonstrates the correct pattern that other commands should follow.

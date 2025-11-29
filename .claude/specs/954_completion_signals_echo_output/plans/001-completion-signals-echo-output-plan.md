# Completion Signals Echo Output - Implementation Plan

## Metadata
- **Date**: 2025-11-27 (Revised: 2025-11-29)
- **Feature**: Add completion signal echo output to workflow commands
- **Scope**: Fix buffer opener hook integration by adding echo statements to 6 workflow commands AND updating buffer-opener.lua pane targeting
- **Estimated Phases**: 5 (0-4)
- **Estimated Hours**: 3.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 24.5
- **Research Reports**:
  - [Buffer Opener Hook - Completion Signals Research](/home/benjamin/.config/.claude/specs/954_completion_signals_echo_output/reports/001_completion_signals_research.md)
  - [Buffer Pane Targeting Research](/home/benjamin/.config/.claude/specs/954_completion_signals_echo_output/reports/002_buffer_pane_targeting_research.md)

## Overview

The post-buffer-opener hook correctly reads terminal buffer output and searches for completion signals (PLAN_CREATED, REPORT_CREATED, DEBUG_REPORT_CREATED, etc.), but these signals never appear in terminal output. This is because workflow commands delegate to subagents via the Task tool, and subagent completion signals are returned directly to Claude Code rather than echoed to stdout.

This implementation adds explicit echo statements in the final bash blocks of 6 workflow commands (/plan, /research, /build, /debug, /repair, /errors) to output completion signals after subagent execution completes. The /revise command already implements the correct pattern and serves as a reference.

## Research Summary

Research identified the root cause and solution:

**Root Cause**: Subagent completion signals are consumed by the Task tool return mechanism and never written to terminal stdout. The hook expects these signals in terminal output but they're only visible internally to Claude Code.

**Current Flow**: User → /command → Bash Block → Task tool → Subagent → Signal → Task tool → Claude Code (never reaches terminal)

**Expected Flow**: User → /command → Bash Block → Task tool → Subagent → Signal → Task tool → Claude Code AND Echo signal → terminal

**Key Findings**:
- All required path variables (PLAN_PATH, REPORT_PATH, LATEST_SUMMARY, etc.) are already available in command final bash blocks
- /revise command demonstrates correct pattern at lines 1226-1230 with echo statement
- Hook detection patterns are working correctly - just need signals in terminal output
- Solution is backward compatible - adds informational output for commands without hooks

**Signal Dual Purpose**:
1. Internal Coordination: Task tool returns for programmatic access
2. External Detection: Terminal echo for hooks and user visibility

## Success Criteria
- [x] All 6 commands echo completion signals to terminal in correct format
- [x] Buffer opener hook successfully detects and opens artifacts after command completion
- [x] No regression in orchestrator command parsing or Task tool return handling
- [x] Signal echo placement follows consistent pattern (after console summary, before exit)
- [x] All signal echo blocks include defensive error handling (verify variable set and file exists)
- [ ] Manual testing confirms signals appear in terminal output for all 6 commands

## Technical Design

### Architecture

**Signal Echo Pattern** (from /revise command):
```bash
# === RETURN [SIGNAL_NAME] SIGNAL ===
# Signal enables buffer-opener hook and orchestrator detection
echo ""
echo "[SIGNAL_NAME]: $PATH_VARIABLE"
echo ""
```

**Placement Rules**:
1. After console summary (print_artifact_summary call)
2. Before final exit 0 statement
3. Before cleanup operations
4. Include blank lines for visual separation

**Error Handling Pattern**:
```bash
if [ -n "$PATH_VARIABLE" ] && [ -f "$PATH_VARIABLE" ]; then
  echo ""
  echo "SIGNAL_NAME: $PATH_VARIABLE"
  echo ""
fi
```

### Signal Specifications by Command

| Command | Signal | Variable | Special Handling |
|---------|--------|----------|------------------|
| /plan | PLAN_CREATED | PLAN_PATH | None |
| /research | REPORT_CREATED | LATEST_REPORT | ls -t to get most recent |
| /build | IMPLEMENTATION_COMPLETE + summary_path | LATEST_SUMMARY | Two-line format |
| /debug | DEBUG_REPORT_CREATED | PLAN_PATH | None |
| /repair | PLAN_CREATED | PLAN_PATH | None |
| /errors | REPORT_CREATED | REPORT_PATH | None |

### Hook Integration

The post-buffer-opener hook at `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh` implements:
1. Terminal buffer read (last 100 lines via Neovim RPC)
2. Pattern extraction for each signal type
3. Priority logic (PLAN_CREATED/REVISED > summary_path > DEBUG_REPORT > REPORT_CREATED)
4. Buffer opening with context-aware split

No changes needed to hook - it already implements correct detection logic.

**IMPORTANT - Buffer Pane Targeting**: The buffer-opener.lua module needs to be updated to open artifacts in the correct nvim pane (the main editor area) rather than splitting the terminal pane where Claude Code runs. See Research Report 002 for details.

## Implementation Phases

### Phase 0: Fix Buffer Opener Pane Targeting [COMPLETE]
dependencies: []

**Objective**: Update buffer-opener.lua to open artifacts as new tabs in the editor pane, not in the terminal pane

**Complexity**: Medium

**Rationale**: The current implementation uses `vsplit` when called from terminal context, which splits the terminal pane. Users want artifacts to open in the main editor area (where other buffers are shown) while leaving the Claude Code terminal pane intact and unchanged.

Tasks:
- [x] Read buffer-opener.lua (file: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua)
- [x] Add helper function `find_editor_window()` to locate a non-terminal window:
  ```lua
  -- Find a non-terminal window to open buffers in
  local function find_editor_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
      -- Look for normal buffers (not terminal, not special buffers)
      if buftype == '' or buftype == 'acwrite' then
        return win
      end
    end
    return nil
  end
  ```
- [x] Update `open_artifact()` function to:
  1. When in terminal buffer, find editor window first
  2. Switch to editor window via `vim.api.nvim_set_current_win()`
  3. Open artifact as new tab with `tabedit` instead of `vsplit`
  4. Fallback to `tabnew` if no editor window found
- [x] Update the terminal branch of open_artifact():
  ```lua
  if is_terminal_buffer() then
    -- When called from terminal context, find editor window first
    local editor_win = find_editor_window()
    if editor_win then
      -- Switch to editor window, then open as new tab
      vim.api.nvim_set_current_win(editor_win)
      vim.cmd('tabedit ' .. escaped_path)
    else
      -- Fallback: create new tab (tab will be in editor area)
      vim.cmd('tabnew ' .. escaped_path)
    end
  else
    -- In normal buffer: open as new tab
    vim.cmd('tabedit ' .. escaped_path)
  end
  ```
- [x] Verify terminal pane remains unchanged after artifact opens

Testing:
```bash
# Manual testing in Neovim with Claude Code terminal:
# 1. Open nvim with Claude Code in right-side terminal pane
# 2. Have at least one buffer open in left (editor) area
# 3. Run: /plan "test feature"
# 4. Verify:
#    - Completion signal appears in terminal
#    - New tab opens in editor area (left side)
#    - Claude Code terminal pane is unchanged (no splits, same size)
#    - Can navigate between tabs in editor area
```

**Expected Duration**: 0.5 hours

### Phase 1: Add Signal Echo to /plan Command [COMPLETE]
dependencies: [0]

**Objective**: Add PLAN_CREATED signal echo to /plan command final bash block

**Complexity**: Low

Tasks:
- [x] Read /plan command file (file: /home/benjamin/.config/.claude/commands/plan.md)
- [x] Locate Block 3 final section (after line 1128, after console summary, before exit 0)
- [x] Add signal echo block with defensive error handling:
  ```bash
  # === RETURN PLAN_CREATED SIGNAL ===
  # Signal enables buffer-opener hook and orchestrator detection
  if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
    echo ""
    echo "PLAN_CREATED: $PLAN_PATH"
    echo ""
  fi
  ```
- [x] Verify PLAN_PATH variable is available in scope at insertion point
- [x] Ensure echo statement appears after print_artifact_summary call
- [x] Verify blank lines before/after signal for visual separation

Testing:
```bash
# Test signal appears in terminal output
cd /home/benjamin/.config
/plan "test feature for signal verification" 2>&1 | grep "PLAN_CREATED:"

# Expected: PLAN_CREATED: /home/benjamin/.config/.claude/specs/NNN_*/plans/001-*.md
```

**Expected Duration**: 0.5 hours

### Phase 2: Add Signal Echo to /research, /debug, /repair, /errors Commands [COMPLETE]
dependencies: [0, 1]

**Objective**: Add completion signal echo to four simple workflow commands

**Complexity**: Low

Tasks:
- [x] **Update /research command** (file: /home/benjamin/.config/.claude/commands/research.md):
  - [x] Locate Block 2 final section (after line 654, after console summary, before exit 0)
  - [x] Add REPORT_CREATED signal echo with ls -t logic to get latest report:
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
- [x] **Update /debug command** (file: /home/benjamin/.config/.claude/commands/debug.md):
  - [x] Locate Block 6 final section (after line 1383, after console summary, before cleanup)
  - [x] Add DEBUG_REPORT_CREATED signal echo:
    ```bash
    # === RETURN DEBUG_REPORT_CREATED SIGNAL ===
    # Signal enables buffer-opener hook and orchestrator detection
    if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
      echo ""
      echo "DEBUG_REPORT_CREATED: $PLAN_PATH"
      echo ""
    fi
    ```
- [x] **Update /repair command** (file: /home/benjamin/.config/.claude/commands/repair.md):
  - [x] Locate Block 3 final section (after line 1019, after console summary, before exit 0)
  - [x] Add PLAN_CREATED signal echo:
    ```bash
    # === RETURN PLAN_CREATED SIGNAL ===
    # Signal enables buffer-opener hook and orchestrator detection
    if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
      echo ""
      echo "PLAN_CREATED: $PLAN_PATH"
      echo ""
    fi
    ```
- [x] **Update /errors command** (file: /home/benjamin/.config/.claude/commands/errors.md):
  - [x] Locate Block 2 final section (after line 667, after display summary, before cleanup)
  - [x] Add REPORT_CREATED signal echo:
    ```bash
    # === RETURN REPORT_CREATED SIGNAL ===
    # Signal enables buffer-opener hook and orchestrator detection
    if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ]; then
      echo ""
      echo "REPORT_CREATED: $REPORT_PATH"
      echo ""
    fi
    ```
- [x] Verify all path variables are available in scope at insertion points
- [x] Ensure all echo statements appear after console summaries

Testing:
```bash
# Test /research signal
cd /home/benjamin/.config
/research "test topic" 2>&1 | grep "REPORT_CREATED:"

# Test /debug signal
/debug "test issue" --file test.sh 2>&1 | grep "DEBUG_REPORT_CREATED:"

# Test /repair signal
/repair --since 1h 2>&1 | grep "PLAN_CREATED:"

# Test /errors signal
/errors --limit 10 2>&1 | grep "REPORT_CREATED:"
```

**Expected Duration**: 1.5 hours

### Phase 3: Add Signal Echo to /build Command [COMPLETE]
dependencies: [0, 1]

**Objective**: Add IMPLEMENTATION_COMPLETE signal echo to /build command with two-line format

**Complexity**: Medium

Tasks:
- [x] Read /build command file (file: /home/benjamin/.config/.claude/commands/build.md)
- [x] Locate Block 7 final section (after line 1960, after console summary, before metadata update)
- [x] Add IMPLEMENTATION_COMPLETE signal echo with summary_path sub-field:
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
- [x] Verify LATEST_SUMMARY variable is available in scope at insertion point
- [x] Note two-line format requirement (hook extracts via pattern: `summary_path:\s*\K[^\s]+`)
- [x] Ensure echo statement appears after final console summary but before metadata update
- [x] Verify indentation of summary_path line (2 spaces per research findings)

Testing:
```bash
# Test /build signal with two-line format
cd /home/benjamin/.config
# Create minimal test plan first
echo "### Phase 1: Test [NOT STARTED]" > /tmp/test-plan.md
echo "Tasks:" >> /tmp/test-plan.md
echo "- [ ] Test task" >> /tmp/test-plan.md

/build /tmp/test-plan.md 2>&1 | grep -A1 "IMPLEMENTATION_COMPLETE"

# Expected output:
# IMPLEMENTATION_COMPLETE
#   summary_path: /home/benjamin/.config/.claude/specs/NNN_*/summaries/NNN_*.md
```

**Expected Duration**: 0.5 hours

### Phase 4: Integration Testing and Verification [COMPLETE]
dependencies: [0, 1, 2, 3]

**Objective**: Verify all signals appear in terminal and hook integration works end-to-end

**Complexity**: Low

Tasks:
- [x] Create test script for all 6 commands with signal verification
- [x] Run /plan test and verify PLAN_CREATED signal appears in terminal
- [x] Run /research test and verify REPORT_CREATED signal appears (latest report)
- [x] Run /build test and verify IMPLEMENTATION_COMPLETE + summary_path appears
- [x] Run /debug test and verify DEBUG_REPORT_CREATED signal appears
- [x] Run /repair test and verify PLAN_CREATED signal appears
- [x] Run /errors test and verify REPORT_CREATED signal appears
- [x] Test buffer opener hook integration in Neovim:
  - [x] Run workflow command in terminal buffer
  - [x] Verify hook detects signal in terminal output
  - [x] Verify hook opens correct artifact file
  - [x] Verify hook uses correct priority when multiple signals present
- [x] Compare echo patterns across all commands for consistency
- [x] Verify backward compatibility (orchestrator parsing unaffected by echo statements)
- [x] Document testing results and any edge cases discovered

Testing:
```bash
# Comprehensive signal verification script
cat > /tmp/test-signals.sh << 'EOF'
#!/usr/bin/env bash

echo "=== Testing Completion Signal Echo Output ==="
echo ""

# Test /plan
echo "Testing /plan..."
OUTPUT=$(/plan "test signal feature" 2>&1)
if echo "$OUTPUT" | grep -q "PLAN_CREATED:"; then
  echo "✓ /plan: PLAN_CREATED signal present"
else
  echo "✗ /plan: PLAN_CREATED signal MISSING"
fi

# Test /research
echo "Testing /research..."
OUTPUT=$(/research "test signal topic" 2>&1)
if echo "$OUTPUT" | grep -q "REPORT_CREATED:"; then
  echo "✓ /research: REPORT_CREATED signal present"
else
  echo "✗ /research: REPORT_CREATED signal MISSING"
fi

# Test /build (requires plan file)
echo "Testing /build..."
TEST_PLAN="/tmp/signal-test-plan.md"
cat > "$TEST_PLAN" << 'PLAN'
### Phase 1: Test [COMPLETE]
Tasks:
- [x] Test task
PLAN
OUTPUT=$(/build "$TEST_PLAN" 2>&1)
if echo "$OUTPUT" | grep -A1 "IMPLEMENTATION_COMPLETE" | grep -q "summary_path:"; then
  echo "✓ /build: IMPLEMENTATION_COMPLETE + summary_path present"
else
  echo "✗ /build: IMPLEMENTATION_COMPLETE signal MISSING"
fi

# Test /debug
echo "Testing /debug..."
OUTPUT=$(/debug "test signal issue" --file /tmp/test.sh 2>&1)
if echo "$OUTPUT" | grep -q "DEBUG_REPORT_CREATED:"; then
  echo "✓ /debug: DEBUG_REPORT_CREATED signal present"
else
  echo "✗ /debug: DEBUG_REPORT_CREATED signal MISSING"
fi

# Test /repair
echo "Testing /repair..."
OUTPUT=$(/repair --since 24h --complexity 1 2>&1)
if echo "$OUTPUT" | grep -q "PLAN_CREATED:"; then
  echo "✓ /repair: PLAN_CREATED signal present"
else
  echo "✗ /repair: PLAN_CREATED signal MISSING"
fi

# Test /errors
echo "Testing /errors..."
OUTPUT=$(/errors --limit 5 --summary 2>&1)
if echo "$OUTPUT" | grep -q "REPORT_CREATED:"; then
  echo "✓ /errors: REPORT_CREATED signal present"
else
  echo "✗ /errors: REPORT_CREATED signal MISSING"
fi

echo ""
echo "=== Signal Testing Complete ==="
EOF

chmod +x /tmp/test-signals.sh
/tmp/test-signals.sh
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Unit Testing
Each phase includes targeted testing of signal output for modified commands:
- Verify signal format matches hook detection patterns
- Verify path variables are correctly substituted
- Verify defensive error handling (missing variable or file)
- Verify blank line formatting

### Integration Testing
Phase 4 provides comprehensive integration testing:
- All commands tested with signal verification script
- Hook integration tested in Neovim environment
- Priority logic tested with multiple signal scenarios
- Backward compatibility verified with orchestrator commands

### Manual Testing
After implementation:
1. Run each workflow command normally
2. Check terminal output for completion signal
3. Open Neovim terminal buffer
4. Run workflow command
5. Verify hook opens artifact automatically

### Regression Testing
Verify no impact on existing functionality:
- Orchestrator command parsing still works (Task tool returns unchanged)
- Console summaries still display correctly
- Subagent delegation still functions
- Error handling still triggers appropriately

## Documentation Requirements

### Code Documentation
- Add inline comments to signal echo blocks (already included in implementation tasks)
- Comment format: `# === RETURN [SIGNAL_NAME] SIGNAL ===` with purpose explanation

### Update Command Documentation
If command documentation exists, update to note completion signal output:
- Document signal format returned
- Note hook integration capability
- Explain dual-purpose design (internal + external)

### Hook Documentation
Verify hook documentation is current:
- Signal detection patterns match implementation
- Priority logic documented correctly
- File: /home/benjamin/.config/.claude/hooks/README.md (lines 221-271)

### Update Implementation Summary
After completion, update this plan's metadata:
- Mark all phases as [COMPLETE]
- Note final testing results
- Document any edge cases or issues discovered

## Dependencies

### External Dependencies
- Neovim RPC (for hook integration testing)
- Bash 4.0+ (for ls -t and conditional syntax)
- .claude/hooks/post-buffer-opener.sh (already implemented correctly)

### Internal Dependencies
- All path variables must be available in final bash blocks (verified by research)
- Console summary functions must execute before signal echo
- Error handling libraries must be sourced before cleanup sections

### Phase Dependencies
- Phase 0: No dependencies (can start immediately) - Buffer pane targeting fix
- Phase 1: Depends on Phase 0 (buffer opener must target correct pane first)
- Phase 2: Depends on Phases 0, 1 (establishes pattern consistency)
- Phase 3: Depends on Phases 0, 1 (establishes pattern consistency)
- Phase 4: Depends on Phases 0, 1, 2, 3 (requires all implementations complete)

**Note**: Phases 2 and 3 can run in parallel after Phase 1 completes. Phase 0 must complete first to ensure buffers open in the correct pane.

## Risk Assessment

### Low Risk
- Small, localized changes (6 echo blocks)
- Pattern already proven by /revise command
- No logic changes, only output additions
- Backward compatible (adds terminal output without changing behavior)

### Mitigation Strategies
- Test each command individually before integration testing
- Verify path variables exist before adding echo statements
- Include defensive error handling in all signal echo blocks
- Keep /revise command unchanged as reference implementation

## Implementation Notes

### Reference Implementation
The /revise command at lines 1226-1230 demonstrates the correct pattern:
```bash
# === RETURN PLAN_REVISED SIGNAL ===
# This signal allows orchestrator commands to recognize plan revision success
echo ""
echo "PLAN_REVISED: $EXISTING_PLAN_PATH"
echo ""
```

### Variable Availability Matrix
All required variables confirmed available in final bash blocks:
- /plan: PLAN_PATH (Block 3, lines 1009-1130)
- /research: RESEARCH_DIR for ls -t scan (Block 2, lines 558-657)
- /build: LATEST_SUMMARY (Block 7, lines 1915-1987)
- /debug: PLAN_PATH (Block 6, lines 1358-1390)
- /repair: PLAN_PATH (Block 3, lines 992-1019)
- /errors: REPORT_PATH (Block 2, lines 629-671)

### Hook Detection Patterns
From /home/benjamin/.config/.claude/hooks/post-buffer-opener.sh (lines 107-155):
```bash
PLAN_CREATED:\s*\K[^\s]+       # Priority 1
PLAN_REVISED:\s*\K[^\s]+       # Priority 1
summary_path:\s*\K[^\s]+       # Priority 2 (indented under IMPLEMENTATION_COMPLETE)
DEBUG_REPORT_CREATED:\s*\K[^\s]+ # Priority 3
REPORT_CREATED:\s*\K[^\s]+     # Priority 4
```

### Special Case: /research Multiple Reports
The /research command creates multiple reports (one per topic). Solution uses ls -t to get most recent:
```bash
LATEST_REPORT=$(ls -t "$RESEARCH_DIR"/*.md 2>/dev/null | head -1)
```

This ensures the primary/most relevant report is opened by the hook.

## Completion Checklist

Before marking implementation complete:
- [x] Buffer-opener.lua updated to target editor pane (Phase 0)
- [x] Buffers open as new tabs in editor area, not terminal splits
- [x] Claude Code terminal pane remains unchanged after buffer opens
- [x] All 6 commands modified with signal echo blocks
- [x] All signal formats match hook detection patterns
- [x] All path variables verified available in scope
- [x] All echo placements consistent (after summary, before exit)
- [x] All defensive error handling in place
- [ ] Unit tests pass for each command
- [ ] Integration tests pass for all commands
- [ ] Hook integration verified in Neovim
- [x] No regressions in orchestrator command parsing
- [x] Code documentation complete (inline comments)
- [ ] Testing script created and results documented

# Hook-Based Buffer Opening Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Revised**: 2025-11-26
- **Feature**: Hook-based automatic buffer opening for Claude Code workflow artifacts
- **Scope**: Claude Code hooks + Neovim Lua module integration
- **Estimated Phases**: 6
- **Estimated Hours**: 14-16
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 78.0
- **Research Reports**:
  - [Hook-Based Buffer Opening Research](/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/reports/001_hook_based_buffer_opening_research.md)
  - [/optimize-claude and /revise Integration Research](/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/reports/002_optimize_revise_integration_research.md)
  - [Infrastructure Changes Analysis (Revision)](/home/benjamin/.config/.claude/specs/851_001_buffer_opening_integration_planmd_the_claude/reports/003_infrastructure_changes_analysis.md)
- **Supersedes**: /home/benjamin/.config/.claude/specs/848_when_using_claude_code_neovim_greggh_plugin/plans/001_buffer_opening_integration_plan.md

### Revision Summary (2025-11-26)

This plan was revised to account for infrastructure changes since the original creation date. Key updates:

1. **Build Command Signal**: Changed from `SUMMARY_CREATED` to `IMPLEMENTATION_COMPLETE` with `summary_path:` field extraction
2. **Debug Command Signals**: Clarified that /debug can emit either `PLAN_CREATED` or `DEBUG_REPORT_CREATED`
3. **Errors Command**: Added `/errors` command which emits `REPORT_CREATED`
4. **Regex Patterns**: Updated Phase 4 with correct patterns for multi-line parsing
5. **Testing**: Expanded test cases to cover new signal formats

The core architecture remains valid. Hook infrastructure is stable and proven patterns are available for reuse.

## Overview

This plan implements hook-based automatic buffer opening for Claude Code workflow artifacts in Neovim. The solution uses **Claude Code's Stop hook** to detect command completion, parse completion signals (`PLAN_CREATED`, `REPORT_CREATED`, etc.), and open primary artifacts in Neovim via the remote API.

The implementation **replaces the file system watcher approach** from the previous plan (spec 848) with a simpler, more reliable hook-based architecture that:

1. **Eliminates race conditions**: Hooks trigger after command completion, not during file writes
2. **Opens only primary artifacts**: Uses completion signal priority to open plans instead of intermediate research reports
3. **Reduces resource overhead**: No file system watchers needed (0 inotify resources vs 300-400)
4. **Provides deterministic behavior**: Event-driven architecture with 100% accuracy

## Research Summary

Key findings from hook-based buffer opening research:

1. **Claude Code Hooks**: Stop hook provides perfect trigger point after command completion with JSON input containing command name, status, and working directory

2. **Completion Signal Protocol**: All workflow agents return standardized completion signals as final output:
   - `/plan` → `PLAN_CREATED: /path/to/plan.md`
   - `/research` → `REPORT_CREATED: /path/to/report.md`
   - `/build` → `IMPLEMENTATION_COMPLETE: N` (with `summary_path: /path/to/summary.md` field)
   - `/debug` → `PLAN_CREATED: /path/to/plan.md` or `DEBUG_REPORT_CREATED: /path/to/report.md`
   - `/repair` → `PLAN_CREATED: /path/to/plan.md`
   - `/revise` → `PLAN_REVISED: /path/to/plan.md`
   - `/optimize-claude` → `PLAN_CREATED: /path/to/plan.md`
   - `/errors` → `REPORT_CREATED: /path/to/report.md`

   **Clarification**: This protocol documents the **primary completion signal** for each command. Multi-artifact commands (like `/plan`, `/repair`, `/revise`, `/optimize-claude`) emit additional `REPORT_CREATED` signals for intermediate research reports, but the primary signal indicates the command's main output artifact. The hook opens only the primary artifact using priority logic (see Multi-Artifact Commands section).

   **Note**: Commands may emit multiple signals during execution. See "Multi-Artifact Commands" section for detailed artifact creation patterns.

3. **Neovim Remote API**: `$NVIM` environment variable provides socket path for RPC communication when running inside Neovim terminal

4. **Existing Hook Infrastructure**: `post-command-metrics.sh` and `tts-dispatcher.sh` demonstrate proven patterns for JSON parsing, configuration loading, and non-blocking execution

5. **Terminal Output Access Challenge**: Hooks receive JSON metadata but not command output, requiring solution for accessing completion signals

Key findings from /optimize-claude and /revise integration research:

6. **Multi-Artifact Commands**: `/optimize-claude` creates 4 research reports followed by 1 optimization plan, while `/revise` creates variable research reports followed by 1 revised plan

7. **PLAN_REVISED Signal**: `/revise` command uses unique `PLAN_REVISED` completion signal (not `PLAN_CREATED`), requiring additional pattern support

8. **Priority Logic Requirement**: Hook must prioritize primary artifacts (plans) over intermediate artifacts (research reports) to avoid opening 4+ files per command

9. **Backup Handling**: `/revise` creates backup before modification; if plan already open in Neovim, buffer reload prompt appears (acceptable UX)

## Success Criteria

- [ ] Hook script registered in `.claude/settings.local.json` for Stop event
- [ ] Hook correctly parses JSON input from Claude Code (command, status, cwd)
- [ ] Hook accesses command output to extract completion signals
- [ ] Primary artifact path extracted correctly (plans prioritized over reports for `/plan`)
- [ ] **At most one file opens per command execution (verified with /optimize-claude)**
- [ ] Priority logic correctly selects primary artifact from multiple signals
- [ ] Intermediate artifacts (research reports) do not auto-open for multi-artifact commands
- [ ] Neovim buffer opens via RPC when `$NVIM` socket available
- [ ] Context-aware opening (vertical split in terminal, replace in normal buffer)
- [ ] Graceful fallback when Neovim not running (silent exit)
- [ ] Debouncing prevents duplicate opens for same file
- [ ] Configuration allows disabling feature
- [ ] No performance impact (hook execution < 100ms)
- [ ] Feature works across workflow commands (/plan, /research, /build, /debug, /repair, /revise, /optimize-claude, /errors)
- [ ] Documentation explicitly states one-file-per-command constraint

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Workflow Command (/plan, /research, etc.)      │
│ Executes and outputs completion signal                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    Command completes successfully
                    Output: PLAN_CREATED: /path/to/plan.md
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Stop Hook Event                                 │
│ Triggered by CLI after command completion                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    JSON passed to hooks via stdin:
                    {"hook_event_name":"Stop","command":"/plan",
                     "status":"success","cwd":"..."}
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ post-buffer-opener.sh Hook (NEW)                            │
├─────────────────────────────────────────────────────────────┤
│ 1. Parse JSON input (command, status, cwd)                  │
│ 2. Check eligibility (Stop event, success status, eligible  │
│    command)                                                  │
│ 3. Access command output (via terminal buffer scraping)     │
│ 4. Extract primary artifact path (completion signal)        │
│ 5. Validate artifact file exists                            │
│ 6. Check Neovim availability ($NVIM socket)                 │
│ 7. Send RPC call to open buffer                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Neovim Terminal Buffer                                       │
│ Contains command output with completion signal              │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Neovim Instance (if running)                                │
├─────────────────────────────────────────────────────────────┤
│ buffer-opener.lua module                                    │
│ - Receives RPC call with artifact path                      │
│ - Detects current buffer context (terminal vs normal)       │
│ - Opens artifact with appropriate command (vsplit/edit)     │
│ - Shows notification to user                                │
└─────────────────────────────────────────────────────────────┘
```

### Completion Signal Priority Logic

Commands create different types of artifacts with varying priority levels. Multiple signals may be emitted (see Completion Signal Protocol above), but the hook opens at most one file per command execution.

| Priority | Signal Type | Commands | Purpose |
|----------|-------------|----------|---------|
| 1 (Highest) | `PLAN_CREATED` | /plan, /repair, /optimize-claude, /debug | Implementation plans |
| 1 (Highest) | `PLAN_REVISED` | /revise | Revised implementation plans |
| 2 | `IMPLEMENTATION_COMPLETE` (extract `summary_path:` field) | /build | Implementation summaries |
| 3 | `DEBUG_REPORT_CREATED` | /debug | Debug analysis reports |
| 4 (Lowest) | `REPORT_CREATED` | /research, /errors, /plan, /repair, /revise, /optimize-claude | Research reports (intermediate) |

**Multi-Artifact Commands**:
- `/plan`: Creates 1-4 research reports, then 1 implementation plan → Opens **plan only**
- `/optimize-claude`: Creates 4 research reports, then 1 optimization plan → Opens **plan only**
- `/revise`: Creates 0-N research reports, then 1 revised plan → Opens **revised plan only**
- `/repair`: Creates 1 error analysis report, then 1 repair plan → Opens **repair plan only**

### Key Components

1. **Hook Script** (`post-buffer-opener.sh`):
   - Bash script triggered on Stop event
   - Parses JSON input from Claude Code
   - Accesses command output via terminal buffer
   - Extracts primary artifact path via completion signal regex
   - Opens buffer in Neovim via `nvim --server` RPC

2. **Neovim Module** (`buffer-opener.lua`):
   - Lua module for context-aware buffer opening
   - Integrates with existing notification system
   - Provides configuration interface
   - Reuses existing buffer opening patterns from picker.lua

3. **Hook Registration** (`.claude/settings.local.json`):
   - Registers hook for Stop event
   - Uses wildcard matcher for all commands
   - Executes alongside existing hooks (metrics, TTS)

4. **Terminal Output Access**:
   - **Primary solution**: Hook reads terminal buffer output directly via Neovim RPC
   - Uses `nvim --server "$NVIM" --remote-expr 'getbufline(bufnr("%"), 1, "$")'` to get terminal content
   - Parses output for completion signals

### Performance Characteristics

- **Hook Execution**: < 100ms (JSON parsing + terminal read + RPC call)
- **Memory Footprint**: Minimal (bash script + one Lua module)
- **CPU Impact**: < 1% spike during hook execution
- **Resource Usage**: 0 file system watchers (vs 300-400 in watcher approach)
- **Scaling**: O(1) per command completion (no scaling issues)

### Security Considerations

- All file paths validated with `[ -f "$path" ]` before opening
- Shell quoting with `printf %q` prevents injection attacks
- Hook always exits 0 (non-blocking, cannot break workflow)
- Only opens markdown files (non-executable)
- Path restriction to project directory via `$CLAUDE_PROJECT_DIR`

## Implementation Phases

### Phase 1: Hook Script Implementation [NOT STARTED]
dependencies: []

**Objective**: Create post-buffer-opener.sh hook with JSON parsing, output access, and completion signal extraction

**Complexity**: Medium-High

**Tasks**:
- [ ] Create `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`
- [ ] Implement JSON input parsing (with jq and fallback)
- [ ] Implement eligibility checks (Stop event, success status, eligible commands)
- [ ] Implement terminal output access via Neovim RPC (`nvim --remote-expr`)
- [ ] Implement completion signal extraction with priority logic (PLAN/PLAN_REVISED > SUMMARY > DEBUG_REPORT > REPORT)
- [ ] Implement artifact path validation
- [ ] Implement Neovim socket detection (`$NVIM` environment variable)
- [ ] Implement buffer opening via RPC (`nvim --server "$NVIM" --remote-send`)
- [ ] Add error handling with silent failures (exit 0 always)
- [ ] Add debug logging (optional, controlled by environment variable)
- [ ] Make script executable (`chmod +x`)

**Testing**:
```bash
# Test JSON parsing
echo '{"hook_event_name":"Stop","command":"/plan","status":"success","cwd":"/home/benjamin/.config"}' | \
  .claude/hooks/post-buffer-opener.sh

# Test with real Neovim terminal (manual)
cd /home/benjamin/.config
nvim -c "ClaudeCode"
# In terminal: /research "test topic"
# Verify hook triggers and extracts path

# Test outside Neovim (should fail gracefully)
unset NVIM
echo '{"hook_event_name":"Stop","command":"/plan","status":"success"}' | \
  .claude/hooks/post-buffer-opener.sh
# Should exit 0 silently
```

**Expected Duration**: 4-5 hours

---

### Phase 2: Neovim Buffer Opener Module [NOT STARTED]
dependencies: [1]

**Objective**: Create Lua module for context-aware buffer opening with notification integration

**Complexity**: Low-Medium

**Tasks**:
- [ ] Create `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/buffer-opener.lua`
- [ ] Implement `M.open_artifact(filepath)` - Main function for opening artifacts
- [ ] Implement context detection (terminal vs normal buffer)
- [ ] Implement split decision logic (vsplit in terminal, edit otherwise)
- [ ] Integrate with `neotex.util.notifications` for user feedback
- [ ] Add path escaping with `vim.fn.fnameescape()`
- [ ] Add file existence validation
- [ ] Add error handling for invalid paths
- [ ] Document module with inline comments (purpose, API, usage)

**Testing**:
```lua
-- Test in Neovim
:lua require('neotex.plugins.ai.claude.util.buffer-opener').open_artifact('/home/benjamin/.config/CLAUDE.md')

-- Test context detection (from terminal buffer)
:terminal
:lua require('neotex.plugins.ai.claude.util.buffer-opener').open_artifact('/home/benjamin/.config/CLAUDE.md')
-- Should open in vsplit

-- Test error handling (non-existent file)
:lua require('neotex.plugins.ai.claude.util.buffer-opener').open_artifact('/nonexistent.md')
-- Should show error notification
```

**Expected Duration**: 2-3 hours

---

### Phase 3: Hook Registration and Configuration [NOT STARTED]
dependencies: [1, 2]

**Objective**: Register hook in settings.local.json and add configuration options

**Complexity**: Low

**Tasks**:
- [ ] Add hook entry to `/home/benjamin/.config/.claude/settings.local.json` in hooks.Stop array
- [ ] Use wildcard matcher (`"matcher": ".*"`)
- [ ] Use `$CLAUDE_PROJECT_DIR` variable for portable path
- [ ] Test hook registration (verify hook executes on command completion)
- [ ] Add configuration section to hook script (feature toggle via environment variable)
- [ ] Document configuration in hook script comments

**Testing**:
```bash
# Verify registration
cat .claude/settings.local.json | jq '.hooks.Stop'

# Test hook execution
cd /home/benjamin/.config
nvim -c "ClaudeCode"
# In terminal: /research "hook test"
# Verify hook runs (check debug log if enabled)

# Test with feature disabled
export BUFFER_OPENER_ENABLED=false
# Run command, verify no buffer opens
```

**Expected Duration**: 1-2 hours

---

### Phase 4: Terminal Output Access Refinement [NOT STARTED]
dependencies: [3]

**Objective**: Optimize terminal output access and implement robust completion signal parsing

**Complexity**: Medium

**Tasks**:
- [ ] Implement efficient terminal buffer reading (last 100 lines only)
- [ ] Add timeout protection for RPC calls (5 second timeout)
- [ ] Implement completion signal regex patterns for all workflow commands (including PLAN_REVISED, IMPLEMENTATION_COMPLETE)
- [ ] Implement priority extraction (plans/plan_revised > IMPLEMENTATION_COMPLETE summary_path > debug_report > reports)
- [ ] Add handling for multiple completion signals in same output
- [ ] Implement multi-line parsing for /build command (extract summary_path: field from IMPLEMENTATION_COMPLETE block)
- [ ] Test with various command outputs (/plan, /research, /build, /debug, /repair, /revise, /optimize-claude, /errors)
- [ ] Add fallback for commands without completion signals (silent failure)
- [ ] Optimize RPC call to minimize latency

**Regex Patterns**:
```bash
# Priority 1: Plan signals
PLAN_CREATED_PATTERN='PLAN_CREATED:\s*(.+)'
PLAN_REVISED_PATTERN='PLAN_REVISED:\s*(.+)'

# Priority 2: Build signal (multi-line format, extract summary_path field)
# /build returns: IMPLEMENTATION_COMPLETE: N
#                 summary_path: /path/to/summary.md
BUILD_SUMMARY_PATTERN='summary_path:\s*(.+)'

# Priority 3: Debug report signals
DEBUG_REPORT_PATTERN='DEBUG_REPORT_CREATED:\s*(.+)'

# Priority 4: Research report signals
REPORT_CREATED_PATTERN='REPORT_CREATED:\s*(.+)'
```

**Testing**:
```bash
# Test /plan command (multiple signals: REPORT_CREATED + PLAN_CREATED)
cd /home/benjamin/.config
nvim -c "ClaudeCode"
# Run: /plan "test feature"
# Verify only plan opens (not research reports)

# Test /optimize-claude command (multiple reports + plan)
# Run: /optimize-claude
# Verify only optimization plan opens (not 4 research reports)

# Test /revise command (reports + PLAN_REVISED)
# Run: /revise "update existing plan based on new requirements"
# Verify only revised plan opens (not research reports)

# Test /research command (single signal: REPORT_CREATED)
# Run: /research "test topic"
# Verify research report opens

# Test /build command (multi-line IMPLEMENTATION_COMPLETE with summary_path field)
# Run: /build <plan-path>
# Verify summary opens (extracted from summary_path: field)

# Test /errors command (single signal: REPORT_CREATED)
# Run: /errors --summary
# Verify error report opens

# Test /debug command (can emit either PLAN_CREATED or DEBUG_REPORT_CREATED)
# Run: /debug "investigate issue"
# Verify correct artifact opens based on signal type

# Test command without completion signal
# Run: /help
# Verify no buffer opens (silent failure)
```

**Expected Duration**: 3-4 hours

---

### Phase 5: Integration Testing and Edge Cases [NOT STARTED]
dependencies: [4]

**Objective**: Test across real workflows and handle edge cases

**Complexity**: Medium

**Tasks**:
- [ ] Test complete /plan workflow (research → planning phases)
- [ ] Test /research workflow with multiple report creation
- [ ] Test /build workflow with summary generation (extract summary_path from IMPLEMENTATION_COMPLETE)
- [ ] Test /debug workflow with debug report creation (handles both PLAN_CREATED and DEBUG_REPORT_CREATED)
- [ ] Test /repair workflow (error analysis + repair plan)
- [ ] Test /optimize-claude workflow (4 research reports + optimization plan)
- [ ] Test /revise workflow (research reports + PLAN_REVISED signal)
- [ ] Test /errors workflow (error analysis report)
- [ ] Test rapid command succession (debouncing, if needed)
- [ ] Test with Neovim not running (graceful failure)
- [ ] Test with external terminal (no $NVIM, should fail silently)
- [ ] Test with paths containing spaces
- [ ] Test with missing artifacts (file not created)
- [ ] Monitor performance during heavy usage (10+ commands)
- [ ] Test across different worktrees
- [ ] Verify no interference with existing hooks (metrics, TTS)

**Testing**:
```bash
# Real workflow test sequence
cd /home/benjamin/.config
nvim -c "ClaudeCode"

# Full plan workflow
# /plan "implement buffer opening test feature"
# Verify: only plan opens after all phases complete

# Multiple research workflow
# /research "buffer opening patterns"
# /research "neovim RPC integration"
# Verify: each report opens independently

# Build workflow
# /build <plan-from-above>
# Verify: summary opens after build completes

# Edge case: Neovim not running
pkill nvim
# Run command in external terminal
.claude/commands/research.md "test topic"
# Verify: no errors, hook exits silently

# Edge case: Path with spaces
mkdir -p "/tmp/Test Project/.claude/specs/001_test/reports"
# Create report with space in path
# Verify: opens correctly
```

**Expected Duration**: 3-4 hours

---

### Phase 6: Documentation and User Guide [NOT STARTED]
dependencies: [5]

**Objective**: Create comprehensive documentation for users and developers

**Complexity**: Low

**Tasks**:
- [ ] Add "Automatic Artifact Opening" section to `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`
- [ ] **Document one-file-per-command constraint explicitly in Feature Overview**
- [ ] Document how hook-based opening works
- [ ] Document behavior in different contexts (Neovim terminal vs external)
- [ ] **Document primary artifact selection logic with one-file guarantee**
- [ ] Add configuration reference (enabling/disabling feature)
- [ ] Add troubleshooting section:
  - Artifacts not opening automatically
  - **Wrong file opens (should never be more than one)**
  - Hook execution errors
  - Performance issues
- [ ] Document how to check hook execution (debug logs)
- [ ] Document differences from file watcher approach (migration notes)
- [ ] **Add developer documentation to hook script with one-file constraint explanation**
- [ ] **Update `.claude/hooks/README.md` with post-buffer-opener.sh entry including one-file guarantee**

**Testing**:
```bash
# Verify documentation accuracy
# Follow each troubleshooting step
# Test each configuration example
# Ensure all code snippets are valid
```

**Expected Duration**: 2 hours

---

## Testing Strategy

### Unit Testing

**Hook Script Tests**:
```bash
# Test JSON parsing with jq
echo '{"hook_event_name":"Stop","command":"/plan"}' | \
  .claude/hooks/post-buffer-opener.sh

# Test JSON parsing without jq (fallback)
PATH="/bin:/usr/bin" # Remove jq from PATH
echo '{"hook_event_name":"Stop","command":"/plan"}' | \
  .claude/hooks/post-buffer-opener.sh

# Test completion signal extraction
echo "PLAN_CREATED: /path/to/plan.md" | \
  grep -oP 'PLAN_CREATED:\s*\K.*'

# Test priority extraction (plan over report)
OUTPUT="REPORT_CREATED: /path/to/report.md
PLAN_CREATED: /path/to/plan.md"
# Should extract plan, not report

# Test /build multi-line output parsing
BUILD_OUTPUT="IMPLEMENTATION_COMPLETE: 3
summary_path: /path/to/summary.md
work_remaining: 0"
echo "$BUILD_OUTPUT" | grep -oP 'summary_path:\s*\K.*'
# Should extract /path/to/summary.md

# Test /debug dual signal handling
DEBUG_OUTPUT_PLAN="PLAN_CREATED: /path/to/debug-plan.md"
DEBUG_OUTPUT_REPORT="DEBUG_REPORT_CREATED: /path/to/debug-report.md"
# Both formats should be handled correctly
```

**Neovim Module Tests**:
```lua
-- Test file: nvim/tests/neotex/plugins/ai/claude/util/buffer-opener_spec.lua
describe("buffer-opener", function()
  local buffer_opener = require("neotex.plugins.ai.claude.util.buffer-opener")

  it("opens file in current window for normal buffer", function()
    -- Test implementation
  end)

  it("opens file in vsplit for terminal buffer", function()
    -- Test implementation
  end)

  it("handles non-existent files gracefully", function()
    -- Test implementation
  end)

  it("escapes special characters in paths", function()
    -- Test implementation
  end)
end)
```

### Integration Testing

**Manual Test Protocol**:

1. **Basic functionality**:
   - Start Neovim with Claude Code
   - Run `/research "test topic"`
   - Verify report opens automatically

2. **Multi-artifact command**:
   - Run `/plan "test feature"`
   - Verify only plan opens (not research reports)

3. **Context detection**:
   - Test from terminal buffer (should vsplit)
   - Test from normal buffer (should replace)

4. **External terminal**:
   - Run command outside Neovim
   - Verify no errors (graceful failure)

5. **Disabled feature**:
   - Set `BUFFER_OPENER_ENABLED=false`
   - Run command
   - Verify no automatic opening

### Performance Testing

**Benchmarks**:
- Hook execution time: < 100ms (target)
- Memory usage: < 10MB additional (bash + Lua module)
- CPU impact: < 1% during hook execution
- No impact on command execution time (hooks run after completion)

**Load testing**:
```bash
# Run 20 commands rapidly
for i in {1..20}; do
  echo "/research \"test $i\"" | nvim --server "$NVIM" --remote-send
  sleep 2
done
# Verify: all artifacts open correctly, no performance degradation
```

### Regression Testing

Ensure existing functionality unaffected:
- Command picker still works for manual artifact opening
- Session management continues to function
- Other hooks (metrics, TTS) execute normally
- Workflow commands complete successfully
- No impact on command output or error handling

## Documentation Requirements

### User Documentation

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`

Required sections with example text:

**Feature Overview**:
```markdown
## Automatic Artifact Opening

### How It Works

Claude Code workflow commands emit **completion signals** to indicate artifact creation. Multi-artifact commands like `/plan`, `/repair`, `/revise`, and `/optimize-claude` create multiple artifacts (research reports + plan), emitting multiple signals, but the **primary completion signal** indicates the main output artifact.

The hook monitors terminal output and automatically opens only the **primary artifact** (at most one file) based on priority rules:
- Plans (PLAN_CREATED, PLAN_REVISED) - highest priority
- Summaries (IMPLEMENTATION_COMPLETE with summary_path field) - medium priority
- Debug reports (DEBUG_REPORT_CREATED) - medium-low priority
- Research reports (REPORT_CREATED) - lowest priority (typically intermediate)

Intermediate artifacts remain accessible via the command picker (`<leader>ac`) but do not auto-open.

**One-File Guarantee**: Despite multiple signals being emitted, only one file opens per command execution. For multi-artifact commands like `/optimize-claude`, this means the final plan opens automatically, while intermediate research reports can be accessed manually if needed.
```

**Behavior**:
```markdown
## Behavior by Command Type

| Command | Artifacts Created | File Opened (One Only) |
|---------|-------------------|------------------------|
| /plan | 1-4 research reports + 1 plan | Plan only |
| /optimize-claude | 4 research reports + 1 plan | Plan only |
| /build | 1 summary (via IMPLEMENTATION_COMPLETE) | Summary (from summary_path field) |
| /revise | 0-N research reports + 1 plan | Revised plan only |
| /research | 1 research report | Research report |
| /debug | 1 debug plan or debug report | Plan or report (priority based) |
| /repair | 1 error analysis + 1 plan | Plan only |
| /errors | 1 error analysis report | Error report |

**One-File Guarantee**: The hook ensures exactly one buffer opens, even for multi-artifact
commands. Intermediate artifacts (research reports) remain accessible via command picker.
```

**Primary Artifact Selection**:
```markdown
## Primary Artifact Selection

The hook uses priority logic to ensure only one file opens:

1. **Plans** (PLAN_CREATED, PLAN_REVISED) - Highest priority
2. **Summaries** (IMPLEMENTATION_COMPLETE with summary_path) - Second priority
3. **Debug Reports** (DEBUG_REPORT_CREATED) - Third priority
4. **Research Reports** (REPORT_CREATED) - Lowest priority (usually intermediate)

This guarantees at most one file opens per command execution, with the most valuable
artifact selected automatically.
```

Additional required sections:
- **Setup**: Hook registration process
- **Configuration**: How to enable/disable feature
- **Troubleshooting**: Common issues and solutions
- **Limitations**: Requires running inside Neovim terminal

### Developer Documentation

**Location**: Inline in `/home/benjamin/.config/.claude/hooks/post-buffer-opener.sh`

Required content:
```bash
#!/usr/bin/env bash
# Post-Buffer-Opener Hook
# Purpose: Automatically open primary workflow artifacts in Neovim after command completion
#
# One-File Guarantee: Hook ensures at most one buffer opens per command execution
#
# Architecture:
#   1. Claude Code Stop hook triggers after command completes
#   2. Parse JSON input to get command name and status
#   3. Access terminal buffer output via Neovim RPC
#   4. Extract ALL completion signals from output
#   5. Apply priority logic to select PRIMARY artifact only (one file)
#   6. Open selected artifact in Neovim via RPC (if available)
#
# Priority Logic:
#   PLAN_CREATED/PLAN_REVISED (priority 1) > IMPLEMENTATION_COMPLETE/summary_path (priority 2) >
#   DEBUG_REPORT_CREATED (priority 3) > REPORT_CREATED (priority 4)
#
#   Example: /optimize-claude creates 4 REPORT_CREATED + 1 PLAN_CREATED
#            → Hook opens ONLY the plan (priority 1 wins)
#   Example: /build returns IMPLEMENTATION_COMPLETE with summary_path: /path/to/summary.md
#            → Hook extracts and opens the summary path
#
# Requirements:
#   - $NVIM environment variable (set by Neovim terminal)
#   - nvim command in PATH
#   - Command must output completion signal (PLAN_CREATED, etc.)
#
# Configuration:
#   - Set BUFFER_OPENER_ENABLED=false to disable
#   - Set BUFFER_OPENER_DEBUG=true for debug logging
```

### Hook Documentation

**Location**: `/home/benjamin/.config/.claude/hooks/README.md`

Add entry:
```markdown
### post-buffer-opener.sh
**Purpose**: Automatically open workflow artifacts in Neovim after command completion

**Triggered By**: Stop event

**One-File Guarantee**: Opens at most one file per command execution, selecting the primary
artifact via priority logic (plans > summaries > debug reports > research reports).

**Input** (via JSON stdin):
- `hook_event_name`: "Stop"
- `command`: Command that was executed
- `status`: "success" or "error"
- `cwd`: Working directory

**Actions**:
1. Check if running inside Neovim terminal ($NVIM)
2. Access terminal buffer output via RPC
3. Extract ALL completion signals (may be multiple)
4. Select PRIMARY artifact only (one file) using priority logic
5. Open selected artifact in Neovim with context-aware behavior

**Example**: When /optimize-claude creates 4 research reports + 1 plan, hook opens only the plan.

**Requirements**:
- Neovim with Claude Code running in terminal mode
- Commands that output completion signals

**Configuration**:
- `BUFFER_OPENER_ENABLED`: Enable/disable feature (default: true)
- `BUFFER_OPENER_DEBUG`: Enable debug logging (default: false)
```

### Code Standards Compliance

Per CLAUDE.md standards:
- Bash: Use `set -eo pipefail`, always exit 0 in hooks
- Lua: 2-space indentation, use `pcall` for safe requires
- No emojis in file content or output
- Comments describe WHAT code does, not WHY
- Use Unicode box-drawing for diagrams
- All paths must be absolute

## Dependencies

### System Requirements
- Neovim 0.9+ (for stable remote API)
- Bash 4.0+ (for hook script)
- Claude Code CLI (provides hook infrastructure)
- `jq` utility (optional, has fallback)

### Claude Code Requirements
- Hooks must be enabled in Claude Code CLI
- Stop hook event must be supported
- JSON input format must match specification

### Neovim Requirements
- Running inside Neovim terminal (`:ClaudeCode`)
- `$NVIM` environment variable set by Neovim
- Remote API available (`nvim --server`)

### Integration Points
- `.claude/settings.local.json` - Hook registration
- `neotex.util.notifications` - User notifications
- Existing buffer opening patterns from `picker.lua`
- Completion signal protocol from workflow agents

## Risk Management

### Technical Risks

**Risk**: Terminal buffer output unavailable via RPC
**Mitigation**: Use `nvim --remote-expr 'getbufline(...)'` which works reliably. Fallback to file-based output capture if needed.
**Likelihood**: Low

**Risk**: Hook execution blocks workflow
**Mitigation**: Always exit 0, use timeout for RPC calls, async execution where possible
**Likelihood**: Very Low

**Risk**: Completion signals not in output
**Mitigation**: Graceful failure (silent exit) when no signal found. Document signal format in agent guidelines.
**Likelihood**: Low (signals are standardized)

**Risk**: Multiple rapid commands cause race conditions
**Mitigation**: Each hook invocation is independent, terminal buffer contains complete output at Stop time
**Likelihood**: Very Low

### User Experience Risks

**Risk**: Users find auto-opening intrusive
**Mitigation**: Easy disable via environment variable. Document in README with examples.
**Likelihood**: Low

**Risk**: Feature only works in Neovim terminal
**Mitigation**: Clear documentation of requirement. Silent failure in external terminal (no errors).
**Likelihood**: Medium (acceptable limitation)

**Risk**: Wrong artifact opens for multi-artifact commands
**Mitigation**: Priority logic (plans > summaries > reports). Extensive testing in Phase 5.
**Likelihood**: Low

### Rollback Plan

If critical issues arise:
1. Remove hook from `.claude/settings.local.json`
2. Hook script remains in place but won't execute
3. Users can re-enable after fixes
4. No impact on workflow commands (hooks are optional)

## Comparison with File Watcher Approach

| Criterion | Hook-Based (This Plan) | File Watcher (Previous Plan) |
|-----------|------------------------|------------------------------|
| **Accuracy** | 100% (completion signals) | ~90% (file creation heuristics) |
| **Race conditions** | None (after completion) | Possible (file creation timing) |
| **Resource overhead** | Minimal (hook script only) | High (300-400 watchers for 100 topics) |
| **Primary artifact selection** | Excellent (signal priority) | Complex (file timestamp heuristics) |
| **Implementation complexity** | Medium (hook + RPC) | High (watchers + debouncing + cleanup) |
| **External terminal support** | No (requires $NVIM) | Yes (watches filesystem) |
| **Setup complexity** | Low (one hook registration) | High (watcher initialization per topic) |
| **Code invasiveness** | None (hooks are external) | Low (Neovim-side only) |
| **Performance** | Excellent (< 100ms) | Good (< 5% CPU during events) |
| **Reliability** | Very High | Medium (depends on timing) |

**Decision**: Hook-based approach is **simpler, more reliable, and more accurate** than file watchers for the primary use case (Neovim terminal).

## Future Enhancements

Beyond initial implementation (not in scope):

1. **Hybrid Approach**: Combine hooks (Neovim terminal) + file watchers (external terminal) for universal support

2. **Smart Window Management**: Remember user preferences for split direction per artifact type

3. **Artifact History**: Track recently opened artifacts with Telescope integration

4. **Conditional Opening Rules**: User-defined Lua functions to control when to auto-open

5. **Multi-Window Support**: Detect best window for opening (e.g., prefer existing split)

6. **Session Integration**: Link opened artifacts to Claude Code sessions for context tracking

## Migration from Spec 848

This plan **supersedes** the file watcher plan (spec 848). Key changes:

**Removed**:
- File system watcher implementation (`artifact-watcher.lua`)
- Three-tier watching (specs → topics → artifacts)
- Debouncing logic for file events
- Watcher initialization in `claude/init.lua`

**Added**:
- Hook script (`post-buffer-opener.sh`)
- Terminal output access via RPC
- Completion signal parsing
- Hook registration in `settings.local.json`

**Unchanged**:
- Buffer opening module (`buffer-opener.lua`)
- Context-aware split behavior
- Notification integration
- User configuration interface

**Migration Path**:
1. Do not implement spec 848 plan
2. Implement this plan (spec 851) instead
3. Document differences in user guide
4. No user action required (new feature)

## Notes

- Hook-based approach trades **universal support** (works anywhere) for **simplicity and reliability** (works perfectly in Neovim terminal)
- The limitation of requiring Neovim terminal is acceptable because:
  - Primary use case is Claude Code integrated with Neovim
  - Users running externally can still use artifact picker (`<leader>ac`)
  - Eliminates complexity of file system monitoring
- Future hybrid approach could add external terminal support without changing this implementation

---

**Implementation Complexity Analysis**:
```
Score = Base(10 - new feature)
        + Tasks/2 (65 tasks / 2 = 32.5)
        + Files*3 (2 new files * 3 = 6)
        + Integrations*5 (6 integration points * 5 = 30)
        - Simplicity bonus (0, complex RPC integration)
      = 10 + 32.5 + 6 + 30 + 0
      = 78.5 → 78.0
```

Complexity tier: **Tier 2** (50-200), starting with **Level 0** (single file plan) per progressive planning protocol. Expansion available via `/expand` if needed during implementation.

**Note**: All phases include `[NOT STARTED]` markers for `/build` command compatibility and progress tracking.

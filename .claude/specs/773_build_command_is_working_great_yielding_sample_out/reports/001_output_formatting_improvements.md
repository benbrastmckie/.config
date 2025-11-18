# Build Command Output Formatting Improvements Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Build command output formatting improvements
- **Report Type**: codebase analysis and best practices

## Executive Summary

The /build command generates verbose, repetitive output that obscures meaningful status updates. Analysis identified five primary issues: excessive `set +H` header repetition, redundant project directory bootstrapping output, verbose state machine transitions, truncated Bash blocks in Claude Code display, and lack of a unified progress system. Five improvement options are proposed ranging from minimal fixes (Option 1) to comprehensive redesign (Option 5), with Option 3 (Progressive Output Levels) recommended as the optimal balance of impact versus complexity.

## Findings

### Current State Analysis

#### Issue 1: Repetitive Comment Headers
The build command contains 7 bash blocks, each beginning with identical `set +H` header (build.md:37, 54, 211, 284, 483, 611, 857). This creates repetitive visual noise:
```
● Bash(set +H  # CRITICAL: Disable history expansion
      mkdir -p "${HOME}/.claude/tmp" 2>/dev/null || true...)
```

#### Issue 2: Redundant Project Directory Bootstrapping
Every bash block repeats the same 12-line project directory detection code (build.md:76-92, 214-227, 284-303, 410-427, 486-504, 615-628, 715-728, 774-792, 860-878). This adds 100+ lines of redundant output across a single workflow.

#### Issue 3: Verbose Diagnostic Output
Error and diagnostic blocks are excessively verbose (build.md:262-275, 312-324, 527-539, 656-670, 816-829, 904-915):
```bash
  echo "DIAGNOSTIC Information:" >&2
  echo "  - Current State: ..." >&2
  echo "  - Attempted Transition: ..." >&2
  echo "POSSIBLE CAUSES:" >&2
  echo "  - State machine not initialized properly" >&2
  echo "  - Invalid transition from current state" >&2
  echo "TROUBLESHOOTING:" >&2
```

#### Issue 4: Truncated Bash Output Display
The sample output shows Claude Code truncating bash output with "+ N more lines (ctrl+o to expand)" (build-output.md:16-17, 21-24, 26-29), making key information like state transitions and errors invisible without manual expansion.

#### Issue 5: Inconsistent Progress Marker Usage
The unified-logger.sh provides `emit_progress()` function (lines 700-714) and progress-dashboard.sh offers rich terminal rendering (lines 295-302), but build.md uses raw echo statements instead. Only one PROGRESS marker appears (build.md:146) among 90+ echo statements.

### Current Output Volume Analysis

| Component | Lines | Purpose | Noise Level |
|-----------|-------|---------|-------------|
| Bash block headers | 7 | Disable history | High |
| Project detection | 84 | Find CLAUDE_PROJECT_DIR | High |
| Library sourcing | 14 | Load dependencies | Medium |
| State transitions | 42 | Track workflow state | Medium |
| Checkpoints | 35 | Verify phase completion | Low |
| Error handling | 150+ | Diagnostic output | High (when triggered) |

### Industry Best Practices (from CLI Guidelines)

1. **Signal-to-Noise Ratio**: "Group similar errors under explanatory headers rather than printing many similar lines" (clig.dev)
2. **Default Output**: "Display output on success, but keep it brief" - balance between silence and verbosity
3. **Progress Indicators**: "A good spinner or progress indicator can make a program appear to be faster than it is" NOTE: I don't need this
4. **Verbosity Control**: Provide `-v` for warnings, `-vv` for info, `-vvv` for debug; `-q` for quiet NOTE: I don't need this
5. **Error Formatting**: "Don't print stack traces to regular users; reserve for unexpected errors" NOTE: I do want stack traces for all errors and would like to see them in full if possible

### Existing Infrastructure

The codebase has underutilized output formatting infrastructure:

1. **unified-logger.sh** (lines 700-714): `emit_progress()` for structured progress markers
2. **progress-dashboard.sh** (lines 105-264): Full ANSI dashboard with terminal detection
3. **base-utils.sh**: `info()`, `warn()`, `error()` functions for structured logging

## Recommendations

### Option 1: Minimal Fixes (Low Effort, Low Impact)

**Description**: Reduce obvious repetition without structural changes.

**Changes**:
- Consolidate bash block headers by removing redundant `set +H` comments after first occurrence NOTE: from experience and the .claude/docs/ it seems that `set +H` helped to avoid errors. If there is a better way around this that would be great, but I want to be careful not to reproduce errors. It would be prudent to attempt the refactor for one /research first to confirm errors are not created, and then role out the rest of the refactor from any lessons learned on this first command.
- Truncate diagnostic output to single-line summaries with `--verbose` flag for full details NOTE: this might do the trick, and maybe is all that I am looking for if this provides fast and clear status updates
- Replace 90% of echo statements with unified-logger.sh `emit_progress()` calls NOTE: this might also do the trick

**Strengths**:
- Minimal code changes (~50 lines modified)
- No architectural changes required
- Immediate reduction in output noise

**Weaknesses**:
- Doesn't address fundamental design issues
- Truncated output still visible in Claude Code display
- No structured progress tracking

**Runtime Overhead**: Negligible
**Implementation Time**: 1-2 hours

### Option 2: Quiet Mode Flag (Low Effort, Medium Impact)

NOTE: I want to avoid flags for simplicity

**Description**: Add `--quiet` flag to suppress non-essential output.

**Changes**:
- Add `-q/--quiet` flag parsing (build.md:122-127)
- Wrap verbose output in `[ "$QUIET" != "true" ] && echo ...` conditionals
- Keep only CHECKPOINT and ERROR output in quiet mode
- Add `--verbose` for full diagnostic output

**Strengths**:
- User-controlled verbosity
- Backwards compatible (default remains verbose)
- Follows CLI best practices

**Weaknesses**:
- Requires explicit user action to reduce noise
- Conditional logic adds complexity throughout file
- Doesn't improve default experience

**Runtime Overhead**: Minimal (boolean checks)
**Implementation Time**: 2-3 hours

### Option 3: Progressive Output Levels (Medium Effort, High Impact) - RECOMMENDED

NOTE: I don't need multiple levels of output, just one minimal but complete implementation that reports all useful information and nothing extra

**Description**: Implement structured output levels with smart defaults.

**Changes**:
1. Extract project directory detection to library function (source once, cache result)
2. Replace all echo statements with level-aware output functions:
   - `emit_status()` - Always shown (phase transitions, completion)
   - `emit_detail()` - Shown with `-v` (state machine info)
   - `emit_debug()` - Shown with `-vv` (full diagnostics)
3. Default to `emit_status()` level only
4. Add automatic progress marker emission at key milestones

**Output Transformation**:
```
BEFORE:
● Bash(set +H  # CRITICAL: Disable history expansion...)
  ⎿ ... +10 lines (ctrl+o to expand)

AFTER:
● Bash(Build workflow: Initializing state machine...)
  ⎿ Phase 1: Implementation → In Progress
```

**Strengths**:
- Dramatic noise reduction (estimated 80% less output)
- Meaningful status visible by default
- Full details available when needed
- Uses existing unified-logger infrastructure

**Weaknesses**:
- Requires systematic refactoring of all bash blocks
- May hide useful information during debugging
- Learning curve for output level flags

**Runtime Overhead**: Minimal (function calls vs raw echo)
**Implementation Time**: 4-6 hours

### Option 4: Dashboard Integration (High Effort, Very High Impact)

**Description**: Integrate progress-dashboard.sh for rich terminal updates.

**Changes**:
1. Initialize dashboard at workflow start
2. Update dashboard after each state transition
3. Clear dashboard on completion
4. Fallback to PROGRESS markers for non-ANSI terminals
5. Replace all bash block output with dashboard updates

**Output Transformation**:
```
┌─────────────────────────────────────────────────────┐
│ Implementation Progress: 772_implementation.md      │
├─────────────────────────────────────────────────────┤
│ Phase 1: Setup ..................... → Complete     │
│ Phase 2: Implementation ............ → In Progress  │
├─────────────────────────────────────────────────────┤
│ Progress: [████████████░░░░░░░░░░░░░░] 40% (2/5)    │
│ Elapsed: 3m 42s  |  Estimated: ~5m 30s             │
└─────────────────────────────────────────────────────┘
```

**Strengths**:
- Professional visual presentation
- Real-time progress visibility
- Leverages existing progress-dashboard.sh code
- Terminal capability detection built-in

**Weaknesses**:
- Significant implementation complexity
- May conflict with subagent Task output
- Requires careful state management
- Not all terminals support ANSI

**Runtime Overhead**: Moderate (terminal detection, rendering)
**Implementation Time**: 8-12 hours

### Option 5: Command Description Refactor (Medium Effort, High Impact)

NOTE: this also seems like a very natural thing to do if it does not cause any errors.

**Description**: Restructure bash blocks to use meaningful descriptions for Claude Code display.

**Changes**:
1. Change bash command descriptions from code snippets to meaningful summaries:
   - OLD: `Bash(set +H  # CRITICAL: Disable history expansion...)`
   - NEW: `Bash(Initializing build workflow)`
2. Move verbose code execution inside bash blocks (not in description)
3. Emit single summary line after each block:
   ```bash
   echo "Initialized state machine (WORKFLOW_ID: $WORKFLOW_ID)"
   ```
4. Suppress intermediate output with `> /dev/null` for non-essential operations

**Strengths**:
- Directly addresses Claude Code truncation issue
- Makes collapsed view informative
- Maintains full functionality
- Compatible with all other options

**Weaknesses**:
- Requires understanding Claude Code display behavior
- May require changes to how bash blocks are structured
- Loss of inline visibility during execution

**Runtime Overhead**: Negligible
**Implementation Time**: 3-4 hours

## Option Comparison Matrix

| Option | Output Reduction | User Control | Implementation | Runtime Cost | Compatibility |
|--------|-----------------|--------------|----------------|--------------|---------------|
| 1 Minimal | 20% | None | 1-2h | None | Full |
| 2 Quiet Mode | 60% | Manual | 2-3h | Minimal | Full |
| 3 Progressive | 80% | Flags | 4-6h | Minimal | Full |
| 4 Dashboard | 90% | None | 8-12h | Moderate | Partial |
| 5 Description | 70% | None | 3-4h | None | Full |

## Implementation Priority

**Recommended**: Start with **Option 3 (Progressive Output Levels)** combined with **Option 5 (Command Description Refactor)**.

**Rationale**:
- Option 3 provides the best signal-to-noise ratio improvement
- Option 5 directly addresses Claude Code display truncation
- Combined, they reduce output by 85%+ while maintaining full debuggability
- Both leverage existing infrastructure (unified-logger.sh)
- Neither requires complex terminal handling (Option 4)

**Phase 1** (Option 5): Refactor bash block descriptions - 3-4 hours
**Phase 2** (Option 3): Implement progressive output levels - 4-6 hours
**Phase 3** (Option 2): Add quiet/verbose flags - 2-3 hours (optional)

Total estimated implementation: 9-13 hours for complete solution.

## References

### Files Analyzed
- /home/benjamin/.config/.claude/commands/build.md (lines 1-976) - Main build command
- /home/benjamin/.config/.claude/build-output.md (lines 1-35) - Sample output
- /home/benjamin/.config/.claude/lib/unified-logger.sh (lines 1-825) - Logging infrastructure
- /home/benjamin/.config/.claude/lib/progress-dashboard.sh (lines 1-352) - Dashboard rendering
- /home/benjamin/.config/.claude/agents/implementer-coordinator.md (lines 1-200) - Agent that produces output

### External Sources
- Command Line Interface Guidelines (https://clig.dev/) - Output formatting best practices
- Microsoft Azure CLI Format Output Guide - Output structure patterns
- CLI Design Best Practices (https://codyaray.com/2020/07/cli-design-best-practices) - Verbosity control

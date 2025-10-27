# Performance Features and User-Facing Options

**Research Date**: 2025-10-23
**Topic**: Comparative analysis of performance optimization features and user-facing options in /orchestrate vs /supervise workflows
**Status**: Complete

## Executive Summary

This report analyzes the performance optimization features and user-facing options available in /orchestrate vs /supervise commands. Key findings reveal that /orchestrate provides significantly richer user-facing features including dry-run mode, TodoWrite integration for progress tracking, and comprehensive PROGRESS: markers. However, /supervise's minimalist design lacks these user-friendly options entirely. Both commands share similar parallel execution capabilities and context reduction strategies, but /orchestrate offers superior user feedback mechanisms and workflow preview capabilities.

**Critical Gap**: /supervise lacks ALL user-facing features present in /orchestrate (--dry-run, --dashboard, TodoWrite, PROGRESS markers).

## Research Findings

### Command-Line Options and Flags

**Command Signatures**:
- `/orchestrate`: `<workflow-description> [--parallel] [--sequential] [--create-pr] [--dry-run]` (orchestrate.md:3)
- `/supervise`: `<workflow-description>` (NO FLAGS - supervise.md:1-5)

**Comparison Table**:

| Feature | /orchestrate | /supervise | Gap |
|---------|-------------|-----------|-----|
| `--parallel` | ✓ Yes (orchestrate.md:3) | Implicit default | Missing explicit flag |
| `--sequential` | ✓ Yes (orchestrate.md:3) | N/A | Not supported |
| `--create-pr` | ✓ Yes (orchestrate.md:3, 4192-4194) | N/A | Missing feature |
| `--dry-run` | ✓ Yes (orchestrate.md:3, 101-116) | N/A | **Critical gap** |
| `--dashboard` | N/A (implement only) | N/A | Both lack |

**Key Findings**:
1. **orchestrate.md:3** - Provides 4 command-line flags for user control
2. **supervise.md:1-5** - Zero command-line flags, minimal user control
3. **orchestrate.md:101-116** - Dry-run mode with 7-step workflow analysis and confirmation prompt
4. **orchestrate.md:4192-4194** - Conditional PR creation based on --create-pr flag
5. **implement.md:3** - Comprehensive flag set: `[--report-scope-drift] [--force-replan] [--create-pr] [--dashboard] [--dry-run]`

**Analysis**:
- /orchestrate provides explicit execution mode control (--parallel vs --sequential)
- /supervise assumes parallel by default with no sequential fallback option
- Neither command implements --dashboard (only available in /implement)
- --dry-run is /orchestrate's killer feature for workflow preview

### Performance Optimization Features

**Parallel Execution**:

Both commands support parallel research agent invocation, but with different approaches:

**orchestrate.md**:
- **Line 49**: "Invoke 2-4 research-specialist agents in parallel"
- **Performance**: Commands README.md:200 - "40-60% time savings"
- **Method**: Dynamic topic-based parallelism (2-4 agents based on complexity)
- **Context**: orchestrate.md:63 - "metadata-based context passing for <30% context usage"

**supervise.md**:
- **Line 526**: "Invoke 2-4 research agents in parallel"
- **Lines 542-567**: Complexity-based research topic detection (1-4 topics)
- **Performance**: supervise.md:158 - References "Performance Targets" section
- **Method**: Keyword-based complexity scoring to determine agent count

**Context Reduction Strategies**:

Both commands use similar metadata extraction patterns:

**orchestrate.md**:
- **Line 1263**: "Metadata extraction (title + 50-word summary) reduces context by 99%"
- **Line 63**: "metadata-based context passing (forward_message pattern)"
- **Line 702**: Sources `metadata-extraction.sh` utility library
- **Line 1155**: "Generate 100-word summary for context reduction"

**supervise.md**:
- **Line 16**: "Extract and aggregate metadata from agent results (forward message pattern)"
- **Line 35**: "Read: Parse agent output files for metadata extraction"
- **Line 874**: "Plan Metadata Extraction" section
- Similar ~99% context reduction through metadata-only passing

**Key Performance Metrics**:

| Metric | /orchestrate | /supervise | Source |
|--------|-------------|-----------|--------|
| Time savings | 40-60% | Not documented | README.md:200 |
| Context reduction | 99% | Not documented | orchestrate.md:1263 |
| Parallel agents | 2-4 (dynamic) | 1-4 (keyword-based) | orchestrate.md:49, supervise.md:542-567 |
| Target context usage | <30% | Not specified | orchestrate.md:63 |

**Analysis**:
- Both commands implement identical parallel execution architecture
- /orchestrate documents performance benefits; /supervise does not
- Context reduction strategy is shared (metadata extraction + forward message pattern)
- /orchestrate's dynamic parallelism may be more adaptive than /supervise's keyword scoring

### User Feedback and Progress Mechanisms

**TodoWrite Integration**:

**orchestrate.md**:
- **Line 2**: Explicitly lists TodoWrite in allowed-tools
- **Line 128**: "EXECUTE NOW: Initialize TodoWrite and workflow state"
- **Line 132**: "USE the TodoWrite tool to create a task list tracking all workflow phases"
- **Line 226**: "TodoWrite invoked with all 6 workflow phase tasks"
- **Line 326**: "Update TodoWrite BEFORE emitting phase transition markers"
- **Line 4400**: "UPDATE TodoWrite to mark all tasks complete"
- **Lines 5112-5129**: Complete TodoWrite lifecycle (initialize → update → complete)

**supervise.md**:
- **Line 2**: Lists TodoWrite in allowed-tools
- **Line 33**: "TodoWrite: Track phase progress"
- **NO USAGE INSTRUCTIONS** - Listed as available but never mandated or demonstrated

**Gap**: /orchestrate has 8+ explicit TodoWrite instructions; /supervise mentions it but provides zero implementation guidance.

**PROGRESS: Markers**:

**orchestrate.md**:
- **Line 301**: "Progress Streaming" section header
- **Line 326**: "Update TodoWrite BEFORE emitting phase transition markers"
- Detailed PROGRESS: marker specifications in referenced logging-patterns.md

**supervise.md**:
- **NO PROGRESS MARKERS** found in command file
- No progress streaming section
- No phase transition markers specified

**References to Progress Systems**:

From grep results:
- **report.md:202-206**: Defines PROGRESS: marker format for research agents
  - "PROGRESS: Creating report file"
  - "PROGRESS: Searching codebase"
  - "PROGRESS: Analyzing findings"
  - "PROGRESS: Updating report"
  - "PROGRESS: Research complete"
- **orchestrate-enhancements.md:69-80**: Complexity evaluation progress markers
  - "PROGRESS: Starting Complexity Evaluation Phase"
  - "PROGRESS: Evaluating Phase N/M complexity..."
  - "PROGRESS: Phase N - score: X.X (method) - expansion decision"

**Dashboard Features**:

Neither /orchestrate nor /supervise implement dashboard features. Dashboard is exclusive to /implement:

**implement.md:255-303**:
- **Line 257**: "--dashboard flag enables real-time visual progress tracking"
- **Line 264-269**: Features list (ANSI rendering, phase progress, progress bar, time tracking, test results, wave info)
- **Line 272-273**: Terminal requirements (xterm, kitty, alacritty, etc.)
- **Line 276**: "Graceful Fallback" to PROGRESS: markers when ANSI unavailable
- **Line 279-295**: Visual dashboard layout example with Unicode box-drawing
- **Line 298**: Uses `.claude/lib/progress-dashboard.sh` utility

**Analysis**:
- /orchestrate provides comprehensive TodoWrite integration and PROGRESS: markers
- /supervise lists TodoWrite but never uses it, provides no progress feedback
- Dashboard feature is implement-exclusive, unavailable to either command
- /orchestrate's progress streaming is a major user experience advantage

### Dry-Run and Workflow Preview

**Dry-Run Implementation**:

**orchestrate.md**:
- **Line 3**: `--dry-run` in argument-hint signature
- **Lines 101-116**: Complete dry-run mode documentation
  - **7-step analysis**: Workflow parsing, research topic ID, agent planning, duration estimation, execution preview, artifact preview, confirmation prompt
  - **Line 104**: Usage example with dry-run flag
  - **Line 116**: References detailed examples in orchestration-alternatives.md

**supervise.md**:
- **NO --dry-run FLAG**
- **NO PREVIEW MODE**
- **NO WORKFLOW ANALYSIS PREVIEW**

**Dry-Run Analysis Features** (orchestrate.md:107-115):
1. Workflow parsing - analyze description and determine workflow type
2. Research topic identification - identify topics from workflow description
3. Agent planning - determine which agents invoked for each phase
4. Duration estimation - estimate time based on complexity and agent metrics
5. Execution preview - display phase-by-phase workflow with agent assignments
6. Artifact preview - list reports, plans, files that would be created
7. Confirmation prompt - option to proceed with actual workflow execution

**Comparison to /implement dry-run**:

**implement.md:304-319**:
- **Line 306**: `--dry-run` flag preview execution plan without changes
- **Line 308**: Can combine `--dry-run` with `--dashboard` for visual preview
- **Lines 310-318**: 7-step analysis:
  - Plan parsing (structure, phases, tasks, dependencies)
  - Complexity evaluation (hybrid complexity scores per phase)
  - Agent assignments (which agents invoked for each phase)
  - Duration estimation (agent-registry metrics)
  - File/test analysis (affected files and tests)
  - Execution preview (wave-based order with parallelism)
  - Confirmation prompt (proceed or exit)

**Analysis**:
- /orchestrate implements full dry-run preview with 7-step analysis
- /supervise has NO preview capability whatsoever
- /implement's dry-run is even more detailed (includes complexity scoring, wave analysis, test detection)
- Dry-run + dashboard combination (/implement) provides best user experience
- /supervise's lack of preview mode is a critical usability gap

### Checkpoint and State Management

**orchestrate.md**:
- **Line 60**: "DO NOT skip checkpoint saves between phases"
- **Line 82**: References "Checkpoint structure and operations" in templates
- **Line 88**: References "Checkpoint save/restore patterns" in docs
- **Line 124**: "checkpoint persistence" in initialization infrastructure
- **Lines 211-228**: Complete checkpoint detection and resume logic
  - Check for `.claude/checkpoints/orchestrate_latest.checkpoint`
  - Prompt user to resume if checkpoint found
  - Load checkpoint state and skip to current_phase if resuming
- **Line 252**: Sources `checkpoint-utils.sh` utility library

**supervise.md**:
- **Line 15**: "Verify agent outputs at mandatory checkpoints"
- **Line 23**: "Skip mandatory verification checkpoints" (prohibition)
- **Line 34**: "Bash: Verification checkpoints (ls, grep, wc)"
- **Line 228**: "File Verification Checkpoint Template"
- **NO PERSISTENT CHECKPOINT SYSTEM** - Only verification checkpoints, not resumable state

**Analysis**:
- /orchestrate implements persistent checkpoint system for workflow resumption
- /supervise uses "checkpoint" term for verification points only, not state persistence
- /orchestrate can resume interrupted workflows; /supervise cannot
- Checkpoint-utils.sh library exclusive to /orchestrate workflow

## Related Reports

- [Overview Report](./OVERVIEW.md) - Complete comparison of /orchestrate vs /supervise across all dimensions
- [Core Workflow Report](./001_core_workflow_phases_and_execution_patterns.md) - Phase structure and execution patterns
- [Agent Coordination Report](./002_agent_coordination_and_behavioral_injection.md) - Behavioral injection patterns and agent invocation
- [Error Handling Report](./003_error_handling_state_management_and_recovery.md) - Error recovery and checkpoint systems

## File References

### Command Files
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - Lines: 3, 49, 63, 101-116, 124, 128, 132, 211-228, 226, 252, 301, 326, 702, 1155, 1263, 4192-4194, 4400, 5112-5129
- `/home/benjamin/.config/.claude/commands/supervise.md` - Lines: 2, 15-16, 23, 33-35, 158, 228, 526, 542-567, 874
- `/home/benjamin/.config/.claude/commands/implement.md` - Lines: 3, 255-319
- `/home/benjamin/.config/.claude/commands/README.md` - Line: 200

### Documentation Files
- `/home/benjamin/.config/.claude/commands/shared/orchestration-alternatives.md` - Referenced for dry-run examples
- `/home/benjamin/.config/.claude/commands/shared/orchestrate-enhancements.md` - Lines: 69-80 (progress markers)
- `/home/benjamin/.config/.claude/commands/report.md` - Lines: 202-206 (PROGRESS: marker format)

### Utility Libraries
- `.claude/lib/metadata-extraction.sh` - Context reduction utilities
- `.claude/lib/checkpoint-utils.sh` - Checkpoint save/restore operations
- `.claude/lib/progress-dashboard.sh` - Dashboard rendering (implement only)

## Recommendations

### 1. Add User-Facing Options to /supervise

**Priority**: CRITICAL
**Effort**: Medium

/supervise should implement the same user-facing options as /orchestrate:

```markdown
# Recommended signature
/supervise <workflow-description> [--parallel] [--sequential] [--dry-run] [--create-pr]
```

**Specific additions**:
- `--dry-run` flag with 7-step workflow analysis (copy from orchestrate.md:101-116)
- `--sequential` flag to disable parallel execution (for debugging/CI environments)
- `--create-pr` flag for automatic PR creation after workflow completion
- `--parallel` flag to make default behavior explicit

**Rationale**: Users should not have to choose between clean architecture (/supervise) and usability features (/orchestrate). The architectural benefits of /supervise are undermined by poor user experience.

**Implementation**: Add argument parsing section after line 5 in supervise.md, copy dry-run logic from orchestrate.md.

### 2. Implement TodoWrite Integration in /supervise

**Priority**: HIGH
**Effort**: Low

/supervise currently lists TodoWrite as an allowed tool (supervise.md:2, 33) but provides zero implementation guidance. Add explicit TodoWrite instructions:

```markdown
# Recommended addition after line 33
**Step 1: Initialize TodoWrite with Workflow Phases**

USE the TodoWrite tool to create a task list tracking all workflow phases:
- Phase 0: Location & Setup (pending)
- Phase 1: Research (pending)
- Phase 2: Planning (pending)
- Phase 3: Implementation (pending)
- Phase 4: Testing (pending)
- Phase 5: Debugging (conditional)
- Phase 6: Documentation (pending)

**Step 2: Update TodoWrite After Each Phase**
Mark phase as in_progress at start, complete at end.
```

**Rationale**: TodoWrite provides visual progress feedback that significantly improves user experience during long-running workflows. /supervise already declares it as available but never uses it.

**Implementation**: Copy TodoWrite initialization pattern from orchestrate.md:128-226, adapt for /supervise's phase structure.

### 3. Add PROGRESS: Markers to /supervise

**Priority**: HIGH
**Effort**: Low

/supervise has no progress streaming mechanism. Add PROGRESS: markers at key workflow transitions:

```markdown
# Recommended markers
PROGRESS: Phase 0 - Creating topic directory structure
PROGRESS: Phase 1 - Invoking {N} parallel research agents
PROGRESS: Phase 1 - Research complete ({N}/{N} reports created)
PROGRESS: Phase 2 - Creating implementation plan
PROGRESS: Phase 2 - Plan created: {plan_path}
PROGRESS: Phase 3 - Implementation in progress
PROGRESS: Phase 3 - Implementation complete
PROGRESS: Phase 4 - Running test suite
PROGRESS: Phase 4 - Tests {passed|failed}
PROGRESS: Phase 5 - Debugging test failures (conditional)
PROGRESS: Phase 6 - Generating documentation
PROGRESS: Workflow complete - All artifacts created
```

**Rationale**: PROGRESS: markers are the bare minimum for user feedback in terminal environments. Without them, users have no visibility into workflow status during execution.

**Implementation**: Add marker emission after each phase verification checkpoint (after supervise.md:228 verification template usage).

### 4. Document Performance Metrics in /supervise

**Priority**: MEDIUM
**Effort**: Low

/supervise implements parallel execution and context reduction but does not document performance benefits. Add metrics section:

```markdown
## Performance Characteristics

- **Parallel Research**: 40-60% time savings vs sequential execution
- **Context Reduction**: ~99% through metadata-only passing
- **Target Context Usage**: <30% throughout workflow
- **Parallel Agents**: 1-4 agents based on workflow complexity
- **Metadata Extraction**: Title + 50-word summary per artifact
```

**Rationale**: Users need to understand performance implications when choosing between commands. /orchestrate documents these metrics; /supervise should match.

**Implementation**: Add "Performance Characteristics" section after line 158 in supervise.md, copy metrics from orchestrate.md:1263 and README.md:200.

### 5. Implement Persistent Checkpoints in /supervise

**Priority**: LOW
**Effort**: High

/supervise uses "checkpoint" term for verification points only (supervise.md:15, 23, 34, 228), not resumable workflow state like /orchestrate. Consider adding persistent checkpoint system:

```markdown
## Checkpoint and Resume Support

**Checkpoint File**: `.claude/checkpoints/supervise_{timestamp}.checkpoint`

**Checkpoint Contents**:
- Current phase number
- Workflow description
- Topic directory path
- Completed artifact paths
- Agent invocation history
- Timestamp and metadata

**Resume Logic**:
Before starting workflow, check for existing checkpoint.
Prompt user to resume or start fresh.
If resuming, load state and skip to current_phase.
```

**Rationale**: Long-running workflows can be interrupted (network issues, timeouts, user cancellation). Persistent checkpoints enable resumption without restarting entire workflow.

**Implementation**: Source `.claude/lib/checkpoint-utils.sh` (orchestrate.md:252), add checkpoint detection logic (copy from orchestrate.md:211-228), save checkpoint after each phase completion.

**Note**: This is lower priority because /supervise workflows are typically shorter than /orchestrate workflows due to simplified architecture.

## Conclusion

This analysis reveals significant disparities in user-facing features between /orchestrate and /supervise. While /supervise achieves its architectural goal of clean agent delegation (no SlashCommand anti-pattern), it sacrifices critical user experience features in the process:

**Feature Parity**:
- Both commands implement parallel execution (40-60% time savings)
- Both use metadata-based context reduction (~99% reduction)
- Both support 2-4 parallel research agents

**Critical Gaps in /supervise**:
1. **No dry-run mode** - Cannot preview workflow before execution
2. **No TodoWrite integration** - No visual progress tracking despite listing tool as available
3. **No PROGRESS: markers** - Zero user feedback during execution
4. **No command-line flags** - No user control over execution mode
5. **No performance metrics documentation** - Users unaware of optimization benefits
6. **No persistent checkpoints** - Cannot resume interrupted workflows

**Recommendations Priority**:
1. CRITICAL: Add --dry-run flag (Rec #1) - Essential for usability
2. HIGH: Implement TodoWrite (Rec #2) - Tool already listed, just needs usage
3. HIGH: Add PROGRESS: markers (Rec #3) - Bare minimum feedback mechanism
4. MEDIUM: Document performance metrics (Rec #4) - Quick documentation win
5. LOW: Persistent checkpoints (Rec #5) - Nice-to-have for long workflows

The architectural cleanliness of /supervise is valuable, but not at the expense of basic user experience. All five recommendations are implementable without compromising /supervise's core design principle (no SlashCommand invocations). The command can maintain its clean agent delegation pattern while still providing users with preview, progress, and control capabilities.

**Next Steps**: Prioritize implementing Recommendations #1-3 to bring /supervise to feature parity with /orchestrate for user-facing options, while preserving its superior architectural pattern.

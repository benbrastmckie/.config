# Expected vs Actual /supervise Behavior Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: expected_vs_actual_behavior
- **Report Type**: behavioral comparison
- **Source**: CLAUDE.md, command-reference.md, supervise.md, TODO.md
- **Parent Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The /supervise command is designed as a clean multi-agent workflow orchestrator that follows strict architectural patterns: pure orchestration via Task tool (no SlashCommand usage), mandatory verification checkpoints, and 100% file creation rate with auto-recovery. When functioning correctly, /supervise should never use TodoWrite, never search codebases directly with Grep/Glob, and never execute tasks itself—it delegates all work to specialized agents via the Task tool. The TODO.md output reveals the assistant treated the invocation as a normal user request rather than executing the orchestrator command, indicating a meta-level failure where the /supervise command never started execution.

## Findings

### Expected Behavior (From Documentation)

#### Architecture Pattern (CLAUDE.md lines 240-252)

The /supervise command implements hierarchical agent architecture with these characteristics:

1. **Multi-level agent coordination** that minimizes context window consumption through metadata-based context passing
2. **Metadata Extraction Pattern** - Extract title + 50-word summary from reports/plans (99% context reduction)
3. **Forward Message Pattern** - Pass subagent responses directly without re-summarization
4. **Recursive Supervision** - Supervisors can manage sub-supervisors for complex workflows
5. **Context Pruning** - Aggressive cleanup of completed phase data
6. **Subagent Delegation** - Commands delegate complex tasks to specialized subagents

**Performance Targets** (CLAUDE.md line 254-257):
- **Target**: <30% context usage throughout workflows
- **Achieved**: 92-97% reduction through metadata-only passing
- **Performance**: 60-80% time savings with parallel subagent execution

#### Command Summary (CLAUDE.md lines 340-342)

"/supervise - Sequential orchestration with proven architectural compliance"

Part of three orchestration commands:
- /orchestrate: Full-featured with PR automation
- /coordinate: Wave-based parallel execution (2,500-3,000 lines)
- /supervise: Sequential with proven architectural compliance

All provide 7-phase workflow with parallel research (2-4 agents), automated complexity evaluation, and conditional debugging.

#### Core Role Definition (supervise.md lines 7-25)

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

#### Workflow Phases (supervise.md lines 115-131)

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Implementation (conditional)
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

#### Tool Restrictions (supervise.md lines 31-40)

**TOOLS ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (not for task execution)

**TOOLS PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)

#### Phase 1 Expected Behavior (supervise.md lines 899-987)

**STEP 2: Invoke 2-4 research agents in parallel (single message, multiple Task calls)**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATHS[i]} (absolute path, pre-calculated by orchestrator)
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[i]}
  "
}
```

The command should emit progress markers:
- `PROGRESS: [Phase 1] - Invoking N research agents in parallel`
- `PROGRESS: [Phase 1] - All research agents invoked - awaiting completion`

#### Verification Requirements (supervise.md lines 988-1117)

After agent invocations, the command MUST verify all research report files exist:

```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"

VERIFICATION_FAILURES=0
SUCCESSFUL_REPORT_PATHS=()
FAILED_AGENTS=()

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  if retry_with_backoff 2 1000 test -f "$REPORT_PATH" -a -s "$REPORT_PATH"; then
    # Success - add to successful list
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    # Failure - retry or fail
    FAILED_AGENTS+=("agent_$i")
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done
```

#### Library Dependencies (supervise.md lines 234-323)

The command sources 7 critical libraries in Phase 0:

1. **workflow-detection.sh** - Fallback available (lines 242-274)
2. **error-handling.sh** - CRITICAL, no fallback (line 276-282)
3. **checkpoint-utils.sh** - CRITICAL, no fallback (line 284-290)
4. **unified-logger.sh** - CRITICAL, no fallback (line 292-298)
5. **unified-location-detection.sh** - CRITICAL, no fallback (line 300-306)
6. **metadata-extraction.sh** - CRITICAL, no fallback (line 308-314)
7. **context-pruning.sh** - CRITICAL, no fallback (line 316-322)

If any critical library is missing, the command exits immediately with error.

#### Anti-Pattern Documentation (CLAUDE.md lines 294-306)

**Historical Note**: An anti-pattern was discovered in the /supervise command (spec 438) where 7 YAML blocks were wrapped in markdown code fences, causing a 0% agent delegation rate.

**Resolution**: All orchestration commands now enforce Standard 11 (Imperative Agent Invocation Pattern), which requires:
- Imperative instructions (`**EXECUTE NOW**: USE the Task tool...`)
- No code block wrappers around Task invocations
- Direct reference to agent behavioral files
- Explicit completion signals

### Actual Behavior (From TODO.md)

The TODO.md file (lines 1-103) shows the assistant's response when /supervise was invoked. Key observations:

#### No Orchestrator Execution

The output shows normal assistant behavior, NOT orchestrator behavior:

**Line 6**: "I'll analyze the /coordinate command to identify why it's not executing research subagents correctly"

This is the assistant speaking in first person, explaining what it will do—not an orchestrator command executing predefined phases.

#### Direct Tool Usage (Violations)

**Lines 9-22**: Multiple Read tool calls made directly by the assistant:
- `Read(.claude/TODO.md)`
- `Read(.claude/commands/coordinate.md)`
- `Read(.claude/commands/supervise.md)`
- `Read(.claude/agents/research-specialist.md)`

**Expected**: Orchestrator should NEVER use Read/Grep/Glob to search codebase. These tasks should be delegated to research-specialist agents via Task tool.

**Line 25**: `Bash(mkdir -p "/home/benjamin/.config/.claude/specs/494_coordinate_command_failure_analysis/reports")`

**Expected**: Orchestrator should only create the topic root directory in Phase 0. Subdirectories (reports/) should be created lazily by agents when they write files.

**Line 28-30**: `Write(.claude/specs/494_coordinate_command_failure_analysis/reports/001_coordinate_vs_supervise_analysis.md)`

**Expected**: Orchestrator should NEVER use Write tool. Research reports should be created by research-specialist agents via Task tool invocations.

#### TodoWrite Usage

The output includes no TodoWrite calls, but the presence of direct tool usage indicates the orchestrator pattern was never engaged.

**Expected**: /supervise should use TodoWrite to track phase progress (per line 33 of supervise.md).

#### No Progress Markers

The output contains NO progress markers like:
- `PROGRESS: [Phase 0] - Pre-calculating artifact paths`
- `PROGRESS: [Phase 1] - Invoking N research agents`

**Expected**: All orchestrator commands emit progress markers at phase boundaries (supervise.md lines 223-230).

#### No Agent Invocations

The output shows ZERO Task tool invocations to specialized agents.

**Expected**: The orchestrator should invoke research-specialist agents in Phase 1 with pre-calculated report paths.

#### No Verification Checkpoints

The output contains no verification checkpoint messages like:
```
════════════════════════════════════════════════════════
  MANDATORY VERIFICATION - Research Reports
════════════════════════════════════════════════════════
```

**Expected**: After each phase, the orchestrator should verify agent outputs at mandatory checkpoints (supervise.md lines 988-991).

#### No Workflow Scope Detection

The output shows no workflow scope detection output like:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Workflow Scope Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Description: "..."
Detected Scope: research-and-plan
```

**Expected**: Phase 0 should detect workflow scope and display phase execution plan (supervise.md lines 612-673).

#### Assistant Commentary

**Lines 41-101**: The assistant provided extensive commentary explaining what it found:
- "Critical Discovery: Meta-Level Failure"
- "Root Cause Analysis"
- "Key Differences Found"
- "Immediate Actions"

**Expected**: Orchestrator commands do NOT provide interpretive commentary. They execute phases, invoke agents, verify outputs, and report artifact locations.

### Root Cause Analysis

The evidence points to a **meta-level failure** where the /supervise command never started execution:

#### Hypothesis 1: Library Sourcing Failure (MOST LIKELY)

**Evidence**:
1. No bash library sourcing output visible in TODO.md
2. No error messages about missing libraries
3. Command should fail immediately if critical libraries missing (lines 276-322 of supervise.md)

**Mechanism**: If library sourcing fails silently (e.g., incorrect SCRIPT_DIR calculation), the command exits before Phase 0 starts, causing Claude to treat the invocation as a normal user request.

**Test**: Check if library files exist and are sourceable:
```bash
ls -la /home/benjamin/.config/.claude/lib/{error-handling,checkpoint-utils,unified-logger,unified-location-detection,metadata-extraction,context-pruning}.sh
```

#### Hypothesis 2: Command File Parsing Error

**Evidence**:
1. No Phase 0 output (should be first thing after library sourcing)
2. supervise.md is 2177 lines—bash parsing errors possible

**Mechanism**: If supervise.md contains syntax errors (unclosed quotes, unescaped backticks), bash parsing fails silently and Claude treats content as documentation.

**Test**: Validate bash syntax:
```bash
bash -n /home/benjamin/.config/.claude/commands/supervise.md 2>&1 | head -20
```

#### Hypothesis 3: SlashCommand Tool Routing Failure

**Evidence**:
1. User invoked `/supervise` but assistant never saw the command prompt
2. No `.md` file expansion markers visible

**Mechanism**: The SlashCommand tool may have failed to expand supervise.md content into the prompt, causing Claude to receive only the user's description without the command instructions.

**Test**: Check SlashCommand tool implementation for /supervise routing.

#### Hypothesis 4: BASH_SOURCE Variable Issue

**Evidence**:
1. Library sourcing depends on `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` (line 239)
2. If BASH_SOURCE is undefined or wrong, all library imports fail

**Mechanism**: In some execution contexts, BASH_SOURCE[0] may not resolve correctly, causing the SCRIPT_DIR calculation to return the wrong path or fail entirely.

**Test**: Check if SCRIPT_DIR calculation works in the execution environment.

### Comparison Table

| Aspect | Expected (/supervise) | Actual (TODO.md) |
|--------|----------------------|------------------|
| **Execution Mode** | Orchestrator command | Normal assistant conversation |
| **Tool Usage** | Task only (+ TodoWrite, Bash verification) | Read, Write, Bash directly |
| **Agent Invocations** | 2-4 research-specialist agents | Zero agents invoked |
| **Progress Markers** | PROGRESS: [Phase N] emitted | No progress markers |
| **Verification** | Mandatory checkpoints after each phase | No verification checkpoints |
| **File Creation** | Agents create files via Task tool | Assistant creates files directly via Write |
| **Commentary Style** | Minimal status messages | Extensive explanatory text |
| **Workflow Scope** | Detect and display (research-only, research-and-plan, etc.) | No scope detection |
| **Library Dependencies** | Source 7 libraries in Phase 0 | No library sourcing visible |
| **Phase Execution** | Phase 0 → 1 → 2 → ... | No phase execution |

### Behavioral Signature Differences

#### Orchestrator Signature (Expected)

When /supervise executes correctly, you should see:

1. **Library sourcing output** (or fallback warnings)
2. **Workflow scope detection** with boxed display
3. **Phase 0 header**: "Location and Path Pre-Calculation"
4. **Progress markers**: `PROGRESS: [Phase N] - action`
5. **Agent Task invocations** with research-specialist behavioral injection
6. **Verification checkpoints** with box drawing characters
7. **Artifact path exports**: `TOPIC_PATH=...`, `PLAN_PATH=...`
8. **Minimal commentary**: Status messages, not explanations

#### Assistant Signature (Actual)

What TODO.md shows:

1. **First-person commentary**: "I'll analyze...", "I've completed..."
2. **Direct tool usage**: Read, Write, Bash without delegation
3. **Interpretive analysis**: "Critical Discovery:", "Root Cause Analysis"
4. **No progress markers**
5. **No agent invocations**
6. **No verification checkpoints**
7. **Extensive explanations**: Multi-paragraph summaries
8. **Proactive recommendations**: "Would you like me to..."

## Recommendations

### Immediate Diagnostics

1. **Verify library files exist and are accessible**:
   ```bash
   ls -la /home/benjamin/.config/.claude/lib/{workflow-detection,error-handling,checkpoint-utils,unified-logger,unified-location-detection,metadata-extraction,context-pruning}.sh
   ```

2. **Check bash syntax of supervise.md**:
   ```bash
   bash -n /home/benjamin/.config/.claude/commands/supervise.md 2>&1 | head -20
   ```

3. **Test SCRIPT_DIR calculation manually**:
   ```bash
   cd /home/benjamin/.config/.claude/commands && \
   SCRIPT_DIR="$(cd "$(dirname "supervise.md")" && pwd)" && \
   echo "SCRIPT_DIR: $SCRIPT_DIR" && \
   ls -la "$SCRIPT_DIR/../lib/"
   ```

4. **Check SlashCommand tool routing**:
   - Verify /supervise is registered in command index
   - Check if command file expansion occurs before Claude sees prompt

### Architectural Fixes

If library sourcing is the issue:

1. **Add early debug output** at the very start of supervise.md (before library sourcing):
   ```bash
   echo "DEBUG: /supervise command starting execution"
   echo "DEBUG: BASH_SOURCE[0]=${BASH_SOURCE[0]}"
   echo "DEBUG: Current directory: $(pwd)"
   ```

2. **Add fallback for critical libraries** (similar to workflow-detection.sh fallback in lines 242-274):
   ```bash
   if [ -f "$SCRIPT_DIR/../lib/error-handling.sh" ]; then
     source "$SCRIPT_DIR/../lib/error-handling.sh"
   else
     echo "ERROR: error-handling.sh not found"
     echo "DEBUG: Searched in: $SCRIPT_DIR/../lib/"
     echo "DEBUG: SCRIPT_DIR=$SCRIPT_DIR"
     ls -la "$SCRIPT_DIR/../lib/" 2>&1 || echo "DEBUG: Directory does not exist"
     exit 1
   fi
   ```

3. **Add function existence verification** after library sourcing (already present in lines 357-388):
   - Verify this section is actually executing
   - If not, the command is exiting before reaching function verification

### Long-Term Improvements

1. **Add startup marker** that Claude MUST echo before any agent invocations:
   ```bash
   echo "ORCHESTRATOR_ACTIVE: /supervise v1.0"
   ```

2. **Validate execution environment** in Phase 0:
   ```bash
   # Ensure we're in orchestrator mode
   if [ -z "$ORCHESTRATOR_MODE" ]; then
     echo "ERROR: /supervise must run in orchestrator mode"
     echo "This command requires SlashCommand tool expansion"
     exit 1
   fi
   ```

3. **Add comprehensive diagnostic mode**:
   ```bash
   /supervise --diagnose
   # Output:
   # - Library file locations and sizes
   # - Function availability after sourcing
   # - SCRIPT_DIR calculation result
   # - Workflow scope detection test
   ```

## References

### Primary Sources
- /home/benjamin/.config/CLAUDE.md (lines 240-252: Hierarchical Agent Architecture)
- /home/benjamin/.config/CLAUDE.md (lines 340-342: /supervise description)
- /home/benjamin/.config/.claude/commands/supervise.md (complete command file, 2177 lines)
- /home/benjamin/.config/.claude/TODO.md (lines 1-103: Actual behavior output)
- /home/benjamin/.config/.claude/docs/reference/command-reference.md (lines 1-200: Command catalog)

### Related Documentation
- /home/benjamin/.config/.claude/agents/research-specialist.md (research agent behavioral file)
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md (agent invocation pattern)
- /home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md (mandatory verification pattern)
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md (Standard 11: Imperative Agent Invocation)

### Library Files (Expected Locations)
- /home/benjamin/.config/.claude/lib/workflow-detection.sh
- /home/benjamin/.config/.claude/lib/error-handling.sh
- /home/benjamin/.config/.claude/lib/checkpoint-utils.sh
- /home/benjamin/.config/.claude/lib/unified-logger.sh
- /home/benjamin/.config/.claude/lib/unified-location-detection.sh
- /home/benjamin/.config/.claude/lib/metadata-extraction.sh
- /home/benjamin/.config/.claude/lib/context-pruning.sh

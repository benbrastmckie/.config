# Orchestrator Workflow Optimization Research Report

## Metadata
- **Date**: 2025-10-28
- **Agent**: research-specialist
- **Topic**: Orchestrator Workflow Optimization
- **Report Type**: best practices and pattern recognition
- **Commands Analyzed**: /orchestrate, /coordinate, /supervise, /research
- **Libraries Analyzed**: 8 optimization libraries
- **Complexity Level**: Advanced (multi-agent coordination optimization)
- **Parent Report**: [Research Overview](./OVERVIEW.md)
- **Related Subtopics**: [Context Preservation](./001_context_window_preservation_techniques.md), [Hierarchical Agent Delegation](./002_hierarchical_agent_delegation_patterns.md), [Standards Documentation](./003_current_standards_documentation_review.md)

## Executive Summary

Analysis of orchestrator workflow optimization in Claude Code reveals systematic performance improvements through unified library integration, wave-based parallel execution, metadata-only passing, and fail-fast error handling. The research examined three orchestration commands (totaling ~10,000 lines) and identified patterns achieving 85% token reduction in Phase 0 (25x speedup), 40-60% time savings through parallel implementation, 95-99% context reduction via metadata extraction, and 100% file creation reliability through verification checkpoints. Key optimization strategies include pre-calculating all artifact paths before agent invocations, using behavioral injection instead of command chaining, implementing wave-based parallel execution with dependency analysis, aggressive context pruning between phases, and fail-fast error handling with comprehensive diagnostics. These patterns enable orchestrators to coordinate 10+ specialized agents across 7-phase workflows while maintaining <30% context usage and predictable performance.

## Findings

### 1. Phase 0 Path Pre-Calculation Optimization (85% Token Reduction, 25x Speedup)

**Pattern**: Unified location detection library replaced agent-based path calculation.

**Previous Approach**:
- Used location-specialist agent for Phase 0
- Token usage: 75,600 tokens
- Execution time: 25.2 seconds

**Current Approach** (unified-location-detection.sh):
- Pure Bash library with no external dependencies
- Token usage: <11,000 tokens
- Execution time: <1 second
- Functions: detect_project_root(), detect_specs_directory(), get_next_topic_number(), create_topic_structure()

**Performance Impact**:
- 85% token reduction (75.6k → 11k tokens)
- 25x speedup (25.2s → <1s)
- Lazy directory creation eliminates 400-500 empty subdirectories
- 80% reduction in mkdir calls during location detection

**Reference**: .claude/lib/unified-location-detection.sh:1-150

### 2. Wave-Based Parallel Execution (40-60% Time Savings)

**Pattern**: Parse plan dependencies to group independent phases into waves, executing wave members in parallel.

**Dependency Analysis Process**:
1. Parse implementation plan for phase dependencies
2. Extract `dependencies: [N, M]` from each phase
3. Build directed acyclic graph (DAG)
4. Group phases using Kahn's algorithm:
   - Wave 1: All phases with no dependencies
   - Wave 2: Phases depending only on Wave 1
   - Wave N: Phases depending only on previous waves

**Example** (/coordinate, lines 212-234):
```
Plan with 8 phases → 4 waves
  Wave 1: [Phase 1, Phase 2]          ← 2 phases in parallel
  Wave 2: [Phase 3, Phase 4, Phase 5] ← 3 phases in parallel
  Wave 3: [Phase 6, Phase 7]          ← 2 phases in parallel
  Wave 4: [Phase 8]                   ← 1 phase

Sequential: 8T
Wave-based: 4T
Savings: 50%
```

**Performance Metrics**:
- 4-agent research: 75% savings (40 min → 10 min)
- 5-phase implementation: 25% savings (16h → 12h)
- /orchestrate (7 phases): 40% savings (8h → 4.8h)
- Complex workflow (15 phases, 6 waves): 60% savings (30h → 12h)

**References**: .claude/lib/dependency-analyzer.sh, parallel-execution.md:1-292

### 3. Metadata Extraction for Context Reduction (95-99% Reduction)

**Pattern**: Agents return condensed metadata (200-300 tokens) instead of full content (5,000-10,000 tokens).

**Required Metadata Fields**:
```json
{
  "artifact_path": "/absolute/path/to/artifact.md",
  "title": "Extracted from first # heading",
  "summary": "First 50 words from Executive Summary",
  "key_findings": ["Finding 1", "Finding 2", "Finding 3"],
  "recommendations": ["Rec 1", "Rec 2", "Rec 3"],
  "file_paths": ["/path/to/file1.sh", "/path/to/file2.md"]
}
```

**Extraction Utilities** (.claude/lib/metadata-extraction.sh:13-87):
- extract_report_metadata() - Extract title, summary, paths, recommendations
- extract_plan_metadata() - Extract title, phase count, complexity, time estimates
- load_metadata_on_demand() - Generic metadata loader with caching

**Performance Impact**:
- Research agent output: 5,000 tokens → 250 tokens (95% reduction)
- 4 parallel research agents: 20,000 tokens → 1,000 tokens (95% reduction)
- Hierarchical supervision (3 levels): 60,000 tokens → 3,000 tokens (95% reduction)

**Agent Coordination Scalability**:
- Before: 2-3 agents maximum per supervisor (context overflow)
- After: 10+ agents per supervisor
- Recursive supervision: 30+ total agents across 3 levels

**Context Budget**:
- Before: 80-100% context usage
- After: <30% context usage across all 7 phases

**Reference**: metadata-extraction.md:1-393

### 4. Workflow Scope Detection for Conditional Execution

**Pattern**: Detect workflow type from description and execute only appropriate phases.

**Scope Types** (workflow-detection.sh:16-84):

1. **research-only**: Phases 0-1 only
   - Keywords: "research [topic]" without "plan" or "implement"
   - No plan created, no summary

2. **research-and-plan**: Phases 0-2 only (MOST COMMON)
   - Keywords: "research...to create plan", "analyze...for planning"
   - Creates reports + plan

3. **full-implementation**: Phases 0-4, 6
   - Keywords: "implement", "build", "add feature"
   - Phase 5 conditional on test failures

4. **debug-only**: Phases 0, 1, 5 only
   - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
   - No new plan or summary

**Benefits**:
- Appropriate phase execution (no unnecessary planning for research-only)
- Clear user feedback (explains why phases skipped)
- Performance optimization (skip phases, not execute-then-discard)

**Reference**: .claude/lib/workflow-detection.sh:1-100

### 5. Fail-Fast Error Handling with Enhanced Diagnostics

**Pattern**: Configuration errors fail immediately with 5-component diagnostic messages.

**5-Component Error Message Standard**:
1. **What failed**: Specific operation that failed
2. **Expected state**: What should have happened
3. **Diagnostic commands**: Exact commands to investigate
4. **Context**: Why this operation is required
5. **Action**: Steps to resolve the issue

**Example Implementation**:
```bash
if ! source "$SCRIPT_DIR/../lib/library-sourcing.sh"; then
  echo "ERROR: Required library not found: library-sourcing.sh"
  echo "Expected location: $SCRIPT_DIR/../lib/library-sourcing.sh"
  echo "Diagnostic commands:"
  echo "  ls -la $SCRIPT_DIR/../lib/ | grep library-sourcing"
  exit 1
fi
```

**Fail-Fast Philosophy**:
- Bootstrap failures: Exit immediately, no fallbacks
- Configuration errors: Never mask with silent degradation
- Transient tool failures: Detect with verification, single retry allowed
- Test failures: Not errors - enter conditional debugging phase

**Spec 057 Case Study**:
- Removed 32 lines of bootstrap fallbacks
- Enhanced 7 library error messages with diagnostics
- Result: 100% bootstrap reliability through fail-fast

**Critical Distinction**:
- Bootstrap Fallbacks (REMOVED): Hide configuration errors that MUST be fixed
- File Creation Verification Fallbacks (PRESERVED): Detect transient Write tool failures

**Reference**: orchestration-troubleshooting.md:1-833

### 6. Mandatory Verification Checkpoints (100% File Creation Reliability)

**Pattern**: Defense-in-depth approach with three verification layers.

**Three-Layer Defense**:

**Layer 1: Agent Prompt Enforcement**
- Mark file creation as "ABSOLUTE REQUIREMENT" or "PRIMARY OBLIGATION"
- Sequential dependencies: "STEP 1 (REQUIRED BEFORE STEP 2)"
- Imperative language: "YOU MUST create" not "should create"

**Layer 2: Agent Behavioral File Reinforcement**
- Standard 0.5: Subagent Prompt Enforcement
- 10-category enforcement rubric (target: 95+/100 score)
- Required completion criteria with explicit checklists

**Layer 3: Command-Level Verification + Fallback** (/coordinate, lines 873-985):
```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - Research Reports"
echo "════════════════════════════════════════════════════════"

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  if [ -f "$REPORT_PATH" ] && [ -s "$REPORT_PATH" ]; then
    FILE_SIZE=$(wc -c < "$REPORT_PATH")
    echo "  ✅ PASSED: Report created successfully ($FILE_SIZE bytes)"
    SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
  else
    echo "  ❌ ERROR: Report file verification failed"
    echo "  DIAGNOSTIC INFORMATION:"
    echo "    - Expected path: $REPORT_PATH"
    echo "    - Agent: research-specialist (agent $i)"
    VERIFICATION_FAILURES=$((VERIFICATION_FAILURES + 1))
  fi
done
```

**Performance Impact**:
- Without verification: 60-80% file creation reliability
- With verification: 100% file creation reliability

**Partial Research Success**: Research phase continues if ≥50% of parallel agents succeed (other phases require 100%).

**Reference**: verification-fallback.md:1-404

### 7. Library Integration for Code Reuse

**Required Libraries** (/coordinate, lines 318-332):

| Library | Purpose |
|---------|---------|
| workflow-detection.sh | Workflow scope detection, phase execution control |
| error-handling.sh | Error classification, diagnostic messages |
| checkpoint-utils.sh | Workflow resume, state management |
| unified-logger.sh | Progress tracking, event logging |
| unified-location-detection.sh | Topic directory structure creation |
| metadata-extraction.sh | Context reduction via metadata-only passing |
| context-pruning.sh | Context optimization between phases |
| dependency-analyzer.sh | Wave-based execution, dependency graph analysis |

**Library Sourcing Pattern** (/coordinate, lines 352-388):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library-sourcing utilities first
if [ -f "$SCRIPT_DIR/../lib/library-sourcing.sh" ]; then
  source "$SCRIPT_DIR/../lib/library-sourcing.sh"
else
  echo "ERROR: Required library not found: library-sourcing.sh"
  exit 1
fi

# Source all required libraries
if ! source_required_libraries "dependency-analyzer.sh"; then
  exit 1
fi

echo "✓ All libraries loaded successfully"
```

**Function Verification** (/coordinate, lines 423-463):
- Verify critical functions defined after library sourcing
- REQUIRED_FUNCTIONS array: detect_workflow_scope, should_run_phase, emit_progress, save_checkpoint, restore_checkpoint
- Fail-fast if any functions missing

**Benefits**:
- Code reuse (single implementation)
- Consistency (same behavior across commands)
- Testing (test libraries once, benefits all commands)
- Maintenance (update once, applies everywhere)

### 8. Progress Streaming and Checkpoint Recovery

**Progress Markers** (/coordinate, lines 341-349):

Format: `PROGRESS: [Phase N] - [action]`

Examples:
```
PROGRESS: [Phase 0] - Location pre-calculation complete
PROGRESS: [Phase 1] - Research complete (4/4 succeeded)
PROGRESS: [Phase 2] - Planning complete (plan created with 8 phases)
```

**When to Emit**:
- Phase transitions (start/complete)
- Agent invocations (before/after)
- Verification checkpoints (completion)
- Long operations (every 30s)

**Checkpoint Pattern** (/coordinate, lines 1043-1061):
```bash
# Save checkpoint after Phase 1
ARTIFACT_PATHS_JSON=$(cat <<EOF
{
  "research_reports": [$(printf '"%s",' "${SUCCESSFUL_REPORT_PATHS[@]}" | sed 's/,$//')]
}
EOF
)
save_checkpoint "coordinate" "phase_1" "$ARTIFACT_PATHS_JSON"

# Context pruning after Phase 1
store_phase_metadata "phase_1" "complete" "$PHASE_1_ARTIFACTS"
```

**Auto-Resume** (/coordinate, lines 637-679):
```bash
RESUME_DATA=$(restore_checkpoint "coordinate" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
  echo "Resuming from Phase $RESUME_PHASE..."
fi
```

**Benefits**:
- Workflow continuity (recover from interruptions)
- No duplicate work (skip completed phases)
- State preservation (artifact paths, status)
- User visibility (know what's happening)
- Debugging aid (last marker before failure)

### 9. Layered Context Architecture

**Four-Layer Approach**:

**Layer 1 (Permanent)**: User request, workflow type, critical errors
- Retention: Entire workflow duration
- Size: 500-1,000 tokens

**Layer 2 (Phase-Scoped)**: Current phase instructions
- Retention: During phase only
- Size: 2,000-4,000 tokens
- Pruned: After phase completion

**Layer 3 (Metadata)**: Artifact paths, phase summaries
- Retention: Between phases for coordination
- Size: 200-300 tokens per phase
- Pruned: Apply pruning policy based on workflow scope

**Layer 4 (Transient)**: Full agent responses
- Retention: 0 tokens (extract metadata immediately)
- Size: 5,000-10,000 tokens per agent
- Pruned: Immediately after metadata extraction

**Context Pruning Utilities** (.claude/lib/context-pruning.sh):
- prune_subagent_output() - Clear full outputs after metadata extraction
- prune_phase_metadata() - Remove phase data after completion
- apply_pruning_policy() - Automatic pruning by workflow type
- store_phase_metadata() - Store metadata in checkpoint for recovery

**Checkpoint-Based State**:
- Store full state in .claude/data/checkpoints/workflow_id.json
- Prune state from active context after saving
- Load on-demand during recovery

**Performance Impact**:
- Research phase (4 agents): 20,000 tokens → 1,000 tokens (95% reduction)
- 7-phase /orchestrate: 40,000 tokens → 7,000 tokens (82% reduction)
- Hierarchical (3 levels): 60,000 tokens → 4,000 tokens (93% reduction)

## Recommendations

### 1. Adopt Unified Library Integration for Phase 0 Across All Orchestrators

**Rationale**: 85% token reduction and 25x speedup enables near-instantaneous Phase 0 completion.

**Implementation**:
- Replace location-specialist agent invocations with unified-location-detection.sh
- Use initialize_workflow_paths() for consolidated path calculation + directory creation
- Verify directory structure before proceeding to Phase 1
- Add lazy directory creation to eliminate empty subdirectories

**Success Metrics**:
- Phase 0 completion time: <1 second (vs ~25s with agent)
- Token usage: <11,000 tokens (vs 75,600 with agent)
- Zero empty subdirectories created

### 2. Implement Wave-Based Parallel Execution for All Implementation Commands

**Rationale**: 40-60% time savings for plans with ≥3 phases and dependency information.

**Implementation**:
- Parse implementation plans for phase dependencies using dependency-analyzer.sh
- Calculate wave structure using Kahn's algorithm
- Invoke implementer-coordinator agent for wave orchestration
- Execute wave members in parallel, waves sequentially
- Save wave checkpoints for resume capability

**Success Metrics**:
- Time savings: 40-60% for plans with dependencies
- No overhead for simple plans (<3 phases)
- 100% dependency satisfaction

### 3. Enforce Metadata-Only Passing Between All Agents and Phases

**Rationale**: 95-99% context reduction enables coordination of 10+ agents vs 2-3 without optimization.

**Implementation**:
- Update all agent behavioral files to return metadata-only (200-300 tokens)
- Implement metadata extraction utilities in command-level verification
- Use forward message pattern (no re-summarization) when passing metadata
- Apply aggressive context pruning after each phase completion

**Success Metrics**:
- Context usage: <30% across entire 7-phase workflow
- Agent coordination scalability: 10+ agents per supervisor
- 100% workflow completion rate (no context overflows)

### 4. Implement Workflow Scope Detection for All Multi-Phase Commands

**Rationale**: Skip inappropriate phases based on workflow type, eliminating unnecessary work.

**Implementation**:
- Use workflow-detection.sh for scope detection from workflow description
- Map scope to phase execution list (research-only, research-and-plan, full-implementation, debug-only)
- Check before each phase using should_run_phase()
- Provide clear user feedback when skipping phases

**Success Metrics**:
- Appropriate phase execution (no planning for research-only workflows)
- Clear skip messages explaining reason
- Performance optimization (skip phases, not execute-then-discard)

### 5. Adopt Fail-Fast Error Handling with 5-Component Diagnostics

**Rationale**: Predictable behavior, easier debugging, faster feedback vs silent fallbacks.

**Implementation**:
- Remove all bootstrap fallback mechanisms
- Implement 5-component error messages (what failed, expected, diagnostic, context, action)
- Exit immediately on configuration errors
- Preserve file creation verification fallbacks

**Success Metrics**:
- 100% bootstrap reliability through fail-fast
- Zero silent failures
- Clear debugging guidance in all error messages

### 6. Implement Mandatory Verification Checkpoints for All File Creation

**Rationale**: 100% file creation reliability prevents cascading phase failures.

**Implementation**:
- Add MANDATORY VERIFICATION blocks after every agent invocation that creates files
- Verify file exists, has content (>500 bytes), has expected structure
- Implement fallback file creation when verification fails
- Test file creation reliability across 10 workflow executions

**Success Metrics**:
- File creation reliability: 100% (10/10 test runs)
- Zero cascading phase failures due to missing files
- Verification checkpoint execution visible in logs

## References

### Primary Command Files
- /home/benjamin/.config/.claude/commands/orchestrate.md (5,400+ lines)
- /home/benjamin/.config/.claude/commands/coordinate.md:187-244 (wave-based execution)
- /home/benjamin/.config/.claude/commands/coordinate.md:746-778 (Phase 0 optimization)
- /home/benjamin/.config/.claude/commands/supervise.md (2,300 lines)
- /home/benjamin/.config/.claude/commands/research.md

### Optimization Pattern Documentation
- /home/benjamin/.config/.claude/docs/concepts/patterns/parallel-execution.md:1-292
- /home/benjamin/.config/.claude/docs/concepts/patterns/metadata-extraction.md:1-393
- /home/benjamin/.config/.claude/docs/concepts/patterns/context-management.md
- /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md
- /home/benjamin/.config/.claude/docs/concepts/patterns/verification-fallback.md
- /home/benjamin/.config/.claude/docs/concepts/patterns/checkpoint-recovery.md

### Library Implementations
- /home/benjamin/.config/.claude/lib/unified-location-detection.sh:1-150
- /home/benjamin/.config/.claude/lib/workflow-detection.sh:1-100
- /home/benjamin/.config/.claude/lib/metadata-extraction.sh:13-87
- /home/benjamin/.config/.claude/lib/context-pruning.sh
- /home/benjamin/.config/.claude/lib/error-handling.sh
- /home/benjamin/.config/.claude/lib/checkpoint-utils.sh
- /home/benjamin/.config/.claude/lib/unified-logger.sh
- /home/benjamin/.config/.claude/lib/dependency-analyzer.sh

### Reference Documentation
- /home/benjamin/.config/.claude/docs/guides/orchestration-troubleshooting.md:1-833
- /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
- /home/benjamin/.config/CLAUDE.md (hierarchical_agent_architecture section)

### Specification Case Studies
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90%)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures (12 invocations fixed)
- Spec 057 (2025-10-27): /supervise robustness improvements (32 lines of bootstrap fallbacks removed)
- Spec 497 (2025-10-27): Unified orchestration improvements
- Spec 080: /orchestrate enhancement (wave-based implementation, Phase 0 optimization)

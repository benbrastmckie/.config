# Agent Consolidation Opportunities

## Research Status
Status: Complete
Created: 2025-10-26
Topic: Agent Consolidation Analysis

## Executive Summary

Analysis of 21 agents in .claude/agents/ reveals significant consolidation opportunities. Three high-priority consolidations identified: (1) merge expansion-specialist and collapse-specialist into unified "plan-structure-manager" (95% code overlap), (2) merge implementer-coordinator and implementation-executor (sequential workflow, shared context), (3) merge plan-expander into expansion-specialist (eliminate wrapper layer). Additionally, git-commit-helper can be refactored to utility library (no agent behavioral logic needed). Total potential reduction: 4 agents → 2-3 unified agents + 1 library.

## Findings

### Current Agent Inventory

**Total Agents**: 21 (down from 22 after location-specialist removal on 2025-10-26)

**Agent Categories by Tool Access**:
- Read-Only Analysts (7): code-reviewer, debug-specialist, debug-analyst, metrics-specialist, test-specialist, complexity-estimator, implementation-researcher
- Writers (8): code-writer, doc-writer, plan-architect, research-specialist, implementation-executor, expansion-specialist, spec-updater, research-synthesizer
- Coordinators (3): implementer-coordinator, plan-expander, github-specialist
- Utility Agents (2): git-commit-helper, doc-converter
- Specialized (1): collapse-specialist

### High-Priority Consolidation Opportunities

#### 1. Expansion-Specialist + Collapse-Specialist → Plan-Structure-Manager

**File References**:
- `/home/benjamin/.config/.claude/agents/expansion-specialist.md` (745 lines)
- `/home/benjamin/.config/.claude/agents/collapse-specialist.md` (661 lines)

**Analysis**:
- **Code Overlap**: 95% structural similarity
  - Both use identical STEP 1-5 workflow patterns (lines 66-360 in expansion-specialist, lines 66-305 in collapse-specialist)
  - Both invoke spec-updater for cross-reference verification (lines 263-292 expansion-specialist, lines 206-235 collapse-specialist)
  - Both create artifacts in `specs/artifacts/{plan_name}/` (lines 300-360 expansion-specialist, lines 244-304 collapse-specialist)
  - Both use identical checkpoint/verification patterns (STEP 1, STEP 1.5, STEP 3, STEP 4.5)
  - Both manage Structure Level metadata transitions (lines 543-566 expansion-specialist, lines 413-442 collapse-specialist)

- **Shared Tools**: Read, Write, Edit, Bash (expansion-specialist line 26-29, collapse-specialist line 26-29)

- **Shared Behavioral Logic**:
  - Progress tracking reminders injection (expansion-specialist lines 143-226, not in collapse-specialist but should be)
  - Metadata validation and updates
  - Artifact creation with identical sections
  - Hierarchical plan updates (phase → parent, stage → phase → parent)

**Consolidation Strategy**:
```markdown
# Plan Structure Manager Agent

## Operations
- expand_phase: Extract phase to separate file (Level 0 → 1)
- expand_stage: Extract stage to separate file (Level 1 → 2)
- collapse_phase: Merge phase back to parent (Level 1 → 0)
- collapse_stage: Merge stage back to phase (Level 2 → 1)

## Unified Workflow
STEP 1: Validate operation request (expand vs collapse)
STEP 2: Extract/merge content
STEP 3: Create/delete files
STEP 4: Update metadata (Structure Level, Expanded lists)
STEP 4.5: Verify cross-references (spec-updater)
STEP 5: Create artifact
```

**Benefits**:
- Reduce 2 agents → 1 agent (50% reduction)
- Eliminate code duplication (95% overlap removed)
- Unified artifact format for expansion/collapse operations
- Single source of truth for Structure Level transitions
- Easier maintenance (change once applies to both operations)

**Complexity Score**: 8/10 (high consolidation value, moderate refactoring effort)

---

#### 2. Implementer-Coordinator + Implementation-Executor → Unified Implementation Agent

**File References**:
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (479 lines)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` (596 lines)

**Analysis**:
- **Sequential Workflow**: Coordinator invokes executor(s), waits for completion, aggregates results
  - Coordinator lines 121-186: Parallel executor invocation pattern
  - Executor lines 50-346: Task execution, plan updates, git commits
  - No independent usage: coordinator always invokes executor

- **Shared Context**: Both operate on same plan hierarchy, artifact paths, topic structure
  - Coordinator input (lines 22-44): plan_path, topic_path, artifact_paths
  - Executor input (lines 30-48): phase_file_path, topic_path, artifact_paths (subset of coordinator input)

- **Tools**:
  - Coordinator: Read, Bash, Task (line 2)
  - Executor: Read, Write, Edit, Bash, TodoWrite (line 2)
  - Unified agent would use union: Read, Write, Edit, Bash, TodoWrite, Task

**Consolidation Strategy**:
```markdown
# Implementation Manager Agent

## Modes
- coordinator_mode: Parse plan structure, analyze dependencies, orchestrate waves
- executor_mode: Execute single phase/stage tasks, update hierarchy, create commits

## Workflow
STEP 1 (Coordinator): Detect plan structure (Level 0/1/2)
STEP 2 (Coordinator): Analyze dependencies, build wave structure
STEP 3 (Coordinator): For each wave, invoke executor_mode for each phase
STEP 4 (Executor): Execute tasks, update plans, create commits
STEP 5 (Coordinator): Aggregate results, generate implementation report

## Context Benefits
- Shared plan parsing logic (no duplication)
- Direct access to executor context (no Task tool overhead)
- Single checkpoint management system
- Unified progress reporting
```

**Benefits**:
- Reduce 2 agents → 1 agent (50% reduction)
- Eliminate Task tool overhead for executor invocation
- Shared context reduces token usage (no passing artifact_paths between agents)
- Single checkpoint/state management system
- Easier error propagation (coordinator sees executor errors directly)

**Complexity Score**: 7/10 (moderate consolidation value, requires mode switching logic)

**Trade-offs**:
- Loses parallelism benefit of separate executor instances
- Single agent context window includes both coordinator and executor logic
- May need to preserve Task tool pattern if multiple phases execute truly in parallel

**Recommendation**: Defer consolidation until parallel execution patterns are validated. If parallelism proves essential, keep separate. If sequential execution dominates, merge.

---

#### 3. Plan-Expander → Expansion-Specialist (Eliminate Wrapper)

**File References**:
- `/home/benjamin/.config/.claude/agents/plan-expander.md` (562 lines)
- `/home/benjamin/.config/.claude/agents/expansion-specialist.md` (745 lines)

**Analysis**:
- **Wrapper Pattern**: plan-expander is pure coordination wrapper
  - Lines 100-126: Invokes /expand command via SlashCommand tool
  - Lines 130-198: Validates expansion results
  - Lines 221-322: Generates JSON validation output
  - NO actual expansion logic (all in expansion-specialist or /expand command)

- **Redundancy**: Same validation logic exists in expansion-specialist
  - plan-expander lines 136-198: Verify file creation, parent plan updates, metadata
  - expansion-specialist lines 66-137 (STEP 1): Same validation checks

- **Output Format**: JSON validation output only used by /orchestrate
  - plan-expander lines 254-279: JSON structure
  - Orchestrator could invoke expansion-specialist directly and parse markdown artifact

**Consolidation Strategy**:
```markdown
# Expansion-Specialist Enhancement

Add JSON output mode for orchestrator integration:

## Output Modes
- artifact_mode (default): Return artifact path + operation summary
- json_mode: Return JSON validation for orchestrator

## JSON Output (when mode=json)
{
  "phase_num": N,
  "expansion_status": "success|error|skipped",
  "expanded_file_path": "/path",
  "validation": {
    "file_exists": true,
    "parent_plan_updated": true,
    "metadata_correct": true,
    "spec_updater_checklist_preserved": true
  }
}
```

**Benefits**:
- Eliminate 1 agent (plan-expander wrapper)
- Reduce code duplication (validation logic consolidated)
- Orchestrator invokes expansion-specialist directly
- Single source of truth for expansion operations

**Complexity Score**: 5/10 (low complexity, high value - simple wrapper elimination)

---

#### 4. Git-Commit-Helper → Utility Library (Not an Agent)

**File References**:
- `/home/benjamin/.config/.claude/agents/git-commit-helper.md` (100 lines)

**Analysis**:
- **No Behavioral Logic**: Purely deterministic commit message generation
  - Lines 20-47: Template-based message formatting
  - Lines 49-63: Standards compliance rules
  - No codebase analysis, no decision-making, no context needed

- **Better Fit**: Shell utility library
  - Current: Agent invocation overhead (Task tool, context passing)
  - Proposed: Direct function call via `.claude/lib/git-commit-utils.sh`
  - Implementation-executor already sources git-utils.sh (line 199)

**Consolidation Strategy**:
```bash
# .claude/lib/git-commit-utils.sh

generate_commit_message() {
  local topic_num="$1"
  local completion_type="$2"  # phase|stage|plan
  local phase_num="$3"
  local stage_num="$4"
  local name="$5"
  local feature_name="$6"

  case "$completion_type" in
    stage)
      echo "feat(${topic_num}): complete Phase ${phase_num} Stage ${stage_num} - ${name}"
      ;;
    phase)
      echo "feat(${topic_num}): complete Phase ${phase_num} - ${name}"
      ;;
    plan)
      echo "feat(${topic_num}): complete ${feature_name}"
      ;;
  esac
}
```

**Benefits**:
- Eliminate 1 agent (git-commit-helper)
- Zero agent invocation overhead
- Direct function call (faster, simpler)
- Easier testing (bash unit tests)
- Already integrated in implementation-executor (line 199: `source git-utils.sh`)

**Complexity Score**: 3/10 (trivial refactoring, clear benefit)

**Implementation**: Move to `.claude/lib/git-commit-utils.sh`, update implementation-executor to source it

---

### Medium-Priority Consolidation Opportunities

#### 5. Debug-Specialist + Debug-Analyst (Functional Overlap)

**File References**:
- `/home/benjamin/.config/.claude/agents/debug-specialist.md` (unknown - not read in this analysis)
- `/home/benjamin/.config/.claude/agents/debug-analyst.md` (unknown - not read in this analysis)

**Analysis from README**:
- debug-specialist (line 138): "Investigate and diagnose issues without making changes"
- debug-analyst (from agent list): Similar investigation capabilities
- Both have same tools: Read, Grep, Glob, Bash, Write

**Preliminary Assessment**: High likelihood of consolidation opportunity. Both perform root cause analysis and create debug reports. Requires detailed file analysis to confirm overlap percentage.

**Recommendation**: Follow-up analysis to determine if these can be merged into single "debug-investigator" agent

---

#### 6. Implementation-Researcher + Research-Specialist (Scope Overlap)

**File References**:
- `/home/benjamin/.config/.claude/agents/implementation-researcher.md` (372 lines)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (unknown - not read in this analysis)

**Analysis**:
- implementation-researcher: Analyzes codebase before implementation phases (lines 1-372)
  - Tools: Read, Grep, Glob, Bash (line 2)
  - Creates artifacts in `specs/{topic}/artifacts/phase_{N}_exploration.md` (line 148)
  - Returns 50-word metadata summary (line 211-224)

- research-specialist (from README line 260): "Conduct research and generate comprehensive reports"
  - Tools: Read, Write, Grep, Glob, WebSearch (README line 372)
  - Creates reports in `specs/reports/{topic}/` (README line 268)

**Key Difference**: WebSearch capability (research-specialist has it, implementation-researcher doesn't)

**Preliminary Assessment**: Moderate consolidation opportunity. Could create unified "researcher" agent with modes:
- codebase_mode: Internal codebase analysis (no WebSearch)
- external_mode: Technology/best practices research (with WebSearch)

**Complexity Score**: 6/10 (moderate complexity due to different output locations and tool sets)

**Recommendation**: Consider consolidation if implementation-researcher use cases expand to need external research

---

### Low-Priority Consolidation Opportunities

#### 7. Code-Reviewer + Code-Writer (Sequential Workflow)

**Analysis**:
- code-reviewer (README line 100): Read-only analysis, standards compliance checking
- code-writer (README line 119): Write code, implement features, refactoring

**Trade-off**: Separation maintains clear read-only vs. write boundaries. Consolidation would create large agent with mixed concerns.

**Recommendation**: Keep separate. Read-only vs. write separation is architecturally valuable.

---

#### 8. Research-Synthesizer (Single-Purpose Agent)

**File Reference**:
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (259 lines)

**Analysis**:
- Single purpose: Synthesize multiple research reports into overview (lines 1-259)
- Tools: Read, Write (line 2)
- Called by: /orchestrate Research Phase (line 257)
- Only used after parallel research-specialist agents complete

**Preliminary Assessment**: No clear consolidation target. Specialized synthesis logic not duplicated elsewhere.

**Recommendation**: Keep as standalone. Synthesis workflow is unique and well-scoped.

---

## Consolidation Strategies

### Strategy 1: Merge Similar Operations (Expansion/Collapse)

**Target**: expansion-specialist + collapse-specialist → plan-structure-manager

**Approach**:
1. Create unified agent with operation parameter (expand/collapse)
2. Extract shared workflow steps to common functions
3. Operation-specific logic in conditional branches
4. Single artifact format for both operations

**File Structure**:
```
plan-structure-manager.md (900 lines, vs 1406 lines combined)
├─ Shared: Validation, spec-updater invocation, artifact creation
├─ Expand-specific: Content extraction, file creation, progress injection
└─ Collapse-specific: Content merge, file deletion, child validation
```

**Savings**: 506 lines (36% reduction)

---

### Strategy 2: Sequential Workflow Consolidation (Coordinator + Executor)

**Target**: implementer-coordinator + implementation-executor → implementation-manager

**Approach**:
1. Preserve parallel execution capability via Task tool for true parallelism
2. Direct function calls for sequential phases (no Task overhead)
3. Unified state management and checkpoint system
4. Mode switching based on operation type

**Complexity**: Moderate (requires careful mode separation)

**Trade-off**: May lose context isolation between parallel executors

**Recommendation**: Defer until parallel execution patterns validated in production

---

### Strategy 3: Wrapper Elimination (Plan-Expander)

**Target**: plan-expander → expansion-specialist (direct invocation)

**Approach**:
1. Add JSON output mode to expansion-specialist
2. Orchestrator invokes expansion-specialist directly
3. Parse markdown artifact OR JSON validation (based on mode)
4. Delete plan-expander agent

**Savings**: 562 lines, 1 agent eliminated

**Complexity**: Low (simple mode addition)

---

### Strategy 4: Agent-to-Library Refactoring (Git-Commit-Helper)

**Target**: git-commit-helper → .claude/lib/git-commit-utils.sh

**Approach**:
1. Extract commit message templates to shell function
2. Move to `.claude/lib/git-commit-utils.sh`
3. Update implementation-executor to source library
4. Delete git-commit-helper agent

**Savings**: 100 lines agent code, agent invocation overhead eliminated

**Complexity**: Trivial

---

## Recommendations

### Immediate Actions (High Priority)

1. **Consolidate expansion-specialist + collapse-specialist**
   - **Timeline**: 1-2 days
   - **Complexity**: 8/10
   - **Impact**: 36% code reduction, single source of truth for Structure Level operations
   - **File**: Create `/home/benjamin/.config/.claude/agents/plan-structure-manager.md`
   - **Testing**: Verify expansion and collapse operations still work via /expand and /collapse commands

2. **Eliminate plan-expander wrapper**
   - **Timeline**: 4 hours
   - **Complexity**: 5/10
   - **Impact**: 1 agent eliminated, reduced orchestrator coupling
   - **Change**: Add JSON output mode to expansion-specialist
   - **Testing**: Verify /orchestrate complexity evaluation phase still works

3. **Refactor git-commit-helper to library**
   - **Timeline**: 2 hours
   - **Complexity**: 3/10
   - **Impact**: 1 agent eliminated, zero invocation overhead
   - **File**: Create `/home/benjamin/.config/.claude/lib/git-commit-utils.sh`
   - **Testing**: Verify implementation-executor commits still formatted correctly

**Total Immediate Impact**: 3 agents eliminated or consolidated (14% reduction in agent count)

---

### Medium-Term Actions (Follow-Up Analysis Required)

4. **Investigate debug-specialist + debug-analyst consolidation**
   - **Action**: Detailed file analysis to measure code overlap
   - **Decision Criteria**: If >70% overlap, consolidate; else keep separate
   - **Timeline**: 1 day analysis, 1-2 days implementation if consolidation warranted

5. **Evaluate implementer-coordinator + implementation-executor merge**
   - **Action**: Production validation of parallel execution patterns
   - **Decision Criteria**: If sequential execution dominates (>80% of phases), consolidate
   - **Timeline**: 1 week monitoring, 2-3 days implementation if warranted
   - **Risk**: May lose parallelism benefits if consolidated prematurely

6. **Consider implementation-researcher + research-specialist unification**
   - **Action**: Analyze use case overlap and tool requirements
   - **Decision Criteria**: If implementation-researcher needs external research (WebSearch), merge
   - **Timeline**: 1 day analysis, 1-2 days implementation if warranted

---

### No Action Recommended

- **code-reviewer + code-writer**: Keep separate (read-only vs. write boundary valuable)
- **research-synthesizer**: Keep standalone (unique synthesis logic, no duplication)
- **doc-writer + doc-converter**: Different purposes (creation vs. conversion)
- **complexity-estimator**: Standalone (unique LLM-based scoring, no overlap)

---

## Related Reports

- [Research Overview](./OVERVIEW.md) - Complete agent directory review with consolidated recommendations

## References

### Agents Analyzed (File Paths)
- `/home/benjamin/.config/.claude/agents/README.md` (656 lines)
- `/home/benjamin/.config/.claude/agents/expansion-specialist.md` (745 lines)
- `/home/benjamin/.config/.claude/agents/collapse-specialist.md` (661 lines)
- `/home/benjamin/.config/.claude/agents/plan-expander.md` (562 lines)
- `/home/benjamin/.config/.claude/agents/complexity-estimator.md` (426 lines)
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` (479 lines)
- `/home/benjamin/.config/.claude/agents/implementation-executor.md` (596 lines)
- `/home/benjamin/.config/.claude/agents/implementation-researcher.md` (372 lines)
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (259 lines)
- `/home/benjamin/.config/.claude/agents/spec-updater.md` (first 150 lines analyzed)
- `/home/benjamin/.config/.claude/agents/git-commit-helper.md` (100 lines)

### Tool Access Patterns (from grep analysis)
- Read-only agents: 7 agents (code-reviewer, debug-specialist, debug-analyst, metrics-specialist, test-specialist, complexity-estimator, implementation-researcher)
- Writing agents: 8 agents (code-writer, doc-writer, plan-architect, research-specialist, implementation-executor, expansion-specialist, spec-updater, research-synthesizer)
- Coordinators: 3 agents (implementer-coordinator, plan-expander, github-specialist)
- Utility agents: 2 agents (git-commit-helper, doc-converter)

### Context
- Agent cleanup completed: 2025-10-26 (location-specialist archived)
- Current agent count: 21 (down from 22)
- Directory: `/home/benjamin/.config/.claude/agents/`
- Analysis date: 2025-10-26

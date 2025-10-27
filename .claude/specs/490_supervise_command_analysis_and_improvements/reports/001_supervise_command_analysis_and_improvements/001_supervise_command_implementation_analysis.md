# /supervise Command Implementation Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: supervise_command_implementation_analysis
- **Report Type**: codebase analysis
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The `/supervise` command currently implements a 7-phase multi-agent workflow orchestration system (Phase 0-6) that coordinates research, planning, implementation, testing, debugging, and documentation. The user's TODO.md indicates a desire to add "wave-based implementation" following the patterns from `/orchestrate`. Analysis reveals that `/supervise` uses sequential implementation in Phase 3, while `/orchestrate` achieves 40-60% time savings through parallel wave-based execution using dependency graphs. The current implementation is architecturally sound but lacks the parallel execution capability that exists in `/orchestrate`.

## Findings

### Current /supervise Implementation Structure

**File**: `/home/benjamin/.config/.claude/commands/supervise.md` (2177 lines)

#### Architecture Overview (Lines 5-110)

The command defines itself as a **WORKFLOW ORCHESTRATOR** with explicit responsibilities:
- Pre-calculate ALL artifact paths before agent invocations (Phase 0)
- Determine workflow scope (4 types: research-only, research-and-plan, full-implementation, debug-only)
- Invoke specialized agents via Task tool with behavioral injection
- Verify agent outputs at mandatory checkpoints
- Extract and aggregate metadata from results
- Report final workflow status

**Critical Prohibition** (Lines 42-109): The command explicitly prohibits invoking other commands via SlashCommand tool, mandating direct agent invocation via Task tool for lean context and behavioral control.

#### Workflow Phases (Lines 111-131)

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents) ← ALREADY PARALLEL
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Implementation (conditional) ← CURRENTLY SEQUENTIAL
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

**Key Observation**: Phase 1 (Research) already implements parallel execution (2-4 agents invoked simultaneously), but Phase 3 (Implementation) is sequential.

#### Phase 3 Implementation (Lines 1404-1527)

**Current Approach** (Lines 1430-1450):
- Single Task invocation to code-writer agent
- Agent reads plan file and executes phases sequentially
- Returns `IMPLEMENTATION_STATUS`, `PHASES_COMPLETED`, `PHASES_TOTAL`
- No wave-based execution, no parallel phase processing

**Code-Writer Agent Invocation Template** (Lines 1431-1451):
```yaml
Task {
  description: "Execute implementation plan with mandatory artifact creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/code-writer.md

    **Workflow-Specific Context**:
    - Plan File Path: ${PLAN_PATH}
    - Implementation Artifacts Directory: ${IMPL_ARTIFACTS}
    - Project Standards: ${STANDARDS_FILE}

    Execute implementation following all guidelines in behavioral file.
    Return: IMPLEMENTATION_STATUS, PHASES_COMPLETED, PHASES_TOTAL
  "
}
```

**Problem**: The code-writer agent processes the plan sequentially, phase-by-phase. No dependency analysis, no wave calculation, no parallel execution.

### /orchestrate Wave-Based Implementation Pattern

**Evidence from TODO.md** (Lines 1-143):

The user's TODO explicitly references wave-based implementation from `/orchestrate`:
- "research the /orchestrate command and best practices online"
- "integrate wave-based implementation into /supervise"
- Research summary mentions "40-60% time savings through parallel phase execution"

#### Key Components Identified in TODO

**Agents**:
1. `implementer-coordinator.md` - Orchestrates waves and invokes implementation-executor agents in parallel
2. `implementation-executor.md` - Executes single phase/stage with task completion and git commits

**Libraries**:
1. `dependency-analyzer.sh` - Parses phase dependencies, builds dependency graphs, identifies execution waves
2. `checkpoint-utils.sh` - Saves/restores wave execution state (already used by /supervise)
3. `unified-logger.sh` - Progress tracking across waves (already used by /supervise)

**Phase Dependency Syntax** (from TODO lines 94-97):
```markdown
### Phase N: Phase Name
**Dependencies**: [] or [1, 2, 3]
**Complexity**: Low|Medium|High
```

**Wave Execution Pattern** (from TODO lines 99-103):
- Wave 1: All phases with no dependencies (in-degree = 0)
- Wave 2: Phases that depend only on Wave 1
- Wave N: Phases whose dependencies are all satisfied
- **Critical**: All phases in a wave execute in parallel using multiple Task tool invocations in a single message

#### Performance Metrics

From TODO (lines 134-138):
- **Time Savings**: 40-60% reduction in implementation time
- **Scalability**: Handle complex plans with 5-15 phases efficiently
- **Consistency**: Identical pattern to /orchestrate (proven in production)
- **Maintainability**: Reuse tested libraries and agents

### Gap Analysis: What /supervise Lacks

#### 1. Dependency Analysis (MISSING)

**Required**: Parse plan file to extract phase dependencies
**Current State**: No dependency parsing in Phase 3 implementation
**Needed Components**:
- Integration with `dependency-analyzer.sh` library
- Parsing of `**Dependencies**: [...]` fields from plan phases
- DAG validation (detect circular dependencies)

#### 2. Wave Calculation (MISSING)

**Required**: Use topological sort (Kahn's algorithm) to group phases into waves
**Current State**: No wave calculation logic
**Needed Components**:
- Call to `calculate_execution_waves()` from dependency-analyzer.sh
- Wave boundary identification
- Execution order determination

#### 3. Parallel Phase Invocation (MISSING)

**Required**: Invoke multiple implementation-executor agents in parallel (one per phase in each wave)
**Current State**: Single code-writer agent processes all phases sequentially
**Needed Components**:
- Replace single code-writer invocation with wave-based loop
- Invoke N implementation-executor agents per wave (parallel Task calls in single message)
- Wait for wave completion before starting next wave

#### 4. Wave-Level Checkpointing (PARTIAL)

**Required**: Save checkpoints at wave boundaries for resume capability
**Current State**: Checkpoints saved after each phase (Phase 1-4), not at wave boundaries
**Needed Components**:
- Modify checkpoint schema to include wave number
- Save checkpoint after each wave completes
- Resume logic to restore from wave boundary

#### 5. Implementer-Coordinator Agent (NOT USED)

**Required**: Delegate wave orchestration to specialized agent
**Current State**: /supervise directly invokes code-writer (not implementer-coordinator)
**Needed Components**:
- Invoke implementer-coordinator agent in Phase 3 instead of code-writer
- Pass plan path and wave configuration to coordinator
- Coordinator handles wave calculation and parallel executor invocation

### Architectural Comparison

| Aspect | /supervise (Current) | /orchestrate (Wave-Based) |
|--------|---------------------|---------------------------|
| **Phase 3 Execution** | Sequential (code-writer) | Parallel (implementer-coordinator → N executors) |
| **Dependency Analysis** | None | dependency-analyzer.sh (Kahn's algorithm) |
| **Wave Calculation** | N/A | Topological sort, level-based grouping |
| **Parallel Invocation** | No (single agent) | Yes (multiple Task calls per wave) |
| **Time Complexity** | O(N) phases sequential | O(max_wave_depth) with parallel phases |
| **Performance** | Baseline | 40-60% time savings |
| **Scalability** | Limited by sequential execution | Handles 5-15 phases efficiently |

### Standards Compliance Review

The TODO mentions conformance to `.claude/docs/` standards:

#### 1. Parallel Execution Pattern
**Location**: `.claude/docs/concepts/patterns/parallel-execution.md` (referenced in TODO)
**Requirement**: 40-60% time savings target, wave-based execution
**Current Compliance**: ❌ Phase 3 does not implement parallel execution

#### 2. Phase Dependencies Guide
**Location**: `.claude/docs/reference/phase_dependencies.md` (referenced in TODO)
**Requirement**: Dependency syntax (`**Dependencies**: [...]`), validation, wave calculation
**Current Compliance**: ❌ No dependency parsing in Phase 3

#### 3. Behavioral Injection Pattern
**Location**: `.claude/docs/concepts/patterns/behavioral-injection.md`
**Requirement**: Task tool with agent behavioral files, NOT SlashCommand
**Current Compliance**: ✅ /supervise already uses Task tool correctly

#### 4. Checkpoint Recovery Pattern
**Location**: `.claude/docs/concepts/patterns/checkpoint-recovery.md`
**Requirement**: Resume from phase/wave boundaries
**Current Compliance**: ⚠️ Partial - checkpoints exist but not at wave boundaries

### Integration Complexity Assessment

#### Low Complexity Changes (Reuse Existing Infrastructure)

1. **Library Integration** (Lines 299-306 already source libraries):
   - `dependency-analyzer.sh` is already available (sourced by /orchestrate)
   - `checkpoint-utils.sh` already sourced (line 285-290)
   - `unified-logger.sh` already sourced (line 292-298)
   - No new libraries needed, just add dependency-analyzer.sh sourcing

2. **Agent Availability**:
   - `implementer-coordinator.md` already exists (used by /orchestrate)
   - `implementation-executor.md` already exists (used by /orchestrate)
   - No new agent behavioral files needed

#### Medium Complexity Changes (Modify Phase 3)

1. **Replace Sequential Invocation** (Lines 1430-1451):
   - Remove single code-writer Task invocation
   - Add wave-based loop with implementer-coordinator invocation
   - Update verification logic to check wave completion (not single agent)

2. **Add Dependency Parsing** (New logic in Phase 3):
   - Read plan file to extract phase dependencies
   - Call `parse_phase_dependencies()` from dependency-analyzer.sh
   - Validate DAG (no circular dependencies)

3. **Wave Calculation** (New logic in Phase 3):
   - Call `calculate_execution_waves()` from dependency-analyzer.sh
   - Store wave assignments for progress tracking
   - Emit progress markers per wave (not per phase)

#### High Complexity Changes (New Behavior)

1. **Checkpoint Schema Modification**:
   - Add `current_wave` field to checkpoint JSON
   - Modify `save_phase_checkpoint()` calls to include wave number
   - Update resume logic to restore from wave boundary

2. **Error Handling for Wave Failures**:
   - Partial wave failure handling (≥50% success threshold)
   - Continue with independent phases if some fail
   - Mark failed phases for retry or manual intervention

### What the Command Currently Does

From file analysis (Lines 111-2177):

**Phase 0** (Lines 556-896): ✅ Working correctly
- Uses `unified-location-detection.sh` for deterministic path calculation
- Pre-calculates ALL artifact paths (research reports, plan, implementation, debug, summary)
- Creates topic directory structure (lazy subdirectory creation)

**Phase 1** (Lines 897-1169): ✅ Parallel execution already implemented
- Invokes 2-4 research-specialist agents in parallel (Lines 948-987)
- Verification with auto-recovery (single retry for transient failures)
- Partial failure handling (≥50% success threshold)

**Phase 2** (Lines 1171-1402): ✅ Working correctly
- Invokes plan-architect agent via Task tool (NOT /plan command)
- Verification with auto-recovery
- Extracts plan metadata (complexity, phases, estimated time)

**Phase 3** (Lines 1404-1527): ❌ SEQUENTIAL IMPLEMENTATION (TARGET FOR WAVE-BASED UPGRADE)
- Single code-writer agent processes entire plan
- No dependency analysis
- No parallel execution
- Returns completion status after all phases done sequentially

**Phase 4** (Lines 1529-1635): ✅ Working correctly
- Invokes test-specialist agent
- Determines if Phase 5 (Debug) needed based on test results

**Phase 5** (Lines 1637-1961): ✅ Working correctly
- Conditional execution (only if tests fail)
- Debug iteration loop (max 3 iterations)
- Invokes debug-analyst + code-writer + test-specialist per iteration

**Phase 6** (Lines 1963-2053): ✅ Working correctly
- Conditional execution (only if implementation occurred)
- Invokes doc-writer agent to create summary
- Links all artifacts (research, plan, implementation, tests)

### What the Command Should Do (Wave-Based Implementation)

Based on TODO research summary (Lines 118-139):

**Phase 3 Modification** (Only phase that needs changes):

1. **Pre-Execution: Dependency Analysis**
   - Read plan file at `$PLAN_PATH`
   - Extract `**Dependencies**: [...]` field from each phase
   - Build dependency graph using `build_dependency_graph()`
   - Validate no circular dependencies with `validate_dag()`

2. **Wave Calculation**
   - Call `calculate_execution_waves()` from dependency-analyzer.sh
   - Group phases by execution wave (Wave 1, Wave 2, ..., Wave N)
   - Determine parallel execution groups

3. **Wave-Based Execution Loop**
   ```bash
   for wave_num in 1 2 3 ... N; do
     # Identify phases in current wave
     WAVE_PHASES=(phases with all dependencies satisfied)

     # Invoke implementer-coordinator agent
     Task {
       description: "Coordinate Wave $wave_num implementation"
       prompt: "
         Read: .claude/agents/implementer-coordinator.md

         Context:
         - Plan Path: $PLAN_PATH
         - Wave Number: $wave_num
         - Phases in Wave: ${WAVE_PHASES[@]}
         - Artifacts Directory: $IMPL_ARTIFACTS

         Execute wave $wave_num following behavioral guidelines.
         Return: WAVE_STATUS, PHASES_COMPLETED, PHASES_FAILED
       "
     }

     # Verify wave completion
     # Update checkpoint with wave progress
     # Continue to next wave
   done
   ```

4. **Progress Tracking**
   - Emit `PROGRESS: [Wave N/M] - Executing K phases in parallel`
   - Update checkpoint after each wave completes
   - Track individual phase completion within waves

5. **Verification and Recovery**
   - Verify all phases in wave completed successfully
   - Apply auto-recovery for transient failures (single retry)
   - Partial wave failure handling (≥50% success threshold)
   - Mark failed phases for retry or manual intervention

### Key Differences (Current vs Should)

| Aspect | Current (Sequential) | Should (Wave-Based) |
|--------|---------------------|---------------------|
| **Agent Invoked** | code-writer (single) | implementer-coordinator (per wave) |
| **Execution Pattern** | Phase 1 → Phase 2 → ... → Phase N | Wave 1 (phases 1,3,5 parallel) → Wave 2 (phases 2,4 parallel) → ... |
| **Dependency Awareness** | None | Full DAG analysis and validation |
| **Parallelization** | No | Yes (multiple Task calls per wave) |
| **Time Complexity** | O(N) sequential | O(W) where W = max wave depth |
| **Performance** | Baseline | 40-60% faster |
| **Checkpoint Granularity** | After all implementation | After each wave completes |

## Recommendations

### 1. Integrate dependency-analyzer.sh Library

**Action**: Add library sourcing in Phase 0 (after line 306)
**Code**:
```bash
# Source dependency analysis utilities (wave-based implementation)
if [ -f "$SCRIPT_DIR/../lib/dependency-analyzer.sh" ]; then
  source "$SCRIPT_DIR/../lib/dependency-analyzer.sh"
else
  echo "ERROR: dependency-analyzer.sh not found"
  exit 1
fi
```

**Rationale**: Reuse tested library from /orchestrate (no duplication)

### 2. Modify Phase 3 to Use Wave-Based Execution

**Action**: Replace code-writer invocation (lines 1430-1451) with wave-based loop
**Changes Required**:
- Add dependency parsing before wave loop
- Call `calculate_execution_waves()` to determine wave structure
- Iterate through waves, invoking implementer-coordinator per wave
- Update verification to check wave completion (not single agent)

**Expected Impact**: 40-60% time savings in Phase 3 execution

### 3. Update Checkpoint Schema for Wave Tracking

**Action**: Modify checkpoint JSON to include wave information
**Schema Addition**:
```json
{
  "current_phase": 3,
  "current_wave": 2,
  "waves_total": 4,
  "wave_phases_completed": [1, 3, 5],
  "wave_phases_failed": []
}
```

**Rationale**: Enable resume from wave boundary (not just phase boundary)

### 4. Add Wave-Level Progress Markers

**Action**: Emit progress markers at wave boundaries (not just phase boundaries)
**Example**:
```bash
emit_progress "3" "Wave 2/4 - Executing 3 phases in parallel"
```

**Rationale**: Provide visibility into parallel execution progress

### 5. Implement Partial Wave Failure Handling

**Action**: Add ≥50% success threshold logic for wave completion
**Behavior**:
- If ≥50% of wave phases succeed → continue to next wave
- If <50% succeed → terminate workflow with diagnostics
- Mark failed phases for retry or manual intervention

**Rationale**: Consistent with Phase 1 partial research failure handling

### 6. Maintain Behavioral Injection Pattern

**Action**: Ensure implementer-coordinator invocation uses Task tool (NOT SlashCommand)
**Validation**: Verify no `/implement` command invocations (violates architecture prohibition)
**Compliance**: Lines 42-109 explicitly prohibit SlashCommand usage

### 7. Testing and Validation

**Action**: Add test coverage for wave-based execution
**Test Cases**:
1. Plan with no dependencies (all phases in Wave 1 → fully parallel)
2. Plan with sequential dependencies (Wave 1 → Wave 2 → Wave 3 → sequential)
3. Plan with mixed dependencies (some parallel, some sequential)
4. Plan with circular dependencies (should fail validation)
5. Wave failure recovery (partial success ≥50%)

**Expected Coverage**: ≥80% for wave calculation and execution logic

## Related Reports

- **[OVERVIEW.md](./OVERVIEW.md)** - Synthesizes findings from all 4 research reports
- **[002_standards_violations_and_pattern_deviations.md](./002_standards_violations_and_pattern_deviations.md)** - Standards compliance analysis showing 95% adherence with 3 specific violations
- **[003_root_cause_of_subagent_delegation_failures.md](./003_root_cause_of_subagent_delegation_failures.md)** - Delegation failure investigation showing historical anti-pattern resolution
- **[004_corrective_actions_and_improvement_recommendations.md](./004_corrective_actions_and_improvement_recommendations.md)** - Implementation guidance and deprecation evaluation

## References

- `/home/benjamin/.config/.claude/commands/supervise.md` (Lines 1-2177) - Current implementation
- `/home/benjamin/.config/.claude/TODO.md` (Lines 1-143) - User requirements and research summary
- `.claude/lib/dependency-analyzer.sh` - Wave calculation library (referenced, not read)
- `.claude/agents/implementer-coordinator.md` - Wave orchestration agent (referenced, not read)
- `.claude/agents/implementation-executor.md` - Single phase executor (referenced, not read)
- `.claude/docs/concepts/patterns/parallel-execution.md` - Standards (referenced, not read)
- `.claude/docs/reference/phase_dependencies.md` - Dependency syntax (referenced, not read)

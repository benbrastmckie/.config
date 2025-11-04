# Current State of /supervise Command - Research Report

## Metadata
- **Date**: 2025-11-02
- **Agent**: research-specialist
- **Topic**: Current state of /supervise command - analyze structure, size, patterns, and areas for improvement
- **Report Type**: codebase analysis

## Executive Summary

The /supervise command is a 1,938-line multi-agent orchestration system positioned as a "minimal reference" command compared to /coordinate (1,930 lines). Analysis reveals that /supervise is architecturally identical to /coordinate in structure, patterns, and library integration, differing primarily in missing wave-based parallel execution (Phase 3) and having slightly more verbose error diagnostics. The "minimal character" positioning is not reflected in implementation - both commands share the same 7-phase workflow, library dependencies, agent invocation patterns, and verification checkpoints. Key opportunities include: (1) implementing wave-based execution from /coordinate, (2) consolidating verbose diagnostic templates into shared library, (3) clarifying architectural positioning beyond file size similarity.

## Findings

### 1. Overall Structure and Organization

**File Size and Complexity**:
- /supervise: 1,938 lines (coordinate.md:1938)
- /coordinate: 1,930 lines (coordinate.md:1930)
- Size difference: 8 lines (0.4% larger)
- **Finding**: The "minimal reference" characterization is not supported by file size - commands are virtually identical in length

**7-Phase Workflow Structure** (supervise.md:117-133):
```
Phase 0: Location and Path Pre-Calculation
Phase 1: Research (2-4 parallel agents)
Phase 2: Planning (conditional)
Phase 3: Implementation (conditional)
Phase 4: Testing (conditional)
Phase 5: Debug (conditional - only if tests fail)
Phase 6: Documentation (conditional - only if implementation occurred)
```

**Architectural Pattern** (supervise.md:26-30):
```
- Phase 0: Pre-calculate paths → Create topic directory structure
- Phase 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
- Completion: Report success + artifact locations
```

**Pattern Consistency**: /supervise follows identical orchestration pattern as /coordinate - both are "pure orchestrators" that delegate all work to specialized agents

### 2. Current Library Usage and Integration Patterns

**Required Libraries** (supervise.md:168-174):
```bash
- workflow-detection.sh - Workflow scope detection and phase execution control
- error-handling.sh - Error classification and recovery
- checkpoint-utils.sh - Workflow resume capability
- unified-logger.sh - Progress tracking
- unified-location-detection.sh - Project structure location detection
- metadata-extraction.sh - Artifact metadata extraction
- context-pruning.sh - Context management
```

**Library Sourcing Pattern** (supervise.md:207-238):
- Uses `library-sourcing.sh` for consolidated library loading
- Implements fail-fast: exits immediately if any library missing
- Verifies 5 critical functions after sourcing (supervise.md:275-330)
- **Quality**: Robust library integration with comprehensive validation

**Library Integration Quality**:
- Source pattern: Clean, consolidated via `source_required_libraries()`
- Function verification: Explicit checks for `detect_workflow_scope`, `should_run_phase`, `emit_progress`, `save_checkpoint`, `restore_checkpoint`
- Error reporting: Shows which library should provide missing functions (supervise.md:296-312)

**Comparison with /coordinate**:
- /coordinate uses identical library set PLUS `dependency-analyzer.sh` for wave execution (coordinate.md:329)
- Both commands share same sourcing pattern and validation approach
- **Finding**: Library integration is identical except for wave-based execution infrastructure

### 3. Error Handling and Verification Approaches

**Fail-Fast Philosophy** (supervise.md:138-149):
```
- Verification failures: Immediate error with 5-section diagnostic template
- File creation errors: Structured diagnostics (Expected/Found/Diagnostic/Commands/Causes)
- Partial research failure: Continue if ≥50% agents succeed
- No retry overhead: Errors detected and reported immediately
```

**Verification Checkpoint Count**:
- 14 `EXECUTE NOW` or `Task {` invocations (agent invocation points)
- 14 verification checkpoints with `verify_file_created`, `MANDATORY VERIFICATION`, or `VERIFICATION REQUIRED`
- 31 error handling instances with `fail-fast`, `ERROR`, or `DIAGNOSTIC` keywords
- **Quality**: Comprehensive verification at every file creation point

**5-Section Diagnostic Template** (supervise.md:692-730):
```
1. ERROR [Phase N, Operation]: What failed
2. Expected: File exists and has content
3. Found: File does not exist / File exists but is empty
4. DIAGNOSTIC INFORMATION:
   - Expected path
   - Directory status with file counts
   - Recent files listing
5. Diagnostic Commands:
   - Specific bash commands to investigate
6. Most Likely Causes:
   - Numbered list of failure reasons
```

**Error Message Verbosity**:
- /supervise: 38-line diagnostic template per verification failure (supervise.md:692-730)
- /coordinate: Uses `verify_file_created()` helper function with concise output (coordinate.md:771-810)
- **Finding**: /supervise has more verbose inline error messages vs /coordinate's function-based approach

**Partial Failure Handling** (supervise.md:159-162):
- Research phase allows ≥50% success threshold
- Uses `handle_partial_research_failure()` function (supervise.md:747)
- All other phases fail-fast on any verification failure
- **Consistency**: Same partial failure logic as /coordinate

### 4. Agent Invocation Patterns

**Agent Invocation Count**:
- 14 agent invocation points identified
- All invocations use imperative `**EXECUTE NOW**: USE the Task tool` pattern
- All follow behavioral injection pattern with `.claude/agents/*.md` references

**Invocation Template Structure** (supervise.md:625-642):
```
**EXECUTE NOW**: USE the Task tool for each research topic with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert workflow description for this topic]
    - Report Path: [insert absolute path from REPORT_PATHS array]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [insert exact absolute path]
```

**Agent Types Referenced**:
1. research-specialist.md - Phase 1 (supervise.md:630)
2. plan-architect.md - Phase 2 (supervise.md:953)
3. code-writer.md - Phase 3 (supervise.md:1169)
4. test-specialist.md - Phase 4 (supervise.md:1315)
5. debug-analyst.md - Phase 5 (supervise.md:1444)
6. doc-writer.md - Phase 6 (supervise.md:1814)

**Comparison with /coordinate**:
- /coordinate Phase 3 adds: `implementer-coordinator.md` and `implementation-executor.md` for wave orchestration (coordinate.md:1799-1800)
- /coordinate uses same 6 core agents plus 2 additional for wave execution
- **Finding**: Agent invocation patterns are architecturally identical except for wave-based implementation agents

**Standard 11 Compliance** (supervise.md:101-110):
```
✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```
- All invocations follow imperative pattern (not documentation-only YAML blocks)
- Direct Task tool usage (not SlashCommand chaining) - see architectural prohibition (supervise.md:42-109)
- **Quality**: 100% compliance with Standard 11 imperative agent invocation pattern

### 5. File Size and Complexity Comparison

**Line Count Breakdown**:
```
/supervise: 1,938 lines total
  - Phase 0: ~345 lines (lines 207-551)
  - Phase 1: ~283 lines (lines 565-847)
  - Phase 2: ~256 lines (lines 885-1140)
  - Phase 3: ~144 lines (lines 1142-1285)
  - Phase 4: ~117 lines (lines 1289-1405)
  - Phase 5: ~373 lines (lines 1407-1779)
  - Phase 6: ~119 lines (lines 1781-1899)
  - Utility functions: ~301 lines (lines 240-540)

/coordinate: 1,930 lines total
  - Phase 0: ~245 lines (lines 522-766)
  - Phase 1: ~270 lines (lines 815-1084)
  - Phase 2: ~131 lines (lines 1038-1168)
  - Phase 3: ~184 lines (lines 1216-1399) [includes wave execution]
  - Phase 4: ~107 lines (lines 1404-1510)
  - Phase 5: ~183 lines (lines 1513-1695)
  - Phase 6: ~83 lines (lines 1689-1771)
  - Utility functions: ~65 lines (lines 747-811) [verify_file_created helper]
```

**Key Size Differences**:
1. **Phase 0**: /supervise 100 lines longer (more verbose library sourcing diagnostics)
2. **Phase 3**: /coordinate 40 lines longer (wave-based execution logic)
3. **Phase 5**: /supervise 190 lines longer (verbose debug iteration diagnostics)
4. **Utility functions**: /supervise 236 lines longer (inline function definitions vs library-based)

**Complexity Metrics**:
- Agent invocation points: Both have 14 invocations (supervise adds 2 for debug iterations)
- Verification checkpoints: Both have 14 mandatory checkpoints
- Library dependencies: /supervise has 7, /coordinate has 8 (adds dependency-analyzer.sh)
- **Finding**: Complexity is equivalent - size difference is verbose diagnostics, not architectural complexity

### 6. Areas Where /supervise Could Benefit from /coordinate's Improvements

**Missing Wave-Based Execution** (Critical Gap):
- /coordinate Phase 3 implements wave-based parallel execution achieving 40-60% time savings (coordinate.md:186-243)
- Uses `dependency-analyzer.sh` library for dependency graph analysis and Kahn's algorithm
- /supervise Phase 3 has sequential implementation only (supervise.md:1142-1285)
- **Impact**: /supervise workflows take 40-60% longer for multi-phase implementations

**Wave Execution Pattern from /coordinate** (coordinate.md:1237-1282):
```bash
# Analyze plan dependencies and calculate waves
DEPENDENCY_ANALYSIS=$(analyze_dependencies "$PLAN_PATH")
WAVES=$(echo "$DEPENDENCY_ANALYSIS" | jq '.waves')
WAVE_COUNT=$(echo "$WAVES" | jq 'length')

# Display wave structure
for ((wave_num=1; wave_num<=WAVE_COUNT; wave_num++)); do
  WAVE=$(echo "$WAVES" | jq ".[$((wave_num-1))]")
  WAVE_PHASES=$(echo "$WAVE" | jq -r '.phases[]')
  PHASE_COUNT=$(echo "$WAVE" | jq '.phases | length')
  CAN_PARALLEL=$(echo "$WAVE" | jq -r '.can_parallel')

  echo "  Wave $wave_num: $PHASE_COUNT phase(s) [$([ "$CAN_PARALLEL" == "true" ] && echo "PARALLEL" || echo "SEQUENTIAL")]"
done
```

**Verbose Error Diagnostics vs Helper Functions**:
- /supervise uses inline 38-line diagnostic templates repeated 6+ times
- /coordinate uses `verify_file_created()` helper function (coordinate.md:771-810)
- **Improvement**: Extract diagnostic template to shared library function
- **Benefit**: Reduce command size by ~200 lines, improve maintainability

**Example Helper Function from /coordinate** (coordinate.md:771-810):
```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # Success - single character
    return 0
  else
    # Failure - verbose diagnostic
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    # ... comprehensive diagnostics ...
    return 1
  fi
}
```

**Benefits of Helper Function Approach**:
- Single source of truth for diagnostic format
- Concise verification calls: `verify_file_created "$PATH" "Research report" "Phase 1"`
- Easy to update diagnostic template project-wide
- **Reduction**: ~200 lines if applied to /supervise

**Context Pruning Implementation**:
- Both commands claim "80-90% context reduction via metadata extraction"
- /supervise has inline comments but no actual pruning calls (supervise.md:343-345)
- /coordinate has explicit `apply_pruning_policy()` calls after Phases 2, 3, 5 (coordinate.md:1180, 1393, 1676)
- **Finding**: /supervise metadata extraction claims not fully implemented

**Progress Marker Consistency**:
- /coordinate uses consistent format: `emit_progress "N" "Phase N complete - action"` (coordinate.md:605, 836, 1035, 1401)
- /supervise has mixed progress marker patterns and less consistent dual-mode reporting
- **Improvement**: Standardize progress markers to match /coordinate's consistent pattern

### 7. Features That Should Remain Unique to /supervise (Minimal Character)

**Current "Minimal" Positioning** (CLAUDE.md context):
```
- /coordinate - Production-Ready - Wave-based parallel execution (2,500-3,000 lines, recommended default)
- /orchestrate - In Development - Full-featured with PR automation (5,438 lines, experimental)
- /supervise - In Development - Sequential orchestration (1,939 lines, minimal reference being stabilized)
```

**Analysis of "Minimal Character"**:
1. **File Size**: 1,938 lines vs 1,930 lines for /coordinate (0.4% difference) - NOT minimal
2. **Feature Set**: Same 7-phase workflow, same agents, same verification - NOT minimal
3. **Library Dependencies**: 7 libraries vs 8 for /coordinate - marginally simpler
4. **Architecture**: Identical orchestration pattern, behavioral injection, fail-fast - NOT simpler

**What Could Make /supervise Truly Minimal**:

**Option 1: Single-Phase Workflows Only**
- Remove Phases 3-6 (implementation, testing, debug, documentation)
- Focus exclusively on research and planning (Phases 0-2)
- Target: 800-1,000 lines (50% reduction)
- **Use Case**: Quick research-and-plan workflows without implementation

**Option 2: Sequential-Only Implementation**
- Keep all 7 phases but enforce sequential execution
- Remove all parallelization logic (even research parallelization)
- Target: 1,200-1,400 lines (30% reduction)
- **Use Case**: Simple, predictable, easy-to-debug workflows

**Option 3: Reduced Verification**
- Single verification checkpoint per phase instead of per-file
- Trust agents to create files, verify only at phase boundaries
- Target: 1,400-1,600 lines (20% reduction)
- **Use Case**: Rapid prototyping with less strict enforcement

**Option 4: Library-Only Approach**
- All logic moved to libraries, command is just invocation sequence
- Minimal inline documentation, reference external docs
- Target: 600-800 lines (60% reduction)
- **Use Case**: Maximum maintainability, assumes library stability

**Recommendation for "Minimal" Character**:
- Current positioning as "minimal reference" is misleading - /supervise is architecturally identical to /coordinate
- **Path 1**: Remove wave execution (already done), keep sequential as differentiator
- **Path 2**: Simplify to research-and-plan only (Phases 0-2) for true minimalism
- **Path 3**: Re-position as "sequential orchestration" rather than "minimal" since size is equivalent

**Unique Value Proposition for /supervise**:
- If keeping 7 phases: "Sequential orchestration for predictable, easy-to-debug workflows"
- If reducing scope: "Lightweight research-and-planning orchestrator (no implementation)"
- If maintaining current state: "Reference implementation of clean orchestration patterns"

## Recommendations

### 1. Implement Wave-Based Execution (High Priority)

**Action**: Port Phase 3 wave-based parallel execution from /coordinate to /supervise

**Rationale**:
- 40-60% time savings for multi-phase implementations
- /coordinate has proven implementation (1,930 lines, production-ready)
- Only 8-line size difference - adding waves would still keep /supervise under 2,100 lines

**Implementation Approach**:
1. Add `dependency-analyzer.sh` to required libraries list (supervise.md:174)
2. Replace Phase 3 implementation section (supervise.md:1142-1285) with /coordinate's wave-based approach (coordinate.md:1216-1402)
3. Add `implementer-coordinator.md` and `implementation-executor.md` to agent references
4. Update Phase 3 checkpoint to include wave execution metrics

**Estimated Impact**:
- File size: +186 lines (from 1,938 to 2,124 lines, 9.6% increase)
- Performance: 40-60% faster for multi-phase implementations
- Complexity: Minimal - reusing proven /coordinate implementation

### 2. Extract Verbose Diagnostics to Shared Library Function (Medium Priority)

**Action**: Create `verification-helpers.sh` library with `verify_file_created()` function

**Rationale**:
- /supervise has 6+ copies of 38-line diagnostic template
- /coordinate demonstrates successful helper function approach
- Reduces file size by ~200 lines (10% reduction)
- Improves maintainability (single source of truth)

**Implementation Approach**:
1. Create `.claude/lib/verification-helpers.sh` with `verify_file_created()` function
2. Source in Phase 0 library loading (supervise.md:233)
3. Replace inline diagnostic blocks in Phases 1-6 with function calls
4. Pattern: `verify_file_created "$REPORT_PATH" "Research report $i/$RESEARCH_COMPLEXITY" "Phase 1"`

**Estimated Impact**:
- File size: -228 lines (from 1,938 to 1,710 lines, 11.8% reduction)
- Maintainability: Significant improvement (single diagnostic template)
- Consistency: All verification failures have identical diagnostic structure

### 3. Clarify Architectural Positioning and Differentiation (High Priority)

**Action**: Re-position /supervise based on chosen differentiation strategy

**Rationale**:
- Current "minimal reference" positioning not supported by implementation
- Size difference with /coordinate is negligible (8 lines, 0.4%)
- Architecture, library usage, and patterns are identical

**Option A: Sequential Orchestration** (Recommended)
- Keep all 7 phases, implement wave execution
- Position: "Production-ready sequential orchestration for predictable workflows"
- Differentiator: Sequential execution within phases (vs /coordinate's parallel waves)
- Target size: 2,100-2,200 lines (with wave execution)
- **Best for**: Users who prioritize debuggability over speed

**Option B: Research-and-Plan Only** (True Minimalism)
- Remove Phases 3-6 (implementation, testing, debug, documentation)
- Position: "Lightweight research-and-planning orchestrator"
- Differentiator: Faster, simpler, focused on planning workflows
- Target size: 800-1,000 lines (50% reduction from current)
- **Best for**: Quick research and planning without implementation

**Option C: Reference Implementation** (Current State)
- Keep current 7-phase structure without wave execution
- Position: "Reference implementation of clean orchestration patterns"
- Differentiator: Detailed documentation, educational value
- Target size: 1,700-1,900 lines (after helper function extraction)
- **Best for**: Learning orchestration patterns, template for new commands

**Recommendation**: **Option A** - Implement wave execution and position as "sequential orchestration"
- Maintains feature parity with /coordinate
- Clear differentiator (sequential vs parallel within waves)
- Performance competitive (waves across phases, sequential within phases)
- Size remains reasonable (2,100 lines vs 1,930 for /coordinate)

### 4. Implement Actual Context Pruning (Medium Priority)

**Action**: Add explicit `apply_pruning_policy()` calls after Phases 2, 3, 5

**Rationale**:
- /supervise claims "80-90% context reduction" but has no pruning calls
- /coordinate has working implementation (coordinate.md:1180, 1393, 1676)
- Performance target of <30% context usage not achievable without pruning

**Implementation Approach**:
1. Add pruning call after Phase 2 planning: `apply_pruning_policy "planning" "$WORKFLOW_SCOPE"`
2. Add pruning call after Phase 3 implementation: `apply_pruning_policy "implementation" "orchestrate"`
3. Add pruning call after Phase 5 debugging: Test output pruned after completion
4. Use /coordinate's pattern verbatim (proven implementation)

**Estimated Impact**:
- File size: +12 lines (3 pruning blocks with before/after size logging)
- Performance: Achieve target <30% context usage throughout workflow
- Reliability: Prevent context window exhaustion on large workflows

### 5. Standardize Progress Markers (Low Priority)

**Action**: Align progress marker format with /coordinate's consistent pattern

**Rationale**:
- /coordinate has consistent dual-mode progress reporting
- /supervise has mixed progress marker patterns
- External monitoring tools expect consistent format

**Implementation Approach**:
1. Review all `emit_progress()` calls in /supervise
2. Standardize to format: `emit_progress "N" "Phase N complete - action"`
3. Add dual-mode reporting: silent progress marker + user-facing echo
4. Pattern from /coordinate (coordinate.md:605, 836, 1035, 1401)

**Example Standardization**:
```bash
# After Phase 1
emit_progress "1" "Research complete ($SUCCESSFUL_REPORT_COUNT reports created)"
echo "✓ Phase 1 complete: Research finished ($SUCCESSFUL_REPORT_COUNT reports)"
echo ""
```

**Estimated Impact**:
- File size: +8 lines (additional echo statements for user-facing output)
- UX: Improved consistency with /coordinate
- Monitoring: External tools can parse progress reliably

## References

### Primary Source Files
- `/home/benjamin/.config/.claude/commands/supervise.md:1-1938` - Complete /supervise command implementation
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-1930` - Complete /coordinate command implementation
- `/home/benjamin/.config/CLAUDE.md:502-511` - Orchestration command comparison and positioning

### Key Sections Analyzed

**Library Integration**:
- `supervise.md:168-174` - Required library list
- `supervise.md:207-238` - Library sourcing implementation
- `supervise.md:275-330` - Function verification after sourcing
- `coordinate.md:329` - Dependency-analyzer.sh addition

**Agent Invocation Patterns**:
- `supervise.md:625-642` - Research agent invocation template
- `supervise.md:953` - Plan-architect invocation
- `supervise.md:1169` - Code-writer invocation
- `coordinate.md:1799-1800` - Wave execution agents (implementer-coordinator, implementation-executor)

**Error Handling**:
- `supervise.md:138-149` - Fail-fast philosophy
- `supervise.md:692-730` - 5-section diagnostic template (38 lines)
- `coordinate.md:771-810` - verify_file_created() helper function

**Wave-Based Execution**:
- `coordinate.md:186-243` - Wave execution overview and design
- `coordinate.md:1237-1282` - Dependency analysis and wave calculation
- `coordinate.md:1290-1319` - Implementer-coordinator agent invocation

**Context Pruning**:
- `supervise.md:343-345` - Metadata extraction claims (not fully implemented)
- `coordinate.md:1180` - Pruning after Phase 2 planning
- `coordinate.md:1393` - Pruning after Phase 3 implementation
- `coordinate.md:1676` - Pruning after Phase 5 debugging

### Supporting Documentation
- `.claude/lib/dependency-analyzer.sh` - Wave calculation library (referenced in coordinate.md:193, 329)
- `.claude/lib/error-handling.sh` - Error classification and diagnostics (supervise.md:148, 169)
- `.claude/lib/checkpoint-utils.sh` - Checkpoint resume capability (supervise.md:170, 340)
- `.claude/agents/implementer-coordinator.md` - Wave orchestration agent (coordinate.md:1799)
- `.claude/agents/implementation-executor.md` - Phase execution agent (coordinate.md:1800)

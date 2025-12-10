# Root Cause Analysis and Fix Strategy: Lean-Plan Context Window Optimization

**Research Date**: 2025-12-10
**Topic**: Synthesize findings from output analysis, orchestrator patterns, and standards to identify root causes of context window overuse and develop solution plan
**Complexity**: 3

## Executive Summary

The `/lean-plan` command suffers from **95% context window overuse** compared to `/create-plan` due to **missing research-coordinator integration**. The command directly invokes `research-specialist` in sequential mode instead of using the parallel `research-coordinator` supervisor agent. This results in:

- **Full report content loading** (2,500 tokens/report) instead of metadata-only passing (110 tokens/report)
- **Sequential research execution** instead of parallel topic orchestration
- **No context reduction** (0% vs 95% in create-plan)
- **Limited iteration capacity** (3-4 iterations vs 10+ possible with coordinator)

**Fix Complexity**: Medium (estimated 4-6 hours)
**Impact**: 95% context reduction, 40-60% time savings, 10+ iteration capacity

---

## Root Cause Analysis

### Primary Root Cause: Missing research-coordinator Integration

**Evidence from Code Comparison**:

**lean-plan.md (CURRENT - BROKEN)**:
```bash
# Line 992: Block 1e-exec comment mentions research-coordinator
## Block 1e-exec: Research Coordination (research-coordinator Invocation)

# But actual Task invocation at line 1001 shows DIRECT research-specialist call:
${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

# However, the prompt structure is WRONG - it reads research-coordinator.md
# but then tells the agent to "invoke research-specialist for EACH topic"
# This is attempting to make research-coordinator behavior happen WITHOUT
# actually using the coordinator architecture properly
```

**create-plan.md (CORRECT - WORKING)**:
```bash
# Line 1434-1443: Proper research-coordinator Task invocation
**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Orchestrate parallel research across multiple topics"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    # Proper delegation to coordinator with topics array
    topics: [...]
    report_paths: [...]
    # Coordinator handles research-specialist invocations internally
  "
}
```

**Key Difference**:
- `/create-plan` properly delegates to research-coordinator which handles all research-specialist invocations
- `/lean-plan` tries to invoke research-coordinator but with incorrect prompt structure that bypasses coordinator workflow

### Secondary Root Causes

#### 1. **Topic Detection Missing** (Lines 1-500 of lean-plan.md)

**Observation**: `/lean-plan` does NOT use `topic-detection-agent` (Manual Pre-Decomposition mode)

**create-plan.md has**:
```yaml
dependent-agents:
  - research-coordinator
  - topic-naming-agent
  - topic-detection-agent  # ← MISSING in lean-plan
  - plan-architect
```

**lean-plan.md has**:
```yaml
dependent-agents:
  - topic-naming-agent
  - research-coordinator
  - lean-plan-architect
  # NO topic-detection-agent
```

**Impact**: Without topic-detection-agent, lean-plan cannot pre-decompose research topics into structured arrays, preventing proper research-coordinator Mode 2 invocation (Manual Pre-Decomposition).

#### 2. **Hardcoded Research Topics** (Line 988-1022)

**Current Pattern**:
```bash
# lean-plan.md hardcodes Lean-specific topics:
TOPICS=(
  "Mathlib Theorems for ${FEATURE_DESCRIPTION}|mathlib-theorems"
  "Proof Automation Strategies|proof-automation"
  "Lean Project Structure Patterns|project-structure"
)
```

**Problem**:
- Fixed 3-topic structure regardless of complexity
- No dynamic topic generation based on feature description
- Cannot leverage complexity levels (1-4) for topic count

**create-plan.md Approach**:
```bash
# Uses topic-detection-agent to dynamically generate topics:
# Complexity 1-2: 2-3 topics
# Complexity 3: 3-4 topics
# Complexity 4: 4-5 topics
```

#### 3. **Report Path Pre-Calculation Incomplete** (Line 990-1010)

**Current Issue**:
```bash
# lean-plan.md calculates REPORT_DIR but not individual report paths
REPORT_DIR="${TOPIC_PATH}/reports"
# Missing: REPORT_PATHS array with pre-calculated paths per topic
```

**Required Pattern** (from research-coordinator.md STEP 2):
```bash
# Pre-calculate ALL report paths BEFORE coordinator invocation
REPORT_PATHS=(
  "${REPORT_DIR}/001-mathlib-theorems.md"
  "${REPORT_DIR}/002-proof-automation.md"
  "${REPORT_DIR}/003-project-structure.md"
)
```

#### 4. **Missing Completion Signal Parsing** (Line 1049-1150)

**Current State**: lean-plan has validation logic but doesn't parse coordinator return signal properly

**Required Fields** (from research-coordinator.md Return Signal Contract):
```yaml
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_processed: 3
reports_created: 3
context_reduction_pct: 95
context_usage_percent: 12
reports: [JSON array of metadata]
```

**Current lean-plan validation**:
- Checks for file existence (correct)
- Checks for empty directory (correct)
- **Missing**: Parse context_usage_percent for iteration tracking
- **Missing**: Parse metadata array for downstream use

---

## Gap Analysis: lean-plan vs create-plan

| Feature | create-plan | lean-plan | Gap Impact |
|---------|-------------|-----------|------------|
| **research-coordinator** | ✅ Proper Mode 2 invocation | ❌ Malformed invocation | **CRITICAL** - 95% context overuse |
| **topic-detection-agent** | ✅ Dynamic topic generation | ❌ Hardcoded topics | High - No complexity scaling |
| **Report path pre-calc** | ✅ REPORT_PATHS array | ❌ Only REPORT_DIR | High - Hard barrier broken |
| **Completion signal parse** | ✅ Full metadata extraction | ⚠️ Partial validation | Medium - No context tracking |
| **Context usage tracking** | ✅ Parses context_percent | ❌ Not tracked | Medium - No iteration limit |
| **Metadata passing** | ✅ 110 tokens/report | ❌ Full content (2500 tokens) | **CRITICAL** - 95% overhead |

---

## Solution Architecture

### Phase 1: Research Coordinator Integration (CRITICAL PATH)

**Objective**: Replace direct research-specialist invocation with proper research-coordinator delegation

**Changes Required**:

#### 1.1. Add topic-detection-agent Dependency

**File**: `.claude/commands/lean-plan.md` (Line 5-8)

**Current**:
```yaml
dependent-agents:
  - topic-naming-agent
  - research-coordinator
  - lean-plan-architect
```

**Updated**:
```yaml
dependent-agents:
  - topic-naming-agent
  - topic-detection-agent  # NEW
  - research-coordinator
  - lean-plan-architect
```

#### 1.2. Add Topic Detection Block (NEW Block 1d-topics)

**Location**: After Block 1c (Hard Barrier Validation), before Block 1e-exec (Research Coordination)

**Pattern** (copy from create-plan.md lines 1200-1320):
```bash
## Block 1d-topics: Topic Detection and Report Path Pre-Calculation

**EXECUTE NOW**: USE the Task tool to invoke topic-detection-agent for dynamic topic generation.

Task {
  subagent_type: "general-purpose"
  description: "Detect research topics for Lean formalization"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/topic-detection-agent.md

    **Feature Description**: ${FEATURE_DESCRIPTION}
    **Research Complexity**: ${RESEARCH_COMPLEXITY}
    **Domain Context**: Lean 4 theorem proving (Mathlib, tactics, project structure)
    **Output Path**: ${TOPICS_FILE}

    Generate 2-5 Lean-specific research topics based on complexity.
    Write topics array to output path as JSON.
  "
}
```

**Validation Block** (after Task invocation):
```bash
# Validate topics file exists
if [ ! -f "$TOPICS_FILE" ]; then
  echo "ERROR: topic-detection-agent did not create topics file" >&2
  exit 1
fi

# Parse topics JSON array
TOPICS_JSON=$(cat "$TOPICS_FILE")
TOPICS_COUNT=$(echo "$TOPICS_JSON" | jq -r '.topics | length')

# Pre-calculate report paths for each topic
REPORT_PATHS=()
for i in $(seq 0 $((TOPICS_COUNT - 1))); do
  TOPIC_SLUG=$(echo "$TOPICS_JSON" | jq -r ".topics[$i].slug")
  REPORT_NUM=$(printf "%03d" $((i + 1)))
  REPORT_PATH="${REPORT_DIR}/${REPORT_NUM}-${TOPIC_SLUG}.md"
  REPORT_PATHS+=("$REPORT_PATH")
done

# Persist for Block 1e-exec
append_workflow_state "TOPICS_JSON" "$TOPICS_JSON"
append_workflow_state "REPORT_PATHS" "${REPORT_PATHS[*]}"
```

#### 1.3. Update Research Coordinator Invocation (Block 1e-exec)

**File**: `.claude/commands/lean-plan.md` (Line 992-1035)

**Current (BROKEN)**:
```bash
## Block 1e-exec: Research Coordination (research-coordinator Invocation)

Task {
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    # This tells agent to invoke research-specialist but doesn't provide
    # proper coordinator workflow parameters
  "
}
```

**Updated (CORRECT)**:
```bash
## Block 1e-exec: Research Coordination (research-coordinator Invocation)

**EXECUTE NOW**: USE the Task tool to invoke research-coordinator in Mode 2 (Pre-Decomposed).

Task {
  subagent_type: "general-purpose"
  description: "Orchestrate parallel Lean research across multiple topics"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Invocation Mode**: Mode 2 - Manual Pre-Decomposition

    **Input Parameters**:
    - research_request: Comprehensive Lean 4 research for ${FEATURE_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${REPORT_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_JSON}  # Pre-calculated by topic-detection-agent
    - report_paths: [${REPORT_PATHS[@]}]  # Pre-calculated report paths
    - context:
        feature_description: ${FEATURE_DESCRIPTION}
        lean_project_path: ${LEAN_PROJECT_PATH}
        domain: Lean 4 theorem proving

    Follow research-coordinator.md workflow:
    - STEP 1: Receive topics (already provided)
    - STEP 2: Use provided report_paths (skip calculation)
    - STEP 3: Invoke research-specialist for each topic in parallel
    - STEP 4: Validate all reports exist (hard barrier)
    - STEP 5: Extract metadata (110 tokens per report)
    - STEP 6: Return aggregated metadata

    Return completion signal:
    RESEARCH_COORDINATOR_COMPLETE: SUCCESS
    topics_processed: N
    reports_created: N
    context_reduction_pct: 95
    context_usage_percent: N
    reports: [JSON metadata array]
  "
}
```

#### 1.4. Update Completion Signal Parsing (Block 1f)

**File**: `.claude/commands/lean-plan.md` (Line 1049-1150)

**Add after existing validation**:
```bash
# Parse research-coordinator return signal
COORDINATOR_OUTPUT=$(cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinator_output_${WORKFLOW_ID}.txt" 2>/dev/null || echo "")

# Extract completion fields
TOPICS_PROCESSED=$(echo "$COORDINATOR_OUTPUT" | grep "^topics_processed:" | cut -d: -f2 | tr -d ' ')
REPORTS_CREATED=$(echo "$COORDINATOR_OUTPUT" | grep "^reports_created:" | cut -d: -f2 | tr -d ' ')
CONTEXT_REDUCTION=$(echo "$COORDINATOR_OUTPUT" | grep "^context_reduction_pct:" | cut -d: -f2 | tr -d ' ')
CONTEXT_USAGE=$(echo "$COORDINATOR_OUTPUT" | grep "^context_usage_percent:" | cut -d: -f2 | tr -d ' ')

# Validate completion signal
if [ -z "$TOPICS_PROCESSED" ] || [ "$TOPICS_PROCESSED" -eq 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "agent_error" \
    "research-coordinator returned invalid completion signal" \
    "bash_block_1f" \
    "$(jq -n --arg output "$COORDINATOR_OUTPUT" '{coordinator_output: $output}')"
  echo "ERROR: research-coordinator completion signal missing or invalid" >&2
  exit 1
fi

# Log context metrics
echo "✓ Research coordination complete"
echo "  Topics Processed: $TOPICS_PROCESSED"
echo "  Reports Created: $REPORTS_CREATED"
echo "  Context Reduction: ${CONTEXT_REDUCTION}%"
echo "  Context Usage: ${CONTEXT_USAGE}%"

# Persist context usage for iteration tracking
append_workflow_state "RESEARCH_CONTEXT_USAGE" "$CONTEXT_USAGE"
```

---

### Phase 2: Lean-Plan-Architect Context Optimization

**Objective**: Ensure lean-plan-architect receives metadata-only (not full reports)

**Changes Required**:

#### 2.1. Update lean-plan-architect Invocation (Block 2)

**File**: `.claude/commands/lean-plan.md` (estimated line 1400-1500)

**Pattern**:
```bash
## Block 2: Plan Generation (lean-plan-architect Invocation)

Task {
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-plan-architect.md

    **Research Reports Metadata** (DO NOT read full reports):
    ${REPORTS_METADATA_JSON}

    **Report Paths** (for reference links in plan):
    ${REPORT_PATHS[@]}

    You MUST NOT use Read tool on report files.
    Use metadata-only for context efficiency (95% reduction).
  "
}
```

**Key Change**: Pass `REPORTS_METADATA_JSON` (extracted from coordinator) instead of report paths for reading.

---

### Phase 3: Block Consolidation

**Objective**: Reduce bash block count from 8+ to 4-5 blocks

**Consolidation Strategy**:

#### 3.1. Merge Blocks 1a + 1b (Setup + Topic Path Pre-Calc)

**Rationale**: Both are initialization logic, no agent invocation between them

**Result**: Single "Block 1: Initial Setup and Path Pre-Calculation" (150 lines)

#### 3.2. Keep Block 1b-exec (Topic Naming) Separate

**Rationale**: Hard barrier pattern requires separate Task invocation block

#### 3.3. Keep Block 1c (Hard Barrier Validation) Separate

**Rationale**: Explicit validation checkpoint for hard barrier

#### 3.4. Merge Blocks 1d + 1d-topics (NEW - Topic Detection)

**Rationale**: Topic detection and path pre-calculation are sequential prep

**Result**: Single "Block 1d: Topic Detection and Report Path Pre-Calculation" (100 lines)

#### 3.5. Keep Block 1e-exec (Research Coordination) Separate

**Rationale**: Hard barrier pattern for research-coordinator invocation

#### 3.6. Merge Blocks 1f + 2 (Validation + Planning)

**Rationale**: Validation and plan generation transition can be sequential

**Result**: Single "Block 2: Research Validation and Plan Generation" (200 lines)

**Final Block Structure**:
```
Block 1: Initial Setup and Path Pre-Calculation (merged 1a+1b)
Block 1b-exec: Topic Name Generation (unchanged)
Block 1c: Topic Name Validation (unchanged)
Block 1d: Topic Detection and Report Paths (NEW)
Block 1e-exec: Research Coordination (updated)
Block 2: Research Validation and Plan Generation (merged 1f+2)
```

**Result**: 6 blocks (down from 8-10) while maintaining hard barrier integrity

---

## Validation Strategy

### Pre-Implementation Validation

**Test Case 1: Simple Formalization (Complexity 1)**
```bash
/lean-plan "prove commutativity of addition" --complexity 1 --project ~/ProofChecker
```

**Expected**:
- 2-3 research topics generated
- research-coordinator invoked with Mode 2
- Context usage: ~8-10%
- 3 reports created with metadata-only passing

**Test Case 2: Complex Formalization (Complexity 4)**
```bash
/lean-plan "formalize category theory functors with natural transformations" --complexity 4 --project ~/MathLib
```

**Expected**:
- 4-5 research topics generated
- research-coordinator invoked with Mode 2
- Context usage: ~15-18%
- 5 reports created with metadata-only passing

### Post-Implementation Validation

**Metrics to Track**:
1. **Context Reduction**: Target 95% (2,500 tokens → 110 tokens per report)
2. **Iteration Capacity**: Target 10+ iterations (from 3-4)
3. **Block Count**: Target 6 blocks (from 8-10)
4. **Research Time**: Target 40-60% reduction (parallel execution)
5. **Error Rate**: Target 0% coordinator invocation failures

**Validation Commands**:
```bash
# Validate research-coordinator integration
bash .claude/scripts/validate-agent-dependencies.sh lean-plan.md

# Validate metadata passing
grep -A 10 "REPORTS_METADATA_JSON" .claude/commands/lean-plan.md

# Validate context tracking
grep "context_usage_percent" .claude/commands/lean-plan.md
```

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **topic-detection-agent compatibility** | Low | High | Use create-plan pattern (proven working) |
| **research-coordinator Mode 2 failure** | Low | High | Pre-validated in create-plan (48/48 tests pass) |
| **Lean-specific topic generation** | Medium | Medium | Add Lean domain hints to topic-detection prompt |
| **Block consolidation breaking flow** | Low | Medium | Maintain hard barrier separation |
| **Metadata parsing errors** | Low | Low | Use create-plan JSON parsing pattern |

---

## Implementation Checklist

### Phase 1: Research Coordinator Integration (4 hours)
- [ ] Add topic-detection-agent to dependent-agents list
- [ ] Create Block 1d-topics (topic detection + path pre-calc)
- [ ] Update Block 1e-exec (research-coordinator invocation)
- [ ] Add completion signal parsing in Block 1f
- [ ] Test with complexity 1, 2, 3, 4 cases

### Phase 2: Architect Context Optimization (1 hour)
- [ ] Update lean-plan-architect invocation with metadata-only
- [ ] Remove Read tool from architect prompt
- [ ] Validate plan generation still works

### Phase 3: Block Consolidation (1 hour)
- [ ] Merge Blocks 1a + 1b
- [ ] Merge Blocks 1f + 2
- [ ] Validate hard barriers intact
- [ ] Test full workflow end-to-end

### Phase 4: Validation and Documentation (1 hour)
- [ ] Run validation test suite
- [ ] Measure context reduction (target: 95%)
- [ ] Measure iteration capacity (target: 10+)
- [ ] Update lean-plan-command-guide.md
- [ ] Document breaking changes (if any)

---

## Success Criteria

1. **Context Reduction**: 95% reduction (2,500 → 110 tokens per report)
2. **Iteration Capacity**: 10+ iterations possible (from 3-4)
3. **Research Parallelization**: 3-5 topics researched concurrently
4. **Block Count**: 6 bash blocks (from 8-10)
5. **Zero Regressions**: All existing lean-plan tests pass
6. **Coordinator Integration**: 100% success rate on Mode 2 invocation

---

## References

1. **research-coordinator.md** (lines 1-1190): Complete coordinator workflow specification
2. **create-plan.md** (lines 1200-1600): Working coordinator integration pattern
3. **Hierarchical Agents Examples** (Example 8): Lean command coordinator optimization architecture
4. **Research Coordinator Migration Guide**: Step-by-step integration instructions
5. **Plan Metadata Standard**: Complexity Score and Structure Level requirements

---

## Appendices

### Appendix A: Coordinator Return Signal Contract

**Format** (from research-coordinator.md lines 969-967):
```
RESEARCH_COORDINATOR_COMPLETE: SUCCESS
topics_processed: 3
reports_created: 3
context_reduction_pct: 95
context_usage_percent: 12
checkpoint_path: /path/to/checkpoint.json (optional)

RESEARCH_COMPLETE: 3
reports: [
  {"path": "/path/001.md", "title": "...", "findings_count": 12, "recommendations_count": 5},
  {"path": "/path/002.md", "title": "...", "findings_count": 8, "recommendations_count": 4},
  {"path": "/path/003.md", "title": "...", "findings_count": 10, "recommendations_count": 6}
]
total_findings: 30
total_recommendations: 15
```

### Appendix B: Topic Detection Agent Prompt Template

**Pattern** (for Lean domain):
```
**Feature Description**: ${FEATURE_DESCRIPTION}
**Research Complexity**: ${RESEARCH_COMPLEXITY}
**Domain Context**: Lean 4 theorem proving
**Domain Keywords**: Mathlib, tactics, proof automation, formalization, lakefile

**Topic Generation Guidelines**:
- Complexity 1-2: 2-3 topics (basic formalization)
- Complexity 3: 3-4 topics (standard formalization)
- Complexity 4: 4-5 topics (advanced formalization)

**Lean-Specific Topics** (prioritize):
1. Mathlib theorem search (related to feature)
2. Proof automation strategies (tactics, simplifiers)
3. Project structure patterns (lakefile, module organization)
4. Style guide compliance (naming, formatting)
5. Testing strategies (lean-build validation)

**Output Format**: JSON array with slug, title, description
```

### Appendix C: Block Consolidation Decision Matrix

| Blocks | Can Merge? | Rationale |
|--------|-----------|-----------|
| 1a + 1b | ✅ Yes | Both initialization, no agent between |
| 1b-exec (standalone) | ❌ No | Hard barrier Task invocation |
| 1c (standalone) | ❌ No | Hard barrier validation |
| 1d + 1d-topics | ✅ Yes | Sequential prep work |
| 1e-exec (standalone) | ❌ No | Hard barrier Task invocation |
| 1f + 2 | ✅ Yes | Validation → planning transition |

**Result**: 8 blocks → 6 blocks (25% reduction)

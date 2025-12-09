# Phase 3: Validate Three-Tier Hierarchy Operation

## Metadata

- **Phase Number**: 3
- **Parent Plan**: [001-lean-plan-agent-hierarchy-fix-plan.md](001-lean-plan-agent-hierarchy-fix-plan.md)
- **Objective**: Verify complete three-tier agent hierarchy functions correctly end-to-end
- **Complexity**: High
- **Status**: COMPLETE (Validation Framework)
- **Validation Report**: [phase-3-validation-report.md](../../debug/phase-3-validation-report.md)
- **Dependencies**: Phase 1 (syntax fix - COMPLETE), Phase 2 (error logging fix - COMPLETE)
- **Estimated Hours**: 1-2 hours

## Overview

This phase validates that the /lean-plan command's three-tier agent hierarchy (Orchestrator → Coordinator → Specialist) functions correctly after the syntax and error logging fixes from Phases 1-2. Validation confirms:

1. **Mode 2 (Pre-Decomposed) Pattern**: Orchestrator correctly pre-decomposes topics and pre-calculates paths
2. **Parallel Research Execution**: Coordinator invokes specialists in parallel for 40-60% time savings
3. **Hard Barrier Pattern**: Validation enforces ≥50% report creation threshold
4. **Metadata-Only Passing**: Coordinator returns metadata (~330 tokens) instead of full reports (~7,500 tokens)
5. **Plan Generation**: plan-architect successfully receives metadata and can selectively Read full reports

## Architecture Validation

### Three-Tier Agent Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR TIER                          │
│                    /lean-plan command                            │
│                                                                  │
│  Block 1d-topics: Pre-decompose Lean-specific research topics   │
│  Block 1e-exec: Invoke research-coordinator with Mode 2 contract│
│  Block 1f: Hard Barrier Pattern validation (≥50% threshold)    │
│  Block 1f-metadata: Extract metadata from coordinator output    │
│  Block 2: Pass metadata-only to plan-architect                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     COORDINATOR TIER                             │
│               research-coordinator agent                         │
│                                                                  │
│  Mode 2 Contract:                                                │
│  - Receives pre-decomposed topics (not research_request)        │
│  - Receives pre-calculated report paths                         │
│  - Skips decomposition step                                      │
│  - Invokes specialists in parallel                               │
│  - Returns metadata-only JSON (not full reports)                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (parallel invocation)
┌─────────────────────────────────────────────────────────────────┐
│                      SPECIALIST TIER                             │
│               research-specialist agents (×N)                    │
│                                                                  │
│  Topics (complexity 3):                                          │
│  ├── Mathlib Research: theorems, tactics, data structures       │
│  ├── Proof Strategies: proof patterns, tactic sequences         │
│  └── Project Structure: module organization, dependencies       │
│                                                                  │
│  Output: Full research reports written to pre-calculated paths  │
└─────────────────────────────────────────────────────────────────┘
```

### Token Flow Validation

```
WITHOUT Metadata-Only Passing (previous implementation):
┌───────────────────────────┐     ┌───────────────────────────┐
│   research-coordinator    │────►│      plan-architect       │
│                           │     │                           │
│  Full Report 1: 2,500 tok │     │  Receives: ~7,500 tokens  │
│  Full Report 2: 2,500 tok │     │  (3 full reports)         │
│  Full Report 3: 2,500 tok │     │                           │
└───────────────────────────┘     └───────────────────────────┘

WITH Metadata-Only Passing (current implementation):
┌───────────────────────────┐     ┌───────────────────────────┐
│   research-coordinator    │────►│      plan-architect       │
│                           │     │                           │
│  Metadata: ~110 tokens/ea │     │  Receives: ~330 tokens    │
│  ├── title: ~20 tokens   │     │  (3 metadata summaries)   │
│  ├── findings: ~30 tok   │     │                           │
│  ├── recs: ~20 tokens    │     │  Can use Read tool for    │
│  └── path: ~40 tokens    │     │  selective full access    │
└───────────────────────────┘     └───────────────────────────┘

Context Reduction: 7,500 → 330 tokens = 95.6% reduction
```

## Validation Stages

### Stage 1: Test Environment Setup

**Objective**: Prepare test feature and baseline measurements

**Tasks**:
- [ ] Define test feature for complexity 3 execution
- [ ] Record baseline token count for comparison
- [ ] Ensure clean state (no previous research reports for test feature)
- [ ] Verify all prerequisite fixes from Phase 1-2 are applied

**Test Feature Definition**:
```
Feature: Implement basic group theory structures in Lean 4
Description: Define Group typeclass with associativity, identity, and inverse axioms
Complexity: 3 (triggers Mathlib + Proof Strategies + Project Structure research)
```

**Baseline Measurements**:
| Metric | Expected Value | Measurement Method |
|--------|----------------|-------------------|
| Token count (metadata-only) | ~330 tokens | Count tokens in plan-architect input |
| Token count (full reports) | ~7,500 tokens | Sum of 3 full report token counts |
| Context reduction | 95.6% | (7500-330)/7500 * 100 |

**Pre-Validation Checklist**:
```bash
# Verify Phase 1-2 fixes applied
grep -n "log_command_error" .claude/commands/lean-plan.md | head -5
# Should show 7-parameter signature calls

# Verify error-handling library accessible
ls -la .claude/lib/core/error-handling.sh

# Clean test state
rm -rf .claude/specs/*/reports/*group_theory* 2>/dev/null || true
```

### Stage 2: Block 1d-topics Validation

**Objective**: Verify topic pre-decomposition and path pre-calculation

**Tasks**:
- [ ] Execute Block 1d-topics with complexity 3 feature
- [ ] Verify 3 topics decomposed: Mathlib, Proof Strategies, Project Structure
- [ ] Verify REPORT_PATHS array contains 3 absolute paths
- [ ] Verify paths follow Hard Barrier Pattern format

**Expected Topic Decomposition (Complexity 3)**:
```
LEAN_TOPICS=(
  "Mathlib Research: Existing theorems, tactics, and data structures for group theory"
  "Proof Strategies: Proof patterns for typeclass implementation and axiom verification"
  "Project Structure: Lean 4 module organization for mathematical structures"
)
```

**Expected Path Pattern**:
```
REPORT_PATHS=(
  "/home/benjamin/.config/.claude/specs/NNN_topic/reports/001-mathlib-research.md"
  "/home/benjamin/.config/.claude/specs/NNN_topic/reports/002-proof-strategies.md"
  "/home/benjamin/.config/.claude/specs/NNN_topic/reports/003-project-structure.md"
)
```

**Validation Commands**:
```bash
# After Block 1d-topics executes, verify state
source .claude/data/state/lean-plan_*.state 2>/dev/null

# Check topics array
echo "Topics: ${#LEAN_TOPICS[@]}"
for topic in "${LEAN_TOPICS[@]}"; do
  echo "  - $topic"
done

# Check paths array
echo "Paths: ${#REPORT_PATHS[@]}"
for path in "${REPORT_PATHS[@]}"; do
  echo "  - $path"
  [[ "$path" =~ ^/ ]] && echo "    ✓ Absolute path" || echo "    ✗ NOT absolute"
done
```

**Success Criteria**:
- [ ] LEAN_TOPICS array contains exactly 3 entries
- [ ] REPORT_PATHS array contains exactly 3 entries
- [ ] All paths are absolute (start with `/`)
- [ ] All paths end with `.md`
- [ ] No syntax errors during execution

### Stage 3: Block 1e-exec Validation

**Objective**: Verify research-coordinator invocation with Mode 2 contract

**Tasks**:
- [ ] Verify coordinator receives pre-decomposed topics
- [ ] Verify coordinator receives pre-calculated paths
- [ ] Verify coordinator skips decomposition step
- [ ] Monitor parallel specialist invocation
- [ ] Time research completion

**Mode 2 Contract Verification**:
```
Coordinator Input (Mode 2):
{
  "mode": "pre-decomposed",
  "topics": [
    "Mathlib Research: ...",
    "Proof Strategies: ...",
    "Project Structure: ..."
  ],
  "report_paths": [
    "/absolute/path/to/001-mathlib-research.md",
    "/absolute/path/to/002-proof-strategies.md",
    "/absolute/path/to/003-project-structure.md"
  ]
}
```

**Parallel Execution Timing**:
| Execution Mode | Expected Time | Calculation |
|----------------|---------------|-------------|
| Serial (3 topics) | ~9 minutes | 3 × 3 min per topic |
| Parallel (3 topics) | ~3.5 minutes | max(3 min) + overhead |
| Time Savings | 40-60% | (9-3.5)/9 × 100 ≈ 61% |

**Validation Approach**:
```bash
# Record start time
START_TIME=$(date +%s)

# Execute Block 1e-exec
# ... coordinator invocation ...

# Record end time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Validate parallel execution
if [ $DURATION -lt 300 ]; then  # Less than 5 minutes
  echo "✓ Parallel execution confirmed (${DURATION}s)"
else
  echo "⚠ Sequential execution suspected (${DURATION}s)"
fi
```

**Success Criteria**:
- [ ] Coordinator receives topics array (not research_request string)
- [ ] Coordinator receives report_paths array
- [ ] Total research time ≤ 5 minutes for 3 topics
- [ ] All 3 specialists invoked (log evidence)

### Stage 4: Block 1f Hard Barrier Validation

**Objective**: Verify Hard Barrier Pattern enforcement with ≥50% threshold

**Tasks**:
- [ ] Verify all 3 reports created at pre-calculated paths
- [ ] Test 100% success rate scenario
- [ ] Document partial success threshold behavior
- [ ] Verify error logging for missing reports

**Hard Barrier Pattern Thresholds**:
| Reports Created | Success Rate | Behavior |
|-----------------|--------------|----------|
| 3/3 | 100% | Continue to metadata extraction |
| 2/3 | 67% | Continue (above 50% threshold) |
| 1/3 | 33% | Fail-fast with error logging |
| 0/3 | 0% | Fail-fast with error logging |

**Validation Commands**:
```bash
# After Block 1e-exec completes, verify reports exist
CREATED_COUNT=0
for path in "${REPORT_PATHS[@]}"; do
  if [[ -f "$path" ]]; then
    ((CREATED_COUNT++))
    echo "✓ Report exists: $path"
    wc -l "$path" | awk '{print "  Lines: " $1}'
  else
    echo "✗ Report missing: $path"
  fi
done

# Calculate success rate
TOTAL=${#REPORT_PATHS[@]}
SUCCESS_RATE=$((CREATED_COUNT * 100 / TOTAL))
echo "Success rate: ${SUCCESS_RATE}%"

# Threshold check
if [ $SUCCESS_RATE -ge 50 ]; then
  echo "✓ Above 50% threshold - continue"
else
  echo "✗ Below 50% threshold - fail-fast"
fi
```

**Error Logging Validation** (for failure scenarios):
```bash
# Check errors.jsonl for validation error entries
tail -5 .claude/data/errors.jsonl | jq 'select(.error_type == "validation_error")'

# Expected entry format:
{
  "timestamp": "2025-12-08T...",
  "command": "/lean-plan",
  "workflow_id": "lean-plan_...",
  "error_type": "validation_error",
  "message": "Report creation below 50% threshold",
  "context": "bash_block_1f",
  "details": {"created": 1, "expected": 3, "success_rate": "33%"}
}
```

**Success Criteria**:
- [ ] All 3 reports exist at pre-calculated paths
- [ ] Reports contain meaningful content (>50 lines each)
- [ ] Hard barrier validation passes (≥50% threshold met)
- [ ] No validation errors logged for success scenario

### Stage 5: Block 1f-metadata Validation

**Objective**: Verify metadata extraction produces correct format for plan-architect

**Tasks**:
- [ ] Verify metadata extraction from coordinator output
- [ ] Validate metadata token count (~110 tokens per report)
- [ ] Verify markdown link formatting
- [ ] Confirm instruction to use Read tool included

**Metadata Format Specification**:
```markdown
## Research Summary (Metadata Only)

### Report 1: Mathlib Research
- **Path**: [001-mathlib-research.md](../reports/001-mathlib-research.md)
- **Key Findings**: 5 relevant theorems, 3 applicable tactics
- **Recommendations**: 2 implementation approaches

### Report 2: Proof Strategies
- **Path**: [002-proof-strategies.md](../reports/002-proof-strategies.md)
- **Key Findings**: 4 proof patterns, 2 tactic sequences
- **Recommendations**: 1 axiom ordering strategy

### Report 3: Project Structure
- **Path**: [003-project-structure.md](../reports/003-project-structure.md)
- **Key Findings**: Module structure template, import ordering
- **Recommendations**: 2 dependency management approaches

**Note**: Use Read tool to access full report content when detailed information needed.
```

**Token Count Validation**:
```bash
# Count tokens in metadata output (approximate)
METADATA_OUTPUT="..." # from Block 1f-metadata

# Word count approximation (1 token ≈ 0.75 words for English)
WORD_COUNT=$(echo "$METADATA_OUTPUT" | wc -w)
TOKEN_ESTIMATE=$((WORD_COUNT * 4 / 3))

echo "Estimated tokens: $TOKEN_ESTIMATE"

# Validate token reduction
FULL_REPORT_TOKENS=7500  # 3 × 2500 tokens per report
REDUCTION_PERCENT=$((100 - TOKEN_ESTIMATE * 100 / FULL_REPORT_TOKENS))
echo "Context reduction: ${REDUCTION_PERCENT}%"

# Target: ~330 tokens (95.6% reduction)
if [ $TOKEN_ESTIMATE -lt 500 ]; then
  echo "✓ Metadata-only passing achieved"
else
  echo "⚠ Token count higher than expected"
fi
```

**Success Criteria**:
- [ ] Metadata extracted for all 3 reports
- [ ] Each metadata entry contains: path, findings count, recommendations count
- [ ] Total metadata token count ≤ 500 tokens
- [ ] Markdown links correctly formatted
- [ ] Read tool instruction included

### Stage 6: Block 2 Plan-Architect Validation

**Objective**: Verify plan-architect receives metadata-only input and can access full reports

**Tasks**:
- [ ] Verify plan-architect input contains metadata-only summary
- [ ] Verify plan-architect does NOT receive full report content
- [ ] Confirm plan-architect can use Read tool for selective access
- [ ] Validate plan generated successfully

**Plan-Architect Input Structure**:
```markdown
# /lean-plan Execution Context

## Feature Description
Implement basic group theory structures in Lean 4

## Research Metadata (Use Read tool for full reports)

### Available Reports:
1. **Mathlib Research**: [001-mathlib-research.md](path) - 5 findings, 2 recs
2. **Proof Strategies**: [002-proof-strategies.md](path) - 4 findings, 1 rec
3. **Project Structure**: [003-project-structure.md](path) - 2 findings, 2 recs

Total: 3 reports available for selective reading.

## Task
Create implementation plan using research metadata. Read full reports only when detailed information needed.
```

**Verification Steps**:
```bash
# Capture plan-architect input (from Block 2)
ARCHITECT_INPUT="..." # from task tool invocation

# Verify NO full report content
if echo "$ARCHITECT_INPUT" | grep -q "## Executive Summary"; then
  echo "✗ ERROR: Full report content detected in input"
else
  echo "✓ No full report content in input"
fi

# Verify metadata present
if echo "$ARCHITECT_INPUT" | grep -q "Research Metadata"; then
  echo "✓ Research metadata present"
else
  echo "✗ ERROR: Research metadata missing"
fi

# Verify Read tool instruction
if echo "$ARCHITECT_INPUT" | grep -q "Read tool"; then
  echo "✓ Read tool instruction present"
else
  echo "⚠ Read tool instruction missing"
fi
```

**Plan Generation Validation**:
```bash
# After Block 2 completes, verify plan created
PLAN_FILE=$(find .claude/specs -name "*group_theory*plan*.md" -type f | head -1)

if [[ -f "$PLAN_FILE" ]]; then
  echo "✓ Plan created: $PLAN_FILE"
  echo "  Lines: $(wc -l < "$PLAN_FILE")"
  echo "  Size: $(du -h "$PLAN_FILE" | cut -f1)"
else
  echo "✗ Plan not created"
fi

# Verify plan references research reports
if grep -q "001-mathlib-research" "$PLAN_FILE"; then
  echo "✓ Plan references Mathlib research"
fi
if grep -q "002-proof-strategies" "$PLAN_FILE"; then
  echo "✓ Plan references Proof Strategies"
fi
```

**Success Criteria**:
- [ ] Plan-architect input contains ~330 tokens (not ~7,500)
- [ ] No full report content in plan-architect input
- [ ] Metadata summary present with all 3 reports
- [ ] Read tool instruction included
- [ ] Plan generated successfully
- [ ] Plan references research findings

### Stage 7: Performance Metrics Collection

**Objective**: Document actual performance metrics for comparison with expected values

**Tasks**:
- [ ] Record total execution time
- [ ] Record actual token counts
- [ ] Calculate actual context reduction percentage
- [ ] Document iteration capacity improvement

**Metrics Collection Template**:
```markdown
## Validation Metrics Report

### Execution Time
| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Research completion | ≤4 min | ___ min | ✓/✗ |
| Total /lean-plan execution | ≤6 min | ___ min | ✓/✗ |

### Token Usage
| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Metadata tokens | ~330 | ___ | ✓/✗ |
| Full report tokens (baseline) | ~7,500 | ___ | ✓/✗ |
| Context reduction | 95.6% | ___% | ✓/✗ |

### Hierarchy Operation
| Block | Status | Notes |
|-------|--------|-------|
| 1d-topics | ✓/✗ | ___ |
| 1e-exec | ✓/✗ | ___ |
| 1f | ✓/✗ | ___ |
| 1f-metadata | ✓/✗ | ___ |
| Block 2 | ✓/✗ | ___ |

### Iteration Capacity
- Previous (full reports): ~3-4 iterations before context limit
- Current (metadata-only): Expected 10+ iterations
- Actual measured: ___ iterations
```

**Success Criteria**:
- [ ] All blocks execute without errors
- [ ] Research completion ≤ 4 minutes
- [ ] Context reduction ≥ 90%
- [ ] Plan generated successfully

## Error Handling

### Expected Error Scenarios

**Scenario 1: Report Creation Failure**
```
Error: Research specialist failed to create report
Block: 1e-exec
Handling: Coordinator continues with remaining topics
Impact: Reduced findings, may trigger <50% threshold

Recovery:
1. Check specialist agent output for errors
2. Verify topic definition clarity
3. Re-run with individual topic for debugging
```

**Scenario 2: Hard Barrier Threshold Failure**
```
Error: Report creation below 50% threshold (1/3 reports)
Block: 1f
Handling: Fail-fast with error logging
Impact: Command exits, no plan generated

Recovery:
1. Check errors.jsonl for specialist failures
2. Verify network/API connectivity
3. Re-run command after resolving issues
```

**Scenario 3: Metadata Extraction Failure**
```
Error: Failed to parse coordinator metadata output
Block: 1f-metadata
Handling: Attempt regex fallback, then fail
Impact: Plan-architect receives no metadata

Recovery:
1. Check coordinator output format
2. Verify JSON structure validity
3. Use regex extraction as fallback
```

### Error Logging Integration

```bash
# All validation errors should be logged to errors.jsonl
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "validation_error" \
  "Error message here" \
  "block_name" \
  "$(jq -n --arg detail 'value' '{detail: $detail}')"
```

## Rollback Triggers

If validation fails, rollback Phase 1-2 changes if:

1. **Syntax errors reintroduced**: Block 1d-topics fails with bash syntax errors
2. **Error logging broken**: errors.jsonl entries malformed or missing
3. **Performance regression**: Serial execution slower than expected parallel
4. **Plan quality degradation**: Generated plans missing research integration

## Completion Checklist

- [ ] Stage 1: Test environment prepared
- [ ] Stage 2: Block 1d-topics validated
- [ ] Stage 3: Block 1e-exec validated
- [ ] Stage 4: Block 1f Hard Barrier validated
- [ ] Stage 5: Block 1f-metadata validated
- [ ] Stage 6: Block 2 plan-architect validated
- [ ] Stage 7: Performance metrics collected
- [ ] All blocks execute without errors
- [ ] Context reduction ≥ 90% achieved
- [ ] Research time ≤ 4 minutes
- [ ] Plan generated successfully with research integration

## Output Artifacts

Upon completion, the following artifacts will be created:

1. **Validation Report**: `.claude/specs/022_lean_plan_agent_hierarchy_fix/debug/phase-3-validation-report.md`
2. **Test Research Reports**: `.claude/specs/NNN_group_theory/reports/*.md`
3. **Test Plan**: `.claude/specs/NNN_group_theory/plans/*.md`
4. **Error Log Entries**: `.claude/data/errors.jsonl` (if any errors)

---

## Navigation

- **Parent Plan**: [001-lean-plan-agent-hierarchy-fix-plan.md](001-lean-plan-agent-hierarchy-fix-plan.md)
- **Previous Phase**: Phase 2: Fix Error Logging Integration (COMPLETE)
- **Next Phase**: Phase 4: Update Documentation and Standards (COMPLETE)

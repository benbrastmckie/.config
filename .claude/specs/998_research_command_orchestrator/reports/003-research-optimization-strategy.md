# Design /research Optimization Strategy

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Design optimization strategy to refactor /research command using coordinator agents
- **Report Type**: architecture design

## Executive Summary

The current /research command (research.md) already uses the research-coordinator agent for multi-topic research (complexity ≥3) with 95% context reduction through metadata-only passing. However, optimization opportunities exist: (1) eliminate fallback single-topic research path for consistency, (2) enhance topic decomposition with heuristic analysis, (3) add partial success validation thresholds, and (4) improve error recovery patterns. The strategy recommends minimal architectural changes since core coordinator delegation is already implemented, focusing instead on refining edge cases and removing legacy patterns.

## Findings

### Finding 1: Research Coordinator Already Integrated

**Description**: The /research command (Lines 1099-1145) already invokes research-coordinator for all complexity levels, with pre-decomposed topics and report paths passed via Mode 2 invocation pattern.

**Location**: `/home/benjamin/.config/.claude/commands/research.md` (Lines 752-935 topic decomposition, Lines 1099-1145 coordinator invocation)

**Evidence**:
```markdown
## Block 1d-exec: Research Coordinator Invocation

**HARD BARRIER - Research Coordinator Invocation**

**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Coordinate multi-topic research for ${WORKFLOW_DESCRIPTION}"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Input Contract (Hard Barrier Pattern - Mode 2: Pre-Decomposed)**:
    - research_request: ${WORKFLOW_DESCRIPTION}
    - research_complexity: ${RESEARCH_COMPLEXITY}
    - report_dir: ${RESEARCH_DIR}
    - topic_path: ${TOPIC_PATH}
    - topics: ${TOPICS_LIST}
    - report_paths: ${REPORT_PATHS_LIST}
```

**Impact**: Core optimization (coordinator delegation with parallel execution) is already achieved. Optimization efforts should focus on edge cases, consistency, and error handling rather than fundamental architectural changes.

---

### Finding 2: Topic Decomposition Uses Simple Heuristic Pattern

**Description**: Block 1d-topics (Lines 752-935) uses complexity-based topic count mapping (C1-2→1, C3→2, C4→3) with basic string splitting on conjunctions and commas. This produces adequate decomposition but may miss semantic topic boundaries.

**Location**: `/home/benjamin/.config/.claude/commands/research.md` (Lines 752-935)

**Evidence**:
```bash
# Complexity-based topic count mapping
if [ "${RESEARCH_COMPLEXITY:-2}" -ge 3 ]; then
  USE_MULTI_TOPIC=true
  if [ "${RESEARCH_COMPLEXITY:-2}" -eq 3 ]; then
    TOPIC_COUNT=2  # 2-3 topics for complexity 3
  else
    TOPIC_COUNT=3  # 3-4 topics for complexity 4
  fi
fi

# Simple decomposition based on conjunctions and commas
IFS=',' read -ra PARTS <<< "$WORKFLOW_DESCRIPTION"
for part in "${PARTS[@]}"; do
  # Further split on " and " and " or "
  IFS=' and ' read -ra SUB_PARTS <<< "$part"
  ...
done
```

**Impact**: Works for simple cases ("X, Y, and Z") but may produce poor decomposition for complex multi-clause research requests. However, this is a minor optimization opportunity - current implementation is sufficient for most use cases.

---

### Finding 3: Single-Topic Fallback Path Exists

**Description**: Block 1d-topics (Lines 875-888) includes fallback logic that sets `USE_MULTI_TOPIC=false` and `TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")` when decomposition produces fewer than 2 topics.

**Location**: `/home/benjamin/.config/.claude/commands/research.md` (Lines 875-888)

**Evidence**:
```bash
# If decomposition produced fewer topics than target, use single topic
if [ ${#TOPICS_ARRAY[@]} -lt 2 ]; then
  echo "Decomposition produced ${#TOPICS_ARRAY[@]} topics (less than 2), falling back to single-topic mode"
  USE_MULTI_TOPIC=false
  TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
else
  echo "Decomposed into ${#TOPICS_ARRAY[@]} topics:"
  for i in "${!TOPICS_ARRAY[@]}"; do
    echo "  $((i+1)). ${TOPICS_ARRAY[$i]}"
  done
fi
```

**Impact**: This creates architectural inconsistency - sometimes coordinator is invoked with 1 topic (single-topic mode), sometimes with N topics (multi-topic mode). The coordinator agent should handle both modes, but consistency would improve reliability.

---

### Finding 4: Hard Barrier Validation Uses All-Or-Nothing Pattern

**Description**: Block 1e (Lines 1152-1319) validates that ALL expected reports exist, failing workflow if any report is missing. This does not align with coordinator's partial success mode (≥50% threshold documented in research-coordinator.md).

**Location**: `/home/benjamin/.config/.claude/commands/research.md` (Lines 1218-1313)

**Evidence**:
```bash
# === FAIL-FAST IF ANY REPORTS MISSING ===
if [ "$VALIDATION_FAILED" = "true" ]; then
  echo "" >&2
  echo "ERROR: HARD BARRIER FAILED - ${#FAILED_REPORTS[@]} report(s) missing or invalid" >&2
  ...
  exit 1
fi
```

**Impact**: Overly strict validation contradicts coordinator's documented partial success behavior. If coordinator returns `RESEARCH_COMPLETE: 2` with 1 failed report out of 3, the command should continue with warning, not exit. Current pattern wastes partial research results.

---

### Finding 5: Coordinator Agent Uses Multi-Layer Validation

**Description**: Research-coordinator agent (research-coordinator.md, Lines 511-655) implements comprehensive validation: invocation plan file (STEP 2.5), invocation trace file (STEP 3), and report file existence checks (STEP 4).

**Location**: `/home/benjamin/.config/.claude/agents/research-coordinator.md` (Lines 266-328 STEP 2.5, Lines 510-655 STEP 4)

**Evidence**:
```bash
# STEP 2.5: Invocation plan file creation (hard barrier)
INVOCATION_PLAN_FILE="$REPORT_DIR/.invocation-plan.txt"
cat > "$INVOCATION_PLAN_FILE" <<EOF_PLAN
Expected Invocations: $EXPECTED_INVOCATIONS
Topics:
...
EOF_PLAN

# STEP 4: Validate invocation plan file exists (proves STEP 2.5 executed)
if [ ! -f "$INVOCATION_PLAN_FILE" ]; then
  echo "CRITICAL ERROR: Invocation plan file missing - STEP 2.5 was skipped" >&2
  exit 1
fi

# Validate trace file exists (proves STEP 3 executed)
TRACE_COUNT=$(grep -c "Status: INVOKED" "$TRACE_FILE" 2>/dev/null || echo 0)
if [ "$TRACE_COUNT" -ne "$EXPECTED_INVOCATIONS" ]; then
  echo "ERROR: Trace count mismatch - invoked $TRACE_COUNT Task(s), expected $EXPECTED_INVOCATIONS" >&2
  exit 1
fi
```

**Impact**: Coordinator's self-validation is robust and prevents silent failures. The /research command's Block 1e validation is redundant - it re-checks what the coordinator already validated. This creates unnecessary duplication.

---

### Finding 6: Research-Specialist Behavioral File Is Standards-Compliant

**Description**: Research-specialist agent (research-specialist.md) follows hard barrier pattern with 5-step workflow: (1) receive path, (2) create file FIRST, (3) conduct research, (4) validate sections, (5) return confirmation. All 28 completion criteria documented.

**Location**: `/home/benjamin/.config/.claude/agents/research-specialist.md` (Lines 1-543)

**Evidence**:
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST

**EXECUTE NOW - Create Report File**

**ABSOLUTE REQUIREMENT**: YOU MUST create the report file NOW using the Write tool.
Create it with initial structure BEFORE conducting any research.

**WHY THIS MATTERS**: Creating the file first guarantees artifact creation even if
research encounters errors. This is the PRIMARY task.
```

**Impact**: Research-specialist is reliable and does not require changes. The agent correctly prioritizes file creation over research content, ensuring artifacts exist even on partial failures.

---

### Finding 7: Hierarchical Architecture Documentation Is Comprehensive

**Description**: Documentation in `.claude/docs/concepts/hierarchical-agents-*.md` includes 8 examples, with Example 7 specifically covering research-coordinator pattern with 95% context reduction metrics and integration points.

**Location**: `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Lines 545-891)

**Evidence**:
```markdown
## Example 7: Research Coordinator with Parallel Multi-Topic Research

**Status**: IMPLEMENTED (as of 2025-12-08)

**Command Integration Status**:
- `/create-plan`: ✓ Integrated (Phase 1, Phase 2 - automated topic detection)
- `/research`: ✓ Integrated (Phase 3)
- `/lean-plan`: ✗ Not Integrated (uses lean-research-specialist directly)

### Context Reduction Metrics

**Traditional Approach** (primary agent reads all reports):
3 reports x 2,500 tokens = 7,500 tokens consumed

**Coordinator Approach** (metadata-only):
3 reports x 110 tokens metadata = 330 tokens consumed
Context reduction: 95.6%
```

**Impact**: Documentation confirms /research command is already optimized with coordinator delegation. No additional documentation work required beyond updating integration status notes.

---

### Finding 8: Integration Guide Provides Clear Troubleshooting

**Description**: Research-coordinator integration guide (research-coordinator-integration-guide.md) documents empty directory troubleshooting, partial completion handling, and coordinator bug fixes from 2025-12-09.

**Location**: `/home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md` (Lines 116-182)

**Evidence**:
```markdown
### Fixed Issues

#### Coordinator Early Return Bug (Fixed 2025-12-09)

**Problem**: Research-coordinator was skipping Task invocations in STEP 3...
**Root Cause**: STEP 3 used placeholder syntax that agent interpreted as documentation
**Fix Applied**:
1. STEP 3 Refactor: Bash-generated concrete Task invocations
2. STEP 2.5 Addition: Pre-execution validation barrier
3. STEP 4 Enhancement: Multi-layer validation
4. Error Trap Handler: Mandatory TASK_ERROR signal

**Impact**: Coordinator now achieves 100% invocation rate with no silent failures.
```

**Impact**: Recent fixes (2025-12-09) have already hardened coordinator reliability. No additional error handling architecture needed - current implementation is production-ready.

---

## Recommendations

### Recommendation 1: Align /research Validation with Coordinator Partial Success Mode

**Priority**: HIGH
**Effort**: LOW (1-2 hours)

Update Block 1e validation (Lines 1218-1313) to support partial success:

```bash
# Replace all-or-nothing pattern with ≥50% threshold
SUCCESS_PERCENTAGE=$((SUCCESSFUL_REPORTS * 100 / TOTAL_EXPECTED))

if [ $SUCCESS_PERCENTAGE -lt 50 ]; then
  log_command_error "validation_error" \
    "Research validation failed: <50% success rate" \
    "Only $SUCCESSFUL_REPORTS/$TOTAL_EXPECTED reports created"
  exit 1
fi

if [ $SUCCESS_PERCENTAGE -lt 100 ]; then
  echo "WARNING: Partial research success (${SUCCESS_PERCENTAGE}%)" >&2
  echo "Proceeding with $SUCCESSFUL_REPORTS/$TOTAL_EXPECTED reports..." >&2
fi
```

**Rationale**: Aligns command behavior with coordinator's documented partial success mode, preventing waste of partial research results. Critical for reliability when WebSearch rate limits are hit or specific topics fail.

---

### Recommendation 2: Remove Single-Topic Fallback Path for Consistency

**Priority**: MEDIUM
**Effort**: LOW (30 minutes)

Remove lines 875-888 fallback logic. Always invoke coordinator with topics array, even for single-topic research:

```bash
# Remove this block:
if [ ${#TOPICS_ARRAY[@]} -lt 2 ]; then
  echo "Decomposition produced ${#TOPICS_ARRAY[@]} topics (less than 2), falling back to single-topic mode"
  USE_MULTI_TOPIC=false
  TOPICS_ARRAY=("$WORKFLOW_DESCRIPTION")
fi

# Always use coordinator (handles 1-N topics uniformly)
```

**Rationale**: Simplifies architecture by eliminating conditional logic. Coordinator agent already handles single-topic mode correctly - treating it as "1-element array" requires no special case code.

---

### Recommendation 3: Reduce Block 1e Validation Redundancy

**Priority**: LOW
**Effort**: LOW (30 minutes)

Simplify Block 1e to only validate coordinator completion signal, not re-check report files:

```bash
# Remove detailed file validation (coordinator already did this in STEP 4)
# Keep only:
# 1. Parse RESEARCH_COMPLETE signal
# 2. Extract metadata JSON
# 3. Persist metadata for downstream consumers

# Trust coordinator's validation - it's the authority on report creation
```

**Rationale**: Eliminates redundant validation that duplicates coordinator's STEP 4 checks. Reduces bash block size by ~50 lines. Improves maintainability by having single source of truth (coordinator) for validation logic.

---

### Recommendation 4: Enhance Topic Decomposition with LLM Agent (Optional)

**Priority**: LOW (OPTIONAL)
**Effort**: MEDIUM (2-4 hours)

Add topic-decomposer-agent.md behavioral file for semantic topic boundary detection:

```yaml
# Invoke before research-coordinator
Task {
  description: "Decompose research request into semantic topics"
  prompt: "
    Read and follow: .claude/agents/topic-decomposer-agent.md

    Research Request: ${WORKFLOW_DESCRIPTION}
    Complexity: ${RESEARCH_COMPLEXITY}
    Target Topic Count: ${TOPIC_COUNT}

    Return JSON:
    {
      'topics': ['Topic 1', 'Topic 2', 'Topic 3'],
      'decomposition_rationale': 'Brief explanation'
    }
  "
}
```

**Rationale**: Improves topic decomposition quality beyond simple string splitting. However, current heuristic approach works adequately for most cases - this is optimization, not critical fix.

---

### Recommendation 5: Document /research as Reference Implementation

**Priority**: MEDIUM
**Effort**: LOW (1 hour)

Update `.claude/docs/concepts/hierarchical-agents-examples.md` Example 7 to reference /research command as canonical implementation:

```markdown
## Example 7: Research Coordinator Pattern - Reference Implementation

**Status**: IMPLEMENTED (as of 2025-12-08)

**Reference Command**: `/research` (`.claude/commands/research.md`)
- Lines 752-935: Topic decomposition with complexity-based count
- Lines 1099-1145: Coordinator invocation (Mode 2 - Pre-Decomposed)
- Lines 1152-1319: Hard barrier validation

**See Also**:
- [/research command source](../../commands/research.md)
- [Research coordinator integration guide](../../guides/agents/research-coordinator-integration-guide.md)
```

**Rationale**: Provides concrete reference for other commands implementing coordinator pattern. Reduces documentation duplication by pointing to working implementation.

---

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/research.md` (Lines 1-1577) - Current /research command implementation
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (Lines 1-963) - Coordinator agent behavioral file
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (Lines 1-828) - Specialist agent behavioral file
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (Lines 1-177) - Architecture overview
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Lines 545-891) - Example 7: Research coordinator pattern
- `/home/benjamin/.config/.claude/docs/guides/agents/research-coordinator-integration-guide.md` (Lines 1-252) - Integration patterns and troubleshooting

### Key Metrics

- **Current Context Reduction**: 95% (110 tokens per report vs 2,500 tokens full content)
- **Parallel Execution**: 2-5 research-specialist agents invoked simultaneously
- **Time Savings**: 40-60% vs sequential research invocation
- **Reliability**: 100% invocation rate (as of 2025-12-09 fixes)
- **Coordinator Validation Layers**: 3 (invocation plan file, trace file, report files)

### External Sources

None (codebase analysis only)

# Research Report: /lean-implement Command Error Analysis

**Date**: 2024-12-04
**Research Topic**: Root cause analysis of /lean-implement execution errors from lean-implement-output-2.md
**Complexity**: 2 (Medium)

---

## Executive Summary

Analysis of `/lean-implement` output reveals the command executed **successfully** for the specific use case tested (software-only phases), but exposed several architectural patterns that differ from the standard `/implement` command and could cause issues in more complex scenarios.

The output shows:
- 4 phases (4-7) completed successfully
- Phase classification worked after manual override
- Summary files created and validated
- All hard barriers passed

However, the research identified **systemic architectural differences** that warrant improvement.

---

## Findings

### 1. Phase Number Detection and Regex Issues

**Observation**: The phase extraction logic failed initially with "Phase 1: [SKIPPED - no content]" errors, despite phases 4-7 existing in the plan.

**Root Cause**: The plan being executed was a "continuation plan" starting at Phase 4, but the classifier iterated from 1 to TOTAL_PHASES assuming contiguous numbering.

**Location**: `.claude/commands/lean-implement.md` Block 1a-classify:
```bash
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
  PHASE_CONTENT=$(awk -v target="$phase_num" '...)
```

**Fix Pattern (from /implement)**: The `/implement` command handles this by extracting actual phase numbers from the plan:
```bash
PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+")
```

**Impact**: Commands handling continuation plans or non-contiguous phase numbering will fail classification.

---

### 2. Phase Classification Tier Mismatch

**Observation**: The 2-tier classification algorithm incorrectly classified software phases as "lean" because they mentioned `.lean` file extensions in task descriptions.

**Output Evidence**:
```
Phase numbers found: 4 5 6 7
Total phases: 4
```

With phases 4-5 initially classified as "lean" due to `.lean` extension detection in the task descriptions (which describe files to modify, not theorem proving).

**Root Cause**: Tier 2 keyword detection (`grep -qiE '\.(lean)\b'`) triggers on file paths mentioned in task descriptions, not just on actual Lean theorem-proving indicators.

**Comparison to /implement**: The `/implement` command doesn't have this issue because it treats all phases uniformly as software phases.

**Recommended Fix**: Add Tier 0 detection for `implementer:` field in phase metadata:
```markdown
### Phase 4: Update Test Files [NOT STARTED]
implementer: software

Tasks:
- [ ] Update .lean files with new operator names
```

The lean-implement.md already documents this but relies on Tier 2 keyword fallback which is error-prone.

---

### 3. Hard Barrier Validation Timing Difference

**Observation**: `/lean-implement` uses a different hard barrier pattern than `/research` and `/create-plan`.

**Pattern Comparison**:

| Command | Pattern | Pre-calculation | Validation Timing |
|---------|---------|-----------------|-------------------|
| /research | Hard Barrier v2 | Yes (REPORT_PATH pre-calculated) | Block 1e validates REPORT_PATH |
| /create-plan | Hard Barrier v2 | Yes (PLAN_PATH pre-calculated) | Block validates PLAN_PATH |
| /implement | Implicit | No | Block 1c validates SUMMARIES_DIR/* |
| /lean-implement | Mixed | Partial | Block 1c validates SUMMARIES_DIR/* |

**Finding**: `/lean-implement` inherits the `/implement` pattern of validating "any summary in SUMMARIES_DIR" rather than a pre-calculated specific path. This is less strict but more flexible for multi-phase operations.

**Assessment**: Current pattern is acceptable for orchestrator commands where multiple summaries may be created. Not a bug.

---

### 4. Routing Map Persistence Pattern

**Observation**: `/lean-implement` stores the routing map in a workspace file, which is a good pattern:

```bash
echo "$ROUTING_MAP" > "${LEAN_IMPLEMENT_WORKSPACE}/routing_map.txt"
```

**Comparison**: This matches the pattern used by `/implement` for iteration context and is more robust than shell variable persistence for multi-value data.

**Assessment**: Good architecture choice.

---

### 5. State ID File Path Consistency

**Observation**: Both commands correctly use `CLAUDE_PROJECT_DIR` for state ID files:

```bash
# /lean-implement
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/lean_implement_state_id.txt"

# /implement
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/implement_state_id.txt"
```

**Assessment**: Correct pattern. The `/research` command had issues with path mismatch between HOME and CLAUDE_PROJECT_DIR, but orchestrator commands are consistent.

---

### 6. Missing Pre-Flight Validation for Lean Tools

**Observation**: `/lean-implement` validates library functions but doesn't validate Lean-specific dependencies.

**Missing Checks**:
- lean_build MCP availability (for compilation verification)
- lean_local_search availability (for proof search)
- Mathlib project detection

**Comparison**: `/implement` has comprehensive pre-flight validation:
```bash
validate_implement_prerequisites() {
  # Validates library functions
  if ! declare -F save_completed_states_to_state >/dev/null 2>&1; then
    ...
  fi
}
```

**Recommended Addition** for `/lean-implement`:
```bash
validate_lean_prerequisites() {
  # Check MCP tools available (graceful degradation)
  if ! command -v lake &>/dev/null; then
    echo "WARNING: lake not found - Lean builds may fail" >&2
  fi
}
```

---

### 7. Progress Tracking Instruction Forwarding

**Observation**: The lean-coordinator agent documents progress tracking instruction forwarding to lean-implementer, but the actual invocation prompt in `/lean-implement` doesn't consistently include these instructions.

**Block 1b Task invocation**:
```markdown
Progress Tracking Instructions:
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before starting phase: add_in_progress_marker '${PLAN_FILE}' ${CURRENT_PHASE}
```

**Assessment**: Instructions are present but may benefit from consolidation into the agent's behavioral guidelines rather than repeated in each invocation.

---

### 8. work_remaining Format Consistency

**Observation**: Both agents (lean-coordinator and implementer-coordinator) document the same output format requirements:

```yaml
# CORRECT
work_remaining: Phase_4 Phase_5 Phase_6  # Space-separated string

# WRONG
work_remaining: [Phase 4, Phase 5, Phase 6]  # JSON array triggers state_error
```

**Assessment**: Documentation is correct. The defensive conversion in `/implement` Block 1c handles legacy outputs:
```bash
if [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
  echo "INFO: Converting WORK_REMAINING from JSON array to space-separated string" >&2
```

**Recommendation**: Add same defensive conversion to `/lean-implement` Block 1c.

---

## Comparative Analysis: /lean-implement vs /implement

### Structural Similarities

| Aspect | /implement | /lean-implement |
|--------|-----------|-----------------|
| Block structure | 1a, 1c, 1d, 2 | 1a, 1a-classify, 1b, 1c, 1d, 2 |
| State machine | workflow-state-machine.sh | workflow-state-machine.sh |
| Hard barrier | Summary in SUMMARIES_DIR | Summary in SUMMARIES_DIR |
| Iteration loop | Yes (configurable) | Yes (configurable) |

### Key Differences

| Aspect | /implement | /lean-implement |
|--------|-----------|-----------------|
| Phase classification | None (all software) | 2-tier (lean vs software) |
| Routing | Single coordinator | Routing map (lean/software) |
| Additional block | None | Block 1a-classify |
| Coordinator | implementer-coordinator | lean-coordinator OR implementer-coordinator |

---

## Systematic Improvement Recommendations

### Priority 1: Phase Number Extraction Fix

**File**: `.claude/commands/lean-implement.md` Block 1a-classify

**Current**:
```bash
for phase_num in $(seq 1 "$TOTAL_PHASES"); do
```

**Proposed**:
```bash
# Extract actual phase numbers from plan (handles continuation plans)
PHASE_NUMBERS=$(grep -oE "^### Phase ([0-9]+):" "$PLAN_FILE" | grep -oE "[0-9]+")
for phase_num in $PHASE_NUMBERS; do
```

### Priority 2: Defensive work_remaining Conversion

**File**: `.claude/commands/lean-implement.md` Block 1c

**Add**:
```bash
# === DEFENSIVE WORK_REMAINING FORMAT CONVERSION ===
if [ -n "$WORK_REMAINING" ] && [[ "$WORK_REMAINING" =~ ^[[:space:]]*\[ ]]; then
  echo "INFO: Converting WORK_REMAINING from JSON array to space-separated string" >&2
  WORK_REMAINING_CLEAN="${WORK_REMAINING#[}"
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN%]}"
  WORK_REMAINING_CLEAN="${WORK_REMAINING_CLEAN//,/}"
  WORK_REMAINING_CLEAN=$(echo "$WORK_REMAINING_CLEAN" | tr -s ' ')
  WORK_REMAINING="$WORK_REMAINING_CLEAN"
fi
```

### Priority 3: Implementer Field in Plan Metadata

**File**: `.claude/docs/reference/standards/plan-metadata-standard.md`

**Add new optional phase field**:
```markdown
### Phase-Level Fields (Optional)

| Field | Format | Required | Description |
|-------|--------|----------|-------------|
| implementer | `lean` \| `software` | No | Explicit routing override for hybrid workflows |
```

### Priority 4: Pre-Flight Validation Enhancement

**File**: `.claude/commands/lean-implement.md` Block 1a

**Add**:
```bash
validate_lean_implement_prerequisites() {
  local validation_errors=0

  # Standard library validations (existing)
  # ...

  # Lean-specific validations (graceful degradation)
  if [ "$EXECUTION_MODE" != "software-only" ]; then
    if ! command -v lake &>/dev/null 2>&1; then
      echo "WARNING: lake command not found - Lean compilation may fail" >&2
    fi
  fi

  return $validation_errors
}
```

---

## Infrastructure Integration Opportunities

### 1. Shared Routing Utilities

Create `.claude/lib/workflow/phase-routing.sh`:
```bash
# Phase classification utilities shared across hybrid commands
classify_phase_type() {
  local phase_content="$1"
  local phase_num="$2"
  # Unified 3-tier classification
}

extract_phase_numbers() {
  local plan_file="$1"
  grep -oE "^### Phase ([0-9]+):" "$plan_file" | grep -oE "[0-9]+"
}
```

### 2. Documentation Updates

**Files to update**:
- `.claude/docs/guides/commands/lean-implement-command-guide.md` - Add troubleshooting for continuation plans
- `.claude/docs/reference/standards/plan-progress.md` - Document `implementer:` field
- `.claude/docs/reference/standards/command-reference.md` - Ensure /lean-implement entry is current

### 3. Validation Script Integration

Add to `.claude/scripts/validate-all-standards.sh`:
```bash
# Validate phase routing consistency
validate_phase_routing() {
  # Check commands using phase classification have consistent patterns
}
```

---

## Conclusion

The `/lean-implement` command functions correctly for the tested scenario but has architectural patterns that could cause issues in edge cases:

1. **Phase number extraction** assumes contiguous numbering (breaks continuation plans)
2. **Tier 2 classification** is overly aggressive on `.lean` extension matching
3. **Defensive conversions** present in /implement are missing

The recommended improvements are incremental and can be implemented without breaking existing functionality. The routing map pattern and hard barrier validation are well-designed and consistent with project standards.

---

## Artifacts

- Plan file tested: `/home/benjamin/Documents/Philosophy/Projects/ProofChecker/.claude/specs/038_temporal_conventions_refactor/plans/002-temporal-refactor-completion-plan.md`
- Output analyzed: `/home/benjamin/.config/.claude/output/lean-implement-output-2.md`

## Next Steps

1. Create implementation plan: `/create-plan "Fix lean-implement phase extraction and defensive conversions"`
2. Update documentation: Revise lean-implement-command-guide.md
3. Test with continuation plan: Re-run /lean-implement on a continuation plan after fixes

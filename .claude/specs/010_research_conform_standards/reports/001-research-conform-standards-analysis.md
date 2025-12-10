# Research Report: /research Command Error Analysis

**Date**: 2025-12-09
**Topic**: Research command bash array handling errors
**Status**: COMPLETE

## Executive Summary

The `/research` command fails with bash array errors due to **TWO DISTINCT ROOT CAUSES**:

1. **PRIMARY**: Bash block size >400 lines causes preprocessing transformation bugs with special syntax (`${!ARRAY[@]}`)
2. **SECONDARY**: Missing explicit `declare -a` array declarations (pattern inconsistency with `/create-plan`)

Both issues combine to create the observed failure pattern.

---

## Error Analysis

### Observed Errors

From `/home/benjamin/.config/.claude/output/research-output.md`:

```
Exit code 127 with bash errors:
- Line 383: ${\!TOPICS_ARRAY[@]}: bad substitution
- Line 397: ${\!TOPICS_ARRAY[@]}: bad substitution
- Line 416: REPORT_PATHS_ARRAY[0]: unbound variable
```

Error location: Block 1c (Topic Path Initialization) in research.md

### Error Context

The error occurred during Block 1 execution at approximately line 504 in the bash block:

```bash
for i in "${!TOPICS_ARRAY[@]}"; do
  TOPIC="${TOPICS_ARRAY[$i]}"
  # ...
done
```

---

## Root Cause Analysis

### Root Cause #1: Bash Block Size Exceeds 400-Line Threshold

**Finding**: Block 1 in `/research` command spans **501 lines** (line 45-546 in research.md)

**Evidence from Standards**:
- `.claude/docs/troubleshooting/bash-tool-limitations.md` lines 160-188 documents preprocessing transformation bugs
- **Threshold**: Blocks >400 lines exhibit transformation errors with special bash syntax
- **Affected patterns**: `${!varname}`, `${!array[@]}`, history expansion despite `set +H`

**Why This Matters**:
Claude's Bash tool appears to transform large bash blocks during execution, and this transformation process incorrectly escapes or mangles special bash syntax like `${!TOPICS_ARRAY[@]}` → `${\!TOPICS_ARRAY[@]}` (note the backslash).

**Evidence from Error Output**:
The error shows `${\!TOPICS_ARRAY[@]}` (escaped exclamation) instead of `${!TOPICS_ARRAY[@]}`, indicating preprocessing transformation corruption.

### Root Cause #2: Missing Explicit Array Declarations

**Finding**: `/research` uses implicit array initialization while `/create-plan` uses explicit `declare -a`

**Comparison**:

| Command | Array Declaration Pattern | Location |
|---------|--------------------------|----------|
| `/research` | `TOPICS_ARRAY=()` | research.md:457 |
| `/research` | `REPORT_PATHS_ARRAY=()` | research.md:503 |
| `/create-plan` | `declare -a TOPICS_ARRAY=()` | create-plan.md:1299 |
| `/create-plan` | `declare -a REPORT_PATHS_ARRAY=()` | create-plan.md:1300 |
| `/implement` | `read -ra ARGS_ARRAY <<<` | implement.md:157 |

**Why This Matters**:
Explicit `declare -a` declarations ensure bash treats variables as arrays from initialization, preventing unbound variable errors and providing better error messages during debugging.

**Evidence from Standards**:
- `.claude/docs/troubleshooting/bash-tool-limitations.md:42`: Lists `declare -a ARRAY` as supported pattern
- `.claude/docs/concepts/bash-block-execution-model.md:574`: Shows `declare -ga COMPLETED_STATES=()` as standard pattern for arrays

### Interaction Between Root Causes

The two issues compound each other:
1. **Large block preprocessing** corrupts `${!ARRAY[@]}` syntax → bash can't expand array indices
2. **Implicit array declaration** means bash doesn't recognize TOPICS_ARRAY as array type → "unbound variable" on access
3. Result: Cascading failures at lines 383, 397 (bad substitution) and 416 (unbound variable)

---

## Working Pattern Analysis

### /create-plan Success Pattern

**File**: `/home/benjamin/.config/.claude/commands/create-plan.md`

**Block Structure**:
- Block 1a: ~100 lines (argument capture, library sourcing)
- Block 1b: ~150 lines (topic detection agent invocation)
- Block 1c: ~300 lines (topic decomposition, report path calculation)
- Block 2: Task delegation (research-coordinator/research-specialist)

**Key Differences from /research**:
1. **Smaller blocks**: Each block <400 lines
2. **Explicit declarations**: `declare -a TOPICS_ARRAY=()` at line 1299
3. **Block boundaries**: Natural separation prevents large block issues

**Array Handling Pattern** (create-plan.md:1295-1338):
```bash
TOPIC_COUNT=1
declare -a TOPICS_ARRAY=()
declare -a REPORT_PATHS_ARRAY=()

# Build arrays
for i in $(seq 0 $((TOPIC_COUNT - 1))); do
  TOPICS_ARRAY+=("$TITLE: $SCOPE")
  REPORT_PATHS_ARRAY+=("${RESEARCH_DIR}/${REPORT_FILENAME}")
done
```

### /implement Success Pattern

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Array Handling** (implement.md:157-185):
```bash
read -ra ARGS_ARRAY <<< "$IMPLEMENT_ARGS"
PLAN_FILE="${ARGS_ARRAY[0]:-}"
STARTING_PHASE="${ARGS_ARRAY[1]:-1}"

for arg in "${ARGS_ARRAY[@]:2}"; do
  case "$arg" in
    --dry-run) DRY_RUN="true" ;;
  esac
done

# Safe iteration with bounds checking
for i in "${!ARGS_ARRAY[@]}"; do
  if [ "${ARGS_ARRAY[$i]}" = "--resume" ]; then
    RESUME_CHECKPOINT="${ARGS_ARRAY[$((i+1))]:-}"
  fi
done
```

**Key Success Factors**:
1. `read -ra` implicitly declares array type
2. Safe parameter expansion with `:-` defaults
3. Quoted expansions: `"${!ARGS_ARRAY[@]}"` prevents word splitting
4. Block size <200 lines (no preprocessing issues)

---

## Standards Review

### Bash Block Execution Model

**Source**: `.claude/docs/concepts/bash-block-execution-model.md`

**Lines 550-574** document array limitations:
```
When NOT to Use [conditional initialization]:
- Arrays (parameter expansion syntax not supported: declare -ga ARRAY=())

# Arrays cannot use conditional initialization
declare -ga COMPLETED_STATES=()  # Array syntax incompatible with ${VAR:-}
```

**Implication**: Arrays must be declared with `declare -a` or `declare -ga` for global scope.

### Bash Tool Limitations

**Source**: `.claude/docs/troubleshooting/bash-tool-limitations.md`

**Lines 160-189** document large block preprocessing bugs:

**Symptoms**:
- `bash: ${\\!varname}: bad substitution` errors
- Only occurs with blocks >400 lines
- Same code works in blocks <200 lines

**Solution** (line 189):
> Split Large Bash Blocks

**Lines 42** lists supported patterns:
- `declare -a ARRAY` ✓ (supported)

### Command Authoring Standards

**Source**: `.claude/docs/reference/standards/command-authoring.md`

Reviewed for array handling patterns - no explicit array declaration requirements documented, but examples use `declare -a` pattern.

---

## Recommended Fixes

### Fix #1: Split Block 1 into Smaller Blocks (CRITICAL)

**Priority**: P0 (blocks all /research usage)

**Action**: Refactor Block 1 (501 lines) into 3 smaller blocks:
- Block 1a: Argument capture, state initialization (~100 lines)
- Block 1b: Topic naming agent invocation (~50 lines)
- Block 1c: Topic decomposition and report path calculation (~200 lines)

**Rationale**: Keeps all blocks under 400-line threshold to avoid preprocessing transformation bugs

**Pattern Source**: `/create-plan` command uses this exact structure successfully

### Fix #2: Add Explicit Array Declarations (RECOMMENDED)

**Priority**: P1 (improves reliability)

**Action**: Replace implicit array initialization with explicit declarations:

**Before** (research.md:457):
```bash
TOPICS_ARRAY=()
```

**After**:
```bash
declare -a TOPICS_ARRAY=()
```

**Locations**:
- Line 457: `TOPICS_ARRAY=()` → `declare -a TOPICS_ARRAY=()`
- Line 503: `REPORT_PATHS_ARRAY=()` → `declare -a REPORT_PATHS_ARRAY=()`

**Rationale**:
- Ensures bash treats variables as array type from initialization
- Provides better error messages during debugging
- Matches pattern used in `/create-plan` (line 1299-1300)
- Documented as supported pattern in bash-tool-limitations.md

### Fix #3: Add Array Bounds Checking (DEFENSIVE)

**Priority**: P2 (defensive programming)

**Action**: Add bounds checking before array access at line 538:

**Before** (research.md:538):
```bash
REPORT_PATH="${REPORT_PATHS_ARRAY[0]}"
```

**After**:
```bash
if [ ${#REPORT_PATHS_ARRAY[@]} -eq 0 ]; then
  echo "ERROR: REPORT_PATHS_ARRAY is empty" >&2
  exit 1
fi
REPORT_PATH="${REPORT_PATHS_ARRAY[0]}"
```

**Rationale**: Prevents "unbound variable" errors if array is unexpectedly empty

### Fix #4: Quote Array Expansions (BEST PRACTICE)

**Priority**: P2 (robustness)

**Action**: Ensure all array expansions are properly quoted:

**Pattern**:
```bash
# Index expansion (already correct in research.md)
for i in "${!TOPICS_ARRAY[@]}"; do  # ✓ Quoted

# Element access (already correct)
echo "${TOPICS_ARRAY[$i]}"  # ✓ Quoted
```

**Verification**: research.md already uses correct quoting at lines 483-484, 504-505

---

## Implementation Plan Outline

### Phase 1: Block Splitting (CRITICAL PATH)

**Tasks**:
1. Identify natural split points in Block 1 (lines 45-546)
2. Create Block 1a: Argument capture + state init (lines 45-200)
3. Create Block 1b: Topic naming agent (lines 201-250)
4. Create Block 1c: Topic decomposition + report paths (lines 251-450)
5. Update block transitions with proper state persistence
6. Test all code paths (single-topic and multi-topic modes)

**Success Criteria**:
- All blocks <400 lines
- No preprocessing transformation errors
- Arrays populate correctly across block boundaries

### Phase 2: Array Declaration Updates

**Tasks**:
1. Add `declare -a TOPICS_ARRAY=()` at line 457
2. Add `declare -a REPORT_PATHS_ARRAY=()` at line 503
3. Test array access patterns

### Phase 3: Defensive Checks

**Tasks**:
1. Add bounds checking before `REPORT_PATHS_ARRAY[0]` access
2. Add validation after topic decomposition
3. Add error logging for array-related failures

### Phase 4: Documentation Updates

**Tasks**:
1. Update research-command-guide.md with block structure
2. Document array handling patterns in command
3. Add troubleshooting section for array errors

---

## Testing Strategy

### Test Case 1: Single-Topic Mode (Complexity <3)
```bash
/research "simple research topic" --complexity 2
```
**Expected**: TOPICS_ARRAY has 1 element, REPORT_PATHS_ARRAY has 1 element

### Test Case 2: Multi-Topic Mode (Complexity >=3)
```bash
/research "topic1 and topic2 and topic3" --complexity 3
```
**Expected**: TOPICS_ARRAY has 3 elements, REPORT_PATHS_ARRAY has 3 elements

### Test Case 3: Edge Case - Empty Decomposition
**Scenario**: Decomposition produces <2 topics, fallback to single-topic mode
**Expected**: Arrays reset correctly, no unbound variable errors

---

## References

### Primary Sources
1. `/home/benjamin/.config/.claude/output/research-output.md` - Error output
2. `/home/benjamin/.config/.claude/commands/research.md` - Failing command
3. `/home/benjamin/.config/.claude/commands/create-plan.md` - Working pattern
4. `/home/benjamin/.config/.claude/commands/implement.md` - Working array handling

### Standards Documentation
1. `.claude/docs/troubleshooting/bash-tool-limitations.md` (lines 160-189, 42)
2. `.claude/docs/concepts/bash-block-execution-model.md` (lines 550-574)
3. `.claude/docs/reference/standards/command-authoring.md`

### Related Patterns
1. `.claude/docs/concepts/hierarchical-agents-examples.md` (line 38) - Array declaration example
2. `.claude/docs/troubleshooting/coordinator-agent-failures.md` (line 220) - Array length checking

---

## Appendix: Error Timeline

1. **User invokes**: `/research "proof automation deferred blockers" --complexity 3`
2. **Block 1a-1b complete**: State initialized, topic name generated successfully
3. **Block 1c execution**: Bash interprets 501-line block
4. **Preprocessing corruption**: `${!TOPICS_ARRAY[@]}` → `${\!TOPICS_ARRAY[@]}`
5. **Line 383 error**: Bad substitution in topic decomposition loop
6. **Line 397 error**: Bad substitution in report path calculation loop
7. **Line 416 error**: Unbound variable accessing REPORT_PATHS_ARRAY[0]
8. **Exit code 127**: Bash syntax error prevents further execution

---

**Research Complete**: 2025-12-09
**Confidence Level**: High (multiple confirming sources)
**Recommended Action**: Implement Fix #1 (block splitting) immediately, Fix #2 (array declarations) as part of same PR

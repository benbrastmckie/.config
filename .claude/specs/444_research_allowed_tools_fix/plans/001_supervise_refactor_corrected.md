# Supervise Command Refactor - Corrected Implementation Plan

## Metadata
- **Date**: 2025-10-24
- **Purpose**: Corrected refactor plan for /supervise command with verified search patterns
- **Context**: Fixes pattern mismatch identified in spec 444 diagnostic report
- **Classification Reference**: `supervise_yaml_classification.md` (Task 2.1)
- **Target File**: `.claude/commands/supervise.md` (2,520 lines)

## Overview

This plan corrects the blocked refactor from spec 438/001 by using actual patterns found in supervise.md instead of assumed patterns. The diagnostic report (spec 444/001/OVERVIEW.md) identified that search pattern "Example agent invocation:" does not exist in the file, preventing implementation.

**Key Changes from Spec 438**:
1. **Phase 0**: Added pattern verification step (catches mismatches before implementation)
2. **Search Patterns**: Use actual ` ```yaml` + `Task {` patterns (not "Example agent invocation:")
3. **Target State**: 2 YAML blocks retained (documentation examples), 5 removed (agent templates)
4. **Regression Test**: Fixed to detect actual patterns

---

## Phase 0: Pattern Verification (NEW - CRITICAL)

**Objective**: Verify search patterns exist before attempting implementation

**Rationale**: Prevents wasted effort from pattern mismatches (as occurred in spec 438)

### Tasks

**Task 0.1: Verify YAML Block Count**

```bash
# Count total YAML code fences
YAML_COUNT=$(grep -c '```yaml' .claude/commands/supervise.md)
echo "Total ```yaml blocks found: $YAML_COUNT"

# Expected: 7 blocks before refactor
if [ "$YAML_COUNT" -ne 7 ]; then
  echo "ERROR: Expected 7 YAML blocks, found $YAML_COUNT"
  echo "File may have been modified. Review classification before proceeding."
  exit 1
fi
```

**Task 0.2: Verify Non-Existence of Assumed Pattern**

```bash
# Test for "Example agent invocation:" pattern (should NOT exist)
EXAMPLE_COUNT=$(grep -c "Example agent invocation:" .claude/commands/supervise.md)
echo "Pattern 'Example agent invocation:' found: $EXAMPLE_COUNT"

# Expected: 0 (this pattern does not exist)
if [ "$EXAMPLE_COUNT" -ne 0 ]; then
  echo "WARNING: Unexpected pattern found. Plan may need revision."
fi
```

**Task 0.3: Verify YAML + Task Pattern**

```bash
# Count YAML blocks that contain Task invocations
# This is what we actually need to refactor
YAML_TASK_COUNT=$(awk '
  /```yaml/{flag=1; yaml=""}
  flag{yaml=yaml $0 "\n"}
  /```$/{
    if(flag && yaml ~ /Task \{/){
      count++
    }
    flag=0
  }
  END{print count+0}
' .claude/commands/supervise.md)

echo "YAML blocks with 'Task {' invocation: $YAML_TASK_COUNT"

# Expected: 7 (all blocks contain Task invocations)
if [ "$YAML_TASK_COUNT" -ne 7 ]; then
  echo "ERROR: Expected 7 YAML+Task blocks, found $YAML_TASK_COUNT"
  exit 1
fi
```

**Task 0.4: Verify Specific Line Locations**

```bash
# Verify YAML blocks at expected line numbers
EXPECTED_LINES=(49 63 682 1082 1440 1721 2246)
ACTUAL_LINES=($(awk '/```yaml/{print NR}' .claude/commands/supervise.md))

echo "Expected YAML block line numbers: ${EXPECTED_LINES[@]}"
echo "Actual YAML block line numbers:   ${ACTUAL_LINES[@]}"

# Compare arrays
if [ "${#EXPECTED_LINES[@]}" -ne "${#ACTUAL_LINES[@]}" ]; then
  echo "ERROR: Line count mismatch"
  exit 1
fi

for i in "${!EXPECTED_LINES[@]}"; do
  if [ "${EXPECTED_LINES[$i]}" -ne "${ACTUAL_LINES[$i]}" ]; then
    echo "WARNING: Line number mismatch at position $i"
    echo "  Expected: ${EXPECTED_LINES[$i]}, Actual: ${ACTUAL_LINES[$i]}"
    echo "  File may have been edited. Review before proceeding."
  fi
done
```

**Success Criteria**:
- [ ] 7 YAML blocks found at expected line numbers
- [ ] 0 occurrences of "Example agent invocation:" (confirmed absence)
- [ ] 7 YAML blocks contain `Task {` invocations
- [ ] No errors from verification script

**If Verification Fails**: STOP and review. File may have been modified since classification (Task 2.1). Re-run classification before proceeding.

---

## Phase 1: Fix Documentation Examples (Lines 49-89)

**Objective**: Refactor Block 2 (lines 63-80) to remove behavioral duplication while keeping structural template

**Context**: Block 1 (lines 49-54) is clean and should remain unchanged. Block 2 demonstrates correct Task invocation pattern but includes inline STEP sequences that violate behavioral injection pattern.

### Task 1.1: Verify Block 2 Current State

Before making changes, extract and review Block 2:

```bash
# Extract Block 2 (lines 63-80)
sed -n '63,80p' .claude/commands/supervise.md

# Verify it contains STEP sequences
STEP_COUNT=$(sed -n '63,80p' .claude/commands/supervise.md | grep -c "STEP [0-9]")
echo "STEP instructions in Block 2: $STEP_COUNT"

# Expected: 4 (STEP 1/2/3/4)
if [ "$STEP_COUNT" -ne 4 ]; then
  echo "WARNING: Expected 4 STEP instructions, found $STEP_COUNT"
fi
```

### Task 1.2: Replace Block 2 with Lean Context Injection

**Current Content** (lines 63-80):
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
    STEP 2: Analyze workflow and research findings...
    STEP 3: Use Edit tool to develop implementation phases...
    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
  "
}
```

**Corrected Content** (behavioral injection pattern):
```yaml
# ✅ CORRECT - Behavioral injection pattern
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **CONTEXT INJECTION**:
    - Workflow: ${WORKFLOW_DESCRIPTION}
    - Report artifacts: ${REPORT_PATHS[@]}
    - Output path: ${PLAN_PATH}

    **EXECUTE NOW**: Create implementation plan at specified path following
    all procedures in plan-architect.md behavioral guidelines.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists.
  "
}
```

**Implementation**:

```bash
# Use Edit tool to replace Block 2
# Note: old_string must match EXACTLY (including indentation and newlines)
```

Due to the complexity of exact string matching with the Edit tool, **recommended approach**:

1. Extract lines 63-80 to temp file
2. Create corrected version in temp file
3. Use Edit tool with extracted strings

**Alternative**: Since this is a documentation example, we could also:
- Add a comment noting that STEP sequences are shown for illustration
- Add reference to proper behavioral injection pattern
- Keep the example but clarify it's not production usage

**Decision Required**: Should documentation example show:
- **Option A**: Perfect behavioral injection pattern (no STEP sequences) - pedagogically correct
- **Option B**: Pragmatic pattern with inline STEP for educational clarity - shows what agent will do

**Recommendation**: Option A (pure behavioral injection) to demonstrate best practice.

### Task 1.3: Verify Block 1 Remains Unchanged

```bash
# Verify Block 1 (lines 49-54) was not modified
sed -n '49,54p' .claude/commands/supervise.md | grep -q "SlashCommand"
if [ $? -eq 0 ]; then
  echo "✓ Block 1 intact (SlashCommand anti-pattern example)"
else
  echo "ERROR: Block 1 was modified"
  exit 1
fi
```

**Success Criteria**:
- [ ] Block 1 (lines 49-54) unchanged (SlashCommand example)
- [ ] Block 2 (lines 63-~75) refactored to use context injection only
- [ ] No STEP sequences in Block 2 (moved to agent behavioral file if needed)
- [ ] Documentation section still shows wrong vs. right pattern comparison

---

## Phase 2: Extract Agent Behavioral Content (Lines 682, 1082, 1440, 1721, 2246)

**Objective**: Replace 5 agent template YAML blocks with lean context injection references

**Context**: Per classification (Task 2.1), Blocks 3-7 are ~885 lines of behavioral duplication that should be ~60 lines of context injection.

### Task 2.1: Process Research Agent Template (Block 3, Lines 682-829)

**Current Pattern Detection**:
```bash
# Extract Block 3
START_LINE=682
END_LINE=829  # Approximate, find actual closing ```

# Find exact end of Block 3
END_LINE=$(awk -v start=682 'NR>start && /^```$/{print NR; exit}' .claude/commands/supervise.md)
echo "Block 3 ends at line: $END_LINE"

# Extract full block
sed -n "${START_LINE},${END_LINE}p" .claude/commands/supervise.md > /tmp/block3_original.txt

# Count lines
LINE_COUNT=$(wc -l < /tmp/block3_original.txt)
echo "Block 3 size: $LINE_COUNT lines"
```

**Step 1**: Verify `.claude/agents/research-specialist.md` contains required behavioral content

```bash
# Check if agent file exists and has STEP sequences
AGENT_FILE=".claude/agents/research-specialist.md"

if [ ! -f "$AGENT_FILE" ]; then
  echo "ERROR: $AGENT_FILE not found"
  echo "ACTION: Extract behavioral content from Block 3 before removing"
  exit 1
fi

# Verify agent file has behavioral content
STEP_COUNT=$(grep -c "STEP [0-9]" "$AGENT_FILE")
PRIMARY_COUNT=$(grep -c "PRIMARY OBLIGATION" "$AGENT_FILE")

echo "Agent file STEP instructions: $STEP_COUNT"
echo "Agent file PRIMARY OBLIGATION blocks: $PRIMARY_COUNT"

if [ "$STEP_COUNT" -eq 0 ]; then
  echo "WARNING: Agent file lacks STEP sequences"
  echo "ACTION: Extract from Block 3 and add to $AGENT_FILE"
fi
```

**Step 2**: Extract behavioral content if missing from agent file

If research-specialist.md is incomplete, extract key behavioral content from Block 3:

- PRIMARY OBLIGATION block (lines 690-703)
- STEP 1: File creation procedure (lines 706-737)
- STEP 2: Research methodology (lines 740-767)
- STEP 3: Report population (lines 771-800)
- STEP 4: Metadata return (lines 803-829)

Add to research-specialist.md using Edit tool.

**Step 3**: Replace Block 3 with lean context injection

**Current** (147 lines):
```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **PRIMARY OBLIGATION - File Creation**
    ...
    [145 lines of detailed procedures]
    ...
  "
}
```

**Corrected** (12 lines):
```yaml
# Research Agent Template (repeated for each topic)
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **CONTEXT**:
    - Topic: ${TOPIC_NAME}
    - Output path: ${REPORT_PATHS[i]}
    - Workflow: ${WORKFLOW_DESCRIPTION}
  "
}
```

**Implementation**:
```bash
# Use Edit tool to replace Block 3
# old_string: Lines 682-829 (exact text from file)
# new_string: Corrected 12-line version above
```

**Step 4**: Validate reduction

```bash
# Verify Block 3 replacement
NEW_BLOCK_END=$(awk -v start=682 'NR>start && /^```$/{print NR; exit}' .claude/commands/supervise.md)
NEW_LINE_COUNT=$((NEW_BLOCK_END - 682))

echo "Block 3 size after refactor: $NEW_LINE_COUNT lines"
echo "Expected: ~12-15 lines"

if [ "$NEW_LINE_COUNT" -gt 20 ]; then
  echo "WARNING: Block 3 still too large ($NEW_LINE_COUNT lines)"
  echo "Expected ~12 lines for context injection pattern"
fi

# Verify no STEP sequences remain in Block 3
STEP_COUNT=$(sed -n "682,${NEW_BLOCK_END}p" .claude/commands/supervise.md | grep -c "STEP [0-9]")
if [ "$STEP_COUNT" -ne 0 ]; then
  echo "ERROR: Block 3 still contains $STEP_COUNT STEP sequences"
  echo "Behavioral content was not fully removed"
  exit 1
fi
```

**Success Criteria**:
- [ ] research-specialist.md contains all behavioral procedures
- [ ] Block 3 reduced from ~147 lines to ~12 lines (92% reduction)
- [ ] Block 3 contains only Task structure + context injection
- [ ] No STEP sequences or PRIMARY OBLIGATION in Block 3

---

### Task 2.2: Process Planning Agent Template (Block 4, Lines 1082-1246)

**Process**: Follow same pattern as Task 2.1

1. Extract Block 4 (lines 1082-1246, ~164 lines)
2. Verify `.claude/agents/plan-architect.md` has required behavioral content
3. Extract and add missing content if needed
4. Replace with lean context injection (~12 lines)
5. Validate 93% reduction

**Corrected Version**:
```yaml
# Planning Agent Template
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **CONTEXT**:
    - Research reports: ${REPORT_PATHS[@]}
    - Output path: ${PLAN_PATH}
    - Workflow: ${WORKFLOW_DESCRIPTION}
  "
}
```

---

### Task 2.3: Process Implementation Agent Template (Block 5, Lines 1440-1615)

**Process**: Follow same pattern

**Target Agent File**: `.claude/agents/code-writer.md`

**Corrected Version**:
```yaml
# Implementation Agent Template
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/code-writer.md

    **CONTEXT**:
    - Plan path: ${PLAN_PATH}
    - Starting phase: ${STARTING_PHASE:-1}
  "
}
```

---

### Task 2.4: Process Testing Agent Template (Block 6, Lines 1721-1925)

**Process**: Follow same pattern

**Target Agent File**: `.claude/agents/test-specialist.md`

**Corrected Version**:
```yaml
# Testing Agent Template
Task {
  subagent_type: "general-purpose"
  description: "Run test suite"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/test-specialist.md

    **CONTEXT**:
    - Test scope: ${TEST_SCOPE}
    - Coverage target: ${COVERAGE_TARGET:-80}
  "
}
```

---

### Task 2.5: Process Documentation Agent Template (Block 7, Lines 2246-2441)

**Process**: Follow same pattern

**Target Agent File**: `.claude/agents/doc-writer.md`

**Corrected Version**:
```yaml
# Documentation Agent Template
Task {
  subagent_type: "general-purpose"
  description: "Generate implementation summary"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/doc-writer.md

    **CONTEXT**:
    - Plan path: ${PLAN_PATH}
    - Report paths: ${REPORT_PATHS[@]}
    - Summary path: ${SUMMARY_PATH}
  "
}
```

---

### Phase 2 Summary

**Before Refactor**:
- Block 3 (Research): ~147 lines
- Block 4 (Planning): ~164 lines
- Block 5 (Implementation): ~175 lines
- Block 6 (Testing): ~204 lines
- Block 7 (Documentation): ~195 lines
- **Total**: ~885 lines

**After Refactor**:
- Block 3: ~12 lines
- Block 4: ~12 lines
- Block 5: ~12 lines
- Block 6: ~12 lines
- Block 7: ~12 lines
- **Total**: ~60 lines

**Reduction**: 825 lines removed (93% reduction)

**Success Criteria**:
- [ ] All 5 agent behavioral files complete
- [ ] All 5 blocks replaced with context injection
- [ ] 825+ lines removed from supervise.md
- [ ] No STEP sequences or PRIMARY OBLIGATION blocks in command file
- [ ] All behavioral content in `.claude/agents/*.md` files (single source of truth)

---

## Phase 3: Update Regression Test (Fix False Pass)

**Objective**: Fix regression test to detect actual patterns

**Problem**: Current test searches for "Example agent invocation:" (doesn't exist), giving false pass

**File**: `.claude/tests/test_supervise_delegation.sh`

### Task 3.1: Fix Test 2 Pattern Detection

**Current Code** (line 78):
```bash
# Test 2: YAML documentation blocks (should be 0)
YAML_BLOCKS=$(grep "Example agent invocation:" "$SUPERVISE_FILE" | wc -l)
```

**Problem**: Pattern "Example agent invocation:" not found → reports 0 → false pass

**Corrected Code**:
```bash
# Test 2: YAML blocks containing Task invocations
# Exclude first 100 lines (documentation section) to avoid counting examples
# After refactor: Should be 0 (all agent templates replaced with context injection)
# Note: Documentation examples (lines 49-89) may contain YAML but are outside agent template section

YAML_BLOCKS=$(tail -n +100 "$SUPERVISE_FILE" | grep -c '```yaml')

# Clarify expected values:
# BEFORE refactor: 5 (agent templates: research, plan, implement, test, doc)
# AFTER refactor:  0 (all replaced with context injection)
```

**Rationale for `tail -n +100`**:
- Lines 1-99 contain documentation/examples (should be retained)
- Lines 100+ contain actual workflow implementation (agent templates should be removed)
- This prevents documentation examples from failing the test

**Alternative (more precise)**:
```bash
# Count YAML blocks that contain both ```yaml and embedded STEP sequences
# These are behavioral duplication instances that should be refactored

YAML_BLOCKS=$(awk '
  /```yaml/{flag=1; yaml=""; line=NR}
  flag{yaml=yaml $0 "\n"}
  /^```$/{
    if(flag && line >= 100 && yaml ~ /STEP [0-9]/){
      count++
    }
    flag=0
  }
  END{print count+0}
' "$SUPERVISE_FILE")

echo "YAML blocks with STEP sequences (line 100+): $YAML_BLOCKS"
# BEFORE refactor: 5
# AFTER refactor: 0
```

### Task 3.2: Add Test for "Example agent invocation:" Absence

Add new test to verify anti-pattern stays eliminated:

```bash
# Test 2b: Verify "Example agent invocation:" pattern does NOT exist
# This pattern indicates the anti-pattern that was refactored away

EXAMPLE_PATTERN_COUNT=$(grep -c "Example agent invocation:" "$SUPERVISE_FILE")

if [ "$EXAMPLE_PATTERN_COUNT" -ne 0 ]; then
  echo "Test 2b: 'Example agent invocation:' pattern FOUND (should be 0)... FAIL"
  FAILED_TESTS=$((FAILED_TESTS + 1))
else
  echo "Test 2b: 'Example agent invocation:' pattern (should be 0)... PASS"
fi
```

### Task 3.3: Update Test Documentation

Add comments explaining why patterns changed:

```bash
# Test 2: YAML Template Block Detection
#
# CONTEXT: Spec 438 originally searched for "Example agent invocation:" pattern
# PROBLEM: This pattern never existed in supervise.md (see spec 444 diagnostic)
# FIX: Updated to detect actual ```yaml fences in agent template section
#
# PATTERN HISTORY:
# - Spec 438 (incorrect): grep "Example agent invocation:"
# - Spec 444 (corrected): tail -n +100 | grep '```yaml'
#
# EXPECTED VALUES:
# - Before refactor: 5 (agent template YAML blocks after line 100)
# - After refactor:  0 (all replaced with lean context injection)
# - Documentation examples (lines 49-89) are excluded by tail -n +100
```

**Success Criteria**:
- [ ] Test 2 detects actual YAML pattern (not "Example agent invocation:")
- [ ] Test 2 excludes documentation section (lines 1-99)
- [ ] Test 2b verifies "Example agent invocation:" stays at 0
- [ ] Test documentation explains pattern history
- [ ] Regression test passes after refactor

---

## Success Metrics

### Quantitative

- [ ] **Pattern Verification**: All Phase 0 checks pass
- [ ] **YAML Block Reduction**: 7 → 2 blocks (2 documentation examples retained)
- [ ] **Line Reduction**: ~840 lines removed (92% reduction)
- [ ] **STEP Sequences**: 0 remaining in supervise.md (all in agent files)
- [ ] **Agent Files**: 5 behavioral files complete (research-specialist, plan-architect, code-writer, test-specialist, doc-writer)
- [ ] **Regression Test**: Updated and passing

### Qualitative

- [ ] **Single Source of Truth**: Behavioral content only in `.claude/agents/*.md`
- [ ] **Maintainability**: Changes to agent behavior require editing 1 file (not 2)
- [ ] **Context Efficiency**: Orchestrator context reduced by ~825 lines per workflow
- [ ] **Pattern Compliance**: All agent invocations use behavioral injection pattern
- [ ] **Documentation Clarity**: Examples demonstrate correct structural template usage

---

## Validation Commands

After completing all phases, run these commands to verify success:

```bash
# 1. Count YAML blocks in supervise.md
YAML_COUNT=$(grep -c '```yaml' .claude/commands/supervise.md)
echo "YAML blocks in supervise.md: $YAML_COUNT (expected: 2 for documentation examples)"

# 2. Count STEP sequences in supervise.md (should be 0)
STEP_COUNT=$(grep -c "STEP [0-9]" .claude/commands/supervise.md)
echo "STEP instructions in supervise.md: $STEP_COUNT (expected: 0)"

# 3. Verify no PRIMARY OBLIGATION in command file
PRIMARY_COUNT=$(grep -c "PRIMARY OBLIGATION" .claude/commands/supervise.md)
echo "PRIMARY OBLIGATION in supervise.md: $PRIMARY_COUNT (expected: 0)"

# 4. Count Task invocations (should still exist for documentation)
TASK_COUNT=$(grep -c "Task {" .claude/commands/supervise.md)
echo "Task invocations in supervise.md: $TASK_COUNT (expected: ~2-4 for examples)"

# 5. Verify agent files have behavioral content
echo ""
echo "Agent file verification:"
for agent in research-specialist plan-architect code-writer test-specialist doc-writer; do
  AGENT_FILE=".claude/agents/${agent}.md"
  if [ -f "$AGENT_FILE" ]; then
    STEP_COUNT=$(grep -c "STEP [0-9]" "$AGENT_FILE")
    echo "  $agent: $STEP_COUNT STEP instructions"
  else
    echo "  $agent: FILE MISSING"
  fi
done

# 6. Run regression test
echo ""
echo "Running regression test..."
.claude/tests/test_supervise_delegation.sh

# 7. Calculate line reduction
SUPERVISE_LINES=$(wc -l < .claude/commands/supervise.md)
echo ""
echo "Supervise.md current size: $SUPERVISE_LINES lines"
echo "Expected after refactor: ~1640-1680 lines (2520 - 840 removed)"
```

**Expected Output After Successful Refactor**:
```
YAML blocks in supervise.md: 2 (expected: 2 for documentation examples)
STEP instructions in supervise.md: 0 (expected: 0)
PRIMARY OBLIGATION in supervise.md: 0 (expected: 0)
Task invocations in supervise.md: 2 (expected: ~2-4 for examples)

Agent file verification:
  research-specialist: 12 STEP instructions
  plan-architect: 8 STEP instructions
  code-writer: 15 STEP instructions
  test-specialist: 10 STEP instructions
  doc-writer: 7 STEP instructions

Running regression test...
Test 1: Imperative invocations... PASS
Test 2: YAML blocks (should be 0)... PASS
Test 2b: Example pattern absence... PASS
Test 3: Agent file references... PASS
Test 4: Libraries sourced... PASS

All tests passed!

Supervise.md current size: 1675 lines
Expected after refactor: ~1640-1680 lines (2520 - 840 removed)
```

---

## Risk Mitigation

### Phase 0 Guards

The pattern verification phase prevents:
- Editing with wrong search patterns (caught before implementation)
- Working on modified file (line number mismatches detected)
- False confidence from outdated assumptions (actual patterns verified)

### Backup Strategy

Before making changes:

```bash
# Create backup
cp .claude/commands/supervise.md .claude/commands/supervise.md.backup-refactor

# If refactor fails, restore:
# mv .claude/commands/supervise.md.backup-refactor .claude/commands/supervise.md
```

### Incremental Validation

After each block replacement:
- Verify line count reduction
- Check for STEP sequence removal
- Run syntax validation (if applicable)
- Test agent invocation still works

### Rollback Criteria

If any of these occur, stop and investigate:
- Pattern verification fails (Phase 0)
- Block replacement increases file size
- STEP sequences remain after replacement
- Agent behavioral file is missing content
- Regression test fails after refactor

---

## Comparison to Spec 438 Plan

### What Changed

| Aspect | Spec 438 (Original) | Spec 444 (Corrected) |
|--------|-------------------|---------------------|
| **Phase 0** | No pattern verification | Pattern verification guards |
| **Search Pattern** | "Example agent invocation:" | ` ```yaml` + `Task {` |
| **Pattern Verification** | Assumed to exist | Verified before implementation |
| **Target State** | "0 YAML blocks" (ambiguous) | "2 YAML blocks (docs)" (clear) |
| **Regression Test** | Searches wrong pattern | Searches actual pattern |
| **Line Numbers** | Assumed stable | Verified in Phase 0 |
| **Block Classification** | Inferred from analysis | Explicit (Task 2.1) |

### Why This Plan Succeeds

1. **Pattern Verification**: Phase 0 catches mismatches before wasting effort
2. **Actual Strings**: Uses grep-extracted patterns, not assumptions
3. **Classification**: Explicit YAML block analysis (Task 2.1) guides decisions
4. **Clear Target**: 2 blocks retained (documentation), 5 removed (templates)
5. **Regression Test Fix**: Detects actual patterns, not phantom patterns

---

## References

- **Diagnostic Report**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md`
- **Classification**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/supervise_yaml_classification.md`
- **Original Plan**: `.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/plans/001_supervise_command_refactor_integration/001_supervise_command_refactor_integration.md`
- **Standards Reference**: `.claude/docs/reference/template-vs-behavioral-distinction.md`
- **Target File**: `.claude/commands/supervise.md`
- **Regression Test**: `.claude/tests/test_supervise_delegation.sh`

---

## Next Steps

Per Phase 2 Task 2.3 and 2.4:
1. Document /supervise as case study in troubleshooting guide
2. Update spec 438 plan with addendum referencing these corrections
3. Execute this corrected refactor plan
4. Validate 90% code reduction achieved

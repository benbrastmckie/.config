# Supervise Refactor Pattern Mismatch - Diagnostic Report

## Metadata
- **Date**: 2025-10-24
- **Issue**: Plan 438/001 cannot find YAML blocks to replace
- **Root Cause**: Search pattern mismatch
- **Severity**: HIGH (blocks implementation)
- **Source**: /home/benjamin/.config/.claude/TODO6.md analysis

## Executive Summary

The refactor plan for `/supervise` command (spec 438/001) is unable to find YAML documentation blocks it's supposed to replace, resulting in "0 YAML blocks found" despite 7 YAML blocks existing in the file. The issue stems from an incorrect search pattern in the implementation plan.

**Root Cause**: Plan searches for pattern `Example agent invocation:` followed by ` ```yaml`, but actual file contains only ` ```yaml` markdown code fences without the "Example agent invocation:" prefix.

**Impact**: Phase 1 implementation cannot proceed - the Edit tool cannot locate blocks to replace.

**Fix Required**: Update search pattern in plan to match actual YAML fence patterns in supervise.md.

## Problem Analysis

### What the Plan Expects

From `phase_1_convert_to_executable_invocations.md:148`:
```
1. **Locate YAML block**: Search for `Example agent invocation:` followed by ` ```yaml`
```

From main plan (line 22):
```
**Anti-Pattern**: supervise is the ONLY command using YAML documentation blocks
(`Example agent invocation:` followed by code blocks)
```

### What Actually Exists in supervise.md

**Evidence from TODO6.md (line 35)**:
```bash
$ grep -n '^```yaml' supervise.md | wc -l
0
```

**Evidence from TODO6.md (line 39)**:
```bash
$ grep -n "Example agent invocation:" supervise.md | wc -l
0
```

**Actual pattern found** (confirmed via Grep tool):
```markdown
**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):
```yaml
# ✅ CORRECT - Do this instead
Task {
  ...
}
```
```

**Key finding**: The supervise.md file contains 7 YAML code blocks marked with ` ```yaml` fences, but NONE are preceded by "Example agent invocation:" text.

### Pattern Locations in supervise.md

Seven YAML code fence locations found at:

1. **Line 49**: After "**Wrong Pattern - Command Chaining**" (example/documentation)
2. **Line 63**: After "**Correct Pattern - Direct Agent Invocation**" (example/documentation)
3. **Line 682**: After closing ` ``` ` (research agent template)
4. **Line 1082**: After "STEP 2: Invoke plan-architect agent via Task tool" (planning agent)
5. **Line 1440**: After "STEP 1: Invoke code-writer agent with plan context" (implementation agent)
6. **Line 1721**: After "STEP 1: Invoke test-specialist agent" (testing agent)
7. **Line 2246**: After "STEP 1: Invoke doc-writer agent to create summary" (documentation agent)

**Pattern analysis**:
- First 2 blocks (lines 49, 63): Documentation examples showing wrong vs. correct patterns
- Remaining 5 blocks (lines 682, 1082, 1440, 1721, 2246): Actual agent invocation templates
- NONE have "Example agent invocation:" prefix

### Why the Search Fails

The plan's implementation tasks instruct using Edit tool with search pattern:
```
old_string: "Example agent invocation:\n\n```yaml\nTask {\n..."
```

This pattern will NEVER match because:
1. Text "Example agent invocation:" does not exist in file (0 occurrences)
2. The YAML fences are preceded by different text (e.g., "STEP 1: Invoke...")
3. Pattern ^```yaml finds 0 matches (per TODO6.md:35) - likely because of leading whitespace

### Test Results Confirm Issue

From TODO6.md test execution (lines 92-106):

**Passing tests**:
- ✅ Test 1: 14 imperative invocations found (PASS)
- ✅ Test 2: 0 YAML documentation blocks (PASS) - but using WRONG search pattern!
- ✅ Test 3: 6 agent behavioral file references (PASS)
- ✅ Test 4: 4 libraries sourced (PASS)

**The paradox**: Test 2 passes (0 YAML blocks found) because it searches for "Example agent invocation:", which doesn't exist. But this is a FALSE PASS - 7 YAML blocks DO exist, just not with that prefix.

## Root Cause Diagnosis

### Primary Issue: Outdated Plan Assumptions

The research reports that informed plan 438/001 were based on analyzing OTHER commands or an older version of supervise.md. The pattern `Example agent invocation:` may have existed in:

1. **Other orchestration commands** being analyzed as anti-pattern examples
2. **Earlier draft** of supervise.md that has since been edited
3. **Hypothetical anti-pattern** documented in research but never actually present in production

### Evidence of Mismatch

From plan line 319-327 (Current Anti-Pattern Locations):
```
**Current Anti-Pattern Locations** (7 YAML blocks at lines):
1. Line 49-54: Example SlashCommand pattern (incorrect pattern demonstration)
2. Line 63-82: Example Task pattern with embedded template (should reference agent file)
3. Line 682-829: Research agent template (duplicates research-specialist.md)
...
```

**Discrepancy**: Plan lists line numbers but describes pattern as "Example SlashCommand pattern" / "Example Task pattern" - yet grep finds NO "Example" prefix at these locations.

**Hypothesis**: Research agent analyzed file and INFERRED purpose ("Example SlashCommand pattern") but INCORRECTLY assumed these were prefixed with "Example agent invocation:" text.

### Secondary Issue: Ambiguous Target State

The plan has contradictory goals:

**Goal 1** (from Phase 0:266): "Count YAML documentation blocks (expect 9)"
**Goal 1** (from Phase 1:346): "0 inline YAML template blocks remaining (remove all 7)"

**Contradiction**: Expect 9 but remove 7? This suggests:
- 7 "inline YAML templates" (agent invocations) to be replaced
- 2 "documentation examples" (lines 49, 63) may be intended to stay?

**Ambiguity**: Should documentation examples (wrong vs. correct pattern comparison) be removed or retained?

## Impact Assessment

### Blocked Work

**Phase 1 implementation cannot proceed** because:

1. Edit tool requires exact `old_string` match
2. Pattern `Example agent invocation:` + ` ```yaml` never matches
3. Agent trying to implement gets 0 results, reports "no work to do"
4. Plan checkpoints fail (expects 7 replacements, gets 0)

### Wasted Effort

From TODO6.md (lines 113-114):
```
Let me update the todo list and document the audit findings:
```

Implementation agent spent time on:
- Reading plan (1036 lines)
- Reading supervise.md (2521 lines)
- Running audit commands
- Creating test file (already existed)
- Running tests
- Attempting to create write-protected file

**Result**: No progress on actual refactor because search pattern is wrong.

### False Confidence

The regression test (`test_supervise_delegation.sh`) gives FALSE PASS on Test 2:
```
Test 2: YAML documentation blocks (should be 0)... PASS
```

This passes because it searches for "Example agent invocation:" (0 found), but 7 YAML blocks DO exist. The test validates the WRONG pattern, creating false confidence that no work is needed.

## Recommendations

### Recommendation 1: Fix Search Pattern in Plan (CRITICAL)

**File**: `.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/plans/001_supervise_command_refactor_integration/phase_1_convert_to_executable_invocations.md`

**Current (line 148)**:
```
1. **Locate YAML block**: Search for `Example agent invocation:` followed by ` ```yaml`
```

**Corrected**:
```
1. **Locate YAML block**: Search for ` ```yaml` followed by `Task {`
   - Context patterns to find blocks:
     - Lines 49, 63: After "**Wrong Pattern**" / "**Correct Pattern**" (documentation examples)
     - Line 682: After triple backtick closing (research agent)
     - Line 1082: After "STEP 2: Invoke plan-architect agent"
     - Line 1440: After "STEP 1: Invoke code-writer agent"
     - Line 1721: After "STEP 1: Invoke test-specialist agent"
     - Line 2246: After "STEP 1: Invoke doc-writer agent"
```

**Rationale**: Match actual file contents, not hypothetical pattern.

### Recommendation 2: Update Regression Test Pattern (CRITICAL)

**File**: `.claude/tests/test_supervise_delegation.sh`

**Current (line 78)**:
```bash
YAML_BLOCKS=$(grep "Example agent invocation:" "$SUPERVISE_FILE" | wc -l)
```

**Corrected**:
```bash
# Count YAML code blocks containing Task invocations (not documentation examples)
# Exclude first 100 lines (documentation section) to avoid counting examples
YAML_BLOCKS=$(tail -n +100 "$SUPERVISE_FILE" | grep -c '```yaml')
```

**Alternative (more robust)**:
```bash
# Count YAML blocks that contain actual Task invocations (agent templates)
YAML_TASK_BLOCKS=$(awk '/```yaml/{flag=1; yaml=""} flag{yaml=yaml $0 "\n"} /```/{if(flag && yaml ~ /Task \{/){print yaml; count++} flag=0} END{print count+0}' "$SUPERVISE_FILE")
```

**Rationale**: Detect actual YAML code fence + Task pattern, not non-existent text prefix.

### Recommendation 3: Clarify Target State for Documentation Examples (HIGH)

**Decision needed**: Should lines 49-89 (documentation examples) be retained or removed?

**Option A - Retain examples** (recommended):
- Keep "Wrong Pattern" vs. "Correct Pattern" comparison (lines 49-89)
- Remove ONLY the 5 agent invocation templates (lines 682+)
- Benefit: Developers see anti-pattern explanation with examples
- Target: Remove 5 YAML blocks, retain 2 documentation examples

**Option B - Remove all**:
- Remove all 7 YAML blocks including documentation
- Replace with prose description + reference to patterns doc
- Benefit: Fully complies with "single source of truth" (no inline examples)
- Target: Remove 7 YAML blocks

**Update plan** with explicit decision and adjust success criteria from "0 YAML blocks" to either:
- "2 YAML blocks (documentation examples only)" (Option A)
- "0 YAML blocks" (Option B)

### Recommendation 4: Add Pattern Verification Step to Phase 0 (MEDIUM)

**Enhancement to Phase 0 audit**:

Add verification that search patterns will match before proceeding to Phase 1:

```bash
# Phase 0: Verify search patterns before implementation
echo "Verifying search patterns for Phase 1..."

# Pattern 1: Test for "Example agent invocation:" (plan expects this)
EXAMPLE_COUNT=$(grep -c "Example agent invocation:" .claude/commands/supervise.md)
echo "Pattern 'Example agent invocation:' found: $EXAMPLE_COUNT"

# Pattern 2: Test for actual YAML fences (what actually exists)
YAML_FENCE_COUNT=$(grep -c '```yaml' .claude/commands/supervise.md)
echo "Pattern '```yaml' found: $YAML_FENCE_COUNT"

# Pattern 3: Test for YAML + Task combination (actual targets)
YAML_TASK_COUNT=$(grep -A 5 '```yaml' .claude/commands/supervise.md | grep -c 'Task {')
echo "YAML blocks with 'Task {': $YAML_TASK_COUNT"

# Validation
if [ "$EXAMPLE_COUNT" -eq 0 ] && [ "$YAML_TASK_COUNT" -gt 0 ]; then
  echo "WARNING: Plan search pattern mismatch detected!"
  echo "  Plan expects: 'Example agent invocation:' prefix"
  echo "  File contains: Direct ```yaml fences without prefix"
  echo "  ACTION REQUIRED: Update plan search patterns before Phase 1"
  exit 1
fi
```

**Benefit**: Catch pattern mismatches before wasting implementation effort.

### Recommendation 5: Use Grep for Pattern Discovery, Not Assumptions (MEDIUM)

**Process improvement**:

When creating implementation plans that require string replacement:

1. **Verify patterns exist** using Grep tool before documenting in plan
2. **Extract actual context** (lines before/after) not inferred descriptions
3. **Include actual strings** in plan (copy-paste from Grep output)
4. **Test search patterns** in Phase 0 audit before Phase 1 implementation

**Anti-pattern to avoid**:
```markdown
# DON'T: Assume pattern based on analysis
**Current Anti-Pattern Locations**:
1. Line 49-54: Example SlashCommand pattern (incorrect pattern demonstration)
```

**Correct pattern**:
```markdown
# DO: Document exact strings found via Grep
**Current Anti-Pattern Locations**:
1. Line 49-82: After text "**Wrong Pattern - Command Chaining**", contains:
   ```
   ```yaml
   # ✅ CORRECT - Do this instead
   Task {
   ```
```

## Proposed Fix Implementation

### Step 1: Update Phase 1 Plan

Edit: `phase_1_convert_to_executable_invocations.md`

**Changes**:
1. Line 148: Replace search pattern instruction
2. Add subsection "Pattern Verification" before "Implementation Strategy"
3. Update all Edit tool usage examples to use correct `old_string` patterns
4. Add grep commands to extract actual YAML block boundaries

### Step 2: Update Regression Test

Edit: `.claude/tests/test_supervise_delegation.sh`

**Changes**:
1. Line 78: Fix YAML block detection pattern
2. Add comment explaining why pattern changed
3. Add test case for "Example agent invocation:" to verify it STAYS at 0 (anti-pattern eliminated)

### Step 3: Update Main Plan Documentation

Edit: `001_supervise_command_refactor_integration.md`

**Changes**:
1. Line 22: Update anti-pattern description (remove "Example agent invocation:" mention)
2. Line 319-327: Update "Current Anti-Pattern Locations" with actual grep output
3. Phase 0 success criteria: Add pattern verification checkpoint
4. Clarify whether documentation examples (2 blocks) should be retained

### Step 4: Re-run Phase 0 with Corrected Patterns

After fixes:
```bash
cd /home/benjamin/.config/.claude/tests
./test_supervise_delegation.sh

# Expected output (after test fix):
# Test 2: YAML blocks: 7 (expected >0 before refactor, 0-2 after)
```

## Validation Checklist

After implementing fixes, verify:

- [ ] Grep for '```yaml' in supervise.md returns 7 results (before refactor)
- [ ] Grep for "Example agent invocation:" returns 0 results (confirm absence)
- [ ] Regression test updated to detect actual YAML fences
- [ ] Phase 1 plan updated with correct search patterns
- [ ] Pattern verification step added to Phase 0
- [ ] Decision documented on documentation examples (retain 2 or remove all 7)
- [ ] Test run confirms YAML blocks detected (not 0 false pass)

## Conclusion

The supervise refactor plan is technically sound in its goals and approach, but contains a critical search pattern mismatch that prevents implementation. The pattern `Example agent invocation:` does not exist in the target file, despite being referenced throughout the plan and regression test.

**Fix complexity**: LOW (update 3 files with corrected grep patterns)
**Fix priority**: CRITICAL (blocks all Phase 1 work)
**Fix time**: 30 minutes (pattern updates + test validation)

Once patterns are corrected, the refactor can proceed as designed with high confidence in success.

## References

- **Source Issue**: /home/benjamin/.config/.claude/TODO6.md
- **Target File**: /home/benjamin/.config/.claude/commands/supervise.md (2,521 lines)
- **Refactor Plan**: /home/benjamin/.config/.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/plans/001_supervise_command_refactor_integration/001_supervise_command_refactor_integration.md
- **Phase 1 Details**: .../phase_1_convert_to_executable_invocations.md
- **Regression Test**: /home/benjamin/.config/.claude/tests/test_supervise_delegation.sh
- **Test Output**: TODO6.md lines 79-112

## File References

- `.claude/commands/supervise.md:49` - First YAML fence (documentation example)
- `.claude/commands/supervise.md:63` - Second YAML fence (documentation example)
- `.claude/commands/supervise.md:682` - Research agent template
- `.claude/commands/supervise.md:1082` - Planning agent template
- `.claude/commands/supervise.md:1440` - Implementation agent template
- `.claude/commands/supervise.md:1721` - Testing agent template
- `.claude/commands/supervise.md:2246` - Documentation agent template
- `.claude/tests/test_supervise_delegation.sh:78` - Incorrect YAML block detection
- `phase_1_convert_to_executable_invocations.md:148` - Incorrect search pattern instruction

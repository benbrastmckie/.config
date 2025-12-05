# Research Report: Task Delegation Failure in Command Suite

## Executive Summary

The command suite contains **1 command with active Task invocation violations** (lean-implement.md) that fails to properly delegate work to subagents. The root cause is the use of conditional pseudo-syntax patterns that lack explicit imperative directives, causing Claude to interpret Task blocks as documentation rather than executable instructions.

**Key Finding**: The issue is NOT systemic across all commands. Of 17 commands with Task delegation:
- **16 commands (94%)** correctly use the imperative "EXECUTE NOW: USE the Task tool" pattern
- **1 command (6%)** has violations: lean-implement.md (2 naked Task blocks)

## Problem Statement

### The Core Issue

Commands that use conditional Task invocations with implicit directives (e.g., "**If CONDITION**: USE the Task tool...") without explicit "EXECUTE NOW" statements may fail to invoke subagents. Claude interprets these as instructional guidance rather than mandatory execution directives.

### Evidence from Linter Results

```bash
$ bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/*.md

ERROR: .claude/commands/lean-implement.md:679 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)
ERROR: .claude/commands/lean-implement.md:724 - Naked Task block (missing 'EXECUTE NOW: USE the Task tool' directive)

Files checked: 18
Files with errors: 1
ERROR violations: 2
```

## Root Cause Analysis

### Technical Explanation

From command-authoring.md (lines 94-166):

> "Commands using this pattern will NOT invoke agents... This pseudo-syntax is not recognized by Claude Code... No execution directive tells the LLM to use the Task tool... Variables inside will not be interpolated..."

The problem occurs when:

1. **Conditional Pattern Without EXECUTE NOW**: Using patterns like "**If X**: USE the Task tool" without a separate imperative directive
2. **No Hard Barrier Enforcement**: Lack of bash verification blocks between Task invocations
3. **Ambiguous Delegation Context**: Claude interprets conditional text as guidance, not commands

### Example from lean-implement.md (Lines 677-724)

**Current Pattern** (FAILS):
```markdown
**If CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving"
  prompt: "..."
}
```

**Problem**: The conditional prefix "**If CURRENT_PHASE_TYPE is 'lean'**:" makes the directive ambiguous. Claude reads this as documentation describing what SHOULD happen in a certain condition, not as a mandatory instruction to execute NOW.

## Affected Commands Analysis

### Commands with Task Delegation (17 total)

| Command | Task Blocks | Directives | Status | Notes |
|---------|-------------|------------|--------|-------|
| collapse.md | 4 | 4 | ✅ PASS | All Task blocks have EXECUTE NOW directives |
| convert-docs.md | 1 | 1 | ✅ PASS | Single Task block with proper directive |
| create-plan.md | 3 | 3 | ✅ PASS | All 3 Task blocks (topic-naming, research, plan) have directives |
| debug.md | 4 | 4 | ✅ PASS | All Task blocks properly directed |
| errors.md | 2 | 2 | ✅ PASS | Both Task blocks have directives |
| expand.md | 4 | 5 | ✅ PASS | Extra directive for conditional invocation |
| implement.md | 2 | 2 | ✅ PASS | Initial + iteration loop invocations both have directives |
| lean-build.md | 1 | 1 | ✅ PASS | Single Task block with directive |
| **lean-implement.md** | **2** | **0** | ❌ **FAIL** | **2 conditional Task blocks without EXECUTE NOW** |
| lean-plan.md | 3 | 3 | ✅ PASS | All 3 Task blocks have directives |
| optimize-claude.md | 6 | 7 | ✅ PASS | Multiple Task blocks with directives |
| repair.md | 2 | 2 | ✅ PASS | Both Task blocks have directives |
| research.md | 2 | 2 | ✅ PASS | Topic-naming + research-specialist both have directives |
| revise.md | 2 | 2 | ✅ PASS | Research + plan-architect both have directives |
| setup.md | 1 | 1 | ✅ PASS | Single Task block with directive |
| test.md | 2 | 2 | ✅ PASS | Initial + iteration loop invocations both have directives |
| todo.md | 2 | 1 | ⚠️ EDGE | 1 conditional Task (EXECUTE IF pattern may need verification) |

**Summary Statistics**:
- Total commands with Task delegation: 17
- Commands passing linter: 16 (94%)
- Commands with active violations: 1 (6%)
- Commands needing review: 1 (todo.md - uses EXECUTE IF pattern)

## Documentation Analysis

### Existing Standards (command-authoring.md)

The documentation at `.claude/docs/reference/standards/command-authoring.md` (lines 94-953) provides comprehensive guidance:

1. **Task Tool Invocation Patterns** (lines 94-166)
   - ✅ Documents the problem with pseudo-syntax
   - ✅ Provides correct patterns with "EXECUTE NOW: USE the Task tool"
   - ✅ Shows edge cases (iteration loops, conditionals)

2. **Prohibited Patterns** (lines 1162-1248)
   - ✅ Explicitly prohibits naked Task blocks
   - ✅ Prohibits instructional text without actual invocation
   - ✅ Prohibits incomplete EXECUTE NOW directives

3. **Hard Barrier Pattern** (hard-barrier-subagent-delegation.md)
   - ✅ Documents Setup → Execute → Verify pattern
   - ✅ Shows path pre-calculation pattern
   - ✅ Provides compliance checklist

### Gap Analysis

**What's Missing**:

1. **Conditional Invocation Clarity**: The docs show "**EXECUTE IF**" pattern (line 208-217 in command-authoring.md) but don't explicitly state that conditional prefixes like "**If CONDITION**: USE the Task tool" are insufficient without "EXECUTE NOW"

2. **Routing Pattern Guidance**: No specific guidance for commands that route to different agents based on runtime state (like lean-implement.md's phase type routing)

3. **Linter Integration**: The linter (lint-task-invocation-pattern.sh) doesn't catch conditional patterns that start with "**If**" instead of "**EXECUTE IF**" or "**EXECUTE NOW**"

## Technical Deep Dive: Why Conditional Patterns Fail

### Pattern Analysis: lean-implement.md

**Lines 673-679** (FIRST VIOLATION):
```markdown
**COORDINATOR INVOCATION DECISION**:

Based on the CURRENT_PHASE_TYPE from Block 1b state:

**If CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  ...
}
```

**Lines 722-724** (SECOND VIOLATION):
```markdown
**If CURRENT_PHASE_TYPE is "software"**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  ...
}
```

### Why This Fails

1. **Conditional Prefix Ambiguity**: The pattern "**If CONDITION**: USE the Task tool" reads like a conditional statement in documentation, not an imperative command
2. **No Explicit Execution Directive**: Unlike "**EXECUTE NOW**:" or "**EXECUTE IF**:", the "**If X**:" prefix doesn't signal mandatory execution
3. **Structural Weakness**: The invocation decision block (line 673) separates the conditional logic from the Task blocks, making it read like a decision tree diagram rather than executable code

### Comparison with Working Patterns

**✅ CORRECT: Explicit EXECUTE NOW** (from research.md):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  ...
}
```

**✅ CORRECT: Explicit EXECUTE IF** (from todo.md line 1056):
```markdown
**EXECUTE IF REMOVED_COUNT > 0**: USE the Task tool to invoke the todo-analyzer agent to classify remaining projects after cleanup.

Task {
  ...
}
```

**❌ INCORRECT: Conditional Prefix** (lean-implement.md):
```markdown
**If CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  ...
}
```

### Key Difference

The working patterns use:
- "**EXECUTE NOW**:" (unconditional, immediate)
- "**EXECUTE IF [condition]**:" (conditional, but still imperative)

The failing pattern uses:
- "**If [condition]**:" (descriptive, reads like documentation)

## Linter Effectiveness Analysis

### Current Linter Capabilities

The `lint-task-invocation-pattern.sh` linter (lines 1-172) detects:

1. ✅ **Naked Task blocks**: Task blocks without "EXECUTE NOW" or "EXECUTE IF" within 5 lines
2. ✅ **Instructional text**: "Use the Task tool to invoke..." without actual Task block within 10 lines
3. ✅ **Incomplete directives**: "EXECUTE NOW: Invoke..." without "USE the Task tool"

### Detection Logic

```bash
# Lines 72-96: Pattern 1 detection
if sed -n "${start_line},$((line_num-1))p" "$file" | grep -q 'EXECUTE.*NOW.*Task tool' 2>/dev/null; then
  continue
fi

# Also check for conditional EXECUTE (EXECUTE IF)
if sed -n "${start_line},$((line_num-1))p" "$file" | grep -q 'EXECUTE IF.*Task tool' 2>/dev/null; then
  continue
fi
```

### Why It Caught lean-implement.md

The linter correctly identified that lines 679 and 724 have Task blocks without:
- "EXECUTE NOW" + "Task tool" within 5 lines before, OR
- "EXECUTE IF" + "Task tool" within 5 lines before

The pattern "**If CURRENT_PHASE_TYPE is 'lean'**: USE the Task tool" doesn't match either regex because it lacks "EXECUTE" at the start.

### Linter Gaps

**What the linter DOESN'T catch** (but should):

1. Patterns like "**If X**: USE the Task tool" (lacks "EXECUTE" keyword)
2. Patterns like "**When X**: USE the Task tool" (alternative conditional phrasing)
3. Patterns like "**Based on X**: USE the Task tool" (decision routing patterns)

## Commands Successfully Using Conditional Patterns

### todo.md (Line 1056)

**CORRECT PATTERN**:
```markdown
**EXECUTE IF REMOVED_COUNT > 0**: USE the Task tool to invoke the todo-analyzer agent to classify remaining projects after cleanup.

Task {
  ...
}
```

This passes because:
- Uses "**EXECUTE IF**" (imperative + conditional)
- Includes "USE the Task tool" phrase
- Linter regex matches: `EXECUTE IF.*Task tool`

### expand.md and optimize-claude.md

These commands have more directives than Task blocks (5 directives for 4 blocks, 7 for 6 blocks) because they use multiple conditional invocation points. Each potential invocation path has its own directive.

## Recommended Solutions

### Solution 1: Add Explicit EXECUTE NOW Directives (RECOMMENDED)

**For lean-implement.md lines 677-679**:

```markdown
**COORDINATOR INVOCATION DECISION**:

Based on the CURRENT_PHASE_TYPE from Block 1b state:

**If CURRENT_PHASE_TYPE is "lean"**:

**EXECUTE NOW**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Wave-based Lean theorem proving for phase ${CURRENT_PHASE}"
  prompt: "..."
}
```

**For lean-implement.md lines 722-724**:

```markdown
**If CURRENT_PHASE_TYPE is "software"**:

**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Software implementation for phase ${CURRENT_PHASE}"
  prompt: "..."
}
```

**Benefits**:
- ✅ Explicit, unambiguous directive
- ✅ Passes linter validation
- ✅ Consistent with 16 other commands
- ✅ Maintains conditional documentation context

### Solution 2: Convert to EXECUTE IF Pattern

**Alternative for lean-implement.md**:

```markdown
**EXECUTE IF CURRENT_PHASE_TYPE is "lean"**: USE the Task tool to invoke the lean-coordinator agent.

Task {
  ...
}

**EXECUTE IF CURRENT_PHASE_TYPE is "software"**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  ...
}
```

**Benefits**:
- ✅ Single-line conditional + directive
- ✅ Passes linter validation
- ⚠️ May be less readable (condition and directive combined)

### Solution 3: Enhance Linter to Detect Conditional Prefix Patterns

**Update lint-task-invocation-pattern.sh**:

Add detection for patterns like "**If X**: USE the Task tool" that lack "EXECUTE":

```bash
# Pattern 4: Conditional prefixes without EXECUTE keyword
local conditional_without_execute=$(grep -n '\*\*If.*\*\*:.*Task tool' "$file" 2>/dev/null | \
                                   grep -v 'EXECUTE' || true)

if [ -n "$conditional_without_execute" ]; then
  while IFS= read -r line; do
    local line_num=$(echo "$line" | cut -d: -f1)
    echo -e "${RED}ERROR${NC}: $file:$line_num - Conditional pattern without EXECUTE keyword (ambiguous directive)"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    file_errors=$((file_errors + 1))
  done <<< "$conditional_without_execute"
fi
```

**Benefits**:
- ✅ Prevents future violations
- ✅ Catches all conditional patterns lacking explicit execution keywords
- ✅ Provides clear error messages

## Implementation Recommendations

### Phase 1: Fix Existing Violation (IMMEDIATE)

1. **Apply Solution 1** to lean-implement.md
   - Add "EXECUTE NOW" directives on separate lines after conditional descriptions
   - Lines to modify: 677-679, 722-724

2. **Verify with linter**:
   ```bash
   bash .claude/scripts/lint-task-invocation-pattern.sh .claude/commands/lean-implement.md
   # Expected: 0 violations
   ```

3. **Test command**:
   ```bash
   /lean-implement <plan-file>
   # Expected: Proper agent delegation, not inline work
   ```

### Phase 2: Enhance Documentation (NEXT SPRINT)

1. **Update command-authoring.md** (Section 2.2.4):
   - Add explicit guidance on conditional invocation patterns
   - Show anti-pattern: "**If X**: USE the Task tool" (PROHIBITED)
   - Show correct patterns: "**EXECUTE NOW**" or "**EXECUTE IF X**"

2. **Create decision tree flowchart**:
   - When to use EXECUTE NOW (unconditional)
   - When to use EXECUTE IF (conditional, single line)
   - When to use bash conditional + EXECUTE NOW (complex conditions)

3. **Update migration guide** (task-invocation-pattern-migration.md):
   - Add Section: "Routing Pattern Migration"
   - Show lean-implement.md as case study

### Phase 3: Enhance Linter (FUTURE)

1. **Add Pattern 4 detection** (conditional prefixes without EXECUTE)
2. **Add Pattern 5 detection** (routing patterns with decision blocks)
3. **Improve error messages** with suggested fixes

### Phase 4: Audit Other Commands (VERIFICATION)

Review commands that may have similar patterns:

1. **todo.md**: Verify EXECUTE IF pattern works correctly in practice
2. **expand.md, optimize-claude.md**: Review why they have extra directives (likely correct, but verify)
3. **All commands**: Re-run linter after enhancement to catch any edge cases

## Success Criteria

### Immediate (Phase 1)

- [ ] lean-implement.md passes linter validation (0 violations)
- [ ] lean-implement command delegates to agents (not inline work)
- [ ] No regression in other 16 commands

### Short-term (Phase 2)

- [ ] Documentation explicitly prohibits conditional prefix patterns
- [ ] Migration guide includes routing pattern examples
- [ ] Decision tree flowchart for conditional invocations published

### Long-term (Phase 3)

- [ ] Linter detects all conditional prefix patterns
- [ ] Pre-commit hook prevents future violations
- [ ] All commands (17/17) pass enhanced linter

## Related Files

### Commands with Task Delegation

```
.claude/commands/collapse.md         (4 Task blocks, 4 directives) ✅
.claude/commands/convert-docs.md     (1 Task block, 1 directive) ✅
.claude/commands/create-plan.md      (3 Task blocks, 3 directives) ✅
.claude/commands/debug.md            (4 Task blocks, 4 directives) ✅
.claude/commands/errors.md           (2 Task blocks, 2 directives) ✅
.claude/commands/expand.md           (4 Task blocks, 5 directives) ✅
.claude/commands/implement.md        (2 Task blocks, 2 directives) ✅
.claude/commands/lean-build.md       (1 Task block, 1 directive) ✅
.claude/commands/lean-implement.md   (2 Task blocks, 0 directives) ❌
.claude/commands/lean-plan.md        (3 Task blocks, 3 directives) ✅
.claude/commands/optimize-claude.md  (6 Task blocks, 7 directives) ✅
.claude/commands/repair.md           (2 Task blocks, 2 directives) ✅
.claude/commands/research.md         (2 Task blocks, 2 directives) ✅
.claude/commands/revise.md           (2 Task blocks, 2 directives) ✅
.claude/commands/setup.md            (1 Task block, 1 directive) ✅
.claude/commands/test.md             (2 Task blocks, 2 directives) ✅
.claude/commands/todo.md             (2 Task blocks, 1 directive*) ⚠️

* todo.md uses EXECUTE IF pattern which passes linter but needs runtime verification
```

### Documentation Files

```
.claude/docs/reference/standards/command-authoring.md (Lines 94-953)
.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md
.claude/docs/guides/migration/task-invocation-pattern-migration.md
.claude/scripts/lint-task-invocation-pattern.sh
```

### Archived Prompt Analysis

```
.claude/specs/045_create_plan_delegation_failure/reports/001-task-delegation-failure-analysis.md
.claude/specs/046_task_delegation_subagent_commands/prompts/001-task-delegation-failure-analysis.md
```

## Conclusion

The Task delegation issue is **NOT systemic**. It affects only 1 of 17 commands (6%) that use Task delegation. The root cause is well-understood: conditional prefix patterns ("**If X**: USE the Task tool") lack the explicit execution signal that "**EXECUTE NOW**:" or "**EXECUTE IF X**:" provide.

**The fix is straightforward**: Add explicit "EXECUTE NOW" directives after conditional descriptions in lean-implement.md. This brings the command into compliance with the existing standard that 94% of commands already follow.

The broader issue is **prevention**: The current linter doesn't detect conditional prefix patterns. Enhancing the linter will prevent future violations and ensure all commands maintain the imperative directive standard.

**Impact Assessment**:
- **Low urgency**: Only 1 command affected
- **High confidence fix**: Pattern well-documented, 16 working examples
- **Preventable**: Linter enhancement will catch future violations
- **No architectural changes needed**: Standard already exists and works

---

**REPORT_CREATED**: /home/benjamin/.config/.claude/specs/046_task_delegation_subagent_commands/reports/001-task-delegation-comprehensive-analysis.md

# Implementation Plan: Fix Research-Coordinator Imperative Directives

## Metadata
- **Date**: 2025-12-08
- **Feature**: Fix research-coordinator agent to use imperative Task directives instead of documentation examples
- **Status**: [IN PROGRESS] (3/4 phases complete, Phase 4 requires manual integration test)
- **Estimated Hours**: 2-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-root-cause-analysis.md](../reports/001-root-cause-analysis.md)

## Problem Summary

The research-coordinator agent fails to invoke research-specialist sub-agents because STEP 3 contains **documentation examples** wrapped in markdown code fences (` ```markdown ... ``` `) rather than **executable imperative directives**. Per command-authoring.md Section 2 "Task Tool Invocation Patterns":

> Commands using `Task {}` pseudo-syntax inside code blocks will NOT invoke agents. Problems:
> 1. This pseudo-syntax is not recognized by Claude Code
> 2. No execution directive tells the LLM to use the Task tool
> 3. Variables inside will not be interpolated
> 4. Code block wrapper makes it documentation, not executable

## Root Cause

**Location**: `/home/benjamin/.config/.claude/agents/research-coordinator.md` lines 207-307

**Current pattern** (broken):
```markdown
**Example Parallel Invocation** (3 topics):

```markdown  ← CODE FENCE MAKES THIS DOCUMENTATION
I'm now invoking research-specialist for 3 topics in parallel.

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist.

Task { ... }
```  ← END FENCE - agent reads this as example text, not instructions
```

**Required pattern** (working):
```markdown
### STEP 3: Invoke Parallel Research Workers

**CRITICAL**: For EACH topic in the TOPICS array, you MUST invoke research-specialist using the Task tool.

Generate and execute one Task tool invocation per topic:

**EXECUTE NOW**: For topic index 0, USE the Task tool to invoke research-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[0]}"
  prompt: "... REPORT_PATH=${REPORT_PATHS[0]} ..."
}

**EXECUTE NOW**: For topic index 1, USE the Task tool to invoke research-specialist:

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPICS[1]}"
  prompt: "... REPORT_PATH=${REPORT_PATHS[1]} ..."
}

[Continue for all topics...]
```

## Implementation Phases

### Phase 1: Fix Research-Coordinator STEP 3 [COMPLETE]

**Objective**: Rewrite STEP 3 to use imperative Task directives without code fences

**Files to modify**:
- `.claude/agents/research-coordinator.md` (lines 198-310)

**Changes**:

1. Remove the "Example Parallel Invocation" section header and code fences
2. Add mandatory execution directive pattern at the start of STEP 3:
   ```markdown
   **MANDATORY EXECUTION**: You MUST invoke research-specialist for each topic in the TOPICS array using the Task tool. Generate one Task invocation per topic - do NOT skip or summarize this step.
   ```
3. Convert the example Task invocations to a template format with CRITICAL directive:
   ```markdown
   **CRITICAL**: For each index `i` from 0 to `${#TOPICS[@]} - 1`, generate and execute:

   **EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic ${TOPICS[i]}:

   Task {
     subagent_type: "general-purpose"
     description: "Research ${TOPICS[i]}"
     prompt: "
       Read and follow behavioral guidelines from:
       ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

       **CRITICAL - Hard Barrier Pattern**:
       REPORT_PATH=${REPORT_PATHS[i]}

       **Research Topic**: ${TOPICS[i]}

       **Context**:
       ${CONTEXT}

       Follow all steps in research-specialist.md.
       Return: REPORT_CREATED: ${REPORT_PATHS[i]}
     "
   }
   ```

4. Add checkpoint verification after Task generation:
   ```markdown
   **CHECKPOINT**: Before proceeding to STEP 4, verify you have invoked the Task tool for ALL topics. Count the Task tool invocations in your response - it MUST equal ${#TOPICS[@]}.
   ```

**Success Criteria**:
- [x] STEP 3 contains imperative directive (`**EXECUTE NOW**: USE the Task tool...`)
- [x] NO markdown code fences wrapping Task invocations
- [x] Template pattern allows dynamic topic count
- [x] Checkpoint verification added

### Phase 2: Fix Coordinator Template [COMPLETE]

**Objective**: Update coordinator-template.md to use imperative pattern so future coordinators work correctly

**Files to modify**:
- `.claude/agents/templates/coordinator-template.md` (lines 182-233)

**Changes**:

1. Remove code fences around Task invocation examples
2. Change section from "Example Parallel Invocation" to "Parallel Invocation Template"
3. Add mandatory directive pattern matching Phase 1 changes
4. Document the NO CODE FENCE requirement prominently

**Success Criteria**:
- [x] Template STEP 3 uses imperative directive pattern
- [x] NO code fences wrapping Task invocations
- [x] Comment added: `<!-- CRITICAL: Do NOT wrap Task invocations in code fences -->`

### Phase 3: Add Self-Validation in Coordinator [COMPLETE]

**Objective**: Add validation in STEP 3 that verifies Task tool was actually used before proceeding

**Files to modify**:
- `.claude/agents/research-coordinator.md` (after STEP 3 changes)

**Changes**:

1. Add self-validation prompt in STEP 3.5 (new section):
   ```markdown
   ### STEP 3.5: Verify Task Invocations

   **SELF-CHECK**: Before proceeding to STEP 4, answer these questions:
   - Did you generate Task tool invocations for each topic? (YES/NO)
   - How many Task invocations did you generate? (must equal topic count)
   - Did each Task invocation include the REPORT_PATH?

   If any answer is NO or incorrect, STOP and re-execute STEP 3 before continuing.
   ```

2. Update STEP 4 to expect Task responses, not just file existence

**Success Criteria**:
- [x] STEP 3.5 added with self-validation questions
- [x] Agent cannot proceed without confirming Task usage
- [x] Clear failure mode if Tasks not invoked

### Phase 4: Integration Test [NOT STARTED]

**Objective**: Verify the fix works end-to-end with /create-plan command

**Testing approach**:
1. Run `/create-plan "test research coordinator fix"` with complexity 3
2. Verify research-coordinator is invoked
3. Verify research-coordinator invokes research-specialist (check for multiple Task tool uses)
4. Verify research reports are created at pre-calculated paths
5. Verify hard barrier validation passes

**Success Criteria**:
- [ ] /create-plan with complexity >= 3 triggers research-coordinator
- [ ] research-coordinator shows multiple Task tool invocations
- [ ] All research reports created at expected paths
- [ ] Hard barrier validation passes without manual fallback

## Dependencies

- Phase 2 depends on Phase 1 (template should match fixed coordinator)
- Phase 3 depends on Phase 1 (validation applies to fixed STEP 3)
- Phase 4 depends on Phases 1-3 (integration test of all fixes)

## Risk Assessment

**Low Risk**:
- Changes are isolated to two files (coordinator and template)
- Existing hard barrier validation will catch any regressions
- Primary agent fallback still works if coordinator fails

**Medium Risk**:
- Other commands using research-coordinator need to be tested
- Template changes may require updating other coordinators

## Files Changed Summary

| File | Change Type | Lines Affected |
|------|-------------|----------------|
| `.claude/agents/research-coordinator.md` | Major rewrite | ~100 lines (198-310) |
| `.claude/agents/templates/coordinator-template.md` | Major rewrite | ~50 lines (182-233) |

## Validation Commands

After implementation, run these to validate:

```bash
# 1. Verify no code fences around Task invocations in coordinator
grep -n '```markdown' .claude/agents/research-coordinator.md
# Expected: No matches in STEP 3 section

# 2. Verify imperative directive present
grep -n 'EXECUTE NOW.*Task' .claude/agents/research-coordinator.md
# Expected: Multiple matches in STEP 3

# 3. Integration test
# Run: /create-plan "test feature" --complexity 3
# Verify: research-coordinator shows Task tool invocations
```

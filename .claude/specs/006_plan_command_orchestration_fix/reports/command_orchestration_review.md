# Command Orchestration Review - Cross-Command Analysis

## Metadata
- **Date**: 2025-12-02
- **Reviewer**: research-specialist (revise workflow)
- **Review Scope**: All workflow commands (.claude/commands/*.md)
- **Reference Plan**: /home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/plans/001-plan-command-orchestration-fix-plan.md
- **Objective**: Identify commands suffering from similar orchestration issues as /plan

## Executive Summary

**Critical Finding**: All 7 workflow commands reviewed suffer from the SAME orchestration issue identified in /plan. Every command uses the pseudo-code `Task { ... }` syntax that Claude does not recognize as actual tool invocations.

**Impact**: 7 commands affected, all using hard barrier pattern but with broken Task delegation

**Root Cause**: The pseudo-code Task invocation pattern (inherited from a common template or early implementation) was copied across all workflow commands without applying the fix from commit 0b710aff (supervise.md).

**Recommended Action**: Expand the existing plan to include ALL workflow commands, not just /plan.

## Commands Reviewed

### Commands with Orchestration Issues

1. **/build** - AFFECTED (3 Task invocations)
2. **/debug** - AFFECTED (4 Task invocations)
3. **/implement** - AFFECTED (1 Task invocation + iteration loop)
4. **/repair** - AFFECTED (2 Task invocations)
5. **/research** - AFFECTED (2 Task invocations)
6. **/revise** - AFFECTED (2 Task invocations)
7. **/test** - AFFECTED (2 Task invocations in instructional text)

**Total Affected**: 7/7 commands (100%)
**Total Broken Task Invocations**: ~16 instances across all commands

## Detailed Findings by Command

### 1. /build Command

**File**: `/home/benjamin/.config/.claude/commands/build.md`

**Issues Identified**:

#### Issue 1.1: Implementer-Coordinator Invocation (Lines 515-573)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax without imperative directive
**Location**: Block 1b (implementer-coordinator invocation)
**Agent**: implementer-coordinator
**Context**: Hard barrier pattern with verification in Block 1c

#### Issue 1.2: Spec-Updater Invocation (Lines 1083-1110)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Update plan hierarchy after implementation completion"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax (fallback invocation)
**Location**: After phase update block
**Agent**: spec-updater
**Context**: Fallback if checkbox-utils fails

#### Issue 1.3: Test-Executor Invocation (Lines 1245-1303)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute test suite with framework detection and structured reporting"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax
**Location**: Before Block 2 (testing phase)
**Agent**: test-executor
**Context**: Hard barrier pattern with structured return signal

#### Issue 1.4: Debug-Analyst Invocation (Lines 1605-1626)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Debug failed tests in build workflow"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax (conditional invocation)
**Location**: If tests failed section
**Agent**: debug-analyst
**Context**: Conditional delegation based on test results

**Severity**: HIGH - /build is a primary workflow command with 4 critical delegation points

---

### 2. /debug Command

**File**: `/home/benjamin/.config/.claude/commands/debug.md`

**Issues Identified**:

#### Issue 2.1: Topic-Naming-Agent Invocation (Lines 322-346)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax
**Location**: Block 2a (topic name generation)
**Agent**: topic-naming-agent
**Context**: Required for directory allocation

#### Issue 2.2: Research-Specialist Invocation (Lines 659-682)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research root cause for $ISSUE_DESCRIPTION"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 3 (research phase)
**Agent**: research-specialist
**Context**: Hard barrier with mandatory verification

#### Issue 2.3: Plan-Architect Invocation (Lines 946-970)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create debug strategy plan for $ISSUE_DESCRIPTION"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 4 (planning phase)
**Agent**: plan-architect
**Context**: Hard barrier with mandatory verification

#### Issue 2.4: Debug-Analyst Invocation (Lines 1203-1222)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Root cause analysis for $ISSUE_DESCRIPTION"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 5 (debug phase)
**Agent**: debug-analyst
**Context**: Hard barrier with mandatory verification

**Severity**: HIGH - /debug orchestrates 4 agents sequentially, all broken

---

### 3. /implement Command

**File**: `/home/benjamin/.config/.claude/commands/implement.md`

**Issues Identified**:

#### Issue 3.1: Implementer-Coordinator Invocation (Lines 514-576)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 1b (implementer-coordinator invocation)
**Agent**: implementer-coordinator
**Context**: Hard barrier with iteration loop support

#### Issue 3.2: Iteration Loop Pattern (Lines 879-1010)
```markdown
**ITERATION DECISION**:
- If IMPLEMENTATION_STATUS is "continuing", repeat the Task invocation above with updated ITERATION
- ...

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS})"
  prompt: "..."
}
```

**Problem**: Duplicate Task invocation for iteration continuation (same pseudo-code issue)
**Location**: After Block 1c (iteration decision)
**Agent**: implementer-coordinator (re-invocation)
**Context**: Iteration loop requires re-invoking agent with updated context

**Special Note**: /implement uses an iteration loop pattern where the same Task invocation is repeated multiple times. Each iteration requires proper imperative invocation. The plan should account for loop-based delegation patterns.

**Severity**: HIGH - /implement is critical for implementation-only workflow, iteration loop compounds the issue

---

### 4. /repair Command

**File**: `/home/benjamin/.config/.claude/commands/repair.md`

**Issues Identified**:

#### Issue 4.1: Repair-Analyst Invocation (Lines 503-530)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax
**Location**: Block 1b-exec (repair analysis delegation)
**Agent**: repair-analyst
**Context**: Hard barrier with pre-calculated report path

#### Issue 4.2: Plan-Architect Invocation (Lines 1159-1206)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax
**Location**: Block 2b-exec (plan creation delegation)
**Agent**: plan-architect
**Context**: Hard barrier with pre-calculated plan path

**Severity**: HIGH - /repair analyzes error logs and creates fix plans, critical for maintenance workflow

---

### 5. /research Command

**File**: `/home/benjamin/.config/.claude/commands/research.md`

**Issues Identified**:

#### Issue 5.1: Topic-Naming-Agent Invocation (Lines 368-395)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL label
**Location**: Block 1b-exec (topic name generation)
**Agent**: topic-naming-agent
**Context**: Hard barrier with pre-calculated output path

#### Issue 5.2: Research-Specialist Invocation (Lines 841-867)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax
**Location**: Block 1d-exec (research specialist invocation)
**Agent**: research-specialist
**Context**: Hard barrier with pre-calculated report path

**Severity**: MEDIUM-HIGH - /research is foundational for other workflows, but simpler orchestration (only 2 agents)

---

### 6. /revise Command

**File**: `/home/benjamin/.config/.claude/commands/revise.md`

**Issues Identified**:

#### Issue 6.1: Research-Specialist Invocation (Lines 623-642)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 4b (research phase execution)
**Agent**: research-specialist
**Context**: Hard barrier with mandatory verification

#### Issue 6.2: Plan-Architect Invocation (Lines 1053-1085)
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "..."
}
```

**Problem**: Pseudo-code Task syntax with CRITICAL BARRIER label
**Location**: Block 5b (plan revision execution)
**Agent**: plan-architect
**Context**: Hard barrier with mandatory verification

**Severity**: HIGH - /revise enables iterative plan improvement, critical for adaptive planning

---

### 7. /test Command

**File**: `/home/benjamin/.config/.claude/commands/test.md`

**Issues Identified**:

#### Issue 7.1: Test-Executor Invocation (Lines 388-426)
```markdown
**EXECUTE NOW**: CRITICAL BARRIER - Invoke test-executor agent to run test suite. This is a hard barrier: the agent MUST create the test output file at the pre-calculated path.

Use the Task tool to invoke the test-executor agent with the following behavioral injection:

Read and follow ALL behavioral guidelines from:
/home/benjamin/.config/.claude/agents/test-executor.md

You are executing the test execution phase for: {plan description from plan file}
...
```

**Problem**: Instructional text instead of actual Task invocation (different but related issue)
**Location**: Block 3 (test execution)
**Agent**: test-executor
**Context**: Hard barrier with pre-calculated test output path

#### Issue 7.2: Debug-Analyst Invocation (Lines 618-642)
```markdown
# Task tool invocation happens during execution:
# Use the Task tool to invoke debug-analyst with:
#
# Read and follow ALL behavioral guidelines from:
# /home/benjamin/.config/.claude/agents/debug-analyst.md
...
```

**Problem**: Commented instructional text instead of actual Task invocation
**Location**: Block 5 (debug phase, conditional)
**Agent**: debug-analyst
**Context**: Conditional debug analysis

**Special Note**: /test has a DIFFERENT but related issue - it uses instructional text comments instead of pseudo-code Task blocks. This suggests the command was written with a different template or approach. However, the underlying problem is the same: no imperative Task directive.

**Severity**: MEDIUM-HIGH - /test is critical for test execution loop, but has a different manifestation of the issue

---

## Pattern Analysis

### Common Patterns Across All Commands

1. **Hard Barrier Pattern Usage**: All commands use the hard barrier pattern correctly (pre-calculate paths, pass to agent, verify after return), but the Task invocation itself is broken.

2. **Pseudo-Code Format**: 6/7 commands use identical pseudo-code `Task { ... }` format without imperative directives.

3. **CRITICAL BARRIER Labels**: Many commands label delegation points as "CRITICAL BARRIER" or "HARD BARRIER", indicating awareness of the pattern, but fail to use imperative invocations.

4. **Verification Blocks**: All commands have verification blocks that check for artifacts, proving the architectural intent is correct—only the invocation syntax is wrong.

5. **Subprocess Isolation**: All commands properly handle subprocess isolation with state restoration, suggesting good architectural understanding elsewhere.

### Outlier: /test Command

The `/test` command uses instructional text comments instead of pseudo-code Task blocks:

```markdown
# Use the Task tool to invoke the test-executor agent with the following behavioral injection:
#
# Read and follow ALL behavioral guidelines from:
# ...
```

This suggests:
- Different authoring approach (possibly documentation-first design)
- Awareness that Task invocation needed but unclear on syntax
- May have been written before other commands or by different author

**Implication**: /test needs a different fix approach (convert instructional text to imperative Task invocations rather than just adding EXECUTE NOW directive).

---

## Issue Categorization

### By Severity

**CRITICAL (4 commands)**:
- /build (4 Task invocations, primary workflow)
- /debug (4 Task invocations, complex orchestration)
- /implement (2 Task invocations, iteration loop pattern)
- /revise (2 Task invocations, plan revision)

**HIGH (2 commands)**:
- /repair (2 Task invocations, error analysis workflow)
- /test (2 Task invocations, test execution loop)

**MEDIUM-HIGH (1 command)**:
- /research (2 Task invocations, foundational for others)

### By Agent Delegation Count

| Command | Task Invocations | Agent Types |
|---------|------------------|-------------|
| /build | 4 | implementer-coordinator, spec-updater, test-executor, debug-analyst |
| /debug | 4 | topic-naming-agent, research-specialist, plan-architect, debug-analyst |
| /implement | 2 (with iteration) | implementer-coordinator (repeated in loop) |
| /repair | 2 | repair-analyst, plan-architect |
| /research | 2 | topic-naming-agent, research-specialist |
| /revise | 2 | research-specialist, plan-architect |
| /test | 2 | test-executor, debug-analyst |

### By Fix Complexity

**Simple (Single Pass)**:
- /research: 2 straightforward Task invocations
- /repair: 2 straightforward Task invocations

**Medium (Conditional Logic)**:
- /debug: 4 Task invocations, sequential workflow
- /revise: 2 Task invocations, sequential workflow

**Complex (Iteration or Multiple Paths)**:
- /build: 4 Task invocations with conditional debug path
- /implement: 2 Task invocations with iteration loop requiring multiple invocations
- /test: 2 Task invocations with coverage loop (different syntax issue)

---

## Root Cause Analysis

### Why Did This Happen?

1. **Template Inheritance**: All commands appear to use a common command template that included the pseudo-code Task syntax.

2. **Partial Fix Application**: Commit 0b710aff fixed supervise.md with the imperative pattern, but this fix was not propagated to other commands.

3. **Documentation vs Implementation Gap**: Commands have extensive documentation about hard barriers and agent delegation, but the actual invocation syntax doesn't match Claude's requirements.

4. **Copy-Paste Propagation**: Once the pseudo-code pattern was in one command, it was likely copied to others during development.

### Why Wasn't This Caught Earlier?

1. **Permissive Tool Access**: Commands have `allowed-tools: Task, TodoWrite, Bash, Read, Grep, Glob` which allows orchestrators to fall back to doing work directly when Task invocations fail.

2. **No Validation**: No automated validation checks Task invocation syntax in command files.

3. **Testing Gap**: Integration tests may not verify actual agent delegation vs inline work.

---

## Recommended Plan Revisions

### Expand Scope to All Commands

The existing plan (001-plan-command-orchestration-fix-plan.md) should be expanded to include:

**Phase 2 Expansion** (High-Priority Orchestrator Commands):
- /plan (already in plan) ✓
- /research (add)
- /revise (add)
- /debug (add)
- /repair (add)
- /build (move from Phase 3 to Phase 2 - it's more critical)

**Phase 3 Expansion** (Remaining Commands):
- /implement (keep, but add iteration loop handling)
- /test (keep, but add note about different syntax issue)
- Remove: /build (moved to Phase 2)
- Keep remaining: errors.md, expand.md, collapse.md, setup.md, convert-docs.md, optimize-claude.md, todo.md

### Add Special Handling for Edge Cases

**Iteration Loop Pattern** (/implement, /test):
- Commands with iteration loops need multiple Task invocations fixed
- /implement: Same invocation repeated with updated context
- Plan should address loop-based delegation patterns

**Instructional Text Pattern** (/test):
- Different syntax: instructional comments instead of pseudo-code blocks
- Requires conversion from comments to imperative Task invocations
- Add to Phase 3 with special fix template

**Conditional Invocations** (/build, /test):
- Some Task invocations are conditional (e.g., only invoke debug-analyst if tests fail)
- Fix should preserve conditional logic while adding imperative directives

### Update Phase 4 Validator Requirements

The lint-task-invocation-pattern.sh linter should detect:

1. **Naked Task blocks**: `Task {` without "EXECUTE NOW" within 2 lines before (already in plan)
2. **Instructional text pattern**: Comments like `# Use the Task tool to invoke...` without actual Task invocation
3. **Iteration loop invocations**: Repeated Task invocations in loop contexts

### Update Phase 5 Documentation

Add to migration guide:
- **Iteration loop handling**: How to fix repeated Task invocations
- **Instructional text conversion**: How to convert commented instructions to imperative invocations
- **Conditional invocations**: How to preserve conditional logic while fixing invocation syntax

---

## Priority Ranking for Fixes

### Tier 1: Fix Immediately (Core Workflows)
1. **/build** - Most complex, used for full implementation workflow
2. **/implement** - Critical for implementation-only workflow, has iteration pattern
3. **/plan** - Original issue, foundational for all workflows (already in plan)

### Tier 2: Fix Next (Supporting Workflows)
4. **/debug** - Complex orchestration, 4 agents
5. **/revise** - Plan revision, iterative improvement
6. **/repair** - Error analysis and fix planning

### Tier 3: Fix Last (Specialized Workflows)
7. **/research** - Simpler orchestration, only 2 agents
8. **/test** - Different syntax issue, more isolated

---

## Specific Fix Recommendations by Command

### /build (4 Task Invocations)

**File**: .claude/commands/build.md

**Task 1: Implementer-Coordinator (Line 515)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS}) with mandatory file creation"
  prompt: "..."
}
```

**Task 2: Spec-Updater (Line 1083)** - Already has fallback context, keep as fallback only

**Task 3: Test-Executor (Line 1245)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite with framework detection and structured reporting with mandatory file creation"
  prompt: "..."
}
```

**Task 4: Debug-Analyst (Line 1605)** - Conditional, add imperative directive inside conditional block

---

### /debug (4 Task Invocations)

**File**: .claude/commands/debug.md

**All 4 invocations**: Add `**EXECUTE NOW**: USE the Task tool to invoke the [agent-name] agent.` before each Task block (lines 322, 659, 946, 1203).

Add "with mandatory file creation" to description fields.

---

### /implement (2 Task Invocations + Loop)

**File**: .claude/commands/implement.md

**Task 1: Implementer-Coordinator (Line 514)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the implementer-coordinator agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with wave-based parallelization (iteration ${ITERATION}/${MAX_ITERATIONS}) with mandatory file creation"
  prompt: "..."
}
```

**Task 2: Implementer-Coordinator Iteration (Line 944)**
Same fix, but note this is a repeated invocation in iteration loop context.

---

### /repair (2 Task Invocations)

**File**: .claude/commands/repair.md

**Task 1: Repair-Analyst (Line 503)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the repair-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze error logs and create report with mandatory file creation"
  prompt: "..."
}
```

**Task 2: Plan-Architect (Line 1159)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${ERROR_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

---

### /research (2 Task Invocations)

**File**: .claude/commands/research.md

**Task 1: Topic-Naming-Agent (Line 368)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the topic-naming-agent.

Task {
  subagent_type: "general-purpose"
  description: "Generate semantic topic directory name with mandatory file creation"
  prompt: "..."
}
```

**Task 2: Research-Specialist (Line 841)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${WORKFLOW_DESCRIPTION} with mandatory file creation"
  prompt: "..."
}
```

---

### /revise (2 Task Invocations)

**File**: .claude/commands/revise.md

**Task 1: Research-Specialist (Line 623)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research revision insights for ${REVISION_DETAILS} with mandatory file creation"
  prompt: "..."
}
```

**Task 2: Plan-Architect (Line 1053)**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Revise implementation plan based on ${REVISION_DETAILS} with mandatory file modification"
  prompt: "..."
}
```

---

### /test (2 Task Invocations - Different Format)

**File**: .claude/commands/test.md

**Task 1: Test-Executor (Lines 388-426)**

Current (instructional text):
```markdown
**EXECUTE NOW**: CRITICAL BARRIER - Invoke test-executor agent...

Use the Task tool to invoke the test-executor agent with the following behavioral injection:
```

Should be:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the test-executor agent.

Task {
  subagent_type: "general-purpose"
  description: "Execute test suite with framework detection and structured reporting with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/test-executor.md
    ...
  "
}
```

**Task 2: Debug-Analyst (Lines 618-642)**

Current (commented instructional text):
```markdown
# Task tool invocation happens during execution:
# Use the Task tool to invoke debug-analyst with:
```

Should be:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Debug test failures with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md
    ...
  "
}
```

---

## Testing Requirements

### Integration Tests Needed

For each fixed command, add integration tests to verify:

1. **Actual Delegation Occurs**
   - Agent behavioral file is read by subagent (not orchestrator)
   - Artifacts created at expected paths by subagent
   - Orchestrator does not perform subagent work inline

2. **Hard Barrier Enforcement**
   - Verification blocks detect missing artifacts
   - Workflow fails gracefully when agent doesn't create output
   - Error logging captures delegation failures

3. **Iteration Loops** (for /implement, /test)
   - Multiple invocations work correctly
   - State persists across iterations
   - Loop termination conditions respected

4. **Conditional Invocations** (for /build, /test debug path)
   - Conditional logic preserved
   - Agent only invoked when condition met
   - State correctly tracks conditional branches

### Validation Tests

1. **Linter Test Suite**
   - Detects naked Task blocks without EXECUTE NOW
   - Detects instructional text pattern without Task block
   - Accepts correct imperative pattern
   - No false positives on documentation sections

2. **Pre-Commit Hook Test**
   - Blocks commits with invalid Task invocations
   - Allows commits with correct pattern
   - Provides actionable error messages

---

## Impact Analysis

### If Not Fixed

**Context Token Waste**: 40-60% higher context usage in ALL workflow commands (not just /plan)

**Architectural Degradation**: Complete defeat of agent specialization system across the entire command suite

**Unpredictable Behavior**: Any command could bypass delegation depending on orchestrator context availability

**Testing Impossibility**: Cannot unit test agents independently if orchestrators do their work

**Maintenance Burden**: Bug fixes require changing both orchestrators and agents

### After Fix

**Context Efficiency**: 40-60% reduction in orchestrator context usage

**Architectural Integrity**: Hard barriers properly enforced, agent specialization respected

**Predictable Behavior**: Delegation always occurs, orchestrators never do subagent work

**Testability**: Agents can be unit tested, orchestrators testable separately

**Maintainability**: Single-responsibility principle restored, changes localized to appropriate agents

---

## Recommendations for Plan Update

### Immediate Actions

1. **Expand Phase 2** to include /build, /debug, /repair, /research, /revise (not just /plan)
   - These are the most critical workflow commands
   - High usage, complex orchestration, biggest impact

2. **Update Phase 3** to handle edge cases:
   - /implement: Iteration loop pattern
   - /test: Instructional text conversion

3. **Enhance Phase 4 validator** to detect:
   - Instructional text patterns (# Use the Task tool...)
   - Loop-based invocations needing multiple fixes

4. **Update Phase 5 documentation** with:
   - Migration guide for all command types
   - Special handling for iteration loops and conditional invocations

### Long-Term Improvements

1. **Command Template**: Create standardized command template with correct Task invocation syntax

2. **Automated Validation**: Integrate lint-task-invocation-pattern.sh into CI pipeline

3. **Integration Test Suite**: Add tests verifying actual delegation (not just artifact creation)

4. **Documentation Update**: Update command authoring guide with correct Task invocation examples from ALL fixed commands (not just supervise.md)

---

## Conclusion

**Finding**: All 7 workflow commands suffer from the same pseudo-code Task invocation issue as /plan. The issue is systemic, not isolated.

**Root Cause**: Template inheritance and incomplete propagation of supervise.md fix (commit 0b710aff).

**Scope Impact**: 16+ broken Task invocations across the entire command suite.

**Recommended Action**: Expand the existing plan to fix ALL workflow commands in a phased approach prioritizing by usage and complexity.

**Urgency**: HIGH - This affects every workflow in the system, wasting 40-60% more context tokens and defeating the entire agent specialization architecture.

---

## Appendix: Line Number References

### /build Command
- Line 515-573: implementer-coordinator invocation (Block 1b)
- Line 1083-1110: spec-updater invocation (fallback)
- Line 1245-1303: test-executor invocation (before Block 2)
- Line 1605-1626: debug-analyst invocation (conditional)

### /debug Command
- Line 322-346: topic-naming-agent invocation (Block 2a)
- Line 659-682: research-specialist invocation (Block 3)
- Line 946-970: plan-architect invocation (Block 4)
- Line 1203-1222: debug-analyst invocation (Block 5)

### /implement Command
- Line 514-576: implementer-coordinator invocation (Block 1b)
- Line 944-1008: implementer-coordinator re-invocation (iteration loop)

### /repair Command
- Line 503-530: repair-analyst invocation (Block 1b-exec)
- Line 1159-1206: plan-architect invocation (Block 2b-exec)

### /research Command
- Line 368-395: topic-naming-agent invocation (Block 1b-exec)
- Line 841-867: research-specialist invocation (Block 1d-exec)

### /revise Command
- Line 623-642: research-specialist invocation (Block 4b)
- Line 1053-1085: plan-architect invocation (Block 5b)

### /test Command
- Line 388-426: test-executor invocation (instructional text, Block 3)
- Line 618-642: debug-analyst invocation (commented text, Block 5)

---

**Report Complete**: REPORT_CREATED: /home/benjamin/.config/.claude/specs/006_plan_command_orchestration_fix/reports/command_orchestration_review.md

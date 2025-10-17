# Critical Issues in /orchestrate Artifact Management and Subagent Delegation

## Metadata
- **Date**: 2025-10-17
- **Report Number**: 001
- **Topic**: orchestrate_diagnostics
- **Created By**: /report command
- **Issue Severity**: CRITICAL
- **Impact**: Complete failure of hierarchical agent architecture

## Executive Summary

The `/orchestrate` command is fundamentally broken with respect to artifact management and subagent delegation. When executed, it fails to create research reports, delegates slash commands incorrectly, and consumes 308k+ tokens instead of the targeted <600 characters through metadata passing. This represents a complete failure of the hierarchical agent architecture's core design principles.

**Key Finding**: Research agents return summaries directly to the orchestrator instead of creating report files, and the `/plan` command is invoked via SlashCommand tool by the orchestrator instead of being delegated to a subagent.

## Problem Statement

### Observed Behavior (from recent execution)

Based on analysis of `/home/benjamin/.config/.claude/specs/todo/research_phase.md`, which documents a recent `/orchestrate` execution:

**Research Phase Execution**:
```
Phase 1: Research Phase (Parallel Execution)
I'll launch 4 specialized research agents in parallel to comprehensively
analyze the .claude/ directory:
1. Directory Structure & Inventory Analysis
2. Redundancy & Unused Component Detection
3. Code Quality & Efficiency Analysis
4. High-Value Functionality Documentation

● Task(Analyze .claude/ directory structure)
  ⎿  Done (26 tool uses · 47.9k tokens · 1m 44s)

● Task(Identify redundant/unused components)
  ⎿  Done (48 tool uses · 61.5k tokens · 1m 56s)

● Task(Analyze code quality issues)
  ⎿  Done (20 tool uses · 100.8k tokens · 1m 15s)

● Task(Document high-value functionality)
  ⎿  Done (18 tool uses · 79.7k tokens · 1m 32s)

● Task(Analyze context preservation opportunities)
  ⎿  Done (16 tool uses · 124.3k tokens · 1m 5s)
```

**Total Research Context Consumed**: 413.3k tokens across 5 agents

**Planning Phase Execution**:
```
Phase 2: Planning Phase

Perfect! All research is complete. Now I'll synthesize the findings
into comprehensive reports and an implementation plan using the
/report and /plan commands.

... (various tasks take place) ...

● Now let me create a comprehensive but more concise report to preserve
  context. I'll generate the complete report in a single, well-structured
  Write operation:
```

**Key Issues Observed**:
1. **No research report files created**: Research findings returned directly as 150+ word summaries
2. **Context explosion**: 103k+ tokens consumed by single research agent (expected: ~150 chars metadata)
3. **Direct `/plan` invocation**: Orchestrator called SlashCommand tool itself instead of delegating to subagent
4. **Report created late**: Single report created after planning phase, not during research

### Expected Behavior (from documentation)

According to `.claude/agents/research-specialist.md` and `.claude/templates/orchestration-patterns.md`:

**Research Phase Should**:
1. **Launch research-specialist agents in parallel** (3-4 agents)
2. **Each agent creates a report FILE** using Write tool at: `specs/reports/{topic}/NNN_*.md`
3. **Each agent returns ONLY**: `REPORT_PATH: /absolute/path/to/report.md` + 1-2 sentence summary
4. **Orchestrator receives**: Paths only (~50 chars each = ~150 chars total for 3 reports)
5. **Context reduction**: 95-99% (full reports ~3000 chars → metadata ~150 chars)

**Planning Phase Should**:
1. **Orchestrator delegates to plan-architect subagent** via Task tool
2. **Plan-architect receives**: Report PATHS (not content), workflow description, thinking mode
3. **Plan-architect invokes**: `/plan` command via SlashCommand tool
4. **Plan-architect creates**: Plan file at specified path
5. **Plan-architect returns**: `PLAN_PATH: /absolute/path/to/plan.md` + brief summary

## Root Cause Analysis

### Issue 1: Research Agents Not Creating Report Files

**Evidence**: From `/home/benjamin/.config/.claude/specs/todo/research_phase.md`:

> CURRENT EXECUTION: After conducting research with separate research agents, claude code created a single report by calling the `/report` command.
>
> DESIRED EXECUTION: I want each research subagent to create a report in `{project}/specs/reports/{NNN_topic}/NNN_report_name.md`. I then want references to these reports to be passed to the planning agent along with the instruction to read the reports and create a plan...

**Root Cause**: Research agent prompts in `/orchestrate` command do NOT explicitly instruct agents to create report files.

**Expected Prompt Pattern** (from orchestration-patterns.md lines 92-111):
```markdown
## Report File Creation

You MUST create a research report file using the Write tool. Do NOT return only a summary.

**CRITICAL: Use the Provided Absolute Path**:

The orchestrator has calculated an ABSOLUTE report file path for you. You MUST use this exact path when creating the report file:

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`

**DO NOT**:
- Recalculate the path yourself
- Use relative paths (e.g., `specs/reports/...`)
- Change the directory location
- Modify the report number

**DO**:
- Use the Write tool with the exact path provided above
- Create the report at the specified ABSOLUTE path
- Return this exact path in your REPORT_PATH: output
```

**Actual Behavior**: Research agents received prompts asking for "summary in 150 words" instead of explicit file creation instructions.

### Issue 2: Planning Phase Using SlashCommand Instead of Task Delegation

**Evidence**: From `/orchestrate` command analysis (lines 612-727 in orchestrate.md):

The planning phase section describes HOW planning should work but contains NO explicit Task tool invocation. It says:

> "I'll invoke planning agent..."
> "See [Planning Phase](../templates/orchestration-patterns.md#planning-phase-sequential-execution)"

**Expected Pattern** (from /plan command lines 103-134):
```markdown
Use Task tool to invoke 2-3 research-specialist agents in parallel:

Task tool invocation:
subagent_type: general-purpose
description: "Research {topic} for {feature}"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/research-specialist.md

  You are acting as a Research Specialist Agent.
  ...
```

**Actual Behavior**: `/orchestrate` itself invoked the `/plan` command via SlashCommand tool instead of delegating to a subagent who would then invoke `/plan`.

**Correct Delegation Pattern** (what should happen):
```
Orchestrator → Task(plan-architect agent) → plan-architect uses SlashCommand(/plan)
```

**Current Broken Pattern** (what actually happens):
```
Orchestrator → SlashCommand(/plan)  [WRONG - no agent delegation]
```

### Issue 3: Documentation-Only Command Structure

**Evidence**: From `/home/benjamin/.config/.claude/specs/reports/042_orchestrate_subagent_invocation_diagnosis.md`:

> **Location**: `.claude/commands/orchestrate.md` (1953 lines)
>
> **Problem**: The entire file is **documentation/specification** rather than **executable instructions**.
>
> **Analysis**:
> - The file describes HOW the orchestrator SHOULD work
> - It does NOT contain explicit instructions to USE the Task tool
> - Claude Code reads this as a prompt but doesn't have clear action steps
> - The phrase "I'll" is aspirational, not imperative

**Example from orchestrate.md** (Research Phase section):
```markdown
### Research Phase (Parallel Execution)

The research phase coordinates multiple specialized agents to investigate different
aspects of the workflow in parallel, then verifies all research outputs before proceeding.

**When to Use Research Phase**:
- Complex workflows requiring investigation
- Medium+ complexity
- Skip for simple tasks

**Quick Overview**:
1. Analyze workflow complexity and determine thinking mode
2. Identify 2-4 research topics based on complexity
3. Launch research-specialist agents in parallel (single message, multiple Task calls)
4. Monitor agent execution and collect report paths
5. Verify reports exist at expected paths
6. Save checkpoint with research outputs
```

**Problem**: This describes WHAT should happen, not an explicit instruction to DO IT NOW.

**Required Pattern** (what's missing):
```markdown
**EXECUTE NOW**: Launch research-specialist agents in parallel

For each research topic identified in Step 1:
1. Calculate absolute report path: `${PROJECT_DIR}/specs/reports/${TOPIC}/NNN_report.md`
2. Generate research prompt from template (lines 19-198 in orchestration-patterns.md)
3. Invoke Task tool with:
   - subagent_type: general-purpose
   - description: "Research {topic}"
   - prompt: [Template with ABSOLUTE_REPORT_PATH filled in]

Send ALL Task invocations in a SINGLE message for parallel execution.

[Then show Task invocation examples inline]
```

### Issue 4: Missing Report Path Calculation

**Evidence**: Research agents don't receive pre-calculated absolute report paths.

**From orchestration-patterns.md** (lines 28, 96-98):
```markdown
**Placeholders**:
- `[ABSOLUTE_REPORT_PATH]`: ABSOLUTE path for report file (CRITICAL - must be absolute)

**Report Path**: [ABSOLUTE_REPORT_PATH]

Example: `/home/benjamin/.config/.claude/specs/reports/orchestrate_improvements/001_existing_patterns.md`
```

**Problem**: The `/orchestrate` command doesn't calculate these paths before invoking research agents, so agents either:
1. Don't create files at all (return summaries)
2. Create files at wrong locations
3. Calculate paths themselves (leading to inconsistencies)

**Correct Flow**:
```bash
# Before invoking research agents
for TOPIC in "${RESEARCH_TOPICS[@]}"; do
  # Calculate next report number for this topic
  TOPIC_DIR="${PROJECT_DIR}/specs/reports/${TOPIC}"
  mkdir -p "$TOPIC_DIR"

  NEXT_NUM=$(ls "$TOPIC_DIR"/[0-9][0-9][0-9]_*.md 2>/dev/null | \
             sed 's/.*\/0*\([0-9]*\)_.*/\1/' | sort -n | tail -1)
  NEXT_NUM=$(printf "%03d" $((NEXT_NUM + 1)))

  REPORT_PATH="$TOPIC_DIR/${NEXT_NUM}_${TOPIC}_analysis.md"
  RESEARCH_PROMPTS["$TOPIC"]="$REPORT_PATH"
done

# Then pass REPORT_PATH to each agent in its prompt
```

## Impact Analysis

### Current State Consequences

**1. Context Window Explosion**:
- **Target**: <30% context usage through metadata passing
- **Actual**: 308k+ tokens consumed in research phase alone
- **Failure**: 1000x+ higher than target (308k vs 300 chars)

**2. No Artifact Persistence**:
- **Expected**: 3-4 report files created in `specs/reports/{topic}/NNN_*.md`
- **Actual**: No report files created during research phase
- **Impact**: Cannot reference research findings in later phases

**3. Broken Hierarchical Architecture**:
- **Expected**: Orchestrator → Task(agent) → agent performs work → returns metadata
- **Actual**: Orchestrator directly receives full research output (breaking encapsulation)
- **Impact**: No context isolation, no parallelization benefits, no agent specialization

**4. Planning Phase Inefficiency**:
- **Expected**: plan-architect agent reads report files selectively as needed
- **Actual**: plan-architect receives no report files (nothing created)
- **Impact**: Cannot synthesize research findings (they're in chat history, not files)

**5. Missing Workflow Artifacts**:
- **Expected**: Cross-referenced artifacts (reports → plan → summary)
- **Actual**: Incomplete artifact chain (missing reports, direct plan creation)
- **Impact**: Cannot audit workflow, cannot resume, cannot reuse research

### Performance Metrics Failure

**Hierarchical Agent Architecture Goals** (from CLAUDE.md):

> **Context Reduction Metrics**
> - **Target**: <30% context usage throughout workflows
> - **Achieved**: 92-97% reduction through metadata-only passing
> - **Performance**: 60-80% time savings with parallel subagent execution

**Actual Performance** (from evidence):
- **Context Reduction**: 0% (full summaries returned, not metadata)
- **Time Savings**: Unknown (parallel execution occurred, but without artifact creation)
- **Metadata Passing**: Failed (no REPORT_PATH: format returned)

## Systemic Issues in Other Commands

### Similar Problems in /plan Command

**Evidence**: `/home/benjamin/.config/.claude/commands/plan.md` lines 103-134 show correct delegation:

```markdown
**Step 4: Invoke Research Subagents in Parallel**

Use Task tool to invoke 2-3 research-specialist agents in parallel:

Task tool invocation:
subagent_type: general-purpose
description: "Research {topic} for {feature}"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/research-specialist.md
```

**However**: The `/plan` command is being invoked BY the orchestrator via SlashCommand instead of the orchestrator delegating to a plan-architect agent who would then call `/plan`.

**Correct Hierarchy**:
```
/orchestrate
  └→ Task(plan-architect agent)
      └→ plan-architect uses SlashCommand(/plan)
          └→ /plan optionally uses Task(research-specialist)
```

**Current Broken Hierarchy**:
```
/orchestrate
  └→ SlashCommand(/plan)  [WRONG - skipped agent layer]
      └→ /plan uses Task(research-specialist)
```

### Delegation Pattern Violations

**Commands That Should Be Delegated to Subagents**:

1. **/plan** - Should be invoked by plan-architect agent, not orchestrator
2. **/implement** - Should be invoked by code-writer agent, not orchestrator
3. **/debug** - Should be invoked by debug-specialist agent, not orchestrator
4. **/document** - Should be invoked by doc-writer agent, not orchestrator

**From orchestrate.md** (lines 2680-2710):

> ### Agent Usage
>
> This command uses specialized agents for each workflow phase:
>
> ### Research Phase
> - **Agent**: `research-specialist` (multiple instances in parallel)
>
> ### Planning Phase
> - **Agent**: `plan-architect`
> - **Purpose**: Generate structured implementation plans from research findings
> - **Invocation**: Single agent, sequential execution

**Problem**: Documentation states plan-architect agent should be used, but actual execution shows SlashCommand(/plan) invocation instead.

## Recommendations

### Immediate Fixes (Critical Priority)

#### 1. Fix Research Agent Prompts in /orchestrate

**Location**: `.claude/commands/orchestrate.md` Research Phase section

**Required Changes**:

a. **Calculate Report Paths Before Agent Invocation**:
```bash
# Add before "EXECUTE NOW: Invoke Research Agents"
RESEARCH_TOPICS=("existing_patterns" "best_practices" "alternatives")
declare -A REPORT_PATHS

for TOPIC in "${RESEARCH_TOPICS[@]}"; do
  TOPIC_DIR="${PROJECT_DIR}/specs/reports/${TOPIC}"
  mkdir -p "$TOPIC_DIR"

  NEXT_NUM=$(find "$TOPIC_DIR" -name "[0-9][0-9][0-9]_*.md" | \
             sed 's/.*\/0*\([0-9]*\)_.*/\1/' | sort -n | tail -1)
  NEXT_NUM=$(printf "%03d" $((${NEXT_NUM:-0} + 1)))

  REPORT_PATHS["$TOPIC"]="$TOPIC_DIR/${NEXT_NUM}_${TOPIC}_analysis.md"
done
```

b. **Update Research Agent Prompt Template**:
```markdown
**EXECUTE NOW**: For each research topic, invoke Task tool with this prompt:

Task tool invocation:
subagent_type: general-purpose
description: "Research ${TOPIC} using research-specialist protocol"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/research-specialist.md

  You are acting as a Research Specialist Agent.

  ## Research Task: ${TOPIC_TITLE}

  **CRITICAL: Create Report File**

  You MUST create a research report file using the Write tool at this EXACT path:

  **Report Path**: ${REPORT_PATHS[$TOPIC]}

  Example: /home/benjamin/.config/.claude/specs/reports/existing_patterns/001_analysis.md

  DO NOT return a summary. CREATE THE FILE.

  [Rest of research requirements...]

  ## Expected Output

  **Primary Output**: Report file path in this EXACT format:
  ```
  REPORT_PATH: ${REPORT_PATHS[$TOPIC]}
  ```

  **Secondary Output**: Brief summary (1-2 sentences ONLY):
  - What was researched
  - Key finding or primary recommendation

  SUCCESS CRITERIA:
  - Report file created at specified path
  - File contains complete findings (not abbreviated)
  - REPORT_PATH returned in parseable format
```

c. **Add Verification After Agent Completion**:
```markdown
**EXECUTE AFTER ALL AGENTS COMPLETE**: Verify all report files created

For each expected report path:
1. Check file exists: `[ -f "$REPORT_PATH" ]`
2. Check file not empty: `[ -s "$REPORT_PATH" ]`
3. If missing: Search for alternative location using Glob
4. If still missing: Retry agent invocation with emphasized path instruction
5. If retry fails: Escalate to user

Only proceed to Planning Phase after ALL reports verified.
```

#### 2. Fix Planning Phase Delegation in /orchestrate

**Location**: `.claude/commands/orchestrate.md` Planning Phase section

**Current (Broken)**:
```markdown
I'll synthesize findings into implementation plan using /plan command.

[Calls SlashCommand(/plan) directly]
```

**Required (Fixed)**:
```markdown
**EXECUTE NOW**: Delegate planning to plan-architect agent

Task tool invocation:
subagent_type: general-purpose
description: "Create implementation plan using plan-architect protocol"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/plan-architect.md

  You are acting as a Plan Architect Agent.

  ## Planning Task: Create Implementation Plan

  ### Context
  - **Workflow**: ${WORKFLOW_DESCRIPTION}
  - **Project Name**: ${PROJECT_NAME}
  - **Thinking Mode**: ${THINKING_MODE}
  - **Project Standards**: /home/benjamin/.config/CLAUDE.md

  ### Research Reports Available

  You have access to these research reports created during research phase:

  ${FOR each REPORT_PATH}
  - ${REPORT_PATH}
  ${END FOR}

  **IMPORTANT**: Use Read tool to access report content. Do not ask for summaries.

  ### Your Task

  1. Read all research reports to understand findings
  2. Use SlashCommand tool to invoke: /plan "${WORKFLOW_DESCRIPTION}" ${REPORT_PATHS[@]}
  3. Verify plan file created successfully
  4. Return plan path in format: PLAN_PATH: /absolute/path/to/plan.md

  ## Success Criteria
  - Plan file created via /plan command
  - Plan references all research reports
  - Plan path returned in parseable format
```

#### 3. Add "EXECUTE NOW" Blocks Throughout /orchestrate

**Pattern**: After each descriptive section, add explicit execution block.

**Template**:
```markdown
### Phase N: [Phase Name] ([Execution Mode])

[Description of what this phase does - can keep existing documentation]

**Pattern Details**: See [Phase Template](../templates/orchestration-patterns.md#phase-template)

**EXECUTE NOW**: [Imperative instructions]

1. [Action 1 with tool/function to use]
2. [Action 2 with tool/function to use]
3. [Verification step]

[Inline code examples or tool invocations]

**Verification Checklist**:
- [ ] [Expected outcome 1]
- [ ] [Expected outcome 2]
- [ ] Ready to proceed to next phase

If any checkbox unchecked, STOP and complete missing steps.
```

### Medium-Priority Fixes

#### 4. Update All Delegation Patterns

**Commands to Update**:
- `/orchestrate` → Fix all phase delegations (research, planning, implementation, debugging, documentation)
- `/plan` → Ensure research delegation uses correct format
- `/implement` → Verify code-writer delegation
- `/debug` → Verify debug-specialist delegation

**Delegation Pattern Template**:
```markdown
**EXECUTE NOW**: Delegate [task] to [agent-type] agent

Task tool invocation:
subagent_type: general-purpose
description: "[Brief task description]"
prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/[agent-file].md

  You are acting as a [Agent Type] Agent.

  [Agent-specific task details]

  ## Expected Output
  - Primary: [ARTIFACT_PATH_TYPE]: /absolute/path/to/artifact.md
  - Secondary: Brief summary (1-2 sentences)
```

#### 5. Create Validation Test Suite

**Test Cases**:

1. **Test: Research Phase Creates Report Files**
   ```bash
   # Execute /orchestrate with simple workflow
   /orchestrate "Test research phase artifact creation"

   # Verify: 2-3 report files created in specs/reports/*/NNN_*.md
   # Verify: Each research agent returned REPORT_PATH: format
   # Verify: Context usage <1000 chars (not 100k+ tokens)
   ```

2. **Test: Planning Phase Uses Subagent Delegation**
   ```bash
   # Monitor Task tool invocations
   # Verify: plan-architect agent invoked via Task
   # Verify: plan-architect then invokes /plan via SlashCommand
   # Verify: NOT orchestrator directly calling SlashCommand(/plan)
   ```

3. **Test: End-to-End Artifact Chain**
   ```bash
   # Execute full workflow
   /orchestrate "Complete test workflow with all phases"

   # Verify artifact chain:
   # - specs/reports/{topic1}/001_*.md (research)
   # - specs/reports/{topic2}/001_*.md (research)
   # - specs/plans/NNN_*.md (planning, references reports)
   # - specs/summaries/NNN_*.md (documentation, references plan+reports)
   ```

### Long-Term Improvements

#### 6. Command Architecture Standards Enforcement

**Create Validation Tool**: `.claude/lib/validate-command.sh`

**Checks**:
- [ ] Command contains "EXECUTE NOW" blocks for each action
- [ ] Agent delegations use Task tool (not SlashCommand for /commands)
- [ ] Artifact paths calculated before agent invocation
- [ ] Verification steps included after agent completion
- [ ] Checkpoint saves after each major phase
- [ ] Error recovery patterns implemented

**Usage**:
```bash
.claude/lib/validate-command.sh .claude/commands/orchestrate.md
```

#### 7. Documentation Cleanup

**Separate Concerns**:
- **Command Files** (`.claude/commands/*.md`): Executable instructions ONLY
  - Use imperative voice ("EXECUTE", "INVOKE", "VERIFY")
  - Inline critical tool invocations
  - Include explicit verification steps

- **Documentation Files** (`.claude/docs/*.md`): Explanatory content ONLY
  - Describe architecture and patterns
  - Explain design decisions
  - Provide examples and best practices

**Example Command Structure**:
```markdown
# /orchestrate Command

[Brief description]

**Reference Documentation**: See `.claude/docs/orchestration-guide.md` for architecture

## Workflow Execution

### Phase 1: Research (Parallel)

**EXECUTE NOW**: Launch research agents

[Inline Task tool invocations]

**Verification**:
- [ ] All report files created
- [ ] All agents returned REPORT_PATH
- [ ] Ready for planning phase

[Continue with explicit execution blocks for each phase]
```

## Testing Strategy

### Unit Tests (Command-Level)

**Test File**: `.claude/tests/test_orchestrate_artifact_creation.sh`

```bash
#!/bin/bash

# Test 1: Research agents create report files
test_research_creates_files() {
  # Setup
  WORKFLOW="Test simple feature"

  # Execute
  OUTPUT=$(/orchestrate "$WORKFLOW")

  # Assert
  REPORT_COUNT=$(find .claude/specs/reports -name "[0-9][0-9][0-9]_*.md" | wc -l)
  [ "$REPORT_COUNT" -ge 2 ] || fail "Expected ≥2 reports, found $REPORT_COUNT"

  # Verify REPORT_PATH format in output
  grep -q "REPORT_PATH: /" <<< "$OUTPUT" || fail "No REPORT_PATH found in output"
}

# Test 2: Planning uses plan-architect agent
test_planning_delegates_to_agent() {
  # Execute
  OUTPUT=$(/orchestrate "$WORKFLOW")

  # Assert: Should see Task(plan-architect) in output, NOT SlashCommand(/plan)
  grep -q "Task.*plan-architect" <<< "$OUTPUT" || fail "plan-architect not invoked"
  ! grep -q "SlashCommand.*plan" <<< "$OUTPUT" || fail "Direct /plan invocation found"
}

# Test 3: Context usage < target
test_context_usage_under_threshold() {
  # Execute
  OUTPUT=$(/orchestrate "$WORKFLOW")

  # Parse context usage from output
  RESEARCH_CONTEXT=$(grep "Done.*tokens" <<< "$OUTPUT" | awk '{sum+=$5} END {print sum}')

  # Assert: Total research context should be <10k tokens (not 308k)
  [ "$RESEARCH_CONTEXT" -lt 10000 ] || fail "Context too high: ${RESEARCH_CONTEXT}k tokens"
}

# Run tests
test_research_creates_files
test_planning_delegates_to_agent
test_context_usage_under_threshold

echo "All tests passed"
```

### Integration Tests (Workflow-Level)

**Test: Complete Workflow Artifact Chain**

```bash
#!/bin/bash

# Execute full workflow
/orchestrate "Implement test feature with authentication"

# Verify complete artifact chain exists
REPORTS=$(find .claude/specs/reports -name "[0-9][0-9][0-9]_*.md" | wc -l)
PLANS=$(find .claude/specs/plans -name "[0-9][0-9][0-9]_*.md" | wc -l)
SUMMARIES=$(find .claude/specs/summaries -name "[0-9][0-9][0-9]_*.md" | wc -l)

[ "$REPORTS" -ge 2 ] || fail "Expected ≥2 reports"
[ "$PLANS" -eq 1 ] || fail "Expected 1 plan"
[ "$SUMMARIES" -eq 1 ] || fail "Expected 1 summary"

# Verify cross-references
PLAN_FILE=$(find .claude/specs/plans -name "[0-9][0-9][0-9]_*.md" | head -1)
grep -q "Research Reports:" "$PLAN_FILE" || fail "Plan doesn't reference reports"

SUMMARY_FILE=$(find .claude/specs/summaries -name "[0-9][0-9][0-9]_*.md" | head -1)
grep -q "Plan:" "$SUMMARY_FILE" || fail "Summary doesn't reference plan"

echo "Workflow artifact chain validated"
```

## Success Criteria

**Implementation Complete When**:

1. **Research Phase**:
   - [ ] All research agents create report files at specified paths
   - [ ] All agents return `REPORT_PATH: /absolute/path` format
   - [ ] Context usage <10k tokens for research phase (not 308k+)
   - [ ] Report files contain complete findings (not abbreviated summaries)

2. **Planning Phase**:
   - [ ] Orchestrator delegates to plan-architect agent via Task tool
   - [ ] plan-architect agent invokes /plan via SlashCommand
   - [ ] Plan file references all research reports
   - [ ] Plan file created at correct numbered location

3. **Agent Delegation**:
   - [ ] All slash commands invoked BY agents, not BY orchestrator
   - [ ] Correct hierarchy: Orchestrator → Task(agent) → agent uses SlashCommand(command)
   - [ ] No direct SlashCommand invocations by orchestrator

4. **Artifact Management**:
   - [ ] Complete artifact chain: reports → plan → implementation → summary
   - [ ] All artifacts cross-reference related artifacts
   - [ ] Artifacts created in topic-based directory structure
   - [ ] Gitignore compliance maintained

5. **Test Coverage**:
   - [ ] Unit tests verify report file creation
   - [ ] Unit tests verify delegation patterns
   - [ ] Integration tests verify complete workflow
   - [ ] Tests run in CI/CD pipeline

## Related Issues

### Previous Diagnostic Reports

- **042_orchestrate_subagent_invocation_diagnosis.md** - Initial diagnosis of delegation failures
- **043_orchestrate_implement_improvement_opportunities.md** - Broader improvement analysis

### Dependent Fixes Required

1. **orchestration-patterns.md** - Templates are correct, need enforcement in orchestrate.md
2. **research-specialist.md** - Agent behavioral guidelines are correct
3. **orchestrate.md** - Primary fix location (research and planning phases)
4. **plan.md** - Secondary fix (ensure not invoked directly by orchestrator)

## Conclusion

The `/orchestrate` command's artifact management and subagent delegation is completely broken. Research agents don't create report files, planning phase doesn't delegate to agents, and context usage is 1000x higher than target. This represents a fundamental violation of the hierarchical agent architecture's core principles.

**Priority**: CRITICAL - This affects every multi-agent workflow
**Complexity**: HIGH - Requires coordinated fixes across multiple command files
**Impact**: Complete failure of context preservation and hierarchical delegation

**Recommended Approach**: Implement immediate fixes (Section 1-3) first, validate with tests, then proceed with medium and long-term improvements.

## References

### Primary Evidence
- `.claude/specs/todo/research_phase.md` - Actual execution behavior documented by user
- `.claude/templates/orchestration-patterns.md` - Correct agent prompt templates
- `.claude/agents/research-specialist.md` - Agent behavioral guidelines (correct)
- `.claude/commands/orchestrate.md` - Primary command file (broken)

### Secondary Evidence
- `.claude/specs/reports/042_orchestrate_subagent_invocation_diagnosis.md` - Prior diagnosis
- `.claude/commands/plan.md` - Shows correct delegation pattern for comparison
- `CLAUDE.md` - Hierarchical agent architecture goals and metrics

### Related Documentation
- `.claude/docs/hierarchical_agents.md` - Architecture overview
- `.claude/docs/command_architecture_standards.md` - Command structure guidelines
- `.claude/docs/command-patterns.md` - Pattern library (mostly correct)

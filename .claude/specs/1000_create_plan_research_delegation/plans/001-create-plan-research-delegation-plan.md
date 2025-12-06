# Implementation Plan: /create-plan Research Delegation Refactor

## Metadata
- **Date**: 2025-12-04 (Revised)
- **Feature**: Refactor /create-plan to enforce mandatory subagent delegation for both research AND planning phases
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-create-plan-research-delegation-analysis.md](../reports/001-create-plan-research-delegation-analysis.md)

## Overview

The `/create-plan` command currently **completely bypasses subagent delegation** for BOTH research AND planning phases. Analysis of `/home/benjamin/.config/.claude/output/create-plan-output.md` shows:

1. **Research phase failure**: Primary agent directly executed `Read()`, `Search()`, `Glob()` operations (lines 17-71) instead of invoking Task tool for research-specialist
2. **Research artifact failure**: Primary agent directly wrote the research report using `Write()` (lines 84-87) instead of having research-specialist create it
3. **Planning phase failure**: Primary agent directly wrote the plan using `Write()` (lines 99-113) instead of invoking Task tool for plan-architect

### Root Cause Analysis

The current `Task { ... }` pseudo-code syntax in the command file is **NOT an actual tool invocation**. The primary agent interprets this as descriptive text and performs the work directly. This violates:

- **Task Tool Invocation Patterns** from CLAUDE.md code-standards section
- **Hierarchical Agent Architecture** requiring subagent delegation

### Solution Approach

This plan refactors the command to use:

1. **Imperative directive pattern** for Task invocations: `**EXECUTE NOW**: USE the Task tool...`
2. **Hard barrier verification blocks** that FAIL if subagent artifacts are missing
3. **Explicit bash block completion** before Task invocation to create context barrier
4. **Complexity-based routing** to research-sub-supervisor for complex research (complexity 3-4)
5. **Report summary extraction** for efficient plan-architect context

## Success Criteria
- [ ] Primary orchestrator performs NO research directly (no Read/Grep/Glob for research purposes)
- [ ] Primary orchestrator performs NO planning directly (no Write for plan creation)
- [ ] Hard barrier verification blocks prevent bypass of research delegation
- [ ] Hard barrier verification blocks prevent bypass of planning delegation
- [ ] Complexity 1-2 routes to single research-specialist
- [ ] Complexity 3-4 routes to research-sub-supervisor with parallel workers
- [ ] Report summaries passed to plan-architect (not just paths)
- [ ] Plan-architect creates plan file (not primary orchestrator)
- [ ] 95% context reduction achieved for complex research via metadata aggregation

---

## Phase 1: Fix Task Invocation Pattern for Research Delegation [COMPLETE]

**Objective**: Replace pseudo-code `Task { ... }` syntax with mandatory imperative directives that enforce actual Task tool invocation

### Root Cause Fix

The current Block 1d uses pseudo-code syntax that the agent interprets as descriptive text:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION}..."
  prompt: "..."
}
```

This MUST be replaced with the imperative directive pattern per CLAUDE.md Task Tool Invocation Patterns:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
- **prompt**: [full prompt text]

DO NOT perform research directly. DO NOT use Read/Grep/Glob for research.
The Task tool invocation is MANDATORY.
```

### Tasks
- [ ] Replace Block 1d pseudo-code with imperative directive pattern
- [ ] Add explicit "DO NOT" prohibitions before Task invocation:
  - "DO NOT perform research directly"
  - "DO NOT use Read/Grep/Glob for research purposes"
  - "DO NOT use Write to create research reports"
- [ ] Add CHECKPOINT bash block BEFORE Task invocation to create context barrier
- [ ] Add REPORT_PATH pre-calculation in setup block (hard barrier pattern)
- [ ] Add Block 1e "Research Output Verification" with:
  - Hard barrier check: file existence at REPORT_PATH
  - File size validation (≥100 bytes)
  - Content validation (## Findings section exists)
  - Fail-fast on validation failure with recovery hints
  - Error logging via log_command_error()

### Critical Pattern: Context Barrier

The bash block MUST complete and emit a CHECKPOINT BEFORE the Task invocation section:
```markdown
## Block 1d: Research Setup and Context Barrier

**EXECUTE NOW**: Execute the bash block below to prepare for research delegation.

\`\`\`bash
# ... setup code ...
echo "CHECKPOINT: Research setup complete, ready for Task invocation"
\`\`\`

## Block 1d-exec: Research Specialist Invocation

**CRITICAL BARRIER**: The bash block above MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

You MUST use the Task tool with these EXACT parameters:
...
```

### Dependencies
- Existing infrastructure: validation-utils.sh, state-persistence.sh, error-handling.sh

### Success Criteria
- [ ] Imperative directive "**EXECUTE NOW**: USE the Task tool" present before each Task invocation
- [ ] Explicit "DO NOT" prohibitions prevent direct research by primary agent
- [ ] CHECKPOINT bash block creates context barrier before Task invocation
- [ ] Block 1e fails workflow if research-specialist doesn't create report at REPORT_PATH
- [ ] No research operations (Read/Grep/Glob for research) in primary orchestrator after Block 1c

---

## Phase 2: Fix Task Invocation Pattern for Planning Delegation [COMPLETE]

**Objective**: Apply the same imperative directive fix to the planning phase Task invocation

### Root Cause

The planning Task invocation after Block 2 also uses pseudo-code syntax:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan for ${FEATURE_DESCRIPTION}..."
  prompt: "..."
}
```

The primary agent interpreted this as descriptive text and wrote the plan directly using Write() instead of delegating to plan-architect.

### Tasks
- [ ] Replace Block 2 plan-architect pseudo-code with imperative directive pattern
- [ ] Add explicit "DO NOT" prohibitions before Task invocation:
  - "DO NOT write the plan file directly"
  - "DO NOT use Write tool for plan creation"
  - "The plan-architect subagent MUST create the plan file"
- [ ] Add CHECKPOINT at end of Block 2 bash block to create context barrier
- [ ] Add PLAN_PATH pre-calculation in Block 2 setup (already exists, but verify passed to subagent)
- [ ] Add Block 3a "Planning Output Verification" BEFORE Block 3 completion with:
  - Hard barrier check: file existence at PLAN_PATH
  - File size validation (≥500 bytes)
  - Structure validation (## Metadata, ### Phase headings exist)
  - Fail-fast on validation failure with recovery hints

### Critical Pattern: Block 2 Structure

```markdown
## Block 2: Research Verification and Planning Setup

**EXECUTE NOW**: Execute the bash block below to verify research and prepare for planning.

\`\`\`bash
# ... verification and setup code ...
echo "CHECKPOINT: Planning setup complete, ready for Task invocation"
\`\`\`

## Block 2-exec: Plan-Architect Invocation

**CRITICAL BARRIER**: The bash block above MUST complete before proceeding.

**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "Create implementation plan for ${FEATURE_DESCRIPTION}"
- **prompt**: [full prompt text]

DO NOT write the plan file directly. DO NOT use Write tool for plan creation.
The Task tool invocation is MANDATORY.
```

### Dependencies
- Phase 1 (research delegation fix must be complete first)
- plan-architect.md agent (already exists)

### Success Criteria
- [ ] Imperative directive "**EXECUTE NOW**: USE the Task tool" present for plan-architect invocation
- [ ] Explicit "DO NOT" prohibitions prevent direct plan writing by primary agent
- [ ] CHECKPOINT bash block creates context barrier before Task invocation
- [ ] Block 3a fails workflow if plan-architect doesn't create plan at PLAN_PATH
- [ ] No Write operations for plan file in primary orchestrator

---

## Phase 3: Add Complexity-Based Routing [NOT STARTED]

**Objective**: Route research to appropriate agent based on complexity flag

### Tasks
- [ ] Add routing logic in Block 1d based on RESEARCH_COMPLEXITY:
  ```bash
  if [ "$RESEARCH_COMPLEXITY" -ge 3 ]; then
    RESEARCH_MODE="hierarchical"
    # Calculate multiple report paths for parallel workers
  else
    RESEARCH_MODE="flat"
    # Single report path for research-specialist
  fi
  ```
- [ ] Add Block 1d-exec-hierarchical for complexity 3-4:
  - Invoke research-sub-supervisor instead of research-specialist
  - Pass topics array derived from feature description
  - Pass output directory and state file
- [ ] Add topic extraction helper in setup block:
  - Parse feature description for distinct research areas
  - Generate topics array for research-sub-supervisor
  - Default to 3-4 topics for complexity 3-4

### Dependencies
- Phase 2 (planning delegation fix must be complete)
- research-sub-supervisor.md agent (already exists)

### Success Criteria
- [ ] Complexity 1-2 invokes research-specialist directly
- [ ] Complexity 3-4 invokes research-sub-supervisor
- [ ] Multiple research reports created in parallel for hierarchical mode
- [ ] SUPERVISOR_COMPLETE signal parsed in Block 1e

---

## Phase 4: Update Block 1e for Hierarchical Verification [NOT STARTED]

**Objective**: Verify outputs from both flat and hierarchical research modes

### Tasks
- [ ] Add conditional verification logic:
  ```bash
  if [ "$RESEARCH_MODE" = "hierarchical" ]; then
    # Verify multiple reports from research-sub-supervisor
    # Parse aggregated metadata from SUPERVISOR_COMPLETE signal
  else
    # Verify single report from research-specialist
  fi
  ```
- [ ] Extract aggregated metadata from research-sub-supervisor response:
  - Parse reports_created array
  - Extract combined summary
  - Store key_findings for plan-architect
- [ ] Validate all expected reports exist (for hierarchical mode)
- [ ] Calculate and log context reduction percentage

### Dependencies
- Phase 3 (routing logic must exist)

### Success Criteria
- [ ] Block 1e validates correct output based on RESEARCH_MODE
- [ ] Aggregated metadata extracted and persisted for plan-architect
- [ ] Context reduction logged (target: ≥90%)

---

## Phase 5: Integrate Report Summaries into Plan-Architect Invocation [NOT STARTED]

**Objective**: Pass research summaries to plan-architect for efficient context usage

### Tasks
- [ ] Add summary extraction logic in Block 2 (before plan-architect):
  ```bash
  REPORT_SUMMARIES=""
  for report in $(find "$RESEARCH_DIR" -name '*.md' | sort); do
    summary=$(extract_report_summary "$report")
    REPORT_SUMMARIES+="### $(basename "$report")\n$summary\n\n"
  done
  ```
- [ ] Add extract_report_summary function to standards-extraction.sh or create new lib:
  - Extract ## Executive Summary section
  - Limit to 100 words per report
  - Format as structured text
- [ ] Update plan-architect Task prompt to include REPORT_SUMMARIES:
  - Pass summaries in Workflow-Specific Context
  - Maintain REPORT_PATHS_LIST for full report access
- [ ] Update plan-architect.md behavioral file if needed:
  - Document expected REPORT_SUMMARIES input
  - Clarify when to read full reports vs use summaries

### Dependencies
- Phase 4 (verification must validate reports)

### Success Criteria
- [ ] plan-architect receives research summaries (not just paths)
- [ ] plan-architect can still access full reports when needed
- [ ] Context usage reduced in plan-architect prompt

---

## Phase 6: Testing and Validation [COMPLETE]

**Objective**: Verify refactored command works correctly for all complexity levels

### Tasks
- [ ] Create test script: test_create_plan_research_delegation.sh
- [ ] Test Case 1: Simple feature (complexity 1)
  - Verify research-specialist invoked via Task tool (not directly by orchestrator)
  - Verify single report created BY research-specialist (not by orchestrator)
  - Verify plan created BY plan-architect (not by orchestrator)
- [ ] Test Case 2: Medium feature (complexity 2)
  - Verify research-specialist invoked via Task tool
  - Verify NO research operations (Read/Grep/Glob) in orchestrator output
  - Verify NO Write operations for plan/report in orchestrator output
- [ ] Test Case 3: Complex feature (complexity 3)
  - Verify research-sub-supervisor invoked
  - Verify multiple reports created in parallel
  - Verify aggregated metadata parsed
- [ ] Test Case 4: Very complex feature (complexity 4)
  - Verify parallel execution
  - Verify 95% context reduction
- [ ] Test Case 5: Hard barrier failure (research)
  - Simulate research-specialist failure (no report created)
  - Verify Block 1e fails workflow with recovery hints
- [ ] Test Case 6: Hard barrier failure (planning)
  - Simulate plan-architect failure (no plan created)
  - Verify Block 3a fails workflow with recovery hints
- [ ] Validate no regression in existing functionality

### Dependencies
- Phase 5 (all implementation complete)

### Success Criteria
- [ ] All 6 test cases pass
- [ ] No research performed directly by orchestrator (grep output for Read/Grep/Glob in orchestrator context)
- [ ] No plan writing directly by orchestrator (grep output for Write in orchestrator context)
- [ ] Hard barrier prevents research bypass
- [ ] Hard barrier prevents planning bypass

---

## Phase 7: Documentation Updates [COMPLETE]

**Objective**: Update command guide and troubleshooting documentation

### Tasks
- [ ] Update .claude/docs/guides/commands/create-plan-command-guide.md:
  - Document imperative directive pattern requirement
  - Document complexity-based routing
  - Document hard barrier pattern usage
  - Add examples for each complexity level
- [ ] Update .claude/docs/troubleshooting/create-plan-command-errors.md:
  - Add "Research delegation failed" troubleshooting section
  - Add "Planning delegation failed" troubleshooting section
  - Add "Hard barrier verification failed" section
  - Add "research-sub-supervisor failed" section
- [ ] Update command-reference.md:
  - Note complexity flag affects research routing
- [ ] Update CLAUDE.md Task Tool Invocation Patterns section:
  - Add explicit prohibition against pseudo-code `Task { ... }` syntax
  - Document imperative directive as MANDATORY pattern
- [ ] Add reference to this plan in TODO.md via /todo command

### Dependencies
- Phase 6 (testing complete)

### Success Criteria
- [ ] Documentation reflects new architecture
- [ ] Documentation explicitly prohibits pseudo-code Task syntax
- [ ] Troubleshooting covers new failure modes (research AND planning)
- [ ] Examples demonstrate all complexity levels

---

## Technical Notes

### Block Structure (Post-Refactor)

```
Block 1a: Initial Setup and State Initialization
Block 1b: Topic Name File Path Pre-Calculation
Block 1b-exec: Topic Name Generation (Task tool - topic-naming-agent)
Block 1c: Topic Name Hard Barrier Validation
Block 1d: Topic Path Initialization
Block 1e: Research Setup and Context Barrier [NEW - CHECKPOINT]
Block 1e-exec: Research Specialist Invocation [REFACTORED - imperative directive]
  OR Block 1e-exec-hierarchical: Research-Sub-Supervisor Invocation [NEW]
Block 1f: Research Output Verification [NEW - hard barrier]
Block 2: Research Verification and Planning Setup [CHECKPOINT at end]
Block 2-exec: Plan-Architect Invocation [REFACTORED - imperative directive]
Block 3a: Planning Output Verification [NEW - hard barrier]
Block 3: Plan Verification and Completion
```

### Critical Pattern: Imperative Directive for Task Invocation

**PROHIBITED** (causes delegation bypass):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "..."
  prompt: "..."
}
```

**REQUIRED** (enforces actual Task tool invocation):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the [agent-name] agent.

You MUST use the Task tool with these EXACT parameters:
- **subagent_type**: "general-purpose"
- **description**: "[task description]"
- **prompt**: "[prompt text]"

DO NOT [perform the action directly].
The Task tool invocation is MANDATORY.
```

### Key Pattern: Hard Barrier with Context Barrier

From `.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md`:

1. **Setup Block (Na)**: Calculate output path, persist to state, emit CHECKPOINT
2. **Execute Block (Nb)**: Task invocation ONLY with imperative directive, pass path as contract
3. **Verify Block (Nc)**: Validate file exists at exact path, fail-fast with error logging

### Context Reduction Target

- Single research-specialist: ~2,500 tokens per report
- research-sub-supervisor (4 topics): 10,000 tokens → 500 tokens (95% reduction)

### Error Handling Integration

All verification failures must use:
```bash
log_command_error \
  "$COMMAND_NAME" \
  "$WORKFLOW_ID" \
  "$USER_ARGS" \
  "agent_error" \
  "Message describing failure" \
  "bash_block_1f" \
  "$(jq -n --arg path "$REPORT_PATH" '{expected_path: $path}')"
```

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-04 | Initial plan created |
| 1.1 | 2025-12-04 | Revised to fix BOTH research AND planning delegation failures. Added Phase 2 for planning delegation fix. Documented root cause as pseudo-code `Task { ... }` syntax being interpreted as descriptive text. Added imperative directive pattern requirement. Renumbered phases (6 → 7 total). |

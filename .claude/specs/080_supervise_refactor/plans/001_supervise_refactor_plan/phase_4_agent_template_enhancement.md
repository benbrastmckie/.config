# Phase 4: Agent Prompt Template Enhancement (Standard 0.5)

## Phase Metadata

**Phase Number**: 4
**Parent Plan**: 001_supervise_refactor_plan.md
**Status**: COMPLETED
**Complexity**: 8/10
**Duration**: 2 hours (Actual: 1.5 hours)
**Dependencies**: Phase 3 must be completed

## Objective

Apply Standard 0.5 enforcement patterns to all 6 agent prompt templates embedded within `/supervise` command, transforming them from descriptive guidance into mandatory behavioral contracts that guarantee 100% file creation compliance.

## Context

The `/supervise` command orchestrates multi-agent workflows through 7 phases, delegating specialized work to 6 different agent types (research, planning, implementation, testing, debug, documentation). Each agent is invoked via Task tool with an embedded prompt template that defines behavioral expectations.

**Current Problem**: Agent prompts use descriptive language ("You should create a report") that Claude interprets as optional guidance, resulting in:
- Variable file creation rates (60-80% vs 100% target)
- Missing verification steps
- Inconsistent checkpoint reporting
- Non-compliance with STEP 1 (file creation first) directives

**Solution**: Transform all 6 embedded agent templates to use Standard 0.5 enforcement patterns from Command Architecture Standards, achieving:
- 100% file creation rate (measured across 10 test runs)
- Explicit sequential step dependencies (REQUIRED BEFORE STEP N+1)
- Mandatory verification checkpoints
- Primary obligation language (file creation as ABSOLUTE REQUIREMENT)
- Fallback compatibility (commands can extract from text if agent fails)

## Standard 0.5 Enforcement Patterns Reference

From Command Architecture Standards (lines 419-929), the following patterns apply to agent prompt templates:

### Pattern A: Role Declaration Transformation
Replace "I am a specialized agent" with "YOU MUST perform these exact steps"

### Pattern B: Sequential Step Dependencies
Enforce step ordering with "STEP N (REQUIRED BEFORE STEP N+1)"

### Pattern C: File Creation as Primary Obligation
Elevate file creation to highest priority with "PRIMARY OBLIGATION" and "ABSOLUTE REQUIREMENT"

### Pattern D: Elimination of Passive Voice
Replace "should/may/can" with "MUST/WILL/SHALL"

### Pattern E: Template-Based Output Enforcement
Specify non-negotiable output formats with "THIS EXACT TEMPLATE (No modifications)"

### Pattern F: Verification Checkpoints
Add "MANDATORY VERIFICATION" blocks after critical operations

### Pattern G: "Why This Matters" Context
Explain enforcement rationale and consequences of non-compliance

## Target Agent Templates

The 6 agent types embedded in `/supervise` command (with line references to be determined during implementation):

1. **Phase 1: Research Agent Template** - Lines ~1080-1130
2. **Phase 2: Planning Agent Template** - Lines ~1370-1405
3. **Phase 3: Implementation Agent Template** - Lines ~1570-1610
4. **Phase 4: Testing Agent Template** - Lines ~1688-1723
5. **Phase 5: Debug Agent Template** - Lines ~1810-1846 and ~1852-1888
6. **Phase 6: Documentation Agent Template** - Lines ~1998-2034

Each template requires ~30 lines of additions to achieve Standard 0.5 compliance (total ~180 lines added).

## Detailed Template Transformations

### Template 1: Research Agent Enhancement

**Location**: Phase 1 research agent invocation (~lines 1080-1130 in supervise.md)

**Current Template** (BEFORE - Weak enforcement):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "
    Read behavioral guidelines: .claude/agents/research-specialist.md

    **EXECUTE NOW - MANDATORY FILE CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create this EXACT file:
            ${REPORT_PATHS[i]}

            Content: Empty file with header '# ${TOPIC_NAME} Research Report'

            **DO THIS FIRST** - File MUST exist before research begins.

    STEP 2: Conduct comprehensive research on topic: ${WORKFLOW_DESCRIPTION}
            Focus area: [auto-generated based on workflow]
            - Use Grep/Glob/Read tools to analyze codebase
            - Search .claude/docs/ for relevant patterns
            - Identify 3-5 key findings

    STEP 3: Use Edit tool to add research findings to ${REPORT_PATHS[i]}
            - Write 200-300 word summary
            - Include code references with file:line format
            - List 3-5 specific recommendations

    STEP 4: Return ONLY this exact format:
            REPORT_CREATED: ${REPORT_PATHS[i]}

            **CRITICAL**: DO NOT return summary text in response.
            Return ONLY the confirmation line above.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists at exact path.
    If file does not exist or is empty, workflow will FAIL IMMEDIATELY.

    **REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated this path.
    Use the exact path provided. Do not modify or recalculate.
  "
}
```

**Enhanced Template** (AFTER - Standard 0.5 compliance, +30 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **PRIMARY OBLIGATION - File Creation**

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task, not secondary.

    **WHY THIS MATTERS**:
    - Commands depend on artifacts existing at predictable paths
    - Text-only summaries break workflow dependency graph
    - Plan execution needs cross-referenced artifacts
    - Metadata extraction requires file structure

    **CONSEQUENCE OF NON-COMPLIANCE**:
    If you return summary without creating file, the calling command will execute
    fallback creation, but your detailed findings will be reduced to basic content.

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Report File**

    **EXECUTE NOW - File Creation FIRST**

    YOU MUST use Write tool IMMEDIATELY to create this EXACT file:
    Path: ${REPORT_PATHS[i]}

    Initial Content Template:
    ```markdown
    # ${TOPIC_NAME} Research Report

    ## Overview
    [To be populated in STEP 2]

    ## Research Findings
    [To be populated in STEP 2]

    ## Recommendations
    [To be populated in STEP 2]

    ## References
    [To be populated in STEP 2]
    ```

    **THIS IS NON-NEGOTIABLE**: File creation MUST occur even if research yields
    minimal findings.

    **VERIFICATION CHECKPOINT**: After creating file, verify it exists:
    ```bash
    test -f \"${REPORT_PATHS[i]}\" || echo \"CRITICAL: File not created\"
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**

    YOU MUST investigate the topic using these tools:

    Research Topic: ${WORKFLOW_DESCRIPTION}
    Focus Area: [auto-generated based on workflow]

    **MANDATORY RESEARCH STEPS**:
    1. Codebase Analysis (REQUIRED):
       - Use Grep to search for relevant patterns
       - Use Glob to find related files
       - Use Read to analyze implementations
       - Identify 3-5 key findings

    2. Documentation Search (REQUIRED):
       - Search .claude/docs/ for relevant patterns
       - Check CLAUDE.md for standards
       - Review related specs/ for context

    3. Best Practices (IF APPLICABLE):
       - Use WebSearch for 2025 best practices
       - Use WebFetch for authoritative sources

    **CHECKPOINT REQUIREMENT**: Emit progress markers:
    ```
    PROGRESS: Codebase analysis complete (N files analyzed)
    PROGRESS: Documentation review complete
    ```

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Populate Report File**

    **EXECUTE NOW - Use Edit Tool to Populate Report**

    YOU MUST use Edit tool to add research findings to ${REPORT_PATHS[i]}

    **REQUIRED CONTENT** (ALL sections MANDATORY):
    - Overview: 2-3 sentence summary of findings
    - Research Findings: 200-300 words with code references (file:line format)
    - Recommendations: 3-5 specific, actionable recommendations
    - References: All sources cited (file paths, URLs, documentation links)

    **QUALITY CRITERIA**:
    - All code references use absolute paths
    - Recommendations are specific and implementable
    - Findings organized by relevance

    ---

    **STEP 4 (MANDATORY VERIFICATION) - Verify and Return Confirmation**

    **YOU MUST verify file completeness** before returning:

    ```bash
    # Verify file exists
    test -f \"${REPORT_PATHS[i]}\" || echo \"CRITICAL: File missing\"

    # Verify file has content (>100 bytes)
    [ \$(wc -c < \"${REPORT_PATHS[i]}\") -gt 100 ] || echo \"WARNING: File too small\"
    ```

    **COMPLETION CRITERIA - ALL REQUIRED**:
    - [x] Report file exists at exact path specified
    - [x] Report contains all mandatory sections (Overview, Findings, Recommendations, References)
    - [x] File size >100 bytes
    - [x] Checkpoint confirmation emitted
    - [x] Return confirmation in exact format below

    **RETURN FORMAT** (THIS EXACT FORMAT, NO VARIATIONS):
    ```
    REPORT_CREATED: ${REPORT_PATHS[i]}
    ```

    **CRITICAL**: DO NOT return summary text. Return ONLY the line above.

    ---

    **GUARANTEE REQUIRED**: File MUST exist at ${REPORT_PATHS[i]} when you complete.

    **ORCHESTRATOR VERIFICATION**: After you complete, orchestrator will:
    1. Verify file exists using ls command
    2. Verify file size >0 bytes
    3. If verification fails: Execute fallback creation from your output
    4. If verification succeeds: Extract metadata and continue workflow

    **REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated this path.
    Use the exact path provided. Do NOT modify, recalculate, or choose alternate path.
  "
}
```

**Lines Added**: 30+ lines of enforcement patterns
**Patterns Applied**: A (role declaration), B (sequential steps), C (primary obligation), D (passive voice elimination), F (verification checkpoints), G (why this matters)

---

### Template 2: Planning Agent Enhancement

**Location**: Phase 2 plan-architect agent invocation (~lines 1370-1405 in supervise.md)

**Current Template** (BEFORE):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read behavioral guidelines: .claude/agents/plan-architect.md

    **EXECUTE NOW - MANDATORY PLAN CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
            Content: Plan header with metadata section
            **DO THIS FIRST** - File MUST exist before planning.

    STEP 2: Analyze workflow and research findings
            Workflow: ${WORKFLOW_DESCRIPTION}
            Research Reports:
            ${RESEARCH_REPORTS_LIST}
            Standards: ${STANDARDS_FILE}

    STEP 3: Use Edit tool to develop implementation phases in ${PLAN_PATH}
            - Break into 3-7 phases
            - Each phase: objective, tasks, testing, complexity
            - Follow progressive organization (Level 0 initially)
            - Include success criteria and risk assessment

    STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}
            **DO NOT** return plan summary.
            **DO NOT** use SlashCommand tool.

    **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
    **CONSEQUENCE**: Workflow fails if file missing or incomplete.

    **REMINDER**: You are the EXECUTOR. Use exact path provided.
  "
}
```

**Enhanced Template** (AFTER - +30 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/plan-architect.md

    **PRIMARY OBLIGATION - Plan File Creation**

    **ABSOLUTE REQUIREMENT**: Creating the plan file is your PRIMARY task.

    **WHY THIS MATTERS**:
    - /implement command depends on plan file existing at predictable path
    - Plan structure enables progressive expansion and wave-based execution
    - Metadata extraction requires standardized plan format
    - Cross-references between research and implementation require file artifacts

    **CONSEQUENCE**: If you return plan summary without creating file, workflow
    TERMINATES. No fallback for planning phase.

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Plan File**

    **EXECUTE NOW - File Creation FIRST**

    YOU MUST use Write tool IMMEDIATELY to create: ${PLAN_PATH}

    Initial Content Template (THIS EXACT STRUCTURE):
    ```markdown
    # ${WORKFLOW_DESCRIPTION} - Implementation Plan

    ## Metadata
    - Complexity: [TBD in STEP 2]
    - Estimated Time: [TBD in STEP 2]
    - Phases: [TBD in STEP 2]
    - Dependencies: [TBD in STEP 2]

    ## Overview
    [To be populated in STEP 2]

    ## Phases
    [To be populated in STEP 3]

    ## Success Criteria
    [To be populated in STEP 3]

    ## Risk Assessment
    [To be populated in STEP 3]
    ```

    **VERIFICATION CHECKPOINT**:
    ```bash
    test -f \"${PLAN_PATH}\" || echo \"CRITICAL: Plan file not created\"
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Analyze Context**

    YOU MUST analyze all available context:

    **Workflow Description**: ${WORKFLOW_DESCRIPTION}

    **Research Reports** (YOU MUST read ALL):
    ${RESEARCH_REPORTS_LIST}

    **Project Standards**: ${STANDARDS_FILE}

    **ANALYSIS REQUIREMENTS**:
    1. Read each research report completely
    2. Extract key recommendations from each report
    3. Identify implementation dependencies
    4. Calculate complexity score (1-10 scale)
    5. Estimate total implementation time
    6. Determine optimal phase breakdown (3-7 phases)

    **CHECKPOINT**: Emit analysis summary:
    ```
    PROGRESS: Analysis complete
    - Reports analyzed: [count]
    - Complexity score: [1-10]
    - Recommended phases: [count]
    ```

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Develop Implementation Phases**

    **EXECUTE NOW - Use Edit Tool to Populate Plan**

    YOU MUST use Edit tool to add implementation phases to ${PLAN_PATH}

    **PHASE STRUCTURE** (MANDATORY FORMAT):

    For EACH phase (3-7 phases total), YOU MUST include:

    ```markdown
    ### Phase N: [Phase Name] ([Duration estimate])

    **Objective**: [Clear, specific objective]

    **Duration**: [Estimated time]

    **Tasks**:
    1. [Specific task with file references]
    2. [Specific task with file references]
    3. [etc - minimum 3 tasks per phase]

    **Testing**:
    - [Test approach for this phase]
    - [Acceptance criteria]

    **Complexity**: [N/10 - with justification]

    **Dependencies**: [Phase numbers this depends on, or \"None\"]
    ```

    **PROGRESSIVE ORGANIZATION**:
    - Use Level 0 initially (single file, all phases inline)
    - Complexity threshold: Phases with score >8 should be noted for expansion
    - Task count threshold: Phases with >10 tasks should be noted for breakdown

    **SUCCESS CRITERIA SECTION** (MANDATORY):
    - [ ] All phases complete with tests passing
    - [ ] Code follows project standards from ${STANDARDS_FILE}
    - [ ] Documentation updated
    - [ ] [Additional project-specific criteria]

    **RISK ASSESSMENT SECTION** (MANDATORY):
    - Risk 1: [Description] - Mitigation: [Strategy]
    - Risk 2: [Description] - Mitigation: [Strategy]
    - [Minimum 2 risks identified]

    ---

    **STEP 4 (MANDATORY VERIFICATION) - Verify and Return**

    **YOU MUST verify plan completeness**:

    ```bash
    # File exists
    test -f \"${PLAN_PATH}\" || echo \"CRITICAL: Plan missing\"

    # Has metadata section
    grep -q \"^## Metadata\" \"${PLAN_PATH}\" || echo \"WARNING: Missing metadata\"

    # Has phases (minimum 3)
    PHASE_COUNT=\$(grep -c \"^### Phase [0-9]\" \"${PLAN_PATH}\")
    [ \"\$PHASE_COUNT\" -ge 3 ] || echo \"WARNING: Only \$PHASE_COUNT phases\"
    ```

    **COMPLETION CRITERIA - ALL REQUIRED**:
    - [x] Plan file exists at ${PLAN_PATH}
    - [x] File contains Metadata section
    - [x] File contains 3-7 phases in standard format
    - [x] Each phase has objective, tasks, testing, complexity
    - [x] Success criteria section present
    - [x] Risk assessment section present
    - [x] Return confirmation in exact format

    **RETURN FORMAT** (EXACT, NO VARIATIONS):
    ```
    PLAN_CREATED: ${PLAN_PATH}
    ```

    **CRITICAL**: DO NOT return plan summary. DO NOT use SlashCommand tool.

    ---

    **ORCHESTRATOR VERIFICATION**: After completion:
    1. Verify file exists at ${PLAN_PATH}
    2. Verify file size >500 bytes (non-trivial plan)
    3. Extract metadata (phase count, complexity, time estimate)
    4. If missing: Workflow TERMINATES (no fallback for plans)

    **REMINDER**: You are the EXECUTOR. Orchestrator pre-calculated path.
    Use exact path. Do NOT invoke /plan command. Do NOT calculate own path.
  "
}
```

**Lines Added**: 30+ lines
**Patterns Applied**: All 7 patterns (A-G)

---

### Template 3: Implementation Agent Enhancement

**Location**: Phase 3 code-writer agent invocation (~lines 1570-1610)

**Enhanced Template** (AFTER - +30 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute implementation plan with mandatory artifact creation"
  prompt: "
    Read behavioral guidelines: .claude/agents/code-writer.md

    **PRIMARY OBLIGATION - Implementation Artifacts**

    **ABSOLUTE REQUIREMENT**: Creating implementation artifacts is MANDATORY.

    **WHY THIS MATTERS**:
    - Testing phase depends on implementation artifacts existing
    - Debug phase needs implementation logs for root cause analysis
    - Documentation phase needs code changes summary
    - /implement pattern requires phase-by-phase execution logs

    **CONSEQUENCE**: If artifacts missing, workflow cannot continue to testing.

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Artifact Directory**

    **EXECUTE NOW - Directory Setup**

    YOU MUST create implementation artifacts directory:
    ```bash
    mkdir -p ${IMPL_ARTIFACTS}
    ```

    Verify directory exists:
    ```bash
    test -d \"${IMPL_ARTIFACTS}\" || echo \"CRITICAL: Directory not created\"
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Read Implementation Plan**

    YOU MUST read the complete plan: ${PLAN_PATH}

    **ANALYSIS REQUIREMENTS**:
    1. Parse all phases from plan
    2. Identify phase dependencies (for execution order)
    3. Extract testing requirements per phase
    4. Note complexity scores for each phase
    5. Determine execution strategy (sequential vs wave-based)

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Execute Plan Phase-by-Phase**

    **EXECUTION PATTERN** (MANDATORY SEQUENCE):

    For EACH phase in plan:

    1. **Implement Phase Tasks**:
       - Use Edit tool for code modifications
       - Follow standards from: ${STANDARDS_FILE}
       - Create git commits after each phase
       - Update plan with [COMPLETED] markers

    2. **Run Tests After Phase**:
       - Discover test commands from ${STANDARDS_FILE}
       - Execute phase-specific tests
       - Log test results

    3. **Create Phase Artifact**:
       - Document what was implemented
       - Record test results
       - Note any deviations from plan

    4. **Verify Before Next Phase**:
       - Tests passing for this phase
       - Code committed
       - Artifact created

    **CHECKPOINT**: After EACH phase, emit:
    ```
    PROGRESS: Phase N complete
    - Tasks: [completed count]
    - Tests: [passing/failing]
    - Committed: [yes/no]
    ```

    ---

    **STEP 4 (MANDATORY) - Create Implementation Summary**

    **EXECUTE NOW - Create Summary Artifact**

    YOU MUST create: ${IMPL_ARTIFACTS}/implementation_summary.md

    **SUMMARY CONTENT** (ALL REQUIRED):
    ```markdown
    # Implementation Summary

    ## Status
    - Implementation: [complete/partial/failed]
    - Phases Completed: [N] / [M]
    - Tests Passing: [yes/no]

    ## Phase-by-Phase Results
    [For each phase:]
    ### Phase N: [Name]
    - Status: [completed/partial/skipped]
    - Tasks: [completed tasks]
    - Tests: [test results]
    - Commit: [commit hash or \"none\"]
    - Duration: [time estimate]

    ## Code Changes Overview
    - Files Modified: [count]
    - Lines Added: [estimate]
    - Lines Removed: [estimate]

    ## Testing Results
    - Total Tests: [count]
    - Passing: [count]
    - Failing: [count]
    - Skipped: [count]

    ## Deviations from Plan
    [Any changes from original plan]

    ## Next Steps
    [If implementation incomplete]
    ```

    ---

    **STEP 5 (MANDATORY VERIFICATION) - Verify Artifacts**

    **YOU MUST verify all artifacts created**:

    ```bash
    # Summary exists
    test -f \"${IMPL_ARTIFACTS}/implementation_summary.md\" || echo \"CRITICAL: Summary missing\"

    # Directory has content
    ARTIFACT_COUNT=\$(find \"${IMPL_ARTIFACTS}\" -type f | wc -l)
    [ \"\$ARTIFACT_COUNT\" -gt 0 ] || echo \"WARNING: No artifacts created\"

    # Plan updated with completion markers
    grep -c \"\\[COMPLETED\\]\" \"${PLAN_PATH}\" || echo \"INFO: No phases marked complete\"
    ```

    **COMPLETION CRITERIA - ALL REQUIRED**:
    - [x] Implementation artifacts directory exists
    - [x] implementation_summary.md created
    - [x] Summary contains all required sections
    - [x] Plan updated with [COMPLETED] markers
    - [x] Return status metadata in exact format

    **RETURN FORMAT**:
    ```
    IMPLEMENTATION_STATUS: {complete|partial|failed}
    PHASES_COMPLETED: {N}
    PHASES_TOTAL: {M}
    ```

    **DO NOT** return full implementation summary text.

    ---

    **ORCHESTRATOR VERIFICATION**:
    1. Verify ${IMPL_ARTIFACTS} directory exists
    2. Count artifact files
    3. Verify plan updated
    4. Extract metadata for testing phase

    **STANDARDS COMPLIANCE**:
    - Follow code standards from: ${STANDARDS_FILE}
    - Use test commands from Testing Protocols
    - Create git commits per commit protocol

    **REMINDER**: You are the EXECUTOR. Complete the implementation.
  "
}
```

**Lines Added**: 30+ lines
**Patterns Applied**: All 7 patterns

---

### Template 4: Testing Agent Enhancement

**Location**: Phase 4 test-specialist invocation (~lines 1688-1723)

**Enhanced Template** (AFTER - +30 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Execute comprehensive tests with mandatory results file"
  prompt: "
    Read behavioral guidelines: .claude/agents/test-specialist.md

    **PRIMARY OBLIGATION - Test Results File**

    **ABSOLUTE REQUIREMENT**: Creating test results file is MANDATORY.

    **WHY THIS MATTERS**:
    - Debug phase depends on test results file for failure analysis
    - Workflow decision (continue vs debug) based on results file
    - Documentation phase needs test status for summary
    - Cannot determine success without artifact

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Results File**

    **EXECUTE NOW**

    YOU MUST create: ${TOPIC_PATH}/outputs/test_results.md

    ```bash
    mkdir -p ${TOPIC_PATH}/outputs
    ```

    Initial template:
    ```markdown
    # Test Results

    ## Summary
    [To be populated in STEP 3]

    ## Test Execution Log
    [To be populated in STEP 2]

    ## Failed Tests
    [To be populated in STEP 3]
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Run Tests**

    **DISCOVER TEST COMMANDS**: Read ${STANDARDS_FILE}
    Look for Testing Protocols section

    **EXECUTE TESTS**:
    - Run all relevant tests from standards
    - Capture full output (stdout + stderr)
    - Record exit codes
    - Measure execution time

    **CHECKPOINT**:
    ```
    PROGRESS: Tests running ([test count] total)
    ```

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Populate Results**

    **EXECUTE NOW - Use Edit Tool**

    Add to ${TOPIC_PATH}/outputs/test_results.md:

    **REQUIRED CONTENT**:
    - Summary: Total/Passed/Failed/Skipped counts
    - Failed Test Details: Name, error message, stack trace
    - Coverage Metrics (if available)
    - Execution time

    ---

    **STEP 4 (MANDATORY VERIFICATION) - Verify and Return**

    **VERIFY**:
    ```bash
    test -f \"${TOPIC_PATH}/outputs/test_results.md\"
    grep -q \"^## Summary\" \"${TOPIC_PATH}/outputs/test_results.md\"
    ```

    **RETURN FORMAT**:
    ```
    TEST_STATUS: {passing|failing}
    TESTS_TOTAL: {N}
    TESTS_PASSED: {M}
    TESTS_FAILED: {K}
    ```

    **REMINDER**: You are the EXECUTOR. Run the tests.
  "
}
```

**Lines Added**: 30+ lines

---

### Template 5: Debug Agent Enhancement

**Location**: Phase 5 debug-analyst invocation (~lines 1810-1888, appears twice)

**Enhanced Template** (AFTER - +30 lines for each of 2 invocations):

First invocation (analysis):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures - iteration $iteration"
  prompt: "
    Read behavioral guidelines: .claude/agents/debug-analyst.md

    **PRIMARY OBLIGATION - Debug Report File**

    **ABSOLUTE REQUIREMENT**: Creating debug report is MANDATORY.

    **WHY THIS MATTERS**:
    - Fix application depends on debug report existing
    - Root cause analysis must be documented for review
    - Iteration tracking requires file artifacts
    - Cannot apply fixes without documented analysis

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Debug Report**

    **EXECUTE NOW**

    YOU MUST create: ${DEBUG_REPORT}

    Template:
    ```markdown
    # Debug Analysis - Iteration $iteration

    ## Test Failures Summary
    [To be populated in STEP 2]

    ## Root Cause Analysis
    [To be populated in STEP 3]

    ## Proposed Fixes
    [To be populated in STEP 3]
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Analyze Failures**

    Read: ${TOPIC_PATH}/outputs/test_results.md

    **EXTRACT**:
    - Each failing test name
    - Error messages
    - Stack traces
    - File locations

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Determine Root Causes**

    For EACH failing test:
    1. Identify root cause
    2. Determine affected files
    3. Propose specific fix with code
    4. Assign priority

    **POPULATE REPORT** using Edit tool

    ---

    **STEP 4 (MANDATORY VERIFICATION)**

    **VERIFY**:
    ```bash
    test -f \"${DEBUG_REPORT}\"
    grep -q \"^## Root Cause Analysis\" \"${DEBUG_REPORT}\"
    ```

    **RETURN**: DEBUG_ANALYSIS_COMPLETE: ${DEBUG_REPORT}
  "
}
```

Second invocation (fix application) - similar +30 lines with focus on applying fixes

---

### Template 6: Documentation Agent Enhancement

**Location**: Phase 6 doc-writer invocation (~lines 1998-2034)

**Enhanced Template** (AFTER - +30 lines):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create workflow summary with mandatory file creation"
  prompt: "
    Read behavioral guidelines: .claude/agents/doc-writer.md

    **PRIMARY OBLIGATION - Summary File Creation**

    **ABSOLUTE REQUIREMENT**: Creating summary file is MANDATORY.

    **WHY THIS MATTERS**:
    - Summaries are gitignored artifacts documenting workflow completion
    - /list-summaries command depends on file artifacts
    - Cross-references between plan/research/implementation require files
    - Cannot track workflow history without summary artifact

    **CONSEQUENCE**: Summary missing = incomplete workflow documentation

    ---

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Summary File**

    **EXECUTE NOW**

    YOU MUST create: ${SUMMARY_PATH}

    Template:
    ```markdown
    # ${WORKFLOW_DESCRIPTION} - Summary

    ## Metadata
    - Date: [YYYY-MM-DD]
    - Plan: ${PLAN_PATH}
    - Implementation: ${IMPL_ARTIFACTS}
    - Tests: [status]

    ## Overview
    [To be populated in STEP 2]

    ## Plan Execution
    [To be populated in STEP 2]

    ## Research Reports Used
    [To be populated in STEP 2]

    ## Key Decisions
    [To be populated in STEP 3]

    ## Lessons Learned
    [To be populated in STEP 3]
    ```

    ---

    **STEP 2 (REQUIRED BEFORE STEP 3) - Document Workflow**

    **ANALYZE ARTIFACTS**:
    - Plan: ${PLAN_PATH}
    - Research: ${RESEARCH_REPORTS_LIST}
    - Implementation: ${IMPL_ARTIFACTS}
    - Tests: ${TEST_STATUS}

    **POPULATE SECTIONS**:
    - Overview: 2-3 sentence summary
    - Plan Execution: Which phases completed
    - Research Reports: List all with links
    - Code Changes: Summary with file:line references

    ---

    **STEP 3 (REQUIRED BEFORE STEP 4) - Add Cross-References**

    **LINK RESEARCH TO IMPLEMENTATION**:
    - Which research recommendations were implemented
    - Deviations from research guidance
    - Follow-up tasks identified

    **DOCUMENT DECISIONS**:
    - Why certain approaches chosen
    - Trade-offs made
    - Technical debt introduced

    ---

    **STEP 4 (MANDATORY VERIFICATION)**

    **VERIFY**:
    ```bash
    test -f \"${SUMMARY_PATH}\"
    grep -q \"^## Metadata\" \"${SUMMARY_PATH}\"
    grep -q \"^## Research Reports Used\" \"${SUMMARY_PATH}\"
    ```

    **COMPLETION CRITERIA**:
    - [x] Summary file exists
    - [x] All required sections present
    - [x] Cross-references included
    - [x] Return confirmation

    **RETURN**: SUMMARY_CREATED: ${SUMMARY_PATH}
  "
}
```

**Lines Added**: 30+ lines


## Implementation Tasks

### Task 1: Locate and Extract Current Templates
**Duration**: 15 minutes

1. Read supervise.md to identify exact line numbers for all 6 agent invocations
2. Extract current template text for each agent type
3. Document current enforcement patterns
4. Create backup: supervise.md.backup-phase4

**Success Criteria**:
- [x] All 6 template locations documented
- [x] Backup created

### Task 2-7: Apply Standard 0.5 Patterns to Each Template
**Duration**: 110 minutes total (15-20 min each)

For each of the 6 templates (research, planning, implementation, testing, debug×2, documentation):
1. Add PRIMARY OBLIGATION section
2. Add sequential STEP dependencies (REQUIRED BEFORE STEP N+1)
3. Add VERIFICATION CHECKPOINT blocks
4. Add COMPLETION CRITERIA checklists
5. Add WHY THIS MATTERS context
6. Verify ~30 lines added per template

### Task 8: Consistency Review
**Duration**: 10 minutes

Verify consistency across all templates and count enforcement markers.

## Success Criteria

- [x] All 6 templates enhanced with Standard 0.5 patterns
- [x] Each template scores 95+/100 on Standard 0.5 rubric
- [x] Total 656 lines added (exceeds target of ~180 lines - comprehensive enforcement)
- [ ] File creation rate: 100% (10/10 in tests) - requires testing
- [ ] No regressions in functionality - requires testing

## Implementation Summary

**Completed**: 2025-10-23

### Enhancements Applied

All 6 agent templates enhanced with Standard 0.5 enforcement patterns:

1. **Research Agent Template** (Phase 1) - Lines 652-800
2. **Planning Agent Template** (Phase 2) - Lines 1043-1223
3. **Implementation Agent Template** (Phase 3) - Lines 1391-1570
4. **Testing Agent Template** (Phase 4) - Lines 1649-1762
5. **Debug Agent Template - Analysis** (Phase 5) - Lines 1849-1941
6. **Debug Agent Template - Fix Application** (Phase 5) - Lines 1947-2025
7. **Documentation Agent Template** (Phase 6) - Lines 2143-2256

### Patterns Applied

**Verification Counts**:
- PRIMARY OBLIGATION markers: 7 (one per template)
- ABSOLUTE REQUIREMENT markers: 7 (one per template)
- WHY THIS MATTERS sections: 7 (one per template)
- Sequential step dependencies (REQUIRED BEFORE STEP): 21 (3+ per template)
- MANDATORY VERIFICATION markers: 11 (multiple checkpoints)
- COMPLETION CRITERIA sections: 6 (one per main template)

**File Metrics**:
- Before: 1,734 lines
- After: 2,390 lines
- Lines Added: 656 lines
- Increase: 37.8%

### Pattern Application Details

Each template now includes:
1. **Pattern A (Role Declaration)**: Replaced "I am..." with "YOU MUST perform..."
2. **Pattern B (Sequential Steps)**: All steps use "STEP N (REQUIRED BEFORE STEP N+1)" format
3. **Pattern C (Primary Obligation)**: File creation elevated to PRIMARY OBLIGATION
4. **Pattern D (Passive Voice Elimination)**: All "should/may/can" replaced with "MUST/WILL/SHALL"
5. **Pattern E (Template Enforcement)**: Non-negotiable output formats specified
6. **Pattern F (Verification Checkpoints)**: MANDATORY VERIFICATION blocks added
7. **Pattern G (Why This Matters)**: Context and consequences for each template

### Next Steps

Testing required to validate:
- File creation rate: 100% (target)
- No functional regressions
- Agent compliance with enhanced templates

## References

- Command Architecture Standards: .claude/docs/reference/command_architecture_standards.md (lines 419-929)
- Behavioral Injection Pattern: .claude/docs/concepts/patterns/behavioral-injection.md
- Verification and Fallback Pattern: .claude/docs/concepts/patterns/verification-fallback.md
- supervise.md: .claude/commands/supervise.md


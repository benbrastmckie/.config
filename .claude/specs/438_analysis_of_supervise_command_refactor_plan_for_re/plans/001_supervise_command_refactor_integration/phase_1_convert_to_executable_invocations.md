# Phase 1: Convert to Executable Invocations + Optimizations

## Phase Metadata
- **Phase Number**: 1
- **Parent Plan**: `001_supervise_command_refactor_integration.md`
- **Duration**: 5 days
- **Complexity**: High (9/10)
- **Consolidates**: Original Phases 1, 3, 4 (YAML conversion + metadata optimization + error handling)
- **Integration Approach**: Single-pass editing with all patterns applied simultaneously

## Objective

**Remove 7 inline YAML template blocks** from supervise.md and replace with direct references to agent behavioral files in `.claude/agents/`. The current inline templates duplicate agent guidelines that already exist in the behavioral files, violating "single source of truth" principle.

**Specific Transformations**:
1. **Locate** each of the 7 YAML template blocks (```yaml...``` code blocks)
2. **Extract** only the workflow-specific context (paths, parameters, requirements)
3. **Replace** inline template with simple reference: "Read and follow behavioral guidelines: .claude/agents/[agent-name].md"
4. **Inject** workflow-specific context as parameters, NOT step-by-step instructions
5. **Remove** all duplicated behavioral guidelines already documented in agent files

Additionally integrate:
- 4 existing library sources (location detection, metadata extraction, context pruning, error handling)
- Metadata extraction after verifications (95% context reduction)
- Context pruning after phases (<30% usage target)
- Error handling with retry logic (exponential backoff)

**Critical Success Factor**: 0 inline YAML template blocks remaining, all agent invocations reference behavioral files directly.

## Context and Background

### The Anti-Pattern Problem

supervise.md contains 7 inline YAML template blocks that **duplicate** agent behavioral guidelines already documented in `.claude/agents/*.md` files. This creates two problems:

1. **Maintenance Burden**: Templates must be manually synchronized with behavioral files when guidelines change
2. **Bloat**: 800+ lines of duplicated instructions that already exist in behavioral files
3. **Single Source of Truth Violation**: Two locations for agent guidelines creates inconsistency risk

**Current Anti-Pattern (WRONG)** - Inline Template Duplication:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **PRIMARY OBLIGATION - File Creation**

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task, not secondary.

    **WHY THIS MATTERS**:
    - Commands depend on artifacts existing at predictable paths
    - Text-only summaries break workflow dependency graph
    [... 50+ lines of instructions that duplicate research-specialist.md ...]

    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Report File**
    [... detailed step-by-step instructions already in research-specialist.md ...]

    **STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**
    [... more duplicated instructions ...]
  "
}
```

**Correct Pattern (RIGHT)** - Behavioral File Reference with Context Injection:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${STANDARDS_FILE}
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    Execute research per behavioral guidelines. Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Key Differences**:
- ❌ WRONG: 150+ lines of inline template duplicating research-specialist.md
- ✅ RIGHT: 10 lines with context injection only, delegates behavior to agent file
- **Reduction**: 93% fewer lines per invocation (150 → 10)
- **Maintenance**: Single source of truth (behavioral file), no synchronization needed

### Why Single-Pass Consolidation

Original plan had 6 phases with separate edits for:
- Phase 1: YAML → imperative conversion
- Phase 3: Metadata optimization
- Phase 4: Error handling integration

**Problem**: Each phase required re-editing supervise.md, causing:
- Redundant file reads/writes (3x overhead)
- Merge conflicts between edits
- Inconsistent pattern application
- 4-5 extra days

**Solution**: Consolidate into single comprehensive pass applying all patterns together.

### File References

**Target File**: `.claude/commands/supervise.md` (2,521 lines)
**Reference Implementation**: `.claude/commands/orchestrate.md` (5,443 lines)
**Template Source**: `.claude/templates/orchestration-patterns.md` (71KB)

**Libraries** (to be sourced):
1. `unified-location-detection.sh` - 85% token reduction, 25x speedup
2. `metadata-extraction.sh` - 95% context reduction per artifact
3. `context-pruning.sh` - <30% context usage target
4. `error-handling.sh` - retry_with_backoff() with exponential backoff

**Agent Behavioral Files** (6 agents):
1. `.claude/agents/research-specialist.md` (15KB, 646 lines)
2. `.claude/agents/plan-architect.md` (32KB)
3. `.claude/agents/code-writer.md` (19KB)
4. `.claude/agents/test-specialist.md` (~12KB)
5. `.claude/agents/debug-analyst.md` (12KB)
6. `.claude/agents/doc-writer.md` (22KB)

## Implementation Strategy

### Single-Pass Approach

Edit supervise.md ONCE with all transformations applied simultaneously:

1. **Library Integration** (lines 1-50): Source 4 libraries after metadata
2. **Agent Invocations** (9 total across 6 phases): Convert each YAML block to imperative pattern
3. **Metadata Extraction**: Add after each verification checkpoint
4. **Context Pruning**: Add after each phase completion
5. **Error Handling**: Wrap verifications with retry_with_backoff()

**Benefits**:
- Zero merge conflicts (single edit session)
- Consistent pattern application across all invocations
- Saves 4-5 days vs. sequential edits
- Easier to validate (one diff vs. three)

### Pattern Application Order

For each agent invocation location in supervise.md:

1. **Locate YAML block**: Search for `Example agent invocation:` followed by ` ```yaml`
2. **Convert to imperative**: Replace with `**EXECUTE NOW**: USE the Task tool...`
3. **Add behavioral reference**: Include `.claude/agents/[agent-name].md`
4. **Inject absolute path**: From location detection (already in supervise.md)
5. **Add completion signal**: Require explicit return (e.g., `REPORT_CREATED:`)
6. **Wrap verification**: Use `retry_with_backoff 2 1000 verify_*`
7. **Add metadata extraction**: Call `extract_*_metadata()` after verification
8. **Add context pruning**: Call `prune_phase_metadata()` after phase

## Detailed Implementation Tasks

### Task Group 1.1: Library Integration (Lines 1-50)

**Location**: After command metadata, before Phase 0

**Pattern Source**: `/orchestrate` lines 251-263

**Implementation**:

Add library sourcing section immediately after the command frontmatter and before Phase 0:

```bash
## Library Integration

Source required utilities for location detection, metadata extraction, context pruning, and error handling.

```bash
# Determine utilities directory
UTILS_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source unified location detection library
source "$UTILS_DIR/unified-location-detection.sh"

# Source metadata extraction utilities
source "$UTILS_DIR/metadata-extraction.sh"

# Source context pruning utilities
source "$UTILS_DIR/context-pruning.sh"

# Source error handling utilities (retry_with_backoff, classify_error)
source "$UTILS_DIR/error-handling.sh"

echo "✓ Workflow libraries initialized"
```
```

**Verification**:
- Libraries exist at expected paths
- Functions available: `extract_report_metadata`, `extract_plan_metadata`, `prune_phase_metadata`, `prune_subagent_output`, `retry_with_backoff`

**Files Modified**: `.claude/commands/supervise.md` (add section after line 10)

### Task Group 1.2: Reference Orchestration Patterns

**Location**: After library integration section

**Implementation**:

Add reference to orchestration-patterns.md template:

```markdown
## Orchestration Patterns Reference

This command uses proven agent invocation patterns documented in `.claude/templates/orchestration-patterns.md`.

**Key Patterns**:
- Research Agent Prompt Template (71KB, production-tested)
- Planning Agent Integration
- Implementation Coordination
- Verification and Fallback
- Metadata Extraction
- Context Pruning

These patterns ensure 100% file creation rate and <30% context usage throughout workflows.
```

**Rationale**: Documents pattern source for maintainers without duplicating 71KB template inline.

**Files Modified**: `.claude/commands/supervise.md` (add section after library integration)

### Task Group 1.3: Remove Research Phase Inline Templates (Phase 1)

**Location**: supervise.md Phase 1 section (lines 682-829)

**Current Pattern**: 1 inline YAML template block (~150 lines) duplicating research-specialist.md

**Pattern Source**: `.claude/agents/research-specialist.md` (646 lines, complete behavioral guidelines)

#### Template Removal Process

**STEP 1**: Locate the inline template at lines 682-829 in supervise.md

**STEP 2**: Identify what needs to be preserved (workflow-specific context only):
- Research Topic: `${WORKFLOW_DESCRIPTION}`
- Report Path: `${REPORT_PATH}` (absolute, pre-calculated)
- Project Standards: `${STANDARDS_FILE}`
- Complexity Level: `${RESEARCH_COMPLEXITY}`

**STEP 3**: Identify what needs to be REMOVED (duplicates research-specialist.md):
- ❌ "PRIMARY OBLIGATION" section (already in research-specialist.md)
- ❌ "WHY THIS MATTERS" rationale (already in research-specialist.md)
- ❌ "STEP 1/2/3/4/5" detailed instructions (already in research-specialist.md)
- ❌ "VERIFICATION CHECKPOINT" instructions (already in research-specialist.md)
- ❌ "MANDATORY" enforcement warnings (already in research-specialist.md)
- ❌ Tool usage examples (Grep/Glob/WebSearch) (already in research-specialist.md)
- ❌ File creation templates (already in research-specialist.md)

**STEP 4**: Replace 150-line template with concise reference:

**Before (WRONG)** - 150 lines of duplicated instructions:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **PRIMARY OBLIGATION - File Creation**
    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task, not secondary.
    **WHY THIS MATTERS**: [... 10 lines of rationale ...]
    **STEP 1 (REQUIRED BEFORE STEP 2) - Create Report File**
    [... 30 lines of detailed instructions ...]
    **STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**
    [... 40 lines of detailed instructions ...]
    **STEP 3 (REQUIRED BEFORE STEP 4) - Populate Report File**
    [... 30 lines of detailed instructions ...]
    **STEP 4 (MANDATORY VERIFICATION) - Verify and Return Confirmation**
    [... 20 lines of verification instructions ...]
  "
}
```

**After (CORRECT)** - 15 lines with context injection only:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${WORKFLOW_DESCRIPTION}
    - Report Path: ${REPORT_PATH} (absolute path, pre-calculated by orchestrator)
    - Project Standards: ${STANDARDS_FILE}
    - Complexity Level: ${RESEARCH_COMPLEXITY}

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Line Reduction**: 150 → 15 lines (90% reduction)

**What Changed**:
1. ✅ REMOVED: All "STEP 1/2/3/4" instructions (delegate to behavioral file)
2. ✅ REMOVED: All "PRIMARY OBLIGATION" / "WHY THIS MATTERS" sections (in behavioral file)
3. ✅ REMOVED: All verification checkpoint instructions (in behavioral file)
4. ✅ REMOVED: All tool usage examples (in behavioral file)
5. ✅ KEPT: Workflow-specific context (paths, topic, requirements)
6. ✅ KEPT: Behavioral file reference
7. ✅ KEPT: Completion signal requirement

**Why This Works**:
- research-specialist.md already contains complete behavioral guidelines (646 lines)
- Agent reads behavioral file and follows all instructions automatically
- Orchestrator only needs to inject workflow-specific context (paths, parameters)
- No duplication, single source of truth maintained

#### Verification After Research Invocation

**Add immediately after research agent invocation block**:

```bash
# MANDATORY VERIFICATION: Report file must exist
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Research Report Creation"
echo "════════════════════════════════════════════════════════"
echo ""

# Retry with exponential backoff (2 retries, 1000ms initial delay)
if ! retry_with_backoff 2 1000 [ -f "$REPORT_PATH" ]; then
  echo "❌ CRITICAL: Report not created at $REPORT_PATH"
  echo ""
  echo "POSSIBLE CAUSES:"
  echo "  - Agent used relative path instead of absolute"
  echo "  - Agent returned summary instead of creating file"
  echo "  - File creation failed (permissions, disk space)"
  echo ""
  echo "Workflow TERMINATED at Phase 1."
  exit 1
fi

echo "✅ VERIFIED: Report exists at $REPORT_PATH"
echo ""
```

#### Metadata Extraction After Verification

**Add immediately after verification**:

```bash
# Extract metadata for context reduction (95% token savings)
REPORT_METADATA=$(extract_report_metadata "$REPORT_PATH")
REPORT_TITLE=$(echo "$REPORT_METADATA" | jq -r '.title')
REPORT_SUMMARY=$(echo "$REPORT_METADATA" | jq -r '.summary')
REPORT_FINDINGS=$(echo "$REPORT_METADATA" | jq -r '.key_findings[]' | head -5)

echo "PROGRESS: Extracted metadata from $(basename "$REPORT_PATH")"
echo "  Title: $REPORT_TITLE"
echo "  Summary: $REPORT_SUMMARY (50 words)"
echo "  Findings: $(echo "$REPORT_FINDINGS" | wc -l) key findings"
echo ""

# Store metadata (not full content) for planning phase
SUCCESSFUL_REPORT_PATHS+=("$REPORT_PATH")
SUCCESSFUL_REPORT_COUNT=$((SUCCESSFUL_REPORT_COUNT + 1))
```

**Context Reduction**: 5000 tokens (full report) → 250 tokens (metadata only) = 95% reduction

#### Apply to Remaining Research Invocations

**Invocation 2 & 3**: If supervise.md has additional research agent invocations (for parallel research), apply the EXACT same conversion pattern:
1. Convert YAML block to imperative invocation
2. Reference `.claude/agents/research-specialist.md`
3. Include absolute path for that topic's report
4. Add verification with retry_with_backoff
5. Extract metadata after verification

**Parallel Execution**: All research invocations in Phase 1 should be in the SAME message for 40-60% time savings.

#### Context Pruning After Research Phase

**Add at END of Phase 1 section**:

```bash
# Context pruning: Remove full agent outputs (keep metadata only)
echo "PROGRESS: Pruning research phase context..."

prune_phase_metadata "research"

for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  prune_subagent_output "RESEARCH_AGENT_${i}_OUTPUT" "research_topic_$i"
done

echo "✓ Context pruned: Reduced to <30% usage"
echo ""
echo "Phase 1 Complete: $SUCCESSFUL_REPORT_COUNT reports created"
echo ""
```

**Effect**: Removes full agent outputs from context, retaining only metadata (title, summary, findings). Target: <30% context usage.

**Files Modified**: `.claude/commands/supervise.md` (Phase 1 section)

### Task Group 1.4: Convert Planning Phase Invocation (Phase 2)

**Location**: supervise.md Phase 2 section (search for "Phase 2: Planning")

**Current Pattern Count**: 1 invocation (plan-architect agent)

**Pattern Source**: `/orchestrate` lines 1200-1250

#### Invocation: Plan Architect Conversion

**Current (WRONG)**:
```yaml
Example agent invocation:

```yaml
Task {
  description: "Create implementation plan"
  prompt: "..."
}
```
```

**New (CORRECT)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the plan-architect agent.

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan from research findings"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/plan-architect.md

    **PRIMARY OBLIGATION - Plan File Creation**

    **ABSOLUTE REQUIREMENT**: Creating the plan file at the specified path is your PRIMARY task.

    **Planning Context**:
    - **Workflow Description**: ${WORKFLOW_DESCRIPTION}
    - **Plan File Path**: ${PLAN_PATH}
    - **Project Standards**: /home/benjamin/.config/CLAUDE.md

    **Research Report References** (METADATA ONLY - NOT FULL CONTENT):
    $(for REPORT_PATH in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
      echo "  - Report: $REPORT_PATH"
      echo "    Title: $(echo "$REPORT_METADATA" | jq -r '.title')"
      echo "    Summary: $(echo "$REPORT_METADATA" | jq -r '.summary')"
      echo ""
    done)

    **STEP 1 (CRITICAL)**: Verify plan path is absolute
    If ${PLAN_PATH} is empty or relative, EXIT with error.

    **STEP 2 (MANDATORY)**: Create plan file FIRST
    Use Write tool to create ${PLAN_PATH} with plan structure.
    Include: Metadata, Overview, Phases, Testing Strategy

    **STEP 3**: Analyze research report findings
    Read research reports referenced above (use Read tool)
    Extract relevant findings, patterns, recommendations
    Synthesize into coherent implementation approach

    **STEP 4**: Develop implementation phases
    Break work into 3-6 phases with clear objectives
    Include task lists, file references, testing requirements
    Apply complexity scoring (1-10 scale)
    Add phase dependencies for parallel execution where possible

    **STEP 5**: Return completion signal
    Output EXACTLY: PLAN_CREATED: ${PLAN_PATH}

    **MANDATORY**: Orchestrator will verify plan file exists.
  "
}
```

**Key Differences from Research Agent**:
1. Behavioral file: `plan-architect.md` (not research-specialist.md)
2. Input: Research report metadata (NOT full content) - 95% context savings
3. Output: Implementation plan file (not research report)
4. Completion signal: `PLAN_CREATED:` (not REPORT_CREATED:)

#### Verification After Planning Invocation

**Add immediately after plan-architect invocation**:

```bash
# MANDATORY VERIFICATION: Plan file must exist
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Plan File Creation"
echo "════════════════════════════════════════════════════════"
echo ""

# Retry with exponential backoff
if ! retry_with_backoff 2 1000 [ -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL: Plan not created at $PLAN_PATH"
  echo ""
  echo "Workflow TERMINATED at Phase 2."
  exit 1
fi

echo "✅ VERIFIED: Plan exists at $PLAN_PATH"

# Extract plan metadata
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")
PLAN_PHASES=$(echo "$PLAN_METADATA" | jq -r '.phase_count')
PLAN_COMPLEXITY=$(echo "$PLAN_METADATA" | jq -r '.complexity_score')
PLAN_ESTIMATE=$(echo "$PLAN_METADATA" | jq -r '.time_estimate')

echo "  Phases: $PLAN_PHASES"
echo "  Complexity: $PLAN_COMPLEXITY/10"
echo "  Estimate: $PLAN_ESTIMATE"
echo ""
```

#### Context Pruning After Planning Phase

```bash
# Context pruning: Remove full plan-architect output
echo "PROGRESS: Pruning planning phase context..."

prune_phase_metadata "planning"
prune_subagent_output "PLAN_ARCHITECT_OUTPUT" "implementation_plan"

echo "✓ Context pruned: Reduced to <30% usage"
echo ""
echo "Phase 2 Complete: Plan created at $PLAN_PATH"
echo ""
```

**Files Modified**: `.claude/commands/supervise.md` (Phase 2 section)

### Task Group 1.5: Convert Implementation Phase Invocations (Phase 3)

**Location**: supervise.md Phase 3 section

**Current Pattern Count**: 1-3 invocations (code-writer agents, potentially parallel)

**Pattern Source**: `/orchestrate` implementation delegation

#### Invocation: Code Writer Conversion

**New (CORRECT)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the code-writer agent.

Task {
  subagent_type: "general-purpose"
  description: "Implement Phase ${PHASE_NUM} from plan"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/code-writer.md

    **PRIMARY OBLIGATION - Code Implementation**

    **Implementation Context**:
    - **Plan File**: ${PLAN_PATH}
    - **Phase Number**: ${PHASE_NUM}
    - **Phase Name**: ${PHASE_NAME}
    - **Project Standards**: /home/benjamin/.config/CLAUDE.md

    **Plan Metadata** (NOT full content):
    - Total Phases: ${PLAN_PHASES}
    - Current Phase Complexity: ${PHASE_COMPLEXITY}/10
    - Current Phase Tasks: ${PHASE_TASK_COUNT}

    **STEP 1**: Read plan file to understand phase objectives
    Use Read tool to load ${PLAN_PATH}
    Extract Phase ${PHASE_NUM} tasks and requirements

    **STEP 2**: Implement phase tasks per behavioral guidelines
    Use Read/Write/Edit tools to modify codebase
    Follow project standards from CLAUDE.md
    Implement all tasks in phase checklist

    **STEP 3**: Mark phase tasks complete in plan
    Use Edit tool to check off completed tasks
    Update phase status in plan file

    **STEP 4**: Run phase-specific tests (if applicable)
    Execute tests per Testing Protocols in CLAUDE.md
    Log test results

    **STEP 5**: Return completion signal with status
    Output EXACTLY: PHASE_COMPLETE: ${PHASE_NUM} [PASS|FAIL]
    Include test results if tests were run

    **MANDATORY**: Orchestrator will verify phase tasks marked complete.
  "
}
```

**Key Differences**:
1. Behavioral file: `code-writer.md`
2. Input: Plan metadata + phase number (not full plan content)
3. Output: Modified code files + updated plan
4. Completion signal: `PHASE_COMPLETE:`

#### Verification After Implementation Invocation

```bash
# MANDATORY VERIFICATION: Phase tasks must be marked complete
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Phase ${PHASE_NUM} Implementation"
echo "════════════════════════════════════════════════════════"
echo ""

# Verify phase completion in plan file
if ! retry_with_backoff 2 1000 grep -q "\[x\].*Phase ${PHASE_NUM}" "$PLAN_PATH"; then
  echo "❌ CRITICAL: Phase ${PHASE_NUM} tasks not marked complete in plan"
  echo ""
  echo "Workflow TERMINATED at Phase 3."
  exit 1
fi

echo "✅ VERIFIED: Phase ${PHASE_NUM} tasks marked complete"

# Extract implementation metadata (files modified)
FILES_MODIFIED=$(grep -A 50 "Phase ${PHASE_NUM}" "$PLAN_PATH" | grep -o '`[^`]*\.[a-z]*`' | sort -u | wc -l)

echo "  Files modified: $FILES_MODIFIED"
echo ""

IMPLEMENTATION_OCCURRED="true"
```

#### Context Pruning After Implementation Phase

```bash
# Context pruning: Remove full code-writer output
echo "PROGRESS: Pruning implementation phase context..."

prune_phase_metadata "implementation"
prune_subagent_output "CODE_WRITER_OUTPUT" "phase_${PHASE_NUM}_implementation"

echo "✓ Context pruned: Reduced to <30% usage"
echo ""
echo "Phase 3 Complete: Phase ${PHASE_NUM} implemented"
echo ""
```

**Files Modified**: `.claude/commands/supervise.md` (Phase 3 section)

### Task Group 1.6: Convert Testing Phase Invocation (Phase 4)

**Location**: supervise.md Phase 4 section

**Current Pattern Count**: 1 invocation (test-specialist agent)

#### Invocation: Test Specialist Conversion

**New (CORRECT)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the test-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Run test suite and validate implementation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/test-specialist.md

    **PRIMARY OBLIGATION - Test Execution**

    **Testing Context**:
    - **Plan File**: ${PLAN_PATH}
    - **Test Output Path**: ${TOPIC_PATH}/outputs/test_results.txt
    - **Testing Protocols**: Per CLAUDE.md Testing Protocols section

    **STEP 1**: Determine test command from CLAUDE.md
    Read /home/benjamin/.config/CLAUDE.md
    Extract test commands from Testing Protocols section
    Identify project-specific test patterns

    **STEP 2**: Execute test suite
    Use Bash tool to run tests
    Capture stdout and stderr
    Parse test results for pass/fail counts

    **STEP 3**: Write test results to output file
    Use Write tool to create ${TOPIC_PATH}/outputs/test_results.txt
    Include: pass count, fail count, error messages
    Format for easy parsing by orchestrator

    **STEP 4**: Return completion signal with test status
    Output EXACTLY: TESTS_COMPLETE: [PASS|FAIL]
    If FAIL, include failure count and first error message

    **MANDATORY**: Orchestrator will verify test results file exists.
  "
}
```

#### Verification After Testing Invocation

```bash
# MANDATORY VERIFICATION: Test results file must exist
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Test Results"
echo "════════════════════════════════════════════════════════"
echo ""

TEST_RESULTS_FILE="${TOPIC_PATH}/outputs/test_results.txt"

if ! retry_with_backoff 2 1000 [ -f "$TEST_RESULTS_FILE" ]; then
  echo "❌ WARNING: Test results file not found"
  echo "  Expected: $TEST_RESULTS_FILE"
  echo "  Assuming tests FAILED"
  TESTS_PASSING="false"
else
  echo "✅ VERIFIED: Test results file exists"

  # Parse test results
  if grep -q "TESTS_COMPLETE: PASS" "$TEST_RESULTS_FILE"; then
    TESTS_PASSING="true"
    echo "  Test Status: ✅ PASS"
  else
    TESTS_PASSING="false"
    echo "  Test Status: ❌ FAIL"

    # Extract failure details
    FAILURE_COUNT=$(grep -o "Failures: [0-9]*" "$TEST_RESULTS_FILE" | grep -o "[0-9]*")
    echo "  Failures: $FAILURE_COUNT"
  fi
fi

echo ""
```

#### Context Pruning After Testing Phase

```bash
# Context pruning: Remove full test-specialist output
echo "PROGRESS: Pruning testing phase context..."

prune_phase_metadata "testing"
prune_subagent_output "TEST_SPECIALIST_OUTPUT" "test_execution"

echo "✓ Context pruned: Reduced to <30% usage"
echo ""
echo "Phase 4 Complete: Tests executed (Status: $TESTS_PASSING)"
echo ""
```

**Files Modified**: `.claude/commands/supervise.md` (Phase 4 section)

### Task Group 1.7: Convert Debug Phase Invocations (Phase 5 - Conditional)

**Location**: supervise.md Phase 5 section

**Current Pattern Count**: 1-2 invocations (debug-analyst agents, only if TESTS_PASSING=false)

**Conditional Entry**: Only execute if `$TESTS_PASSING = "false"`

#### Invocation: Debug Analyst Conversion

**New (CORRECT)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the debug-analyst agent.

Task {
  subagent_type: "general-purpose"
  description: "Analyze test failures and identify root causes"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/debug-analyst.md

    **PRIMARY OBLIGATION - Debug Analysis**

    **Debug Context**:
    - **Test Results File**: ${TEST_RESULTS_FILE}
    - **Plan File**: ${PLAN_PATH}
    - **Debug Report Path**: ${DEBUG_REPORT}
    - **Project Root**: ${PROJECT_ROOT}

    **STEP 1**: Read test results to understand failures
    Use Read tool to load ${TEST_RESULTS_FILE}
    Extract error messages, stack traces, failure patterns
    Identify affected files and functions

    **STEP 2**: Investigate root causes
    Use Grep/Read tools to analyze failing code
    Identify logic errors, missing dependencies, configuration issues
    Compare against project standards

    **STEP 3**: Create debug report
    Use Write tool to create ${DEBUG_REPORT}
    Include: Root cause analysis, proposed fixes, file references
    Structure for easy parsing by orchestrator

    **STEP 4**: Return completion signal with findings
    Output EXACTLY: DEBUG_REPORT_CREATED: ${DEBUG_REPORT}
    Include 1-line summary of root cause

    **MANDATORY**: Orchestrator will verify debug report exists.
  "
}
```

#### Verification After Debug Invocation

```bash
# MANDATORY VERIFICATION: Debug report must exist
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Debug Report"
echo "════════════════════════════════════════════════════════"
echo ""

if ! retry_with_backoff 2 1000 [ -f "$DEBUG_REPORT" ]; then
  echo "❌ WARNING: Debug report not created"
  echo "  Expected: $DEBUG_REPORT"
  echo "  Continuing without debug analysis"
else
  echo "✅ VERIFIED: Debug report exists at $DEBUG_REPORT"

  # Extract debug metadata
  DEBUG_METADATA=$(extract_report_metadata "$DEBUG_REPORT")
  DEBUG_FINDINGS=$(echo "$DEBUG_METADATA" | jq -r '.key_findings[]' | head -3)

  echo "  Findings: $(echo "$DEBUG_FINDINGS" | wc -l) root causes identified"
  echo ""
fi
```

#### Context Pruning After Debug Phase

```bash
# Context pruning: Remove full debug-analyst output
echo "PROGRESS: Pruning debug phase context..."

prune_phase_metadata "debug"
prune_subagent_output "DEBUG_ANALYST_OUTPUT" "debug_analysis"

echo "✓ Context pruned: Reduced to <30% usage"
echo ""
echo "Phase 5 Complete: Debug report created at $DEBUG_REPORT"
echo ""
```

**Files Modified**: `.claude/commands/supervise.md` (Phase 5 section)

### Task Group 1.8: Convert Documentation Phase Invocation (Phase 6)

**Location**: supervise.md Phase 6 section

**Current Pattern Count**: 1 invocation (doc-writer agent)

**Conditional Entry**: Only execute if `$IMPLEMENTATION_OCCURRED = "true"`

#### Invocation: Doc Writer Conversion

**New (CORRECT)**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the doc-writer agent.

Task {
  subagent_type: "general-purpose"
  description: "Update documentation and create workflow summary"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/doc-writer.md

    **PRIMARY OBLIGATION - Documentation Updates**

    **Documentation Context**:
    - **Plan File**: ${PLAN_PATH}
    - **Summary File Path**: ${SUMMARY_PATH}
    - **Research Reports**: ${SUCCESSFUL_REPORT_COUNT} reports created
    - **Implementation Status**: ${IMPLEMENTATION_OCCURRED}
    - **Test Status**: ${TESTS_PASSING}

    **STEP 1**: Read plan and implementation artifacts
    Use Read tool to load ${PLAN_PATH}
    Review implementation phases and completed tasks
    Extract files modified and features added

    **STEP 2**: Update project documentation
    Use Edit tool to update relevant README.md files
    Document new features, API changes, configuration
    Follow Documentation Standards from CLAUDE.md

    **STEP 3**: Create workflow summary
    Use Write tool to create ${SUMMARY_PATH}
    Include: Workflow overview, phases completed, artifacts created
    Reference: research reports, plan file, implementation details
    Format: Structured markdown for easy navigation

    **STEP 4**: Return completion signal
    Output EXACTLY: DOCS_UPDATED: ${SUMMARY_PATH}
    Include count of documentation files modified

    **MANDATORY**: Orchestrator will verify summary file exists.
  "
}
```

#### Verification After Documentation Invocation

```bash
# MANDATORY VERIFICATION: Summary file must exist
echo ""
echo "════════════════════════════════════════════════════════"
echo "  VERIFICATION CHECKPOINT - Documentation Summary"
echo "════════════════════════════════════════════════════════"
echo ""

if ! retry_with_backoff 2 1000 [ -f "$SUMMARY_PATH" ]; then
  echo "❌ WARNING: Summary not created at $SUMMARY_PATH"
  echo "  Workflow completed without summary documentation"
else
  echo "✅ VERIFIED: Summary exists at $SUMMARY_PATH"

  # Extract summary metadata
  SUMMARY_METADATA=$(extract_report_metadata "$SUMMARY_PATH")
  SUMMARY_TITLE=$(echo "$SUMMARY_METADATA" | jq -r '.title')

  echo "  Summary: $SUMMARY_TITLE"
  echo ""
fi
```

#### Context Pruning After Documentation Phase

```bash
# Final context pruning
echo "PROGRESS: Pruning documentation phase context..."

prune_phase_metadata "documentation"
prune_subagent_output "DOC_WRITER_OUTPUT" "documentation_updates"

echo "✓ Context pruned: Workflow complete at <30% usage"
echo ""
echo "Phase 6 Complete: Documentation updated"
echo ""
```

**Files Modified**: `.claude/commands/supervise.md` (Phase 6 section)

### Task Group 1.9: Final Cleanup and Validation

#### Remove All YAML Documentation Block Wrappers

**Search Pattern**: `^```yaml$` (should find 0 matches after all conversions)

**Action**:
1. Search supervise.md for remaining YAML code blocks
2. Search for "Example agent invocation:" prefix (should find 0 matches)
3. Remove any remaining documentation-only patterns

#### Verify All Agent Invocations Include Required Elements

For EACH of the 9 agent invocations, verify presence of:
1. ✅ Imperative instruction: `**EXECUTE NOW**: USE the Task tool...`
2. ✅ Agent behavioral file reference: `.claude/agents/[name].md`
3. ✅ Absolute artifact path from location detection
4. ✅ Completion signal requirement (e.g., `REPORT_CREATED:`)
5. ✅ Verification checkpoint with `retry_with_backoff`
6. ✅ Metadata extraction after verification
7. ✅ Context pruning after phase

**Validation Command**:
```bash
# Count imperative invocations (expect 9)
grep -c "EXECUTE NOW.*Task tool" .claude/commands/supervise.md

# Count agent behavioral references (expect 6 unique agents)
grep -o ".claude/agents/[a-z-]*\.md" .claude/commands/supervise.md | sort -u | wc -l

# Count verification checkpoints (expect ≥9)
grep -c "MANDATORY VERIFICATION" .claude/commands/supervise.md

# Count metadata extraction calls (expect ≥6 phases)
grep -c "extract_.*_metadata" .claude/commands/supervise.md

# Count context pruning calls (expect ≥6 phases)
grep -c "prune_phase_metadata" .claude/commands/supervise.md

# Count error handling calls (expect ≥9)
grep -c "retry_with_backoff" .claude/commands/supervise.md
```

#### Verify File Size Target

**Current**: 2,521 lines
**Target**: ≤2,000 lines (realistic based on /orchestrate at 5,443 lines)
**Expected After Refactor**: ~1,900 lines (removing YAML wrappers, adding library sourcing)

**Measurement**:
```bash
wc -l .claude/commands/supervise.md
# Expect: ~1900 lines (600 line reduction from removing documentation bloat)
```

## Testing Specifications

### Regression Test: test_supervise_delegation.sh

**Purpose**: Validate all 7 critical checks pass after refactor

**Location**: `.claude/tests/test_supervise_delegation.sh`

**Test Cases**:

```bash
#!/bin/bash
# Test 1: Count imperative invocations (expect ≥9)
IMPERATIVE_COUNT=$(grep -c "EXECUTE NOW.*Task tool" .claude/commands/supervise.md)
if [ "$IMPERATIVE_COUNT" -ge 9 ]; then
  echo "✅ PASS: Imperative invocations: $IMPERATIVE_COUNT (expected ≥9)"
else
  echo "❌ FAIL: Imperative invocations: $IMPERATIVE_COUNT (expected ≥9)"
  exit 1
fi

# Test 2: Count YAML documentation blocks (expect 0)
YAML_BLOCK_COUNT=$(grep -c "^```yaml$" .claude/commands/supervise.md)
if [ "$YAML_BLOCK_COUNT" -eq 0 ]; then
  echo "✅ PASS: YAML blocks: $YAML_BLOCK_COUNT (expected 0)"
else
  echo "❌ FAIL: YAML blocks: $YAML_BLOCK_COUNT (expected 0)"
  exit 1
fi

# Test 3: Count agent behavioral file references (expect 6 unique)
AGENT_REF_COUNT=$(grep -o ".claude/agents/[a-z-]*\.md" .claude/commands/supervise.md | sort -u | wc -l)
if [ "$AGENT_REF_COUNT" -eq 6 ]; then
  echo "✅ PASS: Agent references: $AGENT_REF_COUNT (expected 6)"
else
  echo "❌ FAIL: Agent references: $AGENT_REF_COUNT (expected 6)"
  exit 1
fi

# Test 4: Verify library sourcing (expect 4 libraries)
LIBRARY_COUNT=$(grep -c "source.*\.claude/lib/.*\.sh" .claude/commands/supervise.md)
if [ "$LIBRARY_COUNT" -ge 4 ]; then
  echo "✅ PASS: Library sourcing: $LIBRARY_COUNT (expected 4)"
else
  echo "❌ FAIL: Library sourcing: $LIBRARY_COUNT (expected 4)"
  exit 1
fi

# Test 5: Verify metadata extraction calls (expect ≥6)
METADATA_COUNT=$(grep -c "extract_.*_metadata" .claude/commands/supervise.md)
if [ "$METADATA_COUNT" -ge 6 ]; then
  echo "✅ PASS: Metadata extraction: $METADATA_COUNT (expected ≥6)"
else
  echo "❌ FAIL: Metadata extraction: $METADATA_COUNT (expected ≥6)"
  exit 1
fi

# Test 6: Verify context pruning calls (expect ≥6)
PRUNING_COUNT=$(grep -c "prune_phase_metadata" .claude/commands/supervise.md)
if [ "$PRUNING_COUNT" -ge 6 ]; then
  echo "✅ PASS: Context pruning: $PRUNING_COUNT (expected ≥6)"
else
  echo "❌ FAIL: Context pruning: $PRUNING_COUNT (expected ≥6)"
  exit 1
fi

# Test 7: Verify error handling with retry (expect ≥9)
RETRY_COUNT=$(grep -c "retry_with_backoff" .claude/commands/supervise.md)
if [ "$RETRY_COUNT" -ge 9 ]; then
  echo "✅ PASS: Error handling: $RETRY_COUNT (expected ≥9)"
else
  echo "❌ FAIL: Error handling: $RETRY_COUNT (expected ≥9)"
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ALL CHECKS PASSED - REFACTOR SUCCESSFUL"
echo "════════════════════════════════════════════════════════"
```

**Expected Output After Refactor**:
```
✅ PASS: Imperative invocations: 9 (expected ≥9)
✅ PASS: YAML blocks: 0 (expected 0)
✅ PASS: Agent references: 6 (expected 6)
✅ PASS: Library sourcing: 4 (expected 4)
✅ PASS: Metadata extraction: 6 (expected ≥6)
✅ PASS: Context pruning: 6 (expected ≥6)
✅ PASS: Error handling: 9 (expected ≥9)

ALL CHECKS PASSED - REFACTOR SUCCESSFUL
```

## Architecture Decisions

### Decision 1: Single-Pass Consolidation

**Rationale**: Editing supervise.md three separate times (Phases 1, 3, 4) creates merge conflicts and redundant work.

**Solution**: Apply all transformations in one comprehensive editing session:
- YAML → imperative conversion
- Metadata extraction integration
- Context pruning integration
- Error handling integration

**Trade-off**: Higher complexity in Phase 1, but saves 4-5 days total and eliminates merge conflicts.

### Decision 2: Reference Behavioral Files (Not Extract Templates)

**Rationale**: All 6 agent behavioral files already exist with complete guidelines (100% coverage).

**Solution**: Reference `.claude/agents/*.md` files directly in agent prompts instead of extracting templates inline.

**Benefits**:
- Eliminates 934 lines of template duplication
- Single source of truth for agent behavior
- Saves 3-4 days of template extraction work
- Updates to behavioral files automatically apply

### Decision 3: Copy Patterns from /orchestrate

**Rationale**: /orchestrate is production-tested (5,443 lines) and demonstrates all required patterns.

**Solution**: Copy library integration, agent invocation, metadata extraction, and context pruning patterns exactly from /orchestrate.

**Benefits**:
- Zero risk (patterns proven in production)
- Consistent implementation across orchestration commands
- No need to design new patterns

### Decision 4: Metadata-Only Passing Between Phases

**Rationale**: Passing full report/plan content between phases consumes 5000+ tokens per artifact.

**Solution**: Extract metadata (title, 50-word summary, key findings) after verifications and pass only metadata to subsequent agents.

**Benefits**:
- 95% context reduction per artifact (5000 → 250 tokens)
- <30% context usage throughout workflow
- Enables 6+ phase workflows without context overflow

### Decision 5: retry_with_backoff for All Verifications

**Rationale**: Transient failures (timeouts, file locks) should not terminate workflows.

**Solution**: Wrap all file existence verifications with `retry_with_backoff 2 1000` (2 retries, 1000ms initial delay, exponential backoff).

**Benefits**:
- >95% recovery rate for transient errors
- <5% performance overhead (negligible)
- Graceful degradation vs. hard failures

## Performance Considerations

### Context Usage Target: <30%

**Mechanism**: Context pruning after each phase using `prune_phase_metadata()` and `prune_subagent_output()`.

**Effect**: Removes full agent outputs from context, retaining only metadata (title, summary, findings).

**Measurement**: Monitor context usage after each phase, expect <30% throughout 6-phase workflow.

### File Creation Rate: 100%

**Mechanism**: Pre-calculated absolute paths injected into agent prompts, verification checkpoints with retry logic.

**Effect**: Agents receive exact file paths, no path calculation ambiguity.

**Measurement**: All verifications pass on first attempt (no retries needed for path mismatches).

### Delegation Rate: 100%

**Mechanism**: Imperative "EXECUTE NOW" pattern with explicit behavioral file references.

**Effect**: Agents interpret invocations as executable instructions, not documentation examples.

**Measurement**: All 9 agent invocations execute and return completion signals.

## Error Scenarios and Recovery

### Scenario 1: Research Agent Returns Summary Instead of Creating File

**Detection**: Verification checkpoint fails (`[ ! -f "$REPORT_PATH" ]`)

**Recovery**: retry_with_backoff executes 2 retries with exponential backoff

**Escalation**: If still fails, workflow terminates with diagnostic error:
```
❌ CRITICAL: Report not created at $REPORT_PATH

POSSIBLE CAUSES:
  - Agent used relative path instead of absolute
  - Agent returned summary instead of creating file
  - File creation failed (permissions, disk space)

Workflow TERMINATED at Phase 1.
```

### Scenario 2: Metadata Extraction Fails (Malformed Report)

**Detection**: `jq` command fails or returns null

**Recovery**: Log warning, use filename as title, "No summary available" as summary

**Escalation**: Continue workflow with degraded metadata (not critical failure)

### Scenario 3: Test Failures in Phase 4

**Detection**: Test results file contains "TESTS_COMPLETE: FAIL"

**Recovery**: Set `TESTS_PASSING=false`, conditionally enter Phase 5 (Debug) instead of terminating

**Escalation**: Debug phase creates analysis, workflow continues to documentation

### Scenario 4: Context Usage Exceeds 30% Target

**Detection**: Monitor context usage after each phase

**Recovery**: Apply additional pruning with `prune_subagent_output()` for older phases

**Escalation**: If still exceeds 40%, warn user and suggest reducing research complexity

## Success Criteria

### Primary Goals
- ✅ 100% agent delegation rate (9/9 invocations executing)
- ✅ 0 YAML documentation blocks remaining
- ✅ All agent invocations reference `.claude/agents/*.md` behavioral files
- ✅ All verifications use `retry_with_backoff()` error handling
- ✅ Metadata extraction after each verification (6+ phases)
- ✅ Context pruning after each phase (<30% usage)
- ✅ Regression test passes (7/7 checks)

### File Modifications
- ✅ `.claude/commands/supervise.md` updated with all transformations
- ✅ File size ≤2,000 lines (realistic target, expect ~1,900)

### Testing
- ✅ Regression test created: `.claude/tests/test_supervise_delegation.sh`
- ✅ All 7 test checks pass
- ✅ Test integrated into `.claude/tests/run_all_tests.sh`

## Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE 1 TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
  - Use spec-updater: `mark_phase_complete` function
  - Verify hierarchy synchronization
- [ ] **Run regression test**: `.claude/tests/test_supervise_delegation.sh`
  - Verify all 7 checks passing
  - Debug failures before proceeding to Phase 2
- [ ] **Create git commit** with standardized message
  - Format: `feat(438): complete Phase 1 - Convert to Executable Invocations`
  - Include: `.claude/commands/supervise.md`, `.claude/tests/test_supervise_delegation.sh`
  - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
  - Include: Plan path, phase number, completion status
  - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
  - Verify bidirectional links intact
  - Update plan metadata with completion timestamp

---

**EXPANSION_CREATED**: /home/benjamin/.config/.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/artifacts/phase_1_convert_to_executable_invocations.md

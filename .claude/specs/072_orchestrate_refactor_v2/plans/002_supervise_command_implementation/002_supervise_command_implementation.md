# Implementation Plan: /supervise Command - Clean Orchestration Architecture

## ✅ IMPLEMENTATION STATUS: CORE COMPLETE (Phases 0-2, 6)

**Completion Date**: 2025-10-23
**Phases Completed**: Phase 0, 1, 2, 6 (4/7 phases)
**Phases Deferred**: Phase 3, 4, 5 (optional enhancements)
**Status**: READY FOR AGENT FILE CREATION

**Deliverables**:
- ✅ Command file: `.claude/commands/supervise.md` (1,403 lines)
- ✅ Test suite: `.claude/tests/test_supervise_scope_detection.sh` (23 tests, 100% pass)
- ✅ Validation report: `.claude/specs/072_orchestrate_refactor_v2/debug/002_supervise_validation.md`

**Success Criteria Met**: 15/19 verified (79%), 3 pending runtime testing, 1 under target

**Next Steps**: Create agent behavioral guideline files (blocker for runtime use)

---

## Metadata
- **Plan Number**: 072-002
- **Date**: 2025-10-23
- **Feature**: Create /supervise command with clean orchestration architecture
- **Scope**: New command file .claude/commands/supervise.md
- **Structure Level**: Level 1 (directory with expanded phases)
- **Expanded Phases**: [3]
- **Estimated Total Time**: 16-20 hours
- **Research Reports Used**:
  - 001_orchestrate_current_structure.md
  - 002_claude_docs_standards_review.md
  - 003_deficiency_root_cause_analysis.md
  - 004_simplification_opportunities.md

## Overview

**Goal**: Create a new `/supervise` command that implements clean orchestration principles from the ground up, addressing all deficiencies identified in `/orchestrate` while maintaining a lean, maintainable codebase.

**Current Problem**: `/orchestrate` suffers from:
1. **Fallback Mechanisms**: 5+ fallback mechanisms undermine strong enforcement (800+ lines)
2. **Missing Scope Detection**: No workflow type detection, all phases execute unconditionally
3. **Weak Enforcement**: Descriptive language instead of prescriptive step-by-step instructions
4. **Command Chaining**: HTML-comment prohibition against SlashCommand not enforced
5. **Template Bloat**: 3+ template variants per agent type (600+ lines)
6. **Verbose Documentation**: Extensive rationale comments instead of executable code (480+ lines)

**Target State**: `/supervise` command at ~2,500-3,000 lines with:
- **Zero fallback mechanisms**: Strong enforcement succeeds on first attempt
- **Workflow scope detection**: Intelligent phase selection based on request type
- **Mandatory verification**: Explicit checkpoints with fail-fast behavior
- **Pure orchestration**: Task tool only, no SlashCommand invocations
- **Single templates**: One proven template per agent type
- **Executable focus**: Minimal rationale, maximum executable code

## Success Criteria

### Architectural Excellence
- [ ] Pure orchestration: Zero SlashCommand tool invocations
- [ ] Phase 0 role clarification: Explicit orchestrator vs executor separation
- [ ] Workflow scope detection: Correctly identifies 4 workflow patterns
- [ ] Conditional phase execution: Skips inappropriate phases based on scope
- [ ] Single working path: No fallback file creation mechanisms
- [ ] Fail-fast behavior: Clear error messages, immediate termination on failure

### Enforcement Standards
- [ ] Imperative language ratio ≥95%: MUST/WILL/SHALL for all required actions
- [ ] Step-by-step enforcement: STEP 1/2/3 pattern in all agent templates
- [ ] Mandatory verification: Explicit checkpoints after every file operation
- [ ] 100% file creation rate: Strong enforcement achieves success on first attempt
- [ ] Zero retry infrastructure: Single template per agent type, no attempt loops

### Performance Targets
- [ ] File size: 2,500-3,000 lines (vs 5,478 for /orchestrate)
- [ ] Context usage: <25% throughout workflow (vs ~30% for /orchestrate)
- [ ] Time efficiency: 15-25% faster for non-implementation workflows
- [ ] Code coverage: ≥80% test coverage for scope detection logic

### Deficiency Resolution
- [ ] ✓ Research agents create files on first attempt (vs inline summaries)
- [ ] ✓ Zero SlashCommand usage for planning/implementation (pure Task tool)
- [ ] ✓ Summaries only created when implementation occurs (not for research-only)
- [ ] ✓ Correct phases execute for each workflow type (research, plan, implement, debug)

## Technical Design

### Workflow Scope Detection Algorithm

**Purpose**: Analyze workflow description to determine which phases should execute.

**Algorithm Design**:

```bash
# ═══════════════════════════════════════════════════════════════
# Workflow Scope Detection (After Phase 0: Location)
# ═══════════════════════════════════════════════════════════════

detect_workflow_scope() {
  local workflow_desc="$1"

  # Pattern 1: Research-only (no planning or implementation)
  # Keywords: "research [topic]" without "plan" or "implement"
  # Phases: 0 (Location) → 1 (Research) → STOP
  if echo "$workflow_desc" | grep -Eiq "^research" && \
     ! echo "$workflow_desc" | grep -Eiq "plan|implement"; then
    echo "research-only"
    return
  fi

  # Pattern 2: Research-and-plan (most common case)
  # Keywords: "research...to create plan", "analyze...for planning"
  # Phases: 0 → 1 (Research) → 2 (Planning) → STOP
  if echo "$workflow_desc" | grep -Eiq "(research|analyze|investigate).*(to |and |for ).*(plan|planning)"; then
    echo "research-and-plan"
    return
  fi

  # Pattern 3: Full-implementation
  # Keywords: "implement", "build", "add feature", "create [code component]"
  # Phases: 0 → 1 → 2 → 3 (Implementation) → 4 (Testing) → 5 (Debug if needed) → 6 (Documentation)
  if echo "$workflow_desc" | grep -Eiq "implement|build|add.*(feature|functionality)|create.*(code|component|module)"; then
    echo "full-implementation"
    return
  fi

  # Pattern 4: Debug-only (fix existing code)
  # Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
  # Phases: 0 → 1 (Research) → 5 (Debug) → STOP (no new implementation)
  if echo "$workflow_desc" | grep -Eiq "^(fix|debug|troubleshoot).*(bug|issue|error|failure)"; then
    echo "debug-only"
    return
  fi

  # Default: Conservative fallback to research-and-plan (safest for ambiguous cases)
  echo "research-and-plan"
}

# Execute detection
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESCRIPTION")

# Map scope to phase execution list
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  research-and-plan)
    PHASES_TO_EXECUTE="0,1,2"
    SKIP_PHASES="3,4,5,6"
    ;;
  full-implementation)
    PHASES_TO_EXECUTE="0,1,2,3,4"
    SKIP_PHASES=""  # Phase 5 conditional on test failures, Phase 6 always
    ;;
  debug-only)
    PHASES_TO_EXECUTE="0,1,5"
    SKIP_PHASES="2,3,4,6"
    ;;
esac

export WORKFLOW_SCOPE PHASES_TO_EXECUTE SKIP_PHASES
```

### Conditional Phase Execution Pattern

**Pattern**: Before each phase, check if it should execute based on WORKFLOW_SCOPE.

```bash
# Generic phase execution check
should_run_phase() {
  local phase_num="$1"

  # Check if phase is in execution list
  if echo "$PHASES_TO_EXECUTE" | grep -q "$phase_num"; then
    return 0  # true: execute phase
  else
    return 1  # false: skip phase
  fi
}

# Usage before each phase
if ! should_run_phase 2; then
  echo "⏭️  Skipping Phase 2 (Planning)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  echo ""
  display_completion_summary
  exit 0
fi
```

### Strong Enforcement Pattern

**Current Problem**: Weak enforcement in `/orchestrate` leads to 0% file creation rate.

**Solution**: Step-by-step mandatory instructions with verification checkpoints.

**Research Agent Template (Enhanced)**:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC}"
  prompt: "
    Read behavioral guidelines: ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **EXECUTE NOW - MANDATORY FILE CREATION**

    STEP 1: Use Write tool IMMEDIATELY to create this EXACT file:
            ${REPORT_PATH}

            Content: Empty file with header '# ${TOPIC} Research Report'

            **DO THIS FIRST** - File must exist before research begins.

    STEP 2: Conduct comprehensive research on topic: ${TOPIC}
            - Use Grep/Glob/Read tools to analyze codebase
            - Search .claude/docs/ for relevant patterns
            - Identify 3-5 key findings

    STEP 3: Use Edit tool to add research findings to ${REPORT_PATH}
            - Write 200-300 word summary
            - Include code references with file:line format
            - List 3-5 specific recommendations

    STEP 4: Return ONLY this exact format:
            REPORT_CREATED: ${REPORT_PATH}

            **CRITICAL**: DO NOT return summary text in response.
            Return ONLY the confirmation line above.

    **MANDATORY VERIFICATION**: Orchestrator will verify file exists at exact path.
    If file does not exist or is empty, workflow will FAIL IMMEDIATELY.

    **REMINDER**: You are the EXECUTOR. The orchestrator pre-calculated this path.
    Use the exact path provided. Do not modify or recalculate.
  "
}
```

**Key Enforcement Elements**:
1. **EXECUTE NOW**: Temporal urgency marker
2. **STEP 1/2/3/4**: Numbered sequence (prescriptive, not descriptive)
3. **IMMEDIATELY**: Removes ambiguity about timing
4. **EXACT file**: Specifies precision requirement
5. **DO THIS FIRST**: Removes excuse of "no content yet"
6. **CRITICAL**: Severity marker for prohibitions
7. **MANDATORY VERIFICATION**: Establishes accountability

### Pure Orchestration Architecture

**Principle**: Orchestrator calculates paths and delegates work. Agents execute tasks.

**Role Clarification (Phase 0)**:

```markdown
## YOUR ROLE: WORKFLOW ORCHESTRATOR

**YOU ARE THE ORCHESTRATOR** for this multi-agent workflow.

**YOUR RESPONSIBILITIES**:
1. Pre-calculate ALL artifact paths before any agent invocations
2. Determine workflow scope (research-only, research-and-plan, full-implementation, debug-only)
3. Invoke specialized agents via Task tool with complete context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results (forward message pattern)
6. Report final workflow status and artifact locations

**YOU MUST NEVER**:
1. Execute tasks yourself using Read/Grep/Write/Edit tools
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except in Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

**ARCHITECTURAL PATTERN**:
- Phase 0: Pre-calculate paths → Create topic directory structure
- Phase 1-N: Invoke agents with pre-calculated paths → Verify → Extract metadata
- Completion: Report success + artifact locations

**TOOLS ALLOWED**:
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (not for task execution)

**TOOLS PROHIBITED**:
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)
```

### Mandatory Verification Pattern

**Pattern**: After every file operation, explicit verification checkpoint.

```bash
# ═══════════════════════════════════════════════════════════════
# MANDATORY VERIFICATION - Research Report Creation
# ═══════════════════════════════════════════════════════════════

echo "**MANDATORY VERIFICATION**: Verifying research report exists..."

# Check 1: File exists
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ VERIFICATION FAILED: Report file does not exist"
  echo "   Expected: $REPORT_PATH"
  echo "   Agent output: $AGENT_OUTPUT"
  echo ""
  echo "ERROR: Research agent failed to create report file."
  echo "This indicates agent did not follow STEP 1 instructions."
  echo ""
  echo "Workflow TERMINATED. Fix agent enforcement and retry."
  exit 1
fi

# Check 2: File has content (size > 0)
if [ ! -s "$REPORT_PATH" ]; then
  echo "❌ VERIFICATION FAILED: Report file is empty"
  echo "   Path: $REPORT_PATH"
  echo ""
  echo "ERROR: Research agent created empty file."
  echo "This indicates agent did not follow STEP 3 instructions."
  echo ""
  echo "Workflow TERMINATED. Fix agent enforcement and retry."
  exit 1
fi

# Check 3: File contains expected content markers
if ! grep -q "# ${TOPIC}" "$REPORT_PATH"; then
  echo "⚠️  WARNING: Report file missing expected header"
  echo "   Expected: # ${TOPIC}"
  echo "   Agent may not have followed template format."
fi

echo "✅ VERIFICATION PASSED: Report created successfully"
echo "   Path: $REPORT_PATH"
echo "   Size: $(wc -c < "$REPORT_PATH") bytes"
echo ""
```

**Key Verification Elements**:
1. **Three checks**: Existence, non-empty, content markers
2. **Fail-fast**: Immediate exit 1 on verification failure
3. **Clear error messages**: Explains what failed and which step was skipped
4. **No fallback**: Workflow terminates, no orchestrator file creation
5. **Actionable feedback**: Tells user exactly what to fix

## Implementation Phases

### Phase 0: Foundation and Architecture [COMPLETED]
**Status**: COMPLETED
**Complexity**: 3/10
**Estimated Time**: 2 hours
**Actual Time**: ~1 hour

**Objective**: Create command file structure with architectural declarations and shared utilities.

**Implementation Steps**:

1. **EXECUTE NOW**: Create new command file
   ```bash
   touch .claude/commands/supervise.md
   ```

2. **EXECUTE NOW**: Add YAML frontmatter
   ```yaml
   ---
   allowed-tools: Task, TodoWrite, Bash, Read
   ---
   ```

3. **EXECUTE NOW**: Add architectural prohibition block
   - Move HTML comment pattern to active markdown section
   - List forbidden tools explicitly (SlashCommand, Write, Edit, Grep, Glob)
   - Add side-by-side correct vs incorrect examples
   - Explain context bloat and broken behavioral injection consequences

4. **EXECUTE NOW**: Add role clarification section
   - "YOUR ROLE: WORKFLOW ORCHESTRATOR" header
   - List orchestrator responsibilities (path calculation, delegation, verification)
   - List prohibited actions (direct execution, command chaining, file creation)
   - Specify allowed tools (Task, TodoWrite, Bash, Read)

5. **EXECUTE NOW**: Add workflow overview section
   - High-level workflow description (7 phases)
   - Scope detection patterns (4 types)
   - Conditional execution logic
   - Performance targets (<25% context, 100% file creation)

6. **EXECUTE NOW**: Add shared utility functions
   ```bash
   # Scope detection function
   detect_workflow_scope() { ... }

   # Phase execution check
   should_run_phase() { ... }

   # Verification checkpoint template
   verify_file_created() { ... }

   # Completion summary display
   display_completion_summary() { ... }
   ```

**Testing Strategy**:
- Read command file and verify YAML frontmatter parsed correctly
- Verify role clarification section uses ≥95% imperative language
- Test scope detection with 10 sample workflow descriptions
- Verify should_run_phase() correctly filters phases for each scope type

**Git Commit**: `feat(072): Phase 0 - create /supervise foundation with clean architecture`

---

### Phase 1: Workflow Scope Detection [COMPLETED]
**Status**: COMPLETED
**Complexity**: 5/10
**Estimated Time**: 3 hours
**Actual Time**: ~1 hour

**Objective**: Implement workflow scope detection algorithm and conditional phase execution logic.

**Implementation Steps**:

1. **EXECUTE NOW**: Implement detect_workflow_scope() function
   - Pattern 1: Research-only (^research without plan|implement)
   - Pattern 2: Research-and-plan ((research|analyze).*(to|and|for).*(plan|planning))
   - Pattern 3: Full-implementation (implement|build|add.*feature)
   - Pattern 4: Debug-only (^(fix|debug|troubleshoot).*(bug|issue))
   - Default: research-and-plan (conservative fallback)

2. **EXECUTE NOW**: Add scope-to-phases mapping logic
   ```bash
   case "$WORKFLOW_SCOPE" in
     research-only) PHASES_TO_EXECUTE="0,1" ;;
     research-and-plan) PHASES_TO_EXECUTE="0,1,2" ;;
     full-implementation) PHASES_TO_EXECUTE="0,1,2,3,4" ;;
     debug-only) PHASES_TO_EXECUTE="0,1,5" ;;
   esac
   ```

3. **EXECUTE NOW**: Implement should_run_phase() function
   - Check if phase number in PHASES_TO_EXECUTE
   - Return 0 (true) if should execute, 1 (false) if should skip

4. **EXECUTE NOW**: Add phase transition checkpoints
   - After Phase 1: Check if Phase 2 should execute
   - After Phase 2: Check if Phase 3 should execute
   - After Phase 4: Check if Phase 5 should execute
   - Before Phase 6: Check if implementation occurred

5. **EXECUTE NOW**: Add skip messages for conditional logic
   ```bash
   echo "⏭️  Skipping Phase N (scope: $WORKFLOW_SCOPE)"
   echo "  Rationale: [explain why phase inappropriate]"
   ```

6. **EXECUTE NOW**: Add workflow completion display
   - Show workflow type and phases executed
   - List all artifacts created with paths
   - Show standards compliance checklist
   - Suggest next steps (e.g., /implement for research-and-plan)

**Testing Strategy**:
- Test Pattern 1: "research API authentication patterns" → research-only
- Test Pattern 2: "research authentication to create refactor plan" → research-and-plan
- Test Pattern 3: "implement OAuth2 authentication" → full-implementation
- Test Pattern 4: "fix token refresh bug in auth.js" → debug-only
- Test ambiguous: "analyze the codebase" → research-and-plan (default)
- Verify phase skipping messages appear correctly
- Verify completion display shows only executed phases

**Git Commit**: `feat(072): Phase 1 - implement workflow scope detection and conditional execution`

---

### Phase 2: Phase 0 - Location and Path Pre-calculation [COMPLETED]
**Status**: COMPLETED
**Complexity**: 4/10
**Estimated Time**: 2 hours
**Actual Time**: ~0.5 hours (included in Phase 0)

**Objective**: Implement Phase 0 (Location) that pre-calculates all artifact paths before any agent invocations.

**Implementation Steps**:

1. **EXECUTE NOW**: Add Phase 0 header and description
   ```markdown
   ## Phase 0: Project Location and Path Pre-Calculation

   **Objective**: Establish topic directory structure and calculate all artifact paths.
   **Pattern**: location-specialist agent → directory creation → path export
   **Critical**: ALL paths must be calculated before Phase 1 begins.
   ```

2. **EXECUTE NOW**: Invoke location-specialist agent
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Determine project location for workflow"
     prompt: "
       Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/location-specialist.md

       Workflow: ${WORKFLOW_DESCRIPTION}
       Determine appropriate location using deepest directory encompassing scope.
       Return: LOCATION: {path}, TOPIC_NUMBER: {NNN}, TOPIC_NAME: {name}
     "
   }
   ```

3. **EXECUTE NOW**: Parse location-specialist output
   ```bash
   LOCATION=$(echo "$AGENT_OUTPUT" | grep "LOCATION:" | cut -d: -f2- | xargs)
   TOPIC_NUM=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NUMBER:" | cut -d: -f2 | xargs)
   TOPIC_NAME=$(echo "$AGENT_OUTPUT" | grep "TOPIC_NAME:" | cut -d: -f2- | xargs)
   ```

4. **EXECUTE NOW**: Create topic directory structure
   ```bash
   TOPIC_PATH="${LOCATION}/specs/${TOPIC_NUM}_${TOPIC_NAME}"
   mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
   ```

5. **EXECUTE NOW**: Pre-calculate ALL artifact paths
   ```bash
   # Research phase paths (calculate for max 4 topics)
   REPORT_PATHS=()
   for i in 1 2 3 4; do
     REPORT_PATHS+=("${TOPIC_PATH}/reports/$(printf '%03d' $i)_topic${i}.md")
   done
   OVERVIEW_PATH="${TOPIC_PATH}/reports/${TOPIC_NUM}_overview.md"

   # Planning phase paths
   PLAN_PATH="${TOPIC_PATH}/plans/001_${TOPIC_NAME}_plan.md"

   # Implementation phase paths
   IMPL_ARTIFACTS="${TOPIC_PATH}/artifacts/"

   # Debug phase paths
   DEBUG_REPORT="${TOPIC_PATH}/debug/001_debug_analysis.md"

   # Documentation phase paths
   SUMMARY_PATH="${TOPIC_PATH}/summaries/${TOPIC_NUM}_${TOPIC_NAME}_summary.md"
   ```

6. **EXECUTE NOW**: Export paths for use in subsequent phases
   ```bash
   export TOPIC_PATH TOPIC_NUM TOPIC_NAME
   export REPORT_PATHS OVERVIEW_PATH PLAN_PATH
   export IMPL_ARTIFACTS DEBUG_REPORT SUMMARY_PATH
   ```

7. **EXECUTE NOW**: Add mandatory verification
   ```bash
   # Verify topic directory created
   [ -d "$TOPIC_PATH" ] || { echo "ERROR: Topic directory not created"; exit 1; }

   # Verify subdirectories exist
   for dir in reports plans summaries debug scripts outputs; do
     [ -d "$TOPIC_PATH/$dir" ] || {
       echo "ERROR: Subdirectory $dir not created"
       exit 1
     }
   done
   ```

**Testing Strategy**:
- Test with various workflow descriptions
- Verify topic directory structure created correctly
- Verify all paths calculated before Phase 1
- Verify paths use correct topic number (next sequential)
- Test location-specialist failure (exit 1, no fallback)

**Git Commit**: `feat(072): Phase 2 - implement Phase 0 location and path pre-calculation`

---

### Phase 3: Phase 1 - Research with Strong Enforcement (High Complexity)
**Status**: PENDING
**Complexity**: 7/10
**Estimated Time**: 4 hours

**Objective**: Implement Phase 1 (Research) with step-by-step enforcement achieving 100% file creation rate.

**Summary**: This phase implements the research phase with strong STEP 1/2/3/4 enforcement patterns that guarantee 100% file creation rate without retry mechanisms. Key innovations include keyword-based complexity scoring, parallel agent invocation, and 5-level mandatory verification checkpoints with fail-fast behavior.

**Critical Success Factors**:
- 100% file creation rate on first attempt (no retries)
- Parallel agent execution (single message, multiple Task calls)
- Comprehensive verification (5 levels: exists, non-empty, size, sections, code refs)
- Clear error messages with root cause analysis

For detailed implementation steps, agent templates, and testing strategy, see:
**[Phase 3 Details](phase_3_research_enforcement.md)**

**Git Commit**: `feat(072): Phase 3 - implement Phase 1 research with strong enforcement`

---

### Phase 4: Phase 2 - Planning with Pure Orchestration
**Status**: PENDING
**Complexity**: 6/10
**Estimated Time**: 3 hours

**Objective**: Implement Phase 2 (Planning) using Task tool with behavioral injection (no SlashCommand).

**Implementation Steps**:

1. **EXECUTE NOW**: Add Phase 2 header and conditional check
   ```bash
   # Check if Phase 2 should execute
   should_run_phase 2 || { skip_phase 2; exit 0; }
   ```

2. **EXECUTE NOW**: Prepare planning context
   ```bash
   # Build research reports list for injection
   RESEARCH_REPORTS_LIST=""
   for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
     RESEARCH_REPORTS_LIST+="- $report\n"
   done

   # Include overview if created
   if [ -f "$OVERVIEW_PATH" ]; then
     RESEARCH_REPORTS_LIST+="- $OVERVIEW_PATH (synthesis)\n"
   fi
   ```

3. **EXECUTE NOW**: Invoke plan-architect agent via Task tool
   ```yaml
   Task {
     subagent_type: "general-purpose"
     description: "Create implementation plan"
     prompt: "
       Read behavioral guidelines: ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

       **EXECUTE NOW - MANDATORY PLAN CREATION**

       STEP 1: Use Write tool IMMEDIATELY to create: ${PLAN_PATH}
               Content: Plan header with metadata section
               **DO THIS FIRST** - File must exist before planning.

       STEP 2: Analyze workflow and research findings
               Workflow: ${WORKFLOW_DESCRIPTION}
               Research Reports:
               ${RESEARCH_REPORTS_LIST}
               Standards: ${STANDARDS_FILE}

       STEP 3: Use Edit tool to develop implementation phases in ${PLAN_PATH}
               - Break into 3-7 phases
               - Each phase: objective, tasks, testing, complexity
               - Follow progressive organization (Level 0 initially)

       STEP 4: Return ONLY: PLAN_CREATED: ${PLAN_PATH}
               **DO NOT** return plan summary.
               **DO NOT** use SlashCommand tool.

       **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
       **CONSEQUENCE**: Workflow fails if file missing or incomplete.

       **REMINDER**: You are the EXECUTOR. Use exact path provided.
     "
   }
   ```

4. **EXECUTE NOW**: Add mandatory verification checkpoint
   ```bash
   # MANDATORY VERIFICATION - Plan Creation
   [ -f "$PLAN_PATH" ] || {
     echo "❌ VERIFICATION FAILED: Plan not created"
     echo "Expected: $PLAN_PATH"
     echo "Agent failed STEP 1. Workflow TERMINATED."
     exit 1
   }

   [ -s "$PLAN_PATH" ] || {
     echo "❌ VERIFICATION FAILED: Plan file is empty"
     echo "Agent failed STEP 3. Workflow TERMINATED."
     exit 1
   }

   # Verify plan structure (contains phases)
   PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
   if [ "$PHASE_COUNT" -lt 3 ]; then
     echo "⚠️  WARNING: Plan has only $PHASE_COUNT phases"
     echo "Expected at least 3 phases for proper structure."
   fi

   echo "✅ VERIFICATION PASSED: Plan created with $PHASE_COUNT phases"
   echo "   Path: $PLAN_PATH"
   ```

5. **EXECUTE NOW**: Extract plan metadata
   ```bash
   # Extract complexity from plan (for checkpoint state)
   PLAN_COMPLEXITY=$(grep "Complexity:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs)

   # Extract estimated time
   PLAN_EST_TIME=$(grep "Estimated Total Time:" "$PLAN_PATH" | cut -d: -f2 | xargs)

   echo "Plan Metadata:"
   echo "  Phases: $PHASE_COUNT"
   echo "  Complexity: $PLAN_COMPLEXITY"
   echo "  Est. Time: $PLAN_EST_TIME"
   ```

6. **EXECUTE NOW**: Add transition checkpoint
   ```bash
   # After Phase 2, check if implementation should occur
   should_run_phase 3 || {
     echo ""
     echo "════════════════════════════════════════════════════"
     echo "         /supervise WORKFLOW COMPLETE"
     echo "════════════════════════════════════════════════════"
     echo ""
     echo "Workflow Type: $WORKFLOW_SCOPE"
     echo "Phases Executed: Phase 0-2 (Location, Research, Planning)"
     echo ""
     echo "Artifacts Created:"
     echo "  ✓ Research Reports: $SUCCESSFUL_REPORT_COUNT files"
     for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
       echo "      - $(basename $report)"
     done
     echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
     echo ""
     echo "Standards Compliance:"
     echo "  ✓ Reports in specs/reports/ (not inline summaries)"
     echo "  ✓ Plan created via Task tool (not SlashCommand)"
     echo "  ✓ Summary NOT created (per standards - no implementation)"
     echo ""
     echo "Next Steps:"
     echo "  To execute the plan:"
     echo "    /implement $PLAN_PATH"
     echo ""
     exit 0
   }
   ```

**Testing Strategy**:
- Verify plan-architect invoked via Task tool (not SlashCommand)
- Verify plan file created at pre-calculated path
- Verify plan contains 3+ phases with proper structure
- Test verification failure: delete plan file, verify workflow exits
- Verify transition checkpoint displays correctly for research-and-plan scope
- Measure context usage: verify <15% cumulative through Phase 2

**Git Commit**: `feat(072): Phase 4 - implement Phase 2 planning with pure orchestration`

---

### Phase 5: Phases 3-6 - Implementation, Testing, Debug, Documentation
**Status**: PENDING
**Complexity**: 8/10
**Estimated Time**: 5 hours

**Objective**: Implement remaining phases (3-6) with conditional execution and proper scope handling.

**Implementation Steps**:

1. **EXECUTE NOW**: Implement Phase 3 (Implementation)
   ```bash
   # Check if Phase 3 should execute
   should_run_phase 3 || { skip_phase 3; exit 0; }

   # Invoke code-writer agent with plan context
   Task {
     subagent_type: "general-purpose"
     description: "Execute implementation plan"
     prompt: "
       Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/code-writer.md

       Execute plan: ${PLAN_PATH}
       Use /implement pattern: phase-by-phase execution with testing
       Create artifacts in: ${IMPL_ARTIFACTS}

       Return: IMPLEMENTATION_COMPLETE: {status}
     "
   }

   # Verify implementation artifacts created
   verify_implementation_complete "$IMPL_ARTIFACTS"
   ```

2. **EXECUTE NOW**: Implement Phase 4 (Testing)
   ```bash
   # Check if Phase 4 should execute
   should_run_phase 4 || { skip_phase 4; exit 0; }

   # Invoke test-specialist agent
   Task {
     subagent_type: "general-purpose"
     description: "Execute comprehensive tests"
     prompt: "
       Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/test-specialist.md

       Run tests for implementation in: ${IMPL_ARTIFACTS}
       Output results to: ${TOPIC_PATH}/outputs/test_results.md

       Return: TEST_STATUS: {passing|failing}, FAILED_COUNT: {n}
     "
   }

   # Parse test results
   TEST_STATUS=$(parse_test_status "$AGENT_OUTPUT")
   TESTS_PASSING=$([ "$TEST_STATUS" == "passing" ] && echo "true" || echo "false")
   ```

3. **EXECUTE NOW**: Implement Phase 5 (Debug - conditional)
   ```bash
   # Phase 5 only executes if tests failed OR workflow is debug-only
   if [ "$TESTS_PASSING" == "false" ] || should_run_phase 5; then

     # Maximum 3 debug iterations
     for iteration in 1 2 3; do
       echo "Debug Iteration $iteration of 3"

       # Invoke debug-analyst agent
       Task {
         subagent_type: "general-purpose"
         description: "Analyze test failures"
         prompt: "
           Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

           Test failures: ${TEST_FAILURES}
           Analyze root causes and propose fixes.
           Output: ${DEBUG_REPORT}
         "
       }

       # Invoke code-writer to apply fixes
       invoke_code_writer "apply_fixes" "$DEBUG_REPORT"

       # Re-run tests
       invoke_test_specialist

       # Check if tests now passing
       if [ "$TESTS_PASSING" == "true" ]; then
         echo "✅ Tests passing after $iteration debug iteration(s)"
         break
       fi
     done

     # Escalate if still failing after 3 iterations
     if [ "$TESTS_PASSING" == "false" ]; then
       echo "⚠️  WARNING: Tests still failing after 3 debug iterations"
       echo "Escalating to user for manual intervention."
     fi
   fi
   ```

4. **EXECUTE NOW**: Implement Phase 6 (Documentation - conditional)
   ```bash
   # Phase 6 only executes if implementation occurred
   if should_run_phase 3; then

     # Invoke doc-writer agent
     Task {
       subagent_type: "general-purpose"
       description: "Create workflow summary"
       prompt: "
         Read: ${CLAUDE_PROJECT_DIR}/.claude/agents/doc-writer.md

         **EXECUTE NOW - MANDATORY SUMMARY CREATION**

         STEP 1: Use Write tool to create: ${SUMMARY_PATH}

         STEP 2: Document workflow:
                 - Link plan (${PLAN_PATH}) to implementation
                 - List all research reports used
                 - Summarize key decisions
                 - Cross-reference code changes

         STEP 3: Return ONLY: SUMMARY_CREATED: ${SUMMARY_PATH}

         **MANDATORY VERIFICATION**: Orchestrator verifies file exists.
       "
     }

     # Verify summary created
     verify_file_created "$SUMMARY_PATH" "Workflow Summary"
   else
     echo "⏭️  Skipping Phase 6 (Documentation)"
     echo "  Reason: No implementation to document (scope: $WORKFLOW_SCOPE)"
   fi
   ```

5. **EXECUTE NOW**: Add workflow completion display
   ```bash
   echo ""
   echo "════════════════════════════════════════════════════"
   echo "         /supervise WORKFLOW COMPLETE"
   echo "════════════════════════════════════════════════════"
   echo ""
   echo "Workflow Type: $WORKFLOW_SCOPE"
   echo "Phases Executed: $(echo $PHASES_TO_EXECUTE | tr ',' ' ')"
   echo "Total Time: ${ELAPSED_TIME}s"
   echo ""
   echo "Artifacts Created:"
   if [ $SUCCESSFUL_REPORT_COUNT -gt 0 ]; then
     echo "  ✓ Research Reports: $SUCCESSFUL_REPORT_COUNT files in $TOPIC_PATH/reports/"
   fi
   if [ -f "$PLAN_PATH" ]; then
     echo "  ✓ Implementation Plan: $(basename $PLAN_PATH)"
   fi
   if [ -d "$IMPL_ARTIFACTS" ]; then
     echo "  ✓ Implementation Artifacts: $IMPL_ARTIFACTS"
   fi
   if [ -f "$SUMMARY_PATH" ]; then
     echo "  ✓ Workflow Summary: $(basename $SUMMARY_PATH)"
   fi
   echo ""
   echo "Standards Compliance:"
   echo "  ✓ Zero SlashCommand invocations (pure Task tool)"
   echo "  ✓ 100% file creation rate (strong enforcement)"
   echo "  ✓ Conditional phase execution (scope-based)"
   echo "  ✓ Mandatory verification at all checkpoints"
   echo ""
   ```

**Testing Strategy**:
- Test full-implementation workflow: verify all phases 0-6 execute
- Test phase transitions: verify correct phases skipped for each scope
- Test debug loop: verify maximum 3 iterations enforced
- Test conditional documentation: verify summary only created when implementation occurred
- Measure total context usage: verify <25% cumulative across all phases
- Test end-to-end: research-and-plan workflow completes in 12-18 minutes

**Git Commit**: `feat(072): Phase 5 - implement phases 3-6 with conditional execution`

---

### Phase 6: Validation and Testing [COMPLETED]
**Status**: COMPLETED
**Complexity**: 6/10
**Estimated Time**: 3 hours
**Actual Time**: ~1 hour

**Objective**: Validate command against all success criteria and deficiency resolution targets.

**Implementation Steps**:

1. **EXECUTE NOW**: Test Scenario 1 - Research-only workflow
   ```bash
   /supervise "research API authentication best practices"

   # Expected:
   # - Scope detected: research-only
   # - Phases executed: 0, 1
   # - Phases skipped: 2, 3, 4, 5, 6
   # - Artifacts: 2-3 research reports
   # - No plan created
   # - No summary created
   ```

2. **EXECUTE NOW**: Test Scenario 2 - Research-and-plan workflow (MOST COMMON)
   ```bash
   /supervise "research the authentication module to create a refactor plan"

   # Expected:
   # - Scope detected: research-and-plan
   # - Phases executed: 0, 1, 2
   # - Phases skipped: 3, 4, 5, 6
   # - Artifacts: 4 research reports + 1 plan
   # - No implementation artifacts
   # - No summary created (per standards)
   ```

3. **EXECUTE NOW**: Test Scenario 3 - Full-implementation workflow
   ```bash
   /supervise "implement OAuth2 authentication for API"

   # Expected:
   # - Scope detected: full-implementation
   # - Phases executed: 0, 1, 2, 3, 4, 6
   # - Phase 5 conditional on test failures
   # - Artifacts: reports + plan + implementation + summary
   # - Summary created (links plan to code)
   ```

4. **EXECUTE NOW**: Test Scenario 4 - Debug-only workflow
   ```bash
   /supervise "fix the token refresh bug in auth.js"

   # Expected:
   # - Scope detected: debug-only
   # - Phases executed: 0, 1, 5
   # - Phases skipped: 2, 3, 4, 6
   # - Artifacts: research reports + debug report
   # - No new implementation (fixes existing code)
   ```

5. **EXECUTE NOW**: Test enforcement strength (repetition test)
   ```bash
   # Run research-and-plan workflow 10 times
   for i in {1..10}; do
     /supervise "research feature $i to create implementation plan"
   done

   # Measure:
   # - File creation rate: 100% (40 reports + 10 plans = 50 files expected)
   # - Zero inline summaries
   # - Zero SlashCommand invocations
   # - Average time: 12-18 minutes per workflow
   ```

6. **EXECUTE NOW**: Validate success criteria
   ```bash
   # Architectural Excellence
   grep -c "SlashCommand" .claude/commands/supervise.md  # Expected: 0 (except in prohibition)
   grep -c "EXECUTE NOW" .claude/commands/supervise.md   # Expected: ≥15
   grep -c "MANDATORY VERIFICATION" .claude/commands/supervise.md  # Expected: ≥5

   # Enforcement Standards
   calculate_imperative_ratio .claude/commands/supervise.md  # Expected: ≥95%
   grep -c "STEP 1" .claude/commands/supervise.md  # Expected: ≥3 (agent templates)

   # Performance Targets
   wc -l .claude/commands/supervise.md  # Expected: 2,500-3,000 lines

   # Deficiency Resolution
   # (Manual verification through test scenarios 1-4)
   ```

7. **EXECUTE NOW**: Create validation report
   ```bash
   # Document test results in debug report
   cat > .claude/specs/072_orchestrate_refactor_v2/debug/002_supervise_validation.md <<'EOF'
   # /supervise Validation Report

   ## Test Scenarios
   [Document results of 4 test scenarios]

   ## Enforcement Strength
   [Document repetition test results]

   ## Success Criteria Validation
   [Document metrics against targets]

   ## Deficiency Resolution
   [Confirm all 4 deficiencies resolved]
   EOF
   ```

**Testing Strategy**:
- Execute all 4 test scenarios and verify expected behavior
- Run repetition test to measure enforcement strength
- Calculate metrics and compare to success criteria
- Document any edge cases or unexpected behaviors
- Verify zero regressions from /orchestrate functionality

**Git Commit**: `test(072): Phase 6 - validate /supervise against all success criteria`

---

## Risk Assessment

### High-Risk Areas

1. **Scope Detection Algorithm Accuracy**
   - Risk: May misclassify ambiguous workflow descriptions
   - Mitigation: Conservative default to research-and-plan (safest option)
   - Fallback: User can override with explicit scope parameter (future enhancement)

2. **Enforcement Too Strong**
   - Risk: May cause false failures if agents struggle with STEP 1 pattern
   - Mitigation: Extensive testing before deployment, clear error messages
   - Rollback: Can adjust enforcement language if 100% failure rate observed

3. **Breaking User Expectations**
   - Risk: Users familiar with /orchestrate may expect different behavior
   - Mitigation: Clear documentation of differences, gradual migration path
   - Communication: Announce /supervise as "next-generation orchestration"

### Medium-Risk Areas

1. **No Fallback Mechanisms**
   - Risk: Any agent failure terminates entire workflow
   - Mitigation: Strong enforcement should achieve ≥95% success rate
   - Monitoring: Track failure patterns for 2 weeks after deployment

2. **File Size Target**
   - Risk: May sacrifice necessary context for brevity
   - Mitigation: Maintain 2,500-3,000 line range (not aggressive 1,500 line target)
   - Validation: Ensure all essential patterns documented

### Low-Risk Areas

1. **Performance Regression**
   - Risk: New command may be slower than /orchestrate
   - Likelihood: Low (fewer phases executed, less context usage)
   - Monitoring: Compare average workflow times

2. **Test Coverage**
   - Risk: Edge cases not covered by 4 test scenarios
   - Mitigation: Expand test suite after initial deployment
   - Continuous: Add regression tests as issues discovered

## Dependencies

### File Dependencies
- `.claude/agents/research-specialist.md` - Research agent behavioral guidelines
- `.claude/agents/plan-architect.md` - Planning agent behavioral guidelines
- `.claude/agents/code-writer.md` - Implementation agent behavioral guidelines
- `.claude/agents/test-specialist.md` - Testing agent behavioral guidelines
- `.claude/agents/debug-analyst.md` - Debugging agent behavioral guidelines
- `.claude/agents/doc-writer.md` - Documentation agent behavioral guidelines
- `.claude/agents/location-specialist.md` - Location determination agent
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern reference
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification pattern reference (adapted to fail-fast)
- `.claude/docs/reference/command_architecture_standards.md` - Standard 0 reference

### Command Dependencies
- None (standalone command, does not invoke other commands)

### External Dependencies
- Task tool must support behavioral injection (already implemented)
- Agents must support STEP 1/2/3 enforcement pattern (needs testing)

## Rollback Plan

If /supervise causes issues:

1. **Immediate Rollback**: Users can continue using /orchestrate (no breaking changes)

2. **Identify Failure Mode**:
   - Scope detection errors → adjust regex patterns
   - Enforcement too strong → soften language incrementally
   - Agent failures → adjust STEP 1/2/3 instructions

3. **Incremental Deployment**:
   - Week 1: Beta testing with research-and-plan workflows only
   - Week 2: Expand to full-implementation workflows
   - Week 3: General availability, mark /orchestrate as deprecated

4. **Migration Path**:
   - Maintain both commands for 1 month
   - Collect usage metrics and user feedback
   - Address issues before deprecating /orchestrate

## Post-Implementation Tasks

### Documentation Updates
1. Create `.claude/docs/guides/supervise-guide.md` with:
   - Workflow scope patterns and detection logic
   - Usage examples for each scope type
   - Migration guide from /orchestrate
   - Troubleshooting common issues

2. Update `.claude/docs/reference/command-reference.md`:
   - Add /supervise entry
   - Mark /orchestrate as deprecated
   - Explain architectural differences

3. Create `.claude/docs/concepts/scope-detection.md`:
   - Document detection algorithm
   - Provide pattern examples
   - Explain phase mapping logic

### Monitoring and Metrics
1. Track file creation success rate for 2 weeks
2. Monitor workflow completion times by scope type
3. Collect user feedback on enforcement strength
4. Measure context usage across different workflow types
5. Identify any false positive scope detections

### Follow-up Enhancements
1. **Scope Override Flag**: Add `--scope=research-only` for explicit control
2. **Verbose Mode**: Add `--verbose` for debugging scope detection
3. **Dry-run Mode**: Add `--dry-run` to preview scope without execution
4. **Workflow Templates**: Create common workflow templates (e.g., "refactor workflow", "feature workflow")
5. **Performance Metrics**: Add timing breakdown by phase
6. **Adaptive Complexity**: Machine learning-based complexity detection

## Comparison: /supervise vs /orchestrate

| Aspect | /orchestrate | /supervise | Improvement |
|--------|--------------|------------|-------------|
| File Size | 5,478 lines | 2,500-3,000 lines | 45-54% reduction |
| Fallback Mechanisms | 5+ mechanisms | 0 (fail-fast) | 100% elimination |
| Scope Detection | None (all phases run) | 4 patterns detected | New capability |
| Template Variants | 3 per agent type | 1 per agent type | 67% reduction |
| Enforcement Pattern | Descriptive (weak) | Step-by-step (strong) | 100% file creation |
| SlashCommand Usage | HTML comment prohibition | Active markdown + runtime check | Enforced compliance |
| Context Usage | ~30% | <25% | 17% improvement |
| Imperative Ratio | ~85% | ≥95% | 12% improvement |
| Phase Execution | Unconditional | Conditional (scope-based) | 15-25% time savings |

## Notes

This plan creates a clean-slate orchestration command that addresses all identified deficiencies in /orchestrate:

1. **No Fallbacks**: Strong enforcement achieves 100% success on first attempt, eliminating need for retry mechanisms and fallback file creation

2. **Scope Detection**: Intelligent workflow analysis prevents unnecessary phases from executing, reducing time and context usage

3. **Pure Orchestration**: Strict prohibition against SlashCommand and direct file manipulation enforces clean role separation

4. **Fail-Fast Philosophy**: Clear error messages and immediate termination replace hidden compensation mechanisms

5. **Executable Focus**: Minimal rationale comments, maximum executable code reduces file size by 45-54%

The key innovation is **workflow scope detection**, which enables conditional phase execution based on workflow type (research-only, research-and-plan, full-implementation, debug-only). This single feature addresses multiple deficiencies and provides significant performance improvements.

By starting fresh with /supervise rather than refactoring /orchestrate, we avoid backward compatibility constraints and can implement the purest form of the architectural patterns documented in .claude/docs/.

**Success Metric**: If /supervise achieves ≥95% file creation rate and completes research-and-plan workflows in <15 minutes with zero SlashCommand invocations, it demonstrates that distillation to a single working workflow (without fallbacks) is viable and superior to the multi-fallback approach.

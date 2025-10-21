# Phase 7: Command Migration - Tier 2 & 3 (Remaining Commands) - Detailed Specification

## Phase Metadata
- **Parent Plan**: 077_execution_enforcement_migration.md
- **Phase Number**: 7
- **Objective**: Migrate /orchestrate, /debug, /refactor, /expand, /collapse, /convert-docs to execution enforcement patterns
- **Complexity**: Exceptional (10/10)
- **Duration**: 40 hours (Week 4-5)
- **Commands**: 6 remaining commands requiring Phase 0 role clarification + full pattern migration
- **Status**: PENDING

## Executive Summary

Phase 7 completes the command migration by upgrading the final 6 commands to execution enforcement standards. These commands range from highly complex multi-agent orchestrators (/orchestrate with 7-phase workflow) to conditional delegation patterns (/convert-docs with agent mode detection). Each command requires unique architectural considerations based on its delegation patterns, agent dependencies, and execution complexity.

**Key Challenge**: These commands have diverse architectural patterns:
- **7-phase workflow orchestration** (/orchestrate - 3800 lines, most complex command)
- **Parallel hypothesis investigation** (/debug - conditional multi-agent delegation)
- **Read-only analysis with report generation** (/refactor - code-reviewer agent)
- **Auto-analysis with parallel expansion agents** (/expand - complexity-estimator + expansion-specialist agents)
- **Auto-analysis with collapse coordination** (/collapse - complexity-estimator + collapse-specialist agents)
- **Conditional agent vs script mode** (/convert-docs - doc-converter agent with orchestration flag)

**Migration Approach**: Tailored Phase 0 implementations for each command's specific orchestration pattern, followed by comprehensive Pattern 1-4 enforcement and agent template updates.

---

## Command-Specific Migration Details

### 7.1: Migrate /orchestrate Command (12 hours)

**File**: `.claude/commands/orchestrate.md`
**Current Size**: 3797 lines (largest command in codebase)
**Complexity**: Exceptional (10/10)
**Agent Dependencies**: 6 agents (research-specialist, plan-architect, code-writer, debug-specialist, doc-writer, github-specialist)
**Unique Architecture**: 7-phase workflow with parallel research, adaptive implementation, conditional debugging

#### Current State Analysis

**Existing Strengths**:
- Comprehensive workflow documentation (7 phases detailed)
- Error recovery patterns documented in reference files
- Agent templates in `.claude/templates/orchestration-patterns.md`
- Logging patterns in `.claude/docs/logging-patterns.md`
- Checkpoint infrastructure (save/restore workflow state)
- TodoWrite integration for progress tracking
- Dry-run mode with workflow preview

**Critical Gaps** (Enforcement Audit: ~45/100):
- **Phase 0**: Missing orchestrator role clarification in opening
  - Current: "I'll coordinate multiple specialized subagents..."
  - Problem: Ambiguous whether Claude orchestrates or executes phases
  - Impact: May execute phases directly instead of invoking agents
- **Pattern 1**: No path pre-calculation for 5 artifact types (research reports, plans, implementation files, debug reports, documentation)
- **Pattern 2**: Verification checkpoints present but not systematically enforced
- **Pattern 3**: Error handling documented but fallback mechanisms not enforced
- **Pattern 4**: TodoWrite checkpoint reporting present but not REQUIRED
- **Agent Templates**: 6 agent invocation templates lack "THIS EXACT TEMPLATE" markers

#### Architectural Complexity

The /orchestrate command manages the most complex workflow in the system:

```
Phase 1: Research (Parallel)
  ├─ Invoke 2-4 research-specialist agents in parallel
  ├─ Collect metadata from each report (forward_message pattern)
  ├─ Verify all research reports created
  └─ Save checkpoint with research_reports: [paths]

Phase 2: Planning (Sequential)
  ├─ Invoke plan-architect with research report paths
  ├─ Verify plan file created
  └─ Save checkpoint with plan_path

Phase 3: Implementation (Adaptive)
  ├─ Invoke code-writer with plan path
  ├─ Monitor test results per phase
  ├─ Conditionally trigger Phase 4 if tests fail
  └─ Save checkpoint with implementation_status

Phase 4: Debugging (Conditional)
  ├─ Skip if tests passing (most common)
  ├─ Invoke debug-specialist if test failures detected
  ├─ Max 3 iterations, escalate if exceeded
  └─ Save checkpoint with debug_reports: [paths]

Phase 5: Documentation (Sequential)
  ├─ Invoke doc-writer for README/CHANGELOG/summary
  ├─ Verify documentation files updated
  └─ Save checkpoint with documentation_paths: [paths]

Phase 6: GitHub Integration (Conditional)
  ├─ Skip unless --create-pr flag provided
  ├─ Invoke github-specialist for PR creation
  └─ Save checkpoint with pr_url

Phase 7: Workflow Summary
  ├─ Generate execution summary
  ├─ Display metrics (duration, agents invoked, files created)
  └─ Final checkpoint: workflow_complete
```

**Delegation Pattern**: Each phase delegates to specialized agents, then aggregates results via metadata extraction (context reduction pattern).

#### Migration Approach

**Step 1: Phase 0 - Orchestrator Role Clarification** (3 hours)

Current opening (lines 1-146):
```markdown
# Multi-Agent Workflow Orchestration

I'll coordinate multiple specialized subagents through a complete development
workflow, from research to documentation, while preserving context and
enabling intelligent parallelization.
```

**Problem**: "I'll coordinate" is ambiguous - does Claude coordinate agents or execute phases?

**Solution**: Replace with explicit orchestrator role declaration:

```markdown
# Multi-Agent Workflow Orchestration

**YOU MUST orchestrate a 7-phase development workflow by delegating to specialized subagents.**

**YOUR ROLE**: You are the ORCHESTRATOR, not the executor.
- **DO NOT** execute research/planning/implementation yourself using Read/Write/Bash tools
- **ONLY** use Task tool to invoke specialized agents for each phase
- **YOUR RESPONSIBILITY**: Coordinate agents, verify outputs, manage checkpoints

**CRITICAL INSTRUCTIONS**:
- Execute all workflow phases in EXACT sequential order (Phases 1-7)
- DO NOT skip agent invocations in favor of direct execution
- DO NOT skip verification of agent outputs
- DO NOT skip checkpoint saves between phases
- Fallback mechanisms ensure 100% workflow completion
```

**Verification of Phase 0**:
- [ ] Opening paragraph explicitly states "YOU MUST orchestrate"
- [ ] "YOUR ROLE: You are the ORCHESTRATOR" present
- [ ] "DO NOT execute yourself" warnings added
- [ ] "ONLY use Task tool" directive present
- [ ] All 7 phases listed with orchestration verbs (delegate, invoke, coordinate)

**Step 2: Pattern 1 - Path Pre-Calculation for 7 Phases** (4 hours)

Each phase creates different artifact types. Add path pre-calculation blocks before each phase's agent invocation.

**Phase 1 (Research) - Calculate Report Paths**:

Insert before "Phase 1: Research (Parallel Execution)" section (line ~416):

```markdown
**STEP 1.A (REQUIRED BEFORE AGENT INVOCATION) - Calculate Research Report Paths**

**EXECUTE NOW - Pre-Calculate Report Paths for All Research Topics**:

```bash
# Source required utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"

# Extract research topics from workflow description
# Number of topics based on complexity score (calculated in Step 1.5)
COMPLEXITY_SCORE=$(calculate_workflow_complexity "$WORKFLOW_DESCRIPTION")

# Determine topic count
if [ "$COMPLEXITY_SCORE" -le 3 ]; then
  TOPIC_COUNT=1  # Low complexity
elif [ "$COMPLEXITY_SCORE" -le 6 ]; then
  TOPIC_COUNT=2  # Medium complexity
elif [ "$COMPLEXITY_SCORE" -le 9 ]; then
  TOPIC_COUNT=3  # High complexity
else
  TOPIC_COUNT=4  # Critical complexity
fi

# Identify research topics (semantic extraction from workflow)
RESEARCH_TOPICS=$(extract_research_topics "$WORKFLOW_DESCRIPTION" "$TOPIC_COUNT")

# Pre-calculate absolute report paths for each topic
REPORT_PATHS=()
for i in $(seq 1 $TOPIC_COUNT); do
  TOPIC=$(echo "$RESEARCH_TOPICS" | jq -r ".[$((i-1))].topic")
  TOPIC_SLUG=$(slugify "$TOPIC")

  # Calculate path using artifact-operations.sh
  REPORT_PATH=$(get_or_create_topic_dir "$TOPIC_SLUG" "specs")
  REPORT_PATH="${REPORT_PATH}/reports/$(printf "%03d" 1)_${TOPIC_SLUG}.md"

  REPORT_PATHS+=("$REPORT_PATH")
  echo "PROGRESS: Research $i/$TOPIC_COUNT path calculated: $REPORT_PATH"
done

# Store paths in workflow state for verification later
workflow_state[research_report_paths]="${REPORT_PATHS[@]}"
```

**MANDATORY VERIFICATION - Report Paths Calculated**:

```bash
if [ ${#REPORT_PATHS[@]} -ne $TOPIC_COUNT ]; then
  echo "❌ ERROR: Expected $TOPIC_COUNT report paths, calculated ${#REPORT_PATHS[@]}"
  exit 1
fi

for path in "${REPORT_PATHS[@]}"; do
  if [ -z "$path" ]; then
    echo "❌ ERROR: Empty report path calculated"
    exit 1
  fi
  echo "✓ VERIFIED: Report path valid: $path"
done
```
```

**Phase 2 (Planning) - Calculate Plan Path**:

Insert before "Planning Phase (Sequential)" section:

```markdown
**STEP 2.A (REQUIRED BEFORE AGENT INVOCATION) - Calculate Plan Path**

**EXECUTE NOW - Pre-Calculate Implementation Plan Path**:

```bash
# Extract plan topic from workflow description
PLAN_TOPIC=$(extract_plan_topic "$WORKFLOW_DESCRIPTION")
PLAN_SLUG=$(slugify "$PLAN_TOPIC")

# Get or create topic directory
TOPIC_DIR=$(get_or_create_topic_dir "$PLAN_SLUG" "specs")

# Calculate next plan number in topic
PLAN_NUM=$(get_next_artifact_number "$TOPIC_DIR/plans")

# Build absolute plan path
PLAN_PATH="${TOPIC_DIR}/plans/$(printf "%03d" $PLAN_NUM)_${PLAN_SLUG}.md"

# Store in workflow state
workflow_state[plan_path]="$PLAN_PATH"

echo "PROGRESS: Plan path calculated: $PLAN_PATH"
```

**MANDATORY VERIFICATION - Plan Path Calculated**:

```bash
if [ -z "$PLAN_PATH" ]; then
  echo "❌ ERROR: Plan path not calculated"
  exit 1
fi

# Verify parent directory exists
PLAN_DIR=$(dirname "$PLAN_PATH")
if [ ! -d "$PLAN_DIR" ]; then
  mkdir -p "$PLAN_DIR"
  echo "✓ Created plan directory: $PLAN_DIR"
fi

echo "✓ VERIFIED: Plan path ready: $PLAN_PATH"
```
```

**Repeat path pre-calculation pattern for**:
- Phase 3 (Implementation): Calculate modified file paths from plan
- Phase 4 (Debugging): Calculate debug report path (conditional)
- Phase 5 (Documentation): Calculate README/CHANGELOG/summary paths
- Phase 6 (GitHub): Calculate PR metadata (conditional)

**Step 3: Pattern 2 - Verification Checkpoints After Each Phase** (2 hours)

Add mandatory verification after each agent invocation. Example for Phase 1:

```markdown
**STEP 1.C (REQUIRED AFTER AGENT COMPLETION) - Verify Research Reports Created**

**MANDATORY VERIFICATION - All Research Reports Exist**:

```bash
# Check each pre-calculated report path
MISSING_REPORTS=()
for i in $(seq 0 $((${#REPORT_PATHS[@]} - 1))); do
  EXPECTED_PATH="${REPORT_PATHS[$i]}"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "⚠️  Report not found at expected path: $EXPECTED_PATH"
    MISSING_REPORTS+=("$EXPECTED_PATH")
  else
    echo "✓ VERIFIED: Report exists: $EXPECTED_PATH"
  fi
done

# If reports missing, trigger fallback mechanism
if [ ${#MISSING_REPORTS[@]} -gt 0 ]; then
  echo "⚠️  ${#MISSING_REPORTS[@]} reports missing - triggering fallback"

  # Fallback: Search alternative locations
  for missing_path in "${MISSING_REPORTS[@]}"; do
    TOPIC=$(basename "$(dirname "$(dirname "$missing_path")")")

    # Search for report in alternative locations
    FOUND_PATH=$(find specs -name "*${TOPIC}*.md" -path "*/reports/*" -type f 2>/dev/null | head -1)

    if [ -n "$FOUND_PATH" ]; then
      echo "✓ Fallback: Found report at alternate path: $FOUND_PATH"
      # Update workflow state with actual path
      workflow_state[research_reports]+=("$FOUND_PATH")
    else
      echo "❌ CRITICAL: Report not found even with fallback search"
      echo "   Expected: $missing_path"
      echo "   Searched: specs/*${TOPIC}*.md in reports/"
      exit 1
    fi
  done
fi

echo "✓ VERIFIED: All ${#REPORT_PATHS[@]} research reports confirmed"
```
```

Repeat verification pattern for all 7 phases with phase-specific checks.

**Step 4: Pattern 3 - Add Fallback Mechanisms** (1 hour)

Already partially covered in verification blocks above. Enhance with:
- Agent invocation retry (3 attempts with exponential backoff)
- Alternative path search for missing artifacts
- Manual file creation as last resort
- Checkpoint rollback on catastrophic failure

**Step 5: Pattern 4 - Checkpoint Reporting** (1 hour)

Add CHECKPOINT REQUIREMENT blocks after each phase completion:

```markdown
**CHECKPOINT REQUIREMENT - Phase 1 Research Complete**

**ABSOLUTE REQUIREMENT**: After research phase completes and all reports verified, YOU MUST report this checkpoint. This is NOT optional.

**WHY THIS MATTERS**: Checkpoint confirms research outputs are ready for planning phase and enables workflow resumption if interrupted.

**Report Format**:

```
CHECKPOINT: Research Phase Complete
- Workflow: ${WORKFLOW_DESCRIPTION}
- Complexity Score: ${COMPLEXITY_SCORE}
- Thinking Mode: ${THINKING_MODE}
- Research Topics: ${TOPIC_COUNT}
- Reports Created: ${#REPORT_PATHS[@]}
- Report Paths:
  ${REPORT_PATHS[@]}
- Context Reduction: ${CONTEXT_REDUCTION_PERCENT}%
- Status: READY FOR PLANNING
```

**Required Information**:
- Workflow description (from user input)
- Complexity score (from Step 1.5 calculation)
- Thinking mode (standard/think/think hard/think harder)
- Number of research topics
- All report file paths (absolute paths)
- Context reduction percentage (metadata vs full content)
- Ready for next phase confirmation
```

Repeat for all 7 phases with phase-specific checkpoint data.

**Step 6: Update Agent Invocation Templates** (1 hour)

Update all 6 agent invocations to include "THIS EXACT TEMPLATE" markers:

Example for research-specialist invocation (Phase 1):

```markdown
**Agent Invocation Template**:

YOU MUST use THIS EXACT TEMPLATE for each research topic (No modifications, no paraphrasing):

**CRITICAL**: All Task tool calls MUST be in a SINGLE message for true parallel execution.

```
For each research topic, invoke Task tool:

Task {
  subagent_type: "general-purpose"
  description: "Research topic: ${TOPIC}"
  prompt: |
    Read and follow the behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    Research Topic: ${TOPIC}
    Report Path: ${REPORT_PATH}  # Pre-calculated in Step 1.A

    Create comprehensive research report at the pre-calculated path.
    Return metadata only (path + 50-word summary).
}
```

**Template Variables** (ONLY allowed modifications):
- `${TOPIC}`: Research topic extracted from workflow
- `${REPORT_PATH}`: Pre-calculated report path from Step 1.A

**DO NOT modify**:
- Agent behavioral guidelines path
- Agent role statement
- Report path (must use pre-calculated value)
- Return format requirement (metadata only)
```

Repeat for plan-architect, code-writer, debug-specialist, doc-writer, github-specialist with their specific template requirements.

#### Testing Procedures

**Test 1: 7-Phase Workflow End-to-End** (10 test runs):
```bash
for i in {1..10}; do
  /orchestrate "Add user authentication with JWT tokens"

  # Verify all phases completed
  [ -f specs/*/reports/001_*.md ] && echo "✓ Research" || echo "✗ Research"
  [ -f specs/*/plans/001_*.md ] && echo "✓ Planning" || echo "✗ Planning"
  [ -d src/auth ] && echo "✓ Implementation" || echo "✗ Implementation"
  [ -f README.md ] && echo "✓ Documentation" || echo "✗ Documentation"
  [ -f specs/*/summaries/001_*.md ] && echo "✓ Summary" || echo "✗ Summary"
done
```

**Test 2: Conditional Debugging Phase**:
```bash
# Introduce failing test, verify debug phase activates
/orchestrate "Add feature with intentional test failure"

# Verify debug-specialist invoked
grep -q "debug-specialist" /tmp/orchestrate_output.log
```

**Test 3: Parallel Research Verification**:
```bash
# Complex workflow with 4 research topics
/orchestrate "Implement OAuth2 with PKCE, refresh tokens, and session management"

# Verify 4 reports created in parallel
find specs -name "*.md" -path "*/reports/*" -newer /tmp/workflow_start | wc -l
# Expected: 4
```

**Test 4: Path Mismatch Fallback**:
```bash
# Manually move report to alternative location mid-workflow
# Verify fallback search finds it
/orchestrate "Test workflow"
# Should complete successfully despite path mismatch
```

**Test 5: Audit Score**:
```bash
.claude/lib/audit-execution-enforcement.sh .claude/commands/orchestrate.md
# Expected: ≥95/100
```

#### Deliverables

- [ ] /orchestrate command updated with Phase 0 orchestrator role (lines 1-50)
- [ ] Path pre-calculation added for all 7 phases
- [ ] Verification checkpoints added after each phase
- [ ] Fallback mechanisms enhanced with search and retry
- [ ] Checkpoint reporting blocks added for all 7 phases
- [ ] 6 agent invocation templates marked with "THIS EXACT TEMPLATE"
- [ ] All tests passing (10/10 runs for workflow completion)
- [ ] Audit score ≥95/100
- [ ] Migration documented in tracking spreadsheet

---

### 7.2: Migrate /debug Command (8 hours)

**File**: `.claude/commands/debug.md`
**Current Size**: 802 lines
**Complexity**: High (8/10)
**Agent Dependencies**: debug-specialist, debug-analyst (parallel hypothesis investigation)
**Unique Architecture**: Conditional multi-agent delegation with parallel hypothesis investigation

#### Current State Analysis

**Existing Strengths**:
- Comprehensive STEP-based process (Steps 1-5, Step 3.5 for parallel investigation)
- Verification checkpoints present ("MANDATORY VERIFICATION" blocks)
- Fallback mechanisms for report creation (Write tool fallback)
- Spec-updater integration for plan annotation
- Checkpoint reporting present

**Critical Gaps** (Enforcement Audit: ~65/100):
- **Phase 0**: Missing orchestrator role clarification
  - Current: "I'll investigate issues and create diagnostic report..."
  - Problem: Suggests Claude will investigate directly
  - Impact: May analyze code directly instead of invoking debug-specialist
- **Pattern 1**: Path pre-calculation for debug reports present but not enforced as "EXECUTE NOW"
- **Pattern 2**: Verification checkpoints present but some lack fallback triggers
- **Agent Templates**: debug-analyst template has "THIS EXACT TEMPLATE" but debug-specialist invocation missing template enforcement

#### Migration Approach

**Step 1: Phase 0 - Investigation Orchestrator Role** (2 hours)

Current opening (lines 1-21):
```markdown
# /debug Command

**YOU MUST investigate and create debug report following exact process:**
```

**Problem**: "YOU MUST investigate" is ambiguous - investigate directly or orchestrate investigation?

**Solution**: Add explicit orchestrator role after line 21:

```markdown
# /debug Command

**YOU MUST orchestrate a diagnostic investigation by delegating to specialized debug agents.**

**YOUR ROLE**: You are the INVESTIGATION ORCHESTRATOR, not the investigator.
- **DO NOT** analyze code/logs/errors yourself using Read/Grep/Bash tools
- **ONLY** use Task tool to invoke debug-specialist or debug-analyst agents
- **YOUR RESPONSIBILITY**: Coordinate investigation, aggregate findings, verify report creation

**EXECUTION MODES**:
- **Simple Mode** (single root cause): Invoke debug-specialist for direct analysis
- **Complex Mode** (2+ potential causes): Invoke multiple debug-analyst agents in parallel for hypothesis testing

**CRITICAL INSTRUCTIONS**:
- Execute all investigation steps in EXACT sequential order (Steps 1-5)
- DO NOT skip Step 3.5 (parallel investigation) for complex issues
- DO NOT skip report file creation and verification
- DO NOT skip spec-updater invocation for plan linking
- Fallback mechanisms ensure 100% report creation
```

[Remaining steps for /debug follow similar pattern to /orchestrate but adapted for investigation workflow...]

---

### 7.3: Migrate /refactor Command (5 hours)

**File**: `.claude/commands/refactor.md`
**Current Size**: 259 lines
**Complexity**: Medium (6/10)
**Agent Dependencies**: code-reviewer
**Unique Architecture**: Read-only analysis with single agent delegation

[Similar detailed migration approach as /orchestrate and /debug...]

---

### 7.4: Migrate /expand Command (5 hours)

**File**: `.claude/commands/expand.md`
**Current Size**: 1065 lines
**Complexity**: High (8/10)
**Agent Dependencies**: complexity-estimator, expansion-specialist (via auto-analysis-utils.sh)
**Unique Architecture**: Auto-analysis mode with parallel expansion agents

[Similar detailed migration approach...]

---

### 7.5: Migrate /collapse Command (5 hours)

**File**: `.claude/commands/collapse.md`
**Current Size**: 609 lines
**Complexity**: High (8/10)
**Agent Dependencies**: complexity-estimator, collapse-specialist
**Unique Architecture**: Similar to /expand but reverse operation

[Similar detailed migration approach...]

---

### 7.6: Migrate /convert-docs Command (5 hours)

**File**: `.claude/commands/convert-docs.md`
**Current Size**: 215 lines
**Complexity**: Medium (6/10)
**Agent Dependencies**: doc-converter (conditional)
**Unique Architecture**: Dual-mode execution (script mode default, agent mode on flag or keywords)

[Similar detailed migration approach with mode-specific Phase 0...]

---

## Phase 7 Summary and Integration Testing

### Completion Criteria

Phase 7 is complete when ALL of the following are verified:

- [ ] All 6 commands migrated with Phase 0 role clarification
- [ ] All 6 commands have path pre-calculation (Pattern 1)
- [ ] All 6 commands have verification checkpoints (Pattern 2)
- [ ] All 6 commands have fallback mechanisms (Pattern 3)
- [ ] All 6 commands have checkpoint reporting (Pattern 4)
- [ ] All agent invocation templates marked "THIS EXACT TEMPLATE"
- [ ] All 6 commands score ≥95/100 on audit script
- [ ] All 6 commands achieve 10/10 file creation rate
- [ ] Integration tests pass for command interactions

### Integration Testing

**Test 1: /orchestrate → /debug Integration**:
```bash
# Workflow with intentional failure triggers /debug
/orchestrate "Add feature with test failure"

# Verify /orchestrate invokes /debug
# Verify both commands execute with enforcement patterns
```

**Test 2: /plan → /expand Integration**:
```bash
# Complex plan creation triggers auto-expansion
/plan "Implement complex authentication system with 5 integration points"

# Verify /expand invoked automatically for complex phases
# Verify expansion artifacts created
```

**Test 3: /refactor → /plan Integration**:
```bash
# Refactoring report used as input to planning
/refactor src/auth/

# Use refactoring report for plan creation
/plan "Implement refactoring recommendations" specs/reports/*_refactoring_*.md

# Verify plan incorporates refactoring findings
```

### Performance Metrics

**Expected Improvements**:
- File creation rate: 60-80% → 100%
- Agent delegation success: Variable → Consistent
- Verification checkpoint execution: ~40% → 100%
- Fallback mechanism activation: ~20% → 100% (when needed)
- Audit scores: 40-70/100 → 95-100/100

**Time Allocation Validation**:
- /orchestrate (12 hours): Justified by 3800 lines, 7 phases, 6 agent templates
- /debug (8 hours): Justified by complex conditional delegation, parallel investigation
- /refactor (5 hours): Justified by simpler architecture, single agent
- /expand (5 hours): Justified by existing auto-analysis infrastructure
- /collapse (5 hours): Justified by similarity to /expand patterns
- /convert-docs (5 hours): Justified by dual-mode complexity

**Total**: 40 hours for 6 commands (6.7 hours average per command, appropriate for Tier 2 & 3 complexity)

### Documentation Updates

After Phase 7 completion:
- [ ] Update `.claude/docs/guides/execution-enforcement-migration-guide.md` with Phase 7 learnings
- [ ] Document multi-agent orchestration patterns in `.claude/templates/orchestration-patterns.md`
- [ ] Update command examples in `.claude/docs/command-examples.md` with verified enforcement patterns
- [ ] Record final metrics in `specs/plans/077_migration_tracking.csv`

---

## Conclusion

Phase 7 completes the command migration by upgrading the final 6 commands to execution enforcement standards. Each command has unique architectural considerations:

- **/orchestrate**: Most complex, 7-phase workflow with 6 agent dependencies
- **/debug**: Conditional parallel investigation with hypothesis testing
- **/refactor**: Read-only analysis with single agent delegation
- **/expand**: Auto-analysis with parallel expansion agents
- **/collapse**: Reverse of /expand with content preservation
- **/convert-docs**: Dual-mode execution with conditional agent delegation

The migration follows consistent patterns (Phase 0 role clarification, Patterns 1-4 enforcement, agent template updates) while adapting to each command's specific orchestration architecture. Upon completion, all 12 commands in the system will have uniform execution enforcement, achieving 100% file creation rates and predictable subagent delegation.

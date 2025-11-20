# Orchestration Best Practices Guide

**Path**: docs → guides → orchestration-best-practices.md

[Used by: /build, /plan, /research, /debug, all workflow orchestration commands]

Comprehensive guide for implementing production-quality orchestration workflows using the unified 7-phase framework. This guide synthesizes best practices from Spec 508 unified framework, achieving 92-97% context reduction and 40-60% time savings through proven architectural patterns.

## Overview

Orchestration commands coordinate multi-phase workflows through hierarchical agent delegation, achieving exceptional performance through five core techniques:

1. **Phase 0 Path Pre-Calculation**: 85% token reduction, 25x speedup (unified-location-detection.sh)
2. **Behavioral Injection**: 100% file creation reliability through explicit context injection
3. **Metadata-Only Passing**: 95-99% context reduction per artifact
4. **Wave-Based Parallel Execution**: 40-60% time savings through dependency analysis
5. **Fail-Fast Error Handling**: Immediate configuration error detection with diagnostic context

**Architectural Foundation**: All orchestration commands are built on the [Bash Block Execution Model](../concepts/bash-block-execution-model.md), which defines subprocess isolation constraints and validated patterns for cross-block state management

**Target Performance**:
- Context usage: <30% throughout 7-phase workflow
- File creation reliability: 100%
- Agent delegation rate: >90%
- Time savings (parallel execution): 40-60%

---

## Command Selection

### Maturity Status

**Use /build for implementation workflows** - it is the stable, tested, and recommended orchestration command for executing implementation plans.

| Command | Status | Recommendation |
|---------|--------|----------------|
| **/build** | **Production-Ready** | Stable, tested, recommended for implementation workflows. Use this by default. |
| **/plan** | **Production-Ready** | Stable, tested, recommended for research-driven planning. |
| **/research** | **Production-Ready** | Stable, tested, recommended for investigation. |
| **/debug** | **Production-Ready** | Stable, tested, recommended for issue investigation. |

**Note**: `/coordinate`, `/orchestrate`, and `/supervise` have been archived.

### Quick Decision Tree

```
Need orchestration workflow?
│
├─ Have an implementation plan? ──→ Use /build (recommended)
│
├─ Need to create a plan? ──→ Use /plan (recommended)
│
├─ Need deep investigation? ──→ Use /research
│
└─ Debugging an issue? ──→ Use /debug
```

### Feature Comparison Matrix

| Feature | /build | /plan | /research | /debug | Maturity Status |
|---------|--------|-------|-----------|--------|-----------------|
| **Wave-Based Parallel Execution** | ✓ (40-60% time savings) | ✗ | ✗ | ✗ | Production-ready |
| **Research Phase** | ✗ | ✓ | ✓ | ✓ | Production-ready |
| **Planning Phase** | ✗ | ✓ | ✗ | ✓ | Production-ready |
| **Implementation Phase** | ✓ | ✗ | ✗ | ✗ | Production-ready |
| **Testing Phase** | ✓ | ✗ | ✗ | ✗ | Production-ready |
| **Behavioral Injection Pattern** | ✓ | ✓ | ✓ | ✓ | All commands |
| **Fail-Fast Error Handling** | ✓ | ✓ | ✓ | ✓ | All commands |
| **Checkpoint Recovery** | ✓ | ✗ | ✗ | ✗ | Production-ready |
| **Context Management (<30%)** | ✓ | ✓ | ✓ | ✓ | All commands |

### Command-Specific Capabilities

#### /build (Production-Ready)
- **Focus**: Implementation phase execution
- **Unique Features**:
  - Wave-based parallel implementation (40-60% time savings)
  - Progressive plan structure support (Level 0/1/2)
  - Automatic test execution and debugging loops
  - Git commits for completed phases
- **Best For**: Executing existing implementation plans
- **Stability**: Stable, tested, recommended

#### /plan (Production-Ready)
- **Focus**: Research-driven planning
- **Unique Features**:
  - Research phase with specialist agents
  - Complexity-based depth adjustment (1-4)
  - Topic-based artifact organization
  - Cross-references research reports in plan metadata
- **Best For**: Creating implementation plans with research
- **Stability**: Stable, tested, recommended

#### /research (Production-Ready)
- **Focus**: Deep topic investigation
- **Unique Features**:
  - Hierarchical research with sub-supervisors
  - Parallel research agent coordination
  - Topic-based report organization
- **Best For**: Investigation without planning or implementation
- **Stability**: Stable, tested, recommended

#### /debug (Production-Ready)
- **Focus**: Issue investigation and diagnosis
- **Unique Features**:
  - Parallel hypothesis testing
  - Root cause analysis
  - Debug report generation
- **Best For**: Root cause analysis and bug fixing
- **Stability**: Stable, tested, recommended

### Use Case Recommendations

**Implementation**: Use **/build** when you have:
- An existing implementation plan to execute
- Multiple phases that need parallel execution
- Need for automatic testing and debugging

**Planning**: Use **/plan** when you need:
- Research-driven implementation planning
- Complexity analysis and phase organization
- Topic-based artifact organization

**Investigation**: Use **/research** when you need:
- Deep topic investigation
- Multiple research angles explored
- Research reports without planning

**Debugging**: Use **/debug** when you have:
- An issue to investigate
- Need for root cause analysis
- Parallel hypothesis testing

### Architectural Compatibility

All commands share architectural compatibility:

- **Behavioral Injection**: Direct agent invocation via Task tool with pre-calculated paths
- **Fail-Fast Error Handling**: Zero retries, comprehensive diagnostics, immediate termination
- **Shared Infrastructure**: Identical library dependencies and agent behavioral files
- **Topic-Based Organization**: Artifacts organized under specs/{NNN_topic}/

**Workflow**: Commands work together in sequence: `/plan` creates plans → `/build` executes them. Use `/research` for investigation-only workflows and `/debug` for issue diagnosis.

### Research Reference

For detailed comparative analysis, see:
- [Spec 513 Research Report](../../specs/513_compare_orchestrate_supervise_and_coordinate_in_or/reports/001_compare_orchestrate_supervise_and_coordinate_in_or/OVERVIEW.md)

---

## The Unified 7-Phase Framework

All orchestration commands follow this structure:

```
Phase 0: Location Detection
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (complexity evaluation)
  ↓
Phase 3: Implementation (wave-based parallel)
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debugging (conditional, parallel)
  ↓
Phase 6: Documentation
  ↓
Phase 7: Summary (artifact lifecycle)
```

**Context Budget** (21% total target):
- Phase 0: 500-1,000 tokens (4%)
- Phase 1: 600-1,200 tokens (6% - 2-4 agents × 200-300 tokens metadata each)
- Phase 2: 800-1,200 tokens (5%)
- Phase 3: 1,500-2,000 tokens (8%)
- Phase 4-7: 200-500 tokens each (2% each, conditional phases may be 0%)

---

## Phase 0: Path Pre-Calculation (MANDATORY)

### Purpose

Calculate all artifact paths **before** any agent invocation to enable explicit context injection and lazy directory creation. This eliminates agent-based location detection (75,600 tokens, 25.2s → 11,000 tokens, <1s).

### Performance Metrics

- **Token Reduction**: 85% (75,600 → 11,000 tokens)
- **Speed Improvement**: 25x faster (25.2s → <1s)
- **Directory Creation**: Lazy (only create when agents produce output)
- **Context Before Research**: Zero tokens (paths calculated, not created)

### Implementation Pattern

**Correct Pattern** (using unified-location-detection.sh):

```markdown
## Phase 0: Location Detection

**EXECUTE NOW**: USE the Bash tool to calculate paths:

\`\`\`bash
# Source unified location detection library
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Perform location detection
LOCATION_JSON=$(perform_location_detection "<workflow_description>")

# Extract paths
TOPIC_PATH=$(echo "$LOCATION_JSON" | jq -r '.topic_path')
REPORTS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.reports')
PLANS_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.plans')
SUMMARIES_DIR=$(echo "$LOCATION_JSON" | jq -r '.artifact_paths.summaries')

# MANDATORY VERIFICATION
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Location detection failed - topic directory not created"
  echo "DIAGNOSTIC: ls -la $(dirname "$TOPIC_PATH")"
  exit 1
fi

# Signal completion
echo "LOCATION_COMPLETE: $TOPIC_PATH"
echo "REPORTS_DIR: $REPORTS_DIR"
echo "PLANS_DIR: $PLANS_DIR"
\`\`\`

**WAIT for Bash tool output before proceeding to Phase 1.**
```

**Anti-Pattern** (agent-based detection):

```markdown
# WRONG - Do not invoke agent for location detection
**EXECUTE NOW**: USE the Task tool to detect locations:
- subagent_type: general-purpose
- prompt: "Determine the appropriate directory for this workflow..."

# This costs 75,600 tokens and takes 25 seconds
```

### Lazy Directory Creation

**Principle**: Only create artifact directories when agents successfully produce output.

```markdown
# After research agent completes
if [ -f "$REPORT_PATH" ]; then
  # Agent succeeded - directory was created automatically
  echo "Report created: $REPORT_PATH"
else
  # Agent failed - no directory pollution
  echo "ERROR: Research agent failed to create report"
  echo "DIAGNOSTIC: Check agent output for errors"
  exit 1
fi
```

### Integration Checklist

- [ ] Source `unified-location-detection.sh` before any path calculation
- [ ] Use `perform_location_detection()` instead of manual path logic
- [ ] Extract paths from JSON using `jq` or sed fallback
- [ ] Add MANDATORY VERIFICATION checkpoint after location detection
- [ ] Signal completion with `LOCATION_COMPLETE: <path>` format
- [ ] Do not create artifact directories manually

See [Phase 0 Optimization Guide](phase-0-optimization.md) for complete breakthrough analysis.

---

## Phase 1: Research (2-4 Parallel Agents)

### Purpose

Gather information through parallel specialized research agents, extracting only metadata (title + 50-word summary) to achieve 95-99% context reduction.

### Performance Metrics

- **Context Reduction**: 95-99% per report (5,000 tokens → 250 tokens)
- **Parallelization**: 2-4 agents simultaneously
- **Metadata Size**: 200-300 tokens per report
- **Total Phase Budget**: 600-1,200 tokens (2-4 agents)

### Implementation Pattern

#### Step 1: Calculate Report Paths

```markdown
## Phase 1: Research

**Research Topics Identified**:
1. OAuth 2.0 flow patterns → `001_oauth_flow_patterns.md`
2. Token refresh strategies → `002_token_refresh_strategies.md`
3. Security best practices → `003_security_best_practices.md`

**EXECUTE NOW**: USE the Bash tool to calculate report paths:

\`\`\`bash
# Calculate report paths
REPORT_1="${REPORTS_DIR}/001_oauth_flow_patterns.md"
REPORT_2="${REPORTS_DIR}/002_token_refresh_strategies.md"
REPORT_3="${REPORTS_DIR}/003_security_best_practices.md"

# Signal paths calculated
echo "REPORT_1_PATH: $REPORT_1"
echo "REPORT_2_PATH: $REPORT_2"
echo "REPORT_3_PATH: $REPORT_3"
\`\`\`

**WAIT for paths before agent invocation.**
```

#### Step 2: Invoke Agents with Behavioral Injection

```markdown
**EXECUTE NOW**: USE the Task tool to invoke parallel research agents:

**Agent 1 - OAuth Flow Patterns**:
- subagent_type: general-purpose
- model: sonnet
- prompt: |
    Research OAuth 2.0 flow patterns for Node.js APIs.

    **YOUR ROLE**: You are a research specialist. Your task is to investigate the topic and create a comprehensive report.

    **MANDATORY OUTPUT LOCATION**: You MUST create your report at this EXACT path:
    \`$REPORT_1\`

    **REQUIRED REPORT STRUCTURE**:
    - Title
    - Metadata (date, agent, topic, complexity)
    - Executive Summary (50 words max)
    - Findings (detailed research)
    - Recommendations

    **VERIFICATION CHECKPOINT**: After writing the report, you MUST verify:
    \`\`\`bash
    test -f "$REPORT_1" && echo "REPORT_CREATED: $REPORT_1" || echo "ERROR: Report not created at $REPORT_1"
    \`\`\`

**Agent 2 - Token Refresh Strategies**:
(identical structure, different topic, REPORT_2 path)

**Agent 3 - Security Best Practices**:
(identical structure, different topic, REPORT_3 path)

**WAIT for all agents to complete before proceeding.**
```

#### Step 3: Extract Metadata Only

```markdown
**EXECUTE NOW**: USE the Bash tool to extract metadata:

\`\`\`bash
# Source metadata extraction library
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"

# Extract metadata from all reports
METADATA_1=$(extract_report_metadata "$REPORT_1")
METADATA_2=$(extract_report_metadata "$REPORT_2")
METADATA_3=$(extract_report_metadata "$REPORT_3")

# Store metadata for Phase 2
echo "## Research Phase Complete"
echo ""
echo "**Report 1**: OAuth Flow Patterns"
echo "$METADATA_1"
echo ""
echo "**Report 2**: Token Refresh Strategies"
echo "$METADATA_2"
echo ""
echo "**Report 3**: Security Best Practices"
echo "$METADATA_3"
echo ""
echo "RESEARCH_COMPLETE"
\`\`\`

**FORWARD metadata to Phase 2 (do not include full report content).**
```

### Integration Checklist

- [ ] Calculate all report paths before invoking agents
- [ ] Use behavioral injection (explicit path in agent prompt)
- [ ] Add MANDATORY VERIFICATION checkpoints to agent prompts
- [ ] Invoke 2-4 agents in parallel (single Task tool call)
- [ ] Extract metadata using `metadata-extraction.sh`
- [ ] Forward metadata only (not full reports)
- [ ] Each report path must be unique (001_, 002_, 003_)

See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for complete pattern details.

---

## Phase 2: Planning

### Purpose

Create implementation plan using metadata from research reports, applying complexity evaluation and forward message pattern.

### Performance Metrics

- **Context Reduction**: Forward research metadata directly (no re-summarization)
- **Complexity Evaluation**: Automated threshold-based expansion recommendations
- **Total Phase Budget**: 800-1,200 tokens

### Implementation Pattern

#### Step 1: Invoke Plan Architect

```markdown
## Phase 2: Planning

**EXECUTE NOW**: USE the Task tool to create implementation plan:

- subagent_type: general-purpose
- model: sonnet
- prompt: |
    Create an implementation plan for OAuth 2.0 authentication.

    **YOUR ROLE**: You are a plan architect. Create a detailed implementation plan.

    **MANDATORY OUTPUT LOCATION**: You MUST create your plan at this EXACT path:
    \`${PLANS_DIR}/001_oauth_implementation_plan.md\`

    **RESEARCH CONTEXT** (metadata only):
    {FORWARD metadata from Phase 1 WITHOUT modification or summarization}

    **REQUIRED PLAN STRUCTURE**:
    - Metadata (date, feature, scope, estimated phases/hours, complexity score)
    - Overview
    - Research Summary (synthesize research metadata)
    - Success Criteria
    - Technical Design
    - Implementation Phases (with complexity score if >8 or >10 tasks)
    - Testing Strategy
    - Documentation Requirements
    - Dependencies
    - Risk Mitigation

    **COMPLEXITY SCORING**: Calculate complexity score using complexity-utils.sh patterns:
    - Task count × 1.0
    - File references × 0.5
    - External dependencies × 2.0
    - Integration points × 1.5

    **VERIFICATION CHECKPOINT**: After writing the plan, you MUST verify:
    \`\`\`bash
    test -f "${PLANS_DIR}/001_oauth_implementation_plan.md" && echo "PLAN_CREATED" || echo "ERROR: Plan not created"
    \`\`\`

**WAIT for plan agent to complete.**
```

#### Step 2: Evaluate Complexity

```markdown
**EXECUTE NOW**: USE the Bash tool to evaluate plan complexity:

\`\`\`bash
# Source complexity utilities
source "${CLAUDE_CONFIG}/.claude/lib/plan/complexity-utils.sh"

# Analyze plan
PLAN_PATH="${PLANS_DIR}/001_oauth_implementation_plan.md"
COMPLEXITY=$(analyze_plan_complexity "$PLAN_PATH")
PHASE_COUNT=$(get_phase_count "$PLAN_PATH")

echo "Plan complexity: $COMPLEXITY"
echo "Phase count: $PHASE_COUNT"

# Check for expansion recommendation
if (( $(echo "$COMPLEXITY > 8.0" | bc -l) )); then
  echo "RECOMMENDATION: Complexity score >8, consider phase expansion"
fi

echo "PLANNING_COMPLETE: $PLAN_PATH"
\`\`\`
```

### Forward Message Pattern

**Principle**: Pass subagent responses directly without re-summarization.

```markdown
# Correct: Forward metadata as-is
**RESEARCH CONTEXT** (metadata only):
{PASTE metadata exactly as extracted in Phase 1}

# WRONG: Re-summarize
**RESEARCH CONTEXT**:
Based on three research reports, the findings suggest... (DO NOT DO THIS)
```

### Integration Checklist

- [ ] Calculate plan path before invoking agent
- [ ] Use behavioral injection (explicit path in prompt)
- [ ] Forward research metadata directly (no summarization)
- [ ] Add MANDATORY VERIFICATION checkpoint
- [ ] Evaluate complexity using `complexity-utils.sh`
- [ ] Recommend expansion if complexity >8 or >10 tasks

See [Forward Message Pattern](../concepts/patterns/forward-message.md) for complete pattern details.

---

## Phase 3: Implementation (Wave-Based Parallel)

### Purpose

Execute implementation plan using wave-based parallel execution for independent phases, achieving 40-60% time savings.

### Performance Metrics

- **Time Savings**: 40-60% through parallel execution
- **Context Reduction**: 96% per-phase pruning after completion
- **Total Phase Budget**: 1,500-2,000 tokens (increases with plan complexity)

### Implementation Pattern

#### Step 1: Analyze Phase Dependencies

```markdown
## Phase 3: Implementation

**EXECUTE NOW**: USE the Bash tool to analyze dependencies:

\`\`\`bash
# Source dependency analyzer
source "${CLAUDE_CONFIG}/.claude/lib/util/dependency-analyzer.sh"

# Analyze plan dependencies
PLAN_PATH="${PLANS_DIR}/001_oauth_implementation_plan.md"
WAVES=$(analyze_dependencies_kahn "$PLAN_PATH")

echo "Dependency analysis complete:"
echo "$WAVES"

# Expected output:
# Wave 1: [1, 2] (phases 1 and 2 can run in parallel)
# Wave 2: [3] (phase 3 depends on 1, 2)
# Wave 3: [4, 5] (phases 4 and 5 can run in parallel, depend on 3)
\`\`\`
```

#### Step 2: Execute Waves Sequentially

```markdown
**EXECUTE NOW**: Implement Wave 1 (Phases 1-2 in parallel):

**EXECUTE NOW**: USE the Task tool to invoke implementation agents:

**Agent for Phase 1**:
- subagent_type: general-purpose
- model: sonnet
- prompt: |
    Implement Phase 1 of the OAuth implementation plan.

    **YOUR ROLE**: You are an implementation specialist.

    **PLAN LOCATION**: Read the plan from: \`$PLAN_PATH\`

    **PHASE TO IMPLEMENT**: Phase 1 (read details from plan file)

    **WORKING DIRECTORY**: /path/to/project

    **INSTRUCTIONS**:
    1. Read the plan file to understand Phase 1 requirements
    2. Implement all tasks in Phase 1
    3. Mark tasks complete in plan using Edit tool
    4. Run tests if specified
    5. Signal completion: \`PHASE_1_COMPLETE\`

**Agent for Phase 2**:
(identical structure, different phase number)

**WAIT for both Phase 1 and Phase 2 to complete before starting Wave 2.**
```

#### Step 3: Prune Completed Phase Context

```markdown
**EXECUTE NOW**: USE the Bash tool to prune completed context:

\`\`\`bash
# Source context pruning library
# Context pruning library not yet implemented

# Prune Phase 1 and Phase 2 context (aggressive policy)
prune_phase_output "Wave 1 (Phases 1-2)" "aggressive"

# Metadata retained: Phase 1 COMPLETE, Phase 2 COMPLETE
# Full implementation details pruned (96% reduction)

echo "Wave 1 complete, context pruned"
\`\`\`

**Continue to Wave 2...**
```

### Wave-Based Execution Advantages

| Approach | Execution Time | Context Usage | Dependencies |
|----------|----------------|---------------|--------------|
| **Sequential** | 100% (baseline) | Moderate | Simple |
| **Wave-Based** | 40-60% of baseline | Low (pruned per wave) | Advanced |

**Example**: 5-phase plan with dependencies [1] → [2, 3] → [4, 5]
- Sequential: Phase 1 (5min) → Phase 2 (5min) → Phase 3 (5min) → Phase 4 (5min) → Phase 5 (5min) = **25 minutes**
- Wave-Based: Wave 1 [1] (5min) → Wave 2 [2,3] (5min parallel) → Wave 3 [4,5] (5min parallel) = **15 minutes** (40% savings)

### Integration Checklist

- [ ] Source `dependency-analyzer.sh` before phase execution
- [ ] Use `analyze_dependencies_kahn()` for topological sort
- [ ] Execute phases within same wave in parallel
- [ ] Wait for wave completion before starting next wave
- [ ] Prune completed wave context using `context-pruning.sh`
- [ ] Track wave completion in orchestrator context

See [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) for complete pattern details.

---

## Phase 4: Testing (Conditional)

### Purpose

Run project-specific tests if workflow scope includes implementation or debugging.

### Performance Metrics

- **Conditional Execution**: Skip if scope is "research-only" or "research-and-plan"
- **Total Phase Budget**: 200-500 tokens (or 0 if skipped)

### Implementation Pattern

```markdown
## Phase 4: Testing

**EXECUTE NOW**: USE the Bash tool to check workflow scope:

\`\`\`bash
# Source workflow detection library
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

# Determine if testing phase should run
WORKFLOW_DESCRIPTION="<original workflow description>"
SHOULD_RUN=$(should_run_phase "$WORKFLOW_DESCRIPTION" "testing")

if [ "$SHOULD_RUN" = "true" ]; then
  echo "Testing phase required for this workflow"
else
  echo "Testing phase skipped (scope: research-only or research-and-plan)"
  echo "TESTING_SKIPPED"
  exit 0
fi
\`\`\`

**If testing required**:

**EXECUTE NOW**: USE the Bash tool to run tests:

\`\`\`bash
# Discover test commands from CLAUDE.md
source "${CLAUDE_CONFIG}/.claude/lib/standards-discovery.sh"
TEST_COMMAND=$(get_test_command ".")

# Run tests
$TEST_COMMAND

if [ $? -eq 0 ]; then
  echo "TESTS_PASSED"
else
  echo "TESTS_FAILED"
  echo "TRIGGER_DEBUGGING: true"
  exit 1
fi
\`\`\`
```

### Integration Checklist

- [ ] Source `workflow-detection.sh` before testing
- [ ] Use `should_run_phase()` to check if testing required
- [ ] Skip phase cleanly if scope doesn't require testing
- [ ] Trigger debugging phase if tests fail
- [ ] Signal completion or skip status

See [Workflow Scope Detection Pattern](../concepts/patterns/workflow-scope-detection.md) for complete scope detection logic.

---

## Phase 5: Debugging (Conditional, Parallel Investigations)

### Purpose

Investigate and fix failures from testing phase through parallel hypothesis testing.

### Performance Metrics

- **Conditional Execution**: Only run if Phase 4 tests failed
- **Parallelization**: 2-3 investigators per failure category
- **Total Phase Budget**: 600-1,200 tokens (or 0 if skipped)

### Implementation Pattern

```markdown
## Phase 5: Debugging

**Condition**: Phase 4 tests failed

**EXECUTE NOW**: USE the Bash tool to categorize failures:

\`\`\`bash
# Analyze test output
TEST_OUTPUT="<captured from Phase 4>"

# Categorize failures (e.g., auth errors, database errors, API errors)
CATEGORIES=$(echo "$TEST_OUTPUT" | grep "FAILED" | awk '{print $2}' | sort -u)

echo "Failure categories identified:"
echo "$CATEGORIES"
\`\`\`

**EXECUTE NOW**: USE the Task tool to invoke parallel debugging agents:

**Agent 1 - Auth Failure Investigation**:
- subagent_type: general-purpose
- model: sonnet
- prompt: |
    Investigate authentication failures in test suite.

    **TEST OUTPUT**: {PASTE relevant test failures}

    **YOUR ROLE**: Debug analyst. Investigate root causes.

    **MANDATORY OUTPUT LOCATION**: \`${DEBUG_DIR}/001_auth_failure_analysis.md\`

    **DELIVERABLES**:
    1. Root cause analysis
    2. Proposed fix
    3. Test verification steps

    **VERIFICATION**: \`test -f "${DEBUG_DIR}/001_auth_failure_analysis.md" && echo "DEBUG_REPORT_CREATED"\`

**Agent 2 - Database Failure Investigation**:
(identical structure, different category)

**WAIT for all debugging agents to complete.**

**Then**: Apply fixes and re-run tests.
```

### Integration Checklist

- [ ] Only run if Phase 4 indicated failures
- [ ] Categorize failures for targeted investigation
- [ ] Invoke 2-3 parallel debug analysts
- [ ] Create debug reports in `debug/` artifact directory
- [ ] Apply fixes based on debug analysis
- [ ] Re-run tests to verify fixes

See [Hierarchical Supervision Pattern](../concepts/patterns/hierarchical-supervision.md) for multi-level debugging coordination.

---

## Phase 6: Documentation

### Purpose

Create implementation summary linking plan and research reports.

### Performance Metrics

- **Total Phase Budget**: 200-400 tokens

### Implementation Pattern

```markdown
## Phase 6: Documentation

**EXECUTE NOW**: USE the Task tool to create summary:

- subagent_type: general-purpose
- model: haiku
- prompt: |
    Create implementation summary for OAuth 2.0 authentication.

    **YOUR ROLE**: Documentation specialist.

    **MANDATORY OUTPUT LOCATION**: \`${SUMMARIES_DIR}/001_oauth_implementation_summary.md\`

    **CONTEXT**:
    - Plan: \`$PLAN_PATH\`
    - Reports: {LIST report paths}
    - Implementation complete: {DATE}

    **REQUIRED SUMMARY STRUCTURE**:
    - Metadata (date completed, plan link, phases completed)
    - Implementation Overview
    - Key Changes
    - Test Results
    - Lessons Learned

    **VERIFICATION**: \`test -f "${SUMMARIES_DIR}/001_oauth_implementation_summary.md" && echo "SUMMARY_CREATED"\`

**WAIT for summary creation.**
```

### Integration Checklist

- [ ] Calculate summary path before invoking agent
- [ ] Include link to plan in metadata (creates traceability chain: Summary → Plan → Reports)
- [ ] Document test results from Phase 4
- [ ] Capture lessons learned for future workflows

---

## Phase 7: Summary (Artifact Lifecycle Tracking)

### Purpose

Update research reports with implementation notes and finalize artifact lifecycle.

### Performance Metrics

- **Total Phase Budget**: 200-300 tokens

### Implementation Pattern

```markdown
## Phase 7: Finalization

**EXECUTE NOW**: USE the Bash tool to update reports:

\`\`\`bash
# Add implementation notes to research reports
for REPORT in "$REPORT_1" "$REPORT_2" "$REPORT_3"; do
  if [ -f "$REPORT" ]; then
    # Append implementation note
    echo "" >> "$REPORT"
    echo "## Implementation Status" >> "$REPORT"
    echo "" >> "$REPORT"
    echo "**Implemented**: $(date +%Y-%m-%d)" >> "$REPORT"
    echo "**Plan**: [001_oauth_implementation_plan.md](../plans/001_oauth_implementation_plan.md)" >> "$REPORT"
    echo "**Summary**: [001_oauth_implementation_summary.md](../summaries/001_oauth_implementation_summary.md)" >> "$REPORT"
  fi
done

echo "WORKFLOW_COMPLETE"
\`\`\`
```

### Integration Checklist

- [ ] Update all research reports with implementation status
- [ ] Cross-reference plan and summary
- [ ] Signal workflow completion
- [ ] Archive temporary files if applicable

---

## Output Formatting and Context Management

### Purpose

Orchestration commands produce clean, concise output that minimizes context consumption while maintaining full diagnostic capability on failures. The /build command implements a comprehensive formatting architecture achieving 50-60% context reduction through library silence, concise verification, standardized progress markers, and simplified completion summaries.

### Architecture: Libraries Calculate, Commands Communicate

**Principle**: Libraries perform logic silently; commands control all user-facing output.

This separation of concerns enables:
- Consistent formatting across all orchestration commands
- Individual commands customize output without library interference
- Library code focuses on data transformation, not presentation
- Token savings through elimination of redundant library output

**Implementation**:
```bash
# Library code (workflow-initialization.sh) - SILENT
detect_workflow_scope() {
  # Performs scope detection logic
  # NO echo statements except errors to stderr
  echo "$WORKFLOW_SCOPE"  # Return value only
}

# Command code (coordinate.md) - COMMUNICATES
WORKFLOW_SCOPE=$(detect_workflow_scope "$WORKFLOW_DESC")
echo "Workflow scope: $WORKFLOW_SCOPE"  # User-facing output
```

**Metrics**:
- Library output reduced: 30+ lines → 0 lines (100% reduction)
- User-facing output: Controlled entirely by command
- Context savings: ~400 tokens per workflow

### Workflow Scope Detection Format

**Purpose**: Display which phases will execute upfront for workflow transparency.

**Format**: 8-12 line phase execution report with ✓/✗ indicators

```
Workflow scope: research-and-plan

Phases to execute:
  ✓ Phase 0: Location detection
  ✓ Phase 1: Research (2-4 parallel agents)
  ✓ Phase 2: Planning
  ✗ Phase 3: Implementation (skipped)
  ✗ Phase 4: Testing (skipped)
  ✗ Phase 5: Debugging (skipped)
  ✗ Phase 6: Documentation (skipped)
  ✓ Phase 7: Summary
```

**Benefits**:
- Users confirm correct workflow scope before execution
- Clear expectation of which phases run vs skip
- Eliminates surprise when phases are skipped
- Pattern adoptable by other orchestration commands

**Metrics**:
- Previous verbose output: 71 lines → 10 lines (86% reduction)
- Context savings: ~800 tokens per workflow
- Token reduction from library silence: additional ~400 tokens

**Implementation Pattern**:
```bash
# After workflow scope detection
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "Phases to execute:"
    echo "  ✓ Phase 0: Location detection"
    echo "  ✓ Phase 1: Research (2-4 parallel agents)"
    echo "  ✗ Phase 2: Planning (skipped)"
    # ... remaining phases marked ✗
    ;;
  research-and-plan)
    echo "Phases to execute:"
    echo "  ✓ Phase 0: Location detection"
    echo "  ✓ Phase 1: Research (2-4 parallel agents)"
    echo "  ✓ Phase 2: Planning"
    echo "  ✗ Phase 3: Implementation (skipped)"
    # ... remaining phases marked ✗
    ;;
  # ... other workflow types
esac
```

See [Workflow Scope Detection Pattern](../concepts/patterns/workflow-scope-detection.md) for complete scope detection logic and conditional phase execution.

### Concise Verification Pattern

**Purpose**: Display verification status compactly (1-2 lines on success), with full diagnostics on failure.

**Philosophy**: Fail-fast with diagnostics, no fallbacks. Target >95% success rate through proper agent invocation.

**Format**:
```bash
# Success (1-2 lines):
Verifying research reports (3): ✓✓✓ (all passed)

# Failure (multi-line diagnostics):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VERIFICATION FAILED: Research agent did not create report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**What failed**: Report file creation
**Expected**: Report should exist at /path/to/report.md
**Diagnostic**: Check agent output above for errors
**Context**: Required for metadata extraction in Phase 1
**Action**: Review agent prompt for path injection, verify write permissions
```

**Implementation Pattern**:
```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ]; then
    echo -n "✓"  # Silent success (no newline)
  else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "VERIFICATION FAILED: $item_desc not created"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "**What failed**: $item_desc file creation"
    echo "**Expected**: File should exist at $file_path"
    echo "**Diagnostic**: Check agent output above for errors"
    echo "**Context**: Required for $phase_name"
    echo "**Action**: Review agent prompt, verify write permissions"
    echo ""
    return 1
  fi
}

# Usage in Phase 1 (research reports verification)
echo -n "Verifying research reports ($REPORT_COUNT): "
for report in "${REPORT_PATHS[@]}"; do
  verify_file_created "$report" "Research report" "metadata extraction"
done
echo " (all passed)"
```

**Metrics**:
- Success output: 50+ lines → 1-2 lines per checkpoint (≥90% reduction)
- Token reduction: ≥3,150 tokens saved per workflow
- File creation reliability: >95% through proper agent invocation
- Fail-fast exposes root causes immediately (no fallback masking)

See [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) for complete fail-fast philosophy and diagnostic standards.

### Standardized Progress Markers

**Purpose**: Provide parseable progress tracking for external monitoring tools.

**Format**: `PROGRESS: [Phase N] - [description]`

**Implementation**:
```bash
emit_progress() {
  local phase="$1"
  local message="$2"
  echo "PROGRESS: [Phase $phase] - $message"
}

# Usage
emit_progress "0" "Location detection complete"
emit_progress "1" "Research complete: verified 3/3 reports"
emit_progress "2" "Planning complete: 5-phase plan created"
emit_progress "3" "Implementation complete: Wave 1 finished"
```

**Benefits**:
- Consistent format across all phase transitions
- External tools can parse progress (`grep "PROGRESS:"`)
- Integration with monitoring dashboards
- Parseable by awk/sed for progress tracking scripts

**Parsing Example**:
```bash
# Extract current phase
grep "PROGRESS:" workflow.log | tail -1 | sed 's/PROGRESS: \[Phase \([0-9]\)\].*/\1/'

# Monitor progress in real-time
tail -f workflow.log | grep --line-buffered "PROGRESS:"
```

**Metrics**:
- Replaced box-drawing headers throughout (7 phase headers)
- Token reduction: ~200 tokens (box-drawing overhead eliminated)
- Consistent format enables external parsing

**Consolidation**: Progress marker format and usage documented here as single authoritative reference. Other files cross-reference this section rather than duplicating details.

### Simplified Completion Summaries

**Purpose**: Display essential workflow completion information compactly.

**Format**: 8-line summary showing workflow scope, artifact counts, and next steps

```
Workflow complete: research-and-plan

Artifacts:
  ✓ 3 research reports
  ✓ 1 implementation plan (5 phases, 8-12 hours estimated)

Next: /implement specs/042_auth/plans/001_oauth_implementation.md
```

**Previous Format** (53 lines):
- Workflow type and phases executed (5 lines)
- Artifacts created with file sizes (15 lines)
- Plan overview with metadata (8 lines)
- Key findings summary (20+ lines)
- Next steps (5 lines)

**Metrics**:
- Summary reduced: 53 lines → 8 lines (85% reduction)
- Token reduction: ~700 tokens per workflow (90% reduction)
- Essential information preserved (workflow scope, artifact counts, next action)
- Detailed information available in artifact files themselves

**Implementation Pattern**:
```bash
# Simplified completion summary
echo ""
echo "Workflow complete: $WORKFLOW_SCOPE"
echo ""
echo "Artifacts:"
echo "  ✓ $SUCCESSFUL_REPORT_COUNT research reports"
if [ -n "$PLAN_PATH" ] && [ -f "$PLAN_PATH" ]; then
  PHASE_COUNT=$(grep -c "^### Phase [0-9]" "$PLAN_PATH" || echo "0")
  PLAN_EST=$(grep "Estimated Total Time:" "$PLAN_PATH" | head -1 | cut -d: -f2 | xargs || echo "unknown")
  echo "  ✓ 1 implementation plan ($PHASE_COUNT phases, $PLAN_EST estimated)"
fi
echo ""
echo "Next: /implement $PLAN_PATH"
echo ""
```

### Context Reduction Metrics

**Overall Performance**: 50-60% context reduction through combined formatting improvements

| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| **Library Output** | 30+ lines | 0 lines | 100% (~400 tokens) |
| **Workflow Scope** | 71 lines | 10 lines | 86% (~800 tokens) |
| **Verification** | 50+ lines/checkpoint | 1-2 lines/checkpoint | ≥90% (≥3,150 tokens) |
| **Progress Markers** | Box-drawing headers | Standardized emit_progress | ~200 tokens |
| **Completion Summary** | 53 lines | 8 lines | 85% (~700 tokens) |
| **Total Workflow** | Baseline | Reduced | **50-60% (~5,250 tokens)** |

**Performance Impact**:
- Faster command execution (less output processing)
- Clearer user experience (scan completion at a glance)
- Lower context consumption (more budget for agent work)
- Maintained diagnostic capability (full output on failures)

### Integration Checklist

When implementing formatting improvements in orchestration commands:

- [ ] Libraries are silent (no echo except errors to stderr)
- [ ] Commands control all user-facing output
- [ ] Workflow scope displays phase execution plan upfront (✓/✗ indicators)
- [ ] Verification uses concise format (1-2 lines success, multi-line failure diagnostics)
- [ ] Progress markers use standardized `emit_progress()` format
- [ ] Completion summaries are simplified (≤10 lines, essential info only)
- [ ] All formatting changes are display-only (no functional modifications)
- [ ] Context reduction measured and documented

### Related Patterns and Guides

- [Workflow Scope Detection Pattern](../concepts/patterns/workflow-scope-detection.md) - Complete scope detection logic
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Fail-fast philosophy and diagnostics
- [Context Management Pattern](../concepts/patterns/context-management.md) - Pruning and reduction techniques
- [Context Budget Management Tutorial](../workflows/context-budget-management.md) - Layered context architecture

---

## Error Handling: Fail-Fast with 5-Component Diagnostics

### Purpose

Detect configuration errors immediately with actionable diagnostic context.

### 5-Component Error Message Standard

Every error message must include:

1. **What Failed**: Specific operation (e.g., "unified-location-detection.sh library load failed")
2. **Expected State**: What should have happened (e.g., "Library should exist at ${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh")
3. **Diagnostic Commands**: Exact commands to investigate (e.g., `ls -la ${CLAUDE_CONFIG}/.claude/lib/`)
4. **Context**: Why this is required (e.g., "Required for Phase 0 path calculation")
5. **Action**: Steps to resolve (e.g., "Verify library installation: git status .claude/lib/")

### Fail-Fast vs Verification Checkpoints

| Situation | Approach | Rationale |
|-----------|----------|-----------|
| **Bootstrap Library Loading** | Fail-Fast | Configuration error - cannot proceed without library |
| **File Creation (Agent Output)** | Verification + Fallback | Transient error - agent may retry or user may intervene |
| **Directory Creation** | Verification + Fallback | Transient error - can retry or create manually |
| **Function Availability** | Fail-Fast | Configuration error - indicates library not sourced |

### Example: Fail-Fast Error

```bash
# Bootstrap library loading
if ! source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ERROR: Failed to load unified-location-detection.sh library"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Library sourcing"
  echo "**Expected**: Library should exist at ${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"
  echo "**Diagnostic**: Run: ls -la ${CLAUDE_CONFIG}/.claude/lib/"
  echo "**Context**: Required for Phase 0 path pre-calculation (85% token reduction)"
  echo "**Action**: Verify installation: git status .claude/lib/ | grep unified-location-detection"
  echo ""
  exit 1
fi
```

### Example: Verification Checkpoint

```bash
# File creation verification (agent output)
if [ ! -f "$REPORT_PATH" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "VERIFICATION FAILED: Research agent did not create report"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "**What failed**: Report file creation"
  echo "**Expected**: Report should exist at $REPORT_PATH"
  echo "**Diagnostic**: Check agent output above for errors"
  echo "**Context**: Required for metadata extraction in Phase 1"
  echo "**Action**: Review agent prompt for path injection, verify write permissions"
  echo ""
  # DO NOT exit - allow retry or user intervention
fi
```

### Integration Checklist

- [ ] All bootstrap operations use fail-fast (library loading, function checks)
- [ ] All agent outputs use verification checkpoints (file creation)
- [ ] Every error includes all 5 components
- [ ] Diagnostic commands are copy-paste ready
- [ ] Context explains why operation is required

See [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) for complete distinction.

---

## Context Budget Management

### Target: 21% Total Context Usage

| Layer | Purpose | Budget | Percentage |
|-------|---------|--------|------------|
| **Layer 1: Permanent** | Command prompt, standards | 500-1,000 tokens | 4% |
| **Layer 2: Phase-Scoped** | Current phase state, wave tracking | 2,000-4,000 tokens | 12% |
| **Layer 3: Metadata** | Report/plan summaries (200-300 each) | 600-1,200 tokens | 6% |
| **Layer 4: Transient** | Full agent outputs (pruned immediately) | 0 tokens | 0% |
| **Total** | Full 7-phase workflow | 3,100-6,200 tokens | 21% |

### Pruning Policies

**Aggressive** (recommended for orchestration):
- Prune full agent outputs immediately after metadata extraction
- Keep only metadata (title + 50-word summary)
- Prune completed wave context before starting next wave
- Retain only phase completion status

**Moderate**:
- Keep agent outputs until phase completion
- Prune after phase verified complete
- Retain summary statistics

**Minimal**:
- Keep all outputs for debugging
- Only prune after workflow completion

### Example: 6-Phase Workflow Budget

```
Phase 0: 500 tokens (location detection JSON)
Phase 1: 900 tokens (3 research reports × 300 tokens metadata each)
Phase 2: 800 tokens (plan metadata + forward message)
Phase 3: 2,000 tokens (wave tracking, current implementation state)
Phase 4: 400 tokens (test results summary)
Phase 6: 300 tokens (summary metadata)
───────────────────────────────────────────────────
Total: 4,900 tokens = 19.6% of 25,000 token budget
```

See [Context Budget Management Tutorial](../workflows/context-budget-management.md) for actionable budget allocation strategies.

---

## Library Integration Checklist

### 8 Required Libraries for Full Orchestration

All orchestration commands must source these libraries:

```bash
# Phase 0: Location Detection
source "${CLAUDE_CONFIG}/.claude/lib/core/unified-location-detection.sh"

# Phase 1: Research
source "${CLAUDE_CONFIG}/.claude/lib/workflow/metadata-extraction.sh"

# Phase 2: Planning
source "${CLAUDE_CONFIG}/.claude/lib/plan/complexity-utils.sh"

# Phase 3: Implementation
source "${CLAUDE_CONFIG}/.claude/lib/util/dependency-analyzer.sh"
# Context pruning library not yet implemented

# Phase 4: Testing
source "${CLAUDE_CONFIG}/.claude/lib/workflow/workflow-detection.sh"

# Phase 5: Debugging
source "${CLAUDE_CONFIG}/.claude/lib/core/error-handling.sh"

# All Phases: Checkpoint Management
source "${CLAUDE_CONFIG}/.claude/lib/workflow/checkpoint-utils.sh"
```

### Verification Template

```bash
# Verify all required functions available
REQUIRED_FUNCTIONS=(
  "perform_location_detection"
  "extract_report_metadata"
  "analyze_plan_complexity"
  "analyze_dependencies_kahn"
  "prune_phase_output"
  "should_run_phase"
  "log_error_diagnostic"
  "save_checkpoint"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
  if ! declare -f "$func" > /dev/null; then
    echo "ERROR: Required function '$func' not available"
    echo "DIAGNOSTIC: Check library sourcing in command bootstrap"
    exit 1
  fi
done

echo "All required libraries verified"
```

See [Library API Reference](../reference/library-api/overview.md) for complete function signatures.

---

## Performance Metrics Reference

### Quantified Benefits

| Technique | Metric | Before | After | Improvement |
|-----------|--------|--------|-------|-------------|
| **Phase 0 Optimization** | Tokens | 75,600 | 11,000 | 85% reduction |
| **Phase 0 Optimization** | Speed | 25.2s | <1s | 25x faster |
| **Metadata Extraction** | Tokens/report | 5,000 | 250 | 95% reduction |
| **Wave-Based Execution** | Time | 25 min | 10-15 min | 40-60% savings |
| **Behavioral Injection** | File creation rate | Variable | 100% | Reliability |
| **Context Pruning** | Tokens/phase | 5,000 | 200 | 96% reduction |
| **Hierarchical Supervision** | Tokens (10 agents) | 50,000 | 4,500 | 91% reduction |

### Real-World Case Studies

**Plan 080** (10-agent research workflow):
- Before hierarchical supervision: 50,000 tokens (impossible)
- After hierarchical supervision: 4,500 tokens (91% reduction)
- Enabled 10 parallel research topics vs baseline 4

**Spec 438** (/supervise agent delegation fix):
- Before imperative pattern: 0% delegation rate (7 YAML blocks failed)
- After imperative pattern: >90% delegation rate
- 100% file creation reliability achieved

**Spec 495** (/coordinate and /research fixes):
- Before imperative pattern: 0% delegation (9 invocations failed)
- After imperative pattern: >90% delegation
- Eliminated 100% of fallback bootstrap pollution

**Spec 057** (fail-fast error handling):
- Before: Bootstrap fallbacks hid configuration errors
- After: Fail-fast exposed errors immediately with diagnostics
- Removed 32 lines of misleading fallback logic

See [Orchestration Performance Metrics Reference](../reference/workflows/orchestration-reference.md#performance-metrics) (if created) for comprehensive metrics catalog.

---

## Integration Priorities

### When Creating New Orchestration Commands

**Priority 1** (MANDATORY):
1. Phase 0 path pre-calculation (unified-location-detection.sh)
2. Behavioral injection pattern (explicit paths in agent prompts)
3. Verification checkpoints (mandatory file creation checks)
4. Fail-fast error handling (5-component diagnostics)

**Priority 2** (RECOMMENDED):
1. Metadata-only passing (metadata-extraction.sh)
2. Forward message pattern (no re-summarization)
3. Context pruning (prune after phase completion)
4. Workflow scope detection (conditional phase execution)

**Priority 3** (OPTIONAL for advanced workflows):
1. Wave-based parallel execution (dependency-analyzer.sh)
2. Hierarchical supervision (for 5+ agents)
3. Checkpoint recovery (resumable workflows)

### Verification Checklist

Before releasing orchestration command:

- [ ] Phase 0 uses unified-location-detection.sh (not agent-based detection)
- [ ] All agent invocations use behavioral injection (explicit paths)
- [ ] All file creation has MANDATORY VERIFICATION checkpoints
- [ ] All errors use 5-component diagnostic format
- [ ] Bootstrap uses fail-fast (library loading errors exit immediately)
- [ ] Research phase extracts metadata only (not full reports)
- [ ] Planning phase forwards metadata directly (no re-summarization)
- [ ] Implementation phase prunes context after each wave
- [ ] Testing phase checks workflow scope before running
- [ ] All 8 required libraries sourced and verified

---

## Common Anti-Patterns

### Anti-Pattern 1: Agent-Based Location Detection

**Problem**: Invoking agent for directory discovery costs 75,600 tokens and 25 seconds.

**Correct**:
```bash
LOCATION_JSON=$(perform_location_detection "$WORKFLOW_DESC")
```

**Wrong**:
```yaml
# YAML block invoking agent for location detection
```

### Anti-Pattern 2: Documentation-Only YAML Blocks

**Problem**: YAML wrapped in markdown code fences never executes (0% delegation rate).

**Correct**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research agent:
- subagent_type: general-purpose
- prompt: "Research topic..."
```

**Wrong**:
```markdown
```yaml
# Research agent invocation
task:
  subagent_type: general-purpose
  prompt: "Research topic..."
\`\`\`
```

### Anti-Pattern 3: Re-Summarizing Subagent Output

**Problem**: Re-summarization wastes tokens and introduces errors.

**Correct**:
```markdown
**RESEARCH CONTEXT**: {PASTE metadata exactly as extracted}
```

**Wrong**:
```markdown
Based on the research, I found that... (re-summarization)
```

### Anti-Pattern 4: Bootstrap Fallbacks

**Problem**: Fallback logic hides configuration errors instead of exposing them.

**Correct**:
```bash
if ! source library.sh; then
  echo "ERROR: Library not found"
  exit 1
fi
```

**Wrong**:
```bash
if ! source library.sh 2>/dev/null; then
  # Fallback: try alternate path (HIDES ERROR)
  source /alternate/path/library.sh 2>/dev/null || true
fi
```

See [Behavioral Injection Pattern - Anti-Patterns](../concepts/patterns/behavioral-injection.md#anti-pattern-documentation) for complete case studies.

---

## Cross-References

### Related Patterns
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Explicit context injection
- [Metadata Extraction Pattern](../concepts/patterns/metadata-extraction.md) - 95% context reduction
- [Forward Message Pattern](../concepts/patterns/forward-message.md) - No re-summarization
- [Parallel Execution Pattern](../concepts/patterns/parallel-execution.md) - Wave-based implementation
- [Verification and Fallback Pattern](../concepts/patterns/verification-fallback.md) - Fail-fast vs verification
- [Workflow Scope Detection Pattern](../concepts/patterns/workflow-scope-detection.md) - Conditional phases

### Related Guides
- [Phase 0 Optimization Guide](../patterns/phase-0-optimization.md) - Complete breakthrough analysis
- [Command Development Guide](../development/command-development/command-development-fundamentals.md) - Creating orchestration commands
- [Agent Development Guide](../development/agent-development/agent-development-fundamentals.md) - Creating specialized agents
- [Orchestration Troubleshooting Guide](orchestration-troubleshooting.md) - Debugging delegation issues

### Related Workflows
- [Context Budget Management Tutorial](../workflows/context-budget-management.md) - Layered context architecture

### Related Reference
- [Orchestration Reference](../reference/workflows/orchestration-reference.md) - Command syntax and comparison
- [Library API Reference](../reference/library-api/overview.md) - Complete function catalog
- [Command Architecture Standards](../reference/architecture/overview.md) - Standards compliance

---

## Changelog

### 2025-10-28: Initial Creation
- Synthesized from Spec 508 unified framework
- 7-phase workflow documented with performance metrics
- All 8 required libraries integrated
- Context budget management included
- 5-component error message standard defined
- Real-world case studies added (Plans 080, Specs 438/495/057)

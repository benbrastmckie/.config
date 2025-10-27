# Simplification Opportunities in /orchestrate

## Executive Summary

**File Size**: 5,478 lines
**Core Issue**: Excessive fallback mechanisms, redundant templates, and verbose guidance instead of executable code
**Estimated Reduction**: 1,800-2,200 lines (33-40% size reduction to ~3,300 lines)
**Primary Goal**: Single working workflow with minimal conditional logic

## Fallback Mechanisms to Remove

### Auto-Retry Infrastructure (Lines 858-1022, 1519-1781)

**Pattern**: Research and planning phases include 3-attempt retry loops with escalating template enforcement
- **Attempt 1**: Standard template
- **Attempt 2**: Ultra-explicit template
- **Attempt 3**: Step-by-step template

**Occurrences**:
- Research phase: 84 mentions of "fallback|retry|attempt"
- Planning phase: Similar retry pattern
- Total: ~500 lines of auto-retry infrastructure

**Recommendation**: Remove auto-retry. Use single template with strong enforcement markers.

**Rationale**:
- Retry logic masks agent issues instead of fixing root cause
- Three templates for same operation = maintenance burden
- Adds complexity without proven benefit
- Single well-designed template should succeed 90%+

**Lines to Remove**:
- Lines 858-1022: Research phase auto-retry loop
- Lines 1519-1781: Planning phase auto-retry loop
- Lines 1079-1109: Auto-recovery architecture explanation
- Estimated: ~500 lines

### Fallback File Creation (Lines 1177-1228, 1884-1947, 3156-3195, 3771-3800, 3879-3946)

**Pattern**: After agent fails to create file, orchestrator creates minimal fallback version

**Occurrences**:
- Research overview fallback (lines 1177-1228)
- Plan creation fallback (implied in verification)
- Test output fallback (lines 3156-3195)
- Debug report fallback (lines 2771-2800)
- Summary fallback (lines 3879-3946)

**Total**: ~250 lines of fallback file creation

**Recommendation**: Remove all fallback file creation. If agent fails, report error and exit.

**Rationale**:
- Fallback creates incomplete artifacts
- Hides agent failures instead of exposing them
- Violates "orchestrator coordinates, doesn't execute" principle
- Creates technical debt (minimal files need manual completion)

### Path Correction Mechanisms (Lines 1883-1920)

**Pattern**: If agent creates file in wrong location, orchestrator searches and moves it

**Occurrences**:
- Lines 1905-1910: Path mismatch handling in planning
- Lines 3882-3900: Search and move summary file
- Estimated: ~50 lines

**Recommendation**: Remove path correction. Pre-calculate paths, verify creation, fail if wrong.

**Rationale**:
- If agent can't follow path instructions, fix agent prompt
- Path correction adds fragility (what if multiple files match?)
- Complicates verification logic

**Total Fallback Lines to Remove**: ~800 lines

## Redundant Templates to Consolidate

### Three Templates Per Agent Invocation

**Current State**: Each subagent invocation has 3 template variations:
1. STANDARD template (attempt 1)
2. ULTRA-EXPLICIT template (attempt 2)
3. STEP-BY-STEP template (attempt 3)

**Count**: 82 occurrences of template selection keywords

**Redundancy**:
- Research agents: 3 templates × multiple topics = 9-12 template blocks
- Planning agent: 3 templates = 3 template blocks
- Debug agent: 1 template (no retry)
- Documentation agent: 1 template (no retry)

**Total Template Lines**: ~600 lines (18 agent invocations × ~35 lines per template)

**Recommendation**: Single template per agent type with strong enforcement.

**Consolidation Example**:

```yaml
# BEFORE: 3 templates (105 lines)
standard_template: {...35 lines...}
ultra_explicit_template: {...35 lines...}
step_by_step_template: {...35 lines...}

# AFTER: 1 template (40 lines)
enforced_template: {
  ...strong enforcement markers...
  ...verification checkpoints...
  ...mandatory file creation...
}
```

**Lines Saved**: ~400 lines (keeping strongest enforcement, removing redundant variants)

## Guidance to Make Executable

### Enforcement Rationale Comments (32 Occurrences)

**Pattern**: HTML comments explaining why enforcement is needed

**Examples**:
- Lines 677-687: "ENFORCEMENT RATIONALE: Path Pre-Calculation"
- Lines 754-770: "ENFORCEMENT RATIONALE: Agent Template Verbatim Usage"
- Lines 1062-1077: "ENFORCEMENT RATIONALE: Mandatory Verification + Fallback"
- Lines 1321-1337: "ENFORCEMENT RATIONALE: Checkpoint Reporting"

**Count**: 32 comment blocks, ~15 lines each = ~480 lines

**Current Function**: Explain to AI why certain patterns are mandatory

**Recommendation**: Remove enforcement rationale comments. Replace with inline directives.

**Example Transformation**:

```markdown
# BEFORE (20 lines)
<!--
ENFORCEMENT RATIONALE: Path Pre-Calculation

WHY "EXECUTE NOW" instead of "First, create":
- Without "EXECUTE NOW", Claude interprets as guidance
- ~30% of runs skip path calculation
- Skipping causes agents to create files in wrong locations
- Explicit "EXECUTE NOW" + verification = 100% execution

BEFORE: "First, create..." (60-70% compliance)
AFTER: "**EXECUTE NOW**" (100% compliance)
-->

**EXECUTE NOW - Calculate Report Paths**

# AFTER (2 lines)
**MANDATORY - Calculate Report Paths (Verify completion before proceeding)**
```

**Lines Saved**: ~400 lines

### Procedural Steps and Checkpoints (27 Occurrences)

**Pattern**: Verbose step-by-step procedures with verification checkpoints

**Examples**:
- "Step 1: Extract context" (5-10 lines explaining what to extract)
- "Step 2: Invoke agent" (15-20 lines with template)
- "Step 3: Verify results" (10-15 lines with bash verification)
- "CHECKPOINT: Phase complete" (10-15 lines reporting status)

**Count**: 27 step/phase headers with detailed explanations

**Recommendation**: Condense steps into executable blocks.

**Example Transformation**:

```markdown
# BEFORE (35 lines)
### Step 1: Prepare Planning Context

GATHER workflow artifacts and build planning context structure.

**EXECUTE NOW: Gather Workflow Artifacts**

EXTRACT the following from workflow_state:
1. **Research report paths** (from research phase checkpoint)
2. **Implementation plan path** (from planning phase checkpoint)
...5 more items...

BUILD the planning context structure:
```yaml
planning_context:
  workflow_description: "..."
  research_reports: [...]
  ...10 more fields...
```

**VERIFICATION CHECKLIST**:
- [ ] workflow_description extracted
- [ ] All phase outputs collected
- [ ] File paths verified
- [ ] Context structure complete

# AFTER (10 lines)
**Planning Context (Extract and verify before agent invocation)**

```bash
# Required: workflow_description, research_reports, plan_path, thinking_mode
PLANNING_CONTEXT=$(build_planning_context "$WORKFLOW_STATE")
verify_context_complete "$PLANNING_CONTEXT" || exit 1
```
```

**Lines Saved**: ~400 lines (condensing verbose procedures)

## Optional Features to Remove

### Dry-Run Mode (Lines 99-116)

**Current State**: 3 references to `--dry-run` flag
- Lines 99-116: Dry-run mode description
- References orchestration-alternatives.md for examples
- Adds conditional logic throughout workflow

**Recommendation**: Remove dry-run mode completely.

**Rationale**:
- Dry-run is preview functionality, not core workflow
- Adds conditional branches (if dry_run: preview, else: execute)
- Users can review plan file before implementing (same effect)
- Minimal usage based on lack of implementation details

**Lines Saved**: ~50 lines (removing dry-run description and conditional logic)

### Pull Request Creation (Lines 4186-4370, 4776-4868)

**Current State**: Conditional PR creation with github-specialist agent
- Lines 4186-4370: Step 7 - PR creation in documentation phase
- Lines 4776-4868: Step 8 - Duplicate PR creation section
- Checks for `--create-pr` flag
- Validates gh CLI and auth
- Invokes github-specialist agent
- Updates summary with PR link

**Recommendation**: Remove PR creation from core orchestration.

**Rationale**:
- PR creation is post-workflow operation, not core orchestration
- Users can run `/create-pr` command separately
- Adds complexity (gh CLI checks, auth validation, error handling)
- Minimal value in automated PR vs manual review before creating

**Lines Saved**: ~300 lines

**Alternative**: Document manual PR creation in workflow summary.

## Verbose Sections to Distill

### Phase Coordination Headers (Lines 390-596, 1407-1880, 2125-2619)

**Pattern**: Each phase has extensive documentation before execution

**Example Structure**:
```markdown
### Research Phase (Parallel Execution)

[3-paragraph explanation of when to use, what it does]

**Quick Overview**: [7-step summary]

**Pattern Details**: See external file for:
- Complete step-by-step execution
- Complexity score calculation
- Thinking mode determination
- [8 more items]

**Key Execution Requirements**: [5 subsections]
```

**Occurrences**:
- Phase 0: Location determination (206 lines)
- Phase 1: Research (490 lines)
- Phase 2: Planning (470 lines)
- Phase 3: Implementation (495 lines)
- Phase 4: Testing (306 lines)
- Phase 5: Debugging (620 lines)
- Phase 6: Documentation (872 lines)

**Total**: ~3,459 lines for phase descriptions

**Recommendation**: Reduce each phase description to 30-50 lines.

**Distillation Example**:

```markdown
# BEFORE (490 lines)
### Research Phase (Parallel Execution)

The research phase coordinates multiple specialized agents to investigate
different aspects of the workflow in parallel, then verifies all research
outputs before proceeding.

**When to Use Research Phase**:
- Complex workflows requiring investigation
- Medium+ complexity
- Skip for simple tasks

**Quick Overview**: [7 steps]
**Pattern Details**: See orchestration-patterns.md for:
- [15 items]

**Key Execution Requirements**:
1. Complexity Analysis: [20 lines]
2. Path Calculation: [40 lines]
3. Agent Invocation: [150 lines with 3 templates]
4. Verification: [80 lines]
...

# AFTER (40 lines)
### Phase 1: Research (Parallel, conditional)

**Trigger**: Complexity ≥4 (calculate: keywords×weights + file_count/5)
**Agents**: 2-4 research-specialists (parallel invocation)
**Output**: Reports in ${ARTIFACT_REPORTS}, overview synthesis

```bash
# Calculate complexity and determine research topics
COMPLEXITY=$(calculate_complexity "$WORKFLOW_DESC")
[[ $COMPLEXITY -lt 4 ]] && skip_research=true

# Invoke research agents (single message, parallel execution)
for topic in "${RESEARCH_TOPICS[@]}"; do
  REPORT_PATH="${ARTIFACT_REPORTS}${TOPIC_NUMBER}_${topic}.md"
  invoke_agent research-specialist "$topic" "$REPORT_PATH"
done

# Synthesize overview from individual reports
invoke_agent research-synthesizer "${SUCCESSFUL_REPORTS[@]}" \
  "${ARTIFACT_REPORTS}${TOPIC_NUMBER}_overview.md"

# Verify all reports created
verify_files_exist "${REPORT_PATHS[@]}" || exit 1
```
```

**Lines Saved per Phase**: ~450 lines × 7 phases = ~2,100 lines

**But**: This is too aggressive. Maintain 100-150 lines per phase for clarity.

**Realistic Saving**: ~250 lines × 7 = ~1,750 lines

## Size Reduction Estimate

### By Category

| Category | Current Lines | Removable | After Removal |
|----------|---------------|-----------|---------------|
| Auto-Retry Infrastructure | 800 | 800 | 0 |
| Fallback Mechanisms | 250 | 250 | 0 |
| Redundant Templates | 600 | 400 | 200 |
| Enforcement Rationale | 480 | 400 | 80 |
| Verbose Steps/Checkpoints | 500 | 400 | 100 |
| Optional Features (dry-run, PR) | 350 | 350 | 0 |
| Phase Descriptions | 3,459 | 1,750 | 1,709 |
| **Total** | **6,439** | **4,350** | **2,089** |

### File Size Projection

- **Current**: 5,478 lines
- **Orchestration Logic**: ~1,039 lines (phases, agents, state)
- **Removable Bloat**: ~2,200 lines (as calculated above)
- **Target**: ~3,300 lines (40% reduction)

**Breakdown of Final Structure** (~3,300 lines):
- Metadata & Architecture: 150 lines
- Shared Utilities & Reference: 100 lines
- Phase 0: Location: 50 lines
- Phase 1: Research: 150 lines
- Phase 2: Planning: 120 lines
- Phase 3: Implementation: 200 lines
- Phase 4: Testing: 100 lines
- Phase 5: Debugging: 150 lines
- Phase 6: Documentation: 200 lines
- Agent Templates: 700 lines (1 per agent type, comprehensive)
- State Management: 150 lines
- Error Handling: 100 lines
- Context Management: 100 lines
- Completion & Reporting: 130 lines

## Minimum Viable Workflow

### Single Working Path (No Fallbacks)

```markdown
# /orchestrate - Multi-Agent Workflow Coordination

**Architecture**: Orchestrator invokes specialized agents via Task tool (never SlashCommand)
**Phases**: Location → Research → Planning → Implementation → Testing → [Debug] → Documentation
**Pattern**: Pre-calculate paths → Invoke agents → Verify files → Proceed or fail

## Phase 0: Location

```bash
invoke_agent location-specialist "$WORKFLOW_DESC" → LOCATION_CONTEXT
verify_directory_structure "$TOPIC_PATH" || exit 1
export ARTIFACT_PATHS
```

## Phase 1: Research (Complexity ≥4)

```bash
calculate_topics_from_complexity "$WORKFLOW_DESC" → RESEARCH_TOPICS
for topic in topics; invoke_agent research-specialist "$topic" done
invoke_agent research-synthesizer "${REPORTS[@]}" → OVERVIEW
verify_files_exist "${REPORTS[@]}" "$OVERVIEW" || exit 1
```

## Phase 2: Planning

```bash
invoke_agent plan-architect "$OVERVIEW" "$WORKFLOW_DESC" → PLAN_PATH
verify_file_exists "$PLAN_PATH" || exit 1
verify_plan_structure "$PLAN_PATH" || exit 1
```

## Phase 3: Implementation

```bash
invoke_agent implementer-coordinator "$PLAN_PATH" → WAVE_RESULTS
verify_implementation_complete "$WAVE_RESULTS" || exit 1
```

## Phase 4: Testing

```bash
invoke_agent test-specialist "$PLAN_PATH" → TEST_RESULTS
parse_test_status "$TEST_RESULTS" → TESTS_PASSING
```

## Phase 5: Debugging (if !TESTS_PASSING, max 3 iterations)

```bash
for iteration in 1 2 3; do
  invoke_agent debug-analyst "$TEST_FAILURES" → DEBUG_REPORT
  invoke_agent code-writer "fix:$DEBUG_REPORT" → FIX_APPLIED
  invoke_agent test-specialist → TEST_RESULTS
  [[ $TESTS_PASSING == true ]] && break
done
[[ $TESTS_PASSING == false ]] && escalate_to_user
```

## Phase 6: Documentation

```bash
invoke_agent doc-writer "$WORKFLOW_CONTEXT" → SUMMARY_PATH
verify_summary_exists "$SUMMARY_PATH" || exit 1
verify_cross_references "$SUMMARY" "$PLAN" "$REPORTS[@]" || exit 1
display_completion_message
```

## Agent Templates (1 per type, comprehensive enforcement)

### research-specialist
[Single template with strong enforcement, 40 lines]

### plan-architect
[Single template with strong enforcement, 50 lines]

### implementer-coordinator
[Single template with wave-based execution, 60 lines]

### test-specialist
[Single template with comprehensive testing, 40 lines]

### debug-analyst
[Single template with root cause analysis, 40 lines]

### doc-writer
[Single template with summary generation, 50 lines]

## Error Handling

**Philosophy**: Fail fast, report clearly, no hidden compensation

```bash
verify_agent_file_creation() {
  [[ -f "$EXPECTED_PATH" ]] || {
    echo "ERROR: Agent failed to create $EXPECTED_PATH"
    echo "Agent output: $AGENT_OUTPUT"
    exit 1
  }
}
```

## State Management

**Minimal State**: Current phase, artifact paths, test status, timing

```yaml
workflow_state:
  phase: "research|planning|implementation|testing|debugging|documentation"
  location_context: {...from Phase 0...}
  artifact_paths: {reports: [], plan: "", summary: ""}
  tests_passing: true|false
  debug_iteration: 0-3
  timing: {start, phase_times}
```

## Context Reduction

**Pattern**: Pass file paths, not content. Extract metadata summaries (50 words).

```bash
# NOT THIS: Pass full 5000-token plan to agent
agent_prompt="Plan content: $(cat $PLAN_PATH)"

# THIS: Pass path, agent reads selectively
agent_prompt="Plan path: $PLAN_PATH (use Read tool to access)"
```
```

**Total Minimal Viable**: ~800 lines of executable workflow + 700 lines of agent templates = **1,500 lines core**

## Recommendations

### Phase 1: Remove Fallback Infrastructure

1. Remove all auto-retry loops (research, planning)
2. Remove all fallback file creation
3. Remove path correction mechanisms
4. **Result**: -800 lines, fail-fast behavior

### Phase 2: Consolidate Templates

1. Keep strongest template per agent (STEP-BY-STEP or ULTRA-EXPLICIT)
2. Remove STANDARD and other variants
3. **Result**: -400 lines, single working template

### Phase 3: Condense Guidance

1. Remove enforcement rationale comments (keep directives)
2. Reduce phase descriptions to 100-150 lines each
3. Convert verbose steps to executable bash blocks
4. **Result**: -1,000 lines, executable focus

### Phase 4: Remove Optional Features

1. Remove dry-run mode
2. Remove PR creation (document manual command)
3. **Result**: -350 lines, core workflow only

### Total Reduction: ~2,550 lines (47% reduction to ~2,900 lines)

**Conservative Target**: 3,300 lines (40% reduction) to maintain clarity

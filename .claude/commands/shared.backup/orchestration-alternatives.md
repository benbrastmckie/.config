# Orchestration Workflow Alternatives

[Extracted from orchestrate.md during 070 refactor]

Last Updated: 2025-10-23

---

[Content will be added during Phase 2, 3, and 5]
2. Invoke plan-structure-manager agent with recursive expansion (operation: expand)
3. Extract expansion results (files created, structure level)
4. Validate expansion artifacts created
5. Update workflow state with hierarchical plan information
6. Display expansion summary
7. Proceed to Phase 5 (Implementation) with hierarchical plan

### Step 1: Verify Expansion Requirements

**EXECUTE NOW - Check Expansion Pending Flag**:

```bash
# Verify expansion flag from Phase 2.5
if [ "$WORKFLOW_STATE_EXPANSION_PENDING" != true ]; then
  echo "═══════════════════════════════════════════════════════"
  echo "PHASE 4: Plan Expansion - SKIPPED"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Reason: No phases require expansion (expansion pending = false)"
  echo "✓ Proceeding directly to Phase 5 (Implementation)"
  echo ""

  # Skip to Phase 5
  exit 0
fi

# Expansion required - proceed with Phase 4
echo "═══════════════════════════════════════════════════════"
echo "PHASE 4: Plan Expansion"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Expansion Required: YES"
echo "Phases to Expand: ${WORKFLOW_STATE_PHASES_TO_EXPAND[@]}"
echo "Expansion Count: $WORKFLOW_STATE_EXPANSION_COUNT"
echo "Complexity Threshold: $EXPANSION_THRESHOLD"
echo ""
```

### Step 2: Invoke Expansion-Specialist Agent

**EXECUTE NOW - Recursive Plan Expansion**:

Use the Task tool to invoke plan-structure-manager with behavioral injection (operation: expand):

```yaml
subagent_type: general-purpose

description: "Expand high-complexity phases based on complexity analysis"

timeout: 180000  # 3 minutes for expansion operations

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-structure-manager.md

  Operation: expand

  You are acting as an Expansion Specialist Agent.

  EXPANSION TASK: Recursive Plan Expansion

  CONTEXT:
  - Plan Path: ${IMPLEMENTATION_PLAN_PATH}
  - Complexity Report: Available from Phase 2.5
  - Phases to expand: ${WORKFLOW_STATE_PHASES_TO_EXPAND[@]}
  - Expansion threshold: ${EXPANSION_THRESHOLD}
  - Task count threshold: ${TASK_COUNT_THRESHOLD}
  - Max depth: 2 (Level 0 → 1 → 2)
  - Current structure level: 0 (inline phases)

  YOUR TASK:
  1. For each phase in expansion list (${WORKFLOW_STATE_PHASES_TO_EXPAND[@]}):
     - Expand phase to Level 1 (separate file with stages)
     - Re-evaluate complexity of expanded phase
     - If any stages exceed threshold, expand to Level 2
  2. Respect max depth limit (no Level 3 expansion)
  3. Create expansion artifacts for each operation
  4. Update parent plans with summaries and references
  5. Maintain cross-reference integrity
  6. Return expansion summary report

  EXPANSION WORKFLOW:
  For each phase requiring expansion:

  STEP 1 (Validation):
  - Verify plan file exists at ${IMPLEMENTATION_PLAN_PATH}
  - Verify phase number valid and not already expanded
  - Confirm current Structure Level is 0
  - Verify write permissions on plan directory

  STEP 2 (Extraction):
  - Read main plan file
  - Extract full phase content (heading to next heading or EOF)
  - Preserve all formatting, code blocks, checkboxes
  - Capture phase name from heading
  - Maintain exact indentation and markdown structure

  STEP 3 (File Creation):
  - Create plan directory if Level 0 → 1 transition
  - Create phase file with extracted content
  - Add metadata section with phase number, parent plan link, complexity score
  - Verify file creation successful

  STEP 4 (Parent Update):
  - Replace phase content with summary in parent plan
  - Add [See: phase_N_name.md] marker
  - Update Structure Level metadata to 1
  - Add phase number to Expanded Phases list

  STEP 5 (Artifact Creation):
  - Create artifact file at specs/artifacts/{plan_name}/expansion_{N}.md
  - Include all required sections (Metadata, Operation Summary, Files Created, Validation)
  - Populate all metadata fields
  - Complete validation checklist

  RECURSIVE EVALUATION:
  - After expanding each phase, re-evaluate complexity of expanded content
  - If any stages exceed ${EXPANSION_THRESHOLD}, expand to Level 2
  - Maximum 2 expansion attempts per item (loop prevention)

  REQUIRED OUTPUT:
  Return structured YAML report:

  expansion_summary:
    plan_path: "${IMPLEMENTATION_PLAN_PATH}"
    expansion_timestamp: "[ISO 8601 timestamp]"
    initial_structure_level: 0
    final_structure_level: [1|2]

    expansions_performed:
      - phase_number: [N]
        phase_name: "[name]"
        expansion_level: [1|2]
        phase_file_created: "[path]"
        complexity_score: [N.N]
        stages_expanded: [array of stage numbers if Level 2]
        artifact_path: "[path]"

    files_created:
      - "[absolute path to phase_N_name.md]"
      - "[absolute path to stage_M_name.md]" (if Level 2)

    files_modified:
      - "[absolute path to parent plan]"

    artifacts_created:
      - "[absolute path to expansion artifact]"

    expansion_summary_path: "[path to expansion_summary.md in specs/artifacts/]"

    final_plan_structure:
      structure_level: [1|2]
      expanded_phases: [array of phase numbers]
      expanded_stages: "[Phase N: [M, ...]]" (if Level 2)

    recommendations:
      - "[Any manual review recommendations]"

  Quality Requirements:
  - All required files created (no missing files)
  - All parent plans updated with references
  - All expansion artifacts created
  - Cross-references verified (no broken links)
  - YAML properly formatted (2-space indentation)
  - No conversational text, only structured output
```

### Step 3: Validate Expansion Results

**MANDATORY VERIFICATION CHECKPOINT**:

```bash
# Verify plan-structure-manager produced valid output
if [ -z "$PLAN_STRUCTURE_MANAGER_OUTPUT" ]; then
  echo "ERROR: plan-structure-manager agent returned empty output"
  echo "FALLBACK: Creating minimal expansion summary"

  # Fallback: Create minimal expansion summary
  EXPANSION_SUMMARY_PATH="${WORKFLOW_TOPIC_DIR}/artifacts/expansion_summary_fallback.md"
  cat > "$EXPANSION_SUMMARY_PATH" <<'EOF'
# Expansion Summary (Fallback)

## Summary
Expansion specialist failed - minimal expansion summary created by fallback mechanism.

## Files Created
- (Manual expansion required - agent failed)

## Recommendation
Review complexity report and manually expand high-complexity phases using /expand command.
EOF

  echo "✓ Fallback expansion summary created at: $EXPANSION_SUMMARY_PATH"
  EXPANSION_FAILED=true
else
  echo "✓ VERIFIED: Expansion specialist returned output"
  EXPANSION_FAILED=false
fi

# Verify output contains required fields
if ! echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -q "expansion_summary:"; then
  echo "ERROR: plan-structure-manager output missing 'expansion_summary:' field"
  echo "Output received:"
  echo "$EXPANSION_SPECIALIST_OUTPUT"
  echo ""
  echo "FALLBACK: Proceeding with fallback expansion summary"
  EXPANSION_FAILED=true
fi

# Extract expansion summary path
EXPANSION_SUMMARY_PATH=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep "expansion_summary_path:" | cut -d'"' -f2)

if [ -z "$EXPANSION_SUMMARY_PATH" ] || [ ! -f "$EXPANSION_SUMMARY_PATH" ]; then
  echo "ERROR: Expansion summary not created at expected location"
  echo "Expected path: $EXPANSION_SUMMARY_PATH"
  echo ""
  echo "FALLBACK: Creating minimal expansion summary"

  # Fallback summary path
  EXPANSION_SUMMARY_PATH="${WORKFLOW_TOPIC_DIR}/artifacts/expansion_summary_fallback.md"
  cat > "$EXPANSION_SUMMARY_PATH" <<EOF
# Expansion Summary (Fallback)

## Plan
${IMPLEMENTATION_PLAN_PATH}

## Phases Attempted
${WORKFLOW_STATE_PHASES_TO_EXPAND[@]}

## Status
Expansion specialist encountered errors during execution.

## Recommendation
Review complexity analysis and manually expand phases using:
/expand ${IMPLEMENTATION_PLAN_PATH} phase [N]
EOF

  echo "✓ Fallback expansion summary created"
  EXPANSION_FAILED=true
fi

echo "Verification complete: Expansion summary at $EXPANSION_SUMMARY_PATH"
echo ""
```

### Step 4: Extract Expansion Metadata

**EXECUTE NOW - Parse Expansion Results**:

```bash
# Extract key metadata from expansion summary
FINAL_STRUCTURE_LEVEL=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep "final_structure_level:" | grep -oE "[0-2]")
EXPANDED_PHASES=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -A 50 "expanded_phases:" | grep -E "^\s*-\s*[0-9]+" | grep -oE "[0-9]+" | tr '\n' ' ')
EXPANDED_STAGES=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep "expanded_stages:" | cut -d'"' -f2)

# Extract files created
FILES_CREATED=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -A 100 "files_created:" | grep -E "^\s*-\s*\"" | cut -d'"' -f2 | tr '\n' ' ')
FILES_COUNT=$(echo "$FILES_CREATED" | wc -w)

# Fallback values if parsing failed
[ -z "$FINAL_STRUCTURE_LEVEL" ] && FINAL_STRUCTURE_LEVEL=0
[ -z "$EXPANDED_PHASES" ] && EXPANDED_PHASES="${WORKFLOW_STATE_PHASES_TO_EXPAND[@]}"
[ -z "$FILES_COUNT" ] && FILES_COUNT=0

echo "Expansion Metadata Extracted:"
echo "- Final Structure Level: $FINAL_STRUCTURE_LEVEL"
echo "- Expanded Phases: ${EXPANDED_PHASES}"
echo "- Expanded Stages: ${EXPANDED_STAGES:-none}"
echo "- Files Created: $FILES_COUNT"
echo ""

# Verify phase/stage files from files_created list
for phase_file in $FILES_CREATED; do
  if [ ! -f "$phase_file" ]; then
    echo "WARNING: Expected phase/stage file missing: $phase_file"
    echo "FALLBACK: Creating minimal phase file"

    # Extract phase number from filename
    phase_num=$(basename "$phase_file" | sed 's/phase_\([0-9]*\).*/\1/')

    # Create minimal phase file
    cat > "$phase_file" <<EOF
# Phase $phase_num

## Overview
Minimal phase file created by fallback mechanism.
Manual expansion required.

## Tasks
- [ ] Review complexity analysis
- [ ] Manually break down this phase
EOF

    echo "✓ Minimal phase file created: $phase_file"
  else
    echo "✓ Phase file verified: $phase_file"
  fi
done

echo ""
```

### Step 5: Update Workflow State

**EXECUTE NOW - Store Expansion Data in Workflow State**:

```bash
# Update workflow state with expansion results
WORKFLOW_STATE_EXPANSION_PERFORMED=true
WORKFLOW_STATE_EXPANSION_FAILED=$EXPANSION_FAILED
WORKFLOW_STATE_FINAL_STRUCTURE_LEVEL=$FINAL_STRUCTURE_LEVEL
WORKFLOW_STATE_PLAN_IS_HIERARCHICAL=$([ "$FINAL_STRUCTURE_LEVEL" -gt 0 ] && echo "true" || echo "false")
WORKFLOW_STATE_EXPANSION_SUMMARY_PATH=$EXPANSION_SUMMARY_PATH

# Update plan path if plan was moved into directory during expansion
if [ "$FINAL_STRUCTURE_LEVEL" -gt 0 ]; then
  PLAN_DIR=$(dirname "$IMPLEMENTATION_PLAN_PATH")/$(basename "$IMPLEMENTATION_PLAN_PATH" .md)
  if [ -d "$PLAN_DIR" ]; then
    IMPLEMENTATION_PLAN_PATH="$PLAN_DIR/$(basename $IMPLEMENTATION_PLAN_PATH)"
    echo "✓ Plan path updated (hierarchical): $IMPLEMENTATION_PLAN_PATH"
  fi
fi

echo "Workflow State Updated:"
echo "- Expansion Performed: $WORKFLOW_STATE_EXPANSION_PERFORMED"
echo "- Expansion Failed: $WORKFLOW_STATE_EXPANSION_FAILED"
echo "- Final Structure Level: $WORKFLOW_STATE_FINAL_STRUCTURE_LEVEL"
echo "- Plan is Hierarchical: $WORKFLOW_STATE_PLAN_IS_HIERARCHICAL"
echo "- Expansion Summary: $WORKFLOW_STATE_EXPANSION_SUMMARY_PATH"
echo "- Updated Plan Path: $IMPLEMENTATION_PLAN_PATH"
echo ""
```

### Step 6: Display Expansion Summary

**EXECUTE NOW - Format and Display Expansion Summary**:

```bash
echo "═══════════════════════════════════════════════════════"
echo "PHASE 4: Plan Expansion Complete"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Plan: $(basename $IMPLEMENTATION_PLAN_PATH)"
echo "Structure Level: 0 → $FINAL_STRUCTURE_LEVEL"
echo "Expansions Performed: ${#WORKFLOW_STATE_PHASES_TO_EXPAND[@]}"
echo "Files Created: $FILES_COUNT"
echo ""

if [ "$EXPANSION_FAILED" = true ]; then
  echo "⚠ WARNING: Expansion encountered errors"
  echo "   Review expansion summary for details: $EXPANSION_SUMMARY_PATH"
  echo "   Manual expansion may be required using /expand command"
2. Invoke plan-structure-manager agent with recursive expansion (operation: expand)
3. Extract expansion results (files created, structure level)
4. Validate expansion artifacts created
5. Update workflow state with hierarchical plan information
6. Display expansion summary
7. Proceed to Phase 5 (Implementation) with hierarchical plan

### Step 1: Verify Expansion Requirements

**EXECUTE NOW - Check Expansion Pending Flag**:

```bash
# Verify expansion flag from Phase 2.5
if [ "$WORKFLOW_STATE_EXPANSION_PENDING" != true ]; then
  echo "═══════════════════════════════════════════════════════"
  echo "PHASE 4: Plan Expansion - SKIPPED"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Reason: No phases require expansion (expansion pending = false)"
  echo "✓ Proceeding directly to Phase 5 (Implementation)"
  echo ""

  # Skip to Phase 5
  exit 0
fi

# Expansion required - proceed with Phase 4
echo "═══════════════════════════════════════════════════════"
echo "PHASE 4: Plan Expansion"
echo "═══════════════════════════════════════════════════════"
echo ""
--
     - Re-evaluate complexity of expanded phase
     - If any stages exceed threshold, expand to Level 2
  2. Respect max depth limit (no Level 3 expansion)
  3. Create expansion artifacts for each operation
  4. Update parent plans with summaries and references
  5. Maintain cross-reference integrity
  6. Return expansion summary report

  EXPANSION WORKFLOW:
  For each phase requiring expansion:

  STEP 1 (Validation):
  - Verify plan file exists at ${IMPLEMENTATION_PLAN_PATH}
  - Verify phase number valid and not already expanded
  - Confirm current Structure Level is 0
  - Verify write permissions on plan directory

  STEP 2 (Extraction):
  - Read main plan file
  - Extract full phase content (heading to next heading or EOF)
  - Preserve all formatting, code blocks, checkboxes
  - Capture phase name from heading
  - Maintain exact indentation and markdown structure

  STEP 3 (File Creation):
  - Create plan directory if Level 0 → 1 transition
  - Create phase file with extracted content
  - Add metadata section with phase number, parent plan link, complexity score
  - Verify file creation successful

  STEP 4 (Parent Update):
--
  RECURSIVE EVALUATION:
  - After expanding each phase, re-evaluate complexity of expanded content
  - If any stages exceed ${EXPANSION_THRESHOLD}, expand to Level 2
  - Maximum 2 expansion attempts per item (loop prevention)

  REQUIRED OUTPUT:
  Return structured YAML report:

  expansion_summary:
    plan_path: "${IMPLEMENTATION_PLAN_PATH}"
    expansion_timestamp: "[ISO 8601 timestamp]"
    initial_structure_level: 0
    final_structure_level: [1|2]

    expansions_performed:
      - phase_number: [N]
        phase_name: "[name]"
        expansion_level: [1|2]
        phase_file_created: "[path]"
        complexity_score: [N.N]
        stages_expanded: [array of stage numbers if Level 2]
        artifact_path: "[path]"

    files_created:
      - "[absolute path to phase_N_name.md]"
      - "[absolute path to stage_M_name.md]" (if Level 2)

    files_modified:
      - "[absolute path to parent plan]"

    artifacts_created:
4. Validate expansion artifacts created
5. Update workflow state with hierarchical plan information
6. Display expansion summary
7. Proceed to Phase 5 (Implementation) with hierarchical plan

### Step 1: Verify Expansion Requirements

**EXECUTE NOW - Check Expansion Pending Flag**:

```bash
# Verify expansion flag from Phase 2.5
if [ "$WORKFLOW_STATE_EXPANSION_PENDING" != true ]; then
  echo "═══════════════════════════════════════════════════════"
  echo "PHASE 4: Plan Expansion - SKIPPED"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "Reason: No phases require expansion (expansion pending = false)"
  echo "✓ Proceeding directly to Phase 5 (Implementation)"
  echo ""

  # Skip to Phase 5
  exit 0
fi

# Expansion required - proceed with Phase 4
echo "═══════════════════════════════════════════════════════"
--
  - Verify file creation successful

  STEP 4 (Parent Update):
  - Replace phase content with summary in parent plan
  - Add [See: phase_N_name.md] marker
  - Update Structure Level metadata to 1
  - Add phase number to Expanded Phases list

  STEP 5 (Artifact Creation):
  - Create artifact file at specs/artifacts/{plan_name}/expansion_{N}.md
  - Include all required sections (Metadata, Operation Summary, Files Created, Validation)
  - Populate all metadata fields
  - Complete validation checklist

  RECURSIVE EVALUATION:
  - After expanding each phase, re-evaluate complexity of expanded content
  - If any stages exceed ${EXPANSION_THRESHOLD}, expand to Level 2
  - Maximum 2 expansion attempts per item (loop prevention)

  REQUIRED OUTPUT:
  Return structured YAML report:

  expansion_summary:
    plan_path: "${IMPLEMENTATION_PLAN_PATH}"
    expansion_timestamp: "[ISO 8601 timestamp]"
    initial_structure_level: 0
**Preview Output Example**:
```
┌─────────────────────────────────────────────────────────────┐
│ Workflow: Add user authentication with JWT tokens (Dry-Run)│
├─────────────────────────────────────────────────────────────┤
│ Workflow Type: feature  |  Estimated Duration: ~28 minutes  │
│ Complexity: Medium-High  |  Agents Required: 6              │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research (Parallel - 3 agents)           ~8min    │
│   ├─ research-specialist: "JWT authentication patterns"    │
│   │    Report: specs/reports/jwt_patterns/001_*.md         │
│   ├─ research-specialist: "Security best practices"        │
│   │    Report: specs/reports/security/001_*.md             │
│   └─ research-specialist: "Token refresh strategies"       │
│        Report: specs/reports/token_refresh/001_*.md        │
│                                                              │
│ Phase 2: Planning (Sequential)                    ~5min    │
│   └─ plan-architect: Synthesize research into plan         │
│        Plan: specs/plans/NNN_user_authentication.md        │
│        Uses: 3 research reports                             │
│                                                              │
│ Phase 3: Implementation (Adaptive)                ~12min   │
│   └─ code-writer: Execute plan phase-by-phase              │
│        Files: auth/, middleware/, utils/                    │
│        Tests: test_auth.lua, test_jwt.lua                   │
│        Phases: 4 (1 sequential, 1 parallel wave)           │
│                                                              │
│ Phase 4: Debugging (Conditional)                  ~0min    │
│   └─ debug-specialist: Skipped (no test failures)          │
│        Triggers: Only if implementation tests fail          │
│        Max iterations: 3                                    │
│                                                              │
│ Phase 5: Documentation (Sequential)               ~3min    │
│   └─ doc-writer: Update docs and generate summary          │
│        Files: README.md, CHANGELOG.md, API.md               │
│        Summary: specs/summaries/NNN_*.md                    │
├─────────────────────────────────────────────────────────────┤
│ Execution Summary:                                           │
│   Total Phases: 5  |  Conditional Phases: 1  |  Parallel: Yes│
│   Agents Invoked: 6  |  Reports: 3  |  Plans: 1            │
│   Files Created: ~12  |  Tests: ~5                          │
│   Estimated Time: 28 minutes (20min with parallelism)      │
└─────────────────────────────────────────────────────────────┘

Proceed with workflow execution? (y/n):
```
**Workflow Type Detection**:
- **feature**: Adding new functionality (triggers full workflow)
- **refactor**: Code restructuring (skips research if standards exist)
- **debug**: Investigation and fixes (starts with debug phase)
- **investigation**: Research-only (skips implementation)

**Use Cases**:
- **Validation**: Verify workflow interpretation before execution
- **Time estimation**: Understand time commitment for complete workflow
- **Resource planning**: See which agents will be involved
- **Scope verification**: Confirm research topics and implementation scope
- **Team coordination**: Share workflow plan before starting
- **Budget estimation**: Understand LLM API costs based on agent count

**Use Cases**:
- **Validation**: Verify workflow interpretation before execution
- **Time estimation**: Understand time commitment for complete workflow
- **Resource planning**: See which agents will be involved
- **Scope verification**: Confirm research topics and implementation scope
- **Team coordination**: Share workflow plan before starting
- **Budget estimation**: Understand LLM API costs based on agent count

**Dry-Run Scope**:
- ✓ Analyzes workflow description
- ✓ Identifies research topics
- ✓ Determines agent assignments
- ✓ Estimates phase durations
- ✓ Shows execution order and parallelism
- ✓ Lists artifacts to be created
- ✗ Does not invoke agents
- ✗ Does not create files
- ✗ Does not execute commands
- ✗ Does not create reports/plans

**Dry-Run with Other Flags**:
```bash
# Dry-run with parallel research (default)
/orchestrate "Add feature X" --dry-run

# Dry-run with sequential research
/orchestrate "Add feature X" --dry-run --sequential

# Dry-run with PR creation enabled
/orchestrate "Add feature X" --dry-run --create-pr
```

**Implementation Details**:
- Workflow analysis uses pattern matching and keyword detection
- Duration estimation from `.claude/lib/agent-registry-utils.sh` metrics
- Research topic extraction via semantic analysis of workflow description
- Agent selection based on workflow type and phase requirements


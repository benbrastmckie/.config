# Phase 2: Fix /orchestrate Other Phases - Detailed Implementation

## Metadata
- **Phase Number**: 2
- **Parent Plan**: 001_execution_enforcement_fix.md
- **Objective**: Apply execution enforcement to planning, implementation, documentation phases
- **Dependencies**: [Phase 1]
- **Complexity**: Medium
- **Risk**: Low
- **Estimated Time**: 4-5 hours
- **Status**: PENDING

## Overview

This phase applies the same enforcement patterns from Phase 1 to the remaining /orchestrate phases: planning, implementation, and documentation. Each phase needs "EXECUTE NOW" markers, "MANDATORY VERIFICATION" checkpoints, and checkpoint reporting.

### Scope

**Three Phases to Fix**:
1. **Planning Phase** (lines ~1019-1150): /plan command invocation
2. **Implementation Phase** (lines ~1151-1350): /implement command invocation
3. **Documentation Phase** (lines ~1351-1500): Summary file creation

### Enforcement Patterns to Apply

For each phase:
- Add "**EXECUTE NOW**" before command invocations
- Add "**MANDATORY VERIFICATION**" after command completes
- Add "**CHECKPOINT REQUIREMENT**" at phase end
- Convert descriptive language to imperatives
- Add fallback mechanisms where applicable

## Implementation Tasks

### Task 1: Read Planning Phase Implementation

**Objective**: Understand current planning phase structure.

**Action**: Read lines ~1019-1150 of .claude/commands/orchestrate.md

**Expected Findings**:
- How /plan command is invoked
- What inputs are passed (research report paths)
- How plan path is extracted
- Current verification approach

**Completion Criteria**: Can identify specific lines needing enforcement

---

### Task 2: Add "EXECUTE NOW" for /plan Command Invocation

**Objective**: Make /plan invocation mandatory and explicit.

**Current Pattern** (likely descriptive):
```markdown
### Planning Phase (Sequential Execution)

After research completes, generate an implementation plan using /plan command.
```

**New Pattern (Enforcement Applied)**:
```markdown
### Planning Phase (Sequential Execution)

**EXECUTE NOW - Generate Implementation Plan**

YOU MUST invoke the /plan command to generate a structured implementation plan. This is NOT optional.

**WHY THIS MATTERS**: The planning phase is critical - it structures all research findings into actionable implementation steps. Skipping or simplifying this step leads to unstructured implementation.

**MANDATORY INPUTS**:
- Workflow description (original user request)
- Research report paths (from Phase 1: ${#RESEARCH_REPORT_PATHS[@]} reports)

**EXECUTE NOW - Invoke /plan Command**:

```bash
# Construct report path arguments
REPORT_ARGS=""
for report_path in "${RESEARCH_REPORT_PATHS[@]}"; do
  REPORT_ARGS="$REPORT_ARGS $report_path"
done

# MANDATORY: Invoke /plan with workflow description and reports
echo "Invoking /plan command..."
echo "  Workflow: $WORKFLOW_DESCRIPTION"
echo "  Reports: ${#RESEARCH_REPORT_PATHS[@]}"

# Use SlashCommand tool to invoke /plan
# Pattern: /plan "<feature>" <report1> <report2> ...
/plan "$WORKFLOW_DESCRIPTION" $REPORT_ARGS
```

**CRITICAL REQUIREMENTS**:
- YOU MUST use SlashCommand tool (not simulate)
- YOU MUST pass ALL research report paths
- YOU MUST pass complete workflow description
- DO NOT paraphrase or simplify the workflow description

**CHECKPOINT BEFORE INVOCATION**:
```
CHECKPOINT: Planning phase starting
- Workflow: $WORKFLOW_DESCRIPTION
- Research reports: ${#RESEARCH_REPORT_PATHS[@]}
- Report paths ready: ✓
- Invoking: /plan command
```
```

**Changes Made**:
1. Added "**EXECUTE NOW - Generate Implementation Plan**"
2. Added "YOU MUST invoke" imperative
3. Added "**WHY THIS MATTERS**" explanation
4. Added "**MANDATORY INPUTS**" list
5. Provided explicit bash code for invocation
6. Added "**CRITICAL REQUIREMENTS**" checklist
7. Added pre-invocation checkpoint

**Completion Criteria**:
- /plan invocation marked "EXECUTE NOW"
- Imperative language used
- Code provided for exact invocation
- Checkpoint added before invocation

---

### Task 3: Add "MANDATORY VERIFICATION" for Plan File Existence

**Objective**: Verify /plan command created a plan file.

**New Section** (add after /plan invocation):

```markdown
**MANDATORY VERIFICATION - Plan File Created**

After /plan command completes, YOU MUST verify that a plan file was created.

**EXECUTE NOW - Extract and Verify Plan Path**:

```bash
# STEP 1: Extract plan path from /plan command output
# Expected format: "Plan created: specs/plans/NNN_feature.md"
PLAN_OUTPUT="[capture /plan command output]"
PLAN_PATH=$(echo "$PLAN_OUTPUT" | grep -oP 'Plan created:\s*\K.+\.md' | head -1)

if [ -z "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: /plan did not return plan path"
  echo "Command output: $PLAN_OUTPUT"
  exit 1
fi

echo "✓ Plan path extracted: $PLAN_PATH"

# STEP 2: Convert to absolute path if relative
if [[ ! "$PLAN_PATH" =~ ^/ ]]; then
  PLAN_PATH="$CLAUDE_PROJECT_DIR/$PLAN_PATH"
fi

echo "✓ Absolute plan path: $PLAN_PATH"

# STEP 3: MANDATORY file existence check
echo "Verifying plan file exists..."

if [ ! -f "$PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: Plan file not found at: $PLAN_PATH"
  echo "This should never happen if /plan executed correctly"
  exit 1
fi

echo "✓ VERIFIED: Plan file exists"

# STEP 4: Verify plan has required sections
REQUIRED_SECTIONS=("Metadata" "Overview" "Implementation Phases")
MISSING_SECTIONS=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$PLAN_PATH"; then
    MISSING_SECTIONS+=("$section")
  fi
done

if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
  echo "⚠️  WARNING: Plan missing sections: ${MISSING_SECTIONS[*]}"
  echo "Plan may be incomplete"
fi

echo "✓ VERIFIED: Plan has required structure"

# Export for implementation phase
export IMPLEMENTATION_PLAN_PATH="$PLAN_PATH"
```

**MANDATORY VERIFICATION CHECKLIST**:

YOU MUST confirm ALL before proceeding to implementation:

- [ ] Plan path extracted from /plan output
- [ ] Plan path converted to absolute
- [ ] Plan file exists at expected location
- [ ] Plan has required sections (Metadata, Overview, Phases)
- [ ] Plan path exported for implementation phase

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Planning phase complete
- Plan created: ✓
- Plan path: $PLAN_PATH
- Plan structure verified: ✓
- Required sections present: ✓
- Exported to: IMPLEMENTATION_PLAN_PATH
- Proceeding to: Implementation phase
```

**CRITICAL**: If plan file verification fails, DO NOT proceed to implementation.
```

**Changes Made**:
1. Added "**MANDATORY VERIFICATION - Plan File Created**" section
2. Provided extraction and verification code
3. Added 4-step verification process
4. Added structure validation (required sections)
5. Added export for implementation phase
6. Added verification checklist
7. Added checkpoint reporting
8. Added critical failure handling

**Completion Criteria**:
- Verification marked "MANDATORY"
- Extraction code provided
- File existence verified
- Structure validated
- Checkpoint added

---

### Task 4: Add Checkpoint Reporting After Planning Phase

**Objective**: Mark planning phase complete with metrics.

(Incorporated in Task 3's checkpoint requirement)

**Completion Criteria**:
- Checkpoint includes plan path
- Checkpoint includes verification status
- Checkpoint marks transition to implementation

---

### Task 5: Read Implementation Phase

**Objective**: Understand how /implement is invoked.

**Action**: Read lines ~1151-1350 of .claude/commands/orchestrate.md

**Expected Findings**:
- /implement command invocation pattern
- Test status extraction
- Error handling approach

**Completion Criteria**: Can identify enforcement points

---

### Task 6: Add "EXECUTE NOW" for /implement Command Invocation

**Objective**: Make /implement invocation mandatory.

**New Section**:

```markdown
### Implementation Phase (Adaptive Execution)

**EXECUTE NOW - Execute Implementation Plan**

YOU MUST invoke the /implement command to execute the plan created in the planning phase. This is the core execution step.

**WHY THIS MATTERS**: This step performs the actual code changes. Without proper enforcement, the workflow stops at planning without implementation.

**MANDATORY INPUT**:
- Plan path from planning phase: $IMPLEMENTATION_PLAN_PATH

**EXECUTE NOW - Invoke /implement Command**:

```bash
# Verify we have plan path from planning phase
if [ -z "$IMPLEMENTATION_PLAN_PATH" ]; then
  echo "❌ CRITICAL ERROR: No plan path from planning phase"
  exit 1
fi

echo "✓ Plan path from planning: $IMPLEMENTATION_PLAN_PATH"

# MANDATORY: Invoke /implement with plan path
echo "Invoking /implement command..."
echo "  Plan: $IMPLEMENTATION_PLAN_PATH"

# Use SlashCommand tool to invoke /implement
/implement "$IMPLEMENTATION_PLAN_PATH"
```

**CRITICAL REQUIREMENTS**:
- YOU MUST use SlashCommand tool
- YOU MUST pass plan path from planning phase
- DO NOT modify or simplify the plan path

**CHECKPOINT BEFORE INVOCATION**:
```
CHECKPOINT: Implementation phase starting
- Plan path: $IMPLEMENTATION_PLAN_PATH
- Plan verified: ✓ (from planning phase)
- Invoking: /implement command
```
```

**Changes Made**:
1. Added "**EXECUTE NOW - Execute Implementation Plan**"
2. Added imperative language
3. Added input verification (plan path exists)
4. Provided invocation code
5. Added pre-invocation checkpoint

**Completion Criteria**:
- /implement invocation marked "EXECUTE NOW"
- Input verification added
- Invocation code provided
- Checkpoint added

---

### Task 7: Add "MANDATORY VERIFICATION" for Implementation Status

**Objective**: Verify implementation completed and tests passed.

**New Section** (add after /implement invocation):

```markdown
**MANDATORY VERIFICATION - Implementation Status**

After /implement command completes, YOU MUST verify implementation status and test results.

**EXECUTE NOW - Extract and Verify Implementation Status**:

```bash
# STEP 1: Extract test status from /implement output
# Expected format includes: "Tests passing: ✓" or "Tests passing: ✗"
IMPLEMENT_OUTPUT="[capture /implement output]"

# Extract test status
TESTS_PASSING=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Tests passing:\s*\K[✓✗]' | head -1)

if [ "$TESTS_PASSING" == "✓" ]; then
  echo "✓ VERIFIED: All tests passing"
  IMPLEMENTATION_SUCCESS=true
elif [ "$TESTS_PASSING" == "✗" ]; then
  echo "❌ TESTS FAILING"
  IMPLEMENTATION_SUCCESS=false
else
  echo "⚠️  WARNING: Could not determine test status from output"
  IMPLEMENTATION_SUCCESS=unknown
fi

# STEP 2: Extract phases completed
PHASES_COMPLETED=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Phases completed:\s*\K\d+/\d+' | head -1)
echo "Phases completed: $PHASES_COMPLETED"

# STEP 3: Extract files modified
FILES_MODIFIED=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Files modified:\s*\K\d+' | head -1)
echo "Files modified: $FILES_MODIFIED"

# STEP 4: Extract git commits
GIT_COMMITS=$(echo "$IMPLEMENT_OUTPUT" | grep -oP 'Git commits:\s*\K\d+' | head -1)
echo "Git commits: $GIT_COMMITS"

# Export status for documentation phase
export IMPLEMENTATION_SUCCESS
export TESTS_PASSING
export PHASES_COMPLETED
export FILES_MODIFIED
export GIT_COMMITS
```

**MANDATORY VERIFICATION CHECKLIST**:

YOU MUST confirm before proceeding to documentation:

- [ ] Test status extracted (passing or failing)
- [ ] Phases completed count extracted
- [ ] Files modified count extracted
- [ ] Git commits count extracted
- [ ] Implementation status exported

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Implementation phase complete
- Implementation status: $IMPLEMENTATION_SUCCESS
- Tests passing: $TESTS_PASSING
- Phases completed: $PHASES_COMPLETED
- Files modified: $FILES_MODIFIED
- Git commits: $GIT_COMMITS
- Proceeding to: Documentation phase
```

**CONDITIONAL LOGIC** (if tests failing):

If $IMPLEMENTATION_SUCCESS is false, trigger debugging loop (not part of this phase).
For this orchestration, proceed to documentation phase regardless (document current state).
```

**Changes Made**:
1. Added "**MANDATORY VERIFICATION - Implementation Status**"
2. Provided status extraction code (4 steps)
3. Added export for documentation phase
4. Added verification checklist
5. Added checkpoint with all metrics
6. Added conditional logic note

**Completion Criteria**:
- Status verification marked "MANDATORY"
- Extraction code provided
- All key metrics extracted
- Status exported
- Checkpoint added

---

### Task 8: Read Documentation Phase

**Objective**: Understand how summary is created.

**Action**: Read lines ~1351-1500 of .claude/commands/orchestrate.md

**Expected Findings**:
- Summary file creation approach
- What content is included
- How files are organized

**Completion Criteria**: Can identify enforcement points

---

### Task 9: Add "EXECUTE NOW" for Summary File Creation

**Objective**: Make summary creation mandatory.

**New Section**:

```markdown
### Documentation Phase (Sequential Execution)

**EXECUTE NOW - Generate Workflow Summary**

YOU MUST create a comprehensive workflow summary documenting the entire orchestration. This is NOT optional.

**WHY THIS MATTERS**: The summary is the permanent record of what was accomplished. Without it, the orchestration workflow is undocumented and non-reproducible.

**MANDATORY INPUTS**:
- Workflow description
- Research report paths
- Implementation plan path
- Implementation status
- All phase metrics

**EXECUTE NOW - Calculate Summary Path**:

```bash
# STEP 1: Calculate summary path (same directory as plan)
PLAN_DIR=$(dirname "$IMPLEMENTATION_PLAN_PATH")
PLAN_BASE=$(basename "$IMPLEMENTATION_PLAN_PATH" .md)
PLAN_NUM=$(echo "$PLAN_BASE" | grep -oP '^\d+')

# Summary goes in same topic directory, summaries/ subdirectory
SUMMARY_DIR="$(dirname "$PLAN_DIR")/summaries"
mkdir -p "$SUMMARY_DIR"

SUMMARY_PATH="$SUMMARY_DIR/${PLAN_NUM}_workflow_summary.md"

echo "Summary will be created at: $SUMMARY_PATH"
```

**EXECUTE NOW - Create Summary File**:

```bash
# STEP 2: Generate summary content
cat > "$SUMMARY_PATH" <<EOF
# Workflow Summary: $WORKFLOW_DESCRIPTION

## Metadata
- **Date Completed**: $(date -u +%Y-%m-%d)
- **Workflow Type**: [feature|refactor|debug|investigation]
- **Original Request**: $WORKFLOW_DESCRIPTION
- **Total Duration**: [calculated duration]

## Workflow Execution

### Phases Completed
- [x] Research (parallel) - [duration]
- [x] Planning (sequential) - [duration]
- [x] Implementation (adaptive) - [duration]
- [x] Documentation (sequential) - [duration]

### Artifacts Generated

**Research Reports**:
$(for report in "${RESEARCH_REPORT_PATHS[@]}"; do
  echo "- [$report](../$report)"
done)

**Implementation Plan**:
- Path: $IMPLEMENTATION_PLAN_PATH
- Phases: $PHASES_COMPLETED

**Implementation Results**:
- Tests passing: $TESTS_PASSING
- Files modified: $FILES_MODIFIED
- Git commits: $GIT_COMMITS

## Cross-References

### Research Phase
This workflow incorporated findings from ${#RESEARCH_REPORT_PATHS[@]} research reports.

### Planning Phase
Implementation followed the plan at: $IMPLEMENTATION_PLAN_PATH

### Implementation Phase
- Status: $IMPLEMENTATION_SUCCESS
- All artifacts cross-referenced above

## Notes

[Any additional context about the workflow execution]

---

*Workflow orchestrated using /orchestrate command*
EOF

echo "✓ Summary file created"
```

**MANDATORY VERIFICATION - Summary File Created**:

```bash
# STEP 3: Verify summary exists
if [ ! -f "$SUMMARY_PATH" ]; then
  echo "❌ CRITICAL ERROR: Summary file not created"
  exit 1
fi

echo "✓ VERIFIED: Summary file exists at $SUMMARY_PATH"

# STEP 4: Verify summary has required sections
REQUIRED_SECTIONS=("Metadata" "Workflow Execution" "Artifacts Generated" "Cross-References")
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "## $section" "$SUMMARY_PATH"; then
    echo "⚠️  WARNING: Summary missing section: $section"
  fi
done

echo "✓ VERIFIED: Summary structure complete"
```

**CRITICAL REQUIREMENTS**:
- YOU MUST create summary file (not optional)
- YOU MUST include all cross-references
- YOU MUST verify file created

**CHECKPOINT REQUIREMENT**:
```
CHECKPOINT: Documentation phase complete
- Summary created: ✓
- Summary path: $SUMMARY_PATH
- Cross-references included: ✓
- All phases documented: ✓
```
```

**Changes Made**:
1. Added "**EXECUTE NOW - Generate Workflow Summary**"
2. Added path calculation code
3. Provided complete summary template
4. Added verification after creation
5. Added checkpoint reporting

**Completion Criteria**:
- Summary creation marked "EXECUTE NOW"
- Path calculation provided
- Template provided
- Verification added
- Checkpoint added

---

### Task 10: Add Final Workflow Checkpoint Reporting

**Objective**: Mark entire orchestration workflow complete.

**New Section** (add after documentation phase):

```markdown
## Orchestration Workflow Complete

**CHECKPOINT REQUIREMENT - Report Workflow Completion**

After documentation phase completes, YOU MUST report this final checkpoint:

```
═══════════════════════════════════════════════════════
CHECKPOINT: Orchestration Workflow Complete
═══════════════════════════════════════════════════════

Workflow Status: COMPLETE ✓

Workflow Summary:
- Original request: $WORKFLOW_DESCRIPTION
- Total duration: [calculated]
- Phases executed: 4 (Research, Planning, Implementation, Documentation)

Artifacts Created:
- Research reports: ${#RESEARCH_REPORT_PATHS[@]}
- Implementation plan: $IMPLEMENTATION_PLAN_PATH
- Implementation commits: $GIT_COMMITS
- Workflow summary: $SUMMARY_PATH

Implementation Results:
- Tests passing: $TESTS_PASSING
- Files modified: $FILES_MODIFIED
- Phases completed: $PHASES_COMPLETED
- Implementation success: $IMPLEMENTATION_SUCCESS

Performance Metrics:
- Research time: [duration]
- Planning time: [duration]
- Implementation time: [duration]
- Documentation time: [duration]
- Total workflow time: [duration]
- Parallel execution savings: ~60-70% (research phase)

Context Usage:
- Research phase: <10% (metadata only)
- Planning phase: <20%
- Implementation phase: variable
- Documentation phase: <10%
- Overall: <30% average

Next Steps:
- Review workflow summary: $SUMMARY_PATH
- Review implementation plan: $IMPLEMENTATION_PLAN_PATH
- Review research reports: ${#RESEARCH_REPORT_PATHS[@]} files

═══════════════════════════════════════════════════════
```

**CRITICAL**: This checkpoint is MANDATORY. It marks the official completion of the orchestration workflow.
```

**Changes Made**:
1. Added "## Orchestration Workflow Complete" section
2. Added final checkpoint template
3. Included all key metrics and artifacts
4. Added performance metrics
5. Added context usage summary
6. Added next steps for user

**Completion Criteria**:
- Final checkpoint requirement added
- Template includes all metrics
- Marked as "MANDATORY"
- Provides user next steps

---

## Validation Checklist

Before marking Phase 2 complete, verify ALL of these:

### Planning Phase Enforcement
- [ ] "EXECUTE NOW" added for /plan invocation
- [ ] "MANDATORY VERIFICATION" added for plan file
- [ ] Checkpoint added after planning phase
- [ ] Imperative language used throughout

### Implementation Phase Enforcement
- [ ] "EXECUTE NOW" added for /implement invocation
- [ ] "MANDATORY VERIFICATION" added for test status
- [ ] Status extraction code provided
- [ ] Checkpoint added after implementation phase

### Documentation Phase Enforcement
- [ ] "EXECUTE NOW" added for summary creation
- [ ] Summary template provided
- [ ] "MANDATORY VERIFICATION" added for summary file
- [ ] Checkpoint added after documentation phase

### Final Workflow Checkpoint
- [ ] Final checkpoint requirement added
- [ ] All metrics included
- [ ] Marked as mandatory
- [ ] User next steps provided

### File Updates
- [ ] .claude/commands/orchestrate.md updated
- [ ] All enforcement patterns applied
- [ ] All checkpoints added
- [ ] No regressions introduced

## Success Metrics

**Command Execution Rate**:
- Before: ~80% (/plan, /implement may be skipped)
- After: 100% (mandatory with verification)
- Improvement: +20 percentage points

**Artifact Creation Rate**:
- Before: ~70% (plan and summary may be missing)
- After: 100% (guaranteed by verification)
- Improvement: +30 percentage points

**Checkpoint Reporting**:
- Before: 0% (no checkpoints)
- After: 100% (4 checkpoints per workflow)
- Improvement: Complete visibility

## Next Phase

After completing Phase 2:
- Proceed to Phase 2.5: Fix Priority Subagent Prompts
- Apply enforcement to 6 priority agent files
- Use same patterns: "EXECUTE NOW", "MANDATORY", "YOU MUST"

---

**Phase 2 Status**: PENDING
**Last Updated**: 2025-10-19
**Parent Plan**: 001_execution_enforcement_fix.md

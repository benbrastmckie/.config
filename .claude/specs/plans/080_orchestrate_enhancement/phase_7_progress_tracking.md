# Phase 7: Progress Tracking - Automated Reminders and Spec Updates

## Metadata
- **Phase Number**: 7
- **Complexity**: 8/10
- **Dependencies**: depends_on: [phase_0, phase_6]
- **Estimated Duration**: 4-5 hours
- **Expansion Reason**: Multi-level integration, hierarchical state propagation, and cross-agent coordination

## Overview

This phase implements comprehensive progress tracking with automated reminders for plan updates, git commits, and spec-updater integration. The system ensures that implementation progress is consistently tracked across all plan hierarchy levels (L2 → L1 → L0), with standardized git commits and real-time progress visualization.

**Key Integration Points**:
- **expansion-specialist**: Injects progress reminders into expanded phase/stage files
- **plan-architect**: Injects reminders into initial Level 0 plans
- **implementation-executor**: Updates plan hierarchy and creates git commits after phase completion
- **spec-updater**: Maintains hierarchical checkbox consistency across all plan levels
- **git-commit-helper**: Generates standardized commit messages following project conventions

**Core Capabilities**:
1. Automated reminder injection at task and phase boundaries
2. Hierarchical checkbox propagation (stage → phase → main plan)
3. Standardized git commit message generation
4. Real-time progress visualization for [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md)
5. spec-updater integration for cross-reference integrity
6. Error handling for propagation failures and permission issues

## Stage 1: Inject Progress Reminders in expansion-specialist and plan-architect

**Objective**: Update expansion-specialist and plan-architect agents to automatically inject progress tracking reminders into all plan files (Level 0, Level 1, and Level 2).

**Reminder Injection Patterns**:

### Task-Level Reminders (Every 3-5 Tasks)

```markdown
<!-- PROGRESS CHECKPOINT (injected by expansion-specialist) -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to Level 0
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->
```

**Injection Frequency**: After every 3-5 tasks in expanded phase/stage files

### Phase Completion Checklist (End of Every Phase/Stage)

```markdown
## Phase Completion Checklist

**MANDATORY STEPS AFTER ALL PHASE TASKS COMPLETE**:

- [ ] **Mark all phase tasks as [x]** in this file
- [ ] **Update parent plan** with phase completion status
 - Use spec-updater: `mark_phase_complete` function
 - Verify hierarchy synchronization
- [ ] **Run full test suite**: `npm test` or per Testing Protocols in CLAUDE.md
 - Verify all tests passing
 - Debug failures before proceeding
- [ ] **Create git commit** with standardized message
 - Format: `feat(NNN): complete Phase N - [Phase Name]`
 - Include files modified in this phase
 - Verify commit created successfully
- [ ] **Create checkpoint**: Save progress to `.claude/data/checkpoints/`
 - Include: Plan path, phase number, completion status
 - Timestamp: ISO 8601 format
- [ ] **Invoke spec-updater**: Update cross-references and summaries
 - Verify bidirectional links intact
 - Update plan metadata with completion timestamp
```

**Injection Location**: At the end of every phase/stage file created by expansion-specialist

### Implementation Tasks

**Task 1.1: Update expansion-specialist agent to inject task-level reminders**

Update `.claude/agents/expansion-specialist.md` to add reminder injection logic:

```markdown
**STEP 3.5 (AFTER STEP 3, BEFORE STEP 4) - Inject Progress Tracking Reminders**

When creating expanded phase/stage files, YOU MUST inject progress reminders at regular intervals.

**Reminder Injection Algorithm**:

1. Count total tasks in expanded phase/stage content
2. Calculate reminder frequency: Every 3-5 tasks
3. Insert task-level reminder checkpoints
4. Insert phase completion checklist at end

**Task-Level Reminder Template**:
```markdown
<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Update parent plan: Propagate progress to hierarchy
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->
\```

**Phase Completion Checklist Template**:
[Use full template from Stage 1 above]

**Injection Points**:
- After tasks 3-5, 8-10, 13-15, etc. (every 3-5 tasks)
- At end of phase/stage file (completion checklist)
```

- [ ] Read current expansion-specialist.md content
- [ ] Add STEP 3.5 section for reminder injection
- [ ] Define task-level reminder template
- [ ] Define phase completion checklist template
- [ ] Add injection algorithm logic
- [ ] Test expansion-specialist creates reminders correctly

**Task 1.2: Update plan-architect agent to inject reminders in Level 0 plans**

Level 0 plans (initial plans before expansion) also need progress tracking reminders.

Update `.claude/agents/plan-architect.md`:

```markdown
**STEP 4.5 (AFTER STEP 4, BEFORE STEP 5) - Inject Progress Tracking Reminders**

Even Level 0 plans (not yet expanded) need progress tracking reminders for direct implementation.

**For each phase in Level 0 plan**:

1. Count tasks in phase
2. If tasks > 5: Insert task-level reminder after every 5 tasks
3. Insert phase completion checklist at end of phase section

**Level 0 Phase Completion Reminder**:
```markdown
**Phase N Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite)
- [ ] Git commit created: `feat(NNN): complete Phase N - [Name]`
- [ ] Checkpoint saved (if complex phase)
\```

**Injection is MANDATORY** - Do not create plans without progress reminders.
```

- [ ] Read current plan-architect.md content
- [ ] Add STEP 4.5 section for reminder injection
- [ ] Define Level 0 reminder templates (simpler than Level 1/2)
- [ ] Add validation: Verify reminders present before returning plan
- [ ] Test plan-architect creates plans with reminders

**Task 1.3: Test reminder injection end-to-end**

- [ ] Create test plan with /plan command
- [ ] Verify Level 0 plan includes phase completion reminders
- [ ] Expand high-complexity phase with expansion-specialist
- [ ] Verify Level 1 phase file includes task-level checkpoints (every 3-5 tasks)
- [ ] Verify Level 1 phase file includes completion checklist
- [ ] Count reminder frequency: Should be every 3-5 tasks
- [ ] Verify reminder templates follow exact format from Stage 1

**Testing Commands**:
```bash
# Test Level 0 reminder injection
/plan "Simple feature with 3 phases"
grep -A 5 "Phase.*Completion" specs/NNN_topic/NNN_topic.md
# Expected: Phase completion reminders for all phases

# Test Level 1 reminder injection
# (Requires high-complexity phase for automatic expansion)
/plan "Complex authentication system with database, API, JWT, testing"
# Verify Phase 2 expanded (complexity likely >8)
grep -A 5 "PROGRESS CHECKPOINT" specs/NNN_topic/plans/NNN_plan/phase_2*.md
# Expected: Multiple progress checkpoints throughout phase file

# Count reminder frequency
TASK_COUNT=$(grep -c "^\- \[ \]" phase_2*.md)
CHECKPOINT_COUNT=$(grep -c "PROGRESS CHECKPOINT" phase_2*.md)
echo "Tasks: $TASK_COUNT, Checkpoints: $CHECKPOINT_COUNT"
# Expected: Approximately 1 checkpoint per 3-5 tasks
```

**Expected Outcomes**:
- All plans created include progress reminders
- Reminder frequency: Every 3-5 tasks in expanded phases
- Phase completion checklists present in all phase files
- Reminders follow standardized format

---

## Stage 2: Create git-commit-helper Agent

**Objective**: Implement git-commit-helper agent to generate standardized commit messages following project conventions.

**Commit Message Format Standards**:

```
Stage completion (L2): feat(NNN): complete Phase N Stage M - [Stage Name]
Phase completion (L1): feat(NNN): complete Phase N - [Phase Name]
Plan completion (L0): feat(NNN): complete [Feature Name]

Examples:
- feat(027): complete Phase 2 Stage 1 - Database Schema
- feat(027): complete Phase 2 - Backend Implementation
- feat(027): complete authentication system implementation
```

**Standard Format**:
- **Prefix**: `feat(NNN):` where NNN is topic number
- **Action**: `complete` for phase/stage/plan completion
- **Scope**: Phase/Stage number and name
- **No emojis**: Follow CLAUDE.md character encoding standards

### Implementation Tasks

**Task 2.1: Create git-commit-helper agent file**

Create `.claude/agents/git-commit-helper.md`:

```markdown
---
allowed-tools: Read, Bash
description: Generates standardized git commit messages following project conventions
---

# Git Commit Helper Agent

**YOU MUST generate commit messages following these exact standards.**

## Role

Generate standardized, project-compliant git commit messages for phase, stage, and plan completions in orchestrated workflows.

## Input Format

YOU WILL receive:
```yaml
topic_number: "027"
completion_type: "phase" | "stage" | "plan"
phase_number: 2 (if applicable)
stage_number: 1 (if applicable)
name: "Backend Implementation"
feature_name: "authentication system" (if plan completion)
\```

## Output Format

YOU MUST return a single-line commit message in THIS EXACT FORMAT:

**For Stage Completion**:
```
feat(NNN): complete Phase N Stage M - [Stage Name]
\```

**For Phase Completion**:
```
feat(NNN): complete Phase N - [Phase Name]
\```

**For Plan Completion**:
```
feat(NNN): complete [feature name]
\```

## Standards Compliance

**MANDATORY RULES**:
1. NO emojis (UTF-8 encoding compliance)
2. Prefix ALWAYS `feat(NNN):`
3. Action verb ALWAYS `complete`
4. Capitalize Phase/Stage in scope
5. Use hyphen separator before name
6. Name in Title Case

**FORBIDDEN**:
- Emojis: ✓ ✗ 🎉 etc.
- Alternative prefixes: fix, chore, docs (use feat for completions)
- Lowercase phase/stage: "phase 2" (must be "Phase 2")
- Missing topic number: feat: complete... (must include (NNN))

## Example Invocations

**Input 1** (Stage Completion):
```yaml
topic_number: "042"
completion_type: "stage"
phase_number: 3
stage_number: 2
name: "API Endpoints"
\```

**Output 1**:
```
feat(042): complete Phase 3 Stage 2 - API Endpoints
\```

**Input 2** (Phase Completion):
```yaml
topic_number: "027"
completion_type: "phase"
phase_number: 5
name: "Testing and Validation"
\```

**Output 2**:
```
feat(027): complete Phase 5 - Testing and Validation
\```

**Input 3** (Plan Completion):
```yaml
topic_number: "080"
completion_type: "plan"
feature_name: "orchestrate command enhancement"
\```

**Output 3**:
```
feat(080): complete orchestrate command enhancement
\```

## Integration with Other Commands

**Called by**:
- implementation-executor (after phase/stage completion)
- orchestrator (after plan completion)

**Return Format**:
YOU MUST return ONLY the commit message (no additional text):
```
COMMIT_MESSAGE: [generated message]
\```

## Behavioral Guidelines

**DO**:
- Follow format exactly as specified
- Validate topic number is 3-digit format (001-999)
- Capitalize phase/stage names
- Return commit message only (no explanations)

**DO NOT**:
- Add emojis or special characters
- Deviate from format templates
- Add multi-line commit messages
- Include issue references (not needed for completions)

## Error Handling

**Missing Required Input**:
```bash
if [ -z "$TOPIC_NUMBER" ]; then
 echo "ERROR: topic_number required" >&2
 exit 1
fi
\```

**Invalid Completion Type**:
```bash
if [[ ! "$COMPLETION_TYPE" =~ ^(phase|stage|plan)$ ]]; then
 echo "ERROR: completion_type must be phase, stage, or plan" >&2
 exit 1
fi
\```

## Testing

```bash
# Test stage completion
echo "topic_number: 027
completion_type: stage
phase_number: 2
stage_number: 1
name: Database Schema" | git-commit-helper
# Expected: feat(027): complete Phase 2 Stage 1 - Database Schema

# Test phase completion
echo "topic_number: 042
completion_type: phase
phase_number: 3
name: Backend Implementation" | git-commit-helper
# Expected: feat(042): complete Phase 3 - Backend Implementation

# Test plan completion
echo "topic_number: 080
completion_type: plan
feature_name: authentication system" | git-commit-helper
# Expected: feat(080): complete authentication system
\```
```

- [ ] Create `.claude/agents/git-commit-helper.md` with above content
- [ ] Test agent with stage completion input
- [ ] Test agent with phase completion input
- [ ] Test agent with plan completion input
- [ ] Verify output format exactly matches standards
- [ ] Verify no emojis in output
- [ ] Test error handling for missing inputs

**Task 2.2: Create git-commit-helper invocation helper function**

Create utility function for easy invocation from other agents:

Add to `.claude/lib/git-utils.sh`:

```bash
#!/bin/bash

# Generate standardized commit message using git-commit-helper agent
generate_commit_message() {
 local topic_number="$1"
 local completion_type="$2" # phase|stage|plan
 local phase_number="$3"
 local stage_number="$4"
 local name="$5"
 local feature_name="$6"

 # Build YAML input
 local input="topic_number: \"$topic_number\"
completion_type: \"$completion_type\""

 if [ "$completion_type" = "stage" ]; then
  input="$input
phase_number: $phase_number
stage_number: $stage_number
name: \"$name\""
 elif [ "$completion_type" = "phase" ]; then
  input="$input
phase_number: $phase_number
name: \"$name\""
 elif [ "$completion_type" = "plan" ]; then
  input="$input
feature_name: \"$feature_name\""
 fi

 # Invoke git-commit-helper agent (simulated here, in real implementation use Task tool)
 # For now, generate directly following agent logic
 local commit_msg=""

 case "$completion_type" in
  stage)
   commit_msg="feat($topic_number): complete Phase $phase_number Stage $stage_number - $name"
   ;;
  phase)
   commit_msg="feat($topic_number): complete Phase $phase_number - $name"
   ;;
  plan)
   commit_msg="feat($topic_number): complete $feature_name"
   ;;
  *)
   echo "ERROR: Invalid completion_type: $completion_type" >&2
   return 1
   ;;
 esac

 echo "$commit_msg"
}

# Test function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
 # Test stage completion
 MSG=$(generate_commit_message "027" "stage" 2 1 "Database Schema")
 echo "Stage: $MSG"
 # Expected: feat(027): complete Phase 2 Stage 1 - Database Schema

 # Test phase completion
 MSG=$(generate_commit_message "042" "phase" 3 "" "Backend Implementation")
 echo "Phase: $MSG"
 # Expected: feat(042): complete Phase 3 - Backend Implementation

 # Test plan completion
 MSG=$(generate_commit_message "080" "plan" "" "" "" "authentication system"
 echo "Plan: $MSG"
 # Expected: feat(080): complete authentication system
fi
```

- [ ] Create `.claude/lib/git-utils.sh` with `generate_commit_message` function
- [ ] Test function with stage completion parameters
- [ ] Test function with phase completion parameters
- [ ] Test function with plan completion parameters
- [ ] Verify output matches git-commit-helper agent output
- [ ] Add error handling for invalid parameters

---

## Stage 3: Integrate git-commit-helper in implementation-executor

**Objective**: Update implementation-executor agent to invoke git-commit-helper and create git commits after phase completion.

**Current Behavior**: implementation-executor completes phase tasks but may not create standardized git commits.

**Target Behavior**: After phase completion, executor invokes git-commit-helper, gets formatted message, creates commit.

### Implementation Tasks

**Task 3.1: Add git-commit-helper invocation to implementation-executor**

Update `.claude/agents/implementation-executor.md` (or code-writer.md if used):

Add phase completion workflow section:

```markdown
## Phase Completion Workflow

**AFTER ALL PHASE TASKS COMPLETE** (MANDATORY SEQUENCE):

**STEP 1: Verify All Tests Passing**
```bash
# Run test suite per Testing Protocols in CLAUDE.md
TEST_RESULT=$(run_test_suite)
if [ $? -ne 0 ]; then
 error "Tests failing - cannot complete phase"
 invoke_debug_specialist
 exit 1
fi
\```

**STEP 2: Generate Commit Message**
```bash
# Extract topic number from plan path
TOPIC_NUM=$(basename "$(dirname "$PLAN_PATH")" | grep -oP '^\d{3}')

# Determine completion type and parameters
COMPLETION_TYPE="phase" # or "stage" if L2 execution
PHASE_NUM="${PHASE_NUMBER}"
PHASE_NAME="${PHASE_NAME}"

# Invoke git-commit-helper
source .claude/lib/git-utils.sh
COMMIT_MSG=$(generate_commit_message "$TOPIC_NUM" "$COMPLETION_TYPE" "$PHASE_NUM" "" "$PHASE_NAME")

echo "Generated commit message: $COMMIT_MSG"
\```

**STEP 3: Create Git Commit**
```bash
# Stage modified files
git add .

# Create commit with generated message
git commit -m "$COMMIT_MSG"

# Verify commit created
COMMIT_HASH=$(git rev-parse HEAD)
echo "✓ Git commit created: $COMMIT_HASH"
echo " Message: $COMMIT_MSG"
\```

**STEP 4: Update Plan Hierarchy** (See Stage 4)

**STEP 5: Create Checkpoint**
```bash
# Save checkpoint after successful phase completion
source .claude/lib/checkpoint-utils.sh
create_checkpoint "$PLAN_PATH" "$PHASE_NUM" "completed"
\```

**MANDATORY**: All 5 steps must complete successfully before returning to orchestrator.
```

- [ ] Read implementation-executor.md (or identify correct agent)
- [ ] Add phase completion workflow section
- [ ] Add git-commit-helper invocation logic
- [ ] Add git commit creation commands
- [ ] Add commit hash verification
- [ ] Test implementation-executor creates commits correctly

**Task 3.2: Test git commit creation in isolated environment**

- [ ] Create test plan with simple phase
- [ ] Invoke implementation-executor to complete phase
- [ ] Verify git commit created with correct message format
- [ ] Verify commit includes all modified files
- [ ] Extract commit hash and verify in git log
- [ ] Test multiple phases create separate commits

**Testing Commands**:
```bash
# Create test plan
/plan "Test git commits - Phase 1: Setup, Phase 2: Implementation, Phase 3: Testing"

# Execute Phase 1
# (implementation-executor would be invoked here)

# Verify commit created
git log -1 --oneline
# Expected: feat(NNN): complete Phase 1 - Setup

# Verify commit message format
git log -1 --pretty=format:"%s"
# Expected: Exact format from git-commit-helper
```

---

## Stage 4: Create spec-updater Integration for Hierarchical Updates

**Objective**: Integrate spec-updater agent invocation after phase completion to maintain hierarchical checkbox consistency.

**Integration Point**: After git commit, before checkpoint creation

**spec-updater Responsibilities**:
1. Update checkbox state in phase file (mark phase tasks complete)
2. Propagate checkbox updates to parent plans (L2 → L1 → L0)
3. Verify hierarchy synchronization across all levels
4. Update cross-references if paths changed

### Implementation Tasks

**Task 4.1: Add spec-updater invocation to implementation-executor**

Update implementation-executor phase completion workflow:

```markdown
**STEP 4: Update Plan Hierarchy** (AFTER STEP 3: Git Commit)

**CRITICAL**: Invoke spec-updater to maintain checkbox consistency across hierarchy.

**Invocation Pattern**:
```
Task {
 subagent_type: "general-purpose"
 description: "Update plan hierarchy after Phase ${PHASE_NUM} completion"
 prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/spec-updater.md

  You are acting as a Spec Updater Agent.

  Update plan hierarchy checkboxes after Phase ${PHASE_NUM} completion.

  Plan: ${PLAN_PATH}
  Phase: ${PHASE_NUM}
  All tasks in this phase have been completed successfully.

  Steps:
  1. Source checkbox utilities: source .claude/lib/checkbox-utils.sh
  2. Mark phase complete: mark_phase_complete "${PLAN_PATH}" ${PHASE_NUM}
  3. Verify consistency: verify_checkbox_consistency "${PLAN_PATH}" ${PHASE_NUM}
  4. Report: List all files updated (stage → phase → main plan)

  Expected output:
  - Confirmation of hierarchy update
  - List of updated files at each level
  - Verification that all levels are synchronized
}
\```

**Verify spec-updater Response**:
```bash
# Extract files updated from spec-updater response
UPDATED_FILES=$(echo "$SPEC_UPDATER_OUTPUT" | grep -oP 'Files updated:.*')

echo "✓ Plan hierarchy updated"
echo "$UPDATED_FILES"
\```

**Error Handling**:
```bash
# If spec-updater fails
if ! spec_updater_successful; then
 warn "Hierarchy update failed - manual verification needed"
 warn "Phase marked complete in phase file only"
 # Continue workflow (non-critical failure)
fi
\```
```

- [ ] Add spec-updater invocation to implementation-executor
- [ ] Use exact invocation pattern from spec-updater.md
- [ ] Add verification of spec-updater response
- [ ] Add error handling for spec-updater failures
- [ ] Test spec-updater updates hierarchy correctly

**Task 4.2: Test hierarchical checkbox propagation**

- [ ] Create Level 1 plan (expanded phases)
- [ ] Complete Phase 2 using implementation-executor
- [ ] Verify Phase 2 tasks marked [x] in phase file
- [ ] Verify Phase 2 marked [x] in Level 0 main plan
- [ ] Verify checkbox consistency with `verify_checkbox_consistency`
- [ ] Test spec-updater handles missing phase files gracefully

**Testing Commands**:
```bash
# Create expanded plan
/plan "Feature with complex Phase 2"
# (Phase 2 should be expanded automatically if complexity >8)

# Complete Phase 2
# (implementation-executor invoked)

# Verify hierarchy updated
grep -A 2 "### Phase 2:" specs/NNN_topic/NNN_topic.md
# Expected: Phase 2 section shows [x] for completed tasks

# Verify phase file updated
grep "\[x\]" specs/NNN_topic/plans/NNN_plan/phase_2*.md
# Expected: All tasks marked [x]

# Verify consistency
source .claude/lib/checkbox-utils.sh
verify_checkbox_consistency "specs/NNN_topic/NNN_topic.md" 2
# Expected: ✓ Hierarchy consistent
```

---

## Stage 5: Implement Hierarchical Checkbox Propagation

**Objective**: Ensure checkbox updates propagate correctly across all plan hierarchy levels (L2 → L1 → L0).

**Propagation Flow**:
```
Stage File (L2)     Phase File (L1)     Main Plan (L0)
stage_1_db.md      phase_2_backend.md   027_auth.md
[x] Task 1   ──────▶  [x] Stage 1  ──────▶ [x] Phase 2
[x] Task 2                    (auto-updated)
```

**Utilities Available**: `.claude/lib/checkbox-utils.sh`

**Functions Used**:
- `mark_phase_complete()` - Mark all phase tasks complete
- `propagate_checkbox_update()` - Propagate update to parents
- `verify_checkbox_consistency()` - Verify synchronization

### Implementation Tasks

**Task 5.1: Verify checkbox-utils.sh supports L2 propagation**

Current checkbox-utils.sh may only support L0 ↔ L1 propagation. Need L2 → L1 → L0.

- [ ] Read `.claude/lib/checkbox-utils.sh`
- [ ] Check if `propagate_checkbox_update` handles stage files (L2)
- [ ] If not supported: Add stage-to-phase propagation logic
- [ ] Test propagation: L2 stage update → L1 phase update → L0 main plan update

**Task 5.2: Add stage completion handling to spec-updater**

Update spec-updater to handle stage completions (L2):

```markdown
### Handling Stage Completions (Level 2)

**When invoked for stage completion**:

**Input**:
```yaml
plan_path: "specs/027_auth/027_auth.md"
phase_number: 2
stage_number: 1
\```

**Propagation Sequence**:
1. Mark stage complete in stage file: `stage_1_db.md`
2. Update phase file: `phase_2_backend.md` (mark Stage 1 [x])
3. Update main plan: `027_auth.md` (if all stages in phase complete, mark phase [x])

**Commands**:
```bash
# Get stage file path
STAGE_FILE=$(get_stage_file "$PLAN_PATH" "$PHASE_NUM" "$STAGE_NUM")

# Mark stage tasks complete
mark_stage_complete "$STAGE_FILE"

# Propagate to phase file
PHASE_FILE=$(get_phase_file "$PLAN_PATH" "$PHASE_NUM")
update_checkbox "$PHASE_FILE" "Stage $STAGE_NUM" "x"

# Propagate to main plan (if all stages complete)
if all_stages_complete "$PHASE_FILE"; then
 mark_phase_complete "$PLAN_PATH" "$PHASE_NUM"
fi
\```
```

- [ ] Add stage completion handling to spec-updater
- [ ] Test spec-updater with stage completion input
- [ ] Verify L2 → L1 → L0 propagation works
- [ ] Test partial stage completion (not all stages in phase complete)
- [ ] Test complete phase via stage completions

**Task 5.3: Test end-to-end hierarchical propagation**

- [ ] Create Level 2 plan (phase with expanded stages)
- [ ] Complete Stage 1 of Phase 2
- [ ] Verify Stage 1 marked [x] in stage file
- [ ] Verify Stage 1 marked [x] in phase file
- [ ] Verify main plan NOT yet updated (phase incomplete)
- [ ] Complete Stage 2 of Phase 2 (last stage)
- [ ] Verify Phase 2 NOW marked [x] in main plan
- [ ] Run `verify_checkbox_consistency` - should pass

**Testing Commands**:
```bash
# Create Level 2 plan (requires very high complexity)
# Manual setup: Create phase with 2 stages

# Complete Stage 1
# (implementation-executor for stage)

# Verify stage file
grep "\[x\]" specs/NNN/plans/NNN_plan/phase_2/stage_1*.md
# Expected: All tasks marked [x]

# Verify phase file shows Stage 1 complete
grep "Stage 1" specs/NNN/plans/NNN_plan/phase_2*.md
# Expected: [x] Stage 1 complete

# Verify main plan NOT yet complete (Stage 2 still pending)
grep "### Phase 2:" specs/NNN/NNN.md
# Expected: [ ] Phase 2 (not all stages complete)

# Complete Stage 2
# (implementation-executor for stage)

# NOW verify main plan shows Phase 2 complete
grep "### Phase 2:" specs/NNN/NNN.md
# Expected: [x] Phase 2 (all stages now complete)
```

---

## Stage 6: Add Progress Visualization to Orchestrator

**Objective**: Implement real-time progress visualization in orchestrator output to show implementation progress across parallel waves.

**Visualization Format**:
```
Implementation Progress:

Wave 1 (parallel):
 ├─ Phase 1: Setup     ████████████████████ 100% (15/15 tasks) ✓
 └─ Phase 3: Frontend   ████████░░░░░░░░░░░ 60% (12/20 tasks)

Wave 2 (waiting for Wave 1):
 ├─ Phase 2: Backend    ░░░░░░░░░░░░░░░░░░░░ 0% (not started)
 └─ Phase 4: Integration  ░░░░░░░░░░░░░░░░░░░░ 0% (not started)

Overall: 27/55 tasks complete (49%)
```

**Update Frequency**: Every time implementation-executor reports progress

### Implementation Tasks

**Task 6.1: Create progress visualization utility**

Create `.claude/lib/progress-dashboard.sh`:

```bash
#!/bin/bash

# Display real-time progress for parallel wave execution

display_progress_dashboard() {
 local plan_path="$1"

 echo ""
 echo "Implementation Progress:"
 echo ""

 # Parse wave structure from plan
 source .claude/lib/dependency-analyzer.sh
 local waves=$(build_wave_structure "$plan_path")

 local total_tasks=0
 local completed_tasks=0

 # For each wave
 for wave_num in $(echo "$waves" | jq -r '.[] | .wave_number'); do
  local phases=$(echo "$waves" | jq -r ".[] | select(.wave_number == $wave_num) | .phases[]")

  # Wave header
  if [ "$wave_num" -eq 1 ]; then
   echo "Wave $wave_num (parallel):"
  else
   echo ""
   echo "Wave $wave_num (waiting for Wave $((wave_num - 1))):"
  fi

  # For each phase in wave
  for phase in $phases; do
   local phase_num=$(echo "$phase" | grep -oP '\d+')
   local phase_name=$(get_phase_name "$plan_path" "$phase_num")

   # Get phase progress
   local phase_total=$(count_phase_tasks "$plan_path" "$phase_num")
   local phase_complete=$(count_completed_tasks "$plan_path" "$phase_num")
   local phase_percent=$((phase_complete * 100 / phase_total))

   # Progress bar (20 characters)
   local filled=$((phase_percent / 5))
   local empty=$((20 - filled))
   local bar=$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))

   # Status indicator
   local status=""
   if [ $phase_percent -eq 100 ]; then
    status=" ✓"
   elif [ $phase_percent -gt 0 ]; then
    status=""
   else
    status=" (not started)"
   fi

   echo " ├─ Phase $phase_num: $phase_name"
   echo "   $bar ${phase_percent}% ($phase_complete/$phase_total tasks)$status"

   total_tasks=$((total_tasks + phase_total))
   completed_tasks=$((completed_tasks + phase_complete))
  done
 done

 # Overall progress
 local overall_percent=$((completed_tasks * 100 / total_tasks))
 echo ""
 echo "Overall: $completed_tasks/$total_tasks tasks complete (${overall_percent}%)"
 echo ""
}

# Helper functions
get_phase_name() {
 local plan="$1"
 local phase_num="$2"
 grep -oP "### Phase $phase_num: \K.*" "$plan" | head -1
}

count_phase_tasks() {
 local plan="$1"
 local phase_num="$2"
 # Count checkboxes in phase section
 sed -n "/### Phase $phase_num:/,/### Phase $((phase_num + 1)):/p" "$plan" | grep -c "^\- \[ \]"
}

count_completed_tasks() {
 local plan="$1"
 local phase_num="$2"
 # Count checked checkboxes in phase section
 sed -n "/### Phase $phase_num:/,/### Phase $((phase_num + 1)):/p" "$plan" | grep -c "^\- \[x\]"
}
```

- [ ] Create `.claude/lib/progress-dashboard.sh` with visualization logic
- [ ] Implement `display_progress_dashboard` function
- [ ] Add helper functions for task counting
- [ ] Test visualization with simple plan (2 phases)
- [ ] Test visualization with parallel waves (3 phases, 2 in Wave 1)
- [ ] Verify progress bar rendering correct (20 characters)

**Task 6.2: Integrate progress dashboard into orchestrator**

Update `/orchestrate` command to call progress dashboard:

```markdown
**Phase 3: Implementation** (Wave-Based [Parallel Execution Pattern](../../../docs/concepts/patterns/parallel-execution.md))

**AFTER** invoking implementer-coordinator:

**Display Progress**:
```bash
# Initial display
source .claude/lib/progress-dashboard.sh
display_progress_dashboard "$PLAN_PATH"

# Monitor executor updates
while implementation_in_progress; do
 sleep 5 # Poll every 5 seconds
 clear
 display_progress_dashboard "$PLAN_PATH"
done

# Final display
display_progress_dashboard "$PLAN_PATH"
\```

**Progress Update Triggers**:
- Every 5 seconds during implementation
- After each phase completion
- After each wave completion
- At workflow end
```

- [ ] Update orchestrate.md to add progress visualization
- [ ] Add polling loop for real-time updates
- [ ] Test progress updates during implementation
- [ ] Verify visualization updates every 5 seconds
- [ ] Test final visualization shows 100% completion

**Task 6.3: Test progress visualization end-to-end**

- [ ] Create workflow with 3 phases (2 parallel, 1 sequential)
- [ ] Start /orchestrate workflow
- [ ] Verify initial progress dashboard shows 0% for all phases
- [ ] Monitor progress updates during implementation
- [ ] Verify Wave 1 phases update in parallel (both show progress)
- [ ] Verify Wave 2 phase starts only after Wave 1 complete
- [ ] Verify final progress shows 100% overall completion
- [ ] Test progress visualization with failed phase (progress stops)

---

## Testing Strategy

### Unit Testing

**Test 1: Reminder Injection**
```bash
# Test expansion-specialist injects reminders
/plan "Complex feature requiring expansion"
grep -c "PROGRESS CHECKPOINT" specs/NNN/plans/NNN_plan/phase_*.md
# Expected: Multiple checkpoints (1 per 3-5 tasks)
```

**Test 2: Git Commit Message Generation**
```bash
# Test git-commit-helper agent
source .claude/lib/git-utils.sh
MSG=$(generate_commit_message "027" "phase" 2 "" "Backend Implementation")
echo "$MSG"
# Expected: feat(027): complete Phase 2 - Backend Implementation
```

**Test 3: Hierarchical Checkbox Propagation**
```bash
# Test spec-updater propagation
source .claude/lib/checkbox-utils.sh
mark_phase_complete "specs/027/027_auth.md" 2
verify_checkbox_consistency "specs/027/027_auth.md" 2
# Expected: ✓ Hierarchy consistent
```

### Integration Testing

**Test 4: Phase Completion Workflow**
- Create plan with 2 phases
- Complete Phase 1 using implementation-executor
- Verify all 5 completion steps execute:
 1. Tests passing
 2. Git commit created with correct message
 3. Plan hierarchy updated (checkboxes propagated)
 4. Checkpoint saved
 5. spec-updater invoked successfully

**Test 5: Progress Visualization**
- Create plan with parallel phases
- Start implementation
- Monitor progress dashboard updates
- Verify real-time progress display
- Verify completion shows 100%

### Error Handling Testing

**Test 6: Propagation Failure Recovery**
```bash
# Simulate permission error
chmod -w specs/027/027_auth.md
# Run spec-updater
# Expected: Graceful failure, warning logged, workflow continues
```

**Test 7: Missing Utilities**
```bash
# Simulate missing checkbox-utils.sh
mv .claude/lib/checkbox-utils.sh .claude/lib/checkbox-utils.sh.bak
# Run implementation-executor
# Expected: Error message, fallback behavior, utility restored
```

---

## Expected Outcomes

**After Phase 7 Complete**:

1. **Reminder Injection**:
  - All expanded plans include progress checkpoints (every 3-5 tasks)
  - All plans include phase completion checklists
  - Level 0 plans include simplified reminders

2. **Git Commit Standardization**:
  - git-commit-helper agent generates consistent commit messages
  - All phase completions create git commits
  - Commit format: `feat(NNN): complete Phase N - [Name]`
  - No emojis (UTF-8 compliance)

3. **Hierarchical Checkbox Propagation**:
  - spec-updater maintains consistency across L2 → L1 → L0
  - Checkbox updates propagate automatically
  - `verify_checkbox_consistency` passes for all phases

4. **Progress Visualization**:
  - Real-time progress dashboard during implementation
  - Wave-based progress display (parallel vs sequential)
  - Overall completion percentage tracked

5. **Integration Success**:
  - All 6 critical gaps from TODO.md addressed
  - Progress tracking complete across all workflow phases
  - /orchestrate enhancement Phase 7 complete

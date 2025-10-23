# Phase 3: Remove Phase 4 (Plan Expansion) - Detailed Specification

## Metadata
- **Phase Number**: 3
- **Parent Plan**: /home/benjamin/.config/.claude/specs/070_orchestrate_refactor/plans/001_orchestrate_simplification.md
- **Objective**: Remove automatic plan expansion infrastructure from /orchestrate and transfer expansion capabilities to /expand command
- **Complexity**: High (8.0/10)
- **Estimated Duration**: 90-120 minutes
- **Status**: PENDING

## Overview

This phase removes the 470-line Phase 4 (Plan Expansion) section from orchestrate.md, transfers expansion logic to the /expand command, and updates the Phase 2→Phase 3 transition to invoke /expand via SlashCommand tool when users choose to expand their plans. This represents the second major reduction in orchestrate.md (following Phase 2's removal of Phase 2.5).

**Current State**:
- orchestrate.md: 6,356 lines total
- Phase 4 section: Lines 2581-2800+ (approximately 470 lines)
- Automatic expansion: Phase 2.5 (complexity evaluation) → Phase 4 (expansion-specialist invocation)
- /expand command: 1,073 lines with basic expansion capabilities

**Target State**:
- orchestrate.md: ~5,886 lines (470-line reduction)
- Phase 4 section: Completely removed
- Phase 2→3 transition: User prompt + optional /expand invocation via SlashCommand
- /expand command: Enhanced with Phase 0 (Complexity Evaluation) and Phase 4 expansion patterns

**Key Changes**:
1. Delete entire Phase 4 section from orchestrate.md
2. Add Phase 0 to /expand for complexity evaluation
3. Transfer expansion-specialist agent invocation template to /expand
4. Transfer recursive expansion logic to /expand
5. Update orchestrate Phase 2 completion to offer optional expansion
6. Remove all Phase 4 references from workflow state, checkpoints, TodoWrite
7. Update phase number references (Phase 5→3, Phase 6→4, Phase 7→5)

## Architecture Analysis

### Current Phase 4 Structure (Lines 2581-2800+)

**Section Breakdown**:
```
Line 2581-2600:  Phase 4 header and conditional execution logic
Line 2600-2632:  Step 1 - Verify expansion requirements
Line 2633-2758:  Step 2 - Invoke expansion-specialist agent (125 lines of template)
Line 2759-2800:  Step 3 - Validate expansion results
Line 2801-2850:  Step 4 - Extract expansion metrics
Line 2851-2900:  Step 5 - Verify file creation
Line 2901-2950:  Step 6 - Update workflow state
Line 2951-3000:  Step 7 - Display expansion summary
Line 3001-3050:  Error recovery and fallback mechanisms
```

**Content Classification**:
- **Execution-critical** (must transfer to /expand):
  - expansion-specialist agent invocation template (lines 2639-2758)
  - File creation verification patterns (lines 2851-2900)
  - Recursive expansion logic (embedded in agent prompt)
  - Expansion artifact validation

- **Orchestrate-specific** (must adapt for Phase 2→3 transition):
  - Workflow state variables (WORKFLOW_STATE_EXPANSION_PENDING)
  - Conditional branching from Phase 2.5
  - Phase numbering logic

- **Removable** (orchestration overhead):
  - Phase 4 progress markers
  - Phase 4 TodoWrite entries
  - Phase 4 checkpoint operations
  - Complexity threshold loading (already in Phase 2.5, which was removed)

### /expand Command Current Structure

**Current Capabilities** (1,073 lines):
- Auto-Analysis Mode: Invoke complexity-estimator, then expansion-specialist
- Explicit Mode: Direct phase/stage expansion
- Phase expansion (Level 0→1): Create separate phase files
- Stage expansion (Level 1→2): Create separate stage files
- Metadata coordination across hierarchy levels
- Cross-reference verification via spec-updater

**Missing Capabilities** (to be added from Phase 4):
- Phase 0: Complexity Evaluation (currently complexity-estimator invoked in Phase 2)
- Recursive expansion logic (expand generated phase files if warranted)
- Expansion verification patterns from Phase 4
- Advanced fallback mechanisms for agent failures
- Workflow state integration for coordinated operations

**Integration Point**:
- /expand already has agent invocation infrastructure
- Need to add Phase 0 before current Phase 1
- Current "Phase 1: Setup and Discovery" becomes "Phase 1: Validation and Setup"
- Insert new "Phase 0: Complexity Evaluation" at beginning

## Implementation Steps

### Step 1: Read and Analyze Phase 4 Content

**EXECUTE NOW - Extract Phase 4 Section**:

```bash
# Read Phase 4 section completely
READ_START=2581
READ_END=3100  # Conservative estimate, may extend further

# Extract to temporary file for analysis
PHASE_4_CONTENT=$(sed -n "${READ_START},${READ_END}p" /home/benjamin/.config/.claude/commands/orchestrate.md)

# Verify extraction captured complete section
if ! echo "$PHASE_4_CONTENT" | grep -q "## Phase 4: Plan Expansion"; then
  echo "ERROR: Phase 4 header not found in extraction"
  exit 1
fi

# Find actual end of Phase 4 (next ## heading or EOF)
ACTUAL_END=$(echo "$PHASE_4_CONTENT" | grep -n "^## Phase 5:" | head -1 | cut -d: -f1)
if [ -z "$ACTUAL_END" ]; then
  # No Phase 5 found, check for Phase 6 or other section
  ACTUAL_END=$(echo "$PHASE_4_CONTENT" | grep -n "^## " | tail -1 | cut -d: -f1)
fi

echo "✓ Phase 4 content extracted: $READ_START to $((READ_START + ACTUAL_END)) ($(($ACTUAL_END)) lines)"
```

**MANDATORY VERIFICATION - Phase 4 Boundaries Identified**:

```bash
# Verify we have complete Phase 4 section
if [ -z "$PHASE_4_CONTENT" ]; then
  echo "❌ ERROR: Phase 4 content empty"
  exit 1
fi

# Count lines
PHASE_4_LINE_COUNT=$(echo "$PHASE_4_CONTENT" | wc -l)
if [ "$PHASE_4_LINE_COUNT" -lt 400 ]; then
  echo "⚠️  WARNING: Phase 4 section smaller than expected ($PHASE_4_LINE_COUNT lines < 400)"
fi

echo "✓ VERIFIED: Phase 4 section identified ($PHASE_4_LINE_COUNT lines)"
```

### Step 2: Extract Valuable Content for /expand Enhancement

**EXECUTE NOW - Identify Transferable Patterns**:

Extract these specific elements from Phase 4 for transfer to /expand:

**2.1 - expansion-specialist Agent Invocation Template** (lines 2639-2758):

```yaml
# This EXACT template must be transferred to /expand command
# Location in /expand: New Phase 1 (after new Phase 0: Complexity Evaluation)

subagent_type: general-purpose

description: "Expand high-complexity phases based on complexity analysis"

timeout: 180000  # 3 minutes for expansion operations

prompt: |
  Read and follow the behavioral guidelines from:
  ${CLAUDE_PROJECT_DIR}/.claude/agents/expansion-specialist.md

  You are acting as an Expansion Specialist Agent.

  EXPANSION TASK: Recursive Plan Expansion

  CONTEXT:
  - Plan Path: ${IMPLEMENTATION_PLAN_PATH}
  - Complexity Report: Available from Phase 0
  - Phases to expand: ${PHASES_TO_EXPAND[@]}
  - Expansion threshold: ${EXPANSION_THRESHOLD}
  - Task count threshold: ${TASK_COUNT_THRESHOLD}
  - Max depth: 2 (Level 0 → 1 → 2)
  - Current structure level: 0 (inline phases)

  YOUR TASK:
  1. For each phase in expansion list:
     - Expand phase to Level 1 (separate file with stages)
     - Re-evaluate complexity of expanded phase
     - If any stages exceed threshold, expand to Level 2
  2. Respect max depth limit (no Level 3 expansion)
  3. Create expansion artifacts for each operation
  4. Update parent plans with summaries and references
  5. Maintain cross-reference integrity
  6. Return expansion summary report

  EXPANSION WORKFLOW:
  [Full workflow steps from lines 2674-2707]

  RECURSIVE EVALUATION:
  - After expanding each phase, re-evaluate complexity of expanded content
  - If any stages exceed ${EXPANSION_THRESHOLD}, expand to Level 2
  - Maximum 2 expansion attempts per item (loop prevention)

  REQUIRED OUTPUT:
  [Full YAML schema from lines 2713-2757]
```

**Transfer Instructions**:
1. Copy entire agent template to /expand command
2. Place in new Phase 1 section (after Phase 0: Complexity Evaluation)
3. Adapt context variables to /expand's workflow state
4. Update prompt to reference Phase 0 results instead of Phase 2.5

**2.2 - Recursive Expansion Logic** (lines 2708-2711):

```bash
# This logic must be added to /expand command's Phase 1

# After expanding each phase, re-evaluate complexity of expanded content
# If any stages exceed ${EXPANSION_THRESHOLD}, expand to Level 2
# Maximum 2 expansion attempts per item (loop prevention)

# Implementation in /expand:
for PHASE_FILE in "${CREATED_PHASE_FILES[@]}"; do
  # Re-analyze expanded phase file
  STAGE_COMPLEXITY=$(analyze_stage_complexity "$PHASE_FILE")

  # If stages exceed threshold, trigger Stage expansion
  if [ "$STAGE_COMPLEXITY" -gt "$EXPANSION_THRESHOLD" ]; then
    echo "Recursive expansion triggered: Stage complexity $STAGE_COMPLEXITY > $EXPANSION_THRESHOLD"

    # Invoke /expand stage recursively (via SlashCommand or direct execution)
    /expand stage "$PHASE_FILE" "$STAGE_NUM"
  fi
done
```

**Transfer Instructions**:
1. Add recursive expansion capability to /expand Phase 1
2. Use complexity-utils.sh for stage complexity analysis
3. Implement loop prevention counter (max 2 recursions per item)
4. Log recursive expansion events to adaptive-planning.log

**2.3 - Expansion Verification Patterns** (lines 2760-2850):

```bash
# File creation verification with fallback (must transfer to /expand)

# Verify expansion-specialist produced valid output
if [ -z "$EXPANSION_SPECIALIST_OUTPUT" ]; then
  echo "ERROR: expansion-specialist agent returned empty output"
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
  echo "ERROR: expansion-specialist output missing 'expansion_summary:' field"
  echo "FALLBACK: Proceeding with fallback expansion summary"
  EXPANSION_FAILED=true
fi
```

**Transfer Instructions**:
1. Add this verification checkpoint to /expand Phase 2 (after agent invocation)
2. Create fallback expansion summary in specs/artifacts/ directory
3. Set EXPANSION_FAILED flag for error handling
4. Continue workflow even if agent fails (graceful degradation)

**2.4 - Extract Metrics and Files Created** (lines 2801-2900):

```bash
# Parse expansion results from YAML output

FILES_CREATED=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -A 50 "files_created:" | grep "^ *- " | sed 's/^ *- *//' | tr '\n' ' ')
FILES_MODIFIED=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -A 50 "files_modified:" | grep "^ *- " | sed 's/^ *- *//' | tr '\n' ' ')
ARTIFACTS_CREATED=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep -A 50 "artifacts_created:" | grep "^ *- " | sed 's/^ *- *//' | tr '\n' ' ')

FINAL_STRUCTURE_LEVEL=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep "structure_level:" | tail -1 | grep -oE "[0-9]+")
EXPANDED_PHASES=$(echo "$EXPANSION_SPECIALIST_OUTPUT" | grep "expanded_phases:" | grep -oE "\[[0-9, ]*\]")

# Verify all expected files exist
for FILE in $FILES_CREATED; do
  if [ ! -f "$FILE" ]; then
    echo "⚠️  WARNING: Expected file not created: $FILE"
    VERIFICATION_WARNINGS+=("File not created: $FILE")
  fi
done

echo "✓ Expansion metrics extracted:"
echo "  Files created: $(echo "$FILES_CREATED" | wc -w)"
echo "  Files modified: $(echo "$FILES_MODIFIED" | wc -w)"
echo "  Artifacts: $(echo "$ARTIFACTS_CREATED" | wc -w)"
echo "  Final structure level: $FINAL_STRUCTURE_LEVEL"
```

**Transfer Instructions**:
1. Add metric extraction to /expand Phase 2
2. Verify all files created by expansion-specialist
3. Collect warnings for files not found
4. Report comprehensive expansion summary to user

### Step 3: Extract Supplemental Content for Reference Files

**EXECUTE NOW - Identify Reference Content**:

Extract these sections for shared reference documentation:

**3.1 - Extended Expansion Examples** → `shared/orchestration-alternatives.md`:

```markdown
# Orchestration Workflow Alternatives

## Expansion Strategies

### Automatic Expansion (Removed in 070 Refactor)
Previously, /orchestrate automatically expanded plans when complexity thresholds were exceeded.
This approach was removed to enhance user control and simplify the command architecture.

**How it worked**:
1. Phase 2.5: complexity-estimator evaluated all phases
2. Phase 4: expansion-specialist expanded high-complexity phases
3. Automatic transition to hierarchical plan structure

**Why it was removed**:
- Removed user agency (no choice to expand or not)
- Over-engineered for most use cases
- Created confusion about which command was responsible for expansion
- Violated command architecture standards (commands should do one thing well)

### Manual Expansion (Current Approach)
Users now explicitly choose when to expand plans via /expand command.

**Workflow**:
1. /orchestrate Phase 2 completes (plan created)
2. User presented with expansion option (AskUserQuestion)
3. If user chooses "Yes": Invoke /expand command via SlashCommand
4. /expand performs complexity evaluation and expansion
5. Return to /orchestrate Phase 3 (Implementation) with expanded plan

**Benefits**:
- User maintains full control over expansion
- Clear separation of concerns (/orchestrate = workflow, /expand = structure)
- Simplified command architecture
- Easier to understand and debug

### Alternative Strategies

**Progressive Expansion During Implementation**:
Expand phases on-demand as implementation reaches high-complexity sections.

**Threshold-Based Prompting**:
Display expansion recommendation to user when complexity detected, but don't force decision.

**Hybrid Approach**:
Automatic expansion for very high complexity (>10), optional for medium complexity (8-10).
```

### Step 4: Remove Phase 4 Section from orchestrate.md

**EXECUTE NOW - Delete Phase 4 Content**:

```bash
# Locate exact boundaries of Phase 4
PHASE_4_START=$(grep -n "^## Phase 4: Plan Expansion" /home/benjamin/.config/.claude/commands/orchestrate.md | cut -d: -f1)
PHASE_4_END=$(grep -n "^## Phase 5:" /home/benjamin/.config/.claude/commands/orchestrate.md | head -1 | cut -d: -f1)

if [ -z "$PHASE_4_START" ]; then
  echo "ERROR: Phase 4 start not found"
  exit 1
fi

if [ -z "$PHASE_4_END" ]; then
  # No Phase 5, find next major section
  PHASE_4_END=$(grep -n "^## " /home/benjamin/.config/.claude/commands/orchestrate.md | awk -v start="$PHASE_4_START" '$1 > start' | head -1 | cut -d: -f1)
fi

# Calculate lines to delete
PHASE_4_LINES=$((PHASE_4_END - PHASE_4_START))

echo "Phase 4 boundaries identified:"
echo "  Start: Line $PHASE_4_START"
echo "  End: Line $PHASE_4_END"
echo "  Lines to delete: $PHASE_4_LINES"

# Delete Phase 4 section
sed -i "${PHASE_4_START},$((PHASE_4_END - 1))d" /home/benjamin/.config/.claude/commands/orchestrate.md

echo "✓ Phase 4 section deleted from orchestrate.md"
```

**MANDATORY VERIFICATION - Phase 4 Completely Removed**:

```bash
# Verify Phase 4 section removed
if grep -q "^## Phase 4: Plan Expansion" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "❌ ERROR: Phase 4 header still exists"
  exit 1
fi

# Verify no expansion-specialist invocations remain
if grep -q "expansion-specialist" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "⚠️  WARNING: expansion-specialist references still exist"
  grep -n "expansion-specialist" /home/benjamin/.config/.claude/commands/orchestrate.md
fi

# Verify line count reduced
CURRENT_LINES=$(wc -l < /home/benjamin/.config/.claude/commands/orchestrate.md)
EXPECTED_MAX=5900  # 6356 - 470 = 5886 + buffer

if [ "$CURRENT_LINES" -gt "$EXPECTED_MAX" ]; then
  echo "⚠️  WARNING: Line count higher than expected ($CURRENT_LINES > $EXPECTED_MAX)"
fi

echo "✓ VERIFIED: Phase 4 removed, line count reduced to $CURRENT_LINES"
```

### Step 5: Update /expand Command with Phase 0 and Phase 4 Logic

**EXECUTE NOW - Enhance /expand with Complexity Evaluation**:

**5.1 - Insert Phase 0: Complexity Evaluation**:

Location in /expand.md: After line 558 (before "### Phase 1: Setup and Discovery")

Content to insert is documented in the expansion-specialist agent output (see Step 2.1 above).

Key components:
- Load complexity thresholds from CLAUDE.md
- Invoke complexity-estimator agent via Task tool
- Validate complexity report output
- Extract complexity metrics (phases_to_expand, expansion_count, etc.)
- Create checkpoint after Phase 0 completion

**5.2 - Update Phase 1 with Recursive Expansion Logic**:

Location in /expand.md: Inside "#### Phase 1: Validation and Expansion" section (after expansion-specialist invocation)

Insert recursive expansion evaluation logic (see Step 2.2 above).

Key components:
- Analyze stage complexity after phase expansion
- Check if stages exceed expansion threshold
- Implement recursion counter (max 2 recursions)
- Invoke /expand stage for high-complexity stages
- Log recursive expansion events

### Step 6: Remove Phase 4 References from orchestrate.md

**EXECUTE NOW - Update Phase Number References**:

**6.1 - Remove Phase 4 from Conditional Branching**:

```bash
# Verify no Phase 4 branching logic
if grep -q "PROCEEDING TO: Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "⚠️  WARNING: Phase 4 branching logic still exists"
  grep -n "PROCEEDING TO: Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md

  # Remove these references
  sed -i '/PROCEEDING TO: Phase 4/d' /home/benjamin/.config/.claude/commands/orchestrate.md
fi

# Verify no expansion pending checks
if grep -q "WORKFLOW_STATE_EXPANSION_PENDING" /home/benjamin/.config/.claude/commands/orchestrate.md; then
  echo "⚠️  WARNING: Expansion pending state variable still referenced"
  grep -n "WORKFLOW_STATE_EXPANSION_PENDING" /home/benjamin/.config/.claude/commands/orchestrate.md

  # Remove these references
  sed -i '/WORKFLOW_STATE_EXPANSION_PENDING/d' /home/benjamin/.config/.claude/commands/orchestrate.md
fi

echo "✓ Conditional branching to Phase 4 removed"
```

**6.2 - Remove TodoWrite Phase 4 Items**:

```bash
# Find TodoWrite calls referencing Phase 4
TODOWRITE_PHASE4=$(grep -n "Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md | grep -i "todo\|task")

if [ -n "$TODOWRITE_PHASE4" ]; then
  echo "TodoWrite Phase 4 references found:"
  echo "$TODOWRITE_PHASE4"

  # Manual review required: Update TodoWrite calls to remove Phase 4 items
fi

# Verify TodoWrite phase sequence
grep -A 20 "TodoWrite" /home/benjamin/.config/.claude/commands/orchestrate.md | grep "content:" | grep "Phase"
```

**6.3 - Update Workflow State Variables**:

```bash
# Remove Phase 4-specific workflow state variables
sed -i '/WORKFLOW_STATE_EXPANSION_COUNT/d' /home/benjamin/.config/.claude/commands/orchestrate.md
sed -i '/WORKFLOW_STATE_PHASES_TO_EXPAND/d' /home/benjamin/.config/.claude/commands/orchestrate.md
sed -i '/WORKFLOW_STATE_AVERAGE_COMPLEXITY/d' /home/benjamin/.config/.claude/commands/orchestrate.md
sed -i '/WORKFLOW_STATE_MAX_COMPLEXITY/d' /home/benjamin/.config/.claude/commands/orchestrate.md

echo "✓ Workflow state variables cleaned"
```

**6.4 - Remove Checkpoint Phase 4 Operations**:

```bash
# Remove checkpoint creation for Phase 4
sed -i '/CHECKPOINT.*Phase 4/d' /home/benjamin/.config/.claude/commands/orchestrate.md
sed -i '/checkpoint.*expansion/d' /home/benjamin/.config/.claude/commands/orchestrate.md

echo "✓ Checkpoint references to Phase 4 removed"
```

**6.5 - Update Error Messages**:

```bash
# Find error messages referencing Phase 4
grep -n "Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md | grep -i "error\|warning\|failed"

# Update error messages to reflect new phase numbering
# (Manual review required for context-specific updates)
```

### Step 7: Update Phase 2→Phase 3 Transition

**EXECUTE NOW - Add User Prompt for Expansion**:

Location in orchestrate.md: After Phase 2 completion checkpoint (find "## Phase 2 Complete")

Insert new section between Phase 2 completion and Phase 3 start with:
- Quick complexity assessment (inline, no agent)
- AskUserQuestion for expansion choice
- Conditional /expand invocation via SlashCommand
- Fallback handling if /expand fails
- Checkpoint after user decision

See detailed implementation in expanded specification output above.

## Testing Specifications

### Test 1: Phase 4 Removal Verification

**Objective**: Verify Phase 4 section completely removed from orchestrate.md

```bash
# Test 1.1: Phase 4 header removed
! grep -q "## Phase 4: Plan Expansion" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 1.1 passed: Phase 4 header removed"

# Test 1.2: expansion-specialist invocations removed from orchestrate
! grep -q "expansion-specialist" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 1.2 passed: No expansion-specialist invocations in orchestrate"

# Test 1.3: Workflow state variables removed
! grep -q "WORKFLOW_STATE_EXPANSION_PENDING" /home/benjamin/.config/.claude/commands/orchestrate.md
! grep -q "WORKFLOW_STATE_PHASES_TO_EXPAND" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 1.3 passed: Expansion workflow state variables removed"

# Test 1.4: Line count reduction achieved
CURRENT_LINES=$(wc -l < /home/benjamin/.config/.claude/commands/orchestrate.md)
[ "$CURRENT_LINES" -lt 5900 ] && echo "✓ Test 1.4 passed: Line count reduced to $CURRENT_LINES"
```

### Test 2: /expand Enhancement Verification

**Objective**: Verify /expand command enhanced with Phase 0 and Phase 4 logic

```bash
# Test 2.1: Phase 0 (Complexity Evaluation) added to /expand
grep -q "Phase 0: Complexity Evaluation" /home/benjamin/.config/.claude/commands/expand.md
echo "✓ Test 2.1 passed: Phase 0 added to /expand"

# Test 2.2: complexity-estimator invocation present in /expand Phase 0
grep -q "complexity-estimator" /home/benjamin/.config/.claude/commands/expand.md
echo "✓ Test 2.2 passed: complexity-estimator invoked in /expand"

# Test 2.3: Recursive expansion logic added to /expand
grep -q "Recursive expansion" /home/benjamin/.config/.claude/commands/expand.md
echo "✓ Test 2.3 passed: Recursive expansion logic present"

# Test 2.4: expansion-specialist invocation template transferred
grep -A 50 "expansion-specialist" /home/benjamin/.config/.claude/commands/expand.md | grep -q "EXPANSION TASK: Recursive Plan Expansion"
echo "✓ Test 2.4 passed: expansion-specialist template transferred"
```

### Test 3: Phase 2→3 Transition Verification

**Objective**: Verify user control added after Phase 2

```bash
# Test 3.1: AskUserQuestion added after Phase 2
grep -q "Would you like to expand this plan" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 3.1 passed: Expansion prompt added"

# Test 3.2: /expand invocation via SlashCommand
grep -q "/expand.*IMPLEMENTATION_PLAN_PATH" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 3.2 passed: /expand invocation present"

# Test 3.3: Skip expansion path exists
grep -q "No - proceed to implementation" /home/benjamin/.config/.claude/commands/orchestrate.md
echo "✓ Test 3.3 passed: Skip expansion option available"
```

### Test 4: Execution Test (Manual)

**Objective**: Verify /orchestrate executes successfully with new workflow

Manual test procedure:
1. Run /orchestrate with simple feature request
2. Verify 6 phases execute: 0 (Location), 1 (Research), 2 (Planning), 2.5 (Review), 3 (Implementation)
3. At Phase 2.5, select "No - proceed to implementation"
4. Verify Phase 3 (Implementation) starts without expansion
5. Verify no errors related to Phase 4 or expansion

Expected output:
- No "Phase 4: Plan Expansion" section appears
- User prompt for expansion appears after Phase 2
- Implementation proceeds directly if expansion skipped

### Test 5: Standards Compliance Test

**Objective**: Verify execution-critical content remains inline

```bash
# Test 5.1: Critical warnings preserved
CRITICAL_COUNT=$(grep -c "CRITICAL:" /home/benjamin/.config/.claude/commands/orchestrate.md)
[ "$CRITICAL_COUNT" -ge 8 ] && echo "✓ Test 5.1 passed: Critical warnings preserved ($CRITICAL_COUNT)"

# Test 5.2: Agent invocation templates complete
AGENT_TEMPLATES=$(grep -c "subagent_type: general-purpose" /home/benjamin/.config/.claude/commands/orchestrate.md)
[ "$AGENT_TEMPLATES" -ge 4 ] && echo "✓ Test 5.2 passed: Agent templates complete ($AGENT_TEMPLATES)"

# Test 5.3: Execution blocks present
BASH_BLOCKS=$(grep -c '```bash' /home/benjamin/.config/.claude/commands/orchestrate.md)
[ "$BASH_BLOCKS" -ge 15 ] && echo "✓ Test 5.3 passed: Execution blocks preserved ($BASH_BLOCKS)"
```

## Architecture Decisions

### Decision 1: Transfer Expansion Logic to /expand vs Create New Command

**Chosen**: Transfer to /expand command

**Rationale**:
- /expand already has expansion infrastructure (agent invocation, file creation, metadata updates)
- Avoids proliferation of commands (simplicity principle)
- Clear separation of concerns: /orchestrate = workflow coordination, /expand = plan structure management
- Users already familiar with /expand for manual expansion

**Trade-offs**:
- /expand becomes slightly more complex with Phase 0 addition
- But: Complexity is justified by enhanced capabilities (automatic complexity evaluation)

### Decision 2: Inline Complexity Assessment vs Agent Invocation in Phase 2.5

**Chosen**: Inline complexity assessment (basic indicators only)

**Rationale**:
- Phase 2.5 is a user decision point, not an execution phase
- Simple metrics (phase count, task count) sufficient for user decision
- Full complexity analysis deferred to /expand Phase 0 if user chooses expansion
- Reduces orchestrate.md complexity and execution time

**Trade-offs**:
- Less sophisticated complexity evaluation in orchestrate
- But: Full analysis still available via /expand if user chooses

### Decision 3: AskUserQuestion vs Automatic Expansion Trigger

**Chosen**: AskUserQuestion (explicit user choice)

**Rationale**:
- Aligns with TODO3.md requirement: "restore user agency"
- Follows command architecture standards: avoid over-automation
- Users can skip expansion for simple features (performance benefit)
- Users can review plan before deciding (informed decision)

**Trade-offs**:
- One additional user interaction per orchestrate execution
- But: User control valued over automation convenience

### Decision 4: SlashCommand Invocation vs Direct Function Call

**Chosen**: SlashCommand tool invocation

**Rationale**:
- Maintains command independence (orchestrate doesn't directly depend on /expand internals)
- Cleaner separation of concerns
- Easier to test and debug (commands remain decoupled)
- Consistent with hierarchical agent architecture patterns

**Trade-offs**:
- Slightly higher overhead (SlashCommand tool invocation)
- But: Overhead negligible compared to expansion operation duration

## Error Handling Patterns

### Error 1: /expand Invocation Fails

**Scenario**: User chooses "Yes - expand now", but /expand command fails

**Handling**:
```bash
# Invoke /expand with error capture
EXPAND_RESULT=$(/expand "$IMPLEMENTATION_PLAN_PATH" 2>&1)
EXPAND_EXIT_CODE=$?

if [ "$EXPAND_EXIT_CODE" -ne 0 ]; then
  echo "⚠️  WARNING: /expand command failed"
  echo "Error output:"
  echo "$EXPAND_RESULT"
  echo ""
  echo "FALLBACK: Proceeding to Phase 3 with current plan structure"
  echo "Note: You can manually run /expand later if needed"
  echo ""

  # Continue workflow (graceful degradation)
  EXPANSION_FAILED=true
else
  echo "✓ Plan expansion successful"
  EXPANSION_FAILED=false
fi
```

**Recovery**: Proceed to implementation with current plan structure, user can manually expand later

### Error 2: Phase 4 References Remain After Deletion

**Scenario**: Some Phase 4 references not caught by deletion script

**Handling**:
```bash
# Post-deletion verification sweep
PHASE_4_REFS=$(grep -n "Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md | wc -l)

if [ "$PHASE_4_REFS" -gt 0 ]; then
  echo "⚠️  WARNING: $PHASE_4_REFS Phase 4 references remain"
  grep -n "Phase 4" /home/benjamin/.config/.claude/commands/orchestrate.md

  # Manual review required
  echo "Manual cleanup required for remaining Phase 4 references"
  exit 1
fi
```

**Recovery**: Manual review and removal of remaining references

### Error 3: /expand Phase 0 Complexity Analysis Fails

**Scenario**: complexity-estimator agent fails in /expand Phase 0

**Handling**: Fallback complexity report with conservative defaults, user presented with plan summary for manual decision

## Performance Considerations

### Optimization 1: Inline Complexity Assessment vs Full Analysis

**Impact**: Phase 2.5 inline assessment (simple grep/wc) completes in <1 second vs Phase 0 complexity-estimator agent (20-40 seconds)

**Benefit**: 95% of users who skip expansion save 20-40 seconds per orchestrate execution

**Trade-off**: Users who choose expansion incur full analysis cost in /expand Phase 0

### Optimization 2: Lazy Expansion (User Choice) vs Automatic Expansion

**Impact**: Eliminating automatic expansion reduces orchestrate.md execution time by 30-60 seconds for plans that would trigger expansion

**Benefit**: Simple features (no expansion needed) complete faster

**Trade-off**: Complex features require explicit user action to expand

### Optimization 3: File Size Reduction (470 lines)

**Impact**: Reduced orchestrate.md file size improves:
- Read time (fewer disk I/O operations)
- Parse time (less content to process)
- Token usage (fewer tokens in context window)

**Benefit**: Estimated 10-15% reduction in orchestrate command load time

## Integration Points

### Integration 1: orchestrate → /expand (SlashCommand)

**Flow**:
1. orchestrate Phase 2 completes (plan created)
2. orchestrate Phase 2.5 presents AskUserQuestion
3. User chooses "Yes - expand now"
4. orchestrate invokes `/expand $IMPLEMENTATION_PLAN_PATH` via SlashCommand tool
5. /expand Phase 0 runs complexity evaluation
6. /expand Phase 1 performs expansion operations
7. /expand completes, control returns to orchestrate
8. orchestrate proceeds to Phase 3 (Implementation) with expanded plan

**Contract**:
- orchestrate passes: Plan file path (absolute)
- /expand returns: Expansion summary (via stdout)
- Error handling: orchestrate catches /expand failures, proceeds with fallback

### Integration 2: /expand Phase 0 → complexity-estimator agent

**Flow**:
1. /expand Phase 0 loads complexity thresholds
2. /expand invokes complexity-estimator via Task tool
3. Agent analyzes plan and returns YAML complexity report
4. /expand Phase 0 validates report and extracts metrics
5. Phases requiring expansion identified for Phase 1

**Contract**:
- /expand passes: Plan path, thresholds, analysis mode
- Agent returns: Structured YAML complexity_report
- Fallback: Minimal complexity report if agent fails

### Integration 3: /expand Phase 1 → expansion-specialist agent

**Flow**:
1. /expand Phase 1 receives phases_to_expand list from Phase 0
2. For each phase, /expand invokes expansion-specialist via Task tool
3. Agent creates phase files, updates parent plan, creates artifacts
4. /expand validates files created and extracts expansion summary
5. Recursive evaluation: If stages exceed threshold, expand to Level 2

**Contract**:
- /expand passes: Plan path, phase numbers, complexity scores, thresholds
- Agent returns: Structured YAML expansion_summary
- Fallback: Manual expansion fallback if agent fails

## Completion Criteria

- [ ] Phase 4 section completely removed from orchestrate.md (470 lines)
- [ ] expansion-specialist invocation template transferred to /expand
- [ ] Recursive expansion logic transferred to /expand Phase 1
- [ ] Expansion verification patterns transferred to /expand Phase 2
- [ ] Phase 0 (Complexity Evaluation) added to /expand command
- [ ] Phase 2→3 transition updated with AskUserQuestion and /expand invocation
- [ ] All Phase 4 references removed (TodoWrite, checkpoints, workflow state)
- [ ] Supplemental content extracted to shared/orchestration-alternatives.md
- [ ] Testing specifications defined for verification
- [ ] Architecture decisions documented
- [ ] Error handling patterns defined
- [ ] Integration points documented

## Git Commit Message

```
feat(070): Phase 3 - remove automatic expansion and enhance /expand command

Remove 470-line Phase 4 (Plan Expansion) section from orchestrate.md and
transfer expansion logic to /expand command with new Phase 0 complexity
evaluation. Update Phase 2→3 transition to offer optional expansion via
AskUserQuestion, restoring user control over expansion decisions.

Changes:
- Remove Phase 4 section from orchestrate.md (lines 2581-3050)
- Add Phase 0 (Complexity Evaluation) to /expand command
- Transfer expansion-specialist invocation template to /expand
- Transfer recursive expansion logic to /expand Phase 1
- Add AskUserQuestion after Phase 2 for expansion decision
- Remove expansion workflow state variables
- Update phase numbering references (5→3, 6→4, 7→5)

Line count reduction: 6,356 → 5,886 lines (470 lines removed)

Related to: TODO3.md requirements, command architecture standards
Follows: 070-001 orchestrate simplification plan

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

**END OF PHASE 3 SPECIFICATION**

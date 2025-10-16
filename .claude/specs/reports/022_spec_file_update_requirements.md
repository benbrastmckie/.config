# Spec File Update Requirements Research Report

## Metadata

- **Date**: 2025-10-03
- **Scope**: Analysis of .claude/ commands and agents for spec file update gaps
- **Primary Directory**: /home/benjamin/.config/.claude/
- **Files Analyzed**: 20 command files, 8 agent files, multiple spec examples
- **Research Focus**: Identifying commands that should update spec files but don't consistently do so

## Executive Summary

After analyzing all commands and agents in `.claude/`, I identified **5 critical spec file management gaps**:

### New Gap (User-Identified)
0. **Specs Directory Location Tracking** - Plans and reports don't document their specs/ directory location, causing subsequent commands to scatter related specs across multiple directories

### Existing Gaps
1. **`/implement`** - Does not consistently update plan files with completion status during execution
2. **`/debug`** - Creates debug reports but doesn't update related plans with debugging outcomes
3. **`/orchestrate`** - Creates workflow summaries but inconsistently updates referenced plans and reports
4. **`/report`** - Never updates itself when findings change or implementation occurs

**Most Critical Issues**:
- **Specs directory tracking** (Priority 0): Without this, modular/monorepo projects get disorganized specs scattered across locations
- **`/implement` updates** (Priority 1): Primary execution mechanism, incomplete updates make resuming interrupted work difficult

These issues compound: If specs are in different directories AND plans aren't updated during implementation, users lose context on both location and progress.

## Problem Statement

### User's Issue

> "I find when I use /implement, it does not always keep the spec files updated, but I want to ensure that it does so that it is easy to follow and pick up where I left off if I am interrupted"

This reflects a broader pattern where **execution commands create or use spec files but don't maintain bidirectional update relationships**.

### Impact

- **Lost context**: Interrupted implementations can't be resumed without manual inspection
- **Orphaned specs**: Plans exist without knowing if they were implemented
- **Stale information**: Reports don't reflect that recommendations were adopted
- **Workflow friction**: Manual tracking required to know what's complete

## Current State Analysis

### Commands That Update Specs Correctly

#### `/plan` - Creates Plans
✅ **Status**: Good - Creates numbered plans in `specs/plans/`
- Generates `NNN_feature_name.md` with proper structure
- Includes metadata, phases, tasks with checkboxes
- References research reports if provided

#### `/update-plan` - Modifies Plans
✅ **Status**: Good - Explicitly designed to update plans
- Adds new phases, tasks, or requirements
- Maintains version history with timestamps
- Preserves completion markers

#### `/update-report` - Modifies Reports
✅ **Status**: Good - Explicitly designed to update reports
- Adds new findings to existing reports
- Updates specific sections
- Documents update history

#### `/list-plans`, `/list-reports`, `/list-summaries`
✅ **Status**: Good - Read-only commands, no updates needed

### Commands With Spec Update Gaps

#### 1. `/implement` - **CRITICAL GAP**

**Current Behavior** (from implement.md:108-123):
```markdown
4. For each phase:
   - Display the phase name and tasks
   - Implement changes following discovered standards
   - Run tests using standards-defined test commands
   - Verify compliance with standards before completing
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
```

**What It Should Do** (line 147-148):
```markdown
4. Plan Update
- Mark completed tasks with `[x]` instead of `[ ]`
- Add `[COMPLETED]` marker to the phase heading
- Save the updated plan file
```

**The Gap**:
- **Documented intention exists** but implementation is inconsistent
- No verification step ensures plan was actually updated
- No rollback if phase fails after marking complete
- Summary generation (lines 189-236) happens only at the end, not incrementally
- If interrupted mid-implementation, no summary exists

**Evidence from Code**:
Looking at line 355: "Let me start by finding your implementation plan" - this is where the command begins, but there's no explicit "update plan after each phase" verification step mentioned in the execution flow.

**What's Missing**:
1. **Checkpoint updates**: Plan should be updated after each successful phase commit
2. **Atomic updates**: Task checkmarks and `[COMPLETED]` markers should be written together
3. **Failure handling**: If phase fails, don't mark as complete
4. **Incremental summaries**: Write progress notes even if implementation incomplete
5. **Verification**: Confirm plan file updated before moving to next phase

#### 2. `/orchestrate` - **SIGNIFICANT GAP**

**Current Behavior** (from orchestrate.md:1376-1406):
```markdown
## Workflow Summary: [Feature/Task Name]

### Cross-References

#### Research Phase
This workflow incorporated findings from:
- [Report 1 path and title]

#### Planning Phase
Implementation followed the plan at:
- [Plan path and title]
```

**The Gap**:
- Creates summaries that **link to** plans and reports
- But **doesn't update** the referenced plans/reports to link back to the summary
- One-way references only

**What's Missing**:
1. **Bidirectional linking**: Update referenced reports to note "Implemented in summary NNN"
2. **Plan completion marking**: Add "Executed on YYYY-MM-DD, see summary NNN" to completed plans
3. **Report implementation status**: Mark which report recommendations were adopted
4. **Cross-reference verification**: Ensure all linked files actually exist

**Current Documentation** (lines 1389-1405):
```markdown
**Cross-Reference Updates**:
```markdown
Update related files to link back to summary:

In Implementation Plan (specs/plans/NNN_*.md):
Add at bottom:
## Implementation Summary
This plan was executed on [date]. See workflow summary:
- [Summary path and link]
```

This is **documented as should happen** but agent prompts (lines 1118-1198) don't include explicit instructions to update the original plan/report files.

#### 3. `/debug` - **MODERATE GAP**

**Current Behavior** (from debug.md:69-114):
```markdown
## Report Structure

# Debug Report: [Issue Title]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Issue**: [Brief description]
- **Related Reports**: [List of reference reports]

## Proposed Solutions
[Fix proposals]

## Next Steps
[Action items]
```

**The Gap**:
- Creates debug reports in `specs/reports/NNN_debug_*.md`
- References the plan being debugged (if provided as argument)
- But **doesn't update the plan** to note that debugging occurred
- Doesn't track which debug reports relate to which plan phases

**What's Missing**:
1. **Plan annotation**: Add "Debugged in report NNN" to the failed phase
2. **Issue tracking**: Mark which tasks caused failures
3. **Resolution tracking**: Update plan when debug report leads to successful fix
4. **Debug history**: Keep record of all debugging attempts per plan

**Integration Flow** (lines 167-177):
```markdown
### After Debugging
- Use `/plan` to create implementation plan from findings
- Use `/implement` to execute the solution
- Consider `/test` to verify the fix
```

But there's no "update the original plan with debug outcomes" step.

#### 4. `/report` - **LOW-MODERATE GAP**

**Current Behavior** (from report.md:56-102):
```markdown
The report will include:
- **Executive Summary**: Brief overview of findings
- **Recommendations**: Suggested improvements or next steps
- **References**: Links to relevant files and resources
```

**The Gap**:
- Reports make recommendations
- Plans may reference reports (via `/plan <feature> report1.md report2.md`)
- But when recommendations are **implemented**, the report isn't updated
- No tracking of "which recommendations were adopted"

**What's Missing**:
1. **Implementation tracking**: Section noting "Recommendations adopted in plan NNN"
2. **Status updates**: Mark recommendations as "Implemented", "Deferred", "Rejected"
3. **Outcome recording**: Document how implementations differed from recommendations
4. **Lifecycle management**: Reports should reflect their current relevance

**Current Agent Section** (lines 107-163):
Mentions that `/orchestrate` can use reports, but doesn't mention updating reports after implementation.

### Commands That Don't Need Updates

- `/test`, `/test-all` - Execute tests, no specs to update
- `/document` - Updates documentation, not specs
- `/refactor` - Creates reports, same gap as `/report` but lower priority
- `/validate-setup` - Read-only validation
- `/example-with-agent` - Template/documentation
- `/resume-implement` - Wrapper for `/implement`, same gaps
- `/revise` - Updates plans (explicitly designed for this)

## Key Findings

### Finding 1: Missing Bidirectional Updates

**Pattern**: Commands create relationships between spec files but maintain only one-way links.

**Examples**:
- `/plan` can reference reports: `plan.md` → `report.md` ✓
- But reports don't get updated: `report.md` ↛ `plan.md` ✗

- `/implement` uses plan: `implement` → `plan.md` ✓
- But plan doesn't always get marked complete: `plan.md` ↛ `summary.md` ⚠

- `/orchestrate` creates summary linking everything
- But original files don't link to summary ✗

**Impact**: Orphaned spec files, unclear which specs are current vs. historical

### Finding 2: Incomplete Incremental Updates

**Pattern**: Updates happen at workflow completion, not incrementally during execution.

**Example from `/implement`** (lines 124-176):
- Phase 1: Implement → Test → **Update plan** → Commit ✓
- Phase 2: Implement → Test → **Update plan** → Commit ✓
- Phase N: Implement → Test → **Update plan** → Commit ✓
- **After all phases**: Generate summary ✓

But if interrupted at Phase 3 of 6:
- Phases 1-2: Marked complete in plan ✓
- Phase 3: Partial work committed but not marked complete ⚠
- Summary: **Not created** ✗
- Resume point: **Unclear** without reading plan manually ⚠

**What's Needed**: Incremental summary updates after each phase, not just at end.

### Finding 3: No Update Verification

**Pattern**: Commands assume updates succeeded without verification.

**Example from `/implement`**:
```markdown
4. Plan Update
- Mark completed tasks with `[x]`
- Add `[COMPLETED]` marker
- Save the updated plan file
```

**No verification that**:
- Plan file is writable
- Edits succeeded
- Markers were correctly added
- File was actually saved

**Impact**: Silent failures leave specs inconsistent with actual state.

### Finding 4: Debugging Outcomes Not Tracked

**Pattern**: Debugging creates new reports but doesn't annotate the original plan with debugging context.

**Scenario**:
1. `/implement plan_013.md` fails at Phase 3
2. `/debug "Phase 3 test failures" plan_013.md` creates `reports/025_debug_phase3.md`
3. Debug report proposes fixes
4. Fixes applied manually or via another `/implement` run
5. **But `plan_013.md` never updated** to note:
   - Phase 3 failed initially
   - Debugged in report 025
   - Fixed and re-run successfully

**Impact**: Lost context about why certain phases were challenging, debugging history not preserved.

## Technical Details

### `/implement` Update Mechanism Analysis

**Current approach** (inferred from command documentation):

```bash
# Pseudocode of current implementation
for phase in plan.phases:
    execute_phase(phase)
    run_tests(phase)
    if tests_pass:
        update_plan_file(phase, mark_complete=True)  # ← Inconsistent
        git_commit(phase)
    else:
        break  # Stops here, no summary

# Only if all phases complete:
generate_summary()  # ← Too late if interrupted
```

**Problems**:
1. `update_plan_file()` may not execute reliably
2. No rollback if commit fails after marking complete
3. No partial summary if interrupted

**Improved approach**:

```bash
# Enhanced implementation
for phase in plan.phases:
    checkpoint_start(phase)

    execute_phase(phase)
    run_tests(phase)

    if tests_pass:
        # Atomic update: plan + git + checkpoint
        update_plan_atomically(phase):
            mark_tasks_complete()
            add_completed_marker()
            update_incremental_summary()  # ← NEW
            verify_file_written()  # ← NEW

        git_commit(phase)
        checkpoint_success(phase)
    else:
        checkpoint_failure(phase, preserve_partial_work=True)
        break

# Always generate summary, even if incomplete
generate_summary(
    completed_phases=checkpoints.successful,
    failed_phase=checkpoints.failed,
    status="complete" | "partial" | "failed"
)
```

**New elements**:
- `checkpoint_start()`: Record phase attempt
- `checkpoint_success()`: Verify plan updated
- `checkpoint_failure()`: Record failure context
- `update_incremental_summary()`: Write progress notes after each phase
- `verify_file_written()`: Confirm plan actually updated
- `generate_summary()`: Always run, notes if incomplete

### `/orchestrate` Cross-Reference Mechanism

**Current approach** (from orchestrate.md:1389-1405):

```yaml
# Documented but not enforced in agent prompts
summary_creation:
  write_summary_file:
    - research_reports: [link to reports]
    - plan_file: [link to plan]
    - files_modified: [list]

  # This section exists but unclear if actually executed:
  update_cross_references:
    - update_plan: "Add summary reference"
    - update_reports: "Add summary reference"
```

**Gap**: Agent prompts for `doc-writer` (lines 1118-1198) don't explicitly require updating original files.

**Improved approach**:

```yaml
documentation_phase:
  step_1_create_summary: "specs/summaries/NNN.md"

  step_2_update_plan:
    file: "specs/plans/NNN.md"
    action: append_section
    content: |
      ## Implementation Summary
      Executed: 2025-10-03
      Summary: [link to specs/summaries/NNN.md]
      Status: Complete

  step_3_update_reports:
    for report in referenced_reports:
      file: report.path
      action: append_section
      content: |
        ## Implementation Status
        Recommendations implemented in:
        - Plan: [link to specs/plans/NNN.md]
        - Summary: [link to specs/summaries/NNN.md]
        - Date: 2025-10-03

  step_4_verify:
    - check_summary_exists: True
    - check_plan_updated: True
    - check_reports_updated: True
    - check_bidirectional_links: True
```

### `/debug` Plan Annotation Mechanism

**Currently missing** - no mechanism exists.

**Proposed approach**:

```yaml
debug_completion:
  create_debug_report: "specs/reports/NNN_debug_*.md"

  if plan_path_provided:
    update_original_plan:
      file: plan_path
      phase: failed_phase_number
      action: add_debug_annotation
      content: |
        ### Debug History
        - 2025-10-03: Phase failed, investigated in [report NNN](../reports/NNN_debug_*.md)
        - Root cause: [brief summary]
        - Resolution: [applied fixes | pending | abandoned]

  track_debugging_iterations:
    - attempt_1: report_025.md
    - attempt_2: report_026.md
    - attempt_3: escalated_to_user
```

### `/report` Implementation Tracking

**Currently missing** - reports are write-once, never updated.

**Proposed approach**:

```yaml
report_lifecycle:
  creation:
    status: "research_complete"
    recommendations: [list]
    implementation_status: "pending"

  when_plan_references_report:
    update_report:
      section: "## Planning Status"
      content: |
        This report informed planning for:
        - Plan: [link to specs/plans/NNN.md]
        - Date: 2025-10-03

  when_implementation_completes:
    update_report:
      section: "## Implementation Status"
      content: |
        Recommendations from this report were implemented:

        Adopted Recommendations:
        - [Recommendation 1]: Implemented in Phase 2
        - [Recommendation 2]: Implemented in Phase 4

        Deferred Recommendations:
        - [Recommendation 3]: Deferred to future work

        Modified Recommendations:
        - [Recommendation 4]: Implemented with modification (explain)

        Summary: [link to specs/summaries/NNN.md]
        Date: 2025-10-03

  status_tracking:
    - "research_complete" → "planning_in_progress"
    - "planning_in_progress" → "implementation_in_progress"
    - "implementation_in_progress" → "implemented"
    - any_state → "superseded" (if newer report covers same topic)
```

## Additional Requirement: Specs Directory Location Tracking

### Context from Report 018

Report 018 (Flexible Specs Location Strategies) extensively researches configuration strategies for placing specs/ directories in relevant locations:
- Configuration file approach (`.claude/config/specs-locations.json`)
- Environment variable overrides
- Scope rules for monorepos
- Automatic detection of "deepest relevant directory"

**The Gap**: While Report 018 covers **how to configure** specs locations, there's still a missing piece:

**Plans and reports should document their own specs/ directory location** so subsequent commands can continue using the same location.

### The Problem

**Current Behavior**:
1. `/report` uses automatic detection to create `nvim/lua/neotex/auth/specs/reports/001_auth_research.md`
2. `/plan` references that report but may place the plan in a different specs/ directory
3. `/implement` uses the plan but may place the summary in yet another location
4. Result: Specs scattered across multiple directories for the same feature

**Example Scenario**:
```bash
# Working on authentication module
cd nvim/lua/neotex/auth/

/report "authentication patterns"
# Creates: nvim/lua/neotex/auth/specs/reports/001_auth_patterns.md

# Later, from project root:
/plan "add authentication" nvim/lua/neotex/auth/specs/reports/001_auth_patterns.md
# Creates: specs/plans/015_add_authentication.md  ← Wrong location!
# Should be: nvim/lua/neotex/auth/specs/plans/001_add_authentication.md

/implement specs/plans/015_add_authentication.md
# Creates: specs/summaries/015_implementation.md  ← Wrong location!
# Should be: nvim/lua/neotex/auth/specs/summaries/001_implementation.md
```

**Impact**: Related specs files not co-located, harder to find context.

### The Solution

**Add specs directory metadata to all spec files**:

```markdown
# In every report, plan, and summary

## Metadata
- **Date**: 2025-10-03
- **Specs Directory**: nvim/lua/neotex/auth/specs/  ← NEW
- **Report Number**: 001 (within this specs/ directory)
...
```

**Commands should read and respect this**:

```yaml
/plan behavior:
  if report_paths_provided:
    for report in report_paths:
      specs_dir = extract_specs_dir_from_metadata(report)
      if specs_dir:
        use_specs_dir_for_plan: specs_dir

  # Example:
  # Report says: "Specs Directory: nvim/lua/neotex/auth/specs/"
  # Plan created at: nvim/lua/neotex/auth/specs/plans/NNN.md
  # Plan metadata says: "Specs Directory: nvim/lua/neotex/auth/specs/"

/implement behavior:
  plan_file = args.plan_path
  specs_dir = extract_specs_dir_from_metadata(plan_file)
  if specs_dir:
    summary_path = specs_dir + "/summaries/NNN.md"
  else:
    summary_path = detect_or_fallback()

  # Summary metadata says: "Specs Directory: nvim/lua/neotex/auth/specs/"
```

**This ensures**:
- All related specs (reports, plans, summaries) stay in the same specs/ directory
- Cross-references use relative paths within the same directory
- Easy to find all specs for a feature
- Works with flexible location strategies from Report 018

### Implementation Changes

**Update all spec file templates**:

1. **`/report` template** (report.md:85-105):
   ```markdown
   ## Metadata
   - **Date**: [YYYY-MM-DD]
   - **Specs Directory**: [detected or configured path]
   - **Report Number**: [NNN within this directory]
   - **Scope**: [Description]
   ```

2. **`/plan` template** (plan.md:113-126):
   ```markdown
   ## Metadata
   - **Date**: [YYYY-MM-DD]
   - **Specs Directory**: [from report or detected]
   - **Plan Number**: [NNN within this directory]
   - **Research Reports**: [links to reports]
   ```

3. **`/implement` summary template** (implement.md:211-221):
   ```markdown
   ## Metadata
   - **Date Completed**: [YYYY-MM-DD]
   - **Specs Directory**: [from plan]
   - **Summary Number**: [NNN within this directory]
   - **Plan**: [link]
   ```

**Add extraction function** (all commands need this):

```bash
# Pseudocode
extract_specs_dir_from_metadata(file_path):
  content = read_file(file_path)

  # Look for metadata section
  if match = content.match(/## Metadata.*- \*\*Specs Directory\*\*: (.+)/):
    return match[1]

  # Fallback: infer from file path
  if file_path contains "/specs/reports/":
    return dirname(dirname(file_path))  # Go up two levels

  if file_path contains "/specs/plans/":
    return dirname(dirname(file_path))

  if file_path contains "/specs/summaries/":
    return dirname(dirname(file_path))

  return null  # Trigger automatic detection
```

**Update command logic**:

```yaml
/report:
  1. Detect specs directory (using Report 018 strategies)
  2. Create report at: {specs_dir}/reports/NNN.md
  3. Include metadata: "Specs Directory: {specs_dir}"

/plan:
  1. If reports provided: Extract specs_dir from first report
  2. Else: Detect specs directory (Report 018 strategies)
  3. Create plan at: {specs_dir}/plans/NNN.md
  4. Include metadata: "Specs Directory: {specs_dir}"

/implement:
  1. Extract specs_dir from plan metadata
  2. Create summary at: {specs_dir}/summaries/NNN.md
  3. Include metadata: "Specs Directory: {specs_dir}"

/orchestrate:
  1. Research reports specify their specs_dir
  2. Plan uses same specs_dir from reports
  3. Implementation summary uses same specs_dir from plan
  4. All specs co-located
```

### Benefits

1. **Consistency**: All related specs in same directory
2. **Portability**: Moving specs/ directory moves everything
3. **Discovery**: Easy to find all specs for a module/feature
4. **Cross-references**: Relative paths always work
5. **Resumability**: `/resume-implement` knows exactly where to look

### Integration with Report 018

This enhancement **complements** Report 018's configuration strategies:

**Report 018** defines **where** specs/ directories should be:
- Configuration file
- Environment variables
- Scope rules
- Automatic detection

**Report 022 (this update)** defines **how** to maintain consistency:
- Document the chosen location in metadata
- Subsequent commands read and respect it
- All related specs stay together

**Together**: Flexible initial placement + consistent subsequent usage.

## Recommendations

### Priority 0: Add Specs Directory Metadata (NEW - HIGH PRIORITY)

**Why High Priority**: Ensures all related specs stay co-located, critical for modular/monorepo projects.

**Changes Needed**:

1. **Update all spec templates**:
   ```markdown
   # Add to /report, /plan, /implement templates

   ## Metadata
   - **Specs Directory**: [path to specs/ parent]
   - **[Type] Number**: [NNN within this directory]
   ```

2. **Add metadata extraction function**:
   ```bash
   # New shared function in .claude/lib/

   extract_specs_dir_from_file(file_path):
     - Parse metadata section
     - Extract "Specs Directory" field
     - Return path or null
   ```

3. **Update command logic**:
   ```markdown
   /plan:
     - If report provided: Read specs_dir from report metadata
     - Use same directory for plan
     - Document in plan metadata

   /implement:
     - Read specs_dir from plan metadata
     - Use same directory for summary
     - Document in summary metadata

   /orchestrate:
     - Ensure all workflow specs use same directory
     - Propagate through research → plan → summary
   ```

**Implementation Difficulty**: Low-Medium
- Simple metadata field addition
- Straightforward parsing logic
- Update templates in 3 commands

**User Benefit**: Very High
- Modular projects keep specs organized
- No more scattered specs across directories
- Works seamlessly with Report 018 strategies

### Priority 1: Fix `/implement` Incremental Updates (CRITICAL)

**Why Critical**: This is the primary execution mechanism users rely on for resumability.

**Changes Needed**:

1. **Add checkpoint system**:
   ```markdown
   # In /implement command

   After each phase completion:
   1. Update plan file atomically:
      - Mark phase tasks complete: `- [x]`
      - Add phase completion marker: `### Phase N [COMPLETED]`
      - Write file and verify success

   2. Create incremental checkpoint in plan:
      - Add "## Implementation Progress" section
      - Record last completed phase
      - Note date and git commit
      - Include resume instructions

   3. Verify update succeeded:
      - Read plan file back
      - Confirm markers present
      - If verification fails, rollback and retry
   ```

2. **Generate partial summaries**:
   ```markdown
   # After each phase (not just at end)

   Update or create specs/summaries/NNN_partial.md:
   - Phases completed: M/N
   - Last successful phase: Phase M
   - Git commits: [list]
   - Status: "in_progress"
   - Resume command: `/implement plan_NNN.md M+1`

   On complete, rename NNN_partial.md → NNN_summary.md
   On interrupt, partial summary remains for context
   ```

3. **Add verification step before next phase**:
   ```markdown
   Before starting Phase N+1:
   - Read plan file
   - Confirm Phase N marked `[COMPLETED]`
   - Confirm all Phase N tasks checked `[x]`
   - If not, mark complete before proceeding
   - Log discrepancy for investigation
   ```

**Implementation Difficulty**: Medium
- Requires editing `/implement` command structure
- Needs new checkpoint system
- Must handle partial summary file lifecycle

**User Benefit**: High
- Can always resume interrupted implementations
- Clear progress tracking
- No lost context on interruption

### Priority 2: Add `/orchestrate` Bidirectional Linking (HIGH)

**Why High**: Prevents orphaned spec files, improves navigation.

**Changes Needed**:

1. **Update `doc-writer` agent prompt** (orchestrate.md:1118-1198):
   ```markdown
   # Add to documentation phase agent prompt

   Step 6: Update Referenced Files

   For the implementation plan at [plan_path]:
   - Append section: "## Implementation Summary"
   - Add: "Executed on [date], see [summary_link]"
   - Add: "Status: Complete"

   For each research report in [research_reports]:
   - Append section: "## Implementation Status"
   - Add: "Recommendations implemented in [plan_link]"
   - Add: "Implementation summary: [summary_link]"
   - Add: "Date: [date]"

   Verify all cross-references:
   - Summary links to plan and reports ✓
   - Plan links to summary ✓
   - Reports link to plan and summary ✓
   ```

2. **Add verification to workflow completion**:
   ```markdown
   Before marking workflow complete:
   - Read summary file
   - Extract all linked plan/report paths
   - For each linked file:
     * Verify file exists
     * Check if file contains reciprocal link to summary
     * If not, update file with link
     * Verify update succeeded
   - Report any linking failures
   ```

**Implementation Difficulty**: Medium
- Requires updating orchestrate.md agent prompts
- Needs file update logic
- Must handle edge cases (file not writable, etc.)

**User Benefit**: High
- Easy navigation between related specs
- Clear tracking of what was implemented
- Reports show their outcomes

### Priority 3: Add `/debug` Plan Annotations (MEDIUM)

**Why Medium**: Improves debugging context, but less frequently used than `/implement`.

**Changes Needed**:

1. **Add plan update to debug workflow**:
   ```markdown
   # In debug.md, after creating debug report

   If plan_path provided in arguments:

   Update plan file with debug annotation:

   Location: After the failed phase section

   Content:
   ```markdown
   #### Debugging Notes
   - **Date**: 2025-10-03
   - **Issue**: [Brief description from debug report]
   - **Investigation**: [Link to debug report NNN]
   - **Root Cause**: [One-line summary]
   - **Resolution**: [Applied | Pending | Deferred]
   - **Fix Applied In**: [Git commit hash or "Not yet applied"]
   ```

   This creates a debugging history per phase.
   ```

2. **Track debugging iterations**:
   ```markdown
   If multiple debug reports reference same plan:
   - Group under "## Debugging History" section
   - List chronologically
   - Note iteration count
   - Flag if escalated to manual intervention
   ```

**Implementation Difficulty**: Low-Medium
- Simple append to plan file
- Straightforward logic
- Minimal edge cases

**User Benefit**: Medium
- Preserves debugging context
- Helps identify problematic phases
- Shows debugging iteration history

### Priority 4: Add `/report` Implementation Tracking (LOW-MEDIUM)

**Why Low-Medium**: Nice to have, improves report lifecycle, but not critical for workflow.

**Changes Needed**:

1. **Add status section to report template**:
   ```markdown
   # In report.md template (lines 85-105)

   Add new section:

   ## Implementation Status

   - **Status**: Research Complete
   - **Plan**: None yet
   - **Implementation**: Not started
   - **Date**: 2025-10-03

   ### Recommendation Tracking

   | Recommendation | Status | Implemented In | Notes |
   |---------------|---------|----------------|-------|
   | [Rec 1] | Pending | - | - |
   | [Rec 2] | Pending | - | - |
   ```

2. **Update report when plan references it**:
   ```markdown
   # In /plan command

   When creating plan with report arguments:

   For each report in [report1.md, report2.md]:
   - Update report's "Implementation Status" section
   - Change status to "Planning In Progress"
   - Add plan link
   - Add date
   ```

3. **Update report when implementation completes**:
   ```markdown
   # In /implement or /orchestrate

   When generating summary:

   If plan referenced research reports:
   - For each report:
     * Update "Implementation Status" to "Implemented"
     * Fill in "Recommendation Tracking" table
     * Link to summary
   ```

**Implementation Difficulty**: Medium
- Requires changes to multiple commands
- Needs table update logic
- Must handle reports created before this feature

**User Benefit**: Low-Medium
- Nice to see report outcomes
- Helps identify stale reports
- Shows which recommendations were valuable

## Migration Path

### Phase 0: Add Specs Directory Tracking (Week 1)

1. Add "Specs Directory" metadata field to all spec templates
2. Implement metadata extraction function
3. Update `/report` to document specs directory
4. Update `/plan` to read from reports and document in plan
5. Update `/implement` to read from plan and document in summary
6. Update `/orchestrate` to propagate specs directory through workflow
7. Test with modular project structure

**Success Criteria**:
- All new specs include "Specs Directory" metadata
- `/plan` uses same specs/ directory as referenced reports
- `/implement` uses same specs/ directory as plan
- All related specs co-located in one directory

### Phase 1: Fix `/implement` Incremental Updates (Week 2)

1. Add checkpoint system to `/implement` command
2. Implement plan file verification
3. Add incremental summary generation
4. Test with existing plans
5. Document new behavior in command help

**Success Criteria**:
- Interrupted implementations always leave updated plan
- Partial summaries exist for incomplete implementations
- `/resume-implement` works reliably

### Phase 2: Add `/orchestrate` Bidirectional Links (Week 3)

1. Update `doc-writer` agent prompt in `orchestrate.md`
2. Add cross-reference verification step
3. Test with existing specs
4. Backfill existing summaries with reciprocal links (optional)

**Success Criteria**:
- All new orchestrations create bidirectional links
- Plans and reports reference summaries
- Navigation works in both directions

### Phase 3: Add `/debug` Annotations (Week 4)

1. Add plan annotation logic to `debug.md`
2. Test with sample debugging scenarios
3. Document debugging history format

**Success Criteria**:
- Debug reports update original plans
- Debugging history visible in plan files
- Multi-iteration debugging tracked

### Phase 4: Add `/report` Tracking (Week 5, Optional)

1. Update report template with status section
2. Add report update logic to `/plan`
3. Add report update logic to `/implement` and `/orchestrate`
4. Backfill existing reports (manual)

**Success Criteria**:
- New reports include status tracking
- Reports updated when referenced
- Reports show implementation outcomes

## Testing Strategy

### Test Case 0: Specs Directory Consistency

```bash
# Setup: Modular project structure
mkdir -p nvim/lua/neotex/auth
cd nvim/lua/neotex/auth

# Execute
/report "authentication patterns"
# Should create: nvim/lua/neotex/auth/specs/reports/001_auth_patterns.md

# Verify report metadata
cat specs/reports/001_auth_patterns.md
# Should contain:
# - **Specs Directory**: nvim/lua/neotex/auth/specs/
# - **Report Number**: 001

# Create plan from report (from different directory)
cd /home/benjamin/.config  # Move to project root
/plan "add authentication" nvim/lua/neotex/auth/specs/reports/001_auth_patterns.md

# Verify plan location
ls nvim/lua/neotex/auth/specs/plans/001_add_authentication.md
# Plan should be in SAME specs/ directory as report

# Verify plan metadata
cat nvim/lua/neotex/auth/specs/plans/001_add_authentication.md
# Should contain:
# - **Specs Directory**: nvim/lua/neotex/auth/specs/
# - **Plan Number**: 001
# - **Research Reports**: [../reports/001_auth_patterns.md]

# Implement plan
/implement nvim/lua/neotex/auth/specs/plans/001_add_authentication.md

# Verify summary location
ls nvim/lua/neotex/auth/specs/summaries/001_add_authentication.md
# Summary should be in SAME specs/ directory

# Verify all specs co-located
ls nvim/lua/neotex/auth/specs/
# Should show:
#   reports/001_auth_patterns.md
#   plans/001_add_authentication.md
#   summaries/001_add_authentication.md
# All in one directory! ✓
```

### Test Case 1: Interrupted `/implement`

```bash
# Setup
/plan "Test feature with 5 phases"
# Creates plan_023.md with 5 phases

# Execute
/implement plan_023.md
# Interrupt after Phase 3 completes (Ctrl+C)

# Verify
- plan_023.md shows Phases 1-3 marked [COMPLETED]
- specs/summaries/023_partial.md exists
- Partial summary shows "Status: in_progress"
- Partial summary shows "Phases completed: 3/5"
- Resume command provided: /implement plan_023.md 4

# Resume
/resume-implement  # Should auto-detect plan_023.md

# Verify
- Resumes from Phase 4
- After completion, 023_partial.md → 023_summary.md
- Final summary shows "Status: complete"
```

### Test Case 2: `/orchestrate` Cross-References

```bash
# Setup
/report "Authentication best practices"
# Creates reports/028_auth_best_practices.md

# Execute
/orchestrate "Add authentication using report 028"
# Should create plan, implement, generate summary

# Verify
- specs/summaries/029_workflow.md exists
- Summary links to:
  * plans/029_auth.md ✓
  * reports/028_auth_best_practices.md ✓
- plans/029_auth.md contains:
  * "Implementation Summary" section ✓
  * Link to summaries/029_workflow.md ✓
- reports/028_auth_best_practices.md contains:
  * "Implementation Status" section ✓
  * Link to plans/029_auth.md ✓
  * Link to summaries/029_workflow.md ✓
```

### Test Case 3: `/debug` Annotations

```bash
# Setup
/plan "Feature with tricky logic"
# Creates plan_030.md

# Execute and fail
/implement plan_030.md
# Phase 2 fails with test errors

# Debug
/debug "Phase 2 test failures" plan_030.md
# Creates reports/029_debug_phase2.md

# Verify
- reports/029_debug_phase2.md exists with root cause
- plan_030.md Phase 2 section contains:
  * "Debugging Notes" subsection ✓
  * Link to reports/029_debug_phase2.md ✓
  * Root cause summary ✓
  * Resolution status: "Pending" ✓

# Fix and retry
# Apply fixes from debug report
/implement plan_030.md 2

# Verify
- plan_030.md Phase 2 "Debugging Notes" updated:
  * Resolution status: "Applied" ✓
  * Fix commit hash included ✓
```

## Metrics

Track success of these improvements:

1. **Implementation Resumability**:
   - Before: X% of interrupted implementations resume cleanly
   - After: 100% of interrupted implementations resume cleanly

2. **Spec Staleness**:
   - Before: Y% of plans don't know if they're implemented
   - After: 0% ambiguity (all plans marked with status)

3. **Navigation Efficiency**:
   - Before: N clicks to go from summary → plan → report → summary
   - After: 1 click (bidirectional links)

4. **Debugging Context**:
   - Before: Debug reports orphaned from plans
   - After: All debug reports linked from plan phase

## References

### Files Analyzed

#### Commands (20 files)
- `/home/benjamin/.config/.claude/commands/implement.md` (355 lines)
- `/home/benjamin/.config/.claude/commands/orchestrate.md` (2050 lines)
- `/home/benjamin/.config/.claude/commands/debug.md` (260 lines)
- `/home/benjamin/.config/.claude/commands/report.md` (165 lines)
- `/home/benjamin/.config/.claude/commands/plan.md` (241 lines)
- `/home/benjamin/.config/.claude/commands/update-plan.md` (80 lines)
- `/home/benjamin/.config/.claude/commands/update-report.md` (similar structure)
- `/home/benjamin/.config/.claude/commands/resume-implement.md` (94 lines)
- `/home/benjamin/.config/.claude/commands/document.md` (337 lines)
- Plus 11 other commands analyzed

#### Agents (8 files)
- All agent definitions reviewed for spec update patterns
- No agents currently update spec files (they create or read only)

#### Example Specs
- `/home/benjamin/.config/.claude/specs/summaries/015_tts_workflow_integration_summary.md` (360 lines)
  - Shows ideal summary format
  - Demonstrates cross-referencing
  - Notes that plan/reports weren't updated reciprocally

#### Standards
- `/home/benjamin/.config/CLAUDE.md` - Specs directory protocol
- `/home/benjamin/.config/.claude/specs/README.md` - Spec file format

### Related Reports

- **Report 018: Flexible Specs Location Strategies** - Comprehensive research on configuring specs/ directory locations (configuration files, environment variables, scope rules, automatic detection)
- Report 010: Command Workflow Optimization - Command efficiency analysis
- Report 014: Claude Directory Implementation Status and Gaps - Infrastructure audit

### External Resources

- [LangChain Supervisor Pattern (2025)](https://blog.langchain.dev/langgraph-supervisor-pattern/)
  - Context preservation strategies
  - State management best practices
- CommonMark Spec: Markdown formatting standards
- Git hooks best practices: For checkpoint system

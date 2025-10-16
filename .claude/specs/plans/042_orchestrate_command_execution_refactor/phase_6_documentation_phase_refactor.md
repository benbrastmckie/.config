# Phase 6: Documentation Phase Refactor

## Metadata
- **Phase Number**: 6
- **Parent Plan**: 042_orchestrate_command_execution_refactor.md
- **Dependencies**: Phase 5
- **Complexity**: Medium-High (7/10)
- **Estimated Hours**: 4-5
- **Status**: COMPLETED
- **Completion Date**: 2025-10-12
- **Lines Affected**: 3020-4050 (orchestrate.md, adjusted from initial estimate)
- **Lines Transformed**: ~1030 lines (significantly exceeded initial estimate of 462 lines due to comprehensive inline documentation)

## Objective

Transform the documentation phase from passive documentation descriptions into execution-driven instructions that explicitly invoke the doc-writer agent using the Task tool. This phase completes the workflow by updating project documentation, generating a comprehensive workflow summary with performance metrics, establishing bidirectional cross-references between all artifacts, and optionally creating a pull request.

The refactored documentation phase will:
1. Gather workflow artifacts and calculate performance metrics explicitly
2. Invoke doc-writer agent with complete inline prompt and summary template
3. Extract and validate documentation results
4. Create workflow summary file with cross-references
5. Update all artifact files with bidirectional links
6. Optionally invoke github-specialist agent for PR creation
7. Save final checkpoint with complete workflow metrics
8. Display workflow completion message with artifact paths

## Context and Background

### Current Implementation Issues

The current documentation phase (lines 1138-1600) suffers from the same issues as earlier phases:
- **Passive Voice**: "This phase updates all relevant documentation" instead of "UPDATE all relevant documentation NOW"
- **Missing EXECUTE NOW Blocks**: Steps describe what should happen without explicit execution instructions
- **External References**: Summary template in separate section instead of inlined in agent prompt
- **No Verification**: No checklist to ensure doc-writer agent was actually invoked

### Why This Phase Matters

The documentation phase is critical for workflow completion because it:
1. **Preserves Knowledge**: Workflow summary documents research → planning → implementation decisions
2. **Enables Traceability**: Cross-references create audit trail linking all artifacts
3. **Measures Performance**: Calculates time savings from parallel execution
4. **Facilitates Collaboration**: Optional PR creation enables team review
5. **Completes the Loop**: Links research reports back to implementation summaries

Without proper execution of this phase, valuable research and implementation context is lost.

## Detailed Implementation Steps

### Step 1: Prepare Documentation Context (EXECUTE NOW)

**Transform from**:
```markdown
**Gather All Workflow Artifacts**:
```yaml
documentation_context:
  files_modified: [list from implementation]
```

**Transform to**:
```markdown
**EXECUTE NOW: Gather Workflow Artifacts**

EXTRACT the following from workflow_state:
1. Research report paths (from research phase checkpoint)
2. Implementation plan path (from planning phase checkpoint)
3. Implementation status (from implementation phase checkpoint)
4. Debug report paths if any (from debugging phase checkpoint)
5. Modified files list (from implementation agent output)
6. Test results (passing or fixed_after_debugging)
```

**Context to Gather**:

Build the documentation context structure:

```yaml
documentation_context:
  # From workflow initialization
  workflow_description: "[Original user request]"
  workflow_type: "feature|refactor|debug|investigation"
  project_name: "[generated project name]"

  # From research phase (if completed)
  research_reports: [
    "specs/reports/existing_patterns/001_report.md",
    "specs/reports/security_practices/001_report.md"
  ]
  research_topics: ["existing_patterns", "security_practices"]

  # From planning phase
  plan_path: "specs/plans/NNN_feature_name.md"
  plan_number: NNN
  phase_count: N

  # From implementation phase
  implementation_status:
    tests_passing: true
    phases_completed: "N/N"
    files_modified: [
      "file1.ext",
      "file2.ext"
    ]
    git_commits: [
      "hash1",
      "hash2"
    ]

  # From debugging phase (if occurred)
  debug_reports: [
    "debug/phase1_failures/001_config_init.md"
  ]
  debug_iterations: N
  issues_resolved: [
    "Issue 1 description",
    "Issue 2 description"
  ]

  # Current phase
  current_phase: "documentation"
```

**VERIFICATION**:
- [ ] workflow_description extracted from state
- [ ] All phase outputs collected (research, planning, implementation, debugging)
- [ ] File paths verified (all referenced files exist)
- [ ] Context structure complete

### Step 2: Calculate Performance Metrics (EXECUTE NOW)

**Transform from**:
```markdown
**Calculate Performance Metrics**:
```yaml
performance_summary:
  total_workflow_time: "[duration in minutes]"
```

**Transform to**:
```markdown
**EXECUTE NOW: Calculate Performance Metrics**

CALCULATE workflow timing and performance:

1. **Total Workflow Time**:
   ```
   total_time = current_timestamp - workflow_start_timestamp
   total_minutes = total_time / 60
   total_hours = total_minutes / 60
   formatted_duration = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
   ```

2. **Phase Breakdown**:
   For each completed phase, calculate:
   ```
   phase_duration = phase_end_timestamp - phase_start_timestamp
   phase_minutes = phase_duration / 60
   ```

3. **Parallelization Metrics** (if research phase completed):
   ```
   parallel_agents = count(research_reports)
   estimated_sequential_time = parallel_agents × average_research_time
   actual_parallel_time = research_phase_duration
   time_saved = estimated_sequential_time - actual_parallel_time
   time_saved_percentage = (time_saved / estimated_sequential_time) × 100
   ```

4. **Error Recovery Metrics** (if debugging occurred):
   ```
   total_errors = count(debug_reports)
   auto_recovered = total_errors (if tests eventually passed)
   manual_interventions = 0 (if no user escalation)
   recovery_success_rate = (auto_recovered / total_errors) × 100
   ```
```

**Performance Data Structure**:

```yaml
performance_summary:
  # Time metrics
  total_workflow_time: "[HH:MM:SS format]"
  total_minutes: N

  # Phase breakdown
  phase_times:
    research: "[HH:MM:SS or 'Skipped']"
    planning: "[HH:MM:SS]"
    implementation: "[HH:MM:SS]"
    debugging: "[HH:MM:SS or 'Not needed']"
    documentation: "[current phase]"

  # Parallel execution metrics (if research completed)
  parallelization_metrics:
    parallel_research_agents: N
    estimated_sequential_time: "[minutes]"
    actual_parallel_time: "[minutes]"
    time_saved_estimate: "[N% saved vs sequential]"

  # Error recovery metrics (if debugging occurred)
  error_recovery:
    total_errors: N
    auto_recovered: N
    manual_interventions: N
    recovery_success_rate: "[N%]"
```

**VERIFICATION**:
- [ ] All timestamps extracted from checkpoints
- [ ] Duration calculations correct (no negative times)
- [ ] Parallelization metrics calculated (if applicable)
- [ ] Error recovery metrics calculated (if debugging occurred)

### Step 3: Invoke Doc-Writer Agent (EXECUTE NOW)

**Transform from**:
```markdown
**Task Tool Invocation**:
```yaml
subagent_type: general-purpose
description: "Update documentation for workflow using doc-writer protocol"
```

**Transform to**:
```markdown
**EXECUTE NOW: Invoke Doc-Writer Agent**

USE the Task tool to invoke the doc-writer agent NOW.

Task tool invocation:
```

#### Complete Task Tool Syntax

```yaml
subagent_type: general-purpose

description: "Update documentation and generate workflow summary using doc-writer protocol"

prompt: |
  Read and follow the behavioral guidelines from:
  /home/benjamin/.config/.claude/agents/doc-writer.md

  You are acting as a Documentation Writer Agent with the tools and constraints
  defined in that file.

  ## Documentation Task: Complete Workflow Documentation

  ### Workflow Context
  - **Original Request**: [workflow_description]
  - **Workflow Type**: [workflow_type]
  - **Project Name**: [project_name]
  - **Completion Date**: [current_date YYYY-MM-DD]

  ### Artifacts Generated

  **Research Reports** (if research phase completed):
  [For each report in research_reports:]
  - [report_path] - [topic]

  **Implementation Plan**:
  - Path: [plan_path]
  - Number: [plan_number]
  - Phases: [phase_count]

  **Implementation Status**:
  - Tests: [passing/fixed_after_debugging]
  - Phases Completed: [N/N]
  - Files Modified: [count] files
  - Git Commits: [count] commits

  **Debug Reports** (if debugging occurred):
  [For each report in debug_reports:]
  - [debug_report_path] - [issue resolved]
  - Iterations: [debug_iterations]

  ### Performance Metrics
  - Total Duration: [total_workflow_time HH:MM:SS]
  - Research Time: [research_phase_time or "Skipped"]
  - Planning Time: [planning_phase_time]
  - Implementation Time: [implementation_phase_time]
  - Debugging Time: [debugging_phase_time or "Not needed"]
  - Parallelization Savings: [time_saved_percentage% or "N/A"]
  - Error Recovery Rate: [recovery_success_rate% or "100% (no errors)"]

  ### Documentation Requirements

  1. **Update Project Documentation**:
     - Review files modified during implementation
     - Update relevant README files
     - Add usage examples where appropriate
     - Ensure documentation follows CLAUDE.md standards

  2. **Create Workflow Summary**:
     Create a comprehensive workflow summary file at:
     `[plan_directory]/specs/summaries/[plan_number]_workflow_summary.md`

     Use this exact template:

     ```markdown
     # Workflow Summary: [Feature/Task Name]

     ## Metadata
     - **Date Completed**: [YYYY-MM-DD]
     - **Specs Directory**: [specs_directory_path]
     - **Summary Number**: [NNN] (matches plan number)
     - **Workflow Type**: [feature|refactor|debug|investigation]
     - **Original Request**: [workflow_description]
     - **Total Duration**: [HH:MM:SS]

     ## Workflow Execution

     ### Phases Completed
     - [x] Research (parallel) - [duration or "Skipped"]
     - [x] Planning (sequential) - [duration]
     - [x] Implementation (adaptive) - [duration]
     - [x] Debugging (conditional) - [duration or "Not needed"]
     - [x] Documentation (sequential) - [duration]

     ### Artifacts Generated

     **Research Reports**:
     [If research phase completed, list each report:]
     - [Report 1: path - brief description]
     - [Report 2: path - brief description]

     [If no research: "(No research phase - direct implementation)"]

     **Implementation Plan**:
     - Path: [plan_path]
     - Phases: [phase_count]
     - Complexity: [Low|Medium|High]
     - Link: [relative link to plan file]

     **Debug Reports**:
     [If debugging occurred, list each report:]
     - [Debug report 1: path - issue addressed]

     [If no debugging: "(No debugging needed - tests passed on first run)"]

     ## Implementation Overview

     ### Key Changes
     **Files Created**:
     [For each new file:]
     - [new_file.ext] - [brief purpose]

     **Files Modified**:
     [For each modified file:]
     - [modified_file.ext] - [changes made]

     **Files Deleted**:
     [For each deleted file:]
     - [deleted_file.ext] - [reason for deletion]

     ### Technical Decisions
     [Key architectural or technical decisions made during workflow]
     - Decision 1: [what and why]
     - Decision 2: [what and why]

     ## Test Results

     **Final Status**: ✓ All tests passing

     [If debugging occurred:]
     **Debugging Summary**:
     - Iterations required: [debug_iterations]
     - Issues resolved:
       1. [Issue 1 and fix]
       2. [Issue 2 and fix]

     ## Performance Metrics

     ### Workflow Efficiency
     - Total workflow time: [HH:MM:SS]
     - Estimated manual time: [HH:MM:SS calculated estimate]
     - Time saved: [N%]

     ### Phase Breakdown
     | Phase | Duration | Status |
     |-------|----------|--------|
     | Research | [time] | [Completed/Skipped] |
     | Planning | [time] | Completed |
     | Implementation | [time] | Completed |
     | Debugging | [time] | [Completed/Not needed] |
     | Documentation | [time] | Completed |

     ### Parallelization Effectiveness
     [If research completed:]
     - Research agents used: [N]
     - Parallel vs sequential time: [N% faster]

     [If no research: "No parallel execution in this workflow"]

     ### Error Recovery
     [If debugging occurred:]
     - Total errors encountered: [N]
     - Automatically recovered: [N]
     - Manual interventions: [0 or N]
     - Recovery success rate: [N%]

     [If no errors: "Zero errors - clean implementation"]

     ## Cross-References

     ### Research Phase
     [If applicable:]
     This workflow incorporated findings from:
     - [Report 1 path and title]
     - [Report 2 path and title]

     ### Planning Phase
     Implementation followed the plan at:
     - [Plan path and title]

     ### Related Documentation
     Documentation updated includes:
     - [Doc 1 path]
     - [Doc 2 path]

     ## Lessons Learned

     ### What Worked Well
     - [Success 1 - what went smoothly]
     - [Success 2 - effective strategies]

     ### Challenges Encountered
     - [Challenge 1 and how it was resolved]
     - [Challenge 2 and resolution approach]

     ### Recommendations for Future
     - [Recommendation 1 for similar workflows]
     - [Recommendation 2 for improvements]

     ## Notes

     [Any additional context, caveats, or important information about this workflow]

     ---

     *Workflow orchestrated using /orchestrate command*
     *For questions or issues, refer to the implementation plan and research reports linked above.*
     ```

  3. **Create Cross-References**:

     a. **Update Implementation Plan** ([plan_path]):
        Add at bottom of plan file:
        ```markdown
        ## Implementation Summary
        This plan was executed on [YYYY-MM-DD]. See workflow summary:
        - [Summary path link]

        Status: ✅ COMPLETE
        - Duration: [HH:MM:SS]
        - Tests: All passing
        - Files modified: [N]
        ```

     b. **Update Research Reports** (if any):
        For each report in research_reports, add:
        ```markdown
        ## Implementation Reference
        Findings from this report were incorporated into:
        - [Plan path] - Implementation plan
        - [Summary path] - Workflow execution summary
        - Date: [YYYY-MM-DD]
        ```

     c. **Update Debug Reports** (if any):
        For each report in debug_reports, add:
        ```markdown
        ## Resolution Summary
        This issue was resolved during:
        - Workflow: [workflow_description]
        - Iteration: [N]
        - Summary: [Summary path link]
        ```

  ### Output Requirements

  Return results in this format:

  ```
  PROGRESS: Updating project documentation...
  PROGRESS: Updating [file1.ext]...
  PROGRESS: Updating [file2.ext]...
  PROGRESS: Creating workflow summary...
  PROGRESS: Adding cross-references...

  DOCUMENTATION_RESULTS:
  - updated_files: [list of documentation files modified]
  - readme_updates: [list of README files updated]
  - workflow_summary_created: [summary file path]
  - cross_references_added: [count]
  - documentation_complete: true
  ```

  ### Quality Checklist
  - [ ] Purpose clearly stated in updated docs
  - [ ] Usage examples included where appropriate
  - [ ] Cross-references added bidirectionally
  - [ ] Unicode box-drawing used (not ASCII art)
  - [ ] No emojis in content
  - [ ] Code examples have syntax highlighting
  - [ ] Navigation links updated
  - [ ] CommonMark compliant
  - [ ] Workflow summary follows template exactly
  - [ ] All cross-references validated (files exist)
```

**Monitoring During Agent Execution**:
- Watch for `PROGRESS: <message>` markers in agent output
- Display progress updates to user in real-time
- Verify summary file creation
- Validate cross-reference updates

**VERIFICATION**:
- [ ] Task tool invoked with doc-writer protocol
- [ ] Complete prompt provided inline (not referenced)
- [ ] Workflow summary template inlined in prompt
- [ ] Cross-reference instructions explicit
- [ ] Agent execution monitored (progress markers)

### Step 4: Extract Documentation Results (EXECUTE NOW)

**Transform from**:
```markdown
**Results Extraction**:
```markdown
From documentation agent output, extract:
- updated_files: [list of documentation files modified]
```

**Transform to**:
```markdown
**EXECUTE NOW: Extract and Validate Documentation Results**

PARSE the doc-writer agent output to extract results.

1. **Locate Results Block**:
   Search agent output for "DOCUMENTATION_RESULTS:" marker

2. **Extract Results Data**:
   ```yaml
   documentation_results:
     updated_files: [
       "file1.ext",
       "file2.ext"
     ]
     readme_updates: [
       "dir1/README.md",
       "dir2/README.md"
     ]
     workflow_summary_created: "specs/summaries/NNN_workflow_summary.md"
     cross_references_added: N
     documentation_complete: true
   ```

3. **Validate Results**:
   - At least one documentation file updated (updated_files not empty)
   - Workflow summary file created and exists
   - Cross-references count > 0 (at least plan → summary link)
   - documentation_complete is true

4. **Store in Workflow State**:
   ```yaml
   workflow_state.documentation_paths: [
     "specs/summaries/NNN_workflow_summary.md",
     ...updated_files,
     ...readme_updates
   ]
   ```
```

**Validation Checklist**:
- [ ] At least one documentation file updated
- [ ] Workflow summary file exists at expected path
- [ ] Summary file follows template structure (verify key sections present)
- [ ] Cross-references include all workflow artifacts
- [ ] Plan file updated with "Implementation Summary" section
- [ ] Research reports updated with "Implementation Reference" (if applicable)
- [ ] Debug reports updated with "Resolution Summary" (if applicable)
- [ ] No broken links (all referenced paths valid)
- [ ] Documentation follows project standards (CLAUDE.md compliance)

**Error Handling**:
```yaml
if documentation_complete == false:
  ERROR: "Documentation phase incomplete"
  → Check agent output for error messages
  → Verify doc-writer has Write and Edit tool access
  → Retry with clarified instructions if recoverable
  → Escalate to user if persistent failure

if workflow_summary_created == null:
  ERROR: "Workflow summary not created"
  → Check specs/summaries/ directory exists
  → Verify plan_number extracted correctly
  → Retry summary creation explicitly

if cross_references_added == 0:
  WARNING: "No cross-references created"
  → Cross-reference step may have failed
  → Manually update files if needed
  → Note in workflow completion message
```

**VERIFICATION**:
- [ ] Results extracted from agent output
- [ ] All expected fields present
- [ ] Validation checklist completed
- [ ] Error handling triggered if issues detected

### Step 5: Verify Cross-References (EXECUTE NOW)

**Add new step** (not in current implementation):

```markdown
**EXECUTE NOW: Verify Bidirectional Cross-References**

VALIDATE that cross-references were created correctly.

1. **Read Implementation Plan** ([plan_path]):
   ```
   USE Read tool to open plan file
   SEARCH for "## Implementation Summary" section
   VERIFY section exists and includes:
   - Summary path link
   - Completion date
   - Status (COMPLETE)
   ```

2. **Read Workflow Summary** ([summary_path]):
   ```
   USE Read tool to open summary file
   SEARCH for "## Cross-References" section
   VERIFY section includes:
   - Research reports (if applicable)
   - Implementation plan
   - Related documentation
   ```

3. **Read Research Reports** (if any):
   ```
   FOR each report in research_reports:
     USE Read tool to open report file
     SEARCH for "## Implementation Reference" section
     VERIFY section exists and includes:
     - Plan path link
     - Summary path link
     - Completion date
   ```

4. **Read Debug Reports** (if any):
   ```
   FOR each report in debug_reports:
     USE Read tool to open debug report file
     SEARCH for "## Resolution Summary" section
     VERIFY section includes:
     - Workflow description
     - Summary path link
   ```

**Cross-Reference Validation Matrix**:

| From | To | Link Type | Verified |
|------|-----|-----------|----------|
| Plan | Summary | Implementation Summary section | [ ] |
| Summary | Plan | Cross-References section | [ ] |
| Summary | Reports | Cross-References section | [ ] |
| Reports | Plan | Implementation Reference section | [ ] |
| Reports | Summary | Implementation Reference section | [ ] |
| Debug | Summary | Resolution Summary section | [ ] |

**If Validation Fails**:
```yaml
if any_validation_fails:
  WARNING: "Cross-reference validation failed"
  → Report which links are missing
  → Attempt manual cross-reference creation
  → Use Edit tool to add missing sections
  → Re-validate after manual fixes
```

**VERIFICATION**:
- [ ] All plan → summary links verified
- [ ] All summary → plan links verified
- [ ] All summary → report links verified (if applicable)
- [ ] All report → plan/summary links verified (if applicable)
- [ ] All debug → summary links verified (if applicable)
- [ ] Cross-reference matrix complete

### Step 6: Save Final Checkpoint (EXECUTE NOW)

**Transform from**:
```markdown
**Workflow Complete Checkpoint**:
```yaml
checkpoint_workflow_complete:
  phase_name: "documentation"
```

**Transform to**:
```markdown
**EXECUTE NOW: Save Final Workflow Checkpoint**

CREATE final checkpoint with complete workflow metrics.

USE checkpoint utility:
```bash
.claude/lib/save-checkpoint.sh orchestrate "$PROJECT_NAME" "$CHECKPOINT_DATA"
```

Where CHECKPOINT_DATA is:
```yaml
checkpoint_workflow_complete:
  # Phase identification
  phase_name: "documentation"
  completion_time: [current_timestamp]

  # Documentation outputs
  outputs:
    documentation_updated: [list of updated files]
    workflow_summary_created: "[summary_path]"
    cross_references_added: N
    status: "success"

  # Workflow completion
  next_phase: "complete"
  workflow_status: "success"

  # Complete workflow metrics
  final_metrics:
    # Time metrics
    total_workflow_time: "[HH:MM:SS]"
    total_minutes: N

    # Phase completion
    phases_completed: [
      "research",    # or "skipped"
      "planning",
      "implementation",
      "debugging",   # or "not_needed"
      "documentation"
    ]

    # Artifact counts
    artifacts_generated:
      research_reports: N
      implementation_plan: 1
      workflow_summary: 1
      debug_reports: N
      documentation_updates: N

    # File changes
    files_modified: N
    files_created: N
    files_deleted: N
    git_commits: N

    # Performance
    parallelization_savings: "[N% or 'N/A']"
    error_recovery_success: "[N% or '100% (no errors)']"

  # Complete workflow summary
  workflow_summary:
    research_reports: [list of paths]
    implementation_plan: "[plan_path]"
    workflow_summary: "[summary_path]"
    debug_reports: [list of paths]
    tests_passing: true
    documentation_complete: true
```

**Checkpoint File Location**:
```
.claude/data/checkpoints/orchestrate_${PROJECT_NAME}_${TIMESTAMP}.json
```

**VERIFICATION**:
- [ ] Checkpoint saved successfully
- [ ] All workflow metrics included
- [ ] Artifact paths recorded
- [ ] Status set to "complete"

### Step 7: Conditional PR Creation (EXECUTE NOW)

**Transform from**:
```markdown
**When to Create PR:**
- If `--create-pr` flag is provided, OR
```

**Transform to**:
```markdown
**EXECUTE NOW: Check for PR Creation Flag**

EVALUATE whether to create a pull request.

1. **Check for --create-pr Flag**:
   ```
   if "--create-pr" in original_command_arguments:
     pr_creation_required = true
   else:
     pr_creation_required = false
   ```

2. **Prerequisites Check** (if pr_creation_required):
   ```bash
   # Check if gh CLI is available and authenticated
   if ! command -v gh &>/dev/null; then
     echo "Note: gh CLI not installed. Skipping PR creation."
     echo "Install: brew install gh (or equivalent)"
     pr_creation_required = false
   fi

   if ! gh auth status &>/dev/null; then
     echo "Note: gh CLI not authenticated. Skipping PR creation."
     echo "Run: gh auth login"
     pr_creation_required = false
   fi
   ```

3. **Invoke github-specialist Agent** (if pr_creation_required):

   **EXECUTE NOW: Invoke GitHub Specialist Agent**

   USE the Task tool to invoke github-specialist agent NOW.

   Task tool invocation:
   ```yaml
   subagent_type: general-purpose

   description: "Create PR for completed workflow using github-specialist protocol"

   prompt: |
     Read and follow the behavioral guidelines from:
     /home/benjamin/.config/.claude/agents/github-specialist.md

     You are acting as a GitHub Specialist Agent with the tools and constraints
     defined in that file.

     ## PR Creation Task: Workflow Completion Pull Request

     ### Workflow Context
     - **Plan**: [absolute path to implementation plan]
     - **Branch**: [current branch name from git]
     - **Base**: main (or master, detect from repo)
     - **Summary**: [absolute path to workflow summary]
     - **Original Request**: [workflow_description]

     ### PR Description Content

     Create a comprehensive PR description following this structure:

     ```markdown
     # [Feature/Task Name]

     ## Summary
     [Brief 1-2 sentence summary of what was implemented]

     ## Workflow Overview
     This PR was created through a complete /orchestrate workflow:

     **Research Phase**: [N reports generated or "Skipped"]
     [If research completed:]
     - [Report 1 title and key finding]
     - [Report 2 title and key finding]

     **Planning Phase**: [Phase count]-phase implementation plan
     - Complexity: [Low|Medium|High]
     - See: [plan path]

     **Implementation Phase**: All [N] phases completed successfully
     - Tests: [All passing or Fixed after M debug iterations]
     - Files modified: [N]
     - Commits: [N]

     **Debugging Phase**: [N iterations or "Not needed"]
     [If debugging occurred:]
     - Issues resolved: [M]
     - See debug reports: [debug report paths]

     **Documentation Phase**: [N] files updated
     - Documentation: [list updated files]
     - Workflow summary: [summary path]

     ## Performance Metrics
     - **Total Duration**: [HH:MM:SS]
     - **Parallelization Savings**: [N% or "N/A"]
     - **Error Recovery**: [success rate or "100% (no errors)"]

     ## File Changes
     [Use git diff --stat to show change summary]

     **Files Created**: [N]
     **Files Modified**: [N]
     **Files Deleted**: [N]

     ## Cross-References

     **Implementation Plan**: [plan path]
     **Workflow Summary**: [summary path]
     [If research:]
     **Research Reports**:
     - [report 1 path]
     - [report 2 path]
     [If debugging:]
     **Debug Reports**:
     - [debug report 1 path]

     ## Test Results
     ✓ All tests passing

     [If debugging occurred:]
     Fixed issues:
     1. [Issue 1 description]
     2. [Issue 2 description]

     ## Checklist
     - [x] All implementation phases completed
     - [x] Tests passing
     - [x] Documentation updated
     - [x] Code follows project standards
     - [ ] Ready for review
     ```

     ### Output Required

     Return PR details in this format:
     ```
     PR_CREATED:
     - url: [PR URL]
     - number: [PR number]
     - branch: [feature branch]
     - base: [base branch]
     ```
   ```

4. **Capture PR URL** (if created):
   ```
   PARSE github-specialist output for PR_CREATED block
   EXTRACT pr_url and pr_number

   STORE in workflow_state:
   workflow_state.pr_url = pr_url
   workflow_state.pr_number = pr_number
   ```

5. **Update Workflow Summary with PR Link** (if created):
   ```
   USE Edit tool to update workflow summary file
   ADD section at bottom:

   ## Pull Request
   - **PR**: [pr_url]
   - **Number**: #[pr_number]
   - **Created**: [YYYY-MM-DD]
   - **Status**: Open
   ```

6. **Graceful Degradation** (if PR creation fails):
   ```yaml
   if pr_creation_fails:
     LOG error message from github-specialist

     DISPLAY manual PR creation command:
     ```
     To create PR manually:

     gh pr create \
       --title "feat: [feature name]" \
       --body-file [pr_description_file] \
       --base main
     ```

     CONTINUE workflow (don't block on PR failure)
   ```
```

**VERIFICATION**:
- [ ] --create-pr flag checked
- [ ] Prerequisites validated (gh CLI, auth)
- [ ] github-specialist agent invoked (if required)
- [ ] PR URL captured and stored
- [ ] Workflow summary updated with PR link
- [ ] Error handled gracefully (if PR creation fails)

### Step 8: Workflow Completion Message (EXECUTE NOW)

**Transform from**:
```markdown
**Final Output to User**:
```markdown
✅ Workflow Complete
```

**Transform to**:
```markdown
**EXECUTE NOW: Display Workflow Completion Message**

OUTPUT final workflow summary to user.

USE this exact format:

```markdown
┌─────────────────────────────────────────────────────────────┐
│                     WORKFLOW COMPLETE                       │
└─────────────────────────────────────────────────────────────┘

**Duration**: [HH:MM:SS]

**Phases Executed**:
[If research completed:]
✓ Research (parallel) - [duration]
  - Topics: [N]
  - Reports: [report paths]

✓ Planning (sequential) - [duration]
  - Plan: [plan_path]
  - Phases: [N]

✓ Implementation (adaptive) - [duration]
  - Phases completed: [N/N]
  - Files modified: [N]
  - Git commits: [N]

[If debugging occurred:]
✓ Debugging ([N] iterations) - [duration]
  - Issues resolved: [M]
  - Debug reports: [debug report paths]

✓ Documentation (sequential) - [duration]
  - Documentation updates: [N] files
  - Workflow summary: [summary_path]
  - Cross-references: [N] links

**Implementation Results**:
- Files created: [N]
- Files modified: [N]
- Files deleted: [N]
- Tests: ✓ All passing

**Performance Metrics**:
[If parallelization used:]
- Time saved via parallelization: [N%]
[If error recovery occurred:]
- Error recovery: [N/M errors auto-recovered]
[Else:]
- Error-free execution: 100%

**Artifacts Generated**:
[If research:]
- Research reports: [N] reports in [M] topics
[Always:]
- Implementation plan: [plan_path]
- Workflow summary: [summary_path]
[If debugging:]
- Debug reports: [N] reports

[If PR created:]
**Pull Request**:
- PR #[pr_number]: [pr_url]
- Status: Open for review

**Next Steps**:
[If PR created:]
1. Review PR at [pr_url]
2. Request reviews from team members
3. Merge when approved

[Else:]
1. Review workflow summary: [summary_path]
2. Review implementation plan: [plan_path]
3. Consider creating PR with: gh pr create

**Summary**: [summary_path]
Review the workflow summary for complete details, cross-references, and lessons learned.

┌─────────────────────────────────────────────────────────────┐
│  All workflow artifacts saved and cross-referenced.         │
│  Thank you for using /orchestrate!                          │
└─────────────────────────────────────────────────────────────┘
```
```

**Completion Data to Display**:

Extract from workflow_state and performance_summary:
- Total duration (formatted HH:MM:SS)
- All phase durations (or "Skipped"/"Not needed")
- Artifact counts and paths
- File modification counts
- Test status
- Performance metrics (parallelization, error recovery)
- PR information (if created)

**VERIFICATION**:
- [ ] Completion message displayed to user
- [ ] All key metrics included
- [ ] Artifact paths provided
- [ ] Next steps suggested
- [ ] Message formatted clearly (Unicode box-drawing)

### Step 9: Cleanup Final Checkpoint (EXECUTE NOW)

**Add new step** (cleanup after successful completion):

```markdown
**EXECUTE NOW: Cleanup Completed Workflow Checkpoint**

REMOVE checkpoint file after successful workflow completion.

```bash
# Delete checkpoint file (workflow complete, no resume needed)
rm -f .claude/data/checkpoints/orchestrate_${PROJECT_NAME}_*.json

# Log completion
echo "[$(date)] Workflow ${PROJECT_NAME} completed successfully" >> .claude/logs/orchestrate.log
```

**Checkpoint Cleanup Logic**:
```yaml
if workflow_status == "success":
  → Delete checkpoint file (no longer needed)
  → Log completion to orchestrate.log

elif workflow_status == "escalated":
  → Keep checkpoint file (user may resume)
  → Move to .claude/data/checkpoints/failed/ for investigation

elif workflow_status == "error":
  → Keep checkpoint file (debugging needed)
  → Archive to .claude/data/checkpoints/failed/
```

**VERIFICATION**:
- [ ] Checkpoint file removed (if success)
- [ ] Completion logged
- [ ] Failed checkpoints archived (if applicable)

## Workflow Summary Template

**Complete Markdown Template for Workflow Summary**:

This template is inlined in the doc-writer agent prompt (Step 3) but reproduced here for reference:

```markdown
# Workflow Summary: [Feature/Task Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Specs Directory**: [specs_directory_path]
- **Summary Number**: [NNN] (matches plan number)
- **Workflow Type**: [feature|refactor|debug|investigation]
- **Original Request**: [workflow_description]
- **Total Duration**: [HH:MM:SS]

## Workflow Execution

### Phases Completed
- [x] Research (parallel) - [duration or "Skipped"]
- [x] Planning (sequential) - [duration]
- [x] Implementation (adaptive) - [duration]
- [x] Debugging (conditional) - [duration or "Not needed"]
- [x] Documentation (sequential) - [duration]

### Artifacts Generated

**Research Reports**:
[If research phase completed, list each report:]
- [Report 1: path - brief description]
- [Report 2: path - brief description]

[If no research: "(No research phase - direct implementation)"]

**Implementation Plan**:
- Path: [plan_path]
- Phases: [phase_count]
- Complexity: [Low|Medium|High]
- Link: [relative link to plan file]

**Debug Reports**:
[If debugging occurred, list each report:]
- [Debug report 1: path - issue addressed]

[If no debugging: "(No debugging needed - tests passed on first run)"]

## Implementation Overview

### Key Changes
**Files Created**:
- [new_file.ext] - [brief purpose]

**Files Modified**:
- [modified_file.ext] - [changes made]

**Files Deleted**:
- [deleted_file.ext] - [reason for deletion]

### Technical Decisions
[Key architectural or technical decisions made during workflow]
- Decision 1: [what and why]
- Decision 2: [what and why]

## Test Results

**Final Status**: ✓ All tests passing

[If debugging occurred:]
**Debugging Summary**:
- Iterations required: [debug_iterations]
- Issues resolved:
  1. [Issue 1 and fix]
  2. [Issue 2 and fix]

## Performance Metrics

### Workflow Efficiency
- Total workflow time: [HH:MM:SS]
- Estimated manual time: [HH:MM:SS calculated estimate]
- Time saved: [N%]

### Phase Breakdown
| Phase | Duration | Status |
|-------|----------|--------|
| Research | [time] | [Completed/Skipped] |
| Planning | [time] | Completed |
| Implementation | [time] | Completed |
| Debugging | [time] | [Completed/Not needed] |
| Documentation | [time] | Completed |

### Parallelization Effectiveness
[If research completed:]
- Research agents used: [N]
- Parallel vs sequential time: [N% faster]

[If no research: "No parallel execution in this workflow"]

### Error Recovery
[If debugging occurred:]
- Total errors encountered: [N]
- Automatically recovered: [N]
- Manual interventions: [0 or N]
- Recovery success rate: [N%]

[If no errors: "Zero errors - clean implementation"]

## Cross-References

### Research Phase
[If applicable:]
This workflow incorporated findings from:
- [Report 1 path and title]
- [Report 2 path and title]

### Planning Phase
Implementation followed the plan at:
- [Plan path and title]

### Related Documentation
Documentation updated includes:
- [Doc 1 path]
- [Doc 2 path]

## Lessons Learned

### What Worked Well
- [Success 1 - what went smoothly]
- [Success 2 - effective strategies]

### Challenges Encountered
- [Challenge 1 and how it was resolved]
- [Challenge 2 and resolution approach]

### Recommendations for Future
- [Recommendation 1 for similar workflows]
- [Recommendation 2 for improvements]

## Notes

[Any additional context, caveats, or important information about this workflow]

---

*Workflow orchestrated using /orchestrate command*
*For questions or issues, refer to the implementation plan and research reports linked above.*
```

## Cross-Reference Implementation

### Bidirectional Linking Strategy

The documentation phase establishes comprehensive cross-references between all workflow artifacts:

**1. Plan → Summary Link**:
```markdown
In plan file (specs/plans/NNN_*.md), add at bottom:

## Implementation Summary
This plan was executed on [YYYY-MM-DD]. See workflow summary:
- [Workflow Summary](../summaries/NNN_workflow_summary.md)

Status: ✅ COMPLETE
- Duration: [HH:MM:SS]
- Tests: All passing
- Files modified: [N]
```

**2. Summary → Plan Link**:
```markdown
In summary file (specs/summaries/NNN_*.md), add in Cross-References section:

### Planning Phase
Implementation followed the plan at:
- [Implementation Plan](../plans/NNN_plan_name.md)
```

**3. Summary → Reports Links**:
```markdown
In summary file, add in Cross-References section:

### Research Phase
This workflow incorporated findings from:
- [Report 1](../reports/topic1/001_report.md)
- [Report 2](../reports/topic2/001_report.md)
```

**4. Reports → Plan/Summary Links**:
```markdown
In each report file (specs/reports/topic/NNN_*.md), add:

## Implementation Reference
Findings from this report were incorporated into:
- [Implementation Plan](../../plans/NNN_plan_name.md)
- [Workflow Summary](../../summaries/NNN_workflow_summary.md)
- Date: [YYYY-MM-DD]
```

**5. Debug → Summary Links**:
```markdown
In each debug report file (debug/topic/NNN_*.md), add:

## Resolution Summary
This issue was resolved during:
- Workflow: [workflow_description]
- Iteration: [N]
- Summary: [path to summary]
```

### Link Validation Algorithm

```
FOR each artifact file:
  READ file content
  EXTRACT all relative path links
  FOR each link:
    RESOLVE absolute path
    CHECK file exists
    IF not exists:
      ERROR: Broken link [link] in [artifact]
    ENDIF
  ENDFOR
ENDFOR
```

## Code Examples

### Performance Metric Calculation

```bash
# Extract timestamps from checkpoints
WORKFLOW_START=$(cat .claude/data/checkpoints/orchestrate_${PROJECT}_*.json | jq -r '.workflow_start_time')
WORKFLOW_END=$(date +%s)

# Calculate total duration
TOTAL_SECONDS=$((WORKFLOW_END - WORKFLOW_START))
HOURS=$((TOTAL_SECONDS / 3600))
MINUTES=$(((TOTAL_SECONDS % 3600) / 60))
SECONDS=$((TOTAL_SECONDS % 60))
TOTAL_DURATION=$(printf "%02d:%02d:%02d" $HOURS $MINUTES $SECONDS)

# Calculate phase durations
RESEARCH_START=$(cat checkpoint.json | jq -r '.research_start')
RESEARCH_END=$(cat checkpoint.json | jq -r '.research_end')
RESEARCH_DURATION=$((RESEARCH_END - RESEARCH_START))

# Calculate parallelization savings (if research completed)
if [ "$RESEARCH_REPORTS" -gt 0 ]; then
  PARALLEL_AGENTS=$RESEARCH_REPORTS
  AVG_RESEARCH_TIME=300  # 5 minutes average per topic
  ESTIMATED_SEQUENTIAL=$((PARALLEL_AGENTS * AVG_RESEARCH_TIME))
  ACTUAL_PARALLEL=$RESEARCH_DURATION
  TIME_SAVED=$((ESTIMATED_SEQUENTIAL - ACTUAL_PARALLEL))
  SAVINGS_PCT=$((TIME_SAVED * 100 / ESTIMATED_SEQUENTIAL))
fi
```

### Cross-Reference Creation

```bash
# Function to add implementation summary to plan
add_plan_summary() {
  local plan_path=$1
  local summary_path=$2
  local completion_date=$3
  local duration=$4

  cat >> "$plan_path" <<EOF

## Implementation Summary
This plan was executed on ${completion_date}. See workflow summary:
- [Workflow Summary](${summary_path})

Status: ✅ COMPLETE
- Duration: ${duration}
- Tests: All passing
- Files modified: ${FILES_MODIFIED_COUNT}
EOF
}

# Function to add implementation reference to reports
add_report_reference() {
  local report_path=$1
  local plan_path=$2
  local summary_path=$3
  local completion_date=$4

  cat >> "$report_path" <<EOF

## Implementation Reference
Findings from this report were incorporated into:
- [Implementation Plan](${plan_path})
- [Workflow Summary](${summary_path})
- Date: ${completion_date}
EOF
}
```

## Testing Specifications

### Test Case 1: Simple Workflow (No Research)

**Scenario**: Feature implementation without research phase

**Execute**:
```bash
/orchestrate "Add configuration validation helper function"
```

**Verify Documentation Phase**:
- [ ] doc-writer agent invoked (Task tool used)
- [ ] Project documentation updated (README or module docs)
- [ ] Workflow summary created at specs/summaries/NNN_*.md
- [ ] Plan updated with "Implementation Summary" section
- [ ] No research reports (research skipped)
- [ ] No debug reports (tests passed first time)
- [ ] Completion message displayed with all artifacts

### Test Case 2: Medium Workflow (Research + Implementation)

**Scenario**: Feature with research phase

**Execute**:
```bash
/orchestrate "Implement JWT authentication middleware"
```

**Verify Documentation Phase**:
- [ ] doc-writer agent invoked with complete prompt
- [ ] Workflow summary includes research reports section
- [ ] Research reports updated with "Implementation Reference"
- [ ] Plan updated with "Implementation Summary"
- [ ] Cross-references bidirectional (validated)
- [ ] Performance metrics include parallelization savings
- [ ] Completion message shows all phases

### Test Case 3: Complex Workflow (With Debugging)

**Scenario**: Implementation requiring debugging iterations

**Execute**:
```bash
/orchestrate "Add database transaction rollback support"
# (with intentional test failures)
```

**Verify Documentation Phase**:
- [ ] Workflow summary includes debugging section
- [ ] Debug reports listed in summary
- [ ] Debug reports updated with "Resolution Summary"
- [ ] Performance metrics include error recovery rate
- [ ] Completion message shows debugging iterations

### Test Case 4: PR Creation Workflow

**Scenario**: Complete workflow with PR creation

**Execute**:
```bash
/orchestrate "Add user profile API endpoints" --create-pr
```

**Verify Documentation Phase**:
- [ ] gh CLI prerequisites checked
- [ ] github-specialist agent invoked (if prerequisites met)
- [ ] PR created successfully
- [ ] PR URL captured and stored
- [ ] Workflow summary updated with PR section
- [ ] Completion message includes PR link
- [ ] If PR fails, graceful degradation and manual command provided

### Test Case 5: Cross-Reference Validation

**Scenario**: Validate bidirectional linking

**After any workflow completion**:
```bash
# Verify plan → summary link
grep -q "Implementation Summary" specs/plans/NNN_*.md

# Verify summary → plan link
grep -q "Implementation Plan" specs/summaries/NNN_*.md

# Verify summary → reports links (if research)
grep -q "Research Phase" specs/summaries/NNN_*.md

# Verify reports → summary links (if research)
for report in specs/reports/*/001_*.md; do
  grep -q "Implementation Reference" "$report"
done

# Verify debug → summary links (if debugging)
for debug in debug/*/001_*.md; do
  grep -q "Resolution Summary" "$debug"
done
```

**Verify**:
- [ ] All plan → summary links exist
- [ ] All summary → plan links exist
- [ ] All summary → report links exist (if applicable)
- [ ] All report → summary links exist (if applicable)
- [ ] All debug → summary links exist (if applicable)
- [ ] No broken links (all paths valid)

## Error Handling

### Error Case 1: Doc-Writer Agent Fails

**Symptom**: documentation_complete == false in results

**Diagnosis**:
1. Check doc-writer agent output for error messages
2. Verify doc-writer has required tools (Write, Edit)
3. Check file permissions on documentation directories

**Recovery**:
```yaml
if documentation_agent_fails:
  → Log error details
  → Retry with simplified prompt (core docs only)
  → If retry fails: Create minimal workflow summary manually
  → Update plan file manually with summary reference
  → Continue to completion message
```

### Error Case 2: Workflow Summary Creation Fails

**Symptom**: workflow_summary_created == null in results

**Diagnosis**:
1. Check specs/summaries/ directory exists
2. Verify plan_number extracted correctly from plan_path
3. Check file write permissions

**Recovery**:
```yaml
if summary_creation_fails:
  → Create specs/summaries/ directory if missing
  → Extract plan number from plan file metadata
  → Invoke doc-writer agent again with explicit summary path
  → If persistent failure: Generate summary manually using template
```

### Error Case 3: Cross-Reference Validation Fails

**Symptom**: Cross-reference verification checklist incomplete

**Diagnosis**:
1. Use Read tool to check each artifact file
2. Search for expected section headers
3. Identify which links are missing

**Recovery**:
```yaml
if cross_reference_validation_fails:
  → Report which artifacts missing links
  → Use Edit tool to add missing sections manually
  → Follow cross-reference templates from Step 5
  → Re-validate after manual additions
  → If validation passes: Continue
  → If validation still fails: Warn user and continue
```

### Error Case 4: PR Creation Fails

**Symptom**: github-specialist agent reports error

**Diagnosis**:
1. Check gh CLI installation (command -v gh)
2. Check gh authentication (gh auth status)
3. Check repository remote configuration
4. Review github-specialist error message

**Recovery**:
```yaml
if pr_creation_fails:
  → Log error from github-specialist
  → Generate manual PR creation command:
    gh pr create \
      --title "feat: [feature name]" \
      --body "$(cat pr_description.txt)" \
      --base main
  → Display manual command to user
  → Continue workflow (don't block on PR failure)
  → Mark workflow as complete (PR optional)
```

### Error Case 5: Performance Metric Calculation Fails

**Symptom**: Division by zero, negative durations, missing timestamps

**Diagnosis**:
1. Check checkpoints have timestamps
2. Verify timestamp format consistency
3. Check for clock skew issues

**Recovery**:
```yaml
if metric_calculation_fails:
  → Use fallback values:
    - total_duration: "Unknown"
    - phase_durations: "Not recorded"
    - parallelization_savings: "N/A"
  → Include error note in workflow summary
  → Continue with available metrics
```

## Success Criteria

### Phase Success Criteria

- [ ] **Passive to Active**: All "I'll" and "For each" converted to imperative commands
- [ ] **EXECUTE NOW Blocks**: Added for Steps 1-3, 5-9 (explicit execution instructions)
- [ ] **Task Tool Usage**: doc-writer agent invoked with complete inline prompt
- [ ] **Template Inlined**: Workflow summary template inlined in agent prompt (not referenced)
- [ ] **Cross-References**: Bidirectional linking established and validated
- [ ] **Performance Metrics**: Calculated explicitly with algorithm provided
- [ ] **PR Creation**: Conditional logic implemented with github-specialist invocation
- [ ] **Verification Checklists**: Added after each major step
- [ ] **Error Handling**: Comprehensive error recovery for all failure modes

### Integration Success Criteria

- [ ] **Agent Invocation Verified**: Test workflow confirms doc-writer agent actually invoked
- [ ] **Files Created**: Workflow summary created at correct path with correct numbering
- [ ] **Template Compliance**: Summary file follows template structure exactly
- [ ] **Cross-Reference Validation**: All bidirectional links verified programmatically
- [ ] **Performance Metrics Accurate**: Calculations produce correct durations and percentages
- [ ] **PR Creation Optional**: Workflow completes successfully with or without --create-pr
- [ ] **Completion Message**: User sees formatted completion message with all artifacts
- [ ] **Checkpoint Cleanup**: Final checkpoint saved then deleted on success

### Documentation Success Criteria

- [ ] **orchestrate.md Updated**: Lines 1138-1600 refactored to execution-driven
- [ ] **EXECUTE NOW Visible**: Every major step has explicit execution block
- [ ] **Inline Content**: Summary template, PR template, cross-reference logic all inline
- [ ] **No External References**: Pattern references replaced with inline instructions
- [ ] **Clear Flow**: Steps flow logically from context gathering → agent invocation → validation → completion

## Notes

### Summary Best Practices

**Content Guidelines**:
- Keep summary concise but complete (target 300-500 lines)
- Include specific file paths and line numbers where relevant
- Document technical decisions with rationale
- List lessons learned (what worked, what didn't)
- Provide actionable recommendations for future workflows

**Cross-Reference Strategy**:
- Always link summary → plan (planning phase reference)
- Always link plan → summary (implementation completion)
- Link summary → reports only if research phase completed
- Link reports → summary only after implementation complete
- Link debug reports → summary for resolution traceability

**Performance Metrics Guidelines**:
- Calculate parallelization savings conservatively (don't overstate)
- Estimate manual time based on realistic developer hours
- Include error recovery rate even if 100% (shows reliability)
- Break down time by phase for transparency

### PR Creation Considerations

**When to Create PRs**:
- Large features benefiting from team review
- Breaking changes requiring discussion
- Refactors needing validation
- Security-related implementations

**When to Skip PRs**:
- Small bug fixes
- Documentation-only updates
- Personal/exploratory projects
- Local development workflows

**PR Description Best Practices**:
- Lead with clear summary (1-2 sentences)
- Include workflow overview showing methodology
- List all artifacts (reports, plan, summary) for reviewer context
- Show performance metrics to demonstrate efficiency
- Provide file change summary for quick review
- Link to workflow summary for complete details

### Workflow Summary Maintenance

**Periodic Review**:
- Review summaries monthly to identify patterns
- Look for common challenges across workflows
- Identify opportunities for process improvement
- Archive old summaries (>6 months) to separate directory

**Quality Improvement**:
- Standardize "Lessons Learned" content across summaries
- Ensure recommendations are actionable and specific
- Validate cross-references remain valid (files not moved/deleted)
- Update summary template based on feedback

### Integration with Other Phases

**From Phase 5** (Debugging):
- Documentation phase receives debug_reports array
- Must document debugging iterations and resolutions
- Include error recovery rate in performance metrics

**To Phase 7** (Infrastructure):
- Documentation phase demonstrates complete workflow
- Provides model for state management and verification
- Validates checkpoint and TodoWrite integration

**To Phase 8** (Testing):
- Documentation phase completion marks workflow end
- All artifacts generated and cross-referenced
- Provides basis for end-to-end testing validation

### Complexity Justification

**Phase Complexity: 7/10 (Medium-High)**

Factors contributing to complexity:
1. **Multiple Sub-Steps**: 9 detailed steps with EXECUTE NOW blocks
2. **Agent Coordination**: doc-writer and optionally github-specialist
3. **Cross-Referencing**: Bidirectional linking requires careful validation
4. **Performance Calculations**: Complex metric calculations with edge cases
5. **Template Management**: Large inline template (200+ lines)
6. **Conditional Logic**: PR creation requires prerequisite checks
7. **Error Handling**: Multiple failure modes to handle gracefully

Not maximally complex because:
- Single primary agent (doc-writer)
- No iterative loops (unlike debugging phase)
- Clear sequential flow (no complex branching)

### Estimated Hours Breakdown

**4-5 hours total**:
- Step 1-2 (Context + Metrics): 30 minutes
- Step 3 (Agent Invocation): 90 minutes (large inline prompt)
- Step 4-5 (Results + Validation): 45 minutes
- Step 6 (Checkpoint): 15 minutes
- Step 7 (PR Creation): 60 minutes (conditional logic + github-specialist)
- Step 8-9 (Completion + Cleanup): 30 minutes
- Testing and validation: 60 minutes

### Success Indicators

Phase 6 succeeds when:
1. Test workflow demonstrates actual doc-writer invocation
2. Workflow summary created with correct template structure
3. All cross-references validated programmatically
4. Performance metrics calculated accurately
5. PR created successfully (if --create-pr provided)
6. User receives clear completion message
7. Final checkpoint saved and cleaned up
8. All verification checklists complete

This completes the documentation phase refactor and enables end-to-end workflow orchestration.

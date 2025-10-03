---
allowed-tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob, TodoWrite
argument-hint: [plan-file] [starting-phase]
description: Execute implementation plan with automated testing and commits (auto-resumes most recent incomplete plan if no args)
command-type: primary
dependent-commands: list-plans, update-plan, list-summaries, revise, debug, document
---

# Execute Implementation Plan

I'll help you systematically implement the plan file with automated testing and commits at each phase.

## Plan Information
- **Plan file**: $1 (or I'll find the most recent incomplete plan)
- **Starting phase**: $2 (default: resume from last incomplete phase or 1)

## Auto-Resume Feature
If no plan file is provided, I will:
1. Search for the most recently modified implementation plan
2. Check if it has incomplete phases or tasks
3. Resume from the first incomplete phase
4. If all recent plans are complete, show a list to choose from

## Standards Discovery and Application

Before implementing, I'll discover and apply project standards from CLAUDE.md:

### Discovery Process
1. **Locate CLAUDE.md**: Search upward from working directory and target directories
2. **Check Subdirectory Standards**: Look for directory-specific CLAUDE.md files
3. **Parse Relevant Sections**: Extract Code Standards, Testing Protocols
4. **Handle Missing Standards**: Fall back to language-specific defaults

### Standards Sections Used
- **Code Standards**: Indentation, line length, naming conventions, error handling
- **Testing Protocols**: Test commands, patterns, coverage requirements
- **Documentation Policy**: Documentation requirements for new code
- **Standards Discovery**: Discovery method, inheritance rules, fallback behavior

### Application During Implementation
Standards influence implementation as follows:

#### Code Generation
- **Indentation**: Generated code matches CLAUDE.md indentation spec (e.g., 2 spaces)
- **Line Length**: Keep lines within specified limit (e.g., ~100 characters)
- **Naming**: Follow naming conventions (e.g., snake_case vs camelCase)
- **Error Handling**: Use specified error handling patterns (e.g., pcall for Lua)
- **Module Organization**: Follow project structure patterns

#### Testing
- **Test Commands**: Use test commands from Testing Protocols (e.g., `:TestSuite`)
- **Test Patterns**: Create test files matching patterns (e.g., `*_spec.lua`)
- **Coverage**: Aim for coverage requirements from standards

#### Documentation
- **Inline Comments**: Document complex logic
- **Module Headers**: Add purpose and API documentation
- **README Updates**: Follow Documentation Policy requirements

### Compliance Verification
Before marking each phase complete and committing:
- [ ] Code style matches CLAUDE.md specifications (indentation, line length)
- [ ] Naming follows project conventions
- [ ] Error handling matches project patterns
- [ ] Tests follow testing standards and pass
- [ ] Documentation meets policy requirements (if new modules created)

### Fallback Behavior
When CLAUDE.md not found or incomplete:
1. **Use Language Defaults**: Apply sensible language-specific conventions
2. **Suggest Creation**: Recommend running `/setup` to create CLAUDE.md
3. **Graceful Degradation**: Continue with reduced standards enforcement
4. **Document Limitations**: Note in commit message which standards were uncertain

### Example: Standards Application

```lua
-- From CLAUDE.md Code Standards:
-- Indentation: 2 spaces, expandtab
-- Naming: snake_case for variables/functions
-- Error Handling: Use pcall for operations that might fail

local function process_user_data(user_id)  -- snake_case naming
  local status, result = pcall(function()  -- pcall error handling
    local data = database.query({          -- 2-space indentation
      id = user_id,
      fields = {"name", "email"}
    })
    return data
  end)

  if not status then                       -- error handling pattern
    print("Error: " .. result)
    return nil
  end

  return result
end
```

## Process

Let me first locate the implementation plan:

1. **Parse the plan** to identify:
   - Phases and tasks
   - Referenced research reports (if any)
   - Standards file path (if captured in plan metadata)
2. **Discover and load standards**:
   - Find CLAUDE.md files (working directory and subdirectories)
   - Extract Code Standards, Testing Protocols, Documentation Policy
   - Note standards for application during implementation
3. **Check for research reports**:
   - Extract report paths from plan metadata
   - Note reports for summary generation
4. **For each phase**:
   - Display the phase name and tasks
   - Implement changes following discovered standards
   - Run tests using standards-defined test commands
   - Verify compliance with standards before completing
   - Update the plan file with completion markers
   - Create a git commit with a structured message
   - Move to the next phase
5. **After all phases complete**:
   - Generate implementation summary
   - Update referenced reports if needed
   - Link plan and reports in summary

## Phase Execution Protocol

For each phase, I will:

### 1. Display Phase Information
Show the current phase number, name, and all tasks that need to be completed.

### 2. Implementation
Create or modify the necessary files according to the plan specifications.

### 3. Testing
Run tests by:
- Looking for test commands in the phase tasks
- Checking for common test patterns (npm test, pytest, make test)
- Running language-specific test commands based on project type

### 3.5. Update Debug Resolution (if tests pass for previously-failed phase)
**Check if this phase was previously debugged:**

**Step 1: Check for Debugging Notes**
- Read current phase section in plan
- Look for "#### Debugging Notes" subsection
- Check if it contains "Resolution: Pending"

**Step 2: Update Resolution**
- If debugging notes exist and tests now pass:
  - Use Edit tool to update: `Resolution: Pending` → `Resolution: Applied`
  - Add git commit hash line (will be added after commit)
  - This marks that the debugging led to a successful fix

**Step 3: Add Fix Commit Hash (after git commit)**
- After git commit succeeds
- If resolution was updated: Add commit hash to debugging notes
- Format: `Fix Applied In: [commit-hash]`

**Example:**
```markdown
#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase failed with null pointer
- **Debug Report**: [../reports/026_debug.md](../reports/026_debug.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

### 4. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 5. Plan Update (After Git Commit Succeeds)
**Incremental plan updates after each phase:**

**Step 1: Mark Phase Tasks Complete**
- Use Edit tool to change all phase tasks: `- [ ]` → `- [x]`
- Find each unchecked task in the phase section
- Replace with checked version

**Step 2: Add Phase Completion Marker**
- Use Edit tool to add `[COMPLETED]` to phase heading
- Change: `### Phase N: Phase Name` → `### Phase N: Phase Name [COMPLETED]`

**Step 3: Verify Plan Updated**
- Use Read tool to read back the plan file
- Check that phase heading has `[COMPLETED]`
- Check that all phase tasks are `[x]`
- If verification fails: Log warning but continue (don't block workflow)

**Step 4: Add/Update Implementation Progress Section**
- Use Edit tool to add or update "## Implementation Progress" section
- Place after metadata, before overview
- Include:
  - Last completed phase number and name
  - Completion date
  - Git commit hash
  - Resume instructions: `/implement <plan-file> <next-phase-number>`

**Example Implementation Progress Section:**
```markdown
## Implementation Progress

- **Last Completed Phase**: Phase 2: Core Implementation
- **Date**: 2025-10-03
- **Commit**: abc1234
- **Status**: In Progress (2/5 phases complete)
- **Resume**: `/implement specs/plans/018.md 3`
```

### 6. Incremental Summary Generation
**Create or update partial summary after each phase:**

**Step 1: Determine Summary Path**
- Extract specs directory from plan metadata
- Summary path: `[specs-dir]/summaries/NNN_partial.md`
- Number matches plan number

**Step 2: Create or Update Partial Summary**
- If first phase: Use Write tool to create new partial summary
- If subsequent phase: Use Edit tool to update existing partial summary
- Include:
  - Status: "in_progress"
  - Phases completed: "M/N"
  - Last completed phase name and date
  - Last git commit hash
  - Resume instructions

**Partial Summary Template:**
```markdown
# Implementation Summary: [Feature Name] (PARTIAL)

## Metadata
- **Date Started**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Status**: in_progress
- **Phases Completed**: M/N

## Progress

### Last Completed Phase
- **Phase**: Phase M: [Phase Name]
- **Completed**: [YYYY-MM-DD]
- **Commit**: [hash]

### Phases Summary
- [x] Phase 1: [Name] - Completed [date]
- [x] Phase 2: [Name] - Completed [date]
- [ ] Phase 3: [Name] - Pending
- [ ] Phase 4: [Name] - Pending

## Resume Instructions
To continue this implementation:
```
/implement [plan-path] M+1
```

Or use auto-resume:
```
/resume-implement
```

## Implementation Notes
[Brief notes about progress, challenges, or decisions made]
```

### 7. Before Starting Next Phase
**Defensive check before proceeding:**

**Step 1: Read Current Plan State**
- Use Read tool to read plan file
- Find previous phase heading

**Step 2: Verify Previous Phase Complete**
- Check that previous phase has `[COMPLETED]` marker
- Check that previous phase tasks are `[x]`

**Step 3: Mark Complete if Missing (Defensive)**
- If previous phase not marked but commit exists: Mark it now
- Log warning about inconsistency
- This ensures plan stays consistent even if previous update failed

## Test Detection Patterns

I'll look for and run:
- Commands containing `:lua.*test`
- Commands with `:Test`
- Standard test commands: `npm test`, `pytest`, `make test`
- Project-specific test commands based on configuration files

## Resuming Implementation

If we need to stop and resume later, you can use:
```
/implement <plan-file> <phase-number>
```

This will start from the specified phase number.

## Error Handling and Rollback

### Test Failures
If tests fail or issues arise:
1. I'll show the error details
2. We'll fix the issues together
3. Re-run tests before proceeding
4. Only move forward when tests pass

### Phase Failure Handling
**What happens when a phase fails:**

**Don't Mark Phase Complete:**
- If phase tests fail: Do NOT mark tasks as `[x]`
- Do NOT add `[COMPLETED]` marker to phase heading
- Do NOT update partial summary with this phase
- Do NOT create git commit

**Preserve Partial Work:**
- Keep code changes in working directory
- Previous phases remain marked complete
- Partial summary reflects only successful phases
- User can debug, fix, and retry the phase

**Retry Failed Phase:**
```
# After fixing issues
/implement <plan-file> <failed-phase-number>
```

**Partial Summary Always Accurate:**
- Partial summary only includes successfully completed phases
- "Phases Completed: M/N" reflects actual progress
- Resume instructions point to first incomplete phase
- Status remains "in_progress" until all phases complete

### Git Commit Failure Handling
If git commit fails after marking phase complete:
- Log error with details
- Preserve partial work (don't rollback code changes)
- Partial summary already reflects completed phase
- Manual intervention required to resolve git issues

## Summary Generation

After completing all phases, I'll:

### 1. Extract Specs Directory from Plan
- Read the plan file
- Extract "Specs Directory" from plan metadata
- This is where the summary will be created (same directory as plan)

### 2. Create Summary Directory
- Location: `[specs-dir]/summaries/` (from plan metadata)
- Create if it doesn't exist

### 3. Finalize Summary File
**Convert partial summary to final summary:**

**Step 1: Check for Partial Summary**
- Look for `[specs-dir]/summaries/NNN_partial.md`
- If exists: This is a resumed or interrupted implementation

**Step 2: Finalize Partial Summary**
- Use Bash tool to rename: `NNN_partial.md` → `NNN_implementation_summary.md`
- Use Edit tool to update the summary:
  - Change title: Remove "(PARTIAL)"
  - Update status: `in_progress` → `complete`
  - Update "Phases Completed": `M/N` → `N/N`
  - Add completion date
  - Remove "Resume Instructions" section
  - Add final "Lessons Learned" section

**Step 3: Or Create New Summary (if no partial)**
- If no partial summary exists: Use Write tool to create new summary
- Format: `NNN_implementation_summary.md`
- Number matches the plan number
- Location: `[specs-dir]/summaries/NNN_implementation_summary.md`
- Contains:
  - Implementation overview
  - Plan executed with link
  - Reports referenced (if any)
  - Key changes made
  - Test results
  - Lessons learned

### 4. Update SPECS.md Registry
- Increment "Summaries" count for this project
- Update "Last Updated" date
- Use Edit tool to update SPECS.md

### 5. Create Bidirectional Cross-References
**Add backward links from plan and reports to summary:**

**Step 1: Update Implementation Plan**
- Use Edit tool to append "## Implementation Summary" section to plan file:
  ```markdown
  ## Implementation Summary
  - **Status**: Complete
  - **Date**: [YYYY-MM-DD]
  - **Summary**: [link to specs/summaries/NNN_implementation_summary.md]
  ```
- Place at end of plan file

**Step 2: Update Research Reports (if any)**
- Extract research report paths from plan metadata
- For each report:
  - Use Edit tool to append "## Implementation Status" section:
    ```markdown
    ## Implementation Status
    - **Status**: Implemented
    - **Date**: [YYYY-MM-DD]
    - **Plan**: [link to specs/plans/NNN.md]
    - **Summary**: [link to specs/summaries/NNN_implementation_summary.md]
    ```
  - Place at end of report file

**Step 3: Verify Bidirectional Links**
- Use Read tool to verify each file was updated
- Check that plan has "Implementation Summary" section
- Check that each report (if any) has "Implementation Status" section
- If verification fails: Log warning but continue (don't block)

**Edge Cases:**
- If plan/report file not writable: Log warning, continue
- If file already has implementation section: Update existing with Edit tool, don't duplicate
- If no research reports: Skip Step 2

### Summary Format
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
- **Specs Directory**: [path/to/specs/]
- **Summary Number**: [NNN]
- **Plan**: [Link to plan file]
- **Research Reports**: [Links to reports used]
- **Phases Completed**: [N/N]

## Implementation Overview
[Brief description of what was implemented]

## Key Changes
- [Major change 1]
- [Major change 2]

## Test Results
[Summary of test outcomes]

## Report Integration
[How research informed implementation]

## Lessons Learned
[Insights from implementation]
```

## Finding the Implementation Plan

### Auto-Detection Logic (when no arguments provided):
```bash
# 1. Find all plan files, sorted by modification time
find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null

# 2. For each plan, check for incomplete markers:
# - Look for unchecked tasks: "- [ ]"
# - Look for phases without [COMPLETED] marker
# - Skip plans marked with "IMPLEMENTATION COMPLETE"

# 3. Select the first incomplete plan
```

### If no plan file provided:
I'll search for the most recent incomplete implementation plan by:
1. Looking in all `specs/plans/` directories
2. Sorting by modification time (most recent first)
3. Checking each plan for:
   - Unchecked tasks `- [ ]`
   - Phases without `[COMPLETED]` marker
   - Absence of `IMPLEMENTATION COMPLETE` header
4. Selecting the first incomplete plan found
5. Determining the first incomplete phase to resume from

### If a plan file is provided:
I'll use the specified plan file directly and:
1. Check its completion status
2. Find the first incomplete phase (if any)
3. Resume from that phase or start from phase 1

### Plan Status Detection Patterns:
- **Complete Plan**: Contains `## ✅ IMPLEMENTATION COMPLETE` or all phases marked `[COMPLETED]`
- **Incomplete Phase**: Phase heading without `[COMPLETED]` marker
- **Incomplete Task**: Checklist item with `- [ ]` instead of `- [x]`

## Integration with Other Commands

### Standards Flow
This command is part of the standards enforcement pipeline:

1. `/report` - Researches topic (no standards needed)
2. `/plan` - Discovers and captures standards in plan metadata
3. `/implement` - **Applies standards during code generation** (← YOU ARE HERE)
4. `/test` - Verifies implementation using standards-defined test commands
5. `/document` - Creates documentation following standards format
6. `/refactor` - Validates code against standards

### How /implement Uses Standards

#### From /plan
- Reads captured standards file path from plan metadata
- Uses plan's documented test commands and coding style

#### Applied During Implementation
- **Code generation**: Follows Code Standards (indentation, naming, error handling)
- **Test execution**: Uses Testing Protocols (test commands, patterns)
- **Documentation**: Creates docs per Documentation Policy

#### Verified Before Commit
- Standards compliance checked before marking phase complete
- Commit message notes which standards were applied

### Example Flow
```
User runs: /plan "Add authentication"
  ↓
/plan discovers CLAUDE.md:
  - Code Standards: snake_case, 2 spaces, pcall
  - Testing: :TestSuite
  ↓
Plan metadata captures: Standards File: CLAUDE.md
  ↓
User runs: /implement auth_plan.md
  ↓
/implement discovers CLAUDE.md + reads plan:
  - Confirms standards
  - Applies during generation
  - Tests with :TestSuite
  - Verifies compliance
  ↓
Generated code follows standards automatically
```

## Agent Usage

This command does not directly invoke specialized agents. Instead, it executes implementation directly using its own tools (Read, Edit, Write, Bash, TodoWrite).

### Potential Agent Integration (Future Enhancement)
While `/implement` currently works autonomously, it could potentially delegate to specialized agents:

- **code-writer**: For complex code generation tasks
  - Would receive plan context and phase requirements
  - Could apply standards more intelligently
  - Would use TodoWrite for task tracking

- **test-specialist**: For test execution and analysis
  - Could provide more detailed test failure diagnostics
  - Would categorize errors more effectively
  - Could suggest fixes for common test failures

- **code-reviewer**: For standards compliance checking
  - Optional pre-commit validation
  - Could run after each phase before marking complete
  - Would provide structured feedback on standards violations

### Current Design Rationale
`/implement` executes directly without agent delegation because:
1. **Performance**: Avoids agent invocation overhead for simple implementations
2. **Context**: Maintains full implementation context across all phases
3. **Control**: Direct execution provides more predictable behavior
4. **Simplicity**: Easier to debug and reason about

For complex, multi-phase implementations requiring specialized expertise, use `/orchestrate` instead, which fully leverages the agent system.

## Checkpoint Detection and Resume

Before starting implementation, I'll check for existing checkpoints that might indicate an interrupted implementation.

### Step 1: Check for Existing Checkpoint

```bash
# Load most recent implement checkpoint
CHECKPOINT=$(.claude/utils/load-checkpoint.sh implement 2>/dev/null || echo "")
```

### Step 2: Interactive Resume Prompt (if checkpoint found)

If a checkpoint exists for this plan, I'll present interactive options:

```
Found existing checkpoint for implementation
Plan: [plan_path]
Created: [created_at] ([age] ago)
Progress: Phase [current_phase] of [total_phases] completed
Last test status: [tests_passing]

Options:
  (r)esume - Continue from Phase [current_phase + 1]
  (s)tart fresh - Delete checkpoint and restart from beginning
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

### Step 3: Resume Implementation State (if user chooses resume)

If user selects resume:
1. Load plan_path from checkpoint
2. Restore current_phase, completed_phases
3. Skip to next incomplete phase
4. Continue implementation from that point

### Step 4: Save Checkpoints After Each Phase

After each phase completes successfully (after git commit):

```bash
# Build checkpoint state
STATE_JSON=$(cat <<EOF
{
  "workflow_description": "Implement [plan-name]",
  "plan_path": "$PLAN_PATH",
  "current_phase": $CURRENT_PHASE,
  "total_phases": $TOTAL_PHASES,
  "completed_phases": [$COMPLETED_PHASES_ARRAY],
  "status": "in_progress",
  "tests_passing": true
}
EOF
)

# Save checkpoint
PROJECT_NAME=$(basename "$PLAN_PATH" .md | sed 's/^[0-9]*_//')
.claude/utils/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON"
```

### Step 5: Cleanup on Completion

On successful implementation completion:
```bash
# Delete checkpoint file
rm .claude/checkpoints/implement_${PROJECT_NAME}_*.json
```

On implementation failure:
```bash
# Update checkpoint with error info, archive to failed/
STATE_JSON=$(cat <<EOF
{
  "status": "failed",
  "last_error": "$ERROR_MESSAGE",
  "failed_phase": $CURRENT_PHASE
}
EOF
)
.claude/utils/save-checkpoint.sh implement "$PROJECT_NAME" "$STATE_JSON"
mv .claude/checkpoints/implement_${PROJECT_NAME}_*.json .claude/checkpoints/failed/
```

Let me start by finding your implementation plan.

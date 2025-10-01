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

### 4. Plan Update
- Mark completed tasks with `[x]` instead of `[ ]`
- Add `[COMPLETED]` marker to the phase heading
- Save the updated plan file

### 5. Git Commit
Create a structured commit:
```
feat: implement Phase N - Phase Name

Automated implementation of phase N from implementation plan
All tests passed successfully

Co-Authored-By: Claude <noreply@anthropic.com>
```

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

## Error Handling

If tests fail or issues arise:
1. I'll show the error details
2. We'll fix the issues together
3. Re-run tests before proceeding
4. Only move forward when tests pass

## Summary Generation

After completing all phases, I'll:

### 1. Create Summary Directory
- Location: Same directory as the plan, in `specs/summaries/`
- Create if it doesn't exist

### 2. Generate Summary File
- Format: `NNN_implementation_summary.md`
- Number matches the plan number
- Contains:
  - Implementation overview
  - Plan executed with link
  - Reports referenced (if any)
  - Key changes made
  - Test results
  - Lessons learned

### 3. Update Reports (if referenced)
If the plan referenced research reports:
- Add implementation notes to each report
- Cross-reference the summary
- Note which recommendations were implemented

### Summary Format
```markdown
# Implementation Summary: [Feature Name]

## Metadata
- **Date Completed**: [YYYY-MM-DD]
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

Let me start by finding your implementation plan.

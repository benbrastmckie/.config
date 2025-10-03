---
command-type: primary
dependent-commands: list-reports, report
description: Investigate issues and create diagnostic report without code changes
argument-hint: <issue-description> [report-path1] [report-path2] ...
allowed-tools: Read, Bash, Grep, Glob, WebSearch, WebFetch, TodoWrite, Task
---

# /debug Command

Investigates issues and creates a comprehensive diagnostic report without making any code changes. Focuses on understanding root causes and documenting findings.

## Usage

```
/debug <issue-description> [report-path1] [report-path2] ...
```

### Arguments

- `<issue-description>` (required): Description of the bad behavior or issue to investigate
- `[report-path1] [report-path2] ...` (optional): Related reports or plan paths that might provide context
  - Can be report paths: `specs/reports/001_*.md`
  - Can be plan paths: `specs/plans/002_*.md` (will annotate plan with debug notes)

## Examples

### Basic Debugging
```
/debug "Terminal commands appearing mixed with startup messages"
```

### With Context Reports
```
/debug "Module caching preventing updates" specs/reports/001_architecture.md
```

### Multiple Reports
```
/debug "Performance degradation after refactor" reports/002_perf.md reports/003_profiling.md
```

## Process

### 1. Issue Analysis
- Parse and understand the reported behavior
- Identify affected components and systems
- Review any provided context reports
- Determine investigation scope

### 2. Evidence Gathering
- **Code Inspection**: Examine relevant source files
- **Environment Analysis**: Check configuration and environment variables
- **Log Analysis**: Review error logs and debug output (if available)
- **Dependency Review**: Verify module dependencies and versions
- **State Examination**: Check caches, session data, and persistent state

### 3. Root Cause Investigation
- **Trace Execution Paths**: Follow code flow from symptoms to source
- **Identify Patterns**: Look for common failure modes
- **Test Hypotheses**: Validate potential causes through inspection
- **Check Recent Changes**: Review git history if relevant
- **Environmental Factors**: Consider system-specific issues

### 4. Documentation
- Create numbered report in `specs/reports/` directory
- Include all findings and evidence
- Document potential solutions (but don't implement)
- Provide clear next steps for resolution

## Report Structure

```markdown
# Debug Report: [Issue Title]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Issue**: [Brief description]
- **Severity**: [Critical|High|Medium|Low]
- **Type**: Debugging investigation
- **Related Reports**: [List of reference reports]

## Problem Statement
[Detailed description of the issue and its impact]

## Investigation Process
[Step-by-step investigation methodology]

## Findings

### Root Cause Analysis
[Primary cause identification]

### Contributing Factors
[Secondary issues that compound the problem]

### Evidence
[Code snippets, logs, environment details]

## Proposed Solutions

### Option 1: [Solution Name]
[Description, pros, cons, implementation approach]

### Option 2: [Solution Name]
[Alternative approach if applicable]

## Recommendations
[Prioritized list of actions to resolve the issue]

## Next Steps
[Clear action items for implementation]

## References
[Links to relevant files, documentation, external resources]
```

## Investigation Techniques

### Code Analysis
- Search for error messages and their sources
- Trace function calls and data flow
- Identify state mutations and side effects
- Review error handling and edge cases

### Pattern Detection
- Look for similar issues in codebase
- Check for known anti-patterns
- Identify missing validation or guards
- Review synchronization and timing issues

### Environmental Checks
- Verify configuration files
- Check environment variables
- Review system dependencies
- Validate file permissions

### Cache and State
- Identify caching mechanisms
- Check for stale data
- Review session persistence
- Examine module loading

## Output

Creates a debug report at:
```
specs/reports/NNN_debug_[issue_name].md
```

Where NNN is the next sequential number.

## Best Practices

### DO
- **Be Systematic**: Follow a methodical investigation process
- **Document Everything**: Record all findings, even dead ends
- **Preserve Evidence**: Include relevant code snippets and logs
- **Consider Context**: Review related reports for background
- **Think Broadly**: Consider environmental and timing issues
- **Propose Multiple Solutions**: Offer alternatives when possible

### DON'T
- **Don't Modify Code**: This is investigation only
- **Don't Assume**: Validate hypotheses with evidence
- **Don't Skip Steps**: Thorough investigation prevents recurrence
- **Don't Ignore Warnings**: Small issues can indicate larger problems

## Integration with Other Commands

### Before Debugging
- Use `/list-reports` to find related documentation
- Check existing debug reports for similar issues

### After Debugging
- Use `/plan` to create implementation plan from findings
- Use `/implement` to execute the solution
- Consider `/test` to verify the fix

## Plan Annotation

**When a plan path is provided as an argument:**

After creating the debug report, automatically annotate the plan with debugging history.

### Step 1: Identify Plan and Failed Phase
- Check if any argument is a plan path (`specs/plans/*.md`)
- If yes: Determine which phase failed (from issue description or plan analysis)
- Extract phase number from user's description or by analyzing plan

### Step 2: Extract Root Cause
- From the debug report just created
- Summarize root cause in one line
- Extract debug report path

### Step 3: Annotate Plan with Debugging Notes
- Use Edit tool to add "#### Debugging Notes" subsection after the failed phase
- Format:
  ```markdown
  #### Debugging Notes
  - **Date**: [YYYY-MM-DD]
  - **Issue**: [Brief description from issue-description argument]
  - **Debug Report**: [link to specs/reports/NNN_debug_*.md]
  - **Root Cause**: [One-line summary from debug report]
  - **Resolution**: Pending
  ```

### Step 4: Handle Multiple Debugging Iterations
- Before adding notes: Check if phase already has "#### Debugging Notes"
- If exists: Append new iteration using Edit tool
  ```markdown
  **Iteration 2** (2025-10-03)
  - **Issue**: [New issue description]
  - **Debug Report**: [link to new debug report]
  - **Root Cause**: [New root cause]
  - **Resolution**: Pending
  ```
- If 3+ iterations: Add note `**Status**: Escalated to manual intervention`

### Step 5: Update Resolution When Fixed
**Note for `/implement` command:**
- After a phase with debugging notes passes tests
- Check for "Resolution: Pending" in debugging notes
- Update to "Resolution: Applied"
- Add git commit hash: `Fix Applied In: [commit-hash]`

### Example Annotation

```markdown
### Phase 3: Core Implementation

Tasks:
- [x] Implement main feature
- [x] Add error handling
- [x] Write tests

#### Debugging Notes
- **Date**: 2025-10-03
- **Issue**: Phase 3 tests failing with null pointer exception
- **Debug Report**: [../reports/026_debug_phase3.md](../reports/026_debug_phase3.md)
- **Root Cause**: Missing null check in error handler
- **Resolution**: Applied
- **Fix Applied In**: abc1234
```

## Common Investigation Areas

### Performance Issues
- Profiling bottlenecks
- Memory leaks
- Inefficient algorithms
- Database query optimization

### Integration Problems
- API compatibility
- Module conflicts
- Version mismatches
- Configuration errors

### State Management
- Race conditions
- Cache invalidation
- Session corruption
- Data synchronization

### User Experience
- Unexpected behavior
- Error message clarity
- Workflow disruptions
- Feature failures

## Agent Usage

This command delegates investigation work to the `debug-specialist` agent:

### debug-specialist Agent
- **Purpose**: Root cause analysis and diagnostic reporting
- **Tools**: Read, Bash, Grep, Glob, WebSearch
- **Invocation**: Single agent for each debug request
- **Read-Only**: Never modifies code, only investigates and reports

### Invocation Pattern
```yaml
Task {
  subagent_type: "debug-specialist"
  description: "Investigate [issue description]"
  prompt: "
    Debug Task: Investigate [issue]

    Context:
    - Issue: [user's description]
    - Related Reports: [paths if provided]
    - Project Standards: CLAUDE.md

    Investigation:
    1. Gather evidence (logs, code, configs)
    2. Identify root cause
    3. Analyze contributing factors
    4. Propose multiple solutions with tradeoffs

    Output:
    - Debug report at specs/reports/NNN_debug_[issue].md
    - Summary with root cause and recommended fix
  "
}
```

### Agent Benefits
- **Specialized Investigation**: Focused on evidence gathering and analysis
- **Structured Reporting**: Consistent debug report format
- **Multiple Solutions**: Always proposes alternatives with tradeoffs
- **Non-Invasive**: Read-only access ensures no unintended modifications
- **Reusable Diagnostics**: Reports serve as documentation for future issues

### Workflow Integration
1. User invokes `/debug` with issue description
2. Command delegates to `debug-specialist` agent
3. Agent investigates systematically and creates report
4. Command returns report path and summary
5. User can use report with `/plan` to create fix implementation

## Notes

- Debug reports are permanent documentation of issues and investigations
- Reports help prevent similar issues in the future
- Clear documentation speeds up resolution when issues recur
- Investigation without implementation allows for careful planning
- The `debug-specialist` agent ensures thorough, structured investigations
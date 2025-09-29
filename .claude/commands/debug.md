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
- `[report-path1] [report-path2] ...` (optional): Related reports that might provide context

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

## Notes

- Debug reports are permanent documentation of issues and investigations
- Reports help prevent similar issues in the future
- Clear documentation speeds up resolution when issues recur
- Investigation without implementation allows for careful planning
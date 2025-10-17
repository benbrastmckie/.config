# Debug Report Template

This template defines the standard structure for debug reports created by the `/debug` command.

## File Location

Debug reports are created in the topic-based directory structure:
```
specs/{NNN_topic}/debug/NNN_debug_issue_name.md
```

Where:
- `{NNN_topic}`: Three-digit numbered topic directory (e.g., `042_authentication`)
- `NNN`: Next sequential number within the topic's `debug/` subdirectory
- `issue_name`: Snake_case conversion of the issue description

**IMPORTANT**: Debug reports are **committed to git** (unlike other artifact types which are gitignored). This ensures debugging history is preserved in the repository for issue tracking.

## Standard Debug Report Structure

```markdown
# Debug Report: [Issue Title]

## Metadata
- **Date**: [YYYY-MM-DD]
- **Issue**: [Brief description]
- **Severity**: [Critical|High|Medium|Low]
- **Type**: Debugging investigation
- **Topic Directory**: [specs/{NNN_topic}/]
- **Related Plan**: [../plans/NNN_plan.md] (if applicable)
- **Related Reports**: [List of reference reports if provided]

## Problem Statement

### Reported Behavior
[Detailed description of the issue as reported by the user]

### Expected Behavior
[What should happen instead]

### Impact
[How this issue affects users or the system]

### Environment
[Relevant environment details: OS, versions, configuration]

## Investigation Process

### Initial Analysis
[First steps taken to understand the issue]

### Evidence Gathering
[Methods used to collect information]

### Hypotheses Tested
1. **Hypothesis 1**: [Description]
   - Test: [How it was tested]
   - Result: [Confirmed/Rejected]

2. **Hypothesis 2**: [Description]
   - Test: [How it was tested]
   - Result: [Confirmed/Rejected]

### Diagnostic Tools Used
- [Tool/method 1]
- [Tool/method 2]

## Findings

### Root Cause Analysis

**Primary Cause**: [Main issue identified]

**Explanation**: [Detailed explanation of why this causes the problem]

**Location**: [Specific file(s) and line numbers]

```language
[Relevant code snippet showing the problem]
```

### Contributing Factors

**Factor 1**: [Secondary issue]
- Impact: [How it contributes]
- Location: [File:line]

**Factor 2**: [Secondary issue]
- Impact: [How it contributes]
- Location: [File:line]

### Evidence

#### Code Evidence
```language
# File: path/to/file.ext:line
[Code snippet with problem highlighted]
```

#### Log Evidence
```
[Relevant log output showing the error]
```

#### State Evidence
[Description of state/cache/configuration issues found]

### Timeline
[If relevant, chronological sequence of events leading to the issue]

## Proposed Solutions

### Option 1: [Solution Name]

**Approach**: [High-level description of the solution]

**Implementation Steps**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Pros**:
- [Advantage 1]
- [Advantage 2]

**Cons**:
- [Disadvantage 1]
- [Disadvantage 2]

**Effort**: [Quick Win|Small|Medium|Large]

**Risk**: [Safe|Low|Medium|High]

**Code Changes**: [Brief description of what needs to change]

### Option 2: [Alternative Solution Name]

[Same structure as Option 1]

### Recommended Solution
[Which option and why]

## Recommendations

### Immediate Actions (Priority: High)
1. [Action 1 with rationale]
2. [Action 2 with rationale]

### Follow-up Actions (Priority: Medium)
1. [Action 1 with rationale]

### Preventive Measures
1. [How to prevent similar issues in the future]

## Testing Strategy

### Validation Tests
[How to verify the fix works]

### Regression Tests
[How to ensure the fix doesn't break other functionality]

### Test Cases to Add
1. [Test case 1 description]
2. [Test case 2 description]

## Next Steps

### Implementation Plan
1. [ ] [Specific task 1]
2. [ ] [Specific task 2]
3. [ ] [Specific task 3]

### Assignee
[Who should implement the fix, if known]

### Related Issues
[Links to similar issues or related problems]

## Resolution Status
- **Status**: Investigated | Fix Planned | Fix Applied | Verified
- **Fix Applied In**: [commit-hash] (when fixed)
- **Resolution Date**: [YYYY-MM-DD] (when fixed)

*This section will be updated when the issue is resolved.*

## References

### Affected Files
- [file1.ext:line](relative/path/to/file1.ext) - [Brief description of relevance]
- [file2.ext:line](relative/path/to/file2.ext) - [Brief description of relevance]

### Related Artifacts
- Plan: [../plans/NNN_plan.md](../plans/NNN_plan.md) (if applicable)
- Reports: [../reports/NNN_report.md](../reports/NNN_report.md) (if provided as context)

### External Resources
- [Resource title](https://url) - [Brief description]
```

## Section Guidelines

### Problem Statement
- Clear description of reported behavior
- What was expected vs what happened
- Quantifiable impact when possible
- Environment details that might be relevant

### Investigation Process
- Document the methodology used
- Show what was checked and how
- Include hypotheses that were rejected (helps future debugging)
- List diagnostic tools and techniques

### Findings
- **Root Cause**: Must be specific and actionable
- **Code Location**: Exact file and line numbers
- **Evidence**: Code snippets, logs, state information
- **Contributing Factors**: Don't ignore secondary issues

### Proposed Solutions
- Always provide at least 2 options when possible
- Be realistic about pros, cons, effort, and risk
- Include specific implementation steps
- Recommend one option with clear rationale

### Recommendations
- Prioritized action items
- Include preventive measures
- Consider both immediate and long-term fixes
- Be specific and actionable

### Testing Strategy
- How to verify the fix
- How to prevent regressions
- New test cases to add
- Existing tests that might need updates

## Best Practices

### Investigation Techniques

#### Code Analysis
- Grep for error messages to find sources
- Trace function calls and data flow
- Identify state mutations and side effects
- Review error handling and edge cases

#### Pattern Detection
- Search for similar issues in codebase
- Check for known anti-patterns
- Identify missing validation or guards
- Look for race conditions or timing issues

#### Environmental Checks
- Verify configuration files
- Check environment variables
- Review system dependencies
- Validate file permissions

#### Cache and State
- Identify caching mechanisms
- Check for stale data
- Review session persistence
- Examine module loading

### Documentation Style
- Be objective and factual
- Include both successful and failed investigations
- Use code examples to illustrate issues
- Provide enough context for others to understand
- No blame or subjective opinions

### Code Examples
- Show problematic code with context
- Highlight the specific issue
- Include file paths and line numbers
- Keep examples focused and minimal
- Show before/after for proposed fixes

### Evidence Collection
- Logs: Include relevant portions with timestamps
- Code: Show the problematic code and call sites
- State: Describe configuration or cache issues
- Timeline: Show sequence of events if relevant

## Severity Levels

### Critical
- System down or unusable
- Data loss or corruption
- Security vulnerability
- Affects all users

### High
- Major feature broken
- Significant performance degradation
- Affects many users
- Workaround exists but difficult

### Medium
- Minor feature broken
- Moderate performance issue
- Affects some users
- Easy workaround available

### Low
- Cosmetic issue
- Minimal impact
- Affects few users
- No urgency to fix

## Cross-Referencing

### Plan Annotation
When a plan path is provided as context, the debug report should be linked to the specific phase that failed.

The spec-updater agent will add a "Debugging Notes" subsection to the phase:

```markdown
#### Debugging Notes
- **Date**: [YYYY-MM-DD]
- **Issue**: [Brief description]
- **Debug Report**: [../debug/NNN_debug_issue.md](../debug/NNN_debug_issue.md)
- **Root Cause**: [One-line summary]
- **Resolution**: Pending | Applied
- **Fix Applied In**: [commit-hash] (when resolved)
```

### Multiple Debugging Iterations
If a phase is debugged multiple times, append new iterations:

```markdown
#### Debugging Notes

**Iteration 1** (2025-10-03)
- **Issue**: Null pointer exception
- **Debug Report**: [../debug/001_null_pointer.md](../debug/001_null_pointer.md)
- **Root Cause**: Missing null check
- **Resolution**: Applied
- **Fix Applied In**: abc1234

**Iteration 2** (2025-10-05)
- **Issue**: Performance regression after fix
- **Debug Report**: [../debug/002_performance.md](../debug/002_performance.md)
- **Root Cause**: Inefficient validation loop
- **Resolution**: Applied
- **Fix Applied In**: def5678
```

### Within Topic
Use relative paths for artifacts in the same topic:
- Plans: `../plans/NNN_plan.md`
- Reports: `../reports/NNN_report.md`
- Other debug reports: `./NNN_other_debug.md` or `NNN_other_debug.md`
- Summaries: `../summaries/NNN_summary.md`

## Integration with Commands

### /debug Command
Creates debug reports using this structure automatically.

### /plan Command
Can reference debug reports in plan metadata or phase notes.

### /implement Command
Should update Resolution Status when fixes are applied:
- Change status from "Investigated" to "Fix Applied"
- Add commit hash
- Add resolution date

### spec-updater Agent
- Creates bidirectional links between debug reports and plans
- Annotates plans with debugging notes
- Verifies debug/ subdirectory is committed to git (not gitignored)

## Git Tracking

**Critical**: Debug reports must be committed to git for issue tracking.

### Verification
The spec-updater agent should verify:
```bash
# Check if debug/ is tracked by git
git ls-files specs/{topic}/debug/ | grep -q . && echo "✓ Tracked" || echo "✗ Not tracked"

# Check gitignore doesn't exclude debug/
! git check-ignore specs/{topic}/debug/ && echo "✓ Not ignored" || echo "✗ Ignored"
```

### Gitignore Configuration
The `.gitignore` should include:
```
# Topic artifact structure
specs/*/reports/
specs/*/plans/
specs/*/summaries/
specs/*/scripts/
specs/*/outputs/
specs/*/artifacts/
specs/*/backups/

# Debug reports are NOT ignored (committed for issue tracking)
# specs/*/debug/  ← This line should NOT be present
```

## Output Pattern

When debug report is complete, use minimal output pattern:

```
✓ Debug Report Complete
Artifact: /absolute/path/to/specs/{topic}/debug/NNN_debug_issue.md
Summary: [1 line root cause summary]
```

If linked to plan:
```
✓ Debug Report Complete
Artifact: /absolute/path/to/specs/{topic}/debug/NNN_debug_issue.md
Plan Updated: /absolute/path/to/specs/{topic}/plans/NNN_plan.md (Phase N annotated)
Summary: [1 line root cause summary]
```

See `.claude/templates/output-patterns.md` for complete output standards.

## Notes

- Debug reports are **committed to git** (exception to normal artifact gitignore rules)
- Each debug iteration gets its own numbered report
- Plan annotation tracks debugging history
- Resolution status updated when fix is applied
- Cross-references maintained by spec-updater agent
- Severity and risk assessments guide prioritization

# Debug Analyst Agent

## Role
Investigate potential root cause for test failure or bug

## Purpose
Perform focused root cause analysis for a specific hypothesis, enabling parallel investigation of multiple potential causes.

## Invocation Context

You will be provided:
- **Issue description**: {issue_desc}
- **Failed tests**: {test_output}
- **Modified files**: {file_list}
- **Hypothesis**: {potential_cause}

## Responsibilities

1. **Reproduce the issue**
   - Run the failing tests
   - Analyze error messages and stack traces
   - Verify the issue occurs consistently

2. **Identify root cause**
   - Investigate the hypothesis provided
   - Check for logic errors, missing dependencies, config issues
   - Trace code execution to find the failure point

3. **Assess impact**
   - Determine scope of the problem
   - Identify affected components
   - Check for related issues

4. **Propose fix**
   - Suggest specific code changes
   - Provide rationale for the fix
   - Estimate fix complexity

## Investigation Process

### 1. Test Reproduction
```bash
# Run the failing test
bash -c "{test_command}"

# Capture full output
{test_command} 2>&1 | tee test_output.log
```

### 2. Error Analysis
```bash
# Read error logs
read {log_file}

# Search for error patterns
grep "ERROR\|FAIL\|Exception" {log_file}
```

### 3. Code Investigation
```bash
# Read relevant files
read {modified_file}

# Search for the suspected issue
grep "{hypothesis_pattern}" {modified_file}

# Check related code
glob "**/*{related_pattern}*"
```

### 4. Dependency Check
```bash
# Check imports
grep "^import\|^require\|^source" {file}

# Verify dependencies exist
test -f {dependency_path} && echo "Found" || echo "Missing"
```

## Output Format

Create artifact file at: `specs/{topic}/debug/NNN_investigation.md`

### Artifact Structure
```markdown
# Debug Investigation: {issue_desc}

## Metadata
- **Date**: {date}
- **Issue**: {issue_desc}
- **Hypothesis**: {potential_cause}
- **Investigation Status**: {status}

## Issue Reproduction

### Test Output
```
{test_output}
```

### Reproduction Steps
1. {step_1}
2. {step_2}
3. {step_3}

### Reproduction Result
- [x] Issue reproduced
- [ ] Issue not reproduced
- [ ] Intermittent

## Root Cause Analysis

### Hypothesis Validation
{hypothesis}: **{CONFIRMED|REJECTED}**

### Evidence
1. {evidence_1}
2. {evidence_2}
3. {evidence_3}

### Root Cause
{detailed_explanation_of_root_cause}

## Impact Assessment

### Scope
- Affected files: {file_list}
- Affected components: {component_list}
- Severity: {Low|Medium|High|Critical}

### Related Issues
- {related_issue_1}
- {related_issue_2}

## Proposed Fix

### Fix Description
{clear_description_of_proposed_fix}

### Code Changes
```{language}
// File: {file_path}
// Lines: {line_range}

{proposed_code_changes}
```

### Fix Rationale
{explanation_of_why_this_fixes_the_issue}

### Fix Complexity
- Estimated time: {hours}
- Risk level: {Low|Medium|High}
- Testing required: {test_approach}

## Recommendations

1. {recommendation_1}
2. {recommendation_2}
3. {recommendation_3}
```

## Return Format

After creating the artifact, return only:

```json
{
  "artifact_path": "specs/{topic}/debug/NNN_investigation.md",
  "metadata": {
    "title": "Debug Investigation: {issue_desc}",
    "summary": "{50-word summary of findings}",
    "root_cause": "{concise_root_cause}",
    "proposed_fix": "{brief_fix_description}",
    "hypothesis_confirmed": true|false
  }
}
```

**DO NOT** include the full investigation details in your response. The parent agent will load it on-demand using the artifact path.

## Context Preservation

- Keep summary to exactly 50 words
- Include only essential findings in metadata
- Parent agent uses `load_metadata_on_demand()` to read full artifact
- This achieves 95%+ context reduction vs. returning full content

## Example Usage

### Invocation by /debug
```bash
# When /debug needs to investigate multiple hypotheses in parallel
hypotheses='[
  {"hypothesis": "Missing import statement", "priority": "high"},
  {"hypothesis": "Incorrect function signature", "priority": "medium"},
  {"hypothesis": "Race condition in async code", "priority": "low"}
]'

# Parent invokes multiple debug-analyst agents in parallel (one per hypothesis)
Task tool (agent 1):
  subagent_type: general-purpose
  description: "Investigate missing import hypothesis"
  prompt: |
    Read and follow: .claude/agents/debug-analyst.md

    Investigation Context:
    - Issue: "Token refresh fails after 1 hour"
    - Failed test: test_token_refresh
    - Modified files: src/auth/token.js, src/auth/session.js
    - Hypothesis: Missing import statement

    Investigate this hypothesis and create artifact at:
    specs/042_auth/debug/001_investigation_missing_import.md

    Return metadata only (50-word summary).

# Similar invocations for agents 2 and 3 with different hypotheses
```

### Response Format
```json
{
  "artifact_path": "specs/042_auth/debug/001_investigation_missing_import.md",
  "metadata": {
    "title": "Debug Investigation: Token Refresh Failure",
    "summary": "Hypothesis CONFIRMED: Missing import of refreshToken() function from lib/token-utils.js in src/auth/token.js line 45. Function call fails silently. Fix: Add import statement. Low complexity, 5-minute fix. Tests verify resolution.",
    "root_cause": "Missing import: refreshToken() from lib/token-utils.js",
    "proposed_fix": "Add: import { refreshToken } from '../lib/token-utils'",
    "hypothesis_confirmed": true
  }
}
```

## Integration with /debug

The `/debug` command uses this agent when:
- Multiple potential root causes exist
- Issue is complex and requires parallel investigation
- User provides specific hypotheses to test
- Previous debugging attempts failed

Workflow:
1. `/debug` identifies 2-4 potential root causes
2. Invokes debug-analyst for each hypothesis in parallel
3. Receives metadata-only responses (artifact paths + 50-word summaries)
4. Synthesizes findings from all agents
5. Identifies confirmed hypothesis
6. Applies the fix from the confirmed investigation
7. Prunes debug artifacts after fix verified

Context savings: ~3000 tokens for complex debugging (90% reduction)

## Parallel Investigation Strategy

When `/debug` invokes multiple debug-analyst agents:

1. **Hypothesis Prioritization**
   - High priority: Most likely causes investigated first
   - Medium priority: Alternative explanations
   - Low priority: Edge cases

2. **Parallel Execution**
   - All agents run simultaneously (single message, multiple Task invocations)
   - Each investigates one hypothesis independently
   - Results synthesized by parent `/debug` command

3. **Result Synthesis**
   - Parent loads metadata from all agents
   - Identifies which hypothesis was confirmed
   - Loads full artifact only for confirmed hypothesis
   - Applies fix from confirmed investigation

4. **Context Efficiency**
   - 3 hypotheses × 50-word summaries = 150 words in context
   - Full investigation loaded on-demand only for confirmed cause
   - Alternative investigations pruned after confirmation
   - Saves ~2500 tokens vs. sequential full investigations

## Debug Artifact Lifecycle

Debug artifacts in `debug/` subdirectories are **COMMITTED to git** for issue tracking:
- Permanent record of debugging process
- Helps with similar issues in future
- Documents known issues and solutions
- Not pruned like other temporary artifacts

This is different from other artifacts (scripts/, outputs/, artifacts/) which are gitignored and temporary.

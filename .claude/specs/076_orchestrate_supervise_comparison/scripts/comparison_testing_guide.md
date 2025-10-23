# Comparison Testing Guide: /orchestrate vs /supervise

## Overview

This guide provides a framework for optional manual comparison testing between `/orchestrate` and `/supervise` workflows. This testing is **not required** for Phase 5 completion but can provide valuable insights for future decision-making.

## Purpose

Compare completion rates, error handling behavior, and user experience between the two commands on identical workflows.

## Test Methodology

### Test Scenarios

Execute the same workflow with both commands and compare results across these dimensions:

1. **Completion Rate**: Did the workflow complete successfully?
2. **Error Handling**: How were errors detected and handled?
3. **User Experience**: Were there interruptions? Was the output clear?
4. **Performance**: How long did the workflow take?
5. **Artifacts Created**: Were the same artifacts produced?

### Recommended Test Workflows

#### Workflow 1: Simple Research and Planning
```bash
# Test with /supervise
/supervise "research OAuth2 authentication patterns and create implementation plan"

# Test with /orchestrate (if available)
/orchestrate "research OAuth2 authentication patterns and create implementation plan"
```

**Expected Outcome**: Both should produce research reports and implementation plan.

**Compare**:
- Time to completion
- Number of research reports created
- Plan quality and detail
- Any errors or retries needed

#### Workflow 2: Research Only
```bash
# Test with /supervise
/supervise "research best practices for API rate limiting"

# Test with /orchestrate (if available)
/orchestrate "research best practices for API rate limiting --research-only"
```

**Expected Outcome**: Both should produce research reports without planning.

**Compare**:
- Report completeness
- Time to completion
- Error handling (if any transient failures occur)

#### Workflow 3: Debug Workflow
```bash
# Test with /supervise
/supervise "debug authentication token expiration issue in auth.js"

# Test with /orchestrate (if available)
/orchestrate "debug authentication token expiration issue in auth.js --debug-only"
```

**Expected Outcome**: Both should produce debug analysis reports.

**Compare**:
- Root cause identification accuracy
- Suggested fixes quality
- Time to analysis

### Comparison Metrics

Create a comparison table for each workflow:

| Metric | /supervise | /orchestrate | Notes |
|--------|-----------|-------------|-------|
| Completion Time | ___ min | ___ min | Which was faster? |
| Artifacts Created | ___ | ___ | Same files? |
| Errors Encountered | ___ | ___ | How handled? |
| Retries Needed | ___ | ___ | Auto-recovery success? |
| User Interruptions | ___ | ___ | Any prompts? |
| Context Usage | ___% | ___% | Resource efficiency |
| Clarity of Output | 1-10 | 1-10 | User experience rating |

## Simulating Transient Failures

To test auto-recovery capabilities, you can simulate transient failures:

### Method 1: Network Interruption
```bash
# Temporarily disable network during workflow execution
# (Advanced - requires network control)
# Start workflow, interrupt network briefly, restore

# Expected: /supervise should auto-retry on timeout
# Expected: /orchestrate may have more sophisticated retry logic
```

### Method 2: File Lock Simulation
```bash
# Create a file lock on expected output location
# (Complex - not recommended for casual testing)
```

### Method 3: Natural Transient Failures
Simply run multiple workflows and note any natural transient failures that occur (rate limits, brief network hiccups, etc.) and observe how each command handles them.

## Results Documentation

### Template for Recording Results

```markdown
# Comparison Test Results

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Environment**: [OS, network conditions, etc.]

## Workflow 1: [Name]

### /supervise Results
- **Status**: Success/Failure
- **Time**: X minutes
- **Artifacts**: List of files created
- **Errors**: Any errors encountered
- **Recovery**: Auto-recovery triggered? Y/N
- **Notes**: Additional observations

### /orchestrate Results
- **Status**: Success/Failure
- **Time**: X minutes
- **Artifacts**: List of files created
- **Errors**: Any errors encountered
- **Recovery**: Auto-recovery triggered? Y/N
- **Notes**: Additional observations

### Comparison Summary
- **Winner**: /supervise | /orchestrate | Tie
- **Reason**: Brief explanation
- **Recommendation**: Which to use for this workflow type?

## Workflow 2: [Name]
[Repeat above structure]

## Overall Findings

### Strengths of /supervise
1. [Strength 1]
2. [Strength 2]
3. [Strength 3]

### Strengths of /orchestrate
1. [Strength 1]
2. [Strength 2]
3. [Strength 3]

### Recommendations
- Use /supervise for: [scenario types]
- Use /orchestrate for: [scenario types]
- Future considerations: [deprecation decisions, consolidation ideas]
```

## Optional: Automated Comparison

For more rigorous testing, you could create an automated comparison script:

```bash
#!/usr/bin/env bash
# compare_commands.sh - Automated workflow comparison

WORKFLOW="research JWT authentication and create plan"

echo "Testing /supervise..."
time /supervise "$WORKFLOW" > /tmp/supervise_output.txt 2>&1
SUPERVISE_EXIT=$?

echo "Testing /orchestrate..."
time /orchestrate "$WORKFLOW" > /tmp/orchestrate_output.txt 2>&1
ORCHESTRATE_EXIT=$?

echo "=== Comparison Results ==="
echo "/supervise exit code: $SUPERVISE_EXIT"
echo "/orchestrate exit code: $ORCHESTRATE_EXIT"

# Compare artifacts created
echo "Artifacts comparison:"
diff <(ls .claude/specs/*/reports/ | sort) <(ls .claude/specs/*/reports/ | sort) || echo "Different artifacts"

# Compare output lengths
echo "/supervise output: $(wc -l < /tmp/supervise_output.txt) lines"
echo "/orchestrate output: $(wc -l < /tmp/orchestrate_output.txt) lines"
```

## Important Notes

### This Testing is Optional

**Phase 5 completion does NOT require comparison testing.** This guide is provided for optional future evaluation.

**Phase 5 completion criteria:**
- Documentation complete ✓
- Test script created ✓
- /supervise meets production-ready standards ✓
- Performance overhead <5% ✓

### Deprecation Decisions are Separate

Any decisions about `/orchestrate` deprecation are **completely separate** from this implementation plan. They should be based on:

1. Extended production usage of both commands
2. User feedback and preferences
3. Maintenance burden analysis
4. Feature parity evaluation
5. Community input

**Do not make deprecation decisions based solely on this comparison testing.**

## When to Run Comparison Testing

Consider running comparison tests when:

1. **Evaluating which command to use** for a new project or workflow type
2. **Gathering data for future deprecation discussions** (months from now)
3. **Documenting user experience differences** for documentation updates
4. **Validating auto-recovery improvements** have brought /supervise up to production standards
5. **Training new users** on which command to use for different scenarios

## Conclusion

This comparison testing framework allows for optional evaluation of `/orchestrate` vs `/supervise` but is **not required** for Phase 5 completion. The primary goal of Phase 5 is to document the auto-recovery features added to `/supervise`, ensure testing coverage, and confirm production-readiness - all of which have been achieved.

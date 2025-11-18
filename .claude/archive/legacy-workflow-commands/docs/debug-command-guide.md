# /debug Command - Complete Guide

**Executable**: `.claude/commands/debug.md`

**Quick Start**: Run `/debug "<issue description>" [report-path1]` - investigates issues and creates diagnostic reports without making code changes.

---

## Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Investigation Techniques](#investigation-techniques)
4. [Parallel Hypothesis Testing](#parallel-hypothesis-testing)
5. [Report Structure](#report-structure)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The `/debug` command investigates issues systematically, creating diagnostic reports that document root causes, proposed solutions, and prevention recommendations - all without modifying code.

### Key Capabilities

- **Root cause analysis**: Systematic investigation to identify underlying issues
- **Parallel hypothesis testing**: Investigates multiple potential causes simultaneously
- **Evidence collection**: Gathers code, logs, git history, and environmental factors
- **Solution proposals**: Recommends multiple solutions with pros/cons/risks
- **Impact assessment**: Evaluates severity, scope, and urgency
- **Prevention recommendations**: Suggests measures to prevent recurrence

### When to Use

- Investigate production issues or bugs
- Analyze test failures during implementation
- Diagnose performance problems
- Research recurring issues
- Document known issues before fixing

---

## Usage

### Basic Syntax

```bash
/debug "<issue description>" [report-path1] [report-path2] ...
```

### Arguments

- **issue description** (required): Clear description of the problem to investigate
- **report-path** (optional): Context reports (research, other debug reports)

### Examples

```bash
# Basic investigation
/debug "Authentication failing with null pointer exception"

# With context report
/debug "Database migration fails on production" specs/042_db/reports/001_prod_analysis.md

# Multiple context reports
/debug "Performance regression after caching update" \
  specs/050_cache/reports/001_redis_analysis.md \
  specs/050_cache/reports/002_performance_benchmarks.md
```

---

## Investigation Techniques

### Code Analysis

**Static Analysis:**
- Search for relevant code patterns
- Identify error handling gaps
- Check for null/undefined access
- Review type safety

**Pattern Detection:**
- Search for similar issues in codebase
- Check git history for related changes
- Review closed issues/PRs
- Identify code smells

### Environmental Checks

**System State:**
- Check environment variables
- Review configuration files
- Verify dependencies/versions
- Check system resources

**Log Analysis:**
- Search error logs for patterns
- Check timestamps for correlation
- Identify error frequency
- Review stack traces

### Git History

**Recent Changes:**
```bash
# Changes in last week
git log --oneline --since="1 week ago"

# Changes to specific files
git log --oneline -- path/to/file

# Find when issue was introduced
git bisect start
```

---

## Parallel Hypothesis Testing

For complex issues (complexity ≥6), the command invokes multiple debug-analyst agents in parallel to investigate different hypotheses simultaneously.

### Complexity Triggers

Parallel investigation activates when:
1. **Issue complexity ≥6** (calculated from description and potential causes)
2. **Multiple potential causes** (3+ distinct hypotheses)
3. **System-wide impact** (affects multiple components)

### Parallel Investigation Workflow

```
┌─────────────────────────────────────────┐
│ Issue Complexity Analysis               │
│ → Calculate Complexity Score            │
│ → Identify Potential Causes             │
└─────────────────────────────────────────┘
                 │
                 ▼
         Complexity ≥6?
                 │
         ┌───────┴───────┐
         │               │
         ▼               ▼
        YES             NO
         │               │
         │               └──→ Single Investigation
         │
         ▼
┌─────────────────────────────────────────┐
│ Invoke 2-3 Debug Analysts in Parallel  │
│ → Each investigates different hypothesis│
│ → Simultaneous evidence collection      │
│ → Independent root cause analysis       │
└─────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Aggregate Findings                      │
│ → Collect all investigation results     │
│ → Compare hypotheses                    │
│ → Identify strongest root cause         │
│ → Merge evidence                        │
└─────────────────────────────────────────┘
```

### Agent Invocation

```
Task {
  subagent_type: "general-purpose"
  description: "Investigate hypothesis: <hypothesis>"
  prompt: |
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md
    
    You are acting as a Debug Analyst Agent.
    
    Issue: <issue description>
    Hypothesis: <specific hypothesis to investigate>
    Context: <relevant context and reports>
    
    Investigate this hypothesis:
    1. Collect relevant evidence
    2. Analyze code and logs
    3. Verify hypothesis
    4. Propose solutions if valid
    
    Return: Structured findings (evidence, verification, solutions)
}
```

### Benefits

- **50% faster investigation**: Parallel hypothesis testing vs sequential
- **Comprehensive coverage**: Multiple angles investigated simultaneously
- **Higher accuracy**: Cross-validation of findings
- **Reduced context**: Metadata-only aggregation (95% reduction)

---

## Report Structure

Debug reports follow a uniform structure for consistency and completeness.

### Standard Template

```markdown
# Debug Report: <Issue Title>

## Metadata
- **Report ID**: NNN
- **Date**: YYYY-MM-DD
- **Issue**: Brief description
- **Severity**: [CRITICAL/HIGH/MEDIUM/LOW]
- **Status**: Under Investigation
- **Related Files**: List of files
- **Context Reports**: Links to reports used

## Issue Description

Detailed description of the problem including:
- Symptoms observed
- When issue occurs
- Affected systems/users
- Error messages

## Investigation Summary

High-level summary of investigation process and findings.

## Evidence Collected

### Code Analysis
- Relevant code sections
- Potential problem areas
- Code patterns identified

### Recent Changes
- Git commits related to issue
- Configuration changes
- Dependency updates

### Error Patterns
- Error logs and stack traces
- Error frequency and timing
- Patterns across environments

## Root Cause Analysis

### Primary Root Cause
Most likely cause with supporting evidence

### Contributing Factors
1. Factor 1 with explanation
2. Factor 2 with explanation

### Verification
How root cause was verified (tests, reproduction steps)

## Proposed Solutions

### Solution 1 (Recommended)
- **Description**: What to do
- **Implementation**: How to implement
- **Pros**: Benefits
- **Cons**: Drawbacks
- **Risk**: [LOW/MEDIUM/HIGH]

### Solution 2 (Alternative)
[Same structure]

## Impact Assessment

- **Users Affected**: Scope
- **Systems Affected**: List
- **Data Impact**: Any data concerns
- **Urgency**: [IMMEDIATE/HIGH/MEDIUM/LOW]

## Next Steps

1. Immediate actions
2. Short-term fixes
3. Long-term improvements

## Prevention Recommendations

- How to prevent recurrence
- Monitoring improvements
- Process changes
- Testing enhancements

## References

- Related issues
- Documentation links
- External resources
```

### Report Location

Reports are stored in topic-based directories:

```
specs/
└── 042_authentication/
    ├── debug/
    │   ├── 001_debug.md
    │   ├── 002_debug.md
    │   └── 003_debug.md
    ├── plans/
    │   └── 042_implementation_plan.md
    └── reports/
        └── 042_research.md
```

---

## Troubleshooting

### No Debug Report Created

**Symptom**: Command runs but report not found

**Diagnosis**:
```bash
# Check specs directory
ls -la specs/*/debug/

# Verify permissions
ls -ld specs/
```

**Solutions:**
- Create debug directory: `mkdir -p specs/001_topic/debug`
- Fix permissions: `chmod 755 specs`
- Check disk space: `df -h`

### Parallel Investigation Not Triggering

**Symptom**: Complex issue but single investigation

**Diagnosis**:
```bash
# Check issue complexity
source .claude/lib/complexity-utils.sh
SCORE=$(calculate_issue_complexity "$ISSUE_DESC")
echo "Complexity: $SCORE"
```

**Solutions:**
- Add detail to issue description (increases complexity)
- Mention multiple potential causes
- Add system-wide impact keywords

### Root Cause Not Found

**Symptom**: Investigation complete but no root cause identified

**Solutions:**
- Provide more context reports
- Add specific error messages to description
- Include reproduction steps
- Review recent git changes manually
- Use `/research` for deeper analysis first

---

## See Also

- [/implement Command Guide](implement-command-guide.md) - Error recovery integration
- [/test Command Guide](test-command-guide.md) - Test failure debugging
- [Error Handling Utilities](../reference/library-api.md#error-handling) - Error classification
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Command Development Guide](command-development-guide.md)

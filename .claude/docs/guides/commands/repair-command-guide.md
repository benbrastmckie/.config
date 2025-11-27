# /repair Command - Complete Guide

**Executable**: `.claude/commands/repair.md`

**Quick Start**: Run `/repair` - analyzes error logs, identifies patterns, and creates fix implementation plan.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Error Filtering](#error-filtering)
5. [Advanced Topics](#advanced-topics)
6. [Troubleshooting](#troubleshooting)
7. [See Also](#see-also)

---

## Overview

### Purpose

The `/repair` command provides an error analysis and repair planning workflow that reads error logs, groups errors by patterns, identifies root causes, and creates an implementation plan to fix them. It transforms error data into actionable fixes by producing both analysis (error patterns) and repair steps (implementation plan).

### When to Use

- **Systematic error resolution**: When you have accumulated errors in the error log
- **Pattern detection**: Identifying systemic issues from error clusters
- **Root cause analysis**: Understanding underlying causes of failures
- **Fix planning**: Creating structured plans to address error patterns
- **Maintenance**: Regular error log cleanup and resolution

### When NOT to Use

- **Single error debugging**: Use `/debug` for investigating specific issues
- **Test failures**: Use `/debug` for test-specific root cause analysis
- **Query errors**: Use `/errors` to query and view error logs without creating plans
- **Direct fixes**: If you already know the fix, use `/build` with a manual plan

---

## Architecture

### Design Principles

1. **Two-Phase Workflow**: Error Analysis → Fix Planning (no implementation)
2. **Terminal at Plan**: Workflow ends after plan creation
3. **Analysis-Informed Planning**: Plan-architect uses error analysis reports for context
4. **Complexity-Aware Analysis**: Adjustable analysis depth (default: 2 for error analysis)
5. **Pattern-Based Fixes**: Groups related errors for systemic solutions
6. **Comprehensive Error Capture**: 80%+ error logging coverage ensures reliable analysis (Spec 945)

### Error Coverage and Reliability

As of Spec 945, the `/repair` command benefits from comprehensive error logging coverage:

- **80%+ Coverage Target**: All commands maintain minimum 80% error logging coverage
- **Automatic Detection**: Bash error traps catch unhandled errors (exit 127, unbound variables)
- **State Restoration Validation**: `validate_state_restoration()` logs state persistence failures
- **Enforcement**: Pre-commit hooks prevent coverage regressions

This comprehensive coverage means repair analyses capture the vast majority of actual errors, leading to more accurate fix plans and fewer missed error patterns.

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Two-state workflow
- **Behavioral Injection**: (behavioral-injection.md) Agent behavior separated from orchestration
- **Fail-Fast Verification**: (Standard 0) File and size verification
- **Topic-Based Structure**: (directory-protocols.md) Numbered topic directories with plans/ and reports/
- **Inline Analysis**: repair-analyst uses jq queries inline (no library modifications)

### Workflow States

```
┌──────────────┐
│   RESEARCH   │ ← Error log analysis
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     PLAN     │ ← Fix implementation plan creation (terminal state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   COMPLETE   │
└──────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Error Analysis**: repair-analyst agent for log analysis reports
- **Planning**: plan-architect agent for fix implementation plan creation
- **Error Logs**: .claude/data/logs/errors.jsonl for error data
- **Output**: specs/{NNN_topic}/reports/ and specs/{NNN_topic}/plans/

### Data Flow

1. **Input**: Optional error filters (--since, --type, --command, --severity) + complexity (default: 2)
2. **State Initialization**: sm_init() with workflow_type="research-and-plan"
3. **Analysis Phase**: repair-analyst reads error logs, groups by patterns, creates analysis reports
4. **Planning Phase**: plan-architect creates fix implementation plan from analysis
5. **Output**: Error analysis reports + fix implementation plan ready for /build

---

## Complete Error Management Workflow

The `/repair` command is part of a comprehensive error management lifecycle that bridges error discovery and systematic resolution. Understanding this workflow helps you leverage error logging for continuous improvement and proactive debugging.

### Error Lifecycle Phases

**1. Error Production (Automatic)**
- Commands and agents automatically log errors via `log_command_error()`
- Errors stored in `~/.claude/data/logs/errors.jsonl` with full context
- No manual intervention required

**2. Error Querying (/errors)**
- View and filter logged errors by time, type, command, or severity
- Generate summary reports to identify error patterns
- Determine scope and priority for analysis

**3. Error Analysis (/repair)**
- Group errors by pattern and root cause using repair-analyst agent
- Create comprehensive error analysis reports in `specs/{NNN_topic}/reports/`
- Generate implementation plans with fix phases via plan-architect agent
- Return plan path ready for execution

**4. Fix Implementation (/build)**
- Execute repair plans with automatic testing after each phase
- Create git commits for completed fix phases
- Handle failures via debugging workflow if needed

**5. Verification (/errors)**
- Query errors after fix implementation to confirm resolution
- Validate error patterns no longer occur
- Close the error management loop

### Example Workflow

Complete workflow from error discovery through resolution:

```bash
# Step 1: Discover error patterns
/errors --since 24h --summary

# Output shows multiple state_error and parse_error instances across commands

# Step 2: Analyze specific error pattern (e.g., state errors)
/repair --type state_error --complexity 3

# Creates:
# - specs/857_state_error_patterns/reports/001_state_error_analysis.md
# - specs/857_state_error_patterns/plans/001_state_error_fix_plan.md

# Step 3: Review plan before implementation
# (Manual review of plan file to understand proposed fixes)

# Step 4: Execute repair plan
/build specs/857_state_error_patterns/plans/001_state_error_fix_plan.md

# Step 5: Verify fixes resolved the errors
/errors --type state_error --since 10m

# Output: No errors found (confirmation)
```

### Integration Points

- **Error Handling Pattern**: See [Error Handling Pattern](../../concepts/patterns/error-handling.md) for technical integration details
- **Errors Command**: See [Errors Command Guide](errors-command-guide.md) for error querying and discovery workflow
- **Build Command**: See [Build Command Guide](build-command-guide.md) for executing repair plans with testing

### When to Use /repair vs /debug

**Use /repair when**:
- Multiple similar errors across different workflows
- Error patterns suggest systematic issues (not one-off bugs)
- You want automated analysis + fix plan generation
- Working with logged errors from historical execution

**Use /debug when**:
- Single specific failure needs root cause analysis
- Interactive debugging with file inspection required
- Error not logged or needs immediate investigation
- Working with current/live failures

---

## Usage Examples

### Example 1: Analyze All Errors

```bash
/repair
```

**Expected Output**:
```
=== Error Analysis and Repair Planning Workflow ===

✓ State machine initialized
✓ Error log path: .claude/data/logs/errors.jsonl

=== Phase 1: Error Analysis ===

EXECUTE NOW: USE the Task tool to invoke repair-analyst agent

Workflow-Specific Context:
- Error Filters: {"since":"","type":"","command":"","severity":""}
- Research Complexity: 2
- Output Directory: .claude/specs/835_error_analysis_and_repair/reports
- Workflow Type: research-and-plan
- Error Log Path: .claude/data/logs/errors.jsonl

✓ Analysis phase complete (1 report created)

=== Phase 2: Planning ===

EXECUTE NOW: USE the Task tool to invoke plan-architect agent

Workflow-Specific Context:
- Feature Description: error analysis and repair
- Output Path: .claude/specs/835_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md
- Research Reports: [".claude/specs/835_error_analysis_and_repair/reports/001_error_analysis.md"]
- Workflow Type: research-and-plan
- Operation Mode: new plan creation

✓ Planning phase complete

=== Error Analysis and Planning Complete ===

Workflow Type: research-and-plan
Specs Directory: .claude/specs/835_error_analysis_and_repair
Error Analysis Reports: 1 reports in .claude/specs/835_error_analysis_and_repair/reports
Fix Implementation Plan: .claude/specs/835_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md

Next Steps:
- Review plan: cat .claude/specs/835_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md
- Implement fixes: /build .claude/specs/835_error_analysis_and_repair/plans/001_error_analysis_and_repair_plan.md
```

**Explanation**:
Analyzes all errors in the error log, groups them by patterns, identifies root causes, and creates a fix implementation plan.

---

### Example 2: Filter by Error Type

```bash
/repair --type state_error
```

**Expected Output**:
Only analyzes `state_error` type errors. Creates focused analysis report and fix plan for state management issues.

**Explanation**:
Filters error log to only include state_error entries. Useful when targeting specific categories of failures.

---

### Example 3: Filter by Time Range

```bash
/repair --since 2025-11-19
```

**Expected Output**:
Analyzes errors that occurred after 2025-11-19. Creates analysis of recent error patterns.

**Explanation**:
Uses ISO 8601 timestamp to filter errors by time. Useful for analyzing errors from a specific time period (e.g., after a deployment).

---

### Example 4: Filter by Command and Severity

```bash
/repair --command /build --severity high --complexity 3
```

**Expected Output**:
Analyzes high-severity errors from the /build command with deeper analysis (complexity 3).

**Explanation**:
Combines multiple filters for targeted analysis. Higher complexity enables more thorough pattern detection and root cause analysis.

---

## Error Filtering

### Available Filters

All filters are optional. When no filters are provided, all errors are analyzed.

#### --since TIME

Filter errors after a specific timestamp.

**Format**: ISO 8601 timestamp (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)

**Examples**:
```bash
/repair --since 2025-11-19
/repair --since 2025-11-19T14:30:00
```

**Use Case**: Analyze errors from recent deployments, specific time windows, or after bug fixes.

---

#### --type TYPE

Filter by error type.

**Valid Types**:
- `state_error` - Workflow state persistence issues
- `validation_error` - Input validation failures
- `agent_error` - Subagent execution failures
- `parse_error` - Output parsing failures
- `file_error` - File system operations failures
- `timeout_error` - Operation timeout errors
- `execution_error` - General execution failures
- `dependency_error` - Missing or invalid dependencies

**Examples**:
```bash
/repair --type state_error
/repair --type validation_error
```

**Use Case**: Focus on specific categories of errors for targeted fixes.

---

#### --command CMD

Filter by command that generated the error.

**Examples**:
```bash
/repair --command /build
/repair --command /plan
/repair --command /debug
```

**Use Case**: Identify issues with specific commands or workflows.

---

#### --severity LEVEL

Filter by error severity level.

**Valid Levels**: low, medium, high, critical

**Examples**:
```bash
/repair --severity high
/repair --severity critical
```

**Use Case**: Prioritize fixing high-impact errors first.

---

#### --complexity 1-4

Set analysis depth (default: 2).

**Levels**:
- **1**: Basic - Quick pattern grouping, simple recommendations
- **2**: Standard - Pattern analysis with frequencies, root cause identification
- **3**: Deep - Detailed correlation analysis, multiple fix strategies
- **4**: Comprehensive - Extensive investigation, risk analysis, phased fix approach

**Examples**:
```bash
/repair --complexity 1  # Quick analysis
/repair --complexity 3  # Deep investigation
```

**Use Case**: Adjust thoroughness based on error volume and complexity.

---

#### --file PATH

Provide a workflow output file for comprehensive error analysis. The repair-analyst agent will read and analyze this file for runtime errors, path mismatches, state file errors, and bash execution errors in addition to the error log.

**Format**: Absolute or relative file path

**Examples**:
```bash
# Analyze workflow output from a failed /plan command
/repair --file .claude/plan-output.md --type state_error

# Analyze research output with path mismatch errors
/repair --file .claude/research-output.md --since 2025-11-20

# Combine with other filters for targeted analysis
/repair --file .claude/debug-output.md --command /build --complexity 3
```

**Use Case**:
- **Runtime error analysis**: When errors.jsonl entries lack sufficient context and the actual workflow output contains more detailed error messages
- **Path mismatch debugging**: When state files reference incorrect paths (e.g., HOME vs CLAUDE_PROJECT_DIR mismatches)
- **Correlation analysis**: Matching logged errors to actual runtime output for more accurate root cause identification

**What gets analyzed**:
- State file errors ("State file not found", "STATE_FILE variable empty")
- Path mismatch patterns ("expected path", "actual path", "not found at")
- Bash execution errors ("exit code", "line N:", "command not found")
- Variable unset errors ("unbound variable")
- Permission errors ("Permission denied", "cannot access")

**Report output**: When --file is provided, the error analysis report includes a "Workflow Output Analysis" section with:
- File path and size analyzed
- Runtime errors detected with line numbers and context
- Path mismatches identified
- Correlation with error log entries

---

### Combining Filters

Multiple filters can be combined for precise targeting:

```bash
# High-severity state errors from /build in last week
/repair --type state_error --command /build --severity high --since 2025-11-12

# All validation errors with deep analysis
/repair --type validation_error --complexity 3
```

---

## Advanced Topics

### Error Analysis Reports

The repair-analyst agent creates structured markdown reports with:

- **Executive Summary**: Error count, most common types, urgency level
- **Error Patterns**: Frequency, commands affected, root cause hypothesis
- **Root Cause Analysis**: Underlying issues (not just symptoms)
- **Recommendations**: Prioritized fixes with effort estimates

**Report Structure**:
```markdown
# Error Analysis Report

## Metadata
- Date: YYYY-MM-DD
- Agent: repair-analyst
- Error Count: N
- Time Range: earliest - latest

## Executive Summary
[2-3 sentences with key findings]

## Error Patterns

### Pattern 1: [Name]
- Frequency: N errors (X%)
- Commands Affected: [list]
- Root Cause Hypothesis: [explanation]
- Proposed Fix: [approach]

## Root Cause Analysis

### Root Cause 1: [Issue]
- Related Patterns: [list]
- Impact: N commands, X% of errors
- Fix Strategy: [approach]

## Recommendations

### 1. [Fix Name] (Priority: High, Effort: Medium)
- Description: [what to do]
- Rationale: [why]
- Implementation: [how]
```

---

### Integration with /errors Command

The `/repair` command complements `/errors`:

- **`/errors`**: Query utility for viewing error logs (read-only)
- **`/repair`**: Analysis and planning workflow (creates reports and plans)

**Workflow**:
1. Use `/errors` to explore error logs and identify patterns
2. Use `/repair` with appropriate filters to create fix plans
3. Use `/build` to execute fix implementation

**Example**:
```bash
# 1. Query recent errors
/errors --since 2025-11-19

# 2. Analyze and plan fixes
/repair --since 2025-11-19 --complexity 2

# 3. Implement fixes
/build .claude/specs/NNN_topic/plans/001_fix_plan.md
```

---

### Pattern Detection Strategies

The repair-analyst uses inline jq queries for pattern analysis:

**Frequency Analysis**:
```bash
# Count by error type
jq -s 'group_by(.error_type) | map({type: .[0].error_type, count: length})' errors.jsonl

# Count by command
jq -s 'group_by(.command) | map({command: .[0].command, count: length})' errors.jsonl
```

**Temporal Analysis**:
```bash
# Errors by date
jq -s 'group_by(.timestamp[0:10]) | map({date: .[0].timestamp[0:10], count: length})' errors.jsonl
```

**Root Cause Correlation**:
```bash
# Find errors with similar messages
jq -s 'group_by(.message) | map(select(length > 1))' errors.jsonl
```

---

## Troubleshooting

### Issue: No errors found

**Symptom**: repair-analyst reports no errors to analyze

**Causes**:
1. Error log file doesn't exist or is empty
2. Filters are too restrictive (no errors match)
3. Error logging not configured

**Solutions**:
```bash
# Check if error log exists
ls -la .claude/data/logs/errors.jsonl

# Check error count
wc -l .claude/data/logs/errors.jsonl

# Try without filters
/repair

# Check specific time range
/repair --since 2025-11-01
```

---

### Issue: Analysis report too small

**Symptom**: Verification fails with "Report file too small"

**Causes**:
1. Very few errors matched filters
2. Analysis complexity too low
3. Agent didn't complete analysis

**Solutions**:
```bash
# Increase complexity
/repair --complexity 3

# Remove filters to analyze all errors
/repair

# Check error log manually
cat .claude/data/logs/errors.jsonl | jq .
```

---

### Issue: Plan doesn't address root causes

**Symptom**: Generated plan focuses on symptoms, not underlying issues

**Causes**:
1. Analysis complexity too low
2. Insufficient error data for pattern detection
3. Need manual root cause investigation

**Solutions**:
```bash
# Use higher complexity
/repair --complexity 4

# Use /debug for specific error investigation
/debug "investigate state_error in /build command"

# Manually review error log
/errors --type state_error
```

---

## See Also

### Related Commands

- [/errors](errors-command-guide.md) - Query and view error logs
- [/debug](debug-command-guide.md) - Debug-focused root cause analysis
- [/build](build-command-guide.md) - Execute fix implementation plans
- [/plan](plan-command-guide.md) - Research and planning workflow pattern

### Related Concepts

- [Error Handling](../../reference/architecture/error-handling.md) - Error logging and handling standards
- [State-Based Orchestration](../../architecture/state-based-orchestration-overview.md) - Workflow state machine
- [Directory Protocols](../../concepts/directory-protocols.md) - Topic-based artifact organization

### Related Agents

- [repair-analyst](../../agents/repair-analyst.md) - Error log analysis agent
- [plan-architect](../../agents/plan-architect.md) - Implementation plan creation agent

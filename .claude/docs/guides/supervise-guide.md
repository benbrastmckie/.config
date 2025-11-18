# /supervise Usage Guide

## Overview

The `/supervise` command is a clean multi-agent workflow orchestrator that coordinates research, planning, implementation, testing, debugging, and documentation through a 7-phase workflow.

## Quick Start

### Basic Usage

```bash
# Research only
/supervise "research authentication patterns"

# Research and plan (most common)
/supervise "research auth patterns for planning"

# Full implementation
/supervise "implement user authentication feature"

# Debug existing code
/supervise "fix login timeout bug"
```

## Workflow Scope Types

The command automatically detects the workflow type from your description and executes only the appropriate phases:

###

 1. Research-Only

**When to use**: Pure exploratory research without planning or implementation

**Keywords**: "research [topic]" without "plan" or "implement"

**Phases executed**: 0-1 only

**Output**:
- Research reports in `specs/{NNN_topic}/reports/`
- No plan created
- No summary generated

**Example**:
```bash
/supervise "research best practices for error handling in bash scripts"
```

### 2. Research-and-Plan (MOST COMMON)

**When to use**: Research to inform implementation planning

**Keywords**: "research...to create plan", "analyze...for planning"

**Phases executed**: 0-2 only

**Output**:
- Research reports in `specs/{NNN_topic}/reports/`
- Implementation plan in `specs/{NNN_topic}/plans/`
- No summary (no implementation occurred)

**Example**:
```bash
/supervise "research authentication patterns for planning JWT implementation"
```

### 3. Full-Implementation

**When to use**: Complete feature development from research through documentation

**Keywords**: "implement", "build", "add feature"

**Phases executed**: 0-4, 6 (Phase 5 conditional on test failures)

**Output**:
- Research reports
- Implementation plan
- Implementation artifacts
- Test results
- Debug reports (if tests failed)
- Workflow summary

**Example**:
```bash
/supervise "implement user authentication with JWT tokens"
```

### 4. Debug-Only

**When to use**: Bug fixing without new implementation

**Keywords**: "fix [bug]", "debug [issue]", "troubleshoot [error]"

**Phases executed**: 0, 1, 5 only

**Output**:
- Research reports (root cause analysis)
- Debug reports
- No new plan or summary

**Example**:
```bash
/supervise "debug and fix the login timeout issue in auth module"
```

## Workflow Phases

```
Phase 0: Location and Path Pre-Calculation
  ↓
Phase 1: Research (2-4 parallel agents)
  ↓
Phase 2: Planning (conditional)
  ↓
Phase 3: Implementation (conditional)
  ↓
Phase 4: Testing (conditional)
  ↓
Phase 5: Debug (conditional - only if tests fail)
  ↓
Phase 6: Documentation (conditional - only if implementation occurred)
```

## Performance Targets

- **Context Usage**: <25% throughout workflow
- **File Creation Rate**: 100% with fail-fast error handling
- **Error Feedback**: Immediate (<1s) with structured diagnostics
- **Enhanced Error Reporting**:
  - Error location extraction accuracy: >90%
  - Error type categorization accuracy: >85%
  - Error reporting overhead: <30ms per error (negligible)

## Common Patterns

### Pattern 1: Exploratory Research

Use when you need to understand a topic without committing to implementation:

```bash
/supervise "research state management patterns in React applications"
```

**Output**: Research reports only

**Next steps**: Review reports, decide if planning is needed

### Pattern 2: Research-Driven Planning

Use when you want research to inform a detailed implementation plan:

```bash
/supervise "research API authentication methods for planning secure REST API"
```

**Output**: Research reports + Implementation plan

**Next steps**: Review plan, run `/implement` when ready

### Pattern 3: End-to-End Feature Development

Use when you want complete automation from research through testing:

```bash
/supervise "implement rate limiting for API endpoints with Redis backend"
```

**Output**: Complete artifact set (research, plan, implementation, tests, summary)

**Next steps**: Review summary, address any test failures

### Pattern 4: Bug Investigation and Fix

Use when debugging existing code:

```bash
/supervise "fix memory leak in background job processor"
```

**Output**: Root cause analysis + Debug report

**Next steps**: Review fixes, verify solution

## Tips and Best Practices

### 1. Be Specific in Your Description

**Good**:
```bash
/supervise "research OAuth 2.0 flows for planning secure third-party integrations"
```

**Less effective**:
```bash
/supervise "research security"
```

### 2. Use Appropriate Keywords

- **"research"** - Triggers research-only or research-and-plan
- **"for planning"** - Ensures plan is created
- **"implement"** - Triggers full implementation workflow
- **"fix"/"debug"** - Triggers debug-only workflow

### 3. Leverage Automatic Scope Detection

The command automatically determines workflow scope, so you don't need to specify phases manually. Just describe your goal naturally.

### 4. Check Output Locations

All artifacts are organized in topic-based directories:

```
specs/
  NNN_topic_name/
    reports/        # Research reports
    plans/          # Implementation plans
    summaries/      # Workflow summaries
    debug/          # Debug reports (if applicable)
```

### 5. Use Fail-Fast Diagnostics

When errors occur, the command provides structured 5-section diagnostics:

1. **ERROR**: What failed
2. **Expected/Found**: What was supposed to happen vs what actually happened
3. **DIAGNOSTIC INFORMATION**: Paths, directory status, agent details
4. **Diagnostic Commands**: Example commands to debug
5. **Most Likely Causes**: Common failure reasons

Review these diagnostics to quickly identify and resolve issues.

## Troubleshooting

### Agent Failed to Create File

**Symptom**: Verification checkpoint fails with "File does not exist"

**Diagnosis**: Check the diagnostic output for:
- Expected path
- Directory status
- Agent output above verification checkpoint

**Common causes**:
1. Agent encountered error during execution
2. Path mismatch (agent used different path)
3. Permission denied

**Solution**: Run the diagnostic commands provided in the error output

### Workflow Scope Incorrect

**Symptom**: Wrong phases executed (e.g., plan created when you wanted research-only)

**Diagnosis**: Review your workflow description

**Solution**: Adjust keywords:
- Add "for planning" to trigger plan creation
- Remove "implement" to avoid full workflow
- Use "research" alone for research-only

### Tests Failing

**Symptom**: Phase 5 (Debug) executes automatically

**Behavior**: This is expected - Phase 5 only runs if tests fail

**Solution**: Review debug report for proposed fixes, or run `/implement` to apply fixes iteratively

## See Also

- [/supervise Phase Reference](../archive/reference/supervise-phases.md) - Detailed phase documentation (archived)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How agents are invoked
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - Fail-fast error handling
- [Directory Protocols](../concepts/directory-protocols.md) - Artifact organization structure

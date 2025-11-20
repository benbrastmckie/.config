# /debug Command - Complete Guide

**Executable**: `.claude/commands/debug.md`

**Quick Start**: Run `/debug "<issue-description>"` - debug-focused workflow for root cause analysis.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Usage Examples](#usage-examples)
4. [Advanced Topics](#advanced-topics)
5. [Troubleshooting](#troubleshooting)
6. [See Also](#see-also)

---

## Overview

### Purpose

The `/debug` command provides a debug-focused workflow for investigating issues through research, creating debug strategy plans, and performing root cause analysis. It automates the investigation process using specialized agents and produces actionable debugging artifacts.

### When to Use

- **Bug investigation**: Analyzing production errors, timeouts, or failures
- **Root cause analysis**: Investigating intermittent issues or performance problems
- **Debug strategy**: Creating systematic debugging approaches for complex issues
- **Error diagnosis**: Understanding stack traces, logs, and error patterns

### When NOT to Use

- **Implementing features**: Use `/build` or `/coordinate` for implementation workflows
- **Creating plans**: Use `/plan` or `/plan` for implementation planning
- **Research without fixes**: Use `/research` for investigation-only tasks
- **Plan revision**: Use `/revise` for modifying existing plans

---

## Architecture

### Design Principles

1. **Debug-Only Workflow**: Focuses solely on investigation and analysis, not implementation
2. **Three-Phase Process**: Research → Plan → Debug with agent delegation
3. **Artifact Generation**: Creates research reports, debug strategy plan, and debug artifacts
4. **Complexity-Aware**: Adjustable research complexity (1-4) for investigation depth
5. **State Machine Based**: Terminal state is "debug" (workflow ends after root cause analysis)

### Patterns Used

- **State-Based Orchestration**: (state-based-orchestration-overview.md) Manages debug workflow states
- **Behavioral Injection**: (behavioral-injection.md) Separates orchestration from agent behavior
- **Fail-Fast Verification**: (Standard 0) File-level verification with size checks
- **Complexity-Based Research**: (complexity-utils.sh) Adjusts research depth based on issue complexity

### Workflow States

```
┌──────────────┐
│   RESEARCH   │ ← Issue investigation
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     PLAN     │ ← Debug strategy creation
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    DEBUG     │ ← Root cause analysis (terminal state)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   COMPLETE   │
└──────────────┘
```

### Integration Points

- **State Machine**: workflow-state-machine.sh (>=2.0.0) for state management
- **Research**: research-specialist agent for issue investigation
- **Planning**: plan-architect agent for debug strategy creation
- **Analysis**: debug-analyst agent for root cause investigation
- **Output**: specs/{NNN_topic}/reports/, plans/, debug/ directories

### Data Flow

1. **Input**: Issue description + optional complexity level (default: 2)
2. **Research Phase**: research-specialist creates investigation reports
3. **Planning Phase**: plan-architect creates debug strategy plan
4. **Debug Phase**: debug-analyst performs root cause analysis
5. **Output**: Debug artifacts in specs/{topic}/debug/, strategy plan, research reports

---

## Usage Examples

### Example 1: Basic Bug Investigation

```bash
/debug"authentication timeout errors in production"
```

**Expected Output**:
```
=== Debug-Focused Workflow ===
Issue: authentication timeout errors in production
Research Complexity: 2

✓ State machine initialized

=== Phase 1: Research (Issue Investigation) ===

EXECUTE NOW: USE the Task tool to invoke research-specialist agent

Workflow-Specific Context:
- Research Complexity: 2
- Issue Description: authentication timeout errors in production
- Output Directory: /home/user/.config/.claude/specs/748_authentication_timeout/reports
- Workflow Type: debug-only
- Context Mode: root cause analysis

✓ Research phase complete (3 reports created)

=== Phase 2: Planning (Debug Strategy) ===

EXECUTE NOW: USE the Task tool to invoke plan-architect agent

✓ Planning phase complete (strategy: 001_debug_strategy.md)

=== Phase 3: Debug (Root Cause Analysis) ===

EXECUTE NOW: USE the Task tool to invoke debug-analyst agent

✓ Debug phase complete (artifacts: 2 files)

=== Debug Workflow Complete ===

Workflow Type: debug-only
Specs Directory: .claude/specs/748_authentication_timeout
Research Reports: 3 reports
Debug Strategy Plan: .claude/specs/748_authentication_timeout/plans/001_debug_strategy.md
Debug Artifacts: 2 files

Next Steps:
- Review debug strategy: cat .claude/specs/748_authentication_timeout/plans/001_debug_strategy.md
- Review debug artifacts: ls .claude/specs/748_authentication_timeout/debug
- Apply fixes identified in analysis
- Re-run tests to verify fix
```

**Explanation**:
Investigates authentication timeouts through automated research, creates systematic debug strategy, and performs root cause analysis. Generates comprehensive debugging artifacts for manual fix application.

### Example 2: Complex Issue with Higher Complexity

```bash
/debug"intermittent database connection failures --complexity 4"
```

**Expected Output**:
```
=== Debug-Focused Workflow ===
Issue: intermittent database connection failures
Research Complexity: 4

✓ State machine initialized

=== Phase 1: Research (Issue Investigation) ===

NOTE: Hierarchical supervision mode (complexity ≥4)
Invoke research-sub-supervisor agent to coordinate multiple sub-agents

✓ Research phase complete (8 reports created)

=== Phase 2: Planning (Debug Strategy) ===
...
```

**Explanation**:
Higher complexity (4) triggers hierarchical supervision mode for deeper investigation. Produces more comprehensive research reports and detailed debug strategy.

### Example 3: Performance Issue Investigation

```bash
/debug"API endpoint latency exceeds 2s on POST /api/users"
```

**Expected Output**:
```
=== Debug-Focused Workflow ===
Issue: API endpoint latency exceeds 2s on POST /api/users
Research Complexity: 2

✓ State machine initialized

=== Phase 1: Research (Issue Investigation) ===
...
✓ Research phase complete (4 reports created)

=== Phase 2: Planning (Debug Strategy) ===
...
✓ Planning phase complete (strategy: 001_debug_strategy.md)

=== Phase 3: Debug (Root Cause Analysis) ===
...
✓ Debug phase complete (artifacts: 3 files)

=== Debug Workflow Complete ===

Next Steps:
- Review debug strategy: cat .claude/specs/749_api_endpoint_latency/plans/001_debug_strategy.md
- Review debug artifacts: ls .claude/specs/749_api_endpoint_latency/debug
- Apply fixes identified in analysis
- Re-run tests to verify fix
```

**Explanation**:
Performance issues are investigated with focus on latency analysis. Debug artifacts may include profiling data, query analysis, or resource utilization reports.

---

## Advanced Topics

### Performance Considerations

**Complexity Levels**:
- **Level 1**: Quick investigation, 1-2 reports, surface-level analysis
- **Level 2** (default): Standard investigation, 3-4 reports, moderate depth
- **Level 3**: Deep investigation, 5-6 reports, comprehensive analysis
- **Level 4**: Hierarchical investigation, 7+ reports, exhaustive analysis with sub-supervisor

**Research Time**:
- Complexity 1: ~5-10 minutes
- Complexity 2: ~10-20 minutes
- Complexity 3: ~20-40 minutes
- Complexity 4: ~40-60 minutes

**Artifact Storage**:
- Reports: `.claude/specs/{NNN_topic}/reports/`
- Plans: `.claude/specs/{NNN_topic}/plans/`
- Debug artifacts: `.claude/specs/{NNN_topic}/debug/`

### Customization

**Complexity Override**:
```bash
# Embedded in description
/debug"issue description --complexity 3"

# Or use explicit syntax (if supported)
/debug--complexity 3 "issue description"
```

**Issue Description Best Practices**:
- Be specific: Include error messages, stack traces, affected components
- Provide context: Environment (production/staging), frequency, user impact
- Include constraints: "occurs only on mobile browsers", "happens after 10pm"

### Integration with Other Workflows

**Fix → Build Chain**:
```bash
/debug"authentication bug"              # Investigate and identify root cause
# Manually apply fixes
/build                                 # Re-run implementation tests
```

**Research → Fix Chain**:
```bash
/research "authentication patterns in codebase"  # Understand system
/debug"authentication timeout errors"                    # Debug specific issue
```

**Fix → Plan → Build Chain**:
```bash
/debug"database performance issues"     # Identify problems
/plan "optimize database queries"      # Create fix implementation plan
/build                                 # Implement fixes
```

---

## Troubleshooting

### Common Issues

#### Issue 1: Research Phase Fails to Create Artifacts

**Symptoms**:
- Error: "Research phase failed to create report files"
- Research directory exists but is empty

**Cause**:
Research-specialist agent encountered errors or issue description too vague.

**Solution**:
```bash
# Make issue description more specific
/debug"authentication timeout errors in production - JWT validation fails after 30s"

# Or increase complexity for deeper investigation
/debug"authentication timeout errors --complexity 3"

# Check research-specialist agent logs
cat .claude/agents/research-specialist.md
```

#### Issue 2: Plan File Too Small

**Symptoms**:
- Error: "Plan file too small (XXX bytes)"
- Plan created but minimal content

**Cause**:
Plan-architect agent received insufficient research context or encountered errors.

**Solution**:
```bash
# Verify research reports exist
ls .claude/specs/*/reports/

# Check report file sizes
du -h .claude/specs/*/reports/*.md

# If reports are empty, re-run with higher complexity
/debug"issue description --complexity 3"
```

#### Issue 3: No Debug Artifacts Created

**Symptoms**:
- Note: "No debug artifacts created (analysis may be in plan or reports)"
- Debug directory empty

**Cause**:
Debug-analyst provided analysis in strategy plan or reports rather than separate artifacts. This is normal for some issue types.

**Solution**:
```bash
# Review debug strategy plan
cat .claude/specs/*/plans/001_debug_strategy.md

# Review research reports
cat .claude/specs/*/reports/*.md

# Debug analysis is often embedded in these files
```

#### Issue 4: State Machine Initialization Failed

**Symptoms**:
- Error: "State machine initialization failed"
- Diagnostic shows library version issues

**Cause**:
Missing or incompatible workflow-state-machine.sh version.

**Solution**:
```bash
# Check library version
grep "VERSION=" .claude/lib/workflow/workflow-state-machine.sh

# Ensure version >=2.0.0
# Update library if needed

# Verify state-persistence.sh exists
ls .claude/lib/core/state-persistence.sh
```

#### Issue 5: Issue Description Too Vague

**Symptoms**:
- Research produces generic reports
- Debug strategy lacks specific steps
- Root cause analysis inconclusive

**Cause**:
Issue description doesn't provide enough context for targeted investigation.

**Solution**:
Improve issue description with:
- **Error messages**: Exact error text or codes
- **Stack traces**: Relevant portions of stack traces
- **Environment**: Production/staging, OS, browser, version
- **Steps to reproduce**: How to trigger the issue
- **Frequency**: Always, intermittent, specific conditions

Example:
```bash
# Before (too vague)
/debug"authentication problems"

# After (specific)
/debug"JWT validation fails with 'Token expired' error in production after exactly 30 seconds, only affects users in EU timezone, started after deployment on 2025-01-15"
```

#### Issue 6: Workflow Failures Investigation

**Symptoms**:
- Debug workflow itself fails
- Agent invocation errors
- State machine errors during debug process

**Cause**:
Previous workflow errors or system issues affecting debug workflow execution.

**Solution**:
Use `/errors` command to investigate error history before debugging:

```bash
# Check recent errors for this workflow
/errors --workflow-id debug_20251019_153045

# Check recent /debug command errors
/errors --command /debug --limit 5

# Review error patterns before debugging
/errors --summary

# Investigate specific error types
/errors --type agent_error --limit 10
```

This helps identify if the issue is:
- A recurring pattern across multiple workflows
- Specific to certain agents or phases
- Related to recent system changes or environment issues

**See Also**: [/errors Command Guide](errors-command-guide.md)

### Debug Mode

Enable bash debugging for verbose output:

```bash
# Enable trace mode
set -x
/debug"issue description"
set +x
```

**State Inspection**:
```bash
# View current state
cat ~/.claude/data/state/workflow_state.json | jq .

# Check workflow type
cat ~/.claude/data/state/workflow_state.json | jq '.workflow_type'
```

**Artifact Verification**:
```bash
# List all research reports
find .claude/specs -name "*.md" -path "*/reports/*"

# Check file sizes
find .claude/specs -path "*/reports/*.md" -exec du -h {} \;

# Verify minimum size (should be >100 bytes)
find .claude/specs -path "*/reports/*.md" -size -100c
```

### Getting Help

- Check [Command Reference](../reference/standards/command-reference.md) for quick syntax
- Review [Research-Specialist Agent](../../agents/research-specialist.md) for research patterns
- See related commands: `/research`, `/debug`, `/build`
- Review [State-Based Orchestration](../architecture/state-based-orchestration-overview.md) for workflow details

---

## See Also

- [Research-Specialist Agent](../../agents/research-specialist.md)
- [Plan-Architect Agent](../../agents/plan-architect.md)
- [Debug-Analyst Agent](../../agents/debug-analyst.md)
- [State-Based Orchestration Overview](../architecture/state-based-orchestration-overview.md)
- [Command Reference](../reference/standards/command-reference.md)
- Related Commands: `/debug`, `/research`, `/build`, `/coordinate`

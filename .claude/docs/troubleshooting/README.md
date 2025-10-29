# Troubleshooting Guide Index

This directory contains troubleshooting guides for common issues in the .claude/ system.

## Core Troubleshooting Guides

### [Agent Delegation Troubleshooting](./agent-delegation-troubleshooting.md) ⭐ START HERE
- **Problem**: All agent delegation-related issues (unified guide)
- **Category**: Implementation/Configuration
- **Coverage**: Commands not delegating, 0% delegation rate, path mismatches, context bloat, recursion risks, topic organization
- **Fix Time**: 5-30 minutes depending on issue
- **Features**:
  - Decision tree for quick diagnosis
  - 6 root cause analyses with solutions
  - Prevention guidelines and code review checklist
  - Real-world case studies (Specs 438, 469)

**Quick Links by Symptom**:
- No Task invocations → [Issue A: Command Not Delegating](./agent-delegation-troubleshooting.md#issue-a-command-executes-directly-no-delegation)
- "File not found" after creation → [Issue B: Path Mismatch](./agent-delegation-troubleshooting.md#issue-b-artifact-created-at-wrong-location)
- Task invocations but 0% success → [Issue C: Delegation Failure](./agent-delegation-troubleshooting.md#issue-c-delegation-failure-0-rate)
- Context usage >50% → [Issue D: Context Bloat](./agent-delegation-troubleshooting.md#issue-d-context-reduction-not-achieved)
- Agent uses SlashCommand → [Issue E: Recursion Risk](./agent-delegation-troubleshooting.md#issue-e-recursion-risk-slash-command-invocation)
- Flat file structure → [Issue F: Topic Organization](./agent-delegation-troubleshooting.md#issue-f-artifacts-not-in-topic-directories)

### [Inline Template Duplication](./inline-template-duplication.md)
- **Problem**: Behavioral content duplicated in command files instead of referenced from agent files
- **Category**: Anti-Pattern
- **Priority**: Medium (affects maintainability, not functionality)
- **Symptoms**: Large command files, STEP sequences in commands, maintenance burden
- **Fix Time**: 15-30 minutes per command
- **Impact**: 90% code reduction per agent invocation when fixed

## Quick Reference

### By Problem Type

**Agent Delegation:**
- [Agent Delegation Troubleshooting](./agent-delegation-troubleshooting.md) - Unified guide for all delegation issues

**Anti-Patterns:**
- [Inline Template Duplication](./inline-template-duplication.md) - Behavioral content duplication

### By Symptom

**Task Tool Not Invoked:**
- [Command Executes Directly](./agent-delegation-troubleshooting.md#issue-a-command-executes-directly-no-delegation)

**Agent Failures:**
- [Delegation Failure (0% Rate)](./agent-delegation-troubleshooting.md#issue-c-delegation-failure-0-rate)
- [Path Mismatch](./agent-delegation-troubleshooting.md#issue-b-artifact-created-at-wrong-location)
- [Context Bloat](./agent-delegation-troubleshooting.md#issue-d-context-reduction-not-achieved)

**Recursion/Organization:**
- [Recursion Risk](./agent-delegation-troubleshooting.md#issue-e-recursion-risk-slash-command-invocation)
- [Topic Organization](./agent-delegation-troubleshooting.md#issue-f-artifacts-not-in-topic-directories)

**Large/Bloated Files:**
- [Inline Template Duplication](./inline-template-duplication.md) - Command files >2000 lines

**Maintenance Burden:**
- [Inline Template Duplication](./inline-template-duplication.md) - Updating behavior in multiple files

## Diagnostic Workflow

### Step 1: Identify Your Symptom

Use the [Agent Delegation Decision Tree](./agent-delegation-troubleshooting.md#quick-diagnosis-decision-tree) to quickly identify your issue type.

### Step 2: Apply Fix

Follow the specific solution in the troubleshooting guide for your issue.

### Step 3: Verify Fix

Run validation commands to confirm the fix:
```bash
# Agent delegation validation
.claude/tests/test_supervise_agent_delegation.sh

# Topic-based artifacts validation
.claude/tests/validate_topic_based_artifacts.sh

# SlashCommand anti-pattern detection
.claude/tests/validate_no_agent_slash_commands.sh
```

### Step 4: Prevent Recurrence

Follow [Prevention Guidelines](./agent-delegation-troubleshooting.md#prevention-guidelines) and use the [Code Review Checklist](./agent-delegation-troubleshooting.md#code-review-checklist).

## Related Documentation

- [Command Development Guide](../guides/command-development-guide.md) - Best practices for command creation
- [Agent Development Guide](../guides/agent-development-guide.md) - Creating agent behavioral files
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 11: Imperative Agent Invocation
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Complete pattern documentation
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture

## Archive

Files that have been consolidated are archived in [archive/troubleshooting/](../archive/troubleshooting/) with redirect READMEs.

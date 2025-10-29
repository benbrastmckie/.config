# Archived Troubleshooting Files

Files in this directory have been archived as part of the documentation consolidation (Spec 509).

## Redirects

All agent delegation troubleshooting content has been consolidated into a single unified guide.

**See**: [Agent Delegation Troubleshooting](../../troubleshooting/agent-delegation-troubleshooting.md)

### File Consolidations

The following files have been merged into the unified guide:

- `agent-delegation-failure.md` → [Issue C: Delegation Failure (0% Rate)](../../troubleshooting/agent-delegation-troubleshooting.md#issue-c-delegation-failure-0-rate)
- `agent-delegation-issues.md` → [Root Cause Analysis](../../troubleshooting/agent-delegation-troubleshooting.md#root-cause-analysis)
- `command-not-delegating-to-agents.md` → [Issue A: Command Executes Directly](../../troubleshooting/agent-delegation-troubleshooting.md#issue-a-command-executes-directly-no-delegation)

### What Changed

**Before** (3 separate files, 1,380 lines total):
- agent-delegation-failure.md - Root cause analysis for 0% delegation rates
- agent-delegation-issues.md - Common issues with agents (path mismatches, context bloat, recursion)
- command-not-delegating-to-agents.md - Commands executing directly without Task invocations

**After** (1 unified file, ~600 lines, 57% reduction):
- agent-delegation-troubleshooting.md - Complete guide with decision tree, all root causes, solutions, and prevention guidelines

### Benefits

- **Decision tree** at top for quick diagnosis
- **Unified symptom checking** across all delegation issues
- **Eliminated 85% content overlap** while preserving all unique content
- **Consistent troubleshooting workflow** across all issue types
- **Comprehensive prevention guidelines** in one location

### Migration Date

2025-10-28 (Spec 509, Phase 1)

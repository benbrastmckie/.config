# Legacy Workflow Commands Archive

## Overview

This archive contains 5 legacy workflow commands and their exclusive infrastructure that were superseded by the state-based orchestration architecture. These commands have been archived (not deleted) to preserve git history while cleaning up the active codebase.

**Archive Date**: 2025-11-17
**Related Spec**: 761_research_and_plan_the_archival_of_the_debug_md_imp

## Archived Contents

### Commands (5 files)
- `commands/debug.md` - Legacy debug workflow command
- `commands/implement.md` - Legacy implementation workflow command
- `commands/plan.md` - Legacy planning workflow command
- `commands/research.md` - Legacy research workflow command
- `commands/revise.md` - Legacy revision workflow command

### Agents (2 files)
- `agents/code-writer.md` - Code generation agent (exclusive to implement.md)
- `agents/implementation-executor.md` - Phase execution agent (exclusive to implement.md)

### Libraries (1 file)
- `lib/validate-plan.sh` - Plan validation utilities (exclusive to plan.md/implement.md)

### Documentation (5 files)
- `docs/debug-command-guide.md` - Debug command documentation
- `docs/implement-command-guide.md` - Implement command documentation
- `docs/plan-command-guide.md` - Plan command documentation
- `docs/research-command-guide.md` - Research command documentation
- `docs/revise-command-guide.md` - Revise command documentation

### Tests (4 files)
- `tests/test_auto_debug_integration.sh` - Debug workflow tests
- `tests/test_plan_command.sh` - Plan command tests
- `tests/test_adaptive_planning.sh` - Adaptive planning tests
- `tests/e2e_implement_plan_execution.sh` - Implementation e2e tests

## Why Archived

These commands were replaced by state-based orchestration workflows that provide:
- Better reliability through explicit state machines
- Improved parallel execution with wave-based dependencies
- Clearer separation of concerns
- More consistent error handling

The replacement commands are:
- `/build` - Replaces debug, implement, plan workflow
- `/debug` - Replaces debug-focused workflow (previously /fix)
- `/coordinate` - Replaces multi-agent orchestration
- `/plan` - Replaces research + plan workflow (previously /research-plan)
- `/revise` - Replaces research + revise workflow (previously /research-revise)
- `/research` - Replaces research-only workflow (previously /research-report)

## Recovery Procedures

All archived files remain accessible through git history. Use these git-based recovery methods:

### Restore Single File

```bash
# Find the commit before archival
git log --oneline -- .claude/commands/debug.md

# Restore specific file from commit before archival
git checkout HEAD~4 -- .claude/commands/debug.md
```

### Restore Multiple Files

```bash
# Restore all 5 commands from before archival
git checkout HEAD~4 -- \
  .claude/commands/debug.md \
  .claude/commands/implement.md \
  .claude/commands/plan.md \
  .claude/commands/research.md \
  .claude/commands/revise.md
```

### Restore All Archived Files

```bash
# Restore all commands, agents, and libs
git checkout HEAD~4 -- \
  .claude/commands/debug.md \
  .claude/commands/implement.md \
  .claude/commands/plan.md \
  .claude/commands/research.md \
  .claude/commands/revise.md \
  .claude/agents/code-writer.md \
  .claude/agents/implementation-executor.md \
  .claude/lib/validate-plan.sh

# Restore documentation
git checkout HEAD~4 -- \
  .claude/docs/guides/debug-command-guide.md \
  .claude/docs/guides/implement-command-guide.md \
  .claude/docs/guides/plan-command-guide.md \
  .claude/docs/guides/research-command-guide.md \
  .claude/docs/guides/revise-command-guide.md

# Restore tests
git checkout HEAD~4 -- \
  .claude/tests/test_auto_debug_integration.sh \
  .claude/tests/test_plan_command.sh \
  .claude/tests/test_adaptive_planning.sh \
  .claude/tests/e2e_implement_plan_execution.sh
```

### Full Rollback

```bash
# Revert all archival commits (4 commits for phases 2-5)
git revert HEAD~3..HEAD

# Or reset to pre-archival state (caution: discards later changes)
git reset --hard HEAD~4
```

## Notes

- The shared infrastructure (25+ agents, 15+ libraries) remains active in the main codebase
- These archived components were EXCLUSIVELY used by the 5 archived commands
- No other commands depend on these archived files
- Tests should continue to pass after archival (excluding the archived test files)

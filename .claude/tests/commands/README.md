# Command Tests

Tests for slash command functionality and error handling.

## Purpose

This directory contains tests that verify slash command behavior including task delegation, error recovery, input validation, and plan preservation. Tests ensure commands execute correctly and handle edge cases appropriately.

## Test Organization

Tests organized by command and feature:
- /build command task delegation
- /revise command error recovery and validation
- /revise input handling (small plans, long prompts)
- Plan preservation during revisions

## Running Tests

```bash
# Run all command tests
cd /home/benjamin/.config/.claude/tests/commands
for test in test_*.sh; do bash "$test"; done

# Run specific test
bash test_build_task_delegation.sh
```

## Files in This Directory

### test_build_task_delegation.sh
**Purpose**: Verify /build command task delegation to subagents
**Coverage**: Agent invocation, task coordination, completion signals
**Dependencies**: Sample plans in fixtures/

### test_revise_error_recovery.sh
**Purpose**: Verify /revise error handling and recovery
**Coverage**: Error detection, graceful degradation, error reporting
**Dependencies**: Invalid plan fixtures

### test_revise_long_prompt.sh
**Purpose**: Verify /revise handles long revision descriptions
**Coverage**: Prompt truncation, context management
**Dependencies**: None (generates long prompts)

### test_revise_preserve_completed.sh
**Purpose**: Verify /revise preserves completed phase markers
**Coverage**: Checkbox preservation, phase status retention
**Dependencies**: Plans with completed phases

### test_revise_small_plan.sh
**Purpose**: Verify /revise handles minimal plans correctly
**Coverage**: Small plan edge cases, minimal structure handling
**Dependencies**: Small plan fixtures

## Navigation

- [← Parent Directory](../README.md)
- [Related: agents/](../agents/README.md)

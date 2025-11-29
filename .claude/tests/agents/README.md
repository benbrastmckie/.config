# Agent Tests

Tests for agent behavioral compliance and revision capabilities.

## Purpose

This directory contains tests that verify agent behavioral specifications, agent invocation patterns, and specialized agent features like revision mode. Tests ensure agents comply with architectural standards and execute correctly within the agential system.

## Test Organization

Tests organized by agent feature area:
- Agent behavioral compliance tests
- Revision mode functionality tests
- Agent invocation pattern validation

## Running Tests

```bash
# Run all agent tests
cd /home/benjamin/.config/.claude/tests/agents
for test in test_*.sh; do bash "$test"; done

# Run specific test
bash test_plan_architect_revision_mode.sh
```

## Files in This Directory

### test_plan_architect_revision_mode.sh
**Purpose**: Verify plan-architect agent revision mode functionality
**Coverage**: Revision mode activation, plan analysis, revision suggestions
**Dependencies**: plan_architect_revision_fixtures/ directory

### plan_architect_revision_fixtures/
**Purpose**: Fixture directory for revision mode tests
**Coverage**: Sample plans for revision testing

## Navigation

- [← Parent Directory](../README.md)
- [Related: commands/](../commands/README.md)

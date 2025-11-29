# Plan Architect Revision Mode Test Fixtures

## Purpose

This directory contains test fixture plans for validating plan-architect agent's revision mode functionality.

## Test Fixtures

### 1. small_plan.md
- **Size**: 3 phases, ~100 lines
- **Status**: All phases [NOT STARTED]
- **Use Case**: Test basic revision operations (add/remove/modify phases)
- **Complexity**: 35.0 (below Tier 2 threshold)

### 2. medium_plan_with_completed.md
- **Size**: 6 phases, ~200 lines
- **Status**: Mixed (2 [COMPLETE], 1 [IN PROGRESS], 3 [NOT STARTED])
- **Use Case**: Test preservation of [COMPLETE] phases during revision
- **Complexity**: 125.0 (Tier 2 - moderate complexity)
- **Critical Test**: Verify plan-architect NEVER modifies Phase 1 or Phase 2 (both [COMPLETE])

### 3. large_plan.md
- **Size**: 12 phases, ~350 lines
- **Status**: All phases [NOT STARTED]
- **Use Case**: Test revision performance with large plans
- **Complexity**: 285.0 (Tier 3 - high complexity)
- **Test Focus**: Phase renumbering, dependency updates across many phases

## Test Scenarios

### Scenario 1: Basic Phase Modification
- **Fixture**: small_plan.md
- **Operation**: Modify Phase 2 tasks (add 2 new tasks)
- **Expected**: Only Phase 2 modified, other phases unchanged
- **Tool**: Edit (not Write)
- **Signal**: PLAN_REVISED

### Scenario 2: Completed Phase Preservation
- **Fixture**: medium_plan_with_completed.md
- **Operation**: Add new Phase 4, renumber subsequent phases
- **Expected**:
  - Phase 1 [COMPLETE] - unchanged
  - Phase 2 [COMPLETE] - unchanged
  - Phase 3 [IN PROGRESS] - unchanged
  - New Phase 4 inserted
  - Old Phase 4 → Phase 5, etc.
- **Tool**: Edit (not Write)
- **Signal**: PLAN_REVISED with "Completed Phases: 2"

### Scenario 3: Phase Split
- **Fixture**: small_plan.md
- **Operation**: Split Phase 2 into Phase 2 and Phase 3, renumber Phase 3 → Phase 4
- **Expected**:
  - Phase 1 unchanged
  - Phase 2 split into Phase 2 (first half) and Phase 3 (second half)
  - Old Phase 3 → Phase 4
  - Dependencies updated
- **Tool**: Edit (not Write)
- **Signal**: PLAN_REVISED

### Scenario 4: Large Plan Renumbering
- **Fixture**: large_plan.md
- **Operation**: Insert 3 new phases after Phase 6
- **Expected**:
  - Phases 1-6 unchanged
  - 3 new phases inserted (Phase 7, 8, 9)
  - Old Phases 7-12 → Phases 10-15
  - All dependencies updated correctly
- **Tool**: Edit (not Write)
- **Signal**: PLAN_REVISED

## Validation Checklist

For each test scenario, verify:

- [ ] plan-architect detects operation mode correctly (plan_revision)
- [ ] Agent uses Edit tool (not Write)
- [ ] [COMPLETE] phases preserved exactly (no changes)
- [ ] Requested revisions applied correctly
- [ ] Metadata updated (Date, Estimated Hours, Phase count)
- [ ] Phase numbering has no gaps or duplicates
- [ ] Dependencies updated correctly
- [ ] Returns PLAN_REVISED signal (not PLAN_CREATED)
- [ ] Metadata includes "Completed Phases" count (for fixtures with completed phases)

## Manual Testing

To manually test revision mode:

```bash
# Test basic revision (Scenario 1)
# In Claude Code chat, invoke plan-architect with:

Task {
  subagent_type: "general-purpose"
  prompt: |
    Read behavioral guidelines from: /home/benjamin/.config/.claude/agents/plan-architect.md

    OPERATION MODE: plan_revision

    EXISTING_PLAN_PATH: /home/benjamin/.config/.claude/tests/agents/plan_architect_revision_fixtures/small_plan.md
    BACKUP_PATH: /home/benjamin/.config/.claude/tests/agents/plan_architect_revision_fixtures/small_plan.md.backup

    Revision: Add 2 new tasks to Phase 2 (Login Implementation):
    - Add rate limiting to login endpoint
    - Add login attempt logging

    Use Edit tool. Preserve other phases. Return PLAN_REVISED signal.
}

# Verify:
# 1. Phase 2 has 5 tasks total (3 original + 2 new)
# 2. Phase 1 and Phase 3 unchanged
# 3. Metadata Date updated
# 4. Signal: PLAN_REVISED (not PLAN_CREATED)
```

## Automated Testing

Future: Create automated test suite:
- `.claude/tests/agents/test_plan_architect_revision_mode.sh`
- Run all 4 scenarios programmatically
- Validate results against expected outcomes
- Integrate with CI/CD pipeline

## Notes

- Test fixtures are gitignored (ephemeral test data)
- Backup files (.backup.*) created during tests should be cleaned up
- Test with both small and large plans to verify scalability
- Critical: Always verify [COMPLETE] phase preservation (Scenario 2)

## Navigation

- [← Parent Directory](../README.md)
- [Related: Agent Tests](../README.md)

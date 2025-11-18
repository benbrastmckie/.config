# Workflow Phases: Overview

**Related Documents**:
- [Research Phase](workflow-phases-research.md) - Parallel research execution
- [Planning Phase](workflow-phases-planning.md) - Plan creation
- [Implementation Phase](workflow-phases-implementation.md) - Code execution
- [Testing Phase](workflow-phases-testing.md) - Test execution
- [Documentation Phase](workflow-phases-documentation.md) - Documentation updates

---

## Purpose

This documentation covers all workflow phases in the /orchestrate and related commands, including detailed execution procedures, agent invocation patterns, and checkpoint management.

## Phase Summary

| Phase | Execution | Purpose | Agents |
|-------|-----------|---------|--------|
| Research | Parallel | Gather information | research-specialist (N) |
| Planning | Sequential | Create implementation plan | plan-architect |
| Implementation | Adaptive | Execute code changes | implementation-agent |
| Testing | Sequential | Validate changes | test-specialist |
| Documentation | Sequential | Update docs | doc-writer |

## Phase Flow

```
Research Phase (Parallel)
    |
    v
Planning Phase
    |
    v
Implementation Phase (Wave-based)
    |
    v
Testing Phase
    |
    v
Documentation Phase
```

## Phase Coordination

### When to Use Each Phase

**Research Phase**:
- Complex workflows requiring investigation
- Medium+ complexity (implement, redesign, architecture)
- Skip for simple tasks (fix, update single file)

**Planning Phase**:
- Always after research (if research performed)
- Creates structured implementation plan
- Determines parallel execution waves

**Implementation Phase**:
- Execute code changes per plan
- Wave-based parallel execution
- Run tests after each phase

**Testing Phase**:
- Comprehensive test suite
- Integration tests
- Verification of all changes

**Documentation Phase**:
- Update affected documentation
- Create workflow summary
- Update README files

### Phase Dependencies

```yaml
Research -> Planning -> Implementation -> Testing -> Documentation

Dependencies:
- Planning requires Research outputs
- Implementation requires Plan
- Testing requires Implementation complete
- Documentation requires Tests pass
```

## Checkpoint Management

### Checkpoint Structure

Each phase saves checkpoint data:

```json
{
  "workflow_id": "uuid",
  "current_phase": "research|planning|implementation|testing|documentation",
  "phase_data": {
    "research": {
      "reports": ["/path/to/report1.md", "/path/to/report2.md"],
      "thinking_mode": "think hard",
      "complexity_score": 8
    },
    "planning": {
      "plan_path": "/path/to/plan.md",
      "phase_count": 5,
      "wave_count": 3
    },
    "implementation": {
      "current_phase": 2,
      "completed_phases": ["Phase 1"],
      "current_wave": 1
    }
  },
  "state": "running|paused|completed|failed"
}
```

### Checkpoint Operations

```bash
# Save checkpoint
save_checkpoint "orchestrate" "$CHECKPOINT_DATA"

# Load checkpoint
CHECKPOINT=$(load_checkpoint "orchestrate")

# Update phase
update_checkpoint_phase "planning"
```

## Common Patterns

### Pre-Calculate Paths

All phases pre-calculate paths before execution:

```bash
TOPIC_DIR=$(get_or_create_topic_dir "$DESC" ".claude/specs")

REPORT_PATH="${TOPIC_DIR}/reports/001_research.md"
PLAN_PATH="${TOPIC_DIR}/plans/001_implementation.md"
SUMMARY_PATH="${TOPIC_DIR}/summaries/001_workflow.md"
```

### Agent Invocation

All phases use behavioral injection:

```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/[agent-name].md

    Context:
    - [field]: ${VALUE}
}
```

### Verification

All phases verify outputs:

```bash
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Missing output"
  exit 1
fi
```

## Quick Reference

### Phase Execution Order

1. **Research** (if needed): Parallel agents gather information
2. **Planning**: Create implementation plan
3. **Implementation**: Execute plan phases in waves
4. **Testing**: Run test suite
5. **Documentation**: Update docs

### Skip Conditions

- Skip Research: Simple tasks (fix, minor update)
- Skip Documentation: No user-facing changes

### Failure Handling

- Research: Proceed if >=50% reports complete
- Planning: Retry once, then fail
- Implementation: Pause at failing phase
- Testing: Report failures, don't proceed
- Documentation: Optional, can skip

---

## Related Documentation

- [Research Phase](workflow-phases-research.md)
- [Planning Phase](workflow-phases-planning.md)
- [Implementation Phase](workflow-phases-implementation.md)
- [Testing Phase](workflow-phases-testing.md)
- [Documentation Phase](workflow-phases-documentation.md)
- [Orchestration Guide](../workflows/orchestration-guide.md)

# Shared Command Documentation

## Purpose

This directory contains reusable documentation sections referenced by multiple commands. It follows the proven reference-based composition pattern from `agents/shared/`, which reduced agent files by 28% while maintaining clarity.

## Usage Pattern

Commands reference shared sections using relative markdown links:

```markdown
For detailed workflow phase descriptions, see [Workflow Phases](shared/workflow-phases.md).
```

When Claude processes a command, it automatically reads referenced files, making this pattern zero-overhead.

## Shared Sections

### High Priority (orchestrate.md)
- `workflow-phases.md` - Detailed phase descriptions (~800 lines)
- `error-recovery.md` - Error handling patterns (~400 lines)
- `context-management.md` - Context optimization guide (~300 lines)
- `agent-coordination.md` - Agent invocation patterns (~500 lines)
- `orchestrate-examples.md` - Usage examples (~400 lines)

### Medium Priority (implement.md, setup.md, revise.md)
- `adaptive-planning.md` - Adaptive planning guide (~200 lines)
- `progressive-structure.md` - L0->L1->L2 documentation (~150 lines)
- `phase-execution.md` - Phase execution protocol (~180 lines)
- `setup-modes.md` - Setup command modes (~300 lines)
- `bloat-detection.md` - Bloat detection algorithms (~150 lines)
- `extraction-strategies.md` - Extraction preferences (~100 lines)
- `revise-auto-mode.md` - Auto-mode specification (~250 lines)
- `revision-types.md` - Revision type descriptions (~250 lines)

### Low Priority (multiple commands)
- `error-handling.md` - Common error patterns
- `testing-patterns.md` - Testing protocols

## Cross-Reference Index

| Shared Section | Referenced By | Lines Saved |
|----------------|---------------|-------------|
| _(to be populated)_ | _(during extraction)_ | _(after extraction)_ |

## Maintenance

When adding new shared sections:
1. Extract focused, cohesive documentation (200-400 lines ideal)
2. Update this README with new section
3. Add cross-references to index
4. Validate all links with `test_command_references.sh`

## Related Patterns

- `.claude/agents/shared/` - Agent behavioral guidelines (28% reduction achieved)
- `.claude/lib/` - Bash utility functions (code extraction)
- `.claude/templates/` - Plan templates (composition without duplication)

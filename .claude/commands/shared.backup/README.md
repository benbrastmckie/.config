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
- `workflow-phases.md` - Detailed phase descriptions ✓
- `orchestrate-enhancements.md` - Complexity evaluation, expansion, wave-based patterns ✓
- `error-recovery.md` - Error handling patterns ✓
- `context-management.md` - Context optimization guide ✓
- `agent-coordination.md` - Agent invocation patterns ✓
- `orchestrate-examples.md` - Usage examples ✓

### Medium Priority (implement.md, setup.md, revise.md)
- `adaptive-planning.md` - Adaptive planning guide ✓
- `progressive-structure.md` - L0->L1->L2 documentation ✓
- `phase-execution.md` - Phase execution protocol ✓
- `setup-modes.md` - Setup command modes ✓
- `bloat-detection.md` - Bloat detection algorithms ✓
- `extraction-strategies.md` - Extraction preferences ✓
- `revise-auto-mode.md` - Auto-mode specification ✓
- `revision-types.md` - Revision type descriptions ✓
- `implementation-workflow.md` - Implementation patterns ✓
- `standards-analysis.md` - Standards analysis patterns ✓

### Low Priority (multiple commands)
- `error-handling.md` - Common error patterns ✓
- `testing-patterns.md` - Testing protocols ✓

### Template Reference Files (migrated from .claude/templates/)
- `agent-invocation-patterns.md` - Agent coordination patterns
- `agent-tool-descriptions.md` - Tool usage documentation
- `audit-checklist.md` - Command quality checklist
- `command-frontmatter.md` - Command metadata structure
- `debug-structure.md` - Debug report structure
- `orchestration-patterns.md` - Orchestration workflow patterns
- `output-patterns.md` - Command output formatting
- `readme-template.md` - Directory README template
- `refactor-structure.md` - Refactor report structure
- `report-structure.md` - Research report structure

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

## Navigation

- [← Parent Directory](../README.md)
- [agents/shared/](../../agents/shared/) - Agent behavioral guidelines
- [lib/](../../lib/) - Bash utility functions
- [templates/](../templates/) - Plan templates (YAML)

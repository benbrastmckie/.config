# Research Report: Task #10

**Task**: Replace 'context: fork' with explicit context file references in SKILL.md files
**Date**: 2026-01-10
**Focus**: General research

## Summary

The project has 8 SKILL.md files using `context: fork` in their frontmatter. This is a placeholder value with no functional meaning - the context system has ~70 well-organized context files in `.claude/context/` that should be explicitly referenced instead. Each skill has distinct context needs based on its purpose (orchestration, research, planning, implementation, git, status sync, neovim-specific).

## Findings

### Files Using `context: fork`

All 8 skills in `.claude/skills/` use the placeholder:

1. **skill-orchestrator** - Central routing for task operations
2. **skill-researcher** - General-purpose research agent
3. **skill-planner** - Implementation plan creator
4. **skill-implementer** - General implementation executor
5. **skill-neovim-research** - Neovim/Lua research specialist
6. **skill-neovim-implementation** - Neovim/Lua implementation with TDD
7. **skill-git-workflow** - Git commit creation
8. **skill-status-sync** - Task status synchronization

### Context Directory Organization

The `.claude/context/` directory has a well-organized structure:

```
context/
├── index.md                 # Quick-reference map for context loading
├── README.md                # Directory organization guide
├── core/                    # Reusable patterns (41 files)
│   ├── orchestration/       # Routing, delegation, state (11 files)
│   ├── formats/             # Output formats (7 files)
│   ├── standards/           # Quality standards (10 files)
│   ├── workflows/           # Workflow patterns (5 files)
│   └── templates/           # Reusable templates (5 files)
└── project/                 # Project-specific context
    ├── neovim/              # Neovim/Lua domain (17 files)
    ├── meta/                # Meta-builder context (6 files)
    ├── processes/           # Development workflows (3 files)
    └── repo/                # Repository-specific (2 files)
```

### Context Loading Strategy (from index.md)

The system has a three-tier loading strategy:

1. **Tier 1: Orchestrator** (<5% context window)
   - `orchestration/routing.md`, `orchestration/delegation.md`

2. **Tier 2: Commands** (10-20% context window)
   - `formats/subagent-return.md`, `workflows/status-transitions.md`

3. **Tier 3: Skills** (60-80% context window)
   - `project/neovim/*`, `project/meta/*`

### Skill-to-Context Mapping Analysis

Based on each skill's responsibilities:

| Skill | Recommended Context Files |
|-------|--------------------------|
| skill-orchestrator | `core/orchestration/routing.md`, `core/orchestration/delegation.md`, `core/orchestration/state-lookup.md` |
| skill-researcher | `core/formats/report-format.md`, `core/standards/documentation.md`, `core/workflows/status-transitions.md` |
| skill-planner | `core/formats/plan-format.md`, `core/standards/task-management.md`, `core/workflows/status-transitions.md` |
| skill-implementer | `core/standards/code-patterns.md`, `core/formats/summary-format.md`, `core/standards/git-integration.md` |
| skill-neovim-research | `project/neovim/domain/neovim-api.md`, `project/neovim/domain/lua-patterns.md`, `project/neovim/domain/plugin-ecosystem.md` |
| skill-neovim-implementation | `project/neovim/standards/lua-style-guide.md`, `project/neovim/standards/testing-standards.md`, `project/neovim/patterns/plugin-definition.md` |
| skill-git-workflow | `core/standards/git-safety.md`, `core/standards/git-integration.md` |
| skill-status-sync | `core/orchestration/state-management.md`, `core/standards/status-markers.md` |

### Current Template Issue

The skill-template.md shows:
- Line 18: `context: fork` (template default)
- Line 118: Documents `context` as "Context handling mode" with `fork` as example
- No definition of what `fork` actually means or does

### Related Documentation Mentions

Also found `context: fork` in:
- `.claude/docs/guides/creating-skills.md` - Multiple examples with `fork`
- `.claude/docs/templates/README.md` - Template reference
- `.claude/docs/skills/README.md` - Skills documentation
- `.claude/ARCHITECTURE.md` - Architecture document

## Recommendations

1. **Define explicit context files per skill**: Replace `context: fork` with an array of specific context file paths (e.g., `context: [core/orchestration/routing.md, core/standards/git-safety.md]`)

2. **Keep context minimal**: Each skill should only load context it actually needs to minimize context window usage

3. **Document the context field**: Update skill-template.md to explain the context field format and provide examples

4. **Consider conditional loading**: Some skills (neovim-specific) could use language-based context loading

5. **Update all 8 SKILL.md files**: Each needs tailored context references

## References

- `.claude/context/index.md` - Context loading index
- `.claude/context/README.md` - Context directory organization
- `.claude/docs/templates/skill-template.md` - Skill template
- `.claude/ARCHITECTURE.md` - Architecture documentation
- All 8 SKILL.md files in `.claude/skills/*/`

## Next Steps

1. Define the syntax for explicit context references in frontmatter
2. Create context mapping for each skill based on responsibilities
3. Update all 8 SKILL.md files with explicit context references
4. Update skill-template.md with new context format
5. Update related documentation (creating-skills.md, skills/README.md)

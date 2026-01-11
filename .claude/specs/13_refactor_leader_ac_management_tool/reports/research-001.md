# Research Report: Task #13

**Task**: Refactor leader-ac management tool
**Date**: 2026-01-11
**Focus**: Alignment with refactored .claude/ agent system

## Summary

The `<leader>ac` management tool is a Telescope-based picker for browsing and managing Claude Code artifacts (commands, agents, hooks, TTS files, etc.). The current implementation is functional but has grown organically with goose.nvim legacy code and overly complex sync operations. The refactored .claude/ system now uses a skills-based architecture that the picker should align with.

## Current Architecture

### File Structure (9 modules, ~2,800 lines)

```
nvim/lua/neotex/plugins/ai/claude/commands/
├── picker.lua                    # Main orchestration (272 lines)
├── parser.lua                    # Artifact parsing (795 lines)
└── picker/
    ├── init.lua                  # Picker creation/mappings (272 lines)
    ├── display/
    │   ├── entries.lua           # Entry formatting (730 lines)
    │   └── previewer.lua         # Preview generation (646 lines)
    ├── operations/
    │   ├── sync.lua              # Load All / sync operations (1161 lines - LARGEST)
    │   ├── edit.lua              # File editing operations (~150 lines)
    │   └── terminal.lua          # Terminal command execution (~100 lines)
    ├── artifacts/
    │   ├── metadata.lua          # Metadata parsing (~100 lines)
    │   └── registry.lua          # Artifact registry (~100 lines)
    └── utils/
        ├── scan.lua              # Directory scanning (197 lines)
        └── helpers.lua           # Utility functions (~100 lines)
```

### Entry Point

The picker is invoked via:
- `<leader>ac` (normal mode) - mapped to `:ClaudeCommands`
- `<leader>ac` (visual mode) - sends selection to Claude with prompt
- `:ClaudeCommands` user command

### Key Observations

1. **Goose Legacy**: sync.lua contains extensive goose.nvim sync code that is now deprecated (marked in comments) but not removed. This is 1,161 lines of mostly dead code.

2. **No Agents Directory**: The `.claude/agents/` directory doesn't exist in the current system - agents are now defined via skills in `.claude/skills/`.

3. **Parser Complexity**: parser.lua scans for agents in `.claude/agents/` which doesn't exist. The agent parsing infrastructure is ~200 lines of unused code.

4. **Artifact Types Now Present**:
   - Commands: `.claude/commands/*.md` (9 files)
   - Skills: `.claude/skills/*/SKILL.md` (8 skills)
   - Docs: `.claude/docs/**/*.md`
   - Hooks: `.claude/hooks/*.sh`
   - Rules: `.claude/rules/*.md`
   - Context: `.claude/context/**/*.md`

5. **Skills Architecture**: The new system uses skills (SKILL.md files) instead of separate agents. Skills have:
   - Frontmatter: name, description, allowed-tools, context
   - Context file references for loading relevant documentation
   - Invoked via Claude's Skill tool

## Identified Issues

### 1. Dead Code (High Priority)
- sync.lua: ~1,000 lines of goose sync code marked deprecated
- parser.lua: Agent scanning for non-existent directory
- entries.lua: Standalone agents section that will never have content

### 2. Missing Skill Support
- No skill discovery/display in picker
- Skills are the new "agents" but not represented

### 3. Complexity Mismatch
- Parser builds complex hierarchy for commands with nested agents
- Current system has flat command structure with no agent dependencies
- build_agent_dependencies() returns empty results

### 4. Sync Operations
- "Load All" functionality syncs artifacts between global/project
- Useful but overly complex with 5 different strategies
- Could be simplified to 2: "Sync New" and "Sync All (Replace)"

## Recommendations

### 1. Remove Dead Code
- Remove goose.nvim sync infrastructure from sync.lua
- Remove agent scanning from parser.lua
- Simplify entries.lua by removing standalone agents section

### 2. Add Skills Support
- Add skill discovery to parser.lua
- Display skills in picker under [Skills] section
- Enable skill file editing via Enter/Ctrl-e

### 3. Simplify Architecture
- Remove agent_dependencies infrastructure
- Flatten command hierarchy (no nested dependents needed)
- Reduce sync strategies from 5 to 2

### 4. Update Categories
Display order should be:
1. [Commands] - Slash commands
2. [Skills] - SKILL.md files
3. [Hooks] - Event-triggered scripts
4. [Docs] - Integration guides
5. [Lib] - Utility libraries
6. [Scripts] - Standalone CLI tools
7. [Tests] - Test suites

Remove: [Agents], [TTS Files] (TTS integrated into hooks)

### 5. Clean Up Keymaps
Current mappings are functional but documentation is stale:
- Ctrl-l: Load locally (keep)
- Ctrl-u: Update from global (keep)
- Ctrl-s: Save to global (keep)
- Ctrl-e: Edit file (keep)
- Ctrl-n: Create new command (keep)
- Ctrl-r: Run script (keep)
- Ctrl-t: Run test (keep)

## Effort Estimate

| Component | Lines to Remove | Lines to Add | Complexity |
|-----------|----------------|--------------|------------|
| sync.lua cleanup | ~800 | 0 | Low |
| parser.lua skill support | ~200 | ~100 | Medium |
| entries.lua simplification | ~150 | ~50 | Low |
| previewer.lua skill preview | 0 | ~40 | Low |
| **Total** | ~1,150 | ~190 | Low-Medium |

Net reduction: ~960 lines

## References

- .claude/skills/skill-orchestrator/SKILL.md - Example skill structure
- .claude/commands/*.md - Current command definitions
- nvim/lua/neotex/plugins/ai/claude/README.md - Module documentation

## Next Steps

1. Create implementation plan with phased approach
2. Phase 1: Remove dead code (sync.lua, agent scanning)
3. Phase 2: Add skill support
4. Phase 3: Simplify entries and previewer
5. Phase 4: Test all operations

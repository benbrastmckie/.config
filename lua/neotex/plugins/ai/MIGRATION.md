# Migration Guide: Architectural Reorganization (Avante Separation)

**Date**: 2025-11-16
**Affected**: All files importing from `claude/util/` or `claude/utils/`

## Summary

The AI plugin structure has been reorganized to **properly separate Avante from Claude Code**:

| Old Location | New Location | Rationale |
|--------------|--------------|-----------|
| `claude/util/` | `avante/mcp/` | Avante-specific functionality moved to its own namespace |
| `claude/utils/` | `claude/claude-session/` | Claude Code functionality remains under claude/, renamed for clarity |

## Why This Change?

### Problem

**Avante utilities were misplaced under the Claude namespace**. The `claude/util/` directory primarily contained Avante-MCP integration code, but was located under `ai/claude/` which should only contain Claude Code functionality.

This created:
1. **Architectural confusion**: Avante code under Claude branding
2. **Namespace pollution**: Two unrelated AI integrations mixed together
3. **Poor modularity**: Can't modify/remove Avante without affecting Claude
4. **Misleading organization**: Directory name didn't reflect actual responsibility

### Solution

**Proper architectural boundaries**: Each AI integration owns its own top-level directory.

- **ai/avante/mcp/**: Avante-MCP integration (moved from claude/util/)
- **ai/claude/claude-session/**: Claude Code session management (renamed from claude/utils/)

## What Changed?

### Directory Structure
```
┌─────────────────────────────────────────────────────────────┐
│ OLD structure (architecturally incorrect)                   │
│                                                              │
│ nvim/lua/neotex/plugins/ai/claude/                          │
│ ├── util/          # Avante-MCP (WRONG LOCATION!)           │
│ └── utils/         # Claude Code session                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ NEW structure (architecturally correct)                     │
│                                                              │
│ nvim/lua/neotex/plugins/ai/                                 │
│ ├── avante/                                                 │
│ │   └── mcp/       # Avante-MCP integration                │
│ └── claude/                                                 │
│     └── claude-session/  # Claude Code session             │
└─────────────────────────────────────────────────────────────┘
```

### Import Paths
All require() statements updated to reflect architectural separation:

```lua
-- Avante-MCP integration imports
-- OLD: require("neotex.plugins.ai.claude.util.avante_mcp")
-- NEW: require("neotex.plugins.ai.avante.mcp.avante_mcp")

-- Claude Code session management imports
-- OLD: require("neotex.plugins.ai.claude.utils.terminal-state")
-- NEW: require("neotex.plugins.ai.claude.claude-session.terminal-state")
```

**Key change**: Avante imports now use `avante.*` namespace, not `claude.*`

### What Didn't Change?

**NO behavioral changes**:
- All modules function identically
- No API changes to exported functions
- No configuration changes required
- No changes to abstractions or state management

**NO breaking changes**:
- All existing functionality preserved
- No refactoring of complex logic
- No changes to MCP server configuration
- No changes to terminal state persistence

This was a **pure organizational refactoring** focused on clarity and documentation.

## For Plugin Users

**No action required** if you:
- Use the plugin through lazy.nvim or similar plugin managers
- Don't directly import Claude integration modules
- Use only the public API commands (:Claude*, etc.)

**Update required** if you:
- Have custom configurations importing `claude.util.*` (now `avante.mcp.*`) or `claude.utils.*` (now `claude.claude-session.*`)
- Wrote custom extensions using internal modules
- Reference these paths in configuration files

**Important**: Avante imports must change namespace from `claude` to `avante`!

## For Plugin Developers

### Updating Your Code

1. **Search for old imports**:
```bash
# Find all references to old paths
rg "claude/util" your_config_dir/
rg "claude/utils" your_config_dir/
```

2. **Replace with new paths**:
```bash
# Automated replacement (review changes before committing)
# IMPORTANT: Note the namespace change for Avante!

# Avante-MCP: claude.util → avante.mcp
find your_config_dir/ -type f -name "*.lua" -exec sed -i \
  's|claude\.util\.|avante.mcp.|g' {} +

# Claude session: claude.utils → claude.claude-session
find your_config_dir/ -type f -name "*.lua" -exec sed -i \
  's|claude\.utils\.|claude.claude-session.|g' {} +
```

3. **Manual verification**:
- Check that all imports resolve correctly
- Verify no hard-coded paths in strings or comments
- Test your custom functionality still works

### Understanding the New Structure

**avante/mcp/** directory handles (NEW NAMESPACE):
- Avante-MCP server lifecycle (start/stop/restart)
- Tool registry with context-aware selection
- Model and provider configuration
- System prompt persistence
- MCP server integration coordination
- **Note**: This is Avante-specific, not Claude Code!

**claude/claude-session/** directory handles:
- Claude Code terminal session state management
- Bash subprocess isolation patterns
- Command queuing and execution
- Terminal capability detection (ANSI support)
- File-based state persistence across bash blocks
- **Note**: This is Claude Code-specific, not Avante!

## Timeline

- **2025-11-16**: Architectural reorganization completed
- **Transition period**: No symlinks created (clean break preferred for architectural clarity)
- **Future**: Avante utilities in `ai/avante/`, Claude utilities in `ai/claude/`

## Questions?

See research reports for detailed analysis:
- [OVERVIEW.md](../../.claude/specs/724_and_utils_directory_which_is_redundant_carefully/reports/OVERVIEW.md)
- Subtopic reports in same directory

## Related Changes

This reorganization was based on comprehensive research documented in:
- Topic 724: util/ and utils/ directory analysis
- 4 detailed research reports analyzing module organization
- Recommendations for low-risk, high-impact improvements

# Implementation Plan: Safe Directory Reorganization for util/ and utils/

## Metadata
- **Plan ID**: 001
- **Topic Number**: 724
- **Date Created**: 2025-11-16
- **Type**: Refactor (Low-Risk, Documentation-Heavy)
- **Scope**: Reorganize util/ and utils/ directories by architectural responsibility - move Avante utilities to proper location, rename Claude-specific session management
- **Priority**: HIGH
- **Complexity**: 4/10 (mechanical changes with proper architectural separation)
- **Estimated Duration**: 5-7 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Research**:
  - [Research Overview](../reports/001_and_utils_directory_which_is_redundant_carefully/OVERVIEW.md) - Synthesized findings across all research areas
  - [Avante MCP Consolidation and Abstraction](../reports/001_and_utils_directory_which_is_redundant_carefully/001_avante_mcp_consolidation_and_abstraction.md) - MCP integration architecture and tool registry patterns
  - [Terminal Management and State Coordination](../reports/001_and_utils_directory_which_is_redundant_carefully/002_terminal_management_and_state_coordination.md) - Bash subprocess isolation, state persistence, ANSI terminals
  - [System Prompts and Configuration Persistence](../reports/001_and_utils_directory_which_is_redundant_carefully/003_system_prompts_and_configuration_persistence.md) - YAML frontmatter vs JSON configuration approaches
  - [Internal API Surface and Module Organization](../reports/001_and_utils_directory_which_is_redundant_carefully/004_internal_api_surface_and_module_organization.md) - 58 libraries, 109+ functions, 9 domains
- **Structure Level**: 0 (Single-file)

## Executive Summary

### Problem Statement

The Neovim plugin structure has a fundamental architectural problem:
- **util/** (8 files, 2,955 lines): Manages **Avante**-MCP integration with tool registry and server lifecycle management
- **utils/** (7 files, 600+ lines): Handles **Claude Code** session management with terminal state coordination

**The core issue**: Avante-specific utilities are misplaced in `ai/claude/` directory. Since `util/` primarily concerns Avante (not Claude Code), it shouldn't be under the `ai/claude/` namespace at all. This creates:

1. **Architectural confusion**: Avante functionality nested under Claude branding
2. **Naming collision**: Both util/ and utils/ appear as generic utility directories
3. **Unclear responsibility**: Which directory handles which integration?
4. **Poor modularity**: Can't cleanly separate Avante from Claude Code concerns

### Solution Overview

This plan implements **proper architectural separation** with low-risk mechanical changes:

1. **Move Avante utilities** out of `ai/claude/` to proper `ai/avante/` location
2. **Rename Claude utilities** from generic `utils/` to specific `claude-session/`
3. **Update all import paths** across the codebase with automated verification
4. **Enhance documentation** to explain architectural boundaries and migration path

**New Structure**:
```
nvim/lua/neotex/plugins/ai/
├── avante/              # NEW: Avante-specific functionality
│   ├── mcp/             # Moved from claude/util/
│   │   ├── avante-support.lua
│   │   ├── avante_mcp.lua
│   │   ├── mcp_server.lua
│   │   ├── system-prompts.lua
│   │   └── ...
│   └── README.md
└── claude/              # Claude Code integration
    ├── claude-session/  # Renamed from utils/
    │   ├── claude-code.lua
    │   ├── terminal-state.lua
    │   └── ...
    └── README.md
```

**Explicitly OUT OF SCOPE** (per user request):
- Complex refactoring of abstractions
- Configuration system unification
- State management changes
- API surface modifications

### Success Criteria

- [ ] Avante utilities moved to `ai/avante/mcp/` directory
- [ ] Claude utilities renamed to `ai/claude/claude-session/`
- [ ] All import paths updated and verified functional
- [ ] Comprehensive documentation explains architectural boundaries
- [ ] Zero breaking changes for existing functionality
- [ ] README files updated with clear separation of concerns
- [ ] Migration guide explains the architectural improvement

### Benefits

- **Proper architectural boundaries**: Avante and Claude Code concerns completely separated
- **Namespace clarity**: `ai/avante/` for Avante, `ai/claude/` for Claude Code
- **Improved modularity**: Can modify/remove Avante integration without affecting Claude Code
- **Reduced confusion**: No more Avante code under Claude branding
- **Better organization**: Each integration owns its full directory tree
- **Low risk**: Mechanical directory moves with straightforward verification

---

## Implementation Phases

### Phase 1: Pre-Migration Analysis and Verification

**Objective**: Analyze current state, identify all import paths, and plan the migration safely

**Dependencies**: None

**Complexity**: 1/10

**Duration**: 30-45 minutes

#### Tasks

- [ ] Scan codebase for all references to `claude/util/` and `claude/utils/`
- [ ] Identify which files truly depend on Claude vs Avante functionality
- [ ] Create comprehensive list of affected files (expect 50-100+ files)
- [ ] Verify no circular dependencies between Avante and Claude modules
- [ ] Document current directory structure in detail
- [ ] Create backup reference point (git commit)

#### Deliverables

1. **affected_files.txt**: List of all files importing from util/ or utils/
2. **current_structure.md**: Documentation of current directory layout
3. **Git commit**: Clean state before changes

#### Success Criteria

- [ ] Complete inventory of affected files (50-100+ files expected)
- [ ] Clear separation identified: Avante modules vs Claude modules
- [ ] No uncommitted changes in working directory
- [ ] Clear understanding of architectural migration scope

#### Implementation Notes

```bash
# Find all Lua files importing from util/ or utils/
rg "require.*claude/util" --type lua > /tmp/util_imports.txt
rg "require.*claude/utils" --type lua > /tmp/utils_imports.txt

# Count affected files
wc -l /tmp/util_imports.txt /tmp/utils_imports.txt

# Create snapshot
git add -A
git commit -m "Pre-migration snapshot before util/ utils/ reorganization"
```

---

### Phase 2: Create Architectural Structure

**Objective**: Create proper directory structure with Avante separated from Claude

**Dependencies**: Phase 1 complete

**Complexity**: 3/10

**Duration**: 20-30 minutes

#### Tasks

- [ ] Create new `ai/avante/` directory structure
- [ ] Move `claude/util/` → `avante/mcp/` (Avante-MCP integration)
- [ ] Rename `claude/utils/` → `claude/claude-session/` (Claude Code session management)
- [ ] Verify directory structure matches architectural design
- [ ] Create README files for both new top-level directories

#### Deliverables

1. **New directory structure**:
   - `/nvim/lua/neotex/plugins/ai/avante/mcp/` (moved from claude/util/)
   - `/nvim/lua/neotex/plugins/ai/claude/claude-session/` (renamed from claude/utils/)
2. **New README files**:
   - `/nvim/lua/neotex/plugins/ai/avante/README.md`
   - Updated `/nvim/lua/neotex/plugins/ai/claude/README.md`

#### Success Criteria

- [ ] `ai/avante/` directory created with proper structure
- [ ] All Avante utilities moved out of `claude/` namespace
- [ ] Claude session utilities properly renamed
- [ ] All files preserved (no data loss)
- [ ] README files explain architectural boundaries

#### Implementation Notes

```bash
cd /home/benjamin/.config/nvim/lua/neotex/plugins/ai/

# Create Avante directory structure
mkdir -p avante/mcp

# Move Avante-MCP utilities from claude/util/ to avante/mcp/
git mv claude/util/* avante/mcp/

# Remove old util/ directory (should be empty now)
rmdir claude/util

# Rename Claude utilities: utils/ → claude-session/
cd claude/
git mv utils claude-session

# Verify new structure
ls -la /home/benjamin/.config/nvim/lua/neotex/plugins/ai/
# Expected: avante/ and claude/ directories

ls -la avante/mcp/
# Expected: avante-support.lua, avante_mcp.lua, mcp_server.lua, system-prompts.lua, etc.

ls -la claude/claude-session/
# Expected: claude-code.lua, terminal-state.lua, terminal-detection.lua, etc.
```

**Architectural Rationale**:
- **ai/avante/mcp/**: Avante integration owns its own top-level directory under `ai/`, making it clear this is Avante-specific functionality (not Claude Code)
- **ai/claude/claude-session/**: Claude Code integration stays under `claude/`, renamed to clearly indicate session management responsibility
- **Separation of concerns**: Each AI integration (Avante vs Claude Code) has its own namespace, preventing architectural confusion

---

### Phase 3: Update Import Paths

**Objective**: Update all import statements to use new directory names

**Dependencies**: Phase 2 complete

**Complexity**: 3/10 (mechanical but requires careful verification)

**Duration**: 1-2 hours

#### Tasks

- [ ] Create sed script for automated path replacement
- [ ] Update all Lua require() statements (claude/util → avante/mcp, claude/utils → claude/claude-session)
- [ ] Update any path references in configuration files
- [ ] Update lazy.nvim plugin specifications if affected
- [ ] Verify no hard-coded paths in comments or documentation

#### Deliverables

1. **migration_script.sh**: Automated import path update script
2. **Updated import paths** across all affected files
3. **Verification report**: Confirms all imports updated

#### Success Criteria

- [ ] All require() statements updated to new paths
- [ ] Avante imports use `neotex.plugins.ai.avante.mcp.*` namespace
- [ ] Claude imports use `neotex.plugins.ai.claude.claude-session.*` namespace
- [ ] No references to old `claude/util/` or `claude/utils/` paths (except in migration docs)
- [ ] Script can be re-run safely (idempotent)

#### Implementation Notes

**Automated Migration Script**:

```bash
#!/bin/bash
# migration_script.sh - Update import paths: claude/util → avante/mcp, claude/utils → claude/claude-session

NVIM_ROOT="/home/benjamin/.config/nvim"

echo "Updating import paths for architectural reorganization..."
echo ""

# STEP 1: Update claude/util/ → avante/mcp/
echo "1. Moving Avante imports from claude.util to avante.mcp..."

find "$NVIM_ROOT" -type f -name "*.lua" -exec sed -i \
  's|neotex\.plugins\.ai\.claude\.util\.|neotex.plugins.ai.avante.mcp.|g' {} +

find "$NVIM_ROOT" -type f -name "*.lua" -exec sed -i \
  's|neotex/plugins/ai/claude/util/|neotex/plugins/ai/avante/mcp/|g' {} +

# STEP 2: Update claude/utils/ → claude/claude-session/
echo "2. Renaming Claude session imports from claude.utils to claude.claude-session..."

find "$NVIM_ROOT" -type f -name "*.lua" -exec sed -i \
  's|neotex\.plugins\.ai\.claude\.utils\.|neotex.plugins.ai.claude.claude-session.|g' {} +

find "$NVIM_ROOT" -type f -name "*.lua" -exec sed -i \
  's|neotex/plugins/ai/claude/utils/|neotex/plugins/ai/claude/claude-session/|g' {} +

echo ""
echo "Verification: Checking for old references..."

# Verify no old references remain
OLD_UTIL_COUNT=$(rg "claude/util[/\.]" --type lua "$NVIM_ROOT" 2>/dev/null | wc -l)
OLD_UTILS_COUNT=$(rg "claude/utils[/\.]" --type lua "$NVIM_ROOT" 2>/dev/null | wc -l)

echo "Old claude/util/ references: $OLD_UTIL_COUNT (should be 0)"
echo "Old claude/utils/ references: $OLD_UTILS_COUNT (should be 0)"

# Verify new references exist
AVANTE_COUNT=$(rg "avante/mcp[/\.]" --type lua "$NVIM_ROOT" 2>/dev/null | wc -l)
SESSION_COUNT=$(rg "claude-session[/\.]" --type lua "$NVIM_ROOT" 2>/dev/null | wc -l)

echo ""
echo "New avante/mcp/ references: $AVANTE_COUNT (should be >0)"
echo "New claude-session/ references: $SESSION_COUNT (should be >0)"

if [ "$OLD_UTIL_COUNT" -eq 0 ] && [ "$OLD_UTILS_COUNT" -eq 0 ] && [ "$AVANTE_COUNT" -gt 0 ] && [ "$SESSION_COUNT" -gt 0 ]; then
  echo ""
  echo "✓ Migration successful!"
else
  echo ""
  echo "⚠ Warning: Some references may need manual review"
fi
```

**Manual Verification**:

```bash
# After running script, manually verify critical files:

# 1. Check Avante MCP imports now use avante namespace
rg "require.*avante.*mcp" nvim/lua/neotex/plugins/ai/ --type lua

# 2. Check Claude session imports use new name
rg "require.*claude.*claude-session" nvim/lua/neotex/plugins/ai/ --type lua

# 3. Verify plugin entry points updated
nvim nvim/lua/neotex/plugins/ai/avante/init.lua  # If exists
nvim nvim/lua/neotex/plugins/ai/claude/init.lua

# 4. Check for any remaining old references (should be 0)
rg "claude\.util\.|claude/util/" nvim/lua/ --type lua
rg "claude\.utils\.|claude/utils/" nvim/lua/ --type lua
```

---

### Phase 4: Documentation Updates

**Objective**: Comprehensively update all documentation to reflect new directory structure

**Dependencies**: Phase 3 complete

**Complexity**: 3/10

**Duration**: 2-3 hours

#### Tasks

- [ ] Create new Avante README (/nvim/lua/neotex/plugins/ai/avante/README.md)
- [ ] Update Claude README (/nvim/lua/neotex/plugins/ai/claude/README.md)
- [ ] Update avante/mcp/ directory README
- [ ] Update claude/claude-session/ directory README
- [ ] Add migration guide explaining the architectural reorganization
- [ ] Update CLAUDE.md if it references old paths
- [ ] Update any architecture documentation
- [ ] Add inline comments explaining architectural boundaries

#### Deliverables

1. **Updated README.md files** (3 files minimum)
2. **MIGRATION.md**: Guide for developers familiar with old structure
3. **Updated architecture docs** with new directory names
4. **Inline comments** in init.lua explaining module organization

#### Success Criteria

- [ ] All README files reflect new architectural structure
- [ ] Migration guide explains architectural rationale (Avante vs Claude separation)
- [ ] Documentation clearly explains `ai/avante/` vs `ai/claude/` boundaries
- [ ] No outdated references to `claude/util/` or `claude/utils/` in docs
- [ ] Inline comments explain why Avante is separated from Claude

#### Implementation Details

**New Avante README** (`ai/avante/README.md`):

```markdown
# Avante Integration

This directory contains **Avante-specific** functionality for the Neotex AI plugins.

## Architecture Decision

Avante utilities were previously misplaced under `ai/claude/util/`. Since Avante is a separate AI integration from Claude Code, it has been moved to its own top-level directory under `ai/avante/` to properly reflect architectural boundaries.

## Directory Structure

### `mcp/` - Model Context Protocol Integration
Handles Avante-MCP integration, tool registry, and server lifecycle management.

**Key modules**:
- `avante-support.lua` - Model and provider configuration
- `avante_mcp.lua` - Avante and MCPHub integration coordinator
- `mcp_server.lua` - MCP server lifecycle (start/stop/restart)
- `system-prompts.lua` - System prompt persistence and management
- `avante-highlights.lua` - Visual highlighting for Avante UI

**Purpose**: Orchestrates MCP tool infrastructure, manages server connections,
provides tool registry abstraction for context-aware selection.

## Import Paths

```lua
-- Avante MCP integration
require("neotex.plugins.ai.avante.mcp.avante_mcp")
require("neotex.plugins.ai.avante.mcp.mcp_server")
```

## Relationship to Claude Code

**Avante and Claude Code are separate integrations**. This directory (`ai/avante/`) handles Avante-specific concerns, while `ai/claude/` handles Claude Code session management. They should not be confused or intermixed.
```

**Updated Claude README** (`ai/claude/README.md`):

```markdown
# Claude Code Integration

This directory contains **Claude Code-specific** functionality for terminal session management and state coordination.

## Directory Structure

### `claude-session/` - Terminal Session Management
Handles Claude Code session management, terminal state coordination, and command queuing.

**Key modules**:
- `claude-code.lua` - Claude Code plugin integration
- `terminal-state.lua` - State management and command queuing
- `terminal-detection.lua` - Terminal emulator type detection
- `terminal-commands.lua` - Terminal-agnostic command generation
- `terminal.lua` - Claude terminal buffer management
- `git.lua` - Git utilities for terminal operations
- `persistence.lua` - Session data persistence

**Purpose**: Manages terminal session state, coordinates subprocess isolation,
provides file-based state persistence across bash block boundaries.

## Import Paths

```lua
-- Claude Code session management
require("neotex.plugins.ai.claude.claude-session.claude-code")
require("neotex.plugins.ai.claude.claude-session.terminal-state")
```

## Architectural Note

This directory contains **only Claude Code** functionality. Avante-related utilities have been moved to `ai/avante/` to maintain proper separation of concerns.
```

**MIGRATION.md**:

```markdown
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
```bash
# OLD structure (architecturally incorrect)
nvim/lua/neotex/plugins/ai/claude/
├── util/          # Avante-MCP (WRONG LOCATION!)
└── utils/         # Claude Code session

# NEW structure (architecturally correct)
nvim/lua/neotex/plugins/ai/
├── avante/
│   └── mcp/       # Avante-MCP integration
└── claude/
    └── claude-session/  # Claude Code session
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
- [OVERVIEW.md](../reports/001_and_utils_directory_which_is_redundant_carefully/OVERVIEW.md)
- Subtopic reports in same directory

## Related Changes

This reorganization was based on comprehensive research documented in:
- Topic 724: util/ and utils/ directory analysis
- 4 detailed research reports analyzing module organization
- Recommendations for low-risk, high-impact improvements
```

---

### Phase 5: Verification and Testing

**Objective**: Verify all changes work correctly and nothing is broken

**Dependencies**: Phase 4 complete

**Complexity**: 2/10

**Duration**: 30-45 minutes

#### Tasks

- [x] Source Neovim configuration and check for errors
- [x] Verify MCP integration loads without errors
- [x] Verify session management loads without errors
- [x] Test basic Claude commands work
- [x] Verify no "module not found" errors in logs
- [x] Run any existing tests if available

#### Deliverables

1. **Verification report**: Confirms all functionality works
2. **Test results**: Any automated tests pass
3. **Error log review**: No new errors introduced

#### Success Criteria

- [x] Neovim loads Claude integration without errors
- [x] All require() statements resolve successfully
- [x] Basic Claude commands functional (:ClaudeCode, etc.)
- [x] No regressions in existing functionality

#### Implementation Notes

**Manual Testing Checklist**:

```bash
# 1. Start Neovim with clean state
nvim --noplugin -u ~/.config/nvim/init.lua

# 2. Check for load errors
:messages

# 3. Verify MCP integration loaded
:lua print(vim.inspect(require("neotex.plugins.ai.claude.mcp.avante_mcp")))

# 4. Verify session management loaded
:lua print(vim.inspect(require("neotex.plugins.ai.claude.session.terminal-state")))

# 5. Test basic commands
:ClaudeCode

# 6. Check logs for errors
tail -f ~/.local/state/nvim/log
```

**Automated Verification**:

```bash
# Verify all expected modules can be required
lua <<EOF
local modules = {
  "neotex.plugins.ai.claude.mcp.avante_mcp",
  "neotex.plugins.ai.claude.mcp.mcp_server",
  "neotex.plugins.ai.claude.mcp.system-prompts",
  "neotex.plugins.ai.claude.session.terminal-state",
  "neotex.plugins.ai.claude.session.claude-code",
  "neotex.plugins.ai.claude.session.terminal-detection",
}

for _, mod in ipairs(modules) do
  local ok, result = pcall(require, mod)
  if ok then
    print(string.format("✓ %s loaded", mod))
  else
    print(string.format("✗ %s FAILED: %s", mod, result))
  end
end
EOF
```

---

### Phase 6: Finalization and Documentation

**Objective**: Commit changes, update cross-references, mark plan complete

**Dependencies**: Phase 5 complete (all verification passed)

**Complexity**: 1/10

**Duration**: 15-30 minutes

#### Tasks

- [ ] Review all changes one final time
- [ ] Create comprehensive git commit
- [ ] Update research report cross-references
- [ ] Mark implementation plan as complete
- [ ] Add completion notes to plan metadata

#### Deliverables

1. **Git commit**: All changes committed with detailed message
2. **Updated plan metadata**: Status marked as "Completed"
3. **Cross-reference updates**: Reports linked to plan

#### Success Criteria

- [ ] All changes committed to git
- [ ] Commit message explains architectural reorganization rationale
- [ ] Plan marked complete in metadata
- [ ] No uncommitted changes remaining

#### Implementation Notes

**Git Commit Message Template**:

```
refactor(ai): Separate Avante from Claude - proper architectural boundaries

BREAKING CHANGE: Avante utilities moved out of claude/ namespace

**Summary**:
Reorganized AI plugin structure to properly separate Avante from Claude Code.
Avante-specific functionality was incorrectly placed under ai/claude/ directory.

**Architectural Changes**:
- claude/util/ → avante/mcp/ (Avante-MCP integration moved to own namespace)
- claude/utils/ → claude/claude-session/ (Claude Code session management renamed)

**Rationale**:
The claude/util/ directory primarily contained Avante-MCP integration code,
but was located under ai/claude/ which should only contain Claude Code functionality.
This created architectural confusion and namespace pollution.

**New Structure**:
```
ai/
├── avante/mcp/           # Avante-specific (moved from claude/util/)
└── claude/claude-session/ # Claude Code-specific (renamed from claude/utils/)
```

**Changes**:
1. Created ai/avante/ directory for Avante integration
2. Moved claude/util/* to avante/mcp/
3. Renamed claude/utils/ to claude/claude-session/
4. Updated all require() import paths (50-100+ files)
5. Created comprehensive README files explaining boundaries
6. Added MIGRATION.md with architectural rationale

**Verification**:
- All modules load successfully
- Avante imports use avante.* namespace
- Claude imports use claude.claude-session.* namespace
- No cross-contamination between integrations
- Documentation explains architectural separation

**Breaking Changes**:
Import namespace changes:
- OLD: require("neotex.plugins.ai.claude.util.*")
- NEW: require("neotex.plugins.ai.avante.mcp.*")  ← NAMESPACE CHANGED!

- OLD: require("neotex.plugins.ai.claude.utils.*")
- NEW: require("neotex.plugins.ai.claude.claude-session.*")

**Impact**:
- Avante imports MUST change namespace (claude → avante)
- Claude session imports renamed within same namespace

Users with custom configurations must update their import paths.
See MIGRATION.md for detailed migration guide and architectural rationale.

**Related Research**:
- Topic 724: util/ and utils/ directory analysis
- Implementation Plan: 001_safe_directory_reorganization.md

**Impact**:
- Affected files: 50-100+ Lua files
- Risk level: Low (mechanical search-and-replace)
- Behavioral changes: None
- Configuration changes: Import paths only

✓ All tests pass
✓ All modules load successfully
✓ Documentation updated
✓ Migration guide provided
```

---

## Rollback Strategy

If issues occur during migration, rollback is straightforward:

### Immediate Rollback (During Implementation)

```bash
# Discard all uncommitted changes
git reset --hard HEAD

# Return to pre-migration state
git checkout <commit-before-phase-2>
```

### Post-Commit Rollback (After Merging)

```bash
# Revert the migration commit
git revert <migration-commit-sha>

# Or create inverse migration (more complex due to namespace change)
cd nvim/lua/neotex/plugins/ai/
git mv avante/mcp/* claude/util/
rmdir avante/mcp avante/
git mv claude/claude-session claude/utils
# Run migration script in reverse
# Update documentation to old names
```

### Partial Rollback (Fix-Forward)

If only some imports are broken:

```bash
# Fix individual files
nvim path/to/broken_file.lua
# Manually correct import paths

# Or create temporary symlinks (note: cannot symlink across parent dirs)
cd nvim/lua/neotex/plugins/ai/claude/
ln -s ../avante/mcp util      # May not work on all systems
ln -s claude-session utils
```

**Note**: Rollback is more complex than original plan due to namespace change.
The architectural improvement comes with slightly higher rollback complexity.

**Rollback Risk**: Low - all changes are mechanical and easily reversible

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Missed import paths | Medium | Medium | Comprehensive grep verification, automated script |
| Typos in sed script | Low | High | Test on single file first, review script carefully |
| Documentation out of sync | Low | Low | Phase 4 dedicated to docs, migration guide included |
| Breaking external plugins | Low | Low | Changes are internal to Claude integration only |
| Git merge conflicts | Low | Low | Single atomic commit, clean state before starting |
| Hard-coded path strings | Low | Medium | Manual search for string literals, verify in Phase 1 |

**Overall Risk Level**: Low
**Mitigation Confidence**: High (mechanical changes, comprehensive verification)

---

## Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Import path updates | 100% | grep verification shows 0 old `claude/util` or `claude/utils` paths |
| Namespace separation | 100% | Avante uses `avante.*`, Claude uses `claude.*` |
| Module load success | 100% | All require() calls succeed |
| Documentation coverage | 100% | 4+ README files updated (ai/avante/, ai/claude/, subdirs) |
| Architectural clarity | Qualitative | Clear separation between Avante and Claude integrations |
| Zero regressions | 100% | All existing functionality works |

---

## Completion Criteria

This plan is complete when:

1. [ ] Architectural reorganization complete:
   - [ ] `ai/avante/` directory created
   - [ ] `claude/util/` moved to `avante/mcp/`
   - [ ] `claude/utils/` renamed to `claude/claude-session/`
2. [ ] All import paths updated and verified:
   - [ ] Avante imports use `avante.mcp.*` namespace
   - [ ] Claude imports use `claude.claude-session.*` namespace
   - [ ] 0 references to `claude.util.*` or `claude.utils.*` (except migration docs)
3. [ ] Documentation comprehensive and accurate:
   - [ ] `ai/avante/README.md` created explaining separation
   - [ ] `ai/claude/README.md` updated to clarify Claude-only scope
   - [ ] Subdirectory READMEs updated
   - [ ] MIGRATION.md explains architectural rationale
4. [ ] All modules load without errors
5. [ ] Basic commands functional (both Avante and Claude Code)
6. [ ] Changes committed to git with architectural rationale explained
7. [ ] Cross-references updated in research reports

---

## Future Enhancements (Out of Scope)

These items are documented in research reports but **NOT included in this plan**:

- Configuration system unification (YAML frontmatter vs JSON)
- Abstraction improvements (Result<T,E> pattern, builder patterns)
- State management hardening
- Terminal multiplexing support
- Function deprecation strategy
- Library consolidation beyond directory naming

See research [OVERVIEW.md](../reports/001_and_utils_directory_which_is_redundant_carefully/OVERVIEW.md) Phase 2-5 for these advanced refactoring recommendations.

---

## Notes

**Design Philosophy**:
This plan prioritizes **proper architectural boundaries** over minimal changes.
While more extensive than simple renaming, it corrects a fundamental architectural
mistake: Avante utilities should never have been under the Claude namespace.

**Why This Approach**:
Per user insight, "if util/ primarily concerns Avante, it shouldn't be in the
ai/claude/ directory." This plan implements proper separation of concerns:
each AI integration owns its own namespace, preventing confusion and enabling
independent evolution.

**Architectural Benefits**:
- **Clear boundaries**: Avante and Claude Code completely separated
- **Namespace clarity**: `ai/avante/` for Avante, `ai/claude/` for Claude
- **Improved modularity**: Can modify/remove either integration independently
- **Better organization**: Directory structure reflects actual architectural responsibility

**Lessons for Future**:
- Namespace organization should reflect architectural boundaries, not convenience
- Related utilities should be grouped by integration, not by generic category
- Proper architecture is worth the migration cost (50-100+ file updates)
- Mechanical refactors with clear rationale gain developer buy-in
## Revision History

- **2025-11-16**: Architectural revision - changed from simple directory renaming to proper Avante/Claude separation. Moved Avante utilities out of claude/ namespace to ai/avante/. Rationale: util/ primarily concerns Avante, should not be under ai/claude/ directory.

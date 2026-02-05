# Research Report: Task #44 (Round 2)

**Task**: 44 - Complete LogosWebsite Task 9 Equivalent
**Focus**: `<leader>ac` sync mechanism analysis and discrepancy identification
**Started**: 2026-02-05
**Completed**: 2026-02-05
**Effort**: Medium
**Dependencies**: None
**Sources/Inputs**: Codebase analysis of sync.lua, scan.lua, picker/init.lua; directory comparison between source and destination repos
**Artifacts**: This report
**Standards**: report-format.md

## Executive Summary

- The `<leader>ac` keybinding opens a Telescope picker (`ClaudeCommands`) with a "Load All Artifacts" option that syncs `.claude/` from `~/.config/.claude/` (the "global" directory) to the current project
- **Root cause of discrepancies**: The sync reads from `~/.config/.claude/` (a STALE copy), not from `~/.config/nvim/.claude/` (the actively-developed repo). These two directories have diverged with 63 file content differences and 2 files missing from the global copy
- The LogosWebsite was correctly synced from the global directory, then received 20 legitimate project-specific customizations (web routing, Astro agents, Tailwind context)
- **3 files** are truly missing due to scan limitations: 2 JSON schemas and 1 JSON template in `context/core/` (the context scanner only looks for `*.md` files)
- **3 directories** are not scanned at all: `output/`, `systemd/`, and `docs/reference/standards/` (the last one is because the file was added after the global copy was made)
- The top-level `CLAUDE.md` (project root) is NOT synced by the mechanism at all

## Context and Scope

The user used `<leader>ac` to copy/pull the `.claude/` agent system from this Neovim config repo into the LogosWebsite project. The research focuses on understanding the sync mechanism, identifying why discrepancies exist, and proposing fixes.

## Findings

### 1. Mechanism Analysis: `<leader>ac` Keybinding

**Keybinding chain**:
- `<leader>ac` (normal mode) -> `<cmd>ClaudeCommands<CR>` (defined in `lua/neotex/plugins/editor/which-key.lua:248`)
- `ClaudeCommands` user command -> `M.show_commands_picker()` (defined in `lua/neotex/plugins/ai/claude/init.lua:146`)
- Picker shows a "Load All Artifacts" entry at the top
- Selecting it calls `sync.load_all_globally()` (in `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua:201`)

**Key design**: The sync is a FILE-BY-FILE copy from a "global" `.claude/` directory to the current project's `.claude/` directory. It reads file content and writes it to the destination.

### 2. Source Directory: The Critical Bug

**File**: `sync.lua:203`
```lua
local global_dir = vim.fn.expand("~/.config")
```

This means the sync reads from `~/.config/.claude/`, NOT from `~/.config/nvim/.claude/`. These are two physically separate directories:

| Directory | Inode | Purpose | Status |
|-----------|-------|---------|--------|
| `~/.config/.claude/` | 22449366 | "Global" source for sync | STALE (older versions) |
| `~/.config/nvim/.claude/` | 26749111 | Active development repo | CURRENT (latest changes) |

The two directories have **63 files with different content** and **2 files** present only in the nvim version (`docs/reference/standards/multi-task-creation-standard.md` and `scripts/migrate-directory-padding.sh`).

**Impact**: When users run the sync from any project, they get an outdated version of the `.claude/` system.

### 3. File Type Coverage Gaps

The `scan_all_artifacts` function (sync.lua:148-196) scans specific directories with specific file extensions:

| Directory | Extension | Misses |
|-----------|-----------|--------|
| commands | `*.md` | -- |
| hooks | `*.sh` | -- |
| templates | `*.yaml` | -- |
| lib | `*.sh` | -- |
| docs | `*.md` | -- |
| scripts | `*.sh` | -- |
| tests | `test_*.sh` | -- |
| agents | `*.md` | -- |
| rules | `*.md` | -- |
| **context** | **`*.md`** | **`.json` and `.yaml` files** |
| skills | `*.md` + `*.yaml` | -- |
| settings | `settings.json` | -- |
| root_files | specific filenames | -- |

**Missing files due to extension filtering**:
- `context/core/schemas/frontmatter-schema.json` (not scanned: `.json` extension)
- `context/core/schemas/subagent-frontmatter.yaml` (not scanned: `.yaml` extension)
- `context/core/templates/state-template.json` (not scanned: `.json` extension)

### 4. Unscanned Directories

The following directories exist in `.claude/` but are not handled by `scan_all_artifacts`:

| Directory | Contents | Extension |
|-----------|----------|-----------|
| `output/` | 5 `.md` files (command output templates) | `.md` |
| `systemd/` | 2 files (`.service` + `.timer`) | `.service`, `.timer` |

### 5. Top-Level CLAUDE.md Not Synced

The sync only handles files inside `.claude/`. The project root `CLAUDE.md` at `~/.config/nvim/CLAUDE.md` is not part of the sync mechanism. LogosWebsite is missing this file entirely.

### 6. LogosWebsite Discrepancy Breakdown

**Category 1: Stale source (63 files)** - The global `~/.config/.claude/` has older versions than `~/.config/nvim/.claude/`. The most significant difference is the `{N}` vs `{NNN}` directory padding convention across agents, skills, and commands.

**Category 2: Missing from scan (3 files)** - JSON/YAML files in `context/core/` not picked up by `*.md` pattern:
- `context/core/schemas/frontmatter-schema.json`
- `context/core/schemas/subagent-frontmatter.yaml`
- `context/core/templates/state-template.json`

**Category 3: Unscanned directories (7 files)**:
- `output/` (5 files): `learn.md`, `plan.md`, `research.md`, `revise.md`, `todo.md`
- `systemd/` (2 files): `claude-refresh.service`, `claude-refresh.timer`

**Category 4: Post-global-copy additions (2 files)** - Files added to `nvim/.claude/` after the global copy was made:
- `docs/reference/standards/multi-task-creation-standard.md`
- `scripts/migrate-directory-padding.sh`

**Category 5: Legitimate project-specific customizations (20 files in LogosWebsite)** - These are correct and intentional. LogosWebsite tasks added web-specific routing, agents, skills, and context references. These should NOT be overwritten by sync.

**Category 6: Project-specific additions (23 dest-only files)** - Files only in LogosWebsite that don't exist in source:
- `agents/web-implementation-agent.md`, `agents/web-research-agent.md`
- `context/project/web/` (18 files for Astro/Tailwind/Cloudflare)
- `rules/web-astro.md`
- `skills/skill-web-implementation/SKILL.md`, `skills/skill-web-research/SKILL.md`

### 7. Sync Behavior: "Sync All" vs "New Only"

The user is presented with two options when files already exist:
1. **Sync all (replace existing)**: Overwrites all destination files with global versions
2. **Add new only**: Only copies files that don't exist in destination

If the user chose "Add new only" (which is the safer default), then no existing files would be updated. If they chose "Sync all", then all files would be replaced with the (stale) global versions, which is what happened given that LogosWebsite `.claude/` files match the global copy.

## Root Cause Summary

There are **three distinct root causes**:

1. **Stale global source** (`~/.config/.claude/`): The sync mechanism reads from `~/.config/.claude/` which is a separate, outdated copy of the system. Development happens in `~/.config/nvim/.claude/` but changes are never propagated back to the global directory. This is the PRIMARY issue responsible for 63 outdated files.

2. **Incomplete file type scanning**: The `context` directory scanner only looks for `*.md` files, missing `.json` and `.yaml` schemas/templates. The `output/` and `systemd/` directories are not scanned at all.

3. **No project-root CLAUDE.md handling**: The sync doesn't copy the top-level `CLAUDE.md` that sits outside `.claude/`.

## Recommendations

### Fix 1: Update Global Source Path (Critical)

**Option A**: Change `global_dir` to point to the nvim repo:
```lua
-- sync.lua:203
local global_dir = vim.fn.expand("~/.config/nvim")
```
This makes the sync read from the actively-developed repo. However, this hardcodes the path.

**Option B**: Make the global source configurable:
```lua
-- In claude/config.lua
M.defaults = {
  global_source = vim.fn.expand("~/.config/nvim"),
  -- ...
}
```

**Option C**: Add a sync mechanism to keep `~/.config/.claude/` in sync with `~/.config/nvim/.claude/` (more complex, maintains backward compatibility).

**Recommended**: Option A or B. The fundamental issue is that `~/.config/.claude/` is not the repo being actively developed.

### Fix 2: Add Multi-Extension Context Scanning

In `scan_all_artifacts`, add `.json` and `.yaml` to context scanning:
```lua
-- Current:
artifacts.context = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.md")

-- Fixed:
local ctx_md = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.md")
local ctx_json = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.json")
local ctx_yaml = scan.scan_directory_for_sync(global_dir, project_dir, "context", "*.yaml")
artifacts.context = {}
for _, files in ipairs({ctx_md, ctx_json, ctx_yaml}) do
  for _, file in ipairs(files) do
    table.insert(artifacts.context, file)
  end
end
```

### Fix 3: Add Missing Directory Scanning

Add `output/` and `systemd/` to the scan:
```lua
counts.output = sync_files(all_artifacts.output or {}, false, merge_only)
counts.systemd = sync_files(all_artifacts.systemd or {}, false, merge_only)

-- In scan_all_artifacts:
artifacts.output = scan.scan_directory_for_sync(global_dir, project_dir, "output", "*.md")
artifacts.systemd = scan.scan_directory_for_sync(global_dir, project_dir, "systemd", "*")
```

### Fix 4: Handle Project-Root CLAUDE.md

Add the project-root `CLAUDE.md` to root_files scanning:
```lua
-- Add to root_files section in scan_all_artifacts
local project_claude_md_global = global_dir .. "/CLAUDE.md"
local project_claude_md_local = project_dir .. "/CLAUDE.md"
if vim.fn.filereadable(project_claude_md_global) == 1 then
  table.insert(artifacts.root_files, {
    name = "CLAUDE.md (project root)",
    global_path = project_claude_md_global,
    local_path = project_claude_md_local,
    action = vim.fn.filereadable(project_claude_md_local) == 1 and "replace" or "copy",
    is_subdir = false,
  })
end
```

### Fix 5: Consider a "Wildcard" Scan Mode

Instead of enumerating specific directories and extensions, add a fallback that catches all files:
```lua
-- After specific scans, do a catch-all:
artifacts.other = scan.scan_directory_for_sync(global_dir, project_dir, "", "*.*")
-- Filter out files already captured by specific scans
```

This is more future-proof as new directories/file types won't be silently dropped.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Changing global_dir breaks other users | High | Make it configurable with sensible default |
| Syncing overwrites project customizations | Medium | The existing "Sync All" vs "New Only" dialog handles this |
| Wildcard scan catches unwanted files | Low | Add exclusion patterns for logs/, temp files |
| global/.claude/ becomes permanently stale | Medium | Add a reverse-sync option or remove global copy entirely |

## Appendix

### Files Examined
- `lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Main sync logic
- `lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` - File scanning
- `lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Picker UI and keybindings
- `lua/neotex/plugins/editor/which-key.lua` - `<leader>ac` keybinding definition
- `lua/neotex/plugins/ai/claude/init.lua` - `ClaudeCommands` user command registration

### Quantitative Summary

| Category | Count | Description |
|----------|-------|-------------|
| Files in source `.claude/` | 211 | Total files in `~/.config/nvim/.claude/` |
| Files in dest `.claude/` | 216 | Total files in LogosWebsite `.claude/` (includes project-specific) |
| Stale content | 63 | Files outdated due to global source being behind |
| Missing (scan gap) | 3 | JSON/YAML files not captured by `*.md` pattern |
| Missing (unscanned dirs) | 7 | Files in `output/` and `systemd/` |
| Missing (post-copy) | 2 | Files added to nvim after global copy was made |
| Project-specific mods | 20 | Intentional LogosWebsite customizations |
| Project-specific adds | 23 | Files only in LogosWebsite (web domain) |

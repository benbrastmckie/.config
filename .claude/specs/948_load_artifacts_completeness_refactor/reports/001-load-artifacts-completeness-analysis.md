# Load All Artifacts Completeness Analysis

## Executive Summary

The "Load All Artifacts" feature in the Neovim claude-code.nvim plugin (invoked via `<leader>ac`) only copies **top-level files** from each artifact directory, missing all **subdirectory contents** and the **skills/** directory entirely. This results in incomplete artifact synchronization where critical infrastructure (49 lib files, 238 docs files, skills directory) is not copied.

**Root Cause**: The `scan_directory_for_sync()` function uses a flat glob pattern (`dir/*.ext`) that does not recursively scan subdirectories.

**Impact**: Projects that use "Load All Artifacts" receive only 10-15% of the required infrastructure, causing missing dependencies, broken references, and non-functional workflows.

## Research Findings

### 1. Implementation Analysis

**Location**: `/home/benjamin/.local/share/nvim/lazy/claude-code.nvim` (Neovim plugin repository, not user configuration)

**Entry Point**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- Function: `M.load_all_globally()` (lines 149-356)
- Invoked when user selects `[Load All Artifacts]` from picker menu

**Core Scanning Logic**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`
- Function: `M.scan_directory_for_sync()` (lines 37-57)
- Uses: `vim.fn.glob(global_path .. "/" .. extension, false, true)`
- Problem: Flat glob pattern only matches top-level files

**Artifact Types Scanned** (sync.lua lines 160-173):
```lua
local commands = scan.scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
local agents = scan.scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
local hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")
local scripts = scan.scan_directory_for_sync(global_dir, project_dir, "scripts", "*.sh")
local tests = scan.scan_directory_for_sync(global_dir, project_dir, "tests", "test_*.sh")
local lib_utils = scan.scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh")
local docs = scan.scan_directory_for_sync(global_dir, project_dir, "docs", "*.md")
```

**Subdirectories Scanned** (sync.lua lines 167-186):
```lua
local tts_hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh")
local tts_files = scan.scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh")
local agents_prompts = scan.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md")
local agents_shared = scan.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md")
local standards = scan.scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md")
```

**Directory Creation** (sync.lua lines 76-91):
```lua
helpers.ensure_directory(project_dir .. "/.claude/commands")
helpers.ensure_directory(project_dir .. "/.claude/agents")
helpers.ensure_directory(project_dir .. "/.claude/agents/prompts")
helpers.ensure_directory(project_dir .. "/.claude/agents/shared")
helpers.ensure_directory(project_dir .. "/.claude/hooks")
helpers.ensure_directory(project_dir .. "/.claude/tts")
helpers.ensure_directory(project_dir .. "/.claude/templates")
helpers.ensure_directory(project_dir .. "/.claude/lib")
helpers.ensure_directory(project_dir .. "/.claude/docs")
helpers.ensure_directory(project_dir .. "/.claude/scripts")
helpers.ensure_directory(project_dir .. "/.claude/tests")
helpers.ensure_directory(project_dir .. "/.claude/specs/standards")
helpers.ensure_directory(project_dir .. "/.claude/data/commands")
helpers.ensure_directory(project_dir .. "/.claude/data/agents")
helpers.ensure_directory(project_dir .. "/.claude/data/templates")
helpers.ensure_directory(project_dir .. "/.claude")
```

### 2. Comparison Analysis

**Source**: `/home/benjamin/.config/.claude/`
**Destination**: `/home/benjamin/Documents/Philosophy/TODO/.claude/`

#### Top-Level Directory Comparison

| Directory | Source | Destination | Status |
|-----------|--------|-------------|--------|
| agents/ | Present | Present | PARTIAL (subdirs copied, files incomplete) |
| commands/ | Present | Present | OK (flat structure) |
| data/ | Present | Present | EMPTY (no subdirs copied) |
| docs/ | Present | Present | CRITICAL FAILURE (1 of 238 files) |
| hooks/ | Present | Present | PARTIAL (top-level only) |
| lib/ | Present | Present | CRITICAL FAILURE (0 of 49 files) |
| logs/ | Present | MISSING | Not scanned |
| output/ | Present | MISSING | Not scanned |
| scripts/ | Present | Present | PARTIAL (no subdirs) |
| skills/ | Present | MISSING | NOT SCANNED |
| specs/ | Present | Present | EMPTY (standards subdir created but empty) |
| tests/ | Present | Present | PARTIAL (test_*.sh only, no subdirs) |
| tmp/ | Present | MISSING | Not scanned |
| tts/ | Present | Present | OK (flat structure) |
| templates/ | MISSING in source | Present in dest | Unknown origin |

#### Critical Missing Components

**lib/ Directory** (CRITICAL):
- Source: 49 shell script files in 10 subdirectories
  - `lib/artifact/` - Artifact management utilities
  - `lib/convert/` - Document conversion utilities
  - `lib/core/` - Core infrastructure (error-handling.sh, state-persistence.sh, workflow-state-machine.sh)
  - `lib/plan/` - Plan management utilities
  - `lib/util/` - General utilities
  - `lib/workflow/` - Workflow orchestration
- Destination: 0 files (only README.md)
- Impact: All commands fail due to missing library dependencies

**docs/ Directory** (CRITICAL):
- Source: 238 markdown files in 7 subdirectories
  - `docs/architecture/` - System architecture documentation
  - `docs/concepts/` - Core concepts and patterns
  - `docs/guides/` - User guides and tutorials
  - `docs/reference/` - Reference documentation
  - `docs/troubleshooting/` - Troubleshooting guides
  - `docs/workflows/` - Workflow documentation
  - `docs/archive/` - Archived documentation
- Destination: 1 file (README.md only)
- Impact: No documentation accessible in project

**skills/ Directory** (MISSING):
- Source: Present with `document-converter/` skill
  - `skills/README.md` - Skills documentation
  - `skills/document-converter/` - Document conversion skill
- Destination: Not created at all
- Impact: Skills functionality completely unavailable

**tests/ Directory** (PARTIAL):
- Source: 100+ test files in 11 subdirectories
  - `tests/classification/`
  - `tests/features/`
  - `tests/integration/`
  - `tests/progressive/`
  - `tests/state/`
  - `tests/topic-naming/`
  - `tests/unit/`
  - `tests/utilities/`
  - `tests/fixtures/`
  - `tests/lib/`
  - `tests/logs/`
- Destination: Only top-level `test_*.sh` files (0 files since none exist at top level)
- Impact: Cannot run test suite

**scripts/ Directory** (PARTIAL):
- Source: Contains `scripts/lint/` subdirectory with validation scripts
- Destination: Top-level scripts only, no `lint/` subdirectory
- Impact: Missing validation and linting infrastructure

**data/ Directory** (EMPTY):
- Source: Contains runtime data subdirectories
- Destination: Empty subdirectories created but no READMEs copied
- Impact: Missing runtime documentation

### 3. Root Cause Analysis

**Primary Issue**: Flat glob pattern in `scan_directory_for_sync()`

The function at scan.lua:40 uses:
```lua
local global_files = vim.fn.glob(global_path .. "/" .. extension, false, true)
```

This pattern only matches files directly in `global_path/`, not in subdirectories.

**Secondary Issues**:

1. **Hard-coded subdirectory list**: Only specific subdirectories are scanned (agents/prompts, agents/shared, specs/standards), but this approach:
   - Requires maintaining a manual list
   - Misses new subdirectories added to source
   - Does not scale to multi-level directory structures

2. **Missing artifact types**: The scanning logic does not include:
   - `skills/` directory (not in artifact type list)
   - `logs/`, `output/`, `tmp/` directories (runtime directories, but may contain useful data)
   - Deeper nested structures (e.g., `lib/core/`, `docs/architecture/`)

3. **Incomplete directory creation**: While `ensure_directory()` creates some subdirectories (sync.lua:76-91), it:
   - Only creates known subdirectories (agents/prompts, agents/shared, specs/standards)
   - Does not recursively create subdirectories discovered during scanning
   - Misses subdirectories like lib/core/, docs/architecture/, etc.

4. **Pattern mismatch for tests**: Tests scan uses `test_*.sh` pattern (sync.lua:164), which only matches:
   - Files starting with `test_` at top level
   - Misses test files in subdirectories (classification/, features/, integration/, etc.)

### 4. Impact Assessment

**Severity**: CRITICAL

**Affected Workflows**:
- All slash commands fail due to missing lib/ dependencies
- Documentation unavailable (docs/ nearly empty)
- Skills functionality missing (skills/ not copied)
- Test infrastructure incomplete (tests/ subdirs missing)
- Validation infrastructure missing (scripts/lint/ not copied)

**User Experience**:
- User receives success message: "Synced N artifacts"
- All commands fail with "Cannot load library" errors
- No indication that sync was incomplete
- User must manually copy missing files or understand infrastructure requirements

**Data Loss Risk**: LOW (operation is copy-only, does not delete source files)

**Workaround Complexity**: HIGH (requires manual recursive copy of 6+ directories)

## Refactor Plan

### Goals

1. **Completeness**: Copy all artifacts including subdirectory contents
2. **Maintainability**: Eliminate hard-coded subdirectory lists
3. **Transparency**: Report what was copied with accurate counts
4. **Performance**: Efficient recursive scanning and copying
5. **Standards Compliance**: Follow .claude/docs/ development standards

### Proposed Solution

**Option A: Recursive Glob Pattern** (RECOMMENDED)

Modify `scan_directory_for_sync()` to use recursive glob pattern:

```lua
function M.scan_directory_for_sync(global_dir, local_dir, subdir, extension)
  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = local_dir .. "/.claude/" .. subdir

  -- Use ** for recursive globbing
  local global_files = vim.fn.glob(global_path .. "/**/" .. extension, false, true)

  local files = {}
  for _, global_file in ipairs(global_files) do
    -- Get relative path from global_path
    local rel_path = global_file:sub(#global_path + 2) -- +2 to skip leading /
    local local_file = local_path .. "/" .. rel_path

    local action = vim.fn.filereadable(local_file) == 1 and "replace" or "copy"
    table.insert(files, {
      name = rel_path,
      global_path = global_file,
      local_path = local_file,
      action = action,
      is_subdir = rel_path:match("/") ~= nil, -- Track if file is in subdirectory
    })
  end

  return files
end
```

**Benefits**:
- Single pattern matches all files recursively
- No hard-coded subdirectory list
- Scales to arbitrary directory depth
- Minimal code changes

**Risks**:
- May include unwanted files (tmp/, logs/, etc.)
- Glob pattern support varies by Neovim version

**Option B: Recursive Directory Walker**

Create new function that walks directory tree:

```lua
function M.scan_directory_recursive(dir, extension)
  local files = {}
  local function walk(path, base_path)
    local entries = vim.fn.readdir(path)
    for _, entry in ipairs(entries) do
      local full_path = path .. "/" .. entry
      local stat = vim.loop.fs_stat(full_path)
      if stat.type == "directory" then
        walk(full_path, base_path)
      elseif stat.type == "file" and entry:match(extension:gsub("*", ".*")) then
        local rel_path = full_path:sub(#base_path + 2)
        table.insert(files, {
          name = rel_path,
          filepath = full_path,
        })
      end
    end
  end
  walk(dir, dir)
  return files
end
```

**Benefits**:
- Full control over traversal
- Can filter directories (skip tmp/, logs/, etc.)
- Works consistently across Neovim versions

**Risks**:
- More complex implementation
- Requires careful handling of symlinks
- Performance considerations for large directories

### Recommended Approach: Hybrid Solution

**Phase 1: Recursive Scanning** (Option A)
- Modify `scan_directory_for_sync()` to use recursive glob
- Add exclusion list for runtime directories (tmp/, logs/, output/)

**Phase 2: Skills Support**
- Add skills/ to artifact type list in `load_all_globally()`
- Scan recursively for all files in skills/ subdirectories

**Phase 3: Dynamic Directory Creation**
- Modify `sync_files()` to create parent directories dynamically
- Remove hard-coded `ensure_directory()` calls

**Phase 4: Reporting Enhancement**
- Count and report subdirectory files separately
- Show directory structure in sync summary

### Implementation Steps

#### Step 1: Update scan_directory_for_sync() for Recursive Scanning

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`

**Changes**:
```lua
--- Scan directory for files to sync (used by Load All operation)
--- Now supports recursive scanning of subdirectories
--- @param global_dir string Global base directory (e.g., ~/.config)
--- @param local_dir string Local base directory (e.g., current project)
--- @param subdir string Subdirectory to scan (e.g., "commands", "hooks")
--- @param extension string File extension pattern (e.g., "*.md", "*.sh")
--- @param recursive boolean Whether to scan subdirectories (default: true)
--- @return table Array of file sync info {name, global_path, local_path, action, is_subdir}
function M.scan_directory_for_sync(global_dir, local_dir, subdir, extension, recursive)
  if recursive == nil then recursive = true end

  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = local_dir .. "/.claude/" .. subdir

  -- Use recursive glob pattern if enabled
  local glob_pattern = recursive
    and (global_path .. "/**/" .. extension)
    or (global_path .. "/" .. extension)

  local global_files = vim.fn.glob(glob_pattern, false, true)

  -- Also scan top-level files
  if recursive then
    local top_level_files = vim.fn.glob(global_path .. "/" .. extension, false, true)
    for _, file in ipairs(top_level_files) do
      table.insert(global_files, file)
    end
  end

  local files = {}
  local seen = {} -- Deduplicate files

  for _, global_file in ipairs(global_files) do
    if not seen[global_file] then
      seen[global_file] = true

      -- Calculate relative path from global_path
      local rel_path = global_file:sub(#global_path + 2) -- +2 to skip leading /
      local local_file = local_path .. "/" .. rel_path

      local action = vim.fn.filereadable(local_file) == 1 and "replace" or "copy"
      table.insert(files, {
        name = rel_path,
        global_path = global_file,
        local_path = local_file,
        action = action,
        is_subdir = rel_path:match("/") ~= nil,
      })
    end
  end

  return files
end
```

#### Step 2: Add Skills Support to load_all_globally()

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Changes** (after line 173):
```lua
-- Scan skills directory (recursive for all files)
local skills_lua = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.lua", true)
local skills_md = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.md", true)
local skills_yaml = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.yaml", true)

-- Merge all skills files
local skills = {}
for _, file in ipairs(skills_lua) do table.insert(skills, file) end
for _, file in ipairs(skills_md) do table.insert(skills, file) end
for _, file in ipairs(skills_yaml) do table.insert(skills, file) end
```

**Update directory creation** (after line 86):
```lua
helpers.ensure_directory(project_dir .. "/.claude/skills")
```

**Update sync call** (line 352-354):
```lua
return load_all_with_strategy(
  project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
  all_agent_protocols, standards, all_data_docs, settings, scripts, tests, skills, merge_only
)
```

**Update load_all_with_strategy signature** (line 72):
```lua
local function load_all_with_strategy(project_dir, commands, agents, hooks, all_tts, templates,
                                      lib_utils, docs, all_agent_protocols, standards,
                                      all_data_docs, settings, scripts, tests, skills, merge_only)
```

**Update sync_files call** (after line 106):
```lua
local skill_count = sync_files(skills, true, merge_only)
```

**Update total count** (line 108-109):
```lua
local total_synced = cmd_count + agt_count + hook_count + tts_count + tmpl_count + lib_count + doc_count +
                     proto_count + std_count + data_count + set_count + script_count + test_count + skill_count
```

**Update reporting** (line 116-118):
```lua
"Synced %d artifacts%s: %d commands, %d agents, %d hooks, %d TTS, %d templates, %d lib, %d docs, " ..
"%d protocols, %d standards, %d data, %d settings, %d scripts, %d tests, %d skills",
total_synced, strategy_msg, cmd_count, agt_count, hook_count, tts_count, tmpl_count, lib_count, doc_count,
proto_count, std_count, data_count, set_count, script_count, test_count, skill_count
```

**Update count_actions calls** (after line 266):
```lua
local skill_copy, skill_replace = count_actions(skills)
```

**Update totals** (line 268-271):
```lua
local total_copy = cmd_copy + agt_copy + hook_copy + tts_copy + tmpl_copy + lib_copy + doc_copy +
                   proto_copy + std_copy + data_copy + set_copy + script_copy + test_copy + skill_copy
local total_replace = cmd_replace + agt_replace + hook_replace + tts_replace + tmpl_replace + lib_replace +
                      doc_replace + proto_replace + std_replace + data_replace + set_replace + script_replace +
                      test_replace + skill_replace
```

#### Step 3: Update sync_files() for Dynamic Directory Creation

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Changes** (replace function at line 15-53):
```lua
--- Sync files from global to local directory
--- Automatically creates subdirectories as needed
--- @param files table List of file sync info
--- @param preserve_perms boolean Preserve execute permissions for shell scripts
--- @param merge_only boolean If true, skip "replace" actions (only copy new files)
--- @return number success_count Number of successfully synced files
local function sync_files(files, preserve_perms, merge_only)
  local success_count = 0
  merge_only = merge_only or false

  for _, file in ipairs(files) do
    -- Skip replace actions if merge_only is true
    if merge_only and file.action == "replace" then
      goto continue
    end

    -- Create parent directory if needed
    local parent_dir = vim.fn.fnamemodify(file.local_path, ":h")
    helpers.ensure_directory(parent_dir)

    -- Read global file
    local content = helpers.read_file(file.global_path)
    if content then
      -- Write to local
      local write_success = helpers.write_file(file.local_path, content)
      if write_success then
        -- Preserve permissions for shell scripts
        if preserve_perms and file.name:match("%.sh$") then
          helpers.copy_file_permissions(file.global_path, file.local_path)
        end
        success_count = success_count + 1
      else
        helpers.notify(
          string.format("Failed to write file: %s", file.name),
          "ERROR"
        )
      end
    else
      helpers.notify(
        string.format("Failed to read global file: %s", file.name),
        "ERROR"
      )
    end

    ::continue::
  end

  return success_count
end
```

#### Step 4: Remove Hard-coded Directory Creation

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Changes** (remove/simplify lines 76-91):
```lua
-- Create base .claude directory
helpers.ensure_directory(project_dir .. "/.claude")

-- Note: Subdirectories are created dynamically by sync_files() as needed
```

#### Step 5: Enhanced Reporting with Subdirectory Counts

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Add helper function** (after count_actions at line 143):
```lua
--- Count files by depth (top-level vs subdirectories)
--- @param files table Array of file sync info
--- @return number top_level_count Files at top level
--- @return number subdir_count Files in subdirectories
local function count_by_depth(files)
  local top_level = 0
  local subdir = 0
  for _, file in ipairs(files) do
    if file.is_subdir then
      subdir = subdir + 1
    else
      top_level = top_level + 1
    end
  end
  return top_level, subdir
end
```

**Update reporting** (replace lines 112-123):
```lua
-- Report results with depth information
if total_synced > 0 then
  local strategy_msg = merge_only and " (new only, conflicts preserved)" or " (including conflicts)"

  -- Calculate subdirectory vs top-level breakdown
  local _, lib_subdir = count_by_depth(lib_utils)
  local _, doc_subdir = count_by_depth(docs)
  local _, test_subdir = count_by_depth(tests)
  local _, skill_subdir = count_by_depth(skills)

  helpers.notify(
    string.format(
      "Synced %d artifacts%s:\n" ..
      "  Commands: %d | Agents: %d | Hooks: %d | TTS: %d\n" ..
      "  Templates: %d | Lib: %d (%d in subdirs) | Docs: %d (%d in subdirs)\n" ..
      "  Protocols: %d | Standards: %d | Data: %d | Settings: %d\n" ..
      "  Scripts: %d | Tests: %d (%d in subdirs) | Skills: %d (%d in subdirs)",
      total_synced, strategy_msg,
      cmd_count, agt_count, hook_count, tts_count,
      tmpl_count, lib_count, lib_subdir, doc_count, doc_subdir,
      proto_count, std_count, data_count, set_count,
      script_count, test_count, test_subdir, skill_count, skill_subdir
    ),
    "INFO"
  )
end
```

### Testing Strategy

**Test Cases**:

1. **Recursive Scanning Validation**
   - Verify glob pattern works on test directory structure
   - Confirm subdirectories at multiple depths are scanned
   - Check deduplication of files

2. **Skills Directory Sync**
   - Verify skills/ directory is created
   - Confirm document-converter skill files are copied
   - Test multiple file types in skills/

3. **Dynamic Directory Creation**
   - Verify nested subdirectories are created (lib/core/, docs/architecture/)
   - Test with empty subdirectories
   - Confirm permission preservation for shell scripts in subdirs

4. **Reporting Accuracy**
   - Verify counts match actual copied files
   - Confirm subdirectory vs top-level breakdown
   - Test with merge_only strategy

5. **Conflict Handling**
   - Test replace strategy with existing subdirectory files
   - Verify merge_only preserves local subdirectory files
   - Test with partially populated subdirectories

6. **Edge Cases**
   - Empty source directory
   - Symlinks in directory tree
   - Files with special characters in names
   - Very deep directory nesting (5+ levels)

**Test Environment**:
- Create test fixture at `/tmp/test-load-artifacts/`
- Mock directory structure with controlled file counts
- Validate against expected counts at each level

**Validation Criteria**:
- 100% of source files copied (recursive comparison)
- Subdirectory structure preserved exactly
- File permissions match source (for .sh files)
- Reporting counts accurate to within 0 files
- No duplicate files in destination

### Standards Compliance

**Clean-Break Development**:
- This is an internal tooling change affecting only the Nvim plugin
- Apply clean-break refactoring: no deprecation period needed
- Old implementation replaced atomically

**Code Standards**:
- Lua code follows nvim/CLAUDE.md conventions
- 2-space indentation, 100-character lines
- Comprehensive inline documentation
- Error handling with pcall for file operations

**Testing Protocols**:
- Lua test files: `*_spec.lua` in `tests/` directory
- Use `assert.is_not_nil()` for pattern matching tests
- Mock file system operations for unit tests

**Documentation Standards**:
- Update `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md`
- Document new recursive scanning behavior
- Add troubleshooting section for glob pattern issues

**Character Encoding**:
- No emojis in code or file content
- Use Unicode box-drawing characters only for diagrams
- UTF-8 encoding for all files

### Migration Plan

**Phase 1: Development** (1-2 days)
- Implement recursive scanning in scan.lua
- Add skills support to sync.lua
- Update dynamic directory creation
- Enhance reporting

**Phase 2: Testing** (1 day)
- Create test fixtures
- Run validation tests
- Verify against real .config/.claude/ structure
- Test on fresh project directory

**Phase 3: Documentation** (0.5 days)
- Update commands/README.md
- Add troubleshooting guide
- Document new reporting format

**Phase 4: Deployment** (immediate)
- Update plugin in lazy.nvim
- Test on existing projects
- Verify backward compatibility (should work seamlessly)

**Rollback Plan**: Keep backup of original sync.lua and scan.lua for quick revert if issues arise.

### Risk Assessment

**Technical Risks**: LOW
- Glob pattern support is standard in Neovim
- File operations are atomic (no partial writes)
- No changes to file format or structure

**User Impact**: MEDIUM (during implementation)
- Users should avoid running "Load All Artifacts" during development
- Existing projects may need re-sync after update
- No data loss risk (operation is copy-only)

**Performance Impact**: LOW
- Recursive glob may be slower on large directories
- Acceptable for typical .claude/ size (500-1000 files)
- Consider adding progress indicator for large syncs

**Compatibility**: HIGH
- Should work on all Neovim versions supporting vim.fn.glob
- No breaking changes to API or user workflow
- Existing projects unaffected (idempotent sync)

## Conclusion

The "Load All Artifacts" feature requires comprehensive refactoring to support recursive directory scanning. The proposed hybrid solution (recursive glob + skills support + dynamic directory creation) provides:

- **Completeness**: All 300+ artifact files copied
- **Maintainability**: Eliminates hard-coded subdirectory lists
- **Transparency**: Accurate reporting with depth breakdown
- **Performance**: Acceptable for typical directory sizes
- **Standards Compliance**: Follows .claude/docs/ development patterns

**Estimated Effort**: 2-3 days (development + testing + documentation)

**Priority**: HIGH (current implementation breaks workflow functionality)

**Next Steps**:
1. Review this research with maintainer
2. Create implementation branch in nvim config repo
3. Implement Phase 1-2 changes
4. Test against real .claude/ structure
5. Update documentation
6. Deploy and verify

## Appendix: File Count Summary

| Directory | Source Files | Destination Files | Missing Count | Status |
|-----------|--------------|-------------------|---------------|--------|
| agents/ | 30 | 28 | 2 | PARTIAL |
| commands/ | 14 | 14 | 0 | OK |
| data/ | 3 READMEs | 0 | 3 | EMPTY |
| docs/ | 238 | 1 | 237 | CRITICAL |
| hooks/ | 4 | 4 | 0 | OK |
| lib/ | 49 | 0 | 49 | CRITICAL |
| scripts/ | 12+ | 9 | 3+ | PARTIAL |
| skills/ | 10+ | 0 | 10+ | MISSING |
| specs/standards/ | Unknown | 0 | Unknown | EMPTY |
| tests/ | 100+ | 0 | 100+ | CRITICAL |
| tts/ | 3 | 3 | 0 | OK |
| **TOTAL** | **450+** | **59** | **391+** | **87% MISSING** |

**Conclusion**: Only 13% of required artifacts are being copied. This refactor is essential for "Load All Artifacts" to function as intended.

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [../plans/001-load-artifacts-completeness-refactor-plan.md](../plans/001-load-artifacts-completeness-refactor-plan.md)
- **Implementation**: [Will be updated by build workflow]
- **Date**: 2025-11-26

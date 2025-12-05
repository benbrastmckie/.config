# Research Report: Fix Option 5 (Clean Replace) in Nvim Claude-Code Sync Utility

**Research Date**: 2025-12-04
**Complexity**: 3
**Feature**: Enable option 5 (clean replace) to remove all local artifacts and replace with global versions

---

## Executive Summary

The nvim claude-code sync utility provides a "Load All Artifacts" feature that syncs artifacts from `~/.config/.claude/` to local project `.claude/` directories. Option 5 ("Clean copy") is currently unimplemented and falls back to option 1 (Replace existing + add new). This option should enable removal of local-only artifacts that no longer exist in the global configuration, allowing for clean synchronization.

**Key Finding**: Option 5 currently shows a warning ("Clean copy not yet implemented") and falls back to merge_only=false behavior, which preserves all local-only files instead of removing them.

---

## Current Implementation Analysis

### 1. Sync Utility Location and Structure

**Primary Files**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` (503 lines)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` (197 lines)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/helpers.lua` (166 lines)

**Entry Point**:
- User command `:ClaudeCommands` → `show_commands_picker()` → `[Load All Artifacts]` entry → `sync.load_all_globally()`

### 2. Current Sync Options

The sync utility presents users with 6 options when conflicts exist:

| Option | Name | Current Behavior | merge_only Flag |
|--------|------|------------------|----------------|
| 1 | Replace + add new | Replaces conflicts, adds new | false |
| 2 | Add new only | Skips conflicts, adds new | true |
| 3 | Interactive | Not implemented (fallback to option 1) | false |
| 4 | Preview diff | Not implemented (fallback to option 1) | false |
| 5 | **Clean copy** | **Not implemented (fallback to option 1)** | **false** |
| 6 | Cancel | Exits without changes | N/A |

**Code Location** (sync.lua:357-377):
```lua
if total_replace > 0 then
  -- Options: 1=Replace existing + add new, 2=Add new only, 3=Interactive, 4=Preview diff, 5=Clean copy, 6=Cancel
  if choice == 1 then
    merge_only = false
  elseif choice == 2 then
    merge_only = true
  elseif choice == 3 then
    -- Interactive per-file (not implemented yet, fallback to Replace all for now)
    helpers.notify("Interactive mode not yet implemented, using Replace existing + add new", "WARN")
    merge_only = false
  elseif choice == 4 then
    -- Preview diff (not implemented yet, fallback to Replace all for now)
    helpers.notify("Preview diff not yet implemented, using Replace existing + add new", "WARN")
    merge_only = false
  elseif choice == 5 then
    -- Clean copy (not implemented yet, fallback to Replace all for now)
    helpers.notify("Clean copy not yet implemented, using Replace existing + add new", "WARN")
    merge_only = false
  else
    helpers.notify("Load all artifacts cancelled", "INFO")
    return 0
  end
```

### 3. How Options 1 and 2 Currently Work

#### Option 1: Replace + Add New (merge_only = false)

**Behavior**:
1. Scans global directory for all artifacts
2. For each artifact:
   - If local version exists: **overwrites** with global version (action="replace")
   - If local version doesn't exist: **copies** global version (action="copy")
3. **Preserves local-only artifacts** (no global equivalent)

**Code Flow** (sync.lua:49-91):
```lua
function sync_files(files, preserve_perms, merge_only)
  for _, file in ipairs(files) do
    -- Skip replace actions if merge_only is true
    if merge_only and file.action == "replace" then
      goto continue
    end

    -- Ensure parent directory exists
    local parent_dir = vim.fn.fnamemodify(file.local_path, ":h")
    helpers.ensure_directory(parent_dir)

    -- Copy file content
    local content = helpers.read_file(file.global_path)
    helpers.write_file(file.local_path, content)

    -- Preserve permissions for shell scripts
    if preserve_perms and file.name:match("%.sh$") then
      helpers.copy_file_permissions(file.global_path, file.local_path)
    end
  end
end
```

**Key Limitation**: Only processes files found in global directory. Local-only files are never touched because they're never scanned.

#### Option 2: Add New Only (merge_only = true)

**Behavior**:
1. Scans global directory for all artifacts
2. For each artifact:
   - If local version exists: **skips** (preserves local version)
   - If local version doesn't exist: **copies** global version
3. **Preserves local-only artifacts** (no global equivalent)

**Code Flow**: Same as option 1, but skips files where `file.action == "replace"`

### 4. Artifact Categories Synced

The sync operation handles **14 artifact categories** with recursive scanning for nested directories:

| Category | Pattern | Directory | Recursive | Permission Preservation |
|----------|---------|-----------|-----------|------------------------|
| Commands | *.md | commands/ | No | No |
| Agents | *.md | agents/ | No | No |
| Hooks | *.sh | hooks/ | No | Yes |
| Scripts | *.sh | scripts/ | Yes | Yes |
| Tests | test_*.sh | tests/ | Yes | Yes |
| TTS Files | *.sh | hooks/, tts/ | No | Yes |
| Templates | *.yaml | templates/ | No | No |
| Lib Utils | *.sh | lib/ | Yes | Yes |
| Docs | *.md | docs/ | Yes | No |
| Skills (lua) | *.lua | skills/ | Yes | Yes |
| Skills (md) | *.md | skills/ | Yes | No |
| Skills (yaml) | *.yaml | skills/ | Yes | No |
| Agent Protocols | *.md | agents/prompts/, agents/shared/ | Yes | No |
| Standards | *.md | specs/standards/ | Yes | No |
| Data Docs | README.md | data/commands/, data/agents/, data/templates/ | Yes | No |
| Settings | settings.local.json | (root) | No | No |

**Total Files**: Approximately 450+ artifacts across all categories

**Code Location** (sync.lua:186-225): Scans all artifact types

### 5. Directory Structure Example

**Global Directory** (`~/.config/.claude/`):
```
.claude/
├── commands/          (14 files)
├── agents/            (30 files)
├── hooks/             (4 files)
├── scripts/           (12 files, 3 nested)
├── tests/             (102 files, all nested)
├── lib/               (49 files, all nested)
│   ├── core/
│   ├── plan/
│   └── workflow/
├── docs/              (238 files, 237 nested)
│   ├── architecture/
│   ├── guides/
│   └── reference/
├── skills/            (5 files, nested)
├── templates/         (0 files currently)
└── settings.local.json
```

**Local Project Directory** (before sync):
```
.claude/
├── commands/
│   ├── old-command.md      (removed from global)
│   └── plan.md             (also in global)
├── agents/
│   └── custom-agent.md     (local-only, not in global)
└── settings.local.json     (outdated)
```

### 6. Why Option 5 Needs Implementation

**Problem Scenario**:
1. User previously synced all artifacts to local project
2. Global config evolves: commands are removed/renamed in `~/.config/.claude/`
3. User runs sync with option 1 (Replace + add new)
4. **Result**: Old local artifacts remain, causing:
   - Stale commands appearing in picker
   - Confusion about which commands are current
   - Cluttered local `.claude/` directory

**Example**:
- Global had `/old-workflow` command → User synced it locally
- Global removes `/old-workflow` (superseded by `/new-workflow`)
- User syncs again with option 1
- `/old-workflow` still exists locally (not cleaned up)
- Picker shows both old and new commands

**What Option 5 Should Do**:
1. **Remove entire local `.claude/` directory** (or specific artifact subdirectories)
2. **Copy all artifacts from global directory** with fresh state
3. **Result**: Local `.claude/` becomes exact mirror of global config
4. **Use Case**: "Reset to global defaults" or "Clean slate sync"

---

## Implementation Requirements

### 1. Clean Replace Logic

**High-Level Algorithm**:
```
1. Backup confirmation (optional safety measure)
2. Remove local .claude/ directory (or specific subdirectories)
3. Recreate .claude/ structure
4. Copy all artifacts from global (same as option 1)
5. Report sync results
```

### 2. Directories to Remove

**Option A: Full Clean** (remove entire `.claude/` directory)
- **Pros**: Complete reset, simplest implementation
- **Cons**: Removes user-specific settings, local-only customizations
- **Risk**: Data loss if user has custom artifacts

**Option B: Selective Clean** (remove only synced artifact types)
- **Pros**: Preserves user files in non-synced directories (e.g., `specs/`, `output/`)
- **Cons**: More complex logic, needs careful directory enumeration
- **Recommended**: Safer approach

**Directories to Remove** (Option B):
```
.claude/commands/
.claude/agents/
.claude/hooks/
.claude/scripts/
.claude/tests/
.claude/lib/
.claude/docs/
.claude/skills/
.claude/templates/
.claude/tts/
.claude/data/commands/
.claude/data/agents/
.claude/data/templates/
.claude/agents/prompts/
.claude/agents/shared/
.claude/specs/standards/
.claude/settings.local.json
```

**Directories to Preserve** (Option B):
```
.claude/specs/        (user work in progress)
.claude/output/       (generated reports)
.claude/logs/         (command execution logs)
.claude/tmp/          (temporary files)
```

### 3. Safety Confirmation

**Recommended Flow**:
1. User selects option 5 "Clean copy"
2. Show **second confirmation dialog**:
   ```
   WARNING: Clean copy will remove all local artifacts!

   This will DELETE:
   - All local .claude/ artifact directories
   - Custom commands, agents, hooks, etc.

   This will PRESERVE:
   - specs/ (your work in progress)
   - output/ (generated reports)
   - logs/ (command history)

   Proceed with clean copy?
   [Yes] [No, go back]
   ```
3. If confirmed, execute clean replace
4. If declined, return to main sync options

### 4. Implementation Functions

**New Function**: `clean_and_replace_all()`

**Signature**:
```lua
--- Remove all local artifact directories and replace with global versions
--- @param project_dir string Local project directory
--- @param global_dir string Global config directory
--- @return number total_synced Number of artifacts synced
local function clean_and_replace_all(project_dir, global_dir)
```

**Implementation Steps**:

**Step 1: Define Artifact Directories**
```lua
local artifact_dirs = {
  "commands",
  "agents",
  "hooks",
  "scripts",
  "tests",
  "lib",
  "docs",
  "skills",
  "templates",
  "tts",
  "data/commands",
  "data/agents",
  "data/templates",
  "agents/prompts",
  "agents/shared",
  "specs/standards",
}
```

**Step 2: Remove Local Artifact Directories**
```lua
for _, subdir in ipairs(artifact_dirs) do
  local local_path = project_dir .. "/.claude/" .. subdir
  if vim.fn.isdirectory(local_path) == 1 then
    vim.fn.delete(local_path, "rf")  -- Recursive force delete
  end
end

-- Remove settings file
local settings_file = project_dir .. "/.claude/settings.local.json"
if vim.fn.filereadable(settings_file) == 1 then
  vim.fn.delete(settings_file)
end
```

**Step 3: Scan and Sync All Artifacts**
```lua
-- Use existing scanning logic from load_all_globally()
local commands = scan.scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
local agents = scan.scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
-- ... (all other artifact types)

-- Sync with merge_only=false (no conflicts since directories were removed)
return load_all_with_strategy(
  project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
  all_agent_protocols, standards, all_data_docs, settings, scripts, tests, all_skills, false
)
```

**Step 4: Update Option 5 Handler**
```lua
elseif choice == 5 then
  -- Clean copy - remove all local artifacts and replace with global
  local confirm_message =
    "WARNING: Clean copy will REMOVE ALL local artifacts!\n\n" ..
    "This will DELETE:\n" ..
    "- All .claude/ artifact directories\n" ..
    "- Commands, agents, hooks, libs, docs, etc.\n\n" ..
    "This will PRESERVE:\n" ..
    "- specs/ (work in progress)\n" ..
    "- output/ (reports)\n" ..
    "- logs/ (history)\n\n" ..
    "Proceed with clean copy?"

  local confirm_choice = vim.fn.confirm(confirm_message, "&Yes\n&No", 2)

  if confirm_choice == 1 then
    return clean_and_replace_all(project_dir, global_dir)
  else
    helpers.notify("Clean copy cancelled", "INFO")
    return 0
  end
```

### 5. Error Handling

**Scenarios to Handle**:

1. **Permission Errors** (can't delete directory)
   ```lua
   local success = pcall(vim.fn.delete, local_path, "rf")
   if not success then
     helpers.notify(
       string.format("Failed to remove directory: %s", subdir),
       "ERROR"
     )
     return 0
   end
   ```

2. **Global Directory Missing**
   ```lua
   if vim.fn.isdirectory(global_dir .. "/.claude") == 0 then
     helpers.notify("Global .claude directory not found", "ERROR")
     return 0
   end
   ```

3. **Partial Deletion Failure**
   - Track which directories were successfully removed
   - Report partial success/failure
   - Offer rollback option (advanced)

### 6. Testing Considerations

**Test Scenarios**:
1. Clean replace with local-only artifacts → should remove them
2. Clean replace with nested subdirectories → should remove entire tree
3. Clean replace with preserved directories (specs/) → should not touch them
4. Clean replace with permission errors → should show error and not corrupt state
5. Cancel after confirmation → should not delete anything

**Manual Test Procedure**:
```bash
# Setup test project
cd /tmp/test-project
mkdir -p .claude/commands
echo "test" > .claude/commands/old-command.md

# Run sync with option 5
# 1. Open Neovim in project
# 2. :ClaudeCommands
# 3. Navigate to [Load All Artifacts]
# 4. Press Enter
# 5. Select option 5 "Clean"
# 6. Confirm deletion
# 7. Verify old-command.md was removed
# 8. Verify global artifacts were copied
```

---

## Dependencies and Integration Points

### 1. Existing Functions to Reuse

| Function | Location | Purpose |
|----------|----------|---------|
| `scan.scan_directory_for_sync()` | scan.lua:38-90 | Scans global artifacts |
| `sync_files()` | sync.lua:49-91 | Copies files with permission handling |
| `load_all_with_strategy()` | sync.lua:111-169 | Orchestrates multi-category sync |
| `helpers.ensure_directory()` | helpers.lua:78-83 | Creates parent directories |
| `helpers.notify()` | helpers.lua:109-113 | User notifications |

### 2. New Functions Required

| Function | Purpose |
|----------|---------|
| `clean_and_replace_all()` | Main clean replace orchestration |
| `remove_artifact_directories()` | Delete specified directories safely |
| `confirm_clean_replace()` | Safety confirmation dialog |

### 3. Modified Functions

**`load_all_globally()`** (sync.lua:175-393):
- Update option 5 handler (line 370-373)
- Add call to `clean_and_replace_all()`
- Add second confirmation dialog

---

## Implementation Risks and Mitigation

### High Risk: Data Loss

**Risk**: User accidentally deletes important local-only artifacts

**Mitigation**:
1. **Two-step confirmation** (main sync options + clean replace warning)
2. **Clear messaging** about what will be deleted
3. **Escape clause** (default to "No" in confirmation dialog)
4. **Future enhancement**: Backup local `.claude/` before deletion

### Medium Risk: Incomplete Deletion

**Risk**: Some directories fail to delete, leaving partial state

**Mitigation**:
1. **Transaction-like behavior**: Verify all deletes succeed before syncing
2. **Error reporting**: Show which directories failed to delete
3. **State validation**: Check directory state before and after operation

### Low Risk: Performance

**Risk**: Large directories (450+ files) take time to delete/copy

**Mitigation**:
1. **Progress indicators**: Show sync progress (future enhancement)
2. **Async operations**: Use vim.loop for non-blocking I/O (future enhancement)
3. **Batch operations**: Current sync already handles large file counts

---

## Recommended Implementation Plan

### Phase 1: Core Implementation (Estimated: 2-3 hours)

1. **Add `clean_and_replace_all()` function**
   - Define artifact directories list
   - Implement directory deletion logic
   - Reuse existing sync functions for copying

2. **Update option 5 handler**
   - Remove fallback warning
   - Add confirmation dialog
   - Call `clean_and_replace_all()`

3. **Add error handling**
   - Permission checks
   - Partial failure detection
   - User-friendly error messages

### Phase 2: Testing (Estimated: 1 hour)

1. **Unit tests** (if test framework exists)
   - Test directory deletion
   - Test confirmation cancellation
   - Test error scenarios

2. **Manual integration testing**
   - Test with various local configurations
   - Verify preserved directories untouched
   - Test error conditions (permissions, missing global)

### Phase 3: Documentation (Estimated: 30 minutes)

1. **Update commands/README.md**
   - Document option 5 behavior
   - Add safety warnings
   - Include use cases

2. **Add inline comments**
   - Explain directory preservation logic
   - Document safety confirmations

---

## Alternative Approaches Considered

### Alternative 1: Backup Before Delete

**Description**: Create backup of local `.claude/` before deletion

**Pros**:
- User can restore if mistake made
- No data loss risk

**Cons**:
- More complex implementation
- Requires backup storage location
- Cleanup of old backups needed

**Verdict**: Good future enhancement, not required for MVP

### Alternative 2: Diff Preview

**Description**: Show user which files will be removed before deletion

**Pros**:
- More transparency
- User can make informed decision

**Cons**:
- Complex UI (multiple screens)
- Overlaps with option 4 (Preview diff)

**Verdict**: Save for option 4 implementation

### Alternative 3: Selective Clean

**Description**: Let user choose which artifact types to clean

**Pros**:
- More granular control
- Less risky

**Cons**:
- Much more complex UI
- Harder to reason about state

**Verdict**: Not recommended - defeats purpose of "clean" replace

---

## Success Criteria

1. **Functionality**:
   - Option 5 removes all local artifact directories
   - Option 5 copies all global artifacts successfully
   - Preserved directories (specs/, output/, logs/) untouched
   - Settings file removed and replaced

2. **Safety**:
   - Two-step confirmation required
   - Default choice is "No" (safe)
   - Clear warning messages
   - No data corruption on errors

3. **User Experience**:
   - Clear messaging about what happens
   - Proper error notifications
   - Picker refreshes after sync
   - Sync report shows accurate counts

4. **Code Quality**:
   - Reuses existing functions
   - Follows codebase conventions
   - Includes error handling
   - Has inline documentation

---

## Open Questions

1. **Q: Should we preserve `.claude/specs/` directory?**
   - A: Yes - user work in progress should never be deleted by sync

2. **Q: Should we backup before deletion?**
   - A: Not in MVP - can be added as future enhancement

3. **Q: How to handle `.claude/CLAUDE.md` file (project standards)?**
   - A: Preserve if exists locally - not synced from global

4. **Q: Should option 5 be available when no conflicts exist?**
   - A: Yes - user may want fresh sync even without conflicts

5. **Q: Should we add option 5 to the "no conflicts" dialog?**
   - A: Yes - expand dialog to include option 5 even when no conflicts detected

---

## References

### Code Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` (main sync logic)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` (directory scanning)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/helpers.lua` (utility functions)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md` (feature documentation)

### Key Functions
- `load_all_globally()` - Main sync entry point (sync.lua:175)
- `sync_files()` - File copying with permissions (sync.lua:49)
- `load_all_with_strategy()` - Multi-category orchestration (sync.lua:111)
- `scan_directory_for_sync()` - Artifact discovery (scan.lua:38)

### Directory Structures
- Global: `/home/benjamin/.config/.claude/` (450+ files)
- Local: `{project}/.claude/` (varies by project)

---

## Conclusion

Option 5 (clean replace) requires implementing directory deletion logic before the standard sync operation. The implementation is straightforward, reusing existing scanning and copying functions. Key safety measures include two-step confirmation and clear messaging about data loss. The main risk is accidental deletion of important local artifacts, mitigated through confirmation dialogs and preserving non-artifact directories (specs/, output/, logs/).

**Recommended Implementation**: Selective clean (Option B) with preserved directories, two-step confirmation, and clear user messaging. This provides the "reset to global defaults" functionality while minimizing data loss risk.

# settings.local.json Sync Strategy Implementation Plan

## Metadata
- **Date**: 2025-12-04 (Revised)
- **Feature**: Revise settings.local.json handling in claude-code sync utility - exclude from sync, add template-based initialization, and clean up current file
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [001-settings-sync-strategy-analysis.md](../reports/001-settings-sync-strategy-analysis.md)

## Overview

The settings.local.json file is being synced between projects by the claude-code sync utility, which violates the official Claude Code design intent. According to official documentation, settings.local.json is explicitly designed to be local-only, not version controlled, and not shared between projects. The current implementation copies project-specific permissions (including hardcoded absolute paths) which would break in target projects.

### Problem Statement
1. settings.local.json contains project-specific absolute paths that break when copied to other projects
2. The sync utility treats settings.local.json as a regular artifact, not respecting its local-only intent
3. Users may inadvertently propagate machine-specific permissions across projects
4. New projects don't get hook configurations automatically

### Proposed Solution
1. Exclude settings.local.json from sync operations entirely
2. Create a shared settings.json template with portable hook configurations
3. Modify sync utility to initialize settings.local.json from settings.json if it doesn't exist
4. Clean up the current settings.local.json file to remove accumulated clutter

## Implementation Phases

### Phase 1: Exclude settings.local.json from Sync [COMPLETE]

**Objective**: Modify the sync utility to skip settings.local.json during all sync operations.

**Files to Modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Tasks**:
- [x] Remove settings scanning from `load_all_globally()` function (line 871)
- [x] Remove settings scanning from `clean_and_replace_all()` function (line 619)
- [x] Remove settings from `load_all_with_strategy()` function signature and call (line 774)
- [x] Remove settings from sync report notification (line 806)
- [x] Remove settings file deletion from `remove_artifact_directories()` function (lines 511, 536-548)
- [x] Update sync confirmation dialogs to not mention settings (various locations)

**Implementation Details**:

```lua
-- BEFORE (line 871):
local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")

-- AFTER:
-- Remove this line entirely - settings.local.json should not be synced
```

```lua
-- BEFORE (line 774):
local set_count = sync_files(settings, false, merge_only)

-- AFTER:
-- Remove this line and set_count from total calculation
```

```lua
-- BEFORE (lines 536-548):
local settings_file = claude_dir .. "/settings.local.json"
if vim.fn.filereadable(settings_file) == 1 then
  local result = vim.fn.delete(settings_file)
  -- ...
end

-- AFTER:
-- Remove this block - settings.local.json should not be deleted during clean replace
```

**Success Criteria**:
- [x] `[Load All Artifacts]` operation does not sync settings.local.json
- [x] Clean Replace operation does not delete local settings.local.json
- [x] Sync notifications do not report settings count
- [x] Interactive mode does not prompt for settings.local.json

**Estimated Effort**: 30-45 minutes

---

### Phase 2: Create Shared settings.json Template [COMPLETE]

**Objective**: Create a template settings.json file with portable hook configurations that can be version controlled and shared.

**Files to Create**:
- `/home/benjamin/.config/.claude/settings.json` (new file)

**Tasks**:
- [x] Extract hooks section from current settings.local.json
- [x] Verify all hooks use $CLAUDE_PROJECT_DIR (portable)
- [x] Create settings.json with portable hooks only
- [x] Add settings.json to version control

**Template Content**:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-command-metrics.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          },
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-buffer-opener.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/tts-dispatcher.sh"
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/post-subagent-metrics.sh"
          }
        ]
      }
    ]
  }
}
```

**Success Criteria**:
- [x] settings.json contains only portable configurations
- [x] All paths use $CLAUDE_PROJECT_DIR variable
- [x] File is added to version control
- [x] Other projects can use this template

**Estimated Effort**: 10-15 minutes

---

### Phase 3: Add settings.local.json Initialization Logic [COMPLETE]

**Objective**: Modify the sync utility to create settings.local.json from settings.json template when the local file doesn't exist.

**Files to Modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Tasks**:
- [x] Add new function `initialize_settings_from_template(project_dir, global_dir)`
- [x] Call this function at the start of `load_all_globally()` and `clean_and_replace_all()`
- [x] Function should check if project's `.claude/settings.local.json` exists
- [x] If not, copy from global `.claude/settings.json` template
- [x] Add notification when settings.local.json is initialized

**Implementation Details**:

```lua
--- Initialize settings.local.json from settings.json template if not exists
--- @param project_dir string Project directory path
--- @param global_dir string Global directory path
--- @return boolean initialized True if file was created
local function initialize_settings_from_template(project_dir, global_dir)
  local local_settings = project_dir .. "/.claude/settings.local.json"
  local global_template = global_dir .. "/.claude/settings.json"

  -- Only initialize if local file doesn't exist
  if vim.fn.filereadable(local_settings) == 1 then
    return false
  end

  -- Check if template exists
  if vim.fn.filereadable(global_template) ~= 1 then
    return false
  end

  -- Ensure .claude directory exists
  helpers.ensure_directory(project_dir .. "/.claude")

  -- Copy template to local settings
  local content = helpers.read_file(global_template)
  if content then
    local success = helpers.write_file(local_settings, content)
    if success then
      helpers.notify("Initialized settings.local.json from template", "INFO")
      return true
    end
  end

  return false
end
```

**Integration Points**:

```lua
-- In load_all_globally() at the start (after project_dir check):
initialize_settings_from_template(project_dir, global_dir)

-- In clean_and_replace_all() after directory removal (before scan):
initialize_settings_from_template(project_dir, global_dir)
```

**Success Criteria**:
- [x] New projects get settings.local.json created from template on first sync
- [x] Existing settings.local.json files are NOT overwritten
- [x] Clean Replace initializes settings.local.json after clearing artifacts
- [x] Notification shown when initialization occurs

**Estimated Effort**: 20-30 minutes

---

### Phase 4: Clean Up settings.local.json [COMPLETE]

**Objective**: Remove accumulated session-specific permissions from settings.local.json, keeping only intentional entries and moving hooks to settings.json.

**Files to Modify**:
- `/home/benjamin/.config/.claude/settings.local.json`

**Tasks**:
- [x] Create backup of current settings.local.json
- [x] Identify which permissions are session-specific vs intentional
- [x] Remove hardcoded absolute path permissions
- [x] Remove accumulated session-specific permissions
- [x] Keep only generic command permissions that are intentional
- [x] Remove hooks section (now in settings.json)

**Current State (28 permission entries)**:
- 4 entries with hardcoded paths (NON-PORTABLE) - REMOVE
- 6 generic command permissions (PORTABLE) - KEEP
- 18 session-specific permissions (ACCUMULATED) - REMOVE

**Recommended Final State**:
```json
{
  "permissions": {
    "allow": [
      "Bash(grep:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git checkout:*)",
      "Read(//tmp/**)"
    ],
    "deny": [],
    "ask": []
  }
}
```

**Success Criteria**:
- [x] Backup created before cleanup
- [x] settings.local.json contains only intentional permissions
- [x] No hardcoded absolute paths remain
- [x] No accumulated session-specific permissions remain
- [x] Hooks removed (now in settings.json)
- [x] File is significantly smaller and more maintainable

**Estimated Effort**: 15-20 minutes

---

### Phase 5: Update Documentation [COMPLETE]

**Objective**: Update sync utility README to document the settings.local.json exclusion, template initialization, and explain the rationale.

**Files to Modify**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md`

**Tasks**:
- [x] Remove settings.local.json from "[Load All Artifacts]" documentation (line 159)
- [x] Add new section explaining settings file handling
- [x] Document the three-tier settings hierarchy (user global, project shared, project local)
- [x] Explain why settings.local.json is excluded from sync
- [x] Document the template initialization behavior

**Documentation Content**:

```markdown
### Settings File Handling

The sync utility respects Claude Code's official settings hierarchy:

**settings.local.json is NOT synced** because:
- It's designed for personal, machine-specific preferences
- Contains project-specific absolute paths that break in other projects
- Should NOT be version controlled or shared between projects
- Permissions accumulate during interactive sessions and aren't meant for long-term storage

**Automatic Initialization**:
When syncing to a project that doesn't have `.claude/settings.local.json`, the sync utility will automatically create it from the global `.claude/settings.json` template. This ensures new projects get standard hook configurations without copying project-specific permissions.

**Recommended Settings Structure**:
| File | Purpose | Synced? | Auto-Initialized? |
|------|---------|---------|-------------------|
| `~/.claude/settings.json` | User-wide defaults | N/A (user global) | No |
| `.claude/settings.json` | Team-shared project config (template) | Via version control | Source |
| `.claude/settings.local.json` | Personal overrides | Never | Yes (from template) |

**To share hook configurations**, use `.claude/settings.json` which serves as both a version-controlled shared config and the template for initializing new projects.
```

**Success Criteria**:
- [ ] README accurately reflects settings.local.json exclusion
- [ ] Template initialization behavior is documented
- [ ] Three-tier settings hierarchy is documented
- [ ] Users understand how to share hook configurations properly

**Estimated Effort**: 15-20 minutes

## Testing Strategy

### Unit Tests
- [ ] Verify `load_all_globally()` does not include settings in scanned artifacts
- [ ] Verify `clean_and_replace_all()` does not delete settings.local.json
- [ ] Verify sync count excludes settings in all report modes
- [ ] Verify `initialize_settings_from_template()` creates file when missing
- [ ] Verify `initialize_settings_from_template()` does NOT overwrite existing file

### Integration Tests
- [ ] Run `[Load All Artifacts]` and verify settings.local.json unchanged (if exists)
- [ ] Run `[Load All Artifacts]` on new project and verify settings.local.json created
- [ ] Run Clean Replace and verify settings.local.json preserved or re-initialized
- [ ] Run Interactive mode and verify no settings.local.json prompt appears

### Manual Verification
- [ ] Test sync from global to new project - settings.local.json should be created from template
- [ ] Test sync with existing local settings - file should remain unchanged
- [ ] Verify sync notifications do not mention settings count
- [ ] Verify cleaned settings.local.json still works with Claude Code

## Alternative Approaches Considered

### Option B: Selective Section Merging (Rejected)
Merge only hooks section while preserving permissions locally. **Rejected** because:
- Complex implementation requiring JSON parsing
- Unclear user expectations
- Doesn't align with official Claude Code design
- Harder to maintain as settings schema evolves

### Option C: Full Template-Based Settings with Variables (Rejected)
Create settings.template.json with variable substitution. **Rejected** because:
- Overkill for current use case
- Adds setup complexity
- Simple template copy achieves the goal

### Option D: Settings Layering (Already Exists)
Claude Code already implements three-tier settings hierarchy. No implementation needed.

### Option E: Sync with Confirmation Dialog (Rejected)
Could add warning when settings.local.json is about to be synced. **Rejected** because:
- Complete exclusion is cleaner and aligns with official design
- Template initialization handles new project use case
- Users who need to share settings can use settings.json

## Rollback Plan

If issues arise after implementation:
1. Revert sync.lua changes (git checkout)
2. Re-add settings scanning lines
3. Remove initialize_settings_from_template function
4. Restore settings.local.json from backup
5. No permanent data loss - backups preserved

## Success Metrics

- [ ] settings.local.json is excluded from all sync operations
- [ ] New projects get settings.local.json initialized from template
- [ ] Existing settings.local.json files are never overwritten
- [ ] Documentation clearly explains settings file handling
- [ ] Portable hooks are available in settings.json template
- [ ] Current project's settings.local.json is cleaned up
- [ ] No regressions in other sync functionality

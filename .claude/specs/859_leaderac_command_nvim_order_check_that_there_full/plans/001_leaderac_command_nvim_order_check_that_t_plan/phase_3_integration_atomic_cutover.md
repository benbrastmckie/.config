# Phase 3 Expansion: Integration and Atomic Cutover

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 001_leaderac_command_nvim_order_check_that_t_plan.md
- **Objective**: Integrate all modules, improve sync operations, and perform atomic replacement of old implementation
- **Complexity**: Medium
- **Status**: NOT STARTED
- **Dependencies**: Phase 1, Phase 2

## Overview

This phase integrates the modular architecture established in Phase 1 and artifact additions from Phase 2 into a production-ready system with enhanced sync operations, comprehensive conflict resolution options, and atomic cutover from the old monolithic implementation.

**Duration**: 6 hours
**Risk Level**: Medium (atomic cutover requires careful execution)

## Core Objectives

1. **Registry-Driven Sync**: Replace hardcoded artifact scanning with registry-based architecture
2. **Enhanced Conflict Resolution**: Implement 5 distinct sync strategies with appropriate safety mechanisms
3. **Validation Infrastructure**: Add file integrity checks, permission verification, and result reporting
4. **Atomic Cutover**: Single-commit replacement of old implementation with comprehensive validation
5. **Test Coverage**: Achieve 80%+ coverage for sync operations, 95%+ for destructive Option 5

## Conflict Resolution Options Architecture

**Option 1: Replace Existing + Add New** (rename from "Replace all")
- **Intent**: Update all global artifacts, preserve local-only files
- **Behavior**:
  - Copy new artifacts (action="copy")
  - Replace conflicting artifacts (action="replace")
  - Preserve local-only artifacts (not in global)
- **Use Case**: Standard sync when you want latest global versions
- **Safety**: Low risk - preserves local customizations not in global

**Option 2: Add New Only** (existing functionality)
- **Intent**: Only add missing artifacts, never overwrite
- **Behavior**:
  - Copy new artifacts (action="copy")
  - Skip conflicting artifacts (action="replace")
- **Use Case**: Selective sync when you have local modifications to preserve
- **Safety**: Very safe - no overwrites

**Option 3: Interactive Per-File**
- **Intent**: User decides for each conflict individually
- **Behavior**:
  - Auto-copy new artifacts
  - Prompt for each conflict: [K]eep local / [R]eplace with global / [D]iff
  - Allow diff preview before decision
- **Use Case**: Careful sync with specific local changes
- **Safety**: Maximum control - user reviews each conflict

**Option 4: Preview Diff Before Sync**
- **Intent**: See all changes before committing
- **Behavior**:
  - Generate diff for all replace actions
  - Show side-by-side comparison in preview buffer
  - Confirm before executing sync
- **Use Case**: Auditing changes before applying
- **Safety**: High visibility into changes

**Option 5: Clean Copy** (destructive)
- **Intent**: Complete reset to global state
- **Behavior**:
  - **DELETE** all local-only artifacts
  - Replace all global artifacts with global versions
  - Clean up empty directories
- **Use Case**: Reset local .claude/ to match global exactly
- **Safety**: HIGH RISK - requires two-stage confirmation and backup recommendation

## Detailed Implementation Specifications

### Task 1: Registry-Driven Sync Infrastructure

**File**: `picker/operations/sync.lua`
**Lines**: ~250 total (expanded from current ~100)

**Implementation Steps**:

1. **Create sync orchestrator function** (40 lines):
```lua
--- Orchestrate registry-driven sync of all artifact types
--- @param global_dir string Global .claude/ directory path
--- @param project_dir string Project .claude/ directory path
--- @return table Artifact collections by type
local function orchestrate_sync(global_dir, project_dir)
  local registry = require("picker.artifacts.registry")
  local scan = require("picker.utils.scan")

  -- Validate directories exist
  if vim.fn.isdirectory(global_dir .. "/.claude") ~= 1 then
    return nil, "Global .claude/ directory not found"
  end

  local collections = {}

  for type_id, artifact_type in pairs(registry.types) do
    if not artifact_type.sync_enabled then
      goto continue
    end

    local type_files = {}

    -- Scan all locations for this type
    for _, location in ipairs(artifact_type.locations) do
      local scanned = scan.scan_directory_for_sync(
        global_dir,
        project_dir,
        location,
        artifact_type.pattern
      )
      vim.list_extend(type_files, scanned)
    end

    collections[type_id] = {
      type_def = artifact_type,
      files = type_files,
      new_count = count_by_action(type_files, "copy"),
      conflict_count = count_by_action(type_files, "replace")
    }

    ::continue::
  end

  return collections
end
```

### Task 2-6: Conflict Resolution Options

#### Option 3: Interactive Per-File

**File**: `picker/operations/sync.lua`
**New Function** (80 lines):

```lua
--- Interactive conflict resolution - prompt for each file
--- @param collections table Artifact collections by type
--- @param project_dir string Project directory
--- @return number Total files synced
local function interactive_sync(collections, project_dir)
  local notify = require('neotex.util.notifications')
  local helpers = require('picker.utils.helpers')
  local synced_count = 0

  -- Auto-copy all new files first
  for _, collection in pairs(collections) do
    for _, file in ipairs(collection.files) do
      if file.action == "copy" then
        if copy_file(file.global_path, file.local_path, collection.type_def.executable) then
          synced_count = synced_count + 1
        end
      end
    end
  end

  -- Interactive resolution for conflicts
  for type_id, collection in pairs(collections) do
    local conflicts = vim.tbl_filter(function(f)
      return f.action == "replace"
    end, collection.files)

    if #conflicts == 0 then
      goto continue
    end

    notify.editor(
      string.format("Resolving %d conflicts in %s...", #conflicts, type_id),
      notify.categories.STATUS
    )

    for i, file in ipairs(conflicts) do
      local rel_path = file.local_path:gsub(project_dir .. "/.claude/", "")

      local message = string.format(
        "Conflict %d/%d: %s\n\n" ..
        "Local version exists. Choose action:",
        i, #conflicts, rel_path
      )

      local buttons = "&Keep local\n&Replace with global\n&Diff\n&Skip remaining\n&Cancel sync"
      local choice = vim.fn.confirm(message, buttons, 1)  -- Default Keep

      if choice == 1 then
        -- Keep local
        goto next_file
      elseif choice == 2 then
        -- Replace with global
        if copy_file(file.global_path, file.local_path, collection.type_def.executable) then
          synced_count = synced_count + 1
        end
      elseif choice == 3 then
        -- Show diff, then re-prompt
        helpers.show_diff(file.local_path, file.global_path)
        local retry_choice = vim.fn.confirm(
          "After viewing diff: " .. rel_path,
          "&Keep local\n&Replace with global",
          1
        )
        if retry_choice == 2 then
          if copy_file(file.global_path, file.local_path, collection.type_def.executable) then
            synced_count = synced_count + 1
          end
        end
      elseif choice == 4 then
        -- Skip remaining conflicts
        break
      else
        -- Cancel entire sync
        notify.editor(
          string.format("Sync cancelled. %d files synced.", synced_count),
          notify.categories.WARNING
        )
        return synced_count
      end

      ::next_file::
    end

    ::continue::
  end

  return synced_count
end
```

**UI/UX Design**:
- Progress indicator: "Conflict X/Y: filename"
- Diff option opens split with vimdiff
- Skip remaining allows batch skip
- Cancel preserves already-synced files

#### Option 5: Clean Copy (Destructive)

**File**: `picker/operations/sync.lua`
**New Functions** (120 lines total):

```lua
--- Identify local-only artifacts (not in global)
--- @param project_dir string Project directory
--- @param collections table Artifact collections (has global files)
--- @return table List of local-only files to delete
local function identify_local_only(project_dir, collections)
  local scan = require('picker.utils.scan')
  local registry = require('picker.artifacts.registry')

  local local_only = {}

  -- Scan local directory for all artifact types
  for type_id, artifact_type in pairs(registry.types) do
    if not artifact_type.sync_enabled then
      goto continue
    end

    for _, location in ipairs(artifact_type.locations) do
      local local_files = scan.scan_local_artifacts(
        project_dir,
        location,
        artifact_type.pattern
      )

      -- Check if each local file exists in global
      for _, local_file in ipairs(local_files) do
        local found_in_global = false

        if collections[type_id] then
          for _, global_file in ipairs(collections[type_id].files) do
            if global_file.local_path == local_file.path then
              found_in_global = true
              break
            end
          end
        end

        if not found_in_global then
          table.insert(local_only, {
            path = local_file.path,
            type_id = type_id,
            rel_path = local_file.path:gsub(project_dir .. "/.claude/", "")
          })
        end
      end
    end

    ::continue::
  end

  return local_only
end

--- Two-stage confirmation for clean copy
--- @param collections table Artifact collections
--- @return table|nil Strategy or nil if cancelled
local function confirm_clean_copy(collections)
  -- Stage 1: Identify what will be deleted
  local project_dir = vim.fn.getcwd()
  local local_only = identify_local_only(project_dir, collections)

  -- Stage 1 confirmation
  local stage1_msg = string.format(
    "DESTRUCTIVE OPERATION WARNING\n\n" ..
    "Clean copy will:\n" ..
    "1. DELETE %d local-only artifacts\n" ..
    "2. REPLACE all global artifacts with global versions\n\n" ..
    "Recommendation: Create backup before proceeding\n" ..
    "  git commit -am 'backup before clean copy'\n\n" ..
    "Continue to preview deletion list?",
    #local_only
  )

  local stage1 = vim.fn.confirm(
    stage1_msg,
    "&Preview deletions\n&Cancel",
    2  -- Default Cancel
  )

  if stage1 ~= 1 then
    return nil
  end

  -- Show deletion preview
  preview_deletion(local_only, project_dir)

  -- Stage 2: Final confirmation
  local stage2_msg = string.format(
    "FINAL CONFIRMATION\n\n" ..
    "You reviewed the deletion preview.\n" ..
    "This action CANNOT BE UNDONE.\n\n" ..
    "Delete %d local-only files and replace all global artifacts?",
    #local_only
  )

  local stage2 = vim.fn.confirm(
    stage2_msg,
    "&YES, DELETE AND REPLACE\n&Cancel",
    2  -- Default Cancel
  )

  if stage2 == 1 then
    return {
      mode = "clean_copy",
      merge_only = false,
      delete_local_only = true,
      local_only_files = local_only
    }
  else
    return nil
  end
end
```

**Safety Mechanisms**:
1. **Two-stage confirmation**: Preview → Final confirm
2. **Deletion preview**: Shows exact files to be deleted
3. **Backup recommendation**: Suggests git commit
4. **Default to Cancel**: Both dialogs default to safe option
5. **Explicit YES button**: Final confirm requires affirmative choice

### Task 7-10: Validation and Reporting

#### File Integrity Validation

**File**: `picker/utils/helpers.lua`
**Function** (30 lines):

```lua
--- Validate file integrity after copy
--- @param source string Source file path
--- @param dest string Destination file path
--- @return boolean Valid
--- @return string|nil Error message
local function validate_file_integrity(source, dest)
  -- Check destination exists
  if vim.fn.filereadable(dest) ~= 1 then
    return false, "Destination file not created"
  end

  -- Compare file sizes
  local source_size = vim.fn.getfsize(source)
  local dest_size = vim.fn.getfsize(dest)

  if source_size ~= dest_size then
    return false, string.format(
      "Size mismatch: source=%d, dest=%d",
      source_size, dest_size
    )
  end

  -- For small files (<100KB), compare checksums
  if source_size < 100000 then
    local source_sum = vim.fn.system(string.format('md5sum "%s"', source)):match("^%S+")
    local dest_sum = vim.fn.system(string.format('md5sum "%s"', dest)):match("^%S+")

    if source_sum ~= dest_sum then
      return false, "Checksum mismatch"
    end
  end

  return true
end
```

#### Sync Result Reporting

**File**: `picker/operations/sync.lua`
**Function** (50 lines):

```lua
--- Report sync results with success/failure breakdown
--- @param results table Sync results by type
--- @param strategy table Sync strategy used
local function report_sync_results(results, strategy)
  local notify = require('neotex.util.notifications')

  local total_success = 0
  local total_failed = 0
  local failures = {}

  for type_id, result in pairs(results) do
    total_success = total_success + result.success_count
    total_failed = total_failed + result.failure_count

    if result.failure_count > 0 then
      table.insert(failures, {
        type_id = type_id,
        count = result.failure_count,
        errors = result.errors
      })
    end
  end

  -- Success notification
  if total_success > 0 then
    local strategy_desc = {
      replace_and_add = "replace existing + add new",
      add_only = "add new only",
      interactive = "interactive",
      preview_diff = "preview diff",
      clean_copy = "clean copy (DELETE local-only)"
    }

    notify.editor(
      string.format(
        "Synced %d artifacts (%s)",
        total_success,
        strategy_desc[strategy.mode]
      ),
      notify.categories.SUCCESS
    )
  end

  -- Failure reporting
  if total_failed > 0 then
    local error_details = {}
    table.insert(error_details, string.format("Failed to sync %d artifacts:", total_failed))

    for _, failure in ipairs(failures) do
      table.insert(error_details, string.format("  %s: %d failures", failure.type_id, failure.count))
      for _, error in ipairs(failure.errors) do
        table.insert(error_details, string.format("    - %s: %s", error.file, error.message))
      end
    end

    notify.editor(
      table.concat(error_details, "\n"),
      notify.categories.ERROR
    )
  end
end
```

### Task 14-17: Atomic Cutover

#### Step 1: Map All External Usage

**Command**: Grep for all picker.lua imports and function calls

```bash
# Find all imports
rg "require.*picker" nvim/

# Find all function calls
rg "picker\.(show|load_all|create)" nvim/

# Find all keybindings
rg "<leader>ac" nvim/
```

#### Step 2: Update All Callers (Single Commit)

**Commit Message**:
```
feat: atomic cutover to modular picker architecture

- Update all picker.lua callers to use new API
- Preserve all user-facing functionality
- Enable registry-driven artifact management
- Add 5 conflict resolution options for Load All

Breaking changes:
- show_commands_picker() → show()
- Internal functions now private

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### Step 3: Remove Old Implementation

**File**: `picker.lua`
**After** (15 lines - facade only):

```lua
-- neotex.plugins.ai.claude.commands.picker
-- Public API boundary for Claude artifacts picker

local internal = require("neotex.plugins.ai.claude.commands.picker.init")

local M = {}

--- Show Claude artifacts picker
--- @param opts table|nil Optional configuration
M.show = function(opts)
  return internal.show(opts)
end

return M
```

## Testing Specifications

### Unit Tests (80% coverage target)

**File**: `picker/operations/sync_spec.lua` (150 lines)

```lua
describe("sync operations", function()
  local sync = require("picker.operations.sync")

  describe("Option 1: Replace existing + add new", function()
    it("copies new files", function() end)
    it("replaces conflicting files", function() end)
    it("preserves local-only files", function() end)
    it("reports accurate counts", function() end)
  end)

  describe("Option 3: Interactive per-file", function()
    it("auto-copies new files", function() end)
    it("prompts for each conflict", function() end)
    it("handles keep local choice", function() end)
    it("handles replace choice", function() end)
    it("handles diff then decide", function() end)
    it("handles skip remaining", function() end)
    it("handles cancel mid-sync", function() end)
  end)

  describe("Option 5: Clean copy", function()
    it("identifies all local-only files", function() end)
    it("shows deletion preview", function() end)
    it("requires stage 1 confirmation", function() end)
    it("requires stage 2 confirmation", function() end)
    it("deletes local-only files", function() end)
    it("replaces all global files", function() end)
    it("cleans up empty directories", function() end)
    it("cancels if stage 1 declined", function() end)
    it("cancels if stage 2 declined", function() end)
  end)

  describe("validation", function()
    it("validates file integrity with checksums", function() end)
    it("verifies executable permissions", function() end)
    it("detects size mismatches", function() end)
    it("detects checksum mismatches", function() end)
  end)
end)
```

### Manual Testing Checklist

**Phase 3 Acceptance Criteria**:
- [ ] **Option 1**: Replace existing + add new works correctly
- [ ] **Option 2**: Add new only works correctly
- [ ] **Option 3**: Interactive per-file works correctly
- [ ] **Option 4**: Preview diff works correctly
- [ ] **Option 5**: Clean copy works correctly
  - [ ] Stage 1 confirmation shown
  - [ ] Deletion preview accurate
  - [ ] Stage 2 confirmation shown
  - [ ] Backup recommendation shown
  - [ ] Local-only files deleted
  - [ ] Global files replaced
- [ ] **Validation**: File integrity and permissions
- [ ] **Reporting**: Sync results accurate
- [ ] **Atomic Cutover**: No regressions

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Option 5 data loss | Low | High | Two-stage confirmation, backup recommendation, deletion preview |
| Interactive UI blocking | Medium | Low | Non-blocking dialogs, escape key always works |
| Checksum performance | Low | Low | Only for files <100KB, optional validation |
| Partial sync state | Medium | Medium | Transaction-like approach, rollback on critical failure |

## Success Criteria

**Functional**:
- All 5 conflict resolution options work correctly
- Validation catches integrity and permission issues
- Reporting shows accurate success/failure counts
- Atomic cutover preserves all existing features

**Quality**:
- 80%+ test coverage for sync operations
- 95%+ test coverage for Option 5 (destructive)
- No critical bugs
- Performance within ±5% baseline

## Phase 3 Completion Checklist

- [ ] All 17 tasks implemented
- [ ] All tests passing (80%+ coverage)
- [ ] Manual testing checklist complete
- [ ] Atomic cutover executed (single commit)
- [ ] No regressions detected
- [ ] Performance benchmarks acceptable
- [ ] Documentation updated
- [ ] Phase 4 can begin

---

**Estimated Duration**: 6 hours

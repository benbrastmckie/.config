-- neotex.plugins.ai.goose.commands.picker.operations.sync
-- Load All Artifacts operation with sync functionality

local M = {}

-- Dependencies
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")

-- Decision constants for interactive mode
local DECISION = {
  KEEP = "keep",       -- Keep local version (skip sync)
  REPLACE = "replace", -- Replace with global version
  SKIP = "skip",       -- Decide later (skip in this session)
  DIFF = "diff",       -- View diff (returns to same prompt after)
}

--- Interactive state for managing per-file sync decisions
--- @class InteractiveState
--- @field conflicts table Array of conflict files (action="replace")
--- @field new_files table Array of new files (action="copy")
--- @field decisions table Map of filepath -> decision
--- @field current_index number Current conflict index (1-based)
--- @field apply_all string|nil "keep" or "replace" if bulk action chosen
--- @field cancelled boolean User cancelled operation

--- Create initial interactive state
--- @param conflicts table Array of files with action="replace"
--- @param new_files table Array of files with action="copy"
--- @return InteractiveState state Initial state object
local function create_interactive_state(conflicts, new_files)
  return {
    conflicts = conflicts,
    new_files = new_files,
    decisions = {},
    current_index = 1,
    apply_all = nil,
    cancelled = false,
  }
end

--- Show diff view for local vs global file
--- @param file table File object with local_path and global_path
--- @param on_close function Callback when diff view closed
local function show_diff_for_file(file, on_close)
  -- Use pcall for safe file operations
  local success, err = pcall(function()
    -- Check if both files exist
    if vim.fn.filereadable(file.local_path) ~= 1 then
      helpers.notify(string.format("Local file not found: %s", file.name), "ERROR")
      on_close()
      return
    end
    if vim.fn.filereadable(file.global_path) ~= 1 then
      helpers.notify(string.format("Global file not found: %s", file.name), "ERROR")
      on_close()
      return
    end

    -- Save current window for restoration
    local original_win = vim.api.nvim_get_current_win()

    -- Open global file in new vertical split
    vim.cmd("vsplit " .. vim.fn.fnameescape(file.global_path))
    local global_win = vim.api.nvim_get_current_win()

    -- Open local file in diff split
    vim.cmd("diffsplit " .. vim.fn.fnameescape(file.local_path))
    local local_win = vim.api.nvim_get_current_win()

    -- Show notification with instructions
    helpers.notify(
      "Viewing diff: Local (left) vs Global (right)\nPress q to return to sync prompt",
      "INFO"
    )

    -- Set up autocommand to detect when both windows are closed
    local group = vim.api.nvim_create_augroup("InteractiveSyncDiff", { clear = true })

    -- Track if callback already invoked (prevent double-call)
    local callback_invoked = false

    -- Set up key mapping for q to close diff and return
    vim.keymap.set("n", "q", function()
      if callback_invoked then
        return
      end
      callback_invoked = true

      -- Close diff windows safely
      pcall(function()
        if vim.api.nvim_win_is_valid(global_win) then
          vim.api.nvim_win_close(global_win, false)
        end
      end)
      pcall(function()
        if vim.api.nvim_win_is_valid(local_win) then
          vim.api.nvim_win_close(local_win, false)
        end
      end)

      -- Clear autocommands
      vim.api.nvim_del_augroup_by_name("InteractiveSyncDiff")

      -- Return to original window if valid
      if vim.api.nvim_win_is_valid(original_win) then
        vim.api.nvim_set_current_win(original_win)
      end

      -- Call completion callback
      on_close()
    end, { buffer = vim.api.nvim_win_get_buf(local_win), nowait = true })

    -- Also set up autocmd for window close events
    vim.api.nvim_create_autocmd("WinClosed", {
      group = group,
      callback = function(ev)
        local closed_win = tonumber(ev.match)
        if closed_win == global_win or closed_win == local_win then
          if callback_invoked then
            return
          end
          callback_invoked = true

          -- Close both windows if one was closed
          pcall(function()
            if vim.api.nvim_win_is_valid(global_win) then
              vim.api.nvim_win_close(global_win, false)
            end
          end)
          pcall(function()
            if vim.api.nvim_win_is_valid(local_win) then
              vim.api.nvim_win_close(local_win, false)
            end
          end)

          -- Clear autocommands
          pcall(vim.api.nvim_del_augroup_by_name, "InteractiveSyncDiff")

          -- Return to original window
          if vim.api.nvim_win_is_valid(original_win) then
            vim.api.nvim_set_current_win(original_win)
          end

          on_close()
        end
      end,
    })
  end)

  if not success then
    helpers.notify(string.format("Error opening diff: %s", tostring(err)), "ERROR")
    on_close()
  end
end

--- Prompt user for decision on a single conflict (recursive async function)
--- @param state InteractiveState Current interactive state
--- @param on_complete function Callback when all conflicts resolved
local function prompt_for_conflict(state, on_complete)
  -- Base case: All conflicts processed
  if state.current_index > #state.conflicts then
    on_complete(state)
    return
  end

  local file = state.conflicts[state.current_index]
  local total = #state.conflicts
  local current = state.current_index

  -- Build prompt title with file info
  local relative_path = file.name
  local title = string.format("File %d of %d: %s", current, total, relative_path)

  -- Build choices array
  local choices = {
    "1. Keep local version",
    "2. Replace with global",
    "3. Skip (decide later)",
    "4. View diff",
    "─────────────────────────",
    "5. Keep ALL remaining local",
    "6. Replace ALL remaining with global",
    "7. Cancel",
  }

  -- Use vim.ui.select for async prompting
  vim.ui.select(choices, {
    prompt = title .. "\n\nLocal differs from global version\n",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    -- Handle nil (escape/cancelled)
    if not choice then
      state.cancelled = true
      on_complete(state)
      return
    end

    -- Parse choice number
    local choice_num = tonumber(choice:match("^(%d+)%."))
    if not choice_num then
      -- User might have escaped, treat as cancel
      state.cancelled = true
      on_complete(state)
      return
    end

    -- Handle choice
    if choice_num == 1 then
      -- Keep local
      state.decisions[file.local_path] = DECISION.KEEP
      state.current_index = state.current_index + 1
      -- Recursive call scheduled to avoid stack overflow
      vim.schedule(function()
        prompt_for_conflict(state, on_complete)
      end)
    elseif choice_num == 2 then
      -- Replace with global
      state.decisions[file.local_path] = DECISION.REPLACE
      state.current_index = state.current_index + 1
      vim.schedule(function()
        prompt_for_conflict(state, on_complete)
      end)
    elseif choice_num == 3 then
      -- Skip
      state.decisions[file.local_path] = DECISION.SKIP
      state.current_index = state.current_index + 1
      vim.schedule(function()
        prompt_for_conflict(state, on_complete)
      end)
    elseif choice_num == 4 then
      -- View diff (will return to same prompt after)
      show_diff_for_file(file, function()
        -- Return to same prompt after diff closed
        vim.schedule(function()
          prompt_for_conflict(state, on_complete)
        end)
      end)
    elseif choice_num == 5 then
      -- Keep all remaining
      state.apply_all = DECISION.KEEP
      on_complete(state)
    elseif choice_num == 6 then
      -- Replace all remaining
      state.apply_all = DECISION.REPLACE
      on_complete(state)
    elseif choice_num == 7 then
      -- Cancel
      state.cancelled = true
      on_complete(state)
    end
  end)
end

--- Apply user decisions and sync files accordingly
--- @param state InteractiveState State with user decisions
--- @param project_dir string Project directory path
--- @return number total_synced Number of files synced
local function apply_interactive_decisions(state, project_dir)
  -- Check if cancelled
  if state.cancelled then
    helpers.notify("Interactive sync cancelled", "INFO")
    return 0
  end

  -- Build list of files to sync
  local files_to_sync = {}

  -- Always include new files (action="copy")
  for _, file in ipairs(state.new_files) do
    table.insert(files_to_sync, file)
  end

  -- Include conflicts based on decisions
  local replaced_count = 0
  local kept_count = 0
  local skipped_count = 0

  for _, file in ipairs(state.conflicts) do
    local decision = state.decisions[file.local_path]

    -- Handle explicit decision or apply_all
    if state.apply_all == DECISION.REPLACE then
      table.insert(files_to_sync, file)
      replaced_count = replaced_count + 1
    elseif state.apply_all == DECISION.KEEP then
      kept_count = kept_count + 1
      -- Don't sync (keep local)
    elseif decision == DECISION.REPLACE then
      table.insert(files_to_sync, file)
      replaced_count = replaced_count + 1
    elseif decision == DECISION.KEEP then
      kept_count = kept_count + 1
      -- Don't sync (keep local)
    else
      -- SKIP or no decision
      skipped_count = skipped_count + 1
    end
  end

  -- Build preserve_perms map for shell scripts
  local preserve_perms_files = {}
  for _, file in ipairs(files_to_sync) do
    if file.name:match("%.sh$") then
      table.insert(preserve_perms_files, file)
    end
  end

  -- Sync files using existing sync infrastructure
  local synced_count = sync_files(files_to_sync, true, false)

  -- Build summary notification
  local new_count = #state.new_files
  local summary_parts = {}

  if synced_count > 0 then
    table.insert(summary_parts, string.format("Synced %d files", synced_count))
    if new_count > 0 then
      table.insert(summary_parts, string.format("(%d new", new_count))
    end
    if replaced_count > 0 then
      if new_count > 0 then
        table.insert(summary_parts, string.format(", %d replaced)", replaced_count))
      else
        table.insert(summary_parts, string.format("(%d replaced)", replaced_count))
      end
    elseif new_count > 0 then
      table.insert(summary_parts, ")")
    end
  end

  if kept_count > 0 then
    table.insert(summary_parts, string.format("\nKept %d local versions", kept_count))
  end

  if skipped_count > 0 then
    table.insert(summary_parts, string.format("\nSkipped %d files", skipped_count))
  end

  if #summary_parts > 0 then
    helpers.notify(table.concat(summary_parts, ""), "INFO")
  else
    helpers.notify("No files synced", "INFO")
  end

  return synced_count
end

--- Run interactive sync mode with per-file prompts
--- @param all_artifacts table Array of all artifact arrays to flatten and process
--- @param project_dir string Project directory path
--- @param global_dir string Global directory path
--- @return number total_synced Number of files synced
local function run_interactive_sync(all_artifacts, project_dir, global_dir)
  -- Flatten all artifact arrays into single array
  local all_files = {}
  for _, artifact_array in ipairs(all_artifacts) do
    for _, file in ipairs(artifact_array) do
      table.insert(all_files, file)
    end
  end

  -- Separate into conflicts and new files
  local conflicts = {}
  local new_files = {}

  for _, file in ipairs(all_files) do
    if file.action == "replace" then
      table.insert(conflicts, file)
    else
      table.insert(new_files, file)
    end
  end

  -- If no conflicts, just sync all new files
  if #conflicts == 0 then
    helpers.notify(
      string.format("No conflicts found. Syncing %d new files...", #new_files),
      "INFO"
    )
    return sync_files(new_files, true, false)
  end

  -- Create interactive state
  local state = create_interactive_state(conflicts, new_files)

  -- Show initial notification
  helpers.notify(
    string.format(
      "Interactive mode: %d conflicts, %d new files\nResolving conflicts...",
      #conflicts,
      #new_files
    ),
    "INFO"
  )

  -- Start recursive prompting (async)
  -- This returns immediately, prompts happen in background
  prompt_for_conflict(state, function(final_state)
    -- This callback runs when all prompts complete
    apply_interactive_decisions(final_state, project_dir)
  end)

  -- Return 0 for now (actual count reported by apply_interactive_decisions)
  return 0
end

--- Initialize settings.local.json from settings.json template if not exists
--- @param project_dir string Project directory path
--- @param global_dir string Global directory path
--- @return boolean initialized True if file was created
local function initialize_settings_from_template(project_dir, global_dir)
  local local_settings = project_dir .. "/.goose/settings.local.json"
  local global_template = global_dir .. "/.goose/settings.json"

  -- Only initialize if local file doesn't exist
  if vim.fn.filereadable(local_settings) == 1 then
    return false
  end

  -- Check if template exists
  if vim.fn.filereadable(global_template) ~= 1 then
    return false
  end

  -- Ensure .goose directory exists
  helpers.ensure_directory(project_dir .. "/.goose")

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

--- Count files by depth (top-level vs subdirectory)
--- @param files table Array of file sync info with is_subdir field
--- @return number top_level_count Number of top-level files
--- @return number subdir_count Number of files in subdirectories
local function count_by_depth(files)
  local top_level_count = 0
  local subdir_count = 0
  for _, file in ipairs(files) do
    if file.is_subdir then
      subdir_count = subdir_count + 1
    else
      top_level_count = top_level_count + 1
    end
  end
  return top_level_count, subdir_count
end

--- Count operations by action type
--- @param files table Array of file sync info
--- @return number copy_count Number of copy operations
--- @return number replace_count Number of replace operations
local function count_actions(files)
  local copy_count = 0
  local replace_count = 0
  for _, file in ipairs(files) do
    if file.action == "copy" then
      copy_count = copy_count + 1
    else
      replace_count = replace_count + 1
    end
  end
  return copy_count, replace_count
end

--- Confirm clean replace operation with two-step safety dialog
--- Shows detailed warning about which directories will be deleted vs preserved
--- @return boolean true if user confirmed, false if cancelled
local function confirm_clean_replace()
  local message = string.format(
    "WARNING: Clean Replace will DELETE all local artifacts!\n\n" ..
    "The following will be REMOVED:\n" ..
    "  - commands/\n" ..
    "  - agents/\n" ..
    "  - hooks/\n" ..
    "  - scripts/\n" ..
    "  - tests/\n" ..
    "  - lib/\n" ..
    "  - docs/\n" ..
    "  - skills/\n" ..
    "  - templates/\n" ..
    "  - tts/\n" ..
    "  - data/commands/, data/agents/, data/templates/\n" ..
    "  - agents/prompts/, agents/shared/\n" ..
    "  - specs/standards/\n\n" ..
    "The following will be PRESERVED:\n" ..
    "  - specs/ (your plans and reports)\n" ..
    "  - output/ (generated artifacts)\n" ..
    "  - logs/ (command history)\n" ..
    "  - tmp/ (temporary files)\n" ..
    "  - settings.local.json (local-only settings)\n" ..
    "  - CLAUDE.md (project standards)\n\n" ..
    "All deleted artifacts will be replaced with global versions.\n\n" ..
    "Are you SURE you want to continue?"
  )

  local buttons = "&Yes\n&No"
  local default_choice = 2  -- Default to No for safety

  local choice = vim.fn.confirm(message, buttons, default_choice)
  return choice == 1  -- Return true if Yes selected, false otherwise
end

--- Remove artifact directories from project directory
--- Deletes all artifact directories (commands/, agents/, etc.) but preserves user work (specs/, output/, logs/)
--- @param project_dir string Project directory path
--- @return boolean success true if all deletions succeeded
--- @return table details Table with success and failed lists
local function remove_artifact_directories(project_dir)
  local goose_dir = project_dir .. "/.goose"

  -- Define all artifact directories to remove
  local artifact_dirs = {
    goose_dir .. "/commands",
    goose_dir .. "/agents",
    goose_dir .. "/hooks",
    goose_dir .. "/scripts",
    goose_dir .. "/tests",
    goose_dir .. "/lib",
    goose_dir .. "/docs",
    goose_dir .. "/skills",
    goose_dir .. "/templates",
    goose_dir .. "/tts",
    goose_dir .. "/data/commands",
    goose_dir .. "/data/agents",
    goose_dir .. "/data/templates",
    goose_dir .. "/agents/prompts",
    goose_dir .. "/agents/shared",
    goose_dir .. "/specs/standards",
  }

  local success_list = {}
  local failed_list = {}

  -- Delete each directory
  for _, dir_path in ipairs(artifact_dirs) do
    -- Only attempt deletion if directory exists
    if vim.fn.isdirectory(dir_path) == 1 then
      local success, error_msg = pcall(function()
        local result = vim.fn.delete(dir_path, "rf")
        if result ~= 0 then
          error("Deletion failed with code: " .. tostring(result))
        end
      end)

      if success then
        table.insert(success_list, dir_path)
      else
        table.insert(failed_list, {path = dir_path, error = error_msg})
      end
    end
  end

  -- settings.local.json is NOT deleted (local-only, project-specific)

  local all_succeeded = #failed_list == 0
  return all_succeeded, {success = success_list, failed = failed_list}
end

--- Sync files from global to local directory
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

    -- Ensure parent directory exists (dynamic creation for subdirectories)
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

--- Helper function to perform the actual sync with the chosen strategy
--- @param project_dir string Project directory path
--- @param commands table Commands to sync
--- @param agents table Agents to sync
--- @param hooks table Hooks to sync
--- @param all_tts table TTS files to sync
--- @param templates table Templates to sync
--- @param lib_utils table Lib utilities to sync
--- @param docs table Docs to sync
--- @param all_agent_protocols table Agent protocols to sync
--- @param standards table Standards to sync
--- @param all_data_docs table Data docs to sync
--- @param scripts table Scripts to sync
--- @param tests table Tests to sync
--- @param skills table Skills to sync
--- @param merge_only boolean If true, only add new files (skip conflicts)
--- @return number total_synced Total number of artifacts synced
local function load_all_with_strategy(project_dir, commands, agents, hooks, all_tts, templates,
                                      lib_utils, docs, all_agent_protocols, standards,
                                      all_data_docs, scripts, tests, skills, settings, merge_only)
  -- Create base .goose directory (subdirectories created dynamically by sync_files)
  helpers.ensure_directory(project_dir .. "/.goose")

  -- Sync all artifact types with merge_only flag
  local cmd_count = sync_files(commands, false, merge_only)
  local agt_count = sync_files(agents, false, merge_only)
  local hook_count = sync_files(hooks, true, merge_only)
  local tts_count = sync_files(all_tts, true, merge_only)
  local tmpl_count = sync_files(templates, false, merge_only)
  local lib_count = sync_files(lib_utils, true, merge_only)
  local doc_count = sync_files(docs, false, merge_only)
  local proto_count = sync_files(all_agent_protocols, false, merge_only)
  local std_count = sync_files(standards, false, merge_only)
  local data_count = sync_files(all_data_docs, false, merge_only)
  local script_count = sync_files(scripts, true, merge_only)
  local test_count = sync_files(tests, true, merge_only)
  local skill_count = sync_files(skills, true, merge_only)
  local set_count = sync_files(settings, false, merge_only)

  local total_synced = cmd_count + agt_count + hook_count + tts_count + tmpl_count + lib_count + doc_count +
                       proto_count + std_count + data_count + script_count + test_count + skill_count + set_count

  -- Report results with depth breakdown
  if total_synced > 0 then
    local strategy_msg = merge_only and " (new only, conflicts preserved)" or " (including conflicts)"

    -- Calculate subdirectory counts for key directories
    local _, lib_subdir = count_by_depth(lib_utils)
    local _, doc_subdir = count_by_depth(docs)
    local _, test_subdir = count_by_depth(tests)
    local _, script_subdir = count_by_depth(scripts)
    local _, skill_subdir = count_by_depth(skills)

    -- Build notification message with subdirectory info
    local lib_msg = lib_count > 0 and string.format("%d lib (%d nested)", lib_count, lib_subdir) or string.format("%d lib", lib_count)
    local doc_msg = doc_count > 0 and string.format("%d docs (%d nested)", doc_count, doc_subdir) or string.format("%d docs", doc_count)
    local test_msg = test_count > 0 and string.format("%d tests (%d nested)", test_count, test_subdir) or string.format("%d tests", test_count)
    local script_msg = script_count > 0 and string.format("%d scripts (%d nested)", script_count, script_subdir) or string.format("%d scripts", script_count)
    local skill_msg = skill_count > 0 and string.format("%d skills (%d nested)", skill_count, skill_subdir) or string.format("%d skills", skill_count)

    helpers.notify(
      string.format(
        "Synced %d artifacts%s:\n" ..
        "  Commands: %d | Agents: %d | Hooks: %d | TTS: %d | Templates: %d\n" ..
        "  %s | %s | Protocols: %d | Standards: %d\n" ..
        "  Data: %d | %s | %s | %s | Settings: %d",
        total_synced, strategy_msg, cmd_count, agt_count, hook_count, tts_count, tmpl_count,
        lib_msg, doc_msg, proto_count, std_count,
        data_count, script_msg, test_msg, skill_msg, set_count
      ),
      "INFO"
    )
  end

  return total_synced
end

--- Clean and replace all artifacts (orchestration function for option 5)
--- Confirms with user, removes artifact directories, rescans global, and syncs all
--- @param project_dir string Project directory path
--- @param global_dir string Global directory path
--- @return number total_synced Total number of artifacts synced (0 if cancelled or failed)
local function clean_and_replace_all(project_dir, global_dir)
  -- Step 1: Confirm clean replace operation
  if not confirm_clean_replace() then
    helpers.notify("Clean replace cancelled", "INFO")
    return 0
  end

  -- Step 2: Remove artifact directories
  local success, details = remove_artifact_directories(project_dir)
  if not success then
    -- Build error message with failed deletions
    local error_msg = "Failed to remove some directories:\n"
    for _, failure in ipairs(details.failed) do
      error_msg = error_msg .. string.format("  - %s: %s\n", failure.path, failure.error)
    end
    helpers.notify(error_msg, "ERROR")
    return 0
  end

  -- Step 2.5: Initialize settings.local.json from template if needed
  initialize_settings_from_template(project_dir, global_dir)

  -- Step 3: Scan all artifact types from global directory (same as load_all_globally)
  local commands = scan.scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
  local agents = scan.scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
  local hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")
  local scripts = scan.scan_directory_for_sync(global_dir, project_dir, "scripts", "*.sh")
  local tests = scan.scan_directory_for_sync(global_dir, project_dir, "tests", "test_*.sh")

  -- Scan TTS files from 2 directories
  local tts_hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh")
  local tts_files = scan.scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh")

  -- Scan templates, lib utilities, and docs
  local templates = scan.scan_directory_for_sync(global_dir, project_dir, "templates", "*.yaml")
  local lib_utils = scan.scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh")
  local docs = scan.scan_directory_for_sync(global_dir, project_dir, "docs", "*.md")

  -- Scan skills directory (*.lua, *.md, *.yaml files)
  local skills_lua = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.lua")
  local skills_md = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.md")
  local skills_yaml = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.yaml")

  -- Scan README files for all directories
  local hooks_readme = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "README.md")
  local tts_readme = scan.scan_directory_for_sync(global_dir, project_dir, "tts", "README.md")
  local templates_readme = scan.scan_directory_for_sync(global_dir, project_dir, "templates", "README.md")
  local lib_readme = scan.scan_directory_for_sync(global_dir, project_dir, "lib", "README.md")
  local agents_prompts_readme = scan.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "README.md")
  local agents_shared_readme = scan.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "README.md")

  -- Scan agent protocols and standards
  local agents_prompts = scan.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md")
  local agents_shared = scan.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md")
  local standards = scan.scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md")

  -- Scan data runtime documentation
  local data_commands_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/commands", "README.md")
  local data_agents_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/agents", "README.md")
  local data_templates_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/templates", "README.md")

  -- Scan settings.json (portable hook configurations)
  local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.json")

  -- Merge TTS files
  local all_tts = {}
  for _, file in ipairs(tts_hooks) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_files) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_readme) do
    table.insert(all_tts, file)
  end

  -- Merge README files into their respective arrays
  for _, file in ipairs(hooks_readme) do
    table.insert(hooks, file)
  end
  for _, file in ipairs(templates_readme) do
    table.insert(templates, file)
  end
  for _, file in ipairs(lib_readme) do
    table.insert(lib_utils, file)
  end
  for _, file in ipairs(agents_prompts_readme) do
    table.insert(agents_prompts, file)
  end
  for _, file in ipairs(agents_shared_readme) do
    table.insert(agents_shared, file)
  end

  -- Merge agent protocols
  local all_agent_protocols = {}
  for _, file in ipairs(agents_prompts) do
    table.insert(all_agent_protocols, file)
  end
  for _, file in ipairs(agents_shared) do
    table.insert(all_agent_protocols, file)
  end

  -- Merge data READMEs
  local all_data_docs = {}
  for _, file in ipairs(data_commands_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_agents_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_templates_readme) do
    table.insert(all_data_docs, file)
  end

  -- Merge skills files
  local all_skills = {}
  for _, file in ipairs(skills_lua) do
    table.insert(all_skills, file)
  end
  for _, file in ipairs(skills_md) do
    table.insert(all_skills, file)
  end
  for _, file in ipairs(skills_yaml) do
    table.insert(all_skills, file)
  end

  -- Step 4: Sync all artifacts with merge_only=false (replace mode)
  return load_all_with_strategy(
    project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
    all_agent_protocols, standards, all_data_docs, scripts, tests, all_skills, settings, false
  )
end

--- Load all global artifacts locally
--- Scans global directory, copies new artifacts, and replaces existing local artifacts
--- with global versions. Preserves local-only artifacts without global equivalents.
--- @return number count Total number of artifacts loaded or updated
function M.load_all_globally()
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    helpers.notify("Already in the global directory", "INFO")
    return 0
  end

  -- Initialize settings.local.json from template if needed
  initialize_settings_from_template(project_dir, global_dir)

  -- Scan all artifact types
  local commands = scan.scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
  local agents = scan.scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
  local hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")
  local scripts = scan.scan_directory_for_sync(global_dir, project_dir, "scripts", "*.sh")
  local tests = scan.scan_directory_for_sync(global_dir, project_dir, "tests", "test_*.sh")

  -- Scan TTS files from 2 directories
  local tts_hooks = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh")
  local tts_files = scan.scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh")

  -- Scan templates, lib utilities, and docs
  local templates = scan.scan_directory_for_sync(global_dir, project_dir, "templates", "*.yaml")
  local lib_utils = scan.scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh")
  local docs = scan.scan_directory_for_sync(global_dir, project_dir, "docs", "*.md")

  -- Scan skills directory (*.lua, *.md, *.yaml files)
  local skills_lua = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.lua")
  local skills_md = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.md")
  local skills_yaml = scan.scan_directory_for_sync(global_dir, project_dir, "skills", "*.yaml")

  -- Scan README files for all directories
  local hooks_readme = scan.scan_directory_for_sync(global_dir, project_dir, "hooks", "README.md")
  local tts_readme = scan.scan_directory_for_sync(global_dir, project_dir, "tts", "README.md")
  local templates_readme = scan.scan_directory_for_sync(global_dir, project_dir, "templates", "README.md")
  local lib_readme = scan.scan_directory_for_sync(global_dir, project_dir, "lib", "README.md")
  local agents_prompts_readme = scan.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "README.md")
  local agents_shared_readme = scan.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "README.md")

  -- Scan agent protocols and standards
  local agents_prompts = scan.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md")
  local agents_shared = scan.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md")
  local standards = scan.scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md")

  -- Scan data runtime documentation
  local data_commands_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/commands", "README.md")
  local data_agents_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/agents", "README.md")
  local data_templates_readme = scan.scan_directory_for_sync(global_dir, project_dir, "data/templates", "README.md")

  -- Scan settings.json (portable hook configurations)
  local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.json")

  -- Merge TTS files
  local all_tts = {}
  for _, file in ipairs(tts_hooks) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_files) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_readme) do
    table.insert(all_tts, file)
  end

  -- Merge README files into their respective arrays
  for _, file in ipairs(hooks_readme) do
    table.insert(hooks, file)
  end
  for _, file in ipairs(templates_readme) do
    table.insert(templates, file)
  end
  for _, file in ipairs(lib_readme) do
    table.insert(lib_utils, file)
  end
  for _, file in ipairs(agents_prompts_readme) do
    table.insert(agents_prompts, file)
  end
  for _, file in ipairs(agents_shared_readme) do
    table.insert(agents_shared, file)
  end

  -- Merge agent protocols
  local all_agent_protocols = {}
  for _, file in ipairs(agents_prompts) do
    table.insert(all_agent_protocols, file)
  end
  for _, file in ipairs(agents_shared) do
    table.insert(all_agent_protocols, file)
  end

  -- Merge data READMEs
  local all_data_docs = {}
  for _, file in ipairs(data_commands_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_agents_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_templates_readme) do
    table.insert(all_data_docs, file)
  end

  -- Merge skills files
  local all_skills = {}
  for _, file in ipairs(skills_lua) do
    table.insert(all_skills, file)
  end
  for _, file in ipairs(skills_md) do
    table.insert(all_skills, file)
  end
  for _, file in ipairs(skills_yaml) do
    table.insert(all_skills, file)
  end

  -- Check if any artifacts found
  local total_files = #commands + #agents + #hooks + #all_tts + #templates + #lib_utils + #docs +
                      #all_agent_protocols + #standards + #all_data_docs + #scripts + #tests + #all_skills + #settings
  if total_files == 0 then
    helpers.notify("No global artifacts found in ~/.config/.goose/", "WARN")
    return 0
  end

  local cmd_copy, cmd_replace = count_actions(commands)
  local agt_copy, agt_replace = count_actions(agents)
  local hook_copy, hook_replace = count_actions(hooks)
  local tts_copy, tts_replace = count_actions(all_tts)
  local tmpl_copy, tmpl_replace = count_actions(templates)
  local lib_copy, lib_replace = count_actions(lib_utils)
  local doc_copy, doc_replace = count_actions(docs)
  local proto_copy, proto_replace = count_actions(all_agent_protocols)
  local std_copy, std_replace = count_actions(standards)
  local data_copy, data_replace = count_actions(all_data_docs)
  local script_copy, script_replace = count_actions(scripts)
  local test_copy, test_replace = count_actions(tests)
  local skill_copy, skill_replace = count_actions(all_skills)
  local set_copy, set_replace = count_actions(settings)

  local total_copy = cmd_copy + agt_copy + hook_copy + tts_copy + tmpl_copy + lib_copy + doc_copy +
                     proto_copy + std_copy + data_copy + script_copy + test_copy + skill_copy + set_copy
  local total_replace = cmd_replace + agt_replace + hook_replace + tts_replace + tmpl_replace + lib_replace +
                        doc_replace + proto_replace + std_replace + data_replace + script_replace + test_replace + skill_replace + set_replace

  -- Skip if no operations needed
  if total_copy + total_replace == 0 then
    helpers.notify("All artifacts already in sync", "INFO")
    return 0
  end

  -- Use vim.fn.confirm for blocking dialog
  local message, buttons, default_choice, merge_only

  if total_replace > 0 then
    -- Has conflicts - offer all 4 strategies
    message = string.format(
      "Load all artifacts from global directory?\n\n" ..
      "New artifacts: %d\n" ..
      "Conflicts (local versions exist): %d\n\n" ..
      "Choose sync strategy:\n" ..
      "  1: Replace + add new (%d total)\n" ..
      "  2: Add new only (%d new)\n" ..
      "  3: Interactive\n" ..
      "  4: Clean copy   5: Cancel",
      total_copy, total_replace, total_copy + total_replace, total_copy
    )
    buttons = "&1 Replace\n&2 New only\n&3 Interactive\n&4 Clean\n&5 Cancel"
    default_choice = 5  -- Default to Cancel for safety
  else
    -- No conflicts - only new artifacts (offer Add all or Clean copy)
    message = string.format(
      "Load all artifacts from global directory?\n\n" ..
      "New artifacts: %d\n" ..
      "No conflicts found\n\n" ..
      "Choose sync strategy:\n" ..
      "  1: Add all new artifacts\n" ..
      "  2: Clean copy (remove all local artifacts first)\n" ..
      "  3: Cancel",
      total_copy
    )
    buttons = "&Add all\n&Clean copy\n&Cancel"
    default_choice = 3
  end

  local choice = vim.fn.confirm(message, buttons, default_choice)

  if total_replace > 0 then
    -- Options: 1=Replace existing + add new, 2=Add new only, 3=Interactive, 4=Clean copy, 5=Cancel
    if choice == 1 then
      merge_only = false
    elseif choice == 2 then
      merge_only = true
    elseif choice == 3 then
      -- Interactive per-file sync with vim.ui.select prompts
      -- Use vim.schedule to ensure picker closes before prompts appear
      vim.schedule(function()
        run_interactive_sync(
          {
            commands, agents, hooks, all_tts, templates, lib_utils, docs,
            all_agent_protocols, standards, all_data_docs, scripts, tests, all_skills, settings
          },
          project_dir,
          global_dir
        )
      end)
      return 0  -- Actual count reported by apply_interactive_decisions
    elseif choice == 4 then
      -- Clean copy - remove all local artifacts and replace with global versions
      return clean_and_replace_all(project_dir, global_dir)
    else
      helpers.notify("Load all artifacts cancelled", "INFO")
      return 0
    end
  else
    -- Options: 1=Add all, 2=Clean copy, 3=Cancel
    if choice == 1 then
      merge_only = false
    elseif choice == 2 then
      -- Clean copy - remove all local artifacts and replace with global versions
      return clean_and_replace_all(project_dir, global_dir)
    else
      helpers.notify("Load all artifacts cancelled", "INFO")
      return 0
    end
  end

  -- Execute the sync operation
  return load_all_with_strategy(
    project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
    all_agent_protocols, standards, all_data_docs, scripts, tests, all_skills, settings, merge_only
  )
end

--- Update local artifact from global version
--- @param artifact table Artifact data with filepath and name
--- @param artifact_type string Type of artifact (for directory determination)
--- @param silent boolean Don't show notifications
--- @return boolean success
function M.update_artifact_from_global(artifact, artifact_type, silent)
  if not artifact or not artifact.name then
    if not silent then
      helpers.notify("No artifact selected", "ERROR")
    end
    return false
  end

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't update if we're in the global directory
  if project_dir == global_dir then
    if not silent then
      helpers.notify(
        "Cannot update artifacts in the global directory",
        "WARN"
      )
    end
    return false
  end

  -- Determine directory based on artifact type
  local subdir_map = {
    command = "commands",
    agent = "agents",
    hook = "hooks",
    lib = "lib",
    doc = "docs",
    template = "templates",
    tts_file = "tts",
    script = "scripts",
    test = "tests",
  }

  local subdir = subdir_map[artifact_type]
  if not subdir then
    if not silent then
      helpers.notify("Unknown artifact type: " .. artifact_type, "ERROR")
    end
    return false
  end

  -- Find the global version
  local global_filepath = global_dir .. "/.goose/" .. subdir .. "/" .. artifact.name
  if artifact_type == "command" or artifact_type == "agent" or artifact_type == "doc" then
    global_filepath = global_filepath .. ".md"
  elseif artifact_type == "hook" or artifact_type == "lib" or artifact_type == "tts_file" or
         artifact_type == "script" or artifact_type == "test" then
    global_filepath = global_filepath .. ".sh"
  elseif artifact_type == "template" then
    global_filepath = global_filepath .. ".yaml"
  end

  -- Check if global version exists
  if not helpers.is_file_readable(global_filepath) then
    if not silent then
      helpers.notify(
        string.format("Global version not found: %s", artifact.name),
        "ERROR"
      )
    end
    return false
  end

  -- Create local directory if needed
  local local_dir = project_dir .. "/.goose/" .. subdir
  helpers.ensure_directory(local_dir)

  -- Copy global file to local
  local local_filepath = local_dir .. "/" .. vim.fn.fnamemodify(global_filepath, ":t")
  local content = helpers.read_file(global_filepath)
  if not content then
    if not silent then
      helpers.notify("Failed to read global file", "ERROR")
    end
    return false
  end

  local write_success = helpers.write_file(local_filepath, content)
  if not write_success then
    if not silent then
      helpers.notify("Failed to write local file", "ERROR")
    end
    return false
  end

  -- Preserve permissions for shell scripts
  if artifact_type == "hook" or artifact_type == "lib" or artifact_type == "tts_file" or
     artifact_type == "script" or artifact_type == "test" then
    helpers.copy_file_permissions(global_filepath, local_filepath)
  end

  if not silent then
    helpers.notify(
      string.format("Updated %s from global version", artifact.name),
      "INFO"
    )
  end

  return true
end

return M

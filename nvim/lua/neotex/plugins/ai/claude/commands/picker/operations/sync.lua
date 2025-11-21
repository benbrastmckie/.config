-- neotex.plugins.ai.claude.commands.picker.operations.sync
-- Load All Artifacts operation with sync functionality

local M = {}

-- Dependencies
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")

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
--- @param settings table Settings to sync
--- @param scripts table Scripts to sync
--- @param tests table Tests to sync
--- @param merge_only boolean If true, only add new files (skip conflicts)
--- @return number total_synced Total number of artifacts synced
local function load_all_with_strategy(project_dir, commands, agents, hooks, all_tts, templates,
                                      lib_utils, docs, all_agent_protocols, standards,
                                      all_data_docs, settings, scripts, tests, merge_only)
  -- Create local directories if needed
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
  local set_count = sync_files(settings, false, merge_only)
  local script_count = sync_files(scripts, true, merge_only)
  local test_count = sync_files(tests, true, merge_only)

  local total_synced = cmd_count + agt_count + hook_count + tts_count + tmpl_count + lib_count + doc_count +
                       proto_count + std_count + data_count + set_count + script_count + test_count

  -- Report results
  if total_synced > 0 then
    local strategy_msg = merge_only and " (new only, conflicts preserved)" or " (including conflicts)"
    helpers.notify(
      string.format(
        "Synced %d artifacts%s: %d commands, %d agents, %d hooks, %d TTS, %d templates, %d lib, %d docs, " ..
        "%d protocols, %d standards, %d data, %d settings, %d scripts, %d tests",
        total_synced, strategy_msg, cmd_count, agt_count, hook_count, tts_count, tmpl_count, lib_count, doc_count,
        proto_count, std_count, data_count, set_count, script_count, test_count
      ),
      "INFO"
    )
  end

  return total_synced
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

  -- Scan settings file
  local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")

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

  -- Check if any artifacts found
  local total_files = #commands + #agents + #hooks + #all_tts + #templates + #lib_utils + #docs +
                      #all_agent_protocols + #standards + #all_data_docs + #settings + #scripts + #tests
  if total_files == 0 then
    helpers.notify("No global artifacts found in ~/.config/.claude/", "WARN")
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
  local set_copy, set_replace = count_actions(settings)
  local script_copy, script_replace = count_actions(scripts)
  local test_copy, test_replace = count_actions(tests)

  local total_copy = cmd_copy + agt_copy + hook_copy + tts_copy + tmpl_copy + lib_copy + doc_copy +
                     proto_copy + std_copy + data_copy + set_copy + script_copy + test_copy
  local total_replace = cmd_replace + agt_replace + hook_replace + tts_replace + tmpl_replace + lib_replace +
                        doc_replace + proto_replace + std_replace + data_replace + set_replace + script_replace + test_replace

  -- Skip if no operations needed
  if total_copy + total_replace == 0 then
    helpers.notify("All artifacts already in sync", "INFO")
    return 0
  end

  -- Use vim.fn.confirm for blocking dialog
  local message, buttons, default_choice, merge_only

  if total_replace > 0 then
    -- Has conflicts - offer all 5 strategies
    message = string.format(
      "Load all artifacts from global directory?\n\n" ..
      "New artifacts: %d\n" ..
      "Conflicts (local versions exist): %d\n\n" ..
      "Choose sync strategy:",
      total_copy, total_replace
    )
    buttons = string.format(
      "&1: Replace existing + add new (%d total)\n" ..
      "&2: Add new only (%d new)\n" ..
      "&3: Interactive per-file\n" ..
      "&4: Preview diff\n" ..
      "&5: Clean copy (DELETE local-only)\n" ..
      "&Cancel",
      total_copy + total_replace, total_copy
    )
    default_choice = 6  -- Default to Cancel for safety
  else
    -- No conflicts - only new artifacts
    message = string.format(
      "Load all artifacts from global directory?\n\n" ..
      "New artifacts: %d\n" ..
      "No conflicts found\n\n" ..
      "All artifacts will be added to local .claude/",
      total_copy
    )
    buttons = string.format(
      "&Add all (%d new)\n&Cancel",
      total_copy
    )
    default_choice = 2
  end

  local choice = vim.fn.confirm(message, buttons, default_choice)

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
  else
    -- Options: 1=Add all, 2=Cancel
    if choice == 1 then
      merge_only = false
    else
      helpers.notify("Load all artifacts cancelled", "INFO")
      return 0
    end
  end

  -- Execute the sync operation
  return load_all_with_strategy(
    project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
    all_agent_protocols, standards, all_data_docs, settings, scripts, tests, merge_only
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
  local global_filepath = global_dir .. "/.claude/" .. subdir .. "/" .. artifact.name
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
  local local_dir = project_dir .. "/.claude/" .. subdir
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

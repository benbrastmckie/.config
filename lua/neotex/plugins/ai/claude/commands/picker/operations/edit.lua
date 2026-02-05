-- neotex.plugins.ai.claude.commands.picker.operations.edit
-- File editing operations for artifacts

local M = {}

-- Dependencies
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")

--- Edit artifact file with proper escaping
--- @param filepath string Path to file to edit
function M.edit_artifact_file(filepath)
  if not filepath or not helpers.is_file_readable(filepath) then
    helpers.notify(
      "File not found or not readable: " .. (filepath or "nil"),
      "ERROR"
    )
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

--- Save local artifact to global directory
--- @param artifact table Artifact data with filepath and name
--- @param artifact_type string Type of artifact (for directory determination)
--- @return boolean success
function M.save_artifact_to_global(artifact, artifact_type)
  if not artifact or not artifact.filepath then
    helpers.notify("No artifact selected", "ERROR")
    return false
  end

  local project_dir = vim.fn.getcwd()
  local global_dir = scan.get_global_dir()

  -- Don't save if we're in the global directory
  if project_dir == global_dir then
    helpers.notify(
      "Already in the global directory - nothing to save",
      "WARN"
    )
    return false
  end

  -- Check if artifact is local
  if not artifact.is_local then
    helpers.notify(
      "Artifact is already global - no need to save",
      "INFO"
    )
    return false
  end

  -- Determine target directory based on artifact type
  local subdir_map = {
    command = "commands",
    skill = "skills",
    hook = "hooks",
    lib = "lib",
    doc = "docs",
    template = "templates",
    script = "scripts",
    test = "tests",
  }

  local subdir = subdir_map[artifact_type]
  if not subdir then
    helpers.notify("Unknown artifact type: " .. artifact_type, "ERROR")
    return false
  end

  -- Ensure global directory exists
  local global_target_dir = global_dir .. "/.claude/" .. subdir
  helpers.ensure_directory(global_target_dir)

  -- Copy local file to global
  local filename = helpers.get_filename(artifact.filepath)
  local global_filepath = global_target_dir .. "/" .. filename

  local content = helpers.read_file(artifact.filepath)
  if not content then
    helpers.notify("Failed to read local file", "ERROR")
    return false
  end

  local write_success = helpers.write_file(global_filepath, content)
  if not write_success then
    helpers.notify("Failed to write global file", "ERROR")
    return false
  end

  -- Preserve permissions for shell scripts
  if artifact_type == "hook" or artifact_type == "lib" or artifact_type == "script" or artifact_type == "test" then
    helpers.copy_file_permissions(artifact.filepath, global_filepath)
  end

  helpers.notify(
    string.format("Saved %s to global directory", artifact.name),
    "INFO"
  )

  return true
end

--- Load artifact locally from global directory (with dependencies)
--- @param artifact table Artifact data
--- @param artifact_type string Type of artifact
--- @param parser table Parser module for dependency resolution
--- @return boolean success
function M.load_artifact_locally(artifact, artifact_type, parser)
  if not artifact or not artifact.name then
    helpers.notify("No artifact selected", "ERROR")
    return false
  end

  local project_dir = vim.fn.getcwd()
  local global_dir = scan.get_global_dir()

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    helpers.notify("Already in the global directory", "INFO")
    return false
  end

  -- Determine source and target directories
  local subdir_map = {
    command = "commands",
    skill = "skills",
    hook = "hooks",
    lib = "lib",
    doc = "docs",
    template = "templates",
    script = "scripts",
    test = "tests",
  }

  local subdir = subdir_map[artifact_type]
  if not subdir then
    helpers.notify("Unknown artifact type: " .. artifact_type, "ERROR")
    return false
  end

  -- Ensure local directory exists
  local local_dir = project_dir .. "/.claude/" .. subdir
  helpers.ensure_directory(local_dir)

  -- Find global version
  local global_filepath
  if artifact.filepath and artifact.filepath:match("^" .. vim.pesc(global_dir)) then
    global_filepath = artifact.filepath
  else
    -- Construct global filepath from global directory
    global_filepath = global_dir .. "/.claude/" .. subdir .. "/" .. artifact.name
    if artifact_type == "command" or artifact_type == "skill" or artifact_type == "doc" then
      global_filepath = global_filepath .. ".md"
    elseif artifact_type == "hook" or artifact_type == "lib" or artifact_type == "script" or artifact_type == "test" then
      global_filepath = global_filepath .. ".sh"
    elseif artifact_type == "template" then
      global_filepath = global_filepath .. ".yaml"
    end
  end

  -- Check if global version exists
  if not helpers.is_file_readable(global_filepath) then
    helpers.notify(
      string.format("Global version not found: %s", artifact.name),
      "ERROR"
    )
    return false
  end

  -- Copy main file
  local filename = helpers.get_filename(global_filepath)
  local local_filepath = local_dir .. "/" .. filename

  local content = helpers.read_file(global_filepath)
  if not content then
    helpers.notify("Failed to read global file", "ERROR")
    return false
  end

  local write_success = helpers.write_file(local_filepath, content)
  if not write_success then
    helpers.notify("Failed to write local file", "ERROR")
    return false
  end

  -- Preserve permissions for shell scripts
  if artifact_type == "hook" or artifact_type == "lib" or artifact_type == "script" or artifact_type == "test" then
    helpers.copy_file_permissions(global_filepath, local_filepath)
  end

  -- Load dependencies for commands
  local total_loaded = 1
  if artifact_type == "command" and parser then
    local command = artifact.command or artifact
    if command.dependent_commands and #command.dependent_commands > 0 then
      for _, dep_name in ipairs(command.dependent_commands) do
        local dep_global_path = global_dir .. "/.claude/commands/" .. dep_name .. ".md"
        if helpers.is_file_readable(dep_global_path) then
          local dep_local_path = project_dir .. "/.claude/commands/" .. dep_name .. ".md"
          local dep_content = helpers.read_file(dep_global_path)
          if dep_content and helpers.write_file(dep_local_path, dep_content) then
            total_loaded = total_loaded + 1
          end
        end
      end
    end
  end

  if total_loaded > 1 then
    helpers.notify(
      string.format("Loaded %s with %d dependencies", artifact.name, total_loaded - 1),
      "INFO"
    )
  else
    helpers.notify(
      string.format("Loaded %s locally", artifact.name),
      "INFO"
    )
  end

  return true
end

return M

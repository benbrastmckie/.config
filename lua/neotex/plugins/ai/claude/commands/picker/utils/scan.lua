-- neotex.plugins.ai.claude.commands.picker.utils.scan
-- Directory scanning utilities for artifacts

local M = {}

--- Scan a directory for files matching a pattern
--- @param dir string Directory path to scan
--- @param pattern string File pattern (e.g., "*.md", "*.sh")
--- @return table Array of file info {name, filepath, is_local}
function M.scan_directory(dir, pattern)
  local files = {}
  local file_paths = vim.fn.glob(dir .. "/" .. pattern, false, true)

  for _, filepath in ipairs(file_paths) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local is_readme = filename == "README.md"

    if not is_readme then
      local name = vim.fn.fnamemodify(filepath, ":t:r")
      table.insert(files, {
        name = name,
        filepath = filepath,
        is_local = false, -- Will be set by merge logic
      })
    end
  end

  return files
end

--- Scan directory for files to sync (used by Load All operation)
--- @param global_dir string Global base directory (e.g., ~/.config)
--- @param local_dir string Local base directory (e.g., current project)
--- @param subdir string Subdirectory to scan (e.g., "commands", "hooks")
--- @param extension string File extension pattern (e.g., "*.md", "*.sh")
--- @return table Array of file sync info {name, global_path, local_path, action}
function M.scan_directory_for_sync(global_dir, local_dir, subdir, extension)
  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = local_dir .. "/.claude/" .. subdir
  local global_files = vim.fn.glob(global_path .. "/" .. extension, false, true)

  local files = {}
  for _, global_file in ipairs(global_files) do
    local filename = vim.fn.fnamemodify(global_file, ":t")
    local local_file = local_path .. "/" .. filename

    local action = vim.fn.filereadable(local_file) == 1 and "replace" or "copy"
    table.insert(files, {
      name = filename,
      global_path = global_file,
      local_path = local_file,
      action = action,
    })
  end

  return files
end

--- Merge local and global artifacts (local overrides global)
--- @param local_artifacts table Array of local artifacts
--- @param global_artifacts table Array of global artifacts
--- @return table Merged array with is_local flag set correctly
function M.merge_artifacts(local_artifacts, global_artifacts)
  local all_artifacts = {}
  local artifact_map = {}

  -- Add local artifacts first and mark them as local
  for _, artifact in ipairs(local_artifacts) do
    artifact.is_local = true
    table.insert(all_artifacts, artifact)
    artifact_map[artifact.name] = true
  end

  -- Add global artifacts only if not overridden by local
  for _, artifact in ipairs(global_artifacts) do
    if not artifact_map[artifact.name] then
      artifact.is_local = false
      table.insert(all_artifacts, artifact)
    end
  end

  return all_artifacts
end

--- Filter artifacts by name pattern
--- @param artifacts table Array of artifacts
--- @param pattern string Lua pattern (e.g., "^tts%-")
--- @return table Filtered array
function M.filter_by_pattern(artifacts, pattern)
  local filtered = {}

  for _, artifact in ipairs(artifacts) do
    if artifact.name:match(pattern) then
      table.insert(filtered, artifact)
    end
  end

  return filtered
end

--- Get project and global directories
--- @return table {project_dir, global_dir}
function M.get_directories()
  return {
    project_dir = vim.fn.getcwd(),
    global_dir = vim.fn.expand("~/.config"),
  }
end

--- Scan artifacts for picker display
--- @param type_config table Artifact type configuration from registry
--- @return table Array of artifacts with metadata
function M.scan_artifacts_for_picker(type_config)
  local dirs = M.get_directories()
  local local_artifacts = {}
  local global_artifacts = {}

  -- Scan each subdirectory defined in type_config
  for _, subdir in ipairs(type_config.subdirs) do
    local local_path = dirs.project_dir .. "/.claude/" .. subdir
    local global_path = dirs.global_dir .. "/.claude/" .. subdir

    local local_files = M.scan_directory(local_path, "*" .. type_config.extension)
    local global_files = M.scan_directory(global_path, "*" .. type_config.extension)

    vim.list_extend(local_artifacts, local_files)
    vim.list_extend(global_artifacts, global_files)
  end

  -- Apply pattern filter if defined (e.g., tts-*.sh)
  if type_config.pattern_filter then
    local_artifacts = M.filter_by_pattern(local_artifacts, type_config.pattern_filter)
    global_artifacts = M.filter_by_pattern(global_artifacts, type_config.pattern_filter)
  end

  -- Merge artifacts (local overrides global)
  return M.merge_artifacts(local_artifacts, global_artifacts)
end

--- Scan all artifact types for sync operation
--- @return table Map of artifact_type -> array of sync files
function M.scan_all_for_sync()
  local dirs = M.get_directories()
  local global_dir = dirs.global_dir
  local project_dir = dirs.project_dir

  return {
    commands = M.scan_directory_for_sync(global_dir, project_dir, "commands", "*.md"),
    agents = M.scan_directory_for_sync(global_dir, project_dir, "agents", "*.md"),
    hooks = M.scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh"),
    tts_hooks = M.scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh"),
    tts_files = M.scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh"),
    templates = M.scan_directory_for_sync(global_dir, project_dir, "templates", "*.yaml"),
    lib_utils = M.scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh"),
    docs = M.scan_directory_for_sync(global_dir, project_dir, "docs", "*.md"),
    agent_prompts = M.scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md"),
    agent_shared = M.scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md"),
    standards = M.scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md"),
    settings = M.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json"),
  }
end

return M

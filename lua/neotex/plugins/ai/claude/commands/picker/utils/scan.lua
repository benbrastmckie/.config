-- neotex.plugins.ai.claude.commands.picker.utils.scan
-- Directory scanning utilities for artifacts

local M = {}

--- Get the global source directory from config with fallback
--- @return string Global source directory path
function M.get_global_dir()
  local ok, config = pcall(require, "neotex.plugins.ai.claude.config")
  if ok and config.options and config.options.global_source_dir then
    return config.options.global_source_dir
  end
  if ok and config.defaults and config.defaults.global_source_dir then
    return config.defaults.global_source_dir
  end
  return vim.fn.expand("~/.config/nvim")
end

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
--- @param global_dir string Global base directory (e.g., ~/.config/nvim)
--- @param local_dir string Local base directory (e.g., current project)
--- @param subdir string Subdirectory to scan (e.g., "commands", "hooks")
--- @param extension string File extension pattern (e.g., "*.md", "*.sh")
--- @param recursive boolean Enable recursive scanning with ** pattern (default: true)
--- @return table Array of file sync info {name, global_path, local_path, action, is_subdir}
function M.scan_directory_for_sync(global_dir, local_dir, subdir, extension, recursive)
  if recursive == nil then recursive = true end

  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = local_dir .. "/.claude/" .. subdir

  local all_files = {}
  local seen = {}  -- Deduplication table to prevent copying same file twice

  if recursive then
    -- Scan nested subdirectories with ** pattern (e.g., lib/core/utils.sh, docs/architecture/design.md)
    -- This is critical for copying all infrastructure files, not just top-level files
    local recursive_files = vim.fn.glob(global_path .. "/**/" .. extension, false, true)
    for _, global_file in ipairs(recursive_files) do
      seen[global_file] = true
      table.insert(all_files, global_file)
    end

    -- Scan top-level files separately (e.g., lib/README.md)
    -- **/ pattern doesn't match files directly in base directory, so we need both scans
    local top_level_files = vim.fn.glob(global_path .. "/" .. extension, false, true)
    for _, global_file in ipairs(top_level_files) do
      if not seen[global_file] then  -- Skip if already found by recursive scan
        seen[global_file] = true
        table.insert(all_files, global_file)
      end
    end
  else
    -- Original behavior: top-level only (for backward compatibility)
    all_files = vim.fn.glob(global_path .. "/" .. extension, false, true)
  end

  local files = {}
  for _, global_file in ipairs(all_files) do
    -- Calculate relative path from global_path base (e.g., "core/utils.sh" from "/path/lib/core/utils.sh")
    local rel_path = global_file:sub(#global_path + 2)
    local local_file = local_path .. "/" .. rel_path

    -- Detect if file is in subdirectory (for reporting depth breakdown)
    local is_subdir = rel_path:match("/") ~= nil

    local action = vim.fn.filereadable(local_file) == 1 and "replace" or "copy"
    table.insert(files, {
      name = vim.fn.fnamemodify(global_file, ":t"),
      global_path = global_file,
      local_path = local_file,
      action = action,
      is_subdir = is_subdir,
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
    global_dir = M.get_global_dir(),
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

return M

-- neotex.plugins.ai.claude.commands.parser
-- Parse Claude commands from .claude/commands/ directory
-- Extracts metadata and builds hierarchical structure

local M = {}

-- Dependencies
local plenary_path = require("plenary.path")

--- Parse YAML frontmatter from markdown content
--- @param content string The markdown file content
--- @return table|nil Parsed frontmatter or nil if not found
local function parse_frontmatter(content)
  local frontmatter_pattern = "^%-%-%-\n(.-)%-%-%-"
  local frontmatter_text = content:match(frontmatter_pattern)

  if not frontmatter_text then
    return nil
  end

  -- Simple YAML parser for our specific fields
  local metadata = {}

  -- Fields that should be treated as arrays (comma-separated)
  local array_fields = {
    allowed_tools = true,
    dependent_commands = true,
    parent_commands = true,
  }

  for line in frontmatter_text:gmatch("[^\n]+") do
    local key, value = line:match("^([%w%-_]+):%s*(.+)")
    if key and value then
      local normalized_key = key:gsub("%-", "_")

      -- Handle array values (comma-separated) only for specific fields
      if array_fields[normalized_key] and value:find(",") then
        local array = {}
        for item in value:gmatch("([^,]+)") do
          table.insert(array, vim.trim(item))
        end
        metadata[normalized_key] = array
      else
        -- Convert value to string to avoid table concatenation issues
        metadata[normalized_key] = tostring(vim.trim(value))
      end
    end
  end

  return metadata
end

--- Extract command name from filename
--- @param filepath string Full path to command file
--- @return string Command name without .md extension
local function get_command_name(filepath)
  local filename = vim.fn.fnamemodify(filepath, ":t")
  return filename:gsub("%.md$", "")
end

--- Scan .claude/commands/ directory for command files
--- @param commands_dir string Path to commands directory (default: .claude/commands)
--- @return table Array of command file paths
function M.scan_commands_directory(commands_dir)
  commands_dir = commands_dir or ".claude/commands"
  local commands_path = plenary_path:new(commands_dir)

  if not commands_path:exists() then
    return {}
  end

  local command_files = {}

  -- Use scandir instead of iter for directory contents
  local scandir_ok, scan_result = pcall(vim.fn.readdir, commands_dir)
  if not scandir_ok then
    return {}
  end

  for _, filename in ipairs(scan_result) do
    if filename:match("%.md$") then
      table.insert(command_files, filename)
    end
  end

  return command_files
end

--- Parse a single command file
--- @param filepath string Path to the command file
--- @return table|nil Parsed command data or nil if error
function M.parse_command_file(filepath)
  local path = plenary_path:new(filepath)

  if not path:exists() then
    return nil
  end

  local content = path:read()
  if not content then
    return nil
  end

  local metadata = parse_frontmatter(content)
  if not metadata then
    return nil
  end

  local command_name = get_command_name(filepath)

  -- Ensure array fields are always tables
  local function ensure_array(value)
    if type(value) == "string" then
      return {}
    elseif type(value) == "table" then
      return value
    else
      return {}
    end
  end

  return {
    name = command_name,
    filepath = filepath,
    command_type = metadata.command_type or "primary",
    description = metadata.description or "",
    argument_hint = metadata.argument_hint or "",
    allowed_tools = ensure_array(metadata.allowed_tools),
    dependent_commands = ensure_array(metadata.dependent_commands),
    parent_commands = ensure_array(metadata.parent_commands),
  }
end

--- Parse all commands in directory and build data structure
--- @param commands_dir string Path to commands directory (optional)
--- @return table Parsed commands data
function M.parse_all_commands(commands_dir)
  commands_dir = commands_dir or ".claude/commands"

  local command_files = M.scan_commands_directory(commands_dir)
  local parsed_commands = {}

  for _, filename in ipairs(command_files) do
    local filepath = commands_dir .. "/" .. filename
    local command_data = M.parse_command_file(filepath)

    if command_data then
      parsed_commands[command_data.name] = command_data
    end
  end

  return parsed_commands
end

--- Build two-level hierarchy from parsed commands
--- @param commands table Parsed commands from parse_all_commands
--- @return table Hierarchical structure with primary and dependent commands
function M.build_hierarchy(commands)
  local hierarchy = {
    primary_commands = {},
    dependent_commands = {},
  }

  -- First pass: categorize commands
  for name, command in pairs(commands) do
    if command.command_type == "primary" then
      hierarchy.primary_commands[name] = {
        command = command,
        dependents = {}
      }
    else
      hierarchy.dependent_commands[name] = command
    end
  end

  -- Second pass: link dependents to their parents
  for name, dependent in pairs(hierarchy.dependent_commands) do
    local parent_commands = dependent.parent_commands or {}

    -- If no explicit parents, try to infer from dependent_commands in primary commands
    if #parent_commands == 0 then
      for primary_name, primary_data in pairs(hierarchy.primary_commands) do
        local dependent_list = primary_data.command.dependent_commands or {}
        for _, dep_name in ipairs(dependent_list) do
          if dep_name == name then
            table.insert(parent_commands, primary_name)
          end
        end
      end
    end

    -- Link to parent commands
    for _, parent_name in ipairs(parent_commands) do
      if hierarchy.primary_commands[parent_name] then
        table.insert(hierarchy.primary_commands[parent_name].dependents, dependent)
      end
    end
  end

  return hierarchy
end

--- Sort commands alphabetically within hierarchy
--- @param hierarchy table Hierarchical structure from build_hierarchy
--- @return table Sorted hierarchy
function M.sort_hierarchy(hierarchy)
  -- Sort primary commands
  local sorted_primary = {}
  local primary_names = {}

  for name, _ in pairs(hierarchy.primary_commands) do
    table.insert(primary_names, name)
  end
  table.sort(primary_names)

  for _, name in ipairs(primary_names) do
    local primary_data = hierarchy.primary_commands[name]

    -- Sort dependent commands under this primary
    table.sort(primary_data.dependents, function(a, b)
      return a.name < b.name
    end)

    sorted_primary[name] = primary_data
  end

  hierarchy.primary_commands = sorted_primary
  return hierarchy
end

--- Parse commands from both local and global directories with local priority
--- @param project_dir string|nil Path to project-specific commands directory
--- @param global_dir string Path to global commands directory (.config/.claude/commands)
--- @return table Merged commands with is_local flag
function M.parse_with_fallback(project_dir, global_dir)
  local merged_commands = {}
  local local_command_names = {}

  -- Special case: when in .config/, project_dir equals global_dir
  -- In this case, all commands should be marked as local since we're in that directory
  if project_dir and project_dir == global_dir then
    if vim.fn.isdirectory(project_dir) == 1 then
      local commands = M.parse_all_commands(project_dir)
      for name, command in pairs(commands) do
        command.is_local = true  -- Mark as local since we're in this directory
        merged_commands[name] = command
      end
    end
    return merged_commands
  end

  -- Normal case: Parse local project commands first (if directory exists and is different from global)
  if project_dir and project_dir ~= global_dir then
    local project_exists = vim.fn.isdirectory(project_dir) == 1
    if project_exists then
      local local_commands = M.parse_all_commands(project_dir)
      for name, command in pairs(local_commands) do
        command.is_local = true  -- Mark as local command
        merged_commands[name] = command
        local_command_names[name] = true
      end
    end
  end

  -- Parse global commands from .config
  if vim.fn.isdirectory(global_dir) == 1 then
    local global_commands = M.parse_all_commands(global_dir)
    for name, command in pairs(global_commands) do
      -- Only add global command if no local version exists
      if not local_command_names[name] then
        command.is_local = false  -- Mark as global command
        merged_commands[name] = command
      end
    end
  end

  return merged_commands
end

--- Main function to get organized command structure
--- @param commands_dir string Path to commands directory (optional)
--- @return table Organized, sorted command hierarchy
function M.get_command_structure(commands_dir)
  -- For backward compatibility, if a specific dir is passed, use it
  if commands_dir then
    local commands = M.parse_all_commands(commands_dir)
    local hierarchy = M.build_hierarchy(commands)
    return M.sort_hierarchy(hierarchy)
  end

  -- New behavior: check both project and global directories
  local project_dir = vim.fn.getcwd() .. "/.claude/commands"
  local global_dir = vim.fn.expand("~/.config/.claude/commands")

  local commands = M.parse_with_fallback(project_dir, global_dir)
  local hierarchy = M.build_hierarchy(commands)
  return M.sort_hierarchy(hierarchy)
end

return M
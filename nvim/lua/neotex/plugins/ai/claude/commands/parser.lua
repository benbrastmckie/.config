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

  -- Third pass: link primary commands that are listed as dependents of other primary commands
  -- This allows primary commands to show other primary commands as their dependents in the picker
  for primary_name, primary_data in pairs(hierarchy.primary_commands) do
    local dependent_list = primary_data.command.dependent_commands or {}

    for _, dep_name in ipairs(dependent_list) do
      -- Check if this dependent is actually a primary command
      if hierarchy.primary_commands[dep_name] then
        -- Add a reference to the primary command as a dependent
        -- Clone the command data to avoid modifying the original
        local primary_as_dependent = vim.deepcopy(hierarchy.primary_commands[dep_name].command)
        table.insert(primary_data.dependents, primary_as_dependent)
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

--- Scan .claude/agents/ directory for agent files
--- @param agents_dir string Path to agents directory
--- @return table Array of agent metadata
function M.scan_agents_directory(agents_dir)
  local agents_path = plenary_path:new(agents_dir)

  if not agents_path:exists() then
    return {}
  end

  local agent_files = {}

  local scandir_ok, scan_result = pcall(vim.fn.readdir, agents_dir)
  if not scandir_ok then
    return {}
  end

  for _, filename in ipairs(scan_result) do
    if filename:match("%.md$") then
      local filepath = agents_dir .. "/" .. filename
      local path = plenary_path:new(filepath)

      if path:exists() then
        local content = path:read()
        if content then
          local metadata = parse_frontmatter(content)
          if metadata then
            local agent_name = filename:gsub("%.md$", "")
            table.insert(agent_files, {
              name = agent_name,
              description = metadata.description or "",
              allowed_tools = metadata.allowed_tools or {},
              filepath = filepath,
              is_local = false,  -- Will be set by caller
              parent_commands = {}  -- Will be populated by build_agent_dependencies
            })
          end
        end
      end
    end
  end

  return agent_files
end

--- Scan .claude/hooks/ directory for hook scripts
--- @param hooks_dir string Path to hooks directory
--- @return table Array of hook metadata
function M.scan_hooks_directory(hooks_dir)
  local hooks_path = plenary_path:new(hooks_dir)

  if not hooks_path:exists() then
    return {}
  end

  local hook_files = {}

  local scandir_ok, scan_result = pcall(vim.fn.readdir, hooks_dir)
  if not scandir_ok then
    return {}
  end

  for _, filename in ipairs(scan_result) do
    if filename:match("%.sh$") then
      local filepath = hooks_dir .. "/" .. filename
      local path = plenary_path:new(filepath)

      if path:exists() then
        -- Parse header comments for description
        local content = path:read()
        local description = ""

        if content then
          -- Look for "# Purpose:" line in header
          for line in content:gmatch("[^\n]+") do
            local purpose = line:match("^#%s*Purpose:%s*(.+)")
            if purpose then
              description = vim.trim(purpose)
              break
            end
          end
        end

        table.insert(hook_files, {
          name = filename,
          description = description,
          filepath = filepath,
          is_local = false,  -- Will be set by caller
          events = {}  -- Will be populated by build_hook_dependencies
        })
      end
    end
  end

  return hook_files
end

--- Scan for TTS files across multiple .claude/ subdirectories
--- @param base_dir string Base directory path (project or global)
--- @return table Array of tts_file metadata
function M.scan_tts_files(base_dir)
  local base_path = plenary_path:new(base_dir) / ".claude"

  if not base_path:exists() then
    return {}
  end

  -- TTS directories and their roles (consolidated to 2 directories)
  local tts_directories = {
    { subdir = "hooks", role = "dispatcher" },
    { subdir = "tts", role = nil }  -- Role determined by filename
  }

  local tts_files = {}

  for _, dir_spec in ipairs(tts_directories) do
    local dir_path = base_path / dir_spec.subdir

    if dir_path:exists() then
      local scandir_ok, files = pcall(vim.fn.readdir, dir_path:absolute())
      if scandir_ok then
        for _, filename in ipairs(files) do
          -- Match tts-*.sh only (exclude test-tts.sh as it's in bin/)
          if filename:match("^tts%-.*%.sh$") then
            local filepath = dir_path:absolute() .. "/" .. filename
            local path = plenary_path:new(filepath)

            if path:exists() then
              local content = path:read()
              local description = ""
              local variables = {}

              if content then
                -- Extract description from header comment
                for line in content:gmatch("[^\n]+") do
                  local desc = line:match("^#%s*(.+)")
                  if desc and not desc:match("^!/") then  -- Skip shebang
                    description = vim.trim(desc)
                    break  -- Use first comment as description
                  end

                  -- Extract TTS_* variables for config files
                  if filename:match("config") then
                    local var = line:match("^([A-Z_]+)=")
                    if var and var:match("^TTS_") then
                      table.insert(variables, var)
                    end
                  end
                end

                -- Determine role based on directory and filename
                local role = dir_spec.role  -- "dispatcher" for hooks/
                if not role then  -- tts/ directory
                  if filename:match("config") then
                    role = "config"
                  elseif filename:match("messages") then
                    role = "library"
                  else
                    role = "library"  -- Default for tts/
                  end
                end

                table.insert(tts_files, {
                  name = filename,
                  description = description ~= "" and description or "TTS system file",
                  filepath = filepath,
                  is_local = false,  -- Set by caller
                  role = role,  -- config|dispatcher|library
                  directory = dir_spec.subdir,  -- hooks|tts
                  variables = variables,  -- For config files
                  line_count = select(2, content:gsub("\n", "\n")) + 1
                })
              end
            end
          end
        end
      end
    end
  end

  return tts_files
end

--- Build command → agents dependency map
--- @param commands table Parsed commands
--- @param agents table Agent data
--- @return table Map of command name → agents used
function M.build_agent_dependencies(commands, agents)
  local agent_deps = {}

  -- For each command, find which agents it uses
  for cmd_name, command in pairs(commands) do
    local cmd_filepath = command.filepath

    if cmd_filepath and vim.fn.filereadable(cmd_filepath) == 1 then
      local content = vim.fn.readfile(cmd_filepath)
      local agents_used = {}

      -- Search for subagent_type: references
      for _, line in ipairs(content) do
        local agent_type = line:match("subagent_type:%s*[\"']?([a-z%-]+)[\"']?")
        if agent_type then
          agents_used[agent_type] = true
        end
      end

      -- Convert to array and store
      local agents_list = {}
      for agent_name, _ in pairs(agents_used) do
        table.insert(agents_list, agent_name)
      end

      if #agents_list > 0 then
        agent_deps[cmd_name] = agents_list
      end
    end
  end

  -- Build reverse mapping: agent → commands that use it
  for _, agent in ipairs(agents) do
    agent.parent_commands = {}
    for cmd_name, agents_list in pairs(agent_deps) do
      for _, agent_name in ipairs(agents_list) do
        if agent_name == agent.name then
          table.insert(agent.parent_commands, cmd_name)
        end
      end
    end
  end

  return agent_deps
end

--- Build hook event → hooks dependency map
--- @param hooks table Hook data
--- @param settings_path string Path to settings.local.json
--- @return table Map of event name → hooks triggered
function M.build_hook_dependencies(hooks, settings_path)
  local hook_events = {}

  -- Try to read settings.local.json
  if vim.fn.filereadable(settings_path) ~= 1 then
    return hook_events
  end

  local settings_content = table.concat(vim.fn.readfile(settings_path), "\n")
  local ok, settings = pcall(vim.fn.json_decode, settings_content)

  if not ok or not settings or not settings.hooks then
    return hook_events
  end

  -- Parse hooks section
  for event_name, event_configs in pairs(settings.hooks) do
    hook_events[event_name] = {}

    for _, config in ipairs(event_configs) do
      if config.hooks then
        for _, hook_config in ipairs(config.hooks) do
          if hook_config.command then
            -- Extract hook script name from command
            local hook_name = hook_config.command:match("([^/]+%.sh)$")
            if hook_name then
              table.insert(hook_events[event_name], hook_name)
            end
          end
        end
      end
    end
  end

  -- Update hooks with their events
  for _, hook in ipairs(hooks) do
    hook.events = {}
    for event_name, hook_names in pairs(hook_events) do
      for _, hook_name in ipairs(hook_names) do
        if hook_name == hook.name then
          table.insert(hook.events, event_name)
        end
      end
    end
  end

  return hook_events
end

--- Parse agents from both local and global directories with local priority
--- @param project_agents_dir string Path to project-specific agents directory
--- @param global_agents_dir string Path to global agents directory
--- @return table Merged agents with is_local flag
local function parse_agents_with_fallback(project_agents_dir, global_agents_dir)
  local merged_agents = {}
  local local_agent_names = {}

  -- Special case: when in .config/, project_agents_dir equals global_agents_dir
  -- In this case, all agents should be marked as local since we're in that directory
  if project_agents_dir and project_agents_dir == global_agents_dir then
    if vim.fn.isdirectory(project_agents_dir) == 1 then
      local agents = M.scan_agents_directory(project_agents_dir)
      for _, agent in ipairs(agents) do
        agent.is_local = true  -- Mark as local since we're in this directory
        table.insert(merged_agents, agent)
      end
    end
    return merged_agents
  end

  -- Normal case: Parse local agents first
  if vim.fn.isdirectory(project_agents_dir) == 1 then
    local local_agents = M.scan_agents_directory(project_agents_dir)
    for _, agent in ipairs(local_agents) do
      agent.is_local = true
      table.insert(merged_agents, agent)
      local_agent_names[agent.name] = true
    end
  end

  -- Parse global agents
  if vim.fn.isdirectory(global_agents_dir) == 1 then
    local global_agents = M.scan_agents_directory(global_agents_dir)
    for _, agent in ipairs(global_agents) do
      if not local_agent_names[agent.name] then
        agent.is_local = false
        table.insert(merged_agents, agent)
      end
    end
  end

  return merged_agents
end

--- Parse hooks from both local and global directories with local priority
--- @param project_hooks_dir string Path to project-specific hooks directory
--- @param global_hooks_dir string Path to global hooks directory
--- @return table Merged hooks with is_local flag
local function parse_hooks_with_fallback(project_hooks_dir, global_hooks_dir)
  local merged_hooks = {}
  local local_hook_names = {}

  -- Special case: when in .config/, project_hooks_dir equals global_hooks_dir
  -- In this case, all hooks should be marked as local since we're in that directory
  if project_hooks_dir and project_hooks_dir == global_hooks_dir then
    if vim.fn.isdirectory(project_hooks_dir) == 1 then
      local hooks = M.scan_hooks_directory(project_hooks_dir)
      for _, hook in ipairs(hooks) do
        hook.is_local = true  -- Mark as local since we're in this directory
        table.insert(merged_hooks, hook)
      end
    end
    return merged_hooks
  end

  -- Normal case: Parse local hooks first
  if vim.fn.isdirectory(project_hooks_dir) == 1 then
    local local_hooks = M.scan_hooks_directory(project_hooks_dir)
    for _, hook in ipairs(local_hooks) do
      hook.is_local = true
      table.insert(merged_hooks, hook)
      local_hook_names[hook.name] = true
    end
  end

  -- Parse global hooks
  if vim.fn.isdirectory(global_hooks_dir) == 1 then
    local global_hooks = M.scan_hooks_directory(global_hooks_dir)
    for _, hook in ipairs(global_hooks) do
      if not local_hook_names[hook.name] then
        hook.is_local = false
        table.insert(merged_hooks, hook)
      end
    end
  end

  return merged_hooks
end

--- Parse TTS files from both local and global directories with local priority
--- @param project_dir string Path to project directory
--- @param global_dir string Path to global directory
--- @return table Merged TTS files with is_local flag
local function parse_tts_files_with_fallback(project_dir, global_dir)
  -- Special case: when in .config/, project_dir equals global_dir
  -- In this case, all TTS files should be marked as local since we're in that directory
  if project_dir and project_dir == global_dir then
    local files = M.scan_tts_files(project_dir)
    for _, file in ipairs(files) do
      file.is_local = true  -- Mark as local since we're in this directory
    end
    return files
  end

  -- Normal case: Parse local and global TTS files
  local local_files = M.scan_tts_files(project_dir)
  local global_files = M.scan_tts_files(global_dir)

  -- Mark local files
  for _, file in ipairs(local_files) do
    file.is_local = true
  end

  -- Merge: local overrides global by name
  local merged = {}
  local seen = {}

  for _, file in ipairs(local_files) do
    merged[#merged + 1] = file
    seen[file.name] = true
  end

  for _, file in ipairs(global_files) do
    if not seen[file.name] then
      merged[#merged + 1] = file
    end
  end

  return merged
end

--- Get extended structure with commands, agents, hooks, and TTS files
--- @return table Structure with commands, agents, hooks, TTS files, and dependencies
function M.get_extended_structure()
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Get command structure (existing functionality)
  local project_commands_dir = project_dir .. "/.claude/commands"
  local global_commands_dir = global_dir .. "/.claude/commands"
  local commands = M.parse_with_fallback(project_commands_dir, global_commands_dir)
  local hierarchy = M.build_hierarchy(commands)
  local sorted_hierarchy = M.sort_hierarchy(hierarchy)

  -- Get agents
  local project_agents_dir = project_dir .. "/.claude/agents"
  local global_agents_dir = global_dir .. "/.claude/agents"
  local agents = parse_agents_with_fallback(project_agents_dir, global_agents_dir)

  -- Get hooks
  local project_hooks_dir = project_dir .. "/.claude/hooks"
  local global_hooks_dir = global_dir .. "/.claude/hooks"
  local hooks = parse_hooks_with_fallback(project_hooks_dir, global_hooks_dir)

  -- Get TTS files from multiple directories
  local tts_files = parse_tts_files_with_fallback(project_dir, global_dir)

  -- Build dependencies
  local agent_deps = M.build_agent_dependencies(commands, agents)

  local settings_path = project_dir .. "/.claude/settings.local.json"
  if vim.fn.filereadable(settings_path) ~= 1 then
    settings_path = global_dir .. "/.claude/settings.local.json"
  end
  local hook_events = M.build_hook_dependencies(hooks, settings_path)

  -- Return extended structure
  return {
    -- Existing command hierarchy
    primary_commands = sorted_hierarchy.primary_commands,
    dependent_commands = sorted_hierarchy.dependent_commands,

    -- Agents, hooks, and TTS files
    agents = agents,
    hooks = hooks,
    tts_files = tts_files,
    agent_dependencies = agent_deps,
    hook_events = hook_events
  }
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
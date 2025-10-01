---@class AgentDefinition
---@field name string Agent identifier from filename
---@field description string Brief description from frontmatter
---@field allowed_tools string[] List of allowed tools
---@field system_prompt string Full system prompt content
---@field filepath string Full path to agent file

local Path = require("plenary.path")

local M = {}

-- Cache for agent definitions
local agent_cache = nil

---Parse YAML frontmatter from markdown content
---@param content string The markdown file content
---@return table|nil Parsed frontmatter or nil if not found
local function parse_frontmatter(content)
  local frontmatter_pattern = "^%-%-%-\n(.-)%-%-%-"
  local frontmatter_text = content:match(frontmatter_pattern)

  if not frontmatter_text then
    return nil
  end

  local metadata = {}

  for line in frontmatter_text:gmatch("[^\n]+") do
    local key, value = line:match("^([%w%-_]+):%s*(.+)")
    if key and value then
      local normalized_key = key:gsub("%-", "_")

      -- Handle comma-separated values for allowed-tools
      if normalized_key == "allowed_tools" then
        local array = {}
        for item in value:gmatch("([^,]+)") do
          local trimmed = vim.trim(item)
          if trimmed ~= "" then
            table.insert(array, trimmed)
          end
        end
        metadata[normalized_key] = array
      else
        metadata[normalized_key] = tostring(vim.trim(value))
      end
    end
  end

  return metadata
end

---Scan a directory for agent files
---@param agents_dir string Path to agents directory
---@return AgentDefinition[] List of agent definitions
local function scan_agent_directory(agents_dir)
  local agents = {}
  local agents_path = Path:new(agents_dir)

  if not agents_path:exists() or not agents_path:is_dir() then
    return agents
  end

  -- Find all .md files in agents directory
  local agent_files = vim.fn.glob(agents_dir .. "/*.md", false, true)

  for _, filepath in ipairs(agent_files) do
    local agent = M.parse_agent_file(filepath)
    if agent then
      table.insert(agents, agent)
    end
  end

  return agents
end

---Parse an agent file and extract definition
---@param filepath string Full path to agent file
---@return AgentDefinition|nil Agent definition or nil on error
function M.parse_agent_file(filepath)
  local success, result = pcall(function()
    local path = Path:new(filepath)
    if not path:exists() then
      return nil
    end

    -- Read file content
    local content = path:read()
    if not content or content == "" then
      return nil
    end

    -- Extract filename without extension as agent name
    local filename = vim.fn.fnamemodify(filepath, ":t:r")

    -- Parse YAML frontmatter
    local frontmatter = parse_frontmatter(content)
    if not frontmatter then
      return nil
    end

    -- Extract system prompt (everything after frontmatter)
    local system_prompt = ""
    local lines = vim.split(content, "\n")
    local in_frontmatter = false
    local frontmatter_end = false
    local prompt_lines = {}

    for _, line in ipairs(lines) do
      if line:match("^%-%-%-") then
        if not in_frontmatter then
          in_frontmatter = true
        else
          frontmatter_end = true
        end
      elseif frontmatter_end then
        table.insert(prompt_lines, line)
      end
    end

    system_prompt = table.concat(prompt_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")

    -- Build agent definition
    return {
      name = filename,
      description = frontmatter.description or "",
      allowed_tools = frontmatter.allowed_tools or {},
      system_prompt = system_prompt,
      filepath = filepath,
    }
  end)

  if not success then
    vim.notify("Error parsing agent file: " .. filepath .. "\n" .. tostring(result), vim.log.levels.ERROR)
    return nil
  end

  return result
end

---Scan agent directories and build registry
---@return table<string, AgentDefinition> Map of agent name to definition
local function build_agent_registry()
  local registry = {}

  -- Scan global agents directory
  local global_agents_dir = vim.fn.expand("~/.config/.claude/agents")
  local global_agents = scan_agent_directory(global_agents_dir)

  for _, agent in ipairs(global_agents) do
    registry[agent.name] = agent
  end

  -- Scan project agents directory (overrides global)
  local project_root = vim.fn.getcwd()
  local project_agents_dir = project_root .. "/.claude/agents"
  local project_agents = scan_agent_directory(project_agents_dir)

  for _, agent in ipairs(project_agents) do
    registry[agent.name] = agent
  end

  return registry
end

---Get agent definition by name
---@param name string Agent name
---@return AgentDefinition|nil Agent definition or nil if not found
function M.get_agent(name)
  -- Lazy load registry on first access
  if not agent_cache then
    agent_cache = build_agent_registry()
  end

  return agent_cache[name]
end

---List all available agent names
---@return string[] Sorted list of agent names
function M.list_agents()
  -- Lazy load registry on first access
  if not agent_cache then
    agent_cache = build_agent_registry()
  end

  local names = {}
  for name, _ in pairs(agent_cache) do
    table.insert(names, name)
  end

  table.sort(names)
  return names
end

---Validate if an agent exists
---@param name string Agent name
---@return boolean True if agent exists
function M.validate_agent(name)
  return M.get_agent(name) ~= nil
end

---Get only the system prompt for an agent
---@param name string Agent name
---@return string|nil System prompt or nil if agent not found
function M.get_agent_prompt(name)
  local agent = M.get_agent(name)
  if not agent then
    return nil
  end
  return agent.system_prompt
end

---Reload the agent registry (clear cache and rescan)
function M.reload_registry()
  agent_cache = nil
  agent_cache = build_agent_registry()
end

---Get agent tools list
---@param name string Agent name
---@return string[]|nil List of allowed tools or nil if agent not found
function M.get_agent_tools(name)
  local agent = M.get_agent(name)
  if not agent then
    return nil
  end
  return agent.allowed_tools
end

---Get agent metadata without full prompt
---@param name string Agent name
---@return table|nil Agent info (name, description, allowed_tools, filepath) or nil
function M.get_agent_info(name)
  local agent = M.get_agent(name)
  if not agent then
    return nil
  end

  return {
    name = agent.name,
    description = agent.description,
    allowed_tools = agent.allowed_tools,
    filepath = agent.filepath,
  }
end

---Format a task prompt by combining agent system prompt with task description and context
---@param agent_name string Name of the agent to use
---@param task_description string Brief description of the task
---@param context string|nil Optional additional context for the task
---@return string|nil Formatted prompt or nil if agent not found
function M.format_task_prompt(agent_name, task_description, context)
  local agent = M.get_agent(agent_name)
  if not agent then
    return nil
  end

  local prompt_parts = {
    agent.system_prompt,
    "",
    "Task: " .. task_description,
  }

  if context and context ~= "" then
    table.insert(prompt_parts, "")
    table.insert(prompt_parts, "Context:")
    table.insert(prompt_parts, context)
  end

  return table.concat(prompt_parts, "\n")
end

---Create a complete task configuration for use with Task tool
---@param agent_name string Name of the agent to use
---@param task_description string Brief description of the task (will be used for description field)
---@param context string|nil Optional additional context for the task
---@return table|nil Task config {subagent_type, description, prompt} or nil if agent not found
function M.create_task_config(agent_name, task_description, context)
  local prompt = M.format_task_prompt(agent_name, task_description, context)
  if not prompt then
    return nil
  end

  -- Generate 3-5 word description from task_description
  local words = {}
  for word in task_description:gmatch("%S+") do
    table.insert(words, word)
    if #words >= 5 then
      break
    end
  end
  local short_description = table.concat(words, " ")

  return {
    subagent_type = "general-purpose",
    description = short_description,
    prompt = prompt,
  }
end

return M

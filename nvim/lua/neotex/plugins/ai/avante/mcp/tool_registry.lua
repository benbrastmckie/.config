local M = {}

-- Tool metadata registry with comprehensive tool definitions
M.tool_registry = {
  -- Context7 tools for documentation
  context7_resolve = {
    server = "context7",
    tool_name = "resolve-library-id",
    category = "documentation",
    priority = "high",
    tokens_cost = 45,
    description = "Resolves library names to Context7 IDs for documentation lookup",
    usage_pattern = "automatic_on_library_mention",
    personas = { "researcher", "coder", "expert", "tutor" },
    trigger_keywords = { "library", "framework", "documentation", "docs", "api" }
  },
  
  context7_docs = {
    server = "context7",
    tool_name = "get-library-docs",
    category = "documentation",
    priority = "high", 
    tokens_cost = 60,
    description = "Retrieves detailed documentation for specific topics from library docs",
    usage_pattern = "automatic_after_resolve",
    personas = { "researcher", "coder", "expert", "tutor" },
    trigger_keywords = { "how to", "usage", "example", "implementation", "tutorial" }
  },

  -- Tavily tools for web search
  tavily_search = {
    server = "tavily",
    tool_name = "search",
    category = "search",
    priority = "high",
    tokens_cost = 50,
    description = "AI-optimized web search for current information and trends",
    usage_pattern = "automatic_on_current_info",
    personas = { "researcher", "expert", "tutor" },
    trigger_keywords = { "recent", "latest", "current", "news", "trends", "2024", "2025" }
  },

  tavily_extract = {
    server = "tavily",
    tool_name = "extract",
    category = "search",
    priority = "medium",
    tokens_cost = 40,
    description = "Extracts detailed content from specific URLs",
    usage_pattern = "on_demand",
    personas = { "researcher", "expert" },
    trigger_keywords = { "extract", "content", "article", "detailed" }
  },

  -- GitHub tools for development
  github_tools = {
    server = "github",
    tool_name = "various",
    category = "development",
    priority = "medium",
    tokens_cost = 70,
    description = "GitHub repository management, issues, PRs, and code analysis",
    usage_pattern = "on_mention",
    personas = { "coder", "expert" },
    trigger_keywords = { "github", "repository", "repo", "issues", "pull request", "pr" }
  },

  -- Git tools for version control
  git_tools = {
    server = "git",
    tool_name = "various",
    category = "development", 
    priority = "medium",
    tokens_cost = 55,
    description = "Git version control operations and repository management",
    usage_pattern = "on_mention",
    personas = { "coder", "expert" },
    trigger_keywords = { "git", "commit", "branch", "merge", "version control" }
  },

  -- Web tools
  fetch_tools = {
    server = "fetch",
    tool_name = "various",
    category = "web",
    priority = "low",
    tokens_cost = 45,
    description = "Web content fetching and HTTP operations",
    usage_pattern = "on_mention",
    personas = { "researcher", "coder" },
    trigger_keywords = { "fetch", "http", "web content", "download" }
  },

  agentql_tools = {
    server = "agentql", 
    tool_name = "various",
    category = "web",
    priority = "low",
    tokens_cost = 65,
    description = "Advanced web scraping and data extraction",
    usage_pattern = "on_mention",
    personas = { "coder", "researcher" },
    trigger_keywords = { "scrape", "extract", "web scraping", "agentql" }
  },

  brave_search = {
    server = "brave-search",
    tool_name = "search",
    category = "search",
    priority = "low", 
    tokens_cost = 40,
    description = "Brave search engine for web queries",
    usage_pattern = "fallback",
    personas = { "researcher" },
    trigger_keywords = { "brave search", "search engine" }
  }
}

-- Smart defaults configuration
M.smart_defaults = {
  persona_defaults = {
    researcher = { 
      "context7_resolve", "context7_docs", "tavily_search"
    },
    coder = { 
      "context7_resolve", "context7_docs", "github_tools"
    },
    expert = { 
      "context7_resolve", "context7_docs", "tavily_search", "git_tools"
    },
    tutor = { 
      "context7_resolve", "context7_docs", "tavily_search"
    }
  },
  
  dynamic_enhancers = {
    mention_triggers = {
      ["github"] = { "github_tools" },
      ["git"] = { "git_tools" },
      ["web scraping"] = { "agentql_tools", "fetch_tools" },
      ["scrape"] = { "agentql_tools" },
      ["current events"] = { "tavily_search", "tavily_extract" },
      ["recent"] = { "tavily_search" },
      ["latest"] = { "tavily_search" },
      ["2024"] = { "tavily_search" },
      ["2025"] = { "tavily_search" },
      ["fetch"] = { "fetch_tools" },
      ["http"] = { "fetch_tools" },
      ["brave"] = { "brave_search" }
    },
    
    keyword_triggers = {
      documentation = { "context7_resolve", "context7_docs" },
      search = { "tavily_search" },
      development = { "github_tools", "git_tools" },
      web = { "fetch_tools", "agentql_tools" }
    }
  }
}

-- Context budgeting configuration
M.context_budget = {
  max_tokens = 2000,        -- Maximum tokens for tool descriptions
  essential_reserve = 500,   -- Reserve for essential tools
  adaptive_threshold = 0.8,  -- When to start being more selective
  min_tools = 3,            -- Minimum tools to always include
  max_tools = 8             -- Maximum tools to prevent bloat
}

-- Utility functions
local function table_contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

local function merge_unique(table1, table2)
  local result = {}
  local seen = {}
  
  -- Add items from first table
  for _, item in ipairs(table1) do
    if not seen[item] then
      table.insert(result, item)
      seen[item] = true
    end
  end
  
  -- Add items from second table
  for _, item in ipairs(table2) do
    if not seen[item] then
      table.insert(result, item)
      seen[item] = true
    end
  end
  
  return result
end

local function conversation_mentions(conversation_context, trigger)
  if not conversation_context or type(conversation_context) ~= "string" then
    return false
  end
  return string.find(conversation_context:lower(), trigger:lower()) ~= nil
end

local function calculate_tools_token_cost(tool_list)
  local total_cost = 0
  for _, tool_id in ipairs(tool_list) do
    local tool = M.tool_registry[tool_id]
    if tool then
      total_cost = total_cost + tool.tokens_cost
    end
  end
  return total_cost
end

local function prioritize_tools(tool_list)
  local priority_order = { high = 1, medium = 2, low = 3 }
  
  table.sort(tool_list, function(a, b)
    local tool_a = M.tool_registry[a]
    local tool_b = M.tool_registry[b]
    
    if not tool_a or not tool_b then return false end
    
    local priority_a = priority_order[tool_a.priority] or 3
    local priority_b = priority_order[tool_b.priority] or 3
    
    return priority_a < priority_b
  end)
  
  return tool_list
end

-- Main function to select tools based on persona and context
function M.select_tools(persona, conversation_context)
  local base_tools = M.smart_defaults.persona_defaults[persona] or M.smart_defaults.persona_defaults["expert"]
  local enhanced_tools = {}
  
  -- Add tools based on conversation mentions
  if conversation_context then
    for trigger, tools in pairs(M.smart_defaults.dynamic_enhancers.mention_triggers) do
      if conversation_mentions(conversation_context, trigger) then
        enhanced_tools = merge_unique(enhanced_tools, tools)
      end
    end
  end
  
  -- Merge base and enhanced tools
  local all_tools = merge_unique(base_tools, enhanced_tools)
  
  -- Prioritize tools
  all_tools = prioritize_tools(all_tools)
  
  -- Apply context budgeting
  local final_tools = {}
  local current_cost = 0
  local budget = M.context_budget.max_tokens
  
  -- Always include minimum number of high-priority tools
  local essential_count = 0
  for _, tool_id in ipairs(all_tools) do
    local tool = M.tool_registry[tool_id]
    if tool and tool.priority == "high" and essential_count < M.context_budget.min_tools then
      table.insert(final_tools, tool_id)
      current_cost = current_cost + tool.tokens_cost
      essential_count = essential_count + 1
    end
  end
  
  -- Add remaining tools within budget
  for _, tool_id in ipairs(all_tools) do
    if not table_contains(final_tools, tool_id) then
      local tool = M.tool_registry[tool_id]
      if tool and (current_cost + tool.tokens_cost) <= budget and #final_tools < M.context_budget.max_tools then
        table.insert(final_tools, tool_id)
        current_cost = current_cost + tool.tokens_cost
      end
    end
  end
  
  return final_tools
end

-- Generate tool descriptions for selected tools
function M.generate_tool_descriptions(selected_tools)
  local descriptions = {}
  
  for _, tool_id in ipairs(selected_tools) do
    local tool = M.tool_registry[tool_id]
    if tool then
      local desc = string.format(
        "- %s (%s): %s",
        tool_id,
        tool.server,
        tool.description
      )
      table.insert(descriptions, desc)
    end
  end
  
  return table.concat(descriptions, "\n")
end

-- Generate MCP tool usage instructions
function M.generate_mcp_instructions(selected_tools)
  local servers = {}
  local has_context7 = false
  local has_tavily = false
  
  -- Collect unique servers from selected tools and check for specific tools
  for _, tool_id in ipairs(selected_tools) do
    local tool = M.tool_registry[tool_id]
    if tool then
      if not table_contains(servers, tool.server) then
        table.insert(servers, tool.server)
      end
      if tool.server == "context7" then
        has_context7 = true
      elseif tool.server == "tavily" then
        has_tavily = true
      end
    end
  end
  
  local instructions = "MCP TOOLS AVAILABLE:\n\n"
  instructions = instructions .. "IMPORTANT: You must ONLY use the MCP tools provided below. Do NOT use any built-in web search tools.\n\n"
  instructions = instructions .. "Use 'use_mcp_tool' with these parameters:\n"
  instructions = instructions .. "- server_name: " .. table.concat(servers, ", ") .. "\n"
  instructions = instructions .. "- tool_name: Specific tool name for the operation\n"
  instructions = instructions .. "- tool_input: Parameters required for the tool\n\n"
  
  -- Add specific usage patterns based on available tools
  if has_context7 then
    instructions = instructions .. "MANDATORY: For ANY library, framework, or API documentation questions, you MUST use Context7:\n"
    instructions = instructions .. "STEP 1: resolve-library-id with libraryName parameter (React, Vue, Next.js, Express, etc.)\n"
    instructions = instructions .. "STEP 2: get-library-docs with context7CompatibleLibraryID from step 1 and topic parameter\n"
    instructions = instructions .. "CORRECT PARAMETERS: libraryName (not library_name), context7CompatibleLibraryID (not libraryId)\n"
    instructions = instructions .. "This includes: React, Vue, Next.js, Express, TypeScript, Angular, Prisma, etc.\n\n"
  end
  
  if has_tavily then
    instructions = instructions .. "For current information, news, or recent trends (containing 'latest', 'recent', '2024', '2025'), use Tavily search.\n\n"
  end
  
  instructions = instructions .. "AVAILABLE TOOLS:\n"
  instructions = instructions .. M.generate_tool_descriptions(selected_tools)
  
  -- Add mandatory usage rules
  instructions = instructions .. "\n\nMANDATORY USAGE RULES:\n"
  if has_context7 then
    instructions = instructions .. "🔴 REQUIRED: Any question about libraries/frameworks/APIs → MUST use Context7 (never web search)\n"
    instructions = instructions .. "Examples requiring Context7: 'Next.js authentication', 'Vue routing', 'React hooks'\n"
  end
  if has_tavily then
    instructions = instructions .. "🔵 When user asks about current events/trends → Use Tavily\n"
  end
  instructions = instructions .. "🚫 DO NOT use any built-in web search tools when MCP tools are available\n"
  
  return instructions
end

-- Generate context-aware system prompt addition
function M.generate_context_aware_prompt(persona, conversation_context)
  local selected_tools = M.select_tools(persona, conversation_context)
  local mcp_instructions = M.generate_mcp_instructions(selected_tools)
  
  return mcp_instructions
end

-- Get tool metadata
function M.get_tool_metadata(tool_id)
  return M.tool_registry[tool_id]
end

-- Get all tools for a category
function M.get_tools_by_category(category)
  local tools = {}
  for tool_id, tool in pairs(M.tool_registry) do
    if tool.category == category then
      table.insert(tools, tool_id)
    end
  end
  return tools
end

-- Get tools suitable for a persona
function M.get_tools_by_persona(persona)
  local tools = {}
  for tool_id, tool in pairs(M.tool_registry) do
    if table_contains(tool.personas, persona) then
      table.insert(tools, tool_id)
    end
  end
  return tools
end

return M
-- Lualine Extension for Claude Code Terminal Buffers
-- Displays context usage, model, cost, and cursor position
local M = {}

-- Color definitions based on usage thresholds
local colors = {
  low = "#98c379",     -- Green: < 50%
  medium = "#e5c07b",  -- Yellow: 50-80%
  high = "#e06c75",    -- Red: > 80%
  neutral = "#61afef", -- Blue: model/cost info
  muted = "#5c6370",   -- Gray: secondary info
}

--- Get color based on usage level
--- @param level string "low", "medium", "high", or "unknown"
--- @return string Hex color code
local function get_usage_color(level)
  return colors[level] or colors.neutral
end

--- Context component with percentage, progress bar, and token counts
local function context_component()
  local ok, ctx_module = pcall(require, "neotex.util.claude-context")
  if not ok then
    return ""
  end

  local ctx = ctx_module.get_context()
  if not ctx then
    return ""
  end

  -- Format: 42% [████░░░░░░] 85k/200k
  local pct_str = ctx_module.get_percentage_str()
  local bar = ctx_module.get_progress_bar(10)
  local tokens = ctx_module.get_tokens_str()

  if pct_str == "" then
    return ""
  end

  return string.format("%s [%s] %s", pct_str, bar, tokens)
end

--- Context component with dynamic color
local function context_colored()
  return {
    context_component,
    color = function()
      local ok, ctx_module = pcall(require, "neotex.util.claude-context")
      if not ok then
        return { fg = colors.neutral }
      end
      local level = ctx_module.get_usage_level()
      return { fg = get_usage_color(level), gui = "bold" }
    end,
  }
end

--- Model component
local function model_component()
  local ok, ctx_module = pcall(require, "neotex.util.claude-context")
  if not ok then
    return ""
  end
  return ctx_module.get_model()
end

--- Cost component
local function cost_component()
  local ok, ctx_module = pcall(require, "neotex.util.claude-context")
  if not ok then
    return ""
  end
  return ctx_module.get_cost_str()
end

--- Model and cost combined component
local function model_cost_component()
  local ok, ctx_module = pcall(require, "neotex.util.claude-context")
  if not ok then
    return ""
  end

  local model = ctx_module.get_model()
  local cost = ctx_module.get_cost_str()

  if model == "" and cost == "" then
    return ""
  elseif model == "" then
    return cost
  elseif cost == "" then
    return model
  else
    return string.format("%s | %s", model, cost)
  end
end

--- Check if current buffer is a Claude Code terminal
local function is_claude_terminal()
  if vim.bo.buftype ~= "terminal" then
    return false
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  return bufname:match("claude") or bufname:match("ClaudeCode")
end

--- Check if context data is available
local function has_context()
  local ok, ctx_module = pcall(require, "neotex.util.claude-context")
  if not ok then
    return false
  end
  return ctx_module.has_context()
end

-- Build the extension
M.sections = {
  lualine_a = { "mode" },
  lualine_b = {},
  lualine_c = {
    {
      function()
        return "TERMINAL"
      end,
      color = { fg = colors.neutral, gui = "bold" },
    },
    context_colored(),
  },
  lualine_x = {
    {
      model_cost_component,
      color = { fg = colors.neutral },
    },
  },
  lualine_y = {},
  lualine_z = { "location" },
}

M.inactive_sections = {
  lualine_a = {},
  lualine_b = {},
  lualine_c = {
    {
      function()
        return "TERMINAL (Claude)"
      end,
      color = { fg = colors.muted },
    },
  },
  lualine_x = {},
  lualine_y = {},
  lualine_z = {},
}

-- Filetypes that this extension applies to
M.filetypes = { "claude-code" }

return M

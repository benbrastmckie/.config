-----------------------------------------------------------
-- NeoVim Plugin Specification Loader
-- 
-- This module organizes and loads plugin specifications by category.
-- It provides a structured way to manage plugins while maintaining
-- backward compatibility with the previous organization.
--
-- Plugin Categories:
-- - coding: Code editing enhancements (syntax, completion, etc.)
-- - editor: Core editor capabilities (navigation, search, etc.)
-- - lsp: Language server integration and configuration
-- - tools: External tool integration (git, terminal, etc.)
-- - ui: User interface components (statusline, colors, etc.)
-- - extras: Optional functionality that can be enabled/disabled
--
-- The module uses a consistent error handling approach to ensure
-- NeoVim starts properly even if some plugin specifications fail.
-- Each plugin is loaded from its own module in the plugins/ directory.
-----------------------------------------------------------

-- Categorize existing plugins for easy management
-- This still loads the existing plugin configurations but organizes them
local categories = {
  coding = {
    "autopairs",     -- Auto-close pairs of characters
    "comment",       -- Comment toggling
    "luasnip",       -- Snippet engine
    "surround",      -- Surround text with characters
    "treesitter",    -- Advanced syntax highlighting
  },
  
  editor = {
    "autolist",      -- Smart list handling
    "lean",          -- Lean theorem prover support
    "local-highlight", -- Highlight current word occurrences
    "mini",          -- Mini plugins bundle
    "nvim-tree",     -- File explorer
    "sessions",      -- Session management
    "telescope",     -- Fuzzy finder
    "which-key",     -- Keybinding helper
    "yanky",         -- Yanking and clipboard manager
  },
  
  lsp = {
    -- These are imported from neotex.plugins.lsp directly
  },
  
  tools = {
    "firenvim",      -- Browser integration
    "gitsigns",      -- Git integration
    "lectic",        -- AI integration
    "avante",        -- AI integration
    "markdown-preview", -- Markdown preview
    "toggleterm",    -- Terminal integration
    "vimtex",        -- LaTeX support
  },
  
  ui = {
    "bufferline",    -- Buffer tabs
    "colorscheme",   -- Color scheme
    "lualine",       -- Status line
    "nvim-web-devicons", -- Icons
    "snacks",        -- UI enhancements
  },
  
  extras = {
    -- Currently empty, future plugins will go here
  }
}

-- Helper function to require a module with error handling
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to load plugin module: " .. module, vim.log.levels.WARN)
    return {}
  end
  return result
end

-- Helper to safely load plugin modules by category
local function load_category(category, plugins)
  local specs = {}
  
  for _, plugin_name in ipairs(plugins) do
    local plugin_module = "neotex.plugins." .. plugin_name
    local plugin_spec = safe_require(plugin_module)
    
    -- Handle both table and function return types
    if type(plugin_spec) == "function" then
      local ok, result = pcall(plugin_spec)
      if ok then
        if type(result) == "table" then
          table.insert(specs, result)
        end
      end
    elseif type(plugin_spec) == "table" then
      -- Check if the table is a list (indexed by consecutive numbers starting at 1)
      -- This replaces the deprecated vim.tbl_islist function
      local is_list = true
      for k, _ in pairs(plugin_spec) do
        if type(k) ~= "number" or k <= 0 or k > #plugin_spec then
          is_list = false
          break
        end
      end
      
      if is_list and #plugin_spec > 0 then
        for _, spec in ipairs(plugin_spec) do
          table.insert(specs, spec)
        end
      else
        table.insert(specs, plugin_spec)
      end
    end
  end
  
  return specs
end

-- Main plugin specification - combines all categories
local plugins = {}

-- Load plugins from each category
for category, category_plugins in pairs(categories) do
  local category_specs = load_category(category, category_plugins)
  for _, spec in ipairs(category_specs) do
    table.insert(plugins, spec)
  end
end

-- Add any custom/specialty plugins not in categories here

return plugins
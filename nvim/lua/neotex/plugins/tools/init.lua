-----------------------------------------------------------
-- Tool Integration Plugins
--
-- This module loads plugins that integrate various tools:
-- - gitsigns.lua: Git integration
-- - firenvim.lua: Browser integration
-- - vimtex.lua: LaTeX integration
-- - lean.lua: Lean theorem prover integration
-- - markdown-preview.lua: Markdown preview
-- - autolist.lua: Smart list handling for markdown
-- - mini.lua: Mini plugins collection (pairs, comments, etc.)
-- - surround.lua: Text surrounding functionality
-- - todo-comments.lua: Highlight and search TODO comments
-- - yanky.lua: Enhanced yank and paste functionality
-- - himalaya/: Email client integration with local storage
--
-- Note: The following remain in other modules:
-- - toggleterm.lua: Terminal integration (editor module)
-- - telescope.lua: Fuzzy finder and navigation (editor module)
-- - treesitter.lua: Syntax highlighting and code navigation (editor module)
-- - sessions.lua: Session management (ui module)
--
-- The module uses a consistent error handling approach to ensure
-- NeoVim starts properly even if some plugin specifications fail.
-----------------------------------------------------------

-- Helper function to require a module with error handling
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to load plugin module: " .. module, vim.log.levels.WARN)
    return {}
  end
  
  -- Validate that the result is actually a valid plugin spec
  -- Most plugin specs are tables with a string at index 1 (the repo)
  if type(result) == "table" then
    -- It's already a valid spec if it has a string in position 1
    if type(result[1]) == "string" then
      return result
    end
    
    -- It's already a valid spec if it's an import directive
    if result.import then
      return result
    end
    
    -- For function-only modules (which would cause the "invalid plugin spec" error)
    -- Return an empty table instead of the function
    if result.setup and type(result.setup) == "function" and not result[1] then
      vim.notify("Module " .. module .. " only has a setup function and is not a valid plugin spec", vim.log.levels.WARN)
      return {}
    end
    
    -- Special case: himalaya-plugin should return its own spec, not expose the full module
    if module == "neotex.plugins.tools.himalaya-plugin" then
      -- This should be a direct plugin spec table with dir, name, etc.
      if result.dir and result.name then
        return result
      end
    end
    
    -- If we're getting a complex module with utils, setup, etc. instead of a plugin spec
    if result.utils and result.setup and result.get_config and not result[1] and not result.dir then
      vim.notify("Module " .. module .. " appears to be a full module, not a plugin spec", vim.log.levels.WARN)
      return {}
    end
  end
  
  return result
end

-- Load modules
local gitsigns_module = safe_require("neotex.plugins.tools.gitsigns")
local firenvim_module = safe_require("neotex.plugins.tools.firenvim")
local snacks_module = safe_require("neotex.plugins.tools.snacks")
local autolist_module = safe_require("neotex.plugins.tools.autolist")
local mini_module = safe_require("neotex.plugins.tools.mini")
local surround_module = safe_require("neotex.plugins.tools.surround")
local todo_comments_module = safe_require("neotex.plugins.tools.todo-comments")
local yanky_module = safe_require("neotex.plugins.tools.yanky")
local himalaya_module = safe_require("neotex.plugins.tools.himalaya-plugin")

-- Create array of valid plugin specs
local plugins = {}

-- Helper function to add valid specs to the plugins array
local function add_if_valid(spec)
  if type(spec) == "table" and (spec[1] or spec.import or spec.dir) then
    table.insert(plugins, spec)
  end
end

-- Add only valid plugin specs
add_if_valid(gitsigns_module)
add_if_valid(firenvim_module)
add_if_valid(snacks_module)
add_if_valid(autolist_module)
add_if_valid(mini_module)
add_if_valid(surround_module)
add_if_valid(todo_comments_module)
add_if_valid(yanky_module)

-- Himalaya returns a single spec, add it directly
add_if_valid(himalaya_module)

-- Return only valid plugin specs
return plugins


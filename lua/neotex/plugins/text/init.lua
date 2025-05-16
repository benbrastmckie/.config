-----------------------------------------------------------
-- Text Processing Plugins
--
-- This module loads plugins specifically for text formats and processing:
-- - vimtex.lua: LaTeX integration
-- - lean.lua: Lean theorem prover integration
-- - jupyter/: Jupyter notebook integration
-- - markdown-preview.lua: Markdown preview functionality
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
  end

  return result
end

-- Load modules
local vimtex_module = safe_require("neotex.plugins.text.vimtex")
local lean_module = safe_require("neotex.plugins.text.lean")
local jupyter_module = safe_require("neotex.plugins.text.jupyter")
local markdown_preview_module = safe_require("neotex.plugins.text.markdown-preview")

-- Create array of valid plugin specs
local plugins = {}

-- Helper function to add valid specs to the plugins array
local function add_if_valid(spec)
  if type(spec) == "table" and (spec[1] or spec.import) then
    table.insert(plugins, spec)
  end
end

-- Add only valid plugin specs
add_if_valid(vimtex_module)
add_if_valid(lean_module)
add_if_valid(jupyter_module)
add_if_valid(markdown_preview_module)

-- Return only valid plugin specs
return plugins


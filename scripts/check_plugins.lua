-- Plugin checking utility for NeoVim configuration
-- Run with: nvim --headless -c "luafile scripts/check_plugins.lua" -c "qa!"

local function print_header(text)
  local width = 60
  local padding = math.floor((width - #text) / 2)
  local line = string.rep("=", width)
  
  print(line)
  print(string.rep(" ", padding) .. text)
  print(line)
end

local function get_plugins_by_category()
  -- Get the categories from our new plugin organization
  local ok, plugins_module = pcall(require, "neotex.plugins")
  if not ok then
    print("❌ Failed to load neotex.plugins module")
    return nil
  end
  
  -- Try to get the categories table
  local categories = {
    coding = {},
    editor = {},
    lsp = {},
    tools = {},
    ui = {},
    extras = {}
  }
  
  -- We'll reconstruct our categories by looking at plugin specs
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    print("❌ Failed to load lazy.nvim")
    return nil
  end
  
  local plugins = lazy.plugins()
  
  -- For each loaded plugin, check which of our module files it comes from
  for _, plugin in pairs(plugins) do
    local found = false
    for cat_name, cat_plugins in pairs(categories) do
      if not found then
        -- Try to match the plugin to one of our category modules
        for _, mod_name in ipairs({
          "neotex.plugins." .. cat_name .. "." .. plugin.name,
          "neotex.plugins." .. plugin.name
        }) do
          local mod_ok = pcall(require, mod_name)
          if mod_ok then
            table.insert(cat_plugins, plugin.name)
            found = true
            break
          end
        end
      end
    end
    
    if not found then
      -- Plugins that don't match any category go to "extras"
      table.insert(categories.extras, plugin.name)
    end
  end
  
  return categories
end

-- Main execution
print_header("NEOVIM PLUGIN CHECK")

-- Count loaded plugins
local lazy_ok, lazy = pcall(require, "lazy")
if not lazy_ok then
  print("❌ Lazy.nvim not loaded")
  return
end

local plugins = lazy.plugins()
local count = 0
for _ in pairs(plugins) do
  count = count + 1
end

print("Total plugins loaded: " .. count)

-- Get plugins by category
local categories = get_plugins_by_category()
if categories then
  print("\nPlugins by Category:")
  
  for cat_name, cat_plugins in pairs(categories) do
    if #cat_plugins > 0 then
      print("\n" .. string.upper(cat_name) .. " (" .. #cat_plugins .. "):")
      table.sort(cat_plugins)
      for _, plugin in ipairs(cat_plugins) do
        print("  - " .. plugin)
      end
    end
  end
end

print("\nPlugin loading structure test completed.")
-- Clear Lua module cache for Himalaya
local M = {}

function M.clear_himalaya_cache()
  -- Clear all Himalaya-related modules from package.loaded
  local cleared = {}
  
  for key, _ in pairs(package.loaded) do
    if key:match('himalaya') then
      package.loaded[key] = nil
      table.insert(cleared, key)
    end
  end
  
  if #cleared > 0 then
    print("Cleared " .. #cleared .. " Himalaya modules from cache:")
    for _, module in ipairs(cleared) do
      print("  - " .. module)
    end
  else
    print("No Himalaya modules found in cache")
  end
  
  -- Also clear preload if any
  for key, _ in pairs(package.preload) do
    if key:match('himalaya') then
      package.preload[key] = nil
    end
  end
  
  print("\nRestart Neovim or reload the plugin to use the updated modules.")
end

vim.api.nvim_create_user_command('HimalayaClearCache', M.clear_himalaya_cache, {
  desc = 'Clear Himalaya module cache'
})

return M
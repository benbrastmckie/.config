-- Snacks utility functions
local M = {}

-- Safe lazygit launcher with fallback
-- This function tries to use Snacks.lazygit() first, but falls back to ToggleTerm
-- if Snacks isn't available or fails
M.safe_lazygit = function()
  local success = false
  
  -- First try using Snacks.lazygit if available
  if Snacks and Snacks.lazygit then
    success = pcall(function() Snacks.lazygit() end)
  end
  
  -- If Snacks failed or isn't available, use ToggleTerm as fallback
  if not success then
    vim.cmd('TermExec cmd="lazygit" direction=float')
    vim.notify('Using ToggleTerm fallback for LazyGit', vim.log.levels.INFO)
  end
end

return M
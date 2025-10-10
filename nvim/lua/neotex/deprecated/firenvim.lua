-- DEPRECATED: 2025-10-03
-- Reason: Minimal usage, features not needed
-- Moved from: lua/neotex/plugins/tools/firenvim.lua
-- Can be removed after: 2025-11-03 (30 days)

return {
  "glacambre/firenvim",
  -- Lazy load firenvim
  -- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
  lazy = not vim.g.started_by_firenvim,
  -- Use a safer build function that doesn't call a function directly
  build = ":call firenvim#install(0)",
  -- { "lualine.nvim", cond = not vim.g.started_by_firenvim }, -- not useful in the browser
}

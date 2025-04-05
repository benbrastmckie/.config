-- Buffer-local settings for lectic.markdown files

-- Import markdown settings
-- Reuse markdown.lua configuration if it exists
local markdown_path = vim.fn.stdpath("config") .. "/after/ftplugin/markdown.lua"
if vim.fn.filereadable(markdown_path) == 1 then
  dofile(markdown_path)
end

-- -- Enable folding specifically for lectic files with our custom fold expression
-- -- Note: Fold settings are window-local options, not buffer-local
-- vim.wo.foldenable = true
-- vim.wo.foldmethod = "expr"
-- vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
-- vim.wo.foldlevel = 99 -- Open all folds by default

-- Markdown settings that make sense for lectic.markdown too
vim.opt_local.conceallevel = 2     -- Enable concealing of syntax
vim.opt_local.concealcursor = "nc" -- Conceal in normal and command mode

-- Don't explicitly set folding options here - use the global persistence system
-- vim.opt_local.foldenable = true
-- vim.opt_local.foldmethod = "manual"
-- vim.opt_local.foldlevel = 99

-- Load the saved folding state instead
require("neotex.core.functions").LoadFoldingState()

-- Make sure that we inherit markdown settings
vim.cmd [[
  runtime! syntax/markdown.vim
  runtime! indent/markdown.vim
]]

-- Handle checkbox for Lectic files
function _G.HandleCheckbox()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*%-%s%[[ x]%]") then
    -- Toggle between [ ] and [x]
    if line:match("%[ %]") then
      vim.cmd("s/\\[ \\]/[x]/e")
    else
      vim.cmd("s/\\[x\\]/[ ]/e")
    end
  end
end

-- Additional keymaps specific to lectic.markdown
vim.keymap.set("n", "<C-n>", ":lua HandleCheckbox()<CR>",
  { buffer = true, silent = true, desc = "Toggle checkbox" })

-- Add keybinding to open the URL under cursor with gx for familiar Vim behavior
vim.keymap.set("n", "gx", ":lua OpenUrlUnderCursor()<CR>",
  { buffer = true, silent = true, desc = "Open URL under cursor" })

-- Enable Ctrl+Click to open URLs
vim.keymap.set("n", "<C-LeftMouse>", function()
  -- We don't perform standard Ctrl+LeftMouse because we want to keep cursor position
  -- Instead, we directly get the mouse position and use it
  vim.schedule(function()
    OpenUrlAtMouse()
  end)
end, { buffer = true, silent = true, desc = "Open URL with Ctrl+Click" })

-- Handle mouse release to avoid issues
vim.keymap.set("n", "<C-LeftRelease>", "<Nop>", { buffer = true, silent = true })

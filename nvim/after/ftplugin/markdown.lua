require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "_", "_" },
      find = "_.-_",
      delete = "^(_)().-(_)()$",
    },
  },
})

-- prevents markdown from changing tabs to 4 spaces
-- vim.g.markdown_recommended_style = 0

-- Custom Markdown header-based folding function
-- This creates folds at each heading level (# Header)
function MarkdownFoldLevel()
  local line = vim.fn.getline(vim.v.lnum)
  local next_line = vim.fn.getline(vim.v.lnum + 1)
  
  -- Check for markdown headings (### style)
  local level = line:match("^(#+)%s")
  if level then
    return ">" .. string.len(level)
  end
  
  -- Check for markdown headings (underline style)
  if next_line and next_line:match("^=+$") then
    return ">1"
  end
  if next_line and next_line:match("^-+$") then
    return ">2"
  end
  
  -- Keep current level for indented content
  return "="
end

-- Configure folding for markdown files
-- Note: Fold settings are window-local options, not buffer-local
vim.wo.foldenable = true
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
vim.wo.foldlevel = 1 -- Show top-level headings but fold others

-- Force the creation of folds
function _G.CreateMarkdownFolds()
  -- Fold settings are window-local, not buffer-local
  vim.wo.foldmethod = "manual"  -- First set to manual to reset
  vim.wo.foldmethod = "expr"    -- Then back to expr
  vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
  vim.cmd("normal! zx")         -- Update folds
  print("Markdown folds created")
end

-- Add keybinding to force creation of folds
vim.keymap.set("n", "<leader>mF", ":lua CreateMarkdownFolds()<CR>", 
  { buffer = true, silent = true, desc = "Create markdown folds" })

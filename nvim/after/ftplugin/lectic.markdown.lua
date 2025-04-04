-- Buffer-local settings for lectic.markdown files

-- Import markdown settings
-- Reuse markdown.lua configuration if it exists
local markdown_path = vim.fn.stdpath("config") .. "/after/ftplugin/markdown.lua"
if vim.fn.filereadable(markdown_path) == 1 then
  dofile(markdown_path)
end

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
  
  -- Check for XML/HTML style tags that Lectic uses
  if line:match("^<[^/][^>]*>$") then
    return "a1"
  end
  if line:match("^</[^>]+>$") then
    return "s1"
  end
  
  -- Keep current level for indented content
  return "="
end

-- Enable folding specifically for lectic files with our custom fold expression
-- Note: Fold settings are window-local options, not buffer-local
vim.wo.foldenable = true
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
vim.wo.foldlevel = 1 -- Show top-level headings but fold others

-- Custom function to fold XML-like tool calls in Lectic files
function _G.FoldLecticToolCalls()
  -- Try to use the Lectic-specific fold function if it exists
  local success, lectic_fold = pcall(require, 'lectic.fold')
  
  if success and lectic_fold and lectic_fold.fold_tool_calls then
    -- Use the plugin's function if available
    lectic_fold.fold_tool_calls()
  else
    -- Fallback manual implementation
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local stack = {}
    
    for i, line in ipairs(lines) do
      if line:match("^<[^/][^>]*>$") then
        table.insert(stack, i - 1)
      elseif line:match("^</[^>]+>$") and #stack > 0 then
        local start_line = table.remove(stack)
        local end_line = i - 1
        
        -- Create a manual fold
        vim.cmd(start_line + 1 .. "," .. end_line + 1 .. "fold")
      end
    end
    print("Created folds for XML-like blocks")
  end
end

-- Create keybinding to fold tool calls
vim.keymap.set("n", "<leader>mT", ":lua FoldLecticToolCalls()<CR>", 
  { buffer = true, silent = true, desc = "Fold Lectic tool calls" })

-- Markdown settings that make sense for lectic.markdown too
vim.opt_local.conceallevel = 2 -- Enable concealing of syntax
vim.opt_local.concealcursor = "nc" -- Conceal in normal and command mode

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

-- Force the creation of folds
function _G.CreateMarkdownFolds()
  -- Fold settings are window-local, not buffer-local
  vim.wo.foldmethod = "manual"  -- First set to manual to reset
  vim.wo.foldmethod = "expr"    -- Then back to expr
  vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
  vim.cmd("normal! zx")         -- Update folds
  print("Markdown folds created")
end

-- Additional keymaps specific to lectic.markdown
vim.keymap.set("n", "<C-n>", ":lua HandleCheckbox()<CR>", 
  { buffer = true, silent = true, desc = "Toggle checkbox" })
  
-- Add keybinding to open URLs in Lectic files
vim.keymap.set("n", "<leader>mu", ":lua OpenUrlUnderCursor()<CR>", 
  { buffer = true, silent = true, desc = "Open URL under cursor" })
  
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
  
-- Add keybinding to force creation of folds
vim.keymap.set("n", "<leader>mF", ":lua CreateMarkdownFolds()<CR>", 
  { buffer = true, silent = true, desc = "Create markdown folds" })
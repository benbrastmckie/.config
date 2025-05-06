-- BOOTSTRAP LAZY
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Clean up any tree-sitter tmp directories that might cause conflicts
pcall(function()
  local tmp_dirs = vim.fn.glob(vim.fn.expand("~") .. "/tree-sitter-*-tmp", true, true)
  for _, dir in ipairs(tmp_dirs) do
    vim.fn.delete(dir, "rf")
  end
end)

-- Check if the lazy-lock.json file is valid
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
if vim.fn.filereadable(lockfile) == 1 then
  -- Read the file content
  local content = table.concat(vim.fn.readfile(lockfile), "\n")
  -- Check if it's valid JSON
  local success, _ = pcall(vim.fn.json_decode, content)
  if not success then
    -- If not valid JSON, create a valid but empty JSON object
    local valid_json = [[{
  "_comments": "This is a temporary placeholder lock file that will be replaced when plugins are installed"
}]]
    vim.fn.writefile(vim.split(valid_json, "\n"), lockfile)
    vim.notify("Fixed invalid lazy-lock.json file", vim.log.levels.INFO)
  end
end

require("lazy").setup({
  { import = "neotex.plugins" },    -- main plugins directory
  { import = "neotex.plugins.lsp" } -- lsp plugins directory
}, {
  install = {
    colorscheme = { "gruvbox" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  performance = {
    reset_packpath = true,
    rtp = {
      reset = true,
    },
  },
})

return {
  "gleachkr/lectic",
  lazy = true,
  ft = "markdown",       -- Only load for markdown files
  build = "npm install", -- Install dependencies
  init = function()
    -- Create the autocmd group early
    vim.api.nvim_create_augroup("Lectic", { clear = true })
  end,
  config = function()
    -- Add the command first
    -- vim.opt.rtp:append(plugin.dir .. "/extra/lectic.nvim")
    vim.cmd([[command! -range=% Lectic :<line1>,<line2>!lectic]])

    -- Setup the FileType autocmd after plugin is loaded
    vim.api.nvim_create_autocmd("FileType", {
      group = "Lectic",
      pattern = "markdown",
      callback = function()
        -- Check if the setup function exists before calling
        if vim.fn.exists("*lectic#setup") == 1 then
          vim.cmd([[call lectic#setup()]])
        end
      end
    })
  end,
}

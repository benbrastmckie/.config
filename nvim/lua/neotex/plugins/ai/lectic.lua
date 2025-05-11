return {
  "gleachkr/lectic",
  lazy = true,
  -- Use both markdown and lectic.markdown filetypes
  ft = { "markdown", "lectic.markdown" },
  cmd = { "Lectic" },
  build = "npm install", -- Install dependencies
  -- Don't modify the dir path - it's causing installation issues
  -- The plugin needs to be installed correctly first
  -- We'll let it install completely, then configure it
  init = function()
    -- Add the plugin's lua directory to the runtimepath
    vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/lectic/extra/lectic.nvim")
    
    -- Create the autocmd group early
    vim.api.nvim_create_augroup("Lectic", { clear = true })

    -- Keymappings are now defined in which-key.lua to centralize all mappings

    -- Add filetype detection for .lec files if not already defined
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = "Lectic",
      pattern = "*.lec",
      callback = function()
        vim.bo.filetype = "lectic.markdown"
      end
    })
  end,
  config = function()
    -- The Lectic utility functions are now loaded from neotex.util.lectic_extras
    -- and available via the global commands LecticCreateFile and LecticSubmitSelection

    -- Register the command to use the plugin's submit function
    vim.api.nvim_create_user_command(
      'Lectic',
      function(opts)
        local start_line = opts.line1
        local end_line = opts.line2
        require("lectic.submit").submit_lectic(start_line, end_line)
      end,
      {
        range = "%",
        desc = "Process current buffer with Lectic AI (can be used with visual selections)",
        nargs = "?",
        complete = function()
          return { "gpt-4", "gpt-3.5-turbo" }
        end
      }
    )

    -- Configure any additional plugin settings
    vim.g.lectic_model = "gpt-4" -- Default model

    -- Create additional keymaps for Lectic files
    vim.api.nvim_create_autocmd("FileType", {
      group = "Lectic",
      pattern = "lectic.markdown",
      callback = function(ev)
        local bufnr = ev.buf

        -- Use the global manual folding settings from options.lua
        -- No need to set folding options specifically for lectic

        -- Also set standard markdown settings for this buffer
        vim.opt_local.conceallevel = 2     -- Enable concealing of syntax
        vim.opt_local.concealcursor = "nc" -- Conceal in normal and command mode

        -- Apply markdown-specific keymaps
        -- This is defined in keymaps.lua and adds bullet point handling, etc.
        _G.set_markdown_keymaps()

        -- Add lectic-specific indicator in the statusline
        vim.opt_local.statusline = "%<%f %h%m%r%=Model: " .. vim.g.lectic_model .. " | lectic.markdown %l,%c%V %P"
      end
    })
  end,
  -- Define dependencies if needed
  dependencies = {
    "nvim-lua/plenary.nvim",          -- Required by many plugins
    "nvim-treesitter/nvim-treesitter" -- For better folding support
  }
}
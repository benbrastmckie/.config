return {
  'Julian/lean.nvim',
  event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',          -- Completion engine
    'hrsh7th/cmp-nvim-lsp',      -- LSP source for nvim-cmp
    'saadparwaiz1/cmp_luasnip',  -- Snippet source for nvim-cmp (optional)
    'L3MON4D3/LuaSnip',          -- Snippet engine (optional)
  },

  -- Configuration options for lean.nvim
  opts = {
    lsp = {},
    abbreviations = {
      enabled = false
    },
    -- For notifications
    stderr = {
        enable = true,
        on_lines = function(lines) vim.notify(lines) end
    },
    mappings = true,   -- Enable default key mappings
    infoview = {
      autoopen = true,
    }
  },

  -- Configuration function to set up lean.nvim and related settings
  config = function(_, opts)
    -- Initialize lean.nvim with the provided options
    require('lean').setup(opts)

    -- Create an augroup for Lean-related autocommands
    local lean_group = vim.api.nvim_create_augroup("LeanCloseInfoview", { clear = true })

    -- Prevent Infoview Buffer from Appearing in Buffer Lists
    vim.api.nvim_create_autocmd("FileType", {
      group = lean_group,
      pattern = "leaninfo",  -- Infoview buffer filetype
      callback = function()
        -- Set buffer options to exclude it from buffer lists and normal operations
        vim.bo.buflisted = false       -- Exclude from buffer lists
        vim.bo.bufhidden = "hide"      -- Hide the buffer when it's no longer displayed
        vim.bo.buftype = "nofile"      -- Specify that it's not associated with a file
        -- Optional: Prevent modifications to the Infoview buffer
        vim.bo.modifiable = false
        vim.bo.swapfile = false
      end,
    })

  end
}

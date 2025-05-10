-----------------------------------------------------------
-- Yanky.nvim: Enhanced Yank and Paste Functionality
-- 
-- This module configures yanky.nvim for improved clipboard management:
-- - Maintains a history of yanked text
-- - Offers Telescope integration for browsing clipboard history
-- - Provides better paste functionality with formatting options
-- - Optimizes performance and reduces memory usage
-- - Integrates with the system clipboard
--
-- Yanky.nvim enhances Neovim's yank and paste operations with
-- advanced features and a more intuitive user experience.
-----------------------------------------------------------

return {
  "gbprod/yanky.nvim",
  lazy = true,
  event = { "TextYankPost", "CursorMoved" },
  keys = {
    -- Yanky mappings in normal mode
    { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank text" },
    { "p", "<Plug>(YankyPutAfter)", mode = "n", desc = "Put yanked text after cursor" },
    { "P", "<Plug>(YankyPutBefore)", mode = "n", desc = "Put yanked text before cursor" },
    { "gp", "<Plug>(YankyGPutAfter)", mode = "n", desc = "Put yanked text after cursor and leave cursor after" },
    { "gP", "<Plug>(YankyGPutBefore)", mode = "n", desc = "Put yanked text before cursor and leave cursor after" },
    { "<C-n>", "<Plug>(YankyCycleForward)", desc = "Cycle forward through yank history" },
    { "<C-p>", "<Plug>(YankyCycleBackward)", desc = "Cycle backward through yank history" },
    
    -- Telescope integration
    { "<leader>fy", "<cmd>Telescope yank_history<CR>", desc = "Yank history" },
    { "<leader>yh", "<cmd>Telescope yank_history<CR>", desc = "Yank history" },
    { "<leader>yc", "<cmd>YankyClearHistory<CR>", desc = "Clear yank history" },
  },
  dependencies = {
    { "nvim-telescope/telescope.nvim", lazy = true },
  },
  config = function()
    local yanky_ok, yanky = pcall(require, "yanky")
    if not yanky_ok then
      vim.notify("Failed to load yanky.nvim. Functionality will be limited.", vim.log.levels.WARN)
      return
    end
    
    yanky.setup({
      -- Configure ring history
      ring = {
        -- History settings with performance optimizations
        history_length = 50, -- Reduced from 100 to lower memory usage
        storage = "memory", -- Use memory for faster access
        storage_path = vim.fn.stdpath("data") .. "/yanky", -- Path for persistent storage
        
        -- Sync with system clipboard
        sync_with_numbered_registers = true,
        
        -- Cancel yank if cursor position changed during operation
        cancel_event = "update",
        
        -- Clean unused entries periodically to reduce memory usage
        ignore_registers = { "_" }, -- Ignore the black hole register
      },
      
      -- Pick settings - optimized for performance
      picker = {
        select = { 
          action = nil, -- Will be set lazily when needed
        },
        telescope = {
          use_default_mappings = true,
          mappings = {},
        },
      },
      
      -- System clipboard integration
      system_clipboard = {
        sync_with_ring = true,
      },
      
      -- Highlighting settings - reduced duration for better performance
      highlight = {
        on_put = true,
        on_yank = true,
        timer = 100,  -- Reduced from 150ms for better performance
      },
      
      -- Preserve cursor position on put
      preserve_cursor_position = {
        enabled = true,
      },
      
      -- Clean up duplicates in the yank history to save memory
      deduplicate = true,
    })
    
    -- Lazy load Telescope integration only when needed
    vim.api.nvim_create_autocmd("User", {
      pattern = "TelescopeLoaded",
      once = true,
      callback = function()
        pcall(require("telescope").load_extension, "yank_history")
      end,
    })
    
    -- Add autocommands to clean up yank history periodically
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        -- Clean up yanky history when writing files to prevent memory growth
        if #require("yanky.history").all() > 30 then
          -- Only keep recent entries
          local entries = require("yanky.history").all()
          for i = 31, #entries do
            require("yanky.history").delete(i)
          end
        end
      end,
    })
    
    -- Clean up on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        pcall(require("yanky").clear_history)
      end,
    })
    
    -- Optimize treesitter integration - only use when treesitter is already loaded
    if package.loaded["nvim-treesitter"] then
      vim.g.yanky_use_treesitter = true
    end
  end,
}
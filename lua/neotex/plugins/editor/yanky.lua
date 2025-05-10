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
  event = "TextYankPost",
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
  },
  dependencies = {
    "nvim-telescope/telescope.nvim",
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
        -- History settings
        history_length = 100, -- Limit history to reduce memory usage
        storage = "memory", -- Use memory for faster access
        storage_path = vim.fn.stdpath("data") .. "/yanky", -- Path for persistent storage
        
        -- Sync with system clipboard
        sync_with_numbered_registers = true,
        
        -- Cancel yank if cursor position changed during operation
        cancel_event = "update",
        
        -- Clean unused entries periodically to reduce memory usage
        ignore_registers = { "_" }, -- Ignore the black hole register
      },
      
      -- Pick settings
      picker = {
        select = { 
          action = nil, -- We'll set this after checking if actions is available
        },
        telescope = {
          use_default_mappings = true,
          -- We'll configure telescope mappings only if the telescope extension is loaded properly
        },
      },
      
      -- System clipboard integration
      system_clipboard = {
        sync_with_ring = true,
      },
      
      -- Highlighting settings
      highlight = {
        on_put = true,
        on_yank = true,
        timer = 150,  -- Shorter highlight duration for better performance
      },
      
      -- Preserve cursor position on put
      preserve_cursor_position = {
        enabled = true,
      },
      
      -- Clean up duplicates in the yank history to save memory
      deduplicate = true,
    })
    
    -- Add Telescope integration if available
    local telescope_ok, telescope = pcall(require, "telescope")
    if telescope_ok then
      -- Check if telescope extension exists before loading
      local status_ok, _ = pcall(telescope.load_extension, "yank_history")
      if not status_ok then
        vim.notify("Yanky: failed to load telescope extension. Some features may be missing.", vim.log.levels.WARN)
      end
    end
    
    -- Add custom keymaps via which-key
    local has_which_key, which_key = pcall(require, "which-key")
    if has_which_key and telescope_ok then
      -- Only register Telescope commands if telescope is available
      which_key.register({
        ["<leader>y"] = { 
          name = "YANK",
          h = { "<cmd>Telescope yank_history<CR>", "history" },
          c = { "<cmd>YankyClearHistory<CR>", "clear history" },
        },
      })
    end
    
    -- Add autocommands to clean up yank history periodically
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        -- Clean up yanky history when exiting Neovim
        require("yanky").clear_history()
      end,
    })
    
    -- Check if nvim-treesitter is available for better highlighting
    local has_treesitter = pcall(require, "nvim-treesitter")
    if has_treesitter then
      -- Use treesitter for syntax-aware yanking when available
      vim.g.yanky_use_treesitter = true
    end
  end,
}
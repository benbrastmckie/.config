-----------------------------------------------------
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
    { "y",          "<Plug>(YankyYank)",               mode = { "n", "x" },        desc = "Yank text" },
    { "p",          "<Plug>(YankyPutAfter)",           mode = "n",                 desc = "Put yanked text after cursor" },
    { "P",          "<Plug>(YankyPutBefore)",          mode = "n",                 desc = "Put yanked text before cursor" },
    { "gp",         "<Plug>(YankyGPutAfter)",          mode = "n",                 desc = "Put yanked text after cursor and leave cursor after" },
    { "gP",         "<Plug>(YankyGPutBefore)",         mode = "n",                 desc = "Put yanked text before cursor and leave cursor after" },
    -- Leader mappings moved to which-key.lua
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
        history_length = 50,                               -- Reduced from 100 to lower memory usage
        storage = "memory",                                -- Use memory for faster access
        storage_path = vim.fn.stdpath("data") .. "/yanky", -- Path for persistent storage

        -- Sync with system clipboard
        sync_with_numbered_registers = true,

        -- Cancel yank if cursor position changed during operation
        cancel_event = "update",

        -- Clean unused entries periodically to reduce memory usage
        ignore_registers = { "_" }, -- Ignore the black hole register
      },

      -- Enhanced picker setup with custom function to replace the Telescope picker
      picker = {
        select = {
          action = function(entry)
            require("yanky.picker").actions.put("p", false)(entry)
          end,
        },
        -- Basic telescope config that will be enhanced via the override below
        telescope = {
          use_default_mappings = true,
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
        timer = 100, -- Reduced from 150ms for better performance
      },

      -- Preserve cursor position on put
      preserve_cursor_position = {
        enabled = true,
      },

      -- Clean up duplicates in the yank history to save memory
      deduplicate = true,
    })

    -- Create a custom yank_history function that doesn't rely on the extension
    -- This will override the default mappings from which-key
    _G.YankyTelescopeHistory = function()
      local tele_status, telescope = pcall(require, "telescope")
      if not tele_status then
        vim.notify("Telescope not available", vim.log.levels.ERROR)
        return
      end
      
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local previewers = require("telescope.previewers")
      local conf = require("telescope.config").values
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      
      -- Get all yanks
      local history = {}
      for index, value in pairs(require("yanky.history").all()) do
        value.history_index = index
        history[index] = value
      end
      
      -- Create a previewer that shows the yanked content
      local previewer = previewers.new_buffer_previewer({
        title = "Yanked Text",
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, vim.split(entry.value.regcontents, "\n"))
          if entry.value.filetype ~= nil then
            vim.bo[self.state.bufnr].filetype = entry.value.filetype
          end
        end,
      })
      
      -- Custom entry maker
      local make_entry = function(entry)
        return {
          value = entry,
          ordinal = entry.regcontents,
          display = entry.regcontents:gsub("\n", "\\n"),
        }
      end
      
      -- Create new picker with reliable behavior
      pickers.new({}, {
        prompt_title = "Yank History",
        finder = finders.new_table({
          results = history,
          entry_maker = make_entry,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewer,
        attach_mappings = function(prompt_bufnr, map)
          -- Define a reliable action for putting yanked content
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            
            vim.schedule(function()
              -- Use yanky's put function for consistent behavior
              local yanky = require("yanky")
              require("yanky.utils").use_temporary_register(
                require("yanky.utils").get_default_register(),
                selection.value,
                function() yanky.put("p", false) end
              )
            end)
          end)
          
          return true
        end,
      }):find()
    end
    
    -- NOTE: Keymaps for <leader>fy and <leader>yh are defined in which-key.lua
    -- They will automatically use the _G.YankyTelescopeHistory() function defined above
    
    -- Still try to load the extension as a fallback
    pcall(function()
      require("telescope").load_extension("yank_history")
    end)

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

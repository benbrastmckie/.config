return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    local width_manager = require("neotex.util.neotree-width")
    
    -- Load saved width
    local saved_width = width_manager.load_width()
    
    -- Disable netrw (similar to nvim-tree setup)
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    
    require("neo-tree").setup({
      close_if_last_window = true,
      
      window = {
        width = saved_width,
        position = "left",
        mappings = {
          -- Vim-style navigation (matching nvim-tree keymaps)
          ["l"] = "open",
          ["h"] = "close_node",
          ["<CR>"] = "open",
          ["-"] = "navigate_up",
          ["a"] = "add",
          ["d"] = "delete",
          ["r"] = "rename",
          ["y"] = "copy_to_clipboard",
          ["x"] = "cut_to_clipboard",
          ["p"] = "paste_from_clipboard",
          ["q"] = "close_window",
          ["R"] = "refresh",
          ["?"] = "show_help",
          ["H"] = "toggle_hidden",
          ["v"] = "open_vsplit",
          ["<2-LeftMouse>"] = "open",
        },
      },
      
      -- Event handlers using Neo-tree's natural event system
      event_handlers = {
        -- Apply custom settings when entering neo-tree buffer
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            -- Disable word highlighting plugins
            vim.b.minicursorword_disable = true
            vim.b.local_highlight_enabled = false
            vim.b.cursorword_disable = true
            vim.b.highlight_current_word_enabled = false
            vim.opt_local.hlsearch = false
            
            -- Prevent horizontal scrolling
            vim.opt_local.sidescrolloff = 0
            vim.opt_local.wrap = false
            vim.opt_local.list = false
            vim.opt_local.linebreak = false
            
            -- Disable horizontal scroll key mappings
            local opts = { buffer = true, silent = true }
            vim.keymap.set('n', '<ScrollWheelRight>', '<Nop>', opts)
            vim.keymap.set('n', '<ScrollWheelLeft>', '<Nop>', opts)
            vim.keymap.set('n', 'zl', '<Nop>', opts)
            vim.keymap.set('n', 'zh', '<Nop>', opts)
            vim.keymap.set('n', 'zL', '<Nop>', opts)
            vim.keymap.set('n', 'zH', '<Nop>', opts)
            vim.keymap.set('n', '<Right>', '<Nop>', opts)
            vim.keymap.set('n', '<Left>', '<Nop>', opts)
            
            -- Apply saved width after a short delay
            vim.defer_fn(function()
              width_manager.apply_width()
            end, 10)
            
            -- Disable vim-illuminate if available
            pcall(function()
              require('illuminate').pause_buf()
            end)
          end,
        },
        
        -- Save width when closing
        {
          event = "neo_tree_window_before_close",
          handler = function()
            width_manager.track_width_change()
          end,
        },
        
        -- Auto-close behavior (mimics nvim-tree quit_on_open)
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
        
        -- Handle window resize for width tracking
        {
          event = "neo_tree_window_after_open",
          handler = function()
            -- Apply width immediately after opening
            vim.defer_fn(function()
              width_manager.apply_width()
            end, 50)
          end,
        },
      },
      
      -- Use default component configs (cleaner appearance)
      
      -- Filesystem source configuration
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        filtered_items = {
          visible = true, -- Show dotfiles and git ignored files
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {},
          hide_by_pattern = {},
          always_show = {},
          never_show = {},
        },
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = true,
        -- Use default renderers and components
      },
      
      -- Git status source configuration
      git_status = {
        window = {
          position = "float",
        },
      },
      
      -- Buffers source configuration  
      buffers = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
      },
    })
    
    -- Set up width tracking via VimResized autocmd
    vim.api.nvim_create_autocmd("VimResized", {
      group = vim.api.nvim_create_augroup("NeoTreeWidthTracking", { clear = true }),
      callback = function()
        width_manager.track_width_change()
      end,
      desc = "Track Neo-tree width changes",
    })
    
    -- Color scheme integration (matching original nvim-tree colors)
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("NeoTreeColors", { clear = true }),
      callback = function()
        -- Directory colors (soft light purple like nvim-tree)
        local dir_color = "#b294bb"
        
        -- Directory and folder highlights
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = dir_color })
        vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = dir_color, bold = true, italic = true })
        vim.api.nvim_set_hl(0, "NeoTreeFolderIcon", { fg = dir_color })
        vim.api.nvim_set_hl(0, "NeoTreeFolderName", { fg = dir_color, bold = true })
        
        -- Modified file indicator (orange like nvim-tree)
        vim.api.nvim_set_hl(0, "NeoTreeModified", { fg = "#e78a4e", bold = true })
        
        -- Git colors matching GitSigns
        local git_colors = _G.GitColors or {
          add = "#4fa6ed",
          change = "#e78a4e", 
          delete = "#fb4934"
        }
        
        vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = git_colors.add, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = git_colors.change, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = git_colors.delete, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitStaged", { fg = git_colors.add, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged", { fg = git_colors.change, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = git_colors.add, bold = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitIgnored", { fg = "#666666", italic = true })
        vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { fg = git_colors.delete, bold = true })
        
        -- File icons
        vim.api.nvim_set_hl(0, "NeoTreeFileIcon", { fg = "#a89984" })
        
        -- Header background matching bufferline
        local function get_highlight_bg(group)
          local hl = vim.api.nvim_get_hl(0, { name = group })
          return hl and hl.bg
        end
        
        local bg_groups = {
          "BufferLineFill",
          "BufferlineBackground", 
          "TabLineFill",
          "StatusLine",
          "Normal",
        }
        
        local bg_color
        for _, group in ipairs(bg_groups) do
          bg_color = get_highlight_bg(group)
          if bg_color then break end
        end
        
        if bg_color then
          local hex_bg_color
          if type(bg_color) == "number" then
            hex_bg_color = string.format("#%06x", bg_color)
          else
            hex_bg_color = bg_color
          end
          
          -- Set header background to match bufferline
          vim.api.nvim_set_hl(0, "NeoTreeTitleBar", {
            fg = dir_color,
            bg = hex_bg_color,
            bold = true
          })
        end
      end,
    })
    
    -- Apply colors immediately and on VimEnter
    vim.schedule(function()
      vim.cmd("doautocmd ColorScheme")
    end)
    
    vim.defer_fn(function()
      vim.cmd("doautocmd ColorScheme")
    end, 100)
    
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("doautocmd ColorScheme")
      end,
      once = true,
    })
    
    -- Create user commands for Neo-tree with width management
    vim.api.nvim_create_user_command('NeoTreeCustomToggle', function()
      require("neo-tree.command").execute({ action = "toggle" })
    end, { desc = "Toggle Neo-tree with width persistence" })
    
    vim.api.nvim_create_user_command('NeoTreeCustomOpen', function()
      require("neo-tree.command").execute({ action = "show" })
    end, { desc = "Open Neo-tree with width persistence" })
    
    vim.api.nvim_create_user_command('NeoTreeCustomClose', function()
      width_manager.track_width_change()
      require("neo-tree.command").execute({ action = "close" })
    end, { desc = "Close Neo-tree with width persistence" })
  end,
}
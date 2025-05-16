-- Create a global module for NvimTree width persistence
-- This ensures the callbacks can always access it
_G.NvimTreePersistence = _G.NvimTreePersistence or {}

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local nvimtree = require("nvim-tree")
    local api = require("nvim-tree.api")
    
    -- Initialize the global module if not already done
    if not _G.NvimTreePersistence.initialized then
      _G.NvimTreePersistence = {
        -- Store the width value
        width = nil,
        
        -- Keep track of whether the tree is currently open
        is_open = false,
        
        -- Default width from config
        default_width = 30,
        
        -- Flag to prevent multiple initializations
        initialized = true,
        
        -- Store reference to the API for use in methods
        api = api,
        
        -- Get current width (fallback to default if not set)
        get_width = function()
          return _G.NvimTreePersistence.width or _G.NvimTreePersistence.default_width
        end,
        
        -- Save the current tree width
        save_width = function()
          -- Only run if tree is open and not currently in the process of opening
          if not _G.NvimTreePersistence.is_open or _G.NvimTreePersistence.opening then 
            return
          end
          
          -- Find NvimTree window directly without using the API
          local found_width = nil
          
          -- Loop through all windows to find NvimTree
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local buf_name = vim.api.nvim_buf_get_name(buf)
            -- Use vim.bo instead of the deprecated nvim_buf_get_option
            local buf_ft = vim.bo[buf].filetype
            
            -- Check if it's the NvimTree window
            if buf_ft == "NvimTree" or buf_name:match("NvimTree") then
              found_width = vim.api.nvim_win_get_width(win)
              break
            end
          end
          
          -- Save the width if found and different from current
          if found_width and found_width > 0 and found_width ~= _G.NvimTreePersistence.width then
            _G.NvimTreePersistence.width = found_width
          end
        end,
        
        -- Setup autocommands for width tracking
        setup_autocmds = function()
          local augroup = vim.api.nvim_create_augroup("NvimTreeWidthPersistence", { clear = true })
          
          -- Track window resize events - this is the main width tracking mechanism
          vim.api.nvim_create_autocmd("WinResized", {
            group = augroup,
            callback = function()
              _G.NvimTreePersistence.save_width()
            end
          })
          
          -- Track when tree is shown - ensures our state is correct
          vim.api.nvim_create_autocmd("User", {
            pattern = "NvimTreeOpened",
            group = augroup,
            callback = function()
              _G.NvimTreePersistence.is_open = true
              
              -- Force a width save on open after a short delay
              vim.defer_fn(function()
                _G.NvimTreePersistence.save_width()
              end, 100)
            end
          })
          
          -- Track when tree is closed
          vim.api.nvim_create_autocmd("User", {
            pattern = "NvimTreeClosed",
            group = augroup,
            callback = function()
              _G.NvimTreePersistence.is_open = false
            end
          })
          
          -- Also track BufEnter to detect when we're in NvimTree
          vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            callback = function(args)
              -- Check if this is an NvimTree buffer
              if vim.bo[args.buf].filetype == "NvimTree" then
                _G.NvimTreePersistence.is_open = true
              end
            end
          })
        end,
        
        -- Custom open function to use saved width
        open = function(opts)
          -- Get saved width or default
          local width = _G.NvimTreePersistence.get_width()
          
          -- Store that we're in the process of opening to avoid resize flicker
          _G.NvimTreePersistence.opening = true
          
          -- Ensure view.width is set before opening
          -- This is the most important part for preventing the two-step opening
          if nvimtree and nvimtree.setup then
            -- Apply width directly to config first (without reloading)
            pcall(function()
              if nvimtree.config and nvimtree.config.view then
                nvimtree.config.view.width = width
              end
            end)
            
            -- Hold off opening for a tiny moment to let the config take effect
            vim.defer_fn(function()
              -- Open the tree with explicit width parameter
              local api = _G.NvimTreePersistence.api
              pcall(function()
                api.tree.open({width = width})
              end)
              
              -- Set state and verify width in a second step if needed
              vim.defer_fn(function()
                _G.NvimTreePersistence.opening = false
                _G.NvimTreePersistence.is_open = true
                
                -- Just to be sure, verify the width once more
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  if vim.bo[buf].filetype == "NvimTree" then
                    local current_width = vim.api.nvim_win_get_width(win)
                    -- Only resize if width doesn't match and we're not in a nested resize
                    if current_width ~= width then
                      -- Use cmd instead of API to ensure smoother visual transition
                      vim.cmd("silent! " .. width .. "wincmd |")
                    end
                    break
                  end
                end
              end, 16)  -- One frame @60fps
            end, 0)     -- Next event loop iteration
          else
            -- Fallback if nvimtree is not available
            pcall(function() 
              local api = _G.NvimTreePersistence.api
              api.tree.open() 
            end)
            _G.NvimTreePersistence.is_open = true
            _G.NvimTreePersistence.opening = false
          end
        end,
        
        -- Custom close function to save width before closing
        close = function()
          -- Save current width before closing (using our direct method)
          _G.NvimTreePersistence.save_width()
          
          -- Close the tree using the API
          local api = _G.NvimTreePersistence.api
          pcall(function()
            api.tree.close()
          end)
          
          -- Update state
          _G.NvimTreePersistence.is_open = false
        end,
        
        -- Custom toggle function that preserves width
        toggle = function(opts)
          -- If we're currently in the process of opening, do nothing to avoid flicker
          if _G.NvimTreePersistence.opening then
            return
          end
          
          -- More reliable way to check if tree is open
          local is_visible = false
          
          -- Check all windows for NvimTree
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local buf_ft = vim.bo[buf].filetype
            
            if buf_ft == "NvimTree" then
              is_visible = true
              break
            end
          end
          
          -- Set our state based on what we found
          _G.NvimTreePersistence.is_open = is_visible
          
          -- Toggle based on actual visibility
          if is_visible then
            _G.NvimTreePersistence.close()
          else
            _G.NvimTreePersistence.open(opts)
          end
        end
      }
    end
    
    -- Always update the API reference in case it's changed
    _G.NvimTreePersistence.api = api

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    local function on_attach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- custom mappings
      local keymap = vim.keymap -- for conciseness
      keymap.set('n', '<CR>', api.node.open.tab, opts('Open'))
      keymap.set('n', '<S-M>', api.node.show_info_popup, opts('Info'))
      keymap.set('n', 'h', api.node.navigate.parent_close, opts('Close Directory'))
      keymap.set('n', 'l', api.node.open.edit, opts('Open'))
      keymap.set('n', 'J', api.node.navigate.sibling.last, opts('Last Sibling'))
      keymap.set('n', 'K', api.node.navigate.sibling.first, opts('First Sibling'))
      keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
      keymap.set('n', 'a', api.fs.create, opts('Create'))
      keymap.set('n', 'y', api.fs.copy.node, opts('Copy'))
      keymap.set('n', 'd', api.fs.remove, opts('Delete'))
      keymap.set('n', 'D', api.fs.trash, opts('Trash'))
      keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
      keymap.set('n', 'H', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
      keymap.set('n', 'p', api.fs.paste, opts('Paste'))
      keymap.set('n', 'O', api.node.navigate.parent, opts('Parent Directory'))
      keymap.set('n', 'q', api.tree.close, opts('Close'))
      keymap.set('n', 'r', api.fs.rename, opts('Rename'))
      keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
      keymap.set('n', 'o', api.node.run.system, opts('System Open'))
      keymap.set('n', 's', api.tree.search_node, opts('Search'))
      keymap.set('n', 'v', api.node.open.vertical, opts('Vertical Split'))
      keymap.set('n', 'x', api.fs.cut, opts('Cut'))
      keymap.set('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
      -- keymap.set('n', '<BS>',  api.node.navigate.parent_close,        opts('Close Directory'))
      -- keymap.set('n', '<CR>',  api.node.open.edit,                    opts('Open'))
      -- keymap.set('n', '<C-r>', api.fs.rename_sub,                     opts('Rename: Omit Filename'))
      -- keymap.set('n', 'j',     api.node.navigate.sibling.next,        opts('Next Sibling'))
      -- keymap.set('n', 'k',     api.node.navigate.sibling.prev,        opts('Previous Sibling'))
      -- keymap.set('n', 'e',     api.fs.rename_basename,                opts('Rename: Basename'))
    end

    -- Set up autocmds
    _G.NvimTreePersistence.setup_autocmds()
    
    -- Add commands to use our persistence module functions
    vim.api.nvim_create_user_command('NvimTreeCustomOpen', function()
      _G.NvimTreePersistence.open()
    end, {})
    
    vim.api.nvim_create_user_command('NvimTreeCustomClose', function()
      _G.NvimTreePersistence.close()
    end, {})
    
    vim.api.nvim_create_user_command('NvimTreeCustomToggle', function()
      _G.NvimTreePersistence.toggle()
    end, {})
    
    -- Override existing toggle function with our custom version
    api.tree.toggle = function(find_file, no_focus)
      _G.NvimTreePersistence.toggle({
        find_file = find_file,
        focus = not no_focus
      })
    end
    
    -- Create an autocommand to match NvimTree header bg with bufferline
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        -- Get background color from Directory highlight group which is used by bufferline
        local bufferline_hl = vim.api.nvim_get_hl(0, { name = "Directory" })
        local bg_color = bufferline_hl.bg
        
        if bg_color then
          -- Convert decimal bg_color to hex if needed
          local hex_bg_color
          if type(bg_color) == "number" then
            hex_bg_color = string.format("#%06x", bg_color)
          else
            hex_bg_color = bg_color
          end
          
          -- Set NvimTreeTitle highlight group to match bufferline
          vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { bg = hex_bg_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeTitle", { bg = hex_bg_color })
        end
      end
    })
    
    -- Trigger the colorscheme handler once on startup
    vim.defer_fn(function()
      vim.cmd("doautocmd ColorScheme")
    end, 100)

    -- Set default width in the global module
    _G.NvimTreePersistence.default_width = 30
    
    -- configure nvim-tree
    nvimtree.setup({
      on_attach = on_attach,
      actions = {
        open_file = {
          quit_on_open = true,
          eject = true,
          resize_window = true,
          window_picker = {
            enable = true,
            picker = "default",
            chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            exclude = {
              filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
              buftype = { "nofile", "terminal", "help" },
            },
          },
        },
        change_dir = {
          enable = false,
          global = false,
          restrict_above_cwd = false,
        },
        use_system_clipboard = true,
        expand_all = {
          max_folder_discovery = 300,
          exclude = {},
        },
        file_popup = {
          open_win_config = {
            col = 1,
            row = 1,
            relative = "cursor",
            border = "shadow",
            style = "minimal",
          },
        },
        remove_file = {
          close_window = true,
        },
      },
      git = {
        enable = true,
        show_on_dirs = true,
        -- show_on_open_dirs = true,
        disable_for_dirs = {},
        timeout = 500,
        cygwin_support = false,
      },
      filters = {
        git_ignored = false,
        dotfiles = false,
        git_clean = false,
        no_buffer = false,
        no_bookmark = false,
        -- custom = { ".git" },
        -- custom = { ".DS_Store" },
        exclude = {},
      },
      update_focused_file = {
        enable = true,
        update_root = true,
        ignore_list = {},
        update_cwd = true,
      },
      renderer = {
        add_trailing = false,
        group_empty = false,
        full_name = false,
        root_folder_label = ":t",
        indent_width = 2,
        special_files = {},
        symlink_destination = true,
        highlight_git = false,
        highlight_diagnostics = false,
        highlight_opened_files = "none",
        highlight_modified = "none",
        highlight_bookmarks = "none",
        highlight_clipboard = "name",
        indent_markers = {
          enable = false,
          inline_arrows = true,
          icons = {
            corner = "└",
            edge = "│",
            item = "│",
            bottom = "─",
            none = " ",
          },
        },
        icons = {
          web_devicons = {
            file = {
              enable = true,
              color = true,
            },
            folder = {
              enable = false,
              color = true,
            },
          },
          git_placement = "before",
          modified_placement = "after",
          diagnostics_placement = "signcolumn",
          bookmarks_placement = "signcolumn",
          padding = " ",
          symlink_arrow = " ➛ ",
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
            modified = true,
            diagnostics = true,
            bookmarks = false,
          },
          glyphs = {
            default = "",
            -- toml = "󰰤", -- Change this to the desired icon for TOML files
            symlink = "",
            bookmark = "󰆤",
            modified = "●",
            folder = {
              arrow_closed = "",
              arrow_open = "",
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "➜",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "★",
              deleted = "✗",
              -- deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
          min = vim.diagnostic.severity.HINT,
          max = vim.diagnostic.severity.ERROR,
        },
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        },
      },
      hijack_cursor = false,
      auto_reload_on_write = true,
      disable_netrw = false,
      hijack_netrw = true,
      hijack_unnamed_buffer_when_opening = false,
      root_dirs = {},
      prefer_startup_root = false,
      sync_root_with_cwd = false,
      reload_on_bufenter = false,
      respect_buf_cwd = false,
      select_prompts = false,
      sort = {
        sorter = "name",
        folders_first = true,
        files_first = false,
      },
      view = {
        centralize_selection = false,
        cursorline = true,
        debounce_delay = 15,
        side = "left",
        preserve_window_proportions = false,
        number = false,
        relativenumber = false,
        signcolumn = "yes",
        width = 30,
        float = {
          enable = false,
          quit_on_focus_loss = true,
          open_win_config = {
            relative = "editor",
            border = "rounded",
            width = 30,
            height = 30,
            row = 1,
            col = 1,
          },
        },
      },
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      system_open = {
        cmd = "",
        args = {},
      },
      modified = {
        enable = false,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },
      live_filter = {
        prefix = "[FILTER]: ",
        always_show_folders = true,
      },
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
        ignore_dirs = {},
      },
      trash = {
        cmd = "gio trash",
      },
      tab = {
        sync = {
          open = false,
          close = false,
          ignore = {},
        },
      },
      notify = {
        threshold = vim.log.levels.ERROR,
        absolute_path = true,
      },
      help = {
        sort_by = "key",
      },
      ui = {
        confirm = {
          remove = true,
          trash = true,
          default_yes = true,
        },
      },
      experimental = {},
      log = {
        enable = false,
        truncate = false,
        types = {
          all = false,
          config = false,
          copy_paste = false,
          dev = false,
          diagnostics = false,
          git = false,
          profile = false,
          watcher = false,
        },
      },
    })
  end
}

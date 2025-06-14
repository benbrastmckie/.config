-- Create a global module for NvimTree width persistence
-- This ensures the callbacks can always access it across Neovim's runtime
_G.NvimTreePersistence = _G.NvimTreePersistence or {}

-- Initialize the width directly in the global scope (outside of any function)
-- This ensures it's available before any code runs
if not _G.NvimTreePersistence.width then
  -- Try to read from a file first if we have one
  local width_file = vim.fn.stdpath("data") .. "/nvim_tree_width"
  local width = 30 -- Default width

  -- Try to read the stored width
  pcall(function()
    if vim.fn.filereadable(width_file) == 1 then
      local file_content = vim.fn.readfile(width_file)
      if file_content and file_content[1] then
        local stored_width = tonumber(file_content[1])
        if stored_width and stored_width > 10 and stored_width < 100 then
          width = stored_width
        end
      end
    end
  end)

  -- Store the width directly in the global object
  _G.NvimTreePersistence.width = width
end

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local nvimtree = require("nvim-tree")
    local api = require("nvim-tree.api")

    -- Initialize the global module if not already done
    if not _G.NvimTreePersistence.initialized then
      -- If width is not set in the global scope, try to read from file
      if not _G.NvimTreePersistence.width then
        local width_file = vim.fn.stdpath("data") .. "/nvim_tree_width"
        local width = 30 -- Standard default

        pcall(function()
          if vim.fn.filereadable(width_file) == 1 then
            local file_content = vim.fn.readfile(width_file)
            if file_content and file_content[1] then
              local stored_width = tonumber(file_content[1])
              if stored_width and stored_width > 10 and stored_width < 100 then
                width = stored_width
              end
            end
          end
        end)

        _G.NvimTreePersistence.width = width
      end

      -- Initialize the rest of the module
      _G.NvimTreePersistence = vim.tbl_extend("force", _G.NvimTreePersistence, {
        -- Keep track of whether the tree is currently open
        is_open = false,

        -- Use our stored width as the default now
        default_width = _G.NvimTreePersistence.width or 30,

        -- Flag to prevent multiple initializations
        initialized = true,

        -- Store reference to the API for use in methods
        api = api,

        -- Get current width (fallback to default if not set)
        get_width = function()
          return _G.NvimTreePersistence.width or _G.NvimTreePersistence.default_width
        end,

        -- Save the current tree width (both in memory and to a file)
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
          if found_width and found_width > 10 and found_width ~= _G.NvimTreePersistence.width then
            -- Save to the global module
            _G.NvimTreePersistence.width = found_width

            -- Update the default_width as well to avoid mismatches
            _G.NvimTreePersistence.default_width = found_width

            -- Also save to a file for persistence across sessions
            local width_file = vim.fn.stdpath("data") .. "/nvim_tree_width"
            pcall(function()
              vim.fn.writefile({ tostring(found_width) }, width_file)
            end)

            -- Immediately update the Neovim module config to avoid the two-step problem
            pcall(function()
              local nvimtree = require("nvim-tree")
              if nvimtree and nvimtree.config and nvimtree.config.view then
                nvimtree.config.view.width = found_width
              end

              -- Also try to update the state in the view module directly
              local view = package.loaded["nvim-tree.view"]
              if view then
                if view.View and view.View.width then
                  view.View.width = found_width
                end
                if view._config and view._config.width then
                  view._config.width = found_width
                end
              end
            end)
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

          -- More aggressive approach: override the width in all possible places
          -- 1. Set an autocmd to be triggered when window is created (highest priority)
          local winenter_augroup = vim.api.nvim_create_augroup("NvimTreeSingleStepOpen", { clear = true })
          vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "BufEnter" }, {
            group = winenter_augroup,
            pattern = { "NvimTree*" },
            once = true,              -- Only trigger once
            callback = function()
              vim.schedule(function() -- Use schedule to ensure we run after window creation
                -- Find the NvimTree window
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  if vim.bo[buf].filetype == "NvimTree" then
                    -- Force correct width with no animation - critical for seamless opening
                    vim.api.nvim_win_set_width(win, width)
                    vim.api.nvim_win_set_option(win, "winfixwidth", true)

                    -- We're using api.nvim_win_set_option above, which is better
                    -- than using vim.wo since we have the window handle
                    break
                  end
                end
              end)
            end
          })

          -- 2. Directly update configuration in all possible locations
          pcall(function()
            -- Update any loaded modules that might store width
            for _, module_name in ipairs({ "nvim-tree", "nvim-tree.view", "nvim-tree.lib", "nvim-tree.renderer" }) do
              local module = package.loaded[module_name]
              if module then
                -- Try various possible width storage locations
                if module.config and module.config.view then
                  module.config.view.width = width
                end
                if module.View then
                  module.View.width = width
                end
                if module._config then
                  module._config.width = width
                end
              end
            end

            -- Also set the width in the live config
            if nvimtree and nvimtree.config and nvimtree.config.view then
              nvimtree.config.view.width = width
            end
          end)

          -- Inject width into config before opening
          if nvimtree and nvimtree.setup then
            -- Apply width to all config locations to ensure it's used
            pcall(function()
              -- Direct config modification
              if nvimtree.config and nvimtree.config.view then
                nvimtree.config.view.width = width
              end

              -- Also modify any other view-related configs that might be used
              local tree_module = package.loaded["nvim-tree.view"] or {}
              if tree_module._config then
                tree_module._config.width = width
              end
            end)

            -- Open the tree in a single operation
            local api = _G.NvimTreePersistence.api

            -- Use pcall to handle any errors during opening
            pcall(function()
              -- Use the open call with width parameter
              api.tree.open({ width = width })
            end)

            -- Set state after a very short delay to allow window to open
            vim.defer_fn(function()
              _G.NvimTreePersistence.opening = false
              _G.NvimTreePersistence.is_open = true

              -- Apply settings to NvimTree buffer
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype == "NvimTree" then
                  -- Make sure the width is correct
                  if vim.api.nvim_win_get_width(win) ~= width then
                    vim.api.nvim_win_set_width(win, width)
                  end

                  -- Fix the width to prevent unwanted resizing
                  vim.api.nvim_win_set_option(win, "winfixwidth", true)

                  -- Apply buffer settings
                  vim.b.minicursorword_disable = true
                  vim.b.local_highlight_enabled = false
                  vim.opt_local.hlsearch = false
                  break
                end
              end

              -- Apply highlight colors
              vim.cmd("doautocmd ColorScheme")
            end, 10) -- Very short delay
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

        -- Enhanced toggle function that preserves width with visual consistency
        toggle = function(opts)
          -- If we're currently in the process of opening, do nothing to avoid flicker
          if _G.NvimTreePersistence.opening then
            return
          end

          -- More reliable way to check if tree is open
          local is_visible = false
          local tree_win = nil

          -- Check all windows for NvimTree and capture the window handle
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local buf_ft = vim.bo[buf].filetype

            if buf_ft == "NvimTree" then
              is_visible = true
              tree_win = win
              break
            end
          end

          -- Set our state based on what we found
          _G.NvimTreePersistence.is_open = is_visible

          -- If tree is open, ensure we capture the current width before closing
          if is_visible and tree_win then
            -- Get the actual width directly from the window to ensure accuracy
            local current_width = vim.api.nvim_win_get_width(tree_win)
            if current_width and current_width > 10 then -- Sanity check
              _G.NvimTreePersistence.width = current_width
            end
            _G.NvimTreePersistence.close()
          else
            -- Set opening flag to prevent potential issues
            _G.NvimTreePersistence.opening = true

            -- Call our enhanced open function
            _G.NvimTreePersistence.open(opts)
          end
        end
      })
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

    -- Add options to the NvimTree setup to handle horizontal scrolling and styling
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "NvimTree",
      callback = function()
        -- Apply local options to prevent horizontal scrolling
        vim.wo.wrap = false             -- Don't wrap long lines
        vim.wo.sidescrolloff = 0        -- No side scrolling offset
        vim.opt_local.list = false      -- Don't show invisible characters
        vim.opt_local.linebreak = false -- Don't break at words

        -- Apply our custom highlight colors for directories
        -- Soft light purple for directories
        local dir_color = "#b294bb"

        -- Apply the color
        vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = dir_color })
        vim.api.nvim_set_hl(0, "NvimTreeSymlinkFolderName", { fg = dir_color, bold = true })
        vim.api.nvim_set_hl(0, "NvimTreeSpecialFolderName", { fg = dir_color, bold = true, italic = true })
        vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = dir_color })
        vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = dir_color })

        -- Set the root folder with normal background (to match regular tree items)
        vim.api.nvim_set_hl(0, "NvimTreeRootFolder", {
          fg = dir_color,
          bg = nil, -- No background
          bold = true,
          italic = true
        })

        -- Set the Directory highlight separately for the top header
        local header_bg = vim.fn.synIDattr(vim.fn.hlID("TabLineFill"), "bg#")
        if header_bg and header_bg ~= "" then
          vim.api.nvim_set_hl(0, "Directory", {
            fg = dir_color,
            bg = header_bg,
            bold = true
          })
        end
      end,
      desc = "Set NvimTree appearance and behavior options"
    })

    -- Set up autocommands for NvimTree custom settings
    local nvim_tree_autocmds = vim.api.nvim_create_augroup("NvimTreeCustomSettings", { clear = true })

    -- Add ColorScheme handler to ensure colors are reapplied when colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = nvim_tree_autocmds,
      callback = function()
        -- Check if NvimTree is loaded before applying
        if vim.fn.exists(":NvimTreeToggle") == 2 then
          -- Apply our custom highlight colors for directories
          local dir_color = "#b294bb" -- Soft light purple

          -- Regular directories in the file tree should have no background
          vim.api.nvim_set_hl(0, "NvimTreeRootFolder", {
            fg = dir_color,
            bg = nil, -- No background
            bold = true,
            italic = true
          })

          -- Top path should have darker background (from bufferline)
          local header_bg = vim.fn.synIDattr(vim.fn.hlID("TabLineFill"), "bg#")
          if header_bg and header_bg ~= "" then
            vim.api.nvim_set_hl(0, "Directory", {
              fg = dir_color,
              bg = header_bg,
              bold = true
            })
          end
        end
      end,
      desc = "Update NvimTree highlights when colorscheme changes"
    })

    -- Handle word highlighting and scrolling behavior
    vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
      group = nvim_tree_autocmds,
      pattern = "NvimTree",
      callback = function(ev)
        -- For mini.cursorword (mini.nvim plugin)
        vim.b.minicursorword_disable = true

        -- For local-highlight.nvim plugin
        vim.b.local_highlight_enabled = false

        -- For built-in 'hlsearch'
        vim.opt_local.hlsearch = false

        -- For other plugins that follow similar patterns
        vim.b.cursorword_disable = true
        vim.b.highlight_current_word_enabled = false

        -- For vim-illuminate plugin
        pcall(function()
          require('illuminate').pause_buf()
        end)

        -- Disable horizontal scrolling in NvimTree
        vim.opt_local.sidescrolloff = 0 -- No side scrolling offset
        vim.opt_local.hlsearch = false  -- No search highlight
        vim.opt_local.list = false      -- No list mode

        -- Set window options for better appearance
        pcall(function()
          -- These might not all be available but try them anyway
          vim.wo.breakindent = false
          vim.wo.linebreak = false
        end)

        -- Disable horizontal scroll commands to prevent side scrolling
        vim.keymap.set('n', '<ScrollWheelRight>', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', '<ScrollWheelLeft>', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', 'zl', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', 'zh', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', 'zL', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', 'zH', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', '<Right>', '<Nop>', { buffer = true, silent = true })
        vim.keymap.set('n', '<Left>', '<Nop>', { buffer = true, silent = true })
      end
    })

    -- Handle window entry to ensure consistent NvimTree appearance
    vim.api.nvim_create_autocmd("WinEnter", {
      group = nvim_tree_autocmds,
      callback = function()
        -- Check if the current buffer is NvimTree
        if vim.bo.filetype == "NvimTree" then
          -- Apply window-specific options to prevent horizontal scrolling
          vim.wo.wrap = false
          vim.wo.sidescrolloff = 0
          vim.wo.list = false

          -- Apply visual settings consistently
          vim.wo.cursorline = true      -- Highlight current line
          vim.wo.signcolumn = "yes"     -- Show sign column
          vim.wo.number = false         -- No line numbers
          vim.wo.relativenumber = false -- No relative line numbers
        end
      end,
      desc = "Consistent NvimTree window settings"
    })

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
        -- Get background colors from multiple highlight groups to find the best match
        local function get_highlight_attr(group, attr)
          local hl = vim.api.nvim_get_hl(0, { name = group })
          return hl and hl[attr]
        end

        local function get_highlight_bg(group)
          return get_highlight_attr(group, "bg")
        end

        local function get_highlight_fg(group)
          return get_highlight_attr(group, "fg")
        end

        -- Try several highlight groups used by bufferline in order of preference
        local highlight_groups = {
          "BufferLineFill",       -- Background of the entire bufferline
          "BufferlineBackground", -- Another bufferline background group
          "TabLineFill",          -- Default tab line background
          "BufferInactive",       -- Inactive buffer color
          "TabLine",              -- Another tab line group
          "StatusLine",           -- Status line background
          "Normal",               -- Fallback to normal background
        }

        -- Try each highlight group until we find one with a bg color
        local bg_color
        local matched_group
        for _, group in ipairs(highlight_groups) do
          bg_color = get_highlight_bg(group)
          if bg_color then
            matched_group = group
            break
          end
        end

        -- If we still don't have a color, try to get it from other UI elements
        if not bg_color then
          bg_color = get_highlight_bg("StatusLineNC") or
              get_highlight_bg("VertSplit") or
              get_highlight_bg("LineNr") or
              get_highlight_bg("SignColumn")
        end

        -- Apply the color if found
        if bg_color then
          -- Convert decimal bg_color to hex if needed
          local hex_bg_color
          if type(bg_color) == "number" then
            hex_bg_color = string.format("#%06x", bg_color)
          else
            hex_bg_color = bg_color
          end

          -- For the text/foreground color, try to get it from the matched group
          -- or use a default that contrasts with the background
          local fg_color = matched_group and get_highlight_fg(matched_group) or get_highlight_fg("Normal")
          local hex_fg_color
          if fg_color and type(fg_color) == "number" then
            hex_fg_color = string.format("#%06x", fg_color)
          elseif fg_color then
            hex_fg_color = fg_color
          end

          -- Set up text color with proper contrast if none found
          if not hex_fg_color then
            -- Default to white text on dark backgrounds and black text on light backgrounds
            -- Simple luminance test (can be improved)
            local r, g, b = tonumber(hex_bg_color:sub(2, 3), 16) or 0,
                tonumber(hex_bg_color:sub(4, 5), 16) or 0,
                tonumber(hex_bg_color:sub(6, 7), 16) or 0
            local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
            hex_fg_color = luminance > 0.5 and "#000000" or "#FFFFFF"
          end

          -- =================== DIRECTORY TEXT STYLING ===================
          -- Use a soft light purple color for directories to make them stand out

          -- Define a soft light purple color for directories
          local dir_color = "#b294bb" -- Soft light purple

          -- =================== ROOT PATH STYLING ===================
          -- For the top text showing the current directory - should match bufferline background

          -- The root path at the top of nvim-tree uses the Directory highlight group
          -- This should match the bufferline tab background color
          vim.api.nvim_set_hl(0, "Directory", {
            fg = dir_color,
            bg = hex_bg_color,
            bold = true
          })

          -- =================== TREE DIRECTORY STYLING ===================
          -- Regular directories in the tree should have no background (transparent)

          -- Apply the directory color to all folder-related highlights in the tree (no background)
          vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = dir_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = dir_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = dir_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = dir_color })

          -- Root folder in the tree content (not the header) should match other directories
          vim.api.nvim_set_hl(0, "NvimTreeRootFolder", {
            fg = dir_color,
            bg = nil, -- Transparent background to match other tree directories
            bold = true,
            italic = true
          })

          -- =================== HEADER & TITLE ELEMENTS ===================
          -- These are additional header elements that should also match bufferline

          -- Main header highlight
          vim.api.nvim_set_hl(0, "NvimTreeTitle", {
            fg = hex_fg_color,
            bg = hex_bg_color
          })

          -- General header background
          vim.api.nvim_set_hl(0, "NvimTreeHeader", {
            bg = hex_bg_color
          })

          -- Window picker (used when selecting windows with nvim-tree)
          vim.api.nvim_set_hl(0, "NvimTreeWindowPicker", {
            fg = hex_fg_color,
            bg = hex_bg_color,
            bold = true
          })

          -- Ensure special folder states also use the same color
          vim.api.nvim_set_hl(0, "NvimTreeSymlinkFolderName", { fg = dir_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeSpecialFolderName", { fg = dir_color, bold = true, italic = true })

          -- Make folder arrows match the directory color
          vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = dir_color })
          vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = dir_color })

          -- =================== GIT STATUS ELEMENTS ===================
          -- Use the same colors as GitSigns for consistency

          -- Get colors from GitColors global or use defaults
          local add_color = _G.GitColors and _G.GitColors.add or "#4fa6ed"       -- Light blue
          local change_color = _G.GitColors and _G.GitColors.change or "#e78a4e" -- Soft rust orange
          local delete_color = _G.GitColors and _G.GitColors.delete or "#fb4934" -- Red

          -- Apply consistent git colors for NvimTree
          vim.api.nvim_set_hl(0, "NvimTreeGitNew", { fg = add_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { fg = change_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeGitStaged", { fg = add_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeGitMerge", { fg = change_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeGitRenamed", { fg = change_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeGitDeleted", { fg = delete_color, bold = true })

          -- Apply colors to modified indicator (which shows next to files)
          vim.api.nvim_set_hl(0, "NvimTreeFileStaged", { fg = add_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeFileDirty", { fg = change_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeFileRenamed", { fg = change_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeFileNew", { fg = add_color, bold = true })
          vim.api.nvim_set_hl(0, "NvimTreeFileDeleted", { fg = delete_color, bold = true })

          -- Also set the modified symbol color
          vim.api.nvim_set_hl(0, "NvimTreeModifiedFile", { fg = change_color, bold = true })

          -- =================== FOLDER & FILE ELEMENTS ===================
          -- We'll preserve their original foreground colors but apply our bg if needed

          -- Set file/folder elements with their original fg colors
          local preserve_fg_groups = {
            "NvimTreeSymlink",
            "NvimTreeFolderName",
            "NvimTreeOpenedFolderName",
            "NvimTreeEmptyFolderName",
            "NvimTreeFolderIcon",
            "NvimTreeFileIcon",
            "NvimTreeFileName",
            "NvimTreeIndentMarker",
            "NvimTreeExecFile",
            "NvimTreeSpecialFile",
            "NvimTreeImageFile",
          }

          -- Preserve foreground colors but ensure proper background
          for _, group in ipairs(preserve_fg_groups) do
            local current = vim.api.nvim_get_hl(0, { name = group })
            if current then
              -- Only override the background
              vim.api.nvim_set_hl(0, group, {
                fg = current.fg,
                bg = nil, -- Let it inherit from NvimTreeNormal
                bold = current.bold,
                italic = current.italic,
                underline = current.underline,
              })
            end
          end

          -- =================== MAIN BACKGROUND ===================
          -- Set the main background of NvimTree

          -- Get main editor background for NvimTree content area
          local normal_bg = get_highlight_bg("Normal")
          if normal_bg then
            local normal_hex_bg
            if type(normal_bg) == "number" then
              normal_hex_bg = string.format("#%06x", normal_bg)
            else
              normal_hex_bg = normal_bg
            end

            -- Set NvimTree's main background to match the editor
            vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = normal_hex_bg })
            vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = normal_hex_bg })
          end

          -- We no longer need to log styling information
          -- Silent operation is preferred
        else
          -- Silent operation is preferred, no logging needed
        end
      end
    })

    -- Trigger the colorscheme handler multiple times to ensure styling applies
    -- First immediate application
    vim.schedule(function()
      vim.cmd("doautocmd ColorScheme")
    end)

    -- Second application after a short delay (for race conditions with other plugins)
    vim.defer_fn(function()
      vim.cmd("doautocmd ColorScheme")
    end, 100)

    -- Final application after UI is fully loaded
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("doautocmd ColorScheme")

        -- Set up a custom highlight for truncated lines in NvimTree
        vim.api.nvim_set_hl(0, "NvimTreeTruncateLine", {
          fg = "#666666", -- Light gray
          italic = true
        })
      end,
      once = true
    })

    -- Set default width in the global module using the persisted value
    if not _G.NvimTreePersistence.width then
      _G.NvimTreePersistence.width = 30
    end
    _G.NvimTreePersistence.default_width = _G.NvimTreePersistence.width

    -- Pre-configure the view width before setup
    local initial_width = _G.NvimTreePersistence.width

    -- Directly modify the NvimTree view module if available
    pcall(function()
      local view = package.loaded["nvim-tree.view"]
      if view then
        if view.View then view.View.width = initial_width end
        if view._config then view._config.width = initial_width end
      end
    end)

    -- Configure nvim-tree with our persisted width
    nvimtree.setup({
      on_attach = function(bufnr)
        -- Call the original on_attach
        on_attach(bufnr)

        -- Fix the width to prevent automatic resizing
        -- Get the window ID for the buffer
        local win_id = vim.fn.bufwinid(bufnr)
        if win_id ~= -1 then
          vim.api.nvim_win_set_option(win_id, "winfixwidth", true)
        end
      end,
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
        root_folder_label = ":t",    -- Only show the last component of the path
        root_folder_modifier = ":t", -- Only show the root folder name, not the full path
        indent_width = 2,
        special_files = {},
        symlink_destination = true,
        highlight_git = true, -- Enable git highlighting so our colors are used
        highlight_diagnostics = false,
        highlight_opened_files = "none",
        highlight_modified = "name", -- Show modified indicator next to file names
        highlight_bookmarks = "none",
        highlight_clipboard = "name",
        -- Removed unsupported options (truncate_names, trailing_slash)
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
            modified = "◉", -- Larger modified indicator with rust orange color
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
        adaptive_size = false, -- Don't automatically resize the window
        centralize_selection = false,
        cursorline = true,
        debounce_delay = 0,                 -- Eliminate debounce delay for immediate rendering
        side = "left",
        preserve_window_proportions = true, -- Maintain proportions to prevent resizing
        number = false,
        relativenumber = false,
        signcolumn = "yes",
        width = initial_width, -- Use stored width from the beginning
        -- Removed unsupported options (width_increment, wrap, scrolloff)
        float = {
          enable = false, -- Disable floating mode
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
        enable = true,            -- Enable the modified status tracking
        show_on_dirs = true,      -- Show on directories
        show_on_open_dirs = true, -- Show on open directories
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

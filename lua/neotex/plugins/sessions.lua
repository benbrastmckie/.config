return {
  "Shatur/neovim-session-manager",
  event = "VimEnter",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    local Path = require('plenary.path')
    local config = require('session_manager.config')
    require('session_manager').setup({
      -- sessions_dir = Path:new(vim.fn.stdpath('data'), 'sessions'), -- The directory where the session files will be saved.
      sessions_dir = Path:new(vim.fn.stdpath('config'), 'sessions'), -- The directory where the session files will be saved.
      -- session_filename_to_dir =  '~/.config/nvim/sessions/', -- Function that replaces symbols into separators and colons to transform filename into a session directory.
      -- dir_to_session_filename = '~/.config/nvim/sessions/', -- Function that replaces separators and colons into special symbols to transform session directory into a filename. Should use `vim.uv.cwd()` if the passed `dir` is `nil`.
      -- path_replacer = '__', -- The character to which the path separator will be replaced for session files.
      -- colon_replacer = '++', -- The character to which the colon symbol will be replaced for session files.
      autoload_mode = config.AutoloadMode.Disabled, -- Define what to do when Neovim is started without arguments. See "Autoload mode" section below.
      autosave_last_session = true, -- Automatically save last session on exit and on session switch.
      autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
      autosave_ignore_dirs = {}, -- A list of directories where the session will not be autosaved.
      autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
        'gitcommit',
        'gitrebase',
      },
      autosave_ignore_buftypes = {}, -- All buffers of these bufer types will be closed before the session is saved.
      autosave_only_in_session = true, -- Always autosaves session. If true, only autosaves after a session is active.
      max_path_length = 80,  -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
    })
  end,
}



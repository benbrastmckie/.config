return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  -- ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = {
      enabled = false,
      notify = true,
      size = 100 * 1024,   -- 100 KB
    },
    bufdelete = { enabled = true },
    dashboard = {
      enabled = true,
      preset = require("neotex.plugins.snacks.dashboard").preset,
      sections = require("neotex.plugins.snacks.dashboard").sections,
      -- sections = require("neotex.plugins.snacks.gh_dashboard").sections,
    },
    git = { enabled = true },
    gitbrowse = { enabled = true },
    indent = {
      enabled = true,
      priority = 1,
      char = "|",
      only_scope = false,
      only_current = false,
      animate = { enabled = false },
      scope = {
        enabled = true, -- enable highlighting the current scope
        priority = 200,
        char = "│",
        underline = false, -- underline the start of the scope
        only_current = false, -- only show scope in the current window
        hl = "GruvboxGray", ---@type string|string[] hl group for scopes
      },
    },
    input = {
      enabled = true,
      -- backdrop = false,
      -- position = "float",
      -- border = "rounded",
      -- title_pos = "center",
      -- icon = "?",
      icon_hl = 'SnacksInputIcon',
      icon_pos = 'left',
      prompt_pos = 'title',
      win = { style = 'input' },
      expand = true,
    },
    lazygit = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 4000,
      width = { min = 40, max = 0.4 },
      height = { min = 1, max = 0.6 },
      margin = { top = 0, right = 1, bottom = 0 },
      padding = true,
      sort = { 'level', 'added' },
      level = vim.log.levels.TRACE,
      -- icons = {
      --     debug = icons.ui.Bug,
      --     error = icons.diagnostics.Error,
      --     info = icons.diagnostics.Information,
      --     trace = icons.ui.Bookmark,
      --     warn = icons.diagnostics.Warning,
      -- },
      style = 'compact',
      top_down = true,
      date_format = '%R',
      more_format = ' ↓ %d lines ',
      refresh = 50,
    },
    notify = { enabled = true },
    profiler = { enabled = false },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = {
      enabled = true,
      keys = {
        textobject = {
          ii = {
            min_size = 2,         -- minimum size of the scope
            edge = false,         -- inner scope
            cursor = false,
            treesitter = { blocks = { enabled = false } },
            desc = 'inner scope',
          },
          ai = {
            cursor = false,
            min_size = 2,         -- minimum size of the scope
            treesitter = { blocks = { enabled = false } },
            desc = 'full scope',
          },
        },
        jump = {
          ['[a'] = {
            min_size = 1,         -- allow single line scopes
            bottom = false,
            cursor = false,
            edge = true,
            treesitter = { blocks = { enabled = false } },
            desc = 'jump to top edge of scope',
          },
          ['];'] = {
            min_size = 1,         -- allow single line scopes
            bottom = true,
            cursor = false,
            edge = true,
            treesitter = { blocks = { enabled = false } },
            desc = 'jump to bottom edge of scope',
          },
        },
      },
    },
    scratch = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = {
        enabled = true,
        left = { 'mark', 'sign' },
        right = { 'fold', 'git' },
        folds = {
            open = false,
            git_hl = false,
        },
        git = {
            patterns = { 'GitSign', 'MiniDiffSign' },
        },
        refresh = 50,
    },
    terminal = { enabled = true },
    toggle = { enabled = false },
    win = { enabled = true },
    words = { enabled = false },
    zen = {
        enabled = false,
        toggles = {
            dim = true,
            git_signs = false,
            mini_diff_signs = false,
            -- diagnostics = false,
            -- inlay_hints = false,
        },
        show = {
            statusline = false,
            tabline = false,
        },
        win = { style = 'zen' },
        zoom = {
            toggles = {},
            show = { statusline = true, tabline = true },
            win = {
                backdrop = false,
                width = 0,
            },
        },
    },
  },
}

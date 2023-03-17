local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_status_ok then
  return
end

local tree_cb = nvim_tree_config.nvim_tree_callback

-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
vim.g.nvim_tree_respect_buf_cwd = 1

nvim_tree.setup {
  -- sync_root_with_cwd = true,
  -- respect_buf_cwd = true,
  -- disable_netrw = true,
  -- hijack_netrw = true,
  -- respect_buf_cwd = false,
  -- update_cwd = false,
  actions = {
    open_file = {
      quit_on_open = true,
    },
    change_dir = {
      enable = true,
      global = false,
    },
  },
  git = {
      enable = true,
      ignore = false,
      timeout = 500,
    },
  filters = {
    custom = { ".git" },
  },
  update_focused_file = {
    enable = true,
    update_cwd = true,
    -- ignore_list = {},
    -- update_root = true,
  },
  renderer = {
    root_folder_modifier = ":t",
    icons = {
      glyphs = {
        default = "",
        symlink = "",
        folder = {
          arrow_open = "",
          arrow_closed = "",
          default = "",
          open = "",
          empty = "",
          empty_open = "",
          symlink = "",
          symlink_open = "",
        },
        git = {
          unstaged = "",
          staged = "S",
          unmerged = "",
          renamed = "➜",
          untracked = "U",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  view = {
    width = 30,
    side = "left",
    mappings = {
      list = {
        { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
        { key = "h", cb = tree_cb "close_node" },
        { key = "v", cb = tree_cb "vsplit" },
      },
    },
  },
}



return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- change color for arrows in tree to light blue
    vim.cmd([[ highlight NvimTreeFolderArrowClosed guifg=#3FC5FF ]])
    vim.cmd([[ highlight NvimTreeFolderArrowOpen guifg=#3FC5FF ]])

    local function on_attach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- custom mappings
    local keymap = vim.keymap -- for conciseness
    keymap.set('n', '<CR>',  api.node.open.tab,                    opts('Open'))
    keymap.set('n', '<S-M>', api.node.show_info_popup,              opts('Info'))
    keymap.set('n', 'h',  api.node.navigate.parent_close,        opts('Close Directory'))
    keymap.set('n', 'l',  api.node.open.edit,                    opts('Open'))
    keymap.set('n', 'J',     api.node.navigate.sibling.last,        opts('Last Sibling'))
    keymap.set('n', 'K',     api.node.navigate.sibling.first,       opts('First Sibling'))
    keymap.set('n', '-',     api.tree.change_root_to_parent,        opts('Up'))
    keymap.set('n', 'a',     api.fs.create,                         opts('Create'))
    keymap.set('n', 'c',     api.fs.copy.node,                      opts('Copy'))
    keymap.set('n', 'd',     api.fs.remove,                         opts('Delete'))
    keymap.set('n', 'D',     api.fs.trash,                          opts('Trash'))
    keymap.set('n', 'g?',    api.tree.toggle_help,                  opts('Help'))
    keymap.set('n', 'H',     api.tree.toggle_hidden_filter,         opts('Toggle Dotfiles'))
    keymap.set('n', 'p',     api.fs.paste,                          opts('Paste'))
    keymap.set('n', 'O',     api.node.navigate.parent,              opts('Parent Directory'))
    keymap.set('n', 'q',     api.tree.close,                        opts('Close'))
    keymap.set('n', 'r',     api.fs.rename,                         opts('Rename'))
    keymap.set('n', 'R',     api.tree.reload,                       opts('Refresh'))
    keymap.set('n', 's',     api.node.run.system,                   opts('Run System'))
    keymap.set('n', 'S',     api.tree.search_node,                  opts('Search'))
    keymap.set('n', 'x',     api.fs.cut,                            opts('Cut'))
    keymap.set('n', '<2-LeftMouse>',  api.node.open.edit,           opts('Open'))
    -- keymap.set('n', '<BS>',  api.node.navigate.parent_close,        opts('Close Directory'))
    -- keymap.set('n', '<CR>',  api.node.open.edit,                    opts('Open'))
    -- keymap.set('n', '<C-r>', api.fs.rename_sub,                     opts('Rename: Omit Filename'))
    -- keymap.set('n', 'j',     api.node.navigate.sibling.next,        opts('Next Sibling'))
    -- keymap.set('n', 'k',     api.node.navigate.sibling.prev,        opts('Previous Sibling'))
    -- keymap.set('n', 'e',     api.fs.rename_basename,                opts('Rename: Basename'))
    end

    -- configure nvim-tree
    nvimtree.setup ({
      on_attach = on_attach,
      actions = {
        open_file = {
          quit_on_open = true,
        },
        -- change_dir = {
        --   enable = true,
        --   global = false,
        -- },
      },
      git = {
          enable = true,
          ignore = false,
          timeout = 500,
        },
      filters = {
        custom = { ".git" },
        -- custom = { ".DS_Store" },
      },
      update_focused_file = {
        enable = true,
        -- update_cwd = true,
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
              -- arrow_closed = "", -- arrow when folder is closed
              -- arrow_open = "", -- arrow when folder is open
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
        side = "left"
      },
    })
  end
}

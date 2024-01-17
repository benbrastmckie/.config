return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Set header
    dashboard.section.header.val = {
      "                                                      ",
      " ███╗   ██╗███████╗ ██████╗ ████████╗███████╗██╗  ██╗ ",
      " ████╗  ██║██╔════╝██╔═══██╗╚══██╔══╝██╔════╝╚██╗██╔╝ ",
      " ██╔██╗ ██║█████╗  ██║   ██║   ██║   █████╗   ╚███╔╝  ",
      " ██║╚██╗██║██╔══╝  ██║   ██║   ██║   ██╔══╝   ██╔██╗  ",
      " ██║ ╚████║███████╗╚██████╔╝   ██║   ███████╗██╔╝ ██╗ ",
      " ╚═╝  ╚═══╝╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝ ",
      "                                                      ",
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button("s", "  Sessions", "<cmd>SessionManager load_session<CR>"),
      dashboard.button("r", "󰈚  Recent", ":Telescope oldfiles <CR>"),
      dashboard.button("e", "󰱼  Explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("f", "  Find", ":Telescope find_files <CR>"),
      dashboard.button("c", "  Config", ":e $MYVIMRC <CR>"),
      dashboard.button("i", "  Info", "<cmd>e ~/.config/CheatSheet.md<cr>"),
      dashboard.button("p", "  Plugins", "<cmd>Lazy<cr>"),
      dashboard.button("h", "  Checkhealth", "<cmd>checkhealth<cr>"),
      dashboard.button("q", "  Quit", "<cmd>qa!<CR>"),
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- Disable folding on alpha buffer
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}

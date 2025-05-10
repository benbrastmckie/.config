return {
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    build = "make install_jsregexp", -- Important for NixOS
    config = function()
      -- Completely avoid the problematic jsregexp
      vim.g.luasnip_no_community_snippets = true
      vim.g.luasnip_no_jsregexp = true
      
      -- Disable potential problematic integrations to ensure clean startup
      vim.g.luasnip_no_vscode_loader = true
      
      -- Initialize LuaSnip
      local ls = require("luasnip")
      ls.setup({
        history = true,
        update_events = "TextChanged,TextChangedI",
        delete_check_events = "TextChanged",
        enable_autosnippets = true,
      })
      
      -- Disable vscode snippet loading which is causing errors
      vim.g.luasnip_no_vscode_loader = true
      
      -- Defer loading snippets to avoid errors at startup
      vim.api.nvim_create_autocmd("InsertEnter", {
        callback = function()
          -- Load snippets safely
          local ok, loader = pcall(require, "luasnip.loaders.from_snipmate")
          if ok and loader then
            loader.load({ paths = "~/.config/nvim/snippets/" })
          end
        end,
        once = true,
      })
    end
  },
  {
    "saadparwaiz1/cmp_luasnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
  }
}
return {
  {
    "L3MON4D3/LuaSnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = {
      {
        "rafamadriz/friendly-snippets",
        config = function() end, -- Empty config to prevent auto-loading
      },
    },
    build = "make install_jsregexp", -- Important for NixOS
    config = function()
      -- Set all disabling flags before requiring luasnip
      vim.g.luasnip_no_community_snippets = true
      vim.g.luasnip_no_jsregexp = true
      vim.g.luasnip_no_vscode_loader = true
      
      -- Initialize LuaSnip with minimal configuration
      local ls = require("luasnip")
      ls.setup({
        history = true,
        update_events = "TextChanged,TextChangedI",
        enable_autosnippets = true,
      })
      
      -- Defer all snippet loading with a delay to ensure editor is fully loaded
      vim.defer_fn(function()
        -- Load snippets only when editor has been idle for a bit
        local ok, loader = pcall(require, "luasnip.loaders.from_snipmate")
        if ok and loader then
          loader.load({ paths = "~/.config/nvim/snippets/" })
        end
      end, 100)
    end
  },
  {
    "saadparwaiz1/cmp_luasnip",
    lazy = true,
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
  }
}
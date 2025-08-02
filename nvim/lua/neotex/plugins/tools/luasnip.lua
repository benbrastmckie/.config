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

      -- Load snippets immediately
      local ok, loader = pcall(require, "luasnip.loaders.from_snipmate")
      if ok and loader then
        loader.load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
      end
      
      -- Clear snippet jump points when leaving insert mode
      vim.api.nvim_create_autocmd("InsertLeave", {
        callback = function()
          if ls.session.current_nodes[vim.api.nvim_get_current_buf()] 
            and not ls.session.jump_active then
            ls.unlink_current()
          end
        end,
      })
      
      -- Add explicit keymaps for snippet navigation
      vim.keymap.set({"i", "s"}, "<C-l>", function()
        if ls.jumpable(1) then
          ls.jump(1)
        end
      end, { silent = true, desc = "Jump to next snippet field" })
      
      vim.keymap.set({"i", "s"}, "<C-h>", function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true, desc = "Jump to previous snippet field" })
    end
  }
}

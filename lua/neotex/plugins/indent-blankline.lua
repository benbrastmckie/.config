return {
  "lukas-reineke/indent-blankline.nvim",
  -- dependencies = {},
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("ibl").setup({
      -- indent_blankline_show_current_context = true,
      indent = {
        char = "│",
        tab_char = "│",
        highlight = "IblIndent",
        smart_indent_cap = true,
        priority = 1,
        repeat_linebreak = true,
      },
      scope = {
        enabled = true,
        char = nil,
        show_start = false,
        show_end = false,
        show_exact_scope = false,
        injected_languages = true,
        highlight = "IblScope",
        priority = 1024,
        include = {
          node_type = { ["*"] = { "*" } }, -- makes lines show on all blocks
        },
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "NvimTree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lspinfo",
          "checkhealth",
          "man",
          "gitcommit",
          "TelescopePrompt",
          "TelescopeResults",
          "",
        },
        buftypes = {
          "terminal",
          "nofile",
          "quickfix",
          "prompt",
        },
      },
    })
  end
}

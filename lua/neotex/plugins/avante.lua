return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = "*", -- Using latest version to get the most recent fixes, otherwise set to "false"
  init = function()
    -- Create autocmd for Avante buffer-specific mappings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "AvanteInput", "Avante" },
      callback = function()
        -- Create buffer-local insert mode mapping for toggle
        vim.api.nvim_buf_set_keymap(0, "i", "<C-t>", "<cmd>AvanteToggle<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(0, "n", "<C-t>", "<cmd>AvanteToggle<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(0, "n", "q", "<cmd>AvanteToggle<CR>", { noremap = true, silent = true })
        -- Add mapping to clear selected text
        vim.api.nvim_buf_set_keymap(0, "n", "<C-c>", "<cmd>AvanteReset<CR>", { noremap = true, silent = true })
        -- Set scrolloff to keep cursor in the middle
        vim.opt_local.scrolloff = 999
      end
    })
  end,
  opts = function()
    -- Default configuration
    local config = {
      provider = "claude",
      auto_suggestions_provider = "claude",
      system_prompt = "You are an expert mathematician, logician and computer scientist with deep knowledge of Neovim, Lua, and programming languages. Provide concise, accurate responses with code examples when appropriate. For mathematical content, use clear notation and step-by-step explanations.",
      -- Commented out MCP-related tools
      -- custom_tools = {
      --   require("mcphub.extensions.avante").mcp_tool(),
      -- },
      endpoint = "https://api.anthropic.com",
      -- model = "claude-3-7-sonnet-20250219",
      model = "claude-3-5-sonnet-20241022",
      force_model = true, -- Add this to enforce model selection
      temperature = 0.1, -- Slight increase for more creative responses
      max_tokens = 4096,
      top_p = 0.95, -- Add top_p for better response quality
      top_k = 40, -- Add top_k for better response filtering
      timeout = 60000, -- Increase timeout for complex queries
      dual_boost = {
        enabled = false,
        first_provider = "claude",
        second_provider = "openai",
        prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
        timeout = 60000,
      },
      fallback = {
        enabled = false, -- Enable fallback model if primary fails
        model = "claude-3-5-sonnet-20241022", -- More stable fallback model
        auto_retry = false,
      },
      behaviour = {
        enable_claude_text_editor_tool_mode = false,
        auto_suggestions = false,
        auto_set_highlight_group = false,
        auto_set_keymaps = false,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff = true,
        preserve_state = true,
        safe_mode = true, -- Add safe mode to handle potential iteration errors
      },
      mappings = {
        diff = {
          ours = "o",
          theirs = "t",
          all_theirs = "a",
          both = "b",
          cursor = "c",
          next = "<C-j>",
          prev = "<C-k>",
        },
        suggestion = {
          accept = "<C-l>",
          next = "<C-j>",
          prev = "<C-k>",
          dismiss = "<C-h>",
        },
        jump = {
          next = "n",
          prev = "N",
        },
        submit = {
          normal = "<CR>",
          insert = "<C-l>",
        },
        sidebar = {
          apply_all = "A",
          apply_cursor = "a",
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
        },
      },
      hints = { enabled = false },
      windows = {
        position = "right",
        wrap = true,
        width = 40,
        sidebar_header = {
          enabled = true,
          align = "left",
          rounded = false,
        },
        input = {
          rounded = true,
          prefix = "󰭹 ",
          height = 8,
        },
        edit = {
          border = "rounded",
          start_insert = true,
        },
        ask = {
          floating = false,
          start_insert = true,
          border = "rounded",
          focus_on_apply = "ours",
        },
      },
      highlights = {
        diff = {
          current = "DiffText",
          incoming = "DiffAdd",
        },
      },
      diff = {
        autojump = true,
        list_opener = "copen",
        override_timeoutlen = 500,
      },
    }

    return config
  end,
  build = "make",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}

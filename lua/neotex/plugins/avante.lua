return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = "*", -- Using latest version to get the most recent fixes, otherwise set to "false"
  init = function()
    -- Define provider models (moved to global scope for reuse)
    _G.provider_models = {
      claude = {
        "claude-3-5-sonnet-20241022",
        "claude-3-7-sonnet-20250219",
        "claude-3-opus-20240229",
      },
      openai = {
        "gpt-4o",
        "gpt-4-turbo",
        "gpt-4",
        "gpt-3.5-turbo",
      },
      gemini = {
        "gemini-1.5-pro",
        "gemini-1.5-flash",
        "gemini-pro",
      }
    }

    -- Initialize state
    _G.avante_cycle_state = _G.avante_cycle_state or {
      provider = "claude",
      model_index = 1
    }

    -- Create autocmd for Avante buffer-specific mappings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "AvanteInput", "Avante" },
      callback = function()

        -- Explicitly map <CR> in insert mode to just create a new line
        vim.api.nvim_buf_set_keymap(0, "i", "<CR>", "<CR>",
          { noremap = true, silent = true, desc = "Create new line (prevent submit)" })

        -- Toggle Avante interface
        vim.api.nvim_buf_set_keymap(0, "n", "<C-t>", "<cmd>AvanteToggle<CR>",
          { noremap = true, silent = true, desc = "Toggle Avante interface" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-t>", "<cmd>AvanteToggle<CR>",
          { noremap = true, silent = true, desc = "Toggle Avante interface" })
        vim.api.nvim_buf_set_keymap(0, "n", "q", "<cmd>AvanteToggle<CR>",
          { noremap = true, silent = true, desc = "Toggle Avante interface" })

        -- Reset/clear Avante content
        vim.api.nvim_buf_set_keymap(0, "n", "<C-c>", "<cmd>AvanteReset<CR>",
          { noremap = true, silent = true, desc = "Reset Avante content" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-c>", "<cmd>AvanteReset<CR>",
          { noremap = true, silent = true, desc = "Reset Avante content" })

        -- Cycle AI models and providers
        vim.api.nvim_buf_set_keymap(0, "n", "<C-m>", "<cmd>lua cycle_ai_model()<CR>",
          { noremap = true, silent = true, desc = "Cycle AI models within provider" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-m>", "<cmd>lua cycle_ai_model()<CR>",
          { noremap = true, silent = true, desc = "Cycle AI models within provider" })
        vim.api.nvim_buf_set_keymap(0, "n", "<C-p>", "<cmd>lua cycle_ai_provider()<CR>",
          { noremap = true, silent = true, desc = "Cycle AI providers" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-p>", "<cmd>lua cycle_ai_provider()<CR>",
          { noremap = true, silent = true, desc = "Cycle AI providers" })

        vim.opt_local.scrolloff = 999
      end
    })
  end,
  opts = function()
    -- Default configuration
    local config = {
      -- Anthropic configuration
      provider = "claude",
      endpoint = "https://api.anthropic.com",
      model = "claude-3-5-sonnet-20241022",
      force_model = true, -- Add this to enforce model selection
      temperature = 0.1,  -- Slight increase for more creative responses
      max_tokens = 4096,
      top_p = 0.95,       -- Add top_p for better response quality
      top_k = 40,         -- Add top_k for better response filtering
      timeout = 60000,    -- Increase timeout for complex queries
      auto_suggestions_provider = "claude",
      -- OpenAI configuration
      openai = {
        api_key = os.getenv("OPENAI_API_KEY"),
        model = "gpt-4o",
        temperature = 0.1,
        max_tokens = 4096,
        top_p = 0.95,
        timeout = 60000,
      },
      -- Gemini configuration
      gemini = {
        api_key = os.getenv("GEMINI_API_KEY"),
        model = "gemini-1.5-pro",
        temperature = 0.1,
        max_tokens = 4096,
        top_p = 0.95,
        timeout = 60000,
      },
      system_prompt =
      "You are an expert mathematician, logician and computer scientist with deep knowledge of Neovim, Lua, and programming languages. Provide concise, accurate responses with code examples when appropriate. For mathematical content, use clear notation and step-by-step explanations. IMPORTANT: Never create files, make git commits, or perform system changes without explicit permission. Always ask before suggesting any file modifications or system operations.",
      -- Disable all tools that could modify the system
      disable_tools = {
        "file_creation",
        "git_operations",
        "system_commands",
        "file_modifications",
      },
      -- custom_tools = {
      --   require("mcphub.extensions.avante").mcp_tool(),
      -- },
      dual_boost = {
        enabled = false,
        first_provider = "claude",
        second_provider = "openai",
        prompt =
        "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
        timeout = 60000,
      },
      fallback = {
        enabled = false,                      -- Enable fallback model if primary fails
        model = "claude-3-5-sonnet-20241022", -- More stable fallback model
        auto_retry = false,
      },
      behaviour = {
        enable_claude_text_editor_tool_mode = true,
        auto_suggestions = false,
        auto_set_highlight_group = false,
        auto_set_keymaps = false,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff = true,
        preserve_state = true,                   -- Add safe mode to handle potential iteration errors
        require_confirmation_for_actions = true, -- Require confirmation for any actions
        disable_file_creation = true,            -- Prevent automatic file creation
        disable_git_operations = true,           -- Prevent automatic git operations
        respect_enter_key = true,                -- Add this to make <CR> behave normally in insert mode
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
          insert = "<C-l>", -- Keep this as <C-l> to avoid conflicts with normal <CR> behavior
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

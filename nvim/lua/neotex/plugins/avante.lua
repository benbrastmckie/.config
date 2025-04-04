return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = "false", -- Using latest version to get the most recent fixes
  -- Explicitly checking for Neovim 0.10.1+ compatibility
  cond = function()
    if vim.fn.has("nvim-0.10.1") == 0 then
      vim.notify("Avante requires Neovim 0.10.1 or later", vim.log.levels.WARN)
      return false
    end
    return true
  end,
  init = function()
    -- Set recommended vim option for best Avante view compatibility
    -- Views can only be fully collapsed with the global statusline
    vim.opt.laststatus = 3

    -- Define provider models (moved to global scope for reuse)
    -- IMPORTANT: Keep claude-3-5-sonnet as the first model
    _G.provider_models = {
      claude = {
        "claude-3-5-sonnet-20241022", -- IMPORTANT: Keep this as index 1
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

    -- Require the support module just once in this scope
    -- This module will be visible to all code in the init function
    local avante_support = require("neotex.plugins.ai.avante-support")

    -- Initialize state with the settings from our support module
    -- This sets up _G.avante_cycle_state and returns the settings
    local settings = avante_support.init()

    -- Add additional autocmd to enforce model after fully loaded
    -- No notification here - will show when window is first opened
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        vim.defer_fn(function()
          local ok, avante = pcall(require, "avante")
          if ok then
            -- Load settings from our support module
            -- Using the avante_support variable from the outer scope
            local lazy_settings = avante_support.init()

            -- Create model config from settings
            local model_config = lazy_settings

            -- First try: config.override
            local success = pcall(function()
              if avante.config and avante.config.override then
                avante.config.override(model_config)
                return true
              end
            end)

            -- Second try: direct override
            if not success then
              success = pcall(function()
                if type(avante.override) == "function" then
                  avante.override(model_config)
                  return true
                end
              end)
            end

            -- Third try: require config module
            if not success then
              pcall(function()
                local config_module = require("avante.config")
                if config_module and config_module.override then
                  config_module.override(model_config)
                end
              end)
            end

            -- Set a flag to show notification on first window open
            _G.avante_first_open = true
          end
        end, 1000) -- Longer delay to ensure everything is loaded
      end
    })

    -- Add VimEnter event to enforce model configuration without disrupting UI settings
    -- No notification here to keep the interface clean
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.defer_fn(function()
          local ok, avante = pcall(require, "avante")
          if ok then
            -- Load settings from our support module
            -- Using the avante_support variable from the outer scope
            local vim_settings = avante_support.init()

            -- Create model config from settings
            local model_config = vim_settings

            -- Try different paths to update configuration
            local success = false

            -- First try: config.override
            success = pcall(function()
              if avante.config and avante.config.override then
                avante.config.override(model_config)
                return true
              end
            end)

            -- Second try: direct override
            if not success then
              success = pcall(function()
                if type(avante.override) == "function" then
                  avante.override(model_config)
                  return true
                end
              end)
            end

            -- Third try: require config module
            if not success then
              pcall(function()
                local config_module = require("avante.config")
                if config_module and config_module.override then
                  config_module.override(model_config)
                end
              end)
            end
          end
        end, 300) -- Delay after Vim is fully started
      end
    })

    -- Set up Avante commands using the support module
    avante_support.setup_commands()

    -- Create autocmd for Avante buffer-specific mappings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "AvanteInput", "Avante" },
      callback = function()
        -- Show model notification on first window open in a session
        -- Use local variable to prevent race condition with multiple notifications
        local filetype = vim.bo.filetype
        if _G.avante_first_open and filetype == "Avante" then
          -- Immediately clear the flag to prevent multiple notifications
          _G.avante_first_open = false

          vim.defer_fn(function()
            -- Use support module to show the notification
            -- Using the avante_support variable from the outer scope
            avante_support.show_model_notification()
          end, 100)
        end

        -- Set up buffer keymaps using the support module
        avante_support.setup_buffer_keymaps(0)

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
      -- Removed force_model which isn't supported
      temperature = 0.1, -- Slight increase for more creative responses
      max_tokens = 4096,
      top_p = 0.95,      -- Add top_p for better response quality
      top_k = 40,        -- Add top_k for better response filtering
      timeout = 60000,   -- Increase timeout for complex queries
      auto_suggestions_provider = "claude",
      -- Explicitly set model in provider config for priority
      claude = {
        model = "claude-3-5-sonnet-20241022",
        temperature = 0.1,
        max_tokens = 4096,
        top_p = 0.95,
        timeout = 60000,
      },
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
      "You are an expert mathematician, logician and computer scientist with deep knowledge of Neovim, Lua, and programming languages. Provide concise, accurate responses with code examples when appropriate. For mathematical content, use clear notation and step-by-step explanations. IMPORTANT: Never create files, make git commits, or perform system changes without explicit permission. Always ask before suggesting any file modifications or system operations. Only use the SEARCH/REPLACE blocks to suggest changes.",
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
        enable_cursor_planning_mode = false,    -- Experimental feature for more focused cursor-based planning
        auto_suggestions = false,
        auto_suggestions_respect_ignore = true, -- Honor .gitignore when searching for context
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
        use_cwd_as_project_root = false,         -- Use current working directory as project root
      },

      -- Token counting configuration (helps track token usage)
      token_counting = {
        enabled = true,              -- Enable token counting for cost awareness
        show_in_status_line = false, -- Don't show in status line to keep it clean
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

    -- Override with saved settings if they exist
    -- Note: Using new variable names to avoid confusion with the init function scope
    local opts_support = require("neotex.plugins.ai.avante-support")
    local opts_settings = opts_support.init()

    -- Apply settings to config
    if opts_settings then
      for k, v in pairs(opts_settings) do
        if type(v) == "table" then
          if config[k] then
            for sk, sv in pairs(v) do
              config[k][sk] = sv
            end
          else
            config[k] = v
          end
        else
          config[k] = v
        end
      end
    end

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

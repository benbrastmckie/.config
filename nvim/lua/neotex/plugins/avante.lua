return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = "false", -- Using latest version to get the most recent fixes, otherwise set to "false"
  init = function()
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

    -- Initialize state to default values (from the opts function below)
    _G.avante_cycle_state = {
      provider = "claude",
      model_index = 1 -- This corresponds to claude-3-5-sonnet
    }

    -- Add additional autocmd to enforce model after fully loaded
    -- No notification here - will show when window is first opened
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      callback = function()
        vim.defer_fn(function()
          local ok, avante = pcall(require, "avante")
          if ok then
            -- Use the default configuration
            local model_config = {
              provider = "claude",
              model = "claude-3-7-sonnet-20250219",
              claude = {
                model = "claude-3-5-sonnet-20241022"
              }
            }

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
            -- Use the default configuration
            local model_config = {
              provider = "claude",
              model = "claude-3-5-sonnet-20241022",
              claude = {
                model = "claude-3-5-sonnet-20241022"
              }
            }

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

    -- Add AvanteSelectModel command since it doesn't seem to exist in our version
    if not pcall(vim.api.nvim_get_commands, {}, { pattern = "AvanteSelectModel" }) then
      vim.api.nvim_create_user_command("AvanteSelectModel", function(opts)
        local ok, avante_api = pcall(require, "avante.api")
        if ok and avante_api and avante_api.select_model then
          avante_api.select_model()
        end
      end, { nargs = "?" })
    end

    -- Create a command for selecting and setting the default model
    vim.api.nvim_create_user_command("AvanteSetDefaultModel", function()
      -- Define the selection function locally to avoid dependency issues
      local function select_default_model()
        -- First, select a provider
        local providers = { "claude", "openai", "gemini" }

        vim.ui.select(providers, {
          prompt = "Select default AI provider:",
          format_item = function(item)
            -- Capitalize first letter for nicer display
            return item:sub(1, 1):upper() .. item:sub(2)
          end
        }, function(selected_provider)
          -- Handle cancellation
          if not selected_provider then
            vim.notify("Default model selection canceled", vim.log.levels.INFO)
            return
          end

          -- Now select a model for the chosen provider
          local models = _G.provider_models[selected_provider] or {}
          if #models == 0 then
            vim.notify("No models available for provider: " .. selected_provider, vim.log.levels.ERROR)
            return
          end

          vim.ui.select(models, {
            prompt = "Select default model for " .. selected_provider .. ":",
            format_item = function(item) return item end
          }, function(selected_model)
            -- Handle cancellation
            if not selected_model then
              vim.notify("Default model selection canceled", vim.log.levels.INFO)
              return
            end

            -- Set runtime state first
            _G.avante_cycle_state = {
              provider = selected_provider,
              model_index = 1 -- Will be updated properly after finding index
            }

            -- Find the model index
            for i, model in ipairs(models) do
              if model == selected_model then
                _G.avante_cycle_state.model_index = i
                break
              end
            end

            -- Directly modify the configuration file
            local avante_file_path = vim.fn.stdpath("config") .. "/lua/neotex/plugins/avante.lua"

            -- Read the current file content
            local file = io.open(avante_file_path, "r")
            if not file then
              vim.notify("Could not open avante.lua for editing", vim.log.levels.ERROR)
              return
            end

            local content = file:read("*all")
            file:close()

            -- Define patterns to look for in the file - more robust with whitespace variations
            local provider_pattern = "(provider%s*=%s*[\"'])([^\"']+)([\"'])"
            local model_pattern = "(model%s*=%s*[\"'])([^\"']+)([\"'])"

            -- For provider_model_pattern, we need to find the section for the specific provider
            -- This pattern looks for the provider table definition and updates the model inside it
            local provider_section_pattern = "(" .. selected_provider .. "%s*=%s*{.-model%s*=%s*[\"'])([^\"']+)([\"'])"

            -- Flag to track if we made changes
            local changes_made = false

            -- Replace the main provider in the top-level config
            content, changes_count = content:gsub(provider_pattern, "%1" .. selected_provider .. "%3", 1)
            changes_made = changes_made or changes_count > 0

            -- Replace the main model in the top-level config
            content, changes_count = content:gsub(model_pattern, "%1" .. selected_model .. "%3", 1)
            changes_made = changes_made or changes_count > 0

            -- Replace the provider-specific model
            -- This is a more complex pattern that needs to find the right section
            content, changes_count = content:gsub(provider_section_pattern, "%1" .. selected_model .. "%3", 1)
            changes_made = changes_made or changes_count > 0

            -- Only write the file if changes were made
            if changes_made then
              file = io.open(avante_file_path, "w")
              if not file then
                vim.notify("Could not write to avante.lua", vim.log.levels.ERROR)
                return
              end

              file:write(content)
              file:close()

              -- Try to refresh provider and model after config change
              local ok, avante = pcall(require, "avante")
              if ok then
                -- Prepare model configuration for override
                local model_config = {
                  provider = selected_provider,
                  model = selected_model,
                  [selected_provider] = {
                    model = selected_model
                  }
                }

                -- Try to apply config override
                pcall(function()
                  if avante.config and avante.config.override then
                    avante.config.override(model_config)
                  end
                end)

                -- Try the command-based approach as well
                pcall(function()
                  vim.cmd("AvanteSwitchProvider " .. selected_provider)
                end)
              end

              vim.notify(
                "Default model set to " .. selected_provider .. "/" .. selected_model ..
                "\nThis will be used for all future Neovim sessions.",
                vim.log.levels.INFO
              )
            else
              vim.notify("No changes needed in avante.lua configuration", vim.log.levels.INFO)
            end
          end)
        end)
      end

      -- Call the function
      select_default_model()
    end, {
      desc = "Select and set the default Avante provider and model"
    })

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
            -- Get the current model from global state
            local current_provider = _G.avante_cycle_state.provider or "claude"
            local current_index = _G.avante_cycle_state.model_index or 1
            local models = _G.provider_models[current_provider] or {}
            local current_model = "unknown"

            if #models >= current_index then
              current_model = models[current_index]
            end

            -- Show a single notification with the active model
            vim.notify("Avante ready with model: " .. current_model, vim.log.levels.INFO)
          end, 100)
        end

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

        -- Stop generation and set default model
        vim.api.nvim_buf_set_keymap(0, "n", "<C-s>", "<cmd>AvanteStop<CR>",
          { noremap = true, silent = true, desc = "Stop Avante generation" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-s>", "<cmd>AvanteStop<CR>",
          { noremap = true, silent = true, desc = "Stop Avante generation" })
        vim.api.nvim_buf_set_keymap(0, "n", "<C-d>", "<cmd>AvanteSetDefaultModel<CR>",
          { noremap = true, silent = true, desc = "Set default Avante model" })
        vim.api.nvim_buf_set_keymap(0, "i", "<C-d>", "<cmd>AvanteSetDefaultModel<CR>",
          { noremap = true, silent = true, desc = "Set default Avante model" })

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

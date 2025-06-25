------------------------------------------
-- Avante AI Assistant Support Module --
------------------------------------------
-- This module contains all Avante-related functions and utilities
-- Makes the main configuration cleaner by separating Avante-specific code
--
-- Features:
-- 1. Model Selection: Switch between different Claude/OpenAI/Gemini models
--    - Commands: AvanteModel, AvanteProvider
--    - Keybindings: <leader>hm, <leader>hd
--
-- 2. System Prompt Management: Create/edit/select system prompts
--    - Commands: AvantePrompt, AvantePromptManager, AvantePromptEdit
--    - Keybindings: <leader>hp, <leader>hP
--    - Storage: ~/.config/nvim/lua/neotex/plugins/ai/system-prompts.json
--
-- 3. Generation Control: Stop ongoing generation
--    - Commands: AvanteStop
--    - Keybindings: <leader>hs, <C-s> (in Avante buffers)
--
-- 4. Provider Models: Centralized definition of available AI models
--    - Maintains consistent model lists across the configuration
--    - Accessible via global _G.provider_models for backward compatibility
--
-- All configurations persist between Neovim sessions

local M = {}
local notify = require('neotex.util.notifications')

-- Define AI provider models
-- Centralized definition that can be accessed by other modules
M.provider_models = {
  claude = {
    "claude-3-5-sonnet-20241022", -- IMPORTANT: Keep this as index 1
    "claude-3-7-sonnet-20250219",
    "claude-4-sonnet-20250514",
    "claude-3-opus-20240229",
  },
  openai = {
    "gpt-4o",
    "gpt-4-turbo",
    "gpt-4",
    "gpt-3.5-turbo",
  },
  gemini = {
    -- Gemini 2.5 models
    "gemini-2.5-pro-preview-03-25",
    -- "gemini-2.5-pro-exp-03-25",
    -- Gemini 2.0 models
    "gemini-2.0-flash",
    -- "gemini-2.0-flash-lite",
    -- "gemini-2.0-flash-001",
    -- "gemini-2.0-flash-exp",
    -- "gemini-2.0-flash-lite-001",
    -- Gemini 1.5 models
    -- "gemini-1.5-pro",
    -- "gemini-1.5-flash",
  }
}

-- Get provider models and update global state
-- This maintains backward compatibility with code using _G.provider_models
function M.get_provider_models()
  -- Update global state for backward compatibility
  _G.provider_models = M.provider_models
  return M.provider_models
end

-- Initialize global state if not already defined
if not _G.avante_cycle_state then
  _G.avante_cycle_state = {
    provider = "claude",
    model_index = 3  -- Claude 4.0 is at index 3 in the provider_models.claude array
  }
end

-- Persistent settings storage
local avante_data_dir = vim.fn.stdpath("data") .. "/avante"
local avante_settings_file = avante_data_dir .. "/settings.lua"

-- Make sure the directory exists
if vim.fn.isdirectory(avante_data_dir) == 0 then
  vim.fn.mkdir(avante_data_dir, "p")
end

-- Load settings from file
function M.load_settings()
  -- Check if file exists
  if vim.fn.filereadable(avante_settings_file) ~= 1 then
    -- Return default settings based on the actual defaults
    return {
      provider = "claude",
      model = "claude-4-sonnet-20250514",
      providers = {
        claude = {
          model = "claude-4-sonnet-20250514"
        }
      }
    }
  end

  -- Try to load the settings
  local ok, settings = pcall(dofile, avante_settings_file)
  if ok and settings then
    return settings
  end

  -- Return default settings if anything went wrong
  return {
    provider = "claude",
    model = "claude-4-sonnet-20250514",
    providers = {
      claude = {
        model = "claude-4-sonnet-20250514"
      }
    }
  }
end

-- Save settings to file
function M.save_settings(provider, model)
  -- Create settings content using new provider structure
  local content = string.format([[
-- Avante default settings
-- Generated on: %s
return {
  provider = "%s",
  providers = {
    ["%s"] = {
      model = "%s"
    }
  }
}
]], os.date("%Y-%m-%d %H:%M:%S"), provider, provider, model)

  -- Write to file
  local file = io.open(avante_settings_file, "w")
  if not file then
    notify.ai('Could not save Avante settings', notify.categories.ERROR)
    return false
  end

  file:write(content)
  file:close()
  return true
end

-- Apply settings to Avante
function M.apply_settings(provider, model, model_index, notify)
  -- Update global state
  _G.avante_cycle_state = {
    provider = provider,
    model_index = model_index or 1
  }

  -- Create model config
  local model_config = {
    provider = provider,
    model = model,
    [provider] = {
      model = model
    }
  }

  -- Apply configuration in multiple ways for reliability

  -- 1. Try config module override
  local success = false
  pcall(function()
    local config_module = require("avante.config")
    if config_module and config_module.override then
      config_module.override(model_config)
      success = true
    end
  end)

  -- 2. Try direct override if #1 failed
  if not success then
    pcall(function()
      local avante = require("avante")
      if avante.config and avante.config.override then
        avante.config.override(model_config)
        success = true
      elseif type(avante.override) == "function" then
        avante.override(model_config)
        success = true
      end
    end)
  end

  -- 3. Try provider switching command
  pcall(function()
    vim.cmd("AvanteSwitchProvider " .. provider)
  end)

  -- 4. Try to refresh provider
  pcall(function()
    local avante = require("avante")
    if avante.providers and avante.providers.refresh then
      avante.providers.refresh(provider)
    end
  end)

  -- 5. Show notification if requested
  if notify then
    notify.ai('Model switched', notify.categories.USER_ACTION, { provider = provider, model = model })
  end

  return success
end

-- Initialize Avante settings at startup
function M.init()
  -- Provider models are now defined in this module
  -- No need to skip if not defined
  
  local settings = M.load_settings()

  -- Find model index
  local provider = settings.provider
  local model = settings.model
  local model_index = 1

  -- If model is not specified in settings, try to get it from providers
  if not model and settings.providers and settings.providers[provider] then
    model = settings.providers[provider].model
  end

  -- Find the model index in our provider models list
  if M.provider_models[provider] and model then
    for i, m in ipairs(M.provider_models[provider]) do
      if m == model then
        model_index = i
        break
      end
    end
  end

  -- Apply settings without notification
  _G.avante_cycle_state = {
    provider = provider,
    model_index = model_index
  }

  -- Return settings for further use
  return settings
end

-- AvanteModel: Function to select a model for the current provider
function M.model_select()
  -- Check if avante is loaded
  local ok, avante = pcall(require, "avante")
  if not ok then
    notify.ai('Avante plugin is not loaded yet', notify.categories.ERROR)
    return
  end

  -- Get current provider
  local current_provider = _G.avante_cycle_state.provider or "claude"

  -- Get models for current provider
  local models = M.provider_models[current_provider] or {}
  if #models == 0 then
    notify.ai('No models available for provider', notify.categories.WARNING, { provider = current_provider })
    return
  end

  -- Create UI for model selection
  vim.ui.select(models, {
    prompt = "Select model for " .. current_provider .. " provider:",
    format_item = function(item) return item end
  }, function(selected_model)
    if not selected_model then
      return -- User canceled
    end

    -- Find index of selected model
    local selected_index = 1
    for i, model in ipairs(models) do
      if model == selected_model then
        selected_index = i
        break
      end
    end

    -- Apply settings (temporary change)
    M.apply_settings(current_provider, selected_model, selected_index, true)
  end)
end

-- AvanteProvider: Function to select provider and model with option to set as default
function M.provider_select()
  -- Check if avante is loaded
  local ok, avante = pcall(require, "avante")
  if not ok then
    notify.ai('Avante plugin is not loaded yet', notify.categories.ERROR)
    return
  end

  -- List of available providers (get from provider_models keys)
  local providers = {}
  for provider, _ in pairs(M.provider_models) do
    table.insert(providers, provider)
  end
  
  -- Sort providers alphabetically for consistent UI
  table.sort(providers)

  -- Create UI for provider selection
  vim.ui.select(providers, {
    prompt = "Select AI provider:",
    format_item = function(item)
      -- Capitalize first letter for nicer display
      return item:sub(1, 1):upper() .. item:sub(2)
    end
  }, function(selected_provider)
    if not selected_provider then
      return -- User canceled
    end

    -- Get models for selected provider
    local models = M.provider_models[selected_provider] or {}
    if #models == 0 then
      vim.notify("No models available for provider: " .. selected_provider, vim.log.levels.WARN)
      return
    end

    -- Create UI for model selection
    vim.ui.select(models, {
      prompt = "Select model for " .. selected_provider .. ":",
      format_item = function(item) return item end
    }, function(selected_model)
      if not selected_model then
        return -- User canceled
      end

      -- Find index of selected model
      local selected_index = 1
      for i, model in ipairs(models) do
        if model == selected_model then
          selected_index = i
          break
        end
      end

      -- Create UI to ask if this should be the default
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Set as default for future sessions?",
      }, function(make_default)
        if not make_default then
          return -- User canceled
        end

        -- Apply settings immediately
        M.apply_settings(selected_provider, selected_model, selected_index, false)

        -- Save as default if requested
        if make_default == "Yes" then
          if M.save_settings(selected_provider, selected_model) then
            vim.notify(
              "Default model set to " .. selected_provider .. "/" .. selected_model ..
              "\nSwitched to this model and saved for future sessions.",
              vim.log.levels.INFO
            )
          end
        else
          vim.notify(
            "Switched to " .. selected_provider .. "/" .. selected_model,
            vim.log.levels.INFO
          )
        end
      end)
    end)
  end)
end

-- Function to stop Avante generation
function M.stop_generation()
  -- Try direct access to the llm module first
  local ok, llm = pcall(require, "avante.llm")
  if ok and llm and type(llm.cancel_inflight_request) == "function" then
    llm.cancel_inflight_request()
    vim.notify("Stopped Avante generation", vim.log.levels.INFO)
    return
  end

  -- Fall back to the API module as a second attempt
  local ok_api, api = pcall(require, "avante.api")
  if ok_api and api and type(api.stop) == "function" then
    api.stop()
    vim.notify("Stopped Avante generation", vim.log.levels.INFO)
    return
  end

  -- If both approaches fail, notify the user
  vim.notify("Failed to stop Avante generation - model may still be running", vim.log.levels.WARN)
end

-- Set up all Avante-related commands
function M.setup_commands()
  -- Model selection command
  vim.api.nvim_create_user_command("AvanteModel", function()
    M.model_select()
  end, { desc = "Select a model for the current AI provider" })

  -- Provider selection command
  vim.api.nvim_create_user_command("AvanteProvider", function()
    M.provider_select()
  end, { desc = "Select an AI provider and model, with option to set as default" })

  -- Stop generation command
  vim.api.nvim_create_user_command("AvanteStop", function()
    M.stop_generation()
  end, { desc = "Stop Avante generation in progress" })

  -- System prompt selection command
  vim.api.nvim_create_user_command("AvantePrompt", function()
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.util.system-prompts")
    if ok then
      system_prompts.show_prompt_selection()
    else
      vim.notify("Failed to load system prompts module", vim.log.levels.ERROR)
    end
  end, { desc = "Select a system prompt" })

  -- System prompt management command
  vim.api.nvim_create_user_command("AvantePromptManager", function()
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.util.system-prompts")
    if ok then
      system_prompts.show_prompt_manager()
    else
      vim.notify("Failed to load system prompts module", vim.log.levels.ERROR)
    end
  end, { desc = "Manage system prompts" })

  -- System prompt editor command
  vim.api.nvim_create_user_command("AvantePromptEdit", function(opts)
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.util.system-prompts")
    if ok then
      -- If args provided, try to edit that specific prompt
      if opts.args and opts.args ~= "" then
        system_prompts.show_prompt_editor(opts.args)
      else
        -- Otherwise just open the manager
        system_prompts.show_prompt_manager()
      end
    else
      vim.notify("Failed to load system prompts module", vim.log.levels.ERROR)
    end
  end, { nargs = "?", desc = "Edit system prompts" })

  -- Add AvanteSelectModel command if it doesn't exist
  if not pcall(vim.api.nvim_get_commands, {}, { pattern = "AvanteSelectModel" }) then
    vim.api.nvim_create_user_command("AvanteSelectModel", function(opts)
      local ok, avante_api = pcall(require, "avante.api")
      if ok and avante_api and avante_api.select_model then
        avante_api.select_model()
      end
    end, { nargs = "?" })
  end
end

-- Function to set up keymaps in Avante buffers
-- Now calls the centralized function in keymaps.lua for better organization
-- Kept for backward compatibility
function M.setup_buffer_keymaps(bufnr)
  -- Simply call the global function that's defined in keymaps.lua
  -- This ensures all keymappings are defined in one central location
  _G.set_avante_keymaps()
end

-- Function for first open notification
function M.show_model_notification()
  -- Get the current model from global state
  local current_provider = _G.avante_cycle_state.provider or "claude"
  local current_index = _G.avante_cycle_state.model_index or 1
  local models = M.provider_models[current_provider] or {}
  local current_model = "unknown"

  if #models >= current_index then
    current_model = models[current_index]
  end

  -- Load the default system prompt
  local ok, system_prompts = pcall(require, "neotex.plugins.ai.util.system-prompts")
  local prompt_info = ""
  local prompt_name = ""

  if ok then
    local default_prompt, default_id = system_prompts.get_default()
    if default_prompt then
      prompt_info = " with prompt: " .. default_prompt.name
      prompt_name = default_prompt.name

      -- Store current prompt in global state
      _G.current_avante_prompt = {
        id = default_id,
        name = default_prompt.name
      }

      -- Apply the default prompt
      pcall(function()
        local config = require("avante.config")
        if config and config.override then
          config.override({ 
            system_prompt = default_prompt.prompt,
            prompt_name = default_prompt.name
          })
        end
      end)

      -- Add an autocmd to show the prompt name in responses
      pcall(function()
        -- Create autocmd group if it doesn't exist
        if vim.fn.exists("##AvantePromptAttribution") == 0 then
          vim.api.nvim_create_augroup("AvantePromptAttribution", { clear = true })
        end

        -- Add autocmd for entering Avante buffers
        vim.api.nvim_create_autocmd("FileType", {
          group = "AvantePromptAttribution",
          pattern = "Avante",
          callback = function()
            -- Add autocommand for when text is added to buffer
            vim.api.nvim_create_autocmd("TextChanged", {
              group = "AvantePromptAttribution",
              buffer = vim.api.nvim_get_current_buf(),
              callback = function()
                -- Check if this is a new response (only execute once per response)
                if _G.avante_last_response_time and (os.time() - _G.avante_last_response_time) < 5 then
                  return
                end

                -- Get the current prompt information
                local current_prompt = _G.current_avante_prompt and _G.current_avante_prompt.name or "Unknown"
                local win_info = "Using " .. current_model .. " with " .. current_prompt .. " prompt"
                
                -- Update window title
                pcall(function()
                  local buf = vim.api.nvim_get_current_buf()
                  local win = vim.api.nvim_get_current_win()
                  if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_set_option(win, "winbar", win_info)
                  end
                end)
                
                -- Update timestamp to avoid multiple executions
                _G.avante_last_response_time = os.time()
              end
            })
          end
        })
      end)
    end
  end

  -- Show a single notification with the active model and prompt
  vim.notify("Avante ready with model: " .. current_model .. prompt_info, vim.log.levels.INFO)
end

return M
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
-- All configurations persist between Neovim sessions

local M = {}

-- Initialize global state if not already defined
if not _G.avante_cycle_state then
  _G.avante_cycle_state = {
    provider = "gemini",
    model_index = 1
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
    -- Return default settings
    return {
      provider = "gemini",
      model = "gemini-1.5-pro",
      gemini = {
        model = "gemini-1.5-pro"
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
    provider = "gemini",
    model = "gemini-1.5-pro",
    gemini = {
      model = "gemini-1.5-pro"
    }
  }
end

-- Save settings to file
function M.save_settings(provider, model)
  -- Create settings content
  local content = string.format([[
-- Avante default settings
-- Generated on: %s
return {
  provider = "%s",
  model = "%s",
  ["%s"] = {
    model = "%s"
  }
}
]], os.date("%Y-%m-%d %H:%M:%S"), provider, model, provider, model)

  -- Write to file
  local file = io.open(avante_settings_file, "w")
  if not file then
    vim.notify("Could not save Avante settings", vim.log.levels.ERROR)
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
    vim.notify("Switched to " .. provider .. "/" .. model, vim.log.levels.INFO)
  end

  return success
end

-- Initialize Avante settings at startup
function M.init()
  -- Skip if provider_models isn't defined yet
  if not _G.provider_models then
    return M.load_settings()
  end

  local settings = M.load_settings()

  -- Find model index
  local provider = settings.provider
  local model = settings.model
  local model_index = 1

  if _G.provider_models and _G.provider_models[provider] then
    for i, m in ipairs(_G.provider_models[provider]) do
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
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  -- Get current provider
  local current_provider = _G.avante_cycle_state.provider or "claude"

  -- Get models for current provider
  local models = _G.provider_models[current_provider] or {}
  if #models == 0 then
    vim.notify("No models available for provider: " .. current_provider, vim.log.levels.WARN)
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
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  -- List of available providers
  local providers = { "claude", "openai", "gemini" }

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
    local models = _G.provider_models[selected_provider] or {}
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
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.system-prompts")
    if ok then
      system_prompts.show_prompt_selection()
    else
      vim.notify("Failed to load system prompts module", vim.log.levels.ERROR)
    end
  end, { desc = "Select a system prompt" })

  -- System prompt management command
  vim.api.nvim_create_user_command("AvantePromptManager", function()
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.system-prompts")
    if ok then
      system_prompts.show_prompt_manager()
    else
      vim.notify("Failed to load system prompts module", vim.log.levels.ERROR)
    end
  end, { desc = "Manage system prompts" })

  -- System prompt editor command
  vim.api.nvim_create_user_command("AvantePromptEdit", function(opts)
    local ok, system_prompts = pcall(require, "neotex.plugins.ai.system-prompts")
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
  local models = _G.provider_models[current_provider] or {}
  local current_model = "unknown"

  if #models >= current_index then
    current_model = models[current_index]
  end

  -- Load the default system prompt
  local ok, system_prompts = pcall(require, "neotex.plugins.ai.system-prompts")
  local prompt_info = ""

  if ok then
    local default_prompt, default_id = system_prompts.get_default()
    if default_prompt then
      prompt_info = " with prompt: " .. default_prompt.name

      -- Apply the default prompt
      pcall(function()
        local config = require("avante.config")
        if config and config.override then
          config.override({ system_prompt = default_prompt.prompt })
        end
      end)
    end
  end

  -- Show a single notification with the active model and prompt
  vim.notify("Avante ready with model: " .. current_model .. prompt_info, vim.log.levels.INFO)
end

return M


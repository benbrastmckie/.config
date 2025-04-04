-- Avante Preferences Module
-- This file handles default model selection and persistence for Avante.nvim

local M = {}

-- Load saved preferences
function M.load_preferences()
  local data_dir = vim.fn.stdpath("data") .. "/avante"
  local prefs_file = data_dir .. "/preferences.lua"
  
  -- Check if preferences file exists
  if vim.fn.filereadable(prefs_file) == 1 then
    local ok, prefs = pcall(dofile, prefs_file)
    if ok and prefs then
      return prefs
    end
  end
  
  -- Return default preferences if file doesn't exist or can't be loaded
  return {
    provider = "claude",
    model = "claude-3-5-sonnet-20241022",
    claude = {
      model = "claude-3-5-sonnet-20241022"
    }
  }
end

-- Save preferences to file
function M.save_preferences(provider, model)
  local data_dir = vim.fn.stdpath("data") .. "/avante"
  local prefs_file = data_dir .. "/preferences.lua"
  
  -- Create directory if it doesn't exist
  if vim.fn.isdirectory(data_dir) == 0 then
    vim.fn.mkdir(data_dir, "p")
  end
  
  -- Construct the preferences file content
  local content = string.format([[
-- Auto-generated Avante preferences file
-- This file is loaded to set default provider and model settings
-- Last updated: %s

return {
  provider = "%s",
  model = "%s",
  %s = {
    model = "%s"
  }
}
]], os.date("%Y-%m-%d %H:%M:%S"), provider, model, provider, model)
  
  -- Write the file
  local file = io.open(prefs_file, "w")
  if not file then
    vim.notify("Failed to save Avante preferences", vim.log.levels.ERROR)
    return false
  end
  
  file:write(content)
  file:close()
  return true
end

-- Apply preferences to runtime configuration
function M.apply_preferences(preferences)
  -- Get provider and model from preferences
  local provider = preferences.provider or "claude"
  local model = preferences.model or "claude-3-5-sonnet-20241022"
  
  -- Update the global state
  if _G.provider_models and _G.provider_models[provider] then
    local model_index = 1
    for i, m in ipairs(_G.provider_models[provider]) do
      if m == model then
        model_index = i
        break
      end
    end
    
    _G.avante_cycle_state = {
      provider = provider,
      model_index = model_index
    }
  end
  
  -- Apply configuration immediately through multiple approaches
  pcall(function()
    -- 1. Try config override first
    local avante = require("avante")
    if avante.config and avante.config.override then
      avante.config.override(preferences)
    end
    
    -- 2. Try direct provider and model selection
    pcall(function()
      -- Try to switch provider first
      if vim.fn.exists(":AvanteSwitchProvider") > 0 then
        vim.cmd("AvanteSwitchProvider " .. provider)
      end
      
      -- Then try to apply model if API is available
      local avante_api = require("avante.api")
      if avante_api then
        if type(avante_api.select_model_by_name) == "function" then
          avante_api.select_model_by_name(model)
        elseif type(avante_api.select_model) == "function" then
          -- If there's no direct by_name function, we can try the general selector
          avante_api.select_model()
        end
      end
    end)
  end)
end

-- Select and set default model with UI
function M.select_default_model()
  -- First, select a provider
  local providers = { "claude", "openai", "gemini" }
  
  vim.ui.select(providers, {
    prompt = "Select default AI provider:",
    format_item = function(item) 
      -- Capitalize first letter for nicer display
      return item:sub(1,1):upper() .. item:sub(2)
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
      
      -- Build preferences object
      local preferences = {
        provider = selected_provider,
        model = selected_model,
        [selected_provider] = {
          model = selected_model
        }
      }
      
      -- Save preferences to file
      if M.save_preferences(selected_provider, selected_model) then
        -- Apply preferences to current session
        M.apply_preferences(preferences)
        
        -- Apply model selection immediately - multiple approaches for reliability
        -- 1. First try direct provider switching
        pcall(function()
          vim.cmd("AvanteSwitchProvider " .. selected_provider)
        end)
        
        -- 2. Try to force model selection via API if available (might require a delay)
        vim.defer_fn(function()
          pcall(function()
            local avante_api = require("avante.api")
            if avante_api and avante_api.select_model_by_name then
              avante_api.select_model_by_name(selected_model)
            end
          end)
        end, 300)
        
        -- 3. Try to restart Avante to fully apply the changes
        vim.defer_fn(function()
          pcall(function()
            -- Toggle off and back on to fully refresh
            vim.cmd("AvanteToggle")
            vim.defer_fn(function()
              vim.cmd("AvanteToggle")
            end, 300)
          end)
        end, 600)
        
        vim.notify(
          "Default model set to " .. selected_provider .. "/" .. selected_model .. 
          "\nSwitching to this model immediately and saving for future sessions." ..
          "\nIf Avante interface needs refreshing, try toggling it with <C-t>.",
          vim.log.levels.INFO
        )
      end
    end)
  end)
end

-- Create command for model selection
function M.setup_command()
  vim.api.nvim_create_user_command("AvanteSetDefaultModel", function()
    M.select_default_model()
  end, {
    desc = "Select and set the default Avante provider and model"
  })
end

return M
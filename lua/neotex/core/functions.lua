-- Display vim messages in quickfix window
function DisplayMessages()
  -- Get all messages and split them into lines
  local messages = vim.fn.execute('messages')
  local lines = vim.split(messages, '\n')

  -- Create quickfix items from messages
  local qf_items = vim.tbl_map(function(line)
    return { text = line }
  end, lines)

  -- Set the quickfix list and open it
  vim.fn.setqflist(qf_items)
  vim.cmd('copen')
end

-- Fine all instances of a word in a project with telescope
function SearchWordUnderCursor()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({ default_text = word })
end

-- Reload neovim config
vim.api.nvim_create_user_command('ReloadConfig', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^plugins') then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  vim.notify('Nvim configuration reloaded!', vim.log.levels.INFO)
end, {})

-- Go to next/previous most recent buffer, excluding buffers where winfixbuf = true
function GotoBuffer(count, direction)
  -- Check if a buffer is in a fixed window
  local function is_buffer_fixed(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.wo[win].winfixbuf then
        return true
      end
    end
    return false
  end

  -- Check if current window is fixed
  local current_buf = vim.api.nvim_get_current_buf()
  if is_buffer_fixed(current_buf) then
    return
  end

  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  -- Filter and sort buffers into two groups
  local normal_buffers = {}
  local fixed_buffers = {}

  for _, buf in ipairs(buffers) do
    if is_buffer_fixed(buf.bufnr) then
      table.insert(normal_buffers, buf)
    else
      table.insert(fixed_buffers, buf)
    end
  end

  -- Sort both lists by modification time
  local sort_by_mtime = function(a, b)
    return vim.fn.getftime(a.name) > vim.fn.getftime(b.name)
  end
  table.sort(normal_buffers, sort_by_mtime)
  table.sort(fixed_buffers, sort_by_mtime)

  -- Choose which buffer list to use
  local target_buffers = #normal_buffers > 0 and normal_buffers or fixed_buffers
  if #target_buffers == 0 then
    return
  end

  -- Find current buffer index
  local current = vim.fn.bufnr('%')
  local current_index = 1
  for i, buf in ipairs(target_buffers) do
    if buf.bufnr == current then
      current_index = i
      break
    end
  end

  -- Calculate target buffer index
  local target_index = current_index + (direction * count)
  if target_index < 1 then
    target_index = #target_buffers
  elseif target_index > #target_buffers then
    target_index = 1
  end

  -- Switch to target buffer
  vim.cmd('buffer ' .. target_buffers[target_index].bufnr)
end

-- Function for selecting a model for the current provider
function _G.cycle_ai_model()
  -- Check if avante is loaded before proceeding
  local ok, avante = pcall(require, "avante")
  if not ok then
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  local current_provider = _G.avante_cycle_state.provider or "claude"
  
  -- Get list of models for current provider
  local models = _G.provider_models[current_provider] or {}
  if #models == 0 then
    vim.notify("No models available for provider: " .. current_provider, vim.log.levels.WARN)
    return
  end

  -- Create a simple UI to select from available models for current provider only
  vim.ui.select(models, {
    prompt = "Select model for " .. current_provider .. " provider:",
    format_item = function(item) return item end
  }, function(selected_model)
    if not selected_model then 
      -- User canceled, keep current state
      return
    end
    
    -- Find the index of the selected model
    local selected_index = 1
    for i, model in ipairs(models) do
      if model == selected_model then
        selected_index = i
        break
      end
    end
    
    -- Update runtime configuration
    _G.update_avante_model(current_provider, selected_model, selected_index)
    
    -- Try to refresh provider after config change
    pcall(function()
      if avante.providers and avante.providers.refresh then
        avante.providers.refresh()
      end
    end)
    
    vim.notify("Set model to: " .. selected_model, vim.log.levels.INFO)
  end)
end

-- Function for selecting a provider
function _G.cycle_ai_provider()
  -- Check if avante is loaded before proceeding
  local ok, avante = pcall(require, "avante")
  if not ok then
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  -- List only available providers, not models
  local providers = { "claude", "openai", "gemini" }
  
  -- Create a simple UI to select from available providers only
  vim.ui.select(providers, {
    prompt = "Select AI provider:",
    format_item = function(item) return item end
  }, function(selected_provider)
    if not selected_provider then 
      -- User canceled, keep current state
      return
    end
    
    -- Get default model for selected provider
    local models = _G.provider_models[selected_provider] or {}
    if #models == 0 then
      vim.notify("No models available for provider: " .. selected_provider, vim.log.levels.WARN)
      return
    end
    local default_model = models[1]
    
    -- Update runtime configuration
    _G.update_avante_model(selected_provider, default_model, 1)
    
    -- Try the command-based approach as well to ensure UI updates
    pcall(function()
      vim.cmd("AvanteSwitchProvider " .. selected_provider)
    end)
    
    -- Try to refresh provider after config change
    pcall(function()
      if avante.providers and avante.providers.refresh then
        avante.providers.refresh(selected_provider)
      end
    end)
    
    vim.notify("Set provider to: " .. selected_provider .. " with model: " .. default_model, vim.log.levels.INFO)
  end)
end

-- Update model selection state with runtime override
function _G.update_avante_model(provider, model, model_index)
  -- Update global state
  _G.avante_cycle_state = {
    provider = provider,
    model_index = model_index or 1
  }
  
  -- Try to update config using configuration module
  pcall(function()
    local config_module = require("avante.config")
    if config_module and config_module.override then
      local model_config = {
        provider = provider,
        model = model,
        [provider] = {
          model = model
        }
      }
      config_module.override(model_config)
    end
  end)
end

-- Set the default Avante model by directly editing the avante.lua file
function _G.set_avante_default_model(provider, model)
  -- Define the path to the avante.lua file
  local avante_file_path = vim.fn.stdpath("config") .. "/lua/neotex/plugins/avante.lua"
  
  -- Read the current file content
  local file = io.open(avante_file_path, "r")
  if not file then
    vim.notify("Could not open avante.lua for editing", vim.log.levels.ERROR)
    return false
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Define patterns to look for in the file - more robust with whitespace variations
  local provider_pattern = "(provider%s*=%s*[\"'])([^\"']+)([\"'])"  
  local model_pattern = "(model%s*=%s*[\"'])([^\"']+)([\"'])"
  
  -- For provider_model_pattern, we need to find the section for the specific provider
  -- This pattern looks for the provider table definition and updates the model inside it
  local provider_section_pattern = "("..provider.."%s*=%s*{.-model%s*=%s*[\"'])([^\"']+)([\"'])"

  -- Flag to track if we made changes
  local changes_made = false
  
  -- Replace the main provider in the top-level config
  content, changes_count = content:gsub(provider_pattern, "%1" .. provider .. "%3", 1)
  changes_made = changes_made or changes_count > 0
  
  -- Replace the main model in the top-level config
  content, changes_count = content:gsub(model_pattern, "%1" .. model .. "%3", 1)
  changes_made = changes_made or changes_count > 0
  
  -- Replace the provider-specific model
  -- This is a more complex pattern that needs to find the right section
  content, changes_count = content:gsub(provider_section_pattern, "%1" .. model .. "%3", 1)
  changes_made = changes_made or changes_count > 0
  
  -- Only write the file if changes were made
  if changes_made then
    file = io.open(avante_file_path, "w")
    if not file then
      vim.notify("Could not write to avante.lua", vim.log.levels.ERROR)
      return false
    end
    
    file:write(content)
    file:close()
    
    -- Also update runtime configuration
    _G.update_avante_model(provider, model)
    return true
  else
    vim.notify("No changes needed in avante.lua configuration", vim.log.levels.INFO)
    return false
  end
end

-- Improved function to select and set the default Avante provider and model
function _G.select_and_set_default_model()
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
      
      -- Find the model index
      local selected_index = 1
      for i, model in ipairs(models) do
        if model == selected_model then
          selected_index = i
          break
        end
      end
      
      -- 1. Update the runtime configuration
      _G.update_avante_model(selected_provider, selected_model, selected_index)
      
      -- 2. Save to configuration file
      if _G.set_avante_default_model(selected_provider, selected_model) then
        vim.notify(
          "Default model set to " .. selected_provider .. "/" .. selected_model .. 
          "\nThis will be used for all future Neovim sessions.", 
          vim.log.levels.INFO
        )
      end
      
      -- 3. Try using Avante API commands for immediate effect
      pcall(function()
        vim.cmd("AvanteSwitchProvider " .. selected_provider)
      end)
    end)
  end)
end

-- Register the AvanteStop command to interrupt generation
vim.api.nvim_create_user_command("AvanteStop", function()
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
end, { desc = "Stop Avante generation in progress" })
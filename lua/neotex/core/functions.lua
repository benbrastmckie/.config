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

------------------------------------------
-- Avante AI Assistant Model Management --
------------------------------------------

-- Persistent settings storage
local avante_data_dir = vim.fn.stdpath("data") .. "/avante"
local avante_settings_file = avante_data_dir .. "/settings.lua"

-- Make sure the directory exists
if vim.fn.isdirectory(avante_data_dir) == 0 then
  vim.fn.mkdir(avante_data_dir, "p")
end

-- Load settings from file
local function load_avante_settings()
  -- Check if file exists
  if vim.fn.filereadable(avante_settings_file) ~= 1 then
    -- Return default settings
    return {
      provider = "claude",
      model = "claude-3-5-sonnet-20241022",
      claude = {
        model = "claude-3-5-sonnet-20241022"
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
    model = "claude-3-5-sonnet-20241022",
    claude = {
      model = "claude-3-5-sonnet-20241022"
    }
  }
end

-- Save settings to file
local function save_avante_settings(provider, model)
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
local function apply_avante_settings(provider, model, model_index, notify)
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

-- AvanteModel: Function to select a model for the current provider
function _G.avante_model()
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
    apply_avante_settings(current_provider, selected_model, selected_index, true)
  end)
end

-- AvanteProvider: Function to select provider and model with option to set as default
function _G.avante_provider()
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
        apply_avante_settings(selected_provider, selected_model, selected_index, false)

        -- Save as default if requested
        if make_default == "Yes" then
          if save_avante_settings(selected_provider, selected_model) then
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

-- Apply settings at startup
function _G.avante_init()
  local settings = load_avante_settings()

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

  -- We'll let the plugin initialization handle the rest
  return settings
end

-- Register commands
vim.api.nvim_create_user_command("AvanteModel", function()
  _G.avante_model()
end, { desc = "Select a model for the current AI provider" })

vim.api.nvim_create_user_command("AvanteProvider", function()
  _G.avante_provider()
end, { desc = "Select an AI provider and model, with option to set as default" })

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


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

-- Function to cycle through models within the current provider
function _G.cycle_ai_model()
  -- Check if avante is loaded before proceeding
  local ok, avante = pcall(require, "avante")
  if not ok then
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  local current_provider = _G.avante_cycle_state.provider
  local current_index = _G.avante_cycle_state.model_index

  -- Find next model in the current provider's list
  local models = _G.provider_models[current_provider] or {}
  if #models == 0 then
    vim.notify("No models available for provider: " .. current_provider, vim.log.levels.WARN)
    return
  end

  -- Get next model (cycle within provider)
  local next_index = current_index % #models + 1
  local next_model = models[next_index]
  _G.avante_cycle_state.model_index = next_index

  -- Update the configuration with the new model
  avante.setup({
    [current_provider] = {
      model = next_model
    },
  })
  vim.notify("Switched to model: " .. next_model, vim.log.levels.INFO)
end

-- Function to cycle through providers
function _G.cycle_ai_provider()
  -- Check if avante is loaded before proceeding
  local ok, avante = pcall(require, "avante")
  if not ok then
    vim.notify("Avante plugin is not loaded yet", vim.log.levels.ERROR)
    return
  end

  local current_provider = _G.avante_cycle_state.provider
  local providers = { "claude", "openai", "gemini" }

  -- Find next provider
  local next_provider = current_provider
  for i, provider in ipairs(providers) do
    if provider == current_provider then
      next_provider = providers[i % #providers + 1]
      break
    end
  end

  -- Set first model of the new provider
  local next_model = _G.provider_models[next_provider][1]
  _G.avante_cycle_state.provider = next_provider
  _G.avante_cycle_state.model_index = 1

  -- Update the configuration with the new provider and model
  avante.setup({
    provider = next_provider,
    [next_provider] = {
      model = next_model
    }
  })
  vim.notify("Switched to provider: " .. next_provider .. " with model: " .. next_model, vim.log.levels.INFO)
end

--- Goose Recipe Execution Module
--- Handles parameter prompting and recipe execution in goose.nvim sidebar
---
--- This module manages the execution workflow including parameter collection
--- with type validation, CLI command construction with proper escaping, and
--- integration with goose.nvim sidebar for streaming output.
---
--- Recipe execution uses `goose run --recipe <path>` CLI syntax directly,
--- bypassing goose.nvim's job builder which only supports `--text` flag.
--- This ensures recipes are executed as intended rather than sent as text.
---
--- @module neotex.plugins.ai.goose.picker.execution

local M = {}

-- plenary.job for CLI execution with output streaming
local Job = require('plenary.job')

-- Module state: pending recipe for sidebar parameter input
-- Structure: { path: string, metadata: table, param_key: string } or nil
M._pending_recipe = nil

-- Internal helper for parameter serialization
--- Serialize parameters table to key=value,key2=value2 format
--- @param params table Dictionary of parameter key-value pairs
--- @return string Serialized parameter string
function M._serialize_params(params)
  if not params or vim.tbl_count(params) == 0 then
    return ''
  end

  local param_parts = {}
  for key, value in pairs(params) do
    table.insert(param_parts, string.format('%s=%s', key, tostring(value)))
  end
  return table.concat(param_parts, ',')
end

--- Run a recipe in goose.nvim sidebar using direct CLI execution
--- Executes `goose run --recipe <path>` directly, bypassing goose.nvim's
--- job builder which only supports --text flag. Output streams to sidebar.
---
--- @param recipe_path string Absolute path to recipe file
--- @param metadata table Parsed recipe metadata from metadata.parse()
--- @return nil
function M.run_recipe_in_sidebar(recipe_path, metadata)
  -- Validate recipe file exists
  if not recipe_path or vim.fn.filereadable(recipe_path) ~= 1 then
    vim.notify(
      string.format('Recipe file not found: %s', recipe_path or 'nil'),
      vim.log.levels.ERROR
    )
    return
  end

  -- Ensure goose.nvim plugin is loaded (handles lazy.nvim lazy-loading)
  local goose_loaded, _ = pcall(require, 'goose')
  if not goose_loaded then
    vim.notify(
      'goose.nvim required for recipe execution. Install plugin: azorng/goose.nvim',
      vim.log.levels.ERROR
    )
    return
  end

  -- Load goose modules for UI integration
  local state = require('goose.state')
  local ui = require('goose.ui.ui')
  local goose_core = require('goose.core')

  -- Recipe name for display
  local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')

  -- Prompt for required parameters if any exist
  local params = {}
  if metadata.parameters and #metadata.parameters > 0 then
    params = M.prompt_for_parameters(metadata.parameters)
    if params == nil then
      -- User cancelled or validation failed
      return
    end
  end

  -- Notify user
  vim.notify(
    string.format('Starting recipe: %s', recipe_name),
    vim.log.levels.INFO
  )

  -- Open sidebar if not already open (without starting a new session)
  goose_core.open({ focus = 'output', new_session = true })

  -- Build CLI args: goose run --recipe <path>
  local args = { 'run', '--recipe', recipe_path }

  -- Add parameters via --params flag (one per parameter)
  for key, value in pairs(params) do
    local str_value = tostring(value)
    -- Escape single quotes for shell safety
    str_value = str_value:gsub("'", "'\"'\"'")
    table.insert(args, '--params')
    table.insert(args, string.format("%s=%s", key, str_value))
  end

  -- Add session resume if active
  if state.active_session then
    table.insert(args, '--name')
    table.insert(args, state.active_session.name)
    table.insert(args, '--resume')
  end

  -- Execute recipe via direct CLI call with output streaming to sidebar
  state.goose_run_job = Job:new({
    command = 'goose',
    args = args,
    on_start = function()
      vim.schedule(function()
        -- Render initial output state
        if state.windows then
          ui.render_output()
        end
      end)
    end,
    on_stdout = function(_, out)
      if out then
        vim.schedule(function()
          -- Reload modified file buffers
          vim.cmd('checktime')

          -- Capture session ID for new sessions
          if not state.active_session then
            local session_id = out:match("session id:%s*([%w_]+)")
            if session_id then
              vim.defer_fn(function()
                local session_mod = require('goose.session')
                state.active_session = session_mod.get_by_name(session_id)
              end, 100)
            end
          end
        end)
      end
    end,
    on_stderr = function(_, err)
      if err then
        vim.schedule(function()
          -- Filter out informational messages from goose CLI
          local is_info = err:match('^%s*Parameters used') or
                          err:match('^%s*Description:') or
                          err:match('^%s*Loading recipe:') or
                          err:match('^%s*$')
          if not is_info then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        state.goose_run_job = nil
        require('goose.review').check_cleanup_breakpoint()
        -- Final render
        if state.windows then
          ui.render_output()
          ui.scroll_to_bottom()
        end
      end)
    end
  })

  state.goose_run_job:start()
end

--- Prompt user for recipe parameters
--- Collects parameter values based on requirement type (required, optional, user_prompt)
---
--- @param parameters table Array of parameter definitions from metadata
--- @return table|nil Dictionary of parameter key-value pairs, or nil if cancelled
function M.prompt_for_parameters(parameters)
  if not parameters or #parameters == 0 then
    return {}
  end

  local params = {}

  for _, param in ipairs(parameters) do
    -- Skip optional parameters with defaults (use default value)
    if param.requirement == 'optional' and param.default then
      params[param.key] = param.default
    -- Prompt for required and user_prompt parameters
    elseif param.requirement == 'required' or param.requirement == 'user_prompt' then
      local prompt_text = string.format(
        'Enter %s (%s)%s: ',
        param.key,
        param.input_type,
        param.description ~= '' and ' - ' .. param.description or ''
      )

      local ok, value = pcall(vim.fn.input, prompt_text)
      if not ok or value == '' then
        -- User cancelled or provided empty value for required parameter
        if param.requirement == 'required' then
          vim.notify(
            string.format('Required parameter "%s" not provided', param.key),
            vim.log.levels.ERROR
          )
          return nil
        end
      else
        -- Validate parameter type
        local valid, converted = M.validate_param(value, param.input_type)
        if not valid then
          vim.notify(
            string.format('Invalid %s value for parameter "%s"', param.input_type, param.key),
            vim.log.levels.ERROR
          )
          return nil
        end
        params[param.key] = converted
      end
    end
  end

  return params
end

--- Validate parameter value against type definition
--- Checks that parameter value matches expected type (string, number, boolean)
---
--- @param value string User-provided parameter value
--- @param param_type string Expected type: "string", "number", "boolean"
--- @return boolean, any Valid flag and converted value
function M.validate_param(value, param_type)
  if param_type == 'string' then
    -- String type: non-empty
    if value and value ~= '' then
      return true, value
    end
    return false, nil

  elseif param_type == 'number' then
    -- Number type: convert via tonumber
    local num = tonumber(value)
    if num then
      return true, num
    end
    return false, nil

  elseif param_type == 'boolean' then
    -- Boolean type: accept true/false/yes/no/1/0
    local lower = value:lower()
    if lower == 'true' or lower == 'yes' or lower == '1' then
      return true, true
    elseif lower == 'false' or lower == 'no' or lower == '0' then
      return true, false
    end
    return false, nil

  else
    -- Unknown type: accept as string
    return true, value
  end
end

--- Run a recipe in neovim terminal for interactive CLI usage
--- Executes `goose run --recipe <path>` in a terminal window using
--- toggleterm.nvim if available, or native :terminal as fallback.
--- This enables full interactive goose CLI experience with real-time I/O.
---
--- @param recipe_path string Absolute path to recipe file
--- @param metadata table Parsed recipe metadata from metadata.parse()
--- @return nil
function M.run_recipe_in_terminal(recipe_path, metadata)
  -- Validate recipe file exists
  if not recipe_path or vim.fn.filereadable(recipe_path) ~= 1 then
    vim.notify(
      string.format('Recipe file not found: %s', recipe_path or 'nil'),
      vim.log.levels.ERROR
    )
    return
  end

  -- Recipe name for display
  local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')

  -- Prompt for required parameters if any exist
  local params = {}
  if metadata.parameters and #metadata.parameters > 0 then
    params = M.prompt_for_parameters(metadata.parameters)
    if params == nil then
      -- User cancelled or validation failed
      return
    end
  end

  -- Build goose CLI command
  -- Use single quotes around path (matching <C-p> preview pattern that works)
  local cmd = string.format("goose run --recipe '%s'", recipe_path)

  -- Add parameters via --params flag (one per parameter)
  for key, value in pairs(params) do
    local str_value = tostring(value)
    -- Escape single quotes in parameter values
    str_value = str_value:gsub("'", "'\"'\"'")
    cmd = cmd .. string.format(" --params '%s=%s'", key, str_value)
  end

  -- Notify user
  vim.notify(
    string.format('Starting recipe in terminal: %s', recipe_name),
    vim.log.levels.INFO
  )

  -- Check if toggleterm is available
  local has_toggleterm = pcall(require, 'toggleterm')
  if has_toggleterm then
    -- Use toggleterm's Lua API directly to avoid vim.cmd escaping issues
    local Terminal = require('toggleterm.terminal').Terminal
    local goose_term = Terminal:new({
      cmd = cmd,
      direction = 'horizontal',
      close_on_exit = false,
      on_open = function(term)
        vim.api.nvim_buf_set_name(term.bufnr, string.format('goose:%s', recipe_name))
      end,
    })
    goose_term:toggle()
  else
    -- Fallback to native terminal
    vim.cmd('terminal ' .. cmd)
  end
end

--- Validate recipe syntax using goose CLI
--- Runs goose recipe validate to check recipe structure
---
--- @param recipe_path string Absolute path to recipe file
--- @return nil
function M.validate_recipe(recipe_path)
  -- Execute command and capture output
  local output = vim.fn.system({ 'goose', 'recipe', 'validate', recipe_path })
  local exit_code = vim.v.shell_error

  -- Show result notification
  if exit_code == 0 then
    vim.notify('Recipe validation passed: ' .. recipe_path, vim.log.levels.INFO)
  else
    vim.notify('Recipe validation failed:\n' .. output, vim.log.levels.ERROR)
  end
end

--- Clear pending recipe state
--- Used for cleanup when sidebar is closed without submission
---
--- @return nil
function M._clear_pending_recipe()
  M._pending_recipe = nil
end

--- Prompt for recipe parameter in sidebar
--- Opens goose sidebar with prompt message and sets up submit handler
--- to execute recipe with user's input when submitted
---
--- @param recipe_path string Absolute path to recipe file
--- @param metadata table Parsed recipe metadata from metadata.parse()
--- @param param_key string Parameter key to prompt for
--- @return nil
function M.prompt_in_sidebar(recipe_path, metadata, param_key)
  -- Validate inputs
  if not recipe_path or not metadata or not param_key then
    vim.notify(
      'Invalid parameters for prompt_in_sidebar',
      vim.log.levels.ERROR
    )
    return
  end

  -- Ensure goose.nvim plugin is loaded
  local goose_loaded, _ = pcall(require, 'goose')
  if not goose_loaded then
    vim.notify(
      'goose.nvim required for sidebar prompting. Install plugin: azorng/goose.nvim',
      vim.log.levels.ERROR
    )
    return
  end

  -- Load goose modules for UI integration
  local state = require('goose.state')
  local ui = require('goose.ui.ui')
  local goose_core = require('goose.core')
  local config = require('goose.config')

  -- Store pending recipe state
  M._pending_recipe = {
    path = recipe_path,
    metadata = metadata,
    param_key = param_key,
  }

  -- Find parameter definition for prompt message
  local param_def = nil
  for _, param in ipairs(metadata.parameters) do
    if param.key == param_key then
      param_def = param
      break
    end
  end

  local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
  local prompt_message = string.format(
    'Recipe: %s\nParameter: %s (%s)%s\n\nEnter your input below and press Enter to execute:\n(Press Escape to cancel)',
    recipe_name,
    param_key,
    param_def and param_def.input_type or 'string',
    param_def and param_def.description ~= '' and '\nDescription: ' .. param_def.description or ''
  )

  -- Open sidebar with focus on input
  goose_core.open({ focus = 'input', new_session = true })

  -- Wait for sidebar to be fully initialized
  vim.defer_fn(function()
    if not state.windows then
      vim.notify('Failed to open goose sidebar', vim.log.levels.ERROR)
      M._pending_recipe = nil
      return
    end

    -- Write prompt message to output buffer
    local output_buf = state.windows.output_buf
    if output_buf and vim.api.nvim_buf_is_valid(output_buf) then
      local lines = vim.split(prompt_message, '\n')
      -- Temporarily enable modifiable to write content
      vim.bo[output_buf].modifiable = true
      vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, lines)
      vim.bo[output_buf].modifiable = false
    end

    -- Set up WinClosed autocmd to clear state when sidebar is closed
    local input_buf = state.windows.input_buf
    if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
      vim.api.nvim_create_autocmd('WinClosed', {
        buffer = input_buf,
        once = true,
        callback = function()
          M._clear_pending_recipe()
        end,
      })

      -- Set up escape key to close sidebar and clear state
      vim.keymap.set('n', '<Esc>', function()
        M._clear_pending_recipe()
        vim.cmd('close')
      end, {
        buffer = input_buf,
        silent = true,
        desc = 'Cancel recipe parameter input',
      })

      -- Set up submit keymap override on input buffer
      local submit_key = (config.values.keymap.window and config.values.keymap.window.submit) or '<CR>'
      local handler = M._create_recipe_submit_handler(state.windows)

      vim.keymap.set('n', submit_key, handler, {
        buffer = input_buf,
        silent = false,
        desc = 'Submit recipe parameter input',
      })

      -- Auto-resize input window as content grows (including wrapped lines)
      local input_win = state.windows.input_win
      local output_win = state.windows.output_win
      local original_input_height = vim.api.nvim_win_get_height(input_win)
      local original_output_height = vim.api.nvim_win_get_height(output_win)
      local total_height = original_input_height + original_output_height

      vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'CursorMovedI' }, {
        group = vim.api.nvim_create_augroup('GooseRecipeResize', { clear = true }),
        buffer = input_buf,
        callback = function()
          -- Calculate display lines including wrapped lines
          local win_width = vim.api.nvim_win_get_width(input_win)
          local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
          local display_lines = 0

          for _, line in ipairs(lines) do
            -- Calculate how many display rows this line takes when wrapped
            local line_width = vim.fn.strdisplaywidth(line)
            if line_width == 0 then
              display_lines = display_lines + 1
            else
              display_lines = display_lines + math.ceil(line_width / win_width)
            end
          end

          -- Add 1 for the winbar, 1 for cursor room
          local needed_height = display_lines + 2
          local new_input_height = math.max(original_input_height, math.min(needed_height, math.floor(total_height * 0.7)))
          local new_output_height = total_height - new_input_height

          if new_output_height >= 3 then
            vim.api.nvim_win_set_height(input_win, new_input_height)
            vim.api.nvim_win_set_height(output_win, new_output_height)
          end
        end,
      })
    end
  end, 100)
end

--- Create submit handler for recipe parameter input
--- Returns a function that reads input, executes recipe, and clears state
---
--- @param windows table Goose sidebar windows state
--- @return function Submit handler function
function M._create_recipe_submit_handler(windows)
  return function()
    -- Check if we have pending recipe state
    if not M._pending_recipe then
      -- No pending recipe, fall through to normal goose.nvim behavior
      local core = require('goose.core')
      core.run()
      return
    end

    -- Read input buffer content
    local input_buf = windows.input_buf
    if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
      vim.notify('Invalid input buffer', vim.log.levels.ERROR)
      M._pending_recipe = nil
      return
    end

    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local user_input = table.concat(lines, '\n'):match('^%s*(.-)%s*$')

    if not user_input or user_input == '' then
      vim.notify('Parameter input cannot be empty', vim.log.levels.ERROR)
      return
    end

    -- Get pending recipe info
    local recipe_path = M._pending_recipe.path
    local metadata = M._pending_recipe.metadata
    local param_key = M._pending_recipe.param_key

    -- Clear pending state
    M._pending_recipe = nil

    -- Clear input buffer
    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {''})

    -- Build parameters table with user input
    local params = {}
    params[param_key] = user_input

    -- Notify user
    vim.notify(
      string.format('Executing recipe: %s', metadata.name or recipe_path),
      vim.log.levels.INFO
    )

    -- Execute recipe using existing run logic
    local state = require('goose.state')
    local ui = require('goose.ui.ui')
    local Job = require('plenary.job')

    -- Build CLI args: goose run --recipe <path>
    local args = { 'run', '--recipe', recipe_path }

    -- Add parameters via --params flag
    for key, value in pairs(params) do
      local str_value = tostring(value)
      -- Escape single quotes for shell safety
      str_value = str_value:gsub("'", "'\"'\"'")
      table.insert(args, '--params')
      table.insert(args, string.format("%s=%s", key, str_value))
    end

    -- Add session resume if active
    if state.active_session then
      table.insert(args, '--name')
      table.insert(args, state.active_session.name)
      table.insert(args, '--resume')
    end

    -- Execute recipe via direct CLI call with output streaming to sidebar
    state.goose_run_job = Job:new({
      command = 'goose',
      args = args,
      on_start = function()
        vim.schedule(function()
          if state.windows then
            ui.render_output()
          end
        end)
      end,
      on_stdout = function(_, out)
        if out then
          vim.schedule(function()
            vim.cmd('checktime')
            if not state.active_session then
              local session_id = out:match("session id:%s*([%w_]+)")
              if session_id then
                vim.defer_fn(function()
                  local session_mod = require('goose.session')
                  state.active_session = session_mod.get_by_name(session_id)
                end, 100)
              end
            end
          end)
        end
      end,
      on_stderr = function(_, err)
        if err then
          vim.schedule(function()
            local is_info = err:match('^%s*Parameters used') or
                            err:match('^%s*Description:') or
                            err:match('^%s*Loading recipe:') or
                            err:match('^%s*$')
            if not is_info then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end)
        end
      end,
      on_exit = function()
        vim.schedule(function()
          state.goose_run_job = nil
          require('goose.review').check_cleanup_breakpoint()
          if state.windows then
            ui.render_output()
            ui.scroll_to_bottom()
          end
        end)
      end
    })

    state.goose_run_job:start()
  end
end

return M

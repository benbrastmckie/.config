--- Goose Recipe Execution Module
--- Handles parameter prompting and recipe execution in goose.nvim sidebar
---
--- This module manages the execution workflow including parameter collection
--- with type validation, CLI command construction with proper escaping, and
--- integration with goose.nvim sidebar for streaming output.
---
--- @module neotex.plugins.ai.goose.picker.execution

local M = {}

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

--- Run a recipe in goose.nvim sidebar with real-time streaming output
--- Prompts user for required parameters, validates types, opens/ensures sidebar,
--- executes recipe via plenary.job, and displays output in goose sidebar UI
---
--- @param recipe_path string Absolute path to recipe file
--- @param metadata table Parsed recipe metadata from metadata.parse()
--- @return nil
function M.run_recipe_in_sidebar(recipe_path, metadata)
  -- Validate recipe file exists
  if vim.fn.filereadable(recipe_path) ~= 1 then
    vim.notify(
      string.format('Recipe file not found: %s', recipe_path),
      vim.log.levels.ERROR
    )
    return
  end

  -- Ensure goose.nvim plugin is loaded (handles lazy.nvim lazy-loading)
  -- This triggers lazy.nvim to load the plugin if not already loaded
  local goose_loaded, goose = pcall(require, 'goose')
  if not goose_loaded then
    vim.notify(
      'goose.nvim required for recipe execution. Install plugin: azorng/goose.nvim',
      vim.log.levels.ERROR
    )
    return
  end

  -- Now load goose.nvim modules (plugin is guaranteed loaded)
  -- Note: goose.nvim's UI module is at goose.ui.ui (no init.lua in ui/)
  local goose_core, goose_ui, goose_state
  local ok, err = pcall(function()
    goose_core = require('goose.core')
    goose_ui = require('goose.ui.ui')
    goose_state = require('goose.state')
  end)

  if not ok then
    vim.notify(
      string.format('Failed to load goose.nvim modules: %s', tostring(err)),
      vim.log.levels.ERROR
    )
    return
  end

  -- Collect parameters
  local params = M.prompt_for_parameters(metadata.parameters)
  if not params then
    vim.notify('Recipe execution cancelled', vim.log.levels.INFO)
    return
  end

  -- Ensure sidebar is open
  if not goose_state.windows or not goose_state.windows.output then
    local open_ok, open_err = pcall(goose_core.open)
    if not open_ok then
      -- Retry once
      vim.schedule(function()
        vim.defer_fn(function()
          local retry_ok = pcall(goose_core.open)
          if not retry_ok then
            vim.notify(
              'Failed to open goose sidebar. Try running :Goose first.',
              vim.log.levels.ERROR
            )
          end
        end, 100)
      end)
      return
    end
  end

  -- Stop any existing goose jobs
  if goose_state.goose_run_job then
    pcall(goose_core.stop)
  end

  -- Build recipe CLI arguments
  local args = { 'run', '--recipe', recipe_path }

  -- Add parameters if present
  local params_str = M._serialize_params(params)
  if params_str ~= '' then
    table.insert(args, '--params')
    table.insert(args, params_str)
  end

  -- Create plenary.job for recipe execution
  local Job = require('plenary.job')
  local job = Job:new({
    command = 'goose',
    args = args,
    on_start = function()
      vim.schedule(function()
        -- Notify start
        local param_count = vim.tbl_count(params)
        vim.notify(
          string.format(
            'Executing recipe: %s (%d parameters) | Output: Goose sidebar',
            metadata.name or 'Unknown',
            param_count
          ),
          vim.log.levels.INFO
        )

        -- Initial render
        pcall(goose_ui.render_output)
        pcall(goose_ui.scroll_to_bottom)
      end)
    end,
    on_stdout = function(_, line)
      if not line then return end
      vim.schedule(function()
        -- Reload session file changes
        vim.cmd('checktime')

        -- Update sidebar output
        pcall(goose_ui.render_output)
        pcall(goose_ui.scroll_to_bottom)
      end)
    end,
    on_stderr = function(_, line)
      if not line then return end
      vim.schedule(function()
        -- Display error in notification and sidebar
        vim.notify(
          string.format('Recipe error: %s', line),
          vim.log.levels.WARN
        )

        -- Still render in sidebar for full context
        vim.cmd('checktime')
        pcall(goose_ui.render_output)
        pcall(goose_ui.scroll_to_bottom)
      end)
    end,
    on_exit = function(_, return_code)
      vim.schedule(function()
        -- Clear job state
        if goose_state.goose_run_job then
          goose_state.goose_run_job = nil
        end

        -- Final render and notification
        vim.cmd('checktime')
        pcall(goose_ui.render_output)
        pcall(goose_ui.scroll_to_bottom)

        if return_code == 0 then
          vim.notify(
            string.format('Recipe completed: %s', metadata.name or 'Unknown'),
            vim.log.levels.INFO
          )
        else
          vim.notify(
            string.format('Recipe failed with code %d: %s', return_code, metadata.name or 'Unknown'),
            vim.log.levels.ERROR
          )
        end
      end)
    end,
  })

  -- Register job in goose state
  goose_state.goose_run_job = job

  -- Start job
  job:start()
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

return M

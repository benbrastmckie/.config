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

--- Run a recipe in goose.nvim sidebar using native goose.core.run()
--- Opens sidebar and sends /recipe:<name> command, letting Goose handle
--- parameter prompting conversationally within the chat interface
---
--- @param recipe_path string Absolute path to recipe file (unused, kept for API compatibility)
--- @param metadata table Parsed recipe metadata from metadata.parse()
--- @return nil
function M.run_recipe_in_sidebar(recipe_path, metadata)
  -- Ensure goose.nvim plugin is loaded (handles lazy.nvim lazy-loading)
  local goose_loaded, _ = pcall(require, 'goose')
  if not goose_loaded then
    vim.notify(
      'goose.nvim required for recipe execution. Install plugin: azorng/goose.nvim',
      vim.log.levels.ERROR
    )
    return
  end

  -- Load goose.core for native run() function
  local goose_core
  local ok, err = pcall(function()
    goose_core = require('goose.core')
  end)

  if not ok then
    vim.notify(
      string.format('Failed to load goose.nvim core module: %s', tostring(err)),
      vim.log.levels.ERROR
    )
    return
  end

  -- Build /recipe:<name> command - Goose will prompt for parameters conversationally
  local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
  local prompt = string.format('/recipe:%s', recipe_name)

  -- Notify user
  vim.notify(
    string.format('Starting recipe: %s', recipe_name),
    vim.log.levels.INFO
  )

  -- Use goose.core.run() which handles sidebar opening and job management
  goose_core.run(prompt)
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

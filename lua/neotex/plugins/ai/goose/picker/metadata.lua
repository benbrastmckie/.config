--- Goose Recipe Metadata Parser
--- Handles YAML parsing and parameter extraction from recipe files
---
--- This module parses recipe YAML files to extract metadata including name,
--- description, parameters, and subrecipes. It validates parameter definitions
--- and provides structured data for preview and execution modules.
---
--- @module neotex.plugins.ai.goose.picker.metadata

local M = {}

--- Parse recipe metadata from YAML file
--- Extracts name, description, parameters, subrecipes, and instructions
---
--- @param recipe_path string Absolute path to recipe YAML file
--- @return table|nil Parsed metadata structure, or nil on error:
---   - name: string - Recipe name
---   - description: string - Recipe description
---   - parameters: table - Array of parameter definitions
---   - sub_recipes: table - Array of subrecipe references
---   - instructions: string - Recipe instructions
function M.parse(recipe_path)
  -- Read file contents
  local file = io.open(recipe_path, 'r')
  if not file then
    vim.notify('Failed to read recipe file: ' .. recipe_path, vim.log.levels.ERROR)
    return nil
  end

  local yaml_content = file:read('*all')
  file:close()

  if not yaml_content or yaml_content == '' then
    vim.notify('Recipe file is empty: ' .. recipe_path, vim.log.levels.ERROR)
    return nil
  end

  -- Extract top-level fields
  local name = M.extract_yaml_field(yaml_content, 'name')
  local description = M.extract_yaml_field(yaml_content, 'description')
  local instructions = M.extract_yaml_field(yaml_content, 'instructions')

  -- Parse parameters array
  local parameters = M.extract_parameters(yaml_content)

  -- Extract sub_recipes (if present)
  local sub_recipes = M.extract_sub_recipes(yaml_content)

  -- Validate required fields
  if not name or name == '' then
    vim.notify('Recipe missing required field: name', vim.log.levels.ERROR)
    return nil
  end

  return {
    name = name,
    description = description or '',
    parameters = parameters,
    sub_recipes = sub_recipes,
    instructions = instructions or '',
  }
end

--- Extract parameters section from YAML content
--- Parses parameter definitions with type, requirement, default, description
---
--- @param yaml_content string Full YAML file content
--- @return table Array of parameter definitions with fields:
---   - key: string - Parameter name
---   - input_type: string - "string", "number", "boolean"
---   - requirement: string - "required", "optional", "user_prompt"
---   - description: string - Parameter description
---   - default: any - Default value (if optional)
function M.extract_parameters(yaml_content)
  local parameters = {}

  -- Find parameters section
  local params_start = yaml_content:find('parameters:')
  if not params_start then
    return parameters
  end

  -- Extract parameters section (until next top-level key or instructions)
  local params_section = yaml_content:sub(params_start)
  local params_end = params_section:find('\n[a-z_]+:') or params_section:find('\ninstructions:')
  if params_end then
    params_section = params_section:sub(1, params_end - 1)
  end

  -- Parse each parameter entry (marked by '  - key:')
  for param_block in params_section:gmatch('  %- key: ([^\n]+).-\n(.-)\n  [%-a-z]') do
    local key = param_block

    -- Extract parameter fields from the block
    local param_start = params_section:find('  %- key: ' .. key)
    if param_start then
      local next_param = params_section:find('\n  %- key:', param_start + 1)
      local next_section = params_section:find('\n[a-z_]+:', param_start + 1)
      local block_end = next_param or next_section or #params_section
      local block = params_section:sub(param_start, block_end)

      local input_type = block:match('input_type: ([^\n]+)') or 'string'
      local requirement = block:match('requirement: ([^\n]+)') or 'required'
      local description = block:match('description: ([^\n]+)') or ''
      local default = block:match('default: ([^\n]+)')

      -- Clean up extracted values (trim whitespace)
      input_type = input_type:match('^%s*(.-)%s*$')
      requirement = requirement:match('^%s*(.-)%s*$')
      description = description:match('^%s*(.-)%s*$')
      if default then
        default = default:match('^%s*(.-)%s*$')
      end

      table.insert(parameters, {
        key = key,
        input_type = input_type,
        requirement = requirement,
        description = description,
        default = default,
      })
    end
  end

  return parameters
end

--- Extract a single YAML field value using pattern matching
--- Simple helper for extracting top-level YAML fields
---
--- @param yaml_content string Full YAML file content
--- @param field_name string Field name to extract
--- @return string|nil Field value, or nil if not found
function M.extract_yaml_field(yaml_content, field_name)
  -- Match simple single-line value
  local pattern = field_name .. ': ([^\n]+)'
  local value = yaml_content:match(pattern)

  if value then
    -- Trim whitespace and remove quotes if present
    value = value:match('^%s*(.-)%s*$')
    value = value:gsub('^["\'](.-)["\'"]$', '%1')
    return value
  end

  -- Match multiline value with | or >
  local multiline_pattern = field_name .. ': [|>]%s*\n(.-)\n%S'
  local multiline_value = yaml_content:match(multiline_pattern)
  if multiline_value then
    return multiline_value
  end

  return nil
end

--- Extract sub_recipes section from YAML content
--- Parses subrecipe references if present
---
--- @param yaml_content string Full YAML file content
--- @return table Array of subrecipe names
function M.extract_sub_recipes(yaml_content)
  local sub_recipes = {}

  -- Find sub_recipes section
  local subrec_start = yaml_content:find('sub_recipes:')
  if not subrec_start then
    return sub_recipes
  end

  -- Extract sub_recipes section
  local subrec_section = yaml_content:sub(subrec_start)
  local subrec_end = subrec_section:find('\n[a-z_]+:')
  if subrec_end then
    subrec_section = subrec_section:sub(1, subrec_end - 1)
  end

  -- Parse each subrecipe entry
  for name in subrec_section:gmatch('  %- name: ([^\n]+)') do
    name = name:match('^%s*(.-)%s*$')
    table.insert(sub_recipes, name)
  end

  return sub_recipes
end

return M

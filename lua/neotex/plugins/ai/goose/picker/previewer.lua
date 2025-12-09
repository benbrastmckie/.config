--- Goose Recipe Previewer Module
--- Custom Telescope previewer for recipe metadata display
---
--- This module creates a custom Telescope previewer that shows recipe metadata
--- in a markdown-formatted preview window, including name, description,
--- parameters, subrecipes, and execution command preview.
---
--- @module neotex.plugins.ai.goose.picker.previewer

local M = {}

local previewers = require('telescope.previewers')
local putils = require('telescope.previewers.utils')
local metadata = require('neotex.plugins.ai.goose.picker.metadata')

--- Create a custom recipe previewer for Telescope
--- Returns a Telescope previewer instance configured for recipe display
---
--- @return table Telescope previewer instance
function M.create_recipe_previewer()
  return previewers.new_buffer_previewer({
    title = 'Recipe Preview',

    define_preview = function(self, entry, status)
      -- Get recipe path from entry
      local recipe_path = entry.value.path

      -- Parse recipe metadata
      local meta = metadata.parse(recipe_path)
      if not meta then
        vim.api.nvim_buf_set_lines(
          self.state.bufnr,
          0,
          -1,
          false,
          { 'Error: Failed to parse recipe metadata' }
        )
        return
      end

      -- Format preview lines
      local lines = M.format_preview(meta, recipe_path)

      -- Set buffer content
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Apply markdown syntax highlighting
      putils.highlighter(self.state.bufnr, 'markdown')
    end,
  })
end

--- Format recipe metadata for preview display
--- Converts parsed metadata into markdown-formatted text
---
--- @param meta table Parsed recipe metadata from metadata.parse()
--- @param recipe_path string Absolute path to recipe file
--- @return table Array of formatted lines for preview buffer
function M.format_preview(meta, recipe_path)
  local lines = {}

  -- Recipe header
  table.insert(lines, '# ' .. meta.name)
  table.insert(lines, '')
  table.insert(lines, '**Path:** `' .. recipe_path .. '`')
  table.insert(lines, '')

  -- Description
  if meta.description and meta.description ~= '' then
    table.insert(lines, '## Description')
    table.insert(lines, '')
    table.insert(lines, meta.description)
    table.insert(lines, '')
  end

  -- Parameters
  if #meta.parameters > 0 then
    table.insert(lines, '## Parameters')
    table.insert(lines, '')
    for i, param in ipairs(meta.parameters) do
      table.insert(lines, string.format('%d. **%s** (`%s`, `%s`)', i, param.key, param.input_type, param.requirement))
      if param.description and param.description ~= '' then
        table.insert(lines, '   - ' .. param.description)
      end
      if param.default then
        table.insert(lines, '   - Default: `' .. tostring(param.default) .. '`')
      end
      table.insert(lines, '')
    end
  else
    table.insert(lines, '## Parameters')
    table.insert(lines, '')
    table.insert(lines, '*No parameters required*')
    table.insert(lines, '')
  end

  -- Subrecipes
  if meta.sub_recipes and #meta.sub_recipes > 0 then
    table.insert(lines, '## Sub-Recipes')
    table.insert(lines, '')
    for _, subrec in ipairs(meta.sub_recipes) do
      table.insert(lines, '- ' .. subrec)
    end
    table.insert(lines, '')
  end

  -- Execution command preview
  table.insert(lines, '## Execution Command')
  table.insert(lines, '')
  table.insert(lines, '```bash')
  table.insert(lines, 'goose run --recipe ' .. recipe_path .. ' --interactive')
  if #meta.parameters > 0 then
    table.insert(lines, '# Parameters will be prompted interactively')
  end
  table.insert(lines, '```')
  table.insert(lines, '')

  -- Instructions preview (truncated)
  if meta.instructions and meta.instructions ~= '' then
    table.insert(lines, '## Instructions')
    table.insert(lines, '')
    local instr_lines = vim.split(meta.instructions, '\n')
    if #instr_lines > 20 then
      for i = 1, 20 do
        table.insert(lines, instr_lines[i])
      end
      table.insert(lines, '')
      table.insert(lines, '*... (truncated, ' .. (#instr_lines - 20) .. ' more lines)*')
    else
      for _, line in ipairs(instr_lines) do
        table.insert(lines, line)
      end
    end
  end

  return lines
end

return M

--- Goose Recipe Picker - Main Entry Point
--- Provides Telescope-based picker for Goose recipe management
---
--- This module orchestrates recipe discovery, preview, and execution through
--- a unified Telescope interface, replacing the original inline vim.ui.select
--- implementation with a rich, context-aware picker experience.
---
--- @module neotex.plugins.ai.goose.picker
--- @author Benjamin
--- @license MIT

local M = {}

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local discovery = require('neotex.plugins.ai.goose.picker.discovery')
local metadata = require('neotex.plugins.ai.goose.picker.metadata')
local previewer = require('neotex.plugins.ai.goose.picker.previewer')
local execution = require('neotex.plugins.ai.goose.picker.execution')

--- Show the Goose recipe picker with Telescope
--- Opens a Telescope picker showing all discovered recipes from project and global
--- directories, with preview window and context-aware keybindings
---
--- @param opts table|nil Optional Telescope configuration overrides
--- @return nil
function M.show_recipe_picker(opts)
  opts = opts or {}

  -- Discover recipes
  local recipes = discovery.find_recipes()
  if #recipes == 0 then
    return
  end

  -- Create entry maker for display formatting
  local entry_maker = function(recipe)
    return {
      value = recipe,
      display = string.format('%s %s', recipe.location, recipe.name),
      ordinal = recipe.name,
    }
  end

  -- Create picker
  pickers
    .new(opts, {
      prompt_title = 'Goose Recipes',
      finder = finders.new_table({
        results = recipes,
        entry_maker = entry_maker,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = previewer.create_recipe_previewer(),
      attach_mappings = function(prompt_bufnr, map)
        -- <CR>: Execute recipe in sidebar with parameter prompts
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local recipe = selection.value
          local meta = metadata.parse(recipe.path)
          if meta then
            execution.run_recipe_in_sidebar(recipe.path, meta)
          end
        end)

        -- <C-e>: Edit recipe file
        map('i', '<C-e>', function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd('edit ' .. selection.value.path)
        end)

        -- <C-p>: Preview recipe (explain mode)
        map('i', '<C-p>', function()
          local selection = action_state.get_selected_entry()
          local recipe = selection.value
          local cmd = string.format("goose run --recipe '%s' --explain", recipe.path)
          vim.cmd(string.format("TermExec cmd='%s'", cmd))
          vim.notify('Running recipe in preview mode (--explain)', vim.log.levels.INFO)
        end)

        -- <C-v>: Validate recipe
        map('i', '<C-v>', function()
          local selection = action_state.get_selected_entry()
          execution.validate_recipe(selection.value.path)
        end)

        -- <C-r>: Refresh picker
        map('i', '<C-r>', function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          current_picker:refresh(
            finders.new_table({
              results = discovery.find_recipes(),
              entry_maker = entry_maker,
            }),
            { reset_prompt = true }
          )
          vim.notify('Recipe list refreshed', vim.log.levels.INFO)
        end)

        return true
      end,
    })
    :find()

  -- Show notification with recipe count
  local project_count = 0
  local global_count = 0
  for _, recipe in ipairs(recipes) do
    if recipe.location == '[Project]' then
      project_count = project_count + 1
    else
      global_count = global_count + 1
    end
  end

  vim.notify(
    string.format(
      'Found %d recipes (%d project, %d global)',
      #recipes,
      project_count,
      global_count
    ),
    vim.log.levels.INFO
  )
end

--- Setup function for picker initialization
--- Called during plugin loading to register user commands and perform setup
---
--- @return nil
function M.setup()
  -- Register user command for direct invocation
  vim.api.nvim_create_user_command("GooseRecipes", function()
    M.show_recipe_picker()
  end, {
    desc = "Open Goose recipe picker"
  })
end

return M

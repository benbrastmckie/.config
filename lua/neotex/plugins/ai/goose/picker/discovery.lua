--- Goose Recipe Discovery Module
--- Handles recipe file discovery from project and global directories
---
--- This module scans both project-local (.goose/recipes/) and global
--- (~/.config/goose/recipes/) recipe directories, merges results with
--- priority-based sorting (project-first), and provides location labeling
--- for display differentiation.
---
--- @module neotex.plugins.ai.goose.picker.discovery

local M = {}

--- Find all recipes from project and global directories
--- Scans .goose/recipes/ (project) and ~/.config/goose/recipes/ (global),
--- returning a merged list with priority sorting (project recipes first)
---
--- @return table List of recipe entries with fields:
---   - name: string - Recipe filename without extension
---   - path: string - Absolute path to recipe file
---   - location: string - "[Project]" or "[Global]"
---   - priority: number - Sort priority (1=project, 2=global)
function M.find_recipes()
  local recipes = {}
  local seen_names = {}

  -- Find project recipes directory (search upward for .goose/)
  local project_dir = vim.fn.finddir('.goose', vim.fn.getcwd() .. ';')
  if project_dir ~= '' then
    local project_recipes_dir = vim.fn.fnamemodify(project_dir, ':p') .. 'recipes'
    if vim.fn.isdirectory(project_recipes_dir) == 1 then
      local files = vim.fn.glob(project_recipes_dir .. '/*.yaml', false, true)
      for _, filepath in ipairs(files) do
        local filename = vim.fn.fnamemodify(filepath, ':t')
        local name = vim.fn.fnamemodify(filepath, ':t:r')
        -- Skip if already seen (shouldn't happen but safeguard)
        if not seen_names[name] then
          table.insert(recipes, {
            name = name,
            path = vim.fn.fnamemodify(filepath, ':p'),
            location = '[Project]',
            priority = 1,
          })
          seen_names[name] = true
        end
      end
    end
  end

  -- Find global recipes directory
  local global_recipes_dir = vim.fn.expand('~/.config/goose/recipes')
  if vim.fn.isdirectory(global_recipes_dir) == 1 then
    local files = vim.fn.glob(global_recipes_dir .. '/*.yaml', false, true)
    for _, filepath in ipairs(files) do
      local filename = vim.fn.fnamemodify(filepath, ':t')
      local name = vim.fn.fnamemodify(filepath, ':t:r')
      -- Only add if not already present from project
      if not seen_names[name] then
        table.insert(recipes, {
          name = name,
          path = vim.fn.fnamemodify(filepath, ':p'),
          location = '[Global]',
          priority = 2,
        })
      end
    end
  end

  -- Sort by priority (project first), then alphabetically by name
  table.sort(recipes, function(a, b)
    if a.priority ~= b.priority then
      return a.priority < b.priority
    end
    return a.name < b.name
  end)

  -- Show warning if no recipes found
  if #recipes == 0 then
    vim.notify('No Goose recipes found in project or global directories', vim.log.levels.WARN)
  end

  return recipes
end

--- Get absolute path for a recipe file
--- Resolves recipe name to full filesystem path
---
--- @param recipe_name string Recipe filename (with or without .yaml extension)
--- @param location string "project" or "global"
--- @return string|nil Absolute path to recipe file, or nil if not found
function M.get_recipe_path(recipe_name, location)
  -- Add .yaml extension if missing
  local filename = recipe_name
  if not filename:match('%.yaml$') then
    filename = filename .. '.yaml'
  end

  local recipe_path = nil

  if location == 'project' then
    -- Find project recipes directory
    local project_dir = vim.fn.finddir('.goose', vim.fn.getcwd() .. ';')
    if project_dir ~= '' then
      local project_recipes_dir = vim.fn.fnamemodify(project_dir, ':p') .. 'recipes'
      recipe_path = project_recipes_dir .. '/' .. filename
    end
  elseif location == 'global' then
    -- Use global recipes directory
    recipe_path = vim.fn.expand('~/.config/goose/recipes/' .. filename)
  end

  -- Verify file exists
  if recipe_path and vim.fn.filereadable(recipe_path) == 1 then
    return vim.fn.fnamemodify(recipe_path, ':p')
  end

  return nil
end

return M

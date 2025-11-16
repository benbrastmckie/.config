------------------------------------------
-- Avante System Prompts Manager Module --
------------------------------------------
-- This module provides functions for managing system prompts
-- for the Avante AI assistant

local M = {}

-- Prompts file location 
local prompts_file = vim.fn.stdpath("config") .. "/lua/neotex/plugins/ai/util/system-prompts.json"

-- Default prompts to use if file is missing
local default_prompts = {
  default = "expert",
  prompts = {
    expert = {
      name = "Expert",
      description = "Expert mathematician and programmer with MCP tools",
      prompt =
      "You are an expert mathematician, logician and computer scientist with deep knowledge of Neovim, Lua, and programming languages. Provide concise, accurate responses with code examples when appropriate. For mathematical content, use clear notation and step-by-step explanations.\n\n{MCP_TOOLS_PLACEHOLDER}\n\nIMPORTANT: Never create files, make git commits, or perform system changes without explicit permission. Always ask before suggesting any file modifications or system operations. Only use the SEARCH/REPLACE blocks to suggest changes."
    },
    tutor = {
      name = "Tutor",
      description = "Educational assistant with MCP tools",
      prompt =
      "You are a patient and knowledgeable tutor. Explain concepts clearly with examples. When I ask questions, provide step-by-step explanations that build understanding rather than just giving answers. If I'm making a mistake, gently correct me and explain why. Focus on clarity and educational value in your responses.\n\n{MCP_TOOLS_PLACEHOLDER}"
    },
    coder = {
      name = "Coder",
      description = "Focused on code and implementation with MCP tools",
      prompt =
      "You are an expert software engineer with deep knowledge of various programming languages, algorithms, and software design principles. Focus primarily on providing high-quality, efficient code solutions with brief explanations. Keep explanations concise and prioritize showing working code over lengthy discussions. Suggest optimizations where appropriate. Provide error handling where needed.\n\n{MCP_TOOLS_PLACEHOLDER}\n\nIMPORTANT: Never create files, make git commits, or perform system changes without explicit permission."
    },
    researcher = {
      name = "Researcher",
      description = "Auto-uses Context7 and Tavily for comprehensive research",
      prompt =
      "You are a research-focused AI assistant specializing in comprehensive information gathering using both documentation and real-time search capabilities.\n\nAUTOMATIC WORKFLOW FOR LIBRARIES/FRAMEWORKS:\n1. When ANY library/framework is mentioned, immediately use 'resolve-library-id' to find the correct Context7 ID\n2. Use 'get-library-docs' with specific topics relevant to the user's question\n3. Base technical answers on retrieved official documentation\n4. Provide code examples from official docs when available\n\nAUTOMATIC WORKFLOW FOR CURRENT INFORMATION:\n1. For news, trends, current events, or recent developments, immediately use MCP tools\n2. Use MCP tools for detailed content from specific sources\n3. Prefer recent, authoritative sources for time-sensitive information\n4. Cross-reference multiple sources when needed\n\nEXAMPLES OF AUTOMATIC TOOL USAGE:\n- 'How do I use React hooks?' → Auto-search Context7 for React docs\n- 'Latest AI developments 2024' → Auto-search with MCP tools for current info\n- 'Vue routing setup' → Auto-get Vue Router documentation from Context7\n- 'Recent security vulnerabilities in Node.js' → Auto-search with MCP tools for news\n- 'Express middleware' → Auto-search Context7 for Express.js docs\n- 'Current JavaScript framework trends' → Auto-search with MCP tools for industry trends\n\n{MCP_TOOLS_PLACEHOLDER}\n\nAlways be proactive in using the appropriate MCP tools based on the information type requested."
    }
  }
}

-- Function to directly save default prompts
local function save_default_prompts()
  -- Make sure the directory exists
  local dir = vim.fn.fnamemodify(prompts_file, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    local success = vim.fn.mkdir(dir, "p")
    if success ~= 1 then
      vim.notify("Failed to create directory for system prompts: " .. dir, vim.log.levels.ERROR)
      return false
    end
  end

  -- Convert to JSON
  local ok, json = pcall(vim.fn.json_encode, default_prompts)
  if not ok or not json then
    vim.notify("Failed to encode default prompts to JSON", vim.log.levels.ERROR)
    return false
  end

  -- Format JSON for better readability
  local formatted_json = json:gsub('{"', '{\n  "')
      :gsub('","', '",\n  "')
      :gsub('":{"', '": {\n    "')
      :gsub('","', '",\n    "')
      :gsub('}}', '}\n}')
      :gsub('},', '},\n  ')
      :gsub('}}', '}\n}')

  -- Write to file
  local file = io.open(prompts_file, "w")
  if not file then
    vim.notify("Could not open prompts file for writing", vim.log.levels.ERROR)
    return false
  end

  file:write(formatted_json)
  file:close()
  return true
end

-- Ensure the prompts file exists
local function ensure_prompts_file()
  -- Check if file exists
  if vim.fn.filereadable(prompts_file) == 1 then
    return true
  end

  -- Create the file with default prompts using the direct save function
  local ok = save_default_prompts()
  if ok then
    vim.notify("Created new system prompts file with default prompts", vim.log.levels.INFO)
    return true
  else
    vim.notify("Failed to create system prompts file", vim.log.levels.ERROR)
    return false
  end
end

-- Load prompts from JSON file
function M.load_prompts()
  -- Ensure file exists
  if not ensure_prompts_file() then
    -- Return default prompts if file couldn't be created
    return vim.deepcopy(default_prompts)
  end

  -- Read the file content
  local content = vim.fn.readfile(prompts_file)
  if not content or #content == 0 then
    vim.notify("System prompts file is empty, recreating with defaults", vim.log.levels.WARN)
    save_default_prompts()
    return vim.deepcopy(default_prompts)
  end

  -- Parse JSON
  local ok, prompts = pcall(vim.fn.json_decode, table.concat(content, '\n'))
  if not ok or not prompts then
    vim.notify("Failed to parse system prompts file, recreating with defaults", vim.log.levels.ERROR)
    save_default_prompts()
    return vim.deepcopy(default_prompts)
  end

  return prompts
end

-- Save prompts to JSON file
function M.save_prompts(prompts)
  -- Ensure prompts is a table
  if type(prompts) ~= "table" then
    vim.notify("Invalid prompts data", vim.log.levels.ERROR)
    return false
  end

  -- Convert to JSON
  local ok, json = pcall(vim.fn.json_encode, prompts)
  if not ok or not json then
    vim.notify("Failed to encode prompts to JSON", vim.log.levels.ERROR)
    return false
  end

  -- Format JSON for better readability
  local formatted_json = json:gsub('{"', '{\n  "')
      :gsub('","', '",\n  "')
      :gsub('":{"', '": {\n    "')
      :gsub('","', '",\n    "')
      :gsub('}}', '}\n}')
      :gsub('},', '},\n  ')
      :gsub('}}', '}\n}')

  -- Write to file
  local file = io.open(prompts_file, "w")
  if not file then
    vim.notify("Could not open prompts file for writing", vim.log.levels.ERROR)
    return false
  end

  file:write(formatted_json)
  file:close()
  return true
end

-- Get a specific prompt by ID
function M.get_prompt(id)
  local prompts = M.load_prompts()
  if not prompts or not prompts.prompts or not prompts.prompts[id] then
    return nil
  end

  return prompts.prompts[id]
end

-- Get the default prompt
function M.get_default()
  local prompts = M.load_prompts()
  if not prompts or not prompts.default or not prompts.prompts then
    return nil
  end

  local default_id = prompts.default
  return prompts.prompts[default_id], default_id
end

-- Set a prompt as default
function M.set_default(id)
  local prompts = M.load_prompts()

  -- Check if the prompt exists
  if not prompts.prompts[id] then
    vim.notify("Prompt '" .. id .. "' does not exist", vim.log.levels.ERROR)
    return false
  end

  -- Update default
  prompts.default = id

  -- Save changes
  if M.save_prompts(prompts) then
    vim.notify("Set '" .. prompts.prompts[id].name .. "' as default system prompt", vim.log.levels.INFO)
    return true
  end

  return false
end

-- Apply a prompt to Avante
function M.apply_prompt(id)
  -- Get the prompt
  local prompt_data = M.get_prompt(id)
  if not prompt_data then
    vim.notify("Prompt '" .. id .. "' not found", vim.log.levels.ERROR)
    return false
  end

  -- Store current prompt name in global state
  _G.current_avante_prompt = {
    id = id,
    name = prompt_data.name
  }

  -- Update Avante's configuration
  local ok, config = pcall(require, "avante.config")
  if ok and config and config.override then
    -- Create the modified prompt that includes attribution at the beginning of responses
    local prompt_with_attribution = prompt_data.prompt

    -- Configure Avante with the prompt
    config.override({ 
      system_prompt = prompt_with_attribution,
      -- Remember the prompt name for use in attribution
      prompt_name = prompt_data.name
    })

    -- Show notification
    vim.notify("Applied system prompt: " .. prompt_data.name, vim.log.levels.INFO)
    return true
  else
    vim.notify("Failed to apply system prompt - Avante not available", vim.log.levels.ERROR)
  end

  return false
end

-- Create a new prompt
function M.create_prompt(data)
  -- Validate data
  if not data or not data.id or not data.name or not data.prompt then
    vim.notify("Invalid prompt data", vim.log.levels.ERROR)
    return false
  end

  -- Load existing prompts
  local prompts = M.load_prompts()

  -- Check if ID already exists
  if prompts.prompts[data.id] then
    vim.notify("A prompt with ID '" .. data.id .. "' already exists", vim.log.levels.ERROR)
    return false
  end

  -- Add new prompt
  prompts.prompts[data.id] = {
    name = data.name,
    description = data.description or "",
    prompt = data.prompt
  }

  -- Save changes
  if M.save_prompts(prompts) then
    vim.notify("Created new system prompt: " .. data.name, vim.log.levels.INFO)
    return true
  end

  return false
end

-- Edit an existing prompt
function M.edit_prompt(id, data)
  -- Validate data
  if not data or not data.name or not data.prompt then
    vim.notify("Invalid prompt data", vim.log.levels.ERROR)
    return false
  end

  -- Load existing prompts
  local prompts = M.load_prompts()

  -- Check if prompt exists
  if not prompts.prompts[id] then
    vim.notify("Prompt '" .. id .. "' does not exist", vim.log.levels.ERROR)
    return false
  end

  -- Update prompt
  prompts.prompts[id] = {
    name = data.name,
    description = data.description or prompts.prompts[id].description or "",
    prompt = data.prompt
  }

  -- Save changes
  if M.save_prompts(prompts) then
    vim.notify("Updated system prompt: " .. data.name, vim.log.levels.INFO)
    return true
  end

  return false
end

-- Delete a prompt
function M.delete_prompt(id)
  -- Load existing prompts
  local prompts = M.load_prompts()

  -- Check if prompt exists
  if not prompts.prompts[id] then
    vim.notify("Prompt '" .. id .. "' does not exist", vim.log.levels.ERROR)
    return false
  end

  -- Check if it's the default
  if prompts.default == id then
    vim.notify("Cannot delete the default prompt", vim.log.levels.ERROR)
    return false
  end

  -- Store name for notification
  local name = prompts.prompts[id].name

  -- Delete prompt
  prompts.prompts[id] = nil

  -- Save changes
  if M.save_prompts(prompts) then
    vim.notify("Deleted system prompt: " .. name, vim.log.levels.INFO)
    return true
  end

  return false
end

-- Show prompt selection menu
function M.show_prompt_selection()
  -- Load prompts
  local prompts = M.load_prompts()
  if not prompts or not prompts.prompts then
    vim.notify("No system prompts available", vim.log.levels.ERROR)
    return
  end

  -- Get default prompt ID
  local default_id = prompts.default

  -- Create selection items
  local items = {}
  local display_items = {}
  for id, prompt in pairs(prompts.prompts) do
    table.insert(items, id)
    local display = prompt.name
    if prompt.description and prompt.description ~= "" then
      display = display .. " - " .. prompt.description
    end
    if id == default_id then
      display = display .. " [Default]"
    end
    display_items[id] = display
  end

  -- Sort items alphabetically by name
  table.sort(items, function(a, b)
    return display_items[a] < display_items[b]
  end)

  -- Show selection UI
  vim.ui.select(items, {
    prompt = "Select a system prompt:",
    format_item = function(id) return display_items[id] end
  }, function(id)
    if not id then return end -- User cancelled

    -- Apply the selected prompt
    M.apply_prompt(id)

    -- Ask if it should be set as default
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Set as default for future sessions?",
    }, function(choice)
      if choice == "Yes" then
        M.set_default(id)
      end
    end)
  end)
end

-- Show prompt editor
function M.show_prompt_editor(edit_id)
  -- Load prompts
  local prompts = M.load_prompts()

  -- If editing, check if prompt exists
  local edit_prompt = nil
  if edit_id then
    edit_prompt = prompts.prompts[edit_id]
    if not edit_prompt then
      vim.notify("Prompt '" .. edit_id .. "' not found", vim.log.levels.ERROR)
      return
    end
  end

  -- Determine mode (create/edit)
  local mode = edit_id and "edit" or "create"

  -- If creating, first ask for ID
  if mode == "create" then
    vim.ui.input({
      prompt = "Enter prompt ID (lowercase, no spaces):",
      default = "",
    }, function(id)
      if not id or id == "" then return end -- User cancelled

      -- Check if ID already exists
      if prompts.prompts[id] then
        vim.notify("A prompt with ID '" .. id .. "' already exists", vim.log.levels.ERROR)
        return
      end

      -- Now proceed with prompt creation
      M.prompt_editor_fields(id, nil)
    end)
  else
    -- Edit existing prompt
    M.prompt_editor_fields(edit_id, edit_prompt)
  end
end

-- Helper for prompt editor fields
function M.prompt_editor_fields(id, existing)
  local mode = existing and "edit" or "create"

  -- Ask for name
  vim.ui.input({
    prompt = "Prompt name:",
    default = existing and existing.name or "",
  }, function(name)
    if not name or name == "" then return end -- User cancelled

    -- Ask for description
    vim.ui.input({
      prompt = "Description:",
      default = existing and existing.description or "",
    }, function(description)
      if not description then return end -- User cancelled

      -- Create a buffer for editing the prompt text
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = 'wipe'

      -- Set initial content if editing
      if existing and existing.prompt then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(existing.prompt, '\n'))
      else
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "You are an assistant that helps with...",
          "",
          "Focus on...",
          "",
          "IMPORTANT: Never create files, make git commits, or perform system changes without explicit permission."
        })
      end

      -- Set buffer filetype for syntax highlighting
      vim.bo[buf].filetype = 'markdown'

      -- Create a window with the buffer
      local width = math.floor(vim.o.columns * 0.8)
      local height = math.floor(vim.o.lines * 0.8)
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)

      local opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' ' .. (mode == "create" and "Create" or "Edit") .. ' System Prompt ',
        title_pos = 'center',
      }

      local win = vim.api.nvim_open_win(buf, true, opts)

      -- Set window options
      vim.api.nvim_win_set_option(win, 'wrap', true)
      vim.api.nvim_win_set_option(win, 'cursorline', true)

      -- Add prompt-specific mappings
      vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
        noremap = true,
        callback = function()
          -- Get buffer content
          local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local prompt_text = table.concat(content, '\n')

          -- Close the window
          vim.api.nvim_win_close(win, true)

          -- Prepare data
          local data = {
            id = id,
            name = name,
            description = description,
            prompt = prompt_text
          }

          -- Create or update prompt
          if mode == "create" then
            M.create_prompt(data)
          else
            M.edit_prompt(id, data)
          end
        end
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
        noremap = true,
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.notify("Cancelled prompt " .. mode, vim.log.levels.INFO)
        end
      })

      -- Add instructions at the top of the window
      local notify_msg = "Edit the system prompt text. Press ENTER to save, ESC to cancel."
      vim.api.nvim_echo({ { notify_msg, "Type" } }, false, {})
    end)
  end)
end

-- Show prompt management menu
function M.show_prompt_manager()
  -- Load prompts
  local prompts = M.load_prompts()

  -- Prepare main menu options
  local main_options = {
    { label = "Switch Prompt",     action = "switch" },
    { label = "Create New Prompt", action = "create" },
    { label = "Edit Prompt",       action = "edit_menu" },
    { label = "Delete Prompt",     action = "delete_menu" },
  }

  -- Show main selection UI
  vim.ui.select(main_options, {
    prompt = "System Prompts Manager:",
    format_item = function(item) return item.label end
  }, function(selected)
    if not selected then return end -- User cancelled

    if selected.action == "switch" then
      -- Show prompt selection menu
      M.show_prompt_selection()
    elseif selected.action == "create" then
      -- Show prompt editor for new prompt
      M.show_prompt_editor()
    elseif selected.action == "edit_menu" then
      -- Show edit submenu
      M.show_edit_submenu(prompts)
    elseif selected.action == "delete_menu" then
      -- Show delete submenu
      M.show_delete_submenu(prompts)
    end
  end)
end

-- Show edit prompt submenu
function M.show_edit_submenu(prompts)
  if not prompts then
    prompts = M.load_prompts()
  end

  -- Prepare edit options
  local edit_options = {}

  -- Add existing prompts to edit
  for id, prompt in pairs(prompts.prompts) do
    table.insert(edit_options, {
      label = prompt.name,
      id = id
    })
  end

  -- Sort options alphabetically by name
  table.sort(edit_options, function(a, b)
    return a.label < b.label
  end)

  if #edit_options == 0 then
    vim.notify("No prompts available to edit", vim.log.levels.WARN)
    return
  end

  -- Show selection UI
  vim.ui.select(edit_options, {
    prompt = "Select prompt to edit:",
    format_item = function(item) return item.label end
  }, function(selected)
    if not selected then return end -- User cancelled

    -- Show prompt editor for the selected prompt
    M.show_prompt_editor(selected.id)
  end)
end

-- Show delete prompt submenu
function M.show_delete_submenu(prompts)
  if not prompts then
    prompts = M.load_prompts()
  end

  -- Prepare delete options
  local delete_options = {}

  -- Add existing prompts to delete (except default)
  for id, prompt in pairs(prompts.prompts) do
    if id ~= prompts.default then
      table.insert(delete_options, {
        label = prompt.name,
        id = id
      })
    end
  end

  -- Sort options alphabetically by name
  table.sort(delete_options, function(a, b)
    return a.label < b.label
  end)

  if #delete_options == 0 then
    vim.notify("No prompts available to delete (can't delete the default prompt)", vim.log.levels.WARN)
    return
  end

  -- Show selection UI
  vim.ui.select(delete_options, {
    prompt = "Select prompt to delete:",
    format_item = function(item) return item.label end
  }, function(selected)
    if not selected then return end -- User cancelled

    -- Confirm deletion
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Are you sure you want to delete prompt: " .. selected.label .. "?",
    }, function(choice)
      if choice == "Yes" then
        -- Delete the prompt
        if M.delete_prompt(selected.id) then
          -- Return to delete submenu after successful deletion
          vim.defer_fn(function()
            M.show_delete_submenu()
          end, 100)
        end
      end
    end)
  end)
end

return M

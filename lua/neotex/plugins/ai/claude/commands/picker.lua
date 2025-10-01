-- neotex.plugins.ai.claude.commands.picker
-- Telescope picker for Claude commands with hierarchical display

local M = {}

-- Dependencies
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

-- Local modules
local parser = require("neotex.plugins.ai.claude.commands.parser")

--- Create flattened entries for telescope display
--- @param structure table Command hierarchy from parser.get_command_structure()
--- @return table Array of entries for telescope
local function create_picker_entries(structure)
  local entries = {}

  -- Add load all commands entry (added first, appears second from bottom)
  table.insert(entries, {
    is_load_all = true,
    name = "~~~load_all",  -- Ensures it sorts after everything with descending strategy
    display = string.format(
      "  %-40s %s",
      "[Load All Commands]",
      "Copy all global commands locally"
    ),
    command = nil
  })

  -- Add keyboard shortcuts help entry (added last, appears at bottom)
  table.insert(entries, {
    is_help = true,
    name = "~~~help",  -- Ensures it sorts after everything with descending strategy
    display = string.format(
      "  %-40s %s",
      "[Keyboard Shortcuts]",
      "Help"
    ),
    command = nil
  })

  -- Collect and sort primary command names alphabetically
  local sorted_primary_names = {}
  for primary_name, _ in pairs(structure.primary_commands) do
    table.insert(sorted_primary_names, primary_name)
  end
  table.sort(sorted_primary_names)

  -- Add primary commands and their dependents in alphabetical order
  -- With descending sort, we add dependents first so they appear below primaries visually
  for _, primary_name in ipairs(sorted_primary_names) do
    local primary_data = structure.primary_commands[primary_name]
    local primary_command = primary_data.command

    -- Add dependent commands first (with indentation)
    local dependents = primary_data.dependents
    for i, dependent in ipairs(dependents) do
      -- With descending sort, display order is reversed:
      -- - First item (i=1) appears LAST visually → should get └─
      -- - Last item (i=#dependents) appears FIRST visually → should get ├─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

      -- Add '*' prefix for local dependent commands
      local dependent_display = dependent.is_local and ("* " .. dependent.name) or ("  " .. dependent.name)
      table.insert(entries, {
        name = dependent.name,
        display = string.format(
          "%s %s %-38s %s",
          dependent.is_local and "*" or " ",
          indent_char,
          dependent.name,
          dependent.description or ""
        ),
        command = dependent,
        is_primary = false,
        parent = primary_name
      })
    end

    -- Add primary command after dependents (no indentation)
    -- Add '*' prefix for local commands
    local display_name = primary_command.is_local and ("* " .. primary_name) or ("  " .. primary_name)
    table.insert(entries, {
      name = primary_name,
      display = string.format(
        "%-42s %s",
        display_name,
        primary_command.description or ""
      ),
      command = primary_command,
      is_primary = true
    })
  end

  return entries
end

--- Create custom previewer for command documentation
--- @return table Telescope previewer
local function create_command_previewer()
  return previewers.new_buffer_previewer({
    title = "Command Details",
    define_preview = function(self, entry, status)
      -- Show help for keyboard shortcuts entry
      if entry.value.is_help then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "Keyboard Shortcuts:",
          "",
          "  Enter (CR)  - Insert command into Claude Code terminal",
          "  Ctrl-n      - Create new command (opens Claude Code with prompt)",
          "  Ctrl-l      - Load command locally (copies with dependencies)",
          "  Ctrl-u      - Update command from global version (overwrites local)",
          "  Ctrl-s      - Save local command to global (share across projects)",
          "  Ctrl-e      - Edit command (loads locally first if needed)",
          "  Escape      - Close picker",
          "",
          "Navigation:",
          "  Ctrl-j/k    - Move selection down/up",
          "  Ctrl-d      - Scroll preview down",
          "",
          "Command Structure:",
          "  Primary commands - Main workflow commands",
          "  ├─ dependent   - Supporting commands called by primary",
          "  └─ dependent   - Commands may appear under multiple primaries",
          "",
          "Indicators:",
          "  *  - Command defined locally in project (.claude/commands/)",
          "       Local commands override global ones from .config/",
          "  (no *) - Global command from ~/.config/.claude/commands/",
          "",
          "Command Management:",
          "  Ctrl-n - Create new command with Claude Code assistance",
          "  Ctrl-l - Copies global command to local (preserves local if exists)",
          "  Ctrl-u - Updates/overwrites local with global version",
          "  Ctrl-s - Saves local command to global (requires local command)",
          "  The picker refreshes after changes to show updated status",
          "",
          "Note: Commands are loaded from both project and .config directories"
        })
        return
      end

      -- Show info for load all commands entry
      if entry.value.is_load_all then
        local project_dir = vim.fn.getcwd()
        local global_dir = vim.fn.expand("~/.config")

        -- Scan global commands directory (same logic as load_all_commands_locally)
        local global_commands_dir = global_dir .. "/.claude/commands"
        local global_files = vim.fn.glob(global_commands_dir .. "/*.md", false, true)

        local count_to_load = 0
        local count_to_update = 0
        local local_commands_dir = project_dir .. "/.claude/commands"

        -- Check if global commands exist
        if type(global_files) == "table" and #global_files > 0 then
          -- Categorize commands into new and existing
          for _, global_path in ipairs(global_files) do
            local command_name = vim.fn.fnamemodify(global_path, ":t:r")
            local local_path = local_commands_dir .. "/" .. command_name .. ".md"

            if vim.fn.filereadable(local_path) == 1 then
              -- Local version exists - will be replaced
              count_to_update = count_to_update + 1
            else
              -- No local version - will be copied
              count_to_load = count_to_load + 1
            end
          end
        end

        local lines = {
          "Load All Commands",
          "",
          "This action will copy all commands from ~/.config/.claude/commands/",
          "to your local project's .claude/commands/ directory.",
          "",
        }

        if count_to_load > 0 or count_to_update > 0 then
          table.insert(lines, "**Operations:**")
          table.insert(lines, string.format("  - Copy %d new commands", count_to_load))
          table.insert(lines, string.format("  - Replace %d existing local commands", count_to_update))
          table.insert(lines, "")
          table.insert(lines, "**Note:** Local commands without global equivalents will not be affected.")
        else
          table.insert(lines, "**All commands already in sync!**")
        end

        table.insert(lines, "")
        table.insert(lines, "**Current Status:**")
        table.insert(lines, string.format("  Project directory: %s", project_dir))
        table.insert(lines, string.format("  Global commands directory: ~/.config/.claude/commands/"))
        table.insert(lines, "")
        table.insert(lines, "Press Enter to proceed with confirmation, or Escape to cancel.")

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        return
      end

      local command = entry.value.command
      if not command then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"No command data available"})
        return
      end

      local lines = {}

      -- Header
      table.insert(lines, string.format("━━━ %s ━━━", command.name))

      -- Basic info
      table.insert(lines, "")
      table.insert(lines, "**Type**: " .. (command.command_type == "primary" and "Primary Command" or "Dependent Command"))

      if entry.value.parent then
        table.insert(lines, "**Parent**: " .. entry.value.parent)
      end

      -- Description
      if command.description and command.description ~= "" then
        table.insert(lines, "")
        table.insert(lines, "**Description**:")
        table.insert(lines, command.description)
      end

      -- Arguments
      if command.argument_hint and command.argument_hint ~= "" then
        table.insert(lines, "")
        table.insert(lines, "**Usage**: /" .. command.name .. " " .. command.argument_hint)
      end

      -- Dependencies
      if command.command_type == "primary" and #command.dependent_commands > 0 then
        table.insert(lines, "")
        table.insert(lines, "**Dependent Commands**:")
        for _, dep in ipairs(command.dependent_commands) do
          table.insert(lines, "  • " .. dep)
        end
      elseif command.command_type == "dependent" and #command.parent_commands > 0 then
        table.insert(lines, "")
        table.insert(lines, "**Used By**:")
        for _, parent in ipairs(command.parent_commands) do
          table.insert(lines, "  • " .. parent)
        end
      end

      -- Tools
      if command.allowed_tools and type(command.allowed_tools) == "table" and #command.allowed_tools > 0 then
        table.insert(lines, "")
        table.insert(lines, "**Allowed Tools**:")
        table.insert(lines, table.concat(command.allowed_tools, ", "))
      end

      -- File path
      table.insert(lines, "")
      table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
      table.insert(lines, "**File**: " .. (command.filepath or "Unknown"))

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
    end,
  })
end

--- Send command to Claude Code terminal (event-driven, no timers)
--- @param command table Command data
local function send_command_to_terminal(command)
  local notify = require('neotex.util.notifications')
  local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')

  -- Get base command string with trailing space for arguments
  local command_text = "/" .. command.name .. " "

  -- Check if Claude Code plugin is available
  local has_claude_code = pcall(require, "claude-code")
  if not has_claude_code then
    notify.editor(
      "Claude Code plugin not found. Please install claude-code.nvim",
      notify.categories.ERROR,
      { command = command_text, required_plugin = "claude-code.nvim" }
    )
    return
  end

  -- Queue command - terminal_state.queue_command handles all timing logic
  terminal_state.queue_command(command_text, {
    -- Pass flag to ensure Claude Code opens if needed
    ensure_open = true,
    -- Removed auto_focus - queue_command() already calls focus_terminal()
    -- Removed notification - user doesn't need confirmation for picker selections
  })
end

--- Load command and its dependencies locally
--- @param command table Command data
--- @param silent boolean Don't show notifications for dependencies
--- @return boolean success
local function load_command_locally(command, silent)
  local notify = require('neotex.util.notifications')

  if not command.filepath then
    if not silent then
      notify.editor(
        "Command file path not available",
        notify.categories.ERROR,
        { command = command.name }
      )
    end
    return false
  end

  -- Check if file exists
  if vim.fn.filereadable(command.filepath) ~= 1 then
    if not silent then
      notify.editor(
        string.format("Command file not found: %s", command.filepath),
        notify.categories.ERROR,
        { command = command.name, filepath = command.filepath }
      )
    end
    return false
  end

  -- Determine if we need to copy from global to local
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")
  local local_commands_dir = project_dir .. "/.claude/commands"

  -- If command is already local or we're in .config directory, nothing to do
  if command.is_local or project_dir == global_dir then
    if not silent then
      notify.editor(
        string.format("Command '%s' is already local", command.name),
        notify.categories.STATUS,
        { command = command.name }
      )
    end
    return true
  end

  -- Create local .claude/commands directory if it doesn't exist
  vim.fn.system("mkdir -p " .. vim.fn.shellescape(local_commands_dir))

  -- Copy the command file to local
  local filename = vim.fn.fnamemodify(command.filepath, ":t")
  local local_filepath = local_commands_dir .. "/" .. filename

  local copy_cmd = string.format("cp %s %s",
    vim.fn.shellescape(command.filepath),
    vim.fn.shellescape(local_filepath)
  )

  local result = vim.fn.system(copy_cmd)
  if vim.v.shell_error ~= 0 then
    if not silent then
      notify.editor(
        string.format("Failed to copy command file: %s", result),
        notify.categories.ERROR,
        { command = command.name, error = result }
      )
    end
    return false
  end

  if not silent then
    notify.editor(
      string.format("Loaded command '%s' locally", command.name),
      notify.categories.STATUS,
      { command = command.name, from = command.filepath, to = local_filepath }
    )
  end

  -- Copy dependencies recursively
  if command.dependent_commands then
    -- Handle both string and table formats
    local deps
    if type(command.dependent_commands) == "table" then
      deps = command.dependent_commands
    else
      deps = vim.split(command.dependent_commands, ",")
    end

    for _, dep_name in ipairs(deps) do
      dep_name = vim.trim(dep_name)

      -- Find the dependency command in the global structure
      local parser = require('neotex.plugins.ai.claude.commands.parser')
      local global_commands_dir = vim.fn.expand("~/.config/.claude/commands")
      local dep_filepath = global_commands_dir .. "/" .. dep_name .. ".md"

      if vim.fn.filereadable(dep_filepath) == 1 then
        local dep_command = parser.parse_command_file(dep_filepath)
        if dep_command then
          dep_command.filepath = dep_filepath
          -- Recursively load dependency (silently to avoid spam)
          load_command_locally(dep_command, true)
        end
      end
    end

    if not silent then
      notify.editor(
        string.format("Loaded %d dependencies for '%s'", #deps, command.name),
        notify.categories.STATUS,
        { command = command.name, dependencies = table.concat(deps, ", ") }
      )
    end
  end

  return true
end

--- Load all global commands locally and update existing ones
--- Scans global directory, copies new commands, and replaces existing local commands
--- with global versions. Preserves local-only commands without global equivalents.
--- @return number count Number of commands loaded or updated
local function load_all_commands_locally()
  local notify = require('neotex.util.notifications')

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    notify.editor(
      "Already in the global commands directory",
      notify.categories.STATUS
    )
    return 0
  end

  -- Scan global commands directory
  local global_commands_dir = global_dir .. "/.claude/commands"
  local global_files = vim.fn.glob(global_commands_dir .. "/*.md", false, true)

  -- Check if global directory exists and has commands
  if type(global_files) ~= "table" or #global_files == 0 then
    notify.editor(
      "No global commands found in ~/.config/.claude/commands/",
      notify.categories.WARNING
    )
    return 0
  end

  -- Categorize commands into new and existing
  local commands_to_load = {}    -- New commands (not yet local)
  local commands_to_update = {}  -- Existing local commands with global versions
  local local_commands_dir = project_dir .. "/.claude/commands"

  for _, global_path in ipairs(global_files) do
    local command_name = vim.fn.fnamemodify(global_path, ":t:r")  -- filename without .md
    local local_path = local_commands_dir .. "/" .. command_name .. ".md"

    if vim.fn.filereadable(local_path) == 1 then
      -- Local version exists - will be replaced
      table.insert(commands_to_update, {
        name = command_name,
        global_path = global_path,
        local_path = local_path
      })
    else
      -- No local version - will be copied
      table.insert(commands_to_load, {
        name = command_name,
        global_path = global_path,
        local_path = local_path
      })
    end
  end

  -- Calculate total operations
  local total_operations = #commands_to_load + #commands_to_update

  -- Skip if no operations needed
  if total_operations == 0 then
    notify.editor(
      "All commands already in sync",
      notify.categories.STATUS
    )
    return 0
  end

  -- Show confirmation dialog
  local message = string.format(
    "Load all commands from global directory?\n\n" ..
    "This will:\n" ..
    "  - Copy %d new commands\n" ..
    "  - Replace %d existing local commands\n\n" ..
    "Local-only commands will not be affected.",
    #commands_to_load,
    #commands_to_update
  )

  local choice = vim.fn.confirm(message, "&Yes\n&No", 2)  -- Default to No
  if choice ~= 1 then
    notify.editor(
      "Load all commands cancelled",
      notify.categories.STATUS
    )
    return 0
  end

  -- Create local commands directory if needed
  vim.fn.mkdir(local_commands_dir, "p")

  -- Copy new commands
  local loaded_count = 0
  for _, cmd in ipairs(commands_to_load) do
    local success, content = pcall(vim.fn.readfile, cmd.global_path)
    if success then
      local write_success = pcall(vim.fn.writefile, content, cmd.local_path)
      if write_success then
        loaded_count = loaded_count + 1
      else
        notify.editor(
          string.format("Failed to write command: %s", cmd.name),
          notify.categories.ERROR
        )
      end
    else
      notify.editor(
        string.format("Failed to read global command: %s", cmd.name),
        notify.categories.ERROR
      )
    end
  end

  -- Replace existing commands
  local updated_count = 0
  for _, cmd in ipairs(commands_to_update) do
    local success, content = pcall(vim.fn.readfile, cmd.global_path)
    if success then
      local write_success = pcall(vim.fn.writefile, content, cmd.local_path)
      if write_success then
        updated_count = updated_count + 1
      else
        notify.editor(
          string.format("Failed to update command: %s", cmd.name),
          notify.categories.ERROR
        )
      end
    else
      notify.editor(
        string.format("Failed to read global command: %s", cmd.name),
        notify.categories.ERROR
      )
    end
  end

  -- Report results
  if loaded_count > 0 or updated_count > 0 then
    notify.editor(
      string.format("Loaded %d new, replaced %d existing commands", loaded_count, updated_count),
      notify.categories.SUCCESS
    )
  end

  return loaded_count + updated_count
end

--- Update local command from global version
--- @param command table Command data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_command_from_global(command, silent)
  local notify = require('neotex.util.notifications')

  if not command or not command.name then
    if not silent then
      notify.editor(
        "No command selected",
        notify.categories.ERROR
      )
    end
    return false
  end

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't update if we're in the global directory
  if project_dir == global_dir then
    if not silent then
      notify.editor(
        "Cannot update commands in the global directory",
        notify.categories.WARNING,
        { command = command.name }
      )
    end
    return false
  end

  -- Find the global version of the command
  local global_commands_dir = global_dir .. "/.claude/commands"
  local global_filepath = global_commands_dir .. "/" .. command.name .. ".md"

  -- Check if global version exists
  if vim.fn.filereadable(global_filepath) ~= 1 then
    if not silent then
      notify.editor(
        string.format("No global version found for command '%s'", command.name),
        notify.categories.ERROR,
        { command = command.name }
      )
    end
    return false
  end

  -- Create local commands directory if needed
  local local_commands_dir = project_dir .. "/.claude/commands"
  vim.fn.mkdir(local_commands_dir, "p")

  -- Copy the global file to local (overwriting if exists)
  local local_filepath = local_commands_dir .. "/" .. command.name .. ".md"
  local content = table.concat(vim.fn.readfile(global_filepath), "\n")
  vim.fn.writefile(vim.split(content, "\n"), local_filepath)

  if not silent then
    notify.editor(
      string.format("Updated '%s' from global version", command.name),
      notify.categories.SUCCESS,
      { command = command.name, from = global_filepath, to = local_filepath }
    )
  end

  -- Also update dependencies if they exist globally
  if command.dependent_commands then
    local deps
    if type(command.dependent_commands) == "table" then
      deps = command.dependent_commands
    else
      deps = vim.split(command.dependent_commands, ",")
    end

    local updated_deps = {}
    for _, dep_name in ipairs(deps) do
      dep_name = vim.trim(dep_name)
      local dep_global_path = global_commands_dir .. "/" .. dep_name .. ".md"

      if vim.fn.filereadable(dep_global_path) == 1 then
        local dep_local_path = local_commands_dir .. "/" .. dep_name .. ".md"
        local dep_content = table.concat(vim.fn.readfile(dep_global_path), "\n")
        vim.fn.writefile(vim.split(dep_content, "\n"), dep_local_path)
        table.insert(updated_deps, dep_name)
      end
    end

    if #updated_deps > 0 and not silent then
      notify.editor(
        string.format("Updated %d dependencies for '%s'", #updated_deps, command.name),
        notify.categories.STATUS,
        { command = command.name, dependencies = table.concat(updated_deps, ", ") }
      )
    end
  end

  return true
end

--- Save local command to global directory
--- @param command table Command data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_command_to_global(command, silent)
  local notify = require('neotex.util.notifications')

  if not command or not command.name then
    if not silent then
      notify.editor(
        "No command selected",
        notify.categories.ERROR
      )
    end
    return false
  end

  -- Check if command is local
  if not command.is_local then
    if not silent then
      notify.editor(
        string.format("Command '%s' is not local. Only local commands can be saved to global.", command.name),
        notify.categories.ERROR,
        { command = command.name, location = "global" }
      )
    end
    return false
  end

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't save if we're already in the global directory
  if project_dir == global_dir then
    if not silent then
      notify.editor(
        "Already in the global directory",
        notify.categories.WARNING,
        { command = command.name }
      )
    end
    return false
  end

  -- Find the local command file
  local local_commands_dir = project_dir .. "/.claude/commands"
  local local_filepath = local_commands_dir .. "/" .. command.name .. ".md"

  -- Check if local file exists
  if vim.fn.filereadable(local_filepath) ~= 1 then
    if not silent then
      notify.editor(
        string.format("Local command file not found: %s", local_filepath),
        notify.categories.ERROR,
        { command = command.name, filepath = local_filepath }
      )
    end
    return false
  end

  -- Create global commands directory if needed
  local global_commands_dir = global_dir .. "/.claude/commands"
  vim.fn.mkdir(global_commands_dir, "p")

  -- Copy the local file to global
  local global_filepath = global_commands_dir .. "/" .. command.name .. ".md"
  local content = table.concat(vim.fn.readfile(local_filepath), "\n")
  vim.fn.writefile(vim.split(content, "\n"), global_filepath)

  if not silent then
    notify.editor(
      string.format("Saved '%s' to global commands", command.name),
      notify.categories.USER_ACTION,
      { command = command.name, from = local_filepath, to = global_filepath }
    )
  end

  -- Also save dependencies if they exist locally
  if command.dependent_commands then
    local deps
    if type(command.dependent_commands) == "table" then
      deps = command.dependent_commands
    else
      deps = vim.split(command.dependent_commands, ",")
    end

    local saved_deps = {}
    for _, dep_name in ipairs(deps) do
      dep_name = vim.trim(dep_name)
      local dep_local_path = local_commands_dir .. "/" .. dep_name .. ".md"

      if vim.fn.filereadable(dep_local_path) == 1 then
        local dep_global_path = global_commands_dir .. "/" .. dep_name .. ".md"
        local dep_content = table.concat(vim.fn.readfile(dep_local_path), "\n")
        vim.fn.writefile(vim.split(dep_content, "\n"), dep_global_path)
        table.insert(saved_deps, dep_name)
      end
    end

    if #saved_deps > 0 and not silent then
      notify.editor(
        string.format("Saved %d dependencies to global for '%s'", #saved_deps, command.name),
        notify.categories.STATUS,
        { command = command.name, dependencies = table.concat(saved_deps, ", ") }
      )
    end
  end

  return true
end

--- Edit command file in buffer
--- @param command table Command data
local function edit_command_file(command)
  local notify = require('neotex.util.notifications')

  if not command.filepath then
    notify.editor(
      "Command file path not available",
      notify.categories.ERROR,
      { command = command.name }
    )
    return
  end

  -- Check if file exists
  if vim.fn.filereadable(command.filepath) ~= 1 then
    notify.editor(
      string.format("Command file not found: %s", command.filepath),
      notify.categories.ERROR,
      { command = command.name, filepath = command.filepath }
    )
    return
  end

  -- First load the command locally (which will copy it and its dependencies if needed)
  local success = load_command_locally(command, false)
  if not success then
    return
  end

  -- Determine the file to edit (local version if it was copied)
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")
  local file_to_edit = command.filepath

  -- If command was copied, use the local version
  if not command.is_local and project_dir ~= global_dir then
    local local_commands_dir = project_dir .. "/.claude/commands"
    local filename = vim.fn.fnamemodify(command.filepath, ":t")
    file_to_edit = local_commands_dir .. "/" .. filename
  end

  -- Open file in current window
  vim.cmd.edit(file_to_edit)

  notify.editor(
    string.format("Opened command file: %s", command.name),
    notify.categories.USER_ACTION,
    { command = command.name, filepath = file_to_edit }
  )
end

--- Main function to show Claude commands picker
--- @param opts table Options (optional)
function M.show_commands_picker(opts)
  opts = opts or {}
  local notify = require('neotex.util.notifications')

  -- Get command structure
  local structure = parser.get_command_structure()

  if vim.tbl_count(structure.primary_commands) == 0 then
    notify.editor(
      "No Claude commands found in .claude/commands/ or ~/.config/.claude/commands/",
      notify.categories.WARNING,
      {
        project = vim.fn.getcwd() .. "/.claude/commands",
        global = "~/.config/.claude/commands"
      }
    )
    return
  end

  -- Create entries for picker
  local entries = create_picker_entries(structure)

  -- Create picker
  pickers.new(opts, {
    prompt_title = "Claude Commands",
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name .. " " .. (entry.command and entry.command.description or ""),
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    sorting_strategy = "descending",  -- Bottom-up display like other pickers
    default_selection_index = 2,     -- Start on [Keyboard Shortcuts] (one above bottom)
    previewer = create_command_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      -- Insert command on Enter (or load all for Load All Commands)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          -- Handle Load All Commands action
          if selection.value.is_load_all then
            local loaded = load_all_commands_locally()
            if loaded > 0 then
              -- Refresh the picker to show updated local status
              actions.close(prompt_bufnr)
              vim.defer_fn(function()
                M.show_commands_picker(opts)
              end, 50)
            end
          -- Handle regular command insertion
          elseif selection.value.command and not selection.value.is_help then
            actions.close(prompt_bufnr)
            send_command_to_terminal(selection.value.command)
          end
        end
      end)

      -- Load command locally with Ctrl-l (keeps picker open and refreshes)
      map("i", "<C-l>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.command and not selection.value.is_help then
          local command = selection.value.command

          -- Load the command locally
          load_command_locally(command, false)

          -- Refresh the picker to show updated local status
          local current_prompt = action_state.get_current_line()
          actions.close(prompt_bufnr)

          -- Re-open the picker with refreshed data
          vim.defer_fn(function()
            M.show_commands_picker(opts)
            -- Restore the search prompt if there was one
            if current_prompt and current_prompt ~= "" then
              vim.defer_fn(function()
                vim.api.nvim_feedkeys(current_prompt, 'n', false)
              end, 50)
            end
          end, 100)
        end
      end)

      -- Edit command file with Ctrl-e
      map("i", "<C-e>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.command and not selection.value.is_help then
          actions.close(prompt_bufnr)
          edit_command_file(selection.value.command)
        end
      end)

      -- Update command from global version with Ctrl-u (keeps picker open and refreshes)
      map("i", "<C-u>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.command and not selection.value.is_help and not selection.value.is_load_all then
          local command = selection.value.command

          -- Update the command from global
          local success = update_command_from_global(command, false)

          if success then
            -- Refresh the picker to show updated status
            local current_prompt = action_state.get_current_line()
            actions.close(prompt_bufnr)

            -- Re-open the picker with refreshed data
            vim.defer_fn(function()
              M.show_commands_picker(opts)
              -- Restore the search prompt if there was one
              if current_prompt and current_prompt ~= "" then
                vim.defer_fn(function()
                  vim.api.nvim_feedkeys(current_prompt, 'n', false)
                end, 50)
              end
            end, 100)
          end
        end
      end)

      -- Save local command to global with Ctrl-s (keeps picker open and refreshes)
      map("i", "<C-s>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.command and not selection.value.is_help and not selection.value.is_load_all then
          local command = selection.value.command

          -- Save the command to global
          local success = save_command_to_global(command, false)

          if success then
            -- Refresh the picker to show updated status
            local current_prompt = action_state.get_current_line()
            actions.close(prompt_bufnr)

            -- Re-open the picker with refreshed data
            vim.defer_fn(function()
              M.show_commands_picker(opts)
              -- Restore the search prompt if there was one
              if current_prompt and current_prompt ~= "" then
                vim.defer_fn(function()
                  vim.api.nvim_feedkeys(current_prompt, 'n', false)
                end, 50)
              end
            end, 100)
          end
        end
      end)

      -- Create new command with Ctrl-n (event-driven, no timers)
      map("i", "<C-n>", function()
        local notify = require('neotex.util.notifications')
        local terminal_state = require('neotex.plugins.ai.claude.utils.terminal-state')
        local project_dir = vim.fn.getcwd()

        -- Close the picker
        actions.close(prompt_bufnr)

        -- Construct the prompt for new command creation
        local prompt_text = string.format(
          "Create a new claude-code command in the %s/.claude/commands/ directory called ",
          project_dir
        )

        -- Check if Claude Code is available
        local has_claude_code = pcall(require, "claude-code")
        if not has_claude_code then
          notify.editor(
            "Claude Code plugin not found. Please install claude-code.nvim",
            notify.categories.ERROR
          )
          return
        end

        -- Find or open Claude terminal
        local claude_buf = terminal_state.find_claude_terminal()
        if not claude_buf then
          notify.editor(
            "Opening Claude Code to create new command...",
            notify.categories.STATUS
          )
          vim.cmd("ClaudeCode")  -- Triggers TermOpen autocommand
        end

        -- Queue prompt - autocommand will send when ready
        terminal_state.queue_command(prompt_text, {
          auto_focus = true,
          notification = function()
            notify.editor(
              "Creating new command - complete the description in Claude Code",
              notify.categories.USER_ACTION
            )
          end
        })
      end)

      return true
    end,
  }):find()
end

return M
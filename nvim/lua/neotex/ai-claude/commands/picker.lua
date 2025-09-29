-- neotex.ai-claude.commands.picker
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
local parser = require("neotex.ai-claude.commands.parser")

--- Create flattened entries for telescope display
--- @param structure table Command hierarchy from parser.get_command_structure()
--- @return table Array of entries for telescope
local function create_picker_entries(structure)
  local entries = {}

  -- Add keyboard shortcuts help entry
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

  -- Add primary commands and their dependents
  -- With descending sort, we add dependents first so they appear below primaries visually
  for primary_name, primary_data in pairs(structure.primary_commands) do
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
          "  Ctrl-e      - Edit command markdown file",
          "  Escape      - Close picker",
          "",
          "Navigation:",
          "  Ctrl-j/k    - Move selection down/up",
          "  Ctrl-u/d    - Scroll preview up/down",
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
          "Note: Commands are loaded from both project and .config directories"
        })
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

--- Send command to Claude Code terminal
--- @param command table Command data
local function send_command_to_terminal(command)
  local notify = require('neotex.util.notifications')

  -- Get base command string
  -- Just the command name, no placeholders
  local command_text = "/" .. command.name

  -- Try to use ai-claude utilities first
  local claude_code_utils = require('neotex.ai-claude.utils.claude-code')

  -- Check if Claude Code is available through the plugin
  local has_claude_code, claude_code = pcall(require, "claude-code")

  if has_claude_code then
    -- Use claude-code plugin if available
    -- Try to get the current Claude buffer/terminal through the plugin
    local claude_buf = nil
    local claude_channel = nil

    -- Look for Claude Code terminal buffers
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and
         vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
        local buf_name = vim.api.nvim_buf_get_name(buf)
        -- More specific matching for Claude Code terminals
        if buf_name:lower():match("claude") or buf_name:match("ClaudeCode") then
          claude_buf = buf
          claude_channel = vim.api.nvim_buf_get_option(buf, "channel")
          break
        end
      end
    end

    if not claude_buf or not claude_channel then
      notify.editor(
        "Claude Code terminal not found. Opening Claude Code...",
        notify.categories.WARNING,
        { command = command_text, action = "opening_claude" }
      )

      -- Store the command to be inserted after Claude Code opens
      vim.g.claude_pending_command = command_text

      -- Set up an autocmd to insert the command when terminal is ready
      -- This triggers after the terminal buffer is fully loaded
      local autocmd_id = vim.api.nvim_create_autocmd({"TermOpen", "BufEnter", "BufWinEnter"}, {
        pattern = "*",
        callback = function(ev)
          local pending_cmd = vim.g.claude_pending_command
          if not pending_cmd then
            return false  -- Remove autocmd if no pending command
          end

          local buf = ev.buf
          -- Check if this is the Claude Code terminal
          if vim.api.nvim_buf_is_valid(buf) and
             vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name:lower():match("claude") or buf_name:match("ClaudeCode") then
              -- Clear the pending command
              vim.g.claude_pending_command = nil

              -- Small delay to ensure prompt is displayed
              vim.defer_fn(function()
                local channel = vim.api.nvim_buf_get_option(buf, "channel")
                if channel then
                  -- Send the command
                  vim.api.nvim_chan_send(channel, pending_cmd)

                  -- Focus and position cursor
                  local wins = vim.fn.win_findbuf(buf)
                  if #wins > 0 then
                    vim.api.nvim_set_current_win(wins[1])
                    vim.cmd('normal! G$')
                    vim.cmd('startinsert!')
                  end

                  notify.editor(
                    string.format("Inserted '%s' into Claude Code terminal", pending_cmd),
                    notify.categories.USER_ACTION,
                    { command = pending_cmd }
                  )
                end
              end, 250)  -- Small delay just for prompt to appear

              return true  -- Remove autocmd after successful insertion
            end
          end
        end
      })

      -- Try to open Claude Code
      local success = pcall(claude_code.toggle)
      if not success then
        vim.g.claude_pending_command = nil
        vim.api.nvim_del_autocmd(autocmd_id)
        notify.editor(
          "Failed to open Claude Code terminal",
          notify.categories.ERROR,
          { command = command_text }
        )
        return
      end

      -- Fallback: Clear pending command after timeout
      vim.defer_fn(function()
        if vim.g.claude_pending_command then
          vim.g.claude_pending_command = nil
          vim.api.nvim_del_autocmd(autocmd_id)
          notify.editor(
            "Timeout waiting for Claude Code terminal",
            notify.categories.WARNING,
            { command = command_text }
          )
        end
      end, 3000)  -- 3 second timeout
      return
    end

    -- Send command to terminal (without executing)
    vim.api.nvim_chan_send(claude_channel, command_text)

    -- Focus the Claude terminal
    local claude_wins = vim.fn.win_findbuf(claude_buf)
    if #claude_wins > 0 then
      vim.api.nvim_set_current_win(claude_wins[1])
      -- Enter insert mode if in normal mode
      if vim.api.nvim_get_mode().mode == 'n' then
        vim.cmd('startinsert!')
      end
    end

    notify.editor(
      string.format("Inserted '%s' into Claude Code terminal", command_text),
      notify.categories.USER_ACTION,
      { command = command_text, hint = command.argument_hint or "none" }
    )
  else
    -- Fallback: Claude Code plugin not available
    notify.editor(
      "Claude Code plugin not found. Please install claude-code.nvim",
      notify.categories.ERROR,
      { command = command_text, required_plugin = "claude-code.nvim" }
    )
  end
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

  -- Open file in current window
  vim.cmd.edit(command.filepath)

  notify.editor(
    string.format("Opened command file: %s", command.name),
    notify.categories.USER_ACTION,
    { command = command.name, filepath = command.filepath }
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
    default_selection_index = 2,     -- Start on first actual command
    previewer = create_command_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      -- Insert command on Enter
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.command and not selection.value.is_help then
          actions.close(prompt_bufnr)
          send_command_to_terminal(selection.value.command)
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

      return true
    end,
  }):find()
end

return M
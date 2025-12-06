-- neotex.plugins.ai.claude.commands.picker.display.previewer
-- Custom previewer for telescope picker with rich metadata display

local M = {}

-- Dependencies
local previewers = require("telescope.previewers")
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")

-- Maximum lines for doc previews (to avoid performance issues)
local MAX_PREVIEW_LINES = 150

--- Helper function to scan directory for sync info
--- @param global_dir string Global directory
--- @param project_dir string Project directory
--- @param subdir string Subdirectory path
--- @param extension string File extension pattern
--- @return table Array of file sync info
local function scan_directory_for_sync(global_dir, project_dir, subdir, extension)
  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = project_dir .. "/.claude/" .. subdir
  local global_files = vim.fn.glob(global_path .. "/" .. extension, false, true)

  local files = {}
  for _, global_file in ipairs(global_files) do
    local filename = vim.fn.fnamemodify(global_file, ":t")
    local local_file = local_path .. "/" .. filename

    local action = vim.fn.filereadable(local_file) == 1 and "replace" or "copy"
    table.insert(files, {
      name = filename,
      global_path = global_file,
      local_path = local_file,
      action = action,
    })
  end

  return files
end

--- Count operations by action type
--- @param files table Array of file sync info
--- @return number copy_count Number of copy operations
--- @return number replace_count Number of replace operations
local function count_actions(files)
  local copy_count = 0
  local replace_count = 0
  for _, file in ipairs(files) do
    if file.action == "copy" then
      copy_count = copy_count + 1
    else
      replace_count = replace_count + 1
    end
  end
  return copy_count, replace_count
end

--- Create preview for heading entries (category headers)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_heading(self, entry)
  local ordinal = entry.value.ordinal or "Unknown"
  local readme_path = nil

  -- Try local project first, then global
  local local_path = vim.fn.getcwd() .. "/.claude/" .. ordinal .. "/README.md"
  local global_path = vim.fn.expand("~/.config/.claude/" .. ordinal .. "/README.md")

  if vim.fn.filereadable(local_path) == 1 then
    readme_path = local_path
  elseif vim.fn.filereadable(global_path) == 1 then
    readme_path = global_path
  end

  if readme_path then
    -- Read README content with line limit
    local success, file = pcall(io.open, readme_path, "r")
    if success and file then
      local lines = {}
      local line_count = 0
      for line in file:lines() do
        table.insert(lines, line)
        line_count = line_count + 1
        if line_count >= MAX_PREVIEW_LINES then
          break
        end
      end
      file:close()

      -- Get total line count to check if truncation needed
      local total_lines = #vim.fn.readfile(readme_path)
      if total_lines > MAX_PREVIEW_LINES then
        table.insert(lines, "")
        table.insert(lines, "...")
        table.insert(lines, string.format(
          "[Preview truncated - showing first %d of %d lines]",
          MAX_PREVIEW_LINES, total_lines
        ))
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
      return
    end
  end

  -- Fallback to generic text
  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
    "Category: " .. ordinal,
    "",
    entry.value.display or "",
    "",
    "This is a category heading to organize artifacts in the picker.",
    "Navigate past this entry to view items in this category."
  })
end

--- Create preview for help entry (keyboard shortcuts)
--- @param self table Telescope previewer state
local function preview_help(self)
  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
    "Keyboard Shortcuts:",
    "",
    "Commands:",
    "  Enter (CR)     - Execute action for selected item",
    "                   Commands: Insert into Claude Code",
    "                   All others: Open file for editing",
    "  Ctrl-n         - Create new command (opens Claude Code with prompt)",
    "  Ctrl-l         - Load artifact locally (copies with dependencies)",
    "  Ctrl-s         - Save local artifact to global (share across projects)",
    "  Ctrl-e         - Edit artifact file (all types)",
    "",
    "Navigation:",
    "  Ctrl-j/k       - Move selection down/up",
    "  Escape         - Close picker",
    "",
    "Preview Navigation:",
    "  Ctrl-u         - Scroll preview up (half page)",
    "  Ctrl-d         - Scroll preview down (half page)",
    "  Ctrl-b         - Scroll preview up (full page)",
    "  Ctrl-f         - Scroll preview down (full page)",
    "",
    "Artifact Types:",
    "  [Commands]     - Claude Code slash commands",
    "    Primary        - Main workflow commands",
    "    ├─ command     - Supporting commands called by primary",
    "    └─ agent       - Agents used by this command",
    "",
    "  [Agents]       - Custom AI agent definitions",
    "    Standalone agents",
    "    Also shown under commands that use them",
    "",
    "  [Hook Events]  - Event triggers for hooks",
    "    Hook files displayed in metadata preview area",
    "",
    "  [TTS Files]    - Text-to-speech system files",
    "    config.json    - Configuration",
    "    dispatcher.sh  - Event router",
    "    library.sh     - Message generator",
    "",
    "Indicators:",
    "  *       - Artifact defined locally in project (.claude/)",
    "            Otherwise a global artifact from ~/.config/.claude/",
    "",
    "File Operations:",
    "  Ctrl-l/u/s  - Commands, Agents, Hooks, TTS, Templates, Lib, Docs",
    "  Ctrl-e      - Edit file (all artifact types)",
    "                Preserves executable permissions for .sh files",
    "",
    "  [Load All] - Batch synchronizes all artifact types",
    "               including commands, agents, hooks, and TTS files.",
    "               Replaces local with global artifacts with the same",
    "               name while preserving local-only artifacts.",
    "",
    "Notes: All artifacts loaded from both project and .config directories",
    "       Local artifacts override global ones from .config/"
  })
end

--- Create preview for Load All entry
--- @param self table Telescope previewer state
local function preview_load_all(self)
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Scan all artifact types
  local commands = scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
  local agents = scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
  local hooks = scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")
  local tts_hooks = scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh")
  local tts_files = scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh")
  local templates = scan_directory_for_sync(global_dir, project_dir, "templates", "*.yaml")
  local lib_utils = scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh")
  local docs = scan_directory_for_sync(global_dir, project_dir, "docs", "*.md")
  local agents_prompts = scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md")
  local agents_shared = scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md")
  local standards = scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md")
  local settings = scan_directory_for_sync(global_dir, project_dir, "", "settings.json")

  -- Merge TTS files
  local all_tts = {}
  for _, file in ipairs(tts_hooks) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_files) do
    table.insert(all_tts, file)
  end

  -- Merge agent protocols
  local all_protocols = {}
  for _, file in ipairs(agents_prompts) do
    table.insert(all_protocols, file)
  end
  for _, file in ipairs(agents_shared) do
    table.insert(all_protocols, file)
  end

  local cmd_copy, cmd_replace = count_actions(commands)
  local agt_copy, agt_replace = count_actions(agents)
  local hook_copy, hook_replace = count_actions(hooks)
  local tts_copy, tts_replace = count_actions(all_tts)
  local tmpl_copy, tmpl_replace = count_actions(templates)
  local lib_copy, lib_replace = count_actions(lib_utils)
  local doc_copy, doc_replace = count_actions(docs)
  local proto_copy, proto_replace = count_actions(all_protocols)
  local std_copy, std_replace = count_actions(standards)
  local set_copy, set_replace = count_actions(settings)

  local total_copy = cmd_copy + agt_copy + hook_copy + tts_copy + tmpl_copy + lib_copy + doc_copy +
                     proto_copy + std_copy + set_copy
  local total_replace = cmd_replace + agt_replace + hook_replace + tts_replace + tmpl_replace +
                        lib_replace + doc_replace + proto_replace + std_replace + set_replace

  local lines = {
    "Load All Artifacts",
    "",
    "This action will sync all artifacts from ~/.config/.claude/ to your",
    "local project's .claude/ directory.",
    "",
  }

  if total_copy + total_replace > 0 then
    table.insert(lines, "**Operations by Type:**")
    table.insert(lines, string.format("  Commands:        %d new, %d replace", cmd_copy, cmd_replace))
    table.insert(lines, string.format("  Agents:          %d new, %d replace", agt_copy, agt_replace))
    table.insert(lines, string.format("  Hooks:           %d new, %d replace", hook_copy, hook_replace))
    table.insert(lines, string.format("  TTS Files:       %d new, %d replace", tts_copy, tts_replace))
    table.insert(lines, string.format("  Templates:       %d new, %d replace", tmpl_copy, tmpl_replace))
    table.insert(lines, string.format("  Lib Utils:       %d new, %d replace", lib_copy, lib_replace))
    table.insert(lines, string.format("  Docs:            %d new, %d replace", doc_copy, doc_replace))
    table.insert(lines, string.format("  Agent Protocols: %d new, %d replace", proto_copy, proto_replace))
    table.insert(lines, string.format("  Standards:       %d new, %d replace", std_copy, std_replace))
    table.insert(lines, string.format("  Settings:        %d new, %d replace", set_copy, set_replace))
    table.insert(lines, "")
    table.insert(lines, string.format("**Total:** %d new, %d replace", total_copy, total_replace))
    table.insert(lines, "")
    table.insert(lines, "**Note:** Local-only artifacts will not be affected.")
    table.insert(lines, "          Execute permissions preserved for .sh files.")
  else
    table.insert(lines, "**All artifacts already in sync!**")
  end

  table.insert(lines, "")
  table.insert(lines, "**Current Status:**")
  table.insert(lines, string.format("  Project directory: %s", project_dir))
  table.insert(lines, "  Global directory:  ~/.config/.claude/")
  table.insert(lines, "")
  table.insert(lines, "Press Enter to proceed with confirmation, or Escape to cancel.")

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
end

--- Create preview for agent entries
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_agent(self, entry)
  local agent = entry.value.agent
  if not agent then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"No agent data available"})
    return
  end

  local lines = {
    "# Agent: " .. agent.name,
    "",
    "**Description**: " .. (agent.description or "N/A"),
    "",
    "**Allowed Tools**: " .. (agent.allowed_tools and #agent.allowed_tools > 0
      and table.concat(agent.allowed_tools, ", ") or "N/A"),
    "",
  }

  -- Show commands that use this agent
  if agent.parent_commands and #agent.parent_commands > 0 then
    table.insert(lines, "**Commands that use this agent**:")
    for i, cmd_name in ipairs(agent.parent_commands) do
      local tree_char = (i == #agent.parent_commands) and "└─" or "├─"
      table.insert(lines, "   " .. tree_char .. " " .. cmd_name)
    end
  else
    if entry.value.parent then
      table.insert(lines, "**Commands that use this agent**:")
      table.insert(lines, "   └─ " .. entry.value.parent)
    else
      table.insert(lines, "**Commands that use this agent**: None")
    end
  end

  table.insert(lines, "")
  table.insert(lines, "**File**: " .. agent.filepath)
  table.insert(lines, "")
  table.insert(lines, agent.is_local and "[Local] Local override" or "[Global] Global definition")

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
end

--- Create preview for hook event entries
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_hook_event(self, entry)
  local event_descriptions = {
    Stop = "Triggered after command completion",
    SessionStart = "When Claude Code session begins",
    SessionEnd = "When Claude Code session ends",
    SubagentStop = "After subagent completes",
    Notification = "Permission or idle notification events",
    PreToolUse = "Before tool execution",
    PostToolUse = "After tool execution",
    UserPromptSubmit = "When user prompt submitted",
    PreCompact = "Before context compaction",
  }

  local lines = {
    "# Hook Event: " .. entry.value.name,
    "",
    "**Description**: " .. (event_descriptions[entry.value.name] or "Unknown event"),
    "",
    "**Registered Hooks**: " .. #entry.value.hooks .. " hook(s)",
    "",
    "Hooks:",
  }
  for _, hook in ipairs(entry.value.hooks) do
    table.insert(lines, "- " .. hook.name .. " (" .. hook.filepath .. ")")
  end

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
end

--- Create preview for TTS file entries
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_tts_file(self, entry)
  local tts = entry.value
  if not tts then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"No TTS data available"})
    return
  end

  local lines = {
    "# TTS File: " .. tts.name,
    "",
    "**Description**: " .. (tts.description or "N/A"),
    "",
    "**Role**: " .. (tts.role or "N/A"),
    "",
    "**Directory**: " .. (tts.directory or "N/A"),
    "",
    "**Variables**: " .. (tts.variables and #tts.variables > 0
      and table.concat(tts.variables, ", ") or "None"),
    "",
    "**File**: " .. tts.name,
    "",
    tts.is_local and "[Local] Local override" or "[Global] Global configuration"
  }

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
end

--- Create preview for script entries (shell scripts)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_script(self, entry)
  local filepath = entry.value.filepath
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found"})
    return
  end

  local lines = vim.fn.readfile(filepath)

  -- Add metadata footer
  table.insert(lines, "")
  table.insert(lines, "# " .. string.rep("=", 60))
  table.insert(lines, "")
  table.insert(lines, "# File: " .. entry.value.name)

  -- Get permissions
  local perms = vim.fn.getfperm(filepath)
  table.insert(lines, "# Permissions: " .. (perms or "N/A"))

  table.insert(lines, "# Status: " .. (entry.value.is_local and "[Local]" or "[Global]"))
  table.insert(lines, "# Action: Run with <C-r> (prompts for arguments)")

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "sh")
end

--- Create preview for test entries (shell scripts)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_test(self, entry)
  local filepath = entry.value.filepath
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found"})
    return
  end

  local lines = vim.fn.readfile(filepath)

  -- Add metadata footer
  table.insert(lines, "")
  table.insert(lines, "# " .. string.rep("=", 60))
  table.insert(lines, "")
  table.insert(lines, "# File: " .. entry.value.name)

  -- Get permissions
  local perms = vim.fn.getfperm(filepath)
  table.insert(lines, "# Permissions: " .. (perms or "N/A"))

  table.insert(lines, "# Status: " .. (entry.value.is_local and "[Local]" or "[Global]"))
  table.insert(lines, "# Action: Run with <C-t> (executes test)")

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "sh")
end

--- Create preview for lib entries (shell scripts)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_lib(self, entry)
  local filepath = entry.value.filepath
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found"})
    return
  end

  local lines = vim.fn.readfile(filepath)

  -- Add metadata footer
  table.insert(lines, "")
  table.insert(lines, "# " .. string.rep("=", 60))
  table.insert(lines, "")
  table.insert(lines, "# File: " .. entry.value.name)

  -- Get permissions
  local perms = vim.fn.getfperm(filepath)
  table.insert(lines, "# Permissions: " .. (perms or "N/A"))

  table.insert(lines, "# Status: " .. (entry.value.is_local and "[Local]" or "[Global]"))

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "sh")
end

--- Create preview for template entries (YAML files)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_template(self, entry)
  local filepath = entry.value.filepath
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found"})
    return
  end

  local lines = vim.fn.readfile(filepath)

  -- Add metadata footer
  table.insert(lines, "")
  table.insert(lines, "# " .. string.rep("=", 60))
  table.insert(lines, "")
  table.insert(lines, "# File: " .. entry.value.name)
  table.insert(lines, "# Status: " .. (entry.value.is_local and "[Local]" or "[Global]"))

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "yaml")
end

--- Create preview for doc entries (markdown files)
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_doc(self, entry)
  local filepath = entry.value.filepath
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"File not found"})
    return
  end

  local success, file = pcall(io.open, filepath, "r")
  if not success or not file then
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Failed to open file"})
    return
  end

  local lines = {}
  local line_count = 0
  for line in file:lines() do
    table.insert(lines, line)
    line_count = line_count + 1
    if line_count >= MAX_PREVIEW_LINES then
      break
    end
  end
  file:close()

  -- Check if truncation needed
  local total_lines = #vim.fn.readfile(filepath)
  if total_lines > MAX_PREVIEW_LINES then
    table.insert(lines, "")
    table.insert(lines, "...")
    table.insert(lines, string.format(
      "[Preview truncated - showing first %d of %d lines]",
      MAX_PREVIEW_LINES, total_lines
    ))
  end

  -- Add metadata footer
  table.insert(lines, "")
  table.insert(lines, "---")
  table.insert(lines, "")
  table.insert(lines, "**File**: " .. entry.value.name)
  table.insert(lines, "**Status**: " .. (entry.value.is_local and "[Local]" or "[Global]"))

  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
end

--- Create preview for command entries
--- @param self table Telescope previewer state
--- @param entry table Telescope entry
local function preview_command(self, entry)
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
end

--- Create custom previewer for command documentation
--- @return table Telescope previewer
function M.create_command_previewer()
  return previewers.new_buffer_previewer({
    title = "Command Details",
    define_preview = function(self, entry, status)
      -- Route to appropriate preview function based on entry type
      if entry.value.is_heading then
        preview_heading(self, entry)
      elseif entry.value.is_help then
        preview_help(self)
      elseif entry.value.is_load_all then
        preview_load_all(self)
      elseif entry.value.entry_type == "agent" then
        preview_agent(self, entry)
      elseif entry.value.entry_type == "hook_event" then
        preview_hook_event(self, entry)
      elseif entry.value.entry_type == "tts_file" then
        preview_tts_file(self, entry)
      elseif entry.value.entry_type == "lib" then
        preview_lib(self, entry)
      elseif entry.value.entry_type == "script" then
        preview_script(self, entry)
      elseif entry.value.entry_type == "test" then
        preview_test(self, entry)
      elseif entry.value.entry_type == "template" then
        preview_template(self, entry)
      elseif entry.value.entry_type == "doc" then
        preview_doc(self, entry)
      elseif entry.value.entry_type == "command" then
        preview_command(self, entry)
      else
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {"Unknown entry type"})
      end
    end,
  })
end

return M

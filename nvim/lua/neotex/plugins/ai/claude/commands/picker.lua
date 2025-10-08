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

--- Helper function to get agents for a specific command
--- @param command_name string Name of the command
--- @param agent_deps table Agent dependencies map
--- @param agents table All agents
--- @return table Array of agents used by this command
local function get_agents_for_command(command_name, agent_deps, agents)
  local command_agents = {}
  local agent_names = agent_deps[command_name] or {}

  for _, agent_name in ipairs(agent_names) do
    for _, agent in ipairs(agents) do
      if agent.name == agent_name then
        table.insert(command_agents, agent)
        break
      end
    end
  end

  -- Sort agents alphabetically
  table.sort(command_agents, function(a, b)
    return a.name < b.name
  end)

  return command_agents
end

--- Format agent entry for display
--- @param agent table Agent data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_agent(agent, indent_char)
  local prefix = agent.is_local and "*" or " "
  local display_name = "[agent] " .. agent.name

  return string.format(
    "%s %s %-38s %s",
    prefix,
    indent_char,
    display_name,
    agent.description or ""
  )
end

--- Format hook entry for display
--- @param hook table Hook data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_hook(hook, indent_char)
  local prefix = hook.is_local and "*" or " "

  return string.format(
    "%s %s %-38s %s",
    prefix,
    indent_char,
    hook.name,
    hook.description or ""
  )
end

--- Format hook event header for display
--- @param event_name string Hook event name
--- @return string Formatted display string
local function format_hook_event(event_name)
  local display_name = "[Hook Event] " .. event_name
  local descriptions = {
    Stop = "After command completion",
    SessionStart = "When session begins",
    SessionEnd = "When session ends",
    SubagentStop = "After subagent completes",
    Notification = "Permission/idle events",
    PreToolUse = "Before tool execution",
    PostToolUse = "After tool execution",
    UserPromptSubmit = "When prompt submitted",
    PreCompact = "Before context compaction",
  }

  return string.format(
    "%-42s %s",
    display_name,
    descriptions[event_name] or ""
  )
end

--- Format TTS file for display
--- @param file table TTS file data
--- @return string Formatted display string
local function format_tts_file(file)
  local prefix = file.is_local and "*" or " "
  local role_label = "[" .. file.role .. "]"
  local location = file.directory  -- hooks|tts

  return string.format(
    "%s %-12s %-25s (%s) %dL",
    prefix,
    role_label,
    file.name,
    location,
    file.line_count or 0
  )
end

--- Create flattened entries for telescope display
--- Insertion order is REVERSED for descending sort: last inserted appears at TOP
--- @param structure table Extended structure from parser.get_extended_structure()
--- @return table Array of entries for telescope
local function create_picker_entries(structure)
  local entries = {}

  -- Special entries: Insert FIRST so they appear at BOTTOM with descending sort
  -- Add keyboard shortcuts help entry (added first, appears at absolute bottom)
  table.insert(entries, {
    is_help = true,
    name = "~~~help",
    display = string.format(
      "  %-40s %s",
      "[Keyboard Shortcuts]",
      "Help"
    ),
    command = nil,
    entry_type = "special"
  })

  -- Add load all commands entry (added second, appears second from bottom)
  table.insert(entries, {
    is_load_all = true,
    name = "~~~load_all",
    display = string.format(
      "  %-40s %s",
      "[Load All Artifacts]",
      "Sync commands, agents, hooks, TTS files"
    ),
    command = nil,
    entry_type = "special"
  })

  -- Helper function to scan a directory for files
  local function scan_directory(dir, pattern)
    local files = {}
    local file_paths = vim.fn.glob(dir .. "/" .. pattern, false, true)
    for _, filepath in ipairs(file_paths) do
      local filename = vim.fn.fnamemodify(filepath, ":t")
      local is_readme = filename == "README.md"
      if not is_readme then
        local name = vim.fn.fnamemodify(filepath, ":t:r")
        table.insert(files, {
          name = name,
          filepath = filepath,
          is_local = filepath:match("^" .. vim.fn.getcwd()) ~= nil
        })
      end
    end
    return files
  end

  -- Docs section - Insert FIRST to appear LAST (above special entries)
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Scan for docs (*.md files in .claude/docs/)
  local local_docs = scan_directory(project_dir .. "/.claude/docs", "*.md")
  local global_docs = scan_directory(global_dir .. "/.claude/docs", "*.md")

  -- Merge docs (local overrides global)
  local all_docs = {}
  local doc_map = {}
  for _, doc in ipairs(global_docs) do
    all_docs[#all_docs + 1] = doc
    doc_map[doc.name] = true
  end
  for _, doc in ipairs(local_docs) do
    if not doc_map[doc.name] then
      all_docs[#all_docs + 1] = doc
    end
  end

  if #all_docs > 0 then
    table.sort(all_docs, function(a, b) return a.name < b.name end)

    -- Insert doc items FIRST
    for i, doc in ipairs(all_docs) do
      -- First doc (i=1) appears LAST visually, so it gets └─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

      table.insert(entries, {
        display = string.format(
          "%s%s %-38s %s",
          doc.is_local and "*" or " ",
          indent_char,
          doc.name,
          "Documentation"
        ),
        entry_type = "doc",
        name = doc.name,
        filepath = doc.filepath,
        is_local = doc.is_local,
        ordinal = "zzzz_doc_" .. doc.name
      })
    end

    -- Insert heading LAST (appears at TOP of section)
    table.insert(entries, {
      is_heading = true,
      name = "~~~docs_heading",
      display = string.format(
        "  %-40s %s",
        "[Docs]",
        "Integration guides"
      ),
      entry_type = "heading",
      ordinal = "docs"
    })
  end

  -- Lib section - Insert BEFORE Docs to appear AFTER Docs
  local local_lib = scan_directory(project_dir .. "/.claude/lib", "*.sh")
  local global_lib = scan_directory(global_dir .. "/.claude/lib", "*.sh")

  -- Merge lib utils (local overrides global)
  local all_lib = {}
  local lib_map = {}
  for _, lib in ipairs(global_lib) do
    all_lib[#all_lib + 1] = lib
    lib_map[lib.name] = true
  end
  for _, lib in ipairs(local_lib) do
    if not lib_map[lib.name] then
      all_lib[#all_lib + 1] = lib
    end
  end

  if #all_lib > 0 then
    table.sort(all_lib, function(a, b) return a.name < b.name end)

    -- Insert lib items FIRST
    for i, lib in ipairs(all_lib) do
      -- First lib (i=1) appears LAST visually, so it gets └─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

      table.insert(entries, {
        display = string.format(
          "%s%s %-38s %s",
          lib.is_local and "*" or " ",
          indent_char,
          lib.name,
          "Utility library"
        ),
        entry_type = "lib",
        name = lib.name,
        filepath = lib.filepath,
        is_local = lib.is_local,
        ordinal = "zzzz_lib_" .. lib.name
      })
    end

    -- Insert heading LAST (appears at TOP of section)
    table.insert(entries, {
      is_heading = true,
      name = "~~~lib_heading",
      display = string.format(
        "  %-40s %s",
        "[Lib]",
        "Utility libraries"
      ),
      entry_type = "heading",
      ordinal = "lib"
    })
  end

  -- Templates section - Insert BEFORE Lib to appear AFTER Lib
  local local_templates = scan_directory(project_dir .. "/.claude/templates", "*.yaml")
  local global_templates = scan_directory(global_dir .. "/.claude/templates", "*.yaml")

  -- Merge templates (local overrides global)
  local all_templates = {}
  local template_map = {}
  for _, tmpl in ipairs(global_templates) do
    all_templates[#all_templates + 1] = tmpl
    template_map[tmpl.name] = true
  end
  for _, tmpl in ipairs(local_templates) do
    if not template_map[tmpl.name] then
      all_templates[#all_templates + 1] = tmpl
    end
  end

  if #all_templates > 0 then
    table.sort(all_templates, function(a, b) return a.name < b.name end)

    -- Insert template items FIRST
    for i, tmpl in ipairs(all_templates) do
      -- First template (i=1) appears LAST visually, so it gets └─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

      table.insert(entries, {
        display = string.format(
          "%s%s %-38s %s",
          tmpl.is_local and "*" or " ",
          indent_char,
          tmpl.name,
          "Workflow template"
        ),
        entry_type = "template",
        name = tmpl.name,
        filepath = tmpl.filepath,
        is_local = tmpl.is_local,
        ordinal = "zzzz_template_" .. tmpl.name
      })
    end

    -- Insert heading LAST (appears at TOP of section)
    table.insert(entries, {
      is_heading = true,
      name = "~~~templates_heading",
      display = string.format(
        "  %-40s %s",
        "[Templates]",
        "Workflow templates"
      ),
      entry_type = "heading",
      ordinal = "templates"
    })
  end

  -- TTS files section - Insert BEFORE Templates to appear AFTER Templates
  local tts_files = structure.tts_files or {}
  if #tts_files > 0 then
    -- Sort TTS files by role (config, dispatcher, library) then name
    table.sort(tts_files, function(a, b)
      if a.role ~= b.role then
        -- Order: config, dispatcher, library
        local role_order = { config = 1, dispatcher = 2, library = 3 }
        return (role_order[a.role] or 99) < (role_order[b.role] or 99)
      end
      return a.name < b.name
    end)

    -- Insert TTS file items FIRST
    for _, file in ipairs(tts_files) do
      entries[#entries + 1] = {
        display = format_tts_file(file),
        entry_type = "tts_file",
        name = file.name,
        description = file.description,
        filepath = file.filepath,
        is_local = file.is_local,
        role = file.role,
        directory = file.directory,
        variables = file.variables,
        line_count = file.line_count,
        ordinal = "zzzz_tts_" .. file.name
      }
    end

    -- Insert heading LAST (appears at TOP of section with descending sort)
    table.insert(entries, {
      is_heading = true,
      name = "~~~tts_heading",
      display = string.format(
        "  %-40s %s",
        "[TTS Files]",
        "Text-to-speech system files"
      ),
      entry_type = "heading",
      ordinal = "tts"
    })
  end

  -- Standalone Agents section - Insert BEFORE Hooks to appear AFTER Hooks in display
  -- Identify agents not associated with any command
  local used_agents = {}
  for _, primary_data in pairs(structure.primary_commands) do
    local command_agents = get_agents_for_command(
      primary_data.command.name,
      structure.agent_dependencies or {},
      structure.agents or {}
    )
    for _, agent in ipairs(command_agents) do
      used_agents[agent.name] = true
    end
  end

  -- Find standalone agents (not used by any command)
  local standalone_agents = {}
  for _, agent in ipairs(structure.agents or {}) do
    if not used_agents[agent.name] then
      table.insert(standalone_agents, agent)
    end
  end

  -- Sort standalone agents alphabetically
  table.sort(standalone_agents, function(a, b)
    return a.name < b.name
  end)

  -- Add standalone agents section if any exist
  if #standalone_agents > 0 then
    -- Insert agent items FIRST
    for i, agent in ipairs(standalone_agents) do
      -- First agent (i=1) appears LAST visually, so it gets └─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

      table.insert(entries, {
        name = agent.name,
        display = format_agent(agent, indent_char),
        agent = agent,
        is_primary = true,
        entry_type = "agent",
        ordinal = "agent_" .. agent.name
      })
    end

    -- Insert heading LAST (appears at TOP of section)
    table.insert(entries, {
      is_heading = true,
      name = "~~~agents_heading",
      display = string.format(
        "  %-40s %s",
        "[Agents]",
        "Standalone AI agents"
      ),
      entry_type = "heading",
      ordinal = "agents"
    })
  end

  -- Hooks section - Insert BEFORE Standalone Agents to appear AFTER Agents in display
  local hook_events = structure.hook_events or {}
  local hooks = structure.hooks or {}

  if vim.tbl_count(hook_events) > 0 then
    -- Sort hook event names
    local sorted_event_names = {}
    for event_name, _ in pairs(hook_events) do
      table.insert(sorted_event_names, event_name)
    end
    table.sort(sorted_event_names)

    -- Insert hook events and their hooks FIRST
    for _, event_name in ipairs(sorted_event_names) do
      local event_hook_names = hook_events[event_name]

      -- Get full hook data for this event
      local event_hooks = {}
      for _, hook_name in ipairs(event_hook_names) do
        for _, hook in ipairs(hooks) do
          if hook.name == hook_name then
            table.insert(event_hooks, hook)
            break
          end
        end
      end

      -- Add individual hooks first
      -- With descending sort: first inserted = last displayed
      for i, hook in ipairs(event_hooks) do
        -- First hook (i=1) appears LAST visually, so it gets └─
        local is_first = (i == 1)
        local indent_char = is_first and "└─" or "├─"

        table.insert(entries, {
          name = hook.name,
          display = format_hook(hook, indent_char),
          hook = hook,
          is_primary = false,
          parent = event_name,
          entry_type = "hook"
        })
      end

      -- Add hook event header after hooks
      table.insert(entries, {
        name = event_name,
        display = format_hook_event(event_name),
        is_primary = true,
        entry_type = "hook_event",
        hooks = event_hooks
      })
    end

    -- Insert [Hook Events] heading LAST (appears at TOP of section with descending sort)
    table.insert(entries, {
      is_heading = true,
      name = "~~~hooks_heading",
      display = string.format(
        "  %-40s %s",
        "[Hook Events]",
        "Event-triggered scripts"
      ),
      entry_type = "heading",
      ordinal = "hooks"
    })
  end

  -- Commands section - Insert LAST to appear at TOP with descending sort
  -- Collect and sort primary command names alphabetically
  local sorted_primary_names = {}
  for primary_name, _ in pairs(structure.primary_commands) do
    table.insert(sorted_primary_names, primary_name)
  end
  table.sort(sorted_primary_names)

  -- Add primary commands with their dependents AND agents
  for _, primary_name in ipairs(sorted_primary_names) do
    local primary_data = structure.primary_commands[primary_name]
    local primary_command = primary_data.command

    -- Get agents for this command
    local command_agents = get_agents_for_command(
      primary_name,
      structure.agent_dependencies or {},
      structure.agents or {}
    )

    -- Calculate total items (dependents + agents)
    local dependents = primary_data.dependents
    local total_items = #dependents + #command_agents

    -- Add dependent commands first
    -- With descending display: first inserted = last displayed (bottom)
    for i, dependent in ipairs(dependents) do
      -- Dependents are inserted FIRST, so they appear at BOTTOM of tree
      -- First dependent (i=1) appears at absolute BOTTOM → always gets └─
      -- Later dependents (i>1) appear above first → get ├─
      local is_first = (i == 1)
      local indent_char = is_first and "└─" or "├─"

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
        parent = primary_name,
        entry_type = "command"
      })
    end

    -- Add agents for this command (sorted alphabetically ascending)
    -- With descending display: first inserted (i=1) appears at BOTTOM
    for i, agent in ipairs(command_agents) do
      -- First agent (i==1) appears at BOTTOM
      -- If there are dependents, first agent is NOT the last item overall
      -- First agent (i=1) + no dependents → gets └─
      -- First agent (i=1) + has dependents → gets ├─ (dependents appear below)
      -- Later agents (i>1) → get ├─ (more items below)
      local is_first = (i == 1)
      local is_last_item = (is_first and #dependents == 0)
      local indent_char = is_last_item and "└─" or "├─"

      table.insert(entries, {
        name = agent.name,
        display = format_agent(agent, indent_char),
        agent = agent,
        is_primary = false,
        parent = primary_name,
        entry_type = "agent"
      })
    end

    -- Add primary command after dependents and agents
    local display_name = primary_command.is_local and ("* " .. primary_name) or ("  " .. primary_name)
    table.insert(entries, {
      name = primary_name,
      display = string.format(
        "%-42s %s",
        display_name,
        primary_command.description or ""
      ),
      command = primary_command,
      is_primary = true,
      entry_type = "command"
    })
  end

  -- Insert [Commands] heading LAST (appears at very TOP with descending sort)
  table.insert(entries, {
    is_heading = true,
    name = "~~~commands_heading",
    display = string.format(
      "  %-40s %s",
      "[Commands]",
      "Claude Code slash commands"
    ),
    entry_type = "heading",
    ordinal = "commands"
  })

  return entries
end

--- Get file permissions in rwx format
--- @param filepath string Path to file
--- @return string|nil Permissions string or nil if file doesn't exist
local function get_file_permissions(filepath)
  local perms = vim.fn.getfperm(filepath)
  if perms == "" then return nil end
  return perms  -- Returns: rwxr-xr-x format
end

--- Scan directory for files to sync
--- @param global_dir string Global base directory
--- @param local_dir string Local base directory
--- @param subdir string Subdirectory to scan (e.g., "commands", "hooks")
--- @param extension string File extension pattern (e.g., "*.md", "*.sh")
--- @return table files List of file sync info {name, global_path, local_path, action}
local function scan_directory_for_sync(global_dir, local_dir, subdir, extension)
  local global_path = global_dir .. "/.claude/" .. subdir
  local local_path = local_dir .. "/.claude/" .. subdir
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
      action = action
    })
  end

  return files
end

--- Sync files from global to local directory
--- @param files table List of file sync info
--- @param preserve_perms boolean Preserve execute permissions for shell scripts
--- @return number success_count Number of successfully synced files
local function sync_files(files, preserve_perms)
  local success_count = 0
  local notify = require('neotex.util.notifications')

  for _, file in ipairs(files) do
    -- Read global file
    local success, content = pcall(vim.fn.readfile, file.global_path)
    if success then
      -- Write to local
      local write_success = pcall(vim.fn.writefile, content, file.local_path)
      if write_success then
        -- Preserve permissions for shell scripts
        if preserve_perms and file.name:match("%.sh$") then
          local perms = vim.fn.getfperm(file.global_path)
          if perms ~= "" then
            vim.fn.setfperm(file.local_path, perms)
          end
        end
        success_count = success_count + 1
      else
        notify.editor(
          string.format("Failed to write file: %s", file.name),
          notify.categories.ERROR
        )
      end
    else
      notify.editor(
        string.format("Failed to read global file: %s", file.name),
        notify.categories.ERROR
      )
    end
  end

  return success_count
end

--- Create custom previewer for command documentation
--- @return table Telescope previewer
local function create_command_previewer()
  return previewers.new_buffer_previewer({
    title = "Command Details",
    define_preview = function(self, entry, status)
      -- Show info for heading entries
      if entry.value.is_heading then
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
          local MAX_PREVIEW_LINES = 150
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

            -- Display README content with markdown highlighting
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
            return
          end
        end

        -- Fallback to current generic text
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "Category: " .. ordinal,
          "",
          entry.value.display or "",
          "",
          "This is a category heading to organize artifacts in the picker.",
          "Navigate past this entry to view items in this category."
        })
        return
      end

      -- Show help for keyboard shortcuts entry
      if entry.value.is_help then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "Keyboard Shortcuts:",
          "",
          "Commands:",
          "  Enter (CR)  - Insert command into Claude Code terminal",
          "  Ctrl-n      - Create new command (opens Claude Code with prompt)",
          "  Ctrl-l      - Load artifact locally (copies with dependencies)",
          "  Ctrl-u      - Update artifact from global version (overwrites local)",
          "  Ctrl-s      - Save local artifact to global (share across projects)",
          "  Ctrl-e      - Edit artifact file (loads locally first if needed)",
          "",
          "Navigation:",
          "  Ctrl-j/k    - Move selection down/up",
          "  Ctrl-d      - Scroll preview down",
          "  Escape      - Close picker",
          "",
          "Artifact Types:",
          "  Commands    - Claude Code slash commands",
          "    Primary   - Main workflow commands",
          "    ├─ dependent - Supporting commands called by primary",
          "    └─ [agent]   - Agents used by this command",
          "",
          "  Agents      - Custom AI agent definitions",
          "    Shown under commands that use them",
          "",
          "  Hook Events - Event triggers for hooks",
          "    ├─ hook.sh - Shell scripts registered for this event",
          "",
          "  TTS Files   - Text-to-speech system files",
          "    [config]    - Configuration",
          "    [dispatcher] - Event router",
          "    [library]   - Message generator",
          "",
          "Indicators:",
          "  *  - Artifact defined locally in project (.claude/)",
          "       Local artifacts override global ones from .config/",
          "  (no *) - Global artifact from ~/.config/.claude/",
          "",
          "File Operations (Ctrl-l/u/s/e):",
          "  Work for: Commands, Agents, Hooks, TTS Files",
          "  Preserves executable permissions for .sh files",
          "",
          "  [Load All] - Batch synchronizes all artifact types",
          "               Commands, agents, hooks, and TTS files",
          "               (preserves local-only artifacts)",
          "",
          "Note: All artifacts loaded from both project and .config directories"
        })
        return
      end

      -- Show info for load all artifacts entry
      if entry.value.is_load_all then
        local project_dir = vim.fn.getcwd()
        local global_dir = vim.fn.expand("~/.config")

        -- Scan all artifact types (same logic as load_all_globally)
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
        local settings = scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")

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

        -- Count operations by action type
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
        table.insert(lines, string.format("  Global directory:  ~/.config/.claude/"))
        table.insert(lines, "")
        table.insert(lines, "Press Enter to proceed with confirmation, or Escape to cancel.")

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        return
      end

      -- Show agent preview
      if entry.value.entry_type == "agent" then
        local agent = entry.value.agent
        if agent then
          local lines = {
            "# Agent: " .. agent.name,
            "",
            "**Description**: " .. (agent.description or "N/A"),
            "",
            "**Allowed Tools**: " .. (agent.allowed_tools and #agent.allowed_tools > 0
              and table.concat(agent.allowed_tools, ", ") or "N/A"),
            "",
            "**Used By Commands**: " .. (entry.value.parent or "N/A"),
            "",
            "**File**: " .. agent.filepath,
            "",
            agent.is_local and "[Local] Local override" or "[Global] Global definition"
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
        return
      end

      -- Show hook preview
      if entry.value.entry_type == "hook" then
        local hook = entry.value.hook
        if hook then
          local lines = {
            "# Hook: " .. hook.name,
            "",
            "**Description**: " .. (hook.description or "N/A"),
            "",
            "**Triggered By Events**: " .. (entry.value.parent or "N/A"),
            "",
            "**Script**: " .. hook.filepath,
            "",
            "**Permissions**: " .. (get_file_permissions(hook.filepath) or "N/A"),
            "",
            hook.is_local and "[Local] Local override" or "[Global] Global definition"
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
        return
      end

      -- Show hook event preview
      if entry.value.entry_type == "hook_event" then
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
          table.insert(lines, "- " .. hook.name)
        end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        return
      end

      -- Show TTS config preview
      if entry.value.entry_type == "tts_file" then
        local tts = entry.value
        if tts then
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
            "**File**: " .. tts.filepath,
            "",
            tts.is_local and "[Local] Local override" or "[Global] Global configuration"
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
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

--- Load all global artifacts (commands, agents, hooks, TTS files, templates, lib, docs) locally
--- Scans global directory, copies new artifacts, and replaces existing local artifacts
--- with global versions. Preserves local-only artifacts without global equivalents.
--- @return number count Total number of artifacts loaded or updated
local function load_all_globally()
  local notify = require('neotex.util.notifications')

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    notify.editor(
      "Already in the global directory",
      notify.categories.STATUS
    )
    return 0
  end

  -- Scan all artifact types
  local commands = scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
  local agents = scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
  local hooks = scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")

  -- Scan TTS files from 2 directories
  local tts_hooks = scan_directory_for_sync(global_dir, project_dir, "hooks", "tts-*.sh")
  local tts_files = scan_directory_for_sync(global_dir, project_dir, "tts", "*.sh")

  -- Scan templates, lib utilities, and docs
  local templates = scan_directory_for_sync(global_dir, project_dir, "templates", "*.yaml")
  local lib_utils = scan_directory_for_sync(global_dir, project_dir, "lib", "*.sh")
  local docs = scan_directory_for_sync(global_dir, project_dir, "docs", "*.md")

  -- Scan README files for all directories
  local hooks_readme = scan_directory_for_sync(global_dir, project_dir, "hooks", "README.md")
  local tts_readme = scan_directory_for_sync(global_dir, project_dir, "tts", "README.md")
  local templates_readme = scan_directory_for_sync(global_dir, project_dir, "templates", "README.md")
  local lib_readme = scan_directory_for_sync(global_dir, project_dir, "lib", "README.md")
  local agents_prompts_readme = scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "README.md")
  local agents_shared_readme = scan_directory_for_sync(global_dir, project_dir, "agents/shared", "README.md")

  -- Scan agent protocols and standards
  local agents_prompts = scan_directory_for_sync(global_dir, project_dir, "agents/prompts", "*.md")
  local agents_shared = scan_directory_for_sync(global_dir, project_dir, "agents/shared", "*.md")
  local standards = scan_directory_for_sync(global_dir, project_dir, "specs/standards", "*.md")

  -- Scan data runtime documentation
  local data_commands_readme = scan_directory_for_sync(global_dir, project_dir, "data/commands", "README.md")
  local data_agents_readme = scan_directory_for_sync(global_dir, project_dir, "data/agents", "README.md")
  local data_templates_readme = scan_directory_for_sync(global_dir, project_dir, "data/templates", "README.md")

  -- Scan settings file
  local settings = scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")

  -- Merge TTS files
  local all_tts = {}
  for _, file in ipairs(tts_hooks) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_files) do
    table.insert(all_tts, file)
  end
  for _, file in ipairs(tts_readme) do
    table.insert(all_tts, file)
  end

  -- Merge README files into their respective arrays
  for _, file in ipairs(hooks_readme) do
    table.insert(hooks, file)
  end
  for _, file in ipairs(templates_readme) do
    table.insert(templates, file)
  end
  for _, file in ipairs(lib_readme) do
    table.insert(lib_utils, file)
  end
  for _, file in ipairs(agents_prompts_readme) do
    table.insert(agents_prompts, file)
  end
  for _, file in ipairs(agents_shared_readme) do
    table.insert(agents_shared, file)
  end

  -- Merge agent protocols
  local all_agent_protocols = {}
  for _, file in ipairs(agents_prompts) do
    table.insert(all_agent_protocols, file)
  end
  for _, file in ipairs(agents_shared) do
    table.insert(all_agent_protocols, file)
  end

  -- Merge data READMEs
  local all_data_docs = {}
  for _, file in ipairs(data_commands_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_agents_readme) do
    table.insert(all_data_docs, file)
  end
  for _, file in ipairs(data_templates_readme) do
    table.insert(all_data_docs, file)
  end

  -- Check if any artifacts found
  local total_files = #commands + #agents + #hooks + #all_tts + #templates + #lib_utils + #docs +
                      #all_agent_protocols + #standards + #all_data_docs + #settings
  if total_files == 0 then
    notify.editor(
      "No global artifacts found in ~/.config/.claude/",
      notify.categories.WARNING
    )
    return 0
  end

  -- Count operations by action type
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

  local cmd_copy, cmd_replace = count_actions(commands)
  local agt_copy, agt_replace = count_actions(agents)
  local hook_copy, hook_replace = count_actions(hooks)
  local tts_copy, tts_replace = count_actions(all_tts)
  local tmpl_copy, tmpl_replace = count_actions(templates)
  local lib_copy, lib_replace = count_actions(lib_utils)
  local doc_copy, doc_replace = count_actions(docs)
  local proto_copy, proto_replace = count_actions(all_agent_protocols)
  local std_copy, std_replace = count_actions(standards)
  local data_copy, data_replace = count_actions(all_data_docs)
  local set_copy, set_replace = count_actions(settings)

  local total_copy = cmd_copy + agt_copy + hook_copy + tts_copy + tmpl_copy + lib_copy + doc_copy +
                     proto_copy + std_copy + data_copy + set_copy
  local total_replace = cmd_replace + agt_replace + hook_replace + tts_replace + tmpl_replace + lib_replace +
                        doc_replace + proto_replace + std_replace + data_replace + set_replace

  -- Skip if no operations needed
  if total_copy + total_replace == 0 then
    notify.editor(
      "All artifacts already in sync",
      notify.categories.STATUS
    )
    return 0
  end

  -- Show confirmation dialog with detailed breakdown
  local message = string.format(
    "Load all artifacts from global directory?\n\n" ..
    "Commands: %d new, %d replace\n" ..
    "Agents: %d new, %d replace\n" ..
    "Hooks: %d new, %d replace\n" ..
    "TTS Files: %d new, %d replace\n" ..
    "Templates: %d new, %d replace\n" ..
    "Lib Utils: %d new, %d replace\n" ..
    "Docs: %d new, %d replace\n" ..
    "Agent Protocols: %d new, %d replace\n" ..
    "Standards: %d new, %d replace\n" ..
    "Data Docs: %d new, %d replace\n" ..
    "Settings: %d new, %d replace\n\n" ..
    "Total: %d new, %d replace\n\n" ..
    "Local-only artifacts will not be affected.",
    cmd_copy, cmd_replace,
    agt_copy, agt_replace,
    hook_copy, hook_replace,
    tts_copy, tts_replace,
    tmpl_copy, tmpl_replace,
    lib_copy, lib_replace,
    doc_copy, doc_replace,
    proto_copy, proto_replace,
    std_copy, std_replace,
    data_copy, data_replace,
    set_copy, set_replace,
    total_copy, total_replace
  )

  local choice = vim.fn.confirm(message, "&Yes\n&No", 2)  -- Default to No
  if choice ~= 1 then
    notify.editor(
      "Load all artifacts cancelled",
      notify.categories.STATUS
    )
    return 0
  end

  -- Create local directories if needed
  vim.fn.mkdir(project_dir .. "/.claude/commands", "p")
  vim.fn.mkdir(project_dir .. "/.claude/agents", "p")
  vim.fn.mkdir(project_dir .. "/.claude/agents/prompts", "p")
  vim.fn.mkdir(project_dir .. "/.claude/agents/shared", "p")
  vim.fn.mkdir(project_dir .. "/.claude/hooks", "p")
  vim.fn.mkdir(project_dir .. "/.claude/tts", "p")
  vim.fn.mkdir(project_dir .. "/.claude/templates", "p")
  vim.fn.mkdir(project_dir .. "/.claude/lib", "p")
  vim.fn.mkdir(project_dir .. "/.claude/docs", "p")
  vim.fn.mkdir(project_dir .. "/.claude/specs/standards", "p")
  vim.fn.mkdir(project_dir .. "/.claude/data/commands", "p")
  vim.fn.mkdir(project_dir .. "/.claude/data/agents", "p")
  vim.fn.mkdir(project_dir .. "/.claude/data/templates", "p")
  vim.fn.mkdir(project_dir .. "/.claude", "p")  -- For settings.local.json

  -- Sync all artifact types
  local cmd_count = sync_files(commands, false)
  local agt_count = sync_files(agents, false)
  local hook_count = sync_files(hooks, true)  -- Preserve permissions for shell scripts
  local tts_count = sync_files(all_tts, true)  -- Preserve permissions for TTS scripts
  local tmpl_count = sync_files(templates, false)
  local lib_count = sync_files(lib_utils, true)  -- Preserve permissions for utilities
  local doc_count = sync_files(docs, false)
  local proto_count = sync_files(all_agent_protocols, false)
  local std_count = sync_files(standards, false)
  local data_count = sync_files(all_data_docs, false)
  local set_count = sync_files(settings, false)

  local total_synced = cmd_count + agt_count + hook_count + tts_count + tmpl_count + lib_count + doc_count +
                       proto_count + std_count + data_count + set_count

  -- Report results
  if total_synced > 0 then
    notify.editor(
      string.format(
        "Synced %d artifacts: %d commands, %d agents, %d hooks, %d TTS, %d templates, %d lib, %d docs, " ..
        "%d protocols, %d standards, %d data, %d settings",
        total_synced, cmd_count, agt_count, hook_count, tts_count, tmpl_count, lib_count, doc_count,
        proto_count, std_count, data_count, set_count
      ),
      notify.categories.SUCCESS
    )
  end

  return total_synced
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

--- Load agent locally from global
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_agent_locally(agent, silent)
  local notify = require('neotex.util.notifications')

  if agent.is_local then
    if not silent then
      notify.editor(
        "Agent already local: " .. agent.name,
        notify.categories.STATUS
      )
    end
    return false
  end

  local dest = vim.fn.getcwd() .. "/.claude/agents/" .. agent.name .. ".md"
  local src = agent.filepath

  -- Create directory if needed
  vim.fn.mkdir(vim.fn.getcwd() .. "/.claude/agents", "p")

  -- Copy file
  local success, content = pcall(vim.fn.readfile, src)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read agent file: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, dest)
  if write_success then
    if not silent then
      notify.editor(
        "Loaded agent locally: " .. agent.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to load agent: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Load hook locally from global (preserves permissions)
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_hook_locally(hook, silent)
  local notify = require('neotex.util.notifications')

  if hook.is_local then
    if not silent then
      notify.editor(
        "Hook already local: " .. hook.name,
        notify.categories.STATUS
      )
    end
    return false
  end

  local dest = vim.fn.getcwd() .. "/.claude/hooks/" .. hook.name
  local src = hook.filepath

  -- Create directory
  vim.fn.mkdir(vim.fn.getcwd() .. "/.claude/hooks", "p")

  -- Get source permissions BEFORE copying
  local perms = vim.fn.getfperm(src)

  -- Copy file
  local success, content = pcall(vim.fn.readfile, src)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read hook file: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, dest)
  if write_success then
    -- Restore permissions (critical for hooks!)
    vim.fn.setfperm(dest, perms)

    if not silent then
      notify.editor(
        "Loaded hook locally: " .. hook.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to load hook: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Load TTS file locally from global (preserves permissions)
--- @param tts_file table TTS file data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_tts_file_locally(tts_file, silent)
  local notify = require('neotex.util.notifications')

  if tts_file.is_local then
    if not silent then
      notify.editor(
        "TTS file already local: " .. tts_file.name,
        notify.categories.STATUS
      )
    end
    return false
  end

  local dest = vim.fn.getcwd() .. "/.claude/" .. tts_file.directory .. "/" .. tts_file.name
  local src = tts_file.filepath

  -- Create directory
  vim.fn.mkdir(vim.fn.getcwd() .. "/.claude/" .. tts_file.directory, "p")

  -- Get source permissions BEFORE copying
  local perms = vim.fn.getfperm(src)

  -- Copy file
  local success, content = pcall(vim.fn.readfile, src)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, dest)
  if write_success then
    -- Restore permissions (critical for shell scripts!)
    vim.fn.setfperm(dest, perms)

    if not silent then
      notify.editor(
        "Loaded TTS file locally: " .. tts_file.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to load TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Update agent from global version
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_agent_from_global(agent, silent)
  local notify = require('neotex.util.notifications')

  local local_path = vim.fn.getcwd() .. "/.claude/agents/" .. agent.name .. ".md"
  local global_path = vim.fn.expand("~/.config/.claude/agents/" .. agent.name .. ".md")

  if vim.fn.filereadable(global_path) ~= 1 then
    if not silent then
      notify.editor(
        "No global version of agent: " .. agent.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  -- Overwrite local with global
  local success, content = pcall(vim.fn.readfile, global_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read global agent: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, local_path)
  if write_success then
    if not silent then
      notify.editor(
        "Updated agent from global: " .. agent.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to update agent: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Update hook from global version (preserves permissions)
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_hook_from_global(hook, silent)
  local notify = require('neotex.util.notifications')

  local local_path = vim.fn.getcwd() .. "/.claude/hooks/" .. hook.name
  local global_path = vim.fn.expand("~/.config/.claude/hooks/" .. hook.name)

  if vim.fn.filereadable(global_path) ~= 1 then
    if not silent then
      notify.editor(
        "No global version of hook: " .. hook.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  -- Get source permissions
  local perms = vim.fn.getfperm(global_path)

  -- Overwrite local with global
  local success, content = pcall(vim.fn.readfile, global_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read global hook: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, local_path)
  if write_success then
    -- Restore permissions
    vim.fn.setfperm(local_path, perms)

    if not silent then
      notify.editor(
        "Updated hook from global: " .. hook.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to update hook: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Update TTS file from global version (preserves permissions)
--- @param tts_file table TTS file data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_tts_file_from_global(tts_file, silent)
  local notify = require('neotex.util.notifications')

  local local_path = vim.fn.getcwd() .. "/.claude/" .. tts_file.directory .. "/" .. tts_file.name
  local global_path = vim.fn.expand("~/.config/.claude/" .. tts_file.directory .. "/" .. tts_file.name)

  if vim.fn.filereadable(global_path) ~= 1 then
    if not silent then
      notify.editor(
        "No global version of TTS file: " .. tts_file.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  -- Get source permissions
  local perms = vim.fn.getfperm(global_path)

  -- Overwrite local with global
  local success, content = pcall(vim.fn.readfile, global_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read global TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, local_path)
  if write_success then
    -- Restore permissions
    vim.fn.setfperm(local_path, perms)

    if not silent then
      notify.editor(
        "Updated TTS file from global: " .. tts_file.name,
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to update TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Save agent to global directory
--- @param agent table Agent data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_agent_to_global(agent, silent)
  local notify = require('neotex.util.notifications')

  if not agent.is_local then
    if not silent then
      notify.editor(
        "Agent is not local: " .. agent.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  local local_path = vim.fn.getcwd() .. "/.claude/agents/" .. agent.name .. ".md"
  local global_path = vim.fn.expand("~/.config/.claude/agents/" .. agent.name .. ".md")

  -- Create global directory if needed
  vim.fn.mkdir(vim.fn.expand("~/.config/.claude/agents"), "p")

  -- Copy local to global
  local success, content = pcall(vim.fn.readfile, local_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read local agent: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, global_path)
  if write_success then
    if not silent then
      notify.editor(
        "Saved agent to global: " .. agent.name,
        notify.categories.USER_ACTION
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to save agent: " .. agent.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Save hook to global directory (preserves permissions)
--- @param hook table Hook data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_hook_to_global(hook, silent)
  local notify = require('neotex.util.notifications')

  if not hook.is_local then
    if not silent then
      notify.editor(
        "Hook is not local: " .. hook.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  local local_path = vim.fn.getcwd() .. "/.claude/hooks/" .. hook.name
  local global_path = vim.fn.expand("~/.config/.claude/hooks/" .. hook.name)

  -- Get local permissions
  local perms = vim.fn.getfperm(local_path)

  -- Create global directory if needed
  vim.fn.mkdir(vim.fn.expand("~/.config/.claude/hooks"), "p")

  -- Copy local to global
  local success, content = pcall(vim.fn.readfile, local_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read local hook: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, global_path)
  if write_success then
    -- Preserve permissions
    vim.fn.setfperm(global_path, perms)

    if not silent then
      notify.editor(
        "Saved hook to global: " .. hook.name,
        notify.categories.USER_ACTION
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to save hook: " .. hook.name,
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Save TTS file to global directory (preserves permissions)
--- @param tts_file table TTS file data
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_tts_file_to_global(tts_file, silent)
  local notify = require('neotex.util.notifications')

  if not tts_file.is_local then
    if not silent then
      notify.editor(
        "TTS file is not local: " .. tts_file.name,
        notify.categories.WARNING
      )
    end
    return false
  end

  local local_path = vim.fn.getcwd() .. "/.claude/" .. tts_file.directory .. "/" .. tts_file.name
  local global_path = vim.fn.expand("~/.config/.claude/" .. tts_file.directory .. "/" .. tts_file.name)

  -- Get local permissions
  local perms = vim.fn.getfperm(local_path)

  -- Create global directory if needed
  vim.fn.mkdir(vim.fn.expand("~/.config/.claude/" .. tts_file.directory), "p")

  -- Copy local to global
  local success, content = pcall(vim.fn.readfile, local_path)
  if not success then
    if not silent then
      notify.editor(
        "Failed to read local TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, global_path)
  if write_success then
    -- Preserve permissions
    vim.fn.setfperm(global_path, perms)

    if not silent then
      notify.editor(
        "Saved TTS file to global: " .. tts_file.name,
        notify.categories.USER_ACTION
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        "Failed to save TTS file: " .. tts_file.name,
        notify.categories.ERROR
      )
    end
    return false
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

--- Load generic artifact (template, lib, doc) locally
--- @param entry table Entry data with filepath, name, is_local
--- @param entry_type string Type of entry (template, lib, doc)
--- @param silent boolean Don't show notifications
--- @return boolean success
local function load_artifact_locally(entry, entry_type, silent)
  local notify = require('neotex.util.notifications')

  if entry.is_local then
    if not silent then
      notify.editor(
        string.format("%s already local: %s", entry_type, entry.name),
        notify.categories.STATUS
      )
    end
    return false
  end

  -- Determine directory based on type
  local dir_map = {
    template = "templates",
    lib = "lib",
    doc = "docs"
  }
  local subdir = dir_map[entry_type] or entry_type

  local dest = vim.fn.getcwd() .. "/.claude/" .. subdir .. "/" .. vim.fn.fnamemodify(entry.filepath, ":t")
  local src = entry.filepath

  -- Create directory if needed
  vim.fn.mkdir(vim.fn.getcwd() .. "/.claude/" .. subdir, "p")

  -- Get source permissions BEFORE copying (for .sh files)
  local perms = vim.fn.getfperm(src)

  -- Copy file
  local success, content = pcall(vim.fn.readfile, src)
  if not success then
    if not silent then
      notify.editor(
        string.format("Failed to read %s file: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, dest)
  if write_success then
    -- Restore permissions for shell scripts
    if entry_type == "lib" and perms ~= "" then
      vim.fn.setfperm(dest, perms)
    end

    if not silent then
      notify.editor(
        string.format("Loaded %s locally: %s", entry_type, entry.name),
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        string.format("Failed to load %s: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Update generic artifact from global version
--- @param entry table Entry data
--- @param entry_type string Type of entry (template, lib, doc)
--- @param silent boolean Don't show notifications
--- @return boolean success
local function update_artifact_from_global(entry, entry_type, silent)
  local notify = require('neotex.util.notifications')

  local dir_map = {
    template = "templates",
    lib = "lib",
    doc = "docs"
  }
  local subdir = dir_map[entry_type] or entry_type

  local local_path = vim.fn.getcwd() .. "/.claude/" .. subdir .. "/" .. vim.fn.fnamemodify(entry.filepath, ":t")
  local global_path = vim.fn.expand("~/.config/.claude/" .. subdir .. "/" .. vim.fn.fnamemodify(entry.filepath, ":t"))

  if vim.fn.filereadable(global_path) ~= 1 then
    if not silent then
      notify.editor(
        string.format("No global version of %s: %s", entry_type, entry.name),
        notify.categories.WARNING
      )
    end
    return false
  end

  -- Get source permissions
  local perms = vim.fn.getfperm(global_path)

  -- Overwrite local with global
  local success, content = pcall(vim.fn.readfile, global_path)
  if not success then
    if not silent then
      notify.editor(
        string.format("Failed to read global %s: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, local_path)
  if write_success then
    -- Restore permissions for shell scripts
    if entry_type == "lib" and perms ~= "" then
      vim.fn.setfperm(local_path, perms)
    end

    if not silent then
      notify.editor(
        string.format("Updated %s from global: %s", entry_type, entry.name),
        notify.categories.SUCCESS
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        string.format("Failed to update %s: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Save generic artifact to global directory
--- @param entry table Entry data
--- @param entry_type string Type of entry (template, lib, doc)
--- @param silent boolean Don't show notifications
--- @return boolean success
local function save_artifact_to_global(entry, entry_type, silent)
  local notify = require('neotex.util.notifications')

  if not entry.is_local then
    if not silent then
      notify.editor(
        string.format("%s is not local: %s", entry_type, entry.name),
        notify.categories.WARNING
      )
    end
    return false
  end

  local dir_map = {
    template = "templates",
    lib = "lib",
    doc = "docs"
  }
  local subdir = dir_map[entry_type] or entry_type

  local local_path = vim.fn.getcwd() .. "/.claude/" .. subdir .. "/" .. vim.fn.fnamemodify(entry.filepath, ":t")
  local global_path = vim.fn.expand("~/.config/.claude/" .. subdir .. "/" .. vim.fn.fnamemodify(entry.filepath, ":t"))

  -- Get local permissions
  local perms = vim.fn.getfperm(local_path)

  -- Create global directory if needed
  vim.fn.mkdir(vim.fn.expand("~/.config/.claude/" .. subdir), "p")

  -- Copy local to global
  local success, content = pcall(vim.fn.readfile, local_path)
  if not success then
    if not silent then
      notify.editor(
        string.format("Failed to read local %s: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end

  local write_success = pcall(vim.fn.writefile, content, global_path)
  if write_success then
    -- Preserve permissions for shell scripts
    if entry_type == "lib" and perms ~= "" then
      vim.fn.setfperm(global_path, perms)
    end

    if not silent then
      notify.editor(
        string.format("Saved %s to global: %s", entry_type, entry.name),
        notify.categories.USER_ACTION
      )
    end
    return true
  else
    if not silent then
      notify.editor(
        string.format("Failed to save %s: %s", entry_type, entry.name),
        notify.categories.ERROR
      )
    end
    return false
  end
end

--- Main function to show Claude commands picker
--- @param opts table Options (optional)
function M.show_commands_picker(opts)
  opts = opts or {}
  local notify = require('neotex.util.notifications')

  -- Get extended structure (commands + agents + hooks)
  local structure = parser.get_extended_structure()

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
        -- Handle entries that may not have a name field (like section headers)
        local name = entry.name or entry.ordinal or ""
        local description = entry.command and entry.command.description or entry.description or ""

        return {
          value = entry,
          display = entry.display,
          ordinal = name .. " " .. description,
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
          -- Skip heading entries
          if selection.value.is_heading then
            return
          end

          -- Handle Load All Commands action
          if selection.value.is_load_all then
            local loaded = load_all_globally()
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

      -- Load artifact locally with Ctrl-l (keeps picker open and refreshes)
      map("i", "<C-l>", function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_help or selection.value.is_load_all or selection.value.is_heading then
          return
        end

        local success = false
        if selection.value.command then
          success = load_command_locally(selection.value.command, false)
        elseif selection.value.agent then
          success = load_agent_locally(selection.value.agent, false)
        elseif selection.value.hook then
          success = load_hook_locally(selection.value.hook, false)
        elseif selection.value.entry_type == "tts_file" then
          success = load_tts_file_locally(selection.value, false)
        elseif selection.value.entry_type == "template" then
          success = load_artifact_locally(selection.value, "template", false)
        elseif selection.value.entry_type == "lib" then
          success = load_artifact_locally(selection.value, "lib", false)
        elseif selection.value.entry_type == "doc" then
          success = load_artifact_locally(selection.value, "doc", false)
        end

        -- Refresh the picker to show updated local status
        if success then
          local current_prompt = action_state.get_current_line()
          actions.close(prompt_bufnr)

          vim.defer_fn(function()
            M.show_commands_picker(opts)
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
        if selection and selection.value.command and not selection.value.is_help and not selection.value.is_heading then
          actions.close(prompt_bufnr)
          edit_command_file(selection.value.command)
        end
      end)

      -- Update artifact from global version with Ctrl-u (keeps picker open and refreshes)
      map("i", "<C-u>", function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_help or selection.value.is_load_all or selection.value.is_heading then
          return
        end

        local success = false
        if selection.value.command then
          success = update_command_from_global(selection.value.command, false)
        elseif selection.value.agent then
          success = update_agent_from_global(selection.value.agent, false)
        elseif selection.value.hook then
          success = update_hook_from_global(selection.value.hook, false)
        elseif selection.value.entry_type == "tts_file" then
          success = update_tts_file_from_global(selection.value, false)
        elseif selection.value.entry_type == "template" then
          success = update_artifact_from_global(selection.value, "template", false)
        elseif selection.value.entry_type == "lib" then
          success = update_artifact_from_global(selection.value, "lib", false)
        elseif selection.value.entry_type == "doc" then
          success = update_artifact_from_global(selection.value, "doc", false)
        end

        if success then
          local current_prompt = action_state.get_current_line()
          actions.close(prompt_bufnr)

          vim.defer_fn(function()
            M.show_commands_picker(opts)
            if current_prompt and current_prompt ~= "" then
              vim.defer_fn(function()
                vim.api.nvim_feedkeys(current_prompt, 'n', false)
              end, 50)
            end
          end, 100)
        end
      end)

      -- Save local artifact to global with Ctrl-s (keeps picker open and refreshes)
      map("i", "<C-s>", function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_help or selection.value.is_load_all or selection.value.is_heading then
          return
        end

        local success = false
        if selection.value.command then
          success = save_command_to_global(selection.value.command, false)
        elseif selection.value.agent then
          success = save_agent_to_global(selection.value.agent, false)
        elseif selection.value.hook then
          success = save_hook_to_global(selection.value.hook, false)
        elseif selection.value.entry_type == "tts_file" then
          success = save_tts_file_to_global(selection.value, false)
        elseif selection.value.entry_type == "template" then
          success = save_artifact_to_global(selection.value, "template", false)
        elseif selection.value.entry_type == "lib" then
          success = save_artifact_to_global(selection.value, "lib", false)
        elseif selection.value.entry_type == "doc" then
          success = save_artifact_to_global(selection.value, "doc", false)
        end

        if success then
          local current_prompt = action_state.get_current_line()
          actions.close(prompt_bufnr)

          vim.defer_fn(function()
            M.show_commands_picker(opts)
            if current_prompt and current_prompt ~= "" then
              vim.defer_fn(function()
                vim.api.nvim_feedkeys(current_prompt, 'n', false)
              end, 50)
            end
          end, 100)
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
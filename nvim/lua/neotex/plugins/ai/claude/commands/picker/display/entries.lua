-- neotex.plugins.ai.claude.commands.picker.display.entries
-- Entry creation for telescope picker with hierarchical display

local M = {}

-- Dependencies
local scan = require("neotex.plugins.ai.claude.commands.picker.utils.scan")
local metadata = require("neotex.plugins.ai.claude.commands.picker.artifacts.metadata")
local helpers = require("neotex.plugins.ai.claude.commands.picker.utils.helpers")

--- Format TTS file entry for display
--- @param file table TTS file data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_tts_file(file, indent_char)
  local prefix = file.is_local and "*" or " "
  local role_short = ({
    config = "[C]",
    dispatcher = "[D]",
    library = "[L]",
  })[file.role] or "[?]"

  return string.format(
    "%s %s %-38s %s %s",
    prefix,
    indent_char,
    file.name,
    role_short,
    file.description or ""
  )
end

--- Format agent entry for display
--- @param agent table Agent data
--- @param indent_char string Tree character (├─ or └─)
--- @return string Formatted display string
local function format_agent(agent, indent_char)
  local prefix = agent.is_local and "*" or " "

  -- Strip redundant "Specialized in " prefix if present
  local description = agent.description or ""
  description = description:gsub("^Specialized in ", "")

  return string.format(
    "%s %s %-38s %s",
    prefix,
    indent_char,
    agent.name,
    description
  )
end

--- Format hook event header for display
--- @param event_name string Hook event name
--- @param indent_char string Tree character (├─ or └─)
--- @param event_hooks table Array of hooks associated with this event
--- @return string Formatted display string
local function format_hook_event(event_name, indent_char, event_hooks)
  -- Determine if event has any local hooks
  local has_local_hook = false
  if event_hooks then
    for _, hook in ipairs(event_hooks) do
      if hook.is_local then
        has_local_hook = true
        break
      end
    end
  end

  local prefix = has_local_hook and "*" or " "

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
    "%s  %s %-37s %s",
    prefix,
    indent_char,
    event_name,
    descriptions[event_name] or ""
  )
end

--- Format command entry for display
--- @param command table Command data
--- @param indent_char string Tree character
--- @param is_dependent boolean Whether this is a dependent command
--- @return string Formatted display string
local function format_command(command, indent_char, is_dependent)
  local prefix = command.is_local and "*" or " "
  local description = command.description or ""

  if is_dependent then
    return string.format(
      "%s   %s %-37s %s",
      prefix,
      indent_char,
      command.name,
      description
    )
  else
    return string.format(
      "%s %s %-38s %s",
      prefix,
      indent_char,
      command.name,
      description
    )
  end
end

--- Get agents for a specific command
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

  table.sort(command_agents, function(a, b)
    return a.name < b.name
  end)

  return command_agents
end

--- Create entries for docs section
--- @return table Array of entries
function M.create_docs_entries()
  local entries = {}
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  local local_docs = scan.scan_directory(project_dir .. "/.claude/docs", "*.md")
  local global_docs = scan.scan_directory(global_dir .. "/.claude/docs", "*.md")
  local all_docs = scan.merge_artifacts(local_docs, global_docs)

  if #all_docs > 0 then
    table.sort(all_docs, function(a, b) return a.name < b.name end)

    -- Insert doc items FIRST (appear last in descending sort)
    for i, doc in ipairs(all_docs) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)
      local description = metadata.parse_doc_description(doc.filepath)

      table.insert(entries, {
        display = helpers.format_display(
          doc.is_local and "*" or " ",
          " " .. indent_char,
          doc.name,
          description
        ),
        entry_type = "doc",
        name = doc.name,
        filepath = doc.filepath,
        is_local = doc.is_local,
        ordinal = "zzzz_doc_" .. doc.name
      })
    end

    -- Insert heading LAST (appears at TOP)
    table.insert(entries, {
      is_heading = true,
      name = "~~~docs_heading",
      display = string.format("%-40s %s", "[Docs]", "Integration guides"),
      entry_type = "heading",
      ordinal = "docs"
    })
  end

  return entries
end

--- Create entries for lib section
--- @return table Array of entries
function M.create_lib_entries()
  local entries = {}
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  local local_lib = scan.scan_directory(project_dir .. "/.claude/lib", "*.sh")
  local global_lib = scan.scan_directory(global_dir .. "/.claude/lib", "*.sh")
  local all_lib = scan.merge_artifacts(local_lib, global_lib)

  if #all_lib > 0 then
    table.sort(all_lib, function(a, b) return a.name < b.name end)

    for i, lib in ipairs(all_lib) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)
      local description = metadata.parse_script_description(lib.filepath)

      table.insert(entries, {
        display = helpers.format_display(
          lib.is_local and "*" or " ",
          " " .. indent_char,
          lib.name,
          description
        ),
        entry_type = "lib",
        name = lib.name,
        filepath = lib.filepath,
        is_local = lib.is_local,
        ordinal = "zzzz_lib_" .. lib.name
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~lib_heading",
      display = string.format("%-40s %s", "[Lib]", "Utility libraries"),
      entry_type = "heading",
      ordinal = "lib"
    })
  end

  return entries
end

--- Create entries for templates section
--- @return table Array of entries
function M.create_templates_entries()
  local entries = {}
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  local local_templates = scan.scan_directory(project_dir .. "/.claude/templates", "*.yaml")
  local global_templates = scan.scan_directory(global_dir .. "/.claude/templates", "*.yaml")
  local all_templates = scan.merge_artifacts(local_templates, global_templates)

  if #all_templates > 0 then
    table.sort(all_templates, function(a, b) return a.name < b.name end)

    for i, tmpl in ipairs(all_templates) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)
      local description = metadata.parse_template_description(tmpl.filepath)

      table.insert(entries, {
        display = helpers.format_display(
          tmpl.is_local and "*" or " ",
          " " .. indent_char,
          tmpl.name,
          description
        ),
        entry_type = "template",
        name = tmpl.name,
        filepath = tmpl.filepath,
        is_local = tmpl.is_local,
        ordinal = "zzzz_template_" .. tmpl.name
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~templates_heading",
      display = string.format("%-40s %s", "[Templates]", "Workflow templates"),
      entry_type = "heading",
      ordinal = "templates"
    })
  end

  return entries
end

--- Create entries for scripts section
--- @return table Array of entries
function M.create_scripts_entries()
  local entries = {}
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  local local_scripts = scan.scan_directory(project_dir .. "/.claude/scripts", "*.sh")
  local global_scripts = scan.scan_directory(global_dir .. "/.claude/scripts", "*.sh")
  local all_scripts = scan.merge_artifacts(local_scripts, global_scripts)

  if #all_scripts > 0 then
    table.sort(all_scripts, function(a, b) return a.name < b.name end)

    for i, script in ipairs(all_scripts) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)
      local description = metadata.parse_script_description(script.filepath)

      table.insert(entries, {
        display = helpers.format_display(
          script.is_local and "*" or " ",
          " " .. indent_char,
          script.name,
          description
        ),
        entry_type = "script",
        name = script.name,
        filepath = script.filepath,
        is_local = script.is_local,
        ordinal = "zzzz_script_" .. script.name
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~scripts_heading",
      display = string.format("%-40s %s", "[Scripts]", "Standalone CLI tools"),
      entry_type = "heading",
      ordinal = "scripts"
    })
  end

  return entries
end

--- Create entries for tests section
--- @return table Array of entries
function M.create_tests_entries()
  local entries = {}
  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  local local_tests = scan.scan_directory(project_dir .. "/.claude/tests", "test_*.sh")
  local global_tests = scan.scan_directory(global_dir .. "/.claude/tests", "test_*.sh")
  local all_tests = scan.merge_artifacts(local_tests, global_tests)

  if #all_tests > 0 then
    table.sort(all_tests, function(a, b) return a.name < b.name end)

    for i, test in ipairs(all_tests) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)
      local description = metadata.parse_script_description(test.filepath)

      table.insert(entries, {
        display = helpers.format_display(
          test.is_local and "*" or " ",
          " " .. indent_char,
          test.name,
          description
        ),
        entry_type = "test",
        name = test.name,
        filepath = test.filepath,
        is_local = test.is_local,
        ordinal = "zzzz_test_" .. test.name
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~tests_heading",
      display = string.format("%-40s %s", "[Tests]", "Test suites"),
      entry_type = "heading",
      ordinal = "tests"
    })
  end

  return entries
end

--- Create entries for TTS files section
--- @param tts_files table TTS files from parser
--- @return table Array of entries
function M.create_tts_entries(tts_files)
  local entries = {}

  if #tts_files > 0 then
    -- Sort TTS files by role (config, dispatcher, library) then name
    table.sort(tts_files, function(a, b)
      if a.role ~= b.role then
        local role_order = { config = 1, dispatcher = 2, library = 3 }
        return (role_order[a.role] or 99) < (role_order[b.role] or 99)
      end
      return a.name < b.name
    end)

    for i, file in ipairs(tts_files) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)

      entries[#entries + 1] = {
        display = format_tts_file(file, indent_char),
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

    table.insert(entries, {
      is_heading = true,
      name = "~~~tts_heading",
      display = string.format("%-40s %s", "[TTS Files]", "Text-to-speech system files"),
      entry_type = "heading",
      ordinal = "tts"
    })
  end

  return entries
end

--- Create entries for standalone agents section
--- @param structure table Extended structure from parser
--- @return table Array of entries
function M.create_standalone_agents_entries(structure)
  local entries = {}

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

  -- Find standalone agents
  local standalone_agents = {}
  for _, agent in ipairs(structure.agents or {}) do
    if not used_agents[agent.name] then
      table.insert(standalone_agents, agent)
    end
  end

  table.sort(standalone_agents, function(a, b)
    return a.name < b.name
  end)

  if #standalone_agents > 0 then
    for i, agent in ipairs(standalone_agents) do
      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)

      table.insert(entries, {
        name = agent.name,
        display = format_agent(agent, indent_char),
        agent = agent,
        is_primary = true,
        entry_type = "agent",
        ordinal = "agent_" .. agent.name
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~agents_heading",
      display = string.format("%-40s %s", "[Agents]", "Standalone AI agents"),
      entry_type = "heading",
      ordinal = "agents"
    })
  end

  return entries
end

--- Create entries for hooks section
--- @param structure table Extended structure from parser
--- @return table Array of entries
function M.create_hooks_entries(structure)
  local entries = {}
  local hook_events = structure.hook_events or {}
  local hooks = structure.hooks or {}

  if vim.tbl_count(hook_events) > 0 then
    local sorted_event_names = {}
    for event_name, _ in pairs(hook_events) do
      table.insert(sorted_event_names, event_name)
    end
    table.sort(sorted_event_names)

    for i, event_name in ipairs(sorted_event_names) do
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

      local is_first = (i == 1)
      local indent_char = helpers.get_tree_char(is_first)

      table.insert(entries, {
        name = event_name,
        display = format_hook_event(event_name, indent_char, event_hooks),
        is_primary = true,
        entry_type = "hook_event",
        hooks = event_hooks
      })
    end

    table.insert(entries, {
      is_heading = true,
      name = "~~~hooks_heading",
      display = string.format("%-40s %s", "[Hook Events]", "Event-triggered scripts"),
      entry_type = "heading",
      ordinal = "hooks"
    })
  end

  return entries
end

--- Create entries for commands section
--- @param structure table Extended structure from parser
--- @return table Array of entries
function M.create_commands_entries(structure)
  local entries = {}

  -- Collect and sort primary command names
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

    local dependents = primary_data.dependents
    local total_items = #dependents + #command_agents

    -- Insert agents FIRST (appear LAST in command tree)
    for i, agent in ipairs(command_agents) do
      local agent_position = #dependents + i
      local is_last = (agent_position == total_items)
      local tree_char = is_last and "└─" or "├─"

      table.insert(entries, {
        name = agent.name,
        display = format_agent(agent, tree_char),
        command = primary_command,
        agent = agent,
        is_primary = false,
        entry_type = "agent",
        ordinal = "command_" .. primary_name .. "_agent_" .. agent.name
      })
    end

    -- Insert dependents AFTER agents
    for i, dep in ipairs(dependents) do
      local is_last = (i == #dependents and #command_agents == 0)
      local tree_char = is_last and "└─" or "├─"

      table.insert(entries, {
        name = dep.name,
        display = format_command(dep, tree_char, true),
        command = dep,
        parent_command = primary_command,
        is_primary = false,
        entry_type = "command",
        ordinal = "command_" .. primary_name .. "_dep_" .. dep.name
      })
    end

    -- Insert primary command LAST (appears FIRST in tree)
    local has_children = total_items > 0
    local tree_char = has_children and "├─" or "└─"

    table.insert(entries, {
      name = primary_command.name,
      display = format_command(primary_command, tree_char, false),
      command = primary_command,
      is_primary = true,
      entry_type = "command",
      ordinal = "command_" .. primary_name
    })
  end

  -- Add [Commands] heading
  table.insert(entries, {
    is_heading = true,
    name = "~~~commands_heading",
    display = string.format("%-40s %s", "[Commands]", "Slash commands"),
    entry_type = "heading",
    ordinal = "commands"
  })

  return entries
end

--- Create special entries (help and load all)
--- @return table Array of entries
function M.create_special_entries()
  local entries = {}

  -- Load all artifacts entry (appears at bottom)
  table.insert(entries, {
    is_load_all = true,
    name = "~~~load_all",
    display = string.format(
      "%-40s %s",
      "[Load All Artifacts]",
      "Sync commands, agents, hooks, TTS files"
    ),
    command = nil,
    entry_type = "special"
  })

  -- Keyboard shortcuts help entry
  table.insert(entries, {
    is_help = true,
    name = "~~~help",
    display = string.format(
      "%-40s %s",
      "[Keyboard Shortcuts]",
      "Help"
    ),
    command = nil,
    entry_type = "special"
  })

  return entries
end

--- Create all picker entries from structure
--- Insertion order is REVERSED for descending sort: last inserted appears at TOP
--- @param structure table Extended structure from parser.get_extended_structure()
--- @return table Array of entries for telescope
function M.create_picker_entries(structure)
  local all_entries = {}

  -- Insert in reverse order (last inserted appears first with descending sort)

  -- 1. Special entries (appear at bottom)
  local special = M.create_special_entries()
  for _, entry in ipairs(special) do
    table.insert(all_entries, entry)
  end

  -- 2. Docs section
  local docs = M.create_docs_entries()
  for _, entry in ipairs(docs) do
    table.insert(all_entries, entry)
  end

  -- 3. Lib section
  local lib = M.create_lib_entries()
  for _, entry in ipairs(lib) do
    table.insert(all_entries, entry)
  end

  -- 4. Templates section
  local templates = M.create_templates_entries()
  for _, entry in ipairs(templates) do
    table.insert(all_entries, entry)
  end

  -- 5. Scripts section
  local scripts = M.create_scripts_entries()
  for _, entry in ipairs(scripts) do
    table.insert(all_entries, entry)
  end

  -- 6. Tests section
  local tests = M.create_tests_entries()
  for _, entry in ipairs(tests) do
    table.insert(all_entries, entry)
  end

  -- 7. TTS files section
  local tts = M.create_tts_entries(structure.tts_files or {})
  for _, entry in ipairs(tts) do
    table.insert(all_entries, entry)
  end

  -- 8. Standalone agents section
  local standalone_agents = M.create_standalone_agents_entries(structure)
  for _, entry in ipairs(standalone_agents) do
    table.insert(all_entries, entry)
  end

  -- 9. Hooks section
  local hooks = M.create_hooks_entries(structure)
  for _, entry in ipairs(hooks) do
    table.insert(all_entries, entry)
  end

  -- 10. Commands section (appears at top)
  local commands = M.create_commands_entries(structure)
  for _, entry in ipairs(commands) do
    table.insert(all_entries, entry)
  end

  return all_entries
end

return M

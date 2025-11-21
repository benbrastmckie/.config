-- neotex.plugins.ai.claude.commands.picker.artifacts.registry
-- Central registry of artifact types with metadata and formatting

local M = {}

-- Artifact type configurations
-- Each artifact type defines its scanning, display, and behavior characteristics
M.ARTIFACT_TYPES = {
  command = {
    name = "command",
    plural = "Commands",
    extension = ".md",
    subdirs = { "commands" },
    preserve_permissions = false,
    description_parser = "parse_command_description",
    heading = "[Commands]",
    heading_description = "Slash commands",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },

  agent = {
    name = "agent",
    plural = "Agents",
    extension = ".md",
    subdirs = { "agents" },
    preserve_permissions = false,
    description_parser = "parse_agent_description",
    heading = "[Agents]",
    heading_description = "AI assistants",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },

  hook_event = {
    name = "hook_event",
    plural = "Hook Events",
    extension = ".sh",
    subdirs = { "hooks" },
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[Hook Events]",
    heading_description = "Event-triggered scripts",
    tree_indent = "  ",  -- 2-space indent for hook events
    picker_visible = true,
    sync_enabled = true,
    -- Special: hooks are grouped by event name
    group_by_event = true,
  },

  tts_file = {
    name = "tts_file",
    plural = "TTS Files",
    extension = ".sh",
    subdirs = { "tts", "hooks" },  -- Multiple scan directories
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[TTS Files]",
    heading_description = "Text-to-speech scripts",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
    -- Special: filter for tts-*.sh pattern
    pattern_filter = "^tts%-",
  },

  template = {
    name = "template",
    plural = "Templates",
    extension = ".yaml",
    subdirs = { "templates" },
    preserve_permissions = false,
    description_parser = "parse_template_description",
    heading = "[Templates]",
    heading_description = "YAML templates",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },

  lib = {
    name = "lib",
    plural = "Lib Utilities",
    extension = ".sh",
    subdirs = { "lib" },
    preserve_permissions = true,
    description_parser = "parse_script_description",
    heading = "[Lib Utilities]",
    heading_description = "Shell libraries",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },

  doc = {
    name = "doc",
    plural = "Docs",
    extension = ".md",
    subdirs = { "docs" },
    preserve_permissions = false,
    description_parser = "parse_doc_description",
    heading = "[Docs]",
    heading_description = "Documentation files",
    tree_indent = " ",
    picker_visible = true,
    sync_enabled = true,
  },

  -- Artifact types used by sync but not displayed in picker
  agent_protocol = {
    name = "agent_protocol",
    plural = "Agent Protocols",
    extension = ".md",
    subdirs = { "agents" },
    preserve_permissions = false,
    description_parser = "parse_doc_description",
    heading = "[Agent Protocols]",
    heading_description = "Agent protocol files",
    tree_indent = " ",
    picker_visible = false,
    sync_enabled = true,
  },

  standard = {
    name = "standard",
    plural = "Standards",
    extension = ".md",
    subdirs = { "docs" },
    preserve_permissions = false,
    description_parser = "parse_doc_description",
    heading = "[Standards]",
    heading_description = "Standard definitions",
    tree_indent = " ",
    picker_visible = false,
    sync_enabled = true,
  },

  data_doc = {
    name = "data_doc",
    plural = "Data Docs",
    extension = ".md",
    subdirs = { "docs" },
    preserve_permissions = false,
    description_parser = "parse_doc_description",
    heading = "[Data Docs]",
    heading_description = "Data documentation",
    tree_indent = " ",
    picker_visible = false,
    sync_enabled = true,
  },

  settings = {
    name = "settings",
    plural = "Settings",
    extension = ".sh",
    subdirs = { "." },  -- Root .claude directory
    preserve_permissions = false,
    description_parser = "parse_script_description",
    heading = "[Settings]",
    heading_description = "Configuration files",
    tree_indent = " ",
    picker_visible = false,
    sync_enabled = true,
  },
}

--- Get artifact type configuration
---@param type_name string Artifact type name
---@return table|nil Configuration table or nil if not found
function M.get_type(type_name)
  return M.ARTIFACT_TYPES[type_name]
end

--- Get all artifact types
---@return table Map of type_name -> config
function M.get_all_types()
  return M.ARTIFACT_TYPES
end

--- Get all picker-visible artifact types
---@return table Array of artifact type configurations
function M.get_visible_types()
  local visible = {}
  for _, config in pairs(M.ARTIFACT_TYPES) do
    if config.picker_visible then
      table.insert(visible, config)
    end
  end
  return visible
end

--- Get all sync-enabled artifact types
---@return table Array of artifact type configurations
function M.get_sync_types()
  local sync_types = {}
  for _, config in pairs(M.ARTIFACT_TYPES) do
    if config.sync_enabled then
      table.insert(sync_types, config)
    end
  end
  return sync_types
end

--- Check if artifact type should preserve file permissions
---@param type_name string Artifact type name
---@return boolean True if permissions should be preserved
function M.should_preserve_permissions(type_name)
  local config = M.get_type(type_name)
  return config and config.preserve_permissions or false
end

--- Format artifact for display in picker
---@param artifact table Artifact data with name, description, is_local
---@param type_name string Artifact type
---@param indent_char string Tree character (├─ or └─)
---@return string Formatted display string
function M.format_artifact(artifact, type_name, indent_char)
  local config = M.get_type(type_name)
  if not config then
    return ""
  end

  local prefix = artifact.is_local and "*" or " "
  local description = artifact.description or ""

  -- Strip redundant "Specialized in " prefix if present
  description = description:gsub("^Specialized in ", "")

  -- Format: "* ├─ artifact-name     Description text"
  -- Standard 1-space indent (agents, templates, lib, docs, commands)
  -- Exception: hook events use 2-space indent (distinguishing marker)
  local indent_spaces = config.tree_indent or " "

  return string.format(
    "%s%s%s %-38s %s",
    prefix,
    indent_spaces,
    indent_char,
    artifact.name,
    description
  )
end

--- Format heading for artifact section
---@param type_name string Artifact type
---@return string Formatted heading display
function M.format_heading(type_name)
  local config = M.get_type(type_name)
  if not config then
    return ""
  end

  return string.format(
    "%-40s %s",
    config.heading,
    config.heading_description
  )
end

--- Get tree indent for artifact type
---@param type_name string Artifact type
---@return string Indent string (" " or "  ")
function M.get_tree_indent(type_name)
  local config = M.get_type(type_name)
  return config and config.tree_indent or " "
end

return M

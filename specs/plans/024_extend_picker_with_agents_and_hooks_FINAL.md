# Extend Command Picker with Agents, Hooks, and TTS Configs - FINAL Plan

## Metadata
- **Date**: 2025-10-01 (Final Revision)
- **Original Plan**: 024_extend_picker_with_agents_and_hooks.md
- **Feature**: Complete `<leader>ac` picker for managing all `.claude/` artifacts
- **Scope**: Previewer, file management, Load All, TTS config integration
- **Estimated Time**: 8-12 hours (Phase 3-4 remaining)
- **Complexity**: Medium
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**:
  - nvim/specs/reports/034_extend_command_picker_with_agents_and_hooks.md
  - nvim/specs/reports/036_agent_registry_relevance_analysis.md
  - .claude/specs/reports/019_custom_agent_invocation_workarounds.md

## Revision Summary

### Changes from Previous Revisions
1. **Agent Registry Removed** (2025-10-01)
   - Deleted `agent_registry.lua` and `agent_registry_spec.lua`
   - Marked Plans 025 and 026 as obsolete
   - Updated README.md with picker-centric approach

2. **Picker is Single Management Interface**
   - Parser provides all agent/hook scanning (no duplicate system)
   - Natural language invocation for commands (Workaround 1)
   - Focus on lifecycle management (load, update, save)

3. **TTS Config Integration**
   - Added as fourth artifact type
   - Managed alongside commands, agents, hooks

### Architecture Decision
[DECISION] **Picker-Centric Approach**: The `<leader>ac` picker is the single interface for discovering, viewing, editing, and synchronizing all `.claude/` artifacts across projects.

## Overview

The `<leader>ac` picker provides complete lifecycle management for four artifact types:

1. **Commands** (`.claude/commands/*.md`) - Slash commands
2. **Agents** (`.claude/agents/*.md`) - AI agent definitions
3. **Hooks** (`.claude/hooks/*.sh`) - Event-driven shell scripts
4. **TTS Configs** (`.claude/config/*.sh`) - Text-to-speech configurations

### Current State (Phase 1-2: COMPLETED)
- [DONE] Parser scans commands, agents, and hooks
- [DONE] Agents appear under parent commands in hierarchy
- [DONE] Hooks appear under hook event headers
- [DONE] Tree characters (├─, └─) display correctly
- [DONE] Basic picker structure integrated

### Target State (Phase 3-4: REMAINING)
- Previewer shows metadata for all artifact types
- File operations (load, update, save, edit) work for all types
- Load All synchronizes all four artifact types
- Keyboard shortcuts work uniformly across types
- TTS configs integrated into picker
- Executable permissions preserved for hooks/configs

## Success Criteria
- [x] Parser scans agents and hooks (Phase 1)
- [x] Agents under commands in picker (Phase 2)
- [x] Hooks under events in picker (Phase 2)
- [x] Tree characters correct (Phase 2)
- [x] Previewer shows all metadata (Phase 3)
- [x] Ctrl-l loads locally (Phase 3)
- [x] Ctrl-u updates from global (Phase 3)
- [x] Ctrl-s saves to global (Phase 3)
- [x] Enter opens in buffer (Phase 3)
- [x] Load All syncs all types (Phase 4)
- [x] TTS configs in picker (Phase 4)
- [x] Permissions preserved (Phase 3-4)

## Technical Design

### Artifact Types

```lua
entry_type = "command"      -- .claude/commands/*.md
entry_type = "agent"        -- .claude/agents/*.md
entry_type = "hook"         -- .claude/hooks/*.sh
entry_type = "hook_event"   -- Hook event header
entry_type = "tts_file"     -- TTS subsystem files (NEW)
entry_type = "tts_section"  -- TTS section header (NEW)
```

### TTS File Organization Analysis

**Revised Structure** (2 directories, simplified):
```
.claude/
├── hooks/
│   └── tts-dispatcher.sh     (349 lines) - Event router (registered hook)
└── tts/                      (CONSOLIDATED from config/ and lib/)
    ├── tts-config.sh         (164 lines) - Configuration variables
    └── tts-messages.sh       (277 lines) - Message generator library
```

**Excluded from Picker Management** (for simplicity):
- `bin/` directory (test-tts.sh and other utilities)
- `docs/` directory (documentation files)

**Rationale**:
- Consolidate TTS files into single `tts/` directory
- Dispatcher remains in `hooks/` (registered as hook)
- Move config from `config/` → `tts/` to avoid tracking extra directory
- Exclude bin/ and docs/ to focus picker on core TTS files only

**Picker Enhancement**: Recognize TTS as unified subsystem by scanning 2 directories

### Data Structures

```lua
-- TTS file structure (NEW - represents all TTS-related files)
tts_file = {
  name = "tts-config.sh",
  description = "Main TTS configuration",
  filepath = "/path/to/.claude/tts/tts-config.sh",
  is_local = true|false,
  role = "config|dispatcher|library",  -- Based on file type
  directory = "hooks|tts",  -- Only 2 directories (simplified)
  variables = {"TTS_ENABLED", "TTS_VOICE", ...},  -- For config files
  line_count = 164  -- File size indicator
}

-- TTS file role mapping (consolidated into tts/ and hooks/)
tts_roles = {
  ["hooks/tts-dispatcher.sh"] = "dispatcher",  -- Event router
  ["tts/tts-config.sh"] = "config",           -- Configuration (moved from config/)
  ["tts/tts-messages.sh"] = "library"         -- Message generator
}
```

### Parser Integration

The parser (`commands/parser.lua`) already provides:
- `scan_agents_directory()` - Parses `.claude/agents/*.md`
- `scan_hooks_directory()` - Parses `.claude/hooks/*.sh`
- `build_agent_dependencies()` - Maps commands → agents
- `build_hook_dependencies()` - Maps events → hooks
- `get_extended_structure()` - Returns unified structure

**New Addition Needed**:
- `scan_tts_configs_directory()` - Parse `.claude/config/*.sh` files

## Implementation Phases

### Phase 1: Parser Extensions [COMPLETED]
**Status**: Implemented in parser.lua:299-604

**What Was Done**:
- Agent scanning with frontmatter parsing
- Hook scanning with header comment parsing
- Agent dependency tracking (commands → agents)
- Hook dependency tracking (events → hooks)
- Unified structure via `get_extended_structure()`

**No Changes Needed** - Phase 1 complete.

### Phase 2: Picker Integration [COMPLETED]
**Status**: Implemented in picker.lua:1-100

**What Was Done**:
- Agents appear under parent commands with tree characters
- Hooks appear under event headers
- `format_agent()` and `format_hook()` display functions
- `get_agents_for_command()` helper function
- Picker calls `get_extended_structure()`

**No Changes Needed** - Phase 2 complete.

### Phase 3: Previewer and File Management [COMPLETED]
**Objective**: Complete previewer and implement all file operations
**Estimated Time**: 4-6 hours
**Status**: Implemented in picker.lua

#### Part A: Previewer Enhancement (2-3 hours)

**Tasks**:
- [x] Update `create_command_previewer()` in picker.lua
  - Add agent preview case
    ```lua
    if entry.entry_type == "agent" then
      return {
        "# Agent: " .. entry.name,
        "",
        "**Description**: " .. (entry.description or "N/A"),
        "",
        "**Allowed Tools**: " .. table.concat(entry.allowed_tools or {}, ", "),
        "",
        "**Used By Commands**: " .. table.concat(entry.parent_commands or {}, ", "),
        "",
        "**File**: " .. entry.filepath,
        "",
        entry.is_local and "📍 Local override" or "🌍 Global definition"
      }
    end
    ```

  - Add hook preview case
    ```lua
    if entry.entry_type == "hook" then
      return {
        "# Hook: " .. entry.name,
        "",
        "**Description**: " .. (entry.description or "N/A"),
        "",
        "**Triggered By Events**: " .. table.concat(entry.events or {}, ", "),
        "",
        "**Script**: " .. entry.filepath,
        "",
        "**Permissions**: " .. (get_file_permissions(entry.filepath) or "N/A"),
        "",
        entry.is_local and "📍 Local override" or "🌍 Global definition"
      }
    end
    ```

  - Add hook event preview case
    ```lua
    if entry.entry_type == "hook_event" then
      local event_descriptions = {
        Stop = "Triggered after command completion",
        SessionStart = "When Claude Code session begins",
        -- ... full lookup table
      }
      return {
        "# Hook Event: " .. entry.name,
        "",
        "**Description**: " .. event_descriptions[entry.name],
        "",
        "**Registered Hooks**: " .. #entry.hooks .. " hook(s)",
        "",
        "Hooks:",
        unpack(vim.tbl_map(function(h) return "- " .. h.name end, entry.hooks))
      }
    end
    ```

  - Add TTS config preview case (NEW)
    ```lua
    if entry.entry_type == "tts_config" then
      return {
        "# TTS Config: " .. entry.name,
        "",
        "**Description**: " .. (entry.description or "N/A"),
        "",
        "**Category**: " .. (entry.category or "config"),
        "",
        "**Variables**: " .. (#entry.variables > 0 and table.concat(entry.variables, ", ") or "None"),
        "",
        "**File**: " .. entry.filepath,
        "",
        entry.is_local and "📍 Local override" or "🌍 Global configuration"
      }
    end
    ```

- [x] Add helper function `get_file_permissions(filepath)`
  ```lua
  local function get_file_permissions(filepath)
    local perms = vim.fn.getfperm(filepath)
    if perms == "" then return nil end
    return perms  -- Returns: rwxr-xr-x format
  end
  ```

- [x] Update help text in previewer
  - Document all entry types
  - List keyboard shortcuts for each type
  - Explain Load All for all artifact types

**Testing**:
```bash
<leader>ac
# Navigate to agent → verify preview shows metadata
# Navigate to hook → verify preview shows events and permissions
# Navigate to hook event → verify preview lists hooks
# Press ? → verify help text complete
```

#### Part B: File Management Operations (2-3 hours)

**Tasks**:
- [x] Implement `load_agent_locally(agent, silent)`
  ```lua
  local function load_agent_locally(agent, silent)
    if agent.is_local then
      if not silent then
        vim.notify("Agent already local: " .. agent.name, vim.log.levels.INFO)
      end
      return false
    end

    local dest = vim.fn.getcwd() .. "/.claude/agents/" .. agent.name .. ".md"
    local src = agent.filepath

    -- Create directory if needed
    vim.fn.mkdir(vim.fn.getcwd() .. "/.claude/agents", "p")

    -- Copy file
    local success = vim.fn.writefile(vim.fn.readfile(src), dest)

    if success == 0 then
      if not silent then
        vim.notify("Loaded agent locally: " .. agent.name, vim.log.levels.INFO)
      end
      return true
    else
      vim.notify("Failed to load agent: " .. agent.name, vim.log.levels.ERROR)
      return false
    end
  end
  ```

- [x] Implement `load_hook_locally(hook, silent)`
  ```lua
  local function load_hook_locally(hook, silent)
    if hook.is_local then
      if not silent then
        vim.notify("Hook already local: " .. hook.name, vim.log.levels.INFO)
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
    local success = vim.fn.writefile(vim.fn.readfile(src), dest)

    if success == 0 then
      -- Restore permissions (critical for hooks!)
      vim.fn.setfperm(dest, perms)

      if not silent then
        vim.notify("Loaded hook locally: " .. hook.name, vim.log.levels.INFO)
      end
      return true
    else
      vim.notify("Failed to load hook: " .. hook.name, vim.log.levels.ERROR)
      return false
    end
  end
  ```

- [x] Implement `load_tts_file_locally(tts_file, silent)` (similar to load_hook with permissions)

- [x] Implement `update_agent_from_global(agent, silent)`
  ```lua
  local function update_agent_from_global(agent, silent)
    if not agent.is_local then
      vim.notify("Agent is not local: " .. agent.name, vim.log.levels.WARN)
      return false
    end

    local local_path = vim.fn.getcwd() .. "/.claude/agents/" .. agent.name .. ".md"
    local global_path = vim.fn.expand("~/.config/.claude/agents/" .. agent.name .. ".md")

    if vim.fn.filereadable(global_path) ~= 1 then
      vim.notify("No global version of agent: " .. agent.name, vim.log.levels.WARN)
      return false
    end

    -- Overwrite local with global
    local success = vim.fn.writefile(vim.fn.readfile(global_path), local_path)

    if success == 0 then
      if not silent then
        vim.notify("Updated agent from global: " .. agent.name, vim.log.levels.INFO)
      end
      return true
    else
      vim.notify("Failed to update agent: " .. agent.name, vim.log.levels.ERROR)
      return false
    end
  end
  ```

- [x] Implement `update_hook_from_global(hook, silent)` (with permission preservation)
- [x] Implement `update_tts_file_from_global(tts_file, silent)` (with permission preservation)

- [x] Implement `save_agent_to_global(agent, silent)`
  ```lua
  local function save_agent_to_global(agent, silent)
    if not agent.is_local then
      vim.notify("Agent is not local: " .. agent.name, vim.log.levels.WARN)
      return false
    end

    local local_path = agent.filepath
    local global_path = vim.fn.expand("~/.config/.claude/agents/" .. agent.name .. ".md")

    -- Create global directory if needed
    vim.fn.mkdir(vim.fn.expand("~/.config/.claude/agents"), "p")

    -- Copy local to global
    local success = vim.fn.writefile(vim.fn.readfile(local_path), global_path)

    if success == 0 then
      if not silent then
        vim.notify("Saved agent to global: " .. agent.name, vim.log.levels.INFO)
      end
      return true
    else
      vim.notify("Failed to save agent: " .. agent.name, vim.log.levels.ERROR)
      return false
    end
  end
  ```

- [x] Implement `save_hook_to_global(hook, silent)` (with permission preservation)
- [x] Implement `save_tts_file_to_global(tts_file, silent)` (with permission preservation)

- [x] Update action mappings in `attach_mappings()`
  ```lua
  -- <CR> (Enter): Open file in buffer
  actions.select_default:replace(function(prompt_bufnr)
    local entry = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    if entry.entry_type == "command" then
      vim.cmd("edit " .. entry.filepath)
    elseif entry.entry_type == "agent" then
      vim.cmd("edit " .. entry.filepath)
    elseif entry.entry_type == "hook" then
      vim.cmd("edit " .. entry.filepath)
    elseif entry.entry_type == "tts_config" then
      vim.cmd("edit " .. entry.filepath)
    elseif entry.entry_type == "hook_event" or entry.entry_type == "tts_section" then
      -- Headers - do nothing
    elseif entry.is_load_all then
      -- Handle Load All
    end
  end)

  -- <C-l>: Load locally
  map("i", "<C-l>", function(prompt_bufnr)
    local entry = action_state.get_selected_entry()

    if entry.entry_type == "command" then
      load_command_locally(entry, false)
    elseif entry.entry_type == "agent" then
      load_agent_locally(entry, false)
    elseif entry.entry_type == "hook" then
      load_hook_locally(entry, false)
    elseif entry.entry_type == "tts_config" then
      load_tts_config_locally(entry, false)
    end

    -- Refresh picker
    refresh_picker(prompt_bufnr)
  end)

  -- Similar for <C-u> (update) and <C-s> (save)
  ```

**Testing**:
```bash
<leader>ac

# Test agent operations
# Select global agent → Ctrl-l → verify copied to .claude/agents/
# Verify * indicator appears (local)
# Edit locally → Ctrl-s → verify saved to ~/.config/.claude/agents/

# Test hook operations
# Select global hook → Ctrl-l → verify permissions preserved
# Check: ls -la .claude/hooks/hook-name.sh
# Should show: -rwxr-xr-x (executable)

# Test TTS config operations
# Similar to hooks (executable preservation)
```

### Phase 4: Load All and TTS Integration [COMPLETED]
**Objective**: Sync all artifact types and integrate TTS configs
**Estimated Time**: 4-6 hours
**Status**: COMPLETED on 2025-10-01

#### Part A: Multi-Directory TTS Scanner (1-2 hours) [COMPLETED]

**Background**: TTS system consolidated into 2 directories:
- `.claude/hooks/` - Event dispatcher (tts-dispatcher.sh - 349 lines)
- `.claude/tts/` - Configuration + library (tts-config.sh 164L, tts-messages.sh 277L)

The scanner handles these 2 directories only (bin/ and docs/ excluded for simplicity).

**Tasks**:
- [x] Implement `scan_tts_files(base_dir)` in parser.lua
  ```lua
  --- Scan for TTS files across multiple .claude/ subdirectories
  --- @param base_dir string Base directory path (project or global)
  --- @return table Array of tts_file metadata
  function M.scan_tts_files(base_dir)
    local base_path = plenary_path:new(base_dir) / ".claude"

    if not base_path:exists() then
      return {}
    end

    -- TTS directories and their roles (consolidated to 2 directories)
    local tts_directories = {
      { subdir = "hooks", role = "dispatcher" },
      { subdir = "tts", role = nil }  -- Role determined by filename
    }

    local tts_files = {}

    for _, dir_spec in ipairs(tts_directories) do
      local dir_path = base_path / dir_spec.subdir

      if dir_path:exists() then
        local scandir_ok, files = pcall(vim.fn.readdir, dir_path:absolute())
        if scandir_ok then
          for _, filename in ipairs(files) do
            -- Match tts-*.sh or test-tts.sh
            if (filename:match("^tts%-.*%.sh$") or filename == "test-tts.sh") then
              local filepath = dir_path:absolute() .. "/" .. filename
              local path = plenary_path:new(filepath)

              if path:exists() then
                local content = path:read()
                local description = ""
                local variables = {}

                if content then
                  -- Extract description from header comment
                  for line in content:gmatch("[^\n]+") do
                    local desc = line:match("^#%s*(.+)")
                    if desc and not desc:match("^!/") then  -- Skip shebang
                      description = vim.trim(desc)
                      break  -- Use first comment as description
                    end

                    -- Extract TTS_* variables for config files
                    if filename:match("config") then
                      local var = line:match("^([A-Z_]+)=")
                      if var and var:match("^TTS_") then
                        table.insert(variables, var)
                      end
                    end
                  end

                  -- Determine role based on directory and filename
                  local role = dir_spec.role  -- "dispatcher" for hooks/
                  if not role then  -- tts/ directory
                    if filename:match("config") then
                      role = "config"
                    elseif filename:match("messages") then
                      role = "library"
                    else
                      role = "library"  -- Default for tts/
                    end
                  end

                  table.insert(tts_files, {
                    name = filename,
                    description = description ~= "" and description or "TTS system file",
                    filepath = filepath,
                    is_local = false,  -- Set by caller
                    role = role,  -- config|dispatcher|library
                    directory = dir_spec.subdir,  -- hooks|tts
                    variables = variables,  -- For config files
                    line_count = select(2, content:gsub("\n", "\n")) + 1
                  })
                end
              end
            end
          end
        end
      end
    end

    return tts_files
  end
  ```

- [x] Update `get_extended_structure()` to include TTS files
  ```lua
  function M.get_extended_structure()
    -- ... existing code ...

    -- Get TTS files from multiple directories (NEW)
    local tts_files = parse_tts_files_with_fallback(project_dir, global_dir)

    return {
      primary_commands = sorted_hierarchy.primary_commands,
      dependent_commands = sorted_hierarchy.dependent_commands,
      agents = agents,
      hooks = hooks,
      tts_files = tts_files,  -- NEW
      agent_dependencies = agent_deps,
      hook_events = hook_events
    }
  end
  ```

- [ ] Add `parse_tts_files_with_fallback()` helper
  ```lua
  local function parse_tts_files_with_fallback(project_dir, global_dir)
    local local_files = M.scan_tts_files(project_dir)
    local global_files = M.scan_tts_files(global_dir)

    -- Mark local files
    for _, file in ipairs(local_files) do
      file.is_local = true
    end

    -- Merge: local overrides global by name
    local merged = {}
    local seen = {}

    for _, file in ipairs(local_files) do
      merged[#merged + 1] = file
      seen[file.name] = true
    end

    for _, file in ipairs(global_files) do
      if not seen[file.name] then
        merged[#merged + 1] = file
      end
    end

    return merged
  end
  ```

**Testing**:
```lua
:lua local parser = require('neotex.plugins.ai.claude.commands.parser')
:lua local structure = parser.get_extended_structure()
:lua vim.print(vim.tbl_map(function(f) return {f.name, f.role, f.directory} end, structure.tts_files))
-- Should show: tts-dispatcher.sh (dispatcher/hooks),
--              tts-config.sh (config/tts),
--              tts-messages.sh (library/tts)
```

#### Part B: Picker TTS Integration (1-2 hours) [COMPLETED]

**Tasks**:
- [x] Update `create_picker_entries()` to add TTS file entries
  ```lua
  -- After hook events section, add TTS files section
  entries[#entries + 1] = {
    display = "─── TTS System Files ───",
    entry_type = "tts_section",
    ordinal = "zzzz_tts_header"
  }

  -- Sort TTS files by role (config, dispatcher, library) then name
  table.sort(tts_files, function(a, b)
    if a.role ~= b.role then
      -- Order: config, dispatcher, library
      local role_order = { config = 1, dispatcher = 2, library = 3 }
      return (role_order[a.role] or 99) < (role_order[b.role] or 99)
    end
    return a.name < b.name
  end)

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
  ```

- [x] Implement `format_tts_file(file)`
  ```lua
  local function format_tts_file(file)
    local prefix = file.is_local and "*" or " "
    local role_label = "[" .. file.role .. "]"
    local location = file.directory  -- config|hooks|tts

    return string.format(
      "%s %-12s %-25s (%s) %dL",
      prefix,
      role_label,
      file.name,
      location,
      file.line_count
    )
  end
  ```

**Testing**:
```bash
<leader>ac
# Scroll to bottom → verify "─── TTS System Files ───" section
# Verify files appear with role labels: [config], [dispatcher], [library]
# Verify directory location shown in parentheses: (hooks), (tts)
# Verify line counts shown: 349L (dispatcher), 164L (config), 277L (library)
# Verify * indicator for local files
# Verify Ctrl-l/u/s work for TTS files
```

#### Part C: Enhanced Load All (2 hours) [COMPLETED]

**Tasks**:
- [x] Rename `load_all_commands_locally()` to `load_all_globally()`
  - Update all references in picker.lua

- [x] Add helper `scan_directory_for_sync(global_dir, local_dir, extension)`
  ```lua
  local function scan_directory_for_sync(global_dir, local_dir, extension)
    local result = {
      new_files = {},
      update_files = {},
      new_count = 0,
      update_count = 0
    }

    local global_files = vim.fn.glob(global_dir .. "/*" .. extension, false, true)

    for _, filepath in ipairs(global_files) do
      local filename = vim.fn.fnamemodify(filepath, ":t")
      local local_path = local_dir .. "/" .. filename

      if vim.fn.filereadable(local_path) == 1 then
        -- File exists locally - will be updated
        table.insert(result.update_files, filename)
        result.update_count = result.update_count + 1
      else
        -- New file
        table.insert(result.new_files, filename)
        result.new_count = result.new_count + 1
      end
    end

    result.all_files = vim.list_extend(result.new_files, result.update_files)
    return result
  end
  ```

- [x] Add helper `sync_files(files, global_dir, local_dir, preserve_perms)`
  ```lua
  local function sync_files(files, global_dir, local_dir, preserve_perms)
    local results = {new = 0, updated = 0, failed = 0}

    -- Create local directory
    vim.fn.mkdir(local_dir, "p")

    for _, filename in ipairs(files) do
      local src = global_dir .. "/" .. filename
      local dest = local_dir .. "/" .. filename
      local is_new = vim.fn.filereadable(dest) ~= 1

      -- Get permissions before copying (if preserving)
      local perms = preserve_perms and vim.fn.getfperm(src) or nil

      -- Copy file
      local success = vim.fn.writefile(vim.fn.readfile(src), dest)

      if success == 0 then
        -- Restore permissions if needed
        if preserve_perms and perms then
          vim.fn.setfperm(dest, perms)
        end

        if is_new then
          results.new = results.new + 1
        else
          results.updated = results.updated + 1
        end
      else
        results.failed = results.failed + 1
      end
    end

    return results
  end
  ```

- [x] Update `load_all_globally()` to sync all four types
  ```lua
  function M.load_all_globally()
    local project_dir = vim.fn.getcwd()
    local global_dir = vim.fn.expand("~/.config/.claude")

    -- Scan all artifact types
    local cmd_sync = scan_directory_for_sync(
      global_dir .. "/commands",
      project_dir .. "/.claude/commands",
      ".md"
    )

    local agent_sync = scan_directory_for_sync(
      global_dir .. "/agents",
      project_dir .. "/.claude/agents",
      ".md"
    )

    local hook_sync = scan_directory_for_sync(
      global_dir .. "/hooks",
      project_dir .. "/.claude/hooks",
      ".sh"
    )

    -- Scan TTS files from 2 directories (hooks and tts)
    local tts_dispatcher_sync = scan_directory_for_sync(
      global_dir .. "/hooks",
      project_dir .. "/.claude/hooks",
      ".sh"
    )

    local tts_lib_sync = scan_directory_for_sync(
      global_dir .. "/tts",
      project_dir .. "/.claude/tts",
      ".sh"
    )

    -- Combine TTS counts
    local tts_new = tts_dispatcher_sync.new_count + tts_lib_sync.new_count
    local tts_update = tts_dispatcher_sync.update_count + tts_lib_sync.update_count

    -- Calculate totals
    local total_new = cmd_sync.new_count + agent_sync.new_count +
                      hook_sync.new_count + tts_new
    local total_update = cmd_sync.update_count + agent_sync.update_count +
                         hook_sync.update_count + tts_update

    -- Confirmation dialog
    local msg = string.format(
      "Load All from ~/.config/.claude/?\n\n" ..
      "Commands:     %2d new, %2d update\n" ..
      "Agents:       %2d new, %2d update\n" ..
      "Hooks:        %2d new, %2d update\n" ..
      "TTS Files:    %2d new, %2d update\n\n" ..
      "Total: %d new, %d updates",
      cmd_sync.new_count, cmd_sync.update_count,
      agent_sync.new_count, agent_sync.update_count,
      hook_sync.new_count, hook_sync.update_count,
      tts_new, tts_update,
      total_new, total_update
    )

    if vim.fn.confirm(msg, "&Yes\n&No", 2) ~= 1 then
      return
    end

    -- Sync each type
    local cmd_results = sync_files(cmd_sync.all_files,
      global_dir .. "/commands",
      project_dir .. "/.claude/commands",
      false  -- No permission preservation for markdown
    )

    local agent_results = sync_files(agent_sync.all_files,
      global_dir .. "/agents",
      project_dir .. "/.claude/agents",
      false
    )

    local hook_results = sync_files(hook_sync.all_files,
      global_dir .. "/hooks",
      project_dir .. "/.claude/hooks",
      true  -- Preserve permissions for hooks!
    )

    -- Sync TTS files from 2 directories (hooks and tts)
    local tts_dispatcher_results = sync_files(tts_dispatcher_sync.all_files,
      global_dir .. "/hooks",
      project_dir .. "/.claude/hooks",
      true  -- Preserve permissions for shell scripts!
    )

    local tts_lib_results = sync_files(tts_lib_sync.all_files,
      global_dir .. "/tts",
      project_dir .. "/.claude/tts",
      true  -- Preserve permissions for shell scripts!
    )

    -- Combine TTS results
    local tts_results = {
      new = tts_dispatcher_results.new + tts_lib_results.new,
      updated = tts_dispatcher_results.updated + tts_lib_results.updated,
      failed = tts_dispatcher_results.failed + tts_lib_results.failed
    }

    -- Results notification
    local total_synced = cmd_results.new + cmd_results.updated +
                         agent_results.new + agent_results.updated +
                         hook_results.new + hook_results.updated +
                         tts_results.new + tts_results.updated

    vim.notify(
      string.format("Synchronized %d files to .claude/", total_synced),
      vim.log.levels.INFO
    )

    -- Refresh picker
    return true  -- Indicates refresh needed
  end
  ```

- [x] Update [Load All Commands] preview to show breakdown

**Testing**:
```bash
<leader>ac
# Select [Load All Commands]
# Verify preview shows:
#   Commands: X new, Y update
#   Agents: X new, Y update
#   Hooks: X new, Y update
#   TTS Configs: X new, Y update
# Press Enter → verify confirmation shows same counts
# Confirm → verify all synced
# Check permissions: ls -la .claude/hooks/ .claude/config/
# All .sh files should be executable (rwxr-xr-x)
```

## Testing Strategy

### Unit Testing
- Parser functions (agent/hook/TTS scanning)
- File management functions (load/update/save)
- Permission preservation logic

### Integration Testing
- Full picker workflow (open → navigate → preview → edit)
- All keyboard shortcuts (Enter, Ctrl-l, Ctrl-u, Ctrl-s)
- Load All with all four types
- Permission handling for hooks and configs

### Edge Cases
- Empty directories (no local `.claude/`)
- Global-only artifacts
- Local-only artifacts
- Mixed (some local, some global)
- Permission denied errors
- Malformed files (invalid YAML, corrupted scripts)
- Large numbers of artifacts (performance)

## Documentation Requirements

### Code Documentation
- [ ] Docstrings for all new functions
- [ ] Document TTS config data structure
- [ ] Explain permission preservation logic
- [ ] Document Load All synchronization flow

### User Documentation
- [ ] Update picker.lua module comments
- [ ] Update help text in previewer
- [ ] Document all keyboard shortcuts
- [ ] Explain artifact types and indicators

### README Updates
- [ ] Update `nvim/lua/neotex/plugins/ai/claude/commands/README.md`
  - Document all four artifact types
  - Show example picker display
  - List keyboard shortcuts
  - Explain Load All behavior

## Dependencies

### External
- Telescope.nvim (already dependency)
- plenary.nvim (already dependency)

### File Dependencies
- `.claude/commands/*.md` - Slash commands
- `.claude/agents/*.md` - Agent definitions
- `.claude/hooks/*.sh` - Hook scripts
- `.claude/config/*.sh` - TTS configurations
- `.claude/settings.local.json` - Hook registrations

### Standards
- Follow nvim/CLAUDE.md standards
- 2 spaces indentation, expandtab
- snake_case naming
- pcall for error handling

## Risk Assessment

### Medium Risk
- **Permission handling** - Critical for hooks and TTS configs
  - Mitigation: Use vim.fn.getfperm/setfperm consistently
  - Mitigation: Test on multiple platforms
  - Mitigation: Verify after every file operation

- **TTS config parsing** - Shell scripts may have varied formats
  - Mitigation: Robust parsing with fallbacks
  - Mitigation: Handle missing metadata gracefully

### Low Risk
- **Performance** - More entries in picker
  - Mitigation: Current performance good with existing entries
  - Mitigation: Profile if issues arise

- **Backward compatibility** - Projects without all artifact types
  - Mitigation: Parser returns empty arrays for missing types
  - Mitigation: Graceful handling throughout

## Architecture Notes

### Why No Agent Registry
Based on `specs/reports/036_agent_registry_relevance_analysis.md`:

1. **Agent registry only valuable for Lua workflows** - Not needed for picker or commands
2. **Parser provides everything picker needs** - Metadata for display, no programmatic invocation
3. **Commands use natural language** - Workaround 1 is simpler than programmatic invocation
4. **User chose picker-centric approach** - Single management interface

### Picker as Single Source
The picker is the complete interface for:
- **Discovery** - Browse all artifacts hierarchically
- **Preview** - View metadata before opening
- **Edit** - Open files in buffer
- **Synchronize** - Load, update, save operations
- **Batch operations** - Load All for bulk sync

### Parser Role
- Scans directories for all artifact types
- Parses metadata (frontmatter, header comments)
- Builds dependencies (commands → agents, events → hooks)
- Returns structured data for picker display

## Implementation Timeline

**Total Estimate**: 8-12 hours

Breakdown:
- **Phase 3A**: Previewer (2-3 hours)
- **Phase 3B**: File Management (2-3 hours)
- **Phase 4A**: TTS Scanner (1-2 hours)
- **Phase 4B**: Picker TTS Integration (1-2 hours)
- **Phase 4C**: Enhanced Load All (2 hours)
- **Documentation**: 1-2 hours

## Future Enhancements

- Create new agent/hook/config from picker (Ctrl-n pattern)
- Hook enablement toggle from picker
- TTS config variable editor
- Search/filter by artifact type
- Dependency visualization
- Templates for new artifacts

## Migration Notes

### From Agent Registry Approach
- **Old**: agent_registry.lua + programmatic invocation
- **New**: Parser + natural language invocation (Workaround 1)
- **Impact**: Simpler, no infrastructure needed

### Command Updates Needed
If any commands still use `subagent_type: "agent-name"`:
1. Replace with natural language: `Use the [agent-name] agent to [task]`
2. Test that agent is invoked correctly
3. Remove any `[AGENT_PROMPT:name]` token patterns

## References

### Reports
- `.claude/specs/reports/019_custom_agent_invocation_workarounds.md` - Workaround 1 details
- `nvim/specs/reports/034_extend_command_picker_with_agents_and_hooks.md` - Original analysis
- `nvim/specs/reports/036_agent_registry_relevance_analysis.md` - Architecture decision

### Related Plans
- [OBSOLETE] Plan 025 (Agent Registry) - Marked obsolete
- [OBSOLETE] Plan 026 (Bulk Migration) - Marked obsolete
- [ACTIVE] Plan 024 (This plan) - Final implementation

---

*Plan finalized: 2025-10-01*
*Agent registry removed, picker-centric approach chosen*
*Focus: Complete lifecycle management for all `.claude/` artifacts*

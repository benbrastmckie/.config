# Research Report: Implementation Strategy for .opencode/ Picker

**Date**: 2025-12-15
**Topic**: Implementation Strategy and Technical Design
**Research Phase**: Technical Design

---

## Executive Summary

This report outlines a complete implementation strategy for creating a `.opencode/` picker analogous to the existing `<leader>ac` Claude Code picker. The strategy leverages the existing picker architecture while adapting it for the .opencode/ directory structure.

---

## Implementation Approach

### Option 1: Dedicated Module (Recommended)

Create a separate picker module specifically for .opencode/ utilities:

**Pros**:
- Clean separation of concerns
- No interference with existing Claude picker
- Easier to maintain and extend
- Can simplify structure (no local/global sync)

**Cons**:
- Some code duplication (mitigated by shared utilities)

**Structure**:
```
nvim/lua/neotex/plugins/ai/opencode/
├── picker.lua              # Facade
├── picker/
│   ├── init.lua           # Main orchestration
│   ├── parser.lua         # .opencode/ structure parser
│   ├── display/
│   │   ├── entries.lua    # Entry creation
│   │   └── previewer.lua  # Preview window
│   └── utils/
│       ├── helpers.lua    # Helper utilities
│       └── scan.lua       # Directory scanning
└── init.lua               # Plugin entry point
```

### Option 2: Shared Infrastructure

Extend existing picker infrastructure to support multiple artifact sources:

**Pros**:
- Maximum code reuse
- Unified architecture

**Cons**:
- Higher complexity
- Risk of breaking existing picker
- Harder to maintain

**Not Recommended**: Too much coupling risk.

---

## Module Design

### 1. Parser Module (`parser.lua`)

**Responsibilities**:
- Scan .opencode/ directory structure
- Parse command/agent files
- Extract metadata (descriptions, purposes)
- Build hierarchical data structure

**Key Functions**:

```lua
-- Scan .opencode/command/ directory
function M.scan_commands()
  -- Returns: array of {name, filepath, description}
end

-- Scan .opencode/agent/ directory (orchestrator + subagents)
function M.scan_agents()
  -- Returns: array of {name, filepath, description, role}
  -- role: "orchestrator", "primary", "subagent"
end

-- Scan .opencode/context/ subdirectories
function M.scan_context(subdir)
  -- subdir: "domain", "processes", "standards", "templates"
  -- Returns: array of {name, filepath, title}
end

-- Scan .opencode/workflows/
function M.scan_workflows()
  -- Returns: array of {name, filepath, title}
end

-- Scan .opencode/specs/ (projects and TODO.md)
function M.scan_specs()
  -- Returns: {
  --   todo_file = "/path/to/TODO.md",
  --   projects = [{number, name, filepath}]
  -- }
end

-- Get complete structure
function M.get_structure()
  return {
    commands = M.scan_commands(),
    agents = M.scan_agents(),
    context_domain = M.scan_context("domain"),
    context_processes = M.scan_context("processes"),
    context_standards = M.scan_context("standards"),
    context_templates = M.scan_context("templates"),
    workflows = M.scan_workflows(),
    specs = M.scan_specs(),
  }
end
```

**Metadata Extraction**:

```lua
-- Extract description from command file
function M.parse_command_description(filepath)
  local lines = vim.fn.readfile(filepath, '', 20)
  
  -- Look for "# /command" header
  for _, line in ipairs(lines) do
    if line:match("^# /") then
      -- Next non-empty line is description
      ...
    end
  end
end

-- Extract description from agent file
function M.parse_agent_description(filepath)
  local lines = vim.fn.readfile(filepath, '', 30)
  
  -- Look for "**Purpose**:" marker
  for i, line in ipairs(lines) do
    if line:match("^%*%*Purpose%*%*:") then
      return vim.trim(line:gsub("^%*%*Purpose%*%*:%s*", ""))
    end
  end
end

-- Extract title from markdown heading
function M.parse_title(filepath)
  local first_line = vim.fn.readfile(filepath, '', 1)[1]
  if first_line and first_line:match("^# ") then
    return first_line:gsub("^# ", "")
  end
  return ""
end
```

---

### 2. Display Module (`display/entries.lua`)

**Responsibilities**:
- Create picker entries from structure
- Format display strings
- Handle hierarchical sections

**Entry Creation**:

```lua
-- Create entries for commands section
function M.create_commands_entries(commands)
  local entries = {}
  
  -- Sort commands alphabetically
  table.sort(commands, function(a, b) return a.name < b.name end)
  
  -- Insert command entries (FIRST, appear LAST)
  for i, cmd in ipairs(commands) do
    local is_last = (i == #commands)
    local tree_char = is_last and "└─" or "├─"
    
    table.insert(entries, {
      display = string.format(
        " %s %-38s %s",
        tree_char,
        cmd.name,
        cmd.description or ""
      ),
      entry_type = "command",
      name = cmd.name,
      filepath = cmd.filepath,
      ordinal = "command_" .. cmd.name
    })
  end
  
  -- Insert heading (LAST, appears FIRST)
  table.insert(entries, {
    is_heading = true,
    name = "~~~commands_heading",
    display = string.format("%-40s %s", "[Commands]", "Workflow commands"),
    entry_type = "heading",
    ordinal = "commands"
  })
  
  return entries
end

-- Create entries for agents section
function M.create_agents_entries(agents)
  local entries = {}
  
  -- Group agents by role
  local orchestrator = nil
  local primary = {}
  local subagents = {}
  
  for _, agent in ipairs(agents) do
    if agent.role == "orchestrator" then
      orchestrator = agent
    elseif agent.role == "primary" then
      table.insert(primary, agent)
    else
      table.insert(subagents, agent)
    end
  end
  
  -- Sort within groups
  table.sort(primary, function(a, b) return a.name < b.name end)
  table.sort(subagents, function(a, b) return a.name < b.name end)
  
  -- Insert entries (orchestrator first, then primary, then subagents)
  local all_agents = {}
  if orchestrator then table.insert(all_agents, orchestrator) end
  vim.list_extend(all_agents, primary)
  vim.list_extend(all_agents, subagents)
  
  for i, agent in ipairs(all_agents) do
    local is_last = (i == #all_agents)
    local tree_char = is_last and "└─" or "├─"
    
    table.insert(entries, {
      display = string.format(
        " %s %-38s %s",
        tree_char,
        agent.name,
        agent.description or ""
      ),
      entry_type = "agent",
      name = agent.name,
      filepath = agent.filepath,
      role = agent.role,
      ordinal = "agent_" .. agent.name
    })
  end
  
  -- Insert heading
  table.insert(entries, {
    is_heading = true,
    name = "~~~agents_heading",
    display = string.format("%-40s %s", "[Agents]", "AI agents"),
    entry_type = "heading",
    ordinal = "agents"
  })
  
  return entries
end

-- Create entries for context sections
function M.create_context_entries(context_files, subdir_name, heading, description)
  local entries = {}
  
  if #context_files > 0 then
    table.sort(context_files, function(a, b) return a.name < b.name end)
    
    for i, file in ipairs(context_files) do
      local is_last = (i == #context_files)
      local tree_char = is_last and "└─" or "├─"
      
      table.insert(entries, {
        display = string.format(
          " %s %-38s %s",
          tree_char,
          file.name,
          file.title or ""
        ),
        entry_type = "context_" .. subdir_name,
        name = file.name,
        filepath = file.filepath,
        ordinal = "context_" .. subdir_name .. "_" .. file.name
      })
    end
    
    table.insert(entries, {
      is_heading = true,
      name = "~~~context_" .. subdir_name .. "_heading",
      display = string.format("%-40s %s", heading, description),
      entry_type = "heading",
      ordinal = "context_" .. subdir_name
    })
  end
  
  return entries
end

-- Create all entries
function M.create_picker_entries(structure)
  local all_entries = {}
  
  -- Insert in reverse order (descending sort)
  
  -- Documentation
  -- State
  -- Specs
  -- Workflows
  local workflows = M.create_context_entries(
    structure.workflows,
    "workflows",
    "[Workflows]",
    "Process workflows"
  )
  vim.list_extend(all_entries, workflows)
  
  -- Context - Templates
  local templates = M.create_context_entries(
    structure.context_templates,
    "templates",
    "[Context - Templates]",
    "File templates"
  )
  vim.list_extend(all_entries, templates)
  
  -- Context - Standards
  local standards = M.create_context_entries(
    structure.context_standards,
    "standards",
    "[Context - Standards]",
    "Coding standards"
  )
  vim.list_extend(all_entries, standards)
  
  -- Context - Processes
  local processes = M.create_context_entries(
    structure.context_processes,
    "processes",
    "[Context - Processes]",
    "Process workflows"
  )
  vim.list_extend(all_entries, processes)
  
  -- Context - Domain
  local domain = M.create_context_entries(
    structure.context_domain,
    "domain",
    "[Context - Domain]",
    "Domain knowledge"
  )
  vim.list_extend(all_entries, domain)
  
  -- Agents
  local agents = M.create_agents_entries(structure.agents)
  vim.list_extend(all_entries, agents)
  
  -- Commands (appears at top)
  local commands = M.create_commands_entries(structure.commands)
  vim.list_extend(all_entries, commands)
  
  return all_entries
end
```

---

### 3. Previewer Module (`display/previewer.lua`)

**Responsibilities**:
- Create Telescope previewer
- Show file contents in preview window

**Implementation**:

```lua
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values

function M.create_previewer()
  return previewers.new_buffer_previewer {
    title = "OpenCode Preview",
    define_preview = function(self, entry, status)
      local filepath = entry.value.filepath
      
      if filepath and vim.fn.filereadable(filepath) == 1 then
        conf.buffer_previewer_maker(filepath, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
        })
      end
    end,
  }
end
```

---

### 4. Main Orchestration (`picker/init.lua`)

**Responsibilities**:
- Create Telescope picker instance
- Set up keybindings
- Handle entry selection

**Keybindings**:

| Key | Action | Description |
|-----|--------|-------------|
| `<Enter>` | Open file | Open artifact in buffer |
| `<Ctrl-e>` | Edit file | Edit artifact (same as Enter) |
| `<Esc>` | Close picker | Exit immediately |
| `<Ctrl-u/d/f/b>` | Scroll preview | Preview window scrolling |

**Implementation**:

```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local parser = require("neotex.plugins.ai.opencode.picker.parser")
local entries = require("neotex.plugins.ai.opencode.picker.display.entries")
local previewer = require("neotex.plugins.ai.opencode.picker.display.previewer")

function M.show_opencode_picker(opts)
  opts = opts or {}
  
  -- Get structure
  local structure = parser.get_structure()
  
  if not structure or vim.tbl_isempty(structure.commands or {}) then
    vim.notify(
      "No OpenCode utilities found in .opencode/",
      vim.log.levels.WARN
    )
    return
  end
  
  -- Create entries
  local picker_entries = entries.create_picker_entries(structure)
  
  -- Create picker
  pickers.new(opts, {
    prompt_title = "OpenCode Utilities",
    finder = finders.new_table {
      results = picker_entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name or entry.ordinal or "",
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    sorting_strategy = "descending",
    default_selection_index = 2,
    previewer = previewer.create_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      -- Escape: close
      map("i", "<Esc>", actions.close)
      map("n", "<Esc>", actions.close)
      
      -- Preview scrolling
      map("i", "<C-u>", actions.preview_scrolling_up)
      map("i", "<C-d>", actions.preview_scrolling_down)
      map("i", "<C-f>", actions.preview_scrolling_down)
      map("i", "<C-b>", actions.preview_scrolling_up)
      
      -- Enter: open file
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_heading then
          return
        end
        
        actions.close(prompt_bufnr)
        
        local filepath = selection.value.filepath
        if filepath then
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        end
      end)
      
      -- Ctrl-e: edit (same as Enter)
      map("i", "<C-e>", function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_heading then
          return
        end
        
        actions.close(prompt_bufnr)
        
        local filepath = selection.value.filepath
        if filepath then
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        end
      end)
      
      return true
    end,
  }):find()
end
```

---

## Keybinding Integration

### Which-key Configuration

Add to `neotex/plugins/editor/which-key.lua`:

```lua
{ "<leader>ao", "<cmd>OpenCodePicker<CR>", desc = "opencode picker", icon = "󰘳" },
```

### User Command

Add to opencode plugin init:

```lua
vim.api.nvim_create_user_command("OpenCodePicker", function()
  require("neotex.plugins.ai.opencode.picker").show_opencode_picker()
end, { desc = "Show OpenCode utilities picker" })
```

---

## Testing Strategy

### Manual Testing

1. **Command Discovery**:
   - Verify all .opencode/command/ files appear
   - Check descriptions are extracted correctly

2. **Agent Discovery**:
   - Verify orchestrator, primary agents, subagents all appear
   - Check role-based grouping

3. **Context Discovery**:
   - Verify all context subdirectories scanned
   - Check hierarchical display

4. **Navigation**:
   - Test Enter key file opening
   - Test preview window scrolling
   - Test Esc key closing

5. **Edge Cases**:
   - Empty .opencode/ directory
   - Missing subdirectories
   - Files without descriptions

### Automated Testing

Create test file: `tests/opencode_picker_spec.lua`

```lua
describe("OpenCode Picker", function()
  local parser = require("neotex.plugins.ai.opencode.picker.parser")
  
  it("scans commands directory", function()
    local commands = parser.scan_commands()
    assert.is_not_nil(commands)
    assert.is_true(#commands > 0)
  end)
  
  it("scans agents directory", function()
    local agents = parser.scan_agents()
    assert.is_not_nil(agents)
    assert.is_true(#agents > 0)
  end)
  
  it("extracts command descriptions", function()
    local desc = parser.parse_command_description("/path/to/command.md")
    assert.is_not_nil(desc)
  end)
end)
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (2-3 hours)
1. Create directory structure
2. Implement parser module
3. Implement metadata extraction
4. Write parser tests

### Phase 2: Display Layer (2 hours)
1. Implement entries module
2. Implement previewer module
3. Test entry creation

### Phase 3: Telescope Integration (1-2 hours)
1. Implement main orchestration
2. Set up keybindings
3. Create user command
4. Test picker functionality

### Phase 4: Keybinding Integration (30 min)
1. Add to which-key configuration
2. Document keybinding
3. Test keybinding

### Phase 5: Documentation & Polish (1 hour)
1. Add module documentation
2. Add usage examples
3. Update README if needed
4. Final testing

**Total Estimated Time**: 6.5-8.5 hours

---

## Success Criteria

1. ✅ Picker opens with `<leader>ao`
2. ✅ All .opencode/ artifacts discovered
3. ✅ Hierarchical display with tree characters
4. ✅ Descriptions extracted and displayed
5. ✅ Enter key opens files in buffer
6. ✅ Preview window shows file contents
7. ✅ Esc key closes picker
8. ✅ No errors or warnings
9. ✅ Code follows existing patterns
10. ✅ Tests pass

---

## Future Enhancements

1. **Command Execution**: Run .opencode commands directly from picker (like Claude picker's Ctrl-r for scripts)
2. **Project Filtering**: Filter specs by status (active/archived)
3. **Search Integration**: Fuzzy search across descriptions
4. **Recent Files**: Track recently opened .opencode files
5. **Favorites**: Bookmark frequently used utilities

---

## Conclusion

This implementation strategy provides a complete roadmap for creating an .opencode/ picker that mirrors the existing Claude Code picker architecture while adapting to the .opencode/ directory structure. The modular approach ensures maintainability and extensibility.

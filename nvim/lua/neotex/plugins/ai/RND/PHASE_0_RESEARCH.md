# Phase 0 Research Findings: Solid Core Foundation

## Executive Summary

Research conducted for Phase 0 of the Agent System implementation reveals several key insights:
1. Task management plugins favor simple formats (todotxt, markdown checkboxes)
2. Context gathering is best handled by prompt-tower.nvim's proven patterns
3. Modern Neovim (0.11+) simplifies plugin architecture significantly
4. GTD workflows integrate well with markdown-based task systems

## 1. Task Management Plugin Research

### todotxt.nvim Analysis

**Two Main Implementations:**

#### arnarg/todotxt.nvim
- **Useful Features:**
  - `:ToDoTxtCapture` - Quick task entry prompt
  - `:ToDoTxtTasksToggle` - Sidebar with parsed tasks
  - Simple configuration with todo_file path
- **Code Complexity:** Low (~200 lines)
- **Dependencies:** None
- **Adaptation Potential:** HIGH - Simple format, easy to modify

#### phrmendes/todotxt.nvim
- **Useful Features:**
  - Priority cycling keybindings
  - Task state toggling
  - Sorting capabilities
- **Code Complexity:** Medium (~400 lines)
- **Listed in:** awesome-neovim (quality indicator)
- **Adaptation Potential:** MEDIUM - More features but complex

**Key Pattern to Extract:**
```lua
-- Simple task format parsing
local function parse_task(line)
  local completed = line:match("^x ")
  local priority = line:match("^%(([A-Z])%)")
  local date = line:match("(%d%d%d%d%-%d%d%-%d%d)")
  local text = line:gsub("^[x ]", ""):gsub("^%([A-Z]%)%s*", "")
  return {completed = completed, priority = priority, date = date, text = text}
end
```

### vim-getting-things-down
- **Unique Feature:** Progress bars in folded sections
- **Format:** Plain markdown with TODO keywords
- **Keyword Cycling:** DONE → WIP → WAIT → HELP → TODO
- **Adaptation:** Use checkbox format instead of keywords

### neowiki.nvim (GTD-focused)
- **Task Toggle:** `<leader>wt` switches `[ ]` ↔ `[x]`
- **Nested Progress:** Real-time updates of parent task completion
- **Multiple Wikis:** Work/personal separation
- **Key Insight:** Dynamic parent task updates based on children

**Pattern to Adapt:**
```lua
-- Nested task progress calculation
local function calculate_progress(tasks)
  local total = #tasks
  local completed = 0
  for _, task in ipairs(tasks) do
    if task.completed then completed = completed + 1 end
  end
  return string.format("[%d/%d]", completed, total)
end
```

### Decision: Markdown Checkbox Format
Based on research, use markdown checkboxes with extensions:
- `[ ]` - Pending
- `[~]` - In Progress (WIP)
- `[x]` - Completed  
- `[-]` - Blocked
- Add timestamps and metadata inline
- No external format dependencies

## 2. Context Gathering Research

### prompt-tower.nvim Deep Dive

**Architecture Strengths:**
- **No runtime dependencies** - Uses only Neovim APIs
- **File Selection UI** - Telescope-like picker
- **Smart Ignores** - Respects .gitignore and .towerignore
- **Template System** - XML, Markdown, Minimal formats

**Key Code Patterns:**

#### File Tree Generation
```lua
-- Simplified from prompt-tower
local function generate_tree(path, indent)
  local items = vim.fn.readdir(path)
  local tree = {}
  for _, item in ipairs(items) do
    if not is_ignored(item) then
      local full_path = path .. "/" .. item
      local is_dir = vim.fn.isdirectory(full_path) == 1
      table.insert(tree, {
        name = item,
        path = full_path,
        is_dir = is_dir,
        indent = indent
      })
      if is_dir then
        -- Recursive call for directories
        vim.list_extend(tree, generate_tree(full_path, indent + 1))
      end
    end
  end
  return tree
end
```

#### Ignore Pattern Implementation
```lua
-- Smart ignore checking
local function is_ignored(path)
  local ignore_patterns = {
    "node_modules", ".git", "*.pyc", "__pycache__",
    "dist", "build", ".next", ".cache"
  }
  
  -- Check .gitignore
  if use_gitignore then
    -- Parse .gitignore patterns
  end
  
  -- Check .towerignore
  if vim.fn.filereadable(".towerignore") == 1 then
    -- Parse custom ignore patterns
  end
  
  for _, pattern in ipairs(ignore_patterns) do
    if path:match(pattern) then return true end
  end
  return false
end
```

**What to Fork/Adapt:**
1. File tree generation logic (50 lines)
2. Ignore pattern system (30 lines)
3. NOT the UI - use Telescope instead

### Context Gathering Best Practices

From multiple sources:
- **Auto-detect related files** via imports/requires
- **Include test files** (*_test.*, *.test.*, *_spec.*)
- **Respect project boundaries** (.git root)
- **Limit context size** (10-15 files max for AI)

## 3. Plugin Architecture Research

### Modern Neovim Patterns (2025)

#### Directory Structure
```
~/.config/nvim/
├── init.lua                 # Entry point
└── lua/
    └── plugin-name/
        ├── init.lua         # Main module with setup()
        ├── config.lua       # Default configuration
        ├── tasks.lua        # Task management
        └── context.lua      # Context gathering
```

#### Setup Pattern
```lua
-- Standard setup pattern all plugins use
local M = {}

local defaults = {
  task_file = vim.fn.expand("~/.local/share/nvim/tasks.md"),
  auto_save = true,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})
  
  -- Initialize submodules
  require("plugin-name.tasks").setup(M.config)
  require("plugin-name.context").setup(M.config)
  
  -- Create commands
  M.create_commands()
  
  -- Set up autocommands
  M.create_autocmds()
end

return M
```

#### Best Practices from nvim-best-practices
1. **Separate config from initialization**
2. **Use pcall for error handling**
3. **Lazy load where possible**
4. **Use LuaCATS annotations**
5. **Target Lua 5.1 API for compatibility**

#### Error Handling Pattern
```lua
local ok, module = pcall(require, "some-module")
if not ok then
  vim.notify("Module not found: " .. module, vim.log.levels.WARN)
  return
end
```

### Configuration Insights

From 2025 Neovim configs:
- **Neovim 0.11+** simplifies everything
- **lazy.nvim** is the standard plugin manager
- **Keep it simple** - 180 lines can do everything
- **Modular files** beat monolithic configs

## 4. Specific Code to Extract/Adapt

### Priority 1: Task File Management (Day 1-2)
**Source:** Combination of patterns
```lua
-- From todotxt.nvim + neowiki.nvim patterns
local M = {}

-- Task format: - [x] Description (2024-01-15 14:30) [DONE: 2024-01-15 15:00]
local task_pattern = "^%s*%- %[(.-)%]%s+(.-)%s*%((.-)%)(.*)$"

function M.parse_task_line(line)
  local marker, desc, created, metadata = line:match(task_pattern)
  if not marker then return nil end
  
  return {
    status = marker == "x" and "done" or 
             marker == "~" and "wip" or
             marker == "-" and "blocked" or "pending",
    description = desc,
    created = created,
    metadata = metadata
  }
end

function M.toggle_task(line)
  local task = M.parse_task_line(line)
  if not task then return line end
  
  local status_map = {pending = "~", wip = "x", done = " ", blocked = " "}
  local new_marker = status_map[task.status] or " "
  
  return line:gsub("%[.-%]", "[" .. new_marker .. "]", 1)
end
```

### Priority 2: Context Gathering (Day 3-4)
**Source:** prompt-tower.nvim simplified
```lua
local M = {}

function M.gather_context()
  local context = {
    files = {},
    current_file = vim.fn.expand("%:p"),
    git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", ""),
  }
  
  -- Get related files
  local related = M.find_related_files(context.current_file)
  for _, file in ipairs(related) do
    if #context.files < 10 then  -- Limit context size
      table.insert(context.files, {
        path = file,
        content = table.concat(vim.fn.readfile(file), "\n")
      })
    end
  end
  
  return context
end

function M.find_related_files(current)
  local related = {}
  local dir = vim.fn.fnamemodify(current, ":h")
  local base = vim.fn.fnamemodify(current, ":t:r")
  
  -- Look for test files
  local test_patterns = {base .. "_test", base .. ".test", base .. "_spec"}
  for _, pattern in ipairs(test_patterns) do
    local files = vim.fn.glob(dir .. "/" .. pattern .. ".*", false, true)
    vim.list_extend(related, files)
  end
  
  -- Look for imports in current file
  local lines = vim.fn.readfile(current)
  for _, line in ipairs(lines) do
    local import = line:match('require%("(.-)"%)')
    if import then
      local import_path = import:gsub("%.", "/") .. ".lua"
      table.insert(related, import_path)
    end
  end
  
  return related
end
```

### Priority 3: Configuration Module (Day 1)
**Source:** Best practices compilation
```lua
local M = {}

M.defaults = {
  -- Task settings
  task_file = vim.fn.expand("~/.local/share/nvim/AGENT_TASKS.md"),
  task_auto_save = true,
  task_archive_after_days = 7,
  
  -- Context settings  
  context_max_files = 10,
  context_use_gitignore = true,
  context_auto_detect = true,
  
  -- Integration settings
  auto_inject_tasks = true,
  debug = false,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.defaults, opts or {})
  
  -- Validate configuration
  M.validate()
  
  -- Initialize modules in order
  local modules = {"tasks", "context", "templates"}
  for _, module in ipairs(modules) do
    local ok, mod = pcall(require, "agent." .. module)
    if ok then
      mod.setup(M.config)
    elseif M.config.debug then
      vim.notify("Failed to load module: " .. module, vim.log.levels.WARN)
    end
  end
  
  -- Set up commands
  M.create_commands()
end

function M.validate()
  -- Ensure directories exist
  local task_dir = vim.fn.fnamemodify(M.config.task_file, ":h")
  if vim.fn.isdirectory(task_dir) == 0 then
    vim.fn.mkdir(task_dir, "p")
  end
end

return M
```

## 5. Implementation Recommendations

### What to Build (Week 1)

1. **Day 1: Configuration Module**
   - Use standard setup() pattern
   - Implement validation
   - Create directory structure

2. **Day 2-3: Task File System**
   - Implement markdown checkbox format
   - Add toggle functionality
   - Create task parser
   - Build stats calculator

3. **Day 4-5: Basic Context Gatherer**
   - Adapt prompt-tower's file finding
   - Implement related file detection
   - Add gitignore support
   - Format for Claude

### What to Fork/Adapt

| Component | Source | Lines | Complexity | Decision |
|-----------|--------|-------|------------|----------|
| Task parsing | todotxt.nvim | ~30 | Low | Adapt pattern only |
| Task toggle | neowiki.nvim | ~20 | Low | Copy and modify |
| File tree | prompt-tower.nvim | ~50 | Medium | Simplify and adapt |
| Ignore patterns | prompt-tower.nvim | ~30 | Low | Copy with modifications |
| Config setup | Best practices | ~40 | Low | Use as template |

### What to Skip/Defer

1. **Complex UI** - Use vim.ui.input and Telescope
2. **Database/JSON storage** - Markdown is enough
3. **Bidirectional sync** - One-way extraction first
4. **Hook system** - Simple autocmds only
5. **Subagent spawning** - Wait for Week 5 research

## 6. Risk Mitigation

### Potential Issues and Solutions

1. **Task file conflicts**
   - Solution: Use file locks or atomic writes
   - Implement simple conflict detection

2. **Context size explosion**
   - Solution: Hard limit of 10 files
   - Add token counting estimate

3. **Performance with large projects**
   - Solution: Cache file trees
   - Use async where possible

4. **Integration with existing Claude setup**
   - Solution: Make all features optional
   - Use feature flags in config

## Conclusion

Phase 0 research validates the approach of building a simple, markdown-based task system with smart context gathering. The existing plugins provide excellent patterns to adapt without requiring complex dependencies. The total implementation should be under 500 lines of well-structured Lua code.

### Next Steps
1. Create directory structure
2. Implement config module with validation
3. Build task parser and toggle
4. Adapt context gathering from prompt-tower
5. Test integration with existing Claude setup

### Time Estimate
- Total Phase 0: 5-7 days
- Core functionality: 3-4 days  
- Integration and testing: 2-3 days
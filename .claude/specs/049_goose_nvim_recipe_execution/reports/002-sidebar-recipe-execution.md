# Neovim Sidebar Recipe Execution Methods

**Research Date**: 2025-12-09
**Topic**: Methods for running recipes directly from the neovim sidebar UI, integrating recipe execution with the sidebar component, and handling real-time output display within the sidebar panel
**Status**: Complete

---

## Executive Summary

This research investigates methods for executing goose recipes directly within the goose.nvim sidebar UI instead of external terminal output. Analysis reveals that goose.nvim's architecture fully supports recipe execution through its existing API layer, but the current custom recipe picker bypasses this integration.

**Key Findings**:
- goose.nvim sidebar is designed for real-time streaming output via plenary.job callbacks
- Recipe execution can be integrated using `goose.api.run()` or `goose.core.run()`
- Goose CLI supports both `--text` prompts and `--recipe` execution modes
- Sidebar output pane uses markdown rendering and auto-scrolling for chat-like UX
- Three integration strategies identified: (1) Text-based wrapper, (2) Native recipe args, (3) Hybrid approach

---

## Sidebar Component Architecture

### Window Layout and Management

The goose.nvim sidebar uses a split-pane layout managed by `goose.ui.ui.lua`:

```lua
-- From ui.lua: M.create_windows()
function M.create_windows()
  -- Creates sidebar with two panes:
  -- ┌─────────────┐
  -- │  Topbar     │  <- Provider/model/mode status
  -- ├─────────────┤
  -- │  Output     │  <- Goose responses (markdown rendered)
  -- │  Pane       │  <- Real-time streaming
  -- ├─────────────┤
  -- │  Input      │  <- User prompts
  -- │  Pane       │  <- Insert mode by default
  -- └─────────────┘

  state.windows = {
    output_window = output_win,
    input_window = input_win,
    output_buffer = output_buf,
    input_buffer = input_buf
  }
end
```

**Configuration** (from `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`):
```lua
ui = {
  window_width = 0.35,     -- 35% of screen width
  input_height = 0.15,     -- 15% for input area
  fullscreen = false,
  layout = "right",        -- Sidebar on right side
  floating_height = 0.8,
  display_model = true,    -- Show model in winbar
  display_goose_mode = true -- Show mode in winbar
}
```

### Output Rendering System

**Real-Time Streaming** (`ui.lua: M.render_output()`):
- Uses `on_stdout` callback from plenary.job to receive output chunks
- Appends output to output buffer incrementally
- Applies markdown rendering via render-markdown.nvim
- Auto-scrolls to bottom for chat-like experience

**Rendering Flow**:
```
goose CLI stdout
      │
      ▼
job.lua on_stdout callback
      │
      ▼
core.lua handlers.on_output()
      │
      ▼
ui.render_output() -> Append to buffer
      │
      ▼
render-markdown.nvim -> Format markdown
      │
      ▼
ui.scroll_to_bottom() -> Auto-scroll
```

---

## Integration Strategies for Recipe Execution

### Strategy 1: Text-Based Recipe Wrapper (Simplest)

**Concept**: Wrap recipe execution command as text prompt and pass to `goose.api.run()`.

**Implementation**:
```lua
-- In picker/execution.lua: M.run_recipe()
function M.run_recipe(recipe_path, metadata)
  local params = M.prompt_for_parameters(metadata.parameters)
  local cmd = M.build_command(recipe_path, params)

  -- Instead of: toggleterm.exec(cmd)
  -- Use goose API:
  local goose_api = require('goose.api')

  -- Option 1a: Execute as shell command text
  goose_api.run("Execute this command: " .. cmd)

  -- Option 1b: Direct CLI invocation (if goose handles it)
  goose_api.run(cmd)
end
```

**Pros**:
- Minimal code changes to recipe picker
- Uses existing goose.api.run() infrastructure
- Output appears in sidebar automatically
- Session state preserved

**Cons**:
- Relies on goose LLM interpreting the command (may not be direct)
- No explicit recipe parameter passing
- Potential for command interpretation errors

**Feasibility**: Medium - depends on whether goose CLI can be invoked as text

---

### Strategy 2: Native Recipe Arguments in job.lua (Most Robust)

**Concept**: Extend `goose.job.build_args()` to support `--recipe` arguments natively.

**Implementation**:
```lua
-- In goose/job.lua: Enhanced M.build_args()
function M.build_args(prompt, opts)
  opts = opts or {}

  -- Recipe execution mode
  if opts.recipe_path then
    local args = { "run", "--recipe", opts.recipe_path }

    -- Add parameters if present
    if opts.params then
      local param_str = {}
      for key, value in pairs(opts.params) do
        table.insert(param_str, string.format("%s=%s", key, value))
      end
      table.insert(args, "--params")
      table.insert(args, table.concat(param_str, ","))
    end

    -- Add interactive mode flag
    if opts.interactive then
      table.insert(args, "--interactive")
    end

    -- Add session management (if resuming)
    if state.active_session then
      table.insert(args, "--name")
      table.insert(args, state.active_session.name)
      table.insert(args, "--resume")
    end

    return args
  end

  -- Standard text prompt mode (existing code)
  local message = context.format_message(prompt)
  return { "run", "--text", message, ... }
end
```

**Usage in Recipe Picker**:
```lua
-- In picker/execution.lua: M.run_recipe()
function M.run_recipe(recipe_path, metadata)
  local params = M.prompt_for_parameters(metadata.parameters)

  -- Use enhanced core.run() with recipe options
  local goose_core = require('goose.core')
  goose_core.run(nil, {  -- nil prompt (using recipe instead)
    ensure_ui = true,
    new_session = false,
    focus = "output",
    recipe_path = recipe_path,  -- NEW: Recipe path option
    params = params,             -- NEW: Parameters
    interactive = true           # NEW: Interactive mode
  })
end
```

**Required Changes**:
1. Modify `goose/job.lua:build_args()` to accept opts table
2. Update `goose/core.lua:run()` to pass opts to job.build_args()
3. Update picker/execution.lua to call goose_core.run() with recipe opts

**Pros**:
- Clean integration with goose.nvim architecture
- Explicit recipe support in job layer
- Full session management integration
- Output streams to sidebar naturally
- Extensible for future recipe features

**Cons**:
- Requires modification of goose.nvim core (job.lua, core.lua)
- More complex implementation
- May require upstream PR to goose.nvim repository

**Feasibility**: High - goose CLI fully supports recipe execution, just needs args plumbing

---

### Strategy 3: Hybrid Approach (Best Balance)

**Concept**: Keep goose.nvim core unchanged, create adapter layer in recipe picker.

**Implementation**:
```lua
-- In picker/execution.lua: New function M.run_recipe_in_sidebar()
function M.run_recipe_in_sidebar(recipe_path, metadata)
  local params = M.prompt_for_parameters(metadata.parameters)

  -- Build goose CLI command
  local cmd = M.build_command(recipe_path, params)

  -- Create adapter to execute recipe via goose.job directly
  local goose_job = require('goose.job')
  local goose_ui = require('goose.ui.ui')
  local goose_state = require('goose.state')
  local goose_core = require('goose.core')

  -- Ensure sidebar is open
  if not goose_state.windows then
    goose_core.open({ new_session = false, focus = "output" })
  end

  -- Stop any running jobs
  goose_core.stop()

  -- Build recipe args manually
  local args = { "run", "--recipe", recipe_path, "--interactive" }
  if vim.tbl_count(params) > 0 then
    local param_parts = {}
    for key, value in pairs(params) do
      table.insert(param_parts, string.format("%s=%s", key, tostring(value)))
    end
    table.insert(args, "--params")
    table.insert(args, table.concat(param_parts, ","))
  end

  -- Execute via plenary.job directly (mimicking job.execute())
  local Job = require('plenary.job')
  goose_state.goose_run_job = Job:new({
    command = 'goose',
    args = args,
    on_start = function()
      vim.schedule(function()
        goose_ui.render_output()
      end)
    end,
    on_stdout = function(_, out)
      if out then
        vim.schedule(function()
          -- Trigger UI update (same as core.run)
          vim.cmd('checktime')
          goose_ui.render_output()
        end)
      end
    end,
    on_stderr = function(_, err)
      if err then
        vim.schedule(function()
          vim.notify(err, vim.log.levels.ERROR)
        end)
      end
    end,
    on_exit = function()
      vim.schedule(function()
        goose_state.goose_run_job = nil
      end)
    end
  })

  goose_state.goose_run_job:start()

  vim.notify(
    string.format('Executing recipe in sidebar: %s', metadata.name),
    vim.log.levels.INFO
  )
end
```

**Pros**:
- No modifications to goose.nvim core required
- Full control over recipe execution flow
- Output appears in sidebar
- Can coexist with ToggleTerm option (dual keybindings)
- Self-contained in recipe picker module

**Cons**:
- Duplicates some job.execute() logic
- Bypasses some goose.core orchestration (session handling, context)
- Requires manual state management

**Feasibility**: High - proven pattern already exists in job.lua

---

## Real-Time Output Handling

### Streaming Architecture

goose.nvim's streaming system is built on plenary.job's callback architecture:

```lua
-- From goose/job.lua
Job:new({
  command = 'goose',
  args = args,
  on_stdout = function(_, output_line)
    -- Called for EACH line of stdout
    vim.schedule(function()
      handlers.on_output(output_line)
    end)
  end,
  on_stderr = function(_, error_line)
    -- Called for EACH line of stderr
    vim.schedule(function()
      handlers.on_error(error_line)
    end)
  end,
  on_exit = function(job, exit_code)
    -- Called once when process exits
    vim.schedule(function()
      handlers.on_exit()
    end)
  end
})
```

**Key Characteristics**:
- Line-buffered output (each line triggers callback)
- Callbacks run in vim.schedule() for async safety
- Handlers receive raw output strings (no preprocessing)
- UI rendering happens in handlers (not in job.lua)

### UI Update Mechanism

**Output Buffer Management** (from `ui.lua`):
```lua
function M.render_output()
  -- Get session history from goose
  local session_output = session.get_output(state.active_session)

  -- Write to output buffer
  local output_lines = vim.split(session_output, '\n')
  vim.api.nvim_buf_set_lines(
    state.windows.output_buffer,
    0, -1,  -- Replace entire buffer
    false,
    output_lines
  )

  -- Apply markdown rendering
  -- (render-markdown.nvim hooks into buffer updates)

  -- Auto-scroll to bottom
  M.scroll_to_bottom()
end
```

**Markdown Rendering**:
- Handled by MeanderingProgrammer/render-markdown.nvim plugin
- Applied automatically on buffer updates
- Supports code blocks, headers, lists, emphasis
- Anti-conceal disabled in config (keeps markdown visible)

---

## Keybinding Integration Options

### Option A: Replace Current Behavior

Update the default `<CR>` action in picker to use sidebar:

```lua
-- In picker/init.lua: attach_mappings
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  local recipe = selection.value
  local meta = metadata.parse(recipe.path)
  if meta then
    -- NEW: Use sidebar instead of ToggleTerm
    execution.run_recipe_in_sidebar(recipe.path, meta)
  end
end)
```

### Option B: Dual Keybindings (Recommended)

Provide both terminal and sidebar execution options:

```lua
-- In picker/init.lua: attach_mappings
-- <CR>: Execute in goose sidebar (NEW DEFAULT)
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  local recipe = selection.value
  local meta = metadata.parse(recipe.path)
  if meta then
    execution.run_recipe_in_sidebar(recipe.path, meta)
  end
end)

-- <C-t>: Execute in ToggleTerm (ALTERNATIVE)
map('i', '<C-t>', function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  local recipe = selection.value
  local meta = metadata.parse(recipe.path)
  if meta then
    execution.run_recipe(recipe.path, meta)  -- Original ToggleTerm
  end
  vim.notify('Executing recipe in terminal (ToggleTerm)', vim.log.levels.INFO)
end)

-- <C-s>: Execute in goose sidebar (EXPLICIT)
map('i', '<C-s>', function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  local recipe = selection.value
  local meta = metadata.parse(recipe.path)
  if meta then
    execution.run_recipe_in_sidebar(recipe.path, meta)
  end
  vim.notify('Executing recipe in goose sidebar', vim.log.levels.INFO)
end)
```

**Keybinding Summary**:
- `<CR>`: Execute in sidebar (new default, most common use case)
- `<C-t>`: Execute in ToggleTerm (fallback for terminal-specific needs)
- `<C-s>`: Execute in sidebar (explicit, same as <CR>)
- `<C-e>`: Edit recipe file (existing)
- `<C-p>`: Preview recipe (--explain mode, existing)
- `<C-v>`: Validate recipe (existing)
- `<C-r>`: Refresh picker (existing)

---

## Session Management Integration

### Goose Session System

goose.nvim maintains persistent sessions via `goose.session.lua`:

**Session Structure**:
```lua
{
  name = "20250209_143052",  -- Session ID (timestamp)
  description = "Recipe: create-plan",  -- First prompt summary
  last_modified = 1707491452,
  messages = [ ... ]  -- Chat history
}
```

**Session Files**:
- Location: `~/.config/goose/sessions/`
- Format: JSONL (one message per line)
- Naming: `<session_id>.jsonl`

### Recipe-Session Integration

When executing recipes through the sidebar, sessions are automatically managed:

```lua
-- In core.lua: M.run()
if state.active_session then
  -- Resume existing session
  args = { "--name", state.active_session.name, "--resume" }
else
  -- Create new session
  -- goose CLI auto-generates session ID
  -- Session object populated via on_output callback:
  local session_id = output:match("session id:%s*([%w_]+)")
  if session_id then
    state.active_session = session.get_by_name(session_id)
  end
end
```

**Recipe Execution Sessions**:
- Each recipe run creates OR continues a session
- Recipe name can be included in session description
- Follow-up prompts in same session maintain context
- Session picker (`:GooseSelectSession`) allows resuming recipe sessions

**Session Description Enhancement**:
```lua
-- Suggested enhancement in execution.lua
function M.run_recipe_in_sidebar(recipe_path, metadata)
  -- ...execute recipe...

  -- Update session description with recipe name
  vim.defer_fn(function()
    if state.active_session then
      local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
      -- Could update session metadata to indicate recipe origin
      vim.notify(
        string.format('Recipe session: %s', state.active_session.name),
        vim.log.levels.INFO
      )
    end
  end, 100)
end
```

---

## Recommendations

### 1. Implement Strategy 3 (Hybrid Approach)

**Rationale**:
- No dependency on upstream goose.nvim changes
- Clean separation between picker and plugin
- Can be implemented immediately
- Proven pattern from goose.job.lua

**Implementation Steps**:
1. Add `run_recipe_in_sidebar()` function to `execution.lua`
2. Update picker `attach_mappings` to use new function for `<CR>`
3. Add `<C-t>` keybinding for ToggleTerm fallback
4. Test with existing recipes

### 2. Enhance UI Feedback

Add visual indicators for recipe execution mode:
- Notification: "Executing recipe in sidebar: <recipe_name>"
- Output pane title: "Goose - Recipe: <recipe_name>"
- Session description: "Recipe: <recipe_name>"

### 3. Future Enhancement: Native Recipe Support

Once sidebar execution is validated, consider:
- Submitting PR to goose.nvim for native recipe support (Strategy 2)
- Upstreaming recipe picker as goose.nvim extension
- Contributing to goose CLI recipe documentation

---

## Testing Checklist

### Basic Functionality
- [ ] Recipe executes in sidebar (output visible)
- [ ] Parameter prompts work correctly
- [ ] Markdown rendering applies to recipe output
- [ ] Auto-scroll to bottom during execution
- [ ] Session state preserved across recipe runs

### Edge Cases
- [ ] Recipe with no parameters
- [ ] Recipe with optional parameters
- [ ] Recipe with validation errors
- [ ] Long-running recipes (streaming output)
- [ ] Recipe execution cancellation (`:GooseStop`)

### Integration
- [ ] Can resume recipe session via session picker
- [ ] Recipe execution doesn't interfere with normal chat
- [ ] ToggleTerm fallback (`<C-t>`) still works
- [ ] Provider/model settings respected
- [ ] File context integration (if recipe uses @mentions)

---

## Relevant Code References

### goose.nvim Core
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/`
  - `core.lua:55-95` - `M.run()` execution flow
  - `job.lua:11-29` - `M.build_args()` argument construction
  - `job.lua:31-68` - `M.execute()` plenary.job setup
  - `ui/ui.lua` - Output rendering and window management

### Recipe Picker
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/`
  - `init.lua:61-70` - Default action handler (to be updated)
  - `execution.lua:19-40` - Current `run_recipe()` (ToggleTerm)
  - `execution.lua:139-157` - `build_command()` (recipe args)

### Configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua:66-89` - UI settings

---

## Performance Considerations

### Output Streaming Efficiency

**Current Architecture**:
- Line-buffered callbacks: Low overhead (only new lines trigger updates)
- vim.schedule() wrapping: Prevents UI blocking on rapid output
- Buffer replacement strategy: Entire buffer replaced on each render (acceptable for chat-sized output)

**Recipe-Specific Concerns**:
- Long-running recipes (e.g., file analysis) may produce large output
- goose CLI may batch output differently with --recipe vs --text
- Session file growth over multiple recipe runs

**Mitigations**:
- goose.nvim already handles long outputs (tested with multi-turn chats)
- Markdown rendering is efficient (render-markdown.nvim uses treesitter)
- Session files use JSONL (append-only, efficient)

### UI Responsiveness

**Current Implementation**:
- All callbacks run in vim.schedule() (non-blocking)
- Output buffer updates are asynchronous
- Markdown rendering happens after buffer update (also async via autocmds)

**No anticipated performance issues** with recipe execution in sidebar.

---

## Alternative Approaches Considered

### Option: Direct goose CLI Output Capture

**Concept**: Capture goose CLI output without plenary.job, redirect to buffer.

**Rejected Because**:
- Loses real-time streaming (output would only appear at end)
- No progress indication during long recipes
- Harder to manage process lifecycle (stop, cancel)
- plenary.job provides robust process management

### Option: Embedded Recipe Interpreter

**Concept**: Implement recipe execution in pure Lua (no goose CLI for recipes).

**Rejected Because**:
- Duplicates goose CLI recipe logic (YAML parsing, parameter validation)
- Breaks compatibility with goose recipe ecosystem
- Maintenance burden for recipe feature parity
- goose CLI is the canonical recipe implementation

---

## Conclusion

Integrating recipe execution with the goose.nvim sidebar is fully feasible using existing plugin architecture. The recommended hybrid approach (Strategy 3) provides immediate value without requiring upstream changes, while keeping the door open for future native integration (Strategy 2).

**Expected Outcome**:
- Recipe output appears in goose sidebar instead of ToggleTerm
- Real-time streaming of recipe execution progress
- Session management for recipe runs
- Improved UX with markdown rendering and auto-scroll
- Dual keybindings for sidebar vs terminal execution

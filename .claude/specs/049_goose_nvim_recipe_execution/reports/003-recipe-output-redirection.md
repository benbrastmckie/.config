# Recipe Output Handling and File Redirection

**Research Date**: 2025-12-09
**Topic**: Current output handling in the picker (<leader>aR), understanding why output redirects to goose-picker-output.md, and designing improvements to control output flow and prevent unwanted file creation
**Status**: Complete

---

## Executive Summary

Investigation of the recipe picker's output redirection reveals that `goose-picker-output.md` is NOT created by the recipe picker code itself, but rather by an external process or workflow unrelated to the picker implementation. The current picker executes recipes via ToggleTerm, which outputs to a terminal buffer, not a markdown file.

**Key Findings**:
- Recipe picker uses ToggleTerm.exec() which outputs to neovim terminal buffer (not a file)
- `goose-picker-output.md` exists at `/home/benjamin/.config/.claude/output/` but is not referenced in picker code
- File appears to be created by a separate workflow (possibly /create-plan or other Claude command)
- No evidence of file redirection in picker execution flow
- Switching to sidebar execution will eliminate terminal output entirely (no files created)

---

## Current Output Handling in Recipe Picker

### Execution Flow Analysis

**Keybinding**: `<leader>aR` (from `which-key.lua`)

**Code Path**:
```
User presses <leader>aR
      │
      ▼
which-key.lua: Calls require('neotex.plugins.ai.goose.picker').show_recipe_picker()
      │
      ▼
picker/init.lua: Shows Telescope picker with recipes
      │
      ▼
User selects recipe and presses <CR>
      │
      ▼
picker/init.lua:61-70: actions.select_default handler
      │
      ▼
picker/execution.lua:19-40: M.run_recipe(recipe_path, metadata)
      │
      ▼
picker/execution.lua:31-32: toggleterm.exec(cmd)
      │
      ▼
ToggleTerm opens terminal buffer and executes:
  goose run --recipe '/path/to/recipe.yaml' --interactive --params key=val
      │
      ▼
goose CLI output streams to ToggleTerm buffer
```

**No file redirection occurs in this flow.**

### ToggleTerm Execution Mechanism

**Code** (from `picker/execution.lua:30-33`):
```lua
-- Execute via ToggleTerm using direct API call
local toggleterm = require('toggleterm')
toggleterm.exec(cmd)
```

**ToggleTerm Behavior**:
- `toggleterm.exec(cmd)` spawns a terminal buffer
- Command output goes to terminal buffer (not file)
- Terminal buffer is ephemeral (can be closed, not saved)
- No automatic file redirection

**Terminal Buffer Characteristics**:
- Buffer type: `terminal`
- Listed: No (hidden from buffer list by default)
- Modifiable: No (read-only, controlled by job)
- Persistence: Lost on neovim exit (unless session saved)

---

## Investigation: goose-picker-output.md Origin

### File Location and Contents

**Path**: `/home/benjamin/.config/.claude/output/goose-picker-output.md`

**Content Examination**:
```markdown
goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive --params feature_description='remove avante from neovim completely including all historical mentions in documentation, code, or comments'

┌─────────────────────────────────────────────────┐
├─ 󱄅 Distro : NixOS 24.11 (Vicuna)
├─  Kernal : Linux 6.6.94
├─  Packages : 6958 (nix-system), 2190 (nix-user)
...
Error: Template rendering failed: Failed to parse recipe: missing field `title` at line 12 column 1
```

**Analysis**:
1. Shows full goose CLI command with parameters
2. Includes system information banner (from neovim terminal or shell)
3. Contains goose error message about recipe parsing
4. Format suggests terminal output capture, not direct file write

### Code Search for File Creation

**Search 1: Direct filename reference**
```bash
grep -r "goose-picker-output" /home/benjamin/.config/nvim/
# Result: No matches
```

**Search 2: Output redirection patterns**
```bash
grep -r ">" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/ | grep -v "^--"
# Result: No output redirection operators found
```

**Search 3: File write operations**
```bash
grep -r "vim.fn.writefile\|io.open.*w" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/
# Result: No file write operations found
```

**Conclusion**: The recipe picker code does NOT create `goose-picker-output.md`.

### Hypothesis: External Workflow File Creation

**Evidence**:
1. File location: `.claude/output/` (Claude command output directory)
2. Filename pattern: `*-output.md` (matches other Claude output files)
3. Content: Includes full command line with parameters
4. Directory listing shows other output files:
   ```
   .claude/output/
   ├── create-plan-output.md
   ├── debug-output.md
   ├── goose-picker-output.md  <- This file
   ├── lean-implement-output.md
   └── lean-plan-output.md
   ```

**Most Likely Cause**:
- User or Claude workflow captured terminal output and saved to file
- Possibly via `/create-plan` or similar command
- File may be a debugging artifact or manual capture
- Not part of normal recipe picker operation

### Alternative Hypothesis: ToggleTerm Logging

**Investigation**:
```lua
-- Check ToggleTerm configuration
-- From: nvim/lua/neotex/plugins/editor/toggleterm.lua (if exists)
```

**Search for ToggleTerm config**:
```bash
find /home/benjamin/.config/nvim -name "toggleterm.lua" -o -name "*toggleterm*"
```

If ToggleTerm is configured with output logging, it could create files automatically.

**However**: No evidence found in picker code that enables ToggleTerm logging.

---

## Output Flow Comparison

### Current Flow (ToggleTerm)

```
Recipe Picker (<leader>aR)
      │
      ▼
User selects recipe + parameters
      │
      ▼
execution.lua: toggleterm.exec(cmd)
      │
      ▼
┌─────────────────────────────────┐
│  ToggleTerm Buffer             │
│  ┌───────────────────────────┐ │
│  │ $ goose run --recipe ...  │ │
│  │                           │ │
│  │ [Goose output here...]    │ │
│  │                           │ │
│  └───────────────────────────┘ │
└─────────────────────────────────┘
      │
      ▼
Output visible in terminal buffer
(No file created by picker)
```

**Output Destinations**:
1. ToggleTerm buffer (primary)
2. goose session file (`~/.config/goose/sessions/<session_id>.jsonl`)
3. **NOT** to goose-picker-output.md (unless manually captured)

### Proposed Flow (Sidebar Integration)

```
Recipe Picker (<leader>aR)
      │
      ▼
User selects recipe + parameters
      │
      ▼
execution.lua: run_recipe_in_sidebar()
      │
      ▼
goose.job.execute() via plenary.job
      │
      ▼
┌─────────────────────────────────┐
│  Goose Sidebar                 │
│  ┌───────────────────────────┐ │
│  │  [Recipe output here...]  │ │ <- Output Pane
│  │  [Markdown rendered]      │ │
│  │  [Real-time streaming]    │ │
│  ├───────────────────────────┤ │
│  │  > _                      │ │ <- Input Pane
│  └───────────────────────────┘ │
└─────────────────────────────────┘
      │
      ▼
Output visible in sidebar
(No file created, no terminal buffer)
```

**Output Destinations**:
1. Goose sidebar output pane (primary)
2. goose session file (`~/.config/goose/sessions/<session_id>.jsonl`)
3. **NOT** to any markdown files (sidebar uses buffers, not files)

---

## File Creation Prevention Strategies

### Strategy 1: Eliminate ToggleTerm (Recommended)

**Implementation**: Use sidebar execution exclusively (Strategy 3 from Report 002).

**Effect**:
- No terminal buffers created
- All output goes to sidebar buffers (not files)
- Session files still created (normal goose behavior)
- No markdown output files

**Code**:
```lua
-- In picker/execution.lua
function M.run_recipe(recipe_path, metadata)
  -- OLD: toggleterm.exec(cmd)  -- Creates terminal buffer
  -- NEW: run_recipe_in_sidebar(recipe_path, metadata)  -- Uses sidebar buffer
  M.run_recipe_in_sidebar(recipe_path, metadata)
end
```

### Strategy 2: Conditional Output Destination

**Implementation**: Provide user choice between terminal and sidebar.

**Code**:
```lua
-- In picker/init.lua: attach_mappings
map('i', '<CR>', function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  local recipe = selection.value
  local meta = metadata.parse(recipe.path)

  -- Prompt for output destination
  vim.ui.select(
    { 'Sidebar (recommended)', 'Terminal' },
    { prompt = 'Execute recipe in:' },
    function(choice)
      if choice == 'Sidebar (recommended)' then
        execution.run_recipe_in_sidebar(recipe.path, meta)
      else
        execution.run_recipe(recipe.path, meta)  -- ToggleTerm
      end
    end
  )
end)
```

**Effect**:
- User controls output destination per recipe execution
- Sidebar option eliminates file creation
- Terminal option preserves current behavior (if needed)

### Strategy 3: ToggleTerm Output Capture Prevention

**Implementation**: Configure ToggleTerm to disable output logging (if enabled).

**Code** (hypothetical, if ToggleTerm config exists):
```lua
-- In toggleterm.lua config
require('toggleterm').setup({
  persist_mode = false,  -- Don't persist terminal state
  persist_size = false,  -- Don't persist terminal size
  direction = 'float',
  close_on_exit = true,  -- Auto-close on command completion
  -- Ensure no output logging:
  on_stdout = nil,  -- No custom stdout handler
  on_stderr = nil,  -- No custom stderr handler
})
```

**Note**: No evidence that ToggleTerm is creating files in current setup.

---

## Root Cause Analysis: goose-picker-output.md

### Finding 1: File is Not Created by Picker Code

**Evidence**:
- No file write operations in picker modules
- No output redirection in command strings
- ToggleTerm outputs to buffer, not file
- No matches for filename in codebase

**Conclusion**: Picker code is not responsible for file creation.

### Finding 2: File Location Suggests Claude Workflow

**Evidence**:
- Location: `.claude/output/` (Claude command output directory)
- Filename pattern: Matches other Claude output files
- Content format: Terminal output capture

**Hypothesis**: File was created by one of these mechanisms:
1. Manual capture: User ran `TermExec` and saved buffer to file
2. Claude command: `/create-plan` or other command captured output
3. Debugging workflow: Output redirected during troubleshooting
4. External script: Automation script saved terminal output

### Finding 3: File is a Debugging Artifact

**Evidence**:
- Content shows recipe error: `missing field 'title'`
- Full command line preserved for debugging
- System information included (suggests diagnostic capture)

**Conclusion**: File appears to be a one-time debugging artifact, not regular picker output.

### Recommendation: Ignore goose-picker-output.md

**Rationale**:
- Not created by picker code
- Not part of normal operation
- Likely a manual or one-time debugging file
- Sidebar migration will prevent any future terminal output captures

**Action**:
- Add `goose-picker-output.md` to `.gitignore` (if committing .claude/output/)
- Delete file if no longer needed for debugging
- Focus implementation effort on sidebar migration (prevents recurrence)

---

## Output Control Improvements

### Improvement 1: Sidebar Exclusive Execution

**Goal**: All recipe output goes to sidebar (no terminal, no files).

**Implementation**:
```lua
-- picker/init.lua: Update default action
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  local recipe = selection.value
  local meta = metadata.parse(recipe.path)
  if meta then
    execution.run_recipe_in_sidebar(recipe.path, meta)  -- NEW: Sidebar only
  end
end)
```

**Benefits**:
- Single, consistent output destination
- No terminal buffers created
- No risk of file captures
- Better UX with markdown rendering

### Improvement 2: Output Destination Feedback

**Goal**: Notify user where output will appear.

**Implementation**:
```lua
-- picker/execution.lua: Enhanced run_recipe_in_sidebar()
function M.run_recipe_in_sidebar(recipe_path, metadata)
  -- ...setup code...

  -- Clear notification with output location
  vim.notify(
    string.format(
      'Executing recipe: %s\nOutput: Goose sidebar (right panel)\nSession: %s',
      metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r'),
      state.active_session and state.active_session.name or 'new'
    ),
    vim.log.levels.INFO,
    { title = 'Recipe Execution' }
  )

  -- ...execute recipe...
end
```

**Benefits**:
- User knows where to look for output
- Session ID shown for future reference
- Reduces confusion about output location

### Improvement 3: Session File Management

**Goal**: Prevent session file accumulation from recipe runs.

**Context**:
- Each recipe run creates/updates goose session file
- Session files persist in `~/.config/goose/sessions/`
- Over time, many session files accumulate

**Implementation Option A: Automatic Session Cleanup**
```lua
-- Pseudo-code: Add to execution.lua
function M.cleanup_old_recipe_sessions()
  local sessions = require('goose.session').get_sessions()

  -- Find recipe sessions older than 7 days
  local week_ago = os.time() - (7 * 24 * 60 * 60)
  for _, session in ipairs(sessions) do
    if session.description:match("^Recipe:") and session.last_modified < week_ago then
      -- Delete old recipe session
      os.remove(session.path)
    end
  end
end
```

**Implementation Option B: Recipe Session Tagging**
```lua
-- Add metadata to session description
local session_desc = string.format(
  "Recipe: %s [picker:%s]",
  metadata.name,
  os.date("%Y%m%d")
)
-- User can filter/delete sessions with [picker:*] tag
```

**Recommendation**: Option B (tagging) is safer - preserves user sessions, enables manual cleanup.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Manual File Redirection

**DON'T**:
```lua
-- BAD: Redirect output to file
local cmd = M.build_command(recipe_path, params)
cmd = cmd .. " > " .. output_file_path
toggleterm.exec(cmd)
```

**Why**: Creates persistent files, hard to manage, loses real-time feedback.

### Anti-Pattern 2: Buffer-to-File Conversion

**DON'T**:
```lua
-- BAD: Capture terminal buffer and save to file
local term_buf = toggleterm.get_buffer()
local lines = vim.api.nvim_buf_get_lines(term_buf, 0, -1, false)
vim.fn.writefile(lines, "goose-picker-output.md")
```

**Why**: Creates unnecessary files, defeats purpose of buffers.

### Anti-Pattern 3: Silent Output Suppression

**DON'T**:
```lua
-- BAD: Suppress output entirely
local cmd = M.build_command(recipe_path, params)
cmd = cmd .. " > /dev/null 2>&1"
toggleterm.exec(cmd)
```

**Why**: User has no feedback on recipe execution, errors invisible.

---

## Implementation Checklist

### Phase 1: Sidebar Integration (Primary Goal)
- [ ] Implement `run_recipe_in_sidebar()` in execution.lua
- [ ] Update picker default action to use sidebar execution
- [ ] Test recipe execution with output in sidebar
- [ ] Verify markdown rendering works for recipe output
- [ ] Confirm no terminal buffers created

### Phase 2: Keybinding Updates
- [ ] Set `<CR>` to sidebar execution
- [ ] Add `<C-t>` for ToggleTerm fallback (optional)
- [ ] Update which-key descriptions
- [ ] Document new keybindings in picker README

### Phase 3: Output Management
- [ ] Add output destination notification
- [ ] Test session file creation/update
- [ ] Verify session picker shows recipe sessions
- [ ] Add session description tagging (optional)

### Phase 4: Cleanup and Documentation
- [ ] Delete or archive goose-picker-output.md
- [ ] Add output files to .gitignore (if needed)
- [ ] Update picker README with new execution flow
- [ ] Document troubleshooting for output issues

---

## Expected Outcomes

### Before (Current State)

**Output Flow**:
```
Recipe Picker -> ToggleTerm -> Terminal Buffer -> (Manual capture?) -> goose-picker-output.md
```

**Issues**:
- Output in terminal buffer (separate from goose UI)
- Inconsistent file creation (manual captures)
- No markdown rendering in terminal
- Harder to reference past recipe runs

### After (Sidebar Integration)

**Output Flow**:
```
Recipe Picker -> goose.job.execute -> Sidebar Output Pane -> Session File
```

**Improvements**:
- Output in goose sidebar (consistent with chat UX)
- No file creation (except session files)
- Markdown rendering with syntax highlighting
- Easy access to past recipe runs via session picker
- Real-time streaming with auto-scroll

---

## Monitoring and Validation

### Post-Implementation Checks

**1. Verify No File Creation**:
```bash
# Before running recipe, note file count
ls -1 .claude/output/ | wc -l

# Run recipe via picker (<leader>aR)
# Select recipe, provide parameters, execute

# After execution, verify count unchanged
ls -1 .claude/output/ | wc -l

# Check for new output files
find .claude/output -name "*output.md" -mtime -1
```

**2. Verify Sidebar Output**:
- Check goose sidebar output pane shows recipe output
- Verify markdown rendering applied (code blocks, headers)
- Confirm auto-scroll to bottom during execution
- Test with long-running recipe (streaming works)

**3. Verify Session Management**:
```bash
# List sessions before recipe
goose session list

# Run recipe

# List sessions after recipe
goose session list

# Verify new session created or existing session updated
# Session description should include recipe name
```

---

## Conclusion

The `goose-picker-output.md` file is NOT created by the recipe picker code. It appears to be a debugging artifact from an external workflow or manual capture. The current picker uses ToggleTerm, which outputs to a terminal buffer (not a file).

**Resolution Strategy**:
1. **Primary**: Migrate recipe execution to goose sidebar (eliminates terminal buffers entirely)
2. **Secondary**: Delete/archive goose-picker-output.md (not needed)
3. **Tertiary**: Add `.claude/output/*-output.md` to .gitignore (prevent future manual captures from being committed)

**Key Insight**: Sidebar integration solves the "unwanted file creation" problem by design - all output goes to buffers managed by goose.nvim, with only session files (intentional, managed by goose CLI) persisted to disk.

---

## Relevant File Paths

### Picker Implementation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/`
  - `execution.lua:30-33` - ToggleTerm execution (current)
  - `init.lua:61-70` - Default action handler (to be updated)

### Output File (Debugging Artifact)
- `/home/benjamin/.config/.claude/output/goose-picker-output.md` - Not created by picker

### Session Files (Legitimate Output)
- `~/.config/goose/sessions/` - goose CLI session storage (JSONL files)

### Configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua` - Plugin config
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` - `<leader>aR` keybinding

---

## Additional Notes

- ToggleTerm is a valid tool for terminal integration, not a source of unwanted file creation
- goose CLI session files are intentional and necessary (not "unwanted" output)
- Future consideration: Add session file cleanup utility for old recipe sessions
- Consider adding recipe execution history tracking (separate from sessions) for analytics

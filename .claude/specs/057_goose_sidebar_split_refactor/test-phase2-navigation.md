# Phase 2: Split Navigation Integration Testing

## Test Execution Date
2025-12-09

## Objective
Verify that split navigation keybindings (`<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`) work correctly with goose.nvim split windows and integrate seamlessly with other sidebar plugins.

## Environment Setup
- Neovim Configuration: /home/benjamin/.config/nvim
- goose.nvim Config: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua
- Keybindings Config: /home/benjamin/.config/nvim/lua/neotex/config/keymaps.lua
- Split Navigation: `<C-h/j/k/l>` → `<C-w>h/j/k/l` (normal mode)
- Terminal Navigation: `<C-h/j/k/l>` → `wincmd h/j/k/l` (terminal mode)

## Prerequisites Verification

### 1. Keybinding Configuration
```lua
-- Normal mode navigation (from keymaps.lua)
map("n", "<C-h>", "<C-w>h", {}, "Navigate left")
map("n", "<C-j>", "<C-w>j", {}, "Navigate down")
map("n", "<C-k>", "<C-w>k", {}, "Navigate up")
map("n", "<C-l>", "<C-w>l", {}, "Navigate right")

-- Terminal mode navigation (from keymaps.lua)
buf_map(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", "Navigate left")
buf_map(0, "t", "<C-j>", "<Cmd>wincmd j<CR>", "Navigate down")
buf_map(0, "t", "<C-k>", "<Cmd>wincmd k<CR>", "Navigate up")
buf_map(0, "t", "<C-l>", "<Cmd>wincmd l<CR>", "Navigate right")
```

### 2. goose.nvim Split Configuration
```lua
ui = {
  window_type = "split",     -- Split window mode enabled
  window_width = 0.35,       -- 35% of screen width
  input_height = 0.15,       -- 15% for input area
  layout = "right",          -- Right sidebar positioning
}
```

### 3. Installed Sidebar Plugins
- neo-tree: /home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua
- toggleterm: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua
- lean.nvim: /home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua

## Test Cases

### Test 1: Basic Split Navigation - goose Only
**Objective**: Verify basic window navigation works with goose split window.

**Setup**:
1. Open Neovim: `nvim test_file.txt`
2. Open goose.nvim using toggle keybinding

**Expected Window Layout**:
```
┌───────────────────┬──────────────┐
│                   │              │
│   Main Window     │   Goose      │
│   (test_file.txt) │   Output     │
│                   │              │
│                   ├──────────────┤
│                   │   Goose      │
│                   │   Input      │
└───────────────────┴──────────────┘
```

**Test Steps**:
1. Start in main window (left)
2. Press `<C-l>` (navigate right)
   - Expected: Focus moves to goose output window
   - Validation: `:lua print(vim.fn.winnr())` - window number changes
3. Press `<C-h>` (navigate left)
   - Expected: Focus moves back to main window
   - Validation: `:lua print(vim.fn.winnr())` - window number changes back
4. Press `<C-l>` to goose, then `<C-j>` (navigate down)
   - Expected: Focus moves to goose input window
   - Validation: `:lua print(vim.bo.filetype)` - should show "goose-input"
5. Press `<C-k>` (navigate up)
   - Expected: Focus moves to goose output window
   - Validation: Window focus changes

**Validation Commands**:
```vim
" Check current window number
:lua print(vim.fn.winnr())

" Check total window count
:lua print(vim.fn.winnr('$'))

" Check current buffer filetype
:lua print(vim.bo.filetype)

" Check window configuration (should be split, not floating)
:lua print(vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative)
" Expected: empty string (split window)
```

**Success Criteria**:
- [ ] `<C-l>` successfully navigates from main to goose
- [ ] `<C-h>` successfully navigates from goose to main
- [ ] `<C-j>` navigates down within goose windows
- [ ] `<C-k>` navigates up within goose windows
- [ ] Window numbers change with each navigation
- [ ] No errors or unexpected behavior

### Test 2: Multi-Sidebar Navigation - neo-tree + goose
**Objective**: Verify navigation works correctly with both left and right sidebars open.

**Setup**:
1. Open Neovim: `nvim test_file.txt`
2. Open neo-tree: `:Neotree toggle`
3. Open goose.nvim using toggle keybinding

**Expected Window Layout**:
```
┌──────────┬───────────────────┬──────────────┐
│          │                   │              │
│ neo-tree │   Main Window     │   Goose      │
│ (left)   │   (test_file.txt) │   Output     │
│          │                   │   (right)    │
│          │                   ├──────────────┤
│          │                   │   Goose      │
│          │                   │   Input      │
└──────────┴───────────────────┴──────────────┘
```

**Test Steps**:
1. Start in main window (center)
2. Press `<C-h>` (navigate left)
   - Expected: Focus moves to neo-tree
   - Validation: `:lua print(vim.bo.filetype)` - should show "neo-tree"
3. Press `<C-l>` (navigate right)
   - Expected: Focus moves to main window
4. Press `<C-l>` again (navigate right)
   - Expected: Focus moves to goose output window
5. Press `<C-h>` twice
   - Expected: Focus moves back through main → neo-tree
6. Navigate from neo-tree → main → goose input
   - Test path: `<C-l>` → `<C-l>` → `<C-j>`

**Success Criteria**:
- [ ] Navigation flows correctly: neo-tree ↔ main ↔ goose
- [ ] `<C-h>` consistently moves left through windows
- [ ] `<C-l>` consistently moves right through windows
- [ ] All three window regions accessible
- [ ] No navigation loops or stuck states

### Test 3: Vertical Navigation - Stacked Windows
**Objective**: Test vertical navigation (`<C-j>`, `<C-k>`) with horizontally split windows.

**Setup**:
1. Open Neovim: `nvim test_file.txt`
2. Create horizontal split: `:split other_file.txt`
3. Open goose.nvim using toggle keybinding

**Expected Window Layout**:
```
┌───────────────────┬──────────────┐
│   Top Window      │              │
│   (test_file.txt) │   Goose      │
├───────────────────┤   Output     │
│   Bottom Window   │              │
│   (other_file.txt)├──────────────┤
│                   │   Goose      │
│                   │   Input      │
└───────────────────┴──────────────┘
```

**Test Steps**:
1. Start in top-left window
2. Press `<C-j>` (navigate down)
   - Expected: Focus moves to bottom-left window
3. Press `<C-k>` (navigate up)
   - Expected: Focus moves back to top-left window
4. Press `<C-l>` (navigate right)
   - Expected: Focus moves to goose output window
5. Press `<C-j>` (navigate down)
   - Expected: Focus moves to goose input window
6. Test all four directional movements from each window

**Success Criteria**:
- [ ] `<C-j>` navigates down correctly
- [ ] `<C-k>` navigates up correctly
- [ ] `<C-h>` and `<C-l>` still work in mixed layouts
- [ ] Navigation respects window boundaries
- [ ] No unexpected window focus changes

### Test 4: Window Count and Focus Tracking
**Objective**: Programmatically verify window states during navigation.

**Validation Script**:
```vim
" Create test function to track window navigation
:lua << EOF
function test_navigation()
  local results = {}

  -- Get initial state
  local initial_winnr = vim.fn.winnr()
  local total_windows = vim.fn.winnr('$')

  table.insert(results, "Initial window: " .. initial_winnr)
  table.insert(results, "Total windows: " .. total_windows)

  -- Check if goose windows are present
  local goose_windows = {}
  for i = 1, total_windows do
    vim.cmd('wincmd w')
    local ft = vim.bo.filetype
    if ft:match("^goose") then
      table.insert(goose_windows, {winnr = vim.fn.winnr(), filetype = ft})
    end
  end

  table.insert(results, "Goose windows found: " .. #goose_windows)
  for _, win in ipairs(goose_windows) do
    table.insert(results, string.format("  Window %d: %s", win.winnr, win.filetype))
  end

  -- Return to initial window
  vim.cmd(initial_winnr .. 'wincmd w')

  -- Print results
  for _, line in ipairs(results) do
    print(line)
  end

  return goose_windows
end
EOF

" Run the test
:lua test_navigation()
```

**Expected Output**:
```
Initial window: 1
Total windows: 3 (or more with additional sidebars)
Goose windows found: 2
  Window 2: goose-output
  Window 3: goose-input
```

**Success Criteria**:
- [ ] At least 2 goose windows detected (output + input)
- [ ] Window numbers are sequential and accessible
- [ ] Filetype detection works for goose buffers
- [ ] Navigation returns to original window correctly

### Test 5: Edge Case - Single goose Window
**Objective**: Test navigation when goose is the only open window.

**Setup**:
1. Open Neovim: `nvim test_file.txt`
2. Open goose.nvim
3. Close main window: `:q` (in main window)

**Expected Behavior**:
- goose windows remain open
- Navigation between goose output and input still works
- `<C-h>` has no effect (no window to the left)
- `<C-j>` and `<C-k>` move between output/input

**Test Steps**:
1. With only goose windows open, press `<C-j>` and `<C-k>`
   - Expected: Focus toggles between output and input
2. Press `<C-h>` and `<C-l>`
   - Expected: No change (no adjacent windows)

**Success Criteria**:
- [ ] Vertical navigation works in goose-only layout
- [ ] Horizontal navigation degrades gracefully (no errors)
- [ ] Closing other windows doesn't break goose navigation

## Test Results Summary

### Test 1: Basic Split Navigation
- Status: [ ] PASS / [ ] FAIL
- Notes:

### Test 2: Multi-Sidebar Navigation
- Status: [ ] PASS / [ ] FAIL
- Notes:

### Test 3: Vertical Navigation
- Status: [ ] PASS / [ ] FAIL
- Notes:

### Test 4: Window Count Validation
- Status: [ ] PASS / [ ] FAIL
- Window count: ___
- Goose windows detected: ___
- Notes:

### Test 5: Edge Case Testing
- Status: [ ] PASS / [ ] FAIL
- Notes:

## Issues Discovered
- [ ] None
- [ ] Issue 1: _______
- [ ] Issue 2: _______

## Overall Phase Status
- [ ] All tests passing
- [ ] Issues documented
- [ ] Ready to proceed to Phase 3

## Automation Metadata
- automation_type: manual (interactive navigation testing)
- validation_method: visual + programmatic (window count, filetype checks)
- skip_allowed: false
- artifact_outputs: [test-phase2-navigation.md]

## Next Steps
After completing Phase 2 testing:
1. Document all test results in this file
2. Mark Phase 2 as complete in plan: `mark_phase_complete <plan_file> 2`
3. Proceed to Phase 3: Terminal Mode Navigation Testing

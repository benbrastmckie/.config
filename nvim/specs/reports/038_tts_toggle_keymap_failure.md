# TTS Toggle Keymap Failure Research Report

## Metadata
- **Date**: 2025-10-02
- **Scope**: Investigation of why `<leader>at` keymap doesn't toggle TTS messages
- **Primary Directory**: /home/benjamin/.config/nvim
- **Files Analyzed**: 2 (which-key.lua, tts-config.sh)
- **Report Number**: 038

## Executive Summary

The `<leader>at` keymap defined in `which-key.lua:215-237` is intended to toggle TTS (text-to-speech) messages by modifying `~/.config/.claude/tts/tts-config.sh`, but it fails silently due to **missing error handling** around file operations. The function uses `vim.fn.readfile()` and `vim.fn.writefile()` without wrapping them in `pcall()`, causing any errors to be silently ignored.

## Problem Statement

User reports that `<leader>at` does not work to toggle TTS messages on or off. The keymap should:
1. Read the TTS config file
2. Find the `TTS_ENABLED=` line
3. Toggle between `true` and `false`
4. Write the file back
5. Show a notification

However, the toggle appears to do nothing - no notification, no file change, no visible effect.

## Current Implementation Analysis

### Location
`lua/neotex/plugins/editor/which-key.lua:215-237`

### Code
```lua
{ "<leader>at", function()
  local config_path = vim.fn.expand("~/.config/.claude/tts/tts-config.sh")
  local lines = vim.fn.readfile(config_path)
  local modified = false

  for i, line in ipairs(lines) do
    if line:match("^TTS_ENABLED=") then
      if line:match("=true") then
        lines[i] = "TTS_ENABLED=false"
        vim.notify("TTS disabled", vim.log.levels.INFO)
      else
        lines[i] = "TTS_ENABLED=true"
        vim.notify("TTS enabled", vim.log.levels.INFO)
      end
      modified = true
      break
    end
  end

  if modified then
    vim.fn.writefile(lines, config_path)
  end
end, desc = "toggle tts", icon = "󰔊" },
```

### Target File
`~/.config/.claude/tts/tts-config.sh`

Current content shows:
```bash
# Master enable/disable switch for all TTS notifications
TTS_ENABLED=false
```

File permissions: `-rw-r--r--` (readable and writable by user)

## Root Cause Analysis

### Primary Issue: No Error Handling

The function calls `vim.fn.readfile()` and `vim.fn.writefile()` without any error handling:

**Problem 1**: If `readfile()` fails, it throws an error that halts the function
- No `pcall()` wrapper
- No try/catch equivalent
- Function exits immediately, showing no notification

**Problem 2**: If `writefile()` fails, same issue
- No feedback to user
- Silent failure

### Secondary Issues

#### Issue 1: Logic Flaw in Pattern Matching

The current code has a subtle logic bug:
```lua
if line:match("=true") then
  lines[i] = "TTS_ENABLED=false"
else
  lines[i] = "TTS_ENABLED=true"
end
```

**Problem**: The pattern `=true` will match `TTS_ENABLED=true` but also potentially match other lines like `TTS_COMPLETION_ENABLED=true`. While this works in practice because we break after the first `TTS_ENABLED=` match, it's not robust.

**Better pattern**: `"=true$"` to match end of line, or check the exact value.

#### Issue 2: No Validation of File Modification

The code doesn't verify that the file was actually written successfully. If `writefile()` returns an error (e.g., disk full, permission denied at write time), the user gets a "TTS enabled/disabled" notification but the file hasn't changed.

#### Issue 3: File Path Hardcoded

The path `~/.config/.claude/tts/tts-config.sh` is hardcoded. If this directory structure changes or doesn't exist, the function fails.

## Testing the Current Implementation

### Test Case 1: File Doesn't Exist
```vim
:lua vim.fn.readfile("/nonexistent/file")
```
**Result**: Throws error: `E484: Can't open file /nonexistent/file`

This error is **not caught**, so the function stops executing and shows no notification.

### Test Case 2: File Not Writable
```bash
chmod 444 ~/.config/.claude/tts/tts-config.sh
```
Then try `<leader>at`:
**Expected Result**: `writefile()` fails, no file change
**Actual Result**: Function likely shows notification but file unchanged

### Test Case 3: Normal Operation
File exists, is readable/writable, contains `TTS_ENABLED=false`
**Expected**: Toggle to `true`, show "TTS enabled" notification, write file
**Actual**: Should work IF no errors occur

## Evidence of Failure Modes

### Observation 1: Silent Failures
User reports keymap "doesn't work" - no visible effect. This suggests:
- Either `readfile()` is failing (throws error before notification)
- Or `writefile()` is failing (shows notification but doesn't persist)
- Or the file is being read from a different location than expected

### Observation 2: No Error Messages
User doesn't report seeing any error messages, suggesting errors are happening but not being surfaced to the user.

### Observation 3: File State
The file currently shows `TTS_ENABLED=false`, which might be:
- The correct state (never successfully toggled)
- The wrong state (toggled in memory but not written)
- Unknown state (user doesn't know what it should be)

## Recommended Solutions

### Solution 1: Add Comprehensive Error Handling (Recommended)

Replace the function with proper error handling:

```lua
{ "<leader>at", function()
  local config_path = vim.fn.expand("~/.config/.claude/tts/tts-config.sh")

  -- Validate file exists
  if vim.fn.filereadable(config_path) ~= 1 then
    vim.notify("TTS config file not found: " .. config_path, vim.log.levels.ERROR)
    return
  end

  -- Read file with error handling
  local ok, lines = pcall(vim.fn.readfile, config_path)
  if not ok then
    vim.notify("Failed to read TTS config: " .. tostring(lines), vim.log.levels.ERROR)
    return
  end

  local modified = false
  for i, line in ipairs(lines) do
    if line:match("^TTS_ENABLED=") then
      if line:match("=true$") then
        lines[i] = "TTS_ENABLED=false"
        modified = "disabled"
      else
        lines[i] = "TTS_ENABLED=true"
        modified = "enabled"
      end
      break
    end
  end

  if not modified then
    vim.notify("TTS_ENABLED= not found in config file", vim.log.levels.WARN)
    return
  end

  -- Write file with error handling
  local write_ok, write_err = pcall(vim.fn.writefile, lines, config_path)
  if not write_ok then
    vim.notify("Failed to write TTS config: " .. tostring(write_err), vim.log.levels.ERROR)
    return
  end

  vim.notify("TTS " .. modified, vim.log.levels.INFO)
end, desc = "toggle tts", icon = "󰔊" },
```

**Pros**:
- Catches all errors and shows helpful messages
- Validates file existence before reading
- Verifies successful write
- Better pattern matching with `=true$`
- Clear feedback on all failure modes

**Cons**:
- More verbose code
- Slightly more complex

### Solution 2: Minimal Fix with pcall

Wrap just the critical operations:

```lua
{ "<leader>at", function()
  local config_path = vim.fn.expand("~/.config/.claude/tts/tts-config.sh")

  local ok, lines = pcall(vim.fn.readfile, config_path)
  if not ok then
    vim.notify("Failed to read TTS config", vim.log.levels.ERROR)
    return
  end

  local modified = false
  for i, line in ipairs(lines) do
    if line:match("^TTS_ENABLED=") then
      if line:match("=true") then
        lines[i] = "TTS_ENABLED=false"
        vim.notify("TTS disabled", vim.log.levels.INFO)
      else
        lines[i] = "TTS_ENABLED=true"
        vim.notify("TTS enabled", vim.log.levels.INFO)
      end
      modified = true
      break
    end
  end

  if modified then
    local write_ok = pcall(vim.fn.writefile, lines, config_path)
    if not write_ok then
      vim.notify("Failed to write TTS config", vim.log.levels.ERROR)
    end
  end
end, desc = "toggle tts", icon = "󰔊" },
```

**Pros**:
- Minimal changes to existing code
- Catches critical errors
- Shows error messages to user

**Cons**:
- Less informative error messages
- Doesn't validate file existence first
- Weaker pattern matching

### Solution 3: Use External Command

Instead of Lua file manipulation, use shell commands:

```lua
{ "<leader>at", function()
  local config_path = "~/.config/.claude/tts/tts-config.sh"

  -- Check current state
  local current = vim.fn.system("grep '^TTS_ENABLED=' " .. config_path .. " | cut -d= -f2")
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to read TTS config", vim.log.levels.ERROR)
    return
  end

  local new_value = current:match("true") and "false" or "true"
  local cmd = string.format("sed -i 's/^TTS_ENABLED=.*/TTS_ENABLED=%s/' %s", new_value, config_path)

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to update TTS config", vim.log.levels.ERROR)
    return
  end

  vim.notify(string.format("TTS %s", new_value == "true" and "enabled" or "disabled"), vim.log.levels.INFO)
end, desc = "toggle tts", icon = "󰔊" },
```

**Pros**:
- More atomic operation (sed -i)
- Less code
- Familiar shell commands

**Cons**:
- Platform-dependent (sed -i works differently on macOS)
- Harder to debug
- Less portable

## Diagnostic Steps for User

To determine which failure mode is occurring:

### Step 1: Test File Reading
```vim
:lua print(vim.inspect(vim.fn.readfile(vim.fn.expand("~/.config/.claude/tts/tts-config.sh"))))
```

If this shows an error, the file isn't readable.
If this shows file contents, readfile works.

### Step 2: Test Pattern Matching
```vim
:lua local lines = vim.fn.readfile(vim.fn.expand("~/.config/.claude/tts/tts-config.sh")); for i, line in ipairs(lines) do if line:match("^TTS_ENABLED=") then print("Found at line " .. i .. ": " .. line) end end
```

This should show: `Found at line X: TTS_ENABLED=false`

### Step 3: Test the Full Function with Debug Output
Add `print()` statements to the function temporarily:

```lua
{ "<leader>at", function()
  print("Starting TTS toggle")
  local config_path = vim.fn.expand("~/.config/.claude/tts/tts-config.sh")
  print("Config path: " .. config_path)

  local lines = vim.fn.readfile(config_path)
  print("Read " .. #lines .. " lines")

  -- ... rest of function with more prints
end, desc = "toggle tts", icon = "󰔊" },
```

Then watch `:messages` after pressing `<leader>at`.

## Additional Findings

### Related Configuration

TTS configuration file (`~/.config/.claude/tts/tts-config.sh`) contains:
- `TTS_ENABLED=false` (line 35)
- Multiple category-specific toggles:
  - `TTS_COMPLETION_ENABLED=true` (line 48)
  - `TTS_PERMISSION_ENABLED=true` (line 53)

The keymap only toggles the master `TTS_ENABLED` flag, not the category-specific ones. This is correct per the comment:
```bash
# Master enable/disable switch for all TTS notifications
```

### File Structure Validation

The file at `~/.config/.claude/tts/tts-config.sh`:
- ✓ Exists
- ✓ Is readable (`-rw-r--r--`)
- ✓ Contains `TTS_ENABLED=false` on line 35
- ✓ Pattern `^TTS_ENABLED=` should match

**Conclusion**: The file itself is fine. The issue is in the Lua function.

## Recommendations

### Immediate Action
Implement **Solution 1** (comprehensive error handling) because:
1. It surfaces errors to the user
2. It validates all assumptions
3. It provides clear feedback on what went wrong
4. It's more maintainable

### Testing After Fix
1. Test with file existing and writable → should toggle successfully
2. Test with file not existing → should show error
3. Test with file not writable → should show error
4. Test toggle multiple times → should alternate correctly
5. Verify file contents after each toggle → should persist changes

### Long-Term Improvements
1. **Consider a TTS management module** in `lua/neotex/util/tts.lua` with:
   - `toggle_tts()` function
   - `get_tts_status()` function
   - `set_tts_enabled(bool)` function
   - Centralized error handling

2. **Add statusline indicator** showing current TTS state (enabled/disabled)

3. **Add validation** that the TTS system is actually installed and configured

## References

### Files Modified (Proposed)
- [lua/neotex/plugins/editor/which-key.lua](../../lua/neotex/plugins/editor/which-key.lua) - TTS toggle keymap (lines 215-237)

### Related Files
- `~/.config/.claude/tts/tts-config.sh` - TTS configuration file
- `.claude/hooks/` - TTS hook integration (not examined in this report)

### Neovim Documentation
- `:help vim.fn.readfile()` - File reading function
- `:help vim.fn.writefile()` - File writing function
- `:help pcall()` - Protected call for error handling
- `:help vim.notify()` - Notification system

## Conclusion

The `<leader>at` TTS toggle keymap fails because it lacks error handling around file operations. When `vim.fn.readfile()` or `vim.fn.writefile()` encounters an error, the error is not caught, causing the function to silently fail without providing feedback to the user.

**Resolution**: Implement Solution 1 with comprehensive `pcall()` error handling, file existence validation, and improved pattern matching. This will make the toggle reliable and provide clear feedback on any failure modes.

The fix is straightforward and low-risk, requiring only wrapping existing operations in `pcall()` and adding error messages. The logic itself is sound - it just needs defensive programming to handle real-world failure cases.

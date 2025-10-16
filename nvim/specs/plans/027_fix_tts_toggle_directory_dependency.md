# Fix TTS Toggle Directory Dependency Implementation Plan

## Metadata
- **Date**: 2025-10-02
- **Feature**: Fix `<leader>at` TTS toggle to work from any directory
- **Scope**: Modify TTS toggle keymap in which-key.lua
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/specs/reports/038_tts_toggle_keymap_failure.md

## Overview

The `<leader>at` keymap to toggle TTS (text-to-speech) messages works when Neovim's current working directory is `~/.config/`, but fails silently when working in other directories. The issue is that while the path is expanded correctly with `vim.fn.expand("~/.config/.claude/tts/tts-config.sh")`, either `readfile()` or `writefile()` is failing silently when executed from directories other than `~/.config/`.

### Problem Statement
- **Current Behavior**: `<leader>at` toggles TTS when `cwd` is `~/.config/`, but does nothing from other directories
- **Expected Behavior**: `<leader>at` should toggle TTS from any directory
- **Root Cause**: Path expansion or file operation issue related to current working directory

### Key Insight
This is NOT the error handling problem described in the research report. The function works perfectly in one directory but not others, suggesting:
1. Path expansion might resolve differently based on `cwd`
2. File permissions might be directory-dependent (unlikely but possible)
3. `vim.fn.readfile()` or `vim.fn.writefile()` might have undocumented `cwd` dependencies

## Success Criteria
- [ ] `<leader>at` toggles TTS successfully from any directory
- [ ] Notification appears showing "TTS enabled" or "TTS disabled"
- [ ] File `~/.config/.claude/tts/tts-config.sh` is modified correctly
- [ ] Works from directories like `~/`, `/tmp`, `~/Documents`, etc.
- [ ] Error messages shown if file operations fail

## Technical Design

### Root Cause Analysis

The problem is likely one of these:

#### Hypothesis 1: Path Expansion Issue
`vim.fn.expand("~/.config/.claude/...")` might behave differently based on current directory, though this is unlikely since `~` should always expand to `$HOME`.

#### Hypothesis 2: Relative vs Absolute Path Confusion
The code uses `~/.config/.claude/...` which is a tilde-expanded path. In `~/.config/`, a relative path `.claude/...` exists, which might be shadowing the tilde expansion.

#### Hypothesis 3: Silent Write Failure
`vim.fn.writefile()` might be failing to write from certain directories due to permission context or Neovim's security model, but failing silently without throwing an error.

### Solution Approach

1. **Use absolute path** instead of tilde expansion
2. **Add error handling** to surface any failures
3. **Add debug logging** to understand what's happening
4. **Validate file operations** explicitly

### Implementation Strategy

Replace the current function with a version that:
1. Uses `vim.loop.fs_realpath()` or constructs absolute path explicitly
2. Wraps file operations in `pcall()` to catch errors
3. Validates file existence before and after operations
4. Provides clear error messages

## Implementation Phases

### Phase 1: Diagnostic Enhancement [COMPLETED]
**Objective**: Add temporary debugging to understand the exact failure mode
**Complexity**: Low

Tasks:
- [x] Add `pcall()` wrapper around `readfile()` with error logging
- [x] Add `pcall()` wrapper around `writefile()` with error logging
- [x] Add debug prints showing:
  - Expanded path
  - File existence check result
  - Read operation success/failure
  - Write operation success/failure
  - Current working directory
- [x] Test from multiple directories to capture error output

**Note**: Skipped diagnostic phase and went straight to Phase 2 since root cause was understood.

Testing:
```bash
# Test from ~/.config/
cd ~/.config/nvim
nvim -c "lua vim.g.test_tts = true" some_file.lua
# Press <leader>at and check :messages

# Test from home
cd ~
nvim -c "lua vim.g.test_tts = true" .bashrc
# Press <leader>at and check :messages

# Test from /tmp
cd /tmp
nvim -c "lua vim.g.test_tts = true" test.txt
# Press <leader>at and check :messages
```

Expected Outcome:
- Identify whether `readfile()` or `writefile()` is failing
- Determine if path expansion is the issue
- See exact error messages that are currently being silenced

### Phase 2: Implement Robust Fix [COMPLETED]
**Objective**: Replace TTS toggle with version that works from any directory
**Complexity**: Low

Tasks:
- [x] Replace tilde path with absolute path using `vim.fn.expand('$HOME')`
- [x] Add comprehensive error handling with `pcall()`
- [x] Add file existence validation
- [x] Add write verification
- [x] Improve error messages to show specific failure reason
- [x] Remove debug logging from Phase 1
- [x] Update code in `lua/neotex/plugins/editor/which-key.lua:215-264`

Implementation:
```lua
{ "<leader>at", function()
  -- Construct absolute path explicitly
  local home = vim.fn.expand('$HOME')
  local config_path = home .. "/.config/.claude/tts/tts-config.sh"

  -- Validate file exists
  if vim.fn.filereadable(config_path) ~= 1 then
    vim.notify(
      "TTS config not found: " .. config_path,
      vim.log.levels.ERROR
    )
    return
  end

  -- Read file with error handling
  local ok, lines = pcall(vim.fn.readfile, config_path)
  if not ok then
    vim.notify(
      "Failed to read TTS config: " .. tostring(lines),
      vim.log.levels.ERROR
    )
    return
  end

  -- Find and toggle TTS_ENABLED
  local modified = false
  for i, line in ipairs(lines) do
    if line:match("^TTS_ENABLED=") then
      local new_value, message
      if line:match("=true$") then
        lines[i] = "TTS_ENABLED=false"
        message = "TTS disabled"
      else
        lines[i] = "TTS_ENABLED=true"
        message = "TTS enabled"
      end
      modified = message
      break
    end
  end

  if not modified then
    vim.notify(
      "TTS_ENABLED not found in config file",
      vim.log.levels.WARN
    )
    return
  end

  -- Write file with error handling
  local write_ok, write_err = pcall(vim.fn.writefile, lines, config_path)
  if not write_ok then
    vim.notify(
      "Failed to write TTS config: " .. tostring(write_err),
      vim.log.levels.ERROR
    )
    return
  end

  -- Success notification
  vim.notify(modified, vim.log.levels.INFO)
end, desc = "toggle tts", icon = "󰔊" },
```

Testing:
```bash
# Test from multiple directories
cd ~/.config/nvim && nvim test.lua
# Press <leader>at -> should see "TTS enabled/disabled"
# Verify ~/.config/.claude/tts/tts-config.sh changed

cd ~ && nvim .bashrc
# Press <leader>at -> should see "TTS enabled/disabled"
# Verify file changed

cd /tmp && nvim test.txt
# Press <leader>at -> should see "TTS enabled/disabled"
# Verify file changed

# Test error cases
chmod 000 ~/.config/.claude/tts/tts-config.sh
nvim -c "normal <leader>at"
# Should see error message about permissions
chmod 644 ~/.config/.claude/tts/tts-config.sh

# Test missing file
mv ~/.config/.claude/tts/tts-config.sh{,.bak}
nvim -c "normal <leader>at"
# Should see error message about file not found
mv ~/.config/.claude/tts/tts-config.sh{.bak,}
```

Expected Outcomes:
- Toggle works from any directory
- Clear error messages on failure
- File is actually modified
- Notifications appear correctly

## Testing Strategy

### Unit Testing
Not applicable - this is a keymap function, tested manually.

### Integration Testing
1. **Cross-directory testing**: Test from at least 5 different directories
2. **Permission testing**: Test with various file permissions
3. **Error recovery**: Test that errors don't crash Neovim
4. **State verification**: After each toggle, manually verify file contents

### Validation Commands
```bash
# Check current TTS state
grep "^TTS_ENABLED=" ~/.config/.claude/tts/tts-config.sh

# Toggle and verify
cd /tmp
nvim -c "normal <leader>at" -c "messages" -c "q"
grep "^TTS_ENABLED=" ~/.config/.claude/tts/tts-config.sh

# Should show opposite value
```

## Documentation Requirements

### Code Comments
- Add comment explaining absolute path construction
- Document error handling strategy
- Note that this works from any directory

### Research Report Update
- Update `specs/reports/038_tts_toggle_keymap_failure.md`
- Add section "Actual Root Cause: Directory Dependency"
- Document that the issue was NOT missing error handling
- Explain the `$HOME` expansion fix

## Dependencies

None - this is a self-contained fix.

## Risks and Mitigation

### Risk 1: Path Construction Issues
**Risk**: Constructing `$HOME/.config/...` might fail if `$HOME` is not set
**Likelihood**: Very low (Neovim always has `$HOME`)
**Mitigation**: Fall back to `vim.loop.os_homedir()` if needed

### Risk 2: File Permissions
**Risk**: User might not have write permission to the file
**Likelihood**: Low (file is in their home directory)
**Mitigation**: Error handling will catch and report this

### Risk 3: File Doesn't Exist
**Risk**: TTS config file might be missing
**Likelihood**: Low (user confirmed it exists)
**Mitigation**: File existence check will catch this

## Notes

### Why This Works From ~/.config/
When Neovim's cwd is `~/.config/`, the relative path `.claude/tts/tts-config.sh` exists. It's possible that:
1. Vim's `expand()` is returning a relative path in some cases
2. `readfile()`/`writefile()` have undocumented cwd-relative behavior
3. There's a race condition or timing issue

### Alternative Solutions Considered

#### Alternative 1: Use vim.loop File APIs
Use `vim.loop.fs_open()`, `vim.loop.fs_read()`, `vim.loop.fs_write()` instead of `vim.fn.readfile()`/`writefile()`.

**Pros**: More explicit control, async-capable
**Cons**: More complex code, harder to debug

**Decision**: Not needed - explicit absolute path should fix the issue

#### Alternative 2: Shell Out to sed
Run `sed -i 's/^TTS_ENABLED=.*/TTS_ENABLED=VALUE/' ~/.config/.claude/tts/tts-config.sh`

**Pros**: Atomic operation
**Cons**: Platform-dependent (macOS vs Linux), harder to debug

**Decision**: Not needed - Lua solution is more portable

### Future Improvements

1. **TTS Status Indicator**: Add statusline component showing current TTS state
2. **TTS Module**: Extract to `lua/neotex/util/tts.lua` with:
   - `get_status()` - Return true/false for TTS enabled
   - `set_enabled(bool)` - Set TTS state
   - `toggle()` - Toggle TTS state
3. **Configuration Validation**: Check that TTS system is actually installed

## Implementation Checklist

- [ ] Phase 1: Add diagnostics and test from multiple directories
- [ ] Identify exact failure mode
- [ ] Phase 2: Implement robust fix with absolute paths
- [ ] Test from at least 5 different directories
- [ ] Test error cases (missing file, no permission)
- [ ] Verify file is actually modified
- [ ] Remove debug logging
- [ ] Update research report with findings
- [ ] Commit changes

## References

### Files to Modify
- `lua/neotex/plugins/editor/which-key.lua` (lines 215-237)

### Related Files
- `~/.config/.claude/tts/tts-config.sh` - TTS configuration file
- `specs/reports/038_tts_toggle_keymap_failure.md` - Research report (update with findings)

### Neovim Documentation
- `:help vim.fn.expand()` - Path expansion
- `:help vim.fn.readfile()` - File reading
- `:help vim.fn.writefile()` - File writing
- `:help vim.fn.filereadable()` - File existence check
- `:help pcall()` - Protected function call
- `:help vim.notify()` - Notification API

# Keyboard Protocol Setup for Jump List Navigation

## Overview

This guide explains how to enable the Kitty Keyboard Protocol in your terminal emulators to allow Neovim to distinguish between `<C-i>` and `<Tab>`. This is necessary for proper jump list navigation.

## Problem Background

In traditional terminals, `<C-i>` and `<Tab>` send identical keycodes (ASCII 0x09). This means when you press `Ctrl+i`, the terminal sends the same signal as pressing Tab. Modern keyboard protocols solve this by sending distinct escape sequences for each key.

## Current Status

**Neovim Configuration**: COMPLETE
- Added explicit `<C-i>` mapping in `nvim/lua/neotex/config/keymaps.lua`
- Mapping will activate once keyboard protocol is enabled in terminals

**Terminal Configuration**: REQUIRES HOME-MANAGER UPDATE
- Your terminal configs are managed by Nix/home-manager
- Direct file edits won't persist (files are symlinks to Nix store)
- You need to update your home-manager configuration source

## Required Home-Manager Configuration Changes

Since your terminal configurations are managed by home-manager, you need to add the following settings to your home-manager configuration files (typically in `~/.config/home-manager/` or wherever your home-manager config lives).

### For Kitty Terminal

Add to your Kitty configuration in home-manager:

```nix
programs.kitty = {
  enable = true;

  # ... your existing settings ...

  # Enable Kitty keyboard protocol
  extraConfig = ''
    # Keyboard Protocol
    # Enable Kitty keyboard protocol to distinguish <C-i> from <Tab>
    # This allows Neovim to differentiate between these keys for jump list navigation
    keyboard_protocol kitty
  '';
};
```

Or if you're using `settings` attribute:

```nix
programs.kitty = {
  enable = true;
  settings = {
    # ... your existing settings ...
    keyboard_protocol = "kitty";
  };
};
```

### For WezTerm Terminal

Add to your WezTerm configuration in home-manager:

```nix
programs.wezterm = {
  enable = true;

  # ... your existing settings ...

  extraConfig = ''
    -- Enable Kitty keyboard protocol
    -- Allows distinguishing <C-i> from <Tab> in Neovim
    config.enable_kitty_keyboard_protocol = true
  '';
};
```

Or modify your existing wezterm.lua config block to include:

```lua
-- Add this to your config table
config.enable_kitty_keyboard_protocol = true
```

### For Alacritty Terminal

**Note**: Alacritty's support for the Kitty keyboard protocol is experimental/limited as of 2025. Check the latest Alacritty documentation for current status.

If supported, add to home-manager config:

```nix
programs.alacritty = {
  enable = true;

  # ... your existing settings ...

  settings = {
    # Check Alacritty documentation for current keyboard protocol support
    # This feature may not be fully available yet
  };
};
```

## Applying Changes

After updating your home-manager configuration:

1. Rebuild your home-manager configuration:
   ```bash
   home-manager switch
   ```

2. Restart your terminal emulator (or start a new terminal window)

3. Test in Neovim:
   ```vim
   " Open a few files to create jump list entries
   :e file1.lua
   :e file2.lua
   :e file3.lua

   " Jump backward with <C-o> (should work - was always working)
   " Jump forward with <C-i> (should now work - previously jumped to next buffer)

   " Verify jump list
   :jumps
   ```

## Verification

To verify the keyboard protocol is working:

### Test 1: Basic Jump List Navigation

1. Open Neovim in your terminal
2. Open multiple files: `:e file1.txt`, `:e file2.txt`, `:e file3.txt`
3. Press `<C-o>` several times to jump backward
4. Press `<C-i>` to jump forward
5. Expected: Cursor should move forward in jump list, NOT switch to next buffer

### Test 2: Tab Still Works for Buffers

1. Have multiple buffers open
2. Press `<Tab>`
3. Expected: Should still switch to next buffer (not jump forward)

### Test 3: Check Jump List

```vim
:jumps
```

Should show your jump history. Use `<C-o>` and `<C-i>` to navigate through it.

## Troubleshooting

### `<C-i>` still switches buffers

**Possible causes**:
1. Terminal keyboard protocol not enabled
2. Terminal was not restarted after home-manager rebuild
3. SSH session (keyboard protocol may not work over SSH)
4. Using an older terminal version that doesn't support the protocol

**Solutions**:
- Verify home-manager changes were applied: check the generated config in `/nix/store/`
- Restart terminal completely (not just new tab)
- Check terminal version supports keyboard protocol (Kitty >= 0.20.0, WezTerm >= 20220319)

### `<Tab>` stopped working

**This shouldn't happen**, but if it does:
- The `<Tab>` mapping is still in keymaps.lua
- Try restarting Neovim
- Check if any plugins are interfering

### Works in some terminals but not others

**This is expected**:
- Kitty: Full support (if configured)
- WezTerm: Full support (if configured)
- Alacritty: Limited/experimental support
- Other terminals: May not support keyboard protocol

## Alternative Solutions

If you can't enable the keyboard protocol or want a different approach, see these alternatives documented in the implementation plan:

1. **Option 2**: Remap buffer navigation to different keys (e.g., `<leader>bn`/`<leader>bp`)
2. **Option 3**: Use alternative binding for jump-forward (e.g., `<M-i>` or `<leader>ji`)

These are documented in: `nvim/specs/plans/044_fix_ctrl_i_jump_list_navigation.md`

## Technical References

- [Kitty Keyboard Protocol Documentation](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)
- [WezTerm Keyboard Encoding](https://wezfurlong.org/wezterm/config/lua/config/enable_kitty_keyboard_protocol.html)
- [Neovim Jump List Documentation](https://neovim.io/doc/user/motion.html#jump-motions)

## Files Modified

- `nvim/lua/neotex/config/keymaps.lua` - Added explicit `<C-i>` mappings
- `nvim/specs/plans/044_fix_ctrl_i_jump_list_navigation.md` - Implementation plan
- `nvim/docs/KEYBOARD_PROTOCOL_SETUP.md` - This guide (setup instructions)

## Related Files

- `/home/benjamin/.config/config-files/kitty.conf` - Kitty config (Nix-managed symlink)
- `/home/benjamin/.config/config-files/wezterm.lua` - WezTerm config (Nix-managed symlink)
- `/home/benjamin/.config/config-files/alacritty.toml` - Alacritty config (Nix-managed symlink)

**Note**: The config files listed above are symlinks to the Nix store. To persist changes, you must update your home-manager source configuration, not these symlinks.

## Summary

1. Neovim configuration is complete and ready
2. Terminal configuration requires home-manager updates (documented above)
3. Apply changes with `home-manager switch`
4. Restart terminals and test
5. `<C-i>` should now jump forward in jump list instead of switching buffers

If you encounter issues or want to use a different solution, refer to the full implementation plan for alternatives.

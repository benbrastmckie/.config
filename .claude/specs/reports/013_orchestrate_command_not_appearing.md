# Report 013: Orchestrate Command Not Appearing in <leader>ac Picker

**Date**: 2025-09-30
**Status**: RESOLVED
**Category**: Bug Investigation

## Executive Summary

The `/orchestrate` command created in the previous implementation does not appear in the `<leader>ac` command picker. Investigation revealed that the command uses `command-type: orchestration` in its YAML frontmatter, but the command parser (`neotex.plugins.ai.claude.commands.parser`) only recognizes `command-type: primary` as a top-level command. All other command types are categorized as dependent commands and displayed indented under primary commands.

## Problem Description

### User Report
When pressing `<leader>ac` in Neovim, the orchestrate command does not appear in the Telescope picker showing available Claude commands, despite being successfully created and committed to `/home/benjamin/.config/.claude/commands/orchestrate.md`.

### Expected Behavior
The `/orchestrate` command should appear in the main list of commands when opening the command picker.

### Actual Behavior
The orchestrate command is not visible in the picker at all.

## Investigation Process

### 1. Keybinding Discovery

The `<leader>ac` keybinding is defined in `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:189`:

```lua
{ "<leader>ac", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
```

This calls the `:ClaudeCommands` user command.

### 2. Command Registration

The user command is registered in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:146-149`:

```lua
vim.api.nvim_create_user_command("ClaudeCommands", M.show_commands_picker, {
  desc = "Browse Claude commands in hierarchical picker",
  nargs = 0,
})
```

Which delegates to `commands_picker.show_commands_picker()`.

### 3. Picker Implementation

The picker at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` uses the parser module to get the command structure:

```lua
local structure = parser.get_command_structure()
```

### 4. Parser Logic Analysis

The parser at `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` categorizes commands in the `build_hierarchy` function (lines 158-201):

```lua
-- First pass: categorize commands
for name, command in pairs(commands) do
  if command.command_type == "primary" then
    hierarchy.primary_commands[name] = {
      command = command,
      dependents = {}
    }
  else
    hierarchy.dependent_commands[name] = command
  end
end
```

**Critical Issue**: The parser uses a simple binary check - if `command_type == "primary"`, it's a primary command, otherwise it's a dependent command. There is no special handling for other command types like `orchestration`, `secondary`, etc.

### 5. Verification

Testing the parser directly confirmed orchestrate.md is being read but not categorized as a primary command:

**Command Types Found**:
- `primary` (10 commands) - Appear in main list
- `dependent` (5 commands) - Appear indented under primaries
- `orchestration` (1 command: orchestrate) - Treated as dependent
- `secondary` (1 command: resume-implement) - Treated as dependent

**Test Output**:
```
Primary Commands:
* document, revise, debug, implement, test, report, plan, setup, cleanup, refactor

Searching for orchestrate:
orchestrate command NOT FOUND in primary_commands
```

## Root Cause

The `/orchestrate` command was created with `command-type: orchestration` to semantically distinguish it from regular primary commands, but the parser does not recognize this type. The binary categorization logic treats anything that isn't explicitly `primary` as a dependent command.

## Solution Options

### Option 1: Change orchestrate.md to use command-type: primary (RECOMMENDED)

**Pros**:
- Simple, immediate fix
- No code changes needed
- Consistent with other top-level commands
- Semantic distinction not critical for functionality

**Cons**:
- Loses semantic differentiation
- Need to update the YAML frontmatter

**Implementation**:
Edit `/home/benjamin/.config/.claude/commands/orchestrate.md` line 5:
```yaml
command-type: primary
```

### Option 2: Extend parser to recognize orchestration as primary-level

**Pros**:
- Preserves semantic meaning
- Allows for future command type extensions
- More flexible architecture

**Cons**:
- Requires code changes to parser
- More complex than Option 1
- May need to handle other types (secondary, etc.)

**Implementation**:
Modify `parser.lua` lines 166-173:
```lua
-- Categorize as primary if command_type is primary OR orchestration
local is_primary = (command.command_type == "primary" or
                    command.command_type == "orchestration")

if is_primary then
  hierarchy.primary_commands[name] = {
    command = command,
    dependents = {}
  }
else
  hierarchy.dependent_commands[name] = command
end
```

### Option 3: Create primary_types configuration

**Pros**:
- Most flexible
- Allows configuration of which types are primary
- Future-proof for new command types

**Cons**:
- Most complex solution
- May be over-engineering for current needs

## Recommendation

**Use Option 1** - Change `orchestrate.md` to use `command-type: primary`.

**Rationale**:
1. The semantic distinction between "primary" and "orchestration" provides no functional benefit
2. Users understand orchestrate as a top-level workflow command, not a type distinction
3. Simplest fix with zero risk
4. Can be changed in ~10 seconds
5. All other workflow commands (plan, implement, report, etc.) use "primary"

If semantic categorization becomes important in the future, we can implement Option 2 or 3, but the current use case doesn't justify the complexity.

## Files Analyzed

1. `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:189` - Keybinding
2. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua:146-149` - Command registration
3. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Picker implementation
4. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/parser.lua:158-201` - Parser categorization logic
5. `/home/benjamin/.config/.claude/commands/orchestrate.md:5` - Command metadata

## Next Steps

1. Change `orchestrate.md` line 5 from `command-type: orchestration` to `command-type: primary`
2. Verify the command appears in `<leader>ac` picker
3. Optional: Update plan 012 and summary 012 to note this metadata correction

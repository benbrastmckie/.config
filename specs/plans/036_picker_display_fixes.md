# Picker Display Fixes Implementation Plan

## IMPLEMENTATION COMPLETE

All phases completed successfully on 2025-10-08.

## Metadata
- **Date**: 2025-10-08
- **Feature**: Fix picker display issues (template quotes, help accuracy, hook asterisks)
- **Scope**: picker.lua and parser.lua corrections for UI consistency
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md

## Overview

Fix multiple picker display issues that affect user experience:
1. Template descriptions showing quotes (inconsistent with other artifact types)
2. Keyboard shortcuts help containing 4 inaccuracies about UI structure
3. Hook events (and agents, TTS) not showing asterisks in .config/ directory
4. Various styling inconsistencies in help text

These are cosmetic but important UX issues that reduce trust in the UI.

## Success Criteria
- [x] Template descriptions display without quotes (consistent with commands/agents)
- [x] Keyboard shortcuts help accurately describes picker structure
- [x] Hook events show asterisks when viewed in .config/ directory
- [x] Agent entries show asterisks when viewed in .config/ directory
- [x] TTS entries show asterisks when viewed in .config/ directory
- [x] All help text styling is consistent and accurate

## Technical Design

### Issue 1: Template Quote Stripping
**Location**: picker.lua:120 in `parse_template_description()`
**Root Cause**: YAML parser captures quoted values but doesn't strip quotes
**Solution**: Add `desc:gsub('^"(.-)"$', '%1')` after capture

### Issue 2: Keyboard Shortcuts Help Accuracy
**Location**: picker.lua:848-890
**Inaccuracies Identified**:
1. Missing mention of standalone agents section
2. TTS files shown with brackets `[config]` when actual has none
3. Hooks shown as tree items when they're in metadata preview
4. Tree character logic oversimplified

**Solution**: Rewrite help text to accurately reflect current implementation

### Issue 3: Hook/Agent/TTS Asterisk Detection
**Location**: parser.lua functions:
- `parse_hooks_with_fallback` (lines 618-644)
- `parse_agents_with_fallback` (lines 586-612)
- `parse_tts_files_with_fallback` (lines 650-674)

**Root Cause**: Missing special case for `project_dir == global_dir`
**Solution**: Add same logic as commands have (parser.lua:255-266)

## Implementation Phases

### Phase 1: Template Description Quote Stripping [COMPLETED]
**Objective**: Remove quotes from template descriptions for consistency
**Complexity**: Low

Tasks:
- [x] Modify picker.lua:120-122 to strip quotes from template descriptions
- [x] Add `desc:gsub('^"(.-)"$', '%1')` after initial capture
- [x] Handle both single and double quotes
- [x] Ensure empty strings return correctly

Testing:
```bash
# Manual testing in Neovim
:lua require('neotex.plugins.ai.claude.commands.picker').show()
# Navigate to Templates section
# Verify descriptions show without quotes
# Test with multiple template files
```

Expected Results:
- Template descriptions display without surrounding quotes
- Consistent with command/agent description display
- Empty descriptions handled gracefully

### Phase 2: Keyboard Shortcuts Help Accuracy [COMPLETED]
**Objective**: Fix all inaccuracies in keyboard shortcuts help text
**Complexity**: Low

Tasks:
- [x] Update picker.lua:848-890 help text content
- [x] Add standalone agents section description
- [x] Fix TTS file type descriptions (remove incorrect brackets)
- [x] Correct hooks description (metadata preview, not tree items)
- [x] Simplify tree character examples to match actual behavior
- [x] Ensure styling consistency throughout help text

Testing:
```bash
# Manual testing in Neovim
:lua require('neotex.plugins.ai.claude.commands.picker').show()
# Press ? to open help
# Verify all sections accurately describe UI behavior:
#   1. Agents section mentioned
#   2. TTS files correctly described
#   3. Hooks correctly described as metadata preview
#   4. Tree characters match actual display
```

Expected Results:
- Help text accurately describes all picker sections
- No misleading information about UI structure
- Consistent formatting and style
- Clear, helpful guidance for users

### Phase 3: Hook/Agent/TTS Asterisk Detection [COMPLETED]
**Objective**: Add special case logic for .config/ directory asterisk display
**Complexity**: Medium

Tasks:
- [x] Modify `parse_hooks_with_fallback` (parser.lua:618-644)
- [x] Add special case: if `project_hooks_dir == global_hooks_dir`, mark all as local
- [x] Modify `parse_agents_with_fallback` (parser.lua:586-612)
- [x] Add special case: if `project_agents_dir == global_agents_dir`, mark all as local
- [x] Modify `parse_tts_files_with_fallback` (parser.lua:650-674)
- [x] Add special case: if `project_dir == global_dir`, mark all as local
- [x] Follow same pattern as commands (parser.lua:255-266)

Testing:
```bash
# Manual testing in .config/ directory
cd ~/.config
nvim
:lua require('neotex.plugins.ai.claude.commands.picker').show()
# Verify all hooks show * indicator
# Verify all agents show * indicator
# Verify all TTS files show * indicator

# Manual testing in different project directory
cd ~/some-other-project
nvim
:lua require('neotex.plugins.ai.claude.commands.picker').show()
# Verify global hooks/agents/TTS do NOT show * indicator
# Verify local hooks/agents/TTS DO show * indicator
```

Expected Results:
- When in .config/ directory, all hooks/agents/TTS show asterisk
- When in other directories, only local artifacts show asterisk
- Consistent with command asterisk behavior
- Behavior matches user expectations

## Testing Strategy

### Manual Testing Approach
Since this is UI-focused work with no automated test infrastructure for picker display:

1. **Template Testing**:
   - Open picker in various projects
   - Verify template descriptions across different template files
   - Check edge cases (empty descriptions, special characters)

2. **Help Text Testing**:
   - Read through entire help text
   - Verify each section matches actual behavior
   - Test in both .config/ and project directories

3. **Asterisk Testing**:
   - Test in .config/ directory (all should show *)
   - Test in project with local .claude/ (locals show *, globals don't)
   - Test in project without local .claude/ (none show *)
   - Test all artifact types: commands, agents, hooks, TTS

### Test Coverage
- Commands: Already working (reference implementation)
- Agents: Need fixing
- Hooks: Need fixing
- TTS: Need fixing
- Templates: Need fixing (different issue - quotes)
- Help text: Need fixing (accuracy)

## Documentation Requirements

No documentation updates required - these are bug fixes to match existing documented behavior.

## Dependencies

None - all changes are self-contained within picker.lua and parser.lua

## Notes

### Pattern Reference
The command parser already implements the correct pattern for .config/ detection:
```lua
-- Special case: when in .config/, project_dir equals global_dir
-- In this case, all commands should be marked as local since we're in that directory
if project_dir and project_dir == global_dir then
  if vim.fn.isdirectory(project_dir) == 1 then
    local commands = M.parse_all_commands(project_dir)
    for name, command in pairs(commands) do
      command.is_local = true  -- Mark as local since we're in this directory
      merged_commands[name] = command
    end
  end
  return merged_commands
end
```

This same pattern should be applied to hooks, agents, and TTS parsing functions.

### Quote Stripping Pattern
Simple gsub pattern to remove surrounding quotes:
```lua
desc = desc:gsub('^"(.-)"$', '%1')  -- Remove double quotes
desc = desc:gsub("^'(.-)'$", '%1')  -- Remove single quotes (if needed)
```

### Help Text Accuracy
Current help text shows outdated/incorrect information:
- Missing: Standalone agents section (recently added)
- Wrong: TTS bracket notation doesn't match actual display
- Wrong: Hooks described as tree items when they're in metadata preview
- Oversimplified: Tree character logic more nuanced than described

The help text should be rewritten to accurately reflect the current picker implementation.

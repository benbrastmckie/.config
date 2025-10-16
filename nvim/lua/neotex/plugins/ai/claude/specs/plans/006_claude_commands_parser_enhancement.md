# Claude Commands YAML Frontmatter Standardization Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

## Metadata
- **Date**: 2025-09-30
- **Feature**: Standardize all Claude commands to use proper YAML frontmatter format
- **Scope**: Fix missing commands by correcting frontmatter syntax and format issues
- **Estimated Phases**: 3
- **Complexity**: Low
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**: `010_claude_commands_picker_config_directory_issue.md`

## Overview

The Claude commands picker (`<leader>ac`) currently excludes 10 out of 27 commands due to frontmatter parsing failures. Rather than building complex multi-format parsing, this plan standardizes all commands to use proper YAML frontmatter format and documents the requirements clearly.

**Current Issues**:
1. **Template Format**: 2 commands use `{{template:...}}` format instead of YAML
2. **Empty YAML Fields**: 8 commands have `dependent-commands:` with no values, causing parser failures
3. **Missing Documentation**: No clear specification of required frontmatter format

**Solution**: Fix all command files to use standard YAML frontmatter and document the requirements comprehensively.

## Success Criteria
- [ ] All 27 commands visible in `<leader>ac` picker
- [ ] All commands use standardized YAML frontmatter format
- [ ] Empty YAML fields properly handled (remove or populate)
- [ ] Template format commands converted to YAML
- [ ] Clear documentation of frontmatter requirements
- [ ] No regression in existing command functionality
- [ ] All commands execute properly after frontmatter fixes

## Technical Design

### Problem Analysis

**Commands with Issues** (10 total):
```
Template Format (2):
├── orchestrate.md        → Convert {{template:...}} to YAML
└── workflow-recovery.md  → Convert {{template:...}} to YAML

Empty YAML Fields (8):
├── coordination-hub.md      → Fix empty dependent-commands:
├── dependency-resolver.md   → Already has proper dependent-commands
├── performance-monitor.md   → Already has proper dependent-commands
├── progress-aggregator.md   → Already has proper dependent-commands
├── resource-manager.md      → Fix empty dependent-commands:
├── resume-implement.md      → Has proper frontmatter, check other issues
├── workflow-status.md       → Has proper frontmatter, check other issues
└── workflow-template.md     → Has proper frontmatter, check other issues
```

### Standard YAML Format
```yaml
---
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash
argument-hint: "<command-args>"
description: "Command description"
command-type: primary
dependent-commands: command1, command2
---
```

### Component Interactions
- **Command Files**: Standardized YAML frontmatter across all files
- **parser.lua**: Existing YAML parser continues to work unchanged
- **picker.lua**: All commands become visible automatically
- **Documentation**: Clear frontmatter format requirements

## Implementation Phases

### Phase 1: Fix Template Format Commands [COMPLETED]
**Objective**: Convert `orchestrate.md` and `workflow-recovery.md` from template to YAML format
**Complexity**: Low

Tasks:
- [x] Extract metadata from `orchestrate.md` template format
- [x] Convert to standard YAML frontmatter in `orchestrate.md`
- [x] Extract metadata from `workflow-recovery.md` template format
- [x] Convert to standard YAML frontmatter in `workflow-recovery.md`
- [x] Preserve original command content and functionality
- [x] Test both commands parse correctly after conversion

Template Analysis:
```
orchestrate.md:
{{template:orchestration_yaml:orchestrate,Multi-agent workflow...,\"<workflow-description>\"...,report,plan,implement...}}

Convert to:
---
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash
argument-hint: \"<workflow-description> [--dry-run] [--template=<template-name>] [--priority=<high|medium|low>]\"
description: \"Multi-agent workflow orchestration for complete research → planning → implementation workflows\"
command-type: primary
dependent-commands: report, plan, implement, debug, refactor, document, test, test-all
---
```

Testing:
```bash
# Test parsing after conversion
nvim -c "lua local p = require('neotex.plugins.ai.claude.commands.parser'); print(vim.inspect(p.parse_command_file('/home/benjamin/.config/.claude/commands/orchestrate.md')))"

# Verify command count increases
nvim -c "lua local p = require('neotex.plugins.ai.claude.commands.parser'); local cmds = p.parse_all_commands('/home/benjamin/.config/.claude/commands'); print('Commands parsed: ' .. vim.tbl_count(cmds))"
```

### Phase 2: Fix YAML Frontmatter Issues [COMPLETED]
**Objective**: Fix empty and malformed YAML fields in remaining 8 commands
**Complexity**: Low

Tasks:
- [x] Fix empty `dependent-commands:` field in `coordination-hub.md`
- [x] Fix empty `dependent-commands:` field in `resource-manager.md` (if needed)
- [x] Investigate why `resume-implement.md` fails parsing despite proper YAML
- [x] Investigate why `workflow-status.md` fails parsing despite proper YAML
- [x] Investigate why `workflow-template.md` fails parsing despite proper YAML
- [x] Ensure all YAML fields have proper values or are omitted
- [x] Validate YAML syntax in all command files

Required Fixes:
```yaml
# coordination-hub.md: Fix empty dependent-commands
# FROM:
dependent-commands:
# TO (option 1 - remove field):
# (omit the field entirely)
# TO (option 2 - add dependencies):
dependent-commands: resource-manager, workflow-status
```

Testing:
```bash
# Test each fixed file individually
for file in coordination-hub resource-manager resume-implement workflow-status workflow-template; do
  nvim -c "lua local p = require('neotex.plugins.ai.claude.commands.parser'); local cmd = p.parse_command_file('/home/benjamin/.config/.claude/commands/$file.md'); if cmd then print('✓ $file.md') else print('✗ $file.md') end"
done

# Test final command count
nvim -c "lua local p = require('neotex.plugins.ai.claude.commands.parser'); print('Total commands: ' .. vim.tbl_count(p.parse_all_commands('/home/benjamin/.config/.claude/commands')))"
```

### Phase 3: Documentation and Validation [COMPLETED]
**Objective**: Document YAML frontmatter requirements and validate all commands work
**Complexity**: Low

Tasks:
- [x] Create frontmatter format specification document
- [x] Update existing documentation with YAML requirements
- [x] Add examples of proper frontmatter format
- [x] Document required vs optional fields
- [x] Validate all 27 commands appear in picker
- [x] Test functionality of previously missing commands
- [x] Create validation script for future command additions

Documentation Requirements:
```markdown
# Claude Commands Frontmatter Specification

## Required Format
All command files must include YAML frontmatter:

```yaml
---
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash
argument-hint: \"<command-arguments>\"
description: \"Brief command description\"
command-type: primary  # or secondary, utility, dependent
dependent-commands: cmd1, cmd2  # optional, comma-separated
---
```

## Field Definitions
- `allowed-tools`: Tools the command can use
- `argument-hint`: Usage syntax for the command
- `description`: Brief description for picker display
- `command-type`: Command category (primary/secondary/utility/dependent)
- `dependent-commands`: Commands this command depends on (optional)
```

Testing:
```bash
# Final integration test
cd /home/benjamin/.config && nvim

# Test picker shows all commands
# Press <leader>ac and count commands (should be 27)

# Test previously missing commands work
# Try orchestrate, coordination-hub, workflow-recovery, etc.

# Validation script
nvim -c "lua
  local parser = require('neotex.plugins.ai.claude.commands.parser')
  local commands_dir = '/home/benjamin/.config/.claude/commands'
  local all_files = vim.fn.readdir(commands_dir)
  local md_files = vim.tbl_filter(function(f) return f:match('%.md$') end, all_files)
  local parsed = parser.parse_all_commands(commands_dir)
  print('Files: ' .. #md_files .. ', Parsed: ' .. vim.tbl_count(parsed))
  if #md_files == vim.tbl_count(parsed) then
    print('✓ All commands parsed successfully')
  else
    print('✗ Some commands missing')
  end
"
```

## Testing Strategy

### File-by-File Validation
- **Template Conversion**: Verify `orchestrate.md` and `workflow-recovery.md` convert properly
- **YAML Syntax**: Validate all frontmatter parses correctly
- **Field Mapping**: Ensure all required fields are present and properly formatted
- **Command Functionality**: Test that fixed commands execute properly

### Integration Tests
- **Picker Display**: Verify all 27 commands appear in `<leader>ac`
- **Command Execution**: Test functionality of all previously missing commands
- **No Regressions**: Ensure existing commands continue to work

### Validation Script
```lua
-- Command parsing validation
local function validate_all_commands()
  local parser = require('neotex.plugins.ai.claude.commands.parser')
  local commands_dir = '/home/benjamin/.config/.claude/commands'

  -- Get all .md files
  local all_files = {}
  for _, file in ipairs(vim.fn.readdir(commands_dir)) do
    if file:match('%.md$') then
      table.insert(all_files, file:gsub('%.md$', ''))
    end
  end

  -- Parse all commands
  local parsed_commands = parser.parse_all_commands(commands_dir)

  -- Report results
  print(string.format("Total .md files: %d", #all_files))
  print(string.format("Successfully parsed: %d", vim.tbl_count(parsed_commands)))

  -- List any missing commands
  local missing = {}
  for _, filename in ipairs(all_files) do
    if not parsed_commands[filename] then
      table.insert(missing, filename)
    end
  end

  if #missing > 0 then
    print("MISSING COMMANDS:")
    for _, name in ipairs(missing) do
      print("  ✗ " .. name)
    end
    return false
  else
    print("✓ All commands parsed successfully!")
    return true
  end
end
```

## Documentation Requirements

### Format Specification
- [ ] Create comprehensive YAML frontmatter specification
- [ ] Document required vs optional fields
- [ ] Provide examples of proper frontmatter format
- [ ] Add validation guidelines for new commands

### User Documentation
- [ ] Update README.md with YAML frontmatter requirements
- [ ] Document proper command file format
- [ ] Add troubleshooting guide for frontmatter issues

## Dependencies

### Internal Dependencies
- **Existing parser.lua**: YAML parsing logic remains unchanged
- **Command files**: Direct file edits to fix frontmatter
- **Documentation**: Updates to specify YAML requirements

### External Dependencies
- No external dependencies required
- No code changes needed (only file content fixes)

## Risk Assessment

### Low Risk
- **File Content Changes**: Simple frontmatter format fixes
- **Backward Compatibility**: Existing commands continue to work
- **No Code Changes**: Parser logic remains unchanged

### Minimal Risk
- **YAML Syntax Errors**: Easy to validate and fix
- **Command Functionality**: Content changes only affect metadata

### Mitigation Strategies
- Test each command file after frontmatter changes
- Validate YAML syntax before committing changes
- Keep original command content and functionality intact

## Implementation Notes

### Code Style Standards
- **Indentation**: 2 spaces, expandtab (per CLAUDE.md)
- **Line length**: ~100 characters (soft limit)
- **Character Encoding**: UTF-8 only, no emojis in file content
- **YAML Format**: Follow standard YAML syntax with proper field spacing

### Git Workflow
- Create feature branch: `fix/claude-commands-yaml-frontmatter`
- Atomic commits per command file or logical group
- Test parsing after each change
- Final commit format: `fix: standardize Claude commands YAML frontmatter format`

### Testing Commands
```bash
# Run after each phase
nvim -c "lua require('neotex.plugins.ai.claude').show_commands_picker()"

# Verify command count
nvim -c "lua print('Commands: ' .. vim.tbl_count(require('neotex.plugins.ai.claude.commands.parser').get_command_structure().primary_commands))"

# Test previously missing commands
nvim -c "ClaudeCommands" # Should show orchestrate, coordination-hub, etc.
```

## Success Metrics

### Quantitative
- **Command Availability**: 27/27 commands visible in picker (currently 17/27)
- **YAML Compliance**: 100% of command files use proper YAML frontmatter
- **Zero Regressions**: All existing commands continue to work

### Qualitative
- **User Experience**: All commands accessible in picker
- **Developer Experience**: Clear frontmatter format requirements
- **Maintainability**: Consistent YAML format across all command files

## Notes

### Template Format Conversion
The 2 template format commands follow this pattern:
```
{{template:type:name,description,argument-hint,dependencies}}
```

Conversion to YAML:
```yaml
---
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash
argument-hint: "[extracted from template]"
description: "[extracted from template]"
command-type: primary
dependent-commands: [extracted from template]
---
```

### Documentation Standards
After fixes, all commands will follow the documented YAML frontmatter standard, making the format requirements clear for future command additions.

### Future Maintenance
- Clear frontmatter format specification prevents future parsing issues
- Validation script helps verify new commands follow standards
- Simple YAML format is easy to maintain and extend
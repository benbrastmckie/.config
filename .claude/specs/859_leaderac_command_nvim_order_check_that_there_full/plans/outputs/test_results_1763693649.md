# Test Execution Report

## Metadata
- **Date**: 2025-11-20 17:34:09
- **Plan**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md
- **Test Framework**: plenary
- **Test Command**: nvim --headless -c "PlenaryBustedDirectory nvim/lua/neotex/plugins/ai/claude/commands/picker/ { minimal_init = 'tests/minimal_init.vim' }"
- **Exit Code**: 1
- **Execution Time**: <1s
- **Environment**: test

## Summary
- **Total Tests**: 59
- **Passed**: 50
- **Failed**: 9
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

### registry_spec.lua (8 failures)

1. **get_sync_types includes all 11 artifact types**
   - File: registry_spec.lua:112
   - Expected: 11 artifact types
   - Actual: 13 artifact types
   - Error: Test expects 11 types but registry now has 13 (likely scripts and tests were added)

2. **format_heading formats command heading correctly**
   - File: registry_spec.lua:120
   - Expected: true (boolean)
   - Actual: '[Commands]' (string)
   - Error: Assertion type mismatch

3. **format_heading formats agent heading correctly**
   - File: registry_spec.lua:127
   - Expected: true (boolean)
   - Actual: '[Agents]' (string)
   - Error: Assertion type mismatch

4. **format_artifact formats artifact with local marker**
   - File: registry_spec.lua:146
   - Expected: true (boolean)
   - Actual: '*' (string)
   - Error: Assertion checking for presence of marker incorrectly

5. **format_artifact formats artifact without local marker**
   - File: registry_spec.lua:159
   - Expected: false (boolean)
   - Actual: nil
   - Error: Assertion checking for absence of marker incorrectly

6. **format_artifact uses 2-space indent for hook_event**
   - File: registry_spec.lua:173
   - Expected: true (boolean)
   - Actual: '  ├─' (string)
   - Error: Assertion type mismatch

7. **format_artifact uses 1-space indent for commands**
   - File: registry_spec.lua:185
   - Expected: true (boolean)
   - Actual: ' ├─' (string)
   - Error: Assertion type mismatch

8. **format_artifact strips 'Specialized in' prefix from agent descriptions**
   - File: registry_spec.lua:196
   - Expected: false (boolean)
   - Actual: nil
   - Error: Assertion checking for stripped prefix incorrectly

### metadata_spec.lua (1 failure)

9. **parse_doc_description ignores subheadings when looking for paragraph**
   - File: metadata_spec.lua:221
   - Expected: '' (empty string - should not extract subheading)
   - Actual: 'This should not be extracted'
   - Error: Parser incorrectly extracts content from subheadings instead of ignoring them

## Full Output

```
Starting...Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua
Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua
Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan_spec.lua
E282: Cannot read from "tests/minimal_init.vim"

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua
Success	||	picker.artifacts.registry get_type returns configuration for valid command type
Success	||	picker.artifacts.registry get_type returns configuration for valid agent type
Success	||	picker.artifacts.registry get_type returns nil for invalid type
Success	||	picker.artifacts.registry should_preserve_permissions returns true for executable script types
Success	||	picker.artifacts.registry should_preserve_permissions returns false for non-executable types
Success	||	picker.artifacts.registry should_preserve_permissions returns false for invalid type
Success	||	picker.artifacts.registry get_visible_types returns only picker-visible types
Success	||	picker.artifacts.registry get_visible_types excludes agent_protocol, standard, data_doc, settings
Success	||	picker.artifacts.registry get_visible_types includes command, agent, hook_event, tts_file, template, lib, doc
Success	||	picker.artifacts.registry get_sync_types returns sync-enabled types
Fail	||	picker.artifacts.registry get_sync_types includes all 11 artifact types
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:112: Expected objects to be equal.
            Passed in:
            (number) 13
            Expected:
            (number) 11

Fail	||	picker.artifacts.registry format_heading formats command heading correctly
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:120: Expected objects to be the same.
            Passed in:
            (string) '[Commands]'
            Expected:
            (boolean) true

Fail	||	picker.artifacts.registry format_heading formats agent heading correctly
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:127: Expected objects to be the same.
            Passed in:
            (string) '[Agents]'
            Expected:
            (boolean) true

Success	||	picker.artifacts.registry format_heading returns empty string for invalid type
Fail	||	picker.artifacts.registry format_artifact formats artifact with local marker
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:146: Expected objects to be the same.
            Passed in:
            (string) '*'
            Expected:
            (boolean) true

Fail	||	picker.artifacts.registry format_artifact formats artifact without local marker
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:159: Expected objects to be the same.
            Passed in:
            (nil)
            Expected:
            (boolean) false

Fail	||	picker.artifacts.registry format_artifact uses 2-space indent for hook_event
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:173: Expected objects to be the same.
            Passed in:
            (string) '  ├─'
            Expected:
            (boolean) true

Fail	||	picker.artifacts.registry format_artifact uses 1-space indent for commands
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:185: Expected objects to be the same.
            Passed in:
            (string) ' ├─'
            Expected:
            (boolean) true

Fail	||	picker.artifacts.registry format_artifact strips 'Specialized in' prefix from agent descriptions
            ...ns/ai/claude/commands/picker/artifacts/registry_spec.lua:196: Expected objects to be the same.
            Passed in:
            (nil)
            Expected:
            (boolean) false

Success	||	picker.artifacts.registry get_tree_indent returns single space for commands
Success	||	picker.artifacts.registry get_tree_indent returns double space for hook_event
Success	||	picker.artifacts.registry get_tree_indent returns single space for agents
Success	||	picker.artifacts.registry get_tree_indent returns single space as default for invalid type

Success: 	15
Failed : 	8
Errors : 	0
========================================
Tests Failed. Exit: 1

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan_spec.lua
Success	||	picker.utils.scan scan_directory scans directory and returns file info
Success	||	picker.utils.scan scan_directory excludes README.md files
Success	||	picker.utils.scan scan_directory returns empty array for non-existent directory
Success	||	picker.utils.scan scan_directory returns empty array when no files match pattern
Success	||	picker.utils.scan scan_directory_for_sync identifies new files for copying
Success	||	picker.utils.scan scan_directory_for_sync identifies existing files for replacement
Success	||	picker.utils.scan scan_directory_for_sync returns empty array when no global files exist
Success	||	picker.utils.scan merge_artifacts merges local and global artifacts with local override
Success	||	picker.utils.scan merge_artifacts handles empty local artifacts
Success	||	picker.utils.scan merge_artifacts handles empty global artifacts
Success	||	picker.utils.scan filter_by_pattern filters artifacts by name pattern
Success	||	picker.utils.scan filter_by_pattern returns empty array when no matches
Success	||	picker.utils.scan filter_by_pattern handles empty input
Success	||	picker.utils.scan get_directories returns current project and global config directories

Success: 	14
Failed : 	0
Errors : 	0
========================================

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua
Success	||	picker.artifacts.metadata parse_template_description extracts description from YAML file with double quotes
Success	||	picker.artifacts.metadata parse_template_description extracts description from YAML file with single quotes
Success	||	picker.artifacts.metadata parse_template_description extracts description from YAML file without quotes
Success	||	picker.artifacts.metadata parse_template_description truncates description to 40 characters
Success	||	picker.artifacts.metadata parse_template_description returns empty string for file without description
Success	||	picker.artifacts.metadata parse_template_description returns empty string for non-existent file
Success	||	picker.artifacts.metadata parse_script_description extracts description from Purpose header
Success	||	picker.artifacts.metadata parse_script_description extracts description from Description header
Success	||	picker.artifacts.metadata parse_script_description extracts first non-shebang comment if no Purpose/Description
Success	||	picker.artifacts.metadata parse_script_description truncates description to 40 characters
Success	||	picker.artifacts.metadata parse_script_description ignores shebang line
Success	||	picker.artifacts.metadata parse_script_description returns empty string for non-existent file
Success	||	picker.artifacts.metadata parse_doc_description extracts description from YAML frontmatter
Success	||	picker.artifacts.metadata parse_doc_description extracts first paragraph after title when no frontmatter
Success	||	picker.artifacts.metadata parse_doc_description truncates description to 40 characters
Fail	||	picker.artifacts.metadata parse_doc_description ignores subheadings when looking for paragraph
            ...ns/ai/claude/commands/picker/artifacts/metadata_spec.lua:221: Expected objects to be equal.
            Passed in:
            (string) 'This should not be extracted'
            Expected:
            (string) ''

Success	||	picker.artifacts.metadata parse_doc_description returns empty string for non-existent file
Success	||	picker.artifacts.metadata get_parser_for_type returns correct parser for template type
Success	||	picker.artifacts.metadata get_parser_for_type returns correct parser for script types
Success	||	picker.artifacts.metadata get_parser_for_type returns correct parser for doc type
Success	||	picker.artifacts.metadata get_parser_for_type returns nil for types without specific parser
Success	||	picker.artifacts.metadata get_parser_for_type returns nil for invalid type

Success: 	21
Failed : 	1
Errors : 	0
========================================
Tests Failed. Exit: 1
```

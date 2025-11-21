# Test Execution Report

## Metadata
- **Date**: 2025-11-20
- **Plan**: /home/benjamin/.config/.claude/specs/877_fix_phase3_picker_test_failures/plans/001_fix_phase3_picker_test_failures_plan.md
- **Test Framework**: plenary
- **Test Command**: `nvim --headless -c "PlenaryBustedDirectory nvim/lua/neotex/plugins/ai/claude/commands/picker/ { minimal_init = 'tests/minimal_init.vim' }" -c "qa!"`
- **Exit Code**: 0
- **Execution Time**: 0s
- **Environment**: test

## Summary
- **Total Tests**: 59
- **Passed**: 59
- **Failed**: 0
- **Skipped**: 0
- **Coverage**: N/A

## Failed Tests

None - all tests passed!

## Full Output

```bash
START_TIME=$(date +%s) && timeout 30m nvim --headless -c "PlenaryBustedDirectory nvim/lua/neotex/plugins/ai/claude/commands/picker/ { minimal_init = 'tests/minimal_init.vim' }" -c "qa!" > /tmp/test_output_1763695845.txt 2>&1; EXIT_CODE=$?; END_TIME=$(date +%s); DURATION=$((END_TIME - START_TIME)); echo "EXIT_CODE=$EXIT_CODE"; echo "DURATION=$DURATION"; cat /tmp/test_output_1763695845.txt
EXIT_CODE=0
DURATION=0
Starting...Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua
Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua
Scheduling: nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan_spec.lua
E282: Cannot read from "tests/minimal_init.vim"

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua
[32mSuccess[0m	||	picker.artifacts.registry get_type returns configuration for valid command type
[32mSuccess[0m	||	picker.artifacts.registry get_type returns configuration for valid agent type
[32mSuccess[0m	||	picker.artifacts.registry get_type returns nil for invalid type
[32mSuccess[0m	||	picker.artifacts.registry should_preserve_permissions returns true for executable script types
[32mSuccess[0m	||	picker.artifacts.registry should_preserve_permissions returns false for non-executable types
[32mSuccess[0m	||	picker.artifacts.registry should_preserve_permissions returns false for invalid type
[32mSuccess[0m	||	picker.artifacts.registry get_visible_types returns only picker-visible types
[32mSuccess[0m	||	picker.artifacts.registry get_visible_types excludes agent_protocol, standard, data_doc, settings
[32mSuccess[0m	||	picker.artifacts.registry get_visible_types includes command, agent, hook_event, tts_file, template, lib, doc
[32mSuccess[0m	||	picker.artifacts.registry get_sync_types returns sync-enabled types
[32mSuccess[0m	||	picker.artifacts.registry get_sync_types includes all 13 artifact types
[32mSuccess[0m	||	picker.artifacts.registry format_heading formats command heading correctly
[32mSuccess[0m	||	picker.artifacts.registry format_heading formats agent heading correctly
[32mSuccess[0m	||	picker.artifacts.registry format_heading returns empty string for invalid type
[32mSuccess[0m	||	picker.artifacts.registry format_artifact formats artifact with local marker
[32mSuccess[0m	||	picker.artifacts.registry format_artifact formats artifact without local marker
[32mSuccess[0m	||	picker.artifacts.registry format_artifact uses 2-space indent for hook_event
[32mSuccess[0m	||	picker.artifacts.registry format_artifact uses 1-space indent for commands
[32mSuccess[0m	||	picker.artifacts.registry format_artifact strips 'Specialized in' prefix from agent descriptions
[32mSuccess[0m	||	picker.artifacts.registry get_tree_indent returns single space for commands
[32mSuccess[0m	||	picker.artifacts.registry get_tree_indent returns double space for hook_event
[32mSuccess[0m	||	picker.artifacts.registry get_tree_indent returns single space for agents
[32mSuccess[0m	||	picker.artifacts.registry get_tree_indent returns single space as default for invalid type

[32mSuccess: [0m	23
[31mFailed : [0m	0
[31mErrors : [0m	0
========================================
E282: Cannot read from "tests/minimal_init.vim"

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan_spec.lua
[32mSuccess[0m	||	picker.utils.scan scan_directory scans directory and returns file info
[32mSuccess[0m	||	picker.utils.scan scan_directory excludes README.md files
[32mSuccess[0m	||	picker.utils.scan scan_directory returns empty array for non-existent directory
[32mSuccess[0m	||	picker.utils.scan scan_directory returns empty array when no files match pattern
[32mSuccess[0m	||	picker.utils.scan scan_directory_for_sync identifies new files for copying
[32mSuccess[0m	||	picker.utils.scan scan_directory_for_sync identifies existing files for replacement
[32mSuccess[0m	||	picker.utils.scan scan_directory_for_sync returns empty array when no global files exist
[32mSuccess[0m	||	picker.utils.scan merge_artifacts merges local and global artifacts with local override
[32mSuccess[0m	||	picker.utils.scan merge_artifacts handles empty local artifacts
[32mSuccess[0m	||	picker.utils.scan merge_artifacts handles empty global artifacts
[32mSuccess[0m	||	picker.utils.scan filter_by_pattern filters artifacts by name pattern
[32mSuccess[0m	||	picker.utils.scan filter_by_pattern returns empty array when no matches
[32mSuccess[0m	||	picker.utils.scan filter_by_pattern handles empty input
[32mSuccess[0m	||	picker.utils.scan get_directories returns current project and global config directories

[32mSuccess: [0m	14
[31mFailed : [0m	0
[31mErrors : [0m	0
========================================
E282: Cannot read from "tests/minimal_init.vim"

========================================
Testing: 	/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description extracts description from YAML file with double quotes
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description extracts description from YAML file with single quotes
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description extracts description from YAML file without quotes
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description truncates description to 40 characters
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description returns empty string for file without description
[32mSuccess[0m	||	picker.artifacts.metadata parse_template_description returns empty string for non-existent file
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description extracts description from Purpose header
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description extracts description from Description header
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description extracts first non-shebang comment if no Purpose/Description
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description truncates description to 40 characters
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description ignores shebang line
[32mSuccess[0m	||	picker.artifacts.metadata parse_script_description returns empty string for non-existent file
[32mSuccess[0m	||	picker.artifacts.metadata parse_doc_description extracts description from YAML frontmatter
[32mSuccess[0m	||	picker.artifacts.metadata parse_doc_description extracts first paragraph after title when no frontmatter
[32mSuccess[0m	||	picker.artifacts.metadata parse_doc_description truncates description to 40 characters
[32mSuccess[0m	||	picker.artifacts.metadata parse_doc_description ignores subheadings when looking for paragraph
[32mSuccess[0m	||	picker.artifacts.metadata parse_doc_description returns empty string for non-existent file
[32mSuccess[0m	||	picker.artifacts.metadata get_parser_for_type returns correct parser for template type
[32mSuccess[0m	||	picker.artifacts.metadata get_parser_for_type returns correct parser for script types
[32mSuccess[0m	||	picker.artifacts.metadata get_parser_for_type returns correct parser for doc type
[32mSuccess[0m	||	picker.artifacts.metadata get_parser_for_type returns nil for types without specific parser
[32mSuccess[0m	||	picker.artifacts.metadata get_parser_for_type returns nil for invalid type

[32mSuccess: [0m	22
[31mFailed : [0m	0
[31mErrors : [0m	0
========================================
```

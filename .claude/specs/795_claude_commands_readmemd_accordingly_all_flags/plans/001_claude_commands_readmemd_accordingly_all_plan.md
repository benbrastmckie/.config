# Commands README.md Documentation Update Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Update Commands README.md with complete flag and CLI documentation
- **Scope**: Revise all 11 command entries with missing flags, add common flags section, update examples
- **Estimated Phases**: 3
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 17.5
- **Research Reports**:
  - [Command Flags Research](/home/benjamin/.config/.claude/specs/795_claude_commands_readmemd_accordingly_all_flags/reports/001_command_flags_research.md)

## Overview

Update the Commands README.md to include all flags, CLI operations, and file-passing capabilities discovered in the research report. The current README.md is missing documentation for `--file`, `--complexity`, `--auto-mode`, and `--threshold` flags across multiple commands. This plan will systematically update each command's usage section and add comprehensive reference documentation.

## Research Summary

Key findings from the research report:

1. **Missing `--file` flag documentation**: `/plan`, `/research`, and `/debug` support `--file <path>` for loading descriptions from files, with file archival to `{topic}/prompts/`
2. **Missing `--complexity` flag documentation**: `/plan` (default 3), `/research` (default 2), `/debug` (default 2), `/revise` (default 2) all support `--complexity 1-4`
3. **Missing `--auto-mode` flag**: `/expand` supports `--auto-mode` for non-interactive JSON output
4. **Missing `--threshold` flag**: `/setup` supports `--threshold [aggressive|balanced|conservative]` with `--cleanup`
5. **Mode detection keywords**: `/convert-docs` triggers agent mode on keywords like "detailed logging", "quality reporting"

Recommended approach: Update each command's usage section with complete flag syntax, add a Common Flags reference section, and enhance examples to show flag combinations.

## Success Criteria

- [x] All 11 commands have complete flag documentation in usage sections
- [x] Common Flags reference section added with `--file`, `--complexity`, `--dry-run`, `--auto-mode` explanations
- [x] File passing behavior documented (archival to `{topic}/prompts/`)
- [x] Examples updated with flag combination examples
- [x] `/convert-docs` mode detection keywords documented
- [x] All usage strings match actual command implementations

## Technical Design

### Architecture Overview

The README.md follows a structured format:
1. Overview sections (purpose, highlights, architecture)
2. Available Commands with individual command entries
3. Command Definition Format
4. Adaptive Plan Structures
5. Standards Discovery
6. Creating Custom Commands
7. Examples

### Update Strategy

**Command Entry Updates**: Each command entry in "Available Commands" will have its `**Usage**:` line updated to include all supported flags in standard CLI format.

**New Section**: Add "Common Flags" section after "Available Commands" to provide detailed flag explanations.

**Examples Enhancement**: Update "Examples" section with flag usage demonstrations.

### Flag Documentation Format

Standard format for usage strings:
```
**Usage**: `/command <required> [optional] [--flag <value>] [--boolean-flag]`
```

## Implementation Phases

### Phase 1: Update Command Usage Sections [COMPLETED] [COMPLETE]
dependencies: []

**Objective**: Update all 11 command entries with complete flag documentation

**Complexity**: Medium

Tasks:
- [x] Update `/plan` usage: add `[--file <path>]` and `[--complexity 1-4]` (file: /home/benjamin/.config/.claude/commands/README.md)
- [x] Update `/research` usage: add `[--file <path>]` and `[--complexity 1-4]`
- [x] Update `/debug` usage: add `[--file <path>]` and `[--complexity 1-4]`
- [x] Update `/revise` usage: add `[--complexity 1-4]`
- [x] Update `/setup` usage: add `[--threshold aggressive|balanced|conservative]` to cleanup section
- [x] Update `/expand` usage: add `[--auto-mode]` to both usage variants
- [x] Verify `/build`, `/coordinate`, `/collapse`, `/convert-docs`, `/optimize-claude` usage strings are accurate

Testing:
```bash
# Verify all usage strings are updated
grep -n "^\*\*Usage\*\*:" /home/benjamin/.config/.claude/commands/README.md

# Check for new flags in usage lines
grep -E "\-\-file|\-\-complexity|\-\-auto-mode|\-\-threshold" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 2 hours

### Phase 2: Add Common Flags Section [COMPLETED] [COMPLETE]
dependencies: [1]

**Objective**: Create comprehensive Common Flags reference section

**Complexity**: Medium

Tasks:
- [x] Create "Common Flags" section after "Available Commands" section
- [x] Document `--file <path>` flag: supported commands, behavior, file archival
- [x] Document `--complexity 1-4` flag: supported commands, default values, interpretation
- [x] Document `--dry-run` flag: supported commands and behavior
- [x] Document `--auto-mode` flag: supported commands and JSON output format
- [x] Add subsection for `/convert-docs` mode detection keywords
- [x] Cross-reference flags to specific command documentation

Testing:
```bash
# Verify section exists and has content
grep -A 50 "## Common Flags" /home/benjamin/.config/.claude/commands/README.md

# Verify all four main flags documented
grep -c "### --" /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 1.5 hours

### Phase 3: Update Examples and Validation [COMPLETED] [COMPLETE]
dependencies: [1, 2]

**Objective**: Add flag usage examples and validate documentation completeness

**Complexity**: Low

Tasks:
- [x] Add flag combination examples to Examples section
- [x] Add example: `/plan --file /path/to/requirements.md --complexity 4`
- [x] Add example: `/debug --file /tmp/error-log.md --complexity 3`
- [x] Add example: `/setup --cleanup --threshold aggressive --dry-run`
- [x] Add example: `/expand specs/plans/007_feature.md --auto-mode`
- [x] Validate all usage strings against command implementations
- [x] Ensure consistent formatting throughout document

Testing:
```bash
# Check examples section has new flag examples
grep -A 100 "## Examples" /home/benjamin/.config/.claude/commands/README.md | grep -E "\-\-file|\-\-complexity|\-\-threshold|\-\-auto-mode"

# Validate document structure
wc -l /home/benjamin/.config/.claude/commands/README.md
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Documentation Validation
- Verify all 11 commands have complete usage documentation
- Ensure flag syntax matches actual command implementations
- Check cross-references are accurate

### Content Review
- Validate Common Flags section covers all identified flags
- Confirm examples demonstrate practical flag usage
- Ensure consistent formatting and terminology

### Implementation Verification
- Compare updated usage strings against command source files
- Verify file archival behavior documentation accuracy
- Confirm mode detection keywords are complete

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/commands/README.md` - Primary target file

### Documentation Standards
- Follow existing README.md structure and formatting
- Use backtick code formatting for flags and paths
- No emojis in file content
- CommonMark specification compliance

## Dependencies

### Prerequisites
- Research report completed with all flag analysis
- Access to all command definition files for verification

### External Dependencies
- None

### Related Documentation
- Individual command `.md` files for implementation verification
- [Command Authoring Standards](/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md)

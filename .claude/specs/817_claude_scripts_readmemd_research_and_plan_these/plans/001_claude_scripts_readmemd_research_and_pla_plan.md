# Markdown-Link-Check Configuration Relocation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Relocate markdown-link-check.json to scripts/ directory
- **Scope**: Move configuration file, update 5 file references, remove empty config/ directory
- **Estimated Phases**: 3
- **Estimated Hours**: 1.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 27
- **Research Reports**:
  - [Markdown Link Check Relocation Research](../reports/001_markdown_link_check_relocation.md)

## Overview

This plan implements the relocation of `.claude/config/markdown-link-check.json` to `.claude/scripts/markdown-link-check.json` and updates all references to maintain script functionality. The move eliminates the undocumented `config/` directory and co-locates the configuration with the scripts that use it, aligning with directory organization standards.

## Research Summary

Key findings from the research report:
- **5 files** reference the configuration file: validate-links.sh, validate-links-quick.sh, scripts/README.md, TODO.md, and broken-links-troubleshooting.md
- The `config/` directory is **not documented** in directory organization standards and contains only this single file
- All references use **relative paths from project root**, making updates consistent
- Moving to `scripts/` **co-locates** the configuration with its consumers (validate-links*.sh scripts)

Recommended approach: Sequential file relocation followed by reference updates and verification.

## Success Criteria

- [ ] Configuration file exists at `.claude/scripts/markdown-link-check.json`
- [ ] Old `config/` directory no longer exists
- [ ] All 5 file references updated to new path
- [ ] validate-links-quick.sh executes successfully with new configuration path
- [ ] No remaining references to `config/markdown-link-check` in `.claude/` directory
- [ ] scripts/README.md documents the configuration file

## Technical Design

### Architecture Overview

The change is a pure file relocation with reference updates:

```
Before:
.claude/
├── config/
│   └── markdown-link-check.json  (orphaned)
├── scripts/
│   ├── validate-links.sh         (references config/)
│   └── validate-links-quick.sh   (references config/)

After:
.claude/
├── scripts/
│   ├── markdown-link-check.json  (co-located)
│   ├── validate-links.sh         (references scripts/)
│   └── validate-links-quick.sh   (references scripts/)
```

### Design Rationale

1. **Standards Compliance**: Eliminates undocumented `config/` directory
2. **Co-location Principle**: Configuration lives with its consumers
3. **Minimal Risk**: Simple path substitution in all files
4. **Reversible**: Easy to revert if issues arise

## Implementation Phases

### Phase 1: File Relocation [COMPLETE]
dependencies: []

**Objective**: Move configuration file and remove empty directory

**Complexity**: Low

Tasks:
- [x] Move file from `.claude/config/markdown-link-check.json` to `.claude/scripts/markdown-link-check.json`
- [x] Remove empty `.claude/config/` directory
- [x] Verify file exists at new location

Testing:
```bash
# Verify file moved successfully
test -f .claude/scripts/markdown-link-check.json && echo "File relocated successfully"

# Verify old directory removed
! test -d .claude/config/ && echo "Config directory removed"
```

**Expected Duration**: 0.25 hours

### Phase 2: Reference Updates [COMPLETE]
dependencies: [1]

**Objective**: Update all file references to the new configuration path

**Complexity**: Low

Tasks:
- [x] Update `.claude/scripts/validate-links.sh` line 6: change `CONFIG_FILE=".claude/config/markdown-link-check.json"` to `CONFIG_FILE=".claude/scripts/markdown-link-check.json"`
- [x] Update `.claude/scripts/validate-links-quick.sh` line 6: change `CONFIG_FILE=".claude/config/markdown-link-check.json"` to `CONFIG_FILE=".claude/scripts/markdown-link-check.json"`
- [x] Update `.claude/scripts/README.md` line 31: change path from `config/` to `scripts/`
- [x] Update `.claude/docs/troubleshooting/broken-links-troubleshooting.md` line 10: change path in command example
- [x] Remove line 14 from `.claude/TODO.md` (this move addresses the TODO item)
- [x] Add configuration file section to `.claude/scripts/README.md` documenting markdown-link-check.json

Testing:
```bash
# Verify no remaining old references
grep -r "config/markdown-link-check" .claude/ && echo "FAIL: Old references remain" || echo "PASS: All references updated"

# Verify new references exist
grep -q "scripts/markdown-link-check.json" .claude/scripts/validate-links.sh && echo "PASS: validate-links.sh updated"
grep -q "scripts/markdown-link-check.json" .claude/scripts/validate-links-quick.sh && echo "PASS: validate-links-quick.sh updated"
```

**Expected Duration**: 0.75 hours

### Phase 3: Validation and Documentation [COMPLETE]
dependencies: [2]

**Objective**: Verify functionality and finalize documentation

**Complexity**: Low

Tasks:
- [x] Run validate-links-quick.sh to confirm script functionality with new configuration path
- [x] Verify scripts/README.md includes configuration file documentation
- [x] Perform final grep check for any missed references
- [x] Document completion in build output

Testing:
```bash
# Functional test - run quick validation
bash .claude/scripts/validate-links-quick.sh 1

# Final comprehensive reference check
grep -r "config/markdown-link-check\|\.claude/config" .claude/ && echo "FAIL: References remain" || echo "PASS: All clean"

# Verify documentation added
grep -q "markdown-link-check.json" .claude/scripts/README.md && echo "PASS: README documented"
```

**Expected Duration**: 0.5 hours

## Testing Strategy

### Test Approach
1. **Phase-level testing**: Each phase includes specific verification commands
2. **Functional testing**: Execute validate-links-quick.sh with limit of 1 file
3. **Reference verification**: Use grep to ensure all old paths are updated
4. **Documentation verification**: Confirm README.md updates

### Test Commands
Primary test command from standards:
```bash
bash .claude/scripts/validate-links-quick.sh 1
```

### Success Metrics
- Script executes without errors
- Configuration file is found and used
- No stale references to old path remain

## Documentation Requirements

### Files to Update
1. **scripts/README.md**: Add "Configuration Files" section documenting markdown-link-check.json
2. **broken-links-troubleshooting.md**: Update command example path

### Documentation Format
Follow project documentation standards:
- Clear, concise language
- Code examples with syntax highlighting
- No emojis in file content

## Dependencies

### Prerequisites
- Node.js and npm installed (for markdown-link-check)
- Write access to all files in `.claude/` directory

### External Dependencies
- markdown-link-check npm package (already in use)

### Blockers
None identified - this is a self-contained refactoring task

## Risk Assessment

### Low Risk
- **Simple path substitution**: All changes are find-and-replace operations
- **Easily reversible**: Can restore from git if issues arise
- **Limited scope**: Only 5 files affected, all in `.claude/` directory

### Mitigation
- Verify file exists before removing old directory
- Run validation script after changes to confirm functionality
- Use grep to catch any missed references

## Notes

This plan addresses the TODO item at `.claude/TODO.md` line 14 which flagged this configuration file location for cleanup. After implementation, the `config/` directory will be completely removed as it served no other purpose.

# Markdown-Link-Check Configuration Relocation Research Report

## Metadata
- **Date**: 2025-11-19
- **Agent**: research-specialist
- **Topic**: Relocating markdown-link-check.json from config/ to scripts/
- **Report Type**: codebase analysis

## Executive Summary

The relocation of markdown-link-check.json from `.claude/config/` to `.claude/scripts/` is a straightforward refactoring task involving 5 files that reference this configuration. The move aligns with directory organization standards since the `config/` directory is not part of the documented structure and the JSON file is exclusively used by validation scripts in `scripts/`. All references use relative paths from project root, making the update pattern consistent across all affected files.

## Findings

### Current State Analysis

#### File Location and Content
- **Current path**: `/home/benjamin/.config/.claude/config/markdown-link-check.json`
- **File size**: 984 bytes
- **Purpose**: Configuration for markdown-link-check npm package
- **Content**: Defines ignore patterns for templates, anchors, specs, archives, and external URLs

The configuration file (lines 1-43) contains:
- 8 ignore patterns for template variables, placeholders, shell variables, regex patterns, anchors, specs, and archive directories
- Network settings: 10s timeout, retry on 429, 3 retries with 5s fallback delay
- Valid status codes: 200, 206

#### Files Requiring Updates

**5 files reference the configuration file**:

1. **validate-links.sh** (line 6)
   - Path: `/home/benjamin/.config/.claude/scripts/validate-links.sh`
   - Reference: `CONFIG_FILE=".claude/config/markdown-link-check.json"`
   - Usage: Primary validation script, uses npx markdown-link-check with --config flag (line 62)

2. **validate-links-quick.sh** (line 6)
   - Path: `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh`
   - Reference: `CONFIG_FILE=".claude/config/markdown-link-check.json"`
   - Usage: Quick validation for recently modified files (line 28)

3. **scripts/README.md** (line 31)
   - Path: `/home/benjamin/.config/.claude/scripts/README.md`
   - Reference: `- Uses configuration from \`.claude/config/markdown-link-check.json\``
   - Usage: Documentation of validate-links.sh features

4. **TODO.md** (line 14)
   - Path: `/home/benjamin/.config/.claude/TODO.md`
   - Reference: `- /home/benjamin/.config/.claude/config/markdown-link-check.json`
   - Usage: Listed as item to research/clean up (this move addresses that TODO item)

5. **broken-links-troubleshooting.md** (line 10)
   - Path: `/home/benjamin/.config/.claude/docs/troubleshooting/broken-links-troubleshooting.md`
   - Reference: `--config .claude/config/markdown-link-check.json`
   - Usage: Quick diagnostic command example

### Directory Standards Compliance

The current `config/` directory is problematic:
- **Not documented** in directory-organization.md standards (lines 8-19)
- **Contains only 1 file** (markdown-link-check.json)
- **Orphaned structure** - no README.md, no documented purpose

The documented standard directory structure is:
```
.claude/
├── scripts/        Standalone CLI tools
├── lib/            Sourced function libraries
├── commands/       Slash command definitions
├── agents/         Specialized AI assistants
├── docs/           Integration guides and standards
└── tests/          Test suites
```

### Rationale for scripts/ Placement

The markdown-link-check.json file belongs in `scripts/` because:

1. **Tool co-location**: It's exclusively used by validate-links*.sh scripts in that directory
2. **Standards alignment**: Eliminates undocumented config/ directory
3. **Discoverability**: Related files are in the same directory
4. **Precedent**: Scripts directory already contains all link validation infrastructure

## Recommendations

### 1. Move Configuration File

Move the file from `.claude/config/markdown-link-check.json` to `.claude/scripts/markdown-link-check.json`.

**Implementation steps**:
```bash
# Move the file
mv .claude/config/markdown-link-check.json .claude/scripts/

# Remove empty config directory
rmdir .claude/config/
```

### 2. Update Script References (2 files)

Update the CONFIG_FILE variable in both validation scripts:

**validate-links.sh** (line 6):
```bash
# Old: CONFIG_FILE=".claude/config/markdown-link-check.json"
# New: CONFIG_FILE=".claude/scripts/markdown-link-check.json"
```

**validate-links-quick.sh** (line 6):
```bash
# Old: CONFIG_FILE=".claude/config/markdown-link-check.json"
# New: CONFIG_FILE=".claude/scripts/markdown-link-check.json"
```

### 3. Update Documentation References (3 files)

**scripts/README.md** (line 31):
```markdown
# Old: - Uses configuration from `.claude/config/markdown-link-check.json`
# New: - Uses configuration from `.claude/scripts/markdown-link-check.json`
```

**broken-links-troubleshooting.md** (line 10):
```bash
# Old: --config .claude/config/markdown-link-check.json
# New: --config .claude/scripts/markdown-link-check.json
```

**TODO.md** (line 14):
Remove the line entirely since this move addresses the TODO item:
```markdown
# Remove: - /home/benjamin/.config/.claude/config/markdown-link-check.json
```

### 4. Verification Steps

After making changes, verify:

1. **Scripts still work**:
   ```bash
   bash .claude/scripts/validate-links-quick.sh 1
   ```

2. **Config file accessible**:
   ```bash
   test -f .claude/scripts/markdown-link-check.json && echo "Config found"
   ```

3. **Old directory removed**:
   ```bash
   ! test -d .claude/config/ && echo "Config directory removed"
   ```

4. **No remaining references**:
   ```bash
   grep -r "config/markdown-link-check" .claude/ && echo "FAIL: References remain" || echo "PASS: All updated"
   ```

### 5. Update scripts/README.md

Add a brief mention of the configuration file in the README to improve discoverability.

Add after the "Current Scripts" section or within the validate-links.sh entry:

```markdown
### Configuration Files

**markdown-link-check.json**
- **Purpose**: Configuration for markdown-link-check npm package
- **Used by**: validate-links.sh, validate-links-quick.sh
- **Features**: Ignore patterns for templates, anchors, specs directories
```

## Implementation Order

1. Move file: `config/markdown-link-check.json` -> `scripts/markdown-link-check.json`
2. Update: `scripts/validate-links.sh` line 6
3. Update: `scripts/validate-links-quick.sh` line 6
4. Update: `scripts/README.md` line 31 and add configuration section
5. Update: `docs/troubleshooting/broken-links-troubleshooting.md` line 10
6. Update: `TODO.md` - remove line 14
7. Remove: Empty `config/` directory
8. Verify: Run validate-links-quick.sh to confirm functionality

## References

### Files Analyzed
- `/home/benjamin/.config/.claude/config/markdown-link-check.json` (lines 1-43)
- `/home/benjamin/.config/.claude/scripts/validate-links.sh` (lines 1-87, specifically line 6, 62)
- `/home/benjamin/.config/.claude/scripts/validate-links-quick.sh` (lines 1-44, specifically line 6, 28)
- `/home/benjamin/.config/.claude/scripts/README.md` (lines 1-239, specifically line 31)
- `/home/benjamin/.config/.claude/TODO.md` (lines 1-24, specifically line 14)
- `/home/benjamin/.config/.claude/docs/troubleshooting/broken-links-troubleshooting.md` (lines 1-137, specifically line 10)
- `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md` (lines 1-276)

### Standards Referenced
- Directory Organization Standards: `/home/benjamin/.config/.claude/docs/concepts/directory-organization.md`
- Scripts README: `/home/benjamin/.config/.claude/scripts/README.md`

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_claude_scripts_readmemd_research_and_pla_plan.md](../plans/001_claude_scripts_readmemd_research_and_pla_plan.md)
- **Implementation**: [Will be updated by /build command]
- **Date**: 2025-11-19

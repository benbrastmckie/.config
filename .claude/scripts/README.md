# System Management and Validation Scripts

This directory contains standalone executable scripts for system maintenance, validation, and migration operations.

## Purpose

Scripts provide **task-specific command-line utilities** for:
- **Link validation** - Finding and fixing broken markdown links
- **Migration operations** - Updating references and relocating files
- **Performance analysis** - Analyzing system metrics and behavior
- **System validation** - Verifying integrity and compliance

## Characteristics

**Executable scripts with CLI interfaces**:
- Run directly from command line: `bash .claude/scripts/script-name.sh [options]`
- Include argument parsing (`--dry-run`, `--verbose`, `--help`)
- Provide formatted output with progress indicators
- Return meaningful exit codes
- Complete operational tasks end-to-end

## Current Scripts

### Link Validation

**validate-links.sh**
- **Purpose**: Comprehensive markdown link validation using `markdown-link-check`
- **Usage**: `bash .claude/scripts/validate-links.sh`
- **Features**:
  - Checks `.claude/docs`, `.claude/commands`, `.claude/agents`, READMEs
  - Uses configuration from `.claude/config/markdown-link-check.json`
  - Generates timestamped logs in `.claude/tmp/link-validation/`
  - Color-coded output with error counts
- **Output**: Validation report with broken link details
- **Dependencies**: Node.js, `markdown-link-check` npm package

**validate-links-quick.sh**
- **Purpose**: Fast link validation without external dependencies
- **Usage**: `bash .claude/scripts/validate-links-quick.sh`
- **Features**:
  - Pure bash implementation (no npm required)
  - Checks only `.claude/docs` directory
  - Faster execution for quick checks
- **Output**: List of broken links with expected paths
- **Dependencies**: None (bash only)

### Link Fixing

**fix-absolute-to-relative.sh**
- **Purpose**: Convert absolute filesystem paths to relative markdown links
- **Usage**: `bash .claude/scripts/fix-absolute-to-relative.sh [--dry-run]`
- **Features**:
  - Fixes paths like `/home/user/.config/file.md` → `file.md`
  - Supports dry-run mode for preview
  - Processes all markdown files in active documentation
- **Output**: Count of files modified and changes made

**fix-duplicate-paths.sh**
- **Purpose**: Remove duplicate path components in links
- **Usage**: `bash .claude/scripts/fix-duplicate-paths.sh [--dry-run]`
- **Example**: `.claude/docs/.claude/docs/file.md` → `.claude/docs/file.md`
- **Features**: Pattern detection and automated correction

**fix-renamed-files.sh**
- **Purpose**: Update links to reflect renamed files
- **Usage**: `bash .claude/scripts/fix-renamed-files.sh [--dry-run]`
- **Features**: Searches for old references and updates to new paths

**rollback-link-fixes.sh**
- **Purpose**: Revert link fixing changes
- **Usage**: `bash .claude/scripts/rollback-link-fixes.sh`
- **Features**: Git-based rollback to previous state

### Migration and Updates

**update-template-references.sh**
- **Purpose**: Automated migration of template file references
- **Usage**: `bash .claude/scripts/update-template-references.sh [--dry-run] [--verbose]`
- **Features**:
  - Updates references from old to new paths
  - Dry-run mode shows changes without modifying files
  - Verbose mode shows detailed progress
  - Automatic verification after migration
- **Example**: Used in Phase 7 to migrate sub-supervisor-template.md references
- **Output**: Summary of files updated and verification results

### Analysis and Metrics

**analyze-coordinate-performance.sh**
- **Purpose**: Analyze `/coordinate` command performance metrics
- **Usage**: `bash .claude/scripts/analyze-coordinate-performance.sh`
- **Features**:
  - Parse execution logs for timing data
  - Calculate phase durations
  - Generate performance reports
- **Output**: Performance analysis with bottleneck identification

## vs lib/ (Sourced Libraries)

| Aspect | scripts/ | lib/ |
|--------|----------|------|
| **Purpose** | Standalone operational tasks | Reusable function libraries |
| **Execution** | `bash scripts/name.sh` | `source lib/name.sh` |
| **Interface** | CLI with argument parsing | Function calls |
| **Output** | Formatted reports, progress | Return values, exit codes |
| **Scope** | Complete end-to-end operations | Modular building blocks |
| **Examples** | validate-links.sh, fix-*.sh | plan-parsing.sh, error-handling.sh |
| **Dependencies** | May use external tools | Pure bash functions |
| **State** | Stateful (modifies files/system) | Stateless (pure functions) |
| **Reusability** | Task-specific | General-purpose |

## vs utils/ (Specialized Helpers)

| Aspect | scripts/ | utils/ |
|--------|----------|--------|
| **Purpose** | System management operations | Specialized helper utilities |
| **Scope** | System-wide tasks | Specific use cases |
| **Examples** | Migration, validation | Compatibility shims, metrics display |
| **Documentation** | This README | [../utils/README.md](../utils/README.md) |

## Decision Matrix: When to Use scripts/

Use `scripts/` when:
- ✓ Building a standalone command-line utility
- ✓ Task has complete workflow (input → processing → output)
- ✓ Need CLI argument parsing and help text
- ✓ Operation is system-level (validation, migration, analysis)
- ✓ Output should be formatted for human consumption
- ✓ Task may use external tools (npm, curl, git)

Use `lib/` instead when:
- ✗ Building reusable functions for sourcing
- ✗ Logic needs to be called from multiple commands
- ✗ Functionality is a building block, not complete task
- ✗ Pure functions without side effects preferred

Use `utils/` instead when:
- ✗ Building specialized helper for specific subsystem
- ✗ Providing compatibility or bridge functionality
- ✗ Tool is between general lib/ and specific scripts/

## Common Patterns

### Dry-Run Mode
Most scripts support `--dry-run` to preview changes:
```bash
bash .claude/scripts/fix-absolute-to-relative.sh --dry-run
# Shows what would change without modifying files
```

### Verbose Output
Many scripts support `--verbose` for detailed progress:
```bash
bash .claude/scripts/update-template-references.sh --verbose
# Shows file-by-file progress
```

### Help Text
All scripts should support `--help`:
```bash
bash .claude/scripts/validate-links.sh --help
# Displays usage information
```

### Exit Codes
Scripts use standard exit codes:
- `0` - Success, no errors
- `1` - General error
- `2` - Usage error (invalid arguments)

## Creating New Scripts

When creating a new script in this directory:

1. **Add shebang and set flags**:
   ```bash
   #!/bin/bash
   set -e  # Exit on error
   ```

2. **Include argument parsing**:
   ```bash
   while [[ $# -gt 0 ]]; do
     case $1 in
       --dry-run) DRY_RUN=1; shift ;;
       --help) show_help; exit 0 ;;
       *) echo "Unknown option: $1"; exit 2 ;;
     esac
   done
   ```

3. **Provide help text**:
   ```bash
   show_help() {
     echo "Usage: $0 [--dry-run] [--verbose]"
     echo "Description of what script does"
   }
   ```

4. **Use descriptive output**:
   ```bash
   echo "Processing files..."
   echo "✓ Success: 10 files updated"
   echo "✗ Error: 2 files failed"
   ```

5. **Verify results**:
   ```bash
   # Always verify after making changes
   if validation_passes; then
     echo "✓ Verification successful"
   else
     echo "✗ Verification failed"
     exit 1
   fi
   ```

6. **Update this README**:
   - Add script to appropriate category
   - Document purpose, usage, features, output

## Related Documentation

- [lib/README.md](../lib/README.md) - Sourced function libraries
- [utils/README.md](../utils/README.md) - Specialized helper utilities
- [.claude/README.md](../README.md) - Complete directory structure guide
- [CLAUDE.md](/home/benjamin/.config/CLAUDE.md) - Project standards and guidelines

## Best Practices

1. **Keep scripts focused** - One script, one clear purpose
2. **Provide dry-run mode** - Let users preview changes
3. **Use descriptive names** - `validate-links.sh` not `check.sh`
4. **Document thoroughly** - Help text, comments, README entry
5. **Verify operations** - Check results before declaring success
6. **Handle errors gracefully** - Meaningful error messages
7. **Make executable** - `chmod +x script-name.sh`
8. **Follow naming conventions** - `kebab-case-names.sh`

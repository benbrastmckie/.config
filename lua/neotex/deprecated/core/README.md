# Deprecated Core Modules

Legacy core configuration modules replaced by updated implementations.

## Purpose

This directory contains the original core configuration modules that have been refactored and moved to the active configuration directories. Files are preserved for reference and migration assistance.

## Contents

### autocmds.lua

Legacy autocommand definitions. Functionality moved to `nvim/lua/neotex/config/autocmds.lua` with improvements.

### functions.lua

Original utility functions. Replaced by modular utilities in `nvim/lua/neotex/util/` and `nvim/lua/neotex/core/`.

### init.lua

Legacy core initialization module. Replaced by improved initialization in active core directory.

### keymaps.lua

Original keymap definitions. Functionality moved to `nvim/lua/neotex/config/keymaps.lua` with reorganization.

### options.lua

Legacy NeoVim option settings. Replaced by `nvim/lua/neotex/config/options.lua` with better organization.

## Migration Path

The deprecated core modules have been migrated as follows:

| Deprecated File | Active Location | Changes |
|----------------|-----------------|---------|
| autocmds.lua | config/autocmds.lua | Reorganized by category |
| functions.lua | util/ & core/ | Split into focused modules |
| init.lua | core/init.lua | Improved error handling |
| keymaps.lua | config/keymaps.lua | Better documentation |
| options.lua | config/options.lua | Grouped by purpose |

## Differences from Active Code

The deprecated modules differ from active implementations in:

- **Organization**: Monolithic files vs. modular structure
- **Error Handling**: Basic vs. robust pcall wrappers
- **Documentation**: Minimal vs. comprehensive comments
- **Standards Compliance**: Older conventions vs. current CODE_STANDARDS.md

## Reusing Deprecated Code

To extract functionality from deprecated modules:

1. Identify the specific function or configuration needed
2. Check if equivalent exists in active code
3. If migrating, update to current code standards:
   - 2-space indentation
   - Snake_case naming
   - Pcall error handling
   - Comprehensive documentation
4. Place in appropriate active directory (config/, core/, or util/)

## Related Documentation

- [Active Core Modules](../../core/README.md) - Current core functionality
- [Active Config](../../config/README.md) - Current configuration modules
- [Active Utilities](../../util/README.md) - Current utility functions
- [Code Standards](../../../../docs/CODE_STANDARDS.md) - Coding conventions

## Navigation

- **Parent**: [nvim/lua/neotex/deprecated/](../README.md)
- **Sibling**: [after](../after/README.md), [extras](../extras/README.md)

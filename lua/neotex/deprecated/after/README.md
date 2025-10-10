# Deprecated Runtime Files

Legacy Vim runtime files preserved for reference.

## Purpose

This directory contains deprecated runtime files that were loaded after standard NeoVim configuration, including legacy tree-sitter queries.

## Contents

### queries/

Legacy tree-sitter query definitions that have been replaced or removed.

See [queries/README.md](queries/README.md) for details.

## Migration

These files are **not loaded** during NeoVim initialization. Active runtime files are located in:

- Active after/ files: Moved to appropriate plugin directories or removed
- Active queries: Located in standard tree-sitter query locations

## Related Documentation

- [Deprecated Root](../README.md) - Parent deprecated directory
- [Active Plugins](../../plugins/README.md) - Current plugin system

## Navigation

- **Parent**: [nvim/lua/neotex/deprecated/](../README.md)
- **Subdirectories**: [queries](queries/README.md)

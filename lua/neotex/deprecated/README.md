# Deprecated Code

Legacy plugin configurations and modules preserved for reference.

## Purpose

This directory contains deprecated plugin specifications and configuration modules that have been replaced by newer implementations. Files are retained for:

- Historical reference
- Migration assistance
- Potential future reuse
- Understanding evolution of the configuration

## Contents

### Plugin Specifications (Root Level)

Deprecated lazy.nvim plugin specifications:

- **alpha.lua** - Startup screen plugin (replaced by dashboard)
- **autopairs.lua** - Auto-pairing plugin (replaced or removed)
- **colorizer.lua** - Color highlighting (functionality integrated elsewhere)
- **comment.lua** - Comment utilities (replaced by newer comment plugin)
- **dressing.lua** - UI improvement plugin (integrated into main UI)
- Additional deprecated plugin specs

### Subdirectories

- **[after/](after/README.md)** - Legacy runtime files and syntax queries
- **[core/](core/README.md)** - Original core configuration modules
- **[extras/](extras/README.md)** - Experimental or optional features

## Migration Status

Code in this directory is **not loaded** during NeoVim initialization. The main configuration uses updated implementations located in:

- Active plugins: `nvim/lua/neotex/plugins/`
- Active core config: `nvim/lua/neotex/config/` and `nvim/lua/neotex/core/`

## Using Deprecated Code

To reactivate deprecated functionality:

1. Review the deprecated module to understand its purpose
2. Check if equivalent functionality exists in active code
3. If needed, copy the module to the appropriate active directory
4. Update require paths and dependencies
5. Test thoroughly before committing

## Removal Policy

Deprecated code may be removed when:

- Replacement functionality is well-established (>6 months)
- No active migration needs exist
- Code no longer provides useful reference

## Related Documentation

- [Active Plugins](../plugins/README.md) - Current plugin specifications
- [Core Configuration](../core/README.md) - Active core modules
- [Code Standards](../../../docs/CODE_STANDARDS.md) - Current coding standards

## Navigation

- **Parent**: [nvim/lua/neotex/](../README.md)
- **Subdirectories**: [after](after/README.md), [core](core/README.md), [extras](extras/README.md)

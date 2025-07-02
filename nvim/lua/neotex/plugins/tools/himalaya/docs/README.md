# Documentation

Technical documentation, architecture guides, and testing resources for the Himalaya email plugin.

## Documents

### ARCHITECTURE.md
Comprehensive architecture guide covering:
- **Module hierarchy** and layered dependency rules
- **Dependency management** with resolved circular dependencies
- **External dependencies** (binaries, Lua modules, system requirements)
- **Development patterns** for state management, error handling, notifications
- **Architecture validation** tools and design principles

This combines architecture documentation with dependency information for a complete technical reference.

### TEST_CHECKLIST.md
Comprehensive testing checklist with:
- **All 31 commands** organized by category with expected behavior
- **Workflow testing** for email reading, composition, sync operations
- **State persistence** and configuration testing
- **Performance benchmarks** for regression testing
- **Integration testing** for notifications, state management, architecture compliance

Use this checklist after refactoring phases and before releases to ensure functionality is preserved.

### SYNC_STAT.md
Current sync status implementation documentation:
- **Implementation overview** of the unified sync manager
- **Progress parsing** improvements with folder-focused display
- **Technical details** of parsing logic and display format
- **Error handling** and debugging support
- **Historical context** showing how original sync display issues were resolved

Documents the current working solution for sync progress display.

## Purpose

This documentation serves multiple audiences:

### For Developers
- **Architecture guidelines** for maintaining module boundaries
- **Development patterns** for consistent code style
- **Testing procedures** for validating changes

### For Maintainers
- **System overview** for understanding component relationships
- **Troubleshooting guides** for common issues
- **Performance baselines** for monitoring regression

### For Contributors
- **Onboarding reference** for understanding the codebase
- **Testing requirements** for pull requests
- **Design principles** for architectural decisions

## Related Documentation

- **Specifications**: See [../spec/README.md](../spec/README.md) for planning documents
- **Module READMEs**: Each subdirectory has detailed module documentation
- **User Guide**: See main [../README.md](../README.md) for usage information

## Navigation
- [< Himalaya Plugin](../README.md)
- [Architecture Guide](ARCHITECTURE.md)
- [Testing Checklist](TEST_CHECKLIST.md)
- [Sync Implementation](SYNC_STAT.md)
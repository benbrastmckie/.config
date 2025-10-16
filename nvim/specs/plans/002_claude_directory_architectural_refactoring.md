# Claude Directory Architectural Refactoring Implementation Plan

## Metadata
- **Date**: 2025-09-29
- **Feature**: Comprehensive refactoring of Claude AI integration directory to address architectural and maintainability issues
- **Scope**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/` (9,929 lines across 22 files)
- **Estimated Phases**: 4
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**: `/home/benjamin/.config/nvim/specs/reports/008_claude_directory_refactoring_analysis.md`

## Overview

This plan implements a comprehensive architectural refactoring of the Claude AI integration directory based on critical findings from the refactoring analysis report. The current codebase contains 9,929 lines across 22 files with severe architectural issues, including a 2,275-line monolithic file that violates single responsibility principles and makes the codebase unmaintainable.

The refactoring will transform the current monolithic structure into a well-organized, modular system with clear separation of concerns, improved testability, and better maintainability. The largest file will be reduced from 2,275 lines to under 500 lines through strategic decomposition.

## Success Criteria

- [ ] `core/worktree.lua` (2,275 lines) decomposed into focused modules (<500 lines each)
- [ ] `commands/picker.lua` (1,114 lines) modularized into separate concerns
- [ ] `util/mcp_server.lua` (715 lines) split into lifecycle, port, and process management
- [ ] Configuration extracted from `util/system-prompts.lua` into separate data modules
- [ ] Code duplication reduced by centralizing common patterns (175 notification calls)
- [ ] All existing functionality preserved with backward compatibility
- [ ] Improved test coverage enabled by smaller, focused modules
- [ ] Consistent directory structure with standardized naming (`utils/` not `util/`)
- [ ] Documentation updated to reflect new modular architecture
- [ ] Average file size reduced from 450 lines to 200-300 lines

## Technical Design

### Architecture Overview
```
Current Monolithic Structure ──→ Modular Architecture
     │                              │
     ├─ core/worktree.lua (2,275)   ├─ core/worktree/ (6 modules)
     ├─ commands/picker.lua (1,114) ├─ commands/picker/ (5 modules)
     ├─ util/mcp_server.lua (715)   ├─ utils/mcp/ (5 modules)
     └─ util/system-prompts.lua     └─ utils/prompts/ (4 modules)
```

### Decomposition Strategy
1. **Function Extraction**: Large functions (>50 lines) split into focused helpers
2. **Concern Separation**: Mixed responsibilities separated into dedicated modules
3. **Configuration Externalization**: Hard-coded values moved to configuration modules
4. **Common Pattern Centralization**: Duplicated code moved to shared utilities

### Risk Mitigation
- **Incremental Extraction**: Extract modules one at a time with testing at each step
- **Backward Compatibility**: Maintain existing public APIs during transition
- **Comprehensive Testing**: Validate functionality after each extraction
- **Rollback Procedures**: Ability to revert changes if issues arise

## Implementation Phases

### Phase 1: Critical Monolith Decomposition
**Objective**: Break down the 2,275-line `core/worktree.lua` into manageable, focused modules
**Complexity**: High

Tasks:
- [ ] Create `core/worktree/` directory structure
- [ ] Extract git operations from `core/worktree.lua` lines 180-253 to `core/worktree/git_operations.lua`
- [ ] Extract terminal integration from lines 256-402 (`_spawn_terminal_tab()`) to `core/worktree/terminal_integration.lua`
- [ ] Extract session management logic to `core/worktree/session_manager.lua`
- [ ] Extract restoration logic from lines 1436-1744 (`restore_worktree_session()`) to `core/worktree/restoration.lua`
- [ ] Extract UI interaction flows to `core/worktree/ui_handlers.lua`
- [ ] Create coordinating `core/worktree/index.lua` with public API
- [ ] Update imports in dependent modules to use new structure
- [ ] Remove original `core/worktree.lua` file

Testing:
```bash
# Test worktree creation workflow
:ClaudeWorktree
# Test session restoration
:ClaudeRestoreWorktree
# Test all worktree-related commands
:lua require("neotex.plugins.ai.claude.core.worktree").telescope_worktrees()
```

Expected outcome: 2,275-line file decomposed into 6 focused modules of 200-400 lines each

### Phase 2: Commands System Modularization
**Objective**: Refactor the complex `commands/picker.lua` into a modular picker architecture
**Complexity**: Medium

Tasks:
- [ ] Create `commands/picker/` directory structure
- [ ] Extract entry building logic from lines 20-105 to `commands/picker/entry_builder.lua`
- [ ] Extract keybinding logic from lines 860-1000+ to `commands/picker/keybindings.lua`
- [ ] Extract command execution actions to `commands/picker/actions.lua`
- [ ] Extract preview functionality to `commands/picker/previewer.lua`
- [ ] Create main picker orchestration in `commands/picker/main.lua`
- [ ] Update `commands/picker.lua` to use new modular structure
- [ ] Verify all command picker functionality works correctly

Testing:
```bash
# Test command picker interface
:ClaudeCommands
# Test all picker actions (keyboard shortcuts, previews, command execution)
# Verify hierarchical command display works correctly
```

Expected outcome: 1,114-line picker decomposed into 5 focused modules with clear responsibilities

### Phase 3: Utility Module Separation and Code Quality
**Objective**: Separate utility module concerns and address code duplication patterns
**Complexity**: Medium

Tasks:
- [ ] Create `utils/mcp/` directory for MCP server modularization
- [ ] Extract server lifecycle management to `utils/mcp/server_lifecycle.lua`
- [ ] Extract port management to `utils/mcp/port_manager.lua`
- [ ] Extract process management to `utils/mcp/process_manager.lua`
- [ ] Extract state tracking to `utils/mcp/state_tracker.lua`
- [ ] Create `utils/mcp/api.lua` for public interface
- [ ] Create `utils/prompts/` directory structure
- [ ] Extract prompt data to separate files in `utils/prompts/data/`
- [ ] Create prompt management API in `utils/prompts/manager.lua`
- [ ] Create `utils/common/` directory for shared utilities
- [ ] Centralize notification calls in `utils/common/notifications.lua`
- [ ] Create common module loader in `utils/common/module_loader.lua`
- [ ] Extract terminal utilities to `utils/common/terminal_utils.lua`
- [ ] Replace 175 scattered notification calls with centralized system
- [ ] Replace 33 `pcall(require)` patterns with common loader

Testing:
```bash
# Test MCP server functionality
:lua require("neotex.plugins.ai.claude.utils.mcp.api").start()
# Test prompt system
:lua require("neotex.plugins.ai.claude.utils.prompts.manager").get_default()
# Verify all notifications work correctly
# Test error handling with common utilities
```

Expected outcome: Utility modules properly separated, code duplication significantly reduced

### Phase 4: Configuration Management and Structure Standardization
**Objective**: Centralize configuration management and standardize directory structure
**Complexity**: Low

Tasks:
- [ ] Create `config/` directory for centralized configuration
- [ ] Extract default values to `config/defaults.lua`
- [ ] Extract terminal commands to `config/terminal_commands.lua`
- [ ] Extract timeout configurations to `config/timeouts.lua`
- [ ] Extract path configurations to `config/paths.lua`
- [ ] Standardize directory naming (rename `util/` to `utils/` where inconsistent)
- [ ] Update all import paths to reflect new structure
- [ ] Update `README.md` files to reflect new modular organization
- [ ] Update API documentation for new module structure
- [ ] Create migration guide for any external consumers
- [ ] Run comprehensive integration tests to verify all functionality

Testing:
```bash
# Test entire Claude integration system
:lua require("neotex.plugins.ai.claude").smart_toggle()
:ClaudeCommands
:ClaudeWorktree
:ClaudeSessions
# Test visual selection with <leader>ac
# Test session management workflows
# Verify all terminal integrations work
# Test error handling and notifications
```

Expected outcome: Consistent, well-organized structure with centralized configuration

## Testing Strategy

### Regression Testing Framework
- **Pre-refactoring baseline**: Document all current functionality and API contracts
- **Phase-by-phase validation**: Test after each module extraction
- **End-to-end workflow testing**: Validate complete user workflows remain intact
- **API compatibility testing**: Ensure public interfaces remain stable

### Integration Testing Approach
- **Module boundary testing**: Verify new module interfaces work correctly
- **Configuration loading testing**: Validate centralized configuration system
- **Error handling validation**: Test error paths with new module structure
- **Performance verification**: Ensure refactoring doesn't impact performance

### Validation Commands by Phase
```bash
# Phase 1 - Worktree decomposition
:ClaudeWorktree
:ClaudeRestoreWorktree
:lua require("neotex.plugins.ai.claude.core.worktree").telescope_worktrees()

# Phase 2 - Picker modularization
:ClaudeCommands
# Test keyboard shortcuts and preview functionality

# Phase 3 - Utility separation
:lua require("neotex.plugins.ai.claude.utils.mcp.api").start()
# Test all notification systems

# Phase 4 - Configuration and structure
:lua require("neotex.plugins.ai.claude").smart_toggle()
# Complete end-to-end testing
```

## Documentation Requirements

### Updated Documentation
- **Module READMEs**: Create README.md for each new module directory following CLAUDE.md standards
- **API Documentation**: Update function documentation for new module boundaries
- **Architecture Documentation**: Document new modular architecture and design decisions
- **Migration Guide**: Guide for any external code that imports these modules

### Documentation Structure Updates
```markdown
# Updated README Structure
claude/
├── core/worktree/README.md     # Worktree module documentation
├── commands/picker/README.md   # Picker system documentation
├── utils/mcp/README.md         # MCP server documentation
├── utils/prompts/README.md     # Prompt system documentation
├── utils/common/README.md      # Shared utilities documentation
└── config/README.md            # Configuration system documentation
```

## Dependencies

### Internal Dependencies
- Existing Claude integration functionality must remain intact
- Terminal integration dependencies (Kitty, WezTerm detection)
- Session management and persistence systems
- Telescope picker framework integration

### External Dependencies
- `plenary.nvim` for utilities and async operations
- `telescope.nvim` for UI picker functionality
- Git worktree functionality for repository operations
- Terminal applications for tab/window management

### Module Interdependencies
- Configuration modules must be available to all other modules
- Common utilities must be established before module refactoring
- API coordination modules must be created after extraction

## Migration Path

### Phase 1 Preparation
1. **Backup current implementation**: Create safety checkpoint
2. **Document existing APIs**: Catalog all public function signatures
3. **Create test coverage**: Ensure functionality can be validated
4. **Set up development branch**: Work in isolation from main branch

### Phase 2 Incremental Extraction
1. **Start with least risky modules**: Begin with configuration extraction
2. **Maintain backward compatibility**: Keep original interfaces during transition
3. **Test thoroughly at each step**: Validate after every extraction
4. **Update imports progressively**: Modify dependent code incrementally

### Phase 3 Integration and Cleanup
1. **Consolidate new module structure**: Ensure all extractions are complete
2. **Remove deprecated code**: Clean up original monolithic files
3. **Update all documentation**: Reflect new architecture throughout
4. **Final integration testing**: Comprehensive validation of entire system

## Risk Assessment and Mitigation

### High Risk Areas
- **`core/worktree.lua` extraction**: Complex business logic with many dependencies
  - *Mitigation*: Extract in small, testable chunks with validation at each step
- **Session management changes**: Critical for user workflow continuity
  - *Mitigation*: Maintain exact API compatibility during transition

### Medium Risk Areas
- **MCP server refactoring**: Important for external tool integration
  - *Mitigation*: Test server lifecycle thoroughly, maintain state consistency
- **Picker functionality changes**: Central to user command interface
  - *Mitigation*: Validate all keyboard shortcuts and UI interactions

### Low Risk Areas
- **Configuration extraction**: Mostly data movement with clear boundaries
- **Directory structure changes**: Import path updates with clear patterns

## Expected Outcomes

### Quantitative Improvements
- **Largest file size**: Reduced from 2,275 lines to <500 lines
- **Average file size**: Reduced from 450 lines to 200-300 lines
- **Total files**: Increased from 22 to ~40 (better organization)
- **Code duplication**: Reduced by centralizing 175+ notification calls
- **Function length violations**: Eliminated through decomposition

### Qualitative Benefits
- **Maintainability**: Dramatically improved with focused, single-responsibility modules
- **Testability**: Individual modules can be tested in isolation
- **Extensibility**: Clear module boundaries enable easier feature additions
- **Documentation**: Smaller modules are easier to document comprehensively
- **Onboarding**: New developers can understand individual modules more easily

## Notes

### Refactoring Principles Applied
- **Single Responsibility Principle**: Each module has one clear purpose
- **Don't Repeat Yourself**: Common patterns centralized in shared utilities
- **Separation of Concerns**: Business logic, UI, configuration, and utilities separated
- **Interface Segregation**: Modules depend only on interfaces they actually use

### Post-Refactoring Maintenance
- **Easier debugging**: Issues can be isolated to specific modules
- **Safer changes**: Modifications have limited blast radius
- **Better performance**: Targeted optimizations possible per module
- **Clearer responsibilities**: Module boundaries enforce architectural decisions

### Future Enhancement Opportunities
- **Module-specific testing**: Unit tests for individual modules
- **Performance profiling**: Per-module performance analysis
- **Feature additions**: New functionality can be added as separate modules
- **Code reuse**: Extracted utilities can be used across other parts of the codebase

---

**Implementation Timeline**: 14-19 days of focused refactoring work across 4 phases
**Risk Level**: Medium (careful extraction required, but well-analyzed approach)
**Impact**: Transformational improvement in codebase maintainability and organization
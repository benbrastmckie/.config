# Himalaya Development Guidelines

This document provides comprehensive guidelines for development in the Himalaya project. These principles ensure clean, maintainable, and efficient code while respecting the realities of a working Neovim plugin.

## Core Philosophy

### Evolution, Not Revolution
**IMPORTANT**: While we strive for architectural purity, this codebase acknowledges pragmatic compromises necessary for a functional Neovim plugin. Document these compromises clearly and work toward better patterns over time.

### Systematic Analysis Before Implementation
Before implementing any changes, conduct a thorough analysis to understand:
1. How new changes will integrate with existing code
2. What redundancies can be eliminated without breaking functionality
3. How to improve simplicity and maintainability
4. What existing patterns and working code can be preserved
5. Where pragmatic compromises are acceptable

The goal is to enhance the unity, elegance, and integrity of the codebase through thoughtful evolution.

## Design Principles

### Core Principles
1. **Single Source of Truth**: One authoritative module for each domain (e.g., `core/state.lua` for all state)
2. **Pragmatic Architecture**: Accept necessary compromises (e.g., config UI dependencies for keybindings)
3. **Incremental Improvement**: Evolve the codebase gradually while maintaining functionality
4. **Systematic Integration**: New code must work with existing patterns
5. **Test-Driven Migration**: Run `:HimalayaTest all` with 100% pass rate before proceeding
6. **Living Documentation**: Keep documentation accurate to implementation reality

### Code Quality Goals
Every refactor should improve:
- **Simplicity**: Reduce complexity where possible without losing functionality
- **Unity**: Ensure components work together (even with some coupling)
- **Maintainability**: Balance ideal patterns with practical needs
- **Reliability**: Preserve all working functionality through migrations
- **Testability**: Improve test coverage with each change

## Development Process

### Pre-Implementation Analysis
Before writing any code:

1. **Analyze Existing Codebase**
   ```markdown
   - What modules will be affected?
   - What can be deleted or simplified?
   - What redundancies exist?
   - How will new code integrate?
   ```

2. **Design for Simplicity**
   ```markdown
   - Can existing modules be reused?
   - What is the minimal implementation?
   - How can we reduce total lines of code?
   - What abstractions can be eliminated?
   ```

3. **Plan Integration**
   ```markdown
   - How will changes affect other modules?
   - What APIs need updating?
   - What tests need modification?
   - What documentation needs updates?
   ```

### Phase-Based Development

Each refactor MUST follow a phase-based approach with rigorous testing:

```markdown
### Phase X: [Name] (Timeline)

1. **Pre-Phase Analysis**:
   - [ ] Analyze affected modules and dependencies
   - [ ] Identify what can be improved without breaking functionality
   - [ ] Document current architectural compromises
   - [ ] Plan migration path that preserves working code

2. **Implementation**:
   - [ ] Preserve backward compatibility during migration
   - [ ] Write new tests for refactored modules
   - [ ] Update existing code incrementally
   - [ ] Document any pragmatic compromises made

3. **Testing Protocol** (MANDATORY):
   - [ ] Run `:HimalayaTest all` - MUST achieve 100% pass rate
   - [ ] Write new unit tests for refactored modules
   - [ ] Update integration tests as needed
   - [ ] Manual testing of key workflows
   - [ ] Document any test failures and fixes

4. **Documentation**:
   - [ ] Update REFACTOR.md with progress
   - [ ] Document architectural decisions and compromises
   - [ ] Update affected README.md files
   - [ ] Create migration notes if needed

5. **Commit & Review**:
   - [ ] Atomic commit for each phase
   - [ ] Clear message: "Phase X: [Description]"
   - [ ] List improvements and any compromises
   - [ ] Request manual testing from users

6. **User Approval**:
   - [ ] Wait for manual testing confirmation
   - [ ] Address any issues found
   - [ ] Only proceed to next phase after approval
```

### Architectural Patterns

The codebase follows these established patterns:

1. **Unified State Management**
   ```lua
   -- All state goes through core/state.lua
   local state = require('neotex.plugins.tools.himalaya.core.state')
   state.set_current_folder('INBOX')
   ```

2. **Consistent Error Handling**
   ```lua
   local ok, result = pcall(operation)
   if not ok then
     logger.error('Operation failed', { context = 'function_name' })
     notify.himalaya('Operation failed', notify.categories.ERROR)
     return nil, result
   end
   ```

3. **Event-Driven Orchestration**
   ```lua
   -- Commands emit events through orchestrator
   local orchestrator = require('...commands.orchestrator')
   orchestrator.emit(event_constants.EMAIL_SENT, data)
   ```

4. **Pragmatic Compromises (Documented)**
   ```lua
   -- core/config.lua contains UI dependencies for keybindings
   -- This violates layering but provides essential functionality
   -- Future: Move to event-based keybinding system
   ```

## Testing Requirements

### Mandatory Testing Protocol
**CRITICAL**: Each phase MUST achieve 100% test pass rate before proceeding:

```vim
" Run all tests after each phase
:HimalayaTest all

" Expected output: All tests passing
" If any test fails, fix before proceeding
```

### Test Coverage Expectations
| Phase | Description | New Tests Required |
|-------|-------------|-------------------|
| Utils Refactor | Split utils.lua | ~25 unit tests |
| Config Restructure | Split config modules | ~20 unit tests |
| UI Cleanup | Reorganize UI | ~15 unit tests |
| Data Layer | Organize data ops | ~30 unit tests |

### Test Structure
```
test/
├── unit/              # New unit tests for refactored modules
│   ├── utils/        # Test each utils module
│   ├── config/       # Test configuration modules
│   └── data/         # Test data operations
├── integration/      # Cross-module tests
├── commands/         # Command-specific tests
└── performance/      # Performance regression tests
```

## Code Organization Guidelines

### Module Size Limits
- **Target**: 200-350 lines per file
- **Maximum**: 400 lines (requires justification)
- **Directories**: 6-8 files maximum

### Current Architectural Realities
The codebase contains pragmatic compromises:
- **config.lua**: Contains UI dependencies for keybindings
- **commands.lua**: Cross-layer dependencies for coordination
- **sync/manager.lua**: Soft UI dependencies via pcall

These are documented and accepted until better patterns emerge.

### Refactoring Approach
1. **Preserve Working Code**: Don't break functionality for purity
2. **Document Compromises**: Clearly mark architectural debt
3. **Plan Future Improvements**: Note migration paths in comments
4. **Test Everything**: 100% pass rate required at each step

## Documentation Standards

### README.md Requirements

Every subdirectory MUST have a README.md that includes:

```markdown
# Module/Directory Name

Clear description of purpose and functionality.

## Architecture
Overview of how this module fits into the larger system.

## Modules
- `module1.lua` - Brief description
- `module2.lua` - Brief description

## API Reference
Document all public functions and their usage.

## Dependencies
List what this module depends on and what depends on it.

## Examples
Show common usage patterns.

## Navigation
- [← Parent Directory](../README.md)
- [→ Subdirectory](subdirectory/README.md)
```

### Link Verification
After refactor completion:
1. Test all forward links (→)
2. Test all backward links (←)
3. Ensure no broken references
4. Update any moved/renamed files

## Migration Strategy

### Backward Compatibility Approach
Maintain functionality during migrations:
```lua
-- utils/init.lua provides backward compatibility
local M = {
  string = require('...utils.string'),
  email = require('...utils.email'),
  -- ... other modules
}

-- Preserve existing API during migration
function M.truncate_string(...)
  return M.string.truncate(...)
end

return M
```

### Incremental Migration
```lua
-- Phase 1: Create new structure, maintain old API
-- Phase 2: Update high-traffic imports
-- Phase 3: Update remaining imports
-- Phase 4: Remove compatibility layer (if safe)
```

## Post-Refactor Testing Support

### Phase Completion Workflow
After implementing each phase:

1. **Run Comprehensive Tests**
   ```vim
   :HimalayaTest all
   " Must see: All tests passing (100%)
   ```

2. **Update Documentation**
   ```markdown
   ## Phase X Complete
   - Tests: 100% passing
   - New tests added: [count]
   - Files refactored: [list]
   - Architectural compromises: [documented]
   ```

3. **Commit and Request Testing**
   ```bash
   git add -A
   git commit -m "Phase X: [Description]"
   # Request user to manually test
   ```

### Root Cause Analysis

**CRITICAL**: When tests fail, use error outputs to identify and fix ROOT CAUSES, not just symptoms:

1. **Analyze Error Patterns**
   ```lua
   -- Don't just patch the error
   -- Ask: WHY did this error occur?
   -- What architectural issue caused it?
   -- How can we prevent similar errors?
   ```

2. **Improve Code Quality**
   ```lua
   -- BAD: Add try/catch to suppress error
   -- GOOD: Fix the underlying design flaw
   
   -- BAD: Add nil check as bandaid
   -- GOOD: Ensure value is never nil through better design
   ```

3. **Document Root Causes**
   ```markdown
   ## Common Issues and Root Causes
   
   ### Issue: Module not found error
   **Symptom**: `module 'xyz' not found`
   **Root Cause**: Inconsistent module naming convention
   **Fix**: Standardize all module paths and update requires
   **Prevention**: Add module path validation in tests
   ```

### Error-Driven Improvements

Use test failures as opportunities to improve the codebase:

1. **Strengthen Architecture**
   - If a test reveals coupling issues, decouple the modules
   - If a test shows missing validation, add it at the source
   - If a test exposes race conditions, fix the async design

2. **Add Defensive Programming**
   ```lua
   -- Based on test failures, add:
   - Input validation at module boundaries
   - Clear error messages with context
   - Assertions for invariants
   ```

3. **Improve Test Coverage**
   ```lua
   -- For each bug found, add:
   - Unit test for the specific case
   - Integration test for the workflow
   - Regression test to prevent recurrence
   ```

### Test Failure Response Protocol

When users report test failures:

1. **Gather Complete Information**
   ```vim
   " Request full error output
   :messages
   " Check debug logs
   :HimalayaDebugLog
   " Get system info
   :HimalayaSystemInfo
   ```

2. **Identify Root Cause**
   - What assumption was violated?
   - What edge case was missed?
   - What integration point failed?

3. **Fix Systematically**
   - Address the root cause, not the symptom
   - Improve the architecture if needed
   - Add tests to prevent regression

4. **Document the Fix**
   ```markdown
   ## Fixed Issues
   - **Issue**: [Description]
   - **Root Cause**: [Why it happened]
   - **Fix**: [What was changed]
   - **Prevention**: [How we prevent recurrence]
   ```

## Quality Checklist

Before proceeding to next phase:

- [ ] `:HimalayaTest all` shows 100% pass rate
- [ ] New unit tests written for refactored modules
- [ ] Architectural compromises documented
- [ ] Working functionality preserved
- [ ] Documentation updated (REFACTOR.md, README.md)
- [ ] Atomic commit created
- [ ] Manual testing requested from user
- [ ] User approval received

## Example: Recent Refactoring Success

The Phase 1-5 refactoring demonstrates pragmatic evolution:

1. **Phase 4**: Consolidated orchestration (2 files → 1, preserved all functionality)
2. **Phase 5**: Merged utilities (400 lines integrated, backward compatibility maintained)
3. **Testing**: 100% pass rate maintained throughout
4. **Documentation**: Created ARCHITECTURE_V3.md with realistic migration plan
5. **Compromises**: Acknowledged config.lua UI dependencies as necessary

## Current Architecture Status

The codebase reflects pragmatic realities:
- **Working State Management**: Unified through `core/state.lua`
- **Event System**: Functional orchestration in `commands/orchestrator.lua`
- **Documented Compromises**: Config UI dependencies, command layer coupling
- **Future Path**: Clear migration strategy in ARCHITECTURE_V3.md

## Summary

These guidelines balance architectural ideals with the practical needs of a working Neovim plugin. By acknowledging necessary compromises while working toward better patterns, we maintain a reliable, testable, and evolvable codebase.

Remember: Evolution, not revolution. Every change should preserve functionality while incrementally improving architecture.
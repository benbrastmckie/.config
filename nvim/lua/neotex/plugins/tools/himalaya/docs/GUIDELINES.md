# Himalaya Development Guidelines

This document provides comprehensive guidelines for development in the Himalaya project. These principles ensure clean, maintainable, and efficient code.

## Core Philosophy

### No Backwards Compatibility Layers
**IMPORTANT**: This codebase maintains zero backwards compatibility layers. While temporary compatibility wrappers may be used during migration phases to facilitate testing, ALL backwards compatibility code MUST be removed by the final phase of any refactor.

### Systematic Analysis Before Implementation
Before implementing any changes, conduct a thorough analysis to understand:
1. How new changes will integrate with existing code
2. What redundancies can be eliminated
3. How to improve simplicity and maintainability
4. What existing code can be reused or refactored

The goal is to enhance the unity, elegance, and integrity of the codebase.

## Design Principles

### Core Principles
1. **Single Source of Truth**: One authoritative module for each domain
2. **No Redundancy**: Eliminate duplicate code and functionality
3. **Clean Architecture**: No backwards compatibility cruft
4. **Systematic Integration**: New code must enhance overall codebase quality
5. **Test Between Phases**: Verify each phase works before proceeding
6. **Complete Documentation**: All directories must have updated README.md files

### Code Quality Goals
Every refactor should improve:
- **Simplicity**: Reduce complexity and cognitive load
- **Unity**: Ensure components work together harmoniously
- **Maintainability**: Make future changes easier
- **Integrity**: Ensure the codebase is internally consistent

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

Each refactor MUST follow a phase-based approach:

```markdown
### Phase X: [Name] (Timeline)

1. **Pre-Phase Analysis**:
   - [ ] Analyze affected modules
   - [ ] Identify redundancies to eliminate
   - [ ] Plan integration strategy
   - [ ] Document expected simplifications

2. **Implementation**:
   - [ ] Write clean code (NO backwards compatibility)
   - [ ] Delete redundant code
   - [ ] Simplify existing modules
   - [ ] Use temporary wrappers ONLY if needed for testing

3. **Testing** (REQUIRED before next phase):
   - [ ] Create/update test files
   - [ ] Run all affected tests
   - [ ] Verify integration with existing code
   - [ ] Confirm no regressions
   - [ ] Document test results

4. **Cleanup**:
   - [ ] Remove ANY temporary compatibility code
   - [ ] Delete unused functions/modules
   - [ ] Simplify complex logic
   - [ ] Ensure code elegance

5. **Documentation**:
   - [ ] Update module documentation
   - [ ] Update affected README.md files
   - [ ] Verify all links work
   - [ ] Document design decisions

6. **Commit**:
   - [ ] Clear commit message
   - [ ] List all deletions/simplifications
   - [ ] Note code reduction metrics
```

### Final Phase Requirements

The final phase of ANY refactor MUST:

1. **Remove ALL Compatibility Layers**
   ```lua
   -- DELETE any temporary wrappers
   -- DELETE any migration helpers
   -- DELETE any backwards compatibility code
   ```

2. **Final Codebase Review**
   - Re-examine entire affected codebase
   - Identify any remaining redundancies
   - Simplify any complex abstractions
   - Ensure architectural unity

3. **Documentation Sweep**
   - Update ALL affected README.md files
   - Verify forward/backward links work
   - Ensure consistent coverage
   - Document the new architecture

## Testing Requirements

### Inter-Phase Testing
**CRITICAL**: Testing MUST be performed between EVERY phase:

1. **Unit Tests**: Test individual components
2. **Integration Tests**: Test component interactions
3. **Full Workflow Tests**: Test complete user workflows
4. **Regression Tests**: Ensure existing functionality works

### Test Before Proceeding
```vim
" Run tests after each phase
:HimalayaTest[Feature]

" Only proceed to next phase if ALL tests pass
" Document any test failures and fixes
```

### Test Structure
```
/scripts/features/
├── test_[feature]_foundation.lua    # Core infrastructure tests
├── test_[feature]_integration.lua   # Integration tests
└── test_[feature]_full.lua         # Complete workflow tests
```

## Code Cleanup Guidelines

### Identifying Redundancy
Look for:
- Duplicate functionality across modules
- Unused functions or variables
- Complex abstractions that can be simplified
- Multiple ways to do the same thing
- Dead code paths

### Simplification Strategies
1. **Merge Similar Modules**: Combine modules with overlapping functionality
2. **Delete Unused Code**: Remove any code not actively used
3. **Flatten Abstractions**: Remove unnecessary layers of indirection
4. **Unify APIs**: Ensure consistent interfaces across modules

### Example Refactor Metrics
Track and report simplification metrics:
```markdown
## Refactor Results
- Modules deleted: 6
- Lines removed: 931
- Code reduction: 40%
- Abstractions eliminated: 3
- APIs unified: 2
```

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

### Temporary Compatibility
When necessary for testing:
```lua
-- TEMPORARY: Remove in final phase
-- This wrapper allows testing during migration
local M = {}
local new_module = require('new_implementation')

-- Redirect old API to new
M.old_function = new_module.new_function

return M
```

### Final Cleanup
```lua
-- In final phase, replace ALL references:
-- OLD: require('old_module').old_function()
-- NEW: require('new_module').new_function()

-- Then DELETE the compatibility wrapper entirely
```

## Post-Refactor Testing Support

### Helping Users Run Tests
After completing a refactor, actively help users validate the changes:

1. **Provide Clear Test Commands**
   ```vim
   " Add these to documentation
   :HimalayaTest[Feature]           " Run specific feature tests
   :HimalayaTestIntegration         " Run full integration tests
   :HimalayaTestAll                 " Run complete test suite
   ```

2. **Create Test Guides**
   ```markdown
   ## Testing Your Installation
   1. Run `:HimalayaTest[Feature]` to verify the refactor
   2. If errors occur, see troubleshooting below
   3. Report issues with full error output
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

Before considering any refactor complete:

- [ ] All backwards compatibility removed
- [ ] All tests passing between phases
- [ ] Redundant code eliminated
- [ ] Architecture simplified
- [ ] Documentation updated
- [ ] README.md files complete with working links
- [ ] Code reduction metrics documented
- [ ] Test commands documented for users
- [ ] Root cause analysis process documented
- [ ] Common issues and fixes documented
- [ ] Final review for elegance and unity

## Example: Maildir Migration

The recent Maildir migration exemplifies these principles:

1. **Analysis**: Identified 6 redundant modules and dual storage system
2. **Simplification**: Reduced code by 40% (931 lines)
3. **No Compatibility**: Removed all dual-storage code
4. **Testing**: Comprehensive tests between each phase
5. **Documentation**: Created new docs and updated all READMEs
6. **Unity**: Single storage format for all emails

## Summary

These guidelines ensure that every change improves the overall quality of the codebase. By focusing on simplification, elimination of redundancy, and systematic testing, we maintain a clean, efficient, and maintainable system.

Remember: The goal is not just to add features, but to enhance the elegance and integrity of the entire codebase with each change.
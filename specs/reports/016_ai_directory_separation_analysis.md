# Refactoring Analysis: AI Directory Structure Separation

## Metadata
- **Date**: 2025-09-30
- **Scope**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/`
- **Standards Applied**: CLAUDE.md, Neovim Configuration Guidelines
- **Specific Concerns**: Keep features added to Avante and Claude separate
- **Priority**: High - Architectural separation and maintainability

## Executive Summary

Analysis of the AI plugins directory reveals significant architectural violations where Avante-specific features are tightly coupled with Claude-specific utilities. This creates a confusing dependency structure where the Avante plugin configuration directly depends on Claude utilities, violating separation of concerns and making the codebase harder to maintain.

**Critical Issues Found**: 3 architectural violations, 2 dependency coupling issues
**Estimated Effort**: 4-6 hours (Medium effort)
**Risk**: Medium - requires careful dependency restructuring

## Critical Issues

### Critical Issue 1: Avante Plugin Depends on Claude Utils
**Location**: `/lua/neotex/plugins/ai/avante.lua:37,51,115,255,351,360,605`
**Current State**:
- Avante plugin configuration directly imports 7 different Claude utility modules
- Creates tight coupling between separate AI tools
- Violates separation of concerns

**Code Examples**:
```lua
-- In avante.lua - WRONG: Avante depending on Claude utilities
local highlights = pcall(require, "neotex.plugins.ai.claude.utils.avante_highlights")
local avante_mcp = require("neotex.plugins.ai.claude.utils.avante_mcp")
local avante_support = require("neotex.plugins.ai.claude.utils.avante_support")
```

**Proposed Solution**:
- Move all Avante-specific utilities to `/neotex/plugins/ai/avante/`
- Create independent Avante utilities that don't depend on Claude structure
- Establish clear boundaries between AI tool configurations

**Priority**: Critical
**Effort**: Large (4-6 hours)
**Risk**: Medium (requires dependency restructuring)

### Critical Issue 2: Claude Utils Contains Avante-Specific Code
**Location**: `/lua/neotex/plugins/ai/claude/utils/avante_*` (6 files)
**Current State**:
- Claude directory contains 6 Avante-specific utility files
- Naming suggests these belong in Claude but they're for Avante
- Creates confusion about module ownership and responsibility

**Files That Should Move**:
```
claude/utils/avante_commands.lua     → avante/commands.lua
claude/utils/avante_highlights.lua   → avante/highlights.lua
claude/utils/avante_integration.lua  → avante/integration.lua
claude/utils/avante_mcp.lua         → avante/mcp_integration.lua
claude/utils/avante_support.lua     → avante/support.lua
claude/utils/avante_ui.lua          → avante/ui.lua
```

**Proposed Solution**:
- Create `/lua/neotex/plugins/ai/avante/` directory structure
- Move all Avante utilities to proper location
- Update all import statements

**Priority**: Critical
**Effort**: Medium (2-3 hours)
**Risk**: Low (safe file moves with import updates)

### Critical Issue 3: Mixed Configuration Responsibilities
**Location**: `/lua/neotex/plugins/ai/avante.lua:346-374` (system_prompt function)
**Current State**:
- Avante plugin configuration directly calls Claude system prompt utilities
- Creates implicit dependency on Claude for core Avante functionality
- System prompt generation should be self-contained per tool

**Code Example**:
```lua
-- In avante.lua opts function - WRONG: Avante calling Claude prompts
local ok, prompts = pcall(require, "neotex.plugins.ai.claude.utils.system_prompts")
```

**Proposed Solution**:
- Create Avante-specific system prompt management
- Allow sharing of prompts through a common interface if needed
- Keep each AI tool's configuration independent

**Priority**: Critical
**Effort**: Medium (2-3 hours)
**Risk**: Low (configuration abstraction)

## Refactoring Opportunities

### Category 1: Directory Structure Reorganization

#### Finding 1.1: Missing Avante Directory Structure
- **Location**: `/lua/neotex/plugins/ai/` (missing `avante/` subdirectory)
- **Current State**: Avante utilities scattered in Claude directory
- **Proposed Solution**: Create proper Avante directory structure
- **Priority**: High
- **Effort**: Small (30 minutes)
- **Risk**: Safe

#### Finding 1.2: Unclear Module Ownership
- **Location**: `claude/utils/avante_*` files
- **Current State**: Avante modules in Claude namespace
- **Proposed Solution**: Move to appropriate Avante namespace
- **Priority**: High
- **Effort**: Medium (2 hours)
- **Risk**: Low

### Category 2: Dependency Decoupling

#### Finding 2.1: Cross-Tool Dependencies
- **Location**: Avante plugin imports from Claude namespace
- **Current State**: Tight coupling prevents independent evolution
- **Proposed Solution**: Create abstraction layer or duplicate necessary utilities
- **Priority**: High
- **Effort**: Large (4-6 hours)
- **Risk**: Medium

#### Finding 2.2: Shared System Prompts
- **Location**: Both tools use `claude/utils/system_prompts.lua`
- **Current State**: Avante depends on Claude for system prompts
- **Proposed Solution**: Extract to common utilities or duplicate
- **Priority**: Medium
- **Effort**: Medium (2 hours)
- **Risk**: Low

### Category 3: Configuration Architecture

#### Finding 3.1: Plugin Configuration Complexity
- **Location**: `avante.lua` (707 lines - oversized)
- **Current State**: Monolithic configuration with mixed concerns
- **Proposed Solution**: Split into focused configuration modules
- **Priority**: Medium
- **Effort**: Medium (3-4 hours)
- **Risk**: Low

#### Finding 3.2: Redundant Utility Patterns
- **Location**: Similar patterns in both Claude and Avante utilities
- **Current State**: Code duplication in UI and command patterns
- **Proposed Solution**: Extract common patterns to shared utilities
- **Priority**: Low
- **Effort**: Medium (2-3 hours)
- **Risk**: Low

## Implementation Roadmap

### Phase 1 - Critical Separation (High Priority)
1. **Create Avante Directory Structure** (30 min)
   ```bash
   mkdir -p lua/neotex/plugins/ai/avante/{commands,core,ui,utils}
   ```

2. **Move Avante Utilities** (2 hours)
   - Move `claude/utils/avante_*` → `avante/utils/`
   - Update all import statements
   - Test module loading

3. **Decouple Avante Configuration** (3-4 hours)
   - Remove Claude dependencies from `avante.lua`
   - Create independent Avante utilities
   - Establish proper module boundaries

### Phase 2 - Configuration Optimization (Medium Priority)
1. **Split Avante Configuration** (2-3 hours)
   - Break down oversized `avante.lua` into focused modules
   - Create `avante/config/` subdirectory
   - Separate concerns (providers, keymaps, UI, MCP integration)

2. **Abstract Common Utilities** (2 hours)
   - Identify truly shared functionality
   - Create `neotex/plugins/ai/common/` for shared utilities
   - Refactor both tools to use common abstractions

### Phase 3 - Architecture Improvements (Low Priority)
1. **Plugin Interface Standardization** (1-2 hours)
   - Define standard interfaces for AI tool plugins
   - Ensure consistent patterns across tools
   - Document plugin architecture standards

## Proposed Directory Structure

### Before (Current - Problematic)
```
plugins/ai/
├── avante.lua (707 lines - depends on claude/*)
├── claude/
│   ├── utils/
│   │   ├── avante_commands.lua    # WRONG: Avante in Claude
│   │   ├── avante_highlights.lua  # WRONG: Avante in Claude
│   │   ├── avante_integration.lua # WRONG: Avante in Claude
│   │   ├── avante_mcp.lua        # WRONG: Avante in Claude
│   │   ├── avante_support.lua    # WRONG: Avante in Claude
│   │   ├── avante_ui.lua         # WRONG: Avante in Claude
│   │   └── system_prompts.lua    # Used by both tools
└── init.lua
```

### After (Proposed - Clean Separation)
```
plugins/ai/
├── avante/
│   ├── init.lua (main plugin config)
│   ├── config/
│   │   ├── providers.lua
│   │   ├── keymaps.lua
│   │   └── ui.lua
│   ├── utils/
│   │   ├── commands.lua
│   │   ├── highlights.lua
│   │   ├── integration.lua
│   │   ├── mcp_integration.lua
│   │   ├── support.lua
│   │   └── ui.lua
│   └── prompts/
│       └── system_prompts.lua
├── claude/
│   ├── (existing Claude-specific modules)
│   └── utils/
│       └── system_prompts.lua (Claude-specific prompts)
├── common/ (if truly shared utilities needed)
│   └── prompt_manager.lua
├── avante.lua (simplified - loads from avante/ modules)
└── init.lua
```

## Testing Strategy

### Pre-Refactoring Validation
1. **Dependency Mapping**
   ```bash
   grep -r "require.*avante" lua/neotex/plugins/ai/claude/
   grep -r "require.*claude" lua/neotex/plugins/ai/avante.lua
   ```

2. **Current Functionality Test**
   - Load Avante plugin: `:Lazy load avante.nvim`
   - Test Avante commands: `:AvanteAsk`, `:AvanteToggle`
   - Test Claude commands: `:ClaudeCommands`

### Post-Refactoring Validation
1. **Module Loading Test**
   ```lua
   -- Test independent loading
   local avante_ok = pcall(require, "neotex.plugins.ai.avante")
   local claude_ok = pcall(require, "neotex.plugins.ai.claude")
   ```

2. **Functionality Verification**
   - All Avante features work without Claude dependencies
   - Claude features work without Avante utilities
   - No circular dependencies between tools

3. **Import Resolution**
   ```bash
   # Verify no cross-tool dependencies remain
   grep -r "neotex.plugins.ai.claude" lua/neotex/plugins/ai/avante/
   grep -r "neotex.plugins.ai.avante" lua/neotex/plugins/ai/claude/
   ```

## Migration Path

### Step 1: Backup and Prepare
```bash
git checkout -b refactor/ai-directory-separation
git tag before-ai-separation
```

### Step 2: Create New Structure
```bash
mkdir -p lua/neotex/plugins/ai/avante/{config,utils,prompts}
```

### Step 3: Move Files Systematically
```bash
# Move Avante utilities
mv lua/neotex/plugins/ai/claude/utils/avante_*.lua lua/neotex/plugins/ai/avante/utils/
# Rename files to remove 'avante_' prefix
cd lua/neotex/plugins/ai/avante/utils/
for file in avante_*.lua; do mv "$file" "${file#avante_}"; done
```

### Step 4: Update Imports
- Use search and replace to update all require statements
- Update module names to match new structure
- Test each change incrementally

### Step 5: Split Configurations
- Extract provider configs from `avante.lua`
- Create focused configuration modules
- Maintain plugin loading interface

## Metrics

- **Files Analyzed**: 36 Lua files in AI directory
- **Critical Issues Found**: 3 architectural violations
- **Dependency Violations**: 7 Claude imports in Avante config
- **Files to Move**: 6 Avante utilities from Claude directory
- **Estimated Total Effort**: 8-12 hours across 3 phases
- **Test Coverage Impact**: Requires new integration tests for separated modules

## Benefits of Separation

### Maintainability
- **Clear Module Ownership**: Each AI tool owns its utilities
- **Independent Evolution**: Tools can evolve without affecting each other
- **Reduced Complexity**: Simpler dependency graphs
- **Better Testing**: Each tool can be tested in isolation

### Development Experience
- **Clearer Mental Model**: Developers know where to find tool-specific code
- **Easier Debugging**: Issues isolated to specific tool boundaries
- **Simpler Onboarding**: New developers understand structure immediately
- **Reduced Coupling**: Changes in one tool don't break another

### Architecture Quality
- **Separation of Concerns**: Each module has single responsibility
- **Dependency Inversion**: Tools depend on abstractions, not concretions
- **Plugin Architecture**: Consistent patterns across AI tools
- **Extensibility**: Easy to add new AI tools following established patterns

## References

- **CLAUDE.md Standards**: Module organization and dependency guidelines
- **Current Code**: `/lua/neotex/plugins/ai/`
- **Related Issues**: Tight coupling between AI tools
- **Future Plans**: Can create `/plan` for implementation roadmap

## Conclusion

The AI directory structure violates fundamental separation of concerns principles by mixing Avante and Claude functionality. This refactoring will establish clear boundaries, improve maintainability, and create a sustainable architecture for multiple AI tools.

**Immediate Next Steps**:
1. Use `/plan` command with this report to create implementation plan
2. Begin with Phase 1 (critical separation) to establish proper boundaries
3. Test thoroughly at each step to ensure no functionality is lost

**Success Criteria**:
- Avante plugin loads without any Claude dependencies
- Claude utilities contain no Avante-specific code
- Clear, logical directory structure that newcomers can understand
- All existing functionality preserved after refactoring
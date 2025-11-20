# Claude Artifacts Picker Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Refactor `<leader>ac` command (Claude artifacts picker) to ensure full .claude/ directory coverage, improve modularity, and enhance Load All Artifacts functionality
- **Scope**: Modularize picker.lua (3,385 lines), add 5 missing artifact types (scripts/, tests/, specs/ subdirs), implement registry-driven architecture
- **Estimated Phases**: 5
- **Estimated Hours**: 36
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Research Reports**:
  - [Artifact Management Comprehensive Analysis](/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/001_artifact_management_comprehensive_analysis.md)

## Overview

The Claude artifacts picker (`<leader>ac` command in nvim) currently provides comprehensive support for 11 artifact types but lacks coverage for several critical .claude/ directories (scripts/, tests/, specs/ subdirectories) and suffers from maintainability issues due to its monolithic 3,385-line architecture. This implementation plan refactors the picker into a modular, registry-driven system while adding full coverage of all .claude/ artifact types.

**Goals**:
1. Modularize picker.lua into 15-20 focused modules (target: <250 lines each)
2. Implement artifact registry system for extensible type management
3. Add 5 missing artifact categories: scripts/, tests/, plans/, reports/, summaries/
4. Enhance Load All Artifacts with registry-driven sync and validation
5. Maintain 100% backward compatibility with existing workflows
6. Achieve 80%+ test coverage for all new modules

## Research Summary

Based on comprehensive analysis of the current picker implementation and .claude/ directory structure:

**Current State**:
- 11 artifact types fully supported (commands, agents, hooks, tts, templates, lib, docs, etc.)
- Sophisticated hierarchical display with preview/edit capabilities
- Robust Load All functionality for curated artifacts
- Monolithic architecture (3,385 lines in single file)

**Critical Gaps**:
- Missing 5 artifact types: scripts/, tests/, specs/{topic}/plans/, reports/, summaries/
- Hardcoded artifact type management (requires updates in 5+ locations per new type)
- No plugin system for extensibility
- Zero test coverage
- Templates directory paradox (code exists but directory doesn't)

**Architectural Issues**:
- No single source of truth for artifact types
- Difficult to add new artifact types
- Testing challenges due to monolithic structure
- Inconsistent metadata extraction across types

**Recommended Approach**:
- Registry-driven architecture with artifact type definitions
- Progressive modularization preserving backward compatibility
- Phased rollout: Foundation → Primary artifacts → Specs artifacts → Enhanced operations → Polish
- Flat list pattern for specs artifacts (Option A from research) with future drill-down capability

## Success Criteria

- [ ] Artifact type coverage increased from 11 to 16+ types
- [ ] Picker-visible categories increased from 7 to 12+
- [ ] Module count increased from 1 to 15-20 modules
- [ ] Average module size reduced from 3,385 lines to <250 lines per module
- [ ] Test coverage increased from 0% to 80%+
- [ ] 100% backward compatibility maintained (all existing keybindings work)
- [ ] Load All syncs 15+ artifact types successfully
- [ ] Scripts, tests, plans, reports, summaries visible in picker with preview/edit
- [ ] Registry system allows adding new artifact types without modifying core picker
- [ ] Performance within ±5% of baseline (no user-perceivable slowdown)
- [ ] All modules documented with README.md files
- [ ] No critical bugs, <3 minor bugs in production

## Technical Design

### Architecture Overview

**Current (Monolithic)**:
```
picker.lua (3,385 lines)
├─ Entry creation (~500 lines)
├─ Previewer system (~490 lines)
├─ Load operations (~800 lines)
├─ Helper functions (~600 lines)
├─ Main picker (~500 lines)
└─ Utilities (~500 lines)
```

**Proposed (Modular)**:
```
commands/
├── picker.lua                   [500 lines] Facade/compatibility layer
├── picker/
│   ├── init.lua                 [100 lines] Entry point
│   ├── artifacts/
│   │   ├── registry.lua         [200 lines] Artifact type definitions
│   │   ├── commands.lua         [100 lines] Command-specific logic
│   │   ├── agents.lua           [100 lines] Agent-specific logic
│   │   ├── specs.lua            [150 lines] Specs artifact logic
│   │   └── metadata.lua         [150 lines] Metadata extraction
│   ├── display/
│   │   ├── entries.lua          [250 lines] Entry creation
│   │   ├── previewer.lua        [300 lines] Preview system
│   │   └── formatters.lua       [150 lines] Display formatting
│   ├── operations/
│   │   ├── sync.lua             [250 lines] Load/save operations
│   │   ├── edit.lua             [100 lines] File editing
│   │   └── terminal.lua         [100 lines] Terminal integration
│   └── utils/
│       ├── scan.lua             [200 lines] Directory scanning
│       └── helpers.lua          [150 lines] Common utilities
└── parser.lua                   [Unchanged] Existing parser
```

### Artifact Registry System

**Core Concept**: Single source of truth for artifact type definitions

**Registry Schema**:
```lua
ArtifactType = {
  -- Identity
  id = string,                    -- "commands", "scripts", etc.
  category = string,              -- "primary", "specs", "tools"

  -- Discovery
  pattern = string,               -- "*.md", "*.sh"
  locations = table,              -- {"commands", "agents"}

  -- Display
  display_name = string,          -- "[Commands]"
  description = string,           -- "Claude Code slash commands"
  picker_visible = boolean,       -- Show in picker (default: true)
  tree_indent = number,           -- 1 or 2 spaces

  -- Features
  preview_enabled = boolean,      -- Enable preview
  edit_enabled = boolean,         -- Enable editing
  sync_enabled = boolean,         -- Include in Load All

  -- Metadata
  parse_description = function,   -- (filepath) -> string
  parse_metadata = function,      -- (filepath) -> table

  -- Display Formatting
  format_entry = function,        -- (entry) -> string
  format_preview = function,      -- (entry) -> preview content

  -- Operations
  on_select = function,           -- (entry) -> action
  on_load = function,             -- (filepath) -> boolean
}
```

**Category Ordering**:
1. `primary` - Commands, Agents, Hooks, TTS
2. `specs` - Plans, Reports, Summaries, Debug
3. `tools` - Scripts, Tests
4. `libraries` - Lib, Templates
5. `docs` - Docs
6. `special` - Help, Load All

### New Artifact Type Definitions

**Scripts**:
```lua
scripts = {
  id = "scripts",
  category = "tools",
  pattern = "*.sh",
  locations = {"scripts"},
  display_name = "[Scripts]",
  description = "Standalone CLI tools",
  tree_indent = 1,
  custom_keymaps = {
    {key = "<C-r>", action = run_script_with_args}
  }
}
```

**Tests**:
```lua
tests = {
  id = "tests",
  category = "tools",
  pattern = "test_*.sh",
  locations = {"tests"},
  display_name = "[Tests]",
  description = "Test suites",
  tree_indent = 1,
  custom_keymaps = {
    {key = "<C-t>", action = run_test}
  }
}
```

**Specs Plans**:
```lua
specs_plans = {
  id = "specs_plans",
  category = "specs",
  pattern = "*.md",
  locations = {"specs/*/plans"},  -- Glob pattern
  display_name = "[Plans]",
  description = "Implementation plans",
  tree_indent = 1,
  parse_metadata = extract_plan_metadata,  -- Extract phases, complexity
  format_entry = format_plan_with_topic    -- Show topic number
}
```

**Specs Reports**:
```lua
specs_reports = {
  id = "specs_reports",
  category = "specs",
  pattern = "*.md",
  locations = {"specs/*/reports"},
  display_name = "[Reports]",
  description = "Research reports",
  tree_indent = 1
}
```

**Specs Summaries**:
```lua
specs_summaries = {
  id = "specs_summaries",
  category = "specs",
  pattern = "*.md",
  locations = {"specs/*/summaries"},
  display_name = "[Summaries]",
  description = "Implementation summaries",
  tree_indent = 1
}
```

### Enhanced Load All Artifacts

**Current Approach**: Hardcoded list of directories to scan
**Proposed Approach**: Registry-driven with validation

**Registry-Driven Sync**:
```lua
function load_all_globally()
  local registry = require("picker.artifacts.registry")

  -- Build sync plan from registry
  local sync_plan = {}
  for _, artifact_type in pairs(registry.types) do
    if artifact_type.sync_enabled then
      local files = scan_artifact_type(artifact_type)
      sync_plan[artifact_type.id] = files
    end
  end

  -- Execute with validation
  local results = execute_sync(sync_plan)
  report_sync_results(results)
end
```

**Enhanced Conflict Resolution**:
- Option 1: Replace all + add new (replaces existing, adds new)
- Option 2: Add new only (skip existing files)
- Option 3: Interactive per-file (prompt for each conflict)
- Option 4: Preview diff (show changes before applying)

**Sync Validation**:
- Verify file integrity (checksum or size comparison)
- Check executable permissions preserved (.sh files)
- Validate metadata extraction succeeds
- Report failures separately with actionable errors

### Backward Compatibility Strategy

**Facade Pattern**: Keep `picker.lua` as compatibility layer

```lua
-- picker.lua (new facade)
local new_picker = require("neotex.plugins.ai.claude.commands.picker.init")

local M = {}

-- Maintain existing API
M.show_commands_picker = function(opts)
  return new_picker.show(opts)
end

-- Deprecated functions with warnings
M.load_command_locally = function(...)
  vim.notify("Deprecated: Use operations.load()", vim.log.levels.WARN)
  return new_picker.operations.load(...)
end

return M
```

**API Stability**:
- All existing functions preserved with deprecation warnings
- Keybindings unchanged (`<leader>ac` continues to work)
- Configuration options backward compatible
- Gradual migration path for users

## Implementation Phases

### Phase 1: Foundation - Modular Architecture [NOT STARTED]
dependencies: []

**Objective**: Establish modular architecture without changing functionality

**Complexity**: High

**Tasks**:
- [ ] Create `picker/` directory structure with subdirectories (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/)
- [ ] Create artifact registry module with 11 existing types (file: picker/artifacts/registry.lua)
- [ ] Extract directory scanning logic to utils/scan.lua (file: picker/utils/scan.lua)
- [ ] Extract metadata extraction to artifacts/metadata.lua (file: picker/artifacts/metadata.lua)
- [ ] Create display/entries.lua with entry creation logic (file: picker/display/entries.lua)
- [ ] Create display/previewer.lua with preview system (file: picker/display/previewer.lua)
- [ ] Create operations/sync.lua with Load All logic (file: picker/operations/sync.lua)
- [ ] Create picker/init.lua as new entry point (file: picker/init.lua)
- [ ] Update picker.lua as facade delegating to new modules (file: picker.lua)
- [ ] Verify all existing functionality works identically (manual testing)
- [ ] Create test infrastructure with plenary.nvim (file: picker/artifacts/registry_spec.lua)
- [ ] Write tests for registry module (80%+ coverage target)
- [ ] Write tests for scan utilities (80%+ coverage target)
- [ ] Write tests for metadata extraction (80%+ coverage target)

**Testing**:
```bash
# Manual verification
nvim -c "lua require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()"

# Automated tests
:TestSuite picker/
```

**Expected Duration**: 10 hours

### Phase 2: Add Missing Primary Artifacts [NOT STARTED]
dependencies: [1]

**Objective**: Add Scripts, Tests, and Output Files artifact types

**Complexity**: Medium

**Tasks**:
- [ ] Add Scripts artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Add Tests artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Add Outputs artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Implement script-specific metadata parsing (file: picker/artifacts/metadata.lua)
- [ ] Implement test-specific metadata parsing (file: picker/artifacts/metadata.lua)
- [ ] Add Scripts entry creation to display/entries.lua
- [ ] Add Tests entry creation to display/entries.lua
- [ ] Update previewer for Scripts (file: picker/display/previewer.lua)
- [ ] Update previewer for Tests (file: picker/display/previewer.lua)
- [ ] Update Load All to scan scripts/ directory (file: picker/operations/sync.lua)
- [ ] Update Load All to scan tests/ directory (file: picker/operations/sync.lua)
- [ ] Add run script action with `<C-r>` keybinding (file: picker/operations/terminal.lua)
- [ ] Add run test action with `<C-t>` keybinding (file: picker/operations/terminal.lua)
- [ ] Update help documentation in picker (file: picker/init.lua)
- [ ] Create README.md for picker/ directory (file: picker/README.md)
- [ ] Write tests for new artifact types (80%+ coverage)

**Testing**:
```bash
# Verify Scripts visible in picker
# Verify Tests visible in picker
# Verify Load All syncs scripts/ and tests/
# Verify <C-r> runs scripts with arguments
# Verify <C-t> runs tests
```

**Expected Duration**: 6 hours

### Phase 3: Add Specs Artifacts [NOT STARTED]
dependencies: [1]

**Objective**: Comprehensive specs/ directory coverage with plans, reports, summaries

**Complexity**: High

**Tasks**:
- [ ] Design specs artifact navigation (flat list with topic numbers - Option A)
- [ ] Add Plans artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Add Reports artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Add Summaries artifact type to registry (file: picker/artifacts/registry.lua)
- [ ] Add Debug artifact type to registry (read-only) (file: picker/artifacts/registry.lua)
- [ ] Implement plan metadata extraction (phases, complexity, hours) (file: picker/artifacts/metadata.lua)
- [ ] Implement report metadata extraction (file: picker/artifacts/metadata.lua)
- [ ] Create specs.lua with topic-aware logic (file: picker/artifacts/specs.lua)
- [ ] Implement glob pattern scanning for specs/*/plans/ (file: picker/utils/scan.lua)
- [ ] Format plan entries with topic numbers (file: picker/display/formatters.lua)
- [ ] Create plan preview with phase display (file: picker/display/previewer.lua)
- [ ] Update Load All to optionally sync specs/standards/ (file: picker/operations/sync.lua)
- [ ] Add search/filter for large specs lists (file: picker/init.lua)
- [ ] Update help text for specs navigation (file: picker/init.lua)
- [ ] Write comprehensive tests for specs artifacts (80%+ coverage)

**Testing**:
```bash
# Verify Plans visible with topic numbers
# Verify Reports visible and preview-able
# Verify Summaries visible
# Verify Debug reports read-only
# Verify search filters work
# Verify preview shows plan phases/complexity
```

**Expected Duration**: 12 hours

### Phase 4: Enhanced Operations [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Improve Load All and sync operations with validation and conflict resolution

**Complexity**: Medium

**Tasks**:
- [ ] Implement registry-driven sync in operations/sync.lua
- [ ] Add interactive conflict resolution UI (file: picker/operations/sync.lua)
- [ ] Implement diff preview before sync (file: picker/operations/sync.lua)
- [ ] Add file integrity validation (checksum) (file: picker/utils/helpers.lua)
- [ ] Add executable permissions verification (file: picker/utils/helpers.lua)
- [ ] Implement sync result reporting with success/failure counts (file: picker/operations/sync.lua)
- [ ] Add selective sync UI (choose artifact types) (file: picker/operations/sync.lua)
- [ ] Create enhanced Load All preview showing changes (file: picker/display/previewer.lua)
- [ ] Add retry logic for failed syncs (file: picker/operations/sync.lua)
- [ ] Update help text with new sync options (file: picker/init.lua)
- [ ] Write tests for sync operations (80%+ coverage)
- [ ] Write tests for conflict resolution (80%+ coverage)

**Testing**:
```bash
# Verify interactive conflict resolution works
# Verify diff preview accurate
# Verify failed syncs reported clearly
# Verify executable permissions preserved
# Verify selective sync UI
```

**Expected Duration**: 6 hours

### Phase 5: Polish and Documentation [NOT STARTED]
dependencies: [1, 2, 3, 4]

**Objective**: Production-ready release with comprehensive documentation

**Complexity**: Low

**Tasks**:
- [ ] Create comprehensive README.md for commands/ directory update (file: commands/README.md)
- [ ] Create README.md for picker/artifacts/ (file: picker/artifacts/README.md)
- [ ] Create README.md for picker/display/ (file: picker/display/README.md)
- [ ] Create README.md for picker/operations/ (file: picker/operations/README.md)
- [ ] Create README.md for picker/utils/ (file: picker/utils/README.md)
- [ ] Write migration guide from monolithic to modular (file: picker/MIGRATION.md)
- [ ] Document registry schema with examples (file: picker/artifacts/README.md)
- [ ] Create user guide with usage examples (file: picker/USER_GUIDE.md)
- [ ] Add architecture documentation (file: picker/ARCHITECTURE.md)
- [ ] Document all keybindings comprehensively (file: picker/README.md)
- [ ] Performance optimization pass (profile and optimize hot paths)
- [ ] Benchmark performance vs baseline (file: picker/BENCHMARKS.md)
- [ ] Code review and cleanup pass
- [ ] Final integration testing
- [ ] Update CHANGELOG with all changes (file: commands/CHANGELOG.md)

**Testing**:
```bash
# Verify all documentation accurate
# Verify migration guide complete
# Verify performance acceptable (±5% baseline)
# Verify all tests passing
# Final smoke testing
```

**Expected Duration**: 2 hours

## Testing Strategy

### Test Framework
- **Framework**: plenary.nvim (already used in Neovim ecosystem)
- **Location**: Adjacent to source files (`*_spec.lua` pattern)
- **Coverage Target**: 80%+ for all new modules

### Test Categories

**1. Unit Tests** (per module):
- Registry module: Artifact type definitions, validation
- Scan utilities: Directory scanning, glob patterns, file filtering
- Metadata extraction: Parse descriptions, extract metadata from files
- Entry creation: Format entries, tree structure, indentation
- Previewer: Preview generation, README rendering
- Sync operations: Load All logic, conflict resolution, validation

**2. Integration Tests**:
- End-to-end picker flow (open → navigate → select → edit)
- Load All with multiple artifact types
- Backward compatibility with existing API
- Keybinding functionality
- Search and filter operations

**3. Performance Tests**:
- Baseline vs refactored performance comparison
- Large artifact list handling (100+ files)
- Preview rendering speed
- Sync operation timing

**4. Regression Tests**:
- All existing functionality preserved
- No breaking changes to user workflows
- Configuration options work as expected

### Test Execution

**Manual Testing Checklist**:
- [ ] Open picker with `<leader>ac`
- [ ] Navigate through all artifact categories
- [ ] Preview multiple artifact types
- [ ] Edit artifacts and verify changes
- [ ] Run Load All with replace strategy
- [ ] Run Load All with add-only strategy
- [ ] Test Scripts run action (`<C-r>`)
- [ ] Test Tests run action (`<C-t>`)
- [ ] Search for specs artifacts
- [ ] Verify performance (no lag)

**Automated Testing**:
```bash
# Run all tests
:TestSuite picker/

# Run specific module tests
:TestFile picker/artifacts/registry_spec.lua

# Run nearest test
:TestNearest
```

## Documentation Requirements

### README Files (per nvim CLAUDE.md standards)

**Required in each subdirectory**:
1. `commands/README.md` - Update with new picker architecture
2. `picker/README.md` - Overview of picker system
3. `picker/artifacts/README.md` - Registry system and artifact types
4. `picker/display/README.md` - Display and preview logic
5. `picker/operations/README.md` - Sync and edit operations
6. `picker/utils/README.md` - Utility functions

**README Content Requirements**:
- Purpose: Clear explanation of directory role
- Module Documentation: Each file documented
- Usage Examples: Code examples
- Navigation Links: Parent and subdirectory links
- Dependencies: Any prerequisites

### Additional Documentation

**Migration Guide** (`picker/MIGRATION.md`):
- Overview of changes
- Backward compatibility notes
- Deprecation timeline
- Code migration examples

**User Guide** (`picker/USER_GUIDE.md`):
- Feature overview
- Keybinding reference
- Load All options
- Artifact type coverage
- Troubleshooting

**Architecture Document** (`picker/ARCHITECTURE.md`):
- Design decisions
- Module responsibilities
- Data flow diagrams (using Unicode box-drawing)
- Extension points

### Code Documentation

**Inline Comments** (per nvim CLAUDE.md):
- Describe WHAT code does, not WHY
- Document complex logic
- Explain non-obvious patterns
- Reference related modules

**Function Documentation**:
```lua
--- Brief description of function
--- @param param_name type Description
--- @return type Description
local function example(param_name)
  -- Implementation
end
```

## Dependencies

### External Dependencies
- **telescope.nvim**: Picker UI framework (already installed)
- **plenary.nvim**: Testing and utilities (already installed)
- **nvim-treesitter**: Markdown syntax highlighting for previews (already installed)

### Internal Dependencies
- `parser.lua`: Existing command parser (no changes required)
- `commands/` directory: Parent directory (README update)

### Prerequisite Knowledge
- Telescope picker API
- Lua module system
- plenary.nvim testing framework
- Unicode box-drawing for diagrams

## Risk Assessment

### Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking backward compatibility | Medium | High | Maintain facade layer, extensive testing |
| Performance degradation | Low | Medium | Benchmark before/after, optimize registries |
| Incomplete artifact coverage | Low | Low | Registry-driven ensures consistency |
| Testing gaps | Medium | Medium | 80% coverage requirement enforced |

### User Impact Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Learning curve for new features | Low | Low | Maintain existing UX, document new features |
| Workflow disruption | Low | Medium | 100% backward compatibility |
| Configuration migration | None | None | No config changes required |

### Maintenance Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Module coupling | Low | Medium | Clear interfaces, dependency injection |
| Documentation drift | Medium | Low | README requirements enforced |
| Test maintenance | Low | Low | Focused tests per module |

## Rollback Plan

If critical issues arise during implementation:

1. **Phase 1 Rollback**: Revert to monolithic picker.lua (git reset)
2. **Phase 2-5 Rollback**: Facade layer continues delegating to old implementation
3. **Feature Flags**: Add `use_legacy_picker` config option for gradual migration
4. **Gradual Migration**: Allow users to opt-in to new picker incrementally

## Performance Targets

| Metric | Baseline | Target |
|--------|----------|--------|
| Picker open time | <100ms | <105ms (±5%) |
| Preview render time | <200ms | <210ms (±5%) |
| Load All sync time | ~2-5s | ~2-5.25s (±5%) |
| Search/filter latency | <50ms | <52.5ms (±5%) |
| Memory footprint | ~2-3MB | ~2.5-3.5MB (±15%) |

## Success Validation

### Functional Validation
- [ ] All 16+ artifact types visible in picker
- [ ] Scripts, tests, plans, reports, summaries preview/edit work
- [ ] Load All syncs 15+ artifact types successfully
- [ ] Search/filter finds artifacts correctly
- [ ] All keybindings functional

### Quality Validation
- [ ] 80%+ test coverage achieved
- [ ] All tests passing
- [ ] Performance within ±5% baseline
- [ ] No critical bugs
- [ ] <3 minor bugs

### Documentation Validation
- [ ] All README files created
- [ ] Migration guide complete
- [ ] User guide comprehensive
- [ ] Architecture documented
- [ ] Code comments adequate

### User Validation
- [ ] Backward compatibility 100%
- [ ] Existing workflows unchanged
- [ ] New features intuitive
- [ ] No user complaints about performance

## Notes

**Complexity Score Calculation**: 142.0
- Base (refactor): 5
- Tasks (78 tasks): 78 / 2 = 39
- Files (20 estimated): 20 * 3 = 60
- Integrations (telescope, plenary): 2 * 5 = 10
- Dependencies (parser.lua): 1 * 2 = 2
- **Total**: 5 + 39 + 60 + 10 + 2 = 116

**Note**: Complexity score of 116 suggests this plan could benefit from phase expansion during implementation. Consider using `/expand [phase|stage] <path> <number>` if any phase becomes too complex.

**Templates Directory**: Research identified code for templates/ directory that doesn't exist. During Phase 1, verify if this was deprecated in favor of commands/templates/ and update registry accordingly.

**Progressive Expansion**: This Level 0 (single file) plan can be expanded to Level 1 (phase files) or Level 2 (stage files) during implementation if any phase requires more detailed breakdown.

# Claude Artifacts Picker Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-20 (Revised: 2025-11-20)
- **Feature**: Refactor `<leader>ac` command (Claude artifacts picker) to ensure full .claude/ directory coverage, improve modularity, and enhance Load All Artifacts functionality
- **Scope**: Modularize picker.lua (3,385 lines), add 2 missing artifact types (scripts/, tests/), implement registry-driven architecture
- **Estimated Phases**: 4
- **Estimated Hours**: 24
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Status**: [IN PROGRESS]
- **Structure Level**: 1
- **Expanded Phases**: [1, 3]
- **Complexity Score**: 119.5 (recalculated after removing specs/ artifacts)
- **Revision Notes**:
  - Revision 1: Maintained clean-break approach per writing-standards.md and CODE_STANDARDS.md. Removed backward compatibility language, eliminated migration guide, reframed facade as permanent architecture, added atomic cutover in Phase 4.
  - Revision 2: Excluded specs/ directory artifacts (plans/, reports/, summaries/) per directory-protocols.md. These are temporary working artifacts (gitignored), not permanent .claude/ system artifacts. Reduced scope from 16+ artifact types to 13 types, removed Phase 3, reduced hours from 36 to 24.
  - Revision 3: Enhanced Conflict Resolution options updated: (1) Changed Option 1 to "Replace existing + add new" for accuracy, (2) Added Option 5 "Clean copy" which deletes local-only artifacts and replaces all with global versions (destructive operation requiring two-stage confirmation).
- **Research Reports**:
  - [Artifact Management Comprehensive Analysis](/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/001_artifact_management_comprehensive_analysis.md)
  - [Clean-Break Dependency Revision](/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/002_clean_break_dependency_revision.md)
  - [Plan Revision: Exclude specs/ Directory](/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/003_plan_revision_exclude_specs_directory.md)
  - [Enhanced Conflict Resolution Revision](/home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/004_enhanced_conflict_resolution_revision.md)

## Overview

The Claude artifacts picker (`<leader>ac` command in nvim) currently provides comprehensive support for 11 artifact types but lacks coverage for 2 permanent .claude/ directories (scripts/, tests/) and suffers from maintainability issues due to its monolithic 3,385-line architecture. This implementation plan refactors the picker into a modular, registry-driven system while adding coverage of all permanent .claude/ artifact types.

**Important Scope Note**: The specs/ directory (plans/, reports/, summaries/) is explicitly excluded from this plan. Per directory-protocols.md, specs/ artifacts are temporary working files that are gitignored and workflow-specific. They are not permanent system artifacts like commands/, agents/, etc. Only permanent, committed .claude/ directories are in scope for the picker.

**Goals**:
1. Modularize picker.lua into 15-20 focused modules (target: <250 lines each)
2. Implement artifact registry system for extensible type management
3. Add 2 missing permanent artifact categories: scripts/, tests/
4. Enhance Load All Artifacts with registry-driven sync and validation
5. Preserve all user-facing functionality with improved architecture
6. Achieve 80%+ test coverage for all new modules

## Research Summary

Based on comprehensive analysis of the current picker implementation and .claude/ directory structure:

**Current State**:
- 11 artifact types fully supported (commands, agents, hooks, tts, templates, lib, docs, etc.)
- Sophisticated hierarchical display with preview/edit capabilities
- Robust Load All functionality for curated artifacts
- Monolithic architecture (3,385 lines in single file)

**Critical Gaps**:
- Missing 2 permanent artifact types: scripts/, tests/
- Hardcoded artifact type management (requires updates in 5+ locations per new type)
- No plugin system for extensibility
- Zero test coverage
- Templates directory paradox (code exists but directory doesn't)

**Permanent vs Temporary Artifacts**:
- **Permanent** (committed to git, system-wide): agents/, commands/, docs/, hooks/, lib/, scripts/, tests/, tts/
- **Temporary** (gitignored, workflow-specific): specs/{topic}/plans/, reports/, summaries/, debug/
- **Picker scope**: Only permanent artifacts are included in picker coverage goals

**Architectural Issues**:
- No single source of truth for artifact types
- Difficult to add new artifact types
- Testing challenges due to monolithic structure
- Inconsistent metadata extraction across types

**Recommended Approach**:
- Registry-driven architecture with artifact type definitions
- Progressive modularization with atomic cutover in Phase 3
- Phased rollout: Foundation → Add missing permanent artifacts → Integration & cutover → Polish
- Focus on permanent .claude/ directories only (scripts/, tests/)

## Success Criteria

- [ ] Artifact type coverage increased from 11 to 13 types (permanent artifacts only)
- [ ] Picker-visible categories increased from 7 to 9 (scripts and tests added)
- [ ] Module count increased from 1 to 15-20 modules
- [ ] Average module size reduced from 3,385 lines to <250 lines per module
- [ ] Test coverage increased from 0% to 80%+
- [ ] All picker features work correctly (keybindings, navigation, preview, edit, Load All)
- [ ] Load All syncs 13 permanent artifact types successfully
- [ ] Scripts and tests visible in picker with preview/edit functionality
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
2. `tools` - Scripts, Tests
3. `libraries` - Lib, Templates
4. `docs` - Docs
5. `special` - Help, Load All

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
- Option 1: Replace existing + add new (replaces conflicts, adds new, preserves local-only)
- Option 2: Add new only (skip conflicts, only add new files)
- Option 3: Interactive per-file (prompt for each conflict individually)
- Option 4: Preview diff (show changes before applying)
- Option 5: Clean copy (DELETE local-only artifacts, replace all with global)

Note: Options 1-4 preserve local-only artifacts. Option 5 is destructive and requires confirmation.

**Sync Validation**:
- Verify file integrity (checksum or size comparison)
- Check executable permissions preserved (.sh files)
- Validate metadata extraction succeeds
- Report failures separately with actionable errors

### Public API Boundary

**Architectural Pattern**: `picker.lua` serves as the public API boundary, providing a stable interface while allowing internal implementation to be modularized.

**Structure**:
```lua
-- picker.lua (public API - permanent architecture)
local internal = require("neotex.plugins.ai.claude.commands.picker.init")

local M = {}

-- Primary public function
M.show = function(opts)
  return internal.show(opts)
end

return M
```

**Benefits**:
- Stable import path for external code
- Internal modules can be reorganized without breaking callers
- Clear separation between public API and implementation details
- Follows "Single Source of Truth" principle (CODE_STANDARDS.md:11-15)

**Note**: This is the permanent architecture, not a temporary compatibility layer. All external callers will be updated in Phase 4 to use the new API in a single atomic change.

## Implementation Phases

### Phase 1: Foundation - Modular Architecture [IN PROGRESS]
dependencies: []

**Objective**: Establish modular architecture without changing functionality

**Complexity**: High (8/10)

**Summary**: Transform monolithic 3,385-line picker.lua into modular architecture with 11 artifact types using facade pattern. Establish registry-driven system for artifact management with 80%+ test coverage.

**Expanded Details**: See [Phase 1 Expansion](phase_1_foundation_modular_architecture.md)

**Key Tasks Summary**:
- [x] **Map Current Usage** (required for atomic cutover):
  - Grep codebase for all picker.lua imports
  - Identify all functions called externally
  - Document current keybinding implementations
  - List all external dependencies on picker
- [x] Create `picker/` directory structure with subdirectories (file: nvim/lua/neotex/plugins/ai/claude/commands/picker/)
- [x] Create artifact registry module with 11 existing types (file: picker/artifacts/registry.lua)
- [x] Extract directory scanning logic to utils/scan.lua (file: picker/utils/scan.lua)
- [x] Extract metadata extraction to artifacts/metadata.lua (file: picker/artifacts/metadata.lua)
- [x] Create display/entries.lua with entry creation logic (file: picker/display/entries.lua)
- [x] Create display/previewer.lua with preview system (file: picker/display/previewer.lua)
- [x] Create operations/sync.lua with Load All logic (file: picker/operations/sync.lua)
- [x] Create picker/init.lua as new entry point (file: picker/init.lua)
- [x] Update picker.lua as facade delegating to new modules (file: picker.lua)
- [x] Verify all existing functionality works identically (manual testing)
- [x] Create test infrastructure with plenary.nvim (file: picker/artifacts/registry_spec.lua)
- [x] Write tests for registry module (80%+ coverage target)
- [x] Write tests for scan utilities (80%+ coverage target)
- [x] Write tests for metadata extraction (80%+ coverage target)

**Testing**:
```bash
# Manual verification
nvim -c "lua require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()"

# Automated tests
:TestSuite picker/
```

**Expected Duration**: 10 hours

### Phase 2: Add Missing Permanent Artifacts [NOT STARTED]
dependencies: [1]

**Objective**: Add Scripts and Tests artifact types (the only 2 missing permanent .claude/ artifacts)

**Complexity**: Medium

**Tasks**:
- [x] Add Scripts artifact type to registry (file: picker/artifacts/registry.lua)
- [x] Add Tests artifact type to registry (file: picker/artifacts/registry.lua)
- [x] Implement script-specific metadata parsing (file: picker/artifacts/metadata.lua)
- [x] Implement test-specific metadata parsing (file: picker/artifacts/metadata.lua)
- [x] Add Scripts entry creation to display/entries.lua
- [x] Add Tests entry creation to display/entries.lua
- [x] Update previewer for Scripts (file: picker/display/previewer.lua)
- [x] Update previewer for Tests (file: picker/display/previewer.lua)
- [x] Update Load All to scan scripts/ directory (file: picker/operations/sync.lua)
- [x] Update Load All to scan tests/ directory (file: picker/operations/sync.lua)
- [x] Add run script action with `<C-r>` keybinding (file: picker/operations/terminal.lua)
- [x] Add run test action with `<C-t>` keybinding (file: picker/operations/terminal.lua)
- [x] Update help documentation in picker (file: picker/init.lua)
- [x] Create README.md for picker/ directory (file: picker/README.md)
- [x] Write tests for new artifact types (80%+ coverage)

**Testing**:
```bash
# Verify Scripts visible in picker
# Verify Tests visible in picker
# Verify Load All syncs scripts/ and tests/
# Verify <C-r> runs scripts with arguments
# Verify <C-t> runs tests
```

**Expected Duration**: 6 hours

### Phase 3: Integration and Atomic Cutover [NOT STARTED]
dependencies: [1, 2]

**Objective**: Integrate all modules, improve sync operations, and perform atomic replacement of old implementation

**Complexity**: Medium (9/10)

**Summary**: Implement registry-driven sync with 5 conflict resolution options (including destructive "Clean Copy" with two-stage confirmation), add file integrity validation, and perform atomic cutover to new implementation. 80%+ test coverage, 95%+ for destructive operations.

**Expanded Details**: See [Phase 3 Expansion](phase_3_integration_atomic_cutover.md)

**Key Tasks Summary**:
- [x] Implement registry-driven sync in operations/sync.lua
- [x] Implement Option 1: Replace existing + add new (rename from "Replace all") (file: picker/operations/sync.lua)
- [x] Implement Option 2: Add new only (existing functionality) (file: picker/operations/sync.lua)
- [x] Implement Option 3: Interactive per-file conflict resolution UI (file: picker/operations/sync.lua)
- [x] Implement Option 4: Preview diff before sync (file: picker/operations/sync.lua)
- [x] Implement Option 5: Clean copy with local-only deletion (file: picker/operations/sync.lua)
  - [x] Add local-only artifact identification (file: picker/utils/scan.lua)
  - [x] Add deletion preview UI for Option 5 (file: picker/operations/sync.lua)
  - [x] Add two-stage safety confirmation for Option 5 (file: picker/operations/sync.lua)
  - [x] Add backup recommendation dialog for Option 5 (file: picker/operations/sync.lua)
  - [x] Implement directory cleanup after deletion (file: picker/utils/helpers.lua)
- [x] Add file integrity validation (checksum) (file: picker/utils/helpers.lua)
- [x] Add executable permissions verification (file: picker/utils/helpers.lua)
- [x] Implement sync result reporting with success/failure counts (file: picker/operations/sync.lua)
- [x] Add selective sync UI (choose artifact types) (file: picker/operations/sync.lua)
- [x] Create enhanced Load All preview showing changes (file: picker/display/previewer.lua)
- [x] Add retry logic for failed syncs (file: picker/operations/sync.lua)
- [x] Update help text with all 5 conflict resolution options (file: picker/init.lua)
- [x] **ATOMIC CUTOVER**:
  - [x] Update all external callers to use new API (single commit)
  - [x] Remove all old function implementations from picker.lua
  - [x] Verify no references to old patterns (grep validation)
  - [x] Update keybindings if function names changed
- [x] Write tests for sync operations (80%+ coverage)
- [x] Write tests for all 5 conflict resolution options (95%+ coverage for Option 5)
- [x] Write tests for public API (80%+ coverage)

**Testing**:
```bash
# Verify Option 1: Replace existing + add new works correctly
# Verify Option 2: Add new only skips conflicts
# Verify Option 3: Interactive conflict resolution prompts for each file
# Verify Option 4: Preview diff accurate
# Verify Option 5: Clean copy deletes local-only files correctly
# Verify Option 5: Safety confirmations require explicit approval
# Verify Option 5: Deletion preview shows accurate file list
# Verify failed syncs reported clearly
# Verify executable permissions preserved
# Verify selective sync UI
```

**Expected Duration**: 6 hours

### Phase 4: Polish and Documentation [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Production-ready release with comprehensive documentation

**Complexity**: Low

**Tasks**:
- [x] Update commands/README.md with picker architecture overview (file: commands/README.md)
- [x] Create picker/README.md describing modular structure (file: picker/README.md)
- [x] Create picker/artifacts/README.md documenting registry system (file: picker/artifacts/README.md)
- [x] Create picker/display/README.md explaining entry and preview logic (file: picker/display/README.md)
- [x] Create picker/operations/README.md detailing sync operations (file: picker/operations/README.md)
- [x] Create picker/utils/README.md for utility modules (file: picker/utils/README.md)
- [x] Create picker/ARCHITECTURE.md with module design and data flow (file: picker/ARCHITECTURE.md)
- [x] Create picker/USER_GUIDE.md with usage examples (file: picker/USER_GUIDE.md)
- [x] Create picker/DEVELOPMENT.md for contributors (file: picker/DEVELOPMENT.md)
- [x] Document all keybindings comprehensively (file: picker/README.md)
- [x] Performance optimization pass (profile and optimize hot paths)
- [x] Benchmark performance vs baseline (file: picker/BENCHMARKS.md)
- [x] Code review and cleanup pass
- [x] Final integration testing
- [x] Update CHANGELOG with all changes (file: commands/CHANGELOG.md)

**Testing**:
```bash
# Verify all documentation accurate
# Verify architecture guide complete
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
- Public API functionality preserved
- Keybinding functionality
- Search and filter operations

**3. Performance Tests**:
- Baseline vs refactored performance comparison
- Large artifact list handling (100+ files)
- Preview rendering speed
- Sync operation timing

**4. Functional Tests**:
- All features work correctly
- User workflows function as expected
- Configuration options work as expected

### Test Execution

**Manual Testing Checklist**:
- [ ] Open picker with `<leader>ac`
- [ ] Navigate through all artifact categories
- [ ] Preview multiple artifact types
- [ ] Edit artifacts and verify changes
- [ ] Run Load All with Option 1: Replace existing + add new
- [ ] Run Load All with Option 2: Add new only
- [ ] Run Load All with Option 3: Interactive per-file
- [ ] Run Load All with Option 4: Preview diff
- [ ] Run Load All with Option 5: Clean copy (verify deletion preview and confirmation)
- [ ] Test Scripts run action (`<C-r>`)
- [ ] Test Tests run action (`<C-t>`)
- [ ] Search for artifacts
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

**Architecture Document** (`picker/ARCHITECTURE.md`):
- Design decisions
- Module responsibilities
- Data flow diagrams (using Unicode box-drawing)
- Extension points
- Registry system design

**Development Guide** (`picker/DEVELOPMENT.md`):
- How to add new artifact types
- Testing requirements
- Module organization principles

**User Guide** (`picker/USER_GUIDE.md`):
- Feature overview
- Keybinding reference
- Load All options
- Artifact type coverage
- Troubleshooting

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
| Breaking user workflows | Low | High | Facade layer provides stable API, extensive testing |
| Performance degradation | Low | Medium | Benchmark before/after, optimize registries |
| Incomplete artifact coverage | Low | Low | Registry-driven ensures consistency |
| Testing gaps | Medium | Medium | 80% coverage requirement enforced |

### User Impact Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Learning curve for new features | Low | Low | Preserve existing UX, document new features |
| Workflow disruption | Low | Medium | All features work correctly, extensive testing |
| Configuration migration | None | None | No config changes required |

### Maintenance Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Module coupling | Low | Medium | Clear interfaces, dependency injection |
| Documentation drift | Medium | Low | README requirements enforced |
| Test maintenance | Low | Low | Focused tests per module |

## Risk Mitigation Strategy

### Pre-Merge Quality Gates

**Before committing to main branch**:
1. All tests passing (80%+ coverage requirement)
2. Manual verification checklist complete (Phase 1 task)
3. Performance benchmarks within ±5% baseline
4. Code review approval

### Post-Merge Issue Resolution

**If issues discovered after merge**:
1. **Fix Forward**: Debug and patch the modular implementation
2. **No Rollback to Old Code**: The modular architecture IS the picker
3. **Rapid Response**: High-priority fixes for user-facing issues

**Rationale**:
- Clean-break approach requires confidence in new implementation
- Comprehensive testing (Phases 1-4) builds that confidence
- Forward fixes are faster than maintaining dual implementations
- Git revert available for catastrophic failures (standard practice)

### Risk Reduction Through Design

**Architectural Safeguards**:
- Facade pattern isolates API changes
- Comprehensive test coverage catches regressions
- Phased implementation allows incremental validation
- Performance benchmarks prevent degradation

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
- [ ] All 13 permanent artifact types visible in picker
- [ ] Scripts and tests preview/edit work correctly
- [ ] Load All syncs 13 permanent artifact types successfully
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
- [ ] Architecture documented
- [ ] Development guide complete
- [ ] User guide comprehensive
- [ ] Code comments adequate

### User Validation
- [ ] All features work correctly
- [ ] User workflows function properly
- [ ] New features intuitive
- [ ] No user complaints about performance

## Notes

**Complexity Score Calculation**: 119.5 (recalculated after revision 2)
- Base (refactor): 5
- Tasks (63 tasks after removing Phase 3): 63 / 2 = 31.5
- Files (15 estimated after removing specs.lua and related): 15 * 3 = 45
- Integrations (telescope, plenary): 2 * 5 = 10
- Dependencies (parser.lua): 1 * 2 = 2
- **Total**: 5 + 31.5 + 45 + 10 + 2 = 93.5
- **Original calculation**: 142.0 (with specs/ artifacts)
- **Adjustment**: Removed ~15 tasks (-7.5), 5 files (-15), for final score of ~119.5

**Note**: Complexity score of 119.5 suggests this plan could benefit from phase expansion during implementation. Consider using `/expand [phase|stage] <path> <number>` if any phase becomes too complex.

**Scope Clarification**: This plan focuses on permanent .claude/ system artifacts only. The specs/ directory (plans/, reports/, summaries/) contains temporary, gitignored working files and is intentionally excluded from picker coverage. Only committed, system-wide artifact types are in scope.

**Templates Directory**: Research identified code for templates/ directory that doesn't exist. During Phase 1, verify if this was deprecated in favor of commands/templates/ and update registry accordingly.

**Progressive Expansion**: This Level 0 (single file) plan can be expanded to Level 1 (phase files) or Level 2 (stage files) during implementation if any phase requires more detailed breakdown.

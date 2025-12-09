# Implementation Plan: Goose Picker Utility with Recipe Management

## Metadata

- **Date**: 2025-12-09
- **Feature**: Unified Telescope-based picker utility for Goose recipes replacing <leader>aR keybinding
- **Status**: [COMPLETE]
- **Estimated Hours**: 12-16 hours
- **Complexity Score**: 145
- **Structure Level**: 2
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Claude Code Artifact Picker Architecture](../reports/001-claude-artifact-picker-research.md)
  - [Goose Utility Picker Design Research Report](../reports/002-goose-picker-design.md)
  - [Recipe Execution and Keybinding Integration Research](../reports/003-goose-recipes-keybinding.md)

## Overview

### Purpose

Create a comprehensive Telescope-based picker utility for Goose that manages recipes, provides rich previews, validates parameters, and replaces the existing <leader>aR keybinding with a modular, maintainable architecture following the proven Claude Code picker patterns.

### Scope

**In Scope**:
- Modular picker architecture with Telescope integration
- Recipe discovery from project (.goose/recipes/) and global (~/.config/goose/recipes/) locations
- YAML metadata parsing for recipe parameters and descriptions
- Rich preview window showing recipe details, parameters, and subrecipes
- Parameter validation and structured prompting based on recipe definitions
- Context-aware keybindings for recipe execution, editing, validation, and preview
- ToggleTerm integration for recipe execution with proper parameter passing
- Migration of existing <leader>aR keybinding to new picker module

**Out of Scope** (future enhancements):
- Session management integration (separate picker category)
- Provider/configuration management (separate picker category)
- Recipe creation wizard (Goose AI-assisted recipe generation)
- Batch recipe operations (Load All equivalent)
- Recipe template management

### Success Criteria

- [ ] Recipe picker opens via <leader>aR with Telescope interface
- [ ] Recipes from both project and global directories displayed with location labels
- [ ] Recipe preview shows name, description, parameters, subrecipes, and execution command
- [ ] Parameter prompting validates types (string, number, boolean) and requirements (required, optional, user_prompt)
- [ ] Recipe execution sends properly formatted goose CLI command to ToggleTerm
- [ ] All keybindings documented and functional (<CR>, <C-e>, <C-p>, <C-v>)
- [ ] Module structure follows Claude picker patterns with separation of concerns
- [ ] Unit tests validate metadata parsing and recipe discovery
- [ ] Integration tests verify end-to-end workflow with existing recipes

### Technical Design

**Architecture**: Modular Telescope picker following Claude Code artifact picker patterns

**Module Structure**:
```
nvim/lua/neotex/plugins/ai/goose/picker/
├── init.lua          # Main orchestration, Telescope integration, keybindings
├── discovery.lua     # Recipe discovery (project + global), priority sorting
├── metadata.lua      # YAML parsing, parameter extraction, validation rules
├── previewer.lua     # Recipe preview window with markdown formatting
├── execution.lua     # Parameter prompting, CLI command construction, ToggleTerm integration
└── README.md         # Module documentation, usage examples, keybinding reference
```

**Key Components**:
1. **init.lua**: Entry point exposing `show_recipe_picker()`, Telescope configuration, attach_mappings for keybindings
2. **discovery.lua**: Scans .goose/recipes/ and ~/.config/goose/recipes/, merges with priority (project-first), returns recipe entries
3. **metadata.lua**: Parses YAML frontmatter (name, description, parameters, subrecipes), validates parameter definitions
4. **previewer.lua**: Custom Telescope previewer showing recipe metadata in markdown format
5. **execution.lua**: Prompts for parameters based on requirement type, constructs goose CLI command, executes in ToggleTerm

**Data Flow**:
```
User presses <leader>aR
  ↓
init.show_recipe_picker() invoked
  ↓
discovery.find_recipes() scans directories
  ↓
metadata.parse() extracts YAML for each recipe
  ↓
Telescope picker displays entries with previewer
  ↓
User selects recipe, presses <CR>
  ↓
execution.run_recipe() prompts for parameters
  ↓
execution.build_command() constructs CLI command
  ↓
ToggleTerm executes: goose run --recipe <path> --interactive --params key=value
```

**Integration Points**:
- **Telescope**: Picker UI, finders, actions, previewers
- **ToggleTerm**: Recipe execution via `:TermExec cmd='...'`
- **which-key**: Keybinding registration and icon display
- **goose.nvim**: Provider detection, configuration reading (no direct dependency)

**Standards Compliance**:
- **Code Standards**: Lua module structure, function documentation, error handling
- **Testing Protocols**: Unit tests for metadata parsing, integration tests for discovery
- **Documentation Policy**: README.md with module overview, usage examples, API reference
- **Directory Organization**: Picker module in neotex/plugins/ai/goose/picker/ follows plugin structure

### Dependencies

**Required**:
- telescope.nvim: Picker framework (already installed)
- plenary.nvim: File system utilities (Telescope dependency)
- toggleterm.nvim: Terminal execution (already installed)
- which-key.nvim: Keybinding management (already installed)

**Optional**:
- nvim-treesitter: Markdown syntax highlighting in preview (recommended)

**External Tools**:
- goose CLI: Recipe execution, validation (goose run, goose recipe validate)
- YAML parser: Lua pattern matching for simple parsing (no external library needed)

## Implementation Phases

### Phase 1: Create Picker Module Structure [COMPLETE]

**Objective**: Establish directory structure and skeleton modules for Goose recipe picker

**Tasks**:
- [x] Create directory: `nvim/lua/neotex/plugins/ai/goose/picker/`
- [x] Create skeleton files: init.lua, discovery.lua, metadata.lua, previewer.lua, execution.lua
- [x] Add module documentation headers with purpose and API contract
- [x] Create README.md with architecture overview and planned features
- [x] Verify directory structure matches Claude picker pattern

**Deliverables**:
- Directory structure created at `nvim/lua/neotex/plugins/ai/goose/picker/`
- Skeleton Lua files with module stubs and documentation headers
- README.md documenting module purpose and architecture

**Success Criteria**:
- [x] All module files exist and can be required without errors
- [x] README.md documents module structure and planned capabilities
- [x] Directory structure validated against Neovim plugin conventions

**Testing**:
- Manual verification: `require("neotex.plugins.ai.goose.picker")` loads without errors
- Directory structure matches documented architecture

**Estimated Time**: 1-2 hours

**Dependencies**: None

---

### Phase 2: Implement Recipe Discovery Module [COMPLETE]

**Objective**: Create recipe discovery system that scans project and global recipe directories with priority-based merging

**Tasks**:
- [x] Implement `find_recipes()` function scanning .goose/recipes/ and ~/.config/goose/recipes/
- [x] Add directory existence checks with graceful fallback
- [x] Implement priority-based sorting (project recipes first, then alphabetical)
- [x] Add location labeling ([Project], [Global]) for display
- [x] Create `get_recipe_path()` helper for absolute path resolution
- [x] Add error handling for directory access issues
- [x] Implement caching mechanism with 5-minute timeout (optional optimization)

**Deliverables**:
- `discovery.lua` module with `find_recipes()` function
- Recipe discovery returns list of entries with name, path, location, priority, metadata
- Location labels integrated for display differentiation

**Success Criteria**:
- [x] Discovers recipes from both project and global directories
- [x] Returns empty list with warning notification if no recipes found
- [x] Project recipes appear before global recipes in sorted list
- [x] Location labels correctly identify source ([Project] or [Global])
- [x] Handles missing directories gracefully without errors

**Testing**:
- Unit test: Mock directory structure with project and global recipes
- Unit test: Empty directory returns empty list with warning
- Unit test: Sort order validates project-first then alphabetical
- Integration test: Discover recipes from actual .goose/recipes/ directory

**Estimated Time**: 2-3 hours

**Dependencies**: Phase 1 complete

---

### Phase 3: Implement YAML Metadata Parser [COMPLETE]

**Objective**: Create YAML parser that extracts recipe metadata (name, description, parameters, subrecipes) for preview and validation

**Tasks**:
- [x] Implement `parse()` function for recipe YAML files
- [x] Extract top-level fields: name, description, instructions
- [x] Parse parameters array with key, input_type, requirement, description, default
- [x] Extract sub_recipes list with name and path
- [x] Add validation for parameter definitions (type checks, requirement values)
- [x] Implement `extract_yaml_field()` helper for simple pattern matching
- [x] Add `parse_parameters_section()` for structured parameter parsing
- [x] Handle malformed YAML gracefully with error reporting
- [x] Add caching for parsed recipes (keyed by filepath + mtime)

**Deliverables**:
- `metadata.lua` module with `parse()` function
- Parsed metadata structure: { name, description, parameters, sub_recipes, instructions }
- Parameter validation returning structured parameter definitions

**Success Criteria**:
- [x] Parses name and description from YAML frontmatter
- [x] Extracts all parameters with type, requirement, and default values
- [x] Identifies subrecipes with names and paths
- [x] Handles optional fields gracefully (missing parameters, no subrecipes)
- [x] Returns error for malformed YAML with descriptive message

**Testing**:
- Unit test: Parse create-plan.yaml and validate structure
- Unit test: Handle missing fields (no parameters, no description)
- Unit test: Malformed YAML returns error without crashing
- Integration test: Parse all recipes in .goose/recipes/ and verify metadata

**Estimated Time**: 2-3 hours

**Dependencies**: Phase 1 complete

---

### Phase 4: Implement Recipe Preview Window [COMPLETE]

**Objective**: Create custom Telescope previewer showing recipe metadata in markdown-formatted preview window

**Tasks**:
- [x] Implement `create_recipe_previewer()` function using telescope.previewers
- [x] Create `define_preview()` callback formatting recipe metadata
- [x] Format preview with sections: Recipe name, Description, Parameters, Subrecipes, Execution
- [x] Add parameter formatting: index, key, type, requirement, default, description
- [x] Include execution command preview: `goose run --recipe <path> --interactive`
- [x] Apply markdown syntax highlighting to preview buffer
- [x] Add truncation indicator for long instructions (>150 lines)
- [x] Handle recipes with no parameters or subrecipes gracefully
- [x] Add scrolling support via Telescope native actions (<C-u>, <C-d>)

**Deliverables**:
- `previewer.lua` module with `create_recipe_previewer()` function
- Markdown-formatted preview showing all recipe metadata
- Syntax highlighting for preview buffer

**Success Criteria**:
- [x] Preview shows recipe name, description, parameters, subrecipes
- [x] Parameters formatted with type, requirement, default in readable layout
- [x] Execution command displayed at bottom of preview
- [x] Markdown syntax highlighting applied correctly
- [x] Preview scrolls with <C-u>/<C-d> keybindings
- [x] Empty sections (no parameters, no subrecipes) handled gracefully

**Testing**:
- Manual test: Open picker, navigate recipes, verify preview updates
- Manual test: Preview create-plan.yaml shows 3 parameters correctly
- Manual test: Preview simple recipe (no parameters) displays cleanly
- Integration test: Preview all project recipes without errors

**Estimated Time**: 2-3 hours

**Dependencies**: Phase 2, Phase 3 complete (requires discovery and metadata)

---

### Phase 5: Implement Recipe Execution with Parameter Prompting [COMPLETE]

**Objective**: Create parameter prompting system with validation and goose CLI command construction for ToggleTerm execution

**Tasks**:
- [x] Implement `run_recipe()` function with parameter collection workflow
- [x] Add parameter prompting loop for required/user_prompt parameters
- [x] Implement `validate_param()` for type checking (string, number, boolean)
- [x] Add `build_command()` constructing goose CLI command with --params flags
- [x] Implement proper shell escaping for parameter values
- [x] Add default value substitution for optional parameters
- [x] Create error handling for missing required parameters
- [x] Integrate with ToggleTerm via `:TermExec cmd='...'`
- [x] Add execution notification (recipe started, parameter count)
- [x] Implement validation mode: goose recipe validate <path>

**Deliverables**:
- `execution.lua` module with `run_recipe()` and `build_command()` functions
- Parameter validation with type checking and requirement enforcement
- goose CLI command construction with proper escaping and parameter passing

**Success Criteria**:
- [x] Required parameters prompt user with type validation
- [x] Optional parameters use defaults if not provided
- [x] goose CLI command constructed correctly with --params flags
- [x] Shell escaping prevents injection for special characters
- [x] ToggleTerm executes recipe with interactive mode enabled
- [x] Validation mode checks recipe syntax before execution
- [x] Missing required parameters abort execution with error

**Testing**:
- Unit test: Parameter validation for string, number, boolean types
- Unit test: build_command() constructs correct CLI syntax
- Unit test: Shell escaping handles special characters (commas, equals, quotes)
- Integration test: Execute create-plan.yaml with parameters in ToggleTerm
- Integration test: Validation mode detects malformed YAML

**Estimated Time**: 3-4 hours

**Dependencies**: Phase 3 complete (requires metadata parsing)

---

### Phase 6: Telescope Picker Integration and Keybinding Migration [COMPLETE]

**Objective**: Integrate all modules into Telescope picker, implement keybindings, and migrate <leader>aR to new picker

**Tasks**:
- [x] Implement `show_recipe_picker()` in init.lua with Telescope integration
- [x] Configure Telescope picker: prompt_title, finder, sorter, previewer
- [x] Create entry_maker formatting recipe display: `[Location] recipe-name`
- [x] Implement attach_mappings with context-aware keybindings
- [x] Add <CR> mapping: Run recipe with parameter prompts (execution.run_recipe)
- [x] Add <C-e> mapping: Edit recipe file in buffer
- [x] Add <C-p> mapping: Preview recipe with --explain flag (dry run)
- [x] Add <C-v> mapping: Validate recipe with goose recipe validate
- [x] Add <C-r> mapping: Refresh picker (reload recipe list)
- [x] Update which-key.lua: Replace inline <leader>aR with picker invocation
- [x] Add notification for picker open (recipe count, location summary)
- [x] Create user command: `:GooseRecipes` for direct invocation
- [x] Update goose/README.md documenting picker usage and keybindings

**Deliverables**:
- `init.lua` with complete Telescope picker implementation
- Keybinding migration in which-key.lua
- User command `:GooseRecipes` for CLI-style invocation
- Documentation updates in goose/README.md

**Success Criteria**:
- [x] <leader>aR opens Telescope picker with recipe list
- [x] <CR> executes recipe with parameter prompts
- [x] <C-e> opens recipe YAML file in buffer for editing
- [x] <C-p> runs recipe in preview mode (--explain flag)
- [x] <C-v> validates recipe syntax and reports errors
- [x] <C-r> refreshes recipe list without closing picker
- [x] Display shows location labels: [Project] or [Global]
- [x] Preview window updates as user navigates recipes
- [x] Picker handles empty recipe directories with notification
- [x] `:GooseRecipes` command works identically to <leader>aR

**Testing**:
- Manual test: Press <leader>aR, verify picker opens with recipes
- Manual test: Select recipe, press <CR>, verify parameter prompts
- Manual test: Test all keybindings (<C-e>, <C-p>, <C-v>, <C-r>)
- Integration test: Execute create-plan.yaml end-to-end via picker
- Integration test: Edit recipe, refresh picker, verify changes appear
- Integration test: Validate malformed recipe shows error notification

**Estimated Time**: 3-4 hours

**Dependencies**: Phase 2, Phase 3, Phase 4, Phase 5 complete (requires all modules)

---

## Testing Strategy

### Unit Tests

**Test Framework**: plenary.nvim (Neovim Lua testing)

**Test Files**:
- `tests/goose/picker/metadata_spec.lua`: YAML parsing, parameter extraction, validation
- `tests/goose/picker/discovery_spec.lua`: Recipe discovery, sorting, location labeling
- `tests/goose/picker/execution_spec.lua`: Parameter validation, CLI command construction

**Test Cases**:
1. **metadata_spec.lua**:
   - Parse recipe with all fields (name, description, parameters, subrecipes)
   - Parse recipe with missing optional fields (no parameters, no description)
   - Handle malformed YAML gracefully (syntax errors, missing required fields)
   - Extract parameter types, requirements, defaults correctly
   - Validate parameter requirement values (required, optional, user_prompt)

2. **discovery_spec.lua**:
   - Discover recipes from project directory only
   - Discover recipes from global directory only
   - Merge project and global recipes with priority sorting
   - Handle empty directories (no recipes found)
   - Handle missing directories (directory does not exist)

3. **execution_spec.lua**:
   - Validate string parameters (non-empty)
   - Validate number parameters (tonumber conversion)
   - Validate boolean parameters (true/false conversion)
   - Build CLI command with single parameter
   - Build CLI command with multiple parameters
   - Shell escape special characters (commas, equals, quotes)

**Coverage Target**: >80% for core modules (metadata, discovery, execution)

### Integration Tests

**Test Files**:
- `tests/goose/picker/integration_spec.lua`: End-to-end workflow validation

**Test Cases**:
1. **Recipe Discovery Integration**:
   - Scan actual .goose/recipes/ directory
   - Parse all discovered recipes without errors
   - Verify metadata extracted for each recipe

2. **Picker Display Integration**:
   - Open picker with mock recipes
   - Verify entry formatting with location labels
   - Verify preview updates on navigation

3. **Recipe Execution Integration**:
   - Execute test recipe with parameters (tests/test-params.yaml)
   - Verify CLI command sent to ToggleTerm
   - Verify parameter substitution in command

4. **Keybinding Integration**:
   - Simulate <CR> press (execute recipe)
   - Simulate <C-e> press (edit recipe)
   - Simulate <C-p> press (preview recipe)
   - Simulate <C-v> press (validate recipe)

**Coverage Target**: 100% of user-facing workflows (execute, edit, preview, validate)

### Manual Testing

**Test Scenarios**:
1. **Basic Workflow**:
   - Press <leader>aR
   - Select create-plan.yaml
   - Enter parameters: feature_description="Test feature", complexity=2
   - Verify recipe executes in ToggleTerm

2. **Recipe Editing**:
   - Open picker
   - Select recipe
   - Press <C-e>
   - Edit recipe YAML
   - Press <C-r> to refresh picker
   - Verify changes reflected

3. **Recipe Validation**:
   - Create malformed recipe (invalid YAML)
   - Open picker
   - Select malformed recipe
   - Press <C-v>
   - Verify validation error notification

4. **Empty Directory**:
   - Move all recipes from .goose/recipes/
   - Open picker
   - Verify "no recipes found" notification

5. **Multi-Location Discovery**:
   - Add recipes to ~/.config/goose/recipes/
   - Open picker
   - Verify both [Project] and [Global] recipes displayed
   - Verify [Project] recipes appear first

**Test Duration**: 30-45 minutes for complete manual test suite

### Test Automation

**Continuous Integration**: Not applicable (Neovim plugin, requires interactive environment)

**Pre-Commit Tests**:
```bash
# Run unit tests
nvim --headless -c "PlenaryBustedDirectory tests/goose/picker/ {minimal_init = 'tests/minimal_init.lua'}"

# Run integration tests
nvim --headless -c "PlenaryBustedDirectory tests/goose/picker/integration_spec.lua {minimal_init = 'tests/minimal_init.lua'}"
```

**Test Execution**: Automated via `make test` or `:PlenaryBustedDirectory` command

## Documentation Requirements

### Module Documentation

**File**: `nvim/lua/neotex/plugins/ai/goose/picker/README.md`

**Sections**:
1. **Overview**: Purpose, architecture, integration points
2. **Module Structure**: Directory layout, file descriptions
3. **API Reference**: Public functions with parameters and return values
4. **Usage Examples**: Code snippets for common operations
5. **Keybindings**: Complete keybinding reference with descriptions
6. **Testing**: Test suite organization, running tests
7. **Troubleshooting**: Common issues and solutions

### User Documentation

**File**: `nvim/lua/neotex/plugins/ai/goose/README.md`

**Updates**:
- Add "Recipe Picker" section documenting <leader>aR usage
- Include keybinding reference table
- Add parameter prompting workflow diagram
- Document recipe discovery paths (project vs global)
- Include examples of recipe execution with parameters

### Code Documentation

**Standards**:
- Lua doc comments for all public functions
- Function signatures with @param and @return tags
- Module headers with purpose and dependencies
- Inline comments for complex logic (WHAT, not WHY)

**Example**:
```lua
--- Show the Goose recipe picker
--- @param opts table|nil Telescope options
--- @return nil
function M.show_recipe_picker(opts)
  -- Implementation
end
```

### Migration Guide

**File**: `nvim/lua/neotex/plugins/ai/goose/MIGRATION.md` (optional)

**Sections**:
- Old vs New: Comparison of inline <leader>aR vs picker module
- Breaking Changes: None (backward compatible keybinding)
- New Features: Preview, validation, multi-location discovery
- Upgrade Path: Automatic (keybinding points to new picker)

## Risk Assessment

### Technical Risks

**Risk 1: YAML Parsing Complexity**
- **Impact**: Medium
- **Probability**: Low
- **Mitigation**: Use simple pattern matching for MVP, defer complex YAML library integration to future enhancement
- **Fallback**: Use external yq tool via vim.fn.system() for complex recipes

**Risk 2: ToggleTerm Integration Issues**
- **Impact**: High
- **Probability**: Low
- **Mitigation**: Test TermExec command construction with various parameter types and special characters
- **Fallback**: Use vim.fn.jobstart() for direct command execution if ToggleTerm fails

**Risk 3: Parameter Type Validation**
- **Impact**: Low
- **Probability**: Medium
- **Mitigation**: Implement strict type checking for string, number, boolean with clear error messages
- **Fallback**: Accept all parameters as strings, let goose CLI handle validation

### Implementation Risks

**Risk 1: Module Loading Order**
- **Impact**: Medium
- **Probability**: Low
- **Mitigation**: Use require() within functions (lazy loading) rather than at module scope
- **Fallback**: Add explicit require order documentation in README

**Risk 2: Keybinding Conflicts**
- **Impact**: Low
- **Probability**: Low
- **Mitigation**: Use existing <leader>aR keybinding (no new conflict), test in which-key context
- **Fallback**: Provide alternative keybinding <leader>aP if <leader>aR conflicts discovered

**Risk 3: Recipe Discovery Performance**
- **Impact**: Low
- **Probability**: Medium
- **Mitigation**: Implement caching with 5-minute timeout, lazy metadata parsing
- **Fallback**: Add configuration option to disable global recipe discovery if slow

### User Impact Risks

**Risk 1: Breaking Existing Workflow**
- **Impact**: Low
- **Probability**: Very Low
- **Mitigation**: Preserve <leader>aR keybinding, maintain same execution behavior
- **Fallback**: Provide legacy mode configuration option if users prefer old vim.ui.select picker

**Risk 2: Learning Curve for New Keybindings**
- **Impact**: Low
- **Probability**: Medium
- **Mitigation**: Document all keybindings in which-key popup and README, provide <C-h> help overlay
- **Fallback**: Make advanced keybindings (<C-p>, <C-v>) optional via configuration

## Rollback Plan

### Rollback Triggers

- Recipe picker fails to open (Lua errors)
- Recipe execution sends malformed commands to ToggleTerm
- Parameter prompting crashes Neovim
- Module dependencies break existing goose.nvim functionality

### Rollback Steps

1. **Restore Original Keybinding**:
   ```lua
   -- In which-key.lua, revert to original inline implementation
   { "<leader>aR", function()
     -- Original vim.ui.select implementation (lines 371-413 from research)
   end, desc = "goose run recipe", icon = "󰑮" }
   ```

2. **Remove Picker Module**:
   ```bash
   rm -rf nvim/lua/neotex/plugins/ai/goose/picker/
   ```

3. **Revert Documentation**:
   - Restore original goose/README.md from git history
   - Remove picker documentation references

4. **Verify Functionality**:
   - Test <leader>aR opens original vim.ui.select picker
   - Test recipe execution with parameters still works
   - Confirm no Lua errors on Neovim startup

### Rollback Validation

- [ ] <leader>aR keybinding functional with original implementation
- [ ] Recipe execution works with parameter input
- [ ] No Lua errors in :messages log
- [ ] goose.nvim plugin loads without errors

## Maintenance Plan

### Post-Implementation Tasks

**Week 1**:
- Monitor for Lua errors in :messages log
- Gather user feedback on keybinding UX
- Validate parameter prompting with complex recipes
- Check recipe discovery performance with large recipe sets

**Week 2-4**:
- Address any bug reports or usability issues
- Optimize metadata parsing if performance issues detected
- Add missing parameter types if discovered in recipes
- Update documentation based on user questions

### Long-Term Maintenance

**Monthly**:
- Review recipe discovery paths for new Goose conventions
- Update YAML parser for new recipe fields (if Goose spec changes)
- Check compatibility with Telescope.nvim updates
- Validate keybindings against which-key changes

**Quarterly**:
- Consider feature enhancements (session management, config management)
- Evaluate YAML parsing library integration if simple parser insufficient
- Review test coverage and add missing test cases
- Update documentation with new usage patterns

### Documentation Updates

**Triggers for Updates**:
- New recipe fields added to Goose specification
- New keybindings added for picker operations
- Discovery paths change (new recipe locations)
- Parameter validation rules change

**Update Locations**:
- `picker/README.md`: API changes, new functions
- `goose/README.md`: User-facing feature changes, keybinding updates
- Code comments: Function signature changes

## Future Enhancements

### Phase 7: Session Management Integration (Post-MVP)

**Scope**: Extend picker to include session listing, resume, and cleanup

**Features**:
- Session discovery from ~/.config/goose/sessions/
- Session entry formatting: workspace, message count, time ago
- Session preview: last N messages, timestamps
- Session operations: resume (<CR>), delete (<C-d>), view details (<C-i>)

**Estimated Hours**: 4-6 hours

### Phase 8: Configuration Management Integration (Post-MVP)

**Scope**: Add provider and configuration management to picker

**Features**:
- Configuration entries: provider, model, mode
- Provider status checking: authentication, subscription tier
- Provider switching: show available providers with status
- Model selection: filter models by provider and tier
- Mode toggle: switch between auto and chat modes

**Estimated Hours**: 3-4 hours

### Phase 9: Recipe Creation Wizard (Post-MVP)

**Scope**: Add recipe creation helper with Goose AI assistance

**Features**:
- <C-n> keybinding: prompt for recipe description
- Goose AI generation: create recipe YAML from natural language
- Template selection: choose from recipe templates (utility, automation, workflow)
- Recipe validation: automatic syntax checking after creation
- Location selection: save to project or global directory

**Estimated Hours**: 5-7 hours

### Phase 10: Advanced Recipe Management (Post-MVP)

**Scope**: Batch operations and recipe organization

**Features**:
- Recipe deeplink generation: <C-l> creates shareable link
- Recipe synchronization: copy recipes between project and global
- Recipe validation batch: validate all recipes in directory
- Recipe filtering: filter by category, parameters, subrecipes
- Recipe search: fuzzy search in recipe names and descriptions

**Estimated Hours**: 4-6 hours

## Completion Checklist

### Phase Completion
- [ ] Phase 1: Picker module structure created
- [ ] Phase 2: Recipe discovery implemented and tested
- [ ] Phase 3: YAML metadata parser implemented and tested
- [ ] Phase 4: Recipe preview window implemented
- [ ] Phase 5: Recipe execution with parameter prompting implemented
- [ ] Phase 6: Telescope picker integrated and keybinding migrated

### Testing Completion
- [ ] Unit tests written for metadata, discovery, execution
- [ ] Integration tests written for end-to-end workflows
- [ ] Manual testing completed for all keybindings
- [ ] Test coverage >80% for core modules

### Documentation Completion
- [ ] picker/README.md created with API reference
- [ ] goose/README.md updated with picker usage
- [ ] Code documentation added to all public functions
- [ ] Keybinding reference documented in README

### Deployment Validation
- [ ] <leader>aR opens picker without errors
- [ ] Recipe execution works with parameters
- [ ] Preview window displays correctly
- [ ] All keybindings functional
- [ ] No Lua errors in :messages log
- [ ] Existing goose.nvim functionality unaffected

# Artifact Management Comprehensive Analysis

## Executive Summary

**Research Focus**: Analysis of `<leader>ac` command (Claude artifacts picker) in nvim to ensure full coverage of .claude/ artifact types and design refactor for improved artifact management.

**Key Findings**:
- Current implementation covers 11 artifact categories across 3,385 lines
- Missing coverage: 5 critical artifact types (scripts/, tmp/, archive/, backups/, specs/)
- Load All Artifacts function syncs only curated artifacts, not all .claude/ contents
- Picker architecture is well-structured but lacks extensibility for new artifact types
- Significant opportunity for modularization and enhanced artifact lifecycle management

**Recommendation**: Implement phased refactor to add missing artifact types while improving modularity and maintaining backward compatibility.

---

## 1. Current Implementation Analysis

### 1.1 Architecture Overview

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Size**: 3,385 lines
**Module**: `neotex.plugins.ai.claude.commands.picker`

**Key Components**:
1. **Entry Creation** (`create_picker_entries`) - Lines 227-728
   - Reversed insertion pattern for descending sort display
   - Category headings appear at top, artifacts below
   - Hierarchical tree structure with indent characters

2. **Preview System** (`create_command_previewer`) - Lines 816-1303
   - Custom previewer for all artifact types
   - README content display for category headings
   - Markdown rendering with syntax highlighting

3. **Load All Artifacts** (`load_all_globally`) - Lines 1566-1807
   - Batch synchronization from global to local
   - Conflict resolution (replace vs merge strategies)
   - Comprehensive coverage of curated artifacts

4. **File Operations**:
   - `scan_directory_for_sync` - Line 745
   - `sync_files` - Line 772
   - `edit_artifact_file` - Line 1305

### 1.2 Currently Supported Artifact Types

#### Fully Implemented (11 Categories)

| Category | Pattern | Locations | Preview | Edit | Load |
|----------|---------|-----------|---------|------|------|
| Commands | `*.md` | `.claude/commands/` | Yes | Yes | Yes |
| Agents | `*.md` | `.claude/agents/` | Yes | Yes | Yes |
| Hook Events | `*.sh` | `.claude/hooks/` | Yes | Yes | Yes |
| TTS Files | `*.sh` | `.claude/hooks/`, `.claude/tts/` | Yes | Yes | Yes |
| Templates | `*.yaml` | `.claude/templates/` | Yes | Yes | Yes |
| Lib Utils | `*.sh` | `.claude/lib/` | Yes | Yes | Yes |
| Docs | `*.md` | `.claude/docs/` | Yes | Yes | Yes |
| Agent Protocols | `*.md` | `.claude/agents/prompts/`, `.claude/agents/shared/` | No | No | Yes |
| Standards | `*.md` | `.claude/specs/standards/` | No | No | Yes |
| Data Docs | `README.md` | `.claude/data/commands/`, `.claude/data/agents/`, `.claude/data/templates/` | No | No | Yes |
| Settings | `settings.local.json` | `.claude/` | No | No | Yes |

**Coverage Summary**:
- 7 categories with full picker display (Commands → Docs)
- 4 categories sync-only (Agent Protocols → Settings)
- All categories support Load All Artifacts operation

### 1.3 Load All Artifacts Coverage

**Function**: `load_all_globally()` (Line 1566)

**Scanned Directories** (Lines 1582-1614):
```lua
-- Primary artifacts
commands/        *.md
agents/          *.md
hooks/           *.sh
tts/             *.sh
templates/       *.yaml
lib/             *.sh
docs/            *.md

-- Subdirectories
agents/prompts/  *.md, README.md
agents/shared/   *.md, README.md
specs/standards/ *.md
data/commands/   README.md
data/agents/     README.md
data/templates/  README.md

-- Configuration
./               settings.local.json
```

**Directory Creation** (Lines 1518-1531):
- Creates 10 local directories automatically
- Ensures directory structure exists before sync
- Preserves executable permissions for `.sh` files

---

## 2. .claude/ Directory Comprehensive Map

### 2.1 Official Directory Structure

Based on `/home/benjamin/.config/.claude/`:

```
.claude/
├── agents/              [COVERED] Agent definitions
│   ├── prompts/         [COVERED] Agent protocols (sync-only)
│   └── shared/          [COVERED] Shared protocols (sync-only)
├── archive/             [MISSING] Archived artifacts
├── backups/             [MISSING] Backup files
├── commands/            [COVERED] Slash commands
├── data/                [PARTIAL] Runtime/operational data
│   ├── agents/          [COVERED] Agent data (README only)
│   ├── checkpoints/     [MISSING] State checkpoints
│   ├── commands/        [COVERED] Command data (README only)
│   ├── logs/            [MISSING] Log files
│   └── templates/       [COVERED] Template data (README only)
├── docs/                [COVERED] Documentation
├── hooks/               [COVERED] Event hooks
├── lib/                 [COVERED] Function libraries
├── scripts/             [MISSING] Standalone CLI tools
├── specs/               [PARTIAL] Feature specifications
│   ├── {NNN_topic}/     Topic directories
│   │   ├── plans/       [MISSING] Implementation plans
│   │   ├── reports/     [MISSING] Research reports
│   │   ├── summaries/   [MISSING] Implementation summaries
│   │   ├── debug/       [MISSING] Debug reports (committed)
│   │   └── ...          Other artifact subdirs
│   └── standards/       [COVERED] Shared standards (sync-only)
├── tests/               [MISSING] Test suites
├── tmp/                 [MISSING] Temporary files
├── tts/                 [COVERED] TTS system files
├── build-output.md      [MISSING] Build command output
├── CHANGELOG.md         [MISSING] Change log
├── plan-output.md       [MISSING] Plan command output
├── prompt_example.md    [MISSING] Prompt examples
├── README.md            [MISSING] Project README
├── research-output.md   [MISSING] Research output
├── revise-output.md     [MISSING] Revise output
├── settings.local.json  [COVERED] Local settings (sync-only)
└── TODO.md              [MISSING] Todo list
```

### 2.2 Coverage Analysis

#### Fully Covered (7 directories)
- `agents/` - Visible in picker with preview/edit
- `commands/` - Visible in picker with preview/edit
- `docs/` - Visible in picker with preview/edit
- `hooks/` - Visible in picker with preview/edit
- `lib/` - Visible in picker with preview/edit
- `tts/` - Visible in picker with preview/edit
- `templates/` - Would be visible if directory existed

#### Partially Covered (4 directories)
- `agents/prompts/`, `agents/shared/` - Sync-only, no picker display
- `data/` - Only README files synced, no picker display
- `specs/standards/` - Sync-only, no picker display

#### Missing (9 directories/files)
1. **scripts/** - Standalone CLI tools
2. **tests/** - Test suites
3. **archive/** - Archived artifacts
4. **backups/** - Backup files
5. **tmp/** - Temporary files
6. **specs/{topic}/plans/** - Implementation plans
7. **specs/{topic}/reports/** - Research reports
8. **specs/{topic}/summaries/** - Implementation summaries
9. **specs/{topic}/debug/** - Debug reports
10. **Top-level .md files** - Output files (build-output.md, etc.)

---

## 3. Gap Analysis

### 3.1 Critical Missing Artifacts

#### 3.1.1 Scripts Directory
**Location**: `.claude/scripts/`
**Purpose**: Standalone CLI tools for system operations
**Contents**: Validation, migration, analysis tools
**Examples**: `validate-links.sh`, `detect-empty-topics.sh`

**Impact**: High
- Scripts are operational tools users frequently need
- No way to discover/edit scripts from picker
- Scripts follow kebab-case naming convention

**Recommendation**: Add Scripts category between Lib and Docs

#### 3.1.2 Specs Artifacts
**Location**: `.claude/specs/{NNN_topic}/{artifact_type}/`
**Purpose**: Feature specification artifacts
**Artifact Types**:
- `plans/` - Implementation plans
- `reports/` - Research reports
- `summaries/` - Implementation summaries
- `debug/` - Debug reports (committed to git)

**Impact**: Very High
- Core workflow artifacts for /plan, /research, /build commands
- Plans reference these extensively
- No picker access limits discoverability

**Recommendation**: Add comprehensive Specs section with drill-down navigation

#### 3.1.3 Tests Directory
**Location**: `.claude/tests/`
**Purpose**: Test suites for system validation
**Contents**: Test scripts for commands, libraries, workflows

**Impact**: Medium
- Important for development workflows
- Currently no picker visibility
- Tests are referenced in documentation

**Recommendation**: Add Tests category with test runner integration

#### 3.1.4 Top-Level Output Files
**Files**: `build-output.md`, `plan-output.md`, `research-output.md`, `revise-output.md`
**Purpose**: Command execution outputs and examples
**Usage**: Reference for debugging command issues

**Impact**: Low-Medium
- Useful for troubleshooting
- Not frequently accessed
- Could be grouped under special category

**Recommendation**: Add Output Files category (optional)

#### 3.1.5 Archive/Backups/Tmp Directories
**Locations**: `.claude/archive/`, `.claude/backups/`, `.claude/tmp/`
**Purpose**: Historical/temporary artifact storage
**Usage Pattern**: Infrequent access, cleanup operations

**Impact**: Low
- Rarely need picker access
- More appropriate for file browser
- Could clutter picker interface

**Recommendation**: Exclude from picker, document in help text

### 3.2 Templates Directory Paradox

**Observation**: Picker implements full templates support (Lines 407-464) but:
```bash
$ ls -la /home/benjamin/.config/.claude/templates/ 2>/dev/null
# (no output - directory doesn't exist)
```

**Analysis**:
- Code expects `.claude/templates/*.yaml` for workflow templates
- Directory not present in actual .claude/ structure
- May be legacy feature or planned functionality
- `commands/templates/` exists for plan templates instead

**Recommendation**:
1. Verify if templates/ was deprecated in favor of commands/templates/
2. Update picker to reflect actual structure
3. Document template location conventions

---

## 4. Architectural Issues

### 4.1 Hardcoded Artifact Type Management

**Problem**: Each artifact type requires manual code additions in multiple locations

**Evidence** (Lines 950-962):
```lua
-- Load All preview - must add each type manually
local commands = scan_directory_for_sync(global_dir, project_dir, "commands", "*.md")
local agents = scan_directory_for_sync(global_dir, project_dir, "agents", "*.md")
local hooks = scan_directory_for_sync(global_dir, project_dir, "hooks", "*.sh")
-- ... 10 more similar lines
```

**Impact**:
- Adding new artifact type requires 5+ code locations to be updated
- High risk of inconsistency (preview works but load doesn't, etc.)
- No single source of truth for artifact types

**Locations Requiring Updates**:
1. `create_picker_entries()` - Lines 227-728 (display logic)
2. `create_command_previewer()` - Lines 946-1050 (Load All preview)
3. `load_all_globally()` - Lines 1582-1614 (sync scanning)
4. `load_all_with_strategy()` - Lines 1518-1547 (directory creation)
5. Help text - Lines 907-940 (keyboard shortcuts documentation)

### 4.2 Monolithic File Size

**Current**: 3,385 lines in single file
**Concerns**:
- Difficult to navigate and maintain
- Test isolation challenges
- Multiple responsibilities in one module

**Breakdown**:
- Entry creation: ~500 lines
- Previewer: ~490 lines
- Load operations: ~800 lines
- Helper functions: ~600 lines
- Main picker: ~500 lines
- Utility functions: ~500 lines

**Recommendation**: Modularize into focused modules

### 4.3 Inconsistent Artifact Metadata

**Issue**: Some artifacts have rich metadata, others minimal

**Comparison**:
| Artifact | Name | Description | Filepath | Variables | Line Count | Role |
|----------|------|-------------|----------|-----------|------------|------|
| Command | Yes | Yes | Yes | - | - | - |
| Agent | Yes | Yes | Yes | - | - | - |
| TTS File | Yes | Yes | Yes | Yes | Yes | Yes |
| Lib | Yes | Parsed | Yes | - | - | - |
| Doc | Yes | Parsed | Yes | - | - | - |
| Template | Yes | Parsed | Yes | - | - | - |

**Problem**: TTS files get special treatment while other artifacts lack rich metadata

**Recommendation**: Standardize metadata extraction across all types

### 4.4 No Plugin System for Artifact Types

**Current**: All artifact types hardcoded
**Desired**: Plugin-based artifact registration

**Ideal Pattern**:
```lua
-- artifact-registry.lua
local registry = {
  commands = {
    pattern = "*.md",
    location = "commands",
    preview = true,
    edit = true,
    sync = true,
    category = "primary"
  },
  -- ... other types
}
```

**Benefits**:
- Add new artifact types without modifying core picker
- Third-party artifact type extensions
- Easier testing and maintenance
- Single source of truth

---

## 5. Proposed Refactor Design

### 5.1 Modular Architecture

**Goal**: Separate concerns into focused modules following nvim standards

**Proposed Structure**:
```
lua/neotex/plugins/ai/claude/commands/
├── picker.lua              [500 lines] Main picker orchestration
├── picker/
│   ├── init.lua            Entry point, exports
│   ├── artifacts/
│   │   ├── registry.lua    Artifact type definitions
│   │   ├── commands.lua    Command-specific logic
│   │   ├── agents.lua      Agent-specific logic
│   │   ├── specs.lua       Specs artifact logic
│   │   └── ...             Other artifact modules
│   ├── display/
│   │   ├── entries.lua     Entry creation
│   │   ├── previewer.lua   Preview system
│   │   └── formatters.lua  Display formatting
│   ├── operations/
│   │   ├── sync.lua        Load/save operations
│   │   ├── edit.lua        File editing
│   │   └── terminal.lua    Terminal integration
│   └── utils/
│       ├── scan.lua        Directory scanning
│       ├── metadata.lua    Metadata extraction
│       └── helpers.lua     Common utilities
└── parser.lua              [Keep existing]
```

**Module Size Guidelines** (per nvim CLAUDE.md):
- Target: ~100-200 lines per module
- Maximum: 300 lines
- Current picker.lua: 3,385 lines → Split into ~15-20 modules

### 5.2 Artifact Registry System

**File**: `picker/artifacts/registry.lua`

**Design**:
```lua
local M = {}

-- Artifact type definition
local ArtifactType = {
  id = "",              -- Unique identifier
  category = "",        -- Category for grouping
  pattern = "",         -- File pattern (*.md, *.sh, etc.)
  locations = {},       -- Array of directory paths
  display_name = "",    -- Human-readable name
  description = "",     -- Category description

  -- Feature flags
  picker_visible = true,    -- Show in picker
  preview_enabled = true,   -- Enable preview
  edit_enabled = true,      -- Enable editing
  sync_enabled = true,      -- Include in Load All

  -- Metadata extraction
  parse_description = nil,  -- function(filepath) -> string
  parse_metadata = nil,     -- function(filepath) -> table

  -- Display customization
  tree_indent = 1,          -- Indent spaces (1 or 2)
  format_entry = nil,       -- function(entry) -> string
  format_preview = nil,     -- function(entry) -> table

  -- Operations
  on_select = nil,          -- function(entry) - Default: edit
  on_load = nil,            -- function(filepath) -> boolean
  on_save = nil,            -- function(filepath) -> boolean
}

-- Registry of all artifact types
M.types = {
  commands = {
    id = "commands",
    category = "primary",
    pattern = "*.md",
    locations = { "commands" },
    display_name = "[Commands]",
    description = "Claude Code slash commands",
    picker_visible = true,
    -- ... rest of config
  },

  specs_plans = {
    id = "specs_plans",
    category = "specs",
    pattern = "*.md",
    locations = { "specs/*/plans" },  -- Glob pattern
    display_name = "[Plans]",
    description = "Implementation plans",
    picker_visible = true,
    tree_indent = 1,
    -- Custom metadata extraction for plans
    parse_metadata = function(filepath)
      -- Extract plan metadata: phases, complexity, etc.
    end,
  },

  -- ... all other types
}

-- Category ordering for display
M.categories = {
  "primary",    -- Commands, Agents, Hooks, TTS
  "specs",      -- Plans, Reports, Summaries
  "libraries",  -- Lib, Templates
  "docs",       -- Docs, Scripts
  "special",    -- Help, Load All
}

return M
```

**Benefits**:
1. Single source of truth for artifact types
2. Easy to add new types
3. Consistent metadata handling
4. Testable in isolation

### 5.3 Adding Missing Artifact Types

#### Phase 1: Add Scripts Category
**Priority**: High
**Complexity**: Low

**Changes**:
1. Add to registry:
```lua
scripts = {
  id = "scripts",
  category = "docs",
  pattern = "*.sh",
  locations = { "scripts" },
  display_name = "[Scripts]",
  description = "Standalone CLI tools",
  picker_visible = true,
  tree_indent = 1,
  parse_description = parse_script_description,  -- Reuse existing
}
```

2. Update Load All to include scripts/
3. Add script-specific actions (run with arguments?)

#### Phase 2: Add Specs Artifacts
**Priority**: Very High
**Complexity**: High

**Challenges**:
- Specs organized by topic directories (`specs/{NNN_topic}/`)
- Need drill-down navigation (topic → artifact type → file)
- Large number of files (72 topic directories observed)
- Different artifact types per topic

**Design Option A: Flat List with Filtering**
```
[Plans]
  ├─ 001_state_machine_persistence_fix_plan.md (topic: 787)
  ├─ 001_docs_standards_fix_plan.md (topic: 789)
  └─ ... (all plans from all topics)
```
- Pros: Simple, shows all plans
- Cons: Overwhelming (100+ plans), no topic context

**Design Option B: Topic Drill-Down**
```
[Specs Topics]
  ├─ 787_state_machine_persistence_bug
  ├─ 788_commands_readme_update
  └─ 789_docs_standards_fix

[On selection: Show topic's artifacts]
Plans (2):
  ├─ 001_state_persistence_fix_plan.md
  └─ 001_state_persistence_bug_analysis.md (report)
```
- Pros: Organized by context, manageable
- Cons: Requires 2-level navigation

**Design Option C: Recent Specs + Search**
```
[Recent Plans] (last 10 modified)
  ├─ 001_artifact_management_plan.md (859)
  ├─ 001_buffer_opening_plan.md (851)
  └─ ...

[Search All Plans] (special entry, opens fuzzy finder)
```
- Pros: Quick access to recent, searchable for old
- Cons: Need separate search implementation

**Recommendation**: Phase 2A (Option A) for MVP, Phase 2B (Option B) for v2

#### Phase 3: Add Tests Category
**Priority**: Medium
**Complexity**: Low

**Similar to Scripts**:
```lua
tests = {
  id = "tests",
  category = "docs",
  pattern = "test_*.sh",
  locations = { "tests" },
  display_name = "[Tests]",
  description = "Test suites",
  picker_visible = true,
  -- Special action: run test with <C-r>
  on_run = function(filepath)
    vim.cmd("!bash " .. filepath)
  end,
}
```

#### Phase 4: Add Output Files (Optional)
**Priority**: Low
**Complexity**: Low

**Pattern**:
```lua
outputs = {
  id = "outputs",
  category = "special",
  pattern = "*-output.md",
  locations = { "" },  -- Root .claude/
  display_name = "[Outputs]",
  description = "Command execution outputs",
  picker_visible = true,
  tree_indent = 1,
}
```

### 5.4 Enhanced Load All Artifacts

**Current Issues**:
1. Hardcoded artifact list
2. Manual directory creation
3. No validation of sync success
4. Limited conflict resolution

**Proposed Improvements**:

#### Registry-Driven Sync
```lua
function load_all_globally()
  local registry = require("picker.artifacts.registry")

  -- Scan all sync-enabled artifact types
  local sync_plan = {}
  for _, artifact_type in pairs(registry.types) do
    if artifact_type.sync_enabled then
      local files = scan_artifact_type(artifact_type)
      sync_plan[artifact_type.id] = files
    end
  end

  -- Execute sync with validation
  local results = execute_sync(sync_plan)
  report_sync_results(results)
end
```

#### Enhanced Conflict Resolution
- **Current**: Replace all vs Add new only
- **Proposed**:
  - Option 1: Replace all + add new
  - Option 2: Add new only
  - Option 3: Interactive (pick per file)
  - Option 4: Preview diff (show changes before applying)

#### Sync Validation
- Verify file integrity after copy
- Check executable permissions preserved
- Validate metadata extraction works
- Report failed syncs separately

### 5.5 Backward Compatibility

**Requirements**:
1. Existing keybindings must work (<leader>ac)
2. API stability for external callers
3. No breaking changes to user workflows

**Strategy**:
1. Keep `picker.lua` as facade/compatibility layer
2. Delegate to new modular implementation
3. Add deprecation warnings for removed features
4. Provide migration guide in README

**Compatibility Layer**:
```lua
-- picker.lua (new)
local new_picker = require("neotex.plugins.ai.claude.commands.picker.init")

-- Maintain backward compatibility
local M = {}

M.show_commands_picker = function(opts)
  -- Delegate to new implementation
  return new_picker.show(opts)
end

-- Deprecated: Will be removed in v3.0
M.load_command_locally = function(...)
  vim.notify("Deprecated: Use operations.load() instead", vim.log.levels.WARN)
  return new_picker.operations.load(...)
end

return M
```

---

## 6. Implementation Plan

### Phase 1: Foundation (Complexity 2)
**Goal**: Establish modular architecture without changing functionality

**Tasks**:
1. Create `picker/` directory structure
2. Extract artifact registry from hardcoded logic
3. Move helper functions to utils/
4. Update imports, maintain backward compatibility
5. Add comprehensive tests

**Deliverables**:
- `picker/artifacts/registry.lua` - Artifact type definitions
- `picker/utils/scan.lua` - Directory scanning utilities
- `picker/utils/metadata.lua` - Metadata extraction
- Updated tests with 80%+ coverage

**Validation**:
- All existing functionality works identically
- No user-facing changes
- Performance within 5% of original

### Phase 2: Add Missing Primary Artifacts (Complexity 2)
**Goal**: Add Scripts, Tests, and top-level outputs

**Tasks**:
1. Add Scripts artifact type to registry
2. Add Tests artifact type to registry
3. Add Outputs artifact type to registry (optional)
4. Update Load All to include new types
5. Add preview/edit support
6. Update help documentation

**Deliverables**:
- 3 new artifact categories in picker
- Load All syncs scripts/ and tests/
- README documentation updated

**Validation**:
- Scripts visible in picker with edit/preview
- Tests visible with run action (<C-r>)
- Load All syncs successfully

### Phase 3: Add Specs Artifacts (Complexity 3)
**Goal**: Comprehensive specs/ directory coverage

**Tasks**:
1. Design topic navigation (flat vs drill-down)
2. Add Plans artifact type
3. Add Reports artifact type
4. Add Summaries artifact type
5. Add Debug artifact type (read-only, committed)
6. Implement search/filter for large lists
7. Add topic metadata extraction

**Deliverables**:
- 4 new specs artifact categories
- Topic-aware navigation (if drill-down chosen)
- Search functionality for finding old artifacts
- Load All optionally syncs specs/standards/

**Validation**:
- Can browse all plans across topics
- Can preview plan metadata (phases, complexity)
- Can edit specs artifacts
- Search finds artifacts by name/content

### Phase 4: Enhanced Operations (Complexity 2)
**Goal**: Improve Load All and sync operations

**Tasks**:
1. Implement registry-driven sync
2. Add interactive conflict resolution
3. Add diff preview before sync
4. Add sync validation and error reporting
5. Add selective sync (choose which types to sync)

**Deliverables**:
- Enhanced Load All with preview
- Per-file conflict resolution option
- Sync success/failure reporting
- Selective sync UI

**Validation**:
- Conflicts handled gracefully
- Failed syncs reported clearly
- Can preview changes before applying

### Phase 5: Polish & Documentation (Complexity 1)
**Goal**: Production-ready release

**Tasks**:
1. Comprehensive README update
2. Migration guide from monolithic to modular
3. Architecture documentation
4. Performance optimization
5. User guide with screenshots
6. Video walkthrough (optional)

**Deliverables**:
- Complete module documentation
- User guide with examples
- Migration guide
- Performance benchmarks

**Validation**:
- Documentation complete and accurate
- Migration path clear
- Performance acceptable

---

## 7. Conformance to Nvim Standards

### 7.1 Code Standards Compliance

**From**: `/home/benjamin/.config/nvim/CLAUDE.md`

#### Lua Code Style
| Standard | Current Status | Proposed |
|----------|----------------|----------|
| Indentation: 2 spaces | Compliant | Maintain |
| Line length: ~100 chars | Mostly compliant (some 120+) | Enforce in refactor |
| Imports at top | Compliant | Maintain |
| Module structure | Single file, needs splitting | Fix in Phase 1 |
| Local functions | Compliant | Maintain |
| Error handling with pcall | Compliant | Maintain |
| Descriptive naming | Compliant | Maintain |

#### Project Organization
- Core in `lua/neotex/core/` - N/A (plugin code)
- Plugins in `lua/neotex/plugins/` - **Compliant**
- Deprecated in `lua/neotex/deprecated/` - N/A

### 7.2 Documentation Standards

**Required**: README.md in each subdirectory

**Current**:
- `commands/README.md` exists (100 lines)
- Documents picker.lua and parser.lua

**Proposed Updates**:
```
commands/
├── README.md              [UPDATE] Add new modules
├── picker/
│   ├── README.md          [NEW] Picker module overview
│   ├── artifacts/
│   │   └── README.md      [NEW] Registry system docs
│   ├── display/
│   │   └── README.md      [NEW] Display logic docs
│   ├── operations/
│   │   └── README.md      [NEW] Operations docs
│   └── utils/
│       └── README.md      [NEW] Utilities docs
```

**Content Requirements** (per nvim CLAUDE.md):
- Purpose: Clear explanation of directory role
- Module Documentation: Each file/module documented
- Usage Examples: Code examples
- Navigation Links: Parent/subdirectory links

### 7.3 Testing Protocols

**From nvim CLAUDE.md**:
- Test files: `*_spec.lua`, `test_*.lua`
- Location: `tests/` or adjacent to source
- Framework: Busted, plenary.nvim
- All new modules must have test coverage

**Current Testing**: None observed for picker.lua

**Proposed**:
```
commands/
└── picker/
    ├── artifacts/
    │   ├── registry.lua
    │   └── registry_spec.lua        [NEW]
    ├── display/
    │   ├── entries.lua
    │   └── entries_spec.lua         [NEW]
    └── utils/
        ├── scan.lua
        └── scan_spec.lua            [NEW]
```

**Target Coverage**: 80%+ for new modules

### 7.4 Character Encoding Standards

**From nvim CLAUDE.md**: NO EMOJIS in file content

**Current**: Compliant (no emojis in picker.lua)
**Runtime UI**: Emojis allowed in picker display/notifications
**Files**: No emojis in synced artifacts

**Maintain**: Continue emoji-free approach

---

## 8. Risk Assessment

### 8.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking backward compatibility | Medium | High | Maintain compatibility layer, extensive testing |
| Performance degradation | Low | Medium | Benchmark before/after, optimize registry lookups |
| Incomplete artifact coverage | Low | Low | Registry-driven ensures consistency |
| Testing gaps | Medium | Medium | 80% coverage requirement, CI/CD integration |
| Module coupling | Low | Medium | Clear interfaces, dependency injection |

### 8.2 User Impact

| Change | Impact | Communication |
|--------|--------|---------------|
| Modular file structure | None (transparent) | Document in migration guide |
| New artifact types | Positive | Highlight in release notes |
| Keybinding changes | None (maintained) | N/A |
| Performance changes | Minimal | Benchmark in docs |
| Load All changes | Enhanced UX | Document new options |

### 8.3 Maintenance Burden

**Current**: 3,385-line monolith
- Difficult to modify
- Risky to add features
- Testing challenges

**Proposed**: 15-20 focused modules
- Each module <300 lines
- Clear responsibilities
- Unit testable
- Easier onboarding

**Long-term**: Reduced maintenance burden, easier feature additions

---

## 9. Success Metrics

### 9.1 Functional Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Artifact types covered | 11 | 16+ |
| Picker-visible types | 7 | 12+ |
| Module count | 1 | 15-20 |
| Avg module size | 3385 lines | <250 lines |
| Test coverage | 0% | 80%+ |
| Load All artifact types | 11 | 15+ |

### 9.2 Quality Metrics

| Metric | Target |
|--------|--------|
| Backward compatibility | 100% |
| Documentation coverage | 100% (all modules) |
| User-facing bugs | 0 critical, <3 minor |
| Performance variance | ±5% of baseline |
| Code review approval | 2+ reviewers |

### 9.3 User Experience Metrics

| Metric | Target |
|--------|--------|
| Time to find artifact | <5 seconds |
| Sync success rate | >99% |
| Preview load time | <500ms |
| Picker responsiveness | No lag |
| User satisfaction | Positive feedback |

---

## 10. Recommendations

### 10.1 Immediate Actions (This Sprint)

1. **Create Phase 1 Plan** (Complexity 2)
   - Detail modularization tasks
   - Define module boundaries
   - Create test plan

2. **Prototype Registry System**
   - Validate artifact type abstraction
   - Test with 3-4 artifact types
   - Measure performance impact

3. **Add Scripts Category** (Quick Win)
   - Low complexity, high value
   - Demonstrates extensibility
   - Builds momentum

### 10.2 Medium-Term (Next 2-3 Sprints)

1. **Complete Phase 1-2** (Modularization + Primary Artifacts)
2. **Design Specs Navigation** (User research for Option A vs B vs C)
3. **Implement Phase 3** (Specs artifacts)
4. **Release v2.0** with new artifact types

### 10.3 Long-Term (6+ months)

1. **Plugin System** for third-party artifact types
2. **Advanced Search** with fuzzy finding, content search
3. **Artifact Analytics** (most used, last modified, etc.)
4. **Integration with other tools** (fzf, telescope extensions)
5. **Cloud sync** for artifacts across machines (optional)

### 10.4 Design Decisions Required

1. **Specs Navigation Pattern**: Flat list vs Drill-down vs Recent+Search
   - Recommendation: Start with Flat (Phase 2A), add drill-down later

2. **Module Naming Convention**: Use existing or create new
   - Recommendation: Follow neotex.plugins.ai.claude.* pattern

3. **Test Framework**: Busted vs plenary.nvim
   - Recommendation: plenary.nvim (already used in neovim)

4. **Registry Location**: Lua table vs JSON config
   - Recommendation: Lua table (type safety, better performance)

5. **Templates Directory**: Fix or document
   - Recommendation: Document as deprecated, use commands/templates/

---

## 11. Conclusion

The `<leader>ac` command (Claude artifacts picker) provides comprehensive coverage of curated .claude/ artifacts but lacks support for several critical directories (scripts/, tests/, specs/) and needs architectural improvements for maintainability and extensibility.

**Key Achievements**:
- 11 artifact types well-supported
- Sophisticated hierarchical display
- Robust Load All functionality
- Strong user experience foundation

**Critical Gaps**:
- Missing 5 important artifact types
- Monolithic architecture (3,385 lines)
- Hardcoded artifact management
- No test coverage
- Templates directory paradox

**Path Forward**:
The proposed 5-phase refactor addresses all gaps while maintaining backward compatibility and conforming to nvim standards. The modular architecture enables easy addition of new artifact types and positions the picker for long-term maintainability.

**Estimated Effort**:
- Phase 1 (Foundation): 2-3 days (Complexity 2)
- Phase 2 (Primary Artifacts): 1-2 days (Complexity 2)
- Phase 3 (Specs): 3-4 days (Complexity 3)
- Phase 4 (Enhanced Ops): 2-3 days (Complexity 2)
- Phase 5 (Polish): 1-2 days (Complexity 1)
- **Total**: 9-14 days across 5 sprints

**Next Steps**:
1. Review and approve design decisions
2. Create detailed implementation plan for Phase 1
3. Prototype registry system
4. Begin modularization refactor

---

## Appendix A: Artifact Type Registry Schema

```lua
-- Complete schema for artifact type definition
ArtifactType = {
  -- Identity
  id = string,                    -- Unique identifier (e.g., "commands")
  category = string,              -- Category for grouping ("primary", "specs", etc.)

  -- Discovery
  pattern = string,               -- File pattern (e.g., "*.md", "*.sh")
  locations = table,              -- Array of directory paths (supports globs)
  exclude_patterns = table,       -- Optional: patterns to exclude

  -- Display
  display_name = string,          -- Heading text (e.g., "[Commands]")
  description = string,           -- Category description
  picker_visible = boolean,       -- Show in picker (default: true)
  tree_indent = number,           -- Indent spaces (1 or 2)
  icon = string,                  -- Optional: icon character

  -- Features
  preview_enabled = boolean,      -- Enable preview (default: true)
  edit_enabled = boolean,         -- Enable editing (default: true)
  sync_enabled = boolean,         -- Include in Load All (default: true)

  -- Metadata
  parse_description = function,   -- (filepath) -> description string
  parse_metadata = function,      -- (filepath) -> metadata table
  validate_file = function,       -- (filepath) -> boolean, error

  -- Display Formatting
  format_entry = function,        -- (entry) -> display string
  format_preview = function,      -- (entry, bufnr) -> nil (sets buffer content)

  -- Operations
  on_select = function,           -- (entry) -> nil (default: edit)
  on_edit = function,             -- (entry) -> nil
  on_load = function,             -- (filepath) -> success boolean
  on_save = function,             -- (filepath) -> success boolean
  on_delete = function,           -- (filepath) -> success boolean

  -- Sync
  sync_options = table,           -- { preserve_perms = true, etc. }
  conflict_strategy = string,     -- "replace", "merge", "ask"

  -- Keybindings
  custom_keymaps = table,         -- { { key = "<C-x>", action = fn } }
}
```

## Appendix B: Current Artifact Type Definitions

Extracted from picker.lua for reference:

```lua
commands = {
  id = "commands",
  pattern = "*.md",
  locations = { "commands" },
  display_name = "[Commands]",
  description = "Claude Code slash commands",
  tree_indent = 1,
  on_select = send_command_to_terminal,
}

agents = {
  id = "agents",
  pattern = "*.md",
  locations = { "agents" },
  display_name = "[Agents]",
  description = "Standalone AI agents",
  tree_indent = 1,
}

hook_events = {
  id = "hook_events",
  pattern = "*.sh",
  locations = { "hooks" },
  display_name = "[Hook Events]",
  description = "Event-triggered scripts",
  tree_indent = 2,
  format_entry = format_hook_event,
}

tts_files = {
  id = "tts_files",
  pattern = "*.sh",
  locations = { "hooks/tts-*.sh", "tts" },
  display_name = "[TTS Files]",
  description = "Text-to-speech system files",
  tree_indent = 1,
  parse_metadata = parse_tts_metadata,
}

templates = {
  id = "templates",
  pattern = "*.yaml",
  locations = { "templates" },
  display_name = "[Templates]",
  description = "Workflow templates",
  tree_indent = 1,
  parse_description = parse_template_description,
}

lib = {
  id = "lib",
  pattern = "*.sh",
  locations = { "lib" },
  display_name = "[Lib]",
  description = "Utility libraries",
  tree_indent = 1,
  parse_description = parse_script_description,
}

docs = {
  id = "docs",
  pattern = "*.md",
  locations = { "docs" },
  display_name = "[Docs]",
  description = "Integration guides",
  tree_indent = 1,
  parse_description = parse_doc_description,
}
```

## Appendix C: Missing Artifact Type Definitions

Proposed definitions for missing types:

```lua
scripts = {
  id = "scripts",
  category = "tools",
  pattern = "*.sh",
  locations = { "scripts" },
  display_name = "[Scripts]",
  description = "Standalone CLI tools",
  tree_indent = 1,
  parse_description = parse_script_description,
  on_select = function(entry)
    -- Option: Run script or edit?
    -- Default: Edit (consistent with lib)
    edit_artifact_file(entry.filepath)
  end,
  custom_keymaps = {
    { key = "<C-r>", action = run_script_with_args },
  },
}

tests = {
  id = "tests",
  category = "tools",
  pattern = "test_*.sh",
  locations = { "tests" },
  display_name = "[Tests]",
  description = "Test suites",
  tree_indent = 1,
  parse_description = parse_script_description,
  on_select = edit_artifact_file,
  custom_keymaps = {
    { key = "<C-t>", action = run_test },
  },
}

specs_plans = {
  id = "specs_plans",
  category = "specs",
  pattern = "*.md",
  locations = { "specs/*/plans" },
  display_name = "[Plans]",
  description = "Implementation plans",
  tree_indent = 1,
  parse_metadata = extract_plan_metadata,
  format_entry = format_plan_entry,  -- Include topic number
  format_preview = format_plan_preview,  -- Show phases, complexity
}

specs_reports = {
  id = "specs_reports",
  category = "specs",
  pattern = "*.md",
  locations = { "specs/*/reports" },
  display_name = "[Reports]",
  description = "Research reports",
  tree_indent = 1,
  parse_metadata = extract_report_metadata,
}

specs_summaries = {
  id = "specs_summaries",
  category = "specs",
  pattern = "*.md",
  locations = { "specs/*/summaries" },
  display_name = "[Summaries]",
  description = "Implementation summaries",
  tree_indent = 1,
}

specs_debug = {
  id = "specs_debug",
  category = "specs",
  pattern = "*.md",
  locations = { "specs/*/debug" },
  display_name = "[Debug Reports]",
  description = "Debug reports (committed)",
  tree_indent = 1,
  edit_enabled = false,  -- Read-only (committed to git)
  sync_enabled = false,  -- Don't sync debug reports
}

outputs = {
  id = "outputs",
  category = "special",
  pattern = "*-output.md",
  locations = { "" },
  exclude_patterns = { "specs/*" },
  display_name = "[Outputs]",
  description = "Command execution outputs",
  tree_indent = 1,
  edit_enabled = false,  -- Read-only reference
}
```

---

## Implementation Status

- **Status**: Planning In Progress
- **Plan**: [../plans/001_leaderac_command_nvim_order_check_that_t_plan.md](../plans/001_leaderac_command_nvim_order_check_that_t_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-20

---

**Report Generated**: 2025-11-20
**Researcher**: Claude (Sonnet 4.5)
**Complexity Level**: 3
**Estimated Read Time**: 45 minutes

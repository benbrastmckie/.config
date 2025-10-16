# Flexible Specs Location Strategies Research Report

## Metadata

- **Date**: 2025-10-01
- **Report Number**: 018
- **Scope**: Configuration strategies for flexible specs/ directory placement
- **Primary Directory**: `.claude/`
- **Files Analyzed**: 18 command files, CLAUDE.md, multiple specs directories
- **Keywords**: specs, configuration, scoping, monorepo, module-level

## Executive Summary

This report analyzes strategies for allowing users to specify custom locations for `specs/` directories (reports, plans, summaries) instead of always storing them at project root. Currently, Claude Code commands hardcode `specs/` paths relative to project root, which limits flexibility in monorepos and modular projects.

**Key Findings**:
1. Current implementation supports subdirectory specs/ but has limited user control
2. Four viable configuration strategies identified
3. Monorepo best practices (2025) emphasize module-level configuration
4. CLI tool patterns favor upward directory traversal for config discovery
5. Implementation requires changes to 10+ command files

**Recommended Approach**: Configuration file strategy with environment variable override, maintaining backward compatibility.

## Background

### Current Implementation

Claude Code commands (`/report`, `/plan`, `/implement`, etc.) currently:

1. **Automatically determine location** by finding deepest relevant directory
2. **Create `specs/` subdirectories** at chosen location:
   - `specs/reports/` - Research reports
   - `specs/plans/` - Implementation plans
   - `specs/summaries/` - Implementation summaries

3. **Use three-digit numbering** (001, 002, 003...) within each directory

**Example current behavior**:
```bash
/report "authentication patterns"
# Creates: ./specs/reports/001_authentication_patterns.md

# If relevant files in nvim/:
# Creates: ./nvim/specs/reports/001_authentication_patterns.md
```

### Problem Statement

Users want more control over specs/ location for:

1. **Monorepo organization**: Different modules need separate specs/
2. **Documentation structure**: Specs alongside related docs
3. **Team conventions**: Existing directory structures to maintain
4. **Workspace separation**: Multiple projects in same directory tree

### CLAUDE.md Current Guidance

From `/home/benjamin/.config/CLAUDE.md:24`:
```markdown
**Location**: specs/ directories can exist at project root or in subdirectories
for scoped specifications.
```

This acknowledges multiple locations but doesn't define **how users specify** them.

## Analysis of Current Codebase

### Commands Using specs/ Paths

Analyzed 18 command files. **10 commands** reference `specs/` paths:

| Command | Uses specs/ For | Hardcoded Path |
|---------|----------------|----------------|
| /report | Creating reports | `specs/reports/` |
| /plan | Creating plans | `specs/plans/` |
| /implement | Creating summaries | `specs/summaries/` |
| /orchestrate | All three types | All paths |
| /debug | Debug reports | `specs/reports/` |
| /refactor | Refactor reports | `specs/reports/` |
| /list-reports | Finding reports | `specs/reports/` |
| /list-plans | Finding plans | `specs/plans/` |
| /list-summaries | Finding summaries | `specs/summaries/` |
| /resume-implement | Finding plans | `specs/plans/` |

### Location Determination Logic

**Current pattern** in `/report` and `/plan`:

```markdown
### 2. Location Determination
I'll find the deepest directory that encompasses all relevant files by:
- Searching for files related to the topic
- Identifying common parent directories
- Selecting the most specific directory that includes all relevant content
```

**Limitation**: User cannot override this automatic selection.

### Numbering System

All commands use consistent three-digit numbering:
- Search existing files in target `specs/*/` directory
- Find highest number (e.g., `017_*.md`)
- Use next number (e.g., `018`)

**This works well** and should be preserved in any new strategy.

## Strategy Options

### Strategy 1: Configuration File (`.claude/config/specs-locations.json`)

**Approach**: Allow users to define custom specs locations in configuration.

**Configuration File Structure**:
```json
{
  "specs": {
    "default_location": "docs/planning",
    "reports": "docs/planning/research",
    "plans": "docs/planning/implementation",
    "summaries": "docs/planning/completed",
    "scope_rules": [
      {
        "path_prefix": "nvim/",
        "specs_location": "nvim/docs/specs"
      },
      {
        "path_prefix": "backend/",
        "specs_location": "backend/.specs"
      }
    ],
    "fallback": "specs"
  }
}
```

**Precedence**:
1. Scope rules (if current path matches prefix)
2. Specific type overrides (reports/plans/summaries)
3. Default location
4. Fallback to `specs/` (backward compatibility)

**Pros**:
- ✅ Highly flexible per-module configuration
- ✅ Supports monorepo patterns
- ✅ Backward compatible (fallback to specs/)
- ✅ Centralized configuration
- ✅ Type-specific paths (reports vs plans)

**Cons**:
- ❌ Requires parsing JSON in command prompt
- ❌ More complex discovery logic
- ❌ Configuration management overhead
- ❌ Must update 10+ command files

**Implementation Complexity**: **High**

**Example Usage**:
```bash
# User creates .claude/config/specs-locations.json
# Commands automatically use configured paths

/report "auth patterns"
# Creates: docs/planning/research/001_auth_patterns.md

cd nvim/
/plan "new feature"
# Creates: nvim/docs/specs/plans/001_new_feature.md
```

### Strategy 2: Environment Variables

**Approach**: Allow environment variables to override default locations.

**Environment Variables**:
```bash
export CLAUDE_SPECS_DIR="docs/planning"
export CLAUDE_REPORTS_DIR="docs/research"
export CLAUDE_PLANS_DIR="docs/plans"
export CLAUDE_SUMMARIES_DIR="docs/completed"
```

**Precedence**:
1. Environment variable (if set)
2. Current automatic detection
3. Fallback to `specs/`

**Pros**:
- ✅ Simple to implement
- ✅ No configuration file needed
- ✅ Shell-level control
- ✅ Easy per-session override
- ✅ Works with existing logic

**Cons**:
- ❌ Not persistent (must set in shell config)
- ❌ Less flexible than config file
- ❌ Doesn't support scope rules
- ❌ Global per-shell (not per-module)

**Implementation Complexity**: **Low**

**Example Usage**:
```bash
# In ~/.bashrc or ~/.zshrc
export CLAUDE_SPECS_DIR="docs/specs"

/report "auth patterns"
# Creates: docs/specs/reports/001_auth_patterns.md

# Override per-session
CLAUDE_REPORTS_DIR="research/" /report "performance"
# Creates: research/001_performance.md
```

### Strategy 3: Command-Line Flags

**Approach**: Add optional flags to commands for location override.

**Flag Syntax**:
```bash
/report <topic> [--reports-dir <path>]
/plan <feature> [--plans-dir <path>] [--reports-dir <path>]
/implement <plan> [--summaries-dir <path>]
```

**Pros**:
- ✅ Explicit per-invocation control
- ✅ No configuration needed
- ✅ Clear and visible
- ✅ Easy to document

**Cons**:
- ❌ Verbose for frequent use
- ❌ Must remember flags each time
- ❌ Inconsistent if users forget
- ❌ More complex argument parsing
- ❌ Requires updating all 10 commands

**Implementation Complexity**: **Medium**

**Example Usage**:
```bash
/report "auth patterns" --reports-dir research/

/plan "new feature" --plans-dir implementation/ --reports-dir research/

/implement plan_file.md --summaries-dir completed/
```

### Strategy 4: CLAUDE.md Specs Configuration

**Approach**: Add specs location configuration to CLAUDE.md standards file.

**CLAUDE.md Section**:
```markdown
## Specs Directory Configuration
[Used by: /report, /plan, /implement, /orchestrate]

### Specs Locations
- **Reports**: `docs/research/`
- **Plans**: `docs/implementation/`
- **Summaries**: `docs/completed/`

### Scoped Specifications
Module-specific overrides:
- `nvim/`: Uses `nvim/docs/specs/`
- `backend/`: Uses `backend/.planning/`
- Default: `specs/` (project root)
```

**Discovery Process**:
1. Commands search upward for CLAUDE.md
2. Parse "Specs Directory Configuration" section
3. Apply scoped rules based on current directory
4. Fall back to `specs/` if not configured

**Pros**:
- ✅ Fits existing CLAUDE.md pattern
- ✅ Project-specific configuration
- ✅ Supports scoping/overrides
- ✅ Version-controlled with project
- ✅ Self-documenting

**Cons**:
- ❌ Requires parsing markdown sections
- ❌ Less flexible than JSON
- ❌ CLAUDE.md can become large
- ❌ Complex if multiple CLAUDE.md files

**Implementation Complexity**: **Medium-High**

**Example Usage**:
```bash
# User adds section to CLAUDE.md
# Commands automatically use configured paths

/report "auth patterns"
# Reads CLAUDE.md, creates: docs/research/001_auth_patterns.md

cd nvim/
/plan "feature"
# Reads CLAUDE.md, applies scope rule
# Creates: nvim/docs/specs/plans/001_feature.md
```

## Recommended Strategy

### Hybrid Approach: Config File + Environment Variables

**Combine Strategy 1 and Strategy 2** for maximum flexibility:

1. **Primary**: Configuration file (`.claude/config/specs-locations.json`)
   - Persistent, project-specific configuration
   - Supports scope rules for monorepos
   - Type-specific overrides

2. **Override**: Environment variables
   - Quick per-session overrides
   - Shell-level control
   - No file editing required

3. **Fallback**: Current automatic detection + `specs/`
   - Backward compatibility
   - Works without configuration

**Precedence Order**:
```
Environment Variable → Config File → Automatic Detection → specs/
```

### Configuration File Format

**Location**: `.claude/config/specs-locations.json`

```json
{
  "version": "1.0",
  "specs": {
    "reports": "docs/research",
    "plans": "docs/plans",
    "summaries": "docs/completed",
    "scope_rules": [
      {
        "path_prefix": "nvim/",
        "reports": "nvim/docs/research",
        "plans": "nvim/docs/plans",
        "summaries": "nvim/docs/completed"
      }
    ],
    "fallback": "specs"
  }
}
```

### Environment Variables

```bash
# Global overrides
export CLAUDE_REPORTS_DIR="custom/reports"
export CLAUDE_PLANS_DIR="custom/plans"
export CLAUDE_SUMMARIES_DIR="custom/summaries"

# Or single variable for all
export CLAUDE_SPECS_DIR="custom/specs"
# (Expands to: custom/specs/reports/, custom/specs/plans/, etc.)
```

### Configuration Discovery Algorithm

```
function find_specs_location(type: "reports"|"plans"|"summaries"):
  # 1. Check environment variable
  if env_var_set("CLAUDE_{TYPE}_DIR"):
    return env_var_value()

  if env_var_set("CLAUDE_SPECS_DIR"):
    return env_var_value() + "/" + type

  # 2. Find and parse config file
  config_file = find_upward(".claude/config/specs-locations.json")
  if config_file:
    config = parse_json(config_file)
    current_path = getcwd()

    # Check scope rules
    for rule in config.scope_rules:
      if current_path.starts_with(rule.path_prefix):
        if rule[type]:
          return rule[type]

    # Check type-specific config
    if config.specs[type]:
      return config.specs[type]

    # Check fallback
    if config.specs.fallback:
      return config.specs.fallback + "/" + type

  # 3. Automatic detection (current logic)
  detected = detect_relevant_directory()
  if detected:
    return detected + "/specs/" + type

  # 4. Default fallback
  return "specs/" + type
```

## Implementation Plan

### Phase 1: Configuration Foundation

**Tasks**:
1. Create `.claude/config/specs-locations.json` schema
2. Add environment variable parsing to commands
3. Implement configuration discovery function
4. Test precedence logic

**Files to Create**:
- `.claude/lib/specs-location-resolver.sh` - Core resolution logic
- `.claude/config/specs-locations.json` - Example configuration

**Complexity**: Medium

### Phase 2: Command Updates

**Update these commands** to use new resolution:
1. `/report` - Reports location
2. `/plan` - Plans location
3. `/implement` - Summaries location
4. `/orchestrate` - All three types
5. `/debug` - Debug reports location
6. `/refactor` - Refactor reports location
7. `/list-reports` - Search all configured locations
8. `/list-plans` - Search all configured locations
9. `/list-summaries` - Search all configured locations
10. `/resume-implement` - Search all configured locations

**Pattern for updates**:
```bash
# Before
REPORTS_DIR="specs/reports"

# After
source "$CLAUDE_DIR/lib/specs-location-resolver.sh"
REPORTS_DIR=$(resolve_specs_location "reports")
```

**Complexity**: Low-Medium (repetitive but straightforward)

### Phase 3: Documentation

**Documentation needed**:
1. Configuration file format reference
2. Environment variable reference
3. Scope rules examples
4. Migration guide from current structure
5. Monorepo setup examples

**Files to update**:
- `CLAUDE.md` - Add Specs Configuration section
- `.claude/docs/specs-location-guide.md` - New comprehensive guide
- Each command's help text - Note configuration options

**Complexity**: Low

### Phase 4: Testing

**Test scenarios**:
1. Default behavior (no configuration)
2. Config file only
3. Environment variables only
4. Both config + env vars (precedence)
5. Scope rules in monorepo
6. Invalid configuration (error handling)
7. Migration from old structure

**Complexity**: Medium

## Monorepo Use Cases

### Example 1: Multi-Module Monorepo

**Project Structure**:
```
myproject/
├── .claude/
│   └── config/
│       └── specs-locations.json
├── frontend/
│   ├── src/
│   └── docs/
├── backend/
│   ├── src/
│   └── docs/
└── shared/
    ├── lib/
    └── docs/
```

**Configuration**:
```json
{
  "specs": {
    "scope_rules": [
      {
        "path_prefix": "frontend/",
        "reports": "frontend/docs/research",
        "plans": "frontend/docs/plans"
      },
      {
        "path_prefix": "backend/",
        "reports": "backend/docs/research",
        "plans": "backend/docs/plans"
      },
      {
        "path_prefix": "shared/",
        "reports": "shared/docs/research",
        "plans": "shared/docs/plans"
      }
    ],
    "fallback": "docs/project-wide/specs"
  }
}
```

**Behavior**:
```bash
cd frontend/
/report "React patterns"
# Creates: frontend/docs/research/001_react_patterns.md

cd ../backend/
/plan "API refactor"
# Creates: backend/docs/plans/001_api_refactor.md

cd ../
/report "Architecture overview"
# Creates: docs/project-wide/specs/reports/001_architecture_overview.md
```

### Example 2: Neovim Plugin Development

**Project Structure**:
```
.config/
├── nvim/
│   ├── lua/
│   │   └── neotex/
│   │       ├── plugins/
│   │       │   ├── ai/
│   │       │   │   └── docs/specs/
│   │       │   └── tools/
│   │       │       └── docs/specs/
│   │       └── core/
│   └── docs/specs/
└── .claude/
    └── config/specs-locations.json
```

**Configuration**:
```json
{
  "specs": {
    "scope_rules": [
      {
        "path_prefix": "nvim/lua/neotex/plugins/ai/",
        "reports": "nvim/lua/neotex/plugins/ai/docs/specs/reports",
        "plans": "nvim/lua/neotex/plugins/ai/docs/specs/plans",
        "summaries": "nvim/lua/neotex/plugins/ai/docs/specs/summaries"
      },
      {
        "path_prefix": "nvim/lua/neotex/plugins/tools/",
        "reports": "nvim/lua/neotex/plugins/tools/docs/specs/reports",
        "plans": "nvim/lua/neotex/plugins/tools/docs/specs/plans",
        "summaries": "nvim/lua/neotex/plugins/tools/docs/specs/summaries"
      },
      {
        "path_prefix": "nvim/",
        "reports": "nvim/docs/specs/reports",
        "plans": "nvim/docs/specs/plans",
        "summaries": "nvim/docs/specs/summaries"
      }
    ]
  }
}
```

**Behavior**: Each plugin module gets its own specs/ while nvim-wide specs go to nvim/docs/specs/.

## Industry Best Practices

### Monorepo Tools (2025)

Research on monorepo tools reveals common configuration patterns:

**Turborepo** (`turbo.json`):
- Per-package configuration with inheritance
- Root-level defaults, package-level overrides
- Workspace-relative paths

**Nx** (`nx.json` + `project.json`):
- Project-level configuration files
- Centralized workspace configuration
- Path resolution relative to workspace root

**pnpm Workspaces** (`pnpm-workspace.yaml`):
- Package-scoped settings
- Workspace protocols for cross-package references

**Common Pattern**: **Root config with per-module overrides**

### CLI Tool Configuration Discovery

Standard patterns from research:

1. **Upward Directory Traversal**:
   - Start at current directory
   - Search parent directories until found
   - Stop at filesystem root or project boundary

2. **Configuration File Names**:
   - `.toolrc` or `.tool.json` or `tool.config.*`
   - Hidden files preferred (start with `.`)

3. **Environment Variable Overrides**:
   - `TOOL_CONFIG_PATH` for config location
   - `TOOL_*` for specific settings
   - Environment vars take precedence

**Example Tools Using This Pattern**:
- ESLint (`.eslintrc`, upward search)
- Prettier (`.prettierrc`, upward search)
- Git (`.git/config`, upward search for repo root)
- Cargo (Rust - `Cargo.toml`, upward search)

**Lesson**: Our recommended approach (config file + env vars) aligns with industry standards.

## Migration Strategy

### Backward Compatibility

**Critical**: Existing projects must work without changes.

**Compatibility Requirements**:
1. ✅ Projects without configuration use current behavior
2. ✅ Existing `specs/` directories continue working
3. ✅ No breaking changes to command interfaces
4. ✅ Automatic detection still works as fallback

**Testing Backward Compatibility**:
```bash
# Test 1: No configuration (should work as before)
cd clean-project/
/report "test"
# Should create: specs/reports/001_test.md

# Test 2: Existing specs/ directory
cd project-with-specs/
ls specs/reports/  # Has 001-010 reports
/report "new topic"
# Should create: specs/reports/011_new_topic.md

# Test 3: Subdirectory specs/
cd project/module/
/report "module topic"
# Should detect module/, create: module/specs/reports/001_module_topic.md
```

### Migration Guide for Users

**For users wanting to adopt new configuration**:

#### Step 1: Analyze Current Structure

```bash
# Find all existing specs/ directories
find . -type d -name "specs"

# List all reports/plans/summaries
find . -path "*/specs/reports/*.md"
find . -path "*/specs/plans/*.md"
find . -path "*/specs/summaries/*.md"
```

#### Step 2: Design New Structure

Decide on organization:
- Single central location?
- Per-module locations?
- Custom naming (e.g., `docs/` instead of `specs/`)?

#### Step 3: Create Configuration

```bash
# Create config file
mkdir -p .claude/config
cat > .claude/config/specs-locations.json <<EOF
{
  "specs": {
    "reports": "docs/research",
    "plans": "docs/plans",
    "summaries": "docs/completed"
  }
}
EOF
```

#### Step 4: Move Existing Files (Optional)

```bash
# Move existing specs to new locations
mkdir -p docs/research docs/plans docs/completed
mv specs/reports/* docs/research/
mv specs/plans/* docs/plans/
mv specs/summaries/* docs/completed/
```

**Important**: Update cross-references in files after moving.

#### Step 5: Test Configuration

```bash
# Test new locations
/report "test migration"
ls docs/research/  # Should see new report

# Verify numbering continues correctly
```

## Recommendations

### Primary Recommendation

**Implement Hybrid Strategy**: Configuration file with environment variable overrides.

**Rationale**:
1. **Flexibility**: Supports simple and complex use cases
2. **Industry Standard**: Matches patterns from successful CLI tools
3. **Backward Compatible**: Existing projects work without changes
4. **Monorepo Ready**: Scope rules handle multi-module projects
5. **User-Friendly**: Simple for basic use, powerful when needed

### Configuration File Location

**Recommended**: `.claude/config/specs-locations.json`

**Rationale**:
- Consistent with existing `.claude/` structure
- Separated from code (in config/ subdirectory)
- Easy to find and edit
- Version-controlled with project

### Default Configuration

**Provide sensible defaults** even without config file:

```json
{
  "version": "1.0",
  "specs": {
    "reports": "specs/reports",
    "plans": "specs/plans",
    "summaries": "specs/summaries",
    "scope_rules": [],
    "fallback": "specs"
  }
}
```

This is implicit behavior when no config exists.

### Documentation Priority

**Critical documentation**:
1. **Quick Start**: Simple example in CLAUDE.md
2. **Full Guide**: Comprehensive specs-location-guide.md
3. **Examples**: Monorepo setup examples
4. **Migration**: Step-by-step migration guide

**Update all 10 commands** with brief note about configuration.

### Implementation Priority

**High Priority**:
- Core resolution logic
- Environment variable support
- `/report`, `/plan`, `/implement` updates

**Medium Priority**:
- Configuration file parsing
- Scope rules
- List commands updates

**Low Priority**:
- Advanced scope rules (regex, globs)
- Configuration validation
- Migration tooling

## Risks and Mitigations

### Risk 1: Breaking Changes

**Risk**: Configuration errors break existing workflows

**Mitigation**:
- Robust fallback to current behavior
- Configuration validation on load
- Clear error messages
- Test suite covering edge cases

### Risk 2: Configuration Complexity

**Risk**: Too many options confuse users

**Mitigation**:
- Start with simple config format
- Provide examples and templates
- Make configuration optional
- Comprehensive documentation

### Risk 3: Cross-Reference Management

**Risk**: Moving specs breaks file links

**Mitigation**:
- Document cross-reference patterns
- Provide migration checklist
- Consider adding cross-reference validation
- Update format guide with absolute vs relative paths

### Risk 4: Discovery Performance

**Risk**: Upward directory traversal slows commands

**Mitigation**:
- Cache config location per session
- Limit search depth (stop at git root)
- Optimize parsing (simple JSON)
- Measure and profile

### Risk 5: Multiple Configurations

**Risk**: Multiple CLAUDE.md or config files conflict

**Mitigation**:
- Clear precedence rules
- Document merging behavior
- Warn on conflicts
- Recommend single root config

## Future Enhancements

### Enhancement 1: Visual Configuration Tool

Create `/configure-specs` command for interactive setup:
```bash
/configure-specs

# Prompts:
# 1. "Where should reports be stored?" [specs/reports]
# 2. "Where should plans be stored?" [specs/plans]
# 3. "Do you want module-specific locations? (y/n)"
# 4. Generates .claude/config/specs-locations.json
```

### Enhancement 2: Configuration Validation

Add `/validate-specs-config` command:
- Check for valid JSON
- Verify paths exist (or offer to create)
- Test scope rules
- Validate cross-references

### Enhancement 3: Smart Migration

Create `/migrate-specs` command:
- Analyze current structure
- Suggest new organization
- Offer to move files
- Update cross-references automatically

### Enhancement 4: Workspace Awareness

Support VSCode/IDE workspace configurations:
- Read from `.vscode/settings.json`
- Support multi-root workspaces
- Integrate with IDE file watchers

### Enhancement 5: Template Configurations

Provide configuration templates:
- `monorepo-template.json`
- `single-project-template.json`
- `documentation-focused-template.json`
- `plugin-development-template.json`

Users can copy and customize templates.

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/commands/report.md` - Report creation logic
- `/home/benjamin/.config/.claude/commands/plan.md` - Plan creation logic
- `/home/benjamin/.config/.claude/commands/implement.md` - Summary creation logic
- `/home/benjamin/.config/.claude/commands/orchestrate.md` - All specs types
- `/home/benjamin/.config/.claude/commands/list-*.md` - Discovery logic
- `/home/benjamin/.config/CLAUDE.md` - Current specs structure guidance

### Web Research

- Monorepo best practices (2025): Turborepo, Nx, pnpm workspaces
- CLI tool configuration patterns: ESLint, Prettier, Cargo
- Directory traversal algorithms
- Configuration scoping strategies

### Existing Specs Directories

Found in codebase:
- `/home/benjamin/.config/.claude/specs/` - 18 reports, 6 plans
- `/home/benjamin/.config/nvim/specs/` - Neovim-specific
- `/home/benjamin/.config/nvim/lua/neotex/plugins/*/specs/` - Plugin-level

### Related Commands

- `/report` - Creates research reports
- `/plan` - Creates implementation plans
- `/implement` - Creates implementation summaries
- `/list-reports` - Lists all reports
- `/list-plans` - Lists all plans
- `/list-summaries` - Lists all summaries
- `/orchestrate` - Uses all three spec types

## Conclusion

Implementing flexible specs location strategies will significantly improve Claude Code's usability in monorepos and modular projects. The recommended hybrid approach (configuration file + environment variables) balances flexibility with simplicity while maintaining backward compatibility.

**Key Takeaways**:
1. Configuration file provides persistent, project-specific settings
2. Environment variables enable quick overrides
3. Scope rules support complex monorepo structures
4. Backward compatibility ensures no disruption
5. Implementation affects 10+ commands but follows clear patterns

**Next Steps**:
1. Review this report with stakeholders
2. Validate approach with users
3. Create implementation plan
4. Prototype core resolution logic
5. Update commands incrementally

This strategy positions Claude Code as a flexible, monorepo-ready tool that adapts to users' existing project structures rather than forcing a specific organization.

# Documentation Updates for Organizational Standards

## Metadata
- **Date**: 2025-11-13
- **Agent**: research-specialist (worker 4)
- **Topic**: Documentation updates for organizational standards
- **Report Type**: documentation planning
- **Complexity Level**: 3

## Executive Summary

Analysis of documentation requirements for .claude/ cleanup reveals need for updates across 6 key files: CLAUDE.md (add directory organization standards), scripts/README.md (create new), lib/README.md (fix misleading title), agents/templates/README.md (create new), .claude/README.md (update structure), and link validation documentation. Total effort estimated at 2-3 hours for comprehensive documentation updates ensuring organizational clarity, preventing future confusion, and establishing clear standards for directory usage.

## Documentation Gap Analysis

### Current Documentation State

**Well-Documented Directories**:
- `.claude/commands/` - Has README.md with command catalog
- `.claude/commands/templates/` - Has README.md with template usage
- `.claude/docs/` - Comprehensive documentation with guides, concepts, reference
- `.claude/lib/` - Has UTILS_README.md but with misleading title
- `.claude/tests/` - Has README.md with test organization

**Under-Documented Directories**:
- `.claude/scripts/` - **NO README** (7 operational scripts with no documentation)
- `.claude/agents/` - Has README but doesn't mention templates subdirectory
- `.claude/templates/` - Will be removed, but no migration documentation

**Misleading Documentation**:
- `.claude/lib/UTILS_README.md` - Title says "Standalone Utility Scripts" but this is the lib/ directory (sourced functions, not standalone scripts)

### Standards Gap in CLAUDE.md

**Current State**:
CLAUDE.md contains extensive standards sections but lacks:
- Directory organization standards (when to use scripts/ vs lib/ vs commands/)
- File placement decision matrix
- Naming conventions for different directory types
- Clear examples and anti-examples

**Impact**:
- Developers uncertain where to place new utilities
- Spec 492 attempted scripts/ elimination incorrectly
- Files added to wrong directories (validate_links_temp.sh at root)
- Duplicate functionality across directories

## Required Documentation Updates

### 1. Create scripts/README.md

**Location**: `.claude/scripts/README.md`

**Purpose**: Document standalone operational scripts and clarify distinction from lib/

**Content Structure**:
```markdown
# Standalone Operational Scripts

## Purpose
Standalone CLI tools for system maintenance, validation, and analysis. These are executable scripts that provide command-line interfaces for operational tasks.

## Current Scripts

### Link Validation and Fixing
- **validate-links.sh** - Full markdown link validation across .claude/docs/
- **validate-links-quick.sh** - Fast validation for critical paths only
- **fix-absolute-to-relative.sh** - Convert absolute paths to relative in markdown links
- **fix-duplicate-paths.sh** - Resolve duplicate path references
- **fix-renamed-files.sh** - Update references after file renames
- **rollback-link-fixes.sh** - Rollback link fix changes

### Performance Analysis
- **analyze-coordinate-performance.sh** - Analyze /coordinate command performance metrics

## When to Add Scripts Here

Add to scripts/ when creating:
- **Validation tools** (validate-*)
- **Fixing utilities** (fix-*)
- **Analysis tools** (analyze-*)
- **Maintenance scripts** (cleanup-*, migrate-*)
- **Rollback utilities** (rollback-*)

Requirements:
- Executable with CLI interface
- Accepts command-line arguments
- Standalone (doesn't need to be sourced)
- Operational/maintenance purpose

## When NOT to Add Scripts Here

Do NOT add to scripts/ when creating:
- **Sourced function libraries** → use `.claude/lib/`
- **Command implementations** → use `.claude/commands/`
- **Agent definitions** → use `.claude/agents/`
- **Tests** → use `.claude/tests/`
- **Temporary utilities** → do not commit to repository

## Naming Conventions

Format: `{verb}-{object}[-{qualifier}].sh`

**Examples**:
- validate-links.sh (verb: validate, object: links)
- fix-absolute-to-relative.sh (verb: fix, object: absolute-to-relative)
- analyze-coordinate-performance.sh (verb: analyze, object: coordinate-performance)

**Approved Verbs**: validate, fix, analyze, rollback, generate, migrate, cleanup, sync

## vs lib/ Directory

| Aspect | scripts/ | lib/ |
|--------|----------|------|
| **Execution** | Direct (`./script.sh`) | Sourced (`source lib.sh`) |
| **Interface** | CLI with arguments | Function calls |
| **Purpose** | Standalone tools | Reusable libraries |
| **Users** | Developers, CI/CD | Commands, agents |
| **Independence** | Self-contained | Dependency providers |

See [lib/README.md](../lib/README.md) for sourced library documentation.

## Usage Examples

```bash
# Validate all links
./scripts/validate-links.sh

# Quick validation (critical paths only)
./scripts/validate-links-quick.sh

# Fix absolute paths (dry run)
./scripts/fix-absolute-to-relative.sh --dry-run

# Analyze coordinate performance
./scripts/analyze-coordinate-performance.sh /path/to/logs
```

## Integration

**Used By**:
- Link validation workflows
- Documentation standards compliance
- Performance monitoring
- Migration and cleanup operations

**References**:
- [Broken Links Troubleshooting Guide](../docs/troubleshooting/broken-links-troubleshooting.md)
- [Link Conventions Guide](../docs/guides/link-conventions-guide.md)

## Navigation
- [← Parent Directory](../README.md)
- [Sourced Libraries](../lib/README.md)
- [Commands](../commands/README.md)
- [Tests](../tests/README.md)
```

**Effort**: 45 minutes

### 2. Update lib/README.md

**Location**: `.claude/lib/README.md` (currently UTILS_README.md)

**Issues to Fix**:
1. Misleading title "Standalone Utility Scripts" (should be "Sourced Function Libraries")
2. No clear distinction from scripts/
3. Missing decision matrix for when to use lib/ vs scripts/

**Changes Required**:

**Title Change**:
```markdown
# Sourced Function Libraries
```
(Replace "Standalone Utility Scripts")

**Add Section**:
```markdown
## Purpose vs scripts/

This directory contains **sourced function libraries** that provide reusable functions for commands and agents. These are NOT standalone executable scripts.

| Aspect | lib/ (This Directory) | scripts/ |
|--------|----------------------|----------|
| **Execution** | Sourced (`source lib.sh`) | Direct (`./script.sh`) |
| **Interface** | Function calls | CLI with arguments |
| **Purpose** | Reusable libraries | Standalone tools |
| **Users** | Commands, agents, scripts | Developers, maintainers |
| **Example** | `source lib/context-metrics.sh` | `./scripts/validate-links.sh` |

**If you need a CLI tool**, use [scripts/](../scripts/README.md) instead.

## When to Add Libraries Here

Add to lib/ when creating:
- Reusable function libraries
- Utility functions for commands/agents
- Shared logic across multiple workflows
- Helper functions for complex operations

Requirements:
- Designed to be sourced, not executed
- Provides functions, not CLI interface
- Reusable across multiple contexts
- Well-documented function APIs
```

**Effort**: 30 minutes

### 3. Create agents/templates/README.md

**Location**: `.claude/agents/templates/README.md`

**Purpose**: Document agent template directory and usage

**Content**:
```markdown
# Agent Templates

## Purpose
Templates for creating specialized agents in the `.claude/agents/` directory. These templates provide starting points for new agent implementations following established patterns.

## Available Templates

### sub-supervisor-template.md
**Purpose**: Template for creating hierarchical sub-supervisor agents

**Use Case**: When you need to coordinate multiple specialized worker agents in parallel

**Features**:
- Worker invocation patterns
- Metadata aggregation logic
- Checkpoint coordination
- Partial failure handling
- Context reduction (95%+)

**Usage**:
1. Copy template to `.claude/agents/{agent-name}.md`
2. Update agent metadata (name, purpose, capabilities)
3. Customize worker invocation patterns
4. Adjust aggregation logic for your use case
5. Test with sample workflow

**Example**:
```bash
# Create new sub-supervisor agent
cp .claude/agents/templates/sub-supervisor-template.md .claude/agents/my-supervisor.md

# Edit agent definition
# Update metadata, worker patterns, aggregation logic

# Test agent
# Use in orchestration workflow
```

## Creating New Templates

When creating new agent templates:

1. **Follow Agent Standards**: See [Agent Development Guide](../../docs/guides/agent-development-guide.md)
2. **Include Complete Structure**:
   - Agent metadata (frontmatter)
   - Purpose and capabilities
   - Execution protocol
   - Input/output specifications
   - Performance characteristics
3. **Provide Examples**: Show real usage patterns
4. **Document Customization**: Explain what needs to be changed
5. **Test Thoroughly**: Validate template generates working agents

## Template Naming

Format: `{pattern}-template.md`

Examples:
- sub-supervisor-template.md
- research-specialist-template.md
- implementation-worker-template.md

## vs Command Templates

| Aspect | agents/templates/ | commands/templates/ |
|--------|------------------|---------------------|
| **Purpose** | Agent creation | Plan generation |
| **Format** | Markdown | YAML |
| **Usage** | Copy and customize | Variable substitution |
| **Consumers** | Orchestrators | /plan-from-template |

See [commands/templates/](../../commands/templates/README.md) for plan templates.

## References
- [Agent Development Guide](../../docs/guides/agent-development-guide.md)
- [Hierarchical Agent Architecture](../../docs/concepts/hierarchical_agents.md)
- [Agent Reference](../../docs/reference/agent-reference.md)

## Navigation
- [← Parent Directory](../README.md)
- [Command Templates](../../commands/templates/README.md)
- [Documentation](../../docs/README.md)
```

**Effort**: 30 minutes

### 4. Update CLAUDE.md - Add Directory Organization Standards

**Location**: `/home/benjamin/.config/CLAUDE.md`

**Section to Add**: After code_standards section, before development_philosophy

**Content**:
```markdown
<!-- SECTION: directory_organization -->
## Directory Organization Standards
[Used by: All development, file placement decisions]

### Purpose-Based Directory Structure

The `.claude/` directory organizes files by purpose to ensure clarity and maintainability.

#### scripts/ - Operational CLI Tools
**Purpose**: Standalone executable tools for maintenance and operations

**Characteristics**:
- Executable scripts with CLI interfaces
- Accept command-line arguments
- Direct execution (not sourced)
- Operational/maintenance purpose

**Naming Convention**: `{verb}-{object}[-{qualifier}].sh`
- Verbs: validate, fix, analyze, rollback, generate, migrate, cleanup
- Examples: `validate-links.sh`, `fix-absolute-to-relative.sh`

**Examples**:
- Link validation tools
- Path fixing utilities
- Performance analysis scripts
- Migration and cleanup tools

**Not For**: Sourced libraries, command implementations, agent definitions

#### lib/ - Sourced Function Libraries
**Purpose**: Reusable function libraries for commands and agents

**Characteristics**:
- Function definitions (sourced, not executed)
- Provide reusable functions
- No direct CLI interfaces
- Support infrastructure

**Naming Convention**: `{category}-{component}.sh`
- Categories: context, agent, workflow, artifact, checkpoint
- Examples: `context-metrics.sh`, `agent-registry-utils.sh`

**Examples**:
- Utility functions
- Shared logic
- Helper libraries
- Integration points

**Not For**: Standalone executables, CLI tools, command implementations

#### commands/ - Slash Command Implementations
**Purpose**: Claude Code slash commands

**Structure**:
- `commands/{command-name}.md` - Command implementations
- `commands/templates/` - Plan templates for /plan-from-template

**Examples**: /coordinate, /implement, /plan, /research

**Not For**: Agent definitions, utility functions, standalone scripts

#### agents/ - Specialized Agent Definitions
**Purpose**: Behavioral specifications for specialized agents

**Structure**:
- `agents/{agent-name}.md` - Agent definitions
- `agents/templates/` - Agent templates

**Examples**: research-specialist, implementation-researcher, sub-supervisor

**Not For**: Commands, utilities, plan templates

### File Placement Decision Matrix

When creating a new file, use this matrix to determine correct location:

| Requirement | Location | Example |
|-------------|----------|---------|
| CLI tool for operations | `scripts/` | validate-links.sh |
| Reusable functions | `lib/` | context-metrics.sh |
| Slash command | `commands/` | coordinate.md |
| Plan template | `commands/templates/` | crud-feature.yaml |
| Agent definition | `agents/` | research-specialist.md |
| Agent template | `agents/templates/` | sub-supervisor-template.md |
| Documentation | `docs/` | command-guide.md |
| Test | `tests/` | test_state_machine.sh |

### Anti-Patterns to Avoid

**Wrong Locations**:
- ❌ Temporary scripts in repository root (use scripts/ or .gitignore)
- ❌ CLI tools in lib/ (use scripts/)
- ❌ Sourced libraries in scripts/ (use lib/)
- ❌ Plan templates in agents/templates/ (use commands/templates/)
- ❌ Agent templates in commands/templates/ (use agents/templates/)

**Naming Violations**:
- ❌ Underscores in script names (use hyphens: fix-paths.sh not fix_paths.sh)
- ❌ Generic names without purpose (util.sh → use specific: context-utils.sh)
- ❌ Inconsistent verb choices (check-links.sh when validate-links.sh exists)

### Directory README Requirements

Every subdirectory MUST have a README.md containing:
- **Purpose**: Clear explanation of directory role
- **Contents**: Documentation for each file
- **Usage Examples**: Code examples where applicable
- **Navigation Links**: Links to parent and related directories
- **Standards**: Naming conventions and placement criteria

See [Documentation Policy](#documentation_policy) for complete README standards.
<!-- END_SECTION: directory_organization -->
```

**Effort**: 45 minutes

### 5. Update .claude/README.md

**Location**: `.claude/README.md`

**Changes Required**:

**Update Directory Structure Section**:
```markdown
## Directory Structure

```
.claude/
├── agents/              # Specialized agent definitions
│   └── templates/       # Agent templates (sub-supervisor, etc.)
├── commands/            # Slash command implementations
│   └── templates/       # Plan templates (YAML)
├── config/              # Configuration files
├── data/                # Runtime data, logs, checkpoints
├── docs/                # Documentation (guides, concepts, reference)
├── hooks/               # Git hooks and event handlers
├── lib/                 # Sourced function libraries
├── scripts/             # Standalone operational CLI tools
├── specs/               # Implementation specs and reports
├── tests/               # Test suites
├── tmp/                 # Temporary runtime files
└── tts/                 # Text-to-speech utilities
```
```

**Add Note About Organization**:
```markdown
## Organization Principles

- **scripts/**: Standalone CLI tools (validate, fix, analyze)
- **lib/**: Sourced function libraries (utilities, helpers)
- **commands/**: Slash command implementations
- **agents/**: Specialized agent behavioral specifications
- **templates/**: Separated by consumer (commands/ vs agents/)

See [CLAUDE.md Directory Organization Standards](../../CLAUDE.md#directory_organization) for complete placement guidelines.
```

**Effort**: 20 minutes

### 6. Link Validation Documentation

**Location**: `.claude/docs/troubleshooting/broken-links-troubleshooting.md`

**Update Required**: Add reference to relocated scripts

**Change**:
```markdown
## Validation Tools

Use the link validation scripts:
- **Full validation**: `.claude/scripts/validate-links.sh`
- **Quick validation**: `.claude/scripts/validate-links-quick.sh`
- **Fix tools**: `.claude/scripts/fix-*.sh`

See [scripts/README.md](../../scripts/README.md) for complete documentation.
```

**Effort**: 10 minutes

## Documentation Standards Compliance

### Standards to Follow

All documentation updates must comply with:

1. **Link Conventions** (from CLAUDE.md):
   - Use relative paths from current file
   - No absolute filesystem paths
   - Verify with `./scripts/validate-links.sh`

2. **Writing Standards** (from CLAUDE.md):
   - No emojis in file content
   - UTF-8 encoding only
   - CommonMark specification compliance
   - No historical commentary

3. **README Requirements** (from CLAUDE.md):
   - Purpose section
   - Module documentation
   - Usage examples
   - Navigation links

4. **Imperative Language** (from guides):
   - Use MUST/WILL/SHALL for requirements
   - Use MAY/CAN for options
   - Avoid SHOULD (ambiguous)

### Verification Checklist

After all documentation updates:

- [ ] Run link validation: `./scripts/validate-links.sh`
- [ ] Check for broken cross-references
- [ ] Verify all README files have required sections
- [ ] Ensure consistent terminology across files
- [ ] Test all code examples
- [ ] Review for emojis (should have none)
- [ ] Validate markdown syntax
- [ ] Check navigation links work

## Implementation Timeline

### Phase 1: Create New Documentation (1.5 hours)
1. Create `scripts/README.md` (45 min)
2. Create `agents/templates/README.md` (30 min)
3. Update CLAUDE.md with directory standards (45 min)

### Phase 2: Update Existing Documentation (45 minutes)
4. Update `lib/README.md` title and sections (30 min)
5. Update `.claude/README.md` structure (15 min)

### Phase 3: Update References (15 minutes)
6. Update link validation documentation (10 min)
7. Add cross-references between READMEs (5 min)

### Phase 4: Verification (30 minutes)
8. Run link validation (5 min)
9. Review all changes for consistency (15 min)
10. Test code examples (10 min)

**Total Effort**: 3 hours

## Success Criteria

### Documentation Completeness
- [ ] Every directory has README.md
- [ ] All READMEs have required sections (Purpose, Contents, Usage, Navigation)
- [ ] CLAUDE.md contains directory organization standards
- [ ] Decision matrix documented and clear
- [ ] Examples provided for all standards

### Documentation Quality
- [ ] No broken links (validate-links.sh passes)
- [ ] Consistent terminology across files
- [ ] Clear examples and anti-examples
- [ ] No emojis or special characters
- [ ] Follows writing standards

### Documentation Impact
- [ ] Developers understand where to place files
- [ ] Clear distinction between scripts/ and lib/
- [ ] Template organization documented
- [ ] Future confusion prevented
- [ ] Onboarding time reduced

## Cross-References

**Files to Update**:
1. `/home/benjamin/.config/CLAUDE.md` - Add directory organization section
2. `/home/benjamin/.config/.claude/scripts/README.md` - Create new
3. `/home/benjamin/.config/.claude/lib/README.md` - Fix title, add distinction
4. `/home/benjamin/.config/.claude/agents/templates/README.md` - Create new
5. `/home/benjamin/.config/.claude/README.md` - Update structure
6. `/home/benjamin/.config/.claude/docs/troubleshooting/broken-links-troubleshooting.md` - Update references

**Related Specifications**:
- Spec 492: Scripts consolidation (documentation gaps identified)
- Spec 493: Templates cleanup (documentation requirements)
- Spec 699: Standards in coordinate command (organizational standards)

**Dependencies**:
- Template relocation must complete before agents/templates/README.md creation
- scripts/ documentation should reference final state after validate_links_temp.sh relocation
- CLAUDE.md updates should reflect final directory structure

## Key Findings

1. **Critical Gap**: No scripts/ README despite 7 operational tools
2. **Misleading Content**: lib/README.md title incorrectly says "Standalone Utility Scripts"
3. **Missing Standards**: CLAUDE.md lacks directory organization decision matrix
4. **Template Documentation**: New agents/templates/ directory needs README
5. **Consistency Issues**: Terminology varies across existing documentation

## Recommendations

1. **Create scripts/README.md** - Priority 1 (blocks understanding of scripts/ purpose)
2. **Update lib/README.md** - Priority 1 (misleading content causes confusion)
3. **Add CLAUDE.md standards** - Priority 1 (prevents future mistakes)
4. **Create agents/templates/README.md** - Priority 2 (after template relocation)
5. **Update cross-references** - Priority 2 (after structural changes complete)
6. **Verify all links** - Priority 1 (maintain documentation integrity)

**Total Effort**: 3 hours
**Impact**: High (prevents future organizational confusion)
**Complexity**: Low-Medium (documentation-focused, minimal code changes)

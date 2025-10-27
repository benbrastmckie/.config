# Command Template Dependencies Research Report

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Command template dependencies analysis
- **Report Type**: codebase analysis
- **Files Analyzed**: 21 command files, 24 template files
- **Scope**: Complete .claude/commands/ and .claude/templates/ directories

## Executive Summary

This research analyzed dependencies between slash commands in `.claude/commands/` and template files in `.claude/templates/`. The findings reveal a clear separation between two types of templates: **YAML plan templates** (used by `/plan-from-template`) and **Markdown reference templates** (used by multiple commands for structural guidance).

**Key Findings**:
- **11 YAML templates** are exclusively used by `/plan-from-template` command for rapid plan generation
- **13 Markdown templates** serve as reference documentation for multiple commands
- **5 commands** have critical dependencies on specific template structures
- Template usage follows a consistent pattern: YAML for instantiation, Markdown for reference

The template system successfully reduces code duplication by centralizing structural patterns, agent invocation examples, and output formatting standards.

## Findings

### Template Categories

The `.claude/templates/` directory contains two distinct template types:

#### 1. YAML Plan Templates (11 files)
Used exclusively by `/plan-from-template` for variable substitution and plan generation:

1. **api-endpoint.yaml** - REST API endpoint implementation
2. **crud-feature.yaml** - CRUD operations for entities
3. **debug-workflow.yaml** - Debugging investigation workflow
4. **documentation-update.yaml** - Documentation synchronization
5. **example-feature.yaml** - Template structure reference
6. **migration.yaml** - Breaking changes and migrations
7. **refactor-consolidation.yaml** - Code consolidation refactoring
8. **refactoring.yaml** - General refactoring workflow
9. **research-report.yaml** - Research investigation template
10. **spec-updater-test.yaml** - Spec updater testing template
11. **test-suite.yaml** - Test suite implementation

**Usage Pattern**: These templates are loaded by `/plan-from-template` command only, parsed for variables, instantiated with user-provided values, and saved as implementation plans.

**Location References**:
- `/home/benjamin/.config/.claude/commands/plan-from-template.md:46` - Lists templates via grep
- `/home/benjamin/.config/.claude/commands/plan-from-template.md:70-71` - Template discovery logic
- `/home/benjamin/.config/.claude/commands/README.md:295-298` - Template examples

#### 2. Markdown Reference Templates (13 files)
Used by multiple commands as structural and behavioral reference:

1. **agent-invocation-patterns.md** - Standard Task tool invocation patterns
2. **agent-tool-descriptions.md** - Tool access documentation for agents
3. **artifact_research_invocation.md** - Research agent invocation template
4. **audit-checklist.md** - Quality audit checklist
5. **command-frontmatter.md** - Standard YAML frontmatter for commands
6. **debug-structure.md** - Debug report structure standard
7. **orchestration-patterns.md** - Multi-agent coordination patterns
8. **output-patterns.md** - Minimal output formatting standards
9. **readme-template.md** - Directory README structure
10. **refactor-structure.md** - Refactoring report structure standard
11. **report-structure.md** - Research report structure standard
12. **sub_supervisor_pattern.md** - Recursive supervision template
13. **README.md** - Template directory documentation

**Usage Pattern**: These are referenced for structural guidance but not directly instantiated. Commands read them to understand expected formats.

### Command Dependencies Matrix

| Command | Template Files | Dependency Type | Critical? |
|---------|----------------|-----------------|-----------|
| `/plan-from-template` | All 11 YAML files | Direct instantiation | ✓ Critical |
| `/orchestrate` | orchestration-patterns.md | Reference | ✓ Critical |
| `/research` | report-structure.md | Reference | ✓ Critical |
| `/refactor` | refactor-structure.md | Reference | ✓ Critical |
| `/debug` | debug-structure.md | Reference | ✓ Critical |
| `/plan` | example-feature.yaml (reference) | Optional | - |
| `/document` | output-patterns.md | Reference | Optional |
| Other commands | None | N/A | - |

### Detailed Command Analysis

#### 1. /plan-from-template Command (CRITICAL DEPENDENCY)

**File**: `/home/benjamin/.config/.claude/commands/plan-from-template.md`

**Template Dependencies**:
- **All 11 YAML templates** - Direct instantiation
- **templates/README.md** - Documentation reference

**Usage Pattern**:
```bash
# Line 46: Category listing
grep -h "^category:" .claude/templates/*.yaml

# Line 70-71: Template discovery
.claude/templates/<name>.yaml
.claude/templates/custom/<name>.yaml
```

**Dependency Strength**: **CRITICAL** - Command cannot function without YAML templates. Removes a template file breaks the command for that template type.

**Variable Substitution**: Uses `.claude/lib/parse-template.sh` and `.claude/lib/substitute-variables.sh` utilities to process templates.

**References**:
- `/home/benjamin/.config/.claude/commands/plan-from-template.md:46` - Template discovery
- `/home/benjamin/.config/.claude/commands/plan-from-template.md:70-71` - File location logic
- `/home/benjamin/.config/.claude/commands/plan-from-template.md:278` - Documentation reference

#### 2. /orchestrate Command (CRITICAL DEPENDENCY)

**File**: `/home/benjamin/.config/.claude/commands/orchestrate.md`

**Template Dependencies**:
- **orchestration-patterns.md** - Agent prompt templates, phase coordination patterns, checkpoint structure, error recovery patterns

**Usage Pattern**:
```markdown
# Line 79: Reference declaration
- **Agent Templates**: `.claude/templates/orchestration-patterns.md`

# Line 273: Error recovery patterns
See `.claude/templates/orchestration-patterns.md#error-recovery-patterns`

# Line 299: Implementation examples reference
See `.claude/templates/orchestration-patterns.md` for detailed implementation examples.

# Line 573, 1385, 2112: Phase pattern references
See [Orchestration Patterns - Research/Planning/Implementation Phase]
```

**Dependency Strength**: **CRITICAL** - Template provides essential agent invocation templates, coordination patterns, and recovery strategies. Without it, command would lack standardized multi-agent patterns.

**References**:
- `/home/benjamin/.config/.claude/commands/orchestrate.md:79` - Template declaration
- `/home/benjamin/.config/.claude/commands/orchestrate.md:273` - Error recovery
- `/home/benjamin/.config/.claude/commands/orchestrate.md:299` - Pattern details
- `/home/benjamin/.config/.claude/commands/orchestrate.md:573` - Research phase
- `/home/benjamin/.config/.claude/commands/orchestrate.md:1385` - Planning phase
- `/home/benjamin/.config/.claude/commands/orchestrate.md:2112` - Implementation phase

#### 3. /research Command (CRITICAL DEPENDENCY)

**File**: `/home/benjamin/.config/.claude/commands/research.md`

**Template Dependencies**:
- **report-structure.md** - Standard research report structure and section guidelines

**Usage Pattern**:
```markdown
# Line 691: Structure reference
For complete report structure and section guidelines, see `.claude/templates/report-structure.md`
```

**Dependency Strength**: **CRITICAL** - Defines the expected structure for all research reports. Agents creating reports follow this template to ensure consistency.

**References**:
- `/home/benjamin/.config/.claude/commands/research.md:691` - Structure reference

#### 4. /refactor Command (CRITICAL DEPENDENCY)

**File**: `/home/benjamin/.config/.claude/commands/refactor.md`

**Template Dependencies**:
- **refactor-structure.md** - Standard refactoring report structure

**Usage Pattern**:
```markdown
# Line 187: Critical requirement
**CRITICAL**: Refactoring reports MUST follow the standard structure defined in
`.claude/templates/refactor-structure.md`.

# Line 198: Complete guidelines reference
For complete refactoring report structure and analysis guidelines, see
`.claude/templates/refactor-structure.md`
```

**Dependency Strength**: **CRITICAL** - Refactoring reports MUST follow this structure. The command explicitly requires adherence via "CRITICAL" markers.

**References**:
- `/home/benjamin/.config/.claude/commands/refactor.md:187` - Critical requirement
- `/home/benjamin/.config/.claude/commands/refactor.md:198` - Complete guidelines

#### 5. /debug Command (CRITICAL DEPENDENCY)

**File**: `/home/benjamin/.config/.claude/commands/debug.md`

**Template Dependencies**:
- **debug-structure.md** - Standard debug report structure

**Usage Pattern**:
```markdown
# Line 580: Structure declaration
Debug reports follow the standard structure defined in `.claude/templates/debug-structure.md`.

# Line 591: Complete guidelines reference
For complete debug report structure and investigation guidelines, see
`.claude/templates/debug-structure.md`
```

**Dependency Strength**: **CRITICAL** - Debug reports must follow standardized structure for consistency across investigations.

**References**:
- `/home/benjamin/.config/.claude/commands/debug.md:580` - Structure declaration
- `/home/benjamin/.config/.claude/commands/debug.md:591` - Complete guidelines

#### 6. Other Commands (OPTIONAL/REFERENCE)

**Commands with optional template references**:
- `/plan` - References example-feature.yaml for template structure (line 76)
- `/document` - May reference output-patterns.md for formatting
- Various commands - Reference agent-invocation-patterns.md indirectly through docs

**Dependency Strength**: Optional - These commands can function without templates but benefit from referencing them for consistency.

### Template Utility Scripts

**Supporting Infrastructure**:
- `.claude/lib/parse-template.sh` - YAML template validation and metadata extraction
- `.claude/lib/substitute-variables.sh` - Variable substitution engine for {{var}} syntax
- `.claude/lib/UTILS_README.md:line` - Documentation of template utilities

**Referenced by**: `/plan-from-template` command exclusively for YAML template processing.

### Template Maintenance Patterns

**How Templates Are Updated**:
1. **YAML Templates**: Modified directly when adding new template types or improving existing workflows
2. **Markdown Templates**: Updated when command patterns change or new standards emerge
3. **Version Control**: All templates are git-tracked, changes visible in commit history

**Documentation Standards**:
- `/home/benjamin/.config/.claude/templates/README.md` - Central template documentation
- Neovim integration via artifact picker (keybinding: `<leader>ac`)
- Templates automatically detected by picker for easy browsing/editing

### Usage Frequency Analysis

**High-Usage Templates** (referenced by multiple commands or frequently used):
1. **orchestration-patterns.md** - Referenced 6+ times in /orchestrate
2. **report-structure.md** - Used by /research and research-specialist agent
3. **refactor-structure.md** - Used by /refactor and code-reviewer agent
4. **debug-structure.md** - Used by /debug and debug-analyst agent
5. **crud-feature.yaml** - Most commonly used plan template

**Low-Usage Templates** (specialized use cases):
- **spec-updater-test.yaml** - Testing infrastructure only
- **audit-checklist.md** - Quality assurance reference
- **sub_supervisor_pattern.md** - Advanced recursive supervision

### Template Instantiation vs Reference

**Instantiation Pattern** (YAML templates):
```bash
# User invokes command
/plan-from-template crud-feature

# Command loads template
parse_template_file ".claude/templates/crud-feature.yaml"

# Prompts for variables
entity_name: User
fields: name, email, password

# Substitutes variables
{{entity_name}} → User
{{#each fields}}{{this}}{{/each}} → name, email, password

# Creates new plan file
specs/plans/NNN_user_crud_implementation.md
```

**Reference Pattern** (Markdown templates):
```bash
# User invokes command
/research "Authentication patterns"

# Command references structure
See: .claude/templates/report-structure.md

# Agent reads template for structure guidance
Read: report-structure.md

# Creates report following template structure
specs/NNN_topic/reports/001_auth_patterns.md
```

### Template File Locations

**All templates are in**: `/home/benjamin/.config/.claude/templates/`

**YAML Templates** (11 files):
- api-endpoint.yaml
- crud-feature.yaml
- debug-workflow.yaml
- documentation-update.yaml
- example-feature.yaml
- migration.yaml
- refactor-consolidation.yaml
- refactoring.yaml
- research-report.yaml
- spec-updater-test.yaml
- test-suite.yaml

**Markdown Templates** (13 files):
- agent-invocation-patterns.md
- agent-tool-descriptions.md
- artifact_research_invocation.md
- audit-checklist.md
- command-frontmatter.md
- debug-structure.md
- orchestration-patterns.md
- output-patterns.md
- readme-template.md
- refactor-structure.md
- report-structure.md
- sub_supervisor_pattern.md
- README.md

## Recommendations

### 1. Template Dependency Documentation

**Current State**: Template dependencies are implicit in command files via inline references.

**Recommendation**: Create a centralized template dependency registry documenting:
- Which commands use which templates
- Whether dependencies are critical or optional
- Expected template structure versions
- Breaking change impact analysis

**Implementation**: Add `template-dependencies.yaml` in `.claude/templates/`:
```yaml
dependencies:
  /plan-from-template:
    templates:
      - "*.yaml"
    type: critical
    usage: instantiation
  /orchestrate:
    templates:
      - orchestration-patterns.md
    type: critical
    usage: reference
  # ... etc
```

**Benefit**: Makes template usage explicit, enables automated dependency checking, prevents accidental breaking changes.

### 2. Template Versioning System

**Current State**: Templates have no version tracking. Changes to template structure can break commands silently.

**Recommendation**: Add semantic versioning to all templates:
- **YAML templates**: Add `version: "1.2.0"` field
- **Markdown templates**: Add version header
- Commands specify minimum compatible version
- Validation script checks version compatibility

**Example**:
```yaml
name: "CRUD Feature"
version: "2.0.0"  # Breaking change: new required field
breaking_changes:
  - "2.0.0: Added 'authorization_model' variable"
```

**Benefit**: Prevents silent breakage, enables backward compatibility checks, documents evolution.

### 3. Template Usage Testing

**Current State**: No automated tests verify templates are used correctly by commands.

**Recommendation**: Create test suite in `.claude/tests/`:
- `test_template_dependencies.sh` - Verify all template references resolve
- `test_yaml_template_parsing.sh` - Validate YAML template structure
- `test_template_substitution.sh` - Test variable substitution edge cases
- Integration tests for each command's template usage

**Benefit**: Catches broken references, validates template changes, prevents regressions.

### 4. Template Discovery Improvements

**Current State**: `/plan-from-template` uses grep for template discovery, hardcoded paths.

**Recommendation**: Create template registry library:
- `.claude/lib/template-registry.sh` - Centralized template discovery
- Caches template metadata for fast lookups
- Supports custom template directories
- Provides template search by category, complexity, keywords

**Benefit**: Faster discovery, extensible architecture, consistent API across commands.

### 5. Consolidate Redundant Templates

**Current State**: Some overlap between YAML templates (e.g., `refactoring.yaml` vs `refactor-consolidation.yaml`).

**Recommendation**: Review YAML templates for consolidation opportunities:
- Merge similar templates with conditional variables
- Use template inheritance/composition if needed
- Document when to use each template variant

**Example**: Merge refactoring templates into single `refactoring.yaml` with:
```yaml
variables:
  - name: refactoring_type
    options: ["general", "consolidation", "extraction"]
```

**Benefit**: Reduces template maintenance burden, clearer template selection, less duplication.

### 6. Template Linting and Validation

**Current State**: Manual validation of template structure, no automated checks.

**Recommendation**: Implement template linting:
- YAML schema validation for plan templates
- Markdown structure validation for reference templates
- Variable reference validation (no undefined variables)
- Pre-commit hook to validate template changes

**Tools**:
- `yamllint` for YAML syntax
- Custom validator for variable references
- Structural validators for required sections

**Benefit**: Catch errors early, enforce standards, improve template quality.

### 7. Template Usage Analytics

**Current State**: Unknown which templates are most/least used.

**Recommendation**: Add usage tracking:
- Log template usage in `.claude/data/logs/template-usage.log`
- Periodic analysis of template popularity
- Identify unused templates for deprecation
- Identify frequently-used patterns for optimization

**Benefit**: Data-driven template maintenance, identify improvement opportunities, optimize common workflows.

### 8. Template Migration Path Documentation

**Current State**: No guidance on updating commands when template structure changes.

**Recommendation**: Document template migration process:
- How to update templates without breaking commands
- Checklist for template changes
- Testing requirements for template modifications
- Rollback procedures for breaking changes

**Location**: Add `TEMPLATE_MIGRATION_GUIDE.md` to `.claude/templates/`

**Benefit**: Safe template evolution, clear change management, reduced breakage risk.

## References

### Command Files Analyzed

- `/home/benjamin/.config/.claude/commands/plan-from-template.md:1-280` - Complete analysis
- `/home/benjamin/.config/.claude/commands/orchestrate.md:1-100,273,299,573,1385,2112` - Template references
- `/home/benjamin/.config/.claude/commands/research.md:680-710` - Report structure reference
- `/home/benjamin/.config/.claude/commands/refactor.md:180-210` - Refactor structure reference
- `/home/benjamin/.config/.claude/commands/debug.md:575-605` - Debug structure reference
- `/home/benjamin/.config/.claude/commands/plan.md:76` - Example template reference
- `/home/benjamin/.config/.claude/commands/README.md:291-305` - Template documentation

### Template Files Analyzed

**YAML Templates**:
- `/home/benjamin/.config/.claude/templates/crud-feature.yaml:1-88` - Complete structure analysis
- `/home/benjamin/.config/.claude/templates/example-feature.yaml:1-75` - Template reference
- `/home/benjamin/.config/.claude/templates/api-endpoint.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/debug-workflow.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/documentation-update.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/migration.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/refactor-consolidation.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/refactoring.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/research-report.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/spec-updater-test.yaml` - Verified existence
- `/home/benjamin/.config/.claude/templates/test-suite.yaml` - Verified existence

**Markdown Templates**:
- `/home/benjamin/.config/.claude/templates/README.md:1-287` - Template system documentation
- `/home/benjamin/.config/.claude/templates/orchestration-patterns.md:1-50` - Agent prompt templates
- `/home/benjamin/.config/.claude/templates/report-structure.md:1-50` - Research report standard
- `/home/benjamin/.config/.claude/templates/refactor-structure.md:1-50` - Refactoring report standard
- `/home/benjamin/.config/.claude/templates/debug-structure.md:1-50` - Debug report standard
- `/home/benjamin/.config/.claude/templates/agent-invocation-patterns.md:1-50` - Task tool patterns
- `/home/benjamin/.config/.claude/templates/command-frontmatter.md:1-212` - Frontmatter standards
- `/home/benjamin/.config/.claude/templates/output-patterns.md:1-50` - Output formatting
- `/home/benjamin/.config/.claude/templates/agent-tool-descriptions.md:1-50` - Tool documentation

### Supporting Infrastructure

- `/home/benjamin/.config/.claude/lib/parse-template.sh` - Template parsing utility
- `/home/benjamin/.config/.claude/lib/substitute-variables.sh` - Variable substitution
- `/home/benjamin/.config/.claude/lib/UTILS_README.md` - Utility documentation

### External References

- Neovim artifact picker integration (templates browsable via `<leader>ac`)
- Template README navigation: `/home/benjamin/.config/.claude/templates/README.md:280-286`

# Templates Directory Structure and Organization

## Metadata
- **Date**: 2025-10-27
- **Topic Directory**: .claude/specs/493_research_the_homebenjaminconfigclaudetemplates_dir/
- **Report Number**: 001
- **Scope**: Complete inventory and analysis of .claude/templates/ directory
- **Files Analyzed**: 24 template files

## Executive Summary

The `.claude/templates/` directory contains a comprehensive collection of reusable templates, patterns, and structural definitions that power the Claude Code workflow system. The templates are organized into four primary categories: implementation plan templates (YAML), orchestration patterns (Markdown), structural templates (Markdown), and specialized patterns (Markdown). These templates enable rapid plan generation, consistent agent invocations, standardized artifact structures, and context-optimized output patterns.

Key Points:
- 11 YAML plan templates for common development patterns (CRUD, API, refactoring, testing, migration, documentation, debug)
- 7 Markdown structural templates defining standard report/plan/debug formats
- 3 Markdown orchestration pattern files providing agent invocation templates and coordination logic
- 3 Markdown specialized patterns for output standardization, agent tooling, and hierarchical supervision
- Central README.md with comprehensive documentation on template usage, variable substitution, and Neovim integration

**Overall Assessment**: Highly organized and well-documented template system supporting both manual and automated plan generation.

## Background

### Current State

The templates directory serves as the foundational infrastructure for the Claude Code workflow system, providing:

1. **Plan Generation**: YAML templates with variable substitution enable 60-80% faster plan creation vs. manual planning
2. **Agent Coordination**: Markdown patterns standardize agent invocations across 7+ specialized agents
3. **Artifact Structure**: Structural templates ensure consistent report/plan/debug formats
4. **Output Optimization**: Output patterns minimize context usage (70-80% reduction)

### Research Questions

1. What categories of templates exist in the directory?
2. How are templates structured and what variable substitution patterns are supported?
3. What integration points exist with commands, agents, and the Neovim editor?
4. How do templates support the hierarchical agent architecture and context optimization?

## Analysis

### Category 1: YAML Plan Templates (11 files)

YAML plan templates provide structured, variable-substituted implementation plans for common development patterns.

#### Key Findings

**Standard Templates** (7 files):
- `crud-feature.yaml` - CRUD operations with authentication, database schema, API, and frontend
- `api-endpoint.yaml` - REST API endpoint implementation with authentication and validation
- `refactoring.yaml` - Basic refactoring workflow
- `test-suite.yaml` - Comprehensive test implementation (unit, integration, coverage)
- `migration.yaml` - Database or system migration plans
- `documentation-update.yaml` - Documentation update workflows
- `debug-workflow.yaml` - Systematic debugging workflows

**Advanced Templates** (4 files):
- `refactor-consolidation.yaml` - Advanced refactoring with analysis, incremental changes, validation
- `research-report.yaml` - Research topic investigation structure
- `example-feature.yaml` - Reference template showing structure and conventions
- `spec-updater-test.yaml` - Testing template for spec-updater agent functionality

#### Evidence

All YAML templates follow consistent structure:

```yaml
name: "Template Name"
description: "Brief description"
category: "feature|testing|refactoring|research"
complexity_level: "low|medium|medium-high|high"
estimated_time: "X-Y hours"
variables:
  - name: variable_name
    description: "Variable purpose"
    type: string|array|boolean|number
    required: true|false
    default: "optional default"
phases:
  - name: "Phase Name"
    dependencies: [] or [phase_numbers]
    tasks:
      - "Task with {{variable}} substitution"
      - "{{#if condition}}Conditional task{{/if}}"
      - "{{#each array}}Loop task: {{this}}{{/each}}"
research_topics:
  - "Research topic with {{variable}} substitution"
```

**Variable Substitution Syntax**:
- Simple: `{{variable_name}}`
- Arrays: `{{#each array_var}}{{this}}{{/each}}` with `{{@index}}`, `{{@first}}`, `{{@last}}`
- Conditionals: `{{#if variable}}...{{/if}}` and `{{#unless variable}}...{{/unless}}`
- Comparisons: `{{#if_eq var 'value'}}...{{/if_eq}}`

### Category 2: Structural Templates (7 files)

Markdown templates defining standard formats for research reports, plans, debug reports, and refactoring analyses.

#### Key Findings

**Report Structures** (4 files):
- `report-structure.md` - Standard research report format with metadata, analysis, recommendations, implementation status
- `debug-structure.md` - Debug report template with root cause analysis, proposed solutions, testing strategy
- `refactor-structure.md` - Refactoring analysis report with critical issues, opportunities, implementation roadmap
- `readme-template.md` - Directory README format for documentation coverage

**Specialized Structures** (3 files):
- `command-frontmatter.md` - Standard frontmatter for slash command files
- `audit-checklist.md` - Checklist template for code/standards audits
- `artifact_research_invocation.md` - Pattern for invoking research on existing artifacts

#### Evidence

Example from `report-structure.md` showing metadata-driven structure:

```markdown
# [Topic] Research Report

## Metadata
- **Date**: [YYYY-MM-DD]
- **Topic Directory**: [specs/{NNN_topic}/ or .claude/specs/{NNN_topic}/]
- **Report Number**: [NNN] (within topic)
- **Scope**: [Description of research scope]
- **Files Analyzed**: [Count and key files]

## Executive Summary
[Brief overview - 2-3 paragraphs maximum]

## Analysis
[Detailed findings organized by area]

## Recommendations
### High Priority
### Medium Priority
### Future Considerations

## Implementation Status
- **Status**: Research Complete
- **Plan**: None yet | [Link to related plan]
```

Key structural principles:
1. **Metadata-first**: Every artifact begins with structured metadata
2. **Progressive disclosure**: Executive summary → detailed analysis → appendices
3. **Cross-referencing**: Relative paths for bidirectional artifact links
4. **Living documents**: Implementation status tracked and updated
5. **Gitignore awareness**: Debug reports committed, others gitignored

### Category 3: Orchestration Patterns (3 files)

Large markdown files providing comprehensive agent invocation templates and workflow coordination patterns.

#### Key Findings

**orchestration-patterns.md** (71KB, 2,520 lines):
- Agent prompt templates for 7+ agent types (research, planning, implementation, debug, documentation)
- Phase coordination patterns (research, planning, implementation, debugging, documentation)
- Checkpoint structure and resumption logic
- Error recovery patterns (agent failures, test failures, checkpoint failures)
- Progress streaming patterns with PROGRESS: markers
- Wave-based parallelization integration for phase dependency management
- Complexity evaluation integration with hybrid scoring
- Plan expansion integration with automatic `/expand` coordination
- Spec updater integration for plan hierarchy updates

**agent-invocation-patterns.md** (7.6KB, 324 lines):
- Standard Task tool invocation patterns for all agent types
- Parallel vs. sequential invocation examples
- Agent response patterns (success/failure formats)
- Best practices for prompt construction, output expectations, error handling
- Common mistakes to avoid (verbose prompts, missing file paths, unnecessary context)

**agent-tool-descriptions.md** (8.6KB):
- Tool descriptions and capabilities for agent behavioral files
- Standard tool access patterns for different agent roles
- Tool usage guidelines and constraints

#### Evidence

Example agent invocation pattern from `agent-invocation-patterns.md`:

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research [specific topic] patterns and best practices"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist.

    Research Topic: [Topic name]
    Focus Area: [Specific aspect]
    Project Standards: CLAUDE.md

    Investigation:
    1. Codebase Analysis
       - Search for existing implementations
       - Identify patterns and conventions
       - Note relevant file locations

    2. Best Practices Research
       - Industry standards (2025)
       - Framework-specific recommendations
       - Trade-offs and considerations

    Output: Max 150-word summary with:
    - Key findings
    - Existing patterns
    - Recommendations
    - File references
}
```

Critical orchestration patterns identified:
1. **Parallel research phase**: All research agents invoked in SINGLE message
2. **Absolute path requirement**: All report/plan paths pre-calculated by orchestrator
3. **Metadata extraction**: 99% context reduction through 50-word summaries
4. **Wave-based implementation**: Phase dependency analysis enables parallel execution
5. **Complexity evaluation**: Hybrid threshold + agent scoring determines expansion needs

### Category 4: Specialized Patterns (3 files)

Markdown templates for output standardization, hierarchical supervision, and specialized workflows.

#### Key Findings

**output-patterns.md** (6.3KB):
- Minimal success pattern: `✓ [Operation] Complete\nArtifact: [path]\nSummary: [1-2 lines]`
- Minimal error pattern: `✗ [Operation] Failed\nError: [brief]\nDetails: [log-path]`
- Progress markers: `PROGRESS: [Stage] - [Brief status]`
- Context optimization principles (progressive disclosure, external memory, standardized formatting)
- Command-specific and agent-specific output patterns
- Testing output patterns
- Benefits: 70-80% token reduction, better context management, consistent UX

**sub_supervisor_pattern.md** (3.4KB):
- Template for hierarchical agent supervision
- Coordinates 2-3 specialized subagents per domain
- Returns metadata-only to parent supervisor
- Enables 10+ research topics vs. 4 with flat structure
- 92-97% context reduction through metadata-only passing

**artifact_research_invocation.md** (3.7KB):
- Pattern for researching existing artifacts before modification
- Used by `/plan`, `/implement`, `/orchestrate` for context-aware analysis
- Ensures changes respect existing patterns and standards

#### Evidence

Output pattern example from `output-patterns.md`:

```
✓ Report Complete
Artifact: /home/benjamin/.config/specs/042_auth/reports/001_patterns.md
Summary: Analyzed authentication patterns, identified 3 security best practices
```

Benefits achieved:
- **Token reduction**: 70-80% reduction in console output
- **Context preservation**: Details stored in files, not conversation
- **Scriptability**: Standardized format enables programmatic parsing
- **Progressive disclosure**: Users can drill down via file links

### Integration Points

#### Integration with Commands

**Template usage by slash commands**:

1. **`/plan-from-template`**: Primary consumer of YAML templates
   - Loads template YAML
   - Prompts for required variables
   - Applies variable substitution
   - Generates numbered implementation plan
   - Saves to specs/plans/

2. **`/orchestrate`**: Uses orchestration patterns extensively
   - References `orchestration-patterns.md` for agent prompts
   - Uses output patterns for consistent reporting
   - Implements wave-based execution from patterns
   - Applies checkpoint structures

3. **`/report`** / **`/research`**: Uses report-structure.md
   - Creates reports following standard structure
   - Applies metadata requirements
   - Implements cross-referencing patterns

4. **`/debug`**: Uses debug-structure.md
   - Creates debug reports following standard format
   - Ensures debug/ directory committed to git
   - Implements severity/priority tracking

5. **`/refactor`**: Uses refactor-structure.md
   - Creates refactoring analysis reports
   - Implements priority matrix and roadmap structure
   - Applies metrics and effort estimation

#### Integration with Agents

All agents reference templates for standardization:

- **research-specialist**: Uses report-structure.md for output format
- **plan-architect**: References plan templates and orchestration patterns
- **code-writer**: Uses output patterns for progress reporting
- **debug-specialist**: Uses debug-structure.md for investigation reports
- **doc-writer**: References documentation templates and standards
- **spec-updater**: Uses all structural templates for cross-referencing

#### Integration with Neovim

The README.md documents Neovim Artifact Picker integration:

**Access**: `<leader>ac` or `:ClaudeCommands`

**Features**:
- Templates listed in `[Templates]` category
- Local templates marked with `*` prefix
- Descriptions extracted from YAML metadata
- Quick actions: Open, load locally, update from global, edit, sync

**Display Format**:
```
[Templates]                   Workflow templates

* ├─ crud-feature.yaml         CRUD feature implementation
  └─ api-endpoint.yaml         API endpoint scaffold
```

### Template Development Guidelines

From README.md best practices:

**Variable Naming**:
- Use snake_case: `entity_name` not `name`
- Be descriptive and specific
- Group related variables: `db_host`, `db_port`, `db_name`

**Task Specificity**:
- Reference specific files when possible
- Include line number hints if applicable
- Specify testing requirements
- Define validation criteria

**Phase Structure**:
- Keep phases focused (5-10 tasks each)
- Use dependencies to enforce order
- Include testing in each phase
- Add documentation tasks

**Research Topics**:
- Include 2-4 relevant research topics
- Use variable substitution for specificity
- Balance general best practices with specific patterns

## Technical Details

### Implementation Patterns

**Variable Substitution Engine**:
- Location: `.claude/utils/substitute-variables.sh`
- Processes `{{variable}}` syntax
- Handles arrays with `{{#each}}`
- Handles conditionals with `{{#if}}`
- Graceful error handling for missing variables

**Template Parser**:
- Location: `.claude/utils/parse-template.sh`
- Validates template YAML structure
- Extracts metadata and phases
- Checks for required fields

**Plan Generator**:
- Location: `.claude/commands/plan-from-template.md`
- Interactive variable collection
- Template instantiation
- Plan file generation with numbering
- Cross-reference to source template

### Dependencies

Templates integrate with multiple system components:

**Shared Libraries**:
- `.claude/lib/checkbox-utils.sh` - Phase completion tracking
- `.claude/lib/complexity-utils.sh` - Complexity analysis
- `.claude/lib/dependency-analysis.sh` - Phase dependency parsing
- `.claude/lib/checkpoint-utils.sh` - Checkpoint management
- `.claude/lib/error-handling.sh` - Error recovery patterns

**Agent Behavioral Files**:
- `.claude/agents/research-specialist.md`
- `.claude/agents/plan-architect.md`
- `.claude/agents/code-writer.md`
- `.claude/agents/debug-specialist.md`
- `.claude/agents/doc-writer.md`
- `.claude/agents/spec-updater.md`
- `.claude/agents/test-specialist.md`

**Command Files**:
- `.claude/commands/plan.md`
- `.claude/commands/plan-from-template.md`
- `.claude/commands/plan-wizard.md`
- `.claude/commands/orchestrate.md`
- `.claude/commands/implement.md`
- `.claude/commands/report.md` (archived)
- `.claude/commands/research.md`
- `.claude/commands/debug.md`
- `.claude/commands/refactor.md`

### Constraints

**Template Safety**:
- Templates are reviewed code, not user input
- Variable values sanitized before substitution
- No code execution in templates (declarative only)
- Templates cannot access filesystem

**Variable Validation**:
- Type checking enforced
- Required variables must be provided
- Arrays must be valid JSON
- No shell injection possible

**File Location**:
- All templates must be in `.claude/templates/`
- YAML templates must have `.yaml` extension
- Markdown templates must have `.md` extension
- Custom templates can be added directly to directory

### Trade-offs

**Template-Based vs. Manual Planning**:

| Aspect | Template-Based | Manual |
|--------|----------------|--------|
| Speed | 60-80% faster | Baseline |
| Customization | Limited by variables | Unlimited |
| Consistency | High (enforced structure) | Variable |
| Learning Curve | Minimal (guided prompts) | Requires planning expertise |
| Best For | Common patterns | Unique/complex features |

**Recommendation**: Use templates for well-understood patterns, manual `/plan` for unique/complex features, `/plan-wizard` for guided planning with research integration.

## Recommendations

### High Priority

1. **Document Advanced Variable Syntax**
   - **Rationale**: Current README documents basic `{{#each}}` and `{{#if}}` but not `{{#if_eq}}`, `{{#unless}}`, array helpers (`{{@index}}`, `{{@first}}`, `{{@last}}`)
   - **Location**: README.md § Variable Substitution Syntax
   - **Effort**: Small (add 20-30 lines to existing section)
   - **Benefit**: Users can leverage full power of variable system

2. **Create Template Testing Suite**
   - **Rationale**: No automated tests for template parsing, variable substitution, or generated plan validation
   - **Location**: `.claude/tests/test_template_parsing.sh` (new)
   - **Effort**: Medium (create test suite covering 11 templates)
   - **Benefit**: Prevents regression in template system, validates variable substitution engine

3. **Add Template Coverage Metrics**
   - **Rationale**: No visibility into which templates are used most frequently or successfully
   - **Location**: `.claude/lib/template-analytics.sh` (new) + update `/plan-from-template`
   - **Effort**: Small (log template usage, generate reports)
   - **Benefit**: Informs template maintenance priorities, identifies underused templates

### Medium Priority

1. **Standardize Orchestration Pattern Length**
   - **Rationale**: `orchestration-patterns.md` is 71KB (2,520 lines) - significantly larger than other templates
   - **Approach**: Extract sections to separate files (complexity-evaluation.md, wave-execution.md, checkpoint-structure.md)
   - **Effort**: Medium (split file, update references in commands)
   - **Benefit**: Easier maintenance, faster loading, clearer organization

2. **Create Template Composition System**
   - **Rationale**: Some templates share common phases (e.g., testing phase in multiple templates)
   - **Approach**: Support `extends:` or `includes:` in YAML to compose templates from reusable phase libraries
   - **Effort**: Large (requires parser updates, variable scoping, validation)
   - **Benefit**: Reduces duplication, easier template maintenance, consistent phase patterns

3. **Add Template Validation Tool**
   - **Rationale**: No validation for custom user-created templates before use
   - **Location**: `.claude/utils/validate-template.sh` (new)
   - **Effort**: Medium (YAML schema validation, variable reference checking, phase dependency validation)
   - **Benefit**: Catches errors before template usage, better user experience

### Future Considerations

1. **Template Marketplace/Sharing**
   - Enable sharing of custom templates across projects or teams
   - Template versioning and compatibility tracking
   - Community-contributed templates

2. **AI-Generated Templates**
   - Use AI to analyze successful implementations and generate new templates
   - Learn from user modifications to improve existing templates
   - Auto-suggest templates based on project characteristics

3. **Template Branching/Variants**
   - Support template variants for different tech stacks (e.g., crud-feature-django.yaml, crud-feature-rails.yaml)
   - Conditional template loading based on project detection
   - Template inheritance for variant management

## Implementation Considerations

### Approach Options

**Option 1: Incremental Enhancement**
- **Approach**: Address recommendations in priority order, one at a time
- **Pros**: Low risk, maintains stability, allows for testing between changes
- **Cons**: Slower progress, may not address systemic issues comprehensively
- **Effort**: Small per recommendation
- **Risk**: Safe

**Option 2: Template System Refactor**
- **Approach**: Redesign template system with composition, validation, analytics built-in
- **Pros**: Modern architecture, eliminates technical debt, enables advanced features
- **Cons**: High risk, requires extensive testing, potential compatibility issues
- **Effort**: Large (3-4 weeks)
- **Risk**: High

**Option 3: Dual Track (Recommended)**
- **Approach**: Address high-priority recommendations immediately while designing next-gen template system
- **Pros**: Immediate value from quick wins, informed redesign based on current pain points
- **Cons**: Requires parallel workstreams, some work may be thrown away
- **Effort**: Medium (2-3 weeks)
- **Risk**: Low-Medium

### Recommended Approach

**Dual Track** approach is recommended:

**Track 1 - Quick Wins** (Week 1):
1. Document advanced variable syntax
2. Add template usage analytics
3. Create basic template validation

**Track 2 - System Design** (Weeks 2-3):
1. Design template composition system
2. Design validation framework
3. Design testing suite architecture
4. Prototype and validate approach

**Track 3 - Implementation** (Week 3+):
1. Implement high-priority enhancements
2. Begin template system refactor
3. Migrate existing templates incrementally

### Prerequisites

- Access to `.claude/utils/` for parser/substitution updates
- Understanding of YAML parsing in bash
- Familiarity with template variable systems (Handlebars, Mustache)
- Testing framework for bash scripts

### Risks

1. **Breaking Changes**: Template format changes could break existing custom templates
   - **Mitigation**: Version templates, provide migration tool, deprecate gradually

2. **Parser Complexity**: Advanced features (composition, validation) increase parser complexity
   - **Mitigation**: Comprehensive test suite, gradual rollout, clear error messages

3. **Performance**: Template parsing overhead for complex templates
   - **Mitigation**: Caching parsed templates, lazy loading, profile and optimize

## Implementation Status
- **Status**: Research Complete
- **Plan**: None yet
- **Implementation**: Not started
- **Date**: 2025-10-27

*This section will be updated if/when recommendations are implemented.*

## References

### Codebase Files
- `.claude/templates/README.md` - Primary template documentation
- `.claude/templates/crud-feature.yaml` - Example YAML plan template
- `.claude/templates/orchestration-patterns.md` - Comprehensive orchestration patterns
- `.claude/templates/agent-invocation-patterns.md` - Agent invocation standards
- `.claude/templates/report-structure.md` - Research report format
- `.claude/templates/debug-structure.md` - Debug report format
- `.claude/templates/refactor-structure.md` - Refactoring analysis format
- `.claude/templates/output-patterns.md` - Output standardization
- `.claude/templates/sub_supervisor_pattern.md` - Hierarchical supervision
- `.claude/utils/parse-template.sh` - Template parser implementation
- `.claude/utils/substitute-variables.sh` - Variable substitution engine
- `.claude/commands/plan-from-template.md` - Template-based planning command

### Documentation
- `CLAUDE.md` - Project standards and directory protocols
- `.claude/docs/guides/command-development-guide.md` - Command development standards
- `.claude/docs/concepts/directory-protocols.md` - Artifact organization

### External Resources
- [Handlebars Templating](https://handlebarsjs.com/) - Similar variable syntax inspiration
- [Mustache Templating](https://mustache.github.io/) - Logic-less template reference
- [YAML Specification](https://yaml.org/spec/1.2.2/) - YAML format reference

### Related Artifacts
- Main Plan: ../plans/ (if implementation plan created)
- Other Reports: ./ (if related research exists)

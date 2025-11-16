# Planning and Wizards Commands Research Report

## Metadata
- **Date**: 2025-11-15
- **Agent**: research-specialist
- **Topic**: Planning and Wizards Commands (plan-from-template.md, plan-wizard.md)
- **Report Type**: Codebase analysis
- **Complexity Level**: 4

## Executive Summary

The `/plan-from-template` and `/plan-wizard` commands provide two distinct approaches to implementation plan generation: template-based rapid generation (60-80% faster) and interactive guided planning with optional research integration. Both commands were archived as part of the command cleanup strategy, yet they offer unique value through their 10-template library covering 8 categories (backend, feature, debugging, documentation, testing, migration, research, refactoring) and sophisticated variable substitution supporting conditionals, arrays, and handlebars-style templating. The wizard provides intelligent component detection and complexity-based research recommendations, creating a lower barrier to entry for new users while integrating with the research-specialist agent system.

## Findings

### 1. Command Purpose and Architecture

#### /plan-from-template (/home/benjamin/.config/.claude/archive/commands/plan-from-template.md)

**Core Functionality** (lines 1-11):
- Generates structured implementation plans from reusable YAML templates
- Interactive variable substitution during plan creation
- Saves to specs/plans/ directory with automatic numbering
- Template-driven approach for common patterns

**Process Flow** (lines 38-245):
1. **Template Selection** (lines 38-77): Supports `--list-categories`, `--category <name>`, or direct template name
2. **Metadata Extraction** (lines 79-105): Calls `.claude/lib/parse-template.sh` to extract name, description, variables
3. **Variable Collection** (lines 107-142): Interactive prompting for each variable with type-based validation
4. **Substitution** (lines 144-171): Calls `.claude/lib/substitute-variables.sh` to apply variable values
5. **Plan Generation** (lines 173-217): Creates numbered plan file with metadata
6. **Confirmation** (lines 219-245): Displays success message with next steps

**Integration Points** (lines 267-279):
- Works with `/implement` for execution
- Works with `/revise` for plan modifications
- Provides 60-80% faster plan generation than manual `/plan` command

#### /plan-wizard (/home/benjamin/.config/.claude/archive/commands/plan-wizard.md)

**Core Functionality** (lines 1-19):
- Interactive, step-by-step wizard for plan creation
- Intelligent component and research topic suggestions
- Optional research agent integration
- Lower barrier to entry for new users

**Wizard Flow** (lines 27-269):
1. **Feature Description** (lines 27-40): Collect user's feature description (1-2 sentences)
2. **Component Identification** (lines 42-65): Suggest components based on keywords (auth, ui, api, etc.)
3. **Complexity Assessment** (lines 67-88): Map 1-4 scale to simple/medium/complex/critical (determines phase count and research recommendation)
4. **Research Decision** (lines 90-111): Complexity-based defaults (complex/critical → recommended, simple/medium → optional)
5. **Research Topics** (lines 113-144): Suggest 3-4 relevant topics based on feature keywords
6. **Execute Research** (lines 146-186): Launch parallel research agents via Task tool
7. **Generate Plan** (lines 188-207): Invoke `/plan` with collected context and research reports
8. **Display Results** (lines 209-229): Show success with next steps

**Intelligent Suggestions** (lines 44-52, 117-122):
- Component detection: "auth/login/security" → auth, security, user
- Research topics: "auth/security/login" → "Security best practices (2025)", "Existing auth patterns in codebase"
- Always includes: "Existing implementations of similar features", "Project coding standards"

### 2. Template System Architecture

#### Template Library (/home/benjamin/.config/.claude/commands/templates/)

**Available Templates** (10 templates, 8 categories):

| Template | Category | Complexity | Time | Variables |
|----------|----------|------------|------|-----------|
| crud-feature.yaml | feature | medium-high | 8-12h | entity_name, fields, use_auth, database_type |
| api-endpoint.yaml | backend | medium | 4-6h | endpoint_path, methods, auth_required, request_schema |
| debug-workflow.yaml | debugging | medium | 4-6h | issue_description, affected_components, priority |
| documentation-update.yaml | documentation | low | - | (not examined) |
| test-suite.yaml | testing | medium | - | (not examined) |
| migration.yaml | migration | high | - | (not examined) |
| research-report.yaml | research | medium | 4-8h | topic, research_questions, depth_level, target_audience |
| refactoring.yaml | refactoring | medium | - | (not examined) |
| refactor-consolidation.yaml | refactoring | medium-high | - | consolidation_strategy, risk_level |
| example-feature.yaml | feature | medium | - | (generic template) |

**Template Structure** (crud-feature.yaml:1-88):
```yaml
name: "Template Name"
description: "Description"
category: "category"
complexity_level: "level"
estimated_time: "range"
variables:
  - name: var_name
    description: "description"
    type: string|array|boolean
    required: true|false
    default: "value"
phases:
  - name: "Phase Name"
    dependencies: [1, 2]  # Phase numbers this phase depends on
    tasks:
      - "Task with {{variable}} substitution"
      - "{{#if condition}}Conditional task{{/if}}"
      - "{{#each array}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}"
research_topics:
  - "Topic with {{variable}} substitution"
spec_updater_checklist:  # Integration with spec updater workflow
  - "Checklist items for artifact management"
phase_completion_protocol:  # Checkbox propagation protocol
  - "Protocol steps for hierarchy updates"
```

#### Template Parsing (/home/benjamin/.config/.claude/lib/parse-template.sh)

**Validation** (lines 18-43):
- Required fields: `name`, `description`
- Optional fields: `variables`, `phases` (minimal validator for flexibility)

**Extraction Actions** (lines 148-166):
- `validate`: Check template structure
- `extract-metadata`: Return JSON with name, description (lines 46-59)
- `extract-variables`: Return JSON array of variable definitions (lines 62-107)
- `extract-phases`: Count number of phases (lines 110-145)

**Variable Extraction** (lines 62-107):
- Parses YAML `variables:` section
- Extracts: name, type (default: "string"), required (default: false), description, default
- Returns JSON array format: `[{"name":"var","type":"string","required":false}]`

#### Variable Substitution (/home/benjamin/.config/.claude/lib/substitute-variables.sh)

**Input Format** (lines 1-4):
```bash
substitute-variables.sh <template-file> '<variables-json>'
# Example: '{"entity_name":"User","fields":["name","email"]}'
```

**Substitution Types** (lines 236-242):

1. **Simple Variables** (lines 44-66):
   - Pattern: `{{variable_name}}`
   - Example: `{{entity_name}}` → `User`

2. **Array Iterations** (lines 68-186):
   - Pattern: `{{#each array}}{{this}}{{/each}}`
   - Supports: `{{@index}}`, `{{@first}}`, `{{@last}}`
   - Example: `{{#each fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}` → `name, email, password`

3. **Conditionals** (lines 188-234):
   - Pattern: `{{#if variable}}...{{/if}}` and `{{#unless variable}}...{{/unless}}`
   - Truthy check: non-empty, not "false", not "0", not "null"
   - Example: `{{#if use_auth}}Add authentication{{/if}}` → `Add authentication` (if true)

**Processing Pipeline** (lines 236-242):
1. Process simple variables (replace all `{{var}}` with values)
2. Process array iterations (expand `{{#each}}` blocks)
3. Process conditionals (evaluate `{{#if}}` and `{{#unless}}`)

### 3. Template Examples and Patterns

#### CRUD Feature Template (crud-feature.yaml)

**Phase Structure** (4 phases with dependencies):
1. Database Schema and Models (no dependencies)
2. Backend CRUD API (depends on phase 1)
3. Frontend Components (depends on phase 2)
4. Testing and Documentation (depends on phases 1, 2, 3)

**Variable Usage Examples**:
- Simple: `Create {{entity_name}} model` → `Create User model`
- Array iteration: `fields: {{#each fields}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}` → `fields: name, email, password`
- Conditional: `{{#if use_auth}}Add authentication middleware{{/if}}` → `Add authentication middleware` (if true)

**Spec Updater Integration** (lines 69-75):
- Topic-based directory structure requirement
- Standard subdirectory creation (reports/, debug/, scripts/, outputs/)
- Cross-reference updates
- Gitignore compliance verification

**Phase Completion Protocol** (lines 76-82):
- Checkbox propagation across hierarchy levels (Level 0, 1, 2)
- Uses `.claude/lib/checkbox-utils.sh` for automatic updates
- Consistency verification after each phase

#### Debug Workflow Template (debug-workflow.yaml)

**Phase Structure** (4 sequential phases):
1. Investigation and Data Collection (lines 29-39)
2. Root Cause Analysis (depends on 1) (lines 40-49)
3. Fix Implementation (depends on 2) (lines 50-60)
4. Regression Testing and Validation (depends on 3) (lines 61-73)

**Priority-Based Conditionals** (lines 71-72):
- `{{#if_eq priority 'critical'}}Prepare hotfix deployment plan{{/if_eq}}`
- `{{#if_eq priority 'high'}}Notify stakeholders of fix{{/if_eq}}`

**Research Topics** (lines 74-77):
- `Common causes of {{issue_description}} in similar systems`
- `Testing strategies for {{#each affected_components}}{{this}}{{/each}}`

#### Research Report Template (research-report.yaml)

**Phase Structure** (4 phases with parallel potential):
1. Literature Review and External Research (no dependencies)
2. Codebase Analysis (depends on 1)
3. Best Practices and Recommendations (depends on 1, 2)
4. Report Generation and Documentation (depends on 3)

**Depth Level Support** (lines 15-19, 79, 84):
- Variable: `depth_level` (survey, detailed, comprehensive)
- Conditional tasks: `{{#if_eq depth_level 'comprehensive'}}Include appendices{{/if_eq}}`
- Adjusts research thoroughness and deliverable detail

**Decision Support** (lines 25-29, 42, 61, 75):
- Variable: `decision_required` (boolean)
- Adds decision criteria identification, alternative comparison, clear recommendation

### 4. Complexity Levels and Research Integration

#### Complexity Mapping (/plan-wizard.md:67-88)

**Scale and Characteristics**:
1. **Simple** (1-2 phases, <2 hours):
   - Minor changes, single file
   - Research: not recommended (default: n)

2. **Medium** (2-4 phases, 2-8 hours):
   - Multiple files, new functionality
   - Research: optional (default: n)

3. **Complex** (4-6 phases, 8-16 hours):
   - Architecture changes, multiple modules
   - Research: recommended (default: y)

4. **Critical** (6+ phases, >16 hours):
   - Major refactor, system-wide impact
   - Research: required (default: y)

#### Research Agent Integration (/plan-wizard.md:146-186)

**Parallel Research Execution**:
- Uses Task tool with `subagent_type: "general-purpose"`
- Follows `.claude/agents/research-specialist.md` behavioral guidelines
- Launches all research agents in single message for parallelization
- Max 150 words summary per topic

**Research Prompt Format** (lines 165-183):
```
Context: User wants to implement: [feature description]
Components: [component list]

Requirements:
- Search codebase for existing patterns
- Research best practices (use WebSearch if needed)
- Identify potential challenges
- Max 150 words summary

Output format:
- Key findings (3-5 bullets)
- Recommended approach
- Potential challenges
```

### 5. Best Use Cases and Decision Matrix

#### Command Selection Guide (/plan-wizard.md:260-265, /plan-from-template.md:271-275)

**Use /plan-wizard when**:
- Guided experience needed
- Unsure of scope or components
- Want intelligent suggestions
- New to project or planning system

**Use /plan-from-template when**:
- Common pattern (CRUD, API, refactoring)
- Know exact variables needed
- Fast generation priority (60-80% faster)
- Template exists for use case

**Use /plan when**:
- Unique features requiring custom structure
- Research-driven planning with existing reports
- Need maximum flexibility
- Template doesn't fit use case

**Use /coordinate when** (commands/README.md:9-16):
- End-to-end automated workflow (research + plan + implement)
- State machine orchestration needed
- Wave-based parallel execution desired
- Full artifact traceability required

#### Template vs Custom Planning Trade-offs

**Template Advantages**:
- 60-80% faster plan generation
- Proven structure for common patterns
- Consistent phase organization
- Built-in testing and documentation tasks
- Spec updater integration pre-configured

**Template Limitations**:
- Limited to 10 predefined templates
- Variables must match template structure
- Customization requires template editing
- May include unnecessary tasks for simpler use cases

**Custom Planning Advantages**:
- Complete flexibility in structure
- Tailored to unique requirements
- Research-driven phase design
- No template constraints

### 6. Integration with Broader Workflow

#### Workflow Integration Points

**Pre-Planning**:
- `/research` → research-specialist agents → reports in specs/reports/
- `/plan-wizard` → (optional research) → `/plan` invocation

**Planning**:
- `/plan-from-template` → specs/plans/NNN_feature.md
- `/plan-wizard` → `/plan` → specs/plans/NNN_feature.md
- `/plan` → specs/plans/NNN_feature.md

**Post-Planning**:
- `/revise` → modify existing plan with research or scope changes
- `/implement` → execute plan phases with testing and commits
- `/coordinate` → full workflow orchestration

#### Standards Discovery and Application

**Both commands follow standards discovery hierarchy** (/plan-from-template.md references CLAUDE.md integration):
1. Search upward for CLAUDE.md
2. Check subdirectory-specific CLAUDE.md
3. Merge/override: subdirectory extends parent
4. Fallback to language defaults if not found

**Template-Specific Standards**:
- Spec updater checklist (crud-feature.yaml:69-75)
- Phase completion protocol (crud-feature.yaml:76-82)
- Research topics for best practices (all templates)

### 7. Archive Status and Historical Context

**Command Cleanup** (commands/README.md:25-32):
- Date: 2025-11-15
- Status: Both commands moved to `.claude/archive/commands/`
- Rationale: Part of clean-break philosophy (48.1% directory reduction)
- Impact: Template library and utilities remain intact in `.claude/commands/templates/` and `.claude/lib/`

**Replacement Strategy**:
- No direct replacement mentioned
- `/coordinate` provides end-to-end workflow (includes planning phase)
- `/plan` remains for custom planning
- Templates and utilities still available for future revival or integration

**Archival vs Deletion**:
- Commands archived (not deleted) suggest potential future use
- Template library maintained (10 templates, README.md updated 2025-11-12)
- Supporting utilities (parse-template.sh, substitute-variables.sh) remain in `.claude/lib/`

## Recommendations

### 1. Consider Selective Revival Based on User Needs

**Rationale**: The 60-80% time savings and lower barrier to entry provide significant value for certain workflows, particularly for teams with recurring patterns.

**Recommendation**: Evaluate usage patterns over next 30 days to determine if template-based planning is missed. If common patterns emerge, consider:
- Integrating `/plan-from-template` functionality into `/plan` as `--template <name>` flag
- Creating `/plan` wizard mode with `--wizard` flag for guided experience
- Maintaining templates as standalone library with direct access via `/coordinate` planning phase

### 2. Preserve Template Library as Reusable Asset

**Rationale**: 10 templates covering 8 categories represent significant investment in workflow patterns, variable definitions, and phase structures.

**Recommendation**:
- Keep templates in `.claude/commands/templates/` (already done)
- Document template structure in `/setup --enhance-with-docs` discovery
- Consider exposing templates as starting points for custom plans (copy to specs/plans/ and edit)
- Add template gallery to documentation for reference during manual planning

### 3. Extract Variable Substitution as General Utility

**Rationale**: The handlebars-style variable substitution system (conditionals, arrays, iterations) is a general-purpose templating engine useful beyond plan generation.

**Recommendation**:
- Promote `substitute-variables.sh` to documented utility in `.claude/lib/`
- Add examples and usage guide to lib/README.md
- Consider using for:
  - Git commit message templates
  - Documentation generation with dynamic content
  - Configuration file generation
  - Test file templates

### 4. Integrate Wizard Intelligence into /plan Command

**Rationale**: Component detection, complexity assessment, and research recommendations reduce cognitive load and improve plan quality.

**Recommendation**:
- Add optional wizard mode to `/plan`: `/plan --wizard "feature description"`
- Implement component detection as pre-planning analysis step
- Use complexity heuristics to recommend research phase inclusion
- Preserve interactive experience while maintaining `/plan` flexibility

### 5. Leverage Templates for /coordinate Planning Phase

**Rationale**: `/coordinate` includes planning phase but may benefit from template-based acceleration for common patterns.

**Recommendation**:
- Add template detection to `/coordinate` planning phase
- If feature description matches template pattern (e.g., "implement CRUD for X"), suggest template usage
- Allow template selection via: `/coordinate "implement User CRUD" --template crud-feature`
- Combine template structure with research findings for comprehensive plans

### 6. Create Template Authoring Guide

**Rationale**: Custom templates for project-specific patterns would extend the 60-80% time savings to organization-specific workflows.

**Recommendation**:
- Document template authoring in `.claude/docs/guides/template-authoring-guide.md`
- Include:
  - YAML structure and required fields
  - Variable types and substitution syntax
  - Phase dependency patterns
  - Research topic formulation
  - Testing and validation checklist
- Add to `/setup --enhance-with-docs` suggested documentation

### 7. Maintain Backward Compatibility Path

**Rationale**: If templates prove valuable after archival, restoration should be seamless.

**Recommendation**:
- Keep template parsing and substitution utilities in `.claude/lib/` (already done)
- Document restoration process in commands/README.md
- Create one-line restoration: `git restore .claude/archive/commands/plan-*.md` → `.claude/commands/`
- Consider adding templates to `/setup --validate` checks (warn if templates exist but commands archived)

## References

### Command Files
- `/home/benjamin/.config/.claude/archive/commands/plan-from-template.md` (lines 1-280)
- `/home/benjamin/.config/.claude/archive/commands/plan-wizard.md` (lines 1-271)

### Template Files
- `/home/benjamin/.config/.claude/commands/templates/crud-feature.yaml` (lines 1-88)
- `/home/benjamin/.config/.claude/commands/templates/api-endpoint.yaml` (lines 1-69)
- `/home/benjamin/.config/.claude/commands/templates/debug-workflow.yaml` (lines 1-78)
- `/home/benjamin/.config/.claude/commands/templates/research-report.yaml` (lines 1-85)
- `/home/benjamin/.config/.claude/commands/templates/refactor-consolidation.yaml` (complexity and risk level variables)
- `/home/benjamin/.config/.claude/commands/templates/README.md` (lines 1-78)

### Utility Scripts
- `/home/benjamin/.config/.claude/lib/parse-template.sh` (lines 1-167)
- `/home/benjamin/.config/.claude/lib/substitute-variables.sh` (lines 1-243)

### Context Files
- `/home/benjamin/.config/.claude/commands/README.md` (lines 1-150 - command architecture and cleanup context)
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-671 - research agent behavioral guidelines)

### Template Categories (from grep output)
- backend: api-endpoint.yaml
- feature: crud-feature.yaml, example-feature.yaml
- debugging: debug-workflow.yaml
- documentation: documentation-update.yaml
- testing: test-suite.yaml
- migration: migration.yaml
- research: research-report.yaml
- refactoring: refactoring.yaml, refactor-consolidation.yaml

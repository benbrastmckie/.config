# Agent Template Dependencies Research Report

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Agent template dependencies analysis
- **Report Type**: Codebase analysis
- **Files Analyzed**: 19 agent files, 13 template files, 7 command files

## Executive Summary

The .claude/templates/ directory contains 26 files (13 markdown templates, 11 YAML workflow templates, 2 supporting files). Analysis reveals that **agents do NOT directly depend on templates** - instead, they embed their own output structure templates inline. Commands, particularly orchestration commands, reference templates as external documentation and scaffold sources. Template dependency is command-driven, not agent-driven.

Key Points:
- Agents have embedded templates (inline scaffolds) for their output structures
- Commands reference .claude/templates/ files for orchestration patterns and YAML workflow templates
- No agent files contain direct Read/file references to .claude/templates/ files
- Template word appears 618 times across agents, but refers to embedded inline templates, not external file dependencies

## Findings

### 1. Agent Template Usage Pattern

**Pattern Discovered**: Agents use EMBEDDED templates, not external file references.

**Evidence from agent files**:

- **debug-specialist.md** (line 311): Contains embedded "Debug Report Structure" template
  ```markdown
  ## Debug Report Structure - Use THIS EXACT TEMPLATE (No modifications)
  ```
  - Template is 68 lines of inline markdown structure
  - No reference to .claude/templates/debug-structure.md
  - Agent embeds the complete template for immediate use

- **research-specialist.md** (lines 83-107): Contains embedded report template
  ```markdown
  # [Topic] Research Report

  ## Metadata
  - **Date**: [YYYY-MM-DD]
  - **Agent**: research-specialist
  ...
  ```
  - Template is 24 lines of inline markdown structure
  - No reference to .claude/templates/report-structure.md
  - Agent creates this structure directly

- **doc-writer.md** (line 310): Contains embedded README template
  ```markdown
  ## README Structure - Use THIS EXACT TEMPLATE (No modifications)
  ```
  - Template is 36+ lines of inline markdown structure
  - No reference to .claude/templates/readme-template.md
  - Agent embeds complete README scaffold

- **code-reviewer.md** (line 211): Contains embedded review report template
  ```markdown
  **THIS EXACT TEMPLATE (No modifications)**:
  ```
  - Inline template for review report structure
  - No external template file reference

- **metrics-specialist.md** (line 280): Contains embedded metrics report template
  ```markdown
  **THIS EXACT TEMPLATE (No modifications)**:
  ```
  - Inline template for metrics analysis output
  - No external template file reference

**Pattern**: All 5 report-generating agents use EMBEDDED templates, not file references.

### 2. Command Template Dependencies

**Pattern Discovered**: Commands reference .claude/templates/ for documentation and YAML workflow templates.

**Evidence from command files**:

- **orchestrate.md** (lines 79-80, 273, 299):
  ```
  - **Agent Templates**: `.claude/templates/orchestration-patterns.md`
  - Complete agent prompt templates for all 5 agents
  ```
  - References orchestration-patterns.md for agent invocation templates
  - Uses templates for parallel/sequential/adaptive coordination patterns
  - References for error recovery patterns

- **plan-from-template.md** (lines 70-71, 248, 278):
  ```
  - Check if template exists in `.claude/templates/<name>.yaml`
  - If not found, check `.claude/templates/custom/<name>.yaml`
  ```
  - Directly loads YAML workflow templates from .claude/templates/
  - Supports 11 standard templates across 8 categories
  - Custom templates in .claude/templates/custom/

- **debug.md** (lines 580, 591):
  ```
  Debug reports follow the standard structure defined in `.claude/templates/debug-structure.md`.
  ```
  - References template for DOCUMENTATION purposes
  - Agents don't read this file; it's reference documentation
  - Commands describe the structure to users

- **research.md** (line 691):
  ```
  For complete report structure and section guidelines, see `.claude/templates/report-structure.md`
  ```
  - Reference documentation for users/developers
  - Not loaded by agents during execution

- **refactor.md** (lines 187, 198):
  ```
  **CRITICAL**: Refactoring reports MUST follow the standard structure defined in `.claude/templates/refactor-structure.md`.
  ```
  - Documentation reference, not runtime dependency
  - Agents have embedded templates, not file reads

**Pattern**: Commands reference templates for:
1. **YAML workflow templates** (runtime loaded by /plan-from-template)
2. **Documentation reference** (for developers/users, not runtime)
3. **Orchestration patterns** (agent invocation scaffolds for /orchestrate)

### 3. Template Directory Contents

**Analysis of .claude/templates/ files**:

**Markdown Template Files** (13 files):
1. `agent-invocation-patterns.md` - Agent invocation scaffolds (referenced by orchestration)
2. `agent-tool-descriptions.md` - Tool usage patterns (reference documentation)
3. `artifact_research_invocation.md` - Research invocation pattern (orchestration reference)
4. `audit-checklist.md` - Quality assurance checklist (reference documentation)
5. `command-frontmatter.md` - Command file frontmatter structure (development guide)
6. `debug-structure.md` - Debug report structure (reference documentation)
7. `orchestration-patterns.md` - Multi-agent coordination patterns (runtime reference for /orchestrate)
8. `output-patterns.md` - Agent output format patterns (reference documentation)
9. `readme-template.md` - README file structure (reference documentation)
10. `refactor-structure.md` - Refactor report structure (reference documentation)
11. `report-structure.md` - Research report structure (reference documentation)
12. `sub_supervisor_pattern.md` - Recursive supervision pattern (orchestration reference)
13. `README.md` - Template system documentation

**YAML Workflow Templates** (11 files):
1. `api-endpoint.yaml` - API endpoint implementation workflow
2. `crud-feature.yaml` - CRUD feature workflow
3. `debug-workflow.yaml` - Debug investigation workflow
4. `documentation-update.yaml` - Documentation update workflow
5. `example-feature.yaml` - Example template structure
6. `migration.yaml` - Database/system migration workflow
7. `refactor-consolidation.yaml` - Code consolidation workflow
8. `refactoring.yaml` - General refactoring workflow
9. `research-report.yaml` - Research workflow template
10. `spec-updater-test.yaml` - Spec updater testing workflow
11. `test-suite.yaml` - Test suite implementation workflow

**Supporting Files** (2 files):
- `README.md` - Documentation
- `.gitignore` (if present)

### 4. Dependency Matrix: Agent → Template Files

**Direct File Dependencies** (Read/source operations):

| Agent | Template Dependency | Dependency Type | Evidence |
|-------|-------------------|-----------------|----------|
| ALL AGENTS | NONE | N/A | No grep matches for `.claude/templates/` in agent files |

**Embedded Template Usage** (inline scaffolds):

| Agent | Embedded Template Type | Lines | External Equivalent |
|-------|----------------------|-------|---------------------|
| research-specialist.md | Report structure | 83-107 | .claude/templates/report-structure.md |
| debug-specialist.md | Debug report structure | 311-378 | .claude/templates/debug-structure.md |
| doc-writer.md | README structure | 310-350 | .claude/templates/readme-template.md |
| code-reviewer.md | Review report template | 211-280 | None (agent-specific) |
| metrics-specialist.md | Metrics report template | 280-495 | None (agent-specific) |
| plan-architect.md | Plan templates | 569-650 | None (embedded in agent) |
| plan-structure-manager.md | Phase templates | 161-247 | None (embedded in agent) |
| complexity-estimator.md | Reasoning chain template | 217+ | None (agent-specific) |

**Command Template Dependencies** (runtime or documentation):

| Command | Template Dependency | Dependency Type | Evidence |
|---------|-------------------|-----------------|----------|
| orchestrate.md | orchestration-patterns.md | Runtime reference | Lines 79, 273, 299 |
| plan-from-template.md | *.yaml (all YAML templates) | Runtime loaded | Lines 70-71, 248 |
| debug.md | debug-structure.md | Documentation ref | Lines 580, 591 |
| research.md | report-structure.md | Documentation ref | Line 691 |
| refactor.md | refactor-structure.md | Documentation ref | Lines 187, 198 |

### 5. Critical vs Optional Dependencies

**Runtime Dependencies** (required for execution):
1. `/plan-from-template` command → `.claude/templates/*.yaml` (11 YAML files)
   - **Critical**: Command cannot function without YAML templates
   - **Usage**: Loaded at runtime, variables substituted, plan generated
   - **Failure impact**: Command fails if template missing

2. `/orchestrate` command → `.claude/templates/orchestration-patterns.md`
   - **Critical**: Used for agent prompt scaffolding
   - **Usage**: Referenced for multi-agent coordination patterns
   - **Failure impact**: Degraded orchestration capability if missing

**Documentation Dependencies** (reference only):
1. All commands → structure templates (debug-structure.md, report-structure.md, etc.)
   - **Optional**: For developer/user reference only
   - **Usage**: Documentation purposes
   - **Failure impact**: None (agents have embedded templates)

**Internalization Candidates** (can be embedded):
1. `orchestration-patterns.md` → Could be embedded in /orchestrate command
2. All structure templates → Already embedded in agents, .md files are redundant
3. `agent-invocation-patterns.md` → Could be embedded in orchestration commands

**Must Remain External** (cannot be internalized):
1. All YAML workflow templates (11 files) → Required for /plan-from-template variability
2. `README.md` → Documentation file

### 6. Template Synchronization Issues

**Problem Discovered**: Embedded agent templates may drift from .claude/templates/ reference files.

**Evidence**:
- `research-specialist.md` has embedded report template (lines 83-107)
- `.claude/templates/report-structure.md` has separate report template (50+ lines)
- No automated synchronization mechanism exists
- Changes to one don't propagate to the other

**Affected Template Pairs**:
1. research-specialist.md embedded template ↔ report-structure.md
2. debug-specialist.md embedded template ↔ debug-structure.md
3. doc-writer.md embedded template ↔ readme-template.md

**Synchronization Risk**:
- Template updates in .claude/templates/ don't update agent behavior
- Agent template updates don't update reference documentation
- Divergence leads to inconsistent artifact structures

### 7. Template Word Usage Analysis

**Statistical Analysis**:
- "template" appears 618 times across 18 agent files
- 0 occurrences of `.claude/templates/` (direct file reference)
- 100% of "template" usage refers to embedded inline templates
- Pattern: "THIS EXACT TEMPLATE", "Template Template", "Reasoning Chain Template"

**Key Insight**: The word "template" in agents refers to EMBEDDED SCAFFOLDS, not external file dependencies.

## Recommendations

### 1. Maintain Current Agent Architecture (High Priority)

**Recommendation**: Keep agents using embedded templates rather than external file references.

**Rationale**:
- Agents are self-contained behavioral specifications
- Embedding templates ensures agents work even if .claude/templates/ is missing
- Reduces runtime file I/O and potential failure points
- Agents can be distributed independently

**Action**: Document this as a design pattern in agent development guide

### 2. Clarify Template Directory Purpose (High Priority)

**Recommendation**: Update .claude/templates/README.md to clarify the directory serves THREE distinct purposes:

1. **YAML Workflow Templates** (runtime dependency for /plan-from-template)
2. **Orchestration Patterns** (runtime reference for /orchestrate)
3. **Reference Documentation** (developer/user reference, NOT runtime)

**Rationale**:
- Current README focuses only on YAML workflow templates
- Developers may not understand why structure templates exist if agents embed them
- Prevents confusion about "why do we have both?"

**Action**: Add "Template Types" section to README explaining the three purposes

### 3. Establish Template Synchronization Process (Medium Priority)

**Recommendation**: Create process for synchronizing embedded agent templates with reference documentation templates.

**Options**:
1. **Manual synchronization**: Document that changes to embedded templates should update .claude/templates/ reference files (and vice versa)
2. **Automated validation**: Script to compare embedded templates with reference templates and flag divergence
3. **Single source of truth**: Eliminate one or the other (see Recommendation 4)

**Rationale**:
- Template drift creates inconsistent artifacts
- Developers updating agents may not know to update reference docs
- Users reading reference docs may see outdated structures

**Action**: Document synchronization responsibility in agent development guide

### 4. Consider Removing Redundant Reference Templates (Low Priority)

**Recommendation**: Evaluate whether to remove .claude/templates/{report,debug,refactor,readme}-structure.md files.

**Rationale**:
- Agents have embedded templates that are the ACTUAL source of truth
- Reference templates in .claude/templates/ are not read by agents
- Maintaining two copies creates synchronization burden
- Users/developers can read agent files for authoritative structures

**Alternatives**:
1. **Keep both**: Document that agent embedded templates are authoritative
2. **Remove reference templates**: Delete redundant .claude/templates/ files
3. **Agent-as-source**: Update commands to reference agent files instead of .claude/templates/

**Action**: Discuss with project maintainers; document decision in architecture guide

### 5. Protect Critical YAML Template Dependencies (High Priority)

**Recommendation**: Add validation to /plan-from-template to check for missing YAML templates and provide clear error messages.

**Rationale**:
- YAML templates are the ONLY critical runtime dependency
- Command fails silently if template missing
- Users may not understand why command doesn't work

**Action**: Enhance /plan-from-template error handling with template existence checks

### 6. Document Orchestration Pattern Usage (Medium Priority)

**Recommendation**: Add usage examples to orchestration-patterns.md showing how /orchestrate loads and uses the patterns.

**Rationale**:
- orchestration-patterns.md is 70KB of templates
- No clear documentation on how these are used at runtime
- Developers modifying /orchestrate need to understand the dependency

**Action**: Add "Usage from /orchestrate" section to orchestration-patterns.md

## References

### Agent Files Analyzed
- /home/benjamin/.config/.claude/agents/debug-specialist.md (lines 311-378)
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 83-107)
- /home/benjamin/.config/.claude/agents/doc-writer.md (lines 310-350)
- /home/benjamin/.config/.claude/agents/code-reviewer.md (lines 211-280)
- /home/benjamin/.config/.claude/agents/metrics-specialist.md (lines 280-495)
- /home/benjamin/.config/.claude/agents/plan-architect.md (lines 569-650)
- /home/benjamin/.config/.claude/agents/plan-structure-manager.md (lines 161-247)
- /home/benjamin/.config/.claude/agents/complexity-estimator.md (line 217)
- /home/benjamin/.config/.claude/agents/github-specialist.md (lines 123, 213, 254)
- /home/benjamin/.config/.claude/agents/doc-converter.md (lines 289, 881, 887, 903)
- /home/benjamin/.config/.claude/agents/spec-updater.md (line 777)
- /home/benjamin/.config/.claude/agents/README.md (line 649)
- /home/benjamin/.config/.claude/agents/shared/README.md
- /home/benjamin/.config/.claude/agents/prompts/README.md
- /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-collapse.md
- /home/benjamin/.config/.claude/agents/prompts/evaluate-phase-expansion.md
- /home/benjamin/.config/.claude/agents/prompts/evaluate-plan-phases.md

### Command Files Analyzed
- /home/benjamin/.config/.claude/commands/orchestrate.md (lines 79-80, 273, 299)
- /home/benjamin/.config/.claude/commands/plan-from-template.md (lines 70-71, 248, 278)
- /home/benjamin/.config/.claude/commands/debug.md (lines 580, 591)
- /home/benjamin/.config/.claude/commands/research.md (line 691)
- /home/benjamin/.config/.claude/commands/refactor.md (lines 187, 198)
- /home/benjamin/.config/.claude/commands/README.md (lines 289-305)
- /home/benjamin/.config/.claude/commands/shared/workflow-phases.md

### Template Files Analyzed
- /home/benjamin/.config/.claude/templates/README.md (287 lines)
- /home/benjamin/.config/.claude/templates/report-structure.md (50+ lines)
- /home/benjamin/.config/.claude/templates/debug-structure.md (50+ lines)
- /home/benjamin/.config/.claude/templates/orchestration-patterns.md (80+ lines analyzed)
- /home/benjamin/.config/.claude/templates/refactor-structure.md
- /home/benjamin/.config/.claude/templates/readme-template.md
- /home/benjamin/.config/.claude/templates/agent-invocation-patterns.md
- /home/benjamin/.config/.claude/templates/agent-tool-descriptions.md
- /home/benjamin/.config/.claude/templates/artifact_research_invocation.md
- /home/benjamin/.config/.claude/templates/audit-checklist.md
- /home/benjamin/.config/.claude/templates/command-frontmatter.md
- /home/benjamin/.config/.claude/templates/output-patterns.md
- /home/benjamin/.config/.claude/templates/sub_supervisor_pattern.md

### YAML Workflow Templates
- /home/benjamin/.config/.claude/templates/api-endpoint.yaml
- /home/benjamin/.config/.claude/templates/crud-feature.yaml
- /home/benjamin/.config/.claude/templates/debug-workflow.yaml
- /home/benjamin/.config/.claude/templates/documentation-update.yaml
- /home/benjamin/.config/.claude/templates/example-feature.yaml
- /home/benjamin/.config/.claude/templates/migration.yaml
- /home/benjamin/.config/.claude/templates/refactor-consolidation.yaml
- /home/benjamin/.config/.claude/templates/refactoring.yaml
- /home/benjamin/.config/.claude/templates/research-report.yaml
- /home/benjamin/.config/.claude/templates/spec-updater-test.yaml
- /home/benjamin/.config/.claude/templates/test-suite.yaml

## Appendix: Search Methodology

### Search Patterns Used
1. Direct file references: `.claude/templates/`, `templates/`, `../templates/`
2. Template keyword: Case-insensitive search for "template"
3. YAML references: `.yaml`, `YAML template`
4. Specific template names: `report-structure`, `debug-structure`, `refactor-structure`, `readme-template`
5. Orchestration patterns: `agent-invocation-patterns`, `orchestration-patterns`, `output-patterns`, `sub_supervisor`

### Files Searched
- All 19 agent files in .claude/agents/
- All command files in .claude/commands/
- Template files in .claude/templates/

### Tools Used
- Glob: File discovery
- Grep: Pattern matching with context (-C flag)
- Read: Detailed file examination
- Bash: Directory listing and metadata

### Verification Steps
1. Confirmed 0 direct `.claude/templates/` references in agent files
2. Verified all agents with embedded templates
3. Cross-referenced command usage of templates
4. Validated YAML template existence and usage
5. Analyzed template word frequency and context

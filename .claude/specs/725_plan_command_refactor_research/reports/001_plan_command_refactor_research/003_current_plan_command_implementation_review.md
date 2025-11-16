# Current Plan Command Implementation Review

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Current /plan command implementation analysis
- **Report Type**: codebase analysis
- **Overview Report**: [Plan Command Refactor Research](OVERVIEW.md)
- **Related Reports**:
  - [Coordinate Command Architecture and Fragility Analysis](001_coordinate_command_architecture_and_fragility_analysis.md)
  - [Optimize-Claude Command Robustness Patterns](002_optimize_claude_command_robustness_patterns.md)
  - [Context Preservation and Metadata Passing Strategies](004_context_preservation_and_metadata_passing_strategies.md)

## Executive Summary

The /plan command is currently a pseudocode template at `/home/benjamin/.config/.claude/commands/plan.md` (230 lines) with comprehensive documentation but NO actual executable implementation. The command relies on library modules that exist (plan-core-bundle.sh, complexity-utils.sh, complexity-thresholds.sh) but key orchestration functions referenced in the template (analyze_feature_description, extract_requirements, validate-plan.sh) do not exist in the codebase. The architecture is well-designed with Phase 0 pre-analysis, research delegation, and progressive plan structures, but implementation is incomplete.

## Findings

### Current Architecture and Implementation

#### 1. Command File Structure
**File**: `/home/benjamin/.config/.claude/commands/plan.md:1-230`

The command is structured as a pseudocode template with six phases:
- **Phase 0**: Parse Arguments and Pre-Analysis (lines 17-39)
- **Phase 0.5**: Research Delegation - Conditional (lines 41-54)
- **Phase 1**: Standards Discovery and Report Integration (lines 56-72)
- **Phase 2**: Requirements Analysis and Complexity Evaluation (lines 74-85)
- **Phase 3**: Topic-Based Location Determination (lines 87-108)
- **Phase 4**: Plan Creation (lines 110-207)
- **Phase 5**: Plan Validation and Registration (lines 209-225)

**Critical Issue**: The entire file contains bash code blocks but is NOT executable. It's documentation of what the command SHOULD do, not what it DOES.

#### 2. Library Module Support

**Existing Libraries** (verified):
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh` (1160 lines) - Phase/stage extraction, metadata management, structure utilities
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh` (162 lines) - Complexity calculation functions
- `/home/benjamin/.config/.claude/lib/complexity-thresholds.sh` (252 lines) - Threshold extraction from CLAUDE.md

**Functions Available**:
- `calculate_phase_complexity()` - complexity-utils.sh:27
- `calculate_plan_complexity()` - complexity-utils.sh:106
- `exceeds_complexity_threshold()` - complexity-utils.sh:138
- `extract_phase_name()` - plan-core-bundle.sh:59
- `extract_phase_content()` - plan-core-bundle.sh:78
- `detect_structure_level()` - plan-core-bundle.sh:763
- 40+ additional plan manipulation functions

**Missing Functions** (referenced but not found):
- `analyze_feature_description()` - plan.md:33
- `extract_requirements()` - plan.md:78
- `.claude/lib/validate-plan.sh` - plan.md:215
- `.claude/lib/extract-standards.sh` - plan.md:62

#### 3. Documentation Quality

**Complete Guide**: `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md:1-461`

The guide documents:
- Research delegation triggers (complexity ≥7, keywords: integrate/migrate/refactor/architecture) - lines 75-117
- Complexity analysis factors and ranges - lines 151-203
- Standards discovery process - lines 206-250
- Uniform plan template structure - lines 253-347
- Progressive plan levels (0/1/2) - lines 371-380

**Quality**: Documentation is comprehensive and well-structured but describes features that may not be implemented.

#### 4. Integration Points

**Workflow Integration**: `/home/benjamin/.config/.claude/docs/workflows/development-workflow.md:22-29`

The /plan command fits into standard workflow:
```
research → plan → implement → test → commit → summarize
```

**Dependent Commands** (from plan.md:6):
- `/list` - List plans
- `/update` - Update plan status
- `/revise` - Revise plan content

**Commands That Use Plans**:
- `/implement` - Executes implementation plans
- `/expand` - Expands phases/stages
- `/collapse` - Collapses phases/stages
- `/revise` - Revises plan content

### What Works Well (Strengths)

#### 1. Architecture Design
The command's conceptual architecture is excellent:
- **Phase 0 Pre-Analysis**: Estimates complexity before planning (smart resource allocation)
- **Research Delegation**: Automatically invokes research agents for complex features (plan.md:41-54)
- **Progressive Structures**: All plans start Level 0, expand on-demand (prevents over-engineering)
- **Standards Integration**: Discovers and applies CLAUDE.md standards automatically

#### 2. Library Module Organization
The plan-core-bundle.sh consolidates three frequently-co-sourced utilities (1143 lines total):
- parse-plan-core.sh (138 lines) - Extraction functions
- plan-metadata-utils.sh (607 lines) - Metadata management
- plan-structure-utils.sh (396 lines) - Structure detection

**Benefit**: Single source operation reduces overhead.

#### 3. Complexity Analysis Framework
Two-tier complexity analysis:
- **Feature-level**: analyze_feature_description() - Pre-planning estimation
- **Plan-level**: calculate_plan_complexity() - Post-requirements calculation

**Thresholds**: Configurable via CLAUDE.md with subdirectory overrides (complexity-thresholds.sh:156-199)

#### 4. Topic-Based Organization
Plans organized in numbered topic directories:
```
specs/{NNN_topic}/
  ├── plans/
  ├── reports/
  ├── summaries/
  └── debug/
```
(plan.md:87-108, development-workflow.md:62-77)

**Benefit**: Clear artifact organization with gitignore compliance.

### What Doesn't Work Well (Weaknesses)

#### 1. Template vs. Implementation Gap
**Critical Issue**: plan.md is pseudocode documentation, not executable code.

Evidence:
- No shebang line (`#!/usr/bin/env bash`)
- No actual execution logic, only code block examples
- Functions called don't exist (analyze_feature_description, extract_requirements)
- No error handling or actual file I/O

**Impact**: Command cannot currently execute without complete rewrite.

#### 2. Missing Core Functions
Key functions referenced but not implemented:

**analyze_feature_description()** - plan.md:33
- Should analyze feature description for complexity
- Should return JSON with estimated_complexity and suggested_phases
- NO implementation found in any library

**extract_requirements()** - plan.md:78
- Should extract requirements from feature description
- Used to calculate plan complexity
- NO implementation found

**validate-plan.sh** - plan.md:215
- Should validate plan structure
- Referenced as `.claude/lib/validate-plan.sh`
- File does NOT exist

**extract-standards.sh** - plan.md:62
- Should extract standards from CLAUDE.md
- Referenced as `.claude/lib/extract-standards.sh`
- File does NOT exist

#### 3. Research Delegation Logic Incomplete
Template shows research delegation (plan.md:41-54):
```bash
if [ "$REQUIRES_RESEARCH" = "true" ]; then
  echo "PROGRESS: Complex feature detected - invoking research agents"
  # Invoke research-specialist agents via Task tool
  # Use forward_message pattern for metadata extraction
  # Cache research reports for plan creation
fi
```

**Issues**:
- Task tool invocation not shown
- Agent behavioral file injection not specified
- Report path calculation missing
- Metadata extraction mechanism unclear

#### 4. No Argument Parsing
Template shows argument parsing (plan.md:20-27):
```bash
FEATURE_DESCRIPTION="$1"
REPORT_PATHS=()
shift
while [[ $# -gt 0 ]]; do
  [[ "$1" == *.md ]] && REPORT_PATHS+=("$1")
  shift
done
```

**Issue**: Simple parsing doesn't handle:
- Quoted multi-word descriptions
- Optional flags (--force-research)
- Error messages for invalid arguments
- Help text display

#### 5. Template Uniformity vs. Flexibility
All plans use identical template (plan.md:114-206).

**Weakness**: No template selection based on:
- Feature type (feature/bugfix/refactor/architecture)
- Complexity score
- Domain (frontend/backend/database/infrastructure)

**Guide mentions** (plan-command-guide.md:173): "Matching templates: database-migration, architecture-refactor" but NO mechanism to apply them.

### Opportunities for Improvement

#### 1. Implement Executable Command
**Current**: Template documentation
**Proposed**: Full bash implementation

Requirements:
- Convert pseudocode to executable bash
- Implement missing functions (analyze_feature_description, extract_requirements)
- Add error handling and validation
- Create validate-plan.sh library
- Test with real feature descriptions

**Benefit**: Command becomes usable, not just documented.

#### 2. LLM-Based Feature Analysis
**Current**: Missing analyze_feature_description()
**Proposed**: Use LLM classifier pattern

Implementation:
```bash
analyze_feature_description() {
  local description="$1"

  # Use Task tool with small model (haiku-4) for classification
  # Analyze: complexity keywords, scope indicators, technical depth
  # Return JSON: estimated_complexity, suggested_phases, matching_templates
}
```

**Reference**: `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md`

**Benefit**: Intelligent pre-analysis without hardcoded heuristics.

#### 3. Template Selection System
**Current**: Single uniform template
**Proposed**: Template library with selection

Structure:
```
.claude/commands/templates/
  ├── feature.md          # Standard feature template
  ├── bugfix.md           # Bug fix template
  ├── refactor.md         # Refactoring template
  ├── architecture.md     # Architecture change template
  ├── database.md         # Database migration template
  └── README.md           # Template catalog
```

Selection logic:
- Analyze feature description (type, domain, complexity)
- Match to template
- Apply template with variable substitution

**Benefit**: Plans tailored to feature type, reducing boilerplate.

#### 4. Research Delegation Automation
**Current**: Incomplete pseudocode (plan.md:41-54)
**Proposed**: Full research orchestration

Implementation:
- Calculate research topics from feature description
- Generate report paths using topic-based organization
- Invoke research-specialist agents with behavioral injection
- Extract metadata using forward_message pattern
- Integrate findings into plan phases

**Reference**: `/home/benjamin/.config/.claude/agents/research-specialist.md:416-489` - Report creation process

**Benefit**: Complex features get comprehensive research automatically.

#### 5. Standards Validation
**Current**: Standards discovered but not validated
**Proposed**: Validate plan against discovered standards

Validation checks:
- Plan includes test phases (if Testing Protocols defined)
- Documentation tasks present (if Documentation Policy defined)
- Code standards referenced in phase tasks
- Phase dependencies valid (if parallel execution supported)

Create validate-plan.sh:
```bash
validate_plan() {
  local plan_file="$1"
  local standards_file="$2"

  # Check: Metadata complete
  # Check: Standards referenced
  # Check: Test phases present
  # Check: Documentation tasks exist
  # Check: Phase dependencies valid

  # Return: validation report with warnings/errors
}
```

**Benefit**: Plans conform to project standards automatically.

#### 6. Interactive Plan Refinement
**Current**: One-shot plan creation
**Proposed**: Interactive review and refinement

Workflow:
1. Generate initial plan
2. Display summary (complexity, phases, duration)
3. Ask user:
   - "Adjust complexity threshold?"
   - "Add/remove phases?"
   - "Change template?"
4. Regenerate with adjustments
5. Confirm before writing

**Tool**: Use AskUserQuestion tool for interaction

**Benefit**: Plans align with user expectations before implementation.

## Recommendations

### Priority 1: Implement Core Execution (CRITICAL)

**Action**: Convert plan.md from template to executable command

Steps:
1. Create bash script implementation (not markdown pseudocode)
2. Implement analyze_feature_description() using LLM classifier pattern
3. Implement extract_requirements() function
4. Create validate-plan.sh library
5. Add comprehensive error handling
6. Test with 10+ diverse feature descriptions

**Estimated Effort**: 8-12 hours
**Blocking**: All plan command functionality

### Priority 2: Research Delegation Implementation (HIGH)

**Action**: Complete research delegation workflow (plan.md:41-54)

Steps:
1. Implement complexity trigger logic
2. Create research topic generation from feature description
3. Invoke research-specialist agents with Task tool
4. Implement metadata extraction from reports
5. Integrate findings into plan phases
6. Add fallback for research failures

**Estimated Effort**: 6-8 hours
**Dependencies**: Priority 1 complete

### Priority 3: Template Selection System (MEDIUM)

**Action**: Create template library and selection mechanism

Steps:
1. Extract existing uniform template to templates/feature.md
2. Create specialized templates (bugfix, refactor, architecture, database)
3. Implement template selection logic in analyze_feature_description()
4. Add template variable substitution
5. Document template catalog in templates/README.md

**Estimated Effort**: 4-6 hours
**Benefit**: Plans tailored to feature type

### Priority 4: Standards Validation (MEDIUM)

**Action**: Create validate-plan.sh library

Steps:
1. Implement metadata validation
2. Check standards references
3. Validate test phases present (if Testing Protocols defined)
4. Validate documentation tasks (if Documentation Policy defined)
5. Validate phase dependencies
6. Generate validation report with warnings/errors

**Estimated Effort**: 3-4 hours
**Benefit**: Plans conform to standards

### Priority 5: Interactive Refinement (LOW)

**Action**: Add interactive plan review and adjustment

Steps:
1. Generate initial plan
2. Display summary to user
3. Use AskUserQuestion for adjustments
4. Regenerate with changes
5. Confirm before writing

**Estimated Effort**: 2-3 hours
**Benefit**: Better user alignment

## References

### Primary Files Analyzed

- `/home/benjamin/.config/.claude/commands/plan.md:1-230` - Command template (pseudocode)
- `/home/benjamin/.config/.claude/lib/plan-core-bundle.sh:1-1160` - Core plan manipulation library
- `/home/benjamin/.config/.claude/lib/complexity-utils.sh:1-162` - Complexity calculation utilities
- `/home/benjamin/.config/.claude/lib/complexity-thresholds.sh:1-252` - Threshold extraction library
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md:1-461` - Comprehensive guide
- `/home/benjamin/.config/.claude/docs/workflows/development-workflow.md:1-174` - Workflow integration
- `/home/benjamin/.config/.claude/agents/research-specialist.md:1-671` - Research agent behavioral file

### Supporting Documentation

- `/home/benjamin/.config/.claude/docs/reference/adaptive-planning-config.md` - Complexity threshold configuration
- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md` - Adaptive planning workflow
- `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md` - Topic-based organization
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md` - LLM classifier pattern

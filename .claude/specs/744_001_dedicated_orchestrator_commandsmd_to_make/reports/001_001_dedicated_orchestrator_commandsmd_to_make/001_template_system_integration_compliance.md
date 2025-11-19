# Template System Integration Compliance Analysis

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Template System Integration Compliance
- **Report Type**: Compliance analysis
- **Plan Under Review**: [001_dedicated_orchestrator_commands.md](../../../743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md)
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)
- **Standards Reference**: Template vs Behavioral Distinction, Library API, template-integration.sh

## Executive Summary

The plan proposes a "template-based approach" for generating 5 dedicated orchestrator commands (/research, /research-plan, /research-revise, /build, /fix) using a single reusable template with substitution markers. However, this approach exhibits CRITICAL non-compliance with documented standards: (1) proposes creating `.claude/templates/state-based-orchestrator-template.md` which violates the established library-based pattern, (2) uses manual substitution markers ({{WORKFLOW_TYPE}}) instead of the documented `template-integration.sh` library functions, (3) introduces versioning complexity without alignment to existing template standards, and (4) creates maintenance burden that the library-based approach was designed to eliminate. The plan's approach contradicts the structural templates vs behavioral content distinction and misses the purpose of template-integration.sh entirely.

## Findings

### 1. Template System Architecture Mismatch

**Issue**: Plan proposes creating command template file at `.claude/templates/state-based-orchestrator-template.md` with manual substitution markers.

**Evidence from Plan** (lines 37-94, expansion_phase_1.md):
```markdown
**File**: `/home/benjamin/.config/.claude/templates/state-based-orchestrator-template.md`

**Structure** (600-800 lines total):
# {{COMMAND_NAME}} - State-Based Orchestrator Template
# Version: 1.0.0
# Template Type: State-Based Orchestrator
# Workflow Type: {{WORKFLOW_TYPE}}

### Workflow-Specific Substitutions
- `{{WORKFLOW_TYPE}}`: debug | research | plan | implement | test
- `{{COMMAND_NAME}}`: /debug | /research | /plan | /implement | /test-all
- `{{DEFAULT_COMPLEXITY}}`: 1-4 (workflow-dependent)
- `{{TERMINAL_STATE}}`: debug_complete | research_complete | etc.
```

**Documented Standard** (template-integration.sh lines 1-370):
The template-integration.sh library provides functions for:
- `list_available_templates()` - Lists templates from `.claude/commands/templates/*.yaml`
- `validate_generated_plan()` - Validates plan structure (not command structure)
- `link_template_to_plan()` - Links template metadata to plans
- `get_or_create_topic_dir()` - Directory management for topic-based organization
- `extract_topic_from_question()` - Topic name extraction

**Analysis**:
The library is designed for **plan template management** (YAML templates in `.claude/commands/templates/`), NOT for command file generation. The plan's approach of creating a command template file fundamentally misunderstands the library's purpose.

**Compliance Status**: CRITICAL VIOLATION

### 2. Confusion Between Structural Templates and Template Files

**Issue**: Plan uses "template" terminology in a way that conflicts with documented architectural distinction.

**Evidence from Standards** (template-vs-behavioral-distinction.md lines 26-87):
```markdown
## Structural Templates (MUST Be Inline)

Structural templates are execution-critical patterns that:
- Must be immediately visible to the orchestrating command
- Define HOW commands execute and coordinate agents
- Are parsed and executed directly by the command
- Cannot be delegated to agents

### Examples
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: checks`
```

**Plan's Usage** (line 88):
```markdown
3. **Command File Structure** (template-based approach):
   # Part 1: Capture Workflow Description (identical across all commands)
   # Part 2: State Machine Initialization (hardcoded workflow_type)
   # Phase 1: Research (identical across all commands)
```

**Analysis**:
The plan conflates THREE distinct concepts:
1. **Structural templates** (inline execution patterns like Task blocks) - documented standard
2. **Template files** (YAML files for plan generation) - documented in template-integration.sh
3. **Command template files** (proposed 600-800 line .md file) - NOT documented, conflicts with standards

The "template-based approach" in the plan refers to creating a master command file for copy-paste generation, which is NOT what the template system or structural templates are for.

**Compliance Status**: MODERATE VIOLATION (terminology confusion)

### 3. Missing Integration with Documented Template System

**Issue**: Plan proposes custom substitution mechanism instead of using existing library functions.

**Evidence from Plan** (expansion_phase_1.md lines 116-128):
```yaml
substitution_markers:
  - WORKFLOW_TYPE
  - COMMAND_NAME
  - DEFAULT_COMPLEXITY
  - TERMINAL_STATE
  - ENABLE_PLANNING
  - ENABLE_IMPLEMENTATION
  - ENABLE_TESTING
  - ENABLE_DEBUG
  - ENABLE_DOCUMENTATION
  - MAX_RESEARCH_DEPTH
  - MAX_RETRY_ATTEMPTS
  - TIMEOUT_MINUTES
```

**Documented Library Functions** (template-integration.sh lines 154-183):
```bash
# Extract topic name from user question or feature description
extract_topic_from_question() {
  local question="${1:-}"
  # Sanitization logic for topic directory names
}

# Get or create topic directory with proper numbering
get_or_create_topic_dir() {
  local description="${1:-}"
  local base_specs_dir="${2:-specs}"
  # Topic directory management
}
```

**Analysis**:
The library provides NO functions for:
- Command file substitution or generation
- Marker replacement in template files
- Workflow type parameterization
- Conditional phase activation

The plan's substitution marker system is implemented from scratch with no connection to template-integration.sh. This suggests either:
1. The plan author wasn't aware of the library's actual capabilities
2. The library doesn't support command generation (which is correct)
3. The plan is trying to extend the template system in an undocumented way

**Compliance Status**: CRITICAL GAP (no library support for proposed approach)

### 4. Version Management Overhead Without Justification

**Issue**: Plan introduces template versioning (v1.0.0, CHANGELOG.md, compatibility matrix) without aligning to existing template standards.

**Evidence from Plan** (expansion_phase_1.md lines 42-62):
```markdown
## Template Metadata
- **Template Version**: 1.0.0
- **Last Updated**: 2025-11-17
- **Minimum Library Version**: state-machine-lib 2.0.0

## Library Compatibility Matrix
| Library Component | Minimum Version | Required Features |
|------------------|----------------|-------------------|
| state-machine-lib | 2.0.0 | Core orchestration, state transitions |
| hierarchical-agent-utils | 1.5.0 | Agent spawning, coordination |
```

**Evidence from template-integration.sh** (lines 1-370):
No versioning system for templates. The library validates plan structure (lines 54-104) but has NO version checks or compatibility validation.

**Analysis**:
The plan proposes creating a versioning infrastructure (CHANGELOG, compatibility matrix, migration guides) for a template file system that:
1. Doesn't currently exist in the codebase
2. Isn't documented in any standards
3. Adds significant maintenance burden (tracking library versions, migration paths)
4. Solves a problem that doesn't exist (commands don't need versioned templates, they need clear patterns)

This is over-engineering for a copy-paste generation approach.

**Compliance Status**: MODERATE VIOLATION (unnecessary complexity)

### 5. Command Generation Strategy Misalignment

**Issue**: Plan's "copy template and substitute markers" approach contradicts the library-based reuse strategy documented throughout the codebase.

**Evidence from Plan** (Phase 2 tasks, line 271):
```markdown
- [ ] Copy template to `.claude/commands/research.md`
- [ ] Substitute `{{WORKFLOW_TYPE}}` → `"research-only"`
- [ ] Substitute `{{TERMINAL_STATE}}` → `"research"`
- [ ] Substitute `{{COMMAND_NAME}}` → `"research"`
- [ ] Remove conditional phase sections
```

**Documented Pattern** (library-api.md lines 1-300):
The standard approach is **library reuse**, not file templates:
```bash
# Commands source shared libraries
source "${CLAUDE_CONFIG}/.claude/lib/unified-location-detection.sh"
source "${CLAUDE_CONFIG}/.claude/lib/workflow-state-machine.sh"

# Commands call library functions
LOCATION_JSON=$(perform_location_detection "research authentication patterns")
sm_init "$WORKFLOW_DESCRIPTION" "$COMMAND_NAME" "$WORKFLOW_TYPE"
```

**Evidence from Plan** (lines 71-80):
```bash
# All commands use same initialization pattern
sm_init \
  "$WORKFLOW_DESCRIPTION" \
  "$COMMAND_NAME" \
  "$WORKFLOW_TYPE" \
  "$RESEARCH_COMPLEXITY" \
  "$RESEARCH_TOPICS_JSON"
```

**Analysis**:
The plan CORRECTLY identifies library-based reuse for state machine functionality but then proposes a TEMPLATE-BASED approach for command generation. This creates a hybrid that:
1. Uses libraries at runtime (good)
2. Uses template copy-paste at development time (unnecessary)
3. Results in 5 nearly-identical 600-800 line command files
4. Creates maintenance burden when library APIs change

**Better Approach**: Create commands by hand-coding the small differences (workflow_type, terminal_state, phase conditions) and sharing everything else via libraries. This is how /coordinate, /supervise, /orchestrate are already structured.

**Compliance Status**: MODERATE VIOLATION (unnecessary complexity)

### 6. Failure Modes in Template Integration Approach

**Issue**: Plan doesn't address how template substitution errors will be detected or prevented.

**Evidence from Plan** (expansion_phase_1.md lines 163-170):
```markdown
### Validation Requirements
Before deploying:
1. All substitution markers resolved (no `{{}}` remaining)
2. Library compatibility verified
3. Essential features checklist complete
4. Syntax validation passed
5. Dry-run execution successful
```

**Missing from Plan**:
1. **How** are markers validated? Manual inspection? Script?
2. **When** does validation happen? Pre-commit? Runtime?
3. **What** if validation fails? Roll back? Manual fix?
4. **Who** maintains the validation script when template evolves?

**Potential Failure Modes**:
1. **Partial substitution**: Developer forgets to replace `{{TERMINAL_STATE}}`, command fails at runtime
2. **Invalid values**: Developer sets `{{WORKFLOW_TYPE}}` to "analyze" instead of "research-only", state machine rejects it
3. **Conditional logic errors**: Developer removes wrong phase sections, breaks state transitions
4. **Version drift**: Template v1.0.0 used but libraries upgraded to 2.1.0, compatibility matrix outdated
5. **Merge conflicts**: Two developers copy template simultaneously, create commands with same structure but different bugs

**Analysis**:
The plan relies on manual validation ("verify all markers resolved") without tooling support. The complexity override parsing (lines 154-171) shows sophisticated bash logic that would need to be copy-pasted correctly into each command.

**Compliance Status**: HIGH RISK (no validation automation)

## Recommendations

### Recommendation 1: Abandon Template File Approach, Use Direct Command Creation

**Rationale**: The template file approach (600-800 lines with substitution markers) adds complexity without benefit. Commands should be created directly with small, focused implementations.

**Implementation**:
1. Create each command file directly in `.claude/commands/[name].md`
2. Write the unique parts (workflow_type, terminal_state, phase conditions) explicitly
3. Share common logic via library functions (already planned)
4. Use `/coordinate` as reference implementation, not as template to copy

**Benefits**:
- Eliminates substitution marker system and validation burden
- Reduces command file size (200-300 lines vs 600-800 lines per plan)
- Makes command-specific logic immediately visible
- Prevents copy-paste errors
- Aligns with existing command development patterns

**Example** (/research command):
```markdown
---
allowed-tools: Task, TodoWrite, Bash, Read
description: Research-only workflow without plan/implementation
---

# Part 1: Workflow Description Capture
[30 lines - identical to /coordinate]

# Part 2: State Machine Initialization
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
sm_init "$WORKFLOW_DESCRIPTION" "research" "$WORKFLOW_TYPE"

# Phase 1: Research
[100 lines - library-based hierarchical coordination]

# Completion
sm_transition "$STATE_COMPLETE"
display_brief_summary
```

This is 150-200 lines, not 600-800.

### Recommendation 2: Document Command Development Pattern, Not Template System

**Rationale**: Developers need guidance on creating new orchestrator commands, but a 600-800 line template file is the wrong tool.

**Implementation**:
1. Create `.claude/docs/guides/creating-orchestrator-commands.md`
2. Document the 5 essential sections every orchestrator command needs:
   - Workflow description capture
   - State machine initialization
   - Phase implementations (conditional)
   - Verification checkpoints
   - Terminal state handling
3. Provide code snippets for each section (not full template)
4. Reference existing commands as examples

**Benefits**:
- Teaches developers the pattern without prescribing exact implementation
- Allows command-specific optimizations
- Easier to maintain (update guide, not 600-800 line template)
- Aligns with existing guide-based documentation

### Recommendation 3: Clarify Template Integration Library Scope

**Rationale**: The confusion between "structural templates", "template files", and "command templates" needs resolution.

**Implementation**:
1. Update template-integration.sh documentation to clearly state: "This library supports PLAN template management, not command generation"
2. Rename if necessary to clarify: `plan-template-integration.sh`
3. Document that commands use "structural templates" (inline execution patterns) not "template files" (YAML plan templates)
4. Cross-reference Template vs Behavioral Distinction documentation

**Benefits**:
- Eliminates terminology confusion
- Clarifies library boundaries
- Prevents future misuse

### Recommendation 4: Use Existing /coordinate as Living Reference, Not Template Source

**Rationale**: The plan correctly identifies /coordinate as having all 6 essential features. Instead of extracting it into a template file, use it directly as reference.

**Implementation**:
1. Document /coordinate as "reference implementation for state-based orchestration"
2. When creating new orchestrator commands:
   - Open /coordinate for reference
   - Copy small sections as needed (30-50 lines max)
   - Adapt for specific workflow type
3. Don't try to parameterize /coordinate itself

**Benefits**:
- /coordinate remains functional reference implementation
- No template maintenance burden
- Developers learn by reading working code
- Aligns with "library reuse" strategy

### Recommendation 5: Simplify Phase 1 Scope - Remove Template Versioning

**Rationale**: The template versioning system (v1.0.0, CHANGELOG, compatibility matrix) is over-engineering for command development.

**Implementation**:
Phase 1 should create:
1. ✓ Documentation guide for orchestrator command pattern
2. ✓ Code snippets for each essential feature
3. ✓ Reference to /coordinate as example
4. ✗ Remove template file creation
5. ✗ Remove versioning system
6. ✗ Remove compatibility verification script

**Benefits**:
- Reduces Phase 1 from 4 hours to 2 hours
- Eliminates maintenance burden
- Focuses on what developers actually need (patterns, not templates)

## References

### Plan Files
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md` (lines 1-585)
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/artifacts/expansion_phase_1.md` (lines 1-200)

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/template-vs-behavioral-distinction.md` (lines 1-472) - Structural templates definition
- `/home/benjamin/.config/.claude/docs/quick-reference/template-usage-decision-tree.md` (lines 1-320) - Inline vs reference guidance
- `/home/benjamin/.config/.claude/docs/reference/library-api.md` (lines 1-1330) - Library function reference

### Library Files
- `/home/benjamin/.config/.claude/lib/template-integration.sh` (lines 1-370) - Plan template management library
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (referenced in library-api.md lines 43-300) - Location detection library

### Key Findings Summary
1. template-integration.sh supports **plan templates** (YAML), not command generation
2. "Structural templates" are **inline execution patterns**, not template files
3. Plan proposes creating undocumented template system for command generation
4. Template versioning adds complexity without corresponding benefit
5. Direct command creation with library reuse is the documented standard
6. No validation tooling proposed for substitution marker system

### Discrepancy Count
- **Critical violations**: 3 (template architecture, library integration, validation automation)
- **Moderate violations**: 3 (terminology confusion, versioning overhead, generation strategy)
- **High risks**: 1 (failure modes in substitution system)

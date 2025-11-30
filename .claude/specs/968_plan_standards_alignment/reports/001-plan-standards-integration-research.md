# Plan Standards Alignment Research Report

## Metadata
- **Date**: 2025-11-29
- **Agent**: research-specialist
- **Topic**: Plan command standards alignment
- **Report Type**: codebase analysis and best practices

## Executive Summary

The /plan command currently does not extract or pass CLAUDE.md standards to the plan-architect agent, creating a critical gap in standards compliance. Research reveals three integration points needed: (1) standards extraction utility, (2) plan-architect prompt enhancement, and (3) divergence detection mechanism. The plan-architect agent already has a "Standards Compliance" section in its completion criteria but lacks the actual standards content to validate against.

## Findings

### Current State Analysis

#### 1. /plan Command Implementation (lines 1-1240)

**Location**: `/home/benjamin/.config/.claude/commands/plan.md`

**Current Flow**:
- Block 1a: Setup and state initialization
- Block 1b: Topic name generation (via topic-naming-agent)
- Block 1c: Topic path initialization
- Block 1d: Research invocation (via research-specialist agent)
- Block 2: Research verification and planning setup
- Block 2 (Task): Plan-architect agent invocation
- Block 3: Plan verification and completion

**Standards References**:
- Line 67: CLAUDE.md path mentioned in metadata but NOT extracted or passed
- Lines 938-960: Plan-architect Task invocation - NO standards content provided
- The workflow description mentions "CLAUDE.md standards file" but never reads it

**Critical Gap Identified**:
The plan-architect prompt (lines 941-960) provides:
- Feature description
- Output path
- Research reports (as JSON array of paths)
- Workflow type
- Operation mode
- Archived prompt file

But it does NOT provide:
- CLAUDE.md standards content
- Relevant standards sections
- Project-specific code conventions
- Testing protocols
- Documentation requirements

#### 2. Plan-Architect Agent Behavioral File (lines 1-1113)

**Location**: `/home/benjamin/.config/.claude/agents/plan-architect.md`

**Standards Integration Points**:

**Line 67**: Metadata inputs list includes "CLAUDE.md standards file path" - but this is just the path, not the content

**Lines 901-906**: Standards Discovery section states:
```markdown
### Standards Discovery
Before creating plan:
1. Read CLAUDE.md for project standards
2. Extract code standards (indentation, naming, etc.)
3. Extract testing protocols
4. Incorporate standards into plan tasks
```

This is aspirational - the agent is TOLD to read CLAUDE.md but is NOT PROVIDED with the standards content or told HOW to extract relevant sections.

**Lines 977-983**: Standards Compliance completion criteria:
```markdown
### Standards Compliance (MANDATORY)
- [x] CLAUDE.md standards file path captured in metadata
- [x] Code standards from CLAUDE.md incorporated in Technical Design
- [x] Testing protocols from CLAUDE.md referenced in Testing Strategy
- [x] Documentation policy from CLAUDE.md referenced in Documentation Requirements
- [x] All phases follow project conventions
```

The agent is expected to validate standards compliance but lacks the mechanism to do so reliably.

**Lines 756-771**: Plan template shows standards reference:
```markdown
## Metadata
- **Standards File**: /path/to/CLAUDE.md
```

But again, this is just a path reference, not actual standards content.

#### 3. CLAUDE.md Structure Analysis

**Location**: `/home/benjamin/.config/CLAUDE.md`

**Relevant Standards Sections** (marked with `[Used by: ...]` metadata):

1. **Line 39-62**: `directory_protocols` - Used by /plan for specs structure
2. **Line 64-72**: `testing_protocols` - Used by /plan for test requirements
3. **Line 74-92**: `code_standards` - Used by /plan, /implement, /refactor
4. **Line 94-108**: `clean_break_development` - Used by /plan for refactoring approaches
5. **Line 110-136**: `code_quality_enforcement` - Standards enforcement mechanisms
6. **Line 138-153**: `output_formatting` - Command output standards
7. **Line 155-194**: `error_logging` - Error logging integration requirements
8. **Line 196-210**: `directory_organization` - File placement rules
9. **Line 212-218**: `development_philosophy` - Development approach and documentation
10. **Line 252-258**: `skills_architecture` - Skills vs commands vs agents

**Section Markers Format**:
```markdown
<!-- SECTION: section_name -->
### Section Title
[Used by: command1, command2, command3]
...
<!-- END_SECTION: section_name -->
```

This structured format enables programmatic extraction by section name.

#### 4. Standards Extraction Patterns in Codebase

**Search Results**: Found 52 files referencing CLAUDE.md, but most are documentation or read operations for specific purposes (worktree management, setup analysis).

**No Existing Standards Extraction Utility**: Grep search for "extract.*standards|parse.*CLAUDE" found no reusable standards extraction library.

**Related Pattern** - Error Handling Integration:
Lines 89-100 of `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` show the error logging integration pattern:
```bash
# 1. Source error-handling library (Tier 1 - fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Cannot load error-handling library" >&2
  exit 1
}
```

This demonstrates the existing pattern for integrating cross-cutting requirements from CLAUDE.md into commands.

### Best Practices Research

#### 1. Standards Section Extraction Approach

**Recommended Pattern**: Use section markers for targeted extraction

```bash
# Extract specific section from CLAUDE.md
extract_claude_section() {
  local section_name="$1"
  local claude_md_path="${CLAUDE_PROJECT_DIR}/CLAUDE.md"

  awk -v section="$section_name" '
    /<!-- SECTION: / {
      if ($0 ~ section) { in_section=1; next }
    }
    /<!-- END_SECTION:/ {
      if (in_section) { exit }
    }
    in_section { print }
  ' "$claude_md_path"
}
```

**Sections Relevant to Planning**:
- `code_standards` - For Technical Design phase
- `testing_protocols` - For Testing Strategy
- `directory_organization` - For file placement
- `documentation_policy` - For Documentation Requirements
- `error_logging` - For error handling requirements
- `clean_break_development` - For refactoring plans

#### 2. Agent Prompt Enhancement Pattern

**Current Plan-Architect Invocation** (lines 938-960 of plan.md):
```
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_JSON}
    ...
  "
}
```

**Enhanced Pattern with Standards**:
```
Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Feature Description: ${FEATURE_DESCRIPTION}
    - Research Reports: ${REPORT_PATHS_JSON}

    **Project Standards** (from CLAUDE.md):

    ### Code Standards
    ${CODE_STANDARDS_CONTENT}

    ### Testing Protocols
    ${TESTING_PROTOCOLS_CONTENT}

    ### Documentation Policy
    ${DOCUMENTATION_POLICY_CONTENT}

    **CRITICAL**: Plans MUST align with these standards. If your approach
    diverges from project standards for well-motivated reasons, include
    Phase 0 to revise standards documentation with clear justification.
  "
}
```

#### 3. Divergence Detection Mechanism

**Requirement**: Plan-architect must detect when proposed approach conflicts with standards and propose standards revision.

**Pattern**: Add divergence detection to plan-architect behavioral file

```markdown
## Standards Divergence Protocol

If your proposed implementation diverges from project standards:

1. **Assess Divergence Impact**:
   - Minor: Document in plan but don't revise standards (e.g., local variable naming)
   - Moderate: Note in Technical Design with justification
   - Major: Add Phase 0 for standards revision (e.g., new architectural pattern)

2. **Phase 0 Format** (for major divergences):
   ```markdown
   ### Phase 0: Standards Revision [NOT STARTED]

   **Objective**: Update project standards to support new approach
   **Divergence**: [Explain which standard conflicts and why]
   **Justification**: [Well-motivated reasoning for divergence]

   Tasks:
   - [ ] Update CLAUDE.md section [section_name] with new guidance
   - [ ] Document rationale in [section_name] section
   - [ ] Update related documentation references
   - [ ] Add migration notes if breaking change

   **User Warning**: This plan proposes changes to project standards.
   Review Phase 0 carefully before proceeding with /build.
   ```

3. **User Notification**:
   - Add "STANDARDS_DIVERGENCE: true" to plan metadata
   - Include warning in PLAN_CREATED output
   - Flag Phase 0 in console summary
```

#### 4. Incremental Standards Integration

**Phase 1**: Basic standards extraction and passing
- Add `extract_claude_sections()` utility to plan.md
- Pass extracted standards to plan-architect in prompt
- Update plan-architect to reference provided standards

**Phase 2**: Validation and divergence detection
- Add standards validation to plan-architect completion criteria
- Implement divergence detection logic
- Add Phase 0 generation for major conflicts

**Phase 3**: Standards evolution tracking
- Track which standards sections are commonly diverged from
- Enable standards improvement suggestions via /repair
- Create standards revision workflow

### Key Insights

1. **Gap Analysis**: The /plan command workflow has a complete standards integration gap - no extraction, no passing, no validation

2. **Agent Capability**: Plan-architect already has the completion criteria for standards compliance (lines 977-983) but lacks the content to validate against

3. **Section-Based Architecture**: CLAUDE.md uses `<!-- SECTION: name -->` markers making programmatic extraction straightforward

4. **Divergence is Valid**: Well-motivated divergence from standards should be supported, not blocked - but requires explicit Phase 0 for standards revision

5. **User Transparency**: Users must be warned when plans propose standards changes so they can review before /build execution

## Recommendations

### Recommendation 1: Create Standards Extraction Utility

**Priority**: High
**Effort**: 2-3 hours

Create `.claude/lib/plan/standards-extraction.sh` with functions:
- `extract_claude_section(section_name)` - Extract single section
- `extract_planning_standards()` - Extract all planning-relevant sections
- `format_standards_for_prompt()` - Format standards for agent prompt injection

**Rationale**: Reusable utility enables other commands (/revise, /implement) to also benefit from standards integration.

### Recommendation 2: Enhance /plan Command Block 2

**Priority**: High
**Effort**: 1-2 hours

In plan.md Block 2 (before plan-architect invocation):
1. Source standards-extraction.sh library
2. Extract relevant standards sections (code_standards, testing_protocols, documentation_policy, error_logging)
3. Store in bash variables for prompt injection
4. Pass standards content to plan-architect Task prompt

**Rationale**: Provides plan-architect with the standards content it needs to validate compliance.

### Recommendation 3: Update Plan-Architect Behavioral File

**Priority**: High
**Effort**: 2-3 hours

Add to plan-architect.md:
1. **Standards Integration Section** (STEP 1) - How to parse provided standards
2. **Divergence Detection Protocol** - When and how to propose Phase 0
3. **Phase 0 Template** - Standard format for standards revision phases
4. **Validation Enhancement** - Update completion criteria to validate against actual standards content (not just path reference)

**Rationale**: Completes the standards integration loop by giving the agent clear instructions on how to use provided standards.

### Recommendation 4: Add User Warning for Divergent Plans

**Priority**: Medium
**Effort**: 1 hour

Update plan.md Block 3 (plan verification):
1. Detect if plan contains "Phase 0: Standards Revision"
2. Add `STANDARDS_DIVERGENCE: true` to plan metadata
3. Include warning in console summary output
4. Flag in PLAN_CREATED signal for buffer-opener hook

**Rationale**: Users should review standards changes before running /build to avoid unintended standards drift.

### Recommendation 5: Document Standards Integration Pattern

**Priority**: Medium
**Effort**: 1-2 hours

Create `.claude/docs/guides/patterns/standards-integration.md` documenting:
- Standards extraction utilities
- Agent prompt enhancement pattern
- Divergence detection protocol
- Standards evolution workflow

**Rationale**: Establishes reusable pattern for other commands needing standards integration (/implement, /revise, /debug).

## References

### Command Files
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 1-1240) - Plan command implementation
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 938-960) - Plan-architect invocation
- `/home/benjamin/.config/.claude/commands/plan.md` (lines 656-933) - Research verification block

### Agent Files
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 1-1113) - Plan-architect behavioral file
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 67-75) - Requirements analysis inputs
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 901-906) - Standards discovery section
- `/home/benjamin/.config/.claude/agents/plan-architect.md` (lines 977-983) - Standards compliance criteria
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-684) - Research specialist reference

### Standards Files
- `/home/benjamin/.config/CLAUDE.md` (lines 1-470) - Project standards index
- `/home/benjamin/.config/CLAUDE.md` (lines 39-62) - directory_protocols section
- `/home/benjamin/.config/CLAUDE.md` (lines 74-92) - code_standards section
- `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (lines 1-100) - Detailed code standards

### Library Files
- `/home/benjamin/.config/.claude/lib/plan/topic-utils.sh` (lines 1-271) - Topic utilities (reference for new library)
- `/home/benjamin/.config/.claude/lib/plan/plan-core-bundle.sh` (lines 1-150) - Plan parsing utilities

### Documentation
- `.claude/docs/guides/patterns/standards-integration.md` (to be created) - Standards integration pattern guide

## Implementation Status
- **Status**: Planning In Progress
- **Plan**: [../plans/001-plan-standards-alignment-plan.md](../plans/001-plan-standards-alignment-plan.md)
- **Implementation**: [Will be updated by /build]
- **Date**: 2025-11-29

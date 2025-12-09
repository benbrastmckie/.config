# Infrastructure Integration with Standards

## Research Overview

**Topic**: Review existing .claude/docs/ standards and analyze how plan generation should integrate with directory protocols, plan metadata standards, and architectural patterns
**Date**: 2025-12-09
**Context**: Integration analysis for fixing /lean-plan metadata generation issues

## Executive Summary

The .claude/docs/ standards infrastructure provides comprehensive integration points for plan generation through standards-extraction.sh, validation scripts, and behavioral guidelines. However, current implementation gaps prevent phase metadata from being injected into planning agents. The infrastructure is well-designed but requires activation of dormant integration points (standards extraction, agent context injection, validation enforcement).

**Key Gaps**:
1. standards-extraction.sh may not include plan_metadata_standard section
2. lean-plan command may not invoke format_standards_for_prompt()
3. lean-plan-architect agent may not receive formatted standards in context
4. No pre-commit validation for phase metadata format

## Findings

### Finding 1: Standards Extraction Library Architecture

**Source**: Plan Metadata Standard references standards-extraction.sh at line 422-434

**Purpose**: Centralized standards extraction from CLAUDE.md for agent context injection

**Expected Function**: `format_standards_for_prompt()`

**Integration Pattern** (from plan-metadata-standard.md):

```bash
source "${CLAUDE_LIB}/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)

# Agent receives standards in prompt:
# **Project Standards**:
# ${FORMATTED_STANDARDS}
```

**Implementation Requirements** (line 434):

> **Implementation**: Add `plan_metadata_standard` to extracted sections array in standards-extraction.sh (~line 150-160).

**Verification Needed**: Check if standards-extraction.sh exists and includes phase metadata section

### Finding 2: CLAUDE.md Section-Based Organization

**Source**: `/home/benjamin/.config/CLAUDE.md`

**Section Markers** (from CLAUDE.md structure):

```markdown
<!-- SECTION: plan_metadata_standard -->
## Plan Metadata Standard
[Used by: /create-plan, /lean-plan, /repair, /revise, /debug, plan-architect]

[Content...]
<!-- END_SECTION: plan_metadata_standard -->
```

**Discovery**: CLAUDE.md uses HTML comment markers for section boundaries, enabling programmatic extraction

**Sections Relevant to Plan Generation**:
- `plan_metadata_standard` - Phase metadata specification
- `directory_protocols` - Topic-based structure
- `hierarchical_agent_architecture` - Agent coordination patterns
- `code_standards` - Bash conditional patterns
- `output_formatting` - Console output standards

**Extraction Method**: Parse CLAUDE.md between `<!-- SECTION: name -->` and `<!-- END_SECTION: name -->` markers

### Finding 3: Command Context Injection Points

**Source**: Command authoring standards (code-standards.md:422-433)

**Pattern**: Commands inject standards via Task tool prompt

**Example Integration** (plan-metadata-standard.md:426-433):

```bash
# In command bash block (before Task invocation)
source "${CLAUDE_LIB}/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)

# In Task prompt
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    **Project Standards**:
    ${FORMATTED_STANDARDS}

    [Rest of context...]
}
```

**Critical Requirement**: Commands MUST invoke standards extraction before Task delegation

**Current Status in /lean-plan**: Unknown if Block 1c or Block 1e invokes standards extraction

### Finding 4: Validation Infrastructure Integration

**Source**: plan-metadata-standard.md:449-478

**Validation Layers**:

1. **validate-plan-metadata.sh** (line 449-457)
   - Standalone validator for plan metadata format
   - Returns ERROR/WARNING/INFO messages
   - Exit 0: pass, Exit 1: errors

2. **pre-commit Hook** (line 462-469)
   - Automatically validates staged plan files
   - Blocks commits on ERROR-level violations
   - Location: `.claude/hooks/pre-commit`

3. **validate-all-standards.sh** (line 471-478)
   - Unified validation runner
   - Includes `--plans` category for metadata validation
   - Run via `bash .claude/scripts/validate-all-standards.sh --plans`

4. **Agent Self-Validation** (line 481-492)
   - plan-architect validates own output before returning
   - Uses `validate-plan-metadata.sh` in STEP 3
   - Fail-fast on validation errors

**Integration Point**: Commands should validate generated plans before completion

**Current Status in /lean-plan**: Unknown if Block 1e (planning phase) includes validation checkpoint

### Finding 5: Behavioral Injection Pattern for Agents

**Source**: code-standards.md:29, hierarchical-agents-overview.md:36-49

**Pattern Description**:

> **Behavioral Injection**: Agents receive behavior through runtime injection rather than hardcoded instructions

**Example** (hierarchical-agents-overview.md:40-48):

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Context:
    - Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
}
```

**Key Principle**: Agents read behavioral guidelines from `.claude/agents/*.md` files, not from command inline instructions

**Application to lean-plan**:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Create Lean implementation plan"
  prompt: |
    Read and follow: .claude/agents/lean-plan-architect.md

    **Project Standards** (from CLAUDE.md):
    ${FORMATTED_STANDARDS}

    **Research Reports**:
    ${REPORT_PATHS_JSON}

    **Feature Description**:
    ${FEATURE_DESCRIPTION}
}
```

**Current Gap**: If standards extraction not invoked, `${FORMATTED_STANDARDS}` variable empty

### Finding 6: Directory Protocols Integration

**Source**: CLAUDE.md:17-30 (directory_protocols section)

**Topic-Based Structure**:

```
specs/
  NNN_topic/
    plans/
      001-plan-name.md
      001-plan-name/         # Level 1 expansion (phases)
        phase_1_name.md
        phase_2_name.md
    reports/
      001-report-name.md
      002-report-name.md
    summaries/
      001-summary-name.md
    debug/
      root_cause_analysis.md
```

**Plan Naming Convention**: `001-topic-slug-plan.md`

**Integration with /lean-plan**:

1. Topic directory created by topic-naming-agent
2. Reports directory pre-calculated by command
3. Plans directory created during planning phase
4. Plan filename follows `NNN-slug-plan.md` convention

**Verification**: Check if generated plan follows naming convention

**Current Status**: Plan at `.claude/specs/053_p6_perpetuity_theorem_derive/plans/001-p6-perpetuity-theorem-derive-plan.md` DOES follow convention

### Finding 7: Hard Barrier Pattern for Agent Delegation

**Source**: hierarchical-agents-overview.md:609-616, research-coordinator.md:139-194

**Pattern Definition**:

> This agent follows the hard barrier pattern:
> 1. **Path Pre-Calculation**: Primary agent calculates REPORT_DIR before invoking coordinator
> 2. **Coordinator Pre-Calculates Paths**: Coordinator calculates individual report paths BEFORE invoking research-specialist
> 3. **Artifact Validation**: Coordinator validates all reports exist AFTER research-specialist returns
> 4. **Fail-Fast**: Workflow aborts if any report missing (mandatory delegation)

**Application to /lean-plan**:

1. **Block 1c**: Calculate REPORT_DIR before research phase
2. **Block 1d**: Pre-calculate individual report paths (REPORT_PATHS_JSON)
3. **Block 1e**: Invoke research-coordinator with pre-calculated paths
4. **Block 1f**: Validate reports exist before planning phase
5. **Block 1g**: Invoke lean-plan-architect with report paths

**Current Issue**: Block 1d fails with bash syntax error, preventing path pre-calculation

**Impact**: Hard barrier pattern broken, research phase skipped, planning phase lacks research context

### Finding 8: Plan Metadata Standard Cross-References

**Source**: plan-metadata-standard.md:647-653

**Related Documentation Links**:

- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md) - Command development patterns
- [Standards Integration Pattern](.claude/docs/guides/patterns/standards-integration.md) - How standards are injected into workflows
- [Enforcement Mechanisms](.claude/docs/reference/standards/enforcement-mechanisms.md) - Pre-commit hooks and validation infrastructure
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Topic-based directory structure for plans and artifacts
- [Development Workflow](.claude/docs/concepts/development-workflow.md) - Overall development workflow including plan creation

**Integration Architecture**: Plan generation integrates with 5 major documentation areas

**Verification Needed**: Check if all referenced files exist and contain relevant integration guidance

### Finding 9: Enforcement Mechanisms Reference

**Source**: CLAUDE.md:173-220 (code_quality_enforcement section)

**Validation Commands**:

```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run specific validator categories
bash .claude/scripts/validate-all-standards.sh --sourcing      # Library sourcing
bash .claude/scripts/validate-all-standards.sh --suppression   # Error suppression
bash .claude/scripts/validate-all-standards.sh --conditionals  # Bash conditionals
bash .claude/scripts/validate-all-standards.sh --readme        # README structure
bash .claude/scripts/validate-all-standards.sh --links         # Link validity
bash .claude/scripts/validate-all-standards.sh --plans         # Plan metadata (inferred)

# Staged files only (pre-commit mode)
bash .claude/scripts/validate-all-standards.sh --staged
```

**Enforcement Tools Table** (CLAUDE.md:206-213):

| Tool | Checks | Severity |
|------|--------|----------|
| check-library-sourcing.sh | Three-tier sourcing, fail-fast handlers | ERROR |
| lint_error_suppression.sh | State persistence suppression, deprecated paths | ERROR |
| lint_bash_conditionals.sh | Preprocessing-unsafe conditionals | ERROR |
| validate-readmes.sh | README structure | WARNING |
| validate-links-quick.sh | Internal link validity | WARNING |

**Missing Entry**: `validate-plan-metadata.sh` not in enforcement tools table but referenced in plan-metadata-standard.md

**Action Required**: Add validate-plan-metadata.sh to enforcement mechanisms table

### Finding 10: Preprocessing-Safe Conditional Standard

**Source**: code-standards.md:34-89, bash-block-execution-model.md

**Anti-Pattern** (causes lean-plan error):

```bash
# Preprocessing-unsafe (causes syntax error)
if [[ ! "$VAR" =~ ^/ ]]; then
```

**Safe Pattern** (from Spec 005 fix):

```bash
# Preprocessing-safe (split into separate test + comparison)
[[ "${VAR:-}" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
```

**Enforcement Tool**: `lint_bash_conditionals.sh` (ERROR-level)

**Integration with /lean-plan**: Fix required at line 937

**Documentation Reference**: bash-block-execution-model.md documents preprocessing behavior

## Recommendations

### Recommendation 1: Verify standards-extraction.sh Implementation

**Action**: Read `/home/benjamin/.config/.claude/lib/plan/standards-extraction.sh`

**Check List**:
- [ ] File exists at expected location
- [ ] `format_standards_for_prompt()` function defined
- [ ] Function parses CLAUDE.md section markers
- [ ] `plan_metadata_standard` section included in extraction array
- [ ] Function returns formatted string for agent context

**If Missing**: Create standards-extraction.sh following specification in plan-metadata-standard.md

**Test**: Run `format_standards_for_prompt()` and verify output includes phase metadata section

### Recommendation 2: Add Standards Extraction to /lean-plan Command

**Location**: `/home/benjamin/.config/.claude/commands/lean-plan.md`

**Integration Point**: Block 1e (before lean-plan-architect Task invocation)

**Code Addition**:

```bash
# Source standards extraction library
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/standards-extraction.sh" 2>/dev/null || {
  echo "WARNING: standards-extraction.sh not found, proceeding without standards context" >&2
}

# Extract formatted standards for agent context
if command -v format_standards_for_prompt &>/dev/null; then
  FORMATTED_STANDARDS=$(format_standards_for_prompt)
  echo "✓ Standards extracted for planning agent context"
else
  FORMATTED_STANDARDS=""
  echo "⚠ Standards extraction unavailable"
fi

# Persist for next block
append_workflow_state "FORMATTED_STANDARDS"
```

**Task Prompt Update**: Add `${FORMATTED_STANDARDS}` to lean-plan-architect context

**Validation**: After fix, verify agent receives phase metadata standard in prompt

### Recommendation 3: Add Validation Checkpoint to /lean-plan

**Location**: After lean-plan-architect returns (Block 1e or 1f)

**Code Addition**:

```bash
# Validate generated plan metadata
if [ -f "${PLAN_PATH}" ]; then
  echo "Validating plan metadata format..."

  # Run validator if available
  if [ -f "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh" ]; then
    bash "${CLAUDE_PROJECT_DIR}/.claude/scripts/lint/validate-plan-metadata.sh" "$PLAN_PATH"
    VALIDATION_EXIT=$?

    if [ $VALIDATION_EXIT -ne 0 ]; then
      log_command_error \
        "$COMMAND_NAME" \
        "$WORKFLOW_ID" \
        "$USER_ARGS" \
        "validation_error" \
        "Generated plan failed metadata validation" \
        "plan_validation" \
        "$(jq -n --arg path "$PLAN_PATH" '{plan_path: $path}')"

      echo "WARNING: Plan metadata validation failed (exit code $VALIDATION_EXIT)" >&2
      echo "Plan created but may not meet metadata standards" >&2
      # Don't exit - allow workflow to complete with warning
    else
      echo "✓ Plan metadata validation passed"
    fi
  else
    echo "⚠ Plan metadata validator not found, skipping validation"
  fi
fi
```

**Integration**: Add between plan generation and final summary display

**Non-Blocking**: Validation warnings should not block workflow completion

### Recommendation 4: Create validate-plan-metadata.sh Script

**Location**: `/home/benjamin/.config/.claude/scripts/lint/validate-plan-metadata.sh`

**Functionality**:

1. **Parse Metadata Section**: Extract fields from `## Metadata` section
2. **Validate Required Fields**: Date, Feature, Status, Estimated Hours, Standards File, Research Reports
3. **Validate Field Formats**: Date pattern, Status bracket notation, Hours range, etc.
4. **Parse Phase Metadata**: Extract phase-level fields (implementer, dependencies, lean_file)
5. **Validate Phase Formats**: implementer values, dependencies array, lean_file paths
6. **Return Results**: Exit 0 (pass), Exit 1 (ERROR), output formatted messages

**Validation Levels**:
- ERROR: Missing required field, invalid format (blocks commits)
- WARNING: Field present but suboptimal (informational)
- INFO: Optional field missing (informational)

**Testing**: Create test plans with various metadata configurations

**Integration**: Add to pre-commit hook and validate-all-standards.sh

### Recommendation 5: Update Enforcement Mechanisms Documentation

**Location**: `/home/benjamin/.config/.claude/docs/reference/standards/enforcement-mechanisms.md`

**Additions**:

1. **Enforcement Tools Table**: Add validate-plan-metadata.sh entry
2. **Pre-Commit Hook**: Document plan metadata validation integration
3. **validate-all-standards.sh**: Add `--plans` category documentation
4. **Agent Self-Validation**: Document plan-architect validation pattern

**Cross-Reference**: Link to plan-metadata-standard.md for field specifications

### Recommendation 6: Document Standards Integration Pattern

**Location**: Create `/home/benjamin/.config/.claude/docs/guides/patterns/standards-integration.md`

**Content Sections**:

1. **Overview**: Purpose of standards extraction and injection
2. **Architecture**: standards-extraction.sh library design
3. **Integration Points**: Where commands inject standards
4. **Agent Context**: How agents receive formatted standards
5. **Validation**: How standards are enforced
6. **Examples**: Complete code examples for common patterns
7. **Troubleshooting**: Common integration issues

**Cross-References**: Link from CLAUDE.md, command-authoring.md, plan-metadata-standard.md

### Recommendation 7: Add lint_bash_conditionals.sh Validation

**Location**: `/home/benjamin/.config/.claude/scripts/lint/lint_bash_conditionals.sh`

**Enhancement**: Ensure linter catches `if [[ ! ... =~ ... ]]` pattern

**Test Pattern**:

```bash
# Should trigger ERROR
if [[ ! "$VAR" =~ ^/ ]]; then

# Should pass
[[ "${VAR:-}" = /* ]]
IS_ABSOLUTE=$?
if [ $IS_ABSOLUTE -ne 0 ]; then
```

**Integration**: Verify pre-commit hook runs this linter on `.claude/commands/*.md` files

**Enforcement**: ERROR-level violation blocks commits

### Recommendation 8: Create Integration Test Suite

**Purpose**: Validate complete standards integration pipeline

**Test Scenarios**:

1. **Standards Extraction**: Verify format_standards_for_prompt() output
2. **Agent Context Injection**: Verify agents receive formatted standards
3. **Plan Generation**: Verify generated plans include phase metadata
4. **Validation Enforcement**: Verify validate-plan-metadata.sh catches errors
5. **Pre-Commit Hook**: Verify hook blocks commits with invalid metadata

**Test Location**: `/home/benjamin/.config/.claude/tests/integration/standards-integration/`

**Execution**: Run via `/test` command or directly with pytest/bash

**Coverage Target**: 90%+ of integration points validated

## Validation Checklist

After implementing recommendations:

- [ ] standards-extraction.sh exists and includes plan_metadata_standard
- [ ] format_standards_for_prompt() returns formatted phase metadata section
- [ ] /lean-plan command invokes standards extraction before Task delegation
- [ ] lean-plan-architect receives FORMATTED_STANDARDS in context
- [ ] Generated plans include phase-level metadata fields
- [ ] validate-plan-metadata.sh script created and functional
- [ ] Pre-commit hook runs plan metadata validation
- [ ] validate-all-standards.sh includes --plans category
- [ ] Enforcement mechanisms documentation updated
- [ ] Standards integration pattern guide created

## Integration Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         CLAUDE.md                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ <!-- SECTION: plan_metadata_standard -->            │   │
│  │ Phase metadata specification...                     │   │
│  │ <!-- END_SECTION: plan_metadata_standard -->        │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │  standards-extraction.sh    │
         │  format_standards_for_prompt│
         └──────────────┬──────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │   /lean-plan    │
              │   Command       │
              └────────┬────────┘
                       │
                       ▼
            ┌────────────────────┐
            │  Task {            │
            │    FORMATTED_      │
            │    STANDARDS       │
            │  }                 │
            └────────┬───────────┘
                     │
                     ▼
         ┌────────────────────────┐
         │ lean-plan-architect    │
         │ Receives standards     │
         │ Generates plan with    │
         │ phase metadata         │
         └────────┬───────────────┘
                  │
                  ▼
       ┌─────────────────────────┐
       │ validate-plan-metadata. │
       │ sh                      │
       │ Validates format        │
       └────────┬────────────────┘
                │
                ▼
      ┌──────────────────────┐
      │  Pre-Commit Hook     │
      │  Blocks invalid      │
      │  metadata            │
      └──────────────────────┘
```

## Related Standards

**Primary Integration Points**:
- Plan Metadata Standard: `/home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md`
- Command Authoring Standards: `.claude/docs/reference/standards/command-authoring.md`
- Code Standards: `.claude/docs/reference/standards/code-standards.md`
- Enforcement Mechanisms: `.claude/docs/reference/standards/enforcement-mechanisms.md`

**Supporting Documentation**:
- Hierarchical Agent Architecture: `.claude/docs/concepts/hierarchical-agents-overview.md`
- Directory Protocols: `.claude/docs/concepts/directory-protocols.md`
- Bash Block Execution Model: `.claude/docs/concepts/bash-block-execution-model.md`

## Conclusion

The .claude/docs/ infrastructure provides comprehensive standards for plan metadata generation but requires activation of dormant integration points. The fix involves:

1. **Library Implementation**: Create/verify standards-extraction.sh with format_standards_for_prompt()
2. **Command Integration**: Add standards extraction to /lean-plan before agent Task invocation
3. **Agent Context**: Ensure lean-plan-architect receives FORMATTED_STANDARDS in prompt
4. **Validation Enforcement**: Create validate-plan-metadata.sh and integrate with pre-commit hooks
5. **Documentation**: Update enforcement mechanisms and create standards integration guide

The infrastructure design is sound - the gap is in activation and enforcement, not in architectural design.

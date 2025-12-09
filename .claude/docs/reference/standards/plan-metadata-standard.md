# Plan Metadata Standard

## Overview

This document defines the canonical metadata standard for all implementation plans created by plan-generating commands (/plan, /repair, /revise, /debug). Uniform metadata structure enables consistent parsing, validation, and tooling integration across all workflows.

## Purpose

**Objectives**:
- Define required and optional metadata fields for all plans
- Establish validation rules for field formats and content
- Enable consistent plan parsing by tooling (metadata-extraction.sh, plan-core-bundle.sh)
- Support workflow-specific extensions without breaking base standard
- Provide migration path from legacy metadata formats

**Benefits**:
- Automated validation via pre-commit hooks and linters
- Consistent plan structure across /plan, /repair, /revise, /debug
- Reliable metadata extraction for progress tracking and reporting
- Self-documenting plans with traceability to standards and research

## Required Metadata Fields

All plans MUST include these fields. Missing fields generate ERROR-level validation failures that block commits.

### 1. Date
- **Format**: `YYYY-MM-DD` or `YYYY-MM-DD (Revised)`
- **Description**: Plan creation date or last revision date
- **Validation**: Must match ISO 8601 date format, optional "(Revised)" suffix
- **Example**:
  ```markdown
  - **Date**: 2025-12-02
  - **Date**: 2025-12-02 (Revised)
  ```

### 2. Feature
- **Format**: Single-line description, 50-100 characters
- **Description**: What is being implemented (feature, fix, refactor, etc.)
- **Validation**: Must be non-empty, single line
- **Example**:
  ```markdown
  - **Feature**: Enforce uniform plan metadata standards across all plan-generating commands
  ```

### 3. Status
- **Format**: `[NOT STARTED]`, `[IN PROGRESS]`, `[COMPLETE]`, or `[BLOCKED]`
- **Description**: Current plan execution status
- **Validation**: Must use exact bracket notation with uppercase status
- **Example**:
  ```markdown
  - **Status**: [IN PROGRESS]
  ```

### 4. Estimated Hours
- **Format**: `{low}-{high} hours` or `{low}-{high} hours (revised from {old_low}-{old_high} to reflect {reason})`
- **Description**: Time estimate as numeric range with optional revision explanation
- **Validation**: Must match pattern `\d+-\d+ hours`, optional revision context
- **Example**:
  ```markdown
  - **Estimated Hours**: 11-15 hours
  - **Estimated Hours**: 11-15 hours (revised from 12-16 to reflect Phase 1 expansion)
  ```

### 5. Standards File
- **Format**: `/absolute/path/to/CLAUDE.md`
- **Description**: Absolute path to standards file for traceability
- **Validation**: Must be absolute path (starts with `/`), typically points to CLAUDE.md
- **Example**:
  ```markdown
  - **Standards File**: /home/benjamin/.config/CLAUDE.md
  ```

### 6. Research Reports
- **Format**: Markdown link list with relative paths, or `none` if no research phase
- **Description**: Links to research reports that informed the plan
- **Validation**: Must use relative paths (e.g., `../reports/`), markdown link format, or literal `none`
- **Example**:
  ```markdown
  - **Research Reports**:
    - [Repair Plan Standards Analysis](../reports/001-repair-plan-standards-analysis.md)
    - [Plan Revision: Standards Documentation Architecture](../reports/002-revise-plan-standards-documentation.md)
  - **Research Reports**: none
  ```

## Optional Metadata Fields

These fields are recommended but not required. Missing fields generate INFO-level messages.

### 7. Scope
- **Format**: Multi-line description
- **Description**: Detailed scope description for complex plans
- **When to Include**: Plans with complexity score > 60, multi-phase implementations
- **Example**:
  ```markdown
  - **Scope**: Create canonical plan metadata standard in .claude/docs/reference/standards/, add lightweight CLAUDE.md reference section, update /repair command to use standard context format, create validation infrastructure, and update plan-architect agent for self-validation
  ```

### 8. Complexity Score
- **Format**: Numeric value (0-100)
- **Description**: Complexity score calculated by plan-architect
- **When to Include**: Always include when plan-architect calculates it
- **Example**:
  ```markdown
  - **Complexity Score**: 78.5
  ```

### 9. Structure Level
- **Format**: `0`, `1`, or `2`
- **Description**: Plan structure tier (0 = single file, 1 = phase expansion, 2 = stage expansion)
- **When to Include**: Always include to track plan organization level
- **Example**:
  ```markdown
  - **Structure Level**: 0
  ```

### 10. Estimated Phases
- **Format**: Numeric value
- **Description**: Phase count estimate before detailed planning
- **When to Include**: Include when known from initial complexity assessment
- **Example**:
  ```markdown
  - **Estimated Phases**: 5
  ```

## Phase-Level Metadata (Optional)

Phase-level metadata enables explicit orchestration control through unambiguous implementer type declaration, dependency tracking for wave-based parallelization, and Lean file associations for theorem proving phases.

**When to Include**: Use phase-level metadata when:
- Plans contain mixed Lean/software phases requiring different coordinators
- Phase dependencies enable parallel wave execution
- Explicit implementer declaration eliminates classification ambiguity

**Format**: Add metadata fields immediately after phase heading, before tasks list:

```markdown
### Phase N: Phase Name [NOT STARTED]
implementer: lean|software
lean_file: /absolute/path/to/file.lean
dependencies: [1, 2]

Tasks:
- [ ] Task 1
- [ ] Task 2
```

### implementer

- **Format**: `implementer: lean` or `implementer: software`
- **Description**: Explicit phase type declaration for coordinator routing
- **When to Include**: Mixed Lean/software plans requiring unambiguous phase classification
- **Validation**: If present, value must be exactly "lean" or "software" (case-sensitive)
- **Example**:
  ```markdown
  ### Phase 1: Core Theorem Implementation [NOT STARTED]
  implementer: lean
  lean_file: /home/user/project/theories/Core.lean
  dependencies: []

  Tasks:
  - [ ] Prove associativity lemma
  - [ ] Prove commutativity theorem
  ```

**Usage Notes**:
- **3-Tier Detection**: Phase classification uses three tiers (strongest signal wins):
  1. Tier 1: `implementer:` field (strongest - no ambiguity)
  2. Tier 2: `lean_file:` field presence (backward compatibility)
  3. Tier 3: Keyword analysis fallback (weakest - prone to misclassification)
- **Coordinator Routing**: `/lean-implement` routes phases to appropriate coordinators:
  - `implementer: lean` → `lean-coordinator.md` (theorem proving workflow)
  - `implementer: software` → `implementer-coordinator.md` (software implementation workflow)

### dependencies

- **Format**: `dependencies: []` or `dependencies: [1, 2, 3]`
- **Description**: Space-separated list of phase numbers that must complete before this phase
- **When to Include**: Plans with independent phases enabling wave-based parallel execution
- **Validation**: If present, format must be valid array notation with numeric phase numbers
- **Example**:
  ```markdown
  ### Phase 3: Integration Layer [NOT STARTED]
  implementer: software
  dependencies: [1, 2]

  Tasks:
  - [ ] Integrate authentication module (depends on Phase 1)
  - [ ] Integrate caching layer (depends on Phase 2)
  ```

**Usage Notes**:
- **Wave Construction**: `/lean-implement` Block 1a builds execution waves from dependency graph
- **Parallel Execution**: Phases with no mutual dependencies execute in parallel (40-60% time savings)
- **Dependency Format**: Empty array `[]` indicates no dependencies (can start in Wave 1)
- **Cross-Reference**: See [Wave-Based Parallelization Documentation](./../guides/commands/lean-implement-command-guide.md#wave-based-execution)

### lean_file

- **Format**: `lean_file: /absolute/path/to/file.lean`
- **Description**: Absolute path to Lean source file for theorem proving phases
- **When to Include**: All Lean theorem proving phases (enables proof validation and build verification)
- **Validation**: If present, path must be absolute (starts with `/`) and end with `.lean` extension
- **Example**:
  ```markdown
  ### Phase 2: Decidability Proofs [IN PROGRESS]
  implementer: lean
  lean_file: /home/user/project/theories/Decidable.lean
  dependencies: [1]

  Tasks:
  - [ ] Prove decidability for equality
  - [ ] Prove decidability for ordering
  ```

**Usage Notes**:
- **Backward Compatibility**: Presence of `lean_file:` field triggers Tier 2 phase classification (Lean phase)
- **Build Integration**: `/lean-build` uses `lean_file:` to locate source files for proof building
- **Multiple Files**: If phase spans multiple files, use primary file path (others referenced in tasks)

### Status Marker Lifecycle

Phase headings support status markers tracking progress through implementation:

**Marker Progression**:
```
[NOT STARTED] → [IN PROGRESS] → [COMPLETE]
```

**Format Support**:
- **H2 Headings**: `## Phase 1: Phase Name [NOT STARTED]`
- **H3 Headings**: `### Phase 1: Phase Name [NOT STARTED]`

Both formats are valid. Choose H3 for consistency with optional metadata fields below headings.

**Automated Updates**:
- `add_in_progress_marker()` - Marks phase as IN PROGRESS when coordinator begins execution
- `mark_phase_complete()` - Marks all tasks complete and adds COMPLETE marker
- `add_complete_marker()` - Adds COMPLETE marker after verification

**Cross-Reference**: See [Plan Progress Tracking](./plan-progress.md) for detailed status marker behavior and checkbox synchronization.

### Heading Level Flexibility

Phase headings support both H2 (`##`) and H3 (`###`) formats:

**H2 Format** (Traditional):
```markdown
## Phase 1: Phase Name [NOT STARTED]

Tasks:
- [ ] Task 1
```

**H3 Format** (With Metadata):
```markdown
### Phase 1: Phase Name [NOT STARTED]
implementer: lean
lean_file: /path/to/file.lean
dependencies: []

Tasks:
- [ ] Task 1
```

**Recommendation**: Use H3 format when including phase-level metadata (visual hierarchy: metadata indented under heading).

### Validation Rules

Phase-level metadata fields are **optional**. Validation only enforces format when fields are present:

**Format Validation** (ERROR-level if field present but malformed):
- `implementer:` must be exactly "lean" or "software"
- `dependencies:` must be valid array notation: `[]` or `[N, N, N]` with numeric values
- `lean_file:` must be absolute path ending with `.lean` extension

**Omission Validation** (No errors):
- Missing phase metadata fields are acceptable (fallback classification applies)
- Plans without any phase metadata are valid (Tier 3 keyword-based classification used)

**Examples of Mixed Lean/Software Plans**:

See real-world examples:
- [Spec 028: Lean Subagent Orchestration](../../specs/028_lean_subagent_orchestration/plans/001-lean-subagent-orchestration-plan.md) - Mixed plan with explicit `implementer:` fields
- [Spec 032: Lean Plan Command](../../specs/032_lean_plan_command/plans/001-lean-plan-command-plan.md) - Pure Lean plan with `lean_file:` associations
- [Spec 037: Lean Metadata Phase Refactor](../../specs/037_lean_metadata_phase_refactor/plans/001-lean-metadata-phase-refactor-plan.md) - Infrastructure plan with software phases only

## Workflow-Specific Optional Fields

Workflow-specific fields extend the base standard without breaking validation.

### /repair Command

Plans generated by /repair may include:

- **Error Log Query**: Filter parameters used to query error log
  ```markdown
  - **Error Log Query**: --since 24h --type state_error --command /implement
  ```

- **Errors Addressed**: Count of errors addressed by repair plan
  ```markdown
  - **Errors Addressed**: 12 state_error instances across 3 commands
  ```

### /revise Command

Plans revised by /revise may include:

- **Original Plan**: Link to original plan being revised
  ```markdown
  - **Original Plan**: [Original Implementation Plan](../plans/001-original-plan.md)
  ```

- **Revision Reason**: Brief explanation of why revision was needed
  ```markdown
  - **Revision Reason**: Expand Phase 1 to include standards-extraction.sh integration
  ```

### Automated Execution Contexts

Plans with automated test execution requirements may include phase-level automation metadata. This enables non-interactive test execution, CI/CD integration, and wave-based parallel test orchestration.

**When to Include**: Test phases should include automation metadata when:
- Plan complexity >= 3 (multi-phase test workflows)
- CI/CD integration required (automated validation gates)
- Wave-based parallel execution used (independent test phases)

**Phase-Level Automation Fields**:

- **automation_type**: Execution mode (`automated` or `manual`)
  ```markdown
  automation_type: automated
  ```

- **validation_method**: Validation approach (`programmatic`, `visual`, or `artifact`)
  ```markdown
  validation_method: programmatic
  ```

- **skip_allowed**: Whether phase can be skipped (`true` or `false`)
  ```markdown
  skip_allowed: false
  ```

- **artifact_outputs**: Test artifacts generated (array of file paths)
  ```markdown
  artifact_outputs: [test-results.xml, coverage.json]
  ```

**Validation Rules**:
- `automation_type` must be exactly "automated" or "manual" (case-sensitive)
- `validation_method` must be "programmatic", "visual", or "artifact"
- `skip_allowed` must be boolean literal `true` or `false`
- `artifact_outputs` must be valid array notation (can be empty: `[]`)
- Interactive anti-patterns (e.g., "manually verify", "skip if needed") trigger ERROR-level violations

**Example Phase with Automation Metadata**:
```markdown
### Phase 3: Unit Testing [NOT STARTED]

automation_type: automated
validation_method: programmatic
skip_allowed: false
artifact_outputs: [test-results.xml, coverage.json]

**Tasks**:
- [ ] Execute test suite: `pytest tests/ --junitxml=test-results.xml || exit 1`
- [ ] Validate coverage: `pytest --cov=src --cov-report=json:coverage.json || exit 1`
```

**Cross-Reference**: See [Non-Interactive Testing Standard](./non-interactive-testing-standard.md) for complete automation requirements, anti-pattern detection, and integration with planning commands.

## Metadata Section Placement

The `## Metadata` section MUST:
1. Appear immediately after the plan title (H1 heading)
2. Precede all other sections (Overview, Research Summary, etc.)
3. Use `## Metadata` as the exact heading text
4. List fields as markdown list items with bold field names

**Correct Structure**:
```markdown
# Plan Title

## Metadata
- **Date**: 2025-12-02
- **Feature**: Description
- **Status**: [NOT STARTED]
- **Estimated Hours**: 10-15 hours
- **Standards File**: /path/to/CLAUDE.md
- **Research Reports**: none

## Overview
[Plan content...]
```

## Validation Rules

### ERROR-Level (Blocks Commits)

- Missing required field (Date, Feature, Status, Estimated Hours, Standards File, Research Reports)
- Invalid Date format (must be YYYY-MM-DD with optional "(Revised)" suffix)
- Invalid Status format (must use bracket notation with approved status)
- Invalid Estimated Hours format (must be numeric range with "hours" suffix)
- Invalid Standards File format (must be absolute path starting with `/`)
- Invalid Research Reports format (must use relative paths with markdown links or literal `none`)

### WARNING-Level (Informational)

- Date format is valid but uses non-standard separator
- Estimated Hours range is unusual (low > high or gap too large)
- Standards File path does not exist on filesystem
- Research Reports link paths do not exist on filesystem

### INFO-Level (Informational)

- Missing optional recommended field (Scope for complex plans, Complexity Score, Structure Level)
- Optional field present but could be improved (e.g., Scope too brief for complex plan)

## Integration Points

### 1. standards-extraction.sh

The `plan_metadata_standard` section from CLAUDE.md is automatically injected into planning context:

```bash
source "${CLAUDE_LIB}/plan/standards-extraction.sh"
FORMATTED_STANDARDS=$(format_standards_for_prompt)

# Agent receives standards in prompt:
# **Project Standards**:
# ${FORMATTED_STANDARDS}
```

**Implementation**: Add `plan_metadata_standard` to extracted sections array in standards-extraction.sh (~line 150-160).

### 2. metadata-extraction.sh

Plan parsing library extracts metadata fields for progress tracking and reporting:

```bash
source "${CLAUDE_LIB}/plan/metadata-extraction.sh"
PLAN_DATE=$(extract_metadata_field "$plan_file" "Date")
PLAN_STATUS=$(extract_metadata_field "$plan_file" "Status")
```

**Backward Compatibility**: Add fallback parsing for legacy field names (e.g., "Estimated Duration" -> "Estimated Hours").

### 3. validate-plan-metadata.sh

Validation script enforces standard compliance:

```bash
bash .claude/scripts/lint/validate-plan-metadata.sh "$plan_file"
# Exit 0: pass, Exit 1: errors
```

**Implementation**: Parse metadata section, validate required fields and formats, return ERROR/WARNING/INFO messages.

### 4. pre-commit Hook

Automatically validates staged plan files before commit:

```bash
# .claude/hooks/pre-commit
for plan_file in $(git diff --cached --name-only --diff-filter=ACM | grep 'specs/.*/plans/.*\.md$'); do
  bash .claude/scripts/lint/validate-plan-metadata.sh "$plan_file" || EXIT_CODE=1
done
```

### 5. validate-all-standards.sh

Unified validation runner includes plan metadata validation:

```bash
bash .claude/scripts/validate-all-standards.sh --plans
bash .claude/scripts/validate-all-standards.sh --all  # includes --plans
```

### 6. plan-architect Agent

Plan-architect validates its own metadata before returning (STEP 3):

```markdown
5. **Verify Metadata Compliance**:
   ```bash
   bash .claude/scripts/lint/validate-plan-metadata.sh "$PLAN_FILE" || {
     echo "ERROR: Plan metadata validation failed"
     exit 1
   }
   ```
```

## Extension Mechanism

### Adding Workflow-Specific Fields

1. **Define Field in Plan-Generating Command**: Add field to Task invocation context
2. **Document Field in This Standard**: Add to "Workflow-Specific Optional Fields" section
3. **Update Validator (Optional)**: If field has strict format requirements, add validation logic
4. **No Breaking Changes**: Base required fields remain unchanged

**Example**: Adding /debug-specific field:

```markdown
### /debug Command

- **Debug Session ID**: Unique identifier for debug session
  ```markdown
  - **Debug Session ID**: debug_20251202_143045
  ```
```

### Adding New Required Fields

**WARNING**: Adding required fields is a breaking change. Follow migration strategy:

1. Add field as optional first (6-month grace period)
2. Update all plan-generating commands to include field
3. Promote to required after all existing plans migrated
4. Update validator to enforce as ERROR-level

## Migration Strategy

### Progressive Migration (Recommended)

- **No Forced Updates**: Existing plans remain valid
- **Natural Revision**: Plans revised via /revise get updated metadata
- **New Plans Only**: Standard applies to plans created after implementation
- **Tooling Compatibility**: metadata-extraction.sh handles both old and new formats

### Backward Compatibility

**Legacy Field Names** (metadata-extraction.sh fallbacks):
- `Estimated Duration` -> `Estimated Hours`
- `Plan ID` -> (not required, ignore if present)
- `Type` -> (not required, ignore if present)
- `Created` -> `Date`

**Legacy Date Formats**:
- ISO 8601 timestamps -> Extract date portion only
- Human-readable dates -> Parse and convert to YYYY-MM-DD

**Legacy Research Reports**:
- Absolute paths -> Convert to relative paths in extraction logic
- JSON arrays -> Parse and convert to markdown link list

### Migration Testing

Verify backward compatibility:

```bash
# Test metadata extraction on old plan
source /home/benjamin/.config/.claude/lib/plan/metadata-extraction.sh
PLAN_DATE=$(extract_metadata_field "old_plan.md" "Date")
[ -n "$PLAN_DATE" ] && echo "Backward compatible extraction works"

# Test validation does not break on old plans (WARNING-level only)
bash .claude/scripts/lint/validate-plan-metadata.sh "old_plan.md"
# Should exit 0 or show WARNINGs only (no ERRORs)
```

## Format Examples

### Minimal Plan (Required Fields Only)

```markdown
# Feature Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Add user authentication to web application
- **Status**: [NOT STARTED]
- **Estimated Hours**: 8-12 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Research Reports**: none

## Overview
[Plan content...]
```

### Complete Plan (All Recommended Fields)

```markdown
# Complex Feature Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Implement hierarchical caching system with Redis integration
- **Scope**: Design cache hierarchy (L1/L2), implement Redis adapter, create cache invalidation strategy, add monitoring instrumentation, write comprehensive test suite
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 24-32 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Complexity Score**: 82.5
- **Structure Level**: 1
- **Estimated Phases**: 6
- **Research Reports**:
  - [Redis Integration Research](../reports/001-redis-integration-research.md)
  - [Cache Invalidation Strategies](../reports/002-cache-invalidation-strategies.md)

## Overview
[Plan content...]
```

### /repair Plan (Workflow-Specific Fields)

```markdown
# Error Repair Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Fix state persistence errors in workflow orchestration
- **Status**: [NOT STARTED]
- **Estimated Hours**: 6-8 hours
- **Standards File**: /home/user/project/CLAUDE.md
- **Error Log Query**: --since 24h --type state_error --command /implement
- **Errors Addressed**: 8 state_error instances across 2 commands
- **Research Reports**:
  - [State Error Analysis](../reports/001-state-error-analysis.md)

## Overview
[Plan content...]
```

### /revise Plan (Revision Fields)

```markdown
# Revised Implementation Plan

## Metadata
- **Date**: 2025-12-02 (Revised)
- **Feature**: Enhanced API authentication with OAuth2 support
- **Scope**: Original scope plus OAuth2 provider integration and token refresh mechanism
- **Status**: [IN PROGRESS]
- **Estimated Hours**: 16-20 hours (revised from 12-16 to reflect OAuth2 complexity)
- **Standards File**: /home/user/project/CLAUDE.md
- **Original Plan**: [Initial API Authentication Plan](../plans/001-api-authentication-plan.md)
- **Revision Reason**: Expand scope to include OAuth2 providers after security review identified requirement
- **Research Reports**:
  - [Original Authentication Research](../reports/001-authentication-research.md)
  - [OAuth2 Provider Comparison](../reports/002-oauth2-provider-comparison.md)

## Overview
[Plan content...]
```

## Related Documentation

- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md) - Command development patterns
- [Standards Integration Pattern](.claude/docs/guides/patterns/standards-integration.md) - How standards are injected into workflows
- [Enforcement Mechanisms](.claude/docs/reference/standards/enforcement-mechanisms.md) - Pre-commit hooks and validation infrastructure
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Topic-based directory structure for plans and artifacts
- [Development Workflow](.claude/docs/concepts/development-workflow.md) - Overall development workflow including plan creation

## Summary

This standard establishes uniform metadata structure for all implementation plans:

**Required Fields** (6): Date, Feature, Status, Estimated Hours, Standards File, Research Reports
**Optional Fields** (4): Scope, Complexity Score, Structure Level, Estimated Phases
**Workflow Extensions**: /repair (Error Log Query, Errors Addressed), /revise (Original Plan, Revision Reason)

**Enforcement**: Automated validation via pre-commit hooks, validate-all-standards.sh --plans, and plan-architect self-validation

**Migration**: Progressive, backward-compatible approach with no forced updates to existing plans

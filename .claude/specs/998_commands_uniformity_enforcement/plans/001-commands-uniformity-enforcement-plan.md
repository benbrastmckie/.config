# Command Infrastructure Uniformity Enforcement Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Command Infrastructure Uniformity Standards
- **Scope**: Standardize argument capture, path initialization, checkpoint format, and block consolidation patterns across `.claude/commands/`
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 47.0
- **Research Reports**:
  - [Command Infrastructure Uniformity Analysis](../reports/001-command-uniformity-research.md)

## Overview

This plan implements uniformity improvements for `.claude/commands/` infrastructure based on comprehensive analysis of 16 active commands. The research identified excellent uniformity in critical areas (state management, error logging, library sourcing) with opportunities for standardization in argument capture, path initialization, checkpoint format, and block consolidation patterns.

**Primary Goals**:
1. Standardize argument capture to 2-block pattern across all commands
2. Document three path initialization patterns with usage guidance
3. Standardize checkpoint format for improved observability
4. Add block consolidation guidelines for workflow commands
5. Create validation helper library to reduce duplication

## Research Summary

The research report analyzed all commands in `.claude/commands/` and found:

**Strengths** (100% compliance):
- State management using workflow-state-machine.sh >=2.0.0
- Error logging integration with centralized error-handling.sh
- Library sourcing following mandatory three-tier pattern
- Defensive programming with validation at every boundary

**Opportunities** (variation without standards):
- **Argument capture**: Variation between single-block and two-block patterns
- **Path initialization**: Three different approaches without explicit documentation
- **Checkpoint format**: Varying detail levels and formats
- **Block consolidation**: No guidance on when to consolidate vs. discrete blocks

**Recommended Priorities**:
- High: Standardize argument capture (2-block pattern), document path initialization, standardize checkpoint format
- Medium: Mandate hard barrier pattern, add block consolidation guidelines
- Low: Create command pattern quick reference, add validation helper library

## Success Criteria

- [ ] All commands use standardized 2-block argument capture pattern
- [ ] Path initialization patterns documented with clear usage guidance
- [ ] Checkpoint format standardized with consistent detail level
- [ ] Block consolidation guidelines added to command development standards
- [ ] Validation helper library created and integrated into 2+ commands
- [ ] Command pattern quick reference created for developer onboarding
- [ ] All standards additions are enforceable via pre-commit hooks or linting
- [ ] Test suite updated to validate new patterns
- [ ] All changes validated against existing command functionality (no regressions)

## Technical Design

### Architecture Overview

**Standards Layer** (documentation):
- Update `command-development-fundamentals.md` with new patterns
- Update `output-formatting.md` with checkpoint format standard
- Create `command-patterns-quick-reference.md` in `.claude/docs/reference/`

**Library Layer** (code):
- Create `validation-utils.sh` in `.claude/lib/workflow/`
- Add functions: `validate_workflow_prerequisites()`, `validate_agent_artifact()`, `validate_absolute_path()`

**Command Layer** (templates and implementations):
- Update command templates to reflect new patterns
- Refactor existing commands to use standardized patterns
- Add inline comments referencing standards sections

**Enforcement Layer** (validation):
- Create validator script for argument capture pattern
- Create validator script for checkpoint format
- Integrate validators into `validate-all-standards.sh`
- Add to pre-commit hook workflow

### Component Interactions

```
Standards Docs ──> Command Templates ──> Command Implementations
                                                 │
                                                 ├──> validation-utils.sh
                                                 └──> workflow-state-machine.sh
                                                           (existing)

Validators ──────> validate-all-standards.sh ──> Pre-commit Hook
```

### Design Decisions

1. **2-Block Argument Capture Pattern**: Separates mechanical capture (Block 1) from parsing/validation logic (Block 2), improving debuggability
2. **Three Path Init Patterns**: Codifies existing practices rather than forcing single approach (different commands have different needs)
3. **Checkpoint Format Standard**: Balances observability with verbosity, uses consistent structure
4. **Validation Helper Library**: Reduces duplication, centralizes common validation patterns
5. **Progressive Rollout**: Document standards first, then update templates, then refactor commands incrementally

## Implementation Phases

### Phase 1: Standards Documentation [NOT STARTED]
dependencies: []

**Objective**: Document new patterns in command development standards

**Complexity**: Low

Tasks:
- [ ] Update `command-development-fundamentals.md` with 2-block argument capture pattern standard
  - Location: `.claude/docs/reference/standards/command-development-fundamentals.md`
  - Add section "Argument Capture Pattern" with template code
  - Document rationale: separation of capture from logic
- [ ] Add path initialization patterns section to `command-development-fundamentals.md`
  - Document Pattern A (Topic Naming Agent): For new topics with semantic naming
  - Document Pattern B (Direct Naming): For timestamp-based allocation
  - Document Pattern C (Path Derivation): For operations on existing topics
  - Add decision tree: When to use which pattern
- [ ] Update `output-formatting.md` with standardized checkpoint format
  - Add section "Checkpoint Reporting Format"
  - Include template with {Phase name}, {Context vars}, {Ready for}
  - Document verbosity guidelines (when to include extra context)
- [ ] Add block consolidation guidelines to `command-development-fundamentals.md`
  - Add section "Block Consolidation Strategy"
  - Document guidance: Linear workflows (<5 phases) prefer discrete blocks, complex workflows (>5 phases) consider consolidation
  - Include performance vs. clarity tradeoffs

Testing:
```bash
# Verify documentation structure
bash .claude/scripts/validate-readmes.sh --check .claude/docs/reference/standards/command-development-fundamentals.md
bash .claude/scripts/validate-readmes.sh --check .claude/docs/reference/standards/output-formatting.md

# Verify links work
bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/
```

**Expected Duration**: 2 hours

### Phase 2: Validation Helper Library [NOT STARTED]
dependencies: [1]

**Objective**: Create reusable validation functions to reduce duplication

**Complexity**: Medium

Tasks:
- [ ] Create `.claude/lib/workflow/validation-utils.sh`
  - Add standard library header with version, dependencies
  - Source error-handling.sh for error logging integration
- [ ] Implement `validate_workflow_prerequisites()` function
  - Check for required functions: `save_completed_states_to_state`, `init_workflow_state`, etc.
  - Return 0 on success, 1 on failure
  - Log errors to error log with validation_error type
- [ ] Implement `validate_agent_artifact()` function
  - Parameters: artifact_path, min_size_bytes, artifact_type
  - Check file existence and minimum size
  - Log errors with agent_error type
  - Return 0 on success, 1 on failure
- [ ] Implement `validate_absolute_path()` function
  - Check if path starts with `/`
  - Check if path exists (optional)
  - Return 0 on success, 1 on failure
- [ ] Add unit tests for validation-utils.sh
  - Create `.claude/tests/lib/test_validation_utils.sh`
  - Test each function with valid/invalid inputs
  - Test error logging integration

Testing:
```bash
# Run unit tests
bash .claude/tests/lib/test_validation_utils.sh

# Verify library can be sourced
bash -c "source .claude/lib/workflow/validation-utils.sh && declare -F validate_workflow_prerequisites"

# Run library sourcing validator
bash .claude/scripts/check-library-sourcing.sh .claude/lib/workflow/validation-utils.sh
```

**Expected Duration**: 3 hours

### Phase 3: Command Pattern Quick Reference [NOT STARTED]
dependencies: [1, 2]

**Objective**: Create developer reference for common command patterns

**Complexity**: Low

Tasks:
- [ ] Create `.claude/docs/reference/command-patterns-quick-reference.md`
  - Add header with purpose, audience, navigation links
- [ ] Add argument capture template section
  - Include 2-block pattern template with YOUR_DESCRIPTION_HERE substitution
  - Show validation and flag extraction examples
  - Reference command-development-fundamentals.md for rationale
- [ ] Add state initialization template section
  - Include workflow-state-machine.sh initialization pattern
  - Show append_workflow_state usage examples
  - Show STATE_ID_FILE persistence pattern
- [ ] Add agent delegation template section
  - Include Task invocation pattern
  - Show hard barrier pattern (pre-calc path + validation)
  - Reference hard-barrier-subagent-delegation.md pattern doc
- [ ] Add checkpoint reporting template section
  - Include standardized checkpoint format
  - Show context variable formatting
  - Show "Ready for" next phase messaging
- [ ] Add validation patterns section
  - Show validation-utils.sh function usage
  - Include defensive programming examples
  - Show error logging integration
- [ ] Update `.claude/docs/reference/README.md` to link to new quick reference

Testing:
```bash
# Verify documentation structure
bash .claude/scripts/validate-readmes.sh --check .claude/docs/reference/command-patterns-quick-reference.md

# Verify all code examples have correct syntax highlighting
grep -c '```bash' .claude/docs/reference/command-patterns-quick-reference.md

# Verify links to other docs work
bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/command-patterns-quick-reference.md
```

**Expected Duration**: 2 hours

### Phase 4: Standards Enforcement Validators [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Create automated validators for new standards

**Complexity**: Medium

Tasks:
- [ ] Create `.claude/scripts/lint-argument-capture.sh`
  - Search for YOUR_DESCRIPTION_HERE substitution pattern
  - Verify 2-block structure (capture block + validation block)
  - Check for temp file cleanup
  - Return ERROR-level violations for non-compliance
- [ ] Create `.claude/scripts/lint-checkpoint-format.sh`
  - Search for [CHECKPOINT] markers
  - Verify format matches standard: "[CHECKPOINT] {Phase} complete"
  - Check for "Ready for" messaging
  - Return WARNING-level violations for non-compliance
- [ ] Integrate new validators into `validate-all-standards.sh`
  - Add `--argument-capture` flag for lint-argument-capture.sh
  - Add `--checkpoints` flag for lint-checkpoint-format.sh
  - Update `--all` flag to include new validators
  - Update help text
- [ ] Add validators to pre-commit hook
  - Update `.git/hooks/pre-commit` template
  - Run argument capture validator on staged `.claude/commands/*.md` files
  - Run checkpoint validator on staged `.claude/commands/*.md` files
  - Block commits on ERROR-level violations
- [ ] Add unit tests for validators
  - Create `.claude/tests/validators/test_argument_capture_lint.sh`
  - Create `.claude/tests/validators/test_checkpoint_lint.sh`
  - Test against valid and invalid command examples

Testing:
```bash
# Run validators on all commands
bash .claude/scripts/lint-argument-capture.sh .claude/commands/*.md
bash .claude/scripts/lint-checkpoint-format.sh .claude/commands/*.md

# Verify integration with validate-all-standards.sh
bash .claude/scripts/validate-all-standards.sh --argument-capture
bash .claude/scripts/validate-all-standards.sh --checkpoints
bash .claude/scripts/validate-all-standards.sh --all

# Run validator unit tests
bash .claude/tests/validators/test_argument_capture_lint.sh
bash .claude/tests/validators/test_checkpoint_lint.sh
```

**Expected Duration**: 3 hours

### Phase 5: Command Refactoring and Template Updates [NOT STARTED]
dependencies: [1, 2, 3, 4]

**Objective**: Update command templates and refactor existing commands to use new standards

**Complexity**: Low

Tasks:
- [ ] Update command template files
  - Locate command template in `.claude/templates/` (or create if doesn't exist)
  - Apply 2-block argument capture pattern
  - Apply standardized checkpoint format
  - Add validation-utils.sh integration examples
  - Reference command-patterns-quick-reference.md in comments
- [ ] Refactor `/repair` command to use 2-block argument capture
  - File: `.claude/commands/repair.md`
  - Split inline parsing into separate validation block
  - Verify functionality unchanged (run integration tests)
- [ ] Refactor `/plan` command to use standardized checkpoints
  - File: `.claude/commands/plan.md`
  - Update checkpoint messages to match standard format
  - Add "Ready for" messaging between blocks
- [ ] Refactor `/research` command to use validation-utils.sh
  - File: `.claude/commands/research.md`
  - Replace inline validation with `validate_agent_artifact()` calls
  - Verify error logging integration works
- [ ] Update CLAUDE.md index to reference new standards sections
  - Add quick reference link to `<!-- SECTION: quick_reference -->`
  - Add command patterns link to `<!-- SECTION: project_commands -->`

Testing:
```bash
# Run validators on refactored commands
bash .claude/scripts/validate-all-standards.sh --all --staged

# Run integration tests for refactored commands
bash .claude/tests/integration/test_repair_delegation.sh
bash .claude/tests/integration/test_research_command.sh

# Verify templates pass validators
bash .claude/scripts/lint-argument-capture.sh .claude/templates/command-template.md
bash .claude/scripts/lint-checkpoint-format.sh .claude/templates/command-template.md

# Smoke test: Run each refactored command with simple input
# /repair --since 1h --summary
# /plan "test feature"
# /research "test research topic"
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Validation-utils.sh functions tested with valid/invalid inputs
- Validators tested against known-good and known-bad command examples
- Each test includes error logging integration verification

### Integration Testing
- Refactored commands tested with real workflow scenarios
- Cross-command workflows tested (e.g., /research → /plan → /build)
- Validation helper library tested in context of actual command execution

### Regression Testing
- All existing commands tested for functionality preservation
- State machine integration tested for backward compatibility
- Error logging tested for consistent format

### Standards Compliance Testing
- Pre-commit hook tested with staged files containing violations
- Validators tested against all 16 active commands
- Link validation tested for all new documentation

## Documentation Requirements

### Standards Documentation
- Update `command-development-fundamentals.md` with 4 new sections
- Update `output-formatting.md` with checkpoint format standard
- Create `command-patterns-quick-reference.md` as new reference doc

### Code Documentation
- Add docstrings to all validation-utils.sh functions
- Add inline comments to command templates referencing standards
- Update CLAUDE.md index with new standards section links

### Developer Onboarding
- Quick reference provides templates for common patterns
- Command development fundamentals provides rationale and context
- Validators provide automated feedback during development

## Dependencies

### Internal Dependencies
- Existing workflow-state-machine.sh library (Tier 1)
- Existing error-handling.sh library (Tier 1)
- Existing unified-location-detection.sh library (Tier 2)
- Existing validate-all-standards.sh script
- Existing pre-commit hook infrastructure

### External Dependencies
- None (all changes are internal to `.claude/` system)

## Risk Assessment

### Low Risk
- Documentation-only changes (Phase 1, 3)
- Adding new library without modifying existing code (Phase 2)

### Medium Risk
- Adding new validators may flag existing commands (Phase 4)
  - Mitigation: Make validators WARNING-level first, then ERROR-level after refactoring
- Refactoring commands may introduce regressions (Phase 5)
  - Mitigation: Comprehensive integration testing before/after refactoring

### Rollback Strategy
- Documentation changes: Git revert
- Library additions: Remove library, update sourcing in refactored commands
- Command refactoring: Git revert individual command files
- Validator additions: Remove from validate-all-standards.sh and pre-commit hook

## Notes

**Progressive Rollout**: This plan follows a progressive rollout strategy:
1. Document standards first (Phase 1) to establish patterns
2. Create supporting infrastructure (Phase 2, 4) to enable adoption
3. Provide developer resources (Phase 3) to reduce friction
4. Refactor incrementally (Phase 5) to validate standards in practice

**Future Work** (not in this plan):
- Mandate hard barrier pattern for all artifact-creating agents (requires plan.md refactoring)
- Create command development tutorial with new patterns
- Add performance benchmarks for block consolidation guidance

**Alignment with Research**: This plan implements all High Priority recommendations (#1-3) and selected Medium/Low Priority recommendations (#5-7) from the research report. It excludes recommendation #4 (mandate hard barrier pattern) as that requires more extensive command refactoring beyond uniformity enforcement scope.

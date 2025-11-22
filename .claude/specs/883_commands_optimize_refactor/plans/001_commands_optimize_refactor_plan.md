# Command Optimization and Standardization Implementation Plan

## Metadata
- **Date**: 2025-11-20 (Revised: 2025-11-21)
- **Feature**: Systematic optimization and standardization of .claude/commands/
- **Scope**: Refactor 12 commands to reduce duplication, consolidate bash blocks, standardize documentation, and enhance maintainability
- **Estimated Phases**: 5
- **Estimated Hours**: 18
- **Structure Level**: 0
- **Complexity Score**: 130.0 (reduced from 142.0 after removing redundant tasks)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Revision Notes**: Updated per research report 001_plan_revision_insights.md - removed redundant tasks already implemented by High Priority plans
- **Research Reports**:
  - [Command Optimization Analysis](../reports/001_command_optimization_analysis.md)
  - [Plan Revision Insights](../reports/001_plan_revision_insights.md)

## Overview

The .claude/commands/ system currently contains 12 well-functioning commands (10,649 LOC) with strong standardization in state management, error logging, and agent integration. Recent High Priority plan implementations have addressed foundational issues (three-tier sourcing pattern, enforcement mechanisms, error logging infrastructure).

Remaining optimization opportunities:
1. **Initialization duplication**: 30-40 line initialization pattern repeated across workflow commands (1,200+ lines of duplication)
2. **Bash block fragmentation**: /expand (32 blocks) and /collapse (29 blocks) have 4x-10x more fragmentation than other commands
3. **Documentation inconsistency**: Mix of "Block N" vs "Part N" naming conventions
4. **Missing command template**: No established template for new command development

**What's Already Complete** (via recent High Priority plans):
- Bash block budget guidelines documented in code-standards.md and output-formatting.md
- Consolidation triggers documented (>10 blocks = review)
- Target block counts by command type documented
- Three-tier sourcing pattern enforced via linter and pre-commit hooks
- Error logging infrastructure enhanced in source-libraries-inline.sh

## Research Summary

Key findings from research reports:

**From 001_command_optimization_analysis.md**:
- 100% metadata compliance across all commands
- 171 error handling occurrences (standardized)
- 379 state persistence operations (consistent patterns)
- Primary bottleneck: /expand (32 blocks) and /collapse (29 blocks) fragmentation
- Initialization overhead: 30-40 lines repeated in every bash block

**From 001_plan_revision_insights.md**:
- 3 of 4 High Priority plans now complete
- 40-50% of original Phase 1 tasks now redundant (bash block standards enforced)
- source-libraries-inline.sh enhanced with error logging (potential integration point)
- New enforcement mechanisms require validation steps in all phases

**Recommended Approach**:
- Evaluate command-initialization.sh as thin wrapper around source-libraries-inline.sh
- Focus on /expand and /collapse consolidation (highest value)
- Add mandatory validation steps to all phases

## Success Criteria

- [ ] Command initialization library evaluated (extend source-libraries-inline.sh vs new library)
- [ ] /expand bash blocks reduced from 32 to <=8 blocks
- [ ] /collapse bash blocks reduced from 29 to <=8 blocks
- [ ] All commands use consistent "Block N" documentation pattern
- [ ] Command template created referencing existing standards
- [ ] README.md enhanced with table of contents navigation
- [ ] All commands maintain 100% functionality after refactoring
- [ ] All linter validations pass (check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh)
- [ ] Pre-commit hooks pass for all modified files

## Technical Design

### Architecture Overview

The optimization follows a systematic refactoring approach:

```
Phase 1: Foundation and Library Evaluation
+-- Evaluate command-initialization.sh design (extend source-libraries-inline.sh?)
+-- Create library if justified (or document why not needed)
+-- Create command template referencing existing standards

Phase 2: Block Consolidation - /expand and /collapse
+-- Analyze block boundaries and consolidation opportunities
+-- Refactor /expand to <=8 blocks
+-- Refactor /collapse to <=8 blocks
+-- Validate all refactored commands pass linters

Phase 3: Documentation Standardization
+-- Standardize all commands to "Block N" pattern
+-- Add table of contents to README.md
+-- Verify cross-references accurate

Phase 4: Testing and Validation
+-- Run comprehensive integration tests
+-- Validate state persistence across new block boundaries
+-- Verify linter and pre-commit compliance

Phase 5: Documentation Updates
+-- Update .claude/docs/ with optimization case study
+-- Document any new patterns discovered
+-- Update cross-references
```

### Key Components

**1. Command Initialization Library (Evaluation Required)**

The proposed command-initialization.sh may overlap with existing source-libraries-inline.sh:
- source-libraries-inline.sh already provides three-tier sourcing pattern
- Enhanced with error logging by Plan 896

**Decision Point**: Create command-initialization.sh as thin wrapper OR document why initialization can remain inline.

Proposed approach (if library created):
```bash
# command-initialization.sh - thin wrapper
init_command_block() {
  local workflow_id_file="$1"
  local command_name="$2"

  # Defer to source-libraries-inline.sh for sourcing
  source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" 2>/dev/null || {
    echo "ERROR: Cannot load source-libraries-inline.sh" >&2
    exit 1
  }

  # Command-specific: workflow ID loading, error context setup
  if [ -f "$workflow_id_file" ]; then
    WORKFLOW_ID=$(cat "$workflow_id_file" 2>/dev/null)
    export WORKFLOW_ID
  fi

  # Setup error trap
  setup_bash_error_trap "$command_name" "$WORKFLOW_ID" "${USER_ARGS:-}"
}
```

**2. Bash Block Consolidation Strategy**

Target: /expand (32->8 blocks), /collapse (29->8 blocks)

Method:
- Combine adjacent blocks with no agent invocations between them
- Group validation operations into single validation block
- Keep agent invocations as natural block separators
- Preserve three-tier sourcing pattern in consolidated blocks

**3. Documentation Standardization**

Adopt "Block N" pattern across all commands:
- Migrate /debug from "Part N" to "Block N"
- Update /expand and /collapse after consolidation
- Add table of contents to 905-line README.md

**4. Command Template (Reduced Scope)**

Create workflow-command-template.md that references:
- Existing standards in code-standards.md
- Output formatting in output-formatting.md
- Enforcement mechanisms documentation
- Skills integration patterns (optional)

### Design Decisions

**Why evaluate rather than implement library immediately?**
- source-libraries-inline.sh already provides core functionality
- Plan 896 enhanced it with error logging
- Avoid creating duplicate infrastructure

**Why focus on /expand and /collapse?**
- Highest fragmentation (32 and 29 blocks vs 3-4 in comparable commands)
- Opportunity for 75% reduction in block count
- Direct alignment with output-formatting.md targets (2-3 blocks)

**Why reference existing standards in template?**
- bash block budget guidelines already documented
- Avoids duplicating content that can drift
- Template remains thin and focused

## Implementation Phases

### Phase 1: Foundation and Library Evaluation [NOT STARTED]
dependencies: []

**Objective**: Evaluate command-initialization.sh necessity, create library if justified, and establish command template referencing existing standards.

**Complexity**: Low

**Tasks**:
- [ ] Analyze source-libraries-inline.sh capabilities (file: .claude/lib/core/source-libraries-inline.sh)
- [ ] Document decision: create command-initialization.sh vs extend source-libraries-inline.sh vs keep initialization inline
- [ ] If library justified: Create /home/benjamin/.config/.claude/lib/workflow/command-initialization.sh
- [ ] If library justified: Implement as thin wrapper around source-libraries-inline.sh
- [ ] Create /home/benjamin/.config/.claude/commands/templates/workflow-command-template.md
- [ ] Template MUST reference code-standards.md#mandatory-bash-block-sourcing-pattern
- [ ] Template MUST reference output-formatting.md#block-consolidation-patterns
- [ ] Template MUST reference enforcement-mechanisms.md for validation requirements
- [ ] Add optional skills availability check to template (per skills-authoring.md)

**Testing**:
```bash
# Validate template syntax
markdown-lint .claude/commands/templates/workflow-command-template.md || echo "Lint check"

# If library created, test loading
if [ -f .claude/lib/workflow/command-initialization.sh ]; then
  source .claude/lib/workflow/command-initialization.sh
  type init_command_block && echo "Function available"
fi

# Run all validators on new/modified files
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --links
```

**Expected Duration**: 2 hours

### Phase 2: Bash Block Consolidation - /expand and /collapse [NOT STARTED]
dependencies: [1]

**Objective**: Consolidate /expand from 32 blocks to <=8 blocks and /collapse from 29 blocks to <=8 blocks through strategic block merging.

**Complexity**: High

**Tasks**:
- [ ] Analyze /home/benjamin/.config/.claude/commands/expand.md block structure and dependencies
- [ ] Identify adjacent blocks in /expand with no agent invocations between them
- [ ] Map validation operations in /expand for consolidation into single validation block
- [ ] Design consolidated block structure for /expand (target: 8 blocks max)
- [ ] Refactor /expand to consolidated structure
- [ ] Ensure all bash blocks follow three-tier sourcing pattern (per code-standards.md)
- [ ] Ensure fail-fast handlers on all critical library sourcing (per enforcement-mechanisms.md)
- [ ] Test /expand with automatic phase expansion scenario
- [ ] Test /expand with manual phase N expansion scenario
- [ ] Analyze /home/benjamin/.config/.claude/commands/collapse.md block structure and dependencies
- [ ] Identify adjacent blocks in /collapse with no agent invocations between them
- [ ] Map validation operations in /collapse for consolidation into single validation block
- [ ] Design consolidated block structure for /collapse (target: 8 blocks max)
- [ ] Refactor /collapse to consolidated structure
- [ ] Ensure all bash blocks follow three-tier sourcing pattern
- [ ] Ensure fail-fast handlers on all critical library sourcing
- [ ] Test /collapse with automatic phase collapse scenario
- [ ] Test /collapse with manual phase N collapse scenario
- [ ] Verify state persistence across new block boundaries in both commands

**Testing**:
```bash
# Run linters on refactored commands (MANDATORY)
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/collapse.md
bash .claude/tests/utilities/lint_error_suppression.sh
bash .claude/tests/utilities/lint_bash_conditionals.sh

# Test /expand scenarios
cd /home/benjamin/.config
/expand phase /path/to/plan.md 1  # Manual expansion

# Test /collapse scenarios
/collapse phase /path/to/expanded_plan.md 1  # Manual collapse

# Run progressive tests if available
cd /home/benjamin/.config/.claude/tests/progressive
./test_progressive_expansion.sh 2>/dev/null || echo "Test script not found"
./test_progressive_collapse.sh 2>/dev/null || echo "Test script not found"
./test_progressive_roundtrip.sh 2>/dev/null || echo "Test script not found"

# Verify block count reduction
grep -c "^```bash" .claude/commands/expand.md  # Should be <=8
grep -c "^```bash" .claude/commands/collapse.md  # Should be <=8
```

**Expected Duration**: 7 hours

### Phase 3: Documentation Standardization [NOT STARTED]
dependencies: [2]

**Objective**: Standardize all commands to "Block N" documentation pattern and enhance README navigation structure.

**Complexity**: Low

**Tasks**:
- [ ] Migrate /home/benjamin/.config/.claude/commands/debug.md from "Part N" to "Block N" pattern
- [ ] Verify /home/benjamin/.config/.claude/commands/expand.md uses consistent "Block N" pattern after consolidation
- [ ] Verify /home/benjamin/.config/.claude/commands/collapse.md uses consistent "Block N" pattern after consolidation
- [ ] Add table of contents to /home/benjamin/.config/.claude/commands/README.md
- [ ] TOC structure: Core Workflow, Primary Commands, Workflow Commands, Utility Commands, Common Flags, Architecture, Custom Commands
- [ ] Create hierarchical navigation structure in README with anchor links
- [ ] Document "Block" terminology convention in README
- [ ] Verify all cross-references in documentation are accurate after refactoring

**Testing**:
```bash
# Verify no "Part N" patterns remain in migrated files
grep -n "^## Part [0-9]" /home/benjamin/.config/.claude/commands/debug.md
# Should return no results after migration

# Verify "Block N" patterns in consolidated files
grep -n "^## Block [0-9]" /home/benjamin/.config/.claude/commands/expand.md
grep -n "^## Block [0-9]" /home/benjamin/.config/.claude/commands/collapse.md

# Validate links in README
bash .claude/scripts/validate-links-quick.sh .claude/commands/README.md

# Validate README structure
bash .claude/scripts/validate-readmes.sh --quick
```

**Expected Duration**: 3 hours

### Phase 4: Testing and Validation [NOT STARTED]
dependencies: [3]

**Objective**: Run comprehensive integration tests on all refactored commands to ensure functionality, state persistence, and linter compliance.

**Complexity**: Medium

**Tasks**:
- [ ] Run linter suite on all modified command files (MANDATORY - blocks completion if failing)
- [ ] Run integration tests for /expand and /collapse at /home/benjamin/.config/.claude/tests/progressive/
- [ ] Test state persistence across block boundaries in all refactored commands
- [ ] Verify error logging integration still functional
- [ ] Verify agent integration still functional with Task invocations
- [ ] Run system-wide validation script: bash .claude/scripts/validate-all-standards.sh --all
- [ ] Test pre-commit hooks pass for all modified files
- [ ] Document any test failures and create fix tasks

**Testing**:
```bash
# MANDATORY: Full linter validation
bash .claude/scripts/validate-all-standards.sh --all

# Pre-commit simulation on modified files
bash .claude/scripts/validate-all-standards.sh --staged

# Run progressive tests
cd /home/benjamin/.config/.claude/tests/progressive
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done

# Run integration tests if available
cd /home/benjamin/.config/.claude/tests/integration
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done

# Run unit tests for error logging
cd /home/benjamin/.config/.claude/tests/unit
./test_error_logging.sh 2>/dev/null || echo "Test not found"
```

**Expected Duration**: 4 hours

### Phase 5: Documentation Updates [NOT STARTED]
dependencies: [4]

**Objective**: Update .claude/docs/ with optimization patterns and cross-references.

**Complexity**: Low

**Tasks**:
- [ ] Document command-initialization.sh evaluation decision in /home/benjamin/.config/.claude/lib/workflow/README.md (if library created)
- [ ] Add optimization case study to /home/benjamin/.config/.claude/docs/concepts/patterns/ documenting /expand and /collapse consolidation
- [ ] Update /home/benjamin/.config/.claude/docs/guides/commands/ with any new refactoring patterns discovered
- [ ] Document command template usage in workflow library documentation
- [ ] Verify all new documentation passes link validation
- [ ] Update cross-references throughout .claude/docs/ if any paths changed

**Testing**:
```bash
# Validate all documentation links
bash .claude/scripts/validate-links-quick.sh

# Validate README structure
bash .claude/scripts/validate-readmes.sh

# Verify cross-references in updated files
grep -r "\[.*\](.*\.md)" .claude/docs/concepts/patterns/ | head -20
```

**Expected Duration**: 2 hours

## Testing Strategy

### Linter Validation (MANDATORY)

All phases MUST pass these validators before completion:

```bash
# Three-tier sourcing validation
bash .claude/scripts/lint/check-library-sourcing.sh

# Error suppression anti-patterns
bash .claude/tests/utilities/lint_error_suppression.sh

# Bash conditional safety
bash .claude/tests/utilities/lint_bash_conditionals.sh

# Unified validation (runs all)
bash .claude/scripts/validate-all-standards.sh --all
```

### Integration Testing

- Run existing test suite at .claude/tests/ after each phase
- Verify state persistence across refactored block boundaries
- Test error logging integration throughout command lifecycle
- Validate agent Task invocations still functional

### Progressive Operation Testing

- Test /expand automatic and manual phase expansion scenarios
- Test /collapse automatic and manual phase collapse scenarios
- Run roundtrip test (expand -> collapse -> verify original structure)

### Regression Testing

- Compare bash block count before/after consolidation (/expand: 32-><=8, /collapse: 29-><=8)
- Measure initialization overhead reduction if library implemented
- Verify 100% metadata compliance maintained
- Confirm error handling patterns preserved
- Validate state management patterns preserved

### Pre-Commit Compliance

Every modified file MUST pass pre-commit hooks before phase completion.

## Documentation Requirements

### New Documentation
- [ ] /home/benjamin/.config/.claude/commands/templates/workflow-command-template.md - Template for new command development (references existing standards)
- [ ] /home/benjamin/.config/.claude/docs/concepts/patterns/command-optimization.md - Case study of /expand and /collapse consolidation (optional)

### Updated Documentation
- [ ] /home/benjamin/.config/.claude/commands/README.md - Add table of contents and hierarchical navigation
- [ ] /home/benjamin/.config/.claude/lib/workflow/README.md - Document command-initialization.sh if created

### Documentation Standards
- Follow CommonMark specification
- Use Unicode box-drawing for diagrams (no emojis in file content)
- Include code examples with syntax highlighting
- Maintain bidirectional cross-references
- No historical commentary (present facts, not history)
- Reference existing standards rather than duplicating content

## Dependencies

### External Dependencies
- Existing test suite at /home/benjamin/.config/.claude/tests/
- Library functions: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- Linters: check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh
- Standards files: code-standards.md, output-formatting.md, enforcement-mechanisms.md

### Internal Dependencies
- Phase 2 depends on Phase 1 (evaluation informs consolidation approach)
- Phase 3 depends on Phase 2 (documentation reflects consolidated structure)
- Phase 4 depends on Phase 3 (test final documentation state)
- Phase 5 depends on Phase 4 (document validated patterns)

### Risk Mitigation
- **Risk**: Breaking existing functionality during refactoring
  - **Mitigation**: Run linter suite and integration tests after each phase, maintain git history for rollback
- **Risk**: State persistence issues across new block boundaries
  - **Mitigation**: Extensive testing of state loading/saving, verify STATE_FILE integrity
- **Risk**: Linter violations introduced during consolidation
  - **Mitigation**: Run linters incrementally during refactoring, fix violations before completing each task
- **Risk**: Pre-commit hooks failing on modified files
  - **Mitigation**: Validate with `--staged` flag before attempting commit

## Rollback Procedures

### Phase-Level Rollback
If any phase introduces regressions:
1. Identify failing tests and root cause
2. Use git to revert changes from that phase
3. Document failure reason in plan
4. Revise phase approach and re-attempt

### Command-Level Rollback
If individual command refactoring fails:
1. Revert that command file only (git checkout HEAD~1 -- .claude/commands/command.md)
2. Continue with other commands
3. Document command-specific issues
4. Create follow-up task for problematic command

## Success Metrics

### Quantitative Metrics
- [ ] /expand bash blocks reduced from 32 to <=8 (75% reduction target)
- [ ] /collapse bash blocks reduced from 29 to <=8 (72% reduction target)
- [ ] 100% linter compliance across all modified files
- [ ] 100% pre-commit hook pass rate
- [ ] All integration tests pass (0 failures)
- [ ] Documentation pattern consistency: 100% "Block N" adoption

### Qualitative Metrics
- [ ] Code maintainability improved through reduced duplication (if library implemented)
- [ ] Developer experience enhanced with command template
- [ ] Documentation navigability improved with table of contents
- [ ] Command execution performance maintained or improved

### Validation Criteria
- [ ] All commands execute successfully after refactoring
- [ ] State persistence verified across all refactored block boundaries
- [ ] Error logging integration confirmed
- [ ] Agent Task invocations functioning correctly
- [ ] All linters pass (check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh)
- [ ] Pre-commit hooks pass for all modified files

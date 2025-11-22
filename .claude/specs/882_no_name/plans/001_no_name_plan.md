# Unified Command Optimization and Standardization Plan

## Metadata
- **Date**: 2025-11-21
- **Feature**: Unified Command Optimization - Consolidation, Standardization, and Optional Helper Functions
- **Scope**: Consolidate /expand (32->8 blocks) and /collapse (29->8 blocks), standardize documentation to "Block N" pattern, evaluate command-initialization.sh, add optional error logging helpers
- **Estimated Phases**: 4
- **Estimated Hours**: 15-18
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 110.0 (reduced from 148 combined after removing redundant tasks)
- **Source Plans**:
  - Plan 883: `.claude/specs/883_commands_optimize_refactor/plans/001_commands_optimize_refactor_plan.md`
  - Plan 902: `.claude/specs/902_error_logging_infrastructure_completion/plans/001_error_logging_infrastructure_completion_plan.md`
- **Research Reports**:
  - [Unified Command Optimization Research](../reports/001_unified_command_optimization_plan_research.md)

## Overview

This unified plan combines high-value work from Plans 883 and 902 while removing 40-50% redundant tasks already completed by recent High Priority plans. The primary focus is bash block consolidation for /expand and /collapse commands, which have 4x-10x more fragmentation than comparable commands.

### Background

The .claude/commands/ system contains 12 commands (10,649 LOC) with strong standardization in state management and error logging. Recent High Priority plan implementations addressed foundational issues:
- Three-tier sourcing pattern: NOW ENFORCED via pre-commit hooks
- Bash block budget guidelines: NOW DOCUMENTED in code-standards.md and output-formatting.md
- Error logging infrastructure: COMPLETE across all orchestrator commands

### Remaining High-Value Work

| Priority | Work Item | Source Plan | Impact |
|----------|-----------|-------------|--------|
| Critical | /expand consolidation (32->8 blocks) | 883 | 75% block reduction |
| Critical | /collapse consolidation (29->8 blocks) | 883 | 72% block reduction |
| High | Documentation standardization ("Block N") | 883 | Consistency across 12 commands |
| Medium | command-initialization.sh evaluation | 883 | Informs future development |
| Low | Optional helper functions | 902 | Boilerplate reduction |

### What Is Explicitly NOT In Scope (Redundant)

- Bash block budget guidelines documentation (completed in code-standards.md)
- Consolidation trigger documentation (completed in output-formatting.md)
- convert-docs.md error logging (already has full integration with 6 call sites)
- Three-tier sourcing enforcement (handled by linter and pre-commit hooks)

## Research Summary

Key findings from unified research report:

**From Plan 883 Analysis**:
- /expand (32 blocks) and /collapse (29 blocks) have 4x-10x fragmentation vs comparable commands
- Target per output-formatting.md is 2-3 blocks for utility, 6-8 for workflow commands
- source-libraries-inline.sh already provides three-tier sourcing pattern
- Phase 1 documentation tasks are NOW REDUNDANT (40-50% of original scope)

**From Plan 902 Analysis**:
- Phase 2 (convert-docs.md) is COMPLETELY OBSOLETE - already has full integration
- Helper functions have LIMITED value (optional convenience, not critical infrastructure)
- Must use `validation_error` type (not `dependency_error` which is undefined)

**Recommended Approach**:
1. Focus on /expand and /collapse consolidation as highest ROI
2. Evaluate command-initialization.sh as thin wrapper vs extension
3. Defer low-priority helper functions to end of plan (can skip if time-constrained)
4. Add mandatory validation steps to all phases per enforcement-mechanisms.md

## Success Criteria

- [ ] /expand bash blocks reduced from 32 to <=8 (75% reduction target)
- [ ] /collapse bash blocks reduced from 29 to <=8 (72% reduction target)
- [ ] All commands use consistent "Block N" documentation pattern
- [ ] README.md has table of contents navigation
- [ ] command-initialization.sh evaluation decision documented
- [ ] All linter validations pass (check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh)
- [ ] Pre-commit hooks pass for all modified files
- [ ] All integration tests pass (0 failures)
- [ ] Optional: Helper functions added to error-handling.sh

## Technical Design

### Architecture Overview

```
Phase 1: Foundation and Library Evaluation (2 hours)
+-- Evaluate command-initialization.sh vs source-libraries-inline.sh
+-- Document decision (implement thin wrapper vs keep initialization inline)
+-- Create workflow-command-template.md (references existing standards)
+-- Add optional helper functions to error-handling.sh

Phase 2: Bash Block Consolidation (7 hours)
+-- /expand: Analyze 32 blocks, consolidate to <=8
+-- /collapse: Analyze 29 blocks, consolidate to <=8
+-- Validate three-tier sourcing pattern in consolidated blocks
+-- Run linters after each refactor

Phase 3: Documentation Standardization (3 hours)
+-- Migrate /debug from "Part N" to "Block N" pattern
+-- Update /expand and /collapse documentation
+-- Add table of contents to commands/README.md

Phase 4: Testing and Validation (3 hours)
+-- Full linter suite validation
+-- Integration tests for /expand and /collapse
+-- Pre-commit compliance verification
```

### Key Components

**1. Command Initialization Library Evaluation**

Evaluate whether to create command-initialization.sh as thin wrapper around source-libraries-inline.sh:

| Capability | source-libraries-inline.sh | Proposed command-initialization.sh |
|------------|---------------------------|-----------------------------------|
| Project directory detection | Yes (detect_claude_project_dir) | Wrapper |
| Three-tier sourcing | Yes (source_critical_libraries, etc) | Wrapper |
| Function validation | Yes (validates critical functions) | Wrapper |
| Workflow ID loading | No | Add |
| Error context setup | No | Add |
| setup_bash_error_trap call | No | Add |

**Decision Point**: If only 15-20 lines needed, create thin wrapper. Otherwise, document why initialization should remain inline.

**2. Bash Block Consolidation Strategy**

Method for /expand and /collapse:
- Identify adjacent blocks with no agent invocations between them (merge candidates)
- Group validation operations into single validation block
- Keep agent invocations as natural block separators
- Preserve three-tier sourcing pattern in EVERY consolidated block (MANDATORY)
- Preserve fail-fast handlers on Tier 1 library sourcing (MANDATORY)

**Target Structure**:
```
Block 1: Setup and Validation (sourcing, argument validation, mode detection)
Block 2: State Loading (load workflow state, restore context)
Block 3-6: Main Logic (phase-specific operations with agent invocations)
Block 7: State Persistence (save workflow state)
Block 8: Cleanup and Summary (final output, completion)
```

**3. Documentation Standardization**

Adopt "Block N" pattern universally:
- /debug currently uses "Part N" -> migrate to "Block N"
- /expand and /collapse will use "Block N" after consolidation
- All commands will have consistent naming convention

**4. Optional Helper Functions**

Add to error-handling.sh (LOW PRIORITY - can defer):
- `validate_required_functions()`: Defensive function existence check
- `execute_with_logging()`: Wrapper for command execution with automatic error logging

Note: Must use `validation_error` type (not `dependency_error` which is undefined).

### Design Decisions

**Why unified plan instead of separate implementations?**
- 40-50% overlap identified in redundant tasks
- Shared testing and validation phases
- Consistent enforcement mechanism usage
- Reduced total implementation time (15-18h vs 20.5h combined)

**Why focus on /expand and /collapse first?**
- Highest fragmentation (32 and 29 blocks vs 3-4 in comparable commands)
- 75% and 72% reduction targets are high-impact
- Direct alignment with output-formatting.md targets

**Why optional helper functions at end?**
- Lower priority than consolidation work
- Can be skipped if time-constrained without affecting core value
- No current adoption means no urgency

## Implementation Phases

### Phase 1: Foundation and Library Evaluation [NOT STARTED]
dependencies: []

**Objective**: Evaluate command-initialization.sh necessity, create library if justified, establish command template, and optionally add helper functions.

**Complexity**: Medium

**Tasks**:
- [ ] Read `/home/benjamin/.config/.claude/lib/core/source-libraries-inline.sh` to understand current capabilities
- [ ] Document evaluation: create command-initialization.sh vs extend source-libraries-inline.sh vs keep initialization inline
- [ ] Decision criteria:
  - If wrapper needed (>10 commands would benefit), create `.claude/lib/workflow/command-initialization.sh`
  - If marginal benefit (<5 lines saved per command), document why not needed
- [ ] If library created: Implement as thin wrapper (~20 lines) with:
  - Workflow ID loading from temp file
  - Error context restoration (COMMAND_NAME, USER_ARGS)
  - setup_bash_error_trap() invocation
- [ ] Create `/home/benjamin/.config/.claude/commands/templates/workflow-command-template.md`:
  - Reference code-standards.md#mandatory-bash-block-sourcing-pattern
  - Reference output-formatting.md#block-consolidation-patterns
  - Reference enforcement-mechanisms.md for validation requirements
  - Add optional skills availability check (per skills-authoring.md)
- [ ] Add `validate_required_functions()` to error-handling.sh (OPTIONAL):
  ```bash
  validate_required_functions() {
    local required_functions="$1"
    local missing_functions=""
    for func in $required_functions; do
      if ! type "$func" &>/dev/null; then
        missing_functions="$missing_functions $func"
      fi
    done
    if [ -n "$missing_functions" ]; then
      log_command_error "validation_error" "Missing required functions:$missing_functions" ...
      return 1
    fi
    return 0
  }
  ```
- [ ] Add `execute_with_logging()` to error-handling.sh (OPTIONAL):
  ```bash
  execute_with_logging() {
    local operation="$1"
    shift
    local output exit_code
    output=$("$@" 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      log_command_error "execution_error" "$operation failed" ...
    fi
    echo "$output"
    return $exit_code
  }
  ```
- [ ] Add both functions to exports section if implemented
- [ ] Run validators on any new/modified files

**Testing**:
```bash
# Validate template syntax
if [ -f .claude/commands/templates/workflow-command-template.md ]; then
  markdown-lint .claude/commands/templates/workflow-command-template.md 2>/dev/null || echo "No linter"
fi

# If library created, test loading
if [ -f .claude/lib/workflow/command-initialization.sh ]; then
  source .claude/lib/workflow/command-initialization.sh
  type init_command_block && echo "Function available"
fi

# Test helper functions if added
if grep -q "validate_required_functions" .claude/lib/core/error-handling.sh 2>/dev/null; then
  source .claude/lib/core/error-handling.sh
  validate_required_functions "log_command_error ensure_error_log_exists"
  echo "validate_required_functions exit: $?"
fi

# Mandatory validation
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --links
```

**Expected Duration**: 2 hours

### Phase 2: Bash Block Consolidation [NOT STARTED]
dependencies: [1]

**Objective**: Consolidate /expand from 32 blocks to <=8 blocks and /collapse from 29 blocks to <=8 blocks through strategic block merging while preserving all functionality.

**Complexity**: High

**Tasks**:

**2.1 /expand Analysis and Refactoring**:
- [ ] Read `/home/benjamin/.config/.claude/commands/expand.md` (32 blocks, 1191 lines)
- [ ] Map all bash blocks with their purpose and dependencies
- [ ] Identify merge candidates (adjacent blocks with no agent invocations between)
- [ ] Identify validation operations that can combine into single validation block
- [ ] Design target 8-block structure:
  - Block 1: Setup, sourcing, argument validation
  - Block 2: State loading and context restoration
  - Block 3-6: Main expansion logic (preserve agent Task boundaries)
  - Block 7: State persistence
  - Block 8: Cleanup and summary output
- [ ] Refactor /expand to consolidated structure
- [ ] Ensure ALL bash blocks follow three-tier sourcing pattern (MANDATORY per code-standards.md)
- [ ] Ensure fail-fast handlers on ALL Tier 1 library sourcing (MANDATORY per enforcement-mechanisms.md)
- [ ] Run linters after refactoring:
  ```bash
  bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md
  bash .claude/tests/utilities/lint_error_suppression.sh
  bash .claude/tests/utilities/lint_bash_conditionals.sh
  ```
- [ ] Test /expand with automatic phase expansion scenario
- [ ] Test /expand with manual `phase N` expansion scenario

**2.2 /collapse Analysis and Refactoring**:
- [ ] Read `/home/benjamin/.config/.claude/commands/collapse.md` (29 blocks, 793 lines)
- [ ] Map all bash blocks with their purpose and dependencies
- [ ] Identify merge candidates (adjacent blocks with no agent invocations between)
- [ ] Identify validation operations that can combine into single validation block
- [ ] Design target 8-block structure (same pattern as /expand)
- [ ] Refactor /collapse to consolidated structure
- [ ] Ensure ALL bash blocks follow three-tier sourcing pattern (MANDATORY)
- [ ] Ensure fail-fast handlers on ALL Tier 1 library sourcing (MANDATORY)
- [ ] Run linters after refactoring:
  ```bash
  bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/collapse.md
  bash .claude/tests/utilities/lint_error_suppression.sh
  bash .claude/tests/utilities/lint_bash_conditionals.sh
  ```
- [ ] Test /collapse with automatic phase collapse scenario
- [ ] Test /collapse with manual `phase N` collapse scenario

**2.3 Cross-Validation**:
- [ ] Verify state persistence works across new block boundaries in /expand
- [ ] Verify state persistence works across new block boundaries in /collapse
- [ ] Run roundtrip test: expand -> collapse -> verify structure preserved

**Testing**:
```bash
# MANDATORY: Linter validation for /expand
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md
bash .claude/tests/utilities/lint_error_suppression.sh
bash .claude/tests/utilities/lint_bash_conditionals.sh

# MANDATORY: Linter validation for /collapse
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/collapse.md

# Verify block count reduction
EXPAND_BLOCKS=$(grep -c "^\`\`\`bash" .claude/commands/expand.md || echo 0)
COLLAPSE_BLOCKS=$(grep -c "^\`\`\`bash" .claude/commands/collapse.md || echo 0)
echo "/expand blocks: $EXPAND_BLOCKS (target: <=8)"
echo "/collapse blocks: $COLLAPSE_BLOCKS (target: <=8)"

# Test scenarios (if available)
if [ -d .claude/tests/progressive ]; then
  cd .claude/tests/progressive
  ./test_progressive_expansion.sh 2>/dev/null || echo "Test not found"
  ./test_progressive_collapse.sh 2>/dev/null || echo "Test not found"
  ./test_progressive_roundtrip.sh 2>/dev/null || echo "Test not found"
fi

# Full validation suite
bash .claude/scripts/validate-all-standards.sh --all
```

**Expected Duration**: 7 hours

### Phase 3: Documentation Standardization [NOT STARTED]
dependencies: [2]

**Objective**: Standardize all commands to "Block N" documentation pattern and enhance README navigation.

**Complexity**: Low

**Tasks**:
- [ ] Read `/home/benjamin/.config/.claude/commands/debug.md` to identify "Part N" sections
- [ ] Migrate /debug from "Part N" to "Block N" pattern:
  - Find all `## Part N:` headings
  - Replace with `## Block N:` headings
  - Update any internal references
- [ ] Verify `/home/benjamin/.config/.claude/commands/expand.md` uses "Block N" after Phase 2 consolidation
- [ ] Verify `/home/benjamin/.config/.claude/commands/collapse.md` uses "Block N" after Phase 2 consolidation
- [ ] Read `/home/benjamin/.config/.claude/commands/README.md` (905 lines)
- [ ] Add table of contents to README.md with structure:
  - Core Workflow (research -> plan -> build cycle)
  - Primary Commands (/plan, /build, /research)
  - Workflow Commands (/expand, /collapse, /revise)
  - Utility Commands (/debug, /errors, /repair)
  - Common Flags and Options
  - Architecture Overview
  - Custom Command Development
- [ ] Create hierarchical navigation with anchor links
- [ ] Document "Block" terminology convention in README
- [ ] Verify all cross-references accurate after Phase 2 changes

**Testing**:
```bash
# Verify no "Part N" patterns remain in /debug
PART_COUNT=$(grep -c "^## Part [0-9]" .claude/commands/debug.md || echo 0)
echo "/debug 'Part N' patterns: $PART_COUNT (target: 0)"

# Verify "Block N" patterns in consolidated files
EXPAND_BLOCK_PATTERN=$(grep -c "^## Block [0-9]" .claude/commands/expand.md || echo 0)
COLLAPSE_BLOCK_PATTERN=$(grep -c "^## Block [0-9]" .claude/commands/collapse.md || echo 0)
echo "/expand 'Block N' patterns: $EXPAND_BLOCK_PATTERN"
echo "/collapse 'Block N' patterns: $COLLAPSE_BLOCK_PATTERN"

# Validate links in README
bash .claude/scripts/validate-links-quick.sh .claude/commands/README.md

# Validate README structure
bash .claude/scripts/validate-readmes.sh --quick
```

**Expected Duration**: 3 hours

### Phase 4: Testing and Validation [NOT STARTED]
dependencies: [3]

**Objective**: Run comprehensive integration tests, validate state persistence, and ensure full compliance with enforcement mechanisms.

**Complexity**: Medium

**Tasks**:
- [ ] Run MANDATORY linter suite on ALL modified files:
  ```bash
  bash .claude/scripts/validate-all-standards.sh --all
  ```
- [ ] Run integration tests for /expand at `.claude/tests/progressive/` (if available)
- [ ] Run integration tests for /collapse at `.claude/tests/progressive/` (if available)
- [ ] Test state persistence across block boundaries:
  - Verify STATE_FILE integrity after /expand operations
  - Verify STATE_FILE integrity after /collapse operations
  - Test multi-block workflows maintain state correctly
- [ ] Verify error logging integration still functional:
  - Check setup_bash_error_trap is called
  - Verify log_command_error generates valid JSONL entries
- [ ] Verify agent integration still functional:
  - Test Task invocations in /expand
  - Test Task invocations in /collapse
- [ ] Run pre-commit validation on all modified files:
  ```bash
  bash .claude/scripts/validate-all-standards.sh --staged
  ```
- [ ] Document any test failures and create follow-up tasks if needed
- [ ] Update documentation if any patterns changed during implementation
- [ ] Final verification: all success criteria checkboxes marked

**Testing**:
```bash
# MANDATORY: Full linter validation (blocks completion if failing)
bash .claude/scripts/validate-all-standards.sh --all
LINTER_EXIT=$?
if [ $LINTER_EXIT -ne 0 ]; then
  echo "CRITICAL: Linter validation failed. Phase cannot complete."
  exit 1
fi

# Pre-commit simulation
bash .claude/scripts/validate-all-standards.sh --staged

# Run progressive tests if available
if [ -d .claude/tests/progressive ]; then
  cd /home/benjamin/.config/.claude/tests/progressive
  for test in test_*.sh; do
    echo "Running $test..."
    ./"$test" || echo "FAILED: $test"
  done
fi

# Run integration tests if available
if [ -d .claude/tests/integration ]; then
  cd /home/benjamin/.config/.claude/tests/integration
  for test in test_*.sh; do
    echo "Running $test..."
    ./"$test" || echo "FAILED: $test"
  done
fi

# Final block count verification
echo "=== Final Block Counts ==="
echo "/expand: $(grep -c '^\`\`\`bash' .claude/commands/expand.md || echo 0) blocks (target: <=8)"
echo "/collapse: $(grep -c '^\`\`\`bash' .claude/commands/collapse.md || echo 0) blocks (target: <=8)"

# Final documentation pattern verification
echo "=== Documentation Patterns ==="
echo "/debug 'Part N': $(grep -c '^## Part [0-9]' .claude/commands/debug.md || echo 0) (target: 0)"
echo "/debug 'Block N': $(grep -c '^## Block [0-9]' .claude/commands/debug.md || echo 0)"
```

**Expected Duration**: 3 hours

## Testing Strategy

### Mandatory Linter Validation

All phases MUST pass these validators before completion (per enforcement-mechanisms.md):

```bash
# ERROR severity - blocks completion
bash .claude/scripts/lint/check-library-sourcing.sh [files]
bash .claude/tests/utilities/lint_error_suppression.sh
bash .claude/tests/utilities/lint_bash_conditionals.sh

# WARNING severity - informational
bash .claude/scripts/validate-links-quick.sh
bash .claude/scripts/validate-readmes.sh --quick

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

- Compare bash block count before/after: /expand 32-><=8, /collapse 29-><=8
- Verify 100% metadata compliance maintained
- Confirm error handling patterns preserved
- Validate state management patterns preserved

## Documentation Requirements

### New Documentation
- [ ] `/home/benjamin/.config/.claude/commands/templates/workflow-command-template.md` - Template referencing existing standards

### Updated Documentation
- [ ] `/home/benjamin/.config/.claude/commands/README.md` - Add table of contents and navigation
- [ ] `/home/benjamin/.config/.claude/commands/debug.md` - Migrate "Part N" to "Block N"
- [ ] `/home/benjamin/.config/.claude/commands/expand.md` - Consolidation + "Block N"
- [ ] `/home/benjamin/.config/.claude/commands/collapse.md` - Consolidation + "Block N"
- [ ] `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Optional helper functions
- [ ] `/home/benjamin/.config/.claude/lib/workflow/README.md` - Document command-initialization.sh evaluation

### Documentation Standards
- Follow CommonMark specification
- Use Unicode box-drawing for diagrams (no emojis in file content)
- Include code examples with syntax highlighting
- Reference existing standards rather than duplicating content
- No historical commentary (present facts, not history)

## Dependencies

### External Dependencies
- Existing test suite at `/home/benjamin/.config/.claude/tests/`
- Library functions: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- Linters: check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh
- Standards: code-standards.md, output-formatting.md, enforcement-mechanisms.md

### Internal Phase Dependencies
- Phase 2 depends on Phase 1 (evaluation informs consolidation approach)
- Phase 3 depends on Phase 2 (documentation reflects consolidated structure)
- Phase 4 depends on Phase 3 (test final documentation state)

### Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing /expand functionality | Medium | High | Run linters after each refactor, maintain git history for rollback |
| State persistence issues in consolidated blocks | Medium | High | Extensive testing, verify STATE_FILE integrity after each change |
| Linter violations in consolidated code | Low | Medium | Run linters incrementally, fix violations before completing tasks |
| Pre-commit hook failures | Low | Medium | Validate with --staged before attempting commit |

## Rollback Procedures

### Phase-Level Rollback
If any phase introduces regressions:
1. Identify failing tests and root cause
2. Use git to revert changes from that phase
3. Document failure reason in plan
4. Revise phase approach and re-attempt

### Command-Level Rollback
If individual command refactoring fails:
1. Revert that command file only: `git checkout HEAD~1 -- .claude/commands/command.md`
2. Continue with other commands
3. Document command-specific issues
4. Create follow-up task for problematic command

## Success Metrics

### Quantitative Metrics
- [ ] /expand bash blocks: 32 -> <=8 (75% reduction target)
- [ ] /collapse bash blocks: 29 -> <=8 (72% reduction target)
- [ ] 100% linter compliance across all modified files
- [ ] 100% pre-commit hook pass rate
- [ ] 0 integration test failures
- [ ] 100% "Block N" documentation pattern adoption

### Qualitative Metrics
- [ ] Code maintainability improved through reduced fragmentation
- [ ] Documentation navigability enhanced with table of contents
- [ ] Developer experience improved with command template
- [ ] Consistency achieved across all 12 commands

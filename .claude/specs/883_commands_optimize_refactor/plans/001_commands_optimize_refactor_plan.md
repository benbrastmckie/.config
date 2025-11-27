# Command Optimization and Standardization Implementation Plan

## Metadata
- **Date**: 2025-11-26 (Revised)
- **Feature**: Systematic optimization and standardization of .claude/commands/
- **Scope**: Optimize all 12 commands for uniformity, efficiency, and robustness
- **Estimated Phases**: 5
- **Estimated Hours**: 14
- **Structure Level**: 0
- **Complexity Score**: 100.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Revision Notes**: v5.0 - Added .claude/docs/ Optimization Standards section with directives for maintaining efficiency and elegance. Replaced magic threshold numbers with principle-based optimization.
- **Research Reports**:
  - [Comprehensive Command Analysis](../reports/001-comprehensive-command-analysis.md) (2025-11-26)
  - [Command Optimization Analysis](../reports/001_command_optimization_analysis.md)
  - [Plan Revision Insights](../reports/001_plan_revision_insights.md)

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-20 | 1.0 | Initial plan with 5 phases |
| 2025-11-21 | 2.0 | Removed redundant tasks from High Priority plans |
| 2025-11-26 | 3.0 | Updated bash block counts, added workflow-bootstrap.sh, expanded scope |
| 2025-11-26 | 4.0 | Replaced magic thresholds with principle-based optimization |
| 2025-11-26 | 5.0 | **Added .claude/docs/ Optimization Standards** - New section defining directives for maintaining efficiency and elegance in future enhancements |

## Overview

The .claude/commands/ system contains 12 commands totaling **17,147 lines** of implementation and documentation. Research analysis (2025-11-26) identified specific optimization opportunities.

**Current State (Verified via grep analysis)**:

| Command | Bash Blocks | Complexity | Documentation | LOC |
|---------|-------------|------------|---------------|-----|
| build.md | 9 | High (iteration loops, checkpoints) | Block N | 1936 |
| plan.md | 6 | Medium (research + planning) | Block N | 1147 |
| research.md | 4 | Low-Medium | Block N | 668 |
| debug.md | 7 | Medium (multi-phase analysis) | **Part N** | 1410 |
| repair.md | 3 | Low-Medium | Block N | 1017 |
| errors.md | 3 | Low (query + report) | Block N | 668 |
| expand.md | 11 | Medium (but fragmented) | **STEP N** | 1196 |
| collapse.md | 8 | Medium | **STEP N** | 798 |
| revise.md | 6 | Medium (research + revision) | **Part N** | 1049 |
| convert-docs.md | 6 | Low-Medium | **STEP N** | 411 |
| setup.md | 3 | Low | Block N | 580 |
| optimize-claude.md | 7 | Medium (multi-agent) | Block N | 647 |

**Key Findings**:

1. **Error Logging Coverage: 100%** - All commands properly integrate error-handling.sh (no gaps)
2. **Unnecessary Fragmentation**: expand.md has 11 blocks for medium complexity work - consecutive blocks can be combined
3. **Documentation Terminology Inconsistent**: 5 commands use "Part N" or "STEP N" instead of "Block N"
4. **Initialization Boilerplate: 98% Duplication** - 23-line pattern repeated in all 12 commands

## Bash Block Optimization Principles

Rather than arbitrary thresholds, apply these principles when evaluating block structure:

### Consolidation Principles

1. **Combine consecutive bash blocks** when there's no agent invocation or user interaction between them
2. **Group related operations** - setup, validation, and initialization belong together
3. **Keep agent Task invocations as natural block boundaries** - they represent async operations
4. **State persistence boundaries** - blocks that save state for later blocks should remain separate
5. **Error handling scope** - keep error-prone operations in their own blocks for clearer diagnostics

### Anti-Patterns to Fix

1. **Over-fragmentation**: Multiple small blocks for sequential operations (expand.md: 11 blocks)
2. **Artificial separation**: Splitting setup across multiple blocks (build.md: Blocks 1a, 1b, 1c)
3. **Validation sprawl**: Separate blocks for each validation check instead of one validation block

### When to Keep Blocks Separate

1. **Agent invocations** - Task tool calls are async and need clean boundaries
2. **State checkpoints** - When state must be persisted for resume/recovery
3. **Different failure modes** - When errors need distinct handling or messaging
4. **Complex commands** - Commands like /build legitimately need more blocks for iteration, checkpoints, and multi-phase orchestration

## .claude/docs/ Optimization Standards

This section defines directives for maintaining efficiency and elegance in future enhancements to the .claude/ infrastructure. These principles should be incorporated into the existing standards documentation.

### Core Optimization Philosophy

**Principle: Elegance over Volume**

Optimization is about clarity and efficiency, not arbitrary metrics. The goal is code and documentation that is:
- **Coherent**: Each component has a single, clear purpose
- **Economical**: No unnecessary duplication, indirection, or abstraction
- **Robust**: Error handling that aids debugging without adding noise
- **Maintainable**: Easy to understand, modify, and extend

### Optimization Decision Framework

When evaluating whether to optimize, ask:

1. **Is there measurable benefit?** - Optimization without measurable improvement is premature
2. **Does it reduce cognitive load?** - Simpler is better; abstraction should clarify, not obscure
3. **Does it preserve debuggability?** - Consolidation should not hide failure points
4. **Is it worth the risk?** - Working code has value; don't break what works for marginal gains

### Directives for Future Enhancements

#### Directive 1: Principle-Based Thresholds

**Standard**: Avoid magic numbers; use principles that adapt to context.

**Bad**: "All commands must have <=8 bash blocks"
**Good**: "Consolidate consecutive blocks when no agent invocation or state checkpoint between them"

**Rationale**: Different commands have different complexity. A simple query command legitimately needs fewer blocks than a multi-phase orchestrator.

**Application**:
- Block counts should reflect command complexity, not arbitrary targets
- Line counts should reflect functionality, not artificial limits
- Test counts should reflect coverage needs, not quota requirements

#### Directive 2: Clean-Break Optimization

**Standard**: When refactoring, delete old patterns completely rather than adding compatibility layers.

**Pattern**:
1. Identify optimization opportunity
2. Implement improved version
3. Update all callers atomically
4. Delete old implementation in same commit
5. No deprecation warnings or wrapper functions

**Reference**: See [Clean-Break Development Standard](.claude/docs/reference/standards/clean-break-development.md)

#### Directive 3: Utility Extraction Threshold

**Standard**: Extract to shared utility when pattern appears 3+ times with identical logic.

**Decision Criteria**:
| Factor | Extract | Keep Inline |
|--------|---------|-------------|
| Identical pattern 3+ times | Yes | - |
| Pattern with variations | Consider | If variations > similarities |
| Command-specific logic | No | Yes |
| Error handling patterns | Yes (for consistency) | - |
| Initialization boilerplate | Yes | - |

**Anti-Pattern**: Creating abstractions for hypothetical future reuse. Only extract when reuse is demonstrated.

#### Directive 4: Documentation Density Standards

**Standard**: Documentation should be comprehensive but not redundant.

**Guidelines**:
- **CLAUDE.md**: Index and quick reference only; link to detailed docs
- **Code comments**: WHAT not WHY; design rationale belongs in guides
- **README.md**: Purpose, usage, navigation; not implementation details
- **Guides**: Detailed how-to with examples; for learning, not reference
- **Reference docs**: Specifications and standards; for compliance, not learning

**Reference**: See [Writing Standards](.claude/docs/concepts/writing-standards.md)

#### Directive 5: Error Handling Optimization

**Standard**: Error handling should aid debugging without adding noise.

**Patterns**:
```bash
# GOOD: Fail-fast with clear error
source "$LIB" 2>/dev/null || { echo "ERROR: Failed to source $LIB" >&2; exit 1; }

# BAD: Silent failure
source "$LIB" 2>/dev/null || true

# GOOD: Structured error with context
log_command_error "$CMD" "$WORKFLOW_ID" "$ARGS" "type" "message" "location" "$details"

# BAD: Generic error without context
echo "ERROR: Something went wrong" >&2; exit 1
```

**Reference**: See [Error Handling Pattern](.claude/docs/concepts/patterns/error-handling.md)

#### Directive 6: Output Suppression Standards

**Standard**: Suppress success noise; preserve error visibility.

**What to Suppress**:
- Library sourcing output (verbose function definitions)
- Progress indicators ("Loading...", "Processing...")
- Intermediate state updates ("Setting X to Y")
- Success confirmations for individual operations

**What to Preserve**:
- Error messages (always visible, always to stderr)
- Final summary (single line per block)
- User-needed data (paths, identifiers)

**Reference**: See [Output Formatting Standards](.claude/docs/reference/standards/output-formatting.md)

#### Directive 7: Testing Optimization

**Standard**: Tests should provide coverage without redundancy.

**Guidelines**:
- One test file per command/library (not per-phase tests)
- Test behavior, not implementation details
- Consolidate validation logic into reusable test utilities
- Integration tests for workflow boundaries; unit tests for functions

**Anti-Patterns**:
- Separate test blocks in command files (consolidate to test suite)
- Testing implementation details that may change
- Duplicate validation logic across multiple tests

### Standards Documentation Updates

This plan includes updating the following .claude/docs/ files to incorporate these optimization directives:

| Document | Update |
|----------|--------|
| code-standards.md | Add "Optimization Principles" section |
| output-formatting.md | Clarify principle-based block consolidation |
| refactoring-methodology.md | Add optimization decision framework |
| writing-standards.md | Add documentation density guidelines |

### Optimization Standards Checklist

For any future enhancement, verify:

- [ ] **Measurable benefit**: Can you quantify the improvement?
- [ ] **Principle-based**: Are decisions based on principles, not magic numbers?
- [ ] **Clean-break**: Is old code deleted, not wrapped?
- [ ] **Utility threshold**: Is extraction justified by 3+ occurrences?
- [ ] **Documentation density**: Is documentation comprehensive but not redundant?
- [ ] **Error handling**: Do errors aid debugging with context?
- [ ] **Output discipline**: Is success noise suppressed, errors preserved?
- [ ] **Testing efficiency**: Are tests consolidated and behavior-focused?

## Success Criteria

- [ ] workflow-bootstrap.sh library created with bootstrap_workflow_env() and load_tier1_libraries()
- [ ] expand.md consecutive blocks consolidated (apply principles, not arbitrary target)
- [ ] All 12 commands use consistent "Block N" documentation pattern
- [ ] Optimization directives documented in .claude/docs/ standards files
- [ ] All commands updated to use workflow-bootstrap.sh (optional - non-breaking change)
- [ ] README.md enhanced with table of contents navigation
- [ ] All commands maintain 100% functionality after refactoring
- [ ] All linter validations pass
- [ ] Pre-commit hooks pass for all modified files

## Technical Design

### Architecture Overview

```
Phase 1: Library Consolidation (Foundation)
+-- Create workflow-bootstrap.sh library
+-- Implement bootstrap_workflow_env() function
+-- Implement load_tier1_libraries() function
+-- Test library loading in isolation

Phase 2: Principle-Based Block Consolidation
+-- Apply consolidation principles to expand.md
+-- Apply consolidation principles to other commands where beneficial
+-- Preserve natural boundaries (agent calls, state persistence)

Phase 3: Documentation Standardization
+-- Rename "Part N" to "Block N" in debug.md, revise.md
+-- Rename "STEP N" to "Block N" in expand.md, collapse.md, convert-docs.md
+-- Add table of contents to README.md

Phase 4: Testing and Validation
+-- Run comprehensive test suite
+-- Verify linter compliance
+-- Test pre-commit hooks

Phase 5: Library Adoption (Optional)
+-- Update commands to use workflow-bootstrap.sh (incremental)
+-- Document new patterns
```

### Key Components

**1. workflow-bootstrap.sh Library (NEW)**

Purpose: Eliminate 276+ lines of duplicated initialization code across 12 commands.

```bash
#!/usr/bin/env bash
# workflow-bootstrap.sh - Common initialization for all workflow commands
# Provides: bootstrap_workflow_env(), load_tier1_libraries()

# bootstrap_workflow_env: Detect project directory and export CLAUDE_PROJECT_DIR
bootstrap_workflow_env() {
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    local current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
  fi

  if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
    echo "ERROR: Failed to detect project directory" >&2
    return 1
  fi

  export CLAUDE_PROJECT_DIR
  return 0
}

# load_tier1_libraries: Source critical foundation libraries with fail-fast
load_tier1_libraries() {
  local libs=("core/state-persistence.sh" "workflow/workflow-state-machine.sh" "core/error-handling.sh")
  for lib in "${libs[@]}"; do
    source "${CLAUDE_PROJECT_DIR}/.claude/lib/$lib" 2>/dev/null || {
      echo "ERROR: Failed to source $lib" >&2
      return 1
    }
  done
  return 0
}

export -f bootstrap_workflow_env
export -f load_tier1_libraries
```

**2. Principle-Based Consolidation Analysis**

| Command | Current | Issue | Recommendation |
|---------|---------|-------|----------------|
| expand.md | 11 blocks | Over-fragmented - STEP 1+2, 4+5, 6+7 are consecutive | Combine consecutive blocks |
| build.md | 9 blocks | Blocks 1a/1b/1c are setup variants | Keep - complex iteration logic justifies structure |
| collapse.md | 8 blocks | Step-based validation sprawl | Review for consecutive block merging |
| debug.md | 7 blocks | Reasonable for multi-phase analysis | Keep - appropriate for complexity |
| optimize-claude.md | 7 blocks | Multi-agent orchestration | Keep - appropriate for complexity |

**3. Documentation Terminology Mapping**

| Command | Current | Target |
|---------|---------|--------|
| debug.md | "Part 1-6" | "Block 1-6" |
| revise.md | "Part 1-5" | "Block 1-5" |
| expand.md | "STEP 1-7" | "Block 1-N" (after consolidation) |
| collapse.md | "STEP 1-8" | "Block 1-N" (after consolidation) |
| convert-docs.md | "STEP 1-6" | "Block 1-6" |

## Implementation Phases

### Phase 1: Library Consolidation [COMPLETE]
dependencies: []

**Objective**: Create workflow-bootstrap.sh library to eliminate initialization duplication.

**Complexity**: Low-Medium

**Tasks**:
- [x] Create /home/benjamin/.config/.claude/lib/workflow/workflow-bootstrap.sh
- [x] Implement bootstrap_workflow_env() function
- [x] Implement load_tier1_libraries() function
- [x] Add source guard pattern (prevent multiple sourcing)
- [x] Add function exports for subprocess access
- [x] Test library loading in isolation
- [x] Verify no regression with existing library loading

**Testing**:
```bash
# Test library loads correctly
source .claude/lib/workflow/workflow-bootstrap.sh
bootstrap_workflow_env && echo "CLAUDE_PROJECT_DIR: $CLAUDE_PROJECT_DIR"
load_tier1_libraries && echo "Libraries loaded successfully"

# Verify functions available
type bootstrap_workflow_env
type load_tier1_libraries

# Run linter on new library
bash .claude/scripts/validate-all-standards.sh --sourcing
```

**Expected Duration**: 2 hours

### Phase 2: Principle-Based Block Consolidation [COMPLETE]
dependencies: [1]

**Objective**: Apply consolidation principles to reduce unnecessary fragmentation while preserving natural boundaries.

**Complexity**: Medium

**Analysis Approach**:
1. For each command, identify consecutive bash blocks with no agent invocations between them
2. Evaluate whether blocks serve distinct purposes (different error handling, state checkpoints)
3. Consolidate where combining improves clarity without losing functionality
4. Preserve blocks that represent natural async boundaries or state persistence points

**Tasks**:
- [x] Analyze expand.md for consecutive blocks that can be merged
  - Identify: STEP 1 (Setup) + STEP 2 (Extract) - consecutive, no agent between
  - Identify: STEP 4 (Structure) + STEP 5 (Create) - consecutive, no agent between
  - Identify: STEP 6 (Metadata) + STEP 7 (Cleanup) - consecutive, no agent between
- [x] Merge identified consecutive blocks in expand.md
- [x] Review collapse.md for similar opportunities
- [x] Ensure state persistence works across consolidated blocks
- [x] Test all expansion scenarios (auto and manual modes)
- [x] Document the consolidation rationale in code comments

**Testing**:
```bash
# Test expand scenarios
/expand phase /path/to/test-plan.md 1
/expand /path/to/test-plan.md  # Auto mode

# Run linters
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md

# Run progressive tests
cd .claude/tests/progressive
./test_parallel_expansion.sh
```

**Expected Duration**: 4 hours

### Phase 3: Documentation Standardization [COMPLETE]
dependencies: [2]

**Objective**: Standardize all commands to "Block N" documentation pattern.

**Complexity**: Low

**Tasks**:
- [x] Update debug.md: Replace "## Part N" with "## Block N"
- [x] Update revise.md: Replace "## Part N" with "## Block N"
- [x] Update expand.md: Rename to "## Block N" (reflects consolidated structure)
- [x] Update collapse.md: Replace "## STEP N" with "## Block N"
- [x] Update convert-docs.md: Replace "## STEP N" with "## Block N"
- [x] Add table of contents to README.md
- [x] Update internal references and comments
- [x] Verify all cross-references accurate

**Testing**:
```bash
# Verify no "Part N" or "STEP N" patterns remain
grep -n "^## Part [0-9]" .claude/commands/debug.md .claude/commands/revise.md
grep -n "^## STEP [0-9]" .claude/commands/*.md
# Should return no results

# Verify "Block N" patterns
grep -c "^## Block" .claude/commands/*.md | sort -t: -k2 -n

# Validate links
bash .claude/scripts/validate-links-quick.sh .claude/commands/README.md
```

**Expected Duration**: 2 hours

### Phase 4: Testing and Validation [COMPLETE]
dependencies: [3]

**Objective**: Comprehensive testing of all refactored commands.

**Complexity**: Medium

**Tasks**:
- [x] Run linter suite on all modified command files
- [x] Run integration tests for expand and collapse
- [x] Test state persistence across consolidated block boundaries
- [x] Verify error logging integration functional
- [x] Run system-wide validation: bash .claude/scripts/validate-all-standards.sh --all
- [x] Test pre-commit hooks pass for all modified files
- [x] Document any test failures and create fix tasks

**Testing**:
```bash
# Full linter validation
bash .claude/scripts/validate-all-standards.sh --all

# Progressive tests
cd .claude/tests/progressive
for test in test_*.sh; do
  echo "Running $test..."
  ./"$test" || echo "FAILED: $test"
done

# Integration tests
cd .claude/tests/integration
for test in test_*.sh; do
  ./"$test" || echo "FAILED: $test"
done
```

**Expected Duration**: 3 hours

### Phase 5: Library Adoption (Optional) [COMPLETE]
dependencies: [4]

**Objective**: Incrementally adopt workflow-bootstrap.sh across commands.

**Complexity**: Low

**Tasks**:
- [x] Update 2-3 commands to use bootstrap_workflow_env() as pilot
- [x] Verify no regression in pilot commands
- [x] Document adoption pattern in workflow library README
- [x] Create migration guide for remaining commands
- [x] Update command template to reference workflow-bootstrap.sh

**Testing**:
```bash
# Test pilot command with bootstrap library
/plan "test feature" --dry-run
/research "test topic"

# Verify library usage
grep -l "workflow-bootstrap.sh" .claude/commands/*.md
```

**Expected Duration**: 3 hours

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

- Run existing test suite after each phase
- Verify state persistence across refactored block boundaries
- Test error logging integration throughout command lifecycle
- Validate agent Task invocations still functional

### Regression Testing

- Verify 100% error logging coverage maintained
- Confirm state management patterns preserved
- Validate all commands execute successfully
- Check that consolidated blocks don't break state persistence

## Documentation Requirements

### New Documentation
- [ ] /home/benjamin/.config/.claude/lib/workflow/workflow-bootstrap.sh - Bootstrap library
- [ ] Update .claude/lib/workflow/README.md with workflow-bootstrap.sh documentation

### Updated Documentation
- [ ] /home/benjamin/.config/.claude/commands/README.md - Add table of contents
- [ ] 5 commands with terminology changes (debug, revise, expand, collapse, convert-docs)

## Dependencies

### External Dependencies
- Existing test suite at /home/benjamin/.config/.claude/tests/
- Library functions: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- Linters: check-library-sourcing.sh, lint_error_suppression.sh, lint_bash_conditionals.sh

### Internal Dependencies
- Phase 2 depends on Phase 1 (library provides foundation)
- Phase 3 depends on Phase 2 (terminology reflects consolidated structure)
- Phase 4 depends on Phase 3 (test final documentation state)
- Phase 5 depends on Phase 4 (document validated patterns)

### Risk Mitigation
- **Risk**: Breaking existing functionality during consolidation
  - **Mitigation**: Run linter suite and integration tests after each phase
- **Risk**: State persistence issues across consolidated block boundaries
  - **Mitigation**: Extensive testing of state loading/saving
- **Risk**: Over-consolidation reducing debuggability
  - **Mitigation**: Apply principles conservatively; keep blocks separate when purpose differs

## Success Metrics

### Quantitative Metrics
- [ ] expand.md unnecessary fragmentation reduced (consecutive blocks merged)
- [ ] 100% linter compliance across all modified files
- [ ] 100% "Block N" adoption across all 12 commands
- [ ] workflow-bootstrap.sh library created and tested

### Qualitative Metrics
- [ ] Code maintainability improved through reduced duplication
- [ ] Block structure reflects command complexity (not arbitrary thresholds)
- [ ] Documentation navigability improved with table of contents
- [ ] Consistent terminology across all commands

### Validation Criteria
- [ ] All commands execute successfully after refactoring
- [ ] State persistence verified across all consolidated block boundaries
- [ ] Error logging integration confirmed (100% coverage maintained)
- [ ] All linters pass
- [ ] Pre-commit hooks pass for all modified files

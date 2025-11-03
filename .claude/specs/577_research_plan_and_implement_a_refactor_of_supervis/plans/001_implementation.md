# /supervise Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-02
- **Feature**: Refactor /supervise to adopt best improvements from /coordinate while maintaining minimal character
- **Scope**: Selective integration of /coordinate improvements focusing on verification patterns, library sourcing, and error handling while preserving /supervise's sequential execution model
- **Estimated Phases**: 4
- **Estimated Hours**: 8-10 hours
- **Structure Level**: 0
- **Complexity Score**: 47.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Recent Changes to /coordinate Command](/home/benjamin/.config/.claude/specs/577_research_plan_and_implement_a_refactor_of_supervis/reports/001_recent_changes_to_coordinate_command.md)
  - [Current State of /supervise Command](/home/benjamin/.config/.claude/specs/577_research_plan_and_implement_a_refactor_of_supervis/reports/002_current_state_of_supervise_command.md)
  - [Shared Libraries Used by Both Commands](/home/benjamin/.config/.claude/specs/577_research_plan_and_implement_a_refactor_of_supervis/reports/003_shared_libraries_used_by_both_commands.md)
  - [Minimal Orchestration Patterns and Best Practices](/home/benjamin/.config/.claude/specs/577_research_plan_and_implement_a_refactor_of_supervis/reports/004_minimal_orchestration_patterns_and_best_practices.md)

## Overview

This plan refactors /supervise to adopt proven improvements from /coordinate while maintaining its minimal and simpler character. The refactor focuses on three core improvements: (1) concise verification patterns achieving 90% token reduction, (2) standardized library sourcing for consistency, and (3) explicit context pruning implementation. The plan explicitly REJECTS wave-based parallel execution to preserve simplicity.

**Key Constraint**: /supervise MUST remain simpler than /coordinate. Target: 1,500-1,700 lines (vs current 1,938 lines).

## Research Summary

Analysis of the four research reports reveals:

**From Report 001 (Recent /coordinate Changes)**:
- /coordinate implements concise verification via `verify_file_created()` helper function (coordinate.md:771-810)
- Achieves 90% token reduction at verification checkpoints (50+ lines → 1-2 lines)
- Uses fail-fast library sourcing with consolidated `source_required_libraries()` function
- Implements explicit context pruning with `apply_pruning_policy()` calls after Phases 2, 3, 5

**From Report 002 (Current /supervise State)**:
- /supervise uses verbose 38-line diagnostic templates repeated 6+ times (supervise.md:692-730)
- Claims "80-90% context reduction" but has no actual `apply_pruning_policy()` calls
- Uses defensive library checks (`if type ... &>/dev/null`) instead of fail-fast pattern
- Size: 1,938 lines (virtually identical to /coordinate's 1,930 lines)

**From Report 003 (Shared Libraries)**:
- Both commands use identical library set (7 core libraries)
- /coordinate has 100% library integration, /supervise has ~50% integration
- workflow-initialization.sh consolidates 225 lines → 10 lines (already adopted by both)
- context-pruning.sh functions available but not fully utilized by /supervise

**From Report 004 (Minimal Orchestration Patterns)**:
- Concise verification pattern: Highest ROI for minimal commands (300-400 line reduction)
- Sequential execution: Should be preserved (no wave-based parallelization)
- External documentation: Best practice preventing inline bloat (already adopted)
- Library-first architecture: Reusability and maintainability (already adopted)

**Recommended Approach Based on Research**:
Adopt /coordinate's concise verification and context pruning implementations while explicitly rejecting wave-based execution to maintain /supervise's simpler character.

## Success Criteria

- [ ] File size reduced to 1,500-1,700 lines (200-400 line reduction from current 1,938)
- [ ] Concise verification pattern adopted (90% token reduction at checkpoints)
- [ ] Explicit context pruning implemented (`apply_pruning_policy()` calls added)
- [ ] Library sourcing standardized (fail-fast pattern, no defensive checks)
- [ ] Sequential execution model preserved (no wave-based parallelization)
- [ ] All tests passing (`.claude/tests/test_orchestration_commands.sh`)
- [ ] Verification reliability maintained (>95% success rate)
- [ ] External documentation ecosystem preserved

## Technical Design

### Architecture Decisions

**1. Adopt Concise Verification Helper Function**

Extract /coordinate's `verify_file_created()` helper function (coordinate.md:771-810) to shared library `.claude/lib/verification-helpers.sh` for reusability.

**Function Signature**:
```bash
verify_file_created() {
  local file_path="$1"
  local item_desc="$2"
  local phase_name="$3"

  if [ -f "$file_path" ] && [ -s "$file_path" ]; then
    echo -n "✓"  # Silent success - single character
    return 0
  else
    # Verbose diagnostic output (38-line template)
    echo ""
    echo "✗ ERROR [$phase_name]: $item_desc verification failed"
    # ... full diagnostic template ...
    return 1
  fi
}
```

**Rationale**: Centralizes verification logic in shared library, enables reuse across all orchestration commands.

**2. Implement Explicit Context Pruning**

Add `apply_pruning_policy()` calls after Phases 2, 3, 5 to achieve documented 80-90% context reduction target.

**Integration Points**:
- Phase 2 (Planning): `apply_pruning_policy "planning" "$WORKFLOW_SCOPE"`
- Phase 3 (Implementation): `apply_pruning_policy "implementation" "supervise"`
- Phase 5 (Debug): Test output pruned after completion

**Rationale**: Matches /coordinate's proven implementation, achieves <30% context usage target.

**3. Standardize Library Sourcing**

Replace defensive checks (`if type ... &>/dev/null`) with unconditional fail-fast pattern.

**Pattern**:
```bash
# Remove:
if type store_phase_metadata &>/dev/null; then
  store_phase_metadata "phase_1" "complete" "$ARTIFACTS"
fi

# Replace with:
store_phase_metadata "phase_1" "complete" "$ARTIFACTS"
```

**Rationale**: Fail-fast philosophy - missing libraries should cause immediate failure with clear diagnostics, not silent degradation.

**4. Preserve Sequential Execution (No Wave-Based Parallelization)**

Explicitly reject wave-based execution to maintain /supervise's minimal and simpler character.

**Rationale**:
- Wave execution adds dependency analysis, Kahn's algorithm, parallel coordination complexity
- /supervise prioritizes simplicity and predictability over 40-60% time savings
- Target audience: users who prefer debuggability and sequential workflows

### Component Interactions

```
┌─────────────────────────────────────────────────────────────┐
│ /supervise Command (1,500-1,700 lines target)              │
├─────────────────────────────────────────────────────────────┤
│ Phase 0: Library Sourcing + Path Pre-Calculation           │
│   ├── source library-sourcing.sh (fail-fast)               │
│   ├── source verification-helpers.sh (NEW)                 │
│   ├── initialize_workflow_paths() (existing)               │
│   └── emit_progress "0" "..." (existing)                   │
├─────────────────────────────────────────────────────────────┤
│ Phase 1: Research                                           │
│   ├── invoke research-specialist agents (existing)         │
│   ├── verify_file_created() for each report (NEW)          │
│   ├── extract_report_metadata() (existing)                 │
│   └── store_phase_metadata() (unconditional, UPDATED)      │
├─────────────────────────────────────────────────────────────┤
│ Phase 2: Planning                                           │
│   ├── invoke plan-architect agent (existing)               │
│   ├── verify_file_created() for plan (NEW)                 │
│   └── apply_pruning_policy "planning" (NEW)                │
├─────────────────────────────────────────────────────────────┤
│ Phase 3: Implementation (Sequential Only)                   │
│   ├── invoke code-writer agent sequentially (existing)     │
│   ├── verify_file_created() for artifacts (NEW)            │
│   └── apply_pruning_policy "implementation" (NEW)          │
├─────────────────────────────────────────────────────────────┤
│ Phase 4: Testing                                            │
│   ├── invoke test-specialist agent (existing)              │
│   └── verify_file_created() for test results (NEW)         │
├─────────────────────────────────────────────────────────────┤
│ Phase 5: Debug (Conditional)                                │
│   ├── invoke debug-analyst agent (existing)                │
│   ├── verify_file_created() for debug report (NEW)         │
│   └── apply_pruning_policy after debug (NEW)               │
├─────────────────────────────────────────────────────────────┤
│ Phase 6: Documentation (Conditional)                        │
│   ├── invoke doc-writer agent (existing)                   │
│   └── verify_file_created() for summary (NEW)              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Shared Libraries (.claude/lib/)                             │
├─────────────────────────────────────────────────────────────┤
│ verification-helpers.sh (NEW)                               │
│   └── verify_file_created() - Concise verification         │
├─────────────────────────────────────────────────────────────┤
│ context-pruning.sh (existing)                               │
│   ├── apply_pruning_policy() - Workflow-specific pruning   │
│   └── store_phase_metadata() - Metadata storage            │
├─────────────────────────────────────────────────────────────┤
│ workflow-initialization.sh (existing)                       │
│   └── initialize_workflow_paths() - Path pre-calculation   │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Create Verification Helper Library
dependencies: []

**Objective**: Extract /coordinate's `verify_file_created()` function to shared library for reuse

**Complexity**: Low

**Tasks**:
- [x] Create `.claude/lib/verification-helpers.sh` library file
- [x] Extract `verify_file_created()` function from /coordinate (coordinate.md:771-810)
- [x] Add library documentation header (purpose, functions, usage examples)
- [x] Add function documentation (parameters, return values, error handling)
- [x] Include 38-line diagnostic template in failure branch
- [x] Add success pattern: `echo -n "✓"` (single character, no newline)
- [x] Test function independently with mock file paths

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test library loads successfully
source .claude/lib/verification-helpers.sh

# Test success case
touch /tmp/test_file.txt
echo "content" > /tmp/test_file.txt
verify_file_created /tmp/test_file.txt "Test file" "Phase Test"
# Expected: ✓ (single character output)

# Test failure case
rm /tmp/test_file.txt
verify_file_created /tmp/test_file.txt "Test file" "Phase Test"
# Expected: Multi-line diagnostic with file path, directory status, diagnostic commands
```

**Expected Duration**: 1-2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(577): complete Phase 1 - Create verification helper library`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Refactor /supervise Verification Checkpoints
dependencies: [1]

**Objective**: Replace verbose inline verification blocks with concise `verify_file_created()` calls

**Complexity**: Medium

**Tasks**:
- [x] Source `verification-helpers.sh` in Phase 0 library loading section
- [x] Add verification function to required functions check
- [x] Replace Phase 1 research verification blocks (6+ instances, supervise.md:650-770)
- [x] Replace Phase 2 planning verification block (supervise.md:~1100)
- [x] Replace Phase 3 implementation verification blocks (supervise.md:~1200-1250)
- [x] Replace Phase 4 testing verification block (supervise.md:~1350)
- [x] Replace Phase 5 debug verification blocks (iteration loop, supervise.md:~1500-1600)
- [x] Replace Phase 6 documentation verification block (supervise.md:~1850)
- [x] Update verification checkpoint format: `verify_file_created "$PATH" "Description" "Phase N"`
- [x] Test all phases with actual workflow execution

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test Phase 1 research verification
/supervise "research async patterns in codebase"
# Expected: ✓✓✓ (3 reports created successfully)

# Test Phase 2 planning verification
/supervise "research and plan user authentication feature"
# Expected: ✓ (plan created successfully)

# Test failure case (simulate missing file)
# Manually remove created file before verification
# Expected: Multi-line diagnostic with ERROR marker
```

**Expected Duration**: 2-3 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(577): complete Phase 2 - Refactor verification checkpoints`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Implement Explicit Context Pruning
dependencies: [2]

**Objective**: Add `apply_pruning_policy()` calls to achieve documented 80-90% context reduction

**Complexity**: Low

**Tasks**:
- [x] Add pruning call after Phase 2 planning: `apply_pruning_policy "planning" "$WORKFLOW_SCOPE"`
- [x] Add context size logging before/after pruning (optional, for metrics)
- [x] Add pruning call after Phase 3 implementation: `apply_pruning_policy "implementation" "supervise"`
- [x] Add context size logging before/after pruning (optional)
- [x] Add pruning call after Phase 5 debugging (test output cleanup)
- [x] Remove defensive checks for `store_phase_metadata` (make unconditional)
- [x] Update Phase 1 metadata storage to unconditional call
- [x] Update Phase 2 metadata storage to unconditional call
- [x] Update Phase 3 metadata storage to unconditional call
- [x] Test context reduction metrics (compare before/after sizes)

**Testing**:
```bash
# Test full workflow with context pruning
/supervise "implement user authentication with session management"

# Verify context reduction occurred (check logs)
grep "context reduction" .claude/data/logs/*.log
# Expected: 80-90% reduction messages after Phases 2, 3, 5

# Verify metadata storage succeeded
ls -la .claude/data/checkpoints/supervise_*.json
# Expected: Checkpoint files exist with phase metadata
```

**Expected Duration**: 1-2 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(577): complete Phase 3 - Implement context pruning`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Validation and Documentation
dependencies: [3]

**Objective**: Validate refactor achieves target metrics and update documentation

**Complexity**: Low

**Tasks**:
- [ ] Run full test suite: `.claude/tests/test_orchestration_commands.sh`
- [ ] Verify line count reduction: `wc -l .claude/commands/supervise.md` (target: 1,500-1,700)
- [ ] Verify verification reliability: Run 10 test workflows, expect >95% success rate
- [ ] Verify context reduction: Check logs for 80-90% reduction confirmations
- [ ] Update CLAUDE.md orchestration section with new /supervise metrics
- [ ] Update .claude/docs/guides/supervise-guide.md (if verification pattern changes affect usage)
- [ ] Update .claude/docs/reference/supervise-phases.md (if phase verification changes)
- [ ] Add migration note in commit message explaining verification pattern change
- [ ] Run architectural validation: `.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md`
- [ ] Create completion summary documenting improvements

**Testing**:
```bash
# Full test suite
.claude/tests/test_orchestration_commands.sh

# Line count verification
BEFORE_LINES=1938
AFTER_LINES=$(wc -l < .claude/commands/supervise.md)
REDUCTION=$((BEFORE_LINES - AFTER_LINES))
echo "Line reduction: $REDUCTION lines (target: 200-400)"

# Verification reliability test (10 workflows)
for i in {1..10}; do
  /supervise "research topic $i" && echo "✓ Workflow $i succeeded" || echo "✗ Workflow $i failed"
done
# Expected: ≥9/10 successes (>90% reliability)

# Architectural validation
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: All checks pass
```

**Expected Duration**: 2-3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(577): complete Phase 4 - Validation and documentation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **verification-helpers.sh**: Test `verify_file_created()` with success/failure cases
- **Library sourcing**: Verify fail-fast behavior when libraries missing
- **Context pruning**: Verify `apply_pruning_policy()` reduces context size by 80-90%

### Integration Testing
- **Full workflows**: Test all 4 workflow scopes (research-only, research-and-plan, full-implementation, debug-only)
- **Verification checkpoints**: Verify all 14 verification points use concise pattern
- **Error handling**: Verify diagnostic quality on verification failures
- **Checkpoint recovery**: Verify resume capability from each phase boundary

### Regression Testing
- **Existing tests**: All tests in `.claude/tests/test_orchestration_commands.sh` must pass
- **File creation reliability**: >95% success rate maintained
- **Sequential execution**: Verify no wave-based parallelization introduced
- **External documentation**: Verify usage guide and phase reference links still valid

### Performance Testing
- **Line count**: Verify 200-400 line reduction (target: 1,500-1,700 lines)
- **Token reduction**: Verify 90% reduction at verification checkpoints
- **Context usage**: Verify <30% context usage throughout workflow
- **Execution time**: Baseline sequential execution time (no degradation expected)

## Documentation Requirements

### Code Documentation
- [ ] Add library documentation to `.claude/lib/verification-helpers.sh` header
- [ ] Add function documentation for `verify_file_created()` (parameters, return values, examples)
- [ ] Update inline comments in /supervise for clarity (verification pattern change)
- [ ] Add migration notes explaining verification pattern change

### External Documentation
- [ ] Update `.claude/docs/guides/supervise-guide.md` if verification pattern affects usage
- [ ] Update `.claude/docs/reference/supervise-phases.md` if phase verification changes
- [ ] Update CLAUDE.md orchestration section with new /supervise metrics (line count, context reduction)
- [ ] Add verification-helpers.sh to library reference documentation

### Commit Messages
- [ ] Phase 1: `feat(577): complete Phase 1 - Create verification helper library`
- [ ] Phase 2: `feat(577): complete Phase 2 - Refactor verification checkpoints`
- [ ] Phase 3: `feat(577): complete Phase 3 - Implement context pruning`
- [ ] Phase 4: `feat(577): complete Phase 4 - Validation and documentation`

## Dependencies

### External Dependencies
- **Libraries (existing)**:
  - `.claude/lib/library-sourcing.sh` - Consolidated library loading
  - `.claude/lib/context-pruning.sh` - Context management functions
  - `.claude/lib/workflow-initialization.sh` - Path pre-calculation
  - `.claude/lib/unified-logger.sh` - Progress tracking
  - `.claude/lib/checkpoint-utils.sh` - Checkpoint management

- **Libraries (new)**:
  - `.claude/lib/verification-helpers.sh` - Concise verification pattern (created in Phase 1)

### Internal Dependencies
- **Phase 1 → Phase 2**: Verification helper library must exist before refactoring checkpoints
- **Phase 2 → Phase 3**: Verification refactor must complete before adding pruning (reduces noise in diff)
- **Phase 3 → Phase 4**: All changes must complete before validation

### Tool Dependencies
- `bash` - Required for library sourcing and verification functions
- `jq` - Required for checkpoint JSON parsing (already used)
- `wc` - Line count validation
- `git` - Version control and diff verification

## Risk Management

### Technical Risks

**Risk 1: Verification Pattern Change Breaks Existing Workflows**
- **Probability**: Low
- **Impact**: High
- **Mitigation**: Comprehensive integration testing with all 4 workflow scopes before commit
- **Rollback**: Git revert to previous verification pattern if failures exceed 5%

**Risk 2: Context Pruning Too Aggressive**
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**: Use proven `apply_pruning_policy()` implementation from /coordinate
- **Rollback**: Remove pruning calls if context needed for later phases

**Risk 3: Line Count Reduction Target Not Met**
- **Probability**: Medium
- **Impact**: Low
- **Mitigation**: Conservative target (1,500-1,700 lines allows 200-400 line variance)
- **Fallback**: Accept 1,700-1,800 lines if verification pattern provides other benefits

### Process Risks

**Risk 4: Refactor Scope Creep (Adding Wave-Based Execution)**
- **Probability**: Low
- **Impact**: High
- **Mitigation**: Explicit constraint in plan: "DO NOT adopt wave-based parallelization"
- **Prevention**: Regular scope checks against planning constraints

**Risk 5: Breaking External Documentation Links**
- **Probability**: Low
- **Impact**: Low
- **Mitigation**: Verify all documentation links in Phase 4 validation
- **Rollback**: Update links if verification pattern changes command structure

## Notes

### Key Differentiators from /coordinate

This refactor explicitly maintains /supervise's minimal and simpler character through:

1. **Sequential Execution Only**: No wave-based parallelization (preserves simplicity)
2. **External Documentation**: Usage guide and phase reference stay external (prevents inline bloat)
3. **Library-First Architecture**: Complex logic delegated to libraries (maintains readability)
4. **Target Audience**: Users who prioritize debuggability over performance

### Adoption from /coordinate

The refactor adopts proven patterns from /coordinate:

1. **Concise Verification**: `verify_file_created()` helper function (90% token reduction)
2. **Explicit Context Pruning**: `apply_pruning_policy()` calls (80-90% context reduction)
3. **Fail-Fast Library Sourcing**: Unconditional library usage (immediate failure on missing libs)

### Rejected Features

The following /coordinate features are explicitly REJECTED to maintain minimal character:

1. **Wave-Based Parallel Execution**: Adds dependency analysis, Kahn's algorithm, parallel coordination complexity
2. **Interactive Progress Dashboard**: ANSI terminal library adds 351 lines for visual features
3. **Comprehensive Metrics Tracking**: Performance analysis adds 500+ lines
4. **PR Automation**: GitHub integration adds 574 lines for experimental features

### Success Metrics

**Target Metrics** (from research reports):
- Line count: 1,500-1,700 lines (200-400 line reduction from 1,938)
- Token reduction: 90% at verification checkpoints (3,150+ tokens saved per workflow)
- Context usage: <30% throughout workflow (via explicit pruning)
- Verification reliability: >95% success rate (maintained from current state)
- File creation reliability: 100% through proper agent invocation

**Validation Criteria**:
- All tests in `.claude/tests/test_orchestration_commands.sh` pass
- Architectural validation passes (`.claude/lib/validate-agent-invocation-pattern.sh`)
- External documentation links valid (usage guide, phase reference)
- Sequential execution preserved (no wave-based parallelization)

# Orchestration Commands Optimization Implementation Plan

## Metadata
- **Date**: 2025-10-27
- **Feature**: Optimize /supervise, /coordinate, and /research commands for startup efficiency and maintainability
- **Scope**: Command initialization, library sourcing, documentation organization, metadata extraction, and error handling improvements
- **Estimated Phases**: 5 phases (Phase 6 testing integrated into Phases 1-5)
- **Total Estimated Effort**: 10-12 hours (reduced through streamlining)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - `/home/benjamin/.config/.claude/specs/504_supervise_command_workflow_inefficiencies_and_opti/reports/001_supervise_command_workflow_inefficiencies_and_opti/OVERVIEW.md`
  - Individual reports: 001-004 in same directory

## Overview

The research reveals that /supervise, /coordinate, and /research commands demonstrate strong architectural compliance but contain addressable startup inefficiencies and organizational opportunities. This plan implements a phased optimization approach targeting:

1. **Library Sourcing Consolidation** - Eliminate 126 lines of boilerplate, achieve 30-50% startup improvement
2. **Metadata Extraction Integration** - Enable 95% context reduction (5,000 → 250 tokens per artifact)
3. **Phase 0 Path Calculation Consolidation** - Reduce 350+ lines to ~100 lines with clearer organization
4. **Documentation Extraction** - Separate 400-500 lines of non-executable documentation while maintaining standards compliance
5. **Error Handling in /research** - Fix bash associative array syntax issue documented in TODO4.md
6. **Pattern Consistency** - Align /supervise with /research's proven three-step startup pattern

All optimizations maintain full compliance with Command Architecture Standards, preserve verification-fallback mechanisms, and ensure checkpoint backward compatibility.

## Success Criteria

- [ ] Library sourcing consolidated into reusable function, reducing 126 lines of boilerplate
- [ ] Metadata extraction implemented in Phase 1 of /supervise, achieving 95% context reduction for Phase 2
- [ ] Phase 0 initialization reduced from 350+ lines to ~100 lines with improved clarity
- [ ] Non-executable documentation extracted to separate files (400-500 line reduction)
- [ ] /research bash associative array syntax error fixed
- [ ] All 6 core Command Architecture Standards remain FULLY COMPLIANT
- [ ] Checkpoint backward compatibility maintained with version migration
- [ ] Test coverage ≥80% for new consolidated functions
- [ ] Phase 0 startup time <1 second (down from 1.5-2 seconds estimated)
- [ ] File size: supervise.md <1,900 lines (down from 2,274 lines)

## Technical Design

### Architecture Overview

The optimization leverages proven patterns already used across the codebase:

```
Orchestration Commands (supervise/coordinate/research)
│
├── Phase 0: Initialization
│   ├── Consolidated Library Sourcing (NEW)
│   │   └── source_required_libraries() function
│   ├── Unified Path Calculation (NEW)
│   │   └── initialize_workflow_paths() function
│   └── Lazy Directory Creation (EXISTING)
│
├── Phase 1: Research/Data Gathering
│   ├── Agent Delegation (EXISTING)
│   └── Metadata Extraction (NEW)
│       └── extract_report_metadata() integration
│
└── Phase 2+: Planning/Implementation
    └── Metadata-Based Context (NEW)
        └── 95% context reduction enabled
```

### Key Design Decisions

1. **Library Consolidation Location**: Create `.claude/lib/library-sourcing.sh` with `source_required_libraries()` function
   - Rationale: Separate file enables testing, reuse across commands, and clear dependency management
   - Alternative considered: Add to error-handling.sh (rejected: violates single responsibility)

2. **Phase 0 Refactoring Strategy**: Extract to `.claude/lib/workflow-initialization.sh` with `initialize_workflow_paths()`
   - Rationale: Reduces inline complexity while maintaining debuggability through progress markers
   - Alternative considered: Keep inline with reduced steps (rejected: still too complex for maintenance)

3. **Documentation Extraction Targets**:
   - Move to `.claude/docs/guides/supervise-guide.md`: Usage examples, workflow tutorials
   - Move to `.claude/docs/reference/supervise-phases.md`: Phase documentation, success criteria
   - Keep inline: Execution flow explanation, behavioral injection templates, critical warnings
   - Rationale: Maintains standards compliance (inline execution docs) while improving file size

4. **Metadata Extraction Integration**: Add after Phase 1 research verification (supervise.md:1203)
   - Rationale: Zero startup cost, 95% context reduction for Phase 2, library already exists
   - Alternative considered: Extract during verification loop (rejected: complicates error handling)

5. **Checkpoint Migration Strategy**: Add checkpoint version field, implement migration function
   - Rationale: Ensures backward compatibility, prevents resume failures, enables rollback
   - Format: `CHECKPOINT_VERSION=2` (current: implicit v1)

### Component Interactions

```
.claude/commands/supervise.md
    │
    ├─→ .claude/lib/library-sourcing.sh (NEW)
    │   └─→ source_required_libraries()
    │       ├─→ Sources 7 libraries with unified error handling
    │       └─→ Returns: success/failure with detailed error messages
    │
    ├─→ .claude/lib/workflow-initialization.sh (NEW)
    │   └─→ initialize_workflow_paths($WORKFLOW_DESC, $WORKFLOW_TYPE)
    │       ├─→ Detects scope (research-only, research+planning, etc)
    │       ├─→ Calculates all artifact paths
    │       └─→ Creates topic directory structure
    │
    ├─→ .claude/lib/metadata-extraction.sh (EXISTING)
    │   └─→ extract_report_metadata($REPORT_PATH)
    │       └─→ Returns: 50-word summary + key findings (250 tokens)
    │
    └─→ .claude/docs/ (NEW STRUCTURE)
        ├─→ guides/supervise-guide.md (usage examples)
        └─→ reference/supervise-phases.md (phase documentation)
```

### Data Flow

**Before Optimization**:
```
Command Start
    ↓
Sequential Library Sourcing (126 lines, 7 × 18 lines each)
    ↓
Phase 0: 7-step initialization (350+ lines)
    ↓
Phase 1: Research delegation
    ↓
Phase 1: Verification (no metadata extraction)
    ↓
Phase 2: Planning delegation (full report context: 5,000 tokens × N reports)
```

**After Optimization**:
```
Command Start
    ↓
source_required_libraries() (12 lines, unified error handling)
    ↓
initialize_workflow_paths() (50 line stub, 3-step internal logic)
    ↓
Phase 1: Research delegation
    ↓
Phase 1: Verification + Metadata Extraction (NEW)
    ↓
Phase 2: Planning delegation (metadata context: 250 tokens × N reports = 95% reduction)
```

## Implementation Phases

### Phase 1: Library Sourcing Consolidation (Quick Win) [COMPLETED]

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 2 hours

**Objective**: Consolidate 7 sequential library sources with repetitive error handling into single reusable function

**Complexity**: LOW
**Effort**: 2 hours
**Impact**: 30-50% Phase 0 startup improvement, 90% line reduction (126 → 12 lines)

**Tasks**:
- [x] Create `.claude/lib/library-sourcing.sh` with `source_required_libraries()` function
  - Function signature: `source_required_libraries() -> exit_code`
  - Sources 7 required libraries: topic-utils.sh, detect-project-dir.sh, artifact-creation.sh, metadata-extraction.sh, overview-synthesis.sh, checkpoint-utils.sh, error-handling.sh
  - Unified error handling with single error message template
  - Returns 0 on success, 1 on failure with detailed error message
- [x] Add comprehensive unit tests to `.claude/tests/test_library_sourcing.sh`
  - Test: All 7 libraries sourced successfully
  - Test: Missing library triggers appropriate error
  - Test: Invalid library path handled gracefully
  - Test: Error message includes library name and expected path
  - Coverage target: >80%
- [x] Update `/supervise` command to use `source_required_libraries()` (supervise.md:243-376)
  - Replace 126 lines of sequential sourcing with single function call
  - Preserve error handling behavior (fail-fast on critical libraries)
  - Add progress marker: "Loading required libraries..."
- [x] Update `/coordinate` command to use `source_required_libraries()`
  - Check coordinate.md for similar library sourcing pattern
  - Replace with function call if pattern matches
- [x] Update `/research` command to use `source_required_libraries()` if applicable
  - Research command may have different library requirements
  - Apply consolidation only if pattern matches

**Testing**:
```bash
# Unit tests
.claude/tests/test_library_sourcing.sh

# Integration tests
/supervise "test workflow" --dry-run  # Verify startup succeeds
/coordinate "test workflow" --dry-run
/research "test topic"  # Verify no regressions

# Performance test
time /supervise "test workflow" --dry-run  # Should be <1 second for Phase 0
```

**Success Criteria**:
- source_required_libraries() function created with >80% test coverage
- All 3 commands updated and passing integration tests
- Phase 0 startup time reduced by 30-50% (measured via time command)
- No behavioral changes to error handling or library sourcing
- ShellCheck passes with no warnings
- **Standards validated inline (no separate Phase 6 needed)**

**Dependencies**: None

---

### Phase 2: Metadata Extraction Integration (Context Reduction) [COMPLETED]

**Dependencies**: [1]
**Risk**: Low
**Estimated Time**: 1 hour

**Objective**: Integrate metadata extraction into /supervise Phase 1 to achieve 95% context reduction for Phase 2 planning

**Complexity**: LOW
**Effort**: 1 hour
**Impact**: 95% context reduction (5,000 → 250 tokens per report), enables more complex planning in same context window

**Tasks**:
- [x] Locate Phase 1 research verification section in supervise.md (around line 1203)
- [x] After research verification loop, add metadata extraction phase:
  ```bash
  # Extract metadata for context reduction (95% reduction: 5,000 → 250 tokens)
  echo "Extracting metadata for context reduction..."
  declare -A REPORT_METADATA

  for report_path in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
    METADATA=$(extract_report_metadata "$report_path")
    REPORT_METADATA["$(basename "$report_path")"]="$METADATA"
    echo "✓ Metadata extracted: $(basename "$report_path")"
  done

  echo "✓ All metadata extracted - context usage reduced 95%"
  ```
- [x] Update Phase 2 planning agent invocation to pass metadata instead of full reports
  - Modify agent prompt to reference REPORT_METADATA array
  - Include metadata in workflow-specific context injection
  - Remove or minimize full report path references
- [x] Add context usage logging to track reduction effectiveness
  - Calculate estimated tokens before/after metadata extraction
  - Log to `.claude/data/logs/adaptive-planning.log`
  - Format: "Context reduction: 20,000 → 1,000 tokens (95%)"
- [x] Update `.claude/docs/reference/supervise-phases.md` to document metadata extraction
  - Add section explaining Phase 1 metadata extraction
  - Include context reduction metrics
  - Document when metadata vs full reports are used

**Testing**:
```bash
# Integration test with real research workflow
/supervise "test feature requiring research" --research-only

# Verify metadata extraction occurs
grep "Extracting metadata" .claude/data/logs/adaptive-planning.log

# Verify context reduction logged
grep "Context reduction:" .claude/data/logs/adaptive-planning.log

# Test with multiple reports (3-4 research topics)
/supervise "complex feature" --research-topics 4
```

**Standards Compliance Verification**:
```bash
# Verify metadata extraction follows .claude/docs/ standards
- [ ] Check metadata extraction follows metadata-extraction pattern (.claude/docs/concepts/patterns/metadata-extraction.md)
- [ ] Verify 95% context reduction achieved (5,000 → 250 tokens per report)
- [ ] Confirm agent prompts follow context management pattern (.claude/docs/concepts/patterns/context-management.md)
- [ ] Validate metadata includes: path, 50-word summary, key findings, file paths
- [ ] Test metadata caching works correctly (metadata-extraction.sh:244-293)
```

**Success Criteria**:
- Metadata extraction added to Phase 1 verification
- Context reduction ≥90% measured via logging
- Phase 2 planning agents receive metadata instead of full reports
- No regression in research → planning workflow
- **Inline validation: metadata format verified, caching tested**

**Dependencies**: [1]

---

### Phase 3: Phase 0 Path Calculation Consolidation (Structural Improvement)

**Dependencies**: [1]
**Risk**: Medium
**Estimated Time**: 4 hours

**Objective**: Consolidate Phase 0's 7-step initialization (350+ lines) into unified `initialize_workflow_paths()` function

**Complexity**: MEDIUM
**Effort**: 4 hours
**Impact**: 300+ line reduction, clearer responsibility boundaries, improved testability

**Tasks**:
- [ ] Create `.claude/lib/workflow-initialization.sh` with `initialize_workflow_paths()` function
  - Function signature: `initialize_workflow_paths($WORKFLOW_DESC, $WORKFLOW_TYPE) -> topic_dir, plans_dir, reports_dir, etc`
  - Implements 3-step pattern from /research:
    - STEP 1: Scope detection (research-only, research+planning, full workflow)
    - STEP 2: Path pre-calculation (topic dir, subdirs, artifact paths)
    - STEP 3: Directory structure creation (lazy creation, only topic root initially)
  - Returns associative array with all paths
  - Progress markers for debuggability: "Detecting workflow scope...", "Pre-calculating artifact paths...", "Creating topic directory structure..."
- [ ] Add comprehensive unit tests to `.claude/tests/test_workflow_initialization.sh`
  - Test: Research-only workflow path calculation
  - Test: Research+planning workflow path calculation
  - Test: Full workflow path calculation
  - Test: Topic directory numbering (gets next available number)
  - Test: Path pre-calculation produces absolute paths
  - Test: Lazy directory creation (only topic root created initially)
  - Coverage target: >80%
- [ ] Refactor /supervise Phase 0 (lines 637-987) to use `initialize_workflow_paths()`
  - Replace 350+ lines with ~50 line stub calling function
  - Preserve all functionality (scope detection, path calculation, directory creation)
  - Maintain progress markers for user visibility
  - Ensure WORKFLOW_SCOPE, TOPIC_DIR, PLANS_DIR, REPORTS_DIR variables populated correctly
- [ ] Update /coordinate Phase 0 to use `initialize_workflow_paths()` if similar pattern exists
- [ ] Add checkpoint version field to enable backward compatibility
  - Add `CHECKPOINT_VERSION=2` to checkpoint files
  - Implement migration function in checkpoint-utils.sh for v1 → v2 conversion
  - Test checkpoint resume with old and new checkpoints

**Testing**:
```bash
# Unit tests
.claude/tests/test_workflow_initialization.sh

# Integration tests - test all workflow types
/supervise "test feature" --research-only
/supervise "test feature" --research+planning
/supervise "test feature" --full-workflow

# Checkpoint backward compatibility test
# 1. Create checkpoint with old version
# 2. Apply Phase 3 changes
# 3. Resume from old checkpoint - should migrate and succeed

# Performance test
time /supervise "test workflow" --dry-run  # Phase 0 should be <1 second
```

**Standards Compliance Verification**:
```bash
# Verify workflow initialization follows .claude/docs/ standards
- [ ] Check lazy directory creation follows directory protocols (.claude/docs/concepts/directory-protocols.md)
- [ ] Verify checkpoint version migration follows checkpoint recovery pattern (.claude/docs/concepts/patterns/checkpoint-recovery.md)
- [ ] Confirm progress markers follow implementation guide (.claude/docs/guides/implementation-guide.md)
- [ ] Validate 3-step pattern matches /research structure (decomposition, path pre-calc, creation)
- [ ] Test that only topic root created initially (lazy creation, not 400-500 empty dirs)
```

**Success Criteria**:
- initialize_workflow_paths() function created with >80% test coverage
- /supervise Phase 0 reduced from 350+ lines to ~100 lines
- All workflow types tested (research-only, research+planning, full)
- Checkpoint backward compatibility verified
- Phase 0 execution time <1 second
- **Inline validation: lazy directory creation verified, checkpoint migration tested**

**Dependencies**: [1]

---

### Phase 4: Fix /research Bash Associative Array Syntax Error [COMPLETED]

**Dependencies**: []
**Risk**: Low
**Estimated Time**: 0.5 hours

**Objective**: Fix bash syntax error in /research command's path verification logic (documented in TODO4.md)

**Complexity**: LOW
**Effort**: 30 minutes
**Impact**: Eliminates error output in /research workflow, improves reliability

**Error Context** (from TODO4.md):
```
/run/current-system/sw/bin/bash: eval: line 119: conditional binary operator expected
/run/current-system/sw/bin/bash: eval: line 119: syntax error near `"${SUBTOPIC_REPORT_PATHS[$subtopic]}"`
/run/current-system/sw/bin/bash: eval: line 119: `  if [[ \! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then`
```

**Root Cause**: Bash `eval` context doesn't properly handle negated regex match with associative array expansion

**Tasks**:
- [x] Locate problematic code in `.claude/commands/research.md` (around STEP 2 path verification)
- [x] Replace negated regex pattern with positive pattern:
  ```bash
  # BEFORE (causes error):
  if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    echo "ERROR: Path is not absolute"
  fi

  # AFTER (fixed):
  if [[ "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    # Path is absolute - success case
    true
  else
    echo "ERROR: Path is not absolute: ${SUBTOPIC_REPORT_PATHS[$subtopic]}"
    exit 1
  fi
  ```
- [x] Alternative fix: Use string comparison instead of regex:
  ```bash
  # Alternative approach (more portable):
  if [ "${SUBTOPIC_REPORT_PATHS[$subtopic]:0:1}" != "/" ]; then
    echo "ERROR: Path is not absolute: ${SUBTOPIC_REPORT_PATHS[$subtopic]}"
    exit 1
  fi
  ```
- [x] Test both approaches and select most reliable (selected string comparison)
- [x] Add test case to `.claude/tests/test_research_command.sh`
  - Test: Absolute path validation succeeds
  - Test: Relative path validation fails with appropriate error
  - Test: Associative array expansion works correctly

**Testing**:
```bash
# Reproduce original error first
/research "test topic with multiple subtopics"
# Should no longer show bash syntax error

# Unit test
.claude/tests/test_research_command.sh  # Add new path validation test

# Integration test
/research "authentication patterns and security"  # Multi-subtopic test
# Verify: No bash errors in output, all reports created successfully
```

**Standards Compliance Verification**:
```bash
# Verify fix follows bash coding standards
- [ ] Check bash syntax follows ShellCheck recommendations (CLAUDE.md code standards)
- [ ] Verify error messages include context (path, expected format)
- [ ] Confirm fail-fast error handling (no silent path validation failures)
- [ ] Validate associative array usage follows bash best practices
- [ ] Test both absolute and relative paths (positive and negative cases)
```

**Success Criteria**:
- Bash syntax error eliminated
- Path validation working (absolute accepted, relative rejected)
- Test coverage added
- No functional regressions
- **Inline validation: ShellCheck passes, error handling tested**

**Dependencies**: []

---

### Phase 5: Documentation Extraction (Maintainability Improvement)

**Dependencies**: [3]
**Risk**: Low
**Estimated Time**: 3 hours

**Objective**: Extract 400-500 lines of non-executable documentation from supervise.md to separate files while maintaining standards compliance

**Complexity**: MEDIUM
**Effort**: 3 hours
**Impact**: 20% file size reduction (2,274 → 1,800 lines), improved navigation and maintenance

**Documentation Categorization**:

**EXTRACT** (non-executable documentation):
- Usage examples and tutorials (50+ lines)
- Phase success criteria explanations (100 lines)
- Workflow type documentation (100 lines)
- Pattern explanations and rationale (150 lines)
- Cross-references to other commands (50 lines)

**KEEP INLINE** (executable/critical documentation):
- Execution flow explanations (~200 lines)
- Behavioral injection templates (~150 lines)
- Critical warnings (CRITICAL, IMPORTANT, NEVER) (~50 lines)
- Phase step sequences with EXECUTE NOW directives (~100 lines)

**Tasks**:
- [ ] Create `.claude/docs/guides/supervise-guide.md` for usage documentation
  - Move usage examples (how to invoke /supervise with different flags)
  - Move workflow type explanations (research-only, research+planning, full)
  - Move success criteria details for each phase
  - Add navigation links back to supervise.md
  - Follow Documentation Standards from CLAUDE.md
- [ ] Create `.claude/docs/reference/supervise-phases.md` for phase documentation
  - Move detailed phase descriptions (objectives, deliverables, patterns)
  - Move phase success criteria and validation approaches
  - Keep phase task lists in supervise.md (those are executable instructions)
  - Add phase transition diagram
- [ ] Update supervise.md to reference extracted documentation
  - Add header section with links: "See guides/supervise-guide.md for usage patterns"
  - Add per-phase reference links: "Phase documentation: reference/supervise-phases.md#phase-1"
  - Remove extracted content (400-500 lines)
  - Verify remaining inline documentation totals >200 lines (maintains standards compliance)
- [ ] Validate Command Architecture Standards compliance after extraction
  - Run `.claude/lib/validate-agent-invocation-pattern.sh` on updated supervise.md
  - Verify all 6 core standards remain FULLY COMPLIANT
  - Check for any undermined imperatives or execution enforcement issues
- [ ] Update CLAUDE.md to reference new documentation structure
  - Add supervise-guide.md to relevant sections
  - Update command references to include documentation links

**Testing**:
```bash
# Standards compliance validation
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/supervise.md
# Expected: 0 anti-patterns detected, all standards FULL compliance

# Integration test - ensure command still works
/supervise "test feature" --dry-run
# Expected: No functionality changes, command executes identically

# Documentation validation
# Manually review:
# - guides/supervise-guide.md renders correctly
# - reference/supervise-phases.md renders correctly
# - Links in supervise.md point to correct sections
# - No broken references

# File size check
wc -l .claude/commands/supervise.md
# Expected: <1,900 lines (down from 2,274)
```

**Standards Compliance Verification**:
```bash
# Verify documentation follows .claude/docs/ standards
- [ ] Check extracted docs follow documentation standards (.claude/docs/concepts/writing-standards.md)
- [ ] Verify supervise.md retains all CRITICAL/IMPORTANT/NEVER warnings (command architecture standards)
- [ ] Confirm behavioral injection templates remain inline (Standard 11)
- [ ] Validate EXECUTE NOW directives preserved in command file (Standard 0)
- [ ] Test that >200 lines of execution flow documentation remain inline
- [ ] Check new docs follow present-focused, timeless writing (no "previously", "(New)" markers)
```

**Success Criteria**:
- 400-500 lines extracted to separate files
- supervise.md reduced to <1,900 lines
- All 6 core standards remain FULLY COMPLIANT (validated inline)
- Inline documentation >200 lines preserved
- No broken references
- No functional regressions
- **Inline validation: validate-agent-invocation-pattern.sh passes all 3 commands**

**Dependencies**: [3]

---

## Final Validation Summary

After completing Phases 1-5, verify overall system integration:

**Quick Integration Check** (15-20 minutes):
```bash
# Run all test suites
for test in .claude/tests/test_library_sourcing.sh \
            .claude/tests/test_workflow_initialization.sh \
            .claude/tests/test_research_command.sh; do
  bash "$test" || echo "FAILED: $test"
done

# Integration smoke test
/supervise "test workflow" --dry-run
/coordinate "test workflow" --dry-run
/research "test topic"

# Standards compliance
.claude/lib/validate-agent-invocation-pattern.sh .claude/commands/{supervise,coordinate,research}.md

# Performance check
time /supervise "test" --dry-run  # Target: <1s
```

**Success Criteria** (all phases):
- All unit tests passing (≥80% coverage)
- All integration tests passing
- Performance targets met (Phase 0 <1s, 95% context reduction)
- Standards compliance validated (all 6 core standards)
- File size targets met (supervise.md <1,900 lines)

---

## Testing Strategy

Testing is integrated into each phase. No separate validation phase needed.

### Unit Testing
- **Location**: `.claude/tests/`
- **Pattern**: `test_*.sh` for each new library/function
- **Coverage Target**: ≥80% for all new code
- **Key Test Files**:
  - `test_library_sourcing.sh` - Tests consolidated library sourcing
  - `test_workflow_initialization.sh` - Tests Phase 0 path calculation
  - `test_research_command.sh` - Tests /research syntax fix and path validation

### Integration Testing
- **Approach**: End-to-end workflow testing with all three commands
- **Test Cases**:
  - Research-only workflow (/supervise, /coordinate, /research)
  - Research + planning workflow (/supervise, /coordinate)
  - Full workflow (/supervise, /coordinate)
  - Checkpoint resume (with v1 and v2 checkpoints)
- **Validation**: Verify outputs match expected structure, no errors, correct metadata extraction

### Performance Testing
- **Metrics**:
  - Phase 0 startup time (target: <1 second)
  - Context usage in Phase 2 (target: 95% reduction from baseline)
  - Memory usage during workflow execution
- **Approach**: Run 10 iterations, calculate mean and std dev, compare to baseline

### Regression Testing
- **Focus**: Ensure no behavioral changes to existing workflows
- **Test Cases**: Run existing test suite from `.claude/tests/test_orchestration_commands.sh`
- **Validation**: All tests passing before and after optimization

## Documentation Requirements

### New Documentation Files

1. **`.claude/docs/guides/supervise-guide.md`** (NEW)
   - Usage examples and patterns
   - Workflow type documentation
   - Common use cases and best practices
   - Troubleshooting tips

2. **`.claude/docs/reference/supervise-phases.md`** (NEW)
   - Detailed phase descriptions
   - Phase success criteria
   - Phase transition diagram
   - Testing requirements per phase

3. **`.claude/docs/guides/checkpoint-migration.md`** (NEW)
   - Checkpoint version history (v1 → v2)
   - Migration process
   - Troubleshooting checkpoint resume issues

### Updated Documentation Files

1. **`.claude/commands/supervise.md`**
   - Add references to extracted documentation
   - Update inline documentation to focus on execution flow
   - Ensure >200 lines of inline docs remain (standards compliance)

2. **`.claude/docs/guides/orchestration-troubleshooting.md`**
   - Add sections for new library functions
   - Document metadata extraction debugging
   - Add Phase 0 initialization troubleshooting

3. **`.claude/docs/reference/command-reference.md`**
   - Update with optimization notes
   - Add performance characteristics
   - Document new debugging flags if added

4. **`CLAUDE.md`**
   - Update project_commands section with optimization notes
   - Update hierarchical_agent_architecture if metadata patterns changed
   - Ensure cross-references accurate

## Dependencies

### External Dependencies
- **None** - All optimizations use existing libraries and patterns

### Internal Dependencies
```
Phase 1 (Library Sourcing)
    ↓
Phase 2 (Metadata Extraction) ← depends on unified error handling
    ↓
Phase 3 (Phase 0 Consolidation) ← depends on library sourcing
    ↓
Phase 4 (/research Fix) ← independent, can run in parallel with Phase 3
    ↓
Phase 5 (Documentation Extraction) ← depends on Phase 3 completion
    ↓
Phase 6 (Testing & Validation) ← depends on all previous phases
```

### Library Dependencies
- **Existing**: topic-utils.sh, detect-project-dir.sh, metadata-extraction.sh, checkpoint-utils.sh, error-handling.sh
- **New**: library-sourcing.sh, workflow-initialization.sh

## Risk Assessment and Mitigation

### Risk 1: Checkpoint Backward Compatibility Failures
**Likelihood**: MEDIUM
**Impact**: HIGH (breaks resume functionality)
**Mitigation**:
- Implement checkpoint version field (v1 → v2)
- Create migration function converting old checkpoint format to new
- Test extensively with old checkpoints before deployment
- Provide rollback script if issues detected
- Document migration process in checkpoint-migration.md

### Risk 2: Standards Compliance Violations During Documentation Extraction
**Likelihood**: LOW
**Impact**: HIGH (violates architectural standards)
**Mitigation**:
- Run `.claude/lib/validate-agent-invocation-pattern.sh` after extraction
- Manual review of extracted vs retained documentation
- Keep execution flow documentation inline (>200 lines)
- Validate all 6 core standards remain FULLY COMPLIANT
- Automated testing in Phase 6

### Risk 3: Performance Regression Instead of Improvement
**Likelihood**: LOW
**Impact**: MEDIUM (defeats purpose of optimization)
**Mitigation**:
- Benchmark Phase 0 timing before and after changes
- Profile each optimization phase individually
- Rollback if any phase shows regression
- Target metrics documented (Phase 0 <1s, 95% context reduction)
- Performance tests in Phase 6

### Risk 4: Library Sourcing Consolidation Breaks Edge Cases
**Likelihood**: LOW
**Impact**: MEDIUM (command fails to initialize)
**Mitigation**:
- Comprehensive unit tests (>80% coverage)
- Test all error paths (missing libraries, invalid paths, permission issues)
- Preserve fail-fast behavior for critical libraries
- Integration tests with all three commands
- Gradual rollout (Phase 1 completion before Phase 3)

### Risk 5: Metadata Extraction Overhead Negates Context Savings
**Likelihood**: LOW
**Impact**: LOW (minor performance impact)
**Mitigation**:
- Use existing metadata-extraction.sh with caching
- Extraction happens once per report (~100ms each)
- Phase 2 benefits far outweigh Phase 1 cost
- Measure context reduction effectiveness in Phase 6
- Disable if overhead exceeds 10% of Phase 1 time

## Implementation Notes

### Phase Execution Order
1. **Quick Wins First** (Phases 1-2): Low complexity, high impact, build confidence
2. **Structural Changes** (Phase 3): Higher complexity, requires careful testing
3. **Independent Fixes** (Phase 4): Can run parallel with Phase 3 if desired
4. **Cleanup** (Phase 5): After structure stabilizes
5. **Final Integration Check**: 15-20 minute smoke test (see Final Validation Summary)

### Rollback Strategy
Each phase = one atomic git commit for easy rollback:
- Phase 1: `feat: consolidate library sourcing (90 line reduction)`
- Phase 2: `feat: add metadata extraction (95% context reduction)`
- Phase 3: `refactor: consolidate Phase 0 (300+ line reduction)`
- Phase 4: `fix: resolve bash associative array syntax in /research`
- Phase 5: `docs: extract documentation (400 line reduction)`

Use `git revert <commit-hash>` for quick rollback if issues arise.

### Testing Throughout Implementation
- After each phase: Run relevant unit and integration tests
- Before moving to next phase: Validate Success Criteria for current phase
- Continuous validation: Check standards compliance after any command file changes
- Final validation: Phase 6 comprehensive testing

### Checkpoint Compatibility Testing Protocol
1. Create checkpoint with current /supervise version (v1 implicit)
2. Implement Phase 3 changes (adds CHECKPOINT_VERSION=2)
3. Attempt to resume from v1 checkpoint - should trigger migration
4. Validate migration creates v2 checkpoint correctly
5. Test resume from v2 checkpoint - should work natively
6. Document any migration edge cases in checkpoint-migration.md

## Completion Checklist

Before considering implementation complete:

- [ ] All 6 phases completed with passing tests
- [ ] All Success Criteria validated (10 criteria from overview)
- [ ] Performance targets met (Phase 0 <1s, context reduction 95%, file size <1,900 lines)
- [ ] Standards compliance validated for all 3 commands (6 core standards FULL)
- [ ] Checkpoint backward compatibility tested and working
- [ ] Documentation updated (5 new/updated files)
- [ ] Test coverage ≥80% for all new code
- [ ] Integration tests passing (research-only, research+planning, full workflow)
- [ ] Performance benchmarks collected and documented
- [ ] Implementation summary created with before/after metrics

## Expected Outcomes

### Quantitative Improvements
- **File Size Reduction**: supervise.md 2,274 → 1,800 lines (20% reduction, 474 lines)
- **Boilerplate Reduction**: Library sourcing 126 → 12 lines (90% reduction, 114 lines)
- **Phase 0 Reduction**: Initialization 350+ → 100 lines (70% reduction, 250+ lines)
- **Documentation Extraction**: 400-500 lines moved to separate files
- **Context Reduction**: Phase 2 planning 5,000 → 250 tokens per report (95% reduction)
- **Startup Performance**: Phase 0 time 1.5-2.0s → <1.0s (30-50% improvement)

### Qualitative Improvements
- **Maintainability**: Clearer code organization, reduced cognitive load
- **Testability**: New library functions enable comprehensive unit testing
- **Debuggability**: Progress markers and consolidated functions improve troubleshooting
- **Consistency**: All 3 commands use same library functions and patterns
- **Standards Compliance**: Maintained full compliance with all 6 core standards
- **Documentation Quality**: Separated concerns (usage vs execution vs reference)

### Architectural Benefits
- **Reusability**: New library functions usable across all orchestration commands
- **Extensibility**: Easier to add new orchestration commands using established patterns
- **Clarity**: Three-step initialization pattern clearer than seven-step
- **Context Management**: Metadata extraction enables more complex workflows in same context window
- **Backward Compatibility**: Checkpoint migration enables smooth upgrades

---

## Notes

### Design Decisions Rationale

1. **Why separate library-sourcing.sh instead of adding to error-handling.sh?**
   - Single Responsibility Principle: error-handling.sh focused on error utilities, not initialization
   - Testability: Isolated function easier to test comprehensively
   - Reusability: Can be imported independently without error-handling.sh dependencies

2. **Why extract documentation to separate files instead of reducing inline docs?**
   - Standards Compliance: Command Architecture Standards require inline execution documentation
   - File Size: Extraction achieves size reduction without compromising standards
   - Usability: Separate guides easier to reference without scrolling through command file
   - Maintenance: Usage patterns and phase docs change less frequently than execution logic

3. **Why implement metadata extraction in Phase 2 instead of Phase 6?**
   - Quick Win: Low complexity, high impact (95% context reduction)
   - Independence: Doesn't depend on Phase 0 refactoring
   - Validation: Earlier implementation enables testing context reduction throughout development

4. **Why add checkpoint version field instead of implicit migration?**
   - Explicitness: Clear versioning prevents ambiguity
   - Debuggability: Easy to identify which checkpoint format in use
   - Extensibility: Enables future checkpoint format changes with explicit migration paths
   - Safety: Migration function can validate checkpoint integrity before conversion

### Future Optimization Opportunities

Beyond this plan's scope, but identified during research:

1. **Parallel Library Sourcing**: If library loading becomes bottleneck, investigate parallel sourcing strategies (complexity: HIGH)
2. **Lazy Library Loading**: Load libraries only when needed (e.g., checkpoint-utils.sh only if resuming) (complexity: MEDIUM)
3. **Metadata Caching Across Commands**: Share metadata cache between /supervise and /coordinate invocations (complexity: MEDIUM)
4. **Phase Dependency Analysis**: Automatic detection of parallelizable phases based on dependency graph (complexity: HIGH)
5. **Dynamic Documentation Generation**: Generate phase documentation from inline comments (complexity: MEDIUM)

These optimizations require further research and are deferred to future iterations.

### Reference Materials

- **Research Report**: `.claude/specs/504_supervise_command_workflow_inefficiencies_and_opti/reports/001_supervise_command_workflow_inefficiencies_and_opti/OVERVIEW.md`
- **Individual Reports**:
  - 001: Supervise command workflow inefficiencies
  - 002: Research command delegation patterns
  - 003: Command architecture standards compliance
  - 004: Startup initialization optimization strategies
- **Standards Documentation**: `.claude/docs/reference/command_architecture_standards.md`
- **Troubleshooting Guide**: `.claude/docs/guides/orchestration-troubleshooting.md`
- **Checkpoint Pattern**: `.claude/docs/concepts/patterns/checkpoint-recovery.md`
- **Metadata Extraction Pattern**: `.claude/docs/concepts/patterns/metadata-extraction.md`

---

## Revision History

### 2025-10-27 - Revision 2: Implementation Standards Compliance

**Changes Made**:
- Added **Standards Compliance Verification** sections to all 6 phases
- Each phase now includes explicit verification tasks for relevant `.claude/docs/` standards:
  - Phase 1: Utility library standards, error handling patterns, bash coding standards
  - Phase 2: Metadata extraction pattern, context management pattern
  - Phase 3: Directory protocols, checkpoint recovery pattern, lazy directory creation
  - Phase 4: Bash coding standards, ShellCheck compliance, error handling
  - Phase 5: Writing standards, command architecture standards (Standards 0, 11), documentation standards
  - Phase 6: Comprehensive standards validation (all command architecture standards, utility standards, testing standards, writing standards, checkpoint patterns, metadata patterns)
- Updated all Success Criteria to explicitly require standards compliance
- Enhanced Phase 6 with comprehensive standards compliance checklist covering all implementation artifacts

**Reason**: Ensure the *implementation produced by this plan* complies with all relevant `.claude/docs/` standards, not just the plan structure itself. User clarified concern is about code/artifact compliance, not plan format compliance.

**Reports Used**:
- `.claude/docs/reference/command_architecture_standards.md` - Command file standards (6 core standards)
- `.claude/docs/guides/using-utility-libraries.md` - Library file standards
- `.claude/docs/concepts/writing-standards.md` - Documentation standards
- `.claude/docs/concepts/patterns/metadata-extraction.md` - Metadata pattern standards
- `.claude/docs/concepts/patterns/checkpoint-recovery.md` - Checkpoint pattern standards
- `.claude/docs/concepts/patterns/context-management.md` - Context reduction standards
- `.claude/docs/concepts/directory-protocols.md` - Directory and artifact standards
- CLAUDE.md - Testing protocols, code standards

**Modified Phases**: All phases (1-6) updated with standards compliance verification tasks

**Verification Impact**:
- Each phase explicitly validates its outputs against relevant standards
- Phase 6 provides comprehensive validation of all implementation artifacts
- Success criteria now require standards compliance, not just functional correctness
- Implementation will produce artifacts that fully comply with `.claude/docs/` standards

### 2025-10-27 - Revision 1: Adaptive Planning Compliance

**Changes Made**:
- Added required **Dependencies**, **Risk**, and **Estimated Time** fields to all 6 phases
- Phase dependencies configured for wave-based execution:
  - Wave 1: Phases 1, 4 (independent, can run in parallel)
  - Wave 2: Phases 2, 3 (depend on Phase 1, can run in parallel with each other)
  - Wave 3: Phase 5 (depends on Phase 3)
  - Wave 4: Phase 6 (depends on all previous phases)
- Updated all **Estimated Time** fields to use hours format (e.g., "2 hours", "0.5 hours", "2-3 hours")
- All phase structures now comply with `.claude/docs/workflows/adaptive-planning-guide.md` requirements

**Reason**: Ensure plan is compatible with `/implement` command's wave-based parallel execution and adaptive planning features as documented in `.claude/docs/` standards

**Reports Used**:
- `.claude/docs/workflows/adaptive-planning-guide.md` - Phase structure requirements
- `.claude/docs/guides/implementation-guide.md` - Phase execution protocol
- `.claude/docs/concepts/directory-protocols.md` - Plan structure levels and dependencies

**Modified Phases**: All phases (1-6) updated with dependency declarations, risk levels, and time estimates

**Execution Impact**:
- Enables parallel execution of independent phases (Phases 1 and 4 can run simultaneously in Wave 1)
- Enables parallel execution of Phases 2 and 3 in Wave 2 (after Phase 1 completes)
- Provides clear dependency graph for `/implement` command
- Total estimated time remains 12-14 hours (unchanged)

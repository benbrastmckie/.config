# /coordinate Command Improvement Implementation Plan

## Metadata
- **Date**: 2025-10-29
- **Feature**: /coordinate Command Reliability and UX Improvements
- **Scope**: Error handling, progress visibility, diagnostics, and minor optimizations
- **Estimated Phases**: 6
- **Estimated Total Time**: 12-14 hours
- **Complexity Score**: 62.0 (Medium complexity)
- **Structure Level**: 0 (single file, may expand complex phases during implementation)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Error Patterns and Root Causes](../reports/001_error_patterns_and_root_causes_in_coordinate_command_research.md)
  - [Workflow Efficiency Analysis](../reports/002_workflow_efficiency_analysis_and_bottleneck_identifi_research.md)
  - [Improvement Opportunities and Best Practices](../reports/003_improvement_opportunities_and_best_practices_for_co_research.md)

## Overview

The /coordinate command is production-ready with 100% file creation reliability, correct workflow scope detection, and clean verification formatting. However, research identified 6 improvement opportunities that would enhance user experience, error diagnostics, and maintainability without compromising the excellent architectural foundation.

This plan addresses three categories of improvements:
1. **High-Priority Quick Wins** (3 hours) - Progress marker visibility and error diagnostics
2. **Medium-Priority Robustness** (8 hours) - Context metrics and regression testing
3. **Low-Priority Polish** (1.5 hours) - Documentation and completion summary enhancements

The implementation prioritizes high-impact, low-effort improvements first, allowing incremental delivery without disrupting the working command.

## Research Summary

Key findings from the three research reports:

**Error Patterns** (Report 001):
- Temp file execution failed in NixOS environment (shebang incompatibility) - recovered automatically
- Grep pattern errors from empty variable expansion during metadata extraction - non-fatal
- All errors were recoverable with graceful degradation
- **Recommendation**: Add null-checks before grep invocations, standardize plan metadata format

**Workflow Efficiency** (Report 002):
- Execution time: ~9 minutes for research-and-plan workflow
- Success rate: 100% (all agents completed, all verifications passed)
- Context usage: ~259k tokens (estimated)
- Only inefficiency: 1,803-line plan file read may be deferrable (0.7% overhead)
- **Recommendation**: Silent library operations working perfectly, maintain current implementation

**Improvement Opportunities** (Report 003):
- 6 identified improvements prioritized by impact/effort
- Current state: Production-ready with 95%+ efficiency rating
- Fail-fast error handling, behavioral injection compliance, context management all excellent
- Missing: Progress marker visibility, enhanced error diagnostics, context metrics transparency
- **Recommendation**: Implement R1+R2+R5 quick wins (3 hours), consider R3+R4 for robustness (8 hours)

**Recommended Implementation Approach**: This plan follows the research-recommended priority order, focusing on quick wins first (Phase 1-2), production hardening second (Phase 3-4), and optional polish last (Phase 5-6).

## Success Criteria

- [ ] Progress markers (PROGRESS:) visible in command output for external monitoring
- [ ] Enhanced error diagnostics provide error type, location, and recovery suggestions
- [ ] Context metrics display actual token counts and reduction percentages
- [ ] Regression test suite covers all 4 workflow scopes and failure scenarios
- [ ] Documentation cross-references link to architectural pattern docs
- [ ] Completion summary includes performance metrics (duration, context usage, file creation stats)
- [ ] All improvements maintain backward compatibility with existing workflows
- [ ] No degradation in current 100% file creation reliability
- [ ] All tests passing (existing test suite + new regression tests)
- [ ] Zero breaking changes to command interface or output format

## Technical Design

### Architecture Compliance

This plan maintains /coordinate's excellent architectural patterns:
- **Behavioral Injection**: 100% agent invocation via Task tool (no SlashCommand)
- **Verification and Fallback**: Mandatory checkpoints after all file creation
- **Fail-Fast Error Handling**: Single execution path, immediate failure feedback
- **Context Management**: <30% usage target through metadata extraction
- **Checkpoint Recovery**: Auto-resume capability preserved

### Component Integration

**Phase 1**: Progress Marker Visibility
- Modify: `.claude/lib/unified-logger.sh` (emit_progress function)
- Verify: Output format matches specification (PROGRESS: [Phase N] - description)
- Integration: No changes to coordinate.md (already calls emit_progress correctly)

**Phase 2**: Error Diagnostic Enhancement
- Import: Functions from `.claude/lib/error-handling.sh`
- Modify: Verification checkpoints in `coordinate.md` (Phases 1-6)
- Pattern: Enhanced diagnostics on failure only (maintain silent success)

**Phase 3**: Context Metrics Visibility
- Create: `.claude/lib/context-metrics.sh` (token counting utilities)
- Modify: Context pruning sections in `coordinate.md`
- Display: Before/after token counts with reduction percentages

**Phase 4**: Regression Test Suite
- Create: `.claude/tests/test_coordinate_workflows.sh`
- Integrate: Into `.claude/tests/run_all_tests.sh`
- Coverage: All 4 workflow scopes, verification failures, checkpoint resume

**Phase 5**: Documentation Cross-References
- Modify: Header sections in `coordinate.md`
- Add: Links to behavioral-injection.md, verification-fallback.md, orchestration-best-practices.md

**Phase 6**: Completion Summary Enhancement
- Modify: `display_brief_summary()` function in `coordinate.md`
- Add: Duration, context usage %, file creation stats, phase execution counts

### Risk Assessment

**Low Risk Changes** (Phases 1, 5, 6):
- Additive only, no modification to core logic
- Impact: Enhanced visibility and documentation
- Rollback: Simple (comment out additions)

**Medium Risk Changes** (Phase 2):
- Modifies verification checkpoint error messages
- Impact: Better diagnostics but changes error output format
- Mitigation: Test all failure scenarios, maintain silent success pattern
- Rollback: Revert verification checkpoint modifications

**Medium Risk Changes** (Phase 3):
- Adds context measurement calls (new library)
- Impact: Performance overhead from token counting
- Mitigation: Ensure context-metrics.sh operations are lightweight (<0.1s)
- Rollback: Remove context measurement calls, delete library

**Low Risk Changes** (Phase 4):
- New test file, no production code changes
- Impact: Better regression detection
- Rollback: N/A (tests don't affect production)

**Overall Risk Level**: LOW - All changes are additive or enhance existing functionality without modifying core orchestration logic.

## Implementation Phases

### Phase 1: Progress Marker Visibility Enhancement
dependencies: []

**Objective**: Make PROGRESS: markers visible in command output for external monitoring and improved user feedback

**Complexity**: Low

**Estimated Duration**: 1 hour

**Tasks**:
- [ ] Read current emit_progress() implementation in `.claude/lib/unified-logger.sh`
- [ ] Verify output format matches specification: `echo "PROGRESS: [Phase N] - description"`
- [ ] Test stdout redirection (ensure markers reach stdout, not stderr or log file only)
- [ ] Add documentation comment explaining PROGRESS marker format in unified-logger.sh
- [ ] Test progress markers with simple /coordinate workflow: `/coordinate "test" 2>&1 | grep "PROGRESS:"`
- [ ] Verify 5-10 progress markers appear throughout workflow execution
- [ ] Update coordinate.md header documentation to explain PROGRESS marker format for external tools
- [ ] Add example of grepping progress markers to troubleshooting section

**Testing**:
```bash
# Run /coordinate with progress marker extraction
/coordinate "research minimal test topic" 2>&1 | grep "PROGRESS:" | tee /tmp/progress_markers.txt

# Verify markers appear at phase boundaries
# Expected: PROGRESS: [Phase 0], [Phase 1], [Phase 2] markers
test $(wc -l < /tmp/progress_markers.txt) -ge 5 || echo "FAIL: Too few progress markers"
```

**Expected Impact**:
- External monitoring tools can track workflow progress
- Users see real-time feedback during long-running workflows
- Debugging easier with visible phase transitions

**Alternative Approaches Considered**:
- Option A: Keep emit_progress() as-is (silent) - Rejected: loses monitoring capability
- Option B: Add separate --verbose flag for progress - Rejected: adds complexity, standard markers better
- Option C: Make progress markers optional via env var - Rejected: always-on is simpler

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 1 - Progress marker visibility`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Error Diagnostic Enhancement
dependencies: [1]

**Objective**: Integrate error-handling.sh utilities for enhanced error diagnostics with type detection, location extraction, and recovery suggestions

**Complexity**: Medium

**Estimated Duration**: 2-3 hours

**Tasks**:
- [ ] Read error-handling.sh to understand available utilities (detect_error_type, extract_location, generate_suggestions)
- [ ] Source error-handling.sh in coordinate.md Phase 0 library loading section
- [ ] Verify all 3 utility functions available after sourcing
- [ ] Enhance Phase 1 verification checkpoint (research reports) with error diagnostics
- [ ] Enhance Phase 2 verification checkpoint (implementation plan) with error diagnostics
- [ ] Enhance Phase 3 verification checkpoint (implementation agents) with error diagnostics (if applicable)
- [ ] Enhance Phase 4 verification checkpoint (testing agents) with error diagnostics (if applicable)
- [ ] Test enhanced diagnostics by simulating file creation failure (mock agent that doesn't create file)
- [ ] Verify error output includes: error type, location (if available), recovery suggestions
- [ ] Ensure silent success pattern maintained (no verbose output on success)
- [ ] Update coordinate.md documentation to explain enhanced error diagnostic format

**Testing**:
```bash
# Create test workflow that will fail verification
# Mock research agent that exits without creating report file

# Run /coordinate and capture error output
/coordinate "test failure scenario" 2>&1 > /tmp/error_output.txt || true

# Verify enhanced diagnostics present
grep "ERROR DIAGNOSTICS:" /tmp/error_output.txt || echo "FAIL: Missing diagnostics section"
grep "Error Type:" /tmp/error_output.txt || echo "FAIL: Missing error type"
grep "RECOVERY SUGGESTIONS:" /tmp/error_output.txt || echo "FAIL: Missing suggestions"
```

**Expected Impact**:
- Faster debugging with categorized errors
- Clear recovery paths for common failures
- Better user experience during error scenarios

**Alternative Approaches Considered**:
- Option A: Write inline error handling (no library) - Rejected: duplicates error-handling.sh logic
- Option B: Only enhance Phase 1-2 checkpoints - Rejected: inconsistent UX across phases
- Option C: Make enhanced diagnostics optional via flag - Rejected: always-on provides better UX

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 2 - Error diagnostic enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Context Metrics Visibility
dependencies: [1, 2]

**Objective**: Display actual context token counts and reduction percentages for transparency and verification of <30% target

**Complexity**: Medium

**Estimated Duration**: 3-4 hours

**Tasks**:
- [ ] Check if `.claude/lib/context-metrics.sh` exists, create if missing
- [ ] Implement count_context_tokens() function (estimate based on character count or use Claude API if available)
- [ ] Implement measure_context_reduction() function (before/after measurement with percentage)
- [ ] Source context-metrics.sh in coordinate.md Phase 0 library loading
- [ ] Verify context measurement functions available
- [ ] Add context measurement before Phase 1 pruning (baseline measurement)
- [ ] Add context measurement after Phase 1 pruning (research metadata extraction)
- [ ] Add context measurement after Phase 2 pruning (planning metadata extraction)
- [ ] Add context measurement after Phase 4 pruning (implementation complete)
- [ ] Update pruning echo statements to show actual token counts: "Context pruned: 10000 → 3000 tokens (70%)"
- [ ] Add cumulative context tracking throughout workflow
- [ ] Display final context efficiency in completion summary
- [ ] Verify context measurements have minimal performance overhead (<0.1s per measurement)
- [ ] Test context metrics with full workflow execution

**Testing**:
```bash
# Run /coordinate with context metrics
/coordinate "research test topic with context tracking" 2>&1 | tee /tmp/context_metrics.txt

# Verify context measurements appear
grep "Context pruned:" /tmp/context_metrics.txt || echo "FAIL: No context metrics"

# Verify reduction percentages shown
grep -E "[0-9]+%" /tmp/context_metrics.txt || echo "FAIL: No percentages"

# Verify final efficiency report
grep "Context Usage:" /tmp/context_metrics.txt || echo "FAIL: No final summary"
```

**Expected Impact**:
- Verify <30% context usage target achieved
- Transparency on efficiency gains from metadata extraction
- Data for future optimization decisions

**Alternative Approaches Considered**:
- Option A: Manual estimation only (no library) - Rejected: inaccurate, no reusability
- Option B: Detailed token-by-token accounting - Rejected: too slow, unnecessary precision
- Option C: Context metrics only in verbose mode - Rejected: always-on provides transparency

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 3 - Context metrics visibility`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Regression Test Suite
dependencies: [1, 2, 3]

**Objective**: Create comprehensive regression tests covering all 4 workflow scopes and failure scenarios

**Complexity**: High

**Estimated Duration**: 5-6 hours

**Tasks**:
- [ ] Create `.claude/tests/test_coordinate_workflows.sh` file with test framework imports
- [ ] Implement test_research_only_workflow() - verify Phases 0-1 execute, 2-6 skip
- [ ] Implement test_research_and_plan_workflow() - verify Phases 0-2 execute, 3-6 skip
- [ ] Implement test_full_implementation_workflow() - verify Phases 0-4, 6 execute
- [ ] Implement test_debug_only_workflow() - verify Phases 0, 1, 5 execute
- [ ] Implement test_verification_failure_handling() - simulate agent file creation failure
- [ ] Implement test_checkpoint_resume() - interrupt at Phase 2, resume and verify continuation
- [ ] Implement test_parallel_research_execution() - verify 2+ agents run simultaneously
- [ ] Implement test_partial_research_failure() - verify ≥50% threshold handling
- [ ] Implement test_progress_marker_visibility() - verify PROGRESS markers in output
- [ ] Implement test_enhanced_error_diagnostics() - verify error type, location, suggestions
- [ ] Implement test_context_metrics_display() - verify token counts and percentages shown
- [ ] Add cleanup functions to remove test artifacts after each test
- [ ] Integrate test suite into `.claude/tests/run_all_tests.sh`
- [ ] Run full test suite and verify all tests pass
- [ ] Document test coverage in test file header

**Testing**:
```bash
# Run new coordinate workflow tests
bash .claude/tests/test_coordinate_workflows.sh

# Verify all tests pass
# Expected: 12/12 tests passing

# Run full test suite including new tests
bash .claude/tests/run_all_tests.sh

# Verify no regressions in other tests
```

**Expected Impact**:
- Prevent regressions when modifying /coordinate
- Ensure reliability across all workflow types
- Automated verification of improvements from Phases 1-3

**Alternative Approaches Considered**:
- Option A: Manual testing only - Rejected: not sustainable, regression-prone
- Option B: Integration tests only (no unit tests) - Accepted: workflow-level tests appropriate for orchestration
- Option C: Mock all agents - Rejected: need real agent integration tests

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 4 - Regression test suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 5: Documentation Cross-References
dependencies: []

**Objective**: Add cross-references to architectural pattern documentation for easier navigation and context

**Complexity**: Low

**Estimated Duration**: 30 minutes

**Tasks**:
- [ ] Add link to behavioral-injection.md in coordinate.md "YOUR ROLE" section
- [ ] Add link to verification-fallback.md in "Verification Helper Functions" section
- [ ] Add link to orchestration-best-practices.md in command description header
- [ ] Add link to workflow-scope-detection.md in Phase 0 scope detection section (if file exists, create reference if needed)
- [ ] Add link to context-management.md in context pruning sections
- [ ] Add link to checkpoint-recovery.md in checkpoint save/restore sections
- [ ] Verify all linked files exist, create placeholder if critical doc missing
- [ ] Update CLAUDE.md to reference coordinate.md as orchestration best practice example
- [ ] Test all documentation links (file paths correct, no broken references)

**Testing**:
```bash
# Verify all referenced documentation files exist
grep -o '\\.claude/docs/[^)]*' .claude/commands/coordinate.md | while read path; do
  [ -f "$path" ] || echo "MISSING: $path"
done

# Verify links are well-formed
# Expected: 0 missing files
```

**Expected Impact**:
- Easier navigation to architectural pattern docs
- Better understanding of /coordinate design decisions
- Knowledge transfer for new command development

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 5 - Documentation cross-references`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 6: Completion Summary Enhancement
dependencies: [3]

**Objective**: Enhance display_brief_summary() to show performance metrics (duration, context usage, file creation stats)

**Complexity**: Low

**Estimated Duration**: 1 hour

**Tasks**:
- [ ] Read current display_brief_summary() implementation in coordinate.md
- [ ] Add START_TIME variable at beginning of Phase 0 (capture workflow start time)
- [ ] Calculate duration_mins in display_brief_summary(): `$(( ($(date +%s) - START_TIME) / 60 ))`
- [ ] Add "Performance Metrics:" section to summary output
- [ ] Display workflow duration: "Duration: ${duration_mins} minutes"
- [ ] Display context efficiency: "Context Usage: <30% (target achieved)" or actual % if available
- [ ] Display file creation stats: "File Creation: 100% success rate" (calculate from verification results)
- [ ] Display phase execution count: "Phases Executed: N/M" (executed vs total)
- [ ] Test enhanced summary with research-only workflow (should show 2 phases executed)
- [ ] Test enhanced summary with research-and-plan workflow (should show 3 phases executed)
- [ ] Verify summary formatting is clean and scannable
- [ ] Ensure backward compatibility (existing artifact listing preserved)

**Testing**:
```bash
# Run /coordinate with enhanced summary
/coordinate "test enhanced summary" 2>&1 | tee /tmp/summary_output.txt

# Verify performance metrics section exists
grep "Performance Metrics:" /tmp/summary_output.txt || echo "FAIL: No metrics section"

# Verify all expected metrics present
grep "Duration:" /tmp/summary_output.txt || echo "FAIL: No duration"
grep "Context Usage:" /tmp/summary_output.txt || echo "FAIL: No context usage"
grep "File Creation:" /tmp/summary_output.txt || echo "FAIL: No file creation stats"
grep "Phases Executed:" /tmp/summary_output.txt || echo "FAIL: No phase count"
```

**Expected Impact**:
- Better visibility into workflow efficiency
- Performance data for optimization decisions
- User confirmation of reliability (100% file creation)

**Alternative Approaches Considered**:
- Option A: Separate performance report command - Rejected: users want summary in one place
- Option B: Verbose metrics only with --verbose flag - Rejected: always-on provides transparency
- Option C: Metrics in log file only - Rejected: users need immediate feedback

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(524): complete Phase 6 - Completion summary enhancement`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Unit Testing
- Individual function tests for new utilities:
  - emit_progress() format validation
  - Context measurement accuracy
  - Error diagnostic generation

### Integration Testing
- Phase 4 regression test suite (primary integration testing)
- All 4 workflow scopes exercised
- Verification failure scenarios tested
- Checkpoint resume capability tested

### Manual Testing
- Run /coordinate with real workflows after each phase
- Verify output formatting improvements
- Confirm no regressions in existing functionality
- Test error scenarios with actual agent failures

### Performance Testing
- Measure context metrics overhead (<0.1s acceptable)
- Verify progress markers don't slow execution
- Ensure error diagnostics don't impact happy path

### Acceptance Criteria
- All 12 regression tests passing
- All existing tests still passing
- 100% file creation reliability maintained
- No breaking changes to command interface
- User-facing output remains clean and scannable

## Documentation Requirements

### Files to Update
1. **coordinate.md**:
   - Header: Add architectural pattern cross-references
   - Progress markers: Document PROGRESS format for external tools
   - Error handling: Explain enhanced diagnostic format
   - Context metrics: Document token measurement display
   - Completion summary: Document new performance metrics section

2. **CLAUDE.md**:
   - Project-Specific Commands: Update /coordinate description with improvement highlights
   - Orchestration Best Practices: Reference /coordinate as production-ready example

3. **orchestration-best-practices.md** (if exists):
   - Add case study section showing /coordinate improvements
   - Document error diagnostic pattern as best practice
   - Reference progress marker format as standard

4. **New Files**:
   - `.claude/lib/context-metrics.sh` - Document token counting approach and limitations
   - `.claude/tests/test_coordinate_workflows.sh` - Document test coverage and usage

### README Updates
- Update `.claude/commands/README.md` to highlight /coordinate improvements
- Add troubleshooting section referencing progress markers and error diagnostics

## Dependencies

### External Dependencies
- **error-handling.sh**: Must exist with detect_error_type, extract_location, generate_suggestions functions
- **unified-logger.sh**: Must exist with emit_progress function
- **Test framework**: Bash test utilities (setup/teardown, assertions)

### Internal Dependencies
- **Phase Dependencies**:
  - Phase 2 depends on Phase 1 (error diagnostics build on progress visibility)
  - Phase 3 depends on Phases 1-2 (context metrics complement other visibility improvements)
  - Phase 4 depends on Phases 1-3 (tests verify all improvements)
  - Phase 5 independent (documentation only)
  - Phase 6 depends on Phase 3 (uses context metrics in summary)

### Compatibility
- **Backward Compatibility**: All changes additive or enhance existing functionality
- **Command Interface**: No changes to /coordinate invocation syntax
- **Output Format**: Enhanced but maintains existing structure (artifacts list, next steps)
- **Agent Contracts**: No changes to agent invocation patterns or requirements

## Risk Mitigation

### Mitigation Strategies

**Risk: Context measurement adds performance overhead**
- Mitigation: Lightweight estimation approach, not precise token counting
- Validation: Measure overhead per call (<0.1s), skip if exceeds threshold
- Fallback: Make context metrics optional via env var if performance issues

**Risk: Enhanced error diagnostics change error output format**
- Mitigation: Maintain silent success pattern, only enhance failure messages
- Validation: Test all existing error scenarios, ensure diagnostics don't break scripts
- Fallback: Add env var to disable enhanced diagnostics if compatibility issues

**Risk: Regression tests too slow**
- Mitigation: Use mock agents for failure scenarios, real agents for success paths
- Validation: Measure test suite execution time (<5 minutes acceptable)
- Fallback: Split into fast/slow test suites, run fast tests in CI

**Risk: Progress markers pollute output for scripts**
- Mitigation: Consistent PROGRESS: prefix allows easy filtering
- Validation: Ensure markers go to stdout (not stderr), document filtering approach
- Fallback: Make progress markers optional via env var COORDINATE_QUIET=1

### Rollback Plan

**Phase 1 Rollback**: Comment out progress marker output in emit_progress()
**Phase 2 Rollback**: Revert verification checkpoint modifications, remove error-handling.sh import
**Phase 3 Rollback**: Remove context measurement calls, delete context-metrics.sh
**Phase 4 Rollback**: N/A (tests don't affect production code)
**Phase 5 Rollback**: Remove documentation cross-references
**Phase 6 Rollback**: Revert display_brief_summary() to original implementation

### Validation Checkpoints

After each phase:
- [ ] Run existing test suite - verify no regressions
- [ ] Run /coordinate with real workflow - verify output quality
- [ ] Check git diff - ensure changes match plan
- [ ] Review commit message - follows conventional commits format

After all phases complete:
- [ ] Run full regression test suite (12 tests)
- [ ] Run /coordinate with all 4 workflow scopes
- [ ] Verify performance metrics (<10% overhead acceptable)
- [ ] Review all documentation updates for accuracy

## Notes

### Implementation Priorities

**Must Have** (Phases 1-2): Progress markers and error diagnostics
- High user impact with minimal implementation effort
- Quick wins that improve UX immediately
- Estimated: 3-4 hours total

**Should Have** (Phases 3-4): Context metrics and regression tests
- Production hardening for long-term reliability
- Data-driven optimization decisions
- Estimated: 8-10 hours total

**Nice to Have** (Phases 5-6): Documentation and summary enhancements
- Polish and knowledge transfer
- Low effort, moderate impact
- Estimated: 1.5 hours total

### Success Metrics

**Quantitative**:
- 100% file creation reliability maintained (currently 100%)
- <10% performance overhead from improvements (target: <5%)
- 12/12 regression tests passing
- Context usage remains <30% (no degradation)

**Qualitative**:
- User feedback on error diagnostic clarity
- Ease of external monitoring with progress markers
- Developer confidence from test coverage
- Knowledge transfer effectiveness from documentation

### Future Enhancements

Beyond this plan's scope (consider for future iterations):
- Interactive progress visualization (real-time phase progress bars)
- Workflow replay capability (re-run from checkpoint)
- Performance profiling mode (detailed timing for each operation)
- Workflow templates (save/reuse common workflows)
- Notification integration (Slack/email on workflow completion)

These enhancements would build on the foundation established in this plan but require separate planning and research phases.

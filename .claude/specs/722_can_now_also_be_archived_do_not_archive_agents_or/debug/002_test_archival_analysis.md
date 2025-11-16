# Test Archival Analysis - Topic 722 Extension

## Executive Summary

Following the archival of agents and library scripts (Topic 722) and the deletion of commands (Topic 718), **20+ test files** should be archived or removed that test deleted/archived functionality.

## Category 1: Tests for DELETED Commands (Topic 718)

**Commands deleted**: `orchestrate.md`, `supervise.md` (superseded by `/coordinate`)

### Definitely Remove (9 tests):

1. **benchmark_orchestrate.sh** - Benchmarks deleted /orchestrate command
2. **e2e_orchestrate_full_workflow.sh** - E2E test for deleted /orchestrate
3. **test_orchestrate_integrated_fix.sh** - Tests deleted /orchestrate
4. **test_orchestrate_planning_behavioral_injection.sh** - Tests deleted /orchestrate
5. **test_orchestrate_refactor.sh** - Tests deleted /orchestrate
6. **test_orchestrate_research_enhancements.sh** - Tests deleted /orchestrate
7. **test_orchestrate_research_enhancements_simple.sh** - Tests deleted /orchestrate
8. **test_supervise_agent_delegation.sh** - Tests deleted /supervise
9. **test_supervise_brief_summary.sh** - Tests deleted /supervise
10. **test_supervise_delegation.sh** - Tests deleted /supervise
11. **test_supervise_scope_detection.sh** - Tests deleted /supervise
12. **validate_orchestrate_pattern.sh** - Validates deleted /orchestrate pattern

## Category 2: Tests for ARCHIVED Agents/Libraries (Topic 722)

**Agents archived**: `code-reviewer.md`, `test-specialist.md`, `doc-writer.md`
**Libraries archived**: `analyze-metrics.sh`, `checkpoint-580.sh`

### Definitely Remove (2 tests):

1. **test_agent_metrics.sh** - Sources archived `analyze-metrics.sh`
   ```bash
   # From file header:
   source "$LIB_DIR/analyze-metrics.sh"
   ```

2. **analyze_test_results.sh** - Uses analyze functions from archived library

## Category 3: Meta-Tests That Reference Archived Tests

### Update or Remove (1 test):

1. **test_all_fixes_integration.sh** - Meta-test that runs other tests including deleted orchestrate tests
   - Lines 33, 37: References deleted orchestrate tests
   - **Recommendation**: Update to remove orchestrate test references, keep the rest

## Category 4: Ambiguous Tests (Require Manual Review)

### Likely Update, Not Remove:

1. **test_orchestration_commands.sh** - Tests "/coordinate, /research, /supervise"
   - **Recommendation**: Update to remove /supervise references, keep /coordinate and /research

2. **test_command_integration.sh** - Contains /orchestrate --dry-run test (line 471-476)
   - **Recommendation**: Update to remove orchestrate test, keep other command tests

3. **test_all_delegation_fixes.sh** - Mentions orchestrate/supervise but may test general patterns
   - **Recommendation**: Manual review needed

4. **test_code_writer_no_recursion.sh** - Mentions orchestrate but may test agent patterns
   - **Recommendation**: Manual review needed

5. **test_coordinate_basic.sh** - Mentions orchestrate in comparison
   - **Recommendation**: Manual review needed

6. **test_model_optimization.sh** - Mentions orchestrate/test-all
   - **Recommendation**: Manual review needed

7. **test_system_wide_location.sh** - Mentions orchestrate
   - **Recommendation**: Manual review needed

8. **validate_no_agent_slash_commands.sh** - Mentions orchestrate
   - **Recommendation**: Manual review needed

9. **verify_phase7_baselines.sh** - Mentions orchestrate
   - **Recommendation**: Manual review needed

## Proposed Archival Structure

Create `.claude/archive/tests/` directory structure:

```
.claude/archive/tests/
├── orchestrate/           # Tests for deleted /orchestrate command
│   ├── benchmark_orchestrate.sh
│   ├── e2e_orchestrate_full_workflow.sh
│   ├── test_orchestrate_integrated_fix.sh
│   ├── test_orchestrate_planning_behavioral_injection.sh
│   ├── test_orchestrate_refactor.sh
│   ├── test_orchestrate_research_enhancements.sh
│   ├── test_orchestrate_research_enhancements_simple.sh
│   └── validate_orchestrate_pattern.sh
├── supervise/             # Tests for deleted /supervise command
│   ├── test_supervise_agent_delegation.sh
│   ├── test_supervise_brief_summary.sh
│   ├── test_supervise_delegation.sh
│   └── test_supervise_scope_detection.sh
└── libraries/             # Tests for archived libraries
    ├── test_agent_metrics.sh
    └── analyze_test_results.sh
```

## Success Criteria

- [ ] 14 tests archived to `.claude/archive/tests/`
- [ ] 2 meta-tests updated (test_all_fixes_integration.sh, test_orchestration_commands.sh)
- [ ] Git history preserved (using `git mv`)
- [ ] run_all_tests.sh updated to exclude archived tests
- [ ] All remaining tests pass after archival

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Archived tests still referenced in meta-tests | Medium | Grep search for test filenames before archival |
| Test runner scripts break | Low | Update run_all_tests.sh |
| Useful test patterns lost | Low | Git history preserves all test code |
| Break existing workflows | Very Low | Pre-archival verification + fail-fast validation |

## Implementation Plan

1. **Phase 1**: Archive orchestrate tests (8 files)
2. **Phase 2**: Archive supervise tests (4 files)
3. **Phase 3**: Archive library tests (2 files)
4. **Phase 4**: Update meta-tests (2 files)
5. **Phase 5**: Update test runner scripts
6. **Phase 6**: Validation (run_all_tests.sh)
7. **Phase 7**: Git commit with descriptive message

## Estimated Impact

- **Tests before**: 126 tests
- **Tests archived**: 14 tests
- **Tests after**: 112 tests (11% reduction)
- **Disk savings**: ~180KB (estimated from file sizes)

## Related Topics

- **Topic 718**: Command cleanup (deleted orchestrate.md, supervise.md)
- **Topic 721**: Command archival (archived 8 commands)
- **Topic 722**: Agent/library archival (archived 3 agents, 5 libraries)

---

**Generated**: 2025-11-15
**Analysis Type**: Test archival dependency analysis
**Scope**: .claude/tests/*.sh (126 files analyzed)

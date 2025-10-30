# Simplified Shim Removal Plan (Clean-Break Approach)

## Metadata
- **Date**: 2025-10-29
- **Feature**: Remove artifact-operations.sh shim, use split libraries directly
- **Scope**: Update 22 references across 12 files, delete shim
- **Estimated Time**: 1-2 hours
- **Philosophy**: Clean-break, fail-fast, zero backward compatibility

## Reality Check

**Research Findings (2025-10-29)**:
- unified-location-detection.sh (14,992 bytes) **IS the consolidated library** (already complete)
- artifact-operations.sh has **22 references** (10 source statements + 12 test files), not 77
- 2 commands already migrated: research.md, coordinate.md use split libraries
- Legacy YAML converter already removed (commit 374942c3)
- Test baseline: 58/77 passing

**What Original Plan Got Wrong**:
- Proposed 28-36 hours across 6 phases for 2-hour task
- Assumed location library consolidation needed (already done)
- Proposed config.json schema (doesn't fit architecture)
- Included 60-day deprecation windows, rollback archives (violates clean-break philosophy)

**This Plan**:
- Single phase: Update references, delete shim, done
- No backward compatibility
- No verification windows
- No migration tracking spreadsheets
- Fail-fast: Either tests pass or they don't

## Success Criteria

- [ ] All artifact-operations.sh source statements updated to split libraries
- [ ] artifact-operations.sh file deleted (no archive)
- [ ] Test suite passing (≥58/77 baseline maintained)
- [ ] Git commit created

## Phase 1: Update References and Delete Shim

**Objective**: Replace artifact-operations.sh with direct split library imports

**Duration**: 1-2 hours

### Tasks

- [ ] **Find all references**
  ```bash
  grep -rn "artifact-operations\.sh" .claude/ --exclude-dir=.git | tee /tmp/references.txt
  # Expected: ~22 references across 12 files
  ```

- [ ] **Update command files** (5 files, 10 source lines)
  - orchestrate.md: Replace shim with `artifact-creation.sh + metadata-extraction.sh`
  - debug.md: Replace shim with `artifact-creation.sh + metadata-extraction.sh`
  - implement.md: Replace shim with `metadata-extraction.sh`
  - plan.md: Replace shim with `artifact-creation.sh + metadata-extraction.sh`
  - list.md: Replace shim with `metadata-extraction.sh`

  Pattern:
  ```bash
  # OLD (shim)
  source .claude/lib/artifact-operations.sh

  # NEW (split libraries)
  source .claude/lib/artifact-creation.sh
  source .claude/lib/metadata-extraction.sh
  # (Use only the libraries you need)
  ```

- [ ] **Update test files** (7 files, 12 source lines)
  - Update test_report_multi_agent_pattern.sh
  - Update test_shared_utilities.sh
  - Update test_command_integration.sh
  - Update verify_phase7_baselines.sh
  - Update test_library_references.sh

  Same pattern as above

- [ ] **Run test suite**
  ```bash
  cd .claude/tests && ./run_all_tests.sh | tee /tmp/test_results.txt
  # Expected: ≥58/77 passing (maintain baseline)
  ```

- [ ] **Delete artifact-operations.sh** (no archive)
  ```bash
  rm .claude/lib/artifact-operations.sh
  # Fail-fast: If anything still references it, bash will error immediately
  ```

- [ ] **Git commit**
  ```bash
  git add -A
  git commit -m "refactor: Remove artifact-operations.sh shim - use split libraries directly

Clean-break removal: Updated 22 references across 12 files to import
artifact-creation.sh and metadata-extraction.sh directly.

No backward compatibility layer. Commands that still reference the shim
will fail with clear 'file not found' errors.

Test baseline maintained: 58/77 passing

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
  ```

### Testing

```bash
# Single test: Does the test suite pass?
cd .claude/tests && ./run_all_tests.sh

# Expected: ≥58/77 tests passing
# If tests fail: Fix the imports, rerun tests, repeat
# No "verification window" - either it works or it doesn't
```

### Completion Criteria

- [ ] All tasks marked [x]
- [ ] Test suite passing (≥58/77)
- [ ] artifact-operations.sh file does not exist
- [ ] Git commit created

## What This Plan Does NOT Include

**No Backward Compatibility**:
- No deprecation warnings
- No 60-day windows
- No compatibility aliases
- Commands break immediately with clear errors

**No Unnecessary Infrastructure**:
- No migration tracking spreadsheets
- No rollback archives (git history is the archive)
- No verification monitoring periods
- No batched migrations for 12 files

**No Redundant Work**:
- No location library consolidation (already done)
- No config.json creation (doesn't fit architecture)
- No claude-config.sh rename (unified-location-detection.sh is fine)
- No function signature standardization (already working)

**No Documentation Phase**:
- Update code → update docs inline
- No separate "documentation update" task
- No historical markers in updated docs

## Philosophy

This plan follows the clean-break, fail-fast philosophy:

1. **Clean Break**: Delete the shim immediately after updating references
2. **Fail Fast**: bash source errors are immediate and obvious
3. **No Cruft**: Zero backward compatibility layers
4. **Git History**: The only archive we need
5. **Test Suite**: Either passes or doesn't (no monitoring periods)
6. **Economical**: 2 hours, not 11 weeks

If something breaks after this change, it should break loudly with:
```
bash: .claude/lib/artifact-operations.sh: No such file or directory
```

This is better than silently redirecting through compatibility layers.

## Notes

**Why the original plan was 18x oversized**:
- Research reports confused "what exists" with "what needs doing"
- Assumed unified-location-detection.sh needed consolidation (already consolidated)
- Counted documentation references as code references (77 vs 22 actual)
- Applied enterprise migration patterns to find-and-replace tasks
- Violated project philosophy with backward compatibility cruft

**Integration with existing work**:
- Plan 519 Phase 2 created the shim (complete)
- Plan 523 Phase 1 removed legacy YAML (complete)
- This plan completes Plan 523 Phases 3-6 in single pass (not 4 separate phases)

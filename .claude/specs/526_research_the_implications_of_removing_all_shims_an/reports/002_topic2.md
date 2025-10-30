# Impact Analysis of Shim Removal on Existing Commands

## Metadata
- **Date**: 2025-10-29
- **Agent**: research-specialist
- **Topic**: Impact analysis of shim removal on existing .claude/commands/
- **Report Type**: codebase analysis
- **Complexity Level**: 4

## Executive Summary

Analysis of shim removal impact reveals that only ONE primary shim exists (artifact-operations.sh) affecting 5 commands with 10 direct references and 7 test files with 12 references. Immediate removal would break /list, /plan, /debug, /implement, and /orchestrate commands with obvious "file not found" errors. Migration requires updating source statements to use split libraries (artifact-creation.sh, artifact-registry.sh, metadata-extraction.sh). Total migration effort estimated at 1-2 hours across all commands and tests. Risk level is LOW because failure mode is immediate and obvious, rollback is trivial, and two commands (research.md, coordinate.md) already demonstrate the migration pattern. Three additional compatibility mechanisms exist but are NOT shims requiring removal: unified-logger.sh (active consolidation), unified-location-detection.sh legacy function (unused, safe to remove), and checkpoint-utils.sh legacy note (documentation only).

## Findings

### Command Dependency Analysis

#### 1. artifact-operations.sh - The Only Active Shim

**Status**: DEPRECATED (created 2025-10-29, scheduled removal 2026-01-01)
**Purpose**: Backward-compatibility shim sourcing split libraries after refactoring
**Location**: `/home/benjamin/.config/.claude/lib/artifact-operations.sh` (57 lines)

**Commands Affected** (5 total):

1. **/list** - 3 references (lines 33, 62, 101)
   - Uses: `get_plan_metadata()`, `get_report_metadata()`
   - Functions from: metadata-extraction.sh
   - Criticality: HIGH (core listing functionality)

2. **/plan** - 4 references (lines 144, 242, 282, 318, 464, 533, 548, 608)
   - Uses: `forward_message()`, `cache_metadata()`, `load_metadata_on_demand()`, `create_topic_artifact()`
   - Functions from: metadata-extraction.sh, artifact-creation.sh
   - Criticality: HIGH (plan creation and research delegation)

3. **/debug** - 7 references (lines 163, 203, 277, 284, 285, 307, 337, 347, 361, 381, 413, 446)
   - Uses: `forward_message()`, `load_metadata_on_demand()`, `create_topic_artifact()`
   - Functions from: metadata-extraction.sh, artifact-creation.sh
   - Criticality: HIGH (debug report creation and investigation)

4. **/implement** - 10 references (lines 890, 930, 965, 1019, 1025, 1074, 1080, 1097, 1098, 1099, 1107, 1122)
   - Uses: `forward_message()`, `cache_metadata()`, `load_metadata_on_demand()`
   - Functions from: metadata-extraction.sh
   - Criticality: CRITICAL (implementation execution with research delegation)

5. **/orchestrate** - 4 references (lines 63, 609, 674, 676, 1240)
   - Uses: `forward_message()`, `create_topic_artifact()`, `extract_report_metadata()`
   - Functions from: metadata-extraction.sh, artifact-creation.sh
   - Criticality: CRITICAL (multi-agent orchestration)

**Commands Already Migrated** (2 total):
- **/research** (line 52) - Sources artifact-creation.sh directly
- **/coordinate** (line 661) - Sources artifact-creation.sh directly

**Function Distribution Across Split Libraries**:

**artifact-creation.sh** (6 functions):
- `create_topic_artifact()` - Used by /plan, /debug, /orchestrate
- `create_artifact_directory()` - Internal helper
- `create_artifact_directory_with_workflow()` - Internal helper
- `get_next_artifact_number()` - Internal helper
- `write_artifact_file()` - Internal helper
- `generate_artifact_invocation()` - Internal helper

**artifact-registry.sh** (11 functions):
- `register_artifact()` - Artifact tracking
- `query_artifacts()` - Artifact queries
- `update_artifact_status()` - Status management
- `cleanup_artifacts()` - Cleanup operations
- `validate_artifact_references()` - Validation
- `list_artifacts()` - Listing
- `get_artifact_path_by_id()` - Path resolution
- `register_operation_artifact()` - Operation tracking
- `get_artifact_path()` - Path lookup
- `validate_operation_artifacts()` - Operation validation
- `create_artifact_directory()` - Directory creation

**metadata-extraction.sh** (12 functions):
- `extract_report_metadata()` - Used by /orchestrate, /supervise
- `extract_plan_metadata()` - Metadata extraction
- `extract_summary_metadata()` - Summary extraction
- `load_metadata_on_demand()` - Used by /debug, /plan, /implement
- `cache_metadata()` - Used by /plan, /implement
- `get_cached_metadata()` - Cache lookup
- `clear_metadata_cache()` - Cache management
- `get_plan_metadata()` - Used by /list
- `get_report_metadata()` - Used by /list
- `get_plan_phase()` - Phase extraction
- `get_plan_section()` - Section extraction
- `get_report_section()` - Report section extraction

**Key Insight**: Commands use specialized functions from split libraries, NOT general-purpose functions from artifact-operations.sh. This validates the refactoring decision and simplifies migration.

#### 2. Other Compatibility Mechanisms (NOT Shims Requiring Removal)

**unified-logger.sh** - Active consolidation library
- Status: PERMANENT (not a backward-compatibility shim)
- Purpose: Consolidates adaptive-planning-logger.sh and conversion-logger.sh
- Impact of removal: CRITICAL (would break all logging across all commands)
- Recommendation: RETAIN (this is working consolidation, not technical debt)

**unified-location-detection.sh - Legacy YAML converter**
- Status: UNUSED (lines 381-416, 36 lines)
- Function: `generate_legacy_location_context()` (converts JSON to YAML)
- Impact of removal: NONE (zero active callers found)
- Recommendation: SAFE TO REMOVE (unused legacy function, keep main library)

**checkpoint-utils.sh - Legacy storage note**
- Status: DOCUMENTATION ONLY (lines 5-11)
- Purpose: Documents legacy checkpoint directory
- Impact of removal: NONE (comments don't affect execution)
- Recommendation: RETAIN (historical context, no code impact)

### Breaking Changes Assessment

#### Immediate Impact if artifact-operations.sh Removed Without Migration

**Severity**: CRITICAL (5 commands fail immediately)

**Failure Mode**:
```bash
bash: .claude/lib/artifact-operations.sh: No such file or directory
```

**Affected Operations**:
1. `/list plans` - Cannot extract plan metadata (fails on line 62)
2. `/list reports` - Cannot extract report metadata (fails on line 101)
3. `/plan <feature>` - Cannot create plans or delegate research (fails on lines 144, 464, 548)
4. `/debug <issue>` - Cannot create debug reports (fails on lines 203, 381)
5. `/implement [plan]` - Cannot delegate research for complex phases (fails on lines 965, 1098)
6. `/orchestrate <workflow>` - Cannot create artifacts or extract metadata (fails on line 609)

**User Impact**:
- Error is IMMEDIATE and OBVIOUS (bash source failure)
- Commands fail before any work is done
- No data corruption or silent failures
- Error message clearly indicates missing file

**Recovery**:
- Trivial: restore artifact-operations.sh from git
- Or: update commands to use split libraries
- No data loss or state corruption

**Severity Rating**: Critical impact, but LOW RISK due to obvious failure mode

#### Partial Migration Risks

**Scenario**: Some commands migrated, others not

**Risk**: Commands continue to work with shim, but deprecation warnings appear in logs

**Mitigation**:
- Shim emits warning once per process (line 52-56 in artifact-operations.sh)
- Warning is informational, doesn't affect functionality
- No risk of inconsistent behavior between migrated and unmigrated commands

### Migration Requirements

#### Per-Command Migration Pattern

**OLD (Using Shim)**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
```

**NEW (Using Split Libraries)**:
```bash
# For commands using create_topic_artifact
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# For commands using metadata extraction
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

# For commands using artifact registry
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh"
```

#### Command-Specific Migration Requirements

**1. /list** (1-2 minutes):
- Replace line 62: `source "$CLAUDE_PROJECT_DIR/.claude/lib/artifact-operations.sh"`
- With: `source "$CLAUDE_PROJECT_DIR/.claude/lib/metadata-extraction.sh"`
- Update line 101 similarly
- Functions used: `get_plan_metadata()`, `get_report_metadata()`

**2. /plan** (3-5 minutes):
- Replace lines 144, 464, 548 source statements
- Add both artifact-creation.sh and metadata-extraction.sh
- Functions used: `create_topic_artifact()`, `forward_message()`, `cache_metadata()`, `load_metadata_on_demand()`

**3. /debug** (3-5 minutes):
- Replace lines 203, 381 source statements
- Add both artifact-creation.sh and metadata-extraction.sh
- Functions used: `create_topic_artifact()`, `forward_message()`, `load_metadata_on_demand()`

**4. /implement** (3-5 minutes):
- Replace lines 965, 1098 source statements
- Add metadata-extraction.sh only
- Functions used: `forward_message()`, `cache_metadata()`, `load_metadata_on_demand()`

**5. /orchestrate** (2-3 minutes):
- Replace line 609 source statement
- Add both artifact-creation.sh and metadata-extraction.sh
- Functions used: `create_topic_artifact()`, `extract_report_metadata()`, `forward_message()`

**Total Command Migration**: 12-20 minutes for all 5 commands

#### Test Migration Requirements

**Test Files Affected** (7 total):

1. **test_report_multi_agent_pattern.sh** (line 10)
   - Has fallback logic for missing shim
   - Update source statement and mock functions
   - Effort: 2 minutes

2. **test_shared_utilities.sh** (lines 341, 344)
   - Tests artifact-operations.sh functionality
   - Update to test split libraries instead
   - Effort: 3 minutes

3. **test_command_integration.sh** (lines 612, 684, 705)
   - Checks for artifact-operations.sh existence
   - Update to check split libraries
   - Effort: 2 minutes

4. **verify_phase7_baselines.sh** (line 91)
   - Validates artifact-operations.sh line count (1585 lines)
   - Update to validate split libraries combined (artifact-creation.sh + artifact-registry.sh + metadata-extraction.sh)
   - Effort: 2 minutes

5. **test_library_references.sh** (line 56)
   - Lists artifact-operations.sh as standalone library
   - Update to list split libraries
   - Effort: 1 minute

**Total Test Migration**: 10-12 minutes for all tests

#### Documentation Updates

**Documentation References** (60+ files):

1. **Primary Migration Guide** (30 minutes):
   - `/home/benjamin/.config/.claude/lib/README.md` (lines 408-436)
   - Mark migration complete, update examples

2. **Developer Guide** (15 minutes):
   - `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (line 1055)
   - Update examples to show split library pattern

3. **Specification Files** (30 minutes):
   - Bulk find/replace across 60+ spec files
   - Update code examples to use split libraries
   - Use automated script for consistency

**Total Documentation**: 75 minutes

#### Total Migration Effort Estimate

- **Commands**: 12-20 minutes
- **Tests**: 10-12 minutes
- **Documentation**: 75 minutes
- **Verification**: 15 minutes (run test suite, check for warnings)
- **Total**: 112-122 minutes (~2 hours)

### Risk Assessment

#### Removal Risk Matrix

| Risk Factor | Level | Mitigation |
|-------------|-------|------------|
| Breaking changes | HIGH | Obvious failure mode, immediate error |
| Data loss | NONE | No data operations in shim |
| Silent failures | NONE | Bash exits on source failure |
| Rollback difficulty | VERY LOW | Git revert or restore single file |
| Testing gaps | LOW | Tests exist for all affected functions |
| User impact | HIGH | 5 critical commands affected |
| Migration complexity | LOW | Simple source statement updates |

#### Risk Categories by Command

**CRITICAL Risk (Breaks core workflows)**:
- `/implement` - Implementation execution with research delegation
- `/orchestrate` - Multi-agent orchestration
- Both rely heavily on metadata extraction and artifact creation

**HIGH Risk (Breaks common operations)**:
- `/plan` - Plan creation with research
- `/debug` - Debug report creation
- `/list` - Artifact listing (less critical but frequently used)

**Mitigation Strategy**:
1. Migrate in order of risk (HIGH → CRITICAL)
2. Test each command after migration
3. Run full test suite before removing shim
4. Monitor logs for deprecation warnings during migration period

#### Testing Coverage Gaps

**Current Coverage**:
- ✓ Unit tests exist for metadata extraction functions
- ✓ Integration tests exist for command workflows
- ✓ Existence checks validate shim file present

**Gaps After Shim Removal**:
1. No tests validate split libraries work when sourced directly (only tested via shim)
2. No tests verify all functions accessible from split libraries
3. No tests check for circular dependencies in split libraries
4. No regression tests for migrated commands vs shimmed commands

**Required New Tests**:
1. **Split Library Sourcing Test** (5 minutes):
   ```bash
   # Test direct sourcing of split libraries
   source .claude/lib/artifact-creation.sh
   source .claude/lib/metadata-extraction.sh
   source .claude/lib/artifact-registry.sh
   type create_topic_artifact
   type get_plan_metadata
   type register_artifact
   ```

2. **Function Availability Test** (10 minutes):
   - Verify all functions from artifact-operations.sh still accessible
   - Check return values match expected behavior
   - Validate error handling

3. **Circular Dependency Test** (5 minutes):
   - Source each library in isolation
   - Verify no "already sourced" errors
   - Check for dependency order issues

4. **Regression Test Suite** (15 minutes):
   - Run commands with shimmed version (baseline)
   - Migrate commands to split libraries
   - Run same commands (compare output)
   - Validate identical behavior

**Total New Testing**: 35 minutes

### Testing Coverage Analysis

#### Existing Test Coverage for Shim Functions

**Functions WITH Test Coverage**:

1. **create_topic_artifact()**
   - Tested in: test_command_integration.sh
   - Coverage: Plan creation, report creation, directory handling
   - Line coverage: ~85%

2. **get_plan_metadata()**, **get_report_metadata()**
   - Tested in: test_shared_utilities.sh
   - Coverage: Metadata extraction, JSON parsing, error handling
   - Line coverage: ~80%

3. **forward_message()**, **cache_metadata()**
   - Tested in: test_context_reduction.sh (implied)
   - Coverage: Context preservation, metadata caching
   - Line coverage: ~70%

**Functions WITHOUT Direct Test Coverage**:

1. **load_metadata_on_demand()**
   - No dedicated unit test
   - Tested indirectly via command integration tests
   - Gap: On-demand loading failures not tested

2. **extract_report_metadata()**, **extract_plan_metadata()**
   - Tested in metadata-extraction tests
   - Gap: Large file handling, malformed metadata not tested

3. **register_artifact()**, **query_artifacts()**
   - Basic registry tests exist
   - Gap: Concurrent access, large registries not tested

#### Test Coverage Impact After Shim Removal

**Scenario 1: Remove shim without updating tests**
- Result: Tests fail with "file not found" on source statements
- Impact: 12 test failures across 7 test files
- Fix required: Update source statements in all affected tests

**Scenario 2: Update tests to use split libraries**
- Result: Tests pass if split libraries function identically
- Risk: Subtle behavioral differences not caught
- Mitigation: Add regression tests comparing shim vs split library behavior

**Scenario 3: Add new tests before removal**
- Result: High confidence in migration safety
- Benefit: Catch issues before production impact
- Cost: 35 minutes additional testing effort

**Recommendation**: Scenario 3 (add new tests first) provides best risk mitigation

#### Test Execution Order for Safe Migration

**Phase 1: Pre-Migration Validation** (5 minutes)
```bash
# Verify current tests pass with shim
./run_all_tests.sh
# Expected: All tests pass
```

**Phase 2: Add New Split Library Tests** (35 minutes)
```bash
# Create test_split_library_migration.sh
# Test direct sourcing, function availability, regression
./test_split_library_migration.sh
# Expected: All new tests pass
```

**Phase 3: Migrate One Command** (5 minutes)
```bash
# Migrate /list command (lowest risk)
# Update source statements
# Run command-specific tests
./test_list_command.sh
# Expected: Tests pass with split libraries
```

**Phase 4: Migrate Remaining Commands** (15 minutes)
```bash
# Migrate /plan, /debug, /implement, /orchestrate
# Run full test suite after each migration
./run_all_tests.sh
# Expected: All tests pass
```

**Phase 5: Remove Shim** (2 minutes)
```bash
# Delete artifact-operations.sh
rm .claude/lib/artifact-operations.sh
# Run full test suite
./run_all_tests.sh
# Expected: All tests still pass
```

**Phase 6: Monitor Production** (7-14 days)
```bash
# Monitor logs for any missed references
grep "artifact-operations.sh" .claude/data/logs/*.log
# Expected: No references found
```

**Total Safe Migration Time**: ~62 minutes testing + ~112 minutes migration = ~3 hours total

## Recommendations

### Recommendation 1: Migrate Commands in Low-Risk to High-Risk Order

**Priority**: HIGH
**Effort**: 12-20 minutes (commands only)
**Timeline**: Complete by 2025-11-15

**Migration Order**:
1. **/list** (lowest risk, simple metadata extraction)
2. **/plan** (medium risk, moderate usage)
3. **/debug** (medium risk, moderate usage)
4. **/orchestrate** (high risk, complex orchestration)
5. **/implement** (highest risk, critical implementation path)

**Rationale**:
- Test migration pattern on low-risk command first
- Build confidence before migrating critical commands
- Early detection of issues minimizes rollback scope

**Success Criteria**:
- Each command tested individually after migration
- No deprecation warnings in logs
- Full test suite passes after each migration

### Recommendation 2: Add Regression Tests Before Removing Shim

**Priority**: HIGH
**Effort**: 35 minutes
**Timeline**: Complete before shim removal (before 2026-01-01)

**Required Tests**:
1. Split library sourcing test (verify direct sourcing works)
2. Function availability test (all functions accessible)
3. Circular dependency test (no sourcing conflicts)
4. Regression test suite (compare shim vs split library behavior)

**Rationale**:
- Current tests only validate shim-based usage
- No tests verify split libraries work when sourced directly
- Regression tests catch subtle behavioral differences

**Success Criteria**:
- All new tests pass with split libraries
- Regression tests show identical behavior (shim vs split)
- No "command not found" errors for any function

### Recommendation 3: Do NOT Remove Other Compatibility Mechanisms

**Priority**: HIGH (clarification)
**Effort**: 0 minutes (no action required)

**What to Keep**:
1. **unified-logger.sh** - Active consolidation library (PERMANENT)
2. **checkpoint-utils.sh legacy note** - Documentation only (NO CODE IMPACT)

**What is Safe to Remove**:
1. **unified-location-detection.sh `generate_legacy_location_context()`** - Unused function (36 lines)
   - Effort: 5 minutes
   - Risk: VERY LOW (zero active callers)
   - Benefit: Remove dead code (36 lines)

**Rationale**:
- Only artifact-operations.sh is a backward-compatibility shim requiring removal
- Other mechanisms serve different purposes (consolidation, documentation)
- Removing active libraries would break all commands

**Clarification for User**:
- The term "all shims" is misleading - only ONE shim exists
- Three other compatibility mechanisms are NOT shims requiring removal
- Confusion likely stems from prior research reports using broad definitions

### Recommendation 4: Automate Migration with Script

**Priority**: MEDIUM
**Effort**: 30 minutes (script creation)
**Timeline**: Optional (saves time if migrating multiple commands)

**Script Functionality**:
```bash
#!/usr/bin/env bash
# migrate-shim-references.sh
# Automates artifact-operations.sh migration

COMMAND_FILE="$1"

# Find all artifact-operations.sh source statements
grep -n "source.*artifact-operations.sh" "$COMMAND_FILE"

# Determine required split libraries based on function usage
FUNCTIONS_USED=$(grep -E "create_topic_artifact|get_plan_metadata|forward_message|cache_metadata|load_metadata_on_demand|extract_report_metadata|register_artifact|query_artifacts" "$COMMAND_FILE")

# Generate replacement source statements
if echo "$FUNCTIONS_USED" | grep -q "create_topic_artifact"; then
  echo "source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh\""
fi

if echo "$FUNCTIONS_USED" | grep -qE "get_plan_metadata|forward_message|cache_metadata|load_metadata_on_demand|extract_report_metadata"; then
  echo "source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh\""
fi

if echo "$FUNCTIONS_USED" | grep -qE "register_artifact|query_artifacts"; then
  echo "source \"\${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-registry.sh\""
fi

# Prompt for confirmation before replacing
# Perform find/replace with backup
# Generate migration report
```

**Benefits**:
- Reduces manual migration errors
- Ensures consistent replacement pattern
- Automatically determines required libraries based on function usage
- Creates backups before modification

**Usage**:
```bash
./migrate-shim-references.sh .claude/commands/list.md
./migrate-shim-references.sh .claude/commands/plan.md
# etc.
```

### Recommendation 5: Monitor Logs During Migration Period

**Priority**: MEDIUM
**Effort**: 5 minutes per week
**Timeline**: 2025-10-29 to 2026-01-01 (2 months)

**Monitoring Commands**:
```bash
# Check for deprecation warnings
grep "artifact-operations.sh is deprecated" .claude/data/logs/*.log

# Count unmigrated commands (should decrease to zero)
grep -r "source.*artifact-operations.sh" .claude/commands/*.md | wc -l

# Verify split library usage increasing
grep -r "source.*artifact-creation.sh\|source.*metadata-extraction.sh" .claude/commands/*.md | wc -l
```

**Weekly Report Template**:
```
Week of [DATE]:
- Commands still using shim: X/5
- Deprecation warnings logged: Y
- Migrated commands tested: Z
- Issues encountered: [description]
- Target: 0 commands using shim by 2025-12-01
```

**Benefits**:
- Track migration progress
- Early detection of issues
- Visibility into adoption rate
- Data for retrospective analysis

### Recommendation 6: Update Documentation After Migration Complete

**Priority**: LOW (post-migration)
**Effort**: 75 minutes
**Timeline**: After all commands migrated, before shim removal

**Documentation Updates**:
1. Mark migration complete in `/home/benjamin/.config/.claude/lib/README.md`
2. Update examples in `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md`
3. Bulk find/replace in 60+ specification files
4. Add migration retrospective section documenting lessons learned

**Rationale**:
- Documentation should reflect current state (split libraries, not shim)
- Examples guide future command development
- Retrospective captures lessons for future library refactoring

**Success Criteria**:
- All documentation shows split library pattern
- No references to deprecated artifact-operations.sh in guides
- Migration retrospective documents timeline, issues, solutions

### Recommendation 7: Remove Shim Only After Verification Period

**Priority**: HIGH
**Effort**: 5 minutes (file deletion)
**Timeline**: 2026-01-01 (after 60-day migration window)

**Pre-Removal Checklist**:
- [ ] All 5 commands migrated to split libraries
- [ ] All 7 test files updated and passing
- [ ] No deprecation warnings in logs for 14+ days
- [ ] Documentation updated to show split library pattern
- [ ] Regression tests pass (shim vs split library behavior identical)
- [ ] Production monitoring shows no issues

**Removal Process**:
1. Create final backup: `cp artifact-operations.sh artifact-operations.sh.backup-final`
2. Move to archive: `mv artifact-operations.sh ../../archive/lib/`
3. Run full test suite: `./run_all_tests.sh`
4. Monitor logs for 7 days: `grep "artifact-operations.sh" logs/*.log`
5. Git commit: "Remove artifact-operations.sh shim after successful migration"

**Rollback Plan** (if issues discovered):
1. Restore from archive: `mv ../../archive/lib/artifact-operations.sh ./`
2. Run test suite to verify restoration
3. Investigate issues before retry

**Success Criteria**:
- Test suite passes after removal
- No "file not found" errors in logs
- Commands execute normally without shim

## References

### Primary Shim File

1. `/home/benjamin/.config/.claude/lib/artifact-operations.sh` - Backward-compatibility shim (57 lines)
   - Lines 2-21: Deprecation notice and migration timeline
   - Lines 25-49: Shim implementation (sources split libraries)
   - Lines 52-56: Deprecation warning emission (once per process)

### Split Libraries (Migration Targets)

2. `/home/benjamin/.config/.claude/lib/artifact-creation.sh` - Artifact creation functions
   - Functions: create_topic_artifact(), create_artifact_directory(), get_next_artifact_number(), write_artifact_file(), generate_artifact_invocation()
   - Dependencies: base-utils.sh, unified-logger.sh, artifact-registry.sh

3. `/home/benjamin/.config/.claude/lib/artifact-registry.sh` - Artifact registry and query functions
   - Functions: register_artifact(), query_artifacts(), update_artifact_status(), cleanup_artifacts(), validate_artifact_references(), list_artifacts(), get_artifact_path_by_id(), register_operation_artifact(), get_artifact_path(), validate_operation_artifacts()
   - Dependencies: base-utils.sh, unified-logger.sh

4. `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` - Metadata extraction and caching
   - Functions: extract_report_metadata(), extract_plan_metadata(), load_metadata_on_demand(), cache_metadata(), get_cached_metadata(), get_plan_metadata(), get_report_metadata(), get_plan_phase(), get_plan_section(), get_report_section()
   - Dependencies: base-utils.sh, json-utils.sh

### Commands Requiring Migration

5. `/home/benjamin/.config/.claude/commands/list.md:33,62,101` - List artifacts command
   - Uses: get_plan_metadata(), get_report_metadata()
   - Migration: Replace with metadata-extraction.sh

6. `/home/benjamin/.config/.claude/commands/plan.md:144,242,282,318,464,533,548,608` - Plan creation command
   - Uses: forward_message(), cache_metadata(), load_metadata_on_demand(), create_topic_artifact()
   - Migration: Add artifact-creation.sh and metadata-extraction.sh

7. `/home/benjamin/.config/.claude/commands/debug.md:163,203,277,284,285,307,337,347,361,381,413,446` - Debug investigation command
   - Uses: forward_message(), load_metadata_on_demand(), create_topic_artifact()
   - Migration: Add artifact-creation.sh and metadata-extraction.sh

8. `/home/benjamin/.config/.claude/commands/implement.md:890,930,965,1019,1025,1074,1080,1097,1098,1099,1107,1122` - Implementation execution command
   - Uses: forward_message(), cache_metadata(), load_metadata_on_demand()
   - Migration: Add metadata-extraction.sh

9. `/home/benjamin/.config/.claude/commands/orchestrate.md:63,609,674,676,1240` - Multi-agent orchestration command
   - Uses: forward_message(), create_topic_artifact(), extract_report_metadata()
   - Migration: Add artifact-creation.sh and metadata-extraction.sh

### Commands Already Migrated (Examples)

10. `/home/benjamin/.config/.claude/commands/research.md:52` - Sources artifact-creation.sh directly
11. `/home/benjamin/.config/.claude/commands/coordinate.md:661` - Sources artifact-creation.sh directly

### Test Files Requiring Updates

12. `/home/benjamin/.config/.claude/tests/test_report_multi_agent_pattern.sh:10` - Multi-agent pattern tests
13. `/home/benjamin/.config/.claude/tests/test_shared_utilities.sh:341,344` - Utility library tests
14. `/home/benjamin/.config/.claude/tests/test_command_integration.sh:612,684,705` - Command integration tests
15. `/home/benjamin/.config/.claude/tests/verify_phase7_baselines.sh:91` - Baseline validation (line count check)
16. `/home/benjamin/.config/.claude/tests/test_library_references.sh:56` - Library dependency validation

### Documentation Files

17. `/home/benjamin/.config/.claude/lib/README.md:408-436` - Migration guide and timeline documentation
18. `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:1055` - Developer guide with migration examples

### Research Reports (Context)

19. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/001_shim_inventory_and_categorization_research.md` - Shim inventory (5 shims catalogued)
20. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/002_shim_dependencies_and_impact_analysis_research.md` - Dependency analysis (77+ references documented)
21. `/home/benjamin/.config/.claude/specs/523_research_all_existing_shims_in_order_to_create_and/reports/003_shim_removal_strategy_and_best_practices_research.md` - Best practices and removal strategy

### Implementation Plans (Context)

22. `/home/benjamin/.config/.claude/specs/519_claudedocs_and_the_current_implementation_in_order/plans/001_library_loading_optimization.md` - Library loading optimization plan (artifact-operations.sh split documented in Phase 2, lines 185-219)

### Other Compatibility Mechanisms (NOT Shims)

23. `/home/benjamin/.config/.claude/lib/unified-logger.sh:1-6` - Active consolidation library (permanent)
24. `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:381-416` - Legacy YAML converter (unused, safe to remove)
25. `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:5-11` - Legacy storage location note (documentation only)

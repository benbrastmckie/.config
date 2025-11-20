# Error Analysis and Repair Implementation Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Error Logging Infrastructure Improvements
- **Scope**: Implement 4 recommendations from error analysis to improve error log management and analysis
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 45.0
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/841_error_analysis_repair/reports/001_error_analysis.md)
  - [Plan Revision Insights](/home/benjamin/.config/.claude/specs/841_error_analysis_repair/reports/001_plan_revision_insights.md)

## Standards Alignment

This implementation extends the following established patterns:

### Error Handling Pattern
Reference: .claude/docs/concepts/patterns/error-handling.md

**Current Standard**: Centralized JSONL log at errors.jsonl with 10MB rotation and standard schema (timestamp, command, workflow_id, user_args, error_type, error_message, source, stack, context)

**Extensions**:
1. **Test/Production Segregation**: Add test-errors.jsonl for automatic test error routing (new pattern)
   - Justification: Error analysis found all 3 examined errors were test-generated, obscuring production issues
   - Schema evolution: Add "environment" field (values: "test", "production", "development")

2. **Metadata Enrichment**: Add severity, user, hostname fields (schema version 2)
   - Justification: Enable richer analysis, filtering, and error attribution
   - Schema versioning: Old entries coexist with new entries (no migration required)

3. **Log Rotation**: Maintain existing 10MB/5 backups policy (no configurability added)
   - Current standard is adequate for identified needs
   - Phase 3 extends rotation to support date-based mode as alternative

### Library API
Reference: .claude/docs/reference/library-api/error-handling.md

**Modified Functions**: log_command_error() behavior extended with auto-detection
**Backward Compatibility**: Existing 7-parameter signature preserved, new fields auto-populated
**New Functions**: detect_execution_context(), calculate_severity()
**Extended Functions**: rotate_error_log() supports both size-based and date-based rotation

## Overview

This plan implements four key recommendations from the error analysis report to improve the error logging infrastructure in the .claude/ system. The analysis revealed that test errors are polluting production error logs, error logs lack rotation mechanisms, test/production segregation happens post-hoc rather than at logging time, and error metadata could be enriched for better analysis.

The implementation will add error log cleanup utilities, implement log rotation with configurable retention, segregate test and production errors at logging time, and enhance error log metadata with severity, environment, user, and hostname fields.

## Research Summary

The error analysis report (001_error_analysis.md) examined the error logging system and identified these key findings:

- **Test Pollution**: All 3 analyzed errors were test-generated, demonstrating that test errors persist in production logs and obscure real issues
- **No Rotation**: Error logs grow indefinitely without rotation, leading to performance degradation and unbounded storage growth
- **Post-hoc Filtering**: Test/production segregation requires manual filtering during analysis rather than automatic segregation at logging time
- **Limited Metadata**: Current error entries lack severity, environment, user, and hostname fields that would enable richer analysis

Recommended approach based on research:
1. Prioritize test/production segregation (High priority, low effort)
2. Implement error log cleanup utility (Medium priority, low effort)
3. Add log rotation mechanism (Low priority, medium effort)
4. Enhance metadata schema (Low priority, low effort)

## Success Criteria
- [ ] Test errors automatically route to separate test-errors.jsonl file
- [ ] Production errors route to errors.jsonl without test pollution
- [ ] Error log cleanup utility can filter and archive test errors from production log
- [ ] Log rotation activates at configurable size threshold with N-file retention
- [ ] Error entries include severity, environment, user, and hostname metadata
- [ ] All existing functionality continues to work without regression
- [ ] Test suite validates all new functionality
- [ ] Documentation updated to reflect new capabilities

## Technical Design

### Architecture Overview

The error logging infrastructure improvements follow a layered approach:

**Layer 1: Error Detection Context**
- Detect execution context (test vs production) at logging time
- Use source file path analysis ($0 variable) to identify test scripts
- Check for tests/ directory and test_ prefix patterns
- New Pattern: Context detection algorithm added to error-handling pattern documentation

**Layer 2: Log Routing**
- Route errors to appropriate log file based on context
- Production errors → .claude/data/logs/errors.jsonl
- Test errors → .claude/data/logs/test-errors.jsonl
- Maintain backward compatibility: existing log_command_error callers work without changes
- Implementation: log_command_error() auto-detects context, no signature change

**Layer 3: Log Management**
- Size-based rotation: 10MB threshold with 5 backups (existing standard maintained)
- Date-based rotation: Alternative mode for time-based archival (new capability)
- Cleanup utility: Manual/automated cleanup of test pollution from production logs
- Rotation functions: Extend existing rotate_error_log() rather than replace

**Layer 4: Enhanced Metadata (Schema Version 2)**
- Add severity field: Derived from error_type using hardcoded mapping table
- Add environment field: Auto-detected from execution context
- Add user field: $USER environment variable
- Add hostname field: $HOSTNAME or $(hostname) command
- Backward Compatibility: Old entries (v1) and new entries (v2) coexist, query_errors() handles gracefully

### Component Interactions

```
┌──────────────────┐
│ log_command_error│
└────────┬─────────┘
         │
         ├─→ detect_execution_context()
         │   ├─→ check $0 for test_ prefix
         │   └─→ check path for /tests/ directory
         │
         ├─→ calculate_severity(error_type)
         │   └─→ map error_type to low/medium/high/critical
         │
         ├─→ enrich_metadata()
         │   ├─→ add severity
         │   ├─→ add environment (test/production)
         │   ├─→ add user ($USER)
         │   └─→ add hostname ($HOSTNAME)
         │
         └─→ route_to_log_file(environment)
             ├─→ test → test-errors.jsonl
             └─→ production → errors.jsonl
```

### Backward Compatibility Strategy

**Function Signature Preservation**:
- log_command_error() maintains 7-parameter signature unchanged
- New fields (environment, severity, user, hostname) auto-populated inside function
- No caller modifications required

**Schema Coexistence**:
- Old log entries (schema v1): timestamp, command, workflow_id, user_args, error_type, error_message, source, stack, context
- New log entries (schema v2): All v1 fields + severity, environment, user, hostname
- No migration required: old and new entries coexist in same file

**Query Handling**:
- query_errors() uses jq with default values: `select(.severity // "unknown")`
- /errors command displays severity if present, omits if absent
- Graceful degradation for mixed schema versions

**Verification**:
- Identify all log_command_error() callers: grep -r "log_command_error" .claude/
- Test each caller after modification (Phase 1 task)
- Test mixed schema queries (old + new entries)

### Severity Mapping Table

All severity values derived deterministically from error_type (hardcoded mapping):

| Error Type           | Severity Level | Rationale                          |
|----------------------|----------------|-------------------------------------|
| validation_error     | low            | User input issue, easily fixable    |
| parse_error          | low            | Output format issue, retryable      |
| state_error          | medium         | Workflow disruption, requires debug |
| file_error           | medium         | I/O issue, may be transient         |
| timeout_error        | medium         | Performance issue, retryable        |
| agent_error          | high           | Subagent failure, blocks workflow   |
| execution_error      | high           | General failure, investigation needed|

**Implementation**: calculate_severity() function uses switch/case on error_type
**Consistency**: Mapping is hardcoded (not configurable) for consistency across system

### Schema Evolution Strategy

**Version 1 (Current)**:
- Fields: timestamp, command, workflow_id, user_args, error_type, error_message, source, stack, context
- All existing log entries use this schema

**Version 2 (New)**:
- All Version 1 fields (unchanged)
- Additional fields: severity, environment, user, hostname
- Backward compatible: old entries remain valid, new entries have additional fields

**Query Compatibility**:
- query_errors() uses jq with default values for missing fields
- Example: `.severity // "unknown"` returns "unknown" for v1 entries
- /errors command displays new fields if present, omits if absent
- No migration required: old and new entries coexist indefinitely

**Schema Version Field** (Not implemented):
- Consider adding explicit "schema_version": 2 field in future
- Current approach: Presence of new fields indicates v2
- Sufficient for two-version coexistence

## Implementation Phases

### Phase 1: Test/Production Error Segregation [NOT STARTED]
dependencies: []

**Objective**: Automatically segregate test and production errors at logging time

**Complexity**: Medium

Tasks:
- [ ] Add detect_execution_context() function to error-handling.sh (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh)
- [ ] Implement context detection using $0 analysis (check for "test_" prefix and "/tests/" path)
- [ ] Add TEST_ERROR_LOG_FILE constant for test-errors.jsonl path
- [ ] Update log_command_error() to detect context and route to appropriate log file
- [ ] Add environment field to error log entries (values: "test", "production", "development")
- [ ] Preserve backward compatibility - existing callers work without changes (7-parameter signature maintained)
- [ ] Identify all log_command_error() callers: grep -r "log_command_error" .claude/
- [ ] Verify each caller still works after modification (no signature changes required)
- [ ] Test mixed schema queries (old entries without environment + new entries with environment)

Testing:
```bash
# Run error logging test suite
/home/benjamin/.config/.claude/tests/test_error_logging.sh

# Verify test errors route to test-errors.jsonl
ls -la /home/benjamin/.config/.claude/data/logs/test-errors.jsonl

# Verify production errors route to errors.jsonl
# (manual verification - log error from non-test context)
```

**Expected Duration**: 2 hours

### Phase 2: Error Log Cleanup Utility [NOT STARTED]
dependencies: [1]

**Objective**: Create utility to clean up test errors from production logs and archive old entries

**Complexity**: Low

Tasks:
- [ ] Create cleanup_error_logs.sh script (file: /home/benjamin/.config/.claude/scripts/cleanup_error_logs.sh)
- [ ] Implement filter by source path to exclude test errors
- [ ] Add archival option to move filtered errors to test-errors.jsonl
- [ ] Add dry-run mode to preview cleanup without making changes
- [ ] Add date-based filtering to clean up errors older than N days
- [ ] Implement summary output showing what was cleaned/archived
- [ ] Make script executable and add usage documentation

Testing:
```bash
# Test dry-run mode
/home/benjamin/.config/.claude/scripts/cleanup_error_logs.sh --dry-run

# Test filtering test errors
/home/benjamin/.config/.claude/scripts/cleanup_error_logs.sh --filter-tests

# Test date-based cleanup
/home/benjamin/.config/.claude/scripts/cleanup_error_logs.sh --since 2025-11-01

# Verify backup created before cleanup
ls -la /home/benjamin/.config/.claude/data/logs/errors.jsonl.backup
```

**Expected Duration**: 2 hours

### Phase 3: Log Rotation Implementation [NOT STARTED]
dependencies: [1]

**Objective**: Implement automatic log rotation with configurable retention

**Complexity**: Medium

Tasks:
- [ ] Review existing rotate_error_log() function implementation
- [ ] Maintain existing 10MB threshold with 5 backups (no configurability added)
- [ ] Implement rotate_by_date() function for date-based rotation as alternative mode
- [ ] Add rotation file naming convention for date mode (errors-YYYY-MM-DD.jsonl)
- [ ] Extend rotate_error_log() to support both size-based (existing) and date-based (new) rotation
- [ ] Implement compression for archived logs (gzip errors-*.jsonl.gz)
- [ ] Update query_errors() to search across rotated logs when needed

Testing:
```bash
# Test size-based rotation
# (Create large test log, verify rotation at threshold)

# Test date-based rotation
# (Set rotation to daily, verify files created with date suffix)

# Test compression
ls -la /home/benjamin/.config/.claude/data/logs/errors-*.jsonl.gz

# Test query across rotated logs
/home/benjamin/.config/.claude/commands/errors.md --since 2025-11-01
```

**Expected Duration**: 2.5 hours

### Phase 4: Enhanced Error Metadata [NOT STARTED]
dependencies: [1]

**Objective**: Add severity, user, and hostname fields to error log entries

**Complexity**: Low

Tasks:
- [ ] Add calculate_severity() function to map error_type to severity level
- [ ] Define severity mapping (state_error=medium, validation_error=low, agent_error=high, etc.)
- [ ] Add severity field to log_command_error() JSON construction
- [ ] Add user field using $USER environment variable
- [ ] Add hostname field using $HOSTNAME or $(hostname) command
- [ ] Update error log schema documentation in error-handling.md
- [ ] Update /errors command to display severity in output

Testing:
```bash
# Verify new fields in error entries
tail -1 /home/benjamin/.config/.claude/data/logs/errors.jsonl | jq .

# Verify severity field present and valid
tail -10 /home/benjamin/.config/.claude/data/logs/errors.jsonl | jq -r '.severity' | sort -u

# Verify user and hostname fields present
tail -1 /home/benjamin/.config/.claude/data/logs/errors.jsonl | jq '{user, hostname}'

# Test /errors command displays severity
/home/benjamin/.config/.claude/commands/errors.md --limit 5
```

**Expected Duration**: 1.5 hours

### Phase 5: Testing and Documentation [NOT STARTED]
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive testing and documentation updates

**Complexity**: Low

Tasks:
- [ ] Add test cases for error segregation to test_error_logging.sh
- [ ] Add test cases for cleanup utility functionality
- [ ] Add test cases for log rotation (size and date modes)
- [ ] Add test cases for enhanced metadata fields
- [ ] Update error-handling.md with test/production segregation pattern
- [ ] Update error-handling.md with environment field documentation
- [ ] Update error-handling.md with severity field and mapping table
- [ ] Update error-handling.md with enhanced metadata schema (user, hostname)
- [ ] Update error-handling.md JSONL schema section with schema v2
- [ ] Update library-api/error-handling.md with new functions (detect_execution_context, calculate_severity)
- [ ] Update library-api/error-handling.md with modified function behaviors (log_command_error, rotate_error_log)
- [ ] Validate all internal links using .claude/scripts/validate-links-quick.sh
- [ ] Update /errors command guide with new query examples (--log-file for test errors)
- [ ] Update /errors command guide with severity filtering examples
- [ ] Add cleanup utility to scripts README
- [ ] Run full test suite and verify no regressions

Testing:
```bash
# Run complete error logging test suite
/home/benjamin/.config/.claude/tests/test_error_logging.sh

# Run test suite against test-errors.jsonl
CLAUDE_ERROR_LOG=/home/benjamin/.config/.claude/data/logs/test-errors.jsonl \
  /home/benjamin/.config/.claude/tests/test_error_logging.sh

# Verify all tests pass
echo $?  # Should be 0
```

**Expected Duration**: 2 hours

## Testing Strategy

### Test Coverage Requirements

**Unit Testing**:
- Test detect_execution_context() with various $0 values (test scripts, commands, agents)
- Test calculate_severity() mapping for all error types
- Test log routing logic (test vs production contexts)
- Test cleanup utility filtering and archival operations
- Test rotation logic at threshold boundaries

**Integration Testing**:
- Test error logging from test suite → test-errors.jsonl
- Test error logging from commands → errors.jsonl
- Test cleanup utility on production logs with test pollution
- Test rotation with real log growth scenarios
- Test query_errors() across rotated logs

**Regression Testing**:
- Verify existing log_command_error callers continue to work
- Verify /errors command works with new schema
- Verify backward compatibility with old log entries (no severity field)
- Verify rotation doesn't break log parsing

### Test Execution

All tests use the existing test framework in /home/benjamin/.config/.claude/tests/test_error_logging.sh with extensions for new functionality.

Test isolation:
- Use temporary log files for unit tests
- Clean up test artifacts after each test
- Separate test and production log state

Coverage target: 90% code coverage for new functions

## Documentation Requirements

### Files to Update

1. **Error Handling Pattern Documentation** (/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)
   - Add "Test/Production Segregation" section explaining context detection algorithm
   - Define environment taxonomy (test, production, development) with detection rules
   - Update JSONL schema section to document schema v2 (add severity, environment, user, hostname fields)
   - Add severity mapping table to schema documentation
   - Document schema evolution strategy (v1/v2 coexistence)
   - Update integration examples to show environment field usage
   - Add cleanup utility usage examples

2. **Library API Documentation** (/home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md)
   - Document detect_execution_context() function: purpose, usage, return values
   - Document calculate_severity() function: error_type mapping, return values
   - Update log_command_error() behavior documentation (auto-populates new fields, signature unchanged)
   - Update rotate_error_log() documentation to mention date-based mode extension
   - Add examples showing query_errors() with --log-file parameter for test logs
   - Document schema v2 field handling in query functions

3. **Errors Command Guide** (/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md)
   - Add --log-file option documentation for querying test-errors.jsonl
   - Provide examples: `/errors --log-file test-errors.jsonl --limit 10`
   - Show severity-based filtering examples (once implemented)
   - Document new output fields (severity, environment, user, hostname) in formatted display
   - Add troubleshooting section for test/production segregation

4. **Scripts README** (.claude/scripts/README.md or equivalent)
   - Add cleanup_error_logs.sh to scripts inventory
   - Document command-line options: --dry-run, --filter-tests, --since
   - Provide common cleanup scenarios (remove test pollution, archive old errors)
   - Explain backup behavior (automatic backup before cleanup)

### Standards Updates

**Error Handling Pattern Standard**: Update to reflect new capabilities
- Add environment field to standard JSONL schema
- Document test/production segregation as standard practice
- Define severity as derived field (not logged separately in early implementations)

**No New Documentation Files**: All changes extend existing documentation

## Dependencies

### External Dependencies
- jq (JSON processing) - already available
- gzip (log compression) - system utility
- stat/du (file size checking) - system utilities

### Internal Dependencies
- error-handling.sh library (existing, will be enhanced)
- state-persistence.sh (for rotation state tracking)
- test_error_logging.sh (existing test suite, will be extended)

### Prerequisite Verification
All dependencies are already present in the system. No new installations required.

## Risk Mitigation

### Risk 1: Breaking Existing Error Logging
- **Mitigation**: Preserve backward compatibility in log_command_error signature
- **Validation**: Regression test suite verifying all existing callers

### Risk 2: Log File Corruption During Rotation
- **Mitigation**: Atomic file operations, create backup before rotation
- **Validation**: Test rotation with concurrent writes

### Risk 3: Performance Impact of Context Detection
- **Mitigation**: Simple $0 string check, minimal overhead (<1ms)
- **Validation**: Benchmark log_command_error performance before/after

### Risk 4: Test Cleanup Removing Production Errors
- **Mitigation**: Dry-run mode, backup creation, strict filtering logic
- **Validation**: Test cleanup utility with mixed test/production logs

## Notes

- Phase dependencies enable sequential execution (each phase builds on previous)
- Complexity score of 45 keeps this as single-file plan (Tier 1)
- Backward compatibility is critical - existing systems must continue to work
- Test/production segregation (Phase 1) is highest priority based on research
- Log rotation enhancement (Phase 3) maintains existing 10MB/5 backups policy - no configurability added per standards conformance decision
- Schema versioning uses field presence detection (v2 has severity/environment/user/hostname) rather than explicit version field
- All new functions (detect_execution_context, calculate_severity) are internal to error-handling.sh library

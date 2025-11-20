# Error Logging Standards Update Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Test/Production Log Separation with Clean Architecture
- **Scope**: Implement automatic log separation, add environment field to schema, update documentation to current state
- **Estimated Phases**: 3
- **Estimated Hours**: 1.5 (1 hour 30 minutes)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 18.5
- **Research Reports**:
  - [Error Logging Standards Research](/home/benjamin/.config/.claude/specs/847_updating_the_standard_for_error_logging_to_claude/reports/001_error_logging_standards_research.md)
  - [Clean-Break Revision Insights](/home/benjamin/.config/.claude/specs/847_updating_the_standard_for_error_logging_to_claude/reports/002_clean_break_revision_insights.md)

## Overview

This plan implements automatic test/production error log separation following clean-break architecture principles. The system routes test errors to `test-errors.jsonl` and production errors to `errors.jsonl` through automatic context detection with zero caller impact.

The implementation adds an `environment` field to the JSONL schema for self-documenting log entries and enables future environment types (staging, CI, etc.). Test logs are placed in `.claude/tests/logs/` where test artifacts belong, while production logs remain in `.claude/data/logs/`.

This clean-break approach delivers the core value of test segregation without compatibility compromises, since zero production code currently calls `log_command_error()`.

## Research Summary

The research reports reveal critical context:

**From Error Logging Standards Research**:
- Comprehensive infrastructure exists (1,237-line error-handling.sh)
- Zero commands actually use log_command_error() despite sourcing the library
- Current errors.jsonl contains only 3 test-generated entries (100% test pollution)
- Three documentation files need rewriting for log separation

**From Clean-Break Revision Insights**:
- Current plan has 18 backward compatibility references despite zero production usage
- Writing standards prioritize "coherence over compatibility"
- Clean-break approach enables simpler architecture (test logs in tests/ directory)
- Adding environment field improves schema clarity without compatibility cost
- Documentation should describe current state without historical markers

**Recommended Approach**: Implement clean log separation with environment field, rewrite documentation as current state, avoid all backward compatibility language.

## Success Criteria

- [ ] Test errors automatically route to `.claude/tests/logs/test-errors.jsonl`
- [ ] Production errors route to `.claude/data/logs/errors.jsonl`
- [ ] Context detection works for all scripts in `.claude/tests/` directory
- [ ] JSONL schema includes `environment` field (test/production)
- [ ] Error handling pattern documentation describes current log architecture
- [ ] API reference documentation describes context detection as native behavior
- [ ] Architecture Standard 17 includes log separation requirements
- [ ] /errors command supports `--log-file` parameter with both log locations
- [ ] Test suite cleanup automated in test_error_logging.sh
- [ ] All documentation written in present tense without historical markers

## Technical Design

### Architecture Overview

**Single-Point Implementation**: All changes localized to `log_command_error()` function with automatic context detection. Function signature unchanged, implementation enhanced.

**Context Detection Algorithm**:
```bash
# Inside log_command_error(), after parameter extraction
local environment="production"

# Check BASH_SOURCE for test script indicators
if [[ "${BASH_SOURCE[2]:-}" =~ /tests/ ]] || [[ "$0" =~ /tests/ ]]; then
  environment="test"
fi

# Route to appropriate log file
if [ "$environment" = "test" ]; then
  ERROR_LOG_FILE="${CLAUDE_PROJECT_DIR}/.claude/tests/logs/test-errors.jsonl"
else
  ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.jsonl"
fi
```

**Detection Logic Rationale**:
- BASH_SOURCE[2]: Inspects call stack (caller of caller of log_command_error)
- Pattern `/tests/`: Matches test directory structure
- Fallback to $0: Catches direct script execution
- Default to production: Unknown contexts route to production log (safe default)
- Coverage: 99%+ of test suite patterns

**Schema Enhancement**: Add `environment` field to JSONL for self-documenting entries.

**Before**:
```json
{
  "timestamp": "2025-11-20T15:30:45Z",
  "command": "/build",
  "workflow_id": "build_123",
  "error_type": "state_error",
  "error_message": "State file not found",
  "context": {}
}
```

**After**:
```json
{
  "timestamp": "2025-11-20T15:30:45Z",
  "environment": "production",
  "command": "/build",
  "workflow_id": "build_123",
  "error_type": "state_error",
  "error_message": "State file not found",
  "context": {}
}
```

**Rotation Behavior**: Both logs use same 10MB/5 backup rotation policy. `rotate_error_log()` supports any log file path. No rotation code changes needed.

### Component Interactions

```
┌─────────────────────┐
│ log_command_error() │
└──────────┬──────────┘
           │
           ├─→ detect_execution_context()
           │   ├─→ inspect BASH_SOURCE[2]
           │   └─→ pattern match /tests/
           │
           ├─→ select_log_file(environment)
           │   ├─→ test → .claude/tests/logs/test-errors.jsonl
           │   └─→ production → .claude/data/logs/errors.jsonl
           │
           └─→ append_to_log(ERROR_LOG_FILE, environment)
               └─→ rotate_error_log(ERROR_LOG_FILE)
```

### Documentation Rewrite Locations

**Pattern Document** (.claude/docs/concepts/patterns/error-handling.md):
- Rewrite "Definition" section to describe log separation as native feature
- Describe automatic context detection as architectural behavior
- Show query examples for both logs as standard usage
- Use present tense throughout (not "add" or "update")

**API Reference** (.claude/docs/reference/library-api/error-handling.md):
- Document log_command_error() with current behavior (includes context detection)
- Describe environment field in schema
- Show examples of both production and test logging

**Architecture Standard** (.claude/docs/reference/architecture/error-handling.md):
- Rewrite Standard 17 to include log separation requirement
- Describe integration pattern showing environment-based routing
- Use single unified approach (not step numbering)

## Implementation Phases

### Phase 1: Implement Log Separation with Environment Field [COMPLETE]
dependencies: []

**Objective**: Automatically segregate test and production errors with environment field in schema.

**Complexity**: Low

Tasks:
- [x] Locate log_command_error() function in error-handling.sh (file: /home/benjamin/.config/.claude/lib/core/error-handling.sh, line 411)
- [x] Add environment detection logic after parameter extraction (line 420)
- [x] Implement BASH_SOURCE[2] inspection for /tests/ pattern
- [x] Add fallback check using $0 variable for direct script execution
- [x] Define ERROR_LOG_FILE variable based on environment
- [x] Route test errors to .claude/tests/logs/test-errors.jsonl
- [x] Route production errors to .claude/data/logs/errors.jsonl (default)
- [x] Create tests/logs/ directory if it doesn't exist
- [x] Add environment field to JSON entry construction (line 462)
- [x] Test with existing test suite: run test_error_logging.sh
- [x] Verify test-errors.jsonl created in tests/logs/ with environment field
- [x] Verify environment field present in all new entries

Testing:
```bash
# Run error logging test suite
/home/benjamin/.config/.claude/tests/test_error_logging.sh

# Verify test log created in correct location
test -f /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl && echo "✅ Test log in tests/logs/"

# Verify environment field in test entries
jq '.environment' /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl | grep -q "test" && echo "✅ Environment field present"

# Performance benchmark (should be < 1ms overhead)
time (for i in {1..100}; do
  source /home/benjamin/.config/.claude/lib/core/error-handling.sh
  log_command_error "/test" "wf" "args" "state_error" "msg" "src" '{}'
done)
```

**Expected Duration**: 30 minutes

### Phase 2: Rewrite Documentation to Current State [COMPLETE]
dependencies: [1]

**Objective**: Rewrite all error handling documentation to describe current architecture without historical markers.

**Complexity**: Low

Tasks:
- [x] Read error-handling.md pattern document (file: /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md)
- [x] Rewrite "Definition" section to describe environment-based log separation (line 11)
- [x] Rewrite "Rationale" section to explain test isolation (line 36)
- [x] Add examples showing queries for both production and test logs
- [x] Describe environment field in JSONL schema section
- [x] Read API reference document (file: /home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md)
- [x] Rewrite log_command_error() documentation to describe current behavior (line 68)
- [x] Document environment field as part of schema
- [x] Show examples with both test and production contexts
- [x] Read architecture standard document (file: /home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md)
- [x] Rewrite Standard 17 to include log separation requirement (line 219)
- [x] Describe integration pattern with environment-based routing
- [x] Use present tense throughout (no "add", "update", "new" language)
- [x] Validate all internal links using .claude/scripts/validate-links-quick.sh
- [x] Verify no temporal markers (New, Updated, Previously, etc.)

Testing:
```bash
# Validate documentation links
/home/benjamin/.config/.claude/scripts/validate-links-quick.sh

# Check for temporal markers (should find none)
grep -r -E "\((New|Old|Updated|Current)\)" /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md /home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md /home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md || echo "✅ No temporal markers"

# Check for temporal phrases (should find none)
grep -r -E "\b(previously|recently|now supports|used to|backward compatibility)\b" /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md /home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md /home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md || echo "✅ No temporal phrases"

# Verify present tense usage
grep -A 5 "environment" /home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md
```

**Expected Duration**: 45 minutes

### Phase 3: Add Query Support and Test Cleanup [COMPLETE]
dependencies: [1]

**Objective**: Extend /errors command to support test log queries and automate test log cleanup.

**Complexity**: Very Low

Tasks:
- [x] Read errors.md command file (file: /home/benjamin/.config/.claude/commands/errors.md)
- [x] Add --log-file parameter to argument parser
- [x] Default to errors.jsonl if --log-file not specified
- [x] Support both absolute and relative paths for --log-file
- [x] Pass log file parameter to query_errors() function call
- [x] Update errors-command-guide.md with --log-file examples (file: /home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md)
- [x] Show example: /errors --log-file .claude/tests/logs/test-errors.jsonl --limit 10
- [x] Show example: /errors --summary (production log)
- [x] Read test_error_logging.sh file (file: /home/benjamin/.config/.claude/tests/test_error_logging.sh)
- [x] Add cleanup at end of test suite: rm -f .claude/tests/logs/test-errors.jsonl
- [x] Verify cleanup executes after test completion
- [x] Test querying test log with various filters
- [x] Test default behavior (errors.jsonl) unchanged

Testing:
```bash
# Query test log
/errors --log-file .claude/tests/logs/test-errors.jsonl --limit 5

# Query production log (default)
/errors --limit 5

# Summary for test log
/errors --log-file .claude/tests/logs/test-errors.jsonl --summary

# Verify cleanup works
/home/benjamin/.config/.claude/tests/test_error_logging.sh
test ! -f /home/benjamin/.config/.claude/tests/logs/test-errors.jsonl && echo "✅ Test log cleaned up"
```

**Expected Duration**: 15 minutes

## Testing Strategy

### Unit Testing

**Test Context Detection**:
- Create test cases with various BASH_SOURCE patterns
- Verify /tests/ pattern matches correctly
- Test fallback to $0 variable detection
- Verify default to production for unknown contexts
- Test edge cases (nested calls, sourced scripts)

**Test Log Routing**:
- Verify test errors go to tests/logs/test-errors.jsonl
- Verify production errors go to data/logs/errors.jsonl
- Test with mixed test/production error logging
- Verify environment field matches log location

**Test Schema Enhancement**:
- Verify environment field present in all new entries
- Test environment="test" for test context
- Test environment="production" for production context
- Verify schema remains valid JSONL

### Integration Testing

**Test Suite Integration**:
- Run complete test_error_logging.sh suite
- Verify all test errors in tests/logs/test-errors.jsonl
- Verify environment field = "test" for all entries
- Test cleanup behavior (teardown removes test log)

**Query Interface Testing**:
- Query tests/logs/test-errors.jsonl with /errors --log-file
- Query data/logs/errors.jsonl with default /errors
- Test all filter combinations on both logs
- Verify summary statistics for both logs

### Performance Testing

**Context Detection Overhead**:
- Benchmark log_command_error() with context detection
- Verify overhead < 1ms per call
- Test with high-volume logging (100+ errors)
- Verify no memory leaks or resource issues

### Test Coverage Requirements

- 100% coverage of context detection logic paths
- 100% coverage of log file selection logic
- 100% coverage of environment field assignment
- All documentation examples must be tested

## Documentation Requirements

### Files to Rewrite

**1. Error Handling Pattern** (/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md):
- Rewrite "Definition" section: describe environment-based log separation (line 11)
- Rewrite "Rationale" section: explain test isolation benefits
- Update JSONL schema examples to include environment field
- Show query examples for both logs as standard usage

**2. Library API Reference** (/home/benjamin/.config/.claude/docs/reference/library-api/error-handling.md):
- Rewrite log_command_error() documentation (line 68)
- Document current behavior (automatic context detection)
- Include environment field in schema documentation
- Show examples for both test and production contexts

**3. Architecture Standard 17** (/home/benjamin/.config/.claude/docs/reference/architecture/error-handling.md):
- Rewrite requirement statement to include log separation (line 219)
- Describe integration pattern with environment routing
- Use present tense throughout
- Show single unified approach

**4. Errors Command Guide** (/home/benjamin/.config/.claude/docs/guides/commands/errors-command-guide.md):
- Add --log-file parameter documentation
- Show examples querying both logs
- Document default behavior (production log)

### Writing Standards Compliance

**Present-Focused Language**:
- Use "The system logs errors to environment-specific files" (not "The system now logs...")
- Use "Commands integrate error logging via log_command_error()" (not "Commands should integrate...")
- Describe current architecture as if it always existed

**Banned Patterns to Avoid**:
- No temporal markers: (New), (Updated), (Current)
- No temporal phrases: "previously", "recently", "now supports"
- No migration language: "backward compatibility", "breaking change"
- No version references: "added in v2.0", "since version"

**Rewriting Approach**:
- Remove all historical context from functional documentation
- Focus on what the system does (not how it changed)
- Use present tense exclusively
- Eliminate comparison to previous implementations

## Dependencies

### External Dependencies
- jq (JSON processing) - already available
- bash 4.0+ (for BASH_SOURCE array) - already available
- Standard UNIX utilities (grep, test) - already available

### Internal Dependencies
- error-handling.sh library (exists, will be modified)
- test_error_logging.sh test suite (exists, will be updated)
- /errors command (exists, will be enhanced)
- Documentation files (exist, will be rewritten)

### Prerequisite Verification
All dependencies verified present in research phase. No installations or configuration changes required.

## Risk Mitigation

### Risk 1: False Positive Test Detection
- **Probability**: Low
- **Impact**: Test errors logged to production log (pollution continues)
- **Mitigation**: BASH_SOURCE inspection covers 99%+ of test patterns
- **Validation**: Manual review of .claude/tests/ directory structure
- **Fallback**: Errors still logged (to wrong file), no data loss

### Risk 2: Test Directory Structure Change
- **Probability**: Very Low
- **Impact**: Test detection fails if tests moved outside /tests/
- **Mitigation**: Follow established convention (tests in .claude/tests/)
- **Validation**: Code review confirms test location standards
- **Recovery**: Update detection pattern if directory structure changes

### Risk 3: Performance Degradation
- **Probability**: Very Low
- **Impact**: Logging becomes slower, affects all error logging
- **Mitigation**: Simple string pattern match (< 1ms overhead)
- **Validation**: Benchmark before/after modification
- **Threshold**: Abort if overhead > 5ms per call

## Notes

- Phase dependencies are sequential (each builds on previous)
- Complexity score of 18.5 keeps this as single-file plan (Tier 1)
- Clean-break approach eliminates compatibility complexity
- Documentation rewritten rather than patched for clarity
- Environment field enables future use cases (staging, CI, etc.)
- Test logs placed in tests/ directory where test artifacts belong
- Zero production code affected (no commands use log_command_error() yet)
- Implementation time: 1h 30min vs 8h (original Plan 841) = 81% time savings
- Follows writing standards: no historical markers, present tense, clean slate

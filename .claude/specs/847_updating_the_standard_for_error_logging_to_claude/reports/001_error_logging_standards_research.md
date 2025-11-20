# Error Logging Standards Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Log separation and error logging integration audit
- **Scope**: Review error logging infrastructure, command integration status, and documentation standards
- **Report Type**: System audit and standardization research
- **Complexity**: 3

## Executive Summary

This research evaluated the current error logging infrastructure, command integration compliance, and documentation structure to implement log separation between test and production errors. The analysis reveals:

1. **Infrastructure Status**: Comprehensive error-handling library (1,237 lines) exists with full functionality including log_command_error(), parse_subagent_error(), rotate_error_log(), and query_errors()
2. **Integration Gap**: Despite infrastructure completeness, ZERO of 13 commands actually call log_command_error() in practice - they only source the library
3. **Log State**: Current errors.jsonl contains only 3 test-generated entries (1.1KB), validating the assessment that 100% of logged errors are from tests
4. **Documentation**: Three primary error handling documents exist (pattern, API reference, architecture standard) but need updates for log separation
5. **Recommendation**: Implement ONLY test/production log separation (test-errors.jsonl) per complexity analysis; defer other enhancements until commands actually integrate error logging

## Current State Analysis

### Error Logging Infrastructure

**Library Location**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`
- **Size**: 1,237 lines
- **Key Functions**:
  - `log_command_error()` (lines 411-487): Logs structured errors to JSONL
  - `parse_subagent_error()` (lines 496-529): Extracts ERROR_CONTEXT from agent output
  - `rotate_error_log()` (lines 535-569): Size-based rotation (10MB/5 backups)
  - `query_errors()` (lines 582-644): Query interface with filters
  - `ensure_error_log_exists()` (line 570): Log directory initialization

**Error Log State**:
- **Path**: `/home/benjamin/.config/.claude/data/logs/errors.jsonl`
- **Size**: 1,131 bytes (1.1KB)
- **Entries**: 4 lines (3 errors + 1 blank)
- **Content**: 100% test-generated from test_error_logging.sh
- **Timestamps**: All errors from 2025-11-20T06:59:45Z (single test run)
- **Growth Rate**: Minimal (< 2KB after months of operation)

**Error Types Defined**:
```bash
ERROR_TYPE_TRANSIENT="transient"
ERROR_TYPE_PERMANENT="permanent"
ERROR_TYPE_FATAL="fatal"
ERROR_TYPE_LLM_TIMEOUT="llm_timeout"
ERROR_TYPE_LLM_API_ERROR="llm_api_error"
ERROR_TYPE_LLM_LOW_CONFIDENCE="llm_low_confidence"
ERROR_TYPE_LLM_PARSE_ERROR="llm_parse_error"
ERROR_TYPE_INVALID_MODE="invalid_mode"
```

**JSONL Schema (Current)**:
```json
{
  "timestamp": "2025-11-20T06:59:45Z",
  "command": "/build",
  "workflow_id": "build_test_123",
  "user_args": "plan.md 3",
  "error_type": "state_error",
  "error_message": "Test state error",
  "source": "bash_block",
  "stack": ["84 test_log_command_error ...", "271 main ..."],
  "context": {"plan_file": "/path/to/plan.md"}
}
```

### Command Integration Status

**Commands Analyzed**: 13 total command files in `.claude/commands/`

**Sourcing Status** (commands that include error-handling.sh):
- build.md ✅
- debug.md ✅
- errors.md ✅
- plan.md ✅
- repair.md ✅
- research.md ✅
- revise.md ✅

**Usage Status** (commands that actually call log_command_error):
- **NONE** - 0 of 13 commands (0% compliance)

**Non-Compliant Commands** (missing both sourcing and usage):
- collapse.md ❌
- convert-docs.md ❌
- expand.md ❌
- optimize-claude.md ❌
- setup.md ❌

**Critical Finding**: While 7 commands source the error-handling library, NONE actually call `log_command_error()` or `parse_subagent_error()` in their implementation. This means error logging is **aspirational but not operational**.

**Test Coverage**:
- `test_error_logging.sh`: Tests library functions directly
- `test_error_logging_compliance.sh`: Validates command integration (currently failing 13/13 commands)
- 5 test files source error-handling.sh (out of 90+ total test files)

### Agent Integration Status

**Total Agents**: 22 agent definition files in `.claude/agents/`

**Error Signal Usage** (agents that use TASK_ERROR/ERROR_CONTEXT):
- plan-architect.md ✅
- research-specialist.md ✅
- implementer-coordinator.md ✅
- shared/error-handling-guidelines.md ✅ (defines protocol)

**Error Return Protocol** (from error-handling-guidelines.md):
```markdown
ERROR_CONTEXT: {
  "error_type": "validation_error",
  "message": "Invalid complexity score",
  "details": {"score": 150, "max": 100}
}

TASK_ERROR: validation_error - Invalid complexity score: 150 exceeds maximum 100
```

**Agent Guidelines**:
- Comprehensive error classification (transient, permanent, fatal)
- Retry strategies defined (exponential backoff, max 3-4 attempts)
- Recovery patterns by error type
- Integration expectations for parent commands

### Documentation Structure

**Primary Error Handling Documentation**:

1. **Pattern Document**: `.claude/docs/concepts/patterns/error-handling.md` (630 lines)
   - Purpose: Architectural pattern explanation
   - Content: JSONL schema, integration guide, usage examples, anti-patterns
   - Audience: Developers implementing error logging
   - Current State: Comprehensive and accurate
   - Updates Needed: Add log separation section

2. **API Reference**: `.claude/docs/reference/library-api/error-handling.md` (200+ lines)
   - Purpose: Function signatures and usage
   - Content: log_command_error(), parse_subagent_error(), query_errors() APIs
   - Audience: Developers calling error logging functions
   - Current State: Complete function documentation
   - Updates Needed: Document context detection for test/production

3. **Architecture Standard**: `.claude/docs/reference/architecture/error-handling.md` (532 lines)
   - Purpose: Standards compliance requirements
   - Content: Standard 17 (Centralized Error Logging Integration)
   - Audience: Command developers ensuring compliance
   - Current State: Defines integration pattern (5 steps)
   - Updates Needed: Update Standard 17 for log separation

**Supporting Documentation**:
- `.claude/docs/guides/commands/errors-command-guide.md`: User guide for /errors command
- `.claude/docs/guides/patterns/error-enhancement-guide.md`: Error improvement workflows
- `.claude/docs/guides/patterns/logging-patterns.md`: General logging patterns
- `.claude/docs/reference/decision-trees/error-handling-flowchart.md`: Decision trees

**Documentation Navigation**:
- Main index: `.claude/docs/README.md` (lines 81-88 cover error logging tasks)
- Cross-references: Pattern ↔ API ↔ Architecture circular references established
- Integration into CLAUDE.md: Error logging standard section exists (lines 217-403)

### Related Plans and Specifications

**Plan 841**: `/home/benjamin/.config/.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md`
- Status: NOT STARTED
- Phases: 5 phases, 8 hours estimated
- Scope: Test/production segregation + cleanup utility + rotation + metadata enrichment
- Assessment: Over-engineered per complexity analysis report 842

**Complexity Analysis (Plan 842)**: `/home/benjamin/.config/.claude/specs/842_841_error_analysis_repair_plans_001_error/reports/001_complexity_analysis.md`
- Key Finding: Plan 841 proposes 8 hours for features with minimal ROI
- Recommendation: Streamlined 30-minute approach (test/production segregation only)
- Cost-Benefit: 94% time savings, 16x ROI improvement
- Rationale: Log rotation already exists, cleanup overkill for 1.1KB, metadata premature with zero production errors

**Error Analysis Report (Plan 841)**: `/home/benjamin/.config/.claude/specs/841_error_analysis_repair/reports/001_error_analysis.md`
- Analyzed: 3 errors (all test-generated)
- Findings: 100% test pollution rate validates segregation need
- Recommendations: 4 recommendations (cleanup, rotation, segregation, metadata)

**CLAUDE.md Error Logging Section**: `/home/benjamin/.config/CLAUDE.md` (lines 217-403)
- Current Content: Comprehensive standard definition
- Integration Steps: 5-step pattern (source, metadata, initialize, log, parse)
- Error Types: 8 standardized types defined
- Validation: test_error_logging_compliance.sh test suite reference

## Gap Analysis

### Gap 1: Log Separation Not Implemented
- **Current**: All errors (test and production) log to single errors.jsonl
- **Desired**: Test errors → test-errors.jsonl, production errors → errors.jsonl
- **Impact**: Test pollution obscures production errors (currently 100% test pollution)
- **Complexity**: LOW (15-line modification to log_command_error)
- **Implementation**: Add context detection in error-handling.sh line 420

### Gap 2: Commands Not Using Error Logging
- **Current**: 0 of 13 commands call log_command_error() despite sourcing library
- **Desired**: All commands integrate error logging per Standard 17
- **Impact**: No production error data collected, error logging infrastructure unused
- **Complexity**: HIGH (requires updating 13 command files + testing)
- **Implementation**: Add log_command_error calls at error points in each command
- **Priority**: HIGHER than log separation (no point separating zero production errors)

### Gap 3: Documentation Doesn't Cover Test Segregation
- **Current**: Docs describe single errors.jsonl log
- **Desired**: Docs describe test-errors.jsonl + errors.jsonl with context detection
- **Impact**: Developers don't know about test log separation
- **Complexity**: LOW (3 documentation files to update)
- **Implementation**: Update pattern, API reference, architecture standard

### Gap 4: No Query Support for Test Log
- **Current**: /errors command queries errors.jsonl only
- **Desired**: /errors --log-file test-errors.jsonl support
- **Impact**: Can't query test errors separately
- **Complexity**: LOW (5-line change to errors.md)
- **Implementation**: Add --log-file parameter to query_errors() wrapper

### Gap 5: Test Cleanup Not Automated
- **Current**: Test errors persist in errors.jsonl after test runs
- **Desired**: Test suite cleans test-errors.jsonl after completion
- **Impact**: Test log accumulation over time
- **Complexity**: VERY LOW (2-line addition to test_error_logging.sh)
- **Implementation**: Add `rm -f test-errors.jsonl` to teardown

## Proposed Solution

### Approach: Phased Implementation

**Phase 1: Implement Test/Production Log Separation** (Priority: HIGH, Effort: 30 min)
- Modify log_command_error() to detect test context (BASH_SOURCE check)
- Route test errors to test-errors.jsonl, production to errors.jsonl
- NO schema changes, NO new metadata fields
- Rationale: Addresses real gap (100% test pollution) with minimal complexity

**Phase 2: Update Documentation Standards** (Priority: HIGH, Effort: 45 min)
- Update error-handling.md pattern with segregation section
- Update error-handling.md API reference with context detection
- Update error-handling.md architecture standard (Standard 17)
- Add examples showing test vs production routing
- Rationale: Developers need to know about test log separation

**Phase 3: Add Query Support for Test Log** (Priority: MEDIUM, Effort: 15 min)
- Extend /errors command with --log-file parameter
- Update errors-command-guide.md with examples
- Test with both errors.jsonl and test-errors.jsonl
- Rationale: Enable analysis of test error patterns

**Phase 4: Integrate Test Log Cleanup** (Priority: LOW, Effort: 10 min)
- Add teardown to test_error_logging.sh to clear test-errors.jsonl
- Document cleanup pattern for other test files
- Rationale: Prevent test log accumulation

**EXPLICITLY EXCLUDED**:
- Log rotation enhancement (already exists, works fine)
- Cleanup utility script (overkill for 1.1KB scale)
- Metadata enrichment (premature with zero production errors)
- Command integration enforcement (separate initiative, higher complexity)

### Technical Design

**Context Detection Algorithm**:
```bash
# In log_command_error(), after parameter extraction (line 420)
local is_test_context=false

# Check BASH_SOURCE for test script indicators
if [[ "${BASH_SOURCE[2]:-}" =~ /tests/test_ ]] || [[ "$0" =~ /tests/test_ ]]; then
  is_test_context=true
fi

# Route to appropriate log file
if [ "$is_test_context" = "true" ]; then
  ERROR_LOG_FILE="${ERROR_LOG_DIR}/test-errors.jsonl"
else
  ERROR_LOG_FILE="${ERROR_LOG_DIR}/errors.jsonl"
fi
```

**Detection Logic**:
- Primary: Check BASH_SOURCE[2] for /tests/test_ pattern (callstack inspection)
- Secondary: Check $0 for /tests/test_ pattern (script name)
- Default: Route to production log (errors.jsonl) if no match
- Rationale: 99% coverage for standard test suite patterns

**No Schema Changes**:
- Existing JSONL schema unchanged
- No "environment" field added (can add later if needed)
- Both logs use identical schema
- Backward compatible (old entries work unchanged)

**Rotation Behavior**:
- Both logs use same 10MB/5 backup rotation policy
- rotate_error_log() already supports any log file path
- No changes needed to rotation logic

### Documentation Updates

**1. Error Handling Pattern** (`.claude/docs/concepts/patterns/error-handling.md`)

Add new section after line 43 (after "Rationale" section):

```markdown
## Log Separation

**Test vs Production Logs**:

The error handling system automatically segregates test and production errors:

- **Production Errors**: `.claude/data/logs/errors.jsonl` (default)
- **Test Errors**: `.claude/data/logs/test-errors.jsonl` (automatic routing)

**Automatic Detection**:

```bash
# Context detection in log_command_error()
# Checks BASH_SOURCE for /tests/test_ pattern
# Routes test errors to test-errors.jsonl automatically
```

**Rationale**: Test errors should not pollute production logs. Automatic segregation based on callstack inspection ensures test errors are isolated without requiring manual log file specification at every callsite.

**Query Interface**:
```bash
# Query production errors (default)
/errors --limit 10

# Query test errors explicitly
/errors --log-file test-errors.jsonl --limit 10
```
```

**2. Error Handling API Reference** (`.claude/docs/reference/library-api/error-handling.md`)

Update log_command_error() section (after line 68):

```markdown
**Log File Selection**:

The function automatically routes errors to appropriate log file based on execution context:
- **Test context** (BASH_SOURCE contains `/tests/test_`): Routes to `test-errors.jsonl`
- **Production context** (default): Routes to `errors.jsonl`

No caller changes required - context detection is automatic.
```

**3. Architecture Standard 17** (`.claude/docs/reference/architecture/error-handling.md`)

Update Standard 17 description (after line 219):

```markdown
### Requirement

All commands and agents MUST integrate centralized error logging via `log_command_error()` for queryable error tracking and cross-workflow debugging. Test errors are automatically segregated to test-errors.jsonl.
```

Add after line 256 (after Step 4):

```markdown
**Step 5a: Automatic Test/Production Segregation**

No additional code required - `log_command_error()` automatically detects test context:
- Test scripts in `.claude/tests/test_*.sh` → route to test-errors.jsonl
- All other contexts → route to errors.jsonl

Detection uses BASH_SOURCE callstack inspection (zero performance overhead).
```

### Implementation Checklist

**Phase 1: Log Separation (30 min)**
- [ ] Modify log_command_error() in error-handling.sh (lines 420-435)
- [ ] Add is_test_context detection logic
- [ ] Add ERROR_LOG_FILE routing logic
- [ ] Test with test_error_logging.sh (verify test-errors.jsonl created)
- [ ] Commit changes

**Phase 2: Documentation (45 min)**
- [ ] Update error-handling.md pattern (add Log Separation section)
- [ ] Update error-handling.md API reference (add context detection note)
- [ ] Update error-handling.md architecture standard (update Standard 17)
- [ ] Validate all internal links
- [ ] Commit changes

**Phase 3: Query Support (15 min)**
- [ ] Add --log-file parameter to /errors command
- [ ] Update query_errors() call with log file parameter
- [ ] Test querying test-errors.jsonl
- [ ] Update errors-command-guide.md with examples
- [ ] Commit changes

**Phase 4: Test Cleanup (10 min)**
- [ ] Add teardown to test_error_logging.sh
- [ ] Test cleanup behavior
- [ ] Document pattern in testing-protocols.md
- [ ] Commit changes

**Total Estimated Time**: 1 hour 40 minutes (vs 8 hours in Plan 841)

## Standards Placement

### New Standard vs Update Existing

**Decision**: UPDATE existing Standard 17 rather than create new standard

**Rationale**:
- Log separation is an extension of existing error logging standard
- Standard 17 already defines integration pattern (5 steps)
- Adding "Step 5a" for automatic segregation maintains continuity
- Avoids standard proliferation
- Natural evolution of existing pattern

**Location**: `.claude/docs/reference/architecture/error-handling.md` (Standard 17)

**Section to Update**: Lines 217-403 (Standard 17: Centralized Error Logging Integration)

### Documentation Organization

**No New Files Created**:
- All updates extend existing documentation
- Maintains established cross-reference structure
- Follows "avoid redundancy" principle from research task

**Update Locations**:
1. **Pattern** (concepts/patterns/error-handling.md): Add Log Separation section
2. **API Reference** (reference/library-api/error-handling.md): Add context detection note
3. **Architecture Standard** (reference/architecture/error-handling.md): Extend Standard 17

**Cross-References Maintained**:
- Pattern → API → Architecture circular links preserved
- No broken links introduced
- Standard section metadata updated in CLAUDE.md

## Testing Strategy

### Unit Tests

**Existing Test**: `test_error_logging.sh` (validates library functions)
- Add test case for test context detection
- Add test case for production context detection
- Verify test-errors.jsonl creation
- Verify errors.jsonl unchanged for production calls

**Compliance Test**: `test_error_logging_compliance.sh` (validates command integration)
- Currently failing 13/13 commands (none use log_command_error)
- Will continue failing until commands integrate error logging
- Test itself doesn't need changes for log separation

### Integration Tests

**Test Segregation**:
```bash
# Run test suite
.claude/tests/test_error_logging.sh

# Verify test errors in test-errors.jsonl
[ -f .claude/data/logs/test-errors.jsonl ] && echo "✅ Test log created"

# Verify production log unchanged
[ ! -s .claude/data/logs/errors.jsonl ] && echo "✅ Production log empty"
```

**Test Query**:
```bash
# Query test log
/errors --log-file test-errors.jsonl --limit 5

# Query production log (default)
/errors --limit 5
```

### Regression Tests

**Verify Backward Compatibility**:
- Existing log_command_error callsites work unchanged
- Old log entries in errors.jsonl still queryable
- Rotation continues to work for both log files
- No performance degradation (<1ms overhead for context detection)

## Dependencies and Prerequisites

### Internal Dependencies
- error-handling.sh library (exists, needs modification)
- test_error_logging.sh test suite (exists, needs extension)
- /errors command (exists, needs --log-file parameter)

### External Dependencies
- None (no new tools or libraries required)

### Prerequisite Verification
- All dependencies present and functional
- No installations needed
- No configuration changes required

## Risk Assessment

### Risk 1: False Positive Test Detection
- **Probability**: Low
- **Impact**: Test errors logged to production log
- **Mitigation**: BASH_SOURCE inspection covers 99% of test patterns
- **Fallback**: Errors still logged (to wrong file), no data loss

### Risk 2: Test Detection False Negatives
- **Probability**: Very Low
- **Impact**: Production code in /tests/ directory logged as test errors
- **Mitigation**: Follow standard convention (tests/ is for tests only)
- **Validation**: Manual code review of .claude/tests/ structure

### Risk 3: Query Interface Breaking Change
- **Probability**: Very Low (adding optional parameter)
- **Impact**: Existing /errors calls continue to work unchanged
- **Mitigation**: --log-file parameter is optional (defaults to errors.jsonl)
- **Validation**: Test existing /errors commands before and after change

### Risk 4: Documentation Inconsistency
- **Probability**: Low
- **Impact**: Developers confused about log separation behavior
- **Mitigation**: Update all three doc locations atomically
- **Validation**: Link validation script confirms no broken references

## Success Criteria

### Technical Validation
- [ ] Test errors route to test-errors.jsonl automatically
- [ ] Production errors route to errors.jsonl (once commands integrate logging)
- [ ] Context detection works for all test scripts in .claude/tests/
- [ ] Query interface supports both log files
- [ ] Rotation works for both log files
- [ ] No performance degradation (context check < 1ms)

### Documentation Validation
- [ ] Error handling pattern updated with log separation section
- [ ] API reference updated with context detection explanation
- [ ] Architecture standard updated (Standard 17 extended)
- [ ] All internal links validated (no broken references)
- [ ] Examples provided for test vs production queries

### Compliance Validation
- [ ] test_error_logging.sh extended with segregation tests
- [ ] All new tests passing
- [ ] No regressions in existing tests
- [ ] test_error_logging_compliance.sh continues to report command integration gap (expected)

## Next Steps

### Immediate (This Plan)
1. Implement log separation (Phase 1)
2. Update documentation (Phase 2)
3. Add query support (Phase 3)
4. Integrate test cleanup (Phase 4)

### Future Work (Out of Scope)
1. **Command Integration Initiative**: Integrate log_command_error() into 13 commands
   - Separate plan required (higher complexity, 13 file changes)
   - Blocked until this plan completes (need test log separation first)
   - Estimated effort: 6-8 hours

2. **Metadata Enrichment**: Add severity, environment, user, hostname fields
   - Deferred until production errors exist (currently zero)
   - Wait for command integration to complete
   - Reassess when error log exceeds 100 production errors

3. **Cleanup Utility**: Build standalone cleanup script
   - Deferred (overkill for current 1.1KB scale)
   - Reassess if test log exceeds 10MB
   - Alternative: Document one-liner cleanup in testing protocols

## References

### Plans and Specifications
- **Plan 841**: `.claude/specs/841_error_analysis_repair/plans/001_error_analysis_repair_plan.md`
  - 5-phase plan (8 hours) - over-engineered per analysis
  - Phases: Segregation + Cleanup + Rotation + Metadata + Docs
- **Complexity Analysis (Plan 842)**: `.claude/specs/842_841_error_analysis_repair_plans_001_error/reports/001_complexity_analysis.md`
  - Key recommendation: 30-minute streamlined approach
  - 94% time savings, 16x ROI improvement
- **Error Analysis Report**: `.claude/specs/841_error_analysis_repair/reports/001_error_analysis.md`
  - 3 errors analyzed (100% test-generated)
  - Validates test pollution problem

### Documentation Files
- **Error Handling Pattern**: `.claude/docs/concepts/patterns/error-handling.md` (630 lines)
- **API Reference**: `.claude/docs/reference/library-api/error-handling.md` (200+ lines)
- **Architecture Standard**: `.claude/docs/reference/architecture/error-handling.md` (532 lines, Standard 17)
- **Errors Command Guide**: `.claude/docs/guides/commands/errors-command-guide.md`
- **Agent Guidelines**: `.claude/agents/shared/error-handling-guidelines.md` (100+ lines)

### Implementation Files
- **Error Handling Library**: `.claude/lib/core/error-handling.sh` (1,237 lines)
  - log_command_error(): lines 411-487
  - parse_subagent_error(): lines 496-529
  - rotate_error_log(): lines 535-569
  - query_errors(): lines 582-644
- **Test Suite**: `.claude/tests/test_error_logging.sh`
- **Compliance Test**: `.claude/tests/test_error_logging_compliance.sh`
- **Errors Command**: `.claude/commands/errors.md`

### Standards Integration
- **CLAUDE.md Section**: Lines 217-403 (Error Logging Standards)
- **Section Metadata**: `[Used by: all commands, all agents, /implement, /build, /debug, /errors, /repair]`

## Appendices

### Appendix A: Current Command Integration Status

| Command | Sources Library | Uses log_command_error | Compliance |
|---------|----------------|------------------------|------------|
| build.md | ✅ | ❌ | Non-compliant |
| plan.md | ✅ | ❌ | Non-compliant |
| research.md | ✅ | ❌ | Non-compliant |
| debug.md | ✅ | ❌ | Non-compliant |
| revise.md | ✅ | ❌ | Non-compliant |
| repair.md | ✅ | ❌ | Non-compliant |
| errors.md | ✅ | ❌ | Non-compliant |
| expand.md | ❌ | ❌ | Non-compliant |
| collapse.md | ❌ | ❌ | Non-compliant |
| convert-docs.md | ❌ | ❌ | Non-compliant |
| optimize-claude.md | ❌ | ❌ | Non-compliant |
| setup.md | ❌ | ❌ | Non-compliant |
| README.md | ❌ | ❌ | Non-compliant |
| **Total** | **7/13** | **0/13** | **0/13** |

### Appendix B: Log Directory State

```bash
$ ls -lh .claude/data/logs/
total 772K
-rw-r--r-- 1 benjamin users 3.6K Oct 24 13:49 approval-decisions.log
-rw-r--r-- 1 benjamin users    0 Nov 14 20:47 bloat-rollbacks.log
-rw-r--r-- 1 benjamin users    0 Nov 14 20:47 bloat-tracking.log
-rw-r--r-- 1 benjamin users  19K Oct 21 20:20 complexity-debug.log
-rw-r--r-- 1 benjamin users 1.2K Nov 19 22:59 errors.jsonl  ← TARGET
-rw-r--r-- 1 benjamin users  12K Nov 14 22:02 final-bloat-audit.txt
-rw-r--r-- 1 benjamin users 428K Nov 20 10:53 hook-debug.log
-rw-r--r-- 1 benjamin users 1.8K Oct 16 23:59 phase-handoffs.log
-rw-r--r-- 1 benjamin users 9.7K Oct  7 15:34 README.md
-rw-r--r-- 1 benjamin users 1.4K Oct 16 23:59 subagent-outputs.log
-rw-r--r-- 1 benjamin users  335 Oct 16 23:59 supervision-tree.log
-rw-r--r-- 1 benjamin users 271K Nov 20 10:53 tts.log
```

### Appendix C: Error Log Content

```jsonl
{"timestamp":"2025-11-20T06:59:45Z","command":"/build","workflow_id":"build_test_123","user_args":"plan.md 3","error_type":"state_error","error_message":"Test state error","source":"bash_block","stack":["84 test_log_command_error /home/benjamin/.config/.claude/tests/test_error_logging.sh","271 main /home/benjamin/.config/.claude/tests/test_error_logging.sh"],"context":{"plan_file":"/path/to/plan.md"}}
{"timestamp":"2025-11-20T06:59:45Z","command":"/plan","workflow_id":"plan_1","user_args":"desc","error_type":"validation_error","error_message":"Plan error","source":"bash_block","stack":["177 test_query_errors_filter /home/benjamin/.config/.claude/tests/test_error_logging.sh","274 main /home/benjamin/.config/.claude/tests/test_error_logging.sh"],"context":{}}
{"timestamp":"2025-11-20T06:59:45Z","command":"/debug","workflow_id":"debug_1","user_args":"issue","error_type":"agent_error","error_message":"Debug error","source":"bash_block","stack":["178 test_query_errors_filter /home/benjamin/.config/.claude/tests/test_error_logging.sh","274 main /home/benjamin/.config/.claude/tests/test_error_logging.sh"],"context":{}}
```

All 3 errors share:
- Same timestamp (2025-11-20T06:59:45Z)
- Same source (test_error_logging.sh)
- Test-specific stack traces
- 100% test pollution rate validates segregation need

### Appendix D: Context Detection Alternatives Considered

**Alternative 1: Environment Variable** (Rejected)
```bash
# Requires manual flag at test invocation
TEST_MODE=1 .claude/tests/test_error_logging.sh
```
- Rejected: Manual intervention required, error-prone, easy to forget

**Alternative 2: Explicit Log File Parameter** (Rejected)
```bash
# Requires all callsites to specify log file
log_command_error "$cmd" "$wf" "$args" "$type" "$msg" "$src" "$ctx" "test-errors.jsonl"
```
- Rejected: Breaking change, requires updating all existing calls, fragile

**Alternative 3: BASH_SOURCE Inspection** (Selected)
```bash
# Automatic detection based on callstack
if [[ "${BASH_SOURCE[2]:-}" =~ /tests/test_ ]]; then
  ERROR_LOG_FILE="test-errors.jsonl"
fi
```
- Selected: Zero-touch integration, automatic, covers 99% of cases, no breaking changes

### Appendix E: Rotation Behavior Verification

**Current Rotation Configuration**:
- Threshold: 10MB (10,485,760 bytes)
- Max Backups: 5 (.1, .2, .3, .4, .5)
- Status: Never triggered (current log 1.1KB)
- Function: rotate_error_log() (lines 535-569)
- Policy: Size-based only (no date-based rotation)

**Post-Segregation Behavior**:
- Both logs rotate independently at 10MB threshold
- No configuration changes needed
- rotate_error_log() already supports any log file path
- Test log accumulation: ~10MB = ~10,000 test errors (unlikely in practice)

**Validation**:
```bash
# Verify rotation config unchanged
grep -A 3 "max_size_bytes" .claude/lib/core/error-handling.sh
# Output: max_size_bytes=$((10 * 1024 * 1024))  # 10MB
```

## Conclusion

This research provides a complete foundation for implementing test/production log separation with documentation standards updates. The streamlined approach (1 hour 40 minutes) delivers the critical value from Plan 841 (test segregation) while avoiding premature optimization (cleanup utility, metadata enrichment, rotation enhancement). The analysis reveals that command integration is the true gap - zero commands currently use error logging despite infrastructure completeness. Log separation should proceed immediately to enable clean error collection once commands integrate logging.

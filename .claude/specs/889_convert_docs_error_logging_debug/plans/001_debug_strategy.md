# /convert-docs Error Logging Debug Strategy

## Metadata
- **Date**: 2025-11-21
- **Workflow Type**: debug-only
- **Feature**: /convert-docs error logging integration and conversion error debugging
- **Scope**: Root cause analysis and systematic debugging of error logging gaps and conversion failures
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Complexity Score**: 47.0 (Base: 3 [fix], Tasks: 18/2=9.0, Files: 7*3=21, Integrations: 2*5=10)
- **Structure Level**: 0 (single file)
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Research Reports**:
  - [Root Cause Analysis](../reports/001_root_cause_analysis.md)

## Overview

The /convert-docs command has a critical infrastructure gap where errors occur during conversion but are not captured by the centralized error logging system, making the /errors command unable to detect failures. Additionally, the conversion test revealed actual execution errors (missing CLAUDE_PROJECT_DIR, bash conditional syntax errors) that expose fragility in the conversion infrastructure.

This debug strategy systematically addresses:
1. **Error Logging Gap**: Complete absence of error-handling.sh integration in /convert-docs command
2. **Delegation Model**: convert-core.sh library lacks error logging despite being the execution layer
3. **Environment Issues**: CLAUDE_PROJECT_DIR not defensively initialized, causing source failures
4. **Syntax Errors**: Incorrect bash conditional escaping (`\!` instead of `!` in `[[ ]]` tests)
5. **Documentation Gaps**: No guidance on error logging in delegation model commands

## Research Summary

Root cause analysis revealed multiple systemic issues:

**Error Logging Integration Gap**:
- /convert-docs command has zero error-handling.sh integration (no source, no log_command_error calls)
- Documentation mandates "all commands" integrate error logging but /convert-docs is non-compliant
- convert-core.sh (1313 lines) similarly lacks integration despite being primary execution layer
- /errors command cannot discover conversion failures, breaking documented error management workflow

**Actual Conversion Errors**:
- **Exit code 1**: Missing CLAUDE_PROJECT_DIR caused source failure (line 34 in output)
- **Exit code 2**: Bash syntax error from escaped negation operator `\!` in conditional (line 68 in output)
- Neither error logged to centralized error log, confirmed by /errors command returning zero results

**Architectural Pattern**:
- Command uses delegation model: coordinator → script/agent/skill
- Error logging responsibility unclear - coordinator assumes delegates handle it, but they don't
- No guidance in documentation for delegation model error logging integration

**Required Fixes**:
1. Integrate error-handling.sh into /convert-docs coordinator (STEP 1.5 addition)
2. Add conditional error logging to convert-core.sh library (backward compatible)
3. Implement defensive CLAUDE_PROJECT_DIR initialization (STEP 0.5 addition)
4. Fix bash conditional escaping bugs (search and replace `\!` patterns)
5. Document delegation model error logging pattern in standards

## Success Criteria

- [ ] /convert-docs command sources error-handling.sh and initializes error logging
- [ ] All critical error points in /convert-docs log to centralized error log with appropriate error types
- [ ] convert-core.sh conditionally integrates error logging when available
- [ ] CLAUDE_PROJECT_DIR is defensively initialized with fallback detection logic
- [ ] Bash conditional escaping bugs fixed (no `\!` patterns in `[[ ]]` tests)
- [ ] /errors command successfully queries /convert-docs errors after triggering known failures
- [ ] Test suite validates error logging integration for all failure modes
- [ ] Documentation updated with delegation model error logging pattern
- [ ] All fixes conform to existing .claude/docs/ standards or include rationale for revisions

## Technical Design

### Architecture: Coordinator Error Logging Pattern

The delegation model requires error logging at multiple layers:

```
/convert-docs.md (coordinator)
├─ Source error-handling.sh
├─ Initialize error log + metadata
├─ Export metadata to environment
└─ Delegate to:
   ├─ convert-core.sh (script mode)
   │  ├─ Conditionally source error-handling.sh
   │  ├─ Use exported metadata if available
   │  └─ Log conversion errors via wrapper function
   ├─ doc-converter agent (agent mode)
   │  └─ Return TASK_ERROR signals for coordinator to log
   └─ document-converter skill (skill mode)
      └─ Natural language delegation (error handling via Claude)
```

**Key Design Decisions**:

1. **Coordinator Responsibility**: /convert-docs owns error logging initialization and delegation boundary errors
2. **Conditional Integration**: convert-core.sh checks availability before logging (backward compatibility)
3. **Environment-Based Metadata**: Export COMMAND_NAME, WORKFLOW_ID, USER_ARGS for delegated scripts
4. **Graceful Degradation**: Libraries log only if error logging available, continue if not

### Error Logging Points

**Coordinator Level** (/convert-docs.md):
- Pre-delegation validation failures (invalid input directory)
- Script sourcing failures (CLAUDE_PROJECT_DIR issues)
- Conversion exit code failures (main_conversion returned non-zero)
- Agent invocation failures (Task tool errors)

**Library Level** (convert-core.sh):
- Input directory validation failures
- File conversion failures (per-file execution errors)
- Tool availability issues (markitdown/pandoc not found)
- Timeout violations (conversion exceeds time limit)

### Environment Initialization Strategy

Use unified-location-detection.sh pattern with fallback:

```bash
# STEP 0.5 in /convert-docs.md
if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]]; then
  source .claude/lib/core/unified-location-detection.sh 2>/dev/null || {
    CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  }

  if [[ -z "${CLAUDE_PROJECT_DIR:-}" ]] && type detect_project_directory &>/dev/null; then
    CLAUDE_PROJECT_DIR="$(detect_project_directory)"
  fi

  export CLAUDE_PROJECT_DIR
fi
```

### Bash Conditional Fix Pattern

Search for all `\!` patterns in `[[ ]]` conditionals and replace:

```bash
# Incorrect (causes exit code 2)
if [[ \! -f "$file" ]]; then

# Correct
if [[ ! -f "$file" ]]; then
```

## Implementation Phases

### Phase 1: Environment and Error Logging Setup [COMPLETE]
dependencies: []

**Objective**: Integrate error logging infrastructure into /convert-docs coordinator and fix environment initialization

**Complexity**: Medium

**Tasks**:
- [x] Add STEP 0.5 to /convert-docs.md: defensive CLAUDE_PROJECT_DIR initialization with unified-location-detection fallback (file: .claude/commands/convert-docs.md)
- [x] Add validation block to verify CLAUDE_PROJECT_DIR is set and valid before proceeding
- [x] Add STEP 1.5 to /convert-docs.md: source error-handling.sh library with error exit on failure (file: .claude/commands/convert-docs.md)
- [x] Add ensure_error_log_exists initialization call
- [x] Set workflow metadata: COMMAND_NAME="/convert-docs", WORKFLOW_ID="convert_docs_$(date +%s)", USER_ARGS="$*"
- [x] Export metadata to environment for delegated scripts: export COMMAND_NAME WORKFLOW_ID USER_ARGS
- [x] Add verification checkpoint confirming error logging initialized

**Testing**:
```bash
# Test CLAUDE_PROJECT_DIR initialization
unset CLAUDE_PROJECT_DIR
/convert-docs /tmp/test-dir 2>&1 | grep "VERIFIED: CLAUDE_PROJECT_DIR"

# Test error logging initialization
/convert-docs /tmp/test-dir 2>&1 | grep "VERIFIED: Error logging initialized"

# Verify metadata exported
/convert-docs /tmp/test-dir && echo $COMMAND_NAME
```

**Expected Duration**: 1.5 hours

### Phase 2: Coordinator Error Logging Integration [COMPLETE]
dependencies: [1]

**Objective**: Add log_command_error calls at all critical error points in /convert-docs coordinator

**Complexity**: Medium

**Tasks**:
- [x] Add validation_error logging for invalid input directory (file: .claude/commands/convert-docs.md, after input validation)
- [x] Add file_error logging for convert-core.sh source failure with context including lib_path (file: .claude/commands/convert-docs.md, STEP 4)
- [x] Add execution_error logging for main_conversion exit code failures with context including exit code, input_dir, output_dir (file: .claude/commands/convert-docs.md, after main_conversion call)
- [x] Add agent_error logging for Task tool invocation failures in agent mode (file: .claude/commands/convert-docs.md, agent mode block)
- [x] Verify all error logging calls include full context JSON for debugging
- [x] Test error logging by triggering each failure mode and checking errors.jsonl

**Testing**:
```bash
# Test validation error logging
/convert-docs /nonexistent/directory && grep "validation_error" .claude/data/logs/errors.jsonl

# Test source failure logging
unset CLAUDE_PROJECT_DIR && /convert-docs /tmp && grep "file_error.*convert-core.sh" .claude/data/logs/errors.jsonl

# Test conversion failure logging
/convert-docs /tmp/corrupted-files && grep "execution_error.*main_conversion" .claude/data/logs/errors.jsonl
```

**Expected Duration**: 2 hours

### Phase 3: Library Error Logging Integration [COMPLETE]
dependencies: [1]

**Objective**: Add conditional error logging to convert-core.sh library for conversion failures

**Complexity**: High

**Tasks**:
- [x] Add conditional error-handling.sh sourcing at top of convert-core.sh with silent failure fallback (file: .claude/lib/convert/convert-core.sh, after line 27)
- [x] Add conditional ensure_error_log_exists call if library loaded
- [x] Create log_conversion_error wrapper function that checks availability before logging (file: .claude/lib/convert/convert-core.sh)
- [x] Add validation_error logging for input directory not found failures (file: .claude/lib/convert/convert-core.sh, line ~1241)
- [x] Add execution_error logging for DOCX conversion failures with file context (file: .claude/lib/convert/convert-core.sh, line ~875)
- [x] Add execution_error logging for PDF conversion failures with file context (file: .claude/lib/convert/convert-core.sh, line ~934)
- [x] Add execution_error logging for markdown conversion failures with file context
- [x] Test backward compatibility: verify convert-core.sh works without error logging available
- [x] Test forward compatibility: verify errors logged when COMMAND_NAME metadata present

**Testing**:
```bash
# Test library error logging integration
export COMMAND_NAME="/convert-docs" WORKFLOW_ID="test_123" USER_ARGS="/tmp"
source .claude/lib/convert/convert-core.sh
# Trigger conversion failure and check errors.jsonl

# Test backward compatibility (no metadata)
unset COMMAND_NAME WORKFLOW_ID USER_ARGS
source .claude/lib/convert/convert-core.sh
# Should work without error logging

# Test graceful degradation (no error-handling.sh)
# Move error-handling.sh temporarily, verify no crashes
```

**Expected Duration**: 2.5 hours

### Phase 4: Bash Syntax Error Fixes [COMPLETE]
dependencies: [1]

**Objective**: Identify and fix all bash conditional escaping bugs causing exit code 2 errors

**Complexity**: Low

**Tasks**:
- [x] Search convert-core.sh for all `\!` patterns in conditionals using grep (file: .claude/lib/convert/convert-core.sh)
- [x] Search convert-markdown.sh for `\!` patterns (file: .claude/lib/convert/convert-markdown.sh)
- [x] Search convert-pdf.sh for `\!` patterns (file: .claude/lib/convert/convert-pdf.sh)
- [x] Search convert-docx.sh for `\!` patterns (file: .claude/lib/convert/convert-docx.sh)
- [x] Replace all `[[ \! -f` with `[[ ! -f` in all conversion libraries
- [x] Replace all `[[ \! -d` with `[[ ! -d` in all conversion libraries
- [x] Test each modified file for syntax errors using bash -n
- [x] Run conversion test to verify exit code 2 error is resolved

**Testing**:
```bash
# Syntax validation for all modified files
for file in convert-{core,markdown,pdf,docx}.sh; do
  bash -n ".claude/lib/convert/$file" || echo "SYNTAX ERROR: $file"
done

# Regression test: verify conversion completes without exit code 2
/convert-docs .claude/tmp/convert-test-original.md ./test-output 2>&1 | grep -c "exit code 2"
# Expected: 0 matches
```

**Expected Duration**: 1 hour

### Phase 5: Validation and Documentation [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Validate complete error logging integration and document delegation model pattern

**Complexity**: Medium

**Tasks**:
- [x] Create test suite for /convert-docs error logging at .claude/tests/features/commands/test_convert_docs_error_logging.sh
- [x] Implement test case: validation_error logged for invalid input directory
- [x] Implement test case: file_error logged for missing CLAUDE_PROJECT_DIR
- [x] Implement test case: execution_error logged for conversion failures
- [x] Implement test case: /errors command successfully queries logged errors with --command /convert-docs filter
- [x] Run full test suite and verify 100% pass rate
- [x] Create or update /home/benjamin/.config/.claude/docs/reference/standards/error-logging-standards.md with delegation model section
- [x] Add "Error Logging in Delegation Model Commands" section documenting coordinator and delegate responsibilities
- [x] Update CLAUDE.md error_logging section to reference new delegation model guidance
- [x] Run /convert-docs with known failure scenarios and verify /errors detects them

**Testing**:
```bash
# Run new test suite
bash .claude/tests/features/commands/test_convert_docs_error_logging.sh

# Integration test: error logging → /errors query workflow
rm -f .claude/data/logs/errors.jsonl  # Fresh start
/convert-docs /nonexistent && /errors --command /convert-docs --limit 5
# Expected: Shows validation_error for missing directory

# Validate documentation standards compliance
grep "Error Logging in Delegation Model" .claude/docs/reference/standards/error-logging-standards.md
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- Test CLAUDE_PROJECT_DIR initialization with various states (unset, invalid, valid)
- Test error logging initialization success and failure paths
- Test log_conversion_error wrapper with and without metadata available
- Test each error logging call produces valid JSONL entries

### Integration Testing
- Test complete /convert-docs → error → /errors workflow
- Test backward compatibility: convert-core.sh without error logging
- Test forward compatibility: full error logging integration
- Test error context includes all required fields (timestamp, command, workflow_id, error_type, message, source, context)

### Regression Testing
- Verify existing conversion functionality unchanged (MD→DOCX, DOCX→MD, MD→PDF, PDF→MD)
- Verify script mode and agent mode both log errors correctly
- Verify skill mode delegation continues working (no error logging expected)

### Error Injection Testing
- Trigger validation_error: provide invalid input directory
- Trigger file_error: unset CLAUDE_PROJECT_DIR before sourcing convert-core.sh
- Trigger execution_error: create corrupted files that fail conversion
- Trigger parse_error: test bash syntax validation catches escaping bugs

### Query Validation Testing
- Test /errors --command /convert-docs returns logged errors
- Test /errors --type validation_error filters correctly
- Test /errors --since 1h captures recent errors
- Test /errors --limit 10 respects result count

## Documentation Requirements

### Standards Documentation
Create or update `.claude/docs/reference/standards/error-logging-standards.md`:
- Add "Error Logging in Delegation Model Commands" section
- Document coordinator responsibilities (source, initialize, export metadata, log delegation boundaries)
- Document delegate responsibilities (conditional integration, graceful degradation)
- Provide example implementation for coordinator and delegate
- Document environment variable pattern (export COMMAND_NAME WORKFLOW_ID USER_ARGS)

### CLAUDE.md Updates
Update error_logging section:
- Add reference to delegation model documentation
- Note that delegation-model commands require special integration pattern
- Link to error-logging-standards.md for complete guidance

### Test Documentation
Document test suite in `.claude/tests/features/commands/test_convert_docs_error_logging.sh`:
- Add header comment explaining what is being tested
- Document each test case with clear assertions
- Provide examples of expected JSONL output format
- Note integration with /errors command workflow

### Command Documentation
Update /convert-docs.md if needed:
- Document error logging behavior in command description
- Note that errors are logged to centralized error log
- Reference /errors command for querying conversion failures

## Dependencies

### External Dependencies
- error-handling.sh library (already exists at .claude/lib/core/error-handling.sh)
- unified-location-detection.sh library (already exists at .claude/lib/core/unified-location-detection.sh)
- /errors command (already exists at .claude/commands/errors.md)
- errors-analyst agent (already exists at .claude/agents/errors-analyst.md)

### Internal Dependencies
- Phase 2 depends on Phase 1 (error logging must be initialized before logging calls)
- Phase 3 depends on Phase 1 (environment variables must be exported for library to use)
- Phase 5 depends on Phases 2, 3, 4 (all fixes must be complete before validation)

### Prerequisites
- Research report completed and analyzed (✓ completed)
- Test conversion output available for reference (✓ available at .claude/convert-docs-output.md)
- Error report showing gap confirmed (✓ available at specs/888_errors_command_test_report/reports/001_error_report.md)

## Compliance Notes

### Standards Conformance
This debug strategy follows:
- Error Logging Standards from CLAUDE.md (will bring /convert-docs into compliance)
- Directory Organization Standards (error logging library location, test location)
- Code Standards (bash style, function naming, error handling)
- Testing Protocols (test suite structure, naming conventions)
- Documentation Standards (markdown format, section structure)

### Potential Standards Revisions
If implementation reveals gaps in current standards:
- Document delegation model pattern in error-logging-standards.md (new content, not revision)
- Clarify "all commands" language to explicitly include delegation-model commands
- Add environment variable export pattern to error logging quick reference

### Integration with Existing Infrastructure
This fix integrates naturally with:
- /errors command (consumers of centralized error log)
- /repair command (uses error patterns to create fix plans)
- error-handling.sh library (error logging interface)
- errors-analyst agent (analyzes logged errors)
- Existing test infrastructure (add new test suite following established patterns)

## Risk Analysis

### Technical Risks
1. **Backward Compatibility**: convert-core.sh changes might break external scripts that source it
   - **Mitigation**: Conditional integration with graceful degradation
   - **Testing**: Verify library works with and without error logging available

2. **Performance Impact**: Error logging adds overhead to conversion loop
   - **Mitigation**: Minimal overhead (single function call, conditional execution)
   - **Testing**: Benchmark conversion speed before/after integration

3. **Environment Variable Pollution**: Exporting metadata could conflict with other tools
   - **Mitigation**: Use CLAUDE_-prefixed names if conflicts discovered
   - **Testing**: Test with common environment setups

### Implementation Risks
1. **Incomplete Error Coverage**: Might miss some error paths in 1313-line convert-core.sh
   - **Mitigation**: Focus on critical paths first (input validation, conversion failures)
   - **Testing**: Error injection testing to verify coverage

2. **Test Suite Complexity**: Error logging tests require mocking failure scenarios
   - **Mitigation**: Use simple file-based failure triggers (nonexistent dirs, corrupted files)
   - **Testing**: Test the tests with known-good and known-bad scenarios

## Notes

### Implementation Sequence
Follow strict phase dependency order:
1. Phase 1 (environment + logging setup) must complete first
2. Phases 2 and 3 can proceed in parallel after Phase 1
3. Phase 4 is independent and can proceed in parallel with Phases 2-3
4. Phase 5 requires Phases 2, 3, 4 complete

### Critical Success Factors
- Error logging initialization happens BEFORE any delegation
- All error log calls include full context JSON
- Backward compatibility maintained for convert-core.sh
- /errors command successfully queries logged errors
- Documentation clearly explains delegation model pattern

### Future Enhancements
After debug strategy complete:
- Consider standardizing delegation model error logging across all commands
- Evaluate automatic error logging injection for all commands via template
- Consider error recovery strategies (automatic retry on transient errors)
- Explore error notification system (alert on critical error patterns)

# Fix Bash Command Failures and Topic Naming Implementation Plan

## Metadata
- **Date**: 2025-11-04
- **Feature**: Fix bash history expansion errors and improve topic directory naming
- **Scope**: Resolve two distinct issues in /coordinate command execution
- **Estimated Phases**: 6
- **Estimated Hours**: 12.5
- **Structure Level**: 0
- **Complexity Score**: 29.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Bash Command Failures Analysis](/home/benjamin/.config/.claude/specs/594_research_the_bash_command_failures_in_homebenjamin/reports/001_bash_command_failures.md)
  - [Topic Directory Naming Analysis](/home/benjamin/.config/.claude/specs/594_research_the_bash_command_failures_in_homebenjamin/reports/002_topic_directory_naming.md)

## Overview

This plan addresses two independent issues identified in the /coordinate command execution:

1. **Bash History Expansion Errors**: "bash: line 145: !: command not found" errors caused by indirect variable references (`${!varname}`) in library files during sourcing. Fixed by replacing with bash 4.3+ nameref pattern in context-pruning.sh and workflow-initialization.sh.
2. **Topic Directory Naming**: Non-suggestive directory names like `586_research_the_homebenjaminconfignvimdocs_directory_` instead of concise names like `nvim_docs_research`. Fixed by improving the topic name generation algorithm.

Both issues are non-blocking but degrade user experience. They can be fixed independently.

## Research Summary

**From Bash Command Failures Report**:
- Root cause: Bash parses scripts for history expansion BEFORE executing commands like `set +H`
- 9 instances of `${!varname}` across 2 library files trigger expansion during sourcing
- `emit_progress` function not found due to Bash tool's export non-persistence limitation
- Errors are non-blocking but create user confusion

**From Topic Directory Naming Report**:
- Current algorithm converts entire workflow descriptions character-by-character, including paths
- Missing: stopword filtering, path component extraction, keyword prioritization
- Recent bad examples: 6+ directories with embedded full paths and stopwords
- Proposed solution: Extract path components, remove stopwords, prioritize keywords

**Recommended Approach**:
- Phase 1: Fix emit_progress sourcing in coordinate.md (30 min, quick win)
- Phase 2: Fix indirect variable references in library files (2.5 hours, root cause fix)
- Phase 3: Add defensive checks for graceful degradation (1 hour)
- Phase 4: Improve topic naming algorithm (3 hours, independent from bash fixes)
- Phase 5: Comprehensive testing (3 hours, validates all fixes)
- Phase 6: Documentation and end-to-end validation (2.5 hours)

## Success Criteria

- [ ] No "!: command not found" errors in /coordinate Phase 0 execution
- [ ] No "emit_progress: command not found" errors in /coordinate Phase 0
- [ ] Topic directories use suggestive names (no embedded paths, <40 chars preferred)
- [ ] All existing tests pass
- [ ] New tests verify fixes for both issues
- [ ] Documentation updated to reflect changes

## Technical Design

### Issue 1: Bash History Expansion Errors

**Problem**: Indirect variable references (`${!varname}`) in library files trigger bash history expansion during library sourcing in Phase 0 Block 1, before `set +H` can execute.

**Root Cause**: When coordinate.md Phase 0 Block 1 sources library files via `source_required_libraries`, bash parses those files and encounters 9 instances of `${!varname}` syntax across 2 files:
- `context-pruning.sh`: 7 occurrences (indirect variable expansion)
- `workflow-initialization.sh`: 2 occurrences (indirect variable expansion and array key iteration)

**Solution Architecture**:
1. **Fix Library File References** (Phase 2): Replace indirect variable expansion `${!varname}` with bash 4.3+ nameref pattern in library files
2. **Fix emit_progress Sourcing** (Phase 1): Add library sourcing before function call in Phase 0 Block 3

**Technical Approach**: Use bash 4.3+ nameref (name references) to avoid `!` character in variable expansion:
```bash
# Old pattern (triggers history expansion):
local full_output="${!output_var_name}"

# New pattern (bash 4.3+ nameref):
local -n output_ref="$output_var_name"
local full_output="$output_ref"
```

**Note**: coordinate.md line 844 (`local checkpoint_pid=$!`) is NOT the issue - it's inside a function definition that isn't executed during Phase 0. No changes needed to coordinate.md bash blocks.

### Issue 2: Topic Directory Naming

**Problem**: Current `sanitize_topic_name()` converts entire input literally without semantic extraction.

**Solution Architecture**:
1. **Path Component Extraction**: Extract last 2-3 meaningful path segments (e.g., `nvim/docs` from full path)
2. **Stopword Removal**: Filter common English words ("the", "a", "to", "for", "of", etc.)
3. **Filler Verb Removal**: Remove research context words ("carefully", "research", "analyze")
4. **Keyword Prioritization**: Preserve action verbs and technical terms
5. **Intelligent Truncation**: Preserve whole words up to 50 characters

**Data Structures**:
- Stopword list: ~40 common English words
- Filler prefix patterns: 5-6 research context phrases
- Path extraction: Regex-based last-N-components extraction

### Integration Points

- **coordinate.md**: Progress emission sourcing (Phase 0 Block 3) - add unified-logger.sh sourcing
- **context-pruning.sh**: Replace 7 indirect variable expansions with nameref pattern
- **workflow-initialization.sh**: Replace 2 indirect variable expansions with nameref pattern
- **topic-utils.sh**: Complete replacement of `sanitize_topic_name()` algorithm
- **Other commands**: No changes needed (/orchestrate, /supervise, /implement use same libraries transparently)

### Backward Compatibility

- Bash fixes are transparent to users (no API changes, library modifications only)
- Nameref pattern requires bash 4.3+ (already a project requirement per CLAUDE.md)
- Topic naming only affects NEW topics (existing directories unchanged)
- `get_or_create_topic_number()` idempotency preserved
- All existing checkpoint and workflow initialization functionality unchanged

## Implementation Phases

### Phase 1: Fix emit_progress Function Availability
dependencies: []

**Objective**: Resolve "emit_progress: command not found" error by sourcing unified-logger.sh in Phase 0 Block 3

**Complexity**: Low

**Tasks**:
- [x] Read coordinate.md Phase 0 Block 3 (lines 905-991)
- [x] Add library sourcing pattern before workflow-initialization.sh sourcing
- [x] Source unified-logger.sh with fallback for graceful degradation
- [x] Add inline comment documenting Bash tool limitation (GitHub #334, #2508)
- [x] Verify library sourcing pattern matches other blocks

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Test emit_progress availability in Phase 0 Block 3
grep -A 20 "STEP 0.6: Initialize Workflow Paths" .claude/commands/coordinate.md | grep -q "source.*unified-logger.sh"
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 1 - Fix emit_progress Function Availability`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Fix Indirect Variable References in Library Files
dependencies: [1]

**Objective**: Eliminate "bash: line 145: !: command not found" by fixing indirect variable references in library files that trigger history expansion during sourcing

**Complexity**: Medium

**Root Cause**: The bash history expansion errors occur when Phase 0 Block 1 sources library files containing `${!varname}` syntax. Bash parses these files for history expansion BEFORE executing any commands, including `set +H`. The errors are NOT caused by coordinate.md line 844 (which is inside a function definition, not executed during Phase 0).

**Tasks**:
- [ ] Read context-pruning.sh and identify all `${!varname}` patterns (7 occurrences expected)
- [ ] Read workflow-initialization.sh and identify all `${!varname}` patterns (2 occurrences expected)
- [ ] For each occurrence, determine if it's indirect variable expansion or array key iteration
- [ ] Replace indirect variable expansion with bash 4.3+ nameref pattern:
  - OLD: `local full_output="${!output_var_name}"`
  - NEW: `local -n output_ref="$output_var_name"; local full_output="$output_ref"`
- [ ] Replace array key iteration with alternative syntax if needed:
  - Pattern: `for key in "${!ARRAY[@]}"` may remain (valid syntax)
  - Test if this specific pattern triggers history expansion
- [ ] Verify all library files can be sourced without history expansion errors
- [ ] Test that checkpoint-utils.sh functionality remains unchanged
- [ ] Test that workflow-initialization.sh functionality remains unchanged
- [ ] Verify no breaking changes to other commands (/orchestrate, /supervise, /implement)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Verify no ${!varname} indirect expansions remain in library files
grep -n '${!.*}' .claude/lib/context-pruning.sh | grep -v '@]' || echo "✓ context-pruning.sh clean"
grep -n '${!.*}' .claude/lib/workflow-initialization.sh | grep -v '@]' || echo "✓ workflow-initialization.sh clean"

# Test library sourcing without errors
bash -c 'source .claude/lib/context-pruning.sh && echo "✓ context-pruning.sh sources cleanly"'
bash -c 'source .claude/lib/workflow-initialization.sh && echo "✓ workflow-initialization.sh sources cleanly"'

# Test coordinate Phase 0 execution has no history expansion errors
/coordinate "test workflow" 2>&1 | grep '!: command not found' && echo "✗ FAIL" || echo "✓ PASS"

# Test checkpoint functionality unchanged
.claude/tests/test_checkpoint_utils.sh
```

**Expected Duration**: 2.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 2 - Fix Indirect Variable References in Library Files`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Add Defensive Checks for Critical Functions
dependencies: [1]

**Objective**: Improve error messages when functions are unavailable

**Complexity**: Low

**Tasks**:
- [ ] Read coordinate.md to identify all critical function calls
- [ ] Add `command -v function_name` checks before emit_progress calls
- [ ] Provide fallback echo statements with same format (PROGRESS: [Phase N] - message)
- [ ] Add checks for other critical functions (save_checkpoint, source_required_libraries)
- [ ] Document pattern in inline comments

**Testing**:
```bash
# Test graceful degradation when library sourcing fails
# Temporarily rename unified-logger.sh and verify fallback behavior
```

**Expected Duration**: 1 hour

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 3 - Add Defensive Checks for Critical Functions`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Implement Improved Topic Naming Algorithm
dependencies: []

**Objective**: Replace `sanitize_topic_name()` with algorithm that produces suggestive, human-readable topic names

**Complexity**: Medium

**Tasks**:
- [ ] Read topic-utils.sh current implementation (lines 60-79)
- [ ] Define stopword list (40+ common English words)
- [ ] Define filler prefix patterns (5-6 research context phrases)
- [ ] Implement Step 1: Path component extraction (last 2-3 segments)
- [ ] Implement Step 2: Remove full paths from description
- [ ] Implement Step 3: Convert to lowercase
- [ ] Implement Step 4: Remove filler prefixes
- [ ] Implement Step 5: Remove stopwords (preserve action verbs)
- [ ] Implement Step 6: Combine path components with cleaned description
- [ ] Implement Step 7: Clean up formatting (remove multiple underscores)
- [ ] Implement Step 8: Intelligent truncation (preserve whole words)
- [ ] Add comprehensive function documentation with examples
- [ ] Update usage examples at end of topic-utils.sh

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Manual test cases
source .claude/lib/topic-utils.sh
sanitize_topic_name "Research the /home/benjamin/.config/nvim/docs directory/"
# Expected: nvim_docs_directory

sanitize_topic_name "research authentication patterns to create implementation plan"
# Expected: authentication_patterns_create_implementation

sanitize_topic_name "fix the token refresh bug"
# Expected: fix_token_refresh_bug
```

**Expected Duration**: 3 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 4 - Implement Improved Topic Naming Algorithm`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Create Comprehensive Test Suite
dependencies: [2, 4]

**Objective**: Verify both fixes work correctly and prevent regressions

**Complexity**: Medium

**Tasks**:
- [ ] Create `.claude/tests/test_bash_command_fixes.sh`
- [ ] Test 1: Verify no history expansion errors in coordinate Phase 0
- [ ] Test 2: Verify emit_progress function available in Phase 0 Block 3
- [ ] Test 3: Verify checkpoint creation without $! exposure
- [ ] Test 4: Verify defensive checks provide graceful degradation
- [ ] Create `.claude/tests/test_topic_naming.sh`
- [ ] Test 5: Verify path extraction from full file paths
- [ ] Test 6: Verify stopword removal
- [ ] Test 7: Verify action verb preservation
- [ ] Test 8: Verify intelligent truncation (whole words preserved)
- [ ] Test 9: Verify idempotency with get_or_create_topic_number()
- [ ] Test 10: Verify backward compatibility (existing topics unaffected)
- [ ] Add tests to `.claude/tests/run_all_tests.sh`
- [ ] Run full test suite to verify no regressions

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Testing**:
```bash
# Run new test suites
.claude/tests/test_bash_command_fixes.sh
.claude/tests/test_topic_naming.sh

# Run full test suite
cd .claude/tests && ./run_all_tests.sh
```

**Expected Duration**: 3 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 5 - Create Comprehensive Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Documentation and Validation
dependencies: [3, 5]

**Objective**: Update documentation and perform end-to-end validation

**Complexity**: Low

**Tasks**:
- [ ] Update `.claude/docs/concepts/directory-protocols.md`
- [ ] Add "Topic Naming Guidelines" section explaining algorithm
- [ ] Document stopword filtering and path component extraction
- [ ] Update `.claude/commands/coordinate.md` inline comments
- [ ] Document why $! is not exposed in command files
- [ ] Document emit_progress sourcing pattern
- [ ] Update `topic-utils.sh` function documentation
- [ ] Add examples of new topic naming behavior
- [ ] Run end-to-end validation with real workflows
- [ ] Test: `/coordinate "Research the .claude/lib directory structure"`
- [ ] Test: `/coordinate "implement OAuth2 authentication"`
- [ ] Test: `/coordinate "fix memory leak in parser.js"`
- [ ] Verify no bash errors in Phase 0 for all test workflows
- [ ] Verify topic names are suggestive and under 40 characters

**Testing**:
```bash
# Integration tests with real workflows
/coordinate "Research the .claude/lib directory structure"
# Verify topic: NNN_claude_lib_directory_structure
# Verify no bash errors in output

/coordinate "implement OAuth2 authentication"
# Verify topic: NNN_implement_oauth2_authentication

/coordinate "fix memory leak in parser.js"
# Verify topic: NNN_fix_memory_leak_parserjs
```

**Expected Duration**: 2.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(594): complete Phase 6 - Documentation and Validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- Test individual functions in isolation
- Use `.claude/tests/test_*.sh` pattern
- Mock library dependencies where needed
- Verify edge cases (empty input, very long strings, special characters)

### Integration Testing
- Test full /coordinate workflow with various input types
- Verify bash errors eliminated in Phase 0
- Verify topic naming produces suggestive names
- Test with existing topics to verify backward compatibility

### Regression Testing
- Run full test suite after each phase
- Verify no breaking changes to existing functionality
- Test other commands that use topic-utils.sh (/research, /plan)
- Test other commands that use checkpoint-utils.sh (/implement, /orchestrate)

### Performance Testing
- Measure topic naming algorithm performance (target: <20ms)
- Verify no significant overhead in /coordinate Phase 0 initialization
- Test with 100+ character workflow descriptions

### Coverage Requirements
- Aim for >80% coverage on modified functions
- Test all code paths in new algorithm
- Verify error handling and graceful degradation

## Documentation Requirements

### Files to Update
1. **`.claude/docs/concepts/directory-protocols.md`**
   - Add "Topic Naming Guidelines" section
   - Explain stopword filtering and path extraction
   - Provide examples of good vs bad topic names

2. **`.claude/commands/coordinate.md`**
   - Update inline comments for emit_progress sourcing
   - Document why background checkpoint uses library wrapper

3. **`topic-utils.sh`**
   - Comprehensive function documentation
   - Examples of input → output transformations
   - Explain algorithm design rationale

4. **`checkpoint-utils.sh`**
   - Document new `save_checkpoint_in_background()` function
   - Explain PID encapsulation pattern

### Documentation Standards
- Follow CommonMark specification
- Use clear, concise language
- Include code examples with expected output
- No historical commentary (present-state focus)
- No emojis (UTF-8 encoding issues)

## Dependencies

### Internal Dependencies
- **Phase 1 → Phase 2**: Both fix bash errors in coordinate.md Phase 0
- **Phase 1 → Phase 3**: Defensive checks build on emit_progress fix
- **Phase 2 → Phase 5**: Testing requires checkpoint logic finalized
- **Phase 4 → Phase 5**: Testing requires topic naming algorithm complete
- **Phase 3, 5 → Phase 6**: Documentation requires all implementation complete

### External Dependencies
- None (all changes are internal to .claude/ system)

### Tool Dependencies
- bash 4.x+ (for indirect variable references, nameref if used)
- grep, sed (for topic naming algorithm)
- git (for testing and validation)

## Risk Management

### Technical Risks
1. **Risk**: Bash 4.3+ nameref pattern incompatible with some environments
   - **Mitigation**: Deferred to future iteration, use current `${!varname}` with fixes
   - **Impact**: Low (fixes address immediate issues)

2. **Risk**: Topic naming algorithm produces unexpected names for edge cases
   - **Mitigation**: Comprehensive test suite with 10+ test cases
   - **Impact**: Medium (can be adjusted post-deployment)

3. **Risk**: Breaking changes to checkpoint API affect other commands
   - **Mitigation**: Wrapper function maintains existing API compatibility
   - **Impact**: Low (backward compatible design)

### Timeline Risks
1. **Risk**: Testing phase reveals unexpected interactions
   - **Mitigation**: Allocate 3 hours for comprehensive testing
   - **Impact**: Medium (can extend timeline by 1-2 hours)

2. **Risk**: Documentation updates take longer than estimated
   - **Mitigation**: Focus on critical sections first
   - **Impact**: Low (can be completed incrementally)

## Rollback Strategy

### If Phase 1-3 Fails
- Revert coordinate.md changes
- Library functions unchanged, no rollback needed
- No user-facing impact

### If Phase 4 Fails
- Revert topic-utils.sh to original implementation
- Existing topics unaffected (naming change is forward-only)
- New topics use old naming temporarily

### If Testing Reveals Issues
- Use git bisect to identify problematic commit
- Revert specific phase causing issue
- Other phases remain functional (independent design)

## Future Enhancements

### Bash Error Fixes (Long-term)
- Consolidate Phase 0 blocks in coordinate.md to reduce repetition (2-3 hours)
- Add automated detection of history expansion triggers in CI/CD pipeline
- Add linting rule to prevent `${!varname}` in new library files

### Topic Naming Improvements
- Interactive naming mode with user confirmation (2 hours)
- Abbreviation dictionary for common terms (auth → authentication)
- Topic similarity detection to prevent duplicates (3 hours)
- Name quality scoring and warnings

## Notes

### Complexity Score Calculation
```
Score = Base(feature) + Tasks/2 + Files*3 + Integrations*5
      = 7 (enhance) + 20/2 + 4*3 + 0*5
      = 7 + 10 + 12 + 0
      = 29 (Tier 1: single file)
```

### Phase Organization
- Phases 1-3 address bash errors (sequential, high priority)
- Phase 4 addresses topic naming (independent, can run in parallel)
- Phase 5 tests both fixes (depends on Phases 2 and 4)
- Phase 6 documents and validates (depends on all implementation)

### Estimated Timeline
- Phase 1: 30 minutes
- Phase 2: 2.5 hours
- Phase 3: 1 hour
- Phase 4: 3 hours
- Phase 5: 3 hours
- Phase 6: 2.5 hours
- **Total**: 12.5 hours

### Standards Compliance
- 2-space indentation (bash scripts)
- Snake_case for function names
- Comprehensive function documentation
- Test-driven development approach
- Git commits per phase with conventional commit messages

# /lean-build Command Error Improvement Plan

## Metadata

- **Date**: 2025-12-03 (Revised)
- **Feature**: Fix /lean-build command awk syntax error and metadata extraction failure, add progress tracking
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Lean Build Error Analysis](../reports/001-lean-build-error-improvement-report.md)
  - [Plan Update Pattern Research](../reports/002-plan-update-pattern-research.md)
- **Complexity Score**: 25
- **Structure Level**: 0

## Overview

This plan addresses two categories of improvements to the /lean-build command:

**Category 1: Critical Metadata Extraction Errors** (Phases 1-6)
1. **AWK Syntax Error**: The awk negation pattern `!/^### Phase '"$STARTING_PHASE"':/"` triggers bash history expansion during preprocessing, causing "backslash not last character on line" errors
2. **Grep Pattern Mismatch**: The Tier 2 fallback grep pattern `^\*\*Lean File\*\*:` doesn't match actual markdown format `- **Lean File**: /path`

These errors block all plan-based /lean-build invocations and require manual intervention every time.

**Category 2: Progress Tracking Enhancement** (Phase 7)
Add real-time progress tracking instructions to lean-coordinator and lean-implementer subagents, mirroring the pattern used by /implement command to update plan file status markers ([NOT STARTED] → [IN PROGRESS] → [COMPLETE]) as phases execute.

## Research Summary

**Report 1: Lean Build Error Analysis**

The error analysis research identified:

- **Root Cause**: Violation of Command Authoring Standards prohibition on negation patterns that trigger bash history expansion during preprocessing stage
- **Standards Violation**: The awk pattern `!/pattern/` is equivalent to prohibited `if !` pattern
- **Grep Pattern Issue**: Missing `- ` prefix and incorrect escaping for markdown bold format
- **Impact**: 100% failure rate for plan-based invocations, 4-9 minutes manual debugging per execution
- **Working Patterns**: Identified correct patterns from /lean-plan validation code and /test command

**Report 2: Plan Update Pattern Research**

The progress tracking research documented:

- **/implement Pattern**: Uses explicit "Progress Tracking Instructions" in Task invocation prompt (lines 538-543)
- **Checkbox-Utils.sh Functions**: `add_in_progress_marker`, `mark_phase_complete`, `add_complete_marker` for status transitions
- **Coordinator Forwarding**: Implementer-coordinator forwards instructions to implementation-executor
- **Lean Infrastructure**: lean-implementer already has STEP 0 and STEP 9 for progress tracking, but not triggered
- **Missing Instructions**: /lean-build Block 1b lacks progress tracking instructions for lean-coordinator
- **Gap Analysis**: lean-coordinator needs to forward instructions to lean-implementer in parallel Task invocations

## Success Criteria

**Metadata Extraction (Phases 1-6)**:
- [ ] No awk syntax errors during plan-based /lean-build invocations
- [ ] Tier 1 metadata extraction succeeds for phase-specific lean_file metadata
- [ ] Tier 2 metadata extraction succeeds for global **Lean File** metadata
- [ ] Discovery logging shows clear Tier 1 → Tier 2 fallback progression
- [ ] Test coverage prevents regression of both patterns
- [ ] Standards compliance validated (no history expansion triggers)

**Progress Tracking (Phase 7)**:
- [ ] Progress tracking instructions added to /lean-build Block 1b Task invocation
- [ ] lean-coordinator.md documents instruction forwarding pattern
- [ ] Plan file progress markers update in real-time ([NOT STARTED] → [IN PROGRESS] → [COMPLETE])
- [ ] Block 1d recovery mechanism still functions correctly
- [ ] Test coverage validates progress marker updates during execution

## Technical Design

### Architecture Overview

The /lean-build command uses a 2-tier metadata extraction system:

**Tier 1 (Preferred)**: Phase-specific metadata extraction
- Pattern: `lean_file: /path/to/file.lean` immediately after phase heading
- Implementation: AWK script parsing phase boundaries
- Current Issue: Negation pattern `!/pattern/` triggers bash history expansion

**Tier 2 (Fallback)**: Global metadata extraction
- Pattern: `- **Lean File**: /path/to/file.lean` in metadata section
- Implementation: grep + sed extraction
- Current Issue: Missing `- ` prefix, incorrect asterisk escaping

### Fix Strategy

**AWK Pattern Fix** (Tier 1):
- Replace negation logic with positive conditional using `index()` function
- Use explicit phase number extraction and numeric comparison
- Single-quote entire awk script to prevent shell interpolation
- Add explicit BEGIN block for state initialization

**Grep Pattern Fix** (Tier 2):
- Change `grep -E` to basic `grep` for better literal handling
- Add `^- ` prefix to match markdown list format
- Single-quote pattern to prevent shell asterisk expansion
- Keep sed transformation for value extraction

**Logging Enhancement**:
- Add "Phase metadata not found, trying global metadata..." message for Tier 2 fallback
- Add WARNING with expected format when both tiers fail
- Show discovery method in all success paths

### Standards Compliance

**Command Authoring Standards**:
- Prohibition on `if !` and `elif !` patterns extends to awk `!/pattern/`
- Preprocessor runs BEFORE `set +H` can disable history expansion
- Required alternative: Exit code capture or positive conditional logic

**Three-Tier Sourcing Pattern**:
- Existing code already follows tier 1 (error-handling) sourcing
- No changes needed to library integration

**Output Suppression**:
- Discovery logging provides minimal, actionable output
- Error messages use structured WHICH/WHAT/WHERE format

### Progress Tracking Enhancement (Phase 7)

**Integration Points**:

1. **/lean-build Block 1b** (command → coordinator delegation):
   - Add "Progress Tracking Instructions" section to Task invocation prompt
   - Pass PLAN_FILE and CLAUDE_PROJECT_DIR variables explicitly
   - Mirror /implement Block 1b pattern (lines 538-543)

2. **lean-coordinator.md** (coordinator → implementer delegation):
   - Document instruction forwarding in behavioral guidelines
   - Update parallel implementer invocation examples (lines 326-412)
   - Add guidance about when to skip (file-based mode, phase_num=0)

3. **lean-implementer.md** (implementer execution):
   - No changes needed (STEP 0 and STEP 9 already exist)
   - Verify PLAN_PATH and PHASE_NUMBER variables are used correctly

4. **/lean-build Block 1d** (recovery):
   - No changes needed (already mirrors /implement's pattern)

**Instruction Format** (from research report Appendix A):

```markdown
Progress Tracking Instructions (plan-based mode only):
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before proving each theorem phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
- After completing each theorem proof: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
- File-based mode: Skip progress tracking (phase_num = 0)
```

**Variable Passing Pattern**:

From /lean-build to lean-coordinator:
- `PLAN_FILE="${PLAN_FILE:-}"` (empty string if file-based mode)
- `EXECUTION_MODE="${EXECUTION_MODE}"` (file-based or plan-based)
- `STARTING_PHASE="${STARTING_PHASE:-1}"` (phase number or 1 if file-based)
- `CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR}"` (absolute path to .claude parent)

From lean-coordinator to lean-implementer:
- `PLAN_PATH="$PLAN_FILE"` (passed from coordinator input)
- `PHASE_NUMBER="$phase_num"` (extracted from theorem_tasks[].phase_number)
- `EXECUTION_MODE="$EXECUTION_MODE"` (forwarded from coordinator input)
- `CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"` (forwarded from coordinator input)

## Implementation Phases

### Phase 1: Fix AWK Negation Pattern (Tier 1 Metadata) [COMPLETE]
dependencies: []

**Objective**: Replace awk negation pattern with positive conditional logic to eliminate bash history expansion errors

**Complexity**: Low

**Tasks**:
- [x] Read current awk pattern in /home/benjamin/.config/.claude/commands/lean-build.md lines 174-182
- [x] Replace negation pattern with positive conditional using index() function per research report Appendix A
- [x] Add explicit BEGIN block for in_phase=0 initialization
- [x] Use single-quoted awk script to prevent shell interpolation
- [x] Change awk variable from `phase` to `target` for clarity
- [x] Test pattern extracts phase-specific lean_file metadata correctly

**Testing**:
```bash
# Create test plan with phase-specific metadata
cat > /tmp/test_lean_plan.md <<'EOF'
# Test Plan

## Metadata
- **Lean File**: /test/global.lean

### Phase 1: Test Phase [COMPLETE]
lean_file: /test/phase1.lean

**Description**: Test phase
EOF

# Test Tier 1 extraction
STARTING_PHASE=1
PLAN_FILE=/tmp/test_lean_plan.md
LEAN_FILE_RAW=$(awk -v target="$STARTING_PHASE" '
  BEGIN { in_phase=0 }
  /^### Phase / {
    if (index($0, "Phase " target ":") > 0) {
      in_phase = 1
    } else {
      in_phase = 0
    }
    next
  }
  in_phase && /^lean_file:/ {
    sub(/^lean_file:[[:space:]]*/, "")
    print
    exit
  }
' "$PLAN_FILE")

# Verify extraction
[ "$LEAN_FILE_RAW" = "/test/phase1.lean" ] && echo "✓ Tier 1 extraction successful" || echo "✗ FAILED"

# Verify no awk errors
echo $? | grep -q '^0$' && echo "✓ No awk syntax errors" || echo "✗ AWK error detected"

# Cleanup
rm /tmp/test_lean_plan.md
```

**Expected Duration**: 30 minutes

### Phase 2: Fix Grep Pattern (Tier 2 Metadata) [COMPLETE]
dependencies: []

**Objective**: Update grep pattern to match actual markdown list format for global metadata extraction

**Complexity**: Low

**Tasks**:
- [x] Read current grep pattern in /home/benjamin/.config/.claude/commands/lean-build.md line 191
- [x] Change grep -E to basic grep for better literal handling
- [x] Add `^- ` prefix to pattern to match markdown list format
- [x] Verify single-quote protection for asterisk escaping
- [x] Update sed pattern to strip `- **Lean File**:` prefix
- [x] Test pattern extracts global metadata correctly

**Testing**:
```bash
# Create test plan with global metadata only
cat > /tmp/test_global_plan.md <<'EOF'
# Test Plan

## Metadata

- **Lean File**: /test/global_file.lean
- **Phase Count**: 1

### Phase 1: No Phase Metadata [COMPLETE]

**Description**: Test global fallback
EOF

# Test Tier 2 extraction
PLAN_FILE=/tmp/test_global_plan.md
LEAN_FILE_RAW=$(grep '^- \*\*Lean File\*\*:' "$PLAN_FILE" | sed 's/^- \*\*Lean File\*\*:[[:space:]]*//' | head -1)

# Verify extraction
[ "$LEAN_FILE_RAW" = "/test/global_file.lean" ] && echo "✓ Tier 2 extraction successful" || echo "✗ FAILED"

# Cleanup
rm /tmp/test_global_plan.md
```

**Expected Duration**: 20 minutes

### Phase 3: Add Discovery Logging [COMPLETE]
dependencies: [1, 2]

**Objective**: Enhance user visibility into metadata discovery process and failure modes

**Complexity**: Low

**Tasks**:
- [x] Add "Phase metadata not found, trying global metadata..." message before Tier 2 attempt
- [x] Add WARNING message when Tier 2 fails with expected format guidance
- [x] Verify discovery method logging shows correct tier (phase_metadata or global_metadata)
- [x] Update error context in log_command_error call to include tier information
- [x] Test logging output for all three scenarios (Tier 1 success, Tier 2 fallback, both fail)

**Testing**:
```bash
# Test Case 1: Tier 1 success (no Tier 2 message)
# Expected: "Lean file(s) discovered via phase metadata: /path"

# Test Case 2: Tier 2 fallback (shows progression)
# Expected:
#   "Phase metadata not found, trying global metadata..."
#   "Lean file(s) discovered via global metadata: /path"

# Test Case 3: Both tiers fail (shows warning)
# Expected:
#   "Phase metadata not found, trying global metadata..."
#   "WARNING: Global metadata extraction failed (check markdown format)"
#   "  Expected format: '- **Lean File**: /path/to/file.lean'"
#   "ERROR: No Lean file found via metadata"

# Verify with actual /lean-build invocation on test plans
```

**Expected Duration**: 30 minutes

### Phase 4: Create Test Coverage [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Implement automated test coverage to prevent regression of metadata extraction patterns

**Complexity**: Medium

**Tasks**:
- [x] Create test file /home/benjamin/.config/.claude/tests/commands/test_lean_build_metadata_extraction.sh
- [x] Implement Test Case 1: Phase-specific metadata extraction (Tier 1)
- [x] Implement Test Case 2: Global metadata extraction (Tier 2)
- [x] Implement Test Case 3: Multi-phase extraction (Phase 2 instead of Phase 1)
- [x] Add validation for no awk syntax errors across all test cases
- [x] Add validation for correct discovery method logging
- [x] Document test execution in lean-build command guide

**Testing**:
```bash
# Run test suite
bash .claude/tests/commands/test_lean_build_metadata_extraction.sh

# Expected output:
# Testing Tier 1 (phase-specific metadata)...
# ✓ Tier 1 extraction successful
# Testing Tier 2 (global metadata)...
# ✓ Tier 2 extraction successful
# Testing Phase 2 extraction...
# ✓ Phase 2 extraction successful
#
# All metadata extraction tests passed

# Verify exit code
echo $? | grep -q '^0$' && echo "✓ Test suite passed" || echo "✗ Test suite failed"
```

**Expected Duration**: 45 minutes

### Phase 5: Update Documentation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Document metadata format requirements and troubleshooting guidance

**Complexity**: Low

**Tasks**:
- [x] Add Lean File Metadata Format section to /home/benjamin/.config/.claude/docs/guides/commands/lean-build-command-guide.md if file exists
- [x] Document Tier 1 format: `lean_file: /path` after phase heading
- [x] Document Tier 2 format: `- **Lean File**: /path` in metadata section
- [x] Add discovery priority documentation (Tier 1 → Tier 2 → ERROR)
- [x] Add troubleshooting section for metadata extraction failures
- [x] Document best practice: Use Tier 1 for all /lean-plan generated plans

**Testing**:
```bash
# Verify documentation completeness
grep -q "Lean File Metadata Format" .claude/docs/guides/commands/lean-build-command-guide.md

# Verify all three formats documented
grep -q "lean_file:" .claude/docs/guides/commands/lean-build-command-guide.md
grep -q "- \*\*Lean File\*\*:" .claude/docs/guides/commands/lean-build-command-guide.md

# Verify discovery priority documented
grep -q "Discovery Priority" .claude/docs/guides/commands/lean-build-command-guide.md
```

**Expected Duration**: 30 minutes

### Phase 6: Standards Compliance Validation [COMPLETE]
dependencies: [1, 2]

**Objective**: Verify fixes comply with Command Authoring Standards and don't introduce new violations

**Complexity**: Low

**Tasks**:
- [x] Run bash preprocessing safety check on lean-build.md
- [x] Verify no `if !` or `elif !` patterns remain in command
- [x] Verify no awk negation patterns `!/pattern/` remain
- [x] Verify grep patterns use single quotes for shell safety
- [x] Run validate-all-standards.sh --sourcing on lean-build.md
- [x] Verify no ERROR-level violations detected

**Testing**:
```bash
# Check for prohibited negation patterns
grep -n '^\s*if !' .claude/commands/lean-build.md && echo "✗ VIOLATION: if ! pattern found" || echo "✓ No if ! violations"
grep -n '^\s*elif !' .claude/commands/lean-build.md && echo "✗ VIOLATION: elif ! pattern found" || echo "✓ No elif ! violations"
grep -n '!/\^' .claude/commands/lean-build.md && echo "✗ VIOLATION: awk negation pattern found" || echo "✓ No awk negation violations"

# Run standards validation
bash .claude/scripts/validate-all-standards.sh --sourcing --staged

# Verify exit code
[ $? -eq 0 ] && echo "✓ Standards validation passed" || echo "✗ Standards validation failed"
```

**Expected Duration**: 15 minutes

### Phase 7: Add Progress Tracking Instructions to Subagent Invocations [COMPLETE]
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Enhance /lean-build command to instruct lean-coordinator and lean-implementer subagents to update plan file progress markers in real-time, mirroring /implement command's pattern.

**Complexity**: Low

**Tasks**:
- [x] Add "Progress Tracking Instructions" section to lean-coordinator Task invocation in /home/benjamin/.config/.claude/commands/lean-build.md Block 1b (after line 403)
- [x] Include conditional guidance for plan-based vs file-based mode in instructions
- [x] Add note about graceful degradation if checkbox-utils.sh unavailable
- [x] Update /home/benjamin/.config/.claude/agents/lean-coordinator.md to document progress tracking instruction forwarding pattern in implementer invocations
- [x] Verify /home/benjamin/.config/.claude/agents/lean-implementer.md STEP 0 and STEP 9 are triggered by new instructions (no code changes needed)
- [x] Test progress marker updates during actual /lean-build execution with test plan
- [x] Verify Block 1d recovery still functions correctly after changes

**Testing**:
```bash
# Create test plan with phases
cat > /tmp/test_lean_progress.md <<'EOF'
# Test Lean Plan

## Metadata
- **Lean File**: /home/benjamin/projects/lean/TestProofs/Test.lean
- **Phase Count**: 2

### Phase 1: Prove theorem_add [COMPLETE]
lean_file: /home/benjamin/projects/lean/TestProofs/Test.lean

**Tasks**:
- [x] Prove theorem_add

### Phase 2: Prove theorem_mul [COMPLETE]
lean_file: /home/benjamin/projects/lean/TestProofs/Test.lean

**Tasks**:
- [x] Prove theorem_mul
EOF

# Execute /lean-build with plan
/lean-build /tmp/test_lean_progress.md --max-attempts=1

# Verify progress markers updated
# Expected: Phases transition [NOT STARTED] → [IN PROGRESS] → [COMPLETE]
grep -c "Phase.*\[IN PROGRESS\]" /tmp/test_lean_progress.md  # Expect 0 (should transition to COMPLETE)
grep -c "Phase.*\[COMPLETE\]" /tmp/test_lean_progress.md     # Expect 2 (both phases marked)

# Cleanup
rm /tmp/test_lean_progress.md
```

**Expected Duration**: 45 minutes

**Implementation Notes**:

The progress tracking instructions follow the exact pattern from /implement Block 1b (lines 538-543):

```markdown
Progress Tracking Instructions (plan-based mode only):
- Source checkbox utilities: source ${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh
- Before proving each theorem phase: add_in_progress_marker '$PLAN_FILE' <phase_num>
- After completing each theorem proof: mark_phase_complete '$PLAN_FILE' <phase_num> && add_complete_marker '$PLAN_FILE' <phase_num>
- This creates visible progress: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
- Note: Progress tracking gracefully degrades if unavailable (non-fatal)
- File-based mode: Skip progress tracking (phase_num = 0)
```

The lean-coordinator will forward these instructions to lean-implementer in its parallel Task invocations, similar to how implementer-coordinator forwards to implementation-executor.

## Testing Strategy

### Unit Testing

**Test Coverage**:
- Tier 1 metadata extraction (phase-specific lean_file)
- Tier 2 metadata extraction (global **Lean File**)
- Multi-phase extraction (Phase 2, Phase 3)
- No awk syntax errors across all patterns
- Discovery method logging accuracy
- Fallback progression visibility

**Test Execution**:
```bash
# Run isolated test suite
bash .claude/tests/commands/test_lean_build_metadata_extraction.sh

# Expected: 100% pass rate, 0 awk errors
```

### Integration Testing

**Test Scenarios**:

1. **Plan-based invocation with phase-specific metadata**:
   ```bash
   /lean-build /home/benjamin/.config/.claude/specs/033_worldhistory_universal_tactic_tests/plans/001-worldhistory-universal-tactic-tests-plan.md
   ```
   - Expected: Tier 1 discovery success, no errors

2. **Plan-based invocation with global metadata only**:
   - Create test plan with only `- **Lean File**:` in metadata
   - Expected: Tier 2 fallback success, shows "trying global metadata" message

3. **Plan-based invocation with missing metadata**:
   - Create test plan with no lean_file metadata
   - Expected: Clear error with format guidance

### Performance Testing

**Metrics**:
- Time savings: 4-9 minutes per invocation (no manual debugging)
- Success rate: 100% for correctly formatted plans (up from 0%)
- Execution time: <5 seconds for metadata extraction (unchanged)

## Documentation Requirements

### Files to Update

1. **/home/benjamin/.config/.claude/commands/lean-build.md**:
   - Lines 174-182: Replace awk negation pattern
   - Line 191: Fix grep pattern
   - Lines 192-196: Add discovery logging

2. **/home/benjamin/.config/.claude/tests/commands/test_lean_build_metadata_extraction.sh**:
   - Create new test file with comprehensive coverage

3. **/home/benjamin/.config/.claude/docs/guides/commands/lean-build-command-guide.md** (if exists):
   - Add metadata format specification section
   - Add troubleshooting section

### Documentation Standards

- Follow clean-break development (no historical commentary)
- Use markdown with code syntax highlighting
- Include concrete examples for all metadata formats
- Document discovery priority and fallback behavior

## Dependencies

### External Dependencies

- None (pure bash/awk/grep implementation)

### Internal Dependencies

- Command Authoring Standards (preprocessing safety)
- Plan Metadata Standard (metadata format conventions)
- Existing error-handling.sh library integration

### Prerequisite Knowledge

- Bash history expansion behavior
- AWK conditional logic patterns
- Grep pattern matching and escaping
- Markdown list format conventions

## Risk Assessment

### Low Risk

**Scope**: Changes isolated to metadata extraction block
**Impact**: Fixes critical blocker, no new features
**Rollback**: Simple git revert if issues detected

### Mitigation Strategies

**Pre-deployment**:
- Comprehensive test coverage before applying fixes
- Standards validation ensures no new violations
- Manual testing with actual plan files

**Post-deployment**:
- Monitor /errors logs for new metadata extraction failures
- Test with multiple plan formats (phase-specific, global, multi-file)
- Document any edge cases discovered

## Implementation Notes

### AWK Pattern Considerations

**Why index() over regex**:
- Simpler string search (no regex complexity)
- More portable across awk implementations
- Easier to understand and maintain
- No escaping issues with special characters

**Alternative: match() with array**:
- More explicit phase number extraction
- Supports complex phase numbering schemes
- Used in research report as comprehensive solution

**Chosen Approach**: index() for simplicity, match() as fallback if edge cases discovered

### Grep Pattern Considerations

**Why basic grep over grep -E**:
- Better literal character handling
- Simpler escaping rules for asterisks
- Matches working pattern from /lean-plan validation
- More predictable with single-quoted patterns

**Critical Requirement**: Single quotes around pattern to prevent shell glob expansion of asterisks

## Success Metrics

- [ ] Zero awk syntax errors in /lean-build invocations
- [ ] 100% success rate for plan-based metadata discovery
- [ ] Clear discovery logging for debugging
- [ ] Test coverage prevents future regressions
- [ ] Standards compliance validated
- [ ] Documentation updated for maintainability

## Completion Criteria

All phases complete with:
- All tasks checked off
- All tests passing
- Standards validation passing
- Documentation updated
- No ERROR-level violations detected

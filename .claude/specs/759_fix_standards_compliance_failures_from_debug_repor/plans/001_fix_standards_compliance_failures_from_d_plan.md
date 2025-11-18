# Fix Standards Compliance Failures Implementation Plan

## Metadata
- **Date**: 2025-11-17
- **Feature**: Fix standards compliance failures from debug report
- **Scope**: Test script bug fixes and command file compliance updates
- **Estimated Phases**: 4
- **Estimated Hours**: 2-3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 22.5
- **Research Reports**:
  - [Standards Compliance Fixes Research Report](/home/benjamin/.config/.claude/specs/759_fix_standards_compliance_failures_from_debug_repor/reports/001_standards_compliance_fixes.md)

## Overview

This plan addresses 4 standards compliance failures identified in the debug report. The primary issue is a test script bug where `grep -c` with alternation patterns (`\|`) produces multiline output instead of a single count, causing bash integer comparison failures. Additionally, three command files require compliance updates: optimize-claude.md and setup.md need imperative language patterns (Standard 0), while revise.md needs project directory detection (Standard 13).

## Research Summary

Key findings from the research report:

- **Test Script Bug**: `grep -c "pattern1\|pattern2"` can produce multiline output, causing "integer expression expected" errors in bash comparisons. Fix: Use `grep -E "pattern1|pattern2" | wc -l` instead.
- **optimize-claude.md**: Has "EXECUTE NOW" directives but lacks required role statement ("YOU ARE EXECUTING" or "YOUR ROLE").
- **revise.md**: Has bash blocks but lacks CLAUDE_PROJECT_DIR detection pattern with git fallback (Standard 13).
- **setup.md**: Has role statement ("YOU ARE EXECUTING AS") but uses non-standard "[EXECUTION-CRITICAL: ...]" markers instead of "EXECUTE NOW".

Recommended approach: Fix test script first to eliminate false failures, then address command file compliance issues.

## Success Criteria

- [ ] Test script `test_command_standards_compliance.sh` runs without "integer expression expected" errors
- [ ] All grep patterns with alternation use `grep -E ... | wc -l` pattern
- [ ] optimize-claude.md passes Standard 0 with role statement added
- [ ] revise.md passes Standard 13 with CLAUDE_PROJECT_DIR detection added
- [ ] setup.md passes Standard 0 with EXECUTE NOW markers
- [ ] Full test suite achieves 100% compliance rate (0 failures)
- [ ] Git commit created for each phase

## Technical Design

### Architecture Overview

The fixes target two layers:
1. **Test Infrastructure Layer**: Fix grep pattern handling in test script
2. **Command Layer**: Update command files to match standards expectations

### Component Changes

1. **test_command_standards_compliance.sh**:
   - Replace `grep -c "A\|B"` with `grep -E "A|B" | wc -l`
   - Affects 6 locations across 4 test functions

2. **optimize-claude.md**:
   - Add role statement after line 1
   - Format: "**YOU ARE EXECUTING** as the CLAUDE.md optimization orchestrator."

3. **revise.md**:
   - Add CLAUDE_PROJECT_DIR detection block at start of bash
   - Use git rev-parse with fallback to .claude directory search

4. **setup.md**:
   - Replace "[EXECUTION-CRITICAL: ...]" with "**EXECUTE NOW**: ..."
   - Affects 7 locations (lines 19, 67, 134, 168, 210, 253, 281)

## Implementation Phases

### Phase 1: Fix Test Script grep Bug
**Dependencies**: []

**Objective**: Fix all grep patterns in test_command_standards_compliance.sh that can produce multiline output

**Complexity**: Low

**Tasks**:
- [ ] Read test script at `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`
- [ ] Fix line 81: Replace `grep -c "YOU MUST\|MUST\|WILL\|SHALL"` with `grep -E "YOU MUST|MUST|WILL|SHALL" | wc -l`
- [ ] Fix line 83: Replace `grep -c "YOU ARE EXECUTING\|YOUR ROLE"` with `grep -E "YOU ARE EXECUTING|YOUR ROLE" | wc -l`
- [ ] Fix line 111: Replace `grep -c "git rev-parse\|\.claude"` with `grep -E "git rev-parse|\.claude" | wc -l`
- [ ] Fix line 161: Replace `grep -c "^source\|source \"\|source '"` with `grep -E "^source|source \"|source '" | wc -l`

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Fix line 167: Replace `grep -c "sm_init\|sm_transition\|verify_file_created\|handle_state_error"` with `grep -E "sm_init|sm_transition|verify_file_created|handle_state_error" | wc -l`
- [ ] Fix line 205: Replace `grep -c "if ! \|if !"` with `grep -E "if ! |if !" | wc -l`
- [ ] Fix line 206: Replace `grep -c " || \|exit 1"` with `grep -E " \|\| |exit 1" | wc -l`
- [ ] Verify script syntax with `bash -n test_command_standards_compliance.sh`

**Testing**:
```bash
# Verify script has no syntax errors
bash -n /home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh

# Run a quick test to verify no integer expression errors
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh setup.md 2>&1 | grep -i "integer expression"
# Expected: No output (no errors)
```

**Expected Duration**: 30 minutes

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(759): complete Phase 1 - Test Script grep Bug Fixes`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 2: Fix optimize-claude.md Standard 0 Compliance
**Dependencies**: [1]

**Objective**: Add role statement to optimize-claude.md to satisfy Standard 0

**Complexity**: Low

**Tasks**:
- [ ] Read optimize-claude.md at `/home/benjamin/.config/.claude/commands/optimize-claude.md`
- [ ] Insert role statement after line 1 (after `# /optimize-claude - CLAUDE.md Optimization Command`)
- [ ] Add blank line after title
- [ ] Add: `**YOU ARE EXECUTING** as the CLAUDE.md optimization orchestrator.`
- [ ] Add blank line
- [ ] Add: `**YOUR ROLE**: You MUST analyze CLAUDE.md structure and .claude/docs/ organization, then generate an actionable optimization plan. You WILL execute each phase in sequence without deviation.`
- [ ] Verify file structure preserved

**Testing**:
```bash
# Verify command passes Standard 0
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh optimize-claude.md

# Verify role statement present
grep -E "YOU ARE EXECUTING|YOUR ROLE" /home/benjamin/.config/.claude/commands/optimize-claude.md
# Expected: 2 lines
```

**Expected Duration**: 15 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(759): complete Phase 2 - optimize-claude.md Standard 0`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 3: Fix revise.md Standard 13 Compliance
**Dependencies**: [1]

**Objective**: Add CLAUDE_PROJECT_DIR detection to revise.md bash block

**Complexity**: Low

**Tasks**:
- [ ] Read revise.md at `/home/benjamin/.config/.claude/commands/revise.md`
- [ ] Locate the bash block starting at line 27 (after "```bash")
- [ ] Insert CLAUDE_PROJECT_DIR detection before `ARG1="$1"` (line 29)
- [ ] Add comment: `# Standard 13: Detect project directory`
- [ ] Add: `CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"`
- [ ] Add if block to detect via git rev-parse with fallback
- [ ] Add export statement: `export CLAUDE_PROJECT_DIR`
- [ ] Verify bash syntax: `bash -n` extract test

**Detection Block to Insert**:
```bash
# Standard 13: Detect project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
    CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
  else
    current_dir="$(pwd)"
    while [ "$current_dir" != "/" ]; do
      if [ -d "$current_dir/.claude" ]; then
        CLAUDE_PROJECT_DIR="$current_dir"
        break
      fi
      current_dir="$(dirname "$current_dir")"
    done
    [ -z "$CLAUDE_PROJECT_DIR" ] && CLAUDE_PROJECT_DIR="$(pwd)"
  fi
fi
export CLAUDE_PROJECT_DIR
```

**Testing**:
```bash
# Verify command passes Standard 13
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh revise.md

# Verify detection pattern present
grep -c "CLAUDE_PROJECT_DIR" /home/benjamin/.config/.claude/commands/revise.md
# Expected: >0

grep -E "git rev-parse|\.claude" /home/benjamin/.config/.claude/commands/revise.md
# Expected: Multiple matches
```

**Expected Duration**: 20 minutes

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(759): complete Phase 3 - revise.md Standard 13`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

### Phase 4: Fix setup.md Standard 0 Compliance and Final Verification
**Dependencies**: [1, 2, 3]

**Objective**: Replace EXECUTION-CRITICAL markers with EXECUTE NOW in setup.md and verify all fixes

**Complexity**: Low

**Tasks**:
- [ ] Read setup.md at `/home/benjamin/.config/.claude/commands/setup.md`
- [ ] Replace line 19: `[EXECUTION-CRITICAL: Execute this bash block immediately]` with `**EXECUTE NOW**: Execute this bash block immediately`
- [ ] Replace line 67: `[EXECUTION-CRITICAL: Execute when MODE=standard]` with `**EXECUTE NOW**: Execute when MODE=standard`
- [ ] Search for all other `[EXECUTION-CRITICAL:` patterns and replace with `**EXECUTE NOW**:`
- [ ] Verify all replacements made (should be 7 total based on research)
- [ ] Run full compliance test suite
- [ ] Verify 0 failures and 100% compliance rate

**Testing**:
```bash
# Verify command passes Standard 0
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh setup.md

# Verify EXECUTE NOW present
grep -c "EXECUTE NOW" /home/benjamin/.config/.claude/commands/setup.md
# Expected: 7 or more

# Verify no EXECUTION-CRITICAL remaining
grep -c "EXECUTION-CRITICAL" /home/benjamin/.config/.claude/commands/setup.md
# Expected: 0

# Full test suite
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh
# Expected: 0 failures, 100% compliance
```

**Expected Duration**: 25 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `fix(759): complete Phase 4 - setup.md Standard 0 and Final Verification`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

---

## Testing Strategy

### Test Approach

1. **Unit Testing**: Each phase tests its specific file changes
2. **Integration Testing**: Final phase runs full compliance suite
3. **Regression Testing**: Verify no new failures introduced

### Test Commands

```bash
# Test individual files
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh setup.md
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh optimize-claude.md
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh revise.md

# Full test suite
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh

# Verify no integer expression errors
/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh 2>&1 | grep -i "integer expression"
```

### Success Criteria Verification

- Full test suite: 0 failures
- Compliance rate: 100%
- No "integer expression expected" errors in output
- All modified commands pass their respective standards

## Documentation Requirements

- [ ] No documentation updates required (these are bug fixes)
- [ ] Debug report already documents the issues

## Dependencies

### Prerequisites
- Access to test script: `/home/benjamin/.config/.claude/tests/test_command_standards_compliance.sh`
- Access to command files in `/home/benjamin/.config/.claude/commands/`
- Bash shell for testing

### External Dependencies
- None

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| grep pattern escaping issues | Low | Medium | Test each pattern individually |
| Breaking existing test functionality | Low | High | Run full suite after each change |
| Missing some EXECUTION-CRITICAL markers | Low | Low | Use grep to find all occurrences |

## Rollback Plan

If issues arise:
1. Git revert individual commits per phase
2. Original patterns are well-documented in research report
3. No destructive changes - all are additive or replacement

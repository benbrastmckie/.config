# Improve /research Command Reliability

## Metadata
- **Date**: 2025-10-24
- **Feature**: Fix /research library reference, simplify fallback, align tool permissions
- **Scope**: Fix library path, add fail-fast error messages, align tool permissions with orchestrator role
- **Estimated Phases**: 2
- **Complexity**: Low
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Related Research**: TODO7.md execution trace analysis

## Overview

The `/research` command references wrong library filename and includes 27 lines of unused fallback code that hides failures instead of surfacing them for debugging.

### Issues Identified

1. **Wrong Library**: `artifact-operations.sh` → should be `artifact-creation.sh` (line 43)
2. **Unused Fallback**: 27 lines that create placeholder reports (never executed, hides agent non-compliance)
3. **Tool Permissions**: Include execution tools (Write, Grep, Glob, WebSearch, WebFetch) despite orchestrator-only role

### Solution

- Fix library reference (single line change)
- Replace unused fallback with fail-fast error message (27 lines → ~5 lines)
- Align tool permissions with orchestrator role: `Task, Bash, Read`

## Success Criteria

- [x] Zero bash errors from library reference
- [x] Fail-fast errors instead of placeholder reports (27 lines → ~5 lines)
- [x] Tool permissions align with orchestrator role: `Task, Bash, Read`
- [ ] All tests pass, no regressions

## Technical Design

### Library Fix
- Single line change: `artifact-operations.sh` → `artifact-creation.sh`
- Zero behavior change (correct library already exists)

### Fallback Simplification
- Remove unused placeholder creation (27 lines)
- Replace with explicit error message (5 lines)
- Fail-fast instead of hiding agent non-compliance
- **Rationale**: Aligns with Command Architecture Standards (fail-fast pattern)

### Tool Permissions
- **Keep**: `Task` (delegation), `Bash` (path calc, verification), `Read` (post-delegation verification)
- **Remove**: `Write, Grep, Glob, WebSearch, WebFetch` (execution tools, violate orchestrator role)
- **Rationale**: Aligns with Behavioral Injection Pattern (orchestrator delegates, doesn't execute)

## Implementation Phases

### Phase 1: Fix Library Reference and Tool Permissions [COMPLETED]
**Dependencies**: []
**Objective**: Eliminate bash errors, align tool permissions with orchestrator role
**Complexity**: Low
**Estimated Time**: 1 hour

Tasks:
- [x] Fix library reference (.claude/commands/research.md:43)
- [x] Update allowed-tools frontmatter
- [x] Update tool usage docs
- [x] Verify changes with grep tests

**1.1 Fix Library Reference**

**EXECUTE NOW** - Update library source statement:
- File: `.claude/commands/research.md`
- Line: 43
- Change: Replace `artifact-operations.sh` with `artifact-creation.sh`
- Pattern: `source .claude/lib/artifact-creation.sh`

**1.2 Update Allowed-Tools**

**EXECUTE NOW** - Update frontmatter:
- File: `.claude/commands/research.md`
- Line: 2
- New value: `allowed-tools: Task, Bash, Read`
- Remove: `Write, Grep, Glob, WebSearch, WebFetch`

**1.3 Update Documentation**

**EXECUTE NOW** - Clarify tool usage restrictions:
- File: `.claude/commands/research.md`
- Lines: 18-19
- Add: "(Read tool ONLY for post-delegation verification)"
- Clarify: Orchestrator delegates research, doesn't execute it

**MANDATORY VERIFICATION** - Test Changes:

Verify library reference:
```bash
grep -q "artifact-creation.sh" /home/benjamin/.config/.claude/commands/research.md
```

Verify allowed-tools:
```bash
head -10 /home/benjamin/.config/.claude/commands/research.md | grep -q "allowed-tools: Task, Bash, Read"
```

Verify no execution tool usage:
```bash
grep -E "^(Write|Grep|Glob|WebSearch|WebFetch) " /home/benjamin/.config/.claude/commands/research.md | wc -l
# Expected output: 0
```

**Files Modified**: `.claude/commands/research.md` (lines 2, 18-19, 43)

### Phase 2: Simplify Fallback to Fail-Fast [COMPLETED]
**Dependencies**: [1]
**Objective**: Replace unused placeholder creation with explicit error messages
**Complexity**: Low
**Estimated Time**: 30 minutes

Tasks:
- [x] Replace fallback code (research.md:264-290) with fail-fast error
- [x] Verify error message format
- [x] Confirm placeholder creation removed

**2.1 Simplify Fallback**

**EXECUTE NOW** - Replace placeholder creation with fail-fast error:
- File: `.claude/commands/research.md`
- Lines: 264-290 (27 lines)
- Replace with: 5-line fail-fast error message
- Pattern: Error message + increment verification counter + add to failed agents list

**Implementation Pattern**:
```markdown
else
  echo "  ❌ ERROR: Report not found: $EXPECTED_PATH"
  echo "  Agent did not create file. Review .claude/agents/research-specialist.md"
  VERIFICATION_ERRORS=$((VERIFICATION_ERRORS + 1))
  FAILED_AGENTS+=("$subtopic")
fi
```

**Rationale**:
- Removes 27 lines of unused code (never executed per TODO7.md analysis)
- Aligns with fail-fast pattern (Command Architecture Standards - Standard 0)
- Provides clear debugging signal vs hidden placeholder report

**MANDATORY VERIFICATION** - Test Simplification:

Verify fallback size reduction:
```bash
START=$(grep -n "else" /home/benjamin/.config/.claude/commands/research.md | grep -A 1 "Report not found" | head -1 | cut -d: -f1)
END=$(grep -n "fi" /home/benjamin/.config/.claude/commands/research.md | awk -v start="$START" '$1 > start {print; exit}' | cut -d: -f1)
LINES=$((END - START))
test $LINES -le 7
# Expected: exit 0 (≤7 lines)
```

Verify placeholder removal:
```bash
grep -q "cat > .*EXPECTED_PATH.*<<EOF" /home/benjamin/.config/.claude/commands/research.md
# Expected: exit 1 (not found)
```

**Files Modified**: `.claude/commands/research.md` (lines 264-290)

### Phase 3 (OPTIONAL): Add Regression Tests
**Dependencies**: [1, 2]
**Objective**: Prevent future regressions (optional - execute only if time permits)
**Complexity**: Low
**Estimated Time**: 30 minutes
**Execution Condition**: Only if Phases 1 and 2 complete successfully

**NOTE**: This phase is OPTIONAL. The core fixes (library, fallback, tools) are complete after Phase 2. Execute this phase ONLY if time permits and regression prevention is desired.

Tasks:
- [ ] Add 3 tests to existing test file (no new files created)
- [ ] Run full test suite to verify no regressions

**3.1 Add Tests to Existing File** (OPTIONAL)

**IF EXECUTING** - Append to `.claude/tests/test_command_integration.sh`:

Test 1: Library reference correctness
```bash
grep -q "artifact-creation.sh" /home/benjamin/.config/.claude/commands/research.md && \
  ! grep -q "artifact-operations.sh" /home/benjamin/.config/.claude/commands/research.md
```

Test 2: Allowed-tools verification
```bash
TOOLS=$(grep "^allowed-tools:" /home/benjamin/.config/.claude/commands/research.md | cut -d: -f2 | tr -d ' ')
[ "$TOOLS" = "Task,Bash,Read" ]
```

Test 3: Placeholder removal confirmation
```bash
! grep -q "cat > .*EXPECTED_PATH.*<<EOF" /home/benjamin/.config/.claude/commands/research.md
```

**MANDATORY VERIFICATION** (IF PHASE 3 EXECUTED):

Run full test suite:
```bash
cd /home/benjamin/.config/.claude/tests
./run_all_tests.sh
```

**Expected**: All tests pass, no regressions introduced

**Files Modified**: `.claude/tests/test_command_integration.sh` (append 3 tests)

## Testing Strategy

### Automated Tests (Phase 3 - Optional)
- Library reference correctness
- Tool permissions verification
- Fallback simplification confirmation

### Manual Validation (Phase 1 & 2)
- Verify library change with grep
- Verify tool permissions with grep
- Verify no bash errors on command execution
- Confirm fail-fast error messages appear when agent fails

### Regression Prevention
- Full test suite pass required (if Phase 3 executed)
- No changes to agent invocation patterns
- No changes to report structure

## Dependencies

### Prerequisites
- Task tool functional
- Correct library exists: `.claude/lib/artifact-creation.sh`
- Agent file unchanged: `.claude/agents/research-specialist.md`

### External Dependencies
None

## Risk Assessment

### Zero Risk
- Library fix: single line, correct library already exists
- Tool permissions: removes unused tools (no execution impact)
- Fallback simplification: replaces unused code (never executed)

## Notes

### Design Principles

1. **Fail-Fast Over Silent Recovery**: Clear errors instead of placeholders
2. **Minimal Viable Improvement**: Fix library, remove bloat, done
3. **Orchestrator Role Alignment**: Remove execution tools, keep delegation tools only

### Excluded from Scope (Streaming Resilience)

**Rationale for Removing Retry Logic from Plan**:

Streaming failures are external to /research command:
- **Root cause**: API/network transient issues, not command design
- **Already handled**: Claude CLI has built-in retry mechanisms
- **Impact scope**: Not specific to /research (affects all Task invocations)
- **Better location**: System-wide retry logic belongs in Claude CLI, not individual commands

**Evidence from TODO7.md**:
- 3/4 streaming failures (75%) but all agents eventually succeeded
- No persistent failures (system-level retries working)
- Command-level retry adds complexity without addressing root cause

**Decision**: Fix actual bugs (library, fallback), defer streaming resilience to system level.

### Related Standards

- [Command Architecture Standards](.claude/docs/reference/command_architecture_standards.md) - Standard 0 (Execution Enforcement)
- [Behavioral Injection Pattern](.claude/docs/concepts/patterns/behavioral-injection.md) - Orchestrator role
- [Verification and Fallback Pattern](.claude/docs/concepts/patterns/verification-fallback.md) - Fail-fast principles

### Commit Message

```
fix(research): Fix library reference and simplify fallback

- Fix library: artifact-operations.sh → artifact-creation.sh
- Simplify fallback: fail-fast (27 lines → ~5 lines, remove placeholder creation)
- Update allowed-tools: Task, Bash, Read (remove execution tools)
- Update docs: clarify orchestrator-only role

Impact: Zero bash errors, clearer error messages, cleaner tool permissions

Closes: spec 470
Refs: TODO7.md execution trace
```

## Revision History

### 2025-10-24 (Revision 2) - Standards Compliance Enhancement
**Changes**: Added imperative language markers, dependency declarations, verification checkpoints
**Modifications**:
- Added **EXECUTE NOW** markers to all implementation steps (Standard 0 compliance)
- Added **MANDATORY VERIFICATION** checkpoints for test validation
- Added phase dependency declarations: Phase 1: [], Phase 2: [1], Phase 3: [1, 2]
- Clarified Phase 3 as truly OPTIONAL (execute only if time permits)
- Replaced diff blocks with imperative instructions (avoid inline code duplication)
- Emphasized fail-fast pattern alignment with Command Architecture Standards
- Maintained economized scope (no retry logic, no new files, minimal implementation)

**Standards Alignment**:
- [Standard 0: Execution Enforcement](/.claude/docs/reference/command_architecture_standards.md#standard-0) - Imperative language, verification checkpoints
- [Directory Protocols](/.claude/docs/concepts/directory-protocols.md) - Phase dependencies for wave-based execution
- [Behavioral Injection Pattern](/.claude/docs/concepts/patterns/behavioral-injection.md) - Orchestrator role clarification

**Plan Size**: ~300 lines (compliant, economical, standards-aligned)

### 2025-10-24 (Revision 1) - Economize for Lean Implementation
**Changes**: Removed retry logic, streamlined to essential fixes only
**Modifications**:
- Removed retry logic implementation (system-level concern, not command-level)
- Removed retry wrapper function (35 lines of bash code)
- Removed troubleshooting documentation file creation
- Removed dedicated test script (consolidated into existing test file)
- Reduced phases: 3 → 2 (+1 optional testing phase)
- Reduced estimated time: 5-8 hours → 1.5-2 hours (70% reduction)
- Reduced plan size: ~700 lines → ~200 lines (71% reduction)
- Added rationale for excluding retry logic

**Rationale**:
1. **Standards compliance**: Aligns with Command Architecture Standards and Behavioral Injection Pattern
2. **Avoid bloating /research**: Retry logic adds complexity without addressing root cause
3. **Fail-fast philosophy**: Clear errors > complex recovery (CLAUDE.md standards)
4. **Economize workflow**: Focus on actual bugs (library, fallback), defer streaming to system level
5. **Efficient implementation**: 1.5 hours vs 5-8 hours (3.5-6.5 hours saved)

## Implementation Summary

**Status**: Not Started

**Phases**: 0/2 completed (Phase 3 optional)

**Next Steps**:
1. Execute Phase 1: Library fix + tool permissions (1 hour)
2. Execute Phase 2: Fallback simplification (30 minutes)
3. (Optional) Execute Phase 3: Regression tests (30 minutes)

**Total Time**: 1.5-2 hours (single session)

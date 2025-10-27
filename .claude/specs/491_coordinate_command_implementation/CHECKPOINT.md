# /coordinate Implementation Checkpoint

## Session Information
- **Date**: 2025-10-27
- **Last Phase Completed**: Phase 1 (Foundation and Baseline)
- **Current Phase**: Phase 2 (Standards Compliance Fixes) - 1/3 violations fixed
- **Context Usage at Pause**: 151k/200k tokens (75%)

## Completed Work

### Phase 1: Foundation and Baseline ✅
**Status**: COMPLETE - Committed as `1179e2e1`

**Completed Tasks**:
- ✅ Copied `/supervise.md` to `/coordinate.md` (2,180 lines)
- ✅ Updated command metadata (argument-hint, description, dependent-commands)
- ✅ Replaced all `/supervise` references with `/coordinate` (14 updates)
- ✅ Created test suite (`.claude/tests/test_coordinate_basic.sh`)
- ✅ Created size tracking document (`SIZE_TRACKING.md`)
- ✅ Updated plan with completion markers
- ✅ Git commit created

**Deliverables**:
- `.claude/commands/coordinate.md` (2,180 lines)
- `.claude/tests/test_coordinate_basic.sh` (6 tests, all passing)
- `.claude/specs/491_coordinate_command_implementation/SIZE_TRACKING.md`
- Plan file updated with [COMPLETED] marker

### Phase 2: Standards Compliance Fixes 🔄
**Status**: IN PROGRESS - 1/3 violations fixed

**Completed Tasks**:
- ✅ Fixed Violation 2: Removed code-fenced YAML anti-pattern (lines 52-58)
  - Changed from code-fenced ```yaml block to plain text
  - Prevents priming effect that causes 0% agent delegation

**Remaining Tasks for Phase 2**:
- ⏳ **Violation 1**: Add "EXECUTE NOW" imperative markers
  - Location 1: Around line 1135-1155 (debug-analyst invocation) - NOTED: This is commented-out code
  - Location 2: Around line 1667-1677 (code-writer Phase 5 invocation)
  - Need to find active Task invocations and add markers within 5 lines

- ⏳ **Violation 3**: Extract behavioral content to agent files
  - Extract debug-analyst STEP 1-4 sequence to `.claude/agents/debug-analyst.md`
  - Extract code-writer STEP 1-4 sequence to `.claude/agents/code-writer.md`
  - Update Task invocations to reference behavioral files only
  - Expected reduction: ~250 lines → ~25 lines (90% reduction)

- ⏳ **Additional Audits**:
  - Search for other code-fenced Task examples: ` ```yaml\nTask {`
  - Verify all Task invocations have imperative markers within 5 lines
  - Document size reduction from behavioral extraction

## Files Modified (Uncommitted)
- `.claude/commands/coordinate.md` - Violation 2 fix applied
- Plan file - Phase 2 in progress

## Resume Instructions

### Option 1: Resume /implement with Phase 2
```bash
/implement /home/benjamin/.config/.claude/specs/491_coordinate_command_implementation/plans/001_coordinate_command_implementation.md 2
```

### Option 2: Manual Continuation

1. **Find Active Task Invocations**:
   ```bash
   grep -n "Task {" .claude/commands/coordinate.md | grep -v "^[[:space:]]*#"
   ```

2. **Add Imperative Markers**:
   - Add "**EXECUTE NOW**:" within 5 lines before each Task invocation
   - Example:
     ```
     **EXECUTE NOW - Invoke Research Agent**

     USE the Task tool to invoke research-specialist:

     Task {
       subagent_type: "general-purpose"
       ...
     }
     ```

3. **Extract Behavioral Content**:
   - Search for inline STEP 1-4 sequences in Task prompts
   - Move to appropriate agent behavioral files
   - Replace with "Read and follow ALL behavioral guidelines from: .claude/agents/[agent].md"

4. **Test Phase 2 Completion**:
   ```bash
   # No code-fenced Task examples
   ! grep -Pzo '```yaml\s*Task\s*\{' .claude/commands/coordinate.md

   # Behavioral content extracted (should be 7+ references)
   grep -c "Read and follow ALL behavioral guidelines from:" .claude/commands/coordinate.md
   ```

5. **Commit Phase 2**:
   ```bash
   git add .claude/commands/coordinate.md .claude/specs/491_coordinate_command_implementation/
   git commit -m "feat(491): complete Phase 2 - Standards Compliance Fixes"
   ```

## Remaining Phases

- **Phase 3**: Wave-Based Implementation Integration (8-12 hours)
- **Phase 4**: Clear Error Handling and Diagnostics (2-3 hours)
- **Phase 5**: Context Reduction and Optimization (4-6 hours)
- **Phase 6**: Integration Testing and Validation (10-12 hours)
- **Phase 7**: Documentation and Migration Guide (4-6 hours)

**Total Remaining**: 28-39 hours estimated

## Size Budget Status
- **Current**: 2,180 lines (after Phase 1)
- **After Phase 2**: ~1,980 lines (expected -200 from behavioral extraction)
- **Target**: 2,500-3,000 lines
- **Budget Available**: 520-1,020 lines for Phases 3-7

## Notes
- Phase 2 Violation 1 locations reference commented-out code at line 1135-1155
- May need to search for actual active Task invocations in the file
- The code-fenced anti-pattern fix (Violation 2) is the easiest and most critical fix
- Behavioral extraction (Violation 3) will provide the largest size reduction

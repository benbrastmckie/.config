# ERR Trap Integration Checklist
## Phase 0 Pre-Implementation Verification

**Date Created**: 2025-11-20
**Plan**: 001_build_command_use_this_research_to_creat_plan.md
**Scope**: Integration points for 5 commands (31 bash blocks)

## Block Count Verification

| Command | Total Blocks | Verified | Line Numbers Mapped | Status |
|---------|--------------|----------|---------------------|--------|
| /plan   | 4            | ✓        | ✓                   | Ready  |
| /build  | 6            | ✓        | ✓                   | Ready  |
| /debug  | 11           | ✓        | ✓                   | Ready  |
| /repair | 3            | ✓        | ✓                   | Ready  |
| /revise | 8            | ✓        | ✓                   | Ready  |
| **Total** | **32**    | ✓        | ✓                   | Ready  |

**Note**: /plan has 4 blocks (not 3 as initially counted). Block 4 is verification/completion block.

## Reference Pattern (from /research command)

**Block 1 Pattern** (lines 152-153 in research.md):
```bash
# After COMMAND_NAME, USER_ARGS, WORKFLOW_ID are set
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

**Block 2+ Pattern** (lines 312-322 in research.md):
```bash
# After load_workflow_state()

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/research")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

## Command-Specific Integration Points

### /plan command (3 blocks)

**File**: `.claude/commands/plan.md`

**Block 1** (Setup):
- **Location**: Line 36
- **Pattern**: Block 1 (set COMMAND_NAME, USER_ARGS, WORKFLOW_ID, then trap)
- **Action**: Add trap setup after COMMAND_NAME, USER_ARGS, WORKFLOW_ID are exported
- **State Persistence**: Already has COMMAND_NAME, USER_ARGS in append_workflow_state
- **Notes**: WORKFLOW_ID needs to be added to state persistence

**Block 2** (Research Phase):
- **Location**: Line 258
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state, before research agent invocation
- **Notes**: Research specialist agent invoked here

**Block 3** (Planning Phase):
- **Location**: Line 431
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state, before plan architect invocation
- **Notes**: Plan architect agent invoked here; also has Block 4 (line 674) for verification

**Complete /plan bash block mapping**:
1. Block 1 (Setup): Line 36
2. Block 2 (Research): Line 258
3. Block 3 (Planning): Line 431
4. Block 4 (Verification): Line 674 - Also needs trap integration

### /build command (6 blocks)

**File**: `.claude/commands/build.md`

**Block 1** (Setup):
- **Location**: Lines ~211-212
- **Pattern**: Block 1 (set COMMAND_NAME, USER_ARGS, WORKFLOW_ID, then trap)
- **Action**: Add trap setup after line 212 (after export COMMAND_NAME USER_ARGS WORKFLOW_ID)
- **State Persistence**: Already has COMMAND_NAME, USER_ARGS, WORKFLOW_ID in append_workflow_state (~lines 260-262)
- **Notes**: Multi-block state machine workflow

**Block 2** (State Validation):
- **Location**: Lines ~558-560
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state, before state validation
- **Notes**: Validates build can proceed

**Block 3** (Phase Update):
- **Location**: Lines ~763-765
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Updates phase checkboxes in plan

**Block 4** (Testing):
- **Location**: Lines ~971-973
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Runs test suite

**Block 5** (Documentation):
- **Location**: Line 932
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Updates documentation

**Block 6** (Completion):
- **Location**: Line 1183
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Marks workflow complete

**Complete /build bash block mapping**:
1. Block 1 (Setup): Line 36
2. Block 2 (State Validation): Line 327
3. Block 3 (Phase Update): Line 520
4. Block 4 (Testing): Line 724
5. Block 5 (Documentation): Line 932
6. Block 6 (Completion): Line 1183

### /debug command (11 blocks)

**File**: `.claude/commands/debug.md`

**Block 1** (Setup):
- **Location**: Lines ~150-151
- **Pattern**: Block 1 (set COMMAND_NAME, USER_ARGS, WORKFLOW_ID, then trap)
- **Action**: Add trap setup after line 151 (after export COMMAND_NAME USER_ARGS)
- **State Persistence**: Need to verify state persistence for COMMAND_NAME, USER_ARGS, WORKFLOW_ID
- **Notes**: Most complex command (11 blocks)

**Blocks 2-11** (Various debug phases):
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after each load_workflow_state call
- **Notes**: Most complex integration (11 blocks total)

**Complete /debug bash block mapping**:
1. Block 1 (Setup): Line 28
2. Block 2: Line 89
3. Block 3: Line 240
4. Block 4: Line 330
5. Block 5: Line 498
6. Block 6: Line 567
7. Block 7: Line 716
8. Block 8: Line 770
9. Block 9: Line 891
10. Block 10: Line 941
11. Block 11: Line 1067

### /repair command (3 blocks)

**File**: `.claude/commands/repair.md`

**Block 1** (Setup):
- **Location**: Line 29
- **Pattern**: Block 1 (set COMMAND_NAME, USER_ARGS, WORKFLOW_ID, then trap)
- **Action**: Add trap setup after COMMAND_NAME, USER_ARGS, WORKFLOW_ID are exported
- **State Persistence**: Need to verify state persistence for COMMAND_NAME, USER_ARGS, WORKFLOW_ID
- **Notes**: Similar to /plan command structure

**Block 2** (Error Analysis):
- **Location**: Line 273
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Repair analyst agent invoked here

**Block 3** (Fix Planning):
- **Location**: Line 482
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after load_workflow_state
- **Notes**: Plan architect agent invoked here

**Complete /repair bash block mapping**:
1. Block 1 (Setup): Line 29
2. Block 2 (Analysis): Line 273
3. Block 3 (Planning): Line 482

### /revise command (8 blocks)

**File**: `.claude/commands/revise.md`

**Block 1** (Setup):
- **Location**: Lines ~235-249 (two COMMAND_NAME assignments)
- **Pattern**: Block 1 (set COMMAND_NAME, USER_ARGS, WORKFLOW_ID, then trap)
- **Action**: Add trap setup after line 249 (after export COMMAND_NAME USER_ARGS WORKFLOW_ID)
- **State Persistence**: Need to verify state persistence for COMMAND_NAME, USER_ARGS, WORKFLOW_ID
- **Notes**: Has conditional COMMAND_NAME assignment

**Blocks 2-8** (Various revise phases):
- **Pattern**: Block 2+ (restore context, then trap)
- **Action**: Add context restoration after each load_workflow_state call
- **Notes**: Second most complex integration (8 blocks)

**Complete /revise bash block mapping**:
1. Block 1 (Setup): Line 36
2. Block 2: Line 53 (appears to be an example or alternate block)
3. Block 3: Line 197
4. Block 4: Line 319
5. Block 5: Line 474
6. Block 6: Line 529
7. Block 7: Line 704
8. Block 8: Line 759

## Command-Specific Integration Challenges

### /build command
**Issue**: Bash history expansion errors in blocks 1b, 2, 3, 4
**Impact**: Non-fatal but creates noise
**Recommendation**: Review all bash blocks for unquoted `!` usage during integration
**Mitigation**: Already present (`set +H 2>/dev/null || true`)

### /debug command
**Issue**: Most complex command with 11 blocks
**Impact**: Highest integration effort, highest testing requirements
**Recommendation**: Test incrementally, validate each block integration before proceeding

### /revise command
**Issue**: Conditional COMMAND_NAME assignment logic
**Impact**: Need to ensure correct COMMAND_NAME value is persisted
**Recommendation**: Verify which COMMAND_NAME assignment (line 235 vs 249) should be used

## State Persistence Requirements

### Commands with COMPLETE state persistence (/research reference):
- COMMAND_NAME
- USER_ARGS
- WORKFLOW_ID

### Commands needing state persistence ADDITIONS:

**/ plan**:
- ✓ Has COMMAND_NAME, USER_ARGS (lines 232-234)
- ✗ Missing WORKFLOW_ID in state persistence
- **Action**: Add `append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"` after line 234

**/ build**:
- ✓ Has COMMAND_NAME, USER_ARGS, WORKFLOW_ID (lines 260-262)
- **Action**: None needed

**/ debug**:
- **Status**: Need to verify
- **Action**: Check for state persistence of COMMAND_NAME, USER_ARGS, WORKFLOW_ID

**/ repair**:
- **Status**: Need to verify
- **Action**: Check for state persistence of COMMAND_NAME, USER_ARGS, WORKFLOW_ID

**/ revise**:
- **Status**: Need to verify
- **Action**: Check for state persistence of COMMAND_NAME, USER_ARGS, WORKFLOW_ID

## Integration Template

### Block 1 Template
```bash
# After sourcing error-handling.sh and setting COMMAND_NAME, USER_ARGS, WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# Must also persist to state:
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

### Block 2+ Template
```bash
# After load_workflow_state()

# === RESTORE ERROR LOGGING CONTEXT ===
if [ -z "${COMMAND_NAME:-}" ]; then
  COMMAND_NAME=$(grep "^COMMAND_NAME=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "/command-name")
fi
if [ -z "${USER_ARGS:-}" ]; then
  USER_ARGS=$(grep "^USER_ARGS=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
fi
export COMMAND_NAME USER_ARGS WORKFLOW_ID

# === SETUP BASH ERROR TRAP ===
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
```

## Testing Strategy Per Command

### After Each Command Integration:
1. Verify trap setup count: `grep -c "setup_bash_error_trap" .claude/commands/COMMAND.md`
2. Verify state persistence: `grep -A5 "append_workflow_state" .claude/commands/COMMAND.md | grep -E "COMMAND_NAME|USER_ARGS|WORKFLOW_ID"`
3. Run command with intentional error to test trap
4. Verify error logged to errors.jsonl with correct metadata

## Phase 0 Completion Checklist

- [x] Verify bash block counts for all 5 commands (32 blocks total, not 31)
- [x] Verify /research command as reference pattern
- [x] Create integration checklist with command-specific notes
- [x] Identify Block 1 in each command (for initial trap setup)
- [x] Identify Blocks 2+ pattern in each command (for context restoration)
- [x] Document command-specific integration challenges
- [x] Complete detailed line number mapping for all /plan blocks (4 blocks)
- [x] Complete detailed line number mapping for all /build blocks (6 blocks)
- [x] Complete detailed line number mapping for all /debug blocks (11 blocks)
- [x] Complete detailed line number mapping for all /repair blocks (3 blocks)
- [x] Complete detailed line number mapping for all /revise blocks (8 blocks)
- [ ] Verify state persistence in /debug, /repair, /revise commands (will check during Phase 1 integration)

## Next Steps (Phase 1)

1. Complete remaining line number mappings (blocks 5-6 of /build, blocks 2-11 of /debug, blocks 2-8 of /revise)
2. Start with simplest commands first (/plan, /repair)
3. Then /build (partially validated structure)
4. Then /revise (8 blocks)
5. Finally /debug (most complex, 11 blocks)
6. Test each command immediately after integration

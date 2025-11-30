# Hook-Based Buffer Opening Fix - Implementation Plan

## Metadata
- **Date**: 2025-11-29
- **Feature**: Fix hook-based buffer opening timing/visibility issue
- **Scope**: Diagnose and fix why completion signals (REPORT_CREATED, PLAN_CREATED) are not visible in terminal buffer when Stop hook executes
- **Estimated Phases**: 4
- **Estimated Hours**: 4
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 48.0
- **Research Reports**:
  - [Hook Buffer Opening Root Cause Analysis](../reports/001-hook-buffer-opening-root-cause-analysis.md)
  - [Research Command Diagnostic Strategy](../reports/002-research-command-diagnostic-strategy.md)
  - [Minimal Changes POC](../reports/003-minimal-changes-poc.md)

## Overview

The hook-based buffer opening feature (Plan 851) is fully implemented with all components functional, but fails to open buffers automatically due to a **timing race condition**: the Stop hook fires when Claude finishes responding, but multi-block bash commands execute AFTER Claude's response completes. The REPORT_CREATED signal is output in Block 2, which hasn't executed when the hook reads the terminal buffer.

This plan implements a **proof-of-concept approach focused on /research command first**, with comprehensive diagnostic debugging to verify the root cause, followed by implementing the minimal delayed buffer read fix (300ms). Only after proving the solution works reliably for /research will it be expanded to other workflow commands (/plan, /debug, /repair, /revise).

## Research Summary

Key findings from three research reports:

**Report 001 - Root Cause Analysis**:
- All Plan 851 components are fully functional (hook script, Neovim module, hook registration)
- Hook successfully captures 2343 characters of terminal output but REPORT_CREATED signal is absent
- Root cause: Stop hook fires when Claude finishes responding, not when bash blocks finish executing

**Report 002 - Diagnostic Strategy**:
- **Critical Discovery**: Stop hook timing is based on Claude's response completion, not bash script completion
- Multi-block commands execute sequentially AFTER Claude responds
- /research Block 2 (which outputs REPORT_CREATED) hasn't executed when Stop hook fires
- Recommended approach: 300ms delayed buffer read to allow Block 2 execution

**Report 003 - Minimal Changes POC**:
- Exact code changes specified for /research proof-of-concept
- Two changes needed: (1) diagnostic terminal output dump, (2) 300ms delay before buffer read
- Total implementation: 44 lines of code added to post-buffer-opener.sh
- Expected success rate: ≥95% with 300ms delay

**Recommended Implementation Path**: Focus exclusively on /research command first, prove the 300ms delay works reliably, then expand to other commands only after achieving ≥95% success rate.

## Success Criteria

**Phase 1 - Diagnostic Verification** (Required before proceeding):
- [ ] Terminal output dump shows Block 2 execution status when hook fires
- [ ] Debug logs confirm REPORT_CREATED signal presence/absence
- [ ] Hypothesis validated: Stop hook fires before Block 2 executes

**Phase 2 - /research Proof-of-Concept** (Gate for expansion to other commands):
- [ ] /research buffer opens automatically ≥95% of the time (19/20 attempts minimum)
- [ ] Latency from /research completion to buffer open is <500ms
- [ ] Debug logs show Block 2 executed and signal detected after delay
- [ ] No regressions in existing hook functionality (metrics, TTS hooks)

**Phase 3 - Expansion to Other Commands** (Only if Phase 2 succeeds):
- [ ] /plan buffer opens automatically ≥95% of the time
- [ ] /debug buffer opens automatically ≥95% of the time
- [ ] /repair buffer opens automatically ≥95% of the time
- [ ] /revise buffer opens automatically ≥95% of the time
- [ ] Solution works consistently across all workflow commands

**Overall Requirements**:
- [ ] Solution does not require command modifications (maintains Plan 851's hook-only design)
- [ ] All existing tests pass with no regressions
- [ ] Configuration documented in hooks README

## Technical Design

### Architecture Overview

The fix maintains Plan 851's hook-based architecture:
1. Commands output completion signals (REPORT_CREATED: /path)
2. Stop hook fires when Claude response completes
3. Hook accesses terminal buffer via Neovim RPC
4. Hook extracts completion signal and opens buffer

The issue lies in step 3 - terminal buffer access timing. Two-phase diagnostic and fix approach:

**Phase 1: Diagnostic Verification**
- Add comprehensive terminal output logging to hook
- Confirm Block 2 execution status when Stop hook fires
- Validate timing race hypothesis with actual debug data
- Minimal risk, critical diagnostic value before implementing fix

**Phase 2: 300ms Delayed Buffer Read**
- Add configurable delay (default 300ms) before reading terminal buffer
- Gives Block 2 time to execute and flush REPORT_CREATED signal to terminal
- Simplest fix that addresses root cause (Stop hook fires before bash blocks complete)
- Configurable via BUFFER_OPENER_DELAY for different system speeds

**Phase 3: Expansion to All Commands**
- Validate delayed read works for /plan, /debug, /repair, /revise
- Same 300ms delay should work for all commands (same timing pattern)
- Testing-only phase, no code changes

**Phase 4: Documentation**
- Document configuration options and tuning guidance
- Update Plan 851 with lessons learned about Stop hook timing

### Component Interactions

```
Current Execution Flow (BROKEN):
1. Command starts (Block 1a-1c: setup, state init, topic naming)
2. Task tool delegation (Block 1d: invoke research-specialist)
3. Claude finishes responding → Stop hook fires
4. Hook reads terminal buffer (sees Blocks 1a-1d output only)
5. Hook searches for REPORT_CREATED signal → NOT FOUND
6. Buffer opening fails
7. Block 2 executes (verification and signal output: "REPORT_CREATED: path")

Root Cause:
- Step 3 (Stop hook) fires when Claude finishes responding (after Block 1d Task invocation)
- Step 7 (Block 2) executes AFTER Claude's response completes
- Hook reads terminal in step 4, but signal is output in step 7
- Timing race: step 4 < step 7

Fixed Execution Flow (WITH 300ms DELAY):
1. Command starts (Block 1a-1c: setup, state init, topic naming)
2. Task tool delegation (Block 1d: invoke research-specialist)
3. Claude finishes responding → Stop hook fires
4. Hook waits 300ms (BUFFER_OPENER_DELAY)
5. [During delay] Block 2 executes and outputs "REPORT_CREATED: path"
6. Hook reads terminal buffer (sees Blocks 1a-1d AND Block 2 output)
7. Hook finds REPORT_CREATED signal → SUCCESS
8. Buffer opens automatically

Solution:
- 300ms delay in step 4 allows Block 2 (step 5) to execute before terminal read (step 6)
- Configurable delay handles different system speeds
- No command modifications needed (hook-only fix)
```

### Technology Choices

- **Bash sleep**: Standard timing control, no additional dependencies
- **Neovim RPC**: Existing mechanism from Plan 851, proven to work
- **Environment variables**: Standard configuration pattern (BUFFER_OPENER_DELAY, BUFFER_OPENER_DEBUG)
- **No external tools**: Maintains zero-dependency design from Plan 851
- **No command modifications**: Hook-only solution preserves Plan 851 architecture

## Implementation Phases

### Phase 1: Diagnostic Verification for /research Command [COMPLETE]
dependencies: []

**Objective**: Add comprehensive diagnostic logging to verify the timing race hypothesis and confirm Block 2 execution status when Stop hook fires

**Complexity**: Low

**Scope**: Only /research command testing in this phase

Tasks:
- [x] Add terminal output dump to post-buffer-opener.sh after line 105 with line-by-line logging (file: /home/benjamin/.config/.claude/hooks/post-buffer-opener.sh)
- [x] Add Block execution markers check: verify presence of "Block 1d" and "Verifying research artifacts" (Block 2 marker)
- [x] Add REPORT_CREATED signal presence check in diagnostic output
- [x] Enable BUFFER_OPENER_DEBUG and run /research command in Neovim terminal
- [x] Examine debug log to confirm: (1) Block 2 NOT present initially, (2) REPORT_CREATED signal absent
- [x] Document findings in debug log: validate timing race hypothesis

Testing:
```bash
# Enable debug mode
export BUFFER_OPENER_DEBUG=true
# Run in Neovim terminal
# Execute: /research "test buffer opening diagnostic"
# Check: /home/benjamin/.config/.claude/tmp/buffer-opener-debug.log
# Expected: Block 1d present, Block 2 ABSENT, REPORT_CREATED signal ABSENT
# This confirms Stop hook fires before Block 2 executes
```

**Success Gate**: Must confirm Block 2 is absent when hook fires before proceeding to Phase 2.

**Expected Duration**: 45 minutes

### Phase 2: Implement 300ms Delayed Buffer Read for /research [COMPLETE]
dependencies: [1]

**Objective**: Add 300ms delay before terminal buffer read to allow Block 2 execution and output flushing, proving the fix works for /research command first

**Complexity**: Low

**Scope**: Only /research command validation in this phase - DO NOT test other commands yet

Tasks:
- [x] Add BUFFER_OPENER_DELAY environment variable with default 0.3 (300ms) (file: /home/benjamin/.config/.claude/hooks/post-buffer-opener.sh, before line 98)
- [x] Add multi-line comment explaining Stop hook timing and why delay is needed
- [x] Implement conditional sleep: if BUFFER_OPENER_DELAY != "0", sleep for that duration
- [x] Add debug log entry: "Applying 0.3s delay before reading terminal buffer"
- [x] Run /research command 20 times with debug enabled
- [x] Verify buffer opens automatically ≥19/20 times (95% success rate minimum)
- [x] Measure actual latency from completion to buffer open (target <500ms)
- [x] Verify debug logs show: Block 2 executed, REPORT_CREATED signal found

Testing:
```bash
# Test with default 300ms delay
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3
# Run in Neovim terminal
# Execute: /research "test delayed buffer read" (repeat 20 times)
# Expected: Buffer opens ≥19/20 times
# Expected: Debug log shows "Block 2 executed" and "REPORT_CREATED signal found"
# Expected: Total latency <500ms

# Test with delay disabled (should fail - proves delay is necessary)
export BUFFER_OPENER_DELAY=0
# Run /research once
# Expected: Buffer does NOT open (confirms timing race without delay)
```

**Success Gate**: Must achieve ≥95% success rate (19/20) for /research before proceeding to Phase 3.

**Expected Duration**: 1 hour

### Phase 3: Expand to All Workflow Commands [COMPLETE]
dependencies: [2]

**Objective**: Validate that the 300ms delayed buffer read solution works consistently for all workflow commands after proving it works for /research

**Complexity**: Low

**Prerequisites**: Phase 2 must achieve ≥95% success rate for /research

Tasks:
- [x] Test /plan command buffer opening with 300ms delay (20 attempts, expect ≥19 successes)
- [x] Test /debug command buffer opening with 300ms delay (20 attempts, expect ≥19 successes)
- [x] Test /repair command buffer opening with 300ms delay (20 attempts, expect ≥19 successes)
- [x] Test /revise command buffer opening with 300ms delay (20 attempts, expect ≥19 successes)
- [x] Verify all commands show Block execution completion in debug logs
- [x] Verify all commands detect appropriate completion signals (PLAN_CREATED, DEBUG_REPORT_CREATED, etc.)
- [x] Measure latency across all commands (all should be <500ms)
- [x] Test edge cases: very fast completions, slow completions, nested Task tool invocations
- [x] Document any command-specific timing variations discovered

Testing:
```bash
# Test each command type with same configuration
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3

# Test /plan
# Execute: /plan "test feature" (repeat 20 times)
# Record success rate

# Test /debug
# Execute: /debug "test issue" (repeat 20 times)
# Record success rate

# Test /repair
# Execute: /repair (repeat 20 times)
# Record success rate

# Test /revise
# Execute: /revise "existing plan" "changes" (repeat 20 times)
# Record success rate

# All commands should achieve ≥95% success rate
```

**Success Gate**: All workflow commands must achieve ≥95% success rate before proceeding to Phase 4.

**Expected Duration**: 1.5 hours

### Phase 4: Documentation and Finalization [COMPLETE]
dependencies: [3]

**Objective**: Document the solution, configuration options, and update Plan 851 with lessons learned

**Complexity**: Low

**Prerequisites**: All workflow commands achieving ≥95% success rate

Tasks:
- [x] Calculate final success rates across all commands (should be ≥95% for each)
- [x] Calculate average latency across all commands (should be <500ms)
- [x] Document configuration options in /home/benjamin/.config/.claude/hooks/README.md
  - BUFFER_OPENER_DEBUG (default: false)
  - BUFFER_OPENER_DELAY (default: 0.3)
  - BUFFER_OPENER_ENABLED (default: true)
- [x] Add "Buffer Opening Configuration" section to hooks README with usage examples
- [x] Add troubleshooting section: "If buffers don't open automatically..."
- [x] Include tuning guidance for different systems (fast: 0.2s, slow: 0.5s, remote: 0.8s)
- [x] Update Plan 851 with lessons learned section documenting Stop hook timing discovery
- [x] Note in Plan 851: "Stop hook fires when Claude responds, not when bash blocks complete"
- [x] Create summary of total changes: 44 lines added, 0 lines removed, 1 file modified

Testing:
```bash
# Verify documentation accuracy
# Test each documented configuration option
# Confirm examples work as described
# Verify troubleshooting steps resolve common issues

# Final validation
# Run each command type 5 times with default config
# Confirm all buffer opening works consistently
```

**Expected Duration**: 45 minutes

## Testing Strategy

### Phase 1 Testing - Diagnostic Verification [COMPLETE]
**Objective**: Confirm timing race hypothesis
- Run /research with BUFFER_OPENER_DEBUG=true
- Verify debug log shows Block 1d output but NOT Block 2 output
- Verify REPORT_CREATED signal is absent
- This confirms Stop hook fires before Block 2 executes

### Phase 2 Testing - /research Proof-of-Concept [COMPLETE]
**Objective**: Validate 300ms delay fixes /research buffer opening
- Run /research 20 times with BUFFER_OPENER_DELAY=0.3
- Measure success rate (target: ≥19/20 = 95%)
- Measure latency (target: <500ms)
- Verify debug logs show Block 2 executed and signal detected
- Test with delay disabled (BUFFER_OPENER_DELAY=0) to prove necessity

### Phase 3 Testing - All Workflow Commands [COMPLETE]
**Objective**: Validate solution works for all commands
- Test /plan, /debug, /repair, /revise with same 300ms delay
- Each command: 20 attempts, ≥19 successes required
- Measure latency for each command type
- Test edge cases: fast completions, slow completions, nested Task tools

### Phase 4 Testing - Documentation Validation [COMPLETE]
**Objective**: Verify documented configuration works as described
- Test each documented environment variable
- Test tuning examples (0.2s, 0.5s, 0.8s delays)
- Verify troubleshooting steps resolve issues
- Final validation: 5 runs per command with default config

### Regression Testing (All Phases)
- Existing hook functionality: metrics hook, TTS hook continue working
- Non-eligible commands: hooks don't interfere with non-workflow commands
- Error cases: hook fails gracefully when Neovim unavailable
- No performance degradation for other hooks

### Test Commands
```bash
# Phase 1: Diagnostic
export BUFFER_OPENER_DEBUG=true
# Run /research and examine debug log

# Phase 2: /research POC
export BUFFER_OPENER_DEBUG=true
export BUFFER_OPENER_DELAY=0.3
# Run /research 20 times, measure success rate

# Phase 3: All commands
export BUFFER_OPENER_DELAY=0.3
# Test each workflow command 20 times

# Phase 4: Configuration validation
# Test tuning examples from documentation
```

## Documentation Requirements

### Hook README Updates (Phase 4)
- Add "Buffer Opening Configuration" section with environment variables:
  - BUFFER_OPENER_DEBUG (enable diagnostic logging)
  - BUFFER_OPENER_DELAY (delay before reading terminal buffer, default: 0.3)
  - BUFFER_OPENER_ENABLED (enable/disable feature entirely)
- Add troubleshooting section: "If buffers don't open automatically..."
- Include tuning examples for different systems:
  - Fast system: BUFFER_OPENER_DELAY=0.2
  - Slow system: BUFFER_OPENER_DELAY=0.5
  - Remote/SSH: BUFFER_OPENER_DELAY=0.8
- Add debugging guide: How to use BUFFER_OPENER_DEBUG to diagnose issues

### Plan 851 Updates (Phase 4)
- Add "Lessons Learned" section documenting Stop hook timing discovery
- Key insight: "Stop hook fires when Claude finishes responding, not when bash blocks complete"
- Note that multi-block commands execute AFTER Claude's response
- Document that 300ms delay was sufficient to resolve timing race
- Reference this plan (975) for diagnostic process and solution details
- Mark Plan 851 as complete with timing caveat documented

## Dependencies

### External Dependencies
- Neovim RPC API (already available, used by Plan 851 implementation)
- Bash sleep command (standard utility, no installation needed)
- jq (already required by hook for JSON parsing)

### Internal Dependencies
- Existing post-buffer-opener.sh hook script (Plan 851)
- Existing buffer-opener.lua Neovim module (Plan 851)
- Hook registration in settings.local.json (Plan 851)
- Workflow commands outputting completion signals (/plan, /research, /debug, /implement)

### Prerequisites
- Plan 851 implementation complete (already done)
- Neovim running with Claude Code integration (user environment)
- Debug logging enabled for diagnostic phase

## Risk Assessment

### Low Risk (Phases 1, 2, 4)
- **Phase 1 (diagnostic)**: Read-only logging, no behavior changes
- **Phase 2 (delayed read)**: Simple sleep command, easily reversible, no complex logic
- **Phase 4 (documentation)**: No code changes, only documentation updates

### Minimal Risk (Phase 3)
- **Phase 3 (testing)**: No code changes, only validation testing of existing Phase 2 code
- Risk limited to discovering the solution doesn't work for some commands
- Mitigation: Can document /research-only support if other commands fail

### No High-Risk Phases
- Original plan's polling strategy (removed) and state file approach (removed) are NOT being implemented
- This revised plan uses simplest solution (300ms delay) with lowest risk profile

### Mitigation Strategies
- **Incremental validation**: Prove /research works before testing other commands
- **Success gates**: Each phase requires ≥95% success rate before proceeding
- **Diagnostic-first**: Phase 1 confirms hypothesis before implementing fix
- **Backward compatibility**: All changes are optional via environment variables
- **Easy rollback**: BUFFER_OPENER_DELAY=0 disables feature instantly
- **Research-driven**: Three research reports inform implementation reducing trial-and-error risk

## Rollback Plan

If any phase introduces regressions:

**Phase 1 Rollback**:
- Remove diagnostic logging code (terminal output dump section)
- No functional impact as Phase 1 is diagnostic-only
- Safe to leave in place with BUFFER_OPENER_DEBUG=false

**Phase 2 Rollback**:
- Set BUFFER_OPENER_DELAY=0 to disable delay
- Or remove delay code entirely and revert to original hook version
- Buffer opening will fail again, but no other functionality impacted

**Phase 3 Rollback**:
- No code changes in Phase 3 (testing only)
- If issues found, stay with /research-only by documenting other commands as unsupported

**Phase 4 Rollback**:
- Documentation changes only
- Remove configuration section from hooks README if needed
- Revert Plan 851 changes if lessons learned section causes confusion

**Emergency Rollback** (complete feature disable):
```bash
export BUFFER_OPENER_ENABLED=false
# Or restore pre-Plan-975 version of post-buffer-opener.sh from git
git checkout HEAD~N .claude/hooks/post-buffer-opener.sh
```

All changes maintain backward compatibility through optional environment variables, allowing gradual rollout and easy disabling if issues occur.

## Success Metrics

**Phase 1 - Diagnostic Success**:
- **Hypothesis Validation**: Debug logs confirm Block 2 NOT executed when hook fires
- **Signal Absence Confirmed**: REPORT_CREATED signal verified absent in initial terminal read
- **Timing Race Proven**: Stop hook timing demonstrated to occur before Block 2 execution

**Phase 2 - /research POC Success**:
- **Success Rate**: ≥95% (minimum 19/20 successful buffer opens for /research)
- **Latency Target**: <500ms (time from /research completion to buffer open)
- **Diagnostic Validation**: Debug logs show Block 2 executed and signal detected after delay
- **Regression Rate**: 0% (no existing hook functionality broken)

**Phase 3 - All Commands Success**:
- **Per-Command Success Rate**: ≥95% for /plan, /debug, /repair, /revise
- **Consistency**: All commands use same 300ms delay configuration
- **Edge Case Coverage**: Fast/slow completions and nested Task tools all work

**Phase 4 - Documentation Success**:
- **Configuration Complexity**: 3 environment variables (BUFFER_OPENER_DEBUG, BUFFER_OPENER_DELAY, BUFFER_OPENER_ENABLED)
- **Documentation Coverage**: 100% (all features documented with examples)
- **Tuning Guidance**: Examples provided for fast/slow/remote systems
- **Plan 851 Update**: Lessons learned section added documenting Stop hook timing

**Overall Metrics**:
- **Total Code Changes**: 44 lines added to post-buffer-opener.sh
- **Files Modified**: 1 (post-buffer-opener.sh)
- **Implementation Time**: 4 hours (reduced from original 6 hours estimate)
- **Solution Simplicity**: Single 300ms delay (no polling complexity needed)

## Notes

**Implementation Strategy**:
- **Incremental Validation**: Prove solution works for /research before expanding to other commands
- **Research-Driven**: Three research reports informed this revised plan (see Research Summary)
- **Simplicity First**: 300ms delay is simplest solution that addresses root cause
- **Hook-Only Design**: Maintains Plan 851's architecture (no command modifications needed)
- **Success Gates**: Each phase has explicit success criteria that must be met before proceeding

**Key Insights from Research**:
- Stop hook timing is based on Claude's response completion, not bash script completion
- Multi-block commands execute sequentially AFTER Claude finishes responding
- Block 2 (which outputs REPORT_CREATED) hasn't executed when Stop hook fires
- 300ms delay provides sufficient time for Block 2 to execute and flush output

**Why /research First**:
- Most frequently used workflow command (good test case)
- Clear, consistent output pattern (REPORT_CREATED signal)
- Simple block structure (easy to verify diagnostic findings)
- High-value proof-of-concept (if this works, others should too)

**Alternative Approaches Considered**:
- Polling with retry (more complex, not needed if 300ms delay works)
- State file signal passing (requires command modifications, violates Plan 851 design)
- Multi-read strategy (unnecessary complexity if simple delay works)
- These remain available if 300ms delay proves insufficient

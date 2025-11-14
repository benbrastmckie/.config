# /coordinate LLM Classification Failure Fixes - Implementation Plan

## Metadata
- **Date**: 2025-11-13
- **Feature**: Fix /coordinate command LLM classification failures
- **Scope**: Surface suppressed error messages, replace PID-based temp files with semantic filenames, implement layered network detection, add automatic fallback to regex-only mode
- **Estimated Phases**: 7
- **Estimated Hours**: 18-22
- **Structure Level**: 0
- **Complexity Score**: 89.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Coordinate Command Failure Analysis - Overview](/home/benjamin/.config/.claude/specs/702_coordinate_command_failure_analysis/reports/001_coordinate_command_failure_analysis/OVERVIEW.md)

## Overview

The /coordinate command experiences classification failures in offline/corporate network environments due to three interconnected issues: (1) helpful error messages suppressed by stderr redirection in sm_init(), (2) PID-based temporary files that leak across bash block boundaries due to subprocess isolation, and (3) single-method network detection (ping only) producing 25-30% false negatives when ICMP is blocked. This implementation addresses all critical and high-priority recommendations from research, improving error visibility from 30% to 100%, network detection accuracy from 70-75% to 95%+, and reducing offline failure time from 10s to 1-4s (60-90% improvement).

## Research Summary

Research analysis identified four critical failure modes requiring coordinated fixes:

**1. Error Visibility Problem** (Recommendations 1-2):
- sm_init() redirects stderr with `2>&1`, capturing error output (workflow-state-machine.sh:353)
- Captured output only displayed on success, hiding actionable guidance about network issues and regex-only mode
- Unused error handler `handle_llm_classification_failure()` exists but never called (workflow-llm-classifier.sh:489-535)

**2. File Persistence Issues** (Recommendation 3):
- PID-based filenames (`/tmp/llm_classification_request_$$.json`) incompatible with bash block execution model
- 7 orphaned files found spanning 2 days, confirming systematic cleanup failures
- Traps fire at bash block boundaries (seconds), not workflow completion (minutes/hours)

**3. Network Detection Gaps** (Recommendations 4-5):
- Single-method detection (ping 8.8.8.8 only) produces 25-30% false negatives
- Corporate firewalls block ICMP in 30-50% of enterprises (security policy)
- No fallback to TCP/HTTP methods (nc, curl) that work when ICMP blocked

**4. Fallback Strategy Alignment** (Recommendations 6-7):
- Current design requires manual mode switching (export WORKFLOW_CLASSIFICATION_MODE=regex-only)
- Spec 057 verification fallback pattern demonstrates automatic fallback is REQUIRED for tool/agent failures
- Missing distinction between permanent offline and transient failures (no retry logic)

**Architectural Integration Points**:
- Bash Block Execution Model (semantic filenames, subprocess isolation patterns)
- Fail-Fast Policy (Spec 057 verification fallback vs bootstrap fallback taxonomy)
- State Persistence Library (fixed semantic filename precedent in state-persistence.sh)
- Clean-Break Philosophy (balance automatic fallback with visibility via warnings)

## Success Criteria

- [ ] Error visibility: 30% → 100% (users see all classification error messages)
- [ ] Network detection accuracy: 70-75% → 95%+ (layered detection handles corporate firewalls)
- [ ] Offline failure time: 10s → 1-4s (60-90% improvement via enhanced network checks)
- [ ] File leaks: Eliminated (0 orphaned temp files, workflow-scoped cleanup)
- [ ] Test coverage: 45+ new tests covering 7 failure modes (network, signaling, fallback)
- [ ] Automatic fallback: Offline scenarios gracefully degrade to regex-only mode
- [ ] Error handler integration: 100% usage (4 call sites using handle_llm_classification_failure)

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ /coordinate Command Invocation                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Phase 0: State Machine Initialization (sm_init)                │
│ - Load workflow-state-machine.sh                               │
│ - Call classify_workflow_comprehensive()                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: Layered Network Detection (NEW)                       │
│ - Layer 1: ICMP ping 8.8.8.8 (1s timeout)                     │
│ - Layer 2: TCP nc google.com 443 (1s timeout)                 │
│ - Layer 3: HTTP curl google.com (2s timeout)                  │
│ - Layer 4: IPv6 ping 2001:4860:4860::8888 (1s)                │
│ Result: Network available → LLM classification                  │
│         Network unavailable → Automatic fallback (NEW)          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Phase 2: LLM Classification (with fallback)                    │
│ - Semantic filenames: ${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json (NEW) │
│ - File-based signaling to Claude Code CLI                      │
│ - Timeout: 10s polling for response file                       │
│ - Error handling: handle_llm_classification_failure() (NEW)    │
│ - Fallback: Automatic switch to regex-only on failure (NEW)    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Phase 3: Error Visibility (FIX)                                │
│ - Capture stderr to temp file (mktemp)                         │
│ - Display stderr on failure (cat stderr_file >&2)              │
│ - Show context-specific suggestions via error handler          │
│ - Clean up temp file after display                             │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

**1. Semantic Filename Pattern** (aligns with state-persistence.sh precedent):
```bash
# Current (broken):
local request_file="/tmp/llm_classification_request_$$.json"

# New (workflow-scoped):
local workflow_id="${WORKFLOW_ID:-coordinate_$(date +%s)}"
local request_file="${HOME}/.claude/tmp/llm_request_${workflow_id}.json"
local response_file="${HOME}/.claude/tmp/llm_response_${workflow_id}.json"
```

**2. Layered Network Detection** (industry best practice):
```bash
check_network_connectivity() {
  # Layer 1: ICMP (fastest, but blocked in 30-50% of corporate)
  # Layer 2: TCP (95% reliability, respects firewall rules)
  # Layer 3: HTTP (90% reliability, respects HTTP_PROXY)
  # Layer 4: IPv6 (10-15% environments, growing trend)
  # Total: 4s worst-case, 95%+ accuracy
}
```

**3. Automatic Fallback with Visibility** (Spec 057 verification fallback):
```bash
classify_workflow_comprehensive() {
  if ! llm_result=$(classify_workflow_llm_comprehensive "$desc"); then
    echo "WARNING: LLM classification failed, falling back to regex-only" >&2
    echo "  Reason: Network unavailable or timeout" >&2
    if regex_result=$(classify_workflow_regex_comprehensive "$desc"); then
      echo "  Success: Regex classification completed" >&2
      return 0
    fi
  fi
}
```

**4. Error Handler Integration** (eliminate code duplication):
```bash
# Replace 4 inline error blocks with:
if ! llm_output=$(invoke_llm_classifier "$llm_input"); then
  handle_llm_classification_failure "timeout" "LLM invocation failed" "$workflow_desc"
  return 1
fi
```

### Component Interactions

1. **sm_init() → check_network_connectivity()**: Pre-flight check before LLM classification
2. **check_network_connectivity() → invoke_llm_classifier()**: Determines LLM vs fallback path
3. **invoke_llm_classifier() → semantic filenames**: Workflow-scoped files persist across blocks
4. **classification failure → handle_llm_classification_failure()**: Structured error messages
5. **LLM failure → automatic fallback**: Verification fallback per Spec 057
6. **sm_init() → stderr capture**: Temp file captures errors, displays on failure

## Implementation Phases

### Phase 1: Surface Suppressed Error Messages
dependencies: []

**Objective**: Capture and display stderr from sm_init() on failure, improving error visibility from 30% to 100%

**Complexity**: Low

**Tasks**:
- [ ] Modify workflow-state-machine.sh:353 to capture stderr to temp file during classification (file: .claude/lib/workflow-state-machine.sh, lines 353-384)
- [ ] Update sm_init() failure path to display captured stderr before returning error (file: .claude/lib/workflow-state-machine.sh, lines 372-384)
- [ ] Add cleanup of stderr temp file on success and failure paths (file: .claude/lib/workflow-state-machine.sh, lines 354, 383)
- [ ] Verify error messages now visible in manual testing with offline classification (test: run /coordinate with WORKFLOW_CLASSIFICATION_MODE=llm-only and no network)
- [ ] Update coordinate.md to remove duplicate error handling logic (file: .claude/commands/coordinate.md, check for sm_init error handling)

**Testing**:
```bash
# Test stderr visibility
export WORKFLOW_CLASSIFICATION_MODE=llm-only
# Disconnect network
/coordinate "research authentication"
# Expected: See "WARNING: No network connectivity detected" and suggestions

# Test success path (no stderr leakage)
export WORKFLOW_CLASSIFICATION_MODE=regex-only
/coordinate "research authentication"
# Expected: No error messages, clean execution
```

**Expected Duration**: 2 hours

**Phase 1 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 1 - Surface Suppressed Error Messages`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 2: Integrate handle_llm_classification_failure Function
dependencies: [1]

**Objective**: Replace inline error handling with structured error handler, eliminating code duplication and providing context-specific recovery suggestions

**Complexity**: Low

**Tasks**:
- [ ] Identify all call sites using inline error handling (file: .claude/lib/workflow-llm-classifier.sh, search for "echo.*ERROR.*LLM")
- [ ] Replace inline error block in classify_workflow_llm_comprehensive() with handle_llm_classification_failure() call (file: .claude/lib/workflow-llm-classifier.sh, lines 53-56)
- [ ] Replace inline error block in invoke_llm_classifier() timeout path with handle_llm_classification_failure() call (file: .claude/lib/workflow-llm-classifier.sh, lines 329-332)
- [ ] Update handle_llm_classification_failure() to support "network" error type (file: .claude/lib/workflow-llm-classifier.sh, lines 489-535)
- [ ] Add test case for handle_llm_classification_failure() integration (file: .claude/tests/test_llm_classifier.sh)

**Testing**:
```bash
# Test error handler integration
bash .claude/tests/test_llm_classifier.sh
# Expected: All 16+ tests pass (including new error handler test)

# Manual test: timeout error handling
export WORKFLOW_CLASSIFICATION_TIMEOUT=1
export WORKFLOW_CLASSIFICATION_MODE=llm-only
/coordinate "research patterns"
# Expected: Structured error message with context-specific suggestions
```

**Expected Duration**: 1.5 hours

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 2 - Integrate Error Handler`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Replace PID-Based Filenames with Semantic Names
dependencies: [1, 2]

**Objective**: Use workflow-scoped semantic filenames for cross-block persistence, eliminating file leaks and enabling checkpoint recovery

**Complexity**: Medium

**Tasks**:
- [ ] Update invoke_llm_classifier() signature to accept workflow_id parameter (file: .claude/lib/workflow-llm-classifier.sh, line 278)
- [ ] Replace PID-based request_file with semantic pattern (file: .claude/lib/workflow-llm-classifier.sh, line 280)
- [ ] Replace PID-based response_file with semantic pattern (file: .claude/lib/workflow-llm-classifier.sh, line 281)
- [ ] Create ${HOME}/.claude/tmp directory if not exists (file: .claude/lib/workflow-llm-classifier.sh, add mkdir -p before file creation)
- [ ] Update all callers of invoke_llm_classifier() to pass workflow_id (file: .claude/lib/workflow-llm-classifier.sh, search for "invoke_llm_classifier")

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Add workflow-scoped cleanup function (file: .claude/lib/workflow-llm-classifier.sh, add cleanup_workflow_classification_files function)
- [ ] Integrate cleanup with workflow completion (file: .claude/commands/coordinate.md, add to display_brief_summary)
- [ ] Remove EXIT trap from invoke_llm_classifier() (file: .claude/lib/workflow-llm-classifier.sh, line 295, trap now premature per bash block execution model)
- [ ] Update error messages to reference new file locations (file: .claude/lib/workflow-llm-classifier.sh, stderr messages)
- [ ] Verify no orphaned files after workflow completion (test: run workflow, check ${HOME}/.claude/tmp for leaks)

**Testing**:
```bash
# Test semantic filename persistence
export WORKFLOW_CLASSIFICATION_MODE=llm-only
WORKFLOW_ID="test_$(date +%s)"
# Run classification in bash block 1
bash -c "source .claude/lib/workflow-llm-classifier.sh; invoke_llm_classifier '$json_input' '$WORKFLOW_ID'"
# Verify file exists in bash block 2
ls "${HOME}/.claude/tmp/llm_request_${WORKFLOW_ID}.json"
# Expected: File exists and accessible across blocks

# Test cleanup on workflow completion
/coordinate "research authentication"
# After completion, check:
ls "${HOME}/.claude/tmp/llm_*.json"
# Expected: No orphaned files remain
```

**Expected Duration**: 3 hours

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 3 - Semantic Filename Persistence`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Implement Layered Network Detection
dependencies: [3]

**Objective**: Replace single-method detection with 4-layer approach, improving accuracy from 70-75% to 95%+

**Complexity**: High

**Tasks**:
- [ ] Backup existing check_network_connectivity() implementation (file: .claude/lib/workflow-llm-classifier.sh, lines 253-270)
- [ ] Implement Layer 1: ICMP ping with IPv4 and IPv6 fallback (file: .claude/lib/workflow-llm-classifier.sh, replace lines 261-266)
- [ ] Implement Layer 2: TCP connectivity check via netcat (file: .claude/lib/workflow-llm-classifier.sh, add after Layer 1)
- [ ] Implement Layer 3: HTTP connectivity check via curl (file: .claude/lib/workflow-llm-classifier.sh, add after Layer 2)
- [ ] Add command availability checks for ping/nc/curl (file: .claude/lib/workflow-llm-classifier.sh, add command -v checks)
- [ ] Update warning messages to indicate which layer succeeded/failed (file: .claude/lib/workflow-llm-classifier.sh, echo messages in each layer)
- [ ] Add timing information to debug logs (file: .claude/lib/workflow-llm-classifier.sh, use date +%s for elapsed time)
- [ ] Document worst-case timeout (4s total) in function comment (file: .claude/lib/workflow-llm-classifier.sh, line 248)

**Testing**:
```bash
# Test Layer 1: ICMP success
timeout 1 ping -c 1 8.8.8.8 && echo "Layer 1: PASS"

# Test Layer 2: TCP fallback (mock ICMP failure)
# Temporarily disable ping, verify nc fallback works
sudo chmod -x /usr/bin/ping
/coordinate "research auth"  # Should succeed via Layer 2
sudo chmod +x /usr/bin/ping

# Test Layer 3: HTTP fallback (mock ICMP+TCP failure)
# Use iptables to block ICMP and TCP 443
# Verify curl fallback succeeds

# Test IPv6 fallback
ping -6 -c 1 2001:4860:4860::8888 && echo "IPv6: PASS"

# Test all layers fail (true offline)
# Disconnect network completely
/coordinate "research auth"  # Should fail fast with clear message
```

**Expected Duration**: 3.5 hours

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 4 - Layered Network Detection`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 5: Add Comprehensive Test Suite
dependencies: [4]

**Objective**: Create 45+ new tests covering 7 failure modes (network, signaling, fallback), achieving comprehensive test coverage

**Complexity**: High

**Tasks**:
- [ ] Create test_network_connectivity.sh (file: .claude/tests/test_network_connectivity.sh, new file)
- [ ] Implement test_icmp_blocked_http_available (file: .claude/tests/test_network_connectivity.sh)
- [ ] Implement test_timeout_edge_cases (file: .claude/tests/test_network_connectivity.sh)
- [ ] Implement test_ping_unavailable (file: .claude/tests/test_network_connectivity.sh)
- [ ] Implement test_ipv6_only_network (file: .claude/tests/test_network_connectivity.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement test_rate_limiting (file: .claude/tests/test_network_connectivity.sh)
- [ ] Implement test_vpn_split_tunnel (file: .claude/tests/test_network_connectivity.sh)
- [ ] Implement test_localhost_only (file: .claude/tests/test_network_connectivity.sh)
- [ ] Create test_file_signaling_persistence.sh (file: .claude/tests/test_file_signaling_persistence.sh, new file)
- [ ] Implement test_single_block_workflow (file: .claude/tests/test_file_signaling_persistence.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement test_multi_block_workflow (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Implement test_workflow_scoped_filename (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Implement test_cleanup_success_path (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Implement test_cleanup_timeout_path (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Implement test_cleanup_signal_interruption (file: .claude/tests/test_file_signaling_persistence.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement test_orphaned_file_detection (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Implement test_race_condition_concurrent_rw (file: .claude/tests/test_file_signaling_persistence.sh)
- [ ] Create test_llm_classification_fallback.sh (file: .claude/tests/test_llm_classification_fallback.sh, new file)
- [ ] Implement test_automatic_fallback_network_failure (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_automatic_fallback_llm_timeout (file: .claude/tests/test_llm_classification_fallback.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement test_retry_logic_transient_network (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_retry_logic_transient_api (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_max_retry_limit (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_error_handler_integration (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_error_type_classification (file: .claude/tests/test_llm_classification_fallback.sh)

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

- [ ] Implement test_user_guidance_validation (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_mode_persistence_across_retries (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Implement test_fallback_warning_visibility (file: .claude/tests/test_llm_classification_fallback.sh)
- [ ] Update run_all_tests.sh to include new test files (file: .claude/tests/run_all_tests.sh)
- [ ] Run full test suite and verify 45+ new tests pass (command: bash .claude/tests/run_all_tests.sh)

**Testing**:
```bash
# Run new test files individually
bash .claude/tests/test_network_connectivity.sh
# Expected: 7 tests pass

bash .claude/tests/test_file_signaling_persistence.sh
# Expected: 8 tests pass

bash .claude/tests/test_llm_classification_fallback.sh
# Expected: 10 tests pass

# Run full test suite
bash .claude/tests/run_all_tests.sh
# Expected: All existing tests + 45 new tests = 113+ tests pass
```

**Expected Duration**: 5 hours

**Phase 5 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 5 - Comprehensive Test Suite`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 6: Implement Automatic Fallback to Regex-Only Mode
dependencies: [5]

**Objective**: Add automatic fallback from LLM to regex classification on failure, improving offline UX and aligning with Spec 057 verification fallback pattern

**Complexity**: Medium

**Tasks**:
- [ ] Add fallback logic to classify_workflow_comprehensive() (file: .claude/lib/workflow-scope-detection.sh, add after LLM classification attempt)
- [ ] Implement fallback trigger detection (network failure vs timeout vs parse error) (file: .claude/lib/workflow-scope-detection.sh)
- [ ] Add warning messages when fallback activates (file: .claude/lib/workflow-scope-detection.sh, echo to stderr)
- [ ] Include fallback reason in warning (file: .claude/lib/workflow-scope-detection.sh, pass error type from classification)
- [ ] Preserve explicit mode choice (regex-only mode skips fallback) (file: .claude/lib/workflow-scope-detection.sh, check WORKFLOW_CLASSIFICATION_MODE)
- [ ] Add failsafe: fail fast if both LLM and regex fail (file: .claude/lib/workflow-scope-detection.sh, return 1 if both methods fail)
- [ ] Update error messages to indicate "automatic fallback active" (file: .claude/lib/workflow-scope-detection.sh)
- [ ] Add unit test for automatic fallback behavior (file: .claude/tests/test_llm_classification_fallback.sh, test fallback trigger)
- [ ] Verify fallback warning visibility in manual testing (test: disconnect network, run /coordinate, check for "WARNING: Falling back to regex-only")

**Testing**:
```bash
# Test automatic fallback on network failure
export WORKFLOW_CLASSIFICATION_MODE=llm-only
# Disconnect network
/coordinate "research authentication"
# Expected:
#   WARNING: LLM classification failed, falling back to regex-only mode
#   Reason: Network unavailable
#   Success: Regex classification completed
# Workflow continues successfully

# Test explicit regex-only (no fallback warning)
export WORKFLOW_CLASSIFICATION_MODE=regex-only
/coordinate "research authentication"
# Expected: No fallback warnings, direct regex classification

# Test both methods fail (fail-fast)
# Mock: Break regex classifier temporarily
/coordinate "research authentication"
# Expected: ERROR: Both LLM and regex classification failed
```

**Expected Duration**: 2.5 hours

**Phase 6 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 6 - Automatic Fallback`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 7: Documentation and Integration Testing
dependencies: [6]

**Objective**: Update documentation, verify end-to-end workflows, validate all success criteria met

**Complexity**: Low

**Tasks**:
- [ ] Update CLAUDE.md with WORKFLOW_CLASSIFICATION_MODE documentation (file: CLAUDE.md, add section under "Workflow Classification Configuration")
- [ ] Document layered network detection in workflow-classification-guide.md (file: .claude/docs/guides/workflow-classification-guide.md)
- [ ] Update coordinate-command-guide.md troubleshooting section (file: .claude/docs/guides/coordinate-command-guide.md, add new error scenarios)
- [ ] Add semantic filename pattern to bash-block-execution-model.md examples (file: .claude/docs/concepts/bash-block-execution-model.md)
- [ ] Run end-to-end integration test: Offline development scenario (test: disconnect network, run full workflow)
- [ ] Run end-to-end integration test: Corporate firewall scenario (test: block ICMP, verify TCP fallback)
- [ ] Run end-to-end integration test: Transient network failure scenario (test: disconnect mid-workflow, verify recovery)
- [ ] Run end-to-end integration test: Multi-block workflow with semantic files (test: verify files persist across blocks)
- [ ] Verify success criteria: Error visibility 100% (test: check all error messages visible)
- [ ] Verify success criteria: Network detection 95%+ (test: all 7 failure modes tested)
- [ ] Verify success criteria: File leaks eliminated (test: check ${HOME}/.claude/tmp after workflows)
- [ ] Verify success criteria: Test coverage 45+ tests (test: count new tests in run_all_tests.sh output)

**Testing**:
```bash
# End-to-end integration tests
bash .claude/tests/test_coordinate_e2e_offline.sh
bash .claude/tests/test_coordinate_e2e_firewall.sh
bash .claude/tests/test_coordinate_e2e_transient.sh
bash .claude/tests/test_coordinate_e2e_multiblock.sh

# Success criteria verification
bash .claude/tests/validate_success_criteria.sh
# Expected: All 7 success criteria met
```

**Expected Duration**: 2.5 hours

**Phase 7 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(702): complete Phase 7 - Documentation and Integration`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Testing
- **test_network_connectivity.sh**: 7 tests for layered detection (ICMP blocked, timeouts, command unavailable, IPv6, rate limiting, VPN, localhost)
- **test_file_signaling_persistence.sh**: 8 tests for semantic filenames (single/multi-block workflows, cleanup paths, race conditions)
- **test_llm_classification_fallback.sh**: 10 tests for automatic fallback (network/timeout failures, retry logic, error handler integration)
- **Total new tests**: 25 unit tests + 20 integration tests = 45 tests

### Integration Testing
- **Offline Development**: Full workflow with no network (automatic fallback to regex-only)
- **Corporate Firewall**: ICMP blocked, TCP/HTTP available (Layer 2/3 detection succeeds)
- **Transient Failure**: Network drops mid-workflow (retry logic recovers)
- **Multi-Block Workflow**: Semantic files persist across bash blocks (no file leaks)
- **High-Latency Network**: 2s round-trip times (timeout adjustments prevent false positives)

### Regression Testing
- **Existing tests**: All 68 existing tests in test_llm_classifier.sh, test_offline_classification.sh, test_sm_init_error_handling.sh, test_coordinate_delegation.sh must continue passing
- **Backward compatibility**: Explicit WORKFLOW_CLASSIFICATION_MODE=regex-only continues working as before
- **Performance**: Online scenarios maintain <3.1s classification time (no degradation)

### Performance Testing
- **Offline scenario**: 10s → 1-4s (60-90% improvement)
- **Online scenario**: <100ms overhead from layered detection (Layer 1 succeeds immediately)
- **Corporate firewall**: <2s (Layer 2 TCP detection)
- **Transient failure with retry**: 6-8s (46-54% improvement vs manual retry)

## Documentation Requirements

### User-Facing Documentation
- **CLAUDE.md**: Add "Workflow Classification Configuration" section with WORKFLOW_CLASSIFICATION_MODE variable, usage examples, when to use regex-only
- **workflow-classification-guide.md**: Update with layered network detection explanation, troubleshooting for each layer failure
- **coordinate-command-guide.md**: Update troubleshooting section with new error scenarios (automatic fallback, layer failures, semantic file locations)

### Developer Documentation
- **bash-block-execution-model.md**: Add semantic filename pattern as validated best practice with LLM classification example
- **workflow-llm-classifier.sh**: Inline comments explaining layered detection logic, fallback triggers, semantic filename rationale
- **CHANGELOG.md**: Entry for Spec 702 with performance improvements, user-visible changes, migration notes (none required)

### Cross-References
- Link bash-block-execution-model.md → workflow-llm-classifier.sh (semantic filename usage)
- Link Spec 057 fail-fast policy → automatic fallback implementation (verification fallback pattern)
- Link state-persistence.sh → semantic filename precedent (architectural consistency)

## Dependencies

### External Dependencies
- **jq**: JSON parsing (already required by existing code)
- **ping**: Layer 1 network detection (already used, graceful fallback if missing)
- **nc (netcat)**: Layer 2 network detection (new dependency, graceful fallback if missing)
- **curl**: Layer 3 network detection (already available in most systems, graceful fallback if missing)

### Internal Dependencies
- **workflow-state-machine.sh**: sm_init() error capture mechanism
- **state-persistence.sh**: Semantic filename pattern precedent, workflow state management
- **error-handling.sh**: handle_state_error() integration for fail-fast
- **unified-logger.sh**: Progress markers, completion summaries
- **workflow-scope-detection.sh**: classify_workflow_comprehensive() entry point

### Architectural Dependencies
- **Bash Block Execution Model**: Subprocess isolation constraints, semantic filenames required
- **Fail-Fast Policy (Spec 057)**: Verification fallback taxonomy (automatic fallback is REQUIRED)
- **Clean-Break Philosophy**: Balance automatic fallback with visibility via warnings
- **State-Based Orchestration**: Workflow-scoped cleanup, checkpoint recovery patterns

## Risk Analysis

### Technical Risks

**Risk 1: Layered Detection Timeout Accumulation**
- **Likelihood**: Medium
- **Impact**: Low (4s total is still 60% faster than 10s LLM timeout)
- **Mitigation**: Each layer has 1-2s timeout, fail-fast on first success

**Risk 2: Automatic Fallback Masks Configuration Issues**
- **Likelihood**: Low
- **Impact**: Medium (users may not notice broken LLM classification)
- **Mitigation**: Explicit warnings when fallback activates, log fallback events to adaptive-planning.log

**Risk 3: Semantic Filenames Conflict in Parallel Workflows**
- **Likelihood**: Low (WORKFLOW_ID includes timestamp)
- **Impact**: Medium (classification failures if collision occurs)
- **Mitigation**: Use $(date +%s%N) for nanosecond precision if needed

### Operational Risks

**Risk 4: Corporate Firewalls Block All Detection Methods**
- **Likelihood**: Very Low (<1% of environments)
- **Impact**: High (classification fails even with layered detection)
- **Mitigation**: User can manually set WORKFLOW_CLASSIFICATION_MODE=regex-only before invocation

**Risk 5: Regression in Existing Functionality**
- **Likelihood**: Low (comprehensive test coverage)
- **Impact**: High (breaks existing workflows)
- **Mitigation**: All 68 existing tests must pass, manual regression testing in Phase 7

### Mitigation Strategy
1. Comprehensive test coverage (45+ new tests)
2. Phased rollout (critical fixes first, enhancements later)
3. Explicit warnings maintain visibility
4. Backward compatibility preserved (regex-only mode unchanged)
5. Fail-fast for genuine errors (both LLM and regex fail)

## Rollback Plan

### Phase-by-Phase Rollback

**Phase 1 (Error Visibility)**: Revert workflow-state-machine.sh lines 353-384 to original stderr redirection
**Phase 2 (Error Handler)**: Restore inline error handling, keep handle_llm_classification_failure() unused
**Phase 3 (Semantic Filenames)**: Revert to PID-based filenames, accept file leaks as known issue
**Phase 4 (Layered Detection)**: Revert to single-method ping detection
**Phase 5 (Test Suite)**: Remove new test files, no impact on production code
**Phase 6 (Automatic Fallback)**: Remove fallback logic, require manual mode switching
**Phase 7 (Documentation)**: Revert documentation changes

### Emergency Rollback Procedure

If critical issues discovered post-deployment:

1. **Immediate**: Set environment variable to disable new features:
   ```bash
   export WORKFLOW_CLASSIFICATION_FORCE_LEGACY=1
   ```

2. **Short-term**: Revert last commit(s) via git:
   ```bash
   git revert HEAD~N  # N = number of phase commits to revert
   ```

3. **Long-term**: Investigate root cause, fix, re-test, re-deploy

### Rollback Testing

Before each phase commit:
- [ ] Verify git diff shows only intended changes
- [ ] Run full test suite (existing + new tests)
- [ ] Manual smoke test of /coordinate command
- [ ] Document rollback procedure in commit message

## Success Metrics

### Quantitative Metrics
- **Error Visibility**: 30% → 100% (all stderr messages displayed on failure)
- **Network Detection Accuracy**: 70-75% → 95%+ (measured across 7 failure modes)
- **Offline Failure Time**: 10s → 1-4s (60-90% improvement)
- **File Leaks**: 7 orphaned files → 0 (verified by checking ${HOME}/.claude/tmp)
- **Test Coverage**: 68 tests → 113+ tests (45 new tests added)

### Qualitative Metrics
- **User Experience**: Elimination of manual two-step recovery process for offline scenarios
- **Error Messages**: Context-specific suggestions visible in all failure scenarios
- **Code Quality**: Elimination of 4 inline error handling blocks (DRY principle)
- **Architectural Alignment**: Semantic filenames align with state-persistence.sh precedent
- **Spec Compliance**: Automatic fallback follows Spec 057 verification fallback pattern

### Acceptance Criteria
- [ ] All 7 phases completed and committed
- [ ] All 113+ tests passing (68 existing + 45 new)
- [ ] All 7 success criteria verified (see Success Criteria section)
- [ ] Documentation updated (CLAUDE.md, guides, bash-block-execution-model.md)
- [ ] Manual testing confirms offline workflow succeeds with automatic fallback
- [ ] No orphaned files after workflow completion (checked in ${HOME}/.claude/tmp)
- [ ] Performance targets met: <4s offline, <100ms online overhead

## Notes

### Implementation Order Rationale
Phases ordered by dependency and user impact:
1. **Phase 1-2** (Error visibility, error handler): Immediate user benefit, no architectural changes
2. **Phase 3** (Semantic filenames): Foundation for cross-block persistence, enables Phase 4-6
3. **Phase 4** (Layered detection): Core improvement, enables accurate offline detection
4. **Phase 5** (Test suite): Validates Phases 1-4, enables safe deployment
5. **Phase 6** (Automatic fallback): User experience enhancement, depends on reliable detection
6. **Phase 7** (Documentation, integration): Final validation and knowledge transfer

### Complexity Score Calculation
```
Score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
      = (57 × 1.0) + (7 × 5.0) + (20 × 0.5) + (6 × 2.0)
      = 57 + 35 + 10 + 12
      = 114

Adjusted for parallel testing work: 89.5 (reflects realistic implementation complexity)
```

Score ≥50 suggests this plan may benefit from `/expand` during implementation if phases become too complex. However, clear task breakdown and comprehensive testing strategy should enable direct implementation from this Level 0 plan.

### Related Specifications
- **Spec 700**: Coordinate error fixes (Phase 5 added network pre-flight check, partial solution)
- **Spec 688**: Hybrid mode removal (Phase 3 clean-break update, created need for automatic fallback)
- **Spec 057**: Fail-fast policy analysis (verification fallback taxonomy justifies automatic fallback)
- **Spec 620/630**: Bash block execution model validation (subprocess isolation discovery, semantic filename precedent)

### Historical Context
This implementation completes work started in Spec 700 Phase 5 (network pre-flight check) and addresses technical debt from Spec 688 Phase 3 (hybrid mode removal). The semantic filename pattern follows precedent established in state-persistence.sh (Spec 630), and automatic fallback aligns with Spec 057 verification fallback requirements.

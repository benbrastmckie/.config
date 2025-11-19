# Refactor Plan Design: Plan Command Library Detection and Path Resolution

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Refactor plan to fix library detection and state persistence issues
- **Report Type**: design analysis
- **Complexity Level**: 3

## Executive Summary

The plan command requires a comprehensive refactor to address three interconnected root causes: (1) incorrect SCRIPT_DIR calculation leading to invalid library paths, (2) bash shell context isolation preventing function reuse across Bash blocks, and (3) missing explicit Task invocations for agent delegation. The refactor must maintain compliance with state-based orchestration patterns from `.claude/docs/architecture/state-based-orchestration-overview.md` while implementing the fixes already validated in spec 731.

## Findings

### Finding 1: Root Cause - SCRIPT_DIR Path Resolution Failure

**Location**: `/home/benjamin/.config/.claude/commands/plan.md:27`

**Current Implementation**:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then
```

**Actual Error** (from `/home/benjamin/.config/.claude/specs/plan_output.md:240-247`):
```
/run/current-system/sw/bin/bash: line 164:
/home/benjamin/.config/../lib/detect-project-dir.sh: No such file or directory
```

**Analysis**:
- Expected path: `/home/benjamin/.config/.claude/commands` → `../lib/` → `/home/benjamin/.config/.claude/lib/`
- Actual path: `/home/benjamin/.config` → `../lib/` → `/home/benjamin/lib/` (WRONG!)
- Root cause: `${BASH_SOURCE[0]}` is NOT set in Claude Code's bash execution context
- When `${BASH_SOURCE[0]}` is empty, `dirname ""` returns `.`, and `cd .` stays in current directory
- Current directory during /plan execution is `/home/benjamin/.config` (project root), NOT commands directory

**Why This Matters**:
- SCRIPT_DIR-based library detection works in normal bash scripts but fails in Claude Code's Bash tool
- The Bash tool doesn't preserve script metadata like BASH_SOURCE[0]
- Standard bash idioms for relative path resolution don't work

**Evidence from 731 Implementation**:
Spec 731 Phases 1-3 are marked complete, indicating the shell context issue was resolved, but the SCRIPT_DIR issue persists because it's a separate root cause.

### Finding 2: Shell Context Isolation (Already Documented)

**Location**: Report 001 (spec 732) comprehensively documents this issue

**Summary**:
- Each Bash tool call creates fresh shell - sourced functions lost
- Solution: Combine library sourcing + execution in single bash blocks
- Already addressed in spec 731 Phase 1 (complete)

**Implementation Status**: RESOLVED in 731

### Finding 3: Missing Task Invocations (Already Documented)

**Location**: Spec 731 Phases 2-3 document this issue

**Summary**:
- Imperative comments don't invoke agents - need explicit Task blocks
- Solution: Replace comments with actual Task invocations following optimize-claude pattern
- Already addressed in spec 731 Phases 2-3 (complete)

**Implementation Status**: RESOLVED in 731

### Finding 4: State-Based Orchestration Pattern Requirements

**Location**: `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:1-150`

**Key Requirements**:
1. **Explicit state names** instead of phase numbers (lines 88-107)
2. **Validated transitions** via state machine (lines 109-128)
3. **Centralized state lifecycle** via workflow-state-machine.sh (lines 129-145)
4. **Selective state persistence** using state-persistence.sh (lines 146-150)

**Current Plan Command Compliance**:
- ✓ Uses workflow-state-machine.sh (plan.md:38-42)
- ✓ Uses state-persistence.sh (plan.md:45-49)
- ✓ Initializes workflow state (plan.md:87-93)
- ✓ Persists state via append_workflow_state (plan.md:185-192)
- ✗ SCRIPT_DIR calculation breaks library loading before state machine can be sourced

**Critical Insight**:
The plan command correctly implements state-based orchestration patterns, but the SCRIPT_DIR failure prevents libraries from being sourced, so the state machine never initializes.

### Finding 5: Path Resolution Solution - CLAUDE_PROJECT_DIR Detection Pattern

**Location**: `/home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-50`

**Standard Pattern** (used by detect-project-dir.sh itself):
```bash
# Detect project root via git
if command -v git &>/dev/null; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null)"
fi

# Fallback: Walk up directory tree looking for .claude/
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# Calculate lib path from CLAUDE_PROJECT_DIR
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
```

**Why This Works**:
- Git detection is reliable and fast (2ms per state-based orchestration docs)
- Doesn't depend on BASH_SOURCE[0] or relative paths
- Works from any current directory
- Already implemented in detect-project-dir.sh library

**The Paradox**:
We need detect-project-dir.sh to get CLAUDE_PROJECT_DIR, but we need CLAUDE_PROJECT_DIR to source detect-project-dir.sh!

**Solution**:
Inline the git-based detection directly in plan.md Phase 0, BEFORE sourcing any libraries:

```bash
# Bootstrap CLAUDE_PROJECT_DIR detection (inline, no library dependency)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# STANDARD 13: Validate CLAUDE_PROJECT_DIR detected successfully
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: Could not find .claude/ directory via git or directory traversal"
  exit 1
fi

# Now we can source libraries using absolute paths
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
source "$UTILS_DIR/workflow-state-machine.sh" || exit 1
source "$UTILS_DIR/state-persistence.sh" || exit 1
# ... etc
```

### Finding 6: Spec 731 Completion Status and Remaining Work

**Location**: `/home/benjamin/.config/.claude/specs/731_claude_specs_plan_outputmd_and_create_a_clear/plans/001_plan.md:1-439`

**Completed Phases**:
- [x] Phase 1: Replace Bash Complexity Analysis with Haiku Subagent (lines 116-192)
- [x] Phase 2: Add Explicit Task Invocations for Research Delegation (lines 194-237)
- [x] Phase 3: Add Explicit Task Invocation for Plan-Architect (lines 239-279)
- [ ] Phase 4: Integration Testing and Documentation (lines 281-319) - INCOMPLETE

**What 731 Fixed**:
1. Replaced bash complexity analysis with Haiku subagent classifier
2. Added explicit Task invocations for research agents
3. Added explicit Task invocation for plan-architect agent
4. Combined library sourcing with execution in single blocks
5. Generated semantic filenames from Haiku-provided slugs

**What 731 Did NOT Fix**:
1. SCRIPT_DIR path resolution (wasn't identified as root cause)
2. Integration testing (Phase 4 incomplete)
3. Documentation updates (Phase 4 incomplete)

**Git Commit History** (from gitStatus):
```
f111dceb docs(731): update plan file with Phases 1-3 completion status
194a6090 feat(731): complete Phase 3 - Add explicit Task invocation for plan-architect
cd1b9097 feat(731): complete Phase 2 - Add explicit Task invocations for research delegation
5bd8ed60 feat(731): complete Phase 1 - Replace bash complexity analysis with Haiku subagent
```

**Conclusion**:
Spec 731 successfully resolved shell context isolation and Task invocation issues but didn't address SCRIPT_DIR path resolution because the failure mode wasn't fully diagnosed.

## Recommendations

### Recommendation 1: Inline CLAUDE_PROJECT_DIR Bootstrap in Phase 0

**Priority**: CRITICAL

**Rationale**: Eliminates SCRIPT_DIR dependency and bootstrap paradox

**Implementation**:
1. Remove lines 27-32 from plan.md (SCRIPT_DIR calculation and detect-project-dir.sh sourcing)
2. Add inline git-based CLAUDE_PROJECT_DIR detection at start of Phase 0
3. Calculate UTILS_DIR from CLAUDE_PROJECT_DIR
4. Source all other libraries using UTILS_DIR absolute paths
5. Keep detect-project-dir.sh library for consistency with other commands, but don't use it in plan.md

**Code Changes**:
```bash
# OLD (plan.md:27-32) - REMOVE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! source "$SCRIPT_DIR/../lib/detect-project-dir.sh" 2>&1; then
  echo "ERROR: Failed to detect project directory"
  exit 1
fi

# NEW (plan.md:24-45) - ADD
set +H  # Disable history expansion

# Bootstrap CLAUDE_PROJECT_DIR detection (inline to avoid circular dependency)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward for .claude/ directory
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

# STANDARD 13: Validate CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory"
  echo "DIAGNOSTIC: No git repository found and no .claude/ directory in parent tree"
  exit 1
fi

# Export for use by sourced libraries
export CLAUDE_PROJECT_DIR

# STANDARD 15: Source libraries using absolute paths
UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"
```

**Testing**:
```bash
# Test from various directories
cd /home/benjamin/.config && /plan "test feature"  # Should work
cd /tmp && /plan "test feature"  # Should fail with clear message
cd /home/benjamin/.config/nvim && /plan "test feature"  # Should work (subdirectory)
```

**Standards Compliance**:
- ✓ Standard 13: CLAUDE_PROJECT_DIR-based path resolution
- ✓ Standard 15: Library sourcing in dependency order
- ✓ State-based orchestration: Uses workflow-state-machine.sh
- ✓ Explicit over implicit: Clear error messages

### Recommendation 2: Complete Spec 731 Phase 4 (Integration Testing)

**Priority**: HIGH

**Rationale**: Spec 731 Phases 1-3 are complete but untested end-to-end

**Tasks** (from 731 plan.md:288-303):
1. Run integration test: /plan "simple feature" (no research)
2. Run integration test: /plan "complex architecture feature" (with research)
3. Run integration test: /plan "feature" /path/to/report.md (with report paths)
4. Verify all error paths produce clear diagnostic messages
5. Verify no "command not found" errors
6. Verify no "bad substitution" errors
7. Verify research agents invoked when needed
8. Verify plan-architect always invoked
9. Verify verification checkpoints fail-fast

**Implementation**:
Execute spec 731 Phase 4 tasks after applying Recommendation 1 fix.

### Recommendation 3: Update Documentation (Spec 731 Phase 4)

**Priority**: MEDIUM

**Rationale**: Phase 4 documentation tasks remain incomplete

**Files to Update** (from 731 plan.md:346-363):
1. `.claude/docs/guides/plan-command-guide.md`
   - Add §2.5 "CLAUDE_PROJECT_DIR Bootstrap Pattern"
   - Update §3.1 "Phase 0" to reflect inline detection
   - Document why SCRIPT_DIR pattern doesn't work in Claude Code
   - Add troubleshooting for "No such file or directory" library errors

2. `.claude/docs/reference/bash-invocation-standards.md` (from 732 report 001)
   - Document BASH_SOURCE[0] limitation in Claude Code Bash tool
   - Document CLAUDE_PROJECT_DIR bootstrap pattern
   - Document shell context isolation (already covered by 731)

3. `.claude/docs/reference/command-reference.md`
   - Update /plan entry if architectural changes warrant it

**Documentation Standards**:
- Follow CommonMark specification
- No emojis
- Include code examples
- No historical commentary

### Recommendation 4: Create Unified Bootstrap Library Pattern

**Priority**: LOW (Future Enhancement)

**Rationale**: Other commands may have same SCRIPT_DIR issue

**Analysis Needed**:
1. Search all commands for SCRIPT_DIR pattern
2. Identify which commands are affected
3. Create standardized bootstrap pattern library
4. Document pattern in .claude/docs/patterns/

**Scope**: Out of scope for this refactor - requires broader codebase analysis

### Recommendation 5: State Persistence Verification

**Priority**: MEDIUM

**Rationale**: Ensure state-persistence.sh works correctly after path fix

**Verification Points**:
1. Confirm STATE_FILE created successfully (plan.md:88-93)
2. Confirm append_workflow_state writes to STATE_FILE (plan.md:185-192)
3. Confirm state recovery works if workflow interrupted
4. Test graceful degradation if state file corrupted

**Testing**:
```bash
# Test state persistence
/plan "test feature" &
PID=$!
sleep 5
kill $PID  # Interrupt workflow
# Verify STATE_FILE exists and contains expected data
cat "$CLAUDE_PROJECT_DIR/.claude/tmp/workflow_plan_*/state.env"
```

**Standards Compliance**:
- ✓ Selective state persistence (state-based orchestration principle 4)
- ✓ Graceful degradation to stateless recalculation
- ✓ GitHub Actions-style workflow state files

## Technical Design

### Architecture Changes Summary

**Current (Broken)**:
```
Phase 0 bash block:
  SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})  ← FAILS (BASH_SOURCE empty)
  source $SCRIPT_DIR/../lib/detect-project-dir.sh  ← PATH WRONG
  source other libraries  ← NEVER REACHED
```

**After Recommendation 1 (Fixed)**:
```
Phase 0 bash block:
  Inline git-based CLAUDE_PROJECT_DIR detection  ← WORKS
  UTILS_DIR="$CLAUDE_PROJECT_DIR/.claude/lib"  ← ABSOLUTE PATH
  source $UTILS_DIR/workflow-state-machine.sh  ← WORKS
  source other libraries in dependency order  ← WORKS
  Initialize state, calculate paths, persist state  ← WORKS
```

**After Spec 731 Integration (Complete Fix)**:
```
Phase 0 bash block: Bootstrap + library sourcing + state init
Phase 0.1 Task: Haiku complexity classifier (returns JSON)
Phase 0.2 bash block: Parse JSON + generate paths + save state
Phase 1.5: Explicit Task invocations for research agents
  → VERIFICATION CHECKPOINT
Phase 3: Explicit Task invocation for plan-architect
  → VERIFICATION CHECKPOINT
Phase 4: Success confirmation
```

### Key Design Decisions

1. **Inline Bootstrap vs Library**:
   - Decision: Inline CLAUDE_PROJECT_DIR detection in Phase 0
   - Rationale: Eliminates circular dependency, works in Claude Code context
   - Trade-off: 15 lines of duplicate code vs bootstrap complexity

2. **Keep detect-project-dir.sh Library**:
   - Decision: Keep library for other commands
   - Rationale: Other commands may use SCRIPT_DIR successfully
   - Scope: Only plan.md needs inline bootstrap

3. **State Persistence Strategy**:
   - Decision: Continue using state-persistence.sh
   - Rationale: Aligns with state-based orchestration architecture
   - Validation: Verify after path fix applied

4. **Integration with Spec 731**:
   - Decision: Apply Recommendation 1 fix to spec 731 codebase
   - Rationale: 731 Phases 1-3 complete, only missing path fix
   - Approach: Complete 731 Phase 4 after applying path fix

### Dependency Analysis

**Libraries Required** (in order):
1. None (bootstrap inline)
2. workflow-state-machine.sh (sourced after bootstrap)
3. state-persistence.sh
4. error-handling.sh
5. verification-helpers.sh
6. unified-location-detection.sh
7. metadata-extraction.sh

**Agents Required**:
1. plan-complexity-classifier.md (created in 731 Phase 1)
2. research-specialist.md
3. plan-architect.md

**External Dependencies**:
- git (for CLAUDE_PROJECT_DIR detection)
- jq (for JSON processing)
- Standard Unix utilities

### Standards Compliance Matrix

| Standard | Description | Compliance | Evidence |
|----------|-------------|------------|----------|
| Standard 0 | Absolute paths only | ✓ YES | All paths validated with `[[ $PATH =~ ^/ ]]` |
| Standard 11 | Imperative invocation | ✓ YES | Task blocks with "EXECUTE NOW" markers |
| Standard 13 | CLAUDE_PROJECT_DIR detection | ✓ YES | Git-based detection inline |
| Standard 15 | Library sourcing order | ✓ YES | Dependency-ordered sourcing |
| State Machine | Explicit state names | ✓ YES | Uses workflow-state-machine.sh |
| State Persistence | Selective file-based | ✓ YES | Uses state-persistence.sh |
| Verified Transitions | Transition validation | ✓ YES | sm_transition function |

## Implementation Phases

### Phase 1: Apply SCRIPT_DIR Fix to Plan Command

**Objective**: Replace SCRIPT_DIR-based library detection with inline CLAUDE_PROJECT_DIR bootstrap

**Tasks**:
1. Read current plan.md Phase 0 (lines 18-200)
2. Remove SCRIPT_DIR calculation (lines 27-32)
3. Add inline CLAUDE_PROJECT_DIR bootstrap (Recommendation 1 code)
4. Update UTILS_DIR calculation to use CLAUDE_PROJECT_DIR
5. Verify all library source statements use UTILS_DIR
6. Test path detection from multiple directories
7. Verify Standard 13 compliance maintained

**Testing**:
```bash
# Test from project root
cd /home/benjamin/.config && /plan "test from root"

# Test from subdirectory
cd /home/benjamin/.config/nvim && /plan "test from subdirectory"

# Test from outside project (should fail gracefully)
cd /tmp && /plan "test from outside" 2>&1 | grep "Failed to detect project"
```

**Success Criteria**:
- CLAUDE_PROJECT_DIR detected correctly from any subdirectory
- Libraries sourced successfully via absolute paths
- Clear error message if run outside project
- No SCRIPT_DIR references remain

### Phase 2: Integration Testing (Spec 731 Phase 4)

**Objective**: Validate complete workflow end-to-end

**Tasks**:
1. Test simple feature (no research): `/plan "add button"`
2. Test complex feature (with research): `/plan "implement distributed tracing"`
3. Test with provided reports: `/plan "feature" /path/to/report.md`
4. Verify Haiku classifier invoked correctly
5. Verify research agents invoked when complexity ≥ threshold
6. Verify plan-architect invoked for all features
7. Verify verification checkpoints fail-fast
8. Verify semantic filenames generated
9. Verify state persistence works
10. Test error paths and diagnostics

**Success Criteria**:
- All integration tests pass
- No "command not found" errors
- No "bad substitution" errors
- All agents invoked correctly
- Files created at expected paths
- State persisted correctly

### Phase 3: Documentation Updates (Spec 731 Phase 4)

**Objective**: Document architectural changes and troubleshooting

**Tasks**:
1. Update plan-command-guide.md §3.1 "Phase 0"
2. Add plan-command-guide.md §2.5 "CLAUDE_PROJECT_DIR Bootstrap"
3. Update bash-invocation-standards.md (if exists) or create it
4. Document BASH_SOURCE[0] limitation in Claude Code
5. Add troubleshooting entries for path errors
6. Update command-reference.md if needed
7. Review all documentation for accuracy

**Success Criteria**:
- Documentation reflects current implementation
- Troubleshooting guides comprehensive
- Standards compliance documented
- No historical commentary

### Phase 4: Regression Testing and Validation

**Objective**: Ensure no existing functionality broken

**Tasks**:
1. Run existing plan command test suite
2. Verify backward compatibility
3. Test all documented usage examples
4. Validate Standards 0, 11, 13, 15 compliance
5. Verify state-based orchestration patterns maintained
6. Test error recovery and diagnostics
7. Review git diff for unintended changes

**Success Criteria**:
- All existing tests pass
- Backward compatibility maintained
- Standards compliance verified
- No regressions introduced

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Inline bootstrap breaks on non-git projects | Low | Medium | Fallback directory traversal included |
| Library dependencies have undocumented order requirements | Low | High | Test thoroughly, verify sourcing order |
| State persistence fails after path change | Low | Critical | Verification checkpoints will catch |
| Spec 731 changes conflict with path fix | Medium | High | Review 731 commits carefully before applying fix |
| Documentation out of sync with implementation | Medium | Medium | Complete Phase 3 documentation updates |
| Breaking changes for existing /plan users | Low | High | Maintain backward compatibility, test extensively |

## Success Metrics

### Functional Metrics
- ✓ CLAUDE_PROJECT_DIR detected 100% in git projects
- ✓ CLAUDE_PROJECT_DIR detected ≥95% in non-git projects (via fallback)
- ✓ Zero "command not found" errors for library functions
- ✓ Zero "bad substitution" errors
- ✓ 100% agent invocation success rate
- ✓ 100% file creation at expected paths

### Performance Metrics
- ≤2ms for CLAUDE_PROJECT_DIR detection (git-based, per state orchestration docs)
- ≤10ms total library sourcing overhead
- No regression vs current performance (when working)

### Quality Metrics
- 100% standards compliance (Standards 0, 11, 13, 15)
- 100% state-based orchestration pattern compliance
- ≥80% test coverage (per CLAUDE.md testing protocols)
- Clear diagnostic messages for all failure modes

## References

### Primary Failure Source
- `/home/benjamin/.config/.claude/specs/plan_output.md:240-247` - SCRIPT_DIR path resolution failure
- `/home/benjamin/.config/.claude/specs/plan_output.md:162-174` - Shell context isolation failure

### Spec 731 (Partial Fix)
- `/home/benjamin/.config/.claude/specs/731_claude_specs_plan_outputmd_and_create_a_clear/plans/001_plan.md:1-439` - Implementation plan
- `/home/benjamin/.config/.claude/specs/731_claude_specs_plan_outputmd_and_create_a_clear/reports/001_topic1.md:1-239` - Root cause analysis

### Plan Command Implementation
- `/home/benjamin/.config/.claude/commands/plan.md:1-947` - Complete command specification
- `/home/benjamin/.config/.claude/commands/plan.md:27-32` - Broken SCRIPT_DIR calculation
- `/home/benjamin/.config/.claude/commands/plan.md:24` - set +H location

### State-Based Orchestration Architecture
- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md:1-150` - Architecture principles
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` - State machine library
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` - State persistence library

### Library Dependencies
- `/home/benjamin/.config/.claude/lib/detect-project-dir.sh:1-50` - Git-based detection pattern (reference)
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh:88-240` - Location detection functions

### Related Documentation
- `/home/benjamin/.config/CLAUDE.md` - Project standards (Standard 0, 11, 13, 15)
- `/home/benjamin/.config/.claude/docs/guides/plan-command-guide.md` - Plan command guide (to update)
- `/home/benjamin/.config/.claude/docs/reference/command-reference.md` - Command reference (to update)

### Git Commits (Spec 731)
- `5bd8ed60` - feat(731): complete Phase 1 - Replace bash complexity analysis with Haiku subagent
- `cd1b9097` - feat(731): complete Phase 2 - Add explicit Task invocations for research delegation
- `194a6090` - feat(731): complete Phase 3 - Add explicit Task invocation for plan-architect
- `f111dceb` - docs(731): update plan file with Phases 1-3 completion status

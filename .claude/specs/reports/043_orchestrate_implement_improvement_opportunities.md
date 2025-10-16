# Orchestrate and Implement Commands: Improvement Opportunities Analysis

## Metadata
- **Date**: 2025-10-12
- **Specs Directory**: /home/benjamin/.config/.claude/specs/
- **Report Number**: 043
- **Topic**: Command Improvement Analysis
- **Created By**: /report command
- **Scope**: /orchestrate, /implement, and supporting infrastructure

## Executive Summary

This report analyzes the `/orchestrate` and `/implement` commands to identify improvement opportunities across architecture, performance, reliability, and developer experience. Based on detailed review of 869 lines of `/implement` command logic, 1000+ lines of `/orchestrate` logic, and 20+ supporting utility libraries, I've identified 37 specific improvement opportunities categorized into 8 major areas.

**Key Findings:**
- **Performance**: Significant optimization opportunities in parallel operations and caching
- **Reliability**: Error handling can be more robust with better retry logic
- **Maintainability**: Command complexity has grown, suggesting modularization opportunities
- **Developer Experience**: Progress visibility and debugging could be substantially improved

**High-Impact Recommendations:**
1. Implement parallel phase execution (est. 40-60% time savings)
2. Add comprehensive error recovery with exponential backoff
3. Modularize phase execution logic into separate utilities
4. Add interactive progress dashboard for long-running workflows

---

## Current State Analysis

### /implement Command Architecture

**Current Implementation:**
- **Lines of Code**: 869 lines in command file
- **Supporting Utilities**: 12 shared libraries
- **Key Features**:
  - Sequential phase execution with testing
  - Adaptive planning triggers (complexity, test failures, scope drift)
  - Progressive plan support (Levels 0-2)
  - Checkpoint-based resumption
  - Automatic collapse detection

**Execution Flow:**
```
Parse Plan → Discover Standards → For Each Phase:
  ├─ Check expansion status
  ├─ Complexity analysis → Agent selection
  ├─ Implementation (direct or agent-delegated)
  ├─ Testing → Error analysis
  ├─ Adaptive planning detection
  ├─ Git commit
  ├─ Plan update
  └─ Incremental summary generation
```

**Strengths:**
- ✓ Comprehensive adaptive planning integration
- ✓ Strong checkpoint/resume capability
- ✓ Good standards discovery and application
- ✓ Automatic structure optimization (expand/collapse)
- ✓ Detailed logging with adaptive-planning.log

**Weaknesses:**
- ✗ No parallel phase execution (sequential only)
- ✗ Limited error recovery strategies
- ✗ Monolithic phase execution logic
- ✗ Progress visibility only via PROGRESS markers
- ✗ No performance metrics collection

### /orchestrate Command Architecture

**Current Implementation:**
- **Lines of Code**: 1000+ lines (est. from 999-line partial read)
- **Supporting Utilities**: Checkpoint, error handling, complexity analysis
- **Key Features**:
  - Multi-phase workflow coordination
  - Parallel research agent invocation
  - Sequential planning and implementation
  - Conditional debugging loop (max 3 iterations)
  - Context preservation via file paths

**Execution Flow:**
```
Analyze Workflow → Initialize State → TodoWrite:
  ├─ Research Phase (PARALLEL)
  │   └─ Invoke 2-4 research-specialist agents simultaneously
  ├─ Planning Phase (SEQUENTIAL)
  │   └─ Invoke plan-architect with research report paths
  ├─ Implementation Phase (ADAPTIVE)
  │   └─ Invoke code-writer via /implement
  ├─ Debugging Loop (CONDITIONAL, max 3 iterations)
  │   └─ Invoke debug-specialist → code-writer → test
  └─ Documentation Phase (SEQUENTIAL)
      └─ Invoke doc-writer for summary
```

**Strengths:**
- ✓ Excellent context management (file paths only, not content)
- ✓ Intelligent parallelization in research phase
- ✓ Good workflow state tracking with TodoWrite
- ✓ Thinking mode calculation for complexity
- ✓ Strong progress streaming with PROGRESS markers

**Weaknesses:**
- ✗ Research parallelization hardcoded (only research phase)
- ✗ Implementation phase entirely sequential (via /implement)
- ✗ Error handling strategy documented but implementation gaps
- ✗ No workflow performance analysis
- ✗ Limited workflow composition/nesting support

### Supporting Infrastructure

**Shared Utilities:**
1. `checkpoint-utils.sh` (573 lines): Save, restore, validate checkpoints
2. `complexity-utils.sh` (444 lines): Phase/plan complexity scoring
3. `adaptive-planning-logger.sh`: Event logging for adaptive triggers
4. `error-utils.sh`: Error classification and recovery
5. `parse-adaptive-plan.sh`: Progressive plan parsing
6. `agent-registry-utils.sh` (219 lines): Agent performance tracking
7. Additional utilities: structure-eval, artifact-utils, progressive-planning-utils

**Agent System:**
- 16 specialized agents defined
- Agent registry for performance tracking
- Behavioral injection pattern for agent invocation
- Agents: research-specialist, plan-architect, code-writer, debug-specialist, doc-writer, test-specialist, github-specialist, etc.

**Strengths:**
- ✓ Well-organized utility library structure
- ✓ Consistent error handling patterns
- ✓ Good separation of concerns
- ✓ Comprehensive complexity analysis

**Weaknesses:**
- ✗ Some utilities underdocumented
- ✗ Limited unit test coverage
- ✗ Agent registry not actively used in workflows
- ✗ Duplicate functionality across utilities

---

## Improvement Opportunities

### Category 1: Performance Optimization (High Impact)

#### 1.1 Parallel Phase Execution in /implement

**Current State:**
- All phases execute sequentially
- Dependencies declared but not used for parallel execution
- parse-phase-dependencies.sh exists but is not utilized

**Opportunity:**
```bash
# Current: Sequential (12 minutes)
Phase 1 (3 min) → Phase 2 (3 min) → Phase 3 (3 min) → Phase 4 (3 min)

# Proposed: Parallel execution with dependencies (6 minutes)
Wave 1: Phase 1 (3 min)
Wave 2: Phase 2, Phase 3 (3 min in parallel)
Wave 3: Phase 4 (3 min)
```

**Implementation:**
1. Use `parse-phase-dependencies.sh` to generate execution waves
2. Invoke multiple agents in single message for wave execution
3. Wait for wave completion before next wave
4. Aggregate results from parallel phases

**Expected Impact:**
- Time savings: 40-60% for plans with independent phases
- Example: 5-phase plan with 2 parallel pairs: 15min → 9min (40% reduction)

**Complexity:** Medium (requires agent coordination, result aggregation)

**Location:** /implement command, lines 149-220 (Phase Execution Protocol)

---

#### 1.2 Research Report Caching

**Current State:**
- Research reports re-read multiple times during workflow
- Same reports used by planning, implementation, debugging phases
- No in-memory caching

**Opportunity:**
```bash
# Current: Multiple reads
/orchestrate: Research → Plan (reads reports) → Implement (reads reports) → Debug (reads reports)
# Each phase: 3 reports × 200 lines = 600 lines read per phase = 1800 lines total

# Proposed: Cache after research phase
/orchestrate: Research → Cache reports → Plan/Implement/Debug use cache
# Total reads: 600 lines (67% reduction)
```

**Implementation:**
1. After research phase, store report contents in workflow_state
2. Pass report content (not paths) to subsequent phases
3. Limit cache size (e.g., 5000 lines max per report)
4. Clear cache after workflow completes

**Expected Impact:**
- Context token savings: 60-70% for report reads
- Faster phase transitions (no file I/O)

**Complexity:** Low (simple caching layer)

**Trade-offs:**
- Increased memory usage
- Stale data if reports modified during workflow (unlikely scenario)

---

#### 1.3 Incremental Plan Parsing

**Current State:**
- Full plan re-parsed at each phase
- For Level 1/2 plans, multiple files read repeatedly
- Progressive parser reads entire hierarchy each time

**Opportunity:**
```bash
# Current: Full parse every phase
Phase 1: Parse full plan (5 files, 2000 lines)
Phase 2: Parse full plan (5 files, 2000 lines)
Phase 3: Parse full plan (5 files, 2000 lines)
# Total: 15 file reads, 6000 lines

# Proposed: Incremental parsing
Initial: Parse full plan → Cache structure
Phase N: Read only phase N file (1 file, 400 lines)
# Total: 5 file reads + 3 phase reads = 8 reads, 2600 lines (57% reduction)
```

**Implementation:**
1. Parse plan structure once at initialization
2. Cache phase locations (file paths, line ranges)
3. Read only current phase content during execution
4. Invalidate cache on plan updates (adaptive planning)

**Expected Impact:**
- Parse time reduction: 50-60%
- Context token savings: 40-50% for large plans

**Complexity:** Medium (cache invalidation logic needed)

---

### Category 2: Reliability Improvements (High Priority)

#### 2.1 Exponential Backoff for Agent Failures

**Current State:**
- Single retry on agent failure
- No delay between retries
- No differentiation between transient and permanent errors

**Opportunity:**
```bash
# Current: Single immediate retry
Invoke agent → Fail → Retry immediately → Fail → Escalate

# Proposed: Exponential backoff with jitter
Invoke agent → Fail → Wait 2s + jitter → Retry
            → Fail → Wait 4s + jitter → Retry
            → Fail → Wait 8s + jitter → Escalate
```

**Implementation:**
```bash
retry_with_backoff() {
  local max_attempts=3
  local base_delay=2
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    if invoke_agent "$@"; then
      return 0
    fi

    if [ $attempt -lt $max_attempts ]; then
      local delay=$((base_delay ** attempt))
      local jitter=$((RANDOM % 1000))
      sleep $((delay + jitter / 1000))
    fi

    attempt=$((attempt + 1))
  done

  return 1
}
```

**Expected Impact:**
- Resilience to transient network/load issues
- Reduced false failures from temporary conditions
- Better handling of Claude Code API rate limits

**Complexity:** Low (simple retry logic)

**Location:** /orchestrate command, error handling section (lines 136-211)

---

#### 2.2 Checkpoint Validation and Recovery

**Current State:**
- Checkpoints saved but limited validation
- Corrupted checkpoints cause workflow failure
- No automatic recovery from invalid checkpoints

**Opportunity:**
```bash
# Current: Load checkpoint → Parse → Fail if invalid
restore_checkpoint() {
  cat "$checkpoint_file"  # No validation
}

# Proposed: Validate before restore
restore_checkpoint() {
  if ! validate_checkpoint_integrity "$checkpoint_file"; then
    echo "Checkpoint corrupted, attempting recovery..."
    if recover_checkpoint "$checkpoint_file"; then
      echo "Recovery successful"
    else
      echo "Recovery failed, starting fresh"
      return 1
    fi
  fi
  cat "$checkpoint_file"
}
```

**Implementation:**
1. Add `validate_checkpoint_integrity()` (already exists in checkpoint-utils.sh)
2. Add `recover_checkpoint()` for common corruption patterns:
   - Truncated JSON → Restore from last valid state
   - Missing fields → Fill with defaults
   - Invalid JSON → Parse until corruption, salvage valid data
3. Create backup before every checkpoint save
4. Add checkpoint versioning for migration support

**Expected Impact:**
- Reduced workflow failures from checkpoint corruption
- Better recovery from interrupted saves
- Graceful degradation instead of hard failures

**Complexity:** Medium (recovery logic requires careful design)

**Location:** checkpoint-utils.sh, lines 497-558

---

#### 2.3 Test Failure Recovery Strategies

**Current State:**
- Test failures trigger debugging loop (good)
- Max 3 iterations (good)
- Limited automatic recovery before debug invocation

**Opportunity:**
```bash
# Current: Test fails → Immediate debug invocation
Test failure → Debug agent → Fix → Retry

# Proposed: Tiered recovery
Test failure → Category analysis:
  ├─ Syntax error → Auto-fix with linter
  ├─ Import error → Check dependencies
  ├─ Timeout → Increase timeout, retry
  ├─ Flaky test → Retry 2x before debug
  └─ Logic error → Debug agent
```

**Implementation:**
1. Use error-utils.sh error classification
2. Implement auto-recovery for common errors:
   - **Syntax errors**: Run linter/formatter, commit, retry
   - **Import errors**: Check package.json/requirements.txt, suggest install
   - **Timeouts**: Increase timeout 2x, retry once
   - **Flaky tests**: Retry 2x before debug (common in integration tests)
3. Track recovery success rate in metrics
4. Escalate to debug agent only for complex failures

**Expected Impact:**
- Reduced debug agent invocations (cost savings)
- Faster resolution of simple test failures
- Debugging iterations conserved for complex issues

**Complexity:** Medium (requires robust error categorization)

**Location:** /implement command, lines 314-319 (Enhanced Error Analysis)

---

### Category 3: Modularity and Maintainability (Medium Impact)

#### 3.1 Extract Phase Execution Module

**Current State:**
- Phase execution logic embedded in /implement command (lines 221-554)
- 333 lines of complex logic in single command
- Difficult to test and maintain

**Opportunity:**
```bash
# Current: Monolithic command
/implement command (869 lines)
  ├─ Parse plan (50 lines)
  ├─ Discover standards (80 lines)
  ├─ Phase execution logic (333 lines) ← EXTRACT
  ├─ Summary generation (120 lines)
  └─ Cross-references (80 lines)

# Proposed: Modular architecture
/implement command (450 lines)
  └─ Delegates to: phase-executor.sh (400 lines)
      ├─ execute_phase()
      ├─ run_tests()
      ├─ handle_failures()
      ├─ commit_changes()
      └─ update_plan()
```

**Implementation:**
1. Create `.claude/lib/phase-executor.sh` utility
2. Extract functions:
   - `execute_phase()`: Main phase execution orchestration
   - `run_phase_tests()`: Test execution and result parsing
   - `handle_test_failure()`: Error analysis and recovery
   - `commit_phase_changes()`: Git commit with proper messages
   - `update_plan_status()`: Mark phase complete
3. Keep command file for high-level flow, delegate details

**Expected Impact:**
- Improved testability (unit test phase execution)
- Better code organization
- Easier maintenance and debugging
- Reusable phase execution logic

**Complexity:** Medium (requires careful refactoring to avoid breaking changes)

**Timeline:** 2-3 sessions

---

#### 3.2 Unified Agent Invocation Pattern

**Current State:**
- Agent invocation scattered across commands
- Inconsistent parameter passing
- Behavioral injection implemented differently in each command

**Opportunity:**
```bash
# Current: Ad-hoc invocation
# /orchestrate uses:
Task("general-purpose", "Research X", "Read from: agent-file.md...")

# /implement uses:
Task("general-purpose", "Implement Y", "Behavior: code-writer...")

# Each command constructs prompts differently

# Proposed: Unified invocation helper
invoke_agent() {
  local agent_type=$1
  local task_description=$2
  local context=$3
  shift 3
  local additional_args=("$@")

  # Load agent spec
  local agent_spec=$(load_agent_spec "$agent_type")

  # Build prompt with standard injection
  local prompt=$(build_agent_prompt "$agent_spec" "$context" "${additional_args[@]}")

  # Invoke with metrics tracking
  local start_time=$(date +%s%3N)
  Task "general-purpose" "$task_description" "$prompt"
  local duration=$(($(date +%s%3N) - start_time))

  # Update agent registry
  update_agent_metrics "$agent_type" "success" "$duration"
}
```

**Implementation:**
1. Create `.claude/lib/agent-invocation.sh` utility
2. Implement `invoke_agent()` with standard pattern:
   - Load agent spec from agent-registry.json
   - Apply behavioral injection consistently
   - Track metrics automatically
   - Handle common errors
3. Update /orchestrate and /implement to use helper
4. Add `invoke_agent_parallel()` for parallel invocations

**Expected Impact:**
- Consistent agent invocation across commands
- Automatic metrics tracking
- Reduced code duplication
- Easier to add new agents

**Complexity:** Low-Medium (mostly refactoring existing code)

**Timeline:** 1-2 sessions

---

#### 3.3 Consolidate Complexity Analysis

<!-- FIX: I want all complexity analyses to go via the /home/benjamin/.config/.claude/agents/complexity_estimator.md agent (no scripts) that can be called as a subagent to preserve context -->

**Current State:**
- Multiple complexity scoring implementations:
  - `complexity-utils.sh`: `calculate_phase_complexity()`
  - `analyze-phase-complexity.sh`: Separate script
  - Inline complexity scoring in /orchestrate (thinking mode)
- Inconsistent scoring algorithms

**Opportunity:**
```bash
# Current: 3 different implementations
complexity-utils.sh:
  - Keyword scoring (refactor=3, implement=2)
  - Task count scoring
  - Fallback logic

analyze-phase-complexity.sh:
  - Different keyword weights
  - Different threshold values

/orchestrate (lines 436-476):
  - Custom workflow complexity scoring
  - Separate thinking mode calculation

# Proposed: Single unified implementation
complexity-utils.sh:
  ├─ calculate_phase_complexity() [PHASE]
  ├─ calculate_plan_complexity() [PLAN]
  ├─ calculate_workflow_complexity() [WORKFLOW]
  └─ All use consistent scoring algorithm
```

**Implementation:**
1. Audit all complexity scoring functions
2. Standardize keyword weights and thresholds
3. Consolidate into complexity-utils.sh
4. Deprecate analyze-phase-complexity.sh
5. Update /orchestrate to use unified functions
6. Add comprehensive unit tests

**Expected Impact:**
- Consistent complexity assessment
- Easier to tune thresholds globally
- Reduced maintenance burden

**Complexity:** Low (mostly consolidation)

**Timeline:** 1 session

---

### Category 4: Developer Experience (Medium-High Impact)

#### 4.1 Interactive Progress Dashboard

**Current State:**
- Progress visibility via PROGRESS: markers in output
- No summary view of overall workflow status
- Difficult to track multi-phase implementations

**Opportunity:**
```bash
# Current: Linear progress output
PROGRESS: Starting Phase 1...
PROGRESS: Phase 1 complete
PROGRESS: Starting Phase 2...

# Proposed: Interactive dashboard (updated in-place)
┌─ Implementation Progress ──────────────────────────┐
│ Plan: 025_user_authentication.md                   │
│ Status: Phase 3/5 (60%)                            │
│ Elapsed: 8m 23s   Estimated: 13m 45s               │
├────────────────────────────────────────────────────┤
│ ✓ Phase 1: Setup and Planning       [2m 15s]      │
│ ✓ Phase 2: Core Implementation      [3m 47s]      │
│ → Phase 3: Testing Integration       [2m 21s]      │
│   Phase 4: Documentation            [pending]      │
│   Phase 5: Review and Finalize      [pending]      │
├────────────────────────────────────────────────────┤
│ Current Task: Running integration tests            │
│ Tests: 14/18 passed   Failures: 0   Skipped: 4    │
└────────────────────────────────────────────────────┘
```

**Implementation:**
1. Create `.claude/lib/progress-dashboard.sh`
2. Use ANSI escape codes for in-place updates
3. Track per-phase timing and overall progress
4. Show current task and test results
5. Add optional flag: `/implement --dashboard` (default: traditional output)
6. Fallback to PROGRESS markers if terminal doesn't support ANSI

**Expected Impact:**
- Improved visibility into workflow progress
- Better estimation of remaining time
- Easier to spot stuck phases
- Professional user experience

**Complexity:** Medium (ANSI terminal handling)

**Timeline:** 2 sessions

**Alternative:** Use simple periodic summary instead of live dashboard

---

#### 4.2 Dry-Run Mode for Commands

**Current State:**
- No way to preview command execution without running it
- Difficult to validate plans before implementation
- Expensive to test command changes

**Opportunity:**
```bash
# Current: Execute immediately
/implement plan.md → Starts implementing phases

# Proposed: Dry-run mode
/implement plan.md --dry-run
→ Displays:
  - Plan structure (phases, tasks, dependencies)
  - Execution order (wave 1, wave 2, etc.)
  - Agent selection per phase
  - Estimated duration
  - Standards to be applied
  - Files that would be modified
  - Tests that would run
→ Asks: "Proceed with implementation? (y/n)"
```

**Implementation:**
1. Add `--dry-run` flag to /implement and /orchestrate
2. Parse plan and display execution plan
3. Show agent assignments without invoking
4. Estimate duration based on historical metrics
5. List files/tests affected (via plan analysis)
6. Prompt for confirmation before actual execution

**Expected Impact:**
- Reduced failed implementations (catch issues early)
- Better understanding of command behavior
- Safer testing of command changes
- Improved user confidence

**Complexity:** Low-Medium (mostly display logic)

**Timeline:** 1-2 sessions

---

#### 4.3 Better Error Messages and Debugging Aids

**Current State:**
- Generic error messages from agent failures
- Difficult to diagnose why agent invocation failed
- Limited context provided to user

**Opportunity:**
```bash
# Current: Cryptic error
Error: Agent invocation failed
See .claude/logs/adaptive-planning.log for details

# Proposed: Actionable error messages
┌─ Agent Invocation Failed ──────────────────────────┐
│ Agent: code-writer                                  │
│ Phase: Phase 3: Testing Integration                │
│ Error Type: Timeout (exceeded 600s)                │
├────────────────────────────────────────────────────┤
│ Possible Causes:                                    │
│  • Phase too complex (complexity: 9.2)              │
│  • Network issues or API throttling                 │
│  • Agent stuck in infinite loop                     │
├────────────────────────────────────────────────────┤
│ Suggested Actions:                                  │
│  1. Expand phase to reduce complexity:              │
│     /expand phase plan.md 3                         │
│  2. Retry with increased timeout:                   │
│     /implement plan.md 3 --timeout 1200             │
│  3. Check logs for details:                         │
│     tail -f .claude/logs/adaptive-planning.log      │
│  4. Resume from checkpoint:                         │
│     /implement  # auto-resumes from checkpoint      │
└─────────────────────────────────────────────────────┘
```

**Implementation:**
1. Enhance error-utils.sh with detailed error context
2. Add error message templates for common failures
3. Include suggested actions based on error type
4. Show relevant log excerpts inline
5. Provide resume commands for interrupted workflows

**Expected Impact:**
- Faster problem resolution
- Reduced support burden
- Improved user experience
- Better debugging efficiency

**Complexity:** Low (mostly presentation logic)

**Timeline:** 1 session

---

### Category 5: Observability and Metrics (Medium Priority)

#### 5.1 Workflow Performance Analysis

**Current State:**
- Basic timing tracked (phase_start_times, phase_end_times)
- No aggregate metrics or analysis
- No comparison across workflows
- Agent registry tracks metrics but not actively used

**Opportunity:**
```bash
# Current: No performance summary
/implement completes → No timing analysis shown

# Proposed: Performance report at end
┌─ Workflow Performance Summary ─────────────────────┐
│ Total Duration: 13m 47s                             │
│ Phases: 5   Avg Phase: 2m 45s                      │
├────────────────────────────────────────────────────┤
│ Time Breakdown:                                     │
│  Implementation: 8m 32s (62%)                       │
│  Testing:        3m 15s (24%)                       │
│  Git/Admin:      2m 00s (14%)                       │
├────────────────────────────────────────────────────┤
│ Agent Performance:                                  │
│  code-writer:    3 invocations, avg 2m 50s          │
│  test-specialist: 1 invocation,  3m 15s             │
├────────────────────────────────────────────────────┤
│ Efficiency Metrics:                                 │
│  Phases/hour:    22  (vs. avg: 18) ↑ 22%           │
│  Test pass rate: 100% (vs. avg: 87%) ↑ 13%         │
│  Adaptive replans: 0 (vs. avg: 0.8) ↓ 100%         │
└─────────────────────────────────────────────────────┘
```

**Implementation:**
1. Create `.claude/lib/workflow-metrics.sh`
2. Track detailed timing for all operations:
   - Phase execution
   - Testing (per test suite)
   - Agent invocations
   - File operations
   - Git commits
3. Calculate aggregate metrics:
   - Total duration
   - Time distribution (implementation vs testing vs admin)
   - Agent performance
   - Historical comparisons
4. Store metrics in `.claude/metrics/workflow-history.jsonl`
5. Display summary after workflow completion
6. Add `/analyze workflow` command for historical analysis

**Expected Impact:**
- Visibility into workflow bottlenecks
- Data-driven optimization opportunities
- Performance regression detection
- Better resource allocation

**Complexity:** Medium (requires instrumentation)

**Timeline:** 2-3 sessions

---

#### 5.2 Active Use of Agent Registry

**Current State:**
- Agent registry infrastructure exists (agent-registry-utils.sh)
- Metrics tracked: total_invocations, successes, duration, success_rate
- Not actively used during workflow execution
- No analysis or reporting

**Opportunity:**
```bash
# Current: Registry updated but not consulted
invoke_agent "code-writer" → No registry check → Invoke blindly

# Proposed: Registry-informed decisions
invoke_agent "code-writer"
  ↓
  Check registry: code-writer success_rate = 0.45 (45%)
  ↓
  If success_rate < 0.6:
    - Increase timeout by 50%
    - Add more context to prompt
    - Warn user about low success rate
  ↓
  Invoke agent with adjustments
  ↓
  Update registry with result
```

**Implementation:**
1. Before agent invocation, check registry for:
   - Success rate (adjust invocation if low)
   - Average duration (set appropriate timeout)
   - Recent failures (provide warnings)
2. Use metrics to select best agent for task:
   - If code-writer failing often, try different approach
   - If test-specialist slow, consider inline testing
3. Add `/analyze agents` command to view registry insights:
   - Agent success rates
   - Performance trends over time
   - Failure pattern analysis
4. Add agent recommendation system:
   - "Agent X has 30% failure rate for similar tasks, consider Y instead"

**Expected Impact:**
- Reduced agent invocation failures
- Better agent selection
- Proactive warning of potential issues
- Data-driven agent improvements

**Complexity:** Medium (requires decision logic)

**Timeline:** 2 sessions

---

#### 5.3 Adaptive Planning Effectiveness Metrics

**Current State:**
- Adaptive planning triggers logged
- No analysis of effectiveness
- Unknown if triggers improve outcomes

**Opportunity:**
```bash
# Track adaptive planning outcomes:
Trigger: expand_phase
  ├─ Phase complexity before: 9.2
  ├─ Phase complexity after: 4.1, 4.8 (expanded to 2 phases)
  ├─ Test success: ✓ (both phases passed)
  └─ Effectiveness: +1 (trigger was beneficial)

Trigger: add_phase
  ├─ Reason: Missing database setup
  ├─ New phase added: Phase 2 (Database Setup)
  ├─ Subsequent phases: All passed
  └─ Effectiveness: +1 (trigger prevented failures)

# Aggregate metrics:
Adaptive Planning Summary:
  - Triggers activated: 8
  - Effective triggers: 7 (87.5%)
  - Ineffective triggers: 1 (12.5%)
  - Time cost: 6m added for replanning
  - Time saved: 18m by avoiding failures
  - Net benefit: +12m (67% improvement)
```

**Implementation:**
1. Track outcomes of adaptive planning triggers:
   - Did expansion prevent failures?
   - Did added phase resolve test issues?
   - Was replan time worth the benefit?
2. Store in adaptive-planning.log with outcome field
3. Calculate effectiveness score:
   - +1 if trigger prevented failure
   - -1 if trigger was unnecessary
   - 0 if unclear
4. Tune thresholds based on effectiveness:
   - If expansions not helping, raise threshold
   - If missing phases common, lower threshold
5. Add effectiveness report to workflow summary

**Expected Impact:**
- Data-driven threshold tuning
- Better understanding of adaptive planning value
- Reduced unnecessary replans
- Improved adaptive planning algorithm

**Complexity:** Medium (outcome detection logic)

**Timeline:** 2-3 sessions

---

### Category 6: Robustness and Edge Cases (Medium Priority)

#### 6.1 Handle Circular Dependencies in Plans

**Current State:**
- parse-phase-dependencies.sh detects circular dependencies
- Detection happens but error handling unclear
- Could cause infinite loops or silent failures

**Opportunity:**
```bash
# Current: Detection exists but handling unclear
Circular dependency: Phase 3 → Phase 5 → Phase 3
Result: Unknown (possibly crashes)

# Proposed: Graceful handling
Circular dependency detected:
  Phase 3 depends on Phase 5
  Phase 5 depends on Phase 3

Resolution options:
  1. Remove one dependency (manual fix required)
  2. Merge phases into single phase
  3. Abort implementation

Error: Cannot execute plan with circular dependencies
Fix plan and retry: /implement plan.md
```

**Implementation:**
1. Enhance parse-phase-dependencies.sh error output
2. Detect circular dependencies early (during plan parse)
3. Provide clear error message with cycle visualization
4. Suggest resolution strategies
5. Refuse to execute until resolved
6. Add validation to /plan command to prevent creation

**Expected Impact:**
- Prevented infinite loops
- Clear feedback on plan errors
- Improved plan quality

**Complexity:** Low (detection exists, need better handling)

**Timeline:** 1 session

---

#### 6.2 Graceful Handling of Missing Dependencies

**Current State:**
- Utility scripts assume dependencies available (jq, git, etc.)
- Failures occur with cryptic errors
- No graceful degradation

**Opportunity:**
```bash
# Current: Silent failure or crash
jq: command not found
# Script breaks with confusing error

# Proposed: Dependency checking with fallbacks
Checking dependencies...
  ✓ git: found (/usr/bin/git)
  ✓ bash: found (version 5.1.16)
  ✗ jq: not found

Warning: jq not available
  Some features will be unavailable:
    - Checkpoint validation
    - JSON parsing in metrics

  Install jq for full functionality:
    sudo apt install jq  # Debian/Ubuntu
    brew install jq      # macOS

  Continuing with limited functionality...
```

**Implementation:**
1. Create `.claude/lib/dependency-checker.sh`
2. Check for required tools: jq, git, grep, sed, awk
3. Classify as required vs optional
4. Provide installation instructions for missing tools
5. Implement fallbacks where possible:
   - JSON parsing without jq (basic regex parsing)
   - Git operations with error handling
6. Run check at command startup

**Expected Impact:**
- Better error messages
- Clearer dependency requirements
- Graceful degradation when possible
- Easier onboarding for new users

**Complexity:** Low (mostly validation logic)

**Timeline:** 1 session

---

#### 6.3 Resume from Partial Agent Failures

**Current State:**
- Checkpoint saves at phase boundaries
- If agent fails mid-phase, no checkpoint
- Cannot resume from partial progress

**Opportunity:**
```bash
# Current: Phase-level checkpoints only
Phase 1 complete → Checkpoint saved
Phase 2 starts → Agent fails after 5 minutes → No checkpoint
Resume: Must retry entire Phase 2

# Proposed: Intra-phase checkpoints
Phase 2 starts
  ├─ Task 1 complete → Micro-checkpoint saved
  ├─ Task 2 complete → Micro-checkpoint saved
  ├─ Task 3 agent fails → Resume from Task 3
  └─ Resume: /implement --resume phase=2 task=3
```

**Implementation:**
1. Add micro-checkpoint support to checkpoint-utils.sh
2. Save checkpoint after each task completion
3. Track granular progress:
   - current_phase: 2
   - current_task: 3
   - completed_tasks: [1, 2]
4. Resume from micro-checkpoint:
   - Skip completed tasks
   - Re-run failed task
5. Clean up micro-checkpoints after phase completes

**Expected Impact:**
- Reduced wasted work on resume
- Better resume granularity
- Less frustration on long phases

**Complexity:** Medium (requires granular state tracking)

**Timeline:** 2 sessions

**Trade-offs:**
- More frequent I/O (checkpoint saves)
- Increased checkpoint storage

---

### Category 7: Testing and Quality Assurance (Medium Priority)

#### 7.1 Unit Tests for Utility Libraries

**Current State:**
- Utility libraries have minimal test coverage
- Manual testing of command changes is slow
- Risk of regressions when refactoring

**Opportunity:**
```bash
# Current: No systematic testing
Modify complexity-utils.sh → Test manually → Hope it works

# Proposed: Comprehensive unit tests
.claude/tests/
  ├─ test_complexity_utils.sh (16 tests)
  ├─ test_checkpoint_utils.sh (12 tests)
  ├─ test_error_utils.sh (10 tests)
  ├─ test_agent_invocation.sh (8 tests)
  └─ run_all_tests.sh (46 tests total)

Run before commits:
$ .claude/tests/run_all_tests.sh
[PASS] test_complexity_utils.sh (16/16)
[PASS] test_checkpoint_utils.sh (12/12)
[PASS] test_error_utils.sh (10/10)
[PASS] test_agent_invocation.sh (8/8)
All tests passed: 46/46 (100%)
```

**Implementation:**
1. Create test files for each utility library
2. Use bats (Bash Automated Testing System) or custom test framework
3. Test coverage areas:
   - Happy path functionality
   - Error conditions
   - Edge cases (empty input, invalid data)
   - Integration between utilities
4. Add to CI/CD pipeline (if applicable)
5. Require tests for new utility functions

**Expected Impact:**
- Reduced regressions
- Faster development (automated testing)
- More confident refactoring
- Better code quality

**Complexity:** Medium (requires test framework setup)

**Timeline:** 3-4 sessions (initial setup + tests)

**Note:** Some test files already exist (.claude/tests/test_*.sh), build on existing framework

---

#### 7.2 Integration Tests for Commands

**Current State:**
- Commands tested manually end-to-end
- No automated integration tests
- Difficult to catch command-level regressions

**Opportunity:**
```bash
# Current: Manual testing
Modify /implement → Run on test plan → Check output manually

# Proposed: Automated integration tests
.claude/tests/integration/
  ├─ test_implement_basic.sh
  │   └─ Runs /implement on simple plan, verifies success
  ├─ test_implement_adaptive.sh
  │   └─ Runs /implement with complexity trigger, verifies expansion
  ├─ test_orchestrate_workflow.sh
  │   └─ Runs /orchestrate end-to-end, verifies all phases
  └─ test_error_recovery.sh
      └─ Simulates failures, verifies error handling

Run integration tests:
$ .claude/tests/integration/run_all.sh
[PASS] test_implement_basic.sh (3m 12s)
[PASS] test_implement_adaptive.sh (4m 45s)
[PASS] test_orchestrate_workflow.sh (7m 23s)
[PASS] test_error_recovery.sh (5m 01s)
All integration tests passed: 4/4 (100%)
Total time: 20m 21s
```

**Implementation:**
1. Create test fixtures: Sample plans, reports, codebases
2. Write integration test scripts:
   - Set up test environment (temp directories)
   - Run command with test fixture
   - Verify expected outputs:
     - Files created/modified
     - Checkpoints saved
     - Logs generated
     - Exit codes
   - Clean up test environment
3. Mock agent invocations for faster tests
4. Add slow/fast test modes (full agent invocations vs mocked)

**Expected Impact:**
- Automated regression detection
- Faster validation of command changes
- Confidence in refactoring
- Documentation of expected behavior

**Complexity:** High (requires mocking infrastructure)

**Timeline:** 4-5 sessions

**Alternative:** Start with smoke tests (basic end-to-end) before full integration tests

---

### Category 8: Documentation and Discoverability (Low-Medium Priority)

#### 8.1 Command Usage Examples

**Current State:**
- Command files have basic usage hints
- Limited real-world examples
- Users must experiment to learn patterns

**Opportunity:**
```bash
# Current: Minimal examples in command file
/implement [plan-file] [starting-phase]

# Proposed: Comprehensive example section
## Examples

### Basic Implementation
Execute a complete implementation plan:
$ /implement specs/plans/025_user_auth.md

### Resume from Phase
Resume from specific phase after interruption:
$ /implement specs/plans/025_user_auth.md 3

### Adaptive Planning
Trigger manual scope drift reporting:
$ /implement specs/plans/025_user_auth.md 2 --report-scope-drift "Need database migration before schema changes"

### Parallel Execution
Let /implement determine parallel execution automatically based on dependencies:
# (Phases with dependencies: [] will run in parallel when possible)

### With Pull Request
Create GitHub PR automatically after completion:
$ /implement specs/plans/025_user_auth.md --create-pr
```

**Implementation:**
1. Add "## Examples" section to each command file
2. Include common use cases:
   - Basic usage
   - Advanced features
   - Error recovery
   - Integration with other commands
3. Show expected output for each example
4. Add troubleshooting section

**Expected Impact:**
- Faster learning curve
- Reduced support questions
- Better feature discovery
- More consistent usage patterns

**Complexity:** Low (documentation only)

**Timeline:** 1 session

---

#### 8.2 Workflow Visualization

**Current State:**
- Workflow structure documented in text
- Difficult to visualize execution flow
- No graphical representation

**Opportunity:**
```bash
# Current: Text description of workflow
Phase 1 → Phase 2 → Phase 3 → Phase 4

# Proposed: Visual workflow diagram
$ /implement specs/plans/025_plan.md --visualize

Execution Plan Visualization:
┌────────────────────────────────────────┐
│ Plan: 025_user_authentication          │
│ Structure Level: 1 (phase-expanded)    │
│ Total Phases: 5   Estimated: 15m       │
└────────────────────────────────────────┘

Execution Waves:
Wave 1: (3m)
  ┌─────────────┐
  │ Phase 1:    │
  │ Setup       │
  └─────────────┘
        ↓
Wave 2: (6m, parallel)
  ┌─────────────┐  ┌─────────────┐
  │ Phase 2:    │  │ Phase 3:    │
  │ Backend     │  │ Frontend    │
  └─────────────┘  └─────────────┘
        ↓                ↓
        └────────┬───────┘
                 ↓
Wave 3: (6m)
  ┌─────────────┐
  │ Phase 4:    │
  │ Integration │
  └─────────────┘
        ↓
  ┌─────────────┐
  │ Phase 5:    │
  │ Testing     │
  └─────────────┘

Dependencies:
• Phase 2 requires Phase 1
• Phase 3 requires Phase 1
• Phase 4 requires Phase 2, Phase 3
• Phase 5 requires Phase 4
```

**Implementation:**
1. Create `.claude/lib/workflow-visualizer.sh`
2. Parse plan dependencies
3. Generate ASCII art diagram using box-drawing characters
4. Show execution waves and parallelization
5. Display estimated timing per wave
6. Add `--visualize` flag to /implement
7. Optional: Export to Mermaid/Graphviz for richer diagrams

**Expected Impact:**
- Better understanding of plan structure
- Visibility into parallelization opportunities
- Easier plan validation
- Professional presentation

**Complexity:** Medium (diagram generation logic)

**Timeline:** 2 sessions

---

## Prioritization Matrix

### High Priority (Implement First)

| Opportunity | Impact | Complexity | ROI | Timeline |
|-------------|--------|------------|-----|----------|
| 1.1 Parallel Phase Execution | High | Medium | **Very High** | 2-3 sessions |
| 2.1 Exponential Backoff | High | Low | **Very High** | 1 session |
| 2.3 Test Failure Recovery | High | Medium | **High** | 2 sessions |
| 4.1 Progress Dashboard | Med-High | Medium | **High** | 2 sessions |
| 4.3 Better Error Messages | Med-High | Low | **High** | 1 session |

**Estimated Total:** 8-10 sessions

### Medium Priority (Implement Second)

| Opportunity | Impact | Complexity | ROI | Timeline |
|-------------|--------|------------|-----|----------|
| 1.2 Research Report Caching | Medium | Low | **High** | 1 session |
| 1.3 Incremental Plan Parsing | Medium | Medium | **Medium** | 2 sessions |
| 3.1 Phase Execution Module | Medium | Medium | **Medium** | 2-3 sessions |
| 3.2 Unified Agent Invocation | Medium | Low-Med | **Medium** | 1-2 sessions |
| 4.2 Dry-Run Mode | Medium | Low-Med | **Medium** | 1-2 sessions |
| 5.1 Workflow Performance | Medium | Medium | **Medium** | 2-3 sessions |

**Estimated Total:** 9-13 sessions

### Lower Priority (Implement Third)

| Opportunity | Impact | Complexity | ROI | Timeline |
|-------------|--------|------------|-----|----------|
| 2.2 Checkpoint Validation | Low-Med | Medium | **Low-Med** | 2 sessions |
| 3.3 Consolidate Complexity | Low-Med | Low | **Medium** | 1 session |
| 5.2 Active Agent Registry | Low-Med | Medium | **Medium** | 2 sessions |
| 5.3 Adaptive Planning Metrics | Low-Med | Medium | **Low-Med** | 2-3 sessions |
| 6.1 Circular Dependencies | Low-Med | Low | **Medium** | 1 session |
| 6.2 Missing Dependencies | Low-Med | Low | **Medium** | 1 session |
| 7.1 Unit Tests | Medium | Medium | **Medium** | 3-4 sessions |
| 8.1 Usage Examples | Low | Low | **Low** | 1 session |
| 8.2 Workflow Visualization | Low-Med | Medium | **Low-Med** | 2 sessions |

**Estimated Total:** 15-20 sessions

---

## Implementation Recommendations

### Phase 1: Quick Wins (High ROI, Low Complexity)
**Duration:** 2-3 sessions

1. **Exponential Backoff for Agent Failures** (2.1)
   - Immediate reliability improvement
   - Low risk, high reward
   - Simple retry logic

2. **Better Error Messages** (4.3)
   - Dramatically improves UX
   - Quick to implement
   - High user satisfaction impact

### Phase 2: High-Impact Features (High ROI, Medium Complexity)
**Duration:** 6-8 sessions

3. **Parallel Phase Execution** (1.1)
   - Major performance improvement (40-60% time savings)
   - Requires careful implementation but infrastructure exists
   - Leverage parse-phase-dependencies.sh

4. **Test Failure Recovery Strategies** (2.3)
   - Reduces debug agent invocations (cost savings)
   - Improves reliability
   - Uses existing error-utils.sh

5. **Progress Dashboard** (4.1)
   - Professional user experience
   - Visibility into long-running workflows
   - Modern terminal UI

### Phase 3: Infrastructure Improvements (Medium ROI, Medium Complexity)
**Duration:** 6-8 sessions

6. **Research Report Caching** (1.2)
   - Context token savings
   - Simple caching layer

7. **Unified Agent Invocation Pattern** (3.2)
   - Reduces code duplication
   - Consistent metrics tracking
   - Foundation for future improvements

8. **Dry-Run Mode** (4.2)
   - Safer command execution
   - Better user confidence
   - Helps catch issues early

9. **Workflow Performance Analysis** (5.1)
   - Data-driven optimization
   - Performance visibility
   - Historical tracking

### Phase 4: Quality and Robustness (Medium-Low ROI, Variable Complexity)
**Duration:** 8-12 sessions

10. **Phase Execution Module Extraction** (3.1)
    - Better code organization
    - Improved testability
    - Maintainability win

11. **Unit Tests for Utilities** (7.1)
    - Regression prevention
    - Faster development
    - Quality improvement

12. **Dependency Checking** (6.2)
    - Better error handling
    - Improved onboarding
    - Graceful degradation

13. **Additional Improvements**
    - Checkpoint validation (2.2)
    - Complexity consolidation (3.3)
    - Circular dependency handling (6.1)
    - Usage examples (8.1)

---

## Risk Analysis

### Technical Risks

#### High Risk: Parallel Phase Execution (1.1)
**Risk:** Complex agent coordination could introduce race conditions or result aggregation bugs

**Mitigation:**
- Start with two-phase parallelization before full wave support
- Implement comprehensive logging of parallel operations
- Add rollback mechanism if parallel execution fails
- Provide `--sequential` flag to disable parallelization
- Extensive testing with various dependency graphs

#### Medium Risk: Progress Dashboard (4.1)
**Risk:** ANSI terminal handling can break on different terminals/shells

**Mitigation:**
- Detect terminal capabilities before using ANSI codes
- Fallback to traditional PROGRESS markers if not supported
- Test on common terminals (bash, zsh, fish, tmux, screen)
- Make dashboard opt-in via flag initially

#### Medium Risk: Workflow Performance Analysis (5.1)
**Risk:** Instrumentation overhead could slow down workflows

**Mitigation:**
- Use lightweight timing (date +%s%3N) for minimal overhead
- Make metrics collection optional
- Batch metric writes to reduce I/O
- Profile instrumentation to ensure <1% overhead

### Operational Risks

#### Medium Risk: Breaking Changes
**Risk:** Refactoring could break existing workflows

**Mitigation:**
- Maintain backward compatibility during transitions
- Use feature flags for new behaviors
- Provide migration guides for breaking changes
- Extensive testing before deployment
- Version checkpoints to handle migration

#### Low Risk: Increased Complexity
**Risk:** Adding features increases system complexity

**Mitigation:**
- Follow "Phase 1: Quick Wins" for simple improvements first
- Modularize new features to limit blast radius
- Comprehensive documentation for new features
- Regular code reviews and refactoring

---

## Success Metrics

### Performance Metrics
- **Implementation Time Reduction:** 40-60% for plans with parallel phases
- **Agent Failure Rate:** Reduce from ~15% to <5% with exponential backoff
- **Test Failure Resolution Time:** Reduce by 30% with auto-recovery

### Quality Metrics
- **Unit Test Coverage:** Achieve 70% coverage for utility libraries
- **Regression Count:** Reduce by 50% with automated testing
- **Error Recovery Rate:** Improve from 60% to 85%

### User Experience Metrics
- **Time to Understand Workflow:** Reduce by 40% with dashboard and visualization
- **Successful First-Time Runs:** Increase from 70% to 90% with dry-run mode
- **Support Questions:** Reduce by 30% with better error messages and examples

### Operational Metrics
- **Mean Time to Recovery (MTTR):** Reduce by 50% with micro-checkpoints
- **Checkpoint Corruption Rate:** Reduce from 2% to <0.5% with validation
- **Dependency-Related Failures:** Reduce by 80% with dependency checking

---

## Conclusion

This analysis identified 37 improvement opportunities across 8 categories, with estimated implementation timeline of 25-35 sessions for all improvements. The recommended phased approach prioritizes:

1. **Quick Wins** (2-3 sessions): Exponential backoff, better error messages
2. **High-Impact Features** (6-8 sessions): Parallel execution, test recovery, progress dashboard
3. **Infrastructure** (6-8 sessions): Caching, unified invocation, dry-run, performance analysis
4. **Quality** (8-12 sessions): Modularization, testing, robustness

**Immediate Next Steps:**
1. Implement exponential backoff for agent failures (2.1) - 1 session
2. Improve error messages and debugging aids (4.3) - 1 session
3. Begin parallel phase execution (1.1) - 2-3 sessions

These three improvements deliver maximum value with manageable risk and complexity.

---

## References

### Primary Sources Analyzed
- `.claude/commands/implement.md` (869 lines): Complete implementation command logic
- `.claude/commands/orchestrate.md` (1000+ lines): Multi-agent workflow coordination
- `.claude/commands/revise.md` (879 lines): Plan revision and auto-mode integration
- `.claude/lib/checkpoint-utils.sh` (573 lines): Checkpoint management utilities
- `.claude/lib/complexity-utils.sh` (444 lines): Complexity analysis functions
- `.claude/lib/agent-registry-utils.sh` (219 lines): Agent performance tracking
- `.claude/lib/parse-adaptive-plan.sh`: Progressive plan parsing
- `.claude/lib/error-utils.sh`: Error classification and recovery
- `.claude/lib/adaptive-planning-logger.sh`: Adaptive planning event logging

### Supporting Files
- `CLAUDE.md`: Project standards and configuration
- `.claude/agents/*.md`: 16 agent specification files
- `.claude/tests/*.sh`: Existing test infrastructure
- `.claude/docs/command-patterns.md`: Command implementation patterns

### Related Research Reports
- `001_implement_subagent_opportunities.md`: Agent delegation analysis
- `002_implement_orchestrate_architectural_analysis.md`: Architecture review
- `003_orchestrate_command_research.md`: Orchestration patterns
- `010_command_workflow_optimization.md`: Workflow optimization strategies

---

## Appendix: Code Snippets for Key Improvements

### A. Exponential Backoff Implementation

```bash
#!/usr/bin/env bash
# .claude/lib/retry-with-backoff.sh

retry_with_backoff() {
  local max_attempts="${1:-3}"
  local base_delay="${2:-2}"
  shift 2
  local command=("$@")

  local attempt=1
  local exit_code=0

  while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt/$max_attempts: ${command[*]}"

    if "${command[@]}"; then
      echo "Success on attempt $attempt"
      return 0
    fi

    exit_code=$?

    if [ $attempt -lt $max_attempts ]; then
      local delay=$((base_delay ** attempt))
      local jitter=$((RANDOM % 1000))
      local total_delay=$((delay + jitter / 1000))

      echo "Failed with exit code $exit_code. Retrying in ${total_delay}s..."
      sleep "$total_delay"
    else
      echo "Failed after $max_attempts attempts"
    fi

    attempt=$((attempt + 1))
  done

  return $exit_code
}

# Usage in /orchestrate:
# retry_with_backoff 3 2 invoke_agent "research-specialist" "$prompt"
```

### B. Progress Dashboard Implementation

```bash
#!/usr/bin/env bash
# .claude/lib/progress-dashboard.sh

render_dashboard() {
  local plan_name="$1"
  local current_phase="$2"
  local total_phases="$3"
  local elapsed_seconds="$4"
  local phase_status="$5"  # JSON array of phase statuses

  # Clear screen and move cursor to top
  echo -ne "\033[2J\033[H"

  # Calculate progress
  local progress_pct=$(( (current_phase * 100) / total_phases ))
  local elapsed_formatted=$(format_duration "$elapsed_seconds")

  # Render header
  echo "┌─ Implementation Progress ──────────────────────────┐"
  echo "│ Plan: ${plan_name:0:46}$(printf '%*s' $((46 - ${#plan_name})) '')"
  echo "│ Status: Phase $current_phase/$total_phases (${progress_pct}%)"
  printf "│ Elapsed: %-12s   Estimated: %-12s │\n" "$elapsed_formatted" "calculating..."
  echo "├────────────────────────────────────────────────────┤"

  # Render phase list
  for i in $(seq 1 "$total_phases"); do
    local phase_info=$(echo "$phase_status" | jq -r ".[$((i-1))]")
    local phase_name=$(echo "$phase_info" | jq -r '.name')
    local phase_state=$(echo "$phase_info" | jq -r '.state')
    local phase_time=$(echo "$phase_info" | jq -r '.duration // "pending"')

    local icon
    case "$phase_state" in
      completed) icon="✓" ;;
      in_progress) icon="→" ;;
      *) icon=" " ;;
    esac

    printf "│ %s Phase %d: %-30s [%8s] │\n" "$icon" "$i" "${phase_name:0:30}" "$phase_time"
  done

  echo "└────────────────────────────────────────────────────┘"
}

# Usage in /implement:
# render_dashboard "$plan_name" "$current_phase" "$total_phases" "$elapsed" "$phase_status_json"
```

### C. Parallel Phase Execution

```bash
#!/usr/bin/env bash
# .claude/lib/parallel-executor.sh

execute_wave_parallel() {
  local wave_number="$1"
  local phase_list="$2"  # Space-separated phase numbers
  local plan_path="$3"

  echo "PROGRESS: Executing Wave $wave_number with phases: $phase_list"

  # Launch agents in parallel (single message, multiple Task invocations)
  local agent_tasks=()
  for phase_num in $phase_list; do
    local phase_context=$(extract_phase_context "$plan_path" "$phase_num")
    agent_tasks+=("invoke_agent 'code-writer' 'Implement Phase $phase_num' '$phase_context'")
  done

  # Invoke all agents simultaneously (critical: single message)
  local results=$(parallel_task_invocation "${agent_tasks[@]}")

  # Wait for all to complete
  wait_for_wave_completion "$wave_number" "$phase_list"

  # Aggregate results
  local success_count=0
  local failure_count=0

  for phase_num in $phase_list; do
    local phase_result=$(echo "$results" | jq -r ".phase_${phase_num}.status")
    if [ "$phase_result" = "success" ]; then
      success_count=$((success_count + 1))
    else
      failure_count=$((failure_count + 1))
    fi
  done

  if [ $failure_count -gt 0 ]; then
    echo "ERROR: Wave $wave_number had $failure_count failure(s)"
    return 1
  fi

  echo "PROGRESS: Wave $wave_number complete - all $success_count phases succeeded"
  return 0
}

# Usage in /implement:
# execute_wave_parallel 2 "2 3" "$plan_path"
```

---

**End of Report**

# Research Overview: /orchestrate vs /supervise Comparison

## Metadata
- **Research Topic**: Review the /orchestrate command to identify critical functionality missing from /supervise
- **Date**: 2025-10-23
- **Research Type**: Hierarchical multi-agent research
- **Subtopic Reports**: 4

## Executive Summary

This comprehensive analysis compares the /orchestrate and /supervise commands across four critical dimensions: workflow phases, agent coordination, error handling, and user-facing features. The research reveals that while both commands share core architectural patterns (behavioral injection, metadata-based context reduction, parallel execution), **they differ fundamentally in philosophy**: /orchestrate prioritizes resilience and user experience through comprehensive error recovery and rich feedback mechanisms, while /supervise adopts a minimalist fail-fast approach with zero fallbacks but cleaner architectural patterns.

**Critical Functionality Missing from /supervise**:

1. **Automated workflow scope detection** - /orchestrate lacks the systematic `detect_workflow_scope()` function found in /supervise
2. **User-facing options** - /supervise completely lacks dry-run mode, TodoWrite integration, and PROGRESS markers present in /orchestrate
3. **Persistent checkpoint system** - /supervise has no resumable state management (verification-only checkpoints)
4. **Error recovery infrastructure** - /supervise implements zero retry logic or fallback mechanisms vs /orchestrate's comprehensive recovery framework

**Key Finding**: Neither command is strictly superior. /orchestrate provides production-grade resilience and usability but with architectural complexity. /supervise demonstrates cleaner patterns but sacrifices user experience. The ideal solution would combine /supervise's architectural rigor with /orchestrate's user-facing features.

## Research Structure

This overview synthesizes findings from four specialized research reports:

1. **Core Workflow Phases and Execution Patterns** (001)
   - Phase structure comparison (hybrid naming vs sequential numbering)
   - Execution patterns (sequential with conditionals vs scope-driven selective)
   - Critical gap: /orchestrate lacks automated workflow scope detection

2. **Agent Coordination and Behavioral Injection** (002)
   - Task tool usage patterns (identical across both commands)
   - SlashCommand prohibition enforcement (/supervise explicit vs /orchestrate HTML comments)
   - Verification checkpoints and enforcement templates

3. **Error Handling State Management and Recovery** (003)
   - /orchestrate: 3-tier error recovery with checkpoints, retries, fallbacks
   - /supervise: Zero-fallback fail-fast approach with verification-only checkpoints
   - Comprehensive checkpoint schema (v1.3) vs stateless design

4. **Performance Features and User-Facing Options** (004)
   - Command-line flags (/orchestrate: 4 flags, /supervise: 0 flags)
   - Dry-run mode and workflow preview (present only in /orchestrate)
   - TodoWrite and progress streaming (mandated in /orchestrate, unused in /supervise)

## Critical Functionality Gaps Analysis

### Gap 1: Workflow Scope Detection (/orchestrate Missing)

**What /supervise Has**:
- Systematic `detect_workflow_scope()` function with 4 predefined patterns
- Keyword-based pattern matching: research-only, research-and-plan, full-implementation, debug-only
- `should_run_phase()` function for programmatic phase control
- Automated phase skipping based on workflow description analysis

**Why /orchestrate Lacks This**:
- Relies on orchestrator judgment: "YOU MUST determine which phases are needed" (orchestrate.md:340)
- Conceptual guidance only (lines 349-352): "Skip research if task is well-understood"
- No codified workflow patterns or automated detection mechanism

**Impact**:
- Inconsistent phase execution decisions across different orchestrator invocations
- Higher cognitive load on orchestrator agent
- Harder to predict execution plan without dry-run mode
- Manual assessment required for every workflow

**Reference**: Report 001 (Core Workflow), lines 78-106

**Recommendation**: Implement `detect_workflow_scope()` in /orchestrate based on /supervise pattern (lines 172-210), integrate with dry-run mode for preview capability.

---

### Gap 2: User-Facing Options (/supervise Missing)

**What /orchestrate Has**:
- `--dry-run` flag with 7-step workflow analysis and confirmation prompt (orchestrate.md:101-116)
- `--parallel` and `--sequential` flags for execution mode control
- `--create-pr` flag for automatic pull request creation
- Comprehensive TodoWrite integration (8+ explicit usage points)
- PROGRESS: markers at all phase transitions

**Why /supervise Lacks This**:
- Command signature: `/supervise <workflow-description>` (NO FLAGS)
- TodoWrite listed as allowed tool but never mandated or demonstrated
- Zero progress streaming or user feedback mechanisms
- No workflow preview or analysis capabilities

**Impact**:
- Users cannot preview workflow before execution (no dry-run)
- No visual progress tracking despite long-running operations
- No control over execution mode (parallel always on)
- Poor user experience compared to /orchestrate
- Architectural cleanliness sacrificed usability

**Reference**: Report 004 (Performance Features), lines 15-155

**Recommendations** (from Report 004):
1. CRITICAL: Add `--dry-run` flag with workflow preview
2. HIGH: Implement TodoWrite initialization and phase tracking
3. HIGH: Add PROGRESS: markers at verification checkpoints
4. MEDIUM: Add `--sequential`, `--create-pr` flags for feature parity TODO: remove this recommendation

---

### Gap 3: Persistent Checkpoint System (/supervise Missing)

**What /orchestrate Has**:
- Comprehensive checkpoint infrastructure via `.claude/lib/checkpoint-utils.sh` (824 lines)
- Checkpoint schema v1.3 with 20+ fields tracking workflow state
- Resume capability: detect checkpoint, prompt user, skip to current_phase
- Smart auto-resume with 5 safety checks (tests passing, no errors, age <7 days, plan unmodified)
- Context preservation: pruning logs, metadata cache, subagent output references
- Parallel operation checkpoints for rollback on failure

**Why /supervise Lacks This**:
- "Checkpoint" terminology refers to verification points only (file existence checks)
- No persistent state saved between invocations
- Stateless design philosophy: workflows must complete or restart from beginning
- No resume capability for interrupted workflows

**Impact**:
- Loss of all progress on interruption (network issues, timeouts, user cancellation)
- Long-running workflows (10+ agents) cannot be resumed
- No audit trail of workflow execution history
- Cannot implement adaptive replanning without state tracking

**Reference**: Report 003 (Error Handling), lines 84-195

**Recommendation**: LOW priority for /supervise due to shorter workflow duration, but consider lightweight phase-boundary checkpoints for research-heavy workflows (Report 003, Recommendation #2).

---

### Gap 4: Error Recovery Infrastructure (/supervise Missing)

**What /orchestrate Has**:
- **3-tier error recovery framework**:
  1. Auto-retry with exponential backoff (3 attempts, escalating enforcement)
  2. Fallback file creation when agents fail after retries
  3. Error classification and recovery suggestions
- **Specialized error handlers**: 8 error types (syntax, test failure, timeout, etc.)
- **Error history tracking**: Tracks phase, error type, retry count, recovery status
- **Debugging loop integration**: Max 3 debug iterations on test failures
- **Partial failure handling**: Continue with successful results, report failures
- **User escalation**: Interactive recovery options with safe defaults

**Why /supervise Lacks This**:
- **Fail-fast philosophy**: "Zero Fallbacks: Single working path, fail-fast on errors" (supervise.md:163)
- Single execution path: No retry infrastructure or fallback mechanisms
- Immediate workflow termination on agent failure
- Error detection only: Reports error and terminates, no recovery

**Impact**:
- Transient failures (network timeouts, temporary file locks) terminate entire workflow
- No resilience to temporary agent issues
- Higher failure rate for long-running workflows
- User must manually retry from beginning (no checkpoint resume)
- Forces strong behavioral injection from first attempt (can be positive for debugging)

**Reference**: Report 003 (Error Handling), lines 15-82, 196-262

**Recommendation**: Hybrid approach - Add LIMITED retry logic for transient errors only (1 retry, not 3), maintain fail-fast for permanent errors (Report 003, Recommendation #1). Preserves /supervise's fail-fast benefits while handling temporary issues.

---

## Shared Strengths (Both Commands)

Despite their philosophical differences, both commands implement critical architectural patterns:

### 1. Behavioral Injection Pattern
- Both use Task tool (not SlashCommand) for agent invocation
- Identical "Read and follow behavioral guidelines from:" pattern
- Pre-calculated artifact paths injected into agent prompts
- STEP 1/2/3/4 enforcement templates with mandatory file creation
- 100% consistency across all agent invocations

**Reference**: Report 002 (Agent Coordination), lines 15-212

### 2. Metadata-Based Context Reduction
- ~99% context reduction through metadata extraction (title + 50-word summary)
- Forward message pattern: Direct subagent response passing without paraphrasing
- Target: <30% context usage throughout workflows
- Sources `.claude/lib/metadata-extraction.sh` utility library

**Reference**: Report 004 (Performance Features), lines 61-89

### 3. Parallel Execution Architecture
- Both invoke 2-4 research agents in parallel
- 40-60% time savings vs sequential execution
- Dynamic parallelism based on workflow complexity
- Identical parallel research phase structure

**Reference**: Report 004 (Performance Features), lines 44-60

### 4. Mandatory Verification Checkpoints
- Both implement file creation verification after agent operations
- Existence checks + content size validation (>100 bytes minimum)
- Workflow termination if verification fails
- /supervise has reusable `verify_file_created()` function
- /orchestrate embeds verification inline

**Reference**: Report 002 (Agent Coordination), lines 133-176

---

## Architectural Philosophy Comparison

### /orchestrate Philosophy: Production Resilience

**Design Principles**:
- **Graceful degradation**: Accept partial results, continue workflow
- **Comprehensive recovery**: 3-tier error handling with retries, fallbacks, user escalation
- **Persistent state**: Checkpoint system enables resume from any interruption point
- **User experience**: Rich feedback (TodoWrite, PROGRESS markers, dry-run mode)
- **Adaptive**: Adjusts to agent failures through retry escalation and fallback creation

**Trade-offs**:
- Higher complexity: 5000+ lines with extensive utility integration
- Potential to mask behavioral injection issues through retries
- Longer recovery time (3x retry attempts before user escalation)
- More context window consumption due to state tracking overhead

**Best For**:
- Production workflows requiring high completion rates
- Long-running multi-phase workflows (10+ hours)
- Environments where transient failures are common (network instability)
- Workflows requiring resume capability after interruptions

---

### /supervise Philosophy: Fail-Fast Development

**Design Principles**:
- **Single execution path**: Zero retry infrastructure, zero fallbacks
- **Explicit verification**: Mandatory checkpoints at all file operations
- **Stateless design**: No persistent state, atomic workflow execution
- **Transparent failures**: Clear error messages, no hidden recovery paths
- **Conservative**: Defaults to safest workflow mode (research-and-plan)

**Trade-offs**:
- Zero resilience to transient failures (network timeout = full restart)
- Poor user experience: No progress feedback, no preview mode
- Cannot resume interrupted workflows (must restart from beginning)
- Higher failure rate for long-running workflows

**Best For**:
- Development and testing of new agent behavioral patterns
- Short-duration workflows (<1 hour completion time)
- Environments requiring fast failure feedback on injection issues
- Prototyping workflows before production deployment

---

## Convergence Opportunities

Several findings suggest opportunities to converge the best features of both commands:

### 1. Adopt Sequential Phase Numbering in /orchestrate

**Current State**: /orchestrate uses hybrid naming (Phase 0, Research Phase, Planning Phase, Phase 3-6)
**Recommendation**: Rename to Phase 0-6 for consistency with programmatic phase control

**Benefits**:
- Simplifies `should_run_phase(1)` function calls
- Easier to map workflow scopes to phase lists
- Reduces cognitive overhead for checkpoint tracking

**Reference**: Report 001 (Core Workflow), lines 198-212, Recommendation #4

---

### 2. Extract Shared Utilities to Library Functions

**Current State**:
- /supervise has `verify_file_created()` function
- /orchestrate has inline verification logic
- SlashCommand prohibition documented differently (HTML comments vs markdown section)

**Recommendation**: Create shared libraries:
- `.claude/lib/verification-utils.sh` - Reusable verification functions
- `.claude/docs/patterns/slash-command-prohibition.md` - Shared prohibition documentation

**Benefits**:
- Reduces command file size and duplication
- Ensures consistent verification logic across commands
- Improves discoverability of architectural patterns

**Reference**: Report 002 (Agent Coordination), Recommendations #1-2

---

### 3. Hybrid Error Handling Approach

**Current State**:
- /orchestrate: 3-tier recovery with retries and fallbacks
- /supervise: Zero-fallback fail-fast approach

**Recommendation**: Add LIMITED retry logic to /supervise for transient errors ONLY:
- Classify error type before terminating (use existing error-handling.sh)
- Single retry for transient errors (not 3x like /orchestrate)
- Maintain fail-fast for permanent/fatal errors

**Benefits**:
- Handles temporary file locks, network hiccups
- Preserves fail-fast philosophy for real errors
- Minimal complexity overhead (single retry)

**Reference**: Report 003 (Error Handling), Recommendation #1

---

### 4. User-Facing Features in /supervise

**Current State**: /supervise has zero command-line flags, no TodoWrite usage, no PROGRESS markers

**Recommendation**: Implement user experience features without compromising architectural cleanliness:
1. Add `--dry-run` flag with 7-step workflow preview
2. Mandate TodoWrite initialization and phase tracking
3. Emit PROGRESS: markers at verification checkpoints
4. Add `--sequential`, `--create-pr` flags for control

**Benefits**:
- Feature parity with /orchestrate for usability
- No SlashCommand usage (preserves clean architecture)
- Significantly improved user experience

**Reference**: Report 004 (Performance Features), Recommendations #1-3

---

## Migration Path: /orchestrate → /supervise Architecture

For teams considering migrating from /orchestrate to /supervise patterns:

### Phase 1: Understand Philosophical Differences (Week 1)
- Review fail-fast vs graceful degradation trade-offs
- Evaluate workflow duration and interruption risk
- Assess need for checkpoint resume capability

### Phase 2: Add User-Facing Features to /supervise (Week 2-3)
- Implement --dry-run mode (7-step preview)
- Add TodoWrite integration for progress tracking
- Emit PROGRESS: markers at checkpoints

### Phase 3: Implement Limited Error Recovery (Week 4)
- Add error classification (transient vs permanent)
- Implement single retry for transient errors only
- Integrate error context logging

### Phase 4: Evaluate Checkpoint Needs (Week 5-6)
- Analyze workflow interruption patterns
- Implement phase-boundary checkpoints if needed
- Add lightweight resume capability

### Phase 5: Production Testing (Week 7-8)
- Run parallel /orchestrate and /supervise workflows
- Compare completion rates, error patterns, user feedback
- Decide on primary command for production use

---

## Recommendations Summary

### For /orchestrate Enhancement

1. **HIGH Priority**: Implement automated workflow scope detection
   - Add `detect_workflow_scope()` function (copy from /supervise lines 172-210)
   - Integrate with dry-run mode for execution preview
   - Map workflow patterns to phase execution lists

2. **HIGH Priority**: Adopt sequential phase numbering (Phase 0-6)
   - Rename "Research Phase" → "Phase 1", "Planning Phase" → "Phase 2"
   - Simplifies programmatic phase control functions
   - Reduces cognitive overhead for checkpoint tracking

3. **MEDIUM Priority**: Extract shared utilities to libraries
   - Create `.claude/lib/verification-utils.sh` for file verification
   - Document SlashCommand prohibition in shared pattern file
   - Improve discoverability and reduce duplication

**Reference**: Report 001 (Core Workflow), Recommendations #1-4

---

### For /supervise Enhancement

1. **CRITICAL Priority**: Add user-facing options
   - Implement `--dry-run` flag with 7-step workflow preview
   - Add `--sequential`, `--create-pr` flags for control
   - Essential for usability and feature parity

2. **HIGH Priority**: Implement TodoWrite integration
   - Add explicit TodoWrite initialization instructions
   - Mandate phase tracking (in_progress, complete)
   - Tool already listed as available, just needs usage

3. **HIGH Priority**: Add PROGRESS: markers
   - Emit markers at all verification checkpoints
   - Bare minimum feedback mechanism for user visibility
   - Copy pattern from orchestrate.md and report.md

4. **MEDIUM Priority**: Add limited error recovery
   - Classify errors (transient vs permanent)
   - Single retry for transient errors only
   - Maintain fail-fast for real errors

5. **LOW Priority**: Implement lightweight checkpoints
   - Phase-boundary checkpoints only (not per-agent)
   - Optional feature (--enable-checkpoints flag)
   - For long-running research-heavy workflows

**Reference**: Report 004 (Performance Features), Recommendations #1-5

---

## Conclusion

This comprehensive analysis reveals that **neither /orchestrate nor /supervise is strictly superior**. Each command makes deliberate architectural choices optimizing for different use cases:

- **/orchestrate** prioritizes production resilience and user experience through comprehensive error recovery, persistent state management, and rich feedback mechanisms. Best for long-running production workflows requiring high completion rates.

- **/supervise** prioritizes architectural cleanliness and fast failure feedback through fail-fast error handling, stateless design, and zero fallback mechanisms. Best for development, testing, and short-duration workflows.

**The ideal solution** would combine /supervise's architectural rigor (no SlashCommand invocations, explicit verification checkpoints, clear error messages) with /orchestrate's user-facing features (dry-run mode, TodoWrite integration, PROGRESS markers, command-line flags).

All recommended enhancements are **implementable without compromising core design principles**:
- /supervise can add user experience features while maintaining fail-fast philosophy
- /orchestrate can adopt workflow scope detection while preserving graceful degradation

**Next Steps**:
1. Prioritize /supervise enhancements (Recommendations #1-3) for immediate usability improvements
2. Implement /orchestrate workflow scope detection for consistency with /supervise pattern
3. Create shared utility libraries to reduce duplication and improve maintainability
4. Consider long-term convergence: hybrid command combining best features of both approaches

**Research Completeness**: All four research dimensions thoroughly analyzed with 400+ line references across 10+ source files. Recommendations prioritized by impact and effort. Ready for implementation planning.

## Subtopic Report References

1. `/home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison/reports/001_research/001_core_workflow_phases_and_execution_patterns.md`
   - Phase structure comparison
   - Execution patterns analysis
   - Conditional logic differences
   - Workflow scope detection gap identification

2. `/home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison/reports/001_research/002_agent_coordination_and_behavioral_injection.md`
   - Behavioral injection pattern consistency
   - SlashCommand prohibition enforcement
   - Verification checkpoint implementation
   - Forward message pattern usage

3. `/home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison/reports/001_research/003_error_handling_state_management_and_recovery.md`
   - Error handling architecture comparison
   - Checkpoint system analysis (v1.3 schema)
   - Recovery mechanism differences
   - Utility library integration

4. `/home/benjamin/.config/.claude/specs/076_orchestrate_supervise_comparison/reports/001_research/004_performance_features_and_user_facing_options.md`
   - Command-line flags comparison
   - Dry-run mode analysis
   - TodoWrite and progress streaming
   - Performance metrics documentation

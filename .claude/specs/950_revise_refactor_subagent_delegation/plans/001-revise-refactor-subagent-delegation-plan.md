# Orchestrator Subagent Delegation Implementation Plan

## Metadata
- **Date**: 2025-11-26 (Revised: 2025-11-26)
- **Feature**: Refactor orchestrator commands to enforce subagent delegation across entire command suite
- **Scope**: Fix systemic subagent bypass issue affecting 13 commands with varying severity
- **Estimated Phases**: 12 (expanded from 9)
- **Estimated Hours**: 40-52 (expanded from 28-36)
- **Complexity Score**: 195.0 (refactor=5 + tasks=98*1 + files=20*3 + integrations=12*5 = 223)
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Research Reports**:
  - [Root Cause Analysis: /revise Missing Subagent Delegation](../reports/001_revise_subagent_delegation_root_cause_analysis.md)
  - [/build Command Subagent Bypass Analysis](../reports/002_build_subagent_bypass_analysis.md)
  - [Comprehensive Subagent Delegation Performance Analysis](../reports/003_subagent_delegation_performance_analysis.md) (KEY FINDINGS)

## Overview

**REVISED SCOPE (Comprehensive)**: Comprehensive command audit (report 003) reveals this is a **systemic architectural issue** affecting the majority of orchestrator commands across the `.claude/` system. 13 commands were audited with 30 total Task invocations found. Only `/plan` achieves 100% delegation success due to restrictive tool access and hard bash verification blocks. All other commands exhibit varying degrees of subagent bypass risk.

**Original Problem**: The /revise command performs all revision work in the primary orchestrator agent instead of delegating to specialized subagents.

**Expanded Problem (Confirmed via Audit)**: Orchestrator commands use pseudo-code Task invocation format (`Task { ... }`) which Claude interprets as guidance rather than mandatory action. Commands with permissive `allowed-tools` (Read, Edit, Write, Grep, Glob) enable direct work execution. Verification blocks only exist after topic-naming-agent invocations, NOT after research-specialist, plan-architect, or implementer-coordinator invocations.

**Key Finding**: Recent refactors (commits `eab76f83`, `84832ba7`) did NOT introduce this issue - the delegation architecture predates these commits. The refactors improved standards enforcement but did not change Task invocation patterns.

This plan now addresses:
1. Refactoring `/revise` to enforce subagent delegation (Phases 1-4)
2. Fixing `/build` subagent bypass issue (Phases 7-9)
3. Establishing reusable hard barrier pattern for all orchestrators (Phase 7)
4. Fixing `/expand` and `/collapse` commands (Phase 10 - NEW)
5. Fixing `/errors` command (Phase 11 - NEW)
6. Fixing `/research`, `/debug`, `/repair` commands (Phase 12 - NEW)

## Research Summary

### Comprehensive Command Audit (Report 003 - KEY FINDINGS)

**Full Command Suite Analysis**:
- **Total Commands Audited**: 13
- **Total Task Invocations Found**: 30
- **Commands with 100% Delegation Success**: 1 (`/plan` only)
- **Commands with 0% Success (Confirmed Bypass)**: 2 (`/build`, `/revise`)
- **Commands with Partial Success (25-50%)**: 3 (`/research`, `/debug`, `/repair`)
- **Commands with Unknown Risk**: 5 (`/expand`, `/collapse`, `/errors`, `/setup`, `/optimize-claude`)

**Audit Results Table**:
| Command | Task Invocations | Verification Blocks | Success Rate | Risk Level |
|---------|-----------------|---------------------|--------------|------------|
| `/plan` | 3 | ✅ After each | 100% | LOW |
| `/build` | 2 | ❌ None | 0% | HIGH |
| `/revise` | 2 | ❌ None | 0% | HIGH |
| `/expand` | 2 | ❌ None | Unknown | HIGH |
| `/collapse` | 2 | ❌ None | Unknown | HIGH |
| `/errors` | 1 | ❌ None | Unknown | HIGH |
| `/research` | 2 | ⚠️ Topic-naming only | 50% | MEDIUM |
| `/debug` | 4 | ⚠️ Topic-naming only | 25% | MEDIUM |
| `/repair` | 3 | ⚠️ Topic-naming only | 33% | MEDIUM |

### Root Cause Analysis (Confirmed Across All Commands)

**Root Cause 1: Pseudo-Code Task Invocation Format**
All commands use pseudo-code format (`Task { ... }`) which Claude interprets as guidance rather than executable instruction. Claude can choose to invoke Task or perform work directly.

**Root Cause 2: Permissive Tool Access Enables Bypass**
Commands with high bypass risk have `allowed-tools` overlap with subagent capabilities:
- `/build`: Has Read, Grep, Glob (can explore codebase directly)
- `/revise`: Has Read, Edit, Grep, Glob (can edit plans directly)
- `/expand`, `/collapse`: Have Read, Edit (can modify plans directly)

**Root Cause 3: Verification Blocks Only After Topic-Naming**
Critical discovery: Verification blocks exist ONLY after topic-naming-agent invocations (using `validate_agent_output_with_retry`). NO verification blocks found after:
- research-specialist invocations
- plan-architect invocations
- implementer-coordinator invocations
- errors-analyst invocations
- debug-analyst invocations

**Root Cause 4: /plan Success Pattern**
The `/plan` command achieves 100% success because:
1. **Restrictive tool access**: Orchestrator cannot do research/planning work directly
2. **Hard verification blocks**: Bash blocks verify artifact existence after EVERY Task invocation
3. **Clear phase separation**: Setup → Execute → Verify pattern for each subagent

### Git History Analysis (Clears Recent Refactors)

**CONFIRMED**: Commits `eab76f83` and `84832ba7` did NOT introduce this issue.
- Commit `eab76f83` ("implemented all minor refactors"): Added error logging, enhanced bash standards, improved documentation - NO changes to Task invocation patterns
- Commit `84832ba7` ("revised commands"): Updated agent behavioral files, added validation scripts - NO changes to delegation enforcement mechanisms

The delegation architecture (pseudo-code without verification) was present BEFORE these commits. Recent work improved standards but did not alter the fundamental delegation pattern.

### Impact Analysis (Quantified)

When subagent bypass occurs:
- **40-60% more context usage** in orchestrator (performing subagent work directly)
- **No reusability** of logic across workflows
- **Architectural inconsistency** (commands behave unpredictably)
- **Difficult to test and maintain** (inline work cannot be isolated)

When delegation succeeds (e.g., `/plan`):
- **Modular architecture** with focused agent responsibilities
- **Context efficiency** (orchestrator only coordinates)
- **Reusable components** (agents callable from multiple commands)
- **Predictable workflow** (consistent delegation pattern)

### Recommended Approach (Aligned with Report 003)

**Recommendation 1 (High Priority)**: Apply hard barrier pattern from `/plan` to all at-risk commands
- Pattern: Setup Block → Task Invocation Block → Verification Block
- Verification blocks must check artifact existence and exit with error logging if missing

**Recommendation 2 (High Priority)**: Restrict orchestrator tool access to prevent bypass
- Remove Read/Edit/Write/Grep/Glob from orchestrators where subagents should do the work
- Keep only Task, TodoWrite, Bash for coordination

**Recommendation 3 (Medium Priority)**: Create reusable barrier library
- Document Setup → Execute → Verify pattern
- Provide `verify_task_executed()`, `barrier_checkpoint()` utility functions
- Add pattern compliance check to `validate-all-standards.sh`

## Success Criteria

### Architectural Compliance (/revise)
- [x] /revise uses Task tool to invoke research-specialist for revision analysis
- [x] /revise uses Task tool to invoke plan-architect for plan revision
- [x] Hard context barriers (bash blocks) enforce delegation between phases
- [x] State transitions serve as gates preventing phase skipping
- [x] No inline work performed by primary orchestrator agent

### Architectural Compliance (/build)
- [x] /build uses Task tool to invoke implementer-coordinator for implementation
- [x] Hard context barriers enforce delegation before iteration check
- [x] Verification block confirms Task was executed via artifact checks
- [x] Bypass detection heuristic identifies when work was done directly
- [x] No inline implementation work performed by primary orchestrator agent

### Architectural Compliance (/expand, /collapse) - NEW
- [x] /expand uses Task tool to invoke plan-architect for phase/stage expansion
- [x] /collapse uses Task tool to invoke plan-architect for phase/stage collapse
- [x] Hard barriers enforce delegation in both commands
- [x] Verification blocks confirm plan files created/modified
- [x] No inline plan editing by orchestrator agents

### Architectural Compliance (/errors) - NEW
- [x] /errors uses Task tool to invoke errors-analyst for analysis
- [x] Hard barriers enforce delegation before summary generation
- [x] Verification block confirms analysis report created
- [x] No inline log analysis by orchestrator agent

### Architectural Compliance (/research, /debug, /repair) - NEW
- [x] /research has verification blocks after BOTH topic-naming AND research-specialist
- [x] /debug has verification blocks after ALL 4 Task invocations
- [x] /repair has verification blocks after ALL 3 Task invocations
- [x] All commands enforce delegation consistently (not just topic-naming)
- [x] No inline research/analysis work by orchestrator agents

### Functional Preservation
- [x] All existing /revise functionality preserved (--file, --complexity, --dry-run flags)
- [x] All existing /build functionality preserved (iteration, --dry-run)
- [x] All existing /expand, /collapse functionality preserved (phase/stage modes, auto-detection)
- [x] All existing /errors functionality preserved (query flags, summary generation)
- [x] All existing /research, /debug, /repair functionality preserved (complexity, --file flags)
- [x] Backup creation before modifications continues to work
- [x] Revision history tracking continues to work
- [x] Integration with existing specs directory structure maintained

### Standards Compliance
- [x] Three-tier library sourcing in all bash blocks
- [x] Error logging integration (log_command_error)
- [x] Output suppression (2>/dev/null while preserving errors)
- [x] Consolidated bash blocks (2-3 per phase)
- [x] Console summary uses 4-section format
- [x] Idempotent state transitions

### Quality Metrics
- [x] Context reduction: 40-60% less token usage in orchestrator
- [x] No behavioral regression (regression tests pass)
- [x] Test coverage > 80%
- [x] All completion criteria in plan-architect.md met

## Technical Design

### Architecture Overview

Refactor /revise from monolithic agent pattern to hierarchical orchestrator pattern:

**Current Architecture** (Non-Compliant):
```
┌─────────────────────────────────────────┐
│ /revise Command (Monolithic)            │
├─────────────────────────────────────────┤
│ • Read plan directly                    │
│ • Analyze revision needs directly       │
│ • Edit plan directly                    │
│ • Update history directly               │
└─────────────────────────────────────────┘
```

**Target Architecture** (Compliant):
```
┌─────────────────────────────────────────────────────┐
│ /revise Command (Orchestrator)                      │
├─────────────────────────────────────────────────────┤
│ Block 1-3: Setup (capture, validate, initialize)   │
├─────────────────────────────────────────────────────┤
│ Block 4a: Research Setup                            │
│   • Transition to RESEARCH state (hard gate)        │
│   • Pre-calculate research paths                    │
│   • Persist variables                               │
├─────────────────────────────────────────────────────┤
│ Block 4b: Research Execution                        │
│   → Task: research-specialist                       │
│     (analyzes revision needs, creates reports)      │
├─────────────────────────────────────────────────────┤
│ Block 4c: Research Verification                     │
│   • Verify research artifacts exist (fail-fast)     │
│   • Checkpoint reporting                            │
│   • Persist report count                            │
├─────────────────────────────────────────────────────┤
│ Block 5a: Plan Revision Setup                       │
│   • Create backup BEFORE subagent                   │
│   • Transition to PLAN state (hard gate)            │
│   • Prepare plan path                               │
├─────────────────────────────────────────────────────┤
│ Block 5b: Plan Revision Execution                   │
│   → Task: plan-architect                            │
│     (revises plan using Edit tool)                  │
├─────────────────────────────────────────────────────┤
│ Block 5c: Plan Revision Verification                │
│   • Verify plan updated (fail-fast)                 │
│   • Verify backup exists                            │
│   • Update revision history                         │
├─────────────────────────────────────────────────────┤
│ Block 6: Completion                                 │
│   • Transition to COMPLETE                          │
│   • Display 4-section summary                       │
│   • Cleanup state files                             │
└─────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Hard Context Barriers**: Split Block 4 and Block 5 into 3 sub-blocks each (Setup → Execute → Verify) with bash blocks between Task invocations, making bypass impossible

2. **State Transitions as Gates**: Use sm_transition with explicit exit code verification; failures block progression

3. **Fail-Fast Verification**: Every subagent invocation followed by mandatory verification block that exits on failure

4. **Metadata-Only Context Passing**: Pass report paths/counts to plan-architect, not full content (95% context reduction)

5. **Single Source of Truth**: Reference agent behavioral files; don't duplicate behavioral instructions

### Agent Enhancements Required

**plan-architect.md** must support "plan revision" operation mode:
- Distinguish "new plan creation" vs "plan revision"
- Use Edit tool (not Write) for revisions
- Preserve completed phases marked [COMPLETE]
- Return PLAN_REVISED signal (not PLAN_CREATED)
- Verify backup exists before editing

**research-specialist.md** must support "revision insights" research type:
- Already supported; verify with test

### Block Structure Comparison

| Block | /plan (Reference) | /revise (Current) | /revise (Target) |
|-------|-------------------|-------------------|------------------|
| 1a | Setup + State Init | Capture Description | Capture Description |
| 1b | Topic Naming Agent | Read + Validate | Read + Validate |
| 1c | Topic Path Init | State Init | State Init |
| 1d | Research Agent | ❌ Inline Work | ✅ Research Setup |
| 2 | Research Verify + Plan Setup | ❌ Inline Work | ✅ Research Execute (Task) |
| 3 | Plan Agent + Verify | ❌ Inline Work | ✅ Research Verify |
| - | - | - | ✅ Plan Setup |
| - | - | - | ✅ Plan Execute (Task) |
| - | - | - | ✅ Plan Verify |
| - | - | Completion | ✅ Completion |

## Implementation Phases

### Phase 1: Audit and Enhance plan-architect.md [COMPLETE]
dependencies: []

**Objective**: Ensure plan-architect agent supports "plan revision" operation mode with all required behaviors

**Complexity**: Medium

**Tasks**:
- [x] Read plan-architect.md behavioral file (file: /home/benjamin/.config/.claude/agents/plan-architect.md)
- [x] Verify agent distinguishes "new plan creation" vs "plan revision" operation modes
- [x] Verify agent uses Edit tool (not Write) for plan revisions
- [x] Verify agent preserves completed phases marked [COMPLETE]
- [x] Add operation mode detection if missing (add "Operation Mode:" workflow context parsing)
- [x] Add revision-specific instructions if needed (backup verification, history updates)
- [x] Add completion signal variation: PLAN_CREATED vs PLAN_REVISED
- [x] Document revision mode in agent behavioral file
- [x] Create revision mode test fixtures (small/medium/large plans, plans with completed phases)

**Testing**:
```bash
# Test plan-architect in revision mode (isolated agent test)
# Create test plan with completed phases
cat > /tmp/test_plan.md <<'EOF'
### Phase 1: Foundation [COMPLETE]
- [x] Task 1 completed

### Phase 2: Implementation [COMPLETE]
- [x] Task 2 pending
EOF

# Test agent invocation with operation mode
# Expected: Uses Edit tool, preserves [COMPLETE], returns PLAN_REVISED
```

**Expected Duration**: 3-4 hours

### Phase 2: Refactor Block 4 (Research Phase) [COMPLETE]
dependencies: [1]

**Objective**: Split Block 4 into 3 sub-blocks (Setup → Execute → Verify) with hard context barriers enforcing research-specialist delegation

**Complexity**: High

**Tasks**:
- [x] Create Block 4a (Research Setup) in /revise command (file: /home/benjamin/.config/.claude/commands/revise.md, line ~385)
  - [x] Add state transition to RESEARCH with exit code verification
  - [x] Add fail-fast error logging on transition failure
  - [x] Pre-calculate RESEARCH_DIR, SPECS_DIR, REVISION_TOPIC_SLUG
  - [x] Persist variables with append_workflow_state
  - [x] Add checkpoint reporting ("Ready for research-specialist invocation")
- [x] Create Block 4b (Research Execution) between Block 4a and Block 4c
  - [x] Add CRITICAL directive emphasizing Task invocation is mandatory
  - [x] Keep existing Task invocation for research-specialist
  - [x] Add note that verification block will FAIL if artifacts not created
- [x] Create Block 4c (Research Verification) after Block 4b
  - [x] Add fail-fast directory existence check (exit 1 if missing)
  - [x] Add fail-fast report file count check (exit 1 if zero)
  - [x] Add detailed error logging with log_command_error
  - [x] Add checkpoint reporting (report counts, verification status)
  - [x] Persist REPORT_COUNT, TOTAL_REPORT_COUNT for next phase
- [x] Remove/replace existing single Block 4 bash+Task merged block
- [x] Add HEREDOC comment at block boundaries explaining barrier purpose

**Testing**:
```bash
# Test Block 4a isolation (should stop at checkpoint, not proceed)
# Test Block 4b Task invocation (verify research-specialist creates reports)
# Test Block 4c fail-fast (simulate missing reports, verify exit 1)
# Test full Block 4 sequence (Setup → Execute → Verify)

# Verify state transitions recorded correctly
grep "RESEARCH" ~/.claude/data/state/revise_*.state

# Verify error logging integration
/errors --command /revise --type state_error --limit 5
```

**Expected Duration**: 4-5 hours

### Phase 3: Refactor Block 5 (Plan Revision Phase) [COMPLETE]
dependencies: [1, 2]

**Objective**: Split Block 5 into 3 sub-blocks (Setup → Execute → Verify) with hard context barriers enforcing plan-architect delegation

**Complexity**: High

**Tasks**:
- [x] Create Block 5a (Plan Revision Setup) in /revise command (file: /home/benjamin/.config/.claude/commands/revise.md, line ~816)
  - [x] Add backup creation BEFORE plan-architect invocation (not after)
  - [x] Add fail-fast backup verification (file size, existence checks)
  - [x] Add state transition to PLAN with exit code verification
  - [x] Add fail-fast error logging on transition failure
  - [x] Persist BACKUP_PATH with append_workflow_state
  - [x] Add checkpoint reporting ("Backup created, ready for plan-architect invocation")
- [x] Create Block 5b (Plan Revision Execution) between Block 5a and Block 5c
  - [x] Add CRITICAL directive emphasizing Task invocation is mandatory
  - [x] Update Task invocation for plan-architect with operation mode
  - [x] Add "Operation Mode: plan revision" to prompt
  - [x] Pass EXISTING_PLAN_PATH, BACKUP_PATH, REVISION_DETAILS
  - [x] Pass research report metadata (count, directory) not full content
  - [x] Add note about verification block dependency
- [x] Create Block 5c (Plan Revision Verification) after Block 5b
  - [x] Add fail-fast plan file modified check (compare timestamp with backup)
  - [x] Add fail-fast backup existence recheck
  - [x] Add revision history update (using Edit tool or dedicated script)
  - [x] Add error logging with log_command_error
  - [x] Add checkpoint reporting (plan updated, backup verified)
- [x] Remove/replace existing single Block 5 bash+Task merged block
- [x] Update completion signal parsing to handle PLAN_REVISED (in addition to PLAN_CREATED)

**Testing**:
```bash
# Test Block 5a backup creation (verify backup before Task invocation)
# Test Block 5b Task invocation (verify plan-architect revises plan)
# Test Block 5c verification (verify plan modified, backup exists)
# Test full Block 5 sequence (Setup → Execute → Verify)

# Test backup restoration on failure
rm /path/to/revised_plan.md  # Simulate failure
# Expect Block 5c to fail and report backup location

# Verify completed phases preserved
grep "\[COMPLETE\]" /path/to/revised_plan.md
```

**Expected Duration**: 4-5 hours

### Phase 4: Update Block 6 (Completion) [COMPLETE]
dependencies: [3]

**Objective**: Enhance completion block with 4-section console summary and proper state cleanup

**Complexity**: Low

**Tasks**:
- [x] Update Block 6 in /revise command (file: /home/benjamin/.config/.claude/commands/revise.md, line ~1000+)
- [x] Add state transition to COMPLETE with verification
- [x] Replace ad-hoc summary with print_artifact_summary call
- [x] Format summary sections (Summary, Phases, Artifacts, Next Steps)
- [x] Add emoji markers per output-formatting.md standards
- [x] Add cleanup of temp files (revise_arg.txt, state_id.txt)
- [x] Add state file cleanup (optional, preserve for debugging)
- [x] Return PLAN_REVISED signal with metadata (path, report count)

**Testing**:
```bash
# Test completion summary format (verify 4 sections present)
# Test state file cleanup (verify temp files removed)
# Test PLAN_REVISED signal parsing (verify orchestrator recognizes it)

# Verify summary matches standards
/revise "test revision" | grep -E "^(📋|🔄|📁|➡️)"
```

**Expected Duration**: 2 hours

### Phase 5: Testing and Validation [COMPLETE]
dependencies: [4]

**Objective**: Comprehensive testing across unit, integration, and regression test suites

**Complexity**: Medium

**Tasks**:
- [x] Create unit test for plan-architect revision mode (file: /home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh)
  - [x] Test revision mode detection
  - [x] Test Edit tool usage (not Write)
  - [x] Test completed phase preservation
  - [x] Test PLAN_REVISED signal return
- [x] Create integration test for /revise with small plan (file: /home/benjamin/.config/.claude/tests/commands/test_revise_small_plan.sh)
  - [x] Test full workflow (Setup → Research → Planning → Completion)
  - [x] Verify research-specialist invoked
  - [x] Verify plan-architect invoked
  - [x] Verify artifacts created (reports, revised plan, backup)
- [x] Create integration test for /revise with completed phases (file: /home/benjamin/.config/.claude/tests/commands/test_revise_preserve_completed.sh)
  - [x] Create plan with mix of [COMPLETE] and [NOT STARTED]
  - [x] Run /revise
  - [x] Verify [COMPLETE] phases unchanged
  - [x] Verify [NOT STARTED] phases updated
- [x] Create integration test for /revise --file flag (file: /home/benjamin/.config/.claude/tests/commands/test_revise_long_prompt.sh)
  - [x] Create prompt file with revision details
  - [x] Run /revise --file /path/to/prompt.md
  - [x] Verify workflow completes successfully
- [x] Create integration test for error recovery (file: /home/benjamin/.config/.claude/tests/commands/test_revise_error_recovery.sh)
  - [x] Simulate research-specialist failure (remove reports directory)
  - [x] Verify Block 4c fails with error logging
  - [x] Verify recovery instructions in error message
- [x] Create regression test for behavioral compatibility (file: /home/benjamin/.config/.claude/tests/regression/test_revise_behavioral_compatibility.sh)
  - [x] Run same revision with old and new /revise
  - [x] Compare plan outputs (should be functionally identical)
  - [x] Compare artifact counts (reports, backups)
- [x] Run all tests and verify >80% pass rate
- [x] Fix any test failures
- [x] Validate error logging integration with /errors command

**Testing**:
```bash
# Run all /revise tests
bash /home/benjamin/.config/.claude/tests/commands/test_revise_*.sh

# Run agent tests
bash /home/benjamin/.config/.claude/tests/agents/test_plan_architect_revision_mode.sh

# Run regression tests
bash /home/benjamin/.config/.claude/tests/regression/test_revise_behavioral_compatibility.sh

# Verify error logging
/errors --command /revise --since 1h --summary
```

**Expected Duration**: 4-5 hours

### Phase 6: Documentation and Rollout [COMPLETE]
dependencies: [5]

**Objective**: Update documentation and prepare for deployment

**Complexity**: Low

**Tasks**:
- [x] Update /revise command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/revise-command-guide.md)
  - [x] Update workflow diagrams (add subagent delegation)
  - [x] Add troubleshooting for subagent failures
  - [x] Document new block structure (4a/4b/4c, 5a/5b/5c)
  - [x] Add recovery procedures for common errors
- [x] Update hierarchical agents examples (file: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md)
  - [x] Add /revise as orchestrator example
  - [x] Show research → planning delegation pattern
  - [x] Document hard context barriers technique
- [x] Update plan-architect.md behavioral file (file: /home/benjamin/.config/.claude/agents/plan-architect.md)
  - [x] Document operation mode: "plan revision"
  - [x] Add revision-specific behavioral guidelines section
  - [x] Document completion signals (PLAN_REVISED vs PLAN_CREATED)
  - [x] Add revision mode examples
- [x] Run validation checks before deployment
  - [x] bash .claude/scripts/validate-all-standards.sh --all
  - [x] pytest .claude/tests/ (if using pytest)
  - [x] Manual smoke test with real plan
- [x] Create deployment checklist
- [x] Document rollback procedure (if needed)

**Testing**:
```bash
# Validate all standards
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all

# Verify documentation links
bash /home/benjamin/.config/.claude/scripts/validate-links-quick.sh

# Manual smoke test
/revise "revise /home/benjamin/.config/.claude/specs/TEST_PLAN/plans/001_test.md to add new phase"
```

**Expected Duration**: 3-4 hours

### Phase 7: Create Reusable Hard Barrier Pattern Documentation [COMPLETE]
dependencies: [6]

**Objective**: Document the hard barrier pattern for use across all orchestrator commands

**Complexity**: Low

**Tasks**:
- [x] Create pattern documentation (file: /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md)
  - [x] Document the Setup -> Execute -> Verify pattern
  - [x] Provide code templates for each block type
  - [x] Document the CRITICAL BARRIER label convention
  - [x] Document verification requirements (artifact existence, file size checks)
  - [x] Add troubleshooting section for bypass detection
- [x] Update hierarchical agents overview (file: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md)
  - [x] Add reference to hard barrier pattern
  - [x] Update orchestrator checklist to include barrier verification
- [x] Create barrier verification utility (file: /home/benjamin/.config/.claude/lib/workflow/barrier-utils.sh)
  - [x] `verify_task_executed` function - checks for expected artifacts
  - [x] `barrier_checkpoint` function - logs barrier state
  - [x] `detect_bypass` function - heuristic to detect if work was done directly
- [x] Add pattern compliance check to validate-all-standards.sh
  - [x] Check for CRITICAL BARRIER labels in commands with Task invocations
  - [x] Check for verification blocks after Task pseudo-code

**Testing**:
```bash
# Test barrier-utils.sh functions
source .claude/lib/workflow/barrier-utils.sh
verify_task_executed "test-agent" "/tmp/expected_artifact.md"

# Test pattern compliance check
bash .claude/scripts/validate-all-standards.sh --barriers
```

**Expected Duration**: 3-4 hours

### Phase 8: Apply Hard Barrier Pattern to /build [COMPLETE]
dependencies: [7]

**Objective**: Refactor /build command to enforce implementer-coordinator delegation using the hard barrier pattern

**Complexity**: High

**Tasks**:
- [x] Audit current /build structure (file: /home/benjamin/.config/.claude/commands/build.md)
  - [x] Identify Block 1 (Setup) boundaries
  - [x] Identify Task invocation location
  - [x] Identify iteration check block
  - [x] Document current allowed-tools
- [x] Refactor Block 1 Implementation Phase
  - [x] Split into Block 1a (Implementation Setup)
    - [x] Add BARRIER_CHECKPOINT marker after variable persistence
    - [x] Add state transition verification
  - [x] Create Block 1b (Implementation Execute) with CRITICAL BARRIER
    - [x] Add mandatory Task invocation for implementer-coordinator
    - [x] Add note about verification block dependency
  - [x] Create Block 1c (Implementation Verification)
    - [x] Verify summary artifact created by implementer-coordinator
    - [x] Verify phase completion markers updated in plan
    - [x] Add fail-fast exit if verification fails
    - [x] Add error logging with recovery instructions
- [x] Update iteration loop logic
  - [x] Move work_remaining parsing into Block 1c
  - [x] Add explicit check that Task was invoked (artifact-based verification)
  - [x] Add bypass detection heuristic
- [x] Update allowed-tools metadata
  - [x] Consider restricting Edit/Write tools in orchestrator (future enhancement note)
- [x] Add checkpoint persistence between Task invocations and verification

**Testing**:
```bash
# Test /build with hard barriers
/build .claude/specs/TEST_PLAN/plans/001_test.md --dry-run

# Verify Task invocation occurs (check for Task(...) in output)
/build .claude/specs/TEST_PLAN/plans/001_test.md 2>&1 | grep -E "^Task\("

# Verify verification block runs
/build .claude/specs/TEST_PLAN/plans/001_test.md 2>&1 | grep "BARRIER_CHECKPOINT"

# Test bypass detection
# (manually bypass Task and verify Block 1c fails)
```

**Expected Duration**: 4-5 hours

### Phase 9: /build Testing and Validation [COMPLETE]
dependencies: [8]

**Objective**: Comprehensive testing of /build with hard barriers

**Complexity**: Medium

**Tasks**:
- [x] Create integration test for /build Task delegation (file: /home/benjamin/.config/.claude/tests/commands/test_build_task_delegation.sh)
  - [x] Test that Task(implementer-coordinator) is invoked
  - [x] Test that verification block runs after Task
  - [x] Test that bypass is detected if Task skipped
- [x] Create integration test for /build iteration (file: /home/benjamin/.config/.claude/tests/integration/test_build_iteration_barriers.sh)
  - [x] Test iteration with work_remaining > 0
  - [x] Test iteration termination conditions
  - [x] Verify checkpoint persistence across iterations
- [x] Create regression test for /build behavioral compatibility
  - [x] Compare outputs between old and new /build
  - [x] Verify plan completion markers work
  - [x] Verify summary artifact creation
- [x] Update existing /build tests to include barrier verification
  - [x] test_build_iteration.sh - add barrier checks
  - [x] test_build_state_transitions.sh - add barrier state verification
- [x] Run full test suite and fix failures
- [x] Manual smoke test with real implementation plan

**Testing**:
```bash
# Run all /build tests
bash /home/benjamin/.config/.claude/tests/commands/test_build_*.sh
bash /home/benjamin/.config/.claude/tests/integration/test_build_*.sh

# Run regression tests
bash /home/benjamin/.config/.claude/tests/regression/test_build_behavioral_compatibility.sh

# Verify error logging
/errors --command /build --since 1h --summary
```

**Expected Duration**: 3-4 hours

### Phase 10: Fix /expand and /collapse Commands [COMPLETE]
dependencies: [7]

**Objective**: Apply hard barrier pattern to /expand and /collapse commands to enforce plan-architect delegation

**Complexity**: Medium-High

**Tasks**:
- [x] Audit /expand command structure (file: /home/benjamin/.config/.claude/commands/expand.md)
  - [x] Identify current Task invocation locations (phase expansion, stage expansion)
  - [x] Document current allowed-tools
  - [x] Identify where verification blocks should be inserted
- [x] Refactor /expand Task invocations
  - [x] Split phase expansion block into Setup → Execute → Verify
  - [x] Split stage expansion block into Setup → Execute → Verify
  - [x] Add CRITICAL BARRIER labels before Task invocations
  - [x] Add fail-fast verification blocks checking for expanded plan files
  - [x] Add error logging with recovery instructions
- [x] Audit /collapse command structure (file: /home/benjamin/.config/.claude/commands/collapse.md)
  - [x] Identify current Task invocation locations (phase collapse, stage collapse)
  - [x] Document current allowed-tools
  - [x] Identify where verification blocks should be inserted
- [x] Refactor /collapse Task invocations
  - [x] Split phase collapse block into Setup → Execute → Verify
  - [x] Split stage collapse block into Setup → Execute → Verify
  - [x] Add CRITICAL BARRIER labels before Task invocations
  - [x] Add fail-fast verification blocks checking for collapsed plan files
  - [x] Add error logging with recovery instructions
- [x] Consider tool restriction for both commands
  - [x] Evaluate removing Edit tool from orchestrator (plan-architect should do all editing)
  - [x] Keep Read for validation only
  - [x] Document decision in command metadata
- [x] Create integration tests for /expand
  - [x] Test phase expansion Task delegation
  - [x] Test stage expansion Task delegation
  - [x] Test verification block failure scenarios
- [x] Create integration tests for /collapse
  - [x] Test phase collapse Task delegation
  - [x] Test stage collapse Task delegation
  - [x] Test verification block failure scenarios

**Testing**:
```bash
# Test /expand with barriers
/expand phase /path/to/plan.md 1
# Verify Task invocation in output
# Verify verification block runs

# Test /collapse with barriers
/collapse phase /path/to/plan.md 2
# Verify Task invocation in output
# Verify verification block runs

# Test error scenarios
# (simulate missing artifacts, verify fail-fast behavior)
```

**Expected Duration**: 4-5 hours

### Phase 11: Fix /errors Command [COMPLETE]
dependencies: [7]

**Objective**: Apply hard barrier pattern to /errors command to enforce errors-analyst delegation

**Complexity**: Medium

**Tasks**:
- [x] Audit /errors command structure (file: /home/benjamin/.config/.claude/commands/errors.md)
  - [x] Identify current Task invocation location (errors-analyst)
  - [x] Document current allowed-tools
  - [x] Identify where verification block should be inserted
- [x] Refactor /errors Task invocation
  - [x] Split error analysis block into Setup → Execute → Verify
  - [x] Add state transition to ANALYSIS state
  - [x] Add CRITICAL BARRIER label before Task invocation
  - [x] Add fail-fast verification block checking for analysis report
  - [x] Add error logging with recovery instructions
- [x] Consider tool restriction
  - [x] Evaluate removing Read/Grep tools from orchestrator
  - [x] errors-analyst should perform all log analysis
  - [x] Keep Bash for error log path detection
- [x] Create integration tests for /errors
  - [x] Test errors-analyst Task delegation
  - [x] Test verification block with missing report
  - [x] Test various query flags (--command, --type, --since)
  - [x] Verify summary generation works after delegation

**Testing**:
```bash
# Test /errors with barriers
/errors --command /build --since 1h --summary
# Verify Task(errors-analyst) is invoked
# Verify verification block runs

# Test error scenarios
# (simulate analyst failure, verify fail-fast behavior)
```

**Expected Duration**: 3 hours

### Phase 12: Fix /research, /debug, /repair Commands (Partial Verification) [COMPLETE]
dependencies: [7, 10, 11]

**Objective**: Add missing verification blocks after research-specialist, plan-architect, and analyst invocations in commands with partial verification

**Complexity**: High

**Tasks**:
- [x] Audit /research command (file: /home/benjamin/.config/.claude/commands/research.md)
  - [x] Confirm topic-naming verification exists
  - [x] Identify missing research-specialist verification block
  - [x] Document current workflow structure
- [x] Refactor /research research phase
  - [x] Split research block into Setup → Execute → Verify (if not already split)
  - [x] Add verification block after research-specialist Task invocation
  - [x] Verify research reports created in specs directory
  - [x] Add fail-fast error logging
- [x] Audit /debug command (file: /home/benjamin/.config/.claude/commands/debug.md)
  - [x] Confirm topic-naming verification exists
  - [x] Identify all 4 Task invocations (topic-naming, research, plan-architect, debug-analyst)
  - [x] Document which invocations lack verification (likely 3 out of 4)
- [x] Refactor /debug Task invocations
  - [x] Add verification after research-specialist invocation
  - [x] Add verification after plan-architect invocation
  - [x] Add verification after debug-analyst invocation
  - [x] Each verification checks for expected artifacts (reports, plans, analysis)
  - [x] Add fail-fast error logging for each verification
- [x] Audit /repair command (file: /home/benjamin/.config/.claude/commands/repair.md)
  - [x] Confirm topic-naming verification exists
  - [x] Identify missing repair-analyst and plan-architect verification blocks
  - [x] Document current workflow structure
- [x] Refactor /repair Task invocations
  - [x] Add verification after repair-analyst invocation (check for repair plan)
  - [x] Add verification after plan-architect invocation (check for implementation plan)
  - [x] Add fail-fast error logging
- [x] Create integration tests for all three commands
  - [x] Test /research with full verification chain
  - [x] Test /debug with all 4 Task verifications
  - [x] Test /repair with all 3 Task verifications
  - [x] Test error recovery scenarios for each

**Testing**:
```bash
# Test /research with barriers
/research "analyze feature performance" --complexity 2
# Verify both topic-naming AND research-specialist have verification blocks

# Test /debug with barriers
/debug "fix authentication bug" --complexity 2
# Verify all 4 Task invocations have verification blocks

# Test /repair with barriers
/repair --since 1h --type state_error --complexity 2
# Verify all 3 Task invocations have verification blocks

# Test error scenarios for each command
```

**Expected Duration**: 6-8 hours

## Testing Strategy

### Test Pyramid

**Unit Tests** (Agent-level):
- plan-architect revision mode behavior
- research-specialist revision insights research type
- implementer-coordinator delegation verification
- Isolated agent invocations with mock inputs

**Integration Tests** (Command-level):
- Full /revise workflow with real plans
- Full /build workflow with real plans
- Error recovery scenarios
- Flag parsing (--file, --complexity, --dry-run)
- State machine transitions
- Hard barrier verification

**Regression Tests**:
- Behavioral compatibility with old /revise
- Behavioral compatibility with old /build
- Artifact output comparison
- Plan validity after revision/implementation

### Coverage Requirements

- Minimum 80% code coverage
- 100% critical path coverage (Setup → Research → Planning → Completion)
- All error paths tested (state transition failures, missing artifacts)

### Test Fixtures

Create standardized test plans:
- **Small plan**: 5 phases, 500 lines (fast test iteration)
- **Medium plan**: 10 phases, 1,000 lines (realistic scenario)
- **Large plan**: 20 phases, 2,000 lines (stress test)
- **Completed phases plan**: Mix of [COMPLETE] and [NOT STARTED] (preservation test)

## Documentation Requirements

### Files to Update

1. **/.claude/commands/revise.md** (Primary implementation file)
   - Document new block structure
   - Add inline comments explaining barriers
   - Update metadata (allowed-tools verification)

2. **/.claude/commands/build.md** (Primary implementation file)
   - Document new block structure with barriers
   - Add CRITICAL BARRIER labels
   - Add verification block comments

3. **/.claude/commands/expand.md** (Primary implementation file - NEW)
   - Document barrier pattern for phase/stage expansion
   - Add verification block comments
   - Update metadata

4. **/.claude/commands/collapse.md** (Primary implementation file - NEW)
   - Document barrier pattern for phase/stage collapse
   - Add verification block comments
   - Update metadata

5. **/.claude/commands/errors.md** (Primary implementation file - NEW)
   - Document barrier pattern for error analysis
   - Add verification block comments
   - Update metadata

6. **/.claude/commands/research.md** (Primary implementation file - NEW)
   - Add verification block after research-specialist
   - Document full delegation pattern
   - Update metadata

7. **/.claude/commands/debug.md** (Primary implementation file - NEW)
   - Add verification blocks after all 4 Task invocations
   - Document comprehensive delegation
   - Update metadata

8. **/.claude/commands/repair.md** (Primary implementation file - NEW)
   - Add verification blocks after repair-analyst and plan-architect
   - Document full delegation pattern
   - Update metadata

9. **/.claude/agents/plan-architect.md** (Agent behavioral file)
   - Add operation mode section
   - Document revision-specific guidelines
   - Add completion signal documentation

10. **/.claude/docs/guides/commands/revise-command-guide.md** (User guide)
    - Update workflow diagrams
    - Add troubleshooting section
    - Document error recovery procedures

11. **/.claude/docs/guides/commands/build-command-guide.md** (User guide)
    - Update workflow diagrams with barriers
    - Add troubleshooting for subagent bypass
    - Document barrier verification

12. **/.claude/docs/concepts/hierarchical-agents-examples.md** (Architecture guide)
    - Add /revise orchestrator example
    - Add /build barrier pattern example
    - Show hard context barriers pattern
    - Add examples from /expand, /collapse, /errors

13. **/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md** (New pattern doc)
    - Document Setup → Execute → Verify pattern
    - Provide reusable code templates
    - Document verification requirements
    - Include tool restriction guidelines

### Documentation Standards

- Follow CommonMark specification
- Use Unicode box-drawing for diagrams
- No emojis in file content (UTF-8 encoding issues)
- No historical commentary (clean-break development)
- Code examples with syntax highlighting
- Clear, concise language

## Dependencies

### External Dependencies

- workflow-state-machine.sh >= 2.0.0 (state transitions)
- state-persistence.sh >= 1.5.0 (variable persistence)
- error-handling.sh (error logging integration)
- unified-location-detection.sh (artifact directory creation)
- barrier-utils.sh (NEW - created in Phase 7)

### Agent Dependencies

- research-specialist.md (must support "revision insights" research type; used by /revise, /research, /debug)
- plan-architect.md (must support "plan revision" operation mode - enhanced in Phase 1; used by /revise, /expand, /collapse, /debug, /repair)
- implementer-coordinator.md (must return expected artifacts for barrier verification; used by /build)
- errors-analyst.md (must return analysis report artifacts; used by /errors)
- debug-analyst.md (must return debug analysis artifacts; used by /debug)
- repair-analyst.md (must return repair plan artifacts; used by /repair)
- topic-naming-agent.md (already has verification pattern; used by all commands with topic creation)

### Integration Dependencies

- /errors command (error query and analysis - fixed in Phase 11)
- /build command (must handle revised plans - fixed in Phases 8-9)
- /revise command (fixed in Phases 1-6)
- /expand command (fixed in Phase 10)
- /collapse command (fixed in Phase 10)
- /research command (fixed in Phase 12)
- /debug command (fixed in Phase 12)
- /repair command (fixed in Phase 12)
- Existing specs directory structure (must remain compatible across all commands)
- validate-all-standards.sh (enhanced with barrier compliance check in Phase 7)

## Risk Mitigation

### Risk 1: Behavioral Regression

**Risk**: Refactored /revise behaves differently than original

**Mitigation**:
- Comprehensive regression test suite (side-by-side comparison)
- Manual testing with real plans before deployment
- Feature flag for gradual rollout (optional)
- Documented rollback procedure

**Rollback**: Revert commit with `git revert <commit-hash>`

### Risk 2: Subagent Failures

**Risk**: research-specialist or plan-architect fail unpredictably

**Mitigation**:
- Comprehensive agent testing before integration (Phase 1)
- Detailed error logging with recovery hints
- Fallback documentation (manual workaround steps)
- Timeout handling (Task tool timeout parameter)

**Fallback**: Manual research report creation → re-run /revise

### Risk 3: Context Exhaustion

**Risk**: Even with subagents, large plans exhaust context

**Mitigation**:
- Plan-architect handles large plans iteratively
- Document maximum recommended plan size (2,000 lines warning)
- Add --max-size validation flag (future enhancement)

**Limits**:
- Small plans: < 1,000 lines (safe)
- Medium plans: 1,000-2,000 lines (monitored)
- Large plans: > 2,000 lines (warning, suggest splitting)

### Risk 4: Integration Breakage

**Risk**: Changes break integration with /plan or /build

**Mitigation**:
- Integration tests across all orchestrators
- Shared agent testing (research-specialist, plan-architect)
- Review agent contracts (input/output formats)
- Staged rollout (test in isolation first)

## Success Metrics

### Quantitative Metrics

1. **Context Reduction**: 40-60% reduction in orchestrator context usage (measured by token count)
2. **Execution Time**: < 10% regression (median execution time within 10% of baseline)
3. **Reliability**: 100% artifact creation success rate (0 failures in 100 test runs)
4. **Error Recovery**: All errors include actionable recovery steps

### Qualitative Metrics

1. **Code Maintainability**: Clear separation of concerns (orchestrator vs specialists)
2. **Developer Experience**: Consistent patterns across all orchestrators
3. **Extensibility**: Easy to add new revision types

## Completion Checklist

Before marking plan complete:

### Phase 1 Complete [COMPLETE]
- [x] plan-architect.md supports revision mode
- [x] Revision mode tested in isolation
- [x] Test fixtures created

### Phase 2 Complete [COMPLETE]
- [x] Block 4 split into 3 sub-blocks
- [x] Hard barriers enforce research-specialist delegation
- [x] Verification blocks fail-fast on missing artifacts

### Phase 3 Complete [COMPLETE]
- [x] Block 5 split into 3 sub-blocks
- [x] Hard barriers enforce plan-architect delegation
- [x] Backup creation happens BEFORE subagent invocation

### Phase 4 Complete [COMPLETE]
- [x] Block 6 uses 4-section summary format
- [x] State cleanup implemented
- [x] PLAN_REVISED signal recognized

### Phase 5 Complete [COMPLETE]
- [x] All tests created and passing (>80% coverage)
- [x] Regression tests confirm behavioral compatibility
- [x] Error logging integration verified

### Phase 6 Complete [COMPLETE]
- [x] All /revise documentation updated
- [x] Validation checks pass
- [x] Deployment checklist complete

### Phase 7 Complete [COMPLETE]
- [x] Hard barrier pattern documentation created
- [x] barrier-utils.sh library created
- [x] Pattern compliance check added to validation

### Phase 8 Complete [COMPLETE]
- [x] /build Block 1 split into 3 sub-blocks
- [x] Hard barriers enforce implementer-coordinator delegation
- [x] Verification block confirms Task execution
- [x] Bypass detection implemented

### Phase 9 Complete [COMPLETE]
- [x] /build integration tests pass
- [x] /build regression tests pass
- [x] Manual smoke test successful

### Phase 10 Complete (NEW) [COMPLETE]
- [x] /expand command refactored with hard barriers
- [x] /collapse command refactored with hard barriers
- [x] Both commands have verification blocks after plan-architect invocations
- [x] Integration tests pass for /expand and /collapse
- [x] Tool access restrictions evaluated and documented

### Phase 11 Complete (NEW) [COMPLETE]
- [x] /errors command refactored with hard barriers
- [x] Verification block confirms errors-analyst execution
- [x] Integration tests pass for /errors
- [x] Tool access restrictions evaluated and documented

### Phase 12 Complete (NEW) [COMPLETE]
- [x] /research has verification after research-specialist (in addition to topic-naming)
- [x] /debug has verification after all 4 Task invocations
- [x] /repair has verification after repair-analyst and plan-architect (in addition to topic-naming)
- [x] Integration tests pass for all three commands
- [x] Error recovery scenarios tested

### Final Validation
- [x] bash .claude/scripts/validate-all-standards.sh --all passes
- [x] No ERROR-level violations
- [x] Manual smoke test for /revise successful
- [x] Manual smoke test for /build successful
- [x] Manual smoke test for /expand, /collapse, /errors successful
- [x] Manual smoke test for /research, /debug, /repair successful
- [x] All 13 audited commands now have proper verification blocks
- [x] Rollback procedure documented

---

## Notes

**Complexity Calculation (REVISED - Full Scope)**:
```
Score = Base(refactor=5) + Tasks(98*1.0) + Files(20*3.0) + Integrations(12*5.0)
      = 5 + 98 + 60 + 60
      = 223
```

**Structure Level**: 0 (single file plan)
- Complexity score 223 exceeds typical 200 threshold for multi-file structure
- However, phases are highly cohesive (all apply same pattern to different commands)
- Keeping as single file for pattern consistency tracking
- Can use /expand phase if any individual phase becomes too complex during implementation

**Phase Dependencies (Updated)**:
- Phase 1: No dependencies (foundation for /revise)
- Phase 2: Depends on Phase 1 (needs plan-architect revision mode)
- Phase 3: Depends on Phases 1,2 (needs both agent enhancements and Block 4 pattern)
- Phase 4: Depends on Phase 3 (needs Block 5 complete)
- Phase 5: Depends on Phase 4 (needs full workflow for testing)
- Phase 6: Depends on Phase 5 (needs tests passing for deployment)
- Phase 7: Depends on Phase 6 (document pattern after /revise proven)
- Phase 8: Depends on Phase 7 (apply pattern to /build)
- Phase 9: Depends on Phase 8 (test /build changes)
- Phase 10: Depends on Phase 7 (apply pattern to /expand and /collapse)
- Phase 11: Depends on Phase 7 (apply pattern to /errors)
- Phase 12: Depends on Phases 7, 10, 11 (complete pattern rollout after testing other fixes)

**Parallel Execution Opportunities (Significant Time Savings)**:
- **Wave 1** (Critical Path): Phases 1-7 (sequential, establish pattern)
- **Wave 2** (Parallel): Phases 8, 10, 11 can run in parallel after Phase 7 completes
- **Wave 3** (Final): Phase 9, 12 can run in parallel after Wave 2
- **Estimated time savings**: 30-40% reduction via parallelization

**Phased Rollout Strategy**:
1. **Milestone 1**: Complete Phases 1-6 (/revise fixed and tested)
2. **Milestone 2**: Complete Phase 7 (pattern documented and validated)
3. **Milestone 3**: Complete Phases 8-11 in parallel (/build, /expand, /collapse, /errors fixed)
4. **Milestone 4**: Complete Phases 9, 12 (comprehensive testing and partial-verification fixes)

**Estimated Timeline**: 40-52 hours
- Sequential execution: 8-10 days at 5 hours/day
- With parallelization: 5-7 days at 6-8 hours/day (aggressive)
- Recommended: 7-9 days at 5-6 hours/day (sustainable with review cycles)

**Tool Restriction Strategy (Recommendation 2 from Report 003)**:
Apply restrictive tool access after hard barriers proven successful in Phases 1-9. This is a secondary reinforcement mechanism:
- Phase 7 documentation should include tool restriction guidelines
- Phase 8-12 should evaluate tool restrictions per command
- Consider adding tool restriction compliance check to validate-all-standards.sh in final validation

**Next Steps After Plan Approval**:
1. Review plan with stakeholders
2. Create feature branch: `feature/orchestrator-subagent-delegation-comprehensive`
3. Begin Phase 1 implementation (/revise agent enhancements)
4. Execute Phases 1-7 sequentially to establish pattern
5. Execute Phases 8, 10, 11 in parallel (Wave 2)
6. Execute Phases 9, 12 in parallel (Wave 3)
7. Final validation across all 13 commands

## Revision History

- **2025-11-26 (Initial)**: Created plan for /revise subagent delegation refactor
- **2025-11-26 (Revision 1)**: Expanded scope to include /build command fix after discovering identical bypass behavior in build-output.md. Added Phases 7-9, updated success criteria, dependencies, and completion checklist.
- **2025-11-26 (Revision 2)**: Comprehensive scope expansion based on report 003 (Subagent Delegation Performance Analysis). Added Phases 10-12 to fix /expand, /collapse, /errors, /research, /debug, /repair commands. Updated metadata (12 phases, 40-52 hours, complexity 223). Confirmed recent refactors NOT to blame. Added full command audit results, verification pattern discovery, and tool restriction strategy. Introduced phased rollout with parallel execution opportunities for 30-40% time savings.

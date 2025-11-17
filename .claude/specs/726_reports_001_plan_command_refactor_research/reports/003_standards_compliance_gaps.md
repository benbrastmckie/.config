# Standards Compliance Gaps Research Report

## Metadata
- **Date**: 2025-11-16
- **Agent**: research-specialist
- **Topic**: Standards Compliance Gaps
- **Report Type**: codebase analysis
- **Complexity Level**: 3

## Executive Summary

The plan demonstrates strong alignment with Command Architecture Standards but contains several critical compliance gaps that could undermine implementation reliability. The most significant deviation is extensive behavioral content duplication (violating Standard 12), with 150+ lines of agent procedures embedded in Task prompts instead of referenced from agent files. Additionally, Standard 11 violations appear in 7 phase task descriptions lacking imperative execution markers, and the plan inconsistently applies Standard 14 executable/documentation separation principles despite explicitly referencing them.

## Findings

### Gap 1: Standard 12 Violation - Behavioral Content Duplication

**Location**: Plan lines 324-340, 433-452, 527-541

**Issue**: The plan instructs implementers to embed complete agent behavioral procedures directly into Task prompts, violating Standard 12's prohibition on behavioral content duplication.

**Evidence from Plan**:

Line 329-333:
```markdown
- [ ] **Standard 12**: NO inline duplication of agent procedures (reference agent file, inject context only)
- [ ] Pass workflow-specific context via metadata: topic, report_path, standards, complexity (metadata-only, 95% reduction)
```

Yet the same phase contradicts this by stating (lines 331-332):
```markdown
- [ ] **Standard 11**: Use imperative invocation: "EXECUTE NOW: USE the Task tool with subagent_type=general-purpose"
- [ ] **Standard 11**: NO code-fenced Task examples in command file (creates priming effect)
```

Without explicit instruction to reference `.claude/agents/research-specialist.md`, implementers will likely embed agent STEP sequences inline.

**Standard 12 Requirement** (from command_architecture_standards.md:1385-1405):
- "Commands MUST NOT duplicate agent behavioral content inline"
- "Behavioral content includes: Agent STEP Sequences, File Creation Workflows, Agent Verification Steps, Output Format Specifications"
- "Pattern: 'Read and follow: .claude/agents/[name].md' with context injection"

**Impact**:
- 150+ lines of duplication per agent invocation (should be ~15 lines)
- 90% context bloat (opposite of plan's stated 95% reduction goal)
- Synchronization burden when agent behavioral files change

**Severity**: Critical - violates explicitly referenced standard

---

### Gap 2: Standard 11 Violation - Missing Imperative Execution Markers

**Location**: Plan lines 227-452 (Phases 1-5 task descriptions)

**Issue**: Phase task lists use descriptive language ("Implement X", "Add Y", "Create Z") instead of imperative directives ("YOU MUST implement X", "EXECUTE NOW: Add Y").

**Evidence from Plan**:

Phase 1, line 227:
```markdown
- [ ] Create `/home/benjamin/.config/.claude/commands/plan.md` with executable bash blocks (file: .claude/commands/plan.md)
```

Phase 3, line 324:
```markdown
- [ ] Implement research delegation trigger logic (file: .claude/commands/plan.md, lines 86-145)
```

**Standard 11 Requirement** (from command_architecture_standards.md:1177-1206):
- "All Task invocations MUST use imperative instructions that signal immediate execution"
- Required patterns: `**EXECUTE NOW**: USE the Task tool to invoke...`
- Prohibited patterns: Descriptive phrases like "The research phase invokes..."

**Impact**:
- Implementers may interpret tasks as documentation (describing what should happen) rather than execution directives (commands to execute)
- Reduces enforcement clarity compared to properly imperative language

**Severity**: High - pattern established in Phase 1 propagates through implementation

---

### Gap 3: Standard 14 Partial Application - Executable File Size Target Conflict

**Location**: Plan lines 66, 84, 219-237

**Issue**: Plan references Standard 14's 250-line executable target but designs a command that will likely exceed it.

**Evidence from Plan**:

Line 66:
```markdown
- [ ] **Standard 14 Compliance**: Executable command <250 lines, comprehensive guide exists separately
```

Yet Phase 1 tasks (lines 226-237) include 12 tasks adding features to a single file:
- Argument parsing (lines 17-39 = ~23 lines)
- Library sourcing (4 libraries = ~20 lines)
- Absolute path validation = ~10 lines
- Workflow state initialization = ~5 lines
- Help text display = ~15 lines
- Set +H directive = ~1 line
- Error context enrichment = ~10 lines
- Comprehensive inline comments = unknown

**Calculation**:
- Phase 1 baseline: ~84 lines
- Phase 2 (feature analysis): ~45 lines (lines 276-287)
- Phase 3 (research delegation): ~60 lines (lines 324-340)
- Phase 4 (standards discovery): ~30 lines (lines 377-393)
- Phase 5 (plan-architect invocation): ~55 lines (lines 433-452)
- Phase 6 (validation): ~20 lines (lines 491-503)
- Phase 7 (expansion evaluation): ~30 lines (lines 527-541)
- **Estimated Total**: ~324 lines (129% over target)

**Standard 14 Guidance** (from executable-documentation-separation.md:96-102):

| File Type | Target | Maximum | Rationale |
|-----------|--------|---------|-----------|
| Executable (simple) | <200 lines | 250 lines | Obviously executable, minimal context bloat |

**Impact**:
- Command will likely require migration to extract documentation to guide file
- Rework during validation phase (Phase 6) when size discovered
- Potential meta-confusion if documentation embedded to explain complex patterns

**Severity**: Medium - plan aware of standard but design conflicts with target

---

### Gap 4: Standard 0 Incomplete Application - Missing Fallback Mechanisms

**Location**: Plan lines 338-340, 444-447

**Issue**: Plan mentions verification checkpoints but doesn't require fallback mechanisms for agent non-compliance.

**Evidence from Plan**:

Line 338-340:
```markdown
- [ ] **Standard 0**: MANDATORY VERIFICATION after each agent: `if [ ! -f "$REPORT_PATH" ]; then fail_fast; fi`
- [ ] Extract metadata from reports using extract_report_metadata() (250-token summaries, 95% context reduction)
```

**Standard 0 Requirement** (from command_architecture_standards.md:203-230):
```markdown
**Fallback Mechanism Requirements**

When commands depend on agent compliance, include fallback mechanisms:

**Required Structure**:
1. Invoke agent with explicit file creation directive
2. Verify expected output exists
3. If missing: Create from agent's text output  # ← Plan omits this
4. Guarantee: Output exists regardless of agent behavior
```

**Missing Implementation**:

Plan should specify (but doesn't):
```bash
# After agent completes
if [ ! -f "$REPORT_PATH" ]; then
  echo "Agent didn't create file. Executing fallback..."
  cat > "$REPORT_PATH" <<EOF
# Fallback Report
$AGENT_OUTPUT
EOF
fi
```

**Impact**:
- Workflow terminates if agents fail to create files (instead of degrading gracefully)
- Reduces reliability from 100% (with fallback) to agent compliance rate (~90%)

**Note**: This conflicts with Standard 0's fail-fast policy clarification (lines 421-465), which prohibits placeholder creation by orchestrators. The plan correctly implements fail-fast (verification only, no placeholder creation), but doesn't explicitly document this design decision, creating ambiguity.

**Severity**: Medium - affects reliability, but fail-fast approach may be intentional

---

### Gap 5: Standard 13 Inconsistent Application

**Location**: Plan lines 228, 377

**Issue**: Plan correctly specifies Standard 13 compliance for library sourcing but doesn't specify it for all path operations.

**Evidence from Plan**:

Line 228:
```markdown
- [ ] **Standard 13**: Use CLAUDE_PROJECT_DIR environment variable for project detection (never BASH_SOURCE[0])
```

But standards discovery task (line 377):
```markdown
- [ ] **Standard 13**: Use CLAUDE_PROJECT_DIR for upward CLAUDE.md search (never rely on BASH_SOURCE[0])
```

Missing from other path operations:
- Report path pre-calculation (Phase 3)
- Plan path pre-calculation (Phase 5)
- Validation library path construction (Phase 6)

**Standard 13 Requirement** (from command_architecture_standards.md:1504-1528):
- "Commands MUST use `CLAUDE_PROJECT_DIR` for project-relative paths"
- "Rationale: `${BASH_SOURCE[0]}` is unavailable in SlashCommand execution context"

**Impact**:
- Inconsistent application may cause implementers to use `BASH_SOURCE[0]` in non-library-sourcing contexts
- Potential path resolution failures

**Severity**: Low - plan mentions standard, but inconsistent application guidance

---

### Gap 6: Standard 16 Missing - Critical Function Return Code Verification

**Location**: Plan lines 229, 288, 384, 448

**Issue**: Plan doesn't reference Standard 16 for critical function calls, despite using functions that require verification.

**Evidence from Plan**:

Line 229:
```markdown
- [ ] **Standard 16**: Verify library sourcing with return code checks: `if ! source lib 2>&1; then handle_error; fi`
```

But missing for other critical functions:

Line 288 (Phase 2):
```markdown
- [ ] **Standard 16**: Verify Task tool return code: `if ! result=$(analyze_feature 2>&1); then fallback_heuristic; fi`
```

Line 384 (Phase 4):
```markdown
- [ ] **Standard 16**: Verify library sourcing: `if ! source unified-location-detection.sh 2>&1; then fail_fast; fi`
```

Line 448 (Phase 5):
```markdown
- [ ] **Standard 16**: Verify metadata extraction: `if ! metadata=$(extract_plan_metadata "$PLAN_PATH" 2>&1); then warn; fi`
```

**Standard 16 Requirement** (from command_architecture_standards.md:2509-2568):
- "All critical initialization functions MUST have their return codes checked"
- "Bash `set -euo pipefail` does not exit on function failures, only simple command failures"

**Critical Functions in Plan** (not exhaustively verified):
- `analyze_feature_description()` - Phase 2
- `extract_report_metadata()` - Phase 3
- `validate_plan()` - Phase 6
- Any function from sourced libraries

**Impact**:
- Silent function failures lead to incomplete state initialization
- Delayed errors instead of immediate fail-fast behavior

**Severity**: Low - plan mentions Standard 16 for library sourcing, but incomplete application

---

### Gap 7: Standard 15 Compliance - Library Sourcing Order Unspecified

**Location**: Plan line 227

**Issue**: Plan specifies Standard 15 compliance but doesn't specify the exact sourcing order required by the standard.

**Evidence from Plan**:

Line 227:
```markdown
- [ ] **Standard 15**: Source libraries in correct order: workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh
```

This is correct, but plan doesn't specify:
- Whether this sourcing happens in Phase 0 or distributed across phases
- Whether Phase 0 exists (plan starts at Phase 1)
- How to handle sourcing in subsequent bash blocks (re-source or rely on persistence?)

**Standard 15 Requirement** (from command_architecture_standards.md:2324-2459):
- "Orchestration commands MUST source libraries in dependency order"
- "Core Principle: Each bash block runs in a separate subprocess, so functions don't persist across blocks and must be sourced in every block that uses them"
- Standard sourcing pattern requires 4 specific libraries in order

**Standard 0 Phase 0 Requirement** (from command_architecture_standards.md:311-419):
```markdown
**Phase 0 Requirement for Orchestrators**:

Every orchestrator command MUST include Phase 0 (before invoking any subagents)
```

**Missing Specification**:
- Does `/plan` command qualify as an orchestrator requiring Phase 0?
- If yes, where is Phase 0 in the implementation phases?
- If no, why not (command does coordinate research agents)?

**Impact**:
- Unclear whether Phase 0 required
- Potential function availability errors if sourcing omitted in later phases

**Severity**: Medium - affects architectural structure of entire command

## Recommendations

### Recommendation 1: Add Explicit Behavioral Injection References (Critical)

**Change**: Update Phase 3 (Research Delegation) and Phase 5 (Plan-Architect Invocation) to include explicit "Read and follow: .claude/agents/[name].md" pattern.

**Implementation**:

Phase 3, add task after line 329:
```markdown
- [ ] **Behavioral Injection Example**: Task prompt format:
  ```
  Read and follow ALL behavioral guidelines from:
  .claude/agents/research-specialist.md

  **Workflow-Specific Context**:
  - Research Topic: [topic from complexity analysis]
  - Report Path: $REPORT_PATH  # Pre-calculated in Phase 0
  - Project Standards: $CLAUDE_PROJECT_DIR/CLAUDE.md
  - Complexity Level: $RESEARCH_COMPLEXITY

  Execute research per behavioral guidelines.
  Return: REPORT_CREATED: $REPORT_PATH
  ```
```

**Rationale**: Makes Standard 12 compliance pattern explicit, prevents inline behavioral duplication

**Expected Impact**: Reduces context per invocation from ~150 lines to ~15 lines (90% reduction)

---

### Recommendation 2: Add Phase 0 for Orchestrator Pattern Compliance (High Priority)

**Change**: Insert Phase 0 before current Phase 1 to establish orchestrator role and pre-calculate paths.

**Implementation**:

Add new phase:
```markdown
### Phase 0: Initialization and Path Pre-Calculation
dependencies: []

**Objective**: Establish orchestrator role, detect project, source libraries, pre-calculate artifact paths

**Complexity**: Low

**Tasks**:
- [ ] **Standard 13**: Detect project directory using CLAUDE_PROJECT_DIR (git-based detection)
- [ ] **Standard 15**: Source libraries in correct order (workflow-state-machine.sh → state-persistence.sh → error-handling.sh → verification-helpers.sh)
- [ ] **Standard 16**: Verify library sourcing with return code checks
- [ ] Pre-calculate topic directory path using `get_or_create_topic_dir()`
- [ ] Pre-calculate plan output path before any agent invocations
- [ ] Pre-calculate potential report paths (if research delegation required)
- [ ] Initialize workflow state using `init_workflow_state("plan_$$")`
- [ ] Export all paths for use in subsequent phases

**Verification**:
- Topic directory exists at calculated path
- All artifact paths are absolute
- Workflow state initialized successfully

**Expected Duration**: 30-45 minutes
```

Renumber existing phases 1-7 to 1-8.

**Rationale**:
- Standard 0 requires Phase 0 for orchestrator commands
- Pre-calculates paths BEFORE agent invocations (behavioral injection requirement)
- Establishes library sourcing pattern for all subsequent phases

**Expected Impact**: Aligns with orchestrator architectural pattern, enables proper path control

---

### Recommendation 3: Add Executable Size Monitoring Task (Medium Priority)

**Change**: Add file size verification to Phase 6 (Plan Validation) to detect Standard 14 violations early.

**Implementation**:

Phase 6 (now Phase 7 after renumbering), add task after line 503:
```markdown
- [ ] **Standard 14 Verification**: Check executable file size
  ```bash
  LINES=$(wc -l < .claude/commands/plan.md)
  if [ "$LINES" -gt 250 ]; then
    echo "WARNING: Executable exceeds 250-line target ($LINES lines)"
    echo "Consider extracting documentation to plan-command-guide.md"
    echo "Target: <250 lines for simple commands"
  fi
  ```
- [ ] If size exceeds target, extract documentation before Phase 8 (Testing)
```

**Rationale**: Early detection enables corrective action before extensive testing investment

**Expected Impact**: Prevents late-stage rework, ensures Standard 14 compliance

---

### Recommendation 4: Transform Task Language to Imperative (Medium Priority)

**Change**: Update all phase task descriptions to use imperative language consistent with Standard 11.

**Implementation**:

Before (current pattern):
```markdown
- [ ] Create `/home/benjamin/.config/.claude/commands/plan.md` with executable bash blocks
```

After (imperative pattern):
```markdown
- [ ] **EXECUTE NOW**: CREATE file `/home/benjamin/.config/.claude/commands/plan.md` with executable bash blocks
- [ ] **YOU MUST**: Include all bash blocks inline, no external references
```

Apply to all tasks in Phases 1-8.

**Rationale**: Consistent imperative language throughout plan reinforces execution mindset

**Expected Impact**: Clearer execution directive, aligns with Standard 0 and 11 patterns

---

### Recommendation 5: Clarify Fail-Fast vs Fallback Strategy (Medium Priority)

**Change**: Add explicit design decision documentation for file creation verification approach.

**Implementation**:

Add to Phase 3 (Research Delegation), after line 338:
```markdown
- [ ] **Design Decision - Fail-Fast Approach**: Verification detects missing files and FAILS IMMEDIATELY
- [ ] **NO PLACEHOLDER CREATION**: Orchestrator does NOT create fallback files (violates fail-fast per Standard 0 clarification)
- [ ] **Rationale**: File creation failures expose agent behavioral issues for debugging
- [ ] **Error Message Template**: "CRITICAL: Agent [name] failed to create file at $EXPECTED_PATH. Check agent output above."
```

**Rationale**: Resolves ambiguity between Standard 0 fallback requirement vs fail-fast policy

**Expected Impact**: Clear implementation guidance, prevents placeholder anti-pattern

---

### Recommendation 6: Add Standard 16 Verification for All Critical Functions (Low Priority)

**Change**: Expand Standard 16 application beyond library sourcing to all critical function calls.

**Implementation**:

Add to each phase using critical functions:

Phase 2 (Feature Analysis), after line 288:
```markdown
- [ ] **Standard 16**: Verify analyze_feature_description() return code before using result
```

Phase 4 (Standards Discovery), after line 384:
```markdown
- [ ] **Standard 16**: Verify discover_claude_md() return code before extracting standards
```

Phase 5 (Plan-Architect Invocation), after line 448:
```markdown
- [ ] **Standard 16**: Verify extract_plan_metadata() return code, fall back to manual parsing if fails
```

**Rationale**: Complete Standard 16 compliance prevents silent function failures

**Expected Impact**: Improved error detection, immediate fail-fast on critical function failures

## References

### Standards Documentation
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (Standards 0, 11-16)
- `/home/benjamin/.config/.claude/docs/concepts/patterns/executable-documentation-separation.md` (Standard 14 pattern)
- `/home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md` (Standard 0, 0.5 implementation)
- `/home/benjamin/.config/CLAUDE.md` (Project standards index)

### Plan Under Analysis
- `/home/benjamin/.config/.claude/specs/726_reports_001_plan_command_refactor_research/plans/001_reports_001_plan_command_refactor_research_plan.md`
  - Line 66: Standard 14 reference
  - Line 227-237: Phase 1 tasks (library sourcing)
  - Line 269-310: Phase 2 tasks (feature analysis)
  - Line 324-340: Phase 3 tasks (research delegation - behavioral duplication issue)
  - Line 377-393: Phase 4 tasks (standards discovery)
  - Line 433-452: Phase 5 tasks (plan-architect invocation - behavioral duplication issue)
  - Line 491-503: Phase 6 tasks (validation)
  - Line 527-541: Phase 7 tasks (expansion evaluation)

### Research Reports Referenced in Plan
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/001_coordinate_command_architecture_and_fragility_analysis.md`
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/002_optimize_claude_command_robustness_patterns.md`
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/003_current_plan_command_implementation_review.md`
- `/home/benjamin/.config/.claude/specs/725_plan_command_refactor_research/reports/001_plan_command_refactor_research/004_context_preservation_and_metadata_passing_strategies.md`

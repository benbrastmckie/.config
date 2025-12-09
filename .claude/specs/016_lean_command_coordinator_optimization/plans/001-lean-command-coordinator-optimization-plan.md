# Lean Command Coordinator Optimization Implementation Plan

## Metadata
- **Date**: 2025-12-08
- **Feature**: Optimize /lean-plan and /lean-implement commands via research-coordinator integration and hard barrier pattern enforcement
- **Scope**: Integrate research-coordinator agent for parallel multi-topic research with 95% context reduction, enforce hard barrier pattern in /lean-implement to prevent delegation bypass, implement wave-based orchestration via implementer-coordinator, add metadata-only context passing, and implement brief summary parsing for 96% context reduction
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Complexity Score**: 85.5
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/lean-plan Command Analysis](../reports/001-lean-plan-analysis.md)
  - [/lean-implement Command Analysis](../reports/002-lean-implement-analysis.md)

## Overview

The /lean-plan and /lean-implement commands currently operate with inefficient context management patterns: /lean-plan invokes lean-research-specialist directly without coordinator delegation (missing 95% context reduction from metadata-only passing and 40-60% time savings from parallel execution), while /lean-implement's primary agent performs implementation work directly instead of delegating to coordinators (bypassing hard barrier validation and consuming excessive context). This plan optimizes both commands to leverage hierarchical agent architecture principles through research-coordinator integration, hard barrier pattern enforcement, and wave-based parallel orchestration.

**Key Optimizations**:
1. **Research-Coordinator Integration** (/lean-plan): Replace single lean-research-specialist invocation with research-coordinator supervisor enabling parallel multi-topic research (e.g., "Mathlib Theorems", "Proof Strategies", "Project Structure") with 95% context reduction via metadata-only passing
2. **Hard Barrier Enforcement** (/lean-implement): Add fail-fast validation preventing orchestrator from bypassing coordinator delegation, ensuring implementation work stays in coordinator layer
3. **Wave-Based Orchestration** (/lean-implement): Ensure implementer-coordinator invocation with dependency analysis and parallel phase execution (40-60% time savings)
4. **Brief Summary Parsing**: Replace full file reads with metadata-only return signals (96% context reduction: 80 tokens vs 2,000 tokens)

**Expected Benefits**:
- 40-60% time reduction for multi-topic Lean research via parallel execution
- 95% context reduction in planning phase (330 tokens vs 7,500 tokens for 3 reports)
- 96% context reduction in implementation iteration (80 tokens vs 2,000 tokens per summary)
- Elimination of orchestrator implementation bypass (hard barrier pattern enforcement)
- Enabled multi-iteration workflows (10+ iterations possible with reduced context)

## Research Summary

### Report 1: /lean-plan Command Analysis (8 findings, 5 recommendations)

**Key Findings**:
- **Finding 1**: Direct lean-research-specialist invocation without research-coordinator intermediary (single research invocation limits parallelization, increases orchestrator context consumption)
- **Finding 2**: Hardcoded single REPORT_PATH prevents parallel multi-topic research decomposition
- **Finding 3**: Orchestrator loads full research report content (766 lines ≈ 2,500 tokens) when only metadata summary needed (≈110 tokens) - missed 95% context reduction
- **Finding 4**: No topic decomposition phase to identify distinct research areas from FEATURE_DESCRIPTION
- **Finding 5**: Planning phase receives full research context rather than metadata summaries (plan-architect must Read full reports)

**Implemented Recommendations**:
- Recommendation 1: Integrate research-coordinator for parallel multi-topic research (HIGH priority) - **Phase 1**
- Recommendation 2: Implement metadata-only context passing (HIGH priority) - **Phase 1**
- Recommendation 3: Add topic decomposition with topic-detection-agent (MEDIUM priority) - **Phase 2**
- Recommendation 5: Add partial success mode to hard barrier validation (MEDIUM priority) - **Phase 2**

### Report 2: /lean-implement Command Analysis (10 findings, 8 recommendations)

**Key Findings**:
- **Finding 1 (CRITICAL)**: Primary agent performing direct implementation work instead of delegating to coordinators (reads 406-line plan, 529-line Tactics.lean, 670-line TacticsTest.lean, updates files directly)
- **Finding 2**: Hard barrier pattern defined in design but not enforced at runtime (primary agent bypassed coordinator delegation entirely)
- **Finding 4**: implementer-coordinator exists but isn't being invoked correctly (gap between routing decision and actual delegation)
- **Finding 5**: Context window consumption from sequential file operations (2,443 lines read ≈ 6,000-8,000 tokens, 30-40% of 200k window)
- **Finding 8**: Brief summary pattern defined but unrealized (0% vs promised 96% context reduction)

**Implemented Recommendations**:
- Recommendation 2: Enforce hard barrier pattern in Block 1b with fail-fast validation (CRITICAL priority) - **Phase 3**
- Recommendation 3: Integrate wave-based orchestration via implementer-coordinator (HIGH priority) - **Phase 3**
- Recommendation 5: Implement brief summary parsing from coordinator return signals (MEDIUM priority) - **Phase 4**
- Recommendation 7: Pre-calculate all artifact paths in Block 1a (MEDIUM priority) - **Phase 3**

## Success Criteria

- [x] /lean-plan integrates research-coordinator with parallel multi-topic research capability
- [x] /lean-plan implements metadata-only context passing (95% context reduction verified)
- [x] /lean-plan supports topic decomposition for complexity-based research count (2-4 topics)
- [x] /lean-implement enforces hard barrier pattern with fail-fast validation (delegation bypass prevented)
- [x] /lean-implement invokes implementer-coordinator with wave-based orchestration
- [x] /lean-implement parses brief summaries from coordinator return signals (96% context reduction verified)
- [x] Both commands demonstrate context reduction in actual execution (validation via output logs)
- [x] All changes maintain backward compatibility with existing plans and workflows
- [x] Pre-commit validation passes for all modified command files
- [x] Integration tests verify coordinator delegation and metadata passing

## Technical Design

### Architecture Overview

```
/lean-plan Command Flow (Optimized):
┌─────────────────────────────────────────────────────────────────┐
│ Block 1a-1c: Setup + Topic Name Generation                      │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1d: Research Topics Classification (NEW)                  │
│ - Complexity-based topic count: C1-2→2, C3→3, C4→4 topics      │
│ - Lean-specific topics: Mathlib, Proofs, Structure, Style      │
│ - Persist TOPICS array and REPORT_PATHS array                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1e-exec: Research Coordinator Invocation (MODIFIED)       │
│ - Replace lean-research-specialist with research-coordinator    │
│ - Pass TOPICS and REPORT_PATHS arrays                          │
│ - Coordinator returns metadata-only (95% context reduction)    │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1f: Hard Barrier Validation (ENHANCED)                    │
│ - Loop through REPORT_PATHS validating each                     │
│ - Partial success mode: ≥50% threshold                         │
│ - Extract metadata from coordinator return signal               │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 2: Planning Phase (OPTIMIZED)                             │
│ - lean-plan-architect receives metadata-only                    │
│ - Format: {title, findings_count, recommendations_count}        │
│ - Architect uses Read tool for full reports (delegated read)   │
└─────────────────────────────────────────────────────────────────┘

/lean-implement Command Flow (Optimized):
┌─────────────────────────────────────────────────────────────────┐
│ Block 1a: Setup + Artifact Path Pre-calculation (ENHANCED)      │
│ - Pre-calculate: SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR         │
│ - Create directories (lazy creation pattern)                    │
│ - Persist paths for coordinator input contract                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1b: Route to Coordinator [HARD BARRIER] (ENFORCED)        │
│ - MANDATORY coordinator delegation (no conditionals)            │
│ - Persist COORDINATOR_NAME for Block 1c validation             │
│ - Task invocation with complete artifact paths                 │
│ - Coordinator performs wave analysis + implementation           │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1c: Hard Barrier Validation (FAIL-FAST)                   │
│ - Verify summary file exists (delegation bypass detection)      │
│ - Parse brief summary from return signal (NOT file read)       │
│ - Extract: summary_brief, phases_completed, context_usage      │
│ - Display metadata-only (96% context reduction)                │
└────────────────┬────────────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────────────┐
│ Block 1d: Phase Marker Recovery (REMOVED)                       │
│ - DELETE entire block (coordinator handles markers)             │
│ - Trust coordinators for marker updates                        │
└─────────────────────────────────────────────────────────────────┘

Coordinator Delegation Pattern:
research-coordinator (Block 1e-exec in /lean-plan):
  ├─> research-specialist #1 (Mathlib Theorems)     │ Parallel
  ├─> research-specialist #2 (Proof Strategies)     │ Wave
  └─> research-specialist #3 (Project Structure)    │ Execution
  Returns: aggregated_metadata (110 tokens each × 3 = 330 tokens)

implementer-coordinator (Block 1b in /lean-implement):
  ├─> dependency-analyzer.sh (extract wave structure)
  ├─> Wave 1: Phases [1, 3, 5] (parallel execution)    │ Wave-Based
  ├─> Wave 2: Phases [2, 4] (parallel execution)       │ Orchestration
  └─> Wave 3: Phase [6] (sequential)                   │
  Returns: brief_summary (80 tokens vs 2,000 full content)
```

### Key Design Decisions

1. **Research-Coordinator Integration** (/lean-plan):
   - Use research-coordinator.md supervisor pattern (Example 7 in hierarchical-agents-examples.md)
   - Complexity-based topic count: Complexity 1-2 → 2 topics, 3 → 3 topics, 4 → 4 topics
   - Lean-specific topic names: "Mathlib Theorems", "Proof Strategies", "Project Structure", "Style Guide"
   - Pass pre-calculated REPORT_PATHS array to coordinator (hard barrier pattern)

2. **Metadata-Only Context Passing**:
   - Extract metadata from coordinator return signal (lines like `reports: [{"path": "...", "title": "...", "findings_count": 12}]`)
   - Format metadata for plan-architect prompt (110 tokens per report vs 2,500 tokens full content)
   - Plan-architect uses Read tool to access full reports (delegated read, not orchestrator read)

3. **Hard Barrier Enforcement** (/lean-implement):
   - Persist COORDINATOR_NAME before Task invocation
   - Validate summary file exists in Block 1c (fail-fast if missing = delegation bypass)
   - Error message includes coordinator name for diagnostics

4. **Brief Summary Parsing**:
   - Parse return signal fields (summary_brief, phases_completed, context_usage_percent)
   - Display brief summary to user (80 tokens vs 2,000 full content)
   - Full summary file path for reference only (user can read if needed)

5. **Standards Compliance**:
   - Three-tier sourcing pattern for all bash blocks (state-persistence.sh, error-handling.sh, workflow-state-machine.sh)
   - Task invocation uses imperative directive: "**EXECUTE NOW**: USE the Task tool..."
   - Path validation uses validate_path_consistency() from validation-utils.sh
   - Error logging integration via log_command_error() for all validation failures
   - Output formatting: suppress library sourcing with 2>/dev/null, consolidate to 2-3 bash blocks per command

## Implementation Phases

### Phase 1: /lean-plan Research-Coordinator Integration [COMPLETE]
dependencies: []

**Objective**: Replace direct lean-research-specialist invocation with research-coordinator supervisor enabling parallel multi-topic research and metadata-only context passing.

**Complexity**: Medium

**Tasks**:
- [x] Add Block 1d: Research Topics Classification after Block 1c topic name validation (file: /home/benjamin/.config/.claude/commands/lean-plan.md)
  - Complexity-based topic count: C1-2 → 2 topics, C3 → 3 topics, C4 → 4 topics
  - Lean-specific topics array: ["Mathlib Theorems", "Proof Strategies", "Project Structure", "Style Guide"]
  - Persist TOPICS array and calculate REPORT_PATHS array (${RESEARCH_DIR}/001-mathlib-theorems.md, etc.)
  - Use append_workflow_state_bulk for batch persistence
- [x] Modify Block 1d-calc to work with REPORT_PATHS array instead of single REPORT_PATH
  - Loop through TOPICS array to build REPORT_PATHS array
  - Validate each path is absolute (starts with /)
  - Create parent directories for all report paths
- [x] Replace Block 1e-exec lean-research-specialist invocation with research-coordinator Task invocation
  - Read behavioral guidelines from ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md
  - Input contract: research_request, research_complexity, report_dir, topics, report_paths, context (lean_project_path)
  - Model: sonnet (coordinator tier, delegates to research-specialist workers)
- [x] Update Block 1f validation to loop through REPORT_PATHS array
  - Check each report exists and meets minimum size (500 bytes)
  - Implement partial success mode: ≥50% success threshold (based on research-coordinator.md lines 504-510)
  - Log validation errors via log_command_error for each failed report
- [x] Add Block 1f-metadata: Extract Report Metadata after Block 1f validation
  - Parse research-coordinator return signal for metadata (RESEARCH_COMPLETE: N, reports: [{...}])
  - Extract JSON metadata using grep/sed pattern matching
  - Format metadata for planning phase: title, findings_count, recommendations_count per report
  - Persist REPORT_METADATA_JSON to workflow state
- [x] Update Block 2 lean-plan-architect invocation to use metadata-only context
  - Pass REPORT_COUNT and formatted metadata (not full report content)
  - Include CRITICAL instruction: agent has Read tool access, full content NOT in prompt
  - Remove orchestrator Read of full report content (current line 75-76 in lean-plan-output.md)

**Testing**:
```bash
# Test with complexity 3 (3 topics expected)
/lean-plan "Implement group homomorphism theorems with Mathlib integration" --complexity 3

# Verify 3 research reports created
ls -la .claude/specs/*/reports/*.md | wc -l  # Should be 3

# Verify metadata-only passing (check output for Read tool usage)
# Expected: No "Read(reports/001-*.md)" in orchestrator output
# Expected: RESEARCH_COMPLETE: 3 in output with metadata JSON

# Verify planning phase receives metadata
# Expected: "Research Reports: 3 reports created" in plan-architect prompt
```

**Expected Duration**: 5-7 hours

### Phase 2: /lean-plan Topic Decomposition and Partial Success [COMPLETE]
dependencies: [1]

**Objective**: Add automated topic detection via topic-detection-agent and enhance hard barrier validation with graceful degradation for partial research success.

**Complexity**: Medium

**Tasks**:
- [x] Create topic-detection-agent behavioral file (file: /home/benjamin/.config/.claude/agents/topic-detection-agent.md)
  - Input contract: FEATURE_DESCRIPTION, RESEARCH_COMPLEXITY
  - Output format: TOPICS array with slug identifiers (2-5 topics based on complexity)
  - Validation: 2-5 topics, each 5-40 characters, unique slugs
  - Model: haiku (fast classification task)
  - Error handling: Return TASK_ERROR if decomposition fails
- [x] Add Block 1c-topics: Topic Detection between Block 1c validation and Block 1d classification
  - Task invocation: topic-detection-agent with FEATURE_DESCRIPTION and RESEARCH_COMPLEXITY
  - Parse return signal for TOPICS array
  - Validate topic count matches complexity (C1-2 → 2, C3 → 3, C4 → 4)
  - Fallback to default Lean topics if agent fails (graceful degradation)
  - Persist TOPICS array to workflow state for Block 1d
- [x] Enhance Block 1f validation with partial success mode
  - Count successful reports (loop through REPORT_PATHS, check existence + size ≥500 bytes)
  - Calculate success percentage: SUCCESSFUL_REPORTS / TOTAL_REPORTS × 100
  - Fail if <50% success (exit 1 with ERROR log)
  - Warn if 50-99% success (continue with WARNING log)
  - Log partial success details: "Proceeding with N/M reports (X% success rate)"
- [x] Update planning phase to handle variable report counts
  - Adjust metadata format to include success_rate field if <100%
  - Plan-architect prompt notes partial research results (if applicable)
  - Include warning in console output if partial success

**Testing**:
```bash
# Test topic decomposition
/lean-plan "Implement advanced proof automation tactics" --complexity 4

# Verify topic-detection-agent invocation
# Expected: "Invoking topic-detection-agent..." in output
# Expected: TOPICS array with 4 unique topics

# Test partial success mode (simulate 1 report failure)
# Manually delete one report mid-execution (Block 1e → Block 1f gap)
# Expected: WARNING message, continues to planning phase
# Expected: "Partial research success (66.7%)" in output

# Test <50% failure
# Simulate 2/3 reports missing
# Expected: ERROR message, workflow fails, no planning phase
```

**Expected Duration**: 4-5 hours

### Phase 3: /lean-implement Hard Barrier Enforcement and Coordinator Integration [COMPLETE]
dependencies: []

**Objective**: Enforce hard barrier pattern to prevent orchestrator delegation bypass, ensure implementer-coordinator invocation with wave-based orchestration, and pre-calculate all artifact paths.

**Complexity**: High

**Tasks**:
- [x] Enhance Block 1a: Pre-calculate All Artifact Paths (file: /home/benjamin/.config/.claude/commands/lean-implement.md)
  - Calculate SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINTS_DIR paths
  - Use mkdir -p for lazy directory creation
  - Persist all paths to workflow state for Block 1b coordinator input contract
  - Add path validation (all must be absolute, start with /)
- [x] Enforce Block 1b: Route to Coordinator [HARD BARRIER]
  - Remove ALL conditionals from coordinator delegation (no if statements)
  - Make Task invocation MANDATORY (delegation is not optional)
  - Persist COORDINATOR_NAME before Task invocation (for Block 1c validation)
  - Input contract: plan_path, topic_path, artifact_paths (summaries, debug, outputs, checkpoints)
  - Add comment: "HARD BARRIER: Orchestrator MUST NOT perform implementation work"
- [x] Add Block 1c fail-fast validation for delegation bypass
  - Check LATEST_SUMMARY file exists (if missing → coordinator was bypassed)
  - Error message includes coordinator name: "Coordinator $COORDINATOR_NAME did not create summary (delegation bypass detected)"
  - Log error via log_command_error with error_type="agent_error"
  - Exit 1 immediately (no recovery, fail-fast pattern)
- [x] Update implementer-coordinator input contract to include all artifact paths
  - Verify implementer-coordinator.md accepts artifact_paths structure
  - Add summaries_dir, debug_dir, outputs_dir, checkpoints_dir to input contract
  - Coordinator validates all paths exist (hard barrier validation on coordinator side)
- [x] Ensure implementer-coordinator invokes dependency-analyzer.sh for wave structure
  - Verify implementer-coordinator.md STEP 2 performs dependency analysis
  - Confirm wave-based execution pattern (lines 248-436 in implementer-coordinator.md)
  - Validate parallel phase execution for independent phases
- [x] Delete Block 1d: Phase Marker Recovery entirely
  - Remove all phase marker validation/recovery logic from orchestrator
  - Trust coordinators to update phase markers correctly
  - Add comment: "Phase marker management delegated to coordinators"

**Testing**:
```bash
# Test hard barrier enforcement
/lean-implement specs/044_proof_strategy/plans/001-proof-strategy-plan.md

# Verify coordinator delegation
# Expected: "Invoking implementer-coordinator..." in output
# Expected: No "Read(.lean)" in orchestrator output (delegation verified)

# Test delegation bypass detection (simulate bypass)
# Manually edit Block 1b to skip Task invocation
# Expected: ERROR in Block 1c: "Coordinator implementer-coordinator did not create summary"
# Expected: Workflow exits immediately (fail-fast)

# Test wave-based orchestration
# Use plan with dependency structure: Phase 1 [], Phase 2 [1], Phase 3 [1]
# Expected: Phases 2 and 3 run in separate waves (dependency graph respected)

# Verify artifact paths pre-calculation
# Check workflow state contains SUMMARIES_DIR, DEBUG_DIR, etc.
cat "${WORKFLOW_STATE_FILE}" | grep -E "(SUMMARIES_DIR|DEBUG_DIR|OUTPUTS_DIR)"
```

**Expected Duration**: 6-8 hours

### Phase 4: /lean-implement Brief Summary Parsing and Context Optimization [COMPLETE]
dependencies: [3]

**Objective**: Implement brief summary parsing from coordinator return signals to achieve 96% context reduction, eliminating full file reads in orchestrator.

**Complexity**: Medium

**Tasks**:
- [x] Update Block 1c to parse return signal fields instead of reading summary file (file: /home/benjamin/.config/.claude/commands/lean-implement.md)
  - Parse summary_brief field: grep "^summary_brief:" from coordinator output, extract value
  - Parse phases_completed field: grep "^phases_completed:", extract array, convert to space-separated list
  - Parse context_usage_percent field: grep "^context_usage_percent:", extract numeric value
  - Remove all Read tool invocations for summary files in orchestrator
- [x] Display brief summary metadata to user (console output optimization)
  - Format: "Summary: $SUMMARY_BRIEF"
  - Format: "Phases completed: $PHASES_COMPLETED"
  - Format: "Context usage: ${CONTEXT_USAGE}%"
  - Include full summary path for reference: "Full report: $LATEST_SUMMARY"
  - User can read full summary if needed (not loaded into orchestrator context)
- [x] Update iteration management logic to use coordinator signals
  - Replace orchestrator iteration logic with coordinator signals: requires_continuation, work_remaining
  - Block 1c checks: if REQUIRES_CONTINUATION=true AND WORK_REMAINING is non-empty → continue
  - Simplified iteration decision (trust coordinator's context-aware continuation decision)
  - Loop back to Block 1b with updated ITERATION state
- [x] Verify implementer-coordinator output format includes all required fields
  - Check implementer-coordinator.md output contract (line 613) includes summary_brief
  - Verify context_usage_percent field present in return signal
  - Confirm phases_completed array format (e.g., [1, 2, 3] or "1 2 3")
- [x] Remove full summary file reads from orchestrator context
  - Audit all Read tool invocations in lean-implement.md
  - Confirm NO Read(summaries/*.md) in orchestrator blocks
  - All summary content access delegated to coordinator layer

**Testing**:
```bash
# Test brief summary parsing
/lean-implement specs/044_proof_strategy/plans/001-proof-strategy-plan.md

# Verify no full file reads in orchestrator
# Expected: No "Read(summaries/001-*.md)" in output
# Expected: "Summary: Brief one-line description" in console

# Verify metadata fields parsed correctly
# Expected: "Phases completed: 1 2 3" (space-separated list)
# Expected: "Context usage: 42%" (numeric percentage)

# Test context reduction (compare old vs new)
# Old behavior: Read 738-line summary (≈2,000 tokens)
# New behavior: Parse 80-token return signal
# Reduction: 96% (2,000 → 80 tokens)

# Test iteration continuation
# Use plan with multiple phases requiring continuation
# Expected: "Continuing to iteration 2 (work remaining: Phase 3, Phase 4)"
# Expected: Loop back to Block 1b without full summary read
```

**Expected Duration**: 3-4 hours

### Phase 5: Integration Testing and Validation [COMPLETE]
dependencies: [2, 4]

**Objective**: Verify end-to-end coordinator integration, context reduction metrics, and backward compatibility with existing plans and workflows.

**Complexity**: Medium

**Tasks**:
- [x] Create integration test suite for /lean-plan coordinator integration (file: /home/benjamin/.config/.claude/tests/integration/test_lean_plan_coordinator.sh)
  - Test research-coordinator invocation with complexity 2, 3, 4 (verify correct topic count)
  - Test metadata-only context passing (verify no full report reads in orchestrator)
  - Test partial success mode (simulate 1/3 report failure, verify WARNING + continuation)
  - Test topic decomposition with topic-detection-agent (verify TOPICS array parsing)
  - Validate all tests use three-tier sourcing pattern and error logging
- [x] Create integration test suite for /lean-implement hard barrier enforcement (file: /home/benjamin/.config/.claude/tests/integration/test_lean_implement_coordinator.sh)
  - Test implementer-coordinator delegation (verify no direct implementation in orchestrator)
  - Test hard barrier validation (simulate delegation bypass, verify fail-fast)
  - Test wave-based orchestration (use plan with dependencies, verify parallel execution)
  - Test brief summary parsing (verify no full summary reads in orchestrator)
  - Test iteration continuation with coordinator signals
- [x] Verify context reduction metrics via actual execution logs
  - Run /lean-plan with complexity 3, measure token usage (orchestrator context)
  - Expected: 330 tokens metadata vs 7,500 tokens full reports (95% reduction)
  - Run /lean-implement with multi-phase plan, measure summary parsing
  - Expected: 80 tokens brief summary vs 2,000 tokens full summary (96% reduction)
  - Document metrics in validation report
- [x] Test backward compatibility with existing plans
  - Run /lean-implement on plans without phase-level metadata (verify routing works)
  - Run /lean-implement on plans with [COMPLETE] phases (verify preservation)
  - Run /lean-plan with existing topic directories (verify numbering works)
  - Ensure no breaking changes to plan structure parsing
- [x] Validate pre-commit standards compliance
  - Run bash .claude/scripts/validate-all-standards.sh --sourcing on modified commands
  - Verify three-tier sourcing pattern in all bash blocks
  - Run bash .claude/scripts/validate-all-standards.sh --links on modified commands
  - Fix any broken internal links in documentation

**Testing**:
```bash
# Run integration test suites
bash .claude/tests/integration/test_lean_plan_coordinator.sh
# Expected: All tests pass (exit 0)

bash .claude/tests/integration/test_lean_implement_coordinator.sh
# Expected: All tests pass (exit 0)

# Verify context reduction metrics
# Manual execution with token counting:
/lean-plan "Implement decidability proofs for custom types" --complexity 3
# Count tokens in orchestrator context (via model output or logging)
# Verify: <500 tokens total (vs >8,000 previously)

# Test backward compatibility
/lean-implement .claude/specs/028_lean_subagent/plans/001-*.md
# Expected: Works with existing plan structure (no breaking changes)

# Validate standards compliance
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --links
# Expected: Exit 0 (all validations pass)
```

**Expected Duration**: 4-5 hours

### Phase 6: Documentation and Completion [COMPLETE]
dependencies: [5]

**Objective**: Update command guides, reference documentation, and architectural docs to reflect coordinator integration changes and context optimization patterns.

**Complexity**: Low

**Tasks**:
- [x] Update /lean-plan command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/lean-plan-command-guide.md)
  - Document research-coordinator integration pattern
  - Add section on metadata-only context passing (95% reduction)
  - Document topic decomposition and complexity-based topic count
  - Add troubleshooting section for partial success mode
  - Include example execution with 3-topic research
- [x] Update /lean-implement command guide (file: /home/benjamin/.config/.claude/docs/guides/commands/lean-implement-command-guide.md)
  - Document hard barrier pattern enforcement and fail-fast validation
  - Add section on wave-based orchestration via implementer-coordinator
  - Document brief summary parsing (96% reduction)
  - Update iteration management section (coordinator signals)
  - Add troubleshooting section for delegation bypass detection
- [x] Update hierarchical agents examples documentation (file: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md)
  - Add Example 8: Lean Command Coordinator Integration
  - Show research-coordinator usage in /lean-plan with parallel research
  - Show implementer-coordinator usage in /lean-implement with wave execution
  - Document context reduction metrics (95% and 96%)
  - Include full execution flow diagrams
- [x] Update plan metadata standard if new fields introduced (file: /home/benjamin/.config/.claude/docs/reference/standards/plan-metadata-standard.md)
  - Verify no new required metadata fields (should be none)
  - Document any new optional fields for Lean-specific metadata
  - Update examples if phase-level metadata usage changes
- [x] Update CLAUDE.md hierarchical agent architecture section reference (file: /home/benjamin/.config/CLAUDE.md)
  - Add note about Lean command coordinator integration pattern
  - Link to updated hierarchical-agents-examples.md Example 8
  - Update performance metrics (40-60% time savings, 95-96% context reduction)

**Testing**:
```bash
# Verify documentation links
bash .claude/scripts/validate-all-standards.sh --links
# Expected: All internal links valid (exit 0)

# Verify README structure
bash .claude/scripts/validate-all-standards.sh --readme
# Expected: All READMEs meet standards (exit 0)

# Manual review of documentation
# Check command guides include new coordinator integration sections
# Check examples documentation includes Example 8 with execution flow
# Check CLAUDE.md references are updated
```

**Expected Duration**: 2-3 hours

## Testing Strategy

### Unit Testing
- Test topic-detection-agent decomposition logic (verify 2-5 topics based on complexity)
- Test metadata extraction from coordinator return signals (verify JSON parsing)
- Test partial success calculation (verify percentage thresholds)
- Test hard barrier validation (verify delegation bypass detection)

### Integration Testing
- Test /lean-plan end-to-end with research-coordinator (verify parallel research execution)
- Test /lean-implement end-to-end with implementer-coordinator (verify wave-based orchestration)
- Test metadata-only context passing (verify no full file reads in orchestrator)
- Test backward compatibility with existing plans (verify no breaking changes)

### Performance Testing
- Measure context reduction: orchestrator token usage before/after optimization
- Measure time reduction: parallel research execution vs sequential (expect 40-60% improvement)
- Measure iteration capacity: number of iterations possible with reduced context (expect 10+ vs 3-4)

### Regression Testing
- Verify existing /lean-plan executions still work (no functionality removed)
- Verify existing /lean-implement executions still work (coordinator delegation doesn't break)
- Verify plans with [COMPLETE] phases are preserved correctly

## Documentation Requirements

- Update /lean-plan command guide with research-coordinator integration pattern
- Update /lean-implement command guide with hard barrier enforcement and wave orchestration
- Update hierarchical-agents-examples.md with Example 8 (Lean Command Coordinator Integration)
- Update CLAUDE.md hierarchical agent architecture section with performance metrics
- Update plan metadata standard if new Lean-specific fields introduced
- Create troubleshooting guide for coordinator integration issues (delegation bypass, partial success, wave execution)

## Dependencies

### External Dependencies
- research-coordinator.md agent behavioral file (exists, lines 1-635)
- implementer-coordinator.md agent behavioral file (exists, lines 1-975)
- topic-detection-agent.md agent behavioral file (needs creation in Phase 2)
- dependency-analyzer.sh script (referenced in implementer-coordinator, verify existence)

### Internal Dependencies
- Phase 1 (research-coordinator integration) can run in parallel with Phase 3 (hard barrier enforcement) - different commands
- Phase 2 (topic decomposition) depends on Phase 1 (builds on research-coordinator integration)
- Phase 4 (brief summary parsing) depends on Phase 3 (requires coordinator delegation working)
- Phase 5 (integration testing) depends on Phases 2 and 4 (validates both commands fully optimized)
- Phase 6 (documentation) depends on Phase 5 (documents validated implementation)

### Standards Dependencies
- Three-tier sourcing pattern: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- Error logging integration: log_command_error for all validation failures
- Task invocation pattern: imperative directive "**EXECUTE NOW**: USE the Task tool..."
- Output formatting: suppress library sourcing with 2>/dev/null, consolidate bash blocks
- Path validation: use validate_path_consistency() from validation-utils.sh

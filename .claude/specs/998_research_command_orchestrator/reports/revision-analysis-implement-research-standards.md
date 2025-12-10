# Revision Analysis: /implement Command Patterns and .claude/docs/ Standards

**Date**: 2025-12-09
**Purpose**: Research /implement command patterns and .claude/docs/ standards to ensure 001-research-command-orchestrator-plan.md maintains consistency with proven implementations
**Related Plan**: `.claude/specs/998_research_command_orchestrator/plans/001-research-command-orchestrator-plan.md`

---

## Executive Summary

This analysis compares the proposed /research command orchestrator implementation plan against established patterns from /implement (the most mature command implementation) and .claude/docs/ documentation standards. The goal is to identify potential consistency issues, pattern violations, and architectural gaps before revision.

---

## Part 1: /implement Command Architecture Analysis

### 1.1 Command Structure

The /implement command (`.claude/commands/implement.md`) represents the most sophisticated command implementation in the project, featuring:

**Core Components**:
1. **Multi-Block Argument Capture** (Blocks 1-2): 2-block standardized pattern
2. **State Machine Initialization** (Block 3): sm_init with workflow type "implement"
3. **Iteration Loop Architecture** (Blocks 5-8): implementer-coordinator delegation with continuation signals
4. **Hard Barrier Verification** (Block 7a-7b): Summary validation and brief parsing

### 1.2 Key Patterns from /implement

**Pattern 1: Coordinator Delegation with Hard Barriers**
```markdown
## Block 5: Initial Coordinator Invocation [CRITICAL BARRIER]

**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator.

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation phases"
  prompt: "..."
}

## Block 6: Summary Validation (Hard Barrier)

```bash
LATEST_SUMMARY=$(find "$SUMMARIES_DIR" -name "*.md" -type f | sort | tail -1)
if [ -z "$LATEST_SUMMARY" ]; then
  log_command_error "agent_error" "Coordinator failed to create summary"
  exit 1
fi
```
```

**Pattern 2: Brief Summary Parsing (96% Context Reduction)**
```bash
# Parse return signal fields instead of reading full file
SUMMARY_BRIEF=$(grep "^summary_brief:" "$LATEST_SUMMARY" | sed 's/^summary_brief:[[:space:]]*//')
PHASES_COMPLETED=$(grep "^phases_completed:" "$LATEST_SUMMARY" | ...)
WORK_REMAINING=$(grep "^work_remaining:" "$LATEST_SUMMARY" | ...)
```

**Pattern 3: Iteration Continuation Logic**
```bash
if [ "$WORK_REMAINING" = "0" ]; then
  sm_transition "$STATE_COMPLETE"
else
  ITERATION=$((ITERATION + 1))
  # Re-invoke coordinator for next iteration
fi
```

### 1.3 Comparison with Proposed /research Orchestrator

**Alignment Points**:
- [x] Uses research-coordinator for multi-topic delegation (matches /implement's implementer-coordinator pattern)
- [x] Pre-calculates report paths before coordinator invocation (hard barrier pattern)
- [x] Metadata aggregation for context reduction (matches 95% reduction approach)

**Potential Gaps Identified**:
1. **Missing Brief Summary Parsing**: Plan does not specify parsing return signals from research-coordinator
2. **No Iteration Loop**: /research is single-pass, but should handle partial success continuation
3. **Missing Validation Block Naming**: Should use "Block 1f" naming convention

---

## Part 2: /research Command Compatibility Analysis

### 2.1 Current /research Command Structure

The /research command (`.claude/commands/research.md`) implements:

**Current Flow**:
1. Block 1: Argument capture
2. Block 2: Topic directory allocation
3. Block 3: State machine initialization
4. Block 4: research-specialist direct invocation (single topic)
5. Block 5: Verification and completion

**Integration Point for Orchestrator**:
The plan proposes inserting research-coordinator between Block 3 (state machine) and Block 5 (verification):
- Block 3 → Block 4a (Topic Decomposition) → Block 4b (Coordinator Invocation) → Block 4c (Multi-Report Validation) → Block 5 (Completion)

### 2.2 Compatibility Risks

**Risk 1: State Variable Collision**
- Current /research uses: `RESEARCH_DIR`, `REPORT_PATH` (singular)
- Proposed orchestrator uses: `RESEARCH_DIR`, `REPORT_PATHS` (array)
- **Mitigation**: Plan correctly uses `REPORT_PATHS` array but must ensure single-topic fallback uses `REPORT_PATH` for backward compatibility

**Risk 2: Workflow Type Mismatch**
- /research workflow type: "research-only"
- /implement workflow type: "implement"
- Proposed orchestrator terminal state: `plan` (from /create-plan integration)
- **Mitigation**: Ensure /research continues to use "research-only" workflow type

**Risk 3: Exit Code Propagation**
- Current /research: Exits 1 on failure, 0 on success
- Proposed orchestrator: Introduces partial success mode (≥50% threshold)
- **Mitigation**: Partial success should return exit 0 with warning, not exit 1

### 2.3 Breaking Change Prevention

The plan MUST NOT break /research by:
1. Preserving single-topic mode when complexity < 3
2. Maintaining backward-compatible variable names
3. Keeping existing verification block behavior for single reports
4. Not changing workflow type or terminal state

---

## Part 3: .claude/docs/ Standards Compliance

### 3.1 Documentation Standards

**Source**: `.claude/docs/reference/standards/documentation-standards.md`

**Required README Structure** (for active directories):
- Purpose
- Module Documentation
- Usage Examples
- Navigation Links

**Plan Compliance Check**:
- [x] Plan includes proper metadata header (Date, Feature, Status, etc.)
- [x] Plan follows phase structure with dependencies
- [ ] Plan should reference `.claude/docs/reference/standards/command-authoring.md` for patterns

### 3.2 Command Authoring Standards

**Source**: `.claude/docs/reference/standards/command-authoring.md`

**Mandatory Patterns**:
1. **Execution Directive Requirements**: All bash blocks need `**EXECUTE NOW**:` prefix
2. **Task Tool Invocation Patterns**: No code block wrappers, inline prompts, completion signals
3. **Subprocess Isolation**: `set +H`, library re-sourcing, return code verification
4. **State Persistence**: `append_workflow_state`, `load_workflow_state`

**Plan Compliance Check**:
- [x] Plan specifies Task invocation pattern (Block 4b)
- [x] Plan includes hard barrier verification (Block 4c)
- [ ] Plan should explicitly require `set +H` in all bash blocks
- [ ] Plan should specify three-tier library sourcing

### 3.3 Research Coordinator Delegation Pattern

**Source**: `.claude/docs/reference/standards/command-authoring.md` Section 10.2

**Required Integration Points**:
1. **Topic Decomposition** → saves TOPICS_LIST and REPORT_PATHS_LIST to state
2. **Coordinator Invocation** → passes topics and paths as contract
3. **Multi-Report Validation** → validates all reports with fail-fast policy
4. **Metadata Extraction** → aggregates findings count, recommendations for passing to next agent

**Plan Compliance Check**:
- [x] Topic decomposition included (Phase 1.1)
- [x] Coordinator invocation specified (Phase 1.2)
- [x] Multi-report validation included (Phase 1.3)
- [ ] Metadata extraction not explicitly specified (should add Phase 1.4)

### 3.4 Non-Interactive Testing Standard

**Source**: `.claude/docs/reference/standards/non-interactive-testing-standard.md`

**Required Test Phase Elements**:
- `automation_type: automated`
- `validation_method: programmatic`
- `skip_allowed: false`
- `artifact_outputs: [list]`

**Plan Test Phase Compliance**:
- [ ] Test phases in plan do not include automation metadata
- [ ] Should add explicit automation requirements to Phase 4

---

## Part 4: Hierarchical Agent Architecture Alignment

### 4.1 Research Coordinator Pattern (Example 7)

**Source**: `.claude/docs/concepts/hierarchical-agents-examples.md` Example 7

**Required Components**:
1. Pre-calculate report paths before coordinator invocation
2. Pass TOPICS and REPORT_PATHS arrays as input contract
3. research-coordinator invokes parallel research-specialist workers
4. Multi-layer validation: invocation plan → trace file → reports
5. Metadata extraction returns 110 tokens per report

**Plan Alignment**:
- [x] Report path pre-calculation included
- [x] Input contract specified
- [ ] Multi-layer validation not specified (should require invocation plan file)
- [ ] Metadata extraction output format not specified

### 4.2 Implementer Coordinator Pattern (Example 8)

**Source**: `.claude/docs/concepts/hierarchical-agents-examples.md` Example 8

**Applicable Patterns for /research**:
1. **Partial Success Mode**: ≥50% threshold (fails if <50%, warns if 50-99%)
2. **Brief Summary Parsing**: Parse return signal fields, not full file
3. **Context Reduction Metrics**: 95-96% reduction targets

**Plan Gaps**:
- [ ] Partial success threshold not specified
- [ ] Return signal parsing not specified
- [ ] Context reduction targets not specified

---

## Part 5: Recommendations for Plan Revision

### 5.1 Critical Additions

1. **Add Block 4d: Metadata Extraction**
   - Extract findings count, recommendations count from each report
   - Format as FORMATTED_METADATA for downstream consumers
   - Specify 110 tokens per report target

2. **Add Partial Success Mode to Block 4c**
   - ≥50% threshold (fail if <50%, warn if 50-99%)
   - Propagate WARNING via exit 0, not error

3. **Add Return Signal Parsing**
   - Specify expected coordinator return format:
     ```
     RESEARCH_COMPLETE: {REPORT_COUNT}
     reports: [JSON array]
     total_findings: {N}
     total_recommendations: {N}
     ```

### 5.2 Standards Compliance Updates

4. **Add Three-Tier Library Sourcing Requirements**
   - Each bash block must source: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
   - Include fail-fast handlers for each tier

5. **Add Non-Interactive Testing Metadata**
   - Phase 4 should include automation_type, validation_method, skip_allowed, artifact_outputs

6. **Add Multi-Layer Validation**
   - Require invocation plan file creation before Task invocation
   - Require trace file validation after Task completion
   - Require report file validation (hard barrier)

### 5.3 Backward Compatibility Protections

7. **Add Single-Topic Fallback**
   - When complexity < 3, bypass coordinator and invoke research-specialist directly
   - Preserves current /research behavior for simple cases

8. **Preserve Workflow Type**
   - /research must continue using "research-only" workflow type
   - Orchestrator integration should not change terminal state

### 5.4 Documentation Cross-References

9. **Add Standards Reference Links**
   - Link to command-authoring.md for Task invocation patterns
   - Link to hierarchical-agents-examples.md for coordinator patterns
   - Link to testing-protocols.md for non-interactive requirements

---

## Part 6: Summary of Findings

| Aspect | Current Plan Status | Required Action |
|--------|---------------------|-----------------|
| Coordinator delegation | Correct | None |
| Hard barrier verification | Correct | None |
| Metadata extraction | Missing | Add Block 4d |
| Partial success mode | Missing | Add to Block 4c |
| Return signal parsing | Missing | Add specification |
| Three-tier sourcing | Implicit | Make explicit |
| Non-interactive testing | Missing | Add to Phase 4 |
| Single-topic fallback | Missing | Add compatibility path |
| Standards references | Missing | Add cross-references |

**Overall Assessment**: The plan is architecturally sound but needs completion of several standard patterns documented in .claude/docs/. The /implement command provides a proven template for coordinator delegation that should be mirrored more closely.

---

## References

- `.claude/commands/implement.md` - Reference implementation for coordinator delegation
- `.claude/commands/research.md` - Current /research implementation
- `.claude/docs/reference/standards/command-authoring.md` - Command patterns and standards
- `.claude/docs/concepts/hierarchical-agents-examples.md` - Example 7 (research-coordinator), Example 8 (implementer-coordinator)
- `.claude/docs/reference/standards/non-interactive-testing-standard.md` - Testing automation requirements

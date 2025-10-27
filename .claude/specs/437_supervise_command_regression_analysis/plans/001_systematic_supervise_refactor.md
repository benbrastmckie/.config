# Systematic /supervise Refactor - Implementation Plan

## Metadata
- **Date**: 2025-10-23
- **Feature**: Refactor /supervise command to restore correct agent delegation functionality
- **Scope**: Fix agent invocation patterns, extract templates, add context optimization, update documentation standards
- **Estimated Phases**: 6
- **Research Report**: [Supervise Regression Analysis](../reports/001_research/OVERVIEW.md)
- **Estimated Duration**: 2-3 weeks
- **Complexity**: 8/10 (High - affects core workflow command, requires standards updates)

## Overview

This plan systematically refactors the `/supervise` command to fix the critical architectural failure where all Task tool invocations exist only as YAML documentation examples within code blocks, not as executable instructions. The refactor will restore 100% agent delegation functionality, reduce file bloat by 37%, implement missing context optimization features, and update documentation standards to prevent future regressions.

**Critical Discovery**: The `/supervise` command has NOT lost delegation through code removal. Instead, it suffers from a pattern failure where agent invocation templates were implemented as documentation examples (````yaml Task { }```) rather than executable instructions preceded by imperative commands ("USE the Task tool NOW").

## Success Criteria

### Critical Success Factors (Must Achieve)
- [ ] 100% agent delegation rate (9/9 Task invocations executable)
- [ ] 0 YAML documentation blocks containing Task patterns
- [ ] 100% file creation rate with mandatory verification
- [ ] Command file reduced from 2,521 → ≤1,600 lines (37% reduction)
- [ ] All tests passing with regression test added

### Standards Compliance (Must Achieve)
- [ ] Context usage <30% throughout full 6-phase workflow
- [ ] Metadata extraction after all artifact verifications (95% context reduction per artifact)
- [ ] Context pruning after each phase completion
- [ ] Forward message pattern for phase transitions (90% context reduction vs full paths)
- [ ] Standards documentation updated with anti-patterns and enforcement

### Quality Metrics (Should Achieve)
- [ ] Regression test prevents future documentation-only patterns
- [ ] All 8 agent templates extracted to external files
- [ ] Error handling uses retry_with_backoff() for transient failures
- [ ] Phase 0 optimization note clarifies scope of changes

## Technical Design

### Architecture Analysis

**Current State**:
- 2,521 lines total (934 lines of inline templates = 37% bloat)
- 10 Task patterns found, 0 executable, 10 documentation examples
- All agent invocations wrapped in ```yaml code blocks
- No metadata extraction (missing 95% context reduction)
- No context pruning (missing <30% context usage target)
- 60% forward message pattern compliance (missing structured handoffs)

**Target State**:
- ≤1,600 lines (templates extracted)
- 9 executable Task invocations with imperative instructions
- 8 external template files in `.claude/templates/supervise/`
- Metadata extraction after Phase 1, 2, 3 verifications
- Context pruning after Phases 1-4
- 100% forward message pattern (structured phase handoffs)

### Design Decisions

1. **Pattern Transformation**: Convert all YAML documentation blocks to imperative Task invocations following `/orchestrate` pattern
2. **Template Extraction**: Move all 8 agent templates to external files with references
3. **Context Optimization**: Integrate metadata-extraction.sh and context-pruning.sh utilities
4. **Standards Updates**: Document anti-patterns in behavioral-injection.md and command-architecture-standards.md

### Component Interactions

```
/supervise command
├── Phase 0: Location (utility-based, optimized)
├── Phase 1: Research
│   ├── Invoke: 2-4 research-specialist agents (NOW EXECUTABLE)
│   ├── Verify: File creation checkpoints
│   └── Extract: Metadata (95% reduction) → Store for Phase 2
├── Phase 2: Planning
│   ├── Invoke: plan-architect agent with research metadata
│   ├── Verify: Plan file checkpoint
│   └── Extract: Phase count, complexity
├── Phase 3-6: Implementation, Testing, Debug, Documentation
│   ├── Each phase: Imperative invocations
│   ├── Each checkpoint: Verification → Metadata extraction
│   └── Each transition: Context pruning → Forward message
└── Completion: Aggregate metadata, report artifacts
```

## Implementation Phases

### Phase 0: Repository Audit and Baseline
**Objective**: Establish baseline metrics and validation infrastructure
**Duration**: 2 days
**Complexity**: 2/10

**Tasks**:
1. [ ] Run audit on current supervise.md state
   - Count YAML blocks: `grep -c '```yaml.*Task {' .claude/commands/supervise.md`
   - Count imperative invocations: `grep -c 'USE the Task tool\|EXECUTE NOW.*Task' .claude/commands/supervise.md`
   - Measure file size: `wc -l .claude/commands/supervise.md`
   - Document baseline: 2,521 lines, 0 executable, 10 YAML blocks
2. [ ] Create regression test: `.claude/tests/test_supervise_delegation.sh`
   - Validate ≥9 imperative Task invocations
   - Validate 0 YAML documentation blocks with Task
   - Exit 0 on pass, exit 1 on failure
   - Test script provided in research report (lines 384-408)
3. [ ] Integrate test into test suite
   - Add to `.claude/tests/run_all_tests.sh`
   - Verify test fails on current implementation (baseline)
   - Document expected failure: "Found 10 YAML blocks (expected 0)"
4. [ ] Create backup of supervise.md
   - Copy to: `.claude/specs/437_supervise_command_regression_analysis/supervise.md.baseline`
   - Commit baseline for comparison

**Testing**:
```bash
# Verify test infrastructure
bash .claude/tests/test_supervise_delegation.sh
# Expected: FAIL (baseline has 10 YAML blocks)

# Verify test integrated
bash .claude/tests/run_all_tests.sh | grep supervise_delegation
# Expected: Test runs and reports failure
```

**Complexity Justification**: Low complexity - audit scripts and baseline documentation only, no code changes.

**Dependencies**: None (Phase 0 always runs first)

---

### Phase 1: Convert Documentation Templates to Executable Invocations
**Objective**: Transform all YAML documentation blocks to imperative Task tool invocations
**Duration**: 4-5 days
**Complexity**: 9/10 (Critical - core functionality restoration)

**Tasks**:
1. [ ] Phase 1 Research - Lines 670-838 (2-4 invocations)
   - Remove ```yaml code block wrapper (lines 682-830)
   - Add imperative instruction: "**EXECUTE NOW**: USE the Task tool to invoke research-specialist agent."
   - Keep complete prompt template inline (will extract in Phase 2)
   - Repeat for each research agent invocation (complexity-based: 1-4 agents)
   - Verify syntax: Task invocation not wrapped in code blocks
2. [ ] Phase 1 Overview - Lines 985-1007 (1 invocation)
   - Currently commented out: `# Task { ... }`
   - Uncomment and convert to executable pattern
   - Add imperative instruction before Task block
   - Note: Only invoked if SUCCESSFUL_REPORT_COUNT ≥2
3. [ ] Phase 2 Planning - Lines 1078-1378 (1 invocation)
   - Remove ```yaml wrapper around planning agent invocation
   - Add: "**EXECUTE NOW**: USE the Task tool to invoke plan-architect agent."
   - Preserve prompt template inline (extraction in Phase 2)
   - Update STEP 2 header to match execution pattern
4. [ ] Phase 3 Implementation - Lines 1415-1695 (1 invocation)
   - Convert code-writer agent invocation to executable
   - Add imperative instruction
   - Maintain artifact verification pattern
5. [ ] Phase 4 Testing - Lines 1697-1893 (1 invocation)
   - Convert test-specialist agent invocation
   - Preserve test results parsing logic
6. [ ] Phase 5 Debug - Lines 1894-2213 (3 invocations)
   - Convert debug-analyst invocation (iteration loop)
   - Convert code-writer-fixes invocation
   - Convert test-rerun invocation
   - Maintain 3-iteration loop structure
7. [ ] Phase 6 Documentation - Lines 2215-2397 (1 invocation)
   - Convert doc-writer agent invocation
   - Conditional execution check preserved
8. [ ] Verify transformation completeness
   - Run: `grep -c '```yaml.*Task' .claude/commands/supervise.md`
   - Expected: 0 (no YAML blocks with Task)
   - Run: `grep -c 'EXECUTE NOW.*Task\|USE the Task tool' .claude/commands/supervise.md`
   - Expected: ≥9 (all invocations converted)

**Reference Pattern** (from `/orchestrate`):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT - File Creation FIRST**

    STEP 1: Use Write tool IMMEDIATELY to create: ${REPORT_PATH}
    STEP 2: Conduct research using Grep/Glob/Read tools
    STEP 3: Populate report using Edit tool
    STEP 4: Return ONLY: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Testing**:
```bash
# Run regression test
bash .claude/tests/test_supervise_delegation.sh
# Expected: PASS (≥9 imperative invocations, 0 YAML blocks)

# Verify no YAML blocks remain
grep -n '```yaml.*Task' .claude/commands/supervise.md
# Expected: No matches

# Count imperative invocations
grep -c 'EXECUTE NOW.*Task\|USE the Task tool' .claude/commands/supervise.md
# Expected: 9 or more
```

**Complexity Justification**: Very high complexity - requires careful transformation of 9 invocations across 6 phases, maintaining prompt structure and verification logic. Critical path item that enables all subsequent workflow functionality.

**Dependencies**: Phase 0 (baseline established)

---

### Phase 2: Extract Agent Templates to External Files
**Objective**: Reduce command file from 2,521 → 1,587 lines by extracting inline templates
**Duration**: 3-4 days
**Complexity**: 6/10

**Tasks**:
1. [ ] Create template directory structure
   - `mkdir -p .claude/templates/supervise/`
   - Add README.md documenting template usage
2. [ ] Extract research-specialist template (145 lines)
   - File: `.claude/templates/supervise/research-specialist-template.md`
   - Content: Lines 687-831 (complete prompt structure)
   - Update supervise.md: Reference template instead of inline
   - Pattern: "**Template**: `.claude/templates/supervise/research-specialist-template.md`"
3. [ ] Extract plan-architect template (180 lines)
   - File: `.claude/templates/supervise/plan-architect-template.md`
   - Content: Lines 1086-1265
   - Update reference in Phase 2
4. [ ] Extract code-writer template (177 lines)
   - File: `.claude/templates/supervise/code-writer-template.md`
   - Content: Lines 1443-1619
   - Update reference in Phase 3
5. [ ] Extract test-specialist template (113 lines)
   - File: `.claude/templates/supervise/test-specialist-template.md`
   - Content: Lines 1724-1836
   - Update reference in Phase 4
6. [ ] Extract debug-analyst template (93 lines)
   - File: `.claude/templates/supervise/debug-analyst-template.md`
   - Content: Lines 1935-2027
   - Update reference in Phase 5
7. [ ] Extract code-writer-fixes template (87 lines)
   - File: `.claude/templates/supervise/code-writer-fixes-template.md`
   - Content: Lines 2053-2139
   - Update reference in Phase 5 (iteration loop)
8. [ ] Extract test-rerun template (26 lines)
   - File: `.claude/templates/supervise/test-rerun-template.md`
   - Content: Lines 2149-2174
   - Update reference in Phase 5 (after fixes applied)
9. [ ] Extract doc-writer template (113 lines)
   - File: `.claude/templates/supervise/doc-writer-template.md`
   - Content: Lines 2250-2362
   - Update reference in Phase 6
10. [ ] Update all Task invocations to reference templates
    - Pattern from `/orchestrate`:
      ```markdown
      **EXECUTE NOW**: USE the Task tool with template injection.

      **Agent**: research-specialist
      **Template**: `.claude/templates/supervise/research-specialist-template.md`
      **Context Injection**:
      - Report Path: ${REPORT_PATH}
      - Topic: ${TOPIC_NAME}
      - Workflow: ${WORKFLOW_DESCRIPTION}
      ```
11. [ ] Verify file size reduction
    - Measure: `wc -l .claude/commands/supervise.md`
    - Expected: ≤1,600 lines (from 2,521 = 37% reduction)

**Testing**:
```bash
# Verify all templates exist
ls -1 .claude/templates/supervise/*.md | wc -l
# Expected: 9 (8 templates + README)

# Verify file size reduction
wc -l .claude/commands/supervise.md
# Expected: ≤1,600 lines

# Verify templates referenced
grep -c 'templates/supervise/.*-template.md' .claude/commands/supervise.md
# Expected: 8 (one per template)

# Run regression test (should still pass)
bash .claude/tests/test_supervise_delegation.sh
# Expected: PASS
```

**Complexity Justification**: Medium-high complexity - requires careful extraction preserving template structure, updating 8 references, maintaining execution flow. Risk of breaking prompt injection if extraction incomplete.

**Dependencies**: Phase 1 (invocations must be executable before extraction)

---

### Phase 3: Implement Metadata Extraction and Context Pruning
**Objective**: Add metadata extraction after verifications and context pruning after phases
**Duration**: 3-4 days
**Complexity**: 7/10

**Tasks**:
1. [ ] Add metadata extraction after Phase 1 verification (after line 878)
   - Source: `.claude/lib/metadata-extraction.sh`
   - Function: `extract_report_metadata()`
   - Store in: `REPORT_METADATA` array (not full paths)
   - Log context reduction: `echo "Context reduction: ${REDUCTION}%"`
   - Expected: 95% reduction (5000 → 250 tokens per report)
   - Code block provided in research report (lines 275-293)
2. [ ] Add context pruning after Phase 1 (after line 968)
   - Source: `.claude/lib/context-pruning.sh`
   - Function: `apply_pruning_policy --mode aggressive --workflow supervise`
   - Prune completed phase: `prune_phase_metadata "research"`
   - Clear agent outputs: `prune_subagent_output "research_agent_$i"`
   - Code block provided in research report (lines 304-320)
3. [ ] Implement forward message pattern for Phase 1→2 transition
   - Build structured handoff JSON (research complete → planning inputs)
   - Export: `RESEARCH_HANDOFF` variable
   - Log to: `.claude/data/logs/phase-handoffs.log`
   - Code block provided in research report (lines 335-356)
   - Expected: 90% context reduction vs passing full paths
4. [ ] Add metadata extraction after Phase 2 verification (plan created)
   - Extract: phase count, complexity score, estimated time
   - Already partially implemented (lines 1353-1362)
   - Enhance with metadata-extraction.sh functions
5. [ ] Add context pruning after Phase 2 (before Phase 3)
   - Prune: Planning agent output, research metadata (keep paths only)
6. [ ] Add metadata extraction after Phase 3 verification (implementation)
   - Extract: implementation status, phases completed, test status
   - Already partially implemented (lines 1637-1668)
7. [ ] Add context pruning after Phase 3 (before Phase 4)
   - Prune: Implementation logs, keep artifact paths
8. [ ] Add context pruning after Phase 4 (before Phase 5/6)
   - Prune: Test execution logs, keep status and failure details
9. [ ] Verify context usage target
   - Measure throughout workflow execution
   - Target: <30% context usage
   - Log: Context usage at each phase transition

**Testing**:
```bash
# Verify metadata extraction functions available
source .claude/lib/metadata-extraction.sh
type extract_report_metadata
# Expected: function definition

# Verify context pruning functions available
source .claude/lib/context-pruning.sh
type apply_pruning_policy prune_phase_metadata
# Expected: function definitions

# Test metadata extraction (mock)
TEST_REPORT="/tmp/test_report.md"
echo -e "# Test\n\n## Overview\n\nTest content" > "$TEST_REPORT"
METADATA=$(extract_report_metadata "$TEST_REPORT")
echo "$METADATA" | grep -q "title"
# Expected: Success (metadata extracted)

# Integration test: Run /supervise workflow and check logs
# Expected: Context reduction messages in output
# Expected: Phase handoff entries in .claude/data/logs/phase-handoffs.log
```

**Complexity Justification**: High complexity - integrates two new utility libraries, requires careful placement of extraction/pruning calls, must maintain workflow state across phases. Performance-critical for <30% context target.

**Dependencies**: Phase 1 (executable invocations required for metadata extraction)

---

### Phase 4: Improve Error Handling and Auto-Recovery
**Objective**: Replace sleep-based retry with exponential backoff, enhance error reporting
**Duration**: 2 days
**Complexity**: 4/10

**Tasks**:
1. [ ] Replace sleep-based retry with retry_with_backoff() (line 889)
   - Source: `.claude/lib/error-handling.sh`
   - Function: `retry_with_backoff 2 1000 verify_report_exists "$REPORT_PATH"`
   - Pattern: Max 2 retries, 1000ms initial backoff
   - Code block provided in research report (lines 367-376)
2. [ ] Verify retry_with_backoff used consistently
   - Check Phase 1 (research verification)
   - Check Phase 2 (plan verification)
   - Both already have retry logic, upgrade to exponential backoff
3. [ ] Test error handling with mock failures
   - Simulate transient error (file lock)
   - Simulate permanent error (syntax error)
   - Verify retry behavior: 1 retry for transient, fail-fast for permanent
4. [ ] Document error handling enhancements in command comments
   - Update auto-recovery section (lines 171-181)
   - Reference error-handling.sh functions

**Testing**:
```bash
# Verify error-handling.sh functions available
source .claude/lib/error-handling.sh
type retry_with_backoff classify_error suggest_recovery
# Expected: function definitions

# Test retry_with_backoff (mock)
test_function() {
  [ -f "/tmp/test_file_that_appears_later" ] && return 0 || return 1
}
(sleep 0.5 && touch /tmp/test_file_that_appears_later) &
retry_with_backoff 3 500 test_function
# Expected: Success after retry

# Integration test: Verify enhanced error messages
# Expected: "Error location: file.js:42" format
# Expected: "Error type: timeout" categorization
```

**Complexity Justification**: Medium-low complexity - straightforward function replacement, existing retry logic already in place, mainly enhancement of existing patterns.

**Dependencies**: Phase 1 (error handling applies to executable invocations)

---

### Phase 5: Update Documentation Standards
**Objective**: Document anti-patterns and add enforcement standards to prevent future regressions
**Duration**: 2-3 days
**Complexity**: 3/10

**Tasks**:
1. [ ] Update `.claude/docs/concepts/patterns/behavioral-injection.md`
   - Add section: "## Anti-Pattern: Template Documentation"
   - Include supervise.md as case study (before/after)
   - Detection method: YAML blocks vs imperative instructions
   - Code examples:
     - ❌ Bad: ````yaml Task { }```
     - ✅ Good: `EXECUTE NOW: USE the Task tool`
   - Location: After line 238 (existing anti-patterns section)
2. [ ] Create/update `.claude/docs/reference/command-architecture-standards.md`
   - File exists (confirmed in read)
   - Add **Standard 11**: "Agent Invocations Must Be Imperative Instructions"
   - Enforcement: Commands must use 'USE Task tool NOW', not '```yaml Task { }```'
   - Add to Standards 1-10 list (after line 100)
3. [ ] Update `.claude/docs/guides/command-development-guide.md`
   - Add section: "Avoiding Documentation-Only Patterns"
   - Before/after examples from supervise.md fix
   - Reference validation test (test_supervise_delegation.sh)
   - Show how to detect pattern violation
4. [ ] Add optimization note to supervise.md Phase 0 (lines 379-380)
   - Clarify scope of commit 25b1e1ff changes
   - Note: "Phase 0 optimization (agent → utilities) is separate from Phase 1+ research delegation"
   - Benefits: 90% context reduction, 20x speed improvement
   - Code block provided in research report (lines 439-446)
5. [ ] Update CLAUDE.md section on hierarchical agent architecture
   - Reference new standards in behavioral-injection.md
   - Add anti-pattern warnings
   - Link to supervise.md case study

**Testing**:
```bash
# Verify documentation files updated
git diff .claude/docs/concepts/patterns/behavioral-injection.md | grep -c "Anti-Pattern"
# Expected: ≥1 (section added)

git diff .claude/docs/reference/command-architecture-standards.md | grep -c "Standard 11"
# Expected: ≥1 (standard added)

# Verify links work
grep -l "behavioral-injection.md" .claude/docs/**/*.md
# Expected: Multiple files reference the pattern doc

# Manual review: Check examples are clear and actionable
```

**Complexity Justification**: Low-medium complexity - documentation updates, no execution changes, clear case study available from Phase 1 work.

**Dependencies**: Phase 1 (before/after examples come from invocation conversion)

---

### Phase 6: Integration Testing and Validation
**Objective**: Verify full workflow execution and measure performance improvements
**Duration**: 2-3 days
**Complexity**: 5/10

**Tasks**:
1. [ ] Run full test suite
   - Execute: `bash .claude/tests/run_all_tests.sh`
   - Verify: test_supervise_delegation.sh passes
   - Expected: All tests pass
2. [ ] Execute test workflows for each scope type
   - Research-only: `/supervise "research authentication patterns"`
   - Research-and-plan: `/supervise "research auth to create plan"`
   - Full-implementation: `/supervise "implement OAuth feature"`
   - Debug-only: `/supervise "fix token refresh bug"`
3. [ ] Measure performance metrics
   - File creation rate: Verify 100% (all artifacts created)
   - Context usage: Measure at each phase, verify <30%
   - File size: Verify ≤1,600 lines (from 2,521)
   - Delegation rate: Verify 9/9 invocations execute
4. [ ] Validate metadata extraction
   - Check logs for "Context reduction: N%" messages
   - Verify: 95% reduction per artifact (5000 → 250 tokens)
   - Check: .claude/data/logs/phase-handoffs.log has entries
5. [ ] Validate context pruning
   - Verify: Context usage decreases after each phase
   - Target: <30% cumulative throughout workflow
6. [ ] Run regression test suite
   - All existing functionality preserved
   - No breaking changes to workflow scope detection
   - Checkpoint resume still works
7. [ ] Performance comparison (before/after)
   - Baseline (from Phase 0): 2,521 lines, 0% delegation, no context optimization
   - Target: ≤1,600 lines, 100% delegation, <30% context usage
   - Document improvements in phase completion notes
8. [ ] Create test report
   - Summary of all test results
   - Performance metrics achieved
   - Comparison to success criteria
   - Save to: `.claude/specs/437_supervise_command_regression_analysis/test_results.md`

**Testing**:
```bash
# Full test suite
bash .claude/tests/run_all_tests.sh
# Expected: All tests pass

# Delegation test specifically
bash .claude/tests/test_supervise_delegation.sh
# Expected: PASS (≥9 imperative, 0 YAML blocks)

# Measure final metrics
wc -l .claude/commands/supervise.md
# Expected: ≤1,600 lines

grep -c 'EXECUTE NOW.*Task\|USE the Task tool' .claude/commands/supervise.md
# Expected: ≥9

grep -c '```yaml.*Task' .claude/commands/supervise.md
# Expected: 0

# Verify templates extracted
ls -1 .claude/templates/supervise/*.md | wc -l
# Expected: 9 (8 templates + README)
```

**Complexity Justification**: Medium complexity - comprehensive testing across multiple workflow types, performance measurement, comparison to baseline. Integration risk from all previous phases.

**Dependencies**: Phases 1-5 (all changes must be complete)

---

## Risk Assessment

### Critical Risks

**Risk 1: Breaking Existing Workflows**
- **Description**: Converting YAML blocks to executable invocations might break prompt structure or variable interpolation
- **Probability**: Medium
- **Impact**: High (workflow failure)
- **Mitigation**:
  - Phase 0: Create baseline backup before changes
  - Phase 1: Test each invocation conversion individually
  - Phase 6: Comprehensive integration testing for all workflow types
  - Rollback: Restore from `.claude/specs/437_supervise_command_regression_analysis/supervise.md.baseline`

**Risk 2: Template Extraction Breaking Prompt Injection**
- **Description**: External template references might fail to inject context properly
- **Probability**: Medium
- **Impact**: High (agent receives incomplete context)
- **Mitigation**:
  - Phase 2: Follow `/orchestrate` reference pattern exactly
  - Test each template extraction with mock invocation
  - Verify context variables (${REPORT_PATH}, etc.) still interpolate
  - Keep complete templates inline during Phase 1, extract only after validation

**Risk 3: Context Optimization Breaking Verification**
- **Description**: Pruning metadata too aggressively might remove data needed for verification
- **Probability**: Low
- **Impact**: High (verification failures)
- **Mitigation**:
  - Phase 3: Prune only AFTER verification and metadata extraction complete
  - Store artifact paths separately from full metadata
  - Test pruning with mock workflows before full integration
  - Log all pruning operations for audit trail

### Medium Risks

**Risk 4: Regression Test False Positives**
- **Description**: Test might pass even if invocations don't actually execute
- **Probability**: Medium
- **Impact**: Medium (undetected regression)
- **Mitigation**:
  - Phase 0: Verify test fails on baseline (expected failure)
  - Phase 6: Run actual workflows, not just syntax tests
  - Test file creation, not just invocation pattern presence

**Risk 5: Documentation Drift**
- **Description**: Standards updates might not reflect actual implementation
- **Probability**: Low
- **Impact**: Medium (future confusion)
- **Mitigation**:
  - Phase 5: Use actual before/after code from Phase 1 as examples
  - Cross-reference standards with command file
  - Include case study section with real regression details

### Low Risks

**Risk 6: Performance Overhead from Metadata Extraction**
- **Description**: Adding metadata extraction calls might slow workflow
- **Probability**: Low
- **Impact**: Low (<5% overhead expected)
- **Mitigation**:
  - Phase 3: Use lightweight extraction functions
  - Measure overhead in Phase 6 testing
  - Target: <30ms per extraction (negligible)

## Testing Strategy

### Unit Testing
- **Phase 0**: Regression test infrastructure (test_supervise_delegation.sh)
- **Phase 1**: Per-invocation validation (each Task pattern executable)
- **Phase 2**: Template extraction validation (each template file complete)
- **Phase 3**: Metadata extraction functions (mock reports)
- **Phase 4**: Error handling functions (mock failures)

### Integration Testing
- **Phase 6**: Full workflow execution for all 4 scope types
- **Phase 6**: Performance measurement (context usage, file creation rate)
- **Phase 6**: Regression suite (all existing functionality preserved)

### Acceptance Testing
- **Phase 6**: Success criteria validation (all checkboxes met)
- **Phase 6**: Performance comparison (before/after metrics)
- **Phase 6**: Test report documentation

## Documentation Requirements

### Command Documentation
- [x] supervise.md: Phase 0 optimization note added
- [x] supervise.md: Agent invocations converted to executable
- [x] supervise.md: Template references instead of inline

### Standards Documentation
- [ ] behavioral-injection.md: Anti-pattern section added
- [ ] command-architecture-standards.md: Standard 11 added
- [ ] command-development-guide.md: Avoiding documentation-only patterns section

### Case Study Documentation
- [ ] Research report: Already exists with complete analysis
- [ ] Test report: Created in Phase 6 with performance metrics
- [ ] Before/after examples: Documented in standards updates

## Dependencies

### External Dependencies
- `.claude/lib/metadata-extraction.sh`: Metadata extraction functions (exists)
- `.claude/lib/context-pruning.sh`: Context pruning functions (exists)
- `.claude/lib/error-handling.sh`: Error handling utilities (exists)
- `.claude/agents/research-specialist.md`: Behavioral guidelines (exists)
- `.claude/agents/plan-architect.md`: Behavioral guidelines (exists)
- Other agent behavioral files (all exist)

### Internal Dependencies
- Phase 0 → Phase 1: Baseline established before changes
- Phase 1 → Phase 2: Invocations executable before template extraction
- Phase 1 → Phase 3: Executable invocations required for metadata extraction
- Phase 1 → Phase 5: Before/after examples from invocation conversion
- Phases 1-5 → Phase 6: All changes complete before integration testing

### Workflow Dependencies
- No impact on `/orchestrate` command (independent)
- No impact on `/implement` command (independent)
- No impact on other workflow commands
- Standards updates apply to all future command development

## Notes

### Key Insights from Research

1. **Regression Mischaracterization**: The command has NOT lost delegation through code removal. The issue is an architectural pattern failure where invocations were implemented as documentation examples.

2. **Phase 0 Optimization Success**: The optimization of Phase 0 (location-specialist agent → utility functions) in commit 25b1e1ff was successful and should be retained. It demonstrates the correct pattern for optimizing deterministic operations while preserving agent delegation for complex reasoning.

3. **Architectural Foundations Strong**: The command demonstrates deep understanding of hierarchical patterns (orchestrator role, command chaining prohibition, path pre-calculation all correct). The issue is execution mechanics, not architectural design.

4. **Context Optimization Missing**: Despite strong architecture, the command lacks metadata extraction and context pruning, preventing achievement of <30% context usage target.

### Implementation Priorities

**CRITICAL (Week 1)**:
- Phase 0: Baseline and regression test
- Phase 1: Convert invocations to executable

**HIGH PRIORITY (Week 1-2)**:
- Phase 2: Extract templates (file size reduction)
- Phase 3: Context optimization (metadata extraction, pruning)

**MEDIUM PRIORITY (Week 2-3)**:
- Phase 4: Error handling improvements
- Phase 5: Documentation standards updates
- Phase 6: Integration testing and validation

### Success Metrics Summary

| Metric | Current (Baseline) | Target | Improvement |
|--------|-------------------|--------|-------------|
| Agent Delegation Rate | 0% (0/9) | 100% (9/9) | +100% |
| File Creation Rate | 0% (workflow fails) | 100% (with verification) | +100% |
| Workflow Completion | 0% (terminates Phase 1) | 100% (all 6 phases) | +100% |
| Context Usage | N/A (no execution) | <30% | Achieves target |
| Command File Size | 2,521 lines | ≤1,600 lines | -37% |
| Compliance Score | 75-80% (architecture only) | 95%+ | +15-20% |
| Template Bloat | 934 lines inline (37%) | 0 lines (extracted) | -100% |

### Cross-References

- Research Report: `.claude/specs/437_supervise_command_regression_analysis/reports/001_research/OVERVIEW.md`
- Baseline File: `.claude/specs/437_supervise_command_regression_analysis/supervise.md.baseline` (created in Phase 0)
- Test Report: `.claude/specs/437_supervise_command_regression_analysis/test_results.md` (created in Phase 6)
- Reference Implementation: `.claude/commands/orchestrate.md` (correct invocation pattern)
- Standards: `.claude/docs/concepts/patterns/behavioral-injection.md`
- Standards: `.claude/docs/reference/command-architecture-standards.md`

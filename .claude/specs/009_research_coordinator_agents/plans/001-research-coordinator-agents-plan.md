# Research Coordinator Agent Implementation Plan

## Metadata
- **Date**: 2025-12-08
- **Feature**: Add research-coordinator agent to /lean-plan for parallel multi-topic research orchestration
- **Status**: [COMPLETE]
- **Estimated Hours**: 18-24 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [Research Coordinator Agent Pattern Analysis](../reports/001-research-coordinator-agents-analysis.md)

## Overview

This plan implements a research-coordinator agent to optimize the /lean-plan command's research phase. Currently, /lean-plan performs initial research inline using the primary agent (13 tool calls consuming significant context), then delegates to planning subagents. The new research-coordinator will enable the primary agent to delegate research orchestration to a specialized coordinator, which can invoke multiple research-specialist subagents in parallel, aggregate findings, and return metadata summaries (achieving 40-60% context reduction).

## Research Summary

The research report identified 8 key findings supporting this implementation:

1. **Current /lean-plan performs inline research** (Finding 1): Primary agent uses 13 tool calls before delegating to plan-architect, consuming significant context
2. **/research demonstrates canonical hard barrier pattern** (Finding 2): Proven reference implementation with path pre-calculation, Task invocation, fail-fast validation
3. **Hierarchical agent architecture supports coordinator pattern** (Finding 3): Existing infrastructure provides explicit supervisor/coordinator roles with 95.6% context reduction
4. **Lean-coordinator demonstrates multi-phase coordination** (Finding 4): Pattern for managing multiple phases with task routing and structured summaries
5. **Topic-based directory structure supports multiple reports** (Finding 5): Sequential report numbering (001, 002, 003) without directory changes
6. **Path pre-calculation is coordinator responsibility** (Finding 6): Hard barrier pattern requires paths calculated BEFORE subagent invocation
7. **Metadata-only context passing reduces token usage** (Finding 7): Return 110 tokens instead of 2,500 tokens per report (95% reduction)
8. **Research-specialist already supports hard barrier pattern** (Finding 8): No behavioral file changes needed - coordinator simply invokes multiple times

Recommended approach: Create research-coordinator agent using hierarchical supervisor pattern with hard barrier delegation, integrate into /lean-plan (and later /create-plan, /repair, /debug, /revise).

## Success Criteria

- [x] research-coordinator behavioral file created at `.claude/agents/research-coordinator.md`
- [x] /lean-plan command integrates research-coordinator with hard barrier pattern
- [x] Research coordinator invokes multiple research-specialist instances in parallel
- [x] Aggregated metadata returned to primary agent (110 tokens per report)
- [x] Plan-architect receives report paths and metadata (not full content)
- [x] Context reduction of 40-60% measured in /lean-plan execution
- [x] All research reports created at pre-calculated paths
- [x] Hard barrier validation fails workflow when reports missing
- [x] Integration tests pass for multi-topic research scenarios

## Technical Design

### Architecture Overview

```
/lean-plan Primary Agent
    |
    +-- research-coordinator (NEW)
            +-- research-specialist 1 (Topic 1: Mathlib Theorems)
            +-- research-specialist 2 (Topic 2: Proof Patterns)
            +-- research-specialist 3 (Topic 3: Project Structure)
```

### Component Design

**1. research-coordinator.md** (New Agent):
- **Role**: Supervisor agent coordinating parallel research tasks
- **Responsibilities**:
  - Parse research topic list from primary agent
  - Pre-calculate report paths for each topic (001, 002, 003...)
  - Invoke research-specialist in parallel for each topic
  - Validate report artifacts (hard barrier pattern)
  - Extract metadata from reports (title, key findings count, recommendations)
  - Return aggregated metadata to primary agent (110 tokens per report)
- **Tools**: Task, Read, Bash, Grep
- **Behavioral Pattern**: Follows hierarchical supervisor pattern from hierarchical-agents-overview.md

**2. /lean-plan Command Integration**:
- **Modifications**:
  - Add Block 1d: Research Topics Classification (analyze user prompt to identify 2-5 topics)
  - Add Block 1d-exec: Research Coordinator Invocation (Task tool with hard barrier)
  - Add Block 1e: Research Validation (verify reports, parse metadata)
  - Update Block 2: Pass report paths to plan-architect (not full content)
- **Delegation Pattern**:
  ```markdown
  Block 1d: Classify topics from user prompt
  Block 1d-exec: Invoke research-coordinator via Task tool
  Block 1e: Validate reports exist, extract metadata
  Block 2: Pass report_paths to plan-architect
  ```

**3. Metadata Format** (Coordinator → Primary Agent):
```json
{
  "reports": [
    {
      "path": "/abs/path/to/001-mathlib-theorems.md",
      "title": "Mathlib Theorem Discovery",
      "findings_count": 12,
      "recommendations_count": 5
    },
    {
      "path": "/abs/path/to/002-proof-patterns.md",
      "title": "Common Proof Patterns",
      "findings_count": 8,
      "recommendations_count": 4
    }
  ],
  "total_reports": 2
}
```

### Hard Barrier Pattern Enforcement

**Path Pre-Calculation** (Before research-coordinator invocation):
1. Primary agent determines research topic count (N)
2. Pre-calculate N report paths: `${RESEARCH_DIR}/001-topic1.md`, `${RESEARCH_DIR}/002-topic2.md`, etc.
3. Pass paths as explicit contract to research-coordinator
4. research-coordinator passes paths to each research-specialist instance

**Verification** (After research-coordinator returns):
1. For each pre-calculated path, verify file exists
2. Verify file size >100 bytes (not empty)
3. Fail-fast if any report missing (workflow abort)
4. Extract metadata from reports using Read tool
5. Pass metadata to plan-architect (not full content)

### Standards Compliance

**Code Standards**:
- Three-tier bash sourcing pattern (error-handling, state-persistence, workflow-state-machine)
- Task invocations use imperative directives: "**EXECUTE NOW**: USE the Task tool..."
- Path validation handles PROJECT_DIR under HOME as valid

**Hierarchical Agent Architecture**:
- research-coordinator fits supervisor role
- Metadata-only context passing (110 tokens per report)
- Single source of truth (behavioral file in .claude/agents/)

**Hard Barrier Pattern**:
- Pre-calculate paths BEFORE agent invocation
- Validate artifacts AFTER agent returns
- Fail-fast on missing artifacts

**Error Logging**:
- Use log_command_error() for all error conditions
- Error types: agent_error, validation_error, state_error
- Centralized error log for queryable tracking

## Implementation Phases

### Phase 1: Create research-coordinator Behavioral File [COMPLETE]
dependencies: []

**Objective**: Create the research-coordinator agent behavioral file following hierarchical supervisor pattern

**Complexity**: Medium

**Tasks**:
- [x] Create `.claude/agents/research-coordinator.md` using hierarchical supervisor template
- [x] Define STEP 1: Receive and Verify Research Topics (parse topic list, validate report paths provided)
- [x] Define STEP 2: Invoke Parallel Research Workers (Task tool invocation for each research-specialist)
- [x] Define STEP 3: Validate Research Artifacts (hard barrier pattern - verify all reports exist)
- [x] Define STEP 4: Extract Metadata (read reports, extract title/findings/recommendations counts)
- [x] Define STEP 5: Return Aggregated Metadata (110 tokens per report format)
- [x] Add allowed-tools frontmatter: Task, Read, Bash, Grep
- [x] Add model: sonnet-4.5 (coordinator role suitable for mid-tier model)
- [x] Add dependent-agents: research-specialist
- [x] Document metadata extraction format (JSON schema)

**Testing**:
```bash
# Verify behavioral file structure
grep -q "## STEP 1: Receive and Verify Research Topics" .claude/agents/research-coordinator.md
grep -q "## STEP 2: Invoke Parallel Research Workers" .claude/agents/research-coordinator.md
grep -q "## STEP 5: Return Aggregated Metadata" .claude/agents/research-coordinator.md

# Validate frontmatter
grep -q "allowed-tools: Task, Read, Bash, Grep" .claude/agents/research-coordinator.md
grep -q "dependent-agents:" .claude/agents/research-coordinator.md
```

**Expected Duration**: 3-4 hours

### Phase 2: Integrate research-coordinator into /lean-plan [COMPLETE]
dependencies: [1]

**Objective**: Modify /lean-plan command to use research-coordinator for initial research phase

**Complexity**: High

**Tasks**:
- [x] Add Block 1d: Research Topics Classification bash block
  - Analyze FEATURE_DESCRIPTION to identify 2-5 research topics
  - Pre-calculate report paths for each topic (001-topic1.md, 002-topic2.md, etc.)
  - Persist topic list and paths to state file
- [x] Add Block 1d-exec: Research Coordinator Invocation using Task tool
  - Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
  - Pass research topics list and pre-calculated paths as contract
  - Include LEAN_PROJECT_PATH and RESEARCH_COMPLEXITY in context
- [x] Add Block 1e: Research Validation bash block (hard barrier)
  - For each pre-calculated path, verify file exists
  - Validate file size >100 bytes
  - Fail-fast if any report missing
  - Extract metadata from each report (title, findings count)
  - Persist metadata to state file
- [x] Update Block 2: Planning Phase Integration
  - Remove inline research tool calls (Read, Grep, Search)
  - Pass report paths to plan-architect (not full content)
  - Include metadata summary in plan-architect prompt
- [x] Update frontmatter dependent-agents field
  - Add research-coordinator to dependency list
  - Maintain existing lean-research-specialist, lean-plan-architect

**Testing**:
```bash
# Test /lean-plan with research-coordinator integration
cd /home/benjamin/Documents/Philosophy/Projects/ProofChecker
/lean-plan "Formalize distributivity properties for lattice operations"

# Verify research-coordinator was invoked (check output)
grep "research-coordinator" /home/benjamin/.config/.claude/output/lean-plan-output.md

# Verify multiple reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
# Should be ≥2 reports

# Verify plan-architect received report paths (not full content)
grep "Research Reports:" .claude/specs/*/plans/*.md
```

**Expected Duration**: 6-8 hours

### Phase 3: Add Topic Detection Agent (Optional Enhancement) [COMPLETE]
dependencies: [2]

**Objective**: Create lightweight topic-detection-agent to automatically decompose user prompts into research topics

**Complexity**: Medium

**Tasks**:
- [x] Create `.claude/agents/topic-detection-agent.md` behavioral file
- [x] Define input contract: FEATURE_DESCRIPTION string
- [x] Define output contract: JSON list of 2-5 topics with scope descriptions
- [x] Add fallback behavior: If detection fails, return single topic (backward compatibility)
- [x] Integrate into research-coordinator (invoke before path pre-calculation)
- [x] Add allowed-tools: Write (for JSON output file)
- [x] Add model: haiku-4.1 (simple task suitable for lightweight model)

**Testing**:
```bash
# Test topic detection agent standalone
Task {
  prompt: "Read and follow: .claude/agents/topic-detection-agent.md
           FEATURE_DESCRIPTION: 'Formalize group homomorphism theorems and proof automation'
           OUTPUT_PATH: /tmp/topics.json"
}

# Verify JSON output format
cat /tmp/topics.json | jq '.topics | length'
# Should return 2-5

# Verify fallback behavior (test with ambiguous prompt)
Task {
  prompt: "Read and follow: .claude/agents/topic-detection-agent.md
           FEATURE_DESCRIPTION: 'Fix bug'
           OUTPUT_PATH: /tmp/topics_fallback.json"
}
cat /tmp/topics_fallback.json | jq '.topics | length'
# Should return 1 (fallback)
```

**Expected Duration**: 4-5 hours

### Phase 4: Apply Pattern to Other Planning Commands [DEFERRED]
dependencies: [2]

**Objective**: Extend research-coordinator pattern to /create-plan, /repair, /debug, /revise commands

**Complexity**: High

**Tasks**:
- [ ] Integrate research-coordinator into /create-plan command
  - Add research phase blocks (1d, 1d-exec, 1e)
  - Update plan-architect invocation to use report metadata
- [ ] Integrate research-coordinator into /repair command
  - Add error pattern research phase
  - Coordinate research across multiple error types
- [ ] Integrate research-coordinator into /debug command
  - Add issue investigation research phase
  - Coordinate research across codebase context
- [ ] Integrate research-coordinator into /revise command
  - Add context research phase before plan revision
  - Pass research findings to plan-architect revision
- [ ] Update command frontmatter for all modified commands
  - Add research-coordinator to dependent-agents
- [ ] Test each command integration independently

**Testing**:
```bash
# Test /create-plan with research-coordinator
/create-plan "Add session management to authentication system" --complexity 3
grep -c "reports/" .claude/specs/*/plans/*.md
# Should show multiple report references

# Test /repair with research-coordinator
/repair --since 1h --type state_error
grep "research-coordinator" .claude/output/repair-output.md

# Test /debug with research-coordinator
/debug "Authentication tokens expire prematurely" --complexity 2
ls .claude/specs/*/reports/*.md
# Should show multiple research reports

# Test /revise with research-coordinator
/revise "Update plan to add security audit phase" --file .claude/specs/042_auth/plans/001_auth.md
grep "Research Reports:" .claude/specs/042_auth/plans/001_auth.md
```

**Expected Duration**: 8-10 hours

### Phase 5: Documentation and Validation [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Document research-coordinator pattern and add validation tests

**Complexity**: Low

**Tasks**:
- [x] Add research-coordinator example to `.claude/docs/concepts/hierarchical-agents-examples.md`
  - Show topic decomposition strategy
  - Show parallel research-specialist invocation
  - Show metadata aggregation format
  - Show primary agent integration pattern
- [x] Create integration test: `.claude/tests/integration/test_research_coordinator.sh`
  - Test multi-topic research scenario
  - Verify parallel execution (time measurement)
  - Verify metadata format returned
  - Verify context reduction (compare before/after token counts)
- [x] Update CLAUDE.md hierarchical_agent_architecture section
  - Reference research-coordinator as Example 7
  - Document metadata-only context passing benefits
- [x] Add troubleshooting entry for research-coordinator failures
  - Missing reports diagnostic
  - Path mismatch diagnostic
  - Metadata extraction errors

**Testing**:
```bash
# Run integration test suite
bash .claude/tests/integration/test_research_coordinator.sh

# Verify documentation links
bash .claude/scripts/validate-links-quick.sh .claude/docs/concepts/hierarchical-agents-examples.md

# Verify standards compliance
bash .claude/scripts/validate-all-standards.sh --all
```

**Expected Duration**: 3-4 hours

## Testing Strategy

### Unit Testing
- Test research-coordinator behavioral file compliance (structure, steps, metadata format)
- Test topic-detection-agent output format (JSON schema validation)
- Test path pre-calculation logic (sequential numbering, slug generation)

### Integration Testing
- Test /lean-plan with research-coordinator (multi-topic scenario)
- Test parallel research-specialist invocation (measure time savings vs sequential)
- Test hard barrier validation (simulate missing reports, verify fail-fast)
- Test metadata extraction and aggregation (verify 110 tokens per report)
- Test plan-architect integration (verify receives paths, not full content)

### Performance Testing
- Measure context reduction: Compare /lean-plan token usage before/after integration
  - Baseline: Current inline research (13 tool calls)
  - Target: 40-60% reduction with research-coordinator
- Measure execution time: Parallel vs sequential research
  - Baseline: Sequential research-specialist invocations
  - Target: 40-60% time reduction with parallel execution

### Regression Testing
- Verify /lean-plan backward compatibility (single-topic scenarios)
- Verify research-specialist behavioral file unchanged
- Verify plan-architect behavioral file unchanged
- Verify existing /lean-plan tests pass

### Coverage Requirements
- 100% coverage of hard barrier validation paths (file exists, size checks)
- 100% coverage of metadata extraction logic
- 100% coverage of error logging integration

## Documentation Requirements

### Agent Documentation
- `.claude/agents/research-coordinator.md` - Complete behavioral file with all 5 steps
- `.claude/agents/topic-detection-agent.md` - Behavioral file with fallback behavior

### Pattern Documentation
- `.claude/docs/concepts/hierarchical-agents-examples.md` - Add Example 7 (research-coordinator)
- `.claude/docs/guides/commands/lean-plan-command-guide.md` - Update with research-coordinator integration
- Update `.claude/docs/reference/standards/command-reference.md` - Document dependent-agents changes

### Troubleshooting Documentation
- Add research-coordinator troubleshooting section to hierarchical-agents-troubleshooting.md
- Document common issues: missing reports, path mismatches, metadata extraction failures

## Dependencies

### External Dependencies
- None (uses existing research-specialist agent)

### Internal Dependencies
- research-specialist agent (unchanged - already supports hard barrier pattern)
- plan-architect agent (receives report paths instead of full content)
- Hard barrier pattern infrastructure (path pre-calculation, validation)
- Hierarchical agent architecture (supervisor/coordinator pattern)

### Standards Dependencies
- CLAUDE.md hierarchical_agent_architecture section
- CLAUDE.md error_logging section
- CLAUDE.md code_standards section (three-tier sourcing)

## Risk Assessment

### Technical Risks

**Risk 1: Topic detection inaccuracy**
- **Impact**: Research-coordinator receives poorly scoped topics
- **Mitigation**: Implement fallback to single-topic mode, allow manual topic specification via --topics flag
- **Severity**: Low (fallback ensures functionality)

**Risk 2: Parallel execution failures**
- **Impact**: One research-specialist fails, blocking entire research phase
- **Mitigation**: Implement partial success mode (coordinator continues if ≥50% reports succeed), log failed topics for retry
- **Severity**: Medium (affects user experience but not critical)

**Risk 3: Metadata extraction parsing errors**
- **Impact**: Coordinator cannot extract metadata from malformed reports
- **Mitigation**: Add graceful degradation (use filename as title fallback), validate report structure
- **Severity**: Low (degrades to basic functionality)

### Integration Risks

**Risk 4: Plan-architect expects full report content**
- **Impact**: Plan quality degrades with metadata-only input
- **Mitigation**: Update plan-architect to read report files as needed (receives paths), verify plan quality in Phase 2 testing
- **Severity**: Medium (affects plan quality)

**Risk 5: Breaking changes to /lean-plan**
- **Impact**: Existing workflows fail after integration
- **Mitigation**: Maintain backward compatibility (single-topic fallback), comprehensive regression testing
- **Severity**: High (breaks existing users)

### Timeline Risks

**Risk 6: Phase 4 scope creep**
- **Impact**: Extending to 4 additional commands exceeds estimated time
- **Mitigation**: Prioritize /create-plan integration (highest impact), defer /repair, /debug, /revise to Phase 6 (future work)
- **Severity**: Low (can be deferred)

## Migration Strategy

### Phase 2 Integration Approach [COMPLETE]

**Option A: Replace Inline Research** (Recommended)
- Remove existing inline research tool calls from /lean-plan
- Delegate entirely to research-coordinator
- Benefits: Clean architecture, full context reduction
- Risks: Breaking change if coordinator fails

**Option B: Hybrid Approach** (Safe Fallback)
- Add research-coordinator as optional phase (--use-coordinator flag)
- Keep inline research as fallback if coordinator fails
- Benefits: Backward compatibility, gradual rollout
- Risks: Maintains legacy code, split maintenance burden

**Decision**: Use Option A with comprehensive hard barrier validation to ensure fail-fast behavior (aligns with existing /research pattern)

### Rollback Plan

If research-coordinator integration causes failures:
1. Revert /lean-plan command to git HEAD (before Phase 2 changes)
2. Preserve research-coordinator.md for future use
3. Document failure mode in research-coordinator troubleshooting
4. Re-evaluate approach with Option B (hybrid)

## Future Enhancements

### Phase 6: Advanced Topic Detection (Deferred)
- LLM-based topic clustering (analyze prompt semantics)
- User-interactive topic refinement (prompt for confirmation)
- Topic dependency tracking (some topics depend on others)

### Phase 7: Adaptive Research Depth (Deferred)
- Complexity-based research allocation (simple prompts = 1 topic, complex = 5 topics)
- Dynamic research-specialist selection (different specialists for different domains)
- Iterative research (coordinator requests follow-up research based on initial findings)

### Phase 8: Cross-Command Research Sharing (Deferred)
- Research cache for common topics (reuse Mathlib theorem research across plans)
- Research index for topic discovery (search existing reports before creating new)
- Research versioning (track when research becomes stale)

## Notes

- This implementation follows the hierarchical supervisor pattern from hierarchical-agents-overview.md
- The hard barrier pattern ensures mandatory delegation (no bypass possible)
- Metadata-only context passing achieves 95%+ context reduction at scale
- research-coordinator is reusable across all planning workflows (/create-plan, /repair, /debug, /revise)
- No changes needed to research-specialist behavioral file (already supports path pre-calculation)
- Topic detection is optional enhancement (Phase 3) - core functionality works without it

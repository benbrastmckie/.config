# Research Coordinator Implementation: Gap Analysis and Uniformity Assessment

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist
- **Topic**: Research coordinator implementation gaps and command uniformity analysis
- **Report Type**: gap analysis and architectural uniformity assessment

## Executive Summary

The research-coordinator implementation (spec 009) has successfully completed Phases 1-3 and 5, creating the behavioral file, topic-detection-agent, documentation, and integration tests. However, **Phase 4 remains DEFERRED** - critically, NO commands currently invoke research-coordinator despite the infrastructure being complete. The original report recommended integrating research-coordinator into /lean-plan first, then /create-plan, /repair, /debug, and /revise. Analysis reveals:

1. **Critical Gap**: Zero commands actively use research-coordinator (0/5 target commands)
2. **/lean-plan Status**: Still uses lean-research-specialist directly (single-topic pattern), not research-coordinator
3. **/create-plan Status**: Still uses research-specialist directly (single-topic pattern), not research-coordinator
4. **Uniformity Gap**: No consistent research orchestration pattern across commands - each implements inline research differently
5. **Standards Alignment**: All commands use hard barrier pattern correctly, but miss parallelization opportunity

The gap between completed infrastructure (research-coordinator agent, topic-detection-agent, tests, docs) and actual command integration represents approximately **18-24 hours of deferred implementation work** per the original plan Phase 4 estimate.

## Findings

### Finding 1: Research-Coordinator Infrastructure is Complete But Unused
- **Description**: All Phase 1-3 and Phase 5 deliverables exist and pass integration tests, but no commands invoke research-coordinator
- **Location**:
  - `/home/benjamin/.config/.claude/agents/research-coordinator.md` (569 lines, complete behavioral file)
  - `/home/benjamin/.config/.claude/agents/topic-detection-agent.md` (523 lines, complete behavioral file)
  - `/home/benjamin/.config/.claude/tests/integration/test_research_coordinator.sh` (501 lines, comprehensive test suite)
  - `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (Example 7 documented at lines 560-798)
- **Evidence**:
```bash
# Verify research-coordinator exists
$ ls -lh .claude/agents/research-coordinator.md
-rw-r--r-- 1 benjamin benjamin 32K Dec  8 12:00 .claude/agents/research-coordinator.md

# Check for commands using research-coordinator
$ grep -l "research-coordinator" .claude/commands/*.md
(no output - zero commands invoke it)

# Verify dependent-agents declarations
$ grep -A 5 "^dependent-agents:" .claude/commands/create-plan.md
dependent-agents:
  - research-specialist
  - research-sub-supervisor
  - plan-architect
```
- **Impact**: **HIGH SEVERITY** - Complete infrastructure with zero utilization. The 40-60% context reduction and parallelization benefits documented in spec 009 are unrealized. Commands continue to use inline single-topic research patterns consuming significant context.

### Finding 2: Original Report Recommended /create-plan Integration (Not Implemented)
- **Description**: The original report (Finding 1-10, Recommendations 1-10) specifically targeted /create-plan for research-coordinator integration, but the command still uses single-topic research-specialist invocation
- **Location**:
  - Original report: `/home/benjamin/.config/.claude/specs/011_create_plan_research_coordinator/reports/001-i-want-the-create-plan-command-in-clau.md` lines 15-246
  - Current /create-plan: `.claude/commands/create-plan.md` lines 951-986 (Block 1e-exec: Research Specialist Invocation)
- **Evidence**:
```markdown
# Original Report Recommendation 3 (lines 198-203):
"Replace Block 1e-exec with research-coordinator invocation: Modify Block 1e-exec (currently single research-specialist invocation) to:
   - Invoke research-coordinator via Task tool (not research-specialist directly)
   - Pass TOPICS_ARRAY, REPORT_PATHS_ARRAY, and RESEARCH_DIR as explicit contract"

# Current /create-plan Block 1e-exec (lines 951-986):
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Research Complexity: ${RESEARCH_COMPLEXITY}
    - Output Path: ${REPORT_PATH}
  "
}
```
- **Impact**: /create-plan continues to perform single-topic research, missing parallelization for complex multi-domain features (e.g., "implement OAuth2 authentication with session management and password security" would benefit from 3 parallel research topics but currently serializes into one report).

### Finding 3: /lean-plan Uses lean-research-specialist Directly (Not Coordinator)
- **Description**: Spec 009 Phase 2 claimed "/lean-plan command integrates research-coordinator with hard barrier pattern" (marked [COMPLETE]), but inspection reveals /lean-plan still uses lean-research-specialist directly
- **Location**: `.claude/commands/lean-plan.md` (research invocation pattern)
- **Evidence**:
```bash
# Check lean-plan for research-coordinator usage
$ grep "research-coordinator\|lean-research-specialist" .claude/commands/lean-plan.md | head -5
  - lean-research-specialist
**EXECUTE NOW**: USE the Task tool to invoke the lean-research-specialist agent with mandatory file creation.
    ${CLAUDE_PROJECT_DIR}/.claude/agents/lean-research-specialist.md
- **Research fails**: Check lean-research-specialist agent behavioral file compliance
```
- **Impact**: Spec 009 Phase 2 success criteria "✓ /lean-plan command integrates research-coordinator with hard barrier pattern" appears to be **incorrectly marked COMPLETE**. The integration was either never implemented or was reverted. This creates **documentation-implementation mismatch**.

### Finding 4: Phase 4 (Multi-Command Integration) Explicitly Deferred
- **Description**: Spec 009 Phase 4 "Apply Pattern to Other Planning Commands" is marked [DEFERRED], with 0/5 target commands integrated
- **Location**: `/home/benjamin/.config/.claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md` lines 266-310
- **Evidence**:
```markdown
### Phase 4: Apply Pattern to Other Planning Commands [DEFERRED]
dependencies: [2]

**Objective**: Extend research-coordinator pattern to /create-plan, /repair, /debug, /revise commands

**Tasks**:
- [ ] Integrate research-coordinator into /create-plan command
- [ ] Integrate research-coordinator into /repair command
- [ ] Integrate research-coordinator into /debug command
- [ ] Integrate research-coordinator into /revise command
- [ ] Update command frontmatter for all modified commands
- [ ] Test each command integration independently
```
- **Impact**: All 5 target commands (/create-plan, /repair, /debug, /revise, /lean-plan) remain unintegrated. The deferred phase represents the **critical deliverable gap** between infrastructure (complete) and user-facing features (incomplete).

### Finding 5: Command Research Patterns Show Non-Uniformity
- **Description**: Commands that perform research use inconsistent invocation patterns - some use research-specialist directly, some use workflow-specific specialists (lean-research-specialist), none use research-coordinator
- **Location**: Command frontmatter and Task invocation blocks across /create-plan, /lean-plan, /debug, /research, /repair
- **Evidence**:
```yaml
# /create-plan (lines 6-9)
dependent-agents:
  - research-specialist
  - research-sub-supervisor  # UNUSED
  - plan-architect

# /lean-plan
dependent-agents:
  - lean-research-specialist  # Specialized variant

# /research (lines 6-9)
dependent-agents:
  - research-specialist
  - research-sub-supervisor  # UNUSED

# /debug
dependent-agents:
  - research-specialist  # Direct invocation

# /repair
dependent-agents:
  - research-specialist  # Direct invocation
```
- **Impact**: Non-uniform patterns create:
  1. **Maintenance burden**: Changes to research orchestration require updating 5 different command patterns
  2. **Feature parity gaps**: Some commands could benefit from multi-topic research but can't use the pattern
  3. **Documentation confusion**: Standards don't specify when to use coordinator vs direct specialist invocation
  4. **Dead code**: research-sub-supervisor listed as dependent but never invoked

### Finding 6: Original Report's Recommendation 9 (Topic-Detection-Agent) Implemented But Unused
- **Description**: The original report suggested "Consider creating lightweight topic-detection-agent for automated decomposition" as optional Phase 3 enhancement. This was implemented and marked [COMPLETE], but no commands invoke it
- **Location**:
  - Agent file: `.claude/agents/topic-detection-agent.md` (523 lines)
  - Original recommendation: `011_create_plan_research_coordinator/reports/001-i-want-the-create-plan-command-in-clau.md` lines 238-243
  - Implementation phase: `009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md` lines 225-263 (Phase 3 [COMPLETE])
- **Evidence**:
```markdown
# topic-detection-agent.md header (lines 1-7):
---
allowed-tools: Write, Bash
description: Lightweight agent analyzing user prompts to decompose into 2-5 focused research topics
model: haiku-4.1
model-justification: Simple task suitable for lightweight model - text analysis and JSON generation with minimal reasoning
fallback-model: sonnet-4.5
---

# Integration point documented (lines 469-471):
### Commands Using Topic Detection

- `/lean-plan` - Lean theorem research phase (planned)
- `/create-plan` - Software feature research phase (planned)
- `/research` - General research workflow (planned)
```
- **Impact**: Haiku-based topic detection agent (cost-optimized) exists but is never invoked. Commands continue to treat user prompts as single topics, missing automated decomposition that would enable parallelization.

### Finding 7: Hard Barrier Pattern Correctly Implemented (Uniformity Success)
- **Description**: All research-performing commands correctly implement the hard barrier pattern (path pre-calculation → Task invocation → validation), showing uniformity in this aspect
- **Location**:
  - /create-plan: `.claude/commands/create-plan.md` lines 849-1108 (Blocks 1e, 1e-exec, 1f)
  - /research: `.claude/commands/research.md` (similar pattern)
  - /lean-plan: `.claude/commands/lean-plan.md` (similar pattern)
- **Evidence**:
```markdown
# /create-plan hard barrier pattern (lines 913-948):
## Block 1e: Research Setup and Context Barrier
# Pre-calculate report path before research-specialist invocation
REPORT_PATH="${RESEARCH_DIR}/${REPORT_FILENAME}"

## Block 1e-exec: Research Specialist Invocation
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

## Block 1f: Research Output Verification
# HARD BARRIER: validate_agent_artifact checks file existence and minimum size
if ! validate_agent_artifact "$REPORT_PATH" 100 "research report"; then
  echo "ERROR: HARD BARRIER FAILED - Research specialist validation failed" >&2
  exit 1
fi
```
- **Impact**: **POSITIVE** - Hard barrier pattern uniformity achieved across commands. Path pre-calculation, Task invocation, and fail-fast validation are consistently implemented. This provides a solid foundation for integrating research-coordinator (which also uses hard barrier pattern internally).

### Finding 8: Original Report Identified Missing "Block 1d-topics: Topic Decomposition" (Not Implemented)
- **Description**: Original report Recommendation 2 specified adding topic decomposition block to /create-plan. This block does not exist in current implementation
- **Location**:
  - Original recommendation: `011_create_plan_research_coordinator/reports/001-i-want-the-create-plan-command-in-clau.md` lines 191-197
  - Current /create-plan structure: `.claude/commands/create-plan.md` (Block 1d is "Topic Path Initialization", not topic decomposition)
- **Evidence**:
```markdown
# Original Recommendation 2 (lines 191-197):
"Add Block 1d-topics: Topic Decomposition to /create-plan: Insert a new bash block after Block 1d (topic path initialization) that:
   - Analyzes FEATURE_DESCRIPTION to identify 1-5 discrete research topics
   - Uses RESEARCH_COMPLEXITY to determine topic count (complexity 1-2 → 1 topic, complexity 3 → 2-3 topics, complexity 4 → 4-5 topics)
   - Pre-calculates report paths for each topic: `${RESEARCH_DIR}/001-topic1.md`, `${RESEARCH_DIR}/002-topic2.md`, etc."

# Current /create-plan Block 1d (lines 541-847):
## Block 1d: Topic Path Initialization
**EXECUTE NOW**: Parse topic name from agent output and initialize workflow paths.
```
- **Impact**: Without topic decomposition, /create-plan cannot identify multi-topic features that would benefit from parallel research. The research-coordinator pattern requires topics list as input, which is not generated.

### Finding 9: Research-Sub-Supervisor Referenced But Never Invoked
- **Description**: Multiple commands list research-sub-supervisor as dependent-agent, but no commands invoke it. Research-coordinator documentation shows it's optional (used when topic count ≥4)
- **Location**:
  - Declared in: `/create-plan` (line 8), `/research` (line 8)
  - Research-coordinator logic: `.claude/agents/research-coordinator.md` lines 172-173
- **Evidence**:
```markdown
# /create-plan dependent-agents (lines 6-9):
dependent-agents:
  - research-specialist
  - research-sub-supervisor  # DECLARED BUT NEVER INVOKED
  - plan-architect

# research-coordinator design note (lines 172-173):
"Invokes research-sub-supervisor if topic count ≥ 4 (hierarchical pattern), or directly invokes multiple research-specialist workers if topic count < 4 (flat pattern)"
```
- **Impact**: **MINOR** - research-sub-supervisor is infrastructure for 4+ topic scenarios (rare). The bigger issue is that research-coordinator (which would invoke sub-supervisor when needed) is itself not invoked. This is a symptom of the Phase 4 deferral.

### Finding 10: Documentation Updated But Commands Not Synchronized
- **Description**: Spec 009 Phase 5 "Documentation and Validation" was marked [COMPLETE], adding Example 7 to hierarchical-agents-examples.md. However, this creates documentation-implementation drift - docs describe research-coordinator pattern but commands don't use it
- **Location**:
  - Documentation: `.claude/docs/concepts/hierarchical-agents-examples.md` lines 560-798 (Example 7: Research Coordinator with /lean-plan)
  - Reality: No commands invoke research-coordinator
- **Evidence**:
```markdown
# hierarchical-agents-examples.md (lines 560-567):
## Example 7: Research Coordinator with /lean-plan

The research-coordinator agent orchestrates parallel research-specialist invocations, validates artifacts via hard barrier pattern, and returns metadata summaries (95% context reduction).

### Hierarchy

```
/lean-plan Primary Agent
    |
    +-- research-coordinator (Supervisor)
            +-- research-specialist 1 (Topic 1: Mathlib Theorems)
            +-- research-specialist 2 (Topic 2: Proof Patterns)
            +-- research-specialist 3 (Topic 3: Project Structure)
```

# But grep shows:
$ grep -l "research-coordinator" .claude/commands/*.md
(no output)
```
- **Impact**: Documentation leads developers to believe the pattern is implemented. New command authors might copy the documented pattern, only to find it doesn't exist in actual commands. This creates **maintenance risk** and **onboarding confusion**.

## Recommendations

### Priority 1: Complete Phase 4 Integration (Critical)

**Recommendation 1**: Implement research-coordinator integration for /create-plan following original report specification
- **Justification**: /create-plan is highest-value target (general-purpose planning), original report provided detailed integration plan (Recommendations 1-4), and complexity is well-understood
- **Scope**:
  1. Add Block 1d-topics: Topic Decomposition (parse FEATURE_DESCRIPTION → 1-5 topics based on RESEARCH_COMPLEXITY)
  2. Optionally invoke topic-detection-agent for automated decomposition (or use heuristic-based decomposition)
  3. Replace Block 1e-exec research-specialist invocation with research-coordinator invocation
  4. Update Block 1f validation to handle multiple reports (loop through REPORT_PATHS_ARRAY)
  5. Update frontmatter dependent-agents: add research-coordinator, optionally add topic-detection-agent
- **Estimated Effort**: 6-8 hours (per spec 009 Phase 4 Task 1 estimate)
- **Success Criteria**:
  - /create-plan invokes research-coordinator when RESEARCH_COMPLEXITY ≥ 3
  - Multiple research reports created in parallel
  - Plan-architect receives report paths (not full content)
  - Context reduction measured (target 40-60%)

**Recommendation 2**: Verify /lean-plan integration status and correct plan documentation
- **Justification**: Spec 009 Phase 2 marked [COMPLETE] but implementation evidence is missing. Either the integration was never done, or it was reverted without updating the plan
- **Scope**:
  1. Inspect /lean-plan command for research-coordinator invocation (currently uses lean-research-specialist directly)
  2. If not integrated: Update spec 009 Phase 2 status to [NOT STARTED] or [PARTIAL]
  3. If integrated but using different pattern: Document the actual implementation vs original plan
  4. Create sub-task for /lean-plan integration (may require lean-specific topic decomposition logic)
- **Estimated Effort**: 2-3 hours (investigation + plan correction) + 6-8 hours (integration if needed)
- **Success Criteria**:
  - Spec 009 Phase 2 status accurately reflects implementation reality
  - If not integrated: Clear work item for /lean-plan research-coordinator integration

**Recommendation 3**: Integrate research-coordinator into /research command (simplest case)
- **Justification**: /research is research-only workflow (no planning phase), making it the simplest integration case. Success here validates the pattern before applying to more complex commands
- **Scope**:
  1. Add topic decomposition logic (research request → 1-5 topics)
  2. Invoke research-coordinator instead of research-specialist directly
  3. Update frontmatter to include research-coordinator and topic-detection-agent
  4. Test multi-topic research scenario
- **Estimated Effort**: 4-6 hours (simpler than /create-plan due to single-phase workflow)
- **Success Criteria**:
  - /research creates multiple reports for complex research requests
  - Parallel execution verified (time measurement)
  - Metadata-only context passing to terminal state

**Recommendation 4**: Defer /repair and /debug integration to Phase 6 (future work)
- **Justification**: /repair and /debug have specialized research needs (error pattern analysis, issue investigation) that may require custom topic decomposition logic. Prioritize general-purpose commands (/create-plan, /research) first
- **Scope**: Add Phase 6 to spec 009 plan with tasks for /repair and /debug integration after /create-plan and /research patterns are validated
- **Estimated Effort**: 8-10 hours each (per original Phase 4 estimate)

### Priority 2: Establish Command Uniformity Standards

**Recommendation 5**: Create research invocation standards document
- **Justification**: Current non-uniformity (Finding 5) stems from lack of clear standards. Document when to use research-coordinator vs research-specialist directly vs specialized variants
- **Scope**: Add `.claude/docs/reference/standards/research-invocation-standards.md` covering:
  1. **Single-topic research**: Use research-specialist directly (complexity 1-2, focused prompts)
  2. **Multi-topic research**: Use research-coordinator (complexity 3-4, broad/complex prompts)
  3. **Specialized research**: Use domain-specific specialist (lean-research-specialist for Lean projects)
  4. **Decision matrix**: RESEARCH_COMPLEXITY × prompt structure → invocation pattern
  5. **Migration path**: How to update existing commands to use coordinator pattern
- **Estimated Effort**: 3-4 hours (documentation)
- **Success Criteria**: Clear decision tree for command authors choosing research pattern

**Recommendation 6**: Update command-authoring.md with research-coordinator pattern examples
- **Justification**: Command Patterns Quick Reference should include copy-paste templates for research-coordinator invocation
- **Scope**: Add to `.claude/docs/reference/standards/command-authoring.md`:
  1. Section: "Research Coordinator Delegation Pattern"
  2. Template: Topic decomposition block
  3. Template: research-coordinator Task invocation
  4. Template: Multi-report validation loop
  5. Template: Metadata extraction and passing
- **Estimated Effort**: 2-3 hours (add templates to existing doc)
- **Success Criteria**: Command authors can copy-paste research-coordinator integration pattern

**Recommendation 7**: Standardize dependent-agents declarations for research workflows
- **Justification**: Inconsistent dependent-agents lists (Finding 5) create confusion about which agents are actually used
- **Scope**: Define standards for dependent-agents field:
  1. **Required**: All agents directly invoked by command
  2. **Transitive**: Agents invoked by sub-agents (e.g., research-coordinator invokes research-specialist)
  3. **Rule**: If command invokes research-coordinator, list research-coordinator (not research-specialist, which is transitive)
  4. **Cleanup**: Update all commands to follow this pattern
- **Estimated Effort**: 2-3 hours (standards doc + command updates)
- **Success Criteria**: All commands have accurate, minimal dependent-agents lists

### Priority 3: Validate and Integrate Topic Detection

**Recommendation 8**: Add topic-detection-agent integration to /create-plan (optional enhancement)
- **Justification**: Original report Recommendation 9 (Phase 3) was implemented but never integrated. Automated topic detection enables research-coordinator without manual topic decomposition
- **Scope**:
  1. Add Block 1d-topics-auto: Topic Detection Agent Invocation (optional path)
  2. Invoke topic-detection-agent via Task tool (Haiku model, fast/cheap)
  3. Parse JSON output to get topics array
  4. Fall back to single-topic mode if detection fails (graceful degradation)
  5. Use detected topics as input to research-coordinator
- **Estimated Effort**: 4-5 hours (integration + testing)
- **Success Criteria**:
  - /create-plan can automatically decompose complex prompts into 2-5 topics
  - Fallback mode works for ambiguous prompts
  - Cost savings measured (Haiku vs Sonnet for topic analysis)

**Recommendation 9**: Create integration test for topic-detection-agent with /create-plan
- **Justification**: topic-detection-agent has unit tests (test_research_coordinator.sh) but no end-to-end integration tests with actual commands
- **Scope**: Add to `.claude/tests/integration/test_research_coordinator.sh`:
  1. Test case: Invoke /create-plan with complex multi-domain prompt
  2. Verify topic-detection-agent was invoked (check output for agent name)
  3. Verify JSON output created with 2-5 topics
  4. Verify research-coordinator received topics array
  5. Verify multiple reports created (one per topic)
- **Estimated Effort**: 2-3 hours (extend existing test suite)
- **Success Criteria**: End-to-end test validates topic detection → research coordination → multi-report creation

### Priority 4: Documentation Synchronization

**Recommendation 10**: Update hierarchical-agents-examples.md Example 7 with implementation status
- **Justification**: Current documentation (Finding 10) shows /lean-plan using research-coordinator, but implementation doesn't match. Add "Status: PLANNED" markers to prevent confusion
- **Scope**: Update `.claude/docs/concepts/hierarchical-agents-examples.md` lines 560-798:
  1. Add status marker: "Status: PLANNED (infrastructure complete, command integration pending)"
  2. Update command list to show which commands actually use research-coordinator vs which are planned
  3. Add troubleshooting note: "If you see this pattern documented but commands use research-specialist directly, see Phase 4 integration status"
- **Estimated Effort**: 1 hour (documentation update)
- **Success Criteria**: Documentation accurately reflects implementation status

**Recommendation 11**: Create migration guide for updating commands to use research-coordinator
- **Justification**: Phase 4 deferred work requires clear migration path for each command type
- **Scope**: Add `.claude/docs/guides/development/research-coordinator-migration-guide.md`:
  1. **Prerequisites**: What must be in place before migration (research-coordinator.md, topic-detection-agent.md)
  2. **Migration steps**: Detailed walkthrough for each command pattern (research-and-plan, research-only, debug, repair)
  3. **Testing checklist**: How to validate successful migration
  4. **Rollback procedure**: How to revert if migration fails
  5. **Case studies**: /create-plan migration as reference implementation
- **Estimated Effort**: 4-5 hours (comprehensive guide)
- **Success Criteria**: Command authors can migrate existing commands to research-coordinator pattern without spec 009 deep dive

### Priority 5: Quality Assurance and Measurement

**Recommendation 12**: Run integration test suite and document current status
- **Justification**: test_research_coordinator.sh exists but hasn't been run in production. Establish baseline before Phase 4 integration
- **Scope**:
  1. Execute: `bash .claude/tests/integration/test_research_coordinator.sh`
  2. Document results (pass/fail counts, any infrastructure issues)
  3. Fix any failing tests (likely due to path assumptions)
  4. Add test run to Phase 4 integration checklist
- **Estimated Effort**: 2-3 hours (run tests, fix issues, document)
- **Success Criteria**: All integration tests pass, baseline established

**Recommendation 13**: Add context reduction measurement to /create-plan (post-integration)
- **Justification**: Spec 009 promised 40-60% context reduction. Measure actual improvement after research-coordinator integration
- **Scope**: Add to /create-plan after research-coordinator integration:
  1. Measure baseline: Count tokens passed to plan-architect (full reports scenario)
  2. Measure coordinator: Count tokens passed to plan-architect (metadata-only scenario)
  3. Calculate reduction percentage
  4. Log to output: "Context reduction: X% (N tokens → M tokens)"
  5. Assert minimum reduction threshold (e.g., fail if <30% reduction)
- **Estimated Effort**: 2-3 hours (instrumentation)
- **Success Criteria**: Quantitative validation of context reduction claim

## References

- `/home/benjamin/.config/.claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md` (lines 1-506) - Implementation plan with Phase 4 [DEFERRED]
- `/home/benjamin/.config/.claude/specs/011_create_plan_research_coordinator/reports/001-i-want-the-create-plan-command-in-clau.md` (lines 1-258) - Original gap analysis and recommendations
- `/home/benjamin/.config/.claude/agents/research-coordinator.md` (lines 1-569) - Complete behavioral file (Phase 1 deliverable)
- `/home/benjamin/.config/.claude/agents/topic-detection-agent.md` (lines 1-523) - Complete behavioral file (Phase 3 deliverable)
- `/home/benjamin/.config/.claude/tests/integration/test_research_coordinator.sh` (lines 1-501) - Integration test suite (Phase 5 deliverable)
- `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-examples.md` (lines 560-798) - Example 7: Research Coordinator documentation (Phase 5 deliverable)
- `/home/benjamin/.config/.claude/commands/create-plan.md` (lines 1-1969) - Current /create-plan implementation (single-topic research)
- `/home/benjamin/.config/.claude/commands/lean-plan.md` - Current /lean-plan implementation (uses lean-research-specialist directly)
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-100) - Current /research implementation (single-topic research)
- `/home/benjamin/.config/CLAUDE.md` (lines 240-248) - Hierarchical agent architecture standards section
- `.claude/docs/reference/standards/command-authoring.md` - Command development patterns (missing research-coordinator template)
- `.claude/docs/reference/standards/command-reference.md` (lines 1-150) - Command catalog reference

## Appendices

### Appendix A: Phase 4 Task Checklist (Per Original Plan)

The following tasks from spec 009 Phase 4 remain incomplete:

- [ ] Integrate research-coordinator into /create-plan command (6-8 hours)
  - [ ] Add research phase blocks (1d-topics, 1d-exec, 1e)
  - [ ] Update plan-architect invocation to use report metadata
- [ ] Integrate research-coordinator into /repair command (8-10 hours)
  - [ ] Add error pattern research phase
  - [ ] Coordinate research across multiple error types
- [ ] Integrate research-coordinator into /debug command (8-10 hours)
  - [ ] Add issue investigation research phase
  - [ ] Coordinate research across codebase context
- [ ] Integrate research-coordinator into /revise command (8-10 hours)
  - [ ] Add context research phase before plan revision
  - [ ] Pass research findings to plan-architect revision
- [ ] Update command frontmatter for all modified commands (2 hours)
  - [ ] Add research-coordinator to dependent-agents
- [ ] Test each command integration independently (4-6 hours)

**Total Remaining Effort**: 40-56 hours (5-7 working days)

### Appendix B: Commands Requiring Research-Coordinator Integration

| Command | Current Pattern | Target Pattern | Priority | Estimated Effort |
|---------|----------------|----------------|----------|------------------|
| /create-plan | research-specialist (single) | research-coordinator (multi) | P0 | 6-8 hours |
| /research | research-specialist (single) | research-coordinator (multi) | P1 | 4-6 hours |
| /lean-plan | lean-research-specialist (single) | research-coordinator + lean-specialist (multi) | P1 | 6-8 hours |
| /repair | research-specialist (single) | research-coordinator (multi, error-focused) | P2 | 8-10 hours |
| /debug | research-specialist (single) | research-coordinator (multi, diagnostic-focused) | P2 | 8-10 hours |

**Total**: 5 commands, 32-42 hours estimated

### Appendix C: Documentation-Implementation Drift Analysis

| Documentation Claims | Implementation Reality | Status |
|---------------------|------------------------|--------|
| "research-coordinator.md exists" | ✓ Exists (569 lines) | MATCH |
| "/lean-plan integrates research-coordinator" | ✗ Uses lean-research-specialist directly | **MISMATCH** |
| "topic-detection-agent.md exists" | ✓ Exists (523 lines) | MATCH |
| "Commands use research-coordinator pattern" | ✗ Zero commands invoke it | **MISMATCH** |
| "Context reduction 40-60%" | Not measurable (not integrated) | **UNMEASURED** |
| "Parallel execution time savings" | Not measurable (not integrated) | **UNMEASURED** |
| "Example 7 shows /lean-plan using coordinator" | /lean-plan uses specialist directly | **MISMATCH** |

**Severity**: HIGH - Documentation describes completed features that are not implemented, creating onboarding confusion and maintenance risk.

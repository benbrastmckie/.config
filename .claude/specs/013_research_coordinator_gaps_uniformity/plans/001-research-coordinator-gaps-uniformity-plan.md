# Research Coordinator Gaps and Uniformity Implementation Plan

## Metadata
- **Date**: 2025-12-08 (Revised)
- **Feature**: Complete research-coordinator integration across ALL planning commands and implement advanced research features
- **Status**: [COMPLETE]
- **Estimated Hours**: 105-139 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Research Coordinator Gaps and Uniformity Analysis](../reports/001-research-coordinator-gaps-uniformity-analysis.md)
  - [Deferred Topics Analysis](../reports/002-deferred-topics-analysis.md)

## Overview

This plan addresses the critical gap between completed research-coordinator infrastructure (Phases 1-3, 5 from spec 009) and zero command integration. Research findings reveal that despite having complete infrastructure (research-coordinator.md, topic-detection-agent.md, integration tests, documentation), NO commands currently use the coordinator pattern. This creates 40-60% unrealized context reduction benefits and non-uniform research patterns across commands.

**Revision Note**: This plan has been expanded to include ALL deferred work from spec 009:
- Phase 4: Remaining command integration (/repair, /debug, /revise)
- Phase 6: Advanced Topic Detection (LLM clustering, interactive refinement, dependencies)
- Phase 7: Adaptive Research Depth (complexity allocation, dynamic specialists, iterative research)
- Phase 8: Cross-Command Research Sharing (cache, index, versioning)

## Research Summary

The gap analysis report identified 10 critical findings:

1. **Infrastructure Complete, Zero Usage** (Finding 1): research-coordinator.md, topic-detection-agent.md exist but no commands invoke them
2. **Original /create-plan Recommendations Not Implemented** (Finding 2): Report spec'd integration but Block 1e-exec still uses research-specialist directly
3. **/lean-plan Integration Incorrectly Marked COMPLETE** (Finding 3): Spec 009 Phase 2 marked [COMPLETE] but /lean-plan uses lean-research-specialist directly (documentation-implementation mismatch)
4. **Phase 4 Explicitly Deferred** (Finding 4): All 5 target commands (/create-plan, /lean-plan, /repair, /debug, /revise) remain unintegrated
5. **Non-Uniform Research Patterns** (Finding 5): Commands use inconsistent invocation patterns - some direct specialist, some specialized variants, research-sub-supervisor declared but never used
6. **Topic-Detection-Agent Implemented But Unused** (Finding 6): Haiku-based agent exists (cost-optimized) but no commands invoke it
7. **Hard Barrier Pattern Uniform (Success)** (Finding 7): All commands correctly implement path pre-calculation → Task invocation → validation
8. **Missing Topic Decomposition Block** (Finding 8): /create-plan lacks Block 1d-topics for multi-topic decomposition
9. **Research-Sub-Supervisor Dead Code** (Finding 9): Listed in dependent-agents but never invoked (symptom of Phase 4 deferral)
10. **Documentation-Implementation Drift** (Finding 10): Example 7 describes coordinator pattern but no commands actually use it

Recommended approach: Implement Phase 4 integration (deferred work) starting with /create-plan, establish research invocation standards, synchronize documentation, and measure context reduction benefits.

## Success Criteria

### Core Integration (Phases 1-9)
- [ ] /create-plan integrates research-coordinator with multi-topic decomposition
- [ ] /research integrates research-coordinator (simplest case validation)
- [ ] /lean-plan integration status verified and corrected
- [ ] Research invocation standards document created (when to use coordinator vs specialist)
- [ ] Command-authoring.md includes research-coordinator pattern templates
- [ ] Topic-detection-agent integrated into /create-plan (automated decomposition)
- [ ] Context reduction measured and documented (target 40-60%)
- [ ] Documentation synchronized with implementation reality
- [ ] All integration tests pass
- [ ] Dependent-agents declarations standardized across commands

### Extended Integration (Phases 10-12)
- [ ] /repair integrates research-coordinator with error pattern topic decomposition
- [ ] /debug integrates research-coordinator with root cause analysis topic decomposition
- [ ] /revise integrates research-coordinator with revision context topic decomposition
- [ ] All three commands pass multi-topic integration tests

### Research Infrastructure (Phases 13-14)
- [ ] Research cache implemented with TTL-based expiration
- [ ] Research index implemented with topic search capability
- [ ] Cache hit/miss metrics logged for performance measurement
- [ ] Index populated for all new research reports

### Advanced Features (Phases 15-17)
- [ ] LLM-based semantic topic clustering implemented (Phase 15a)
- [ ] User-interactive topic refinement (--confirm flag) implemented (Phase 15b)
- [ ] Topic dependency tracking with sequential execution implemented (Phase 15c)
- [ ] Complexity-based research allocation enhanced (Phase 16a)
- [ ] Dynamic research-specialist selection framework documented (Phase 16b)
- [ ] Iterative research capability (max 2 iterations) implemented (Phase 16c)
- [ ] Research versioning with staleness tracking implemented (Phase 17)

## Technical Design

### Architecture Overview

```
Planning Command (e.g., /create-plan)
    |
    +-- topic-detection-agent (Haiku, optional auto-decomposition)
    |       |
    |       +-- OUTPUT: topics.json (2-5 topics)
    |
    +-- research-coordinator (Sonnet 4.5, supervisor)
            |
            +-- research-specialist 1 (Topic 1)
            +-- research-specialist 2 (Topic 2)
            +-- research-specialist 3 (Topic 3)
            |
            +-- OUTPUT: metadata.json (110 tokens/report)
    |
    +-- plan-architect (receives report paths + metadata, not full content)
```

### Component Integration Points

**1. Topic Decomposition Block** (New to /create-plan, /research):
- **Location**: Insert Block 1d-topics after current Block 1d (topic path initialization)
- **Responsibilities**:
  - Analyze FEATURE_DESCRIPTION for multi-topic indicators (conjunctions, domain keywords)
  - Use RESEARCH_COMPLEXITY to determine topic count (1-2 → 1 topic, 3 → 2-3 topics, 4 → 4-5 topics)
  - Optionally invoke topic-detection-agent for automated decomposition (Haiku model)
  - Pre-calculate report paths for each topic: `${RESEARCH_DIR}/001-topic1.md`, `${RESEARCH_DIR}/002-topic2.md`, etc.
  - Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file
  - Fall back to single topic if decomposition fails (backward compatibility)

**2. Research Coordinator Invocation** (Replaces current research-specialist invocation):
- **Location**: Modify Block 1e-exec in /create-plan, /research
- **Pattern Change**:
  - **OLD**: Direct research-specialist invocation with single FEATURE_DESCRIPTION
  - **NEW**: research-coordinator invocation with TOPICS_ARRAY and REPORT_PATHS_ARRAY
- **Contract**:
  ```yaml
  research_request: "${FEATURE_DESCRIPTION}"
  research_complexity: ${RESEARCH_COMPLEXITY}
  report_dir: ${RESEARCH_DIR}
  topics: ["Topic 1", "Topic 2", "Topic 3"]
  report_paths: ["/path/001.md", "/path/002.md", "/path/003.md"]
  ```

**3. Multi-Report Validation** (Extends current Block 1f):
- **Location**: Update Block 1f (research output verification) in /create-plan, /research
- **Changes**:
  - Loop through REPORT_PATHS_ARRAY (not single REPORT_PATH)
  - Validate each report with validate_agent_artifact (file exists, size >100 bytes)
  - Fail-fast if any report missing (hard barrier enforcement)
  - Extract metadata from each report (title, findings count, recommendations count)
  - Aggregate metadata for passing to plan-architect

**4. Metadata-Only Context Passing** (Updates plan-architect invocation):
- **Location**: Block 2 (planning phase) in /create-plan
- **Changes**:
  - Pass REPORT_PATHS_ARRAY to plan-architect (not full content)
  - Include aggregated metadata summary (110 tokens per report format)
  - plan-architect reads reports as needed (receives paths)

### Standards Compliance

**Code Standards**:
- Three-tier bash sourcing pattern (error-handling, state-persistence, workflow-state-machine)
- Task invocations use imperative directives: "**EXECUTE NOW**: USE the Task tool..."
- Path validation handles PROJECT_DIR under HOME as valid

**Hierarchical Agent Architecture**:
- research-coordinator fits supervisor role
- topic-detection-agent fits lightweight analysis role (Haiku model)
- Metadata-only context passing (110 tokens per report vs 2,500 full content)

**Hard Barrier Pattern**:
- Pre-calculate paths BEFORE agent invocation (already implemented)
- Validate artifacts AFTER agent returns (extend to multi-report)
- Fail-fast on missing artifacts (maintain existing behavior)

**Error Logging**:
- Use log_command_error() for all error conditions
- Error types: agent_error, validation_error, state_error
- Parse subagent errors with parse_subagent_error()

**Output Formatting**:
- Target 2-3 bash blocks per command (Setup/Execute/Cleanup)
- Single summary line per block for interim output
- Console summaries use 4-section format (Summary/Phases/Artifacts/Next Steps)

### Research Invocation Standards (New)

**Decision Matrix** (when to use which pattern):

| Scenario | RESEARCH_COMPLEXITY | Prompt Structure | Pattern | Agent |
|----------|---------------------|------------------|---------|-------|
| Simple, focused request | 1-2 | Single domain | Direct invocation | research-specialist |
| Complex, multi-domain | 3 | 2-3 topics identifiable | Coordinator | research-coordinator |
| Comprehensive analysis | 4 | 4-5 topics required | Coordinator + sub-supervisor | research-coordinator |
| Lean-specific research | Any | Lean/Mathlib context | Specialized direct | lean-research-specialist |

**Uniformity Rules**:
1. **Single-topic**: Use research-specialist directly (no coordinator overhead)
2. **Multi-topic**: Always use research-coordinator (enables parallelization)
3. **Automated decomposition**: Use topic-detection-agent when complexity ≥ 3 (optional but recommended)
4. **Dependent-agents**: List only directly invoked agents (research-coordinator implies research-specialist)

## Implementation Phases

### Phase 1: Integrate research-coordinator into /create-plan [COMPLETE]
dependencies: []

**Objective**: Implement research-coordinator integration for /create-plan following original report specification (Recommendations 1-4)

**Complexity**: High

**Tasks**:
- [x] Add Block 1d-topics: Topic Decomposition bash block
  - Analyze FEATURE_DESCRIPTION for multi-topic indicators
  - Use RESEARCH_COMPLEXITY to determine topic count (1 → 1 topic, 2 → 1-2 topics, 3 → 2-3 topics, 4 → 4-5 topics)
  - Implement heuristic-based decomposition (conjunction detection, domain keyword clustering)
  - Pre-calculate report paths for each topic (001-topic1.md, 002-topic2.md, etc.)
  - Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file using save_state
  - Fall back to single topic if decomposition unclear (backward compatibility)
- [x] Replace Block 1e-exec research-specialist invocation with research-coordinator
  - Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
  - Pass research_request, research_complexity, report_dir, topics array, report_paths array as contract
  - Include FEATURE_DESCRIPTION and RESEARCH_DIR in context
- [x] Update Block 1f validation to handle multiple reports (multi-report hard barrier)
  - Loop through REPORT_PATHS_ARRAY and validate each report with validate_agent_artifact
  - Fail-fast if any report missing (maintain hard barrier pattern)
  - Extract metadata from each report using Read tool (title, findings count, recommendations count)
  - Persist aggregated metadata to state file
- [x] Update Block 2: Planning Phase Integration
  - Pass report paths to plan-architect (not full content)
  - Include aggregated metadata summary in plan-architect prompt
  - Remove any inline report content passing (metadata-only pattern)
- [x] Update /create-plan frontmatter dependent-agents field
  - Add research-coordinator to dependency list
  - Remove research-sub-supervisor (not directly invoked, transitive dependency)
  - Maintain plan-architect dependency

**Testing**:
```bash
# Test /create-plan with multi-topic scenario
/create-plan "Implement OAuth2 authentication with session management and password security" --complexity 3

# Verify research-coordinator was invoked
grep "research-coordinator" .claude/output/create-plan-output.md

# Verify multiple reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
# Should be ≥2 reports

# Verify plan-architect received report paths (not full content)
grep "Research Reports:" .claude/specs/*/plans/*.md

# Verify hard barrier validation works (simulate missing report)
rm .claude/specs/*/reports/002*.md
/create-plan "Test feature" --complexity 3
# Should fail with "HARD BARRIER FAILED" error
```

**Expected Duration**: 8-10 hours

### Phase 2: Integrate topic-detection-agent into /create-plan [COMPLETE]
dependencies: [1]

**Objective**: Add automated topic decomposition using topic-detection-agent for complexity ≥ 3

**Complexity**: Medium

**Tasks**:
- [x] Add Block 1d-topics-auto: Topic Detection Agent Invocation (optional path)
  - Check if RESEARCH_COMPLEXITY ≥ 3 (threshold for automated decomposition)
  - Pre-calculate topics JSON output path: `${TOPIC_PATH}/tmp/topics_${TIMESTAMP}.json`
  - Invoke topic-detection-agent via Task tool (Haiku model, fast/cheap)
  - Pass FEATURE_DESCRIPTION, RESEARCH_COMPLEXITY, OUTPUT_PATH as contract
  - Validate JSON output file exists using validate_agent_artifact
- [x] Parse topic-detection-agent JSON output
  - Read JSON file using Read tool or bash jq parsing
  - Extract topics array (2-5 topics expected)
  - Extract scope descriptions for each topic
  - Fall back to single-topic mode if JSON parsing fails (graceful degradation)
- [x] Use detected topics as input to research-coordinator
  - Replace heuristic-based decomposition with topic-detection-agent output when available
  - Pre-calculate report paths using detected topic names (slugified)
  - Persist detected topics to state file for debugging
- [x] Add error handling for topic-detection failures
  - Log detection failures with log_command_error (error_type: "agent_error")
  - Fall back to heuristic decomposition (Phase 1 logic)
  - Continue workflow without blocking (degraded mode)
- [x] Update /create-plan frontmatter to include topic-detection-agent
  - Add topic-detection-agent to dependent-agents field
  - Document in command that topic detection is optional for complexity ≥ 3

**Testing**:
```bash
# Test automated topic detection
/create-plan "Formalize group homomorphism theorems with automated proof tactics and project organization" --complexity 3

# Verify topic-detection-agent was invoked
grep "topic-detection-agent" .claude/output/create-plan-output.md

# Verify JSON output created
ls .claude/specs/*/tmp/topics_*.json

# Verify topics array parsed correctly (3 topics expected)
cat .claude/specs/*/tmp/topics_*.json | jq '.topics | length'
# Should return 3

# Test fallback behavior (ambiguous prompt)
/create-plan "Fix bug" --complexity 3
# Should fall back to single topic

# Test cost savings (Haiku vs Sonnet for topic analysis)
# Compare token usage before/after topic-detection integration
```

**Expected Duration**: 5-6 hours

### Phase 3: Integrate research-coordinator into /research [COMPLETE]
dependencies: [1]

**Objective**: Integrate research-coordinator into /research command (simplest case for pattern validation)

**Complexity**: Medium

**Tasks**:
- [x] Add topic decomposition logic to /research command
  - Research request is provided as single argument (not FEATURE_DESCRIPTION)
  - Analyze research request for multi-topic indicators
  - Use --complexity flag if provided (default: 3 for research workflows)
  - Pre-calculate report paths for each topic
- [x] Replace research-specialist direct invocation with research-coordinator
  - Identify current research-specialist invocation block in /research command
  - Replace with research-coordinator Task invocation
  - Pass topics array and report paths as contract
  - Maintain hard barrier pattern (path pre-calculation → validation)
- [x] Update /research validation to handle multiple reports
  - Loop through report paths for validation
  - Fail-fast if any report missing
  - Extract metadata from reports (title, key findings)
  - Return aggregated metadata to terminal state (no plan-architect in /research)
- [x] Update /research frontmatter dependent-agents
  - Add research-coordinator
  - Remove research-sub-supervisor (unused, transitive dependency)
- [x] Test /research with multi-topic scenario
  - Create test case with 3-topic research request
  - Verify parallel execution (time measurement)
  - Verify metadata-only context passing to terminal state

**Testing**:
```bash
# Test /research with multi-topic request
/research "Investigate Lean 4 tactics for automation, Mathlib theorem structure, and project organization patterns" --complexity 3

# Verify research-coordinator was invoked
grep "research-coordinator" .claude/output/research-output.md

# Verify multiple reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
# Should be ≥2 reports

# Measure parallel execution time savings
time /research "Multi-topic request..." --complexity 3
# Compare to baseline sequential research time

# Verify metadata format in terminal output
grep "Context tokens:" .claude/output/research-output.md
# Should show ~500 tokens (metadata) vs ~10,000 (full content)
```

**Expected Duration**: 6-8 hours

### Phase 4: Verify /lean-plan Integration Status [COMPLETE]
dependencies: []

**Objective**: Investigate /lean-plan research-coordinator integration status and correct spec 009 Phase 2 documentation

**Complexity**: Low (investigation) → High (integration if needed)

**Tasks**:
- [x] Inspect /lean-plan command for research-coordinator usage
  - Search for research-coordinator invocation blocks
  - Identify current research pattern (lean-research-specialist directly)
  - Document actual implementation vs spec 009 Phase 2 claims
- [x] Update spec 009 Phase 2 status if mismatch found
  - If not integrated: Change status from [COMPLETE] to [NOT STARTED]
  - Document discrepancy in spec 009 Notes section
  - Create follow-up task for /lean-plan integration
- [x] If integration needed, plan /lean-plan research-coordinator integration
  - Determine if lean-specific topic decomposition logic required
  - Identify integration with lean-research-specialist (coordinator invokes specialist, not primary agent)
  - Plan multi-topic research for Lean context (Mathlib theorems, proof patterns, project structure)
- [x] Update hierarchical-agents-examples.md Example 7 status
  - Add status marker: "Status: PLANNED (infrastructure complete, command integration pending)"
  - Clarify which commands actually use coordinator vs documented examples
- [x] Document /lean-plan integration requirements for future Phase 6 work
  - Lean-specific topic detection patterns (theorem research, tactic research, structure research)
  - Integration point between research-coordinator and lean-research-specialist
  - Hard barrier pattern for Lean context validation

**Testing**:
```bash
# Verify current /lean-plan implementation
grep "research-coordinator\|lean-research-specialist" .claude/commands/lean-plan.md

# Check spec 009 Phase 2 status
grep "Phase 2.*\[COMPLETE\]" .claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md

# Verify Example 7 claims vs implementation
diff <(grep -A 20 "Example 7" .claude/docs/concepts/hierarchical-agents-examples.md) \
     <(grep -A 10 "dependent-agents" .claude/commands/lean-plan.md)
```

**Expected Duration**: 3-4 hours (investigation) + 8-10 hours (integration if needed, defer to Phase 6)

### Phase 5: Create Research Invocation Standards Document [COMPLETE]
dependencies: [1, 3]

**Objective**: Establish uniformity standards for when to use research-coordinator vs research-specialist directly

**Complexity**: Low

**Tasks**:
- [x] Create `.claude/docs/reference/standards/research-invocation-standards.md`
  - Document decision matrix (complexity × prompt structure → pattern)
  - Specify when to use research-coordinator vs research-specialist directly
  - Define specialized research patterns (lean-research-specialist, etc.)
  - Document dependent-agents declaration rules (direct vs transitive)
- [x] Add standards sections:
  - **Single-Topic Research**: When to use research-specialist directly (complexity 1-2, focused prompts)
  - **Multi-Topic Research**: When to use research-coordinator (complexity 3-4, broad prompts)
  - **Automated Decomposition**: When to use topic-detection-agent (complexity ≥ 3, cost-benefit analysis)
  - **Specialized Research**: When to use domain-specific specialists (lean-research-specialist for Lean projects)
  - **Migration Path**: How to update existing commands from direct to coordinator pattern
- [x] Document uniformity requirements
  - All commands with complexity ≥ 3 SHOULD use research-coordinator
  - All commands MUST use hard barrier pattern (already uniform)
  - Dependent-agents lists MUST include only directly invoked agents
  - Research-sub-supervisor is transitive dependency (not listed unless directly invoked)
- [x] Add decision tree flowchart using Unicode box-drawing
  - Start: "Does prompt require research?"
  - Branch: "RESEARCH_COMPLEXITY < 3?" → Yes: direct specialist, No: coordinator
  - Branch: "Complexity ≥ 3?" → Yes: consider topic-detection-agent
  - Branch: "Domain-specific?" → Yes: specialized specialist (lean-research-specialist)
- [x] Add CLAUDE.md section reference for research invocation standards
  - Add standards section to CLAUDE.md with link to research-invocation-standards.md
  - Include quick reference table in CLAUDE.md

**Testing**:
```bash
# Validate documentation structure
bash .claude/scripts/validate-readmes.sh .claude/docs/reference/standards/research-invocation-standards.md

# Verify link validity
bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/research-invocation-standards.md

# Check CLAUDE.md section reference added
grep "research_invocation_standards" CLAUDE.md
```

**Expected Duration**: 4-5 hours

### Phase 6: Update Command-Authoring Standards with Coordinator Pattern [COMPLETE]
dependencies: [5]

**Objective**: Add research-coordinator integration patterns to command-authoring.md and command-patterns-quick-reference.md

**Complexity**: Low

**Tasks**:
- [x] Add "Research Coordinator Delegation Pattern" section to command-authoring.md
  - Document pattern structure (topic decomposition → coordinator invocation → multi-report validation)
  - Include imperative directive requirement for Task tool invocations
  - Document hard barrier pattern enforcement for multi-report scenarios
  - Reference research-invocation-standards.md for when to use pattern
- [x] Add copy-paste templates to command-patterns-quick-reference.md
  - Template 1: Topic Decomposition Block (heuristic-based)
  - Template 2: Topic Detection Agent Invocation Block (automated)
  - Template 3: Research Coordinator Task Invocation Block
  - Template 4: Multi-Report Validation Loop
  - Template 5: Metadata Extraction and Aggregation
- [x] Document integration points with existing patterns
  - How topic decomposition integrates with state persistence (save_state for TOPICS_ARRAY)
  - How multi-report validation extends hard barrier pattern
  - How metadata passing integrates with agent delegation pattern
- [x] Add troubleshooting section for common integration issues
  - Topic decomposition returns empty array (fallback behavior)
  - topic-detection-agent fails (graceful degradation)
  - research-coordinator reports missing (hard barrier fail-fast)
  - Metadata extraction parsing errors (use filename fallback)
- [x] Update command-authoring.md frontmatter and navigation
  - Add research-coordinator pattern to table of contents
  - Link to research-invocation-standards.md for decision guidance
  - Link to hierarchical-agents-examples.md Example 7 for detailed example

**Testing**:
```bash
# Verify templates are syntactically correct bash
for template in $(grep -A 20 "^### Template" .claude/docs/reference/command-patterns-quick-reference.md | grep -E "^\`\`\`bash" -A 10 | grep -v "^\`\`\`"); do
  echo "$template" | bash -n
done

# Validate link consistency
bash .claude/scripts/validate-links-quick.sh .claude/docs/reference/standards/command-authoring.md

# Check template completeness (all 5 templates documented)
grep -c "^### Template" .claude/docs/reference/command-patterns-quick-reference.md
# Should return ≥5
```

**Expected Duration**: 3-4 hours

### Phase 7: Synchronize Documentation with Implementation [COMPLETE]
dependencies: [1, 3, 4]

**Objective**: Update documentation to accurately reflect implementation status and prevent documentation-implementation drift

**Complexity**: Low

**Tasks**:
- [x] Update hierarchical-agents-examples.md Example 7 status markers
  - Add status: "Status: IMPLEMENTED (as of 2025-12-08)"
  - Update command list to show actual integration status (/create-plan: ✓, /research: ✓, /lean-plan: planned)
  - Add troubleshooting note referencing research-invocation-standards.md
- [x] Create research-coordinator migration guide
  - Add `.claude/docs/guides/development/research-coordinator-migration-guide.md`
  - Document prerequisites (research-coordinator.md, topic-detection-agent.md)
  - Provide step-by-step migration walkthrough for each command pattern
  - Include testing checklist and validation steps
  - Document rollback procedure for failed migrations
  - Add /create-plan as reference implementation case study
- [x] Update CLAUDE.md hierarchical_agent_architecture section
  - Reference research-coordinator as Example 7 (update status to IMPLEMENTED)
  - Document metadata-only context passing benefits (95% reduction)
  - Add quick reference to research-invocation-standards.md
- [x] Add troubleshooting entries to hierarchical-agents-troubleshooting.md
  - Missing reports diagnostic (hard barrier failure)
  - Path mismatch diagnostic (absolute path validation)
  - Metadata extraction errors (fallback to filename)
  - Topic detection failures (graceful degradation)
  - Parallel execution timeout (research-specialist workers hang)
- [x] Audit all documentation for coordinator pattern references
  - Search for "research-coordinator" across .claude/docs/
  - Verify all references accurate (no PLANNED markers for implemented features)
  - Update outdated examples or claims

**Testing**:
```bash
# Verify Example 7 status updated
grep "Status: IMPLEMENTED" .claude/docs/concepts/hierarchical-agents-examples.md

# Validate migration guide structure
bash .claude/scripts/validate-readmes.sh .claude/docs/guides/development/research-coordinator-migration-guide.md

# Check for documentation drift (search for incorrect status markers)
grep -r "Status: PLANNED.*research-coordinator" .claude/docs/ && echo "ERROR: Found PLANNED markers after implementation"

# Validate all links in updated documentation
bash .claude/scripts/validate-links-quick.sh .claude/docs/
```

**Expected Duration**: 4-5 hours

### Phase 8: Integration Testing and Measurement [COMPLETE]
dependencies: [1, 2, 3, 7]

**Objective**: Run integration tests, measure context reduction, and validate performance claims

**Complexity**: Medium

**Tasks**:
- [x] Run existing integration test suite
  - Execute: `bash .claude/tests/integration/test_research_coordinator.sh`
  - Document results (pass/fail counts, errors)
  - Fix any failing tests (likely path assumptions or environment issues)
  - Verify all test cases pass
- [x] Add context reduction measurement to /create-plan
  - Instrument plan-architect invocation to count tokens passed
  - Measure baseline: Full report content scenario (hypothetical)
  - Measure coordinator: Metadata-only scenario (actual)
  - Calculate reduction percentage: (baseline - coordinator) / baseline × 100
  - Log to output: "Context reduction: X% (N tokens → M tokens)"
  - Assert minimum reduction threshold (fail if <30% reduction)
- [x] Add parallel execution time measurement
  - Instrument research-coordinator invocation block
  - Measure time for parallel research (3 topics)
  - Compare to baseline sequential research time (estimated)
  - Calculate time savings percentage
  - Log to output: "Time savings: X% (N seconds → M seconds)"
- [x] Create end-to-end integration test for /create-plan
  - Test case: Complex multi-domain feature requiring 3 topics
  - Verify topic-detection-agent invoked and returned 3 topics
  - Verify research-coordinator invoked with 3 topic inputs
  - Verify 3 research reports created in parallel
  - Verify plan-architect received report paths (not full content)
  - Verify plan quality (ensure metadata-only input doesn't degrade planning)
- [x] Test fallback and error scenarios
  - Test single-topic fallback (complexity 1-2)
  - Test topic-detection failure (malformed JSON)
  - Test missing report (hard barrier validation)
  - Test metadata extraction failure (malformed report)
  - Verify graceful degradation in all cases
- [x] Document test results and performance metrics
  - Add test results to spec 013 deliverables
  - Document context reduction measurements (target 40-60% achieved)
  - Document parallel execution time savings (target 40-60% achieved)
  - Update spec 009 with actual performance metrics

**Testing**:
```bash
# Run full integration test suite
bash .claude/tests/integration/test_research_coordinator.sh

# Measure context reduction for /create-plan
/create-plan "Complex multi-domain feature..." --complexity 3
grep "Context reduction:" .claude/output/create-plan-output.md
# Should show ≥40% reduction

# Measure parallel execution time
time /create-plan "Feature requiring 3 topics..." --complexity 3
# Compare to baseline (estimate 3× single-topic time)

# Test fallback scenarios
/create-plan "Simple feature" --complexity 1
# Should use research-specialist directly, not coordinator

# Test error handling
# (simulate missing report by removing file mid-execution)
# Should fail with "HARD BARRIER FAILED" error
```

**Expected Duration**: 6-8 hours

### Phase 9: Standardize Dependent-Agents Declarations [COMPLETE]
dependencies: [1, 3, 5]

**Objective**: Update all commands to follow consistent dependent-agents declaration rules

**Complexity**: Low

**Tasks**:
- [x] Define dependent-agents standards in research-invocation-standards.md
  - **Required**: All agents directly invoked by command via Task tool
  - **Transitive**: Agents invoked by sub-agents (NOT listed in primary command)
  - **Rule**: If command invokes research-coordinator, list research-coordinator (not research-specialist)
  - **Example**: /create-plan invokes research-coordinator → list research-coordinator, plan-architect (NOT research-specialist, research-sub-supervisor)
- [x] Audit all command frontmatter for dependent-agents accuracy
  - List all commands with dependent-agents field
  - For each command, verify agents listed match actual Task invocations
  - Identify commands with incorrect transitive dependencies (research-sub-supervisor)
- [x] Update /create-plan frontmatter (post-Phase 1 integration)
  - Remove research-specialist (transitive, invoked by research-coordinator)
  - Remove research-sub-supervisor (transitive, invoked by research-coordinator when topic count ≥4)
  - Keep research-coordinator (directly invoked)
  - Keep topic-detection-agent (directly invoked, optional)
  - Keep plan-architect (directly invoked)
- [x] Update /research frontmatter (post-Phase 3 integration)
  - Remove research-specialist (transitive)
  - Remove research-sub-supervisor (transitive)
  - Add research-coordinator (directly invoked)
- [x] Update /lean-plan frontmatter (if Phase 4 integration completed)
  - Add research-coordinator if integrated
  - Keep lean-research-specialist (may be invoked by coordinator, not directly)
- [x] Document dependent-agents cleanup in migration guide
  - Add section: "Updating Dependent-Agents After Integration"
  - Provide before/after examples for common command types
  - Reference standards for decision guidance

**Testing**:
```bash
# Verify /create-plan dependent-agents updated
grep -A 5 "^dependent-agents:" .claude/commands/create-plan.md
# Should list: research-coordinator, topic-detection-agent, plan-architect
# Should NOT list: research-specialist, research-sub-supervisor

# Verify /research dependent-agents updated
grep -A 5 "^dependent-agents:" .claude/commands/research.md
# Should list: research-coordinator
# Should NOT list: research-specialist, research-sub-supervisor

# Audit all commands for transitive dependency issues
grep -r "research-sub-supervisor" .claude/commands/*.md
# Should only appear in research-coordinator.md (its dependent-agents field)
```

**Expected Duration**: 2-3 hours

## Testing Strategy

### Unit Testing
- Test topic decomposition heuristics (conjunction detection, domain keyword clustering)
- Test topic-detection-agent JSON output parsing and validation
- Test multi-report validation loop (hard barrier enforcement)
- Test metadata extraction from reports (title, findings, recommendations parsing)
- Test fallback behaviors (single-topic mode, detection failure, missing reports)

### Integration Testing
- Test /create-plan end-to-end with multi-topic scenario (3 topics)
- Test /research end-to-end with multi-topic scenario (2-3 topics)
- Test topic-detection-agent → research-coordinator → plan-architect pipeline
- Test hard barrier validation (simulate missing reports, verify fail-fast)
- Test metadata-only context passing (verify plan quality maintained)

### Performance Testing
- Measure context reduction: Compare /create-plan token usage before/after integration
  - Baseline: Hypothetical full report content passed to plan-architect
  - Target: 40-60% reduction with metadata-only passing
- Measure execution time: Parallel vs sequential research
  - Baseline: Sequential research-specialist invocations (3× single-topic time)
  - Target: 40-60% time reduction with parallel execution

### Regression Testing
- Verify /create-plan backward compatibility (single-topic scenarios, complexity 1-2)
- Verify research-specialist behavioral file unchanged (no breaking changes)
- Verify plan-architect behavioral file unchanged (receives paths, reads as needed)
- Verify existing /create-plan tests pass (if any)
- Verify hard barrier pattern still enforced (fail-fast on missing artifacts)

### Coverage Requirements
- 100% coverage of hard barrier validation paths (file exists, size checks, multi-report loop)
- 100% coverage of metadata extraction logic (title, findings, recommendations parsing)
- 100% coverage of fallback paths (single-topic mode, detection failure, parsing errors)
- 100% coverage of error logging integration (log_command_error calls for all error types)

## Documentation Requirements

### Standards Documentation
- `.claude/docs/reference/standards/research-invocation-standards.md` - When to use coordinator vs specialist
- `.claude/docs/reference/standards/command-authoring.md` - Add research-coordinator delegation pattern section
- `.claude/docs/reference/command-patterns-quick-reference.md` - Add 5 copy-paste templates for coordinator integration

### Migration Documentation
- `.claude/docs/guides/development/research-coordinator-migration-guide.md` - Step-by-step migration walkthrough with rollback procedure

### Pattern Documentation
- `.claude/docs/concepts/hierarchical-agents-examples.md` - Update Example 7 status to IMPLEMENTED
- `.claude/docs/concepts/hierarchical-agents-troubleshooting.md` - Add coordinator-specific troubleshooting entries

### Reference Documentation
- `CLAUDE.md` - Update hierarchical_agent_architecture section with research-coordinator status
- `.claude/docs/reference/standards/command-reference.md` - Document dependent-agents changes

## Dependencies

### External Dependencies
- None (uses existing research-specialist, research-coordinator, topic-detection-agent)

### Internal Dependencies
- research-coordinator.md (exists, Phase 1 deliverable from spec 009)
- topic-detection-agent.md (exists, Phase 3 deliverable from spec 009)
- research-specialist.md (exists, unchanged - receives paths from coordinator)
- plan-architect.md (exists, unchanged - receives paths and reads as needed)
- Hard barrier pattern infrastructure (path pre-calculation, validate_agent_artifact)
- State persistence library (save_state, load_state for TOPICS_ARRAY)
- Error logging library (log_command_error, parse_subagent_error)

### Standards Dependencies
- CLAUDE.md hierarchical_agent_architecture section
- CLAUDE.md error_logging section
- CLAUDE.md code_standards section (three-tier sourcing, Task invocation patterns)
- CLAUDE.md output_formatting section (checkpoint format, console summaries)

## Risk Assessment

### Technical Risks

**Risk 1: Topic decomposition inaccuracy**
- **Impact**: research-coordinator receives poorly scoped topics, research quality degrades
- **Mitigation**: Implement fallback to single-topic mode, allow manual topic specification via --topics flag, validate topic-detection-agent output
- **Severity**: Low (fallback ensures functionality)

**Risk 2: Parallel execution failures**
- **Impact**: One research-specialist fails, blocking entire research phase
- **Mitigation**: Implement partial success mode (coordinator continues if ≥50% reports succeed), log failed topics for retry, hard barrier validation ensures minimum viable output
- **Severity**: Medium (affects user experience but fail-fast prevents invalid plans)

**Risk 3: Metadata extraction parsing errors**
- **Impact**: Coordinator cannot extract metadata from malformed reports, plan quality degrades
- **Mitigation**: Add graceful degradation (use filename as title fallback), validate report structure before extraction, log parsing errors for debugging
- **Severity**: Low (degrades to basic functionality)

**Risk 4: Plan quality regression with metadata-only input**
- **Impact**: plan-architect receives less context, produces lower-quality plans
- **Mitigation**: plan-architect reads full reports as needed (receives paths), verify plan quality in Phase 8 testing, rollback if quality degrades
- **Severity**: Medium (affects deliverable quality, measure in testing)

**Risk 5: Breaking changes to /create-plan**
- **Impact**: Existing workflows fail after integration, users experience downtime
- **Mitigation**: Maintain backward compatibility (single-topic fallback for complexity 1-2), comprehensive regression testing, rollback plan if integration fails
- **Severity**: High (breaks existing users, mitigated by testing and fallback)

### Integration Risks

**Risk 6: /lean-plan integration complexity**
- **Impact**: Lean-specific topic decomposition differs from general pattern, integration more complex than expected
- **Mitigation**: Defer /lean-plan integration to Phase 6 (future work), validate pattern with /create-plan and /research first
- **Severity**: Low (can be deferred)

**Risk 7: Documentation-implementation drift persists**
- **Impact**: Documentation claims features not implemented, onboarding confusion continues
- **Mitigation**: Phase 7 dedicated to synchronization, add implementation status markers to all coordinator references, validate documentation in Phase 8
- **Severity**: Medium (affects developer experience, addressed by Phase 7)

### Timeline Risks

**Risk 8: Phase 1 integration exceeds estimate (8-10 hours)**
- **Impact**: /create-plan integration takes longer, delays subsequent phases
- **Mitigation**: Phase 1 is highest priority, allocate buffer time, defer Phase 4 (/lean-plan) if needed
- **Severity**: Medium (can adjust schedule)

**Risk 9: Performance benefits don't meet targets (40-60% reduction)**
- **Impact**: Context reduction or time savings below expectations, ROI questioned
- **Mitigation**: Measure in Phase 8 testing, document actual metrics, adjust expectations if needed, benefits still positive even if below target
- **Severity**: Low (benefits likely positive regardless)

## Migration Strategy

### Phased Rollout Approach

**Phase 1-2**: /create-plan integration (Priority 0)
- Highest-value target (general-purpose planning)
- Original report provided detailed integration plan
- Complexity well-understood
- Enables topic-detection-agent validation

**Phase 3**: /research integration (Priority 1)
- Simplest case (research-only workflow, no planning phase)
- Validates coordinator pattern before complex integrations
- Provides baseline performance metrics

**Phase 4**: /lean-plan investigation (Priority 1, defer integration to Phase 6)
- Verify spec 009 Phase 2 status accuracy
- Document integration requirements for future work
- Defer actual integration until /create-plan and /research validated

**Phase 5-7**: Standards and documentation (Priority 2)
- Establish uniformity standards
- Synchronize documentation with implementation
- Enable future command migrations

**Phase 8-9**: Testing and cleanup (Priority 3)
- Measure performance benefits
- Standardize dependent-agents declarations
- Validate all integration tests pass

### Rollback Plan

If research-coordinator integration causes failures:

1. **Immediate Rollback** (/create-plan):
   - Revert /create-plan command to git HEAD (before Phase 1 changes)
   - Preserve research-coordinator.md and topic-detection-agent.md for future use
   - Document failure mode in research-coordinator troubleshooting
   - Re-evaluate approach with hybrid pattern (optional --use-coordinator flag)

2. **Partial Rollback** (specific phases):
   - Phase 2 (topic-detection): Disable automated detection, use heuristic decomposition only
   - Phase 3 (/research): Revert /research, keep /create-plan integration if successful
   - Phase 8 (measurements): Remove instrumentation if performance overhead detected

3. **Documentation Rollback**:
   - Restore documentation status markers to PLANNED (Phase 7 changes)
   - Update hierarchical-agents-examples.md to reflect actual status
   - Document lessons learned in troubleshooting guide

### Validation Gates

Each phase has validation gates that must pass before proceeding:

**Phase 1 Gate**: /create-plan integration test passes
- Multi-topic scenario creates ≥2 reports
- Hard barrier validation works (fail-fast on missing reports)
- Plan-architect receives report paths and produces valid plan

**Phase 2 Gate**: topic-detection-agent integration test passes
- Automated decomposition works for complexity ≥3
- Fallback to heuristic decomposition works if detection fails
- JSON parsing handles malformed output gracefully

**Phase 3 Gate**: /research integration test passes
- Multi-topic research scenario creates ≥2 reports
- Metadata-only context passing works for terminal state
- Parallel execution time savings measured (any improvement acceptable)

**Phase 8 Gate**: Performance targets validated
- Context reduction ≥30% measured (relaxed from 40-60% target)
- Parallel execution time savings >0% measured (any improvement acceptable)
- Integration tests pass with 100% coverage

**Phase 10-12 Gate**: Extended command integration validated
- /repair multi-topic research works with error filters
- /debug multi-topic research works for root cause analysis
- /revise multi-topic research works with existing plan context
- All three commands generate ≥2 reports at complexity ≥3

**Phase 13-14 Gate**: Research infrastructure validated
- Cache hits avoid research-specialist invocation
- Cache TTL enforced (expired entries trigger refresh)
- Index search returns relevant results
- Index populated on new research creation

**Phase 15 Gate**: Advanced topic detection validated
- Semantic clustering identifies related topics
- --confirm flag pauses for user interaction
- Dependencies execute in correct order

**Phase 16 Gate**: Adaptive research depth validated
- --topics flag overrides default allocation
- Dynamic specialist selection routes correctly
- Iterative research triggers on shallow results (max 2 iterations)

**Phase 17 Gate**: Research versioning validated
- Stale research triggers refresh
- Version history preserved
- Archive created for old versions

## Extended Implementation Phases (Deferred from Spec 009)

### Phase 10: Integrate research-coordinator into /repair [NOT STARTED]
dependencies: [1, 5]

**Objective**: Enable multi-topic error analysis research for /repair command

**Complexity**: High

**Tasks**:
- [ ] Add Block 1a-topics: Error Analysis Topic Decomposition
  - Analyze ERROR_DESCRIPTION for multi-topic indicators
  - Use RESEARCH_COMPLEXITY to determine topic count
  - Pre-calculate report paths for error analysis topics (e.g., "error patterns", "root causes", "affected workflows")
  - Factor in error filters (--since, --type, --command, --severity) for topic scoping
  - Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file
- [ ] Replace Block 1b-exec research-specialist invocation with research-coordinator
  - Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
  - Pass error_filters, research_complexity, report_dir, topics array, report_paths array as contract
  - Include ERROR_DESCRIPTION and RESEARCH_DIR in context
- [ ] Update Block 1c validation to handle multiple reports (multi-report hard barrier)
  - Loop through REPORT_PATHS_ARRAY and validate each report with validate_agent_artifact
  - Fail-fast if any report missing (maintain hard barrier pattern)
  - Extract metadata from each report (error patterns found, root causes identified)
  - Persist aggregated metadata to state file
- [ ] Update Block 2b: Planning Phase Integration
  - Pass report paths to plan-architect (not full content)
  - Include aggregated error analysis metadata in plan-architect prompt
- [ ] Update /repair frontmatter dependent-agents field
  - Add research-coordinator to dependency list
  - Remove research-specialist (transitive dependency)

**Testing**:
```bash
# Test /repair with multi-topic error analysis
/repair --type state_error --complexity 3

# Verify research-coordinator was invoked
grep "research-coordinator" .claude/output/repair-output.md

# Verify multiple reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
# Should be ≥2 reports
```

**Expected Duration**: 6-8 hours

### Phase 11: Integrate research-coordinator into /debug [NOT STARTED]
dependencies: [1, 5]

**Objective**: Enable multi-topic root cause analysis research for /debug command

**Complexity**: High

**Tasks**:
- [ ] Add Block 3-topics: Root Cause Topic Decomposition
  - Analyze ISSUE_DESCRIPTION for multi-topic indicators
  - Use RESEARCH_COMPLEXITY to determine investigation scope
  - Pre-calculate report paths for investigation topics (e.g., "symptom analysis", "code path investigation", "context gathering")
  - Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file
- [ ] Replace Block 3 research-specialist invocation with research-coordinator
  - Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
  - Pass issue_description, research_complexity, report_dir, topics array, report_paths array as contract
  - Include DEBUG_DIR context for analysis artifacts
- [ ] Update Block 3 validation to handle multiple reports
  - Loop through REPORT_PATHS_ARRAY and validate each report
  - Extract metadata from each report (investigation findings, suspected causes)
  - Persist aggregated metadata to state file
- [ ] Update Block 4: Planning Phase Integration
  - Pass report paths to plan-architect for debug strategy creation
  - Include aggregated investigation metadata
- [ ] Update /debug frontmatter dependent-agents field
  - Add research-coordinator to dependency list
  - Remove research-specialist (transitive dependency)

**Testing**:
```bash
# Test /debug with multi-topic investigation
/debug "authentication timeout errors in production" --complexity 3

# Verify research-coordinator was invoked
grep "research-coordinator" .claude/output/debug-output.md

# Verify multiple investigation reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
# Should be ≥2 reports
```

**Expected Duration**: 6-8 hours

### Phase 12: Integrate research-coordinator into /revise [NOT STARTED]
dependencies: [1, 5]

**Objective**: Enable multi-topic revision context research for /revise command

**Complexity**: Medium

**Tasks**:
- [ ] Add Block 4a-topics: Revision Context Topic Decomposition
  - Analyze REVISION_DETAILS for multi-topic indicators
  - Use RESEARCH_COMPLEXITY to determine context depth
  - Pre-calculate report paths for revision topics (e.g., "current implementation analysis", "proposed changes impact", "dependency assessment")
  - Include EXISTING_PLAN_PATH context for topic scoping
  - Persist TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file
- [ ] Replace Block 4b research-specialist invocation with research-coordinator
  - Use imperative directive: "**EXECUTE NOW**: USE the Task tool..."
  - Pass revision_details, existing_plan_path, research_complexity, topics array, report_paths array as contract
  - Maintain reference to existing plan for context
- [ ] Update Block 4c validation to handle multiple reports
  - Loop through REPORT_PATHS_ARRAY and validate each report
  - Extract metadata from each report (revision recommendations, impact analysis)
  - Persist aggregated metadata to state file
- [ ] Update Block 5b: Plan Revision Integration
  - Pass report paths to plan-architect (not full content)
  - Include aggregated revision metadata in plan-architect prompt
- [ ] Update /revise frontmatter dependent-agents field
  - Add research-coordinator to dependency list
  - Remove research-specialist, research-sub-supervisor (transitive dependencies)

**Testing**:
```bash
# Test /revise with multi-topic context research
/revise "revise plan at .claude/specs/123/plans/001.md based on new security requirements" --complexity 3

# Verify research-coordinator was invoked
grep "research-coordinator" .claude/output/revise-output.md

# Verify multiple context reports created
ls -1 .claude/specs/*/reports/*.md | wc -l
```

**Expected Duration**: 5-7 hours

### Phase 13: Implement Research Cache [NOT STARTED]
dependencies: [1, 3, 10, 11, 12]

**Objective**: Reduce redundant research by caching recent results

**Complexity**: Medium

**Tasks**:
- [ ] Create cache storage infrastructure
  - Create `.claude/data/research_cache/` directory structure
  - Define cache key generation: hash of normalized topic description
  - Define cache entry format: `{topic_hash}.json` containing report path, metadata, timestamp
- [ ] Add cache check logic to research-coordinator
  - Before invoking research-specialist, check cache for matching topic
  - Cache hit: Return cached report path and metadata (skip research-specialist)
  - Cache miss: Proceed with normal research-specialist invocation
  - Log cache hit/miss for performance metrics
- [ ] Add cache write logic to research-specialist
  - After creating report, compute topic hash
  - Write cache entry with report path, metadata summary, timestamp
  - Respect cache directory permissions
- [ ] Implement cache TTL (Time-To-Live)
  - Default TTL: 7 days
  - Configurable via CLAUDE_RESEARCH_CACHE_TTL environment variable
  - On cache hit, check timestamp against TTL
  - If expired, treat as cache miss
- [ ] Add cache management utilities
  - `clear_research_cache()` - Clear all cached entries
  - `cache_stats()` - Report cache size, hit rate, oldest entry
  - Add to `.claude/lib/research/cache-utils.sh`

**Testing**:
```bash
# Test cache hit scenario
/create-plan "OAuth2 authentication" --complexity 2  # Creates cache
/create-plan "OAuth2 authentication" --complexity 2  # Should hit cache

# Verify cache hit logged
grep "cache_hit" .claude/output/create-plan-output.md

# Test cache miss scenario (different topic)
/create-plan "GraphQL schema design" --complexity 2  # Cache miss

# Verify cache entry created
ls .claude/data/research_cache/*.json
```

**Expected Duration**: 8-10 hours

### Phase 14: Implement Research Index [NOT STARTED]
dependencies: [13]

**Objective**: Enable discovery of existing research reports across topics

**Complexity**: Medium

**Tasks**:
- [ ] Create index storage and schema
  - Storage location: `.claude/data/research_index.json`
  - Schema: `{entries: [{topic, path, date, keywords, summary}]}`
  - Initialize empty index on first use
- [ ] Add index update logic to research-specialist
  - On report creation, extract key information
  - Compute keywords from report content (top 10 significant terms)
  - Generate brief summary (first 200 chars of findings)
  - Append entry to index
- [ ] Implement search/query capability
  - Function: `search_research_index(query, limit=10)`
  - Search fields: topic, keywords, summary
  - Return matching entries sorted by relevance
  - Add to `.claude/lib/research/index-utils.sh`
- [ ] Integrate index check into research-coordinator
  - Before creating new research, query index for related existing reports
  - If relevant reports found, include as context for research-specialist
  - Optional: Skip new research if highly relevant report exists (--reuse-research flag)
- [ ] Add index management utilities
  - `rebuild_research_index()` - Rebuild from existing reports
  - `index_stats()` - Report entry count, date range, common topics

**Testing**:
```bash
# Generate some research to populate index
/create-plan "Feature A" --complexity 2
/research "Topic related to Feature A" --complexity 2

# Search index
search_research_index "Feature A"
# Should return both reports

# Test index integration
/create-plan "Feature A extension" --complexity 2
# Should find and reference existing "Feature A" research
```

**Expected Duration**: 6-8 hours

### Phase 15: Advanced Topic Detection [NOT STARTED]
dependencies: [2]

**Objective**: Improve topic detection quality through semantic analysis and user interaction

**Complexity**: High

**Subtasks**:

**Phase 15a: LLM-based Semantic Topic Clustering**
- [ ] Upgrade topic-detection-agent prompt
  - Add semantic analysis instructions (analyze meaning, not just keywords)
  - Include conceptual grouping guidance
  - Request topic relationships in output (related, independent, overlapping)
- [ ] Extend output format
  - Add `relationships` field to topics JSON
  - Format: `{"topics": [...], "relationships": {"topic1": {"type": "independent"}, "topic2": {"related_to": "topic1"}}}`
- [ ] Update research-coordinator to consume relationships
  - Group related topics for context sharing
  - Process independent topics in parallel

**Phase 15b: User-Interactive Topic Refinement**
- [ ] Add --confirm flag to /create-plan, /research, /repair, /debug, /revise
  - When enabled, pause after topic detection
  - Display detected topics with descriptions
  - Prompt user: "Proceed with these topics? (y)es/(e)dit/(a)dd/(r)emove/(c)ancel"
- [ ] Implement topic editing interface
  - Allow users to rename topics
  - Allow users to add new topics
  - Allow users to remove suggested topics
  - Validate topic format before proceeding
- [ ] Auto-enable for complexity 4 (comprehensive analysis warrants confirmation)
  - Skip confirmation for complexity 1-2 (simple, clear topics)
  - Optional for complexity 3

**Phase 15c: Topic Dependency Tracking**
- [ ] Extend topic-detection-agent output format
  - Add `dependencies` field: `{"topic2": ["topic1"]}` means topic2 depends on topic1
  - Dependency indicates topic2 should be researched after topic1
- [ ] Update research-coordinator execution strategy
  - Build dependency graph from topics
  - Execute independent topics in parallel
  - Execute dependent topics sequentially after dependencies complete
  - Pass prior topic findings as context to dependent topics
- [ ] Add cycle detection
  - Detect circular dependencies (topic1 → topic2 → topic1)
  - If cycle detected, break arbitrarily and log warning

**Testing**:
```bash
# Test semantic clustering
/create-plan "Implement OAuth2 with JWT tokens, session management, and password policies" --complexity 4
# Should identify 3 related topics with clear relationships

# Test interactive confirmation
/create-plan "Complex feature" --confirm
# Should pause and display topics for confirmation

# Test dependency tracking
/research "Database migrations and schema versioning" --complexity 3
# Should identify that versioning depends on migrations understanding
```

**Expected Duration**: 12-15 hours

### Phase 16: Adaptive Research Depth [NOT STARTED]
dependencies: [1, 2, 15]

**Objective**: Dynamically adjust research depth based on prompt complexity and domain

**Complexity**: High

**Subtasks**:

**Phase 16a: Enhanced Complexity-Based Research Allocation**
- [ ] Extend complexity mapping heuristics
  - Factor in prompt length (longer prompts suggest more topics)
  - Factor in technical term density (domain complexity)
  - Factor in ambiguity markers (questions, conditionals suggest deeper research)
- [ ] Add topic count override
  - New flag: `--topics N` to force specific topic count
  - Range: 1-7 topics
  - Log override for audit purposes
- [ ] Document enhanced complexity mapping in research-invocation-standards.md
  - Include decision tree for complexity → topic count
  - Include override guidance

**Phase 16b: Dynamic Research-Specialist Selection**
- [ ] Define specialist types
  - `generic` (default): General-purpose research
  - `lean-specific`: Lean 4 / Mathlib research (existing lean-research-specialist)
  - `security-focused`: Security-related research (new)
  - `performance-focused`: Performance analysis research (new)
- [ ] Extend topic-detection-agent output
  - Add `recommended_specialist` field per topic
  - Format: `{"topic": "...", "recommended_specialist": "lean-specific"}`
- [ ] Update research-coordinator routing
  - Route each topic to recommended specialist
  - Fallback to generic if specialized specialist unavailable
  - Log specialist selection for debugging
- [ ] Document specialist framework in research-invocation-standards.md
  - When to create new specialists
  - How to extend routing logic

**Phase 16c: Iterative Research Capability**
- [ ] Implement research iteration in research-coordinator
  - After initial research, analyze results for completeness
  - If gaps identified (e.g., unanswered questions, missing context), generate follow-up topics
  - Maximum 2 iterations to prevent infinite loops
  - Log iteration count and rationale in metadata
- [ ] Define iteration triggers
  - Findings < 3 per topic (shallow research)
  - Explicit "NEEDS_MORE_RESEARCH" marker in report
  - Unanswered questions section in report
- [ ] Add iteration control flags
  - `--no-iterate`: Disable iterative research
  - `--max-iterations N`: Override default max (default: 2)

**Testing**:
```bash
# Test enhanced complexity allocation
/create-plan "This is a very long and detailed prompt with many technical terms..." --complexity 3
# Should allocate more topics than simple prompt at same complexity

# Test topic count override
/create-plan "Feature" --topics 5
# Should create exactly 5 topics regardless of complexity

# Test dynamic specialist selection
/lean-plan "Formalize group homomorphism theorems"
# Should route to lean-research-specialist

# Test iterative research
/research "Complex ambiguous topic" --complexity 4
# May trigger second iteration if initial research shallow
```

**Expected Duration**: 15-20 hours

### Phase 17: Research Versioning [NOT STARTED]
dependencies: [13, 14]

**Objective**: Track research freshness and trigger refresh when stale

**Complexity**: Medium

**Tasks**:
- [ ] Extend research index with versioning fields
  - Add `research_date` field (ISO timestamp)
  - Add `version` field (incrementing integer)
  - Add `staleness_threshold` field (days until stale, default: 14)
- [ ] Implement staleness checking
  - On cache hit, compare research_date to current date
  - If (current_date - research_date) > staleness_threshold, mark as stale
  - Stale entries trigger refresh, not cache hit
- [ ] Implement refresh behavior
  - When stale entry found, create new research
  - Increment version number in new entry
  - Archive old report (move to `reports/archive/`)
  - Update index with new entry, preserve history link
- [ ] Add version comparison utilities
  - `compare_research_versions(topic, v1, v2)` - Show diff
  - `research_history(topic)` - List all versions
- [ ] Optional: Dependency invalidation
  - Track which research reports cite other reports
  - When source report refreshed, mark derived reports as potentially stale
  - Implementation: Add `depends_on` field to index entries

**Testing**:
```bash
# Create research
/research "Topic A" --complexity 2

# Simulate staleness (adjust timestamp in index)
# Then re-run
/research "Topic A" --complexity 2
# Should trigger refresh, create new version

# Check version history
research_history "Topic A"
# Should show v1 (archived) and v2 (current)
```

**Expected Duration**: 5-7 hours

## Notes

### Core Plan Notes
- This plan addresses the critical gap between completed infrastructure (spec 009 Phases 1-3, 5) and zero command integration
- Original report (spec 011) identified /create-plan as highest-value integration target - this plan prioritizes it as Phase 1
- Spec 009 Phase 2 status discrepancy (/lean-plan marked COMPLETE but not implemented) addressed in Phase 4 investigation
- Documentation-implementation drift (Finding 10) addressed by Phase 7 synchronization and status markers
- Hard barrier pattern already uniform across commands (Finding 7) - foundation for coordinator integration is solid
- topic-detection-agent exists but unused (Finding 6) - Phase 2 integrates it for automated decomposition
- research-sub-supervisor dead code (Finding 9) is symptom of Phase 4 deferral - transitive dependency, not directly invoked
- Performance targets (40-60% context reduction, 40-60% time savings) from spec 009 will be measured in Phase 8 - relaxed to ≥30% reduction and >0% time savings for validation gates
- All phases follow standards: three-tier sourcing, imperative directives for Task tool, hard barrier pattern, error logging integration

### Revision Notes (2025-12-08)
This plan was revised to include all deferred work from spec 009, expanding from 9 phases to 17 phases:

**Extended Integration (Phases 10-12)**: Added full coverage of remaining commands:
- Phase 10: /repair command integration (error pattern multi-topic research)
- Phase 11: /debug command integration (root cause multi-topic research)
- Phase 12: /revise command integration (revision context multi-topic research)

**Research Infrastructure (Phases 13-14)**: Added caching and indexing capabilities:
- Phase 13: Research cache with TTL-based expiration (reduce redundant research)
- Phase 14: Research index with search capability (enable topic discovery)

**Advanced Features (Phases 15-17)**: Added all Phase 6-8 deferred features from spec 009:
- Phase 15: Advanced topic detection (semantic clustering, interactive refinement, dependency tracking)
- Phase 16: Adaptive research depth (complexity allocation, dynamic specialists, iterative research)
- Phase 17: Research versioning (staleness tracking, automatic refresh)

**Estimated Hours Updated**: 105-139 hours (increased from 42-56 hours to cover all deferred work)

**Priority Guidance**:
- Phases 1-9: Core integration (highest priority, enables basic coordinator pattern)
- Phases 10-12: Extended integration (high priority, completes command coverage)
- Phases 13-14: Infrastructure (medium priority, improves efficiency)
- Phases 15-17: Advanced features (lower priority, enhances quality)

PLAN_REVISED: /home/benjamin/.config/.claude/specs/013_research_coordinator_gaps_uniformity/plans/001-research-coordinator-gaps-uniformity-plan.md

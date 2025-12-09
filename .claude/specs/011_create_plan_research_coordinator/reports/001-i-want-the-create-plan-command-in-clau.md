# Research Coordinator Integration for /create-plan Command: Gap Analysis and Enhancement Opportunities

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist
- **Topic**: Research coordinator integration for /create-plan command token optimization
- **Report Type**: gap analysis and architectural enhancement

## Executive Summary

The /create-plan command currently performs all research inline using the primary agent (Sonnet 4.5) in a single research-specialist invocation at Block 1e-exec (lines 951-986). This approach consumes significant primary agent context when complex features require multi-topic research. The existing infrastructure already supports hierarchical research coordination through research-sub-supervisor.md and hierarchical-agents-coordination.md patterns, but /create-plan has not yet been enhanced to use this pattern. A research coordinator integration would enable parallel multi-topic research (achieving 40-60% token reduction and time savings), following the proven pattern from specs/009 planning work. Key gaps include: lack of topic decomposition logic, no parallel research invocation structure, and missing metadata aggregation from multiple research-specialist workers.

## Findings

### Finding 1: Current /create-plan Research Pattern Uses Single Research-Specialist Invocation
- **Description**: The /create-plan command invokes research-specialist exactly once at Block 1e-exec (lines 951-986), passing the entire FEATURE_DESCRIPTION as a single research topic
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md lines 951-986
- **Evidence**:
```markdown
## Block 1e-exec: Research Specialist Invocation

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Research Topic: ${FEATURE_DESCRIPTION}
    Research Complexity: ${RESEARCH_COMPLEXITY}
    Output Path: ${REPORT_PATH}
  "
}
```
- **Impact**: Single research invocation prevents parallelization of multi-topic research. For complex features requiring research across multiple domains (e.g., "implement user authentication with OAuth2, session management, and password hashing"), all research is serialized into one report. This consumes primary agent context and misses parallelization opportunities.

### Finding 2: Existing research-sub-supervisor.md Provides Complete Coordinator Pattern
- **Description**: The research-sub-supervisor agent (500 lines, comprehensive behavioral file) provides a proven pattern for coordinating 4+ research-specialist workers in parallel with 95% context reduction through metadata aggregation
- **Location**: /home/benjamin/.config/.claude/agents/research-sub-supervisor.md lines 1-500
- **Evidence**:
```markdown
## Purpose
Coordinates multiple research-specialist workers to research different topics in parallel:
1. **Parallel Execution**: All workers execute simultaneously (40-60% time savings)
2. **Metadata Aggregation**: Combine worker outputs into supervisor summary (95% context reduction)
3. **Checkpoint Coordination**: Save supervisor state for resume capability
4. **Partial Failure Handling**: Handle scenarios where some workers fail

## Expected Outputs
{
  "supervisor_id": "research_sub_supervisor_20251107_143030",
  "worker_count": 4,
  "reports_created": ["/path1", "/path2", "/path3", "/path4"],
  "summary": "Combined 50-100 word summary integrating all research findings",
  "key_findings": ["finding1", "finding2", "finding3", "finding4"],
  "context_tokens": 500
}

Context Reduction: Returns ~500 tokens vs ~10,000 tokens (95% reduction)
```
- **Impact**: The research-sub-supervisor provides all necessary coordination logic (parallel invocation, metadata extraction, aggregation, failure handling). /create-plan can leverage this existing infrastructure without implementing coordinator logic from scratch.

### Finding 3: Spec 009 Already Planned Research Coordinator Integration (Not Yet Implemented)
- **Description**: Spec 009_research_coordinator_agents contains a complete implementation plan (506 lines) for adding research-coordinator pattern to /lean-plan and /create-plan, but status is [NOT STARTED]
- **Location**: /home/benjamin/.config/.claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md lines 1-506
- **Evidence**:
```markdown
## Metadata
- **Status**: [NOT STARTED]
- **Feature**: Add research-coordinator agent to /lean-plan for parallel multi-topic research orchestration

## Success Criteria
- [ ] research-coordinator behavioral file created at `.claude/agents/research-coordinator.md`
- [ ] /lean-plan command integrates research-coordinator with hard barrier pattern
- [ ] Context reduction of 40-60% measured in /lean-plan execution

## Implementation Phases
### Phase 2: Integrate research-coordinator into /lean-plan [NOT STARTED]
### Phase 4: Apply Pattern to Other Planning Commands [NOT STARTED]
  - [ ] Integrate research-coordinator into /create-plan command
```
- **Impact**: Spec 009 provides a complete roadmap but has not been executed. /create-plan can benefit from this pattern immediately, following the proven spec 009 design for Phase 4 integration.

### Finding 4: Topic Decomposition Logic Missing from /create-plan
- **Description**: /create-plan lacks any mechanism to analyze FEATURE_DESCRIPTION and decompose it into multiple research topics for parallel investigation
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md (no topic decomposition blocks present)
- **Evidence**: The command proceeds directly from topic path initialization (Block 1d, lines 550-846) to single report path pre-calculation (Block 1e, lines 849-948) without any topic analysis or decomposition logic
- **Impact**: Without topic decomposition, /create-plan cannot identify that "implement OAuth2 authentication with session management and password security" should be researched as 3 parallel topics (OAuth2 patterns, session management, password security). The research coordinator pattern requires topic decomposition as input.

### Finding 5: Hard Barrier Pattern Already Implemented in /create-plan
- **Description**: /create-plan already implements the hard barrier pattern with path pre-calculation (Block 1e, lines 849-948), Task invocation (Block 1e-exec, lines 951-986), and validation (Block 1f, lines 989-1108)
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md lines 849-1108
- **Evidence**:
```markdown
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
- **Impact**: The hard barrier infrastructure is already in place. Integrating research coordinator requires extending this pattern to handle multiple report paths (one per research topic) rather than a single report path. The validation pattern (validate_agent_artifact) can be applied to each report in a loop.

### Finding 6: Hierarchical Supervision Pattern Documented in Standards
- **Description**: The hierarchical supervision pattern is fully documented in .claude/docs/concepts/patterns/hierarchical-supervision.md with 3-level coordination (primary supervisor → sub-supervisors → workers), metadata-only communication, and 95%+ context reduction
- **Location**: /home/benjamin/.config/.claude/docs/concepts/patterns/hierarchical-supervision.md lines 1-425
- **Evidence**:
```markdown
## Core Mechanism
Level 1: Primary Supervisor (Orchestrator)
  - Coordinates sub-supervisors, not individual workers
  - DO NOT invoke worker agents directly
  - ONLY invoke sub-supervisors via Task tool

Level 2: Sub-Supervisor
  - Coordinates worker agents within specialized domain
  - DO NOT create research reports yourself
  - ONLY coordinate worker agents who create reports

Level 3: Worker Agents
  - Execute tasks and return metadata only

Context Reduction (10-agent workflow):
  - Flat: 10 agents × 250 tokens = 2,500 tokens (10%)
  - Hierarchical: 2 sub-supervisors × 500 tokens = 1,000 tokens (4%)
```
- **Impact**: /create-plan should invoke research-sub-supervisor (Level 2), which then invokes multiple research-specialist workers (Level 3). This matches the documented pattern and achieves the documented context reduction metrics.

### Finding 7: Research Complexity Flag Supports Multi-Topic Research Depth
- **Description**: /create-plan accepts --complexity flag (1-4, default 3) that controls research depth, which can inform topic decomposition strategy (higher complexity → more topics)
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md lines 55-68
- **Evidence**:
```bash
# Parse optional --complexity flag (default: 3 for research-and-plan)
DEFAULT_COMPLEXITY=3
RESEARCH_COMPLEXITY="$DEFAULT_COMPLEXITY"

if [[ "$FEATURE_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
  FEATURE_DESCRIPTION=$(echo "$FEATURE_DESCRIPTION" | sed 's/--complexity[[:space:]]*[1-4]//' | xargs)
fi
```
- **Impact**: RESEARCH_COMPLEXITY can drive topic decomposition decisions:
  - Complexity 1-2: Single topic (backward compatibility, fast research)
  - Complexity 3: 2-3 topics (standard multi-domain research)
  - Complexity 4: 4-5 topics (comprehensive research across all domains)

### Finding 8: Plan-Architect Already Receives Report Paths, Not Full Content
- **Description**: The plan-architect invocation at Block 2-exec (lines 1437-1511) passes REPORT_PATHS_LIST and research report metadata to plan-architect, which reads full reports as needed
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md lines 1437-1511
- **Evidence**:
```markdown
**Workflow-Specific Context**:
- Feature Description: ${FEATURE_DESCRIPTION}
- Output Path: ${PLAN_PATH}
- Research Reports: ${REPORT_PATHS_LIST}
- Workflow Type: research-and-plan

**CRITICAL**: You MUST write the plan to the EXACT path specified above.
```
- **Impact**: Plan-architect already expects report paths and can handle multiple research reports. No changes needed to plan-architect behavioral file or invocation pattern for research coordinator integration. The existing interface supports multiple reports.

### Finding 9: No Existing Research Coordinator Agent (Only Sub-Supervisor)
- **Description**: The .claude/agents/ directory contains research-sub-supervisor.md but NOT research-coordinator.md as specified in spec 009 Phase 1 requirements
- **Location**: /home/benjamin/.config/.claude/agents/ (glob pattern **/*coordinator*.md shows only conversion-coordinator.md, lean-coordinator.md, implementer-coordinator.md)
- **Evidence**: Grep for "research-sub-supervisor|research coordinator" found 24 files referencing the spec/plan but no research-coordinator.md behavioral file exists in .claude/agents/
- **Impact**: **CRITICAL GAP**: Implementing research coordinator integration requires creating research-coordinator.md behavioral file as specified in spec 009 Phase 1. The existing research-sub-supervisor.md is NOT a drop-in replacement - it expects inputs from a coordinator layer above it. /create-plan needs a coordinator agent that invokes research-sub-supervisor (or directly invokes multiple research-specialist workers if topic count < 4).

### Finding 10: /create-plan Total Length (1969 Lines) Indicates Block Addition Feasibility
- **Description**: /create-plan is currently 1969 lines, which is manageable for adding 3-4 new blocks for topic decomposition, coordinator invocation, and multi-report validation
- **Location**: /home/benjamin/.config/.claude/commands/create-plan.md (1969 total lines)
- **Evidence**: wc -l output shows 1969 lines. For comparison, /research command (with similar structure) is 1355 lines. Adding 150-200 lines for coordinator integration (topic decomposition block, coordinator invocation, multi-report validation) is proportional.
- **Impact**: File length is not a blocker. The command can accommodate additional blocks without becoming unwieldy. Standard practice is to keep commands under 2500 lines; 1969 + 200 = 2169 lines is within acceptable range.

## Recommendations

1. **Create research-coordinator.md behavioral file following spec 009 Phase 1 design**: Define a coordinator agent at `.claude/agents/research-coordinator.md` that:
   - Accepts a list of research topics from the primary agent
   - Pre-calculates report paths for each topic (using sequential numbering: 001, 002, 003, etc.)
   - Invokes research-sub-supervisor if topic count ≥ 4 (hierarchical pattern), or directly invokes multiple research-specialist workers if topic count < 4 (flat pattern)
   - Validates all report artifacts exist (hard barrier pattern)
   - Extracts metadata from each report (title, key findings count, recommendations count)
   - Returns aggregated metadata to primary agent (500-800 tokens total vs 10,000+ for full reports)

2. **Add Block 1d-topics: Topic Decomposition to /create-plan**: Insert a new bash block after Block 1d (topic path initialization) that:
   - Analyzes FEATURE_DESCRIPTION to identify 1-5 discrete research topics
   - Uses RESEARCH_COMPLEXITY to determine topic count (complexity 1-2 → 1 topic, complexity 3 → 2-3 topics, complexity 4 → 4-5 topics)
   - Pre-calculates report paths for each topic: `${RESEARCH_DIR}/001-topic1.md`, `${RESEARCH_DIR}/002-topic2.md`, etc.
   - Persists TOPICS_ARRAY and REPORT_PATHS_ARRAY to state file
   - Falls back to single topic if decomposition fails (backward compatibility)

3. **Replace Block 1e-exec with research-coordinator invocation**: Modify Block 1e-exec (currently single research-specialist invocation) to:
   - Invoke research-coordinator via Task tool (not research-specialist directly)
   - Pass TOPICS_ARRAY, REPORT_PATHS_ARRAY, and RESEARCH_DIR as explicit contract
   - Include RESEARCH_COMPLEXITY for research depth control
   - Use imperative directive: "**EXECUTE NOW**: USE the Task tool to invoke the research-coordinator agent"

4. **Extend Block 1f validation to handle multiple reports**: Update Block 1f (research output verification) to:
   - Loop through REPORT_PATHS_ARRAY and validate each report with validate_agent_artifact
   - Fail-fast if any report missing (hard barrier enforcement)
   - Extract metadata from each report (title, findings count) using Read tool
   - Aggregate metadata for passing to plan-architect (optional: create AGGREGATED_METADATA variable)

5. **Update /create-plan frontmatter to declare research-coordinator dependency**: Add research-coordinator to dependent-agents field:
   ```yaml
   dependent-agents:
     - research-coordinator
     - research-specialist
     - research-sub-supervisor
     - plan-architect
   ```

6. **Implement topic decomposition heuristics based on feature description patterns**: Use pattern matching to identify multi-topic features:
   - Presence of conjunctions ("and", "with", "including") suggests multiple topics
   - Technical keywords (e.g., "authentication", "authorization", "session", "password") map to distinct topics
   - Architecture terms (e.g., "frontend", "backend", "database", "API") suggest domain decomposition
   - Fallback: Single topic if no clear decomposition indicators

7. **Add integration test for multi-topic research scenario**: Create test case that:
   - Invokes /create-plan with complex feature description requiring 3-4 topics
   - Verifies research-coordinator was invoked (check output for "research-coordinator" text)
   - Verifies multiple reports created (count files in RESEARCH_DIR)
   - Verifies plan-architect received multiple report paths (grep plan file for Research Reports section)
   - Measures token reduction (compare context usage before/after integration)

8. **Document research-coordinator pattern in hierarchical agents guide**: Add research-coordinator as Example 8 to `.claude/docs/concepts/hierarchical-agents-examples.md` showing:
   - Topic decomposition strategy and complexity-based thresholds
   - Coordinator decision logic (when to use sub-supervisor vs direct worker invocation)
   - Metadata aggregation format and context reduction metrics
   - Integration pattern for planning commands (/create-plan, /lean-plan, /repair, /debug, /revise)

9. **Consider creating lightweight topic-detection-agent for automated decomposition** (Optional Phase 3 enhancement): Create `.claude/agents/topic-detection-agent.md` that:
   - Accepts FEATURE_DESCRIPTION as input
   - Returns JSON array of 1-5 topics with scope descriptions
   - Uses Haiku model for fast, cost-effective topic analysis
   - Provides fallback to single topic if detection fails
   - Integrates into research-coordinator (or /create-plan directly) for fully automated topic decomposition

10. **Apply research-coordinator pattern to /lean-plan, /repair, /debug, /revise after /create-plan validation**: Once proven in /create-plan (Phase 2), extend pattern to other planning commands following spec 009 Phase 4 approach, prioritizing /lean-plan (highest usage) then /repair, /debug, /revise.

## References

- /home/benjamin/.config/.claude/commands/create-plan.md (lines 1-1969) - Current /create-plan implementation with single research-specialist invocation
- /home/benjamin/.config/.claude/agents/research-sub-supervisor.md (lines 1-500) - Existing hierarchical research coordination infrastructure
- /home/benjamin/.config/.claude/specs/009_research_coordinator_agents/plans/001-research-coordinator-agents-plan.md (lines 1-506) - Complete implementation plan (NOT STARTED status)
- /home/benjamin/.config/.claude/specs/009_research_coordinator_agents/reports/001-research-coordinator-agents-analysis.md (lines 1-190) - Research analysis supporting coordinator pattern
- /home/benjamin/.config/.claude/docs/concepts/patterns/hierarchical-supervision.md (lines 1-425) - Hierarchical supervision pattern documentation
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-coordination.md (lines 1-262) - Multi-agent coordination patterns
- /home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md (lines 1-300) - Command development standards including Task tool invocation patterns
- /home/benjamin/.config/.claude/docs/reference/standards/output-formatting.md (lines 1-200) - Output formatting and suppression standards
- /home/benjamin/.config/CLAUDE.md (lines 240-248) - Hierarchical agent architecture standards section

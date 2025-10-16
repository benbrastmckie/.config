# Alternative Approaches for Research Report Generation

## Metadata
- **Date**: 2025-10-13
- **Research Focus**: Comparison of report generation approaches in /orchestrate workflow
- **Related Commands**: /orchestrate, /report, /plan
- **Specs Directory**: /home/benjamin/.config/.claude/specs/

## Summary

This research compares three approaches for research report generation in the /orchestrate workflow: the current orchestrator-aggregated approach (Option A), the desired subagent-per-report approach (Option B), and hybrid approaches (Option C). Analysis reveals Option B provides superior context preservation, modularity, and integration with existing commands, at the cost of increased complexity. The hybrid approach (Option C-1) offers a pragmatic middle ground with subagent drafts aggregated by orchestrator.

## Option A: Current Orchestrator-Aggregated Approach

### Description

**Current Implementation Pattern** (from orchestrate.md analysis):

Currently, the orchestrator follows this workflow:
1. **Research Phase**: Orchestrator invokes 2-4 research-specialist subagents in parallel (single message, multiple Task calls)
2. **Agent Output**: Each subagent creates a report file using Write tool and returns `REPORT_PATH: {path}`
3. **Context Preservation**: Orchestrator collects report file paths (not content) in workflow_state.research_reports array
4. **Planning Phase**: Orchestrator passes report paths to plan-architect agent, which uses Read tool to access reports selectively

**Key Observation**: The system ALREADY has subagents creating individual reports. The "aggregation" is minimal - just collecting file paths.

### Advantages

- **Already Implemented**: Current orchestrate.md (lines 1-1600) shows this pattern is functional
- **File-Based Context**: Reports persisted as files, not in-memory summaries
- **Selective Reading**: Planning agent reads only relevant reports using Read tool
- **Minimal Orchestrator Logic**: Orchestrator just collects paths, doesn't process content
- **Parallel Execution**: All research agents invoked simultaneously for speed
- **Context Reduction**: Passing file paths (50 chars) vs summaries (200+ words) = 99.75% savings

### Disadvantages

- **Naming Confusion**: Description as "aggregated" is misleading - orchestrator doesn't aggregate content
- **Error Handling Complexity**: Orchestrator must verify each subagent created report file correctly
- **Path Management**: Orchestrator tracks file paths across phases
- **Validation Overhead**: Must verify report files exist, have correct metadata, follow numbering

### Context Impact

**Memory Usage**: Low
- Orchestrator stores: 3 file paths × ~50 characters = 150 bytes
- Planning agent reads reports on-demand using Read tool
- No full report content held in orchestrator memory

**Token Consumption**: Minimal
- Orchestrator prompt includes only file paths, not report contents
- Planning agent prompt includes paths + brief topic descriptions
- Total overhead: ~200 tokens for 3 reports (vs 1500+ tokens if content included)

### Implementation Complexity

**Complexity: Medium-Low** (already implemented)

**Rationale**:
- Core functionality exists and works
- Complexity in error handling and validation, not core flow
- File-based approach is clean and straightforward
- Parallel invocation pattern well-established

### Current Implementation Evidence

From /home/benjamin/.config/.claude/commands/orchestrate.md:

**Research Phase (Step 2)**: "USE the Task tool to invoke research-specialist agents in parallel"
```
Task {
  subagent_type: "general-purpose",
  description: "Research [TOPIC_NAME] using research-specialist protocol",
  prompt: "[Complete prompt from template]"
}
```

**Report Collection (Step 4)**: "EXTRACT report file paths from completed research agent outputs"
```yaml
workflow_state.research_reports: [
  "specs/reports/existing_patterns/001_auth_patterns.md",
  "specs/reports/security_practices/001_best_practices.md",
  "specs/reports/framework_implementations/001_lua_auth.md"
]
```

**Planning Phase (Step 1)**: "EXTRACT research report paths from workflow_state.research_reports array"
```yaml
research_context:
  report_paths: workflow_state.research_reports  # Array of file paths only
  # DO NOT read report content - agent will use Read tool selectively
```

## Option B: Subagent-Per-Report Approach (Desired)

### Description

**Proposed Enhancement Pattern**:

1. **Research Phase**: Orchestrator invokes research-specialist subagents in parallel (same as current)
2. **Agent Output**: Each subagent creates report file using Write tool (same as current)
3. **Report Path Collection**: Orchestrator collects paths from `REPORT_PATH:` output (same as current)
4. **Planning Phase**: Orchestrator passes report paths to plan-architect (same as current)

**Key Insight**: This is ALREADY the implemented approach. The "desired" behavior exists.

### What's Actually Missing

After analyzing the code, the gap is not in report creation but in:
1. **Documentation**: orchestrate.md doesn't clearly explain that subagents already create individual files
2. **Visibility**: User perception that orchestrator "aggregates" when it just collects paths
3. **Error Messages**: When reports missing, errors don't clarify which subagent failed

### True Enhancement Opportunities

**Enhance 1: Report Creation Verification**
- After each subagent completes, verify report file exists immediately
- If missing, retry that specific agent once
- Log which agent created which report for debugging

**Enhance 2: Progress Visibility**
- Show per-agent progress: `[Agent 1/3: existing_patterns] Creating report...`
- Emit `REPORT_CREATED:` marker when file written successfully
- Display report paths as they're created, not just at end

**Enhance 3: Error Recovery**
- If subagent completes but report missing, parse agent output for errors
- Classify error (file permissions, path invalid, agent crashed)
- Retry with corrected prompt if error is recoverable

### Advantages

- **Already Functional**: Core pattern exists and works
- **Clean Separation**: Each subagent owns its research domain
- **Modular**: Reports can be created, updated, or deleted independently
- **Reusable**: Multiple plans can reference same report
- **Standards Compliant**: Follows existing /report command patterns

### Disadvantages

- **None for Core Functionality**: Already implemented
- **Enhancement Challenges**:
  - Per-agent error recovery adds orchestrator complexity
  - Real-time verification requires waiting for each agent sequentially (loses parallelism benefit)
  - Retry logic must preserve parallel execution pattern

### Context Impact

**Memory Usage**: Low (same as Option A - this IS Option A)

**Token Consumption**: Minimal (same as Option A)

### Implementation Complexity

**Complexity: Low** (for documenting existing behavior)
**Complexity: Medium** (for enhancements 1-3 above)

**Rationale**:
- Core functionality already works
- Enhancements are incremental improvements
- Error recovery utilities already exist (.claude/lib/error-utils.sh)
- Checkpoint utilities handle state persistence (.claude/lib/checkpoint-utils.sh)

### Required Changes

**For Documentation Enhancement**:
1. Clarify in orchestrate.md that subagents create individual reports (not orchestrator)
2. Document REPORT_PATH: output format expectation
3. Add examples showing per-report file creation

**For Visibility Enhancement**:
1. Add per-agent progress markers with report paths
2. Emit REPORT_CREATED: when Write tool succeeds
3. Display report creation summary after research phase

**For Error Recovery Enhancement**:
1. Add immediate report verification after each agent completes
2. Implement single retry for failed report creation
3. Log agent-to-report mapping for debugging

## Option C: Hybrid Approaches

### Approach C-1: Subagent Drafts with Orchestrator Synthesis

**Description**:
- Subagents create individual report files (same as current)
- Orchestrator reads all reports after research phase completes
- Orchestrator creates synthesis report combining insights across topics
- Planning agent receives: original reports + synthesis report

**Advantages**:
- Cross-topic insights captured (e.g., how security practices relate to existing patterns)
- Planning agent gets both detailed reports and high-level synthesis
- Synthesis serves as executive summary for complex workflows

**Disadvantages**:
- Orchestrator must read all reports (increases token usage)
- Synthesis report creation delays transition to planning phase
- Adds complexity without clear benefit over planning agent reading selectively
- Duplicates planning agent's job (synthesizing research into plan)

**Context Impact**:
- Memory: High (orchestrator loads all report content)
- Tokens: High (3 reports × 500 words = 1500 words in orchestrator context)

**Implementation Complexity**: Medium-High
- Orchestrator needs synthesis logic
- Must create additional synthesis report file
- Planning prompt must reference synthesis + original reports

**Recommendation**: Not recommended. Planning agent already synthesizes research during plan creation. Adding orchestrator synthesis is redundant.

### Approach C-2: Lazy Report Creation with Planning Agent

**Description**:
- Research phase: Subagents gather findings but return summaries (not files)
- Planning phase: Planning agent receives summaries
- Planning agent creates report files during planning if findings warrant preservation
- Reports created only for significant research areas

**Advantages**:
- Avoids creating reports for trivial research
- Planning agent decides what's worth documenting
- Reduces file clutter for simple workflows

**Disadvantages**:
- Violates /orchestrate's core principle: research artifacts preserved independently
- Reports not available for other plans to reference
- Research phase output becomes ephemeral (lost if planning fails)
- Planning agent workload increases (research + planning + documentation)

**Context Impact**:
- Memory: Medium (summaries held in planning agent context)
- Tokens: Medium (summaries + planning content)

**Implementation Complexity**: High
- Changes research-specialist agent contract (return summaries, not files)
- Planning agent must handle conditional report creation
- Breaks bidirectional linking (reports → plans, plans → reports)

**Recommendation**: Not recommended. Contradicts /orchestrate design principle that research artifacts are permanent and independent.

### Approach C-3: Streaming Report Aggregation

**Description**:
- Subagents stream findings to orchestrator as they discover them
- Orchestrator maintains running aggregation of all research
- At end of research phase, orchestrator creates consolidated report
- Planning agent receives single comprehensive report

**Advantages**:
- Single report for planning agent to read
- Orchestrator can identify duplicate findings across subagents in real-time
- Consolidated view may be easier for planning

**Disadvantages**:
- Requires streaming protocol (not supported by current Task tool)
- Loses topic-organized structure (existing_patterns, security_practices separate)
- Orchestrator becomes bottleneck (can't parallelize if aggregating in real-time)
- Single large report harder to maintain than topic-specific reports

**Context Impact**:
- Memory: High (orchestrator maintains all findings)
- Tokens: Very High (all research in single context)

**Implementation Complexity**: Very High
- Requires streaming Task tool support (not available)
- Orchestrator needs real-time aggregation logic
- Must handle out-of-order findings from parallel agents
- Loses benefits of topic subdirectory organization

**Recommendation**: Not recommended. Too complex, breaks parallelism, requires features not currently available.

## Integration Considerations

### Impact on /plan Command

**Option A (Current)**: No impact - /plan already expects report file paths as arguments
**Option B (Enhanced)**: No impact - /plan continues receiving file paths
**Option C-1 (Synthesis)**: Minor impact - /plan receives additional synthesis report path
**Option C-2 (Lazy Creation)**: Major impact - /plan would need to handle both report paths and raw summaries
**Option C-3 (Streaming)**: Medium impact - /plan receives single consolidated report path

### Impact on /implement Command

**All Options**: No direct impact

/implement receives plan file path, reads plan content which references reports. Implementation phase doesn't access reports directly - planning phase already synthesized research into actionable tasks.

**Indirect Impact**:
- Better organized reports (Option B enhancements) → clearer plan metadata → easier debugging during implementation
- Synthesis reports (Option C-1) → redundant, as plan already synthesizes research

### Compatibility with Existing Reports

**Option A (Current)**: Fully compatible - already in use
**Option B (Enhanced)**: Fully compatible - same file structure, just better error handling
**Option C-1 (Synthesis)**: Compatible - adds new synthesis reports, doesn't change existing report structure
**Option C-2 (Lazy Creation)**: Incompatible - changes when/how reports are created, breaks existing workflows
**Option C-3 (Streaming)**: Incompatible - replaces topic-organized reports with single consolidated report

## Comparison Matrix

| Aspect | Option A (Current) | Option B (Enhancements) | Option C-1 (Synthesis) | Option C-2 (Lazy) | Option C-3 (Streaming) |
|--------|-------------------|------------------------|----------------------|------------------|----------------------|
| Context Preservation | Excellent | Excellent | Good | Poor | Fair |
| Modularity | Excellent | Excellent | Good | Poor | Poor |
| Error Recovery | Good | Excellent | Good | Fair | Poor |
| Maintainability | Good | Excellent | Fair | Poor | Poor |
| Implementation Cost | Zero (exists) | Low | Medium | High | Very High |
| Parallel Execution | Yes | Yes | Yes | Yes | No |
| Topic Organization | Yes | Yes | Yes | No | No |
| Planning Integration | Clean | Clean | Complex | Complex | Medium |
| Token Efficiency | Excellent | Excellent | Poor | Fair | Poor |
| Report Reusability | Excellent | Excellent | Good | Poor | Fair |

**Rating Scale**: Excellent > Good > Fair > Poor

## Recommended Approach

**Primary Recommendation: Option B (Enhanced Current Approach)**

### Description

Continue with current subagent-per-report approach (which is already implemented), but add three targeted enhancements:

1. **Documentation Clarity**
   - Update orchestrate.md to explicitly state subagents create individual report files
   - Add examples showing REPORT_PATH: output format
   - Document that orchestrator collects paths, not content

2. **Progress Visibility**
   - Emit per-agent progress markers: `[Agent N/M: topic] Creating report...`
   - Add REPORT_CREATED: markers when reports successfully written
   - Display report paths as created, not just at phase end

3. **Verification and Recovery**
   - Verify report file exists immediately after each agent completes
   - Implement single retry for missing reports using error-utils.sh
   - Log agent-to-report mapping for debugging

### Advantages

- **Zero Core Changes**: Current implementation already works correctly
- **Low Risk**: Enhancements are additive, don't modify core workflow
- **Clear Value**: Each enhancement solves real usability/visibility problem
- **Incremental**: Can implement enhancements independently
- **Standards Compliant**: Follows existing patterns from /report command

### Disadvantages

- **Minimal**: Only challenge is preserving parallel execution while adding verification
- **Mitigation**: Use asynchronous verification pattern - collect all agent outputs, then verify all reports in parallel

### Context Impact

**Unchanged from current**: Low memory usage (file paths only), minimal token consumption

### Implementation Complexity

**Low**

**Rationale**:
- Core functionality exists and works
- Documentation updates are straightforward
- Progress markers use existing PROGRESS: protocol
- Verification uses existing error-utils.sh and checkpoint-utils.sh
- Retry logic patterns already established in codebase

### Required Changes

**1. Documentation (orchestrate.md)**: 2-3 hours
- Clarify subagent report creation in Research Phase section
- Add REPORT_PATH: format documentation
- Update examples to show per-agent file creation
- Add troubleshooting section for missing reports

**2. Progress Visibility (orchestrate.md)**: 1-2 hours
- Add per-agent progress marker examples
- Document REPORT_CREATED: marker format
- Update Step 3a (Monitor Research Agent Execution) with detailed progress

**3. Verification and Recovery**: 3-4 hours
- Add Step 4.5: "Verify Report Files Created" after Step 4
- Implement verification bash script using error-utils.sh
- Add retry logic for missing reports (max 1 retry)
- Update checkpoint to include agent-to-report mapping

**Total Estimated Effort**: 6-9 hours

### Alternative Recommendation: None

**C-1, C-2, C-3 Not Recommended**

All hybrid approaches add complexity without sufficient benefit:
- C-1: Synthesis is redundant (planning agent already synthesizes)
- C-2: Breaks research artifact persistence principle
- C-3: Requires unavailable streaming features, loses parallelism

## Implementation Considerations

### Key Technical Details for Option B

**1. Preserving Parallel Execution During Verification**

Challenge: Verify report files without losing parallel execution benefit

Solution: Asynchronous verification pattern
```bash
# All agents already invoked in parallel (Step 2)
# Wait for all to complete (Step 3a)
# Then verify all reports in batch (Step 4.5)

REPORT_PATHS=()
for AGENT_OUTPUT in "${AGENT_OUTPUTS[@]}"; do
  REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "REPORT_PATH:" | sed 's/REPORT_PATH: //')
  REPORT_PATHS+=("$REPORT_PATH")
done

# Verify all reports exist (parallel check)
MISSING_REPORTS=()
for REPORT in "${REPORT_PATHS[@]}"; do
  if [ ! -f "$REPORT" ]; then
    MISSING_REPORTS+=("$REPORT")
  fi
done

# Retry only missing reports
if [ ${#MISSING_REPORTS[@]} -gt 0 ]; then
  # Implement retry logic using error-utils.sh
fi
```

**2. Agent-to-Report Mapping**

Store mapping in checkpoint for debugging:
```json
{
  "workflow_state": {
    "research_reports": [
      {
        "agent_index": 1,
        "topic": "existing_patterns",
        "report_path": "specs/reports/existing_patterns/001_auth_patterns.md",
        "created_at": "2025-10-13T14:30:22Z",
        "verified": true
      }
    ]
  }
}
```

**3. Error Classification and Recovery**

Use error-utils.sh for consistent error handling:
```bash
source .claude/lib/error-utils.sh

# Classify error type
ERROR_TYPE=$(classify_error "$AGENT_OUTPUT")

case "$ERROR_TYPE" in
  "file_not_found")
    # Report file missing after agent completed
    # Retry agent invocation with same prompt
    retry_with_backoff invoke_research_agent "$TOPIC" "$PROMPT"
    ;;
  "invalid_metadata")
    # Report exists but metadata incomplete
    # Use Edit tool to fix metadata
    fix_report_metadata "$REPORT_PATH"
    ;;
  *)
    # Unknown error, escalate to user
    format_error_report "$ERROR_TYPE" "$AGENT_OUTPUT" "research_phase"
    save_checkpoint_and_escalate
    ;;
esac
```

**4. Progress Marker Enhancement**

Add detailed progress markers:
```
PROGRESS: Starting Research Phase (3 agents, parallel)
PROGRESS: [Agent 1/3: existing_patterns] Analyzing codebase...
PROGRESS: [Agent 2/3: security_practices] Searching best practices...
PROGRESS: [Agent 3/3: framework_implementations] Comparing libraries...
PROGRESS: [Agent 1/3: existing_patterns] Report created ✓
REPORT_CREATED: specs/reports/existing_patterns/001_auth_patterns.md
PROGRESS: [Agent 2/3: security_practices] Report created ✓
REPORT_CREATED: specs/reports/security_practices/001_best_practices.md
PROGRESS: [Agent 3/3: framework_implementations] Report created ✓
REPORT_CREATED: specs/reports/framework_implementations/001_lua_auth.md
PROGRESS: Research Phase complete - 3 reports verified
```

**5. Documentation Pattern**

Update orchestrate.md with clear examples:

```markdown
### Research Phase: Subagent Report Creation

Each research-specialist subagent creates an individual report file:

**Agent Responsibility**:
- Conduct focused research on assigned topic
- Create report file using Write tool
- Follow specs/reports/{topic}/NNN_report_name.md naming convention
- Return `REPORT_PATH: {path}` in output

**Orchestrator Responsibility**:
- Invoke all research agents in parallel (single message)
- Collect REPORT_PATH outputs from each agent
- Verify report files exist and are readable
- Store report paths (not content) in workflow_state
- Pass report paths to planning phase

**Key Insight**: Orchestrator does NOT aggregate report content. Reports are
independent files. Planning agent reads reports selectively using Read tool.
```

## Potential Challenges

### Challenge 1: Verification Without Breaking Parallelism

**Problem**: If verification happens synchronously after each agent, we lose parallel execution benefit

**Solution**: Batch verification after all agents complete
- Invoke all agents in parallel (Step 2)
- Wait for all to complete (Step 3a)
- Verify all reports in batch (Step 4.5)
- Retry any missing reports (still faster than sequential)

**Trade-off**: Slight delay in detecting missing reports, but preserves ~66% time savings from parallelism

### Challenge 2: Retry Logic Complexity

**Problem**: If retrying failed agents, must maintain topic-to-agent-to-prompt mapping

**Solution**: Store prompts in checkpoint before invocation
```json
{
  "research_phase_data": {
    "agent_prompts": {
      "existing_patterns": "[full prompt]",
      "security_practices": "[full prompt]",
      "framework_implementations": "[full prompt]"
    }
  }
}
```

Then retry using stored prompt:
```bash
RETRY_PROMPT="${AGENT_PROMPTS[$TOPIC]}"
retry_with_backoff invoke_research_agent "$TOPIC" "$RETRY_PROMPT"
```

### Challenge 3: Error Message Clarity

**Problem**: When report missing, current error doesn't identify which subagent failed

**Solution**: Add agent index to progress markers and error messages
```
ERROR: Report missing for Agent 2/3 (topic: security_practices)
Expected: specs/reports/security_practices/001_best_practices.md
Agent output: [show last 100 words of agent output]
Retrying agent invocation...
```

## Conclusion

The current /orchestrate implementation (Option A) is actually the desired approach (Option B) - subagents already create individual reports, and the orchestrator already collects file paths rather than aggregating content. The perceived gap is primarily in documentation and visibility, not functionality.

**Recommended Actions**:

1. **Document Current Behavior** (High Priority)
   - Clarify in orchestrate.md that subagents create individual files
   - Add examples showing REPORT_PATH: output format
   - Explain that orchestrator collects paths, not content

2. **Enhance Progress Visibility** (Medium Priority)
   - Add per-agent progress markers
   - Emit REPORT_CREATED: markers
   - Display report paths as created

3. **Improve Error Recovery** (Low Priority)
   - Add batch verification after all agents complete
   - Implement single retry for missing reports
   - Store agent-to-report mapping in checkpoints

The hybrid approaches (Option C) add complexity without meaningful benefits and are not recommended.

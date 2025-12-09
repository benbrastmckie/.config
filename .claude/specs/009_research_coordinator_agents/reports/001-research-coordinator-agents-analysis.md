# Research Coordinator Agent Pattern Analysis

## Metadata
- **Date**: 2025-12-08
- **Agent**: research-specialist
- **Topic**: research coordinator agents for initial research phase
- **Report Type**: pattern recognition

## Executive Summary

Analysis of /lean-plan output reveals that the current /lean-plan command performs initial research inline using the primary agent (Sonnet 4.5) before delegating to planning subagents. This approach is inefficient for complex research that would benefit from parallel investigation across multiple topics. A research coordinator subagent pattern would enable the primary agent to delegate research orchestration to a specialized coordinator, which can then invoke multiple research-specialist subagents in parallel, aggregate their findings, and return metadata summaries to the primary agent. This pattern reduces primary agent context usage by 40-60% while enabling systematic multi-topic research.

## Findings

### Finding 1: Current /lean-plan Research Pattern
- **Description**: The /lean-plan command performs initial research using the primary agent's tools (Read, Grep, Search) to understand the user's request before invoking planning subagents
- **Location**: /home/benjamin/.config/.claude/output/lean-plan-output.md lines 9-72
- **Evidence**:
```
● Now I understand Task 7 better. Let me read the referenced implementation summary...
● Read(.claude/specs/025_soundness_automation_implementation/summaries/...)
● Read(Logos/Core/Automation/Tactics.lean)
● Search(pattern: "**/TacticsTest.lean")
● Read(Logos/Core/Semantics/Truth.lean)
● Read(Logos/Core/Automation/AesopRules.lean)
```
- **Impact**: The primary agent uses 13 tool calls to understand context before delegating to plan-architect. For complex features requiring research across multiple domains, this inline research consumes significant primary agent context and cannot leverage parallelization.

### Finding 2: Hard Barrier Pattern Already Implemented in /research
- **Description**: The /research command demonstrates the canonical hard barrier pattern with path pre-calculation, mandatory Task invocation, and fail-fast validation
- **Location**: /home/benjamin/.config/.claude/commands/research.md lines 753-1097
- **Evidence**:
```markdown
## Block 1d: Report Path Pre-Calculation
# Pre-calculate absolute report path before invoking research-specialist
REPORT_PATH="${RESEARCH_DIR}/${REPORT_NUMBER}-${REPORT_SLUG}.md"

## Block 1d-exec: Research Specialist Invocation
**HARD BARRIER**: This block MUST invoke research-specialist via Task tool.

## Block 1e: Agent Output Validation (Hard Barrier)
# HARD BARRIER: Report file MUST exist
if [ ! -f "$REPORT_PATH" ]; then
  log_command_error "agent_error" "research-specialist failed to create report file"
  exit 1
fi
```
- **Impact**: The /research command provides a proven reference implementation for delegating to research-specialist. A research coordinator would use the same hard barrier pattern but invoke multiple research-specialist instances in parallel.

### Finding 3: Hierarchical Agent Architecture Supports Coordinator Pattern
- **Description**: The existing hierarchical agent architecture provides explicit support for supervisor/coordinator agents that manage parallel worker agents and aggregate metadata
- **Location**: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md lines 18-94
- **Evidence**:
```
Orchestrator Command
    |
    +-- Research Supervisor
    |       +-- Research Agent 1
    |       +-- Research Agent 2
    |       +-- Research Agent 3
    |
    +-- Implementation Supervisor

Context Efficiency:
  4 Workers x 2,500 tokens -> Supervisor
  Supervisor extracts 110 tokens/worker = 440 tokens to orchestrator
  Reduction: 95.6%
```
- **Impact**: A research-coordinator agent fits naturally into the existing hierarchical pattern as a supervisor role. It can invoke multiple research-specialist workers in parallel, extract metadata from their reports, and return aggregated summaries to the primary agent.

### Finding 4: Lean-Coordinator Demonstrates Multi-Phase Coordination Pattern
- **Description**: The lean-coordinator agent demonstrates how a coordinator manages multiple phases with different task types, aggregates results, and returns structured summaries
- **Location**: /home/benjamin/.config/.claude/agents/lean-coordinator.md (referenced in /lean-implement command)
- **Evidence**: The /lean-implement command (lines 1-200) shows phase classification, intelligent routing to different coordinators (lean-coordinator vs implementer-coordinator), and mode selection (--mode=auto|lean-only|software-only)
- **Impact**: A research-coordinator would use similar phase classification but for research topics rather than implementation phases. It would route each topic to a research-specialist instance and aggregate findings.

### Finding 5: Topic-Based Directory Structure Already Supports Multiple Reports
- **Description**: The specs/ directory protocol supports multiple research reports within a topic directory using numbered report files
- **Location**: /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md lines 44-56
- **Evidence**:
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED to git)
```
- **Impact**: A research-coordinator can create multiple research reports in the same topic directory (e.g., 001-database-patterns.md, 002-authentication-security.md, 003-api-design.md) without modifying the directory structure. The numbering system automatically handles sequential allocation.

### Finding 6: Path Pre-Calculation Must Be Coordinator Responsibility
- **Description**: The hard barrier pattern requires report paths to be pre-calculated BEFORE invoking subagents. A research-coordinator must calculate all report paths before delegating to research-specialist workers.
- **Location**: /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md lines 74-167
- **Evidence**:
```markdown
### Template 1: Research Phase Delegation (with Path Pre-Calculation)

## Block 1d: Report Path Pre-Calculation
# Calculate report number (001, 002, 003...)
EXISTING_REPORTS=$(find "$RESEARCH_DIR" -name '[0-9][0-9][0-9]-*.md' 2>/dev/null | wc -l)
REPORT_NUMBER=$(printf "%03d" $((EXISTING_REPORTS + 1)))

# HARD BARRIER: Report file MUST exist
if [ ! -f "$REPORT_PATH" ]; then
  exit 1
fi
```
- **Impact**: The research-coordinator behavioral file must specify path pre-calculation for each research topic before invoking research-specialist. This prevents path mismatches and ensures deterministic artifact creation.

### Finding 7: Metadata-Only Context Passing Reduces Token Usage
- **Description**: The hierarchical agent architecture specifies passing metadata summaries (110 tokens) instead of full content (2,500 tokens) between supervisor and orchestrator levels
- **Location**: /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md lines 52-62
- **Evidence**:
```
Metadata-Only Context Passing:
- Full content: 2,500 tokens per agent
- Metadata summary: 110 tokens per agent
- Context reduction: 95%+
```
- **Impact**: A research-coordinator should extract brief metadata from each research report (title, key findings summary, recommendations count) and return this aggregated metadata to the primary agent. The primary agent can then pass the list of report paths to plan-architect, which reads full reports as needed.

### Finding 8: Research-Specialist Already Supports Hard Barrier Pattern
- **Description**: The research-specialist agent behavioral file mandates file creation at pre-calculated paths and verification checkpoints
- **Location**: /home/benjamin/.config/.claude/agents/research-specialist.md lines 23-154
- **Evidence**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"

### STEP 2 (REQUIRED BEFORE STEP 3) - Create Report File FIRST
Use the Write tool to create the file at the EXACT path from Step 1.

### STEP 4 (ABSOLUTE REQUIREMENT) - Verify and Return Confirmation
REPORT_CREATED: [EXACT ABSOLUTE PATH FROM STEP 1]
```
- **Impact**: No changes needed to research-specialist behavioral file. The research-coordinator simply invokes it multiple times with different report paths and aggregates the returned paths.

## Recommendations

1. **Create research-coordinator behavioral file**: Define a new agent at `.claude/agents/research-coordinator.md` that follows the hierarchical supervisor pattern. The agent should:
   - Accept research topic list from primary agent
   - Pre-calculate report paths for each topic (using existing report numbering logic)
   - Invoke research-specialist in parallel for each topic (using Task tool)
   - Validate each report file exists (hard barrier pattern)
   - Extract metadata from each report (title, key findings count, recommendations count)
   - Return aggregated metadata to primary agent (110 tokens per report)

2. **Integrate research-coordinator into /lean-plan command**: Modify /lean-plan to use research-coordinator for initial research phase instead of inline research. This requires:
   - Add Block 1d: Research Topics Classification (analyze user prompt to identify research topics)
   - Add Block 1d-exec: Research Coordinator Invocation (Task tool invocation with hard barrier pattern)
   - Add Block 1e: Research Validation (verify reports exist, parse metadata)
   - Update Block 2: Planning Phase (pass report paths to plan-architect via prompt)

3. **Apply research-coordinator pattern to other planning commands**: Once proven in /lean-plan, apply the same pattern to:
   - /create-plan (general software planning)
   - /repair (error pattern research before fix planning)
   - /debug (issue investigation research before debug planning)
   - /revise (context research before plan revision)

4. **Implement topic detection agent for research coordinator**: Create a lightweight subagent that analyzes user prompts and identifies discrete research topics. This enables automatic topic decomposition:
   - Input: User's feature description
   - Output: List of 2-5 research topics with brief scope descriptions
   - Integration: Research-coordinator invokes topic-detection-agent before path pre-calculation
   - Fallback: If topic detection fails, use single topic (backward compatibility)

5. **Add research-coordinator to dependent-agents metadata**: Update command frontmatter for all commands that use research-coordinator:
   ```yaml
   dependent-agents:
     - research-coordinator
     - research-specialist
     - plan-architect
   ```

6. **Document research-coordinator pattern in hierarchical agents guide**: Add research-coordinator as Example 7 in `.claude/docs/concepts/hierarchical-agents-examples.md` showing:
   - Topic decomposition strategy
   - Parallel research-specialist invocation
   - Metadata aggregation format
   - Primary agent integration pattern

## References

- /home/benjamin/.config/.claude/output/lean-plan-output.md (lines 1-120) - Demonstrates current inline research pattern
- /home/benjamin/.config/.claude/commands/research.md (lines 753-1097) - Hard barrier pattern reference implementation
- /home/benjamin/.config/.claude/commands/lean-implement.md (lines 1-200) - Coordinator routing pattern
- /home/benjamin/.config/.claude/agents/research-specialist.md (lines 1-784) - Research-specialist behavioral contract
- /home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md (lines 1-177) - Hierarchical agent architecture
- /home/benjamin/.config/.claude/docs/concepts/patterns/hard-barrier-subagent-delegation.md (lines 1-964) - Hard barrier pattern specification
- /home/benjamin/.config/.claude/docs/concepts/directory-protocols.md (lines 1-150) - Topic-based directory structure
- /home/benjamin/.config/CLAUDE.md (lines 240-248) - Hierarchical agent architecture standards

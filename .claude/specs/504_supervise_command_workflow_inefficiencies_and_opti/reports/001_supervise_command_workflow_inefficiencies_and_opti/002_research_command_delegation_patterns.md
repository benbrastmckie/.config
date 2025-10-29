# Research Command Delegation Patterns

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Research Command Delegation Patterns
- **Report Type**: Codebase analysis
- **Focus**: Analyzing /research command's successful delegation architecture and comparing with /supervise

## Executive Summary

This report examines the /research command's delegation patterns and identifies why it achieves superior performance compared to /supervise. The /research command uses a hierarchical multi-agent pattern with standardized metadata extraction and three distinct phases (decomposition, parallel agent invocation, and synthesis) that enable efficient parallel research with 95% context reduction. The command achieves this through explicit path pre-calculation, consistent behavioral injection, and metadata-only artifact passing - patterns that /supervise could adopt.

## Findings

### 1. Clear Orchestrator vs Executor Role Separation

The /research command explicitly defines orchestrator responsibilities separate from executor (agent) responsibilities (.claude/commands/research.md:11-29):

**Orchestrator Pattern**:
- Does NOT execute research directly (line 16: "DO NOT execute research yourself using Read/Grep/Write tools")
- Uses Task tool ONLY for agent delegation
- Delegates topic decomposition to agents (line 69-73)
- Pre-calculates all artifact paths before agent invocation (line 149-220)
- Uses Read tool ONLY for post-delegation verification (line 25-27)

**Tool Usage by Phase**:
- Delegation Phase (Steps 1-3): Task + Bash only for decomposition and path calculation
- Verification Phase (Steps 4-6): Bash + Read only for verification, NOT research

This contrasts with /supervise (.claude/commands/supervise.md:1-40) which requires similar role separation but implements it less explicitly in startup sequence.

### 2. Hierarchical Multi-Agent Pattern with Parallel Execution

/research uses a three-phase hierarchical pattern (.claude/commands/research.md:36-221):

**Phase 1: Topic Decomposition** (STEP 1, lines 43-90)
- Bash sourcing: 5 utility libraries (topic-decomposition.sh, artifact-creation.sh, template-integration.sh, metadata-extraction.sh, overview-synthesis.sh)
- Complexity-based subtopic generation (2-4 subtopics)
- Task tool invocation for decomposition agent

**Phase 2: Path Pre-Calculation** (STEP 2, lines 92-221)
- ALL artifact paths calculated before agent invocation
- Mandatory verification checkpoints after EACH step (lines 135-145, 173-177, 198-212)
- Absolute path validation (lines 200-211)
- Example shows explicit path injection: `/home/benjamin/.config/.claude/specs/042_authentication/reports/001_jwt_implementation_patterns.md` (line 267)

**Phase 3: Parallel Agent Invocation** (STEP 3, lines 223-279)
- Multiple Task calls in single message for parallel execution (line 229: "multiple Task calls in single message")
- Concrete example with exact path injection (lines 257-279)
- Behavioral guidelines reference: `.claude/agents/research-specialist.md`

### 3. Research-Specialist Agent Behavioral Injection Pattern

/research provides complete agent invocation template (.claude/commands/research.md:233-255):

```
- subagent_type: "general-purpose"
- description: "Research [subtopic] with mandatory artifact creation"
- timeout: 300000  # 5 minutes per agent
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [subtopic name]
    - Report Path: [absolute pre-calculated path]
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    **YOUR ROLE**: You are a SUBAGENT executing research for ONE subtopic.
    - The ORCHESTRATOR calculated your report path (injected above)
    - DO NOT use Task tool to orchestrate other agents
    - STAY IN YOUR LANE: Research YOUR subtopic only

    **CRITICAL**: Create report file at EXACT path provided above.
```

Key aspects:
- Explicit role statement (lines 247-250)
- Path pre-calculation and injection (line 244)
- CRITICAL enforcement for file creation (line 252)
- Return format specification (line 255: `REPORT_CREATED: [EXACT_ABSOLUTE_PATH]`)

### 4. Metadata Extraction with 95% Context Reduction

/research achieves context efficiency through explicit metadata extraction phase (.claude/commands/research.md:388-413):

**Metadata Extraction Pattern** (lines 388-413):
- "Extract metadata from each verified report (95% context reduction)" (line 396)
- "Extract metadata (95% context reduction: 5,000 → 250 tokens)" (line 399)
- "context usage reduced 95%" (line 403)
- Uses `extract_report_metadata()` function from metadata-extraction.sh library
- Stores metadata in associative array REPORT_METADATA for next phase

**Context Reduction Target**:
- Per-artifact reduction: 5,000 tokens → 250 tokens (95% reduction)
- Cumulative context estimate: metadata_tokens + overview_tokens (lines 407-411)
- Target: <30% of context window throughout workflow (line 411)

### 5. Fallback and Recovery Mechanisms

/research uses fallback mechanisms for transient failures (.claude/commands/research.md:321-383):

**Fallback Creation Pattern**:
- Waits for agent completion, then checks file existence (lines 309-324)
- Retry logic: 3 attempts with 500ms delay between attempts (lines 310-319)
- For missing reports: Creates fallback minimal report (lines 327-356)
- Partial failure handling: Allows continuation if ≥50% success (lines 374-382)

**Fallback Report Structure** (lines 334-350):
```markdown
# Research Report: ${subtopic}

## Status
Primary research agent failed to create this report.

## Fallback Action
This minimal report was auto-generated to maintain workflow continuity.

## Next Steps
- Review other subtopic reports for related findings
- Consider re-running research for this specific subtopic
- Check agent logs for failure details
```

### 6. Startup Sequence Efficiency

/research startup sequence (STEP 1-3) is more efficient than /supervise startup:

**/research Startup** (lines 36-279):
1. **STEP 1**: Topic decomposition (2 bash commands sourcing 5 libraries)
2. **STEP 2**: Path pre-calculation (3 bash commands sourcing 2 libraries)
3. **STEP 3**: Parallel agent invocation (1 Task tool call per subtopic)
- **Total steps before delegation**: 3 steps
- **Total bash operations**: ~15 lines of bash code
- **Libraries sourced**: 5 libraries (topic-decomposition, artifact-creation, template-integration, metadata-extraction, overview-synthesis)

**/supervise Startup** (lines 637-987):
1. **STEP 1**: Parse workflow description
2. **STEP 2**: Detect workflow scope
3. **STEP 3-7**: Determine location, calculate metadata, create directory, pre-calculate paths, initialize tracking arrays
- **Total steps before delegation**: 7 steps
- **Total bash operations**: ~100+ lines of bash code for location detection, validation, directory creation
- **Libraries sourced**: 7 libraries (workflow-detection, error-handling, checkpoint-utils, unified-logger, unified-location-detection, metadata-extraction, context-pruning)

### 7. Agent Invocation Architecture Differences

**Research-Only Focus**: /research delegates decomposition to agents (line 69: "USE the Task tool to execute decomposition") whereas /supervise performs decomposition inline.

**Single Responsibility**: /research agents have single responsibility:
- research-specialist: One subtopic research per agent
- research-synthesizer: Overview synthesis after all subtopics

**Research-and-Plan Pattern**: /research integrates with spec-updater for cross-references (.claude/commands/research.md:570-632), creating explicit linkage between research and planning phases.

### 8. Comparison Summary: /research vs /supervise Research Phase

| Aspect | /research | /supervise |
|--------|-----------|-----------|
| Orchestrator role clarity | Explicit (lines 11-29) | Documented but spread across 7 steps |
| Decomposition | Delegated to agents | Inline keyword-based scoring |
| Path pre-calculation | Before agents invoked (STEP 2) | Before agents invoked (STEP 5-6) |
| Parallel research invocation | Single message, multiple Task calls | Single message, multiple Task calls |
| Metadata extraction | Explicit 95% reduction phase (lines 388-413) | Not implemented (context pruning not applied) |
| Fallback mechanism | Fallback report creation for transient failures | Similar pattern but part of larger orchestration |
| Agent behavioral injection | Complete template provided (lines 233-255) | Similar templates across multiple phases |
| Overview synthesis | Conditional based on workflow scope (lines 1207-1257) | Conditional based on workflow scope |
| Cross-reference updates | Explicit spec-updater phase (lines 570-632) | Not implemented |

## Recommendations

### 1. Adopt /research's Explicit Orchestrator Role Definition for /supervise Phase 0

/supervise Phase 0 startup sequence should be reorganized to match /research's explicit pattern:

**Current State**: Phase 0 spans lines 637-987 with 7 sequential steps mixed with location detection, directory creation, and path calculation.

**Recommended Change**: Consolidate Phase 0 into 3 explicit steps matching /research:
- STEP 1: Workflow scope detection (already exists, lines 697-760)
- STEP 2: Location and path pre-calculation (consolidate current STEPS 3-6, lines 762-872)
- STEP 3: Directory structure creation (already exists, lines 870-929)

**Expected Impact**:
- Reduced complexity from 7 steps to 3
- Earlier path validation before agent invocation
- Clearer responsibility boundaries

### 2. Implement Metadata Extraction Phase in /supervise Research Phase

/supervise Phase 1 should extract report metadata after research completion, similar to /research lines 388-413:

**Current State**: Research phase (lines 989-1271) verifies files but does not extract metadata.

**Recommended Change**: After verifying all research reports (line 1170-1203):
```bash
# Extract metadata from each verified report (95% context reduction)
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "$report")
  REPORT_METADATA["$report"]="$METADATA"
done
```

**Expected Impact**:
- 95% context reduction for research reports (5,000 → 250 tokens each)
- Lower context usage for Phase 2 planning invocation
- Better alignment with forward message pattern for metadata passing

### 3. Apply /research's Explicit Behavioral Injection Template to /supervise Phase 1-4 Agents

/supervise currently provides agent templates inline within phase sections. /research demonstrates more explicit template structure:

**Current Pattern** (/supervise phase 1, lines 1044-1067): Templates are inline with less complete examples.

**Recommended Pattern** (/research style): Provide complete, concrete examples showing:
- Exact subagent_type, description, timeout values
- Complete workflow-specific context injection
- Explicit role statement for agents
- Return format specification

**Expected Impact**:
- More consistent agent behavior across commands
- Reduced agent errors from incomplete context
- Better alignment with research-specialist pattern

### 4. Consolidate /supervise's Path Pre-Calculation with Location Detection

/supervise currently pre-calculates paths in multiple places (STEP 6, lines 931-972) after location detection (STEPS 3-5).

**Recommended Change**: Combine location detection and path calculation into single unified STEP 2, similar to /research's STEP 2 approach (lines 92-221).

**Expected Impact**:
- Reduced Phase 0 execution time
- Single location for path validation
- Earlier detection of configuration issues

### 5. Implement Conditional Overview Synthesis Decision Logic

/research demonstrates explicit decision logic for overview synthesis (lines 1207-1257):
```bash
if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  # Create overview
else
  SKIP_REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT")
fi
```

/supervise should adopt this pattern for Phase 1 overview synthesis (current lines 1206-1257).

**Expected Impact**:
- More explicit workflow scope handling
- Clearer distinction between research-only and research-and-plan workflows
- Reduced unnecessary overview creation

### 6. Add Explicit Spec-Updater Integration to /research Phase 6

/research includes spec-updater invocation (lines 570-632) for cross-reference management. This should be standardized across all research workflows.

**Expected Impact**:
- Bidirectional linking between research reports and plans
- Automatic cross-reference maintenance
- Better artifact organization

## References

- /home/benjamin/.config/.claude/commands/research.md - Complete /research command source (902 lines)
- /home/benjamin/.config/.claude/commands/supervise.md - Complete /supervise command source (2,275 lines)
- /home/benjamin/.config/.claude/agents/research-specialist.md - Research specialist behavioral guidelines (671 lines)
- /home/benjamin/.config/.claude/agents/research-synthesizer.md - Research synthesizer behavioral guidelines
- /home/benjamin/.config/.claude/lib/topic-decomposition.sh - Topic decomposition utility (referenced at line 51)
- /home/benjamin/.config/.claude/lib/metadata-extraction.sh - Metadata extraction utility (referenced at line 54)
- /home/benjamin/.config/.claude/lib/unified-location-detection.sh - Location detection utility (referenced in supervise.md:325)
- /home/benjamin/.config/CLAUDE.md - Project standards and architecture documentation (lines 275-340: Hierarchical Agent Architecture)

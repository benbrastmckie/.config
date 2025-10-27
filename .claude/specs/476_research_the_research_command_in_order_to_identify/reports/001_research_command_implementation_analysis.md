# Research Command Implementation Analysis

## Metadata
- **Date**: 2025-10-26
- **Agent**: research-specialist
- **Topic**: /research command implementation analysis
- **Report Type**: codebase analysis

## Executive Summary

The /research command implements a hierarchical multi-agent pattern that decomposes research topics into 2-4 focused subtopics, delegates parallel research to specialized agents, and synthesizes findings into a comprehensive overview. The architecture achieves 95% context reduction through metadata-only passing, uses mandatory verification checkpoints at each step, and integrates with unified location detection for lazy directory creation. Performance characteristics include 40-60% time savings through parallel execution and sophisticated error handling with fallback mechanisms.

## Findings

### 1. Command Architecture and Structure

**File Location**: `/home/benjamin/.config/.claude/commands/research.md` (lines 1-585)

The /research command follows a 6-step orchestration pattern:

1. **Topic Decomposition** (Step 1, lines 43-84): Uses `calculate_subtopic_count()` from `topic-decomposition.sh` to determine 2-4 subtopics based on word count heuristic
2. **Path Pre-Calculation** (Step 2, lines 86-179): Calculates absolute paths for all subtopic reports BEFORE agent invocation using unified location detection
3. **Parallel Agent Invocation** (Step 3, lines 181-245): Invokes multiple research-specialist agents simultaneously with pre-calculated paths
4. **Report Verification** (Step 4, lines 246-289): Validates all subtopic reports exist with fallback search mechanism
5. **Overview Synthesis** (Step 5, lines 291-360): Invokes research-synthesizer agent to create OVERVIEW.md
6. **Cross-Reference Updates** (Step 6, lines 362-446): Invokes spec-updater agent for bidirectional linking

**Key Design Principle**: The orchestrator NEVER executes research directly - it only uses Task tool for delegation and Read tool for post-verification (lines 16-27).

### 2. Agent Invocation Patterns

**Hierarchical Multi-Agent Pattern** (lines 490-523):

The command uses three specialized agents in sequence:

**research-specialist** (lines 194-239):
- Tools: Read, Write, Grep, Glob, WebSearch, WebFetch
- Invoked: Multiple times in parallel (one per subtopic)
- Input: Absolute pre-calculated report path from orchestrator
- Output: `REPORT_CREATED: [path]` confirmation signal
- Context injection: Behavioral file `/home/benjamin/.config/.claude/agents/research-specialist.md` (line 202)

**research-synthesizer** (lines 315-355):
- Tools: Read, Write
- Invoked: Once after all subtopics complete
- Input: Overview path + array of verified subtopic paths
- Output: `OVERVIEW_CREATED: [path]` confirmation signal
- Special requirement: Creates OVERVIEW.md (ALL CAPS, line 344)
- Context injection: Behavioral file `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (line 323)

**spec-updater** (lines 375-424):
- Purpose: Updates cross-references between overview, subtopics, and related plans
- Returns: Cross-reference status summary

**Anti-Pattern Prevention**: Agent prompts are imperative ("EXECUTE NOW", "ABSOLUTE REQUIREMENT") with numbered STEP instructions (lines 215-229), avoiding documentation-only YAML blocks that cause 0% delegation rate.

### 3. Context Management Strategies

**Path Pre-Calculation Pattern** (lines 118-154):

The command implements mandatory path calculation BEFORE agent invocation:

```bash
declare -A SUBTOPIC_REPORT_PATHS
RESEARCH_SUBDIR=$(create_research_subdirectory "$TOPIC_DIR" "${TOPIC_NAME}_research")

for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
done
```

**WHY THIS MATTERS** (line 123): Research-specialist agents require EXACT absolute paths to create files in correct locations. Skipping this causes path mismatch errors.

**Verification Checkpoint** (lines 158-169): Validates all paths are absolute before proceeding to agent invocation.

**95% Context Reduction** (line 579): Each research-specialist agent focuses on a narrow subtopic rather than the full research scope, dramatically reducing context window usage.

### 4. Metadata Extraction Patterns

The command uses metadata-only passing rather than full content:

**Agent Output Signals** (lines 229, 346):
- `REPORT_CREATED: [absolute-path]` from research-specialist agents
- `OVERVIEW_CREATED: [absolute-path]` from research-synthesizer agent
- No summary text returned - orchestrator reads files directly if needed

**research-synthesizer Metadata** (research-synthesizer.md lines 179-218):
- Extracts 100-word summary from overview for planning phase
- Achieves 99% context reduction while maintaining key information
- Returns structured metadata: reports synthesized count, cross-report patterns, recommended approach

**File References** (research-specialist.md line 159): All file references must include line numbers (format: file.lua:123)

### 5. Current Performance Characteristics

**Parallel Execution Benefits** (lines 574-580):
- **40-60% Faster**: Parallel research vs sequential
- **Granular Coverage**: Each subtopic gets focused attention
- **95% Context Reduction**: Each agent has narrow scope
- **Better Organization**: Individual reports easier to maintain

**Subtopic Count Heuristic** (topic-decomposition.sh lines 64-80):
- 1-3 words: 2 subtopics
- 4-6 words: 3 subtopics
- 7+ words: 4 subtopics

**Agent Timeouts**:
- research-specialist: 300000ms (5 minutes, line 197)
- research-synthesizer: 180000ms (3 minutes, line 317)

### 6. Library Dependencies and Utilities

**Core Libraries** (lines 51-53, 93):

1. **topic-decomposition.sh** (lines 1-86):
   - `decompose_research_topic()`: Generates LLM prompt for topic decomposition
   - `validate_subtopic_name()`: Validates snake_case format, max 50 chars
   - `calculate_subtopic_count()`: Word count-based heuristic

2. **artifact-creation.sh** (lines 1-267):
   - `create_topic_artifact()`: Creates numbered artifacts with lazy creation pattern
   - `get_next_artifact_number()`: Finds highest NNN number in directory
   - `create_research_subdirectory()`: Creates numbered research subdirectory

3. **unified-location-detection.sh** (lines 1-100):
   - `perform_location_detection()`: Determines topic directory with JSON output
   - `ensure_artifact_directory()`: Lazy directory creation pattern
   - Precedence: CLAUDE_PROJECT_DIR > git root > current directory

**Lazy Directory Creation** (unified-location-detection.sh lines 11-13):
- Creates artifact directories only when files are written
- Eliminates empty subdirectories (reduced from 400-500 to 0)
- 80% reduction in mkdir calls during location detection

### 7. Error Handling and Recovery Mechanisms

**Verification Checkpoint Pattern** (lines 246-289):

After all agents complete, the orchestrator verifies reports exist:

```bash
declare -A VERIFIED_PATHS
declare -a FAILED_AGENTS
VERIFICATION_ERRORS=0

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [ -f "$EXPECTED_PATH" ]; then
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    # Fallback: Search for report in research subdirectory
    FOUND_PATH=$(find "$RESEARCH_SUBDIR" -name "*${subtopic}*.md" -type f | head -n 1)
  fi
done
```

**Fallback Search Mechanism** (lines 269-280): If report not found at expected path, searches research subdirectory by subtopic name pattern.

**research-specialist Error Handling** (research-specialist.md lines 261-320):
- **Network Errors**: 3 retries with exponential backoff (1s, 2s, 4s)
- **File Access Errors**: 2 retries with 500ms delay
- **Search Timeouts**: 1 retry with broader/narrower scope
- **Graceful Degradation**: Provides partial results with clear limitations

**Mandatory Directory Creation** (research-specialist.md lines 48-69):
```bash
source .claude/lib/unified-location-detection.sh
ensure_artifact_directory "$REPORT_PATH" || {
  echo "ERROR: Failed to create parent directory for report" >&2
  exit 1
}
```

### 8. File Creation Patterns and Verification

**research-specialist File Creation Protocol** (research-specialist.md lines 73-118):

1. **Create File FIRST** (Step 2): Creates report file with initial structure BEFORE conducting research
2. **WHY THIS MATTERS** (line 79): Guarantees artifact creation even if research encounters errors
3. **Incremental Updates** (Step 3): Uses Edit tool to update file during research, never accumulating in memory
4. **Mandatory Verification** (Step 4): Verifies file exists before returning confirmation

**28 Completion Criteria** (research-specialist.md lines 322-411):
- 5 file creation requirements (absolute path, >500 bytes, Write tool used)
- 7 content completeness requirements (executive summary, findings, 3+ recommendations)
- 5 research quality requirements (3+ sources, evidence-based conclusions)
- 6 process compliance requirements (all steps completed, checkpoints passed)
- 5 return format requirements (exact confirmation format)

**Progress Streaming** (research-specialist.md lines 201-238):

Mandatory progress markers during research:
- `PROGRESS: Creating report file at [path]`
- `PROGRESS: Starting research on [topic]`
- `PROGRESS: Searching codebase for [pattern]`
- `PROGRESS: Analyzing [N] files found`
- `PROGRESS: Updating report with findings`
- `PROGRESS: Research complete, report verified`

**Verification Commands** (research-specialist.md lines 362-377):
```bash
# File exists check
test -f "$REPORT_PATH" || echo "CRITICAL ERROR: File not found"

# File size check (minimum 500 bytes)
FILE_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
[ "$FILE_SIZE" -ge 500 ] || echo "WARNING: File too small ($FILE_SIZE bytes)"

# Content completeness check (not just placeholder)
grep -q "placeholder\|TODO\|TBD" "$REPORT_PATH" && echo "WARNING: Placeholder text found"
```

### 9. Cross-Reference Management

**Spec-Updater Integration** (lines 362-446):

The orchestrator invokes spec-updater agent to establish bidirectional links:

**Required Tasks** (lines 394-414):
1. Check if related plan exists in topic's plans/ subdirectory
2. If plan exists: Add overview report reference to plan metadata
3. For each subtopic report: Add link to overview in 'Related Reports' section
4. For overview report: Verify links to all subtopics are relative and correct
5. Verify all cross-references are bidirectional

**Link Format Requirements** (research-synthesizer.md lines 236-242):
- ALWAYS use relative paths (e.g., `./001_subtopic.md`)
- NEVER use absolute paths (maintains portability)
- Research Structure section provides immediate navigation to all subtopics

**Return Format** (lines 437-445):
```
Cross-references updated:
✓ Overview report linked to 4 subtopic reports
✓ Subtopic reports linked to overview
✓ Overview linked to plan: specs/042_auth/plans/001_implementation.md
✓ Plan metadata updated with research references
✓ All links validated
```

### 10. Integration with Larger Workflow

**Alignment with /orchestrate** (lines 581-583): The /orchestrate command's research phase uses the SAME hierarchical multi-agent pattern, ensuring consistency across all research workflows.

**Report Structure** (lines 447-472):

Two types of reports created:

1. **Individual Subtopic Reports**: Standard structure with executive summary, findings, recommendations, references
   - Path: `specs/{NNN_topic}/reports/{NNN_research}/NNN_subtopic_name.md`

2. **Overview Report (OVERVIEW.md)**: Synthesizes all subtopic findings
   - Path: `specs/{NNN_topic}/reports/{NNN_research}/OVERVIEW.md`
   - Sections: Executive summary, research structure (navigation), cross-cutting themes, detailed findings by topic, recommended approach, constraints/trade-offs

**Special Filename Convention** (line 470): Overview file always named OVERVIEW.md (ALL CAPS) to distinguish it as final synthesis report, not another numbered subtopic.

## Recommendations

### 1. Document Path Pre-Calculation Pattern as Reusable Pattern

**Rationale**: The mandatory path pre-calculation pattern (lines 118-154) is a critical best practice that prevents path mismatch errors and enables parallel agent execution. This pattern should be extracted to `.claude/docs/concepts/patterns/path-precalculation.md` for reuse in other orchestration commands.

**Implementation**: Create pattern documentation with:
- Problem statement: Agents need exact file paths before creation
- Solution: Calculate all paths in orchestrator before agent invocation
- Verification checkpoint: Validate all paths are absolute
- Benefits: Enables parallel execution, prevents path errors, improves reliability

### 2. Add Performance Metrics Logging

**Rationale**: The command achieves 40-60% time savings and 95% context reduction, but these metrics are not tracked. Adding instrumentation would validate these claims and identify optimization opportunities.

**Implementation**:
- Log subtopic count, parallel execution time, total research time
- Track agent completion rates and fallback invocations
- Record file sizes for context reduction validation
- Store metrics in `.claude/data/logs/research-performance.log`

### 3. Enhance Subtopic Count Heuristic with LLM-Based Complexity Analysis

**Rationale**: Current word count heuristic (lines 64-80 in topic-decomposition.sh) is simplistic. A topic like "authentication" (1 word) gets 2 subtopics, but may need 4 for comprehensive coverage.

**Implementation**:
- Add `analyze_topic_complexity()` function that uses Task tool
- Analyze topic for: breadth (how many distinct aspects), depth (how detailed), interdependencies
- Return recommended subtopic count (2-4) with justification
- Fall back to word count heuristic if LLM analysis fails

### 4. Implement Agent Output Validation Beyond File Existence

**Rationale**: Current verification only checks if files exist (line 263). It doesn't validate content quality, structure completeness, or whether agents followed the 28 completion criteria.

**Implementation**:
- Add `validate_report_quality()` function in orchestrator
- Check: File size >500 bytes, no placeholder text, has 3+ recommendations, includes file references with line numbers
- If validation fails: Emit warning and suggest manual review
- Track validation failures in performance metrics

### 5. Extract "Imperative Agent Invocation" as Explicit Pattern Documentation

**Rationale**: The command demonstrates excellent use of imperative instructions ("EXECUTE NOW", "ABSOLUTE REQUIREMENT", numbered STEP blocks) that prevent the 0% delegation anti-pattern. This should be formalized as a reusable pattern.

**Implementation**: Enhance `.claude/docs/concepts/patterns/behavioral-injection.md` with:
- Required elements: Imperative language, numbered steps, explicit checkpoints
- Anti-pattern: Documentation-only YAML blocks wrapped in code fences
- Example: Show research command's agent invocation template (lines 194-239)
- Verification: How to confirm agents are executing vs just reading documentation

### 6. Add Timeout Configuration Based on Research Complexity

**Rationale**: All research-specialist agents use 5-minute timeout regardless of subtopic complexity. Simple research might complete in 1 minute, complex research might need 10 minutes.

**Implementation**:
- Add `calculate_agent_timeout()` function
- Factors: Codebase size, subtopic scope (narrow vs broad), whether web research required
- Range: 120000ms (2 min) to 600000ms (10 min)
- Pass calculated timeout to Task invocation

### 7. Strengthen Fallback Search Mechanism with Fuzzy Matching

**Rationale**: Current fallback uses exact subtopic name pattern (line 271). If agent creates file with slightly different name, fallback fails.

**Implementation**:
- Use fuzzy string matching (Levenshtein distance or similar)
- Search for files with >70% similarity to expected subtopic name
- If multiple matches found: Select most recent by timestamp
- Log all fallback invocations for analysis

## References

### Command Files
- `/home/benjamin/.config/.claude/commands/research.md` (lines 1-585) - Main command implementation

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 1-671) - Subtopic research agent with 28 completion criteria
- `/home/benjamin/.config/.claude/agents/research-synthesizer.md` (lines 1-259) - Overview synthesis agent

### Library Dependencies
- `/home/benjamin/.config/.claude/lib/topic-decomposition.sh` (lines 1-86) - Topic decomposition and validation utilities
- `/home/benjamin/.config/.claude/lib/artifact-creation.sh` (lines 1-267) - Artifact creation with lazy directory pattern
- `/home/benjamin/.config/.claude/lib/unified-location-detection.sh` (lines 1-100) - Project root and specs directory detection

### Related Documentation
- `.claude/docs/concepts/patterns/behavioral-injection.md` - Agent invocation pattern documentation
- `.claude/docs/concepts/patterns/verification-fallback.md` - Verification checkpoint pattern
- `.claude/docs/concepts/patterns/checkpoint-recovery.md` - State preservation pattern
- `.claude/docs/concepts/hierarchical_agents.md` - Hierarchical agent architecture guide

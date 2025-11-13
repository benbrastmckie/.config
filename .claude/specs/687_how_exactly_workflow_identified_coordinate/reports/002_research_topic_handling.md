# Research Topic Handling in /coordinate

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Research topic identification, filename generation, and prompt construction in /coordinate
- **Report Type**: Codebase analysis

## Executive Summary

The /coordinate command uses a sophisticated **comprehensive LLM-based classification** system (Claude Haiku 4.5) that identifies research topics, determines complexity, and generates descriptive subtopic names in a single call. Research topics flow from `sm_init()` → `workflow-initialization.sh` → agent prompt injection, with report filenames dynamically allocated to exactly match research complexity (1-4 topics). The system eliminates generic "Topic N" naming through semantic analysis, replacing it with descriptive topic names based on workflow context.

## Findings

### 1. Research Topic Identification Flow

**Primary Mechanism: Comprehensive LLM Classification** (`workflow-state-machine.sh:334-452`)

The topic identification happens in `sm_init()` via unified workflow scope detection:

```bash
# workflow-state-machine.sh:350-366
local classification_result
if classification_result=$(classify_workflow_comprehensive "$workflow_desc" 2>/dev/null); then
  # Parse JSON response with THREE dimensions
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
  RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
  RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

  export WORKFLOW_SCOPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON
fi
```

**Key Architecture Decision**: Single comprehensive call provides:
- `workflow_type`: Scope detection (research-only, research-and-plan, full-implementation, etc.)
- `research_complexity`: Integer 1-4 indicating number of research subtopics needed
- `subtopics`: Array of descriptive topic names (NOT generic "Topic N")

**LLM Prompt Construction** (`workflow-llm-classifier.sh:168-182`):

```bash
json_input=$(jq -n \
  --arg desc "$workflow_description" \
  '{
    "task": "classify_workflow_comprehensive",
    "description": $desc,
    "instructions": "...research_complexity (integer 1-4 indicating number of research subtopics needed),
                     subtopics (array of descriptive subtopic names matching complexity count)...
                     Subtopics should be descriptive and actionable (not generic 'Topic N')."
  }')
```

**Fallback Mechanisms** (lines 388-416):

1. **Regex-only fallback** if LLM classification fails (lines 369-376)
2. **Generic topic detection** checks for "Topic N" pattern (lines 390-393)
3. **Context-aware descriptive generation** if generic detected (lines 395-416):
   - **research-and-revise**: Extract from existing plan content (`generate_descriptive_topics_from_plans()`)
   - **research-and-plan/full-implementation**: Analyze workflow description for key concepts (`generate_descriptive_topics_from_description()`)

**Example Output** (from classification):
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "subtopics": [
    "State-based orchestration implementation architecture",
    "Performance optimization opportunities and integration patterns"
  ],
  "reasoning": "User wants to understand how coordinate handles research topics (research-and-plan intent)"
}
```

### 2. Report Filename Generation

**Dynamic Allocation** (`workflow-initialization.sh:383-408`):

Report paths are **just-in-time allocated** to exactly match `RESEARCH_COMPLEXITY`:

```bash
# workflow-initialization.sh:394-408
local -a report_paths
for i in $(seq 1 "$research_complexity"); do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export individual REPORT_PATH_0, REPORT_PATH_1, etc.
for i in $(seq 0 $((research_complexity - 1))); do
  export "REPORT_PATH_$i=${report_paths[$i]}"
done

export REPORT_PATHS_COUNT="$research_complexity"
```

**Filename Pattern**:
- Initial allocation: `001_topic1.md`, `002_topic2.md`, etc. (generic placeholder)
- **Agent-created filenames**: Research-specialist agents create **descriptive filenames**
- **Dynamic discovery** (`coordinate.md:685-714`): Discovers actual agent-created files after research phase

**Discovery Mechanism** (lines 685-714):

```bash
# coordinate.md:685-714
DISCOVERED_REPORTS=()
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  PATTERN=$(printf '%03d' $i)
  FOUND_FILE=$(find "$REPORTS_DIR" -maxdepth 1 -name "${PATTERN}_*.md" -type f | head -1)

  if [ -n "$FOUND_FILE" ]; then
    DISCOVERED_REPORTS+=("$FOUND_FILE")
    DISCOVERY_COUNT=$((DISCOVERY_COUNT + 1))
  else
    # Keep original generic path if no file discovered
    DISCOVERED_REPORTS+=("${REPORT_PATHS[$i-1]}")
  fi
done

REPORT_PATHS=("${DISCOVERED_REPORTS[@]}")
```

**Key Design**: Pre-calculated generic paths are **reconciled** with agent-created descriptive filenames via filesystem discovery.

### 3. Prompt Construction for Research Agents

**Topic Name Injection** (`coordinate.md:503-523`):

Descriptive topic names from `RESEARCH_TOPICS_JSON` are extracted and exported as individual variables:

```bash
# coordinate.md:503-523
# Reconstruct RESEARCH_TOPICS array from JSON state
if [ -n "${RESEARCH_TOPICS_JSON:-}" ]; then
  mapfile -t RESEARCH_TOPICS < <(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]' 2>/dev/null || true)
else
  # Fallback: Generic names
  RESEARCH_TOPICS=("Topic 1" "Topic 2" "Topic 3" "Topic 4")
fi

# Prepare variables for conditional agent invocations (1-4)
for i in $(seq 1 4); do
  topic_index=$((i-1))
  if [ $topic_index -lt ${#RESEARCH_TOPICS[@]} ]; then
    export "RESEARCH_TOPIC_${i}=${RESEARCH_TOPICS[$topic_index]}"
  else
    export "RESEARCH_TOPIC_${i}=Topic ${i}"  # Fallback
  fi
  export "AGENT_REPORT_PATH_${i}=${!REPORT_PATH_VAR}"
done
```

**Agent Invocation Template** (`coordinate.md:535-554`):

```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $RESEARCH_TOPIC_1
    - Report Path: $AGENT_REPORT_PATH_1
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Conditional Invocation Control** (`coordinate.md:531-623`):

Explicit `IF RESEARCH_COMPLEXITY >= N` guards control agent invocations:
- **IF RESEARCH_COMPLEXITY >= 1**: Invoke agent 1 (always true)
- **IF RESEARCH_COMPLEXITY >= 2**: Invoke agent 2 (true for complexity 2-4)
- **IF RESEARCH_COMPLEXITY >= 3**: Invoke agent 3 (true for complexity 3-4)
- **IF RESEARCH_COMPLEXITY >= 4**: Invoke agent 4 (or triggers hierarchical supervision)

### 4. Relationship Between RESEARCH_TOPICS_JSON and REPORT_PATHS

**Two-Tier System**:

1. **RESEARCH_TOPICS_JSON** (Semantic Layer):
   - Source: LLM classification (`classify_workflow_comprehensive()`)
   - Format: JSON array of descriptive strings
   - Purpose: Semantic topic names for agent prompts
   - Example: `["Implementation architecture", "Integration patterns"]`

2. **REPORT_PATHS** (File System Layer):
   - Source: Path pre-calculation (`initialize_workflow_paths()`)
   - Format: Array of absolute file paths
   - Purpose: Target file locations for agent outputs
   - Example: `["/path/specs/687_topic/reports/001_architecture.md", ...]`

**Mapping**:
```
RESEARCH_TOPICS[0] "Implementation architecture"  → REPORT_PATH_0 /.../.../001_architecture.md
RESEARCH_TOPICS[1] "Integration patterns"         → REPORT_PATH_1 /.../.../002_integration.md
```

**State Persistence** (`coordinate.md:261-274`):

Both dimensions saved to workflow state for bash block persistence:

```bash
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"

# Serialize REPORT_PATHS array to state
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done
```

### 5. Comprehensive Haiku Classification Timing

**When It Runs**: During **state machine initialization** (`sm_init()` in bash block 2 of coordinate.md)

**Invocation Point** (`coordinate.md:166`):
```bash
# coordinate.md:164-166
# CRITICAL: Call sm_init to export WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
```

**What It Produces** (`workflow-state-machine.sh:350-366`):

```json
{
  "workflow_type": "research-and-plan",     // Used for scope detection
  "confidence": 0.95,                       // Confidence threshold check
  "research_complexity": 2,                 // Drives dynamic path allocation
  "subtopics": [                           // Used in agent prompts
    "Implementation architecture",
    "Integration patterns"
  ],
  "reasoning": "Brief explanation..."      // Logged for diagnostics
}
```

**Exported Variables**:
- `WORKFLOW_SCOPE`: Determines workflow terminal state and phase transitions
- `RESEARCH_COMPLEXITY`: Controls number of research agents invoked (1-4)
- `RESEARCH_TOPICS_JSON`: Provides descriptive topic names for agent prompts

**Timing Analysis**:
- **Phase 0 (Initialization)**: Classification happens BEFORE path allocation
- **Enables just-in-time allocation**: Paths allocated to exactly match complexity (no pre-allocation tension)
- **85% token reduction**: Pre-calculated paths injected into agents (Phase 0 optimization)

## Recommendations

### 1. Topic Identification Strengths

**Preserve**:
- Comprehensive LLM classification (single call for all three dimensions)
- Semantic topic names (descriptive, not generic "Topic N")
- Context-aware fallback mechanisms (plan analysis, description parsing)

**Risk**: LLM classification failure defaults to generic topics (lines 369-376). Consider adding more sophisticated regex-based topic extraction before defaulting to "Topic N".

### 2. Filename Generation Optimization

**Current Tension**:
- Generic placeholders (`001_topic1.md`) pre-allocated
- Research-specialist agents create descriptive filenames
- Dynamic discovery reconciles the mismatch (lines 685-714)

**Opportunity**: Consider passing suggested descriptive filename to research-specialist agent:
```markdown
- Suggested Filename: 001_${sanitized_topic_name}.md
```

This would eliminate filesystem discovery overhead and ensure filename consistency.

### 3. Prompt Construction Clarity

**Strength**: Clear separation of concerns:
- Topic name: `$RESEARCH_TOPIC_1` (semantic, from LLM)
- Report path: `$AGENT_REPORT_PATH_1` (file system, from initialization)
- Complexity context: `$RESEARCH_COMPLEXITY` (for agent awareness)

**Recommendation**: Document this variable naming convention in agent behavioral file header for maintainability.

### 4. State Persistence Reliability

**Observation**: Dual serialization strategy:
- `RESEARCH_TOPICS_JSON`: JSON array (efficient, single variable)
- `REPORT_PATHS`: Indexed variables (REPORT_PATH_0, REPORT_PATH_1, ...)

**Tradeoff**: Indexed variables verbose but bash-native (no jq required in reconstruction). JSON compact but requires jq parsing.

**Recommendation**: Consider consolidating to JSON-only persistence with defensive jq availability checks (matching RESEARCH_TOPICS_JSON pattern).

### 5. Classification Performance

**Metrics**:
- **LLM latency**: File-based signaling with 10s timeout (lines 216-264)
- **Confidence threshold**: 0.7 (70% confidence required, line 23)
- **Fallback cost**: Regex-only classification ~instant, generic topics zero cost

**Opportunity**: Cache classification results by workflow description hash to eliminate repeated LLM calls for identical workflows.

## References

### Core Files
- `.claude/commands/coordinate.md:1-2110` - Main orchestration command with research phase logic
- `.claude/lib/workflow-state-machine.sh:334-452` - State machine initialization with comprehensive classification
- `.claude/lib/workflow-initialization.sh:168-548` - Path pre-calculation and dynamic allocation
- `.claude/lib/workflow-llm-classifier.sh:1-438` - LLM-based classification implementation

### Key Functions
- `sm_init()` (workflow-state-machine.sh:334) - Initializes state machine, invokes comprehensive classification
- `classify_workflow_comprehensive()` (workflow-llm-classifier.sh:99) - LLM classification with scope, complexity, subtopics
- `initialize_workflow_paths()` (workflow-initialization.sh:168) - Just-in-time dynamic path allocation
- `reconstruct_report_paths_array()` (workflow-initialization.sh:663) - Array reconstruction from state
- `generate_descriptive_topics_from_plans()` (workflow-state-machine.sh:214) - Plan-based topic extraction
- `generate_descriptive_topics_from_description()` (workflow-state-machine.sh:281) - Description-based topic extraction

### Task Invocation Blocks
- `coordinate.md:535-554` - Research agent 1 (always invoked)
- `coordinate.md:558-577` - Research agent 2 (complexity >= 2)
- `coordinate.md:581-600` - Research agent 3 (complexity >= 3)
- `coordinate.md:604-623` - Research agent 4 (complexity >= 4 or hierarchical)

### State Persistence
- `coordinate.md:261-274` - Research classification saved to state
- `coordinate.md:503-523` - Topic array reconstruction from JSON
- `coordinate.md:685-714` - Dynamic report path discovery

### Documentation References
- `.claude/docs/guides/phase-0-optimization.md` - Phase 0 pre-calculation pattern (85% token reduction)
- `.claude/docs/concepts/bash-block-execution-model.md` - Subprocess isolation and state persistence
- `.claude/specs/678_coordinate_haiku_classification/` - Comprehensive classification implementation spec

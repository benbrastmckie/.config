# Agent Invocation Template Interpretation Analysis

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Agent Invocation Template Interpretation
- **Report Type**: Architecture Analysis

## Executive Summary

Claude interprets the agent invocation template at coordinate.md line 470-491 by combining natural language instructions, surrounding bash context, and workflow state variables to determine how many times to invoke the Task tool. The placeholder `[REPORT_PATHS[$i-1] for topic $i]` is documentation notation showing the relationship between loop iteration and array access, not executable code. Claude resolves actual invocation count by reading RESEARCH_COMPLEXITY from workflow state (lines 402-414, 539-560) and generates concrete Task invocations for each topic (1 to N).

## Findings

### 1. Template Structure and Location

**Template Location**: `/home/benjamin/.config/.claude/commands/coordinate.md:470-491`

**Template Components**:
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research [topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [actual topic name]
    - Report Path: [REPORT_PATHS[$i-1] for topic $i]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Key Observation**: The template contains three types of placeholders:
1. **Natural language placeholders**: `[topic name]`, `[actual topic name]` - Claude replaces with descriptive text
2. **Bash-style placeholders**: `[REPORT_PATHS[$i-1] for topic $i]` - Documentation showing array access pattern
3. **Variable references**: `[RESEARCH_COMPLEXITY value]` - Claude replaces with actual numeric value

### 2. Context Sources for Template Resolution

**Primary Context Source**: RESEARCH_COMPLEXITY workflow state variable

**Initialization Logic** (coordinate.md:402-414):
```bash
# Determine research complexity (1-4 topics)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|migration|refactor|architecture"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multi-.*system|cross-.*platform|distributed|microservices"; then
  RESEARCH_COMPLEXITY=4
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "^(fix|update|modify).*(one|single|small)"; then
  RESEARCH_COMPLEXITY=1
fi
```

**State Persistence** (coordinate.md:427):
```bash
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
```

**Defensive Restoration** (coordinate.md:539-560):
```bash
# Defensive: Restore RESEARCH_COMPLEXITY if not loaded from state
if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  RESEARCH_COMPLEXITY=2
  # ...pattern matching logic repeated...
fi
```

### 3. REPORT_PATHS Array Pre-Calculation

**Array Population** (workflow-initialization.sh:318-331):
```bash
# Research phase paths (calculate for max 4 topics)
local -a report_paths
for i in 1 2 3 4; do
  report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
done

# Export individual report path variables for bash block persistence
export REPORT_PATH_0="${report_paths[0]}"
export REPORT_PATH_1="${report_paths[1]}"
export REPORT_PATH_2="${report_paths[2]}"
export REPORT_PATH_3="${report_paths[3]}"
export REPORT_PATHS_COUNT=4
```

**Key Design**: Pre-calculates ALL 4 possible paths regardless of actual complexity. Actual usage determined by RESEARCH_COMPLEXITY value.

**Array Reconstruction** (workflow-initialization.sh:586-610):
```bash
reconstruct_report_paths_array() {
  # Use generic defensive reconstruction pattern
  reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"

  # Verification Fallback: If reconstruction failed, use filesystem discovery
  if [ ${#REPORT_PATHS[@]} -eq 0 ] && [ -n "${TOPIC_PATH:-}" ]; then
    # Discover report files via glob pattern
    for report_file in "$reports_dir"/[0-9][0-9][0-9]_*.md; do
      if [ -f "$report_file" ]; then
        REPORT_PATHS+=("$report_file")
      fi
    done
  fi
}
```

### 4. Claude's Interpretation Process

**Step 1: Read Natural Language Instruction** (coordinate.md:470):
```
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent for EACH research topic (1 to $RESEARCH_COMPLEXITY):
```

**Analysis**:
- "EXECUTE NOW" triggers immediate action (imperative language per Standard 11)
- "for EACH research topic" indicates iteration requirement
- "(1 to $RESEARCH_COMPLEXITY)" explicitly states loop bounds using state variable

**Step 2: Parse Template Structure**:
Claude recognizes the Task tool invocation structure with fields:
- `subagent_type`: Agent tier selection
- `description`: Human-readable summary
- `timeout`: Execution time limit
- `prompt`: Complete behavioral injection prompt

**Step 3: Resolve Placeholders Using Context**:

For `[REPORT_PATHS[$i-1] for topic $i]`:
1. Claude recognizes bash array notation (documentation, not executable)
2. Searches preceding bash blocks for REPORT_PATHS array definition
3. Finds array reconstruction call at line 419: `reconstruct_report_paths_array`
4. Understands array contains 4 pre-calculated paths
5. Recognizes `$i-1` pattern indicates 0-based indexing (bash arrays)
6. Maps loop variable `i` (1-based iteration) to array index `i-1` (0-based)

For `[RESEARCH_COMPLEXITY value]`:
1. Claude searches bash context for RESEARCH_COMPLEXITY assignment
2. Finds initialization at lines 402-414
3. Observes pattern-based complexity scoring (1-4 topics)
4. Retrieves actual value from workflow state (via load_workflow_state)

**Step 4: Generate Concrete Task Invocations**:

Claude mentally expands the template N times where N=RESEARCH_COMPLEXITY:

**Example: RESEARCH_COMPLEXITY=2**
```
Invocation 1:
  Report Path: ${REPORT_PATHS[0]} = "${topic_path}/reports/001_topic1.md"

Invocation 2:
  Report Path: ${REPORT_PATHS[1]} = "${topic_path}/reports/002_topic2.md"
```

**Example: RESEARCH_COMPLEXITY=3**
```
Invocation 1:
  Report Path: ${REPORT_PATHS[0]} = "${topic_path}/reports/001_topic1.md"

Invocation 2:
  Report Path: ${REPORT_PATHS[1]} = "${topic_path}/reports/002_topic2.md"

Invocation 3:
  Report Path: ${REPORT_PATHS[2]} = "${topic_path}/reports/003_topic3.md"
```

### 5. Documentation vs Executable Code Distinction

**Critical Insight**: The placeholder `[REPORT_PATHS[$i-1] for topic $i]` is NOT bash code to be executed by Claude. It is documentation explaining the relationship between:
- Loop iteration variable `i` (1-based, from "1 to $RESEARCH_COMPLEXITY")
- Array index `$i-1` (0-based, bash array convention)
- Topic numbering in filenames (001_topic1.md, 002_topic2.md, etc.)

**Evidence from Behavioral Injection Pattern**:
- Templates are embedded in markdown prompt strings
- Claude does not execute bash syntax inside prompt strings
- Placeholders serve as human-readable documentation of resolution logic
- Claude performs resolution through natural language understanding + context retrieval

**Contrast with Executable Bash**:
```bash
# This IS executable (runs in bash subprocess)
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  REPORT_PATH="${REPORT_PATHS[$i-1]}"
  # ...actual bash array access...
done
```

### 6. Information Sources for Invocation Count

**Primary Source**: Natural language instruction with variable reference
```
for EACH research topic (1 to $RESEARCH_COMPLEXITY)
```

**Secondary Sources**:
1. **State file**: `${HOME}/.claude/tmp/coordinate_state_${WORKFLOW_ID}.txt`
   - Contains: `RESEARCH_COMPLEXITY=2` (or 1, 3, 4)
   - Loaded via: `load_workflow_state "$WORKFLOW_ID"` (coordinate.md:519)

2. **Bash context**: Complexity calculation logic (coordinate.md:402-414)
   - Pattern matching on WORKFLOW_DESCRIPTION
   - Heuristic scoring based on keywords

3. **Default values**: Defensive restoration fallback (coordinate.md:543)
   - Default: 2 topics
   - Recalculated if state load fails

**Decision Tree**:
```
1. Check explicit instruction: "1 to $RESEARCH_COMPLEXITY" → Found ✓
2. Resolve $RESEARCH_COMPLEXITY:
   a. Load from workflow state file → Found: RESEARCH_COMPLEXITY=2
   b. Value = 2
3. Generate 2 Task invocations
4. For each invocation i ∈ {1, 2}:
   a. Resolve [topic name] → Extract from WORKFLOW_DESCRIPTION or use generic "topic$i"
   b. Resolve [REPORT_PATHS[$i-1]] → Access pre-calculated path at index (i-1)
   c. Resolve [RESEARCH_COMPLEXITY value] → Use value 2
```

### 7. Subprocess Isolation and State Persistence

**Architectural Context**: Each bash block runs in a separate subprocess (bash-block-execution-model.md:1-48)

**Consequence for Template Resolution**:
- REPORT_PATHS array calculated in bash block 1 (coordinate.md:230-259)
- Template invocation occurs between bash blocks (markdown section)
- Array reconstruction required in bash block 2 (coordinate.md:564)

**Why Pre-Calculation Matters**:
- Claude has access to REPORT_PATHS state during template resolution
- No need to calculate paths dynamically during agent invocation
- Consistent path format across all phases (research, plan, implement)

**State Serialization Pattern** (coordinate.md:248-258):
```bash
# Serialize REPORT_PATHS array to state
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

# Save individual report path variables
for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  eval "value=\$$var_name"
  append_workflow_state "$var_name" "$value"
done
```

**Why Not Pass Array Directly**: Bash arrays cannot be exported across subprocess boundaries (bash-block-execution-model.md:64-65)

## Recommendations

### 1. Clarify Documentation Notation in Template Comments

**Current State**: Placeholder `[REPORT_PATHS[$i-1] for topic $i]` may appear as executable bash syntax.

**Recommendation**: Add inline comment explaining documentation purpose:
```markdown
**Workflow-Specific Context**:
- Research Topic: [actual topic name]
- Report Path: [REPORT_PATHS[$i-1] for topic $i]
  # ^ Documentation notation showing 1-based loop (i) maps to 0-based array (i-1)
  # Actual resolution: Claude retrieves pre-calculated path from workflow state
- Project Standards: /home/benjamin/.config/CLAUDE.md
```

**Benefit**: Reduces confusion for developers reading coordinate.md, clarifies that Claude performs resolution (not bash interpreter).

### 2. Document Template Resolution Process

**Current State**: Resolution logic implicit in command structure, not explicitly documented.

**Recommendation**: Create documentation section in coordinate-command-guide.md:

```markdown
### Agent Invocation Template Resolution

The flat research coordination template (Option B, line 470-491) uses placeholders
that Claude resolves through context retrieval:

1. **Iteration Count**: Explicit instruction "1 to $RESEARCH_COMPLEXITY"
2. **Array Access**: Pre-calculated REPORT_PATHS array from workflow state
3. **Placeholder Format**: [VARIABLE_NAME[$index] for item $item]
4. **Resolution Method**: Natural language understanding + state file access

Claude generates N concrete Task invocations where N = RESEARCH_COMPLEXITY value.
```

**Benefit**: Explicit documentation prevents misinterpretation, aids debugging when agent count mismatch occurs.

### 3. Add Diagnostic Output for Template Expansion

**Current State**: Silent template resolution (no visibility into actual invocation count).

**Recommendation**: Add diagnostic output before template section:
```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEMPLATE EXPANSION: Flat Research Coordination"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Invocation Count: $RESEARCH_COMPLEXITY agents"
echo "Report Paths:"
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  echo "  Agent $i: ${REPORT_PATHS[$i-1]}"
done
echo ""
```

**Benefit**: User visibility into template expansion, easier debugging of path mismatches.

### 4. Validate RESEARCH_COMPLEXITY Range

**Current State**: RESEARCH_COMPLEXITY calculated via heuristics (1-4 topics), but no validation against REPORT_PATHS_COUNT.

**Recommendation**: Add validation checkpoint:
```bash
# Validate RESEARCH_COMPLEXITY is within valid range
if [ $RESEARCH_COMPLEXITY -lt 1 ] || [ $RESEARCH_COMPLEXITY -gt $REPORT_PATHS_COUNT ]; then
  echo "ERROR: RESEARCH_COMPLEXITY ($RESEARCH_COMPLEXITY) outside valid range [1, $REPORT_PATHS_COUNT]"
  exit 1
fi
```

**Benefit**: Fail-fast detection of configuration errors before agent invocation.

### 5. Consider Explicit Loop Expansion (Alternative Pattern)

**Current State**: Template uses documentation notation requiring Claude's interpretation.

**Alternative Pattern**: Explicit bash loop generates Task invocations:
```bash
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  TOPIC_NAME="topic${i}"
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  echo "Invoking research-specialist agent $i/$RESEARCH_COMPLEXITY for $TOPIC_NAME"

  # Task tool invocation with concrete resolved values
  # (Task tool called from bash, receives fully resolved prompt string)
done
```

**Trade-offs**:
- **Pro**: Explicit bash execution, easier debugging, visible loop variable
- **Pro**: No template interpretation ambiguity
- **Con**: Loses parallel invocation capability (Task tool called sequentially)
- **Con**: Increases bash block complexity

**Recommendation**: Retain current template pattern for parallel invocation benefits, but document resolution process explicitly (Recommendation 2).

## Cross-References

### Parent Report
- [Agent Mismatch Investigation - OVERVIEW](./OVERVIEW.md) - Complete root cause analysis and recommended solution

### Related Subtopic Reports
- [Hardcoded REPORT_PATHS_COUNT Analysis](./001_hardcoded_report_paths_count_analysis.md) - Phase 0 optimization design rationale
- [Loop Count Determination Logic](./003_loop_count_determination_logic.md) - Variable controlling iteration count

## References

### Source Files Analyzed

1. `/home/benjamin/.config/.claude/commands/coordinate.md:402-491` - RESEARCH_COMPLEXITY calculation and template definition
2. `/home/benjamin/.config/.claude/commands/coordinate.md:539-564` - Defensive restoration and array reconstruction
3. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:167-349` - initialize_workflow_paths() and REPORT_PATHS pre-calculation
4. `/home/benjamin/.config/.claude/lib/workflow-initialization.sh:586-610` - reconstruct_report_paths_array() implementation
5. `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md:1-80` - Subprocess isolation architecture
6. `/home/benjamin/.config/.claude/agents/research-specialist.md:1-100` - Research agent behavioral guidelines

### Key Concepts Referenced

1. **Behavioral Injection Pattern** - Agent invocation via Task tool with injected behavioral file reference
2. **Subprocess Isolation** - Each bash block runs as separate process, requires state file persistence
3. **Imperative Language (Standard 11)** - "EXECUTE NOW" triggers immediate action
4. **Verification Fallback Pattern (Spec 057)** - Filesystem discovery when state reconstruction fails
5. **State-Based Orchestration** - Workflow state persistence across subprocess boundaries

### External Resources

1. Anthropic Claude Documentation: "Use prompt templates and variables" - https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/prompt-templates-and-variables
2. "Effective context engineering for AI agents" - https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
3. "Context Rot: How Increasing Input Tokens Impacts LLM Performance" - https://research.trychroma.com/context-rot

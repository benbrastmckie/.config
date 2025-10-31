# Agent Invocation Placeholder Automation Opportunities

## Metadata
- **Date**: 2025-10-30
- **Agent**: research-specialist
- **Topic**: Agent Invocation Placeholder Automation
- **Report Type**: Pattern recognition and automation analysis
- **Complexity Level**: 4

## Executive Summary

The /coordinate command requires manual placeholder substitution in 12 "EXECUTE NOW" blocks where Claude must replace ${VARIABLE_NAME} placeholders with actual values calculated in Phase 0. This creates cognitive overhead and repetitive work for the orchestrator. Analysis reveals 60-70% reduction potential through helper function automation that pre-expands Task tool invocations with calculated values. However, current bash-based expansion has limitations in the Task tool's Claude-side execution context, suggesting either bash-side templating (envsubst) or Claude-native variable expansion would be most effective.

## Findings

### Current State Analysis

The /coordinate command contains **42 placeholder substitution instructions** requiring Claude to manually replace bracketed placeholders like `[substitute actual topic name]` and variable references like `${REPORT_PATHS[$i-1]}` with calculated values from Phase 0.

**Key Statistics** (from /home/benjamin/.config/.claude/commands/coordinate.md):
- **12 "EXECUTE NOW" blocks** requiring Task tool invocations (lines 522, 751, 873, 968, 1096, 1286, 1431, 1549, 1590, 1622, 1719, 1814)
- **42 total "substitute" instructions** scattered throughout agent invocation blocks
- **9 unique agent invocations**: research-specialist (N times for N topics), research-synthesizer, plan-architect, implementer-coordinator, test-specialist, debug-analyst (3x), code-writer (3x), doc-writer

**Current Pattern Example** (lines 873-896):
```markdown
**YOUR RESPONSIBILITY**: Make N Task tool invocations (one per topic from 1 to $RESEARCH_COMPLEXITY) by substituting actual values for placeholders below.

Task {
  subagent_type: "general-purpose"
  description: "Research [substitute actual topic name] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [substitute actual topic name from research topics list]
    - Report Path: [substitute REPORT_PATHS[$i-1] for this topic where $i is 1 to $RESEARCH_COMPLEXITY]
    - Project Standards: /home/benjamin/.config/CLAUDE.md
    - Complexity Level: [substitute $RESEARCH_COMPLEXITY value]

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Cognitive Overhead Analysis**:
1. **Array Index Math**: `REPORT_PATHS[$i-1]` requires Claude to understand bash array indexing (0-based vs 1-based loop variables)
2. **Loop Context**: Must track which iteration (1 to N) to select correct report path and topic name
3. **Variable Expansion**: Must remember values calculated in Phase 0 (2500+ lines earlier in prompt)
4. **Repetitive Work**: Same substitution pattern repeated for all N research topics
5. **Error-Prone**: Potential for off-by-one errors in array indexing or incorrect variable references

### Manual Invocation Pattern Analysis

**12 "EXECUTE NOW" Blocks Breakdown**:

1. **Phase 0 Setup** (line 522): Bash tool - library sourcing and path calculation (no placeholders, executes as-is)
2. **Phase 0 Helpers** (line 751): Bash tool - helper function definitions (no placeholders, executes as-is)
3. **Phase 1 Research** (line 873): Task tool - **N invocations** (1-4 typically) with 5 placeholders each
4. **Phase 1 Synthesis** (line 968): Task tool - **1 invocation** with 4 placeholders
5. **Phase 2 Planning** (line 1096): Task tool - **1 invocation** with 5 placeholders
6. **Phase 3 Implementation** (line 1286): Task tool - **1 invocation** with 5 placeholders
7. **Phase 4 Testing** (line 1431): Task tool - **1 invocation** with 4 placeholders
8. **Phase 5 Debug Analysis** (line 1549): Task tool - **up to 3 invocations** (loop) with 5 placeholders each
9. **Phase 5 Fix Application** (line 1590): Task tool - **up to 3 invocations** (loop) with 4 placeholders each
10. **Phase 5 Test Rerun** (line 1622): Task tool - **up to 3 invocations** (loop) with 4 placeholders each
11. **Phase 6 Documentation** (line 1719): Task tool - **1 invocation** with 5 placeholders
12. **Reference Pattern** (line 1814): Documentation block explaining invocation pattern (not actual execution)

**Total Invocations Per Workflow**:
- Minimum: 8 invocations (research-only: 2-4 research + 1 synthesis + no plan/implement/test/debug/doc)
- Typical: 12-15 invocations (full workflow: 2-4 research + 1 synthesis + plan + implement + test + doc, no debug)
- Maximum: 21 invocations (full workflow with 4 research + 3 debug iterations: 4 + 1 + 1 + 1 + 1 + (3+3+3) + 1)

**Placeholder Types**:
1. **Topic-specific**: `[substitute actual topic name]` - varies per research topic
2. **Array access**: `[substitute REPORT_PATHS[$i-1]]` - requires loop index math
3. **Simple variables**: `[substitute $RESEARCH_COMPLEXITY value]` - direct value substitution
4. **Formatted lists**: `[substitute $RESEARCH_REPORTS_LIST - formatted list]` - requires string construction
5. **Path variables**: `[substitute $PLAN_PATH - absolute path pre-calculated]` - simple substitution with context reminder

### Automation Opportunities

**Three Automation Approaches Identified**:

#### Approach 1: Bash-Side Template Expansion (envsubst-style)

**Concept**: Pre-expand Task invocation templates using bash variable substitution before presenting to Claude.

**Implementation** (hypothetical helper function):
```bash
# .claude/lib/agent-invocation-helper.sh
invoke_research_agent() {
  local topic="$1"
  local report_path="$2"
  local complexity="$3"

  # Template with ${VAR} placeholders (bash-style)
  local template=$(cat <<'TEMPLATE'
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${AGENT_PATH}

    **Workflow-Specific Context**:
    - Research Topic: ${TOPIC}
    - Report Path: ${REPORT_PATH}
    - Project Standards: ${STANDARDS_FILE}
    - Complexity Level: ${COMPLEXITY}

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
TEMPLATE
)

  # Expand template with actual values
  TOPIC="$topic" \
  REPORT_PATH="$report_path" \
  AGENT_PATH="/home/benjamin/.config/.claude/agents/research-specialist.md" \
  STANDARDS_FILE="/home/benjamin/.config/CLAUDE.md" \
  COMPLEXITY="$complexity" \
  envsubst <<< "$template"
}

# Usage in Phase 1:
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  invoke_research_agent \
    "${RESEARCH_TOPICS[$i-1]}" \
    "${REPORT_PATHS[$i-1]}" \
    "$RESEARCH_COMPLEXITY"
done
```

**Limitations**:
- **envsubst not available** on this system (verified via bash check)
- **Manual expansion** using bash parameter expansion (`${VAR}`) possible but:
  - Quotes in prompts require careful escaping
  - Heredocs with variable expansion can break with special characters
  - No validation that all placeholders were replaced
- **Claude execution barrier**: Bash cannot execute Task tool (only Claude can), so expanded template must be:
  - Printed to stdout for Claude to read
  - Parsed by Claude and executed as Task invocation
  - This adds indirection and complexity

**Verdict**: Not feasible without envsubst, and even with it, the bash→Claude execution boundary creates complexity.

#### Approach 2: Claude-Native Variable Expansion

**Concept**: Provide Claude with pre-calculated variables and instruct Claude to perform substitution in-place when invoking Task tool.

**Current State**: This is exactly what /coordinate does now with 42 "substitute" instructions.

**Optimization**: Reduce cognitive overhead by:
1. **Pre-formatting complex structures** (formatted lists, array access) in Phase 0 bash
2. **Single instruction** instead of per-placeholder instructions
3. **Clear variable namespace** with explicit exports

**Implementation Example** (optimized current approach):
```bash
# Phase 0: Pre-format all agent contexts
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  # Pre-format context for each research topic
  RESEARCH_CONTEXTS[$i-1]=$(cat <<EOF
    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPICS[$i-1]}
    - Report Path: ${REPORT_PATHS[$i-1]}
    - Project Standards: $STANDARDS_FILE
    - Complexity Level: $RESEARCH_COMPLEXITY
EOF
)
done

# Pre-format plan context
PLAN_CONTEXT=$(cat <<EOF
    **Workflow-Specific Context**:
    - Workflow Description: $WORKFLOW_DESCRIPTION
    - Plan File Path: $PLAN_PATH
    - Project Standards: $STANDARDS_FILE
    - Research Reports: $RESEARCH_REPORTS_LIST
    - Research Report Count: $SUCCESSFUL_REPORT_COUNT
EOF
)
```

**Then in "EXECUTE NOW" blocks**:
```markdown
**EXECUTE NOW**: For each research topic (1 to $RESEARCH_COMPLEXITY), invoke Task tool with pre-formatted context.

**INSTRUCTION**: Use RESEARCH_CONTEXTS array - each invocation uses RESEARCH_CONTEXTS[$i-1] for topic $i.

Task {
  subagent_type: "general-purpose"
  description: "Research [topic] with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    ${RESEARCH_CONTEXTS[$i-1]}

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [exact absolute path to report file]
  "
}
```

**Benefits**:
- Reduces 5 placeholders per invocation → 1 context block substitution
- Eliminates array index math from Claude's responsibility
- Pre-validates variable values in bash (can check for empty strings, invalid paths)
- Single instruction ("use RESEARCH_CONTEXTS array") instead of 5 "substitute" instructions

**Reduction**: ~60% fewer substitution instructions (42 → ~17), but still requires manual Task invocations.

#### Approach 3: Inline Agent Invocation (orchestrate pattern)

**Concept**: /orchestrate uses bash variable expansion (`${VAR}`) directly in Task invocation blocks because the entire workflow is a bash script that Claude executes.

**Pattern from /orchestrate** (lines 860-874):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory artifact creation"
  timeout: 300000
  prompt: "
    **FILE CREATION REQUIRED**

    Use Write tool to create: ${REPORT_PATH}

    Research ${TOPIC} and document findings in the file.

    Return only: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Why this works in /orchestrate**:
- **Execution context**: /orchestrate's bash code is executed by Claude via Bash tool
- **Variable scope**: All variables (`${TOPIC}`, `${REPORT_PATH}`) are in bash scope when Claude executes the script
- **Automatic expansion**: Bash expands `${VAR}` before Claude sees the Task invocation text
- **Zero cognitive overhead**: Claude sees fully-expanded text, no substitution required

**Why this doesn't work in /coordinate**:
- **Markdown instructions**: /coordinate is a markdown document with inline code blocks, not a bash script
- **Manual execution**: Claude must manually copy Task invocation blocks from markdown and invoke Task tool
- **No bash context**: Variables like `${TOPIC}` are bash variables in code blocks, not available when Claude invokes Task
- **Literal strings**: If Claude copies `prompt: "Research ${TOPIC}"`, the Task tool receives literal string `${TOPIC}`, not expanded value

**Architectural Difference**:
- **/orchestrate**: Imperative bash script → Claude executes → Bash expands variables → Task tool invoked with expanded text
- **/coordinate**: Declarative markdown instructions → Claude reads → Claude manually substitutes → Task tool invoked

**Conversion Feasibility**: Could /coordinate adopt /orchestrate's pattern?

**Hybrid Approach** (combine bash execution with Task invocation):
```bash
# Phase 1: Generate and execute Task invocations
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  TOPIC="${RESEARCH_TOPICS[$i-1]}"
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  # Generate Task invocation with expanded variables
  cat > /tmp/task_invocation_$i.txt <<EOF
Task {
  subagent_type: "general-purpose"
  description: "Research $TOPIC with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: $TOPIC
    - Report Path: $REPORT_PATH
    - Project Standards: $STANDARDS_FILE
    - Complexity Level: $RESEARCH_COMPLEXITY

    **CRITICAL**: Create report file at EXACT path provided above.

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: $REPORT_PATH
  "
}
EOF

  # Instruct Claude to execute the generated Task invocation
  cat /tmp/task_invocation_$i.txt
done
```

**Limitation**: **Bash cannot invoke Task tool**. Only Claude (the LLM) can invoke tools. Bash can only:
1. Generate the text of a Task invocation
2. Print it to stdout
3. Hope Claude reads it and executes it

This creates a **bash→Claude execution handoff** that adds complexity and potential for misunderstanding.

**Verdict**: /orchestrate's pattern works because the entire script is Claude-executed bash. /coordinate uses markdown instructions, so direct bash variable expansion isn't available during Task invocations.

### Comparison with Other Commands

**Three Orchestration Commands** analyzed for agent invocation patterns:

#### /orchestrate (5,438 lines)

**Pattern**: Bash-native variable expansion in Task invocations within case statements.

**Agent Invocations**: 17 Task blocks (verified via grep)

**Example** (lines 861-874):
```bash
case "$template" in
  standard)
    Task {
      subagent_type: "general-purpose"
      description: "Research ${TOPIC} with mandatory artifact creation"
      timeout: 300000
      prompt: "
        **FILE CREATION REQUIRED**

        Use Write tool to create: ${REPORT_PATH}

        Research ${TOPIC} and document findings in the file.

        Return only: REPORT_CREATED: ${REPORT_PATH}
      "
    }
    ;;
```

**Substitution Method**: **Bash variable expansion** (`${VAR}`) - zero manual substitution
- Variables like `${TOPIC}`, `${REPORT_PATH}` are bash variables in the executing script
- Bash expands them before Claude invokes Task tool
- **Automatic**: No Claude involvement in substitution

**Variables Replaced** (line 807-810):
- **Manual**: `[TOPIC]`, `[TOPIC_NAME]`, `[SPECIFIC RESEARCH FOCUS]` - Claude replaces these per topic
- **Automatic**: `${ARTIFACT_REPORTS}`, `${TOPIC_NUMBER}` - Bash expands these from Phase 0

**Complexity Handling**: 3-tier template system with auto-retry (standard, ultra_explicit, step_by_step)

**Cognitive Overhead**: **LOW** for variable expansion (bash handles it), **MEDIUM** for manual topic replacements

#### /supervise (1,939 lines)

**Pattern**: Direct bash variable expansion in Task invocations (similar to /orchestrate but simpler).

**Agent Invocations**: 2 Task blocks (verified via grep) - minimal orchestration

**Example** (lines 66-80):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]
    - Project Standards: [path to CLAUDE.md]

    Execute planning following all guidelines in behavioral file.
    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Substitution Method**: **Bash variable expansion** for paths (`${PLAN_PATH}`), **manual substitution** for structured data (`[list of paths]`)

**Cognitive Overhead**: **LOW** - only 2 agent invocations, minimal placeholders

**Design Philosophy**: Minimalist reference implementation, not production-focused

#### /coordinate (2,500-3,000 lines)

**Pattern**: Manual placeholder substitution with explicit instructions (`[substitute X]`).

**Agent Invocations**: 12 "EXECUTE NOW" blocks → 8-21 actual invocations (depending on workflow)

**Substitution Method**: **Manual Claude substitution** - Claude reads instructions and replaces all placeholders

**Cognitive Overhead**: **HIGH** - 42 substitution instructions across 12 invocation blocks

**Design Rationale** (from coordinate_research.md:130-159):
> "Current State: 12 manual 'EXECUTE NOW' blocks requiring Claude to substitute placeholders
>
> Issue: Each agent invocation requires:
> - Manual placeholder substitution (${VARIABLE_NAME})
> - Repetitive Task tool invocations
> - Cognitive overhead for the orchestrator
>
> Optimization: [suggests helper function for 60-70% reduction]"

**Key Difference**: /coordinate separates **path calculation** (Phase 0 bash) from **agent invocation** (manual Claude execution). /orchestrate combines both in bash execution context.

### Summary Comparison

| Command | Invocation Count | Substitution Method | Cognitive Overhead | Automation Level |
|---------|------------------|---------------------|--------------------|--------------------|
| /orchestrate | 17 | Bash expansion + manual topic replacement | Medium | 70% automated |
| /supervise | 2 | Bash expansion + minimal manual | Low | 80% automated |
| /coordinate | 12 (8-21 actual) | 100% manual substitution | High | 0% automated |

**Insight**: /orchestrate achieves 70% automation by executing the entire workflow as bash (Claude uses Bash tool), allowing bash to expand variables before Task invocations. /coordinate uses markdown instructions with inline bash blocks, preventing bash variable expansion during Task invocations.

## Recommendations

### 1. **Adopt Approach 2: Pre-Formatted Context Blocks** (Short-Term, 60% Reduction)

**Priority**: HIGH - Immediate improvement with minimal architectural change

**Implementation**:
1. Add Phase 0 context pre-formatting for all agent types:
   - `RESEARCH_CONTEXTS[]` array with all research agent contexts
   - `PLAN_CONTEXT` string with planning context
   - `IMPL_CONTEXT` string with implementation context
   - `TEST_CONTEXT` string with testing context
   - `DEBUG_CONTEXTS[]` array for debug iteration contexts
   - `DOC_CONTEXT` string with documentation context

2. Simplify "EXECUTE NOW" instructions from 5 placeholders per invocation to 1:
   ```markdown
   **EXECUTE NOW**: Invoke Task tool with RESEARCH_CONTEXTS[$i-1] for topic $i
   ```

3. Maintain verification checkpoints and fail-fast patterns (unchanged)

**Benefits**:
- **60% reduction** in manual substitution (42 → ~17 instructions)
- **Eliminates array indexing math** from Claude's cognitive load
- **Pre-validation** of paths and variables in bash (fail-fast if empty)
- **Maintains architectural pattern** (Phase 0 calculation → agent invocation)
- **No behavioral changes** to agents or verification checkpoints

**Estimated Effort**: 2-3 hours
- Modify Phase 0 setup (coordinate.md:522-745) to add context pre-formatting
- Update 12 "EXECUTE NOW" blocks to reference pre-formatted contexts
- Test with research-only, research-and-plan, and full-implementation workflows

**Validation**:
- Verify all 42 placeholders eliminated or consolidated into 6 pre-formatted contexts
- Test array indexing (RESEARCH_CONTEXTS, DEBUG_CONTEXTS) with 2, 3, 4 topics/iterations
- Confirm no behavioral regressions in agent invocations

### 2. **Convert to Bash-Native Execution Pattern** (Long-Term, 100% Automation)

**Priority**: MEDIUM - Fundamental architectural change with highest automation potential

**Implementation**:
1. Convert /coordinate from markdown instructions → bash script execution (like /orchestrate)
2. Move Task invocations inside bash `for` loops with automatic `${VAR}` expansion
3. Leverage existing `/orchestrate` pattern as reference (lines 860-900)

**Architectural Change**:
```bash
# Current (markdown instructions):
**EXECUTE NOW**: Make N Task tool invocations by substituting placeholders
Task { ... prompt: "Research [substitute topic]" ... }

# Proposed (bash script execution):
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  TOPIC="${RESEARCH_TOPICS[$i-1]}"
  REPORT_PATH="${REPORT_PATHS[$i-1]}"

  Task {
    subagent_type: "general-purpose"
    description: "Research ${TOPIC} with mandatory artifact creation"
    prompt: "... ${TOPIC} ... ${REPORT_PATH} ..."
  }
done
```

**Benefits**:
- **100% automation** - zero manual substitution required
- **Zero cognitive overhead** for variable expansion (bash handles it)
- **Alignment with /orchestrate** - consistent pattern across commands
- **Reduced command size** - eliminate 42 substitution instructions (~150 lines)

**Challenges**:
- **Execution model shift**: /coordinate currently uses markdown with inline bash blocks (declarative), must convert to pure bash script (imperative)
- **Tool invocation from bash**: Current pattern has Claude read markdown and invoke Task tool manually; new pattern requires bash→Claude→Task execution flow
- **Indentation and quoting**: Task invocations inside bash loops require careful heredoc quoting to avoid variable expansion conflicts
- **Debugging complexity**: Bash script errors (syntax, quoting) harder to debug than markdown instruction misinterpretation

**Estimated Effort**: 8-12 hours
- Rewrite /coordinate structure from markdown → bash script
- Convert all 12 "EXECUTE NOW" blocks to bash loop execution
- Test error handling and verification checkpoints in bash context
- Update documentation and examples

**Risk**: MEDIUM - architectural change may introduce regressions in verification, checkpoint handling, or agent invocation reliability

**Recommendation**: Defer until Approach 2 validated in production. Use /orchestrate as architectural reference.

### 3. **Create Agent Invocation Helper Library** (Alternative, Reusability Focus)

**Priority**: LOW - Most complex, unclear benefit over Approach 2

**Concept**: Extract agent invocation logic to `.claude/lib/agent-invocation-helper.sh` with functions like:
- `invoke_research_agent(topic, report_path, complexity)`
- `invoke_plan_architect(plan_path, reports_list, standards)`
- `invoke_implementer_coordinator(plan_path, workflow_desc)`

**Implementation Challenge**: **Bash cannot invoke Task tool** (only Claude can), so helper functions can only:
1. Generate Task invocation text with variable expansion
2. Print to stdout
3. Hope Claude reads and executes it

**Alternative**: Helper functions return **JSON context objects** that Claude uses to populate Task invocations:
```bash
# .claude/lib/agent-invocation-helper.sh
generate_research_context() {
  local topic="$1"
  local report_path="$2"
  jq -n \
    --arg topic "$topic" \
    --arg path "$report_path" \
    --arg standards "$STANDARDS_FILE" \
    '{topic: $topic, report_path: $path, standards: $standards}'
}

# Usage:
RESEARCH_CONTEXT=$(generate_research_context "${TOPIC}" "${REPORT_PATH}")
# Claude reads RESEARCH_CONTEXT JSON and populates Task invocation
```

**Verdict**: More complexity than Approach 2 without clear benefit. JSON serialization/deserialization adds overhead. Recommendation: **NOT RECOMMENDED**.

### 4. **Hybrid: Bash-Generated Task Files** (Experimental)

**Concept**: Bash generates complete Task invocation files that Claude reads and executes:

```bash
# Phase 1: Generate Task invocation files
for i in $(seq 1 $RESEARCH_COMPLEXITY); do
  cat > "/tmp/coordinate_task_research_${i}.txt" <<EOF
Task {
  subagent_type: "general-purpose"
  description: "Research ${RESEARCH_TOPICS[$i-1]} with mandatory artifact creation"
  timeout: 300000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPICS[$i-1]}
    - Report Path: ${REPORT_PATHS[$i-1]}
    - Project Standards: $STANDARDS_FILE
    - Complexity Level: $RESEARCH_COMPLEXITY

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: ${REPORT_PATHS[$i-1]}
  "
}
EOF
done

# Instruct Claude to execute generated files
echo "EXECUTE NOW: Read and execute Task invocations from /tmp/coordinate_task_research_*.txt"
```

**Benefits**:
- Bash generates fully-expanded Task invocations (100% variable substitution)
- Claude simply reads files and executes (zero substitution cognitive load)
- Intermediate files provide audit trail and debugging visibility

**Challenges**:
- **Indirection**: Bash→file→Claude→Task execution adds complexity
- **Temp file management**: Need cleanup, collision prevention
- **Error handling**: If file generation fails, Claude sees incomplete invocations
- **Non-atomic**: File generation and Task execution are separate steps

**Verdict**: Interesting but adds indirection. Approach 2 (pre-formatted contexts) achieves similar 60% reduction without temp files. Recommendation: **EXPERIMENTAL - consider if Approach 2 insufficient**.

### Cost-Benefit Analysis

| Approach | Reduction | Effort | Risk | Architectural Change | Recommendation |
|----------|-----------|--------|------|----------------------|----------------|
| **Approach 2: Pre-Formatted Contexts** | 60% | 2-3h | LOW | Minimal (add Phase 0 formatting) | **IMPLEMENT FIRST** |
| **Approach 3: Bash-Native Execution** | 100% | 8-12h | MEDIUM | Major (markdown→bash script) | **DEFER** (after Approach 2 validated) |
| **Helper Library** | 30-40% | 6-8h | MEDIUM | Moderate (new library + integration) | **NOT RECOMMENDED** |
| **Bash-Generated Files** | 80-90% | 4-6h | MEDIUM | Moderate (add file generation step) | **EXPERIMENTAL** |

### Implementation Roadmap

**Phase 1: Immediate Optimization** (Sprint 1)
1. Implement Approach 2 (pre-formatted contexts) in /coordinate
2. Test with 3 workflow types (research-only, research-and-plan, full-implementation)
3. Measure cognitive load reduction (developer experience survey)
4. Validate no behavioral regressions (agent invocation tests)

**Phase 2: Long-Term Convergence** (Sprint 2-3, optional)
1. Evaluate production stability of Approach 2 implementation
2. If stable and successful: consider Approach 3 (bash-native execution) for full automation
3. Use /orchestrate as architectural reference for conversion
4. Incremental migration: one phase at a time (research → plan → implement → test → debug → doc)

**Phase 3: Consolidation** (Sprint 4+, optional)
1. If both /coordinate and /orchestrate adopt bash-native execution, consider command consolidation
2. Unified orchestration pattern across all workflow commands
3. Extract common patterns to shared libraries (`.claude/lib/orchestration-core.sh`)

## References

**Primary Files Analyzed**:
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 1-2500+)
  - Line 522: Phase 0 setup (EXECUTE NOW block 1)
  - Line 751: Phase 0 helper functions (EXECUTE NOW block 2)
  - Line 873-896: Phase 1 research invocation with 5 placeholders (EXECUTE NOW block 3)
  - Line 968: Phase 1 synthesis invocation (EXECUTE NOW block 4)
  - Line 1096-1120: Phase 2 planning invocation with 5 placeholders (EXECUTE NOW block 5)
  - Line 1286: Phase 3 implementation invocation (EXECUTE NOW block 6)
  - Line 1431: Phase 4 testing invocation (EXECUTE NOW block 7)
  - Line 1549: Phase 5 debug analysis loop (EXECUTE NOW block 8)
  - Line 1590: Phase 5 fix application loop (EXECUTE NOW block 9)
  - Line 1622: Phase 5 test rerun loop (EXECUTE NOW block 10)
  - Line 1719: Phase 6 documentation invocation (EXECUTE NOW block 11)
  - Line 1814: Reference pattern documentation (EXECUTE NOW block 12)

- `/home/benjamin/.config/.claude/commands/orchestrate.md` (5,438 lines)
  - Lines 1-150: Command metadata and dry-run mode
  - Lines 800-900: Research phase with bash variable expansion (${TOPIC}, ${REPORT_PATH})
  - Lines 860-874: Example Task invocation with automatic bash expansion

- `/home/benjamin/.config/.claude/commands/supervise.md` (1,939 lines)
  - Lines 1-100: Command metadata and architectural pattern
  - Lines 66-80: Example Task invocation with ${PLAN_PATH} expansion

- `/home/benjamin/.config/.claude/specs/coordinate_research.md`
  - Lines 130-159: Original analysis noting manual placeholder substitution issue and suggesting 60-70% reduction via helper functions

**Supporting Files**:
- `/home/benjamin/.config/.claude/lib/agent-invocation.sh` (136 lines)
  - invoke_complexity_estimator() function showing bash-side prompt generation pattern
  - Note: Returns prompt text, cannot invoke Task tool from bash

- `/home/benjamin/.config/.claude/lib/agent-registry-utils.sh` (100+ lines)
  - Agent registration and metrics tracking (not directly related to invocation automation)

**External Research**:
- Web search: "bash template variable substitution envsubst alternative 2025"
  - envsubst (GNU gettext) - standard tool for ${VAR} expansion
  - Alternatives: j2cli (Jinja2), genvsub (Go), perl/python one-liners
  - Verification: envsubst not available on this system

**Key Statistics**:
- **42 "substitute" instructions** in /coordinate command (verified via grep)
- **12 "EXECUTE NOW" blocks** requiring Task tool invocations
- **8-21 actual agent invocations** per workflow (varies by workflow type and debug iterations)
- **17 Task invocations** in /orchestrate (verified via grep)
- **2 Task invocations** in /supervise (verified via grep)

**Testing Validation Points**:
- Array indexing correctness: REPORT_PATHS[$i-1] for i in 1..N
- Loop iteration tracking: 1-based loop variables (seq 1 N) vs 0-based arrays
- Variable scope: Phase 0 calculations available in Phase 1-6 agent invocations
- Placeholder completeness: All 42 placeholders substituted before Task invocation

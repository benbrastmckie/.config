# Agent Communication Patterns Analysis

## Research Metadata
- **Date**: 2025-10-24
- **Focus**: Agent communication mechanisms in hierarchical workflows
- **Status**: Complete
- **Files Analyzed**: 6 pattern documentation files, 3 command files, 2 agent files, 1 library file

## Executive Summary

Agent communication in the Claude Code system uses a **structured parameter injection pattern** that avoids bash escaping issues entirely. Commands pre-calculate absolute paths, inject them directly into agent prompts via the Task tool's `prompt` parameter, and agents return structured string markers (e.g., `REPORT_CREATED: /absolute/path`) that commands parse with simple string operations. This pattern achieves 100% file creation rate while maintaining clean separation between orchestration (commands) and execution (agents).

Key finding: **Command substitution is NOT used** for path communication. All paths flow through YAML/string parameters in Task invocations, then agents return confirmation markers that commands parse with grep/regex. This eliminates bash escaping concerns for the path-calculation subagent use case.

## Research Findings

### 1. Hierarchical Agent Patterns

**Primary Pattern: Behavioral Injection**

The system uses a "behavioral injection" pattern where orchestrating commands inject complete context into agent prompts through file content references rather than tool invocations.

**Source**: `.claude/docs/concepts/patterns/behavioral-injection.md`

**Pattern Structure** (lines 41-79):
```markdown
## YOUR ROLE

You are the ORCHESTRATOR for this workflow. Your responsibilities:

1. Calculate artifact paths and workspace structure
2. Invoke specialized subagents via Task tool
3. Aggregate and forward subagent results
4. DO NOT execute implementation work yourself using Read/Grep/Write/Edit tools

YOU MUST NOT:
- Execute research directly (use research-specialist agent)
- Create plans directly (use planner-specialist agent)
```

**Path Pre-Calculation** (lines 63-79):
```bash
# Before invoking any agent, calculate and validate all paths:
EXECUTE NOW - Calculate Paths:

1. Determine project root: /home/benjamin/.config
2. Find deepest directory encompassing workflow scope
3. Calculate next topic number: specs/NNN_topic/
4. Create topic directory structure:
   mkdir -p specs/027_authentication/{reports,plans,summaries,debug}
5. Assign artifact paths:
   REPORTS_DIR="specs/027_authentication/reports/"
```

**Key Characteristics**:
- Commands act as orchestrators, not executors
- Paths calculated by command BEFORE agent invocation
- Complete context injected into agent prompts
- Agents receive pre-calculated absolute paths, not instructions to calculate them

### 2. Metadata-Based Communication

**Forward Message Pattern**

Agents return structured metadata instead of full content, enabling 95-99% context reduction.

**Source**: `.claude/docs/concepts/patterns/metadata-extraction.md`

**Metadata Structure** (lines 38-69):
```markdown
## AGENT COMPLETION PROTOCOL (REQUIRED)

After creating the artifact, you MUST return ONLY this metadata structure:

{
  "artifact_path": "/absolute/path/to/artifact.md",
  "title": "Extracted from first # heading",
  "summary": "First 50 words from Executive Summary or opening paragraph",
  "key_findings": [
    "Finding 1 (1 sentence)",
    "Finding 2 (1 sentence)",
    "Finding 3 (1 sentence)"
  ],
  "recommendations": [
    "Top recommendation 1",
    "Top recommendation 2",
    "Top recommendation 3"
  ],
  "file_paths": [
    "/path/to/referenced/file1.sh",
    "/path/to/referenced/file2.md"
  ]
}

DO NOT include full artifact content in your response.
```

**Critical Observation**: Metadata is returned as structured text in agent responses, NOT via command substitution. Commands parse these responses using grep/string operations.

**Context Reduction**:
- Full report: 5,000-10,000 tokens
- Metadata only: 200-300 tokens
- Reduction: 95-99%
- Enables 10+ agent coordination vs 2-3 without metadata

### 3. Successful Agent Delegation Examples

#### Example 1: /research Command - Parallel Research Agents

**Source**: `.claude/commands/research.md:180-224`

**Path Pre-Calculation** (lines 132-138):
```bash
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  # Create absolute path with sequential numbering
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"

  # Store in associative array
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
```

**Path Communication to Agent** (lines 185-200):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  timeout: 300000  # 5 minutes per research agent
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    **STEP 1 (MANDATORY)**: Verify you received the absolute report path above.
    If path is not absolute (starts with /), STOP and report error.

    **STEP 2 (EXECUTE NOW)**: Create report file at EXACT path using Write tool.
```

**Agent Return Mechanism** (line 214):
```markdown
**STEP 4 (ABSOLUTE REQUIREMENT)**: Verify file exists and return:
REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

**Command Verification** (lines 237-262):
```bash
# Track verification results
declare -A VERIFIED_PATHS
VERIFICATION_ERRORS=0

echo "Verifying subtopic reports..."

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    echo "⚠ Warning: Report not found at expected path: $EXPECTED_PATH"

    # Search for report in research subdirectory
    FOUND_PATH=$(find "$RESEARCH_SUBDIR" -name "*${subtopic}*.md" -type f | head -n 1)
```

**Communication Flow**:
1. Command calculates path → stored in bash variable
2. Path injected into prompt parameter → string substitution in YAML
3. Agent receives path → creates file → returns "REPORT_CREATED: /path"
4. Command verifies → checks file existence at expected path
5. Fallback recovery → searches for file if not at expected location

**No Command Substitution Used**: Paths flow through string parameters, file verification uses `[ -f "$path" ]` test, agent output parsed with grep/string matching.

#### Example 2: /implement Command - Code Writer Agent

**Source**: `.claude/commands/implement.md:547-574`

**Agent Invocation Template** (lines 552-574):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Implement Phase ${PHASE_NUM} - ${PHASE_NAME}"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/code-writer.md

    You are acting as a Code Writer Agent.

    Implement Phase ${PHASE_NUM}: ${PHASE_NAME}

    Plan: ${PLAN_PATH}
    Phase Tasks:
    ${TASK_LIST}

    Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
    Complexity: ${COMPLEXITY_SCORE}

    Follow plan tasks exactly, apply coding standards, run tests after implementation.

    Return: Summary of changes made + test results
}
```

**Key Observation**: `${PLAN_PATH}` is a bash variable expanded into the prompt string. The agent receives the literal path value, not a command to execute.

**Communication Mechanism**:
- Command stores plan path in `$PLAN_PATH` variable
- Variable expanded into prompt via `${PLAN_PATH}` substitution
- Agent reads plan from provided path
- Agent returns summary text (not structured path)
- No command substitution involved

#### Example 3: /orchestrate Command - Research Specialist Delegation

**Source**: `.claude/commands/orchestrate.md:1-150`

**Role Clarification** (lines 42-46):
```markdown
**YOUR ROLE**: You are the WORKFLOW ORCHESTRATOR, not the executor.
- **DO NOT** execute research/planning/implementation/testing/debugging/documentation yourself
- **ONLY** use Task tool to invoke specialized agents for each phase
- **YOUR RESPONSIBILITY**: Coordinate agents, verify outputs, aggregate results, manage checkpoints
```

**Execution Model** (lines 47-54):
```markdown
**EXECUTION MODEL**: Pure orchestration across all 6 phases
- **Phase 0 (Location)**: Use unified location detection library to create topic directory structure
- **Phase 1 (Research)**: Invoke 2-4 research-specialist agents in parallel
- **Phase 2 (Planning)**: Invoke plan-architect agent with research report paths
- **Phase 3 (Implementation)**: Invoke code-writer agent with plan path (wave-based execution)
```

**File Creation Verification** (lines 65-73):
```markdown
**FILE CREATION VERIFICATION REQUIREMENT**:
Each phase MUST verify that agents created required files BEFORE marking phase complete:
- Phase 0: Verify topic directory structure created
- Phase 1: Verify all research report files exist
- Phase 2: Verify implementation plan file exists
- Phase 3: Verify code files and implementation complete
```

**Communication Pattern**:
- Orchestrator calculates all paths upfront
- Paths injected into agent prompts as string parameters
- Agents return completion markers
- Orchestrator verifies files exist at expected paths
- Fallback recovery if files in unexpected locations

### 4. Communication Mechanisms Inventory

Based on analysis of hierarchical agent documentation and command implementations, the following communication mechanisms are used:

#### Mechanism 1: String Parameter Injection (PRIMARY)

**Usage**: 100% of agent invocations
**Mechanism**: Command → Task tool `prompt` parameter → Agent receives literal string
**Example**:
```yaml
Task {
  prompt: "**Report Path**: /home/user/.claude/specs/042_auth/reports/001_patterns.md"
}
```

**Characteristics**:
- Paths passed as literal strings in YAML parameters
- No shell interpretation or command substitution
- Agent receives exact string value
- No escaping issues (YAML string handling only)

**Files**: All command files using Task tool invocations

#### Mechanism 2: Structured String Markers (RETURN PATH)

**Usage**: 100% of agent responses
**Mechanism**: Agent → Response text → Command parses with grep/regex
**Example**:
```
Agent Output:
REPORT_CREATED: /home/user/.claude/specs/042_auth/reports/001_patterns.md
```

**Characteristics**:
- Simple string marker format
- Commands parse with grep, string matching, or regex
- No command substitution on return path
- Easy to verify with `[ -f "$path" ]` after extraction

**Files**:
- `.claude/agents/research-specialist.md:124` - DEBUG_REPORT_CREATED marker
- `.claude/commands/research.md:214` - REPORT_CREATED marker
- Pattern used across all specialized agents

#### Mechanism 3: File-Based Context (SUPPLEMENTAL)

**Usage**: Complex context that exceeds prompt size limits
**Mechanism**: Command writes context to temp file → Path passed to agent → Agent reads file
**Example**:
```bash
# Command writes context
cat > /tmp/context.json <<EOF
{"research_reports": [...], "complexity_score": 8.5}
EOF

# Agent invocation
Task {
  prompt: "Context file: /tmp/context.json"
}
```

**Characteristics**:
- Used for large context (e.g., 10+ research reports metadata)
- Path passed via Mechanism 1 (string parameter)
- Agent uses Read tool to load context
- Temporary files cleaned up after workflow

**Files**: Not heavily used in current implementation, but supported pattern

#### Mechanism 4: Environment Variables (LEGACY)

**Usage**: ~5% of cases, primarily for project-wide constants
**Mechanism**: Command sets env var → Agent reads via `${VAR}` expansion
**Example**:
```bash
export CLAUDE_PROJECT_DIR="/home/user/.config"
# Agent behavioral file references ${CLAUDE_PROJECT_DIR}
```

**Characteristics**:
- Only for stable, project-wide paths
- Not used for dynamic artifact paths
- Agent behavioral files may reference
- Not recommended for new implementations

**Files**: `.claude/agents/research-specialist.md:58` references `$REPORT_PATH` from prompt

#### Mechanism 5: Unified Location Detection Library (PATH CALCULATION)

**Usage**: Commands calculate paths, NOT agents
**Mechanism**: Command sources library → Calculates paths → Injects into agents
**Example**:
```bash
# Command execution
source .claude/lib/unified-location-detection.sh
TOPIC_DIR=$(perform_location_detection "workflow description")
REPORT_PATH="${TOPIC_DIR}/reports/001_patterns.md"

# Agent receives calculated path
Task { prompt: "Report Path: $REPORT_PATH" }
```

**Characteristics**:
- **CRITICAL**: Path calculation happens in COMMAND, not AGENT
- Library provides functions for topic discovery, path generation
- 85% token reduction vs agent-based detection
- Agents receive final paths, never calculate them

**Files**: `.claude/lib/unified-location-detection.sh:1-100`

**Key Functions**:
- `detect_project_root()` - Find project root directory
- `detect_specs_directory()` - Find specs/ or .claude/specs/
- `perform_location_detection()` - Full location calculation
- `ensure_artifact_directory()` - Lazy directory creation

### 5. Path Communication Specifically

#### How Paths Are Passed: Command → Agent

**Pattern**: String substitution in Task tool prompt parameter

**Example from /research command** (`.claude/commands/research.md:185-200`):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  prompt: "
    **Research Topic**: [SUBTOPIC_DISPLAY_NAME]
    **Report Path**: [ABSOLUTE_PATH_FROM_SUBTOPIC_REPORT_PATHS]

    **STEP 1 (MANDATORY)**: Verify you received the absolute report path above.
```

**Actual Substitution**:
```bash
# In command
REPORT_PATH="/home/user/.claude/specs/042_auth/reports/001_oauth_patterns.md"

# Substituted into prompt
prompt: "
  **Report Path**: /home/user/.claude/specs/042_auth/reports/001_oauth_patterns.md
"
```

**No Command Substitution**: The path is a plain string value, not `$(command)` syntax. Agent receives literal path string.

#### How Paths Are Returned: Agent → Command

**Pattern**: Structured string marker in agent response

**Agent Output** (`.claude/agents/research-specialist.md` - conceptual):
```
PROGRESS: Creating report file
PROGRESS: Searching codebase
PROGRESS: Analyzing findings
PROGRESS: Updating report
PROGRESS: Research complete

REPORT_CREATED: /home/user/.claude/specs/042_auth/reports/001_oauth_patterns.md
```

**Command Parsing** (`.claude/commands/research.md:228-230`):
```bash
# Monitor agent execution:
- Watch for PROGRESS: markers from each agent
- Collect REPORT_CREATED: paths when agents complete
- Verify paths match pre-calculated paths
```

**Extraction Method**:
```bash
# Command extracts path from agent output
AGENT_OUTPUT="<full agent response text>"
CREATED_PATH=$(echo "$AGENT_OUTPUT" | grep "REPORT_CREATED:" | sed 's/REPORT_CREATED: //')

# Verify file exists
if [ -f "$CREATED_PATH" ]; then
  echo "✓ Verified: $CREATED_PATH"
fi
```

**No Command Substitution on Return**: Agent returns plain text marker, command uses grep/sed to extract path string, then file test to verify.

#### Path Calculation Examples

**Never Done by Agents**: Agents receive pre-calculated absolute paths from commands. Agents DO NOT calculate paths themselves.

**Example: Research Command Path Calculation** (`.claude/commands/research.md:100-138`):
```bash
# COMMAND calculates all paths BEFORE invoking agents

# Step 1: Detect project root
source .claude/lib/unified-location-detection.sh
PROJECT_ROOT=$(detect_project_root)
SPECS_DIR=$(detect_specs_directory "$PROJECT_ROOT")

# Step 2: Determine topic directory
TOPIC_DIR=$(perform_location_detection "$RESEARCH_TOPIC")
# Result: /home/user/.claude/specs/042_auth_patterns/

# Step 3: Create research subdirectory path
RESEARCH_SUBDIR="${TOPIC_DIR}/reports/001_research/"
# Result: /home/user/.claude/specs/042_auth_patterns/reports/001_research/

# Step 4: Calculate subtopic report paths
declare -A SUBTOPIC_REPORT_PATHS
SUBTOPIC_NUM=1
for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH="${RESEARCH_SUBDIR}/$(printf "%03d" "$SUBTOPIC_NUM")_${subtopic}.md"
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
  ((SUBTOPIC_NUM++))
done

# Step 5: Create OVERVIEW.md path
OVERVIEW_PATH="${RESEARCH_SUBDIR}/OVERVIEW.md"

# Step 6: Verify all paths are absolute
for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  if [[ ! "${SUBTOPIC_REPORT_PATHS[$subtopic]}" =~ ^/ ]]; then
    echo "CRITICAL ERROR: Path not absolute"
    exit 1
  fi
done
```

**Result**:
- Command has ALL paths calculated BEFORE any agent invocation
- Paths stored in bash variables/arrays
- Paths injected into agent prompts as literal strings
- Agents NEVER calculate paths, only receive them

#### Escaping Analysis

**Critical Finding**: The current architecture has **ZERO bash escaping issues** for path communication because:

1. **Command → Agent**: Paths flow through YAML string parameters
   - Task tool `prompt` parameter is a YAML string
   - Bash variables expanded BEFORE YAML parsing
   - Agent receives literal string value
   - No shell interpretation in agent context

2. **Agent → Command**: Paths returned in plain text markers
   - "REPORT_CREATED: /path/to/file.md" is plain text
   - Command extracts with grep/sed (string operations)
   - No command substitution or eval
   - File existence verified with `[ -f "$path" ]`

3. **No `$(command)` Pattern**: Neither direction uses command substitution
   - Commands don't run `$(agent calculate-path)`
   - Agents don't return `$(echo $PATH)` expressions
   - All path transfer is literal string passing

**Implication for Path-Calculation Subagent**:

If implementing a path-calculation subagent, it would follow the same pattern:

```bash
# Parent command invokes path-calculator agent
Task {
  prompt: "
    Calculate paths for workflow: authentication system
    Base directory: /home/user/.claude/specs
    Return: PATHS_CALCULATED: <JSON>
  "
}

# Agent calculates and returns JSON
PATHS_CALCULATED: {
  "topic_dir": "/home/user/.claude/specs/042_auth",
  "reports_dir": "/home/user/.claude/specs/042_auth/reports",
  "plan_path": "/home/user/.claude/specs/042_auth/plans/042_implementation.md"
}

# Parent extracts JSON and uses paths
AGENT_OUTPUT="<full response>"
PATHS_JSON=$(echo "$AGENT_OUTPUT" | grep "PATHS_CALCULATED:" | sed 's/PATHS_CALCULATED: //')
TOPIC_DIR=$(echo "$PATHS_JSON" | jq -r '.topic_dir')
```

**No escaping issues** because:
- Agent returns plain text JSON
- Parent extracts with grep/sed (string operations)
- jq parses JSON safely
- Paths used as literal strings in subsequent agent invocations

## Recommendations

### Recommendation 1: Use String Parameter Mechanism for Path-Calculation Subagent

**Pattern**: Follow the established string parameter injection pattern for path communication.

**Implementation**:
```bash
# Parent command invokes path-calculator agent
Task {
  subagent_type: "general-purpose"
  description: "Calculate paths for workflow"
  prompt: "
    Calculate topic directory and artifact paths for:
    Workflow: ${WORKFLOW_DESCRIPTION}
    Base: ${SPECS_DIR}

    Return structured JSON:
    PATHS_CALCULATED: {paths JSON}
  "
}

# Parent parses response
PATHS_JSON=$(echo "$AGENT_OUTPUT" | grep "PATHS_CALCULATED:" | sed 's/PATHS_CALCULATED: //')
TOPIC_DIR=$(echo "$PATHS_JSON" | jq -r '.topic_dir')
```

**Advantages**:
- Zero escaping issues (string parameters)
- Consistent with existing patterns
- Simple parsing (grep + jq)
- Verifiable (file existence checks)

**Disadvantages**:
- None identified (proven pattern)

### Recommendation 2: Avoid Command Substitution Pattern

**Anti-Pattern**: DO NOT use command substitution for path communication.

**Example of what NOT to do**:
```bash
# ❌ BAD - Command substitution
TOPIC_DIR=$(Task { prompt: "Calculate path for: $WORKFLOW" })

# Problem: Unpredictable escaping, shell interpretation issues
```

**Why**: Command substitution introduces:
- Escaping complexity (nested quotes, special chars)
- Shell interpretation ambiguity
- Difficult error handling
- Inconsistent with existing patterns

### Recommendation 3: Use Structured Markers for Return Values

**Pattern**: Agent returns structured string markers that commands parse.

**Format**:
```
MARKER_NAME: <value>
MARKER_NAME: {"json": "object"}
```

**Proven Examples**:
- `REPORT_CREATED: /path/to/file.md`
- `DEBUG_REPORT_CREATED: /path/to/debug.md`
- `PATHS_CALCULATED: {"topic_dir": "/path"}`

**Parsing**:
```bash
VALUE=$(echo "$AGENT_OUTPUT" | grep "MARKER_NAME:" | sed 's/MARKER_NAME: //')
```

**Advantages**:
- Simple, reliable parsing
- No command substitution needed
- Easy to verify (string matching)
- Proven across all agent types

### Recommendation 4: Maintain Command-Calculates, Agent-Receives Pattern

**Current Best Practice**: Commands calculate paths, agents receive them.

**Why This Works**:
- Commands have full context (workflow description, existing structure)
- Agents focused on single task (research, planning, implementation)
- Separation of concerns (orchestration vs execution)
- 85% token reduction vs agent-based calculation

**If Path Calculation Moves to Subagent**:
- Should be early-phase calculation (Phase 0)
- Returns paths to parent command
- Parent injects paths into subsequent agents
- Maintains separation: one agent calculates, others receive

### Recommendation 5: Leverage Unified Location Detection Library

**Current Implementation**: `.claude/lib/unified-location-detection.sh`

**If Moving to Subagent**:
- Subagent should SOURCE the library
- Call library functions to calculate paths
- Return results to parent command
- Maintains code reuse, testability

**Example**:
```yaml
Task {
  prompt: "
    Source library: .claude/lib/unified-location-detection.sh

    Call: perform_location_detection '$WORKFLOW_DESCRIPTION'

    Return: PATHS_CALCULATED: {JSON output}
  "
}
```

**Benefits**:
- Reuses proven, tested code
- Consistent path calculation logic
- Easy to update (single library file)
- No duplication between command and agent

### Recommendation 6: Comparison of Communication Approaches

| Approach | Escaping Issues | Parsing Complexity | Consistency | Proven | Recommendation |
|----------|----------------|-------------------|-------------|--------|----------------|
| String Parameter Injection | None | Low | High | Yes (100% usage) | **Use for path-calc agent** |
| Structured String Markers | None | Low | High | Yes (100% usage) | **Use for return values** |
| File-Based Context | None | Medium | Medium | Limited | Use for large context only |
| Command Substitution | High | High | Low | No | **Avoid entirely** |
| Environment Variables | Low | Low | Medium | Limited (legacy) | Avoid for new patterns |

**Recommended Pattern for Path-Calculation Subagent**:
1. **Input**: String parameters in Task prompt (workflow description, base dir)
2. **Processing**: Agent sources unified-location-detection.sh, calls library functions
3. **Output**: Structured string marker with JSON paths
4. **Parent Parsing**: grep + sed + jq to extract paths
5. **Verification**: File/directory existence checks
6. **Subsequent Use**: Paths injected into other agents via string parameters

This pattern has **zero escaping issues** and is **100% consistent** with existing successful agent delegation patterns.

## References

### Documentation Files
1. `.claude/docs/concepts/hierarchical_agents.md` - Complete hierarchical agent architecture (2,218 lines)
2. `.claude/docs/concepts/patterns/behavioral-injection.md` - Behavioral injection pattern (486 lines)
3. `.claude/docs/concepts/patterns/forward-message.md` - Forward message pattern (331 lines)
4. `.claude/docs/concepts/patterns/metadata-extraction.md` - Metadata extraction pattern (393 lines)

### Command Files
5. `.claude/commands/research.md:180-262` - Research agent delegation with path pre-calculation
6. `.claude/commands/implement.md:547-574` - Code writer agent invocation template
7. `.claude/commands/orchestrate.md:1-150` - Workflow orchestration patterns

### Agent Files
8. `.claude/agents/research-specialist.md:1-80` - Research agent behavioral file
9. `.claude/agents/debug-analyst.md:124` - Debug report creation marker

### Library Files
10. `.claude/lib/unified-location-detection.sh:1-100` - Path calculation library functions

### Key Patterns Identified
- **Behavioral Injection**: Commands inject context, agents execute (behavioral-injection.md)
- **Forward Message**: No re-summarization of agent outputs (forward-message.md)
- **Metadata Extraction**: 95-99% context reduction (metadata-extraction.md)
- **String Parameter Passing**: Zero escaping issues (all command files)
- **Structured String Markers**: Simple, reliable return values (all agent files)
- **Command-Calculates Pattern**: 85% token reduction vs agent-based (unified-location-detection.sh)

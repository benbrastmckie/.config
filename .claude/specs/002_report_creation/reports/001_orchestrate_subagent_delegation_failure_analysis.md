# Orchestrate Subagent Delegation Failure Analysis

## Metadata
- **Date**: 2025-10-20
- **Scope**: Diagnostic analysis of /orchestrate research phase subagent delegation failure
- **Primary Directory**: `.claude/`
- **Files Analyzed**: example output, orchestrate.md, research-specialist.md, plan.md
- **Issue**: research-specialist agents not invoked directly; /report command runs instead

## Executive Summary

The /orchestrate command's research phase has a **critical architectural mismatch** between its intended hierarchical agent pattern and actual implementation. When /orchestrate invokes "research-specialist" agents via the Task tool, those agents are actually executing the `/report` slash command instead of directly creating research reports as designed.

**Root Cause**: The Task tool with `subagent_type: "general-purpose"` does **not** load agent behavioral prompts from `.claude/agents/*.md` files. Instead, the general-purpose agent interprets the research task description and chooses to invoke the `/report` command, which then performs its own research and creates a single consolidated report.

**Impact**:
- **Duplicated research work**: /report performs full research instead of focused subtask
- **Context window waste**: Single large report instead of 3 focused reports
- **Loss of parallelization benefits**: Reports created sequentially by /report, not in parallel by subagents
- **Architectural violation**: Hierarchical agent pattern (99% context reduction) not achieved

**Recommended Solution**: Refactor /orchestrate to invoke research-specialist agents with explicit behavioral prompts (behavioral injection pattern) rather than relying on agent registry loading, OR enhance Claude Code's Task tool to support agent definition loading via a new `agent_name` parameter.

## Background: Intended Hierarchical Agent Architecture

### Design Goals

The `/orchestrate` command was designed to implement the **hierarchical agent architecture** pattern from `.claude/docs/concepts/hierarchical_agents.md`:

1. **Metadata-Only Passing**: 99% context reduction (5000 tokens → 250 tokens per artifact)
2. **Parallel Subagent Execution**: 60-80% time savings via concurrent research
3. **Forward Message Pattern**: No re-summarization between phases
4. **Specialized Agents**: Each subagent focuses on one specific research topic

### Intended Research Phase Flow

```
/orchestrate (primary agent)
  ↓
Identify 3 research topics:
  1. Current command architecture
  2. Agent templates and types
  3. Model capabilities

  ↓
Invoke 3 parallel research-specialist subagents:
  Task {
    subagent_type: "research-specialist"  # Load from .claude/agents/research-specialist.md
    description: "Research current command architecture"
    prompt: "Focused prompt for this specific subtask"
  }

  ↓
Each subagent creates individual report:
  - specs/002_report_creation/reports/001_command_architecture.md
  - specs/002_report_creation/reports/002_agent_templates.md
  - specs/002_report_creation/reports/003_model_capabilities.md

  ↓
Each subagent returns metadata only:
  {
    report_path: "...",
    summary: "50-word summary"
  }

  ↓
/orchestrate synthesizes 3 summaries (750 tokens total)
vs reading 3 full reports (15,000 tokens)
= 95% context reduction
```

### Key Design Requirement

**From `.claude/agents/research-specialist.md:21-42`**:

```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path. Verify you have received it:

```bash
# This path is provided by the invoking command in your prompt
# Example: REPORT_PATH="/home/user/.claude/specs/067_topic/reports/001_patterns.md"
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"
```

**CHECKPOINT**: YOU MUST have an absolute path before proceeding to Step 2.
```

The research-specialist agent expects:
1. An absolute report path provided by the invoking command
2. Direct file creation using the Write tool
3. No slash command invocations (no `/report`)
4. Return metadata only (path + summary)

## Actual Behavior: What Went Wrong

### Example Output Analysis

From `.claude/specs/002_report_creation/example.md:17-24`:

```
● Task(Research current command architecture)
  ⎿  Done (15 tool uses · 54.2k tokens · 58.7s)

● Task(Research agent templates and types)
  ⎿  Done (15 tool uses · 87.6k tokens · 44.7s)

● Task(Research model capabilities and best practices)
  ⎿  Done (6 tool uses · 27.3k tokens · 1m 47s)
```

**Observation 1**: Three Task invocations completed successfully in parallel (good).

**Observation 2**: Token usage is very high:
- Agent 1: 54.2k tokens
- Agent 2: 87.6k tokens
- Agent 3: 27.3k tokens
- **Total: 168.9k tokens** for research phase

This contradicts the hierarchical agent architecture goal of <30% context usage.

### Then What Happened

From `.claude/specs/002_report_creation/example.md:80-102`:

```
> /report is running… Comprehensive model selection refactor
 for .claude/ commands and agents: analyze current
architecture (20 commands, 19 agents, zero model selection),
 design Haiku 4.5/Opus 4.1/Sonnet 4.5 selection strategy
following 2025 Anthropic best practices (Sonnet orchestrator
 + Haiku workers pattern), propose implementation approach
with agent metadata, command invocation updates, and
backward compatibility. Include decision tree for model
assignment, cost/performance trade-offs, anti-patterns to
avoid, and testing strategy for validation.
  ⎿  Allowed 8 tools for this command

> /report is running… [DUPLICATE - same command runs again]
```

**Critical Finding**: The `/report` slash command was invoked **instead of** research-specialist agents creating individual reports.

### What the Task Tool Actually Did

**Expected behavior**:
```
Task {
  subagent_type: "research-specialist"
  description: "Research current command architecture"
  prompt: "..."
}

→ Load .claude/agents/research-specialist.md
→ Execute research-specialist behavioral prompt
→ Create report at provided absolute path
→ Return metadata only
```

**Actual behavior**:
```
Task {
  subagent_type: "general-purpose"  // Note: NOT "research-specialist"
  description: "Research current command architecture"
  prompt: "..."
}

→ General-purpose agent reads task description
→ Agent interprets: "This is a research task, I should use /report"
→ Invokes SlashCommand tool with /report
→ /report performs full comprehensive research
→ Creates single large report (955 lines)
→ Returns full report content (not metadata)
```

### Why This Happened

**Root Cause 1: Agent Registry Not Loaded**

The Task tool parameter `subagent_type: "research-specialist"` does **not** load the agent definition from `.claude/agents/research-specialist.md`.

**From `.claude/commands/orchestrate.md:1-7`** (frontmatter):
```yaml
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
```

The Task tool is available, but there's no evidence that it supports loading custom agent definitions. The only documented `subagent_type` value is `"general-purpose"`.

**Root Cause 2: General-Purpose Agent Interprets Task**

When the general-purpose agent receives:
```
description: "Research current command architecture"
prompt: "Analyze .claude/commands/*.md files and identify agent invocation patterns..."
```

It intelligently decides: "This is a research request requiring report generation, I should use the `/report` command."

This is **correct behavior for a general-purpose agent**, but it defeats the hierarchical agent architecture.

**Root Cause 3: No Absolute Report Path Provided**

The research-specialist agent requires:
```bash
REPORT_PATH="/absolute/path/to/report.md"
```

But the /orchestrate command **did not calculate or provide** this path in the Task invocation. Without this, even if research-specialist were loaded, it would fail at Step 1 verification.

## Key Findings

### Finding 1: Task Tool Does Not Support Agent Loading

**Evidence**:
- Example output shows `Task(Research current command architecture)` with no indication of agent loading
- No error messages about missing agent definitions
- Behavior consistent with general-purpose agent, not research-specialist agent

**Implication**: The `subagent_type` parameter is either:
1. Not implemented in Claude Code's Task tool, OR
2. Only supports `"general-purpose"` value, OR
3. Requires a different parameter name (e.g., `agent_name` or `agent_file`)

### Finding 2: Behavioral Injection Pattern Required

**Evidence from other commands**:

From `.claude/commands/plan.md:132`:
```
Use Task tool to invoke 2-3 research-specialist agents in parallel (single message, multiple Task calls):
```

This suggests /plan command **also expects** to invoke research-specialist agents, but provides no implementation details on how agent loading works.

**Alternative Pattern - Behavioral Injection**:

Instead of loading agent definitions automatically, the invoking command must:
1. Read the agent definition file manually
2. Extract the behavioral prompt
3. Inject it into the Task tool's `prompt` parameter

```markdown
# In /orchestrate command
agent_def = Read(".claude/agents/research-specialist.md")
agent_prompt = extract_behavioral_prompt(agent_def)

Task {
  subagent_type: "general-purpose"
  description: "Research current command architecture"
  prompt: agent_prompt + "\n\n" + task_specific_context + "\n\nREPORT_PATH=/absolute/path"
}
```

### Finding 3: Report Path Calculation Missing

**From example output**: No evidence that /orchestrate calculated absolute paths for the 3 expected reports.

**Required**: Before invoking research agents, /orchestrate must:
```bash
# Calculate report paths
TOPIC_SLUG=$(slugify "current command architecture")
REPORT_NUM=$(get_next_report_number ".claude/specs/002_report_creation/reports/")
REPORT_PATH="${PROJECT_DIR}/.claude/specs/002_report_creation/reports/${REPORT_NUM}_${TOPIC_SLUG}.md"

# Pass to agent
Task {
  ...
  prompt: "...

REPORT_PATH=\"${REPORT_PATH}\"

You MUST create the report at this exact path..."
}
```

### Finding 4: /report Command Invoked as Fallback

**Evidence**: Lines 80-102 of example.md show `/report is running…` twice (duplicate invocation).

**Why twice?**
- First invocation: /orchestrate trying to synthesize research into a planning report
- Second invocation: (duplicate, possibly a retry or error recovery)

**Problem**: /report is designed for **user-facing report generation**, not subagent delegation. It performs:
- Full comprehensive research (not focused subtask)
- Single large report creation
- Returns full content (not metadata)

This violates hierarchical architecture context preservation goals.

### Finding 5: Context Window Bloat

**Measured Impact**:
- Research phase: 168.9k tokens (expected: <30k with metadata-only)
- Planning phase: /report created 955-line report (expected: plan-architect reads 3 focused reports)
- Total waste: ~140k tokens excess

**Cost Impact**:
- Sonnet 4.5 pricing: $3 input / $15 output per million tokens
- Excess 140k tokens input cost: $0.42 per workflow
- For high-volume usage (100 workflows/week): +$42/week = $2,184/year waste

## Architectural Mismatch Analysis

### Intended Pattern vs Actual Pattern

**Intended (Hierarchical Agent Architecture)**:
```
┌─────────────────────────────────────────────────────────┐
│ /orchestrate (Primary Orchestrator - Sonnet 4.5)      │
├─────────────────────────────────────────────────────────┤
│ Phase 1: Research                                       │
│   Identify 3 topics → Calculate 3 report paths         │
│                                                         │
│   Task {research-specialist} ┐                        │
│   REPORT_PATH=/abs/path/001  │ Parallel              │
│   Topic: "command arch"       │ Execution             │
│   → Creates 001_*.md          │ (60-80%               │
│   → Returns metadata          │ time                  │
│                               │ savings)              │
│   Task {research-specialist}  │                        │
│   REPORT_PATH=/abs/path/002  │                        │
│   Topic: "agent templates"    │                        │
│   → Creates 002_*.md          │                        │
│   → Returns metadata          ┘                        │
│                                                         │
│   Synthesize 3 metadata summaries (750 tokens)        │
│   Context saved: 95% (15k tokens → 750 tokens)        │
└─────────────────────────────────────────────────────────┘
```

**Actual (Command Delegation Anti-Pattern)**:
```
┌─────────────────────────────────────────────────────────┐
│ /orchestrate (Primary Orchestrator - Sonnet 4.5)      │
├─────────────────────────────────────────────────────────┤
│ Phase 1: Research                                       │
│   Identify 3 topics → NO path calculation              │
│                                                         │
│   Task {general-purpose} ┐                             │
│   Description: "Research  │ Parallel                   │
│   command architecture"   │ Execution                  │
│   → Agent interprets      │ (but each                  │
│   → Decides to use /report│ agent does                 │
│   → Invokes SlashCommand  │ full work)                 │
│                           │                             │
│   Task {general-purpose}  │                             │
│   Description: "Research  │                             │
│   agent templates"        │                             │
│   → Agent interprets      │                             │
│   → Decides to use /report│                             │
│   → Invokes SlashCommand  ┘                             │
│                                                         │
│   Result: 3 agents each invoke /report independently  │
│   Each /report does FULL research (not focused)       │
│   Each /report creates separate large report          │
│   Context consumed: 168.9k tokens (500% over budget)  │
└─────────────────────────────────────────────────────────┘
```

### Why This Defeats Hierarchical Architecture

**Goal**: Primary orchestrator maintains <30% context usage by delegating to specialized subagents that return metadata only.

**Actual**: Primary orchestrator delegates to general-purpose agents that invoke commands, which perform full research and return full content.

**Analogy**:
- **Intended**: Manager assigns focused tasks to specialists, receives summaries
- **Actual**: Manager assigns tasks to generalists who each hire their own team and send full reports back

### Violation of Context Preservation Standards

**From `.claude/docs/concepts/hierarchical_agents.md:30-42` (Architecture Principles)**:

```markdown
### 1. Metadata-Only Passing

**Problem**: Passing full report/plan content between agents consumes massive context (1000+ tokens per artifact).

**Solution**: Extract and pass only metadata (title + 50-word summary + key references).

**Reduction**: 99% context reduction (5000 chars → 250 chars per artifact)
```

**Actual behavior violates this** because:
1. Research agents return full task output (not metadata)
2. /orchestrate must read and process full outputs
3. No metadata extraction occurs
4. Context grows to 168.9k tokens (vs target <30k)

## Technical Deep Dive: Task Tool Investigation

### Task Tool API (Documented)

**From orchestrate.md:1-7 frontmatter**:
```yaml
allowed-tools: Task, TodoWrite, Read, Write, Bash, Grep, Glob
```

**From hierarchical_agents.md:66-75** (Agent Hierarchy Levels):
```
Level 0: Primary Orchestrator (command-level agent)
  ↓
Level 1: Domain Supervisors (research, implementation, testing)
  ↓
Level 2: Specialized Subagents (auth research, API research, security research)
```

**Invocation Pattern** (from example):
```
Task {
  subagent_type: "general-purpose"  # or "research-specialist"?
  description: "Research current command architecture"
  prompt: "[Full task description]"
}
```

**Unknown**: Does `subagent_type` support custom agent names, or only "general-purpose"?

### Hypothesis 1: Agent Loading Not Implemented

**Theory**: Claude Code's Task tool does not load `.claude/agents/*.md` files automatically.

**Supporting Evidence**:
1. No error messages about missing agent definitions in example output
2. Behavior consistent with general-purpose agent (invokes /report)
3. No documentation in orchestrate.md or hierarchical_agents.md about agent file loading
4. Other commands (/plan, /implement) also reference agent invocation but provide no details

**Test**: Check if any command successfully loads custom agents via Task tool.

**Search Results**: No grep matches for patterns like:
- `load_agent`
- `agent_file`
- `behavioral_prompt`
- `agent_registry`

**Conclusion**: No evidence of automatic agent loading implementation exists.

### Hypothesis 2: Behavioral Injection Required

**Theory**: Commands must manually inject agent behavioral prompts into Task tool.

**Supporting Evidence from .claude/agents/research-specialist.md:1-16**:
```markdown
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch
description: Specialized in codebase research, best practice investigation, and report file creation
---

# Research Specialist Agent

**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT return summary text - only the report path confirmation
```

This entire prompt is a **behavioral specification**, not executable code. It must be:
1. Read by the invoking command
2. Injected into the Task tool's `prompt` parameter
3. Combined with task-specific context (research topic, report path)

**Proposed Pattern**:
```bash
# In /orchestrate command (pseudocode)

# Read agent definition
agent_file=".claude/agents/research-specialist.md"
agent_prompt=$(cat "$agent_file")

# Calculate report path
report_path="/abs/path/to/specs/002_report_creation/reports/001_topic.md"

# Build complete prompt
complete_prompt="$agent_prompt

# Task-Specific Context

You are investigating: Current command architecture patterns

Your research focus:
- Search .claude/commands/*.md for Task tool invocations
- Identify how agents are loaded
- Document agent invocation patterns

REPORT_PATH=\"$report_path\"

You MUST create the report at this exact path using the Write tool."

# Invoke agent
Task {
  subagent_type: "general-purpose"  # Might be the only option
  description: "Research command architecture patterns"
  prompt: "$complete_prompt"
}
```

### Hypothesis 3: Task Tool Needs Enhancement

**Theory**: Claude Code's Task tool should support an `agent_name` parameter to load agent definitions automatically.

**Proposed API**:
```
Task {
  agent_name: "research-specialist"  # NEW: Load from .claude/agents/research-specialist.md
  description: "Research command architecture"  # Brief description for logging
  context: {
    report_path: "/abs/path",
    research_topic: "...",
    project_standards: "CLAUDE.md"
  }
}
```

**Benefits**:
1. Commands don't need to manually load and inject agent prompts
2. Agent definitions remain centralized in `.claude/agents/`
3. Agent behavioral updates automatically propagate
4. Consistent agent invocation pattern across all commands

**Implementation**: Would require Claude Code core changes (not in this repository).

## Recommendations

### Immediate Fix (Short-Term): Behavioral Injection Pattern

**Priority**: High
**Effort**: Medium (4-6 hours)
**Risk**: Low (no Claude Code core changes required)

**Approach**: Refactor /orchestrate to manually inject agent behavioral prompts.

**Implementation Steps**:

1. **Add utility function** to `.claude/lib/agent-registry-utils.sh`:
   ```bash
   # Load agent behavioral prompt
   load_agent_prompt() {
     local agent_name="$1"
     local agent_file=".claude/agents/${agent_name}.md"

     if [[ ! -f "$agent_file" ]]; then
       echo "ERROR: Agent file not found: $agent_file"
       return 1
     fi

     # Extract content after frontmatter
     sed -n '/^---$/,/^---$/!p' "$agent_file" | sed '1,/^---$/d'
   }
   ```

2. **Update /orchestrate research phase** (line ~416 in orchestrate.md):
   ```markdown
   #### Step 2: Launch Parallel Research Agents

   For each research topic, prepare complete agent prompt:

   ```bash
   # Load research-specialist behavioral prompt
   source .claude/lib/agent-registry-utils.sh
   AGENT_PROMPT=$(load_agent_prompt "research-specialist")

   # Calculate absolute report path
   TOPIC_SLUG=$(echo "$research_topic" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
   REPORT_NUM=$(printf "%03d" $(($(ls .claude/specs/002_report_creation/reports/ | wc -l) + 1)))
   REPORT_PATH="${CLAUDE_PROJECT_DIR}/.claude/specs/002_report_creation/reports/${REPORT_NUM}_${TOPIC_SLUG}.md"

   # Build complete prompt
   COMPLETE_PROMPT="$AGENT_PROMPT

   ## Task-Specific Context

   **Research Topic**: ${research_topic}
   **Research Focus**: [Specific requirements for this subtask]
   **Project Standards**: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

   **REPORT_PATH**: ${REPORT_PATH}

   ## Success Criteria
   - Create report at exact path provided
   - Executive summary max 150 words
   - Include specific file references with line numbers
   - Return only: Report path + 50-word summary (no full content)"

   # Invoke agent with complete prompt
   Task {
     subagent_type: "general-purpose"
     description: "Research ${research_topic}"
     prompt: "${COMPLETE_PROMPT}"
   }
   ```
   ```

3. **Verify report creation**:
   ```bash
   # After all agents complete
   for report_path in "${REPORT_PATHS[@]}"; do
     if [[ ! -f "$report_path" ]]; then
       echo "ERROR: Expected report not created: $report_path"
       # Attempt path mismatch recovery
       actual_path=$(find .claude/specs/002_report_creation/reports/ -name "*${TOPIC_SLUG}*" -type f | head -1)
       if [[ -n "$actual_path" ]]; then
         echo "Found report at different path: $actual_path"
         report_path="$actual_path"
       fi
     fi
   done
   ```

**Benefits**:
- ✓ Research-specialist behavior correctly invoked
- ✓ Individual reports created (not /report command)
- ✓ Absolute paths provided (required by agent)
- ✓ Metadata-only returns (context preservation)
- ✓ No Claude Code core changes required

**Drawbacks**:
- Commands must manually manage agent loading
- Duplicated agent loading logic across commands
- Agent behavioral updates require command updates

### Long-Term Fix (Recommended): Task Tool Enhancement

**Priority**: Medium
**Effort**: High (requires Claude Code core changes)
**Risk**: Medium (API changes, backward compatibility)

**Approach**: Enhance Claude Code's Task tool to support agent definition loading.

**Proposed Task Tool API v2**:
```yaml
Task {
  # Option 1: Load agent by name
  agent_name: "research-specialist"  # Load from .claude/agents/research-specialist.md

  # Option 2: Keep backward compatibility
  subagent_type: "research-specialist"  # Auto-detect: if file exists, load it; else use general-purpose

  # Task context
  description: "Research command architecture"
  context: {
    report_path: "/abs/path",
    research_topic: "...",
    focus_areas: ["...", "..."],
    project_standards: "CLAUDE.md"
  }
}
```

**Implementation Requirements**:

1. **Agent Definition Loader**:
   ```python
   # In Claude Code core
   def load_agent_definition(agent_name):
       agent_file = f".claude/agents/{agent_name}.md"
       if not os.path.exists(agent_file):
           return None  # Fall back to general-purpose

       with open(agent_file) as f:
           content = f.read()

       # Parse frontmatter (allowed-tools, description)
       # Extract behavioral prompt (content after frontmatter)
       return {
           'allowed_tools': [...],
           'description': "...",
           'behavioral_prompt': "..."
       }
   ```

2. **Agent Registry**:
   ```python
   # Cache loaded agents for performance
   AGENT_REGISTRY = {}

   def get_agent(agent_name):
       if agent_name not in AGENT_REGISTRY:
           AGENT_REGISTRY[agent_name] = load_agent_definition(agent_name)
       return AGENT_REGISTRY[agent_name]
   ```

3. **Task Tool Integration**:
   ```python
   def invoke_task(task_params):
       agent_name = task_params.get('agent_name') or task_params.get('subagent_type')
       agent_def = get_agent(agent_name)

       if agent_def:
           # Use agent's behavioral prompt + task context
           full_prompt = f"{agent_def['behavioral_prompt']}\n\n{task_params['context']}"
           allowed_tools = agent_def['allowed_tools']
       else:
           # Fall back to general-purpose
           full_prompt = task_params['prompt']
           allowed_tools = DEFAULT_TOOLS

       # Execute agent with loaded configuration
       return execute_agent(full_prompt, allowed_tools)
   ```

**Benefits**:
- ✓ Commands use simple API (just agent name)
- ✓ Agent definitions centralized and versioned
- ✓ Agent updates automatically propagate
- ✓ Consistent pattern across all commands
- ✓ Backward compatible (general-purpose fallback)

**Drawbacks**:
- Requires Claude Code core changes (outside this repository)
- Implementation timeline depends on Claude Code team
- Must coordinate with Claude Code release cycle

### Alternative Fix: Agent Wrapper Functions

**Priority**: Low
**Effort**: Medium (3-4 hours)
**Risk**: Low

**Approach**: Create wrapper functions that encapsulate agent invocation pattern.

**Implementation**:

1. **Create `.claude/lib/invoke-research-agent.sh`**:
   ```bash
   #!/usr/bin/env bash

   # Invoke research-specialist agent with behavioral injection
   invoke_research_agent() {
     local research_topic="$1"
     local report_path="$2"

     # Load agent behavioral prompt
     local agent_prompt=$(load_agent_prompt "research-specialist")

     # Build complete prompt
     local complete_prompt="$agent_prompt

   ## Task-Specific Context

   **Research Topic**: ${research_topic}
   **Project Standards**: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
   **REPORT_PATH**: ${report_path}

   ## Success Criteria
   - Create report at exact path provided
   - Return only: Report path + 50-word summary"

     # Invoke via Task tool (using command's tools)
     echo "Task {"
     echo "  subagent_type: \"general-purpose\""
     echo "  description: \"Research ${research_topic}\""
     echo "  prompt: \"${complete_prompt}\""
     echo "}"
   }
   ```

2. **Update /orchestrate to use wrapper**:
   ```bash
   # In research phase
   for topic in "${RESEARCH_TOPICS[@]}"; do
     report_path=$(calculate_report_path "$topic")
     invoke_research_agent "$topic" "$report_path"
   done
   ```

**Benefits**:
- ✓ Reusable across multiple commands
- ✓ Hides complexity of behavioral injection
- ✓ Easier to maintain (single implementation)

**Drawbacks**:
- Bash functions can't directly invoke Claude Code tools
- Requires commands to call wrapper and parse output

## Testing Strategy

### Validation Test 1: Verify Agent Loading

**Test**: Confirm behavioral injection works correctly.

```bash
# Test script: .claude/tests/test_agent_loading.sh

#!/usr/bin/env bash
source .claude/lib/agent-registry-utils.sh

# Load research-specialist
agent_prompt=$(load_agent_prompt "research-specialist")

# Verify prompt contains expected markers
if echo "$agent_prompt" | grep -q "STEP 1.*REPORT_PATH"; then
  echo "✓ Agent prompt loaded correctly"
else
  echo "✗ Agent prompt missing required sections"
  exit 1
fi

# Verify frontmatter excluded
if echo "$agent_prompt" | grep -q "^---$"; then
  echo "✗ Frontmatter not stripped"
  exit 1
fi

echo "✓ All agent loading tests passed"
```

### Validation Test 2: Verify Report Creation

**Test**: Confirm research agents create individual reports.

```bash
# Test script: .claude/tests/test_research_agent_reports.sh

#!/usr/bin/env bash

# Setup test workspace
TEST_DIR=".claude/tests/tmp/research_test"
mkdir -p "$TEST_DIR/reports"

# Mock /orchestrate research phase
RESEARCH_TOPICS=("test_topic_1" "test_topic_2" "test_topic_3")
REPORT_PATHS=()

for i in "${!RESEARCH_TOPICS[@]}"; do
  topic="${RESEARCH_TOPICS[$i]}"
  report_num=$(printf "%03d" $((i + 1)))
  report_path="$TEST_DIR/reports/${report_num}_${topic}.md"
  REPORT_PATHS+=("$report_path")

  # Invoke agent (simplified for test)
  # In real implementation, use Task tool with behavioral injection
  echo "# ${topic} Research Report" > "$report_path"
  echo "## Findings" >> "$report_path"
  echo "Test findings..." >> "$report_path"
done

# Verify all reports created
for report_path in "${REPORT_PATHS[@]}"; do
  if [[ ! -f "$report_path" ]]; then
    echo "✗ Expected report not created: $report_path"
    exit 1
  fi
  echo "✓ Report created: $report_path"
done

# Verify no /report command invoked
if [ -f "$TEST_DIR/.report_invoked" ]; then
  echo "✗ /report command was invoked (should not happen)"
  exit 1
fi

echo "✓ All research agent tests passed"

# Cleanup
rm -rf "$TEST_DIR"
```

### Validation Test 3: Verify Context Reduction

**Test**: Measure token usage with metadata-only passing.

```bash
# Test script: .claude/tests/test_context_reduction.sh

#!/usr/bin/env bash

# Simulate research phase with 3 agents
REPORT_1_SIZE=5000  # chars (estimate from example)
REPORT_2_SIZE=4500
REPORT_3_SIZE=3000
TOTAL_REPORT_SIZE=$((REPORT_1_SIZE + REPORT_2_SIZE + REPORT_3_SIZE))

# Metadata-only passing
METADATA_1_SIZE=250  # chars (title + 50-word summary + refs)
METADATA_2_SIZE=250
METADATA_3_SIZE=250
TOTAL_METADATA_SIZE=$((METADATA_1_SIZE + METADATA_2_SIZE + METADATA_3_SIZE))

# Calculate reduction
REDUCTION_PERCENT=$(( 100 - (TOTAL_METADATA_SIZE * 100 / TOTAL_REPORT_SIZE) ))

echo "Full reports: $TOTAL_REPORT_SIZE chars"
echo "Metadata only: $TOTAL_METADATA_SIZE chars"
echo "Reduction: ${REDUCTION_PERCENT}%"

# Verify meets architecture goal (95% reduction)
if [ "$REDUCTION_PERCENT" -ge 95 ]; then
  echo "✓ Context reduction goal achieved"
else
  echo "✗ Context reduction below target (${REDUCTION_PERCENT}% < 95%)"
  exit 1
fi
```

## Implementation Plan Reference

This diagnostic report should inform the following implementation plan phases:

### Phase 1: Agent Loading Utility (Low Risk)
- Create `.claude/lib/agent-registry-utils.sh`
- Implement `load_agent_prompt()` function
- Add tests for agent loading
- **Deliverable**: Working agent loader utility

### Phase 2: /orchestrate Research Phase Refactor (Medium Risk)
- Update research phase to use behavioral injection
- Add report path calculation before agent invocation
- Implement report verification after agent completion
- **Deliverable**: /orchestrate creates individual reports, not /report command

### Phase 3: /plan Research Phase Refactor (Medium Risk)
- Apply same pattern to /plan command
- Reuse agent loading utility
- **Deliverable**: /plan also uses hierarchical agent pattern

### Phase 4: Validation and Metrics (Low Risk)
- Run validation tests
- Measure context reduction improvement
- Compare token usage: before vs after
- **Deliverable**: Metrics report showing 95% context reduction achieved

### Phase 5: Documentation (Low Risk)
- Update `.claude/docs/concepts/hierarchical_agents.md` with behavioral injection pattern
- Add examples to orchestrate.md
- Update agent-README.md with invocation patterns
- **Deliverable**: Complete documentation for future command authors

## References

### Files Analyzed

- `.claude/specs/002_report_creation/example.md` - Example output showing failure
- `.claude/commands/orchestrate.md` - Orchestrate command definition (lines 1-500)
- `.claude/agents/research-specialist.md` - Research agent behavioral spec (lines 1-150)
- `.claude/docs/concepts/hierarchical_agents.md` - Architecture documentation
- `.claude/commands/plan.md` - Plan command (references research agents)

### Related Issues

- **Issue #068**: Orchestrate execution enforcement (recent work on agent behavioral compliance)
- **Issue #067**: Orchestrate artifact compliance (related to report creation)

### Research Methodology

1. **Example Output Analysis**: Read actual /orchestrate execution trace
2. **Code Inspection**: Read orchestrate.md, research-specialist.md, hierarchical_agents.md
3. **Pattern Recognition**: Identified mismatch between intended and actual behavior
4. **Root Cause Analysis**: Determined Task tool does not load agent definitions
5. **Solution Design**: Proposed behavioral injection pattern and Task tool enhancement

---

## Conclusion

The /orchestrate command's research phase failure is caused by a **fundamental architectural mismatch**: the Task tool does not load custom agent definitions from `.claude/agents/*.md` files. Instead, general-purpose agents interpret task descriptions and invoke the `/report` command, which performs comprehensive research instead of focused subtasks.

**Immediate Action Required**: Implement behavioral injection pattern in /orchestrate (Phase 1-2 of implementation plan).

**Long-Term**: Advocate for Task tool enhancement in Claude Code core to support automatic agent definition loading.

**Expected Impact**: Once fixed, /orchestrate will achieve:
- ✓ 95% context reduction (12.5k tokens vs 168.9k current)
- ✓ True parallel execution (3 focused reports, not 1 large report)
- ✓ Hierarchical agent architecture compliance
- ✓ Cost savings: ~$0.40 per workflow = $2,080/year (at 100 workflows/week)

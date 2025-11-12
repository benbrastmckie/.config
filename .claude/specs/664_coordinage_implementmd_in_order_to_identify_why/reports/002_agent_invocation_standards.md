# Agent Invocation Standards for Orchestration Commands

## Metadata
- **Date**: 2025-11-11
- **Agent**: research-specialist
- **Topic**: Standards for how orchestration commands invoke implementation agents
- **Report Type**: Standards analysis and pattern documentation

## Executive Summary

Orchestration commands like `/coordinate` MUST invoke implementation agents (implementer-coordinator) using the Task tool with behavioral injection, NOT the SlashCommand tool with /implement. This follows Standard 11 (Imperative Agent Invocation Pattern) which requires direct agent invocation with imperative instructions, behavioral file references, and no code block wrappers. The anti-pattern (invoking /implement via SlashCommand) causes 10-12.5x context bloat (5000+ lines vs 400 lines), prevents path pre-calculation, breaks metadata extraction, and disables wave-based parallel execution. The correct pattern achieves 95% context reduction, 100% file creation reliability, and 40-60% time savings through parallel execution.

## Findings

### Finding 1: Standard 11 - Imperative Agent Invocation Pattern

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 1173-1353)

**Key Requirement**: All Task invocations MUST use imperative instructions that signal immediate execution.

**Required Elements**:
1. **Imperative Instruction**: Use explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`
   - `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`
   - Example: `.claude/agents/implementer-coordinator.md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✅ CORRECT: `Task {` ... `}` (no fence)

4. **No "Example" Prefixes**: Remove documentation context
   - ❌ WRONG: "Example agent invocation:" or "The following shows..."
   - ✅ CORRECT: "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: IMPLEMENTATION_COMPLETE: ${SUMMARY}`
   - Purpose: Enables command-level verification of agent compliance

**Performance Metrics** (lines 1340-1348):
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)
- Parallel execution: Enabled for independent operations
- Bootstrap reliability: 100% (fail-fast exposes configuration errors immediately)
- File creation verification: 100% reliability (70% → 100% with MANDATORY VERIFICATION checkpoints)

### Finding 2: Behavioral Injection Pattern

**Location**: `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162)

**Definition** (lines 9-16): Behavioral Injection is a pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations. This transforms agents from autonomous executors into orchestrated workers that follow injected specifications.

**Why This Pattern Matters** (lines 18-38):

Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets this as "I should execute research directly using Read/Grep/Write tools" instead of "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations

**Problems Solved** (lines 40-45):
- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

**Core Mechanism - Role Clarification** (lines 47-62):

Every orchestrating command begins with explicit role declaration:

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
- Implement code directly (use implementer agent)
- Write documentation directly (use doc-writer agent)
```

### Finding 3: Coordinate Command Implementation Pattern

**Location**: `.claude/docs/guides/coordinate-command-guide.md` (lines 232-290)

**Architectural Note: Implementation Phase Design** (lines 232-235):

The implementation phase uses behavioral injection to invoke the implementer-coordinator agent rather than the /implement slash command. This design choice:

**1. Enables wave-based parallel execution** (lines 236-240):
- implementer-coordinator uses dependency-analyzer.sh to build execution waves
- Independent phases execute in parallel via implementation-executor subagents
- Sequential phases execute in order as dependencies complete
- Achieves significantly better performance than sequential /implement command

**2. Maintains orchestrator-executor separation** (Standard 0 Phase 0) (lines 242-246):
- Orchestrator pre-calculates all artifact paths (REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, etc.)
- Agent receives paths as injected context in Phase 0
- No self-determination of artifact locations by agent
- Ensures predictable artifact organization for verification

**3. Follows Standard 11** (Imperative Agent Invocation Pattern) (lines 248-253):
- Imperative instruction: "**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator"
- Direct reference to agent behavioral file (.claude/agents/implementer-coordinator.md)
- No code block wrappers around Task invocation
- Explicit completion signal: "Return: IMPLEMENTATION_COMPLETE: [summary]"
- Complete context injection (plan path, artifact directories, execution requirements)

**4. Prevents context bloat from nested command prompts** (lines 255-258):
- Direct agent invocation: ~400 lines context (agent behavioral file)
- Command chaining: ~5000+ lines context (full /implement command prompt - 12.5x overhead!)
- Critical for maintaining <30% context usage target throughout workflow

**5. Enables metadata extraction for 95% context reduction** (lines 260-264):
- Agent returns structured completion signal with summary
- Orchestrator verifies artifacts via file system checks
- No full implementation details in orchestrator context
- Verification checkpoint ensures 100% file creation reliability

**The implementer-coordinator agent receives** (lines 266-271):
- Pre-calculated PLAN_PATH from orchestrator
- Pre-calculated artifact directories (REPORTS_DIR, PLANS_DIR, SUMMARIES_DIR, DEBUG_DIR, OUTPUTS_DIR, CHECKPOINT_DIR)
- Topic directory path for artifact organization
- Complete behavioral guidelines from .claude/agents/implementer-coordinator.md
- Execution requirements (wave-based parallel execution, automated testing, git commits, checkpoint state management)

**Performance Benefits** (lines 283-287):
- **Context Reduction**: 95% (5000+ tokens → ~400 tokens)
- **Time Savings**: 40-60% via parallel execution for plans with independent phases
- **Reliability**: 100% file creation via mandatory verification checkpoint
- **Agent Delegation**: 100% compliance with Standard 11

### Finding 4: Correct Implementation Agent Invocation from /coordinate

**Location**: `.claude/commands/coordinate.md` (Implementation Phase)

**Actual Code Pattern** (extracted via grep):

```markdown
**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File: $PLAN_PATH (absolute path)
    - Topic Directory: $TOPIC_PATH
    - Artifact Paths:
      - Reports: $REPORTS_DIR
      - Plans: $PLANS_DIR
      - Summaries: $SUMMARIES_DIR
      - Debug: $DEBUG_DIR
      - Outputs: $OUTPUTS_DIR
      - Checkpoints: $CHECKPOINT_DIR

    **Execution Requirements**:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases
    - Checkpoint state management
  "
}
```

**Key Observations**:
1. ✅ Imperative instruction: `**EXECUTE NOW**: USE the Task tool`
2. ✅ Direct reference to behavioral file: `.claude/agents/implementer-coordinator.md`
3. ✅ No code block wrapper around Task invocation
4. ✅ Context injection: All artifact paths pre-calculated and injected
5. ✅ Execution requirements specified
6. ✅ Timeout specified for long-running implementation (600000ms = 10 minutes)

### Finding 5: Anti-Pattern - Documentation-Only YAML Blocks

**Location**: `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 324-414)

**Pattern Definition** (lines 324-329): YAML code blocks (` ```yaml`) that contain Task invocation examples prefixed with "Example" or wrapped in documentation context, causing 0% agent delegation rate.

**Detection Rule**: Search for ` ```yaml` blocks that are not preceded by imperative instructions like `**EXECUTE NOW**` or `USE the Task tool`.

**Real-World Example from /supervise before refactor** (lines 331-348):

```markdown
❌ INCORRECT - Documentation-only pattern:

The following example shows how to invoke an agent:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

This pattern never executes because it's wrapped in a code block.
```

**Consequences** (lines 349-353):
1. **0% delegation rate**: Agent prompts appear in command file but never execute
2. **Silent failure**: No error messages, command appears to work but agents never invoke
3. **Maintenance confusion**: Developers assume agents are delegating when they're not
4. **Wasted effort**: Time spent debugging why artifacts aren't created

**Correct Pattern - Imperative invocation with no code block wrapper** (lines 355-377):

```markdown
✅ CORRECT - Executable imperative pattern:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}

    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Key Differences** (lines 379-383):
1. **Imperative instruction**: `**EXECUTE NOW**: USE the Task tool...` signals immediate execution
2. **No code block wrapper**: Task invocation is not fenced with ` ``` `
3. **No "Example" prefix**: Removes documentation context that prevents execution
4. **Completion signal required**: Agent must return explicit success indicator

### Finding 6: Why No Command Chaining (SlashCommand Prohibition)

**Location**: `.claude/docs/guides/coordinate-command-guide.md` (lines 123-187)

**CRITICAL PROHIBITION** (lines 124): This command MUST NEVER invoke other commands via the SlashCommand tool.

**Wrong Pattern - Command Chaining** (lines 126-132):

```
❌ INCORRECT - Do NOT do this:
```
SlashCommand with command: "/plan create auth feature"
```
```

**Problems with command chaining** (lines 134-138):
1. **Context Bloat**: Entire /plan command prompt injected into your context (~2000 lines)
2. **Broken Behavioral Injection**: /plan's behavior not customizable via prompt
3. **Lost Control**: Cannot inject specific instructions or constraints
4. **No Metadata**: Get full output, not structured data for aggregation

**Correct Pattern - Direct Agent Invocation** (lines 140-159):

```
✅ CORRECT - Do this instead:
```
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
```

**Benefits of direct agent invocation** (lines 161-165):
1. **Lean Context**: Only agent behavioral guidelines loaded (~200 lines)
2. **Behavioral Control**: Can inject custom instructions, constraints, templates
3. **Structured Output**: Agent returns metadata (path, status) not full summaries
4. **Verification Points**: Can verify file creation before continuing

**Side-by-Side Comparison** (lines 167-176):

| Aspect | Command Chaining (❌) | Direct Agent Invocation (✅) |
|--------|---------------------|------------------------------|
| Context Usage | ~2000 lines (full command) | ~200 lines (agent guidelines) |
| Behavioral Control | Fixed (command prompt) | Flexible (custom instructions) |
| Output Format | Full text summaries | Structured metadata |
| Verification | None (black box) | Explicit checkpoints |
| Path Control | Agent calculates | Orchestrator pre-calculates |
| Role Separation | Blurred (orchestrator executes) | Clear (orchestrator delegates) |

**For Implementation Phase**: The context overhead comparison is even more dramatic:
- Command chaining: ~5000+ lines (full /implement command)
- Direct agent invocation: ~400 lines (implementer-coordinator.md)
- **Overhead difference**: 12.5x for implementation vs 10x for planning

### Finding 7: Agent Files Available

**Location**: `.claude/agents/` directory

**Available Implementation Agents**:
1. `implementer-coordinator.md` (15,953 bytes) - Primary orchestration agent for wave-based implementation
2. `implementation-executor.md` (18,414 bytes) - Executes individual phases within waves
3. `implementation-researcher.md` (9,942 bytes) - Pre-implementation codebase analysis
4. `implementation-sub-supervisor.md` (17,536 bytes) - Hierarchical supervision for complex implementations

**Primary Agent**: `implementer-coordinator.md`
- **Purpose**: Orchestrates wave-based parallel implementation
- **Capabilities**: Dependency analysis, wave calculation, parallel execution coordination
- **Delegates to**: implementation-executor.md (one per phase within wave)
- **Returns**: Structured completion signal with summary

## Recommendations

### Recommendation 1: Use Task Tool with Behavioral Injection for Implementation

**DO**: Invoke implementer-coordinator agent directly via Task tool
- Reference behavioral file: `.claude/agents/implementer-coordinator.md`
- Inject pre-calculated paths: PLAN_PATH, TOPIC_PATH, artifact directories
- Use imperative instruction: `**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator`
- Specify completion signal: `Return: IMPLEMENTATION_COMPLETE: [summary]`

**DO NOT**: Invoke /implement command via SlashCommand tool
- Causes 12.5x context overhead (5000+ lines vs 400 lines)
- Prevents path pre-calculation (orchestrator loses control)
- Disables wave-based parallel execution
- Breaks metadata extraction (95% context reduction lost)

**Rationale**: Standard 11 mandates imperative agent invocation. Behavioral injection enables hierarchical coordination, context optimization, and parallel execution. Command chaining violates architectural separation and causes context bloat.

### Recommendation 2: Pre-Calculate All Artifact Paths in Phase 0

**Pattern**: Phase 0 optimization calculates all paths before any agent invocations

```bash
# Calculate artifact paths for implementer-coordinator agent
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"

# Export for cross-bash-block availability
export REPORTS_DIR PLANS_DIR SUMMARIES_DIR DEBUG_DIR OUTPUTS_DIR CHECKPOINT_DIR

# Save to workflow state for persistence
append_workflow_state "REPORTS_DIR" "$REPORTS_DIR"
append_workflow_state "PLANS_DIR" "$PLANS_DIR"
# ... etc
```

**Benefits**:
- Orchestrator maintains control over artifact organization
- Agent receives paths as injected context (no self-determination)
- Enables verification checkpoints (check expected paths)
- Supports checkpoint recovery (paths persisted to state)

**Rationale**: Standard 0 Phase 0 requires orchestrator-executor separation. Path pre-calculation ensures predictable artifact locations for verification.

### Recommendation 3: Follow Imperative Invocation Pattern Exactly

**Required Elements Checklist**:
- [ ] Imperative instruction: `**EXECUTE NOW**: USE the Task tool...`
- [ ] Behavioral file reference: `Read and follow ALL behavioral guidelines from: .claude/agents/implementer-coordinator.md`
- [ ] No code block wrapper: Task invocation not fenced with ` ``` `
- [ ] No "Example" prefix: Remove documentation context
- [ ] Context injection: All artifact paths provided
- [ ] Execution requirements: Specify wave-based execution, testing, commits, checkpoints
- [ ] Completion signal: `Return: IMPLEMENTATION_COMPLETE: [summary]`
- [ ] Timeout: Specify appropriate timeout (600000ms for implementation)

**Anti-Patterns to Avoid**:
- ❌ Documentation-only YAML blocks (code fence wrapper)
- ❌ Command chaining via SlashCommand
- ❌ Missing imperative instruction
- ❌ Template variables without substitution
- ❌ Generic descriptions without context injection

**Rationale**: Standard 11 enforcement pattern ensures 100% agent delegation rate. Missing any required element causes silent failure or incorrect execution.

### Recommendation 4: Verify Agent File Creation with Mandatory Checkpoints

**Pattern**: After agent invocation, verify expected artifacts created

```bash
# MANDATORY VERIFICATION
if [ ! -f "$EXPECTED_SUMMARY_PATH" ]; then
  echo "❌ ERROR: implementer-coordinator failed to create summary"
  echo "   Expected: $EXPECTED_SUMMARY_PATH"
  echo "   Found: File does not exist"

  echo ""
  echo "DIAGNOSTIC INFORMATION:"
  echo "  - Verify agent behavioral file exists: .claude/agents/implementer-coordinator.md"
  echo "  - Check agent output for error messages"
  echo "  - Verify artifact directories exist and are writable"

  exit 1
fi

echo "✓ Verified: Implementation summary created at $EXPECTED_SUMMARY_PATH"
```

**Benefits**:
- 100% file creation reliability (vs 60-80% without verification)
- Fail-fast on agent errors (immediate diagnostic information)
- Clear troubleshooting guidance (no silent failures)

**Rationale**: Standard 0 mandates verification checkpoints for file creation operations. Fail-fast philosophy requires explicit error detection.

### Recommendation 5: Leverage Wave-Based Parallel Execution Benefits

**Context**: implementer-coordinator agent provides wave-based parallel execution
- 40-60% time savings for plans with independent phases
- Automatic dependency analysis via dependency-analyzer.sh
- Parallel execution of independent phases within waves
- Sequential wave progression respects dependencies

**Implementation**:
1. Ensure plan has phase dependencies specified: `dependencies: [N, M]`
2. Inject execution requirement: "Wave-based parallel execution for independent phases"
3. Let implementer-coordinator handle wave calculation and execution
4. Monitor via checkpoint state (wave number, completed phases)

**Benefits vs Sequential /implement**:
- Time savings: 40-60% for typical plans
- Scalability: Handles large plans (10+ phases) efficiently
- Reliability: Checkpoint state enables resume on failure

**Rationale**: Behavioral injection enables specialized agent capabilities unavailable in command-to-command invocation. Wave-based execution is a key differentiator.

## References

### Documentation Files Analyzed

1. `.claude/docs/reference/command_architecture_standards.md`
   - Lines 1173-1353: Standard 11 (Imperative Agent Invocation Pattern)
   - Lines 1340-1348: Performance metrics for Standard 11 compliance

2. `.claude/docs/concepts/patterns/behavioral-injection.md`
   - Lines 1-1162: Complete behavioral injection pattern documentation
   - Lines 18-45: Why behavioral injection matters, problems solved
   - Lines 47-174: Core implementation mechanism with examples
   - Lines 324-414: Anti-pattern documentation (documentation-only YAML blocks)

3. `.claude/docs/guides/coordinate-command-guide.md`
   - Lines 84-227: Architecture and orchestrator role definition
   - Lines 123-187: Why no command chaining (SlashCommand prohibition)
   - Lines 232-290: Implementation phase design with behavioral injection

4. `.claude/commands/coordinate.md`
   - Implementation Phase: Correct implementation agent invocation pattern
   - Context injection: Pre-calculated artifact paths

### Agent Files Referenced

1. `.claude/agents/implementer-coordinator.md` (15,953 bytes)
   - Primary orchestration agent for wave-based implementation
   - Handles dependency analysis, wave calculation, parallel execution

2. `.claude/agents/implementation-executor.md` (18,414 bytes)
   - Executes individual phases within waves
   - Delegated to by implementer-coordinator

3. `.claude/agents/implementation-researcher.md` (9,942 bytes)
   - Pre-implementation codebase analysis
   - Used for complex phases requiring exploration

4. `.claude/agents/implementation-sub-supervisor.md` (17,536 bytes)
   - Hierarchical supervision for complex implementations
   - Manages multiple implementation-executor agents

### Standards Cross-References

- **Standard 0**: Execution Enforcement (verification checkpoints, fallback mechanisms)
- **Standard 11**: Imperative Agent Invocation Pattern (required for all orchestration commands)
- **Standard 12**: Structural vs Behavioral Content Separation (template vs behavioral distinction)
- **Standard 14**: Executable/Documentation File Separation (command vs guide files)

### Related Patterns

- **Behavioral Injection Pattern**: Context injection via file references instead of tool invocations
- **Checkpoint Recovery Pattern**: State preservation for resumable workflows
- **Parallel Execution Pattern**: Wave-based implementation for 40-60% time savings
- **Metadata Extraction Pattern**: 95% context reduction through structured data passing
- **Verification and Fallback Pattern**: 100% file creation reliability via mandatory checkpoints

## Implementation Guidance

### Step-by-Step Guide for /coordinate Implementation Phase

**Step 1: Pre-Calculate Paths in Phase 0**
```bash
REPORTS_DIR="${TOPIC_PATH}/reports"
PLANS_DIR="${TOPIC_PATH}/plans"
SUMMARIES_DIR="${TOPIC_PATH}/summaries"
DEBUG_DIR="${TOPIC_PATH}/debug"
OUTPUTS_DIR="${TOPIC_PATH}/outputs"
CHECKPOINT_DIR="${HOME}/.claude/data/checkpoints"

export REPORTS_DIR PLANS_DIR SUMMARIES_DIR DEBUG_DIR OUTPUTS_DIR CHECKPOINT_DIR
append_workflow_state "REPORTS_DIR" "$REPORTS_DIR"
# ... save all paths to state
```

**Step 2: Invoke implementer-coordinator with Behavioral Injection**
```markdown
**EXECUTE NOW**: USE the Task tool to invoke implementer-coordinator:

Task {
  subagent_type: "general-purpose"
  description: "Execute implementation with wave-based parallel execution"
  timeout: 600000
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/implementer-coordinator.md

    **Workflow-Specific Context**:
    - Plan File: $PLAN_PATH (absolute path)
    - Topic Directory: $TOPIC_PATH
    - Artifact Paths:
      - Reports: $REPORTS_DIR
      - Plans: $PLANS_DIR
      - Summaries: $SUMMARIES_DIR
      - Debug: $DEBUG_DIR
      - Outputs: $OUTPUTS_DIR
      - Checkpoints: $CHECKPOINT_DIR

    **Execution Requirements**:
    - Wave-based parallel execution for independent phases
    - Automated testing after each wave
    - Git commits for completed phases
    - Checkpoint state management

    Return: IMPLEMENTATION_COMPLETE: [summary]
  "
}
```

**Step 3: Verify Implementation Summary Created**
```bash
EXPECTED_SUMMARY_PATH="${SUMMARIES_DIR}/001_implementation_summary.md"

if [ ! -f "$EXPECTED_SUMMARY_PATH" ]; then
  echo "❌ ERROR: implementer-coordinator failed to create summary"
  echo "   Expected: $EXPECTED_SUMMARY_PATH"
  exit 1
fi

echo "✓ Implementation complete, summary verified"
```

**Step 4: Extract Metadata (Optional)**
```bash
# Extract metadata for context optimization
SUMMARY_TITLE=$(grep "^# " "$EXPECTED_SUMMARY_PATH" | head -1 | sed 's/^# //')
SUMMARY_STATUS=$(grep "Status:" "$EXPECTED_SUMMARY_PATH" | head -1)

# Prune full summary content if not needed for subsequent phases
# (Context optimization via metadata extraction pattern)
```

### Common Mistakes to Avoid

**Mistake 1**: Using SlashCommand to invoke /implement
```markdown
❌ WRONG:
SlashCommand with command: "/implement $PLAN_PATH"
```
**Impact**: 12.5x context overhead, no parallel execution, path control lost

**Mistake 2**: Wrapping Task invocation in code fence
```markdown
❌ WRONG:
```yaml
Task {
  prompt: "Read .claude/agents/implementer-coordinator.md..."
}
```
```
**Impact**: 0% delegation rate, agent never executes

**Mistake 3**: Missing imperative instruction
```markdown
❌ WRONG:
The implementation phase invokes the implementer-coordinator agent:

Task {
  prompt: "..."
}
```
**Impact**: Treated as documentation, not executed

**Mistake 4**: Not pre-calculating paths
```markdown
❌ WRONG:
Task {
  prompt: "
    Implement the plan at $PLAN_PATH
    Create summary in appropriate directory
  "
}
```
**Impact**: Agent self-determines paths, verification impossible

**Mistake 5**: No completion signal
```markdown
❌ WRONG:
Task {
  prompt: "
    Read .claude/agents/implementer-coordinator.md
    Execute implementation
  "
}
```
**Impact**: No structured output for verification, metadata extraction impossible

# Research Report: Command Authoring Standards and Task Invocation Requirements

**Date**: 2025-12-10
**Topic**: Command Authoring Standards and Task Invocation Patterns
**Status**: IN PROGRESS

## Research Objective

Research command authoring standards to understand:
1. Task Tool Invocation Pattern requirements
2. Why `Task {}` pseudo-syntax in code blocks fails
3. Correct Task invocation patterns
4. How agent files differ from command files in tool invocation

## Research Status

- [x] Read command-authoring.md
- [x] Analyze Task Tool Invocation Patterns section
- [x] Document correct invocation requirements
- [x] Identify agent vs command differences
- [x] Provide recommendations

## Findings

### 1. Why `Task {}` Pseudo-Syntax Fails

From `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (lines 99-118):

**Problems with Pseudo-Syntax**:
1. Pseudo-syntax is NOT recognized by Claude Code
2. No execution directive tells the LLM to use the Task tool
3. Variables inside will NOT be interpolated
4. Code block wrapper makes it documentation, not executable

**Example of Failing Pattern**:
```markdown
Task {
  subagent_type: "research-specialist"
  description: "Research topic"
  prompt: "..."
}
```

This pattern has NO imperative directive and is interpreted as documentation/example code.

### 2. Correct Task Invocation Pattern Requirements

From command-authoring.md (lines 119-149):

**Required Elements**:
1. **NO code block wrapper** - Remove ` ```yaml ` fences
2. **Imperative instruction** - "**EXECUTE NOW**: USE the Task tool..."
3. **Inline prompt** - Variables interpolated directly
4. **Completion signal** - Agent must return explicit signal (e.g., `REPORT_CREATED:`)

**Correct Pattern**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${FEATURE_DESCRIPTION} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${FEATURE_DESCRIPTION}
    - Output Directory: ${RESEARCH_DIR}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

### 3. Agent Behavioral File Task Patterns (Lines 295-343)

**CRITICAL REQUIREMENTS for Agent Files**:

When agent behavioral files (e.g., research-coordinator.md) contain Task invocations that the agent should execute:

1. **No code block wrappers**: Task invocations must NOT be wrapped in ``` fences
2. **Imperative directives**: Each Task invocation requires "**EXECUTE NOW**: USE the Task tool..." prefix
3. **Concrete values**: Use actual topic strings and paths, not bash variable placeholders like `${TOPICS[0]}`
4. **Checkpoint verification**: Add explicit "Did you just USE the Task tool?" checkpoints after invocations

**Example from research-coordinator.md STEP 3**:
```markdown
**CHECKPOINT AFTER TOPIC 0**: Did you just USE the Task tool for topic at index 0?

**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic at index 0.

Task {
  subagent_type: "general-purpose"
  description: "Research topic at index 0 with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    (use CLAUDE_PROJECT_DIR)/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=(use REPORT_PATHS[0] - exact absolute path from array)

    **Research Topic**: (use TOPICS[0] - exact topic string from array)

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: (REPORT_PATHS[0])
  "
}
```

### 4. Anti-Patterns (DO NOT USE)

From command-authoring.md (lines 330-343):

**Anti-Patterns Identified**:
- Wrapping Task invocations in code blocks: ` ```Task { }``` `
- Using bash variable syntax: `${TOPICS[0]}` (looks like documentation)
- Separate logging code blocks: ` ```bash echo "..."``` ` before Task invocation
- Pseudo-code notation without imperative directive

**Why This Matters**:
- Agents interpret code-fenced Task blocks as documentation examples
- Bash variable syntax suggests shell interpolation, not actual execution
- Missing imperative directives = agent skips invocation = empty output directories
- Result: Coordinator completes with 0 Task invocations, workflow fails

### 5. Prohibited Patterns (Lines 2088-2237)

**Prohibited Pattern 1: Naked Task Block**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```
Problem: No imperative directive. Claude treats as documentation.

**Prohibited Pattern 2: Instructional Text Without Task Invocation**
```markdown
## Phase 3: Agent Delegation

Use the Task tool to invoke the research-specialist agent with the calculated paths.
The agent will create the report at ${REPORT_PATH}.
```
Problem: Describes what SHOULD happen but doesn't invoke the Task tool.

**Prohibited Pattern 3: Incomplete EXECUTE NOW Directive**
```markdown
**EXECUTE NOW**: Invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```
Problem: Missing "USE the Task tool" phrase.

**Prohibited Pattern 4: Conditional Prefix Without EXECUTE Keyword**
```markdown
**If CONDITION**: USE the Task tool to invoke agent.

Task {
  subagent_type: "general-purpose"
  description: "Process data"
  prompt: "..."
}
```
Problem: Conditional prefix reads as documentation, not imperative execution.

**Key Principle**: The word "EXECUTE" MUST appear in the directive to signal mandatory action vs. descriptive documentation.

### 6. Agent Files vs Command Files

**Key Difference Identified**:

**Command Files**:
- Use bash variable interpolation: `${VAR}` is valid in prompts
- Variables are interpolated by shell BEFORE Claude sees them
- Example: `${CLAUDE_PROJECT_DIR}` → `/home/user/.config`

**Agent Behavioral Files**:
- Cannot use bash variable syntax (no shell interpolation)
- Must use parenthetical instructions: `(use TOPICS[0])`
- Claude reads instructions and accesses variables directly from context
- Example: `(use REPORT_PATHS[0] - exact absolute path from array)`

**Why**: Agent files are NOT executed by bash. They're read by Claude, which then follows instructions to access variables from its current execution context.

### 7. Validation

From command-authoring.md (lines 2223-2237):

All command files are validated by automated linter:

```bash
# Run Task invocation pattern linter
bash .claude/scripts/lint-task-invocation-pattern.sh <command-file>

# Linter detects:
# - ERROR: Task { without EXECUTE NOW directive
# - ERROR: Instructional text without actual Task invocation
# - ERROR: Incomplete EXECUTE NOW directive (missing 'Task tool')
```

## Recommendations

### For Fixing research-coordinator.md Violations

1. **Remove Bash Heredoc Wrapper**:
   - Current: Task invocations wrapped in `cat <<'EOF' ... EOF` output
   - Required: Direct Task invocations with imperative directives
   - Reason: Heredoc converts Task invocations to text/documentation

2. **Add Imperative Directives**:
   - Before EACH Task invocation: "**EXECUTE NOW**: USE the Task tool..."
   - Include checkpoint questions: "**CHECKPOINT**: Did you just USE the Task tool?"
   - Reason: Without directives, Claude interprets as examples, not executable

3. **Replace Bash Variable Syntax**:
   - Current: `${TOPICS[0]}`, `${REPORT_PATHS[0]}`
   - Required: `(use TOPICS[0])`, `(use REPORT_PATHS[0])`
   - Reason: Agent files don't have shell interpolation; Claude accesses variables directly

4. **Remove Code Block Wrappers**:
   - Current: Task invocations inside ``` fences
   - Required: Bare Task blocks with imperative directives
   - Reason: Code fences signal documentation, not execution

5. **Add Explicit Checkpoints**:
   - After each Task invocation: "Did you just USE the Task tool for topic at index N?"
   - Reason: Helps Claude verify execution vs. documentation reading

### Pattern Template for Agent Files

```markdown
**CHECKPOINT AFTER TOPIC N**: Did you just USE the Task tool for topic at index N?

**EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic at index N.

Task {
  subagent_type: "general-purpose"
  description: "Research topic at index N with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    (use CLAUDE_PROJECT_DIR)/.claude/agents/research-specialist.md

    **CRITICAL - Hard Barrier Pattern**:
    REPORT_PATH=(use REPORT_PATHS[N] - exact absolute path from array)

    **Research Topic**: (use TOPICS[N] - exact topic string from array)

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: (use REPORT_PATHS[N])
  "
}
```

### Cross-References

- **Source Document**: `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md`
- **Relevant Sections**:
  - Lines 99-118: Why Task {} pseudo-syntax fails
  - Lines 119-149: Correct Task invocation pattern
  - Lines 295-343: Agent behavioral file Task patterns
  - Lines 2088-2237: Prohibited patterns and validation
- **Related Documentation**:
  - [Hard Barrier Subagent Delegation Pattern](../../concepts/patterns/hard-barrier-subagent-delegation.md)
  - [Hierarchical Agents Examples](../../concepts/hierarchical-agents-examples.md#example-7-research-coordinator)

---
*Report created following research-specialist protocol*

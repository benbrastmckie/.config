# STEP Pattern Classification Flowchart

**Path**: docs → reference → decision-trees → step-pattern-classification-flowchart.md

[Used by: /implement, /plan, /coordinate, all command and agent development]

Fast decision tree for determining whether STEP sequences should be inline (command files) or referenced (agent files).

## Purpose

Resolves the STEP pattern classification contradiction between Standard 0 (Execution Enforcement) and Standard 12 (Behavioral Content Separation) by providing clear ownership-based decision criteria.

## Quick Decision Flowchart

```
┌─────────────────────────────────────────┐
│ Found STEP sequence in command or plan │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│ QUESTION: Who executes this STEP sequence?      │
└──────────────┬───────────────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
      ▼                 ▼
┌──────────────┐   ┌─────────────────┐
│ Command      │   │ Agent           │
│ Orchestrator │   │ Subagent        │
└──────┬───────┘   └────────┬────────┘
       │                    │
       ▼                    ▼
┌──────────────────┐   ┌──────────────────────┐
│ ✓ INLINE         │   │ ✓ REFERENCE          │
│ (Standard 0)     │   │ (Standard 12)        │
└──────┬───────────┘   └────────┬─────────────┘
       │                        │
       ▼                        ▼
┌──────────────────────────┐   ┌─────────────────────────┐
│ Keep in command file     │   │ Move to agent file      │
│ Execution enforcement    │   │ Behavioral separation   │
└──────────────────────────┘   └─────────────────────────┘
```

## Detailed Decision Process

### Step 1: Identify STEP Sequence

**What to look for**:
- Lines starting with `STEP 1:`, `STEP 2:`, etc.
- Numbered execution procedures
- Sequential workflow descriptions

**Example**:
```markdown
STEP 1: Calculate artifact paths
STEP 2: Invoke research agents
STEP 3: Verify file creation
```

### Step 2: Ask "Who Executes This?"

**Command/Orchestrator Indicators** (→ INLINE):
- Cross-agent coordination ("Invoke agents in parallel")
- Path pre-calculation ("Calculate BEFORE agent invocation")
- Phase transitions ("After Phase 1 completes, start Phase 2")
- Agent preparation ("Create topic directory structure")
- Verification checkpoints ("MANDATORY VERIFICATION of agent outputs")

**Agent/Subagent Indicators** (→ REFERENCE):
- File creation workflows ("Create file with Write tool")
- Research procedures ("Analyze codebase patterns")
- Quality checks ("Verify output sections present")
- Agent-specific output formatting ("Return results in JSON")
- Internal verification ("Agent MUST verify before returning")

### Step 3: Apply Standard

**If Command Executes** → **INLINE** (Standard 0: Execution Enforcement)
- Rationale: Command must see execution steps immediately
- Location: Keep in command file (`.claude/commands/*.md`)
- Why: Claude needs visibility for orchestration logic

**If Agent Executes** → **REFERENCE** (Standard 12: Behavioral Content Separation)
- Rationale: Agent behavior belongs in agent file
- Location: Move to agent file (`.claude/agents/*.md`)
- Why: Single source of truth, eliminates duplication

### Step 4: Handle Ambiguous Cases

**When Unsure**: Default to **REFERENCE**

**Rationale**:
- Safer for context management (<30% usage target)
- Eliminates duplication risk
- Enables single source of truth
- Can always inline later if needed

**Test**: "If I change this STEP, where do I update it?"
- "Only this command" → Likely INLINE
- "Multiple commands" → Definitely REFERENCE
- "Agent file" → Definitely REFERENCE

## Examples with Classification

### Example 1: Multi-Phase Orchestration

```markdown
STEP 1: Calculate all artifact paths BEFORE invoking agents
STEP 2: Invoke research agents in parallel (Phase 1)
STEP 3: MANDATORY VERIFICATION of all report files
STEP 4: Invoke implementation agents sequentially (Phase 2)
```

**Decision**: ✓ INLINE (Command executes)
**Rationale**: Command coordinates phases, prepares context, verifies agent outputs
**Standard**: Standard 0 (Execution Enforcement)

### Example 2: File Creation Workflow

```markdown
STEP 1: Create report file with Write tool at pre-calculated path
STEP 2: Verify file exists with Read tool
STEP 3: Return file path in completion signal
```

**Decision**: ✓ REFERENCE (Agent executes)
**Rationale**: Agent internal workflow for file creation
**Standard**: Standard 12 (Behavioral Content Separation)
**Location**: `.claude/agents/researcher.md`

### Example 3: Agent Preparation

```markdown
STEP 1: Create topic directory structure
STEP 2: Pre-calculate all file paths for agent injection
STEP 3: Inject paths into agent prompts via Task tool
```

**Decision**: ✓ INLINE (Command executes)
**Rationale**: Command prepares context before agent invocation
**Standard**: Standard 0 (Execution Enforcement)

### Example 4: Research Procedure

```markdown
STEP 1: Analyze codebase for existing patterns (Grep/Read)
STEP 2: Document findings in structured format
STEP 3: Generate recommendations based on analysis
```

**Decision**: ✓ REFERENCE (Agent executes)
**Rationale**: Agent execution procedure for research
**Standard**: Standard 12 (Behavioral Content Separation)
**Location**: `.claude/agents/researcher.md`

### Example 5: Cross-Agent Synthesis

```markdown
STEP 1: Collect outputs from all research agents
STEP 2: Synthesize findings into unified summary
STEP 3: Pass summary to implementation agents
```

**Decision**: ✓ INLINE (Command executes)
**Rationale**: Command synthesizes cross-agent results
**Standard**: Standard 0 (Execution Enforcement)

### Example 6: Quality Check Sequence

```markdown
STEP 1: Verify all required sections present in output
STEP 2: Check cross-references are valid
STEP 3: Validate markdown format compliance
```

**Decision**: ✓ REFERENCE (Agent executes)
**Rationale**: Agent self-verification before returning results
**Standard**: Standard 12 (Behavioral Content Separation)
**Location**: `.claude/agents/researcher.md`

## Common Pitfalls

### Pitfall 1: Assuming All STEP = Inline

**Misconception**: "STEP sequences are execution steps, so they must be inline per Standard 0"

**Reality**: Only command-owned STEP sequences are inline. Agent-owned STEP sequences belong in agent files.

**Fix**: Apply ownership test: "Who executes this STEP?"

### Pitfall 2: Assuming All STEP = Reference

**Misconception**: "STEP sequences are behavioral procedures, so they must be referenced per Standard 12"

**Reality**: Command orchestration STEP sequences must be inline for execution enforcement.

**Fix**: Distinguish orchestration (command) from execution (agent).

### Pitfall 3: Duplicating Agent Workflows

**Misconception**: "I need this agent workflow visible in the command file"

**Reality**: Behavioral injection pattern injects context, not workflows. Agent reads workflow from agent file.

**Fix**: Inject paths/constraints into agent prompt, reference agent file for workflows.

## Validation

**Command File Check** (`.claude/commands/*.md`):
```bash
# Verify command-owned STEPs only
# Look for orchestration keywords
grep -n "STEP" command.md | grep -E "invoke|verify|calculate|prepare|coordinate"

# Flag agent-owned STEPs
grep -n "STEP" command.md | grep -E "create file|research|analyze|document"
# These should be in agent files, not command files
```

**Agent File Check** (`.claude/agents/*.md`):
```bash
# Verify agent-owned STEPs present
grep -n "STEP" agent.md | grep -E "create file|research|analyze|verify output"

# Flag command-owned STEPs
grep -n "STEP" agent.md | grep -E "invoke|coordinate|prepare context"
# These should be in command files, not agent files
```

## Related Documentation

**Standards**:
- [Command Architecture Standards](../reference/architecture/overview.md) → Standard 0 (Execution Enforcement), Standard 12 (Behavioral Content Separation)
- [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md) → Orchestration Sequences category

**Patterns**:
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) → Context injection without workflow duplication
- [Robustness Framework](../concepts/robustness-framework.md) → Pattern 2 (Agent Behavioral Injection)

**Guides**:
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) → Command orchestration patterns
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) → Agent behavioral guidelines

## Summary

**Decision Rule**: Apply ownership test.

**Command Executes** (orchestration, preparation, verification):
- ✓ INLINE in command file
- Standard 0: Execution Enforcement
- Example: "STEP 1: Invoke agents in parallel"

**Agent Executes** (file creation, research, quality checks):
- ✓ REFERENCE in agent file
- Standard 12: Behavioral Content Separation
- Example: "STEP 1: Create report with Write tool"

**Ambiguous** (unclear ownership):
- ✓ Default to REFERENCE
- Safer for context management
- Can inline later if needed

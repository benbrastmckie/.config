# Behavioral Injection Pattern

**Path**: docs → concepts → patterns → behavioral-injection.md

[Used by: /orchestrate, /implement, /plan, /report, /debug, all coordinating commands]

Commands inject context into agents via file reads instead of SlashCommand tool invocations, enabling hierarchical multi-agent patterns and preventing direct execution.

## Definition

Behavioral Injection is a pattern where orchestrating commands inject execution context, artifact paths, and role clarifications into agent prompts through file content rather than tool invocations. This transforms agents from autonomous executors into orchestrated workers that follow injected specifications.

The pattern separates:
- **Command role**: Orchestrator that calculates paths, manages state, delegates work
- **Agent role**: Executor that receives context via file reads and produces artifacts

## Rationale

### Why This Pattern Matters

Commands that invoke other commands using the SlashCommand tool create two critical problems:

1. **Role Ambiguity**: When a command says "I'll research the topic", Claude interprets this as "I should execute research directly using Read/Grep/Write tools" instead of "I should orchestrate agents to research". This prevents hierarchical multi-agent patterns.

2. **Context Bloat**: Command-to-command invocations nest full command prompts within parent prompts, causing exponential context growth and breaking metadata-based context reduction.

Behavioral Injection solves both problems by:
- Making the orchestrator role explicit: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Injecting all necessary context into agent files: paths, constraints, specifications
- Enabling agents to read context and self-configure without tool invocations

### Problems Solved

- 100% file creation rate through explicit path injection
- <30% context usage by avoiding nested command prompts
- Hierarchical multi-agent coordination through clear role separation
- Parallel execution through independent context injection per agent

## Implementation

### Core Mechanism

**Phase 0: Role Clarification**

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

**Path Pre-Calculation**

Before invoking any agent, calculate and validate all paths:

```bash
# Example from /orchestrate Phase 0
EXECUTE NOW - Calculate Paths:

1. Determine project root: /home/benjamin/.config
2. Find deepest directory encompassing workflow scope
3. Calculate next topic number: specs/NNN_topic/
4. Create topic directory structure:
   mkdir -p specs/027_authentication/{reports,plans,summaries,debug}
5. Assign artifact paths:
   REPORTS_DIR="specs/027_authentication/reports/"
   PLANS_DIR="specs/027_authentication/plans/"
   SUMMARIES_DIR="specs/027_authentication/summaries/"
```

**Context Injection via File Content**

Inject context into agent prompts through structured data:

```yaml
# Injected into research-specialist agent prompt
research_context:
  topic: "OAuth 2.0 authentication patterns"
  scope: "Focus on implementation patterns for Node.js APIs"
  constraints:
    - "Must support refresh tokens"
    - "Must integrate with existing session management"
  output_path: "specs/027_authentication/reports/001_oauth_patterns.md"
  output_format:
    sections:
      - "OAuth 2.0 Flow Overview"
      - "Implementation Patterns"
      - "Security Considerations"
      - "Integration Strategy"
```

### Code Example

Real implementation from Plan 080 - /orchestrate Phase 0:

```markdown
## Phase 0: Project Location Determination

EXECUTE NOW:

1. YOUR ROLE: You are the ORCHESTRATOR, not the executor
2. DO NOT use Read/Grep/Write to explore codebase yourself
3. ONLY use Task tool to invoke location-specialist agent

INVOKE AGENT - location-specialist:

Task tool invocation:
{
  "agent": "location-specialist",
  "task": "Analyze workflow '<user_request>' and determine project location",
  "context": {
    "workflow_request": "<full user request here>",
    "current_directory": "/home/benjamin/.config",
    "requirements": [
      "Find deepest directory encompassing affected components",
      "Calculate next topic number for specs/ directory",
      "Create topic directory structure: NNN_topic/{reports,plans,summaries,debug}",
      "Return topic_path and artifact_paths for injection into subsequent agents"
    ]
  }
}

EXPECTED RETURN (metadata only):
{
  "topic_path": "/path/to/project/specs/027_authentication/",
  "topic_number": "027",
  "artifact_paths": {
    "reports": "{topic_path}/reports/",
    "plans": "{topic_path}/plans/",
    "summaries": "{topic_path}/summaries/",
    "debug": "{topic_path}/debug/"
  },
  "summary": "50-word summary of location analysis and directory structure created"
}
```

After receiving location context, inject into all subsequent agents:

```markdown
## Phase 1: Research

FOR EACH research topic, invoke research-specialist with injected context:

CONTEXT INJECTION (prepend to agent prompt):
---
ARTIFACT LOCATION (REQUIRED):
- Save all reports to: specs/027_authentication/reports/
- Use topic number prefix: 027
- Follow naming: {topic_number}_{topic_name}.md

PROJECT CONTEXT:
- Topic path: specs/027_authentication/
- Related components: [list from location-specialist]
---

Task tool invocation:
{
  "agent": "research-specialist",
  "task": "Research OAuth 2.0 authentication patterns for Node.js",
  "context": "<injected context above + research requirements>"
}
```

### Usage Context

**When to Apply:**
- All commands that coordinate multiple agents (orchestrators)
- Commands that manage workflows with file creation
- Any command scoring <90 on audit-execution-enforcement.sh

**When Not to Apply:**
- Simple utility commands that don't invoke agents
- Agents themselves (they receive injected context, don't inject it)
- Commands that only read and analyze (no file creation)

### Structural Templates vs Behavioral Content

**IMPORTANT CLARIFICATION**: The behavioral injection pattern applies to agent behavioral guidelines, NOT to structural templates.

**Structural Templates (MUST remain inline)**:
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
- Critical warnings: `**CRITICAL**: error conditions`

These are command execution structures, NOT agent behavioral content. They must remain inline for immediate execution and parsing.

**Behavioral Content (MUST be referenced, not duplicated)**:
- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

### Valid Inline Templates

Anti-Pattern Violation 0 is about behavioral duplication, NOT structural templates. The following inline templates are correct and required:

```markdown
✓ CORRECT - Task invocation structure (structural template):

Task {
  subagent_type: "research-specialist"
  description: "Research authentication patterns"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    CONTEXT (inject parameters, not procedures):
    - Topic: OAuth 2.0 authentication
    - Report path: specs/027_auth/reports/001_oauth_patterns.md

    (No STEP sequences here - those are in research-specialist.md)
  "
}
```

```markdown
✓ CORRECT - Bash execution blocks (structural template):

**EXECUTE NOW**: Run the following commands to prepare environment:

bash
mkdir -p specs/027_auth/{reports,plans,summaries}
export REPORT_PATH="specs/027_auth/reports/001_oauth_patterns.md"
```

```markdown
✓ CORRECT - Verification checkpoints (structural template):

**MANDATORY VERIFICATION**: After agent completes, verify:
- Report file exists at $REPORT_PATH
- Report contains all required sections
- File is properly formatted markdown

If verification fails, retry agent invocation with corrected path.
```

### Benefits with Structural Templates Clarified

When properly distinguishing structural templates from behavioral content:
- **90% reduction applies to behavioral content**, not structural templates
- **Structural templates remain inline** for immediate command execution
- **Behavioral content referenced once** from agent files
- **Single source of truth** for agent guidelines (no duplication)

For detailed guidance on what qualifies as structural vs behavioral, see [Template vs Behavioral Distinction](../../reference/architecture/template-vs-behavioral.md).

## Anti-Patterns

### Example Violation 0: Inline Template Duplication

```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool to create file at ${REPORT_PATH}
    [... 30 lines of detailed instructions ...]

    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
    [... 40 lines of detailed instructions ...]

    **STEP 3 (REQUIRED BEFORE STEP 4)**: Populate Report File
    [... 30 lines of detailed instructions ...]

    **STEP 4 (MANDATORY VERIFICATION)**: Verify and Return
    [... 20 lines of verification instructions ...]
  "
}
```

**Why This Fails:**
1. Duplicates 646 lines of research-specialist.md behavioral guidelines (~150 lines per invocation)
2. Creates maintenance burden: must manually sync template with behavioral file
3. Violates "single source of truth" principle: two locations for agent guidelines
4. Adds unnecessary bloat: 800+ lines across command file

**Correct Pattern** - Reference Behavioral File, Inject Context Only:
```markdown
✅ GOOD - Reference behavioral file with context injection:

Task {
  subagent_type: "general-purpose"
  description: "Research topic with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH} (absolute path, pre-calculated)
    - Project Standards: ${STANDARDS_FILE}

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**Benefits:**
- 90% reduction: 150 lines → 15 lines per invocation
- Single source of truth: behavioral file is authoritative
- No synchronization needed: updates to behavioral file automatically apply
- Cleaner commands: focus on orchestration, not behavioral details

### Anti-Pattern: Documentation-Only YAML Blocks

**Pattern Definition**: YAML code blocks (` ```yaml`) that contain Task invocation examples prefixed with "Example" or wrapped in documentation context, causing 0% agent delegation rate.

**Detection Rule**: Search for ` ```yaml` blocks that are not preceded by imperative instructions like `**EXECUTE NOW**` or `USE the Task tool`.

**Real-World Example** (from /supervise before refactor):

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

**Consequences:**
1. **0% delegation rate**: Agent prompts appear in command file but never execute
2. **Silent failure**: No error messages, command appears to work but agents never invoke
3. **Maintenance confusion**: Developers assume agents are delegating when they're not
4. **Wasted effort**: Time spent debugging why artifacts aren't created

**Correct Pattern** - Imperative invocation with no code block wrapper:

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

**Key Differences:**
1. **Imperative instruction**: `**EXECUTE NOW**: USE the Task tool...` signals immediate execution
2. **No code block wrapper**: Task invocation is not fenced with ` ``` `
3. **No "Example" prefix**: Removes documentation context that prevents execution
4. **Completion signal required**: Agent must return explicit success indicator

**How to Detect This Anti-Pattern:**

```bash
# Search for documentation-only YAML blocks in commands
grep -n '```yaml' .claude/commands/*.md

# For each match, check if it's preceded by imperative instruction:
# - If yes: Executable pattern ✓
# - If no: Documentation-only anti-pattern ❌

# Automated detection:
for file in .claude/commands/*.md; do
  # Find YAML blocks not preceded by "EXECUTE NOW" within 5 lines
  awk '/```yaml/{
    found=0
    for(i=NR-5; i<NR; i++) {
      if(lines[i] ~ /EXECUTE NOW|USE the Task tool/) found=1
    }
    if(!found) print FILENAME":"NR": Documentation-only YAML block"
  } {lines[NR]=$0}' "$file"
done
```

**Migration Guide:**

If you find documentation-only YAML blocks:

1. **Retain for documentation**: If the block shows anti-pattern examples or syntax reference, keep it but clearly mark it as non-executable
2. **Convert to executable**: If the block should invoke agents, remove code block wrapper and add imperative instruction
3. **Add tests**: Create regression tests to validate agent delegation rate

For detailed conversion steps, see [Command Development Guide](../../guides/development/command-development/command-development-fundamentals.md#avoiding-documentation-only-patterns).

### Anti-Pattern: Code-Fenced Task Examples Create Priming Effect

**Pattern Definition**: Code-fenced Task invocation examples (` ```yaml ... ``` `) that establish a "documentation interpretation" pattern, causing Claude to treat subsequent unwrapped Task blocks as non-executable examples rather than commands. This results in 0% agent delegation rate even when Task invocations are structurally correct.

**Root Cause**: When Claude encounters code-fenced Task examples early in a command file, it establishes a mental model that "Task blocks are documentation examples, not executable commands". This interpretation carries forward to actual Task invocations later in the file, preventing execution even when they lack code fences.

**Detection Rule**: Search for ` ```yaml` wrappers around Task invocation examples. Even a single code-fenced example can establish the priming effect.

**Real-World Example** (from /supervise before fix, spec 469):

```markdown
❌ INCORRECT - Code-fenced example establishes priming effect:

**Lines 62-79 (Task invocation example)**:
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md
    [...]
  "
}
```

**Lines 350-400 (Actual Task invocations, no code fences)**:
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "..."
}

**Result**: 0% delegation rate. The actual Task invocation at line 350 is interpreted as a documentation example due to the priming effect from lines 62-79.
```

**Consequences:**
1. **0% delegation rate**: All Task invocations fail silently despite correct structure
2. **Streaming fallback masking**: Error recovery mechanism hides the failure
3. **Parallel execution disabled**: Agents never initialize, preventing concurrent work
4. **Context protection disabled**: Metadata extraction never occurs (95% reduction blocked)
5. **Diagnostic difficulty**: Static analysis shows correct syntax, runtime shows 0% execution

**Correct Pattern** - No code fences around Task invocations:

```markdown
✅ CORRECT - Task invocation without code fence wrapper:

**Correct Pattern - Direct Agent Invocation** (lean context, behavioral control):

<!-- This Task invocation is executable -->
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)
    - Research Reports: [list of paths]

    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Key Fixes:**
1. **Remove code fences**: No ` ```yaml ... ``` ` wrapper around Task invocations
2. **Add HTML comment**: `<!-- This Task invocation is executable -->` clarifies intent without creating priming effect (HTML comments are invisible to Claude)
3. **Keep anti-pattern examples fenced**: Examples marked with ❌ should remain code-fenced to prevent accidental execution
4. **Verify tool access**: Ensure agents have Bash in allowed-tools for proper initialization

**How to Detect This Anti-Pattern:**

```bash
# Check for code-fenced Task examples that could cause priming effect
grep -n '```yaml' .claude/commands/*.md | while read match; do
  file=$(echo "$match" | cut -d: -f1)
  line=$(echo "$match" | cut -d: -f2)

  # Check context around match
  sed -n "$((line-2)),$((line+15))p" "$file" | grep -q "Task {" && \
    echo "Potential priming effect in $file at line $line"
done
```

**Verification After Fix:**

```bash
# Run test suite to verify delegation rate
bash .claude/tests/test_supervise_agent_delegation.sh

# Expected metrics after fix:
# - Delegation rate: 0% → 100%
# - Context usage: >80% → <30%
# - Streaming fallback errors: Eliminated
# - Parallel agents: 2-4 executing simultaneously
```

**Related Issues:**
- Spec 438: Similar issue with documentation-only YAML blocks (different root cause)
- Spec 444: Tool access mismatches (missing Bash) compound the problem
- Research report: `.claude/specs/469_supervise_command_agent_delegation_failure_root_ca/reports/001_supervise_command_execution_pattern_analysis.md`

**Prevention Guidelines:**
- Never wrap executable Task invocations in code fences
- Use HTML comments for clarifications (invisible to Claude)
- Move complex examples to external reference files
- Test delegation rate after adding any Task examples
- Follow [Command Development Guide](../../guides/development/command-development/command-development-fundamentals.md) patterns

### Anti-Pattern: Undermined Imperative Pattern

**Pattern Definition**: Following imperative directives (e.g., `**EXECUTE NOW**`) with disclaimers that suggest template or future generation, creating confusion about whether to execute immediately. This causes the AI to treat the directive as documentation rather than an instruction.

**Root Cause**: Disclaimers like "**Note**: The actual implementation will generate N calls" contradict the imperative directive, making the AI interpret the Task block as a template example rather than executable code. This creates template assumption that results in 0% agent delegation rates.

**Detection Rule**: Search for "**Note**:" or similar disclaimers within 25 lines after "**EXECUTE NOW**" directives that reference "generate", "template", or "example only".

**Real-World Example** (from /supervise before fix, spec 502):

```markdown
❌ INCORRECT - Undermining disclaimer:

**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "..."
}

**Note**: The actual implementation will generate N Task calls based on RESEARCH_COMPLEXITY.
```

**Why This Fails:**
1. **Imperative contradicted**: "**EXECUTE NOW**" says act immediately, but "**Note**" says it's a template
2. **Template assumption**: The disclaimer signals that Task block is documentation, not executable
3. **Zero delegation**: AI skips invocation entirely, treating it as reference material
4. **Confusing phrasing**: "actual implementation will generate" implies current context is not the actual implementation

**Correct Pattern** - Clean imperative without disclaimers:

```markdown
✅ GOOD - No undermining disclaimers:

**EXECUTE NOW**: USE the Task tool for each research topic (1 to $RESEARCH_COMPLEXITY) with these parameters:

- subagent_type: "general-purpose"
- description: "Research [insert topic name] with mandatory artifact creation"
- prompt: |
    Read and follow ALL behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: [insert display-friendly topic name]
    - Report Path: [insert absolute path from REPORT_PATHS array]

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

**Key Fixes:**
1. **Remove disclaimers**: No "**Note**:" or similar after imperative directives
2. **Use "for each [item]"**: Indicates loop expectation without disclaimers
3. **Use `[insert value]` placeholders**: Signals substitution clearly
4. **Bullet-point format**: Looks like instructions, not code templates

**How to Detect This Anti-Pattern:**

```bash
# Find undermining disclaimers after EXECUTE NOW directives
grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/*.md | \
  grep -B 5 -i "note.*generate\|template\|example only\|actual implementation"
```

**Verification After Fix:**

```bash
# Verify no undermining disclaimers remain
grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/supervise.md | \
  grep -i "note.*generate" || echo "✓ No undermining disclaimers found"

# Verify bullet-point pattern used
grep -c "^- subagent_type" .claude/commands/supervise.md
# Should match number of agent invocations
```

**Related Issues:**
- Spec 438: YAML blocks wrapped in markdown code fences (different anti-pattern)
- Spec 495: /coordinate and /research delegation failures (multiple anti-patterns)
- Spec 502: Undermined imperative pattern discovery and fix
- Root cause analysis: `.claude/specs/502_supervise_research_delegation_failure/reports/001_root_cause_analysis.md`

**Prevention Guidelines:**
- Never add disclaimers after imperative directives
- Use "for each [item]" phrasing to indicate loops
- Use `[insert value]` placeholder syntax for substitution
- Keep imperatives clean and unambiguous
- Test delegation rate after any changes to agent invocations

### Example Violation 1: Command-to-Command Invocation

```markdown
❌ BAD - /orchestrate calling /plan command:

## Phase 2: Planning

I'll create an implementation plan for the researched topics.

SlashCommand tool invocation:
{
  "command": "/plan Implement OAuth 2.0 authentication"
}
```

**Why This Fails:**
1. Nests full /plan command prompt inside /orchestrate prompt (context bloat)
2. /plan command executes directly instead of delegating to planner-specialist
3. Breaks metadata-based context reduction (full plan content returned, not summary)
4. Prevents hierarchical patterns (flat command chaining)

### Example Violation 2: Direct Execution

```markdown
❌ BAD - Command executing work directly:

## Phase 1: Research

I'll research OAuth 2.0 patterns using Read and Grep tools.

Read tool: /path/to/existing/auth/code.js
Grep tool: pattern="OAuth" path="src/"
```

**Why This Fails:**
1. Command acts as executor instead of orchestrator
2. No agent delegation means no metadata extraction
3. Cannot parallelize research (single command context)
4. Misses behavioral injection of paths and constraints

### Example Violation 3: Ambiguous Role

```markdown
❌ BAD - No role clarification:

## /plan Command

I'll analyze the requirements and create an implementation plan.

First, let me explore the codebase...
```

**Why This Fails:**
1. "I'll create" is ambiguous - direct execution or agent delegation?
2. No explicit "DO NOT execute yourself" instruction
3. Claude defaults to direct execution using Read/Grep/Write
4. Prevents hierarchical multi-agent patterns

## Case Studies

### Spec 495: /coordinate and /research Agent Delegation Failures

**Date**: 2025-10-27
**Commands Affected**: `/coordinate`, `/research`
**Problem**: 0% agent delegation rate despite correct Task tool syntax
**Root Cause**: Documentation-only YAML blocks wrapped in markdown code fences

#### Problem Details

**File**: `.claude/commands/coordinate.md`
**Affected Lines**: 9 agent invocations across all phases (research, planning, implementation, testing, debugging, documentation)

**Broken Pattern Example** (lines 800-850 - Research Phase):
```markdown
The research phase invokes research-specialist agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: ${TOPIC_NAME}
    Output to: ${REPORT_PATH}
}
```

This pattern appeared correct but agents never executed.
```

**Why It Failed:**
1. **Code fence wrapper**: ` ```yaml ... ``` ` marks block as documentation, not execution
2. **Template variables**: `${TOPIC_NAME}` never substituted with actual values
3. **No imperative instruction**: Missing "EXECUTE NOW" directive
4. **No path pre-calculation**: Report paths never calculated before invocation

**Evidence of Failure:**
- Zero reports created in `.claude/specs/NNN_topic/reports/`
- TODO1.md files contained agent output (wrong location)
- No PROGRESS: markers visible during command execution
- Delegation rate analysis: 0% (0 of 9 invocations succeeded)

#### Solution Applied

**Transformation Pattern** (Research Phase fix):

**Before** (Documentation-only YAML):
```yaml
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC_NAME}"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```
```

**After** (Imperative bullet-point):
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate paths:

bash
topic_dir=$(create_topic_structure "authentication_patterns")
report_path="$topic_dir/reports/001_oauth_patterns.md"
echo "REPORT_PATH: $report_path"
```

**EXECUTE NOW**: USE the Task tool NOW with these parameters:

- subagent_type: "general-purpose"
- description: "Research authentication patterns for REST APIs"
- prompt: |
    Read and follow behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    Research topic: Authentication patterns for REST APIs

    Output file: [insert $report_path from above]

    Create comprehensive report covering OAuth 2.0, JWT, session-based authentication.

**WAIT FOR**: Agent to return REPORT_CREATED: $report_path
```

**Key Changes:**
1. **Removed code fence**: Task invocation no longer wrapped in ` ```yaml `
2. **Added imperative directive**: `**EXECUTE NOW**: USE the Task tool NOW`
3. **Pre-calculated paths**: Explicit Bash tool invocation before agent call
4. **Replaced template variables**: Concrete example provided with instructions to insert actual values
5. **Added completion signal**: `REPORT_CREATED:` verification

#### Results

**Delegation Rate Improvement:**
- Before: 0% (0 of 9 invocations)
- After: >90% (9 of 9 invocations)
- Measurement: `.claude/tests/test_orchestration_commands.sh` delegation rate test

**File Creation Reliability:**
- Before: 0 files in correct locations (all output to TODO1.md)
- After: 100% files in `.claude/specs/NNN_topic/` directories
- Evidence: No TODO*.md files created after fix, all artifacts in topic directories

**Performance Impact:**
- Bootstrap time: Unchanged (<1 second)
- Agent invocation time: Unchanged (proper delegation has no overhead)
- Parallel execution: Now possible (was impossible before)

#### /research Command Specifics

**File**: `.claude/commands/research.md`
**Affected Lines**: 3 agent invocations + ~10 bash code blocks

**Additional Problem**: Bash code blocks appearing as documentation:

**Before** (Documentation-style):
```bash
# Calculate topic directory
topic_dir=$(create_topic_structure "$topic")
echo "TOPIC_DIR: $topic_dir"
```

**After** (Explicit tool invocation):
```markdown
**EXECUTE NOW**: USE the Bash tool to calculate topic directory:

bash
topic_dir=$(create_topic_structure "$topic")
echo "TOPIC_DIR: $topic_dir"
```

Verify: $topic_dir should contain absolute path to .claude/specs/NNN_topic/
```

**Key Difference**: `**EXECUTE NOW**: USE the Bash tool` directive signals immediate execution, not documentation.

#### Lessons Learned

1. **Code fences prevent execution**: Any ` ```yaml ` or ` ```bash ` wrapper marks content as documentation
2. **Imperative directives required**: `EXECUTE NOW` signals immediate tool invocation
3. **Template variables must be eliminated**: Provide concrete examples with instructions to substitute actual values
4. **Path pre-calculation essential**: Bash tool must calculate paths before passing to agents
5. **Completion signals enable verification**: `REPORT_CREATED:` confirms successful file creation

#### Prevention Measures

**Validation Script**: `.claude/lib/util/validate-agent-invocation-pattern.sh`
- Detects YAML-style Task blocks in command files
- Detects markdown code fences around invocations
- Detects template variables in prompts (`${VAR}`)
- Exit code 1 on violations, 0 on pass

**Test Suite**: `.claude/tests/test_orchestration_commands.sh`
- Delegation rate tests for all orchestration commands
- File creation location verification
- Regression tests to prevent reintroduction

**Documentation Updates**:
- Updated [Command Architecture Standards](../../reference/architecture/overview.md) - Standard 11
- Created [Orchestration Troubleshooting Guide](../../guides/orchestration/orchestration-troubleshooting.md)
- This behavioral injection documentation updated with case study

### Spec 057: /supervise Command Robustness Improvements

**Date**: 2025-10-27
**Commands Affected**: `/supervise`, `/coordinate`
**Problem**: Bootstrap failures and inconsistent error handling
**Root Cause**: Fallback mechanisms hiding configuration errors

#### Problem Details

**File**: `.claude/commands/supervise.md`
**Affected Areas**: Library sourcing, function verification, directory creation

**Problem 1: Function Name Mismatch** (RESOLVED in Phase 0):
```bash
# Command called:
save_phase_checkpoint "$phase_number" "$data"
load_phase_checkpoint "$phase_number"

# Library provided:
save_checkpoint "$checkpoint_name" "$data"
restore_checkpoint "$checkpoint_name"
```

**Impact**: 12 checkpoint calls failed silently (6 in /supervise, 6 in /coordinate)

**Problem 2: Fallback Mechanisms Hiding Errors**:

```bash
# Example fallback (lines 242-274):
if ! source .claude/lib/workflow/workflow-detection.sh; then
  # Define fallback function inline
  detect_workflow_scope() {
    echo "research-only"  # Default assumption
  }
fi
```

**Why This Failed:**
1. **Silent configuration errors**: Library missing → fallback used → no indication of problem
2. **Inconsistent behavior**: Some environments work (library present), others use fallback (different results)
3. **Debugging difficulty**: No clear error message showing which library failed
4. **False success**: Commands appeared to work but used degraded functionality

#### Solution Applied

**Fail-Fast Error Handling**:

**Before** (Silent fallback):
```bash
if ! source .claude/lib/workflow/workflow-detection.sh; then
  # Fallback function
  detect_workflow_scope() { echo "research-only"; }
fi
```

**After** (Explicit error):
```bash
if ! source .claude/lib/workflow/workflow-detection.sh; then
  echo "ERROR: Failed to source workflow-detection.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/workflow/workflow-detection.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/workflow/workflow-detection.sh"
  echo ""
  echo "CONTEXT: Library required for workflow scope detection"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

**Key Changes:**
1. **Removed fallback function**: Force explicit error instead of degraded functionality
2. **Enhanced error message**: Shows what failed, why, and how to diagnose
3. **Diagnostic commands**: Includes exact commands to investigate problem
4. **Exit immediately**: Prevents command from continuing with broken state

**Enhanced Function Verification**:

**Before** (Generic error):
```bash
if ! declare -F detect_workflow_scope >/dev/null; then
  echo "ERROR: Missing function detect_workflow_scope"
  exit 1
fi
```

**After** (Detailed diagnostics):
```bash
if ! declare -F detect_workflow_scope >/dev/null; then
  echo "ERROR: Missing required function: detect_workflow_scope"
  echo "EXPECTED PROVIDER: .claude/lib/workflow/workflow-detection.sh"
  echo "DIAGNOSTIC: declare -F | grep detect_workflow_scope"
  echo "DIAGNOSTIC: Check if workflow-detection.sh was sourced successfully"
  exit 1
fi
```

**Removed Directory Creation Fallbacks**:

**Before** (Manual fallback):
```markdown
If agent fails to create directory:

bash
mkdir -p "$topic_dir/reports"
mkdir -p "$topic_dir/plans"
```

**After** (Fail-fast):
```markdown
After agent execution, verify directory creation:

bash
if [ ! -d "$topic_dir/reports" ]; then
  echo "ERROR: Agent failed to create reports directory"
  echo "EXPECTED: $topic_dir/reports"
  echo "DIAGNOSTIC: ls -la $topic_dir"
  exit 1
fi
```

**Key Principle**: Agents are responsible for directory creation. If they fail, we must diagnose why, not mask the failure with manual creation.

#### Results

**Error Message Clarity:**
- Before: Generic "sourcing failed" messages
- After: 7 library sourcing checks enhanced with diagnostic commands
- Improvement: Clear actionable errors showing which library failed and how to fix

**Fallback Removal:**
- Before: 32 lines of fallback functions (workflow-detection.sh)
- After: 0 fallback functions, explicit errors instead
- Improvement: Consistent behavior across all environments

**File Size Reduction:**
- Before: 2,323 lines
- After: 2,291 lines
- Change: -32 lines (-1.4%)

#### Fallback Philosophy

**CRITICAL DISTINCTION**: Not all fallbacks are bad. This spec removed bootstrap fallbacks but preserved file creation verification fallbacks.

**Bootstrap Fallbacks** (REMOVED - Hide Configuration Errors):
- Silent function definitions when libraries missing
- Automatic directory creation masking agent delegation failures
- Fallback workflow detection when required libraries unavailable
- Default value substitution for missing required variables

**Rationale**: Configuration errors indicate broken setup that MUST be fixed before workflow execution.

**File Creation Verification Fallbacks** (PRESERVED - Detect Tool Failures):
- MANDATORY VERIFICATION after each agent file creation operation
- File existence checks (ls -la, [ -f "$PATH" ])
- File size validation (minimum 500 bytes)
- Fallback file creation when agent succeeded but Write tool failed
- Re-verification after fallback creation

**Rationale**: File creation verification does NOT hide configuration errors. It detects transient Write tool failures where agent succeeded but file missing.

**Performance Impact**:
- Without verification: 70% file creation reliability
- With verification: 100% file creation reliability
- Improvement: +43% reliability

#### Lessons Learned

1. **Fail-fast enables debugging**: Explicit errors easier to diagnose than silent fallbacks
2. **Fallback type matters**: Bootstrap fallbacks hide errors; verification fallbacks detect errors
3. **Diagnostic commands essential**: Error messages must include exact commands to investigate
4. **Context in errors**: Show what failed, why, expected state, actual state
5. **Exit immediately**: Don't continue execution with broken state

#### Prevention Measures

**Error Message Standards**:
1. What failed (specific operation)
2. Why it failed (exact error message/condition)
3. Context (paths, variables, environment state)
4. Diagnostic commands (exact commands to investigate)
5. Exit code (non-zero to signal failure)

**Test Suite**: `.claude/tests/test_orchestration_commands.sh`
- Bootstrap sequence tests (library sourcing, function verification)
- Error message validation (ensures diagnostics present)
- Regression tests for fallback removal

**Documentation Updates**:
- Created [Orchestration Troubleshooting Guide](../../guides/orchestration/orchestration-troubleshooting.md)
- Updated fail-fast philosophy documentation
- Updated error handling best practices

### Cross-Spec Insights

**Common Root Cause**: Both specs 495 and 057 identified pattern violations that prevented effective operation

- **Spec 495**: Documentation-style patterns prevented agent delegation (0% execution)
- **Spec 057**: Fallback mechanisms prevented effective debugging (silent failures)

**Shared Solution**: Explicit, imperative instructions with fail-fast error handling

- **Spec 495**: Removed code fences, added `EXECUTE NOW` directives
- **Spec 057**: Removed fallbacks, added diagnostic error messages

**Unified Validation**: Both specs contributed to shared testing infrastructure

- **Validation Script**: `.claude/lib/util/validate-agent-invocation-pattern.sh` (from spec 495)
- **Test Suite**: `.claude/tests/test_orchestration_commands.sh` (unified from both specs)
- **Error Standards**: Diagnostic message format (from spec 057)

**Impact on Orchestration Commands**:
- `/coordinate`: Fixed agent delegation (spec 495) + checkpoint API (spec 057)
- `/research`: Fixed agent delegation (spec 495)
- `/supervise`: Improved error handling (spec 057)
- All commands now use consistent patterns and validation

## Testing Validation

### Validation Script

```bash
#!/bin/bash
# .claude/tests/validate_behavioral_injection.sh

COMMAND_FILE="$1"

echo "Validating behavioral injection pattern in $COMMAND_FILE..."

# Check 1: Role clarification present
if ! grep -q "YOU ARE THE ORCHESTRATOR" "$COMMAND_FILE" && \
   ! grep -q "YOUR ROLE:" "$COMMAND_FILE"; then
  echo "❌ MISSING: Role clarification (Phase 0)"
  exit 1
fi

# Check 2: Anti-execution instructions present
if ! grep -q "DO NOT execute.*yourself" "$COMMAND_FILE"; then
  echo "❌ MISSING: Anti-execution instructions"
  exit 1
fi

# Check 3: No SlashCommand invocations to other commands
if grep -q "SlashCommand.*/(plan|implement|debug|report|document)" "$COMMAND_FILE"; then
  echo "❌ VIOLATION: Command-to-command invocation detected"
  exit 1
fi

# Check 4: Path pre-calculation present
if ! grep -q "EXECUTE NOW.*Calculate Paths" "$COMMAND_FILE"; then
  echo "❌ MISSING: Path pre-calculation"
  exit 1
fi

# Check 5: Context injection structure present
if ! grep -q "CONTEXT INJECTION" "$COMMAND_FILE" && \
   ! grep -q "context:" "$COMMAND_FILE"; then
  echo "⚠️  WARNING: No explicit context injection found"
fi

echo "✓ Behavioral injection pattern validated"
```

### Expected Results

**Compliant Command:**
- Audit score ≥90/100 on audit-execution-enforcement.sh
- Role clarification in Phase 0
- All agent invocations use Task tool (not SlashCommand)
- Path pre-calculation before file operations
- Context injection structure for agents

**Non-Compliant Command:**
- Audit score <90/100
- Missing role clarification
- SlashCommand invocations to /plan, /implement, /debug
- Direct execution using Read/Grep/Write instead of agents

## Performance Impact

### Measurable Improvements

**File Creation Rate:**
- Before: 60-80% (commands creating files in wrong locations)
- After: 100% (explicit path injection ensures correct locations)

**Context Reduction:**
- Before: 80-100% context usage (nested command prompts)
- After: <30% context usage (metadata-only passing between agents)

**Parallelization:**
- Before: Impossible (sequential command chaining)
- After: 40-60% time savings (independent agents run in parallel)

**Hierarchical Coordination:**
- Before: Flat command chaining (max 4 agents)
- After: Recursive supervision (10+ agents across 3 levels)

### Real-World Metrics (Plan 080)

**Before behavioral injection:**
- /orchestrate invoked /plan command → /plan invoked planner-specialist
- Context usage: 85% (full /plan prompt nested in /orchestrate)
- File creation: 7/10 plans in correct location (70%)

**After behavioral injection:**
- /orchestrate invoked planner-specialist directly with injected paths
- Context usage: 25% (metadata-only return from planner)
- File creation: 10/10 plans in correct location (100%)

## Related Patterns

- [Metadata Extraction](./metadata-extraction.md) - Complements behavioral injection by reducing context after agent execution
- [Hierarchical Supervision](./hierarchical-supervision.md) - Enabled by behavioral injection's clear role separation
- [Verification and Fallback](./verification-fallback.md) - Uses injected paths for verification checkpoints
- [Parallel Execution](./parallel-execution.md) - Requires independent context injection per agent

## See Also

- [Command Architecture Standards](../../reference/architecture/overview.md) - Phase 0 requirements
- [Creating Commands Guide](../../guides/development/command-development/command-development-fundamentals.md) - Orchestrator patterns
- [Hierarchical Agents Guide](../hierarchical-agents.md) - Agent coordination architecture
- [Orchestration Guide](../../workflows/orchestration-guide.md) - Full workflow patterns

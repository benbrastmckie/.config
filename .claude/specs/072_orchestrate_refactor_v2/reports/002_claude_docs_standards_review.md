# .claude/docs/ Standards Review for Orchestrate Simplification

## Executive Summary

This report comprehensively reviews .claude/docs/ standards to identify the single working workflow pattern that /orchestrate should implement. The core finding: **distilling a single working workflow** means implementing three mandatory patterns (Standard 0, Behavioral Injection, Verification-Fallback) without fallback alternatives. The canonical workflow is a 7-phase orchestration with Phase 0 path pre-calculation and enforcement-driven execution.

## Standard 0: Execution Enforcement

**Location**: `command_architecture_standards.md#standard-0-execution-enforcement-new`

**Core Requirement**: Distinguish between descriptive documentation and mandatory execution directives using imperative language and verification checkpoints.

### Key Components

1. **Imperative vs Descriptive Language**
   - **Prohibited**: "should", "may", "can", "consider", "try to"
   - **Required**: "MUST", "WILL", "SHALL", "EXECUTE NOW", "MANDATORY"
   - **Strength Hierarchy**: MUST/SHALL > WILL > MAY (optional) > should/can (prohibited)

2. **Enforcement Patterns**
   - **Pattern 1**: Direct Execution Blocks with "EXECUTE NOW" markers
   - **Pattern 2**: Mandatory Verification Checkpoints after all file operations
   - **Pattern 3**: Non-Negotiable Agent Prompts using "THIS EXACT TEMPLATE"
   - **Pattern 4**: Checkpoint Reporting with completion confirmation

3. **Fallback Mechanism Requirements**
   - Required for: agent file creation, structured output parsing, artifact organization
   - Structure: Primary Path (agent follows instructions) + Fallback Path (command creates output from agent response)
   - Guarantee: Output exists regardless of agent behavior

4. **Phase 0: Orchestrator vs Executor Role Clarification**
   - **Orchestrator Role**: Pre-calculates artifact paths, invokes subagents via Task tool, injects complete context, verifies artifacts, extracts metadata only
   - **Executor Role**: Receives pre-calculated paths, executes with Read/Write/Edit/Bash tools, creates artifacts at exact paths, returns metadata only
   - **Anti-Pattern**: Orchestrator invokes other command via SlashCommand (loses artifact path control, context bloat, recursion risk)

### What Standard 0 Means for /orchestrate

1. All critical steps must use "YOU MUST", "EXECUTE NOW", "MANDATORY" language
2. Phase 0 MUST pre-calculate all artifact paths before any agent invocations
3. Agent invocations MUST use Task tool (NOT SlashCommand)
4. All file operations MUST have MANDATORY VERIFICATION checkpoints
5. Fallback mechanisms MUST guarantee file creation even if agents fail

## Behavioral Injection Pattern

**Location**: `patterns/behavioral-injection.md`

**Core Requirement**: Commands inject context into agents via Task tool with complete specifications, enabling hierarchical multi-agent patterns and preventing direct execution.

### Key Components

1. **Role Separation**
   - **Command role**: Orchestrator that calculates paths, manages state, delegates work
   - **Agent role**: Executor that receives context via file reads and produces artifacts
   - **Anti-Pattern**: Commands invoking other commands via SlashCommand (causes role ambiguity and context bloat)

2. **Phase 0: Role Clarification**
   ```markdown
   ## YOUR ROLE
   You are the ORCHESTRATOR for this workflow.
   - YOU WILL delegate tasks to subagents using Task tool
   - YOU MUST NOT execute tasks directly using Read/Grep/Write/Edit tools
   - YOU SHALL pre-calculate artifact paths before invoking agents
   ```

3. **Path Pre-Calculation** (BEFORE any agent invocations)
   ```bash
   EXECUTE NOW - Calculate Paths:
   1. Determine project root
   2. Find deepest directory encompassing workflow scope
   3. Calculate next topic number: specs/NNN_topic/
   4. Create topic directory structure: reports/, plans/, summaries/, debug/
   5. Assign artifact paths for all agents
   ```

4. **Context Injection via Task Tool**
   - Agent behavioral prompt reference: "Read: .claude/agents/agent-name.md"
   - Complete task specification with all requirements
   - Pre-calculated artifact paths injected
   - Success criteria and output format specified

### What Behavioral Injection Means for /orchestrate

1. Phase 0 MUST calculate all paths BEFORE research phase
2. Agent invocations MUST use Task tool with injected context
3. Agent prompts MUST include: behavioral file reference + task requirements + pre-calculated paths + success criteria
4. NO command-to-command invocations (no `/plan`, `/implement`, `/debug` via SlashCommand)
5. All agents receive complete context (no partial specifications)

## Verification and Fallback Pattern

**Location**: `patterns/verification-fallback.md`

**Core Requirement**: MANDATORY VERIFICATION checkpoints with fallback file creation mechanisms achieve 100% file creation rates.

### Key Components

1. **Three-Step Structure**
   - **Step 1**: Path Pre-Calculation (all file paths calculated before execution)
   - **Step 2**: MANDATORY VERIFICATION Checkpoints (after each file creation)
   - **Step 3**: Fallback File Creation (if verification fails)

2. **Mandatory Verification Format**
   ```markdown
   ## MANDATORY VERIFICATION - Report Creation
   EXECUTE NOW (REQUIRED BEFORE NEXT STEP):
   1. Verify file exists: ls -la {path}
   2. Verify file size > 0: [ -s {path} ]
   3. If verification fails, proceed to FALLBACK MECHANISM
   4. If verification succeeds, proceed to next agent invocation
   ```

3. **Fallback Mechanism Format**
   ```markdown
   ## FALLBACK MECHANISM - Manual File Creation
   TRIGGER: File verification failed
   EXECUTE IMMEDIATELY:
   1. Create file directly using Write tool
   2. MANDATORY VERIFICATION (repeat)
   3. If still fails, escalate to user
   4. If succeeds, log fallback usage and continue
   ```

4. **Performance Impact**
   - File creation rate: 70% (before) → 100% (after)
   - Downstream failures: 30% (before) → 0% (after)
   - Diagnostic time: 10-20 minutes (before) → immediate (after)

### What Verification-Fallback Means for /orchestrate

1. Phase 0 MUST calculate ALL artifact paths before any file operations
2. After EACH agent completes, MANDATORY VERIFICATION checkpoint MUST execute
3. Verification MUST check: file exists, file size > 0, path matches expected
4. If verification fails, fallback mechanism MUST create file directly
5. Re-verification MUST confirm fallback success before proceeding

## Canonical Development Workflow

**Location**: `development-workflow.md`

**Standard Workflow Pattern**: 5-phase workflow with topic-based organization

### Workflow Phases

1. **Research Phase**: Create research reports in `specs/{NNN_topic}/reports/`
2. **Planning Phase**: Generate implementation plans in `specs/{NNN_topic}/plans/`
3. **Implementation Phase**: Execute plans phase-by-phase with testing and commits
4. **Documentation Phase**: Update relevant documentation based on changes
5. **Summary Phase**: Generate summaries in `specs/{NNN_topic}/summaries/` linking plans to code

### Artifact Lifecycle

**Topic-Based Structure**: `specs/{NNN_topic}/`
- `reports/` - Research reports (gitignored)
- `plans/` - Implementation plans (gitignored)
- `summaries/` - Implementation summaries (gitignored)
- `debug/` - Debug reports (COMMITTED for issue tracking)
- `scripts/` - Investigation scripts (gitignored, temporary)
- `outputs/` - Test outputs (gitignored, cleaned after workflow)

### Adaptive Planning Integration

- Automatic plan revision when complexity >8 or >10 tasks
- Maximum 2 replans per phase prevents infinite loops
- Checkpoint system tracks replan counters

## Imperative Language Requirements

**Location**: `imperative-language-guide.md`

**Core Principle**: Required actions use MUST/WILL/SHALL. Optional actions use MAY. Descriptive text is prohibited in execution instructions.

### Transformation Rules

| Weak Language | Imperative Replacement | When to Use |
|---------------|------------------------|-------------|
| should | **MUST** | Absolute requirements |
| may | **WILL** or **SHALL** | Conditional requirements |
| can | **MUST** or **SHALL** | Capability requirements |
| consider | **MUST** or **SHALL** | Required evaluation |
| try to | **WILL** | Required attempt |

### Language Strength Hierarchy

1. **Critical**: "CRITICAL:", "ABSOLUTE REQUIREMENT" (safety, data integrity)
2. **Mandatory**: "YOU MUST", "REQUIRED", "EXECUTE NOW" (essential steps)
3. **Strong**: "Always", "Never", "Ensure" (best practices)
4. **Standard**: "Should", "Recommended" (preferences) - PROHIBITED in execution
5. **Optional**: "May", "Can", "Consider" (alternatives) - PROHIBITED in required actions

### Validation Metric

- **Target**: Imperative ratio ≥90% (MUST/WILL/SHALL count / total directive count)
- **Excellent**: ≥90% imperative language
- **Needs Improvement**: 70-89% imperative language
- **Requires Migration**: <70% imperative language

## Key Standards for Distillation

### What "Distill a Single Working Workflow" Means

Based on the standards, "distilling a single working workflow" means:

1. **No Fallbacks or Alternatives**
   - Remove "if this doesn't work, try that" branches
   - Implement ONE path: the verified, working pattern
   - No conditional approaches based on complexity/feature type

2. **Mandatory Pattern Implementation**
   - Standard 0 (Execution Enforcement): ALL execution steps use imperative language
   - Behavioral Injection: Phase 0 path pre-calculation + Task tool invocations only
   - Verification-Fallback: MANDATORY VERIFICATION + fallback for every file operation

3. **Canonical Workflow Structure**
   - Phase 0: Project location determination + path pre-calculation
   - Phase 1: Research (parallel agents with metadata-only returns)
   - Phase 2: Planning (single agent with research context)
   - Phase 3: Complexity evaluation (conditional expansion)
   - Phase 4: Implementation (wave-based parallel execution)
   - Phase 5: Testing (conditional debugging loop)
   - Phase 6: Documentation (update all relevant docs)
   - Phase 7: Summary (workflow summary with artifact references)

4. **No Command Chaining**
   - Zero SlashCommand invocations to /plan, /implement, /debug, /document
   - ALL work delegated to specialized agents via Task tool
   - Orchestrator role: calculate paths, invoke agents, aggregate metadata

5. **100% File Creation Guarantee**
   - Path pre-calculation before execution
   - MANDATORY VERIFICATION after every file operation
   - Fallback mechanisms for 100% success rate

### Numbered List of Standards

1. **Standard 0: Execution Enforcement** - Imperative language (MUST/WILL/SHALL), verification checkpoints, fallback mechanisms, Phase 0 role clarification
2. **Behavioral Injection Pattern** - Phase 0 path pre-calculation, Task tool invocations with injected context, no command-to-command invocations
3. **Verification-Fallback Pattern** - Path pre-calculation, MANDATORY VERIFICATION, fallback file creation for 100% success rate
4. **Imperative Language Standard** - ≥90% imperative ratio, MUST/WILL/SHALL for required actions, prohibited weak language
5. **Canonical Development Workflow** - 5-phase workflow (research → plan → implement → document → summarize) with topic-based organization
6. **Artifact Lifecycle Management** - Topic-based directories (specs/{NNN_topic}/), gitignore compliance, spec-updater integration
7. **Context Management** - Metadata-only passing, aggressive pruning, <30% context usage target

## Implementation Requirements for /orchestrate

### Mandatory Changes

1. **Add Phase 0: Role Clarification + Path Pre-Calculation**
   - Explicit "YOU ARE THE ORCHESTRATOR" declaration
   - "DO NOT execute tasks yourself" instruction
   - Calculate ALL artifact paths before Phase 1

2. **Convert All Directives to Imperative Language**
   - Replace "should" → "MUST"
   - Replace "may" → "WILL" (if required) or "MAY" (if optional)
   - Add "EXECUTE NOW" markers for critical code blocks

3. **Add MANDATORY VERIFICATION Checkpoints**
   - After research phase: verify all reports exist
   - After planning phase: verify plan exists
   - After implementation phase: verify implementation summary exists
   - After documentation phase: verify docs updated

4. **Add Fallback Mechanisms**
   - For each verification checkpoint, add fallback file creation
   - Guarantee 100% file creation rate

5. **Remove Command-to-Command Invocations**
   - Replace SlashCommand `/plan` with Task tool → plan-architect agent
   - Replace SlashCommand `/implement` with Task tool → implementer agent
   - Replace SlashCommand `/debug` with Task tool → debug-analyst agent
   - Replace SlashCommand `/document` with Task tool → doc-writer agent

6. **Inject Complete Context into Agents**
   - Include behavioral file reference
   - Inject pre-calculated paths
   - Specify success criteria
   - Define output format

### Validation Criteria

**Target**: Audit score ≥95/100 on enforcement rubric

- Imperative language ratio ≥90%
- Phase 0 present with role clarification
- MANDATORY VERIFICATION checkpoints after all file operations
- Fallback mechanisms for all agent file creation
- Zero command-to-command invocations
- Context usage <30% throughout workflow

## Cross-References

- [Command Architecture Standards](../../reference/command_architecture_standards.md)
- [Imperative Language Guide](../../guides/imperative-language-guide.md)
- [Behavioral Injection Pattern](../../concepts/patterns/behavioral-injection.md)
- [Verification-Fallback Pattern](../../concepts/patterns/verification-fallback.md)
- [Development Workflow](../../concepts/development-workflow.md)
- [Hierarchical Agents Guide](../../concepts/hierarchical-agents.md)

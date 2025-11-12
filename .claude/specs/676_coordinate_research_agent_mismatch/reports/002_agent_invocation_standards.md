# Agent Invocation Standards and Best Practices Research Report

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Agent Invocation Standards and Best Practices
- **Report Type**: Standards analysis and pattern recognition
- **Complexity Level**: 3

## Executive Summary

The project has comprehensive, well-documented standards for agent invocation patterns in Standard 11 (Imperative Agent Invocation Pattern) and the Behavioral Injection Pattern. These standards mandate imperative language, direct Task tool invocations without code fences, behavioral file references, and explicit completion signals. Key requirements include: (1) no documentation-only YAML blocks, (2) imperative instructions like "**EXECUTE NOW**: USE the Task tool", (3) agent behavioral files referenced via "Read and follow: .claude/agents/[name].md", and (4) explicit return signals ("REPORT_CREATED: [path]"). The standards have proven highly effective, achieving >90% agent delegation rates and 100% file creation reliability across all orchestration commands after fixes in Specs 438, 495, 502, and 675.

## Findings

### 1. Standard 11: Imperative Agent Invocation Pattern

**Location**: `.claude/docs/reference/command_architecture_standards.md` (lines 1173-1352)

**Core Requirements**:

1. **Imperative Instructions Required** (lines 1185-1189)
   - Must precede Task invocations
   - Examples: `**EXECUTE NOW**: USE the Task tool to invoke...`
   - Pattern: `**INVOKE AGENT**: Use the Task tool with...`
   - Alternative: `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File References** (lines 1190-1193)
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`
   - Examples: `.claude/agents/research-specialist.md`, `.claude/agents/plan-architect.md`
   - Direct reference to agent behavioral guidelines file

3. **No Code Block Wrappers** (lines 1194-1197)
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✅ CORRECT: `Task {` ... `}` (no fence)
   - Code fences mark content as documentation, preventing execution

4. **No "Example" Prefixes** (lines 1198-1200)
   - ❌ WRONG: "Example agent invocation:" or "The following shows..."
   - ✅ CORRECT: "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement** (lines 1201-1204)
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`
   - Purpose: Enables command-level verification of agent compliance
   - Requirement: Explicit confirmation from agent

**Correct Pattern Example** (lines 1206-1227):
```markdown
**EXECUTE NOW**: USE the Task tool to invoke the research-specialist agent.

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: OAuth 2.0 authentication for Node.js APIs
    - Output Path: /home/benjamin/.config/.claude/specs/027_auth/reports/001_oauth_patterns.md
    - Project Standards: /home/benjamin/.config/CLAUDE.md

    Execute research per behavioral guidelines.
    Return: REPORT_CREATED: /home/benjamin/.config/.claude/specs/027_auth/reports/001_oauth_patterns.md
  "
}
```

**Anti-Pattern Example** (lines 1231-1244):
```markdown
❌ INCORRECT - Documentation-only pattern never executes:

Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "Read .claude/agents/research-specialist.md..."
}
```

The code block wrapper prevents execution.
```

**Undermining Disclaimers Prohibition** (lines 1247-1276):
- Imperative directives MUST NOT be followed by disclaimers suggesting template usage
- ❌ FORBIDDEN: Adding "**Note**: The actual implementation will generate N Task calls" after `**EXECUTE NOW**`
- ✅ CORRECT: Using "for each [item]" phrasing and `[insert value]` placeholders for loops

**Historical Context** (lines 1305-1346):
- **Spec 438** (2025-10-24): Fixed /supervise with 0% → >90% delegation rate
- **Spec 495** (2025-10-27): Fixed /coordinate and /research delegation failures
- **Spec 057** (2025-10-27): Improved error handling and fail-fast principles
- **Spec 497**: Unified validation and testing across all orchestration commands

**Performance Metrics** (lines 1340-1347):
- Agent delegation rate: >90% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)
- Parallel execution: Enabled for independent operations
- Bootstrap reliability: 100% (fail-fast exposes configuration errors immediately)
- File creation verification: 100% reliability (70% → 100% with MANDATORY VERIFICATION checkpoints)

### 2. Behavioral Injection Pattern

**Location**: `.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162)

**Definition** (lines 9-17):
Behavioral Injection separates orchestrator and executor roles. Orchestrators calculate paths, manage state, and delegate work via Task tool. Executors (agents) receive context via file reads and produce artifacts. This transforms agents from autonomous executors into orchestrated workers following injected specifications.

**Rationale** (lines 19-38):

**Problems Solved**:
1. **Role Ambiguity**: Commands saying "I'll research the topic" cause Claude to execute directly instead of orchestrating agents
2. **Context Bloat**: Command-to-command invocations nest full prompts, causing exponential context growth

**Solutions**:
- Explicit orchestrator role: "YOU ARE THE ORCHESTRATOR. DO NOT execute yourself."
- Context injection into agent files: paths, constraints, specifications
- Agents read context and self-configure without tool invocations
- Achieves 100% file creation rate and <30% context usage

**Core Mechanism** (lines 43-103):

**Phase 0: Role Clarification** (lines 43-62):
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

**Path Pre-Calculation** (lines 64-81):
Before invoking any agent, calculate and validate all paths using bash blocks and artifact creation utilities.

**Context Injection Structure** (lines 83-102):
Inject workflow-specific context (topic, scope, constraints, output_path, output_format) into agent prompts through structured data.

**Valid Inline Templates** (lines 207-248):

The behavioral injection pattern applies to agent behavioral guidelines, NOT structural templates:

**MUST remain inline** (Structural Templates):
- Task invocation syntax: `Task { subagent_type, description, prompt }`
- Bash execution blocks: `**EXECUTE NOW**: bash commands`
- JSON schemas: Data structure definitions
- Verification checkpoints: `**MANDATORY VERIFICATION**: file checks`
- Critical warnings: `**CRITICAL**: error conditions`

**MUST be referenced, not duplicated** (Behavioral Content):
- Agent STEP sequences: `STEP 1/2/3` procedural instructions
- File creation workflows: `PRIMARY OBLIGATION` blocks
- Agent verification steps: Agent-internal quality checks
- Output format specifications: Templates for agent responses

**Benefits** (lines 249-257):
- 90% reduction applies to behavioral content, not structural templates
- Structural templates remain inline for immediate command execution
- Behavioral content referenced once from agent files
- Single source of truth for agent guidelines (no duplication)

### 3. Anti-Patterns to Avoid

#### Anti-Pattern 1: Inline Template Duplication (lines 262-323)

**Problem**: Duplicating 646 lines of research-specialist.md behavioral guidelines (~150 lines per invocation) in command prompts.

**❌ BAD Example** (lines 264-288):
```markdown
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

**Why It Fails**:
1. Duplicates behavioral guidelines (800+ lines across command file)
2. Creates maintenance burden (manual sync required)
3. Violates "single source of truth" principle
4. Adds unnecessary bloat

**✅ GOOD Example** (lines 297-323):
```markdown
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

**Benefits**: 90% reduction (150 lines → 15 lines per invocation), single source of truth, no synchronization needed, cleaner commands.

#### Anti-Pattern 2: Documentation-Only YAML Blocks (lines 325-414)

**Pattern Definition** (lines 327-329):
YAML code blocks (` ```yaml`) containing Task invocation examples prefixed with "Example" or wrapped in documentation context, causing 0% agent delegation rate.

**Detection Rule** (lines 329):
Search for ` ```yaml` blocks not preceded by imperative instructions like `**EXECUTE NOW**` or `USE the Task tool`.

**Real-World Example** (lines 331-346):
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

**Consequences** (lines 348-353):
1. 0% delegation rate (agent prompts appear but never execute)
2. Silent failure (no error messages)
3. Maintenance confusion (developers assume agents are delegating)
4. Wasted effort (debugging why artifacts aren't created)

**Correct Pattern** (lines 355-382):
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

**Key Differences** (lines 377-382):
1. Imperative instruction signals immediate execution
2. No code block wrapper (Task not fenced)
3. No "Example" prefix
4. Completion signal required

**Detection Script** (lines 384-404):
```bash
# Automated detection for documentation-only YAML blocks
for file in .claude/commands/*.md; do
  awk '/```yaml/{
    found=0
    for(i=NR-5; i<NR; i++) {
      if(lines[i] ~ /EXECUTE NOW|USE the Task tool/) found=1
    }
    if(!found) print FILENAME":"NR": Documentation-only YAML block"
  } {lines[NR]=$0}' "$file"
done
```

#### Anti-Pattern 3: Code-Fenced Task Examples Create Priming Effect (lines 416-527)

**Pattern Definition** (lines 418-422):
Code-fenced Task invocation examples (` ```yaml ... ``` `) establish a "documentation interpretation" pattern. Claude treats subsequent unwrapped Task blocks as non-executable examples, resulting in 0% delegation rate even when Task invocations are structurally correct.

**Root Cause** (lines 418-422):
Early code-fenced examples establish mental model that "Task blocks are documentation examples, not executable commands". This interpretation persists throughout the file.

**Real-World Example from /supervise** (lines 426-450):
```markdown
❌ INCORRECT - Code-fenced example at lines 62-79:
```yaml
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "..."
}
```

**Lines 350-400 (Actual invocations, no code fences)**:
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "..."
}

**Result**: 0% delegation rate due to priming effect from lines 62-79.
```

**Consequences** (lines 452-457):
1. 0% delegation rate despite correct Task structure
2. Streaming fallback masking (error recovery hides failure)
3. Parallel execution disabled
4. Context protection disabled (95% reduction blocked)
5. Diagnostic difficulty (static analysis shows correct syntax)

**Correct Pattern** (lines 459-482):
```markdown
✅ CORRECT - No code fences around Task invocations:

**Correct Pattern - Direct Agent Invocation**:

<!-- This Task invocation is executable -->
# ✅ CORRECT - Do this instead
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: "
    Read and follow ALL behavioral guidelines from: .claude/agents/plan-architect.md

    **Workflow-Specific Context**:
    - Plan Path: ${PLAN_PATH} (absolute path, pre-calculated)

    Return: PLAN_CREATED: ${PLAN_PATH}
  "
}
```

**Key Fixes** (lines 484-487):
1. Remove code fences (no ` ```yaml ... ``` ` wrapper)
2. Add HTML comment for clarification (invisible to Claude)
3. Keep anti-pattern examples fenced
4. Verify tool access (agents have Bash in allowed-tools)

**Verification After Fix** (lines 504-514):
```bash
# Expected metrics after fix:
# - Delegation rate: 0% → 100%
# - Context usage: >80% → <30%
# - Streaming fallback errors: Eliminated
# - Parallel agents: 2-4 executing simultaneously
```

#### Anti-Pattern 4: Undermined Imperative Pattern (lines 528-617)

**Pattern Definition** (lines 530-532):
Following imperative directives with disclaimers suggesting template or future generation creates confusion about whether to execute immediately. AI treats directive as documentation rather than instruction.

**Root Cause** (lines 534-536):
Disclaimers like "**Note**: The actual implementation will generate N calls" contradict imperative directives, causing template assumption and 0% delegation rates.

**Real-World Example from /supervise** (lines 539-550):
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

**Why It Fails** (lines 552-556):
1. Imperative contradicted ("**EXECUTE NOW**" vs "template")
2. Template assumption (disclaimer signals documentation)
3. Zero delegation (AI skips invocation entirely)
4. Confusing phrasing ("actual implementation will generate")

**Correct Pattern** (lines 558-577):
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

    Return: REPORT_CREATED: [EXACT_ABSOLUTE_PATH]
```

**Key Fixes** (lines 579-583):
1. Remove disclaimers (no "**Note**:" after imperative directives)
2. Use "for each [item]" (indicates loop expectation)
3. Use `[insert value]` placeholders (signals substitution clearly)
4. Bullet-point format (looks like instructions, not code templates)

**Detection Script** (lines 585-591):
```bash
# Find undermining disclaimers after EXECUTE NOW directives
grep -A 25 "\*\*EXECUTE NOW\*\*" .claude/commands/*.md | \
  grep -B 5 -i "note.*generate\|template\|example only\|actual implementation"
```

### 4. Agent Behavioral File Structure

**Location**: `.claude/agents/research-specialist.md` (example agent, lines 0-199 reviewed)

**YAML Frontmatter** (lines 0-6):
```yaml
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
description: Specialized in codebase research, best practice investigation, and report file creation
model: sonnet-4.5
model-justification: Codebase research, best practices synthesis, comprehensive report generation
fallback-model: sonnet-4.5
---
```

**Critical Instructions** (lines 8-17):
```markdown
**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT return summary text - only the report path confirmation
```

**Step-by-Step Structure** (lines 23-196):
- STEP 1: Receive and Verify Report Path (lines 23-44)
- STEP 1.5: Ensure Parent Directory Exists (lines 47-69)
- STEP 2: Create Report File FIRST (lines 72-117)
- STEP 3: Conduct Research and Update Report (lines 120-143)
- STEP 4: Verify and Return Confirmation (lines 146-196)

**Key Patterns**:
1. **Imperative Language**: "YOU MUST", "EXECUTE NOW", "ABSOLUTE REQUIREMENT"
2. **Sequential Dependencies**: "STEP N (REQUIRED BEFORE STEP N+1)"
3. **Verification Checkpoints**: "MANDATORY VERIFICATION", "CHECKPOINT"
4. **Explicit Return Format**: "REPORT_CREATED: [EXACT ABSOLUTE PATH]"

**Return Format Enforcement** (lines 179-196):
```markdown
**CHECKPOINT REQUIREMENT - Return Path Confirmation**

After verification, YOU MUST return ONLY this confirmation:

```
REPORT_CREATED: [EXACT ABSOLUTE PATH FROM STEP 1]
```

**CRITICAL REQUIREMENTS**:
- DO NOT return summary text or findings
- DO NOT paraphrase the report content
- ONLY return the "REPORT_CREATED: [path]" line
- The orchestrator will read your report file directly
```

### 5. Case Studies

#### Spec 495: /coordinate and /research Agent Delegation Failures (lines 677-840)

**Problem**: 0% agent delegation rate despite correct Task tool syntax
**Root Cause**: Documentation-only YAML blocks wrapped in markdown code fences
**Commands Affected**: `/coordinate` (9 invocations), `/research` (3 invocations + ~10 bash blocks)

**Evidence of Failure**:
- Zero reports created in `.claude/specs/NNN_topic/reports/`
- TODO1.md files contained agent output (wrong location)
- No PROGRESS: markers visible
- Delegation rate: 0% (0 of 9 invocations succeeded)

**Solution Applied**:
1. Removed code fences from Task invocations
2. Added imperative directives (`**EXECUTE NOW**: USE the Task tool NOW`)
3. Pre-calculated paths (explicit Bash tool invocation before agent call)
4. Replaced template variables with concrete examples
5. Added completion signals (`REPORT_CREATED:` verification)

**Results**:
- Delegation rate: 0% → >90% (9 of 9 invocations)
- File creation: 0% → 100% files in correct locations
- Performance: No overhead (proper delegation is efficient)
- Parallel execution: Now possible

#### Spec 057: /supervise Command Robustness Improvements (lines 841-1031)

**Problem**: Bootstrap failures and inconsistent error handling
**Root Cause**: Fallback mechanisms hiding configuration errors

**Problem 1: Function Name Mismatch**:
- Command called: `save_phase_checkpoint`, `load_phase_checkpoint`
- Library provided: `save_checkpoint`, `restore_checkpoint`
- Impact: 12 checkpoint calls failed silently

**Problem 2: Silent Fallbacks**:
```bash
if ! source .claude/lib/workflow-detection.sh; then
  detect_workflow_scope() { echo "research-only"; }  # Default fallback
fi
```

**Why It Failed**:
1. Silent configuration errors (library missing → fallback used)
2. Inconsistent behavior (some environments work, others use fallback)
3. Debugging difficulty (no clear error message)
4. False success (commands appeared to work but used degraded functionality)

**Solution Applied**:

**Fail-Fast Error Handling**:
```bash
if ! source .claude/lib/workflow-detection.sh; then
  echo "ERROR: Failed to source workflow-detection.sh"
  echo "EXPECTED PATH: $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "DIAGNOSTIC: ls -la $SCRIPT_DIR/.claude/lib/workflow-detection.sh"
  echo "CONTEXT: Library required for workflow scope detection"
  echo "ACTION: Verify library file exists and is readable"
  exit 1
fi
```

**Results**:
- Error message clarity: Generic → 7 enhanced diagnostics with actionable guidance
- Fallback removal: 32 lines of fallback functions eliminated
- File size: 2,323 → 2,291 lines (-1.4%)
- Behavior: Consistent across all environments (fail-fast principle)

**Fallback Philosophy** (lines 980-1005):

**Bootstrap Fallbacks (REMOVED - Hide Configuration Errors)**:
- Silent function definitions when libraries missing
- Automatic directory creation masking agent delegation failures
- Fallback workflow detection
- Default value substitution

**File Creation Verification Fallbacks (PRESERVED - Detect Tool Failures)**:
- MANDATORY VERIFICATION after each agent file creation
- File existence checks
- File size validation
- Fallback file creation when agent succeeded but Write tool failed
- Re-verification after fallback

**Performance**: 70% → 100% file creation reliability with verification

## Recommendations

### 1. Always Use Imperative Language for Agent Invocations

**Context**: Standard 11 requires imperative instructions preceding all Task tool invocations.

**Implementation**:
- Prefix every Task invocation with `**EXECUTE NOW**: USE the Task tool to invoke [agent-name]`
- Use explicit action verbs: "USE", "INVOKE", "CALL"
- Avoid passive documentation language: "Example invocation:", "The following shows..."

**Expected Outcome**: >90% agent delegation rate (proven across all orchestration commands)

**Reference**: Command Architecture Standards, lines 1185-1189

### 2. Never Wrap Task Invocations in Code Fences

**Context**: Code fences (` ```yaml ... ``` `) mark content as documentation, preventing execution and creating priming effects.

**Implementation**:
- Remove all ` ```yaml ` wrappers around Task invocations in executable contexts
- Use HTML comments for clarifications: `<!-- This Task invocation is executable -->`
- Keep anti-pattern examples fenced with clear ❌ marking
- Reserve code fences only for syntax reference sections

**Expected Outcome**: 0% → 100% delegation rate, eliminates priming effect

**Reference**: Behavioral Injection Pattern, lines 416-527

### 3. Reference Agent Behavioral Files, Don't Duplicate Guidelines

**Context**: Standard 12 (Structural vs Behavioral Separation) prohibits duplicating agent behavioral content in command prompts.

**Implementation**:
- Use pattern: `Read and follow ALL behavioral guidelines from: .claude/agents/[agent-name].md`
- Inject only workflow-specific context: topic, paths, standards file
- Keep structural templates inline: Task syntax, bash blocks, verification checkpoints
- Never duplicate STEP sequences, PRIMARY OBLIGATION blocks, or agent verification procedures

**Expected Outcome**: 90% code reduction per invocation (150 lines → 15 lines), single source of truth, zero synchronization burden

**Reference**: Behavioral Injection Pattern, lines 262-323; Command Architecture Standards, lines 1355-1453

### 4. Require Explicit Completion Signals from Agents

**Context**: Agents must return explicit confirmation to enable orchestrator verification.

**Implementation**:
- All agent prompts must specify: `Return: REPORT_CREATED: ${ABSOLUTE_PATH}`
- Orchestrators verify file existence after agent completion
- Use MANDATORY VERIFICATION checkpoints with diagnostic commands
- Fail-fast if file missing (don't create placeholder files)

**Expected Outcome**: 100% file creation reliability, clear error diagnostics, fail-fast principle compliance

**Reference**: Command Architecture Standards, lines 1201-1204; research-specialist.md, lines 179-196

### 5. Avoid Undermining Disclaimers After Imperative Directives

**Context**: Disclaimers suggesting template usage contradict imperative instructions, causing 0% delegation rates.

**Implementation**:
- Never add "**Note**: The actual implementation will generate N calls" after `**EXECUTE NOW**`
- Use "for each [item]" phrasing to indicate loops without disclaimers
- Use `[insert value]` placeholders to signal substitution clearly
- Keep imperatives clean and unambiguous

**Expected Outcome**: Clear execution intent, no template assumption, maintained >90% delegation rate

**Reference**: Behavioral Injection Pattern, lines 528-617; Command Architecture Standards, lines 1247-1276

### 6. Pre-Calculate All Artifact Paths Before Agent Invocation

**Context**: Phase 0 orchestrator responsibility to calculate paths before delegating to agents.

**Implementation**:
- Use bash blocks with artifact creation utilities: `create_topic_artifact()`, `get_or_create_topic_dir()`
- Calculate all report paths, plan paths, summary paths before any agent invocations
- Export or pass paths as absolute paths to agents
- Never rely on agents to calculate their own output paths

**Expected Outcome**: 100% file creation at correct locations, eliminates TODO*.md wrong-location artifacts

**Reference**: Behavioral Injection Pattern, lines 64-81; Command Architecture Standards, lines 338-418

### 7. Use Validation Scripts to Detect Anti-Patterns

**Context**: Automated validation prevents reintroduction of documentation-only patterns.

**Implementation**:
- Run `.claude/lib/validate-agent-invocation-pattern.sh` before merging command changes
- Add to CI pipeline: `.claude/tests/test_orchestration_commands.sh`
- Test delegation rate after any Task invocation modifications
- Use detection scripts for YAML blocks, template variables, undermining disclaimers

**Expected Outcome**: Zero regression incidents, early detection of anti-patterns, maintainable standards compliance

**Reference**: Behavioral Injection Pattern, lines 384-404, 585-591; Command Architecture Standards, lines 1297-1303

## References

### Primary Standards Documents
- `/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md` (lines 1173-1352) - Standard 11: Imperative Agent Invocation Pattern
- `/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md` (lines 1-1162) - Complete pattern documentation with anti-patterns and case studies
- `/home/benjamin/.config/.claude/docs/guides/command-development-guide.md` (lines 630-768) - Documentation-only pattern prevention and migration

### Agent Behavioral Files
- `/home/benjamin/.config/.claude/agents/research-specialist.md` (lines 0-199) - Example agent with imperative language and STEP structure
- `/home/benjamin/.config/.claude/agents/` - 22 agent behavioral files following same pattern

### Case Studies and Specs
- Spec 438 (2025-10-24): /supervise agent delegation fix (0% → >90%)
- Spec 495 (2025-10-27): /coordinate and /research delegation failures (9 + 3 invocations fixed)
- Spec 057 (2025-10-27): /supervise robustness improvements and fail-fast error handling
- Spec 502 (2025-10-27): Undermined imperative pattern discovery and fix
- Spec 497: Unified validation and testing across all orchestration commands

### Validation and Testing
- `.claude/lib/validate-agent-invocation-pattern.sh` - Automated detection script
- `.claude/tests/test_orchestration_commands.sh` - Comprehensive test suite
- `.claude/tests/test_library_sourcing_order.sh` - Library dependency validation

### Performance Evidence
- Agent delegation rate: >90% across all orchestration commands
- File creation rate: 100% at correct locations
- Context reduction: 90% per invocation via behavioral injection
- Bootstrap reliability: 100% via fail-fast principle
- Parallel execution: Enabled for independent operations

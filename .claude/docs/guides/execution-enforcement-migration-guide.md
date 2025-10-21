# Execution Enforcement Migration Guide

**Document Type**: Migration Guide
**Scope**: Commands and agents requiring execution enforcement upgrades
**Status**: ACTIVE - Use when upgrading existing commands/agents
**Last Updated**: 2025-10-20
**Related Standards**: [Command Architecture Standards - Standard 0 & 0.5](../reference/command_architecture_standards.md)

---

## Purpose

This guide provides a systematic process for migrating existing commands and agent files to use execution enforcement patterns (Standard 0 for commands, Standard 0.5 for agents). Following this process ensures reliable 100% file creation rates and predictable execution.

---

## Table of Contents

1. [Migration Overview](#migration-overview)
2. [Pre-Migration Assessment](#pre-migration-assessment)
3. [Command Migration Process](#command-migration-process)
   - [Phase 0: Clarify Command Role](#phase-0-clarify-command-role-critical-foundation) ← **NEW: Critical for multi-agent commands**
   - [Phase 1: Add Path Pre-Calculation](#phase-1-add-path-pre-calculation-pattern-1)
   - [Phase 2: Add Verification Checkpoints](#phase-2-add-verification-checkpoints-pattern-2)
   - [Phase 3: Add Checkpoint Reporting](#phase-3-add-checkpoint-reporting-pattern-4)
   - [Phase 4: Update Agent Invocation Templates](#phase-4-update-agent-invocation-templates)
4. [Agent Migration Process](#agent-migration-process)
5. [Testing and Validation](#testing-and-validation)
6. [Migration Checklist](#migration-checklist)
7. [Common Migration Patterns](#common-migration-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Migration Overview

### What Gets Migrated?

**Commands** (`.claude/commands/*.md`):
- Add "EXECUTE NOW" markers for critical operations
- Add "MANDATORY VERIFICATION" checkpoints
- Add fallback mechanisms for agent-dependent operations
- Add "THIS EXACT TEMPLATE" markers for agent invocations
- Add "CHECKPOINT REQUIREMENT" blocks for major steps

**Agents** (`.claude/agents/*.md`):
- Transform "I am" declarations to "YOU MUST" directives
- Add sequential step dependencies ("STEP N REQUIRED BEFORE STEP N+1")
- Elevate file creation to "PRIMARY OBLIGATION"
- Eliminate passive voice (should/may/can → MUST/WILL/SHALL)
- Add template-based output enforcement
- Add verification checkpoints
- Add completion criteria checklists

### Migration Priority

**High Priority** (migrate first):
- Commands that invoke agents (/orchestrate, /implement, /plan)
- Agents that create files (research-specialist, plan-architect, doc-writer)
- Commands with complex multi-step workflows

**Medium Priority**:
- Support commands (/debug, /document, /refactor)
- Specialized agents (code-writer, test-specialist)
- Workflow management commands

**Low Priority**:
- Utility commands (/list-plans, /list-reports)
- Read-only agents
- Simple single-step commands

### Expected Outcomes

**Before Migration**:
- Variable file creation rates (60-80%)
- Optional interpretation of steps
- Skipped verification checkpoints
- Unclear completion criteria

**After Migration**:
- 100% file creation rate (via enforcement + fallback)
- Mandatory step execution
- Explicit verification with fallback
- Clear, verifiable completion criteria

---

## Pre-Migration Assessment

### Step 1: Audit Current State

Use the audit script to assess current enforcement level:

```bash
# Audit a command
.claude/lib/audit-execution-enforcement.sh .claude/commands/your-command.md

# Expected output:
# Score: XX/100
# Missing patterns: [list]
# Recommendations: [list]
```

**Scoring interpretation**:
- **0-30**: Descriptive language, no enforcement → High priority migration
- **31-60**: Some imperative language, incomplete enforcement → Medium priority
- **61-84**: Good enforcement, some gaps → Low priority fine-tuning
- **85-94**: Strong enforcement, minor improvements → Optional enhancement
- **95-100**: Excellent enforcement → No migration needed

### Step 2: Identify Dependencies

Map command-agent relationships:

```bash
# Find agent invocations in command
grep -n "Task {" .claude/commands/your-command.md

# For each agent found, assess its enforcement level
.claude/lib/audit-execution-enforcement.sh .claude/agents/agent-name.md
```

**Migration order**: Always migrate agents BEFORE migrating commands that invoke them.

### Step 3: Document Current Behavior

Before making changes, document:
- Current file creation reliability (test 10 runs, count successes)
- Current verification checkpoints (grep for verification)
- Current error handling (grep for fallback mechanisms)

**Baseline metrics template**:
```markdown
## Pre-Migration Metrics

- **File Creation Rate**: X/10 (XX%)
- **Verification Checkpoints**: X present
- **Fallback Mechanisms**: X present
- **Audit Score**: XX/100
- **Migration Priority**: High/Medium/Low
```

---

## Command Migration Process

### Phase 0: Clarify Command Role (Critical Foundation)

**When**: ALL commands that orchestrate subagents

**Priority**: HIGHEST - Must be done FIRST before all other phases

**Problem**: Commands with ambiguous opening statements cause Claude to execute tasks directly instead of delegating to subagents.

**Root Cause**: First-person declarative language ("I'll research...") is interpreted as "I (Claude) should do this" rather than "I will orchestrate agents to do this".

---

#### Pattern A: Ambiguous Opening (Broken)

**Symptoms**:
- Claude uses Read/Write/Grep tools directly
- No Task tool invocations visible in output
- Single artifact created instead of multiple subtopic artifacts
- No parallelization or metadata reduction

**Example** (from `/report` command):
```markdown
# Generate Research Report

I'll research the specified topic and create a comprehensive report in the most appropriate location.

## Topic/Question
$ARGUMENTS

## Process
[sections describing hierarchical multi-agent pattern...]
```

**Claude's Interpretation**:
- "I'll research" → "I (Claude) will research"
- Sees sections as documentation/examples, not executable directives
- Executes research directly using available tools

**Result**: ❌ Hierarchical pattern not executed, no subagents invoked

---

#### Pattern B: Clear Orchestrator Role (Fixed)

**Solution**: Explicitly state Claude's role as orchestrator in opening paragraph.

**Template**:
```markdown
# [Command Name]

I'll orchestrate [task type] by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the [executor/researcher/implementer].

**CRITICAL INSTRUCTIONS**:
- DO NOT execute [task] yourself using [tool list] tools
- ONLY use Task tool to delegate [task] to [agent-type] agents
- Your job: [orchestration steps: decompose → invoke → verify → synthesize]

You will NOT see [task results] directly. Agents will create [artifact type],
and you will [action] after creation.

## [Task] Description
$ARGUMENTS

## Process
[sections with executable directives using Phase 1-4 patterns...]
```

**Example** (fixed `/report`):
```markdown
# Generate Research Report

I'll orchestrate hierarchical research by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize

You will NOT see research findings directly. Agents will create report files,
and you will read those files after creation.

## Research Topic
$ARGUMENTS

## Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Source Utilities and Decompose Topic**
[executable directive with bash code...]
```

**Claude's Interpretation**:
- "I'll orchestrate" → "I will coordinate agents"
- "YOU are the ORCHESTRATOR" → "My role is to delegate, not execute"
- "DO NOT execute research yourself" → "I should not use Read/Grep/Write"
- "ONLY use Task tool" → "I must invoke agents"
- "EXECUTE NOW" markers → "These are commands to execute, not examples"

**Result**: ✅ Hierarchical pattern executed correctly, subagents invoked

---

#### Before/After Example: /report Command

**BEFORE** (Ambiguous - Broken):
```markdown
# Generate Research Report

I'll research the specified topic and create a comprehensive report in the most appropriate location.

## Topic/Question
$ARGUMENTS

## Process

### 1. Topic Analysis
First, I'll analyze the topic to determine:
- Key concepts and scope
- Complexity and breadth (determines number of subtopics)
```

**Execution Trace**:
```
User: /report "topic"
Claude reads opening: "I'll research the specified topic"
Claude interprets: "I should research this topic myself"
Claude executes: Read, Grep, Write (direct research)
Result: Single report, no subagents
```

**AFTER** (Clear Role - Fixed):
```markdown
# Generate Research Report

I'll orchestrate hierarchical research by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize

## Research Topic
$ARGUMENTS

## Process

### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Source Utilities and Decompose Topic**
```

**Execution Trace**:
```
User: /report "topic"
Claude reads opening: "I'll orchestrate... You are the ORCHESTRATOR"
Claude interprets: "I should delegate, not execute research myself"
Claude sees: "EXECUTE NOW - Source Utilities" (executable directive)
Claude executes: Bash (source utilities), Task (invoke agents)
Result: Multiple subtopic reports + overview, hierarchical pattern executed
```

---

#### Migration Steps for Phase 0

**Step 1: Identify Command Type** (2 minutes)

Determine if command orchestrates subagents:
```bash
grep -c "Task {" .claude/commands/your-command.md
# If count > 0: Command orchestrates subagents → needs Phase 0
```

**Step 2: Analyze Opening Statement** (3 minutes)

Check for ambiguous language:
```bash
# Read first 20 lines
head -20 .claude/commands/your-command.md

# Look for problematic patterns:
# - "I'll [verb]" where verb is the task (research, implement, analyze)
# - No explicit role clarification
# - No "DO NOT" constraints
```

**Step 3: Rewrite Opening** (10 minutes)

Use the template from Pattern B:
1. Change "I'll [task]" to "I'll orchestrate [task] by delegating..."
2. Add "**YOUR ROLE**:" section
3. Add "**CRITICAL INSTRUCTIONS**:" with DO NOT and ONLY directives
4. Add "You will NOT see [results] directly" explanation

**Step 4: Update Section Headers** (5 minutes)

Transform documentation-style headers to executable directives:

**Before**:
```markdown
### 1. Topic Analysis
First, I'll analyze the topic to determine:
```

**After**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition

**EXECUTE NOW - Source Utilities and Decompose Topic**

YOU MUST run this code block NOW:
```

**Step 5: Test** (5 minutes)

Run command and verify:
```bash
/your-command "test input"

# Expected in output:
# - Task tool invocations visible
# - Multiple agents invoked (if parallel pattern)
# - Verification checkpoints executed
# - NOT: Direct tool usage (Read/Write for agent tasks)
```

**Total Time**: ~25 minutes per command

---

#### Common Mistakes to Avoid

**Mistake 1: Half-Way Fix**
```markdown
❌ I'll orchestrate research by creating a comprehensive report...
```
Still says "I'll... creating" → suggests direct execution

**Mistake 2: Missing "DO NOT" Constraints**
```markdown
❌ **YOUR ROLE**: You are the orchestrator.

[No explicit "DO NOT use tools directly" statement]
```
Role stated but constraints unclear

**Mistake 3: Tools Listed Without Context**
```markdown
❌ Use Task tool to delegate research.
```
Missing "ONLY" and "DO NOT use Read/Grep/Write"

**Mistake 4: No Execution Markers**
```markdown
❌ ### 1. Topic Decomposition

Decompose the topic into subtopics:
```
Still descriptive, needs "STEP 1 (REQUIRED BEFORE STEP 2)" and "EXECUTE NOW"

---

#### Quick Checklist for Phase 0

After applying Phase 0 fix, verify:

- [ ] Opening statement says "I'll orchestrate" (not "I'll [execute task]")
- [ ] "**YOUR ROLE**:" section explicitly states orchestrator role
- [ ] "**CRITICAL INSTRUCTIONS**:" includes:
  - [ ] "DO NOT execute [task] yourself using [tools]"
  - [ ] "ONLY use Task tool to delegate"
  - [ ] List of orchestration steps
- [ ] "You will NOT see [results] directly" explanation present
- [ ] All major sections use "STEP N (REQUIRED BEFORE STEP N+1)" format
- [ ] All critical operations use "EXECUTE NOW" markers
- [ ] Bash code blocks preceded by imperative instructions
- [ ] Task invocations preceded by "AGENT INVOCATION - Use THIS EXACT TEMPLATE"

---

### Phase 1: Add Path Pre-Calculation (Pattern 1)

**When**: Command invokes agents that create files

**Before**:
```markdown
## Workflow

### Step 2: Invoke Research Agent

Invoke agent to research topic:
```yaml
Task {
  description: "Research authentication patterns"
  prompt: "Research OAuth 2.0 patterns and create a report."
}
```
```

**After**:
```markdown
## Workflow

### Step 1: Pre-Calculate Report Paths

**EXECUTE NOW - Calculate Report Paths**

Before invoking agents, calculate exact file paths:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$RESEARCH_TOPIC" ".claude/specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "001_${TOPIC_SLUG}" "")
echo "Report will be written to: $REPORT_PATH"
```

**WHY THIS MATTERS**: Agents receive explicit paths, commands can verify exact locations, fallback creation knows where to write.

### Step 2: Invoke Research Agent

**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: File creation is your PRIMARY task.

    Research Topic: OAuth 2.0 authentication
    Output Path: ${REPORT_PATH}

    **CRITICAL**: YOU MUST create the file at the exact path specified.
    DO NOT return a text summary without creating the file.

    Return ONLY: REPORT_CREATED: ${REPORT_PATH}
  "
}
```

**ENFORCEMENT**: Copy this template verbatim. Do NOT simplify the prompt.
```

**Key additions**:
- Step 1 added for path pre-calculation
- "EXECUTE NOW" marker
- "WHY THIS MATTERS" context
- "THIS EXACT TEMPLATE" marker for agent invocation
- "ABSOLUTE REQUIREMENT" in agent prompt
- "ENFORCEMENT" warning

### Phase 2: Add Verification Checkpoints (Pattern 2)

**When**: After agent execution or critical file operations

**Before**:
```markdown
### Step 3: Use Report in Planning

Extract report path and use it for planning:
```bash
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "Report:")
# Continue to planning...
```
```

**After**:
```markdown
### Step 3: Verify Report Creation

**MANDATORY VERIFICATION - Report File Exists**

After agent completes, YOU MUST verify the file was created:

```bash
EXPECTED_PATH="${REPORT_PATH}"

if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file at $EXPECTED_PATH"
  echo "Executing fallback creation..."

  # Fallback: Extract content from agent output
  cat > "$EXPECTED_PATH" <<EOF
# ${RESEARCH_TOPIC}

## Findings
${AGENT_OUTPUT}
EOF

  echo "✓ Fallback file created at $EXPECTED_PATH"
fi

echo "✓ Verified: Report exists at $EXPECTED_PATH"
```

**GUARANTEE**: File exists regardless of agent compliance.

### Step 4: Use Report in Planning

Report path is guaranteed to exist, proceed with planning...
```

**Key additions**:
- "MANDATORY VERIFICATION" marker
- Explicit file existence check
- Fallback creation mechanism
- Success confirmation
- "GUARANTEE" statement

### Phase 3: Add Checkpoint Reporting (Pattern 4)

**When**: After major workflow phases

**Before**:
```markdown
### Step 5: Complete Research Phase

Research complete, proceed to planning.
```

**After**:
```markdown
### Step 5: Complete Research Phase

**CHECKPOINT REQUIREMENT**

After research phase, report status:

```
CHECKPOINT: Research phase complete
- Topics researched: ${#TOPICS[@]}
- Reports created: ${#VERIFIED_REPORTS[@]}
- All files verified: ✓
- Proceeding to: Planning phase
```

This reporting is MANDATORY and confirms proper execution.
```

**Key additions**:
- "CHECKPOINT REQUIREMENT" marker
- Explicit status report with metrics
- "MANDATORY" enforcement
- Clear transition to next phase

### Phase 4: Update Agent Invocation Templates

**Pattern**: Replace all agent invocations with enforcement template

**Search for**: `Task {` blocks in command file

**Replace with**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "[Brief task description]"
  prompt: "
    Read and follow: .claude/agents/[agent-name].md

    **ABSOLUTE REQUIREMENT**: [Key requirement, e.g., file creation]

    [Task-specific context]
    Output Path: ${OUTPUT_PATH}

    **CRITICAL**: YOU MUST [critical action].
    DO NOT [anti-pattern].

    Return ONLY: [Expected output format]
  "
}
```

**For each agent invocation**:
1. Add "THIS EXACT TEMPLATE (No modifications)" marker
2. Include "ABSOLUTE REQUIREMENT" for critical operations
3. Add "CRITICAL" and "DO NOT" directives
4. Specify exact output format

---

## Agent Migration Process

### Phase 1: Transform Role Declaration

**Before**:
```markdown
# Research Specialist Agent

I am a specialized agent focused on thorough research and analysis.

My role is to:
- Investigate the codebase for patterns
- Create structured markdown report files using Write tool
- Emit progress markers during research
```

**After**:
```markdown
# Research Specialist Agent

**YOU MUST perform these exact steps in sequence.**

**PRIMARY OBLIGATION**: Creating the report file is MANDATORY, not optional.

**ROLE**: You are a research specialist with ABSOLUTE REQUIREMENT to create structured report files.
```

**Changes**:
- "I am" → "YOU MUST perform"
- "My role is to" → "PRIMARY OBLIGATION"
- Passive list → Active imperatives

### Phase 2: Add Sequential Step Dependencies

**Before**:
```markdown
## Research Process

1. Analyze the research topic and scope
2. Search codebase using Grep, Glob, Read tools
3. Research best practices using WebSearch, WebFetch
4. Organize findings into coherent report structure
5. Create report file in topic directory
6. Verify links and cross-references work
```

**After**:
```markdown
## STEP 1 (REQUIRED BEFORE STEP 2) - Pre-Calculate Report Path

**EXECUTE NOW - Calculate Report Path**

Before beginning research, calculate the exact file path where you will write the report:

```bash
REPORT_PATH="${OUTPUT_DIR}/${TOPIC_SLUG}.md"
echo "Report will be written to: $REPORT_PATH"
```

**VERIFICATION**: Confirm path is absolute and directory exists.

---

## STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research

**YOU MUST investigate the topic using these tools IN THIS ORDER:**

1. **Codebase Analysis** (MANDATORY):
   - Grep: Search for relevant patterns
   - Glob: Find related files
   - Read: Analyze implementations

2. **External Research** (REQUIRED if topic needs current best practices):
   - WebSearch: Find 2025 best practices
   - WebFetch: Retrieve authoritative sources

**CHECKPOINT**: Emit progress marker after each research phase:
```
PROGRESS: Codebase analysis complete (N files analyzed)
PROGRESS: External research complete (N sources reviewed)
```

---

## STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File

**EXECUTE NOW - Create Report File**

**THIS IS YOUR PRIMARY TASK**: YOU MUST use the Write tool to create the report file at the exact path from Step 1.

**WHY THIS MATTERS**:
- Commands depend on file artifacts at predictable paths
- Text-only summaries break workflow dependencies
- Plan execution needs cross-referenced artifacts

[Template specification follows]

---

## STEP 4 (MANDATORY VERIFICATION) - Verify File Creation

**YOU MUST execute this verification** after creating the report:

```bash
test -f "$REPORT_PATH" || echo "CRITICAL: Report file not created at $REPORT_PATH"
```

**CHECKPOINT REQUIREMENT**: Emit this confirmation:
```
CHECKPOINT: Report created and verified at $REPORT_PATH"
```
```

**Changes**:
- Flat list → Sequential STEPs with dependencies
- Simple descriptions → Enforcement blocks per step
- Implicit ordering → Explicit "REQUIRED BEFORE" dependencies
- No verification → "MANDATORY VERIFICATION" blocks

### Phase 3: Eliminate Passive Voice

**Search patterns**: `should`, `may`, `can`, `consider`, `try to`

**Before**:
```markdown
- You should create a report file in the topic directory
- Links should be verified after creating the file
- You may add additional sections as needed
- Consider including code examples for clarity
- Try to use current best practices
```

**After**:
```markdown
- **YOU MUST create** a report file at the exact path specified
- **YOU WILL verify** all links after creating the file using this command: [...]
- **YOU SHALL include** these exact sections (additional sections are FORBIDDEN)
- **YOU MUST add** concrete code examples using this template: [...]
- **YOU WILL use** 2025 best practices (earlier practices are UNACCEPTABLE)
```

**Transformation rules**:
- "should" → "MUST"
- "may" → "WILL" or "SHALL"
- "can" → "MUST" or "SHALL"
- "consider" → "MUST" or "SHALL"
- "try to" → "WILL"

### Phase 4: Add Template Enforcement

**Before**:
```markdown
## Output Format

Create markdown report with these sections:
- Overview (2-3 sentences)
- Current State Analysis
- Research Findings
- Recommendations
- References

You may adjust the structure if needed.
```

**After**:
```markdown
## OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)

YOUR REPORT MUST contain these sections IN THIS ORDER:

```markdown
# [Topic Title]

## Overview
[2-3 sentence summary - REQUIRED, not optional]

## Current State Analysis
[Existing implementation details - MANDATORY section]

## Research Findings
[Detailed findings - MINIMUM 5 bullet points REQUIRED]

## Recommendations
[Specific, actionable guidance - MINIMUM 3 recommendations REQUIRED]

## Implementation Guidance
[Step-by-step implementation steps - REQUIRED]

## References
[Sources and links - ALL sources MUST be listed]

## Metadata
- Research Date: [YYYY-MM-DD - REQUIRED]
- Files Analyzed: [List of files - REQUIRED if codebase research performed]
- External Sources: [List of URLs - REQUIRED if web research performed]
```

**ENFORCEMENT**: Every section marked REQUIRED or MANDATORY is NON-NEGOTIABLE. Reports missing required sections are INCOMPLETE.
```

**Changes**:
- Flexible structure → "THIS EXACT TEMPLATE"
- Optional sections → "REQUIRED" / "MANDATORY" markers
- "may adjust" → "NON-NEGOTIABLE"
- Implied standards → Explicit minimums

### Phase 5: Add Completion Criteria

**Before**:
```markdown
## Success Criteria

- Research complete
- Report created
- Ready for use in planning
```

**After**:
```markdown
## COMPLETION CRITERIA - ALL REQUIRED

Before completing your task, verify ALL of these:
- [x] Report file exists at exact path specified
- [x] Report contains all mandatory sections
- [x] All sections marked REQUIRED are present and populated
- [x] All internal links are functional
- [x] Checkpoint confirmation emitted
- [x] File path returned in this exact format: "REPORT_CREATED: /path/to/report.md"

**NON-COMPLIANCE**: Returning a summary without creating the file is UNACCEPTABLE.
```

**Changes**:
- Vague criteria → Specific checklist
- Implied requirements → Explicit "ALL REQUIRED"
- No format specification → Exact output format
- No consequences → "NON-COMPLIANCE" warning

---

## Testing and Validation

### Post-Migration Testing

**Test 1: File Creation Rate**

Run the command/agent 10 times, count file creation successes:

```bash
for i in {1..10}; do
  # Run command/agent
  /your-command "test task $i"

  # Check if file was created
  if [ -f "$EXPECTED_FILE" ]; then
    echo "Run $i: SUCCESS"
  else
    echo "Run $i: FAILED"
  fi
done
```

**Target**: 10/10 successes (100% rate)

**Test 2: Verification Checkpoint Execution**

Check output for verification markers:

```bash
/your-command "test task" 2>&1 | grep -E "(✓ Verified|CHECKPOINT|MANDATORY)"
```

**Expected**: All verification and checkpoint markers appear in output

**Test 3: Fallback Activation**

Simulate agent non-compliance:

```bash
# Temporarily modify agent to NOT create file
# Run command
# Verify fallback created the file
```

**Expected**: File exists despite agent non-compliance

**Test 4: Audit Score Improvement**

Re-run audit after migration:

```bash
.claude/lib/audit-execution-enforcement.sh .claude/commands/your-command.md
```

**Target**: Score ≥95/100

### Regression Testing

**Verify**:
- [ ] Existing functionality still works
- [ ] Previously passing tests still pass
- [ ] No breaking changes to command interface
- [ ] Backward compatibility maintained (if required)

---

## Migration Checklist

### Command Migration Checklist

Use this checklist for each command being migrated:

**Pre-Migration**:
- [ ] Audit score recorded (baseline)
- [ ] File creation rate measured (baseline)
- [ ] Agent dependencies mapped
- [ ] Current behavior documented

**Migration**:
- [ ] Phase 1: Path pre-calculation added
- [ ] Phase 2: Verification checkpoints added
- [ ] Phase 3: Checkpoint reporting added
- [ ] Phase 4: Agent invocation templates updated
- [ ] All "EXECUTE NOW" markers added
- [ ] All "MANDATORY VERIFICATION" blocks added
- [ ] All "CHECKPOINT REQUIREMENT" blocks added
- [ ] All "THIS EXACT TEMPLATE" markers added
- [ ] All "WHY THIS MATTERS" contexts added

**Post-Migration**:
- [ ] File creation rate tested (target: 100%)
- [ ] Verification checkpoints tested
- [ ] Fallback mechanisms tested
- [ ] Audit score re-measured (target: ≥95/100)
- [ ] Regression tests passed
- [ ] Documentation updated
- [ ] Review checklist completed

### Agent Migration Checklist

Use this checklist for each agent being migrated:

**Pre-Migration**:
- [ ] Audit score recorded (baseline)
- [ ] File creation rate measured (baseline)
- [ ] Commands that invoke this agent identified
- [ ] Current behavior documented

**Migration**:
- [ ] Phase 1: Role declaration transformed
- [ ] Phase 2: Sequential step dependencies added
- [ ] Phase 3: Passive voice eliminated
- [ ] Phase 4: Template enforcement added
- [ ] Phase 5: Completion criteria added
- [ ] All "YOU MUST" directives added
- [ ] All "STEP N (REQUIRED BEFORE STEP N+1)" markers added
- [ ] All "ABSOLUTE REQUIREMENT" markers added
- [ ] All "MANDATORY VERIFICATION" blocks added
- [ ] All "THIS EXACT TEMPLATE" markers added
- [ ] All "WHY THIS MATTERS" contexts added

**Post-Migration**:
- [ ] File creation rate tested (target: 100%)
- [ ] Sequential step compliance tested
- [ ] Template adherence tested
- [ ] Verification checkpoint execution tested
- [ ] Fallback compatibility tested
- [ ] Audit score re-measured (target: ≥95/100)
- [ ] Regression tests passed
- [ ] Documentation updated
- [ ] Review checklist completed

---

## Common Migration Patterns

### Pattern M1: Research Command Migration

**Typical structure**:
1. User provides research topic
2. Command invokes research-specialist agent
3. Agent creates report file
4. Command uses report in downstream operations

**Migration steps**:
1. Add path pre-calculation before agent invocation
2. Add "ABSOLUTE REQUIREMENT" to agent prompt
3. Add "MANDATORY VERIFICATION" after agent execution
4. Add fallback creation if agent doesn't comply
5. Add "CHECKPOINT" after research phase

**Before/After**: See [Standard 0 examples](../reference/command_architecture_standards.md#pattern-1-direct-execution-blocks)

### Pattern M2: Planning Command Migration

**Typical structure**:
1. Research phase (0-N agents)
2. Planning phase (plan-architect agent)
3. Plan file creation
4. Return plan path to user

**Migration steps**:
1. Migrate research phase (Pattern M1)
2. Add plan path pre-calculation
3. Add "ABSOLUTE REQUIREMENT" to plan-architect prompt
4. Add "MANDATORY VERIFICATION" after plan creation
5. Add fallback plan creation
6. Add "CHECKPOINT" after each phase

### Pattern M3: Implementation Command Migration

**Typical structure**:
1. Load plan
2. For each phase:
   a. Execute tasks
   b. Run tests
   c. Commit
3. Generate summary

**Migration steps**:
1. Add "EXECUTE NOW" for plan loading
2. Add "MANDATORY VERIFICATION" for plan file existence
3. For each phase:
   - Add "EXECUTE NOW" for task execution
   - Add "MANDATORY" test execution
   - Add verification before commit
4. Add "CHECKPOINT" after each phase
5. Add summary path pre-calculation
6. Add summary fallback creation

---

## Troubleshooting

### Issue: Audit Score Not Improving

**Symptoms**: Score remains <85 after migration

**Diagnosis**:
```bash
# Check which patterns are missing
.claude/lib/audit-execution-enforcement.sh your-file.md | grep "Missing:"
```

**Solution**: Systematically add each missing pattern from the audit report

### Issue: File Creation Rate Still <100%

**Symptoms**: Files not created consistently after migration

**Diagnosis**:
1. Check if paths are pre-calculated: `grep "EXECUTE NOW.*Path" file.md`
2. Check if verification exists: `grep "MANDATORY VERIFICATION" file.md`
3. Check if fallback exists: `grep "Fallback" file.md`

**Solution**:
- Add missing path pre-calculation
- Add missing verification checkpoint
- Add missing fallback mechanism
- Test fallback activation explicitly

### Issue: Migration Breaks Existing Functionality

**Symptoms**: Previously working command now fails

**Diagnosis**:
1. Run regression tests
2. Check if new enforcement conflicts with existing logic
3. Verify bash syntax in new code blocks

**Solution**:
- Review Phase-by-Phase, test after each phase
- Ensure enforcement supplements (doesn't replace) existing logic
- Validate all bash code blocks

### Issue: Agent Invocations Too Long

**Symptoms**: Agent prompts exceed reasonable size (>1000 tokens)

**Diagnosis**: Too much enforcement detail in prompts

**Solution**:
- Use behavioral injection (reference agent file)
- Keep prompt enforcement concise:
  - "ABSOLUTE REQUIREMENT: Create file"
  - "CRITICAL: Use exact path"
  - "Return ONLY: [format]"
- Detailed enforcement goes in agent file, not prompt

---

## Migration Timeline

### Small Command/Agent (1-2 pages)
- **Pre-Migration Assessment**: 15 minutes
- **Migration**: 30-45 minutes
- **Testing**: 15 minutes
- **Total**: ~1 hour

### Medium Command/Agent (3-5 pages)
- **Pre-Migration Assessment**: 30 minutes
- **Migration**: 1-2 hours
- **Testing**: 30 minutes
- **Total**: ~2-3 hours

### Large Command/Agent (6+ pages)
- **Pre-Migration Assessment**: 45 minutes
- **Migration**: 3-4 hours
- **Testing**: 1 hour
- **Total**: ~5-6 hours

### Batch Migration (5 commands + 6 agents)
- **Assessment**: 2 hours
- **Agent Migration** (do first): 6-8 hours
- **Command Migration**: 8-10 hours
- **Testing**: 2-3 hours
- **Total**: ~18-23 hours

---

## Success Metrics

### Command Migration Success

**Criteria**:
- [x] Audit score ≥95/100
- [x] File creation rate 100% (10/10 tests)
- [x] All verification checkpoints execute
- [x] Fallback mechanisms activate when needed
- [x] Checkpoint reporting at all major steps
- [x] Zero regressions

### Agent Migration Success

**Criteria**:
- [x] Audit score ≥95/100
- [x] All imperative language (zero passive voice)
- [x] Sequential step dependencies present
- [x] File creation marked as PRIMARY OBLIGATION
- [x] Template enforcement present
- [x] Completion criteria explicit
- [x] Compatible with command-level fallbacks

---

## References

- **[Command Architecture Standards](../reference/command_architecture_standards.md)**: Standard 0 (Command Enforcement) and Standard 0.5 (Agent Enforcement)
- **[Creating Commands Guide](creating-commands.md)**: Section 5.5 (Subagent Prompt Enforcement Patterns)
- **[Audit Script](../../lib/audit-execution-enforcement.sh)**: Enforcement pattern scoring tool
- **[Test Suite](../../tests/test_execution_enforcement.sh)**: Automated enforcement validation
- **[Review Checklist](../reference/command_architecture_standards.md#review-checklist)**: PR review criteria

---

## Quick Start Example

**Migrate a simple research command in 1 hour**:

```bash
# 1. Assess (15 min)
.claude/lib/audit-execution-enforcement.sh .claude/commands/research.md
# Note baseline score: e.g., 45/100

# 2. Migrate research-specialist agent first (20 min)
# - Transform role declaration
# - Add sequential steps
# - Eliminate passive voice
# - Add template enforcement
# - Add completion criteria

# 3. Migrate command (20 min)
# - Add path pre-calculation
# - Update agent invocation template
# - Add verification + fallback
# - Add checkpoint reporting

# 4. Test (10 min)
for i in {1..10}; do
  /research "test topic $i"
done
# Verify: 10/10 files created

# 5. Re-audit
.claude/lib/audit-execution-enforcement.sh .claude/commands/research.md
# Target: ≥95/100

# Success!
```

---

**Migration Guide Status**: ✅ COMPLETE
**Version**: 1.0
**Maintained By**: Execution Enforcement Working Group
**Feedback**: Report issues or suggestions via project issue tracker

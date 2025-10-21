# Execution Enforcement Guide

**Document Type**: Comprehensive Guide
**Scope**: Command and agent execution enforcement (Standards 0 and 0.5)
**Status**: ACTIVE - Use for all command/agent creation and migration
**Last Updated**: 2025-10-21
**Related Standards**: [Command Architecture Standards - Standard 0 & 0.5](../reference/command_architecture_standards.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Standards 0 and 0.5](#standards-0-and-0-5)
3. [Enforcement Patterns](#enforcement-patterns)
4. [Migration Process](#migration-process)
5. [Validation and Audit](#validation-and-audit)
6. [Common Migration Patterns](#common-migration-patterns)
7. [Troubleshooting](#troubleshooting)
8. [Quick Reference](#quick-reference)

---

## Overview

### Purpose

This guide provides comprehensive documentation for creating and migrating commands and agents to use execution enforcement patterns. These patterns achieve:
- **100% file creation rates** (vs 60-80% without enforcement)
- **Predictable execution** (mandatory step compliance)
- **Reliable verification** (explicit checkpoints)
- **Consistent outputs** (standardized formats)

### What Is Execution Enforcement?

Execution enforcement transforms optional, descriptive guidance into mandatory, executable directives:

**Before** (Descriptive):
```markdown
You should create a report file after completing the research.
```

**After** (Enforcement):
```markdown
### STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File

**EXECUTE NOW - Create File**

YOU MUST use the Write tool to create the report at the exact path from Step 1.
This is your PRIMARY task.
```

### When to Use This Guide

- **Creating new commands**: Apply enforcement patterns from the start
- **Creating new agents**: Use enforcement templates for reliability
- **Migrating existing commands/agents**: Follow systematic migration process
- **Debugging file creation issues**: Use validation techniques
- **Improving audit scores**: Target ≥95/100 for production readiness

---

## Standards 0 and 0.5

### Standard 0: Command Execution Enforcement

Commands (`.claude/commands/*.md`) must use:
- **"EXECUTE NOW" markers** for critical operations
- **"MANDATORY VERIFICATION" checkpoints** for file creation
- **Fallback mechanisms** for agent-dependent operations
- **"THIS EXACT TEMPLATE" markers** for agent invocations
- **"CHECKPOINT REQUIREMENT" blocks** for major steps

### Standard 0.5: Agent Execution Enforcement

Agents (`.claude/agents/*.md`) must use:
- **"YOU MUST" directives** (not "I am" declarations)
- **Sequential step dependencies** ("STEP N REQUIRED BEFORE STEP N+1")
- **"PRIMARY OBLIGATION"** for file creation
- **Imperative voice** (MUST/WILL/SHALL, not should/may/can)
- **Template-based output enforcement**
- **Verification checkpoints**
- **Completion criteria checklists**

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

---

## Enforcement Patterns

### Pattern 1: Role Declaration

**Purpose**: Establish imperative tone and primary obligation immediately

**Template**:
```markdown
# [Agent Name]

**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- [Primary task] is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT [anti-pattern specific to agent]

**PRIMARY OBLIGATION**: [Core responsibility] is MANDATORY, not optional.
```

**Scoring Impact**: +10 points (Imperative Language section)

---

### Pattern 2: Sequential Step Dependencies

**Purpose**: Enforce strict execution order with explicit dependencies

**Template**:
```markdown
### STEP [N] (REQUIRED BEFORE STEP [N+1]) - [Step Name]

**[MANDATORY|EXECUTE NOW] [Action Type]**

[Detailed instructions for this step]

**CHECKPOINT**: [Verification requirement before next step]
```

**Example**:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path. Verify you have received it:

```bash
# This path is provided by the invoking command in your prompt
REPORT_PATH="[PATH PROVIDED IN YOUR PROMPT]"

# CRITICAL: Verify path is absolute
if [[ ! "$REPORT_PATH" =~ ^/ ]]; then
  echo "CRITICAL ERROR: Path is not absolute: $REPORT_PATH"
  exit 1
fi

echo "✓ VERIFIED: Absolute report path received: $REPORT_PATH"
```

**CHECKPOINT**: YOU MUST have an absolute path before proceeding to Step 2.
```

**Scoring Impact**: +15 points (Step Dependencies section)

---

### Pattern 3: File-First Creation

**Purpose**: Guarantee artifact creation before any processing

**Template**:
```markdown
### STEP 2 (REQUIRED BEFORE STEP 3) - Create [Artifact] File FIRST

**EXECUTE NOW - Create File**

**ABSOLUTE REQUIREMENT**: YOU MUST create the [artifact] file NOW using the Write tool. Create it with initial structure BEFORE [main activity].

**WHY THIS MATTERS**: Creating the file first guarantees artifact creation even if [main activity] encounters errors. This is the PRIMARY task.

Use the Write tool to create the file at the EXACT path from Step 1:

```markdown
# [Initial file structure template]
```

**MANDATORY VERIFICATION - File Created**:

After using Write tool, verify:
```bash
if [ ! -f "$FILE_PATH" ]; then
  echo "CRITICAL ERROR: File not created at: $FILE_PATH"
  exit 1
fi

echo "✓ VERIFIED: File created at $FILE_PATH"
```

**CHECKPOINT**: File must exist at $FILE_PATH before proceeding to Step 3.
```

**Scoring Impact**: +10 points (File Creation Enforcement section)

---

### Pattern 4: Verification Checkpoints

**Purpose**: Ensure critical operations complete successfully

**Template**:
```markdown
**MANDATORY VERIFICATION - [What is being verified]**

After [operation], YOU MUST verify:

```bash
# Verification code
if [ ! -f "$FILE_PATH" ]; then
  echo "CRITICAL ERROR: [Error message]"
  exit 1
fi

# Additional checks (size, content, permissions)
FILE_SIZE=$(wc -c < "$FILE_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt [MIN_SIZE] ]; then
  echo "WARNING: File too small (${FILE_SIZE} bytes)"
fi

echo "✓ VERIFIED: [Success message]"
```

**CHECKPOINT**: [Requirement statement]
```

**Scoring Impact**: +20 points (Verification Checkpoints section)

---

### Pattern 5: Return Format Specification

**Purpose**: Enforce consistent, parseable output for orchestrators

**Template**:
```markdown
**CHECKPOINT REQUIREMENT - Return [Format Type]**

After verification, YOU MUST return ONLY this confirmation:

```
[FORMAT_NAME]: [EXACT_PATH_OR_DATA]
```

**CRITICAL REQUIREMENTS**:
- DO NOT return [verbose content type]
- DO NOT [anti-pattern action]
- ONLY return the "[FORMAT_NAME]: [data]" line
- The orchestrator will [how orchestrator will handle output]

**Example Return**:
```
[FORMAT_NAME]: [concrete example]
```
```

**Example**:
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

**Example Return**:
```
REPORT_CREATED: /home/user/.claude/specs/067_auth/reports/001_patterns.md
```
```

**Scoring Impact**: +5 points (Return Format section)

---

### Pattern 6: Progress Streaming

**Purpose**: Provide visibility during long-running operations

**Template**:
```markdown
## Progress Streaming (MANDATORY During [Activity])

**YOU MUST emit progress markers during [activity]** to provide visibility:

### Progress Marker Format
```
PROGRESS: <brief-message>
```

### Required Progress Markers

YOU MUST emit these markers at each milestone:

1. **Starting** (STEP [N]): `PROGRESS: [Starting message]`
2. **[Milestone 1]** (during [activity]): `PROGRESS: [Activity message]`
3. **[Milestone 2]** (during [activity]): `PROGRESS: [Activity message]`
...
N. **Completing** (STEP [N]): `PROGRESS: [Completion message]`

### Progress Message Requirements
- **Brief**: 5-10 words maximum
- **Actionable**: Describes current activity
- **Frequent**: Every major operation
```

**Scoring Impact**: +5 points (Context: improves debugging)

---

### Pattern 7: Operational Guidelines (Do/Don't Lists)

**Purpose**: Summarize critical behaviors as quick reference

**Template**:
```markdown
## Operational Guidelines

### What YOU MUST Do
- **[Action 1]** ([context or step reference])
- **[Action 2]** ([context or step reference])
- **[Action 3]** ([context or step reference])
...

### What YOU MUST NOT Do
- **DO NOT [anti-pattern 1]** - [consequence or rationale]
- **DO NOT [anti-pattern 2]** - [consequence or rationale]
- **DO NOT [anti-pattern 3]** - [consequence or rationale]
...
```

**Scoring Impact**: +10 points (Critical Requirements section)

---

### Pattern 8: Completion Criteria Checklist

**Purpose**: Define verifiable success criteria before task completion

**Template**:
```markdown
### STEP [FINAL] (ABSOLUTE REQUIREMENT) - Verify and Return

**MANDATORY VERIFICATION - [Artifact] Complete**

After [main activity], YOU MUST verify:

**Verification Checklist** (ALL must be ✓):
- [ ] [Criterion 1: existence check]
- [ ] [Criterion 2: content check]
- [ ] [Criterion 3: quality check]
- [ ] [Criterion 4: standards check]
- [ ] [Criterion 5: format check]
...

**Final Verification Code**:
```bash
# [Verification script with multiple checks]
```

**CHECKPOINT REQUIREMENT - Return [Format]**
[See Pattern 5 for return format specification]
```

**Scoring Impact**: +5 points (Completion Criteria section)

---

### Pattern 9: Agent Invocation Template (Commands)

**Purpose**: Ensure consistent agent invocation in commands

**Template** (for commands):
```markdown
## STEP [N] - Invoke [Agent Name]

Use THIS EXACT TEMPLATE (No modifications):

```
I'm invoking [agent-name] to [purpose].

**[AGENT_NAME] INVOCATION - THIS EXACT TEMPLATE (No modifications)**

Task {
  subagent_type: "[agent-type]"
  description: "[Agent name] - [brief purpose]"
  prompt: |
    [MANDATORY INPUTS YOU MUST PROVIDE]:
    - [Input 1]: [value or variable]
    - [Input 2]: [value or variable]

    [TASK DESCRIPTION]

    [RETURN FORMAT REQUIREMENT]
}
```

**CRITICAL**: DO NOT modify this template. Provide all MANDATORY INPUTS.
```

**Scoring Impact**: Commands score +10 points for agent invocation patterns

---

### Pattern 10: Passive Voice Elimination

**Purpose**: Transform optional language to mandatory directives

**Transformation Table**:

| Pattern | Before | After |
|---------|--------|-------|
| should | "You should create the file" | "YOU MUST create the file" |
| may | "You may include examples" | "YOU WILL include examples" |
| can | "You can use Unicode" | "YOU SHALL use Unicode" |
| consider | "Consider adding links" | "YOU MUST add links" |
| try to | "Try to verify links" | "YOU WILL verify links" |
| could | "You could add tests" | "YOU MUST add tests" |
| might | "You might need to check" | "YOU WILL check" |

**Search Pattern**:
```bash
grep -n "\bshould\b\|\bmay\b\|\bcan\b\|\bconsider\b\|\btry to\b\|\bcould\b\|\bmight\b" agent-file.md
```

**Scoring Impact**: Avoids -5 to -10 penalty (Passive Voice Anti-Pattern section)

---

### Pattern 11: Fallback Mechanisms (Commands Only)

**Purpose**: Ensure file creation even when agent non-compliance occurs

**Template** (for commands):
```markdown
## STEP [N] - Verify [Agent] Output and Fallback

**MANDATORY VERIFICATION - [Agent] File Creation**

After [agent-name] completes, verify file was created:

```bash
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "WARNING: [Agent] did not create file, using fallback"

  # FALLBACK MECHANISM - Create minimal file
  Write {
    file_path: "$EXPECTED_FILE"
    content: |
      # [Artifact Type]

      ## Auto-Generated Fallback

      [Agent] was invoked but did not create file.
      This is a minimal placeholder.

      [Basic template content]
  }

  echo "✓ FALLBACK: Created minimal file at $EXPECTED_FILE"
else
  echo "✓ VERIFIED: [Agent] created file at $EXPECTED_FILE"
fi
```
```

**Scoring Impact**: Commands score +10 points (Fallback Mechanisms section)

---

### Pattern Scoring Summary

| Pattern | Audit Section | Points |
|---------|---------------|--------|
| Role Declaration | Imperative Language | +10 |
| Sequential Steps | Step Dependencies | +15 |
| Verification Checkpoints | Verification Checkpoints | +20 |
| Fallback Mechanisms | Fallback Mechanisms | +10 |
| Critical Requirements | Critical Requirements | +10 |
| File-First Creation | File Creation Enforcement | +10 |
| Return Format | Return Format Specification | +5 |
| Passive Voice Elimination | Passive Voice (anti-pattern) | -10 to 0 |
| Operational Guidelines | (distributed across sections) | +10 |
| **Total** | | **85-95** |

**Target score**: ≥95/100

---

## Migration Process

### Pre-Migration Assessment

#### Step 1: Audit Current State

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

#### Step 2: Identify Dependencies

Map command-agent relationships:

```bash
# Find agent invocations in command
grep -n "Task {" .claude/commands/your-command.md

# For each agent found, assess its enforcement level
.claude/lib/audit-execution-enforcement.sh .claude/agents/agent-name.md
```

**Migration order**: Always migrate agents BEFORE migrating commands that invoke them.

#### Step 3: Document Current Behavior

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

### Command Migration Process

#### Phase 0: Clarify Command Role (Critical Foundation)

**When**: ALL commands that orchestrate subagents

**Priority**: HIGHEST - Must be done FIRST before all other phases

**Problem**: Commands with ambiguous opening statements cause Claude to execute tasks directly instead of delegating to subagents.

**Root Cause**: First-person declarative language ("I'll research...") is interpreted as "I (Claude) should do this" rather than "I will orchestrate agents to do this".

---

**Pattern A: Ambiguous Opening (Broken)**

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

**Pattern B: Clear Orchestrator Role (Fixed)**

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

**Result**: ✅ Hierarchical pattern executed correctly, subagents invoked

---

**Migration Steps for Phase 0** (Total Time: ~25 minutes per command):

**Step 1: Identify Command Type** (2 minutes)
```bash
grep -c "Task {" .claude/commands/your-command.md
# If count > 0: Command orchestrates subagents → needs Phase 0
```

**Step 2: Analyze Opening Statement** (3 minutes)
```bash
# Read first 20 lines
head -20 .claude/commands/your-command.md

# Look for problematic patterns:
# - "I'll [verb]" where verb is the task (research, implement, analyze)
# - No explicit role clarification
# - No "DO NOT" constraints
```

**Step 3: Rewrite Opening** (10 minutes)
1. Change "I'll [task]" to "I'll orchestrate [task] by delegating..."
2. Add "**YOUR ROLE**:" section
3. Add "**CRITICAL INSTRUCTIONS**:" with DO NOT and ONLY directives
4. Add "You will NOT see [results] directly" explanation

**Step 4: Update Section Headers** (5 minutes)

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
```bash
/your-command "test input"

# Expected in output:
# - Task tool invocations visible
# - Multiple agents invoked (if parallel pattern)
# - Verification checkpoints executed
# - NOT: Direct tool usage (Read/Write for agent tasks)
```

---

**Quick Checklist for Phase 0**:

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

#### Phase 1: Add Path Pre-Calculation (Pattern 1)

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

---

#### Phase 2: Add Verification Checkpoints (Pattern 2)

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

---

#### Phase 3: Add Checkpoint Reporting (Pattern 4)

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

---

#### Phase 4: Update Agent Invocation Templates

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

### Agent Migration Process

#### Phase 1: Transform Role Declaration

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

---

#### Phase 2: Add Sequential Step Dependencies

(Use Pattern 2 template - see Enforcement Patterns section)

---

#### Phase 3: Eliminate Passive Voice

(Use Pattern 10 transformation table - see Enforcement Patterns section)

---

#### Phase 4: Add Template Enforcement

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

**ENFORCEMENT**: Every section marked REQUIRED or MANDATORY is NON-NEGOTIABLE.
```

---

#### Phase 5: Add Completion Criteria

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

---

### Migration Checklist

#### Command Migration Checklist

**Pre-Migration**:
- [ ] Audit score recorded (baseline)
- [ ] File creation rate measured (baseline)
- [ ] Agent dependencies mapped
- [ ] Current behavior documented

**Migration**:
- [ ] Phase 0: Orchestrator role clarified (if multi-agent command)
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

#### Agent Migration Checklist

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

## Validation and Audit

### Running the Audit Script

The audit script analyzes command and agent files for enforcement pattern compliance.

**Basic Usage**:
```bash
# Audit a command file
.claude/lib/audit-execution-enforcement.sh .claude/commands/plan.md

# Audit an agent file
.claude/lib/audit-execution-enforcement.sh .claude/agents/research-specialist.md

# Audit multiple files
for file in .claude/commands/*.md; do
  echo "Auditing: $file"
  .claude/lib/audit-execution-enforcement.sh "$file"
  echo ""
done
```

**Output Format**:
```
Execution Enforcement Audit Report
File: .claude/commands/plan.md
Type: command

Enforcement Score: 87/100

Pattern Detection:
✓ Path Pre-Calculation (Pattern 1): DETECTED
✓ Verification Checkpoints (Pattern 2): DETECTED
✓ Checkpoint Reporting (Pattern 4): DETECTED
✗ Agent Invocation Templates (Pattern 5): NOT DETECTED
✓ Behavioral Injection (Pattern 6): DETECTED

Recommendations:
- Add agent invocation templates with "THIS EXACT TEMPLATE" markers
- Increase verification checkpoint frequency (found 2, recommend 5)

Migration Priority: MEDIUM (score 61-84)
```

---

### Interpreting Audit Scores

**Score Ranges**:

| Score | Level | Interpretation | Action Required |
|-------|-------|----------------|-----------------|
| 0-30 | Minimal | Descriptive language, no enforcement patterns | High priority migration |
| 31-60 | Basic | Some imperative language, incomplete enforcement | Medium priority migration |
| 61-84 | Good | Most patterns present, some gaps | Low priority enhancement |
| 85-94 | Strong | All core patterns present, minor improvements | Optional refinement |
| 95-100 | Excellent | Complete enforcement, best practices | No action needed |

---

### File Creation Validation

**Test Protocol**:
```bash
# Test file creation reliability (10 trials)
for i in {1..10}; do
  echo "Trial $i/10"

  # Clean environment
  rm -rf test_artifacts/

  # Invoke command
  /command-name "test input"

  # Check if expected files created
  if [ -f "expected_output.md" ]; then
    echo "✓ Trial $i: File created"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "✗ Trial $i: File NOT created"
  fi
done

# Calculate success rate
echo "File creation rate: $SUCCESS/10"
# Target: 10/10 (100%)
```

**Validation Checklist**:
- [ ] Command creates expected files in 10/10 trials
- [ ] Verification checkpoints execute in correct sequence
- [ ] Fallback mechanisms trigger when agent fails
- [ ] All paths calculated before file operations
- [ ] Checkpoint reports appear in command output

---

### Batch Auditing

**Audit all commands**:
```bash
for cmd in .claude/commands/*.md; do
  echo "Auditing: $cmd"
  .claude/lib/audit-execution-enforcement.sh "$cmd" --json >> audit-results.json
done
```

**Audit all agents**:
```bash
for agent in .claude/agents/*.md; do
  echo "Auditing: $agent"
  .claude/lib/audit-execution-enforcement.sh "$agent" --json >> audit-results.json
done
```

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

**Reference**: See [Standard 0 examples](../reference/command_architecture_standards.md#pattern-1-direct-execution-blocks)

---

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

---

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

---

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

---

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

---

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

### Issue: Verification Checkpoints Not Executing

**Symptoms**: Checkpoint markers not appearing in command/agent output

**Diagnosis**:
1. Check if CHECKPOINT markers are in file
2. Verify checkpoint code is not in comments
3. Check if STEP dependencies are being followed

**Solutions**:
- Ensure CHECKPOINT markers are executable (not just comments)
- Add echo statements for checkpoints
- Verify sequential STEP execution

---

## Quick Reference

### Pattern Usage Guide

**When creating new agents**:
1. **Pattern 1**: Role Declaration → Opening section
2. **Pattern 2**: Sequential Steps → Main process structure
3. **Pattern 3**: File-First Creation → STEP 2 (or earliest step)
4. **Pattern 4**: Verification Checkpoints → After each file operation
5. **Pattern 5**: Return Format → Final step
6. **Pattern 6**: Progress Streaming → Separate section
7. **Pattern 7**: Operational Guidelines → Summary section
8. **Pattern 8**: Completion Criteria → Final verification step
9. **Pattern 10**: Passive Voice Elimination → Throughout

**When creating new commands**:
1. **Pattern 9**: Agent Invocation Template → For each agent call
2. **Pattern 11**: Fallback Mechanisms → After agent invocations
3. **Phase 0**: Clarify orchestrator role (if multi-agent)

---

### Migration Timeline

**Small Command/Agent (1-2 pages)**:
- **Pre-Migration Assessment**: 15 minutes
- **Migration**: 30-45 minutes
- **Testing**: 15 minutes
- **Total**: ~1 hour

**Medium Command/Agent (3-5 pages)**:
- **Pre-Migration Assessment**: 30 minutes
- **Migration**: 1-2 hours
- **Testing**: 30 minutes
- **Total**: ~2-3 hours

**Large Command/Agent (6+ pages)**:
- **Pre-Migration Assessment**: 45 minutes
- **Migration**: 3-4 hours
- **Testing**: 1 hour
- **Total**: ~5-6 hours

---

### Success Metrics

**Command Migration Success**:
- [x] Audit score ≥95/100
- [x] File creation rate 100% (10/10 tests)
- [x] All verification checkpoints execute
- [x] Fallback mechanisms activate when needed
- [x] Checkpoint reporting at all major steps
- [x] Zero regressions

**Agent Migration Success**:
- [x] Audit score ≥95/100
- [x] All imperative language (zero passive voice)
- [x] Sequential step dependencies present
- [x] File creation marked as PRIMARY OBLIGATION
- [x] Template enforcement present
- [x] Completion criteria explicit
- [x] Compatible with command-level fallbacks

---

### Reference Model Files

**High Scorers (Use as Templates)**:
- `.claude/agents/research-specialist.md` (110/100) - Best overall reference
- `.claude/agents/plan-architect.md` (100/100) - Excellent step dependencies
- `.claude/commands/debug.md` (100/100) - Perfect command enforcement
- `.claude/commands/expand.md` (100/100) - Excellent verification patterns

**Study These** when implementing patterns.

---

## Cross-References

### Architectural Patterns

This guide implements enforcement patterns from the [Patterns Catalog](../concepts/patterns/README.md):

- [Behavioral Injection](../concepts/patterns/behavioral-injection.md) - Agent invocation via context injection
- [Verification and Fallback](../concepts/patterns/verification-fallback.md) - Mandatory file creation checkpoints
- [Checkpoint Recovery](../concepts/patterns/checkpoint-recovery.md) - State preservation for resumable workflows
- [Metadata Extraction](../concepts/patterns/metadata-extraction.md) - Summary-based context passing

### Related Guides

- [Migration Testing Guide](./migration-testing.md) - Testing procedures and validation infrastructure
- [Command Development Guide](./command-development-guide.md) - Complete command development patterns
- [Agent Development Guide](./agent-development-guide.md) - Agent creation and behavioral guidelines
- [Standards Integration](./standards-integration.md) - CLAUDE.md standards discovery

### Reference Documentation

- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 0 and 0.5 definitions
- [Command Reference](../reference/command-reference.md) - Complete command catalog
- [Agent Reference](../reference/agent-reference.md) - Available specialized agents

---

**Guide Status**: ✅ COMPLETE
**Version**: 1.0 (Consolidated from 5 migration guides)
**Last Updated**: 2025-10-21
**Maintained By**: Execution Enforcement Working Group
**Feedback**: Report issues or suggestions via project issue tracker

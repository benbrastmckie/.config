# Execution Enforcement Patterns

## Overview

This document extracts proven enforcement patterns from high-scoring agents (≥95/100) for use as templates during migration. These patterns achieve 100% file creation rates and predictable execution.

**Reference Models**:
- research-specialist.md (110/100) - Highest scoring agent
- plan-architect.md (100/100) - Perfect enforcement
- code-writer.md (60/100) - Good reference for code generation patterns

---

## Pattern 1: Role Declaration

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

**Example** (from research-specialist.md:7-15):
```markdown
**YOU MUST perform these exact steps in sequence:**

**CRITICAL INSTRUCTIONS**:
- File creation is your PRIMARY task (not optional)
- Execute steps in EXACT order shown below
- DO NOT skip verification checkpoints
- DO NOT use relative paths (absolute paths only)
- DO NOT return summary text - only the report path confirmation
```

**Key Elements**:
1. **Opening directive**: "YOU MUST perform" establishes imperative tone
2. **CRITICAL INSTRUCTIONS block**: 5 bullet points with 3 DO NOT items minimum
3. **PRIMARY task declaration**: Elevates file creation to top priority
4. **PRIMARY OBLIGATION**: Explicit statement that file creation is mandatory

**Impact**: Scores +10 points (Imperative Language section)

---

## Pattern 2: Sequential Step Dependencies

**Purpose**: Enforce strict execution order with explicit dependencies

**Template**:
```markdown
### STEP [N] (REQUIRED BEFORE STEP [N+1]) - [Step Name]

**[MANDATORY|EXECUTE NOW] [Action Type]**

[Detailed instructions for this step]

**CHECKPOINT**: [Verification requirement before next step]
```

**Example** (from research-specialist.md:20-41):
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

**Key Elements**:
1. **STEP header**: Includes number, dependency, and descriptive name
2. **Action marker**: MANDATORY, EXECUTE NOW, REQUIRED, or ABSOLUTE REQUIREMENT
3. **Verification code**: Bash snippets showing exact validation
4. **CHECKPOINT**: Explicit gate before next step

**Impact**: Scores +15 points (Step Dependencies section)

---

## Pattern 3: File-First Creation

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

**Example** (from research-specialist.md:44-89):
- Creates report file with placeholder structure BEFORE conducting research
- Ensures artifact exists even if research fails
- Uses Write tool immediately (not after accumulating content)

**Key Elements**:
1. **Timing**: File creation happens BEFORE main activity (research, analysis, etc.)
2. **Rationale**: Explicit "WHY THIS MATTERS" explanation
3. **Verification**: Mandatory file existence check
4. **Template**: Shows exact file structure to create

**Impact**: Scores +10 points (File Creation Enforcement section)

---

## Pattern 4: Verification Checkpoints

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

**Example** (from research-specialist.md:132-149):
```bash
# Verify file exists
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL ERROR: Report file not found at: $REPORT_PATH"
  echo "This should be impossible - file was created in Step 2"
  exit 1
fi

# Verify file is not empty
FILE_SIZE=$(wc -c < "$REPORT_PATH" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 500 ]; then
  echo "WARNING: Report file is too small (${FILE_SIZE} bytes)"
  echo "Expected >500 bytes for a complete report"
fi

echo "✓ VERIFIED: Report file complete and saved"
```

**Key Elements**:
1. **Existence check**: Always verify file exists
2. **Size check**: Validate file has meaningful content (>200-500 bytes)
3. **Error messages**: Include exact path and context
4. **Success marker**: "✓ VERIFIED:" prefix for positive confirmation

**Impact**: Scores +20 points (Verification Checkpoints section)

---

## Pattern 5: Return Format Specification

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

**Example** (from research-specialist.md:152-169):
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

**Key Elements**:
1. **Format specification**: Exact string format with placeholders
2. **Prohibitions**: List what NOT to include (prevents verbose output)
3. **Rationale**: Explain why (orchestrator reads file directly)
4. **Concrete example**: Show exact expected output

**Impact**: Scores +5 points (Return Format section)

---

## Pattern 6: Progress Streaming

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

### Example Progress Flow
```
PROGRESS: [Step 1 message]
PROGRESS: [Step 2 message]
PROGRESS: [Step 3 message]
...
```
```

**Example** (from research-specialist.md:173-209):
```markdown
### Required Progress Markers

YOU MUST emit these markers at each milestone:

1. **Starting** (STEP 2): `PROGRESS: Creating report file at [path]`
2. **Starting Research** (STEP 3 start): `PROGRESS: Starting research on [topic]`
3. **Searching** (during search): `PROGRESS: Searching codebase for [pattern]`
4. **Analyzing** (during analysis): `PROGRESS: Analyzing [N] files found`
5. **Web Research** (if applicable): `PROGRESS: Searching for [topic] best practices`
6. **Updating** (during writes): `PROGRESS: Updating report with findings`
7. **Completing** (STEP 4): `PROGRESS: Research complete, report verified`
```

**Key Elements**:
1. **Mandatory**: Labeled as MANDATORY, not optional
2. **Format standard**: Consistent "PROGRESS: " prefix
3. **Milestone list**: Enumerated markers for each major step
4. **Requirements**: Brief, actionable, frequent
5. **Example flow**: Shows complete progress sequence

**Impact**: Scores +5 points (Context: improves debugging), not directly scored by audit

---

## Pattern 7: Operational Guidelines (Do/Don't Lists)

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

**Example** (from research-specialist.md:214-228):
```markdown
### What YOU MUST Do
- **Create report file FIRST** (Step 2, before any research)
- **Use absolute paths ONLY** (never relative paths)
- **Write to file incrementally** (don't accumulate in memory)
- **Emit progress markers** (at each milestone)
- **Verify file exists** (before returning)
- **Return path confirmation ONLY** (no summary text)

### What YOU MUST NOT Do
- **DO NOT skip file creation** - it's the PRIMARY task
- **DO NOT use relative paths** - always absolute
- **DO NOT return summary text** - only path confirmation
- **DO NOT skip verification** - always check file exists
- **DO NOT accumulate findings in memory** - write incrementally
```

**Key Elements**:
1. **Parallel structure**: MUST Do / MUST NOT Do sections
2. **Bolded actions**: Easy to scan
3. **Context**: Step references or rationale in parentheses
4. **Completeness**: Covers all critical behaviors

**Impact**: Scores +10 points (Critical Requirements section)

---

## Pattern 8: Completion Criteria Checklist

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

**Example** (from research-specialist.md:118-149):
```markdown
**Verification Checklist** (ALL must be ✓):
- [ ] Report file exists at $REPORT_PATH
- [ ] Executive Summary completed (not placeholder)
- [ ] Findings section has detailed content
- [ ] Recommendations section has at least 3 items
- [ ] References section lists all files analyzed
- [ ] All file references include line numbers
```

**Key Elements**:
1. **Checkbox format**: Visual checklist with [ ]
2. **ALL must be met**: Explicit requirement for 100% completion
3. **Verifiable**: Each item is objective (not subjective)
4. **Comprehensive**: Covers existence, content, quality, standards

**Impact**: Scores +5 points (Completion Criteria section)

---

## Pattern 9: Agent Invocation Template

**Purpose**: Ensure consistent agent invocation in commands (Standard 0)

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

**Example** (from /report command):
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research Specialist - Topic analysis"
  prompt: |
    REPORT_PATH: $ABSOLUTE_REPORT_PATH

    Research the topic and create comprehensive report.

    Return format: REPORT_CREATED: [path]
}
```

**Key Elements**:
1. **Template marker**: "THIS EXACT TEMPLATE (No modifications)"
2. **Mandatory inputs**: Explicitly labeled section
3. **Format requirement**: Specify expected return format
4. **Warning**: Critical note not to modify template

**Impact**: Commands score +10 points for agent invocation patterns

---

## Pattern 10: Passive Voice Elimination

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
| recommended | "It's recommended to..." | "YOU MUST..." |
| suggested | "It's suggested to..." | "YOU SHALL..." |

**Search Pattern**:
```bash
grep -n "\bshould\b\|\bmay\b\|\bcan\b\|\bconsider\b\|\btry to\b\|\bcould\b\|\bmight\b" agent-file.md
```

**Target**: Zero instances of passive voice (except in examples or quotes)

**Impact**: Avoids -5 to -10 penalty (Passive Voice Anti-Pattern section)

---

## Pattern 11: Fallback Mechanisms (Commands Only)

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

**Key Elements**:
1. **Existence check**: Verify agent created file
2. **Fallback action**: Create minimal file if missing
3. **Warning**: Log that fallback was used
4. **Success marker**: Confirm file exists (via agent or fallback)

**Impact**: Commands score +10 points (Fallback Mechanisms section)

---

## Usage Guide

### When Creating New Agents

Use all patterns 1-8, 10:
1. **Pattern 1**: Role Declaration → Opening section
2. **Pattern 2**: Sequential Steps → Main process structure
3. **Pattern 3**: File-First Creation → STEP 2 (or earliest step)
4. **Pattern 4**: Verification Checkpoints → After each file operation
5. **Pattern 5**: Return Format → Final step
6. **Pattern 6**: Progress Streaming → Separate section
7. **Pattern 7**: Operational Guidelines → Summary section
8. **Pattern 8**: Completion Criteria → Final verification step
9. **Pattern 10**: Passive Voice Elimination → Throughout

### When Migrating Existing Agents

Follow 5-phase transformation:
1. **Phase 1**: Add Pattern 1 (Role Declaration)
2. **Phase 2**: Convert to Pattern 2 (Sequential Steps)
3. **Phase 3**: Apply Pattern 10 (Eliminate Passive Voice)
4. **Phase 4**: Add Patterns 3, 4, 5 (File-First, Verification, Return Format)
5. **Phase 5**: Add Patterns 6, 7, 8 (Progress, Guidelines, Completion)

### When Creating New Commands

Use patterns 9, 11:
1. **Pattern 9**: Agent Invocation Template → For each agent call
2. **Pattern 11**: Fallback Mechanisms → After agent invocations

### When Migrating Existing Commands

Add enforcement patterns:
1. **Phase 0**: Clarify orchestrator role (if multi-agent command)
2. **Pattern 1**: Path pre-calculation with "EXECUTE NOW"
3. **Pattern 4**: Verification checkpoints with "MANDATORY VERIFICATION"
4. **Pattern 11**: Fallback mechanisms
5. **Pattern 9**: Update agent invocations with "THIS EXACT TEMPLATE"

---

## Scoring Impact Summary

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

Target score: ≥95/100

---

## Reference Model Files

**High Scorers (Use as Templates)**:
- `.claude/agents/research-specialist.md` (110/100) - Best overall reference
- `.claude/agents/plan-architect.md` (100/100) - Excellent step dependencies
- `.claude/commands/debug.md` (100/100) - Perfect command enforcement
- `.claude/commands/expand.md` (100/100) - Excellent verification patterns

**Study These** when implementing patterns.

---

## Related Documentation

- [Execution Enforcement Migration Guide](./execution-enforcement-migration-guide.md) - Step-by-step migration process
- [Migration Testing Guide](./migration-testing.md) - Testing procedures
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 0 and 0.5 definitions

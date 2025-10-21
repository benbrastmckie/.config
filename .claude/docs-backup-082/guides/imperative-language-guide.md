# Imperative Language Guide for Commands and Agents

**Document Type**: Guide
**Audience**: Command and agent authors
**Purpose**: Ensure all required elements use imperative language to prevent optional interpretation
**Related Standards**: [Standard 0: Execution Enforcement](../reference/command_architecture_standards.md#standard-0-execution-enforcement-new)

---

## Purpose

This guide ensures commands and agents use **clear, imperative language** that makes required elements unambiguous. Weak language (should, may, can) allows Claude to interpret requirements as optional, leading to incomplete execution and file creation failures.

**Core Principle**: Required actions use MUST/WILL/SHALL. Optional actions use MAY. Descriptive text is prohibited in execution instructions.

---

## Why Imperative Language Matters

### The Problem: Weak Language Creates Optional Behavior

**Weak Language Example** (allows skipping):
```markdown
❌ BAD:
- You should create a report file in the topic directory
- Links should be verified after creating the file
- You may add additional sections as needed
- Consider including code examples for clarity
- Try to use current best practices
```

**Result**: Claude may skip file creation, verification, or examples because "should" and "may" suggest optionality.

### The Solution: Imperative Language Enforces Requirements

**Imperative Language Example** (requires action):
```markdown
✅ GOOD:
- **YOU MUST create** a report file at the exact path specified
- **YOU WILL verify** all links after creating the file using this command: [...]
- **YOU SHALL include** these exact sections (additional sections are FORBIDDEN)
- **YOU MUST add** concrete code examples using this template: [...]
- **YOU WILL use** 2025 best practices (earlier practices are UNACCEPTABLE)
```

**Result**: Claude recognizes these as non-negotiable requirements and executes all steps.

---

## Transformation Rules

### Prohibited Words → Required Replacements

| Weak Language | Strength | Imperative Replacement | When to Use |
|---------------|----------|------------------------|-------------|
| should | Suggestive | **MUST** | Absolute requirements |
| may | Permissive | **WILL** or **SHALL** | Conditional requirements |
| can | Enabling | **MUST** or **SHALL** | Capability requirements |
| could | Possibility | **WILL** or **MAY** | Conditional actions |
| consider | Reflective | **MUST** or **SHALL** | Required evaluation |
| try to | Aspirational | **WILL** | Required attempt |
| might | Uncertainty | **WILL** if required, **MAY** if optional | Based on context |

### Imperative Verbs by Requirement Level

**Absolute Requirements** (no exceptions):
- **MUST**: Mandatory action, no alternatives
- **SHALL**: Formal requirement, specification-level
- **WILL**: Definite future action, guaranteed execution

**Conditional Requirements** (context-dependent):
- **WILL** (when condition met): "If tests fail, YOU WILL invoke debug loop"
- **SHALL** (when specified): "Phase files SHALL include complexity metadata"

**Optional Actions** (user choice):
- **MAY**: Permitted but not required
- Example: "You MAY add custom sections after required sections"

**Prohibited Actions** (explicitly forbidden):
- **MUST NOT**: Absolute prohibition
- **SHALL NOT**: Formal prohibition
- **FORBIDDEN**: Explicit constraint
- Example: "You MUST NOT modify files outside the topic directory"

---

## Application by File Type

### Commands (`.claude/commands/*.md`)

**Phase 0: Role Clarification**

Commands that orchestrate subagents MUST begin with explicit role clarification:

```markdown
# Command: /orchestrate

**YOUR ROLE**: You are the ORCHESTRATOR, not the executor.
- **YOU WILL** delegate tasks to subagents using the Task tool
- **YOU MUST NOT** execute tasks directly (like code writing, file operations)
- **YOU SHALL** pre-calculate artifact paths before invoking agents
- **YOU WILL** inject pre-calculated paths into all agent prompts
```

**Execution Instructions**

All execution steps use imperative language with verification:

```markdown
**STEP 1 (REQUIRED BEFORE STEP 2) - Calculate Artifact Paths**

**EXECUTE NOW**:

```bash
source .claude/lib/artifact-creation.sh
TOPIC_DIR=$(get_or_create_topic_dir "$DESCRIPTION")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research")
```

**MANDATORY VERIFICATION**:
```bash
if [ ! -d "$TOPIC_DIR" ]; then
  echo "❌ CRITICAL ERROR: Topic directory not created"
  exit 1
fi
echo "✓ VERIFIED: Topic directory exists: $TOPIC_DIR"
```

**YOU MUST NOT** proceed to Step 2 until verification passes.
```

**Agent Invocation Templates**

Agent prompts injected by commands use imperative language:

```markdown
**Agent Prompt Template** (Use THIS EXACT TEMPLATE, no modifications):

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [topic]"
  prompt: |
    **YOU MUST complete** this research task with the following requirements:

    **ABSOLUTE REQUIREMENTS** (all must be satisfied):
    1. **YOU WILL search** the codebase for existing patterns
    2. **YOU MUST create** a report file at this exact path: {REPORT_PATH}
    3. **YOU SHALL include** these exact sections: [list]
    4. **YOU WILL verify** file creation before returning

    **PRIMARY OBLIGATION**: File creation at the specified path is MANDATORY.

    **FORBIDDEN ACTIONS**:
    - Creating files in arbitrary locations
    - Skipping required sections
    - Returning before file verification
}
```
```

### Agents (`.claude/agents/*.md`)

**Role Declaration**

Agents begin with imperative role declaration:

```markdown
# Agent: research-specialist

**YOUR ROLE**: You are a research specialist agent.

**YOU MUST**:
- Execute the research task exactly as specified
- Create files at the paths provided by the orchestrator
- Verify all file operations before returning
- Return metadata in the exact format specified

**YOU MUST NOT**:
- Modify the task requirements
- Create files in arbitrary locations
- Skip verification steps
- Return incomplete or partial results
```

**Sequential Steps with Dependencies**

All steps use STEP format with explicit dependencies:

```markdown
## Execution Process

**STEP 1 (REQUIRED BEFORE STEP 2) - Validate Input**

**YOU MUST verify** all required inputs are present:
- Research topic: [provided by orchestrator]
- Report file path: [provided by orchestrator]
- Required sections: [provided by orchestrator]

**MANDATORY CHECK**:
```bash
if [ -z "$REPORT_PATH" ]; then
  echo "❌ ERROR: Report path not provided"
  exit 1
fi
```

**YOU MUST NOT** proceed to Step 2 until all inputs validated.

**STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**

**YOU WILL execute** these research methods IN THIS ORDER:
1. **YOU MUST search** codebase using Grep tool
2. **YOU SHALL analyze** findings for patterns
3. **YOU WILL extract** key insights (max 150 words)

**STEP 3 (REQUIRED BEFORE STEP 4) - Create Report File**

**YOU MUST create** the report file using the Write tool:

```markdown
Write {
  file_path: "{REPORT_PATH}"  # Use exact path provided
  content: "[Generated report content]"
}
```

**MANDATORY VERIFICATION**:
After file creation, **YOU WILL verify** using Read tool:
```markdown
Read {
  file_path: "{REPORT_PATH}"
}
```

If Read fails, **YOU MUST retry** file creation (max 3 attempts).

**STEP 4 (FINAL) - Return Metadata**

**YOU MUST return** this exact metadata structure (no modifications):
```yaml
completion_status: "success"
report_path: "{REPORT_PATH}"
summary: "[50-word summary]"
key_findings: ["finding1", "finding2", "finding3"]
```
```

---

## Enforcement Patterns

### Pattern 1: Direct Execution Blocks

**Use "EXECUTE NOW" markers** for critical operations:

```markdown
**EXECUTE NOW - Create Directory Structure**

Run this code block IMMEDIATELY:

```bash
mkdir -p "$TOPIC_DIR/"{reports,plans,summaries,debug}
chmod 755 "$TOPIC_DIR"
```

**VERIFICATION REQUIRED**:
```bash
for subdir in reports plans summaries debug; do
  if [ ! -d "$TOPIC_DIR/$subdir" ]; then
    echo "❌ ERROR: $subdir not created"
    exit 1
  fi
done
echo "✓ All subdirectories created"
```
```

### Pattern 2: Mandatory Verification Blocks

**Use "MANDATORY VERIFICATION" after all file operations**:

```markdown
**MANDATORY VERIFICATION - Confirm File Exists**

**YOU MUST run** this verification BEFORE proceeding:

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ CRITICAL: Report file not created at $REPORT_PATH"

  # FALLBACK MECHANISM (execute if verification fails)
  echo "Creating minimal report file as fallback..."
  echo "# Research Report" > "$REPORT_PATH"
  echo "Status: Incomplete - manual review required" >> "$REPORT_PATH"

  # Verify fallback succeeded
  if [ ! -f "$REPORT_PATH" ]; then
    echo "❌ FATAL: Fallback creation failed"
    exit 1
  fi
  echo "⚠ Fallback file created - needs enhancement"
fi

echo "✓ VERIFIED: Report file exists at $REPORT_PATH"
```

**YOU MUST NOT** proceed until verification confirms file existence.
```

### Pattern 3: Fallback Mechanisms

**Use fallback mechanisms** for 100% file creation guarantee:

```markdown
**PRIMARY ATTEMPT**: Create report using agent

**FALLBACK MECHANISM** (if primary fails):
1. **YOU WILL create** minimal report file directly
2. **YOU SHALL populate** with basic structure
3. **YOU MUST mark** as incomplete for manual review
4. **YOU WILL log** failure reason for debugging

**GUARANTEE**: File WILL exist at specified path, even if minimal/incomplete.
```

### Pattern 4: Checkpoint Reporting

**Use "CHECKPOINT REQUIREMENT" after major phases**:

```markdown
**CHECKPOINT REQUIREMENT - Report Phase Completion**

After completing this phase, **YOU MUST report**:

```
CHECKPOINT: Research Phase Complete
- Reports created: N/N (100% success rate)
- Verification: ✓ All files verified at correct paths
- Fallback invoked: [Yes|No]
- Status: READY FOR NEXT PHASE
```

**THIS CHECKPOINT IS MANDATORY** and confirms successful phase completion.
```

---

## Testing Validation

### Audit Imperative Language Usage

**Validation Script** (`.claude/lib/audit-imperative-language.sh`):

```bash
#!/bin/bash
# Audit file for imperative language compliance

FILE="$1"

# Count weak language occurrences
SHOULD_COUNT=$(grep -i "should" "$FILE" | grep -v "# " | wc -l)
MAY_COUNT=$(grep -i "\bmay\b" "$FILE" | grep -v "# " | wc -l)
CAN_COUNT=$(grep -i "\bcan\b" "$FILE" | grep -v "# " | wc -l)
CONSIDER_COUNT=$(grep -i "consider" "$FILE" | wc -l)
TRY_COUNT=$(grep -i "try to" "$FILE" | wc -l)

# Count imperative language occurrences
MUST_COUNT=$(grep -i "MUST" "$FILE" | wc -l)
WILL_COUNT=$(grep -i "WILL" "$FILE" | wc -l)
SHALL_COUNT=$(grep -i "SHALL" "$FILE" | wc -l)

# Calculate scores
WEAK_TOTAL=$((SHOULD_COUNT + MAY_COUNT + CAN_COUNT + CONSIDER_COUNT + TRY_COUNT))
IMPERATIVE_TOTAL=$((MUST_COUNT + WILL_COUNT + SHALL_COUNT))

# Imperative ratio (target: >90%)
if [ $((IMPERATIVE_TOTAL + WEAK_TOTAL)) -gt 0 ]; then
  IMPERATIVE_RATIO=$((IMPERATIVE_TOTAL * 100 / (IMPERATIVE_TOTAL + WEAK_TOTAL)))
else
  IMPERATIVE_RATIO=0
fi

echo "=== Imperative Language Audit ==="
echo "File: $FILE"
echo ""
echo "Weak Language (should be eliminated):"
echo "  should: $SHOULD_COUNT"
echo "  may: $MAY_COUNT"
echo "  can: $CAN_COUNT"
echo "  consider: $CONSIDER_COUNT"
echo "  try to: $TRY_COUNT"
echo "  TOTAL WEAK: $WEAK_TOTAL"
echo ""
echo "Imperative Language (required):"
echo "  MUST: $MUST_COUNT"
echo "  WILL: $WILL_COUNT"
echo "  SHALL: $SHALL_COUNT"
echo "  TOTAL IMPERATIVE: $IMPERATIVE_TOTAL"
echo ""
echo "Imperative Ratio: ${IMPERATIVE_RATIO}%"
echo ""

if [ $IMPERATIVE_RATIO -ge 90 ]; then
  echo "✓ PASS: Imperative language usage is excellent"
  exit 0
elif [ $IMPERATIVE_RATIO -ge 70 ]; then
  echo "⚠ WARNING: Imperative language usage needs improvement"
  exit 1
else
  echo "❌ FAIL: Too much weak language, migration required"
  exit 2
fi
```

**Usage**:
```bash
bash .claude/lib/audit-imperative-language.sh .claude/commands/orchestrate.md
```

**Expected Results**:
- Imperative ratio ≥90%: Excellent enforcement
- Imperative ratio 70-89%: Needs improvement
- Imperative ratio <70%: Requires migration

---

## Common Pitfalls

### Pitfall 1: Mixing Descriptive and Imperative Text

**Problem**: Alternating between explaining and commanding confuses execution flow.

**Bad Example**:
```markdown
The research phase involves gathering information from multiple sources.
You should use the Grep tool to search the codebase.
After finding patterns, create a report summarizing the findings.
```

**Good Example**:
```markdown
**RESEARCH PHASE EXECUTION**

**STEP 1 - Search Codebase**
**YOU MUST use** the Grep tool to search for existing patterns:
```
Grep { pattern: "[search term]", path: ".", output_mode: "content" }
```

**STEP 2 - Create Report**
**YOU WILL create** a report file using the Write tool:
```
Write { file_path: "{REPORT_PATH}", content: "[summary]" }
```
```

### Pitfall 2: Implicit Requirements

**Problem**: Assuming Claude knows requirements without stating them explicitly.

**Bad Example**:
```markdown
Create the report file.
```

**Good Example**:
```markdown
**YOU MUST create** the report file at this EXACT path: {REPORT_PATH}

**REQUIREMENTS** (all mandatory):
- Path: MUST use the pre-calculated path (no arbitrary locations)
- Format: MUST use markdown with ## headings
- Sections: MUST include all required sections (no omissions)
- Verification: MUST verify file exists after creation
```

### Pitfall 3: Weak Verification Language

**Problem**: Using "check" or "ensure" instead of mandatory verification.

**Bad Example**:
```markdown
Check that the file was created successfully.
```

**Good Example**:
```markdown
**MANDATORY VERIFICATION - File Creation**

**YOU MUST verify** file existence using this exact code:

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ CRITICAL ERROR: File not created"
  exit 1
fi
echo "✓ VERIFIED: File exists"
```

**YOU MUST NOT** proceed until verification passes.
```

### Pitfall 4: Optional-Sounding Required Actions

**Problem**: Phrasing requirements as suggestions or possibilities.

**Bad Example**:
```markdown
You might want to include examples in your report.
Consider adding cross-references to related documents.
```

**Good Example**:
```markdown
**YOU MUST include** at least 3 code examples in your report.
**YOU SHALL add** cross-references to these related documents: [list]

**FORBIDDEN**: Reports without examples or cross-references are UNACCEPTABLE.
```

---

## Quick Reference

### Imperative Language Checklist

Before finalizing a command or agent file, verify:

- [ ] All execution steps use MUST/WILL/SHALL (not should/may/can)
- [ ] All file operations have MANDATORY VERIFICATION blocks
- [ ] All critical code blocks have "EXECUTE NOW" markers
- [ ] All sequential steps have "REQUIRED BEFORE" dependencies
- [ ] All phase completions have CHECKPOINT REQUIREMENT reporting
- [ ] All fallback mechanisms use imperative language
- [ ] All prohibited actions use MUST NOT/FORBIDDEN
- [ ] Descriptive text is separated from execution instructions
- [ ] Agent invocation templates use "THIS EXACT TEMPLATE"
- [ ] Role clarifications use "YOU are the ORCHESTRATOR/EXECUTOR"

### Language Strength Hierarchy

**Strongest → Weakest**:
1. **MUST** / **SHALL** - Absolute requirements
2. **WILL** - Definite future actions
3. **MAY** - Explicit permissions (optional)
4. ~~should~~ - Prohibited (suggests optionality)
5. ~~may~~ - Prohibited (implies optionality)
6. ~~can~~ - Prohibited (unclear requirement)
7. ~~consider~~ - Prohibited (too weak)

**Rule**: Use only levels 1-3. Levels 4-7 are prohibited in execution instructions.

---

## Related Documentation

- [Standard 0: Execution Enforcement](../reference/command_architecture_standards.md#standard-0-execution-enforcement-new) - Architectural standard defining enforcement patterns
- [Execution Enforcement Migration Guide](execution-enforcement-migration-guide.md) - Complete migration process for existing files
- [Enforcement Patterns](enforcement-patterns.md) - Reusable templates from reference models
- [Verification-Fallback Pattern](../concepts/patterns/verification-fallback.md) - 100% file creation guarantee
- [Migration Validation Guide](migration-validation.md) - How to verify enforcement compliance

---

## Examples

### Example 1: Command with Full Imperative Language

See: `.claude/commands/report.md` (audit score: 105/100)

**Highlights**:
- Phase 0 role clarification: "YOU are the ORCHESTRATOR"
- All steps use STEP format with REQUIRED BEFORE dependencies
- All file operations have MANDATORY VERIFICATION
- All agent prompts use "THIS EXACT TEMPLATE"
- All fallback mechanisms guarantee file creation

### Example 2: Agent with Full Imperative Language

See: `.claude/agents/research-specialist.md` (audit score: 110/100)

**Highlights**:
- Role declaration: "YOU MUST execute the research task"
- Sequential steps: "STEP N (REQUIRED BEFORE STEP N+1)"
- Zero passive voice: All "should" → "MUST"
- Template enforcement: "YOUR REPORT MUST contain these sections"
- Completion criteria: "ALL REQUIRED sections MUST be present"

### Example 3: Before/After Transformation

**Before** (weak language, audit score: 45/100):
```markdown
The agent should search the codebase for patterns. After finding results,
you may create a report in the appropriate directory. Consider including
examples if relevant. Try to verify the file was created successfully.
```

**After** (imperative language, audit score: 95/100):
```markdown
**STEP 1 (REQUIRED BEFORE STEP 2) - Search Codebase**

**YOU MUST search** the codebase using the Grep tool:
```
Grep { pattern: "[term]", path: ".", output_mode: "content" }
```

**STEP 2 (REQUIRED BEFORE STEP 3) - Create Report**

**YOU WILL create** a report file at this EXACT path: {REPORT_PATH}

**MANDATORY**: The report MUST include code examples (minimum 3).

**STEP 3 (FINAL) - Verify File Creation**

**YOU MUST verify** file existence:
```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "❌ CRITICAL: File creation failed"
  exit 1
fi
echo "✓ VERIFIED: Report exists at $REPORT_PATH"
```
```

---

## Summary

**Core Requirement**: All commands and agents MUST use imperative language (MUST/WILL/SHALL) for required actions. Weak language (should/may/can) is prohibited in execution instructions.

**Validation**: Imperative ratio ≥90% required for compliance.

**Result**: 100% file creation rates, predictable execution, zero ambiguity in requirements.

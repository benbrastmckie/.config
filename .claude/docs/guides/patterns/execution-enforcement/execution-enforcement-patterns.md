# Execution Enforcement: Language Patterns

**Related Documents**:
- [Overview](execution-enforcement-overview.md) - Introduction and standards
- [Migration](execution-enforcement-migration.md) - Migration process
- [Validation](execution-enforcement-validation.md) - Validation and troubleshooting

---

## Imperative Language Rules

### Replace Passive Voice

```markdown
# Before (Passive - Implies optionality)
"Reports should be created in topic directories."
"Links should be verified after file creation."

# After (Active - Mandatory)
"YOU MUST create reports in topic directories."
"YOU WILL verify all links after creating the file."
```

### Replace Optional Language

```markdown
# Before (Optional)
"You should create a report file."
"You may include additional sections."
"You can emit progress markers."

# After (Mandatory)
"YOU MUST create a report file."
"YOU WILL include these exact sections."
"YOU SHALL emit progress markers."
```

### Use Explicit Directives

```markdown
# Before (Vague)
"Complete the research task and return findings."

# After (Explicit)
**COMPLETION CRITERIA - ALL REQUIRED**:
- [x] Report file exists at exact path
- [x] Report contains all mandatory sections
- [x] All internal links verified
- [x] Checkpoint confirmation emitted
- [x] File path returned in format: "CREATED: /path/to/file.md"
```

## Enforcement Patterns

### Pattern 1: Direct Execution Blocks

Mark critical operations with explicit markers:

```markdown
**EXECUTE NOW - Calculate Report Paths**

Run this code block BEFORE invoking agents:

```bash
REPORT_PATH="${TOPIC_DIR}/reports/${TOPIC_SLUG}.md"
echo "Report will be written to: $REPORT_PATH"
```

**Verification**: Confirm path calculated before continuing.
```

### Pattern 2: Mandatory Verification

Add explicit verification that Claude MUST execute:

```markdown
**MANDATORY VERIFICATION - Report File Existence**

After creating report, YOU MUST execute this verification:

```bash
if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL: Report not created at $REPORT_PATH"
  exit 1
fi

echo "Verified: $REPORT_PATH"
```

**REQUIREMENT**: This verification is NOT optional.
```

### Pattern 3: Template Enforcement

Specify non-negotiable output formats:

```markdown
**OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)**

YOUR REPORT MUST contain these sections IN THIS ORDER:

# [Title]

## Overview
[REQUIRED - 2-3 sentences]

## Findings
[REQUIRED - Minimum 5 bullet points]

## Recommendations
[REQUIRED - Minimum 3 items]

**ENFORCEMENT**: Every REQUIRED section is NON-NEGOTIABLE.
```

### Pattern 4: Sequential Dependencies

Enforce step ordering:

```markdown
**STEP 1 (REQUIRED BEFORE STEP 2)** - Pre-Calculate Path

EXECUTE NOW - Calculate the exact file path.

**VERIFICATION**: Path must be absolute.

**STEP 2 (REQUIRED BEFORE STEP 3)** - Conduct Research

YOU MUST investigate using Grep, Glob, and Read.

**STEP 3 (ABSOLUTE REQUIREMENT)** - Create Report

**THIS IS NON-NEGOTIABLE**: File creation MUST occur.

**STEP 4 (MANDATORY VERIFICATION)** - Verify Creation

```bash
test -f "$REPORT_PATH" || echo "CRITICAL: Not created"
```
```

### Pattern 5: Primary Obligation

Elevate file creation to highest priority:

```markdown
**PRIMARY OBLIGATION - File Creation**

**ABSOLUTE REQUIREMENT**: Creating the output file is your PRIMARY task.

**PRIORITY ORDER**:
1. FIRST: Create output file (even if empty initially)
2. SECOND: Conduct research and populate file
3. THIRD: Verify file exists with required sections
4. FOURTH: Return confirmation

**WHY THIS MATTERS**: Commands depend on file artifacts at predictable paths.
```

### Pattern 6: Checkpoint Reporting

Require explicit completion reporting:

```markdown
**CHECKPOINT REQUIREMENT**

After completing each major step, report status:

```
CHECKPOINT: Research phase complete
- Topics researched: 3
- Reports created: 3
- All files verified: yes
- Proceeding to: Planning phase
```

This reporting is MANDATORY.
```

## Anti-Patterns

### Anti-Pattern 1: Optional Language

```markdown
# BAD
"You should create a report file."

# GOOD
"YOU MUST create a report file."
```

### Anti-Pattern 2: Vague Completion

```markdown
# BAD
"Complete the task and return findings."

# GOOD
**COMPLETION CRITERIA - ALL REQUIRED**:
- [x] File created
- [x] Sections present
- [x] Signal returned
```

### Anti-Pattern 3: Missing Rationale

```markdown
# BAD
"Create the report at the specified path."

# GOOD
"Create the report at the specified path.

**WHY THIS MATTERS**:
- Commands rely on predictable paths
- Metadata extraction depends on structure
- Text summaries break workflow dependencies"
```

### Anti-Pattern 4: No Fallback

```markdown
# BAD
RESULT=$(invoke_agent)
use_result "$RESULT"

# GOOD
RESULT=$(invoke_agent)
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  # Fallback logic
fi
use_result "$RESULT"
```

## Why This Matters

Include rationale for enforcement:

```markdown
**WHY THIS MATTERS**:
- Commands rely on artifacts at predictable paths
- Metadata extraction depends on file structure
- Plan execution needs cross-references
- Text-only summaries break dependency graph

**CONSEQUENCE OF NON-COMPLIANCE**:
If you return findings as text instead of creating file, the calling command will execute fallback creation, but your detailed analysis will be reduced to basic templated content.
```

## Common Transformations

### Task List to Dependencies

```markdown
# Before
Tasks:
- Research patterns
- Analyze findings
- Write report
- Return summary

# After
**STEP 1**: Research patterns
**STEP 2 (DEPENDS ON 1)**: Analyze findings
**STEP 3 (DEPENDS ON 2)**: Write report
**STEP 4 (DEPENDS ON 3)**: Return summary
```

### Suggestion to Requirement

```markdown
# Before
Consider adding examples for clarity.

# After
YOU MUST add concrete examples using this template.
```

---

## Related Documentation

- [Overview](execution-enforcement-overview.md)
- [Migration](execution-enforcement-migration.md)
- [Validation](execution-enforcement-validation.md)

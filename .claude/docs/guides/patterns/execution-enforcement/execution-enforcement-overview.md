# Execution Enforcement: Overview

**Related Documents**:
- [Language Patterns](execution-enforcement-patterns.md) - Imperative language and enforcement
- [Migration](execution-enforcement-migration.md) - Migration process
- [Validation](execution-enforcement-validation.md) - Validation and troubleshooting

---

## Purpose

This guide provides comprehensive documentation for creating and migrating commands and agents to use execution enforcement patterns. These patterns achieve:
- **100% file creation rates** (vs 60-80% without enforcement)
- **Predictable execution** (mandatory step compliance)
- **Reliable verification** (explicit checkpoints)
- **Consistent outputs** (standardized formats)

## Agent vs Command Patterns

**IMPORTANT CONTEXT**: This guide shows both agent behavioral patterns (for agent files) and command structural patterns (for command files).

| Section | Applies To | File Location | Purpose |
|---------|-----------|---------------|---------|
| STEP Dependencies | Agent files | `.claude/agents/*.md` | Agent behavioral guidelines |
| Execution Blocks | Command files | `.claude/commands/*.md` | Command structural patterns |
| File-First Creation | Agent files | `.claude/agents/*.md` | Agent workflow procedures |
| Verification Checkpoints | Command files | `.claude/commands/*.md` | Orchestrator responsibilities |

**Key Distinction**:
- **Agent behavioral patterns** belong in `.claude/agents/*.md` files
- **Command structural patterns** belong in `.claude/commands/*.md` files
- Commands reference agent files via behavioral injection, do not duplicate

## What Is Execution Enforcement?

Execution enforcement transforms optional, descriptive guidance into mandatory, executable directives.

### Before (Descriptive)

```markdown
You should create a report file after completing the research.
```

### After (Imperative)

```markdown
**STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File**

**EXECUTE NOW - Create Report File**

YOU MUST use the Write tool to create the report file at the exact path.

**THIS IS NON-NEGOTIABLE**: File creation MUST occur even if research findings are minimal.
```

## Standards 0 and 0.5

### Standard 0: Execution Enforcement

**Problem**: Command files contain behavioral instructions that Claude may interpret loosely, skip steps, or simplify critical procedures.

**Solution**: Use specific linguistic patterns and verification checkpoints.

**Key Patterns**:
1. Direct Execution Blocks ("EXECUTE NOW")
2. Mandatory Verification Checkpoints
3. Non-Negotiable Agent Prompts
4. Checkpoint Reporting

### Standard 0.5: Subagent Prompt Enforcement

**Extension for Agent Definition Files**

**Problem**: Agent files use descriptive language ("I am a specialized agent") that Claude treats as guidance rather than mandatory directives.

**Solution**: Agent-specific enforcement patterns:
1. Role Declaration Transformation
2. Sequential Step Dependencies
3. File Creation as Primary Obligation
4. Template-Based Output Enforcement

## Language Strength Hierarchy

| Strength | Pattern | When to Use |
|----------|---------|-------------|
| **Critical** | "CRITICAL:", "ABSOLUTE REQUIREMENT" | Safety, data integrity |
| **Mandatory** | "YOU MUST", "REQUIRED", "EXECUTE NOW" | Essential steps |
| **Strong** | "Always", "Never", "Ensure" | Best practices |
| **Standard** | "Should", "Recommended" | Preferences |
| **Optional** | "May", "Can", "Consider" | Alternatives |

**Rule**: Critical operations require Critical/Mandatory strength.

## Key Transformations

### Role Declarations

```markdown
# Before
I am a specialized agent focused on research.

# After
**YOU MUST perform these exact steps in sequence.**
**PRIMARY OBLIGATION**: File creation is NOT optional.
```

### Step Sequences

```markdown
# Before
1. Analyze topic
2. Research patterns
3. Create report

# After
**STEP 1 (REQUIRED BEFORE STEP 2)** - Analyze Topic
[instructions]
**VERIFICATION**: Topic analyzed

**STEP 2 (REQUIRED BEFORE STEP 3)** - Research Patterns
[instructions]

**STEP 3 (ABSOLUTE REQUIREMENT)** - Create Report
**EXECUTE NOW**: Create report at exact path
**THIS IS NON-NEGOTIABLE**
```

### Output Requirements

```markdown
# Before
Include an overview section in your report.

# After
**OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)**

## Overview
[REQUIRED - 2-3 sentences summary]

**ENFORCEMENT**: Sections marked REQUIRED are NON-NEGOTIABLE.
```

## Expected Results

### Before Enforcement

- File creation rate: 60-80%
- Step compliance: Variable
- Output format: Inconsistent

### After Enforcement

- File creation rate: 100%
- Step compliance: 100%
- Output format: Consistent

## Quality Metrics

Target: All agents achieve 95+/100 on enforcement checklist.

**Scoring Rubric** (10 points per category):
1. Imperative Language (10 pts)
2. Sequential Dependencies (10 pts)
3. File Creation Priority (10 pts)
4. Verification Checkpoints (10 pts)
5. Template Enforcement (10 pts)
6. Passive Voice Elimination (10 pts)
7. Completion Criteria (10 pts)
8. Why This Matters Context (10 pts)
9. Checkpoint Reporting (10 pts)
10. Fallback Integration (10 pts)

---

## Related Documentation

- [Language Patterns](execution-enforcement-patterns.md)
- [Migration](execution-enforcement-migration.md)
- [Validation](execution-enforcement-validation.md)
- [Architecture Standards](../reference/architecture/validation.md)

# Architecture Standards: Execution Enforcement and Validation

**Related Documents**:
- [Overview](overview.md) - Standards index and fundamentals
- [Error Handling](error-handling.md) - Library sourcing, return codes
- [Dependencies](dependencies.md) - Content separation patterns

---

## Standard 0: Execution Enforcement

**Problem**: Command files contain behavioral instructions that Claude may interpret loosely, skip steps, or simplify critical procedures, leading to incomplete execution.

**Solution**: Distinguish between descriptive documentation and mandatory execution directives using specific linguistic patterns and verification checkpoints.

**Complete Guide**: See [Imperative Language Guide](../archive/guides/patterns/execution-enforcement/execution-enforcement-overview.md) for comprehensive usage patterns, transformation rules, and validation techniques.

**Robustness Patterns**: Apply systematic patterns for reliable command development - See [Robustness Framework](../concepts/robustness-framework.md) for unified pattern index with validation methods.

### Imperative vs Descriptive Language

**Descriptive Language** (Explains what happens):
```markdown
BAD - Descriptive, easily skipped:
"The research phase invokes parallel agents to gather information."
"Reports are created in topic directories."
"Agents return file paths for verification."
```

**Imperative Language** (Commands what MUST happen):
```markdown
GOOD - Imperative, enforceable:
"YOU MUST invoke research agents in this exact sequence:"
"EXECUTE NOW: Create topic directory using this code block:"
"MANDATORY: Verify file existence before proceeding:"
```

### Enforcement Patterns

#### Pattern 1: Direct Execution Blocks

Use explicit "EXECUTE NOW" markers for critical operations:

```markdown
**EXECUTE NOW - Calculate Report Paths**

Run this code block BEFORE invoking agents:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"
WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")

declare -A REPORT_PATHS
for topic in "${TOPICS[@]}"; do
  REPORT_PATH=$(create_topic_artifact "$WORKFLOW_TOPIC_DIR" "reports" "${topic}" "")
  REPORT_PATHS["$topic"]="$REPORT_PATH"
  echo "Pre-calculated path: $REPORT_PATH"
done
```

**Verification**: Confirm paths calculated for all topics before continuing.
```

#### Pattern 2: Mandatory Verification Checkpoints

Add explicit verification that Claude MUST execute:

```markdown
**MANDATORY VERIFICATION - Report File Existence**

After agents complete, YOU MUST execute this verification:

```bash
for topic in "${!REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${REPORT_PATHS[$topic]}"

  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "CRITICAL: Report missing at $EXPECTED_PATH"
    echo "Executing fallback creation..."

    # Fallback: Create from agent output
    cat > "$EXPECTED_PATH" <<EOF
# ${topic}
## Findings
${AGENT_OUTPUT[$topic]}
EOF
  fi

  echo "Verified: $EXPECTED_PATH"
done
```

**REQUIREMENT**: This verification is NOT optional. Execute it exactly as shown.
```

#### Pattern 3: Non-Negotiable Agent Prompts

When agent prompts are critical, use "THIS EXACT TEMPLATE" enforcement:

```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE (No modifications)**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    **STEP 1: CREATE FILE** (Do this FIRST, before research)
    Use Write tool to create: ${REPORT_PATHS[$TOPIC]}

    **STEP 2: RESEARCH**
    [research instructions]

    **STEP 3: RETURN CONFIRMATION**
    Return ONLY: REPORT_CREATED: ${REPORT_PATHS[$TOPIC]}

    **CRITICAL**: DO NOT return summary text. File creation is MANDATORY.
  "
}
```

**ENFORCEMENT**: Copy this template verbatim. Do NOT simplify or paraphrase the prompt.
```

#### Pattern 4: Checkpoint Reporting

Require explicit completion reporting:

```markdown
**CHECKPOINT REQUIREMENT**

After completing each major step, report status:

```
CHECKPOINT: Research phase complete
- Topics researched: ${#TOPICS[@]}
- Reports created: ${#VERIFIED_REPORTS[@]}
- All files verified: yes
- Proceeding to: Planning phase
```

This reporting is MANDATORY and confirms proper execution.
```

### Language Strength Hierarchy

Use appropriate strength for different situations:

| Strength | Pattern | When to Use | Example |
|----------|---------|-------------|---------|
| **Critical** | "CRITICAL:", "ABSOLUTE REQUIREMENT" | Safety, data integrity | File creation enforcement |
| **Mandatory** | "YOU MUST", "REQUIRED", "EXECUTE NOW" | Essential steps | Path pre-calculation |
| **Strong** | "Always", "Never", "Ensure" | Best practices | Error handling |
| **Standard** | "Should", "Recommended" | Preferences | Optimization hints |
| **Optional** | "May", "Can", "Consider" | Alternatives | Advanced features |

**Rule**: Critical operations (file creation, data persistence, security) require Critical/Mandatory strength.

### Fallback Mechanism Requirements

When commands depend on agent compliance, include fallback mechanisms:

**Required Structure**:
```markdown
### Agent Execution with Fallback

**Primary Path**: Agent follows instructions and creates output
**Fallback Path**: Command creates output from agent response if agent doesn't comply

**Implementation**:
1. Invoke agent with explicit file creation directive
2. Verify expected output exists
3. If missing: Create from agent's text output
4. Guarantee: Output exists regardless of agent behavior
```

**When Fallbacks Required**:
- Agent file creation (reports, plans, documentation)
- Agent structured output parsing
- Agent artifact organization
- Cross-agent coordination
- NOT needed for read-only operations
- NOT needed for tool-based operations (Write/Edit directly)

### Phase 0: Orchestrator vs Executor Role Clarification

**Problem**: Multi-agent commands that invoke other slash commands create architectural violations:
- Commands calling other commands
- Loss of artifact path control
- Context bloat
- Recursion risk

**Solution**: Distinguish between orchestrator and executor roles:

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths (topic-based organization)
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)

### Relationship to Fail-Fast Policy

Standard 0's Verification and Fallback Pattern implements fail-fast error detection, NOT fail-fast violation. The critical distinction lies in whether fallbacks DETECT errors or HIDE errors.

**How Verification Fallbacks Implement Fail-Fast**:

1. **Error Detection (Fail-Fast)**: MANDATORY VERIFICATION exposes file creation failures immediately
2. **Agent Responsibility**: Agents must create their own artifacts
3. **Fail-Fast on Verification Failure**: Missing files terminate workflow immediately

**Critical Distinction**:
- **Bootstrap fallbacks**: HIDE configuration errors - PROHIBITED (fail-fast violation)
- **Verification fallbacks**: DETECT tool failures - REQUIRED for observability
- **Orchestrator placeholder creation**: HIDES agent failures - PROHIBITED (fail-fast violation)

---

## Standard 0.5: Subagent Prompt Enforcement

**Extension of Standard 0 for Agent Definition Files**

Subagent prompts in `.claude/agents/` follow the same enforcement principles as command files, with additional patterns specific to agent behavior and file creation guarantees.

### Problem Statement

Agent definition files historically used descriptive language ("I am a specialized agent") that Claude treats as guidance rather than mandatory directives. This leads to:
- Variable file creation rates (60-80% vs 100% target)
- Optional interpretation of verification steps
- Skipped checkpoint reporting
- Passive voice that implies optionality

### Solution: Agent-Specific Enforcement Patterns

#### Pattern A: Role Declaration Transformation

Replace descriptive "I am" declarations with imperative "YOU MUST" directives:

```markdown
BAD - Descriptive language:
## Research Specialist Agent

I am a specialized agent focused on thorough research and analysis.

GOOD - Imperative enforcement:
## Research Specialist Agent

**YOU MUST perform these exact steps in sequence:**

**ROLE**: You are a research specialist with ABSOLUTE REQUIREMENT to create structured report files.

**PRIMARY OBLIGATION**: File creation is NOT optional.
```

#### Pattern B: Sequential Step Dependencies

Enforce step ordering with explicit dependencies:

```markdown
**STEP 1 (REQUIRED BEFORE STEP 2) - Pre-Calculate Report Path**

EXECUTE NOW - Calculate the exact file path where you will write the report.

**STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**

YOU MUST investigate the codebase using Grep, Glob, and Read tools.

**STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File**

**THIS IS NON-NEGOTIABLE**: File creation MUST occur even if research findings are minimal.

**STEP 4 (MANDATORY VERIFICATION) - Verify File Creation**

After creating the report, YOU MUST verify.
```

#### Pattern C: File Creation as Primary Obligation

Elevate file creation to the highest priority:

```markdown
**PRIMARY OBLIGATION - File Creation**

**PRIORITY ORDER**:
1. FIRST: Create output file at specified path (even if empty initially)
2. SECOND: Conduct research and populate file
3. THIRD: Verify file exists and contains all required sections
4. FOURTH: Return confirmation of file creation

**WHY THIS MATTERS**: Commands depend on file artifacts existing at predictable paths.
```

#### Pattern D: Elimination of Passive Voice

Replace passive constructions with active imperatives:

```markdown
BAD - Passive voice (implies optionality):
"Reports should be created in topic directories."
"Links should be verified after file creation."

GOOD - Active imperatives:
"YOU MUST create reports in topic directories using this exact path structure:"
"YOU WILL verify all links after creating the file using this command:"
```

#### Pattern E: Template-Based Output Enforcement

Specify non-negotiable output formats:

```markdown
**OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)**

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
```

**ENFORCEMENT**: Every section marked REQUIRED or MANDATORY is NON-NEGOTIABLE.
```

### Agent-Specific Anti-Patterns

**Anti-Pattern A1: Optional Language**
- BAD: "You should create a report file."
- GOOD: "YOU MUST create a report file."

**Anti-Pattern A2: Vague Completion Criteria**
- BAD: "Complete the research task and return findings."
- GOOD: Explicit checklist with ALL REQUIRED marker

**Anti-Pattern A3: Missing "Why This Matters" Context**
- BAD: "Create the report file at the specified path."
- GOOD: Include enforcement rationale

### Quality Metrics

**Target**: All priority agents achieve 95+/100 on enforcement checklist

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

- [Architecture Standards Overview](overview.md)
- [Error Handling Standards](error-handling.md)
- [Testing Standards](testing.md)
- [Integration Patterns](integration.md)

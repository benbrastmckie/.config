# Command and Agent Architecture Standards

**Document Type**: Architecture Standards
**Scope**: All files in `.claude/commands/` and `.claude/agents/`
**Status**: ACTIVE - Must be followed for all modifications
**Last Updated**: 2025-10-16
**Derived From**: Refactoring damage analysis (commit 40b9146)

---

## Purpose

This document establishes architectural standards for Claude Code command and agent files to ensure they remain **directly executable by Claude** while avoiding code duplication and maintaining clear organization.

**Key Principle**: Command and agent files are **AI prompts that drive execution**, not traditional software code. Refactoring patterns that work for code may break AI execution.

---

## Fundamental Understanding

### Command Files Are AI Execution Scripts

**What Command Files Are**:
- Step-by-step execution instructions that Claude reads and follows
- Direct tool invocation patterns with specific parameters
- Decision flowcharts that guide AI behavior
- Critical warnings and constraints that must be visible during execution
- Inline templates for agent prompts, JSON structures, and bash commands

**What Command Files Are NOT**:
- Traditional software that can be refactored using standard DRY principles
- Documentation that can be replaced with links to external references
- Code that can delegate implementation details to imported modules
- Static reference material that users read linearly

### Why External References Don't Work for Execution

When Claude executes a command:
1. User invokes `/commandname "task description"`
2. Claude loads `.claude/commands/commandname.md` into working context
3. Claude **immediately** needs to see execution steps, tool calls, parameters
4. Claude **cannot effectively** load and process multiple external files mid-execution
5. Context switches to external files break execution flow and lose state

**Analogy**: A command file is like a cooking recipe. You can't replace the instructions with "See cookbook on shelf for how to cook this" - the instructions must be present when you need them.

---

## Core Standards

### Standard 0: Execution Enforcement (NEW)

**Problem**: Command files contain behavioral instructions that Claude may interpret loosely, skip steps, or simplify critical procedures, leading to incomplete execution.

**Solution**: Distinguish between descriptive documentation and mandatory execution directives using specific linguistic patterns and verification checkpoints.

**Complete Guide**: See [Imperative Language Guide](../guides/imperative-language-guide.md) for comprehensive usage patterns, transformation rules, and validation techniques.

#### Imperative vs Descriptive Language

**Descriptive Language** (Explains what happens):
```markdown
❌ BAD - Descriptive, easily skipped:
"The research phase invokes parallel agents to gather information."
"Reports are created in topic directories."
"Agents return file paths for verification."
```

**Imperative Language** (Commands what MUST happen):
```markdown
✅ GOOD - Imperative, enforceable:
"YOU MUST invoke research agents in this exact sequence:"
"EXECUTE NOW: Create topic directory using this code block:"
"MANDATORY: Verify file existence before proceeding:"
```

#### Enforcement Patterns

**Pattern 1: Direct Execution Blocks**

Use explicit "EXECUTE NOW" markers for critical operations:

```markdown
**EXECUTE NOW - Calculate Report Paths**

Run this code block BEFORE invoking agents:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
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

**Pattern 2: Mandatory Verification Checkpoints**

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

  echo "✓ Verified: $EXPECTED_PATH"
done
```

**REQUIREMENT**: This verification is NOT optional. Execute it exactly as shown.
```

**Pattern 3: Non-Negotiable Agent Prompts**

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

**Pattern 4: Checkpoint Reporting**

Require explicit completion reporting:

```markdown
**CHECKPOINT REQUIREMENT**

After completing each major step, report status:

```
CHECKPOINT: Research phase complete
- Topics researched: ${#TOPICS[@]}
- Reports created: ${#VERIFIED_REPORTS[@]}
- All files verified: ✓
- Proceeding to: Planning phase
```

This reporting is MANDATORY and confirms proper execution.
```

#### Language Strength Hierarchy

Use appropriate strength for different situations:

| Strength | Pattern | When to Use | Example |
|----------|---------|-------------|---------|
| **Critical** | "CRITICAL:", "ABSOLUTE REQUIREMENT" | Safety, data integrity | File creation enforcement |
| **Mandatory** | "YOU MUST", "REQUIRED", "EXECUTE NOW" | Essential steps | Path pre-calculation |
| **Strong** | "Always", "Never", "Ensure" | Best practices | Error handling |
| **Standard** | "Should", "Recommended" | Preferences | Optimization hints |
| **Optional** | "May", "Can", "Consider" | Alternatives | Advanced features |

**Rule**: Critical operations (file creation, data persistence, security) require Critical/Mandatory strength.

#### Fallback Mechanism Requirements

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

**Example**:
```bash
# After agent completes
if [ ! -f "$EXPECTED_FILE" ]; then
  echo "Agent didn't create file. Executing fallback..."
  cat > "$EXPECTED_FILE" <<EOF
# Fallback Report
$AGENT_OUTPUT
EOF
fi
```
```

**When Fallbacks Required**:
- ✅ Agent file creation (reports, plans, documentation)
- ✅ Agent structured output parsing
- ✅ Agent artifact organization
- ✅ Cross-agent coordination
- ❌ Not needed for read-only operations
- ❌ Not needed for tool-based operations (Write/Edit directly)

#### Anti-Pattern: Assumption Without Verification

**❌ BAD - Assumes compliance**:
```markdown
Step 3: Extract Report Paths

Research agents return report paths. Extract them for use in planning:
```bash
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "Report path:")
```
```

**✅ GOOD - Verifies and enforces**:
```markdown
**EXECUTE NOW - Extract and Verify Report Paths**

Extract paths from agent outputs, with mandatory verification:

```bash
REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep -oP 'REPORT_CREATED:\s*\K.+')

# MANDATORY VERIFICATION
if [ -z "$REPORT_PATH" ]; then
  echo "CRITICAL: Agent didn't return REPORT_CREATED"
  REPORT_PATH="${EXPECTED_PATH}"  # Use pre-calculated path
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "CRITICAL: File doesn't exist at $REPORT_PATH"
  echo "Executing fallback creation..."
  # [Fallback code]
fi

echo "✓ Verified report exists: $REPORT_PATH"
```

**REQUIREMENT**: Both extraction AND verification are mandatory.
```

#### Testing Execution Enforcement

**Test 1: Compliance Under Simplification**

Attempt to simplify command execution and verify critical steps aren't skipped:

```bash
# Simulate: Claude simplifying the research phase
# Expected: Files still created via fallback
# Test: Run command and verify all expected files exist
```

**Test 2: Agent Non-Compliance**

Simulate agents ignoring file creation directives:

```bash
# Simulate: Agent returns text summary instead of creating file
# Expected: Fallback creates file from text
# Test: Verify file exists and contains agent output
```

**Test 3: Verification Bypass Detection**

Check if verification checkpoints are executed:

```bash
# Expected: Verification logs appear in output
# Expected: "✓ Verified:" messages for each critical step
# Test: grep for verification markers in command output
```

#### Phase 0: Orchestrator vs Executor Role Clarification

**Problem** (from Plan 080): Multi-agent commands that invoke other slash commands create architectural violations:
- Commands calling other commands (e.g., `/orchestrate` calling `/plan`, `/implement`)
- Loss of artifact path control (cannot pre-calculate topic-based paths)
- Context bloat (cannot extract metadata before full content loaded)
- Recursion risk (command → command → command loops)

**Solution**: Distinguish between orchestrator and executor roles:

**Orchestrator Role** (coordinates workflow):
- Pre-calculates all artifact paths (topic-based organization)
- Invokes specialized subagents via Task tool (NOT SlashCommand)
- Injects complete context into subagents (behavioral injection pattern)
- Verifies artifacts created at expected locations
- Extracts metadata only (95% context reduction)
- Examples: `/orchestrate`, `/plan` (when coordinating research agents)

**Executor Role** (performs atomic operations):
- Receives pre-calculated paths from orchestrator
- Executes specific task using Read/Write/Edit/Bash tools
- Creates artifacts at exact paths provided
- Returns metadata only (not full content)
- Examples: research-specialist agent, plan-architect agent, implementation-executor agent

**Phase 0 Requirement for Orchestrators**:

Every orchestrator command MUST include Phase 0 (before invoking any subagents):

```markdown
## Phase 0: Pre-Calculate Artifact Paths and Topic Directory

**EXECUTE NOW - Topic Directory Determination**

Before invoking ANY subagents, calculate all artifact paths:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"

# Determine topic directory
WORKFLOW_DESC="$1"  # From user input
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")
# Result: .claude/specs/042_workflow_description/

# Create subdirectories
mkdir -p "$TOPIC_DIR"/{reports,plans,summaries,debug,scripts,outputs}

# Pre-calculate artifact paths
RESEARCH_REPORT_BASE="$TOPIC_DIR/reports"
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")
SUMMARY_PATH=$(create_topic_artifact "$TOPIC_DIR" "summaries" "workflow_summary" "")

# Export for subagent injection
export TOPIC_DIR RESEARCH_REPORT_BASE PLAN_PATH SUMMARY_PATH

echo "✓ Topic directory: $TOPIC_DIR"
echo "✓ Artifact paths calculated"
```

**VERIFICATION**: All paths must be calculated BEFORE any Task invocations.
```

**Anti-Pattern to Avoid**:

```markdown
❌ BAD - Orchestrator invokes other command via SlashCommand:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}

# Problems:
# - /plan calculates its own paths (orchestrator loses control)
# - /plan creates artifacts (orchestrator can't extract metadata first)
# - Context bloat (full plan content loaded into orchestrator)

✅ GOOD - Orchestrator invokes plan-architect agent via Task:

# Phase 0: Pre-calculate plan path
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Phase N: Invoke agent with injected context
Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read: .claude/agents/plan-architect.md

    **Plan Output Path**: ${PLAN_PATH}  # ← Orchestrator controls path
    **Feature**: ${FEATURE_DESCRIPTION}

    Create plan at exact path provided.
    Return metadata: {path, phase_count, complexity}
}

# Phase N+1: Verify and extract metadata
PLAN_METADATA=$(extract_plan_metadata "$PLAN_PATH")
# Result: 95% context reduction (5000 tokens → 250 tokens)
```

**When Phase 0 Required**:
- ✅ `/orchestrate` (coordinates research → plan → implement workflow)
- ✅ `/plan` (if coordinating research agents)
- ✅ `/implement` (if using wave-based parallel execution)
- ✅ `/debug` (if coordinating parallel hypothesis testing)
- ❌ `/list-plans` (read-only, no artifact creation)
- ❌ `/test` (executor role, not orchestrator)

**Cross-Reference**: See [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) for complete implementation details.

### Standard 0.5: Subagent Prompt Enforcement

**Extension of Standard 0 for Agent Definition Files**

Subagent prompts in `.claude/agents/` follow the same enforcement principles as command files, with additional patterns specific to agent behavior and file creation guarantees.

#### Problem Statement

Agent definition files historically used descriptive language ("I am a specialized agent") that Claude treats as guidance rather than mandatory directives. This leads to:
- Variable file creation rates (60-80% vs 100% target)
- Optional interpretation of verification steps
- Skipped checkpoint reporting
- Passive voice that implies optionality

#### Solution: Agent-Specific Enforcement Patterns

**Pattern A: Role Declaration Transformation**

Replace descriptive "I am" declarations with imperative "YOU MUST" directives:

```markdown
❌ WEAK - Descriptive language:
## Research Specialist Agent

I am a specialized agent focused on thorough research and analysis.

My role is to:
- Investigate the codebase for patterns
- Create structured markdown report files using Write tool
- Emit progress markers during research

✅ STRONG - Imperative enforcement:
## Research Specialist Agent

**YOU MUST perform these exact steps in sequence:**

**ROLE**: You are a research specialist with ABSOLUTE REQUIREMENT to create structured report files.

**PRIMARY OBLIGATION**: File creation is NOT optional. You WILL use the Write tool to create the report file at the exact path specified.
```

**Pattern B: Sequential Step Dependencies**

Enforce step ordering with explicit dependencies:

```markdown
❌ WEAK - Unordered list:
Steps to complete:
- Research the topic thoroughly
- Organize findings into sections
- Create report file
- Verify all links work

✅ STRONG - Sequential dependencies:
**STEP 1 (REQUIRED BEFORE STEP 2) - Pre-Calculate Report Path**

EXECUTE NOW - Calculate the exact file path where you will write the report:

```bash
REPORT_PATH="${OUTPUT_DIR}/${TOPIC_NUMBER}_${TOPIC_SLUG}.md"
echo "Report will be written to: $REPORT_PATH"
```

**VERIFICATION**: Path must be absolute and directory must exist.

**STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research**

YOU MUST investigate the codebase using Grep, Glob, and Read tools.

[research instructions]

**STEP 3 (ABSOLUTE REQUIREMENT) - Create Report File**

**EXECUTE NOW - Create Report File**

YOU MUST use the Write tool to create the report file at the exact path from Step 1.

**THIS IS NON-NEGOTIABLE**: File creation MUST occur even if research findings are minimal.

**STEP 4 (MANDATORY VERIFICATION) - Verify File Creation**

After creating the report, YOU MUST verify:

```bash
test -f "$REPORT_PATH" || echo "CRITICAL: Report file not created at $REPORT_PATH"
```

**CHECKPOINT REQUIREMENT**: Report this confirmation before completing the agent task.
```

**Pattern C: File Creation as Primary Obligation**

Elevate file creation to the highest priority:

```markdown
❌ WEAK - File creation as one of many tasks:
Tasks:
- Research patterns
- Analyze findings
- Write report
- Return summary

✅ STRONG - File creation as primary obligation:
**PRIMARY OBLIGATION - File Creation**

**ABSOLUTE REQUIREMENT**: Creating the output file is your PRIMARY task, not a secondary deliverable.

**PRIORITY ORDER**:
1. FIRST: Create output file at specified path (even if empty initially)
2. SECOND: Conduct research and populate file
3. THIRD: Verify file exists and contains all required sections
4. FOURTH: Return confirmation of file creation

**WHY THIS MATTERS**: Commands depend on file artifacts existing at predictable paths. Text summaries returned without files break downstream workflows.

**NON-COMPLIANCE CONSEQUENCE**: If you return a summary without creating the file, the calling command will execute fallback creation, but this degrades quality and loses your detailed findings.
```

**Pattern D: Elimination of Passive Voice**

Replace passive constructions with active imperatives:

```markdown
❌ WEAK - Passive voice (implies optionality):
"Reports should be created in topic directories."
"Links should be verified after file creation."
"Progress markers can be emitted during research."
"Consider adding examples for clarity."

✅ STRONG - Active imperatives:
"YOU MUST create reports in topic directories using this exact path structure:"
"YOU WILL verify all links after creating the file using this command:"
"YOU SHALL emit progress markers at these specific checkpoints:"
"YOU MUST add concrete examples using this template:"
```

**Pattern E: Template-Based Output Enforcement**

Specify non-negotiable output formats:

```markdown
❌ WEAK - Flexible format suggestions:
Include these sections in your report:
- Overview
- Findings
- Recommendations

You may add additional sections as needed.

✅ STRONG - Non-negotiable template:
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

#### Agent-Specific Anti-Patterns

**Anti-Pattern A1: Optional Language**

```markdown
❌ BAD - "should", "may", "can" (implies choice):
"You should create a report file."
"You may include additional sections."
"You can emit progress markers."

✅ GOOD - "MUST", "WILL", "SHALL" (mandatory):
"YOU MUST create a report file."
"YOU WILL include these exact sections."
"YOU SHALL emit progress markers at these checkpoints."
```

**Anti-Pattern A2: Vague Completion Criteria**

```markdown
❌ BAD - Unclear success definition:
"Complete the research task and return findings."

✅ GOOD - Specific completion markers:
**COMPLETION CRITERIA - ALL REQUIRED**:
- [x] Report file exists at exact path specified
- [x] Report contains all mandatory sections
- [x] All internal links verified functional
- [x] Checkpoint confirmation emitted
- [x] File path returned in format: "REPORT_CREATED: /path/to/report.md"

**YOU MUST verify ALL criteria before considering task complete.**
```

**Anti-Pattern A3: Missing "Why This Matters" Context**

```markdown
❌ BAD - Instructions without rationale:
"Create the report file at the specified path."

✅ GOOD - Instructions with enforcement rationale:
**EXECUTE NOW - Create Report File**

Create the report file at the exact path specified in your task prompt.

**WHY THIS MATTERS**:
- Commands rely on artifacts existing at predictable paths
- Metadata extraction depends on file structure
- Plan execution needs cross-references between artifacts
- Text-only summaries break the workflow dependency graph

**CONSEQUENCE OF NON-COMPLIANCE**:
If you return findings as text instead of creating the file, the calling command will execute fallback creation, but your detailed analysis will be reduced to basic templated content.

**GUARANTEE REQUIRED**: File MUST exist at the specified path when you complete this task.
```

#### Before/After Example: research-specialist.md

**Before (Weak Enforcement)**:
```markdown
# Research Specialist Agent

I am a specialized agent focused on thorough research and analysis.

My role is to:
- Investigate the codebase for patterns and existing implementations
- Search external sources for best practices
- Create structured markdown report files using Write tool
- Emit progress markers during research

## Research Process

1. Analyze the research topic and scope
2. Search codebase using Grep, Glob, Read tools
3. Research best practices using WebSearch, WebFetch
4. Organize findings into coherent report structure
5. Create report file in topic directory
6. Verify links and cross-references work

## Output Format

Create markdown report with these sections:
- Overview (2-3 sentences)
- Current State Analysis
- Research Findings
- Recommendations
- References
```

**After (Strong Enforcement)**:
```markdown
# Research Specialist Agent

**YOU MUST perform these exact steps in sequence.**

**PRIMARY OBLIGATION**: Creating the report file is MANDATORY, not optional.

---

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

**OUTPUT FORMAT - Use THIS EXACT TEMPLATE (No modifications)**:

```markdown
# [Topic Title]

## Overview
[2-3 sentence summary - REQUIRED]

## Current State Analysis
[Existing implementation - MANDATORY if codebase research performed]

## Research Findings
[Detailed findings - MINIMUM 5 bullet points REQUIRED]

## Recommendations
[Actionable guidance - MINIMUM 3 recommendations REQUIRED]

## Implementation Guidance
[Step-by-step instructions - REQUIRED]

## References
[Sources - ALL sources MUST be listed]

## Metadata
- Research Date: [YYYY-MM-DD - REQUIRED]
- Files Analyzed: [N files - REQUIRED if codebase analysis]
- External Sources: [N sources - REQUIRED if web research]
```

**ENFORCEMENT**: Every section marked REQUIRED or MANDATORY is NON-NEGOTIABLE.

---

## STEP 4 (MANDATORY VERIFICATION) - Verify File Creation

**YOU MUST execute this verification** after creating the report:

```bash
test -f "$REPORT_PATH" || echo "CRITICAL: Report file not created at $REPORT_PATH"
```

**CHECKPOINT REQUIREMENT**: Emit this confirmation:
```
CHECKPOINT: Report created and verified at $REPORT_PATH
```

---

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

#### Integration with Command-Level Enforcement

Commands that invoke subagents should use a two-layer enforcement approach:

**Layer 1: Command-Level Enforcement (Fallback Guarantee)**
```markdown
**MANDATORY VERIFICATION - Report File Existence**

After research agent completes, YOU MUST verify the file was created:

```bash
EXPECTED_PATH="${REPORT_PATHS[$topic]}"

if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file at $EXPECTED_PATH"
  echo "Executing fallback creation..."

  # Fallback: Extract content from agent output
  cat > "$EXPECTED_PATH" <<EOF
# ${topic}
## Findings
${AGENT_OUTPUT}
EOF

  echo "✓ Fallback file created at $EXPECTED_PATH"
fi
```

**GUARANTEE**: File exists regardless of agent compliance.
```

**Layer 2: Agent-Level Enforcement (Primary Path)**
```markdown
**AGENT INVOCATION - Use THIS EXACT TEMPLATE**

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${topic} with mandatory file creation"
  prompt: "
    Read and follow: .claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT**: File creation is your PRIMARY task.

    Research Topic: ${topic}
    Output Path: ${REPORT_PATHS[$topic]}
    Thinking Mode: ${thinking_mode}

    **CRITICAL**: YOU MUST create the file at the exact path specified.
    DO NOT return a text summary without creating the file.

    Return ONLY: REPORT_CREATED: ${REPORT_PATHS[$topic]}
  "
}
```

**ENFORCEMENT**: Copy this template verbatim. Do NOT simplify the prompt.
```

**Result**: 100% file creation rate through defense-in-depth:
1. Agent prompt enforces file creation (primary path)
2. Agent definition file reinforces enforcement (behavioral layer)
3. Command verification + fallback guarantees outcome (safety net)

#### Testing Subagent Enforcement

**Test Suite**: `.claude/tests/test_subagent_enforcement.sh`

**Test SA-1: File Creation Rate**
```bash
# Invoke each priority agent with standard task
# Expected: 100% file creation rate
# Metric: Files exist at specified paths
```

**Test SA-2: Sequential Step Compliance**
```bash
# Monitor agent execution for checkpoint markers
# Expected: "STEP 1", "STEP 2", "STEP 3" markers in output
# Metric: All steps reported in correct order
```

**Test SA-3: Template Adherence**
```bash
# Verify output files contain all required sections
# Expected: All MANDATORY sections present
# Metric: Parse markdown headers, check against template
```

**Test SA-4: Verification Checkpoint Execution**
```bash
# Check for verification confirmation in output
# Expected: "✓ Verified:" or "CHECKPOINT:" markers
# Metric: grep for verification patterns
```

**Test SA-5: Fallback Activation**
```bash
# Simulate agent non-compliance (text return, no file)
# Expected: Command fallback creates file
# Metric: File exists even with non-compliant agent
```

#### Quality Metrics

**Target**: All priority agents achieve 95+/100 on enforcement checklist

**Scoring Rubric** (10 points per category):
1. **Imperative Language**: All critical steps use YOU MUST/EXECUTE NOW (10 pts)
2. **Sequential Dependencies**: Steps marked REQUIRED BEFORE STEP N+1 (10 pts)
3. **File Creation Priority**: Marked as ABSOLUTE REQUIREMENT (10 pts)
4. **Verification Checkpoints**: MANDATORY VERIFICATION blocks present (10 pts)
5. **Template Enforcement**: THIS EXACT TEMPLATE markers for outputs (10 pts)
6. **Passive Voice Elimination**: Zero "should/may/can" in critical sections (10 pts)
7. **Completion Criteria**: Explicit checklist with ALL REQUIRED marker (10 pts)
8. **Why This Matters Context**: Enforcement rationale provided (10 pts)
9. **Checkpoint Reporting**: CHECKPOINT REQUIREMENT blocks present (10 pts)
10. **Fallback Integration**: Compatible with command-level fallback mechanisms (10 pts)

**95+/100 = 9.5+ categories at full strength**

### Standard 1: Executable Instructions Must Be Inline

**REQUIRED in Command Files**:
- ✅ Step-by-step execution procedures with numbered steps
- ✅ Tool invocation examples with actual parameter values
- ✅ Decision logic flowcharts with conditions and branches
- ✅ JSON/YAML structure specifications with all required fields
- ✅ Bash command examples with actual paths and flags
- ✅ Agent prompt templates (complete, not truncated)
- ✅ Critical warnings (e.g., "CRITICAL: Send ALL Task invocations in SINGLE message")
- ✅ Error recovery procedures with specific actions
- ✅ Checkpoint structure definitions with all fields
- ✅ Regex patterns for parsing results

**ALLOWED as External References**:
- ✅ Extended background context and rationale
- ✅ Additional examples beyond the core pattern
- ✅ Alternative approaches for advanced users
- ✅ Troubleshooting guides for edge cases
- ✅ Historical context and design decisions
- ✅ Related reading and deeper dives

### Standard 2: Reference Pattern

When referencing external files, use this pattern:

**✅ CORRECT Pattern** (Instructions first, reference after):
```markdown
### Research Phase Execution

**Step 1: Calculate Complexity Score**

Use this formula to determine thinking mode:
```
score = keywords("implement") × 3
      + keywords("security") × 4
      + estimated_files / 5
      + (research_topics - 1) × 2

Thinking Mode:
- 0-3: standard (no special mode)
- 4-6: "think" (moderate complexity)
- 7-9: "think hard" (high complexity)
- 10+: "think harder" (critical complexity)
```

**Step 2: Launch Parallel Research Agents**

**CRITICAL**: Send ALL Task tool invocations in SINGLE message block.

Example invocation pattern:
```yaml
# Task 1: Research existing patterns
Task {
  subagent_type: "general-purpose"
  description: "Research existing patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: [topic 1]
    Thinking mode: [mode from Step 1]
    Output path: /absolute/path/to/report1.md
}

# Task 2: Research security practices
Task {
  subagent_type: "general-purpose"
  description: "Research security practices"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research topic: [topic 2]
    Thinking mode: [mode from Step 1]
    Output path: /absolute/path/to/report2.md
}

# [Send both Task blocks in ONE message]
```

**Step 3: Monitor Agent Execution**

Emit PROGRESS markers during execution:
```
PROGRESS: Starting Research Phase (2 agents, parallel execution)
PROGRESS: [Agent 1/2: existing_patterns] Analyzing codebase...
PROGRESS: [Agent 2/2: security_practices] Searching best practices...
```

**For Extended Examples**: See [Orchestration Patterns](../templates/orchestration-patterns.md#research-phase-examples) for additional scenarios and troubleshooting.
```

**❌ INCORRECT Pattern** (Reference only, no inline instructions):
```markdown
### Research Phase Execution

The research phase coordinates multiple agents in parallel.

**See**: [Orchestration Patterns](../templates/orchestration-patterns.md#research-phase) for comprehensive execution details.

**Quick Reference**: Calculate complexity → Launch agents → Monitor execution
```

### Standard 3: Critical Information Density

**Minimum Required Density** per command section:
- **Overview**: Brief description (2-3 sentences)
- **Execution Steps**: Numbered steps with specific actions (5-10 steps typical)
- **Tool Patterns**: At least 1 complete example per tool type used
- **Decision Logic**: All branching conditions with specific thresholds
- **Error Handling**: Recovery procedures for each error type
- **Examples**: At least 1 complete end-to-end example

**Test**: Can Claude execute the command by reading only the command file? If NO, add more inline detail.

### Standard 4: Template Completeness

When providing templates (agent prompts, JSON structures, bash scripts):

**✅ REQUIRED**: Complete, copy-paste ready templates
```yaml
# Complete agent prompt template
Task {
  subagent_type: "general-purpose"
  description: "Update documentation using doc-writer protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/doc-writer.md

    You are acting as a Documentation Writer Agent.

    ## Task: Update Documentation

    ### Context
    - Plan: ${PLAN_PATH}
    - Files Modified: ${FILES_LIST}
    - Tests: ${TEST_STATUS}

    ### Requirements
    1. Update README.md with new feature section
    2. Add usage examples
    3. Update CHANGELOG.md
    4. Create workflow summary at: ${SUMMARY_PATH}

    ### Output Format
    Return results as:
    ```
    DOCUMENTATION_COMPLETE: true
    FILES_UPDATED: [list]
    SUMMARY_CREATED: ${SUMMARY_PATH}
    ```
}
```

**❌ FORBIDDEN**: Truncated or incomplete templates
```yaml
# Incomplete template - DO NOT DO THIS
Task {
  subagent_type: "general-purpose"
  description: "Update documentation"
  prompt: |
    [See doc-writer agent definition for full prompt structure]

    Update documentation for: ${PLAN_PATH}
}
```

### Standard 5: Structural Annotations

Mark sections with usage annotations to guide future refactoring:

```markdown
## Process
[EXECUTION-CRITICAL: This section contains step-by-step procedures that Claude must see during command execution]

### Step 1: Initialize Workflow
[INLINE-REQUIRED: Bash commands and tool calls must remain inline]

bash
source .claude/lib/checkpoint-utils.sh
CHECKPOINT=$(load_checkpoint "implement")


### Step 2: Parse Plan Structure
[INLINE-REQUIRED: Parsing logic with specific commands]

bash
LEVEL=$(parse-adaptive-plan.sh detect_structure_level "$PLAN_PATH")
```

**Annotation Types**:
- `[EXECUTION-CRITICAL]`: Cannot be moved to external files
- `[INLINE-REQUIRED]`: Must stay inline for tool invocation
- `[REFERENCE-OK]`: Can be supplemented with external references
- `[EXAMPLE-ONLY]`: Can be moved to external files if core example remains

---

### Standard 11: Imperative Agent Invocation Pattern

**Requirement**: All Task invocations MUST use imperative instructions that signal immediate execution.

**Problem Statement**:

Documentation-only YAML blocks create a 0% agent delegation rate because they appear as code examples rather than executable instructions. When Task invocations are wrapped in markdown code blocks (` ```yaml`) without preceding imperative instructions, Claude interprets them as syntax examples rather than actions to execute.

**Required Elements**:

Every agent invocation MUST include:

1. **Imperative Instruction**: Use explicit execution markers
   - `**EXECUTE NOW**: USE the Task tool to invoke...`
   - `**INVOKE AGENT**: Use the Task tool with...`
   - `**CRITICAL**: Immediately invoke...`

2. **Agent Behavioral File Reference**: Direct reference to agent guidelines
   - Pattern: `Read and follow: .claude/agents/[agent-name].md`
   - Examples: `.claude/agents/research-specialist.md`, `.claude/agents/plan-architect.md`

3. **No Code Block Wrappers**: Task invocations must NOT be fenced
   - ❌ WRONG: ` ```yaml` ... `Task {` ... `}` ... ` ``` `
   - ✅ CORRECT: `Task {` ... `}` (no fence)

4. **No "Example" Prefixes**: Remove documentation context
   - ❌ WRONG: "Example agent invocation:" or "The following shows..."
   - ✅ CORRECT: "**EXECUTE NOW**: USE the Task tool..."

5. **Completion Signal Requirement**: Agent must return explicit confirmation
   - Pattern: `Return: REPORT_CREATED: ${REPORT_PATH}`
   - Purpose: Enables command-level verification of agent compliance

**Correct Pattern**:

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

**Anti-Pattern (Documentation-Only)**:

```markdown
❌ INCORRECT - This will never execute:

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

**Rationale**:

1. **Execution Clarity**: Imperative instructions make it explicit that this is an action to execute, not a reference example
2. **0% Delegation Prevention**: Removes ambiguity that causes Claude to skip agent invocations
3. **Behavioral Injection**: References agent behavioral files instead of duplicating guidelines inline
4. **Verification Enablement**: Completion signals allow command-level validation

**Enforcement**:

Detection pattern for documentation-only blocks:
```bash
# Find YAML blocks not preceded by imperative instructions
awk '/```yaml/{
  found=0
  for(i=NR-5; i<NR; i++) {
    if(lines[i] ~ /EXECUTE NOW|USE the Task tool|INVOKE AGENT/) found=1
  }
  if(!found) print FILENAME":"NR": Documentation-only YAML block (violates Standard 11)"
} {lines[NR]=$0}' .claude/commands/*.md
```

Regression test requirements:
- Test 1: All agent invocations have imperative instruction within 5 lines
- Test 2: Zero YAML code blocks in agent invocation context (documentation examples excluded)
- Test 3: All agent invocations reference `.claude/agents/*.md` behavioral files
- Test 4: All agent invocations require completion signal in return value

**Historical Context**:

This standard was added after discovering a 0% agent delegation rate in the /supervise command (spec 438). The command contained 7 YAML blocks wrapped in code fences, causing all agent invocations to appear as documentation examples rather than executable instructions.

**Metrics When Properly Applied**:
- Agent delegation rate: 100% (all invocations execute)
- File creation rate: 100% (agents create artifacts at expected paths)
- Context reduction: 90% per invocation (behavioral injection vs inline duplication)

**See Also**:
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md#anti-pattern-documentation-only-yaml-blocks) - Complete anti-pattern documentation
- [Command Development Guide](../guides/command-development-guide.md#avoiding-documentation-only-patterns) - Prevention and migration guide

---

### Standard 12: Structural vs Behavioral Content Separation

Commands MUST distinguish between structural templates (inline) and behavioral content (referenced).

**Requirement - Structural Templates MUST Be Inline**:

Commands MUST include the following structural templates inline:

1. **Task Invocation Syntax**: `Task { subagent_type, description, prompt }` structure
   - Rationale: Commands must parse this structure to invoke agents correctly
   - Example: Complete Task blocks with all required parameters

2. **Bash Execution Blocks**: `**EXECUTE NOW**: bash commands`
   - Rationale: Commands must execute these operations directly
   - Example: Directory creation, environment setup, test execution

3. **JSON Schemas**: Data structure definitions for agent communication
   - Rationale: Commands must parse and validate data structures
   - Example: Report metadata schemas, context injection formats

4. **Verification Checkpoints**: `**MANDATORY VERIFICATION**: file existence checks`
   - Rationale: Orchestrator (command) is responsible for verification
   - Example: Verify files created, validate report structure

5. **Critical Warnings**: `**CRITICAL**: error conditions and constraints`
   - Rationale: Execution-critical constraints that commands must enforce immediately
   - Example: File creation requirements, error handling rules

**Prohibition - Behavioral Content MUST NOT Be Duplicated**:

Commands MUST NOT duplicate agent behavioral content inline. Instead, reference agent files via behavioral injection pattern:

Behavioral content includes:
1. **Agent STEP Sequences**: `STEP 1/2/3` procedural instructions
   - Location: `.claude/agents/*.md` files ONLY
   - Pattern: "Read and follow: .claude/agents/[name].md" with context injection

2. **File Creation Workflows**: `PRIMARY OBLIGATION` blocks defining agent internal procedures
   - Location: `.claude/agents/*.md` files ONLY
   - Pattern: Reference agent file, inject file paths and parameters

3. **Agent Verification Steps**: Agent-internal quality checks before returning
   - Location: `.claude/agents/*.md` files ONLY
   - Pattern: Agent files define self-verification procedures

4. **Output Format Specifications**: Templates showing how agent should format responses
   - Location: `.claude/agents/*.md` files ONLY
   - Pattern: Agent files contain output templates, commands reference them

**Rationale**:
- Single source of truth: Agent behavioral guidelines exist in one location only
- Maintenance burden reduction: 50-67% reduction by eliminating duplication
- Context efficiency: 90% code reduction per agent invocation (150 lines → 15 lines)
- Synchronization elimination: No need to manually sync behavioral content across files

**Enforcement**:

Validation criteria:
- STEP instruction count in commands: <5 (behavioral content should be in agent files)
- Agent invocation size: <50 lines per Task block (context injection only, not behavioral duplication)
- PRIMARY OBLIGATION presence: Zero occurrences in command files (agent files only)
- Behavioral file references: All agent invocations should reference behavioral files

Metrics when properly applied:
- 90% reduction in code per agent invocation
- <30% context window usage throughout workflows
- 100% file creation success rate
- Elimination of synchronization burden

Detection:
- Optional validation script: `.claude/tests/validate_no_behavioral_duplication.sh`
- Automated checks for STEP sequences, PRIMARY OBLIGATION, large Task blocks

**Exceptions**:

NONE - Zero documented exceptions to behavioral duplication prohibition.

If behavioral content duplication is detected:
1. Extract to appropriate agent file in `.claude/agents/`
2. Update command to reference agent file with context injection only
3. Validate reduction (expect ~90% line reduction per invocation)
4. Test command execution to verify agent receives guidelines

**See Also**:
- [Template vs Behavioral Distinction](./template-vs-behavioral-distinction.md) - Detailed guidance and decision criteria
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Pattern for referencing agent behavioral files
- [Inline Template Duplication Troubleshooting](../troubleshooting/inline-template-duplication.md) - Detect and fix anti-pattern

---

## Refactoring Guidelines

### When to Extract Content

**✅ Safe to Extract** (Move to reference files):
1. **Extended Background**: Historical context, design rationale
2. **Alternative Approaches**: Other ways to solve similar problems
3. **Additional Examples**: Beyond the 1-2 core examples needed inline
4. **Troubleshooting Guides**: Edge case handling and debugging tips
5. **Deep Dives**: Detailed explanations of algorithms or patterns
6. **Related Reading**: Links to external documentation or research

**❌ Never Extract** (Must stay inline):
1. **Step-by-step execution procedures**: The core workflow
2. **Tool invocation patterns**: Task, Bash, Read, Write, Edit examples
3. **Decision flowcharts**: If/then logic with specific conditions
4. **Critical warnings**: CRITICAL, IMPORTANT, NEVER, ALWAYS statements
5. **Template structures**: Complete agent prompts, JSON schemas, bash scripts
6. **Error recovery procedures**: Specific actions for each error type
7. **Parameter specifications**: Required/optional parameters with types
8. **Parsing patterns**: Regex patterns, jq queries, grep commands

### Correct Refactoring Process

**Before Refactoring**:
1. Identify duplicated content across command files
2. Classify each duplicated section using "Safe to Extract" vs "Never Extract" lists
3. For "Safe to Extract" content: Move to reference files
4. For "Never Extract" content: Keep inline but consider:
   - Standardizing format across files
   - Using consistent variable names
   - Maintaining separate copies per file

**After Refactoring**:
1. Test each command by executing it
2. Verify Claude can complete tasks without reading external files
3. Check that all critical patterns are still visible
4. Validate that execution flow is clear from command file alone

**Refactoring Checklist**:
- [ ] Execution steps remain inline and numbered
- [ ] Tool invocation examples are complete (not truncated)
- [ ] Critical warnings still present in command file
- [ ] Templates are copy-paste ready (not referencing external files)
- [ ] Decision logic includes all conditions and thresholds
- [ ] Error recovery procedures include specific actions
- [ ] Command can be executed by reading only the command file
- [ ] External references provide supplemental context only
- [ ] File size reduction is secondary to execution clarity

---

## Testing Standards

### Validation Criteria

Before committing changes to command or agent files:

**Test 1: Execution Without External Files**

Temporarily move `.claude/commands/shared/` and `.claude/templates/` to backup location:
```bash
mv .claude/commands/shared .claude/commands/shared.backup
mv .claude/templates .claude/templates.backup
```

Execute the command:
```bash
# Test each command
/orchestrate "Simple test feature"
/implement specs/plans/test_plan.md
/revise "Update test" specs/plans/test_plan.md
/setup
```

**PASS**: Command completes successfully
**FAIL**: Command cannot find necessary information

Restore directories:
```bash
mv .claude/commands/shared.backup .claude/commands/shared
mv .claude/templates.backup .claude/templates
```

**Test 2: Critical Pattern Presence**

For each command file, verify presence of:
```bash
# Search for critical patterns
grep -c "Step [0-9]:" .claude/commands/commandname.md  # Should be ≥5
grep -c "CRITICAL:" .claude/commands/commandname.md    # Should match expected count
grep -c "```bash" .claude/commands/commandname.md      # Should be ≥3
grep -c "```yaml" .claude/commands/commandname.md      # Should be ≥2
grep -c "Task {" .claude/commands/commandname.md       # Should be ≥1 if uses agents
```

**Test 3: Template Completeness**

Extract all templates and verify they are complete:
```bash
# Find all Task invocations
grep -A 20 "Task {" .claude/commands/commandname.md

# Verify each has:
# - subagent_type
# - description
# - prompt with complete instructions
# - No [See...] references in prompt body
```

**Test 4: Reference Pattern Validation**

Check that external references follow correct pattern:
```bash
# Find all external references
grep -n "**See**:" .claude/commands/commandname.md

# For each reference:
# - Verify inline instructions appear BEFORE the reference
# - Reference should supplement, not replace
# - Section should be executable without following the reference
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Reference-Only Sections

**❌ BAD**:
```markdown
## Implementation Phase

The implementation phase executes the plan with testing and commits.

**See**: [Implementation Workflow](shared/implementation-workflow.md) for complete execution steps.

**Quick Reference**: Execute phases → Test → Commit → Update checkpoint
```

**✅ GOOD**:
```markdown
## Implementation Phase

Execute the implementation plan phase by phase with testing and git commits.

**Step 1: Load Plan and Checkpoint**
```bash
source .claude/lib/checkpoint-utils.sh
CHECKPOINT=$(load_checkpoint "implement")
PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.plan_path')
CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')
```

**Step 2: For Each Phase**
1. Read phase tasks from plan file
2. Execute tasks sequentially
3. Run tests after each task
4. Create git commit on phase completion
5. Update checkpoint with progress

**Step 3: Handle Test Failures**
```bash
if [ $TEST_EXIT_CODE -ne 0 ]; then
  source .claude/lib/error-handling.sh
  ERROR_TYPE=$(classify_error "$TEST_OUTPUT")
  SUGGESTIONS=$(suggest_recovery "$ERROR_TYPE" "$TEST_OUTPUT")
  echo "Tests failed: $SUGGESTIONS"
  # Do not mark phase complete
  exit 1
fi
```

**For Extended Examples**: See [Implementation Workflow](shared/implementation-workflow.md) for additional scenarios and edge cases.
```

### Anti-Pattern 2: Truncated Templates

**❌ BAD**:
```markdown
**Agent Invocation Template**:
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: "See agent definition file for complete prompt structure"
}
```
```

**✅ GOOD**:
```markdown
**Agent Invocation Template**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns using research-specialist"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/research-specialist.md

    You are acting as a Research Specialist Agent.

    ## Research Task: Authentication Patterns

    ### Research Topics
    1. Existing authentication implementations in codebase
    2. Industry best practices for 2025
    3. Security considerations

    ### Output Requirements
    Create research report at: /absolute/path/to/report.md

    Include:
    - Current State Analysis
    - Best Practices Review
    - Security Recommendations
    - Implementation Guidance

    ### Thinking Mode
    Use "think hard" mode (complex analysis required)
}
```
```

### Anti-Pattern 3: Vague Quick References

**❌ BAD**:
```markdown
**Quick Reference**: Discover plan → Execute phases → Generate summary
```

**✅ GOOD**:
```markdown
**Quick Reference**:
1. Discover plan using find + parse-adaptive-plan.sh
2. Load checkpoint with load_checkpoint "implement"
3. Execute phases sequentially (or in waves if dependencies present)
4. Run tests after each phase using standards-defined test commands
5. Create git commit on phase completion
6. Update checkpoint after each phase
7. Generate implementation summary in specs/{topic}/summaries/
```

### Anti-Pattern 4: Missing Critical Warnings

**❌ BAD**:
```markdown
**Step 2: Launch Research Agents**

Invoke multiple research-specialist agents for parallel research.
```

**✅ GOOD**:
```markdown
**Step 2: Launch Research Agents**

**CRITICAL**: Send ALL Task tool invocations in SINGLE message block. Do NOT send separate messages per agent - this breaks parallelization.

Invoke multiple research-specialist agents for parallel research:
```yaml
# All agents in ONE message:
Task { ... agent 1 ... }
Task { ... agent 2 ... }
Task { ... agent 3 ... }
```
```

---

## File Organization Standards

### Directory Structure

```
.claude/
├── commands/              # Primary command files (EXECUTION-CRITICAL)
│   ├── orchestrate.md    # Must contain complete execution steps
│   ├── implement.md      # Must contain complete execution steps
│   ├── revise.md         # Must contain complete execution steps
│   ├── setup.md          # Must contain complete execution steps
│   └── shared/           # Reference files only (SUPPLEMENTAL)
│       ├── README.md     # Index of shared content
│       └── *.md          # Extended context, examples, background
├── agents/               # Agent definition files (EXECUTION-CRITICAL)
│   ├── research-specialist.md
│   ├── plan-architect.md
│   └── *.md
├── templates/            # Reusable templates (REFERENCE-OK)
│   ├── orchestration-patterns.md
│   └── *.md
└── docs/                 # Standards and architecture (REFERENCE-OK)
    ├── command_architecture_standards.md  # This file
    ├── command-patterns.md
    └── *.md
```

### File Size Guidelines

**Command Files**:
- **Target**: 500-2000 lines (varies by command complexity)
- **Minimum**: 300 lines (simpler commands)
- **Maximum**: 3000 lines (complex orchestration commands)
- **Warning Signs**:
  - <300 lines: Likely missing execution details
  - <200 lines: Almost certainly broken by over-extraction
  - >3500 lines: Consider splitting into separate commands, not extracting to references

**Reference Files** (shared/, templates/, docs/):
- **Target**: 100-1000 lines
- **Purpose**: Extended examples, background, alternatives
- **Rule**: No file in shared/ should be required reading for command execution

### Content Allocation

**80/20 Rule**:
- 80% of execution-critical content stays in command file
- 20% supplemental context can go to reference files

**Critical Mass Principle**:
- Command file must contain enough detail to execute independently
- Reference files enhance understanding but aren't required for execution

---

## Migration Path for Broken Commands

If a command has been broken by over-extraction:

**Step 1: Identify Missing Patterns**

Compare current file with version before extraction:
```bash
git show <commit-before-extraction>:.claude/commands/commandname.md > original.md
git show HEAD:.claude/commands/commandname.md > current.md
diff -u original.md current.md | grep "^-" | head -100
```

**Step 2: Restore Critical Content**

For each section identified in Step 1:
1. Check if content is in shared/ files
2. If execution-critical: Copy back to command file
3. If supplemental: Leave in shared/ and add reference to command file

**Step 3: Validate Restoration**

Run all tests from "Testing Standards" section above.

**Step 4: Document Changes**

Update command file with structural annotations:
```markdown
## Restored Section
[EXECUTION-CRITICAL: Restored from commit <hash> after over-extraction]
```

---

## Agent File Standards

Agent definition files follow similar principles to command files:

**REQUIRED Inline Content**:
- ✅ Agent role and purpose
- ✅ Tool restrictions and allowed tools list
- ✅ Behavioral constraints and guidelines
- ✅ Output format specifications
- ✅ Success criteria and completion markers
- ✅ Error handling procedures
- ✅ Examples of agent task patterns

**Reference Pattern for Agents**:
```markdown
## Research Specialist Agent

### Role
You are a specialized research agent focused on analyzing codebases and gathering implementation guidance.

### Allowed Tools
- Read, Grep, Glob: For codebase analysis
- WebSearch, WebFetch: For best practices research
- Write: For creating research reports

### Behavioral Guidelines

**Research Process**:
1. **Analyze Context**: Review research topic and current codebase
2. **Gather Information**: Search codebase and external sources
3. **Synthesize Findings**: Organize into structured report
4. **Validate Completeness**: Ensure all research questions answered

**Output Format**:
Create research report with these sections:
- ## Overview: 2-3 sentence summary
- ## Current State: Analysis of existing implementation
- ## Best Practices: Industry standards for 2025
- ## Recommendations: Specific implementation guidance
- ## References: Sources and links

**Quality Criteria**:
- Actionable: Recommendations must be specific and implementable
- Contextual: Consider existing codebase patterns
- Current: Use 2025 best practices, not outdated patterns
- Comprehensive: Cover all aspects of research topic

### Example Task Pattern

Typical research-specialist invocation:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Research Topic: Authentication patterns in Lua applications
    Thinking Mode: think hard
    Output Path: /absolute/path/to/report.md

    Focus Areas:
    - Existing authentication in codebase
    - Security best practices
    - Session management patterns
}
```

**For Extended Research Methodologies**: See [Agent Patterns](../docs/agent-patterns.md#research-specialist-advanced) for advanced techniques.
```

---

## Review Checklist

Use this checklist when reviewing pull requests that modify command or agent files:

### Command File Changes

- [ ] **Execution Enforcement (NEW)**: Are critical steps marked with "EXECUTE NOW", "YOU MUST", or "MANDATORY"?
- [ ] **Verification Checkpoints (NEW)**: Are verification steps explicit with "if [ ! -f ]" checks?
- [ ] **Fallback Mechanisms (NEW)**: Do agent-dependent operations include fallback creation?
- [ ] **Agent Template Enforcement (NEW)**: Are agent prompts marked "THIS EXACT TEMPLATE (No modifications)"?
- [ ] **Checkpoint Reporting (NEW)**: Do major steps include explicit completion reporting?
- [ ] **Execution Steps**: Are numbered steps still present and complete?
- [ ] **Tool Examples**: Are tool invocation examples still inline and copy-paste ready?
- [ ] **Critical Warnings**: Are CRITICAL/IMPORTANT/NEVER statements still present?
- [ ] **Templates**: Are agent prompts, JSON schemas, bash scripts complete (not truncated)?
- [ ] **Decision Logic**: Are conditions, thresholds, and branches specific?
- [ ] **Error Handling**: Are recovery procedures specific with actions?
- [ ] **References**: Do external references supplement (not replace) inline instructions?
- [ ] **File Size**: Is file size >300 lines? (Flag if <300)
- [ ] **Annotations**: Are structural annotations present ([EXECUTION-CRITICAL], etc.)?
- [ ] **Testing**: Has the command been executed successfully after changes?

### Agent File Changes (NEW)

**Subagent Prompt Enforcement** (Standard 0.5):
- [ ] **Imperative Language**: All critical steps use "YOU MUST", "EXECUTE NOW", "ABSOLUTE REQUIREMENT"?
- [ ] **Role Declaration**: Uses "YOU MUST perform" instead of "I am a specialized agent"?
- [ ] **Sequential Dependencies**: Steps marked "STEP N (REQUIRED BEFORE STEP N+1)"?
- [ ] **File Creation Priority**: File creation marked as "PRIMARY OBLIGATION" or "ABSOLUTE REQUIREMENT"?
- [ ] **Verification Checkpoints**: "MANDATORY VERIFICATION" blocks present after critical operations?
- [ ] **Template Enforcement**: Output formats marked "THIS EXACT TEMPLATE (No modifications)"?
- [ ] **Passive Voice Elimination**: Zero "should/may/can" in critical sections, all use "MUST/WILL/SHALL"?
- [ ] **Completion Criteria**: Explicit checklist with "ALL REQUIRED" marker present?
- [ ] **Why This Matters Context**: Enforcement rationale provided for critical operations?
- [ ] **Checkpoint Reporting**: "CHECKPOINT REQUIREMENT" blocks present at major milestones?
- [ ] **Fallback Integration**: Compatible with command-level fallback mechanisms?

**Quality Scoring**: Does the agent file score 95+/100 on the enforcement rubric (9.5+ categories at full strength)?

### Reference File Changes

- [ ] **Supplemental**: Does content supplement command files (not replace)?
- [ ] **Independence**: Can command files execute without reading this reference?
- [ ] **Organization**: Is content organized by topic with clear headings?
- [ ] **Links**: Are links back to command files present and accurate?
- [ ] **Examples**: Are extended examples genuinely additional (not the only examples)?

### Refactoring Changes

- [ ] **Extraction Justification**: Is extracted content truly supplemental?
- [ ] **Inline Retention**: Do command files still have enough detail to execute?
- [ ] **Reference Pattern**: Do references follow "inline first, reference after" pattern?
- [ ] **Test Results**: Have all testing standards tests passed?
- [ ] **Validation**: Can commands execute with shared/ directory temporarily removed?

---

## Enforcement

### Pre-Commit Validation

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Validate command file integrity

for cmd in .claude/commands/*.md; do
  # Skip if not modified in this commit
  git diff --cached --name-only | grep -q "$cmd" || continue

  # Check line count (minimum 300 lines for main commands)
  LINES=$(wc -l < "$cmd")
  if [ "$LINES" -lt 300 ] && [[ "$cmd" =~ (orchestrate|implement|revise|setup).md ]]; then
    echo "ERROR: $cmd has only $LINES lines (minimum 300 for main commands)"
    echo "This suggests execution details have been over-extracted."
    exit 1
  fi

  # Check for critical patterns
  STEPS=$(grep -c "Step [0-9]:" "$cmd")
  if [ "$STEPS" -lt 3 ]; then
    echo "WARNING: $cmd has only $STEPS numbered steps (expected ≥3)"
  fi

  # Check for complete Task examples
  TASKS=$(grep -c "Task {" "$cmd")
  COMPLETE_TASKS=$(grep -A 10 "Task {" "$cmd" | grep -c "prompt: |")
  if [ "$TASKS" -gt 0 ] && [ "$COMPLETE_TASKS" -lt "$TASKS" ]; then
    echo "ERROR: $cmd has incomplete Task invocation templates"
    exit 1
  fi
done

echo "✓ Command file validation passed"
```

### Continuous Integration

Add to CI pipeline:
```bash
# Test command execution (basic smoke tests)
.claude/tests/test_command_execution.sh

# Validate command file structure
.claude/tests/test_command_structure.sh

# Check for anti-patterns
.claude/tests/test_command_antipatterns.sh
```

---

## Examples from Codebase

### Good Example: Current `/implement` Plan Hierarchy Update

**Location**: `.claude/commands/implement.md` lines 184-269

This section demonstrates correct inline content:
- ✅ Complete Task invocation template with full agent prompt
- ✅ Step-by-step update workflow
- ✅ Error handling procedures
- ✅ Checkpoint state structure
- ✅ All hierarchy levels documented

### Bad Example: Broken `/orchestrate` Research Phase

**Location**: `.claude/commands/orchestrate.md` lines 414-436 (after commit 40b9146)

This section demonstrates incorrect reference-only pattern:
- ❌ Only high-level bullet points
- ❌ "See shared/workflow-phases.md for comprehensive details"
- ❌ Missing complexity score calculation formula
- ❌ Missing parallel agent invocation pattern
- ❌ Missing CRITICAL warning about single message
- ❌ Cannot execute without reading external file

### Restoration Target: Original `/orchestrate` Research Phase

**Location**: Commit 40b9146^ lines 414-550

This section demonstrates correct execution-critical content:
- ✅ Complete 7-step execution procedure inline
- ✅ Complexity score formula with specific calculations
- ✅ Thinking mode determination matrix
- ✅ CRITICAL warnings about parallel invocation
- ✅ Complete Task invocation examples
- ✅ Progress monitoring patterns
- ✅ Report verification procedures
- ✅ Error recovery workflows
- ✅ References to orchestration-patterns.md for ADDITIONAL context

---

## Related Standards

This document should be read in conjunction with:
- [Command Patterns](../guides/command-patterns.md): Common execution patterns across commands
- [Agent Patterns](../guides/agent-patterns.md): Agent invocation and coordination patterns
- [Testing Standards](../guides/testing-standards.md): Validation and testing requirements
- [Documentation Standards](../CLAUDE.md#documentation-policy): General documentation guidelines

---

## Version History

- **2025-10-16**: Initial version based on refactoring damage analysis (commit 40b9146)

---

## Quick Reference Card

**When Refactoring Command Files**:

✅ **DO**:
- Keep execution steps inline and numbered
- Include complete tool invocation examples
- Preserve critical warnings and constraints
- Provide copy-paste ready templates
- Add references to supplemental content AFTER inline instructions
- Test commands after refactoring
- Use structural annotations

❌ **DON'T**:
- Replace execution steps with "See external file"
- Truncate templates with references to agent definitions
- Remove critical warnings for brevity
- Assume Claude can effectively load external files mid-execution
- Prioritize DRY principles over execution clarity
- Reduce file size below minimum thresholds
- Extract content without validation testing

**Testing After Changes**:
1. Temporarily remove `.claude/commands/shared/`
2. Execute the modified command
3. If it fails, restore inline content
4. Add references only after execution works

---

**Remember**: Command files are AI execution scripts, not traditional code. When in doubt, keep content inline.

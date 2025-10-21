# Debug Report: /report Command Not Invoking Subagents

## Metadata
- **Date**: 2025-10-20
- **Issue**: /report command executes research directly instead of delegating to subagents
- **Severity**: High
- **Type**: Command Execution Flow
- **Related Reports**:
  - reports/002_report_command_compliance_analysis.md (compliance analysis)

## Problem Statement

When invoking `/report` with a research topic, Claude executes the research **directly as a single agent** instead of following the documented hierarchical multi-agent pattern (topic decomposition → parallel research specialists → synthesis → cross-reference updates).

### Expected Behavior

Per the command documentation (`.claude/commands/report.md` lines 25-380):
1. Decompose research topic into 2-4 subtopics
2. Pre-calculate absolute paths for each subtopic report
3. Invoke research-specialist agents in parallel (one per subtopic)
4. Verify all subtopic reports created
5. Invoke research-synthesizer agent to create OVERVIEW.md
6. Invoke spec-updater agent for cross-references
7. Return overview path with metadata-only summaries

### Actual Behavior

Analysis of execution output (`example_3.md`):
- ✅ Claude reads the command file
- ✅ Claude reads referenced documentation
- ❌ Claude does NOT execute topic decomposition
- ❌ Claude does NOT invoke Task tool for subagents
- ❌ Claude executes research directly using Read/Grep/Write tools
- ❌ Single report created (not multiple subtopic reports + overview)

### Impact

- **No parallelization**: Sequential research instead of parallel (0% time savings vs. 40-60% target)
- **No metadata reduction**: Full content retained in memory (0% reduction vs. 99% target)
- **No synthesis**: Single report instead of organized subtopic reports + overview
- **Pattern violation**: Command doesn't follow hierarchical agent architecture standards

## Investigation Process

### Step 1: Examine Execution Output

**File**: `specs/002_report_creation/example_3.md`

**Key Observations**:
- Lines 10-13: "I'll research the /report command implementation to verify..."
- Lines 15-49: Direct tool usage (Read, Search) by primary agent
- Lines 86-88: Single Write operation creating one report file
- **Missing**: No Task tool invocations for subagents
- **Missing**: No mention of topic decomposition or parallel research

**Conclusion**: Claude executed as a single agent, not as an orchestrator delegating to subagents.

### Step 2: Analyze Command File Structure

**File**: `.claude/commands/report.md`

**Opening Statement (Line 11)**:
```markdown
I'll research the specified topic and create a comprehensive report in the most appropriate location.
```

**Analysis**:
- Language: First-person declarative ("I'll research")
- Implication: Claude should execute research directly
- Problem: Contradicts hierarchical multi-agent pattern in sections 1.5-5

**Section 1.5: Topic Decomposition (Lines 25-64)**:
```markdown
**Decompose research topic into focused subtopics**:

```bash
# Source decomposition utility
source .claude/lib/topic-decomposition.sh
...
```

**Use Task tool** to execute decomposition:

Task invocation:
- subagent_type: general-purpose
- description: "Decompose research topic into subtopics"
```

**Analysis**:
- Format: Documentation/example style
- Language: Descriptive ("Decompose research topic")
- Problem: Not formatted as **mandatory executable directive**
- Missing: "YOU MUST", "EXECUTE NOW", "STEP 1 (REQUIRED BEFORE STEP 2)" enforcement

**Section 3: Parallel Research Invocation (Lines 144-200)**:
```markdown
**Invoke all research agents in parallel** (multiple Task calls in single message):

For EACH subtopic in SUBTOPICS array, invoke research-specialist agent:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  ...
}
```
```

**Analysis**:
- Format: Template/example
- Language: Instructional ("Invoke all research agents")
- Problem: Presented as **what to do** rather than **execute this now**
- Missing: Imperative enforcement ("YOU MUST invoke", "EXECUTE NOW")

### Step 3: Compare with Working Commands

**Comparison**: `/orchestrate` command (known to work with subagents)

**Key Differences**:

| Aspect | /report (broken) | /orchestrate (working) |
|--------|------------------|------------------------|
| Opening | "I'll research the topic..." | "I'll coordinate a multi-phase workflow..." |
| Instructions | Descriptive examples | Mixed (some descriptive, some direct) |
| Enforcement | Weak (no "YOU MUST") | Moderate (some "CRITICAL" markers) |
| Code blocks | Documentation style | Executable directives |
| Agent prompts | Template format | Complete prompts with context |

**Observation**: Both commands have similar issues (descriptive language), but `/orchestrate` may work better due to:
- More explicit phase structure
- "CRITICAL" warnings about parallel invocation
- Clearer separation between what Claude does vs. what agents do

### Step 4: Root Cause Analysis

#### Primary Cause: Ambiguous Command Opening

**Line 11** (`.claude/commands/report.md`):
```markdown
I'll research the specified topic and create a comprehensive report in the most appropriate location.
```

**Problem**: This is interpreted by Claude as:
- **Claude's interpretation**: "I (Claude) will research and create the report"
- **Intended meaning**: "This command will orchestrate research (via subagents) and produce a report"

**Evidence**: In `example_3.md` line 10:
```
● I'll research the /report command implementation to verify...
```

Claude adopted first-person perspective and executed research directly.

#### Contributing Factor 1: Documentation vs. Execution Format

**Sections 1.5-5** contain hierarchical pattern specification, but formatted as:
- **Documentation**: "Here's how the pattern works..."
- **Examples**: "Here's a template for Task invocation..."
- **Instructions**: "Do X, then Y, then Z..."

**Missing**: Execution enforcement per Standard 0 (.claude/docs/reference/command_architecture_standards.md):
- ❌ No "EXECUTE NOW" markers
- ❌ No "YOU MUST" imperatives
- ❌ No "STEP N (REQUIRED BEFORE STEP N+1)" dependencies
- ❌ No "MANDATORY VERIFICATION" checkpoints
- ❌ No "CHECKPOINT:" reporting requirements

#### Contributing Factor 2: Bash Code Blocks Not Executed

**Expected**: Claude executes bash code blocks during command processing

**Example** (lines 29-40):
```bash
# Source decomposition utility
source .claude/lib/topic-decomposition.sh
source .claude/lib/artifact-operations.sh
source .claude/lib/template-integration.sh

# Determine number of subtopics based on topic complexity
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")
```

**Actual**: Claude reads this as **documentation** showing what should happen, not as **code to execute now**

**Reason**: No explicit directive to execute:
- Missing: "EXECUTE NOW - Run this code block:"
- Missing: "YOU MUST source these utilities before proceeding:"
- Format: Presented as example/illustration

#### Contributing Factor 3: Task Tool Invocation Not Explicit

**Section 3** (lines 144-194) shows Task invocation template:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research [SUBTOPIC] with mandatory artifact creation"
  prompt: "..."
}
```

**Problem**: Presented as **template to follow** rather than **execute this now**

**Missing**:
- No "EXECUTE NOW - Invoke research agents:" header
- No "YOU MUST send all Task calls in a SINGLE message:" directive
- No variable substitution (still shows `[SUBTOPIC]` placeholders)
- No completion verification ("After agents complete, verify files exist...")

## Proposed Solutions

### Option 1: Add Execution Enforcement (Recommended)

**Approach**: Transform command from documentation to executable directives using Standard 0 patterns.

**Changes Required**:

#### Change 1: Rewrite Opening Statement

**Current** (line 11):
```markdown
I'll research the specified topic and create a comprehensive report in the most appropriate location.
```

**Fixed**:
```markdown
I'll orchestrate hierarchical research by delegating to specialized subagents.

**CRITICAL INSTRUCTION**: You are NOT executing research directly. You are ORCHESTRATING
subagents who will execute research. Your role is:
1. Decompose topic into subtopics
2. Invoke research-specialist agents (parallel)
3. Invoke research-synthesizer agent (synthesis)
4. Verify artifacts and return metadata-only summaries

DO NOT use Read/Write/Grep tools to conduct research yourself. ONLY use Task tool to delegate.
```

**Impact**: ✅ Clarifies Claude's role as orchestrator, not researcher

#### Change 2: Add Execution Enforcement to Section 1.5

**Current** (lines 25-42):
```markdown
### 1.5. Topic Decomposition

**Decompose research topic into focused subtopics**:

```bash
# Source decomposition utility
source .claude/lib/topic-decomposition.sh
...
```
```

**Fixed**:
```markdown
### 1.5. Topic Decomposition

**STEP 1 (REQUIRED BEFORE STEP 2) - Topic Decomposition**

**EXECUTE NOW - Source Utilities and Decompose Topic**

YOU MUST run this code block NOW:

```bash
# Source required utilities
source "${CLAUDE_PROJECT_DIR}/.claude/lib/topic-decomposition.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-operations.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/template-integration.sh"

# Determine number of subtopics (2-4 based on complexity)
RESEARCH_TOPIC="$ARGUMENTS"
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")

echo "Topic: $RESEARCH_TOPIC"
echo "Subtopics: $SUBTOPIC_COUNT"
```

**MANDATORY VERIFICATION**:
```bash
# Verify utilities loaded
command -v calculate_subtopic_count >/dev/null || echo "ERROR: Utilities not loaded"

# Verify subtopic count in valid range
if [ "$SUBTOPIC_COUNT" -lt 2 ] || [ "$SUBTOPIC_COUNT" -gt 4 ]; then
  echo "ERROR: Invalid subtopic count: $SUBTOPIC_COUNT (must be 2-4)"
  exit 1
fi

echo "✓ VERIFIED: Topic decomposition ready"
```

**CHECKPOINT**:
```
CHECKPOINT: Topic decomposition preparation complete
- Research topic: $RESEARCH_TOPIC
- Target subtopic count: $SUBTOPIC_COUNT
- Utilities loaded: ✓
- Proceeding to: Subtopic naming via decomposition agent
```
```

**Impact**: ✅ Forces execution with imperatives, verification, and checkpoints

#### Change 3: Make Task Invocations Explicit

**Current** (lines 152-194):
```markdown
**Invoke all research agents in parallel** (multiple Task calls in single message):

For EACH subtopic in SUBTOPICS array, invoke research-specialist agent:

```yaml
Task {
  ...
}
```
```

**Fixed**:
```markdown
**STEP 3 (REQUIRED AFTER STEP 2) - Parallel Research Agent Invocation**

**CRITICAL**: Send ALL Task tool invocations in a SINGLE message block.

**EXECUTE NOW - Invoke Research-Specialist Agents**

YOU MUST invoke research-specialist agents for each subtopic IN PARALLEL:

```yaml
# Agent 1: Research ${SUBTOPICS[0]}
Task {
  subagent_type: "general-purpose"
  description: "Research ${SUBTOPICS[0]} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    **Research Topic**: ${SUBTOPICS[0]}
    **Report Path**: ${SUBTOPIC_REPORT_PATHS[${SUBTOPICS[0]}]}
    **Thinking Mode**: ${THINKING_MODE}

    Execute all 4 steps from research-specialist.md.
    Return: REPORT_CREATED: <path>
  "
}

# Agent 2: Research ${SUBTOPICS[1]}
Task {
  subagent_type: "general-purpose"
  description: "Research ${SUBTOPICS[1]} with mandatory file creation"
  prompt: "
    Read and follow behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

    **ABSOLUTE REQUIREMENT - File Creation is Your Primary Task**

    **Research Topic**: ${SUBTOPICS[1]}
    **Report Path**: ${SUBTOPIC_REPORT_PATHS[${SUBTOPICS[1]}]}
    **Thinking Mode**: ${THINKING_MODE}

    Execute all 4 steps from research-specialist.md.
    Return: REPORT_CREATED: <path>
  "
}

# [Continue for all subtopics - DO NOT send these one at a time]
```

**MANDATORY REQUIREMENT**: All Task invocations above MUST be sent in ONE message.

**CHECKPOINT REQUIREMENT - After Agents Complete**:

Monitor for agent completion and emit:
```
CHECKPOINT: Parallel research phase complete
- Agents invoked: ${#SUBTOPICS[@]}
- Reports expected: ${#SUBTOPIC_REPORT_PATHS[@]}
- Proceeding to: Report verification
```
```

**Impact**: ✅ Explicit Task invocations with filled-in variables, enforcement, and verification

#### Change 4: Add Post-Agent Verification

**Add After Section 3** (new Section 3.5):
```markdown
### 3.5. Report Verification and Error Recovery

**STEP 4 (REQUIRED AFTER STEP 3) - Mandatory Report Verification**

**EXECUTE NOW - Verify All Reports Created**

After research agents complete, YOU MUST verify files exist:

```bash
declare -A VERIFIED_PATHS
VERIFICATION_ERRORS=0

echo "Verifying subtopic reports..."

for subtopic in "${!SUBTOPIC_REPORT_PATHS[@]}"; do
  EXPECTED_PATH="${SUBTOPIC_REPORT_PATHS[$subtopic]}"

  if [ -f "$EXPECTED_PATH" ]; then
    echo "✓ Verified: $subtopic at $EXPECTED_PATH"
    VERIFIED_PATHS["$subtopic"]="$EXPECTED_PATH"
  else
    echo "⚠ ERROR: Report not found at $EXPECTED_PATH"
    VERIFICATION_ERRORS=$((VERIFICATION_ERRORS + 1))

    # Fallback: Extract from agent output if available
    echo "  → Executing fallback creation..."
    # [Fallback logic here]
  fi
done

if [ "$VERIFICATION_ERRORS" -gt 0 ]; then
  echo "⚠ Warning: $VERIFICATION_ERRORS reports required fallback"
fi

echo "✓ All subtopic reports verified (${#VERIFIED_PATHS[@]}/${#SUBTOPICS[@]})"
```

**CHECKPOINT**:
```
CHECKPOINT: Report verification complete
- Expected reports: ${#SUBTOPIC_REPORT_PATHS[@]}
- Verified reports: ${#VERIFIED_PATHS[@]}
- Fallback creations: $VERIFICATION_ERRORS
- Status: Ready for synthesis
- Proceeding to: Overview synthesis
```
```

**Impact**: ✅ Guarantees report creation via verification + fallback

### Option 2: Create Wrapper Script (Alternative)

**Approach**: Create a bash script that executes the hierarchical pattern, invoke via Bash tool.

**File**: `.claude/lib/report-orchestrator.sh`

```bash
#!/usr/bin/env bash
# Report Orchestration Script
# Executes hierarchical multi-agent research pattern

set -euo pipefail

RESEARCH_TOPIC="${1:-}"

if [ -z "$RESEARCH_TOPIC" ]; then
  echo "Usage: report-orchestrator.sh <research-topic>" >&2
  exit 1
fi

# Phase 1: Topic Decomposition
source "${CLAUDE_PROJECT_DIR}/.claude/lib/topic-decomposition.sh"
SUBTOPIC_COUNT=$(calculate_subtopic_count "$RESEARCH_TOPIC")
SUBTOPICS=($(decompose_topic "$RESEARCH_TOPIC" "$SUBTOPIC_COUNT"))

# Phase 2: Path Pre-calculation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
TOPIC_DIR=$(get_or_create_topic_dir "$RESEARCH_TOPIC" ".claude/specs")
declare -A SUBTOPIC_REPORT_PATHS

for subtopic in "${SUBTOPICS[@]}"; do
  REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "$subtopic" "")
  SUBTOPIC_REPORT_PATHS["$subtopic"]="$REPORT_PATH"
done

# Phase 3-5: Return JSON for Claude to execute
jq -n \
  --arg topic_dir "$TOPIC_DIR" \
  --argjson subtopics "$(printf '%s\n' "${SUBTOPICS[@]}" | jq -R . | jq -s .)" \
  --argjson paths "$(for st in "${SUBTOPICS[@]}"; do
    echo "${SUBTOPIC_REPORT_PATHS[$st]}"
  done | jq -R . | jq -s .)" \
  '{
    topic_dir: $topic_dir,
    subtopics: $subtopics,
    report_paths: $paths,
    next_step: "invoke_research_agents"
  }'
```

**Command Change**:
```markdown
### 1.5. Topic Decomposition and Path Calculation

**EXECUTE NOW - Run Report Orchestrator**

```bash
ORCHESTRATION_DATA=$(bash .claude/lib/report-orchestrator.sh "$ARGUMENTS")

TOPIC_DIR=$(echo "$ORCHESTRATION_DATA" | jq -r '.topic_dir')
SUBTOPICS=($(echo "$ORCHESTRATION_DATA" | jq -r '.subtopics[]'))
# ... extract paths
```

**Then proceed to Task invocations...**
```

**Pros**:
- ✅ Bash execution guaranteed (single Bash tool call)
- ✅ Less reliance on Claude interpreting instructions
- ✅ Testable independently

**Cons**:
- ❌ Adds complexity (new script file)
- ❌ Still requires Claude to use Task tool for agents
- ❌ Doesn't fix the core issue (command interpretation)

### Option 3: Hybrid Approach (Most Robust)

**Combine**:
1. **Enforcement language** from Option 1 (clarify Claude's orchestrator role)
2. **Bash utilities** from Option 2 (guarantee phase 1-2 execution)
3. **Explicit Task templates** with variable substitution

**Benefits**:
- ✅ Best of both approaches
- ✅ Maximizes execution reliability
- ✅ Maintains hierarchical architecture integrity

## Recommendations

### Immediate Action (Critical)

#### 1. Add Opening Clarification (5 minutes)

**File**: `.claude/commands/report.md` line 11

**Change**:
```markdown
- I'll research the specified topic and create a comprehensive report in the most appropriate location.
+ I'll orchestrate hierarchical research by delegating to specialized subagents.

+ **YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.
+
+ **CRITICAL INSTRUCTIONS**:
+ - DO NOT execute research yourself using Read/Grep/Write tools
+ - ONLY use Task tool to delegate research to research-specialist agents
+ - Your job: decompose topic → invoke agents → verify outputs → synthesize
+
+ You will NOT see research findings directly. Agents will create report files,
+ and you will read those files after creation.
```

**Impact**: ✅ Prevents Claude from executing research directly

**Test**: Run `/report "test topic"` - verify Claude uses Task tool, not Read/Write for research

#### 2. Add Execution Enforcement to Section 1.5 (15 minutes)

Apply "Change 2" from Option 1 (add "EXECUTE NOW", imperatives, verification, checkpoints)

**Impact**: ✅ Forces bash execution for topic decomposition and path calculation

**Test**: Verify bash commands are executed (check for sourced utilities, calculated paths)

#### 3. Make Task Invocations Explicit (20 minutes)

Apply "Change 3" from Option 1 (explicit Task blocks with variable substitution)

**Impact**: ✅ Removes ambiguity about whether/how to invoke agents

**Test**: Verify Task tool invocations appear in output (multiple agents, single message)

### Next Iteration (Important)

#### 4. Add Verification and Fallback (15 minutes)

Apply "Change 4" from Option 1 (post-agent verification with fallback)

**Impact**: ✅ Guarantees report creation even with agent non-compliance

#### 5. Add Metadata Extraction (10 minutes)

Per compliance analysis report:
```bash
# After report verification
source "${CLAUDE_PROJECT_DIR}/.claude/lib/metadata-extraction.sh"

for subtopic in "${!VERIFIED_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "${VERIFIED_PATHS[$subtopic]}")
  # Store metadata, not full content
done
```

**Impact**: ✅ Achieves 99% context reduction

#### 6. Add Context Pruning (10 minutes)

Per compliance analysis report:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/context-pruning.sh"

for i in {1..${#SUBTOPICS[@]}}; do
  prune_subagent_output "research_specialist_$i"
done
```

**Impact**: ✅ Achieves <30% context usage target

### Future Enhancement (Optional)

#### 7. Create Bash Orchestrator Utility

Implement Option 2 approach for phases 1-2 (decomposition + path calculation)

**Impact**: ✅ Increased reliability for preparatory phases

## Next Steps

### Immediate (Today)

1. ✅ Create this debug report
2. Implement Recommendation #1 (opening clarification) - 5 min
3. Test `/report "simple topic"` - verify orchestrator behavior
4. If test passes: Implement Recommendation #2-3 - 35 min
5. If test passes: Implement Recommendation #4-6 - 35 min

**Total Time**: ~1.5 hours for complete fix

### Validation (After Implementation)

**Test 1**: Simple topic
```bash
/report "Authentication patterns in codebase"
```
Expected:
- Topic decomposed into 2-3 subtopics
- Multiple Task invocations (research-specialist agents)
- Subtopic reports created (001_*.md, 002_*.md, ...)
- OVERVIEW.md synthesis created
- Metadata extraction executed

**Test 2**: Complex topic
```bash
/report "Comprehensive system architecture analysis including security, performance, and scalability"
```
Expected:
- Topic decomposed into 4 subtopics
- 4 parallel research agents invoked
- Verification + fallback for all reports
- Synthesis with cross-cutting themes
- Context pruning achieving >90% reduction

**Test 3**: Failure scenarios
```bash
# Simulate agent non-compliance
# (Manually break research-specialist.md temporarily)
/report "Test topic"
```
Expected:
- Fallback creation triggers
- All reports still created (via fallback)
- Warning messages about fallback usage
- Synthesis still succeeds

## References

### Command Files
- `.claude/commands/report.md:11` - Opening statement (root cause)
- `.claude/commands/report.md:25-64` - Topic decomposition section
- `.claude/commands/report.md:144-200` - Research agent invocation
- `.claude/commands/orchestrate.md` - Similar pattern (may have same issue)

### Standards Documentation
- `.claude/docs/reference/command_architecture_standards.md` - Standard 0 (Execution Enforcement)
- `.claude/docs/concepts/hierarchical_agents.md` - Hierarchical pattern specification

### Utility Libraries
- `.claude/lib/topic-decomposition.sh` - Topic decomposition utilities
- `.claude/lib/metadata-extraction.sh` - Metadata extraction (99% reduction)
- `.claude/lib/context-pruning.sh` - Context reduction utilities

### Related Reports
- `.claude/specs/002_report_creation/reports/002_report_command_compliance_analysis.md` - Compliance analysis

### Test Evidence
- `.claude/specs/002_report_creation/example_3.md` - Actual execution showing direct research (not orchestration)

## Appendix: Execution Flow Comparison

### Current (Broken) Flow

```
User: /report "topic"
  ↓
Claude reads report.md
  ↓
Claude sees: "I'll research the specified topic..."
  ↓
Claude interprets: "I should research this topic myself"
  ↓
Claude uses: Read, Grep, Write tools directly
  ↓
Claude creates: Single report file
  ↓
Result: ❌ No subagents, no hierarchy, no parallelization
```

### Expected (Fixed) Flow

```
User: /report "topic"
  ↓
Claude reads report.md
  ↓
Claude sees: "I'll ORCHESTRATE research by delegating..."
  ↓
Claude sees: "EXECUTE NOW - Source utilities and decompose topic"
  ↓
Claude runs: bash commands (source utilities, decompose)
  ↓
Claude sees: "EXECUTE NOW - Invoke research-specialist agents"
  ↓
Claude sends: Multiple Task invocations (single message, parallel)
  ↓
Agents execute: Research in parallel
  ↓
Agents create: Individual subtopic reports
  ↓
Claude sees: "EXECUTE NOW - Verify all reports created"
  ↓
Claude runs: Verification + fallback (if needed)
  ↓
Claude sees: "EXECUTE NOW - Invoke research-synthesizer agent"
  ↓
Synthesizer creates: OVERVIEW.md
  ↓
Claude runs: Metadata extraction, context pruning
  ↓
Result: ✅ Hierarchical pattern, parallelization, context reduction
```

### Key Difference

**Current**: Claude acts as **executor** (does research itself)
**Expected**: Claude acts as **orchestrator** (delegates to agents)

The fix is to **explicitly state Claude's orchestrator role** and use **execution enforcement** (imperatives, "EXECUTE NOW", verification) to guarantee the hierarchical pattern is followed.

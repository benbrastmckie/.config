# Agent Delegation Troubleshooting Guide

This unified guide helps diagnose and fix all agent delegation issues where commands fail to properly invoke specialized agents.

**Quick Navigation**:
- [Quick Diagnosis Decision Tree](#quick-diagnosis-decision-tree) - Start here
- [Root Cause Analysis](#root-cause-analysis) - Deep dive into specific problems
- [Prevention Guidelines](#prevention-guidelines) - Avoid issues in new commands
- [Case Studies](#case-studies) - Real-world examples

---

## Quick Diagnosis Decision Tree

Follow this flowchart to identify your issue:

```
START: Do you see Task tool invocations in command output?
  ├─ NO → [Issue A: Command Not Delegating](#issue-a-command-executes-directly-no-delegation)
  └─ YES → Are artifacts created at expected paths?
      ├─ NO → [Issue B: Path Mismatch](#issue-b-artifact-created-at-wrong-location)
      └─ YES → Is delegation rate 100%?
          ├─ NO (0%) → [Issue C: Delegation Failure](#issue-c-delegation-failure-0-rate)
          └─ YES → Is context usage <30%?
              ├─ NO → [Issue D: Context Bloat](#issue-d-context-reduction-not-achieved)
              └─ YES → All working! Check [Prevention](#prevention-guidelines)
```

**Quick Symptom Checker**:
| Symptom | Issue Type | Fix Time |
|---------|-----------|----------|
| No Task invocations visible | [A: No Delegation](#issue-a-command-executes-directly-no-delegation) | 10-25 min |
| "REPORT_CREATED:" but file not found | [B: Path Mismatch](#issue-b-artifact-created-at-wrong-location) | 5-15 min |
| Task invocations but 0% success | [C: Delegation Failure](#issue-c-delegation-failure-0-rate) | 15-30 min |
| Context usage >50% with agents | [D: Context Bloat](#issue-d-context-reduction-not-achieved) | 10-20 min |
| "streaming fallback triggered" errors | [C: Delegation Failure](#issue-c-delegation-failure-0-rate) | 15-30 min |
| Agent invokes SlashCommand | [E: Recursion Risk](#issue-e-recursion-risk-slash-command-invocation) | 5-10 min |
| Flat artifact structure (specs/reports/*.md) | [F: Topic Organization](#issue-f-artifacts-not-in-topic-directories) | 15-25 min |

---

## Root Cause Analysis

### Issue A: Command Executes Directly (No Delegation)

**Severity**: High | **Fix Time**: 10-25 minutes

#### Symptoms

- Command uses Read/Write/Grep/Edit tools **directly** for agent tasks
- **No Task tool invocations** visible in command output
- **Single artifact** created instead of multiple subtopic artifacts
- No progress markers from subagents (e.g., "PROGRESS: Starting research...")
- No "REPORT_CREATED:" or similar agent return messages
- Execution completes faster than expected (no parallel processing)

#### Example Output Comparison

**Broken Command** (not delegating):
```
● /report is running…
● Read(.claude/commands/report.md)
● Read(.claude/docs/concepts/hierarchical-agents.md)
● Glob(pattern: ".claude/agents/*.md")
● Read(.claude/agents/research-specialist.md)
● Write(reports/001_analysis.md)  ← Direct write, no agent
```

**Working Command** (delegating):
```
● /report is running…
● Bash(source .claude/lib/plan/topic-decomposition.sh && ...)
● Task(research-specialist) - Research auth_patterns
● Task(research-specialist) - Research oauth_flows
● Task(research-specialist) - Research session_mgmt
[Agents execute in parallel]
● Task(research-synthesizer) - Synthesize findings
● Read(reports/001_research/OVERVIEW.md)  ← Reading agent output
```

#### Root Cause

**Pattern**: Command opening uses ambiguous first-person language: "I'll [task verb]..."

Claude interprets this as "I (Claude) should [task]" rather than "I'll orchestrate agents to [task]"

**Examples**:
- ❌ "I'll research the specified topic..." → Claude researches directly
- ❌ "I'll implement the feature..." → Claude implements directly
- ❌ "I'll analyze the codebase..." → Claude analyzes directly
- ❌ "I'll create a plan..." → Claude creates plan directly (no agent delegation)

#### Quick Fix

**Step 1: Update Command Opening (5 minutes)**

Find (example pattern):
```markdown
# [Command Name]

I'll [task verb] the [object]...

## [Section]
$ARGUMENTS
```

Replace with:
```markdown
# [Command Name]

I'll orchestrate [task noun] by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the [executor/researcher/implementer].

**CRITICAL INSTRUCTIONS**:
- DO NOT execute [task] yourself using [Read/Write/Grep/Edit] tools
- ONLY use Task tool to delegate [task] to [agent-type] agents
- Your job: [orchestration steps: decompose → invoke → verify → synthesize]

You will NOT see [task results] directly. Agents will create [artifacts],
and you will [action: read/verify/extract metadata] after creation.

## [Section]
$ARGUMENTS
```

**Step 2: Add Execution Enforcement to Sections (5 minutes)**

Find:
```markdown
### 1. [Task Step]

[Description of what to do]:
```

Replace with:
```markdown
### STEP 1 (REQUIRED BEFORE STEP 2) - [Task Step]

**EXECUTE NOW - [Imperative Action]**

YOU MUST run this code block NOW:
```

#### Verification

After fix, check for:

✅ **Task tool invocations**:
```
● Task(subagent_type: "general-purpose")
  description: "Research [subtopic] with mandatory file creation"
```

✅ **Multiple agents** (if parallel pattern):
```
● Task(research-specialist) - Research subtopic_1
● Task(research-specialist) - Research subtopic_2
```

✅ **Agent return messages**:
```
Agent output: REPORT_CREATED: /path/to/report.md
```

#### Related Resources

- [Execution Enforcement Migration Guide](../guides/patterns/execution-enforcement/execution-enforcement-overview.md)
- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md)

---

### Issue B: Artifact Created at Wrong Location

**Severity**: Medium | **Fix Time**: 5-15 minutes

#### Symptoms

- Command expects artifact at `specs/042_feature/reports/042_research.md`
- Artifact actually created at different path (e.g., `specs/reports/042_research.md`)
- `verify_artifact_or_recover()` returns error
- "Artifact not found" errors in command output

#### Diagnosis

**Step 1: Check where artifact was created**
```bash
find specs -name "*research*.md" -type f
```

**Step 2: Check if command pre-calculated path**
```bash
grep -n "create_topic_artifact\|ARTIFACT_PATH\|REPORT_PATH\|PLAN_PATH" \
  .claude/commands/COMMAND_NAME.md | head -10
```

If no results, command is not using topic-based path calculation.

**Step 3: Check agent behavioral file**
```bash
grep -n "ARTIFACT_PATH\|REPORT_PATH\|PLAN_PATH" .claude/agents/AGENT_NAME.md
```

If agent doesn't reference these variables, it may be calculating its own paths.

#### Solution

**Option 1: Use `verify_artifact_or_recover()` with recovery**

```bash
# After agent invocation
EXPECTED_PATH="specs/042_feature/reports/042_research.md"
ACTUAL_PATH=$(verify_artifact_or_recover "$EXPECTED_PATH" "research")

if [[ -f "$ACTUAL_PATH" ]]; then
  echo "Recovered artifact at: $ACTUAL_PATH"
  METADATA=$(extract_report_metadata "$ACTUAL_PATH")
else
  echo "ERROR: Artifact not found even with recovery"
  exit 1
fi
```

**Option 2: Fix command to pre-calculate path**

```bash
# Add path calculation before agent invocation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")

# Pass path to agent
Task {
  prompt: |
    **Report Output Path**: ${REPORT_PATH}
    Create report at this EXACT path.
}
```

**Option 3: Fix agent to use provided path**

```markdown
# Agent behavioral file
## Step 2: Create Report

Use the **Report Output Path** provided in your context.

Write {
  file_path: "${REPORT_PATH}"  # Use exact path from context
  content: |
    # Research Report
    ...
}
```

#### Verification

```bash
# Verify artifact at expected path
[[ -f "$EXPECTED_PATH" ]] && echo "✅ Artifact found" || echo "❌ Artifact not found"

# Verify topic-based organization
ls -R specs/042_feature/
# Should show: reports/, plans/, summaries/ subdirectories
```

#### Related Resources

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

---

### Issue C: Delegation Failure (0% Rate)

**Severity**: Critical | **Fix Time**: 15-30 minutes

#### Symptoms

**Primary Symptoms**:
- **0% delegation rate**: Task invocations never execute
- **Silent failure**: No error messages, command appears to work
- **"streaming fallback triggered" errors**: Recovery mechanism masks issue
- **Missing artifacts**: Expected reports/plans not created at calculated paths
- **Parallel execution disabled**: Agents never initialize

**Secondary Symptoms**:
- Context usage >80% (should be <30%)
- Sequential execution only (parallel features don't work)
- File creation rate 0% (agents don't create files)

#### Root Causes

##### Cause 1: Code Fence Priming Effect

**Description**: Code-fenced Task invocation examples (` ```yaml ... ``` `) establish a "documentation interpretation" pattern that causes Claude to treat subsequent unwrapped Task blocks as non-executable examples.

**Detection**:
```bash
# Check for code-fenced Task examples
grep -n '```yaml' .claude/commands/*.md | while read match; do
  file=$(echo "$match" | cut -d: -f1)
  line=$(echo "$match" | cut -d: -f2)

  # Check if Task invocation follows
  sed -n "$((line+1)),$((line+15))p" "$file" | grep -q "Task {" && \
    echo "Potential priming effect: $file:$line"
done
```

**Solution**:
1. Remove code fences from Task invocation examples
2. Add HTML comment for clarity: `<!-- This Task invocation is executable -->`
3. Keep anti-pattern examples (marked with ❌) code-fenced to prevent execution
4. Verify fix with test suite

```bash
# Before fix
**Example**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

# After fix
**Example**:

<!-- This Task invocation is executable -->
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

**Verification**:
```bash
# Run validation test
bash .claude/tests/test_supervise_agent_delegation.sh

# Expected: All tests pass, 100% delegation rate
```

**Real-World Case**: Spec 469 - /supervise command had single code-fenced example at lines 62-79, causing 0% delegation for all 10 Task invocations later in file.

##### Cause 2: Tool Access Mismatch

**Description**: Agent behavioral files missing required tools (especially Bash) in frontmatter `allowed-tools` list, preventing proper initialization.

**Detection**:
```bash
# Check if Bash is in all agent allowed-tools
for agent in .claude/agents/*.md; do
  if ! grep -q "allowed-tools:.*Bash" "$agent"; then
    echo "Missing Bash in: $(basename $agent)"
  fi
done
```

**Solution**:

Add missing tools to agent frontmatter:

```yaml
---
allowed-tools: Read, Write, Grep, Glob, WebSearch, WebFetch, Bash
description: Specialized agent description
---
```

**Why Bash is Required**:
- Agents use bash for library sourcing (e.g., `source .claude/lib/workflow/metadata-extraction.sh`)
- Verification checkpoints require bash commands
- File path validation uses bash utilities

**Verification**:
```bash
# Verify all agents have Bash
grep -l "allowed-tools:" .claude/agents/*.md | xargs grep "Bash"

# Expected: All agent files show Bash in allowed-tools
```

**Real-World Case**: Spec 469 - 3 of 6 agent files (research-specialist.md, plan-architect.md, doc-writer.md) were missing Bash, contributing to 0% delegation rate.

##### Cause 3: Documentation-Only YAML Blocks

**Description**: Task invocations wrapped in ` ```yaml` code blocks without imperative instructions, causing Claude to interpret them as syntax examples.

**Detection**:
```bash
# Find YAML blocks in command files
grep -n '```yaml' .claude/commands/*.md

# For each match, check if preceded by imperative instruction:
# - "EXECUTE NOW" within 5 lines → Executable ✓
# - No imperative marker → Documentation-only ❌
```

**Solution**:

Convert documentation-only blocks to executable pattern:

```markdown
# Before (Documentation-only)
Example agent invocation:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "..."
}
```

# After (Executable)
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

**Verification**:

Ensure all Task invocations have:
- Imperative instruction marker (`**EXECUTE NOW**`)
- Reference to behavioral file (`.claude/agents/*.md`)
- Explicit completion signal (e.g., `REPORT_CREATED:`)

**Real-World Case**: Spec 438 - /supervise command had 7 YAML blocks wrapped in code fences, causing 0% delegation rate.

##### Cause 4: Code-Fenced Bash Blocks (Library Sourcing)

**Description**: Bash code blocks (` ```bash ... ``` `) around library sourcing commands create ambiguity about whether commands should execute.

**Detection**:
```bash
# Check if library sourcing region has code fences
sed -n '210,280p' .claude/commands/supervise.md | grep -c '```bash'

# Expected: 0 (no code fences in library sourcing region)
```

**Solution**:

Remove code fences from library sourcing blocks:

```bash
# Before
**Source Required Libraries**

```bash
source "$SCRIPT_DIR/../lib/core/unified-location-detection.sh"
source "$SCRIPT_DIR/../lib/workflow/metadata-extraction.sh"
```

# After
**EXECUTE NOW - Source Required Libraries**

source "$SCRIPT_DIR/../lib/core/unified-location-detection.sh"
source "$SCRIPT_DIR/../lib/workflow/metadata-extraction.sh"
```

**Verification**:
```bash
# Check library sourcing region (adjust line numbers per command)
sed -n '210,280p' .claude/commands/supervise.md | grep '```bash'

# Expected: No output (no code fences)
```

#### Diagnostic Workflow

**Step 1: Identify Symptoms**

Run validation test to measure delegation rate:
```bash
bash .claude/tests/test_supervise_agent_delegation.sh
```

If delegation rate is 0%, proceed to Step 2.

**Step 2: Check Code Fences**

```bash
# Count YAML code fences
grep -c '```yaml' .claude/commands/your-command.md

# Count bash code fences in library regions
sed -n '200,300p' .claude/commands/your-command.md | grep -c '```bash'
```

If counts > 0 (excluding legitimate anti-pattern examples), you likely have priming effect or documentation-only issues.

**Step 3: Check Tool Access**

```bash
# Verify all agents have Bash
for agent in .claude/agents/*.md; do
  grep "allowed-tools:" "$agent" | grep -q "Bash" || echo "Missing: $agent"
done
```

If any agents missing Bash, add it to frontmatter.

**Step 4: Check Imperative Instructions**

```bash
# Find Task invocations without imperative markers
grep -B5 "Task {" .claude/commands/your-command.md | \
  grep -v "EXECUTE NOW\|USE the Task tool" | \
  grep "Task {"
```

If Task invocations found without imperative markers, add them.

**Step 5: Apply Fixes**

Based on findings above:

1. **Remove code fences** from Task examples
2. **Add Bash** to agent frontmatter
3. **Add imperative instructions** to Task invocations
4. **Unwrap library sourcing** bash blocks

**Step 6: Validate Fix**

```bash
# Re-run validation test
bash .claude/tests/test_supervise_agent_delegation.sh

# Expected metrics:
# - Delegation rate: 100%
# - Context usage: <30%
# - No streaming fallback errors
# - All artifacts created at expected paths
```

#### Related Resources

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 11

---

### Issue D: Context Reduction Not Achieved

**Severity**: Medium | **Fix Time**: 10-20 minutes

#### Symptoms

- Context usage still >50% after subagent delegation
- Expected 95% reduction, got <50% reduction
- Commands slow or hitting context limits
- Full artifact content appears in logs/outputs

#### Diagnosis

**Step 1: Check if metadata extraction is used**
```bash
grep -n "extract_report_metadata\|extract_plan_metadata\|extract_debug_metadata" \
  .claude/commands/COMMAND_NAME.md
```

If no results, command is not extracting metadata.

**Step 2: Check for full content loading**
```bash
grep -n "cat.*REPORT\|cat.*PLAN\|Read.*file_path.*REPORT" \
  .claude/commands/COMMAND_NAME.md
```

If results found, command is loading full content (context bloat).

**Step 3: Check metadata summary length**
```bash
source .claude/lib/workflow/metadata-extraction.sh
METADATA=$(extract_report_metadata "$REPORT_PATH")
SUMMARY=$(echo "$METADATA" | jq -r '.summary')
WORD_COUNT=$(echo "$SUMMARY" | wc -w)

echo "Summary word count: $WORD_COUNT (should be ≤50)"
```

#### Solution

**Fix 1: Extract metadata only (not full content)**

```bash
# WRONG: Loading full content
FULL_REPORT=$(cat "$REPORT_PATH")  # ❌ 5000 tokens

# CORRECT: Extract metadata only
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/metadata-extraction.sh"
METADATA=$(extract_report_metadata "$REPORT_PATH")  # ✅ 250 tokens
SUMMARY=$(echo "$METADATA" | jq -r '.summary')  # ≤50 words
```

**Fix 2: Prune subagent outputs after metadata extraction**

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/context-pruning.sh"

# After subagent completes
METADATA=$(extract_report_metadata "$REPORT_PATH")

# Prune full output immediately
prune_subagent_output "subagent_id"

# Now only metadata retained in memory
```

**Fix 3: Verify metadata summaries are ≤50 words**

If summaries are too long, update metadata extraction:

```bash
# In .claude/lib/workflow/metadata-extraction.sh
# Ensure summary truncation to 50 words
SUMMARY=$(echo "$FULL_SUMMARY" | head -c 300 | sed 's/\s\S*$/.../')
```

#### Verification

**Measure context reduction**:
```bash
# Before subagent invocation
CONTEXT_BEFORE=5000  # tokens (example)

# After metadata extraction and pruning
CONTEXT_AFTER=250  # tokens (example)

# Calculate reduction
REDUCTION=$((100 - (CONTEXT_AFTER * 100 / CONTEXT_BEFORE)))
echo "Context reduction: ${REDUCTION}%"
# Expected: ≥90%
```

**Run context reduction validator**:
```bash
.claude/lib/# validate-context-reduction.sh (removed)
# Expected: All tests passing with ≥90% reduction
```

#### Related Resources

- [Hierarchical Agents: Metadata Extraction](../concepts/hierarchical-agents.md#metadata-extraction)
- [Context Management Pattern](../concepts/patterns/context-management.md)

---

### Issue E: Recursion Risk (Slash Command Invocation)

**Severity**: High | **Fix Time**: 5-10 minutes

#### Symptoms

- Agent output contains "Using SlashCommand tool to invoke /plan"
- Unexpected command execution during agent run
- Recursive delegation warnings in logs
- Artifact created but at unexpected path
- Cannot verify artifact location (path unknown)
- Stack overflow or max recursion depth errors
- "Circular delegation chain detected" warnings
- Command execution never completes

#### Diagnosis

**Step 1: Check agent behavioral file**
```bash
grep -n "SlashCommand\|invoke.*slash\|use.*command" .claude/agents/AGENT_NAME.md
```

**Step 2: Run anti-pattern detector**
```bash
.claude/tests/validate_no_agent_slash_commands.sh
```

Expected output if problem exists:
```
❌ VIOLATION: plan-architect.md contains SlashCommand invocation
64:  ABSOLUTE REQUIREMENT: YOU MUST use SlashCommand to invoke /plan
```

**Step 3: Check command → agent → command pattern**
```bash
# In /implement command
grep -n "code-writer" .claude/commands/implement.md

# In code-writer agent
grep -n "/implement" .claude/agents/code-writer.md

# If both found, recursion risk exists:
# /implement → code-writer → /implement → ...
```

#### Solution

**Fix 1: Remove SlashCommand instructions from agent**

```markdown
# WRONG (before fix):
## Step 1: Create Plan

YOU MUST use SlashCommand to invoke /plan:

SlashCommand {
  command: "/plan ${FEATURE_DESCRIPTION}"
}
```

```markdown
# CORRECT (after fix):
## Step 1: Create Plan at Provided Path

You will receive a pre-calculated **Plan Output Path**.

Use Write tool to create plan:

Write {
  file_path: "${PLAN_PATH}"
  content: |
    # Implementation Plan
    ...
}

Return metadata: {path, phase_count, complexity_score}
```

**Fix 2: Update command to inject behavioral context**

```bash
# Command pre-calculates path
PLAN_PATH=$(create_topic_artifact "$TOPIC_DIR" "plans" "implementation" "")

# Command injects complete context
Task {
  prompt: |
    **Plan Output Path**: ${PLAN_PATH}
    Create plan at exact path provided.
}
```

**Fix 3: Clarify agent role**

```markdown
# Agent behavioral file
## Role Clarification

You are invoked BY the /implement command to EXECUTE tasks.

You receive:
- Specific code change TASKS (not plan file paths)
- File paths to modify
- Expected changes

You execute using:
- Read tool (to read existing files)
- Edit tool (to modify files)
- Write tool (to create new files)

You DO NOT:
- Invoke /implement (that invoked YOU)
- Parse plan files (that's /implement's job)

## CRITICAL: Do NOT Invoke Slash Commands

**NEVER** use the SlashCommand tool to invoke:
- /implement (recursion risk - YOU are invoked BY /implement)
- /plan (plan creation is /plan command's responsibility)

**ALWAYS** use Read/Write/Edit tools to modify code directly.
```

#### Verification

```bash
# Verify agent no longer contains SlashCommand
grep -c "SlashCommand" .claude/agents/AGENT_NAME.md
# Expected: 0

# Verify command pre-calculates path
grep -n "create_topic_artifact.*plans" .claude/commands/COMMAND_NAME.md
# Should find path calculation before Task invocation

# Run recursion test
.claude/tests/test_code_writer_no_recursion.sh
# Expected: All tests passing, 0 recursion risks
```

#### Related Resources

- [Agent Development Guide: What Agents Should NOT Do](../guides/development/agent-development/agent-development-fundamentals.md#what-agents-should-not-do)
- [Behavioral Injection Anti-Patterns](../concepts/patterns/behavioral-injection.md#anti-patterns)

---

### Issue F: Artifacts Not in Topic Directories

**Severity**: Medium | **Fix Time**: 15-25 minutes

#### Symptoms

- Artifacts created in flat structure: `specs/reports/042_research.md`
- Not in topic directories: `specs/042_feature/reports/042_research.md`
- Difficult to find all artifacts for a feature
- `validate_topic_based_artifacts.sh` reports violations
- Inconsistent numbering across artifact types

#### Diagnosis

**Step 1: Check current artifact locations**
```bash
# Check for flat structure (incorrect)
find specs -maxdepth 2 -name "*.md" -type f
# If results show specs/reports/*.md or specs/plans/*.md → WRONG

# Check for topic structure (correct)
find specs -maxdepth 3 -name "*.md" -type f
# Should show specs/NNN_topic/reports/*.md pattern
```

**Step 2: Run topic-based artifact validator**
```bash
.claude/tests/validate_topic_based_artifacts.sh
```

Expected output if problem exists:
```
❌ VIOLATION: Artifact in flat structure
  specs/reports/042_research.md
  Should be: specs/042_feature/reports/042_research.md
```

**Step 3: Check if command uses `create_topic_artifact()`**
```bash
grep -n "create_topic_artifact\|get_or_create_topic_dir" \
  .claude/commands/COMMAND_NAME.md

# If no results, command not using topic-based utilities
```

#### Solution

**Fix 1: Use `create_topic_artifact()` for all artifact paths**

```bash
# WRONG: Manual path construction
REPORT_PATH="specs/reports/042_research.md"  # ❌ Flat structure

# CORRECT: Topic-based path calculation
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$FEATURE_DESCRIPTION" "specs")
REPORT_PATH=$(create_topic_artifact "$TOPIC_DIR" "reports" "research" "")
# Result: specs/042_user_authentication/reports/042_research.md ✅
```

**Fix 2: Migrate existing flat artifacts to topic structure**

```bash
#!/usr/bin/env bash
# migrate_to_topic_structure.sh

# Find all flat artifacts
FLAT_REPORTS=$(find specs/reports -maxdepth 1 -name "*.md" 2>/dev/null)

for report in $FLAT_REPORTS; do
  # Extract number and name
  FILENAME=$(basename "$report")
  NUMBER=$(echo "$FILENAME" | grep -oP '^\d{3}')
  NAME=$(echo "$FILENAME" | sed 's/^[0-9]*_//' | sed 's/\.md$//')

  # Create topic directory
  TOPIC_DIR="specs/${NUMBER}_${NAME}"
  mkdir -p "$TOPIC_DIR/reports"

  # Move artifact
  mv "$report" "$TOPIC_DIR/reports/"
  echo "Migrated: $report → $TOPIC_DIR/reports/$FILENAME"
done
```

**Fix 3: Ensure agents use provided topic-based paths**

```markdown
# Agent behavioral file
## Step 1: Receive Pre-Calculated Path

You will receive:
- **Report Output Path**: Topic-based path (e.g., specs/042_feature/reports/042_research.md)

## Step 2: Create Artifact at Exact Path

Use Write tool with EXACT path provided:

Write {
  file_path: "${REPORT_PATH}"  # From context, already topic-based
  content: |
    # Research Report
    ...
}

DO NOT construct your own path. Use the path provided.
```

#### Verification

**Verify topic-based organization**:
```bash
# Check artifact locations
ls -R specs/

# Should show structure:
# specs/042_feature/
#   ├── reports/
#   │   └── 042_research.md
#   ├── plans/
#   │   └── 042_implementation.md
#   └── summaries/
#       └── 042_workflow_summary.md

# Run validator
.claude/tests/validate_topic_based_artifacts.sh
# Expected: 0 violations
```

**Verify sequential numbering within topic**:
```bash
# All artifacts in same topic share base number
ls specs/042_user_authentication/reports/
# 042_oauth_security.md
# 043_database_design.md
# 044_best_practices.md
```

#### Related Resources

- [Directory Protocols](.claude/docs/concepts/directory-protocols.md)
- [Artifact Creation Utilities](.claude/lib/artifact/artifact-creation.sh)

---

## Prevention Guidelines

### Command Development Best Practices

Follow these guidelines when creating new commands:

1. **Never wrap executable Task invocations in code fences**
   - Use HTML comments for annotations: `<!-- This Task invocation is executable -->`
   - Move complex examples to external reference files (`.claude/docs/patterns/`)

2. **Always add imperative instruction markers**
   - Use `**EXECUTE NOW**: USE the Task tool...` before Task blocks
   - Make execution intent explicit

3. **Ensure tool access matches usage**
   - If command uses bash, add Bash to allowed-tools
   - If agent sources libraries, Bash is required
   - Audit tool requirements across all bash code blocks

4. **Test delegation rate early and often**
   - Create validation tests during development
   - Run tests after adding Task examples
   - Monitor delegation rate in production

5. **Always pre-calculate paths** before agent invocation

6. **Always extract metadata only** (not full content)

7. **Never allow agents to invoke slash commands** for artifact creation

8. **Always use topic-based utilities** (`create_topic_artifact()`)

9. **Always verify compliance** with validators

10. **Follow established patterns**
    - Study working commands (e.g., /orchestrate, /research)
    - Reference [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md)
    - Follow [Standard 11: Imperative Agent Invocation](../reference/architecture/overview.md#standard-11)

### Code Review Checklist

Before merging command file changes:

- [ ] All Task invocations have imperative markers (`**EXECUTE NOW**`)
- [ ] No code fences around executable Task blocks
- [ ] All agents have required tools in allowed-tools frontmatter
- [ ] Library sourcing blocks unwrapped (no ` ```bash` fences)
- [ ] Validation test created and passing
- [ ] Delegation rate verified at 100%
- [ ] Command opening clarifies orchestrator role
- [ ] Paths pre-calculated using topic-based utilities
- [ ] Metadata extraction used (not full content loading)
- [ ] Agents don't invoke slash commands

### Quick Reference Template

**Copy-paste template for command openings**:

```markdown
# [Command Name]

I'll orchestrate [task] by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the [executor].

**CRITICAL INSTRUCTIONS**:
- DO NOT execute [task] yourself using [tool-list] tools
- ONLY use Task tool to delegate [task] to [agent-type] agents
- Your job: [step1] → [step2] → [step3] → [step4]

You will NOT see [results] directly. Agents will create [artifacts],
and you will [action] after creation.

## [Description Section]
$ARGUMENTS

## Process

### STEP 1 (REQUIRED BEFORE STEP 2) - [First Step]

**EXECUTE NOW - [Imperative Action]**

YOU MUST run this code block NOW:

```bash
# Actual executable bash code here
```

**CHECKPOINT**:
```
CHECKPOINT: [Step] complete
- [Metric 1]: [value]
- [Metric 2]: [value]
- Proceeding to: [Next step]
```

### STEP 2 (REQUIRED AFTER STEP 1) - [Second Step]

**AGENT INVOCATION - Reference Behavioral File, Inject Context Only**

Task {
  subagent_type: "general-purpose"
  description: "[Brief description with mandatory file creation]"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context Parameter 1]: [value]
    - [Context Parameter 2]: [value]
    - [Output Path]: [absolute path, pre-calculated]

    Execute per behavioral guidelines. Return: [SIGNAL]: [path]
  "
}
```

---

## Case Studies

### Case 1: /supervise Command (Spec 469)

**Problem**: 0% delegation rate, all 10 Task invocations failing silently

**Root Causes**:
1. Code-fenced Task example at lines 62-79 (priming effect)
2. Missing Bash in 3 agent files (tool access mismatch)
3. Code-fenced library sourcing at lines 217-277 (ambiguity)

**Fix**:
1. Removed code fence from Task example, added HTML comment
2. Added Bash to research-specialist.md, plan-architect.md, doc-writer.md
3. Unwrapped library sourcing bash block

**Impact**:
- Delegation rate: 0% → 100%
- Context usage: >80% → <30%
- Streaming fallback errors: Eliminated
- Parallel agent execution: 2-4 agents simultaneously

### Case 2: /supervise Command (Spec 438)

**Problem**: 0% delegation rate despite structurally correct Task invocations

**Root Cause**: 7 YAML blocks wrapped in ` ```yaml` code fences without imperative instructions

**Fix**: Removed code fences, added imperative instructions

**Impact**:
- Delegation rate: 0% → 100%
- File creation rate: 0% → 100%
- Context reduction: Enabled 90% reduction through behavioral injection

### Case 3: /report Command

**Problem**: User runs `/report "authentication patterns"` but gets single report instead of hierarchical multi-agent research

**Root Cause**: Command opening says "I'll research the specified topic..."

**Investigation**:
```bash
# Check execution output
cat .claude/specs/002_report_creation/example_3.md

# Observed:
# - ● Read(.claude/commands/report.md)
# - ● Read(.claude/docs/concepts/hierarchical-agents.md)
# - ● Write(reports/002_report_command_compliance_analysis.md)
# - No Task tool invocations
# - Single report created

# Conclusion: Command executed research directly, no agents invoked
```

**Fix Applied**:
```markdown
# Before
I'll research the specified topic and create a comprehensive report...

# After
I'll orchestrate hierarchical research by delegating to specialized subagents.

**YOUR ROLE**: You are the ORCHESTRATOR, not the researcher.

**CRITICAL INSTRUCTIONS**:
- DO NOT execute research yourself using Read/Grep/Write tools
- ONLY use Task tool to delegate research to research-specialist agents
- Your job: decompose topic → invoke agents → verify outputs → synthesize
```

**Result**: Command now invokes 2-4 research-specialist agents in parallel, creates subtopic reports + overview, achieves 95% context reduction.

---

## Quick Diagnosis Summary

### Symptom → Issue Mapping

| Symptom | Root Cause | Solution Section |
|---------|------------|------------------|
| No Task invocations | Ambiguous first-person opening | [Issue A](#issue-a-command-executes-directly-no-delegation) |
| "File not found" after creation | No path pre-calculation | [Issue B](#issue-b-artifact-created-at-wrong-location) |
| 0% delegation rate | Code fences/missing tools | [Issue C](#issue-c-delegation-failure-0-rate) |
| High context usage | No metadata extraction | [Issue D](#issue-d-context-reduction-not-achieved) |
| Recursive invocations | Agent uses SlashCommand | [Issue E](#issue-e-recursion-risk-slash-command-invocation) |
| Flat file structure | No topic utilities | [Issue F](#issue-f-artifacts-not-in-topic-directories) |

### Validation Commands

```bash
# Run all validators
.claude/tests/test_all_delegation_fixes.sh

# Individual validators:
.claude/tests/validate_no_agent_slash_commands.sh
.claude/tests/validate_command_behavioral_injection.sh
.claude/tests/validate_topic_based_artifacts.sh

# Component tests:
.claude/tests/test_code_writer_no_recursion.sh
.claude/tests/test_supervise_agent_delegation.sh

# Expected: All tests passing, 0 violations
```

---

## Related Documentation

- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - Best practices for command creation
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating agent behavioral files
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Complete pattern documentation
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 11: Imperative Agent Invocation
- [Hierarchical Agent Architecture](../concepts/hierarchical-agents.md) - Overall system architecture
- [Execution Enforcement Migration Guide](../guides/patterns/execution-enforcement/execution-enforcement-overview.md) - Complete migration process

---

## Support

If you encounter agent delegation issues not covered by this guide:

1. **Check logs**: `.claude/data/logs/adaptive-planning.log`
2. **Review test results**: Output from validation test suite
3. **Compare with working commands**: Study /orchestrate or /research patterns
4. **File issue**: Report unexpected behavior with reproducible example

For additional help, see [Claude Code Documentation](.claude/docs/README.md).

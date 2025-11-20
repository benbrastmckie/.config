# Troubleshooting Agent Delegation Issues

This guide covers common issues encountered when commands invoke agents using the behavioral injection pattern.

**Related Documentation**:
- [Command Not Delegating to Agents](command-not-delegating-to-agents.md) - **NEW**: When commands execute tasks directly instead of using agents
- [Agent Development Guide](../guides/agent-development-guide.md) - Creating agent behavioral files
- [Command Development Guide](../guides/command-development-guide.md) - Invoking agents from commands
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Working agent invocation pattern

**Common Issues Quick Links**:
- [Command executes task directly (no agents invoked)](command-not-delegating-to-agents.md) ← **Start here if no Task tool invocations**
- [Agent invokes slash command instead of creating artifact](#issue-1-agent-invokes-slash-command-instead-of-creating-artifact)
- [Agent creates file in wrong location](#issue-2-agent-creates-file-at-unexpected-location)
- [Agent returns summary text instead of creating file](#issue-3-agent-returns-text-summary-instead-of-creating-file)
- [Multiple agents create conflicting artifacts](#issue-4-multiple-agents-create-conflicting-artifacts)

## Issue 1: Agent Invokes Slash Command Instead of Creating Artifact

### Symptoms
- Agent output contains "Using SlashCommand tool to invoke /plan"
- Unexpected command execution during agent run
- Recursive delegation warnings in logs
- Artifact created but at unexpected path
- Cannot verify artifact location (path unknown)

### Diagnosis

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

### Solution

**Fix the agent behavioral file**:

Remove SlashCommand instructions and replace with direct file operations:

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

**Update command to inject behavioral context**:

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

### Verification

```bash
# Verify agent no longer contains SlashCommand
grep -c "SlashCommand" .claude/agents/AGENT_NAME.md
# Expected: 0

# Verify command pre-calculates path
grep -n "create_topic_artifact.*plans" .claude/commands/COMMAND_NAME.md
# Should find path calculation before Task invocation
```

### References
- [Agent Authoring Guide: What Agents Should NOT Do](../guides/agent-development-guide.md#what-agents-should-not-do)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

---

## Issue 2: Artifact Not Found at Expected Path

### Symptoms
- Command expects artifact at `specs/042_feature/reports/042_research.md`
- Artifact actually created at different path (e.g., `specs/reports/042_research.md`)
- `verify_artifact_or_recover()` returns error
- "Artifact not found" errors in command output

### Diagnosis

**Step 1: Check where artifact was actually created**
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

### Solution

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

### Verification

```bash
# Verify artifact at expected path
[[ -f "$EXPECTED_PATH" ]] && echo "✅ Artifact found" || echo "❌ Artifact not found"

# Verify topic-based organization
ls -R specs/042_feature/
# Should show: reports/, plans/, summaries/ subdirectories
```

### References
- [Command Authoring Guide: Topic-Based Artifact Paths](../guides/command-development-guide.md#topic-based-artifact-paths)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

---

## Issue 3: Context Reduction Not Achieved

### Symptoms
- Context usage still >50% after subagent delegation
- Expected 95% reduction, got <50% reduction
- Commands slow or hitting context limits
- Full artifact content appears in logs/outputs

### Diagnosis

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

### Solution

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

### Verification

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
.claude/lib/validate-context-reduction.sh
# Expected: All tests passing with ≥90% reduction
```

### References
- [Hierarchical Agents: Metadata Extraction](../concepts/hierarchical_agents.md#metadata-extraction)
- [Command Authoring Guide: Metadata Extraction](../guides/command-development-guide.md#metadata-extraction)

---

## Issue 4: Recursion Risk or Infinite Loops

### Symptoms
- Command invokes agent which invokes same command
- Stack overflow or max recursion depth errors
- "Circular delegation chain detected" warnings
- Command execution never completes

### Diagnosis

**Step 1: Identify delegation chain**
```bash
# Check if agent invokes command that invoked it
grep -n "/implement\|/plan\|/report" .claude/agents/code-writer.md

# Example violation:
# code-writer.md:29: YOU MUST use /implement command
```

**Step 2: Check command → agent → command pattern**
```bash
# In /implement command
grep -n "code-writer" .claude/commands/implement.md

# In code-writer agent
grep -n "/implement" .claude/agents/code-writer.md

# If both found, recursion risk exists:
# /implement → code-writer → /implement → ...
```

### Solution

**Fix 1: Remove slash command invocations from agent**

```markdown
# code-writer.md - WRONG (before fix):
## Type A: Plan-Based Implementation

YOU MUST use SlashCommand to invoke /implement:

SlashCommand {
  command: "/implement ${PLAN_PATH}"
}
```

```markdown
# code-writer.md - CORRECT (after fix):
## CRITICAL: Do NOT Invoke Slash Commands

**NEVER** use the SlashCommand tool to invoke:
- /implement (recursion risk - YOU are invoked BY /implement)
- /plan (plan creation is /plan command's responsibility)

**ALWAYS** use Read/Write/Edit tools to modify code directly.
```

**Fix 2: Clarify agent role**

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
```

### Verification

```bash
# Verify agent no longer invokes command
grep -c "/implement\|/plan\|/report" .claude/agents/AGENT_NAME.md
# Expected: 0

# Run recursion test
.claude/tests/test_code_writer_no_recursion.sh
# Expected: All tests passing, 0 recursion risks
```

### References
- [Agent Authoring Guide: Recursion Anti-Pattern](../guides/agent-development-guide.md#anti-pattern-recursion)
- [Behavioral Injection Anti-Patterns](../concepts/patterns/behavioral-injection.md#anti-patterns)

---

## Issue 5: Artifacts Not in Topic-Based Directories

### Symptoms
- Artifacts created in flat structure: `specs/reports/042_research.md`
- Not in topic directories: `specs/042_feature/reports/042_research.md`
- Difficult to find all artifacts for a feature
- `validate_topic_based_artifacts.sh` reports violations
- Inconsistent numbering across artifact types

### Diagnosis

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

### Solution

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

**Fix 3: Update `.gitignore` for topic-based structure**

```gitignore
# Ignore artifacts in topic directories
specs/*/reports/*.md
specs/*/plans/*.md
specs/*/summaries/*.md
specs/*/outputs/*.md
specs/*/scripts/*.md

# Commit debug reports (for history)
!specs/*/debug/*.md
```

**Fix 4: Ensure agents use provided topic-based paths**

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

### Verification

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

### References
- [Directory Protocols](.claude/docs/concepts/directory-protocols.md) - Topic-based structure standards
- [Artifact Creation Utilities](.claude/lib/artifact/artifact-creation.sh) - `create_topic_artifact()` function
- [Command Authoring Guide: Topic-Based Paths](../guides/command-development-guide.md#topic-based-artifact-paths)

---

## Summary

### Quick Diagnosis Checklist

```bash
# 1. Check for slash command anti-pattern
.claude/tests/validate_no_agent_slash_commands.sh

# 2. Check for behavioral injection compliance
.claude/tests/validate_command_behavioral_injection.sh

# 3. Check for topic-based organization
.claude/tests/validate_topic_based_artifacts.sh

# 4. Check agent behavioral files for violations
grep -r "SlashCommand" .claude/agents/

# 5. Check artifact paths
find specs -name "*.md" | head -20
```

### Common Root Causes

| Issue | Root Cause | Fix |
|-------|------------|-----|
| **Slash Command Invocation** | Agent behavioral file contains SlashCommand instructions | Remove SlashCommand, use Write/Read/Edit tools |
| **Path Mismatch** | Command doesn't pre-calculate path OR agent calculates own path | Use `create_topic_artifact()` in command, pass to agent |
| **Context Bloat** | Command loads full content instead of metadata | Use `extract_report_metadata()` for metadata only |
| **Recursion** | Agent invokes command that invoked it | Remove slash command invocations, clarify agent role |
| **Flat Structure** | Not using topic-based artifact utilities | Use `get_or_create_topic_dir()` + `create_topic_artifact()` |

### Prevention Best Practices

1. **Always pre-calculate paths** before agent invocation
2. **Always extract metadata only** (not full content)
3. **Never allow agents to invoke slash commands** for artifact creation
4. **Always use topic-based utilities** (`create_topic_artifact()`)
5. **Always verify compliance** with validators

### Getting Help

- **Guides**: See `.claude/docs/guides/` for authoring best practices
- **Examples**: See `.claude/docs/examples/` for working implementations
- **Architecture**: See `.claude/docs/concepts/hierarchical_agents.md` for pattern details
- **Validators**: Run `.claude/tests/validate_*.sh` scripts for automated checks

### Test Suite for Regression Prevention

```bash
# Run all validators
.claude/tests/test_all_delegation_fixes.sh

# Individual validators:
.claude/tests/validate_no_agent_slash_commands.sh
.claude/tests/validate_command_behavioral_injection.sh
.claude/tests/validate_topic_based_artifacts.sh

# Component tests:
.claude/tests/test_code_writer_no_recursion.sh
.claude/tests/test_orchestrate_planning_behavioral_injection.sh

# Expected: All tests passing, 0 violations
```

## See Also

- [Agent Development Guide](../guides/agent-development-guide.md) - Creating agent behavioral files
- [Command Development Guide](../guides/command-development-guide.md) - Invoking agents from commands and working examples
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Complete workflow example and Task tool invocations
- [Hierarchical Agent Architecture](../concepts/hierarchical_agents.md) - Overall system architecture

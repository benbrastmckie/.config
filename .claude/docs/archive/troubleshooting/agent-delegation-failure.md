# Agent Delegation Failure Troubleshooting

This guide helps diagnose and fix agent delegation failures where commands fail to invoke specialized agents despite having structurally correct Task invocations.

## Symptoms

### Primary Symptoms
- **0% delegation rate**: Task invocations never execute
- **Silent failure**: No error messages, command appears to work
- **"streaming fallback triggered" errors**: Recovery mechanism masks the underlying issue
- **Missing artifacts**: Expected reports/plans not created at calculated paths
- **Parallel execution disabled**: Agents never initialize, preventing concurrent work

### Secondary Symptoms
- **Context usage >80%**: Metadata extraction never occurs (should be <30%)
- **Sequential execution only**: Parallel agent features don't work
- **File creation rate 0%**: Agents supposed to create files but don't

## Root Causes

### Cause 1: Code Fence Priming Effect

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

### Cause 2: Tool Access Mismatch

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

### Cause 3: Documentation-Only YAML Blocks

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

### Cause 4: Code-Fenced Bash Blocks (Library Sourcing)

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

## Diagnostic Workflow

### Step 1: Identify Symptoms

Run validation test to measure delegation rate:

```bash
bash .claude/tests/test_supervise_agent_delegation.sh
```

If delegation rate is 0%, proceed to Step 2.

### Step 2: Check Code Fences

```bash
# Count YAML code fences
grep -c '```yaml' .claude/commands/your-command.md

# Count bash code fences in library regions
sed -n '200,300p' .claude/commands/your-command.md | grep -c '```bash'
```

If counts > 0 (excluding legitimate anti-pattern examples), you likely have priming effect or documentation-only issues.

### Step 3: Check Tool Access

```bash
# Verify all agents have Bash
for agent in .claude/agents/*.md; do
  grep "allowed-tools:" "$agent" | grep -q "Bash" || echo "Missing: $agent"
done
```

If any agents missing Bash, add it to frontmatter.

### Step 4: Check Imperative Instructions

```bash
# Find Task invocations without imperative markers
grep -B5 "Task {" .claude/commands/your-command.md | \
  grep -v "EXECUTE NOW\|USE the Task tool" | \
  grep "Task {"
```

If Task invocations found without imperative markers, add them.

### Step 5: Apply Fixes

Based on findings above:

1. **Remove code fences** from Task examples
2. **Add Bash** to agent frontmatter
3. **Add imperative instructions** to Task invocations
4. **Unwrap library sourcing** bash blocks

### Step 6: Validate Fix

```bash
# Re-run validation test
bash .claude/tests/test_supervise_agent_delegation.sh

# Expected metrics:
# - Delegation rate: 100%
# - Context usage: <30%
# - No streaming fallback errors
# - All artifacts created at expected paths
```

## Prevention

### Command Development Guidelines

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

5. **Follow established patterns**
   - Study working commands (e.g., /orchestrate, /research)
   - Reference [Command Development Guide](../guides/command-development-guide.md)
   - Follow [Standard 11: Imperative Agent Invocation](../reference/command_architecture_standards.md#standard-11)

### Code Review Checklist

Before merging command file changes:

- [ ] All Task invocations have imperative markers (`**EXECUTE NOW**`)
- [ ] No code fences around executable Task blocks
- [ ] All agents have required tools in allowed-tools frontmatter
- [ ] Library sourcing blocks unwrapped (no ` ```bash` fences)
- [ ] Validation test created and passing
- [ ] Delegation rate verified at 100%

## Related Documentation

- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Complete pattern documentation
- [Command Development Guide](../guides/command-development-guide.md) - Best practices for command creation
- [Command Architecture Standards](../reference/command_architecture_standards.md) - Standard 11: Imperative Agent Invocation
- [Test Suite](../../tests/test_supervise_agent_delegation.sh) - Validation test for delegation rate

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

## Support

If you encounter agent delegation issues not covered by this guide:

1. **Check logs**: `.claude/data/logs/adaptive-planning.log`
2. **Review test results**: Output from validation test suite
3. **Compare with working commands**: Study /orchestrate or /research patterns
4. **File issue**: Report unexpected behavior with reproducible example

For additional help, see [Claude Code Documentation](.claude/docs/README.md).

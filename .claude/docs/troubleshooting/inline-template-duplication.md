# Inline Template Duplication

## Metadata
- **Problem Type**: Anti-Pattern
- **Symptoms**: Large command files, maintenance burden, synchronization issues
- **Severity**: Medium (affects maintainability, not functionality)
- **Fix Time**: 15-30 minutes per command
- **Related**: [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md)

## Quick Diagnosis

Use this checklist to identify if you have inline template duplication:

- [ ] Command file >2000 lines with multiple agent invocations
- [ ] Agent invocation prompts >100 lines each
- [ ] STEP 1/2/3 sequences embedded in command prompts
- [ ] PRIMARY OBLIGATION or ABSOLUTE REQUIREMENT in command files
- [ ] Duplicate behavioral guidelines across multiple commands
- [ ] Changes to agent behavior require updates in 3+ files

If you checked 2+ items, you likely have behavioral duplication.

## Root Cause

### Issue
Behavioral content is duplicated inline in command files instead of being referenced from agent files.

### Pattern
Commands contain STEP sequences, PRIMARY OBLIGATION blocks, and verification procedures that belong in `.claude/agents/*.md` files.

### Why It Happens
Unclear distinction between:
- **Structural templates** (Task blocks, bash execution, verification checkpoints) that MUST be inline
- **Behavioral content** (agent procedures, workflows) that MUST be referenced

## Detection

### Automated Detection Commands

**Detect inline STEP sequences in commands:**
```bash
# Count STEP instructions in each command file
for file in .claude/commands/*.md; do
  count=$(grep -c "STEP [0-9]" "$file" 2>/dev/null || echo 0)
  if [ "$count" -gt 5 ]; then
    echo "⚠️  WARNING: $file has $count STEP instructions (expect <5)"
  fi
done
```

**Detect PRIMARY OBLIGATION outside agent files:**
```bash
# Should return nothing (PRIMARY OBLIGATION only in agent files)
grep -r "PRIMARY OBLIGATION" .claude/commands/ --include="*.md"

if [ $? -eq 0 ]; then
  echo "❌ FAIL: PRIMARY OBLIGATION found in command files"
  echo "   Should only exist in .claude/agents/*.md files"
else
  echo "✓ PASS: No PRIMARY OBLIGATION in command files"
fi
```

**Find large agent invocations (>50 lines):**
```bash
# Extract Task blocks and count lines
awk '/Task \{/,/^\}$/ {
  if (/Task \{/) { start=NR; file=FILENAME; lines="" }
  lines = lines $0 "\n"
  if (/^\}$/ && start>0) {
    size=NR-start
    if (size > 50) {
      print "⚠️  WARNING: " file " has " size "-line Task invocation (expect <50)"
      print "   Likely contains duplicated behavioral content"
    }
    start=0
  }
}' .claude/commands/*.md
```

**Calculate duplication percentage:**
```bash
# Compare command file size to recommended size
for file in .claude/commands/*.md; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 1500 ]; then
    echo "⚠️  $file: $lines lines (recommend <1000 without duplication)"

    # Estimate potential reduction
    step_count=$(grep -c "STEP [0-9]" "$file" 2>/dev/null || echo 0)
    if [ "$step_count" -gt 10 ]; then
      estimated_reduction=$((step_count * 15))
      echo "   Estimated reduction: ~$estimated_reduction lines (90% per STEP sequence)"
    fi
  fi
done
```

## Refactoring Process

### Step 1: Identify Behavioral Content in Command

Look for these patterns in command files that indicate duplication:

**Behavioral Content (should be in agent files):**
- `STEP 1/2/3` sequences with detailed procedures
- `PRIMARY OBLIGATION` blocks defining agent responsibilities
- `ABSOLUTE REQUIREMENT` blocks for agent behavior
- Agent verification steps (agent self-checks before returning)
- Output format templates for agent responses

**Structural Templates (correctly in command files):**
- `Task { }` invocation structure
- `**EXECUTE NOW**` bash blocks for command execution
- `**MANDATORY VERIFICATION**` checkpoints for orchestrator
- JSON schemas for data structures
- `**CRITICAL**` warnings about execution constraints

### Step 2: Extract to Appropriate Agent File

Create or update agent file in `.claude/agents/`:

**Example: Extract research procedures to research-specialist.md**

Create `.claude/agents/research-specialist.md`:
```markdown
---
allowed-tools: Read, Grep, Write
description: Research specialist for code analysis and documentation
---

# Research Specialist

## Behavioral Guidelines

### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

**MANDATORY INPUT VERIFICATION**

The invoking command MUST provide you with an absolute report path.
Verify you have received it before proceeding.

### STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research

**RESEARCH EXECUTION**

Analyze the codebase, documentation, and requirements to address
the research topic provided in your context.

### STEP 3 (REQUIRED BEFORE STEP 4) - Create Report at Exact Path

**PRIMARY OBLIGATION**: File creation is your PRIMARY task.

YOU MUST use the Write tool to create the report file at the exact
path from Step 1 BEFORE populating content.

### STEP 4 (MANDATORY VERIFICATION) - Verify and Return

**ABSOLUTE REQUIREMENT**: Verify file exists before returning.

Use Read tool to confirm file was created successfully.
```

### Step 3: Update Command to Reference Agent File with Context Injection

Replace inline behavioral content with agent file reference:

**Before (150 lines - behavioral duplication):**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research topic"
  prompt: "
    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.

    **STEP 1 (REQUIRED BEFORE STEP 2)**: Receive and Verify Report Path

    The invoking command MUST provide you with an absolute report path.
    Verify you have received it:

    [... 30 lines of verification instructions ...]

    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct Research

    [... 40 lines of research instructions ...]

    **STEP 3 (REQUIRED BEFORE STEP 4)**: Create Report File

    YOU MUST use the Write tool to create the report at the exact path
    from Step 1 BEFORE populating content.

    [... 30 lines of file creation instructions ...]

    **STEP 4 (MANDATORY VERIFICATION)**: Verify and Return

    [... 20 lines of verification instructions ...]

    Report path: ${REPORT_PATH}
    Research topic: ${TOPIC}
  "
}
```

**After (15 lines - context injection only):**
```markdown
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    CONTEXT (inject parameters, not procedures):
    - Research topic: ${TOPIC}
    - Report path: ${REPORT_PATH} (absolute path - verified by command)
    - Focus areas: ${FOCUS_AREAS}
    - Success criteria: Create report at exact path with research findings
  "
}
```

### Step 4: Validate Reduction

Measure the improvement:

```bash
# Before refactoring
BEFORE_LINES=$(git show HEAD:path/to/command.md | wc -l)

# After refactoring
AFTER_LINES=$(wc -l < path/to/command.md)

# Calculate reduction
REDUCTION=$(( (BEFORE_LINES - AFTER_LINES) * 100 / BEFORE_LINES ))

echo "Reduction: $REDUCTION% ($BEFORE_LINES → $AFTER_LINES lines)"
echo "Expected: ~90% reduction per agent invocation"
```

Expected results:
- Command file reduced by 50-90% (depending on number of agent invocations)
- Each agent invocation reduced from ~150 lines to ~15 lines
- Agent file created with all behavioral guidelines (single source of truth)

### Step 5: Test Command Execution

Verify the agent receives and follows guidelines:

```bash
# Run the command
/command-name "test task"

# Verify:
# 1. Agent creates file at correct path
# 2. File contains expected content
# 3. Agent follows all STEP sequences from behavioral file
# 4. No errors or missing procedures
```

## Before/After Example

### Before Refactoring (646 lines in command file)

**File: `.claude/commands/report.md` (excerpt showing duplication)**
```markdown
## Phase 2: Invoke Research Agent

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    You are a research specialist for software engineering projects.

    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.

    ### STEP 1 (REQUIRED BEFORE STEP 2) - Receive and Verify Report Path

    **MANDATORY INPUT VERIFICATION**

    The invoking command MUST provide you with an absolute report path.
    Verify you have received it before proceeding:

    1. Check that REPORT_PATH variable is set
    2. Verify path is absolute (starts with /)
    3. Verify parent directory exists
    4. Echo confirmation before continuing

    **CHECKPOINT**: YOU MUST have an absolute path before proceeding to Step 2.

    ### STEP 2 (REQUIRED BEFORE STEP 3) - Conduct Research

    **RESEARCH EXECUTION**

    Analyze the codebase, documentation, and requirements to address
    the research topic:

    1. Use Grep to search for relevant code patterns
    2. Use Read to examine implementation details
    3. Document findings with file:line references
    4. Organize information into structured sections
    5. Prepare recommendations based on analysis

    ### STEP 3 (REQUIRED BEFORE STEP 4) - Create Report at Exact Path

    **PRIMARY OBLIGATION**: File creation is your PRIMARY task.

    YOU MUST use the Write tool to create the report file at the exact
    path from Step 1 BEFORE populating content:

    1. Use Write tool with REPORT_PATH from Step 1
    2. Create file with proper markdown structure
    3. Include all required sections (Executive Summary, Findings, etc.)
    4. Do NOT return until file is created

    **CRITICAL**: If Write fails, DO NOT CONTINUE. Report the error immediately.

    ### STEP 4 (MANDATORY VERIFICATION) - Verify and Return

    **ABSOLUTE REQUIREMENT**: Verify file exists before returning.

    Before returning your response:

    1. Use Read tool to verify file exists at REPORT_PATH
    2. Confirm file contains expected sections
    3. Report any discrepancies or issues
    4. Return file path in response

    **DO NOT SKIP VERIFICATION**. This is mandatory.

    ---

    CONTEXT for this research task:
    - Research topic: ${TOPIC}
    - Report path: ${REPORT_PATH}
    - Focus areas: ${FOCUS_AREAS}
  "
}
```

**Issues:**
- 150+ lines of agent behavioral procedures duplicated inline
- If agent behavior changes, must update in multiple commands
- Maintenance burden: 5+ files to update for single agent change
- Context bloat: 85% of invocation is duplicated content

### After Refactoring (15 lines in command file)

**File: `.claude/agents/research-specialist.md` (new agent file)**
```markdown
---
allowed-tools: Read, Grep, Write
description: Research specialist for code analysis and documentation
---

# Research Specialist

[... complete behavioral guidelines as shown in Step 2 above ...]
```

**File: `.claude/commands/report.md` (refactored)**
```markdown
## Phase 2: Invoke Research Agent

Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    CONTEXT:
    - Research topic: ${TOPIC}
    - Report path: ${REPORT_PATH}
    - Focus areas: ${FOCUS_AREAS}
  "
}
```

**Benefits:**
- 90% reduction: 150 lines → 15 lines per invocation
- Single source of truth: Agent behavioral file is authoritative
- Zero maintenance burden: Update once in agent file, all commands benefit
- Context efficiency: <30% context usage vs 85% before

## Prevention

### Development Practices

**1. Use Behavioral Injection Pattern for All Agent Invocations**

Always reference agent behavioral files, never duplicate procedures:

```markdown
✓ CORRECT:
Task {
  prompt: "
    Read and follow: .claude/agents/[name].md

    CONTEXT: [parameters only]
  "
}

✗ INCORRECT:
Task {
  prompt: "
    STEP 1: Do this...
    STEP 2: Do that...
    [behavioral procedures duplicated inline]
  "
}
```

**2. Reference Template vs Behavioral Distinction Before Creating Commands**

Before writing command files, review:
- [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md)
- Decision tree: "Should this be inline?"
- Structural templates (inline) vs behavioral content (referenced)

**3. Run Validation Script Before Commits (Optional)**

If available, run automated validation:

```bash
# Run validation script to detect duplication
.claude/tests/validate_no_behavioral_duplication.sh

# Expected output: No warnings or errors
```

**4. Code Review Checklist**

Include these items in code review checklist:

- [ ] No behavioral duplication in command files
- [ ] Agent invocations use behavioral injection pattern
- [ ] STEP sequences only in agent files, not commands
- [ ] Structural templates (Task syntax, bash) are complete
- [ ] Cross-references to agent behavioral files are correct

### Maintenance Practices

**1. Update Agent Files, Not Command Invocations**

When changing agent behavior:
- ✓ Update `.claude/agents/[name].md` (single source of truth)
- ✗ Do NOT update STEP sequences in command files

**2. Monitor Command File Size**

Track command file sizes over time:

```bash
# Alert if command files grow significantly
for file in .claude/commands/*.md; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 1500 ]; then
    echo "⚠️  $file: $lines lines (investigate for duplication)"
  fi
done
```

**3. Periodic Audits**

Run detection commands monthly:
- Check for STEP sequences in command files
- Check for PRIMARY OBLIGATION in command files
- Identify large agent invocations (>50 lines)

## Troubleshooting Pattern: Search Pattern Mismatch

### Problem Symptoms

**Symptom**: Implementation plan searches for a pattern that doesn't exist in target files.

**Observable Impact**:
- Edit tool finds 0 matches when attempting replacements
- Regression tests give false passes (searching for non-existent patterns)
- Implementation effort wasted trying to replace patterns that aren't present

**Root Cause**: Plan assumes patterns based on analysis rather than verifying actual strings with Grep tool.

### Diagnostic Steps

**Step 1: Pattern Verification**
- Use Grep to find actual patterns in target file
- Compare discovered patterns against plan's search strings
- Identify any mismatches between expected and actual patterns
- Verify regression tests search for correct patterns

**Step 2: Classification of Duplicated Content**
- For each code block or template, classify as:
  - **Structural**: Documentation examples (retain)
  - **Mixed**: Contains both documentation and duplication (refactor selectively)
  - **Behavioral**: Pure duplication (remove/extract)

**Step 3: Corrected Implementation Strategy**
- Add pattern verification phase before making edits
- Update search patterns to match actual file content
- Test Edit tool on sample patterns before full implementation
- Clarify target state with explicit line numbers and examples
- Fixed regression test to detect actual patterns

**Step 4: Pattern Verification Guards**

Added verification commands to Phase 0:

```bash
# Verify YAML block count
YAML_COUNT=$(grep -c '```yaml' .claude/commands/supervise.md)
# Expected: 7 before refactor

# Verify assumed pattern does NOT exist
EXAMPLE_COUNT=$(grep -c "Example agent invocation:" .claude/commands/supervise.md)
# Expected: 0 (pattern never existed)

# Verify actual pattern EXISTS
YAML_TASK_COUNT=$(awk '/```yaml/{flag=1} flag && /Task \{/{count++; flag=0} END{print count}' .claude/commands/supervise.md)
# Expected: 7 (actual pattern to refactor)

# If verification fails, STOP and review
```

### Results

**Before Refactor**:
- 7 YAML blocks, ~915 lines total
- 5 agent templates with full STEP sequences (~885 lines)
- 2 documentation examples (~30 lines)
- Maintenance burden: Update 6 files when changing agent behavior

**After Refactor** (projected):
- 2 YAML blocks, ~75 lines total
- 5 agent templates replaced with context injection (~60 lines)
- 2 documentation examples refined (~15 lines)
- Maintenance: Update 1 agent file per behavior change

**Reduction**: 840 lines removed (92% reduction)

### Key Lessons Learned

#### 1. Always Verify Search Patterns Exist Before Planning Replacements

**Wrong Approach**:
```markdown
# Plan assumption (incorrect)
Current Anti-Pattern Location:
- Line 49-54: Example agent invocation pattern

Implementation:
1. Search for "Example agent invocation:" followed by ```yaml
2. Replace with lean context injection
```

**Correct Approach**:
```bash
# Verify pattern exists first
grep -n "Example agent invocation:" supervise.md
# Output: (no matches)

# Conclusion: Pattern doesn't exist, plan needs revision
```

#### 2. Use Grep to Extract Actual Strings, Not Inferred Descriptions

**Wrong**: "Line 49 shows Example agent invocation pattern"
- This is an INFERENCE about the block's purpose
- The actual text at line 49 may be completely different

**Correct**: Use Grep to extract actual strings
```bash
# Extract actual context around line 49
sed -n '45,55p' supervise.md

# Output shows actual text:
# **Wrong Pattern - Command Chaining** (causes context bloat...):
# ```yaml
# # ❌ INCORRECT - Do NOT do this
```

#### 3. Classify YAML Blocks as Structural vs Behavioral Before Deciding Keep/Remove

Not all YAML/code blocks are behavioral duplication:

- **Documentation examples** (lines 49, 63): Show structural templates (Task invocation syntax)
  - Decision: KEEP (educational value) or REFACTOR (remove behavioral parts)
- **Agent templates** (lines 682+): Full behavioral procedures
  - Decision: REMOVE (replace with context injection)

**Classification prevents**:
- Removing necessary structural templates
- Keeping behavioral duplication mistakenly
- Ambiguous target state ("remove all 7" vs "remove 5, refactor 2")

#### 4. Pattern Verification in Phase 0 Prevents Wasted Implementation Effort

**Cost Without Verification**:
- Agent reads plan (1036 lines)
- Agent reads file (2521 lines)
- Agent attempts implementation
- Agent reports "0 patterns found, no work to do"
- Developer investigates → discovers pattern mismatch
- Plan must be revised and re-implemented
- **Total wasted effort**: 1-2 hours

**Cost With Verification**:
- Run Phase 0 verification script (30 seconds)
- Script reports pattern mismatch immediately
- Developer fixes pattern in plan before implementation
- Implementation succeeds on first attempt
- **Time saved**: 1-2 hours

### Implementation Status

**Completed**:
- ✅ Diagnostic analysis (spec 444/001/OVERVIEW.md)
- ✅ YAML block classification (supervise_yaml_classification.md)
- ✅ Corrected refactor plan with pattern verification (001_supervise_refactor_corrected.md)

**Pending**:
- ⏳ Execute corrected refactor plan
- ⏳ Validate 90% code reduction achieved
- ⏳ Update regression test with actual patterns

### Prevention Checklist for Future Refactors

Based on /supervise experience:

- [ ] **Pattern Verification**: Use Grep to confirm patterns exist before planning replacements
- [ ] **Actual Strings**: Extract and document actual text, not inferred descriptions
- [ ] **Classification**: Explicitly classify content as structural vs behavioral
- [ ] **Phase 0 Guards**: Add verification step to catch mismatches before implementation
- [ ] **Regression Test Accuracy**: Ensure tests detect actual patterns, not phantom patterns
- [ ] **Target State Clarity**: Document exact expected outcome (e.g., "2 blocks retained, 5 removed")

### References

- **Diagnostic Report**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/OVERVIEW.md`
- **Classification**: `.claude/specs/444_research_allowed_tools_fix/reports/001_research/supervise_yaml_classification.md`
- **Corrected Plan**: `.claude/specs/444_research_allowed_tools_fix/plans/001_supervise_refactor_corrected.md`
- **Original Plan** (blocked): `.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/plans/001_supervise_command_refactor_integration.md`
- **Target File**: `.claude/commands/supervise.md` (2,520 lines)

---

## Related Documentation

- [Template vs Behavioral Distinction](../reference/architecture/template-vs-behavioral.md) - Decision criteria for inline vs reference
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How to reference agent files correctly
- [Command Architecture Standards](../reference/architecture/overview.md) - Standard 12: Structural vs Behavioral Content Separation
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Agent files as single source of truth

## Summary

**Problem**: Behavioral content duplicated in command files instead of referenced from agent files

**Detection**: STEP sequences, PRIMARY OBLIGATION, or large Task blocks in commands

**Fix**: Extract to agent file, update command to reference with context injection

**Prevention**: Use behavioral injection pattern for all agent invocations

**Metrics**: Expect 90% reduction per invocation (150 lines → 15 lines)

# Inline Template Patterns and Usage in .claude/docs/

## Metadata
- **Date**: 2025-10-24
- **Agent**: research-specialist
- **Topic**: Inline Template Patterns and Usage in .claude/docs/
- **Report Type**: codebase analysis

## Executive Summary

Documentation in .claude/docs/ distinguishes between acceptable inline templates (Task invocations, bash scripts, YAML/JSON schemas) and anti-pattern inline duplication (embedding full agent behavioral guidelines). Inline templates for tool invocations are documented as the correct pattern across command development guides, enforcement standards, and troubleshooting documentation, while duplicating agent behavioral files inline is explicitly marked as an anti-pattern.

## Findings

### 1. Inline Templates Are Standard Pattern in Command Files

The documentation establishes inline templates as a fundamental requirement for command execution:

**Command Architecture Standards** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:29):
- Line 29: "Inline templates for agent prompts, JSON structures, and bash commands"
- This is listed as a core characteristic of "What Command Files Are"
- Template types: agent prompts, JSON structures, bash commands

**Why Inline Templates Are Required** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:38-45):
- Lines 38-45: Command files are "AI execution scripts" that Claude must execute immediately
- "Claude cannot effectively load and process multiple external files mid-execution"
- "Context switches to external files break execution flow and lose state"
- Analogy provided: "A command file is like a cooking recipe. You can't replace the instructions with 'See cookbook on shelf'"

### 2. Three Types of Inline Templates Documented

**Pattern 1: Direct Execution Blocks** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:79-101):
```markdown
**EXECUTE NOW - Calculate Report Paths**

Run this code block BEFORE invoking agents:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/artifact-creation.sh"
WORKFLOW_TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESCRIPTION" ".claude/specs")
```
```

**Pattern 2: Mandatory Verification Checkpoints** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:104-133):
```bash
for topic in "${!REPORT_PATHS[@]}"; do
  if [ ! -f "$EXPECTED_PATH" ]; then
    echo "CRITICAL: Report missing at $EXPECTED_PATH"
  fi
done
```

**Pattern 3: Agent Invocation Templates** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:136-164):
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research ${TOPIC} with mandatory file creation"
  prompt: "
    **STEP 1: CREATE FILE** (Do this FIRST, before research)
    Use Write tool to create: ${REPORT_PATHS[$TOPIC]}
    ...
  "
}
```

With enforcement marker: "**ENFORCEMENT**: Copy this template verbatim. Do NOT simplify or paraphrase the prompt."

### 3. STEP-by-STEP Templates Extensively Used

Found 21 files containing STEP N patterns with inline instructions:

**Command Development Guide** (/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:729-786):
- Lines 729-786: Complete example showing "STEP 1", "STEP 2", "STEP 3" with inline bash blocks and Task templates
- Pattern: "### STEP N (REQUIRED BEFORE STEP N+1) - [Action]"
- Each step contains executable code blocks

**Troubleshooting Guide** (/home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md:305-323):
- Lines 305-323: Template showing STEP 1, STEP 2 structure with Task templates
- Includes full agent invocation template inline

**Execution Enforcement Guide** (grep results): Multiple occurrences of STEP templates with inline YAML/bash

### 4. Anti-Pattern: Duplicating Agent Behavioral Files

**Behavioral Injection Pattern Documentation** (/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:188-248):

**Anti-Pattern Example (Lines 188-221)**:
```markdown
❌ BAD - Duplicating agent behavioral guidelines inline:

Task {
  prompt: "
    **ABSOLUTE REQUIREMENT**: Creating the report file is your PRIMARY task.
    **STEP 1 (REQUIRED BEFORE STEP 2)**: Use Write tool...
    [... 30 lines of detailed instructions ...]
    **STEP 2 (REQUIRED BEFORE STEP 3)**: Conduct research
    [... 40 lines of detailed instructions ...]
  "
}
```

**Why This Fails**:
1. Duplicates 646 lines of research-specialist.md behavioral guidelines (~150 lines per invocation)
2. Creates maintenance burden: must manually sync template with behavioral file
3. Violates "single source of truth" principle
4. Adds unnecessary bloat: 800+ lines across command file

**Correct Pattern (Lines 222-243)**:
```markdown
✅ GOOD - Reference behavioral file with context injection:

Task {
  prompt: "
    Read and follow ALL behavioral guidelines from:
    .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}

    Execute research per behavioral guidelines.
  "
}
```

**Benefits**: 90% reduction (150 lines → 15 lines per invocation)

### 5. Task Templates vs Behavioral Duplication Distinction

**What Should Be Inline**:

**Command Patterns Guide** (/home/benjamin/.config/.claude/docs/guides/command-patterns.md:32-48):
- Task tool invocation structure
- Context parameters
- Expected output format
- Success criteria

**Refactoring Methodology** (/home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md - grep result):
Line context: "Keep inline: EXECUTE NOW, MANDATORY VERIFICATION, Task templates"

**What Should NOT Be Inline**:

**Behavioral Injection Pattern** (/home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md:215-220):
- Full agent behavioral guidelines (STEP 1, STEP 2, STEP 3 from agent files)
- Detailed execution procedures that exist in agent definitions
- Multi-hundred-line agent instructions

### 6. Where Inline Templates Are Recommended

**Command Development Guide** (/home/benjamin/.config/.claude/docs/guides/command-development-guide.md:722-786):
- Section 7.1: "Example: Research Command with Agent Delegation"
- Shows complete inline templates for:
  - Path pre-calculation bash blocks
  - Task invocation YAML blocks
  - Verification checkpoint bash blocks

**Command Architecture Standards** (/home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md:59-101):
- Section "Standard 0: Execution Enforcement"
- Documents three inline template patterns as mandatory
- No suggestion to extract to external files

**Troubleshooting: Command Not Delegating** (/home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md:282-351):
- Provides "Quick Reference Template" for command openings
- Entire template is inline (STEP 1, STEP 2, Task blocks)
- Lines 282-351: Copy-paste template structure

### 7. YAML and JSON Schema Templates

**Command Patterns** (/home/benjamin/.config/.claude/docs/guides/command-patterns.md:32-96):
- Lines 32-96: Multiple YAML Task templates shown inline
- Basic agent invocation template
- Parallel agent invocation template
- Sequential agent chain template

**Hierarchical Agents Guide** (grep result):
"Supported Formats: JSON code blocks, YAML code blocks"
Context suggests these are used inline in command prompts

## Recommendations

### 1. Clarify Template Terminology

**Issue**: "Inline template" can be ambiguous - refers to both acceptable patterns (Task invocations) and anti-patterns (behavioral duplication).

**Recommendation**: Use precise terminology:
- **"Tool invocation templates"** - Acceptable inline patterns (Task blocks, bash scripts)
- **"Agent behavioral duplication"** - Anti-pattern (embedding full agent files)
- **"Context injection templates"** - Lightweight Task prompts with file references

### 2. Add Visual Distinction in Documentation

**Current State**: Anti-pattern is documented in one location (behavioral-injection.md:188-248).

**Recommendation**: Add visual markers across all guides:
```markdown
✅ INLINE PATTERN - Tool Invocation Template
```yaml
Task { ... }
```

❌ ANTI-PATTERN - Agent Behavioral Duplication
```yaml
Task {
  prompt: "**STEP 1**: [150 lines from agent file]..."
}
```
```

### 3. Update Command Development Guide Examples

**Current**: Examples show Task templates inline (correct) but could clarify the boundary.

**Recommendation**: Add explicit note to section 5.2 (Behavioral Injection Pattern):
```markdown
**Note**: This Task template is a lightweight invocation structure (15 lines).
This is NOT the same as duplicating the full agent behavioral file (646 lines).
See Anti-Pattern in [Behavioral Injection](../concepts/patterns/behavioral-injection.md#anti-pattern-0).
```

### 4. Create Template Size Guidelines

**Recommendation**: Add to Command Architecture Standards:
```markdown
### Inline Template Size Guidelines

**Acceptable inline templates**:
- Task invocation: 10-30 lines (context injection)
- Bash execution block: 5-50 lines (utility function calls)
- Verification checkpoint: 10-30 lines (file checks, error handling)
- JSON/YAML schema: 10-40 lines (data structure definition)

**Requires external reference**:
- Agent behavioral guidelines: 100-700 lines → Reference file
- Detailed procedures: >50 lines → Extract to shared/ or agent file
- Reusable patterns: Used in 3+ commands → Extract to docs/
```

### 5. Audit Existing Commands for Anti-Pattern

**Recommendation**: Search for oversized inline prompts:
```bash
# Find Task blocks with >50 lines of content
grep -A 50 'Task {' .claude/commands/*.md | \
  awk '/Task {/,/}/' | \
  awk 'length > 50 {print FILENAME":"NR}'
```

Flag any command with Task prompts >100 lines for potential behavioral duplication.

## References

### Primary Documentation Files

1. /home/benjamin/.config/.claude/docs/reference/command_architecture_standards.md
   - Lines 29: Inline templates listed as core characteristic
   - Lines 38-45: Rationale for inline templates
   - Lines 79-164: Three inline template patterns with examples

2. /home/benjamin/.config/.claude/docs/concepts/patterns/behavioral-injection.md
   - Lines 188-248: Anti-pattern (inline duplication) vs correct pattern (file reference)
   - Lines 215-220: "Why This Fails" explanation
   - Lines 244-248: "Benefits" of correct pattern (90% reduction)

3. /home/benjamin/.config/.claude/docs/guides/command-development-guide.md
   - Lines 722-786: Complete example with inline templates
   - Lines 429-488: Behavioral injection pattern explanation
   - Lines 729-758: STEP-by-STEP inline template structure

4. /home/benjamin/.config/.claude/docs/troubleshooting/command-not-delegating-to-agents.md
   - Lines 282-351: Copy-paste template with inline structures
   - Lines 305-323: STEP 1, STEP 2 template examples

5. /home/benjamin/.config/.claude/docs/guides/command-patterns.md
   - Lines 32-96: Multiple YAML Task templates
   - Lines 227-259: Spec-updater agent invocation template

### Supporting Files

6. /home/benjamin/.config/.claude/docs/guides/agent-development-guide.md
   - Lines 691-729: Pattern showing agent file structure (what NOT to duplicate inline)

7. /home/benjamin/.config/.claude/docs/guides/execution-enforcement-guide.md
   - Grep results: Multiple STEP templates with inline YAML/JSON/bash

8. /home/benjamin/.config/.claude/docs/guides/refactoring-methodology.md
   - Grep result: "Keep inline: EXECUTE NOW, MANDATORY VERIFICATION, Task templates"

### Search Results Summary

- Files with STEP patterns: 21 files
- Files with Task { blocks: 24 files (113 total occurrences)
- Files mentioning "inline template" or "embedded template": 0 (term not used explicitly)
- Files with YAML/JSON blocks: 26 files

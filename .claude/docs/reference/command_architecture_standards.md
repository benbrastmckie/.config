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
- [Command Patterns](command-patterns.md): Common execution patterns across commands
- [Agent Patterns](agent-patterns.md): Agent invocation and coordination patterns
- [Testing Standards](testing-standards.md): Validation and testing requirements
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
